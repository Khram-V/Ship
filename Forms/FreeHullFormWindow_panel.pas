
//   FreeHullFormWindow_Panel

unit FreeHullFormWindow_Panel;

{$IFNDEF FPC}
  {$MODE Delphi}
{$ELSE}
  {$mode objfpc}{$H+}
{$ENDIF}

interface

uses
// MDIPanel,
{$IFDEF WINDOWS}
  Windows,
 {$ENDIF}
  LCLIntf, LCLType,
  PrintersDlgs,
     SysUtils,
     Classes,
     Graphics,
     Controls,
     Forms,
     Dialogs,
     FreeTypes,
     FreeGeometry,
     FreeShipUnit,
     StdCtrls,
     Menus,
     ActnList,
     Printers,
     LightDialog,
//{$IFDEF USEOPENGL}
//   FreeViewPortOpenGL,
//{$ENDIF}
 {$IFDEF USE_freehullformwindow_form}
     freehullformwindow_form,
 {$ENDIF}
     MDIPanel;
type
 TFreeHullWindow = class(TMDIPanel)                         { TFreeHullWindow }
  BackgroundFrame: TAction;  Frame: TMenuItem;
  SetLight: TAction;         Light: TMenuItem;

  ActionListHull: TActionList;
  ImagesHull: TImageList;

  PopupMenuHull: TPopupMenu;
  PrintDialogHull: TPrintDialog;
//   ScrollBar1: TScrollBar;
//   ScrollBar2: TScrollBar;
   Viewport  : TFreeViewport;
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
   DeselectAll: TAction;
   Deselectall1: TMenuItem;
   Print: TAction;
   ShowWireFrame: TAction;
   Mode1: TMenuItem;
   Wireframe1: TMenuItem;
   ShowFlatShade: TAction;
   Shade1: TMenuItem;
   ShowGaussCurvature: TAction;
   Gausscurvature1: TMenuItem;
   ShowDevelopablity: TAction;
   Developablitycheck1: TMenuItem;
   Print1: TMenuItem;
   SaveAsBitmap: TAction;
   Saveimage1: TMenuItem;
   ShadeZebra: TAction;
   Zebrashading1: TMenuItem;
   ImportBackGround: TAction;
   Backgroundimage1: TMenuItem;
   BackgroundOrigin: TAction;
   Backgroundimage2: TMenuItem;
   Origin1: TMenuItem;
   BackgroundScale: TAction;
   Setscale1: TMenuItem;
   BackgroundTransparentColor: TAction;
   Transparentcolor1: TMenuItem;
   Backgroundclear: TAction;
   Clear1: TMenuItem;
   BackgroundBlending: TAction;
   Blending1: TMenuItem;
   BackgroundExport: TAction;
   Export1: TMenuItem;
   BackgroundTolerance: TAction;
   Tolerance1: TMenuItem;
   BackgroundVisible: TAction;
   Visible1: TMenuItem;

   //FreeHullForm: TFreeHullForm;

   procedure BackgroundFrameExecute(Sender: TObject);
   procedure FormDestroy(Sender: TObject);
   procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
   procedure FormKeyPress(Sender: TObject; var Key: char);
   procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
   procedure FrameClick(Sender: TObject);
//   procedure ScrollBar1Change(Sender: TObject);
//   procedure ScrollBar1Enter(Sender: TObject);
//   procedure ScrollBar2Change(Sender: TObject);
//   procedure ScrollBar2Enter(Sender: TObject);
   procedure SetLightExecute(Sender: TObject);
   procedure ViewportRequestExtents(Sender: TObject; var Min,Max: T3DCoordinate);
   procedure ViewportRedraw(Sender: TObject);
   procedure FormActivate(Sender: TObject);
   procedure FormCreate(Sender: TObject);
   procedure FormClose(Sender: TObject; var aAction: TCloseAction);
   procedure PopupMenuHullPopup(Sender: TObject);
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
   procedure PrintExecute(Sender: TObject);
   procedure ShowWireFrameExecute(Sender: TObject);
   procedure ShowFlatShadeExecute(Sender: TObject);
   procedure ShowGaussCurvatureExecute(Sender: TObject);
   procedure ShowDevelopablityExecute(Sender: TObject);
   procedure SaveAsBitmapExecute(Sender: TObject);
   procedure ViewportKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
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

