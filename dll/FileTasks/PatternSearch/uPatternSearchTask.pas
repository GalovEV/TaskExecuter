unit uPatternSearchTask;

interface
uses  Classes, SysUtils, Generics.Collections, uCommonTask, uCommonInterface, uCommonType;

type

  TPatternSearchTask = class(TTaskImplementation)
  private

//    function GetFormResults(Form: TForm): TArray<TParamValue>;
  protected
  function DoExecute(const AParamValues: TArray<TParamValue>; ACallback: ITaskCallback): Boolean; override;

  public
     procedure AfterConstruction; override;

  end;
implementation

uses
 Controls, System.Types, System.IOUtils, System.Variants, uPatternSearchUnit;

{TPatternSearchTask}

procedure TPatternSearchTask.AfterConstruction;
begin
  inherited;
  FTaskID := 'PatternSearch';
  FTaskName:= '����� ��������� ������������������� � �����';

// ���������: ����
  SetLength(FParams, 3);

  FParams[0].Name := 'Pattern';
  FParams[0].Description := '������� ������';
  FParams[0].ParamType := ptString;
  FParams[0].DefaultValue := 'libsec';

  FParams[1].Name := 'Pattern';
  FParams[1].Description := '������� ������';
  FParams[1].ParamType := ptString;
  FParams[1].DefaultValue := 'binsec';

  FParams[2].Name := 'File';
  FParams[2].Description := '����� �����';
  FParams[2].ParamType := ptFile;
  FParams[2].DefaultValue := '';

end;

function TPatternSearchTask.DoExecute(const AParamValues: TArray<TParamValue>;
  ACallback: ITaskCallback): Boolean;
var
  lFileName: string;
  Patterns: array of AnsiString;
  lSearchResults: TArray<TSearchResult>;

  function GetPattarnPositions(APositions: TArray<Int64>): string;
  begin
     for var Pos in APositions do
      Result:= Result + ' ' + IntToStr(Pos);
  end;
begin
  Result := True;
  FCanceled := False;

  // �������� ����������
  if Length(AParamValues) < 3 then
    raise Exception.Create('������������ ����������');

  lFileName := VarToStr(AParamValues[High(AParamValues)]);

  if not FileExists(lFileName) then
    raise Exception.CreateFmt('���� �� ����������: %s', [lFileName]);

  SetLength(Patterns, Length(AParamValues) - 1);
  for var I := 0 to High(Patterns) do
    Patterns[I]:= AnsiString(AParamValues[I]);

  // ����� ��������� �  �����
  ACallback.LogMessage(Format('������ ������ � ����� %s', [lFileName]));

//  if not SearchPatternsInFile(Self, Patterns, lFileName, ACallback, lSearchResults) then
  if not FindPatternsInFile(Self, Patterns, lFileName, ACallback, lSearchResults) then
    Exit(False);

//  if FCanceled then Exit(False);

  FTaskResult:= '';
  for var Res in lSearchResults do
  begin
    FTaskResult:= FTaskResult + Format('Pattern: %s. Count: %d. Positions: %s' ,
    [Res.Pattern, Res.Count, GetPattarnPositions(Res.Positions)]);

    FTaskResult:= FTaskResult + #13;
  end;
  ACallback.UpdateProgress('����� ��������', 100, tsCompleted);
  Sleep(300);

end;

end.
