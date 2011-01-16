unit ComSettings;

interface

uses
  Classes, CPort, CPortTypes, MSXML2_TLB;

type
  TComSettings = class;

  TComSettingsChangeEvent = procedure(const settings: TComSettings) of object;

  // Port COM settings
  TComSettings = class(TBaseComPort)
  protected
    FTimeOutConstant: Integer;
    FTimeOutPerChar: Integer;

    FOnChangeEvent: TComSettingsChangeEvent;

    procedure SetPort(const value: TPort);
    procedure SetBaudRate(const value: TBaudRate);
    procedure SetParityBits(const value: TParityBits);
    function GetParityBits: TParityBits;
    procedure SetStopBits(const value: TStopBits);
    procedure SetDataBits(const value: TDataBits);
    procedure SetFlowControl(const value: TFlowControl);
    function GetFlowControl: TFlowControl;
  public
    constructor Create(aOwner: TComponent); override;

    procedure Assign(const comSettings: TComSettings); reintroduce;
    function Equals(anObject: TObject): Boolean; override;

    function LoadFromXML(const parentNode: IXmlDomNode): Boolean;
    function SaveToXML(const xmlDocument: IXMLDomDocument;
      const parentNode: IXmlDomNode): Boolean;

    property TimeOutConstant: Integer read FTimeOutConstant
      write FTimeOutConstant;
    property TimeOutPerChar: Integer read FTimeOutPerChar
      write FTimeOutPerChar;

    property Port: TPort read FPort write SetPort;
    property BaudRate: TBaudRate read FBaudRate write SetBaudRate;
    property ParityBits: TParityBits read GetParityBits write SetParityBits;
    property StopBits: TStopBits read FStopBits write SetStopBits;
    property DataBits: TDataBits read FDataBits write SetDataBits;
    property FlowControl: TFlowControl read GetFlowControl write SetFlowControl;

    property OnChange: TComSettingsChangeEvent read FOnChangeEvent write FOnChangeEvent;
  end;

implementation

uses
  SysUtils,
  //CPort,
  DiaporamaUtils;

const
  cstNodeCom = 'ComPort';
  cstNodePort = 'Port';
  cstNodeBaudRate = 'BaudsRate';
  cstNodeDataBits = 'DataBits';
  cstNodeParityBits = 'ParityBits';
  cstNodeStopBits = 'StopBits';
  cstNodeFlowControl = 'FlowControl';
  cstNodeTimeOut = 'TimeOut';
  cstNodeTimeOutConstant = 'Constant';
  cstNodeTimeOutPerChar = 'PerChar';

constructor TComSettings.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FOnChangeEvent := nil;
end;

procedure TComSettings.SetPort(const value: TPort);
begin
  FPort := value;
  if Assigned(FOnChangeEvent) then
    FOnChangeEvent(Self);
end;

procedure TComSettings.SetBaudRate(const value: TBaudRate);
begin
  FBaudRate := value;
  if Assigned(FOnChangeEvent) then
    FOnChangeEvent(Self);
end;

procedure TComSettings.SetParityBits(const value: TParityBits);
begin
  FParity.Bits := value;
  if Assigned(FOnChangeEvent) then
    FOnChangeEvent(Self);
end;

function TComSettings.GetParityBits: TParityBits;
begin
  Result := FParity.Bits;
end;

procedure TComSettings.SetStopBits(const value: TStopBits);
begin
  FStopBits := value;
  if Assigned(FOnChangeEvent) then
    FOnChangeEvent(Self);
end;

procedure TComSettings.SetDataBits(const value: TDataBits);
begin
  FDataBits := value;
  if Assigned(FOnChangeEvent) then
    FOnChangeEvent(Self);
end;

procedure TComSettings.SetFlowControl(const value: TFlowControl);
begin
  FFlowControl.FlowControl := value;
  if Assigned(FOnChangeEvent) then
    FOnChangeEvent(Self);
end;

function TComSettings.GetFlowControl: TFlowControl;
begin
  Result := FFlowControl.FlowControl;
end;

procedure TComSettings.Assign(const comSettings: TComSettings);
begin
  if Assigned(comSettings) then
  begin
    FPort := comSettings.Port;
    FBaudRate := comSettings.BaudRate;
    FDataBits := comSettings.DataBits;
    FParity.Bits := comSettings.ParityBits;
    FStopBits := comSettings.StopBits;
    FFlowControl.FlowControl := comSettings.FlowControl;
    FTimeOutConstant := comSettings.TimeOutConstant;
    FTimeOutPerChar := comSettings.TimeOutPerChar;

    if Assigned(FOnChangeEvent) then
      FOnChangeEvent(Self);
  end;