private    { Private declarations }
   FOnClose: TCloseEvent;   ///+++
   FLCLVersion : string;
   FFormState : TFormState;
   FFreeShip         : TFreeShip;
   FPanned           : Boolean;  // Private variable from which can be seen if the popup menu has to be shown or not
   FInitialPosition  : TPoint;   // Initial position of the mouse cursor when the left or right button was pressed
   FAllowPanOrZoom   : Boolean;  // Flag to check whether panning or zooming is allowed or not (not when an item has just been selected)

   procedure FSetFreeShip(Val:TFreeShip);
   function FCaptionText:string;
   procedure CreateFreeViewport();
   // procedure CreateComponents;
   // procedure CopyComponentsFromFreeHullForm;
   // protected
   // procedure ProcessResource; virtual;
public     { Public declarations }
  LightDialog:TLightDialog;
  constructor Create(AOwner: TComponent); override;
  //constructor CreateNew(AOwner: TComponent); virtual;
  destructor Destroy; override;
  procedure SetCaption;
  procedure UpdateMenu;
  property FreeShip:TFreeShip read FFreeShip write FSetFreeShip;
//  property OnClose: TCloseEvent read FOnClose write FOnClose;
published
  property Caption;
  property Color;
  property LCLVersion:string read FLCLVersion write FLCLVersion;
  property PopupMenu;
  property ClientHeight;
  property ClientWidth;
  property FormStyle;
  property OnClose;
  property OnCreate;
  property OnKeyPress;
  property OnKeyUp;
  property OnShow;
  property Position;
end;

var FreeHullWindow: TFreeHullWindow;

implementation
uses main;

{$R *.lfm}

function Hex2Bin(hex:PChar):Pchar;
var len:integer;
begin
  len:=length(hex) div 2;
  result:=getmem(len);
  HexToBin(hex, result, len);
end;

//{$I freehullformwindow_panel.inc}

constructor TFreeHullWindow.Create(AOwner: TComponent);
begin inherited Create(AOwner); if assigned(OnCreate) then OnCreate(Self);
end;

destructor TFreeHullWindow.Destroy;
begin if assigned(ViewPort) then FreeAndNil(ViewPort); inherited;
end;

function TFreeHullWindow.FCaptionText:string;
begin
   Case Viewport.ViewType of
      fvBodyplan     : Result:='Bodyplan';
      fvProfile      : Result:='Profile';
      fvPlan         : Result:='Plan';
      fvPerspective  : Result:='Perspective';
      else Result:='';
   end;
end;

procedure TFreeHullWindow.SetCaption; begin Caption:=FCaptionText; end;

procedure TFreeHullWindow.FSetFreeShip(Val:TFreeShip);
begin
   if Val<>FFreeShip then begin
      if FFreeShip<>nil then begin // Disconnect from Freeship component
         FFreeShip.DeleteViewport(Viewport);
      end;
      FFreeShip:=Val;
      if FFreeShip<>nil then begin // Connect to Freeship component
         FFreeShip.AddViewport(Viewport);
      end;
   end;  // FreeHullForm.FreeShip := FreeShip;
end;

procedure TFreeHullWindow.UpdateMenu;
begin  // Update all menuitems and action
   Print.Enabled:=(Viewport.ViewportMode=vmWireframe) and (Printer<>nil);
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
   BackgroundTransparentColor.Enabled:= BackgroundOrigin.Enabled;
   BackgroundScale.Enabled           := BackgroundOrigin.Enabled;
   BackgroundBlending.Enabled        := BackgroundOrigin.Enabled;
   BackgroundExport.Enabled          := BackgroundOrigin.Enabled;
   BackgroundFrame.Enabled           := BackgroundBlending.Enabled;
   BackgroundTolerance.Enabled:=(Viewport.ViewType<>fvPerspective) and
                                (Viewport.BackgroundImage.Bitmap<>nil) and
                                (Viewport.BackgroundImage.Visible) and
                                (Viewport.BackgroundImage.ShowInView=Viewport.ViewType) and
                                (Viewport.BackgroundImage.Transparent);
   BackgroundVisible.Checked:=Viewport.BackgroundImage.Visible;
   BackgroundVisible.Enabled:=(Viewport.ViewType<>fvPerspective) and (Viewport.BackgroundImage.Bitmap<>nil) and (Viewport.BackgroundImage.ShowInView=Viewport.ViewType);
end;

procedure TFreeHullWindow.ViewportRequestExtents(Sender: TObject; var Min,Max: T3DCoordinate);
begin
   if FreeShip<>nil then begin
      Freeship.Extents( Min,Max );
      if Viewport.ViewType=fvBodyPlan then //Min.Y:= -Max.Y;
        if -Min.Y > Max.y then Max.Y := -Min.Y
                          else Min.Y := -Max.Y;
   end;
