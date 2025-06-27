unit uCommonType;

interface
  type
  // ���� ���������� �����
  TParamType = (ptString, ptInteger, ptBoolean, ptFolder, ptFile);
  TParamValue = Variant;

 // �������� ��������� ������
  TTaskParam = record
    Name: string;
    Description: string;
    ParamType: TParamType;
    DefaultValue: TParamValue;
  end;

 // ������� ������
  TTaskStatus = (tsWaiting, tsRunning, tsCompleted, tsCanceled, tsError);
 const
  strStatusName: array [TTaskStatus] of string = ('��������',
    '��������', '���������', '��������', '������');

implementation

end.
