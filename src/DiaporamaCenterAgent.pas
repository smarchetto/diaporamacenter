unit DiaporamaCenterAgent;

interface

uses
  Generics.Defaults, Generics.Collections, Classes,
  DiaporamaCenterSettings, DiaporamaDevice, DiaporamaDeviceSettings,
  DiaporamaPlayer, DiaporamaRepository,
  DiapositiveType, DiaporamaDownloader, HttpDownloader, DisplayMode,
  ThreadIntf, DiaporamaScheduler, ScheduleAction;

type
  // Main class of DiaporamaCenter
  TDiaporamaCenterAgent = class(TObject, IScheduleSource)
  private
    // General settings
    FSettings: TDiaporamaCenterSettings;

    // Display devices
    FDiaporamaDevices: TObjectList<TDiaporamaDevice>;

    // Device settings
    FDeviceSettings: TObjectList<TDiaporamaDeviceSettings>;

    // Lecteurs
    FDiaporamaPlayers: TObjectList<TDiaporamaPlayer>;

    // Cache
    FRepository: TDiaporamaRepository;

    // Programmateur
    FScheduler: TDiaporamaScheduler;

    function GetDiaporamaDevice(const index: Integer): TDiaporamaDevice;
    function GetDiaporamaDeviceCount: Integer;

    function GetDeviceSettings(const index: Integer): TDiaporamaDeviceSettings;
    function GetDeviceSettingCount: Integer;

    function GetDiaporamaPlayer(const index: Integer): TDiaporamaPlayer;
    function GetDiaporamaPlayerCount: Integer;

    function GetDevicePath: string;
    function GetTemplatePath: string;

  public
    constructor Create(const aPath: string);
    destructor Destroy; override;

    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    procedure CheckPrerequisities;
    procedure Init;
    procedure Finalize;

    // Load&Save display device settings
    procedure LoadAllDeviceSettings;
    procedure LoadDeviceSettings(const filePath: string);
    procedure SaveDeviceSettings(const diaporamaDeviceIdx: Integer);

    // Detection/configuration display devices
    procedure DetectDiaporamaDevices;
    procedure ConfigureDevices;

    // Play diaporama
    procedure PlayDiaporama(const diaporamaID: string;
      const DiaporamaDeviceIdx: Integer;
      const defaultDiapositiveDuration: Integer);
    procedure StopDiaporama(const DiaporamaDeviceIdx: Integer);

    // IScheduleSource
    function GetSourceName: string;
    function GetDefaultAction(const actionCode: Integer): TScheduleAction;
    function GetActionName(const aScheduleAction: TScheduleAction): string;
    procedure CheckActions(const actions: TObjectList<TScheduleAction>);
    function ExecuteAction(const aScheduleAction: TScheduleAction): Boolean;

    property Settings: TDiaporamaCenterSettings read FSettings;

    property DeviceSettings[const index: Integer]: TDiaporamaDeviceSettings
      read GetDeviceSettings;
    property DeviceSettingCount: Integer read GetDeviceSettingCount;

    property DiaporamaDeviceCount: Integer read GetDiaporamaDeviceCount;
    property DiaporamaDevice[const index: Integer]: TDiaporamaDevice
      read GetDiaporamaDevice;

    property Repository: TDiaporamaRepository read FRepository;

    property DiaporamaPlayer[const index: Integer]: TDiaporamaPlayer
      read GetDiaporamaPlayer;
    property DiaporamaPlayerCount: Integer read GetDiaporamaPlayerCount;

    property Scheduler: TDiaporamaScheduler read FScheduler;
  end;

function CreateDiaporamaCenterAgent: TDiaporamaCenterAgent;

const
  ACT_POWER_ON_ALL_DEVICES  = 0;
  ACT_POWER_OFF_ALL_DEVICES = 1;

implementation

uses
  ActiveX, Forms, SysUtils, MSXML2_TLB, Windows, ComObj, Dialogs,
  Logs, DiaporamaDeviceInfo, DiaporamaUtils;

const
  cstDeviceDetectionMsg
    = '%d detected display devices';
  cstDeviceSettingsLoadingMsg
    = 'Load display devices configurations';
  cstDeviceConfigurationMsg
    = 'Configure the display devices';
  cstShedulerConfigurationMsg
    = 'Configure scheduler';
  cstDeviceInfoMsg = 'Display device <%d> properties:'
    + #13#10 + 'Model name: %s'
    + #13#10 + 'Manufacturer: %s'
    + #13#10 + 'Serial number: %s';
  cstDisplayModeMsg =
    'Display device ''%s'' current display mode: %dx%d - %d bits - %d Hz';
  cstMatchedDeviceSettingsMsg =
  'Device ''%s'' configuration files: %s';

