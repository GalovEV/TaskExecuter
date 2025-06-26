program TaskExecuter;

uses
  Vcl.Forms,
  uFormMain in 'uFormMain.pas' {FormMain},
  uCommonInterface in 'Shared\uCommonInterface.pas',
  uTaskManager in 'uTaskManager.pas',
  uCommonType in 'Shared\uCommonType.pas',
  ufmParamForm in 'ufmParamForm.pas' {fmParamForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);

  Application.Run;
end.
