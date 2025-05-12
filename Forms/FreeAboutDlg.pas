unit FreeAboutDlg;
{$mode delphi}{$H+}
     {———————————————————————————————————————————————————————————}
     { Открытое(свободное) обеспечение корабельной гидромеханики }
     { You should write to the Free Software Foundation, Inc.,   }
     { 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA     }
     {———————————————————————————————————————————————————————————}
interface uses Forms, ExtCtrls, StdCtrls, Grids, FreeVersionUnit;
type
  TFreeAboutDlg = class( TForm )
    Button1:TButton;
    Label3,LabelTitle: TLabel;
    Panel2,Panel4,Panel5: TPanel;
    StringGridVersionInfo: TStringGrid;
    procedure FormCreate(Sender: TObject);
  private
    procedure AddInfo( sName,sValue: AnsiString );
  end;

var FreeAboutDlg: TFreeAboutDlg;

implementation
{$R *.lfm}

procedure TFreeAboutDlg.AddInfo( sName, sValue:AnsiString );
begin with StringGridVersionInfo do begin RowCount:=RowCount+1;
                                 Cells[ 0,RowCount-1 ]:=sName;
                                 Cells[ 1,RowCount-1 ]:=sValue; end;
end;

procedure TFreeAboutDlg.FormCreate( Sender: TObject ); begin
  AddInfo('FREE!ship version',FREESHIP_VERSION );
  AddInfo('Compiler version ',FPCVERSION ); //{$I %FPCVERSION%});
  AddInfo('Target CPU ',      TARGET_CPU );
  AddInfo('Target OS  ',      TARGET_OS );
  AddInfo('Build date ',ReleasedDate+' '+COMPILE_TIME );
  AddInfo('© 2005, Martijn van Engeland, DelftShip','Marine software developer, Netherlands' );
  AddInfo('© 2007÷12 Виктор Фёдорович Тимошенко','Николаевский кораблестроительный институт' );
  AddInfo('© 2015 Mark Malakanov','FreePascal Lazarus, Woodbridge, Canada' );
  AddInfo('© 2024… НТО Крылова, о.Сахалин','Штормовая мореходность,          ‏יְרוּשָׁלַיִם' );
       //  Timoshenko Victor F., vftim@rambler.ru
       //  Mark Malakanov, markmal@github.com
end;

end.

