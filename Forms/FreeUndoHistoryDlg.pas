unit FreeUndoHistoryDlg;
{$MODE Delphi}{$H+}
interface uses
    Graphics, Forms,
    Controls, Buttons,
    StdCtrls, ExtCtrls,
    FreeShipUnit, FreeVersionUnit, FreeTypes,
    FreeGeometry, FreeLanguageSupport;
type
  TFreeUndoHistoryDialog = class(TForm)              { TFreeUndoHistoryDialog }
    FreeShip1: TFreeShip;
    Panel,Panel1: TPanel;
    UndoBox: TListBox;
    Viewport: TFreeViewport;
    Splitter1: TSplitter;
    SpeedButton1,SpeedButton2: TSpeedButton;
    procedure UndoBoxClick(Sender: TObject);
    procedure ViewportRequestExtents(Sender: TObject; var Min,Max: T3DVector);
    procedure ViewportRedraw(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private                                              { Private declarations }
  public                                                { Public declarations }
    procedure CreateFreeShip;
    procedure CreateViewPort;
    function Execute( Freeship:TFreeShip ):Boolean;
  end;

var FreeUndoHistoryDialog: TFreeUndoHistoryDialog;

implementation
{$R *.lfm}

procedure TFreeUndoHistoryDialog.CreateFreeShip;
begin  FreeShip1:= TFreeShip.Create(Self);
  with FreeShip1 do begin
    FileChanged:=True;
    Filename:='~uShip.fbm';
    FileVersion:=fv261;
    Precision:=fpLow;
  end;
end;

procedure TFreeUndoHistoryDialog.CreateViewPort;
begin
  Viewport:=TFreeViewport.Create(Self);
  Viewport.Parent:=Panel1;
  with Viewport do begin
    Left:=200;
    Height:=400;
    Top:=9;
    Width:=400;
    Angle:=30;
    Align:=alClient;
    BackgroundImage.Alpha:=255;
    BackgroundImage.Owner:=Viewport;
    BackgroundImage.Quality:=100;
    BackgroundImage.Scale:=1;
    BackgroundImage.ShowInView:=fvBodyplan;
    BackgroundImage.Tolerance:=5;
    BackgroundImage.Transparent:=False;
    BackgroundImage.TransparentColor:=clBlack;
    BackgroundImage.Visible:=True;
    BevelOuter:=bvLowered;
    BorderStyle:=bsSingle;
    CameraType:=ftStandard;
    DoubleBuffer:=True;
    Elevation:=20;
    Margin:=0;
    ViewType:=fvPerspective;
    ViewportMode:=vmShade; // vmWireFrame;
    OnRedraw:=ViewportRedraw;
    OnRequestExtents:=ViewportRequestExtents;
  end;
end;
function TFreeUndoHistoryDialog.Execute( Freeship:TFreeShip ):Boolean;
var I,Max: Integer; Undo: TFreeUndoObject; Str: AnsiString;
begin
   CreateFreeShip;
   CreateViewPort;
   UndoBox.Clear;
   UndoBox.Items.BeginUpdate;
   Max:=0;
   for I:=0 to Freeship.UndoCount-1 do begin
      Undo:=Freeship.UndoObject[I];
      if length( Undo.UndoText )>Max then Max:=Length( Undo.UndoText );
   end;
   inc( Max,2 );
   for I:=0 to Freeship.UndoCount-1 do begin
      Undo:=Freeship.UndoObject[I];
      Str:=Str+'  ('+Undo.Time+')';
      UndoBox.Items.AddObject( Str,Undo );
   end;
   UndoBox.Items.EndUpdate;
   Freeship.AddViewport( Viewport );
   UndoBox.ItemIndex:=Freeship.UndoPosition-1;
   Viewport.Color:=Freeship.Preferences.ViewportColor;
   ShowTranslatedValues(Self);
   ShowModal;
   Result:=ModalResult=mrOK; ViewPort.Destroy; FreeShip1.Destroy;
end;
procedure TFreeUndoHistoryDialog.UndoBoxClick(Sender: TObject);
var Undo:TFreeUndoObject;
begin
   if UndoBox.ItemIndex<>-1 then begin
      Undo:=UndoBox.Items.Objects[UndoBox.ItemIndex] as TFreeUndoObject;
      Freeship1.LoadProject(Undo.Undodata);
      Viewport.ZoomExtents;
   end;
end;
procedure TFreeUndoHistoryDialog.ViewportRequestExtents( Sender:TObject; var Min,Max:T3DVector );
    begin Freeship1.Extents(Min,Max); end;
procedure TFreeUndoHistoryDialog.ViewportRedraw(Sender: TObject);
    begin Freeship1.DrawToViewport( Viewport ); end;
procedure TFreeUndoHistoryDialog.SpeedButton1Click(Sender: TObject);
    begin ModalResult:=mrOK; end;
procedure TFreeUndoHistoryDialog.SpeedButton2Click(Sender: TObject);
    begin ModalResult:=mrCancel; end;
procedure TFreeUndoHistoryDialog.FormResize(Sender: TObject);
    begin Speedbutton1.Left:=Panel.Width-132;
          Speedbutton2.Left:=Speedbutton1.Left+SpeedButton1.Width+2; end;

end.
