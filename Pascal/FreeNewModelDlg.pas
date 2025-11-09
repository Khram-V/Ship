unit FreeNewModelDlg;
interface uses Spin,
    SysUtils, Forms,
    Controls, StdCtrls,
    Buttons,  ExtCtrls, FreeLanguageSupport;
type
  TFreeNewModelDialog = class( TForm )
    ShipBox,ComboBox1,ComboBox2: TComboBox;
    BitBtn1,BitBtn2: TSpeedButton;
    SpinEdit1,SpinEdit2: TSpinEdit;
    ShipPanel,Panel1,Panel2,Panel3,Panel5: TPanel;
    FloatSpinEdit1,FloatSpinEdit2,FloatSpinEdit3: TFloatSpinEdit;
    ShipType,Label1,Label2,Label3,Label4,Label5,Label6,Label7,SD: TLabel;
    procedure BitBtn1Click( Sender: TObject );
    procedure BitBtn2Click( Sender: TObject );
  private
    function FGetBreadth: Single;  procedure FSetBreadth( Val:single );
    function FGetDraft  : Single;  procedure FSetDraft  ( Val:single );
    function FGetLength : Single;  procedure FSetLength ( Val:single );
    function FGetNCols  : Integer; procedure FSetNCols  ( Val:Integer );
    function FGetNRows  : Integer; procedure FSetNRows  ( Val:Integer );
  public
    function Execute: Boolean;
    property Breadth: Single read FGetBreadth write FSetBreadth;
    property Draft  : Single read FGetDraft write FSetDraft;
    property Length : Single read FGetLength write FSetLength;
    property NCols  : Integer read FGetNCols write FSetNCols;
    property NRows  : Integer read FGetNRows write FSetNRows;
end;

var FreeNewModelDialog: TFreeNewModelDialog;

implementation
{$R *.lfm}
function TFreeNewModelDialog.Execute: Boolean;
   begin NCols:=NCols;
         NRows:=NRows;
         Length:=Length;
         Breadth:=Breadth;
         Draft:=Draft;
         ShowTranslatedValues(Self);
         Showmodal;
         Result:=ModalResult=mrOK;
   end;
function TFreeNewModelDialog.FGetLength : single;  begin Result:=FloatSpinEdit1.Value; end;
function TFreeNewModelDialog.FGetBreadth: single;  begin Result:=FloatSpinEdit2.Value; end;
function TFreeNewModelDialog.FGetDraft  : single;  begin result:=FloatSpinEdit3.Value; end;
function TFreeNewModelDialog.FGetNCols  : integer; begin Result:=SpinEdit1.Value; end;
function TFreeNewModelDialog.FGetNRows  : integer; begin Result:=SpinEdit2.Value; end;
procedure TFreeNewModelDialog.FSetLength (Val: single); begin FloatSpinEdit1.Value:=Val; end;
procedure TFreeNewModelDialog.FSetBreadth(Val: single); begin FloatSpinEdit2.Value:=Val; end;
procedure TFreeNewModelDialog.FSetDraft  (Val: single); begin FloatSpinEdit3.Value:=Val; end;
procedure TFreeNewModelDialog.FSetNCols  (Val: integer); begin if Val<3 then Val:=3; SpinEdit1.Value:=Val; end;
procedure TFreeNewModelDialog.FSetNRows  (Val: integer); begin if Val<3 then Val:=3; SpinEdit2.Value:=Val; end;
procedure TFreeNewModelDialog.BitBtn1Click(Sender: TObject); begin ModalResult:=mrOK; end;
procedure TFreeNewModelDialog.BitBtn2Click(Sender: TObject); begin ModalResult:=mrCancel; end;
end.
