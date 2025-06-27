unit uTaskManager;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Winapi.Windows,
  uCommonInterface, uCommonType, System.SyncObjs;

type
  TTaskEvent = procedure(const ATaskID: string) of object;
  TProgressEvent = procedure(const ATaskID: string; AMessage: string; APercent: Integer; ATaskStatus: TTaskStatus) of object;
  TLogEvent = procedure(const ATaskID, AMessage: string) of object;
  TTaskCompletEvent = procedure(const ATaskID: string; AResult: string) of object;

  // Класс-обертка для передачи TaskID в коллбэки
  TTaskCallbackWrapper = class(TInterfacedObject, ITaskCallback)
  private
    FManager: ITaskCallback;
    FTaskID: string;
  protected
  //ITaskCallback
    procedure UpdateProgress(const AMessage: string; APercent: Integer; ATaskStatus: TTaskStatus);
    procedure LogMessage(const AMessage: string);
    procedure TaskCompleted(const ATaskID: string);
  public
    constructor Create(AManager: ITaskCallback; const ATaskID: string);
  end;

  // Поток для выполнения задачи
  TTaskThread = class(TThread)
  private
    FTask: ITask;
    FTaskID: string;
    FParams: TArray<TParamValue>;
    FCallback: ITaskCallback;
  protected
    procedure Execute; override;
  public
    constructor Create(ATask: ITask; const ATaskID: string;
      const AParams: array of TParamValue; ACallback: ITaskCallback);
  end;

  TTaskManager = class(TInterfacedObject, ITaskCallback, ITaskRegistry)
  private
    FTasks: TDictionary<string, ITask>;
    FActiveTasks: TDictionary<string, TTaskThread>;
    FCompletedTasks: TDictionary<string, ITask>;
    FDLLHandles: TList<HMODULE>;
    FTaskLogs: TDictionary<string, TStringList>;

    FOnTaskStarted: TTaskEvent;
    FOnTaskUpdated: TProgressEvent;
    FOnTaskCompleted: TTaskCompletEvent;
    FOnTaskLogged: TLogEvent;

    // ITaskCallback
    procedure UpdateProgress(const AMessage: string; APercent: Integer; ATaskStatus: TTaskStatus);
    procedure LogMessage(const AMessage: string);
    procedure TaskCompleted(const ATaskID: string);

    // ITaskRegistry
    procedure RegisterTask(ATask: ITask);

    // Внутренние методы
    procedure InternalTaskCompleted(const ATaskID: string);
    function GenerateUniqueID: string;
    procedure LoadTasksFromDLL(const AFileName: string);
    procedure AddTaskLog(const ATaskID: string; AMessage: string);
    procedure InnerLogMessage(const AMessage: string);
  public
    constructor Create;
   destructor Destroy; override;
//    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure LoadAllDLL;
    function GetTask(const ATaskID: string): ITask;
    procedure RunTask(ATask: ITask; const AParams: array of TParamValue);
    procedure CancelTask(const ATaskID: string);
    function GetTaskLog(const ATaskID: string): TStringList;
    function GetTaskResults(const ATaskID: string): string;

    property Tasks: TDictionary<string, ITask> read FTasks;
    property OnTaskStarted: TTaskEvent read FOnTaskStarted write FOnTaskStarted;
    property OnTaskUpdated: TProgressEvent read FOnTaskUpdated write FOnTaskUpdated;
    property OnTaskCompleted: TTaskCompletEvent read FOnTaskCompleted write FOnTaskCompleted;
    property OnTaskLogged: TLogEvent read FOnTaskLogged write FOnTaskLogged;
  end;

   TTaskRegistryProxy = class(TInterfacedObject, ITaskRegistry)
  private
   [Weak] FManager: TTaskManager;
  public
    constructor Create(Manager: TTaskManager);
    procedure RegisterTask(Task: ITask);
  end;

implementation

uses
  IOUtils;

{ TTaskCallbackWrapper }

constructor TTaskCallbackWrapper.Create(AManager: ITaskCallback; const ATaskID: string);
begin
  inherited Create;
  FManager := AManager;
  FTaskID := ATaskID;
end;

