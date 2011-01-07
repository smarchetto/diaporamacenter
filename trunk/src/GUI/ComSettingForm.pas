unit ComSettingForm;

//{$I CPort.inc}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Buttons,
  ComSettings, CPort, CPortCtl, Spin;

type
  // TComPort setup dialog
  TComSettingForm = class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    cbBaudRate: TComComboBox;
    cbPort: TComComboBox;
    cbDataBits: TComComboBox;
    cbFlowControl: TComComboBox;
    cbParity: TComComboBox;
    cbStopBits: TComComboBox;
    lblBaudRate: TLabel;
    lblPort: TLabel;
    lblDataBits: TLabel;
    lblFlowControl: TLabel;
    lblParity: TLabel;
    lblStopBits: TLabel;
    lblTimeOutConstant: TLabel;
    SeTimeOutConstant: TSpinEdit;
    lblTimeOutPerChar: TLabel;
    seTimeOutPerChar: TSpinEdit;
    procedure FormCreate(Sender: TObject);
  private
  public
  end;

procedure EditComSettings(const comSettings: TComSettings);

var
  frmComSetting: TComSettingForm;

implementation

//uses gnugettext;

{$R *.DFM}

procedure EditComSettings(const comSettings: TComSettings);
begin
  if not Assigned(frmComSetting) then
    frmComSetting := TComSettingForm.Create(nil);

  with frmComSetting do
  begin
    cbPort.ComPort := comSettings;
    cbBaudRate.ComPort := comSettings;
    cbDataBits.ComPort := comSettings;
    cbParity.ComPort := comSettings;
    cbStopBits.ComPort := comSettings;
    cbFlowControl.ComPort := comSettings;
    cbPort.UpdateSettings;
    cbBaudRate.UpdateSettings;
    cbDataBits.UpdateSettings;
    cbParity.UpdateSettings;
    cbStopBits.UpdateSettings;
    cbFlowControl.UpdateSettings;
    seTimeOutConstant.Value := comSettings.TimeOutConstant;
    seTimeOutPerChar.Value := comSettings.TimeOutPerChar;
    if ShowModal = mrOK then
    begin
      //comSettings.BeginUpdate;
      cbPort.ApplySettings;
      cbBaudRate.ApplySettings;
      cbDataBits.ApplySettings;
      cbParity.ApplySettings;
      cbStopBits.ApplySettings;
      cbFlowControl.ApplySettings;
      comSettings.TimeOutConstant := seTimeOutConstant.Value;
      comSettings.TimeOutPerChar := seTimeOutPerChar.Value;
      //comSettings.EndUpdate;
    end;
  end;
end;

procedure TComSettingForm.FormCreate(Sender: TObject);
begin
  (*TP_Ignore(self, 'cbComPort');
  TP_Ignore(self, 'cbBaudRate');
  TP_Ignore(self, 'cbDataBits');
  TP_Ignore(self, 'cbParity');
  TP_Ignore(self, 'cbStopBits');
  TP_Ignore(self, 'cbFlowControl');
  TranslateProperties(self, 'cport');*)
end;

initialization
  frmComSetting := nil;

end.
