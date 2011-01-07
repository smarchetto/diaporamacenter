object FrameDiaporamaDevice: TFrameDiaporamaDevice
  Left = 0
  Top = 0
  Width = 470
  Height = 628
  Anchors = [akLeft, akTop, akRight]
  TabOrder = 0
  Visible = False
  DesignSize = (
    470
    628)
  object PageControl: TPageControl
    Left = 4
    Top = 8
    Width = 470
    Height = 593
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Style = tsFlatButtons
    TabOrder = 0
  end
  object pnlButton: TPanel
    Left = 0
    Top = 593
    Width = 470
    Height = 35
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      470
      35)
    object btnApplySettings: TButton
      Left = 291
      Top = 7
      Width = 85
      Height = 25
      Action = actApplyDeviceSettings
      Anchors = [akTop, akRight]
      Caption = 'Apply'
      TabOrder = 0
    end
    object btnSaveSettings: TButton
      Left = 382
      Top = 7
      Width = 85
      Height = 25
      Action = actSaveDeviceSettings
      Anchors = [akTop, akRight]
      Caption = 'Save'
      TabOrder = 1
    end
  end
  object ActionList: TActionList
    Left = 8
    Top = 8
    object actSaveDeviceSettings: TAction
      Caption = 'Sauvegarder'
      OnExecute = actSaveDeviceSettingsExecute
      OnUpdate = actSaveDeviceSettingsUpdate
    end
    object actApplyDeviceSettings: TAction
      Caption = 'Appliquer'
      OnExecute = actApplyDeviceSettingsExecute
      OnUpdate = actApplyDeviceSettingsUpdate
    end
  end
end
