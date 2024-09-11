

unit FreeInsertPlaneDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, LCLType, //
{$ENDIF}
  //Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  Buttons,
  ExtCtrls,
  StdCtrls, Spin,
  FreeTypes,
  //FreeGeometry,
  FreeShipUnit,FreeLanguageSupport;

type

  { TFreeInsertPlaneDialog }

  TFreeInsertPlaneDialog = class(TForm)
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    Edit1: TEdit;
    Edit2: TEdit;
    FloatSpinEdit1: TFloatSpinEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    Label2: TLabel;
    Label5: TLabel;
    CheckBox1: TCheckBox;
    procedure RadioButton1Click(Sender: TObject);
    procedure RadioButton2Click(Sender: TObject);
    procedure RadioButton3Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private   { Private declarations }
    FMin: T3DCoordinate;
    FMax: T3DCoordinate;
    function FGetCreateControlcurve: boolean;
    function FGetPlane: T3DPlane;
    procedure FUpdate;
  public    { Public declarations }
    function Execute: boolean;
    property CreateControlcurve: boolean
      read FGetCreateControlcurve;
    property Max: T3DCoordinate
      read FMax write FMax;
    property Min: T3DCoordinate
      read FMin write FMin;
    property Plane: T3DPlane read FGetPlane;
  end;

var
  FreeInsertPlaneDialog: TFreeInsertPlaneDialog;

implementation

{$IFnDEF FPC}
  {$R *.dfm}

{$ELSE}
  {$R *.lfm}
{$ENDIF}

function TFreeInsertPlaneDialog.FGetCreateControlcurve: boolean;
begin Result:=Checkbox1.Checked; end;

function TFreeInsertPlaneDialog.FGetPlane: T3DPlane;
begin
  Fillchar(Result, SizeOf(Result), 0);
  if RadioButton1.Checked then
    Result.a:=1.0;
  if RadioButton2.Checked then
    Result.c:=1.0;
  if RadioButton3.Checked then
    Result.b:=1.0;
  //Result.d:=-StrToFloat(Edit1.Text);
  Result.d:=-FloatSpinEdit1.Value;
end;

procedure TFreeInsertPlaneDialog.FUpdate;
var MinV,MaxV:TFloatType;
begin
  if RadioButton1.Checked then begin
    MinV:=Min.X;
    MaxV:=Max.X; end;
  if RadioButton2.Checked then begin
    MinV:=Min.Z;
    MaxV:=Max.Z; end;
  if RadioButton3.Checked then begin
    MinV:=Min.Y;
    MaxV:=Max.Y; end;
  MinV:=MinV + 1e-4;
  MaxV:=MaxV - 1e-4;
  FloatSpinEdit1.MinValue:=MinV;
  FloatSpinEdit1.MaxValue:=MaxV;
  Edit1.Caption:=FloatToStrF(MinV, ffFixed, 7, 4);
  Edit2.Caption:=FloatToStrF(MaxV, ffFixed, 7, 4);
end;

function TFreeInsertPlaneDialog.Execute: boolean;
   begin FUpdate; ShowTranslatedValues(Self); ShowModal; Result:=ModalResult=mrOk; end;
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
