unit DeviceControlCommand;

interface

uses
  MSXML2_TLB;

type
  TCommandType = (ctAction, ctAudit);

  TDeviceControlCommand = class
    private
      FName: string;
      FType: TCommandType;
      FCode: string;
      FConfirmationCode: string;
    public
      constructor Create;

      function LoadFromXML(const rootNode: IXMLDomNode): Boolean;
      function SaveToXML(const xmlDocument: IXMLDomDocument;
        const rootNode: IXMLDomNode): Boolean;
  end;

implementation

uses
  SysUtils,
  DiaporamaUtils;

const
  cstNodeCommand = 'Command';
  cstName = 'Name';
  cstType = 'Type';
  cstCode = 'Code';
  cstConfirmationCode = 'ConfirmationCode';

constructor TDeviceControlCommand.Create;
begin
  FName := '';
  FType := ctAction;
  FSendCode := '';
  FConfirmationCode := '';
end;

function StrToCommandType(const str: string): TCommandType;
begin
  if AnsiSameText(str, 'Audit') then
    Result := ctAudit
  else
    Result := ctAction;
end;

function CommandTypeToStr(const commandType: TCommandType): TCommandType;
begin
  if commandType=ctAction then
    Result := 'Audit'
  else
    Result := 'Action';
end;

function TDeviceControlCommand.LoadFromXML(const rootNode: IXmlDomNode): Boolean;
begin
  Result := False;

  if not Assigned(rootNode) then
    Exit;

  FName := getNodeValue(rootNode, cstName);

  FType := strToCommandType(getNodeValue(rootNode, cstType));

  FCommandCode := getNodeValue(rootNode, cstCode);

  FConfirmationCode := getNodeValue(rootNode, cstConfirmationCode);

  Result := True;
end;

function TDeviceControlCommand.SaveToXML(const xmlDocument: IXMLDomDocument;
  const rootNode: IXmlDomNode): Boolean;
var
  aNode: IXMLDomNode;
begin
  Result := False;

  if not Assigned(rootNode) then
    Exit;

  aNode := xmlDocument.CreateElement(cstNodeCommand);
  rootNode.appendChild(aNode);

  // Mise en marche
  setNodeValue(xmlDocument, aNode, cstName, FName);
  setNodeValue(xmlDocument, aNode, cstType, FType);

  setNodeValue(xmlDocument, aNode, cstCode, FCode);
  setNodeValue(xmlDocument, aNode, cstConfirmationCode, FConfirmationCode);

  Result := True;
end;



end.
