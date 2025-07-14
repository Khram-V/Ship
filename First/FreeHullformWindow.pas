unit FreeHullformWindow;

interface uses
     SysUtils,
     Classes,
     Controls,
     Forms,
     StdCtrls,
     Menus,
     ActnList,
     FreeTypes, FreeGeometry, FreeShipUnit;

type TFreeHullWindow  = class(TForm)
     ScrollBar1: TScrollBar;
     ScrollBar2: TScrollBar;
     Viewport  : TFreeViewport;
     PopupMenu: TPopupMenu;
     ActionList1: TActionList;
     StandardLens: TAction;
     WideLens: TAction;
     Camera1: TMenuItem;
     Widelens28mm1: TMenuItem;
     Standard50mm1: TMenuItem;
     ShortTeleLens: TAction;
     Shorttelelens90mm1: TMenuItem;
     MediumTeleLens: TAction;
     Mediumtelelens130mm1: TMenuItem;
     LongTeleLens: TAction;
     Longtelelens200mm1: TMenuItem;
     View1: TMenuItem;
     Bodyplan1: TMenuItem;
     Profile1: TMenuItem;
     Planview1: TMenuItem;
     Perspective1: TMenuItem;
     ViewBodyPlan: TAction;
     ViewProfile: TAction;
     ViewPlan: TAction;
     ViewPerspective: TAction;
     ZoomIn: TAction;
     Zoom1: TMenuItem;
     ZoomIn1: TMenuItem;
     ZoomExtents: TAction;
     ZoomOut: TAction;
     Zoomout1: TMenuItem;
     All1: TMenuItem;
     Shade: TMenuItem;
     DeselectAll: TAction;
     Deselectall1: TMenuItem;
     procedure ViewportRequestExtents(Sender: TObject; var Min,Max: T3DVector);
     procedure ViewportRedraw(Sender: TObject);
     procedure FormCreate(Sender: TObject);
     procedure ScrollBar1Change(Sender: TObject);
     procedure ScrollBar2Change(Sender: TObject);
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
     procedure ShadeClick(Sender: TObject);
     procedure DeselectAllExecute(Sender: TObject);
     procedure ViewportMouseLeave(Sender: TObject);
  private
     FFreeShip         : TFreeShip;
     FPanned           : Boolean;  // Private variable from which can be seen if the popup menu has to be shown or not
     FInitialPosition  : TPoint;   // Initial position of the mouse cursor when the left or right button was pressed
     FAllowPanOrZoom   : Boolean;  // Flag to check whether panning or zooming is allowed or not (not when an item has just been selected)
     procedure FSetFreeShip(Val:TFreeShip);
  public
     procedure SetCaption;
     procedure UpdateMenu;
     property FreeShip:TFreeShip read FFreeShip write FSetFreeShip;
end;

var FreeHullWindow: TFreeHullWindow;

implementation
{$R *.lfm}

procedure TFreeHullWindow.SetCaption;
begin
   Case Viewport.ViewType of
      fvBodyplan     : Caption:='Bodyplan view.';
      fvProfile      : Caption:='Profile view.';
      fvPlan         : Caption:='Plan view.';
      fvPerspective  : Caption:='Perspective view.';
      else caption:='';
   end;
end;{TFreeHullWindow.SetCaption}

procedure TFreeHullWindow.FSetFreeShip(Val:TFreeShip);
begin
   if Val<>FFreeShip then begin
      if FFreeShip<>nil then begin        // Disconnect from Freeship component
         FFreeShip.DeleteViewport(Viewport);
      end;
      FFreeShip:=Val;
      if FFreeShip<>nil then begin        // Connect to Freeship component
         FFreeShip.AddViewport(Viewport);
      end;
   end;
end;{TFreeHullWindow.FSetFreeShip}

