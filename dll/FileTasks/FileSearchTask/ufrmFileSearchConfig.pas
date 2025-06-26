unit ufrmFileSearchConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Buttons, Vcl.ExtCtrls, Vcl.StdCtrls, uCommonType;

type
  TfrmFileSearchConfig = class(TForm)
    edtMask: TEdit;
    lblMask: TLabel;
    lblDir: TLabel;
    edtDirectory: TEdit;
    btnBrowse: TButton;
    pBottom: TPanel;
    bbOK: TBitBtn;
    bbCancel: TBitBtn;
    chkRecursive: TCheckBox;
    chkReturnPaths: TCheckBox;
    procedure btnBrowseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
     function ExecuteParam: TArray<TParamValue>;
  end;

var
  frmFileSearchConfig: TfrmFileSearchConfig;

implementation
uses
  Vcl.FileCtrl;
{$R *.dfm}

{ TfrmFileSearchConfig }

procedure TfrmFileSearchConfig.btnBrowseClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtDirectory.Text;
  if SelectDirectory('Select Directory', '', Dir) then
    edtDirectory.Text := Dir;

end;

function TfrmFileSearchConfig.ExecuteParam: TArray<TParamValue>;
begin
  SetLength(Result, 4);
  Result[0] := edtMask.Text;           // Маска
  Result[1] := edtDirectory.Text;      // Директория
  Result[2] := chkRecursive.Checked;   // Рекурсивный поиск
  Result[3] := chkReturnPaths.Checked; // Возвращать пути
end;

end.
