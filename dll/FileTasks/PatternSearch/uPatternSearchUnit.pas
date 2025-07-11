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

function FindPatternsInFile(const SenderTask: TPatternSearchTask;  Patterns: array of AnsiString; const FileName: string; ACallback: ITaskCallback; out OSearchResults: TArray<TSearchResult>): Boolean;

implementation

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
    Finalize(Buffer);
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
