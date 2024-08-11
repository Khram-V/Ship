{##################################################################}
{                                                                  }
{    You should write to the Free Software Foundation, Inc.,       }
{    59 Temple Place, Suite 330, Boston, MA 02111-1307 USA         }
{                                                                  }
{##################################################################}

unit FreeAboutDlg;

{$mode delphi}

interface

uses
  Forms,
  ExtCtrls,
  StdCtrls,
  Grids,
  FreeVersionUnit;

type

  { TFreeAboutDlg }

  TFreeAboutDlg = class( TForm )             // TFreeAboutDlg
    Button1: TButton;
    Label3: TLabel;
    LabelTitle: TLabel;
    Panel2,Panel4,Panel5: TPanel;
    StringGridVersionInfo: TStringGrid;
    procedure FormCreate(Sender: TObject);
  private
    procedure AddInfo(sName,sValue:String);
  end;

var
  FreeAboutDlg: TFreeAboutDlg;

implementation

{$R *.lfm}

{ TFreeAboutDlg }

procedure TFreeAboutDlg.AddInfo( sName, sValue:String );
begin with StringGridVersionInfo do begin RowCount:=RowCount + 1;
                                 Cells[ 0,RowCount-1 ]:=sName;
                                 Cells[ 1,RowCount-1 ]:=sValue; end;
end;

procedure TFreeAboutDlg.FormCreate(Sender: TObject);
begin
  AddInfo('FREE!ship version',FREESHIP_VERSION);
  AddInfo('Compiler version ',{$I %FPCVERSION%});
  AddInfo('Target CPU ',TARGET_CPU);
  AddInfo('Target OS  ',TARGET_OS);
  AddInfo('Build date ',ReleasedDate+' '+COMPILE_TIME);
  AddInfo('© 2005, Martijn van Engeland, DelftShip','Marine software developer, Netherlands' );
  AddInfo('© 2007-2012 Виктор Фёдорович Тимошенко','Николавский кораблестроительный институт' );
  AddInfo('© 2015 Mark Malakanov','FreePascal Lazarus, Woodbridge, Canada' );
  AddInfo('© 2024, НТО Крылова, о.Сахалин','‏יְרוּשָׁלַיִם' );
       //  © 2005, by Martijn van Engeland
       //  © 2007-2012, by Timoshenko Victor F., vftim@rambler.ru
       //  © 2015, by Mark Malakanov, markmal@github.com
end;

end.

