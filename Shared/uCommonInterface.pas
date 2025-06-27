unit uCommonInterface;



interface
uses
  Classes, SysUtils, Generics.Collections, uCommonType;

  type
  TExecuteResult = (erOk, erError, erAbortUser);
  // ��������� ��� �������� �����
  ITaskCallback = interface
  ['{BEA9D46A-FA94-4BFA-B250-9F3139FA7CEA}']
    procedure UpdateProgress(const  AMessage: string; APercent: Integer; ATaskStatus: TTaskStatus);
    procedure LogMessage(const AMessage: string);
    procedure TaskCompleted(const ATaskID: string);
//    procedure UpdateStatus(AStatus:TTaskStatus);
  end;

// ��������� ������
  ITask = interface
   ['{CB177FC4-0234-4F2A-80C4-5D15D30177DE}']
    function GetTaskID: string;
    function GetTaskName: string;
    function GetResult: string;
    function GetParams: TArray<TTaskParam>;
    function Execute(const AParamValues: TArray<TParamValue>; ACallback: ITaskCallback): TExecuteResult;
    procedure Cancel;
    property TaskID: string read GetTaskID;
  end;

// ��������� ��� ����������� �����
  ITaskRegistry = interface
    ['{C3BAA465-AB02-445B-A8EC-6C6E5A66D191}']
    procedure RegisterTask(ATask: ITask);
  end;
  //���������� ��� ����� ����� ���������� ������ � �������
  ITaskConfigForm = interface
  ['{2055D146-A013-42D8-AA40-04CA4807AC32}']
    function ShowConfig(var VExecuteParam: TArray<TParamValue>): TExecuteResult;
  end;
  //��������� ��� ������ � ������ ����������
  ITaskWithConfig = interface
   ['{20ABD202-4254-47DF-866E-B5C860E74AFC}']
    function CreateConfigForm(AOwner: TComponent): ITaskConfigForm;
  end;

  // ������� ����������� ������ � DLL
  TRegisterTasksProc = procedure(ARegistry: ITaskRegistry); stdcall;

//  TBreakException = class(Exception)
//  strict private const
//    cnstBreakTask = '������ ��������';
//  public
//    constructor Create; reintroduce;
//  end;

implementation

end.
