unit DeviceControlSettings;

interface

uses
  Classes, MSXML2_TLB, ComSettings;

type
  TDeviceControlSettings = class
    private
      FComSettings: TComSettings;

      FPowerOnCode: string;
      FResponsePowerOnOKCode: string;

      FPowerOffCode: string;
      FResponsePowerOffOKCode: string;

      FPowerStatusCode: string;
      FResponseStatusOnCode: string;
      FResponseStatusOffCode: string;
    public
      constructor Create;
      destructor Destroy; override;

      procedure Assign(const deviceControlSettings: TDeviceControlSettings);
      function Equals(anObject: TObject): Boolean; override;

      function LoadFromXML(const parentNode: IXMLDomNode): Boolean;
      function SaveToXML(const xmlDocument: IXMLDomDocument;
        const parentNode: IXMLDomNode): Boolean;

      property PowerOnCode: string read FPowerOnCode write FPowerOnCode;
      property ResponsePowerOnOKCode: string read FResponsePowerOnOKCode
        write FResponsePowerOnOKCode;
      property PowerOffCode: string read FPowerOffCode write FPowerOffCode;
      property ResponsePowerOffOKCode: string read FResponsePowerOffOKCode
        write FResponsePowerOffOKCode;

      property ComSettings: TComSettings read FComSettings;

      property PowerStatusCode: string read FPowerStatusCode
        write FPowerStatusCode;
      property ResponseStatusOnCode: string read FResponseStatusOnCode
        write FResponseStatusOnCode;
      property ResponseStatusOffCode: string read FResponseStatusOffCode
        write FResponseStatusOffCode;
    end;

function StrToPrintableStr(const aStr: string): string;
function PrintableStrToStr(const aStr: string): string;

implementation

uses
  SysUtils,
  DiaporamaUtils;

const
  cstNodeCode = 'CommandCodes';
  cstNodePowerOnCode = 'PowerOn';
  cstNodePowerOnOKCode = 'PowerOnOK';
  cstNodePowerOffCode = 'PowerOff';
  cstNodePowerOffOKCode = 'PowerOffOK';
  cstNodePowerStatusCode = 'PowerStatus';
  cstNodePowerStatusOnCode = 'PowerStatusOn';
  cstNodePowerStatusOffCode = 'PowerStatusOff';

