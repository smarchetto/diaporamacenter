unit DiaporamaCenterSettings;

interface

uses
  HttpSettings, ScheduleAction;

type
  // Diaporama center settings like folders, urls, and so on
  TDiaporamaCenterSettings = class
  private
    // Main folder path
    FPath: string;
    // Cache folder path
    FRepositoryPath: string;
    // Device folder path
    FDevicePath: string;
    // Template folder path
    FTemplatePath: string;
    // Template list file path
    FTypeFilePath: string;
    // Diaporama list file path
    FDiaporamaListFilePath: string;
    // HTTP settings
    FHttpSettings: THttpSettings;
    // Auto download of diaporama
    FDiaporamaAutoUpdate: Boolean;
    FDiaporamaUpdateTime: TActionPeriodicity;

    function GetPath: string;
    function GetDevicePath: string;
    procedure SetDevicePath(const value: string);
    function GetRepositoryPath: string;
    procedure SetRepositoryPath(const value: string);
    function GetTemplatePath: string;
    procedure SetTemplatePath(const value: string);
    function GetTypeFilePath: string;
    procedure SetTypeFilePath(const value: string);
    procedure SetDiaporamaListFilePath(const value: string);
    function GetDiaporamaListFilePath: string;
    function GetSettingFilePath: string;
    function GetScheduleFilePath: string;
   public
    constructor Create(const aPath: string);
    destructor Destroy; override;

    function Equals(anObject: TObject): Boolean; override;
    function Copy: TDiaporamaCenterSettings;
    procedure Assign(const diaporamaCenterSettings: TDiaporamaCenterSettings);
    procedure Fix;

    function LoadFromXML(const xmlFilePath: string): Boolean;
    function SaveToXML(const xmlFilePath: string): Boolean;

    function LoadSettings: Boolean;
    function SaveSettings: Boolean;

    property Path: string read GetPath;
    property HttpSettings: THttpSettings read FHttpSettings;
    property DevicePath: string read GetDevicePath write SetDevicePath;
    property RepositoryPath: string read GetRepositoryPath
      write SetRepositoryPath;
    property TemplatePath: string read GetTemplatePath write SetTemplatePath;
    property TypeFilePath: string read GetTypeFilePath write SetTypeFilePath;
    property DiaporamaListFilePath: string read GetDiaporamaListFilePath
       write SetDiaporamaListFilePath;
    property ScheduleFilePath: string read GetScheduleFilePath;
  end;


implementation

uses
  SysUtils, MSXML2_TLB,
  DiaporamaUtils;

const
  cstDevicePath = 'Devices';
  cstTemplatePath = 'Templates';
  cstRepositoryPath = 'Cache';
  cstTypeFileName = 'Types';
  cstFDiaporamaListFileName = 'DiaporamaList';

  cstNodeDiaporamaCenter = 'DiaporamaCenter';
  cstNodeRepositoryPath = 'RepositoryPath';
  cstNodeTemplatePath = 'TemplatePath';
  cstNodeDevicePath = 'DevicePath';

  cstNodeTypeFilePath = 'TypeFilePath';
  cstNodeDiaporamaListFilePath = 'DiaporamaListFilePath';

  cstNodeHttpSettings = 'HttpSettings';

  cstNodeDiaporamaAutoUpdate = 'DiaporamaAutoUpdate';
  cstDiaporamaUpdateTime = 'DiaporamaUpdateTime';


constructor TDiaporamaCenterSettings.Create(const aPath: string);
begin
  FPath := aPath;
  FRepositoryPath := '';
  FDevicePath := '';
  FTemplatePath := '';
  FTypeFilePath := '';
  FDiaporamaListFilePath := '';
  FHttpSettings := THttpSettings.Create;
  FDiaporamaAutoUpdate := False;
  FDiaporamaUpdateTime := TActionPeriodicity.Create(apEveryHour, 0);
end;

destructor TDiaporamaCenterSettings.Destroy;
begin
  FHttpSettings.Free;
  FDiaporamaUpdateTime.Free;
  inherited;
end;

procedure TDiaporamaCenterSettings.Assign(
  const diaporamaCenterSettings: TDiaporamaCenterSettings);
