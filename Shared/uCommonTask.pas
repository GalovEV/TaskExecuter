unit uCommonTask;

interface
uses
  Classes, SysUtils, Generics.Collections, uCommonInterface, uCommonType, Vcl.Forms;

 type
  // Класс задачи
   TTaskImplementation = class(TInterfacedObject, ITask)
   private

   protected
    FTaskID: string;
    FTaskName: string;
    FParams: TArray<TTaskParam>;
    FCanceled: Boolean;
    FTaskResult: string;
   // ITask
   protected
    function GetTaskID: string;
    function GetTaskName: string;
    function GetParams: TArray<TTaskParam>;
    function GetResult: string;
    function Execute(const AParamValues: TArray<TParamValue>; ACallback: ITaskCallback): TExecuteResult;
    procedure Cancel;
   // ITaskWithConfig
   protected

   protected
    function DoExecute(const AParamValues: TArray<TParamValue>; ACallback: ITaskCallback): Boolean; virtual; abstract;
  public
   property isCancel: Boolean read FCanceled;
  end;

 //Вызов формы парамтеров
  TTaskConfigWrapper = class(TInterfacedObject, ITaskConfigForm)
  private
  protected
    FOwner: TComponent;
    function ShowConfig(var VExecuteParam: TArray<TParamValue>): TExecuteResult;

  protected
  function ShowConfigForm(var VExecuteParam: TArray<TParamValue>): Boolean; virtual; abstract;
  public
    constructor Create(AOwner: TComponent);
//    destructor Destroy; override;
  end;

implementation
uses
     IOUtils;

{ TTaskImplementation }

procedure TTaskImplementation.Cancel;
begin
//critsec
  FCanceled := True;
end;

function TTaskImplementation.Execute(const AParamValues: TArray<TParamValue>;
                  ACallback: ITaskCallback): TExecuteResult;
begin
  FCanceled := False;
  Result := erAbortUser;
  try
    if DoExecute(AParamValues, ACallback) then
      Result := erOk;
  except
//    on E: TBreakException do
//      begin
//        ACallback.UpdateProgress(E.Message, 100);
//        Result := erAbortUser;
//      end;
    on E: Exception do
      begin
        ACallback.UpdateProgress(E.ClassName + ': ' + E.Message, 100, tsError);
        ACallback.LogMessage(E.ClassName + ': ' + E.Message);
        Result := erError
      end
  end;
end;

function TTaskImplementation.GetParams: TArray<TTaskParam>;
begin
  Result := FParams;
end;

function TTaskImplementation.GetResult: string;
begin
  Result :=  FTaskResult;
end;

function TTaskImplementation.GetTaskID: string;
begin
  Result := FTaskID;
end;

function TTaskImplementation.GetTaskName: string;
begin
  Result := FTaskName;
end;

{ TBreakException }

//constructor TBreakException.Create;
//begin
//  inherited Create(cnstBreakTask);
//end;

{TTaskConfigWrapper}
constructor TTaskConfigWrapper.Create(AOwner: TComponent);
begin
  FOwner:= AOwner;
end;
//
function TTaskConfigWrapper.ShowConfig(
  var VExecuteParam: TArray<TParamValue>): TExecuteResult;
begin
   // вызываем форму парамтеров
  Result := erAbortUser;
  if ShowConfigForm(VExecuteParam) then
    begin
      Result := erOK;
    end;
end;

end.
