unit uPatternSearchUnit;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, System.Generics.Collections,
  uCommonInterface, uCommonType, uPatternSearchTask;

type
  TSearchResult = record
    Pattern: string;
    Count: Integer;
    Positions: TArray<Int64>;
  end;

function SearchPatternsInFile(const SenderTask: TPatternSearchTask; Patterns: array of string; const FileName: string; ACallback: ITaskCallback; out OSearchResults: TArray<TSearchResult>): Boolean;
function FindPatternsInFile(const SenderTask: TPatternSearchTask;  Patterns: array of AnsiString; const FileName: string; ACallback: ITaskCallback; out OSearchResults: TArray<TSearchResult>): Boolean;


implementation

type
  TBMHTable = array[Byte] of Integer;

function BuildBMHTable(const Pattern: AnsiString): TBMHTable;
var
  I: Integer;
  Len: Integer;
begin
  Len := Length(Pattern);
  // Инициализируем таблицу длиной шаблона
  for I := 0 to High(Result) do
    Result[I] := Len;

  // Заполняем таблицу смещениями
  for I := 1 to Len - 1 do
    Result[Byte(Pattern[I])] := Len - I;
end;

function FindAllOccurrencesBMH(const SenderTask: TPatternSearchTask; Data: PByte; Size: Int64; Pattern: AnsiString; ACallback: ITaskCallback; out OPositions: TArray<Int64>): Boolean;
var
  Table: TBMHTable;
  PatternLen: Integer;
  DataLen: Int64;
  I, J: Int64;
  LastByte: Byte;
  Positions: TList<Int64>;
  lPercent: Integer;
begin
  Result:= True;
  OPositions := nil;
  PatternLen := Length(Pattern);
  if (PatternLen = 0) or (Size < PatternLen) then
    Exit;

  // Строим таблицу смещений
  Table := BuildBMHTable(Pattern);
  DataLen := Size;
  Positions := TList<Int64>.Create;
  try
    I := PatternLen - 1;
    lPercent:= 0;
    while I < DataLen do
    begin
     if lPercent < Round(I/DataLen * 100) then
      begin
        lPercent:= Round(I/DataLen * 100);
        ACallback.UpdateProgress('',
           Round(lPercent),
           tsRunning
          );
      end;
      J := PatternLen - 1;
      // Сравниваем с конца шаблона
      while (J >= 0) and (PByte(Data + I)^ = Byte(Pattern[J + 1]) ) do
      begin
        Dec(I);
        Dec(J);
      end;
      //проверка отмены задачи
      if SenderTask.isCancel then
        Exit(False);
      // Совпадение найдено
      if J < 0 then
      begin
        Positions.Add(I + 1);
        Inc(I, PatternLen + 1);
      end
      else
      begin
        // Используем таблицу для смещения
        LastByte := PByte(Data + I)^;
        Inc(I, Table[LastByte]);
      end;
    end;
    OPositions := Positions.ToArray;
  finally
    Positions.Free;
  end;
end;

function SearchPatternsInFile(const SenderTask: TPatternSearchTask; Patterns: array of string; const FileName: string; ACallback: ITaskCallback; out OSearchResults: TArray<TSearchResult>): Boolean;
var
  hFile: THandle;
  hMapping: THandle;
  pData: Pointer;
  FileSize: Int64;
  I: Integer;
  AnsiPattern: AnsiString;
  FileInfo: TWin32FileAttributeData;
begin
  Result:= True;
  SetLength(OSearchResults, Length(Patterns));

  // Проверка существования файла
  if not GetFileAttributesEx(PChar(FileName), GetFileExInfoStandard, @FileInfo) then
    raise Exception.Create('File not found: ' + FileName);

  // Проверка размера файла
  FileSize := Int64(FileInfo.nFileSizeLow) or (Int64(FileInfo.nFileSizeHigh) shl 32);
  if FileSize = 0 then
    Exit;

  // Открываем файл
  hFile := CreateFile(
    PChar(FileName),
    GENERIC_READ,
    FILE_SHARE_READ,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
  );
  if hFile = INVALID_HANDLE_VALUE then
    RaiseLastOSError;

  try
    // Создаем файловый mapping
    hMapping := CreateFileMapping(
      hFile,
      nil,
      PAGE_READONLY,
      0,
      0,
      nil
    );
    if hMapping = 0 then
      RaiseLastOSError;

    try
      // Отображаем файл в память
      pData := MapViewOfFile(
        hMapping,
        FILE_MAP_READ,
        0,
        0,
        0
      );
      if not Assigned(pData) then
        RaiseLastOSError;

      try
       var  Total, Current: Integer;
       Total := Length(Patterns);
       Current := 0;
        // Обрабатываем каждый шаблон
        for I := 0 to High(Patterns) do
        begin
          Inc(Current);

          ACallback.LogMessage(Format('Начало поиска "%s"', [Patterns[I]]));

          ACallback.UpdateProgress(
           Format('Поиск "%s": %d/%d', [Patterns[I], Current, Total]),
           Round(Current / Total * 100),
           tsRunning
          );

          OSearchResults[I].Pattern := Patterns[I];
          OSearchResults[I].Count := 0;
          OSearchResults[I].Positions := nil;

          // Конвертируем в Ansi для бинарного поиска
          AnsiPattern := AnsiString(Patterns[I]);
          if AnsiPattern = '' then
            Continue;
         //проверка отмены задачи
          if SenderTask.isCancel then
            Exit(False);
          // Ищем вхождения
          if not FindAllOccurrencesBMH(SenderTask, pData, FileSize, AnsiPattern, ACallback, OSearchResults[I].Positions) then
            Exit(False) ;
          OSearchResults[I].Count := Length(OSearchResults[I].Positions);

          ACallback.UpdateProgress(
           Format('Поиск "%s" завершен. Количество: %d', [Patterns[I], OSearchResults[I].Count]),
           Round(Current / Total * 100),
           tsRunning
          );
          ACallback.LogMessage(Format('Поиск "%s" завершен. Количество: %d', [Patterns[I], OSearchResults[I].Count]));

        end;
      finally
        UnmapViewOfFile(pData);
      end;
    finally
      CloseHandle(hMapping);
    end;
  finally
    CloseHandle(hFile);
  end;
