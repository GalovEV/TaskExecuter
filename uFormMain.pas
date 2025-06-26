unit uFormMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Menus, System.Actions, Vcl.ActnList, System.ImageList, Vcl.ImgList,
  Vcl.ToolWin, uTaskManager, uCommonType;

type
  TFormMain = class(TForm)
    Panel1: TPanel;
    Splitter1: TSplitter;
    pLeft: TPanel;
    pTop: TPanel;
    edFilter: TEdit;
    Panel3: TPanel;
    lvExecuteTasks: TListView;
    ActionList: TActionList;
    actStartReport: TAction;
    actBreakReport: TAction;
    actAbout: TAction;
    actPreviewTaskLog: TAction;
    actWorkParams: TAction;
    actRefresh: TAction;
    actMoveUp: TAction;
    actMoveDown: TAction;
    ASaveToAllUsers: TAction;
    ShowHelp: TAction;
    pmTaskList: TPopupMenu;
    N12: TMenuItem;
    N13: TMenuItem;
    N11: TMenuItem;
    N4: TMenuItem;
    N3: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N6: TMenuItem;
    N8: TMenuItem;
    ToolBar1: TToolBar;
    ToolButton9: TToolButton;
    tbStart: TToolButton;
    tbAbout: TToolButton;
    HotImages32x32: TImageList;
    DisabledImages32x32: TImageList;
    lvTasks: TListView;
    tbDeleteReport: TToolButton;
    ToolButton7: TToolButton;
    MemoLog: TMemo;
    Splitter2: TSplitter;
    lvCompleted: TListView;
    btn1: TToolButton;
    tbOpenTaskLog: TToolButton;
    procedure actRefreshUpdate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure actRefreshExecute(Sender: TObject);
    procedure actStartReportExecute(Sender: TObject);
    procedure actStartReportUpdate(Sender: TObject);
    procedure actBreakReportExecute(Sender: TObject);
    procedure actBreakReportUpdate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure actPreviewTaskLogUpdate(Sender: TObject);
    procedure actPreviewTaskLogExecute(Sender: TObject);
  private
    { Private declarations }
    FTaskManager: TTaskManager;

    procedure RefreshTaskList;
    procedure StartTask(ATaskID: string);
    procedure StopTask(ATaskID: string);   
    procedure OpenTaskLog(ATaskID: string); 
//    procedure RefreshActiveTasks;
//    procedure RefreshCompletedTasks;
  public
    { Public declarations }
    procedure TaskStarted(const ATaskID: string);
    procedure TaskUpdated(const ATaskID: string; AMessage: string; APercent: Integer; ATaskStatus: TTaskStatus);
    procedure TaskCompleted(const ATaskID: string; AResult: string);
    procedure TaskLogged(const ATaskID: string; const AMessage: string);
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}
 uses
  uCommonInterface, ufmParamForm;

{ TFormMain }

procedure TFormMain.actBreakReportExecute(Sender: TObject);
begin
  if lvExecuteTasks.Selected = nil then
    Exit;
  StopTask(lvExecuteTasks.Selected.Caption);
end;

procedure TFormMain.actBreakReportUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled:= Assigned(lvExecuteTasks.Selected);
end;

procedure TFormMain.actPreviewTaskLogExecute(Sender: TObject);
begin
  if lvCompleted.Selected <> nil then
    OpenTaskLog(lvCompleted.Selected.Caption);
end;

procedure TFormMain.actPreviewTaskLogUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled:= Assigned(lvCompleted.Selected);
end;

procedure TFormMain.actRefreshExecute(Sender: TObject);
begin
  RefreshTaskList;
end;

procedure TFormMain.actRefreshUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled:= True;
end;

procedure TFormMain.actStartReportExecute(Sender: TObject);
begin
  if lvTasks.Selected = nil then
    Exit;
  StartTask(lvTasks.Selected.Caption);
end;

procedure TFormMain.actStartReportUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled:= Assigned(lvTasks.Selected);
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FTaskManager := TTaskManager.Create;
  FTaskManager.OnTaskStarted := TaskStarted;
  FTaskManager.OnTaskUpdated := TaskUpdated;
  FTaskManager.OnTaskCompleted := TaskCompleted;
  FTaskManager.OnTaskLogged := TaskLogged;

  //RefreshTaskList;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  lvTasks.Items.Clear;
  lvExecuteTasks.Clear;
  lvCompleted.Clear;
  FreeAndNil(FTaskManager);
  inherited;
end;

procedure TFormMain.RefreshTaskList;
var
  lTask: ITask;
  Item: TListItem;
begin
  FTaskManager.LoadAllDLL;//(OpenDialog.FileName);
  //
  lvTasks.Items.Clear;
  for  lTask in FTaskManager.Tasks.Values do
