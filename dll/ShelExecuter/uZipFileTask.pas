unit uZipFileTask;

interface
uses  Classes, SysUtils, Generics.Collections, uCommonTask, uCommonInterface, uCommonType;

type

  TZipFileTask = class(TTaskImplementation)
  private
//    function GetFormResults(Form: TForm): TArray<TParamValue>;

  function CreateZipFile(AZipFileName: string; APathName: string; out OErrorString: string): Boolean;
  function RunCommandLineProc(ACommandLine: string; out OErrorString: string): Boolean;
  protected
  function DoExecute(const AParamValues: TArray<TParamValue>; ACallback: ITaskCallback): Boolean; override;

  public
     procedure AfterConstruction; override;

  end;
implementation

uses
 Controls, System.Types, System.Variants, WinApi.Windows, System.IOUtils;

{TZipFileTask}

procedure TZipFileTask.AfterConstruction;
begin
  inherited;
  FTaskID := 'ZipFile';
  FTaskName:= 'Архивация папки';

// Параметры: файл
  SetLength(FParams, 1);

  FParams[0].Name := 'Folder';
  FParams[0].Description := 'Выбор папки';
  FParams[0].ParamType := ptFolder;
  FParams[0].DefaultValue := '';

end;

function TZipFileTask.DoExecute(const AParamValues: TArray<TParamValue>;
  ACallback: ITaskCallback): Boolean;
var
  lPathName: string;
  lZipFileName: string;
  lErrorString: string;
  const
  cPathName= '..\..\Archive\';  //или как параметр добавить
begin
  FCanceled := False;

  // Проверка параметров
  if Length(AParamValues) < 1 then
    raise Exception.Create('Недостаточно параметров');

  //Папка для выгрузки
  lPathName := VarToStr(AParamValues[0]);
  if not TDirectory.Exists(lPathName) then
    raise Exception.CreateFmt('Директория не существует: %s', [lPathName]);

  lZipFileName:= '"' + cPathName + Copy(lPathName, LastDelimiter('\', lPathName) + 1, MaxInt) + '"';

  Result:= CreateZipFile(lZipFileName, '"' + lPathName + '"', lErrorString);

  if Result then
    begin
      FTaskResult:= Format('Архив %s', [lZipFileName]);
      ACallback.UpdateProgress('Архив завершен', 100, tsCompleted);
    end
     else
       raise Exception.Create(lErrorString);
end;

function TZipFileTask.CreateZipFile(AZipFileName: string; APathName: string; out OErrorString: string): Boolean;
var
 lArchiverFile: string;
 lCommandLine: string;
 const
  cZipFileName = 'result.zip';
  c7ZipPath = '..\..\7ZIP\7za.exe';
  c7ZipCommandLine = ' a -tzip %s %s ';

  function GetModuleName: string;
    var
      szFileName: array[0..MAX_PATH] of Char;
    begin
      FillChar(szFileName, SizeOf(szFileName), #0);
      GetModuleFileName(hInstance, szFileName, MAX_PATH);
      Result := szFileName;
    end;
begin
  Result := True;

  lArchiverFile := ExtractFilePath(GetModuleName) + c7ZipPath;

  if FileExists(lArchiverFile) then
  begin
    lCommandLine := lArchiverFile + Format(c7ZipCommandLine, [AZipFileName, APathName]);
    if not RunCommandLineProc(lCommandLine, OErrorString) then
      Exit(False)
  end
  else
  begin
    OErrorString := Format('7Zip Archiver not found (%s)', [lArchiverFile]);
    Exit(False)
  end;

end;

function TZipFileTask.RunCommandLineProc(ACommandLine: string;
  out OErrorString: string): Boolean;
var
  si: TStartupInfo;
  pi: TProcessInformation;
  i: Cardinal;
  buffer: TCharArray;

  const
   const7ZipError =  'Ошибка при запуске архиватора "7ZIP": ';
begin
  Result:= False;
 //Запуск процесса
 //Чтобы избежать ошибок доступа, необходимо скопировать строку в изменяемый буфер
  i := (Length(ACommandLine) + 1) * SizeOf(Char);
  SetLength(buffer, i);
  Move(ACommandLine[1], buffer[0], i);
  si := Default(TStartupInfo);
  si.cb := SizeOf(si);
  if not CreateProcess(nil, @buffer[0], nil, nil, False,
                                    CREATE_NO_WINDOW, nil, nil, si, pi) then
   begin
    OErrorString := const7ZipError + SysErrorMessage(GetLastError);
    exit;
  end;
  try
    while (WaitForSingleObject(pi.hProcess, 1000) <> WAIT_OBJECT_0) //and (not isCancel)
      do
        if isCancel then
          TerminateProcess(pi.hProcess, 255);

    if not GetExitCodeProcess(pi.hProcess, I) then
    begin
      OErrorString := SysErrorMessage(GetLastError);
      exit;
    end;

    case Integer(I) of
      0: Result := True;
      1: OErrorString := '7ZIP: Warning (Non fatal error(s)). For example, one or more files were locked by some other application, so they were not compressed.';
      2: OErrorString := '7ZIP: Fatal error.';
      7: OErrorString := '7ZIP: Ошибка формирования командной строки.';
      8: OErrorString := '7ZIP: Для выполнения операции недостаточно памяти.';
      255: OErrorString := '7ZIP: Процесс остановлен пользователем.';
    else
      OErrorString := Format('7ZIP: Неизвестная ошибка(код %s)', [IntToHex(integer(I), 2)]);
    end;

  finally
    CloseHandle(pi.hProcess);
  end;
end;

end.