procedure TFreeHullWindow.UpdateMenu;
begin                                        // Update all menuitems and action
   WideLens.Checked:=Viewport.CameraType=ftWide;
   Camera1.Enabled:=Viewport.Viewtype=fvPerspective;
   StandardLens.Checked:=Viewport.CameraType=ftStandard;
   ShortTeleLens.Checked:=Viewport.CameraType=ftShortTele;
   MediumTeleLens.Checked:=Viewport.CameraType=ftMediumTele;
   LongTeleLens.Checked:=Viewport.CameraType=ftFarTele;        // viewport view
   ViewBodyplan.Checked:=Viewport.ViewType=fvBodyplan;
   ViewProfile.Checked:=Viewport.ViewType=fvProfile;
   ViewPlan.Checked:=Viewport.ViewType=fvPlan;
   ViewPerspective.Checked:=Viewport.ViewType=fvPerspective;
   Shade.Checked:=Viewport.Shade;
end;

procedure TFreeHullWindow.ViewportRequestExtents(Sender: TObject; var Min,Max: T3DVector);
    begin if FreeShip<>nil then Freeship.Extents(Min,Max); end;

procedure TFreeHullWindow.ViewportRedraw(Sender: TObject);
    begin if FreeShip<>nil then FreeShip.DrawToViewport(Viewport); end;
procedure TFreeHullWindow.FormCreate(Sender: TObject);
begin
   ScrollBar1.Position:=Round(Viewport.Angle);
   ScrollBar2.Position:=Round(Viewport.Elevation);
   FAllowPanOrZoom:=False;
end;

procedure TFreeHullWindow.ScrollBar1Change(Sender: TObject);
    begin Viewport.Angle:=ScrollBar1.Position; end;

procedure TFreeHullWindow.ScrollBar2Change(Sender: TObject);
    begin Viewport.Elevation:=ScrollBar2.Position; end;

procedure TFreeHullWindow.FormClose(Sender: TObject; var Action: TCloseAction);
begin // Disconnect from FreeShip component;
   Freeship:=nil;
   Action:=caFree;
end;{TFreeHullWindow.FormClose}

procedure TFreeHullWindow.PopupMenuPopup(Sender: TObject);
    begin UpdateMenu; end;
procedure TFreeHullWindow.StandardLensExecute(Sender: TObject);
    begin Viewport.CameraType:=ftStandard; end;
procedure TFreeHullWindow.WideLensExecute(Sender: TObject);
    begin Viewport.CameraType:=ftWide; end;
procedure TFreeHullWindow.ShortTeleLensExecute(Sender: TObject);
    begin Viewport.CameraType:=ftShortTele; end;
procedure TFreeHullWindow.MediumTeleLensExecute(Sender: TObject);
    begin Viewport.CameraType:=ftMediumTele; end;
procedure TFreeHullWindow.LongTeleLensExecute(Sender: TObject);
    begin Viewport.CameraType:=ftFarTele; end;
procedure TFreeHullWindow.ViewBodyPlanExecute(Sender: TObject);
    begin Viewport.ViewType:=fvBodyplan; end;
procedure TFreeHullWindow.ViewProfileExecute(Sender: TObject);
    begin Viewport.ViewType:=fvProfile; end;
procedure TFreeHullWindow.ViewPlanExecute(Sender: TObject);
    begin Viewport.ViewType:=fvPlan; end;
procedure TFreeHullWindow.ViewPerspectiveExecute(Sender: TObject);
    begin Viewport.ViewType:=fvPerspective; end;
procedure TFreeHullWindow.FormShow(Sender: TObject);
    begin SetCaption; end;
procedure TFreeHullWindow.ViewportChangeViewType(Sender: TObject);
begin
   SetCaption;
   ScrollBar1.Position:=Round(Viewport.Angle);
   Scrollbar1.Visible:=Viewport.ViewType=fvPerspective;
   ScrollBar2.Position:=Round(Viewport.Elevation);
   Scrollbar2.Visible:=Viewport.ViewType=fvPerspective;
end;{TFreeHullWindow.ViewportChangeViewType}

procedure TFreeHullWindow.ZoomInExecute(Sender: TObject);
    begin Viewport.ZoomIn; end;
procedure TFreeHullWindow.ZoomExtentsExecute(Sender: TObject);
    begin Viewport.ZoomExtents; end;
