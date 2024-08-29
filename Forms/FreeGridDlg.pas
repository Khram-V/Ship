

unit FreeGridDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
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

  { TFreeGridDialog }

  TFreeGridDialog = class(TForm)
    Plane: TComboBox;
    SizeA: TFloatSpinEdit;
    SizeB: TFloatSpinEdit;
    Label5: TLabel;
    lbDimensions: TLabel;
    lbPlane: TLabel;
    Panel2: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    lbUnit1: TLabel;
    Panel1: TPanel;
    Panel3: TPanel;
    lbStartpoint: TLabel;
    lbNoPoints: TLabel;
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    StartPointX: TFloatSpinEdit;
    StartPointY: TFloatSpinEdit;
    StartPointZ: TFloatSpinEdit;
    ColumnPoints: TSpinEdit;
    RowPoints: TSpinEdit;
    lbUnit2: TLabel;
    procedure OKButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private   { Private declarations }
    function GetStartPoint: T3DCoordinate;
    procedure SetStartPoint(val: T3DCoordinate);
  public    { Public declarations }
    function Execute(Str: string): boolean;
    property StartPoint: T3DCoordinate
      read GetStartPoint write SetStartPoint;
  end;

var FreeGridDialog: TFreeGridDialog;

implementation

{$R *.lfm}

function TFreeGridDialog.GetStartPoint: T3DCoordinate;
begin
  Result:=SetPoint(StartPointX.Value, StartPointY.Value, StartPointZ.Value);
end;

procedure TFreeGridDialog.SetStartPoint(val: T3DCoordinate);
begin
  StartPointX.Value:=Val.X;
  StartPointY.Value:=Val.Y;
  StartPointZ.Value:=Val.Z;
end;

function TFreeGridDialog.Execute(Str: string): boolean;
begin
  lbUnit1.Caption:=Str;
  lbUnit2.Caption:=Str;                                                       //ShowTranslatedValues(Self);
  Showmodal;
  Result:=ModalResult = mrOk;
end;

procedure TFreeGridDialog.OKButtonClick(Sender: TObject);
begin ModalResult:=mrOk; end;

procedure TFreeGridDialog.CancelButtonClick(Sender: TObject);
begin ModalResult:=mrCancel; end;

procedure TFreeGridDialog.BitBtn1Click(Sender: TObject);
begin ModalResult:=mrOk; end;

procedure TFreeGridDialog.BitBtn2Click(Sender: TObject);
begin ModalResult:=mrCancel; end;

end.
