program FreeShip;                                                 { FREE!ship }
{$mode objfpc}{$H+}
uses Controls, Forms, Dialogs, //Windows,     // System,
     SysUtils, Math, LazUTF8,                // this includes the LCL widgetset
     DefaultTranslator, Interfaces,
     Main                in 'Main.pas',                              {MainForm}
     FreeTypes           in '../Units/FreeTypes.pas',
     FreeVersionUnit     in '../Units/FreeVersionUnit.pas',
     FreeLanguageSupport in '../Units/FreeLanguageSupport.pas';
 var ParametersHelp: boolean=false;
     sOpenFile: AnsiString='';                                  // UTF8ToWinCP(

procedure InitByParameters; var S: AnsiString; p: integer; begin
  for p:=1 to ParamCount do begin S:=ParamStr( p );
    if S='--help' then ParametersHelp:=True else
    if ( lowerCase( RightStr( S,4 ) )='.ftm' )
    or ( lowerCase( RightStr( S,4 ) )='.fbm' )
    or ( lowerCase( RightStr( S,4 ) )='.fef' ) then sOpenFile:=S;      //? UTF8
  end;
end;
procedure PrintParametersHelp( Ans: Boolean ); var sHelp: AnsiString;
begin
  sHelp:='Usage: Free!Ship [parameter] [model]'   // #226+#149+#169 + #10 = '╩'
    +#10+'Where parameter is: --help = this screen'
    +#10+'     digital model: <Ship>.[ftm,fbm,fef]'+#10
    +#10+'«Free!Ship» in Free Pascal.'
    +#10+'Compiled at '+ReleasedDate+' '+COMPILE_TIME
    +#10+'Compiler version: ' + FPCVERSION
    +#10+'Target CPU:       ' + TARGET_CPU
    +#10+'Target OS:        ' + TARGET_OS
    +#10+'Free!Ship version: '+ FREESHIP_VERSION
        +' для ['+VersionString( low( TFreeFileVersion ) )+'..5.0]';
  if Ans then ShowMessage( sHelp )                    // ResourceVersionInfo
         else WriteLn( sHelp );                       // UTF8ToConsole( sHelp )
end;
{$R *.res}
begin // SetConsoleOutputCP( CP_UTF8 ); SetConsoleCP( CP_UTF8 ); //==65001
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

{ Function Experience( Kod: Integer ): Integer; cdecl; external;
  WriteLn( 'Experience in C=3+3='+inttostr( Experience( 3 ) ) );
}
