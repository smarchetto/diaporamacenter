object ControlCommandSettingForm: TControlCommandSettingForm
  Left = 0
  Top = 0
  Caption = 'Control Commands'
  ClientHeight = 207
  ClientWidth = 581
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblPowerOn: TLabel
    Left = 16
    Top = 37
    Width = 49
    Height = 13
    Caption = 'Power on:'
  end
  object lblPowerOff: TLabel
    Left = 16
    Top = 69
    Width = 51
    Height = 13
    Caption = 'Power off:'
  end
  object lblPowerOnOKCode: TLabel
    Left = 314
    Top = 37
    Width = 63
    Height = 13
    Caption = 'Acknowledge'
  end
  object lblPowerOffOKCode: TLabel
    Left = 314
    Top = 69
    Width = 67
    Height = 13
    Caption = 'Acknowledge:'
  end
  object lblPowerStatusCode: TLabel
    Left = 16
    Top = 101
    Width = 67
    Height = 13
    Caption = 'Power status:'
  end
  object lblResponseOnCode: TLabel
    Left = 314
    Top = 101
    Width = 54
    Height = 13
    Caption = 'On status :'
  end
  object lblResponseOffCode: TLabel
    Left = 314
    Top = 134
    Width = 53
    Height = 13
    Caption = 'Off status:'
  end
  object lblPowerOnOffCommands: TLabel
    Left = 8
    Top = 8
    Width = 117
    Height = 13
    Caption = 'Device power on/off '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object edPowerOnCode: TEdit
    Left = 169
    Top = 34
    Width = 121
    Height = 21
    TabOrder = 0
  end
  object edPowerOffCode: TEdit
    Left = 169
    Top = 66
    Width = 121
    Height = 21
    TabOrder = 2
  end
  object edResponsePowerOnOKCode: TEdit
    Left = 449
    Top = 34
    Width = 121
    Height = 21
    TabOrder = 1
  end
  object edResponsePowerOffOKCode: TEdit
    Left = 449
    Top = 66
    Width = 121
    Height = 21
    TabOrder = 3
  end
  object btnOK: TButton
    Left = 406
    Top = 171
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 7
  end
  object btnCancel: TButton
    Left = 492
    Top = 171
    Width = 78
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 8
  end
  object edPowerStatusCode: TEdit
    Left = 169
    Top = 98
    Width = 121
    Height = 21
    TabOrder = 4
  end
  object edResponseStatusOnCode: TEdit
    Left = 449
    Top = 98
    Width = 121
    Height = 21
    TabOrder = 5
  end
  object edResponseStatusOffCode: TEdit
    Left = 449
    Top = 131
    Width = 121
    Height = 21
    TabOrder = 6
  end
end
