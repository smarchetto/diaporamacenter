unit MediaFile;

interface

uses
  MSXML2_TLB,
  DiaporamaDependency, DiapositiveType;

type
  TMediaType = (mtImage, mtVideo);

  // A media can be an image, a video...whatever can be included in a diapositive
  TMediaFile = class(TDiaporamaDependency)
  private
    // Parent diapositive
    FDiapositive: TObject;
  public
    constructor Create(const anID: string; const anURL: string;
      const aDate: TDateTime; const aDiapositive: TObject);

    function LoadFromXML(const aNode: IXmlDomNode): Boolean;
  end;

const
  // XML markups
  cstMediaAttrId = 'id';
  cstMediaAttrURL = 'src';

implementation

uses
  Diapositive, DiaporamaUtils;

constructor TMediaFile.Create(const anID: string; const anURL: string;
  const aDate: TDateTime; const aDiapositive: TObject);
var
  aDiapositiveType: TDiapositiveType;
begin
  inherited Create(anID, anURL, aDate);

  FDiapositive := aDiapositive;
end;

function TMediaFile.LoadFromXML(const aNode: IXmlDomNode): Boolean;
var
  anURL: string;
begin
  Result := False;

  if Assigned(aNode) then
  begin
    FID := getAttributeValue(aNode, cstMediaAttrId);

    // override by specific URL
    anURL := getAttributeValue(aNode, cstMediaAttrURL);
    if anURL<>'' then
      FURL := anURL;

    Result := True;
  end;
end;


end.
