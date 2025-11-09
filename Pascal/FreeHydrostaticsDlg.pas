unit FreeHydrostaticsDlg;
interface uses
  Classes,   SysUtils,
  Forms,     Dialogs,
  StdCtrls,  ExtCtrls,
  Buttons,   FreeShipUnit, FreeLanguageSupport;
type                                                { TFreeHydrostaticsDialog }
  TFreeHydrostaticsDialog=class( TForm )
    Edit: TMemo;
    Panel1,Panel22: TPanel;
    ButtonClose,ButtonSave: TSpeedButton;
    SaveDialog: TSaveDialog;
    procedure ButtonCloseClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  end;

var FreeHydrostaticsDialog: TFreeHydrostaticsDialog;

implementation
{$R *.lfm}

procedure TFreeHydrostaticsDialog.ButtonCloseClick( Sender: TObject );
    begin Close; end;
procedure TFreeHydrostaticsDialog.ButtonSaveClick(Sender: TObject);
begin
  if SaveDialog.Execute then
    case SaveDialog.FilterIndex of                       // save as plain text
      1: Edit.Lines.SaveToFile( ChangeFileExt( SaveDialog.FileName,'.txt') );
    end;
end;
procedure TFreeHydrostaticsDialog.FormShow( Sender: TObject );
var I: integer; S: String;
begin
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Ship.FileName),'')+'.txt';
  I:=Edit.Lines.Count;
  S:=Edit.Lines.CommaText;                       // Place cursor at beginning
  Edit.CaretPos:=TPoint(Point(0,0));
  I:=Edit.Lines.Count;
  S:=Edit.Lines.CommaText;
  ShowTranslatedValues( Self );
end;

end.
