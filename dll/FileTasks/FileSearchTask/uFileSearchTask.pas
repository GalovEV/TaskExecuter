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

//    function GetFormResults(Form: TForm): TArray<TParamValue>;
  protected
//  function DoCreateConfigForm(AOwner: TComponent): ITaskConfigForm; override;
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
  FTaskName:= 'Поиск файлов';

// Параметры: маска, папка
//  SetLength(FParams, 2);
//  FParams[0].Name := 'Mask';
//  FParams[0].Description := 'Маска файлов (например, *.txt)';
//  FParams[0].ParamType := ptString;
//  FParams[0].DefaultValue := '*.*';
//  FParams[1].Name := 'Folder';
//  FParams[1].Description := 'Папка для поиска';
//  FParams[1].ParamType := ptFolder;
//  FParams[1].DefaultValue := '';
end;

function TFileSearchTask.CreateConfigForm(AOwner: TComponent): ITaskConfigForm;
begin
  Result := TFileSearchConfigWrapper.Create(AOwner);
end;

//function TFileSearchTask.DoCreateConfigForm(AOwner: TComponent): ITaskConfigForm;
//begin
//  Result := TFileSearchConfigWrapper.Create(AOwner);
//end;

//function TFileSearchTask.CreateConfigForm(AOwner: TComponent): TForm;
//begin
//  Result := TfrmFileSearchConfig.Create(AOwner);
//end;

function TFileSearchTask.DoExecute(const AParamValues: TArray<TParamValue>;
  ACallback: ITaskCallback): Boolean;
var
  Mask, Dir: string;
  Files: TStringDynArray;
  Total, Current: Integer;
//  SL: TStringList;
begin
  Result := true;

  FCanceled := False;

  // Проверка параметров
  if Length(AParamValues) < 2 then
    raise Exception.Create('Недостаточно параметров');

  Mask := VarToStr(AParamValues[0]);
  Dir := IncludeTrailingPathDelimiter(VarToStr(AParamValues[1]));

  if not TDirectory.Exists(Dir) then
    raise Exception.CreateFmt('Директория не существует: %s', [Dir]);

  // Поиск файлов
  ACallback.LogMessage(Format('Начало поиска: %s в %s', [Mask, Dir]));

  Files := TDirectory.GetFiles(Dir, Mask, TSearchOption.soAllDirectories);
  Total := Length(Files);

  // Обработка результатов
  Current := 0;
  for var FilePath in Files do
  begin
    if FCanceled then Exit(False);

    Inc(Current);
    Sleep(300);
    if Current mod 100 = 0 then
    begin
      ACallback.UpdateProgress(
       Format('Обработано всего: %d', [Total]),
       100,
       tsCompleted
      );
      Sleep(300);
    end
    else
      ACallback.UpdateProgress(
       Format('Обработано: %d/%d', [Current, Total]),
       Round(Current / Total * 100),
       tsRunning
      );

    // Дополнительный результат
    ACallback.LogMessage('Найден: ' + FilePath);
    // Результаты
     FTaskResult:= FTaskResult + #13 + FilePath;
  end;

  ACallback.UpdateProgress(Format('Поиск завершен. Найдено файлов: %d', [Total]), 100, tsCompleted);
end;

//function TFileSearchTask.GetFormResults(Form: TForm): TArray<TParamValue>;
//begin
//  if Form is TfrmFileSearchConfig then
//    Result := TfrmFileSearchConfig(Form).GetFormResults
//  else
//    raise Exception.Create('Invalid form type');
//end;

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
