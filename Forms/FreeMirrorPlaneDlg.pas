
unit FreeMirrorPlaneDlg;

interface

uses Windows,
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
     FreeGeometry,
     FreeNumInput,FreeTypes;

type TFreeMirrorPlaneDialog  = class(TForm)
                                 GroupBox1: TGroupBox;
                                 RadioButton1: TRadioButton;
                                 RadioButton2: TRadioButton;
                                 RadioButton3: TRadioButton;
                                 Edit1: TFreeNumInput;
                                 Label1: TLabel;
                                 CheckBox1: TCheckBox;
                                 Panel1: TPanel;
                                 Panel3: TPanel;
                                 BitBtn1: TSpeedButton;
                                 BitBtn2: TSpeedButton;
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
   Fillchar(Result,SizeOf(Result),0);
   if RadioButton1.Checked then Result.a:=1.0;
   if RadioButton2.Checked then Result.c:=1.0;
   if RadioButton3.Checked then Result.b:=1.0;
   Result.d:=-StrToFloat(Edit1.Text);
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
