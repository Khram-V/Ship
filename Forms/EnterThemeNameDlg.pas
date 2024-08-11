unit EnterThemeNameDlg;

{$mode delphi}

interface

uses
  SysUtils,
  Forms, Controls, Dialogs, StdCtrls,  Buttons, ExtCtrls, Menus,
  FreeShipUnit;

type

  { TEnterThemeNameDlg }

  TEnterThemeNameDlg = class(TForm)
    BitBtn1: TSpeedButton;
    Panel1: TPanel;
    BitBtn2: TSpeedButton;
    EditCustomSchemeName: TEdit;
    Message: TLabel;
    procedure BitBtn2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  public
    { public declarations }
    function Execute:Boolean;
  end;

implementation

{$R *.lfm}

{ TEnterThemeNameDlg }

function TEnterThemeNameDlg.Execute:Boolean;
begin
   GlobalFreeship.Preferences.LoadImageIntoBitmap(BitBtn1.Glyph,'Ok');
   GlobalFreeship.Preferences.LoadImageIntoBitmap(BitBtn2.Glyph,'Cancel');      // ShowTranslatedValues(Self);
   Showmodal;
   Result:=ModalResult=mrOk;
end;

procedure TEnterThemeNameDlg.Button1Click(Sender: TObject);
begin Self.ModalResult := mrOK; end;

procedure TEnterThemeNameDlg.BitBtn2Click(Sender: TObject);
begin Self.ModalResult := mrCancel; end;

end.