procedure TTaskManager.BeforeDestruction;
begin
  // Отменяем все активные задачи
  var ActiveIDs := FActiveTasks.Keys.ToArray;
  for var ID in ActiveIDs do
    CancelTask(ID);

  // Ждем завершения всех потоков
  var Threads := FActiveTasks.Values.ToArray;
  FActiveTasks.Clear;

  for var Thread in Threads do
  begin
    Thread.Free;
  end;

  // Очищаем словари
  FTasks.Clear;
  FCompletedTasks.Clear;
  FActiveTasks.Clear;

  // Освобождаем ресурсы логов
  for var Log in FTaskLogs.Values do
    Log.Free;
  FTaskLogs.Clear;

  // Освобождаем DLL
  for var Handle in FDLLHandles do
    FreeLibrary(Handle);
  FDLLHandles.Clear;

  FreeAndNil(FTasks);
  FreeAndNil(FActiveTasks);
  FreeAndNil(FCompletedTasks);
  FreeAndNil(FTaskLogs);
  FreeAndNil(FDLLHandles);

  OnTaskStarted := nil;
  OnTaskUpdated := nil;
  OnTaskCompleted := nil;
  OnTaskLogged := nil;

  inherited Destroy;
end;

destructor TTaskManager.Destroy;
begin

  inherited;
end;

