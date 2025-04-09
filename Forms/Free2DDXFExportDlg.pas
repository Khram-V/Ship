unit Free2DDXFExportDlg;
{$MODE Delphi}{$H+}
interface uses
  SysUtils, Forms,
  Controls, Dialogs,
  StdCtrls, Buttons,
  ExtCtrls, Spin,
  LazFileUtils, FreeLanguageSupport;
type                                                     { TDXFExport2DDialog }

  TDXFExport2DDialog = class(TForm)
    cbCreateIndividualFiles: TCheckBox;
    cbCreateIndividualLayers: TCheckBox;
    ComboBox1: TComboBox;
    Edit1: TFloatSpinEdit;
    Edit3: TEdit;
    Label1,Label4,Label7: TLabel;
    Panel1,Panel3,Panel4: TPanel;
    SaveDialog: TSaveDialog;
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    SpeedButton1: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
  private                                              { Private declarations }
    function FGetExportDirectory: AnsiString;
    procedure FSetExportDirectory(val: AnsiString);
    function FGetSegmentLength: double;
    procedure FSetSegmentLength(val: double);
    procedure FSetUnits;
  public                                                { Public declarations }
    function BrowseForFolder
    ( const browseTitle: PAnsiChar; initialFolder: AnsiString = ''): AnsiString;
    function Execute: boolean;
    property ExportDirectory: AnsiString read FGetExportDirectory write FSetExportDirectory;
    property SegmentLength: double read FGetSegmentLength write FSetSegmentLength;
  end;

var DXFExport2DDialog: TDXFExport2DDialog;

implementation
  {$R *.lfm}

function TDXFExport2DDialog.BrowseForFolder
( const browseTitle: PAnsiChar;
  initialFolder: AnsiString='' ): AnsiString;
var dlg: TSelectDirectoryDialog;
begin
  dlg:=TSelectDirectoryDialog.Create(Self);
  dlg.Title:=browseTitle;
  dlg.InitialDir:=initialFolder;
  if dlg.Execute then Result:=dlg.FileName else Result:='';
end;

function TDXFExport2DDialog.FGetExportDirectory: AnsiString;
   begin Result:=Edit3.Text; end;
procedure TDXFExport2DDialog.FSetExportDirectory( val: AnsiString );
    begin Edit3.Text:=Val; end;
function TDXFExport2DDialog.FGetSegmentLength: double;
   begin Result:=Edit1.Value; end;
procedure TDXFExport2DDialog.FSetSegmentLength(val: double);
    begin if Val < 1e-5 then Val:=1e-5; Edit1.Value:=Val; end;
procedure TDXFExport2DDialog.FSetUnits;
var Str: AnsiString;
begin Str:=ComboBox1.Text+' ';  //Label3.Caption:=Str;
end;

function TDXFExport2DDialog.Execute: boolean;
begin
  FSetUnits;
  ShowTranslatedValues(Self); Showmodal;
  Result:=ModalResult = mrOk;
end;

procedure TDXFExport2DDialog.SpeedButton1Click( Sender: TObject );
var Tmp: AnsiString;
begin
  Tmp:=BrowseForFolder( 'Choose a directory where you want to save the dxf files to: ', ExportDirectory);
  if DirectoryExistsUTF8(Tmp) then self.ExportDirectory:=Tmp; { *Converted from DirectoryExists* }
end;
procedure TDXFExport2DDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TDXFExport2DDialog.BitBtn2Click(Sender: TObject);
    begin ModalResult:=mrCancel; end;
procedure TDXFExport2DDialog.ComboBox1Change(Sender: TObject);
    begin FSetUnits; end;

end.