end;


function FindPatternsInFile(const SenderTask: TPatternSearchTask;  Patterns: array of AnsiString; const FileName: string; ACallback: ITaskCallback; out OSearchResults: TArray<TSearchResult>): Boolean;
const
  DEFAULT_BLOCK_SIZE = 65536; // 64 KB
var
  BlockSize, maxLen, minLen: Integer;
  j, L: Integer;
  s: AnsiString;
  Buffer: TBytes;
  Stream: TFileStream;
  StartFilePos: Int64;
  TotalBytesInBuffer, BytesRead: Integer;
  i: Integer;
  lPercent: Integer;
  Results: array of TList<Int64>;
begin
  Result:= True;
  // Проверка на пустые шаблоны
  if Length(Patterns) = 0 then
    Exit(False);

  // Вычисление максимальной и минимальной длины шаблонов
  maxLen := 0;
  minLen := MaxInt;
  for s in Patterns do
  begin
    L := Length(s);
    if L > maxLen then
      maxLen := L;
    if (L > 0) and (L < minLen) then
      minLen := L;
  end;

  // Проверка наличия непустых шаблонов
  if (maxLen = 0) or (minLen = MaxInt) then
    Exit(False);

  // Инициализация списков результатов
  SetLength(Results, Length(Patterns));
  for j := 0 to High(Patterns) do
    Results[j] := TList<Int64>.Create;

  // Настройка размера блока чтения
  BlockSize := DEFAULT_BLOCK_SIZE;
  if maxLen > BlockSize then
    BlockSize := maxLen * 4;

  // Выделение буфера с учётом перекрытия
  SetLength(Buffer, BlockSize + maxLen - 1);

  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    StartFilePos := 0;
    // Чтение первого блока
    TotalBytesInBuffer := Stream.Read(Buffer[0], BlockSize);

    lPercent:= 0;
    while TotalBytesInBuffer >= minLen do
    begin
      //проверка отмены задачи
      if SenderTask.isCancel then
         Exit(False);
      // Поиск в текущем блоке
      for i := 0 to TotalBytesInBuffer - minLen do
      begin
        for j := 0 to High(Patterns) do
        begin
          L := Length(Patterns[j]);
          if (L > 0) and (i + L <= TotalBytesInBuffer) then
          begin
            if CompareMem(@Buffer[i], PAnsiChar(Patterns[j]), L) then
              Results[j].Add(StartFilePos + i);
          end;
        end;
      end;

      // Проверка на последний блок
      if TotalBytesInBuffer < BlockSize then
        Break;

      // Копирование перекрытия для следующего блока
      if maxLen > 1 then
        Move(Buffer[TotalBytesInBuffer - (maxLen - 1)], Buffer[0], maxLen - 1);

      // Обновление позиции в файле
      StartFilePos := StartFilePos + TotalBytesInBuffer - (maxLen - 1);

      if lPercent< (Round(StartFilePos/Stream.Size * 100)) then
       begin
        ACallback.UpdateProgress(
           'Поиск ',
           Round(lPercent),
           tsRunning
          );
         lPercent:= Round(StartFilePos/Stream.Size * 100);
//         Sleep(300);
       end;

      // Чтение следующего блока
      BytesRead := Stream.Read(Buffer[maxLen - 1], BlockSize);
      TotalBytesInBuffer := maxLen - 1 + BytesRead;

      if BytesRead = 0 then
        Break;
    end;
  finally
    Stream.Free;
  end;

  // Формирование результата
  SetLength(OSearchResults, Length(Patterns));
  for j := 0 to High(Patterns) do
  begin
    OSearchResults[j].Pattern := string(Patterns[j]);
    OSearchResults[j].Positions := Results[j].ToArray;
    OSearchResults[j].Count:= Length(Results[j].ToArray);
    Results[j].Free;
    ACallback.LogMessage(Format('Поиск "%s" завершен. Количество: %d', [Patterns[j], OSearchResults[j].Count]));
  end;
end;


end.
