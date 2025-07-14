unit FreeInsertPlaneDlg;
{$MODE Delphi}{$H+}
interface uses
  SysUtils,Controls,
  Forms,   Buttons,
  ExtCtrls,StdCtrls,
  Spin,FreeTypes,FreeLanguageSupport;
type
  TFreeInsertPlaneDialog = class( TForm )
    GroupBox1: TGroupBox;
    CheckBox1: TCheckBox;
    Edit1,Edit2: TEdit;
    BitBtn1,BitBtn2: TSpeedButton;
    FloatSpinEdit1: TFloatSpinEdit;
    Label1,Label2,Label5: TLabel;
    Panel1,Panel2,Panel4,Panel5: TPanel;
    RadioButton1,RadioButton2,RadioButton3: TRadioButton;
    procedure RadioButton1Click(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);
    procedure RadioButton3Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private
    function FGetCreateControlcurve: boolean;
    function FGetPlane: T3DPlane;
    procedure FUpdate;
  public
    Min,Max: T3DVector;
    function Execute: boolean;
    property CreateControlcurve: boolean read FGetCreateControlcurve;
    property Plane: T3DPlane read FGetPlane;
  end;

var FreeInsertPlaneDialog: TFreeInsertPlaneDialog;

implementation
{$R *.lfm}

function TFreeInsertPlaneDialog.FGetCreateControlcurve: boolean;
   begin Result:=Checkbox1.Checked; end;
function TFreeInsertPlaneDialog.FGetPlane: T3DPlane;
begin
  Fillchar(Result,SizeOf(Result),0);
  if RadioButton1.Checked then Result.a:=1.0;
  if RadioButton2.Checked then Result.c:=1.0;
  if RadioButton3.Checked then Result.b:=1.0; // Result.d:=-StrToFloat(Edit1.Text);
                               Result.d:=-FloatSpinEdit1.Value;
end;
procedure TFreeInsertPlaneDialog.FUpdate;
var MinV,MaxV:TFloatType;
begin
  if RadioButton1.Checked then begin MinV:=Min.X; MaxV:=Max.X; end;
  if RadioButton2.Checked then begin MinV:=Min.Z; MaxV:=Max.Z; end;
  if RadioButton3.Checked then begin MinV:=Min.Y; MaxV:=Max.Y; end;
  MinV:=MinV+1e-4;
  MaxV:=MaxV-1e-4;
  FloatSpinEdit1.MinValue:=MinV;
  FloatSpinEdit1.MaxValue:=MaxV;
  Edit1.Caption:=FloatToDec(MinV,4);
  Edit2.Caption:=FloatToDec(MaxV,4);
end;
function TFreeInsertPlaneDialog.Execute: boolean;
   begin FUpdate;
         ShowTranslatedValues( Self ); ShowModal; Result:=ModalResult=mrOk;
   end;
procedure TFreeInsertPlaneDialog.RadioButton1Click(Sender: TObject);
    begin FUpdate; end;
procedure TFreeInsertPlaneDialog.RadioButton2Click(Sender: TObject);
    begin FUpdate; end;
procedure TFreeInsertPlaneDialog.RadioButton3Click(Sender: TObject);
    begin FUpdate; end;
procedure TFreeInsertPlaneDialog.BitBtn1Click(Sender: TObject);
    begin Modalresult:=mrOk; end;
procedure TFreeInsertPlaneDialog.BitBtn2Click(Sender: TObject);
    begin Modalresult:=mrCancel; end;

end.