end;

procedure TFreeHullWindow.FormDestroy( Sender: TObject ); begin end;

procedure TFreeHullWindow.FormKeyDown( Sender: TObject; var Key: Word; Shift: TShiftState );
begin ViewportKeyDown( Sender, Key, Shift ); end;

procedure TFreeHullWindow.FormKeyPress(Sender: TObject; var Key: char);
begin ViewportKeyPress( Sender, Key ); end;

procedure TFreeHullWindow.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin ViewportKeyUp(Sender, Key, Shift); end;

procedure TFreeHullWindow.FrameClick(Sender: TObject); begin end;

//procedure TFreeHullWindow.ScrollBar1Change(Sender: TObject);begin SetActive(true); end;
//procedure TFreeHullWindow.ScrollBar1Enter(Sender: TObject);begin SetActive(true); end;
//procedure TFreeHullWindow.ScrollBar2Change(Sender: TObject);begin SetActive(true); end;
//procedure TFreeHullWindow.ScrollBar2Enter(Sender: TObject);begin SetActive(true); end;

procedure TFreeHullWindow.SetLightExecute(Sender: TObject);
begin
  if not assigned(LightDialog) then begin
    LightDialog:=TLightDialog.Create(self);
    LightDialog.ViewPort := self.Viewport;
    LightDialog.Show;
  end else begin
    if not LightDialog.IsVisible then LightDialog.Show;
    LightDialog.BringToFront;
    LightDialog.SetFocus;
  end;
end;

procedure TFreeHullWindow.ViewportRedraw( Sender: TObject );
begin if (FreeShip<>nil) and FreeShip.ModelIsLoaded
      then FreeShip.DrawToViewport( Viewport );
end;

procedure TFreeHullWindow.CreateFreeViewport();
begin
  Viewport := TFreeViewport.Create( Self );
  with Viewport do begin
    Parent := Self;                               // redirected to ClientPanel;
    Cursor := crCross;
    Left := 0;
    Height := 270;
    Top := 0;
    Width := 425;
    Angle := 20;
    Align := alClient;
    BackgroundImage.Alpha := 255;
    BackgroundImage.Owner := Viewport;
    BackgroundImage.Quality := 100;
    BackgroundImage.Scale := 1;
    BackgroundImage.ShowInView := fvBodyplan;
    BackgroundImage.Tolerance := 5;
    BackgroundImage.Transparent := False;
    BackgroundImage.TransparentColor := clBlack;
    BackgroundImage.Visible := True;
    BevelInner := bvNone;
    BevelOuter := bvNone;
    BorderStyle := bsNone;                                         // bsSingle;
    BorderWidth := 0;
    CameraType := ftStandard;                             // Color := 10461087;
    ParentColor := true;
    DoubleBuffer := True;
    Elevation := 20;
//    HorScrollbar := ScrollBar1;
    Margin := 1;
    PopupMenuHull := PopupMenuHull;
//    VertScrollbar := ScrollBar2;
    ViewType      := fvPerspective;  // fvBodyplan;    //
    ViewportMode  := vmWireFrame;    // vmShade; //

    OnChangeBackground := @ViewportChangeBackground;
    OnChangeViewType   := @ViewportChangeViewType;
    OnKeyPress         := @ViewportKeyPress;
    OnKeyDown          := @ViewportKeyDown;
    OnKeyUp            := @ViewportKeyUp;
    OnMouseDown        := @ViewportMouseDown;
    OnMouseUp          := @ViewportMouseUp;
    OnMouseMove        := @ViewportMouseMove;
    OnMouseLeave       := @ViewportMouseLeave;
    OnRedraw           := @ViewportRedraw;
    OnRequestBackgroundImage := @ViewportRequestBackgroundImage;
    OnRequestExtents := @ViewportRequestExtents;
  end;
end;

procedure TFreeHullWindow.FormActivate(Sender: TObject); begin end;

procedure TFreeHullWindow.FormCreate(Sender: TObject);
var o:TObject;
begin
  CreateFreeViewport;
//   CreateComponents;
//   ScrollBar1.Position:=Round(Viewport.Angle);
//   ScrollBar2.Position:=Round(Viewport.Elevation);
//   if ScrollBar1.OnEnter = nil then ScrollBar1.OnEnter := @ScrollBar1Enter;
   FAllowPanOrZoom:=False;
   FreeShip:=GlobalFreeShip;
   o:=self.PopupMenuHull;
   o:=self.ActionListHull;
   o:=self.ImagesHull;
   o:=self.PrintDialogHull;
