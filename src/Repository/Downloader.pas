unit Downloader;

interface

uses
  DiaporamaCenterSettings, DiaporamaResource;

type
  TDownloaderType = (dtHTTP, dtFTP, dtWebService);

  // Generic diaporama and media file downloader
  TDownloader = class
  public
    function DownloadFile(const anUrl: string;
      const localFilePath: string): Boolean; virtual; abstract;

    function DownloadDiaporama(const diaporamaName: string;
      const localFilePath: string): Boolean; virtual; abstract;

    function DownloadResource(const aMedia: TDiaporamaResource;
      const localFilePath: string): Boolean; virtual; abstract;

    function DownloadDiaporamaList(
      const localFilePath: string): Boolean; virtual; abstract;
  end;

function CreateDownloader(const downloaderType: TDownloaderType;
  const diaporamaCenterSettings: TDiaporamaCenterSettings): TDownloader;

implementation

uses
  SysUtils,
  HttpDownloader;

function CreateDownloader(const downloaderType: TDownloaderType;
  const diaporamaCenterSettings: TDiaporamaCenterSettings): TDownloader;
begin
  if Assigned(diaporamaCenterSettings) then
  begin
    case downloaderType of
      dtHTTP : Result :=
        THttpDownloader.Create(diaporamaCenterSettings.HttpSettings);
    else
      raise Exception.Create(
        'HTTP download is the only protocol supported in this version');
    end;
  end else
    Result := nil;
end;

end.
