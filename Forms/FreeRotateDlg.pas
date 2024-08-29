

unit FreeRotateDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Buttons,
  ExtCtrls, Spin, Menus,
  FreeLanguageSupport;

type

  { TFreeRotateDialog }

  TFreeRotateDialog = class(TForm)                        { TFreeRotateDialog }
    FloatSpinEdit1, FloatSpinEdit2, FloatSpinEdit3: TFloatSpinEdit;
    Label1, Label2, Label3, Label4, Label6, Label9: TLabel;
    Panel1, Panel2, Panel3: TPanel;
    OKButton, CancelButton: TSpeedButton;
    procedure OKButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private   { Private declarations }
    function  FGetXValue: extended;
    procedure FSetXValue(val: extended);
    function  FGetYValue: extended;
    procedure FSetYValue(val: extended);
    function  FGetZValue: extended;
    procedure FSetZValue(val: extended);
  public    { Public declarations }
    function Execute( Units: String ): boolean;
    property XValue: extended read FGetXValue write FSetXValue;
    property YValue: extended read FGetYValue write FSetYValue;
    property ZValue: extended read FGetZValue write FSetZValue;
  end;

var FreeRotateDialog: TFreeRotateDialog;

implementation

{$R *.lfm}

function TFreeRotateDialog.FGetXValue: extended;
   begin Result:=FloatSpinEdit1.Value; end;
function TFreeRotateDialog.FGetYValue: extended;
   begin Result:=FloatSpinEdit2.Value; end;
function TFreeRotateDialog.FGetZValue: extended;
   begin Result:=FloatSpinEdit3.Value; end;

procedure TFreeRotateDialog.FSetXValue(val: extended);
    begin FloatSpinEdit1.Value:=val; end;
procedure TFreeRotateDialog.FSetYValue(val: extended);
    begin FloatSpinEdit2.Value:=val; end;
procedure TFreeRotateDialog.FSetZValue(val: extended);
    begin FloatSpinEdit3.Value:=val; end;

function TFreeRotateDialog.Execute( Units: String ): boolean;
begin                                               ShowTranslatedValues(Self);
  Label3.Caption:=Units;                        //  Self.Caption:=Caption;
  Label6.Caption:=Units;
  Label9.Caption:=Units;
  Showmodal;
  Result:=ModalResult = mrOk;
end;

procedure TFreeRotateDialog.OKButtonClick(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TFreeRotateDialog.CancelButtonClick(Sender: TObject);
    begin ModalResult:=mrCancel; end;

end.
