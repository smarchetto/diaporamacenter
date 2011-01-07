unit DiapositiveType;

interface

uses
  Generics.Defaults, Generics.Collections, MSXML2_TLB,
  DiaporamaResource;

type
  TDiapositiveType = class
  private
    // Name
    FName: string;
    // XSL template XML source
    FXMLTemplate: IXMLDomDocument2;
    // XSL template
    FXSLTemplate: IXSLTemplate;
    // XSL processor
    FXSLProcessor: IXSLProcessor;
    // Status
    FError: string;
    // URL to download resources (template resources like stylesheets...),
    // also used by default for diapositive resources...
    FURL: string;
    // Specific URL to download diapositive stuff (images)...
    FMediaURL: string;
    // Mark value in diaporama XML that relate to a media
    FMediaMark: string;
    // Sub directory in cache for medias
    FMediaDir: string;
    // Other includes like style sheet, background image, sound, and so on...
    FTemplateResources: TObjectList<TDiaporamaResource>;

    // Loading status
    FTemplateLoaded: Boolean;

    // Template folder
    class var FTemplatePath: string;
    // Link to whole template list
    class var FTemplateList: TObjectList<TDiapositiveType>;

    function GetTemplateName: string;
    function GetTemplateLoaded: Boolean;

    function GetMediaURL: string;

  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadTemplate;

    function MediaMark(const aMarkName: string): Boolean;

    function LoadFromXML(const parentNode: IXmlDomNode): Boolean;

    class function GetDiapositiveType(const typeName: string): TDiapositiveType;
    class function LoadTypeListFromXML(const xmlFilePath: string): Boolean;
    class procedure ClearTypeList;
    class procedure ReleaseTypeList;

    property Name: string read FName;

    property Template: IXMLDomDocument2 read FXMLTemplate;
    property TemplateName: string read GetTemplateName;
    property TemplateLoaded: Boolean read GetTemplateLoaded;
    property XSLProcessor: IXSLProcessor read FXSLProcessor;

    property URL: string read FURL;

    property MediaURL: string read GetMediaURL;
    property MediaDir: string read FMediaDir;

    // FIXME : use TEnumerable<TDiaporamaResource>
    property TemplateResources: TObjectList<TDiaporamaResource>
      read FTemplateResources;

    class property TemplatePath: string read FTemplatePath write
      FTemplatePath;
    class property TemplateList: TObjectList<TDiapositiveType> read FTemplateList;
  end;

implementation

uses
  SysUtils, ActiveX,
  Logs;

const
  TEMPLATE_TYPE = 'xsl';
  cstTypeNodeList = '/DiapositiveTypes/DiapositiveType';
  cstXMLNodeTypeName = 'Name';
  cstXMLNodeTypeURL = 'URL';
  cstXMLNodeTypeMediaMark = 'MediaMark';
  cstXMLNodeTypeMediaURL = 'MediaURL';
  cstXMLNodeTypeMediaDir = 'MediaDir';
  cstXMLNodeTypeResource = 'Resource';

  cstTypeFileNotFoundError = 'Cannot find type file %s';
  cstTypeFileParsingError = 'Error while parsing file type %s : %s';
  cstTemplateNotFoundError = 'Cannot find template %s';
  cstTemplateParsingError = 'Error while parsing template %s : %s';

  READYSTATE_LOADED = 2;

constructor TDiapositiveType.Create;
begin
  FName := '';
  FError := '';
  FURL := '';
  FMediaMark := 'image';
  FMediaURL := '';
  FTemplateLoaded := False;
  FTemplateResources := TObjectList<TDiaporamaResource>.Create(true);

  FXMLTemplate := nil;
  FXSLTemplate := nil;
  FXSLProcessor := nil;
end;

destructor TDiapositiveType.Destroy;
begin
  FTemplateResources.Free;
  inherited;
end;

function TDiapositiveType.GetTemplateName: string;
begin
  if FName<>'' then
    Result := FName + '.' + TEMPLATE_TYPE
  else
    Result := '';
end;

function TDiapositiveType.GetTemplateLoaded: Boolean;
begin
  Result := FTemplateLoaded;
  //Result := Assigned(FXSLProcessor) and Assigned(FXSLTemplate) and
  //  (FXSLProcessor.ReadyState=READYSTATE_LOADED);
end;

function TDiapositiveType.GetMediaURL: string;
begin
  if FMediaURL<>'' then
    Result := FMediaURL
  else
    Result := FURL;
end;

procedure TDiapositiveType.LoadTemplate;
var
  templateFullPath: string;
