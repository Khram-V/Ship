

{$mode objfpc}{$H+}

unit FreeRotateDlgM;

interface

uses
{$IFnDEF FPC}
  Windows,
  RichEdit,
{$ELSE}
  LCLIntf,
  //FreePrinter,
{$ENDIF}
  //Messages,
  SysUtils,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Buttons,
  ExtCtrls, Spin,
  FreeShipUnit;

type

  { TFreeRotateMDialog }

  TFreeRotateMDialog = class(TForm)
    CancelButton: TSpeedButton;
    FloatSpinEdit1: TFloatSpinEdit;
    FloatSpinEdit2: TFloatSpinEdit;
    FloatSpinEdit3: TFloatSpinEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label6: TLabel;
    Label9: TLabel;
    OKButton: TSpeedButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    procedure FloatSpinEdit1Resize(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private   { Private declarations }
    function FGetXValue: extended;
    procedure FSetXValue(val: extended);
    function FGetYValue: extended;
    procedure FSetYValue(val: extended);
    function FGetZValue: extended;
    procedure FSetZValue(val: extended);
  public    { Public declarations }
    function Execute(aCaption, Units: string): boolean;
    property XValue: extended read FGetXValue write FSetXValue;
    property YValue: extended read FGetYValue write FSetYValue;
    property ZValue: extended read FGetZValue write FSetZValue;
  end;

var
  FreeRotateMDialog: TFreeRotateMDialog;

implementation

{$R *.lfm}

function TFreeRotateMDialog.FGetXValue: extended;
begin Result:=FloatSpinEdit1.Value; end;

procedure TFreeRotateMDialog.FSetXValue(val: extended);
begin FloatSpinEdit1.Value := val; end;

function TFreeRotateMDialog.FGetYValue: extended;
begin Result:=FloatSpinEdit2.Value; end;

procedure TFreeRotateMDialog.FSetYValue(val: extended);
begin FloatSpinEdit2.Value := val; end;

function TFreeRotateMDialog.FGetZValue: extended;
begin Result:=FloatSpinEdit3.Value; end;

procedure TFreeRotateMDialog.FSetZValue(val: extended);
begin FloatSpinEdit3.Value := val; end;

function TFreeRotateMDialog.Execute(aCaption, Units: string): boolean;
begin
  Self.Caption := Caption;
  Label3.Caption := Units;
  Label6.Caption := Units;
  Label9.Caption := Units;                                                      //ShowTranslatedValues(Self);
  Showmodal;
  Result := ModalResult = mrOk;
end;

procedure TFreeRotateMDialog.FloatSpinEdit1Resize(Sender: TObject);
begin
  Label14.Constraints.MinHeight:=FloatSpinEdit1.Height;
  Label15.Constraints.MinHeight:=FloatSpinEdit1.Height;
  Label16.Constraints.MinHeight:=FloatSpinEdit1.Height;
end;

procedure TFreeRotateMDialog.OKButtonClick(Sender: TObject);
begin ModalResult := mrOk; end;

procedure TFreeRotateMDialog.CancelButtonClick(Sender: TObject);
begin ModalResult := mrCancel; end;

end.
