unit DeviceControl;

interface

uses
  CPort, DeviceControlSettings;

type
  TControlType = (ctVGA, ctCom);

  TPowerStatus = (psUnknown, psOn, psOff);

  // Class to control a device display (power on/off) by sending commands on COM port
  TDeviceControl = class
    private
      FComPort: TComPort;
      FSettings: TDeviceControlSettings;
      FPowerStatus: TPowerStatus;

      procedure OnSettingChangeExecute(Sender: TObject);

      procedure SetSettings(const someSettings: TDeviceControlSettings);

      function SendToComPort(const printableCode: string;
        out returnCode: string): Boolean;
    public
      constructor Create(const someSettings: TDeviceControlSettings);
      destructor Destroy; override;

      function PowerOn: Boolean;
      function PowerOff: Boolean;
      function GetPowerStatus: TPowerStatus;

      function SendCommand(const printableCode,
        printableAcknowledgeCode: string): Boolean;

      property PowerStatus: TPowerStatus read GetPowerStatus;
      property Settings: TDeviceControlSettings read FSettings
        write SetSettings;
  end;
                        
implementation

uses
  SysUtils, Logs;

constructor TDeviceControl.Create(
  const someSettings: TDeviceControlSettings);
begin
  FComPort := TComPort.Create(nil);

  SetSettings(someSettings);

  FPowerStatus := psUnknown;
end;

destructor TDeviceControl.Destroy;
begin
  FComPort.Free;
  inherited;
end;

procedure TDeviceControl.SetSettings(const someSettings: TDeviceControlSettings);
begin
  if Assigned(someSettings) then
  begin
    FSettings := someSettings;
    FSettings.ComSettings.OnChange := OnSettingChangeExecute;
  end;
end;

procedure TDeviceControl.OnSettingChangeExecute(Sender: TObject);
begin
  if Assigned(FSettings) then
  begin
    FComPort.Port := FSettings.ComSettings.Port;
    FComPort.BaudRate := FSettings.ComSettings.BaudRate;
    FComPort.DataBits := FSettings.ComSettings.DataBits;
    FComPort.StopBits := FSettings.ComSettings.StopBits;
    FComPort.Parity.Bits := FSettings.ComSettings.ParityBits;
    FComPort.FlowControl.FlowControl :=
      FSettings.ComSettings.FlowControl;

    // Timeout constants for COM dialog
    FComPort.Timeouts.ReadTotalMultiplier :=
      FSettings.ComSettings.TimeOutPerChar;
    FComPort.Timeouts.ReadTotalConstant :=
      FSettings.ComSettings.TimeOutConstant;
    FComPort.Timeouts.WriteTotalMultiplier :=
      FSettings.ComSettings.TimeOutPerChar;
    FComPort.Timeouts.WriteTotalConstant :=
      FSettings.ComSettings.TimeOutConstant;
  end;
end;

function TDeviceControl.SendToComPort(const printableCode: string;
  out returnCode: string): Boolean;
var
  code: string;
  count: Integer;
begin
  Result := False;
  if printableCode='' then
    Exit;

  returnCode := '';
  try
    FComPort.Open;

    code := PrintableStrToStr(printableCode);
    count := FComPort.WriteStr(code);
    LogEvent(Self.ClassName, ltInformation,
      Format('Code ''%s'' envoyé sur le port %s (longueur envoyé : %d) ...',
        [printableCode, FComPort.Port, count]));
    count := 0;

    FComPort.ReadStr(returnCode, count);

    LogEvent(Self.ClassName, ltInformation,
      Format('Réponse recue sur le port %s : ''%s'' (longueur recue : %d)',
      [FComPort.Port, StrToPrintableStr(returnCode), count]));

    Result := returnCode<>'';
  finally
    FComPort.Close;
  end;
end;

function TDeviceControl.SendCommand(const printableCode,
  printableAcknowledgeCode: string): Boolean;
var
  returnCode, acknowledgeCode: string;
begin
  acknowledgeCode := PrintableStrToStr(printableAcknowledgeCode);
  Result := SendToComPort(printableCode, returnCode) and
    (returnCode=acknowledgeCode);
end;

function TDeviceControl.PowerOn: Boolean;
begin
  if SendCommand(FSettings.PowerOnCode,
    FSettings.ResponsePowerOnOKCode) then
  begin
    FPowerStatus := psOn;
    Result := True;
  end else
    Result := False;
end;

function TDeviceControl.PowerOff: Boolean;
begin
  if SendCommand(FSettings.PowerOffCode,
    FSettings.ResponsePowerOffOKCode) then
  begin
    FPowerStatus := psOff;
    Result := True;
  end else
    Result := False;
end;

function TDeviceControl.GetPowerStatus: TPowerStatus;
var
  returnCode: string;
begin
  Result := psUnknown;
  if (FSettings.PowerStatusCode<>'') and
     (FSettings.ResponseStatusOnCode<>'') and
     (FSettings.ResponseStatusOffCode<>'') then
  begin
    if SendToComPort(FSettings.PowerStatusCode, returnCode) then
    begin
      if returnCode=PrintableStrToStr(FSettings.ResponseStatusOnCode) then
        Result := psOn
      else if returnCode=PrintableStrToStr(FSettings.ResponseStatusOffCode) then
        Result := psOff;
    end;
  end;

  if (Result=psUnknown) and (FPowerStatus<>psUnknown) then
    Result := FPowerStatus
  else if Result<>psUnknown then
    FPowerStatus := Result;
end;

end.
