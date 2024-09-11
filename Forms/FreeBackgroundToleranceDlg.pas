unit FreeBackgroundToleranceDlg;

{$mode ObjFPC}{$H+}

interface

uses
  SysUtils, Forms, Controls, Dialogs, ExtCtrls, Buttons, Spin, StdCtrls,
  FreeGeometry,FreeShipUnit,FreeLanguageSupport;

type                                         { TFreeBackgroundToleranceDialog }

  TFreeBackgroundToleranceDialog = class(TForm)
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    Label1: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    SpinEdit1: TSpinEdit;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
  private
    FViewport: TFreeViewport;
  public
    function Execute(Viewport: TFreeViewport): boolean;
  end;

var
  FreeBackgroundToleranceDialog: TFreeBackgroundToleranceDialog;

implementation

{$R *.lfm}

{ TFreeBackgroundToleranceDialog }

function TFreeBackgroundToleranceDialog.Execute(Viewport: TFreeViewport): boolean;
begin
  FViewport:=Viewport;
  SpinEdit1.Value:=FViewport.BackgroundImage.Tolerance;
  ShowTranslatedValues(Self); Showmodal;
  Result:=ModalResult = mrOk;
end;

procedure TFreeBackgroundToleranceDialog.SpinEdit1Change(Sender: TObject);
begin FViewport.BackgroundImage.Tolerance:=SpinEdit1.Value; end;

procedure TFreeBackgroundToleranceDialog.BitBtn1Click(Sender: TObject);
begin ModalResult:=mrOk; end;

procedure TFreeBackgroundToleranceDialog.BitBtn2Click(Sender: TObject);
begin ModalResult:=mrCancel; end;

end.

