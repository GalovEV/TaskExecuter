unit uFileSearchTask;

interface
uses  Classes, SysUtils, Generics.Collections, uCommonTask, uCommonInterface, uCommonType;

type
  TFileSearchConfigWrapper = class (TTaskConfigWrapper)
  private
  protected
  function ShowConfigForm(var VExecuteParam: TArray<TParamValue>): Boolean;  override;
  public
  end;

  TFileSearchTask = class(TTaskImplementation, ITaskWithConfig)
  private
  protected
  function DoExecute(const AParamValues: TArray<TParamValue>; ACallback: ITaskCallback): Boolean; override;
   // ITaskWithConfig
   protected
    function CreateConfigForm(AOwner: TComponent): ITaskConfigForm;
  public
     procedure AfterConstruction; override;
  end;
implementation

uses
 ufrmFileSearchConfig, Controls, System.Types, System.IOUtils, System.Variants;

{TFileSearchTask}

procedure TFileSearchTask.AfterConstruction;
begin
  inherited;
  FTaskID := 'FileSearch';
  FTaskName:= '����� ������';

// ���������: �����, �����
// ���� ����� ����������
end;

function TFileSearchTask.CreateConfigForm(AOwner: TComponent): ITaskConfigForm;
begin
  Result := TFileSearchConfigWrapper.Create(AOwner);
end;

function TFileSearchTask.DoExecute(const AParamValues: TArray<TParamValue>;
  ACallback: ITaskCallback): Boolean;
var
  Mask, Dir: string;
  Files: TStringDynArray;
  Total, Current: Integer;
begin
  Result := true;

  FCanceled := False;

  // �������� ����������
  if Length(AParamValues) < 2 then
    raise Exception.Create('������������ ����������');

  Mask := VarToStr(AParamValues[0]);
  Dir := IncludeTrailingPathDelimiter(VarToStr(AParamValues[1]));

  if not TDirectory.Exists(Dir) then
    raise Exception.CreateFmt('���������� �� ����������: %s', [Dir]);

  // ����� ������
  ACallback.LogMessage(Format('������ ������: %s � %s', [Mask, Dir]));

  Files := TDirectory.GetFiles(Dir, Mask, TSearchOption.soAllDirectories);
  Total := Length(Files);

  // ��������� �����������
  Current := 0;
  for var FilePath in Files do
  begin
    if FCanceled then Exit(False);

    Inc(Current);
    if Current mod 100 = 0 then
    begin
      ACallback.UpdateProgress(
       Format('���������� �����: %d', [Total]),
       100,
       tsCompleted
      );
      Sleep(300);
    end
    else
      ACallback.UpdateProgress(
       Format('����������: %d/%d', [Current, Total]),
       Round(Current / Total * 100),
       tsRunning
      );

    // �������������� ���������
    ACallback.LogMessage('������: ' + FilePath);
    // ����������
     FTaskResult:= FTaskResult + #13 + FilePath;
  end;

  ACallback.UpdateProgress(Format('����� ��������. ������� ������: %d', [Total]), 100, tsCompleted);
end;

{ TFileSearchConfigWrapper }

function TFileSearchConfigWrapper.ShowConfigForm(
  var VExecuteParam: TArray<TParamValue>): Boolean;
  var
    FConfigForm: TfrmFileSearchConfig;
begin
   FConfigForm:= TfrmFileSearchConfig.Create(FOwner);
   try
      Result:= FConfigForm.ShowModal = mrOk;
      if Result then
        VExecuteParam:= FConfigForm.ExecuteParam;
   finally
      FConfigForm.Free;
   end;
end;

end.