begin
  if Assigned(diaporamaCenterSettings) then
  begin
    FPath := diaporamaCenterSettings.FPath;
    FHttpSettings.Assign(diaporamaCenterSettings.FHttpSettings);
    FRepositoryPath := diaporamaCenterSettings.FRepositoryPath;
    FDevicePath := diaporamaCenterSettings.FDevicePath;
    FTemplatePath := diaporamaCenterSettings.FTemplatePath;
    FTypeFilePath := diaporamaCenterSettings.FTypeFilePath;
    FDiaporamaListFilePath := diaporamaCenterSettings.FDiaporamaListFilePath;
  end;
end;

procedure TDiaporamaCenterSettings.Fix;
begin
  FPath := Path;
  FHttpSettings.Assign(HttpSettings);
  FRepositoryPath := RepositoryPath;
  FDevicePath := DevicePath;
  FTemplatePath := TemplatePath;
  FTypeFilePath := TypeFilePath;
  FDiaporamaListFilePath := DiaporamaListFilePath;
end;

function TDiaporamaCenterSettings.Copy: TDiaporamaCenterSettings;
begin
  Result := TDiaporamaCenterSettings.Create('');
  Result.Assign(Self);
end;

function TDiaporamaCenterSettings.Equals(anObject: TObject): Boolean;
var
  diaporamaCenterSettings: TDiaporamaCenterSettings;

  function SamePath(const path1, path2: string): Boolean;
  begin
    Result := SameText(IncludeTrailingBackSlash(path1),
      IncludeTrailingBackSlash(path2));
  end;

begin
  if Assigned(anObject) and (anObject is TDiaporamaCenterSettings) then
  begin
    diaporamaCenterSettings := TDiaporamaCenterSettings(anobject);
    Result := Assigned(diaporamaCenterSettings) and
      SamePath(FPath, diaporamaCenterSettings.FPath) and
      SamePath(FRepositoryPath, diaporamaCenterSettings.FRepositoryPath) and
      SamePath(FDevicePath, diaporamaCenterSettings.FDevicePath)  and
      SamePath(FTemplatePath, diaporamaCenterSettings.FTemplatePath) and
      SamePath(FTypeFilePath, diaporamaCenterSettings.FTypeFilePath) and
      SamePath(FDiaporamaListFilePath, diaporamaCenterSettings.FDiaporamaListFilePath) and
      FHttpSettings.Equals(diaporamaCenterSettings.FHttpSettings);
  end else
    Result := false;
end;

function TDiaporamaCenterSettings.LoadFromXML(
  const xmlFilePath: string): Boolean;
var
  xmlDocument: IXMLDomDocument;
  aNode: IXMLDomNode;
begin
  Result := false;

  if not FileExists(xmlFilePath) then
    raise Exception.Create(Format('Cannot find configuration file %s',
      [xmlFilePath]));

  xmlDocument := coDomDocument40.Create;
  xmlDocument.Load(xmlFilePath);

  if xmlDocument.ParseError.ErrorCode=0 then
  begin
    FDevicePath := GetNodeValue(xmlDocument.DocumentElement, cstNodeDevicePath);

    FRepositoryPath := GetNodeValue(xmlDocument.DocumentElement,
      cstNodeRepositoryPath);

    FTemplatePath := GetNodeValue(xmlDocument.DocumentElement,
      cstNodeTemplatePath);

    FDiaporamaListFilePath := GetNodeValue(xmlDocument.DocumentElement,
      cstNodeDiaporamaListFilePath);

    FTypeFilePath := GetNodeValue(xmlDocument.DocumentElement,
      cstNodeTypeFilePath);

    FHttpSettings.LoadFromXML(xmlDocument.DocumentElement);

    FDiaporamaAutoUpdate := getNodeValueAsBoolean(xmlDocument.DocumentElement,
      cstNodeDiaporamaAutoUpdate, False);

    aNode := xmlDocument.DocumentElement.selectSingleNode(cstDiaporamaUpdateTime);
    FDiaporamaUpdateTime.LoadFromXML(aNode);

    Result := True;
  end;
end;

function TDiaporamaCenterSettings.SaveToXML(const xmlFilePath: string): Boolean;
var
  xmlDocument: IXMLDomDocument;
  aNode: IXMLDomNode;
