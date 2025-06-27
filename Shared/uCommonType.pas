unit uCommonType;

interface
  type
  // Типы параметров задач
  TParamType = (ptString, ptInteger, ptBoolean, ptFolder, ptFile);
  TParamValue = Variant;

 // Описание параметра задачи
  TTaskParam = record
    Name: string;
    Description: string;
    ParamType: TParamType;
    DefaultValue: TParamValue;
  end;

 // Статусы задачи
  TTaskStatus = (tsWaiting, tsRunning, tsCompleted, tsCanceled, tsError);
 const
  strStatusName: array [TTaskStatus] of string = ('Ожидание',
    'Запущена', 'Выполнена', 'Прервана', 'Ошибка');

implementation

end.
