
unit FreeNewModelDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf,
{$ENDIF}
  SysUtils,
  Forms,
  Controls,
  StdCtrls,
  Buttons,
  ExtCtrls, Spin;

type TFreeNewModelDialog = class(TForm)
    FloatSpinEdit1: TFloatSpinEdit;
    FloatSpinEdit2: TFloatSpinEdit;
    FloatSpinEdit3: TFloatSpinEdit;
    Panel2: TPanel;
    Panel3: TPanel;
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    Panel1: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    ComboBox1: TComboBox;
    Panel4: TPanel;
    Panel5: TPanel;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private
    function FGetBreadth: single;
    function FGetDraft: single;
    function FGetLength: single;
    function FGetNCols: integer;
    function FGetNRows: integer;
    procedure FSetBreadth(Val: single);
    procedure FSetDraft(Val: single);
    procedure FSetLength(Val: single);
    procedure FSetNCols(Val: integer);
    procedure FSetNRows(Val: integer);
  public
    function Execute: boolean;
    property Breadth:single read FGetBreadth write FSetBreadth;
    property Draft:  single read FGetDraft write FSetDraft;
    property Length: single read FGetLength write FSetLength;
    property NCols: integer read FGetNCols write FSetNCols;
    property NRows: integer read FGetNRows write FSetNRows;
  end;

var
  FreeNewModelDialog: TFreeNewModelDialog;

implementation

{$R *.lfm}

function TFreeNewModelDialog.FGetLength: single;
begin Result := FloatSpinEdit1.Value; end;

procedure TFreeNewModelDialog.FSetLength(Val: single);
begin FloatSpinEdit1.Value := Val; end;

function TFreeNewModelDialog.FGetBreadth: single;
begin Result := FloatSpinEdit2.Value; end;

procedure TFreeNewModelDialog.FSetBreadth(Val: single);
begin FloatSpinEdit2.Value := Val; end;

function TFreeNewModelDialog.FGetDraft: single;
begin result:=FloatSpinEdit3.Value; end;

procedure TFreeNewModelDialog.FSetDraft(Val: single);
begin FloatSpinEdit3.Value := Val; end;

function TFreeNewModelDialog.FGetNCols: integer;
begin Result := SpinEdit1.Value; end;

procedure TFreeNewModelDialog.FSetNCols(Val: integer);
begin if Val < 3 then Val := 3; SpinEdit1.Value := Val; end;

function TFreeNewModelDialog.FGetNRows: integer;
begin Result := SpinEdit2.Value; end;

procedure TFreeNewModelDialog.FSetNRows(Val: integer);
begin if Val < 3 then Val := 3; SpinEdit2.Value := Val; end;

function TFreeNewModelDialog.Execute: boolean;
begin
  NCols := NCols;
  NRows := NRows;
  Length := Length;
  Breadth := Breadth;
  Draft := Draft;                                                               //ShowTranslatedValues(Self);
  Showmodal;
  Result := ModalResult = mrOk;
end;

procedure TFreeNewModelDialog.BitBtn1Click(Sender: TObject);
begin ModalResult := mrOk; end;

procedure TFreeNewModelDialog.BitBtn2Click(Sender: TObject);
begin ModalResult := mrCancel; end;

end.
