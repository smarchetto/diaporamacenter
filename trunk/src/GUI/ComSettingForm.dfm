object ComSettingForm: TComSettingForm
  Left = 381
  Top = 182
  BorderStyle = bsDialog
  Caption = 'RS232 Port'
  ClientHeight = 298
  ClientWidth = 250
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblBaudRate: TLabel
    Left = 8
    Top = 42
    Width = 49
    Height = 13
    Caption = 'Baud rate:'
  end
  object lblPort: TLabel
    Left = 8
    Top = 11
    Width = 25
    Height = 13
    Caption = 'Port :'
  end
  object lblDataBits: TLabel
    Left = 8
    Top = 73
    Width = 45
    Height = 13
    Caption = 'Data bits:'
  end
  object lblFlowControl: TLabel
    Left = 8
    Top = 166
    Width = 60
    Height = 13
    Caption = 'Flow control:'
  end
  object lblParity: TLabel
    Left = 8
    Top = 104
    Width = 48
    Height = 13
    Caption = 'Parity bits:'
  end
  object lblStopBits: TLabel
    Left = 8
    Top = 135
    Width = 44
    Height = 13
    Caption = 'Stop bits:'
  end
  object lblTimeOutConstant: TLabel
    Left = 8
    Top = 197
    Width = 95
    Height = 13
    Caption = 'Constant delay (ms):'
  end
  object lblTimeOutPerChar: TLabel
    Left = 9
    Top = 228
    Width = 118
    Height = 13
    Caption = 'Delay per character (ms):'
  end
  object btnOK: TButton
    Left = 78
    Top = 266
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 8
  end
  object btnCancel: TButton
    Left = 166
    Top = 266
    Width = 78
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 9
  end
  object cbBaudRate: TComComboBox
    Left = 133
    Top = 39
    Width = 109
    Height = 21
    ComProperty = cpBaudRate
    Text = 'Custom'
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 1
  end
  object cbPort: TComComboBox
    Left = 133
    Top = 8
    Width = 109
    Height = 21
    ComProperty = cpPort
    Text = 'COM1'
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 0
  end
  object cbDataBits: TComComboBox
    Left = 133
    Top = 70
    Width = 109
    Height = 21
    ComProperty = cpDataBits
    Text = '5'
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 2
  end
  object cbFlowControl: TComComboBox
    Left = 133
    Top = 163
    Width = 109
    Height = 21
    ComProperty = cpFlowControl
    Text = 'Hardware'
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 5
  end
  object cbParity: TComComboBox
    Left = 133
    Top = 101
    Width = 109
    Height = 21
    ComProperty = cpParity
    Text = 'None'
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 3
  end
  object cbStopBits: TComComboBox
    Left = 133
    Top = 132
    Width = 109
    Height = 21
    ComProperty = cpStopBits
    Text = '1'
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 4
  end
  object SeTimeOutConstant: TSpinEdit
    Left = 133
    Top = 194
    Width = 109
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 6
    Value = 250
  end
  object seTimeOutPerChar: TSpinEdit
    Left = 133
    Top = 225
    Width = 109
    Height = 22
    MaxValue = 0
    MinValue = 0
    TabOrder = 7
    Value = 20
  end
end
