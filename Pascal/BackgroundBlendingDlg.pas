
unit BackgroundBlendingDlg;
{$MODE Delphi}
interface uses
     SysUtils,Controls,
     Forms,   Dialogs,
     StdCtrls,ComCtrls,
     Buttons, ExtCtrls, Geometry;

type TBackgroundBlendDialog = class( TForm )
     Panel1,Panel2,Panel3: TPanel;
     BitBtn1,BitBtn2: TSpeedButton;
     TrackBar1: TTrackBar;
     Label1,_Label2: TLabel;
     procedure BitBtn1Click(Sender: TObject);
     procedure BitBtn2Click(Sender: TObject);
     procedure TrackBar1Change(Sender: TObject);
     private
        FViewport: TViewport;
     public
        function Execute( Viewport:TViewport ):Boolean;
    end;

var BackgroundBlendDialog: TBackgroundBlendDialog;

implementation
{$R *.lfm}

function TBackgroundBlendDialog.Execute( Viewport:TViewport ):Boolean;
begin
   FViewport:=Viewport;
   Trackbar1.Position :=FViewport.BackgroundImage.Alpha;
   TrackBar1Change( self );
   Showmodal;
   Result:=ModalResult=mrOk;
end;

procedure TBackgroundBlendDialog.BitBtn1Click(Sender: TObject);
   begin ModalResult:=mrOk; end;
procedure TBackgroundBlendDialog.BitBtn2Click(Sender: TObject);
   begin ModalResult:=mrCancel; end;
procedure TBackgroundBlendDialog.TrackBar1Change(Sender: TObject);
begin
  FViewport.BackgroundImage.Alpha:=Trackbar1.Position;              // 0..255
  _Label2.Caption:=IntToStr( (100*Trackbar1.Position) div Trackbar1.Max)+'%';
//FViewport.BackgroundImage.Alpha:=(255*Trackbar1.Position) div Trackbar1.Max;
end;

end.