end;

procedure TFreeHullWindow.FormClose( Sender: TObject; var aAction: TCloseAction );
    begin Freeship:=nil; aAction:=caFree; end;

procedure TFreeHullWindow.PopupMenuHullPopup(Sender: TObject);
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
    begin SetCaption; end;
procedure TFreeHullWindow.ZoomInExecute(Sender: TObject);
    begin Viewport.ZoomIn; end;
procedure TFreeHullWindow.ZoomExtentsExecute(Sender: TObject);
    begin Viewport.ZoomExtents; end;
procedure TFreeHullWindow.ZoomOutExecute(Sender: TObject);
    begin Viewport.ZoomOut; end;

procedure TFreeHullWindow.ViewportMouseDown
( Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y:Integer );
var Select:Boolean=False; P:T2DCoordinate; Point:T3DCoordinate;
begin
   FInitialPosition.X:=X;
   FInitialPosition.Y:=Y;
   if (ssAlt in Shift) and (Viewport.Viewtype<>fvPerspective) then begin // линии тока
      P:=Viewport.ProjectBackTo2D( FInitialPosition );
      if ( Freeship.Visibility.ModelView=mvBoth )
      and ( Viewport.ViewType=fvBodyplan ) then P.X:=abs(P.X);
      Freeship.Edit.Flowline_Add( P,Viewport.Viewtype );
      (MainForm as TmainForm).UpdateMenu; exit;
   end;
   FPanned:=False;
   if Viewport.ViewportMode = vmWireframe then
      FreeShip.MouseDown( Viewport,Button,Shift,X,Y,Select );
   FAllowPanOrZoom:=not Select;   // An item has just been selected or deselect,
                                  // so do NOT pan or zoom the vieport when the
                                  // user (accidently) moves the mouse
   if (Shift=[ssLeft,ssCtrl]) then begin         // выделение контрольных точек
      Viewport.SelectionFrameRect:=Rect(FInitialPosition.X,FInitialPosition.Y,
                                        FInitialPosition.X,FInitialPosition.Y);
      Viewport.SelectionFrameActive:=true;
   end;
end;

procedure TFreeHullWindow.ViewportMouseMove(Sender: TObject;Shift: TShiftState; X, Y: Integer);
var P    : TPoint;
    P2D  : T2DCoordinate;
    P3D  : T3DCoordinate;
    Str  : string='';
begin
// if (Shift <> []) then => ошибка
// if Viewport.ViewType<>fvPerspective then begin SetFocus;
      P.X:=X;
      P.Y:=Y;
      P2D:=Viewport.ProjectBackTo2D( P );
      if abs(P2D.X)<1e-6 then P2D.X:=0;
      if abs(P2D.X)>1e+6 then P2D.X:=1e+6;
      if abs(P2D.Y)<1e-6 then P2D.Y:=0;
      if abs(P2D.Y)>1e+6 then P2D.Y:=1e+6;
      Case Viewport.ViewType of
         fvBodyplan: Str:='Bodyplan.  Y='+FloatToStrF(P2D.X,ffFixed,4,2)+'  Z='+FloatToStrF(P2D.Y,ffFixed,4,2);
         fvProfile : Str:='Profile.  X='+FloatToStrF(P2D.X,ffFixed,4,2)+'  Z='+FloatToStrF(P2D.Y,ffFixed,4,2);
         fvPlan    : Str:='Plan.  X='+FloatToStrF(P2D.X,ffFixed,4,2)+'  Y='+FloatToStrF(P2D.Y,ffFixed,4,2);
         fvPerspective: begin
         { Str:=format('Perspective. Pan.X=%d Pan.Y=%d Elevation=%6.2f Rotation=%6.2f Zoom=%6.4f Scale=%6.3f',
             [Viewport.Pan.X,Viewport.Pan.Y,Viewport.Elevation,Viewport.Angle,Viewport.Zoom,Viewport.Scale] );
         } P3D := Viewport.ProjectBack( Point(X,Y),ZERO );
           Str:=format('Perspective.  X=%-4.2f  Y=%-4.2f  Z=%-4.2f',[P3D.X,P3D.Y,P3D.Z]);
         end else Str:='';
      end; Caption:=Str;