procedure TTaskCallbackWrapper.LogMessage(const AMessage: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Values[FTaskID] := AMessage;
    FManager.LogMessage(SL.CommaText);
  finally
    SL.Free;
  end;
end;

procedure TTaskCallbackWrapper.TaskCompleted(const ATaskID: string);
begin
  FManager.TaskCompleted(ATaskID);
end;

procedure TTaskCallbackWrapper.UpdateProgress(const AMessage: string; APercent: Integer; ATaskStatus: TTaskStatus);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Values[FTaskID] := AMessage;
    FManager.UpdateProgress(SL.CommaText, APercent, ATaskStatus);
  finally
    SL.Free;
  end;
end;

{ TTaskThread }

constructor TTaskThread.Create(ATask: ITask; const ATaskID: string;
  const AParams: array of TParamValue; ACallback: ITaskCallback);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FTask := ATask;
  FTaskID := ATaskID;
  FCallback := ACallback;

  // Копируем параметры
  SetLength(FParams, Length(AParams));
  for var I := 0 to High(AParams) do
    FParams[I] := AParams[I];
end;

procedure TTaskThread.Execute;
begin
  try
    var ExecuteResult := FTask.Execute(FParams, FCallback);
    if ExecuteResult = erAbortUser then
      begin
        FCallback.LogMessage('Task canceled by user');
        FCallback.UpdateProgress('Task canceled by user', -1, tsCanceled);
      end
    else
     if ExecuteResult = erOk then
    begin
    // Уведомление о завершении через синхронизацию
      Synchronize(
        procedure
        begin
          FCallback.TaskCompleted(FTaskID);
        end);
    end;
  except
    on E: Exception do
      Begin
        FCallback.LogMessage('ERROR: ' + E.Message);
      End;
  end;


end;

{ TTaskManager }

constructor TTaskManager.Create;
begin
  inherited;
  FTasks := TDictionary<string, ITask>.Create;
  FActiveTasks := TDictionary<string, TTaskThread>.Create;
  FCompletedTasks := TDictionary<string, ITask>.Create;
  FDLLHandles := TList<HMODULE>.Create;
  FTaskLogs := TDictionary<string, TStringList>.Create;

end;

function TTaskManager.GenerateUniqueID: string;
begin
  Result := TGUID.NewGuid.ToString;
end;

procedure TTaskManager.LoadAllDLL;
begin
  FDLLHandles.Clear;
  FTasks.Clear;
  for var FileDll in TDirectory.GetFiles(ExtractFilePath(ParamStr(0)) + '\dll', '*.dll') do
    LoadTasksFromDLL(FileDll);
end;

procedure TTaskManager.LoadTasksFromDLL(const AFileName: string);
var
  Handle: HMODULE;
  RegisterProc: TRegisterTasksProc;
  Proxy: ITaskRegistry;
begin
  Handle := LoadLibrary(PWideChar(AFileName));
  if Handle = 0 then
    RaiseLastOSError;

  try
    @RegisterProc := GetProcAddress(Handle, 'RegisterTasks');
    if not Assigned(RegisterProc) then
      raise Exception.Create('DLL does not export RegisterTasks function');

    Proxy := TTaskRegistryProxy.Create(Self);
    try
      RegisterProc(Proxy); // Вызов функции регистрации в DLL
    finally
      // Прокси автоматически освободится при выходе из области видимости
    end;

    FDLLHandles.Add(Handle);
  except
     on E:  Exception do
     begin
       InnerLogMessage(Format('%s: %s', [AFileName, E.Message]));
       FreeLibrary(Handle);
     end;
  end;

end;

procedure TTaskManager.RegisterTask(ATask: ITask);
var
  TaskID: string;
begin
 // FCriticalSection.Enter;
  try
    TaskID := GenerateUniqueID;
    FTasks.Add(TaskID, ATask);
  finally
 //   FCriticalSection.Leave;
  end;
end;

procedure TTaskManager.RunTask(ATask: ITask; const AParams: array of TParamValue);
var
  lTaskID: string;
  Thread: TTaskThread;
  Callback: ITaskCallback;
begin
  lTaskID := GenerateUniqueID;

  // Создаем логгер для задачи
  var TaskLog := TStringList.Create;
  FTaskLogs.Add(lTaskID, TaskLog);

  // Создаем обертку для коллбэка с TaskID
  _AddRef;
  Callback := TTaskCallbackWrapper.Create(Self, lTaskID);

  // Создаем и запускаем поток
  Thread := TTaskThread.Create(ATask, lTaskID, AParams, Callback);
  FActiveTasks.Add(lTaskID, Thread);

  // Уведомляем UI о старте задачи
  TThread.Queue(nil,
    procedure
    begin
      if Assigned(FOnTaskStarted) then
        FOnTaskStarted(lTaskID);
    end);

  Thread.Start;
end;

procedure TTaskManager.TaskCompleted(const ATaskID: string);
begin
   InternalTaskCompleted(ATaskID);
end;

procedure TTaskManager.AddTaskLog(const ATaskID: string; AMessage: string);
begin
  var TaskLog := GetTaskLog(ATaskID);
  if Assigned(TaskLog) then
    TaskLog.Add(AMessage);
end;

procedure TTaskManager.CancelTask(const ATaskID: string);
begin
  if FActiveTasks.ContainsKey(ATaskID) then
  begin
    var Thread := FActiveTasks[ATaskID];
    if not Assigned(Thread.FTask) then
       exit;
    Thread.FTask.Cancel; // Запрос отмены
    Thread.Terminate;   // Принудительное завершение
    Thread.WaitFor;
  end;
end;

procedure TTaskManager.InnerLogMessage(const AMessage: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Values['TaskManager'] := AMessage;
    LogMessage(SL.CommaText);
  finally
    SL.Free;
  end;

end;

procedure TTaskManager.InternalTaskCompleted(const ATaskID: string);
begin
  if FActiveTasks.ContainsKey(ATaskID) then
  begin
    var Task := FActiveTasks[ATaskID].FTask;
    FActiveTasks.Remove(ATaskID);
    FCompletedTasks.Add(ATaskID, Task);

    if Assigned(FOnTaskCompleted) then
      FOnTaskCompleted(ATaskID, Task.GetResult);
  end;
end;

function TTaskManager.GetTask(const ATaskID: string): ITask;
begin
  if not FTasks.TryGetValue(ATaskID, Result) then
    Result := nil;
end;

function TTaskManager.GetTaskLog(const ATaskID: string): TStringList;
begin
  if not Assigned(FTaskLogs) then
    Exit(nil);
  if not FTaskLogs.TryGetValue(ATaskID, Result) then
    Result := nil;
end;

function TTaskManager.GetTaskResults(const ATaskID: string): string;
var
  lTask: ITask;
begin
  if not FCompletedTasks.TryGetValue(ATaskID, lTask) then
    Exit('');
  Result:= lTask.GetResult;
end;

{ ITaskCallback implementation }

procedure TTaskManager.LogMessage(const AMessage: string);
begin
  TThread.Queue(nil,
    procedure
    begin
       var SL := TStringList.Create;
      try
       SL.CommaText:= AMessage;
       if SL.Count > 0 then
       begin
         var lTaskID:= SL.Names[0];
         var lTaskMsg:= SL.ValueFromIndex[0];
         if Assigned(FOnTaskLogged) then
          FOnTaskLogged(lTaskID, lTaskMsg);

         // Добавление в лог задачи
         AddTaskLog(lTaskID, lTaskMsg);
       end;
      finally
        SL.Free;
      end;
    end);
//
end;

procedure TTaskManager.UpdateProgress(const AMessage: string; APercent: Integer; ATaskStatus: TTaskStatus);
begin
  TThread.Queue(nil,
    procedure
    begin
      var SL := TStringList.Create;
      try
        SL.CommaText := AMessage;
        if (SL.Count > 0) then
        begin
         var lTaskID:= SL.Names[0];
         var lTaskMsg:= SL.ValueFromIndex[0];
          if Assigned(FOnTaskUpdated) then
            FOnTaskUpdated(lTaskID, lTaskMsg, APercent, ATaskStatus);
        end;
      finally
        SL.Free;
      end;
    end);
end;

{ TTaskRegistryProxy }

constructor TTaskRegistryProxy.Create(Manager: TTaskManager);
begin
   inherited Create;
  FManager := Manager;
end;

procedure TTaskRegistryProxy.RegisterTask(Task: ITask);
begin
  FManager.RegisterTask(Task);
end;

end.
