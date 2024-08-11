
//   FreeExtrudeDlg

unit FreeExtrudeDlg;

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
  Classes,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Buttons,
  ExtCtrls, Spin,
  FreeShipUnit;
type

  { TFreeExtrudeDialog }

  TFreeExtrudeDialog = class(TForm)
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    FloatSpinEdit1: TFloatSpinEdit;
    FloatSpinEdit2: TFloatSpinEdit;
    FloatSpinEdit3: TFloatSpinEdit;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel4: TPanel;
    _Label3: TLabel;
    _Label6: TLabel;
    _Label9: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    procedure Edit1KeyPress(Sender: TObject; var Key: char);
    procedure Edit1Exit(Sender: TObject);
    procedure Edit1KeyDown(Sender: TObject;
      var Key: word; Shift: TShiftState);
    procedure Edit2Exit(Sender: TObject);
    procedure Edit3Exit(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure Edit2KeyPress(Sender: TObject; var Key: char);
    procedure Edit3KeyPress(Sender: TObject; var Key: char);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
  private   { Private declarations }
    function FGetXValue: extended;
    procedure FSetXValue(val: extended);
    function FGetYValue: extended;
    procedure FSetYValue(val: extended);
    function FGetZValue: extended;
    procedure FSetZValue(val: extended);
  public    { Public declarations }
    function Execute(Str: string): boolean;
    property XValue: extended read FGetXValue write FSetXValue;
    property YValue: extended read FGetYValue write FSetYValue;
    property ZValue: extended read FGetZValue write FSetZValue;
  end;

var FreeExtrudeDialog: TFreeExtrudeDialog;

implementation
{$IFnDEF FPC}
  {$R *.dfm}
{$ELSE}
  {$R *.lfm}
{$ENDIF}

function TFreeExtrudeDialog.FGetXValue: extended;
begin
  Result := FloatSpinEdit1.Value;
end;

procedure TFreeExtrudeDialog.FSetXValue(val: extended);
begin
  FloatSpinEdit1.Value := Val;
end;

function TFreeExtrudeDialog.FGetYValue: extended;
begin
  Result := FloatSpinEdit2.Value;
end;

procedure TFreeExtrudeDialog.FSetYValue(val: extended);
begin
  FloatSpinEdit2.Value := Val;
end;

function TFreeExtrudeDialog.FGetZValue: extended;
begin
  Result := FloatSpinEdit3.Value;
end;

procedure TFreeExtrudeDialog.FSetZValue(val: extended);
begin
  FloatSpinEdit3.Value := Val;
end;

function TFreeExtrudeDialog.Execute(Str: string): boolean;
begin
  _label3.Caption := Str;
  _label6.Caption := Str;
  _label9.Caption := Str;                                                       //ShowTranslatedValues(Self);
  Showmodal;
  Result := ModalResult = mrOk;
end;

procedure TFreeExtrudeDialog.Edit1KeyPress(Sender: TObject; var Key: char);
begin
  if (Key in [#8, '1'..'9', '0', '-', #13]) or (Key = FormatSettings.DecimalSeparator) then
  else key := #0;
  if Key = #13 then Edit1Exit(self);
end;

procedure TFreeExtrudeDialog.Edit1Exit(Sender: TObject);
begin
  XValue := self.XValue;
end;

procedure TFreeExtrudeDialog.Edit1KeyDown(Sender: TObject;
  var Key: word; Shift: TShiftState);
begin
  if Key = 13 then SelectNext(Activecontrol, True, True);
end;

procedure TFreeExtrudeDialog.Edit2Exit(Sender: TObject);
begin
  inherited;
  YValue := self.YValue;
end;

procedure TFreeExtrudeDialog.Edit3Exit(Sender: TObject);
begin
  ZValue := self.ZValue;
end;

procedure TFreeExtrudeDialog.OKButtonClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TFreeExtrudeDialog.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFreeExtrudeDialog.Edit2KeyPress(Sender: TObject; var Key: char);
begin
  if (Key in [#8, '1'..'9', '0', '-', #13]) or (Key = FormatSettings.DecimalSeparator) then
  else key := #0;
  if Key = #13 then Edit2Exit(self);
end;

procedure TFreeExtrudeDialog.Edit3KeyPress(Sender: TObject; var Key: char);
begin
  if (Key in [#8, '1'..'9', '0', '-', #13]) or (Key = FormatSettings.DecimalSeparator) then
  else key := #0;
  if Key = #13 then Edit3Exit(self);
end;

procedure TFreeExtrudeDialog.BitBtn1Click(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TFreeExtrudeDialog.BitBtn2Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.