// end;
   if (Shift=[ssLeft]) and (FAllowPanOrZoom) then begin // Zoom in or zoom out
      if (Viewport.ViewType<>fvPerspective) and (abs(FInitialPosition.Y-Y)>4)
      then begin
         if Y<FInitialPosition.Y then begin Viewport.ZoomIn; end else
         if Y>FInitialPosition.Y then begin Viewport.ZoomOut; end;
         FInitialPosition.X:=X;
         FInitialPosition.Y:=Y;
      end;                         // Pan the window left, right, top or bottom
   end else if (Shift = [ssRight]) and (FAllowPanOrZoom) then begin
      if (abs(FInitialPosition.X-X)>4) or (abs(FInitialPosition.Y-Y)>4) then begin
         P.X:=Viewport.Pan.X+X-FInitialPosition.X;
         P.Y:=Viewport.Pan.Y+Y-FInitialPosition.Y;
         Viewport.Pan:=P;
         FPanned:=True;
         FInitialPosition.X:=X;
         FInitialPosition.Y:=Y;
      end;
   end else
   if (Shift=[ssLeft,ssCtrl]) then begin                // Draw selection frame
      if (abs(FInitialPosition.X-X)>4) or (abs(FInitialPosition.Y-Y)>4) then begin
         Viewport.SelectionFrameRect:=Rect(FInitialPosition.X,FInitialPosition.Y,X,Y);
      // Viewport.Rectangle( FInitialPosition.X,FInitialPosition.Y, X,Y );
      end;
    end
  else if Assigned(FFreeShip) then FFreeShip.MouseMove(Viewport,Shift,X,Y);
end;

