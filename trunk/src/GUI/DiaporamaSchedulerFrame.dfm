object FrameDiaporamaScheduler: TFrameDiaporamaScheduler
  Left = 0
  Top = 0
  Width = 463
  Height = 628
  TabOrder = 0
  DesignSize = (
    463
    628)
  object pnlButton: TPanel
    Left = 0
    Top = 589
    Width = 463
    Height = 39
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    DesignSize = (
      463
      39)
    object btnApplySettings: TButton
      Left = 284
      Top = 11
      Width = 85
      Height = 25
      Action = actApplyDeviceSettings
      Anchors = [akTop, akRight]
      Caption = 'Apply'
      TabOrder = 0
    end
    object btnSaveSettings: TButton
      Left = 375
      Top = 11
      Width = 85
      Height = 25
      Action = actSaveDeviceSettings
      Anchors = [akTop, akRight]
      Caption = 'Save'
      TabOrder = 1
    end
  end
  object pnlPageControl: TPanel
    Left = 4
    Top = 8
    Width = 463
    Height = 589
    Anchors = [akLeft, akTop, akRight, akBottom]
    BevelOuter = bvNone
    TabOrder = 1
    object pnlDiaporama: TPanel
      Left = 0
      Top = 497
      Width = 463
      Height = 92
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      DesignSize = (
        463
        92)
      object diaporamaPageControl: TPageControl
        Left = 0
        Top = 25
        Width = 463
        Height = 76
        Anchors = [akLeft, akTop, akRight, akBottom]
        Style = tsFlatButtons
        TabOrder = 0
      end
      object pnlDiaporamaHeader: TPanel
        Left = 0
        Top = 0
        Width = 463
        Height = 24
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object lblDiaporamaHeader: TLabel
          Left = 2
          Top = 0
          Width = 68
          Height = 13
          Caption = 'Diaporamas'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
    end
    object pnlDevice: TPanel
      Left = 0
      Top = 0
      Width = 463
      Height = 497
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      DesignSize = (
        463
        497)
      object devicePageControl: TPageControl
        Left = 0
        Top = 120
        Width = 463
        Height = 371
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
      object pnlDeviceHeader: TPanel
        Left = 0
        Top = 0
        Width = 463
        Height = 24
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object lblDeviceHeader: TLabel
          Left = 2
          Top = 0
          Width = 44
          Height = 13
          Caption = 'Devices'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
    end
  end
  object ActionList: TActionList
    Left = 424
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
