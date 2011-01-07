unit DiaporamaDevice;

interface

uses
  Forms, Classes, Generics.Defaults, Generics.Collections,
  DiaporamaDeviceInfo, DiaporamaDeviceSettings, DisplayMode,
  DeviceControl, DeviceControlSettings, ScheduleAction;

type
  // Device display
  TDiaporamaDevice = class(TObject, IScheduleSource)
  private
    FDiaporamaCenterAgent: TObject;
    // Index
    FDeviceIndex: Integer;
    // Associated Delphi TMonitor class
    FMonitor: TMonitor;
    // Device info
    FDeviceInfo: TDiaporamaDeviceInfo;
    // Device settings
    FSettings: TDiaporamaDeviceSettings;
    // Device control
    FDeviceControl: TDeviceControl;
    // Power event
    FOnPowerChange: TNotifyEvent;
    // Associated diaporama player
    FDiaporamaPlayer: TObject;

    //FOriginalDisplayMode: TDisplayMode;

    // Returns the vide device name (graphic card)
    function GetVideoDeviceName: string;

    // Returns the display device name (screen, videoprojector)
    function GetName: string;
    // Returns the display device title (screen, videoprojector)
    function GetTitle: string;

    // Display mode
    function GetDisplayMode: TDisplayMode;
    procedure SetDisplayMode(const aDisplayMode: TDisplayMode);

    procedure RegisterInSchedule;
  public
    constructor Create(const aDiaporamaCenterAgent: TObject);
    destructor Destroy; override;

    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    // Checks the device is active
    function CheckDevice: Boolean;

    // Get device info
    function FindDeviceInfo: Boolean;

    // User settings
    procedure Configure(const deviceSettings: TDiaporamaDeviceSettings);
    function GetSettingFileName: string;

    // Load & save configuration file
    procedure LoadFromXML(const xmlFilePath: string);
    procedure SaveToXML(const xmlFilePath: string);

    function GetAvailableDisplayModes: TObjectList<TDisplayMode>;
    function GetAvailableDisplayModeStrings: TStringList;
    procedure LogAvailableDisplayModes;

    function ValidMode(const aDisplayMode: TDisplayMode): Boolean;

    // Power commands
    function PowerOn: Boolean;
    function PowerOff: Boolean;
    function GetPowerStatus: TPowerStatus;

    class function PowerOnAllDevices: Boolean;
    class function PowerOffAllDevices: Boolean;

    // IScheduleSource
    function GetSourceName: string;
    function GetDefaultAction(const actionCode: Integer): TScheduleAction;
    function GetActionName(const aScheduleAction: TScheduleAction): string;
    procedure CheckActions(const actions: TObjectList<TScheduleAction>);
    function ExecuteAction(const aScheduleAction: TScheduleAction): Boolean;

    property Name: string read GetName;
    property DeviceIndex: Integer read FDeviceIndex write FDeviceIndex;
    property Settings: TDiaporamaDeviceSettings read FSettings;

    property Monitor: TMonitor read FMonitor write FMonitor;
    property DeviceInfo: TDiaporamaDeviceInfo read FDeviceInfo;
    property DisplayMode: TDisplayMode read GetDisplayMode
      write SetDisplayMode;
    property DeviceControl: TDeviceControl read FDeviceControl;
    property Title: string read GetTitle;

    property OnPowerChange: TNotifyEvent read FOnPowerChange
      write FOnPowerChange;

    property DiaporamaPlayer: TObject read FDiaporamaPlayer
      write FDiaporamaPlayer;
  end;

const
  ACT_POWER_ON  = 0;
  ACT_POWER_OFF = 1;

implementation

uses
  Windows, SysUtils, StrUtils, IdGlobal, Messages,
  Logs, DiaporamaUtils, DiaporamaCenterAgent, DiaporamaPlayer;

type
  // Record containing the display device logical name
  TMonitorInfoEx = record
    cbSize    : DWord;
    rcMonitor : TRect;
    rcWork    : TRect;
    dwFlags   : DWord;
    szDevice  : array[0..CCHDEVICENAME-1] of Char;
  end;
  PMonitorInfoEx = ^TMonitorInfoEx;