procedure TFreeHullWindow.ViewportMouseUp(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var P:TPoint;
begin
   if Button=mbRight then
   begin
      // Tracing:=false;
      // Only show pop-up menu if user has not panned the viewport (with right mouse-button)
      if FPanned then begin FPanned:=False; end else begin
         P.X:=X;
         P.Y:=Y;
         P:=Viewport.ClientToScreen( P );
         PopupMenuHull.Popup( P.X,P.Y );
      end;
   end;                                              // Reset the pan/zoom flag
   FAllowPanOrZoom:=True;
   if Viewport.SelectionFrameActive then begin
      Freeship.SelectPointsInFrame( Viewport, Viewport.SelectionFrameRect );
      Viewport.SelectionFrameActive:=false;
   end;
   Freeship.MouseUp(Viewport,Shift,X,Y);
end;

procedure TFreeHullWindow.DeselectAllExecute(Sender: TObject);
begin FreeShip.Edit.Selection_Clear; end;

procedure TFreeHullWindow.ViewportMouseLeave(Sender: TObject);
begin            // stop panning or zooming when the cursor leaves the viewport
   FAllowPanOrZoom:=False;   // And remove the cursor location from the caption
   SetCaption;               // DeActivate;
end;

procedure TFreeHullWindow.PrintExecute(Sender: TObject);
begin
   if Viewport.Width>Viewport.Height then Printer.Orientation:=poLandscape
                                     else Printer.Orientation:=poPortrait;
   if PrintDialogHull.Execute then Viewport.Print(FreeShip.ProjectSettings.ProjectUnits,Viewport.ViewType<>fvPerspective,'FREE!ship '+FCaptiontext);
end;

procedure TFreeHullWindow.ShowWireFrameExecute(Sender: TObject);
    begin Viewport.ViewportMode:=vmWireframe; end;
procedure TFreeHullWindow.ShowFlatShadeExecute(Sender: TObject);
    begin Viewport.ViewportMode:=vmShade; end;
procedure TFreeHullWindow.ShowGaussCurvatureExecute(Sender: TObject);
    begin Viewport.ViewportMode:=vmShadeGauss; end;
procedure TFreeHullWindow.ShowDevelopablityExecute(Sender: TObject);
    begin Viewport.ViewportMode:=vmShadeDevelopable; end;

procedure TFreeHullWindow.SaveAsBitmapExecute(Sender: TObject);
var Str,vpt: string;
begin
  Case Viewport.ViewType of
     fvBodyplan     : vpt:='_Bodyplan';
     fvProfile      : vpt:='_Profile';
     fvPlan         : vpt:='_Plan';
     fvPerspective  : vpt:='_Perspective';
     else vpt:='';
  end;
  Str:=Freeship.Preferences.ExportDirectory + DirectorySeparator
     + ChangeFileExt( ExtractFilename( Freeship.Filename )+vpt,'.png' );
  Viewport.SaveAsBitmap( Str,true );
end;

procedure TFreeHullWindow.ViewportKeyDown
( Sender:TObject; var Key:Word; Shift:TShiftState );
begin
   if not Viewport.Focused then Viewport.SetFocus;
   Freeship.KeyDown(Sender,Key,Shift);
end;

procedure TFreeHullWindow.ViewportKeyUp(Sender: TObject; var Key: Word;Shift: TShiftState);
    begin Freeship.KeyUp(Sender,Key,Shift); end;
procedure TFreeHullWindow.ViewportKeyPress(Sender: TObject; var Key: Char);
    begin if key=#27 then DeselectAllExecute(self); end;
procedure TFreeHullWindow.ShadeZebraExecute(Sender: TObject);
    begin Viewport.ViewportMode:=vmShadeZebra; UpdateMenu; end;
procedure TFreeHullWindow.ImportBackGroundExecute(Sender: TObject);
    begin if Freeship<>nil then Freeship.Edit.BackgroundImage_Open(Viewport); end;
procedure TFreeHullWindow.BackgroundOriginExecute(Sender: TObject);
    begin Viewport.BackgroundMode:=emSetOrigin; end;
procedure TFreeHullWindow.BackgroundScaleExecute(Sender: TObject);
    begin Viewport.BackgroundMode:=emSetScale; end;
procedure TFreeHullWindow.BackgroundFrameExecute(Sender: TObject);
    begin Viewport.BackgroundMode:=emSetFrame; Viewport.Invalidate; end;
procedure TFreeHullWindow.BackgroundTransparentColorExecute(Sender: TObject);
    begin Viewport.BackgroundMode:=emSetTransparentColor; end;
procedure TFreeHullWindow.BackgroundBlendingExecute(Sender: TObject);
    begin Viewport.BackgroundImage.SetBlendingValue; end;

procedure TFreeHullWindow.BackgroundclearExecute(Sender: TObject);
begin
   if (Viewport.BackgroundImage.Bitmap<>nil) and (Viewport.BackgroundImage.Visible)
   then begin if Freeship<>nil then Freeship.Edit.BackgroundImage_Delete(Viewport);
   end;
end;

procedure TFreeHullWindow.ViewportRequestBackgroundImage(Sender: TObject);
var I:Integer; Data:TFreeBackgroundImageData; Pt:TPoint;
begin
   if Freeship<>nil then begin
      Data:=nil;
      for I:=1 to Freeship.NumberofBackgroundImages do if Freeship.BackgroundImage[I-1].AssignedView=Viewport.ViewType then
         Data:=Freeship.BackgroundImage[I-1];
      if Data<>nil then Viewport.BackgroundImage.AssignData(Data.Image,Data.AssignedView,Data.Origin,Data.Scale,Data.Transparent,Data.TransparentColor,Data.BlendingValue,Data.Quality,Data.Tolerance,True)
                   else if Viewport.BackgroundImage.Bitmap<>nil then begin
         Pt.X:=0;
         Pt.Y:=0;
         Viewport.BackgroundImage.AssignData(nil,fvPerspective,Pt,1.0,False,clBlack,255,100,3,True);
      end;
   end;
end;

procedure TFreeHullWindow.ViewportChangeBackground(Sender: TObject);
var I:Integer;
begin
   for I:=1 to Freeship.NumberofBackgroundImages do
   if Freeship.BackgroundImage[I-1].AssignedView=Viewport.ViewType then begin
      Freeship.Edit.CreateUndoObject( 'Background image settings',true);
      Freeship.BackgroundImage[I-1].UpdateData(Viewport);  Break;
   end;
end;

procedure TFreeHullWindow.BackgroundExportExecute(Sender: TObject);
begin Viewport.BackgroundImage.Save; end;

procedure TFreeHullWindow.BackgroundToleranceExecute(Sender: TObject);
var Str:Ansistring; Value,I:Integer;
begin
   Str:=IntToStr(Viewport.BackgroundImage.Tolerance);
   if InputQuery('Transparency tolerance','Set tolerance (0-255)',Str) then begin
      val( Str,Value,I );
      if I=0 then begin
         if Value<0   then value:=0 else
         if Value>255 then value:=255;
         Viewport.BackgroundImage.Tolerance:=Value;
      end else MessageDlg( 'Invalid value',mtError,[mbok],0)
   end;
end;

procedure TFreeHullWindow.BackgroundVisibleExecute(Sender: TObject);
begin Viewport.BackgroundImage.Visible:=not Viewport.BackgroundImage.Visible; end;

end.
