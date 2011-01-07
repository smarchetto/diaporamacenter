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
    // Location (not used yet)
    FLocation: string;
    // Control settings
    FControlSettings: TDeviceControlSettings;
    // Configuration file name
    FFileName: string;

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
    property FileName: string read GetFileName write FFileName;

    property ControlSettings: TDeviceControlSettings
      read FControlSettings;

    property Location: string read FLocation write FLocation;
  end;

implementation

uses
  MSXML2_TLB, SysUtils, StrUtils,
  DiaporamaUtils;

const
  cstDiaporamaDevice = 'DiaporamaDevice';
  cstName = 'Name';
  cstPowerOnTime = 'PowerOnTime';
  cstPowerOffTime = 'PowerOffTime';
  cstAutoPower = 'AutoPower';

constructor TDiaporamaDeviceSettings.Create;
begin
  FName := '';
  FFileName := '';
  FDeviceInfo := TDiaporamaDeviceInfo.Create;
  FDisplayMode := TDisplayMode.Create;
  FControlSettings := TDeviceControlSettings.Create;
  FLocation := '';
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

  // TODO : Doit on assigner le deviceInfo dans le Assign de DeviceSettings
  FDeviceInfo.Assign(deviceSettings.DeviceInfo);
  
  FDisplayMode.Assign(deviceSettings.DisplayMode);

  FControlSettings.Assign(deviceSettings.ControlSettings);

  FLocation := deviceSettings.Location;
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
      FControlSettings.Equals(deviceSettings.ControlSettings);
      //(SameText(FLocation, deviceSettings.Location);
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

  // Nom de fichier
  FFileName := ExtractFileName(xmlFilePath);

  xmlDocument := coDomDocument40.Create;
  xmlDocument.Load(xmlFilePath);

  if xmlDocument.ParseError.ErrorCode=0 then
  begin
    // Noeud DiaporamaDevice
    if SameText(xmlDocument.DocumentElement.NodeName, cstDiaporamaDevice) then
    begin
      // Nom
      FName := getNodeValue(xmlDocument.DocumentElement,
        cstName);

      // Informations de périphérique
      FDeviceInfo.LoadFromXML(xmlDocument.DocumentElement);

      // Lecture des du mode d'affichage
      FDisplayMode.LoadFromXML(xmlDocument.DocumentElement);

      // Paramétrage lié au controle de videoprojecteur
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

  // Racine
  xmlDocument.documentElement := xmlDocument.createElement(cstDiaporamaDevice);

  // Nom
  setNodeValue(xmlDocument,
    xmlDocument.DocumentElement, cstName, FName);

  // Informations de périphérique
  FDeviceInfo.SaveToXML(xmlDocument, xmlDocument.DocumentElement);

  // Lecture des du mode d'affichage
  FDisplayMode.SaveToXML(xmlDocument, xmlDocument.DocumentElement);

  // Paramétrage lié au controle de videoprojecteur
  FControlSettings.SaveToXML(xmlDocument, xmlDocument.DocumentElement);

  xmlDocument.save(xmlFilePath);

  Result := True;
end;

end.
