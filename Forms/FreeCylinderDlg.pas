
unit FreeCylinderDlg;

interface

uses Windows,
     Messages,
     SysUtils,
     Classes,
     Graphics,
     Controls,
     Forms,
     Dialogs,
     StdCtrls,
     Buttons,
     FreeGeometry,
     ExtCtrls, FreeNumInput,FreeTypes;

type TFreeCylinderDialog = class(TForm)
                              Panel2: TPanel;
                              _Label3: TLabel;
                              _Label6: TLabel;
                              _Label9: TLabel;
                              Panel1: TPanel;
                              Panel3: TPanel;
                              Label1: TLabel;
                              Label2: TLabel;
                              Label4: TLabel;
                              BitBtn1: TSpeedButton;
                              BitBtn2: TSpeedButton;
                              Input1: TFreeNumInput;
                              Input2: TFreeNumInput;
                              Input3: TFreeNumInput;
                              Input4: TFreeNumInput;
                              Input5: TFreeNumInput;
                              Input6: TFreeNumInput;
                              Input7: TFreeNumInput;
                              Input8: TFreeNumInput;
                              Label3: TLabel;
                              procedure OKButtonClick(Sender: TObject);
                              procedure CancelButtonClick(Sender: TObject);
                              procedure BitBtn1Click(Sender: TObject);
                              procedure BitBtn2Click(Sender: TObject);
                           private   { Private declarations }
                              function FGetStartPoint:T3DVector;
                              procedure FSetStartPoint(val:T3DVector);
                              function FGetEndPoint:T3DVector;
                              procedure FSetEndPoint(val:T3DVector);
                           public    { Public declarations }
                              function Execute(Str:string):Boolean;
                              property StartPoint:T3DVector read FGetStartPoint write FSetStartPoint;
                              property EndPoint:T3DVector read FGetEndPoint write FSetEndPoint;
                        end;

var FreeCylinderDialog : TFreeCylinderDialog;

implementation
{$R *.LFM}

function TFreeCylinderDialog.FGetStartPoint:T3DVector;
   begin Result:=Vector(Input1.Value,Input2.Value,Input3.Value); end;

procedure TFreeCylinderDialog.FSetStartPoint(val:T3DVector);
begin
   Input1.Value:=Val.X;
   Input2.Value:=Val.Y;
   Input3.Value:=Val.Z;
end;{TFreeCylinderDialog.FSetStartPoint}

function TFreeCylinderDialog.FGetEndPoint:T3DVector;
begin
   Result:=Vector(Input4.Value,Input5.Value,Input6.Value);
end;{TFreeCylinderDialog.FGetEndPoint}

procedure TFreeCylinderDialog.FSetEndPoint(val:T3DVector);
begin
   Input4.Value:=Val.X;
   Input5.Value:=Val.Y;
   Input6.Value:=Val.Z;
end;{TFreeCylinderDialog.FSetEndPoint}

function TFreeCylinderDialog.Execute(Str:string):Boolean;
begin
   _label3.Caption:=Str;
   _label6.Caption:=Str;
   _label9.Caption:=Str;
   Showmodal;
   Result:=ModalResult=mrOk;
end;{TFreeCylinderDialog.Execute}

procedure TFreeCylinderDialog.OKButtonClick(Sender: TObject);
begin
   ModalResult:=mrOk;
end;{TFreeCylinderDialog.OKButtonClick}

procedure TFreeCylinderDialog.CancelButtonClick(Sender: TObject);
begin
   ModalResult:=mrCancel;
end;{TFreeCylinderDialog.CancelButtonClick}

procedure TFreeCylinderDialog.BitBtn1Click(Sender: TObject);
begin
   ModalResult:=mrOK;
end;{TFreeCylinderDialog.BitBtn1Click}

procedure TFreeCylinderDialog.BitBtn2Click(Sender: TObject);
begin
   ModalResult:=mrCancel;
end;{TFreeCylinderDialog.BitBtn2Click}

end.
