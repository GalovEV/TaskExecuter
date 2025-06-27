unit ufmParamForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, Generics.Collections,
  uCommonType;

type
  TPathButtonClickObj = class
   public
   class var FEditName: string;
   class procedure ButtonClickHandler(Sender: TObject);
  end;

  TFileButtonClickObj = class
   public
   class var FEditName: string;
   class procedure ButtonClickHandler(Sender: TObject);
  end;

  TfmParamForm = class(TForm)
    pBottom: TPanel;
    bbOK: TBitBtn;
    bbCancel: TBitBtn;
    ScrollBox: TScrollBox;
  private
    { Private declarations }
    FControls: TList<TControl>;
    procedure Init(AParams: TArray<TTaskParam>);
    function CreateEditForParam(Param: TTaskParam; Top: Integer): TEdit;
    function CreateComboForParam(Param: TTaskParam; Top: Integer): TComboBox;

  public
    { Public declarations }
    constructor Create(AOwner: TComponent; AParams: TArray<TTaskParam>); reintroduce;
    destructor Destroy; override;
    function GetParams: TArray<TParamValue>;
  end;

implementation

uses
  System.Math, Vcl.FileCtrl;

{$R *.dfm}

{ TfmParamForm }

constructor TfmParamForm.Create(AOwner: TComponent; AParams: TArray<TTaskParam>);
begin
  inherited Create(AOwner);

  FControls:= TList<TControl>.Create;
  Init(AParams);
end;

function TfmParamForm.CreateComboForParam(Param: TTaskParam;
  Top: Integer): TComboBox;
begin
  Result := TComboBox.Create(Self);
  Result.Parent := ScrollBox;
  Result.Left := 200;
  Result.Top := Top;
  Result.Width := 250;
  Result.Style := csDropDownList;
  Result.Items.Add('Да');
  Result.Items.Add('Нет');
  Result.ItemIndex := Integer(Boolean(Param.DefaultValue));
end;

function TfmParamForm.CreateEditForParam(Param: TTaskParam;
  Top: Integer): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := ScrollBox;
  Result.Left := 200;
  Result.Top := Top;
  Result.Width := 250;
  Result.Text := VarToStr(Param.DefaultValue);


  if Param.ParamType in [ptFolder, ptFile] then
  begin
    var Button := TButton.Create(Self);
    Button.Parent := ScrollBox;
    Button.Left := Result.Left + Result.Width + 5;
    Button.Top := Top;
    Button.Caption := '...';
    // Реализация выбора папки
    if Param.ParamType = ptFolder then
    begin
      Result.Name:= 'Edit_Folder';
      TPathButtonClickObj.FEditName:= Result.Name;
      Button.OnClick:= TPathButtonClickObj.ButtonClickHandler;
    end
     else
    begin
      Result.Name:= 'Edit_File';
      TFileButtonClickObj.FEditName:= Result.Name;
      Button.OnClick:= TFileButtonClickObj.ButtonClickHandler;
    end;
    FControls.Add(Button);
  end;


end;

destructor TfmParamForm.Destroy;
begin
  FControls.Free;
  inherited;
end;

function TfmParamForm.GetParams: TArray<TParamValue>;
var
  Index: Integer;
begin
//  SetLength(Result, FControls.Count);
  Index := 0;

  for var Control in FControls do
  begin
    if Control is TButton then
      Continue;
      SetLength(Result, Index + 1);
    if Control is TEdit then
      Result[Index] := TEdit(Control).Text
    else if Control is TComboBox then
      Result[Index] := TComboBox(Control).ItemIndex = 0;

    Inc(Index);
  end;
end;

procedure TfmParamForm.Init(AParams: TArray<TTaskParam>);
var
  TopPos: Integer;
begin
  TopPos:= 10;
  for var lParam in AParams do
  begin
    var lLabel := TLabel.Create(Self);
    lLabel.Parent := ScrollBox;
    lLabel.Left := 10;
    lLabel.Top := TopPos;
    lLabel.Caption := lParam.Description + ':';

    case lParam.ParamType of
      ptString, ptFile, ptFolder:
        FControls.Add(CreateEditForParam(lParam, TopPos));

      ptInteger:
        FControls.Add(CreateEditForParam(lParam, TopPos));

      ptBoolean:
        FControls.Add(CreateComboForParam(lParam, TopPos));
    end;

    Inc(TopPos, 30);
  end;

  Height := Min(600, TopPos + 100);

end;

{ TPathButtonClickObj }

class procedure TPathButtonClickObj.ButtonClickHandler(Sender: TObject);
var
  Dir: string;
  lEdit: TEdit;
begin
  lEdit:= TEdit((Sender as TButton).Parent.Parent.FindComponent(FEditName));
  if not assigned(lEdit) then
    Exit;

  Dir := lEdit.Text;
  if SelectDirectory('Select Directory', '', Dir) then
    lEdit.Text := Dir;
end;

{ TFileButtonClickObj }

class procedure TFileButtonClickObj.ButtonClickHandler(Sender: TObject);
var
  lEdit: TEdit;

  dlg: TOpenDialog;
begin
  lEdit:= TButton(Sender).Parent.Parent.FindComponent(FEditName) as TEdit;
  if not assigned(lEdit) then
    Exit;

  dlg := TOpenDialog.Create(nil);
  try
    dlg.InitialDir := GetCurrentDir;
    dlg.Options := [ofFileMustExist];
    dlg.Filter := 'All files (*.*)|*.*';
    if dlg.Execute then
      lEdit.Text := dlg.FileName;
  finally
    dlg.Free;
  end;

end;

end.