end;

function TComSettings.Equals(anObject: TObject): Boolean;
var
  comSettings: TComSettings;
begin
  if Assigned(anObject) and (anObject is TComSettings) then
  begin
    comSettings := TComSettings(anObject);
    Result :=
      (FBaudRate = comSettings.BaudRate) and
      (FDataBits = comSettings.DataBits) and
      (FParity.Bits = comSettings.ParityBits) and
      (FStopBits = comSettings.StopBits) and
      (FFlowControl.FlowControl = comSettings.FlowControl) and
      (FTimeOutConstant = comSettings.TimeOutConstant) and
      (FTimeOutPerChar = comSettings.TimeOutPerChar);
  end else
    Result := false;
end;

function TComSettings.LoadFromXML(const parentNode: IXmlDomNode): Boolean;
var
  aStr: string;
begin
  Result := False;

  if not Assigned(parentNode) then
    Exit;

  // Port
  FPort := getNodeValue(parentNode, cstNodeCom + '/' + cstNodePort);

  // Baud rate
  aStr := getNodeValue(parentNode, cstNodeCom + '/' + cstNodeBaudRate);
  FBaudRate := StrToBaudRate(aStr);

  // Data bits
  aStr := getNodeValue(parentNode, cstNodeCom + '/' + cstNodeDataBits);
  FDataBits := StrToDataBits(aStr);

  // Parity bits
  aStr := getNodeValue(parentNode, cstNodeCom + '/' + cstNodeParityBits);
  FParity.Bits := StrToParity(aStr);

  // Stop bits
  aStr := getNodeValue(parentNode, cstNodeCom + '/' + cstNodeStopBits);
  FStopBits := StrToStopBits(aStr);

  // Flow control
  aStr := getNodeValue(parentNode, cstNodeCom + '/' + cstNodeFlowControl);
  FFlowControl.FlowControl := StrToFlowControl(aStr);

  // Timeout for COM dialog constants
  // Minimal timeout constant
  aStr := getNodeValue(parentNode, cstNodeCom + '/' + cstNodeTimeOut + '/' +
    cstNodeTimeOutConstant);
  FTimeOutConstant := StrToIntDef(aStr, 250);

  // Timeout per character constant
  aStr := getNodeValue(parentNode, cstNodeCom + '/' + cstNodeTimeOut + '/' +
    cstNodeTimeOutPerChar);
  FTimeOutPerChar := StrToIntDef(aStr, 20);

  Result := True;
end;

function TComSettings.SaveToXML(const xmlDocument: IXMLDomDocument;
  const parentNode: IXmlDomNode): Boolean;
var
  comNode, timeOutNode: IXMLDomNode;
begin
  Result := False;

  if not Assigned(parentNode) then
    Exit;

  ComNode := xmlDocument.CreateElement(cstNodeCom);
  parentNode.appendChild(ComNode);

  // Port
  setNodeValue(xmlDocument, comNode, cstNodePort, FPort);

  // Baud rate
  setNodeValue(xmlDocument, comNode, cstNodeBaudRate,
    BaudRateToStr(FBaudRate));

  // Data bits
  setNodeValue(xmlDocument, comNode, cstNodeDataBits,
    DataBitsToStr(FDataBits));

  // Parity bits
  setNodeValue(xmlDocument, comNode, cstNodeParityBits,
    ParityToStr(FParity.Bits));

  // Stop bits
  setNodeValue(xmlDocument, comNode, cstNodeStopBits,
    StopBitsToStr(FStopBits));

  // Flow control
  setNodeValue(xmlDocument, comNode, cstNodeFlowControl,
    FlowControlToStr(FFlowControl.FlowControl));

  timeOutNode := xmlDocument.CreateElement(cstNodeTimeOut);
  ComNode.appendChild(timeOutNode);

  // Timeout for COM communication constants
  // Minimal timeout constant
  setNodeValue(xmlDocument, timeOutNode, cstNodeTimeOutConstant,
    IntToStr(FTimeOutConstant));

  // Timeout per character constant
  setNodeValue(xmlDocument, timeOutNode, cstNodeTimeOutPerChar,
    IntToStr(FTimeOutPerChar));
end;

end.
