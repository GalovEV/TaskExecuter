library FileTasks;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters.

  Important note about VCL usage: when this DLL will be implicitly
  loaded and this DLL uses TWicImage / TImageCollection created in
  any unit initialization section, then Vcl.WicImageInit must be
  included into your library's USES clause. }

uses
  System.SysUtils,
  System.Classes,
  uFileSearchTask in 'FileSearchTask\uFileSearchTask.pas',
  ufrmFileSearchConfig in 'FileSearchTask\ufrmFileSearchConfig.pas' {frmFileSearchConfig},
  uPatternSearchUnit in 'PatternSearch\uPatternSearchUnit.pas',
  uPatternSearchTask in 'PatternSearch\uPatternSearchTask.pas',
  uCommonInterface in '..\..\Shared\uCommonInterface.pas',
  uCommonTask in '..\..\Shared\uCommonTask.pas',
  uCommonType in '..\..\Shared\uCommonType.pas';

{$R *.res}

// Процедура регистрации задач
procedure RegisterTasks(Registry: ITaskRegistry); stdcall;
begin
  Registry.RegisterTask(TFileSearchTask.Create);
  Registry.RegisterTask(TPatternSearchTask.Create);
end;

exports
  RegisterTasks;

begin
end.
