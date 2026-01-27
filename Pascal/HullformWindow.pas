unit HullformWindow;
interface uses
     SysUtils, Classes,
     Graphics, Controls,
     Forms,    Dialogs,
     StdCtrls, Menus,
     ActnList, Geometry,ShipUnit,STypes;

type THullWindow = class( TForm )
     Viewport: TViewport;
     ScrollBar1,ScrollBar2: TScrollBar;
     PopupMenu: TPopupMenu;
     Images: TImageList;
     ActionList1: TActionList;   Camera1: TMenuItem;
     WideLens: TAction;          Widelens28mm1: TMenuItem;
     StandardLens: TAction;      Standard50mm1: TMenuItem;
     ShortTeleLens: TAction;     Shorttelelens90mm1: TMenuItem;
     MediumTeleLens: TAction;    Mediumtelelens130mm1: TMenuItem;
     LongTeleLens: TAction;      Longtelelens200mm1: TMenuItem;
                                 View1: TMenuItem;
     ViewBodyPlan: TAction;      Bodyplan1: TMenuItem;
     ViewProfile: TAction;       Profile1: TMenuItem;
     ViewPlan: TAction;          Planview1: TMenuItem;
     ViewPerspective: TAction;   Perspective1: TMenuItem;
     ZoomIn: TAction;            ZoomIn1: TMenuItem;
     ZoomExtents: TAction;       Zoom1: TMenuItem;
     ZoomOut: TAction;           Zoomout1: TMenuItem;
                                 All1: TMenuItem;
     DeselectAll: TAction;       Deselectall1: TMenuItem;
     ShowWireFrame: TAction;     Wireframe1: TMenuItem;
                                 Mode1: TMenuItem;
     ShowFlatShade: TAction;     Shade1: TMenuItem;
     ShowGaussCurvature:TAction; Gausscurvature1: TMenuItem;
     ShowDevelopablity: TAction; Developablitycheck1: TMenuItem;
     SaveAsBitmap: TAction;      Saveimage1: TMenuItem;
     ShadeZebra: TAction;        Zebrashading1: TMenuItem;
     ImportBackGround: TAction;  Backgroundimage1: TMenuItem;
     BackgroundOrigin: TAction;  Backgroundimage2: TMenuItem;
                                 Origin1: TMenuItem;
     BackgroundScale: TAction;   Setscale1: TMenuItem;
     BackgroundTransparentColor: TAction; ransparentcolor1: TMenuItem;
     Backgroundclear: TAction;   Clear1: TMenuItem;
     BackgroundBlending: TAction; Blending1: TMenuItem;
     BackgroundExport: TAction;  Export1: TMenuItem;
     BackgroundTolerance: TAction; Tolerance1: TMenuItem;
     BackgroundVisible: TAction; Visible1: TMenuItem;
   procedure ViewportRequestExtents(Sender: TObject; var Min,Max: Vector);
   procedure ViewportRedraw(Sender: TObject);
   procedure FormCreate(Sender: TObject);
   procedure FormClose(Sender: TObject; var Action: TCloseAction);
   procedure PopupMenuPopup(Sender: TObject);
   procedure StandardLensExecute(Sender: TObject);
   procedure WideLensExecute(Sender: TObject);
   procedure ShortTeleLensExecute(Sender: TObject);
   procedure MediumTeleLensExecute(Sender: TObject);
   procedure LongTeleLensExecute(Sender: TObject);
   procedure ViewBodyPlanExecute(Sender: TObject);
   procedure ViewProfileExecute(Sender: TObject);
   procedure ViewPlanExecute(Sender: TObject);
   procedure ViewPerspectiveExecute(Sender: TObject);
   procedure FormShow(Sender: TObject);
   procedure ViewportChangeViewType(Sender: TObject);
   procedure ZoomInExecute(Sender: TObject);
   procedure ZoomExtentsExecute(Sender: TObject);
   procedure ZoomOutExecute(Sender: TObject);
   procedure ViewportMouseDown(Sender: TObject; Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
   procedure ViewportMouseMove(Sender: TObject; Shift: TShiftState; X,Y: Integer);
   procedure ViewportMouseUp(Sender: TObject; Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
   procedure DeselectAllExecute(Sender: TObject);
   procedure ViewportMouseLeave(Sender: TObject);
   procedure ShowWireFrameExecute(Sender: TObject);
   procedure ShowFlatShadeExecute(Sender: TObject);
   procedure ShowGaussCurvatureExecute(Sender: TObject);
   procedure ShowDevelopablityExecute(Sender: TObject);
   procedure SaveAsBitmapExecute(Sender: TObject);
   procedure ViewportKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
   procedure ViewportKeyPress(Sender: TObject; var Key: Char);
   procedure ShadeZebraExecute(Sender: TObject);
   procedure ImportBackGroundExecute(Sender: TObject);
   procedure BackgroundOriginExecute(Sender: TObject);
   procedure BackgroundScaleExecute(Sender: TObject);
   procedure BackgroundTransparentColorExecute(Sender: TObject);
   procedure BackgroundclearExecute(Sender: TObject);
   procedure BackgroundBlendingExecute(Sender: TObject);
   procedure ViewportRequestBackgroundImage(Sender: TObject);
   procedure ViewportChangeBackground(Sender: TObject);
   procedure BackgroundExportExecute(Sender: TObject);
   procedure BackgroundToleranceExecute(Sender: TObject);
   procedure BackgroundVisibleExecute(Sender: TObject);
private
   FShip: TShip;
   FInitialPosition:TPoint; // Initial position of the mouse cursor when the left or right button was pressed
   FAllowPanOrZoom, // Flag to check whether panning or zooming is allowed or not (not when an item has just been selected)
   FPanned:Boolean; // Private variable from which can be seen if the popup menu has to be shown or not
   procedure FSetShip(Val:TShip);
   function FCaptionText: string;
public
// constructor Create( TheOwner: TComponent );
   procedure SetCaption;
   procedure UpdateMenu;
   property St: TShip read FShip write FSetShip;
end;

var HullWindow: THullWindow;

implementation uses LanguageSupport,Main;
{$R *.LFM}
{
Constructor THullWindow.Create( TheOwner: TComponent );
      begin inherited Create( TheOwner );
            BorderStyle:=bsSizeable; //None; //Single;
            BorderWidth:=0;
            ViewPort.BevelWidth:=0;
            ViewPort.BevelInner:=bvNone;
            ViewPort.BevelOuter:=bvNone;
            ViewPort.Invalidate;
      end;
}
procedure THullWindow.FormCreate( Sender: TObject );
begin //Inherited;
      ScrollBar1.Position:=Round( Viewport.Angle );
      ScrollBar2.Position:=Round( Viewport.Elevation );
      FAllowPanOrZoom:=False;
end;
procedure THullWindow.FormClose(Sender: TObject; var Action: TCloseAction);
begin                                  // Disconnect from Ship component
     St:=nil; Action:=caFree;
     TMainform( Application.MainForm ).DelWindow( Self );
end;

function THullWindow.FCaptionText:string;
begin
   Case Viewport.ViewType of
      fvBodyplan    : Result:=Userstring(215)+'.';
      fvProfile     : Result:=Userstring(216)+'.';
      fvPlan        : Result:=Userstring(217)+'.';
      fvPerspective : Result:=Userstring(218)+'.'; else Result:='';
   end;
end;

procedure THullWindow.SetCaption; begin Caption:=FCaptionText; end;

procedure THullWindow.FSetShip(Val:TShip);
begin
   if Val<>FShip then begin
      if FShip<>nil then              // Disconnect from ship component
         FShip.DeleteViewport(Viewport);
      FShip:=Val;
      if FShip<>nil then                   // Connect to ship component
         FShip.AddViewport(Viewport);
   end;
end;

procedure THullWindow.UpdateMenu;
begin                                        // Update all menuitems and action
   WideLens.Checked:=Viewport.CameraType=ftWide;
   Camera1.Enabled:=Viewport.Viewtype=fvPerspective;
   StandardLens.Checked:=Viewport.CameraType=ftStandard;
   ShortTeleLens.Checked:=Viewport.CameraType=ftShortTele;
   MediumTeleLens.Checked:=Viewport.CameraType=ftMediumTele;
   LongTeleLens.Checked:=Viewport.CameraType=ftFarTele;
   // viewport view
   ViewBodyplan.Checked:=Viewport.ViewType=fvBodyplan;
   ViewProfile.Checked:=Viewport.ViewType=fvProfile;
   ViewPlan.Checked:=Viewport.ViewType=fvPlan;
   ViewPerspective.Checked:=Viewport.ViewType=fvPerspective;
   // Drawingmode
   ShowWireframe.Checked:=Viewport.ViewportMode=vmWireframe;
   ShowFlatShade.Checked:=Viewport.ViewportMode=vmShade;
   ShowGaussCurvature.Checked:=Viewport.ViewportMode=vmShadeGauss;
   ShowDevelopablity.Checked:=Viewport.ViewportMode=vmShadeDevelopable;
   ShadeZebra.Checked:=Viewport.ViewportMode=vmShadeZebra;
   // background image properties
   ImportBackGround.Enabled:=Viewport.ViewType<>fvPerspective;
   Backgroundclear.Enabled:=Viewport.BackgroundImage.Bitmap<>nil;
   BackgroundOrigin.Enabled:=(Viewport.ViewType<>fvPerspective)
                         and (Viewport.BackgroundImage.Bitmap<>nil)
                         and (Viewport.BackgroundImage.Visible)
                         and (Viewport.BackgroundImage.ShowInView=Viewport.ViewType);
   BackgroundScale.Enabled:=(Viewport.ViewType<>fvPerspective)
                         and (Viewport.BackgroundImage.Bitmap<>nil)
                         and (Viewport.BackgroundImage.Visible)
                         and (Viewport.BackgroundImage.ShowInView=Viewport.ViewType);
   BackgroundTransparentColor.Enabled:=(Viewport.ViewType<>fvPerspective)
                         and (Viewport.BackgroundImage.Bitmap<>nil)
                         and (Viewport.BackgroundImage.Visible)
                         and (Viewport.BackgroundImage.ShowInView=Viewport.ViewType);
   BackgroundBlending.Enabled:=(Viewport.ViewType<>fvPerspective)
                         and (Viewport.BackgroundImage.Bitmap<>nil)
                         and (Viewport.BackgroundImage.Visible)
                         and (Viewport.BackgroundImage.ShowInView=Viewport.ViewType);
   BackgroundExport.Enabled:=(Viewport.ViewType<>fvPerspective)
                         and (Viewport.BackgroundImage.Bitmap<>nil)
                         and (Viewport.BackgroundImage.Visible)
                         and (Viewport.BackgroundImage.ShowInView=Viewport.ViewType);
   BackgroundTolerance.Enabled:=(Viewport.ViewType<>fvPerspective)
                         and (Viewport.BackgroundImage.Bitmap<>nil)
                         and (Viewport.BackgroundImage.Visible)
                         and (Viewport.BackgroundImage.ShowInView=Viewport.ViewType)
                         and (Viewport.BackgroundImage.Transparent);
   BackgroundVisible.Checked:=Viewport.BackgroundImage.Visible;
   BackgroundVisible.Enabled:=(Viewport.ViewType<>fvPerspective)
                         and (Viewport.BackgroundImage.Bitmap<>nil)
                         and (Viewport.BackgroundImage.ShowInView=Viewport.ViewType);
end;
procedure THullWindow.ViewportRequestExtents(Sender: TObject; var Min,Max: Vector);
begin if St<>nil then begin
         St.Extents( Min,Max );
         if Viewport.ViewType=fvBodyPlan then begin
            if Min.Y>-Max.Y then Min.Y:=-Max.Y;  // симметричное дополнение
            if Max.Y<-Min.Y then Max.Y:=-Min.Y;  // сохранением нулевого центра
         end;
      end;
end;
procedure THullWindow.ViewportRedraw(Sender: TObject);
    begin if St<>nil then begin St.DrawToViewport( Viewport );
             if St.ActiveControlPoint<>nil then
                St.ActiveControlPoint:=St.ActiveControlPoint;
    end end;
procedure THullWindow.PopupMenuPopup(Sender: TObject);
    begin UpdateMenu; end;
procedure THullWindow.StandardLensExecute(Sender: TObject);
    begin Viewport.CameraType:=ftStandard; end;
procedure THullWindow.WideLensExecute(Sender: TObject);
    begin Viewport.CameraType:=ftWide; end;
procedure THullWindow.ShortTeleLensExecute(Sender: TObject);
    begin Viewport.CameraType:=ftShortTele; end;
procedure THullWindow.MediumTeleLensExecute(Sender: TObject);
    begin Viewport.CameraType:=ftMediumTele; end;
procedure THullWindow.LongTeleLensExecute(Sender: TObject);
    begin Viewport.CameraType:=ftFarTele; end;
procedure THullWindow.ViewBodyPlanExecute(Sender: TObject);
    begin Viewport.ViewType:=fvBodyplan; MainForm.WindowMenu; end;
procedure THullWindow.ViewProfileExecute(Sender: TObject);
    begin Viewport.ViewType:=fvProfile; MainForm.WindowMenu; end;
procedure THullWindow.ViewPlanExecute(Sender: TObject);
    begin Viewport.ViewType:=fvPlan; MainForm.WindowMenu; end;
procedure THullWindow.ViewPerspectiveExecute(Sender: TObject);
    begin Viewport.ViewType:=fvPerspective;  MainForm.WindowMenu; end;
procedure THullWindow.FormShow(Sender: TObject);
    begin SetCaption; end;
procedure THullWindow.ViewportChangeViewType(Sender: TObject);
    begin SetCaption; MainForm.WindowMenu; end;
procedure THullWindow.ZoomInExecute(Sender: TObject);
    begin Viewport.ZoomIn; end;
procedure THullWindow.ZoomExtentsExecute(Sender: TObject);
    begin Viewport.ZoomExtents; end;
procedure THullWindow.ZoomOutExecute(Sender: TObject);
    begin Viewport.ZoomOut; end;

procedure THullWindow.ViewportMouseDown
( Sender: TObject;
  Button: TMouseButton;
  Shift: TShiftState;
  X,Y: Integer
);
var Select: Boolean; P:Place;
begin
   FInitialPosition:=Point( X,Y );
   if (ssAlt in Shift)
   and (Viewport.Viewtype<>fvPerspective) then begin          // для линий тока
      P:=Viewport.ProjectBackTo2D(FInitialPosition);
      if (St.Visibility.ModelView=mvBoth)
      and (Viewport.ViewType=fvBodyplan) then P.X:=abs( P.X );
      St.Edit.Flowline_Add( P,Viewport.Viewtype );
      TMainform( Application.MainForm ).UpdateMenu;
      exit;
   end;
   FPanned:=False;
// if Viewport.ViewportMode=vmWireframe then
   St.MouseDown( Viewport,Button,Shift,X,Y,Select );
   FAllowPanOrZoom:=not select;  // An item has just been selected or deselect,
                                 //      so do NOT pan or zoom the vieport when
                                 //       the user (accidently) moves the mouse
   if Shift=[ssLeft,ssCtrl] then begin //           выделение контрольных точек
     Viewport.SelectionFrameRect:=Rect( FInitialPosition.X,FInitialPosition.Y,
                                        FInitialPosition.X,FInitialPosition.Y );
     Viewport.SelectionFrameActive:=true;
   end;
end;

procedure THullWindow.ViewportMouseMove(Sender: TObject;Shift: TShiftState; X, Y: Integer);
var P2D: Place; P3D: Vector; Str: string;
begin
// if Viewport.ViewType<>fvPerspective then begin
   P2D:=Viewport.ProjectBackTo2D( Point( X,Y ) );
   Case Viewport.ViewType of
      fvBodyplan: Str:=Userstring(215)+'.  Y='+FloatToDec(P2D.X,3)+'  Z='+FloatToDec(P2D.Y,3);
      fvProfile : Str:=Userstring(216)+'.  X='+FloatToDec(P2D.X,3)+'  Z='+FloatToDec(P2D.Y,3);
      fvPlan    : Str:=Userstring(217)+'.  X='+FloatToDec(P2D.X,3)+'  Y='+FloatToDec(P2D.Y,3);
      fvPerspective: begin
        P3D:=Viewport.ProjectBack( Point( X,Y ),ZERO );
        Str:=UserString(218)+format( '.  X=%-4.2f  Y=%-4.2f  Z=%-4.2f',[P3D.X,P3D.Y,P3D.Z]);
       end else Str:='';
   end; Caption:=Str;
// end;
   if (Shift=[ssLeft]) and (FAllowPanOrZoom) then begin // Zoom in or zoom out
      if (Viewport.ViewType<>fvPerspective) and (abs(FInitialPosition.Y-Y)>4)
      then begin
         if Y<FInitialPosition.Y then Viewport.ZoomIn else
         if Y>FInitialPosition.Y then Viewport.ZoomOut;
         FInitialPosition:=Point( X,Y );
      end;
   end else
   if (Shift=[ssRight]) and (FAllowPanOrZoom) then begin // Pan the window left, right, top or bottom
      if (abs(FInitialPosition.X-X)>4)
      or (abs(FInitialPosition.Y-Y)>4) then begin
         Viewport.Pan:=Point( Viewport.Pan.X+X-FInitialPosition.X,
                              Viewport.Pan.Y+Y-FInitialPosition.Y );
         FPanned:=True;
         FInitialPosition:=Point( X,Y );
      end;
   end else
   if (Shift=[ssLeft,ssCtrl]) then begin                // Draw selection frame
      if (abs(FInitialPosition.X-X)>4)
      or (abs(FInitialPosition.Y-Y)>4) then begin
         Viewport.SelectionFrameRect:=Rect(FInitialPosition.X,FInitialPosition.Y,X,Y);
      // Viewport.Rectangle( FInitialPosition.X,FInitialPosition.Y,X,Y );
      end;
   end else
   St.MouseMove( Viewport,Shift,X,Y );
end;
procedure THullWindow.ViewportMouseUp(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var P:TPoint;
begin
   if Button=mbRight then begin
      // Tracing:=false;
      // Only show pop-up menu if user has not panned the viewport (with right mouse-button)
      if FPanned then begin FPanned:=False; end else begin
         P:=Viewport.ClientToScreen( Point( X,Y ) );
         PopupMenu.Popup( P.X,P.Y );
      end;
   end;                                              // Reset the pan/zoom flag
   FAllowPanOrZoom:=True;
   if Viewport.SelectionFrameActive then begin
      St.SelectPointsInFrame( Viewport,Viewport.SelectionFrameRect );
      Viewport.SelectionFrameActive:=false;
   end;
   St.MouseUp(Viewport,Shift,X,Y);
end;
procedure THullWindow.DeselectAllExecute(Sender: TObject);
    begin St.Edit.Selection_Clear; end;
procedure THullWindow.ViewportMouseLeave(Sender: TObject);
begin            // stop panning or zooming when the cursor leaves the viewport
   FAllowPanOrZoom:=False;   // And remove the cursor location from the caption
   SetCaption;
   DeActivate;
end;
procedure THullWindow.ShowWireFrameExecute(Sender: TObject);
    begin Viewport.ViewportMode:=vmWireframe; end;
procedure THullWindow.ShowFlatShadeExecute(Sender: TObject);
    begin Viewport.ViewportMode:=vmShade; end;
procedure THullWindow.ShowGaussCurvatureExecute(Sender: TObject);
    begin Viewport.ViewportMode:=vmShadeGauss; end;
procedure THullWindow.ShowDevelopablityExecute(Sender: TObject);
    begin Viewport.ViewportMode:=vmShadeDevelopable; end;
procedure THullWindow.SaveAsBitmapExecute( Sender: TObject );
begin{  Case Viewport.ViewType of
             fvBodyplan   : vpt:='_Bodyplan';
             fvProfile    : vpt:='_Profile';
             fvPlan       : vpt:='_Plan';
             fvPerspective: vpt:='_Perspective'; else vpt:='';
        end; }
  Viewport.SaveAsBitmap( St.Preferences.ExportDirectory
     + ChangeFileExt( ExtractFilename
     ( ChangeFileExt( St.Filename,'' ) )+'_'+FCaptionText,'.png' ),true );
end;
procedure THullWindow.ViewportKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    begin St.KeyUp(Viewport,Key,Shift); end;
procedure THullWindow.ViewportKeyPress(Sender: TObject; var Key: Char);
    begin if key=#27 then DeselectAllExecute( self ); end;
procedure THullWindow.ShadeZebraExecute(Sender: TObject);
    begin Viewport.ViewportMode:=vmShadeZebra; UpdateMenu; end;
procedure THullWindow.ImportBackGroundExecute(Sender: TObject);
    begin if St<>nil then St.Edit.BackgroundImage_Open(Viewport);
    end;
procedure THullWindow.BackgroundOriginExecute(Sender: TObject);
    begin Viewport.BackgroundMode:=emSetOrigin; end;
procedure THullWindow.BackgroundScaleExecute(Sender: TObject);
    begin Viewport.BackgroundMode:=emSetScale; end;
procedure THullWindow.BackgroundTransparentColorExecute(Sender: TObject);
    begin Viewport.BackgroundMode:=emSetTransparentColor; end;

procedure THullWindow.BackgroundClearExecute(Sender: TObject);
begin if (Viewport.BackgroundImage.Bitmap<>nil)
      and (Viewport.BackgroundImage.Visible) then begin
          if St<>nil then St.Edit.BackgroundImage_Delete(Viewport);
      end;
end;
procedure THullWindow.BackgroundBlendingExecute( Sender: TObject );
    begin Viewport.BackgroundImage.SetBlendingValue; end;
procedure THullWindow.ViewportRequestBackgroundImage(Sender: TObject);
var I: Integer; Data: TBackgroundImageData; Pt:TPoint;
begin
   if St<>nil then begin Data:=nil;
      for I:=1 to St.NoBackgroundImages do
       if St.BackgroundImage[I-1].AssignedView=Viewport.ViewType then
         Data:=St.BackgroundImage[I-1];
      if Data<>nil
      then Viewport.BackgroundImage.AssignData(Data.Image,Data.AssignedView,Data.Origin,Data.Scale,Data.Transparent,Data.TransparentColor,Data.BlendingValue,Data.Quality,Data.Tolerance,True)
      else if Viewport.BackgroundImage.Bitmap<>nil then begin Pt.X:=0; Pt.Y:=0;
         Viewport.BackgroundImage.AssignData(nil,fvPerspective,Pt,1.0,False,clBlack,255,100,3,True);
      end;
   end;
end;

procedure THullWindow.ViewportChangeBackground(Sender: TObject);
var I: Integer;
begin
   for I:=1 to St.NoBackgroundImages do
   if St.BackgroundImage[I-1].AssignedView=Viewport.ViewType then begin
      St.Edit.CreateUndoObject(Userstring(219),true);
      St.BackgroundImage[I-1].UpdateData(Viewport);
      Break;
   end;
end;

procedure THullWindow.BackgroundExportExecute(Sender: TObject);
    begin Viewport.BackgroundImage.Save; end;

procedure THullWindow.BackgroundToleranceExecute(Sender: TObject);
var Str:String;
    Value,I: Integer;
begin
   Str:=IntToStr(Viewport.BackgroundImage.Tolerance);
   if InputQuery(Userstring(220),Userstring(221)+' (0-255)',Str) then begin
      val(Str,Value,I);
      if I=0 then begin
         if Value<0 then value:=0 else
         if Value>255 then value:=255;
         Viewport.BackgroundImage.Tolerance:=Value;
      end else ShowMessage(Userstring(222)+'!');
   end;
end;

procedure THullWindow.BackgroundVisibleExecute(Sender: TObject);
    begin Viewport.BackgroundImage.Visible:=not Viewport.BackgroundImage.Visible;
    end;

end.
