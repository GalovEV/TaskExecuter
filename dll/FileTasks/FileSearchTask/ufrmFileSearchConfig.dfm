object frmFileSearchConfig: TfrmFileSearchConfig
  Left = 0
  Top = 0
  Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099
  ClientHeight = 202
  ClientWidth = 645
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  DesignSize = (
    645
    202)
  TextHeight = 15
  object lblMask: TLabel
    Left = 16
    Top = 11
    Width = 38
    Height = 15
    Caption = #1052#1072#1089#1082#1072':'
  end
  object lblDir: TLabel
    Left = 20
    Top = 61
    Width = 69
    Height = 15
    Caption = #1044#1080#1088#1077#1082#1090#1086#1088#1080#1103':'
  end
  object edtMask: TEdit
    Left = 16
    Top = 32
    Width = 273
    Height = 23
    TabOrder = 0
  end
  object edtDirectory: TEdit
    Left = 16
    Top = 82
    Width = 547
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    ExplicitWidth = 530
  end
  object btnBrowse: TButton
    Left = 569
    Top = 81
    Width = 58
    Height = 25
    Caption = '...'
    TabOrder = 2
    OnClick = btnBrowseClick
  end
  object pBottom: TPanel
    Left = 0
    Top = 166
    Width = 645
    Height = 36
    Align = alBottom
    Anchors = [akRight, akBottom]
    BevelEdges = [beTop]
    BevelKind = bkFlat
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = 161
    ExplicitWidth = 335
    DesignSize = (
      645
      34)
    object bbOK: TBitBtn
      Left = 481
      Top = 4
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'OK'
      Default = True
      ModalResult = 1
      NumGlyphs = 2
      TabOrder = 0
    end
    object bbCancel: TBitBtn
      Left = 562
      Top = 4
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = #1054#1090#1084#1077#1085#1072
      ModalResult = 2
      NumGlyphs = 2
      TabOrder = 1
      ExplicitLeft = 256
    end
  end
  object chkRecursive: TCheckBox
    Left = 20
    Top = 120
    Width = 157
    Height = 17
    Caption = #1056#1077#1082#1091#1088#1089#1080#1074#1085#1099#1081' '#1087#1086#1080#1089#1082
    TabOrder = 4
    Visible = False
  end
  object chkReturnPaths: TCheckBox
    Left = 20
    Top = 143
    Width = 141
    Height = 17
    Caption = #1042#1086#1079#1074#1088#1072#1097#1072#1090#1100' '#1087#1091#1090#1080
    TabOrder = 5
    Visible = False
  end
end
