

unit FreeBackgroundBlendingDlg;
{$MODE Delphi}
interface uses
     SysUtils,Controls,
     Forms,   Dialogs,
     StdCtrls,ComCtrls,
     Buttons, ExtCtrls, FreeGeometry;

type TFreeBackgroundBlendDialog = class( TForm )
     Panel1,Panel2,Panel3: TPanel;
     BitBtn1,BitBtn2: TSpeedButton;
     TrackBar1: TTrackBar;
     Label1,_Label2: TLabel;
     procedure BitBtn1Click(Sender: TObject);
     procedure BitBtn2Click(Sender: TObject);
     procedure TrackBar1Change(Sender: TObject);
     private
        FViewport: TFreeViewport;
     public
        function Execute( Viewport:TFreeViewport ):Boolean;
    end;

var FreeBackgroundBlendDialog: TFreeBackgroundBlendDialog;

implementation
{$R *.lfm}

function TFreeBackgroundBlendDialog.Execute(Viewport:TFreeViewport):Boolean;
begin
   FViewport:=Viewport;
   Trackbar1.Position :=FViewport.BackgroundImage.Alpha;
   TrackBar1Change( self );
   Showmodal;
   Result:=ModalResult=mrOk;
end;

procedure TFreeBackgroundBlendDialog.BitBtn1Click(Sender: TObject);
   begin ModalResult:=mrOk; end;
procedure TFreeBackgroundBlendDialog.BitBtn2Click(Sender: TObject);
   begin ModalResult:=mrCancel; end;
procedure TFreeBackgroundBlendDialog.TrackBar1Change(Sender: TObject);
begin
  FViewport.BackgroundImage.Alpha:=Trackbar1.Position;              // 0..255
  _Label2.Caption:=IntToStr( (100*Trackbar1.Position) div Trackbar1.Max)+'%';
//FViewport.BackgroundImage.Alpha:=(255*Trackbar1.Position) div Trackbar1.Max;
end;

end.
