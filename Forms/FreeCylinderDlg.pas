
unit FreeCylinderDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
    {$IFDEF Windows}
  Windows,
    {$ELSE}
  LCLIntf, LCLType,
  LazFileUtils,
    {$ENDIF}
  SysUtils,
  Classes,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Buttons,
  FreeTypes,
  FreeGeometry,
  ExtCtrls, Spin,
  FreeShipUnit;
type

  { TFreeCylinderDialog }

  TFreeCylinderDialog = class(TForm)
    CloseEndDisk: TCheckBox;
    CloseStartDisk: TCheckBox;
    Panel2: TPanel;
    Panel4: TPanel;
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
    StartPointX: TFloatSpinEdit;
    StartPointY: TFloatSpinEdit;
    StartPointZ: TFloatSpinEdit;
    EndPointX: TFloatSpinEdit;
    EndPointY: TFloatSpinEdit;
    EndPointZ: TFloatSpinEdit;
    Radius: TFloatSpinEdit;
    NoOfPoints: TSpinEdit;
    Label3: TLabel;
    procedure OKButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private   { Private declarations }
    function FGetStartPoint: T3DCoordinate;
    procedure FSetStartPoint(val: T3DCoordinate);
    function FGetEndPoint: T3DCoordinate;
    procedure FSetEndPoint(val: T3DCoordinate);
  public    { Public declarations }
    function Execute(Str: string): boolean;
    property StartPoint: T3DCoordinate read FGetStartPoint write FSetStartPoint;
    property EndPoint: T3DCoordinate read FGetEndPoint write FSetEndPoint;
  end;

var FreeCylinderDialog: TFreeCylinderDialog;

implementation

{$R *.lfm}

function TFreeCylinderDialog.FGetStartPoint: T3DCoordinate;
begin
  Result:=SetPoint(StartPointX.Value, StartPointY.Value, StartPointZ.Value);
end;

procedure TFreeCylinderDialog.FSetStartPoint(val: T3DCoordinate);
begin
  StartPointX.Value:=Val.X;
  StartPointY.Value:=Val.Y;
  StartPointZ.Value:=Val.Z;
end;

function TFreeCylinderDialog.FGetEndPoint: T3DCoordinate;
begin
  Result:=SetPoint(EndPointX.Value, EndPointY.Value, EndPointZ.Value);
end;

procedure TFreeCylinderDialog.FSetEndPoint(val: T3DCoordinate);
begin
  EndPointX.Value:=Val.X;
  EndPointY.Value:=Val.Y;
  EndPointZ.Value:=Val.Z;
end;

function TFreeCylinderDialog.Execute(Str: string): boolean;
begin
  _label3.Caption:=Str;
  _label6.Caption:=Str;
  _label9.Caption:=Str;                                                       //ShowTranslatedValues(Self);
  Showmodal;
  Result:=ModalResult = mrOk;
end;

procedure TFreeCylinderDialog.OKButtonClick(Sender: TObject);
begin ModalResult:=mrOk; end;

procedure TFreeCylinderDialog.CancelButtonClick(Sender: TObject);
begin ModalResult:=mrCancel; end;

procedure TFreeCylinderDialog.BitBtn1Click(Sender: TObject);
begin ModalResult:=mrOk; end;

procedure TFreeCylinderDialog.BitBtn2Click(Sender: TObject);
begin ModalResult:=mrCancel; end;

end.
