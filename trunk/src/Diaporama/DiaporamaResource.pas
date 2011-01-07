unit DiaporamaResource;

interface

uses
  MSXML2_TLB;

type
  TDownloadStatus = (dsUnknown=-2, dsFailed=-1, dsQueued=0, dsSucceeded=1);

  // A resource can be an image, a video, whatever can be included in a diapositive
  // It can also be a stylesheet or an image in a diapositive template
  TDiaporamaResource = class
  protected
    // ID (used for file name)
    FID: string;
    // URL to download
    FURL: string;
    // Directory in local cache
    FLocalDir: string;
    // Download status
    FDownloadStatus: TDownloadStatus;
  public
    constructor Create(const anID: string; const anURL: string;
      const aLocalDir: string);

    function LoadFromXML(const aNode: IXmlDomNode): Boolean;

    property ID: string read FID;
    property URL: string read FURL;
    property LocalDir: string read FLocalDir;
    property DownloadStatus: TDownloadStatus read FDownloadStatus
      write FDownloadStatus;
  end;

implementation

uses
  DiaporamaUtils;

const
  // XML markups
  cstXMLAttrResourceId = 'id';
  cstXMLAttrResourceURL = 'src';

constructor TDiaporamaResource.Create(const anID: string;
  const anURL: string; const aLocalDir: string);
begin
  FID := anID;
  FURL := anURL;
  FLocalDir := aLocalDir;
  FDownloadStatus := dsUnknown;
end;

function TDiaporamaResource.LoadFromXML(const aNode: IXmlDomNode): Boolean;
var
  anURL: string;
begin
  Result := False;

  if Assigned(aNode) then
  begin
    FID := getAttributeValue(aNode, cstXMLAttrResourceId);

    // override by specific URL
    anURL := getAttributeValue(aNode, cstXMLAttrResourceURL);
    if anURL<>'' then
      FURL := anURL;

    Result := True;
  end;
end;


end.
