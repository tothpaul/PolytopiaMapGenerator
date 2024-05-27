object Main: TMain
  Left = 0
  Top = 0
  Caption = 'Polytopia Map Generator'
  ClientHeight = 661
  ClientWidth = 1041
  Color = clBlack
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnPaint = FormPaint
  OnResize = FormResize
  TextHeight = 15
  object pnOptions: TPanel
    Left = 0
    Top = 0
    Width = 217
    Height = 661
    Align = alLeft
    Caption = 'pnOptions'
    ParentBackground = False
    ShowCaption = False
    TabOrder = 0
    object Label1: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 209
      Height = 15
      Align = alTop
      Caption = 'Map size'
      ExplicitWidth = 46
    end
    object lbLand: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 54
      Width = 209
      Height = 15
      Align = alTop
      Caption = 'Initial Land'
      ExplicitWidth = 58
    end
    object pbInitalLand: TPaintBox
      AlignWithMargins = True
      Left = 4
      Top = 75
      Width = 209
      Height = 14
      Align = alTop
      OnMouseDown = OnRangeMouseDown
      OnMouseMove = pbInitalLandMouseMove
      OnPaint = pbInitalLandPaint
    end
    object pbSmoothing: TPaintBox
      Tag = 1
      AlignWithMargins = True
      Left = 4
      Top = 116
      Width = 209
      Height = 14
      Align = alTop
      OnMouseDown = OnRangeMouseDown
      OnMouseMove = pbInitalLandMouseMove
      OnPaint = pbInitalLandPaint
      ExplicitLeft = 36
      ExplicitTop = 259
    end
    object lbSmooth: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 95
      Width = 209
      Height = 15
      Align = alTop
      Caption = 'Smoothing'
      ExplicitWidth = 59
    end
    object lbRelief: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 136
      Width = 209
      Height = 15
      Align = alTop
      Caption = 'Relief'
      ExplicitWidth = 29
    end
    object pbRelief: TPaintBox
      Tag = 2
      AlignWithMargins = True
      Left = 4
      Top = 157
      Width = 209
      Height = 14
      Align = alTop
      OnMouseDown = OnRangeMouseDown
      OnMouseMove = pbInitalLandMouseMove
      OnPaint = pbInitalLandPaint
      ExplicitTop = 255
    end
    object lblTribes: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 177
      Width = 209
      Height = 15
      Align = alTop
      Caption = 'Tribes'
      ExplicitWidth = 30
    end
    object Label2: TLabel
      AlignWithMargins = True
      Left = 4
      Top = 343
      Width = 209
      Height = 15
      Align = alTop
      Caption = 'Random Seed'
      ExplicitWidth = 73
    end
    object edMapSize: TEdit
      AlignWithMargins = True
      Left = 4
      Top = 25
      Width = 209
      Height = 23
      Align = alTop
      TabOrder = 0
      Text = '18'
    end
    object lbTribes: TCheckListBox
      AlignWithMargins = True
      Left = 4
      Top = 198
      Width = 209
      Height = 139
      Align = alTop
      ItemHeight = 15
      TabOrder = 1
    end
    object btGenerate: TButton
      Left = 24
      Top = 408
      Width = 169
      Height = 41
      Caption = 'Generate'
      TabOrder = 2
      OnClick = btGenerateClick
    end
    object edSeed: TEdit
      AlignWithMargins = True
      Left = 4
      Top = 364
      Width = 209
      Height = 23
      Align = alTop
      TabOrder = 3
    end
  end
end
