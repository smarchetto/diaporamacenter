unit DiaporamaRepository;

interface

uses
  Generics.Defaults, Generics.Collections, MSXML2_TLB,
  Diaporama, DiaporamaDownloader, HttpDownloader, DiaporamaResource, Diapositive,
  DiaporamaCenterSettings;

type
  // Class with several roles : container of all diaporamas and downloaders,
  // it manages the storage and downloading of diaporamas
  TDiaporamaRepository = class
  private
    // Téléchargeur
    FDiaporamaDownloaders: TObjectList<TDiaporamaDownloader>;
    // Diaporamas
    FDiaporamas: TDiaporamaList;
    // Configuration
    FDiaporamaCenterAgent: TObject;
    FDiaporamaCenterSettings: TDiaporamaCenterSettings;

    function GetRepositoryPath: string;
    function GetDiaporamaListFilePath: string;

    function GetDiaporamas: TEnumerable<TDiaporama>;
    function GetDiaporama(const index: integer): TDiaporama;
    function GetDiaporamaCount: integer;

    function GetDiaporamaDownloader(
      const diaporamaID: string): TDiaporamaDownloader; overload;
    function GetDiaporamaDownloaders: TEnumerable<TDiaporamaDownloader>;
    function GetDiaporamaDownloaderCount: Integer;
  public
    constructor Create(const aDiaporamaCenterAgent: TObject);
    destructor Destroy; override;

    // Load and download of diaporama list
    function LoadDiaporamaList: TDiaporamaList;
    function DownloadDiaporamaList: Boolean;

    // Create diaporama downloaders
    procedure CreateDiaporamaDownloaders;

    // Returns file paths
    function GetDiapositiveFilePath(const aDiapositive: TDiapositive): string;
    function GetResourceFilePath(const aResource: TDiaporamaResource): string;

    function GetDiaporamaPath(const diaporamaID: string): string;
    function LoadDiaporama(const diaporamaID: string): TDiaporama;

    function GetDiaporamaByName(const aName: string): TDiaporama;
    function GetDiaporamaByID(const anID: string): TDiaporama;
    property Diaporamas: TEnumerable<TDiaporama> read GetDiaporamas;
    property Diaporama[const index: integer]: TDiaporama read GetDiaporama;
    property DiaporamaCount: integer read GetDiaporamaCount;

    property DiaporamaDownloaders: TEnumerable<TDiaporamaDownloader>
      read GetDiaporamaDownloaders;
    property DiaporamaDownloaderCount: integer read GetDiaporamaDownloaderCount;
  end;

implementation

uses
  SysUtils,
  DiapositiveType, Downloader, DiaporamaCenterAgent;

constructor TDiaporamaRepository.Create(
  const aDiaporamaCenterAgent: TObject);
begin
  FDiaporamaCenterAgent := aDiaporamaCenterAgent;
  FDiaporamaCenterSettings :=
    TDiaporamaCenterAgent(FDiaporamaCenterAgent).Settings;

  FDiaporamas := TDiaporamaList.Create;

  FDiaporamaDownloaders := TObjectList<TDiaporamaDownloader>.Create;
end;

destructor TDiaporamaRepository.Destroy;
begin
  FDiaporamas.Free;
  FDiaporamaDownloaders.Free;
  inherited;
end;

procedure TDiaporamaRepository.CreateDiaporamaDownloaders;
var
  aDiaporama: TDiaporama;
begin
  FDiaporamaDownloaders.Clear;

  for aDiaporama in FDiaporamas do
    GetDiaporamaDownloader(aDiaporama.ID);
end;

function TDiaporamaRepository.GetDiaporama(const index: integer): TDiaporama;
begin
  Result := FDiaporamas[index];
end;

function TDiaporamaRepository.GetDiaporamas: TEnumerable<TDiaporama>;
begin
  Result := FDiaporamas;
end;

function TDiaporamaRepository.GetDiaporamaCount: integer;
begin
  Result := FDiaporamas.Count;
end;

function TDiaporamaRepository.GetDiaporamaByName(const aName: string): TDiaporama;
begin
  Result := FDiaporamas.GetDiaporamaByName(aName);
end;

function TDiaporamaRepository.GetDiaporamaByID(const anID: string): TDiaporama;
begin
  Result := FDiaporamas.GetDiaporamaByID(anID);
end;

function TDiaporamaRepository.GetDiaporamaDownloaders: TEnumerable<TDiaporamaDownloader>;
begin
  Result := FDiaporamaDownloaders;
end;

function TDiaporamaRepository.GetDiaporamaDownloaderCount: integer;
begin
  Result := FDiaporamaDownloaders.Count;
