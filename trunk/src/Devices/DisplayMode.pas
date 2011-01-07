unit DisplayMode;

interface

uses
  MSXML2_TLB, Windows;

type
  // Interface 
  IDisplayMode = interface
    procedure Assign(const aDisplayMode: IDisplayMode);
    function Equals(const aDisplayMode: IDisplayMode): Boolean;

    function GetWidth: Word;
    function GetHeight: Word;
    function GetFrequency: Byte;
    function GetBitsPerPixel: Byte;

    function LoadFromXML(const parentNode: IXMLDOMNode): Boolean;
    function SaveToXML(const xmlDocument: IXMLDOMDocument;
      const parentNode: IXMLDOMNode): Boolean;

    function ToString: String;
    property Width: Word read GetWidth;
    property Height: Word read GetHeight;
    property Frequency: Byte read GetFrequency;
    property BitsPerPixel: Byte read GetBitsPerPixel;
  end;

  // Display settings: resolution, frequency, ....
  TDisplayMode = class(TInterfacedObject, IDisplayMode)
  private
    FHeight: Word;
    FWidth: Word;
    FFrequency: Byte;
    FBitsPerPixel: Byte;

    function GetWidth: Word;
    function GetHeight: Word;
    function GetFrequency: Byte;
    function GetBitsPerPixel: Byte;
  public
    constructor Create; overload;
    constructor Create(const deviceMode: TDeviceMode); overload;
    constructor Create(const aWidth, aHeight: Word; const aFrequency: Byte;
      const aBitsPerPixel: Byte); overload;

    function Equals(const aDisplayMode: IDisplayMode): Boolean; reintroduce;
    procedure Assign(const aDisplayMode: IDisplayMode);

    function LoadFromXML(const parentNode: IXMLDomNode): Boolean;
    function SaveToXML(const xmlDocument: IXMLDomDocument;
      const parentNode: IXMLDomNode): Boolean;

    function ToString: string; override;

    property Width: Word read GetWidth;
    property Height: Word read GetHeight;
    property Frequency: Byte read GetFrequency;
    property BitsPerPixel: Byte read GetBitsPerPixel;
  end;
implementation

uses
  SysUtils, DiaporamaUtils;

const
  cstNodeDisplayMode = 'DisplayMode';
  cstNodeWidth = 'Width';
  cstNodeHeight = 'Height';
  cstNodeBitsPerPixel = 'BitsPerPixel';
  cstNodeFrequency = 'Frequency';


{$REGION 'TDisplayMode'}

constructor TDisplayMode.Create;
begin
  //Create(1024, 768, 70, 24);
  Create(0, 0, 0, 0);
end;

constructor TDisplayMode.Create(const aWidth, aHeight: Word;
  const aFrequency: Byte; const aBitsPerPixel: Byte);
begin
  FWidth := aWidth;
  FHeight := aHeight;
  FFrequency := aFrequency;
  FBitsPerPixel := aBitsPerPixel;
end;

constructor TDisplayMode.Create(const deviceMode: TDeviceMode);
begin
  Create(deviceMode.dmPelsWidth, deviceMode.dmPelsHeight,
    deviceMode.dmDisplayFrequency, deviceMode.dmBitsPerPel)
end;

function TDisplayMode.GetWidth: Word;
begin
  Result := FWidth;
end;

function TDisplayMode.GetHeight: Word;
begin
  Result := FHeight;
end;

function TDisplayMode.GetFrequency: Byte;
begin
  Result := FFrequency;
end;

function TDisplayMode.GetBitsPerPixel: Byte;
begin
  Result := FBitsPerPixel;
end;

procedure TDisplayMode.Assign(const aDisplayMode: IDisplayMode);
begin
  if Assigned(aDisplayMode) then
  begin
    FWidth := aDisplayMode.Width;
    FHeight := aDisplayMode.Height;
    FFrequency := aDisplayMode.Frequency;
    FBitsPerPixel := aDisplayMode.BitsPerPixel;
  end;
end;

function TDisplayMode.Equals(const aDisplayMode: IDisplayMode): Boolean;
begin
  Result := (FWidth=aDisplayMode.Width) and
    (FHeight=aDisplayMode.Height) and
    (FFrequency=aDisplayMode.Frequency) and
    (FBitsPerPixel=aDisplayMode.BitsPerPixel);
end;

function TDisplayMode.ToString: string;
begin
  Result := Format('%dx%d, %d Hz, %d bits',
    [FWidth, FHeight, FFrequency, FBitsPerPixel])
end;

function TDisplayMode.LoadFromXML(const parentNode: IXmlDomNode): Boolean;
var
  intStr: String;
begin
  Result := False;

  if not Assigned(parentNode) then
    Exit;

  // Resolution
  intStr := GetNodeValue(parentNode, cstNodeDisplayMode + '/' + cstNodeWidth);
  FWidth := StrToIntDef(intStr, 0);

  intStr := getNodeValue(parentNode, cstNodeDisplayMode + '/' + cstNodeHeight);
  FHeight := StrToIntDef(intStr, 0);

  // frequency
  intStr := GetNodeValue(parentNode, cstNodeDisplayMode + '/' + cstNodeFrequency);
  FFrequency := StrToIntDef(intStr, 0);

  // Bits per pixel
  intStr := getNodeValue(parentNode, cstNodeDisplayMode + '/' + cstNodeBitsPerPixel);
  FBitsPerPixel := StrToIntDef(intStr, 0);

  Result := True;
end;

function TDisplayMode.SaveToXML(const xmlDocument: IXMLDomDocument;
  const parentNode: IXmlDomNode): Boolean;
var
  aNode: IXMLDomNode;
begin
  Result := False;

  if not Assigned(parentNode) then
    Exit;

  aNode := xmlDocument.CreateElement(cstNodeDisplayMode);
  parentNode.appendChild(aNode);

  // Resolution
  setNodeValue(xmlDocument, aNode, cstNodeWidth, IntToStr(FWidth));
  setNodeValue(xmlDocument, aNode, cstNodeHeight, IntToStr(FHeight));

  // frequency
  setNodeValue(xmlDocument, aNode, cstNodeFrequency, IntToStr(FFrequency));

  // Bits per pixel
  setNodeValue(xmlDocument, aNode, cstNodeBitsPerPixel, IntToStr(FBitsPerPixel));

  Result := True;
end;

{$ENDREGION}

end.
