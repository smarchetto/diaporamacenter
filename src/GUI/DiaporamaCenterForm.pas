unit DiaporamaCenterForm;

interface

uses
  Windows, Classes, Graphics, Controls, Forms,
  ImgList, ExtCtrls, ToolWin, XPMan, StdCtrls, Buttons,
  DiaporamaCenterAgent,
  DiaporamaDeviceFrame, DiaporamaSettingFrame, DiaporamaPlayerFrame,
  DiaporamaSchedulerFrame;

type
  TfrmDiaporamaCenter = class(TForm)
    MainPanel: TPanel;
    XPManifest: TXPManifest;
    TopPanel: TPanel;
    sbDevices: TSpeedButton;
    sbDiaporamas: TSpeedButton;
    sbSchedule: TSpeedButton;
    sbSettings: TSpeedButton;
    procedure FormCreate(Sender: TObject);
    procedure sbDiaporamasClick(Sender: TObject);
    procedure sbScheduleClick(Sender: TObject);
    procedure sbSettingsClick(Sender: TObject);
    procedure sbDevicesClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FDiaporamaCenterAgent: TDiaporamaCenterAgent;
    FDiaporamaDeviceFrame: TFrameDiaporamaDevice;
    FDiaporamaPlayerFrame: TFrameDiaporamaPlayer;
    FDiaporamaSchedulerFrame: TFrameDiaporamaScheduler;
    FDiaporamaSettingFrame: TFrameDiaporamaSettings;
  public
  end;

var
  frmDiaporamaCenter: TfrmDiaporamaCenter;

implementation

uses
  Sysutils, Dialogs,
  ComSettingForm, ControlCommandSettingForm;

{$R *.dfm}

procedure TfrmDiaporamaCenter.FormCreate(Sender: TObject);
begin
  FDiaporamaCenterAgent := CreateDiaporamaCenterAgent;

  if not Assigned(FDiaporamaCenterAgent) then
    Halt(1);

  FDiaporamaDeviceFrame := nil;
  FDiaporamaPlayerFrame := nil;
  FDiaporamaSettingFrame := nil;

  sbDevicesClick(nil);
end;

procedure TfrmDiaporamaCenter.FormDestroy(Sender: TObject);
begin
  frmControlCommandSetting.Free;
  frmComSetting.Free;
  FDiaporamaCenterAgent.Free;
end;

procedure TfrmDiaporamaCenter.sbDevicesClick(Sender: TObject);
begin
  if not Assigned(FDiaporamaDeviceFrame) then
  begin
    FDiaporamaDeviceFrame := TFrameDiaporamaDevice.Create(MainPanel,
      FDiaporamaCenterAgent);
    FDiaporamaDeviceFrame.Parent := MainPanel;
    FDiaporamaDeviceFrame.Align := AlClient;
  end;

  FDiaporamaDeviceFrame.Visible := True;
  FDiaporamaDeviceFrame.BringToFront;
end;

procedure TfrmDiaporamaCenter.sbDiaporamasClick(Sender: TObject);
begin
  if not Assigned(FDiaporamaPlayerFrame) then
  begin
    FDiaporamaPlayerFrame := TFrameDiaporamaPlayer.Create(MainPanel,
      FDiaporamaCenterAgent);
    FDiaporamaPlayerFrame.Parent := MainPanel;
    FDiaporamaPlayerFrame.Align := AlClient;
  end;

  FDiaporamaPlayerFrame.Visible := True;
  FDiaporamaPlayerFrame.BringToFront;
end;

procedure TfrmDiaporamaCenter.sbScheduleClick(Sender: TObject);
begin
  if not Assigned(FDiaporamaSchedulerFrame) then
  begin
    FDiaporamaSchedulerFrame := TFrameDiaporamaScheduler.Create(MainPanel,
      FDiaporamaCenterAgent);
    FDiaporamaSchedulerFrame.Parent := MainPanel;
    FDiaporamaSchedulerFrame.Align := AlClient;
  end;

  FDiaporamaSchedulerFrame.Visible := True;
  FDiaporamaSchedulerFrame.BringToFront;
end;

procedure TfrmDiaporamaCenter.sbSettingsClick(Sender: TObject);
begin
  if not Assigned(FDiaporamaSettingFrame) then
  begin
    FDiaporamaSettingFrame := TFrameDiaporamaSettings.Create(MainPanel,
      FDiaporamaCenterAgent);
    FDiaporamaSettingFrame.Parent := MainPanel;
    FDiaporamaSettingFrame.Align := AlClient;
  end;

  FDiaporamaSettingFrame.Visible := True;
  FDiaporamaSettingFrame.BringToFront;
end;


end.
