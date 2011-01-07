unit DiaporamaDownloader;

interface

uses
  Generics.Defaults, Generics.Collections,
  Diaporama, DiaporamaResource, DiaporamaCenterSettings,
  ThreadIntf, ScheduleAction, Downloader, Diapositive;

type
  // Downloader of diaporama and needed media files
  // May use different downloading protocols (only HTTP for now)
  TDiaporamaLoadStatus = (dlsIdle, dlsDownloading);

  TDiaporamaDownloader = class(TObject, IThread, IScheduleSource)
  private
    FDiaporamaCenterAgent: TObject;
    FDiaporamaCenterSettings: TDiaporamaCenterSettings;
    // Download is done in a thread
    FThreadLink: TThreadLink;
    // Downloader
    FDownloader: TDownloader;
    // Cache
    FRepository: TObject;
    // Diaporama to be downloaded
    FDiaporama: TDiaporama;
    // Media list to be downloaded
    FDiaporamaResources: TObjectList<TDiaporamaResource>;
    // Status
    FStatus: TDiaporamaLoadStatus;

    function GetDiaporamaFilePath: string;

    // Creates the list of Resources to be downloaded
    procedure PrepareResourceDownloadList;
    // Downloads the listed Resources
    procedure ThreadDownloadResourceList;

    // Registers in schedule
    procedure RegisterInSchedule;
    // Unregisters from schedule
    procedure UnregisterFromSchedule;

    // Deletes the diapositive and associated medias files from cache
    procedure PurgeDiapositive(const aDiapositive: TDiapositive);

  public
    constructor Create(const aRepository: TObject;
      const aDiaporama: TDiaporama;
      const aDiaporamaCenterAgent: TObject);
    destructor Destroy; override;

    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    // IThread
    procedure Execute;
    procedure OnTerminateExecute;

    // IScheduleSource
    function GetSourceName: string;
    function GetDefaultAction(const actionCode: Integer): TScheduleAction;
    function GetActionName(const aScheduleAction: TScheduleAction): string;
    procedure CheckActions(const actions: TObjectList<TScheduleAction>);
    function ExecuteAction(const aScheduleAction: TScheduleAction): Boolean;

    // Downloads (if needed) a diaporama and loads it
    function LoadDiaporama: Boolean;

    // Downloads the XML file of diaporama
    function DownloadDiaporama: Boolean;

    // Runs the download of files needed by a diaporama in a thread
    procedure DownloadDiaporamaResources;

    // Deletes all diapositives and associated medias from the cache
    procedure PurgeDiaporama;

    // Delete diaporama from the cache and downloads it
    function UpdateDiaporama: Boolean;

    // Stop the thread that downloads the media
    procedure StopDownloadDiaporamaResources;

    // Returns the media download status (number of downloaded media files...)
    function GetDownloadStatusMediaCount(
      const aDownloadStatus: TDownloadStatus): Integer;

    property Repository: TObject read FRepository write FRepository;
    property Diaporama: TDiaporama read FDiaporama;
  end;

const
  ACT_UPDATE_DIAPORAMA = 0;

implementation

uses
  SysUtils, ActiveX,
  HttpDownloader, DiaporamaRepository, DiapositiveType, DiaporamaUtils,
  DiaporamaCenterAgent, Logs;

const
  cstDownloadDiaporamaMsg =
    'Download diaporama ID = ''%s''';
  cstPrepareDownloadMsg =
    'Prepare download of diaporama ''%s'' (ID = ''%s'')';
  cstLoadingDiaporamaMsg = 'Load diaporama ID = ''%s''...';
  cstDiaporamaLoadedMsg
    = 'Diaporama ID = ''%s'' was successfully loaded';
  cstDiaporamaLoadError = 'Erreur while loading diaporama ID ''%s''';

constructor TDiaporamaDownloader.Create(const aRepository: TObject;
  const aDiaporama: TDiaporama;
  const aDiaporamaCenterAgent: TObject);
