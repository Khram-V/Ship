unit SplashWndw;
{  Открытое(свободное) обеспечение корабельной гидромеханики, остров Сахалин.
     You should write to the  Software Foundation,Inc.,
       59 Temple Place,Suite 330,Boston,MA 02111-1307 USA
}
interface uses Forms,ExtCtrls,StdCtrls; //, LCLIntf -- интернет ссылки;
type
  TSplashWindow = class( TForm )
    Timer: TTimer;
    LabelC,LabelTitle: TLabel;
    procedure TimerTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  end;
var SplashWindow: TSplashWindow;
    FCounter: Integer=100;

implementation
{$R *.lfm}
procedure TSplashWindow.TimerTimer( Sender: TObject );
    begin dec( FCounter,Timer.Interval );
            if FCounter<=0 then begin FCounter:=3000; Close end;
    end;
procedure TSplashWindow.FormClose(Sender: TObject;var Action: TCloseAction);
    begin Timer.Enabled:=False; Release; end;
procedure TSplashWindow.FormShow( Sender: TObject );
begin LabelC.Caption:=#9+#9+#9+'«·Сахалин·»'
 +#10+'Compiler version: '+#9+{$I %FPCVERSION%}
 +#10+'Target OS/CPU: '+#9+#9+{$I %FPCTARGETOS%}+' / '+{$I %FPCTARGETCPU%}
 +#10+'Build date:    '+#9+#9+{$I %DATE%}+' '+{$I %TIME%}
 +#10+'License: '+#9+#9+#9+'GPL v2+      (www.ShipDesign.ru/SoftWare/Aurora.z)'
 +#10+'© 2005, Martijn van Engeland, DelftShip: Marine software developer, Netherlands'
 +#10+'© 2024… НТО Крылова, о.Сахалин: Штормовая мореходность корабля, ‏יְרוּשָׁלַיִם';
  Timer.Enabled:=True;
end;

end.

