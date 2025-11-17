unit FreeMirrorPlaneDlg;
interface uses
     SysUtils,  Controls,
     Forms,     Buttons,
     ExtCtrls,  StdCtrls,
     Spin,      FreeTypes;

type TFreeMirrorPlaneDialog  = class(TForm)
     GroupBox1: TGroupBox;
     RadioButton1,RadioButton2,RadioButton3: TRadioButton;
     Edit1: TFloatSpinEdit;
     CheckBox1: TCheckBox;
     Panel1,Panel3: TPanel;
     Label1: TLabel;
     BitBtn1,BitBtn2: TSpeedButton;
     procedure BitBtn1Click(Sender: TObject);
     procedure BitBtn2Click(Sender: TObject);
  private
     function FGetPlane:Plate;
  public
     function Execute:Boolean;
     property Plane : Plate read FGetPlane;
end;

var FreeMirrorPlaneDialog: TFreeMirrorPlaneDialog;

implementation

{$R *.lfm}

function TFreeMirrorPlaneDialog.FGetPlane:Plate;
begin
   Fillchar(Result,SizeOf(Result),0);
   if RadioButton1.Checked then Result.a:=1.0;
   if RadioButton2.Checked then Result.c:=1.0;
   if RadioButton3.Checked then Result.b:=1.0;
   Result.d:=-StrToFloat( Edit1.Text );
end;

function TFreeMirrorPlaneDialog.Execute:Boolean;
   begin ShowModal; Result:=ModalResult=mrOK; end;
procedure TFreeMirrorPlaneDialog.BitBtn1Click(Sender: TObject);
    begin Modalresult:=mrOK; end;
procedure TFreeMirrorPlaneDialog.BitBtn2Click(Sender: TObject);
    begin Modalresult:=mrCancel; end;

end.
