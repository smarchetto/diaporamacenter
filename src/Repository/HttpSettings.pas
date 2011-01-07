unit HttpSettings;

interface

uses
  MSXML2_TLB;

type
  THttpSettings = class
  private
    // URL
    FAuthentificationUrl: string;
    FDiaporamaListUrl: string;
    FDiaporamaUrl: string;
    FMediaUrl: string;

    // Login, password
    FLogin: string;
    FPassword: string;

    // Timeout (sec)
    FTimeOut: LongInt;

  public
    constructor Create;

    procedure Assign(const httpSettings: THttpSettings);
    function Equals(anObject: TObject): Boolean; override;

    function LoadFromXML(const parentNode: IXMLDomNode): Boolean;
    function SaveToXML(const xmlDocument: IXMLDomDocument;
      const parentNode: IXmlDomNode): Boolean;

    property AuthentificationUrl: string read FAuthentificationUrl
      write FAuthentificationUrl;
    property DiaporamaListUrl: string read FDiaporamaListUrl
      write FDiaporamaListUrl;
    property DiaporamaUrl: string read FDiaporamaUrl
      write FDiaporamaUrl;
    property MediaUrl: string read FMediaUrl write FMediaUrl;
    property Login: string read FLogin write FLogin;
    property Password: string read FPassword write FPassword;
    property TimeOut: LongInt read FTimeOut;
  end;

implementation

uses
  SysUtils,
  DiaporamaUtils;

const
  cstNodeHttpSettings = 'HttpSettings';
  cstNodeAuthentificationURL = 'AuthentificationURL';
  cstNodeDiaporamaListURL = 'DiaporamaListURL';
  cstNodeDiaporamaURL = 'DiaporamaURL';
  cstNodeMediaURL = 'MediaURL';
  cstNodeLogin = 'Login';
  cstNodePassword = 'Password';

constructor THttpSettings.Create;
begin
  FAuthentificationUrl := '';
  FDiaporamaListUrl := '';
  FDiaporamaUrl := '';
  FMediaUrl := '';
  FLogin := '';
  FPassword := '';
  FTimeOut := 3600*24;
end;

procedure THttpSettings.Assign(const httpSettings: THttpSettings);
begin
  if Assigned(httpSettings) then
  begin
    FAuthentificationUrl := httpSettings.AuthentificationUrl;
    FDiaporamaListUrl := httpSettings.DiaporamaListUrl;
    FDiaporamaUrl := httpSettings.DiaporamaUrl;
    FMediaUrl := httpSettings.MediaUrl;
    FLogin := httpSettings.Login;
    FPassword := httpSettings.Password;
    FTimeOut := httpSettings.TimeOut;
  end;
end;

function THttpSettings.Equals(anObject: TObject): Boolean;
var
  httpSettings: THttpSettings;
begin
  if Assigned(anObject) and (anObject is THttpSettings) then
  begin
    httpSettings := THttpSettings(anObject);
    Result := SameStr(FAuthentificationUrl, httpSettings.AuthentificationUrl) and
      SameStr(FDiaporamaListUrl, httpSettings.DiaporamaListUrl) and
      SameStr(FDiaporamaUrl, httpSettings.DiaporamaUrl) and
      SameStr(FMediaUrl, httpSettings.MediaUrl) and
      SameStr(FLogin, httpSettings.Login) and
      SameStr(FPassword, httpSettings.Password) and
      (FTimeOut=httpSettings.TimeOut);
  end else
    Result := false;
end;

function THttpSettings.LoadFromXML(const parentNode: IXMLDomNode): Boolean;
var
  aNode: IXMLDomNode;
begin
  Result := False;

  if not Assigned(parentNode) then
    Exit;

  aNode := parentNode.selectSingleNode(cstNodeHttpSettings);
  if Assigned(aNode) then
  begin
    // URLs
    FAuthentificationUrl := GetNodeValue(parentNode,
      cstNodeHttpSettings + '/' + cstNodeAuthentificationUrl);
    FDiaporamaListUrl := GetNodeValue(parentNode,
      cstNodeHttpSettings + '/' + cstNodeDiaporamaListUrl);
    FDiaporamaUrl := GetNodeValue(parentNode,
      cstNodeHttpSettings + '/' + cstNodeDiaporamaUrl);
    FMediaUrl := GetNodeValue(parentNode,
      cstNodeHttpSettings + '/' + cstNodeMediaUrl);

    // Login, password
    FLogin := GetNodeValue(parentNode,
      cstNodeHttpSettings + '/' + cstNodeLogin);
    FPassword := GetNodeValue(parentNode,
      cstNodeHttpSettings + '/' + cstNodePassword);

    Result := True;
  end;
end;

function THttpSettings.SaveToXML(const xmlDocument: IXMLDomDocument;
  const parentNode: IXmlDomNode): Boolean;
var
  aNode: IXmlDomNode;
begin
  Result := False;

  if not Assigned(xmlDocument) and not Assigned(parentNode) then
    Exit;

  aNode := xmlDocument.CreateElement(cstNodeHttpSettings);
  parentNode.appendChild(aNode);

  SetNodeValue(xmlDocument, aNode, cstNodeAuthentificationUrl,
    FAuthentificationUrl);

  SetNodeValue(xmlDocument, aNode, cstNodeDiaporamaListUrl, FDiaporamaListUrl);

  SetNodeValue(xmlDocument, aNode, cstNodeDiaporamaUrl, FDiaporamaUrl);

  SetNodeValue(xmlDocument, aNode, cstNodeMediaUrl, FMediaUrl);

  SetNodeValue(xmlDocument, aNode, cstNodeLogin, FLogin);

  // TODO : crypt password
  SetNodeValue(xmlDocument, aNode, cstNodePassword, FPassword);

  Result := True;
end;

end.
