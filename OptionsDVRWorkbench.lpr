Program OptionsDVRWorkbench;

{$mode objfpc}{$H+}

Uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  FormOptionsDVRWorkbench { you can add units after this };

  {$R *.res}

Begin
  RequireDerivedFormResource := True;
  Application.Scaled:=True;
  {$PUSH}
  {$WARN 5044 OFF}
  Application.MainFormOnTaskbar := True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TfrmOptionsDVRWorkbench, frmOptionsDVRWorkbench);
  Application.Run;
End.
