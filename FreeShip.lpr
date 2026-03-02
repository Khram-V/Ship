program Ship;
uses Interfaces,Math,Forms,SysUtils,
  Main       in 'Pascal\Main.pas'       {MainForm},
  SplashWndw in 'Pascal\SplashWndw.pas' {SplashWindow},
  ShipUnit   in 'Pascal\ShipUnit.pas'   {ShipUnit},
  STypes     in 'Pascal\STypes.pas'     {STypes},
  LanguageSupport;                   // #226+#149+#169 + #10='╩'
{$R *.res}
begin
   WriteLn( 'FREEShip <числовая модель>.[ftm,fbm,fef]'+#10
       +#10+'Compiled: '+{$I %DATE%}+' '+{$I %TIME%}
       +#10+'CPU\OS: '+{$I %FPCTARGETCPU%}+' \ '+{$I %FPCTARGETOS%}
       +#10+'Pascal: '+{$I %FPCVERSION%}
       +#10+'@free!Ship v.2.6.2 { от 1.6? до 5 }'+#10 );
   Application.Initialize;
   SplashWindow:=TSplashWindow.Create( Application );
   SplashWindow.Show;
   SplashWindow.Refresh;
   WestPoint;
   Application.CreateForm( TMainForm,MainForm );
   LoadLanguage( St.Preferences.Language,
                 St.Preferences.LanguageFile );
   ShowTranslatedValues( Mainform );
try
  SetExceptionMask(                              // Enabling FPU exception mask
  [exInvalidOp,exDenormalized,exZeroDivide,exOverflow,exUnderflow,exPrecision]);
  Application.OnActivate:=MainForm.OnActivate;   // Sleep( 600 );
  Application.Run;
except                 // Floating point operation - сбои и ошибки игнорируются
    on E: EMathError do;      // ( 'General floating-point exception caught!' )
    on E: EAccessViolation do; // -- не знаю.., может быть так будет не хуже
{   on E: EIntError  do Writeln( 'General integer exception!' );
    on E: EDivByZero do Writeln( 'Division by zero exception!' );
    on E: EOverflow  do Writeln( 'Overflow exception!' );
    on E: EUnderflow do Writeln( 'Underflow exception!' ); }
end

end.

