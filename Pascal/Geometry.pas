unit Geometry;
interface uses
     Windows,SysUtils,Classes,Graphics,Controls,Forms,
     Math,Dialogs,StdCtrls,StrUtils,LazFileUtils,LazUTF8, //LConvEncoding,
     ExtCtrls,STypes,FasterList,FileBuffer,VersionUnit;
const
     IncrementSize=25; // amount of points which is automaticly allocated extra memory for
     Decimals=4;       // When weilding points together this is the accuracy for comparing points
     ZBufferScaleFactor=1.004; // Offset for hidden-line drawing when drawing ontop of shaded triangles
     Zoomfactor=1.02;
type TShadePoint = record  // Used for drawing to the Z-buffer
        X,Y: Integer; Z: Real;
        R,G,B: Integer;
     end;
     TLayerProperties= record
        SurfaceArea: Real;
        Weight: Real;
        SurfaceCenterOfGravity: Vector;
     end;
     TVertexType= (svRegular,svCrease,svDart,svCorner); // Different types of subdivisionvertices
     TCameraType= (ftWide,ftStandard,ftShortTele,ftMediumTele,ftFarTele);
  // Different types of camera lenses, corresponding to focalpoints 20,50,90,130 и 200 mm
     TViewType  = (fvBodyplan,fvProfile,fvPlan,fvPerspective);
     TUnitType  = (fuMetric,fuImperial); // Switch between metric and imperial units
     TViewportmode= (vmWireFrame,vmShade,vmShadeGauss,vmShadeDevelopable,vmShadeZebra);
     SMode= (fmQuadTriangle,fmCatmullClark);
     TAssembleMode= (amRegular,amNURBS);
     TViewportBackgroundMode= (emNormal,emSetOrigin,emSetScale,emSetTransparentColor);
     TLight = record
        Position : Vector; // position of light in world
        Luminance: byte;   // brightness
        Ambient  : byte
     end;
type SBase        = class;
     SSurface     = class;
     SPoint       = class;
     SEdge        = class;
     SFace        = class;
     SControlPoint= class;
     SControlEdge = class;
     SControlFace = class;
     SLayer       = class;
     TViewport    = class;
     TSpline      = class;
     TBackgroundImage = class;
     TFaceGrid = record
        Faces : array of array of SControlFace;
        NCols : Integer;
        NRows : Integer end;
     TFaceArray       = array of TFaceGrid;
     SGrid = array of array of SPoint;
     TZBufferRow      = RealArray;
     TCoordinateGrid  = array of VectorArray;
     TIntersectionData= record // intersections of a spline with a plane
        NoIntersections: Integer;
        Points         : VectorArray;
        Parameters     : RealArray;
     end;
     // Event from Tviewport, which is raised when the viewport initializes
     // and needs the bounding box of the min/max coordinates of the 3D model
     TOnRequestExtentsEvent=procedure(Sender: TObject;var Min,Max:Vector) of object;
                         // Event raised when the active lyers has been changed
     TChangeActiveLayerEvent=procedure(Sender: TObject;Layer:SLayer) of Object;
     TAlphaBlendData= record
        R,G,B: Byte;
        Alpha: Byte;
        zvalue: Real;
     end;
     TAlphaBlendPixelArray= record
        Number  : Byte;
        Capacity: Byte;
        Data    : array of TAlphaBlendData;
     end;
     TAlphaBlendArray= record
        First,Last:Integer;
        Pixels: array of TAlphaBlendPixelArray;
     end;

TAlphaBuffer= class // Alpha-buffer class used in the shading algorithm
private
   FViewport: TViewport;
   FBuffer: array of TAlphaBlendArray;
   FWidth,FHeight,FFirstRow,FLastRow: Integer;
public
   procedure AddPixelData( X,Y:Integer; R,G,B,Alpha:Byte; Z:Real );
   procedure Initialize;
   procedure Draw;
 end;

TZBuffer = class // Z-buffer class used in the shading algorithm
private
   FViewport: TViewport;
   FBuffer  : array of TZBufferRow;
   FWidth,FHeight: Integer;
public
   procedure Initialize;
end;

TBackgroundImage= class(TPersistent) // Background image properties for use in a viewport
private
   FOwner : TViewport;
   FBitmap: TBitmap;
   FOrigin: TPoint;
   FScale : Real;
   FTransparentColor: TColor;
   FTransparent,FVisible: Boolean;
   FShowInView: TViewType;
   FQuality,FAlpha,FTolerance: Byte;
   procedure FSetAlpha(val:Byte);
   procedure FSetOrigin(val:TPoint);
   procedure FSetTolerance(val:Byte);
   procedure FSetTransparent(val:Boolean);
   procedure FSetTransparentColor(val:TColor);
   procedure FSetVisible(val:Boolean);
public
   procedure AssignData
           ( Image:TGraphic;
              View:TViewType;
            Origin:TPoint;
             Scale:Real;
            Transp:boolean;
         TranspCol:TColor;
         Alpha,Quality,Tolerance:Byte;
             Quiet:Boolean );
   procedure Clear;
   constructor Create(Viewport:TViewport);
   destructor Destroy;                        override;
   procedure Draw;
   function ImageCoordinate(X,Y:Integer):TPoint;
   function TargetRect:TRect;
   procedure Open(InitialDir:String);
   procedure Save;
   procedure SetBlendingValue;
   property Origin: TPoint read FOrigin write FSetOrigin;
published
   property Alpha           : byte read FAlpha write FSetAlpha;
   property Bitmap          : TBitmap read FBitmap;
   property Owner           : TViewport read FOwner;
   property Quality         : byte read FQuality;
   property Scale           : Real read FScale;
   property ShowInView      : TViewType read FShowInView;
   property Tolerance       : Byte read FTolerance write FSetTolerance;
   property Transparent     : Boolean read FTransparent write FSetTransparent;
   property TransparentColor: TColor read FTransparentColor write FSetTransparentColor;
   property Visible         : Boolean read FVisible write FSetVisible;
end;
{
  This is a 3D Canvas used for viewing and drawing
  It also is the userinterface for editing the hullform.
}
TViewport = class( TCustomPanel )       // TFlowPanel )
private
   FAngle,
   FDistance, // The distance from the model to the camera, determined by the field of view
   FElevation,
   FFieldOfView: Real; // The field of view in degrees, default=50 degr. which corresponds with the human eye
// FDoubleBuffer: Boolean; // Double buffering prevents flickering when redrawing the viewport
   FDestinationWidth,           // Destinationwidth of the canvas when not drawing to the screen
   FDestinationHeight: Integer; // DestinationHeight of the canvas when not drawing to the screen
   FMin3D,FMax3D,
   FMidPoint: Vector; // Midpoint of the boundarybox determined by FMin3D and FMax3D. This point is used as centerpoint for rotating the 3D model
   FMargin: Real;    // margin around to viewport to keep clear;
                     // and it also is the direction at which the camera looks
   FBackgroundMode: TViewportBackgroundMode;
   FViewType: TViewType; // Switch to sideview, frontview, topview or perspective view
   FCameraLocation: Vector; // Position of the camera, following from the field of view and the distance of the camera
   FCameraType: TCameraType; // Determines the focalpoint of the camera
   FCosAngle,FSinAngle,      // Pre calculated values to speed-up the rotating of point in the perspective-projection
   FCosElevation,FSinElevation, // Pre calculated values to speed-up the rotating of point in the perspective-projection
   FScale,FZoom,                // Scale for projecting the 2D coordinates to the viewport
   FLightIntensity,FAmbientIntencity: Real;
   FViewportMode: TViewportmode; // Switch between wireframe mode or differentypes of shading
   FOnMouseDown,FOnMouseUp: TMouseEvent;
   FOnMouseMove: TMouseMoveEvent;
   FOnMouseEnter,
   FOnMouseLeave,
   FOnRedraw,
   FOnChangeViewType,
   FOnRequestBackgroundImage: TNotifyEvent;
   FOnRequestExtents: TOnRequestExtentsEvent;
   FScreencenter,FPan,FPreviousPosition,FBackgroundOrigin: TPoint;
   FBackgroundImage: TBackgroundImage;                        // shade data
   FZBuffer        : TZBuffer;
   FAlphaBuffer    : TAlphaBuffer;
   FLight          : TLight;
   FHorScrollbar,FVertScrollbar: TScrollBar;
   FOnChangeBackgroundImage: TNotifyEvent;
   FSelectionFrameRect: TRect;
   FSelectionFrameActive: boolean;
   function  FGetBrushColor:TColor;
   function  FGetBrushStyle:TBrushStyle;
   function  FGetFontColor:TColor;
   function  FGetFontName:string;
   function  FGetFontSize:Integer;
   function  FGetPenColor:TColor;
   function  FGetPenStyle:TPenStyle;
   function  FGetPenWidth:integer;
   procedure FSetAngle(Val:Real);
   procedure FSetBackgroundMode(val:TViewportBackgroundMode);
   procedure FSetBrushColor(Val:TColor);
   procedure FSetBrushStyle(Val:TBrushStyle);
   procedure FSetCameraType(Val:TCameraType);
   procedure FSetElevation(Val:Real);
//(*#*) procedure FSetLight(val: TLight);
   procedure FSetFontColor(Val:TColor);
   procedure FSetFontName(val:string);
   procedure FSetFontSize(val:integer);
   procedure FSetHorScrollbar(val:TScrollbar);
   procedure FSetVertScrollbar(val:TScrollbar);
   procedure FSetMargin(Val:Real);
   procedure FSetPan(Val:TPoint);
   procedure FSetPenColor(Val:TColor);
   procedure FSetPenStyle(Val:TPenStyle);
   procedure FSetPenWidth(Val:integer);
   procedure FSetViewType(Val:TViewType);
   procedure FSetViewportMode(Val:TViewportMode);
   procedure FHorScrollbarChange(sender:TObject);
   procedure FVertScrollbarChange(sender:TObject);
   procedure WMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
   procedure WMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
protected
   procedure Paint; override;
   procedure Resize; override;
   procedure MouseDown(Button:TMouseButton;Shift:TShiftState;X,Y:Integer); override;
   procedure MouseMove(Shift:TShiftState;X,Y:Integer); override;
   procedure MouseUp(Button:TMouseButton;Shift:TShiftState;X,Y:Integer); override;
   function  DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
public
   constructor Create(AOwner:TComponent); override;
   destructor Destroy; override;
   procedure DrawLineToZBuffer(Point1,Point2:Vector;R,G,B:Integer);
   procedure InitializeViewport(Min,Max:Vector);
   function Project( P:Vector ):TPoint;
   function ProjectBack( P:TPoint; Input:Vector ):Vector;
   function ProjectBackTo2D( P:TPoint ):Place; // Takes the cursor position and projects it to 2D object space
   function ProjectToZBuffer(P:Vector):TShadePoint; overload;virtual; // Projects a 3D point to the screen and calculate it's Z-value for the Z-buffer
   function ProjectToZBuffer(Scale:Real;P:Vector):TShadePoint;  reintroduce;overload;// Projects a 3D point with a certain z-buffer offset to the screen, used for drawing lines on top of shaded surfaces
   function RotatedPoint(P:Vector):Vector;
   function RotatedPointBack(P:Vector):Vector;
   procedure SaveAsBitmap( Filename:string; const ShowDialog: boolean=true );
   procedure SetPenWidth(Width:integer);
   Procedure ShadedColor( Dp:Real; R,G,B:byte; var ROut,GOut,BOut:byte );
   procedure ShadeTriFace(P_1,P_2,P_3:Vector;R,G,B:byte;Alpha:byte);             // overload;virtual;
   procedure ShadeTriangles(P_1,P_2,P_3:Vector;R1,G1,B1,R2,G2,B2,R3,G3,B3:byte); // reintroduce;overload;
   procedure ZoomIn;
   procedure ZoomExtents;
   procedure ZoomOut;
   procedure SetSelectionFrameRect(Rect: TRect);
   procedure SetSelectionFrameActive(Val: boolean);
   procedure DrawSelectionFrame; //virtual;
   property AlphaBuffer   : TAlphaBuffer read FAlphaBuffer;
   property BackgroundMode: TViewportBackgroundMode read FBackgroundMode write FSetBackgroundMode;
   property BrushColor    : TColor read FGetBrushColor write FSetBrushColor;
   property BrushStyle    : TBrushStyle read FGetBrushStyle write FSetBrushStyle;
   property CameraLocation: Vector read FCameraLocation;
   property FieldOfView: Real read FFieldOfView;
   property FontColor: TColor read FGetFontColor write FSetFontColor;
   property FontName : string read FGetFontname write FSetFontName;
   property FontSize: integer read FGetFontSize write FSetFontSize;
   property Max3D   : Vector read FMax3D;
   property Min3D   : Vector read FMin3D;
//(*#*) property Light: TLight read FLight write FSetLight;
   property PenColor: TColor read FGetPenColor write FSetPenColor;
   property PenStyle: TPenStyle read FGetPenStyle write FSetPenStyle;
   property PenWidth: integer read FGetPenWidth write FSetPenWidth;
   property Scale   : Real read FScale;
   property ZBuffer : TZBuffer read FZBuffer;
   property Zoom    : Real read FZoom;
   property Pan     : TPoint read FPan write FSetPan;
   property SelectionFrameRect: TRect read FSelectionFrameRect write SetSelectionFrameRect;
   property SelectionFrameActive: boolean read FSelectionFrameActive write SetSelectionFrameActive;
published
   property Angle: Real read FAngle write FSetAngle;
   property Align;
   property BackgroundImage: TBackgroundImage read FBackgroundImage write FBackgroundImage;
{  property BevelInner;
   property BevelOuter;
     property BevelWidth;
   property BorderStyle;
     property BorderWidth;
}  property CameraType: TCameraType read FCameraType write FSetCameraType;
   property Color;
// property DoubleBuffer: boolean read FDoubleBuffer write FDoubleBuffer;
   property Elevation   : Real read FElevation write FSetElevation;
   property HorScrollbar: TScrollBar read FHorScrollbar write FSetHorScrollbar;
   property Margin      : Real read FMargin write FSetMargin;
   property PopupMenu;
   property VertScrollbar: TScrollBar read FVertScrollbar write FSetVertScrollbar;
   property Visible;
   property ViewType    : TViewtype read FViewType write FSetViewType;
   property ViewportMode: TViewportmode read FViewportMode write FSetViewportMode;       // Switch between wireframe mode or differentypes of shading
   property OnChangeBackground: TNotifyEvent read FOnChangeBackgroundImage write FOnChangeBackgroundImage;
   property OnChangeViewType: TNotifyEvent read FOnChangeViewType write FOnChangeViewType;
   property OnKeyDown;
   property OnKeyPress;
   property OnKeyUp;
   property OnMouseDown : TMouseEvent read FOnMouseDown write FOnMouseDown;
   property OnMouseUp   : TMouseEvent read FOnMouseUp   write FOnMouseUp;
   property OnMouseMove : TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
   property OnMouseEnter: TNotifyEvent read FOnMouseEnter write FOnMouseEnter;
   property OnMouseLeave: TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
   property OnMouseWheel;
   Property OnResize;
   property OnRedraw: TNotifyEvent read FOnRedraw write FOnRedraw;
   property OnRequestBackgroundImage: TNotifyEvent read FOnRequestBackgroundImage
                                                  write FOnRequestBackgroundImage;
   property OnRequestExtents: TOnRequestExtentsEvent read FOnRequestExtents
                                                    write FOnRequestExtents;
end;

TDevelopedPatch = class  // Unrolled Subdivision control face
Private
   FOwner: SLayer;
   FName: string;
   FConnectedMirror: TDevelopedPatch;
   FPoints,        // All original 3D points
   FEdges,         // All original edges
   FDoneList,      // List containing developed faces in chronological order
   FBoundaryEdges, // All edges forming the boundary edges of the developed plate, sorted in the correct order
   FStations,
   FWaterlines,
   FButtocks,
   FDiagonals,
   FCorners: TFasterList; // contains all cornerpoints for dimensioning reasons
   FRotation         : Real;
   FMirrorPlane      : Plate;
   FMirror           : Boolean;
   FMin2D,FMax2D     : Place;
   FTranslation      : Place;
   FMaxAreaError     : Real;
   FTotalAreaError   : Real;
   FXGrid,FYGrid,FCos,FSin: Real;
   F2DCoordinates    : array of Place; //TUnrolledPoint;
   FEdgeErrors       : RealArray;                         // Visibility options
   FMirrorOnScreen   : Boolean;
   FNoIterations     : Integer;
   function FGetMidPoint:Place;
   function FGetMinError:Real;
   function FGetMaxError:Real;
   function FGetMirrorPoint(index:Integer):Vector;
   function FGetPoint(index:Integer):Vector;
   procedure FSetRotation(Val:Real);
   procedure FSetTranslation(Val:Place);
   procedure FSetMirrorOnScreen(val:Boolean);
public
   Units: TUnitType;
   XGrid,YGrid: Real;
   Visible,
   ShadeSubmerged,
   ShowBoundingBox,   // Draws a boundary box around the surface
   ShowButtocks,
   ShowDiagonals,
   ShowDimensions,
   ShowInteriorEdges, // Draw the interior edges (none crease edges)
   ShowPartName,      // draws the name of the surface at the center
   ShowSolid,         // Fills the surface with the layer color
   ShowStations,
   ShowWaterlines,
   ShowErrorEdges: boolean;

   constructor Create(Owner:SLayer);
   destructor Destroy; override;
   procedure Assign(Org:TDevelopedPatch;Mirror:Boolean);
   procedure Clear;
   function ConvertTo3D(P:Place):Vector;
   function DistanceToCursor(X,Y:Integer;Viewport:TViewport):integer;
   procedure Draw(Viewport:TViewport);
   procedure Extents(var Min,Max:Vector);
   procedure IntersectPlane(Plane:Plate;Color:TColor);
   procedure SaveToDXF(Strings:TStringList);
   procedure SaveToTextFile(Strings:TStringList);
   procedure Unroll(ControlFaces:TFasterList);
   property MaxAreaError         : Real read FMaxAreaError;
   property MaxError             : Real read FGetMaxError;
   property MidPoint             : Place read FGetMidPoint;
   property MinError             : Real read FGetMinError;
   property MirrorOnScreen       : boolean read FMirrorOnScreen write FSetMirrorOnScreen;
   property Name                 : string read FName write FName;
   property NoIterations   : Integer read FNoIterations;
   property Owner                : SLayer read FOwner;
   property MirrorPoint[index:Integer] : Vector read FGetMirrorPoint;
   property Point[index:Integer] : Vector read FGetPoint;
   property Rotation             : Real read FRotation write FSetRotation;
   property TotalAreaError       : Real read FTotalAreaError;
   property Translation          : Place read FTranslation write FSetTranslation;

end;

TEntity = class // This is the base class of all 3D entities in the project
private
   FBuild   : Boolean;   // Flag to check if the entity has already been build
   FMin,FMax: Vector; // The min/max boundary coordinates of the entity after it has been build
   FPenWidth: byte;      // Pen thickness to use when drawing
   FColor   : TColor;    // Color when drawing
   FPenstyle: TPenStyle; // Pen style for drawing the line
   function  FGetMin:Vector; virtual;
   function  FGetMax:Vector; virtual;
   procedure FSetBuild(Val:Boolean); virtual;
public
   constructor Create; virtual;
   procedure   Clear; virtual;
   destructor  Destroy; override;
   procedure   Extents(Var Min,Max : Vector); virtual;
   procedure   Draw(Viewport:TViewport); virtual;
   procedure   Rebuild; virtual;
   property    Build   : Boolean read FBuild write FSetBuild;
   property    Color   : TColor read FColor write FColor;
   property    Min     : Vector read FGetMin;
   property    Max     : Vector read FGetMax;
   property    PenStyle: TPenStyle read FPenStyle write FPenStyle; // Pen style
   property    PenWidth: byte read FPenWidth write FPenWidth; // Pen thickness when drawing on screen
end;
{
  3D CSpline
  Copied from page 107 of the book: "Numerical recipes in fortan 77"
  Url: http://www.library.cornell.edu/nr/bookfpdf/f3-3.pdf
  Modified to use centripetal parametrisation for smoother
  interpolation and to accept knuckles in the controlpoints
}
TSpline = class(TEntity)
   FCapacity,   // Number of points for which memory has been allocated
   FFragments,  // Number of straight-line segments used when drawing the curve
   nS: Integer; // Actual number of points present
   FShowCurvature,
   FShowPoints: Boolean;
   FTotalLength: Real;           // or decrease the scale of the curvature plot
   FPoints,FDerivatives: VectorArray;     // Array containing all controlpoints
   FParameters: RealArray;
   FKnuckles: array of boolean;
   procedure FSetCapacity(Val:Integer);
   function FGetFragments:Integer;              procedure FSetFragments(Val:Integer);
   function FGetPoint(Index:Integer):Vector;    procedure FSetPoint(Index:Integer;P:Vector);
   function FGetKnuckle(Index:integer):Boolean; procedure FSetKnuckle(Index:integer;Value:Boolean);
   function FGetParameter(Index:integer):Real;
   procedure FSetBuild(val:boolean); override;
public
   procedure   Add(P:Vector); // add a new point to the curve
   procedure   Assign(Spline:TSpline); // Copy all data from another spline
   function    CoordLength(T1,T2:Real):Real;
   function    ChordlengthApproximation(Percentage:Real):Real;
   procedure   Clear; override;
   constructor Create; override;
// function    GetValues: VectorArray;
   function    Curvature(Parameter:Real;var Value,Normal:Vector):Real;
   procedure   DeletePoint(Index:Integer);
   function    DistanceToCursor(X,Y:Integer;Viewport:TViewport):integer;virtual;
   procedure   Draw(Viewport:TViewport); override;
   function    FirstDerive(Parameter:Real):Vector;
   procedure   Insert(Index:Integer;P:Vector);
   procedure   InsertSpline(Index:Integer;Invert,DuplicatePoint:Boolean;Source:TSpline);
   function    IntersectPlane(Plane:Plate;var Output:TIntersectionData):Boolean;
   procedure   InvertDirection; // invert the direction of the controlpoints and knuckles
   procedure   LoadBinary(Source:TFileBuffer); virtual;
   procedure   Rebuild; override;
   procedure   SaveBinary(Destination:TFileBuffer); virtual;
   procedure   SaveToDXF(Strings:TStringList;Layername:string;SendMirror:Boolean);
   function    SecondDerive(Parameter:Real):Vector;
   function    Simplify(Criterium:Real):Boolean; // Remove points that do not contribute significantly to the shape
   function    Value( Parameter:Real ):Vector;
   property    Capacity                : Integer read FCapacity write FSetCapacity;
   property    Point[Index:Integer]    : Vector read FGetPoint write FSetPoint;
   property    Fragments               : integer read FGetFragments write FSetFragments;
   property    Knuckle[Index:integer]  : Boolean  read FGetKnuckle write FSetKnuckle;
   property    Parameter[Index:integer]: Real read FGetParameter;
   property    ShowCurvature           : Boolean read FShowCurvature write FShowCurvature;
   property    ShowPoints              : boolean read FShowPoints write FShowPoints;
   property    TotalLength             : Real read FTotalLength;
end;

TNURBSurface  = class(TEntity)
   ColCount,
   RowCount: Integer;
private
   FColCapacity,
   FRowCapacity,
   FColDegree,
   FRowDegree: Integer;
   FColKnots,
   FRowKnots: RealArray;
   FControlPoints: TCoordinateGrid;
   function  FGetpoint(Col,Row:Integer):Vector;
   procedure FSetColDegree(Val:Integer);
   procedure FSetRowDegree(Val:Integer);
   procedure FSetPoint(Col,Row:Integer;Val:Vector);
   procedure FSetColCapacity(Val:integer);
   procedure FSetRowCapacity(Val:integer);
protected
public
   procedure Clear; override;
   procedure DeleteColumn(Col:Integer);
   procedure DeleteRow(Row:Integer);
   procedure InsertColKnot(U:Real);
   procedure InsertRowKnot(V:Real);
   procedure Rebuild; override;
   procedure SetCapacity(Col,Row:integer);
   procedure SetDefaultColKnotvector;
   procedure SetDefaultRowKnotvector;
   procedure SetUniformColKnotvector;
   procedure SetUniformRowKnotvector;
   property  ColCapacity  : integer read FColCapacity write FSetColCapacity;
   property  ColDegree    : integer read FColDegree write FSetColDegree;
   property  ColKnotVector: RealArray read FColknots;
   property  Point[Col,Row:Integer]: Vector read FGetpoint write FSetPoint;
   property  RowCapacity  : integer read FRowCapacity write FSetRowCapacity;
   property  RowDegree    : integer read FRowDegree write FSetRowDegree;
   property  RowKnotVector: RealArray read FRowknots;
end;

{ SBase is the base class      }
{ for all subdivision points, edges and faces }

SBase = class
   Owner: SSurface;
public
   constructor Create( Own: SSurface ); virtual;
end;

{ Controlcurves are curves that can be added to the controlnet an are subdivide with the surface. }
{ The resulting curve therefore lies on the surface, and can be used in the fairing process       }

SControlCurve = class(SBase)
private
   FCurve: TSpline;
   FBuild,FVisible: Boolean;
   FControlPoints,FSubdividedPoints: TFasterList;
   function FGetColor:TColor;
   function FGetNoControlPoints:Integer;
   function FGetControlPoint(Index:Integer):SControlPoint;
   function FGetSelected:Boolean;
   function FGetVisible:Boolean;
   procedure FSetBuild(Val:Boolean);
   procedure FSetSelected(val:Boolean);
public
   procedure AddPoint(P:SPoint);
   procedure Clear;
   constructor Create(Owner:SSurface); override;
   procedure Delete;
   procedure DeleteEdge(Edge:SControlEdge);
   destructor Destroy; override;
   function DistanceToCursor(X,Y:Integer;Viewport:TViewport):integer;
   procedure Draw(Viewport:TViewport);
   procedure InsertControlPoint(P1,P2,New:SControlPoint);
   procedure InsertEdgePoint(P1,P2,New:SPoint);
   procedure LoadBinary(Source:TFileBuffer);
   procedure ReplaceVertexPoint(Old,New:SPoint);
   procedure SaveBinary(Destination:TFileBuffer);
   procedure SaveToDXF(Strings:TStringList);
   property Build: Boolean read FBuild write FSetBuild;
   property Color: TColor read FGetColor;
   property Curve: TSpline read FCurve;
   property NoControlPoints: Integer read FGetNoControlPoints;
   property ControlPoint[index:Integer]: SControlPoint read FGetControlPoint;
   property Selected: boolean read FGetSelected write FSetSelected; // Property to see if this edge has been selected by the user
   property Visible: Boolean read FGetVisible write FVisible;
 end;

{ SLayer is a layer-type class                                       }
{ All individual controlfaces can be assigned to a leyer. Properties such as color, } 
{ visibility etc. are common for all controlfaces belonging the the same layer      }

SLayer = class // color, visibility, symmetric, calc intersections/part of hull
   Owner: SSurface;     // Pointer to the subdivisionsurface
private
   FColor  : TColor;    // Color of this layer
   FVisible: boolean;   // Visibility switch
   FDescription: string;// Description of the layer, used as user identification
   FSymmetric,          // Symmetric patches are mirrored in the centerplane when both halves of the St are drawn
   FDevelopable,        // Developable layers are shaded with Gauss curvature
   FUseForIntersections,// If set to true, stations, waterlines, buttocks and diagonals are calculated
   FUseInHydrostatics,  // If set to true, the panels of this layer will be used for hydrostatic calculations
   FShowInLinesplan: boolean; // Flag to hide or show this layer in the linesplan
   FPatches: TFasterList; // List containing all controlpatches
   function  FGetColor:TColor;
   function  FGetCount:Integer;
   function  FGetDXFLayername:string;
   function  FGetName:string;
   function  FGetItems(Index:Integer):SControlFace;
   function  FGetLayerIndex:Integer;
   function  FGetSurfaceProperties:TLayerProperties;
   procedure FSetFDevelopable(Val:Boolean);
   procedure FSetName(Val:String);
   procedure FSetColor(Val:TColor);
   procedure FSetShowInLinesplan(val:boolean);
   procedure FSetUseInHydrostatics(val:boolean);
   procedure FSetUseForIntersections(val:Boolean);
   procedure FSetVisible(Val:Boolean);
   procedure FSetSymmetric(Val:Boolean);
public
   LayerID: integer; // Unique identification number for internal references
   MaterialDensity,  // Density of material used to calculate the weight of the surface
   Thickness: Real; // Also used for weight calculation
   AlphaBlend: Byte;
   procedure AddControlFace(ControlFace:SControlFace);
   procedure AssignProperties(Source:SLayer);
   function CalculateIntersectionPoints(Layer:SLayer):Boolean;
   constructor Create( Own:SSurface );
   procedure Clear;
   function  Delete:Boolean;
   procedure DeleteControlFace(ControlFace:SControlFace);
   destructor Destroy;                                                                    override;
   procedure Draw(Viewport:TViewport);
   procedure Extents(var Min,Max:Vector);
   procedure LoadBinary(Source:TFileBuffer);
   procedure MoveDown;
   procedure MoveUp;
   procedure SaveToDXF(Strings:TStringList);
   procedure SaveBinary(Destination:TFileBuffer);
   procedure Unroll(Destination:TFasterList);
   property  Color               : TColor read FGetColor write FSetColor;
   property  Count               : Integer read FGetCount;
   property  Developable         : boolean read FDevelopable write FSetFDevelopable;
   property  DXFLayername        : string read FGetDXFLayername;
   property  Items[Index:Integer]: SControlFace read FGetItems;
   property  LayerIndex          : integer read FGetLayerIndex;
   property  Name                : string read FGetName write FSetName;
   property  ShowInLinesplan     : Boolean read FShowInLinesplan write FSetShowInLinesplan;
   property  SurfaceProperties   : TLayerProperties read FGetSurfaceProperties;
   property  Symmetric           : Boolean read FSymmetric write FSetSymmetric;
   property  UseInHydrostatics   : boolean read FUseInHydrostatics write FSetUseInHydrostatics;
   property  UseForIntersections : boolean read FUseForIntersections write FSetUseForIntersections;
   property  Visible             : boolean read FVisible write FSetVisible;
 end;

///  SubdivisionPoint

SPoint = class(SBase)
private
   FFaces,FEdges: TFasterList;
   FCoordinate: Vector;
   function FGetEdge(Index:Integer):SEdge;
   function FGetCoordinate:Vector;
   function FGetCurvature:Real;
   function FGetFace(Index:Integer):SFace;
   function FGetIndex:Integer; virtual;
   function FGetIsBoundaryVertex:Boolean;
   function FGetNormal:Vector;
   function FGetNoCurves:Integer;
   function FGetNoEdges:integer;
   function FGetNoFaces:integer;
   function FGetRegularPoint:Boolean;
   function FGetLimitPoint:Vector;
   procedure FSetCoordinate(Val:Vector); virtual;
public
   VertexType: TVertexType;
   constructor Create(Owner:SSurface); override;
   destructor Destroy; override;
   procedure Clear;
   procedure AddEdge(Edge:SEdge);
   procedure AddFace(Face:SFace);
   procedure DeleteEdge(Edge:SEdge);
   procedure DeleteFace(Face:SFace);
   function Averaging:Vector;
   function CalculateVertexPoint:SPoint; virtual;
   function IndexOfFace(Face:SFace):Integer;
   function IsRegularNURBSPoint(Faces:TFasterList):Boolean;
   property Coordinate: Vector read FGetCoordinate write FSetCoordinate;
   property Curvature : Real read FGetCurvature;
   property Edge[index:Integer]: SEdge read FGetEdge;
   property Face[index:Integer]: SFace read FGetFace;
   property IsBoundaryVertex: boolean read FGetIsBoundaryVertex;
   property LimitPoint  : Vector read FGetLimitPoint;
   property Normal      : Vector read FGetNormal;
   property NoCurves    : Integer read FGetNoCurves;
   property NoEdges     : integer read FGetNoEdges;
   property NoFaces     : integer read FGetNoFaces;
   property RegularPoint: Boolean read FGetRegularPoint;
   property VertexIndex : integer Read FGetIndex;
 end;
{
 SControlPoint
}
SControlPoint = class(SPoint)
private
   FLocked: Boolean;
   function FGetColor:TColor;
   function FGetIsLeak:boolean;
   function FGetSelected:Boolean;
   function FGetVisible:Boolean;
   procedure FSetLocked(val:Boolean);
   procedure FSetSelected(val:Boolean);
   procedure FSetCoordinate(Val:Vector); override;
public
   constructor Create(Owner:SSurface); override;
   procedure Collapse;
   function  FGetIndex:Integer; override;
   function  DistanceToCursor(X,Y:Integer;Viewport:TViewport):Integer;
   procedure SelDeletePoint;
   procedure Draw(Viewport:TViewport);
   procedure LoadBinary(Source:TFileBuffer);
   procedure LoadFromStream(var LineNr:Integer;Strings:TStringList);
   procedure SaveBinary(Destination:TFileBuffer);
   procedure SaveToStream(Strings:TStringlist);
   property  Color   : TColor read FGetColor;
   property  IsLeak  : Boolean read FGetIsLeak;
   property  Locked  : Boolean read FLocked write FSetLocked;
   property  Selected: boolean read FGetSelected write FSetSelected;     // Property to see if this point has been selected by the user
   property  Visible : Boolean read FGetVisible;
 end;

/// SEdge

SEdge = class(SBase)
private
   FFaces: TFasterList;
   FCrease: Boolean;
   FControlEdge: Boolean;
   function  FGetIndex:Integer; virtual;
   function  FGetIsBoundaryEdge:Boolean; virtual;
   function  FGetFace(Index:Integer):SFace;
   function  FGetNoFaces:Integer;
   procedure FSetCrease(Val:Boolean); virtual;
   function  FGetPreviousEdge:SEdge;
   function  FGetNextEdge:SEdge;
public
   Curve: SControlCurve;
   Startpoint: SPoint;
   Endpoint: SPoint;
   constructor Create(Owner:SSurface); override;
   destructor  Destroy; virtual;
   procedure   Clear;
   procedure   AddFace(Face:SFace);
   procedure   Assign(Edge:SEdge); virtual;
   function    CalculateEdgePoint:SPoint;
   procedure   DeleteFace(Face:SFace);
   function    DistanceToCursor(X,Y:Integer;var P:Vector;Viewport:TViewport):integer;virtual;
   procedure   Draw(DrawMirror:Boolean;Viewport:TViewport); virtual;
   procedure   SwapData;
   property    Crease: Boolean read FCrease write FSetCrease;
   property    EdgeIndex: integer read FGetIndex;
   property    Face[index:integer]: SFace read FGetFace;
   property    IsBoundaryEdge: Boolean read FGetIsBoundaryEdge;
   property    NextEdge: SEdge read FGetNextEdge;
   property    NoFaces: integer read FGetNoFaces;
   property    PreviousEdge: SEdge read FGetPreviousEdge;
 end;
{
   SControlEdge
}
SControlEdge= class(SEdge)
private
   function  FGetColor:TColor;
   function  FGetIndex:Integer; override;
   function  FGetIsBoundaryEdge:Boolean; override;
   procedure FSetSelected(val:Boolean);
   function  FGetSelected:Boolean;
   function  FGetVisible:Boolean;
public
   isRead: boolean;   // отметка прочитанного и заново построенного ребра в FEF
   constructor Create(Owner:SSurface); override;
   destructor Destroy; override;
   procedure Collapse;
   procedure SelDeleteEdge;
   function  DistanceToCursor(X,Y:Integer;var P:Vector;Viewport:TViewport):integer;override;
   procedure Draw(DrawMirror:Boolean;Viewport:TViewport); override;
   function  InsertControlPoint(P:Vector):SControlpoint;
   procedure LoadBinary(Source:TFileBuffer);
   procedure LoadFromStream(var LineNr:Integer;Strings:TStringList);
   procedure SaveBinary(Destination:TFileBuffer);
   procedure SaveToStream(Strings:TStringlist);
   procedure Trace;
   property  Color: TColor read FGetColor;
   property  Selected: boolean read FGetSelected write FSetSelected; // Property to see if this edge has been selected by the user
   property  Visible: Boolean read FGetVisible;
 end;

SFace = class(SBase)
private
   FPoints: TFasterlist;
   function FGetArea:Real;
   function FGetFaceCenter:Vector;
   function FGetFaceNormal:Vector;
   function FGetNoPoints:Integer;
   function FGetPoint(Index:Integer):SPoint;
public
   constructor Create(Owner:SSurface); override;
   destructor  Destroy; virtual;
   procedure   Clear; virtual;
   procedure   AddPoint(Point:SPoint);
   function    CalculateFacePoint:SPoint;
   procedure   FlipNormal; // Inverts the point ordering of the face
   function    IndexOfPoint(P:SPoint):Integer;
   procedure   Subdivide(Owner:SSurface;ControlFace:Boolean;VertexPoints,EdgePoints,FacePoints,InteriorEdges,ControlEdges,Dest:TFasterList);virtual;
   property    Area      : Real read FGetArea;
   property    FaceCenter: Vector read FGetFaceCenter;
   property    FaceNormal: Vector read FGetFaceNormal;
   property    Nopoints  : Integer read FGetNoPoints;
   property    Point[index:Integer]: SPoint read FGetPoint;
end;

SControlFace = class(SFace)
private
   FLayer: SLayer;
   FChildren: TFasterList;
   FMin,FMax: Vector;
   FEdges,FControlEdges: TFasterList;
   function FGetChild(Index:Integer):SFace;
   function FGetChildCount:Integer;
   function FGetControlEdge(Index:Integer):SEdge;
   function FGetControlEdgeCount:Integer;
   function FGetEdge(Index:Integer):SEdge;
   function FGetEdgeCount:Integer;
   function FGetIndex:Integer;
   function FGetSelected:Boolean;
   function FGetVisible:Boolean;
   procedure FSetLayer(Val:SLayer);
   procedure FSetSelected(val:Boolean);
public
   constructor Create(Owner:SSurface); override;
   destructor Destroy; override;
   procedure Clear; override;
   procedure CalcExtents;
   procedure ClearChildren;
   function  DistanceToCursor(X,Y:Integer;var P:Vector;Viewport:TViewport):integer;
   procedure SelDeleteFace;
   procedure Draw(Viewport:TViewport); overload; virtual;
   procedure Draw(Viewport:TViewport;MinCurvature,MaxCurvature:Real); reintroduce;overload;
   function  InsertEdge(P1,P2:SControlPoint):SControlEdge;
   procedure LoadBinary(Source:TFileBuffer);
   procedure SaveBinary(Destination:TFileBuffer);
   procedure SaveToDXF(Strings:TStringList);
   procedure SaveToStream(Strings:TStringlist); virtual;
   procedure Subdivide
           ( Owner:SSurface; ControlFace:Boolean;
             VertexPoints,EdgePoints,FacePoints,InteriorEdges,ControlEdges,Dest:TFasterList
           ); override;
   procedure   Trace;   // select all controlfaces connected to the current one
        // that belong to the same layer and are not separated by a crease edge
   property ControlEdge[index:Integer]: SEdge read FGetControlEdge;
   property ControlEdgeCount: Integer read FGetControlEdgeCount;
   property Child[index:Integer]: SFace read FGetChild;
   property ChildCount: integer read FGetChildCount;
   property Edge[index:Integer]: SEdge read FGetEdge;
   property EdgeCount: Integer read FGetEdgeCount;
   property FaceIndex: integer read FGetIndex;
   property Layer: SLayer read FLayer write FSetLayer;
   property Max: Vector read FMax;
   property Min: Vector read FMin;
   property Selected: boolean read FGetSelected write FSetSelected; // Property to see if this controlface has been selected by the user
   property Visible: Boolean read FGetVisible;
 end;
{ 
  This is the subdivision surface used for modelling the hull.
  This is actually a quad-triangle subdivision surface as publisehed in the articles:
   "Quad/triangle subdivision" by J. Stam & C. Loop http://research.microsoft.com/~cloop/qtEG.pdf
   "On C2 triangle/quad subdivision" by Scott Schaeffer & Joe Warren
}
SSurface  = class(TEntity)
private
   FControlPoints,         // List with controlpoints, which can be changed by the user
   FControlEdges,          // List with controledges, which can be changed by the user
   FControlFaces,          // List with controlfaces, which can be changed by the user
   FControlCurves,         // list with mastercurves
   FSelectedControlPoints, // Controlpoints which are selected by the user are put in this list
   FSelectedControlEdges,  // List with currently selected controledges
   FSelectedControlCurves, // List with currently selected controlcurves
   FSelectedControlFaces,  // List with currently selected controlfaces
   FPoints,                // List with points obtained by subdividing the surface
   FLayers,                // All layers are stored in this list
   FEdges: TFasterList;    // this list edges obtained by subdividing the controledges
   FActiveLayer: SLayer;   // Currently active layer, may not be nil!
   FSubdivisionMode: SMode; // Varaiable to switch between quad-triangle and Catmull Clark subdivision
   FLastusedLayerID: Integer;
   FGausCurvature: RealArray; // list with precalculated values of gauss.
   FMinGaussCurvature,
   FMaxGaussCurvature: Real;
   FInitialized: Boolean; // Flag to check if the surface has been initialised.
   FDivSec,FCurrenSLevel: byte;
   function FGetControlPoint(Index:Integer):SControlPoint;
   function FGetControlCurve(Index:Integer):SControlCurve;
   function FGetControlEdge(Index:Integer):SControlEdge;
   function FGetControlFace(Index:Integer):SControlFace;
   function FGetGaussCurvatureCalculated:boolean;
   function FGetLayer(Index:Integer):SLayer;
   function FGetNoControlPoints:Integer;
   function FGetNoControlEdges:Integer;
   function FGetNoControlCurves:Integer;
   function FGetNoControlFaces:Integer;
   function FGetNoFaces:Integer;
   function FGetNoLayers:Integer;
   function FGetNoLockedPoints:Integer;
   function FGetPoint(Index:Integer):SPoint;
   function FGetEdge(Index:Integer):SEdge;
   function FGetNoPoints:Integer;
   function FGetNoSelectedControlCurves:Integer;
   function FGetNoSelectedControlEdges:Integer;
   function FGetNoSelectedControlFaces:Integer;
   function FGetNoSelectedControlPoints:Integer;
   function FGetNoSelectedLockedPoints:Integer;
   function FGetNoEdges:Integer;
   function FGetSelectedControlCurve(Index:Integer):SControlCurve;
   function FGetSelectedControlEdge(Index:Integer):SControlEdge;
   function FGetSelectedControlFace(Index:Integer):SControlFace;
   function FGetSelectedControlPoint(Index:Integer):SControlPoint;
   function FRequestNewLayerID:Integer;
   procedure FSetActiveLayer(Val:SLayer);
   procedure FSetBuild(Val:Boolean); override;
   procedure FSetDivSec(val:byte);
   procedure FSetFShowControlNet(Val:Boolean);
   procedure FSeSMode(val:SMode);
public
   WaterlinePlane: Plate; // This plane is used to clip the hull, and shade the underwatership in a different color
   DrawMirror, // If this is set tot true, the other imaginary half (starboard side) will be drawn aswell
   ShowNormals,    // show normals of selected controlfaces
   ShowControlNet, // Flag to switch controlpoints and control-edges visibility
   ShowInteriorEdges, // Switch to turn on drawing off all interior edges as well.
   ShowCurvature,
   ShowControlCurves: Boolean;
   ControlPointSize: Integer;
   MainframeLocation: Real;
   OnChangeActiveLayer:
      TChangeActiveLayerEvent; // Event raised when the active layer is changed
   OnChangeLayerData, // Event which is raised when layer-data has been changed
   OnSelectItem: TNotifyEvent; // This event is raised whenever an item
 // (such as controlpoint,controledge or controlface) is selected or deselected
   procedure   AddControlCurve(Curve:SControlCurve);
   function    AddControlEdge(P1,P2:SPoint):SControlEdge;                         overload;virtual;
   function    AddControlFace(Points: VectorArray;NoPoints:Integer):SControlFace;      overload;virtual;
   function    AddControlFace(Points:TFasterList;CheckEdges:Boolean):SControlFace;               reintroduce;overload;
   function    AddControlFace(Points:TList;CheckEdges:Boolean):SControlFace;                     reintroduce;overload;
   function    AddControlFace(Points:TFasterList;CheckEdges:Boolean;Layer:SLayer):SControlFace; reintroduce;overload;
   function    AddControlPoint(P:Vector):SControlPoint; overload;virtual;
   procedure   AddControlPoint(P:SControlPoint); reintroduce;overload;
   function    AddControlPoint:SControlPoint; reintroduce;overload; // Adds a new controlpoint at 0,0,0 without checking other points
   function    AddNewLayer:SLayer;
   procedure   AssembleFacesToPatches(Layers:TFasterList;Mode:TAssembleMode;var AssembledPatches:TFaceArray;var NAssembled:Integer);
   procedure   CalculateGaussCurvature;                                       // Calculate Gauss. curvature in each point of the mesh and store it in a array
   procedure   Clear; override;
   procedure   ClearFaces;
   procedure   Clearselection;
   procedure   ConvertToGrid(Input:TFaceGrid;var Cols,Rows:Integer;var Grid:SGrid);
   procedure   Edge_Connect;
   procedure   ExportFeFFile(Strings:TStringList);
   procedure   ImportObjFile(Strings: TStringList);
   procedure   ExportObjFile(ExportControlNet:Boolean;Strings:TStringList);
   procedure   Extents(Var Min,Max : Vector); override;
   procedure   ExtrudeEdges(Edges:TFasterList;Direction:Vector); reintroduce;overload;
   procedure   CalculateIntersections(Plane:Plate;Faces,Destination:TFasterList);
   constructor Create; override;
   destructor  Destroy; override;
   procedure   Rebuild; override;
   procedure   Draw(Viewport:TViewport); override;
   function    EdgeExists(P1,P2:SPoint):SEdge;
   procedure   ExtractAllEdgeLoops( var Destination:TFasterList );   // для DXF
// procedure   ExtractPointsFromFaces(SelectedFaces,Points:TFasterList;var LockedPoints:Integer);   // extracts all points that are used by the faces in the selectedfaces list
   procedure   ExtractPointsFromSelection(SelectedPoints:TFasterList;var LockedPoints:Integer);
   procedure   ImportFEFFile(Strings:TStringList;var LineNr:Integer);
   procedure   ImportGrid(Points:TCoordinateGrid;Cols,Rows:Integer;Layer:SLayer);
   procedure   Initialize(PointStartIndex,EdgeStartIndex,FaceStartIndex:Integer);
   function    IntersectPlane(Plane:Plate;HydrostaticsLayersOnly:Boolean;List:TFasterList):Boolean;
   procedure   InsertPlane(Plane:Plate;AddCurves:Boolean);  // inserts points on edges (visible edges only) that intersect the input plane
   procedure   IsolateEdges(Source,Destination:TFasterList);overload;virtual;
   procedure   LoadBinary(Source:TFileBuffer);
   procedure   LoadVRMLFile(Filename:string);
   function    PointExists( P:SControlPoint ):Boolean;
   procedure   SaveBinary(Destination:TFileBuffer);
   procedure   Selection_Add( item: SBase );
   procedure   Selection_Delete;
   procedure   SortEdges(Edges:TFasterList); overload; virtual;
   procedure   SortEdges(Edges:TFasterList;var Points:TFasterList); reintroduce;overload;
   procedure   SubDivide;
// property    DrawMirror : boolean read FDrawMirror write FDrawMirror;
// property    MainframeLocation: Real read FMainframeLocation write FMainframeLocation;
   property    ActiveLayer                : SLayer read FActiveLayer write FSetActiveLayer;
   property    ControlPoint[index:Integer]: SControlPoint read FGetControlpoint;
   property    ControlCurve[index:Integer]: SControlCurve read FGetControlCurve;
   property    ControlEdge[index:Integer] : SControlEdge  read FGetControlEdge;
   property    ControlEdges               : TFasterlist   read FCOntrolEdges;
   property    ControlFace[index:Integer] : SControlFace  read FGetControlFace;
   property    CurrenSLevel: byte read FCurrenSLevel;
   property    DivSec: byte read FDivSec write FSetDivSec;
   property    GaussCurvatureCalculated: boolean read FGetGaussCurvatureCalculated;
   property    Layer[index:integer]: SLayer read FGetLayer;
   property    MaxGaussCurvature: Real    read FMaxGaussCurvature;
   property    MinGaussCurvature: Real    read FMinGaussCurvature;
   property    NoControlFaces   : Integer read FGetNoControlFaces;
   property    NoControlEdges   : Integer read FGetNoControlEdges;
   property    NoControlCurves  : Integer read FGetNoControlCurves;
   property    NoControlPoints  : Integer read FGetNoControlPoints;
   property    NoFaces          : Integer read FGetNoFaces;
   property    NoLayers         : Integer read FGetNoLayers;
   property    NoLockedPoints   : Integer read FGetNoLockedPoints;
   property    NoSelectedControlCurves: Integer read FGetNoSelectedControlCurves;
   property    NoSelectedControlEdges : Integer read FGetNoSelectedControlEdges;
   property    NoSelectedControlFaces : Integer read FGetNoSelectedControlFaces;
   property    NoSelectedControlPoints: Integer read FGetNoSelectedControlPoints;
   property    NoSelectedLockedPoints : Integer read FGetNoSelectedLockedPoints;
   property    Point[index:Integer]: SPoint read FGetpoint;
   property    Edge[index:Integer] : SEdge read FGetEdge;
   property    NoEdges       : Integer read FGetNoEdges;
   property    NoPoints      : Integer read FGetNoPoints;
   property    SelectedControlCurve[index:Integer]: SControlCurve read FGetSelectedControlCurve;
   property    SelectedControlEdge[index:Integer] : SControlEdge read FGetSelectedControlEdge;
   property    SelectedControlFace[index:Integer] : SControlFace read FGetSelectedControlFace;
   property    SelectedControlPoint[index:Integer]: SControlPoint read FGetSelectedControlPoint;
   property    SubdivisionMode  : SMode read FSubdivisionMode write FSeSMode;
end;

function  AreaStr(Units:TUnitType):String; // Returns a string value with the area units
function  BoolToStr(Val:Boolean):String; // In contrast to delphis own BoolToStrF this procedure returns '0' when false and '1' when true
procedure ClipTriangle(P1,P2,P3:Vector;s1,s2,s3:Real;var Nf,Nb:INteger;var Front,Back:VectorArray);overload;
procedure ClipTriangle(P1,P2,P3:Vector;Plane:Plate;var Nf,Nb:INteger;var Front,Back:VectorArray);overload;
function  ConvertDimension(Value:Real;Units:TUnitType):String;   // Converts a dimesnion to a string
function  ConvertCoordinate(Coord: String; OldCoord: Real):Real;// converts a string to a floatingpoint value, possibly using imperial units
function  DisplacementToVolume(Displ,Density,AppCoeff:Real;Units:TUnitType):Real; // Converts a displacement to volume
function  DensityStr(Units:TUnitType):String; // Returns a string value with the density units
Function  DistanceToLine(P1,P2:TPoint;X,Y:Integer;var Parameter:Real):Real;
function  DotProduct( const U,V : Vector ) : Real;
procedure FillColor(Parameter:Real;var R,G,B:Byte);
function  InertiaStr(Units:TUnitType):String; // Returns a string value with the moment of inertia units
function  Interpolate(P1,P2:Vector;Param:Real):Vector; // perform linear interpolation between two 3D points
procedure JoinSplineSegments(JoinError:Real;ForceToOneSegment:Boolean;List:TFasterList);// Takes multiple splines and tries to connect them to as few as possible
Function  Lines3DIntersect(P1,P2,P3,P4:Vector;var Param:Real;var Int:Vector):Boolean;
function  LengthStr(Units:TUnitType):String; // Returns a string value with the length units
function  MakeLength(value:Real;Decimals,DesLength:integer):string;overload;
function  MakeLength(value:String;DesLength:integer):string;overload;
procedure MinMax( P:Vector;var Min,Max:Vector );
function  Midpoint(P1,P2:Vector):Vector; // Calculate the mid-point between P1 and P2
function  MirrorPlane( P:Vector; Plane:Plate ):Vector; // mirror a point in a plane
function  NoDecimals(Value:Real):Integer; // Finds out with how many decimals a number should be presented
function  PlaneIntersectsBox(Min,Max:Vector;Plane:Plate):Boolean;// Function to determine if a plane intersects a bounding box
function  PlanePointNormal(P,Normal:Vector):Plate; // Calculates the plane with a given normal N through point P
function  PlanePPP(P1,P2,P3:Vector):Plate; // Create a plane defined by three points
function  PointInTriangle(P,A,B,C:Vector):Boolean; // This function calculates if a point lies inside a triangle assuming it lies on the plane determined by the triangle
Function  ProjectPointOnLine(P,P1,P2:Vector):Vector; // Projects point  P on the linesegment through P1 and P2
function  ProjectPointOnPlane(P:Vector;Plane:Plate):Vector;// Projects a point on to a plane
function  RandomColor:TColor;                        // create a random color
function  RotateVector(P0:Vector;sinx,cosx,siny,cosy,sinz,cosz:Real):Vector; // Rotates a iVect around the origin
function  SetPlane(a,b,c,d:Real):Plate;
function  VolStr(Units:TUnitType):String; // Returns a string value with the volume units
function  VolumeToDisplacement(Volume,Density,AppCoeff:Real;Units:TUnitType):Real; // Converts a volume to displacement
function  WeightStr(Units:TUnitType):String; // Returns a string value with the weight units
function  Normalize(const P:Vector):Vector;
Function  UnifiedNormal(const P1,P2,P3:Vector):Vector; // calculate the normal of a plane defined by points P1,P2,P3 and scale to unit-length
function LenMMStr(Units: TUnitType): String;
function FindDXFColorIndex(Color:TColor):integer; // find nearest DXF color corresponding to a windows color
function FindIGSColorIndex(Color:TColor):integer;
//function PoundsToNewton(InpLbs:Real):Real;       // converts pounds to Newton

procedure Register;

implementation
{$R Cursors.res}   // nice cursors with antialiasing - {$R ViewportCursors.res}

uses { Main,} ShipUnit,LanguageSupport,VRMLUnit,BackgroundBlendingDlg;
{$I Geometry_Functions}

const crRotate    = 1; // Rotation cursor
      crPan       = 2; // Pan cursor
      crSetOrigin = 3; // Cursor used when setting the origin of a background image
      crSetScale  = 4; // Cursor used when setting the scale of a background image
      crTranspCol = 5; // Cursor used when setting the transparent color of a background image
{
   TAlphaBuffer
        Alpha-buffer class used in the shading algorithm
}
procedure TAlphaBuffer.AddPixelData( X,Y:Integer; R,G,B,Alpha:Byte; Z:Real );
var Data: TAlphaBlendData;
begin
   if (X>=0) and (X<FWidth) and (Y>=0) and (Y<FHeight) then begin
     if Y<FFirstRow then FFirstRow:=Y else
        if Y>FlastRow then FLastRow:=Y;
     if X<FBuffer[Y].First then FBuffer[Y].First:=X else
        if X>FBuffer[Y].Last then FBuffer[Y].Last:=X;
     if FBuffer[Y].Pixels[X].Number>=FBuffer[Y].Pixels[X].Capacity then begin
        inc(FBuffer[Y].Pixels[X].Capacity,4);
        setlength(FBuffer[Y].Pixels[X].Data,FBuffer[Y].Pixels[X].Capacity);
     end;
     Data.R:=R;
     Data.G:=G;
     Data.B:=B;
     Data.Alpha:=Alpha;
     Data.zvalue:=Z;
     FBuffer[Y].Pixels[X].Data[FBuffer[Y].Pixels[X].Number]:=Data;
     if FBuffer[Y].Pixels[X].Number<250 then inc(FBuffer[Y].Pixels[X].Number);
   end;
end;

procedure TAlphaBuffer.Initialize; Var I,J : Integer;
begin
   if (FWidth<>FViewport.FDestinationWidth)
   or (FHeight<>FViewport.FDestinationheight) then begin
      FHeight:=FViewport.FDestinationheight;
      FWidth:=FViewport.FDestinationWidth;
      FFirstRow:=0;
      FLastRow:=-1;
      Setlength( FBuffer,FHeight );
      for I:=0 to FHeight-1 do begin
         Setlength(FBuffer[I].Pixels,FWidth);
         FBuffer[I].First:=0;
         FBuffer[I].Last:=-1;
         for J:=0 to FWidth-1 do begin
            Setlength( FBuffer[I].Pixels[J].Data,0 );
            FBuffer[I].Pixels[J].Number:=0;
            FBuffer[I].Pixels[J].Capacity:=0;
         end;
      end;
   end;
end;

procedure TAlphaBuffer.Draw;
var I,J: Integer;
   procedure ProcessPixel(X,Y:Integer;PixData:TAlphaBlendPixelArray);
      procedure QuickSort(L,R:Integer);
      var I,J: Integer; Val: Real;
         Procedure Swap(I,J:Integer); var Tmp: TAlphaBlendData;
         begin Tmp:=PixData.Data[I];
               PixData.Data[I]:=PixData.Data[J];
               PixData.Data[J]:=Tmp;
         end;
      begin I:=L; J:=R; Val:=PixData.Data[(L+R) div 2].zvalue;
         repeat
           While PixData.Data[I].zvalue<Val do Inc(I);
           while Val<PixData.Data[J].zvalue do Dec(J);
           if I<=J then begin Swap(I,J); Inc(I); Dec(J); end;
         Until I>J;
         if L<J then QuickSort(L,J);
         if I<R then QuickSort(I,R);
      end; {QuickSort}
   var Data:TAlphaBlendData; C: TColor; R,G,B:Byte; I:Integer;
   begin
      if PixData.Number>1 then QuickSort(0,PixData.Number-1);
      for I:=1 to PixData.Number do begin
         Data:=PixData.Data[I-1];
         if Data.zvalue>FViewport.ZBuffer.FBuffer[Y][X] then begin
         C:=FViewport.Canvas.Pixels[X,Y]; R:=Red( C ); G:=Green( C ); B:=Blue( C );
         FViewport.Canvas.Pixels[X,Y] := RGBtoColor
                 ( R+(Data.Alpha*(Data.R-R)) shr 8,
                   G+(Data.Alpha*(Data.G-G)) shr 8,
                   B+(Data.Alpha*(Data.B-B)) shr 8 );
         end;
      end;
   end;
begin
   for I:=FFirstRow to FLastRow do begin
      for J:=FBuffer[I].First to FBuffer[I].Last do begin
         if FBuffer[I].Pixels[J].Number>0 then begin
            ProcessPixel(J,I,FBuffer[I].Pixels[J]);
            FBuffer[I].Pixels[J].Number:=0;
            FBuffer[I].Pixels[J].Capacity:=0;
            Setlength(FBuffer[I].Pixels[J].Data,0);
         end;
      end;
   end;
   FFirstRow:=0;
   FLastRow:=-1;
end;
{
  TZBuffer
  Z-buffer class used in the shading algorithm
}
procedure TZBuffer.Initialize;
var I : Integer;
begin
   if (FWidth<>FViewport.FDestinationWidth)
   or (FHeight<>FViewport.FDestinationheight) then begin
      FHeight:=FViewport.FDestinationheight;
      FWidth:=FViewport.FDestinationWidth;
      Setlength(FBuffer,FHeight);
      for i:=0 to FHeight-1 do Setlength(FBuffer[I],FWidth);
   end;                        // initalize all pixel cells to an initial value
   for I:=0 to FWidth-1 do FBuffer[0][I]:=-1e10;
   for I:=1 to FHeight-1 do
       Move( FBuffer[0][0],FBuffer[I][0],FWidth*SizeOf(Real) );
end;
{
  Background image properties for use in a viewport
}
procedure TBackgroundImage.AssignData
(  Image: TGraphic;
   View:  TViewType;
   Origin:TPoint;
   Scale: Real;
   Transp:boolean;
   TranspCol:TColor;
   Alpha,Quality,Tolerance:Byte;
   Quiet:Boolean );
var Changed:Boolean;
begin
   Changed:=False;
   if (Image<>nil) and (FBitmap=nil) then begin
      FBitmap:=TBitmap.Create;
      FBitmap.Assign(Image);
      Changed:=True;
   end else if (Image=nil) and (FBitmap<>nil) then begin
      FBitmap.Free;
      FBitmap:=nil;
      Changed:=true;
   end else if (Image<>nil) and (FBitmap<>nil) then begin
      FBitmap.Assign(Image);
      Changed:=true;
   end;
   FShowInView:=View;
   FOrigin:=Origin;
   FScale:=Scale;
   FTransparent:=Transp;
   FTransparentColor:=TranspCol;
   Falpha:=Alpha;
   FQuality:=Quality;
   FTolerance:=Tolerance;
   if Changed and (not Quiet) then Owner.Refresh;
end;

//Function {TBackgroundImage.}FOnChangeBackgroundImage( Sender: TObject ): TNotifyEvent;
//   begin Result:=TNotifyEvent( 0 ); end;

procedure TBackgroundImage.Clear;
begin
   if FBitmap<>nil then begin
      FBitmap.Destroy;
      FBitmap:=nil;
   end;
   FOrigin.X:=0;
   FOrigin.Y:=0;
   FScale:=1.0;
   FTransparent:=False;
   FTransparentColor:=ClBlack;
   FVisible:=True;
   if (not (csdestroying in owner.componentstate)) then
      if assigned(Owner.FOnChangeBackgroundImage) then
         Owner.FOnChangeBackgroundImage(Owner);
   FShowInView:=fvBodyPlan;
   FQuality:=100;
   FAlpha:=255;
   FTolerance:=5;
end;
procedure TBackgroundImage.FSetAlpha(val:Byte);
begin
   if val<>FAlpha then begin FAlpha:=val;
      if (FVisible) and (FBitmap<>nil) then FOwner.Refresh;
   end;
end;
procedure TBackgroundImage.FSetOrigin(val:TPoint);
begin
   if (Val.X<>Forigin.X) or (Val.Y<>FOrigin.Y) then begin
      FOrigin:=Val;
      if (FVisible) and (FBitmap<>nil) then FOwner.Refresh;
      if (not (csdestroying in owner.componentstate)) then
         if assigned(Owner.FOnChangeBackgroundImage) then
             Owner.FOnChangeBackgroundImage(Owner);
   end;
end;
procedure TBackgroundImage.FSetTolerance(val:Byte);
begin
   if Val<>FTolerance then begin
      FTolerance:=val;
      if (FVisible) and (FBitmap<>nil) and (FTransparent) then FOwner.Refresh;
      if (not (csdestroying in owner.componentstate)) then
         if assigned(Owner.FOnChangeBackgroundImage) then
            Owner.FOnChangeBackgroundImage(Owner);
   end;
end;
procedure TBackgroundImage.FSetTransparent(val:Boolean);
begin
   if Val<>FTransparent then begin
      FTransparent:=val;
      if (FVisible) and (FBitmap<>nil) then FOwner.Refresh;
      if (not (csdestroying in owner.componentstate)) then
         if assigned(Owner.FOnChangeBackgroundImage) then
             Owner.FOnChangeBackgroundImage(Owner);
   end;
end;
procedure TBackgroundImage.FSetTransparentColor(val:TColor);
begin
   if Val<>FTransparentColor then begin
      FTransparentColor:=val;
      if (FVisible) and (FBitmap<>nil) and (Transparent) then begin
         if FTransparentColor=Owner.Color then FTransparent:=False;
         FOwner.Refresh;
      end else if FTransparentColor=Owner.Color then FTransparent:=False;
      if (not (csdestroying in owner.componentstate)) then
         if assigned(Owner.FOnChangeBackgroundImage) then
             Owner.FOnChangeBackgroundImage(Owner);
   end;
end;
procedure TBackgroundImage.FSetVisible(val:Boolean);
begin
   if val<>FVisible then begin FVisible:=val;
      if FBitmap<>nil then Owner.Refresh;
      if (not (csdestroying in owner.componentstate)) then
         if assigned(Owner.FOnChangeBackgroundImage) then
            Owner.FOnChangeBackgroundImage( Owner );
   end;
end;
constructor TBackgroundImage.Create(Viewport:TViewport);
      begin Inherited Create; FOwner:=Viewport; FBitmap:=nil; Clear; end;
destructor TBackgroundImage.Destroy;
     begin Clear; Inherited Destroy; end;

procedure TBackgroundImage.Draw;
var Dest: TRect; I,J: Integer;
    Rt,Gt,Bt, Rb,Gb,Bb, R,G,B, TmpVal: Byte; Img: TCanvas;
begin
   if (Visible) and (Owner.ViewType=FShowInView) then begin
      Img := Owner.Canvas;
      Dest:=TargetRect;                // внешняя картинка меньше окна в экране
      StretchBlt( Img.Handle,          // внешняя картинка больше экранной
        Dest.Left,Dest.Top,Dest.Right-Dest.Left,Dest.Bottom-Dest.Top,
        BitMap.Canvas.Handle,0,0,FBitMap.Width,FBitMap.Height,SRCCOPY );
      if (Transparent) or (Alpha<>255) then begin         // -- правим её копию
         RedGreenBlue( Owner.Color,Rb,Gb,Bb );
         RedGreenBlue( FTransparentColor,Rt,Gt,Bt );
         TmpVal:=255-Alpha;
// {$omp parallel for private(I,J)}
         for I:=0 to Owner.Height-1 do
         for J:=0 to Owner.Width-1 do begin
            RedGreenBlue( Tcolor( Img.Pixels[J,I] ),R,G,B );
            if Transparent then begin // Replace transparent pixels with viewport color
            if  (abs(R-Rt)<=FTolerance)
            and (abs(G-Gt)<=FTolerance)
            and (abs(B-Bt)<=FTolerance)
            then Img.Pixels[J,I]:=TColor( Owner.Color )
            else begin    // Blend non-transparent pixels with the viewport
               R:=(Tmpval*Rb+Alpha*R) shr 8;
               G:=(Tmpval*Gb+Alpha*G) shr 8;
               B:=(Tmpval*Bb+Alpha*B) shr 8;
               Img.Pixels[J,I]:=TColor( RGB( R,G,B ) );
            end;
         end else begin              // Blend all pixels with the viewport
            R:=(Tmpval*Rb+Alpha*R) shr 8;
            G:=(Tmpval*Gb+Alpha*G) shr 8;
            B:=(Tmpval*Bb+Alpha*B) shr 8;
            Img.Pixels[J,I]:=TColor( RGB( R,G,B ) );
         end;
       end;
     end;
   end;
end;

function TBackgroundImage.ImageCoordinate(X,Y:Integer):TPoint;
Var Dest:TRect;
begin
   Dest:=TargetRect;
   Result.X:=round(((X-Dest.Left)/(Dest.Right-Dest.Left))*FBitmap.Width);
   Result.Y:=round(((Y-Dest.Top)/(Dest.Bottom-Dest.Top))*FBitmap.Height);
end;

function TBackgroundImage.TargetRect:TRect;
var Pt : TPoint;
begin
   Pt:=FOwner.Project( ZERO );
   Result.Left:=Pt.X-round(Owner.Scale*Owner.Zoom*FScale*FOrigin.X);
   Result.Top:=Pt.Y-round(Owner.Scale*Owner.Zoom*FScale*FOrigin.Y);
   Result.Right:=Result.Left+Round(Owner.Scale*Owner.Zoom*FScale*FBitmap.Width );
   Result.Bottom:=Result.Top+Round(Owner.Scale*Owner.Zoom*FScale*FBitmap.Height );
end;

procedure TBackgroundImage.Open(InitialDir:String);
var Dialog     : TOpenDialog;
    Pt         : TPoint;
    P2D        : Place;
    JPEGImage  : TJPEGImage;
begin
   Dialog:=TOpenDialog.Create(Application);
   Dialog.InitialDir:=InitialDir;
   Dialog.Filter:='All files [*.jpg;*.bmp]|*.jpg; *.bmp|Jpeg images [*.jpg]|*.jpg|Bitmap files [*.bmp]|*.bmp|';
   Dialog.Options:=[ofHideReadOnly];
   if Dialog.Execute then begin
      Clear;
      FShowInView:=Owner.ViewType;
      FBitmap:=TBitmap.Create;
      if Uppercase(ExtractFileExt(Dialog.Filename))='.JPG' then begin
         JPEGImage:=TJPEGImage.Create;
         JPEGImage.LoadFromFile(Dialog.FileName);
         FBitmap.Assign(JPEGImage);
         JPEGImage.Destroy;
         FQuality:=JPEGImage.CompressionQuality;
      end else begin
         FBitmap.LoadFromFile(Dialog.Filename);
         FQuality:=100;
      end;                                                  // calculate scale
      Pt:=Owner.Project(ZERO);
      Pt.X:=Owner.ClientWidth;
      P2D:=Owner.ProjectBackTo2D(Pt);
      FOrigin.X:=0;
      FOrigin.Y:=FBitmap.Height;
      FScale:=P2D.X/FBitmap.Width;
      FOwner.Refresh;
      if (not (csdestroying in owner.componentstate)) then
         if assigned(Owner.FOnChangeBackgroundImage) then
             Owner.FOnChangeBackgroundImage(Owner);
   end;
   Dialog.Destroy;
end;

procedure TBackgroundImage.Save;
var Image      : TJPEGImage;
    SaveDialog : TSaveDialog;
begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.FileName:='image.jpg';
   SaveDialog.Filter:='Jpeg files [*.jpg]|*.jpg';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      Image:=TJPEGImage.Create;
      Image.Assign(FBitmap);
      Image.CompressionQuality:=FQuality;
      Image.SaveToFile(ChangeFileExt(SaveDialog.Filename,'.jpg'));
      Image.Destroy;
   end;
   SaveDialog.Destroy;
end;

procedure TBackgroundImage.SetBlendingValue;
var Dialog: TBackgroundBlendDialog;
    Old   : Byte;
begin
   Dialog:=TBackgroundBlendDialog.Create(Owner);
   ShowTranslatedValues(Dialog);
   Old:=FAlpha;
   if Dialog.Execute(Owner) then begin
      if assigned(Owner.FOnChangeBackgroundImage) then
         Owner.FOnChangeBackgroundImage(Owner);
   end else Alpha:=Old;
   Dialog.Destroy;
end;
{
   TViewport
   This is a 3D drawingcanvas.
}
procedure TViewport.SetSelectionFrameRect(Rect: TRect);
begin FSelectionFrameRect:=Rect; if FSelectionFrameActive then Refresh;
end;
procedure TViewport.SetSelectionFrameActive(Val: boolean);
begin FSelectionFrameActive:=Val; if FSelectionFrameActive then Refresh;
end;
procedure TViewport.DrawSelectionFrame;
begin if not FSelectionFrameActive then exit; // draw it last
      Canvas.Pen.Style:=psDash;               // psInsideframe;
      Canvas.Pen.Color:=clOlive;              // clYellow; // clWhite;
      Canvas.Frame(FSelectionFrameRect);
end;

procedure TViewport.FSetAngle(Val:Real);
begin
   if Val<>FAngle then begin
      FAngle:=Val;
      FCosAngle:=Cos(DegToRad(FAngle));
      FSinAngle:=sin(DegToRad(FAngle));
      FHorScrollbarChange(self);
      InitializeViewport(FMin3D,FMax3D);
   end;
end;
procedure TViewport.FSetBackgroundMode(val:TViewportBackgroundMode);
begin
   FBackgroundMode:=val;
   Case FBackGroundMode of
      emSetOrigin : Cursor:=crSetOrigin;
      emSetScale  : Cursor:=crSetScale;
      emSetTransparentColor:Cursor:=crTranspCol;
      else Cursor:=crCross;
   end;
end;
procedure TViewport.FSetBrushStyle(Val:TBrushStyle);
    begin if Canvas.Brush.Style<>val then Canvas.Brush.Style:=Val; end;
function TViewport.FGetPenStyle:TPenStyle;
   begin Result:=Canvas.Pen.Style; end;
function TViewport.FGetPenWidth:integer;
   begin Result:=Canvas.Pen.Width; end;
function TViewport.FGetBrushStyle:TBrushStyle;
   begin Result:=Canvas.Brush.Style; end;
function TViewport.FGetPenColor:TColor;
   begin Result:=Canvas.Pen.Color; end;
function TViewport.FGetBrushColor:TColor;
   begin Result:=Canvas.Brush.Color; end;
function TViewport.FGetFontColor:TColor;
   begin Result:=Canvas.Font.Color; end;
function TViewport.FGetFontName:string;
   begin Result:=Canvas.Font.Name; end;
function TViewport.FGetFontSize:Integer;
   begin Result:=Canvas.Font.Size; end;

procedure TViewport.FSetCameraType(Val:TCameraType);
var Film,Dist: Real;
begin
   if Val<>FCameraType then begin Film:=35;              // standard 35mm. film
      Case Val of
         ftWide      : Dist:=20;
         ftStandard  : Dist:=50;
         ftShortTele : Dist:=90;
         ftMediumTele: Dist:=130;
         ftFarTele   : Dist:=200; else Dist:=50;
      end;
      FCameraType:=Val;
      FFieldOfView:=RadToDeg(ArcTan(Film/Dist));
      InitializeViewport(FMin3D,FMax3D);
   end;
end;

procedure TViewport.FSetElevation(Val:Real);
begin
   if Val<>FElevation then begin
      FElevation:=Val;
      FCosElevation:=Cos(DegToRad(FElevation));
      FSinElevation:=sin(DegToRad(FElevation));
      FVertScrollbarChange(self);
      InitializeViewport(FMin3D,FMax3D);
   end;
end;
{
procedure TViewport.FSetLight(val: TLight);
begin if  ( FLight.Position.X=Val.Position.X )
      and ( FLight.Position.Y=Val.Position.Y )
      and ( FLight.Position.Z=Val.Position.Z )
      and ( FLight.Ambient=Val.Ambient )
      and ( FLight.Luminance=Val.Luminance ) then exit;
      FLight:=Val;
      FLightIntensity:=FLight.Luminance/255.0;
      FAmbientIntencity:=FLight.Ambient/255.0;
      Refresh;
end;
}
procedure TViewport.FSetPan(Val:TPoint);
begin
   if (FPan.X<>Val.X) or (FPan.Y<>Val.Y) then begin FPan:=Val; Refresh; end;
end;
procedure TViewport.FSetPenColor(Val:TColor);
    begin if Canvas.Pen.Color<>val then Canvas.Pen.Color:=Val; end;
procedure TViewport.FSetBrushColor(Val:TColor);
    begin if Canvas.Brush.Color<>val then Canvas.Brush.Color:=Val; end;
procedure TViewport.FSetFontColor(Val:TColor);
    begin if Canvas.Font.Color<>val then Canvas.Font.Color:=Val; end;
procedure TViewport.FSetFontSize(val:integer);
    begin if Canvas.Font.Size<>val then Canvas.Font.Size:=val; end;
procedure TViewport.FSetFontName( Val:string );
begin
   if Uppercase(Canvas.Font.Name)<>uppercase(Val) then Canvas.Font.Name:=Val;
end;
procedure TViewport.FSetHorScrollbar(val:TScrollbar);
begin
   if FHorScrollbar<>nil then FHorScrollbar.OnChange:=nil;
   FHorScrollbar:=Val;
   if FHorScrollbar<>nil then begin
      FHorScrollbar.OnChange:=FHorScrollbarChange;
      FHorScrollbar.Min:=-180;
      FHorScrollbar.Max:=180;
      if FHorScrollbar.Position<>round(angle) then FHorScrollbar.Position:=Round(Angle);
      FHorScrollbar.Visible:=ViewType=fvPerspective;
   end;
end;

procedure TViewport.FSetVertScrollbar(val:TScrollbar);
begin
   if FVertScrollbar<>nil then FVertScrollbar.OnChange:=nil;
   FVertScrollbar:=Val;
   if FVertScrollbar<>nil then begin
      FVertScrollbar.OnChange:=FVertScrollbarChange;
      FVertScrollbar.Min:=-180;
      FVertScrollbar.Max:=180;
      if FVertScrollbar.Position<>round(Elevation)
        then FVertScrollbar.Position:=Round(Elevation);
      FVertScrollbar.Visible:=ViewType=fvPerspective;
   end;
end;

procedure TViewport.FSetMargin(Val:Real);
begin
   if Val<0 then Val:=0;
   if Val<>FMargin then begin
      FMargin:=Val;
      if not (csDesigning in ComponentState) then begin
         if Zoom<>1.0 then Refresh
                      else ZoomExtents;
      end;
   end;
end;
procedure TViewport.FSetPenStyle(Val:TPenStyle);
    begin if Canvas.Pen.Style<>val then Canvas.Pen.Style:=Val; end;
procedure TViewport.FSetPenWidth(Val:integer);
    begin if Canvas.Pen.Width<>val then Canvas.Pen.Width:=Val; end;
procedure TViewport.FSetViewType(Val:TViewType);
begin
   if Val<>FViewType then begin
      FViewType:=Val;
      FZoom:=1.0;
      FPan.X:=0;
      FPan.Y:=0;
      Case FViewtype of
         fvBodyplan   : begin FAngle:=0;  FElevation:=0; end;
         fvProfile    : begin FAngle:=90; FElevation:=0; end;
         fvPlan       : begin FAngle:=90; FElevation:=90; end;
         fvPerspective: begin FAngle:=20; FElevation:=20; end;
      end;
      if FHorScrollbar<>nil then begin
         FHorScrollbar.Position:=round(Angle);
         FHorScrollbar.Visible:=ViewType=fvPerspective;
         if FHorScrollbar.Position<>round(angle)
            then FHorScrollbar.Position:=Round(Angle);
      end;
      if FVertScrollbar<>nil then begin
         FVertScrollbar.Position:=round( Elevation );
         FVertScrollbar.Visible:=ViewType=fvPerspective;
         if FVertScrollbar.Position<>round(Elevation)
            then FVertScrollbar.Position:=Round(Elevation);
      end;
      if assigned(FOnRequestBackgroundImage) then FOnRequestBackgroundImage(self);
      if assigned(FOnRequestExtents) then FOnRequestExtents(self,FMin3D,FMax3D);
         InitializeViewport( FMin3D,FMax3D );
      if assigned(FOnChangeViewType) then FOnChangeViewType(self);
   end;
end;
procedure TViewport.FSetViewportMode(Val:TViewportMode);
    begin if Val<>FViewportMode then begin FViewportmode:=Val; Refresh; end;
    end;
procedure TViewport.FHorScrollbarChange(sender:TObject);
    begin if FHorScrollbar<>nil then begin
      if Round(Angle)<>FHorScrollbar.Position then Angle:=FHorScrollbar.Position;
    end;
end;
procedure TViewport.FVertScrollbarChange(sender:TObject);
    begin if FVertScrollbar<>nil then begin
      if Round(Elevation)<>FVertScrollbar.Position then Elevation:=FVertScrollbar.Position;
    end;
end;
procedure TViewport.WMMouseEnter(var Message: TMessage);
    begin inherited;
      if assigned(FOnMouseEnter) then FOnMouseEnter(self);
      if not self.Focused then Setfocus;
    end;
procedure TViewport.WMMouseLeave(var Message: TMessage);
    begin inherited;
      if self.Cursor<>crCross then Cursor:=crCross;
      if Assigned(FOnMouseLeave) then FOnMouseLeave(Self);
end;
constructor TViewport.Create( AOwner:TComponent );
begin
   FBackgroundMode:=emNormal;
   FMargin:=0.0;
   FAngle:=20;
   FElevation:=20;
   FDistance:=1e4;
   FZoom:=1.0;
   FPan.X:=0;
   FPan.Y:=0;
   FOnRequestBackgroundImage:=nil;
   FCameraType:=ftStandard; // Standard 50mm. lens, field of view= 35/50 =35 degrees.
   FFieldOfView:=RadToDeg(ArcTan(35/50));
   FViewType:=fvPerspective; //<-- ViewportMode:=vmShade;
   FBackgroundImage:=TBackgroundImage.Create(Self);
   FHorScrollbar:=nil;
   FVertScrollbar:=nil;
{     BorderStyle:=bsNone;
      BorderWidth:=0;
      BevelWidth:=0;
      BevelInner:=bvNone;
      BevelOuter:=bvNone;
}
   Inherited Create( AOwner );
   FZBuffer:=TZBuffer.Create;
   FZBuffer.FViewport:=self;
   FAlphaBuffer:=TAlphaBuffer.Create;
   FAlphaBuffer.FViewport:=self;
   FLight.Position.X:=50;   // 30;  // 50;
   FLight.Position.Y:=20;   // 120; // 20;
   FLight.Position.Z:=10;   // 5;   // 2;
   FLight.Ambient:=25;      // 75;  // 64;
   FLight.Luminance:=192;   // 192; // 140;
{    if ViewType=fvPerspective
        then ViewportMode:=vmShade
        else FViewportmode:=vmWireFrame;
}                                       // Load next cursors from resource file
   Screen.Cursors[crRotate]   :=LoadCursor(hInstance,'ROTATE'     ); // = 1 ROTATEVIEWPORT
   Screen.Cursors[crPan]      :=DWord( crDrag );                     // = 2 PANVIEWPORT
   Screen.Cursors[crSetOrigin]:=LoadCursor(hInstance,'SETORIGIN'  ); // = 3 SETORIGIN
   Screen.Cursors[crSetScale] :=LoadCursor(hInstance,'SETSCALE'   ); // = 4 SETSCALE
   Screen.Cursors[crTranspCol]:=LoadCursor(hInstance,'COLORPICKER'); // = 5 TRANSPARENTCOLOR
 { Screen.Cursors[crSetPoint] :=LoadCursor(hInstance,'SETPOINT'   );   ## 6
   Screen.Cursors[crSetLine]  :=LoadCursor(hInstance,'SETLINE'    );   ## 7
   Screen.Cursors[crSetSpline]:=LoadCursor(hInstance,'SETSPLINE'  );   ## 8
                  crSmallCross = X
                  crColorPicker }
   FontName:=UFont;           //'Consolas'; // 'Times New Roman'; // 'Courier';
   FontColor:=clNavy;                       // clOlive; // clWhite;
   FontSize:=St.Preferences.FontSize;
   Invalidate;
end;

destructor TViewport.Destroy;
begin
   FZBuffer.Destroy;
   FAlphaBuffer.Destroy;
   FBackgroundImage.Destroy;
   inherited Destroy;
end;

procedure TViewport.DrawLineToZBuffer( Point1,Point2:Vector; R,G,B:Integer);
var D,ax,ay,sx,sy,dx,dy,W,H: Integer; P1,P2: TShadePoint; dZ: Real;
begin
   P1:=self.ProjectToZBuffer(ZBufferScaleFactor,Point1);
   W:=ClientWidth;
   H:=ClientHeight;
   P2:=self.ProjectToZBuffer(ZBufferScaleFactor,Point2);
   dx:=P2.X-P1.X;
   dy:=P2.Y-P1.Y;
   ax:=Abs( dx ) shl 1;
   ay:=Abs( dy ) shl 1;
   if dx>=0 then sx:=1 else sx:=-1;
   if dy>=0 then sy:=1 else sy:=-1;
   if ax>ay then begin
      if dx=0 then dz:=0
              else dz:=(P2.Z-P1.Z)/abs(dx);
      d:=ay-ax shr 1;
      While P1.X<>P2.X do begin
         if (P1.Y>0) and (P1.Y<H) then begin
            if (P1.Y>-1) and (P1.Y<H) and (P1.X>0) and (P1.X<W) then begin
               if P1.Z>=FZBuffer.FBuffer[P1.Y][P1.X] then begin
                  Canvas.Pixels[ P1.X,P1.Y ]:=RGBtoColor( R,G,B );
                  FZBuffer.FBuffer[P1.Y][P1.X]:=P1.Z;
               end;
            end;
         end;
         if D>=0 then begin inc(P1.Y,sy); dec(d,ax); end;
         P1.Z:=P1.Z+dZ;
         inc(P1.X,sx);
         inc(d,ay);
      end;
   end else begin
      if dy=0 then dZ:=0
              else dz:=(P2.Z-P1.Z)/abs(dy);
      d:=ax-ay shr 1;
      while P1.Y<>P2.Y do begin
         if (P1.Y>0) and (P1.Y<H) then begin
            if (P1.Y>-1) and (P1.Y<H) and (P1.X>0) and (P1.X<W) then begin
               if P1.Z>=FZBuffer.FBuffer[P1.Y][P1.X] then begin
                  Canvas.Pixels[ P1.X,P1.Y ]:=RGBtoColor( R,G,B );
                  FZBuffer.FBuffer[P1.Y][P1.X]:=P1.Z;
               end;
            end;
         end;
         if d>=0 then begin inc(P1.X,sx); dec(d,ay); end;
         inc(P1.Y,sy); P1.Z:=P1.Z+dZ; inc(d,ax);
      end;
   end;
end;

procedure TViewport.InitializeViewport(Min,Max:Vector);
                 // This procedure initializes the viewports and sets the scale
                 //  in such a way that the model completely fills the viewport
var P: array[1..8] of Vector;
    Projected,Min2D,Max2D: Place;  Pt1,Pt2: TPoint;
    P3D,Diff: Vector;
    I,VertCorr,HorCorr: Integer;
    Width,Height,Tmp,XScale,YScale: Real;
   procedure MinMax(P:Place);
   begin if P.X<Min2D.X then Min2D.X:=P.X;
         if P.Y<Min2D.Y then Min2D.Y:=P.Y;
         if P.X>Max2D.X then Max2D.X:=P.X;
         if P.Y>Max2D.Y then Max2D.Y:=P.Y;
   end;
begin                                                             // Add margin
   Diff:=(FMargin*0.01)*(Max-Min);
   FMin3D:=Min-Diff;
   Diff:=-1.0*Diff;
   FMax3D:=Max-diff;
   // Calculate the midpoint of the boundingbox, which is used as the center of the model for rotating the model
   FMidPoint:=MidPoint(FMin3D,FMax3D);
   // Calculate the distance of the camera to the center of the model, following from the field of view from the camera
   Tmp:=hypot( FMax3D.Y-FMin3D.Y,FMax3D.Z-FMin3D.Z );
   if Tmp=0 then Tmp:=1e-2;
   if FViewtype=fvPerspective then begin
      if ArcTan(DegToRad(FFieldOfView))<>0 then begin
         FDistance:=1.5*Tmp/ArcTan(DegToRad(FFieldOfView));
         if FDistance>1e5 then FDistance:=1e5;
      end else FDistance:=1e5;
   end else FDistance:=1e8;
   FCameraLocation.X:=FMax3D.X+FDistance;
   FCameraLocation.Y:=FMidPoint.Y;
   FCameraLocation.Z:=FMidPoint.Z;
   FLightIntensity:=FLight.Luminance/256.0;
   FAmbientIntencity:=FLight.Ambient/256.0;
   FCosAngle:=Cos(DegToRad(FAngle));
   FSinAngle:=sin(DegToRad(FAngle));
   FCosElevation:=Cos(DegToRad(FElevation));
   FSinElevation:=sin(DegToRad(FElevation));

   // now project all 8 cornerpoints of the bounding box to 2D
   // in order to determin the min. and max. 2D coordinates of the 2D viewport.
   P[1]:=FMin3D;   P[2].X:=FMax3D.X;   P[2].Y:=FMin3D.Y;   P[2].Z:=FMin3D.Z;
                   P[3].X:=FMax3D.X;   P[3].Y:=FMax3D.Y;   P[3].Z:=FMin3D.Z;
                   P[4].X:=FMin3D.X;   P[4].Y:=FMax3D.Y;   P[4].Z:=FMin3D.Z;
                   P[5].X:=FMin3D.X;   P[5].Y:=FMin3D.Y;   P[5].Z:=FMax3D.Z;
                   P[6].X:=FMax3D.X;   P[6].Y:=FMin3D.Y;   P[6].Z:=FMax3D.Z;
   P[7]:=FMax3D;   P[8].X:=FMin3D.X;   P[8].Y:=FMax3D.Y;   P[8].Z:=FMax3D.Z;
   for I:=1 to 8 do begin
      P3D:=RotatedPoint(P[i]);           // apply perspective projection
      Tmp:=FCameralocation.X-P3D.X;      // apply perspective correction
      Projected.X:=FCameralocation.X*P3D.Y/Tmp;
      Projected.Y:=FCameralocation.X*P3D.Z/Tmp;
      if I=1 then begin
         Min2D:=Projected;
         Max2D:=Projected;
      end;
      MinMax(Projected);
   end;
   Width:=Max2D.X-Min2D.X;
   Height:=Max2D.Y-Min2D.Y;
   if (abs(Width)>1e-7) and (abs(Height)>1e-7) then begin
      XScale:=ClientWidth/Width;
      YScale:=ClientHeight/Height;
      if XScale<YScale then FScale:=XScale
                       else FScale:=YScale;
   end else FScale:=1; // Decrease Scale with 1% to keep the model  from the edges
   FScale:=0.99*FScale;
   FScreencenter.X:=ClientWidth div 2;
   FScreencenter.Y:=ClientHeight div 2;
                         // Calculate correction (pan iVect) to make sure
                         // that the St appears in the middle of the viewport
   Pt1.X:=FScreencenter.X+Round( FScale*Min2D.X );
   Pt1.Y:=FScreencenter.Y-Round( FScale*Min2D.Y );
   Pt2.X:=FScreencenter.X+Round( FScale*Max2D.X );
   Pt2.Y:=FScreencenter.Y-Round( FScale*Max2D.Y );
   HorCorr:=(Pt1.X+Pt2.X)div 2 - ClientWidth div 2;
   VertCorr:=(Pt1.Y+Pt2.Y)div 2 - ClientHeight div 2;
   FScreencenter.X:=FScreencenter.X-HorCorr;
   FScreencenter.Y:=FScreencenter.Y-vertCorr;    // Remember the min/max values
   FMin3D:=Min;
   FMax3D:=Max;                                 // Now force a complete repaint
   Invalidate;
end;

function TViewport.Project(P:Vector):TPoint;
var P3D: Vector;
    P2D: Place;
    Dist:Real;
begin
   P3D:=RotatedPoint(P);
   Dist:=FCameralocation.X-P3D.X;               // apply perspective correction
   P2D.X:=FCameralocation.X*P3D.Y/dist;
   P2D.Y:=FCameralocation.X*P3D.Z/Dist;
   Result.X:=FPan.X+FScreencenter.X+Round(FZoom*FScale*P2D.X);
   Result.Y:=FPan.Y+FScreencenter.Y-Round(FZoom*FScale*P2D.Y);
end;

function TViewport.ProjectBack(P:TPoint;Input:Vector):Vector;
var P2D: Place;
    P1,P2,P3D: Vector;
    Dist: Real;
begin                  // convert from screencoordinate to 2D world coordinate
   P2D.X:=(P.X-FPan.X-FScreencenter.X)/(FZoom*FScale);
   P2D.Y:=(P.Y-FPan.Y-FScreencenter.Y)/-(FZoom*FScale);
// Now correct for perspective projection and create a 3D ray through the screen coordinate
   P3D.X:=FMin3D.X;
   Dist:=FCameralocation.X-P3D.X;
   P3D.Y:=P2D.X*dist/FCameralocation.X;
   P3D.Z:=P2D.Y*Dist/FCameralocation.X;
   P1:=RotatedPointBack(P3D);
   P3D.X:=FMax3D.X;
   Dist:=FCameralocation.X-P3D.X;
   P3D.Y:=P2D.X*dist/FCameralocation.X;
   P3D.Z:=P2D.Y*Dist/FCameralocation.X;
   P2:=RotatedPointBack(P3D);
   // Finally project point Input on the ray through P1 and P2
   Result:=ProjectPointOnLine( Input,P1,P2 ); //-- Dist_PL_3D
end;

function TViewport.ProjectBackTo2D( P:TPoint ): Place;
var P2D: Place;
    P1,P2,P3D: Vector;
    Dist: Real;
begin                   // convert from screencoordinate to 2D world coordinate
   P2D.X:=(P.X-FPan.X-FScreencenter.X)/(FZoom*FScale);
   P2D.Y:=(P.Y-FPan.Y-FScreencenter.Y)/-(FZoom*FScale);
// convert from screencoordinate to 2D world coordinate
   P3D.X:=FMin3D.X;
   Dist:=FCameralocation.X-P3D.X;
   P3D.Y:=P2D.X*dist/FCameralocation.X;
   P3D.Z:=P2D.Y*Dist/FCameralocation.X;
   P1:=RotatedPointBack(P3D);
   P3D.X:=FMax3D.X;
   Dist:=FCameralocation.X-P3D.X;
   P3D.Y:=P2D.X*dist/FCameralocation.X;
   P3D.Z:=P2D.Y*Dist/FCameralocation.X;
   P2:=RotatedPointBack(P3D);
   Case ViewType of
      fvBodyplan: begin P2D.X:=P2.Y; P2D.Y:=P2.Z; end;
      fvPlan    : begin P2D.X:=P2.X; P2D.Y:=P2.Y; end;
      fvProfile : begin P2D.X:=P2.X; P2D.Y:=P2.Z; end;
   end;
   Result:=P2D;
end;

// Projects a 3D point to the screen and calculate it's Z-value for the Z-buffer
function TViewport.ProjectToZBuffer(P:Vector):TShadePoint;
var P3D    : Vector;
    P2D    : Place;
    Dist   : Real;
begin
   P3D:=RotatedPoint(P);
   Dist:=FCameralocation.X-P3D.X;               // apply perspective correction
   P2D.X:=FCameralocation.X*P3D.Y/dist;
   P2D.Y:=FCameralocation.X*P3D.Z/Dist;
   Result.X:=FPan.X+FScreencenter.X+Round(FZoom*FScale*P2D.X);
   Result.Y:=FPan.Y+FScreencenter.Y-Round(FZoom*FScale*P2D.Y);
   Result.Z:=FCameralocation.X*P3D.X/Dist;
end;

// Projects a 3D point with a certain z-buffer offset to the screen, used for drawing lines on top of shaded surfaces
function TViewport.ProjectToZBuffer(Scale:Real;P:Vector):TShadePoint;
var P3D  : Vector;
    P2D  : Place;
    Dist : Real;
begin
   P3D:=RotatedPoint(P);
   Dist:=FCameralocation.X-P3D.X;               // apply perspective correction
   P2D.X:=FCameralocation.X*P3D.Y/(Dist);
   P2D.Y:=FCameralocation.X*P3D.Z/(Dist);
   Result.X:=FPan.X+FScreencenter.X+Round(FZoom*FScale*P2D.X);
   Result.Y:=FPan.Y+FScreencenter.Y-Round(FZoom*FScale*P2D.Y);
   Result.Z:=FCameralocation.X*Scale*P3D.X/Dist;
end;

function TViewport.RotatedPoint(P:Vector):Vector;
begin
   // This function takes a point from worldspace and rotates it around the midpoint
   // of the scene as specified by the viewing-parameters (angle/elevation)
   // translate midpoint back to origin
   P:=P-FMidpoint;                                  // Rotate around the origin
   Result.x:=(P.x*FCosAngle-P.y*FSinAngle)*FCosElevation+P.z*FSinElevation;
   Result.y:=P.x*FSinAngle+P.y*FCosAngle;
   Result.z:=-(P.x*FCosAngle-P.y*FSinAngle)*FSinElevation+P.z*FCosElevation;
   // Translate origin back to midpoint
   Result:=Result+FMidPoint;
end;

function TViewport.RotatedPointBack( P:Vector):Vector;
var CosAngle,SinAngle,CosElevation,SinElevation: Real;
begin      // This function takes a point from worldspace and rotates it around
           // the midpoint of the scene as specified by the viewing-parameters
           // (angle/elevation) translate midpoint back to origin
   CosAngle:=Cos(DegToRad(-FAngle));
   SinAngle:=sin(DegToRad(-FAngle));
   CosElevation:=Cos(DegToRad(-FElevation));
   SinElevation:=sin(DegToRad(-FElevation));
   P-=FMidPoint;  // Rotate a point first around Y-axis then around the Z-axis
   Result.x:=(P.x*CosElevation+P.z*SinElevation)*CosAngle-P.y*SinAngle;
   Result.y:=(P.x*CosElevation+P.z*SinElevation)*SinAngle+P.y*CosAngle;
   Result.z:=(-P.x*SinElevation+P.z*CosElevation); // Translate origin back to midpoint
   Result+=FMidPoint;
end;

procedure TViewport.Paint;
var OldCanvas: TCanvas; L: Real; //N: Vector;
begin
 {#!#} Flight.Position:=iVect( 1,0.125,0.0625 ); // {Zero-}CameraLocation;
   if (not (csDestroying in ComponentState))
   and (not (csLoading in ComponentState))
   and (not (csReading in ComponentState))
   and (not (csWriting in ComponentState))
   and (Parent<>nil) then begin  // See if the contents is drawn to the printer
     if ViewportMode<>vmWireframe then begin
        L:=-7.5*Abs( FMin3D-FMax3D );
        FLight.Position:=L*Normalize( FLight.Position );
     end;
     OldCanvas:=Canvas;
     FDestinationWidth:=ClientWidth;
     FDestinationHeight:=ClientHeight;
     if ViewportMode=vmWireframe then Canvas:=OldCanvas;        // Clear buffer
     Canvas.Brush.Color:=Color;
     Canvas.Brush.Style:=bsSolid;
     Canvas.Rectangle( -1,-1,FDestinationWidth+2,FDestinationHeight+2 );
     if BackgroundImage.Bitmap<>nil then BackgroundImage.Draw; // Turn clipping back on
     if ViewportMode<>vmWireframe then begin
       ZBuffer.Initialize;
       AlphaBuffer.Initialize;
     end;
     if Assigned( OnRedraw ) then OnRedraw( Self );
     if ViewportMode<>vmWireframe then begin
        AlphaBuffer.Draw;
        Bitblt(OldCanvas.Handle,0,0,FDestinationWidth,FDestinationHeight,Canvas.Handle,0,0,SRCCOPY);
        Canvas:=OldCanvas;
     end;
     if FSelectionFrameActive then DrawSelectionFrame;
   end;
end;

procedure TViewport.SaveAsBitmap( FileName: String; const ShowDialog: Boolean=true );
Var //I,J: Integer;
  OldCanvas: TCanvas;
  PNG: TPortableNetworkGraphic;
  Dialog: TSaveDialog;
  Ok:boolean;
begin
   if ShowDialog then begin
      Dialog:=TSaveDialog.Create( Self );
      Dialog.InitialDir:=St.Preferences.ExportDirectory;
      Dialog.Title:='Coхранение картинки из ViewPort как есть.';
      Dialog.DefaultExt:= '.png';
      Dialog.Filter:= 'Portable Network Grapfics [*.png]|*.png';
//    Dialog.Options:=[ofEnableSizing,ofViewDetail,ofReadOnly];
      Dialog.FileName:=ExtractFileName( FileName );
      Ok:=Dialog.Execute;
      if Ok then FileName:=Dialog.Filename;
      Dialog.Destroy;
      if not Ok then exit;
  end;
  OldCanvas:=CanVas;
  PNG:=TPortableNetworkGraphic.Create;
  PNG.PixelFormat:=pfDevice;
  PNG.Width:=ClientWidth;
  PNG.Height:=ClientHeight;
  FDestinationWidth:=ClientWidth;
  FDestinationHeight:=ClientHeight;
  BitBlt(PNG.CanVas.Handle,0,0,ClientWidth,ClientHeight,CanVas.Handle,0,0,SRCCOPY);
//  for J:=0 to ClientHeight do
//  for I:=0 to ClientWidth do PNG.CanVas.Pixels[I,J]:=Self.CanVas.Pixels[I,J];
  CanVas:=PNG.CanVas;
  RefResh;
  PNG.SaveToFile( ChangeFileExt( FileName,'.png' ) );
  PNG.Destroy;
  CanVas:=OldCanVas;
  RefResh;
end;

procedure TViewport.Resize;
    begin Inherited Resize; InitializeViewport(FMin3D,FMax3D); end;

Var ShMouse: Integer=2; // задержка начальной реакции мышки на поворот картинки

procedure TViewport.MouseDown(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
var Pt,Diff: TPoint;
    str,Tmp: String;
    XVal,YVal: Real;
    I,Ind: Integer;
    OK: Boolean;
begin Inherited;
   FPreviousPosition:=Point( X,Y );
   ShMouse:=St.Preferences.PointSize;
   if (BackgroundMode<>emNormal) and (ssRight in Shift) then
       BackgroundMode:=emNormal
   else               // Start moving the background image store current origin
   if (BackgroundMode=emSetOrigin) and (ssLeft in Shift)
   then FBackgroundOrigin:=BackgroundImage.Origin else
   if (BackgroundMode=emSetScale) and (ssLeft in Shift) then begin
      Pt:=Project(ZERO);
      if (Scale*Zoom*BackgroundImage.Scale)<>0 then begin
         Diff.X:=round((Pt.X-X)/(Scale*Zoom*BackgroundImage.Scale));
         Diff.Y:=round((Pt.Y-Y)/(Scale*Zoom*BackgroundImage.Scale));
      end else begin
         Diff.X:=Pt.X-X;
         Diff.Y:=Pt.Y-Y;
      end;
      Str:=FloatToDec(-BackgroundImage.Scale*Diff.X,4)+', '
          +FloatToDec( BackgroundImage.Scale*Diff.Y,4);
      if InputQuery(Userstring(91),Userstring(196)+':',str) then begin
         Ind:=Pos(',',Str);
         if Ind<>0 then begin
            OK:=True;
            Tmp:=trim(Copy(Str,1,Ind-1));
            if Tmp<>'' then begin
               Val(Tmp,XVal,I);
               if I<>0 then OK:=False;
            end else XVal:=0;
            Tmp:=trim(Copy(Str,Ind+1,Length(Str)-Ind));
            if Tmp<>'' then begin
               Val(Tmp,YVal,I);
               if I<>0 then OK:=False;
            end else YVal:=0;
            if OK then begin
               if abs(Diff.X)>abs(Diff.Y) then BackgroundImage.FScale:=XVal/-Diff.X
                                          else BackgroundImage.FScale:=YVal/Diff.Y;
               Refresh;
               BackgroundMode:=emNormal;
               if assigned(FOnChangeBackgroundImage) then
                  FOnChangeBackgroundImage(Owner);
            end else ShowMessage(Userstring(197)+'!');
         end else    ShowMessage(Userstring(197)+'!');
      end;
   end else
   if (BackgroundMode=emSetTransparentColor) and (ssLeft in Shift) then begin
      Pt:=Project(ZERO);
      if (Scale*Zoom*BackgroundImage.Scale)<>0 then begin
         Diff.X:=round((Pt.X-X)/(Scale*Zoom*BackgroundImage.Scale));
         Diff.Y:=round((Pt.Y-Y)/(Scale*Zoom*BackgroundImage.Scale));
      end else begin
         Diff.X:=Pt.X-X;
         Diff.Y:=Pt.Y-Y;
      end;
      Pt.X:=BackgroundImage.FOrigin.X-Diff.X;
      Pt.Y:=BackgroundImage.FOrigin.Y-Diff.Y;
      if (Pt.X>=0) and (Pt.X<BackgroundImage.FBitmap.Width)
      and (Pt.Y>=0) and (Pt.Y<=BackgroundImage.FBitmap.Height) then begin
         BackgroundImage.Transparent:=True;
         BackGroundImage.TransparentColor:=BackgroundImage.FBitmap.Canvas.Pixels[Pt.X,Pt.Y];
         Refresh;
         BackgroundMode:=emNormal;
         if assigned(FOnChangeBackgroundImage) then
            FOnChangeBackgroundImage(Owner);
      end else begin
         BackgroundImage.Transparent:=False;
         Refresh;
         BackgroundMode:=emNormal;
         if assigned(FOnChangeBackgroundImage) then
            FOnChangeBackgroundImage(Owner);
      end;
   end else begin
      if Assigned(FOnMouseDown) then OnMouseDown(Self,Button,Shift,X,Y);
      if not focused then setfocus;
      if (ssMiddle in shift) and (Viewtype=fvPerspective) then Cursor:=crRotate;
   end;
end;

procedure TViewport.MouseMove(Shift:TShiftState;X,Y:Integer);
var Desired : TCursor;
    Pt,Prev : TPoint;
    Scale   : Real;
begin
   Inherited;                              // Background image moving procedure
   if (Shift=[ssLeft]) and (Backgroundmode=emSetOrigin) then begin
      Scale:=1.0;
      if scale<>0 then begin
         Prev:=BackgroundImage.ImageCoordinate(FPreviousPosition.X,FPreviousPosition.Y);
         Pt:=BackgroundImage.ImageCoordinate(X,Y);
         Pt.X:=-round((Pt.X-Prev.X)/Scale);
         Pt.Y:=-round((Pt.Y-Prev.Y)/Scale);
         if (Pt.X<>0) or (Pt.Y<>0) then begin
            BackgroundImage.FOrigin.X:=BackgroundImage.FOrigin.X+Pt.X;
            BackgroundImage.FOrigin.Y:=BackgroundImage.FOrigin.Y+Pt.Y;
            if Pt.X<>0 then FPreviousPosition.X:=X;
            if Pt.Y<>0 then FPreviousPosition.Y:=Y;
            Refresh;
         end; exit;
      end;
   end else if (shift=[]) and (Backgroundmode<>emNormal) then begin
      Case Backgroundmode of
         emSetOrigin          : Desired:=crsetOrigin;
         emSetScale           : Desired:=crSetScale;
         emSetTransparentColor: Desired:=crTranspCol;
         else Desired:=cursor;
      end;
      if Cursor<>Desired then Cursor:=Desired;
   end else
   if (Viewtype=fvPerspective)             // rotation using middle mousebutton
   and (shift<>[ssCtrl,ssLeft] ) and ((ssLeft in shift) or (ssmiddle in shift))
   then begin
      Prev:=Point( X-FPreviousPosition.X,Y-FPreviousPosition.Y );
      if abs(Prev.x)+abs(Prev.y)>=ShMouse then begin// St.Preferences.PointSize
        Cursor:=crRotate;         ShMouse:=1;     // немножко излишний пересчёт
        FAngle:=Self.FAngle+(Prev.X)/4;
        while FAngle>180 do FAngle:=FAngle-360;
        while FAngle<-180 do FAngle:=FAngle+360;
        FCosAngle:=Cos(DegToRad(FAngle));
        FSinAngle:=sin(DegToRad(FAngle));

        FElevation:=FElevation+(Prev.Y)/4;
        while FElevation>180 do FElevation:=FElevation-360;
        while FElevation<-180 do FElevation:=FElevation+360;
        FCosElevation:=Cos(DegToRad(FElevation));
        FSinElevation:=sin(DegToRad(FElevation));
        if FHorScrollbar<>nil then
        if FHorScrollbar.Position<>round(angle) then
           FHorScrollbar.Position:=Round(Angle);
        if FVertScrollbar<>nil then
        if FVertScrollbar.Position<>round(Elevation) then
           FVertScrollbar.Position:=Round(Elevation);
        InitializeViewport( FMin3D,FMax3D );
      end;
   end else
   if ssRight in shift then Cursor:=crPan;
   FPreviousPosition:=Point( X,Y );
   if Assigned( FOnMouseMove ) then OnMouseMove( Self,Shift,X,Y );
end;

procedure TViewport.MouseUp(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
begin Inherited;
   if BackgroundMode=emSetOrigin then begin
      // Finished moving the background image
      // Check if origin has changed
      if (FBackgroundOrigin.X<>BackgroundImage.Origin.X) or
         (FBackgroundOrigin.Y<>BackgroundImage.Origin.Y) then begin
         BackgroundMode:=emNormal;
         if assigned(FOnChangeBackgroundImage) then
            FOnChangeBackgroundImage(Owner);
      end;
   end else begin
      if Assigned(FOnMouseUp) then OnMouseUp(Self,Button,Shift,X,Y);
      if Cursor<>crCross then Cursor:=crCross;
   end;
   if not focused then setfocus;
end;

function TViewport.DoMouseWheel
  ( Shift:TShiftState; WheelDelta:Integer; MousePos:TPoint ): Boolean;
const Factor=0.9; //var NewPan,Mid:TPoint;
begin
   Result:=Inherited DoMousewheel( Shift,Wheeldelta,Mousepos );
   MousePos:=self.ScreenToClient( MousePos );
{  if (Focused)
   and (MousePos.X>=0) and (MousePos.X<Clientwidth)
   and (MousePos.Y>=0) and (MousePos.Y<Clientheight) then begin // zoom by using mousewheel
      Mid.X:=ClientWidth div 2;   NewPan.X:=MousePos.X-Mid.X;
      Mid.Y:=ClientHeight div 2;  NewPan.Y:=MousePos.Y-Mid.Y;
}
      if WheelDelta>0 then begin
         FZoom*=Factor;
         FPan.X:=round(Factor*FPan.X);
         FPan.Y:=round(Factor*FPan.Y);
         Refresh;
      end else begin
         FZoom/=Factor;
         FPan.X:=round(FPan.X/Factor);
         FPan.Y:=round(FPan.Y/Factor);
         Refresh;
      end;
// end;
end;

procedure TViewport.SetPenWidth( Width:integer );
    begin if Canvas.Pen.Width<>Width then Canvas.Pen.Width:=Width;
    end;
{$if true}
Procedure TViewport.ShadedColor( Dp:Real; R,G,B:byte; var ROut,GOut,BOut:byte );
const Ambient=0.2; var C,Tmp:Real;
begin
   if Dp<0 then Dp:=-Dp; {else} if Dp>1 then Dp:=1 else Dp:=power( Dp,0.66 );// sqrt( Dp );
   if Dp>=0.80 then begin Tmp:=5-5*Dp;
      if Tmp<0 then C:=0 else C:=Sqrt(Tmp);
      ROut:=Round(255-(255-Dp*R)*C);
      GOut:=Round(255-(255-Dp*G)*C);
      BOut:=Round(255-(255-Dp*B)*C);
   end else begin Dp-=Ambient;
      if Dp<0 then Dp:=0;
      C:=Dp/(0.8-Ambient);
      C:=Ambient+(0.8-Ambient)*C*C;
      ROut:=Round(C*R);
      GOut:=Round(C*G);
      BOut:=Round(C*B);
   end;
end;
{$else}
procedure TViewport.ShadedColor
( Dp:Real; R,G,B:byte; var ROut,GOut,BOut:byte ); Var C: Real; // T: Integer;
begin
  if Dp<0.0 then Dp:=-Dp else if Dp>1.0 then Dp:=1.0;
  C:=FLightIntensity*Dp+FAmbientIntencity;
  if C<0 then C:=-C;
  if C>1.0 then C:=1.0;
  ROut:=Round( R*C );
  GOut:=Round( G*C );
  BOut:=Round( B*C );
end;
{$endif}

procedure TViewport.ShadeTriFace(P_1,P_2,P_3:Vector; R,G,B:byte; Alpha:Byte);
var Normal,Center: Vector;
    LIntensityRatio,ZLeft,dZLeft,ZRight,dZRight: Real;
    Y,XLeft,dXLeft,XRight,dXRight: Integer;
    Pt1,Pt2,Pt3,T: TShadePoint;

   procedure Swap(var A,B:Integer); Var C:Integer; begin C:=A; A:=B; B:=C end;
   procedure ShadeLine( X1,X2,Y: integer;Z1,Z2: Real ); var TZ: Real;
   begin
      if (Y<0) or (Y>FDestinationHeight-1) then exit;
      X1:=X1 div 256;
      X2:=X2 div 256;
      if X1>X2 then begin Swap(X1,X2); TZ:=Z1; Z1:=Z2; Z2:=TZ; end;
      if X1<>X2 then TZ:=(Z2-Z1)/(X2-X1) else TZ:=0.0;
      if (X1>FDestinationWidth-1) or (X2<0) then exit;
      if (X1<0) then begin Z1+=abs(X1)*TZ; X1:=0; end;
      if X2>FDestinationWidth-1 then X2:=FDestinationWidth-1;
      if X1>=0 then            // Use scanline property for faster pixel access
      while X1<=X2 do begin
         if Z1>=FZBuffer.FBuffer[Y][X1] then begin
            if Alpha=255 then begin
               Canvas.Pixels[X1,Y]:={(Alpha shl 24) or} (B shl 16) or (G shl 8) or R; // RGBtoColor( R,G,B );
               FZBuffer.FBuffer[Y][X1]:=Z1;
            end else AlphaBuffer.AddPixelData( X1,Y,R,G,B,Alpha,Z1 );
         end;
         Z1+=TZ; Inc( X1 );
      end;
   end;
begin                                          // Calculate data for the points
   Pt1:=ProjectToZBuffer( P_1 );
   Pt2:=ProjectToZBuffer( P_2 );
   Pt3:=ProjectToZBuffer( P_3 );
   P_1:=RotatedPoint( P_1 );
   P_2:=RotatedPoint( P_2 );
   P_3:=RotatedPoint( P_3 );            // Calculate triangle normal and center
// FLight.Position:=3*CameraLocation;
   Center:=( P_1+P_2+P_3 )/3.0 - FLight.Position;      // Calculate light iVect
   Normal:=UnifiedNormal( P_1,P_2,P_3 );
   LIntensityRatio:=Dotproduct( Normal,Normalize( Center ) ); // /2;
   // Center.z += 2*FLight.Position.z;
   // LIntensityRatio+=Dotproduct( Normal,Normalize( Center ) )/2;
   ShadedColor( LIntensityRatio,R,G,B,R,G,B );
                                            // Sort points according to Y-value
   if Pt2.Y<Pt1.Y then begin T:=Pt1; Pt1:=Pt2; Pt2:=T; end;
   if Pt3.Y<Pt2.Y then begin T:=Pt2; Pt2:=Pt3; Pt3:=T;
      if Pt2.Y<Pt1.Y then begin T:=Pt1; Pt1:=Pt2; Pt2:=T; end;
   end;                           // check if min/max values are outside window
   if ((Pt1.Y>=FDestinationHeight) or (Pt3.Y<=0))
   or ((Pt1.X<0) and (Pt2.X<0) and (Pt3.X<0))
   or ((Pt1.X>FDestinationWidth) and (Pt2.X>FDestinationWidth)
                                 and (Pt3.X>FDestinationWidth)) then exit;
   Pt1.X:=Pt1.X shl 8;
   Pt2.X:=Pt2.X shl 8;
   Pt3.X:=Pt3.X shl 8;
   if Pt3.Y=Pt1.Y then begin
      if Pt2.X>=Pt1.X then ShadeLine( Pt1.X,Pt2.X,Pt1.Y,Pt1.Z,Pt2.Z )
                      else ShadeLine( Pt2.X,Pt1.X,Pt1.Y,Pt2.Z,Pt1.Z );
      if Pt3.X>=Pt2.X then ShadeLine( Pt2.X,Pt3.X,Pt1.Y,Pt2.Z,Pt3.Z )
                      else ShadeLine( Pt3.X,Pt2.X,Pt3.Y,Pt3.Z,Pt2.Z ); Exit;
   end;
   XLeft:=Pt1.X;
   ZLeft:=Pt1.Z;
   if Pt3.Y<>Pt1.Y then begin
      dZLeft:=(Pt3.Z-Pt1.Z)/(Pt3.Y-Pt1.Y);
      dXLeft:=(Pt3.X-Pt1.X) div (Pt3.Y-Pt1.Y);
   end else begin
      dZLeft:=0;
      dXLeft:=0;
   end;
   XRight:=Pt1.X;
   ZRight:=Pt1.Z;
   if Pt2.Y<>Pt1.Y then begin
      dZRight:=(Pt2.Z-Pt1.Z)/(Pt2.Y-Pt1.Y);
      dXRight:=(Pt2.X-Pt1.X) div (Pt2.Y-Pt1.Y);
   end else begin
      dZRight:=0;
      dXRight:=0;
   end;
   Y:=Pt1.Y;
   while Y<Pt2.Y do begin
      if XRight>=XLeft then ShadeLine(XLeft,XRight,Y,ZLeft,ZRight)
                       else ShadeLine(XRight,XLeft,Y,ZRight,ZLeft);
      if Y<Pt2.Y then begin
         Inc(XLeft,dXLeft);   ZLeft+=dZLeft;
         Inc(XRight,dXRight); ZRight+=dZRight;
      end;
      Inc(Y);
   end;
   if Pt2.Y=Pt3.Y then Exit;
   XRight:=Pt2.X;
   ZRight:=Pt2.Z;
   if Pt3.Y<>Pt2.Y then begin
      dZRight:=(Pt3.Z-Pt2.Z)/(Pt3.Y-Pt2.Y);
      dXRight:=(Pt3.X-Pt2.X) div (Pt3.Y-Pt2.Y);
   end;
   for Y:=Pt2.Y to Pt3.Y do begin
      if XRight>=XLeft then ShadeLine(XLeft,XRight,Y,ZLeft,ZRight)
                       else ShadeLine(XRight,XLeft,Y,ZRight,ZLeft);
      Inc( XLeft,dXLeft );   ZLeft+=dZLeft;
      Inc( XRight,dXRight ); ZRight+=dZRight;
   end;
end;

// Draw a smooth shaded triangle to the ZBuffer (used when all 3 corners of the triangle have
// different color, as for example when shading GAUSS curvature

procedure TViewport.ShadeTriangles                 // три точки - три цвета
  ( P_1,P_2,P_3:Vector; R1,G1,B1, R2,G2,B2, R3,G3,B3:byte );
var Left,Right,DLeft,dRight,Tmp,V1,V2,V3:TShadePoint; Y,d: integer;
    Normal,Center:Vector;
    LIntensityRatio:Real;

   procedure SetColor( var P:TShadePoint; R,G,B:byte );
   // Set the color of each vertex based on it's curvature and triangle normal
   begin ShadedColor( LIntensityRatio,R,G,B,R,G,B );
          P.R:=R shl 8;
          P.G:=G shl 8;
          P.B:=B shl 8;
   end;
   procedure ShadeLine(Left,Right:TShadePoint;Y:Integer);
   var Delta,Tmp: TShadePoint; D: Integer;
   begin
//    if (Y<0) or (Y>H-1) then exit;
      Left.X:=Left.X div 256;
      Right.X:=Right.X div 256;
      if Left.X>Right.X then begin Tmp:=Left; Left:=Right; Right:=Tmp; end;
      if (Left.X>ClientWidth-1) or (Right.X<0) or (Y<0) or (Y>ClientHeight-1) then exit;
      D:=Right.X-Left.X;
      if D<>0 then begin
         Delta.Z:=(Right.Z-Left.Z)/d;
         Delta.R:=(Right.R-Left.R) div d;
         Delta.G:=(Right.G-Left.G) div d;
         Delta.B:=(Right.B-Left.B) div d;
      end else begin
         Delta.Z:=0;
         Delta.R:=0;
         Delta.G:=0;
         Delta.B:=0;
      end;
//    if (Left.X>W) or (Right.X<0) then exit;
      if (Left.X<0) then begin
         Left.Z:=Left.Z+-Left.X*Delta.Z;
         Inc(Left.R,-Left.X*Delta.R);
         Inc(Left.G,-Left.X*Delta.G);
         Inc(Left.B,-Left.X*Delta.B);
         Left.X:=0;
      end;
      if Right.X>ClientWidth-1 then Right.X:=ClientWidth-1;
      if Left.X>=0 then begin
         while Left.X<=Right.X do begin
            if Left.Z>FZBuffer.FBuffer[Y][Left.X] then begin
               FZBuffer.FBuffer[Y][Left.X]:=Left.Z;
               Canvas.Pixels[Left.X,Y]:=RGBtoColor(Left.R shr 8,Left.G shr 8,Left.B shr 8);
            end;
            Left.Z:=Left.Z+Delta.Z;
            Inc(Left.R,Delta.R);
            Inc(Left.G,Delta.G);
            Inc(Left.B,Delta.B);
            Inc(Left.X);
         end;
      end;
   end;
begin                                          // Calculate data for the points
   V1:=ProjectToZBuffer(P_1);
   V2:=ProjectToZBuffer(P_2);
   V3:=ProjectToZBuffer(P_3);
   P_1:=RotatedPoint(P_1);
   P_2:=RotatedPoint(P_2);
   P_3:=RotatedPoint(P_3);              // Calculate triangle normal and center
   Normal:=UnifiedNormal(P_1,P_2,P_3);
   Center:=(P_1+P_2+P_3)/3.0;
// FLight.Position:=CameraLocation;
// LIntensityRatio:=abs( Dotproduct(Normal,Normalize(Center-FLight.Position)) );
   LIntensityRatio:=Dotproduct( Normal,Normalize( Center-FLight.Position ) );
   SetColor(V1,R1,G1,B1);
   SetColor(V2,R2,G2,B2);
   SetColor(V3,R3,G3,B3);

   if V2.Y<V1.Y then begin Tmp:=V1; V1:=V2; V2:=Tmp; end;
   if V3.Y<V2.Y then begin Tmp:=V2; V2:=V3; V3:=Tmp;
      if V2.Y<V1.Y then begin Tmp:=V1; V1:=V2; V2:=Tmp; end;
   end;
   V1.X:=V1.X shl 8;
   V2.X:=V2.X shl 8;
   V3.X:=V3.X shl 8;
   if V3.Y=V1.Y then begin
      if V2.X>=V1.X then ShadeLine(V1,V2,V1.Y)
                    else ShadeLine(V2,V1,V1.Y);
      if V3.X>=V2.X then ShadeLine(V2,V3,V1.Y)
                    else ShadeLine(V3,V2,V1.Y); Exit;
   end;

   Left:=V1;
   d:=(V3.Y-V1.Y);
   if d<>0 then begin
      dLeft.Z:=(V3.Z-V1.Z)/d;
      dLeft.X:=(V3.X-V1.X) div d;
      dLeft.R:=(V3.R-V1.R) div d;
      dLeft.G:=(V3.G-V1.G) div d;
      dLeft.B:=(V3.B-V1.B) div d;
   end;

   Right:=V1;
   d:=(V2.Y-V1.Y);
   if d<>0 then begin
      dRight.Z:=(V2.Z-V1.Z)/d;
      dRight.X:=(V2.X-V1.X) div d;
      dRight.R:=(V2.R-V1.R) div d;
      dRight.G:=(V2.G-V1.G) div d;
      dRight.B:=(V2.B-V1.B) div d;
   end;

   Y:=V1.Y;
   if (Y<0) and (V2.Y>0) then begin
      Inc(Left.X,-Y*dLeft.X); Left.Z:=Left.Z+-Y*dLeft.Z;
      Inc(Left.R,-Y*dLeft.R);
      Inc(Left.G,-Y*dLeft.G);
      Inc(Left.B,-Y*dLeft.B);
      Inc(Right.X,-Y*dRight.X); Right.Z:=Right.Z+-Y*dRight.Z;
      Inc(Right.R,-Y*dRight.R);
      Inc(Right.G,-Y*dRight.G);
      Inc(Right.B,-Y*dRight.B);
      Y:=0;
   end;
   while Y<V2.Y do begin
      if Right.X>=Left.X then ShadeLine(Left,Right,Y)
                         else ShadeLine(Right,Left,Y);
      if Y<V2.Y then begin
         Inc(Left.X,dLeft.X); Left.Z:=Left.Z+dLeft.Z;
         Inc(Left.R,dLeft.R);
         Inc(Left.G,dLeft.G);
         Inc(Left.B,dLeft.B);
         Inc(Right.X,dRight.X); Right.Z:=Right.Z+dRight.Z;
         Inc(Right.R,dRight.R);
         Inc(Right.G,dRight.G);
         Inc(Right.B,dRight.B);
      end;
      Inc(Y);
   end;
   if V2.Y=V3.Y then Exit;
   Right:=V2;
   d:=V3.Y-V2.Y;
   if d<>0 then begin
      dRight.Z:=(V3.Z-V2.Z)/d;
      dRight.X:=(V3.X-V2.X) div d;
      dRight.R:=(V3.R-V2.R) div d;
      dRight.G:=(V3.G-V2.G) div d;
      dRight.B:=(V3.B-V2.B) div d;
   end else Fillchar(dRight,SizeOf(dRight),0);

   Y:=V2.Y;
   if (Y<0) and (V3.Y>0) then begin
      Inc(Left.X,-Y*dLeft.X); Left.Z:=Left.Z+-Y*dLeft.Z;
      Inc(Left.R,-Y*dLeft.R);
      Inc(Left.G,-Y*dLeft.G);
      Inc(Left.B,-Y*dLeft.B);
      Inc(Right.X,-Y*dRight.X); Right.Z:=Right.Z+-Y*dRight.Z;
      Inc(Right.R,-Y*dRight.R);
      Inc(Right.G,-Y*dRight.G);
      Inc(Right.B,-Y*dRight.B);
      Y:=0;
   end;
   while Y<=V3.Y do begin
      if Right.X>=Left.X then ShadeLine(Left,Right,Y)
                         else ShadeLine(Right,Left,Y);
      if Y<=V3.Y then begin
         Inc(Left.X,dLeft.X); Left.Z:=Left.Z+dLeft.Z;
         Inc(Left.R,dLeft.R);
         Inc(Left.G,dLeft.G);
         Inc(Left.B,dLeft.B);
         Inc(Right.X,dRight.X); Right.Z:=Right.Z+dRight.Z;
         Inc(Right.R,dRight.R);
         Inc(Right.G,dRight.G);
         Inc(Right.B,dRight.B);
         Inc(Y);
      end;
   end;
end;

procedure TViewport.ZoomExtents;
var Min,Max:Vector;
begin if Assigned( FOnRequestExtents ) then begin
         FOnRequestExtents( self,Min,Max );
         FZoom:=1.0;
         FPan.X:=0;
         FPan.Y:=0; InitializeViewport( Min,Max ); end;
end;

procedure TViewport.ZoomIn;
begin FZoom*=Zoomfactor; FPan.X:=round(Zoomfactor*FPan.X);
                         FPan.Y:=round(Zoomfactor*FPan.Y); Refresh;
end;
procedure TViewport.ZoomOut;
begin FZoom/=Zoomfactor; FPan.X:=round(FPan.X/Zoomfactor);
                         FPan.Y:=round(FPan.Y/Zoomfactor); Refresh;
end;
{
  TDevelopedPatch
  Unrolled Subdivision layer
}
function TDevelopedPatch.FGetMaxError:Real; var I:Integer;
begin Result:=0.0;
   for I:=1 to FEdges.Count do begin
      if I=1 then Result:=FEdgeErrors[I-1] else
      if FEdgeErrors[I-1]>result then Result:=FEdgeErrors[I-1];
   end;
end;
//function TDevelopedPatch.FGetShowErrorEdges:Boolean;
//   begin Result:=ShowInteriorEdges and FShowErrorEdges; end;
function TDevelopedPatch.FGetMidPoint:Place;
   begin Result.X:=0.5*(FMin2D.X+FMax2D.X);
         Result.Y:=0.5*(FMin2D.Y+FMax2D.Y);
   end;
function TDevelopedPatch.FGetMinError:Real; Var I:Integer;
begin Result:=0.0;
   for I:=1 to FEdges.Count do begin
      if I=1 then Result:=FEdgeErrors[I-1] else
      if FEdgeErrors[I-1]<result then Result:=FEdgeErrors[I-1];
   end;
end;

function TDevelopedPatch.FGetPoint(index:Integer):Vector; var P: Place;
begin
   P:=F2DCoordinates[index];
   if (FMirrorOnScreen) and not (FMirror) then P.Y:=-P.Y;
   Result:=ConvertTo3D(P);
end;

function TDevelopedPatch.FGetMirrorPoint(index:Integer):Vector;
var P    : Place;
    Tmp  : Vector;
begin
   P:=F2DCoordinates[index];
   Tmp:=iVect(P.X,P.Y,0.0);
   Tmp:=MirrorPlane(Tmp,FMirrorplane);
   P.X:=Tmp.X;
   P.Y:=Tmp.Y;
   if (FMirrorOnScreen) and not (FMirror) then P.Y:=-P.Y;
   Result:=ConvertTo3D(P);
end;

procedure TDevelopedPatch.FSetRotation(Val:Real);
    begin FRotation:=val;
          FCos:=Cos(DegTorad(FRotation));
          FSin:=Sin(DegTorad(FRotation));
    end;
procedure TDevelopedPatch.FSetTranslation(Val:Place);
    begin FTranslation:=Val; end;

procedure TDevelopedPatch.FSetMirrorOnScreen(val:Boolean);
var Value:Real;
begin
   if (val<>FMirrorOnScreen) and (not FMirror) then begin
      FMirrorOnScreen:=Val;
      Value:=FMin2D.Y;
      FMin2D.Y:=-FMax2D.Y;
      FMax2D.Y:=-Value;
      Rotation:=-Rotation;
   end;
end;

procedure TDevelopedPatch.Assign(Org:TDevelopedPatch;Mirror:Boolean);
var I : Integer;
begin
   FName:=Org.FName;
   ShowSolid:=org.ShowSolid;
   ShowPartName:=Org.ShowPartName;
   ShowBoundingBox:=Org.ShowBoundingBox;
   ShowInteriorEdges:=Org.ShowInteriorEdges;
   ShowStations:=Org.ShowStations;
   ShowButtocks:=Org.ShowButtocks;
   ShowWaterlines:=Org.ShowWaterlines;
   ShowDiagonals:=Org.ShowDiagonals;
   ShowErrorEdges:=Org.ShowErrorEdges;
   ShowDimensions:=Org.ShowDimensions;
   ShadeSubmerged:=Org.ShadeSubmerged;
   FBoundaryEdges.Clear;
   FBoundaryEdges.AddList(Org.FBoundaryEdges);
   FPoints.Clear;
   FPoints.AddList(Org.FPoints);
   FEdges.Clear;
   FEdges.AddList(Org.FEdges);
   FCorners.Clear;
   FCorners.AddList(Org.FCorners);
   FDoneList.Clear;
   FDoneList.AddList(Org.FDoneList);
   Rotation:=-Org.Rotation;
   Translation:=Org.Translation;
   FNoIterations:=Org.FNoIterations;
   FMirrorOnScreen:=Org.FMirrorOnScreen;
   if length(Org.F2DCoordinates)>0 then begin
      Setlength(F2DCoordinates,FPoints.Count);
      for I:=1 to FPoints.Count do begin
         F2DCoordinates[I-1]:=Org.F2DCoordinates[I-1];
         if Mirror then F2DCoordinates[I-1].Y:=-F2DCoordinates[I-1].Y;
         if I=1 then begin
            FMin2D:=F2DCoordinates[I-1];
            FMax2D:=FMin2D;
         end else begin
            if F2DCoordinates[I-1].X<FMin2D.X then FMin2D.X:=F2DCoordinates[I-1].X;
            if F2DCoordinates[I-1].Y<FMin2D.Y then FMin2D.Y:=F2DCoordinates[I-1].Y;
            if F2DCoordinates[I-1].X>FMax2D.X then FMax2D.X:=F2DCoordinates[I-1].X;
            if F2DCoordinates[I-1].Y>FMax2D.Y then FMax2D.Y:=F2DCoordinates[I-1].Y;
         end;
      end;
   end;
   Setlength(FEdgeErrors,Fedges.Count);
   Move(Org.FEdgeErrors[0],FEdgeErrors[0],FEdges.Count*SizeOf(Real));
   FMaxAreaError:=Org.FMaxAreaError;
   FTotalAreaError:=Org.FTotalAreaError;
end;

procedure TDevelopedPatch.Clear;
var I     : Integer;
    Spline: TSpline;
begin
   FConnectedMirror:=nil;
   FXGrid:=1;
   FYGrid:=1;
   FNoIterations:=0;
   FName:='';
   FPoints.Clear;
   FEdges.Clear;
   FDoneList.Clear;
   FCorners.Clear;
   FBoundaryEdges.Clear;
   Setlength(F2DCoordinates,0);
   Setlength(FEdgeErrors,0);
   Rotation:=0.0;
   FMin2D.X:=0.0;
   FMin2D.Y:=0.0;
   FMax2D:=FMin2D;
   FTranslation:=FMin2D;
   ShowSolid:=True;
   ShowBoundingBox:=False;
   ShowInteriorEdges:=True;
   ShowStations:=True;
   ShowButtocks:=True;
   ShowWaterlines:=True;
   ShowDiagonals:=True;
   ShowErrorEdges:=True;
   ShowDimensions:=True;
   ShowPartName:=True;
   ShadeSubmerged:=True;
   Visible:=True;
   FMirrorOnScreen:=False;
   for I:=1 to FStations.Count do begin
      Spline:=FStations[I-1];
      Spline.Destroy;
   end;
   FStations.Clear;
   for I:=1 to FButtocks.Count do begin
      Spline:=FButtocks[I-1];
      Spline.Destroy;
   end;
   FButtocks.Clear;
   for I:=1 to FWaterlines.Count do begin
      Spline:=FWaterlines[I-1];
      Spline.Destroy;
   end;
   FWaterlines.Clear;
   for I:=1 to FDiagonals.Count do begin
      Spline:=FDiagonals[I-1];
      Spline.Destroy;
   end;
   FDiagonals.Clear;
end;

constructor TDevelopedPatch.Create;
begin
   Inherited Create;
   FOwner:=Owner;
   FPoints:=TFasterList.Create;
   FEdges:=TFasterList.Create;
   FDoneList:=TFasterList.Create;
   FBoundaryEdges:=TFasterlist.Create;
   FStations:=TFasterList.Create;
   FWaterlines:=TFasterList.Create;
   FButtocks:=TFasterList.Create;
   FDiagonals:=TFasterList.Create;
   FCorners:=TFasterList.Create;
   Clear;
end;

destructor TDevelopedPatch.Destroy;
begin
   Clear;
   Fillchar(FMirrorplane,SizeOf(FMirrorplane),0);
   FMirror:=False;
   FPoints.Destroy;
   FEdges.Destroy;
   FDoneList.Destroy;
   FBoundaryEdges.Destroy;
   FStations.Destroy;
   FWaterlines.Destroy;
   FButtocks.Destroy;
   FDiagonals.Destroy;
   FCorners.Destroy;
   Inherited Destroy;
end;

function TDevelopedPatch.DistanceToCursor(X,Y:Integer;Viewport:TViewport):integer;
var I,S,E   : Integer;
    Edge    : SEdge;
    P1,P2   : Vector;
    Dist    : integer;
    Param   : Real;
begin
   Result:=1000000;                     // check distance to all interior edges
   for I:=1 to FEdges.Count do begin
      Edge:=FEdges[I-1];
      S:=FPoints.SortedIndexOf(Edge.StartPoint);
      E:=FPoints.SortedIndexOf(Edge.EndPoint);
      if (S<>-1) and (E<>-1) then begin
         P1:=Point[S];
         P2:=Point[E];
         Dist:=Round(DistanceToLine(Viewport.Project(P1),Viewport.Project(P2),X,Y,Param));
         if dist<Result then Result:=Dist;
         if FMirror then begin
            P1:=MirrorPoint[S];
            P2:=MirrorPoint[E];
            Dist:=Round(DistanceToLine(Viewport.Project(P1),Viewport.Project(P2),X,Y,Param));
            if dist<Result then Result:=Dist;
         end;
      end;
   end;
end;

procedure TDevelopedPatch.Draw(Viewport:TViewport);
var I,J,K,S,E,Index,Cap,Na,Nb,r,g,b: Integer;
    Face       : SFace;
    Edge       : SEdge;
    Point      : SPoint;
    Pts        : array of TPoint;
    Pt         : TPoint;
    P1,P2,P3,Min,Max: Vector;
    EdgeColor  : TColor;
    Str        : string;
    WlPlane    : Plate;
    MinZ,MaxZ,s1,s2,s3: Real;
    Above,Below: VectorArray;

    procedure DrawSpline(Spline:TSpline);
    var I   : Integer;
        P2D : Place;
        P3D : Vector;
        Pts : array of TPoint;
    begin
       Setlength(Pts,Spline.Fragments+1);
       for I:=0 to Spline.Fragments do begin
          P3D:=Spline.Value(I/Spline.Fragments);
          P2D.X:=P3D.X;
          P2D.Y:=P3D.Y;
          if (FMirrorOnScreen) and not (FMirror) then P2D.Y:=-P2D.Y;
          P3D:=self.ConvertTo3D(P2D);
          Pts[I]:=Viewport.Project(P3D);
       end;
       Viewport.SetPenWidth(1);
       Viewport.PenColor:=Spline.Color;
       Viewport.Canvas.Polyline(Pts);
    end;

   procedure SetFontHeight(DesiredHeight:Real);
   var Height         : Real;
       CurrentHeight  : Integer;
   begin                       // Sets the fontheight to a height in modelspace
      Height:=DesiredHeight*Viewport.Scale*Viewport.Zoom;
      Viewport.Canvas.Font.Size:=8;
      CurrentHeight:=Viewport.Canvas.TextHeight('X');
      while CurrentHeight>Height do begin
         Viewport.Canvas.Font.Size:=Viewport.Canvas.Font.Size-1;
         CurrentHeight:=Viewport.Canvas.TextHeight('X');
         if Viewport.Canvas.Font.Size<3 then break;
      end;
   end;

   procedure Swap(var P1,P2:Vector);
        var Tmp:Vector; begin Tmp:=P1; P1:=P2; P2:=Tmp; end;
   procedure DrawDimension(P1,P2:Vector);
   var Tmp: Integer; P: Vector; Pt: TPoint; Str: string;
   begin
      if P2.X<>P1.X then begin
         if P2.X<P1.X then Swap(P1,P2);
         Tmp:=Trunc(P1.X/XGrid)-1;
         P.X:=Tmp*XGrid;
         while P.X<=P2.X+XGrid do begin
            if (Abs(P.X-P1.X)<1e-4)
            or (Abs(P.X-P2.X)<1e-4)
            or ((P.X>=P1.X) and (P.X<=P2.X)) then begin
               P.Y:=P1.Y+((P.X-P1.X)/(P2.X-P1.X))*(P2.Y-P1.Y);
               P.Z:=0.0;
               Pt:=Viewport.Project(P);
               Str:=ConvertDimension(P.Y,Units);
               Viewport.Canvas.TextOut(Pt.X-Viewport.Canvas.TextWidth(Str) div 2,Pt.Y,Str);
            end;
            P.X+=XGrid;
         end;
      end;
      if abs(P2.Y-P1.Y)<>0.0 then begin
         if P2.Y<P1.Y then Swap(P1,P2);
         Tmp:=Trunc(P1.Y/YGrid)-1;
         P.Y:=Tmp*YGrid;
         while P.Y<=P2.Y+YGrid do begin
            if (Abs(P.Y-P1.Y)<1e-4)
            or (Abs(P.Y-P2.Y)<1e-4)
            or ((P.Y>=P1.Y) and (P.Y<=P2.Y)) then begin
               P.X:=P1.X+((P.Y-P1.Y)/(P2.Y-P1.Y))*(P2.X-P1.X);
               P.Z:=0.0;
               Pt:=Viewport.Project(P);
               Str:=ConvertDimension(P.X,Units);
               Viewport.Canvas.TextOut(Pt.X-Viewport.Canvas.TextWidth(Str) div 2,Pt.Y,Str);
            end;
            P.Y+=YGrid;
         end;
      end;
   end;
   procedure DrawTriangle( P1,P2,P3:Vector;Color:TColor );
   var Pts:array[0..2] of TPoint;
   begin
      Pts[0]:=Viewport.Project(P1);
      Pts[1]:=Viewport.Project(P2);
      Pts[2]:=Viewport.Project(P3);
      Viewport.PenColor:=Color;
      Viewport.BrushColor:=Color;
      Viewport.Canvas.Polygon(Pts);
   end;
begin
   r:=( 9*GetRValue(Owner.Color) ) div 10;
   g:=( 9*GetGValue(Owner.Color) ) div 10;
   b:=( 9*GetBValue(Owner.Color) ) div 10;
   EdgeColor:=RGB(r,g,b);
   r:=( 11*GetRValue(Owner.Color) ) div 10; if r>255 then r:=255;
   g:=( 11*GetGValue(Owner.Color) ) div 10; if g>255 then g:=255;
   b:=( 11*GetBValue(Owner.Color) ) div 10; if b>255 then b:=255;
   Viewport.BrushColor:=RGB( r,g,b );
   Viewport.PenWidth:=1;                                      //PenwidthFactor;
   if ShowInteriorEdges then Viewport.PenColor:=EdgeColor else
   if ShowSolid then Viewport.PenColor:=Viewport.BrushColor
                else Viewport.PenColor:=clWhite;
   if ShowSolid then Viewport.BrushStyle:=bsSolid
                else Viewport.BrushStyle:=bsClear;
   Viewport.PenStyle:=psSolid;
   Cap:=0;
   if (ShowSolid) or (ShowInteriorEdges) then begin
      Viewport.BrushColor:=RGB(r,g,b);
      if (not showSolid) then Viewport.BrushStyle:=bsClear;
      Wlplane:=Owner.Owner.WaterlinePlane;
      for I:=1 to FDoneList.Count do begin
         Face:=FDoneList[I-1];
         if cap<>Face.Nopoints then begin
            Cap:=Face.Nopoints;
            setlength(Pts,Cap);
         end;
         if ShadeSubmerged then begin
            for J:=3 to Face.Nopoints do begin
               Index:=FPoints.SortedIndexOf(Face.Point[0]);
               if Index<>-1 then P1:=self.Point[index];
               Index:=FPoints.SortedIndexOf(Face.Point[J-2]);
               if Index<>-1 then P2:=self.Point[index];
               Index:=FPoints.SortedIndexOf(Face.Point[J-1]);
               if Index<>-1 then P3:=self.Point[index]; // Check if clipping is required
               Point:=Face.Point[0];
               s1:=WlPlane.a*Point.Coordinate.x+WlPlane.b*Point.Coordinate.y+WlPlane.c*Point.Coordinate.z+WlPlane.d;
               MinZ:=s1;
               MaxZ:=MinZ;
               Point:=Face.Point[J-2];
               s2:=WlPlane.a*Point.Coordinate.x+WlPlane.b*Point.Coordinate.y+WlPlane.c*Point.Coordinate.z+WlPlane.d;
               if s2<MinZ then MinZ:=s2 else if s2>MaxZ then MaxZ:=s2;
               Point:=Face.Point[J-1];
               s3:=WlPlane.a*Point.Coordinate.x+WlPlane.b*Point.Coordinate.y+WlPlane.c*Point.Coordinate.z+WlPlane.d;
               if s3<MinZ then MinZ:=s3 else if s3>MaxZ then MaxZ:=s3;
               if MaxZ<=0.0 then begin               // entirely below the plane
                  DrawTriangle(P1,P2,P3,Sp.UColor );
               end else if MinZ>=0.0 then begin      // entirely above the plane
                  DrawTriangle(P1,P2,P3,Owner.Color);
               end else begin                   // pierces water, clip triangle
                  ClipTriangle(P1,P2,P3,s1,s2,s3,Na,Nb,Above,Below);
                  for K:=3 to Na do DrawTriangle(Above[0],Above[K-2],Above[K-1],Owner.Color);
                  for K:=3 to Nb do DrawTriangle(Below[0],Below[K-2],Below[K-1],Sp.UColor );
               end;
            end;
         end else begin
            for J:=1 to Face.Nopoints do begin
               Index:=FPoints.SortedIndexOf(Face.Point[J-1]);
               if Index<>-1 then begin
                  P1:=self.Point[index];
                  Pts[J-1]:=Viewport.Project(P1);
               end; // else Raise Exception.Create('Unrolled point could not be found!');
            end;
            Viewport.Canvas.Polygon(Pts);
         end;
         if FMirror then begin
            for J:=1 to Face.Nopoints do begin
               Index:=FPoints.SortedIndexOf(Face.Point[J-1]);
               if Index<>-1 then begin
                  P1:=MirrorPoint[index];
                  Pts[J-1]:=Viewport.Project(P1);
               end; // else Raise Exception.Create('Unrolled point could not be found!');
            end;
            Viewport.Canvas.Polygon(Pts);
         end;
      end;
   end;

   if not ShowInteriorEdges then begin              // Draw only boundaryedges
      Viewport.PenColor:=EdgeColor;
      Viewport.PenStyle:=psSolid;
      Viewport.PenWidth:=1; //*PenwidthFactor;
      for I:=1 to FBoundaryEdges.Count do begin
         Edge:=FBoundaryEdges[I-1];
         S:=FPoints.SortedIndexOf(Edge.StartPoint);
         E:=FPoints.SortedIndexOf(Edge.EndPoint);
         if (S<>-1) and (E<>-1) then begin
            Pt:=Viewport.Project(self.Point[S]);
            Viewport.Canvas.MoveTo(Pt.X,Pt.Y);
            Pt:=Viewport.Project(self.Point[E]);
            Viewport.Canvas.LineTo(Pt.X,Pt.Y);
            if FMirror then begin
               Pt:=Viewport.Project(MirrorPoint[S]);
               Viewport.Canvas.MoveTo(Pt.X,Pt.Y);
               Pt:=Viewport.Project(MirrorPoint[E]);
               Viewport.Canvas.LineTo(Pt.X,Pt.Y);
            end;
         end;
      end;
   end;
   if ShowDimensions then begin                              // draw dimensions
      Viewport.PenColor:=clBlack;
      Viewport.BrushStyle:=bsClear;
      Viewport.PenWidth:=1; //PenwidthFactor;
      Viewport.FontName:=UFont;                 // calculate and set fontheight
      SetFontHeight(Abs(Viewport.Min3D-Viewport.Max3D)/150);
      for I:=1 to FBoundaryEdges.Count do begin
         Edge:=FBoundaryEdges[I-1];
         if (not FMirror)
         or (FMirror and (abs(Edge.StartPoint.Coordinate.Y)>1e-3)
                     and (abs(Edge.EndPoint.Coordinate.Y)>1e-3)) then begin
            S:=FPoints.SortedIndexOf(Edge.StartPoint);
            E:=FPoints.SortedIndexOf(Edge.EndPoint);
            if (S<>-1) and (E<>-1) then begin
               DrawDimension(self.Point[S],self.Point[E]);
               if FMirror then DrawDimension(MirrorPoint[S],MirrorPoint[E]);
            end;
         end;
      end;
      for I:=1 to FCorners.Count do begin
         Point:=FCorners[I-1];
         S:=FPoints.SortedIndexOf(Point);
         P1:=Self.Point[S];
         Str:='('+ConvertDimension(P1.X,Units)+' / '+ConvertDimension(P1.Y,Units)+')';
         Pt:=Viewport.Project(P1);
         Viewport.Canvas.TextOut(Pt.X-Viewport.Canvas.TextWidth(Str) div 2,Pt.Y,Str);
         if FMirror then begin
            P1:=Self.MirrorPoint[S];
            Str:='('+ConvertDimension(P1.X,Units)+' / '+ConvertDimension(P1.Y,Units)+')';
            Pt:=Viewport.Project(P1);
            Viewport.Canvas.TextOut(Pt.X-Viewport.Canvas.TextWidth(Str) div 2,Pt.Y,Str);
         end;
      end;
   end;
   if ShowInteriorEdges and ShowErrorEdges then begin // show edges with errors
      Viewport.PenWidth:=2; //*PenwidthFactor;
      for I:=1 to FEdges.Count do begin
         if abs(FEdgeErrors[I-1])>1e-4 then begin
            if FEdgeErrors[I-1]>0 then Viewport.PenColor:=clRed
                                  else Viewport.PenColor:=clBlue;
            Edge:=Fedges[I-1];
            S:=FPoints.SortedIndexOf(Edge.StartPoint);
            E:=FPoints.SortedIndexOf(Edge.EndPoint);
            if (S<>-1) and (E<>-1) then begin
               Pt:=Viewport.Project(self.Point[S]);
               Viewport.Canvas.MoveTo(Pt.X,Pt.Y);
               Pt:=Viewport.Project(self.Point[E]);
               Viewport.Canvas.LineTo(Pt.X,Pt.Y);
               if FMirror then begin
                  Pt:=Viewport.Project(MirrorPoint[S]);
                  Viewport.Canvas.MoveTo(Pt.X,Pt.Y);
                  Pt:=Viewport.Project(MirrorPoint[E]);
                  Viewport.Canvas.LineTo(Pt.X,Pt.Y);
               end;
            end;
         end;
      end;
   end;

   if ShowStations then for I:=1 to FStations.Count do DrawSpline(FStations[I-1]);
   if ShowButtocks then for I:=1 to FButtocks.Count do DrawSpline(FButtocks[I-1]);
   if ShowWaterlines then for I:=1 to FWaterlines.Count do DrawSpline(FWaterlines[I-1]);
   if ShowDiagonals then for I:=1 to FDiagonals.Count do DrawSpline(FDiagonals[I-1]);

   if ShowPartName then begin
      P1:=ConvertTo3D(MidPoint);
      Pt:=Viewport.Project(P1);
      Viewport.FontColor:=clBlack;
      Viewport.PenColor:=clBlack;
      Viewport.PenWidth:=1;
      Viewport.PenStyle:=psSolid;
      Viewport.BrushColor:=clWhite;
      Viewport.BrushStyle:=bsSolid;
      I:=Owner.Owner.ControlPointSize;
      Viewport.Canvas.Font.Size:=7;
      Viewport.Canvas.Rectangle(Pt.X-I,Pt.Y-I,Pt.X+I,Pt.Y+I);
      Viewport.BrushStyle:=bsClear;
      Viewport.Canvas.TextOut(Pt.X-Viewport.Canvas.TextWidth(Name) div 2,Pt.Y,Name);
   end;
   if (ShowBoundingBox) {and (not viewport.Printing)} then begin
      Viewport.PenColor:=clBlack;
      Viewport.PenStyle:=psDot;
      Viewport.PenWidth:=1;
      Viewport.BrushStyle:=bsClear;
      Extents(Min,Max);
      Setlength(Pts,4);
      P1:=Min;     Pts[0]:=Viewport.Project(P1);
      P1.X:=Max.X; Pts[1]:=Viewport.Project(P1);
      P1.Y:=Max.Y; Pts[2]:=Viewport.Project(P1);
      P1.X:=Min.X; Pts[3]:=Viewport.Project(P1);
      Viewport.Canvas.Polygon(Pts);
   end;
   Viewport.BrushStyle:=bsClear;
   Viewport.FontColor:=clBlack;
end;

procedure TDevelopedPatch.Extents(var Min,Max:Vector);
var I : Integer;
    P : Vector;
begin
   if FPoints.Count=0 then begin
      Min.X:=-1.0;
      Min.Y:=-1.0;
      Min.Z:= 0.0;
      Max.X:= 1.0;
      Max.Y:= 1.0;
      Max.Z:= 0.0;
   end else for I:=1 to FPoints.Count do begin
      P:=Point[I-1];
      if I=1 then begin
         Min:=P;
         Max:=Min;
      end;
      MinMax(P,Min,Max);
      if FMirror then begin
         P:=MirrorPoint[I-1];
         MinMax(P,Min,Max);
      end;
   end;
end;

procedure TDevelopedPatch.IntersectPlane(Plane:Plate;Color:TColor);
type IntersectionData = record
       Point    : Vector;
       Knuckle  : Boolean;
     end;

var I,J,K,Index1,Index2,ArrayLength,NoPoints: Integer;
    Edge: SEdge;
    P1,P2: SPoint;
    Side1,Side2,Parameter: Real;
    Output: Vector;
    Spline,Copy: TSpline;
    Face: Sface;
    IntArray: array of IntersectionData;
    Dest: TFasterList;
begin
   ArrayLength:=10;
   Setlength( IntArray,ArrayLength );
   Dest:=TFasterList.Create;
   for J:=1 to FDoneList.Count do begin
      Face:=FDoneList[J-1];
      NoPoints:=0;
      P1:=Face.Point[Face.NoPoints-1];
      Side1:=Plane.A*P1.Coordinate.x+Plane.B*P1.Coordinate.y+Plane.C*P1.Coordinate.z+Plane.D;
      for K:=1 to Face.FPoints.Count do begin
         P2:=Face.FPoints[K-1];
         Side2:=Plane.A*P2.Coordinate.x+Plane.B*P2.Coordinate.y+Plane.C*P2.Coordinate.z+Plane.D;
         if ((Side1<-1e-5) and (Side2>1e-5))
         or ((Side1>1e-5) and (Side2<-1e-5)) then begin
                     // regular intersection of edge - add the edge to the list
            Parameter:=-side1/(side2-side1);
            Index1:=FPoints.SortedIndexOf(P1);
            Index2:=FPoints.SortedIndexOf(P2);
            Output.X:=F2DCoordinates[Index1].X+Parameter*(F2DCoordinates[Index2].X-F2DCoordinates[Index1].X);
            Output.Y:=F2DCoordinates[Index1].Y+Parameter*(F2DCoordinates[Index2].Y-F2DCoordinates[Index1].Y);
            Output.Z:=0.0;
            Inc(NoPoints);
            if NoPoints>ArrayLength then begin
               Inc(ArrayLength,10);
               Setlength(IntArray,ArrayLength);
            end;
            IntArray[NoPoints-1].Point:=Output;
            Edge:=Owner.Owner.EdgeExists(P1,P2);
            if Edge<>nil then IntArray[NoPoints-1].Knuckle:=Edge.Crease
                         else IntArray[NoPoints-1].Knuckle:=False;
         end else begin        // Does the edge lie entirely within the plane??
            if ((abs(side1)<=1e-5) and (abs(Side2)<=1e-5)) then begin
            end else if abs(Side2)<1e-5 then begin
               Inc(NoPoints);
               if NoPoints>ArrayLength then begin
                  Inc(ArrayLength,10);
                  Setlength(IntArray,ArrayLength);
               end;
               Index2:=FPoints.SortedIndexOf(P2);
               IntArray[NoPoints-1].Point.X:=F2DCoordinates[Index2].X;
               IntArray[NoPoints-1].Point.Y:=F2DCoordinates[Index2].Y;
               IntArray[NoPoints-1].Point.Z:=0.0;
               IntArray[NoPoints-1].Knuckle:=P2.VertexType<>svRegular;
            end;
         end;
         P1:=P2;
         Side1:=Side2;
      end;
      if NoPoints>1 then begin
         if Sqr( IntArray[0].Point-IntArray[NoPoints-1].Point )<1e-8 then dec(NoPoints);
         if NoPoints>1 then begin
            Spline:=TSpline.Create;
            Spline.Color:=Color;
            Spline.Capacity:=NoPoints;
            for K:=1 to NoPoints do begin
               Spline.Add(IntArray[K-1].Point);
               Spline.Knuckle[Spline.nS-1]:=IntArray[K-1].Knuckle;
            end;
            Dest.Add(Spline);
         end;
      end;
   end;
   if Dest.Count>1 then begin
      Dest.Capacity:=Dest.Count;
      JoinSplineSegments(0.01,False,Dest);
      for I:=Dest.Count downto 1 do begin // Remove tiny fragments of very small length
         Spline:=Dest[I-1];
         if Spline.nS>1 then begin
            Parameter:=Sqr( Spline.Min-Spline.Max ); // SquaredDistPP(Spline.Min,Spline.Max);
            if Parameter<1e-3 then begin
               Spline.Destroy;
               Dest.Delete(I-1);
            end;
         end;
      end;
   end;
   for I:=1 to Dest.Count do begin
      Spline:=Dest[I-1];
      if abs(Plane.a)>0.9999 then FStations.Add(Spline) else
      if abs(Plane.b)>0.9999 then FButtocks.Add(Spline) else
      if abs(Plane.c)>0.9999 then FWaterlines.Add(Spline) else
      if (abs(Plane.b)>0.5) and (abs(Plane.c)>0.5) then FDiagonals.Add(Spline);
      if FMirror then begin
         Copy:=TSpline.Create;
         Copy.Assign(Spline);
         for J:=1 to Spline.nS do
            Copy.Point[J-1]:=MirrorPlane(Spline.Point[J-1],FMirrorPlane);
         if abs(Plane.a)>0.9999 then FStations.Add(Copy) else
         if abs(Plane.b)>0.9999 then FButtocks.Add(Copy) else
         if abs(Plane.c)>0.9999 then FWaterlines.Add(Copy) else
         if (abs(Plane.b)>0.5) and (abs(Plane.c)>0.5) then FDiagonals.Add(Copy);
      end;
   end;
   Dest.Destroy;
end;

function TDevelopedPatch.ConvertTo3D(P:Place):Vector;
var Mid,P2: Place;
begin
   Mid:=MidPoint;              // translate to origin
   P2.X:=P.X-Mid.X;
   P2.Y:=P.Y-Mid.Y;            // rotate around origin
   P.x:=P2.x*FCos-P2.y*FSin;
   P.y:=P2.x*FSin+P2.y*FCos;   // Translate back again
   Result.X:=P.X+Mid.X+FTranslation.X;
   Result.Y:=P.Y+Mid.Y+FTranslation.Y;
   result.Z:=0.0;
end;

procedure TDevelopedPatch.SaveToDXF(Strings:TStringList);
var I,J,Col,Index: integer;
    P    : SPoint;
    P3D  : Vector;
    Layer: String;
    Source,Dest:TFasterList;

   procedure ExportSpline(Spline:TSpline;Layername:string);
    var I,Col: Integer; P2D: Place; P3D: Vector;
    begin
       Col:=FindDXFColorIndex(Spline.Color);
       Strings.Add('0'+EOL+'POLYLINE');
       Strings.Add('8'+EOL+LayerName);       // layername
       Strings.Add('62'+EOL+IntToStr(Col));  // color by layer
       Strings.Add('66'+EOL+'1');            // vertices follow
       for I:=0 to Spline.Fragments do begin
          P3D:=Spline.Value(I/Spline.Fragments);
          P2D.X:=P3D.X;
          P2D.Y:=P3D.Y;
          if (FMirrorOnScreen) and not (FMirror) then P2D.Y:=-P2D.Y;
          P3D:=ConvertTo3D(P2D);
          Strings.Add('0'+EOL+'VERTEX');
          Strings.Add('8'+EOL+Layername);
          Strings.Add('10'+EOL+FloatToDec(P3D.X,4));
          Strings.Add('20'+EOL+FloatToDec(P3D.Y,4));
       end;
       Strings.Add('0'+EOL+'SEQEND');
    end;
begin                                             // Extract edges as polylines
   Source:=TFasterList.Create;
   Source.AddList(FBoundaryEdges);
   Dest:=TFasterList.Create;
   Owner.Owner.IsolateEdges(Source,Dest);
   Source.Destroy;
   Col:=FindDXFColorIndex(Owner.Color);
   Layer:=Owner.Name;
   for I:=1 to Dest.Count do begin
      Source:=Dest[I-1];                        // Save data as 2D polyline
      Strings.Add('0'+EOL+'POLYLINE');
      Strings.Add('8'+EOL+Layer);               // layername
      Strings.Add('62'+EOL+IntToStr(Col));      // color by layer
      Strings.Add('66'+EOL+'1');                // vertices follow
      for J:=1 to Source.Count do begin
         P:=Source[J-1];
         Index:=FPoints.SortedIndexOf(P);
         P3D:=Point[Index];
         Strings.Add('0'+EOL+'VERTEX');
         Strings.Add('8'+EOL+Layer);
         Strings.Add('10'+EOL+FloatToDec(P3D.X,4));
         Strings.Add('20'+EOL+FloatToDec(P3D.Y,4));
      end;
      Strings.Add('0'+EOL+'SEQEND');
      if FMirror then begin
         Strings.Add('0'+EOL+'POLYLINE');
         Strings.Add('8'+EOL+Layer);            // layername
         Strings.Add('62'+EOL+IntToStr(Col));   // color by layer
         Strings.Add('66'+EOL+'1');             // vertices follow
         for J:=1 to Source.Count do begin
            P:=Source[J-1];
            Index:=FPoints.SortedIndexOf(P);
            P3D:=MirrorPoint[Index];
            Strings.Add('0'+EOL+'VERTEX');
            Strings.Add('8'+EOL+Layer);
            Strings.Add('10'+EOL+FloatToDec(P3D.X,4));
            Strings.Add('20'+EOL+FloatToDec(P3D.Y,4));
         end;
            Strings.Add('0'+EOL+'SEQEND');
      end;  Source.Destroy;
   end;
   if ShowStations then for I:=1 to FStations.Count do ExportSpline(FStations[I-1],'stations');
   if ShowButtocks then for I:=1 to FButtocks.Count do ExportSpline(FButtocks[I-1],'buttocks');
   if ShowWaterlines then for I:=1 to FWaterlines.Count do ExportSpline(FWaterlines[I-1],'waterlines');
   if ShowDiagonals then for I:=1 to FDiagonals.Count do ExportSpline(FDiagonals[I-1],'diagonals');
   Dest.Destroy;
end;

procedure TDevelopedPatch.SaveToTextFile(Strings:TStringList);
var I,J,Index: integer;
    P    : SPoint;
    P3D  : Vector;
    Source,Dest:TFasterList;
    Min,Max:Vector;
    First:Boolean;
begin                   // Extract edges as polylines
   Source:=TFasterList.Create;
   Source.AddList(FBoundaryEdges);
   Dest:=TFasterList.Create;
   Owner.Owner.IsolateEdges(Source,Dest);
   Source.Destroy;      // Calculate min.,max extents of coundary
   First:=True;         // all measurements are referred to the min. coordinate
   Strings.Add('');
   Strings.Add('Boundary coordinates for: '+Name);
   for I:=1 to Dest.Count do begin
      Source:=Dest[I-1];
      for J:=1 to Source.Count do begin
         P:=Source[J-1];
         Index:=FPoints.SortedIndexOf(P);
         P3D:=Point[Index];
         if First then begin
            Min:=P3D;
            Max:=min;
            First:=false;
         end else MinMax(P3D,Min,Max);
         if FMirror then begin
            P3D:=MirrorPoint[Index];
            MinMax(P3D,Min,Max);
         end;
      end;
   end;
   for I:=1 to Dest.Count do begin Source:=Dest[I-1];
      if I>1 then Strings.Add('');
      for J:=1 to Source.Count do begin P:=Source[J-1];
         Index:=FPoints.SortedIndexOf(P);
         P3D:=Point[Index]-Min;
         Strings.Add(FloatToDec(P3D.X,3)+#32+FloatToDec(P3D.Y,3));
      end;
      if FMirror then begin
         Strings.Add('');
         for J:=1 to Source.Count do begin
            P:=Source[J-1];
            Index:=FPoints.SortedIndexOf(P);
            P3D:=MirrorPoint[Index]-Min;
            Strings.Add(FloatToDec(P3D.X,3)+#32+FloatToDec(P3D.Y,3));
         end;
      end;  Source.Destroy;
   end;     Dest.Destroy;
end;

procedure TDevelopedPatch.Unroll(ControlFaces:TFasterList);
type TPolygonOrientation = (poCCW,poCW);
var I,J,K,N,BestIndex,ErrorIndex: Integer;
    Error,Area,MaxError,SeedArea: Real;
    OptArea,Dist,OptAngle       : Real;
    Min,Max,Normal,P3D1,P3D2,P3D3: Vector;
    Ctrlface      : SControlFace;
    Child,Face,Seedface: Sface;
    Edge          : SEdge;
    P1,P2,P3      : SPoint;
    Processed     : array of boolean;
    FFaces,SeedFaces,TmpEdges,SortedEdges: TFasterList;
    Orientation,Winding       : TPolygonOrientation;
    First         : Boolean;

   // Crossproduct
   // Computes the crossproduct of three points
   // Returns whether their internal angle is clockwise or counter-clockwise.
   function Crossproduct(P1,P2,P3:Place):TPolygonOrientation;
   var Tmp:Real;
   begin
      Result:=poCCW;
      Tmp:=(P2.X-P1.X)*(P3.Y-P2.Y)-(P2.Y-P1.Y)*(P3.X-P2.X);
      if Tmp>=0.0 then Result:=poCCW else
         if Tmp<0 then Result:=poCW;
   end;

   // Calculates the third point of a triangle when the length of its
   // three sides and two coordinates are known
   Function CalculateTriangle(a,b,c:Real;P1,P2:Place):Place;
   var Fie1,Fie2,Fie3,P: Real;
   begin
      if abs(P2.X-P1.X)<=1e-6 then begin
         if P2.X=P1.X then begin
            if P2.Y>p1.Y then Fie1:=0.5*Pi
                         else Fie1:=-0.5*Pi;
         end else begin
            Fie1:=ArcTan((P2.Y-P1.Y)/(P2.X-P1.X));
         end;
      end else Fie1:=ArcTan((P2.Y-P1.Y)/(P2.X-P1.X));
      if (Fie1<0) and (P2.Y>P1.Y) then Fie1:=Fie1+Pi;
      if (Fie1>0) and (P2.Y<P1.Y) then Fie1:=Fie1+Pi;
      if b*c<>0 then P:=(b*b+c*c-a*a)/(2*b*c)
                else p:=1*Sign(b*b+c*c-a*a);
      if p>1 then p:=1 else if P<-1 then p:=-1;
      if P=0.0 then begin
         Fie2:=0.5*Pi;
      end else Fie2:=arcTan(Sqrt(1-p*p)/p);
      if p<0 then Fie2:=Pi-abs(Fie2);
      Fie3:=Fie1-Fie2;
      Result.X:=b*Cos(Fie3)+P1.X;
      Result.Y:=b*Sin(Fie3)+P1.Y;
   end;

   Function CalculateTriangle2(a,b,c:Real;P1,P2:Place):Place;
   var Fie1,Fie2,Beta,Tmp: Real;
   begin
      if abs(P2.X-P1.X)<=1e-6 then begin
         if P2.X=P1.X then begin
            if P2.Y>p1.Y then Fie1:=0.5*Pi
                         else Fie1:=-0.5*Pi;
         end else begin
            Fie1:=ArcTan((P2.Y-P1.Y)/(P2.X-P1.X));
         end;
      end else Fie1:=ArcTan((P2.Y-P1.Y)/(P2.X-P1.X));
      if (Fie1<0) and (P2.Y>P1.Y) then Fie1:=Fie1+Pi;
      if (Fie1>0) and (P2.Y<P1.Y) then Fie1:=Fie1+Pi;
      if 2*a*c=0 then begin
         if a=0.0 then a:=1e-7;
         if c=0.0 then c:=1e-7;
      end;
      begin
         Tmp:=(a*a+c*c-b*b)/(2*a*c);
         if tmp>1 then tmp:=1 else
         if tmp<-1 then tmp:=-1;
         Beta:=ArcCos(Tmp);
         Fie2:=Fie1+Beta;
         Result.X:=c*Cos(Fie2)+P1.X;
         Result.Y:=c*Sin(Fie2)+P1.Y;
      end;
   end;

   Procedure Unroll2D(Face:SFace;FirstFace:boolean; var Error:Boolean);
   var I,S,E,Index1,Index2,Index3: Integer;
       P1,P2,P3: SPoint;
       Indices: array of boolean;

       procedure ProcessTriangle(P1,P2,P3:SPoint;Ind1,Ind2,Ind3:Integer);
       var P1_2D,P2_2D,P3_2D: Place;
           a,b,c: Real;
       begin
          a:=Abs(P1.Coordinate-P2.Coordinate);
          b:=Abs(P2.Coordinate-P3.Coordinate);
          c:=Abs(P3.Coordinate-P1.Coordinate);
          if (not Processed[Ind1]) and
             (not Processed[Ind2]) and
             (not Processed[Ind3]) then
          begin
             // first face, calculate P1, P2 and P3
             P1_2D.X:=P1.Coordinate.X;
             P1_2D.Y:=P1.Coordinate.Y;
             P2_2D.X:=P1_2D.X;
             P2_2D.Y:=P1_2D.Y+a;
             Processed[Ind1]:=True;
             F2DCoordinates[Ind1]:=P1_2D;
             Processed[Ind2]:=True;
             F2DCoordinates[Ind2]:=P2_2D;
          end;
          P1_2D:=F2DCoordinates[Ind1];
          P2_2D:=F2DCoordinates[Ind2];
          P3_2D:=F2DCoordinates[Ind3];
          if (Processed[Ind1])
          and (Processed[Ind2])
          and (not Processed[Ind3]) then begin     // calculate position of P3
             a:=Abs( P1_2D-P2_2D );
             P3_2D:=CalculateTriangle2(a,b,c,P1_2D,P2_2D);
             if First then begin
               Orientation:=Crossproduct(P1_2D,P2_2D,P3_2D);
               First:=False;
             end else begin
                Winding:=Crossproduct(P1_2D,P2_2D,P3_2D);
                if Winding<>Orientation then
                if not Error then Error:=True;
             end;
             F2DCoordinates[Ind3]:=P3_2D;
             Processed[ind3]:=True;
          end;
       end;
   begin
      Error:=false;
      setlength(Indices,face.Nopoints);
      for I:=1 to Face.Nopoints do begin
         Index1:=FPoints.SortedIndexOf(Face.Point[I-1]);
         Indices[I-1]:=Processed[Index1];
      end;                                 // find two succ. calculated points
      S:=-1;
      E:=-1;
      for I:=1 to Face.Nopoints do begin
         if Indices[I-1] then begin
            Index1:=I mod face.Nopoints;
            if Indices[Index1] then begin
               S:=I-1;
               E:=Index1;
               break;
            end;
         end;
      end;
      if (S<>-1) and (E<>-1) then begin
         for I:=3 to Face.Nopoints do begin
            P1:=Face.Point[S];
            Index1:=FPoints.SortedIndexOf(P1);
            E:=(S+I-2) mod face.Nopoints;
            P2:=Face.Point[E];
            Index2:=FPoints.SortedIndexOf(P2);
            E:=(S+I-1) mod face.Nopoints;
            P3:=Face.Point[E];
            Index3:=FPoints.SortedIndexOf(P3);
            ProcessTriangle(P1,P2,P3,Index1,Index2,index3);
         end;
      end else begin
         for I:=3 to Face.Nopoints do begin
            P1:=Face.Point[0];
            Index1:=FPoints.SortedIndexOf(P1);
            P2:=Face.Point[I-2];
            Index2:=FPoints.SortedIndexOf(P2);
            P3:=Face.Point[I-1];
            Index3:=FPoints.SortedIndexOf(P3);
            ProcessTriangle(P1,P2,P3,Index1,Index2,index3);
         end;
      end;
   end;

   function TriangleArea(P1,P2,P3:Place):Real;
   begin
      Result:=0.5*((P1.x-P2.x)*(P1.y+P2.y)+(P2.x-P3.x)*(P2.y+P3.y)+(P3.x-P1.x)*(P3.y+P1.y));
   end;

   procedure ProcessFaces(Seedface:SFace;var MaxError:Real;var ErrorIndex:Integer);
   var I,J,k,S,E,P,Index: Integer;
       ToDoList   : TFasterlist;
       Face,Child : SFace;
       Edge       : SEdge;
       P1,P2      : SPoint;
       Error,TotalError,_3DArea,_2DArea: Real;
       Temp       : Boolean;
   begin
      MaxError:=0.0;
      TotalError:=0.0;
      FMaxAreaError:=0.0;
      FTotalAreaError:=0.0;
      ErrorIndex:=-1;
      Setlength(F2DCoordinates,FPoints.Count);
      Setlength(Processed,FPoints.Count);
      Setlength(FEdgeErrors,FEdges.Count);
      for I:=1 to FEdges.Count do FEdgeErrors[I-1]:=0.0;
      for i:=1 to FPoints.Count do begin
         Processed[I-1]:=False;
         F2DCoordinates[I-1].X:=0.0;
         F2DCoordinates[I-1].Y:=0.0;
      end;
      ToDoList:=TFasterList.Create; // Assemble all faces to be developed in a list
      ToDoList.AddList(FFaces);
      ToDoList.Sort;
      FDoneList.Clear;
      FDoneList.Capacity:=ToDoList.Count;
      First:=True;
      while ToDoList.Count>0 do begin
         if SeedFace=nil then // Find a new seedface, this layer has multiple areas
            SeedFace:=ToDoList[0];
         FDoneList.Add(SeedFace);
         Index:=ToDoList.SortedIndexOf(Seedface);
         if Index<>-1 then ToDoList.Delete(Index);
         I:=1;
         while I<=FDoneList.Count do begin
            Face:=FDoneList[I-1];
            Unroll2D(Face,I=1,Temp);
            if (temp) and (ErrorIndex=-1) then ErrorIndex:=I-1;
            P1:=Face.Point[Face.NoPoints-1];
            for J:=1 to Face.Nopoints do begin
               P2:=Face.Point[J-1];
               Edge:=Owner.Owner.EdgeExists(P1,P2);
               if Edge<>nil then begin
                  for K:=1 to Edge.NoFaces do begin
                     Child:=Edge.Face[K-1];
                     Index:=ToDoList.SortedIndexOf(Child);
                     if Index<>-1 then begin
                        FDoneList.Add(Child);
                        ToDoList.Delete(Index);
                     end;
                  end;
               end;     P1:=P2;
            end;        inc(I);
         end;           SeedFace:=nil;
      end;              ToDoList.Destroy;

      // Calculate diff. in area of all faces
      FMaxAreaerror:=0.0;
      FTotalAreaError:=0.0;
      for I:=1 to FDoneList.Count do begin
         Face:=FDoneList[I-1];
         _2DArea:=0.0;
         _3DArea:=Face.Area;                               // calculate 2D area
         S:=FPoints.SortedIndexOf(Face.Point[0]);
         for J:=3 to Face.Nopoints do begin
            E:=FPoints.SortedIndexOf(Face.Point[J-2]);
            P:=FPoints.SortedIndexOf(Face.Point[J-1]);
            _2DArea:=_2DArea+TriangleArea(F2DCoordinates[S],F2DCoordinates[E],F2DCoordinates[P]);
         end;
         Error:=_2DArea-_3DArea;
         FTotalAreaError:=FTotalAreaError+Error;
         Error:=abs(Error);
         if Error>FMaxAreaError then FMaxAreaError:=Error;
      end;

      // calculate min/max errors of edges
      for I:=1 to FEdges.Count do begin
         Edge:=FEdges[I-1];
         S:=FPoints.SortedIndexOf(Edge.StartPoint);
         E:=FPoints.SortedIndexOf(Edge.EndPoint);
         if (S<>-1) and (E<>-1) then begin          // original distance in 3D
            Error:=Abs( Edge.Endpoint.Coordinate-Edge.Startpoint.Coordinate )
                 - Abs( F2DCoordinates[E]-F2DCoordinates[S] );
            TotalError:=TotalError+abs(Error);
            if abs(Error)>MaxError then MaxError:=abs(Error);
            FEdgeErrors[I-1]:=Error;
         end;
      end;
      MaxError:=MaxError+abs(FTotalAreaError);
   end;

begin
   // first assemble all points, edges and faces used
   FFaces:=TFasterList.Create;
   for K:=1 to ControlFaces.Count do begin
      Ctrlface:=ControlFaces[K-1];
      FFaces.AddList(Ctrlface.FChildren);
      FFaces.Sort;
      for I:=1 to Ctrlface.ChildCount do begin
         Child:=Ctrlface.Child[I-1];
         P1:=Child.Point[Child.NoPoints-1];
         for J:=1 to Child.Nopoints do begin
            P2:=Child.Point[J-1];                            // Add this point
            if FPoints.SortedIndexOf(P2)=-1 then FPoints.AddSorted(P2);
            Edge:=Owner.Owner.EdgeExists(P1,P2);               // add this edge
            if Edge<>nil then if FEdges.SortedIndexOf(Edge)=-1 then FEdges.AddSorted(Edge);
            P1:=P2;
         end;
      end;
   end;

   FPoints.Capacity:=FPoints.Count;
   FEdges.Capacity:=FEdges.Count;

   // Find the seed face, which is characterized by the face that it
   // has one cornerpoint with (possibly) multiple faces, but only 1
   // face is present in the list of faces to be unrolled.
   SeedFaces:=TFasterList.Create;
   SeedFace:=nil;
   SeedArea:=0;
   for I:=1 to FPoints.Count do begin P1:=FPoints[I-1]; N:=0;
      for J:=1 to P1.FFaces.Count do begin
         if FFaces.SortedIndexOf(P1.FFaces[J-1])<>-1 then inc(N);
      end;
      if N=1 then begin
         for J:=1 to P1.FFaces.Count do begin
            if FFaces.SortedIndexOf(P1.FFaces[J-1])<>-1 then begin
               Area:=P1.Face[J-1].Area;
               if ( Area>SeedArea ) or ( SeedFace=nil ) then begin
                    SeedFace:=P1.FFaces[J-1];
                    SeedArea:=Area;
               end; Seedfaces.Add(P1.FFaces[J-1]);
            end;
         end;
      end;
   end;
   // if NO seedfaces could be found (which should not occur)
   //  then pick a random one (the one with the largest area)
   if Seedfaces.Count=0 then begin
      for I:=1 to FFaces.Count do begin
         Face:=FFaces[I-1];
         Area:=Face.Area;
         if (I=1) or (Area>SeedArea) then begin
            SeedFace:=face;
            SeedArea:=Area;
         end;
      end;
      if Seedface<>nil then Seedfaces.Add(SeedFace);
   end;

   // sort seedfaces
   for I:=1 to Seedfaces.Count-1 do begin
      SeedFace:=Seedfaces[I-1];
      SeedArea:=Seedface.Area;
      for J:=2 to SeedFaces.Count do begin
         Child:=Seedfaces[J-1];
         Area:=Child.Area;
         if Area<seedArea then begin
            Seedfaces.Exchange(I-1,J-1);
            SeedArea:=Area;
         end;
      end;
   end;
   if SeedFaces.Count>0 then begin
      MaxError:=1e10;
      BestIndex:=-1;
      I:=1;
      FNoIterations:=0;
      // Keep trying to develop the faces until no error has occured and the max. error<1e-7 and the number of iterations<=25
      while I<=seedfaces.count do begin
         Seedface:=Seedfaces[I-1];
         ProcessFaces(Seedface,Error,ErrorIndex);
         inc(FNoIterations);
         if (ErrorIndex<>-1) and (Seedfaces.Count<25) then begin
            // Add faces where an error occured as new seedfaces, these
            // are generally areas where gauss curvature<>0.0
            if Seedfaces.IndexOf(FDonelist[ErrorIndex])=-1 then Seedfaces.Add(FDonelist[ErrorIndex]);
         end;
         if Error<MaxError then begin
            MaxError:=Error;
            BestIndex:=I-1;
         end;
         inc(I);
      end;

      // Restore the best development
      if (BestIndex<>-1) and (BestIndex<>Seedfaces.Count-1) then begin
         Seedface:=Seedfaces[BestIndex];
         ProcessFaces(Seedface,Error,ErrorIndex);
      end;

      // Assemble all boundaryedges
      FBoundaryEdges.Clear;
      for I:=1 to FEdges.Count do begin
         Edge:=FEdges[I-1]; // Only edges with 1 attached face in the ffaces list are valid
         N:=0;
         for J:=1 to Edge.NoFaces do if FFaces.SortedIndexOf(Edge.Face[J-1])<>-1 then inc(N);
         if N=1 then FBoundaryEdges.Add(Edge);
      end;
      FBoundaryEdges.Capacity:=FBoundaryEdges.Count;

      // calculate min/max coordinates in 2D
      for I:=1 to FPoints.Count do begin
         if I=1 then begin
            FMin2D:=F2DCoordinates[I-1];
            FMax2D:=FMin2D;
         end else begin
            if F2DCoordinates[I-1].X<FMin2D.X then FMin2D.X:=F2DCoordinates[I-1].X;
            if F2DCoordinates[I-1].Y<FMin2D.Y then FMin2D.Y:=F2DCoordinates[I-1].Y;
            if F2DCoordinates[I-1].X>FMax2D.X then FMax2D.X:=F2DCoordinates[I-1].X;
            if F2DCoordinates[I-1].Y>FMax2D.Y then FMax2D.Y:=F2DCoordinates[I-1].Y;
         end;
      end;

      // finally find optimal rotation angle such that the
      // area of the bounding box is minimal
      OptArea:=0;
      OptAngle:=0;
      for I:=0 to 180 do begin
         Rotation:=I/2;
         Extents(Min,Max);
         Area:=(Max.X-Min.X)*(Max.Y-Min.Y);
         if I=0 then begin
            OptArea:=Area;
            OptAngle:=Rotation;
         end;
         if Area<OptArea then begin
            OptArea:=Area;
            OptAngle:=Rotation;
         end;
      end;
      Rotation:=OptAngle;
      Extents(Min,Max);
      if Max.X-Min.X<Max.Y-Min.Y then Rotation:=Rotation-90;
      if Owner.Symmetric then begin
         // Now check if the surface has one of its sides on the centerplane
         FMirror:=False;
         TmpEdges:=TFasterList.Create;
         for J:=1 to FEdges.Count do begin
            Edge:=FEdges[J-1];
            if (Edge.NoFaces=1)
            and (abs(Edge.StartPoint.Coordinate.Y)<=1e-4)
            and (abs(Edge.EndPoint.Coordinate.Y)<=1e-4) then begin
               FMirror:=True;
               TmpEdges.Add(Edge);
            end;
         end;
         if TmpEdges.Count>0 then begin
            if FMirror then begin
               // Now if all facenormals have a Y-coordinate of approx. 0.0 then
               // this is probably a bottom panel, a deck or a transom
               for J:=1 to FDoneList.Count do begin
                  Face:=FDonelist[J-1];
                  Normal:=Face.FaceNormal;
                  if abs(Normal.Y)>1e-2 then begin
                     FMirror:=False; // Y-coordinate of Normal is too big, do not attach
                     Break;
                  end;
               end;

               if FMirror then begin
                  // Check if all points on the centerline are developed onto a 2Dline
                  // if so, then this line is used to mirror the other half of the layer
                  // so it forms 1 whole panel and there is no need to unfold it.
                  SortedEdges:=TFasterList.Create;
                  self.FOwner.Owner.IsolateEdges(TmpEdges,SortedEdges);
                  TmpEdges.Destroy;
                  TmpEdges:=nil;
                  for J:=SortedEdges.Count downto 1 do begin
                     TmpEdges:=SortedEdges[J-1];
                     if J>1 then TmpEdges.Destroy;
                  end;
                  if TmpEdges<>nil then if TmpEdges.Count>0 then begin
                     P1:=TmpEdges[0];
                     P2:=TmpEdges[TmpEdges.Count-1];
                     if P1=P2 then begin // closed loop, pick another point
                        J:=TmpEdges.Count;
                        while (J>1) and (P1=P2) do begin
                           P2:=TmpEdges[J-1];
                           Dec(J);
                        end;
                     end;
                     if P1<>P2 then begin
                        BestIndex:=FPoints.SortedIndexOf(P1);
                        P3D1.X:=F2DCoordinates[BestIndex].X;
                        P3D1.Y:=F2DCoordinates[BestIndex].Y;
                        P3D1.Z:=0.0;
                        BestIndex:=FPoints.SortedIndexOf(P2);
                        P3D2.X:=F2DCoordinates[BestIndex].X;
                        P3D2.Y:=F2DCoordinates[BestIndex].Y;
                        P3D2.Z:=0.0;
                        for J:=2 to TmpEdges.Count-1 do begin
                           P3:=TmpEdges[J-1];
                           BestIndex:=FPoints.SortedIndexOf(P3);
                           P3D3.X:=F2DCoordinates[BestIndex].X;
                           P3D3.Y:=F2DCoordinates[BestIndex].Y;
                           P3D3.Z:=0.0;
                           Dist:=DistancepointToLine(P3D1,P3D2,P3D3);
                           if Dist>1e-3 then begin
                              FMirror:=False;
                              break;
                           end;
                        end;
                        if FMirror then begin
                           J:=FPoints.SortedIndexOf(P1);
                           P3D1.X:=F2DCoordinates[J].X;
                           P3D1.Y:=F2DCoordinates[J].Y;
                           P3D1.Z:=0.0;
                           J:=FPoints.SortedIndexOf(P2);
                           P3D2.X:=F2DCoordinates[J].X;
                           P3D2.Y:=F2DCoordinates[J].Y;
                           P3D2.Z:=0.0;
                           P3D3:=P3D2;
                           P3D3.Z:=1.0;
                           FMirror:=True;
                           FMirrorPlane:=PlanePPP(P3D1,P3D2,P3D3);
                           // calculate min/max coordinates in 2D of the mirror part
                           for J:=1 to FPoints.Count do begin
                              P3D2:=iVect(F2DCoordinates[J-1].X,F2DCoordinates[J-1].Y,0.0);
                              P3D1:=MirrorPlane(P3D2,FMirrorplane);
                              if P3D1.X<FMin2D.X then FMin2D.X:=P3D1.X else if P3D1.X>FMax2D.X then FMax2D.X:=P3D1.X;
                              if P3D1.Y<FMin2D.Y then FMin2D.Y:=P3D1.Y else if P3D1.Y>FMax2D.Y then FMax2D.Y:=P3D1.Y;
                           end;
                        end;
                     end;
                  end; SortedEdges.Destroy;
               end;
            end;
         end;          TmpEdges.Destroy;
      end;                            // Assemble cornerpoints for dimensioning
      for I:=1 to FPoints.Count do begin
         P1:=FPoints[I-1];
         N:=0;
         For J:=1 to P1.NoFaces do
           if FFaces.SortedIndexOf(P1.Face[J-1])<>-1 then inc(N);
         if (N=1) or (P1.VertexType=svCorner) then  FCorners.Add(P1);
      end;
   end else ShowMessage('Seed could not be found!');
   Seedfaces.Destroy;
   FFaces.Destroy;
end;

{
    TEntity
    This is the base class of all 3D entities in the project
}
function TEntity.FGetMin:Vector;
begin
   if not Build then Rebuild;
   Result:=FMin;
end;

function TEntity.FGetMax:Vector;
begin
   if not Build then Rebuild;
   Result:=FMax;
end;

procedure TEntity.FSetBuild(Val:Boolean);
begin
   if Val<>FBuild then begin FBuild:=Val;
      if not Val then begin FMin:=ZERO; FMAx:=ZERO; end;
   end;
end;

constructor TEntity.Create;               // Create and initialise all data
      begin inherited Create; Clear; Build:=False; end;
destructor TEntity.Destroy;
     begin Inherited Destroy; end;

procedure TEntity.Clear;
begin
   Build:=False;
   FMin:=ZERO;
   FMAx:=ZERO;
   FColor:=clBlack;
   FPenwidth:=1;
   FPenStyle:=psSolid;
end;


procedure TEntity.Extents(Var Min,Max : Vector);
begin
   if not Build then Rebuild;
   MinMax(FMin,Min,Max);
   MinMax(FMax,Min,Max);
end;

procedure TEntity.Draw; begin end;
procedure TEntity.Rebuild; begin end;

{ TSpline 3D CSpline
  Copied from page 107 of the book: "Numerical recipes in fortan 77"
    Url: http://www.library.cornell.edu/nr/bookfpdf/f3-3.pdf
    Modified to use chordlength parametrisation for smoother
    interpolation and to accept knuckles in the controlpoints
}
procedure TSpline.FSetBuild(val:boolean);
begin
   if not val then begin
      Setlength(FDerivatives,0);
      Setlength(FParameters,0);                               // Clear extents
      FMin:=Zero;
      FMax.X:=1;
      FMax.Y:=1;
      Fmax.Z:=1;
      FTotalLength:=0.0;
   end;
   Inherited FSetBuild(Val);
end;

procedure TSpline.FSetCapacity(Val:integer);
begin
   if Val<>FCapacity then begin
      FCapacity:=Val;
      Setlength(FPoints,FCapacity);
      if nS>FCapacity then begin
      // Make sure that number of points does not exceed the capacity of the curve
         nS:=FCapacity;
         Build:=false;
      end;
      Setlength(FKnuckles,FCapacity);
   end;
end;

procedure TSpline.FSetFragments(Val:Integer);
begin
   if Val<>FFragments then begin
      FFragments:=val;
      Build:=False;
   end;
end;
function TSpline.FGetFragments:Integer;
begin Result:=FFragments; end;

function TSpline.FGetKnuckle(Index:integer):Boolean;
   begin Result:=FKnuckles[Index]; end;
procedure TSpline.FSetKnuckle(Index:integer;Value:Boolean);
    begin FKnuckles[Index]:=Value; Build:=false; end;
procedure TSpline.FSetPoint(Index:Integer;P:Vector);
    begin FPoints[index]:=P; Build:=False; end;
function TSpline.FGetParameter(Index:integer):Real;
   begin if not build then rebuild; Result:=FParameters[Index]; end;

function TSpline.FGetPoint(Index:Integer):Vector;
   begin Result:=FPoints[index]; end;

procedure TSpline.Rebuild;
var I,K: integer;
    Length,Sig,P: Real;
    U: VectorArray;
    Un,Qn: Vector;
begin
   Build:=False;                   // First attempt to eliminate double points
   I:=2;
   FTotalLength:=0;
   while I<=nS do begin
      Length:=Sqrt(Abs(FPoints[I-2]-FPoints[I-1]));
      FTotalLength:=FTotalLength+Length;
      Inc(I);
   end;
   if nS>1 then begin
      Setlength(FDerivatives,nS);
      Setlength(FParameters,nS);
      SetLength(U,nS);
      Length:=0;
      if abs(FTotalLength)<1e-5 then begin // zero arclength, use uniform parameterisation
         for I:=1 to nS do FParameters[I-1]:=(I-1)/(nS-1);
      end else begin
         FParameters[0]:=0.0;
         for I:=2 to nS-1 do begin
            Length+=Sqrt(Abs(FPoints[I-2]-FPoints[I-1]));
            FParameters[I-1]:=Length/FTotalLength;
         end;
         FParameters[nS-1]:=1.0;
      end;
      FDerivatives[0]:=Zero;
      U[0]:=FDerivatives[0];
      for I:=2 to nS-1 do begin
         if Knuckle[I-1] then begin U[I-1]:=Zero; FDerivatives[I-1]:=Zero;
         end else begin
            if (abs(FParameters[I]-FParameters[I-2])<1e-5)
            or (abs(FParameters[I-1]-FParameters[I-2])<1e-5)
            or (abs(FParameters[I]-FParameters[I-1])<1e-5) then FDerivatives[I-1]:=ZERO
            else begin
               Sig:=(FParameters[I-1]-FParameters[I-2])/(FParameters[I]-FParameters[I-2]);
               // first x-value
               P:=Sig*FDerivatives[I-2].X+2.0;
               FDerivatives[I-1].X:=(Sig-1.0)/P;
               U[I-1].X:=(6.0*((FPoints[I].X-FPoints[I-1].X)/(FParameters[I]-FParameters[I-1])-(FPoints[I-1].X-FPoints[I-2].X)/
                         (FParameters[I-1]-FParameters[I-2]))/(FParameters[I]-FParameters[I-2])-sig*U[I-2].X)/p;
               // then y-value
               P:=Sig*FDerivatives[I-2].Y+2.0;
               FDerivatives[I-1].Y:=(Sig-1.0)/P;
               U[I-1].Y:=(6.0*((FPoints[I].Y-FPoints[I-1].Y)/(FParameters[I]-FParameters[I-1])-(FPoints[I-1].Y-FPoints[I-2].Y)/
                         (FParameters[I-1]-FParameters[I-2]))/(FParameters[I]-FParameters[I-2])-sig*U[I-2].Y)/p;
               // then Z-value
               P:=Sig*FDerivatives[I-2].Z+2.0;
               FDerivatives[I-1].Z:=(Sig-1.0)/P;
               U[I-1].Z:=(6.0*((FPoints[I].Z-FPoints[I-1].Z)/(FParameters[I]-FParameters[I-1])-(FPoints[I-1].Z-FPoints[I-2].Z)/
                         (FParameters[I-1]-FParameters[I-2]))/(FParameters[I]-FParameters[I-2])-sig*U[I-2].Z)/p;
            end;
         end;
      end;
      Qn:=Zero; Un:=Qn;
      FDerivatives[nS-1].X:=(Un.X-Qn.X*U[nS-2].X)/(Qn.X*FDerivatives[nS-2].X+1.0);
      FDerivatives[nS-1].Y:=(Un.Y-Qn.Y*U[nS-2].Y)/(Qn.Y*FDerivatives[nS-2].Y+1.0);
      FDerivatives[nS-1].Z:=(Un.Z-Qn.Z*U[nS-2].Z)/(Qn.Z*FDerivatives[nS-2].Z+1.0);
      for K:=nS-1 downto 1 do begin                 // Back substitution
         FDerivatives[K-1].X:=FDerivatives[K-1].X*FDerivatives[K].X+U[K-1].X;
         FDerivatives[K-1].Y:=FDerivatives[K-1].Y*FDerivatives[K].Y+U[K-1].Y;
         FDerivatives[K-1].Z:=FDerivatives[K-1].Z*FDerivatives[K].Z+U[K-1].Z;
      end;
   end;
   FBuild:=true;
   if nS>0 then begin                        // Determine min/max values
      for I:=1 to nS do begin
         if I=1 then begin
            FMin:=FPoints[I-1];
            FMax:=FMin;
         end else MinMax(FPoints[I-1],FMin,FMax);
      end;
   end;
   inherited Rebuild;
end;

function TSpline.SecondDerive(Parameter:Real):Vector;
var Lo,Hi,K: integer;
    Frac: Real;
begin
   Result:=Zero; Lo:=0;
   if nS<2 then exit;
   if not FBuild then Rebuild;
   if nS<2 then exit;
   if nS=2 then Hi:=1
   else begin Hi:=nS-1;
      repeat
         K:=(Lo+Hi) div 2;
         if FParameters[K]<Parameter then Lo:=K else Hi:=K;
      until Hi-Lo<=1;
   end;
   if FParameters[Hi]-FParameters[Lo]<=0.0
      then Frac:=0.5
      else Frac:=(Parameter-FParameters[Lo])/(FParameters[Hi]-FParameters[Lo]);
   Result:=FDerivatives[Lo]+Frac*(FDerivatives[Hi]-FDerivatives[Lo]);
end;

// Remove points that do not contribute significantly to the shape
function TSpline.Simplify(Criterium:Real):Boolean;
var Weights: array of Real;
    TotalLength: Real;
    I,Index {,N1,N2}:Integer;
   Function Weight(Index:Integer):Real;
   var P1,P2,P3: Vector;
       Length,Dist: Real;
   begin
      if (Index=0) or (Index=nS-1)
      or (Knuckle[Index]) then Result:=1e10 else begin
         P1:=Point[Index-1];
         P2:=Point[Index];
         P3:=Point[Index+1];
         Length:=Abs( P3-P1 );
         if Length<1e-5 then Result:=0.0 else begin
            Dist:=DistancepointToLine(P2,P1,P3);
            if Dist<1e-2 then begin
               if Length*Length/TotalLength>0.01 then Result:=1e10
                                                 else Result:=1e8*Dist*Dist*Length;
            end else Result:=1e8*Dist*Dist*Length;
         end;
      end;
   end;
   Function FindNextPoint:integer;
   var MinVal:Real; I:Integer;
   begin
      Result:=-1; if nS<3 then exit;
      Result:=1;  MinVal:=Weights[1]; I:=2;
      While (I<nS) and (MinVal>0) do begin
         if Weights[I-1]<MinVal then begin
            MinVal:=Weights[I-1];
            Result:=I-1;
         end;
         Inc(I);
      end;
   end;
begin
   Result:=False;
   if nS<3 then begin Result:=True; exit; end;
// N1:=0;
// N2:=0;
// for I:=1 to Ns do if Knuckle[I-1] then inc(N1);
   TotalLength:=FTotalLength*FTotalLength;
   if TotalLength=0 then exit;
   SetLength( Weights,nS );
   for I:=1 to nS do Weights[I-1]:=Weight(I-1)/TotalLength;
   repeat
      Index:=FindNextPoint;
      if Index<>-1 then begin
         if (Index=0) or (Index=nS-1)
         or (nS<3) then Index:=-1 else begin
            if Weights[Index]<Criterium then begin
               Move(Weights[Index+1],Weights[Index],(nS-Index-1)*SizeOf(Real));
               Move(FPoints[Index+1],FPoints[Index],(nS-Index-1)*SizeOf(Vector));
               Move(FKnuckles[Index+1],FKnuckles[Index],(nS-Index-1));
               Dec(nS);
               if (Index-1>=0) and (Index-1<nS) then Weights[Index-1]:=Weight(Index-1)/TotalLength;
               if (Index>=0)   and (Index < nS) then Weights[Index]  :=Weight(Index)/TotalLength;
               if (Index+1>=0) and (Index+1<nS) then Weights[Index+1]:=Weight(Index+1)/TotalLength;
            end else Index:=-1;
         end;
      end;
   until index=-1;
   Result:=True;
{  for I:=1 to Ns do if Knuckle[I-1] then inc(N2);
   if N1<>N2 then } Build:=false;
   Capacity:=nS;
end;

procedure TSpline.Add(P:Vector);
begin                      // Make sure that the allocated memory is sufficient
   if nS=Capacity then Capacity:=Capacity+IncrementSize;
   FPoints[nS]:=P;
   FKnuckles[nS]:=False;
   inc(nS);
   Build:=False;  // Curve needs to be rebuild
end;

// Copy all data from another spline
procedure TSpline.Assign(Spline:TSpline);
begin
   FMin:=Spline.FMin;
   FMax:=Spline.FMax;
   FPenWidth:=Spline.FPenwidth;
   FColor:=Spline.FColor;
   FPenstyle:=Spline.FPenStyle;
   Capacity:=Spline.nS;
   Move(Spline.FPoints[0],FPoints[0],Spline.nS*SizeOf(Vector)); // Copy controlpoints
   Move(Spline.FKnuckles[0],FKnuckles[0],Spline.nS*SizeOf(Boolean)); // copy knuckles
   nS:=Spline.nS;
   FShowCurvature:=Spline.ShowCurvature;
   Build:=False;
end;

function TSpline.CoordLength(T1,T2:Real):Real;
var I: Integer; T: Real; P1,P2: Vector;
begin
   Result:=0.0;
   if not build then Rebuild;
   if not Build then exit;
   For I:=0 to Fragments do begin
      T:=T1+(I/Fragments)*(T2-T1);
      P2:=Value(T);
      if I>0 then Result:=Result+Abs( P2-P1 );
      P1:=P2;
   end;
end;

function TSpline.ChordlengthApproximation(Percentage:Real):Real;
var Totallength,Desiredlength,Parameter,Length,T1,T2,L1,L2: Real;
    Counter: integer;
begin
   T1:=0;
   T2:=1;
   Parameter:=1.0;
   Counter:=0;
   L1:=0;
   L2:=0;
   DesiredLength:=0;
   if Percentage<0.0 then Result:=0.0 else
   if Percentage>1.0 then Result:=1.0 else begin
      repeat
         Length:=CoordLength(0,Parameter);
         if counter=0 then begin
            L1:=0;
            L2:=Length;
            TotalLength:=Length;
            DesiredLength:=Percentage*Totallength;
            Parameter:=Percentage;
         end else begin
            if Length>Desiredlength then begin
               T2:=Parameter;
               L2:=Length;
            end else begin
               T1:=Parameter;
               L1:=Length;
            end;
            Parameter:=T1+((DesiredLength-L1)/(L2-L1))*(T2-T1);
            if Parameter<0 then Parameter:=0;
            if Parameter>1 then Parameter:=1;
         end;
         Inc(Counter);
      until(Counter>75) or (abs(Length-DesiredLength)<1e-3);
      Result:=Parameter;
   end;
end;

constructor TSpline.Create;
begin
   Setlength(FPoints,0);
   Setlength(FDerivatives,0);
   Setlength(FParameters,0);
   Setlength(FKnuckles,0);
   FCapacity:=0;
   nS:=0;
   inherited Create;
end;

function TSpline.Curvature(Parameter:Real;var Value,Normal:Vector):Real;
var Vel1,Acc: Vector;
    L,Denom,VdotA,VdotV: Real;
begin
   Value:=self.Value(Parameter);
   Vel1:=FirstDerive(Parameter);
   Acc:=SecondDerive(Parameter);
   L := Abs( Acc*Vel1);              // Crossproduct of first and second derive
   if L=0 then L:=0.00001;
   VdotA:=(Vel1.X*Acc.X)+(Vel1.Y*Acc.Y)+(Vel1.Z*Acc.Z);
   VdotV:=(Vel1.X*Vel1.X)+(Vel1.Y*Vel1.Y)+(Vel1.Z*Vel1.Z);
   Denom:=Power( VdotV,1.5 );
   if Denom>0 then Result:=L/Denom else Result:=0;
   Normal:=Normalize( vdotv*acc-vdota*vel1 );
end;

procedure TSpline.DeletePoint( Index:Integer ); var I: integer;
begin
   if Index<nS then if nS>0 then begin dec(nS);
      for I:=Index to nS-1 do begin
         FPoints[I]:=FPoints[I+1];
         FKnuckles[I]:=FKnuckles[I+1];
      end; Build:=false;
   end;
end;

function TSpline.DistanceToCursor(X,Y:Integer;Viewport:TViewport):integer;
var I,Tmp   : Integer;
    Pt,P1,P2: TPoint;
    V1,V2,P : Vector;
    Param   : Real;
begin
   Result:=1000000;      // Check if cursor position lies within the boundaries
   Pt.X:=X;
   Pt.Y:=Y;
   if (Pt.X>=0) and (Pt.X<=Viewport.Width)
   and (Pt.Y>=0) and (Pt.Y<=Viewport.Height) then begin
      P1:=Viewport.Project(value(0.0));
      P:=Value(0);
      V1:=P;
      for I:=1 to Fragments do begin
         V2:=Value((I-1)/(Fragments-1));
         P2:=Viewport.Project(V2);
         Tmp:=Round(DistanceToLine(P1,P2,X,Y,Param));
         if Tmp<Result then begin
            result:=Tmp;
            P:=Interpolate(V1,V2,Param);
         end;
         P1:=P2;
         V1:=V2;
      end;
   end;
end;

function TSpline.FirstDerive(Parameter:Real):Vector;
var T1,T2:Real;
begin
   T1:=Parameter-1e-3; if T1<0.0 then T1:=0.0;
   T2:=Parameter+1e-3; if T2>1.0 then T2:=1.0;
   Result:=(Value(T2)-Value(T1))/(T2-T1);
end;

procedure TSpline.Insert(Index:Integer;P:Vector);
var I : integer;
begin
// if (Index>=0) and (Index<Ns) then begin
   if nS=Capacity then Capacity:=Capacity+IncrementSize;
   for I:=nS-1 downto Index do begin
      FPoints[I+1]:=FPoints[I];
      FKnuckles[I+1]:=FKnuckles[I];
   end;
   FPoints[Index]:=P;
   FKnuckles[Index]:=False;
   inc(nS);
   Build:=false;
// end else raise Exception.Create('Index out of range'+EOL+IntToStr(Index)+#32+IntToStr(nS));
end;

procedure TSpline.Draw(Viewport:TViewport);
var I,R,G,B: Integer;
    P1,P2,Normal: Vector;
    PArray1,PArray2 : array of TPoint;
    Pt: TPoint;
    C: Real;
begin
   if not Build then Rebuild;
   if Viewport.ViewportMode=vmWireFrame then begin
      if ShowCurvature then begin
         SetLength(PArray1,Fragments);
         SetLength(PArray2,Fragments);
         for I:=1 to Fragments do begin
            C:=Curvature((I-1)/(Fragments-1),P1,Normal);
            PArray1[I-1]:=Viewport.Project(P1);
            PArray2[I-1]:=Viewport.Project(P1-(C*2*Sp.CurvatureScale)*Normal);
         end;
         Viewport.SetPenWidth(1);
         Viewport.PenColor:=Sp.CurvaturePlot;
         for I:=1 to Fragments do
         if (I mod 4=0) or (I=1) or (I=Fragments) then begin
            Viewport.Canvas.MoveTo(PArray1[I-1].X,PArray1[I-1].Y);
            Viewport.Canvas.LineTo(PArray2[I-1].X,PArray2[I-1].Y);
         end;
         Viewport.Canvas.Polyline(PArray2);
      end else begin
         SetLength(PArray1,Fragments);
         for I:=1 to Fragments do begin
            P1:=Value((I-1)/(Fragments-1));
            PArray1[I-1]:=Viewport.Project(P1);
         end;
      end;
      Viewport.SetPenWidth(1);
      Viewport.PenColor:=Color;
      Viewport.Canvas.Pen.Style:=FPenstyle;
      Viewport.Canvas.Polyline(PArray1);
      if ShowPoints then begin
         Viewport.Fontname:=UFont; //'Consolas'; //'small fonts';
         Viewport.FontSize:=ViewPort.FontSize; // =7 St.Preferences.FontSize;
         Viewport.FontColor:=clBlack;
         Viewport.BrushStyle:=bsClear;
         for I:=1 to nS do begin
            Pt:=Viewport.Project(Point[I-1]);
            Viewport.Canvas.Ellipse(Pt.X-2,Pt.Y-2,Pt.X+2,Pt.Y+2);
            Viewport.Canvas.TextOut(Pt.X+2,Pt.Y,IntToStr(I));
         end;
      end;
   end else begin // draw to z-buffer
      if not Build then Rebuild;
      R:=GetRValue(Color);
      G:=GetGValue(Color);
      B:=GetBValue(Color);
      P1:=Value(0.0);
      for I:=1 to Fragments do begin
         P2:=Value(I/Fragments); Viewport.DrawLineToZBuffer(P1,P2,R,G,B);
         P1:=P2;
      end;
   end;
end;

procedure TSpline.InsertSpline
    ( Index: Integer;
      Invert,DuplicatePoint: Boolean;
      Source: TSpline );
var I,J,NoNewPoints: Integer;
begin
   if nS=0 then begin
      Capacity:=Source.nS;
      if Invert then begin
         for I:=0 to Source.nS-1 do begin
            FPoints[Source.nS-1-I]:=Source.FPoints[I];
            FKnuckles[Source.nS-1-I]:=Source.FKnuckles[I];
         end;
      end else begin
         for I:=0 to Source.nS-1 do begin
            FPoints[I]:=Source.FPoints[I];
            FKnuckles[I]:=Source.FKnuckles[I];
         end;
      end;
      nS:=Source.nS;
   end else begin
      if DuplicatePoint then NoNewPoints:=Source.nS-1
                        else NoNewPoints:=Source.nS;
      Capacity:=nS+NoNewPoints;
      Build:=False;
      if Index<nS then begin                     // insert space for new points
         Move(  FPoints[Index],  FPoints[Index+NoNewPoints],(nS-Index)*SizeOf(Vector));
         Move(FKnuckles[Index],FKnuckles[Index+NoNewPoints],(nS-Index));
         if Invert then begin                            // Insert the new data
            Knuckle[index]:=Knuckle[Index] or Source.Knuckle[Source.nS-1];
            for I:=1 to NoNewPoints do begin
               FPoints[Index+I-1]:=Source.FPoints[Source.nS-I];
               FKnuckles[Index+I-1]:=Source.FKnuckles[Source.nS-I];
            end;
         end else begin
            Knuckle[index]:=Knuckle[Index] or Source.Knuckle[0];
            Move(Source.FPoints[0],FPoints[Index],NoNewPoints*SizeOf(Vector));
            Move(Source.FKnuckles[0],FKnuckles[Index],NoNewPoints);
         end;
      end else begin
         if DuplicatePoint then J:=1 else J:=0;
         if Invert then begin
            Knuckle[nS-1]:=Knuckle[nS-1] or Source.Knuckle[Source.nS-1];
            for I:=0 to NoNewPoints-1 do begin
               FPoints[nS+I]:=Source.FPoints[Source.nS-I-1+J];
               FKnuckles[nS+I]:=Source.FKnuckles[Source.nS-I-1+J];
            end;
         end else begin
            Knuckle[nS-1]:=Knuckle[nS-1] or Source.Knuckle[0];
            Move(Source.FPoints[J],FPoints[nS],NoNewPoints*SizeOf(Vector));
            Move(Source.FKnuckles[J],FKnuckles[nS],NoNewPoints); // Add knuckles
         end;
      end;
      inc(nS,NoNewPoints);
      if not DuplicatePoint then Fknuckles[index]:=True;
   end;
end;

function TSpline.IntersectPlane(Plane:Plate;var Output:TIntersectionData):Boolean;
var Capacity,I: Integer; P1,P2: Vector; S1,S2,T1,T2,T: Real;
    procedure AddToOutput(P:Vector;Parameter:Real);
    begin
       if Output.NoIntersections=Capacity then begin
          inc(Capacity,10);
          Setlength(Output.Points,Capacity);
          Setlength(Output.Parameters,Capacity);
       end;
       Output.Points[Output.NoIntersections]:=P;
       Output.Parameters[Output.NoIntersections]:=Parameter;
       inc(Output.NoIntersections);
    end;
begin
   Capacity:=0;
   Output.NoIntersections:=0;
   Setlength(Output.Points,Capacity);
   Setlength(Output.Parameters,Capacity);
   T1:=0.0;
   P1:=value(T1);
   S1:=Plane.a*P1.x+Plane.b*P1.y+Plane.c*P1.z+Plane.d;
   if abs(S1)<1e-6 then AddToOutput(P1,T1);
   for I:=1 to Fragments do begin
      T2:=I/Fragments;
      P2:=Value(T2);
      S2:=Plane.a*P2.x+Plane.b*P2.y+Plane.c*P2.z+Plane.d;
      if abs(S2)<1e-6 then AddToOutput(P2,T2);
      if ((S1<0.0) and (S2>0.0)) or ((S2<0.0) and (S1>0.0)) then begin
         T:=-s1/(s2-s1);                         // intersection found
         T:=T1+T*(T2-T1);
         AddToOutput(Value(T),T);
      end;
      P1:=P2;
      S1:=S2;
      T1:=T2;
   end;
   Result:=Output.NoIntersections>0;
end;

// Invert the direction of controlpoints and knuckles
procedure TSpline.InvertDirection;
var I,Mid: Integer; P: Vector; K: Boolean;
begin Mid:=(nS div 2) - 1;
   for I:=0 to Mid do begin
      P:=FPoints[I];   FPoints[I]:=FPoints[nS-I-1];     FPoints[nS-I-1]:=P;
      K:=FKnuckles[I]; FKnuckles[I]:=FKnuckles[nS-I-1]; FKnuckles[nS-I-1]:=K;
   end; Build:=False;
end;

procedure TSpline.LoadBinary(Source:TFileBuffer);
var I,N: Integer; P: Vector; K: Boolean;
begin
   Source.LoadBoolean(FShowCurvature);
   Source.LoadTFloatType(Sp.CurvatureScale);
   Source.LoadInteger(N); Capacity:=N;
   for I:=1 to N do begin Source.LoadVector(P); Add(P);
                          Source.LoadBoolean(K); Knuckle[I-1]:=K; end;
end;

procedure TSpline.SaveBinary(Destination:TFileBuffer);
var I:Integer;
begin
   Destination.Add(FShowCurvature);
   Destination.Add(Sp.CurvatureScale);
   Destination.Add(nS);
   for I:=1 to nS do begin
      Destination.Add(Point[I-1]);
      Destination.Add(Knuckle[I-1]);
   end;
end;

procedure TSpline.SaveToDXF
( Strings:TStringList; Layername:string; SendMirror:Boolean );
var P: Vector; I,J,Ind,NParams: Integer; Params: RealArray;
begin
  Ind:=FindDXFColorIndex(Color);
  NParams:=0;
  Setlength(Params,nS); // count number of knucklepoints
  if not Build then Rebuild;
  for I:=2 to nS-1 do begin
     if Knuckle[I-1] then begin
        Params[NParams]:=Parameter[I-1];
        inc(NParams);
     end;
  end;
  Setlength(Params,NParams+Fragments);
  for I:=1 to Fragments do begin
     Params[NParams]:=(I-1)/(Fragments-1);
     inc(NParams);
  end;
  ArraySort( Params,NParams );
  Strings.Add('0'+EOL+'POLYLINE');
  Strings.Add('8'+EOL+LayerName);      // layername
  Strings.Add('62'+EOL+IntToStr(Ind)); // color by layer
  Strings.Add('70'+EOL+'10');          // not closed
  Strings.Add('66'+EOL+'1');           // vertices follow
  for J:=1 to NParams do begin
     P:=Value(Params[J-1]);
     Strings.Add('0'+EOL+'VERTEX');
     Strings.Add('8'+EOL+LayerName);
     Strings.Add('10'+EOL+FloatToDec(P.X,4));
     Strings.Add('20'+EOL+FloatToDec(P.z,4));
     Strings.Add('30'+EOL+FloatToDec(P.y,4));
     Strings.Add('70'+EOL+'32'); // 3D polyline mesh vertex
  end;
  Strings.Add('0'+EOL+'SEQEND');
  if SendMirror then begin // send starboard side of the St also
     Strings.Add('0'+EOL+'POLYLINE');
     Strings.Add('8'+EOL+LayerName);      // layername
     Strings.Add('62'+EOL+IntToStr(Ind)); // color by layer
     Strings.Add('70'+EOL+'10');          // not closed
     Strings.Add('66'+EOL+'1');           // vertices follow
     for J:=0 to NParams do begin
        P:=Value(Params[J-1]);
        P.Y:=-P.Y;
        Strings.Add('0'+EOL+'VERTEX');
        Strings.Add('8'+EOL+LayerName);
        Strings.Add('10'+EOL+FloatToDec(P.X,4));
        Strings.Add('20'+EOL+FloatToDec(P.z,4));
        Strings.Add('30'+EOL+FloatToDec(P.y,4));
        Strings.Add('70'+EOL+'32'); // 3D polyline mesh vertex
     end;
     Strings.Add('0'+EOL+'SEQEND');
  end;
end;

procedure TSpline.Clear;
begin
   Setlength(FDerivatives,0);
   Setlength(FParameters,0);
   FTotalLength:=0.0;
   nS:=0;
   inherited Clear;
   Build:=False;
   Setlength(FPoints,0);
   FCapacity:=0;
   nS:=0;
   FFragments:=100;
   FShowCurvature:=false;
   FShowPoints:=False;
end;

function TSpline.Value( Parameter:Real ):Vector;
var Lo,Hi,K: Integer; H,a,b: Real;
begin Result:=Zero;
   if nS<2 then exit;
   if not FBuild then Rebuild;
   if nS<2 then exit;
   if nS=2 then begin Lo:=0; Hi:=1;
   end else begin Lo:=0; Hi:=nS-1;
      repeat
         K:=(Lo+Hi) div 2;
         if FParameters[K]<Parameter then Lo:=K
                                     else Hi:=K;
      until Hi-Lo<=1;
   end;
   H:=FParameters[Hi]-FParameters[Lo];
   if abs(H)<1e-6 then begin       //Raise exception.Create('Invalid cspline');
      Result:=FPoints[Hi];
   end else begin
      A:=(FParameters[Hi]-Parameter)/H;
      B:=(Parameter-FParameters[Lo])/H;
      Result:=A*FPoints[Lo]
            + B*FPoints[Hi]
            + H*H*( (A*A*A-A)*FDerivatives[Lo]
            + (B*B*B-B)*(Fderivatives[Hi]) )/6.0;
   end;
end;
{
    TNURBSurface
}
procedure TNURBSurface.SetCapacity(Col,Row:integer);
var I  : Integer;
begin
   Setlength(FControlPoints,Row);
   for I:=1 to Row do Setlength(FControlPoints[I-1],Col);
   FColCapacity:=Col;
   FRowCapacity:=Row;
end;

function TNURBSurface.FGetpoint(Col,Row:Integer):Vector;
begin
   Result:=FControlPoints[Row][Col];
end;

procedure TNURBSurface.FSetColDegree(Val:Integer);
begin
   if Val>5 then Val:=5;
   if Val<>FColDegree then begin
      FColDegree:=Val;
      Build:=False;
   end;
end;

procedure TNURBSurface.FSetRowDegree(Val:Integer);
begin
   if Val>5 then Val:=5;
   if Val<>FRowDegree then begin
      FRowDegree:=Val;
      Build:=False;
   end;
end;

procedure TNURBSurface.SetDefaultColKnotvector;
var I,L,No: Integer;
begin
   if FColDegree>ColCount-1 then FColDegree:=ColCount-1;
   L:=ColCount+FColDegree+1;
   Setlength(FColKnots,L);
   No:=(ColCount+FColDegree+1)-2*FColDegree;
   for I:=1 to FColDegree do FColKnots[I-1]:=0.0;
   for I:=1 to No do begin
      FColKnots[I+FColDegree-1]:=((I-1)/(No-1));
      if FColKnots[I-1]<0.0 then FColKnots[I-1]:=0.0 else
         if FColKnots[I-1]>1.0 then FColKnots[I-1]:=1.0;
   end;
   for I:=1 to FColDegree do FColKnots[FColDegree+No+I-1]:=1.000;
end;

procedure TNURBSurface.SetDefaultRowKnotvector;
var I,L,No: Integer;
begin
   if FRowDegree>RowCount-1 then FRowDegree:=RowCount-1;
   L:=RowCount+FRowDegree+1;
   Setlength(FRowKnots,L);
   No:=(RowCount+FRowDegree+1)-2*FRowDegree;
   for I:=1 to FRowDegree do FRowKnots[I-1]:=0.0;
   for I:=1 to No do begin
      FRowKnots[I+FRowDegree-1]:=((I-1)/(No-1));
      if FRowKnots[I-1]<0.0 then FRowKnots[I-1]:=0.0 else
         if FRowKnots[I-1]>1.0 then FRowKnots[I-1]:=1.0;
   end;
   for I:=1 to FRowDegree do FRowKnots[FRowDegree+No+I-1]:=1.000;
end;

procedure TNURBSurface.SetUniformColKnotvector;
var I,L: Integer;
begin
   if FColDegree>ColCount-1 then FColDegree:=ColCount-1;
   L:=ColCount+FColDegree+1;
   Setlength(FColKnots,L);
   for I:=1 to L do begin
      FColKnots[I-1]:=(I-1)/(L-1);
         if FColKnots[I-1]<0.0 then FColKnots[I-1]:=0.0 else
            if FColKnots[I-1]>1.0 then FColKnots[I-1]:=1.0;
   end;
end;

procedure TNURBSurface.SetUniformRowKnotvector;
var I,L: Integer;
begin
   if FRowDegree>RowCount-1 then FRowDegree:=RowCount-1;
   L:=RowCount+FRowDegree+1;
   Setlength(FRowKnots,L);
   for I:=1 to L do begin
      FRowKnots[I-1]:=(I-1)/(L-1);
         if FRowKnots[I-1]<0.0 then FRowKnots[I-1]:=0.0 else
            if FRowKnots[I-1]>1.0 then FRowKnots[I-1]:=1.0;
   end;
end;

procedure TNURBSurface.FSetPoint(Col,Row:Integer;Val:Vector);
begin
   if (Col>ColCapacity) and (Row>RowCapacity) then SetCapacity(Col,Row) else
      if Col>ColCapacity then SetCapacity(Col,RowCapacity) else
         if Row>RowCapacity then SetCapacity(ColCapacity,Row);
   FControlPoints[Row][Col]:=Val;
   Build:=false;
end;

procedure TNURBSurface.FSetColCapacity(Val:integer);
begin
   if Val<>FColCapacity then SetCapacity(Val,FRowCapacity);
end;

procedure TNURBSurface.FSetRowCapacity(Val:integer);
begin
   if Val<>FRowCapacity then SetCapacity(FColCapacity,Val);
end;

procedure TNURBSurface.Clear;
begin
   Build:=false;
   Inherited Clear;
   SetCapacity(0,0);
   ColCount:=0;
   RowCount:=0;
   FColDegree:=3;
   FRowDegree:=3;
   Setlength(FColKnots,0);
   Setlength(FRowKnots,0);
end;

procedure TNURBSurface.DeleteColumn(Col:Integer);
var I:Integer;
begin
   for I:=1 to Rowcount do begin
      Move( FControlpoints[I-1][Col+1],
            FControlpoints[I-1][Col],(Colcount-Col-1)*SizeOf(Vector));
   end;
   Dec(ColCount);
   Build:=False;
end;

procedure TNURBSurface.DeleteRow(Row:Integer);
var I:Integer;
begin
   for I:=Row+1 to Rowcount-1 do
     Move(FControlpoints[I][0],FControlpoints[I-1][0],(Colcount)*SizeOf(Vector));
   Dec(RowCount);
   Build:=False;
end;

procedure TNURBSurface.InsertColKnot(U:Real);
var Index,L,I,J,k,N,X: Integer;
    NewPoints: TCoordinateGrid;
    Alpha: RealArray;
begin
   if Length(FColKnots)=0 then SetDefaultColKnotvector;
   FBuild:=True;                                           // Find lowest index
   Index:=0;
   for J:=1 to Length(FColknots)-1 do begin
      if (FColknots[J-1]<U) and (FColknots[J]>=U) then begin
         Index:=J-1;
         break;
      end;
   end;
   if Index<>-1 then begin
      I:=index;
      N:=Colcount;;
      k:=FColdegree+1;
      Setlength(Alpha,N+1);
      Setlength(Newpoints,RowCount);
      L:=I-k+1;
      if L<0 then L:=0;
      for J:=0 to N do begin
         if J<=L then alpha[J]:=1.0 else
            if (L+1<=J) and (J<=I) then begin
               if FColknots[j+k-1]-FColknots[J]=0 then alpha[J]:=0
                                                  else alpha[J]:=(U-FColknots[J])/(FColknots[j+k-1]-FColknots[J]);
            end else alpha[J]:=0;
      end;
      for J:=1 to RowCount do begin
         Setlength(Newpoints[J-1],N+1);
         for X:=0 to N do begin
            if Alpha[X]=0.0 then NewPoints[J-1][X]:=FControlpoints[J-1][X-1] else
            if Alpha[X]=1.0 then NewPoints[J-1][X]:=FControlpoints[J-1][X]
            else begin
               NewPoints[J-1][X]:=(1-Alpha[X])*FControlpoints[J-1][X-1]+Alpha[X]*FControlpoints[J-1][X];
            end;
         end;
      end;
      for I:=1 to Rowcount do begin
         setlength(FControlpoints[I-1],Colcount+1);
         Move(Newpoints[I-1][0],FControlpoints[I-1][0],(Colcount+1)*SizeOf(Vector));
      end;                                             // create new knotvector
      X:=length(FColknots);
      Setlength(FColknots,X+1);
      Move(FColknots[index],FColknots[index+1],(X-Index)*SizeOf(Real));
      FColknots[index+1]:=U;
      FColCapacity:=Colcount;
      inc(Colcount);
   end;
end;

procedure TNURBSurface.InsertRowKnot(V:Real);
var Index,I,J,k,N,X: Integer;
    NewPoints: TCoordinateGrid;
    Alpha: RealArray;
begin

   if Length(FRowKnots)=0 then SetDefaultRowKnotvector;
   FBuild:=True;
   // Find lowest index
   Index:=-1;
   for J:=1 to Length(FRowknots)-1 do begin
      if (FRowknots[J-1]<=V) and (FRowknots[J]>V) then begin
         Index:=J-1;
         break;
      end;
   end;
   if Index<>-1 then begin
      I:=index;
      N:=Rowcount;
      k:=FRowdegree+1;
      Setlength(Alpha,N+1);
      Setlength(Newpoints,RowCount+1);
      for J:=0 to N do begin
         Setlength(Newpoints[J],Colcount);
         if J<=I-k+1 then alpha[J]:=1.0 else
         if (I-k+2<=J) and (J<=I) then begin
            if FRowknots[j+k-1]-FRowknots[J]=0 then alpha[J]:=0
                                               else alpha[J]:=(V-FRowknots[J])/(FRowknots[j+k-1]-FRowknots[J]);
         end else alpha[J]:=0;
      end;
      for J:=1 to ColCount do begin
         for X:=0 to N do begin
            if Alpha[X]=0.0 then NewPoints[X][J-1]:=FControlpoints[X-1][J-1] else
            if Alpha[X]=1.0 then NewPoints[X][J-1]:=FControlpoints[X][J-1]
            else NewPoints[X][J-1]:=(1-Alpha[X])*FControlpoints[X-1][J-1]+alpha[X]*FControlpoints[X][J-1];
         end;
      end;               // Replace the current controlpoints with the new ones
      Setlength(FControlpoints,Rowcount+1);
      for I:=0 to Rowcount do begin
         setlength(FControlpoints[I],Colcount);
         Move(Newpoints[I][0],FControlpoints[I][0],(Colcount)*SizeOf(Vector));
      end;
      X:=length(FRowknots);                    // create the new new knotvector
      Setlength(FRowknots,X+1);
      Move(FRowknots[index],FRowknots[index+1],(X-Index)*SizeOf(Real));
      FRowknots[index+1]:=V;
      inc(Rowcount);
      FRowCapacity:=Rowcount;
   end;
end;

procedure TNURBSurface.Rebuild;
begin
   if Build then Build:=false;
   if FColDegree>Colcount-1 then FColDegree:=Colcount-1;
   if FRowDegree>Rowcount-1 then FRowDegree:=Rowcount-1;
   SetDefaultColKnotVector;
   SetDefaultRowKnotVector;
   Build:=True;
   Inherited Rebuild;
end;
{
  SBase
  SBase is the base class for all subdivision points, edges and faces
}
constructor SBase.Create( Own:SSurface);
      begin Inherited Create; Owner:=Own; end;
{
  SControlCurve
}
procedure SControlCurve.FSetBuild(Val:Boolean);
    begin FBuild:=Val; end;

procedure SControlCurve.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedControlCurves.IndexOf(self);
   if Val then begin               // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedControlCurves.Add(self);
   end else begin
      if Index<>-1 then Owner.FSelectedControlCurves.Delete(index);
   end;
   if Assigned(Owner.OnSelectItem) then Owner.OnSelectItem(self);
end;

procedure SControlCurve.AddPoint(P:SPoint);
begin
   FControlPoints.Add(P);
   Build:=False;
end;

function SControlCurve.FGetColor:TColor;
begin
   if Selected then Result:=Sp.Select
               else Result:=Sp.ControlCurve;
end;

function SControlCurve.FGetSelected:Boolean;
begin
   Result:=Owner.FSelectedControlCurves.IndexOf(self)<>-1;
end;

function SControlCurve.FGetVisible:Boolean;
begin
   Result:=Owner.ShowControlCurves;
end;

function SControlCurve.FGetNoControlPoints:Integer;
begin
   Result:=FControlPoints.Count;
end;

function SControlCurve.FGetControlPoint(Index:Integer):SControlPoint;
begin
   Result:=FControlPoints[index];
end;

procedure SControlCurve.Clear;
begin
   FControlPoints.Clear;
   FVisible:=True;
   FCurve.Clear;
   FSubdividedPoints.Clear;
   FBuild:=False;
end;

constructor SControlCurve.Create(Owner:SSurface);
begin
   Inherited Create(Owner);
   FControlPoints:=TFasterList.Create;
   FSubdividedPoints:=TFasterList.Create;
   FCurve:=TSpline.Create;
   Clear;
end;

procedure SControlCurve.Delete;
var Index,I: Integer; P1,P2: SPoint; Edge: SEdge;
begin
   Index:=Owner.FSelectedControlCurves.IndexOf(self);
   if Index<>-1 then Owner.FSelectedControlCurves.Delete(Index);
   Index:=Owner.FControlCurves.IndexOf(self);
   if Index<>-1 then Owner.FControlCurves.Delete(Index);
   for I:=2 to FControlPoints.Count do begin // Remove references from control edges
      P1:=FControlPoints[I-2];
      P2:=FControlPoints[I-1];
      Edge:=Owner.EdgeExists( P1,P2 );
      if Edge<>nil then Edge.Curve:=nil;
   end;
   FControlPoints.Clear;
   for I:=2 to FSubdividedPoints.Count do begin // Remove references from subdivided edges
      P1:=FSubdividedPoints[I-2];
      P2:=FSubdividedPoints[I-1];
      Edge:=Owner.EdgeExists(P1,P2);
      if Edge<>nil then Edge.Curve:=nil;
   end;
   FSubdividedPoints.Clear;
   Destroy;
end;

procedure SControlCurve.DeleteEdge(Edge:SControlEdge);
var I,J: Integer;
    P1,P2: SPoint;
    AnEdge: SEdge;
    NewCurve: SControlCurve;
    DelCurve: Boolean;
begin
   DelCurve:=False;
   I:=2;
   While I<=FControlPoints.Count do begin
      if ((FControlPoints[I-2]=Edge.StartPoint)
      and (FControlPoints[I-1]=Edge.EndPoint))
      or ((FControlPoints[I-2]=Edge.EndPoint)
      and (FControlPoints[I-1]=Edge.StartPoint)) then begin
         // Remove references to this curve from control edges
         for J:=2 to FControlPoints.Count do begin
            P1:=FControlPoints[J-2];
            P2:=FControlPoints[J-1];
            AnEdge:=Owner.EdgeExists(P1,P2);
            if AnEdge<>nil then AnEdge.Curve:=nil;
         end;                        // Remove references from subdivided edges
         if Build then for J:=2 to FSubdividedPoints.Count do begin
            P1:=FSubdividedPoints[J-2];
            P2:=FSubdividedPoints[J-1];
            AnEdge:=Owner.EdgeExists(P1,P2);
            if AnEdge<>nil then AnEdge.Curve:=nil;
         end;
         FSubdividedPoints.Clear;
         if I-2>0 then begin                           // build first new curve
            NewCurve:=SControlCurve.Create(Owner);
            NewCurve.FControlPoints.Capacity:=I-1;
            Owner.AddControlCurve(Newcurve);
            P1:=nil;
            for J:=0 to I-2 do begin
               P2:=FControlPoints[J];
               NewCurve.FControlPoints.Add(P2);
               if J>0 then begin
                  AnEdge:=Owner.EdgeExists(P1,P2);
                  if AnEdge<>nil then AnEdge.Curve:=NewCurve;
               end; P1:=P2;
            end; NewCurve.Selected:=Selected;
         end;
         if I-1<FControlPoints.Count-1 then begin     // build second new curve
            NewCurve:=SControlCurve.Create(Owner);
            NewCurve.FControlPoints.Capacity:=FControlPoints.Count-(I-1);
            Owner.AddControlCurve(Newcurve);
            P1:=nil;
            for J:=I-1 to FControlPoints.Count-1 do begin
               P2:=FControlPoints[J];
               NewCurve.FControlPoints.Add(P2);
               if J>I-1 then begin
                  AnEdge:=Owner.EdgeExists(P1,P2);
                  if AnEdge<>nil then AnEdge.Curve:=NewCurve;
               end; P1:=P2;
            end; NewCurve.Selected:=Selected;
         end;
         DelCurve:=True; break;
      end;
      inc(I);
   end;
   if DelCurve then begin
      FControlPoints.Clear;
      J:=Owner.FSelectedControlCurves.IndexOf(self);
      if J<>-1 then Owner.FSelectedControlCurves.Delete(J);
      J:=Owner.FControlCurves.IndexOf(self);
      if J<>-1 then Owner.FControlCurves.Delete(J);
      Destroy;
   end;
end;

destructor SControlCurve.Destroy;
begin
   Clear;
   FControlPoints.Destroy;
   FSubdividedPoints.Destroy;
   Fcurve.Destroy;
   Inherited Destroy;
end;

function SControlCurve.DistanceToCursor(X,Y:Integer;Viewport:TViewport):integer;
var I,Tmp    : Integer;
    Pt,P1,P2 : TPoint;
    V1,V2    : Vector;
    Param    : Real;
begin
   if (Viewport.ViewType=fvBodyPlan) and (not Owner.DrawMirror) then begin
      Result:=1000000;   // Check if cursor position lies within the boundaries
      Pt.X:=X;
      Pt.Y:=Y;
      if (Pt.X>=0) and (Pt.X<=Viewport.Width)
      and (Pt.Y>=0) and (Pt.Y<=Viewport.Height) then begin
         V1:=FCurve.Value(0.0);
         if V1.X<Owner.MainframeLocation then V1.Y:=-V1.Y;
         for I:=1 to FCurve.Fragments do begin
            V2:=FCurve.Value((I-1)/(FCurve.Fragments-1));
            if V2.X<Owner.MainframeLocation then V2.Y:=-V2.Y;
            if ((V1.X<Owner.MainframeLocation) and (V2.X<Owner.MainframeLocation))
            or ((V1.X>Owner.MainframeLocation) and (V2.X>Owner.MainframeLocation))
            then begin
               P1:=Viewport.Project(V1);
               P2:=Viewport.Project(V2);
               Tmp:=Round(DistanceToLine(P1,P2,X,Y,Param));
               if Tmp<Result then result:=Tmp;
            end;
            P1:=P2;
            V1:=V2;
         end;
      end;
   end else Result:=FCurve.DistanceToCursor(X,Y,Viewport);
   if Owner.DrawMirror then begin
      for I:=1 to FCurve.nS do begin
         V1:=FCurve.Point[I-1];
         V1.Y:=-V1.Y;
         FCurve.Point[I-1]:=V1;
      end;
      Tmp:=FCurve.DistanceToCursor(X,Y,Viewport);
      if Tmp<Result then Result:=Tmp;
      for I:=1 to FCurve.nS do begin
         V1:=FCurve.Point[I-1];
         V1.Y:=-V1.Y;
         FCurve.Point[I-1]:=V1;
      end;
   end;
end;

procedure SControlCurve.Draw(Viewport:TViewport);
var Sel   : Boolean;
    P1,P2 : SControlPoint;
    I,J,Scale,Fragm,NParam: Integer;
    Param : RealArray;
    Edge  : SControlEdge;
    Plane : Plate;
    Output: TIntersectionData;
    PArray1,PArray2: array of TPoint;
    P3D,Normal: Vector;
    C,T: Real;
begin
   if FCurve.nS>1 then begin
      FCurve.Color:=Color;
      Sel:=Selected;
      FCurve.ShowCurvature:=(Sel) and (Owner.ShowCurvature);
      if FCurve.ShowCurvature then FCurve.Fragments:=600
                              else FCurve.Fragments:=250;
      if not Owner.ShowControlNet and (Sel) then
      For I:=2 to FControlPoints.Count do begin
         P1:=FControlPoints[I-2];
         P2:=FControlPoints[I-1];
         Edge:=Owner.EdgeExists(P1,P2) as SControlEdge;
         if Edge<>nil then Edge.Draw( False,Viewport );
         if I=2 then P1.Draw(Viewport);
         P2.Draw(Viewport);
      end;
      if (Viewport.ViewType=fvBodyPlan) and (not Owner.DrawMirror) then begin
         Plane:=SetPlane(1.0,0.0,0.0,-Owner.MainframeLocation);
         NParam:=2;
         Setlength(Param,NParam);
         Param[0]:=0.0;
         Param[1]:=1.0;
         if FCurve.IntersectPlane(Plane,Output) then begin
            Setlength(Param,NParam+Output.NoIntersections);
            for I:=1 to Output.NoIntersections do begin
               Param[NParam]:=Output.Parameters[I-1];
               inc(NParam);
            end;
            ArraySort( Param,NParam );
         end;
         for I:=2 to NParam do begin
            P3D:=FCurve.Value(0.5*(Param[I-2]+Param[I-1]));
            if P3D.X<Owner.MainframeLocation then Scale:=-1 else scale:=1;
            Fragm:=Round((Param[I-1]-Param[I-2])*FCurve.Fragments);
            if Fragm<10 then Fragm:=10;
            if FCurve.ShowCurvature then begin
               SetLength(PArray1,Fragm);
               SetLength(PArray2,Fragm);
               for J:=1 to Fragm do begin
                  T:=Param[I-2]+(Param[I-1]-Param[I-2])*(J-1)/(Fragm-1);
                  C:=FCurve.Curvature(T,P3D,Normal);
                  P3D.Y:=P3D.Y*Scale;
                  Normal.Y:=Normal.Y*Scale;
                  PArray1[J-1]:=Viewport.Project(P3D);
                  PArray2[J-1]:=Viewport.Project( P3D-(2.0*C*Sp.CurvatureScale)*Normal );
               end;
               Viewport.SetPenWidth(1);
               Viewport.PenColor:=Sp.CurvaturePlot;
               for J:=1 to Fragm do
               if (J mod 4=0) or (J=1) or (J=Fragm) then begin
                  Viewport.Canvas.MoveTo(PArray1[J-1].X,PArray1[J-1].Y);
                  Viewport.Canvas.LineTo(PArray2[J-1].X,PArray2[J-1].Y);
               end;
               Viewport.Canvas.Polyline(PArray2);
            end else begin
               SetLength(PArray1,Fragm);
               for J:=1 to Fragm do begin
                  T:=Param[I-2]+(Param[I-1]-Param[I-2])*(J-1)/(Fragm-1);
                  P3D:=FCurve.Value(T);
                  P3D.Y:=P3D.Y*Scale;
                  PArray1[J-1]:=Viewport.Project(P3D);
               end;
            end;
            Viewport.SetPenWidth(1);
            Viewport.PenColor:=Color;
            Viewport.Canvas.Pen.Style:=FCurve.Penstyle;
            Viewport.Canvas.Polyline(PArray1);
         end;
      end else FCurve.Draw(Viewport);
      if Owner.DrawMirror then begin
         for I:=1 to FCurve.nS do begin
            P3D:=FCurve.Point[I-1];
            P3D.Y:=-P3D.Y;
            FCurve.Point[I-1]:=P3D;
         end;
         FCurve.Draw(Viewport);
         for I:=1 to FCurve.nS do begin
            P3D:=FCurve.Point[I-1]; P3D.Y:=-P3D.Y;
                 FCurve.Point[I-1]:=P3D;
         end;
      end;
   end;
end;

procedure SControlCurve.InsertControlPoint(P1,P2,New:SControlPoint);
var I : Integer;
begin
   I:=2;
   While I<=FControlPoints.Count do begin
      if ((FControlPoints[I-2]=P1) and (FControlPoints[I-1]=P2))
      or ((FControlPoints[I-1]=P1) and (FControlPoints[I-2]=P2))
      then FControlPoints.Insert(I-1,New);
      inc(I);
   end;
end;

procedure SControlCurve.InsertEdgePoint(P1,P2,New:SPoint);
var I : Integer;
begin
   I:=2;
   While I<=FSubdividedPoints.Count do begin
      if ((FSubdividedPoints[I-2]=P1) and (FSubdividedPoints[I-1]=P2))
      or ((FSubdividedPoints[I-1]=P1) and (FSubdividedPoints[I-2]=P2))
      then FSubdividedPoints.Insert(I-1,New);
      inc(I);
   end;
end;

procedure SControlCurve.LoadBinary(Source:TFileBuffer);
var I,N,Ind : Integer;
    P1,P2  : SPoint;
    Edge   : SEdge;
    Sel    : Boolean;
begin
   Source.LoadInteger(N);
   FControlPoints.Capacity:=N;
   P1:=nil;
   for I:=1 to N do begin
      Source.LoadInteger(Ind);
      P2:=Owner.FControlPoints[ind];
      FControlPoints.Add(P2);
      if I>1 then begin
         Edge:=Owner.EdgeExists(P1,P2);
         if Edge<>nil then Edge.Curve:=self;
      end;
      P1:=P2;
   end;
   FSubdividedPoints.AddList(FControlPoints);
   Source.LoadBoolean(Sel);
   if Sel then selected:=True;
end;

procedure SControlCurve.ReplaceVertexPoint(Old,New:SPoint);
var I:Integer;
begin
   for I:=1 to FSubdividedPoints.Count do
   if FSubdividedPoints[I-1]=old then begin
      FSubdividedPoints[I-1]:=New;
      FCurve.Clear;
   end;
end;

procedure SControlCurve.SaveBinary(Destination:TFileBuffer);
var I,Ind: Integer; P: SPoint;
begin
   Destination.Add(NoControlPoints);
   for I:=1 to NoControlPoints do begin
      P:=FControlPoints[I-1];
      Ind:=Owner.FControlPoints.SortedIndexOf(P);
      Destination.Add(Ind);
   end;
   Destination.Add(Selected);
end;

procedure SControlCurve.SaveToDXF(Strings:TStringList);
var Layer : string;
begin
   Layer:='Control_curves';
   FCurve.Fragments:=FCurve.nS;
   FCurve.SaveToDXF(Strings,Layer,Owner.DrawMirror);
end;
{
 SLayer is a leyrtype class
  All individual controlfaces can be assigned to a leyer. Properties such as color,
 visibility etc. are common for all controlfaces belonging the the same layer
}
function SLayer.FGetColor:TColor;
   begin Result:=FColor; end;
function SLayer.FGetCount:Integer;
   begin Result:=FPatches.Count; end;
function SLayer.FGetDXFLayername:string;
   begin Result:=self.Name; end;
function SLayer.FGetName:string;
begin if FDescription='' then Result:=Userstring(33)+#32+IntToStr(LayerId)
                         else Result:=FDescription;
end;
function SLayer.FGetItems(Index:Integer):SControlFace;
   begin Result:=FPatches[Index]; end;
function SLayer.FGetLayerIndex:Integer;
   begin Result:=Owner.FLayers.IndexOf(self); end;

function SLayer.FGetSurfaceProperties:TLayerProperties;
var I,J,K: Integer;
    Child: SFace;
    procedure ProcessTriangle(P1,P2,P3:Vector);
    var Center: Vector; ax,ay,az,Area: Real;
    begin
       Center:=(P1+P2+P3)/3.0;
       ax:=0.5*((P1.y-P2.y)*(P1.z+P2.z)+(P2.y-P3.y)*(P2.z+P3.z)+
                (P3.y-P1.y)*(P3.z+P1.z));
       ay:=0.5*((P1.z-P2.z)*(P1.x+P2.x)+(P2.z-P3.z)*(P2.x+P3.x)+
                (P3.z-P1.z)*(P3.x+P1.x));
       az:=0.5*((P1.x-P2.x)*(P1.y+P2.y)+(P2.x-P3.x)*(P2.y+P3.y)+
                (P3.x-P1.x)*(P3.y+P1.y));
       Area:=Sqrt(ax*ax+ay*ay+az*az);
       Result.SurfaceArea+=Area;
       Result.SurfaceCenterOfGravity+=Area*Center;
    end;
begin
   Fillchar(Result,SizeOf(Result),0);
   for I:=1 to Count do begin
      For J:=1 to Items[I-1].ChildCount do begin
         Child:=Items[I-1].Child[J-1];
         for K:=3 to Child.Nopoints do
            ProcessTriangle(Child.Point[0].Coordinate,Child.Point[K-2].Coordinate,Child.Point[K-1].Coordinate);
      end;
   end;
   if Result.SurfaceArea<>0 then begin
      Result.SurfaceCenterOfGravity/=Result.SurfaceArea;
      if Symmetric then begin
         Result.SurfaceArea:=2*Result.SurfaceArea;
         Result.SurfaceCenterOfGravity.Y:=0.0;
      end;
      Result.Weight:=Result.SurfaceArea*Thickness*MaterialDensity;
   end;
end;

procedure SLayer.FSetFDevelopable(Val:Boolean);
begin
   if val<>FDevelopable then begin
      FDevelopable:=Val;
      if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
   end;
end;

procedure SLayer.FSetName(Val:String);
begin
   if Uppercase(Val)<>Uppercase(FDescription) then begin
      FDescription:=Val;
      if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
      if (self=Owner.ActiveLayer) and (assigned(Owner.OnChangeActiveLayer)) then owner.OnChangeActiveLayer(Owner,Owner.ActiveLayer);
   end;
end;

procedure SLayer.FSetSymmetric(Val:Boolean);
begin
   if Val<>FSymmetric then begin
      FSymmetric:=Val;
      if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
   end;
end;

procedure SLayer.FSetColor(Val:TColor);
begin
   if Val<>FColor then begin FColor:=Val;
      if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
      if (self=Owner.ActiveLayer) and (assigned(Owner.OnChangeActiveLayer))
                then owner.OnChangeActiveLayer(Owner,Owner.ActiveLayer);
   end;
end;

procedure SLayer.FSetShowInLinesplan(val:boolean);
begin
   if Val<>FShowInLinesplan then begin
      FShowInLinesplan:=val;
      if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
   end;
end;

procedure SLayer.FSetUseInHydrostatics(val:boolean);
begin
   if val<>FUseInHydrostatics then begin
      FUseInHydrostatics:=Val;
      if FUseInHydrostatics and (not FSymmetric) then FSymmetric:=true;
      if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
   end;
end;

procedure SLayer.FSetUseForIntersections(val:Boolean);
begin
   if val<>FUseForIntersections then begin
      FUseForIntersections:=Val;
      if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
   end;
end;

procedure SLayer.FSetVisible(Val:Boolean);
begin
   if Val<>FVisible then begin
      FVisible:=Val;
      if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
   end;
end;

procedure SLayer.AddControlFace(ControlFace:SControlFace);
begin                                         // disconnect from current layer
   if ControlFace.Layer<>nil then ControlFace.Layer.DeleteControlFace(ControlFace);
   if FPatches.Indexof(ControlFace)=-1 then FPatches.Add(ControlFace);
   ControlFace.FLayer:=self;
end;

procedure SLayer.AssignProperties(Source:SLayer);
begin
   FColor:=Source.FColor;
   FVisible:=True;
   FDescription:='';
   FSymmetric:=Source.FSymmetric;
   FDevelopable:=Source.FDevelopable;
   MaterialDensity:=Source.MaterialDensity;
   Thickness:=Source.Thickness;
end;

function SLayer.CalculateIntersectionPoints(Layer:SLayer):Boolean;
var I,J,K,L    : Integer;
    Edges,NewPoints: TFasterList;
    P1,P2      : SPoint;
    P          : SControlpoint;
    Edge       : SControlEdge;
    Face       : SControlface;
    Child      : SFace;
    IntFound,Inserted: Boolean;
    Plane      : Plate;
    S1,S2,T    : Real;
    P3D        : Vector;
begin
   Result:=False;
   Edges:=TFasterList.Create;
   NewPoints:=TFasterList.Create;        // assemble all controledges in a list
   for I:=1 to count do begin
      Face:=Items[I-1];
      P1:=Face.Point[Face.NoPoints-1];
      for J:=1 to Face.Nopoints do begin
        P2:=Face.Point[J-1];
         Edge:=Owner.EdgeExists(P1,P2) as SControlEdge;
         if Edge<>nil then if Edges.SortedIndexOf(Edge)=-1 then Edges.AddSorted(Edge);
         P1:=P2;
      end;
   end;                    // now check all edges for intersection with layer 2
   I:=1;
   while I<=Edges.Count do begin
      Edge:=Edges[I-1];
      IntFound:=False;
      J:=1;
      while (J<=Layer.Count) and (not IntFound) do begin
         Face:=Layer.Items[J-1];
         K:=1;
         while (K<=Face.ChildCount) and (not IntFound) do begin
            Child:=Face.Child[K-1];
            L:=3;
            while (L<=Child.Nopoints) and (not IntFound) do begin
               Plane:=PlanePPP(Child.Point[0].Coordinate,Child.Point[L-2].Coordinate,Child.Point[L-1].Coordinate);
               S1:=Plane.a*Edge.Startpoint.FCoordinate.X+Plane.b*Edge.Startpoint.FCoordinate.Y+Plane.c*Edge.Startpoint.FCoordinate.Z+Plane.d;
               S2:=Plane.a*Edge.Endpoint.FCoordinate.X+Plane.b*Edge.Endpoint.FCoordinate.Y+Plane.c*Edge.Endpoint.FCoordinate.Z+Plane.d;
               if ((S1<0) and (S2>0)) or ((S1>0) and (S2<0)) then begin
                  // Edge intersects the plane, does it lie in the triangle?
                  if S1=S2 then T:=0.5
                           else T:=-s1/(s2-s1);
                  P3D.X:=Edge.Startpoint.FCoordinate.X+T*(Edge.Endpoint.FCoordinate.X-Edge.Startpoint.FCoordinate.X);
                  P3D.Y:=Edge.Startpoint.FCoordinate.Y+T*(Edge.Endpoint.FCoordinate.Y-Edge.Startpoint.FCoordinate.Y);
                  P3D.Z:=Edge.Startpoint.FCoordinate.Z+T*(Edge.Endpoint.FCoordinate.Z-Edge.Startpoint.FCoordinate.Z);
                  if PointInTriangle(P3D,Child.Point[0].Coordinate,Child.Point[L-2].Coordinate,Child.Point[L-1].Coordinate)
                  then begin          // Yes, we have a valid intersection here
                     P:=Edge.InsertControlPoint(P3D);
                     if P<>nil then begin
                        IntFound:=true;
                           Result:=True;
                           NewPoints.Add(P);
                     end;
                  end;
               end; inc(L);
            end;    inc(K);
         end;       inc(J);
      end;          inc(I);
   end;
   if NewPoints.Count>0 then begin
      // Try to find multiple new points belonging to the same face and insert an edge
      I:=1;
      NewPoints.Sort;
      Edges.Clear;
      while I<=NewPoints.Count do begin
         P1:=NewPoints[I-1];
         J:=1;
         while J<=P1.NoFaces do begin
            Face:=P1.Face[J-1] as SControlface;
            K:=1;
            Inserted:=False;
            while (K<=Face.Nopoints) and (Not Inserted) do begin
               P2:=Face.Point[K-1] as SControlPoint;
               if (P1<>P2) and (NewPoints.SortedIndexOf(P2)<>-1) then begin
                  // this is also a new point, first check if an edge already exists between P1 and P2
                  if Owner.EdgeExists(P1,P2)=nil then begin
                     Inserted:=True;
                     Edge:=Face.InsertEdge(P1 as SControlPoint,P2 as SControlPoint);
                     Edge.Selected:=True;
                     Edges.Add(Edge);
                  end;
               end;  inc(K);
            end;     if not Inserted then inc(J);
         end;        inc(I);
      end;
   end;
   Edges.Destroy;
   NewPoints.Destroy;
end;

constructor SLayer.Create( Own:SSurface );
begin
   inherited Create;
   Owner:=Own;
   FPatches:=TFasterList.Create;
   Clear;
end;

procedure SLayer.Clear;
begin
   LayerID:=-1;
   FPatches.Clear;
   FColor:=Sp.Layer;
   FVisible:=True;
   FDescription:='';
   FSymmetric:=True;
   FDevelopable:=False;
   FUseForIntersections:=True;
   FUseInHydrostatics:=True;
   FShowInLinesplan:=True;
   MaterialDensity:=0.0;
   Thickness:=0.0;
   AlphaBlend:=255;
end;

function SLayer.Delete:Boolean; var I,Index: Integer;
begin Result:=True;
   for I:=Count downto 1 do Items[I-1].SelDeleteFace;
   if Owner.FActiveLayer=self then Owner.FActiveLayer:=nil;
   Index:=LayerIndex;
   if Index<>-1 then Owner.FLayers.Delete(Index);
   Clear;
   if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
   Destroy;
end;

procedure SLayer.DeleteControlFace(ControlFace:SControlFace);
var Index: Integer;
begin
   Index:=FPatches.IndexOf(ControlFace);
   if index<>-1 then FPatches.Delete(Index);
end;

destructor SLayer.Destroy;
begin
   FPatches.Destroy;
   FPatches:=nil;
   Inherited Destroy;
end;

procedure SLayer.Draw(Viewport:TViewport);
var I,J: Integer; Face: SControlface; Edge: SEdge;
begin
   if Visible and (Count>0) then begin
      if Viewport.ViewportMode<>vmWireframe then begin             // vmShade++
         if Viewport.ViewportMode=vmShadeGauss
         then for I:=1 to Count do Items[I-1].Draw(Viewport,Owner.FMinGaussCurvature,Owner.FMaxGaussCurvature)
         else for I:=1 to count do Items[I-1].Draw(Viewport);
      end else begin
         if Owner.ShowInteriorEdges then begin
            Viewport.SetPenWidth(1);
            Viewport.PenColor:=Color;
            For I:=1 to Count do Items[I-1].Draw(Viewport);
         end;                                 // Draw all interior crease-edges
         Viewport.SetPenWidth(1);
         Viewport.PenStyle:=psSolid;
         Viewport.PenColor:=Sp.Crease;
         For I:=1 to Count do begin
            Face:=Items[I-1];
            for J:=1 to Face.FControlEdges.Count do begin
               Edge:=Face.FControlEdges[J-1];
               if Edge.FCrease then begin
                  Edge.Draw(Owner.DrawMirror and Symmetric,Viewport);
               end;
            end;
         end;
      end;
   end;
end;

procedure SLayer.Extents( var Min,Max:Vector );
var I: Integer; Face: SControlface; P: Vector;
begin
   if Visible then for I:=1 to Count do begin Face:=Items[I-1];
      MinMax(Face.Min,Min,Max);
      MinMax(Face.Max,Min,Max);
      if (Symmetric) and (Owner.DrawMirror) then begin
         P:=Face.Min; P.Y:=-P.Y; MinMax(P,Min,Max);
         P:=Face.Max; P.Y:=-P.Y; MinMax(P,Min,Max);
      end;
   end;
end;

procedure SLayer.LoadBinary(Source:TFileBuffer);
var I:Integer;
begin
   Source.LoadString(FDescription);
   Source.LoadInteger( LayerID );
   if LayerID>Owner.FLastusedLayerID then Owner.FLastusedLayerID:=LayerID;
   Source.LoadInteger(FColor);
     AlphaBlend:=255-byte( Cardinal( FColor ) shr 24 );
     FColor:=FColor and $FFFFFF;
   Source.LoadBoolean(FVisible);
   Source.LoadBoolean(FSymmetric);
   Source.LoadBoolean(FDevelopable);
   MaterialDensity:=0.0;
   Thickness:=0.0;
   FUseForIntersections:=True;
   FUseInHydrostatics:=True;
   FShowInLinesplan:=True;
   if Source.Version>=fv180 then begin
      Source.LoadBoolean(FUseForIntersections);
      Source.LoadBoolean(FUseInHydrostatics);
      if Source.Version>=fv191 then begin
         Source.LoadTFloatType(MaterialDensity);
         Source.LoadTFloatType(Thickness);
         if Source.Version>=fv201 then begin
            Source.LoadBoolean(FShowInLinesplan);
            if Source.Version>=fv260 then begin
               Source.LoadInteger(I);
               AlphaBlend:=I;
            end;
         end;
      end;
   end;
end;

procedure SLayer.MoveDown; var Index:Integer;
begin
   Index:=Owner.FLayers.IndexOf(self);
   if index<Owner.Flayers.Count-1 then Owner.FLayers.Exchange(Index+1,index);
end;
procedure SLayer.MoveUp; var Index:Integer;
begin
   Index:=Owner.FLayers.IndexOf(self);
   if index>0 then Owner.FLayers.Exchange(Index-1,index);
end;

procedure SLayer.SaveToDXF(Strings:TStringList);
var Layers   : TFasterList;
    Assembled: TFaceArray;
    NAssembled,I,J,K,Cols,Rows,Board: Integer;
    AssFace: TFaceGrid;
    Face   : SControlFace;
    Grid   : SGrid;
    P      : Vector;
    DXFName: string;
begin
   if visible then begin
      Layers:=TFasterList.Create;
      Layers.Add(self);
      Owner.AssembleFacesToPatches(Layers,amRegular,Assembled,NAssembled);
      if NAssembled>0 then begin           // assign all patches to new layers
         for I:=1 to NAssembled do begin
            AssFace:=Assembled[I-1];
            if ((AssFace.NCols>1) and (AssFace.NRows>=1)) or
               ((AssFace.NCols>=1) and (AssFace.NRows>1)) or
               ((AssFace.NCols=1) and (AssFace.NRows=1)
            and (AssFace.Faces[0][0].NoPoints=4)) then begin
               Owner.ConvertToGrid(AssFace,Cols,Rows,Grid);
               if (Cols>0) and (Rows>0) then begin
                  DXFName:=DXFLayerName;
                  for Board:=0 to 1 do begin
                     if Board=1 then
                     if (not Owner.DrawMirror) or (not Symmetric) then break;
                     Strings.Add('0'+EOL+'POLYLINE');
                     Strings.Add('8'+EOL+DXFName);
                     Strings.Add('62'+EOL+IntToStr(FindDXFColorIndex(color)));
                     Strings.Add('66'+EOL+'1');
                     Strings.Add('70'+EOL+'16');
                     Strings.Add('71'+EOL+IntToStr(Rows));
                     Strings.Add('72'+EOL+IntToStr(Cols));
                     for J:=1 to Rows do
                     for K:=1 to Cols do begin
                         P:=Grid[J-1][K-1].FCoordinate;
                         if Board=1 then P.Y:=-P.Y;
                         Strings.Add('0'+EOL+'VERTEX');
                         Strings.Add('8'+EOL+DXFName);
                         Strings.Add('10'+EOL+FloatToDec(P.X,4));
                         Strings.Add('20'+EOL+FloatToDec(P.z,4));
                         Strings.Add('30'+EOL+FloatToDec(P.y,4));
                         Strings.Add('70'+EOL+'64');     // polygon mesh vertex
                     end; Strings.add('0'+EOL+'SEQEND');
                  end;
               end else begin
                  for J:=1 to AssFace.NRows do begin
                     for K:=1 to AssFace.NCols do begin
                        Face:=AssFace.Faces[J-1][K-1];
                        if Face<>nil then Face.SaveToDXF(Strings);
                     end;
                  end;
               end;
            end else if (AssFace.NCols=1) and (AssFace.NRows=1) then begin
               Face:=AssFace.Faces[0][0];
               Face.SaveToDXF(Strings);
            end;
         end;
      end; Layers.Destroy;
   end;
end;

procedure SLayer.SaveBinary( Destination:TFileBuffer );
Var C: Cardinal;
begin
   Destination.Add(FDescription);
   Destination.Add( LayerID );
   C:=(Cardinal(FColor) and $FFFFFF)+(Cardinal(255-AlphaBlend) shl 24);
   Destination.Add( Integer( C ) );               //~~ Destination.Add(FColor);
   Destination.Add(FVisible);
   Destination.Add(FSymmetric);
   Destination.Add(FDevelopable);
// if Destination.Version>=fv180 then begin       == всегда ver.2.6
      Destination.Add(FUseForIntersections);
      Destination.Add(FUseInHydrostatics);
//    if Destination.Version>=fv191 then begin
         Destination.Add(MaterialDensity);
         Destination.Add(Thickness);
//       if Destination.Version>=fv201 then begin
            Destination.Add(FShowInLinesplan);
//          if Destination.Version>=fv260 then begin
               Destination.Add(AlphaBlend);
//          end;
//       end;
//    end;
// end;
end;

procedure SLayer.Unroll(Destination:TFasterList);
var ToDoList,DoneList,Current: TFasterList;
    I          : Integer;
    Face       : SControlFace;
    Patch,Copy : TDevelopedPatch;
    Str        : string;
    procedure FindAttachedFaces(List:TFasterList;Face:SControlFace);
    var I,J,Index: Integer;
        P1,P2: SPoint;
        Edge: SEdge;
    begin
       P1:=Face.Point[Face.NoPoints-1];
       for I:=1 to Face.Nopoints do begin
          P2:=Face.Point[I-1];
          Edge:=Face.Owner.EdgeExists(P1,P2);
          if Edge<>nil then begin
             for J:=1 to Edge.NoFaces do
             if Edge.Face[J-1]<>Face then begin
                Index:=ToDoList.IndexOf(Edge.Face[J-1]);
                if Index<>-1 then begin
                   List.Add(Edge.Face[J-1]);
                   ToDoList.Delete(Index);
                   FindAttachedFaces(List,Edge.Face[J-1] as SControlFace);
                end;
             end;
          end;     P1:=p2;
       end;
    end;
begin
   ToDoList:=TFasterList.Create;
   DoneList:=TFasterList.Create;
   ToDoList.Capacity:=FPatches.Count;
   ToDoList.AddList(FPatches);
   if ToDoList.Count>0 then begin
      while ToDoList.Count>0 do begin
         Face:=ToDoList[ToDoList.Count-1];
         ToDoList.Delete(ToDoList.Count-1);
         Current:=TFasterList.Create;
         Current.Add(Face);
         FindAttachedFaces(Current,Face);
         DoneList.Add(Current);
      end;                                 // Unroll each separate surface area
      for I:=1 to DoneList.Count do begin
         Current:=DoneList[I-1];
         if Current.Count>0 then begin
            Patch:=TDevelopedPatch.Create(self);
            Patch.Unroll(Current);
            if DoneList.Count=1 then Str:=Name
                                else Str:=Name+#32+Lowercase(Userstring(198))+#32+IntToStr(I);
            Patch.Name:=Str;
            Destination.Add(Patch);
            if (not Patch.FMirror) and (self.Symmetric) then begin
               Patch.Name:=Str+' (SB)';         // Create the starboard half
               Copy:=TDevelopedPatch.Create(self);
               Copy.Assign(Patch,True);
               Copy.Name:=Str+' (P)';
               Destination.Add(Copy);
            end;
         end;  Current.Destroy;
      end;
   end;
   ToDoList.Destroy;
   DoneList.Destroy;
end;
{
  SPoint
}
function SPoint.FGetEdge(Index:Integer):SEdge;
   begin Result:=FEdges[Index]; end;
function SPoint.FGetCoordinate:Vector;
   begin Result:=FCoordinate; end;

function SPoint.FGetCurvature:Real;
 var I,Index,PrevIndex,NextIndex: Integer;
     Prev,Next: SPoint;
     Face     : Sface;
     Sigma,Tmp: Real;
   function Angle_VV_3D(P1,P2,P3:Vector):Real;
     var V1,V2: Vector; L: Real;
   begin V1:=P1-P2; L:=abs( V1 ); if L<>0 then V1/=L;
         V2:=P3-P2; L:=abs( V2 ); if L<>0 then V2/=L;
         L:=DotProduct( V1,V2 );  if L<-1 then L:=-1 else if L>1 then L:=1;
         Result:=ArcCos( L );
   end;
begin Result:=0.0;
   for I:=1 to FEdges.Count do If Edge[I-1].NoFaces<2 then exit;
   if VertexType in [svRegular,svDart] then
   begin
      Sigma:=0;
      for I:=1 to NoFaces do begin
         Face:=FFaces[I-1];
         Index:=Face.FPoints.IndexOf(self);
         PrevIndex:=(index+(Face.FPoints.Count-1)) mod Face.FPoints.Count;
         NextIndex:=(PrevIndex+2) mod Face.FPoints.Count;
         Prev:=Face.FPoints[PrevIndex];
         Next:=Face.FPoints[NextIndex];
         Tmp:=Angle_VV_3D(Prev.Coordinate,Self.Coordinate,Next.Coordinate);
         Sigma:=Sigma+Tmp;
      end;
      Result:=(360-RadToDeg(sigma));
   end;// else Result:=0.0;
end;

function SPoint.FGetFace(Index:Integer):SFace;
   begin Result:=FFaces[Index]; end;
function SPoint.FGetIndex:Integer;
   begin Result:=Owner.FPoints.IndexOf(Self); end;

function SPoint.FGetIsBoundaryVertex:Boolean;
var I:Integer;
begin Result:=False;
   if abs(Coordinate.Y)>1e-4 then for I:=1 to NoEdges
      do Result:=Result or Edge[I-1].IsBoundaryEdge;
end;

function SPoint.FGetNormal:Vector;
var I,J,Index: Integer;
    Face     : SFace;
    P1,P3,C,N: Vector;
begin Result:=ZERO;
   for I:=1 to FFaces.Count do begin
      Face:=FFaces[I-1];
      if Face.Nopoints>4 then begin // Face possibly concave at this point use the normal of ALL points from this face
         C:=Face.FaceCenter;
         N:=ZERO;
         for J:=2 to Face.Nopoints do
            N := N + UnifiedNormal( C,Face.Point[J-2].Coordinate,Face.Point[J-1].Coordinate );
         N:=Normalize(N);
         Result:=Result+N;
      end else begin
         Index:=Face.FPoints.IndexOf(Self);
         J:=(Index+Face.FPoints.Count-1) mod (Face.FPoints.Count);
         P1:=Face.Point[J].Coordinate;
         J:=(Index+Face.FPoints.Count+1) mod (Face.FPoints.Count);
         P3:=Face.Point[J].Coordinate;
         Result:=Result+UnifiedNormal(P1,FCoordinate,P3);
      end;
   end;
   Result:=Normalize(Result);
end;

function SPoint.FGetNoCurves:Integer;
var I:Integer;
begin Result:=0;
      for I:=1 to NoEdges do if Edge[I-1].Curve<>nil then inc(Result);
end;
function SPoint.FGetNoEdges:integer;
   begin Result:=FEdges.Count; end;
function SPoint.FGetNoFaces:integer;
   begin Result:=FFaces.Count; end;

function SPoint.FGetRegularPoint:Boolean;
var I,N : Integer;
begin
   Result:=False;
   // this procedure was only tested to TRACE regular quad edges
   // and regular/irregular CREASE edges for dxf export
   if (NoFaces=5) and (NoEdges=5) then begin // boundary of quad and triangle
      N:=0;
      for I:=1 to NoFaces do if Face[I-1].NoPoints=3 then inc(N);
      if (N=3) then Result:=True;
   end else if (NoFaces=6) and (NoEdges=6) then begin // regular point with all triangles
      N:=0;
      for I:=1 to NoFaces do if Face[I-1].NoPoints=3 then inc(N);
      if (N=6) then Result:=True;
   end else if (NoFaces=4) and (NoEdges=4) then begin // regular point with all quads
      Result:=True;
   end else //if (NoEdges=3) and (NoFaces=2) then
   begin                                          // regular quad boundary edge
      N:=0;
      for I:=1 to NoEdges do if Edge[I-1].NoFaces=1 then inc(N);
      // test for regular point on boundaryedge
      if (N=2) and (NoEdges=3) then Result:=True;
   end;
end;

function SPoint.FGetLimitPoint:Vector;
var I,N,Ind  : Integer;
    P30,P33,P: SPoint;
    Face     : SFace;
    Edge     : SEdge;
begin
   if VertexType in [svDart,svRegular] then begin
      Result:=ZERO;
      N:=NoFaces;
      for I:=1 to NoFaces do begin
         Face:=FFaces[I-1];
         Ind:=Face.IndexOfPoint(self);
         P30:=Face.Point[(Ind+1) mod Face.Nopoints];
         P33:=Face.Point[(Ind+2) mod Face.Nopoints];
         Result+=n*FCoordinate + 4*P30.Coordinate + P33.Coordinate;
      end;
      Result/=n*(N+5);
   end else if VertexType=svCrease then begin
      P30:=nil;
      P33:=nil;
      for I:=1 to NoEdges do begin
         Edge:=FEdges[I-1];
         if Edge.Crease then begin
            if Edge.StartPoint=self then P:=Edge.EndPoint
                                    else P:=Edge.StartPoint;
            if P30=nil then P30:=P
                       else P33:=P;
         end;
      end;
      if (P30<>nil) and (P33<>nil) then begin
         Result:=(1/6)*P30.Coordinate + (2/3)*FCoordinate + (1/6)*P33.Coordinate;
      end else begin
         ShowMessage( Userstring(199)+'!' );
         Result:=FCoordinate;
      end;
   end else Result:=FCoordinate;
end;

function SPoint.IsRegularNURBSPoint(Faces:TFasterList):Boolean;
var I,Ind,N:Integer;
    Boundary:Boolean;
begin
   if VertexType in [svRegular,svdart] then Result:=NoFaces=4 else
   if VertexType in [svCrease] then begin                         //Faces:=nil;
      if Faces<>nil then begin N:=0;
         for I:=1 to NoFaces do begin
            Ind:=Faces.SortedIndexOf(face[I-1]);
            if Ind<>-1 then inc(N);
         end;
         Result:=N=2;
         if (N=2) and (NoFaces<>4) then Result:=true;
      end else begin                                         // boundary edge ?
         Boundary:=False;
         for I:=1 to NoEdges do Boundary:=Boundary or (Edge[I-1].NoFaces=1);
         if Boundary then Result:=NoFaces=2
                     else Result:=NoFaces=4;
      end;
   end else Result:=False;
end;

procedure SPoint.FSetCoordinate(Val:Vector);
    begin FCoordinate:=Val; end;
procedure SPoint.AddEdge(Edge:SEdge);
    begin if FEdges.IndexOf(Edge)=-1 then FEdges.Add(Edge); end;
procedure SPoint.AddFace(Face:SFace);
    begin if FFaces.IndexOf(Face)=-1 then FFaces.Add(Face); end;

function SPoint.Averaging:Vector;
var I,J,Nt,Nq: Integer;
    a,Weight,TotalWeight:Real;
    Center: Vector;
    Face: SFace;
    Edge: SEdge;
    P: SPoint;
begin
   if (Noedges=0)
   or (VertexType=svCorner) then Result:=FCoordinate else begin
      if VertexType=svCrease then begin
         Result:=0.5*FCoordinate;
         for I:=1 to FEdges.Count do begin
            Edge:=FEdges[I-1];
            if (Edge.FFaces.Count=1) or (Edge.FCrease) then begin
               if Edge.Startpoint=self then P:=Edge.Endpoint
                                       else P:=Edge.Startpoint;
               Result+=0.25*P.FCoordinate;
            end;
         end;
      end else begin
         TotalWeight:=0.0;
         Result:=ZERO;
         Nt:=0;
         for I:=1 to FFaces.Count do begin
            Face:=FFaces[I-1];
            Center:=ZERO;
            if Face.Nopoints=3 then begin inc(Nt); // Calculate centerpoint
               for j:=1 to Face.Nopoints do begin
                  P:=Face.FPoints[J-1];
                  if P=self then Weight:=1/4
                            else Weight:=3/8;
                  Center:=Center+Weight*P.FCoordinate;                          // Center.X:=Center.X+Weight*P.FCoordinate.X; Center.Y:=Center.Y+Weight*P.FCoordinate.Y; Center.Z:=Center.Z+Weight*P.FCoordinate.Z;
               end;
               Weight:=Pi/3;
            end else if Face.Nopoints=4 then begin // Calculate centerpoint
               for j:=1 to Face.Nopoints do begin
                  P:=Face.FPoints[J-1];
                  Weight:=1/4;
                  Center:=Center+Weight*P.FCoordinate;                          // Center.X:=Center.X+Weight*P.FCoordinate.X; Center.Y:=Center.Y+Weight*P.FCoordinate.Y; Center.Z:=Center.Z+Weight*P.FCoordinate.Z;
               end;
               Weight:=Pi/2;
            end;                                                                //!! else Raise exception.Create('Invalid number of points in SPoint.Averaging');
            Result:=Result+Weight*Center;                                       // Result.X:=Result.X+Weight*Center.X; Result.Y:=Result.Y+Weight*Center.Y; Result.Z:=Result.Z+Weight*Center.Z;
            TotalWeight:=TotalWeight+Weight;
         end;
         if TotalWeight<>0 then Result:=Result/TotalWeight;                     // begin Result.X:=Result.X/TotalWeight; Result.Y:=Result.Y/TotalWeight; Result.Z:=Result.Z/TotalWeight; end;
         Nq:=FFaces.Count-Nt;
         if Nt=FFaces.Count then begin // apply averaging in case of vertex surrounded by triangles
            a:=5/3-8/3*sqr(3/8+1/4*cos(2*Pi/FFaces.Count));
         end else if Nq=FFaces.Count then begin // apply averaging in case of vertex surrounded by quads
            a:=4/FFaces.Count;
         end else begin  // apply averaging in case of vertex on boundary of quads and triangles
            if (Nq=0) and (Nt=3) then a:=1.5
                                 else a:=12/(3*Nq+2*Nt);
         end;
         if a<>1.0 then Result:=FCoordinate+A*(Result-FCoordinate);             // begin Result.X:=FCoordinate.X+a*(Result.X-FCoordinate.X); Result.Y:=FCoordinate.Y+a*(Result.Y-FCoordinate.Y); Result.Z:=FCoordinate.Z+a*(Result.Z-FCoordinate.Z); end;
      end;
   end;
end;

function SPoint.CalculateVertexPoint:SPoint;
  var Point: Vector; Edge: SEdge; I: Integer;
begin Point:=FCoordinate;
   Result:=SPoint.Create(Owner);
   Result.VertexType:=VertexType;
   Result.FCoordinate:=Point;
   for I:=0 to Fedges.Count-1 do begin Edge:=FEdges[I];
      if Edge.Curve<>nil then Edge.Curve.ReplaceVertexPoint(Self,Result);
   end;
end;

procedure SPoint.Clear;
begin
   FCoordinate:=Zero; // Fillchar(FCoordinate,SizeOf(Vector),0);
   FFaces.Clear;
   FEdges.Clear;
   VertexType:=svRegular;
end;
constructor SPoint.Create(Owner:SSurface);
      begin inherited Create(Owner);
            FFaces:=TFasterList.Create;
            FEdges:=TFasterList.Create; Clear;
      end;
procedure SPoint.DeleteEdge(Edge:SEdge);
      var Index:Integer;
    begin index:=FEdges.IndexOf(Edge);
       if Index<>-1 then FEdges.Delete(Index);
end;
procedure SPoint.DeleteFace(Face:SFace);
      var Index:Integer;
    begin index:=FFaces.IndexOf(Face);
       if Index<>-1 then FFaces.Delete(Index);
    end;
destructor SPoint.Destroy;
begin Clear;
      FFaces.Destroy; FFaces:=nil;
      FEdges.Destroy; Fedges:=nil; inherited Destroy;
end;
function SPoint.IndexOfFace(Face:SFace):Integer;
   begin Result:=FFaces.IndexOf(Face); end;
{
    SControlPoint
}
function SControlPoint.FGetColor:TColor;
begin
   if Selected then Result:=Sp.Select else begin
      if Locked then Result:=clDkGray else begin
         if IsLeak then Result:=Sp.LeakPoint else
         Case VertexType of
            svRegular : Result:=Sp.RegularPoint;
            svCorner  : Result:=Sp.CornerPoint;
            svDart    : result:=Sp.DartPoint;
            svCrease  : result:=Sp.CreasePoint;
            else Result:=clRed;
         end;
      end;
   end;
end;
function SControlPoint.FGetIndex:Integer;
   begin Result:=Owner.FControlPoints.IndexOf(Self); end;
function SControlPoint.FGetIsLeak:boolean;
   begin Result:=(abs(Coordinate.Y)>1e-4) and (IsBoundaryVertex); end;
function SControlPoint.FGetSelected:Boolean;
   begin Result:=Owner.FSelectedControlPoints.IndexOf(self)<>-1; end;

function SControlPoint.FGetVisible:Boolean;
var I: Integer; CFace: SControlFace;
begin
   // meant for controlpoints only.
   // a controlpoint is visible if at least one of it's
   // neighbouring controlfaces belongs to a visible layer
   Result:=False;
   if Owner.ShowControlNet then begin
      for i:=1 to FFaces.Count
      do if Face[I-1] is SControlFace then begin
         CFace:=FFaces[I-1];
         if CFace.Layer<>nil then begin
            if CFace.Layer.Visible then begin Result:=True; exit; end;
         end;
      end;
   end;
   // Finally check if the point is selected.
   // Selected points must be visible at all times
   // Points with no faces connected also!
   if not Result then Result:=(Selected) or (NoFaces=0);
   if (not Result) and (Owner.NoControlCurves>0) then begin
      For I:=1 to NoEdges do if Edge[I-1].Curve<>nil then begin
         if Edge[I-1].Curve.Selected then begin
            Result:=true;
            break;
         end;
      end;
   end;
end;

procedure SControlPoint.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedControlPoints.IndexOf(self);
   if Val then begin               // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedControlPoints.Add(self);
   end else begin
      if Index<>-1 then Owner.FSelectedControlPoints.Delete(index);
   end;
   if Assigned(Owner.OnSelectItem) then Owner.OnSelectItem(self);
end;

procedure SControlPoint.FSetLocked(val:Boolean);
    begin if Val<>FLocked then FLocked:=Val; end;

procedure SControlPoint.FSetCoordinate(Val:Vector);
begin
   if not Locked then begin
      Inherited FSetCoordinate(Val);
      Owner.Build:=False;
   end;
end;

procedure SControlPoint.Collapse;
var I,J: Integer;
    Face: SControlFace;
    Edge1,Edge2: SControlEdge;
    Edges,Points,Sorted,Checklist:TFasterList;
    P1,P2: SControlPoint;
    Crease,EdgeCollapse:Boolean;
begin
   if NoFaces<=2 then begin
      Selected:=False;
      P1:=nil;
      P2:=nil;
   // This is possibly a point on a boundary edge, check for this special case
      Edge1:=nil;
      Edge2:=nil;
      for i:=1 to NoEdges do if Edge[I-1].NoFaces=1 then begin
         if Edge1=nil then Edge1:=Edge[I-1] as SControlEdge else
                           Edge2:=Edge[I-1] as SControlEdge;
      end;
      if (Edge1<>nil) and (Edge2<>nil) then begin
         for I:=NoEdges downto 1 do if Edge[I-1].NoFaces>1 then begin
            Edge1:=Edge[I-1] as SControlEdge;
            Edge1.Collapse;
         end;
      end;
      if NoEdges=2 then begin
         EdgeCollapse:=True;
         Edge1:=FEdges[0];
         if Edge1.Startpoint=self
            then P1:=Edge1.Endpoint as SControlPoint
            else P1:=Edge1.Startpoint as SControlPoint;
         Edge2:=FEdges[1];
         if Edge2.Startpoint=self
            then P2:=Edge2.Endpoint as SControlPoint
            else P2:=Edge2.Startpoint as SControlPoint;
         Crease:=Edge1.Crease or Edge2.Crease;
      end else begin
         Crease:=False;
         EdgeCollapse:=False;
      end;
      for I:=NoFaces downto 1 do begin
         Face:=FFaces[I-1];
         Points:=TFasterList.Create;
         for J:=1 to Face.FPoints.Count do if Face.FPoints[J-1]<>self then Points.Add(Face.FPoints[J-1]);
         Owner.AddControlFace(Points,False,Face.Layer);
         Points.Destroy;
         Face.SelDeleteFace;
      end;
      if EdgeCollapse then begin
         Edge1:=Owner.EdgeExists(P1,P2) as SControlEdge;
         if Edge1<>nil then begin
            Edge1.Crease:=Crease;// or (Edge1.NoFaces=1);
         end;
      end;
   end else begin
      Checklist:=TFasterList.Create;
      Edges:=TFasterList.Create;
      for i:=1 to NoEdges do if Edge[I-1].StartPoint=self then CheckList.Add(Edge[I-1].EndPoint)
                                                                else CheckList.Add(Edge[I-1].StartPoint);
      for I:=1 to NoFaces do begin
         Face:=Ffaces[I-1];
         P1:=Face.FPoints[Face.NoPoints-1];
         for J:=1 to Face.FPoints.Count do begin
            P2:=face.FPoints[J-1];
            if (P1<>self) and (P2<>self) then begin
               Edge1:=Owner.EdgeExists(P1,P2) as SControlEdge;
               if Edge1<>nil then if Edges.IndexOf(Edge1)=-1 then Edges.Add(Edge1);
            end;
            P1:=P2;
         end;
      end;
      // sort edges in correct order and add new face
      if Edges.Count>2 then begin
         Sorted:=TFasterList.Create;
         Owner.IsolateEdges(Edges,Sorted);
         Edges.Destroy;
         for I:=1 to Sorted.Count do begin
            Points:=Sorted[I-1];
            if Points.Count>2 then begin
               Face:=Owner.AddControlFace(Points,False);
               if Face<>nil then begin
                  P1:=Face.FPoints[Face.FPoints.Count-1];
                  for J:=1 to Face.FPoints.Count do begin
                     P2:=face.FPoints[J-1];
                     Edge1:=Owner.EdgeExists(p1,p2) as SControlEdge;
                  {  if edge1<>nil then begin
                       Cur:=Edge.FFaces.IndexOf(self);
                        if Cur=-1 then Edge.Crease:=Edge.NoFaces<2 else
                           Edge.Crease:=Edge.NoFaces<3;
                     end;
                  }  P1:=P2;
                  end;
               end;
            end; Points.Destroy;
         end;   Sorted.Destroy;
      end else Edges.Destroy;
      SelDeletePoint;
      for i:=Checklist.Count downto 1 do begin
         P1:=Checklist[I-1];
         if (P1.NoFaces>1) and (P1.NoEdges=2) then P1.Collapse;
      end;
      checklist.Destroy;
   end;
end;

constructor SControlPoint.Create(Owner:SSurface);
      begin inherited Create(Owner); end;

procedure SControlPoint.SelDeletePoint;
var Index,I:Integer; Edg: SControlEdge;
begin Selected:=False;
   Index:=Owner.FControlPoints.IndexOf( Self );        // delete from selection
   if Index<>-1 then begin
      Owner.FControlPoints.Delete( Index );
      if FEdges<>nil then
         while FEdges.Count>0 do (Edge[0] as SControlEdge).SelDeleteEdge;
      Destroy;
   end;
end;

procedure SControlPoint.Draw(Viewport:TViewport);
var P: TPoint; Pz: TShadePoint; I: Integer; P3D: Vector;
begin
   if Viewport.ViewportMode<>vmWireframe then begin P3D:=FCoordinate;
      if Viewport.ViewType=fvBodyplan then
        if P3D.X<=Owner.MainframeLocation then P3D.Y:=-P3D.Y;
      P:=Viewport.Project(P3D);
      Pz:=Viewport.ProjectToZBuffer(1.002*ZBufferScaleFactor,P3D);
      // Check if the point lies within the viewport's drawingcanvas boundaries
      if (Pz.X>=0) and (Pz.Y>=0)
      and (Pz.X<Viewport.ClientWidth)
      and (Pz.Y<Viewport.ClientHeight) then // Compare to Z buffer to check visibility;
      if Pz.Z>=Viewport.ZBuffer.FBuffer[Pz.Y][Pz.X] then  // yes, the point is visible
      begin
         Viewport.ZBuffer.FBuffer[Pz.Y][Pz.X]:=Pz.Z;
         if Viewport.Canvas.Pen.Width<>1 then Viewport.Canvas.Pen.Width:=1;
         Viewport.PenColor:=Color;
         Viewport.BrushStyle:=bsClear;
         Viewport.PenStyle:=psSolid;
         for I:=1 to Owner.ControlPointSize
           do Viewport.Canvas.Rectangle( Pz.X-I,Pz.Y-I,Pz.X+I,Pz.Y+I );
      end;
   end else with Viewport.Canvas do begin P3D:=FCoordinate;
      if Viewport.ViewType=fvBodyplan then
         if P3D.X<=Owner.MainframeLocation then P3D.Y:=-P3D.Y;
      P:=Viewport.Project(P3D);
      if Pen.Width<>1 then Pen.Width:=1;
      Viewport.PenColor:=Color;
      if Brush.Style<>bsClear then Brush.Style:=bsClear;
      for I:=1 to Owner.ControlPointSize
         do Viewport.Canvas.Rectangle( P.X-I,P.Y-I,P.X+I,P.Y+I );
      if Selected then           // FInitializeCanvas( Viewport,1,Color,Mode );
            Viewport.Canvas.Rectangle( P.X-Owner.ControlPointSize-2,
                                       P.Y-Owner.ControlPointSize-2,
                                       P.X+Owner.ControlPointSize+2,
                                       P.Y+Owner.ControlPointSize+2 );
   end;
end;

function SControlPoint.DistanceToCursor(X,Y:Integer;Viewport:TViewport):Integer;
var Pt: TPoint; P: Vector;
begin                    // Check if cursor position lies within the boundaries
   P:=FCoordinate;
   if (Viewport.ViewType=fvBodyplan)
   and (P.X<=Owner.MainframeLocation) then P.Y:=-P.Y;
   Pt:=Viewport.Project( P );
   if (Pt.X>=0) and (Pt.X<=Viewport.Width)
   and (Pt.Y>=0) and (Pt.Y<=Viewport.Height)
   then Result:=max(abs(Pt.X-X),abs(Pt.Y-Y)) else Result:=10000;
end;

procedure SControlPoint.LoadBinary(Source:TFileBuffer);
var I: Integer; Sel: Boolean;
begin
   Source.LoadVector(FCoordinate);
   Source.LoadInteger(I);
   Vertextype:=TVertexType(I);
   Source.LoadBoolean(Sel);
   if Sel then Selected:=True;
   if Source.Version>=fv198 then Source.LoadBoolean(FLocked);
end;

procedure SControlPoint.LoadFromStream(var LineNr:Integer;Strings:TStringList);
var Str: string; I: Integer; sel: Boolean;
begin Inc(LineNr);                                               // FCoordinate
   Str:=Strings[LineNr];
   FCoordinate:=GetVector(Str);
   if Str<>'' then begin I:=GetInteger(Str);
      Vertextype:=TVertexType(I);
      if Str<>'' then begin Sel:=GetBoolean(Str);
         if Sel then Selected:=True;
      end;                  // TVertexType=(svRegular,svCrease,svDart,svCorner)
   end else Vertextype:=svRegular;
end;

procedure SControlPoint.SaveBinary(Destination:TFileBuffer);
begin
   Destination.Add(FCoordinate);
   Destination.Add(Ord(VertexType));
   Destination.Add(Selected);
  {if Destination.Version>=fv198 then} Destination.Add( Locked );
end;

procedure SControlPoint.SaveToStream( Strings:TStringlist ); Var Str:String;
begin Str:='';
   if Selected then Str:=IntToStr( Ord( VertexType ) )+' 1' else
   if VertexType<>svRegular then Str:=IntToStr( Ord( VertexType ) );
   Strings.Add( FloatToDec( Fcoordinate.X,5 )+#32
              + FloatToDec( Fcoordinate.Y,5 )+#32
              + FloatToDec( Fcoordinate.Z,5 )+#32+Str );
//            + IntToStr( Ord( VertexType ) )+#32 + BoolToStr( Selected ) );
end;
{
   SEdge
}
function SEdge.FGetIndex:Integer;
begin
   Result:=Owner.FEdges.IndexOf(self);
   if result=-1 then begin
      Result:=Owner.FControlEdges.IndexOf(self);
      if Result=-1 then Result:=0;
   end;
end;
function SEdge.FGetIsBoundaryEdge:Boolean;
begin Result:=False;
   if NoFaces=1 then
   Result:=(abs(StartPoint.Coordinate.Y)>1e-4) or (abs(EndPoint.Coordinate.Y)>1e-4);
end;
function SEdge.FGetFace(Index:Integer):SFace;
   begin Result:=FFaces[Index]; end;
function SEdge.FGetNoFaces:Integer;
   begin Result:=FFaces.Count; end;

procedure SEdge.FSetCrease(Val:Boolean);
var I,N: Integer; Edge: SEdge;
begin
   if NoFaces=1 then Val:=True;  // Boundary edges must ALWAYS be crease edges
   if (Val<>FCrease) then begin
      FCrease:=Val;
      N:=0;
      for I:=1 to StartPoint.FEdges.Count do begin
         Edge:=StartPoint.FEdges[I-1];
         if Edge.Crease then Inc(N);
      end;
      if Startpoint.VertexType=svCorner then begin
         if (StartPoint.NoFaces>1) and (N=2) then Startpoint.VertexType:=svCrease;
      end else begin
         if N=0 then Startpoint.VertexType:=svRegular else
          if N=1 then Startpoint.VertexType:=svDart else
           if N=2 then Startpoint.VertexType:=svCrease else
            if N>2 then Startpoint.VertexType:=svCorner;
      end;
      N:=0;
      for I:=1 to EndPoint.FEdges.Count do begin
         Edge:=EndPoint.FEdges[I-1];
         if Edge.Crease then Inc(N);
      end;
      if Endpoint.VertexType=svCorner then begin
         if (EndPoint.NoFaces>1) and (N=2) then Endpoint.VertexType:=svCrease;
      end else begin
         if N=0 then Endpoint.VertexType:=svRegular else
          if N=1 then Endpoint.VertexType:=svDart else
           if N=2 then Endpoint.VertexType:=svCrease else
            if N>2 then Endpoint.VertexType:=svCorner;
      end;
      StartPoint.Owner.Build:=false;
   end;
end;

function SEdge.FGetPreviousEdge:SEdge;
var P          : SPoint;
    Edge       : SEdge;
    I,J,Index  : Integer;
    Sharesface : Boolean;
begin
   P:=Startpoint;
   Result:=nil;
   if (P.RegularPoint) and (P.VertexType<>svCorner) then begin // Find previous edge
      for I:=1 to P.NoEdges do if P.Edge[I-1]<>self then begin
         Edge:=P.Edge[I-1];
         if Edge.Crease=self.Crease then begin
            SharesFace:=False;
            for J:=1 to self.NoFaces do begin
               Index:=Edge.FFaces.IndexOf(self.Face[J-1]);
               if Index<>-1 then begin
                  SharesFace:=True;
                  Break;
               end;
            end;
            if not SharesFace then begin
               if Edge.StartPoint=self.StartPoint then Edge.SwapData;
               Result:=Edge;
               exit;
            end;
         end;
      end;
   end;
end;

function SEdge.FGetNextEdge:SEdge;
var P          : SPoint;
    Edge       : SEdge;
    I,J,Index  : Integer;
    Sharesface : Boolean;
begin
   P:=Endpoint;
   Result:=nil;
   if (P.RegularPoint) and (P.VertexType<>svCorner) then begin // Find Next edge
      for I:=1 to P.NoEdges do if P.Edge[I-1]<>self then begin
         Edge:=P.Edge[I-1];
         if Edge.Crease=self.Crease then begin
            SharesFace:=False;
            for J:=1 to self.NoFaces do begin
               Index:=Edge.FFaces.IndexOf(self.Face[J-1]);
               if Index<>-1 then begin
                  SharesFace:=True;
                  Break;
               end;
            end;
            if not SharesFace then begin
               if Edge.StartPoint=self.StartPoint then Edge.SwapData;
               Result:=Edge;
               exit;
            end;
         end;
      end;
   end;
end;

procedure SEdge.AddFace(Face:SFace);
begin
   if FFaces.IndexOf(Face)=-1 then FFaces.Add(Face);
end;
procedure SEdge.Assign(Edge:SEdge);
begin
   FCrease:=Edge.FCrease;
   FControlEdge:=Edge.FControlEdge;
end;
function SEdge.CalculateEdgePoint:SPoint;
var Point: Vector;
begin
   Point:=0.5*(Startpoint.FCoordinate+Endpoint.FCoordinate);
   Result:=SPoint.Create(StartPoint.Owner);
   if FCrease then Result.VertexType:=svCrease;
   if Curve<>nil then Curve.InsertEdgePoint(StartPoint,EndPoint,Result);
   Result.FCoordinate:=Point;
end;

procedure SEdge.Clear;
begin
   Startpoint:=nil;
   Endpoint:=nil;
   Curve:=nil;
   FFaces.Clear;
   FCrease:=False;
   FControlEdge:=False;
end;

procedure SEdge.SwapData; var Tmp:SPoint;
    begin Tmp:=Startpoint; Startpoint:=Endpoint; Endpoint:=Tmp;
    end;

constructor SEdge.Create(Owner:SSurface);
begin
   Inherited Create(Owner);
   FFaces:=TFasterList.Create;
   clear;
end;

procedure SEdge.DeleteFace(Face:SFace);
var Index:Integer;
begin Index:=FFaces.IndexOf(Face);
   if Index<>-1 then begin FFaces.Delete(Index);
      if FFaces.Count=1 then Crease:=true else
         if FFaces.Count=0 then Crease:=False;
   end;
end;

destructor SEdge.Destroy;
     begin {if self=nil then exit;} Clear;
           FFaces.Destroy; FFaces:=nil;
           Inherited Destroy;
     end;
destructor SControlEdge.Destroy; begin Inherited Destroy; end;

function SEdge.DistanceToCursor(X,Y:Integer;var P:Vector;Viewport:TViewport):integer;
var Pt1,Pt2: TPoint;
    P1,P2,M: Vector;
    Param: Real;
    Tmp: Integer;
begin
   P:=ZERO;              // Check if cursor position lies within the boundaries
   Result:=10000;
   if Viewport.ViewType=fvBodyplan then begin
      P1:=StartPoint.FCoordinate;
      P2:=EndPoint.FCoordinate;
      if ((P1.X<Owner.MainframeLocation) and (P2.X>Owner.MainframeLocation))
      or ((P1.X>Owner.MainframeLocation) and (P2.X<Owner.MainframeLocation))
      then begin
         if P2.X-P1.X<>0 then M:=Interpolate(P1,P2,(Owner.MainframeLocation-P1.X)/(P2.X-P1.X))
                         else M:=MidPoint(P1,P2);
         if P1.X<=Owner.MainframeLocation then begin         // P2 lies on port
            Pt1:=Viewport.Project(P2);
            Pt2:=Viewport.Project(M);
            Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
            if Tmp<Result then begin
               Result:=Tmp;
               P:=Interpolate(P2,M,Param);
            end;                                        // P1 lies on starboard
            P1.Y:=-P1.Y;
            M.Y:=-M.Y;
            Pt1:=Viewport.Project(P1);
            Pt2:=Viewport.Project(M);
            Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
            if Tmp<Result then begin
               Result:=Tmp;
               P:=Interpolate(P1,M,Param);
            end;
         end else begin                                      // P1 lies on port
            Pt1:=Viewport.Project(P1);
            Pt2:=Viewport.Project(M);
            Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
            if Tmp<Result then begin
               Result:=Tmp;
               P:=Interpolate(P1,M,Param);
            end;                                        // P2 lies on starboard
            P2.Y:=-P2.Y;
            M.Y:=-M.Y;
            Pt1:=Viewport.Project(P2);
            Pt2:=Viewport.Project(M);
            Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
            if Tmp<Result then begin
               Result:=Tmp;
               P:=Interpolate(P2,M,Param);
            end;
         end;
      end else begin
         if P1.X<=Owner.MainframeLocation then P1.Y:=-P1.Y;
         if P2.X<=Owner.MainframeLocation then P2.Y:=-P2.Y;
         Pt1:=Viewport.Project(P1);
         Pt2:=Viewport.Project(P2);
         Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
         if Tmp<Result then begin
            Result:=Tmp;
            P:=Interpolate(P1,P2,Param);
         end;
      end;
   end else begin
//    Pt.X:=X;
//    Pt.Y:=Y;
      Pt1:=Viewport.Project(StartPoint.Coordinate);
      Pt2:=Viewport.Project(EndPoint.Coordinate);
      Result:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
      P:=Interpolate(StartPoint.Coordinate,EndPoint.Coordinate,Param);
   end;
end;

procedure SEdge.Draw(DrawMirror:Boolean;Viewport:TViewport);
var P1,P2,M : Vector;
    Pt1,Pt2 : TPoint;
begin
   P1:=StartPoint.FCoordinate;
   P2:=EndPoint.FCoordinate;
   if (DrawMirror=false) and (Viewport.ViewType=fvBodyplan) then begin
      if ((P1.X<Owner.MainframeLocation)
      and (P2.X>Owner.MainframeLocation))
      or ((P1.X>Owner.MainframeLocation)
      and (P2.X<Owner.MainframeLocation)) then begin
         if P2.X-P1.X<>0 then M:=Interpolate(P1,P2,(Owner.MainframeLocation-P1.X)/(P2.X-P1.X))
                         else M:=MidPoint(P1,P2);
         if P1.X<=Owner.MainframeLocation then begin         // P2 lies on port
            Pt1:=Viewport.Project(P2);
            Pt2:=Viewport.Project(M);
            Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
            Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);        // P1 lies on starboard
            P1.Y:=-P1.Y;
            M.Y:=-M.Y;
            Pt1:=Viewport.Project(P1);
            Pt2:=Viewport.Project(M);
            Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
            Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
         end else begin                                     // P1 lies on port
            Pt1:=Viewport.Project(P1);
            Pt2:=Viewport.Project(M);
            Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
            Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);        // P2 lies on starboard
            P2.Y:=-P2.Y;
            M.Y:=-M.Y;
            Pt1:=Viewport.Project(P2);
            Pt2:=Viewport.Project(M);
            Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
            Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
         end;
      end else begin
         if P1.X<=Owner.MainframeLocation then P1.Y:=-P1.Y;
         if P2.X<=Owner.MainframeLocation then P2.Y:=-P2.Y;
         Pt1:=Viewport.Project(P1);
         Pt2:=Viewport.Project(P2);
         Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
         Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
      end;
   end else begin
      Pt1:=Viewport.Project(P1);
      Pt2:=Viewport.Project(P2);
      Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
      Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
      if DrawMirror then begin
         P1.Y:=-P1.Y; Pt1:=Viewport.Project(P1);
         P2.Y:=-P2.Y; Pt2:=Viewport.Project(P2);
         Viewport.Canvas.MoveTo( Pt1.X,Pt1.Y );
         Viewport.Canvas.LineTo( Pt2.X,Pt2.Y );
      end;
   end;
end;
{
   SControlEdge
}
function SControlEdge.FGetColor:TColor;
begin
   if Selected then Result:=Sp.Select else
     if NoFaces>2 then Result:=clLime else
       if Crease then Result:=Sp.CreaseEdge else
          Result:=Sp.Edge;
end;

function SControlEdge.FGetIndex:Integer;
   begin Result:=Owner.FControlEdges.IndexOf(self); end;

function SControlEdge.FGetIsBoundaryEdge:Boolean;
var I,N  : Integer;
    Face : SControlface;
begin N:=0;
   for I:=1 to NoFaces do begin
      Face:=FFaces[I-1];
      if Face.Layer.UseInHydrostatics then inc(N);
   end;
   if N=1 then Result:=(abs(StartPoint.Coordinate.Y)>1e-4) or (abs(EndPoint.Coordinate.Y)>1e-4)
          else Result:=false;
end;

procedure SControlEdge.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedControlEdges.IndexOf(self);
   if Val then begin               // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedControlEdges.Add(self);
   end else begin
      if Index<>-1 then Owner.FSelectedControlEdges.Delete(index);
   end;
   if Assigned(Owner.OnSelectItem) then Owner.OnSelectItem(self);
end;

function SControlEdge.FGetSelected:Boolean;
   begin Result:=Owner.FSelectedControlEdges.IndexOf(self)<>-1; end;

function SControlEdge.FGetVisible:Boolean;
var I: Integer; CFace: SControlFace;
begin  // meant for controledges only. a controledge is visible if at least one
   Result:=False; // of it's neighbouring controlfaces belongs to visible layer
   if Owner.ShowControlNet then
   for I:=1 to FFaces.Count do
   if Face[I-1] is SControlFace then begin CFace:=FFaces[I-1];
      if CFace.Layer<>nil then
      if CFace.Layer.Visible then begin Result:=True; exit; end;
   end;                           // Finally check if the edge is selected.
                                 // Selected edges must be visible at all times
   if not Result then Result:=Selected;
   if (not Result) and (Curve<>nil) then Result:=Curve.Selected;
end;

procedure SControlEdge.Collapse;
var Face1,Face2,NewFace: SControlFace; Edge: SEdge; P1,P2: SPoint;
    S,E: SControlPoint;
    Layer: SLayer;
    I,Ind1,Ind2,Ind3,Ind4: Integer;
    procedure Swap( var I1,I2:Integer );
          var Tmp:Integer; begin Tmp:=I1; I1:=I2; I2:=Tmp; end;
begin
   if NoFaces=2 then
   if (Face[0] is SControlFace)
   and (Face[1] is SControlFace) then begin
      if (StartPoint.NoEdges>2) and (EndPoint.NoEdges>2) then begin
         if Curve<>nil then Curve.DeleteEdge(self);
         if selected then Selected:=False;
         S:=Startpoint as SControlPoint;
         E:=Endpoint as SControlPoint;
         Owner.Build:=False;
         Face1:=Face[0] as SControlFace;
         Face2:=Face[1] as SControlFace;
         // Check faces for consistent ordering of the points (same normal direction)
         // because inconsistent ordering can lead to access violations
         P1:=Face1.Point[Face1.NoPoints-1];
         for I:=1 to Face1.NoPoints do begin
            P2:=Face1.Point[I-1];
            if ((P1=StartPoint) and (P2=Endpoint))
            or ((P2=StartPoint) and (P1=Endpoint)) then begin
               Ind1:=Face2.IndexOfPoint(P2);
               Ind2:=(Ind1+1) mod Face2.NoPoints;// select the next index
               if Face2.Point[ind2]=P1 then begin// Direction is OK, do nothing
               end else begin             // direction is not ok, invert points
                  Face2.FlipNormal;
               end;
               break;
            end else P1:=P2;
         end;
         Layer:=Face1.Layer;
         // Remove the controlfaces from the layers which they belong to
         Face1.Layer.DeleteControlFace(Face1);
         Face2.Layer.DeleteControlFace(Face2);
         Ind1:=Face1.FPoints.IndexOf(StartPoint);
         Ind2:=Face1.FPoints.IndexOf(EndPoint);
         if (Ind2<Ind1) and (abs(Ind2-Ind1)=1) then Swap(Ind1,Ind2);
         Ind3:=Face2.FPoints.IndexOf(StartPoint);
         Ind4:=Face2.FPoints.IndexOf(EndPoint);
         if (Ind4<Ind3) and (abs(Ind4-Ind3)=1) then Swap(Ind3,Ind4);
         if (Ind1=0) and (Ind2=Face1.Nopoints-1)
         and (Ind3=0) and (Ind4=Face2.Nopoints-1) then begin
            Swap(Ind1,Ind2);
            Swap(Ind3,Ind4);
         end;
         if (Ind1=0) and (Ind2=Face1.Nopoints-1) then Swap(Ind1,Ind2);
         if (Ind3=0) and (Ind4=Face2.Nopoints-1) then Swap(Ind3,Ind4);
         // Remove all references to Face1
         for I:=1 to Face1.Nopoints do Face1.Point[I-1].DeleteFace(Face1);
         // Remove all references to Face2
         for I:=1 to Face2.Nopoints do Face2.Point[I-1].DeleteFace(Face2);
         // Add the new face                                        f
         NewFace:=SControlFace.Create( Owner );
         NewFace.FLayer:=layer;
         Owner.FControlFaces.Add(NewFace);
         for I:=0 to Ind1 do
          if NewFace.FPoints.IndexOf(Face1.Point[I])=-1 then
             NewFace.AddPoint(Face1.Point[I]);
         for I:=Ind4 to Face2.Nopoints-1 do
          if NewFace.FPoints.IndexOf(Face2.Point[I])=-1 then
             NewFace.AddPoint(Face2.Point[I]);
         for I:=0 to Ind3 do
          if NewFace.FPoints.IndexOf(Face2.Point[I])=-1 then
             NewFace.AddPoint(Face2.Point[I]);
         for I:=Ind2 to Face1.Nopoints-1 do
          if NewFace.FPoints.IndexOf(Face1.Point[I])=-1 then
             NewFace.AddPoint(Face1.Point[I]);
         // Check if all appropriate points are added
         if Newface.Nopoints<>Face1.Nopoints+Face2.Nopoints-2 then
            ShowMessage(Userstring(200)+#32+IntToStr(self.EdgeIndex));

         P1:=NewFace.Point[Newface.NoPoints-1];
         for I:=1 to Newface.NoPoints do begin
            P2:=NewFace.Point[I-1];
            Edge:=Owner.EdgeExists(P1,P2);
            if Edge<>nil then begin
               Ind1:=Edge.FFaces.IndexOf(Face1);
               if Ind1<>-1 then Edge.FFaces.Delete(Ind1);
               Ind1:=Edge.FFaces.IndexOf(Face2);
               if Ind1<>-1 then Edge.FFaces.Delete(Ind1);
               Edge.AddFace(NewFace);
               if Edge.NoFaces<2 then Edge.Crease:=True;
            end;
            P1:=p2;
         end;                                // connect the new face to a layer
         Layer.AddControlFace(NewFace);
         if Crease then Crease:=false;
         StartPoint.DeleteEdge(self);
         Endpoint.DeleteEdge(self);
         Ind1:=Owner.FControlEdges.IndexOf(self);
         if Ind1<>-1 then Owner.FControlEdges.Delete(Ind1);
         Ind1:=Owner.FControlFaces.IndexOf(Face1);
         if Ind1<>-1 then Owner.FControlFaces.Delete(Ind1);
         Ind1:=Owner.FControlFaces.IndexOf(Face2);
         if Ind1<>-1 then Owner.FControlFaces.Delete(Ind1);
         Face1.Destroy;
         Face2.Destroy; // check if startpoint and endpoint can be collapsed aswell
         if (S.NoFaces>1) and (S.NoEdges=2) then S.Collapse;
         if (E.NoFaces>1) and (E.NoEdges=2) then E.Collapse;
         Owner.Build:=False;
         Destroy;
      end;
   end;
end;

constructor SControlEdge.Create( Owner:SSurface );
      begin Inherited Create( Owner ); end;

procedure SControlEdge.SelDeleteEdge;
var I: Integer;
begin  Selected:=False;                                // delete from selection
   if Curve<>nil then Curve.DeleteEdge( self );
        I:=Owner.FControlEdges.IndexOf( self );
   if I<>-1 then begin Owner.FControlEdges.Delete( I );
      for I:=FFaces.Count-1 downto 0 do
        (Face[I] as SControlFace).selDeleteFace;
      EndPoint.DeleteEdge(self);  // Remove endpoint from startpoint neighbours
      if EndPoint.NoEdges=0 then
        (Endpoint as SControlPoint).selDeletePoint;
      StartPoint.DeleteEdge(self);// Remove startpoint from endpoint neighbours
      if StartPoint.NoEdges=0 then
        (StartPoint as SControlPoint).selDeletePoint;
      Destroy;
   end;
end;

function SControlEdge.DistanceToCursor
  ( X,Y:Integer; var P:Vector; Viewport:TViewport ):Integer;
var Pt1,Pt2: TPoint; P1,P2,M: Vector; Param: Real; Tmp: Integer;
begin                    // Check if cursor position lies within the boundaries
   P:=Zero;
   Result:=10000;
   if Viewport.ViewType=fvBodyplan then begin
      P1:=StartPoint.FCoordinate;
      P2:=EndPoint.FCoordinate;
      if(((P1.X<Owner.MainframeLocation) and (P2.X>Owner.MainframeLocation))
      or ((P1.X>Owner.MainframeLocation) and (P2.X<Owner.MainframeLocation)))
       and (not Owner.DrawMirror) then begin
         if P2.X-P1.X<>0
          then M:=Interpolate(P1,P2,(Owner.MainframeLocation-P1.X)/(P2.X-P1.X))
           else M:=MidPoint(P1,P2);
         if P1.X<=Owner.MainframeLocation then begin        // P2 lies on port
            Pt1:=Viewport.Project(P2);
            Pt2:=Viewport.Project(M);
            Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
            if Tmp<Result then begin Result:=Tmp; P:=Interpolate(P2,M,Param); end;
            P1.Y:=-P1.Y;                                // P1 lies on starboard
            M.Y:=-M.Y;
            Pt1:=Viewport.Project(P1);
            Pt2:=Viewport.Project(M);
            Tmp:=Round( DistanceToLine( Pt1,Pt2,X,Y,Param ) );
            if Tmp<Result then begin Result:=Tmp; P:=Interpolate(P1,M,Param); end;
         end else begin                                      // P1 lies on port
            Pt1:=Viewport.Project(P1);
            Pt2:=Viewport.Project(M);
            Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
            if Tmp<Result then begin Result:=Tmp; P:=Interpolate(P1,M,Param); end;
            P2.Y:=-P2.Y;                                // P2 lies on starboard
            M.Y:=-M.Y;
            Pt1:=Viewport.Project(P2);
            Pt2:=Viewport.Project(M);
            Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
            if Tmp<Result then begin Result:=Tmp; P:=Interpolate(P2,M,Param); end;
         end;
      end else begin
         if P1.X<=Owner.MainframeLocation then P1.Y:=-P1.Y;
         if P2.X<=Owner.MainframeLocation then P2.Y:=-P2.Y;
         Pt1:=Viewport.Project(P1);
         Pt2:=Viewport.Project(P2);
         Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
         if Tmp<Result then begin Result:=Tmp; P:=Interpolate(P1,P2,Param); end;
      end;
   end else begin
//    Pt.X:=X;
//    Pt.Y:=Y;
      Pt1:=Viewport.Project(StartPoint.Coordinate);
      Pt2:=Viewport.Project(EndPoint.Coordinate);
      Result:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
      P:=Interpolate(StartPoint.Coordinate,EndPoint.Coordinate,Param);
   end;
end;

procedure SControlEdge.Draw( DrawMirror:Boolean; Viewport:TViewport );
var P1,P2,M: Vector; Pt1,Pt2: TPoint;
begin
   if Visible then begin
      P1:=StartPoint.FCoordinate;
      P2:=EndPoint.FCoordinate;
      if Viewport.ViewportMode<>vmWireframe then begin
         Viewport.DrawLineToZBuffer(P1,P2,GetRValue(Color),GetGValue(Color),GetBValue(Color));
      end else begin
         Viewport.PenColor:=(Color);
         if Crease then Viewport.SetPenWidth(2) else
                        Viewport.SetPenWidth(1);
         if Viewport.ViewType=fvBodyplan then begin
            if ((P1.X<Owner.MainframeLocation) and (P2.X>Owner.MainframeLocation))
            or ((P1.X>Owner.MainframeLocation) and (P2.X<Owner.MainframeLocation))
            then begin
               if P2.X-P1.X<>0 then M:=Interpolate(P1,P2,(Owner.MainframeLocation-P1.X)/(P2.X-P1.X))
                               else M:=MidPoint(P1,P2);
               if P1.X<=Owner.MainframeLocation then begin   // P2 lies on port
                  Pt1:=Viewport.Project(P2);
                  Pt2:=Viewport.Project(M);
                  Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                  Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);  // P1 lies on starboard
                  P1.Y:=-P1.Y;
                  M.Y:=-M.Y;
                  Pt1:=Viewport.Project(P1);
                  Pt2:=Viewport.Project(M);
                  Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                  Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
               end else begin                                // P1 lies on port
                  Pt1:=Viewport.Project(P1);
                  Pt2:=Viewport.Project(M);
                  Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                  Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);  // P2 lies on starboard
                  P2.Y:=-P2.Y;
                  M.Y:=-M.Y;
                  Pt1:=Viewport.Project(P2);
                  Pt2:=Viewport.Project(M);
                  Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                  Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
               end;
            end else begin
               if P1.X<=Owner.MainframeLocation then P1.Y:=-P1.Y;
               if P2.X<=Owner.MainframeLocation then P2.Y:=-P2.Y;
               Pt1:=Viewport.Project(P1);
               Pt2:=Viewport.Project(P2);
               Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
               Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
            end;
         end else begin
            Pt1:=Viewport.Project(P1);
            Pt2:=Viewport.Project(P2);
            Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
            Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
         end;
      end;
   end;
end;

function SControlEdge.InsertControlPoint(P:Vector):SControlpoint;
var I,I1,I2: Integer;
    Face: SFace;
    Edge: SControlEdge;
begin
   Result:=SControlpoint.Create(Owner);
   Result.FCoordinate:=P;
   if Curve<>nil then begin        // insert the new point in the controlcurve
      Curve.InsertControlPoint(SControlPoint(StartPoint),
                               SControlPoint(EndPoint),Result);
   end;
   Owner.FControlPoints.Add(Result);
   for I:=1 to NoFaces do begin
      Face:=FFaces[I-1];
      I1:=Face.FPoints.IndexOf(StartPoint);
      I2:=Face.FPoints.IndexOf(EndPoint);
      if (I1<>-1) and (I2<>-1) then begin
         if (I2=I1+1) then Face.FPoints.Insert(I2,Result) else
         if (I1=I2+1) then Face.FPoints.Insert(I1,Result) else
         if (I1=0) and (I2=Face.FPoints.Count-1) then Face.FPoints.Insert(0,Result) else
         if (I2=0) and (I1=Face.FPoints.Count-1) then Face.FPoints.Insert(0,Result);
         Result.AddFace(Face);
      end;
   end;
   Endpoint.DeleteEdge(self);
   Edge:=Owner.AddControlEdge(Result,EndPoint);
   Edge.FCrease:=FCrease;
   Edge.Curve:=Curve;
   if FCrease then Result.VertexType:=svCrease;
   for I:=1 to Nofaces do Edge.AddFace(FFaces[I-1]);
   EndPoint:=Result;
   Result.AddEdge(self);
end;

procedure SControlEdge.LoadBinary(Source:TFileBuffer);
var Index: Integer; Sel: Boolean;
begin                                                        // Read startpoint
   Source.LoadInteger(Index);
   if Index=-1 then Index:=0;
   if Index<>-1 then begin StartPoint:=Owner.FControlPoints[Index];
                           StartPoint.FEdges.Add(Self); end;  // Read endpoint
   Source.LoadInteger(Index);
   if Index=-1 then Index:=0;
   if Index<>-1 then begin EndPoint:=Owner.FControlPoints[Index];
                           EndPoint.FEdges.Add(Self); end;
   Source.LoadBoolean(FCrease);
   Source.LoadBoolean(Sel);
   if Sel then selected:=True;
end;

procedure SControlEdge.LoadFromStream(var LineNr:Integer;Strings:TStringList);
var Str:string;
    Index:Integer;
    Sel:Boolean;
begin
   Inc(LineNr);
   Str:=Strings[LineNr];                                         // FStartpoint
   Index:=GetInteger(Str);
   if index=-1 then index:=0;
// if Index<>-1 then begin
      StartPoint:=Owner.FControlPoints[Index];
      StartPoint.FEdges.Add(Self);
// end;                                                            // FEndpoint
   Index:=GetInteger(Str);
   if index=-1 then index:=0;
// if Index<>-1 then begin
      EndPoint:=Owner.FControlPoints[Index];
      EndPoint.FEdges.Add(Self);
// end;                                                              // FCrease
   FCrease:=GetInteger(Str)=1;
   if Str<>'' then begin // Flag to indicate that this edge was selected when the model was saved (for undo-purposes)
      Sel:=GetBoolean(Str);
      Selected:=Sel;
   end;
end;
procedure SControlEdge.SaveBinary(Destination:TFileBuffer);
begin
   Destination.Add(Owner.FControlPoints.SortedIndexOf(Startpoint));
   Destination.Add(Owner.FControlPoints.SortedIndexOf(Endpoint));
   Destination.Add(FCrease);
   Destination.Add(Selected);
end;
procedure SControlEdge.SaveToStream(Strings:TStringlist); Var Str: String;
begin
   if Selected then Str:=' 1' else Str:='';
   Strings.Add(IntToStr(Owner.FControlPoints.SortedIndexOf(Startpoint))+#32+
               IntToStr(Owner.FControlPoints.SortedIndexOf(Endpoint))+#32+
               IntToStr(Ord(FCrease))+Str ); // #32+BoolToStr(Selected));
end;
procedure SControlEdge.Trace;
var P          : SControlPoint;
    Edge       : SControlEdge;
    I,J,Index  : Integer;
    Sharesface : Boolean;
begin
   P:=Startpoint as SControlPoint;
   if (P.RegularPoint) and (P.VertexType<>svCorner) then begin // Find next edge
      for I:=1 to P.NoEdges do if P.Edge[I-1]<>self then begin
         Edge:=P.Edge[I-1] as SControlEdge;
         if (Edge.Selected<>self.Selected)
         and (Edge.Crease=self.Crease) then begin
            SharesFace:=False;
            for J:=1 to self.NoFaces do begin
               Index:=Edge.FFaces.IndexOf(self.Face[J-1]);
               if Index<>-1 then begin
                  SharesFace:=True;
                  Break;
               end;
            end;
            if not SharesFace then begin
               if Edge.StartPoint=self.StartPoint then Edge.SwapData;
               Edge.Selected:=self.Selected;
               Edge.Trace;
               Break;
            end;
         end;
      end;
   end;
   P:=Endpoint as SControlPoint;
   if (P.RegularPoint) and (P.VertexType<>svCorner) then begin // Find next edge
      for I:=1 to P.NoEdges do if P.Edge[I-1]<>self then begin
         Edge:=P.Edge[I-1] as SControlEdge;
         SharesFace:=False;
         if (Edge.Selected<>self.Selected)
         and (Edge.Crease=self.Crease) then begin
            for J:=1 to self.NoFaces do begin
               Index:=Edge.FFaces.IndexOf(self.Face[J-1]);
               if Index<>-1 then begin
                  SharesFace:=True;
                  Break;
               end;
            end;
            if not SharesFace then begin
               if Edge.Endpoint=self.EndPoint then Edge.SwapData;
               Edge.Selected:=self.Selected;
               Edge.Trace;
               Break;
            end;
         end;
      end;
   end;
end;
{
   SFace
}
function SFace.FGetArea:Real;
var I:Integer;
    function TriangleArea( P1,P2,P3:Vector ): Real;
       begin Result:=0.5*Abs( (P1-P3)*(P2-P3) ); end;
begin Result:=0.0;
      for I:=3 to NoPoints do
      Result:=Result+TriangleArea(Point[0].Coordinate,Point[I-2].Coordinate,Point[I-1].Coordinate);
end;

function SFace.FGetFaceCenter:Vector;
var I: Integer; P: SPoint;
begin Result:=ZERO;
   if FPoints.Count>1 then begin
      for I:=1 to FPoints.Count do begin
           P:=FPoints[I-1];
           Result:=Result+P.FCoordinate;
      end; Result:=Result/FPoints.Count;
   end;
end;

function SFace.FGetNoPoints: Integer;
   begin Result:=FPoints.Count; end;
function SFace.FGetPoint(Index:Integer):SPoint;
   begin Result:=FPoints[Index]; end;
procedure SFace.AddPoint(Point:SPoint);
    begin FPoints.Add(Point); Point.AddFace(self); end;

function SFace.FGetFaceNormal:Vector;
var I: Integer;
    N,C,P: Vector;
    P1,P2: SPoint;
begin
   Result:=ZERO;
   C:=ZERO;                                      //calculate center of the face
   for I:=1 to NoPoints do begin
      P:=Point[I-1].Coordinate;
      C:=C+P;
   end;
   C:=C/NoPoints;                         // calculate normal
   P1:=Point[NoPoints-1];
   for I:=1 to NoPoints do begin
      P2:=Point[I-1];
      N:=UnifiedNormal(C,P1.Coordinate,P2.Coordinate);
      Result:=Result+N;
      P1:=P2;
   end;
   Result:=Normalize( Result );
end;

function SFace.CalculateFacePoint:SPoint;
var I: Integer;
    P,Centre:Vector;
begin
   Result:=nil;
   Centre:=ZERO;
   if (FPoints.Count>3)
   or (Owner.FSubdivisionMode=fmCatmullClark) then begin
      if FPoints.Count>0 then begin
         for I:=1 to FPoints.Count do begin
            P:=Point[I-1].FCoordinate;
            Centre.X:=Centre.X+P.X;
            Centre.Y:=Centre.Y+P.Y;
            Centre.Z:=Centre.Z+P.Z;
         end;
         Centre.X:=Centre.X/FPoints.Count;
         Centre.Y:=Centre.Y/FPoints.Count;
         Centre.Z:=Centre.Z/FPoints.Count;
      end;
      Result:=SPoint.Create(Owner);
      Result.FCoordinate:=Centre;
   end else if FPoints.Count=3 then Result:=nil;
end;

procedure SFace.Clear;
    begin FPoints.Clear; end;
constructor SFace.Create(Owner:SSurface);
begin
   FPoints:=TFasterlist.Create;
   inherited Create(Owner);
   Clear;
end;
destructor SFace.Destroy;
begin
   Clear;
   inherited Destroy;
   FPoints.Destroy;
end;

// Inverts the point ordering of the face
procedure SFace.FlipNormal;
var Mid,I: INteger;
begin
   Mid:=(FPoints.Count div 2) - 1;
   for I:=0 to Mid do begin FPoints.Exchange(I,FPoints.Count-I-1); end;
end;
function SFace.IndexOfPoint(P:SPoint):Integer;
   begin Result:=FPoints.IndexOf(P); end;

procedure SFace.Subdivide
( Owner:SSurface; ControlFace:Boolean;
  VertexPoints,EdgePoints,FacePoints,InteriorEdges,ControlEdges,Dest:TFasterList );
var NewFace: SFace;
    Index,J,I,TmpIndex: Integer;
    Pts: array[0..3] of SPoint;
    PrevEdge,CurrEdge: SEdge;
    P2,PrevEdgePoint,CurrEdgePoint,P2Point,NewLocation: SPoint;
   procedure EdgeCheck
    ( P1,P2:SPoint; Crease,Controledge:Boolean; Curve:SControlCurve );
    var NewEdge: SEdge;
    begin NewEdge:=nil;
      if (P1<>nil) and (P2<>nil) then begin
          NewEdge:=Owner.EdgeExists( P1,P2 );
          if NewEdge=nil then begin
             NewEdge:=SEdge.Create(Owner);
             NewEdge.Startpoint:=P1;
             NewEdge.Endpoint:=P2;
             NewEdge.FFaces.Capacity:=2;
             NewEdge.Startpoint.FEdges.Add( NewEdge );
             NewEdge.Endpoint.FEdges.Add( NewEdge );
             NewEdge.FControlEdge:=ControlEdge;
             NewEdge.FCrease:=Crease;
             if NewEdge.FControlEdge then ControlEdges.Add( NewEdge )
                                     else InteriorEdges.Add( NewEdge );
          end else
          if NewEdge.FControlEdge then ControlEdges.Add( NewEdge );
          if NewEdge.FControlEdge then NewEdge.Curve:=Curve;
       end else Showmessage( 'Error in SFace.Subdivide' );
       NewEdge.FFaces.Add( NewFace );
    end;
begin
   if (NoPoints<>3) or (Owner.FSubdivisionMode=fmCatmullClark) then begin
      for I:=1 to FPoints.Count do begin P2:=FPoints[I-1];
         Index:=(I-2+FPoints.Count) mod FPoints.Count;
         PrevEdge:=Owner.EdgeExists(P2,FPoints[Index]); if PrevEdge=nil then exit;
         Index:=(I+FPoints.Count) mod FPoints.Count;
         CurrEdge:=Owner.EdgeExists(P2,FPoints[Index]); if CurrEdge=nil then exit;
         Index:=(I-1) mod 4;
         TmpIndex:=VertexPoints.SortedIndexOf(P2);
         Pts[Index]:=VertexPoints.Objects[TmpIndex];  // P2.FNewLocation;
         P2Point:=Pts[Index];
         Index:=(Index+1) mod 4;
         TmpIndex:=EdgePoints.SortedIndexOf(CurrEdge);
         Pts[index]:=EdgePoints.Objects[TmpIndex];    // CurrEdge.FNewLocation;
         CurrEdgePoint:=Pts[index];
         Index:=(Index+1) mod 4;
         TmpIndex:=FacePoints.SortedIndexOf(self);
         Pts[index]:=FacePoints.Objects[TmpIndex];    // self.FNewLocation;
         NewLocation:=Pts[index];
         Index:=(Index+1) mod 4;
         TmpIndex:=EdgePoints.SortedIndexOf(PrevEdge);
         Pts[index]:=Edgepoints.Objects[TmpIndex];    // PrevEdge.FNewLocation;
         PrevEdgePoint:=Pts[index];
         NewFace:=SFace.Create(Owner);                // add the new face
         Dest.Add(NewFace);
         EdgeCheck(PrevEdgePoint,P2Point,PrevEdge.Crease,PrevEdge.FControlEdge or ControlFace,PrevEdge.Curve);
         EdgeCheck(P2Point,CurrEdgePoint,CurrEdge.Crease,CurrEdge.FControlEdge or ControlFace,CurrEdge.Curve);
         EdgeCheck(CurrEdgePoint,NewLocation,False,False,nil);
         EdgeCheck(PrevEdgePoint,NewLocation,False,False,nil);
         NewFace.FPoints.Capacity:=4;
         for J:=0 to 3 do begin                       // Add new face to points
            Pts[J].FFaces.Add(NewFace);
            NewFace.FPoints.Add(Pts[J]);
         end;
      end;
   end else if NoPoints=3 then begin
                      // Special case, quadrisect triancle by connecting all
                     // three edge points first the three surrounding triangles
      for I:=1 to FPoints.Count do begin P2:=FPoints[I-1];
         Index:=(I-2+FPoints.Count) mod FPoints.Count;
         PrevEdge:=Owner.EdgeExists( P2,FPoints[Index] );   if PrevEdge=nil then exit; //break; //continue;
         Index:=(I+FPoints.Count) mod FPoints.Count;
         CurrEdge:=Owner.EdgeExists( P2,FPoints[Index] );   if CurrEdge=nil then exit; //break; //continue;
         Index:=0;
         TmpIndex:=EdgePoints.SortedIndexOf(PrevEdge);
         Pts[Index]:=EdgePoints.Objects[Tmpindex];    // PrevEdge.FNewLocation;
         Index:=1;
         TmpIndex:=VertexPoints.SortedIndexOf(P2);
         Pts[index]:=VertexPoints.Objects[Tmpindex];  // P2.FNewLocation;
         Index:=2;
         TmpIndex:=EdgePoints.SortedIndexOf(CurrEdge);
         Pts[index]:=Edgepoints.Objects[Tmpindex];    // CurrEdge.FNewLocation;
         NewFace:=SFace.Create(Owner);                // add the new face
         Dest.Add(NewFace);
         EdgeCheck( Pts[0],Pts[1],PrevEdge.Crease,PrevEdge.FControlEdge or ControlFace,PrevEdge.Curve );
         EdgeCheck( Pts[1],Pts[2],CurrEdge.Crease,CurrEdge.FControlEdge or ControlFace,CurrEdge.Curve );
         EdgeCheck( Pts[2],Pts[0],False,False,nil );
         NewFace.FPoints.Capacity:=3;
         for J:=0 to 2 do begin                       // Add new face to points
             Pts[J].FFaces.Add( NewFace );
             NewFace.FPoints.Add( Pts[J] );
             Pts[J].AddFace( NewFace );
         end;
      end;                                          // then the center triangle
      for I:=1 to FPoints.Count do begin P2:=FPoints[I-1];
         Index:=( I-2+FPoints.Count ) mod FPoints.Count;
         PrevEdge:=Owner.EdgeExists(P2,FPoints[Index]);
         TmpIndex:=EdgePoints.SortedIndexOf(PrevEdge);
         Pts[I-1]:=EdgePoints.Objects[TmpIndex];       // PrevEdge.FNewLocation
      end;                                             // add the new face
      NewFace:=SFace.Create( Owner );
      Dest.Add( NewFace );
      EdgeCheck(Pts[0],Pts[1],False,False,nil);
      EdgeCheck(Pts[1],Pts[2],False,False,nil);
      EdgeCheck(Pts[2],Pts[0],False,False,nil);
      NewFace.FPoints.Capacity:=3;
      for J:=0 to 2 do begin                          // Add new face to points
          Pts[J].FFaces.Add( NewFace );
          NewFace.FPoints.Add( Pts[J] );
          Pts[J].AddFace( NewFace );
      end;
   end;
end;
{
   SControlFace
}
function SControlFace.FGetChild(Index:Integer):SFace;
   begin Result:=FChildren[index]; end;
function SControlFace.FGetChildCount:Integer;
   begin Result:=FChildren.Count; end;
{
function SControlFace.FGetColor:TColor;
   begin if Selected then Result:=Sp.Select
                     else Result:=Layer.Color; end;
}
function SControlFace.FGetControlEdge(Index:Integer):SEdge;
   begin Result:=FControlEdges[Index]; end;

procedure SControlFace.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedControlFaces.IndexOf(self);
   if Val then begin               // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedControlFaces.Add(self);
   end else begin
      if Index<>-1 then Owner.FSelectedControlFaces.Delete(index);
   end;
   if Assigned(Owner.OnSelectItem) then Owner.OnSelectItem(self);
end;
function SControlFace.FGetSelected:Boolean;
   begin Result:=Owner.FSelectedControlFaces.IndexOf(self)<>-1; end;
function SControlFace.FGetControlEdgeCount:Integer;
   begin Result:=FControlEdges.Count; end;
function SControlFace.FGetEdge(Index:Integer):SEdge;
   begin Result:=FEdges[Index]; end;
function SControlFace.FGetEdgeCount:Integer;
   begin Result:=FEdges.Count; end;
function SControlFace.FGetIndex:Integer;
   begin Result:=Owner.FControlFaces.IndexOf(self); end;
function SControlFace.FGetVisible:Boolean;
   begin Result:=Layer.Visible or Selected; end;

procedure SControlFace.FSetLayer(Val:SLayer);
begin
   if Val<>FLayer then begin
      if FLayer<>nil then begin                // Disconnect from current layer
         FLayer.DeleteControlFace(self);
         FLayer:=nil;
      end;
      FLayer:=Val;
      if FLayer<>nil then begin                     // Connect to the new layer
         FLayer.AddControlFace(self);
      end;
   end;
end;

procedure SControlFace.CalcExtents;
var I,J     : Integer;
    Face    : SFace;
    P1      : SPoint;
begin                           // Calculate min/max coordinate of all children
   if NoPoints>0 then FMin:=Point[0].Coordinate
                       else FMin:=ZERO;
   FMax:=FMin;
   if FChildren.Count>0 then begin
      for I:=1 to FChildren.Count do begin
         Face:=FChildren[I-1];
         for J:=1 to Face.FPoints.Count do begin
            P1:=Face.FPoints[J-1];
            if (I=1) and (J=1) then begin
               FMin:=P1.Coordinate;
               FMax:=FMin;
            end;
            MinMax(P1.FCoordinate,FMin,FMax);
         end;
      end;
   end else for I:=2 to NoPoints do MinMax(Point[I-1].Coordinate,FMin,FMax);
end;

procedure SControlFace.Clear;
begin
   ClearChildren;
   inherited Clear;
   FLayer:=nil;
end;

procedure SControlFace.ClearChildren;
var I:Integer;
begin
   for I:=1 to Childcount do Child[I-1].Destroy;
   FChildren.Clear;
   for I:=1 to EdgeCount do Edge[I-1].Destroy;
   FEdges.Clear;
end;

constructor SControlFace.Create(Owner:SSurface);
begin
   FLayer:=nil;
   FChildren:=TFasterlist.Create;
   FEdges:=TFasterList.Create;
   FControlEdges:=TFasterList.Create;
   Inherited Create(Owner);
end;

function SControlFace.DistanceToCursor(X,Y:Integer;var P:Vector;Viewport:TViewport):integer;
var I,Dist,Tmp : Integer;
    Param      : Real;
    Edge       : SEdge;
    Pt1,Pt2    : TPoint;
    P1,P2,M    : Vector;
begin
   Result:=1000000;
   P:=ZERO;
   if Owner.ShowInteriorEdges then begin // check distance to all interior edges
      for I:=1 to FEdges.Count do begin
         Edge:=FEdges[I-1];
         P1:=Edge.Startpoint.Coordinate;
         P2:=Edge.Endpoint.Coordinate;

         if (Viewport.ViewType=fvBodyplan) and (not Owner.DrawMirror) then begin
            if ((P1.X<Owner.MainframeLocation) and (P2.X>Owner.MainframeLocation))
            or ((P1.X>Owner.MainframeLocation) and (P2.X<Owner.MainframeLocation))
            then begin
               if P2.X-P1.X<>0 then M:=Interpolate(P1,P2,(Owner.MainframeLocation-P1.X)/(P2.X-P1.X))
                               else M:=MidPoint(P1,P2);
               if P1.X<=Owner.MainframeLocation then begin   // P2 lies on port
                  Pt1:=Viewport.Project(P2);
                  Pt2:=Viewport.Project(M);
                  Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
                  if Tmp<Result then begin
                     Result:=Tmp;
                     P:=Interpolate(P2,M,Param);
                  end;                                  // P1 lies on starboard
                  P1.Y:=-P1.Y;
                  M.Y:=-M.Y;
                  Pt1:=Viewport.Project(P1);
                  Pt2:=Viewport.Project(M);
                  Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
                  if Tmp<Result then begin
                     Result:=Tmp;
                     P:=Interpolate(P1,M,Param);
                  end;
               end else begin                               // P1 lies on port
                  Pt1:=Viewport.Project(P1);
                  Pt2:=Viewport.Project(M);
                  Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
                  if Tmp<Result then begin
                     Result:=Tmp;
                     P:=Interpolate(P1,M,Param);
                  end;                                  // P2 lies on starboard
                  P2.Y:=-P2.Y;
                  M.Y:=-M.Y;
                  Pt1:=Viewport.Project(P2);
                  Pt2:=Viewport.Project(M);
                  Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
                  if Tmp<Result then begin
                     Result:=Tmp;
                     P:=Interpolate(P2,M,Param);
                  end;
               end;
            end else begin
               if P1.X<=Owner.MainframeLocation then P1.Y:=-P1.Y;
               if P2.X<=Owner.MainframeLocation then P2.Y:=-P2.Y;
               Pt1:=Viewport.Project(P1);
               Pt2:=Viewport.Project(P2);
               Tmp:=Round(DistanceToLine(Pt1,Pt2,X,Y,Param));
               if Tmp<Result then begin
                  Result:=Tmp;
                  P:=Interpolate(P1,P2,Param);
               end;
            end;
         end else begin
            Dist:=Round(DistanceToLine(Viewport.Project(P1),Viewport.Project(P2),X,Y,Param));
            if I=1 then begin
               Result:=Dist;
               P:=Interpolate(P1,P2,Param);
            end else if Dist<Result then begin
               Result:=Dist;
               P:=Interpolate(P1,P2,Param);
            end;
            if (Layer.Symmetric) and (Owner.DrawMirror) then begin
               P1.Y:=-P1.Y;
               P2.Y:=-P2.Y;
               Dist:=Round(DistanceToLine(Viewport.Project(P1),Viewport.Project(P2),X,Y,Param));
               if Dist<Result then begin
                  Result:=Dist;
                  P:=Interpolate(P1,P2,Param);
               end;
            end;
         end;
      end;
   end;
end;

procedure SControlFace.SelDeleteFace;
var I,Index: Integer;
    P1,P2: SPoint;
    Edg: SControlEdge;
begin
   Selected:=false;                                    // delete from selection
   Layer:=nil;                                         // remove from layer
   Index:=Owner.FControlFaces.IndexOf( Self );         // ## ??
   if Index<>-1 then begin
      Owner.FControlFaces.Delete(Index);
      P1:=Point[NoPoints-1];                     // P1.DeleteFace(Self);
      for I:=0 to NoPoints-1 do begin P2:=Point[I]; P2.DeleteFace(Self);
         Edg:=Owner.EdgeExists( P1,P2 ) as SControlEdge;
         if Edg<>nil then begin Edg.DeleteFace( Self );
           if Edg.NoFaces=0 then Edg.SelDeleteEdge;
         end; P1:=P2;
      end;
   end;
   Owner.Build:=False;
   Clear;
   Destroy;
end;

destructor SControlFace.Destroy;
begin Inherited Destroy;
      FEdges.Destroy;
      FControlEdges.Destroy;
      FChildren.Destroy;
end;

procedure SControlFace.Draw( Viewport:TViewport );
Type TIntData = record P: Vector; DotProd: Real; end;
var I,J,K,Na,Nb,Capacity,Index,Board: Integer; Min,Max,Tmp, lEps: Real;
    Edge : SEdge;
    Child: SFace;
    Point: SPoint;
    P1,P2,P3,Camera: Vector; Above,Below: VectorArray;
    R,G,B, Ru,Gu,Bu, Au, Alpha,
    R1,G1, R2,G2, R3,G3: Byte; Back: Boolean; // развёртка перецвета Gauss'иана
    Intersections: array of TIntData;
    Points: TFasterList;

    procedure DrawNormal( P,N:Vector; color:TColor );
    var P1,P2: TPoint; L,Ldes: Real;
    begin
      if (Viewport.ViewType=fvBodyplan)
        and (not Owner.DrawMirror)
        and (P.X<=Owner.MainframeLocation) then begin P.Y:=-P.Y; N.Y:=-N.Y end;
      Viewport.PenColor:=color;
      P1:=Viewport.Project(P);
      P2:=Viewport.Project( P+N );  // Calculate the length of normal on screen
      L:=hypot( P2.X-P1.X,P2.Y-P1.Y );
      if L>0 then begin
         Ldes:=0.0075*Screen.Width;
         if LDes<10 then Ldes:=10;  // Scale the length of the normal such that
         N:=(Ldes/L)*N;   // it is a fixed length relative to screen resolution
         P2:=Viewport.Project( P+N );
         Viewport.Canvas.MoveTo(P1.X,P1.Y);
         Viewport.Canvas.LineTo(P2.X,P2.Y);
      end;
    end; {Draw normal}

    procedure ZebraStripe
    ( Camera:Vector;
      Point1,Point2,Point3:SPoint;
      R,G,B,Zr,Zg,Zb:Byte;
      Right:boolean );
     const Width=0.02;
     var d1,d2,d3,Mindp,Maxdp: Real;
        Eye,Vz,P1,P2,P3,N1,N2,N3: Vector;
        I,J,Npts,NInt,Lo,Hi,Board: Integer;
        Pts: VectorArray;
        procedure Add( P:Vector; Dp:Real );
        begin
           if NInt=Capacity then begin
              inc(Capacity,10);
              Setlength(Intersections,Capacity);
           end;
           Inc(NInt);
           Intersections[NInt-1].P:=P;
           Intersections[NInt-1].DotProd:=Dp;
        end;
        procedure Process( P:Vector; Dp:Real );
        var PrevDp,Val,T: Real; I,L,H: Integer; PrevP,P3D: Vector;
        begin
           PrevDp:=Intersections[NInt-1].DotProd;
           L:=Trunc(PrevDp/Width);
           H:=Trunc(Dp/Width);
           if (H-L)>0 then begin
              PrevP:=Intersections[NInt-1].P;
              for I:=L to H do begin
                 Val:=I*Width;
                 if (Val>PrevDp) and (Val<Dp) then begin
                  T:=(Val-PrevDp)/(Dp-PrevDp);
                  P3D:=PrevP+T*(P-PrevP);
                  Add(P3D,Val);
                 end;
              end;
              Add(P,Dp);
           end else if L-H>0 then begin
              PrevP:=Intersections[NInt-1].P;
              for I:=L downto H do begin
                 Val:=I*Width;
                 if (Val<PrevDp) and (Val>Dp) then begin
                  T:=(Val-PrevDp)/(Dp-PrevDp);
                  P3D:=PrevP+T*(P-PrevP);
                  Add(P3D,Val);
                 end;
              end;
              Add(P,Dp);
           end else Add(P,Dp);
        end;
    begin
       P1:=Point1.FCoordinate;      if Right then P1.y:=-P1.y;
       P2:=Point2.FCoordinate;      if Right then P2.y:=-P2.y;
       P3:=Point3.FCoordinate;      if Right then P3.y:=-P3.y;
       Vz:=UnifiedNormal( P1,P2,P3 );
       if Point1.VertexType in [svRegular,svDart] then N1:=Point1.Normal else N1:=Vz;
       if Point2.VertexType in [svRegular,svDart] then N2:=Point2.Normal else N2:=Vz;
       if Point3.VertexType in [svRegular,svDart] then N3:=Point3.Normal else N3:=Vz;
       for Board:=0 to 1 do begin
          if (Board=1) then
          if (Owner.DrawMirror) and (Layer.Symmetric) then begin
             P1.Y:=-P1.Y; N1.Y:=-N1.Y;
             P2.Y:=-P2.Y; N2.Y:=-N2.Y;
             P3.Y:=-P3.Y; N3.Y:=-N3.Y;
          end else break;
          NInt:=0;
          Eye:=Normalize(Camera-P1); d1:=Dotproduct(Eye,N1); if d1<0 then d1:=-d1;
          Eye:=Normalize(Camera-P2); d2:=Dotproduct(Eye,N2); if d2<0 then d2:=-d2;
          Eye:=Normalize(Camera-P3); d3:=Dotproduct(Eye,N3); if d3<0 then d3:=-d3;
          MindP:=d1;
          MaxDp:=d1;
          if d2<Mindp then Mindp:=d2;
          if d2>Maxdp then Maxdp:=d2;
          if d3<Mindp then Mindp:=d3;
          if d3>Maxdp then Maxdp:=d3;
          Lo:=Trunc(MinDp/Width);
          if Lo<0 then Lo:=0;
          Hi:=trunc(MaxDp/Width);
          if Hi>Round(1/Width) then Hi:=Round(1/Width);
          if Lo=Hi then begin
             if not odd(Lo) then Viewport.ShadeTriFace(P1,P2,P3,R,G,B,Alpha)
                            else Viewport.ShadeTriFace(P1,P2,P3,Zr,Zg,Zb,Alpha);
          end else begin
             Add(P1,d1);
             Process(P2,d2);
             Process(P3,d3);
             Process(P1,d1);
             Setlength(Pts,NInt);
             for I:=Lo to Hi+1 do begin NPts:=0;
               for J:=1 to NInt-1 do begin
                  if ((Intersections[J-1].DotProd>=(I-1)*Width)
                  or (abs(Intersections[J-1].DotProd-(I-1)*Width)<1e-6))
                  and ((Intersections[J-1].DotProd<=I*Width)
                  or (abs(Intersections[J-1].DotProd-I*Width)<1e-6) )then begin
                     inc(Npts);
                     Pts[NPts-1]:=Intersections[J-1].P;
                  end;
               end;
               for J:=3 to NPts do begin
                  if odd(I)
                  then Viewport.ShadeTriFace(Pts[0],Pts[J-2],Pts[J-1],R,G,B,Alpha)
                  else Viewport.ShadeTriFace(Pts[0],Pts[J-2],Pts[J-1],Zr,Zg,Zb,Alpha);
               end;
            end;
         end;
       end;
    end;
begin
   if Viewport.ViewportMode<>vmWireframe then begin
      R:=GetRValue( Layer.Color );
      G:=GetGValue( Layer.Color );
      B:=GetBValue( Layer.Color );
      Alpha:=Layer.AlphaBlend;
      if Self.Selected then begin
         R:=(R+GetRValue( Sp.Select )) div 2;   // не оучше ли: div 3
         G:=(G+GetGValue( Sp.Select )) div 2;
         B:=(B+GetBValue( Sp.Select )) div 2;
      end;
      if (Sp.UColorIs)        // Clip all triangles against waterline plane
      and (Viewport.ViewportMode=vmShade)
      and (Layer.UseInHydrostatics) then begin
         Ru:=GetRValue(Sp.UColor);
         Gu:=GetGValue(Sp.UColor);
         Bu:=GetBValue(Sp.UColor);
         Au:=Sp.UAlfa;
         Ru:=( R*(255-Au) + Ru*Au ) div 255;
         Gu:=( G*(255-Au) + Gu*Au ) div 255;
         Bu:=( B*(255-Au) + Bu*Au ) div 255;
         Setlength(Above,6);
         setlength(Below,6);
         for I:=1 to ChildCount do begin Child:=Self.Child[I-1];
            Back := (not Owner.DrawMirror) and (ViewPort.ViewType=fvBodyPlan)
            and (Child.Point[0].Coordinate.x<=St.ProjectSettings.MidleFrame);
            for J:=2 to Child.Nopoints-1 do begin
               P1:=Child.Point[0].Coordinate;  // веер от начальной точки
               P2:=Child.Point[J-1].Coordinate;
               P3:=Child.Point[J].Coordinate;  // Check if clipping is required
               if Back then begin P1.y:=-P1.y; P2.y:=-P2.y; P3.y:=-P3.y; end;
               for Board:=0 to 1 do begin
                  if Board=1 then
                  if Owner.DrawMirror and Layer.Symmetric then begin
                     P1.Y:=-P1.Y;
                     P2.Y:=-P2.Y;
                     P3.Y:=-P3.Y;              // Check if clipping is required
                  end else break;
                  Min:=Owner.WaterlinePlane.a*P1.x
                     + Owner.WaterlinePlane.b*P1.y
                     + Owner.WaterlinePlane.c*P1.z
                     + Owner.WaterlinePlane.d;
                  Max:=Min;
                  Tmp:=Owner.WaterlinePlane.a*P2.x
                     + Owner.WaterlinePlane.b*P2.y
                     + Owner.WaterlinePlane.c*P2.z
                     + Owner.WaterlinePlane.d;
                  if Tmp<Min then Min:=Tmp else if Tmp>Max then Max:=Tmp;
                  Tmp:=Owner.WaterlinePlane.a*P3.x
                     + Owner.WaterlinePlane.b*P3.y
                     + Owner.WaterlinePlane.c*P3.z
                     + Owner.WaterlinePlane.d;
                  if Tmp<Min then Min:=Tmp else if Tmp>Max then Max:=Tmp;
                  if Max<=0.0 then begin            // entirely below the plane
                     Viewport.ShadeTriFace(P1,P2,P3,Ru,Gu,Bu,Alpha);
                  end else if Min>=0.0 then begin   // entirely above the plane
                     Viewport.ShadeTriFace(P1,P2,P3,R,G,B,Alpha);
                  end else begin                // pierces water, clip triangle
                     ClipTriangle(P1,P2,P3,Owner.WaterlinePlane,Na,Nb,Above,Below);
                     for K:=3 to Na do Viewport.ShadeTriFace(Above[0],Above[K-2],Above[K-1],R,G,B,Alpha);
                     for K:=3 to Nb do Viewport.ShadeTriFace(Below[0],Below[K-2],Below[K-1],Ru,Gu,Bu,Alpha);
                  end;
               end;
            end;
         end;
      end else
      if Viewport.ViewportMode=vmShadeZebra then begin
         Ru:=GetRValue(Sp.ZebraStripe);
         Gu:=GetGValue(Sp.ZebraStripe);
         Bu:=GetBValue(Sp.ZebraStripe);
         Camera:=Viewport.RotatedPointBack(Viewport.FCameraLocation);
         Capacity:=10;
         Setlength(Intersections,Capacity);
         for I:=1 to ChildCount do begin
            Child:=Self.Child[I-1];
            Back := (not Owner.DrawMirror) and (ViewPort.ViewType=fvBodyPlan)
            and (Child.Point[0].Coordinate.x<=St.ProjectSettings.MidleFrame);
            for J:=2 to Child.Nopoints-1 do begin
               P1:=Child.Point[0].Coordinate;
               P2:=Child.Point[J-1].Coordinate;
               P3:=Child.Point[J].Coordinate;
             ZebraStripe(Camera,Child.Point[0],Child.Point[J-1],Child.Point[J],R,G,B,Ru,Gu,Bu,Back);
            end;
         end;
         if capacity<0 then exit;
      end else begin lEps:=exp( -9-Ord( St.Precision ) ); // 1e-12
         for I:=1 to ChildCount do begin                  // == Developed Patch
            Child:=Self.Child[I-1];
            Back := (not Owner.DrawMirror) and (ViewPort.ViewType=fvBodyPlan)
            and (Child.Point[0].Coordinate.x<=St.ProjectSettings.MidleFrame);
            for J:=2 to Child.Nopoints-1 do begin
               P1:=Child.Point[0].Coordinate;
               P2:=Child.Point[J-1].Coordinate;
               P3:=Child.Point[J].Coordinate;
               if Viewport.ViewportMode<>vmShade then begin
                  Index:=Owner.FPoints.SortedIndexOf(Child.Point[0]);
                  if abs(Owner.FGausCurvature[index])<lEps then begin R1:=64; G1:=255 end else begin R1:=255; G1:=64 end;
                  Index:=Owner.FPoints.SortedIndexOf(Child.Point[J-1]);
                  if abs(Owner.FGausCurvature[index])<lEps then begin R2:=64; G2:=255 end else begin R2:=255; G2:=64 end;
                  Index:=Owner.FPoints.SortedIndexOf(Child.Point[J]);
                  if abs(Owner.FGausCurvature[index])<lEps then begin R3:=64; G3:=255 end else begin R3:=255; G3:=64 end;
                  if Back then begin P1.Y:=-P1.y; P2.Y:=-P2.y; P3.Y:=-P3.y; end;
                  Viewport.ShadeTriangles( P1,P2,P3, R1,G1,G1,R2,G2,G2,R3,G3,G3 );
                  if (Owner.DrawMirror) and (Layer.Symmetric) then begin
                     P1.Y:=-P1.Y;
                     P2.Y:=-P2.Y;
                     P3.Y:=-P3.Y;
                     Viewport.ShadeTriangles( P1,P2,P3, R1,G1,G1,R2,G2,G2,R3,G3,G3 );
                  end;
               end else begin
                  Viewport.ShadeTriFace(P1,P2,P3,R,G,B,Alpha);
                  if (Owner.DrawMirror) and (Layer.Symmetric) then begin
                     P1.Y:=-P1.Y;
                     P2.Y:=-P2.Y;
                     P3.Y:=-P3.Y;
                     Viewport.ShadeTriFace(P1,P2,P3,R,G,B,Alpha);
                  end;
               end;
            end;
         end;
      end;
   end else begin     // Draw interior edges (not descending from controledges)
      Viewport.PenStyle:=psSolid;
      Viewport.PenWidth:=1;
      if Selected then Viewport.PenColor:=Sp.Select
                  else Viewport.PenColor:=Layer.Color;
      for I:=1 to FEdges.Count do begin
         Edge:=FEdges[I-1];
         Edge.Draw(Owner.DrawMirror and Layer.Symmetric,Viewport);
      end;                          // Draw edges descending from controledges,
      if not Selected then begin    // but slighly darker then interior edges
         R:=(3*GetRValue(Layer.Color)) div 5;
         G:=(3*GetGValue(Layer.Color)) div 5; // было:
         B:=(3*GetBValue(Layer.Color)) div 5; // round(0.6*GetRValue(Layer.Color));
         Viewport.PenColor:=RGB( R,G,B );
      end;
      for I:=1 to FControlEdges.Count do begin
         Edge:=FControlEdges[I-1];
         Edge.Draw(Owner.DrawMirror and Layer.Symmetric,Viewport);
      end;
      if (Selected) and (Owner.ShowNormals) then begin          // Draw nornals
                           // First assemble all points within this controlface
         Points:=TFasterList.Create;
         for I:=1 to ChildCount do begin
            Child:=Self.Child[I-1];
            for J:=1 to Child.Nopoints-1 do begin
               Point:=Child.Point[J-1];
               if Points.SortedIndexOf(Point)=-1 then Points.AddSorted(Point);
            end;
         end;
         for I:=1 to Points.Count do begin
            Point:=Points[I-1];
            P1:=Point.Coordinate;
            P2:=Point.Normal;
            DrawNormal( P1,P2,Sp.Normal );
            if (Layer.Symmetric) and (Owner.DrawMirror) then begin
               P1.Y:=-P1.Y;
               P2.Y:=-P2.Y;
               DrawNormal( P1,P2,Sp.Normal );
            end;
         end;  Points.Destroy;
      end;
   end;
end;

procedure SControlFace.Draw
( Viewport:TViewport; MinCurvature,MaxCurvature:Real );
var I,J,Index: Integer; Curv: Real; P1,P2,P3: Vector;
    Child: SFace;
    R1,G1,B1, R2,G2,B2, R3,G3,B3: Byte; Back: Boolean;
    function Fragment( Curvature:Real ):Real; const contrast=0.1;
    begin
       if (Curvature>-1e-4) and (Curvature<1e-4) then result:=0.5 else begin
          if Curvature>0
             then Result:=0.5+0.5*Power( Curvature/MaxCurvature,contrast )
             else Result:=0.5-0.5*Power( Curvature/MinCurvature,contrast );
          Result:=1-result;
       end;
    end;
begin
   for I:=1 to ChildCount do begin
      Child:=Self.Child[I-1];
      Back := (not Owner.DrawMirror) and (ViewPort.ViewType=fvBodyPlan)
          and (Child.Point[0].Coordinate.x<=St.ProjectSettings.MidleFrame);
      for J:=2 to Child.Nopoints-1 do begin
         P1:=Child.Point[0].Coordinate;
         Index:=Owner.FPoints.SortedIndexOf(Child.Point[0]);
         Curv:=Owner.FGausCurvature[index];
         FillColor(Fragment(Curv),R1,G1,B1);
         P2:=Child.Point[J-1].Coordinate;
         Index:=Owner.FPoints.SortedIndexOf(Child.Point[J-1]);
         Curv:=Owner.FGausCurvature[index];
         FillColor(Fragment(Curv),R2,G2,B2);
         P3:=Child.Point[J].Coordinate;
         Index:=Owner.FPoints.SortedIndexOf(Child.Point[J]);
         Curv:=Owner.FGausCurvature[index];
         FillColor(Fragment(Curv),R3,G3,B3);
         if Back then begin P1.Y:=-P1.y; P2.Y:=-P2.y; P3.Y:=-P3.y; end;
         Viewport.ShadeTriangles(P1,P2,P3,R1,G1,B1,R2,G2,B2,R3,G3,B3);
         if (Owner.DrawMirror) and (Layer.Symmetric) then begin
            P1.Y:=-P1.Y;
            P2.Y:=-P2.Y;
            P3.Y:=-P3.Y;
            Viewport.ShadeTriangles(P1,P2,P3,R1,G1,B1,R2,G2,B2,R3,G3,B3);
         end;
      end;
   end;
end;

function SControlFace.InsertEdge(P1,P2:SControlPoint):SControlEdge;
var Tmp,I: Integer; Pts: TFasterList;
begin Result:=nil; if P1=P2 then exit;
   try
      if (P1.FFaces.IndexOf(self)<>-1)
      and (P2.FFaces.IndexOf(self)<>-1) then begin
         if Owner.EdgeExists(P1,P2)<>nil then exit;
         Tmp:=IndexOfPoint(P1);
         Pts:=TFasterList.Create;
         Pts.Add(P1);
         for I:=1 to Nopoints do begin
            Tmp:=(Tmp+1) mod Nopoints;
            Pts.Add(Point[Tmp]);
            if Pts[Pts.Count-1]=P2 then break;
         end;
         if Pts.Count>2 then Owner.AddControlFace(Pts,False,Layer);
         Tmp:=IndexOfPoint(P2);
         Pts.Clear;
         Pts.Add(P2);
         for I:=1 to Nopoints do begin
            Tmp:=(Tmp+1) mod Nopoints;
            Pts.Add(Point[Tmp]);
            if Pts[Pts.Count-1]=P1 then break;
         end;
         if Pts.Count>2 then Owner.AddControlFace(Pts,False,Layer);
         Pts.Destroy;
         SelDeleteFace;
      end;
      Result:=Owner.EdgeExists(P1,P2) as SControlEdge;
      if Result<>nil then Result.Crease:=False;
   except
     Result:=Owner.EdgeExists(P1,P2) as SControlEdge; // ##??
   end;
end;

procedure SControlFace.LoadBinary(Source:TFileBuffer);
var I,N,Index: Integer;
    P1,P2: SControlPoint;
    Edge: SControlEdge;
    Sel: Boolean;
begin Source.LoadInteger(N); // Read controlpoint data
   FPoints.Clear;
   FPoints.Capacity:=N;
   for I:=1 to N do begin Source.LoadInteger(Index);
      if Index=-1 then Index:=0;
      if Index<>-1 then begin
         P1:=Owner.FControlPoints[Index];
         FPoints.Add(P1);
         P1.FFaces.Add(Self);
      end;
   end;                      // Read layer-index
   Source.LoadInteger(Index);
   if (Index>=0) and (Index<Owner.FLayers.Count)
      then FLayer:=Owner.Layer[Index]
      else FLayer:=Owner.Layer[0]; // Reference to an invalid layer. Assign to owners default layer
   if FLayer<>nil then FLayer.AddControlFace( self )
    ; // else Raise Exception.Create('Invalid layer reference in procedure SControlFace.LoadBinary!');
   Source.LoadBoolean( Sel );
   if sel then Selected:=True;
   P1:=FPoints[NoPoints-1];
   for I:=1 to NoPoints do begin P2:=FPoints[I-1];
      Edge:=Owner.EdgeExists(P1,P2) as SControlEdge;
      if Edge<>nil then Edge.FFaces.Add( Self ) else begin
         Edge:=Owner.AddControlEdge( P1,P2 );
         Edge.Crease:=True;
         ShowMessage('Could not find edge!');
      end; P1:=P2;
   end;
end;

procedure SControlFace.SaveBinary(Destination:TFileBuffer);
var I,Index : Integer;
begin
   Destination.Add(NoPoints);
   for I:=1 to NoPoints do
       Destination.Add(Owner.FControlPoints.SortedIndexOf(Point[I-1]));
   if Layer<>nil then Index:=Owner.FLayers.IndexOf(Layer)    // Add layer index
                 else Index:=-1;
   Destination.Add(Index);
   Destination.Add(Selected);
end;

procedure SControlFace.SaveToDXF(Strings:TStringList);
var I,J,K,Cols,Rows,ColorIndex,Board: Integer;
    Child      : SFace;
    LayerName  : string;
    P          : Vector;
    Grid       : SGrid;
    FaceData   : TFaceGrid;
begin
   LayerName:=self.Layer.Name;
// LayerName:=ConvertEncoding( LayerName,'utf8','cp1251' );
   ColorIndex:=FindDXFColorIndex(Layer.Color);
   if Nopoints=4 then begin     // create one polymesh for all childfaces
      FaceData.NCols:=1;
      FaceData.NRows:=1;
      Setlength(FaceData.Faces,FaceData.NRows);
      Setlength(FaceData.Faces[0],FaceData.NCols);
      FaceData.Faces[0][0]:=Self;
      Owner.ConvertToGrid(FaceData,Cols,Rows,Grid);
      if (Rows>0) and (Cols>0) then // begin
      for Board:=0 to 1 do begin
         if Board=1 then
         if (not Owner.DrawMirror) or (not Layer.Symmetric) then break;
         Strings.Add('0'+EOL+'POLYLINE');
         Strings.Add('8'+EOL+LayerName);
         Strings.Add('62'+EOL+IntToStr(ColorIndex));
         Strings.Add('66'+EOL+'1');
         Strings.Add('70'+EOL+'16');
         Strings.Add('71'+EOL+IntToStr(Cols));
         Strings.Add('72'+EOL+IntToStr(Rows));
         for I:=1 to Rows do
         for J:=1 to Cols do begin
             P:=Grid[I-1][J-1].FCoordinate; if Board=1 then P.Y:=-P.Y;
             Strings.Add('0'+EOL+'VERTEX');
             Strings.Add('8'+EOL+LayerName);
             Strings.Add('10'+EOL+FloatToDec(P.X,4));
             Strings.Add('20'+EOL+FloatToDec(P.z,4));
             Strings.Add('30'+EOL+FloatToDec(P.y,4));
             Strings.Add('70'+EOL+'64');                 // polygon mesh vertex
         end; Strings.add('0'+EOL+'SEQEND');
      end;
   end else begin                           // send all child faces as 3D faces
      for J:=1 to ChildCount do begin Child:=self.Child[J-1];
         Strings.Add('0'+EOL+'3DFACE');
         Strings.Add('8'+EOL+LayerName);
         Strings.Add('62'+EOL+IntToStr(ColorIndex));
         for K:=1 to Child.Nopoints do begin
            P:=Child.Point[K-1].Coordinate;
            Strings.Add(IntToStr(10+K-1)+EOL+FloatToDec(P.X,4));
            Strings.Add(IntToStr(20+K-1)+EOL+FloatToDec(P.z,4));
            Strings.Add(IntToStr(30+K-1)+EOL+FloatToDec(P.y,4));
         end;
         if Child.Nopoints=3 then begin     // 4th point is same as third
            Strings.Add(IntToStr(13)+EOL+FloatToDec(P.X,4));
            Strings.Add(IntToStr(23)+EOL+FloatToDec(P.z,4));
            Strings.Add(IntToStr(33)+EOL+FloatToDec(P.y,4));
         end;
         if (Layer.Symmetric) and (Owner.DrawMirror) then begin // send starboard side also
            Strings.Add('0'+EOL+'3DFACE');
            Strings.Add('8'+EOL+LayerName);
            Strings.Add('62'+EOL+IntToStr(ColorIndex));
            for K:=Child.Nopoints downto 1 do begin
               P:=Child.Point[K-1].Coordinate; P.Y:=-P.Y;
               Strings.Add(IntToStr(10+K-1)+EOL+FloatToDec(P.X,4));
               Strings.Add(IntToStr(20+K-1)+EOL+FloatToDec(P.z,4));
               Strings.Add(IntToStr(30+K-1)+EOL+FloatToDec(P.y,4));
            end;
            if Child.Nopoints=3 then begin  // 4th point is same as third
               Strings.Add(IntToStr(13)+EOL+FloatToDec(P.X,4));
               Strings.Add(IntToStr(23)+EOL+FloatToDec(P.z,4));
               Strings.Add(IntToStr(33)+EOL+FloatToDec(P.y,4));
            end;
         end;
      end;
   end;
end;

procedure SControlFace.SaveToStream(Strings:TStringlist);
var Str: string; I,Index: Integer;
begin
   Str:=IntToStr(NoPoints);
   for I:=1 to NoPoints do
       Str:=Str+#32+IntToStr(Owner.FControlPoints.SortedIndexOf(Point[I-1]));
   if Layer<>nil then Index:=Owner.FLayers.IndexOf(Layer) // Add layer index
                 else Index:=-1;
   Str:=Str+#32+IntToStr(Index); //+#32+BoolToStr(Selected); без выделений
   if Selected then Str:=Str+' 1';
   strings.Add(Str);
end;

procedure SControlFace.Subdivide
( Owner: SSurface;
  ControlFace: Boolean;
  VertexPoints,EdgePoints,FacePoints,InteriorEdges,ControlEdges,Dest: TFasterList );
var TmpList,Tmp: TFasterList; I: Integer; Face: SFace;
begin
   FControlEdges.Clear;
   if FChildren.Count=0 then begin
      FChildren.Capacity:=NoPoints;
      FEdges.Capacity:=4;
      Inherited Subdivide
        (Owner,True,VertexPoints,EdgePoints,FacePoints,FEdges,FControlEdges,FChildren);
   end else begin
      TmpList:=TFasterlist.Create;
      TmpList.Capacity:=4*ChildCount;
      Tmp:=TFasterList.Create;
      I:=Round( Power( 2,Owner.FCurrenSLevel ) );
      Tmp.Capacity:=2*(I*(I-1));
      for I:=1 to FChildren.Count do begin
         Face:=FChildren[I-1];
         Face.Subdivide(Owner,False,VertexPoints,EdgePoints,FacePoints,Tmp,FControlEdges,TmpList);
      end;
      ClearChildren;
      FEdges.Destroy;
      FEdges:=Tmp;
      FChildren.Destroy;
      FChildren:=TmpList;
   end;
   FControlEdges.Capacity:=FControlEdges.Count;
   ControlEdges.Capacity:=ControlEdges.Count+FControlEdges.Count;
   for I:=1 to FControlEdges.Count do
     if ControlEdges.SortedIndexOf(FControlEdges[I-1])=-1
       then ControlEdges.AddSorted(FControlEdges[I-1]);
   CalcExtents;
end;

// select all controlfaces connected to the current one that belong to the same layer and are not separated by a crease edge
procedure SControlFace.Trace;
var ToDoList : TFasterList;
    I        : Integer;
    Face     : SControlface;
    Prev     : TCursor;
    procedure FindAttachedFaces(List:TFasterList;Face:SControlFace);
    var I,J,Index: Integer;
        P1,P2  : SPoint;
        Edge   : SEdge;
    begin
       P1:=Face.Point[Face.NoPoints-1];
       for I:=1 to Face.Nopoints do begin
          P2:=Face.Point[I-1];
          Edge:=Face.Owner.EdgeExists(P1,P2);
          if Edge<>nil then if not Edge.Crease then begin
             for J:=1 to Edge.NoFaces do if Edge.Face[J-1]<>Face then begin
                Index:=ToDoList.IndexOf(Edge.Face[J-1]);
                if Index<>-1 then begin
                   SControlface(Edge.Face[J-1]).Selected:=selected;
                   //List.Add(Edge.Face[J-1]);
                   ToDoList.Delete(Index);
                   FindAttachedFaces(List,Edge.Face[J-1] as SControlFace);
                end;
             end;
          end; P1:=p2;
       end;
    end;
begin
   Prev:=screen.Cursor;
   Screen.Cursor:=crHourglass;
   ToDoList:=TFasterList.Create;
   ToDoList.capacity:=Layer.Count;
   for I:=1 to Layer.Count do begin Face:=Layer.Items[I-1];
      if (Face<>self) and (Face.Selected<>self.Selected)
         then ToDoList.Add(Layer.Items[I-1]);
   end;
   ToDoList.Sort;
   FindAttachedFaces(ToDoList,self);
   ToDoList.Destroy;
   Screen.Cursor:=prev;
end;
{
   SSurface
~~
function SSurface.AddControlPoint
  ( P:Vector ): SControlPoint;
begin Result:=SControlPoint.Create( self );
      Result.FCoordinate:=P;
      FControlPoints.Add( Result );
end;
}
function SSurface.AddControlPoint
  ( P:Vector ): SControlPoint;
const MaxError=1e-18; // 5;
var I: Integer;
   Edge: SEdge;
   Point: SControlPoint;
   function NewPoint( P:Vector ):SControlPoint;
   begin Result:=SControlPoint.Create( self );
         Result.FCoordinate:=P;
         FControlPoints.Add( Result );
   end;
begin Result:=NIL;                                 Result:=NewPoint(P); exit;
   for I:=1 to NoControlEdges do begin Edge:=FControlEdges[I-1];
      if Edge.FFaces.Count<=1 then begin                     // boundary edge
         if sqr( P-Edge.Startpoint.FCoordinate )<=MaxError then begin
            Result:=Edge.Startpoint as SControlPoint; break;
         end else
         if sqr( P-Edge.Endpoint.FCoordinate )<=MaxError then begin
            Result:=Edge.Endpoint as SControlPoint; break;
         end;
      end;
   end;
   if Result=nil then                     // Search controlpoints without edges
   for I:=1 to FControlPoints.Count do begin Point:=ControlPoint[I-1];
      if Point.NoEdges=0 then
      if sqr( P-Point.FCoordinate )<=MaxError then
         begin Result:=Point; break; end;
   end;
   if Result=nil then Result:=NewPoint(P);
end;

procedure SSurface.AddControlPoint( P:SControlPoint );
    begin if FControlPoints.IndexOf(P)=-1 then
          begin FControlPoints.Add(P); P.Owner:=self; end;
          Build:=False;
    end;
// Adds a new controlpoint at 0,0,0 without checking other points
function SSurface.AddControlPoint:SControlPoint;
   begin Result:=SControlPoint.Create(self);
         Result.FCoordinate:=ZERO;
         FControlPoints.Add(Result);
   end;
function SSurface.AddNewLayer:SLayer;
   begin
      Result:=SLayer.Create(Self);
      FLayers.Add(Result);
      Result.LayerID:=FRequestNewLayerID;
      ActiveLayer:=Result;
      if assigned(OnChangeLayerData) then OnChangeLayerData(self);
   end;

// Tries to assemble quads into as few as possible rectangular patches

procedure SSurface.AssembleFacesToPatches
(     Layers:TFasterList;
      Mode:TAssembleMode;
  var AssembledPatches:TFaceArray;
  var NAssembled:Integer );
var ToDoList,DoneList,Current: TFasterlist;
    I,Capacity,ErrInd: Integer;
    Face: SControlFace;
    Layer: SLayer;
    function GetFace(P1,P2,P3,P4:SPoint):SControlFace;
    var I: Integer; Face: SFace;
    begin Result:=nil;
       for I:=1 to P1.NoFaces do begin Face:=P1.Face[I-1];
          if (P2.IndexOfFace(Face)<>-1)
          and(P3.IndexOfFace(Face)<>-1)
          and(P4.IndexOfFace(Face)<>-1) then begin
              Result:=Face as SControlFace; exit;
          end;
       end;
    end;
    procedure FindAttachedFaces(List:TFasterlist;Face:SControlFace);
    var I,J,Index: integer;
        P1,P2: SPoint;
        Edge: SEdge;
    begin
       P1:=Face.Point[Face.NoPoints-1];
       for I:=1 to Face.Nopoints do begin
          P2:=Face.Point[I-1];
          Edge:=Face.Owner.EdgeExists(P1,P2);
          if Edge<>nil then begin
             if not Edge.Crease then begin
                for J:=1 to Edge.NoFaces do if Edge.Face[J-1]<>Face then begin
                   Index:=ToDoList.IndexOf(Edge.Face[J-1]);
                   if Index<>-1 then begin
                      List.Add(Edge.Face[J-1]);
                      ToDoList.Delete(Index);
                      FindAttachedFaces(List,Edge.Face[J-1] as SControlFace);
                   end;
                end;
             end;
          end; P1:=p2;
       end;
    end;
    procedure AssembleFaces(CtrlFaces:TFasterList;var Assembled:TFaceArray;var NAssembled:Integer);
    { Type TPointRow=record NPoints:Integer; Points: array of SPoint; end;
          TPointGrid=record NRows,RowCapacity,ColCapacity: Integer; Rows: array of TPointRow; end;
    }
    var I,J,Index,NCols,NRows: Integer;
        Face: SControlFace;
        Grid: SGrid;
        NewFace: TFaceGrid;
        CheckFaces: TFasterList; // temporary list with all controlfaces that is used to check if a crease vertex is
                                 // regular (depends on which side of the crease edge is being processed)
        function FindCornerFace:SControlFace;
        var I,J,K,NFaces: Integer;
            Face,Face2: SControlFace;
            P: SPoint;
        begin
           Result:=nil;
           I:=1;
           while (I<=CtrlFaces.Count) and (Result=nil) do begin
              Face:=Ctrlfaces[I-1];
              J:=1;
              while (J<=Face.Nopoints) and (Result=nil) do begin
                 P:=Face.Point[J-1];
                 NFaces:=1;
                 for K:=1 to P.NoFaces do begin
                    Face2:=P.Face[K-1] as SControlFace;
                    if Face2<>Face then
                    if CtrlFaces.SortedIndexOf(Face2)<>-1 then begin
                       inc(NFaces);
                       break;
                    end;
                 end; if NFaces=1 then Result:=Face; inc(J);
              end;                                   inc(I);
           end; if Result=nil then Result:=Ctrlfaces[CtrlFaces.Count-1]
        end;
        procedure AddFace(Face:TFaceGrid);
        begin if NAssembled=Capacity then begin inc(Capacity,50);
                                          setlength(Assembled,Capacity); end;
           inc(NAssembled);
           Assembled[NAssembled-1]:=Face;
        end;
        procedure DoAssemble(var Grid:SGrid;var Cols,Rows:Integer;Faces:TFasterList);
        var SearchBottom,SearchTop,SearchLeft,SearchRight,DataOK: Boolean;
            Counter,Index,I,J,NFaces: Integer;
            Edge1,Edge2: SEdge;
            Face       : SFace;
            TmpFaces: array of SFace;
            function ValidFace(Face:Sface):Boolean;
            var I,J,N,Index: Integer; Tmp: SFace;
            begin Result:=False;
               if Face.Nopoints=4 then begin
                  Index:=Faces.SortedIndexOf(Face);
                  if Index<>-1 then begin Result:=True;
                     for I:=1 to NFaces do if TmpFaces[I-1]=face then begin
                        result:=false;
                        exit;
                     end;
                     if NFaces>0 then begin // must also be connected to previous face
                        Tmp:=TmpFaces[NFaces-1];
                        N:=0;
                        for J:=1 to Face.Nopoints do begin
                           if Tmp.IndexOfPoint(Face.Point[J-1])<>-1 then inc(N);
                        end;
                        Result:=N>1;
                     end;
                  end;
               end;
            end;
        begin
           Counter:=0;
           SearchBottom:=True;
           SearchTop:=True;
           SearchRight:=True;
           SearchLeft:=True;
           if Mode=amNURBS then begin
              if not Grid[0][0].IsRegularNURBSPoint(CheckFaces) then begin
                 SearchLeft:=False;
                 SearchTop:=False;
              end;
              if not Grid[Rows-1][0].IsRegularNURBSPoint(CheckFaces) then begin
                 SearchLeft:=False;
                 SearchBottom:=False;
              end;
              if not Grid[Rows-1][Cols-1].IsRegularNURBSPoint(CheckFaces) then begin
                 SearchRight:=False;
                 SearchBottom:=False;
              end;
              if not Grid[0][Cols-1].IsRegularNURBSPoint(CheckFaces) then begin
                 SearchRight:=False;
                 SearchTop:=False;
              end;
           end;
           while ((SearchBottom)
             or (SearchTop)
             or (SearchRight)
             or (SearchLeft))
            and (Faces.Count>0) do begin inc(Counter);
              if Counter>4 then Counter:=1;
              if (Counter=1) and (SearchBottom) then begin
                 Setlength(TmpFaces,Cols);
                 NFaces:=0;
                 for I:=2 to Cols do begin
                    Edge1:=EdgeExists(Grid[Rows-1][I-2],Grid[Rows-1][I-1]);
                    if Edge1<>nil then
                    if not Edge1.Crease then
                    for J:=1 to Edge1.NoFaces do begin
                       Face:=Edge1.Face[J-1];
                       if ValidFace(Face) then begin
                          TmpFaces[NFaces]:=Face;
                          inc(NFaces);
                          break;
                       end;
                    end;
                    if NFaces<>I-1 then break;
                 end;
                 if NFaces=Cols-1 then begin          // search was successfull
                   for I:=1 to NFaces do begin
                      Setlength(Grid,Rows+1);
                      Setlength(Grid[Rows],Cols);
                      Face:=TmpFaces[I-1];
                      Index:=Faces.SortedIndexOf(Face);
                      if Index<>-1 then Faces.Delete(index);
                      Index:=Face.IndexOfPoint(Grid[Rows-1][I]);
                      Index:=(Index+1) mod Face.Nopoints;
                      if Face.Point[index]=Grid[Rows-1][I-1] then begin
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[Rows][I-1]:=Face.Point[index];
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[Rows][I]:=Face.Point[index];
                      end else begin
                         Index:=Face.IndexOfPoint(Grid[Rows-1][I-1]);
                         Index:=(Index+1) mod Face.Nopoints;
                         if Face.Point[index]=Grid[Rows-1][I] then begin
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[Rows][I]:=Face.Point[index];
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[Rows][I-1]:=Face.Point[index];
                         end;
                      end;
                   end;
                   // check if the boundary edges do not switch between crease or not crease
                   DataOK:=True;
                   if Mode=amNURBS then begin
                      Edge1:=EdgeExists(Grid[Rows][0],Grid[Rows-1][0]);
                      Edge2:=EdgeExists(Grid[Rows-1][0],Grid[Rows-2][0]);
                      if (Edge1<>nil) and (Edge2<>nil) then if Edge1.Crease<>Edge2.Crease then DataOK:=False;
                      Edge1:=EdgeExists(Grid[Rows][Cols-1],Grid[Rows-1][Cols-1]);
                      Edge2:=EdgeExists(Grid[Rows-1][Cols-1],Grid[Rows-2][Cols-1]);
                      if (Edge1<>nil) and (Edge2<>nil) then if Edge1.Crease<>Edge2.Crease then DataOK:=False;
                      for I:=2 to Cols-1 do if not Grid[Rows][I-1].IsRegularNURBSPoint(CheckFaces) then
                         DataOK:=False;
                   end;
                   if not DataOK then begin       // do not add the current row
                      for I:=1 to NFaces do Faces.AddSorted(TmpFaces[I-1]);
                      SearchBottom:=False;
                   end else inc(Rows);
                 end else SearchBottom:=False;
              end else if (Counter=2) and (SearchRight) then begin
                 Setlength(TmpFaces,Rows);
                 NFaces:=0;
                 for I:=2 to Rows do begin
                    Edge1:=EdgeExists(Grid[I-1][Cols-1],Grid[I-2][Cols-1]);
                    if Edge1<>nil then
                    if not Edge1.Crease then
                    for J:=1 to Edge1.NoFaces do begin
                       Face:=Edge1.Face[J-1];
                       if ValidFace(Face) then begin
                          TmpFaces[NFaces]:=Face;
                          inc(NFaces);
                          break;
                       end;
                    end;
                    if NFaces<>I-1 then break;
                 end;
                 if NFaces=Rows-1 then begin          // search was successfull
                   for I:=1 to Rows do begin
                      Setlength(grid[I-1],Cols+1);
                      Grid[I-1][Cols]:=nil;
                   end;
                   for I:=1 to NFaces do begin
                      Face:=TmpFaces[I-1];
                      Index:=Faces.SortedIndexOf(Face);
                      if Index<>-1 then Faces.Delete(index);
                      Index:=Face.IndexOfPoint(Grid[I-1][Cols-1]);
                      Index:=(Index+1) mod Face.Nopoints;
                      if Face.Point[index]=Grid[I][Cols-1] then begin
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[I][Cols]:=Face.Point[index];
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[I-1][Cols]:=Face.Point[index];
                      end else begin
                         Index:=Face.IndexOfPoint(Grid[I][Cols-1]);
                         Index:=(Index+1) mod Face.Nopoints;
                         if Face.Point[index]=Grid[I-1][Cols-1] then begin
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[I-1][Cols]:=Face.Point[index];
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[I][Cols]:=Face.Point[index];
                         end;
                      end;
                   end;
                   DataOK:=True;
                   if Mode=amNURBS then begin
                      Edge1:=EdgeExists(Grid[0][Cols],Grid[0][Cols-1]);
                      Edge2:=EdgeExists(Grid[0][Cols-1],Grid[0][Cols-2]);
                      if (Edge1<>nil) and (Edge2<>nil) then if Edge1.Crease<>Edge2.Crease then DataOK:=False;
                      Edge1:=EdgeExists(Grid[Rows-1][Cols],Grid[Rows-1][Cols-1]);
                      Edge2:=EdgeExists(Grid[Rows-1][Cols-1],Grid[Rows-1][Cols-2]);
                      if (Edge1<>nil) and (Edge2<>nil) then if Edge1.Crease<>Edge2.Crease then DataOK:=False;
                      for I:=2 to Rows-1 do if not Grid[I-2][Cols].IsRegularNURBSPoint(CheckFaces) then
                         DataOK:=False;
                   end;
                   if not DataOK then begin       // do not add the current row
                      for I:=1 to NFaces do Faces.AddSorted(TmpFaces[I-1]);
                      SearchRight:=False;
                   end else inc(Cols);
                 end else SearchRight:=False;
              end else if (Counter=3) and (SearchTop) then begin
                 Setlength(TmpFaces,Cols);
                 NFaces:=0;
                 for I:=2 to Cols do begin
                    Edge1:=EdgeExists(Grid[0][I-2],Grid[0][I-1]);
                    if Edge1<>nil then
                    if not Edge1.Crease then
                    for J:=1 to Edge1.NoFaces do begin
                       Face:=Edge1.Face[J-1];
                       if ValidFace(Face) then begin
                          TmpFaces[NFaces]:=Face;
                          inc(NFaces);
                          break;
                       end;
                    end;
                    if NFaces<>I-1 then break;
                 end;
                 if NFaces=Cols-1 then begin          // search was successfull
                   Setlength(Grid,Rows+1);
                   Setlength(Grid[Rows],Cols);
                   for I:=Rows downto 1 do begin
                      for J:=1 to Cols do Grid[I][J-1]:=Grid[I-1][J-1];
                   end;
                   for I:=1 to Cols do Grid[0][I-1]:=nil;

                   for I:=1 to NFaces do begin
                      Face:=TmpFaces[I-1];
                      Index:=Faces.SortedIndexOf(Face);
                      if Index<>-1 then Faces.Delete(index);

                      Index:=Face.IndexOfPoint(Grid[1][I-1]);
                      Index:=(Index+1) mod Face.Nopoints;
                      if Face.Point[index]=Grid[1][I] then begin
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[0][I]:=Face.Point[index];
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[0][I-1]:=Face.Point[index];
                      end else begin
                         Index:=Face.IndexOfPoint(Grid[1][I]);
                         Index:=(Index+1) mod Face.Nopoints;
                         if Face.Point[index]=Grid[1][I-1] then begin
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[0][I-1]:=Face.Point[index];
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[0][I]:=Face.Point[index];
                         end;
                      end;
                   end;
                   DataOK:=True;
                   if Mode=amNURBS then begin
                      Edge1:=EdgeExists(Grid[0][0],Grid[1][0]);
                      Edge2:=EdgeExists(Grid[1][0],Grid[2][0]);
                      if (Edge1<>nil) and (Edge2<>nil) then if Edge1.Crease<>Edge2.Crease then DataOK:=False;
                      Edge1:=EdgeExists(Grid[0][Cols-1],Grid[1][Cols-1]);
                      Edge2:=EdgeExists(Grid[1][Cols-1],Grid[2][Cols-1]);
                      if (Edge1<>nil) and (Edge2<>nil) then if Edge1.Crease<>Edge2.Crease then DataOK:=False;
                      for I:=2 to Cols-1 do
                        if not Grid[0][I-1].IsRegularNURBSPoint(CheckFaces)
                          then DataOK:=False;
                   end;
                   if not DataOK then begin       // do not add the current row
                      for I:=1 to NFaces do Faces.AddSorted(TmpFaces[I-1]);
                      SearchTop:=False;
                      for I:=1 to Rows do begin
                         for J:=1 to Cols do Grid[I-1][J-1]:=Grid[I][J-1];
                      end;
                   end else inc(Rows);
                 end else SearchTop:=False;
              end else  if (Counter=4) and (SearchLeft) then begin
                 Setlength(TmpFaces,Rows);
                 NFaces:=0;
                 for I:=2 to Rows do begin
                    Edge1:=EdgeExists(Grid[I-2][0],Grid[I-1][0]);
                    if Edge1<>nil then
                    if not Edge1.Crease then
                    for J:=1 to Edge1.NoFaces do begin
                       Face:=Edge1.Face[J-1];
                       if ValidFace(Face) then begin
                          TmpFaces[NFaces]:=Face;
                          inc(NFaces);
                          break;
                       end;
                    end;
                    if NFaces<>I-1 then break;
                 end;
                 if NFaces=Rows-1 then begin          // search was successfull
                   for I:=1 to Rows do begin
                      Setlength(grid[I-1],Cols+1);
                      for J:=Cols downto 1 do Grid[I-1][J]:=Grid[I-1][J-1];
                   end;
                   for I:=1 to NFaces do begin
                      Face:=TmpFaces[I-1];
                      Index:=Faces.SortedIndexOf(Face);
                      if Index<>-1 then Faces.Delete(index);
                      Index:=Face.IndexOfPoint(Grid[I][1]);
                      Index:=(Index+1) mod Face.Nopoints;
                      if Face.Point[index]=Grid[I-1][1] then begin
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[I-1][0]:=Face.Point[index];
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[I][0]:=Face.Point[index];
                      end else begin
                         Index:=Face.IndexOfPoint(Grid[I-1][1]);
                         Index:=(Index+1) mod Face.Nopoints;
                         if Face.Point[index]=Grid[I][1] then begin
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[I][0]:=Face.Point[index];
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[I-1][0]:=Face.Point[index];
                         end;
                      end;
                   end;
                   DataOK:=True;
                   if Mode=amNURBS then begin
                      Edge1:=EdgeExists(Grid[0][0],Grid[0][1]);
                      Edge2:=EdgeExists(Grid[0][1],Grid[0][2]);
                      if (Edge1<>nil) and (Edge2<>nil) then if Edge1.Crease<>Edge2.Crease then DataOK:=False;
                      Edge1:=EdgeExists(Grid[Rows-1][0],Grid[Rows-1][1]);
                      Edge2:=EdgeExists(Grid[Rows-1][1],Grid[Rows-1][2]);
                      if (Edge1<>nil) and (Edge2<>nil) then if Edge1.Crease<>Edge2.Crease then DataOK:=False;
                      for I:=2 to Rows-1 do if not Grid[I-2][0].IsRegularNURBSPoint(CheckFaces) then
                         DataOK:=False;
                   end;
                   if not DataOK then begin    // do not add the current column
                      for I:=1 to NFaces do Faces.AddSorted(TmpFaces[I-1]);
                      SearchLeft:=False;
                      for I:=1 to Rows do begin
                        for J:=1 to Cols do Grid[I-1][J-1]:=Grid[I-1][J];
                      end;
                   end else inc(Cols);
                 end else SearchLeft:=False;
              end;
              if Mode=amNURBS then begin
                 if not Grid[0][0].IsRegularNURBSPoint(CheckFaces) then begin
                    SearchLeft:=False;
                    SearchTop:=False;
                 end;
                 if not Grid[Rows-1][0].IsRegularNURBSPoint(CheckFaces) then begin
                    SearchLeft:=False;
                    SearchBottom:=False;
                 end;
                 if not Grid[Rows-1][Cols-1].IsRegularNURBSPoint(CheckFaces) then begin
                    SearchRight:=False;
                    SearchBottom:=False;
                 end;
                 if not Grid[0][Cols-1].IsRegularNURBSPoint(CheckFaces) then begin
                    SearchRight:=False;
                    SearchTop:=False;
                 end;
              end;
           end;
        end;
    begin
       CtrlFaces.Sort;
       CheckFaces:=TFasterList.Create;
       Checkfaces.AddList(CtrlFaces);
       while CtrlFaces.Count>0 do begin                   // find a corner face
          Face:=FindCornerFace;
          inc(ErrInd);
          if Face<>nil then begin
            Index:=CtrlFaces.SortedIndexOf(Face);
            if Index<>-1 then CtrlFaces.Delete(Index);
            if Face.Nopoints=4 then begin
               NCols:=2;
               NRows:=2;
               Setlength(Grid,NRows);
               Setlength(Grid[0],NCols);
               Setlength(Grid[1],NCols);
               Grid[0][1]:=Face.Point[0];
               Grid[0][0]:=Face.Point[1];
               Grid[1][0]:=Face.Point[2];
               Grid[1][1]:=Face.Point[3];

               DoAssemble(Grid,NCols,NRows,CtrlFaces);

               Newface.NCols:=NCols-1;
               NewFace.NRows:=NRows-1;
               Setlength(NewFace.Faces,NewFace.NRows);
               for I:=2 to NRows do begin
                  Setlength(NewFace.Faces[I-2],NewFace.NCols);
                  for J:=2 to NCols do begin
                     Face:=GetFace(Grid[I-2][J-1],Grid[I-2][J-2],Grid[I-1][J-2],Grid[I-1][J-1]);
                     if Face<>nil then begin
                        NewFace.Faces[I-2][J-2]:=Face;
                     end;
                  // else begin Raise Exception.Create('Error while assembling faces'+#32+IntToStr(ErrInd)); end;
                  end;
               end;
               AddFace(NewFace);
            end else begin
               NewFace.NCols:=1;
               NewFace.NRows:=1;
               Setlength(NewFace.Faces,NewFace.NRows);
               Setlength(NewFace.Faces[0],NewFace.NCols);
               NewFace.Faces[0][0]:=Face;
               AddFace(NewFace);
            end;
          end; //++//++// else Raise Exception.Create('No valid cornerface found!');
       end;
       Checkfaces.Destroy;
    end;
begin
   ToDoList:=TFasterlist.Create;
   DoneList:=TFasterlist.Create;
   NAssembled:=0;
   for I:=1 to Layers.Count do begin                   // use all visible faces
      Layer:=Layers[I-1];
      if Layer.Visible then begin
         ToDoList.Capacity:=ToDoList.Count+Layer.Count;
         ToDoList.AddList(Layer.FPatches);
      end;
   end;
   if ToDoList.Count>0 then begin
      while ToDoList.Count>0 do begin
         Face:=ToDoList[ToDoList.Count-1];
         ToDoList.Delete(ToDoList.Count-1);
         Current:=TFasterlist.Create;
         Current.Add(Face);
         FindAttachedFaces(Current,Face);
         DoneList.Add(Current);
      end;
      Capacity:=50;
      setlength(AssembledPatches,Capacity);
      for I:=1 to DoneList.Count do begin // Assign all groups to different layers
         Current:=DoneList[I-1];
         if Current.Count>0 then AssembleFaces(Current,AssembledPatches,NAssembled);
         Current.Destroy;
      end;
   end;
   ToDoList.Destroy;
   DoneList.Destroy;
end;

// Calculate Gauss. curvature in each point of the mesh and store it in a array

procedure SSurface.CalculateGaussCurvature;
var I: Integer; Point: SPoint;
begin
   if not build then Rebuild;
   SetLength( FGausCurvature,FPoints.Count );
   FPoints.Sort;
   FMinGaussCurvature:=0.0;
   FMaxGaussCurvature:=0.0;
   for I:=0 to FPoints.Count-1 do begin
      Point:=FPoints[I];
      FGausCurvature[I]:=Point.Curvature;
      if I=0 then begin FMinGaussCurvature:=FGausCurvature[I];
                        FMaxGaussCurvature:=FGausCurvature[I];
      end;
      if FGausCurvature[I]<FMinGaussCurvature then FMinGaussCurvature:=FGausCurvature[I];
      if FGausCurvature[I]>FMaxGaussCurvature then FMaxGaussCurvature:=FGausCurvature[I];
   end;
end;
function SSurface.FGetControlPoint(Index:Integer):SControlPoint;
   begin Result:=TObject(FControlpoints[index]) as SControlPoint; end;
function SSurface.FGetControlEdge(Index:Integer):SControlEdge;
   begin Result:=TObject(FControlEdges[index]) as SControlEdge; end;
function SSurface.FGetControlCurve(Index:Integer):SControlCurve;
   begin Result:=TObject(FControlCurves[index]) as SControlCurve; end;
function SSurface.FGetControlFace(Index:Integer):SControlFace;
   begin Result:=TObject(FControlFaces[index]) as SControlFace; end;
function SSurface.FGetGaussCurvatureCalculated:boolean;
   begin Result:=Build and (length(FGausCurvature)=FPoints.Count); end;
function SSurface.FGetLayer(Index:Integer):SLayer;
   begin Result:=FLayers[(Index+Flayers.Count) mod Flayers.Count];
   end;
function SSurface.FGetNoControlPoints:Integer;
   begin Result:=FControlPoints.Count; end;
function SSurface.FGetNoControlEdges:Integer;
   begin Result:=FControlEdges.Count; end;
function SSurface.FGetNoControlCurves:Integer;
   begin Result:=FControlCurves.Count; end;
function SSurface.FGetNoControlFaces:Integer;
   begin Result:=FControlFaces.Count; end;
function SSurface.FGetNoLayers:Integer;
   begin Result:=FLayers.Count; end;
function SSurface.FGetNoSelectedControlCurves:Integer;
   begin Result:=FSelectedControlCurves.Count; end;
function SSurface.FGetNoSelectedControlEdges:Integer;
   begin Result:=FSelectedControlEdges.Count; end;
function SSurface.FGetNoSelectedControlFaces:Integer;
   begin Result:=FSelectedControlFaces.Count; end;
function SSurface.FGetNoSelectedControlPoints:Integer;
   begin Result:=FSelectedControlPoints.Count; end;

function SSurface.FGetNoFaces:Integer; Var I:Integer;
begin Result:=0;
   for I:=1 to NoControlfaces do inc(Result,ControlFace[I-1].ChildCount);
end;
function SSurface.FGetNoLockedPoints:Integer; var I:Integer;
begin Result:=0;
   for I:=1 to NoControlPoints do if ControlPoint[I-1].Locked then inc(Result);
end;
function SSurface.FGetPoint(Index:Integer):SPoint;
begin if FPoints.Count>0 then Result:=FPoints[index]
                         else Result:=FControlpoints[index];
end;
function SSurface.FGetEdge(Index:Integer):SEdge;
begin if FEdges.Count>0 then Result:=FEdges[index]
                        else Result:=FControlEdges[index];
end;
function SSurface.FGetNoPoints:Integer;
begin if FPoints.Count>0 then Result:=FPoints.Count
                         else Result:=FControlpoints.Count;
end;

function SSurface.FGetNoSelectedLockedPoints:Integer;
var I:Integer;
begin Result:=0;
   for I:=1 to NoSelectedControlPoints do if SelectedControlPoint[I-1].Locked then inc(Result);
end;
function SSurface.FGetNoEdges:Integer;
begin if FEdges.Count>0 then Result:=FEdges.Count
                        else Result:=FControlEdges.Count;
end;
function SSurface.FGetSelectedControlCurve(Index:Integer):SControlCurve;
   begin Result:=FSelectedControlCurves[index]; end;
function SSurface.FGetSelectedControlEdge(Index:Integer):SControlEdge;
   begin Result:=FSelectedControlEdges[index]; end;
function SSurface.FGetSelectedControlFace(Index:Integer):SControlFace;
   begin Result:=FSelectedControlfaces[index]; end;
function SSurface.FGetSelectedControlPoint(Index:Integer):SControlPoint;
   begin Result:=FSelectedControlPoints[index]; end;
function SSurface.FRequestNewLayerID:Integer;
   begin inc(FLastusedLayerID); Result:=FLastusedLayerID; end;

procedure SSurface.FSetActiveLayer(Val:SLayer);
begin
   FActiveLayer:=Val;
   if assigned(OnChangeActiveLayer) then OnChangeActiveLayer(self,FActiveLayer);
end;

procedure SSurface.FSetBuild(Val:Boolean);
var I : Integer;
begin
   inherited FSetBuild(Val);
   if not Val then begin
      ClearFaces;
      for I:=1 to NoControlCurves do ControlCurve[I-1].Build:=False;
      FCurrenSLevel:=0;
      Setlength(FGausCurvature,0);
      FMinGaussCurvature:=0.0;
      FMaxGaussCurvature:=0.0;
   end;
end;

procedure SSurface.FSetDivSec(val:byte);
    begin if Val>4 then Val:=4;
          if Val<>FDivSec then begin
                  FDivSec:=val; Build:=False; end;
end;
procedure SSurface.FSetFShowControlNet(Val:Boolean);
    begin if Val<>ShowControlNet then ShowControlNet:=Val; end;

procedure SSurface.FSeSMode(val:SMode);
begin
   if val<>FSubdivisionMode then begin
      FSubdivisionMode:=val;
      Build:=False;
   end;
end;

function SSurface.AddControlFace
( Points:VectorArray; NoPoints:Integer ): SControlFace;
var I,J,N: Integer;
    P: Vector;
    Edge: SEdge;
    Point,Prev: SPoint;
    dist,MaxError: Real;
    InValidFace: boolean;
begin                                                   // Remove double points
   I:=0;
   MaxError:=1/Power(10,Decimals);
   while I<NoPoints-1 do begin J:=I+1;
      while J<NoPoints do begin
         Dist:=Abs(Points[I]-Points[j]);
         if Dist<=MaxError then begin
            for N:=J to NoPoints-2 do Points[N]:=Points[N+1];
            Dec(NoPoints);
         end else Inc(J);
      end; Inc(I);
   end;
   Prev:=nil;
   if NoPoints>2 then begin
      Result:=SControlFace.Create(Self);
      //P1:=Points[NoPoints-1];
      //Prev:=AddControlPoint(Decimals,P1);
      for I:=1 to NoPoints do begin
         P:=Points[I-1];
         Point:=AddControlPoint(P);
         Result.AddPoint(Point);
         if I>1 then begin
            Edge:=AddControlEdge(Prev,Point);
            Edge.AddFace(Result);
         end;
         Prev:=Point;
      end;
      Point:=Result.Point[0];
      Edge:=AddControlEdge(Prev,Point);
      Edge.AddFace(Result);
      // Check if a point refers to the same face more than once ==> invalid face
      InValidFace:=False;
      for I:=1 to Result.Nopoints do begin
         N:=0;
         Point:=Result.Point[I-1];
         for J:=1 to Point.NoFaces do if Point.Face[J-1]=Result then Inc(N);
         if N>1 then InvalidFace:=True;
      end;
      if (Result.Nopoints<3) or (InvalidFace) then begin // Delete invalid controlfaces
         for J:=1 to Result.Nopoints do begin
            Result.Point[J-1].DeleteFace(Result);
            if J=1 then Edge:=EdgeExists(Result.Point[Result.NoPoints-1],Result.Point[J-1])
                   else Edge:=EdgeExists(Result.Point[J-2],Result.Point[J-1]);
            if Edge<>nil then begin
               Edge.DeleteFace(Result);
               Edge.StartPoint.DeleteEdge(Edge);
               Edge.StartPoint.DeleteFace(Result);
               Edge.EndPoint.DeleteEdge(Edge);
               Edge.EndPoint.DeleteFace(Result);
            end;
         end;
         Result.Destroy;
         Result:=nil;
      end else FControlFaces.Add(Result);
   end else Result:=nil;
   Build:=False;
end;

function SSurface.AddControlEdge(P1,P2:SPoint):SControlEdge;
var Edge : SControlEdge;
begin
   Edge:=EdgeExists(P1,P2) as SControlEdge;
   if Edge=nil then begin
      Edge:=SControlEdge.Create(Self);
      Edge.Startpoint:=P1;
      Edge.Endpoint:=P2;
      Edge.FControlEdge:=True;
      P1.AddEdge(Edge);
      P2.AddEdge(Edge);
      FControlEdges.Add(Edge);
        // Result:=Edge;
   end; // else
   Result:=Edge;
end;

procedure SSurface.AddControlCurve(Curve:SControlCurve);
begin
   FControlCurves.Add(Curve);
   Curve.Owner:=self;
   Build:=False;
end;

function SSurface.AddControlFace
    ( Points:TFasterList; CheckEdges:Boolean; Layer:SLayer
    ):SControlFace;
var I,J,N,Index: Integer;
    P1,P2: SControlPoint;
    Edge: SControlEdge;
    Face: SControlFace;
    FaceExists: boolean;
begin
   Result:=nil;
   if Points.Count>2 then if Points[Points.Count-1]=Points[0] then Points.Delete(Points.Count-1);
   if Points.Count>2 then begin
      if Points[Points.Count-1]=Points[0] then Points.Delete(Points.Count-1);
      // Check if another patch with the same vertices exists
      FaceExists:=False;
      I:=1;
      while I<=Points.Count do begin
         P1:=Points[I-1];
         J:=1;
         while J<=P1.NoFaces do begin
            Face:=P1.Face[J-1] as SControlFace;
            if Face.Nopoints=Points.Count then begin
               FaceExists:=True;
               N:=1;
               while (N<=Points.Count) and (FaceExists) do begin
                  Index:=Face.FPoints.IndexOf(Points[N-1]);
                  if Index=-1 then begin
                     N:=Points.Count;
                     FaceExists:=False;
                  end else Inc(N);
               end;
               if FaceExists then begin Result:=nil; exit; end;
            end;  inc(J);
         end;     Inc(I);
      end;
      if FaceExists then begin Result:=nil; exit; end;
      Result:=SControlFace.Create(Self);
      if Layer=nil then Layer:=self.Layer[0];
      Result.FLayer:=layer;
      Layer.AddControlFace(Result);
      Result.FPoints.Capacity:=Points.Count;
      FControlFaces.Add(Result);

      P1:=Points[Points.Count-1];
      for I:=1 to Points.Count do begin
         P2:=Points[I-1];
         P2.FFaces.Add(Result);
         Result.FPoints.Add(P2);
         Edge:=EdgeExists(P1,P2) as SControlEdge;
         if Edge=nil then begin
            Edge:=SControlEdge.Create(Self);
            Edge.Startpoint:=P1;
            Edge.Endpoint:=P2;
            Edge.FControlEdge:=True;
            P1.FEdges.Add(Edge);
            P2.FEdges.Add(Edge);
            FControlEdges.Add(Edge);
            Edge.FFaces.Add(Result);
            Edge.Crease:=true;
         end else begin
            Edge.AddFace(Result);
            if CheckEdges then Edge.Crease:=Edge.NoFaces<2;
         end;
         P1:=P2;
      end;
      if Result.Nopoints<3 then begin
         Result.Destroy;
         Result:=nil;
      end else Build:=False;
   end;
end;

function SSurface.AddControlFace(Points:TFasterList;CheckEdges:Boolean):SControlFace;
   begin Result:=AddControlFace(Points,CheckEdges,nil); end;

function SSurface.AddControlFace(Points:TList;CheckEdges:Boolean):SControlFace;
var Tmp: TFasterlist; I: Integer;
begin
   Tmp:=TFasterList.Create;
   Tmp.Capacity:=Points.Count;
   for I:=1 to Points.Count do Tmp.Add(Points[I-1]);
   Result:=AddControlFace(Tmp,CheckEdges,nil);
   Tmp.Destroy;
end;

procedure SSurface.Clear;
var I: Integer; Layer: SLayer;
begin
   inherited Clear;
   for I:=1 to FControlPoints.Count do ControlPoint[I-1].Destroy; FControlPoints.Clear;
   for I:=1 to NoControlFaces do ControlFace[I-1].Destroy; FControlFaces.Clear;
   for I:=1 to NoControlEdges do ControlEdge[I-1].Destroy; FControlEdges.Clear;
   for I:=1 to NoControlCurves do ControlCurve[I-1].Destroy; FControlCurves.Clear;
   for I:=1 to FEdges.Count do Edge[I-1].Destroy;            FEdges.Clear;
   for I:=1 to FPoints.Count do Point[I-1].Destroy;          FPoints.Clear;
   for i:=1 to NoLayers do self.Layer[I-1].Destroy;          FLayers.Clear;
   if assigned(OnChangeLayerData) then OnChangeLayerData(self);
   FLastusedLayerID:=-1;
   // delete lists with selected items
   FSelectedControlPoints.Clear;
   FSelectedControlEdges.Clear;
   FSelectedControlFaces.Clear;
   FSelectedControlCurves.Clear;
   // Add one default layer and set it to active
   Layer:=AddNewLayer;
   ActiveLayer:=Layer;
   Build:=False;
   DrawMirror:=False;
   ShowControlNet:=True;
   ShowInteriorEdges:=False;
   FInitialized:=False;
   FDivSec:=1;
   ShowNormals:=True;
   Sp.UColorIs:=false;                               // ShadeUnderWater:=False;
   MainframeLocation:=1e8;
end;

procedure SSurface.ClearFaces;
var I : integer;
begin
   for I:=1 to NoControlFaces do Controlface[I-1].ClearChildren; // deletes children and rendermesh
   for I:=1 to FEdges.Count do Edge[I-1].Destroy;   FEdges.Clear;
   for I:=1 to FPoints.Count do Point[I-1].Destroy; FPoints.Clear;
   for I:=1 to NoControlFaces do Controlface[I-1].FControlEdges.Clear;
end;

procedure SSurface.Clearselection;
// Deselect all selected items at once
begin
   FSelectedControlPoints.Clear;
   FSelectedControlEdges.Clear;
   FSelectedControlFaces.Clear;
   FSelectedControlCurves.Clear;
   if Assigned(OnSelectItem) then OnSelectItem(nil);
end;

procedure SSurface.ConvertToGrid(Input:TFaceGrid;var Cols,Rows:Integer;var Grid:SGrid);
var CtrlFace: SControlFace;
    Faces,Backup: TFasterList;
    Face: SFace;
    I,J,N,Ind  : Integer;
        procedure DoAssemble(var Grid:SGrid;var Cols,Rows:Integer;Faces:TFasterList);
        var SearchBottom,SearchTop,SearchLeft,SearchRight: Boolean;
            Counter,Index,I,J,NFaces: Integer;
            Edge: SEdge;
            Face: SFace;
            TmpFaces: array of SFace;

            function ValidFace(Face:Sface):Boolean;
            var I,J,N,Index: Integer; Tmp: SFace;
            begin Result:=False;
               if Face.Nopoints=4 then begin
                  Index:=Faces.SortedIndexOf(Face);
                  if Index<>-1 then begin Result:=True;
                     for I:=1 to NFaces do if TmpFaces[I-1]=face then begin
                        result:=false;
                        exit;
                     end;
                     if NFaces>0 then begin  // must also be connected to previous face
                        Tmp:=TmpFaces[NFaces-1];
                        N:=0;
                        for J:=1 to Face.Nopoints do begin
                           if Tmp.IndexOfPoint(Face.Point[J-1])<>-1 then inc(N);
                        end;
                        Result:=N>1;
                     end;
                  end;
               end;
            end;
        begin
           Counter:=0;
           SearchBottom:=True;
           SearchTop:=True;
           SearchRight:=True;
           SearchLeft:=True;
           while ((SearchBottom) or (SearchTop) or (SearchRight)
              or (SearchLeft)) and (Faces.Count>0)
           do begin
              inc(Counter);
              if Counter>4 then Counter:=1;
              if (Counter=1) and (SearchBottom) then begin
                 Setlength(TmpFaces,Cols);
                 NFaces:=0;
                 for I:=2 to Cols do begin
                    Edge:=EdgeExists(Grid[Rows-1][I-2],Grid[Rows-1][I-1]);
                    if Edge<>nil then for J:=1 to Edge.NoFaces do begin
                       Face:=Edge.Face[J-1];
                       if ValidFace(Face) then begin
                          TmpFaces[NFaces]:=Face;
                          inc(NFaces);
                          break;
                       end;
                    end;
                    if NFaces<>I-1 then break;
                 end;
                 if NFaces=Cols-1 then begin          // search was successfull
                   for I:=1 to NFaces do begin
                      Setlength(Grid,Rows+1);
                      Setlength(Grid[Rows],Cols);
                      Face:=TmpFaces[I-1];
                      Index:=Faces.SortedIndexOf(Face);
                      if Index<>-1 then Faces.Delete(index);

                      Index:=Face.IndexOfPoint(Grid[Rows-1][I]);
                      Index:=(Index+1) mod Face.Nopoints;
                      if Face.Point[index]=Grid[Rows-1][I-1] then begin
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[Rows][I-1]:=Face.Point[index];
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[Rows][I]:=Face.Point[index];
                      end else begin
                         Index:=Face.IndexOfPoint(Grid[Rows-1][I-1]);
                         Index:=(Index+1) mod Face.Nopoints;
                         if Face.Point[index]=Grid[Rows-1][I] then begin
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[Rows][I]:=Face.Point[index];
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[Rows][I-1]:=Face.Point[index];
                         end;
                      end;
                   end;   inc(Rows);
                 end else SearchBottom:=False;
              end else if (Counter=2) and (SearchRight) then begin
                 Setlength(TmpFaces,Rows);
                 NFaces:=0;
                 for I:=2 to Rows do begin
                    Edge:=EdgeExists(Grid[I-1][Cols-1],Grid[I-2][Cols-1]);
                    if Edge<>nil then for J:=1 to Edge.NoFaces do begin
                       Face:=Edge.Face[J-1];
                       if ValidFace(Face) then begin
                          TmpFaces[NFaces]:=Face;
                          inc(NFaces);
                          break;
                       end;
                    end;
                    if NFaces<>I-1 then break;
                 end;
                 if NFaces=Rows-1 then begin          // search was successfull
                   for I:=1 to Rows do begin
                      Setlength(grid[I-1],Cols+1);
                      Grid[I-1][Cols]:=nil;
                   end;
                   for I:=1 to NFaces do begin
                      Face:=TmpFaces[I-1];
                      Index:=Faces.SortedIndexOf(Face);
                      if Index<>-1 then Faces.Delete(index);
                      Index:=Face.IndexOfPoint(Grid[I-1][Cols-1]);
                      Index:=(Index+1) mod Face.Nopoints;
                      if Face.Point[index]=Grid[I][Cols-1] then begin
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[I][Cols]:=Face.Point[index];
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[I-1][Cols]:=Face.Point[index];
                      end else begin
                         Index:=Face.IndexOfPoint(Grid[I][Cols-1]);
                         Index:=(Index+1) mod Face.Nopoints;
                         if Face.Point[index]=Grid[I-1][Cols-1] then begin
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[I-1][Cols]:=Face.Point[index];
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[I][Cols]:=Face.Point[index];
                         end;
                      end;
                   end;
                   inc(Cols);
                 end else SearchRight:=False;
              end else if (Counter=3) and (SearchTop) then begin
                 Setlength(TmpFaces,Cols);
                 NFaces:=0;
                 for I:=2 to Cols do begin
                    Edge:=EdgeExists(Grid[0][I-2],Grid[0][I-1]);
                    if Edge<>nil then for J:=1 to Edge.NoFaces do begin
                       Face:=Edge.Face[J-1];
                       if ValidFace(Face) then begin
                          TmpFaces[NFaces]:=Face;
                          inc(NFaces);
                          break;
                       end;
                    end;
                    if NFaces<>I-1 then break;
                 end;
                 if NFaces=Cols-1 then begin          // search was successfull
                   Setlength(Grid,Rows+1);
                   Setlength(Grid[Rows],Cols);
                   for I:=Rows downto 1 do
                   for J:=1 to Cols do Grid[I][J-1]:=Grid[I-1][J-1];

                   for I:=1 to Cols do Grid[0][I-1]:=nil;
                   for I:=1 to NFaces do begin
                      Face:=TmpFaces[I-1];
                      Index:=Faces.SortedIndexOf(Face);
                      if Index<>-1 then Faces.Delete(index);

                      Index:=Face.IndexOfPoint(Grid[1][I-1]);
                      Index:=(Index+1) mod Face.Nopoints;
                      if Face.Point[index]=Grid[1][I] then begin
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[0][I]:=Face.Point[index];
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[0][I-1]:=Face.Point[index];
                      end else begin
                         Index:=Face.IndexOfPoint(Grid[1][I]);
                         Index:=(Index+1) mod Face.Nopoints;
                         if Face.Point[index]=Grid[1][I-1] then begin
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[0][I-1]:=Face.Point[index];
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[0][I]:=Face.Point[index];
                         end;
                      end;
                   end;
                   inc(Rows);
                 end else SearchTop:=False;
              end else  if (Counter=4) and (SearchLeft) then begin
                 Setlength(TmpFaces,Rows);
                 NFaces:=0;
                 for I:=2 to Rows do begin
                    Edge:=EdgeExists(Grid[I-2][0],Grid[I-1][0]);
                    if Edge<>nil then
                    for J:=1 to Edge.NoFaces do begin
                       Face:=Edge.Face[J-1];
                       if ValidFace(Face) then begin
                          TmpFaces[NFaces]:=Face;
                          inc(NFaces);
                          break;
                       end;
                    end;
                    if NFaces<>I-1 then break;
                 end;
                 if NFaces=Rows-1 then begin          // search was successfull
                   for I:=1 to Rows do begin
                      Setlength(grid[I-1],Cols+1);
                      for J:=Cols downto 1 do Grid[I-1][J]:=Grid[I-1][J-1];
                      //Move(Grid[I-1][0],Grid[I-1][1],Cols*SizeOf(Pointer));
                   end;
                   for I:=1 to NFaces do begin
                      Face:=TmpFaces[I-1];
                      Index:=Faces.SortedIndexOf(Face);
                      if Index<>-1 then Faces.Delete(index);
                      Index:=Face.IndexOfPoint(Grid[I][1]);
                      Index:=(Index+1) mod Face.Nopoints;
                      if Face.Point[index]=Grid[I-1][1] then begin
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[I-1][0]:=Face.Point[index];
                         Index:=(Index+1) mod Face.Nopoints;
                         Grid[I][0]:=Face.Point[index];
                      end else begin
                         Index:=Face.IndexOfPoint(Grid[I-1][1]);
                         Index:=(Index+1) mod Face.Nopoints;
                         if Face.Point[index]=Grid[I][1] then begin
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[I][0]:=Face.Point[index];
                            Index:=(Index+1) mod Face.Nopoints;
                            Grid[I-1][0]:=Face.Point[index];
                         end;
                      end;
                   end; inc(Cols);
                 end else SearchLeft:=False;
              end;
           end;
        end;
begin
   Cols:=0;
   Rows:=0;
   if (Input.NCols=0) or (Input.NRows=0) then exit;
   N:=Input.Faces[0][0].ChildCount; // assmeble all childfaces in one temp. sorted list
   backup:=TFasterList.Create;
   backup.Capacity:=Input.NCols*Input.NRows*N;
   for I:=1 to Input.NRows do begin
      for J:=1 to Input.NCols do begin
         CtrlFace:=Input.Faces[I-1][J-1];
         backup.AddList(Ctrlface.FChildren);
      end;
   end;
   backup.Sort;
   if backup.Count>0 then begin
      Faces:=TFasterList.Create; Ind:=0;
      repeat
         Faces.Assign( Backup );
         inc(Ind);
         Face:=Faces[Ind-1];
         Faces.Delete(Ind-1);
         Rows:=2;
         Cols:=2;
         Setlength( Grid,Rows );
         Setlength( Grid[0],Cols );
         Setlength( Grid[1],Cols );
         grid[0][1]:=Face.Point[0];
         grid[0][0]:=Face.Point[1];
         grid[1][0]:=Face.Point[2];
         grid[1][1]:=Face.Point[3];
         DoAssemble( Grid,Cols,Rows,Faces );
      until (Faces.Count=0) or (Ind=Backup.Count);
//      if Faces.Count<>0 then  ShowMessage('Could not establish the entire grid!');
      Faces.Destroy;
      Backup.Destroy;
   end;
end;

procedure SSurface.Edge_Connect;
var V1,V2: SControlPoint; { Face: SControlFace; Edge: SControlEdge; }
    I,J,f1,f2: Integer;
begin
   if NoSelectedControlPoints>1 then begin
      for I:=NoSelectedControlPoints-1 downto 0 do
      for J:=NoSelectedControlPoints-1 downto 0 do if I<>J then begin
           V1:=SelectedControlPoint[I];
           V2:=SelectedControlPoint[J];
         if EdgeExists(V1,V2)=nil then
          for f1:=0 to V1.NoFaces-1 do
          for f2:=0 to V2.NoFaces-1 do
           if V1.Face[f1]=V2.Face[f2] then begin
             (V1.Face[f1] as SControlFace).InsertEdge(V1,V2); break;
//           (V2.Face[f2] as SControlFace).InsertEdge(V2,V1); break;
           end;
      end;
      for I:=NoSelectedControlPoints downto 1
        do SelectedControlPoint[I-1].Selected:=False;
   end;
end;

procedure SSurface.ExportFEFFile(Strings:TStringList);
var I: Integer;
begin                                                  // Add layer information
   Strings.Add(IntToStr(NoLayers));
   for I:=0 to NoLayers-1 do begin
      Strings.Add(Layer[I].Name);
      Strings.Add(IntToStr(Layer[I].LayerID)+#32+
      I2S(Cardinal(Layer[I].Color and $FFFFFF)+(Cardinal(255-Layer[I].AlphaBlend) shl 24))
//      +#32+IntToStr(Layer[I].Color)
        +#32+BoolToStr(Layer[I].Visible)
        +#32+BoolToStr(Layer[I].Developable)
        +#32+BoolToStr(Layer[I].Symmetric)
        +#32+BoolToStr(Layer[I].FUseForIntersections)
        +#32+BoolToStr(Layer[I].FUseInHydrostatics)
        +#32+BoolToStr(Layer[I].FShowInLinesplan)
        +#32+FloatToDec(Layer[I].MaterialDensity,8)
        +#32+FloatToDec(Layer[I].Thickness,8));
   end; // first sort controlpoints for faster acces of function ( Indexof() )
   FControlPoints.Sort;
   Strings.Add(IntToStr(NoControlPoints));
   for I:=0 to NoControlPoints-1 do ControlPoint[I].SaveToStream(Strings);
   Strings.Add(IntToStr(NoControlEdges));
   for I:=0 to NoControlEdges-1 do ControlEdge[I].SaveToStream(Strings);
   Strings.Add(IntToStr(NoControlFaces));
   for I:=0 to NoControlFaces-1 do ControlFace[I].SaveToStream(Strings);
end;

procedure SSurface.ImportObjFile( Strings: TStringList );
var
  I,J,K,Index: integer; Str: String;
// CFace: SControlFace; CPoint: SCOntrolPoint;
  CPoints,FacePoints: TFasterList; //SControlPoint;
  C3d: Vector;
  Faces: TStringList;
  Vindex: array of String;
begin
//   CPoints:=SControlPoint.Create;
//   FacePoints:=SControlPoint.Create;
   CPoints:=TFasterList.Create;
   FacePoints:=TFasterList.Create;
  Faces:=TStringList.Create;
//  Self.IsLoading:=true;
  for I:=0 to Strings.Count-1 do begin
    Str:=BlankOff( Strings[I] );
    if Str.StartsWith( '#' ) then {пропуск комментария} else
    if Str.StartsWith( 'v ' ) then begin Str[1]:=' ';
      C3d.X:=GetFloat( Str );    //X : -2
      C3d.Z:=GetFloat( Str );    //Z :  1
      C3d.Y:=GetFloat( Str );    //Y :  3
      CPoints.Add( AddControlPoint( C3d ) );
    end else
    if Str.StartsWith('f ') then Faces.Append( Str );
  end;
  for I:=0 to Faces.Count-1 do begin SetLength( Vindex,0 ); FacePoints.Clear;
    Vindex:=Faces[I].Split( [' '] );
    K:=Length( Vindex )-1;           //?? с замыкаением контура много?угольника
    if K>2 then begin
      for J:=1 to K do begin
        Str:=Vindex[J].Replace( '/',' ' );
        Index:=GetInteger( Str );                              // впереди 'f'
        FacePoints.Add( CPoints[Index-1] );
      end;
      if  ( FacePoints[0]<>FacePoints[1] )    // нулевая площадь - приемлема
      and ( FacePoints[1]<>FacePoints[2] )    // совпедение точек - недопустимо
      and ( FacePoints[2]<>FacePoints[0] )
      then AddControlFace( FacePoints,True,Self.Layer[0] );
    end;
  end;                                        //  Self.IsLoading:=false;
  SetLength( Vindex,0 );
  CPoints.Free;
  FacePoints.Free;
  Faces.Free;
end;

procedure SSurface.ExportObjFile(ExportControlNet:Boolean;Strings:TStringList);
var I,J,K,Index: Integer; C3D: Vector;
    Tmp: TFasterList;
    CFace: SControlFace;
    Child: SFace;
    P: SPoint;
    Str: string;
begin
   if not ExportControlNet then begin   // export subdivided surface
      if not build then ReBuild;        // first sort controlpoints for faster acces of function (Indexof())
      Strings.Add('# free!Ship export.obj');
      FPoints.Sort;                     // Create points for portside
      Tmp:=TFasterList.Create;
      Tmp.Capacity:=NoPoints;
      for I:=0 to NoPoints-1 do begin
         C3d:=Point[I].Coordinate;
         Strings.Add(format('v %07.04f %07.04f %07.04f',[C3d.x,C3d.z,C3d.y]));
         if C3d.y>0 then Tmp.Add(Point[I]);  /// ????
      end;
      if DrawMirror then begin                    // Create points for portside
         Tmp.Sort;
         for I:=0 to Tmp.Count-1 do begin
            P:=Tmp[I]; C3d:=P.Coordinate;
            Strings.Add(format('v %07.04f %07.04f %07.04f',[C3d.x,C3d.z,-C3d.y])); //(-Y)!
         end;
      end;
      for I:=0 to NoControlFaces-1 do begin CFace:=ControlFace[I];
         if CFace.Layer.Visible then begin
            for J:=0 to CFace.ChildCount-1 do begin                 // portside
               Str:='f';
               Child:=CFace.Child[J];
               for K:=0 to Child.FPoints.Count-1 do begin
                  Index:=FPoints.SortedIndexOf(Child.FPoints[K]);
                  if Index<>-1 then Str:=Str+#32+IntToStr(index+1);
               end;
               Strings.Add(Str);
               if (CFace.Layer.Symmetric) and (DrawMirror) then begin // Starboard side
                  Str:='f';
                  Child:=CFace.Child[J];
                  for K:=Child.FPoints.Count-1 downto 0 do begin
                     if Child.Point[K].Coordinate.Y>0 then begin
                        Index:=Tmp.SortedIndexOf(Child.Point[K])+NoPoints;
                     end else Index:=FPoints.SortedIndexOf(Child.FPoints[K]);
                     Str:=Str+#32+IntToStr(index+1);
                  end; Strings.Add(Str);
               end;
            end;
         end;
      end;             Tmp.Destroy;
   end else begin                                 // export the controlnet only
      if not Build then ReBuild; // first sort controlpoints for faster acces of function (Indexof())
      Strings.Add('# free!Ship model');
      FControlPoints.Sort;                 // Create ControlPoints for portside
      Tmp:=TFasterList.Create;
      Tmp.Capacity:=NoControlPoints;
      for I:=0 to NoControlPoints-1 do begin
         Strings.Add('v'+#32+FloatToDec(ControlPoint[I].Coordinate.y,4)
                        +#32+FloatToDec(ControlPoint[I].Coordinate.z,4)
                        +#32+FloatToDec(ControlPoint[I].Coordinate.x,4));
         if ControlPoint[I].Coordinate.y>0 then Tmp.Add(ControlPoint[I]);
      end;
      if DrawMirror then begin            // Create ControlPoints for portside
         Tmp.Sort;
         for I:=0 to Tmp.Count-1 do begin P:=Tmp[I];
            Strings.Add('v'+#32+FloatToDec(-P.Coordinate.y,4)
                           +#32+FloatToDec(P.Coordinate.z,4)
                           +#32+FloatToDec(P.Coordinate.x,4));
         end;
      end;
      for I:=0 to NoControlFaces-1 do begin CFace:=ControlFace[I];
         if CFace.Layer.Visible then begin                          // portside
            Str:='f';
            for K:=0 to Cface.FPoints.Count-1 do begin
               Index:=FControlPoints.SortedIndexOf(Cface.FPoints[K]);
               if Index<>-1 then Str:=Str+#32+IntToStr(index+1);
            end;
            Strings.Add(Str);
            if (CFace.Layer.Symmetric) and (DrawMirror) then begin // Starboard side
               Str:='f';
               for K:=Cface.FPoints.Count-1 downto 0 do begin
                  if Cface.Point[K].Coordinate.Y>0 then begin
                     Index:=Tmp.SortedIndexOf(Cface.Point[K])+NoControlPoints;
                  end else Index:=FControlPoints.SortedIndexOf(Cface.FPoints[K]);
                  Str:=Str+#32+IntToStr(index+1);
               end; Strings.Add(Str);
            end;
         end;
      end; Tmp.Destroy;
   end;
end;

procedure SSurface.Extents(Var Min,Max : Vector);
var I: Integer;
begin
   if not build then Rebuild;
   if NoControlFaces>0 then begin
      for I:=1 to NoLayers do Layer[I-1].Extents(Min,Max);
      for I:=1 to NoControlPoints
      do if ControlPoint[I-1].NoFaces=0 then begin
         MinMax(ControlPoint[I-1].FCoordinate,Min,Max);
      end;
   end else begin
      MinMax(FMin,Min,Max);
      MinMax(FMax,Min,Max);
   end;
end;

procedure SSurface.ExtrudeEdges(Edges:TFasterList;Direction:Vector);
var I,INdex,NoEdges,NoVertices: Integer;
    Face: SControlFace;
    Edge,Tmp: SControlEdge;
    Point1,Point2: SControlPoint;
    Vertices,Newedges,Points: TFasterList;
begin
   Vertices:=TFasterList.Create; // first assemble all points
   for I:=1 to Edges.Count do begin
      Edge:=Edges[I-1];
      if Vertices.IndexOf(Edge.StartPoint)=-1 then Vertices.Add(Edge.StartPoint);
      if Vertices.IndexOf(Edge.EndPoint)=-1 then Vertices.Add(Edge.EndPoint);
   end;
   NoEdges:=FControlEdges.Count;
   NoVertices:=FControlPoints.Count;
   NewEdges:=TFasterList.Create;  // create all new extruded points
   for I:=1 to Vertices.Count do begin
      Point1:=Vertices[I-1];
      Point2:=SControlPoint.Create(self);
      FControlPoints.Add(Point2);
      Point2.Coordinate:=Point1.Coordinate+Direction;
      Vertices.Objects[I-1]:=Point2;
   end;
   Points:=TFasterList.Create;
   for I:=1 to Edges.Count do begin
      Edge:=Edges[I-1];
      Points.Clear;
      Points.Add(Edge.EndPoint);
      Points.Add(Edge.StartPoint);
      Point1:=nil;
      Point2:=nil;
      Index:=Vertices.IndexOf(Edge.StartPoint);
      if Index<>-1 then begin
         Point1:=Vertices.Objects[index];
         Points.Add(Point1);
      end;
      Index:=Vertices.IndexOf(Edge.EndPoint);
      if Index<>-1 then begin
         Point2:=Vertices.Objects[index];
         Points.Add(Point2);
      end;
      Face:=AddControlFace(Points,True);
      Face.Layer:=self.ActiveLayer;
      if (Point1<>nil) and (Point2<>nil) then begin
         Tmp:=EdgeExists(Point1,Point2) as SControlEdge;
         if Tmp<>nil then NewEdges.Add(Tmp);
      end;
      if (Edge.StartPoint.VertexType=svCorner) and (Point1<>nil) then begin
         Tmp:=EdgeExists(Edge.StartPoint,Point1) as SControlEdge;
         if Tmp<>nil then Tmp.Crease:=true;
      end;
      if (Edge.EndPoint.VertexType=svCorner) and (Point2<>nil) then begin
         Tmp:=EdgeExists(Edge.EndPoint,Point2) as SControlEdge;
         if Tmp<>nil then Tmp.Crease:=true;
      end;
      Edge.Crease:=true;
   end;
   Points.Destroy;
   Edges.Clear; // return the new edges
   for I:=1 to NewEdges.Count do Edges.Add(Newedges[I-1]);
   Newedges.Destroy;
   Vertices.Destroy;
   Initialize(NoVertices+1,NoEdges+1,NoControlFaces+1);
   Build:=False;
end;

procedure SSurface.CalculateIntersections(Plane:Plate;Faces,Destination:TFasterList);
type IntersectionData = record
         Point    : Vector;
         Knuckle  : Boolean;
         Edge     : SEdge;
     end;
     TSegment  = record
         StartP,EndP:IntersectionData;
     end;

var I,J,K,N,M,ArrayLength,NoPoints,NSegments,SegmCapacity: Integer;
    Edge       : SEdge;
    P1,P2,P3   : SPoint;
    CtrlFace   : SControlFace;
    Side1,Side2,Parameter: Real;
    Output     : Vector;
    Spline     : TSpline;
    Face,F2    : Sface;
    IntArray   : array of IntersectionData;
    Edges      : TFasterList;
    AddEdge    : Boolean;
    Segments   : array of TSegment;
    StartP,EndP: IntersectionData;
    Segment    : TSegment;
//  Skip,CenterPlane,InPlane: Boolean;  Size: Integer;
//  AbsSide1,AbsSide2: Real;            Copy: TSpline;
begin
   // first assemble all edges belonging to this set of faces
   Edges:=TFasterlist.Create;
   Edges.Capacity:=Faces.Count+100;
   ArrayLength:=10;
   Setlength(IntArray,ArrayLength);
// Size:=SizeOf(IntersectionData);
// CenterPlane:=(abs(abs(Plane.b)-1)<1e-5) and (abs(Plane.d)<1e-4);
   NSegments:=0;
   SegmCapacity:=50;
   Setlength(Segments,SegmCapacity);
   for I:=1 to Faces.Count do begin
      CtrlFace:=Faces[I-1];
      for J:=1 to Ctrlface.ChildCount do begin
         Face:=Ctrlface.Child[J-1];
         NoPoints:=0;
         P1:=Face.Point[Face.NoPoints-1];
         Side1:=Plane.A*P1.Coordinate.x+Plane.B*P1.Coordinate.y+Plane.C*P1.Coordinate.z+Plane.D;
         for K:=1 to Face.FPoints.Count do begin
            P2:=Face.FPoints[K-1];
            Side2:=Plane.A*P2.Coordinate.x+Plane.B*P2.Coordinate.y+Plane.C*P2.Coordinate.z+Plane.D;
            AddEdge:=False;
            if ((Side1<-1e-5) and (Side2>1e-5))
            or ((Side1>1e-5) and (Side2<-1e-5)) then begin
               // regular intersection of edge
               // add the edge to the list
               Parameter:=-side1/(side2-side1);
               Output.X:=P1.Coordinate.X+Parameter*(P2.Coordinate.X-P1.Coordinate.X);
               Output.Y:=P1.Coordinate.Y+Parameter*(P2.Coordinate.Y-P1.Coordinate.Y);
               Output.Z:=P1.Coordinate.Z+Parameter*(P2.Coordinate.Z-P1.Coordinate.Z);
               Inc(NoPoints);
               if NoPoints>ArrayLength then begin
                  Inc(ArrayLength,10);
                  Setlength(IntArray,ArrayLength);
               end;
               IntArray[NoPoints-1].Point:=Output;
               Edge:=EdgeExists(P1,P2);
               if Edge<>nil then begin
                  IntArray[NoPoints-1].Knuckle:=Edge.Crease;
                  IntArray[NoPoints-1].Edge:=Edge;
               end else begin
                  IntArray[NoPoints-1].Knuckle:=False;
                  IntArray[NoPoints-1].Edge:=nil;
               end;
            end else begin     // Does the edge lie entirely within the plane??
               if ((abs(side1)<=1e-5) and (abs(Side2)<=1e-5)) then begin
                  // If so then add this edge ONLY if:
                  // 1. The edge is a boundary edge
                  // 2. At least ONE of the attached faces does NOT lie in the plane
                  Edge:=EdgeExists(P1,P2);
                  if Edge<>nil then begin
                     if Edge.FFaces.Count=1 then AddEdge:=True else begin
                        for N:=1 to Edge.FFaces.Count do begin
                           F2:=Edge.FFaces[N-1];
                           for M:=1 to F2.FPoints.Count do begin
                              P3:=F2.Point[M-1];
                              Parameter:=Plane.A*P3.Coordinate.x+Plane.B*P3.Coordinate.y+Plane.C*P3.Coordinate.z+Plane.D;
                              if abs(Parameter)>1e-5 then begin
                                 AddEdge:=True;
                                 break;
                              end;
                           end;
                           if AddEdge then break;
                        end;
                     end;
                     if AddEdge then begin
                        if Edges.SortedIndexOf(Edge)=-1 then begin
                           Edges.AddSorted(Edge);
                           inc(NSegments);
                           if NSegments>SegmCapacity then begin
                              inc(SegmCapacity,75);
                              Setlength(Segments,SegmCapacity);
                           end;
                           Segments[NSegments-1].StartP.Point:=P1.FCoordinate;
                           Segments[NSegments-1].StartP.Edge:=Edge;
                           if not Edge.FCrease then Segments[NSegments-1].StartP.Knuckle:=P1.VertexType<>svRegular
                                               else Segments[NSegments-1].StartP.Knuckle:=P1.VertexType=svCorner;
                           Segments[NSegments-1].EndP.Point:=P2.FCoordinate;
                           Segments[NSegments-1].EndP.Edge:=Edge;
                           if not Edge.FCrease then Segments[NSegments-1].EndP.Knuckle:=P2.VertexType<>svRegular
                                               else Segments[NSegments-1].EndP.Knuckle:=P2.VertexType=svCorner;
                        end;
                     end;
                  end;
               end else if abs(Side2)<1e-5 then begin
                  Inc(NoPoints);
                  if NoPoints>ArrayLength then begin
                     Inc(ArrayLength,10);
                     Setlength(IntArray,ArrayLength);
                  end;
                  IntArray[NoPoints-1].Point:=P2.Coordinate;
                  IntArray[NoPoints-1].Knuckle:=P2.VertexType<>svRegular;
                  IntArray[NoPoints-1].Edge:=EdgeExists(P1,P2);
               end;
            end;
            P1:=P2;
            Side1:=Side2;
         end;
         if NoPoints>1 then begin
            if IntArray[0].Edge=IntArray[NoPoints-1].Edge then
            if Sqr(IntArray[0].Point-IntArray[NoPoints-1].Point)<1e-8 then dec(NoPoints);
            K:=2;
            while K<=NoPoints do begin
               if IntArray[K-1].Edge=IntArray[K-2].Edge then begin
                  if Sqr(IntArray[K-1].Point-IntArray[K-2].Point)<1e-8 then begin
                     Move(IntArray[K-1],IntArray[K-2],(NoPoints-K+1)*SizeOf(Vector));
                     dec(NoPoints);
                  end else inc(K);
               end else inc(K);
            end;
            for K:=2 to NoPoints do begin
               inc(NSegments);
               if NSegments>SegmCapacity then begin
                  inc(SegmCapacity,50);
                  Setlength(Segments,SegmCapacity);
               end;
               Segments[NSegments-1].StartP:=IntArray[K-2];
               Segments[NSegments-1].EndP:=IntArray[K-1];
            end;
         end;
      end;
   end;
   // convert segments into polylines
   Spline:=nil;
   while NSegments>0 do begin
      if Spline=nil then begin
         Spline:=TSpline.Create;
         Spline.Capacity:=NSegments;
         Destination.Add(Spline);
         Segment:=Segments[NSegments-1];
         Spline.Add(Segment.StartP.Point);
         Spline.Knuckle[Spline.nS-1]:=Segment.StartP.Knuckle;
         Spline.Add(Segment.EndP.Point);
         Spline.Knuckle[Spline.nS-1]:=Segment.EndP.Knuckle;
         StartP:=Segment.StartP;
         EndP:=Segment.EndP;
         dec(NSegments);
      end;
      AddEdge:=False;
      J:=1;
      while J<=NSegments do begin
         Segment:=Segments[J-1];
         if (EndP.Edge=Segment.StartP.Edge) then begin
            AddEdge:=Sqr(EndP.Point-Segment.StartP.Point)<1e-8;
            if AddEdge then begin
               Spline.Knuckle[Spline.nS-1]:=Segment.StartP.Knuckle or Spline.Knuckle[Spline.nS-1];
               Spline.Add(Segment.EndP.Point);
               Spline.Knuckle[Spline.nS-1]:=Segment.EndP.Knuckle;
               EndP:=Segment.EndP;
            end;
         end else if (EndP.Edge=Segment.EndP.Edge) then begin
            AddEdge:=Sqr(EndP.Point-Segment.EndP.Point)<1e-8;
            if AddEdge then begin
               Spline.Knuckle[Spline.nS-1]:=Segment.EndP.Knuckle or Spline.Knuckle[Spline.nS-1];
               Spline.Add(Segment.StartP.Point);
               Spline.Knuckle[Spline.nS-1]:=Segment.StartP.Knuckle;
               EndP:=Segment.StartP;
            end;
         end else if (StartP.Edge=Segment.StartP.Edge) then begin
            AddEdge:=Sqr(StartP.Point-Segment.StartP.Point)<1e-8;
            if AddEdge then begin
               Spline.Knuckle[0]:=Segment.StartP.Knuckle or Spline.Knuckle[0];
               Spline.Insert(0,Segment.EndP.Point);
               Spline.Knuckle[0]:=Segment.EndP.Knuckle;
               StartP:=Segment.EndP;
            end;
         end else if (StartP.Edge=Segment.EndP.Edge) then begin
            AddEdge:=Sqr(StartP.Point-Segment.EndP.Point)<1e-8;
            if AddEdge then begin
               Spline.Knuckle[0]:=Segment.EndP.Knuckle or Spline.Knuckle[0];
               Spline.Insert(0,Segment.StartP.Point);
               Spline.Knuckle[0]:=Segment.StartP.Knuckle;
               StartP:=Segment.StartP;
            end;
         end else if Segment.StartP.Edge=Segment.EndP.Edge then begin
            // special case, edge lies entirely in plane
            // perform more extensive test to check whether the two edges
            // are possibly connected
            if (StartP.Edge.Startpoint.FEdges.IndexOf(Segment.StartP.Edge)<>-1)
            or (StartP.Edge.Endpoint.FEdges.IndexOf(Segment.StartP.Edge)<>-1)
            or (EndP.Edge.Startpoint.FEdges.IndexOf(Segment.StartP.Edge)<>-1)
            or (EndP.Edge.Endpoint.FEdges.IndexOf(Segment.StartP.Edge)<>-1)
            then begin
               AddEdge:=Sqr(EndP.Point-Segment.StartP.Point)<1e-8;
               if AddEdge then begin
                  Spline.Knuckle[Spline.nS-1]:=Segment.StartP.Knuckle or Spline.Knuckle[Spline.nS-1];
                  Spline.Add(Segment.EndP.Point);
                  Spline.Knuckle[Spline.nS-1]:=Segment.EndP.Knuckle;
                  EndP:=Segment.EndP;
               end else begin
                  AddEdge:=Sqr(EndP.Point-Segment.EndP.Point)<1e-8;
                  if AddEdge then begin
                     Spline.Knuckle[Spline.nS-1]:=Segment.EndP.Knuckle or Spline.Knuckle[Spline.nS-1];
                     Spline.Add(Segment.StartP.Point);
                     Spline.Knuckle[Spline.nS-1]:=Segment.StartP.Knuckle;
                     EndP:=Segment.StartP;
                  end else begin
                     AddEdge:=Sqr(StartP.Point-Segment.StartP.Point)<1e-8;
                     if AddEdge then begin
                        Spline.Knuckle[0]:=Segment.StartP.Knuckle or Spline.Knuckle[0];
                        Spline.Insert(0,Segment.EndP.Point);
                        Spline.Knuckle[0]:=Segment.EndP.Knuckle;
                        StartP:=Segment.EndP;
                     end else begin
                        AddEdge:=Sqr(StartP.Point-Segment.EndP.Point)<1e-4;
                        if AddEdge then begin
                           Spline.Knuckle[0]:=Segment.EndP.Knuckle or Spline.Knuckle[0];
                           Spline.Insert(0,Segment.StartP.Point);
                           Spline.Knuckle[0]:=Segment.StartP.Knuckle;
                           StartP:=Segment.StartP;
                        end;
                     end;
                  end;
               end;
            end;
         end;
         if AddEdge then begin
            Move(Segments[J],Segments[J-1],(NSegments-J)*SizeOf(TSegment));
            dec(NSegments);
            J:=1;
            AddEdge:=false;
         end else inc(J);
      end;
      if not AddEdge then Spline:=nil;
   end;
   if Destination.Count>1 then begin
      Destination.Capacity:=Destination.Count;
      JoinSplineSegments( 0.01,False,Destination );
      for I:=Destination.Count downto 1 do begin // Remove tiny fragments of very small length
         Spline:=Destination[I-1];
         if Spline.nS>1 then begin
            Parameter:=Sqr(Spline.Min-Spline.Max);
            if Parameter<1e-3 then begin
               Spline.Destroy;
               Destination.Delete(I-1);
            end;
         end;
      end;
   end;
   Edges.Destroy;
end;

constructor SSurface.Create;
begin
   FControlPoints:=TFasterList.Create;
   FControlEdges:=TFasterList.Create;
   FControlFaces:=TFasterList.Create;
   FPoints:=TFasterList.Create;
   FEdges:=TFasterList.Create;
   FLayers:=TFasterList.Create;
   FControlCurves:=TFasterList.Create;
   FSelectedControlPoints:=TFasterList.Create;
   FSelectedControlEdges:=TFasterList.Create;
   FSelectedControlFaces:=TFasterList.Create;
   FSelectedControlCurves:=TFasterList.Create;
   ControlPointSize:=4;
   ShowCurvature:=True;
   ShowControlCurves:=True;
   FSubdivisionMode:=fmQuadTriangle;
   inherited Create;
end;

destructor SSurface.Destroy; var I: Integer;
begin Clear;           // Make sure to also destroy the default layer (layer 0)
   for I:=0 to NoLayers-1 do Layer[I].Destroy;
   FLayers.Clear;
   FControlFaces.Free;
   FControlEdges.Free;
   FControlPoints.Free;
   FEdges.Free;
   FPoints.Free;
   FLayers.Free;
   FControlCurves.Free;
   FSelectedControlPoints.Free;
   FSelectedControlEdges.Free;
   FSelectedControlFaces.Free;
   FSelectedControlCurves.Free;
   inherited Destroy;
end;

procedure SSurface.Draw( Viewport:TViewport ); var I: Integer;
begin
   if not Build then Rebuild;
   if Viewport.ViewportMode<>vmWireframe then begin
      if Viewport.ViewportMode in [vmShadeGauss,vmShadeDevelopable] then
         if not GaussCurvatureCalculated then CalculateGaussCurvature;
   end else inherited Draw( Viewport );
   for I:=0 to NoLayers-1 do Layer[I].Draw( Viewport );
   if ShowControlNet then begin
      for I:=0 to NoControlEdges-1 do ControlEdge[I].Draw( False,Viewport );
      for I:=0 to NoControlPoints-1 do
       if ControlPoint[I].Visible then ControlPoint[I].Draw( Viewport );
   end;
   for I:=0 to NoControlCurves-1 do
    if ControlCurve[I].Visible then ControlCurve[I].Draw( Viewport );
end;

function SSurface.EdgeExists( P1,P2:SPoint ):SEdge; var I:Integer; Edge:SEdge;
begin Result:=nil;
         // If the edge exists then it must exist in both the points, therefore
         //  only the point with the smallest number of edges has to be checked
   if P1.FEdges.Count<=P2.FEdges.Count then begin
      for I:=0 to P1.FEdges.Count-1 do begin Edge:=P1.FEdges[I];
         if ((Edge.Startpoint=P1) and (Edge.Endpoint=P2))
         or ((Edge.Startpoint=P2) and (Edge.Endpoint=P1))
         then begin Result:=Edge; break; end;
      end;
   end else
      for I:=0 to P2.FEdges.Count-1 do begin Edge:=P2.FEdges[I];
         if ((Edge.Startpoint=P1) and (Edge.Endpoint=P2))
         or ((Edge.Startpoint=P2) and (Edge.Endpoint=P1))
         then begin Result:=Edge; break; end;
   end;
end;

procedure SSurface.ExtractAllEdgeLoops( var Destination:TFasterList ); // для DXF
var SourceList,Loop,Points: TFasterList;
    I,Index: Integer;
    Edge: SEdge;
    NextEdge: SEdge;
begin
   SourceList:=TFasterList.Create;
   for I:=1 to Self.FEdges.Count do begin Edge:=FEdges[I-1];
      if Edge.Crease then begin SourceList.Add(Edge); end;
   end;
   SourceList.Sort;
   while SourceList.Count>0 do begin
      Edge:=SourceList[SourceList.Count-1];
      SourceList.Delete(SourceList.Count-1);
      Loop:=TFasterList.Create;
      Loop.Add(Edge);                                     // trace edge to back
      repeat
         NextEdge:=Edge.PreviousEdge;
         if NextEdge<>nil then begin
            Index:=SourceList.SortedIndexOf(NextEdge);
            if Index<>-1 then begin
               Loop.Insert(0,NextEdge);
               SourceList.Delete(index);
               Edge:=NextEdge;
            end else NextEdge:=nil;
         end;
      until NextEdge=nil;
      Edge:=Loop[Loop.Count-1];                          // trace edge to front
      repeat
         NextEdge:=Edge.NextEdge;
         if NextEdge<>nil then begin
            Index:=SourceList.SortedIndexOf(NextEdge);
            if Index<>-1 then begin
               Loop.Add(NextEdge);
               SourceList.Delete(index);
               Edge:=NextEdge;
            end else NextEdge:=nil;
         end;
      until NextEdge=nil;
      SortEdges( Loop,Points );
      if Points<>nil then Destination.Add(Points);
      Loop.Destroy;
   end;
   SourceList.Destroy;
end;
{
// extracts all points that are used by the faces in the selectedfaces list
// only points completely surrounded by faces in the faces list are extracted
procedure SSurface.ExtractPointsFromFaces(SelectedFaces,Points:TFasterList;var LockedPoints:Integer);
var I,J,K,N: Integer; OK: Boolean;
    Face: Sface;
    P: SControlPoint;
begin
   Points.Capacity:=4*SelectedFaces.Count;
   SelectedFaces.Sort;
   LockedPoints:=0;
   for I:=1 to SelectedFaces.Count do begin Face:=SelectedFaces[I-1];
      for J:=1 to Face.Nopoints do begin
         P:=Face.Point[J-1] as SControlPoint;
         if Points.SortedIndexOf(P)=-1 then begin OK:=True;
            for K:=1 to P.NoFaces do begin
               N:=SelectedFaces.SortedIndexOf( P.Face[K-1] );
               if N=-1 then begin OK:=False; break; end;
            end;
            if OK then begin
               Points.AddSorted(P);
               if P.Locked then inc(LockedPoints);
            end;
         end;
      end;
   end;
end;
}
// Extracts all controlpoints from thee entire selection of faces, edges and points
procedure SSurface.ExtractPointsFromSelection(SelectedPoints:TFasterList;var LockedPoints:Integer);
var I,J: Integer; Face: SFace; Edge: SEdge; P: SControlPoint;
begin
   SelectedPoints.Capacity:=4*NoSelectedControlfaces+
                            2*NoSelectedControlEdges+
                              NoSelectedControlPoints+1;
   LockedPoints:=0;
   for I:=1 to NoSelectedControlFaces do begin
      Face:=SelectedControlface[I-1];
      for J:=1 to Face.Nopoints do begin
         P:=Face.Point[J-1] as SControlPoint;
         if SelectedPoints.SortedIndexOf(P)=-1 then SelectedPoints.AddSorted(P);
      end;
   end;
   for I:=1 to NoSelectedControlEdges do begin
      Edge:=SelectedControlEdge[I-1];
      P:=Edge.StartPoint as SControlPoint;
      if SelectedPoints.SortedIndexOf(P)=-1 then SelectedPoints.AddSorted(P);
      P:=Edge.EndPoint as SControlPoint;
      if SelectedPoints.SortedIndexOf(P)=-1 then SelectedPoints.AddSorted(P);
   end;
   for I:=1 to NoSelectedControlPoints do begin
      P:=SelectedControlPoint[I-1];
      if SelectedPoints.SortedIndexOf(P)=-1 then SelectedPoints.AddSorted(P);
   end;
   for I:=1 to SelectedPoints.Count do begin   // count number of locked points
      P:=SelectedPoints[I-1];
      if P.Locked then inc(LockedPoints);
   end;
end;

procedure SSurface.ImportFEFFile( Strings:TStringList; var LineNr:Integer );
var Str: string;
    I,J,K,N,Np,Index: Integer;  Sxr: boolean;
    Point,P1,P2: SControlPoint;
    Curve      : SControlCurve;
    Edge       : SControlEdge;
    Face       : SControlFace;
    Layer      : SLayer;
{ function NewPoint(P:Vector):SControlPoint;
   begin Result:=SControlPoint.Create( self ); Result.FCoordinate:=P;
         FControlPoints.Add( Result );
   end; }
begin                                          // Read layer information
   if LineNr>0 then begin
     Inc( LineNr );                              Sp.UColor:=clGreen;
     Str:=Strings[LineNr];                       Sp.UAlfa:=64;
     N:=GetInteger(Str);                         Sp.UColorIs:=true;
     if N=0 then             /// *** в преобразованиях из Delft есть лишний нолик
        begin Inc( LineNr ); Str:=Strings[LineNr]; N:=GetInteger( Str ); end;
     for I:=1 to N do begin
        if I>NoLayers then Layer:=self.AddNewLayer
                      else Layer:=self.Layer[I-1];
        inc(LineNr); Layer.FDescription:=Strings[LineNr];;
        inc(LineNr); Str:=Strings[LineNr];
        Layer.LayerID:=GetInteger(Str);
        if Layer.LayerID>FLastusedLayerID then FLastusedLayerID:=Layer.LayerID;
        Layer.FColor:=GetInteger(Str);
           Layer.AlphaBlend:=255-byte( Cardinal( Layer.FColor ) shr 24 );
           Layer.FColor:=Layer.FColor and $FFFFFF;
        Layer.FVisible            :=GetBoolean(Str); // видимость
        Layer.FDevelopable        :=GetBoolean(Str); // под развёртку
        Layer.FSymmetric          :=GetBoolean(Str); // только левый борт
        Layer.FUseForIntersections:=GetBoolean(Str); // к теоретическим контурам
        Layer.FUseInHydrostatics  :=GetBoolean(Str); // в расчёты гидростатики
        Layer.FShowInLinesplan    :=GetBoolean(Str); // в теоретические чертежи
        Layer.MaterialDensity     :=GetFloat(Str);   // плотность материала
        Layer.Thickness           :=GetFloat(Str);   // и толщина листов обшивки
     end;
     write( ' L=',NoLayers );
     if Assigned(OnChangeLayerData) then OnChangeLayerData(self);
     Inc( LineNr );
   end;
   Str:=Strings[LineNr];
   N:=GetInteger(Str);
   for I:=1 to N do begin                                 // Read controlpoints
      Point:=SControlPoint.Create(self);
      FControlPoints.Add(Point);
      Point.LoadFromStream(LineNr,Strings);
   end;
   write( ', K=',FControlPoints.Count );
   Inc(LineNr); Str:=Strings[LineNr];
   N:=GetInteger(Str);
   for I:=1 to N do begin                                  // Read controlEdges
      Edge:=SControlEdge.Create( self );
      Edge.isRead:=true;
      Edge.FControlEdge:=true;
      FControlEdges.Add(Edge);
      Edge.LoadFromStream(LineNr,Strings);
   end;
   write( ', E=',FControlEdges.Count );
   Inc(LineNr); Str:=Strings[LineNr];
   N:=GetInteger(Str);
// parallel - не срабатывает
   for I:=1 to N do begin                         // Read controlFaces
      Inc(LineNr);
      if LineNr>=Strings.Count then break; // неожиданный конец файла по списку
      Str:=Trim( Strings[LineNr] );
      if Length(Str)<2 then break;       // пустая строка здесь = конец файла
      Np:=GetInteger(Str);              // и далее следуют комментарии описания
      if Np<3 then continue;            // это неверно, так пусть лучше пропуск
      Face:=SControlFace.Create(self);
      FControlFaces.Add(Face);
      for J:=1 to Np do begin
        Index:=GetInteger(Str);          // Attach controlface to controlpoints
        for K:=FControlPoints.Count-1 downto 0 do
         if ControlPoint[K]=ControlPoint[Index] then begin Index:=K; break end;
        Face.AddPoint(ControlPoint[Index]);
      end;          // Attach controlface to the already existing control edges
      Index:=GetInteger(Str);                                // Read Layerindex
      While Index>NoLayers-1 do AddNewLayer;
      Layer:=FLayers[Index];
      Layer.AddControlFace(Face);
   end;
   write( ', F=',FControlFaces.Count );
   Sxr:=false;                                      // для небольшого ускорения
   for I:=0 to FControlFaces.Count-1 do begin Face:=FControlFaces[I];
      P1:=Face.FPoints[Face.FPoints.Count-1];            // повтор для перебора
      for J:=0 to Face.FPoints.Count-1 do begin
         P2:=Face.FPoints[J]; Edge:=nil;
         Edge:=EdgeExists( P1,P2 ) as SControlEdge;
       { for K:=FControlEdges.Count-1 downto 0 do begin Edge:=FControlEdges[K];
            if ((Edge.StartPoint=P1) and (Edge.EndPoint=P2))
            or ((Edge.StartPoint=P2) and (Edge.EndPoint=P1)) then break
                                                             else Edge:=nil;
         end; }
         if Edge=nil then begin Sxr:=true;         // есть пропуск любого ребра
            Edge:=SControlEdge.Create(Self);
            Edge.Startpoint:=P2;
            Edge.Endpoint:=P1;
            Edge.isRead:=false;
            Edge.Selected:=false;
            Edge.FControlEdge:=true;
            P1.AddEdge(Edge);
            P2.AddEdge(Edge);
            FControlEdges.Add(Edge);
            Edge.Crease:=true;                                // IsBoundaryEdge
         end;
         Edge.FFaces.Add(Face);
         P1:=P2;
      end;
   end;
   write( ', +E=',FControlEdges.Count );
   if Sxr then
   for I:=0 to FControlEdges.Count-1 do begin Edge:=FControlEdges[I];
     if not Edge.isRead then                   // считанные рёбра без изменений
     if Edge.NoFaces=2 then Edge.Crease:=false;
   end;
{ !!!                                          оППа, и не тут-то было !!!
   if LineNr<Strings.Count then begin          // продолжение с контурами
      Inc( LineNr ); Str:=Trim( Strings[LineNr] );
      N:=GetInteger( Str );
      FControlCurves.Capacity:=N;
      for I:=1 to N do begin
         Source.LoadInteger(N);
         FControlPoints.Capacity:=N;
         P1:=nil;
         for I:=1 to N do begin
            Source.LoadInteger(Ind);
            P2:=Owner.FControlPoints[ind];
            FControlPoints.Add(P2);
            if I>1 then begin
               Edge:=Owner.EdgeExists(P1,P2);
               if Edge<>nil then Edge.Curve:=self;
            end;
            P1:=P2;
         end;
         FSubdividedPoints.AddList(FControlPoints);
         Source.LoadBoolean(Sel);
         if Sel then selected:=True;

         Curve:=SControlCurve.Create( self );
         Inc( LineNr ); Str:=Trim( Strings[LineNr] );
         K:=GetInteger( Str );
         FControlCurves.Add( Curve );
         Inc( LineNr ); Str:=Trim( Strings[LineNr] );
         K:=GetInteger( Str ); Curve.Capacity:=K;
        FControlCurves.Add( Curve );
        Curve.LoadBinary(Source);
     end;                                                 // Read controlFaces
//   if LineNr>=Strings.Count then break; // неожиданный конец файла по списку
   end;
}
   writeln( '...' );
   Build:=False;
   FInitialized:=True;
   if assigned(OnChangeLayerData) then OnChangeLayerData(self);
   if assigned(OnChangeActiveLayer) then OnChangeActiveLayer(self,self.Layer[0]);
end;

procedure SSurface.ImportGrid(Points:TCoordinateGrid;Cols,Rows:Integer;Layer:SLayer);
var Grid: SGrid; FacePoints: TFasterList;
    Edge: SEdge; I,J: Integer;
begin
   Setlength( Grid,Rows );
   for I:=1 to Rows do begin
      Setlength(Grid[I-1],Cols);
      for J:=1 to Cols do Grid[I-1][J-1]:=AddControlPoint(Points[I-1][J-1]);
   end;
   FacePoints:=TFasterList.Create;
   for I:=2 to Rows do
   for J:=2 to Cols do begin
      FacePoints.Clear;
      if FacePoints.IndexOf(Grid[I-1,J-1])=-1 then FacePoints.Add(Grid[I-1,J-1]);
      if FacePoints.IndexOf(Grid[I-1,J-2])=-1 then FacePoints.Add(Grid[I-1,J-2]);
      if FacePoints.IndexOf(Grid[I-2,J-2])=-1 then FacePoints.Add(Grid[I-2,J-2]);
      if FacePoints.IndexOf(Grid[I-2,J-1])=-1 then FacePoints.Add(Grid[I-2,J-1]);
      if FacePoints.Count>=3 then if Layer<>nil
         then AddControlFace(FacePoints,True,Layer)
         else AddControlFace(FacePoints,True);
   end;                                                     // set crease edges
   for I:=2 to Cols do begin
      Edge:=EdgeExists(Grid[0][I-2],Grid[0][I-1]);
      if Edge<>nil then Edge.Crease:=true;
      Edge:=EdgeExists(Grid[Rows-1][I-2],Grid[Rows-1][I-1]);
      if Edge<>nil then Edge.Crease:=true;
   end;
   for I:=2 to Rows do begin
      Edge:=EdgeExists(Grid[I-2][0],Grid[I-1][0]);
      if Edge<>nil then Edge.Crease:=true;
      Edge:=EdgeExists(Grid[I-2][Cols-1],Grid[I-1][Cols-1]);
      if Edge<>nil then Edge.Crease:=true;
   end;                                                     // set cornerpoints
   for I:=1 to Rows do
      for J:=1 to Cols do if Grid[I-1][J-1].NoFaces<2 then
      Grid[I-1][J-1].VertexType:=svCorner;
   FacePoints.Destroy;
end;

procedure SSurface.Initialize(PointStartIndex,EdgeStartIndex,FaceStartIndex:Integer);
var I:Integer; Edge:SEdge;
begin                                              // Identify all border edges
   if EdgeStartIndex<=NoControlEdges then
   for I:=EdgeStartIndex to NoControlEdges do begin
      Edge:=ControlEdge[I-1];
      if Edge.NoFaces=0 then begin
         Edge.StartPoint.DeleteEdge(Edge);
         Edge.EndPoint.DeleteEdge(Edge);
         Edge.Crease:=false;
      end else if Edge.NoFaces<>2 then Edge.Crease:=true;
   end;
// for I:=1 to NoControlEdges do if ControlEdge[I-1].NoFaces<>2 then ControlEdge[I-1].Crease:=True;
   for I:=PointStartIndex to NoControlPoints do if ControlPoint[I-1].NoFaces<2 then ControlPoint[I-1].VertexType:=svCorner;
   FInitialized:=True;
end;

function SSurface.IntersectPlane(Plane:Plate;HydrostaticsLayersOnly:Boolean;List:TFasterList):Boolean;
var I,J              : Integer;
    CtrlFace         : SControlFace;
    IntersectedFaces : TFasterList;
    Min,Max          : Vector;
    UseLayer         : Boolean;
    Layer            : SLayer;
begin
   Result:=False;
   if not build then Rebuild;
   if not PlaneIntersectsBox(self.Min,self.Max,Plane) then exit;
   IntersectedFaces:=TFasterList.Create;
   for I:=1 to NoLayers do begin
      Layer:=self.Layer[I-1];
      if HydrostaticsLayersOnly then UseLayer:=Layer.UseInHydrostatics
                                else UseLayer:=Layer.UseForIntersections;
      if UseLayer then for J:=1 to Layer.Count do begin
         CtrlFace:=Layer.Items[J-1];
         Min:=CtrlFace.Min;
         Max:=CtrlFace.MAx;
         if PlaneIntersectsBox(Min,Max,Plane) then IntersectedFaces.Add(CtrlFace);
      end;
   end;
   CalculateIntersections(Plane,IntersectedFaces,List);
   IntersectedFaces.Destroy;
   Result:=List.Count>0;
end;

// inserts points on edges (visible edges only) that intersect the input plane
procedure SSurface.InsertPlane(Plane:Plate;AddCurves:Boolean);
var I,J,K      : Integer;
    S1,S2,T    : Real;
    P          : Vector;
    face       : SControlface;
    Edge       : SControlEdge;
    NewP,P1,P2 : SControlPoint;
    Curve      : SControlCurve;
    Points,Edges,SortedEdges: TFasterList;
    Inserted   : Boolean;
begin
   I:=1;
   Points:=TFasterList.Create;
   while I<=NoControlEdges do begin
      Edge:=self.ControlEdge[I-1];
      if Edge.Visible then begin
         S1:=Plane.a*Edge.Startpoint.Coordinate.x+Plane.b*Edge.Startpoint.Coordinate.y+Plane.c*Edge.Startpoint.Coordinate.z+Plane.d;
         S2:=Plane.a*Edge.Endpoint.Coordinate.x+Plane.b*Edge.Endpoint.Coordinate.y+Plane.c*Edge.Endpoint.Coordinate.z+Plane.d;
         if ((S1<-1e-5) and (S2>1e-5)) or ((S1>1e-5) and (S2<-1e-5)) then begin
            if S1=S2 then T:=0.5
                     else T:=-s1/(s2-s1);
            P:=Edge.Startpoint.Coordinate+T*(Edge.Endpoint.Coordinate-Edge.Startpoint.Coordinate);
            NewP:=Edge.InsertControlPoint(P);
            Points.Add( NewP );
         end;
      end; inc(I);
   end;
   if Points.Count>0 then begin // Try to find multiple points belonging to the same face and insert an edge
      I:=1;
      Points.Sort;
      Edges:=TFasterList.Create;
      while I<=Points.Count do begin
         P1:=Points[I-1];
         J:=1;
         while J<=P1.NoFaces do begin
            Face:=P1.Face[J-1] as SControlface;
            K:=1;
            Inserted:=False;
            while (K<=Face.Nopoints) and (Not Inserted) do begin
               P2:=Face.Point[K-1] as SControlPoint;
               if (P1<>P2) and (Points.SortedIndexOf(P2)<>-1) then begin
               // this is also a new point, first check if an edge already exists between P1 and P2
                  if EdgeExists(P1,P2)=nil then begin
                     Inserted:=True;
                     Edge:=Face.InsertEdge(P1,P2);
                     Edge.Selected:=True;
                     Edges.Add(Edge);
                  end;
               end; inc(K);
            end;    if not Inserted then inc(J);
         end;       inc(I);
      end;
      if AddCurves then begin
         Points.Destroy;
         SortedEdges:=TFasterList.Create;
         IsolateEdges(Edges,SortedEdges);
         for I:=1 to SortedEdges.Count do begin
            Points:=SortedEdges[I-1];
            if Points.Count>1 then begin
               Curve:=SControlCurve.Create(self);
               AddControlCurve(Curve);
               for J:=1 to Points.Count do begin
                  P1:=Points[J-1];
                  Curve.AddPoint(P1);
                  if J>1 then begin
                     Edge:=Curve.Owner.EdgeExists(Curve.ControlPoint[J-2],Curve.ControlPoint[J-1]) as SControlEdge;
                     if Edge<>nil then
                        Edge.Curve:=Curve;
                  end;
               end;
            end; Points.Destroy;
         end;   SortedEdges.Destroy;
      end else Points.Destroy;
      Edges.Destroy;
      Build:=False;
   end else Points.Destroy;
end;

procedure SSurface.IsolateEdges(Source,destination:TFasterList);
var I: Integer;
    Edge,Edge2: SControlEdge;
    TmpEdges,TmpPts: TFasterList;
    Findmore: Boolean;
begin                      // Try to isolate individual (closed) sets of edges
   TmpEdges:=TFasterList.Create;
   while Source.Count>0 do begin
      Edge:=Source[0];
      Source.Delete(0);
      FindMore:=True;
      TmpEdges.Clear;
      TmpEdges.Add(Edge);
      while (Source.Count>0) and (FindMore) do begin FindMore:=False;
         for I:=1 to Source.Count do begin
            Edge2:=Source[I-1];                             // compare at start
            Edge:=TmpEdges[0];
            if (Edge2.Startpoint=Edge.Startpoint)
            or (Edge2.Startpoint=Edge.Endpoint)
            or (Edge2.Endpoint=Edge.Startpoint)
            or (Edge2.Endpoint=Edge.Endpoint) then begin
               TmpEdges.Insert(0,Edge2);
               Source.Delete(I-1);
               Findmore:=true;
               break;
            end else begin
               Edge:=TmpEdges[Tmpedges.Count-1];
               if (Edge2.Startpoint=Edge.Startpoint) or (Edge2.Startpoint=Edge.Endpoint)
               or (Edge2.Endpoint=Edge.Startpoint) or (Edge2.Endpoint=Edge.Endpoint)
               then begin
                  TmpEdges.Add(Edge2);
                  Source.Delete(I-1);
                  Findmore:=true;
                  break;
               end;
            end;
         end;
      end;
      if TmpEdges.Count>0 then begin   // Sort all found edges in correct order
         SortEdges(TmpEdges,TmpPts);
         if TmpPts<>nil then Destination.Add(TmpPts);
      end;
   end;
   TmpEdges.Destroy;
end;

procedure SSurface.LoadBinary(Source:TFileBuffer);
var I,N: Integer;
    Point: SControlPoint;
    Edge : SControlEdge;
    Face : SControlFace;
    Curve: SControlCurve;
    Layer: SLayer;
begin                                                   // First load layerdata
   Source.LoadInteger(N);
   if N<>0 then begin                // Delete current layers and load new ones
      for I:=1 to NoLayers do self.Layer[I-1].Destroy;
      FLayers.Clear;
      FLayers.Capacity:=N;
      for I:=1 to N do begin
         Layer:=AddNewLayer;
         Layer.LoadBinary(Source);
      end;
   end; // else          No layers in the file, so keep the current default one
   if assigned(OnChangeLayerData) then OnChangeLayerData(self);
   Source.LoadInteger(N);                         // Read index of active layer
   ActiveLayer:=self.Layer[N];
   if assigned(OnChangeActiveLayer) then OnChangeActiveLayer(self,self.Layer[0]);
   Source.LoadInteger(N);                                 // Read controlpoints
   FControlPoints.Capacity:=N;
   for I:=1 to N do begin
      Point:=SControlPoint.Create(self);
      FControlPoints.Add(Point);
      Point.LoadBinary(Source);
   end;                                                    // Read controlEdges
   Source.LoadInteger(N);
   FControlEdges.Capacity:=N;
   for I:=1 to N do begin
      Edge:=SControlEdge.Create(self);
      Edge.FControlEdge:=True;
      FControlEdges.Add(Edge);
      Edge.LoadBinary(Source);
   end;
   if Source.Version>=fv195 then begin                    // Load controlcurves
      Source.LoadInteger(N);
      FControlCurves.Capacity:=N;
      for I:=1 to N do begin
         Curve:=SControlCurve.Create(self);
         FControlCurves.Add(Curve);
         Curve.LoadBinary(Source);
      end;
   end;                                                    // Read controlFaces
   Source.LoadInteger(N);
   FControlFaces.Capacity:=N;
   for I:=1 to N do begin
      Face:=SControlFace.Create(self);
      FControlFaces.Add(Face);
      Face.LoadBinary(Source);
   end;
   Build:=False;
   FInitialized:=True;
   if assigned(OnChangeLayerData) then OnChangeLayerData(self);
   if assigned(OnChangeActiveLayer) then OnChangeActiveLayer(self,self.Layer[0]);
end;

procedure SSurface.LoadVRMLFile(Filename:string);
var VRMLList: TVRMLList;
    I,J,K,N,Index: Integer;
    Data,Points,FacePoints,AddedCtrlPts: TFasterList;
    CoordInfo: TVRMLCoordinate3;                        // V3Point:Vector;
    FaceInfo: TVRMLIndexedFaceSet;
    Face: TIntArray;
    Layer: SLayer;
    CtrPoint: SControlpoint;
begin
   if FileExistsUTF8(Filename) then begin
      VRMLList:=TVRMLList.Create;
      VRMLList.LoadFromFile(Filename);
      Data:=VRMLList.ExtractFaceSetData;
      if Data<>nil then begin Clear;
         AddedCtrlPts:=TFasterList.Create;
         AddedCtrlPts.Capacity:=Data.Count;         // Assemble coordinate sets
         for I:=1 to Data.Count do begin FaceInfo:=Data[I-1];
            if AddedCtrlPts.SortedIndexOf(FaceInfo.Coordinates)=-1 then
               AddedCtrlPts.AddSorted(FaceInfo.Coordinates);
         end;
         for I:=1 to AddedCtrlPts.Count do begin// now add actual controlPoints
            CoordInfo:=AddedCtrlPts[I-1];
            Points:=TFasterList.Create;
            Points.Capacity:=CoordInfo.Count;
            AddedCtrlPts.Objects[I-1]:=points;
            for J:=1 to CoordInfo.Count do
               Points.Add( AddControlPoint(CoordInfo.Point[J-1]) );
         end;
         FacePoints:=TFasterList.Create;                    // Add controlfaces
         for I:=1 to Data.Count do begin FaceInfo:=Data[I-1];
            Index:=AddedCtrlPts.SortedIndexOf( FaceInfo.Coordinates );
            if Index<>-1 then begin
               Points:=AddedCtrlPts.Objects[Index];
               Layer:=AddNewLayer;
               for J:=1 to FaceInfo.Count do begin Face:=FaceInfo.Face[J-1];
                  if Face<>nil then begin N:=length(Face); FacePoints.Clear;
                     for K:=1 to N do begin Index:=face[K-1];
                        if (Index>=0) and (Index<Points.Count) then begin
                           CtrPoint:=Points[index];
                           if FacePoints.IndexOf(CtrPoint)=-1 then
                              FacePoints.Add(CtrPoint);
                        end;
                     end;
                     if FacePoints.Count>2 then
                        AddControlFace(FacePoints,True,Layer);
                  end;
               end;
            end;
         end;
         FacePoints.Destroy;
         for I:=1 to AddedCtrlPts.Count do begin
            Points:=AddedCtrlPts.Objects[I-1];
            Points.Destroy;
         end;
         AddedCtrlPts.Destroy;
         for I:=NoLayers downto 1 do begin      // delete empty layers
            if (self.Layer[I-1].Count=0) and (NoLayers>1)
            then self.Layer[I-1].Delete;
         end;
         ActiveLayer:=self.Layer[NoLayers-1];
         build:=false;
         Data.Destroy;
      end;  // else ShowMessage(Userstring(203)+'.');
      VRMLList.Destroy;
   end;
end;

// Check if a controlpoint still exists and is not deleted
function SSurface.PointExists(P:SControlPoint):Boolean;
   begin Result:=FControlPoints.IndexOf( P )<>-1; end;

procedure SSurface.Rebuild;
var I,J: Integer; Curve: SControlCurve; Edge1,Edge2: SEdge; Point: SPoint;
begin
   if not FInitialized then Initialize( 1,1,1 );
   if self.NoControlFaces>0 then begin
      for I:=1 to NoControlCurves do begin Curve:=ControlCurve[I-1];
         if FCurrenSLevel=0 then begin
            Curve.FBuild:=False;
            Curve.FSubdividedPoints.Clear;
            Curve.FSubdividedPoints.AddList(Curve.FControlPoints);
         end;
      end;

      FBuild:=True;
      while (FCurrenSLevel<FDivSec)
        and (FControlFaces.Count>0) do Subdivide;
      for I:=0 to NoControlfaces-1 do begin ControlFace[I].CalcExtents;
         if I=0 then begin FMin:=Controlface[I].FMin;
                           FMax:=Controlface[I].FMax;
         end else begin MinMax( Controlface[I].FMin,FMin,FMax );
                        MinMax( Controlface[I].FMax,FMin,FMax );
         end;
      end;
      for I:=1 to NoControlCurves do begin
         Curve:=ControlCurve[I-1];
         Curve.FCurve.Clear;
         Curve.FCurve.Capacity:=Curve.FSubdividedPoints.Count;
         for J:=1 to Curve.FSubdividedPoints.Count do begin
            Point:=Curve.FSubdividedPoints[J-1];
            Curve.FCurve.Add(Point.Coordinate);
            if (J>1) and (J<Curve.FSubdividedPoints.Count) then begin
               if Point.VertexType=svCorner
               then Curve.FCurve.Knuckle[J-1]:=True else begin
                  Edge1:=EdgeExists(Curve.FSubdividedPoints[J-2],Curve.FSubdividedPoints[J-1]);
                  Edge2:=EdgeExists(Curve.FSubdividedPoints[J-1],Curve.FSubdividedPoints[J]);
                  if (Edge1<>nil) and (Edge2<>nil) then
                  if (Edge1.Crease=False) and (Edge2.Crease=False) then
                      Curve.FCurve.Knuckle[J-1]:=Point.VertexType=svCrease;
               end;
            end; Curve.FBuild:=true;
         end;
      end;
   end
   else if NoControlPoints>0 then begin
      for I:=1 to NoControlPoints do begin
         if I=1 then begin
            FMin:=ControlPoint[I-1].Coordinate; FMax:=FMin;
         end else MinMax(ControlPoint[I-1].Coordinate,FMin,FMax);
      end;
   end else begin FMin:=ZERO; FMax.X:=1.0; FMax.Y:=1.0; FMax.Z:=1.0; end;
end;

procedure SSurface.SaveBinary(Destination:TFileBuffer);
var I: Integer;
begin                                                   // First save layerdata
   Destination.Add(NoLayers);
   for I:=1 to NoLayers do Layer[I-1].SaveBinary(Destination);
   Destination.Add(ActiveLayer.LayerIndex);       // Save index of active layer
           // first sort controlpoints for faster acces of function (Indexof())
   FControlPoints.Sort;
   Destination.Add(NoControlPoints);
   for I:=1 to NoControlPoints do ControlPoint[I-1].SaveBinary(Destination);
   Destination.Add(NoControlEdges);
   for I:=1 to NoControlEdges do ControlEdge[I-1].SaveBinary(Destination);
// if Destination.Version>=fv195 then begin <== всегда ver.2.6
      Destination.Add(NoControlCurves);
      for I:=1 to NoControlCurves do ControlCurve[I-1].SaveBinary(Destination);
// end;
   Destination.Add(NoControlFaces);
   for I:=1 to NoControlFaces do ControlFace[I-1].SaveBinary(Destination);
end;

procedure SSurface.Selection_Add( item: SBase );
begin
  if item=nil then exit;
  if item is SControlPoint then FSelectedControlPoints.Add(item as SControlPoint);
  if item is SControlFace then FSelectedControlFaces.Add(item as SControlFace);
  if item is SControlEdge then FSelectedControlEdges.Add(item as SControlEdge);
  if item is SControlCurve then FSelectedControlCurves.Add(item as SControlCurve);
end;

procedure SSurface.Selection_Delete; var I: Integer;
begin             // First controlcurves, then faces, edges and finally points!
   I:=NoSelectedControlCurves;
   while I>=1 do begin SelectedControlCurve[I-1].Delete; dec(I);
      if I>NoSelectedControlCurves then I:=NoSelectedControlCurves;
   end;
   I:=self.NoSelectedControlFaces;
   while I>=1 do begin SelectedControlFace[I-1].SelDeleteFace; dec(I);
      if I>NoSelectedControlFaces then I:=NoSelectedControlFaces;
   end;
   I:=self.NoSelectedControlEdges;
   while I>=1 do begin SelectedControlEdge[I-1].SelDeleteEdge; dec(I);
      if I>NoSelectedControlEdges then I:=NoSelectedControlEdges;
   end;
   I:=self.NoSelectedControlPoints;
   while I>=1 do begin
      if not SelectedControlPoint[I-1].Locked
         then SelectedControlPoint[I-1].SelDeletePoint; dec( I );
      if I>NoSelectedControlPoints then I:=NoSelectedControlPoints;
   end;
   Build:=False;
end;

procedure SSurface.SortEdges(Edges:TFasterList);
var Edge1,Edge2:SEdge; J:Integer;
begin
   if Edges.Count<=1 then exit else begin Edge1:=Edges[0];
      for J:=2 to Edges.Count do begin Edge2:=Edges[J-1];
         if J=2 then begin
            if (Edge1.StartPoint=Edge2.StartPoint) then begin
               Edge1.SwapData;
            end else if (Edge1.StartPoint=Edge2.EndPoint) then begin
               Edge1.SwapData;
               Edge2.SwapData;
            end else if (Edge1.EndPoint=Edge2.StartPoint) then begin
            end else if (Edge1.EndPoint=Edge2.EndPoint) then begin
               Edge2.SwapData;
            end;
         end else begin
            if (Edge1.EndPoint=Edge2.EndPoint) then Edge2.SwapData;
            if (Edge1.EndPoint=Edge2.StartPoint) then begin
                Edge2.SwapData;
                Edge2.SwapData;
            end;
         end; Edge1:=Edge2;
      end;
   end;
end;

procedure SSurface.SortEdges(Edges:TFasterList;var Points:TFasterList);
var I: Integer; Edge: SEdge;
begin
   if Edges.Count>0 then begin
      Points:=TFasterList.Create;
      Points.Capacity:=Edges.Count+1;
      SortEdges(Edges);
      for I:=1 to Edges.Count do begin Edge:=Edges[I-1];
         if I=1 then Points.Add(Edge.StartPoint);
      // if Edge.EndPoint<>Points[0] then Points.Add( Edge.EndPoint );
         Points.Add(Edge.EndPoint);
      end;
   end else Points:=nil;
end;

procedure SSurface.SubDivide;
{type TQuadData = record
         P: array[1..4] of SPoint;
         Crease1,Crease2: Boolean;
      end; }
var I,J,Number: Integer; TmpPoints: VectorArray;
    CtrlFace: SControlFace;
    Edge: SEdge;
    Point: SPoint;
    NewEdgeList,VertexPoints,FacePoints,EdgePoints: TFasterList;
begin
   if NoControlFaces<1 then exit;
   inc( FCurrenSLevel );
   NewEdgeList:=TFasterList.Create;
   NewEdgelist.Capacity:=NoControlEdges*Round( Power( 2,FCurrenSLevel ) );
   Number:=NoFaces;
   FacePoints:=TFasterList.Create;  // list facepoints and a reference face
   EdgePoints:=TFasterList.Create;  // list edgepoints and a reference edge
   VertexPoints:=TFasterList.Create;// list vertexpoints and a reference vertex
   if Number=0 then begin
      FacePoints.Capacity:=NoControlFaces;
      for I:=0 to NoControlFaces-1 do begin
         CtrlFace:=ControlFace[I];
         FacePoints.AddObject(CtrlFace,CtrlFace.CalculateFacePoint);
      end;
   end else begin
      FacePoints.Capacity:=4*NoControlFaces;
      for I:=0 to NoControlFaces-1 do begin CtrlFace:=ControlFace[I];
         for J:=0 to CtrlFace.Childcount-1 do FacePoints.AddObject(CtrlFace.Child[J],CtrlFace.Child[J].CalculateFacePoint);
         for J:=0 to CtrlFace.Edgecount-1 do EdgePoints.AddObject(CtrlFace.Edge[J],CtrlFace.Edge[J].CalculateEdgePoint);
      end;
   end;
   EdgePoints.Capacity:=EdgePoints.Count+NoEdges; // Calculate other edgepoints
   for I:=0 to NoEdges-1 do EdgePoints.AddObject(self.Edge[I],self.Edge[I].CalculateEdgePoint);
   VertexPoints.Capacity:=VertexPoints.Count+NoPoints; // Calculate vertexpoints
   for I:=0 to Nopoints-1 do VertexPoints.AddObject(Self.Point[I],Self.Point[I].CalculateVertexPoint);
   VertexPoints.Sort;
   EdgePoints.Sort;                     // Sort the new points for faster acces
   FacePoints.Sort;
   // finally create the refined mesh over the newly create vertexpoints, edgepoints and facepoints
   for I:=0 to NoControlFaces-1 do begin
      CtrlFace:=ControlFace[I];
      CtrlFace.Subdivide( Self,True,VertexPoints,EdgePoints,FacePoints,nil,NewEdgeList,nil );
   end;
   for I:=0 to FEdges.Count-1 do begin                      // cleanup old mesh
      Edge:=FEdges[I];
      Edge.Destroy;
   end;
   FEdges.Destroy;
   FEdges:=NewEdgeList;
   for I:=0 to FPoints.Count-1 do begin Point:=FPoints[I]; Point.Destroy; end;
   FPoints.Clear;                      // Add all new points int the point-list
   FPoints.Capacity:=VertexPoints.Count+EdgePoints.Count+FacePoints.Count;
   for I:=0 to VertexPoints.Count-1 do if VertexPoints.Objects[I]<>nil then FPoints.Add(VertexPoints.Objects[I]);
   for I:=0 to EdgePoints.Count-1 do if EdgePoints.Objects[I]<>nil then FPoints.Add(EdgePoints.Objects[I]);
   for I:=0 to FacePoints.Count-1 do if FacePoints.Objects[I]<>nil then FPoints.Add(FacePoints.Objects[I]);
   FPoints.Capacity:=FPoints.Count;                      // Cleanup temp. lists
   VertexPoints.Destroy;
   EdgePoints.Destroy;
   FacePoints.Destroy;    // perform averaging procedure to smooth the new mesh
   Setlength( TmpPoints,FPoints.Count );
   for I:=0 to FPoints.Count-1 do begin Point:=FPoints[I]; TmpPoints[I]:=Point.Averaging; end;
   for I:=0 to FPoints.Count-1 do begin Point:=FPoints[I]; Point.FCoordinate:=TmpPoints[I]; end;
end;

procedure Register; begin RegisterComponents( 'Ship',[TViewport] ); end;

initialization Randomize;
end.


