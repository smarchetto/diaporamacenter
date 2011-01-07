unit DiaporamaSettingFrame;

interface

uses
  Classes, Controls, Forms, StdCtrls, ComCtrls, ActnList,
  DiaporamaCenterAgent, DiaporamaCenterSettings, Dialogs, ExtCtrls;

type
  TFrameDiaporamaSettings = class(TFrame)
    PageControl: TPageControl;
    tsPaths: TTabSheet;
    tsDownload: TTabSheet;
    lblConnection: TLabel;
    edLoginURL: TEdit;
    lblLogin: TLabel;
    edLogin: TEdit;
    lblPassword: TLabel;
    edPassword: TEdit;
    lblDiaporamaList: TLabel;
    edDiaporamaListUrl: TEdit;
    btnDownloadList: TButton;
    lblDiaporama: TLabel;
    edDiaporamaURL: TEdit;
    lblRepositoryPath: TLabel;
    edRepositoryPath: TEdit;
    btnOpenRepositoryPath: TButton;
    btnSaveSettings: TButton;
    btnApplySettings: TButton;
    lblDevicePath: TLabel;
    edDevicePath: TEdit;
    btnOpenDevicePath: TButton;
    lblTemplatePath: TLabel;
    edTemplatePath: TEdit;
    btnOpenTemplatePath: TButton;
    lblDiaporamaListFilePath: TLabel;
    edDiaporamaListFilePath: TEdit;
    btnOpenDiaporamaListFilePath: TButton;
    lblDiapositiveTypeFilePath: TLabel;
    edDiapositiveTypeFilePath: TEdit;
    btnOpenDiapositiveTypeFilePath: TButton;
    lblPaths: TLabel;
    lblFiles: TLabel;
    ActionList: TActionList;
    actApplySettings: TAction;
    actSaveSettings: TAction;
    actDownloadDiaporamaList: TAction;
    lblAuthentificationHeader: TLabel;
    lblDiaporamaHeader: TLabel;
    OpenFileDialog: TOpenDialog;
    pnlButton: TPanel;

    procedure actDownloadDiaporamaListExecute(Sender: TObject);
    procedure actApplySettingsExecute(Sender: TObject);
    procedure actApplySettingsUpdate(Sender: TObject);
    procedure actSaveSettingsExecute(Sender: TObject);
    procedure actSaveSettingsUpdate(Sender: TObject);
    procedure UpdateFromGUI(Sender: TObject);
    procedure btnOpenDiaporamaListFilePathClick(Sender: TObject);
    procedure btnOpenDiapositiveTypeFilePathClick(Sender: TObject);
    procedure btnOpenRepositoryPathClick(Sender: TObject);
    procedure btnOpenDevicePathClick(Sender: TObject);
    procedure btnOpenTemplatePathClick(Sender: TObject);
  private
    FDiaporamaCenterAgent: TDiaporamaCenterAgent;
    FEditedSettings: TDiaporamaCenterSettings;
    FSavedSettings: TDiaporamaCenterSettings;
  public
    constructor Create(aOwner: TComponent;
      const diaporamaCenter: TDiaporamaCenterAgent); reintroduce;
    destructor Destroy; override;

    procedure RefreshGUI;
  end;

implementation

uses
  Diaporama, ScheduleAction, DiaporamaUtils, DiaporamaDownloader;

{$R *.dfm}

constructor TFrameDiaporamaSettings.Create(aOwner: TComponent;
  const diaporamaCenter: TDiaporamaCenterAgent);
begin
  inherited Create(aOwner);
  FDiaporamaCenterAgent := diaporamaCenter;
  FSavedSettings := FDiaporamaCenterAgent.Settings.Copy;
  RefreshGUI;
  FEditedSettings := FDiaporamaCenterAgent.Settings.Copy;
  FEditedSettings.Fix;
end;

destructor TFrameDiaporamaSettings.Destroy;
begin
  FEditedSettings.Free;
  FSavedSettings.Free;
  inherited;
end;

