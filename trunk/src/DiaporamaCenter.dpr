program DiaporamaCenter;

uses
  Forms,
  DiaporamaCenterAgent in 'DiaporamaCenterAgent.pas',
  DiaporamaDeviceSettings in 'Devices\DiaporamaDeviceSettings.pas',
  DiaporamaDevice in 'Devices\DiaporamaDevice.pas',
  DiaporamaDeviceInfo in 'Devices\DiaporamaDeviceInfo.pas',
  SequenceItem in 'Diaporama\SequenceItem.pas',
  Diaporama in 'Diaporama\Diaporama.pas',
  DiaporamaEntity in 'Diaporama\DiaporamaEntity.pas',
  DiaporamaSequenceItem in 'Diaporama\DiaporamaSequenceItem.pas',
  Diapositive in 'Diaporama\Diapositive.pas',
  DiapositiveSequenceItem in 'Diaporama\DiapositiveSequenceItem.pas',
  DiapositiveType in 'Diaporama\DiapositiveType.pas',
  Sequence in 'Diaporama\Sequence.pas',
  DisplayMode in 'Devices\DisplayMode.pas',
  HttpDownloader in 'Repository\HttpDownloader.pas',
  DiaporamaDownloader in 'Repository\DiaporamaDownloader.pas',
  DiaporamaRepository in 'Repository\DiaporamaRepository.pas',
  Logs in 'Utils\Logs.pas',
  DiaporamaUtils in 'Utils\DiaporamaUtils.pas',
  DiaporamaForm in 'Player\DiaporamaForm.pas',
  DiaporamaPlayer in 'Player\DiaporamaPlayer.pas',
  WebDiapositiveFrame in 'Player\WebViewer\WebDiapositiveFrame.pas' {FrameWebDiapositive: TFrame},
  IntfDocHostUIHandler in 'Player\WebViewer\IntfDocHostUIHandler.pas',
  UContainer in 'Player\WebViewer\UContainer.pas',
  UNulContainer in 'Player\WebViewer\UNulContainer.pas',
  ThreadIntf in 'Player\ThreadIntf.pas',
  DiaporamaSettingFrame in 'GUI\DiaporamaSettingFrame.pas' {FrameDiaporamaSettings: TFrame},
  DiaporamaCenterForm in 'GUI\DiaporamaCenterForm.pas' {frmDiaporamaCenter},
  DiaporamaDeviceFrame in 'GUI\DiaporamaDeviceFrame.pas' {FrameDiaporamaDevice: TFrame},
  DiaporamaPlayerFrame in 'GUI\DiaporamaPlayerFrame.pas' {FrameDiaporamaPlayer: TFrame},
  ComSettingForm in 'GUI\ComSettingForm.pas' {ComSettingFrm},
  ControlCommandSettingForm in 'GUI\ControlCommandSettingForm.pas' {ControlCommandSettingForm},
  ComSettings in 'Devices\ComSettings.pas',
  DeviceControl in 'Devices\DeviceControl.pas',
  DeviceControlSettings in 'Devices\DeviceControlSettings.pas',
  DiaporamaCenterSettings in 'DiaporamaCenterSettings.pas',
  DiaporamaScheduler in 'Scheduler\DiaporamaScheduler.pas',
  ScheduleAction in 'Scheduler\ScheduleAction.pas',
  Downloader in 'Repository\Downloader.pas',
  HttpSettings in 'Repository\HttpSettings.pas',
  DiaporamaSchedulerFrame in 'GUI\DiaporamaSchedulerFrame.pas' {FrameDiaporamaScheduler: TFrame},
  GUIUtils in 'GUI\GUIUtils.pas',
  ScheduleActionList in 'Scheduler\ScheduleActionList.pas',
  DiaporamaResource in 'Diaporama\DiaporamaResource.pas';

{$R *.res}

//var
//  aDiaporamaCenterAgent: TDiaporamaCenterAgent;

begin
  Application.Initialize;
  Application.Title := 'DiaporamaCenter';
  Application.CreateForm(TfrmDiaporamaCenter, frmDiaporamaCenter);
  Application.Run;
end.