function CreateDiaporamaCenterAgent: TDiaporamaCenterAgent;
var
  path: string;
begin
  Result := nil;
  path := ExtractFileDir(Application.ExeName);
  Result := TDiaporamaCenterAgent.Create(path);
  try
    Result.Init;
  except
    on e: Exception do
    begin
      MessageDlg(e.Message, mtError, [mbOK], 0);
      FreeAndNil(Result);
    end;
  end;
end;

constructor TDiaporamaCenterAgent.Create(const aPath: string);
begin
  FSettings := TDiaporamaCenterSettings.Create(aPath);
  FRepository := TDiaporamaRepository.Create(Self);
  FDiaporamaDevices := TObjectList<TDiaporamaDevice>.Create;
  FDeviceSettings := TObjectList<TDiaporamaDeviceSettings>.Create;
  FDiaporamaPlayers := TObjectList<TDiaporamaPlayer>.Create;
  FScheduler := TDiaporamaScheduler.Create(Self);
end;

procedure TDiaporamaCenterAgent.CheckPrerequisities;
begin
  // Check MSXML4 is installed
  try
    CoDOMDocument40.Create;
  except
    raise Exception.Create(
      'DiaporamaCenter needs MSXML4 to run.' + #13#10
      + 'Please install ''mxsml4cab.exe'' that can be found in application folder.');
  end;
end;

procedure TDiaporamaCenterAgent.Init;
var
  aDiaporamaPlayer: TDiaporamaPlayer;
  i: Integer;
begin
  // Initiliaze COM
  CoInitializeEx(nil, COINIT_APARTMENTTHREADED);

  // Check MSXML4...
  CheckPrerequisities;

  // Logs
  // TODO : choose log level in init
  InitializeLog(3);

  if IsRemoteSession then
    LogEvent(Self.ClassName, ltInformation,
    'Remote desktop detected');

  // Load settings
  try
    FSettings.LoadSettings;
  except
    on e: Exception do
      LogEvent(FSettings.ClassName, ltError, e.Message);
  end;

  // Detect, load and configure display devices
  DetectDiaporamaDevices;
  LoadAllDeviceSettings;
  ConfigureDevices;

  // Init players
  for i := 0 to DiaporamaDeviceCount-1 do
  begin
    aDiaporamaPlayer := TDiaporamaPlayer.Create(DiaporamaDevice[i],
      FRepository, Self);
    FDiaporamaPlayers.Add(aDiaporamaPlayer);
  end;

  // Load or download diaporama list
  FRepository.LoadDiaporamaList;

  // Create downloaders
  FRepository.CreateDiaporamaDownloaders;

  // Load list of templates
  TDiapositiveType.TemplatePath := GetTemplatePath;
  TDiapositiveType.LoadTypeListFromXML(FSettings.TypeFilePath);

  // Schedule ourself
  Scheduler.RegisterSource(Self);

  // Load schedule
  FScheduler.LoadFromXML(FSettings.ScheduleFilePath);
  FScheduler.Resume;

  LogEvent(Self.ClassName, ltInformation,
    'DiaporamaCenter successfully initialized');
end;

procedure TDiaporamaCenterAgent.Finalize;
begin
  FDiaporamaDevices.Clear;
  FDeviceSettings.Clear;
  FDiaporamaPlayers.Clear;

  LogEvent(Self.ClassName, ltInformation,
    'DiaporamaCenter sucessfully finalized');

  CoUninitialize;
end;

destructor TDiaporamaCenterAgent.Destroy;
begin
  TDiapositiveType.ReleaseTypeList;

  FRepository.Free;
  FDiaporamaDevices.Free;
  FDeviceSettings.Free;
  FDiaporamaPlayers.Free;
  FSettings.Free;

  inherited;
end;

function TDiaporamaCenterAgent.GetDiaporamaDevice(const index: Integer): TDiaporamaDevice;
begin
  Result := FDiaporamaDevices[index]
end;

function TDiaporamaCenterAgent.GetDiaporamaDeviceCount: Integer;
begin
  Result := FDiaporamaDevices.Count;
end;

function TDiaporamaCenterAgent.GetDeviceSettings(
  const index: Integer): TDiaporamaDeviceSettings;
begin
  Result := FDeviceSettings[index]
end;

function TDiaporamaCenterAgent.GetDeviceSettingCount: Integer;
begin
  Result := FDeviceSettings.Count;
end;

function TDiaporamaCenterAgent.GetDiaporamaPlayer(const index: Integer): TDiaporamaPlayer;
begin
  Result := FDiaporamaPlayers[index]
end;