procedure TFreeHullWindow.ZoomOutExecute(Sender: TObject);
    begin Viewport.ZoomOut; end;

procedure TFreeHullWindow.ViewportMouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var Select: Boolean;
begin
   FInitialPosition.X:=X;
   FInitialPosition.Y:=Y;
   FPanned:=False;
  {if not Viewport.Shade then} FreeShip.MouseDown(Viewport,Button,Shift,X,Y,Select);
   FAllowPanOrZoom:=not select; // An item has just been selected or deselect, so do NOT pan or zoom the vieport when the user (accidently) moves the mouse
end;

procedure TFreeHullWindow.ViewportMouseMove(Sender: TObject;Shift: TShiftState; X, Y: Integer);
var P    : TPoint;
    P2D  : T2DCoordinate;
    Str  : string;
begin
   if Viewport.ViewType<>fvPerspective then begin
      P.X:=X;
      P.Y:=Y;
      P2D:=Viewport.ProjectBackTo2D(P);
      Case Viewport.ViewType of
         fvBodyplan: Str:='Bodyplan view.';
         fvProfile : Str:='Profile view.';
         fvPlan    : Str:='Plan view.';
         else Str:='';
      end;
      Case Viewport.ViewType of
         fvBodyplan: Str:=Str+'  Y='+FloatToStrF(P2D.X,ffFixed,7,3)+',   Z='+FloatToStrF(P2D.Y,ffFixed,7,3);
         fvProfile : Str:=Str+'  X='+FloatToStrF(P2D.X,ffFixed,7,3)+',   Z='+FloatToStrF(P2D.Y,ffFixed,7,3);
         fvPlan    : Str:=Str+'  X='+FloatToStrF(P2D.X,ffFixed,7,3)+',   Y='+FloatToStrF(P2D.Y,ffFixed,7,3);
      end;
      Caption:=Str;
   end;
   if (ssLeft in Shift) and (FAllowPanOrZoom) then begin // Zoom in or zoom out
      if abs(FInitialPosition.Y-Y)>2 then begin
         if Y<FInitialPosition.Y then begin Viewport.ZoomIn; end else
         if Y>FInitialPosition.Y then begin Viewport.ZoomOut; end;
      end;
      FInitialPosition.X:=X;
      FInitialPosition.Y:=Y;
   end else if (ssRight in Shift) and (FAllowPanOrZoom) then begin // Pan the window left, right, top or bottom
      if (abs(FInitialPosition.X-X)>1) or (abs(FInitialPosition.Y-Y)>1) then begin
         P.X:=Viewport.Pan.X+X-FInitialPosition.X;
         P.Y:=Viewport.Pan.Y+Y-FInitialPosition.Y;
         Viewport.Pan:=P;
         FPanned:=True;
      end;
      FInitialPosition.X:=X;
      FInitialPosition.Y:=Y;
   end else FFreeShip.MouseMove(Viewport,Shift,X,Y);
end;

procedure TFreeHullWindow.ViewportMouseUp(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var P:TPoint;
begin
   if Button=mbRight then begin // Tracing:=false;  Only show pop-up menu if user has not panned the viewport (with right mouse-button)
      if FPanned then begin FPanned:=False; end else begin
         P.X:=X;
         P.Y:=Y;
         P:=Viewport.ClientToScreen(P);
         PopupMenu.Popup(P.X,P.Y);
      end;
   end;                                             // Reset the pan/zoom flag
   FAllowPanOrZoom:=True;
end;
procedure TFreeHullWindow.ShadeClick(Sender: TObject);
    begin Viewport.Shade:=not Viewport.Shade; end;
procedure TFreeHullWindow.DeselectAllExecute(Sender: TObject);
    begin FreeShip.Edit.Selection_Clear; end;

procedure TFreeHullWindow.ViewportMouseLeave(Sender: TObject);
begin                      // stop panning or zooming when the cursor leaves the viewport
   FAllowPanOrZoom:=False; // And remove the cursor location from the caption
   SetCaption;
end;

end.
