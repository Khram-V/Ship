program FreeShip;                                                 { FREE!ship }
{$mode objfpc}{$H+}
uses Controls, Forms, Dialogs,
     SysUtils, Math, LazUTF8,                 // this includes the LCL widgetset
     DefaultTranslator, Interfaces,
     Main                  in 'Main.pas',                           {MainForm}
     FreeTypes             in '../Units/FreeTypes.pas',
     FreeVersionUnit       in '../Units/FreeVersionUnit.pas',
     FreeLanguageSupport   in '../Units/FreeLanguageSupport.pas';
 var ParametersHelp: boolean=false;
     sOpenFile: AnsiString='';
     sHelp: AnsiString;

procedure InitByParameters; var S: AnsiString; p: integer; begin
  for p:=1 to ParamCount do begin S:=ParamStr(p);
    if S='--help' then ParametersHelp:=True else
    if ( lowerCase(UTF8RightStr( S,4 ))='.ftm' )
    or ( lowerCase(UTF8RightStr( S,4 ))='.fbm' ) then sOpenFile:=S;
  end;
end;
procedure PrintParametersHelp( Ans: Boolean ); begin
  sHelp:=#10+'Usage: Free!Ship [parameter] [model]'
        +#10+'Where parameter is: --help = this screen'
        +#10+'    model file: <Ship>.ftm or <Ship>.fbm'+#10
        +#10+'«Free!Ship» in Pascal.'
        +#10+'Compiled at '+ ReleasedDate+' '+COMPILE_TIME
        +#10+'Compiler version: '+ FPCVERSION
        +#10+'Target CPU:       '+ TARGET_CPU
        +#10+'Target OS:        '+ TARGET_OS
        +#10+'Free!Ship version: '+ FREESHIP_VERSION
        +' для ['+VersionString(low(TFreeFileVersion))+'..5.0]';
  if Ans then ShowMessage( sHelp )                       // ResourceVersionInfo
         else WriteLn( sHelp );
end;
{$R *.res}
begin
  WestPoint;
  InitByParameters;
  PrintParametersHelp( false );
  RequireDerivedFormResource:=True;                                      // new
  Application.Initialize;
  if ParametersHelp then begin PrintParametersHelp( True ); exit; end;
  Application.CreateForm( TMainForm,MainForm );
//Application.CreateForm( TFreeCrosscurvesDialog,FreeCrosscurvesDialog );
  LoadLanguage( Mainform.Freeship.Preferences.Language,
                Mainform.Freeship.Preferences.LanguageFile );
  ShowTranslatedValues( Mainform );
  Mainform.FFileName:=sOpenFile;
try
  SetExceptionMask(                              // Enabling FPU exception mask
  [exInvalidOp,exDenormalized,exZeroDivide,exOverflow,exUnderflow,exPrecision]);
  Application.OnActivate:=MainForm.OnActivate;
  Application.Run;
except                 // Floating point operation - сбои и ошибки игнорируются
    on E: EMathError do;      // ( 'General floating-point exception caught!' )
    on E: EAccessViolation do;    // -- не знаю.., может быть так будут не хуже
//  on E: EIntError  do Writeln( 'General integer exception!' );
//  on E: EDivByZero do Writeln( 'Division by zero exception!' );
//  on E: EOverflow  do Writeln( 'Overflow exception!' );
//  on E: EUnderflow do Writeln( 'Underflow exception!' );
end
end.

