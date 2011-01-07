unit HttpDownloader;

interface

uses
  Classes, 
  IdHttp, IdCookieManager,
  DiaporamaResource, Downloader, HttpSettings;

type
  // Diaporama and media file HTTP downloader
  THttpDownloader = class(TDownloader)
  private
    FIdHttp: TIdHttp;
    FIdCookieManager: TIdCookieManager;

    // HTTP settings
    FHttpSettings: THttpSettings;

    FLogged: Boolean;

    // Login time
    FLoginTime: TDateTime;

    procedure Login;

    function GetLoginTimeSeconds: Integer;
  public
    constructor Create(const aHttpSettings: THttpSettings);
    destructor Destroy; override;

    function DownloadFile(const anUrl: string;
      const localFilePath: string): Boolean; override;

    function DownloadDiaporama(
      const diaporamaName, localFilePath: string): Boolean; override;
    function DownloadResource(const aResource: TDiaporamaResource;
      const localFilePath: string): Boolean; override;
    function DownloadDiaporamaList(const localFilePath: string): Boolean; override;

    property Logged: Boolean read FLogged;
    property HttpSettings: THttpSettings read FHttpSettings;
  end;

implementation

uses
  SysUtils,
  Logs;

const
  cstHTTPCodeMsg = 'Returned HTTP code: %d';
  cstHTTPResponseMsg = 'Server response: %s';
  cstHTTPLoginErrorMsg = 'Error while logging at URL %s : %s';

constructor THttpDownloader.Create(const aHttpSettings: THttpSettings);
begin
  FIdHttp := TIdHttp.Create(nil);
  FIdCookieManager := TIdCookieManager.Create;
  FIdHttp.CookieManager := FIdCookieManager;
  FIdHttp.AllowCookies := True;
  FHttpSettings := aHttpSettings;
  FLogged := False;
end;

destructor THttpDownloader.Destroy;
begin
  // TODO : disconnect HTTP
  FIdHttp.Free;
  FIdCookieManager.Free;
  inherited;
end;

procedure THttpDownloader.Login;
var
  fullUrl, content: string;
begin
  FLoginTime := -1;
  FLogged := False;

  if (FHttpSettings.AuthentificationUrl<>'') then
  begin
    // Full URL login
    fullUrl := Format(FHttpSettings.AuthentificationUrl,
      [FHttpSettings.Login, FHttpSettings.Password]);

    try
      content := FIdHttp.Get(fullUrl);

      if (FIdHttp.ResponseCode=200) then
      begin
        if content='1' then
          FLogged := True
        else
          raise Exception.Create(Format(cstHTTPResponseMsg,
            [content]));
      end else
        raise Exception.Create(Format(cstHTTPCodeMsg,
          [FIdHttp.ResponseCode]));
    except
      on e: Exception do
      begin
        LogEvent(Self.ClassName, ltError,
          Format(cstHTTPLoginErrorMsg, [fullURL, e.Message]));
      end;
    end;

    if FLogged then
      FLoginTime := Now;
  end;
end;

function THttpDownloader.GetLoginTimeSeconds: Integer;
var
  H, M, S, MS: word;
begin
  DecodeTime(FLoginTime, H, M, S, MS);
  result := H * 3600 + M * 60 + S;
end;

function THttpDownloader.DownloadFile(const anUrl: string;
  const localFilePath: string): Boolean;
var
  stream: TMemoryStream;
begin
  Result := False;

  // Needs to log ?
  if (not FLogged) or (Now>GetLoginTimeSeconds+FHttpSettings.TimeOut) then
    Login;

  if FLogged then
  begin
    stream := nil;
    try
      // TODO : lock ?
      stream := TMemoryStream.Create();

      FIdHttp.Get(anUrl, stream);

      // TODO : improve response check and log errors
      Result := (FIdHttp.ResponseCode = 200);

      if Result then
        stream.SaveToFile(localFilePath);
    finally
      stream.Free;
    end;
  end;

end;

function THttpDownloader.DownloadDiaporamaList(
  const localFilePath: string): Boolean;
var
  url: string;
begin
  url := Format(FHttpSettings.DiaporamaListUrl, []);
  Result := DownloadFile(url, localFilePath);
end;

function THttpDownloader.DownloadDiaporama(const diaporamaName,
  localFilePath: string): Boolean;
var
  url: string;
begin
  url := Format(FHttpSettings.DiaporamaUrl, [diaporamaName]);
  Result := DownloadFile(url, localFilePath);
end;

function THttpDownloader.DownloadResource(const aResource: TDiaporamaResource;
  const localFilePath: string): Boolean;
var
  URL, fullURL: string;
begin
  Result := False;

  if Assigned(aResource) and (aResource.ID<>'') then
  begin
    // URL for that Resource ?
    if aResource.URL<>'' then
      URL := aResource.URL
    else
      // Use default Resource root URL otherwise
      URL := FHttpSettings.MediaURL;

    // Full url with ID
    fullURL := Format(URL, [aResource.ID]);

    if fullURL<>''  then
      Result := DownloadFile(fullURL, localFilePath);
  end;
end;


end.
