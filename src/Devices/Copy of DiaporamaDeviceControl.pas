unit DeviceControlSettings;

interface

uses
  MSXML2_TLB, ComSettings;

type
  TDeviceControlSettings = class
    private
      FComSettings: TComSettings;

      FPowerOnCode: string;
      FResponsePowerOnOKCode: string;

      FPowerOffCode: string;
      FResponsePowerOffOKCode: string;

      FPowerStatusCode: string;
      FResponsePowerOnCode: string;
      FResponsePowerOffCode: string;

      function SendCommand(const code, returnCode: string): Boolean;
    public
      constructor Create;
      destructor Destroy; override;

      procedure Assign(const aDiaporamaDeviceControl: TDiaporamaDeviceControl);

      function LoadFromXML(const rootNode: IXMLDomNode): Boolean;
      function SaveToXML(const xmlDocument: IXMLDomDocument;
        const rootNode: IXMLDomNode): Boolean;

      procedure PowerOff;
      procedure PowerOn;

      property PowerOnCode: string read FPowerOnCode write FPowerOnCode;
      property ResponsePowerOnOKCode: string read FResponsePowerOnOKCode
        write FResponsePowerOnOKCode;
      property PowerOffCode: string read FPowerOffCode write FPowerOffCode;
      property ResponsePowerOffOKCode: string read FResponsePowerOffOKCode
        write FResponsePowerOffOKCode;

      property PowerStatusCode: string read FPowerStatusCode
        write FPowerStatusCode;
      property ResponsePowerOnCode: string read FResponsePowerOnCode
        write FResponsePowerOnCode;
      property ResponsePowerOffCode: string read FResponsePowerOffCode
        write FResponsePowerOffCode;
    end;

implementation

uses
  DiaporamaUtils, SysUtils, Dialogs;

const
  cstNodeCom = 'ComPort';
  cstNodePort = 'Port';
  cstNodeBaudRate = 'BaudsRate';
  cstNodeDataBits = 'DataBits';
  cstNodeParityBits = 'ParityBits';
  cstNodeStopBits = 'StopBits';
  cstNodeFlowControl = 'FlowControl';

  cstNodePowerOnCode = 'PowerOnCode';
  cstNodePowerOnOKCode = 'PowerOnOKCode';
  cstNodePowerOffCode = 'PowerOffCode';
  cstNodePowerOffOKCode = 'PowerOffOKCode';

constructor TDiaporamaDeviceControl.Create;
begin
  FComPort := TComPort.Create(nil);

  FPowerOnCode := '';
  FPowerOffCode := '';
  FResponsePowerOnOKCode := '';
  FResponsePowerOffOKCode := '';
  FPowerStatusCode := '';
  FResponsePowerOnCode := '';
  FResponsePowerOffCode := '';
end;

destructor TDiaporamaDeviceControl.Destroy;
begin
  FComPort.Free;
end;

procedure TDiaporamaDeviceControl.Assign(
  const aDeviceControlSettings: TDeviceControlSettings);
