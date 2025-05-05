unit FreeGridDlg;
{$MODE Delphi}{$H+}
interface uses
  Controls,  Forms,
  StdCtrls,  Buttons,
  FreeTypes, ExtCtrls, Spin, FreeShipUnit,FreeLanguageSupport;
type
  TFreeGridDialog = class( TForm )
    Plane: TComboBox;
    BitBtn1,BitBtn2: TSpeedButton;
    Label5,lbPlane,lbUnit1,lbDimensions,lbStartpoint,lbNoPoints,lbUnit2: TLabel;
    Panel2,Panel4,Panel5,Panel6,Panel1,Panel3: TPanel;
    SizeA,SizeB,StartPointX,StartPointY,StartPointZ: TFloatSpinEdit;
    ColumnPoints,RowPoints: TSpinEdit;
    procedure OKButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private
    function GetStartPoint: T3DVector;
    procedure SetStartPoint(val: T3DVector);
  public
    function Execute(Str: AnsiString): boolean;
    property StartPoint: T3DVector read GetStartPoint write SetStartPoint;
  end;

var FreeGridDialog: TFreeGridDialog;

implementation
{$R *.lfm}

function TFreeGridDialog.GetStartPoint: T3DVector;
begin Result:=Vector(StartPointX.Value,StartPointY.Value,StartPointZ.Value);
end;
procedure TFreeGridDialog.SetStartPoint(val: T3DVector);
    begin StartPointX.Value:=Val.X;
          StartPointY.Value:=Val.Y;
          StartPointZ.Value:=Val.Z;
    end;
function TFreeGridDialog.Execute(Str: AnsiString): boolean;
   begin lbUnit1.Caption:=Str;
         lbUnit2.Caption:=Str;
         ShowTranslatedValues(Self); Showmodal; Result:=ModalResult=mrOk;
   end;
procedure TFreeGridDialog.OKButtonClick(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TFreeGridDialog.CancelButtonClick(Sender: TObject);
    begin ModalResult:=mrCancel; end;
procedure TFreeGridDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TFreeGridDialog.BitBtn2Click(Sender: TObject);
    begin ModalResult:=mrCancel; end;

end.
