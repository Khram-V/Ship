
unit FreeInsertPlaneDlg;
{$MODE Delphi}
interface uses
  Messages,
     SysUtils,
     Variants,
     Classes,
     Graphics,
     Controls,
     Forms,
     Dialogs,
     Buttons,
     ExtCtrls,
     StdCtrls,
     FreeGeometry,FreeTypes;
type 
TFreeInsertPlaneDialog  = class(TForm)
    GroupBox1: TGroupBox;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label3: TLabel;
    CheckBox1: TCheckBox;
    Panel1: TPanel;
    Panel3: TPanel;
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    procedure RadioButton1Click(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);
    procedure RadioButton3Click(Sender: TObject);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private   { Private declarations }
    FMin  : T3DVector;
    FMax  : T3DVector;
    function FGetCreateControlcurve:Boolean;
    function FGetPlane:T3DPlane;
    procedure FUpdate;
  public    { Public declarations }
    function Execute:Boolean;
    property CreateControlcurve : Boolean read FGetCreateControlcurve;
    property Max               : T3DVector read FMax write FMax;
    property Min               : T3DVector read FMin write FMin;
    property Plane             : T3DPlane read FGetPlane;
end;

var FreeInsertPlaneDialog: TFreeInsertPlaneDialog;

implementation
{$R *.lfm}

function TFreeInsertPlaneDialog.FGetCreateControlcurve:Boolean;
   begin Result:=Checkbox1.Checked; end;

function TFreeInsertPlaneDialog.FGetPlane:T3DPlane;
begin
   Fillchar(Result,SizeOf(Result),0);
   if RadioButton1.Checked then Result.a:=1.0;
   if RadioButton2.Checked then Result.c:=1.0;
   if RadioButton3.Checked then Result.b:=1.0;
   Result.d:=-StrToFloat(Edit1.Text);
end;

procedure TFreeInsertPlaneDialog.FUpdate;
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

function TFreeInsertPlaneDialog.Execute:Boolean;
begin
   FUpdate;
   ShowModal;
   Result:=ModalResult=mrOK;
end;

procedure TFreeInsertPlaneDialog.RadioButton1Click(Sender: TObject);
    begin FUpdate; end;
procedure TFreeInsertPlaneDialog.RadioButton2Click(Sender: TObject);
    begin FUpdate; end;
procedure TFreeInsertPlaneDialog.RadioButton3Click(Sender: TObject);
    begin FUpdate; end;
procedure TFreeInsertPlaneDialog.Edit1KeyPress(Sender: TObject; var Key: Char);
begin // only valid numerical values
   if (Key in [#8,'1'..'9','0','-',#13]) or (Key=Decimalseparator) then else key:=#0;
end;
procedure TFreeInsertPlaneDialog.BitBtn1Click(Sender: TObject);
    begin Modalresult:=mrOK; end;
procedure TFreeInsertPlaneDialog.BitBtn2Click(Sender: TObject);
    begin Modalresult:=mrCancel; end;

end.