const
  ENUM_CURRENT_SETTINGS = $FFFFFFFF;
  ENUM_REGISTRY_SETTINGS = $FFFFFFFE;

  cstPowerOnDevice = 'Power on of device ''%s'' %s';
  cstPowerOffDevice = 'Power off of device ''%s'' %s';
  cstPowerOnAllDevices =
    'Power on of all devices %s';
  cstPowerOffAllDevices =
    'Power off of all devices %s';

  MONITOR_ON =    -1;
  MONITOR_OFF    = 2;
  MONITOR_STANDBY = 1;

// Windows function returning display device logical name
function GetMonitorInfoEx(aMonitor: THandle;
  LpInfo: PMonitorInfoEx): Boolean; stdcall;
  external User32 name 'GetMonitorInfoW';

// Windows function returning the device display modes
function EnumDisplaySettingsEx(lpszDeviceName: PChar; iModeNum: DWORD;
  var lpDevMode: TDeviceMode; dwFlags: DWORD): Boolean; stdcall;
  external User32 name 'EnumDisplaySettingsExW';

{$REGION 'TDiaporamaDevice'}

constructor TDiaporamaDevice.Create(const aDiaporamaCenterAgent: TObject);
begin
  FMonitor := nil;
  FDeviceIndex := -1;
  FDeviceInfo := TDiaporamaDeviceInfo.Create;
  FSettings := TDiaporamaDeviceSettings.Create;
  FDeviceControl := TDeviceControl.Create(FSettings.ControlSettings);
  FOnPowerChange := nil;
  FDiaporamaCenterAgent := aDiaporamaCenterAgent;
  FDiaporamaPlayer := nil;
end;

procedure TDiaporamaDevice.RegisterInSchedule;
begin
  if Assigned(FDiaporamaCenterAgent) and
    (FDiaporamaCenterAgent is TDiaporamaCenterAgent) then
    TDiaporamaCenterAgent(FDiaporamaCenterAgent).Scheduler.RegisterSource(Self);
end;

destructor TDiaporamaDevice.Destroy;
begin
  FDeviceInfo.Free;
  FSettings.Free;
  FDeviceControl.Free;
  inherited;
end;

function TDiaporamaDevice.GetTitle: string;
begin
  Result := FSettings.Name;
  if Result = '' then
    Result := Format('Device %d', [FDeviceIndex])
  else
    Result := Format('[%d] %s', [FDeviceIndex, Result]);
end;

function TDiaporamaDevice.GetName;
begin
  Result := FSettings.Name;
  if Result = '' then
  begin
    if Assigned(FMonitor) then
      Result := Format('Device %d', [FDeviceIndex]);
  end;
end;

procedure TDiaporamaDevice.Configure(
  const deviceSettings: TDiaporamaDeviceSettings);
begin
  if Assigned(deviceSettings) then
    FSettings.Assign(deviceSettings);

  FSettings.DeviceInfo.Assign(FDeviceInfo);

  RegisterInSchedule;
end;

function TDiaporamaDevice.GetVideoDeviceName: string;
var
  monitorInfo: TMonitorInfoEx;
begin
  if Assigned(FMonitor) then
  begin
    ZeroMemory(Pointer(@monitorInfo), SizeOf(TMonitorInfoEx));
    monitorInfo.cbSize := SizeOf(TMonitorInfoEx);
    GetMonitorInfoEx(FMonitor.Handle, @monitorInfo);
    Result := MonitorInfo.szDevice;
  end else
    Result := '';
end;

function TDiaporamaDevice.CheckDevice: Boolean;
var
  deviceName: string;
begin
  deviceName := GetVideoDeviceName;
  Result := FDeviceInfo.CheckDevice(deviceName);
end;

function TDiaporamaDevice.FindDeviceInfo: Boolean;
var
  deviceName: string;
begin
  deviceName := GetVideoDeviceName;
  Result := FDeviceInfo.FindDeviceInfo(deviceName);
end;

function TDiaporamaDevice.GetDisplayMode: TDisplayMode;
var
  deviceName: PChar;
  dm: TDeviceMode;
  res: Boolean;
begin
  Result := nil;

  deviceName := PChar(GetVideoDeviceName);
  if deviceName<>'' then
  begin
    ZeroMemory(Pointer(@dm), SizeOf(TDeviceMode));
    dm.dmSize := SizeOf(TDeviceMode);
    res := EnumDisplaySettingsEx(deviceName, ENUM_CURRENT_SETTINGS, dm, 0);
    if not res then
      res := EnumDisplaySettingsEx(deviceName, ENUM_REGISTRY_SETTINGS, dm, 0);
    if res then
    begin
      Result := TDisplayMode.Create(dm);
    end;
  end;
