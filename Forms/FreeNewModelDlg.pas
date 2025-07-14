unit FreeNewModelDlg;
{$mode objfpc}{$H+}
interface uses
    Controls,Forms,StdCtrls,Buttons,
    ExtCtrls,Spin,Classes,FreeLanguageSupport;
type
 TFreeNewModelDialog = class( TForm )                   { TFreeNewModelDialog }
    ShipBox,ComboBox1,ComboBox2: TComboBox;
    ShipType,Label1,Label2,Label3,Label4,Label5,Label6,Label7: TLabel;
    ShipPanel,Panel1,Panel2,Panel3,Panel5: TPanel;
    FloatSpinEdit1,FloatSpinEdit2,FloatSpinEdit3: TFloatSpinEdit;
    SpinEdit1,SpinEdit2: TSpinEdit;
    BitBtn1,BitBtn2: TSpeedButton;
    procedure BitBtn1Click( Sender:TObject );
    procedure BitBtn2Click( Sender:TObject );
  private
    function FGetBreadth:single;  procedure FSetBreadth(Val: single);
    function FGetDraft:  single;  procedure FSetDraft(Val: single);
    function FGetLength: single;  procedure FSetLength(Val: single);
    function FGetNCols: integer;  procedure FSetNCols(Val: integer);
    function FGetNRows: integer;  procedure FSetNRows(Val: integer);
  public
    property Breadth:single read FGetBreadth write FSetBreadth;
    property Draft:  single read FGetDraft write FSetDraft;
    property Length: single read FGetLength write FSetLength;
    property NCols: integer read FGetNCols write FSetNCols;
    property NRows: integer read FGetNRows write FSetNRows;
    function Execute: boolean;
  end;

var FreeNewModelDialog: TFreeNewModelDialog;

implementation
{$R *.lfm}

function TFreeNewModelDialog.FGetLength: single;
   begin Result:=FloatSpinEdit1.Value; end;
procedure TFreeNewModelDialog.FSetLength(Val: single);
    begin FloatSpinEdit1.Value:=Val; end;
function TFreeNewModelDialog.FGetBreadth: single;
   begin Result:=FloatSpinEdit2.Value; end;
procedure TFreeNewModelDialog.FSetBreadth(Val: single);
    begin FloatSpinEdit2.Value:=Val; end;
function TFreeNewModelDialog.FGetDraft: single;
   begin result:=FloatSpinEdit3.Value; end;
procedure TFreeNewModelDialog.FSetDraft(Val: single);
    begin FloatSpinEdit3.Value:=Val; end;
function TFreeNewModelDialog.FGetNCols: integer;
   begin Result:=SpinEdit1.Value; end;
procedure TFreeNewModelDialog.FSetNCols(Val: integer);
    begin if Val<3 then Val:=3; SpinEdit1.Value:=Val; end;
function TFreeNewModelDialog.FGetNRows: integer;
   begin Result:=SpinEdit2.Value; end;
procedure TFreeNewModelDialog.FSetNRows(Val: integer);
    begin if Val<3 then Val:=3; SpinEdit2.Value:=Val; end;
function TFreeNewModelDialog.Execute: boolean;
begin NCols:=NCols;
      NRows:=NRows;
      Length:=Length;
      Breadth:=Breadth;
      Draft:=Draft;
      ShowTranslatedValues(Self);
      Showmodal;
      Result:=ModalResult=mrOk;
end;
procedure TFreeNewModelDialog.BitBtn1Click( Sender: TObject );
    begin ModalResult:=mrOk; end;
procedure TFreeNewModelDialog.BitBtn2Click( Sender: TObject );
    begin ModalResult:=mrCancel; end;

end.