function TDiaporamaCenterAgent.GetDiaporamaPlayerCount: Integer;
begin
  Result := FDiaporamaPlayers.Count;
end;

function TDiaporamaCenterAgent.GetDevicePath: string;
begin
  Result := FSettings.DevicePath;

  if (Result<>'') and not DirectoryExists(Result) then
    ForceDirectories(Result);
end;

function TDiaporamaCenterAgent.GetTemplatePath: string;
begin
  Result := FSettings.TemplatePath;

  if (Result<>'') and not DirectoryExists(Result) then
    ForceDirectories(Result);
end;

procedure TDiaporamaCenterAgent.SaveDeviceSettings(const diaporamaDeviceIdx: Integer);
var
  aDiaporamaDevice: TDiaporamaDevice;
begin
  aDiaporamaDevice := DiaporamaDevice[diaporamaDeviceIdx];
  if Assigned(aDiaporamaDevice) then
  begin
    aDiaporamaDevice.Settings.DeviceInfo.Assign(aDiaporamaDevice.DeviceInfo);
    aDiaporamaDevice.Settings.SaveToXML(FSettings.DevicePath +
      aDiaporamaDevice.GetSettingFileName);
  end;
end;

procedure TDiaporamaCenterAgent.LoadDeviceSettings(const filePath: string);
var
  deviceSettings: TDiaporamaDeviceSettings;
begin
  deviceSettings := TDiaporamaDeviceSettings.Create;
  if deviceSettings.LoadFromXML(filePath) then
    FDeviceSettings.Add(deviceSettings);
end;

procedure TDiaporamaCenterAgent.LoadAllDeviceSettings;
var
  sr: TSearchRec;
begin
  LogEvent(Self.ClassName, ltInformation, cstDeviceSettingsLoadingMsg);
  FDeviceSettings.Clear;
  try
    if FindFirst(GetDevicePath + '*.xml', faAnyFile, sr)=0 then
    begin
      LoadDeviceSettings(GetDevicePath + sr.Name);
      while FindNext(sr)=0 do
        LoadDeviceSettings(GetDevicePath + sr.Name);
    end;
  finally
    SysUtils.FindClose(sr);
  end;
end;

procedure TDiaporamaCenterAgent.DetectDiaporamaDevices;
var
  i: Integer;
  aDiaporamaDevice: TDiaporamaDevice;
  displayMode: TDisplayMode;
begin
  LogEvent(Self.ClassName, ltInformation,
    Format(cstDeviceDetectionMsg, [Screen.MonitorCount]));
  FDiaporamaDevices.Clear;
  for i := 0 to Screen.MonitorCount-1 do
  begin
    aDiaporamaDevice := TDiaporamaDevice.Create(Self);
    aDiaporamaDevice.Monitor := Screen.Monitors[i];

    // Check device is active display
    if aDiaporamaDevice.CheckDevice then
    begin
      aDiaporamaDevice.DeviceIndex := FDiaporamaDevices.Count+1;
      FDiaporamaDevices.Add(aDiaporamaDevice);

      // Get device infos (manufacturer, model, serial...)
      if aDiaporamaDevice.FindDeviceInfo then
      begin
        LogEvent(Self.ClassName, ltInformation,
          Format(cstdeviceInfoMsg, [i, aDiaporamaDevice.DeviceInfo.Model,
            aDiaporamaDevice.DeviceInfo.Manufacturer,
            aDiaporamaDevice.DeviceInfo.Serial]));
      end;

      displayMode := aDiaporamaDevice.DisplayMode;
      if Assigned(displayMode) then
      begin
        LogEvent(Self.ClassName, ltInformation,
          Format(cstDisplayModeMsg, [aDiaporamaDevice.Name,
            displayMode.Width, displayMode.Height,
            displayMode.BitsPerPixel, displayMode.Frequency]));
      end;
        //LogEvent(Self.ClassName, ltInformation,
        //  Format(cstdeviceIgnoredMsg, [i, aDiaporamaDevice.Name]));
    end else
    begin
      //LogEvent(Self.ClassName, ltInformation,
      //  Format(cstdeviceIgnoredMsg, [i, aDiaporamaDevice.Name]));
      aDiaporamaDevice.Free;
    end;
  end;
end;

procedure TDiaporamaCenterAgent.ConfigureDevices;
var
  aDiaporamaDevice: TDiaporamaDevice;
  settings, foundSettings: TDiaporamaDeviceSettings;
  match, matchMax: Integer;
  defaultFileName, aStr: string;