end;

function TDiaporamaDevice.GetAvailableDisplayModes: TObjectList<TDisplayMode>;
var
  deviceName: PChar;
  dm: TDeviceMode;
  iModeNum: Integer;
begin
  Result := nil;
  deviceName := PChar(GetVideoDeviceName);
  if deviceName<>'' then
  begin
    ZeroMemory(Pointer(@dm), SizeOf(dm));
    dm.dmSize := SizeOf(dm);
    if EnumDisplaySettings(deviceName, 0, dm) then
    begin
      Result := TObjectList<TDisplayMode>.Create;
      iModeNum := 1;
      while EnumDisplaySettings(deviceName, iModeNum, dm) do
      begin
        Result.Add(TDisplayMode.Create(dm));
        Inc(iModeNum);
      end;
    end;
  end;
  if not Assigned(Result) or (Result.Count<1) then
    LogEvent(Self.ClassName, ltError, Format(
    'Error while retrieving the display mode list ''%s''',
      [deviceName]));
end;

function TDiaporamaDevice.GetAvailableDisplayModeStrings: TStringList;
var
  availableModes: TObjectList<TDisplayMode>;
  displayMode: TDisplayMode;
begin
  Result := nil;

  availableModes := nil;
  try
    availableModes := GetAvailableDisplayModes;

    if Assigned(availableModes) then
    begin
      Result := TStringList.Create;
      for displayMode in availableModes do
      begin
        Result.Add(displayMode.ToString);
      end;
    end;
  finally
    availableModes.Free;
  end;
end;

procedure TDiaporamaDevice.LogAvailableDisplayModes;
var
  availableModeStrings: TStringList;
  i: Integer;
  aStr: String;