begin
  FThreadLink := TThreadLink.Create(Self);

  FRepository :=  aRepository;
  FDiaporama := aDiaporama;

  FDiaporamaCenterAgent := aDiaporamaCenterAgent;
  FDiaporamaCenterSettings :=
    TDiaporamaCenterAgent(FDiaporamaCenterAgent).Settings;

  FDownloader := CreateDownloader(dtHttp, FDiaporamaCenterSettings);

  FDiaporamaResources := TObjectList<TDiaporamaResource>.Create(False);

  RegisterInSchedule;

  FStatus := dlsIdle;
end;

destructor TDiaporamaDownloader.Destroy;
begin
  StopDownloadDiaporamaResources;

  FDiaporamaResources.Free;
  FDownloader.Free;

  UnregisterFromSchedule;

  FThreadLink.Free;

  inherited;
end;

procedure TDiaporamaDownloader.RegisterInSchedule;
begin
  if Assigned(FDiaporamaCenterAgent) and
    (FDiaporamaCenterAgent is TDiaporamaCenterAgent) then
    TDiaporamaCenterAgent(FDiaporamaCenterAgent).Scheduler.RegisterSource(Self);
end;

procedure TDiaporamaDownloader.UnregisterFromSchedule;
begin
  if Assigned(FDiaporamaCenterAgent) and
    (FDiaporamaCenterAgent is TDiaporamaCenterAgent) then
    TDiaporamaCenterAgent(FDiaporamaCenterAgent).Scheduler.UnregisterSource(Self);
end;

function TDiaporamaDownloader.GetDiaporamaFilePath: string;
begin
  if Assigned(FRepository) then
    Result := TDiaporamaRepository(FRepository).GetDiaporamaPath(FDiaporama.ID)
  else
    Result := '';
end;

function TDiaporamaDownloader.GetDownloadStatusMediaCount(
  const aDownloadStatus: TDownloadStatus): Integer;
var
  diaporamaResource: TDiaporamaResource;
begin
  Result := 0;
  for diaporamaResource in FDiaporamaResources do
  begin
    if diaporamaResource.DownloadStatus = aDownloadStatus then
      Inc(Result);
  end;
end;

function TDiaporamaDownloader.DownloadDiaporama: Boolean;
var
  diaporamaFilePath: string;
begin
  diaporamaFilePath := GetDiaporamaFilePath;

  if Assigned(FDiaporama) and (FDiaporama.ID<>'') and (diaporamaFilePath<>'') then
  begin
    LogEvent(Self.ClassName, ltInformation,
      Format(cstDownloadDiaporamaMsg, [FDiaporama.ID]));

    Result := FDownloader.DownloadDiaporama(FDiaporama.ID, diaporamaFilePath);
  end else
    Result := false;
end;

procedure TDiaporamaDownloader.PrepareResourceDownloadList;
var
  aRepository: TDiaporamaRepository;
  diapositiveList: TEnumerable<TDiapositive>;
  aDiapositive: TDiapositive;
  aResource: TDiaporamaResource;
  diapositiveTypeList: TEnumerable<TDiapositiveType>;
  aDiapositiveType: TDiapositiveType;
begin
  Assert(Assigned(FRepository) and (FRepository is TDiaporamaRepository));
  Assert(Assigned(FDiaporama));

  aRepository := TDiaporamaRepository(FRepository);

  LogEvent(Self.ClassName, ltInformation,
    Format(cstPrepareDownloadMsg, [FDiaporama.Name, FDiaporama.ID]));

  FDiaporamaResources.Clear;

  diapositiveList := nil;
  diapositiveTypeList := nil;
  try
    // Resources for each diapositive type
    diapositiveTypeList := FDiaporama.GetAllDiapositiveTypes;

    for aDiapositiveType in diapositiveTypeList do
    begin
      for aResource in aDiapositiveType.TemplateResources do
      begin
        if aResource.ID<>'' then
          FDiaporamaResources.Add(aResource);
      end;
    end;

    // Resources for each diapositive
    diapositiveList := FDiaporama.GetAllDiapositives;

    for aDiapositive in diapositiveList do
    begin
      for aResource in aDiapositive.Medias do
      begin
        if aResource.ID<>'' then
        begin
          FDiaporamaResources.Add(aResource);
        end;
      end;
    end;

    for aResource in FDiaporamaResources do
    begin
      // FIXME : manage date : download if file too old
      if FileExists(aRepository.getResourceFilePath(aResource)) then
        aResource.DownloadStatus := dsSucceeded
      else
        aResource.DownloadStatus := dsQueued;
    end;

  finally
    diapositiveTypeList.Free;
    diapositiveList.Free;
  end;