function StrToPrintableStr(const aStr: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(aStr) do
  begin
    if Ord(aStr[i])<=32 then
      Result := Result + '#' + IntToStr(Ord(aStr[i]))
    else
      Result := Result + aStr[i];
  end;
end;

function PrintableStrToStr(const aStr: string): string;
var
  i, j: Integer;
  ascii: string;
begin
  Result := '';
  i := 1;
  while i<=Length(aStr) do
  begin
    if aStr[i]='#' then
    begin
      ascii := '';
      j := 1;
      if (i+j<=Length(aStr)) and (aStr[i+j]='#') then
        Result := Result + '#'
      else
      begin
        while (j<=3) and (i+j<=Length(aStr)) do
        begin
          if CharInSet(aStr[i+j], ['0'..'9']) then
            ascii := ascii + aStr[i+j]
          else
            Break;
          Inc(j);
        end;
        if ascii<>'' then
          Result := Result + Chr(StrToInt(ascii));
      end;
      i := i+j;
    end else
    begin
      Result := Result + aStr[i];
      Inc(i);
    end;
  end;
end;

{$REGION 'TDeviceControlSettings'}

constructor TDeviceControlSettings.Create;
begin
  FComSettings := TComSettings.Create(nil);

  FPowerOnCode := '';
  FPowerOffCode := '';
  FResponsePowerOnOKCode := '';
  FResponsePowerOffOKCode := '';
  FPowerStatusCode := '';
  FResponseStatusOnCode := '';
  FResponseStatusOffCode := '';
end;

destructor TDeviceControlSettings.Destroy;
begin
  FComSettings.Free;
  inherited;
end;

procedure TDeviceControlSettings.Assign(
  const deviceControlSettings: TDeviceControlSettings);
begin
  if Assigned(deviceControlSettings) then
  begin
    FComSettings.Assign(deviceControlSettings.ComSettings);

    FPowerOnCode := deviceControlSettings.PowerOnCode;
    FResponsePowerOnOKCode := deviceControlSettings.ResponsePowerOnOKCode;

    FPowerOffCode := deviceControlSettings.PowerOffCode;
    FResponsePowerOffOKCode := deviceControlSettings.ResponsePowerOffOKCode;

    FPowerStatusCode := deviceControlSettings.PowerStatusCode;
    FResponseStatusOnCode := deviceControlSettings.ResponseStatusOnCode;
    FResponseStatusOffCode := deviceControlSettings.ResponseStatusOffCode;
  end;
end;

function TDeviceControlSettings.Equals(anObject: TObject): Boolean;
var
  deviceControlSettings: TDeviceControlSettings;
begin
  if Assigned(anObject) and (anObject is TDeviceControlSettings) then
  begin
    deviceControlSettings := TDeviceControlSettings(anObject);
    Result :=
      FComSettings.Equals(deviceControlSettings.ComSettings) and
      (FPowerOnCode = deviceControlSettings.PowerOnCode) and
      (FResponsePowerOnOKCode = deviceControlSettings.ResponsePowerOnOKCode) and
      (FPowerOffCode = deviceControlSettings.PowerOffCode) and
      (FResponsePowerOffOKCode = deviceControlSettings.ResponsePowerOffOKCode) and
      (FPowerStatusCode = deviceControlSettings.PowerStatusCode) and
      (FResponseStatusOnCode = deviceControlSettings.ResponseStatusOnCode) and
      (FResponseStatusOffCode = deviceControlSettings.ResponseStatusOffCode);
  end else
    Result := false;
end;

function TDeviceControlSettings.LoadFromXML(const parentNode: IXmlDomNode): Boolean;
begin
  Result := False;

  if not Assigned(parentNode) then
    Exit;

  // COM settings
  FComSettings.LoadFromXML(parentNode);

  // Power on command
  FPowerOnCode := getNodeValue(parentNode, cstNodeCode + '/' + cstNodePowerOnCode);
  FResponsePowerOnOKCode := getNodeValue(parentNode, cstNodeCode + '/' +
    cstNodePowerOnOKCode);

  // Power off command
  FPowerOffCode := getNodeValue(parentNode, cstNodeCode + '/' + cstNodePowerOffCode);
  FResponsePowerOffOKCode := getNodeValue(parentNode, cstNodeCode + '/' +
    cstNodePowerOffOKCode);

  // Get power status command
  FPowerStatusCode := getNodeValue(parentNode, cstNodeCode + '/' +
    cstNodePowerStatusCode);
  FResponseStatusOnCode := getNodeValue(parentNode, cstNodeCode + '/' +
    cstNodePowerStatusOnCode);
  FResponseStatusOffCode := getNodeValue(parentNode, cstNodeCode + '/' +
    cstNodePowerStatusOffCode);

  Result := True;
end;

function TDeviceControlSettings.SaveToXML(const xmlDocument: IXMLDomDocument;
  const parentNode: IXmlDomNode): Boolean;
var
  aNode: IXMLDomNode;
begin
  Result := False;

  if not Assigned(parentNode) then
    Exit;

  // COM settings
  FComSettings.SaveToXML(xmlDocument, parentNode);

  aNode := xmlDocument.CreateElement(cstNodeCode);
  parentNode.appendChild(aNode);

  // Power on command
  setNodeValue(xmlDocument, aNode, cstNodePowerOnCode, FPowerOnCode);
  setNodeValue(xmlDocument, aNode, cstNodePowerOnOKCode, FResponsePowerOnOKCode);

  // Power off command
  setNodeValue(xmlDocument, aNode, cstNodePowerOffCode, FPowerOffCode);
  setNodeValue(xmlDocument, aNode, cstNodePowerOffOKCode, FResponsePowerOffOKCode);

  // Get power status command
  setNodeValue(xmlDocument, aNode, cstNodePowerStatusCode, FPowerStatusCode);
  setNodeValue(xmlDocument, aNode, cstNodePowerStatusOnCode, FResponseStatusOnCode);
  setNodeValue(xmlDocument, aNode, cstNodePowerStatusOffCode, FResponseStatusOffCode);

  Result := True;
end;

{$ENDREGION}

end.
