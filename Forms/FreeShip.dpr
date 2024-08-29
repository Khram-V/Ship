
{ FREE!ship }

program FreeShip;

{$mode objfpc}{$H+}

uses
  Controls, Forms, Dialogs,
  SysUtils, Math, LazUTF8,                // this includes the LCL widgetset
  DefaultTranslator, Interfaces,
  Main                in '../Forms/Main.pas',                       {MainForm}
  FreeTypes           in '../Units/FreeTypes.pas',
  FreeLanguageSupport in '../Units/FreeLanguageSupport.pas',
  FreeVersionUnit     in '../Units/FreeVersionUnit.pas';

var ParametersHelp: boolean=false;
    sOpenFile : String='';
    sHelp : String;

procedure InitByParameters; var S: string; p: integer; begin
  for p:=1 to ParamCount do begin S:=ParamStr(p);
    if S = '--help' then ParametersHelp:=True else
    if ( lowerCase(UTF8RightStr( S,4 ) ) = '.ftm' )
    or ( lowerCase(UTF8RightStr( S,4 ) ) = '.fbm' ) then sOpenFile:=S;
  end;
end;

procedure PrintParametersHelp( Ans: Boolean );
  begin
  sHelp:= #10+'Usage: Free!Ship [parameter] [model]'
        + #10+ 'Where parameter is: --help = this screen'
        + #10+ '    model file: <Ship>.ftm or <Ship>.fbm'+#10
        + #10+ '«Free!Ship» in Pascal.'
        + #10+ 'Compiled at       '+ReleasedDate+' '+COMPILE_TIME
        + #10+ 'Compiler version: '+FPCVERSION
        + #10+ 'Target CPU:       '+TARGET_CPU
        + #10+ 'Target OS:        '+TARGET_OS
        + #10+ 'FreeShip version: '+FREESHIP_VERSION; // ResourceVersionInfo
    if Ans then ShowMessage( sHelp )
           else WriteLn( sHelp );
  end;

{$R *.res}

begin
  WestPoint;
  InitByParameters;
  PrintParametersHelp( false );
  RequireDerivedFormResource:=True;      // new

  Application.Initialize;

  if ParametersHelp then begin PrintParametersHelp( true ); exit; end;

  Application.CreateForm( TMainForm,MainForm );

//Application.CreateForm( TFreeCrosscurvesDialog,FreeCrosscurvesDialog );

  LoadLanguage( Mainform.Freeship.Preferences.Language,
                Mainform.Freeship.Preferences.LanguageFile );
  ShowTranslatedValues( Mainform );
  Mainform.FFileName:=sOpenFile;

  Application.OnActivate:=MainForm.OnActivate;

  try
  SetExceptionMask(                              // Enabling FPU exception mask
  [exInvalidOp,exDenormalized,exZeroDivide,exOverflow,exUnderflow,exPrecision]);

  Application.Run;

  except                   // Floating point operation
    on E: EMathError do;   //  ( 'General floating-point exception caught!' );
//  on E: EAccessViolation do;
//  on E: EIntError  do Writeln( 'General integer exception!' );
//  on E: EDivByZero do Writeln( 'Division by zero exception!' );
//  on E: EOverflow  do Writeln( 'Overflow exception!' );
//  on E: EUnderflow do Writeln( 'Underflow exception!' );
  end

end.