end;

procedure TDiaporamaDownloader.ThreadDownloadResourceList;
var
  aRepository: TDiaporamaRepository;
  aResource: TDiaporamaResource;
  i: Integer;
  downloaded: Boolean;
begin
  Assert(Assigned(FRepository) and (FRepository is TDiaporamaRepository));
  Assert(Assigned(FDiaporama));

  aRepository := TDiaporamaRepository(FRepository);

  FStatus := dlsDownloading;

  i := 0;
  while (i<FDiaporamaResources.Count) and not FThreadLink.Terminated do
  begin
    aResource := TDiaporamaResource(FDiaporamaResources[i]);

    if aResource.DownloadStatus=dsQueued then
    begin
      downloaded := FDownloader.DownloadResource(aResource,
        aRepository.getResourceFilePath(aResource));

      // TODO : several download attempt
      if downloaded then
        aResource.DownloadStatus := dsSucceeded
      else
        aResource.DownloadStatus := dsFailed;
    end;

    // TODO : The system must not standby while downloading
    //SetThreadExecutionState(ES_SYSTEM_REQUIRED);

    Inc(i);
  end;

  FStatus := dlsIdle;
end;

procedure TDiaporamaDownloader.DownloadDiaporamaResources;
begin
  Assert(Assigned(FRepository) and (FRepository is TDiaporamaRepository));
  Assert(Assigned(FDiaporama));

  PrepareResourceDownloadList;

  // Thread start
  if FThreadLink.Finished then
  begin
    FThreadLink.Free;
    FThreadLink := TThreadLink.Create(self);
  end;
  FThreadLink.Resume;
end;

function TDiaporamaDownloader.LoadDiaporama: Boolean;
var
  diaporamaFilePath: string;
  inRepository: boolean;
begin
  if FStatus=dlsDownloading then
  begin
    Result := True;
    Exit;
  end;

  Result := False;
  
  diaporamaFilePath := GetDiaporamaFilePath;
  if diaporamaFilePath='' then
    Exit;

  // Downloads diaporama if not in cache
  if FileExists(diaporamaFilePath) then
  begin
    inRepository := True
  end else
  begin
    inRepository := DownloadDiaporama;
    // TODO : manage download error
  end;

  if inRepository then
  begin
    LogEvent(Self.ClassName, ltInformation,
      Format(cstLoadingDiaporamaMsg, [FDiaporama.Name, FDiaporama.ID]));

    // TODO : vérifier si le diaporama ne devrait pas etre mise à jour (date)
    if FDiaporama.LoadFromXML(diaporamaFilePath) then
    begin
      LogEvent(Self.ClassName, ltInformation,
        Format(cstDiaporamaLoadedMsg, [FDiaporama.ID]));

      // Now download media files
      DownloadDiaporamaResources;

      Result := True;
    end else
      LogEvent(Self.ClassName, ltError,
        Format(cstDiaporamaLoadError, [FDiaporama.ID]));
  end;
end;

procedure TDiaporamaDownloader.PurgeDiapositive(const aDiapositive: TDiapositive);
var
  aRepository: TDiaporamaRepository;
  aResource: TDiaporamaResource;
begin
  Assert(Assigned(FRepository) and (FRepository is TDiaporamaRepository));
  aRepository := TDiaporamaRepository(FRepository);

  if not Assigned(aDiapositive) then
    Exit;

  DeleteFile(aRepository.getDiapositiveFilePath(aDiapositive));

  for aResource in aDiapositive.Medias do
  begin
    DeleteFile(aRepository.getResourceFilePath(aResource));
  end;
end;