//    for var lId in FTaskManager.Tasks.Keys do
  begin
    if lTask.GetTaskID = '' then
     Continue;

//    lTask:=  FTaskManager.Tasks.Items[lId];
    Item := lvTasks.Items.Add;
    Item.Caption := lTask.GetTaskID;
    Item.SubItems.Add(lTask.GetTaskName);
    Item.Data:= lTask;
  end;
end;

procedure TFormMain.StartTask(ATaskID: string);
var
  lTask: ITask;
  lTaskWithForm: ITaskWithConfig;
  lConfigForm: ITaskConfigForm;
  lParams: TArray<TParamValue>;
//  ParamsForm: TfrmParams;
begin
   lTask := ITask(lvTasks.Selected.Data);//FTaskManager.GetTask(ATaskID);
// Проверяем, поддерживает ли задача кастомную форму
  if Supports(lTask, ITaskWithConfig, lTaskWithForm) then
  begin
    lConfigForm := lTaskWithForm.CreateConfigForm(Self);
    try
      if lConfigForm.ShowConfig(lParams) = erOk then
      begin
//        lParams := lTaskWithForm.GetFormResults(ConfigForm);
//        lParams := lConfigForm.GetParams;
        FTaskManager.RunTask(lTask, lParams);
      end;
    finally
      lConfigForm:= nil;
    end;
  end
  else
  begin
    // Используем стандартную форму
    var ParamsForm := TfmParamForm.Create(nil, lTask.GetParams);
    try
      if ParamsForm.ShowModal = mrOk then
        FTaskManager.RunTask(lTask, ParamsForm.GetParams);
    finally
      ParamsForm.Free;
    end;
  end;

end;

procedure TFormMain.StopTask(ATaskID: string);
begin
  FTaskManager.CancelTask(ATaskID);
  //Замена статуса!
end;

procedure TFormMain.TaskCompleted(const ATaskID: string; AResult: string);
begin
// Переносим задачу в завершенные
  for var I := 0 to lvExecuteTasks.Items.Count - 1 do
    if lvExecuteTasks.Items[I].Caption = ATaskID then
    begin
      var Item := lvCompleted.Items.Add;
      Item.Caption := ATaskID;
      Item.SubItems.Add(lvExecuteTasks.Items[I].SubItems[0]); //
      Item.SubItems.Add(lvExecuteTasks.Items[I].SubItems[1]); //
//      Item.SubItems.Add(strStatusName[tsCompleted]);
      Item.SubItems.Add(lvExecuteTasks.Items[I].SubItems[2]);
      Item.SubItems.Add(AResult);  //Результаты

      lvExecuteTasks.Items.Delete(I);
      Break;
    end;
end;

procedure TFormMain.TaskLogged(const ATaskID: string; const AMessage: string);
begin
  // Добавляем сообщение в лог задачи
  MemoLog.Lines.Add(Format('[%s] %s: %s', 
    [FormatDateTime('hh:nn:ss', Now), ATaskID, AMessage]));
end;

procedure TFormMain.TaskStarted(const ATaskID: string);
begin
  // Добавляем задачу в список
  var Item := lvExecuteTasks.Items.Add;
  Item.Caption := ATaskID;
//  Item.Data:= FTaskManager.GetTask(ATaskID);
//  Item.SubItems.Add(FTaskManager.GetTask(ATaskID).GetTaskName);
  Item.SubItems.Add(strStatusName[tsRunning]);
  Item.SubItems.Add('');
  Item.SubItems.Add('0%');
  Item.SubItems.Add('');  //Параметры
end;

procedure TFormMain.TaskUpdated(const ATaskID: string; AMessage: string; APercent: Integer; ATaskStatus: TTaskStatus);
begin
  // Обновление статуса
  for var I := 0 to lvExecuteTasks.Items.Count - 1 do
    if lvExecuteTasks.Items[I].Caption = ATaskID then
    begin
      lvExecuteTasks.Items[I].SubItems.Strings[0] := strStatusName[ATaskStatus];
      //if AMessage <> '' then
        lvExecuteTasks.Items[I].SubItems.Strings[1] := AMessage;
      if APercent = -1 then
        //lvExecuteTasks.Items[I].SubItems.Strings[2] := ''
      else
        lvExecuteTasks.Items[I].SubItems.Strings[2] := IntToStr(APercent);
      Break;
    end;
end;

// Просмотр логов выполненной задачи
procedure TFormMain.OpenTaskLog(ATaskID: string);
begin
  if lvCompleted.Selected <> nil then
  begin
    var Log := FTaskManager.GetTaskLog(ATaskID);
    if Log <> nil then
      ShowMessage(Log.Text);
  end;
end;

end.