begin
  availableModeStrings := nil;
  try
    availableModeStrings := GetAvailableDisplayModeStrings;

    if Assigned(availableModeStrings) then
    begin
      aStr := '';
      for i := 0 to availableModeStrings.Count-1 do
        aStr := aStr + availableModeStrings[i] + #13#10;

      LogEvent(Self.ClassName, ltInformation,
        Format('Device ''%s'' : available display modes'
          + #13#10 + '%s', [Name, aStr]));
    end;
  finally
    availableModeStrings.Free;
  end;
end;

function TDiaporamaDevice.ValidMode(const aDisplayMode: TDisplayMode): Boolean;
var
  availableModes: TObjectList<TDisplayMode>;
  displayMode: TDisplayMode;
begin
  Result := False;
  if Assigned(aDisplayMode) and
     (aDisplayMode.Width>0) and
     (aDisplayMode.Height>0) and
     (aDisplayMode.Frequency>0) and
     (aDisplayMode.BitsPerPixel>0) then
  begin
    availableModes := nil;
    try
      availableModes := GetAvailableDisplayModes;
      for displayMode in availableModes do
      begin
        if displayMode.Equals(aDisplayMode) then
        begin
          Result := True;
          Exit;
        end;
      end;
    finally
      availableModes.Free;
    end;
  end;
end;

procedure TDiaporamaDevice.SetDisplayMode(const aDisplayMode: TDisplayMode);
var
  deviceName: string;
  dm: TDeviceMode;
begin
  deviceName := GetVideoDeviceName;
  if deviceName<>'' then
  begin
    if not DisplayMode.Equals(aDisplayMode) then
    begin
      if ValidMode(aDisplayMode) then
      begin
        ZeroMemory(Pointer(@dm), SizeOf(dm));
        dm.dmSize := SizeOf(TDeviceMode);
        dm.dmDriverExtra := 0;
        dm.dmPelsWidth := aDisplayMode.Width;
        dm.dmPelsHeight := aDisplayMode.Height;
        dm.dmBitsPerPel := aDisplayMode.BitsPerPixel;
        dm.dmDisplayFrequency := aDisplayMode.Frequency;
        // TODO : update only what has changed
        dm.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT or
          DM_DISPLAYFREQUENCY or DM_BITSPERPEL;
        ChangeDisplaySettingsEx(PChar(deviceName), dm, 0, 0, nil);
        // TODO : logEvent ChangeDisplaySettingsEx
        // TODO : windows repositionning
      end;
    end;
  end;
end;

procedure TDiaporamaDevice.LoadFromXML(const xmlFilePath: string);
begin
  FSettings.LoadFromXML(xmlFilePath);
end;

procedure TDiaporamaDevice.SaveToXML(const xmlFilePath: string);
begin
  FSettings.SaveToXML(xmlFilePath);
end;

class function TDiaporamaDevice.PowerOnAllDevices: Boolean;
var
  res: Integer;
begin
  Sleep(500);

  res := SendMessage(Application.Handle,
    WM_SYSCOMMAND, SC_MONITORPOWER, MONITOR_ON);

  Result := res=0;

  LogEvent(Self.ClassName, ltInformation, Format(cstPowerOnAllDevices,
    [iif(Result, 'succeeded', 'failed')]));
end;

class function TDiaporamaDevice.PowerOffAllDevices: Boolean;
var
  res: Integer;
begin
  Sleep(500);

  res := SendMessage(Application.Handle, WM_SYSCOMMAND,
    SC_MONITORPOWER, MONITOR_OFF);

  Result := res=0;

  LogEvent(Self.ClassName, ltInformation, Format(cstPowerOffAllDevices,
    [iif(Result, 'suceeded', 'failed')]));
end;

function TDiaporamaDevice.PowerOn: Boolean;
begin
  // TODO : concurrent access TCriticalSection
  Result := FDeviceControl.PowerOn;

  LogEvent(Self.ClassName, ltInformation, Format(cstPowerOnDevice, [Name,
    iif(Result, 'suceeded', 'failed')]));

  if Assigned(FOnPowerChange) then
    FOnPowerChange(Self);
end;

function TDiaporamaDevice.PowerOff: Boolean;
begin
  // TODO : concurrent access TCriticalSection
  Result := FDeviceControl.PowerOff;

  LogEvent(Self.ClassName, ltInformation, Format(cstPowerOffDevice, [Name,
    iif(Result, 'suceeded', 'failed')]));

  if Assigned(FOnPowerChange) then
    FOnPowerChange(Self);
end;

function TDiaporamaDevice.GetSettingFileName: string;
begin
  Result := FSettings.FileName;
  if Result='' then
    Result := GetName;
  Result := IncludeXMLExtension(Result);
end;

function TDiaporamaDevice.GetPowerStatus: TPowerStatus;
begin
  Result := FDeviceControl.GetPowerStatus;
end;

procedure TDiaporamaDevice.CheckActions(const actions: TObjectList<TScheduleAction>);
begin
  if actions.Count=2 then
    actions.Delete(0);
end;

function TDiaporamaDevice.ExecuteAction(
  const aScheduleAction: TScheduleAction): Boolean;
begin
  if Assigned(aScheduleAction) then
  begin
    case aScheduleAction.Action of
      ACT_POWER_ON  : Result := PowerOn;
      ACT_POWER_OFF : Result := PowerOff;
    else
      Result := False;
    end;
  end else
    Result := False;
end;

function TDiaporamaDevice.GetDefaultAction(const actionCode: Integer): TScheduleAction;
begin
  case actionCode of
    ACT_POWER_ON: Result := TScheduleAction.CreateAction(Self, ACT_POWER_ON,
      apEveryDay, StrToTime('08:00'), False);
    ACT_POWER_OFF: Result := TScheduleAction.CreateAction(Self, ACT_POWER_OFF,
      apEveryDay, StrToTime('23:00'), False);
  else
    Result := nil;
  end;
end;

function TDiaporamaDevice.GetActionName(
  const aScheduleAction: TScheduleAction): string;
begin
  if Assigned(aScheduleAction) then
  begin
    case aScheduleAction.Action of
      ACT_POWER_ON  : Result := 'Power on';
      ACT_POWER_OFF : Result := 'Power off';
    else
      Result := '';
    end;
  end else
    Result := '';
end;

function TDiaporamaDevice.GetSourceName: string;
begin
  Result := Name;
end;

function TDiaporamaDevice.QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
begin
  Result := -1;
end;

function TDiaporamaDevice._AddRef: Integer; stdcall;
begin
  Result := -1;
end;

function TDiaporamaDevice._Release: Integer; stdcall;
begin
  Result := -1;
end;

{$ENDREGION}

end.
