


unit FreeMirrorPlaneDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
 {$IFDEF Windows}
  Windows,
 {$ELSE}
  LCLIntf, LCLType,
 {$ENDIF}
     SysUtils,
     Variants,
     Graphics,
     Controls,
     Forms,
     Dialogs,
     Buttons,
     ExtCtrls,
     StdCtrls,
     FreeTypes,
     Spin;

type

{ TFreeMirrorPlaneDialog }

 TFreeMirrorPlaneDialog  = class(TForm)
                                BitBtn1: TSpeedButton;
                                BitBtn2: TSpeedButton;
                                CheckBox1: TCheckBox;
                                Edit1: TFloatSpinEdit;
                                 GroupBox1: TGroupBox;
                                 Label1: TLabel;
                                 Panel1: TPanel;
                                 Panel2: TPanel;
                                 Panel4: TPanel;
                                 RadioButton1: TRadioButton;
                                 RadioButton2: TRadioButton;
                                 RadioButton3: TRadioButton;
                                 Panel3: TPanel;
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

{$IFnDEF FPC}
  {$R *.dfm}
{$ELSE}
  {$R *.lfm}
{$ENDIF}

function TFreeMirrorPlaneDialog.FGetPlane:T3DPlane;
begin
   Fillchar(Result,SizeOf(Result),0);
   if RadioButton1.Checked then Result.a:=1.0;
   if RadioButton2.Checked then Result.c:=1.0;
   if RadioButton3.Checked then Result.b:=1.0;
   Result.d:=-GetFloat(Edit1.Text);
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
