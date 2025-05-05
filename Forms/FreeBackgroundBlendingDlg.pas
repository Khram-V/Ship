unit FreeBackgroundBlendingDlg;
{$MODE Delphi}{$H+}
interface uses
  SysUtils,  Controls,
  Forms,     StdCtrls,
  Buttons,   ExtCtrls, ComCtrls, FreeGeometry, FreeLanguageSupport;
type
  TFreeBackgroundBlendDialog = class(TForm)
    Label1, _Label2: TLabel;
    Panel2,Panel1,Panel3,Panel4: TPanel;
    BitBtn1,BitBtn2: TSpeedButton;
    TrackBar1: TTrackBar;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
  private   { Private declarations }
    FViewport: TFreeViewport;
  public    { Public declarations }
    function Execute( Viewport: TFreeViewport ): boolean;
  end;

var
  FreeBackgroundBlendDialog: TFreeBackgroundBlendDialog;

implementation

{$R *.lfm}

function TFreeBackgroundBlendDialog.Execute(Viewport: TFreeViewport): boolean;
begin
  FViewport:=Viewport;
  Trackbar1.Position:=Viewport.BackgroundImage.Alpha;
  TrackBar1Change(self);
  ShowTranslatedValues(Self); Showmodal;
  Result:=ModalResult = mrOk;
end;

procedure TFreeBackgroundBlendDialog.BitBtn1Click(Sender: TObject);
begin ModalResult:=mrOk; end;

procedure TFreeBackgroundBlendDialog.BitBtn2Click(Sender: TObject);
begin ModalResult:=mrCancel; end;

procedure TFreeBackgroundBlendDialog.TrackBar1Change(Sender: TObject);
begin
  FViewport.BackgroundImage.Alpha:=Trackbar1.Position;
  _Label2.Caption:=IntToStr(Round(100 * (Trackbar1.Position) / Trackbar1.Max))+'%';
end;

end.
