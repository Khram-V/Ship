unit FreeSplashWndw;
{ Открытое(свободное) обеспечение корабельной гидромеханики
   You should write to the Free Software Foundation,Inc.,
    59 Temple Place,Suite 330,Boston,MA 02111-1307 USA
}
interface uses Forms,ExtCtrls,StdCtrls;
type
  TFreeSplashWindow = class( TForm )
    Timer: TTimer;
    Panel4: TPanel;
    Button1: TButton;
    LabelC,LabelTitle: TLabel;
    procedure TimerTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Image1Click(Sender: TObject);
  private
    FCounter: integer;
  end;

var FreeSplashWindow: TFreeSplashWindow;

implementation
{$R *.lfm}

procedure TFreeSplashWindow.TimerTimer( Sender: TObject );
    begin inc(FCounter,Timer.Interval); if FCounter>1000 then Close; end;
procedure TFreeSplashWindow.FormClose(Sender: TObject;var Action: TCloseAction);
    begin Timer.Enabled:=False; Release; end;
procedure TFreeSplashWindow.Image1Click(Sender: TObject);
    begin Timer.Enabled:=False; Close; end;
procedure TFreeSplashWindow.FormShow( Sender: TObject );
begin
  LabelC.Caption:=#9+#9+#9+'«·Сахалин·»'
   +#10+'Compiler version: '+#9+{$I %FPCVERSION%}
   +#10+'Target OS/CPU: '+#9+#9+{$I %FPCTARGETOS%}+' / '+{$I %FPCTARGETCPU%}
   +#10+'Build date:    '+#9+#9+{$I %DATE%}+' '+{$I %TIME%}
   +#10+'License: '+#9+#9+#9+'GPL v2+'
   +#10+'© 2005, Martijn van Engeland, DelftShip: Marine software developer, Netherlands'
   +#10+'© 2024… НТО Крылова, о.Сахалин: Штормовая мореходность корабля, ‏יְרוּשָׁלַיִם';
  FCounter:=0;
  Timer.Enabled:=True;
end;

end.

