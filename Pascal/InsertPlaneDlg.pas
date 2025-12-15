unit InsertPlaneDlg;
interface uses
     SysUtils,
     Controls,
     Forms,
     Buttons,
     ExtCtrls,
     StdCtrls, Geometry, STypes;
type 
TInsertPlaneDialog  = class(TForm)
    GroupBox1: TGroupBox;
    RadioButton1,RadioButton2,RadioButton3: TRadioButton;
    Edit1: TEdit;
    Label1,Label2,Label3,Label4,Label5: TLabel;
    CheckBox1: TCheckBox;
    Panel1,Panel3: TPanel;
    BitBtn1,BitBtn2: TSpeedButton;
    procedure RadioButton1Click(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);
    procedure RadioButton3Click(Sender: TObject);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private
    FMin,FMax: Vector;
    function FGetCreateControlcurve:Boolean;
    function FGetPlane:Plate;
    procedure FUpdate;
  public
    function Execute:Boolean;
    property CreateControlcurve : Boolean read FGetCreateControlcurve;
    property Max: Vector read FMax write FMax;
    property Min: Vector read FMin write FMin;
    property Plane: Plate read FGetPlane;
end;

var InsertPlaneDialog: TInsertPlaneDialog;

implementation
{$R *.lfm}

function TInsertPlaneDialog.FGetCreateControlcurve:Boolean;
   begin Result:=Checkbox1.Checked; end;
function TInsertPlaneDialog.FGetPlane:Plate;
begin
   Fillchar(Result,SizeOf(Result),0);
   if RadioButton1.Checked then Result.a:=1.0;
   if RadioButton2.Checked then Result.c:=1.0;
   if RadioButton3.Checked then Result.b:=1.0;
   Result.d:=-StrToFloat(Edit1.Text);
end;
procedure TInsertPlaneDialog.FUpdate;
begin
   if RadioButton1.Checked then label3.Caption:=FloatToStrF(Min.X+1e-4,ffFixed,7,4) else
      if RadioButton2.Checked then label3.Caption:=FloatToStrF(Min.Z+1e-4,ffFixed,7,4) else
         if RadioButton3.Checked then label3.Caption:=FloatToStrF(Min.Y+1e-4,ffFixed,7,4) else
            Label3.Caption:='';
   if RadioButton1.Checked then Label4.Caption:=FloatToStrF(Max.X+1e-4,ffFixed,7,4) else
      if RadioButton2.Checked then Label4.Caption:=FloatToStrF(Max.Z+1e-4,ffFixed,7,4) else
         if RadioButton3.Checked then Label4.Caption:=FloatToStrF(Max.Y+1e-4,ffFixed,7,4) else
            Label4.Caption:='';
end;
function TInsertPlaneDialog.Execute:Boolean;
   begin FUpdate; ShowModal; Result:=ModalResult=mrOK; end;
procedure TInsertPlaneDialog.RadioButton1Click(Sender: TObject);
    begin FUpdate; end;
procedure TInsertPlaneDialog.RadioButton2Click(Sender: TObject);
    begin FUpdate; end;
procedure TInsertPlaneDialog.RadioButton3Click(Sender: TObject);
    begin FUpdate; end;
procedure TInsertPlaneDialog.Edit1KeyPress(Sender: TObject; var Key: Char);
begin // only valid numerical values
   if Key in [#8,'1'..'9','0','-','+',#13,'.'] then else key:=#0;
end;
procedure TInsertPlaneDialog.BitBtn1Click(Sender: TObject);
    begin Modalresult:=mrOK; end;
procedure TInsertPlaneDialog.BitBtn2Click(Sender: TObject);
    begin Modalresult:=mrCancel; end;

end.
