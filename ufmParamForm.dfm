object fmParamForm: TfmParamForm
  Left = 0
  Top = 0
  Caption = #1055#1072#1088#1072#1084#1077#1090#1088#1099
  ClientHeight = 442
  ClientWidth = 628
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 15
  object pBottom: TPanel
    Left = 0
    Top = 406
    Width = 628
    Height = 36
    Align = alBottom
    Anchors = [akRight, akBottom]
    BevelEdges = [beTop]
    BevelKind = bkFlat
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitTop = 405
    ExplicitWidth = 624
    DesignSize = (
      628
      34)
    object bbOK: TBitBtn
      Left = 452
      Top = 4
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'OK'
      Default = True
      ModalResult = 1
      NumGlyphs = 2
      TabOrder = 0
      ExplicitLeft = 448
    end
    object bbCancel: TBitBtn
      Left = 533
      Top = 4
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = #1054#1090#1084#1077#1085#1072
      ModalResult = 2
      NumGlyphs = 2
      TabOrder = 1
      ExplicitLeft = 529
    end
  end
  object ScrollBox: TScrollBox
    Left = 0
    Top = 0
    Width = 628
    Height = 406
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 624
    ExplicitHeight = 405
  end
end