begin
  FTemplateLoaded := False;

  templateFullPath := IncludeTrailingBackSlash(FTemplatePath) + GetTemplateName;

  try
    if not FileExists(templateFullPath) then
      raise Exception.Create(Format(cstTemplateNotFoundError,
        [templateFullPath]));

    FXMLTemplate := CoFreeThreadedDOMDocument40.Create;
    FXMLTemplate.Load(templateFullPath);

    if FXMLTemplate.ParseError.ErrorCode=0 then
    begin
      FXMLTemplate.async := False;

      FXMLTemplate.validateOnParse := False;
      FXMLTemplate.setProperty('NewParser',True);

      FXSLTemplate := CoXSLTemplate40.Create;
      FXSLTemplate.stylesheet := FXMLTemplate;

      FXSLProcessor := FXSLTemplate.createProcessor;

      FTemplateLoaded := Assigned(FXSLProcessor) and Assigned(FXSLTemplate);
    end else
      raise Exception.Create(
        Format(cstTemplateParsingError, [FName,
          FXMLTemplate.ParseError.Reason]));
  except
    on e: Exception do
    begin
      LogEvent(Self.ClassName, ltError, e.Message);
    end;
  end;
end;

function TDiapositiveType.MediaMark(const aMarkName: string): Boolean;
begin
  Result := SameText(aMarkName, FMediaMark);
end;

class function TDiapositiveType.GetDiapositiveType(
  const typeName: string): TDiapositiveType;
begin
  for Result in FTemplateList do
  begin
    if sameText(Result.Name, typeName) then
      Exit;
  end;
  Result := nil;
end;

function TDiapositiveType.LoadFromXML(const parentNode: IXmlDomNode): Boolean;
var
  aNode: IXmlDomNode;
  aResource: TDiaporamaResource;
  i: integer;
begin
  Result := False;
  if not Assigned(parentNode) then
    Exit;

  aNode := parentNode.SelectSingleNode('./' + cstXMLNodeTypeName);
  if Assigned(aNode) then
    FName := aNode.text;

  aNode := parentNode.selectSingleNode('./' + cstXMLNodeTypeURL);
  if Assigned(aNode) then
    FURL := aNode.text;

  aNode := parentNode.selectSingleNode('./' + cstXMLNodeTypeMediaMark);
  if Assigned(aNode) then
    FMediaMark := aNode.text;

  aNode := parentNode.selectSingleNode('./' + cstXMLNodeTypeMediaURL);
  if Assigned(aNode) then
    FMediaURL := aNode.text;

  aNode := parentNode.selectSingleNode('./' + cstXMLNodeTypeMediaDir);
  if Assigned(aNode) then
    FMediaDir := aNode.text;

  for i := 0 to parentNode.ChildNodes.length-1 do
  begin
    aNode := parentNode.ChildNodes[i];
    if SameText(aNode.nodeName, cstXMLNodeTypeResource) then
    begin
      aResource := TDiaporamaResource.Create('', FURL, FName);
      aResource.LoadFromXML(aNode);
      FTemplateResources.Add(aResource);
    end;
  end;

  Result := True;
end;

class function TDiapositiveType.LoadTypeListFromXML(
  const xmlFilePath: string): Boolean;
var
  xmlDocument: IXMLDomDocument2;
  typeNodeList: IXmlDomNodeList;
  aDiapositiveType: TDiapositiveType;
  i: Integer;
begin
  Result := False;

  try
    if not FileExists(xmlFilePath) then
      raise Exception.Create(Format(cstTypeFileNotFoundError, [xmlFilePath]));

    xmlDocument := coDomDocument40.Create;
    xmlDocument.Load(xmlFilePath);

    if xmlDocument.parseError.errorCode=0 then
    begin
      typeNodeList := xmlDocument.selectNodes(cstTypeNodeList);

      for i:=0 to typeNodeList.Length-1 do
      begin
        aDiapositiveType := TDiapositiveType.Create;
        aDiapositiveType.LoadFromXML(typeNodeList[i]);
        FTemplateList.Add(aDiapositiveType);
      end;

      Result := True;
    end else
    raise Exception.Create(Format(cstTypeFileParsingError,
        [xmlFilePath, xmlDocument.ParseError.Reason]));
  except
    on e: Exception do
    begin
      LogEvent(Self.ClassName, ltError, e.Message);
    end;
  end;
end;

class procedure TDiapositiveType.ClearTypeList;
begin
  FTemplateList.Clear;
end;

class procedure TDiapositiveType.ReleaseTypeList;
begin
  FreeAndNil(FTemplateList);
end;


initialization
  TDiapositiveType.FTemplateList := TObjectList<TDiapositiveType>.Create;


end.
