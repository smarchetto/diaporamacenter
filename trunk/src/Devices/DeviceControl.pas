unit DeviceControl;

interface

uses
  CPort, ComSettings, DeviceControlSettings;

type
  TControlType = (ctVGA, ctCom);

  TPowerStatus = (psUnknown, psOn, psOff);

  // Class to control a device display through a COM connection
  // (such as videorojectors), used by application to power/off the device
  TDeviceControl = class
    private
      FComPort: TComPort;
      FSettings: TDeviceControlSettings;
      FPowerStatus: TPowerStatus;

      procedure OnComSettingsChangeExecute(const settings: TComSettings);

      function SendToComPort(const printableCode: string;
        out returnCode: string): Boolean;
    public
      constructor Create(const settings: TDeviceControlSettings);
      destructor Destroy; override;

      function PowerOn: Boolean;
      function PowerOff: Boolean;
      function GetPowerStatus: TPowerStatus;

      function SendCommand(const printableCode,
        printableAcknowledgeCode: string): Boolean;

      property PowerStatus: TPowerStatus read GetPowerStatus;
  end;

implementation

uses
  SysUtils, Logs;

constructor TDeviceControl.Create(const settings: TDeviceControlSettings);
begin
  FComPort := TComPort.Create(nil);
  FSettings := settings;
  if Assigned(settings) then
    settings.ComSettings.OnChange := OnComSettingsChangeExecute;
  FPowerStatus := psUnknown;
end;

destructor TDeviceControl.Destroy;
begin
  FComPort.Free;
  inherited;
end;

procedure TDeviceControl.OnComSettingsChangeExecute(
  const settings: TComSettings);
begin
  if Assigned(settings) then
  begin
    FComPort.Port := settings.Port;
    FComPort.BaudRate := settings.BaudRate;
    FComPort.DataBits := settings.DataBits;
    FComPort.StopBits := settings.StopBits;
    FComPort.Parity.Bits := settings.ParityBits;
    FComPort.FlowControl.FlowControl := settings.FlowControl;

    // Timeout constants for COM dialog
    FComPort.Timeouts.ReadTotalMultiplier := settings.TimeOutPerChar;
    FComPort.Timeouts.ReadTotalConstant := settings.TimeOutConstant;
    FComPort.Timeouts.WriteTotalMultiplier := settings.TimeOutPerChar;
    FComPort.Timeouts.WriteTotalConstant := settings.TimeOutConstant;
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