begin
  LogEvent(Self.ClassName, ltInformation, cstDeviceConfigurationMsg);

  for aDiaporamaDevice in FDiaporamaDevices do
  begin
    matchMax := 0;
    foundSettings := nil;
    defaultFileName := Format('DEVICE%d.xml', [aDiaporamaDevice.DeviceIndex]);
    aStr := '';
    for settings in FDeviceSettings do
    begin
      match := aDiaporamaDevice.DeviceInfo.Matchs(settings.DeviceInfo);
      if (match>matchMax) or SameStr(settings.FileName, defaultFileName) then
      begin
        if not Assigned(foundSettings) then
          foundSettings := settings;

        aStr := aStr + #13#10;

        if match>matchMax then
        begin
          matchMax := match;
          aStr := aStr + Format('%s (%d)', [foundSettings.FileName, match]);
        end else
        begin
          aStr := aStr + Format('%s (has priority)', [foundSettings.FileName]);
          break;
        end;
      end;
    end;

    if Assigned(foundSettings) then
    begin
      LogEvent(Self.ClassName, ltInformation,
        Format(cstMatchedDeviceSettingsMsg, [aDiaporamaDevice.Name, aStr]));
    end;

    // TODO : bug : informations are on bad tab ?
    aDiaporamaDevice.Configure(foundSettings);
  end;
end;

procedure TDiaporamaCenterAgent.PlayDiaporama(const diaporamaID: string;
  const DiaporamaDeviceIdx: Integer;
  const defaultDiapositiveDuration: Integer);
var
  aPlayer: TDiaporamaPlayer;
begin
  if diaporamaID<>'' then
  begin
    // TODO : device and player have same index ?
    aPlayer := GetDiaporamaPlayer(DiaporamaDeviceIdx);

    if Assigned(aPlayer) then
    begin
      aPlayer.DefaultDiapositiveDuration := defaultDiapositiveDuration;
      aPlayer.PlayDiaporama(diaporamaID);
    end;
  end;
end;

procedure TDiaporamaCenterAgent.StopDiaporama(const DiaporamaDeviceIdx: Integer);
var
  aPlayer: TDiaporamaPlayer;
begin
  aPlayer := GetDiaporamaPlayer(DiaporamaDeviceIdx);
  if Assigned(aPlayer) then
    aPlayer.Stop(True);
end;

{procedure TDiaporamaCenterAgent.HandleMessage(var aMessage: TMessage);
var
  aScheduleAction: TScheduleAction;
begin
  aScheduleAction := TScheduleAction(aMessage.LParam);
  FScheduler.ExecuteAction(aScheduleAction);
end;}

procedure TDiaporamaCenterAgent.CheckActions(const actions: TObjectList<TScheduleAction>);
begin
  if actions.Count=2 then
    actions.Delete(0);
end;

function TDiaporamaCenterAgent.ExecuteAction(
  const aScheduleAction: TScheduleAction): Boolean;
begin
  if Assigned(aScheduleAction) then
  begin
    case aScheduleAction.Action of
      ACT_POWER_ON_ALL_DEVICES  : Result := TDiaporamaDevice.PowerOnAllDevices;
      ACT_POWER_OFF_ALL_DEVICES : Result := TDiaporamaDevice.PowerOffAllDevices;
    else
      Result := False;
    end;
  end else
    Result := False;
end;

function TDiaporamaCenterAgent.GetDefaultAction(const actionCode: Integer): TScheduleAction;
begin
  case actionCode of
    ACT_POWER_ON: Result := TScheduleAction.CreateAction(Self,
      ACT_POWER_ON_ALL_DEVICES, apEveryDay, StrToTime('08:00'), False);
    ACT_POWER_OFF: Result := TScheduleAction.CreateAction(Self,
      ACT_POWER_OFF_ALL_DEVICES, apEveryDay, StrToTime('23:00'), False);
  else
    Result := nil;
  end;
end;

function TDiaporamaCenterAgent.GetActionName(
  const aScheduleAction: TScheduleAction): string;
begin
  if Assigned(aScheduleAction) then
  begin
    case aScheduleAction.Action of
       ACT_POWER_ON_ALL_DEVICES  :
        Result := 'Power on all display devices';
      ACT_POWER_OFF_ALL_DEVICES :
        Result := 'Power off all display devices';
    else
      Result := '';
    end;
  end else
    Result := '';
end;

function TDiaporamaCenterAgent.GetSourceName: string;
begin
  Result := 'DiaporamaCenterAgent';
end;

function TDiaporamaCenterAgent.QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
begin
  Result := -1;
end;

function TDiaporamaCenterAgent._AddRef: Integer; stdcall;
begin
  Result := -1;
end;

function TDiaporamaCenterAgent._Release: Integer; stdcall;
begin
  Result := -1;
end;


end.

