
unit FreeBackgroundBlendingDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
    {$IFDEF Windows}
  Windows,
    {$ELSE}
  LazFileUtils,
    {$ENDIF}
  SysUtils,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Buttons,
  ExtCtrls,
  FreeGeometry,
  ComCtrls;

type

  { TFreeBackgroundBlendDialog }

  TFreeBackgroundBlendDialog = class(TForm)
    Label1: TLabel;
    Panel2: TPanel;
    Panel1: TPanel;
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    Panel3: TPanel;
    Panel4: TPanel;
    TrackBar1: TTrackBar;
    _Label2: TLabel;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
  private   { Private declarations }
    FViewport: TFreeViewport;
  public    { Public declarations }
    function Execute(Viewport: TFreeViewport): boolean;
  end;

var
  FreeBackgroundBlendDialog: TFreeBackgroundBlendDialog;

implementation

{$R *.lfm}

function TFreeBackgroundBlendDialog.Execute(Viewport: TFreeViewport): boolean;
begin
  FViewport:=Viewport;
  Trackbar1.Position:=Viewport.BackgroundImage.Alpha;
  TrackBar1Change(self);                                                        //ShowTranslatedValues(Self);
  Showmodal;
  Result:=ModalResult = mrOk;
end;

procedure TFreeBackgroundBlendDialog.BitBtn1Click(Sender: TObject);
begin ModalResult:=mrOk; end;

procedure TFreeBackgroundBlendDialog.BitBtn2Click(Sender: TObject);
begin ModalResult:=mrCancel; end;

procedure TFreeBackgroundBlendDialog.TrackBar1Change(Sender: TObject);
begin
  FViewport.BackgroundImage.Alpha:=Trackbar1.Position;
  _Label2.Caption:=IntToStr(Round(100 * (Trackbar1.Position) / Trackbar1.Max)) + '%';
end;

end.