begin
  if Assigned(aDeviceControlSettings) then
  begin
    FComSettings.Assign(aDiaporamaDeviceControl.ComSettings);
    
    FPowerOnCode := aDiaporamaDeviceControl.PowerOnCode;
    FResponsePowerOnOKCode := aDiaporamaDeviceControl.ResponsePowerOnOKCode;
             (
    FPowerOffCode := aDiaporamaDeviceControl.PowerOffCode;
    FResponsePowerOffOKCode := aDiaporamaDeviceControl.ResponsePowerOffOKCode;

    FPowerStatusCode := aDiaporamaDeviceControl.PowerStatusCode;
    FResponsePowerOnCode := aDiaporamaDeviceControl.ResponsePowerOnCode;
    FResponsePowerOffCode := aDiaporamaDeviceControl.ResponsePowerOffCode;
  end;
end;

function TDiaporamaDeviceControl.SendCommand(const code,
  returnCode: string): Boolean;
var
  response: string;
  count: Integer;
begin
  Result := False;
  response := '';
  count := 0;
  try
    FComPort.Open;
    count := FComPort.WriteStr(code);
    ShowMessage(
      Format('Commande %s envoyé sur le port %s (longueur envoyé = %d)',
        [code, FComPort.Port, count]));
    FComPort.ReadStr(response, count);
    ShowMessage(Format('Réponse recue : %s', [response]));
    Result := response=returnCode;
  finally
    comPort.Close;
  end;
end;

procedure TDiaporamaDeviceControl.PowerOn;
begin

  SendCommand(FPowerOnCode, FResponsePowerOnOKCode);
end;

procedure TDiaporamaDeviceControl.PowerOff;
begin
  SendCommand(FPowerOffCode, FResponsePowerOffOKCode);
end;


function TDiaporamaDeviceControl.LoadFromXML(const rootNode: IXmlDomNode): Boolean;
var
  aStr: string;
begin
  Result := False;

  if not Assigned(rootNode) then
    Exit;

  // Port
  FComPort.Port := getNodeValue(rootNode, cstNodeCom + '/' + cstNodePort);

  // Bauds
  aStr := getNodeValue(rootNode, cstNodeCom + '/' + cstNodeBaudRate);
  FComPort.BaudRate := StrToBaudRate(aStr);

  // Bits de données
  aStr := getNodeValue(rootNode, cstNodeCom + '/' + cstNodeDataBits);
  FComPort.DataBits := StrToDataBits(aStr);

  // Bits de parité
  aStr := getNodeValue(rootNode, cstNodeCom + '/' + cstNodeParityBits);
  FComPort.Parity.Bits := StrToParity(aStr);

  // Bits de stop
  aStr := getNodeValue(rootNode, cstNodeCom + '/' + cstNodeStopBits);
  FComPort.StopBits := StrToStopBits(aStr);

  // Controle de flux
  aStr := getNodeValue(rootNode, cstNodeCom + '/' + cstNodeFlowControl);
  FComPort.FlowControl.FlowControl := StrToFlowControl(aStr);

  // Commande d'allumage
  FPowerOnCode := getNodeValue(rootNode, cstNodeCom + '/' + cstNodePowerOnCode);
  FResponsePowerOnOKCode := getNodeValue(rootNode, cstNodeCom + '/' +
    cstNodePowerOnOKCode);

  // Commande d'extinction
  FPowerOffCode := getNodeValue(rootNode, cstNodeCom + '/' + cstNodePowerOffCode);
  FResponsePowerOffOKCode := getNodeValue(rootNode, cstNodeCom + '/' +
    cstNodePowerOffCode);

  Result := True;
end;

function TDiaporamaDeviceControl.SaveToXML(const xmlDocument: IXMLDomDocument;
  const rootNode: IXmlDomNode): Boolean;
var
  aNode: IXMLDomNode;
begin
  Result := False;

  if not Assigned(rootNode) then
    Exit;

  aNode := xmlDocument.CreateElement(cstNodeCom);
  rootNode.appendChild(aNode);

  // Port
  setNodeValue(xmlDocument, aNode, cstNodePort, FComPort.Port);

  // Bauds
  setNodeValue(xmlDocument, aNode, cstNodeBaudRate,
    BaudRateToStr(FComPort.BaudRate));

  // Bits de données
  setNodeValue(xmlDocument, aNode, cstNodeDataBits,
    DataBitsToStr(FComPort.DataBits));

  // Parité
  setNodeValue(xmlDocument, aNode, cstNodeParityBits,
    ParityToStr(FComPort.Parity.Bits));

  // Bits de stop
  setNodeValue(xmlDocument, aNode, cstNodeStopBits,
    StopBitsToStr(FComPort.StopBits));

  // Controle de flux
  setNodeValue(xmlDocument, aNode, cstNodeFlowControl,
    FlowControlToStr(FComPort.FlowControl.FlowControl));

  // Mise en marche
  setNodeValue(xmlDocument, aNode, cstNodePowerOnCode, FPowerOnCode);
  setNodeValue(xmlDocument, aNode, cstNodePowerOnOKCode, FResponsePowerOnOKCode);

  setNodeValue(xmlDocument, aNode, cstNodePowerOffCode, FPowerOffCode);
  setNodeValue(xmlDocument, aNode, cstNodePowerOffOKCode, FResponsePowerOffOKCode);

  Result := True;
end;


end.
