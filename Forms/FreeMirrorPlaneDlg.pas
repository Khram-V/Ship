unit FreeMirrorPlaneDlg;
{$MODE Delphi}{$H+}
interface uses
     SysUtils,     Controls,
     Forms,        Buttons,
     ExtCtrls,     StdCtrls,
     FreeTypes,    Spin;

type
 TFreeMirrorPlaneDialog  = class(TForm)
     CheckBox1: TCheckBox;
     GroupBox1: TGroupBox;
     Label1: TLabel;
     Panel1,Panel2,Panel3,Panel4: TPanel;
     BitBtn1,BitBtn2: TSpeedButton;
     RadioButton1,RadioButton2,RadioButton3: TRadioButton;
     Edit1: TFloatSpinEdit;
     procedure BitBtn1Click(Sender: TObject);
     procedure BitBtn2Click(Sender: TObject);
   private   { Private declarations }
     function FGetPlane:T3DPlane;
   public    { Public declarations }
     function Execute:Boolean;
     property Plane : T3DPlane read FGetPlane;
 end;

var FreeMirrorPlaneDialog: TFreeMirrorPlaneDialog;

implementation
  {$R *.lfm}

function TFreeMirrorPlaneDialog.FGetPlane:T3DPlane;
begin
   Fillchar( Result,SizeOf(Result),0 );
   if RadioButton1.Checked then Result.a:=1.0;
   if RadioButton2.Checked then Result.c:=1.0;
   if RadioButton3.Checked then Result.b:=1.0;
   Result.d:=-StrToFloat( Edit1.Text ); //GetFloat( Edit1.Text );
end;{TFreeMirrorPlaneDialog.FGetPlane}

function TFreeMirrorPlaneDialog.Execute:Boolean;
begin
   ShowModal;
   Result:=ModalResult=mrOK;
end;{TFreeMirrorPlaneDialog.Execute}

procedure TFreeMirrorPlaneDialog.BitBtn1Click(Sender: TObject);
begin
   Modalresult:=mrOK;
end;{TFreeMirrorPlaneDialog.BitBtn1Click}

procedure TFreeMirrorPlaneDialog.BitBtn2Click(Sender: TObject);
begin
   Modalresult:=mrCancel;
end;{TFreeMirrorPlaneDialog.BitBtn2Click}

end.
