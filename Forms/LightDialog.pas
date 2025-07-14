unit LightDialog;
{$mode objfpc}{$H+}
interface uses Forms,StdCtrls,ComCtrls,ButtonPanel,FreeGeometry,SysUtils;
type TLightDialog = class( TForm )
     ButtonPanel: TButtonPanel;
     GroupBoxPosition,GroupBoxPosition1: TGroupBox;
     LabelX,LabelY,LabelZ,LabelAmbience,LabelLuminance: TLabel;
     TrackBarX,TrackBarY,TrackBarZ: TTrackBar;
     TrackBarAmbience,TrackBarIntensity: TTrackBar;
     procedure FormClose( Sender: TObject; var CloseAction: TCloseAction );
     procedure FormShow( Sender: TObject );
     procedure TrackBarAmbienceChange( Sender: TObject );
     procedure TrackBarIntensityChange( Sender: TObject );
     procedure TrackBarXChange( Sender: TObject );
     procedure TrackBarYChange( Sender: TObject );
     procedure TrackBarZChange( Sender: TObject );
  public
     Act:boolean; ViewPort: TFreeViewPort; function getLight: TFreeLight;
  end;
implementation
{$R *.lfm}
function TLightDialog.getLight: TFreeLight;                    { TLightDialog }
begin result.Position.X:=TrackBarX.Position;
      result.Position.Y:=TrackBarY.Position;
      result.Position.Z:=TrackBarZ.Position;
      result.Ambient:=TrackBarAmbience.Position;
      result.Intensity:=TrackBarIntensity.Position;
end;
procedure TLightDialog.TrackBarXChange( Sender: TObject );
    begin if Act then ViewPort.Light:=getLight; end;
procedure TLightDialog.TrackBarYChange( Sender: TObject );
    begin if Act then ViewPort.Light:=getLight; end;
procedure TLightDialog.TrackBarZChange( Sender: TObject );
    begin if Act then ViewPort.Light:=getLight; end;
procedure TLightDialog.TrackBarAmbienceChange( Sender: TObject );
    begin if Act then ViewPort.Light:=getLight; end;
procedure TLightDialog.TrackBarIntensityChange( Sender: TObject );
    begin if Act then ViewPort.Light:=getLight; end;
procedure TLightDialog.FormClose(Sender:TObject; var CloseAction:TCloseAction);
    begin CloseAction:=caHide; end;
procedure TLightDialog.FormShow( Sender: TObject ); var H: Integer;
begin H:=Canvas.TextHeight( '|' );
      H:= abs( round( H*Font.PixelsPerInch/72.0 ) );
      self.Constraints.MinHeight :=  ButtonPanel.BoundsRect.Bottom
                                   + ButtonPanel.BorderSpacing.Bottom
                                   + ButtonPanel.BorderSpacing.Around
                                   + self.BorderWidth
                                 + ( self.Height-self.ClientHeight ) + H;
      Act:=false;
      TrackBarX.Position:=Round( ViewPort.Light.Position.X );
      TrackBarY.Position:=Round( ViewPort.Light.Position.Y );
      TrackBarZ.Position:=Round( ViewPort.Light.Position.Z );
      TrackBarAmbience.Position:=ViewPort.Light.Ambient;
      TrackBarIntensity.Position:=ViewPort.Light.Intensity; Act:=True;
end;
end.


