object FrameDiaporamaSettings: TFrameDiaporamaSettings
  Left = 0
  Top = 0
  Width = 478
  Height = 480
  TabOrder = 0
  object PageControl: TPageControl
    Left = 0
    Top = 8
    Width = 478
    Height = 445
    ActivePage = tsDownload
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    Style = tsFlatButtons
    TabOrder = 0
    object tsPaths: TTabSheet
      Caption = 'Paths'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object lblRepositoryPath: TLabel
        Left = 12
        Top = 36
        Width = 34
        Height = 13
        Caption = 'Cache:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblDevicePath: TLabel
        Left = 12
        Top = 92
        Width = 41
        Height = 13
        Caption = 'Devices:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblTemplatePath: TLabel
        Left = 12
        Top = 149
        Width = 53
        Height = 13
        Caption = 'Templates:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblDiaporamaListFilePath: TLabel
        Left = 12
        Top = 242
        Width = 71
        Height = 13
        Caption = 'Diaporama list:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblDiapositiveTypeFilePath: TLabel
        Left = 12
        Top = 300
        Width = 56
        Height = 13
        Caption = 'Slide types:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblPaths: TLabel
        Left = 4
        Top = 8
        Width = 41
        Height = 13
        Caption = 'Folders'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblFiles: TLabel
        Left = 4
        Top = 214
        Width = 25
        Height = 13
        Caption = 'Files'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object edRepositoryPath: TEdit
        Left = 12
        Top = 54
        Width = 397
        Height = 21
        TabOrder = 0
        OnChange = UpdateFromGUI
      end
      object btnOpenRepositoryPath: TButton
        Left = 415
        Top = 54
        Width = 25
        Height = 21
        Caption = '...'
        TabOrder = 1
        OnClick = btnOpenRepositoryPathClick
      end
      object edDevicePath: TEdit
        Left = 12
        Top = 110
        Width = 397
        Height = 21
        TabOrder = 2
        OnChange = UpdateFromGUI
      end
      object btnOpenDevicePath: TButton
        Left = 415
        Top = 110
        Width = 25
        Height = 21
        Caption = '...'
        TabOrder = 3
        OnClick = btnOpenDevicePathClick
      end
      object edTemplatePath: TEdit
        Left = 12
        Top = 168
        Width = 397
        Height = 21
        TabOrder = 4
        OnChange = UpdateFromGUI
      end
      object btnOpenTemplatePath: TButton
        Left = 415
        Top = 168
        Width = 25
        Height = 21
        Caption = '...'
        TabOrder = 5
        OnClick = btnOpenTemplatePathClick
      end
      object edDiaporamaListFilePath: TEdit
        Left = 12
        Top = 260
        Width = 397
        Height = 21
        TabOrder = 6
        OnChange = UpdateFromGUI
      end
      object btnOpenDiaporamaListFilePath: TButton
        Left = 415
        Top = 260
        Width = 25
        Height = 21
        Caption = '...'
        TabOrder = 7
        OnClick = btnOpenDiaporamaListFilePathClick
      end
      object edDiapositiveTypeFilePath: TEdit
        Left = 12
        Top = 318
        Width = 397
        Height = 21
        TabOrder = 8
        OnChange = UpdateFromGUI
      end
      object btnOpenDiapositiveTypeFilePath: TButton
        Left = 415
        Top = 318
        Width = 25
        Height = 21
        Caption = '...'
        TabOrder = 9
        OnClick = btnOpenDiapositiveTypeFilePathClick
      end
    end
    object tsDownload: TTabSheet
      Caption = 'Download'
      ImageIndex = 1
      object lblConnection: TLabel
        Left = 12
        Top = 36
        Width = 51
        Height = 13
        Caption = 'Login URL:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblLogin: TLabel
        Left = 12
        Top = 93
        Width = 29
        Height = 13
        Caption = 'Login:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblPassword: TLabel
        Left = 12
        Top = 120
        Width = 50
        Height = 13
        Caption = 'Password:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblDiaporamaList: TLabel
        Left = 12
        Top = 190
        Width = 93
        Height = 13
        Caption = 'Diaporama list URL:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblDiaporama: TLabel
        Left = 12
        Top = 284
        Width = 77
        Height = 13
        Caption = 'Diaporama URL:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblAuthentificationHeader: TLabel
        Left = 4
        Top = 8
        Width = 91
        Height = 13
        Caption = 'Authentification'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblDiaporamaHeader: TLabel
        Left = 4
        Top = 162
        Width = 62
        Height = 13
        Caption = 'Diaporama'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object edLoginURL: TEdit
        Left = 12
        Top = 54
        Width = 419
        Height = 21
        TabOrder = 0
        OnChange = UpdateFromGUI
      end
      object edLogin: TEdit
        Left = 71
        Top = 90
        Width = 146
        Height = 21
        TabOrder = 1
        OnChange = UpdateFromGUI
      end
      object edPassword: TEdit
        Left = 71
        Top = 117
        Width = 146
        Height = 21
        PasswordChar = '*'
        TabOrder = 2
        OnChange = UpdateFromGUI
      end
      object edDiaporamaListUrl: TEdit
        Left = 12
        Top = 209
        Width = 419
        Height = 21
        TabOrder = 3
        OnChange = UpdateFromGUI
      end
      object btnDownloadList: TButton
        Left = 12
        Top = 238
        Width = 149
        Height = 25
        Action = actDownloadDiaporamaList
        Caption = 'Download diaporama list'
        TabOrder = 4
      end
      object edDiaporamaURL: TEdit
        Left = 12
        Top = 303
        Width = 419
        Height = 21
        TabOrder = 5
        OnChange = UpdateFromGUI
      end
    end
  end
  object pnlButton: TPanel
    Left = 0
    Top = 445
    Width = 478
    Height = 35
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      478
      35)
    object btnApplySettings: TButton
      Left = 299
      Top = 7
      Width = 85
      Height = 25
      Action = actApplySettings
      Anchors = [akTop, akRight]
      Caption = 'Apply'
      TabOrder = 0
    end
    object btnSaveSettings: TButton
      Left = 390
      Top = 7
      Width = 85
      Height = 25
      Action = actSaveSettings
      Anchors = [akTop, akRight]
      Caption = 'Save'
      TabOrder = 1
    end
  end
  object ActionList: TActionList
    Left = 8
    Top = 424
    object actApplySettings: TAction
      Caption = 'Appliquer'
      OnExecute = actApplySettingsExecute
      OnUpdate = actApplySettingsUpdate
    end
    object actSaveSettings: TAction
      Caption = 'Sauvegarder'
      OnExecute = actSaveSettingsExecute
      OnUpdate = actSaveSettingsUpdate
    end
    object actDownloadDiaporamaList: TAction
      Caption = 'T'#233'l'#233'charger la liste'
      OnExecute = actDownloadDiaporamaListExecute
    end
  end
  object OpenFileDialog: TOpenDialog
    DefaultExt = 'xml'
    Filter = 'XML (*.xml)|*.xml'
    Left = 48
    Top = 424
  end
end
