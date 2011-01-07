unit ControlCommandSettingForm;

interface

uses
  SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,
  DeviceControlSettings;

type
  TControlCommandSettingForm = class(TForm)
    lblPowerOn: TLabel;
    lblPowerOff: TLabel;
    edPowerOnCode: TEdit;
    edPowerOffCode: TEdit;
    lblPowerOnOKCode: TLabel;
    edResponsePowerOnOKCode: TEdit;
    lblPowerOffOKCode: TLabel;
    edResponsePowerOffOKCode: TEdit;
    lblPowerStatusCode: TLabel;
    edPowerStatusCode: TEdit;
    lblResponseOnCode: TLabel;
    edResponseStatusOnCode: TEdit;
    lblResponseOffCode: TLabel;
    edResponseStatusOffCode: TEdit;
    lblPowerOnOffCommands: TLabel;
    btnOK: TButton;
    btnCancel: TButton;
  private
  public
  end;

procedure EditControlCommands(
  const deviceControlSettings: TDeviceControlSettings);

var
  frmControlCommandSetting: TControlCommandSettingForm;

implementation

{$R *.dfm}

procedure EditControlCommands(
  const deviceControlSettings: TDeviceControlSettings);
begin
  if not Assigned(frmControlCommandSetting) then
    frmControlCommandSetting := TControlCommandSettingForm.Create(nil);

  with frmControlCommandSetting do
  begin
    edPowerOnCode.Text := deviceControlSettings.PowerOnCode;
    edResponsePowerOnOKCode.Text := deviceControlSettings.ResponsePowerOnOKCode;

    edPowerOffCode.Text := deviceControlSettings.PowerOffCode;
    edResponsePowerOffOKCode.Text := deviceControlSettings.ResponsePowerOffOKCode;

    edPowerStatusCode.Text := deviceControlSettings.PowerStatusCode;
    edResponseStatusOnCode.Text := deviceControlSettings.ResponseStatusOnCode;
    edResponseStatusOffCode.Text := deviceControlSettings.ResponseStatusOffCode;

    if ShowModal = mrOK then
    begin
      deviceControlSettings.PowerOnCode :=
        StrToPrintableStr(edPowerOnCode.Text);
      deviceControlSettings.ResponsePowerOnOKCode :=
        StrToPrintableStr(edResponsePowerOnOKCode.Text);

      deviceControlSettings.PowerOffCode :=
        StrToPrintableStr(edPowerOffCode.Text);
      deviceControlSettings.ResponsePowerOffOKCode :=
        StrToPrintableStr(edResponsePowerOffOKCode.Text);

      deviceControlSettings.PowerStatusCode :=
        StrToPrintableStr(edPowerStatusCode.Text);
      deviceControlSettings.ResponseStatusOnCode :=
        StrToPrintableStr(edResponseStatusOnCode.Text);
      deviceControlSettings.ResponseStatusOffCode :=
        StrToPrintableStr(edResponseStatusOffCode.Text);
    end;
  end;
end;

initialization
  frmControlCommandSetting := nil;

end.
