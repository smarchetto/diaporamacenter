unit Diaporama;

interface

uses
  Generics.Defaults, Generics.Collections, MSXML2_TLB,
  Diapositive, DiapositiveType, Sequence,
  SequenceItem, DiaporamaEntity;

type
  TDiaporama = class;

  // Diaporama list class
  TDiaporamaList = class(TObjectList<TDiaporama>)
  private
  public
    function LoadFromXML(const xmlFilePath: string): Boolean; overload;
    function LoadFromXML(const parentNode: IXmlDomNode): Boolean; overload;

    function GetDiaporamaByID(const anID: string): TDiaporama;
    //function GetDiaporamaID(const aName: string): string;
    function GetDiaporamaByName(const aName: string): TDiaporama; overload;
    function GetDiaporamaIndex(const diaporamaID: string): Integer;
  end;

  // Diaporama class
  TDiaporama = class(TDiaporamaEntity)
  private
    // Name
    FName: string;
    // Entity list : diapositives or diaporamas (a diaporama can contain diaporama)
    // Un diaporama peut contenir d'autres diaporamas
    // TODO : rename FEntities en FItems
    FEntities: TObjectList<TDiaporamaEntity>;
    // Link to diapositives
    FDiapositives: TObjectList<TDiapositive>;
    // Link to diaporamas
    FDiaporamas: TDiaporamaList;
    // Play sequence
    FSequence: TSequence;

    function GetDiapositiveCount: Integer;
    function GetDiapositive(const index: Integer): TDiapositive;

    function GetDiaporamaCount: Integer;
    function GetDiaporama(const index: Integer): TDiaporama; overload;

    function GetItemCount: Integer;

    procedure Clear;
  public
    constructor Create(const anID: string;
      const anIndex: Integer=-1); reintroduce;
    destructor Destroy; override;

    function LoadFromXML(const parentNode: IXmlDomNode): Boolean; overload;
    function LoadFromXML(const xmlFilePath: string): Boolean; overload;

    function GetDiaporama(const aName: string): TDiaporama; overload;

    {function GetCurrentDiapositive: TDiapositive;
    function GetCurrentDiapositiveDuration: Integer;
    function GetNextDiapositive: TDiapositive;}

    // Returns all diapositives of the diaporama (and imported diaporamas)
    function GetAllDiapositives: TEnumerable<TDiapositive>;
    // Returns all diapositive types of the diaporama (and imported diaporamas)
    function GetAllDiapositiveTypes: TEnumerable<TDiapositiveType>;

    // Returns true if diaporama contains diapositives
    function HasContent: Boolean;

    property Name: string read FName;

    property DiapositiveCount: Integer read GetDiapositiveCount;
    property Diapositive[const index: Integer]: TDiapositive
      read GetDiapositive;
    property DiaporamaCount: Integer read GetDiaporamaCount;
    property ItemCount: Integer read GetItemCount;
    property Diaporama[const index: Integer]: TDiaporama
      read GetDiaporama;
    property Sequence: TSequence read FSequence;
  end;

implementation

uses
  SysUtils, Classes,
  DiaporamaUtils, DiapositiveSequenceItem, Logs;

const
  // XML markups
  cstDiaporamaNode = 'Diaporama';
  cstImportDiaporamaNode = 'ImportDiaporama';
  cstDiapositiveNode = 'Diapositive';
  cstSequenceNode = 'Sequence';
  cstDiaporamaNameAttr = 'name';
  cstDiaporamaXMLAttr = 'xml';
  cstDiaporamaListNode = 'Diaporamas';
  cstDiaporamaIDAttr = 'id';

  // Error messages
  cstDiaporamaNotFoundError = 'Cannot find diaporama %s';
  cstDiaporamaParsingError = 'Error while parsing diaporama %s in line %d: %s';

  cstDiaporamaListNotFoundError = 'Cannot find diaporama list %s';
  cstDiaporamaListParsingError =
    'Error while parsing diaporama list %s in line %d: %s';


{$REGION 'TDiaporamaList'}

{function TDiaporamaList.GetDiaporamaID(const aName: string): string;
var
  aDiaporama: TDiaporama;
begin
  aDiaporama := GetDiaporama(aName);
  if Assigned(aDiaporama) then
    Result := aDiaporama.ID
  else
    Result := '';
end;}

function TDiaporamaList.GetDiaporamaByID(const anID: string): TDiaporama;
begin
  for Result in Self do
  begin
    if SameText(Result.ID, anID) then
      Exit;
  end;
  Result := nil;
end;

function TDiaporamaList.GetDiaporamaByName(const aName: string): TDiaporama;
begin
  for Result in Self do
  begin
    if SameText(Result.Name, aName) then
      Exit;
  end;
  Result := nil;
end;