procedure TDiaporamaDownloader.PurgeDiaporama;
var
  diapositiveList: TEnumerable<TDiapositive>;
  aDiapositive: TDiapositive;
  diapositiveTypeList: TEnumerable<TDiapositiveType>;
  aDiapositiveType: TDiapositiveType;
  aRepository: TDiaporamaRepository;
  aResource: TDiaporamaResource;
begin
  Assert(Assigned(FRepository) and (FRepository is TDiaporamaRepository));
  aRepository := TDiaporamaRepository(FRepository);
  if not Assigned(FDiaporama) then
    Exit;

  diapositiveList := nil;
  diapositiveTypeList := nil;
  try
    diapositiveList := FDiaporama.GetAllDiapositives;
    for aDiapositive in diapositiveList  do
    begin
      PurgeDiapositive(aDiapositive);
    end;

    diapositiveTypeList := FDiaporama.GetAllDiapositiveTypes;
    for aDiapositiveType in diapositiveTypeList  do
    begin
      for aResource in aDiapositiveType.TemplateResources do
      begin
        DeleteFile(aRepository.getResourceFilePath(aResource));
      end;
    end;

  finally
    diapositiveList.Free;
    diapositiveTypeList.Free;
  end;
end;

function TDiaporamaDownloader.UpdateDiaporama: Boolean;
begin
  // Stop download
  StopDownloadDiaporamaResources;

  // Deletes diaporama XML
  // TODO : diaporama backup
  if GetDiaporamaFilePath<>'' then
    DeleteFile(GetDiaporamaFilePath);

  // Delete all diaporama stuff
  PurgeDiaporama;

  Result := LoadDiaporama;
end;

procedure TDiaporamaDownloader.OnTerminateExecute;
begin
  //FThreadLink := nil;
  FStatus := dlsIdle;
end;

procedure TDiaporamaDownloader.Execute;
begin
  coInitializeEx(nil, COINIT_APARTMENTTHREADED);

  ThreadDownloadResourceList;

  CoUninitialize;
end;

procedure TDiaporamaDownloader.StopDownloadDiaporamaResources;
begin
  if (FStatus=dlsDownloading) then
  begin
    //if Assigned(FThreadLink) and not FThreadLink.Terminated then
    if not FThreadLink.Terminated then
    begin
      FThreadLink.Terminate;
      FThreadLink.WaitTerminate(2000);
    end else
      FStatus := dlsIdle;
  end;
end;

function TDiaporamaDownloader.GetSourceName: string;
begin
  if Assigned(FDiaporama) then
    Result := Format('Diaporama %s downloader', [FDiaporama.ID])
  else
    Result := 'Downloader';
end;

function TDiaporamaDownloader.GetDefaultAction(const actionCode: Integer): TScheduleAction;
begin
  Result := TScheduleAction.CreateAction(Self, ACT_UPDATE_DIAPORAMA,
    apEveryHour, StrToTime('00:00'), False);
end;

function TDiaporamaDownloader.GetActionName(
  const aScheduleAction: TScheduleAction): string;
begin
  if Assigned(aScheduleAction) then
  begin
    case aScheduleAction.Action of
      ACT_UPDATE_DIAPORAMA :
        begin
          if Assigned(FDiaporama) then
            Result := Format('Update diaporama ''%s'' (ID = %s)',
              [FDiaporama.Name, FDiaporama.ID])
          else
            Result := '';
        end
    else
      Result := '';
    end;
  end else
    Result := '';
end;

procedure TDiaporamaDownloader.CheckActions(const actions: TObjectList<TScheduleAction>);
begin
  if not ConnectedToInternet then
    actions.Clear;
end;

function TDiaporamaDownloader.ExecuteAction(
  const aScheduleAction: TScheduleAction): Boolean;
begin
  if Assigned(aScheduleAction) then
  begin
    case aScheduleAction.Action of
      ACT_UPDATE_DIAPORAMA : Result := UpdateDiaporama;
    else
      Result := False;
    end;
  end else
    Result := False;
end;

function TDiaporamaDownloader.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := -1;
end;

function TDiaporamaDownloader._AddRef: Integer;
begin
  Result := -1;
end;

function TDiaporamaDownloader._Release: Integer;
begin
  Result := -1;
end;


end.