end;

function TDiaporamaRepository.GetDiaporamaDownloader(
  const diaporamaID: string): TDiaporamaDownloader;
var
  aDiaporama: TDiaporama;
  aDiaporamaDownloader: TDiaporamaDownloader;
begin
  Result := nil;
  aDiaporama := FDiaporamas.GetDiaporamaByID(diaporamaID);
  if Assigned(aDiaporama) then
  begin
    // Find downloader for that diaporama
    for aDiaporamaDownloader in FDiaporamaDownloaders do
    begin
      if aDiaporamaDownloader.Diaporama.ID=diaporamaID then
      begin
        Result := aDiaporamaDownloader;
        Exit;
      end;
    end;
    // Not found, we create a new one
    Result := TDiaporamaDownloader.Create(Self, aDiaporama,
      FDiaporamaCenterAgent);
    FDiaporamaDownloaders.Add(Result);
  end;
end;

function TDiaporamaRepository.GetRepositoryPath: string;
begin
  Result := ExpandFileName(FDiaporamaCenterSettings.RepositoryPath);

  if (Result<>'') and not DirectoryExists(Result) then
    ForceDirectories(Result);
end;

function TDiaporamaRepository.GetDiaporamaListFilePath: string;
var
  diaporamaListDir: string;
begin
  Result := ExpandFileName(FDiaporamaCenterSettings.DiaporamaListFilePath);
  diaporamaListDir := ExtractFileDir(Result);
  if not DirectoryExists(diaporamaListDir) then
    ForceDirectories(diaporamaListDir);
end;

function TDiaporamaRepository.GetDiapositiveFilePath(
  const aDiapositive: TDiapositive): string;
var
  diapositivePath: string;
begin
  if Assigned(aDiapositive) then
  begin
    diapositivePath := GetRepositoryPath + aDiapositive.DiapositiveType.Name;
    if not DirectoryExists(diapositivePath) then
      ForceDirectories(diapositivePath);

    Result := IncludeTrailingBackSlash(diapositivePath) +
      aDiapositive.ID + '.html';
  end else
    Result := '';
end;

function TDiaporamaRepository.GetResourceFilePath(
  const aResource: TDiaporamaResource): string;
var
  resourcePath: string;
begin
  resourcePath := GetRepositoryPath + aResource.LocalDir;

  if not DirectoryExists(resourcePath) then
    ForceDirectories(resourcePath);

  Result := IncludeTrailingBackSlash(resourcePath) + aResource.ID;
end;

function TDiaporamaRepository.GetDiaporamaPath(const diaporamaID: string): string;
begin
  Result := GetRepositoryPath + diaporamaID + '.xml';
end;

function TDiaporamaRepository.LoadDiaporama(
  const diaporamaID: string): TDiaporama;
var
  aDiaporamaDownloader: TDiaporamaDownloader;
  aDiaporama: TDiaporama;
begin
  Result := nil;

  if diaporamaID<>'' then
  begin
    aDiaporamaDownloader := GetDiaporamaDownloader(diaporamaID);

    if Assigned(aDiaporamaDownloader) then
    begin
      if aDiaporamaDownloader.LoadDiaporama then
      begin
        aDiaporama := aDiaporamaDownloader.Diaporama;
        if Assigned(aDiaporama) then
        begin
          if FDiaporamas.GetDiaporamaIndex(aDiaporama.ID)=-1 then
            FDiaporamas.Add(aDiaporama);
          Result := aDiaporama;
        end;
      end;
    end;
  end;
end;

function TDiaporamaRepository.DownloadDiaporamaList: Boolean;
var
  aDownloader: TDownloader;
begin
  Result := False;
  aDownloader := nil;
  try
    aDownloader := CreateDownloader(dtHttp, FDiaporamaCenterSettings);

    if Assigned(aDownloader) then
      Result := aDownloader.DownloadDiaporamaList(GetDiaporamaListFilePath);
  finally
    aDownloader.Free;
  end;
end;

function TDiaporamaRepository.LoadDiaporamaList: TDiaporamaList;
var
  diaporamaListFilePath: string;
begin
  Result := nil;

  FDiaporamaDownloaders.Clear;

  diaporamaListFilePath := GetDiaporamaListFilePath;

  if not FileExists(diaporamaListFilePath) then
  begin
    if not DownloadDiaporamaList then
      Exit;
  end;

  if FDiaporamas.LoadFromXML(diaporamaListFilePath) then
    Result := FDiaporamas;

  CreateDiaporamaDownloaders;
end;


end.
