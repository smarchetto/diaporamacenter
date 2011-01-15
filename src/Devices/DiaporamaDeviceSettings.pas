unit DiaporamaDeviceSettings;

interface

uses
  Types,
  DiaporamaDeviceInfo, DisplayMode, DeviceControl,
  DeviceControlSettings, ScheduleAction;

type
  // Device display settings
  // TODO : inherit from TPersistent
  TDiaporamaDeviceSettings = class
  private
    // Name
    FName: string;
    // Infos
    FDeviceInfo: TDiaporamaDeviceInfo;
    // Display mode
    FDisplayMode: TDisplayMode;
    // Videoprojector control settings
    FControlSettings: TDeviceControlSettings;
    // Configuration file name
    FFileName: string;
    // Full screen
    FFullScreen: boolean;

    function GetFileName: string;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Assign(const deviceSettings: TDiaporamaDeviceSettings);
    function Equals(anObject: TObject): Boolean; override;
    function Copy: TDiaporamaDeviceSettings;

    function LoadFromXML(const xmlFilePath: string): Boolean;
    function SaveToXML(const xmlFilePath: string): Boolean;

    property Name: string read FName write FName;
    property DeviceInfo: TDiaporamaDeviceInfo read FDeviceInfo;

    property DisplayMode: TDisplayMode read FDisplayMode;

    property FullScreen: boolean read FFullScreen write FFullScreen;

    property ControlSettings: TDeviceControlSettings
      read FControlSettings;

    property FileName: string read GetFileName write FFileName;
  end;

implementation

uses
  MSXML2_TLB, SysUtils, StrUtils,
  DiaporamaUtils;

const
  cstXMLNodeDiaporamaDevice = 'DiaporamaDevice';
  cstXMLNodeName = 'Name';
  cstXMLNodeFullScreen = 'FullScreen';

constructor TDiaporamaDeviceSettings.Create;
begin
  FName := '';
  FFileName := '';
  FDeviceInfo := TDiaporamaDeviceInfo.Create;
  FDisplayMode := TDisplayMode.Create;
  FFullScreen := false;
  FControlSettings := TDeviceControlSettings.Create;
end;

destructor TDiaporamaDeviceSettings.Destroy;
begin
  FDeviceInfo.Free;
  FDisplayMode.Free;
  FControlSettings.Free;
  inherited;
end;

procedure TDiaporamaDeviceSettings.Assign(
  const deviceSettings: TDiaporamaDeviceSettings);
begin
  FName := deviceSettings.Name;
  FFileName := deviceSettings.FileName;

  FDeviceInfo.Assign(deviceSettings.DeviceInfo);
  
  FDisplayMode.Assign(deviceSettings.DisplayMode);

  FFullScreen := deviceSettings.FullScreen;

  FControlSettings.Assign(deviceSettings.ControlSettings);
end;

function TDiaporamaDeviceSettings.Equals(anObject: TObject): Boolean;
var
  deviceSettings: TDiaporamaDeviceSettings;
begin
  if Assigned(anObject) and (anObject is TDiaporamaDeviceSettings) then
  begin
    deviceSettings := TDiaporamaDeviceSettings(anObject);
    Result :=
      SameText(FName, deviceSettings.Name) and
      SameText(FFileName, deviceSettings.FileName) and
      FDisplayMode.Equals(deviceSettings.DisplayMode) and
      FControlSettings.Equals(deviceSettings.ControlSettings) and
      (FFullScreen = deviceSettings.FullScreen);
  end else
    Result := false;
end;

function TDiaporamaDeviceSettings.Copy: TDiaporamaDeviceSettings;
begin
  Result := TDiaporamaDeviceSettings.Create;
  Result.Assign(Self);
end;

function TDiaporamaDeviceSettings.GetFileName: string;
begin
  if FFileName<>'' then
    Result := IncludeXMLExtension(FFileName)
  else if FName<>'' then
    Result := IncludeXMLExtension(FName);
end;

function TDiaporamaDeviceSettings.LoadFromXML(const xmlFilePath: string): Boolean;
var
  xmlDocument: IXMLDomDocument;
begin
  Result := False;

  if not FileExists(xmlFilePath) then
    raise Exception.Create(Format('Cannot find configuration file %s',
      [xmlFilePath]));

  // File name
  FFileName := ExtractFileName(xmlFilePath);

  xmlDocument := coDomDocument40.Create;
  xmlDocument.Load(xmlFilePath);

  if xmlDocument.ParseError.ErrorCode=0 then
  begin
    // DiaporamaDevice node
    if SameText(xmlDocument.DocumentElement.NodeName, cstXMLNodeDiaporamaDevice) then
    begin
      // Name
      FName := getNodeValue(xmlDocument.DocumentElement, cstXMLNodeName);

      // Infos
      FDeviceInfo.LoadFromXML(xmlDocument.DocumentElement);

      // Display mode
      FDisplayMode.LoadFromXML(xmlDocument.DocumentElement);

      // Full screen
      FFullScreen := GetNodeValueAsBoolean(xmlDocument.DocumentElement,
        cstXMLNodeFullScreen, false);

      // Videoprojector control settings
      FControlSettings.LoadFromXML(xmlDocument.DocumentElement);

      Result := True;
    end;
  end;
end;

function TDiaporamaDeviceSettings.SaveToXML(const xmlFilePath: string): Boolean;
var
  xmlDocument: IXMLDomDocument;
begin
  xmlDocument := coDomDocument40.Create;
  xmlDocument.Async := False;

  xmlDocument.documentElement := xmlDocument.createElement(cstXMLNodeDiaporamaDevice);

  // Name
  setNodeValue(xmlDocument, xmlDocument.DocumentElement, cstXMLNodeName, FName);

  // Device infos
  FDeviceInfo.SaveToXML(xmlDocument, xmlDocument.DocumentElement);

  // Display mode
  FDisplayMode.SaveToXML(xmlDocument, xmlDocument.DocumentElement);

  // Full screen
  SetNodeValue(xmlDocument, xmlDocument.DocumentElement,
    cstXMLNodeFullScreen, BoolToStr(FFullScreen));

  // Videoprojector control settings
  FControlSettings.SaveToXML(xmlDocument, xmlDocument.DocumentElement);

  xmlDocument.save(xmlFilePath);

  Result := True;
end;

end.
