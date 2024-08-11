

unit FreeRotateDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, //
{$ENDIF}
  //Messages,
  SysUtils,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Buttons,
  FreeShipUnit,
  ExtCtrls, Spin;

type

  { TFreeRotateDialog }

  TFreeRotateDialog = class(TForm)
    FloatSpinEdit1: TFloatSpinEdit;
    FloatSpinEdit2: TFloatSpinEdit;
    FloatSpinEdit3: TFloatSpinEdit;
    Panel2: TPanel;
    Label3: TLabel;
    Label6: TLabel;
    Label9: TLabel;
    Panel1: TPanel;
    OKButton: TSpeedButton;
    CancelButton: TSpeedButton;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Panel3: TPanel;
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
    function Execute(Caption, Units: string): boolean;
    property XValue: extended read FGetXValue write FSetXValue;
    property YValue: extended read FGetYValue write FSetYValue;
    property ZValue: extended read FGetZValue write FSetZValue;
  end;

var
  FreeRotateDialog: TFreeRotateDialog;

implementation

{$R *.lfm}

function TFreeRotateDialog.FGetXValue: extended;
begin
  Result := FloatSpinEdit1.Value;
end;{TFreeRotateDialog.FGetXValue}

procedure TFreeRotateDialog.FSetXValue(val: extended);
begin FloatSpinEdit1.Value := val; end;

function TFreeRotateDialog.FGetYValue: extended;
begin Result := FloatSpinEdit2.Value; end;

procedure TFreeRotateDialog.FSetYValue(val: extended);
begin FloatSpinEdit2.Value := val; end;

function TFreeRotateDialog.FGetZValue: extended;
begin Result := FloatSpinEdit3.Value; end;

procedure TFreeRotateDialog.FSetZValue(val: extended);
begin FloatSpinEdit3.Value := val; end;

function TFreeRotateDialog.Execute(Caption, Units: string): boolean;
begin                                                                           //ShowTranslatedValues(Self);
  Self.Caption := Caption;
  Label3.Caption := Units;
  Label6.Caption := Units;
  Label9.Caption := Units;
  Showmodal;
  Result := ModalResult = mrOk;
end;

procedure TFreeRotateDialog.OKButtonClick(Sender: TObject);
begin ModalResult := mrOk; end;

procedure TFreeRotateDialog.CancelButtonClick(Sender: TObject);
begin ModalResult := mrCancel; end;

end.