begin
  xmlDocument := coDomDocument40.Create;
  xmlDocument.Async := False;

  xmlDocument.documentElement := xmlDocument.CreateElement(cstNodeDiaporamaCenter);

  SetNodeValue(xmlDocument, xmlDocument.DocumentElement,
    cstNodeDevicePath, FDevicePath);

  SetNodeValue(xmlDocument, xmlDocument.DocumentElement, cstNodeRepositoryPath,
    FRepositoryPath);

  SetNodeValue(xmlDocument, xmlDocument.DocumentElement, cstNodeTemplatePath,
    FTemplatePath);

  SetNodeValue(xmlDocument, xmlDocument.DocumentElement,
    cstNodeDiaporamaListFilePath, FDiaporamaListFilePath);

  SetNodeValue(xmlDocument, xmlDocument.DocumentElement, cstNodeTypeFilePath,
    FTypeFilePath);

  FHttpSettings.SaveToXML(xmlDocument, xmlDocument.DocumentElement);

  SetNodeValue(xmlDocument, xmlDocument.DocumentElement,
    cstNodeDiaporamaAutoUpdate, BoolToStr(FDiaporamaAutoUpdate));

  aNode := xmlDocument.CreateElement(cstDiaporamaUpdateTime);
  xmlDocument.DocumentElement.AppendChild(aNode);
  FDiaporamaUpdateTime.SaveToXML(xmlDocument, aNode);

  xmlDocument.save(xmlFilePath);

  Result := True;
end;

function TDiaporamaCenterSettings.GetSettingFilePath: string;
begin
  Result := GetPath + 'DiaporamaCenter.xml';
end;

function TDiaporamaCenterSettings.GetScheduleFilePath: string;
begin
  Result := GetPath + 'Schedule.xml';
end;

function TDiaporamaCenterSettings.SaveSettings: Boolean;
begin
  Result := SaveToXML(GetSettingFilePath);
end;

function TDiaporamaCenterSettings.LoadSettings: Boolean;
begin
  Result := LoadFromXML(GetSettingFilePath);
end;

function TDiaporamaCenterSettings.GetPath: string;
begin
  Result := IncludeTrailingBackSlash(FPath);
end;

function TDiaporamaCenterSettings.GetDevicePath: string;
begin
  if (FDevicePath<>'') and DirectoryExists(FDevicePath) then
    Result := IncludeTrailingBackSlash(FDevicePath)
  else
    Result :=  IncludeTrailingBackSlash(GetPath + cstDevicePath);
end;

procedure TDiaporamaCenterSettings.SetDevicePath(const value: string);
begin
  FDevicePath := value;
end;

function TDiaporamaCenterSettings.GetRepositoryPath: string;
begin
  if (FRepositoryPath<>'') and DirectoryExists(FRepositoryPath) then
    Result := IncludeTrailingBackSlash(FRepositoryPath)
  else
    Result := IncludeTrailingBackSlash(GetPath + cstRepositoryPath);
end;

procedure TDiaporamaCenterSettings.SetRepositoryPath(const value: string);
begin
  FRepositoryPath := value;
end;

function TDiaporamaCenterSettings.GetTemplatePath: string;
begin
  if (FTemplatePath<>'') and DirectoryExists(FTemplatePath) then
    Result := IncludeTrailingBackSlash(FTemplatePath)
  else
    Result := IncludeTrailingBackSlash(GetPath + cstTemplatePath);
end;

procedure TDiaporamaCenterSettings.SetTemplatePath(const value: string);
begin
  FTemplatePath := value;
end;

function TDiaporamaCenterSettings.GetDiaporamaListFilePath: string;
begin
  if (FDiaporamaListFilePath<>'') and FileExists(FDiaporamaListFilePath) then
    Result := FDiaporamaListFilePath
  else
    Result := GetRepositoryPath + cstFDiaporamaListFileName;
  Result := IncludeXMLExtension(Result);
end;

procedure TDiaporamaCenterSettings.SetDiaporamaListFilePath(const value: string);
begin
  FDiaporamaListFilePath := value
end;

function TDiaporamaCenterSettings.GetTypeFilePath: string;
begin
  if (FTypeFilePath<>'') and FileExists(FTypeFilePath) then
    Result := FTypeFilePath
  else
    Result := GetTemplatePath + cstTypeFileName;
  Result := IncludeXMLExtension(Result);
end;

procedure TDiaporamaCenterSettings.SetTypeFilePath(const value: string);
begin
  FTypeFilePath := value
end;

end.
