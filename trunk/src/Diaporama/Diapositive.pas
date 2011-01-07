unit Diapositive;

interface

uses
  Classes, Generics.Defaults, Generics.Collections, MSXML2_TLB,
  DiaporamaEntity, DiapositiveType, DiaporamaResource;

const
  DIAPOSITIVE_DURATION_S = 10;

type
  // Diapositve to be displayed on a display device
  // Content is HTML generated from
  // - a XSL transform file (type or template)
  // - the XML fragment of diapositive
  TDiapositive = class(TDiaporamaEntity)
  private
    FTypeName: string;
    // Diapositive template
    FType: TDiapositiveType;
    // Données XML du diapositive
    FData: IXMLDomNode;
    // Items : images, animations,... contenus dans la page HTML
    FMedias: TObjectList<TDiaporamaResource>;
    // Durée de la diapositive en ms
    // FDuration: Integer;

    function GetMediaCount: Integer;
    function GetMedia(const index: Integer): TDiaporamaResource;
    function GetMedias: TEnumerable<TDiaporamaResource>;
  public
    constructor Create(const anIndex: Integer = -1); reintroduce; overload;
    constructor Create(const anId: string;
      const aTypeName: string;
      const aData: IXMLDomNode;
      const anIndex: Integer); reintroduce; overload;
    destructor Destroy; override;

    procedure LoadFromXML(const aNode: IXMLDomNode);

    procedure GetContent(const outputStream: TStream);

    property TypeName: string read FTypeName;
    property DiapositiveType: TDiapositiveType read FType;

    property MediaCount: Integer read GetMediaCount;
    property Media[const index: Integer]: TDiaporamaResource read GetMedia;
    property Medias: TEnumerable<TDiaporamaResource> read GetMedias;

    //property Duration: Integer read FDuration;
  end;


implementation

uses
  SysUtils, ActiveX,
  DiaporamaUtils, Logs;

const
  // XML markups
  cstXMLAttrDiapositiveId = 'id';
  cstXMLAttrDiapositiveType = 'type';

  // Error messages
  cstXSLTransformError =
    'The XSL transform (template ''%s'') failed on slide ID = %s';

constructor TDiapositive.Create(const anIndex: Integer = -1);
begin
  Create('', '', nil, anIndex);
end;

constructor TDiapositive.Create(
  const anID: string;
  const aTypeName: string;
  const aData: IXMLDomNode;
  const anIndex: Integer);
begin
  inherited Create(anID, anIndex);
  FData := aData;
  FType := TDiapositiveType.GetDiapositiveType(FTypeName);
  FMedias := TObjectList<TDiaporamaResource>.Create;
  //FDuration := DEFAULT_DURATION;
end;

destructor TDiapositive.Destroy;
begin
  FData := nil;
  FMedias.Free;
  inherited;
end;

procedure TDiapositive.LoadFromXML(const aNode: IXMLDomNode);
var
  aMedia: TDiaporamaResource;
  i: integer;
begin
  if not Assigned(aNode) then
    Exit;

  FID := getAttributeValue(aNode, cstXMLAttrDiapositiveId);

  FTypeName := getAttributeValue(aNode, cstXMLAttrDiapositiveType);

  FType := TDiapositiveType.GetDiapositiveType(FTypeName);

  FData := aNode;

  if Assigned(FData) and Assigned(FType) then
  begin
    for i:=0 to FData.ChildNodes.Length-1 do
    begin
      if FType.MediaMark(FData.ChildNodes[i].NodeName) then
      begin
        // TODO : manage media date
        aMedia := TDiaporamaResource.Create('', FType.MediaURL,
          FType.Name + '\' + FType.MediaDir);
        aMedia.LoadFromXML(FData.ChildNodes[i]);
        FMedias.Add(aMedia);
      end;
    end;
  end;
end;

function TDiapositive.GetMediaCount: Integer;
begin
  Result := FMedias.Count;
end;

function TDiapositive.GetMedia(const index: Integer): TDiaporamaResource;
begin
  Result := TDiaporamaResource(FMedias[index]);
end;

function TDiapositive.GetMedias: TEnumerable<TDiaporamaResource>;
begin
  Result := FMedias;
end;

procedure TDiapositive.GetContent(const outputStream: TStream);
var
  aStreamAdapter: TStreamAdapter;
begin
  // TODO - refactoring : move XSL transformation to DiapositiveType
  if not Assigned(FData) or not Assigned(FType) then
    Exit;

  // Load XSL template if not loaded
  if not FType.TemplateLoaded then
    FType.LoadTemplate;
  if not FType.TemplateLoaded then
    Exit;

  aStreamAdapter := TStreamAdapter.Create(outputStream);
  try
    try
      FType.XSLProcessor.input := FData;

      // Start mode
      // FXSLProcessor.setStartMode('mytestmode','');
      // Parametres
      // XSLProcessor.addParameter('mytestparam','hello','');
      // create output stream...

      // XSL transforma
      FType.XSLProcessor.output := aStreamAdapter as IStream;
      if not FType.XSLProcessor.transform then
        raise Exception.Create(Format(cstXSLTransformError,
          [FType.Name, Self.ID]));
    except
      on e: Exception do
      begin
        LogEvent(Self.ClassName, ltError, e.Message);
      end;
    end;
  finally
    FType.XSLProcessor.Reset;
  end;
end;

end.