procedure TFrameDiaporamaSettings.RefreshGUI;
begin
  // Paths
  with FDiaporamaCenterAgent.Settings do
  begin
    edRepositoryPath.Text := RepositoryPath;
    edTemplatePath.Text := TemplatePath;
    edDevicePath.Text := DevicePath;
    edDiapositiveTypeFilePath.Text := TypeFilePath;
    edDiaporamaListFilePath.Text := DiaporamaListFilePath;
  end;
  // Download
  with FDiaporamaCenterAgent.Settings.HttpSettings do
  begin
    edLoginURL.Text := AuthentificationUrl;
    edLogin.Text := Login;
    edPassword.Text := Password;
    edDiaporamaListURL.Text := DiaporamaListUrl;
    edDiaporamaURL.Text := DiaporamaUrl;
  end;
end;

procedure TFrameDiaporamaSettings.UpdateFromGUI(Sender: TObject);
begin
  if not Assigned(FEditedSettings) then
    Exit;

  with FEditedSettings do
  begin
    RepositoryPath := edRepositoryPath.Text;
    TemplatePath := edTemplatePath.Text;
    DevicePath := edDevicePath.Text;
    TypeFilePath := edDiapositiveTypeFilePath.Text;
    DiaporamaListFilePath := edDiaporamaListFilePath.Text;

    HttpSettings.AuthentificationUrl := edLoginUrl.Text;
    HttpSettings.DiaporamaUrl := edDiaporamaUrl.Text;
    HttpSettings.DiaporamaListUrl := edDiaporamaListURL.Text;
    HttpSettings.Login := edLogin.Text;
    HttpSettings.Password := edPassword.Text;
  end;
end;

procedure TFrameDiaporamaSettings.btnOpenDiaporamaListFilePathClick(
  Sender: TObject);
begin
  OpenFileDialog.InitialDir := FEditedSettings.RepositoryPath;
  if OpenFileDialog.Execute then
    edDiaporamaListFilePath.Text := OpenFileDialog.FileName;
end;

procedure TFrameDiaporamaSettings.btnOpenDiapositiveTypeFilePathClick(
  Sender: TObject);
begin
  OpenFileDialog.InitialDir := FEditedSettings.TemplatePath;
  if OpenFileDialog.Execute then
    edDiapositiveTypeFilePath.Text := OpenFileDialog.FileName;
end;

procedure TFrameDiaporamaSettings.btnOpenDevicePathClick(Sender: TObject);
var
  aPath: string;
begin
  aPath := OpenFolderDialog;
  if aPath<>'' then
    edDevicePath.Text := aPath;
end;

procedure TFrameDiaporamaSettings.btnOpenRepositoryPathClick(Sender: TObject);
var
  aPath: string;
begin
  aPath := OpenFolderDialog;
  if aPath<>'' then
    edRepositoryPath.Text := aPath;
end;

procedure TFrameDiaporamaSettings.btnOpenTemplatePathClick(Sender: TObject);
var
  aPath: string;
begin
  aPath := OpenFolderDialog;
  if aPath<>'' then
    edTemplatePath.Text := aPath;
end;

procedure TFrameDiaporamaSettings.actDownloadDiaporamaListExecute(Sender: TObject);
begin
  FDiaporamaCenterAgent.Repository.LoadDiaporamaList;
end;

procedure TFrameDiaporamaSettings.actSaveSettingsExecute(Sender: TObject);
begin
  FSavedSettings.Assign(FEditedSettings);
  FSavedSettings.SaveSettings;
end;

procedure TFrameDiaporamaSettings.actSaveSettingsUpdate(Sender: TObject);
begin
  actSaveSettings.Enabled := not
    FSavedSettings.Equals(FEditedSettings);
end;

procedure TFrameDiaporamaSettings.actApplySettingsUpdate(Sender: TObject);
begin
  actApplySettings.Enabled := not
    FEditedSettings.Equals(FDiaporamaCenterAgent.Settings);
end;

procedure TFrameDiaporamaSettings.actApplySettingsExecute(Sender: TObject);
begin
  FDiaporamaCenterAgent.Settings.Assign(FEditedSettings);
end;

end.