function TDiaporamaList.GetDiaporamaIndex(const diaporamaID: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to Count-1 do
  begin
    if sameStr(Items[i].ID, diaporamaID) then
    begin
      Result := i;
      Exit;
    end;
  end;
end;

function TDiaporamaList.LoadFromXML(const parentNode: IXmlDomNode): Boolean;
var
  //nodeList: IXMLDomNodeList;
  diaporamaNode: IXMLDomNode;
  aDiaporama: TDiaporama;
  anID: string;
  i: Integer;
begin
  Result := False;

  // Check that is a diaporama
  if not Assigned(parentNode) or
     not SameText(parentNode.NodeName, cstDiaporamaListNode) then
      Exit;

  Clear;

  for i := 0 to parentNode.ChildNodes.length-1 do
  begin
    diaporamaNode := parentNode.ChildNodes[i];

    if SameText(diaporamaNode.nodeName, cstDiaporamaNode) then
    begin
      // Diaporama ID
      anID := getAttributeValue(diaporamaNode, cstDiaporamaIDAttr);

      aDiaporama := TDiaporama.Create(anID);

      // Diaporama name
      aDiaporama.FName := getAttributeValue(diaporamaNode, cstDiaporamaNameAttr);

      Add(aDiaporama);
    end;
  end;

  Result := True;
end;

function TDiaporamaList.LoadFromXML(const xmlFilePath: string): Boolean;
var
  xmlDocument: IXMLDomDocument2;
  parentNode: IXmlDomNode;
begin
  Result := False;

  try
    if not FileExists(xmlFilePath) then
      raise Exception.Create(Format(cstDiaporamaNotFoundError, [xmlFilePath]));

    xmlDocument := CoDOMDocument40.Create;
    xmlDocument.async := False;

    // TODO : use option validateOnParse
    xmlDocument.validateOnParse := False;
    xmlDocument.setProperty('NewParser',True);

    xmlDocument.Load(xmlFilePath);

    if xmlDocument.parseError.errorCode=0 then
    begin
      parentNode := xmlDocument.DocumentElement;
      if Assigned(parentNode) then
        Result := LoadFromXML(parentNode);
  end else
  begin
    raise Exception.Create(Format(cstDiaporamaListParsingError,
      [xmlFilePath, xmlDocument.parseError.line, xmlDocument.parseError.reason]));
  end;
  except
    on e: Exception do
    begin
      LogEvent(Self.ClassName, ltError, e.Message);
      raise e;
    end;
  end;
end;

{$ENDREGION}

{$REGION 'TDiaporama'}

constructor TDiaporama.Create(const anID: string;
  const anIndex: Integer=-1);
begin
  inherited Create(anID, anIndex);
  FName := '';
  FEntities := TObjectList<TDiaporamaEntity>.Create;
  FDiapositives := TObjectList<TDiapositive>.Create(False);
  FDiaporamas := TDiaporamaList.Create;
  FSequence := nil;
end;

destructor TDiaporama.Destroy;
begin
  FEntities.Free;
  FDiapositives.Free;
  FDiaporamas.Free;
  FSequence.Free;
  inherited;
end;

function TDiaporama.GetItemCount: Integer;
begin
  Result := GetDiapositiveCount+GetDiaporamaCount;
end;

function TDiaporama.GetDiapositiveCount: Integer;
begin
  Result := FDiapositives.Count;
end;

function TDiaporama.GetDiapositive(const index: Integer): TDiapositive;
begin
  Result := FDiapositives[index];
end;

function TDiaporama.GetDiaporamaCount: Integer;
begin
  Result := FDiaporamas.Count;
end;

function TDiaporama.GetDiaporama(const aName: string): TDiaporama;
begin
  Result := FDiaporamas.GetDiaporamaByName(aName);
end;

function TDiaporama.GetDiaporama(const index: Integer): TDiaporama;
begin
  Result := FDiaporamas[index];
end;

function TDiaporama.HasContent: Boolean;
begin
  Result := (FDiaporamas.Count>0) or (FDiapositives.Count>0);
end;

procedure TDiaporama.Clear;
begin
  FName := '';
  FEntities.Clear;
  FDiapositives.Clear;
  FDiaporamas.Clear;
  if Assigned(FSequence) then
    FSequence.Clear;
end;

function TDiaporama.LoadFromXML(const xmlFilePath: string): Boolean;
var
  xmlDocument: IXMLDomDocument2;
  parentNode: IXmlDomNode;
  fileName: string;
begin
  Result := False;

  try
    if not FileExists(xmlFilePath) then
      raise Exception.Create(Format(cstDiaporamaNotFoundError, [xmlFilePath]));

    xmlDocument := CoDOMDocument40.Create;
    xmlDocument.async := False;

    // TODO : use validateOnParse
    xmlDocument.validateOnParse := False;
    xmlDocument.setProperty('NewParser',True);

    xmlDocument.Load(xmlFilePath);

    // TODO : secure ID extraction
    fileName := ExtractFileName(xmlFilePath);
    FID := Copy(fileName, 1, Length(fileName)-4);

    if xmlDocument.parseError.errorCode=0 then
    begin
      parentNode := xmlDocument.DocumentElement;
      if Assigned(parentNode) then
        Result := LoadFromXML(parentNode);
    end else
    begin
      raise Exception.Create(Format(cstDiaporamaParsingError,
        [xmlFilePath, xmlDocument.parseError.line, xmlDocument.parseError.reason]));
  end;
  except
    on e: Exception do
    begin
      LogEvent(Self.ClassName, ltError, e.Message);
    end;
  end;
end;

function TDiaporama.LoadFromXML(const parentNode: IXmlDomNode): Boolean;
var
  childNode: IXMLDomNode;
  aDiapositive: TDiapositive;
  aDiaporama: TDiaporama;
  xmlName: string;
  i, anIndex: Integer;
begin
  Result := False;

  // Check we have a diaporama node
  if not Assigned(parentNode) or
     not SameText(parentNode.NodeName, cstDiaporamaNode) then
      Exit;

  Clear;

  // Diaporama name
  FName := getAttributeValue(parentNode, cstDiaporamaNameAttr);

  anIndex := 0;

  for i:=0 to parentNode.ChildNodes.Length-1 do
  begin
    childNode := parentNode.ChildNodes[i];

    // Diapositive node ?
    if SameText(childNode.NodeName, cstDiapositiveNode) then
    begin
      aDiapositive := TDiapositive.Create(anIndex);
      Inc(anIndex);

      aDiapositive.LoadFromXML(childNode);

      if Assigned(aDiapositive) then
      begin
        FEntities.Add(aDiapositive);
        FDiapositives.Add(aDiapositive);
      end;
    end else
    // Or diaporama node ?
    if SameText(childNode.NodeName, cstDiaporamaNode) then
    begin
      aDiaporama := TDiaporama.Create('', anIndex);
      Inc(anIndex);

      xmlName := GetAttributeValue(childNode, cstDiaporamaXMLAttr);

      // TODO : manage child diaporama play
      if xmlName<>'' then
        aDiaporama.LoadFromXML(xmlName);

      if Assigned(aDiaporama) then
      begin
        FEntities.Add(aDiaporama);
        FDiaporamas.Add(aDiaporama);
      end;
    end else
    // Sequence node ?
    if SameText(childNode.NodeName, cstSequenceNode) then
    begin
      // One sequence per diaporama
      if not Assigned(FSequence) then
      begin
        FSequence := TSequence.Create;
        FSequence.LoadFromXML(childNode);
      end;
    end;
  end;

  Result := True;
end;

function TDiaporama.GetAllDiapositives: TEnumerable<TDiapositive>;
var
  aDiaporama: TDiaporama;
  diapositiveList: TEnumerable<TDiapositive>;
  allDiapositives: TObjectList<TDiapositive>;
begin
  allDiapositives := TObjectList<TDiapositive>.Create(False);
  allDiapositives.AddRange(FDiapositives);
  for aDiaporama in FDiaporamas do
  begin
    diapositiveList := aDiaporama.GetAllDiapositives;
    allDiapositives.AddRange(diapositiveList);
    diapositiveList.Free;
  end;
  Result := allDiapositives;
end;

function TDiaporama.GetAllDiapositiveTypes: TEnumerable<TDiapositiveType>;
var
  aDiapositive: TDiapositive;
  aDiapositiveType: TDiapositiveType;
  aDiaporama: TDiaporama;
  diapositiveTypeList: TEnumerable<TDiapositiveType>;
  allDiapositiveTypes: TObjectList<TDiapositiveType>;
begin
  allDiapositiveTypes := TObjectList<TDiapositiveType>.Create(
    TComparer<TDiapositiveType>.Default, False);
  for aDiapositive in FDiapositives do
  begin
    aDiapositiveType := aDiapositive.DiapositiveType;
    if Assigned(aDiapositiveType) then
      if allDiapositiveTypes.IndexOf(aDiapositiveType)=-1 then
        allDiapositiveTypes.Add(aDiapositiveType);
  end;
  for aDiaporama in FDiaporamas do
  begin
    diapositiveTypeList := aDiaporama.GetAllDiapositiveTypes;
    allDiapositiveTypes.AddRange(diapositiveTypeList);
    diapositiveTypeList.Free;
  end;
  Result := allDiapositiveTypes;
end;

{$ENDREGION 'TDiaporama'}

initialization
  Randomize;

end.
