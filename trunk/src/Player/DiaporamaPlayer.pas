unit DiaporamaPlayer;

interface

uses
  Classes, Generics.Defaults, Generics.Collections,
  DiaporamaForm, Diaporama, DiaporamaDevice, DiaporamaRepository,
  DiaporamaSequenceItem, ThreadIntf, ScheduleAction;

type
  TDiapositiveStatus = (dsPreparing, dsPrepared, dsError);

  TDiaporamaPlayerStatus = (dpsIdle, dpsReady, dpsPlaying, dpsSuspended);

  // Plays a diaporama on a device
  TDiaporamaPlayer = class(TObject, IScheduleSource, IThread)
  private
    FDiaporamaCenterAgent: TObject;
    // Diaporama to be played
    FDiaporama: TDiaporama;
    // Playing sequence settings
    FDiaporamaSequenceItem: TDiaporamaSequenceItem;
    // Enumerates all diapositives given the sequence settings
    FDiaporamaEnumerator: TDiaporamaEnumerator;
    // Form in which diapositives are displayed
    FDiaporamaForm: TDiaporamaForm;
    // Device on which diapositives are displayed
    FDiaporamaDevice: TDiaporamaDevice;
    // Diaporama repository
    FRepository: TDiaporamaRepository;
    // Time counter
    FTime: TDateTime;
    // Status
    FPlayerStatus: TDiaporamaPlayerStatus;
    // Current diapositive status
    FDiapositiveStatus: TDiapositiveStatus;
    // Thread used to play
    FThreadLink: TThreadLink;
    // Default diapositive duration
    FDefaultDiapositiveDuration: Integer;

    // Assign a device to that player
    procedure SetDiaporamaDevice(const aDiaporamaDevice: TDiaporamaDevice);

    // Prepare a diapositive
    procedure PrepareDiapositive;

    // Configure display device (resolution...)
    procedure ConfigureDiaporamaDevice;

    // Set window position on display device
    procedure PlacePlayer;

    // Returns current diapositive duration
    function CurrentDiapositiveDuration: Integer;
    //procedure SetDiapositiveDuration(const aValue: Integer);

    function DisplayTimeElapsed: Boolean;

    procedure RegisterInSchedule;

    // Set default diapositive duration (sec)
    procedure SetDefaultDiapositiveDuration(const duration: Integer);
  public
    constructor Create(const aDiaporamaDevice: TDiaporamaDevice;
      const aRepository: TDiaporamaRepository;
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

    // Full reset
    procedure Reset;

    // Loads a diaporama
    function LoadDiaporama(const diaporamaID: string): Boolean;

    // Paramétrage de lecture du diaporama
    procedure SetPlayMode;

    // Start playing (run the thread)
    procedure Play;
    // Stop the play
    function Stop(const closeForm: Boolean): Boolean;

    function PlayDiaporama(const diaporamaID: string): Boolean;

    procedure OnFormCloseExecute(Sender: TObject);
    procedure OnFormChangeExecute(Sender: TObject);

    property DiaporamaDevice: TDiaporamaDevice read FDiaporamaDevice
      write SetDiaporamaDevice;

    property DefaultDiapositiveDuration: Integer read FDefaultDiapositiveDuration
      write SetDefaultDiapositiveDuration;

    property PlayerStatus: TDiaporamaPlayerStatus read FPlayerStatus;
  end;

const
  ACT_PLAy_DIAPORAMA = 0;
  ACT_STOP_DIAPORAMA = 1;

  cstDiaporamaIDParam = 'diaporamaID';
  cstDurationParam = 'diapositiveDuration';

implementation

uses
  SysUtils, ActiveX, DateUtils,
  Diapositive, DiaporamaCenterAgent, SequenceItem, Logs, DiaporamaUtils;

const
  DELTA_TIME = 1000;

  cstPlayingDiaporamaMsg =
    'Play diaporama ''%s'' on display device ''%s''';
  cstPreparingDiapositiveMsg =
    'Diaporama %s : preparation of slide ''%s'' (type ''%s'')';
  cstDiapositiveNoContentError =
    'Slide of ID ''%s'' and type ''%s'' has no content';
  cstDiapositiveTypeNotFoundError =
    'Cannot find type ''%s'' of slide of ID ''%s''';

constructor TDiaporamaPlayer.Create(const aDiaporamaDevice: TDiaporamaDevice;
  const aRepository: TDiaporamaRepository;
  const aDiaporamaCenterAgent: TObject);
begin
  FThreadLink := TThreadLink.Create(Self);

  FDiaporamaDevice := aDiaporamaDevice;

  FRepository := aRepository;

  FDiaporamaForm := TDiaporamaForm.CreateNew(nil);
  FDiaporamaForm.InitialFullScreen := aDiaporamaDevice.Settings.FullScreen;
  FDiaporamaForm.OnChange := OnFormChangeExecute;
  FDiaporamaForm.OnClose := OnFormCloseExecute;

  FDiaporama := nil;
  FDiaporamaSequenceItem := nil;
  FDiaporamaEnumerator := nil;

  FPlayerStatus := dpsIdle;

  FDiaporamaDevice.DiaporamaPlayer := Self;

  SetDefaultDiapositiveDuration(DIAPOSITIVE_DURATION_S);

  FTime := 0;

  FDiaporamaCenterAgent := aDiaporamaCenterAgent;
  RegisterInSchedule;
end;

destructor TDiaporamaPlayer.Destroy;
begin
  Stop(True);

  FDiaporamaForm.Free;
  FDiaporamaSequenceItem.Free;
  FDiaporamaEnumerator.Free;

  FThreadLink.Free;

  inherited;
end;

procedure TDiaporamaPlayer.RegisterInSchedule;
begin
    // Shedule ourself in schedule
  if Assigned(FDiaporamaCenterAgent) and
    (FDiaporamaCenterAgent is TDiaporamaCenterAgent) then
    TDiaporamaCenterAgent(FDiaporamaCenterAgent).Scheduler.RegisterSource(Self);
end;

procedure TDiaporamaPlayer.Reset;
begin
  if FPlayerStatus<>dpsIdle then
  begin
    if (FPlayerStatus=dpsPlaying) or (FPlayerStatus=dpsSuspended) then
      Stop(True);

    FreeAndNil(FDiaporamaEnumerator);
    FreeAndNil(FDiaporamaSequenceItem);

    FPlayerStatus := dpsIdle;
  end;
end;

procedure TDiaporamaPlayer.SetDiaporamaDevice(const aDiaporamaDevice: TDiaporamaDevice);
begin
  // TODO : change monitor while playing
  if (FPlayerStatus = dpsIdle) or (FPlayerStatus = dpsReady) then
  begin
    if Assigned(aDiaporamaDevice) and (FDiaporamaDevice<>aDiaporamaDevice) then
    begin
      FDiaporamaDevice := aDiaporamaDevice;

      PlacePlayer;
    end;
  end;
end;

procedure TDiaporamaPlayer.ConfigureDiaporamaDevice;
begin
  if (FPlayerStatus = dpsIdle) or (FPlayerStatus = dpsReady) then
  begin
    if Assigned(FDiaporamaDevice) then
    begin
      // Set display mode
      FDiaporamaDevice.DisplayMode := FDiaporamaDevice.Settings.DisplayMode;
    end;
  end;
end;

procedure TDiaporamaPlayer.PlacePlayer;
begin
  if Assigned(FDiaporamaDevice) then
  begin
    // Assign window to monitor
    FDiaporamaForm.SetMonitor(FDiaporamaDevice.Monitor);
  end;
end;

procedure TDiaporamaPlayer.SetPlayMode;
begin
  // Default play sequence
  FDiaporamaSequenceItem := TDiaporamaSequenceItem.Create('', 1, -1, soNormal);
end;

function TDiaporamaPlayer.PlayDiaporama(const diaporamaID: string): Boolean;
begin
  Result := False;
  if LoadDiaporama(diaporamaID) then
  begin
    SetPlayMode;
    Play;
    Result := True;
  end;
end;

function TDiaporamaPlayer.LoadDiaporama(const diaporamaID: string): Boolean;
begin
  Result := False;
  if diaporamaID='' then
    Exit;

  // Player ready to load a diaporama ?
  if (FPlayerStatus=dpsIdle) or (FPlayerStatus=dpsReady) then
  begin
    if FPlayerStatus<>dpsIdle then
      Reset;

    // FIXME : do we have to reload diaporama or not ?
    FDiaporama := FRepository.LoadDiaporama(diaporamaID);

    if Assigned(FDiaporama) then
    begin
      FPlayerStatus := dpsReady;

      Result := True;
    end;
  end;
end;

procedure TDiaporamaPlayer.Play;
begin
  if (FPlayerStatus=dpsReady) or (FPlayerStatus=dpsSuspended) then
  begin
    if FPlayerStatus=dpsReady then
    begin
      if not Assigned(FDiaporamaSequenceItem) then
        SetPlayMode;

      FDiaporamaEnumerator :=
        TDiaporamaEnumerator(FDiaporamaSequenceItem.GetEnumerator(FDiaporama));

      // Configure display device
      ConfigureDiaporamaDevice;

      // Place player window
      PlacePlayer;

      FDiaporamaForm.Show;

      LogEvent(Self.ClassName, ltInformation,
        Format(cstPlayingDiaporamaMsg, [FDiaporama.Name, FDiaporamaDevice.Name]));
    end;

    FPlayerStatus := dpsPlaying;

    // Start thread
    if FThreadLink.Finished then
    begin
      FThreadLink.Free;
      FThreadLink := TThreadLink.Create(self);
    end;
    FThreadLink.Resume;
  end;
end;

procedure TDiaporamaPlayer.OnFormCloseExecute(Sender: TObject);
begin
  Stop(False);
end;

procedure TDiaporamaPlayer.OnTerminateExecute;
begin
  // TODO : STOPPED state ?
  FPlayerStatus := dpsReady;
end;

function TDiaporamaPlayer.Stop(const closeForm: Boolean): Boolean;
begin
  if (FPlayerStatus=dpsPlaying) or (FPlayerStatus=dpsSuspended) then
  begin
    //if Assigned(FThreadLink) and not FThreadLink.Terminated then
    if not FThreadLink.Terminated then
      FThreadLink.Terminate;
    if closeForm then
      FDiaporamaForm.Close;
  end;
  Result := True;
end;

{function TDiaporamaPlayer.GetDefaultDiapositive: TDiapositive;
begin
end;}

procedure TDiaporamaPlayer.PrepareDiapositive;
var
  aDiapositive: TDiapositive;
begin
  if FPlayerStatus = dpsPlaying then
  begin
    FDiaporamaEnumerator.MoveNext;
    aDiapositive := FDiaporamaEnumerator.Current;
    if Assigned(aDiapositive) then
    begin
      LogEvent(Self.ClassName, ltInformation,
          Format(cstPreparingDiapositiveMsg, [FDiaporama.Name, aDiapositive.ID,
            aDiapositive.TypeName]));

      if not Assigned(aDiapositive.DiapositiveType) then
      begin
        FDiapositiveStatus := dsError;

        LogEvent(Self.ClassName, ltError, Format(cstDiapositiveTypeNotFoundError,
            [aDiapositive.TypeName, aDiapositive.ID]));
      end;

      FDiapositiveStatus := dsPreparing;
      if not FDiaporamaForm.PrepareDisplay(aDiapositive, FRepository) then
      begin
        FDiapositiveStatus := dsError;

        LogEvent(Self.ClassName, ltError, Format(cstDiapositiveNoContentError,
          [aDiapositive.ID, aDiapositive.TypeName]));
      end;

      // TODO : default diapositive ?
      //if Assigned(DefaultDiapositive) then
      //  FDiaporamaForm.PrepareDisplay(DefaultDiapositive, FRepository);
    end;
  end;
end;

function TDiaporamaPlayer.CurrentDiapositiveDuration: Integer;
begin
  if Assigned(FDiaporamaEnumerator) then
    Result := FDiaporamaEnumerator.GetCurrentDiapositiveDuration
  else
    Result := -1;

  if Result=-1 then
    Result := FDefaultDiapositiveDuration;
end;

procedure TDiaporamaPlayer.SetDefaultDiapositiveDuration(const duration: Integer);
begin
  FDefaultDiapositiveDuration := duration*1000;
end;

function TDiaporamaPlayer.DisplayTimeElapsed: Boolean;
begin
  Result := MilliSecondsBetween(Now, FTime)>=CurrentDiapositiveDuration;
end;

procedure TDiaporamaPlayer.Execute;
begin
  coInitializeEx(nil, COINIT_APARTMENTTHREADED);

  PrepareDiapositive;

  FTime := Now;
  FTime := IncSecond(-CurrentDiapositiveDuration div 1000);

  while not FThreadLink.Terminated do
  begin
    // Prevent system standby
    SetThreadExecutionState(ES_SYSTEM_REQUIRED or ES_DISPLAY_REQUIRED);

    // On attend
    Sleep(DELTA_TIME);

    if DisplayTimeElapsed then
    begin
      // TODO : what if diapositive is not prepared ?
      if FDiapositiveStatus=dsPrepared then
        FDiaporamaForm.Display;

      FTime := Now;

      // Prepare next diapositive
      // TODO : prepare N+2 diapositive if N+1 is bad
      PrepareDiapositive;
    end;
  end;

  coUninitialize;
end;

function TDiaporamaPlayer.ExecuteAction(
  const aScheduleAction: TScheduleAction): Boolean;
var
  diaporamaIDParam, durationParam: string;
begin
  Result := False;
  if not Assigned(aScheduleAction) then
    Exit;
  case aScheduleAction.Action of
    ACT_PLAY_DIAPORAMA :
      begin
        diaporamaIDParam :=
          aScheduleAction.Parameters.Values[cstDiaporamaIDParam];
        if diaporamaIDParam<>'' then
        begin
          durationParam :=
            aScheduleAction.Parameters.Values[cstDurationParam];
          DefaultDiapositiveDuration := StrToIntDef(durationParam,
            DIAPOSITIVE_DURATION_S);
          Result := PlayDiaporama(diaporamaIDParam);
        end;
      end;
    ACT_STOP_DIAPORAMA :
      Result := Stop(True);
  end;
end;

function TDiaporamaPlayer.GetDefaultAction(const actionCode: Integer): TScheduleAction;
begin
  case actionCode of
    ACT_PLAY_DIAPORAMA :
    begin
      Result := TScheduleAction.CreateAction(Self, ACT_PLAY_DIAPORAMA,
        apEveryDay, StrToTime('08:05'), False);
      Result.Parameters.Values[cstDurationParam] :=
        IntToStr(DIAPOSITIVE_DURATION_S);
    end;
    ACT_STOP_DIAPORAMA :
    begin
      Result := TScheduleAction.CreateAction(Self, ACT_STOP_DIAPORAMA,
        apEveryDay, StrToTime('22:55'), False);
    end
  else
    Result := nil;
  end;
end;

function TDiaporamaPlayer.GetActionName(
  const aScheduleAction: TScheduleAction): string;
var
  diaporamaID: string;
begin
  Result := '';
  if Assigned(aScheduleAction) then
  begin
    case aScheduleAction.Action of
      ACT_PLAY_DIAPORAMA:
      begin
        diaporamaID := aScheduleAction.Parameters.Values[cstDiaporamaIDParam];
        Result := Format('Play diaporama ID = ''%s''', [diaporamaID]);
      end;
      ACT_STOP_DIAPORAMA:
      begin
        Result := 'Stop diaporama';
      end;
    end;
  end;
end;

function TDiaporamaPlayer.GetSourceName: string;
begin
  if Assigned(FDiaporamaDevice) then
    Result := Format('Player %s', [FDiaporamaDevice.Name])
  else
    Result := 'Player';
end;

procedure TDiaporamaPlayer.CheckActions(const actions: TObjectList<TScheduleAction>);
begin
  if actions.Count=2 then
    actions.Delete(0);
end;

procedure TDiaporamaPlayer.OnFormChangeExecute(sender: TObject);
begin
  FDiapositiveStatus := dsPrepared
end;

function TDiaporamaPlayer.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := -1;
end;

function TDiaporamaPlayer._AddRef: Integer;
begin
  Result := -1;
end;

function TDiaporamaPlayer._Release: Integer;
begin
  Result := -1;
end;

end.
