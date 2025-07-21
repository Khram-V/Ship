unit FreeGeometry;
interface
uses Windows,  SysUtils,
     Classes,  Graphics,
     Controls, Forms,
     Math,     Dialogs,
     ExtCtrls, FasterList, FreeTypes;

const IncrementSize       = 25;        // amount of points which is automaticly allocated extra memory for
      Decimals            = 4;         // When weilding points together this is the accuracy for comparing points
      ControlPointSize    = 3;         // Size of controlpoints in pixels when drawn on screen
      DefaultLayerColor   = $00009B00; // Default color of each layer (green-ish)
      DefaultSelectedColor= clYellow;  // Default color for selected items
//    PixelCountMax       = 32768;     // used for faster pixel acces when shading to viewport
//    EOL                 = #13#10;
      ZBufferScaleFactor  = 1.004;     // Offset for hidden-line drawing when drawing ontop of shaded triangles

type
//    TFloatType   = single;           // All floatingpoint variables are of this type
//    T2DCoordinate = record X,Y:TFloatType;  end; // 2D coordinate type
//    T3DVector = record  X,Y,Z:TFloatType; end; // 3D coordinate type
//    T3DPlane = record a,b,c,d:TFloatType; end; // Description of a 3D plane: a*x + b*y + c*z -d = 0.0;
      TRGBTriple   = PACKED RECORD
                       rgbtBlue : BYTE;
                       rgbtGreen: BYTE;
                       rgbtRed  : BYTE;
                     END;
      pRGBTripleArray = ^TRGBTripleArray;
      TRGBTripleArray = ARRAY[0..PixelCountMax-1] OF TRGBTriple;
      TShadePoint = record                 // Used for drawing to the Z-buffer
                      X,Y  : Integer;
                      Z    : TFloatType;
                    end;
      TFreeVertexType = (svRegular,svCrease,svDart,svCorner);                   // Different types of subdivisionvertices
      TFreeCameraType = (ftWide,ftStandard,ftShortTele,ftMediumTele,ftFarTele); // Different types of camera lenses, corresponding to focalpoints 20mm, 50mm, 90mm, 130mm, 200mm
      TFreeViewType   = (fvBodyplan,fvProfile,fvPlan,fvPerspective);
      TFreeLight   = record
                       Position  : T3DVector; // position of light in world
                       Luminance : byte;      // brightness
                       Ambient   : byte
                     end;

type TFreeSubdivisionBase        = class;
     TFreeSubdivisionSurface     = class;
     TFreeSubdivisionEdge        = class;
     TFreeSubdivisionFace        = class;
     TFreeSubdivisionControlPoint= class;
     TFreeSubdivisionControlFace = class;
     TFreeSubdivisionLayer       = class;
     TFreeViewport               = class;
     TFreeZBufferRow             = array of TFloatType;
     TOnRequestExtentsEvent      = procedure(Sender: TObject;var Min,Max:T3DVector) of object; // Event from TFreeviewport, which is raised when the viewport initializes and needs the
                                                                                               // bounding box of the min/max coordinates of the 3D model
     TChangeActiveLayerEvent     = procedure(Sender: TObject;Layer:TFreeSubdivisionLayer) of Object; // Event raised when the active lyers has been changed
{----------------------------------------------}
{ Z-buffer class used in the shading algorithm }
{----------------------------------------------}
TFreeZBuffer= class
   private
      FViewport: TFreeViewport;
      FBuffer  : array of TFreeZBufferRow;
      Fwidth,FHeight: Integer;
   public
      procedure Initialize;
end;
{---------------------------------------------------------}
{                                           TFreeViewport }
{ This is a 3D drawingcanvas used for viewing and drawing }
{ It also is the userinterface for editing the hullform.  }
{---------------------------------------------------------}
TFreeViewport = class(TCustomPanel)
   private
      FAngle      : TFloatType;
      FDistance   : TFloatType; // The distance from the model to the camera, determined by the field of view
      FElevation  : TFloatType;
      FFieldOfView: TFloatType; // The field of view in degrees, default=50 degr. which corresponds with the human eye
      FShade      : Boolean;    // Switch between wireframe and shaded mode
      FMin3D,FMax3D,FMidPoint: T3DVector; // Midpoint of the boundarybox determined by FMin3D and FMax3D. This point is used as centerpoint for rotating the 3D model
                                          // and it also is the direction at which the camera looks
      FViewType        : TFreeViewType;   // Switch to sideview, frontview, topview or perspective view
      FCameraLocation  : T3DVector;       // Position of the camera, following from the field of view and the distance of the camera
      FCameraType      : TFreeCameraType; // Determines the focalpoint of the camera
      FCosAngle,FSinAngle,                // Pre calculated values to speed-up the rotating of point in the perspective-projection
      FCosElevation,FSinElevation,        // Pre calculated values to speed-up the rotating of point in the perspective-projection
      FXScale,FYScale,                    // Scale for projecting the 2D coordinates to the viewport
      FZoom            : TFloatType;
      FOnMouseDown     : TMouseEvent;
      FOnMouseUp       : TMouseEvent;
      FOnMouseMove     : TMouseMoveEvent;
      FOnMouseLeave    : TNotifyEvent;
      FOnRedraw        : TNotifyEvent;
      FOnChangeViewType: TNotifyEvent;
      FOnRequestExtents: TOnRequestExtentsEvent;
      FScreencenter    : TPoint;
      FPan             : TPoint;          // shade data
      FZBuffer         : TFreeZBuffer;
      FLight           : TFreeLight;
      function  FGetPenColor:TColor;
      function  FGetPenStyle:TPenStyle;
      procedure FSetAngle(Val:TFloatType);
      procedure FSetCameraType(Val:TFreeCameraType);
      procedure FSetElevation(Val:TFloatType);
      procedure FSetPan(Val:TPoint);
      procedure FSetPenColor(Val:TColor);
      procedure FSetPenStyle(Val:TPenStyle);
      procedure FSetShade(Val:Boolean);
      procedure FSetViewType(Val:TFreeViewType);
      procedure WMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
   protected
      procedure Paint;                                                        override;
      procedure Resize;                                                       override;
      procedure MouseDown(Button:TMouseButton;Shift:TShiftState;X,Y:Integer); override;
      procedure MouseMove(Shift:TShiftState;X,Y:Integer);                     override;
      procedure MouseUp(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);   override;
   public
      constructor Create(AOwner:TComponent);                                  override;
      destructor Destroy;                                                     override;
      procedure DrawLineToZBuffer( P1,P2:T3DVector; R,G,B:Integer );
      procedure InitializeViewport(Min,Max:T3DVector);
      function Project(P:T3DVector):TPoint;
      function ProjectBack(P:TPoint;Input:T3DVector):T3DVector;
      function ProjectBackTo2D(P:TPoint):T2DCoordinate;        // Takes the cursor position and projects it to 2D object space
      function ProjectToZBuffer(P:T3DVector):TShadePoint;  overload;virtual;// Projects a 3D point to the screen and calculate it's Z-value for the Z-buffer
      function ProjectToZBuffer(Scale:TFloatType;P:T3DVector):TShadePoint;  reintroduce;overload;// Projects a 3D point with a certain z-buffer offset to the screen, used for drawing lines on top of shaded surfaces
      function RotatedPoint(P:T3DVector):T3DVector;
      function RotatedPointBack(P:T3DVector):T3DVector;
      procedure SetPenWidth(Width:integer);
      procedure ShadeTriangle(P_1,P_2,P_3:T3DVector;R,G,B:integer);
      procedure ZoomIn;
      procedure ZoomExtents;
      procedure ZoomOut;
      property FieldOfView  : TFloatType read FFieldOfView;
      property Light        : TFreeLight read FLight;
      property PenColor     : TColor read FGetPenColor write FSetPenColor;
      property PenStyle     : TPenStyle read FGetPenStyle write FSetPenStyle;
      property Pan          : TPoint read FPan write FSetPan;
   published
      property Angle        : TFloatType read FAngle write FSetAngle;
      property Align;
      property BevelOuter;
      property CameraType   : TFreeCameraType read FCameraType write FSetCameraType;
      property Color;
      property Elevation    : TFloatType read FElevation write FSetElevation;
      property Enabled;
      property PopupMenu;
      property Shade        : Boolean read FShade write FsetShade; // Switch between wireframe and shaded mode
      property Visible;
      property ViewType     : TFreeViewtype read FViewType write FSetViewType;
      property OnChangeViewType: TNotifyEvent read FOnChangeViewType write FOnChangeViewType;
      property OnMouseDown  : TMouseEvent read FOnMouseDown write FOnMouseDown;
      property OnMouseUp    : TMouseEvent read FOnMouseUp   write FOnMouseUp;
      property OnMouseMove  : TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
      property OnMouseLeave : TNotifyEvent read FOnMouseLeave write FOnMouseLeave;
      Property OnResize;
      property OnRedraw     : TNotifyEvent read FOnRedraw write FOnRedraw;
      property OnRequestExtents: TOnRequestExtentsEvent read FOnRequestExtents write FOnRequestExtents;
end;

TFreeEntity = class // This is the base class of all 3D entities in the project
   private
      FBuild: Boolean;    // Flag to check if the entity has already been build
      FMin,FMax: T3DVector; // The min/max boundary coordinates of the entity after it has been build
      FPenWidth: byte;          // Pen thickness to use when drawing
      FColor   : TColor;        // Color when drawing
      FPenstyle: TPenStyle;     // Pen style for drawing the line
      function  FGetMin:T3DVector;
      function  FGetMax:T3DVector;
      procedure FSetBuild(Val:Boolean); virtual;
   public
      constructor Create; virtual;
      procedure   Clear; virtual;
      destructor  Destroy; override;
      procedure   Extents( Var Min,Max: T3DVector ); virtual;
      procedure   Draw(Viewport:TFreeViewport;Mode:TPenMode); virtual;
      procedure   Rebuild; virtual;
      property    Build   : Boolean read FBuild write FSetBuild;
      property    Color   : TColor read FColor write FColor;
      property    Min     : T3DVector read FGetMin;
      property    Max     : T3DVector read FGetMax;
      property    PenStyle: TPenStyle read FPenStyle write FPenStyle; // Pen style
      property    PenWidth: byte read FPenWidth write FPenWidth; // Pen thickness when drawing on screen
end;
//    3D CSpline from page 107 of book: "Numerical recipes in fortan 77"
//       Modified to use centripetal parametrisation for smoother
//       interpolation and to accept knuckles in the controlpoints
TFreeSpline = class(TFreeEntity)
      FPoints        : array of T3DVector; // Array containing all controlpoints
      FKnuckles      : array of boolean;
      FDerivatives   : array of T3DVector;
      FParameters    : array of TFloatType;
      FCapacity      : Integer;  // Number of points for which memory has been allocated
      FNoPoints      : Integer;  // Actual number of points present
      FFragments     : Integer;  // Number of straight-line segments used when drawing the curve
      function  FGetFragments:Integer;
      function  FGetKnuckle(Index:integer):Boolean;
      function  FGetParameter(Index:integer):TFloatType;
      function  FGetPoint(Index:Integer):T3DVector;
      procedure FSetBuild(val:boolean); override;
      procedure FSetCapacity(Val:Integer);
      procedure FSetFragments(Val:Integer);
      procedure FSetKnuckle(Index:integer;Value:Boolean);
      procedure FSetPoint(Index:Integer;P:T3DVector);
   public
      procedure   Add(P:T3DVector); // add a new point to the curve
      procedure   Clear;  override;
      constructor Create; override;
      procedure   DeletePoint(Index:Integer);
      procedure   InsertSpline(Index:Integer;Invert:Boolean;Source:TFreeSpline);
      procedure   Draw(Viewport:TFreeViewport;Mode:TPenmode); override;
      function    Value(Parameter:extended):T3DVector;
      procedure   Rebuild; override;
      property    Capacity  : Integer read FCapacity write FSetCapacity;
      property    Fragments : integer read FGetFragments write FSetFragments;
      property    Knuckle[Index:integer] : Boolean  read FGetKnuckle write FSetKnuckle;
      property    NumberOfPoints : Integer read FNoPoints;
      property    Parameter[Index:integer]: TFloatType read FGetParameter;
      property    Point [Index:Integer]   : T3DVector read FGetPoint write FSetPoint;
end;

TFreeSubdivisionBase = class //  is the base class for all subdivision points, edges and faces
   private
      FOwner: TFreeSubdivisionSurface;
   public
      constructor Create(Owner:TFreeSubdivisionSurface);                                  virtual;
      property    Owner                         : TFreeSubdivisionSurface read FOwner write FOwner;
end;

// TFreeSubdivisionLayer is a layer-type class
// All individual controlfaces can be assigned to a leyer.
// Properties such as color, visibility etc. are common for all controlfaces belonging the the same layer

TFreeSubdivisionLayer = class
   private     // color, visibility, symmetric, calc intersections/part of hull
      FOwner: TFreeSubdivisionSurface; // Pointer to the subdivisionsurface
      FLayerID    : integer;           // Unique identification number for internal references
      FColor      : TColor;            // Color of this layer
      FVisible    : boolean;           // Visibility switch
      FDescription: string;            // Description of the layer, used as user identification
      FSymmetric  : Boolean;           // Symmetric patches are mirrored in the centerplane when both halves of the ship are drawn
      FPatches    : TFasterList;       // List containing all controlpatches
      function  FGetColor:TColor;
      function  FGetCount:Integer;
      function  FGetName:string;
      function  FGetItems(Index:Integer):TFreeSubdivisionControlFace;
      function  FGetLayerIndex:Integer;
      procedure FSetName(Val:String);
      procedure FSetColor(Val:TColor);
      procedure FSetVisible(Val:Boolean);
      procedure FSetSymmetric(Val:Boolean);
   public
      procedure AddControlFace(ControlFace:TFreeSubdivisionControlFace);
      constructor Create(Owner:TFreeSubdivisionSurface);
      procedure Clear;
      function  Delete:Boolean;
      procedure DeleteControlFace(ControlFace:TFreeSubdivisionControlFace);
      destructor Destroy; override;
      procedure Draw(Viewport:TFreeViewport;Mode:TPenMode);
      procedure Extents(var Min,Max:T3DVector);
      procedure LoadFromStream(var LineNr:Integer;Strings:TStringList);
      procedure SaveToStream(Strings:TStringList);
      property  Color: TColor read FGetColor write FSetColor;
      property  Count: Integer read FGetCount;
      property  Items[Index:Integer]: TFreeSubdivisionControlFace read FGetItems;
      property  LayerID: Integer read FLayerID;
      property  LayerIndex: integer read FGetLayerIndex;
      property  Name: string read FGetName write FSetName;
      property  Owner: TFreeSubdivisionSurface read FOwner write FOwner;
      property  Symmetric: Boolean read FSymmetric write FSetSymmetric;
      property  Visible: boolean read FVisible write FSetVisible;
end;

// TFreeSubdivisionPoint - узлы 0 клюяевой элемент трёхмерной поверхности

TFreeSubdivisionPoint = class(TFreeSubdivisionBase)
   private
      FFaces,FEdges: TFasterList;
      FCoordinate: T3DVector;
      FVertexType: TFreeVertexType;
      function FGetEdge(Index:Integer):TFreeSubdivisionEdge;
      function FGetFace(Index:Integer):TFreeSubdivisionFace;
      function FGetIndex:Integer; virtual;
      function FGetNumberOfEdges:integer;
      function FGetNumberOfFaces:integer;
      procedure FSetCoordinate(Val:T3DVector); virtual;
   public
      procedure   AddEdge(Edge:TFreeSubdivisionEdge);
      procedure   AddFace(Face:TFreeSubdivisionFace);
      function    Averaging:T3DVector;
      function    CalculateVertexPoint:TFreeSubdivisionPoint; virtual;
      procedure   Clear;
      constructor Create(Owner:TFreeSubdivisionSurface); override;
      procedure   DeleteEdge(Edge:TFreeSubdivisionEdge);
      procedure   DeleteFace(Face:TFreeSubdivisionFace);
      destructor  Destroy; override;
      function    IndexOfFace(Face:TFreeSubdivisionFace):Integer;
      property    Coordinate: T3DVector read FCoordinate write FSetCoordinate;
      property    Edge[index:Integer]: TFreeSubdivisionEdge read FGetEdge;
      property    Face[index:Integer]: TFreeSubdivisionFace read FGetFace;
      property    NumberOfEdges: integer read FGetNumberOfEdges;
      property    NumberOfFaces: integer read FGetNumberOfFaces;
      property    VertexIndex  : integer Read FGetIndex;
      property    VertexType   : TFreeVertexType read FVertexType write FVertexType;
end;
TFreeSubdivisionControlPoint = class(TFreeSubdivisionPoint)
   private
      function FGetColor:TColor;
      function FGetIndex:Integer; override;
      function FGetSelected:Boolean;
      function FGetVisible:Boolean;
      procedure FSetSelected(val:Boolean);
      procedure FSetCoordinate(Val:T3DVector); override;
   public
      procedure   Collapse;
      constructor Create(Owner:TFreeSubdivisionSurface); override;
      function    DistanceToCursor(X,Y:Integer;Viewport:TFreeViewport):integer;
      procedure   Delete;
      procedure   Draw(Viewport:TFreeViewport);
      procedure   LoadFromStream(var LineNr:Integer;Strings:TStringList);
      procedure   SaveToStream(Strings:TStringlist);
      property    Color    : TColor read FGetColor;
      property    Selected : boolean read FGetSelected write FSetSelected; // Property to see if this point has been selected by the user
      property    Visible  : Boolean read FGetVisible;
end;

TFreeSubdivisionEdge = class(TFreeSubdivisionBase)
   private
      FStartpoint : TFreeSubdivisionPoint;
      FEndpoint   : TFreeSubdivisionPoint;
      FFaces      : TFasterList;
      FCrease     : Boolean;
      FControlEdge: Boolean;
      function  FGetIndex:Integer; virtual;
      function  FGetFace(Index:Integer):TFreeSubdivisionFace;
      function  FGetNumberOfFaces:Integer;
      procedure FSetCrease(Val:Boolean);
   public
      procedure   AddFace(Face:TFreeSubdivisionFace);
      procedure   Assign(Edge:TFreeSubdivisionEdge); virtual;
      function    CalculateEdgePoint:TFreeSubdivisionPoint;
      procedure   Clear;
      constructor Create(Owner:TFreeSubdivisionSurface); override;
      procedure   DeleteFace(Face:TFreeSubdivisionFace);
      destructor  Destroy; override;
      function    DistanceToCursor(X,Y:Integer;var P:T3DVector;Viewport:TFreeViewport):integer;
      procedure   Draw(DrawMirror:Boolean;Viewport:TFreeViewport); virtual;
      procedure   SwapData;
      property    Crease             : Boolean read FCrease write FSetCrease;
      property    EdgeIndex          : integer read FGetIndex;
      property    EndPoint           : TFreeSubdivisionPoint read FEndPoint write FEndPoint;
      property    Face[index:integer]: TFreeSubdivisionFace read FGetFace;
      property    NumberOfFaces      : integer read FGetNumberOfFaces;
      property    StartPoint         : TFreeSubdivisionPoint read FStartPoint write FStartPoint;
end;
TFreesubdivisionControlEdge= class(TFreeSubdivisionEdge)
   private
      function  FGetColor:TColor;
      function  FGetIndex:Integer; override;
      procedure FSetSelected(val:Boolean);
      function  FGetSelected:Boolean;
      function  FGetVisible:Boolean;
   public
      procedure   Collapse;
      constructor Create(Owner:TFreeSubdivisionSurface); override;
      procedure   Delete;
      procedure   Draw(DrawMirror:Boolean;Viewport:TFreeViewport); override;
      function    InsertControlPoint(P:T3DVector):TFreeSubdivisionControlpoint;
      procedure   LoadFromStream(var LineNr:Integer;Strings:TStringList);
      procedure   SaveToStream(Strings:TStringlist);
      property    Color   : TColor read FGetColor;
      property    Selected: boolean read FGetSelected write FSetSelected; // Property to see if this edge has been selected by the user
      property    Visible : Boolean read FGetVisible;
end;

TFreeSubdivisionFace  = class(TFreeSubdivisionBase)
   private
      FPoints: TFasterlist;
      function FGetNumberOfPoints:Integer;
      function FGetPoint(Index:Integer):TFreeSubdivisionPoint;
   public
      procedure   AddPoint(Point:TFreeSubdivisionPoint);
      function    CalculateFacePoint:TFreeSubdivisionPoint;
      procedure   Clear; virtual;
      constructor Create(Owner:TFreeSubdivisionSurface); override;
      destructor  Destroy; override;
      function    IndexOfPoint(P:TFreeSubdivisionPoint):Integer;
      procedure   Subdivide(Owner:TFreeSubdivisionSurface;ControlFace:Boolean;VertexPoints,EdgePoints,FacePoints,InteriorEdges,ControlEdges,Dest:TFasterList);virtual;
      property    NumberOfpoints                : Integer read FGetNumberOfPoints;
      property    Point[index:Integer]          : TFreeSubdivisionPoint read FGetPoint;
end;
TFreeSubdivisionControlFace = class(TFreeSubdivisionFace)
   private
      FLayer: TFreeSubdivisionLayer;
      FChildren: TFasterList;
      FMin,FMax: T3DVector;
      FEdges   : TFasterList;
      FControlEdges: TFasterList;
      function FGetChild(Index:Integer):TFreeSubdivisionFace;
      function FGetChildCount:Integer;
      function FGetColor:TColor;
      function FGetControlEdge(Index:Integer):TFreeSubdivisionEdge;
      function FGetControlEdgeCount:Integer;
      function FGetEdge(Index:Integer):TFreeSubdivisionEdge;
      function FGetEdgeCount:Integer;
      function FGetIndex:Integer;
      function FGetSelected:Boolean;
      function FGetVisible:Boolean;
      procedure FSetLayer(Val:TFreeSubdivisionLayer);
      procedure FSetSelected(val:Boolean);
   public
      procedure   CalcExtents;
      procedure   Clear;                                                   override;
      procedure   ClearChildren;
      constructor Create(Owner:TFreeSubdivisionSurface);                   override;
      function    DistanceToCursor(X,Y:Integer;var P:T3DVector;Viewport:TFreeViewport):integer;
      procedure   Delete;
      destructor  Destroy;                                                 override;
      procedure   Draw(Viewport:TFreeViewport;mode:TPenMode);              virtual;
      function    InsertEdge(P1,P2:TFreeSubdivisionControlPoint):TFreesubdivisionControlEdge;
      procedure   LoadFromStream(var LineNr:Integer;Strings:TStringList);
      procedure   RemoveReferences;
      procedure   SaveToStream(Strings:TStringlist);                       virtual;
      procedure   Subdivide( Owner:TFreeSubdivisionSurface;
                             ControlFace:Boolean;
                             VertexPoints,EdgePoints,FacePoints,InteriorEdges,ControlEdges,Dest:TFasterList);override;
      property    Color                     : TColor read FGetColor;
      property    ControlEdge[index:Integer]: TFreeSubdivisionEdge read FGetControlEdge;
      property    ControlEdgeCount          : Integer read FGetControlEdgeCount;
      property    Child[index:Integer]      : TFreeSubdivisionFace read FGetChild;
      property    ChildCount                : integer read FGetChildCount;
      property    Edge[index:Integer]       : TFreeSubdivisionEdge read FGetEdge;
      property    EdgeCount                 : Integer read FGetEdgeCount;
      property    FaceIndex                 : integer read FGetIndex;
      property    Layer                     : TFreeSubdivisionLayer read FLayer write FSetLayer;
      property    Max                       : T3DVector read FMax;
      property    Min                       : T3DVector read FMin;
      property    Selected                  : boolean read FGetSelected write FSetSelected;// Property to see if this controlface has been selected by the user
      property    Visible                   : Boolean read FGetVisible;
end;
//
// This is the subdivision surface used for modelling the hull.
// This is actually a quad-triangle subdivision surface as publisehed in the articles:
//      "Quad/triangle subdivision" by J. Stam & C.
//      Loop http://research.microsoft.com/~cloop/qtEG.pdf
//      "On C2 triangle/quad subdivision" by Scott Schaeffer & Joe Warren
//
TFreeSubdivisionSurface = class(TFreeEntity)
   private
      FControlPoints             : TFasterList; // List with controlpoints, which can be changed by the user
      FControlEdges              : TFasterList; // List with controledges, which can be changed by the user
      FControlFaces              : TFasterList; // List with controlfaces, which can be changed by the user
      FPoints                    : TFasterList; // List with points obtained by subdividing the surface
      FEdges                     : TFasterList; // this list edges obtained by subdividing the controledges
      FLayers                    : TFasterList; // All layers are stored in this list
      FSelectedControlPoints     : TFasterList; // Controlpoints which are selected by the user are put in this list
      FSelectedControlEdges      : TFasterList; // List with currently selected controledges
      FSelectedControlFaces      : TFasterList; // List with currently selected controlfaces
      FActiveLayer               : TFreeSubdivisionLayer;// Currently active layer, may not be nil!
      FShowControlNet            : Boolean;     // Flag to switch controlpoints and control-edges visibility
      FInitialized               : Boolean;     // Flag to check if the surface has been initialised.
      FShowInteriorEdges         : Boolean;     // Switch to turn on drawing off all interior edges as well.
      FDrawMirror                : Boolean;     // If this is set tot true, the other imaginary half (starbaord side) will be drawn aswell
      FDesiredSubdivisionLevel   : byte;
      FCurrentSubdivisionLevel   : byte;
      FCreaseColor               : TColor;
      FLastusedLayerID           : integer;
      FOnChangeLayerData         : TNotifyEvent; // Event which is raised when layer-data has been changed
      FOnChangeActiveLayer       : TChangeActiveLayerEvent; // Event raised when the active layer is changed
      FOnSelectItem              : TNotifyEvent; // This event is raised whenever an item (such as controlpoint, controledge or controlface) is selected or deselected
      function FGetControlPoint(Index:Integer):TFreeSubdivisionControlPoint;
      function FGetControlEdge(Index:Integer):TFreesubdivisionControlEdge;
      function FGetControlFace(Index:Integer):TFreeSubdivisionControlFace;
      function FGetLayer(Index:Integer):TFreeSubdivisionLayer;
      function FGetNumberOfControlPoints:Integer;
      function FGetNumberOfControlEdges:Integer;
      function FGetNumberOfControlFaces:Integer;
      function FGetNumberOfFaces:Integer;
      function FGetNumberOfLayers:Integer;
      function FGetPoint(Index:Integer):TFreeSubdivisionPoint;
      function FGetEdge(Index:Integer):TFreeSubdivisionEdge;
      function FGetNumberOfPoints:Integer;
      function FGetNumberOfSelectedControlEdges:Integer;
      function FGetNumberOfSelectedControlFaces:Integer;
      function FGetNumberOfSelectedControlPoints:Integer;
      function FGetNumberOfEdges:Integer;
      function FGetSelectedControlEdge(Index:Integer):TFreeSubdivisionControlEdge;
      function FGetSelectedControlFace(Index:Integer):TFreeSubdivisionControlFace;
      function FGetSelectedControlPoint(Index:Integer):TFreeSubdivisionControlPoint;
      function FRequestNewLayerID:Integer;
      procedure FSetActiveLayer(Val:TFreeSubdivisionLayer);
      procedure FSetBuild(Val:Boolean); override;
      procedure FSetDesiredSubdivisionLevel(val:byte);
      procedure FSetFShowControlNet(Val:Boolean);
   public
      function    AddControlEdge(P1,P2:TFreeSubdivisionPoint):TFreesubdivisionControlEdge; overload;virtual;
      procedure   AddControlEdge(Edge:TFreesubdivisionControlEdge); reintroduce;overload;
      function    AddControlFace(Points:array of T3DVector;NoPoints:Integer):TFreeSubdivisionControlFace; overload;virtual;
      function    AddControlFace(Points:TFasterList):TFreeSubdivisionControlFace; reintroduce;overload;
      function    AddControlFace(Points:TFasterList;Layer:TFreeSubdivisionLayer):TFreeSubdivisionControlFace; reintroduce;overload;
      procedure   AddControlFace(Face:TFreeSubdivisionControlFace); reintroduce;overload;
      function    AddControlPoint(P:T3DVector):TFreeSubdivisionControlPoint; overload;virtual;
      function    AddControlPoint(P:T3DVector;BoundaryVertices:TFasterList):TFreeSubdivisionControlPoint; reintroduce;overload;
      procedure   AddControlPoint(P:TFreeSubdivisionControlPoint); reintroduce;overload;
      function    AddControlPoint:TFreeSubdivisionControlPoint; reintroduce;overload; // Adds a new controlpoint at 0,0,0 without checking other points
      function    AddNewLayer:TFreeSubdivisionLayer;
      procedure   Clear; override;
      procedure   ClearFaces;
      procedure   Clearselection;
      procedure   Edge_Connect;
      procedure   Extents(Var Min,Max : T3DVector); override;
      procedure   CalculateIntersections(Plane:T3DPlane;Faces,Destination:TFasterList);
      constructor Create; override;
      destructor  Destroy; override;
      procedure   Draw(Viewport:TFreeViewport;Mode:TPenmode); override;
      function    EdgeExists(P1,P2:TFreeSubdivisionPoint):TFreeSubdivisionEdge;
      procedure   Initialize(PointStartIndex,EdgeStartIndex,FaceStartIndex:Integer);
      function    IntersectPlane(Plane:T3DPlane;List:TFasterList):Boolean;
      procedure   IsolateEdges(Source,Destination:TFasterList);overload;virtual;
      procedure   LoadFromStream(var LineNr:Integer;Strings:TStringList);
      procedure   Rebuild; override;
      procedure   SaveToStream(Strings:TStringlist);
      procedure   Selection_Delete;
      procedure   SortEdges(Edges:TFasterList); overload;virtual;
      procedure   SortEdges(Edges:TFasterList;var Points:TFasterList); reintroduce;overload;
      procedure   SubDivide;
      property    ActiveLayer                : TFreeSubdivisionLayer read FActiveLayer write FSetActiveLayer;
      property    ControlPoint[index:Integer]: TFreeSubdivisionControlPoint read FGetControlpoint;
      property    ControlEdge[index:Integer] : TFreesubdivisionControlEdge read FGetControlEdge;
      property    ControlFace[index:Integer] : TFreeSubdivisionControlFace read FGetControlFace;
      property    CurrentSubdivisionLevel    : byte read FCurrentSubdivisionLevel;
      property    CreaseColor                : TColor read FCreaseColor write FCreaseColor;
      property    DesiredSubdivisionLevel    : byte read FDesiredSubdivisionLevel write FSetDesiredSubdivisionLevel;
      property    DrawMirror                 : boolean read FDrawMirror write FDrawMirror;
      property    Layer[index:integer]       : TFreeSubdivisionLayer read FGetLayer;
      property    NumberOfControlFaces       : Integer read FGetNumberOfControlFaces;
      property    NumberOfControlEdges       : Integer read FGetNumberOfControlEdges;
      property    NumberOfControlPoints      : Integer read FGetNumberOfControlPoints;
      property    NumberOfFaces              : Integer read FGetNumberOfFaces;
      property    NumberOfLayers             : Integer read FGetNumberOfLayers;
      property    NumberOfSelectedControlEdges : Integer read FGetNumberOfSelectedControlEdges;
      property    NumberOfSelectedControlFaces : Integer read FGetNumberOfSelectedControlFaces;
      property    NumberOfSelectedControlPoints: Integer read FGetNumberOfSelectedControlPoints;
      property    OnChangeActiveLayer : TChangeActiveLayerEvent read FOnChangeActiveLayer write FOnChangeActiveLayer;
      property    OnChangeLayerData   : TNotifyEvent read FOnChangeLayerData write FOnChangeLayerData;
      property    OnSelectItem        : TNotifyEvent read FOnSelectItem write FOnSelectItem;
      property    Point[index:Integer]: TFreeSubdivisionPoint read FGetpoint;
      property    Edge[index:Integer] : TFreeSubdivisionEdge read FGetEdge;
      property    NumberOfEdges       : Integer read FGetNumberOfEdges;
      property    NumberOfPoints      : Integer read FGetNumberOfPoints;
      property    SelectedControlEdge[index:Integer] : TFreeSubdivisionControlEdge read FGetSelectedControlEdge;
      property    SelectedControlFace[index:Integer] : TFreeSubdivisionControlFace read FGetSelectedControlFace;
      property    SelectedControlPoint[index:Integer]: TFreeSubdivisionControlPoint read FGetSelectedControlPoint;
      property    ShowControlNet   : boolean read FShowControlNet write FSetFShowControlNet;
      property    ShowInteriorEdges: Boolean read FShowInteriorEdges write FShowInteriorEdges;
end;

const Zero : T3DVector  = (X:0.0;Y:0.0;Z:0.0);

function  BoolToStr(Val:Boolean):String; // In contrast to delphi's own BoolToStrF this procedure returns '0' when false and '1' when true
Function  DistanceToLine(P1,P2:TPoint;X,Y:Integer;var Parameter:TFloatType):TFloatType;
function  DotProduct( U,V: T3DVector) : TFloatType;
function  Interpolate(P1,P2:T3DVector;Param:TFloatType):T3DVector; // perform linear interpolation between two 3D points
procedure MinMax(P:T3DVector;var Min,Max:T3DVector);
function  Midpoint(P1,P2:T3DVector):T3DVector;               // Calculate the mid-point between P1 and P2
function  PlaneIntersectsBox(Min,Max:T3DVector;Plane:T3DPlane):Boolean; // Function to determine if a plane intersects a bounding box
function  Truncate(Value:TFloatType;Maxlength:integer):String;// Convert a floatingpoint to a string value with a max. number of specified decimals All trailing zeros will be removed
Function  UnifiedNormal(P1,P2,P3:T3DVector):T3DVector;        // calculate the normal of a plane defined by points P1,P2,P3 and scale to unit-length
procedure Register;

implementation Uses Main;

function BoolToStr(Val:Boolean):String;
   begin if val then result:='1' else Result:='0'; end;


Function DistanceToLine(P1,P2:TPoint;X,Y:Integer;var Parameter:TFloatType):TFloatType;
var Pt  : T2DCoordinate;
begin
   if (P1.X<0) and (P2.X<0) then Result:=5000 else
      if (P1.X>Screen.Width) and (P2.X>Screen.width) then Result:=5000 else
         if (P1.Y<0) and (P2.Y<0) then Result:=5000 else
            if (P1.Y>Screen.Height) and (P2.Y>Screen.Height) then Result:=5000 else
   if (P2.X=P1.X) and (P1.Y=P2.Y) then begin
      Result:=hypot( P1.X-X,P1.Y-Y );          //Sqrt(Sqr(P1.X-X)+Sqr(P1.Y-Y));
   end else begin
      Parameter:=((X-P1.X)*(P2.X-P1.X)+(Y-P1.Y)*(P2.Y-P1.Y))
               / ( sqr(P2.X-P1.X)+Sqr(P2.Y-P1.Y) );
      if (Parameter>=0) and (Parameter<=1) then begin
         Pt.X:=P1.X+Parameter*(P2.X-P1.X);
         Pt.Y:=P1.Y+Parameter*(P2.Y-P1.Y);
         if (Pt.X>=0) and (Pt.Y>=0)
         and (Pt.X<=Screen.Width)
         and (Pt.Y<=Screen.Height) then Result:=hypot( Pt.X-X,Pt.Y-Y ) //Sqrt(Sqr(Pt.X-X)+Sqr(Pt.Y-Y))
                                   else Result:=1e10;
      end else Result:=1e10;
   end;
end;
function DotProduct(U, V : T3DVector) : TFloatType;
   begin Result:=(U.X * V.X)+(U.Y * V.Y)+(U.Z * V.Z); end;

function Interpolate(P1,P2:T3DVector;Param:TFloatType):T3DVector;
   begin Result := P1 + Param*(P2-P1);  end;

// This procedure takes a lot of linesegments and tries to connect them into as few as possible splines
procedure JoinSplineSegments(JoinError:TFloatType;ForceToOneSegment:Boolean;List:TFasterList);

type TSegmentRecord = record
        Length: TFloatType;
        COG: T3DVector;
     end;
     TSegmentdata = array[0..0] of TSegmentRecord;
     PSegmentdata = ^TSegmentdata;
var I,J,MatchIndex : Integer;
    Fixed,Match,Nearest : TFreeSpline;
    NearestDist,Min,D1,D2,D3,D4: TFloatType;
    FixedClosed,MatchClosed: Boolean;

    function Minimum(D1,D2,D3,D4:TFloatType):TFloatType;
    begin Result:=D1;
       if D2<Result then Result:=D2;
       if D3<Result then Result:=D3;
       if D4<Result then Result:=D4;
    end; {Minimum}
begin                                  // First remove any single linesegments;
   I:=1;
   while I<List.Count do begin
      Fixed:=List.Items[I-1];
      if Fixed.NumberOfPoints>1 then FixedClosed:=Abs(Fixed.Point[0]-Fixed.Point[Fixed.NumberOfPoints-1])<1e-5
                                else FixedClosed:=False;
      if (Fixed.NumberOfPoints>1) and (Not FixedClosed) then begin
         NearestDist:=1e30;
         Nearest:=nil;
         MatchIndex:=-1;
         for J:=1 to List.Count do if I<>J then begin
            Match:=List.Items[J-1];
            if Match.NumberOfPoints>1 then MatchClosed:=Abs(Match.Point[0]-Match.Point[Match.NumberOfPoints-1])<1e-5
                                      else MatchClosed:=False;
            if (Match.NumberOfPoints>1) and (Not MatchClosed) then begin
               D1:=Sqr(Fixed.Point[0]-Match.Point[0]);
               D2:=Sqr(Fixed.Point[0]-Match.Point[Match.NumberOfPoints-1]);
               D3:=Sqr(Fixed.Point[Fixed.NumberOfPoints-1]-Match.Point[0]);
               D4:=Sqr(Fixed.Point[Fixed.NumberOfPoints-1]-Match.Point[Match.NumberOfPoints-1]);
               Min:=Minimum(D1,D2,D3,D4);
               if Min<NearestDist then begin
                  NearestDist:=Min;
                  Nearest:=Match;
                  MatchIndex:=J;
                  if Min<1e-5 then break;
               end;
            end;
         end;
         if Nearest<>nil then begin
            Match:=Nearest;
            D1:=Sqr(Fixed.Point[0]-Match.Point[0]);
            D2:=Sqr(Fixed.Point[0]-Match.Point[Match.NumberOfPoints-1]);
            D3:=Sqr(Fixed.Point[Fixed.NumberOfPoints-1]-Match.Point[0]);
            D4:=Sqr(Fixed.Point[Fixed.NumberOfPoints-1]-Match.Point[Match.NumberOfPoints-1]);
            Min:=Minimum(D1,D2,D3,D4);
            if (Min<JoinError) or (ForceToOneSegment) then begin // The splines do touch each other on one of their ends
               // Increase capacity of fixed spline
               Fixed.Capacity:=Fixed.Capacity+Match.NumberOfPoints;
               if Min=D1 then begin                                   // Case 1
                  Fixed.InsertSpline(0,True,Match);
               end else if Min=D2 then begin                          // Case 2
                  Fixed.InsertSpline(0,False,Match);
               end else if Min=D3 then begin                          // Case 3
                  Fixed.InsertSpline(Fixed.NumberOfPoints,False,Match);
               end else if Min=D4 then begin                          // Case 4
                  Fixed.InsertSpline(Fixed.NumberOfPoints,True,Match);
               end else messagedlg('Error in comparing minimum values.',mterror,[mbok],0);
               List.Delete(MatchIndex-1);        // Destroy the matching spline
               Match.Destroy;
               I:=0; // Reset match index to start searching for a new matching spline
            end;
         end;
      end; Inc(I);
   end;
end;
                                   // Calculate the mid-point between P1 and P2
function Midpoint( P1,P2:T3DVector ):T3DVector;
   begin Result:=0.5*( P1+P2 ); end;

// Function to determine if a plane intersects a bounding box
function PlaneIntersectsBox(Min,Max:T3DVector;Plane:T3DPlane):Boolean;
var P: array[1..8] of T3DVector;
    I: Integer;
    S,SMin,SMax: TFloatType;
begin
   SMin:=0;
   SMax:=0;
   P[1].X:=Min.X;   P[1].Y:=Min.Y;   P[1].Z:=Min.Z;
   P[2].X:=Max.X;   P[2].Y:=Min.Y;   P[2].Z:=Min.Z;
   P[3].X:=Max.X;   P[3].Y:=Max.Y;   P[3].Z:=Min.Z;
   P[4].X:=Min.X;   P[4].Y:=Max.Y;   P[4].Z:=Min.Z;
   P[5].X:=Min.X;   P[5].Y:=Min.Y;   P[5].Z:=Max.Z;
   P[6].X:=Max.X;   P[6].Y:=Min.Y;   P[6].Z:=Max.Z;
   P[7].X:=Max.X;   P[7].Y:=Max.Y;   P[7].Z:=Max.Z;
   P[8].X:=Min.X;   P[8].Y:=Max.Y;   P[8].Z:=Max.Z;
   for I:=1 to 8 do begin
      S:=Plane.A*P[I].x+Plane.B*P[I].y+Plane.C*P[I].z+Plane.D;
      if I=1 then begin SMin:=S; SMax:=S; end;
      if S<SMin then SMin:=S;
      if S>SMax then SMax:=S;
   end;
   Result:=((Smin<=0.0) and (SMax>=0.0))
       or  ((SMax<=0.0) and (SMin>=0.0));
end;

function Truncate( Value:TFloatType; Maxlength:integer ): String;
// Convert a floatingpoint to a string value with a max. number of specified decimals
begin                                     // All trailing zeros will be removed
   Result:=FloatToStrF(Value,ffFixed,10,Maxlength);
   while Result[Length(Result)]='0' do Delete(Result,Length(Result),1);
   if Length(Result)<MaxLength then Result:=Result+'0' else
      if Result[Length(Result)] in ['.',','] then Result:=Result+'0';
end;

procedure MinMax( P:T3DVector; var Min,Max:T3DVector );
begin if P.X<Min.X then Min.X:=P.X; if P.X>Max.X then Max.X:=P.X;
      if P.Y<Min.Y then Min.Y:=P.Y; if P.Y>Max.Y then Max.Y:=P.Y;
      if P.Z<Min.Z then Min.Z:=P.Z; if P.Z>Max.Z then Max.Z:=P.Z;
end;

Function UnifiedNormal(P1,P2,P3:T3DVector):T3DVector;
var L:TFloatType;
begin
   Result:=(P2-P1)*(P3-P1);
   L:=Abs( Result );                                // VectorMagnitude(Result);
   if L<1e-6 then L:=1e-6;
   Result:=Result/L;
end;
function Unify( P:T3DVector ):T3DVector; // unify a T3DVector to unit length
var L:TFloatType;
begin L:=Abs( P );                            // Sqrt(P.X*P.X+P.Y*P.Y+P.Z*P.Z);
   if L<1e-6 then L:=1e-6;
   Result:=P/L;
end;
{
function VectorMagnitude(Normal:T3DVector) : TFloatType; // calculate the length of a T3DVector
var Tmp:TFloatType;
begin Tmp:=(Normal.X*Normal.X) + (Normal.Y*Normal.Y) + (Normal.Z*Normal.Z);
   if Tmp<=1.e-14 then Result:=0.0000001
                  else Result:=Sqrt( Tmp );
end;
}
{----------------------------------------------}
{ Z-buffer class used in the shading algorithm }
{----------------------------------------------}
procedure TFreeZBuffer.Initialize; var I: Integer;
begin
   if (FWidth<=FViewport.ClientWidth+3)
   or (FHeight<=FViewport.ClientHeight+3) then begin
       FWidth:=FViewport.ClientWidth+3;
       FHeight:=FViewport.ClientHeight+3;
                              Setlength( FBuffer,FHeight );
     for I:=0 to FHeight-1 do Setlength( FBuffer[I],FWidth );
   end;                        // initalize all pixel cells to an initial value
   for I:=0 to FWidth-1 do FBuffer[0][I]:=-1e8;
   for I:=1 to FHeight-1 do
            Move( FBuffer[0][0],FBuffer[I][0],FWidth*SizeOf(TFloatType) );
end;
{-----------------------------}
{ TFreeViewport               }
{ This is a 3D drawingcanvas. }
{-----------------------------}
procedure TFreeViewport.FSetAngle(Val:TFloatType);
begin
   if Val<>FAngle then begin
      FAngle:=Val;
      FCosAngle:=Cos(DegToRad(FAngle));
      FSinAngle:=sin(DegToRad(FAngle)); //refresh;
      InitializeViewport(FMin3D,FMax3D);
   end;
end;

function TFreeViewport.FGetPenStyle:TPenStyle;
   begin Result:=Canvas.Pen.Style; end;
function TFreeViewport.FGetPenColor:TColor;
   begin Result:=Canvas.Pen.Color; end;

procedure TFreeViewport.FSetCameraType(Val:TFreeCameraType);
var Film,Dist : TFloatType;
begin
   if Val<>FCameraType then begin
      Film:=35;   // standard 35mm. film
      Case Val of
         ftWide         : Dist:=20;
         ftStandard     : Dist:=50;
         ftShortTele    : Dist:=90;
         ftMediumTele   : Dist:=130;
         ftFarTele      : Dist:=200;
         else Dist:=50;
      end;
      FCameraType:=Val;
      FFieldOfView:=RadToDeg(ArcTan(Film/Dist));
      InitializeViewport( FMin3D,FMax3D );
   end;
end;

procedure TFreeViewport.FSetElevation(Val:TFloatType);
begin
   if Val<>FElevation then begin
      FElevation:=Val;
      FCosElevation:=Cos(DegToRad(FElevation));
      FSinElevation:=sin(DegToRad(FElevation)); // refresh;
      InitializeViewport(FMin3D,FMax3D);
   end;
end;
procedure TFreeViewport.FSetPan(Val:TPoint);
    begin if (FPan.X<>Val.X) or (FPan.Y<>Val.Y) then begin FPan:=Val; Refresh; end;
    end;
procedure TFreeViewport.FSetPenColor(Val:TColor);
    begin if Canvas.Pen.Color<>val then Canvas.Pen.Color:=Val; end;
procedure TFreeViewport.FSetPenStyle(Val:TPenStyle);
    begin if Canvas.Pen.Style<>val then Canvas.Pen.Style:=Val; end;
procedure TFreeViewport.FSetShade(Val:Boolean);
    begin if val<>FShade then begin FShade:=Val; Refresh; end; end;

procedure TFreeViewport.FSetViewType(Val:TFreeViewType);
begin
   if Val<>FViewType then begin
      FViewType:=Val;
      FZoom:=1.0;
      FPan.X:=0;
      FPan.Y:=0;
      Case FViewtype of
         fvBodyplan :begin FAngle:=0; FElevation:=0; end;
         fvProfile  :begin FAngle:=90; FElevation:=0; end;
         fvPlan     :begin FAngle:=90; FElevation:=90; end;
         fvPerspective:begin FAngle:=20; FElevation:=20; end;
      end;
      InitializeViewport( FMin3D,FMax3D );
      if assigned(FOnChangeViewType) then FOnChangeViewType(self);
   end;
end;

procedure TFreeViewport.WMMouseLeave(var Message: TMessage);
begin inherited;
      if Assigned(FOnMouseLeave) then FOnMouseLeave(Self);
end;

constructor TFreeViewport.Create(AOwner:TComponent);
begin
   FAngle:=20;
   FElevation:=20;
   FDistance:=1e4;
   FZoom:=1.0;
   FPan.X:=0;
   FPan.Y:=0;
   FCameraType:=ftStandard; // Standard 50mm. lens, field of view= 35/50 =35 degrees.
   FFieldOfView:=RadToDeg(ArcTan(35/50));
   FViewType:=fvPerspective;
   Inherited create(AOwner);
   FZBuffer:=TFreeZBuffer.Create;
   FZBuffer.FBuffer:=nil;
   FZBuffer.FHeight:=0;
   FZBuffer.FWidth:=0;
   FZBuffer.FViewport:=self;
   FLight.Position.X:=50;
   FLight.Position.Y:=20;
   FLight.Position.Z:=2;
   FLight.Ambient:=75;
   FLight.Luminance:=140;
end;

destructor TFreeViewport.Destroy;
begin
   FZBuffer.Destroy;
   inherited Destroy;
end;
procedure TFreeViewport.DrawLineToZBuffer( P1,P2:T3DVector;R,G,B:Integer );
var d,x,y,ax,ay,sx,sy,dx,dy:Integer;
    IncZ:TFloatType;
    Pt1,Pt2 : TShadePoint;              //P1,P2: T3DVector;
    Color: TColor;
begin                                   //P1:=Point1; P2:=Point2;
   Pt1:=ProjectToZBuffer(P1);           Color:=RGBtoColor( R,G,B );
   Pt2:=ProjectToZBuffer(P2);
   dx:=Pt2.X-Pt1.X;
   dy:=Pt2.Y-Pt1.Y;
   ax:=Abs( dx ) SHL 1;
   ay:=Abs( dy ) SHL 1;
   if dx>=0 then sx:=1 else sx:=-1;
   if dy>=0 then sy:=1 else sy:=-1;
   x:=Pt1.X;                       if (X<0) or (X>=ClientWidth) then exit;
   y:=Pt1.Y;                       if (Y<0) or (Y>=ClientHeight) then exit;
   if ax>ay then begin
      if Pt2.X-Pt1.X<>0.0 then IncZ:=(Pt2.Z-Pt1.Z)/(Pt2.X-Pt1.X)
                          else IncZ:=0;
      d:=ay-ax SHR 1;
      While X<>Pt2.X do begin
         if (X>=0) and (X<ClientWidth) then
         if (Y>=0) and (Y<ClientHeight) then
         if 1.02*Pt1.Z>FZBuffer.FBuffer[Y][X] then begin
            Canvas.Pixels[X,Y]:=Color;
            FZBuffer.FBuffer[Y][X]:=Pt1.Z;
         end;
         if d>=0 then begin inc(Y,sy); dec(d,ax); end;
         inc(x,sx);
         inc(d,ay);
         Pt1.Z:=Pt1.Z+IncZ;
      end;
   end else begin
      d:=ax-ay SHR 1;
      if Pt2.Y-Pt1.Y<>0.0 then IncZ:=(Pt2.Z-Pt1.Z)/(Pt2.Y-Pt1.Y)
                          else IncZ:=0;
      while Y<>Pt2.Y do begin
         if (X>=0) and (X<ClientWidth) then
         if (Y>=0) and (Y<ClientHeight) then
         if 1.02*Pt1.Z>FZBuffer.FBuffer[Y][X] then begin
            Canvas.Pixels[X,Y]:=Color;
            FZBuffer.FBuffer[Y][X]:=Pt1.Z;
         end;
         if d>=0 then begin inc(x,sx); dec(d,ay); end;
         inc(y,sy);
         inc(d,ax);
         Pt1.Z:=Pt1.Z+IncZ;
      end;
   end;
end; {TFreeViewport.DrawLineToZBuffer}

procedure TFreeViewport.InitializeViewport(Min,Max:T3DVector);
// This procedure initializes the viewports and sets the scale uin such a way
// that the model completely fills the viewport
var P: array[1..8] of T3DVector;
    Projected,Min2D,Max2D: T2DCoordinate;
    P3D: T3DVector;
    I,VertCorr,HorCorr: Integer;
    Width,Height,Tmp: TFloatType;
    Pt1,Pt2: TPoint;
    procedure MinMax(P:T2DCoordinate);
    begin
       if P.X<Min2D.X then Min2D.X:=P.X;
       if P.Y<Min2D.Y then Min2D.Y:=P.Y;
       if P.X>Max2D.X then Max2D.X:=P.X;
       if P.Y>Max2D.Y then Max2D.Y:=P.Y;
    end;
begin                                            // Remember the min/max values
   FMin3D:=Min;
   FMax3D:=Max;                        // Calculate the midpoint of the boundingbox, which is used as the center of the model for rotating the model
   FMidPoint:=MidPoint(FMin3D,FMax3D); // Calculate the distance of the camera to the center of the model, following from the field of view from the camera
   Tmp:=Sqrt(Sqr(FMax3D.Y-FMin3D.Y)+Sqr(FMax3D.Z-FMin3D.Z));
   if Tmp=0 then Tmp:=1e-2;
   if FViewtype=fvPerspective then begin
      if ArcTan(DegToRad(FFieldOfView))<>0 then begin
         FDistance:=Tmp/ArcTan(DegToRad(FFieldOfView));
         if FDistance>1e5 then FDistance:=1e5;
      end else FDistance:=1e5;
   end else FDistance:=1e8;//1e5;
   FCameraLocation.X:=FMax3D.X+FDistance;
   FCameraLocation.Y:=FMidPoint.Y;
   FCameraLocation.Z:=FMidPoint.Z;

   FCosAngle:=Cos(DegToRad(FAngle));
   FSinAngle:=sin(DegToRad(FAngle));
   FCosElevation:=Cos(DegToRad(FElevation));
   FSinElevation:=sin(DegToRad(FElevation));
           // now project all 8 cornerpoints of the bounding box to 2D in order
           //  to determin the min. and max. 2D coordinates of the 2D viewport.
   P[1].X:=FMin3D.X;   P[1].Y:=FMin3D.Y;   P[1].Z:=FMin3D.Z;
   P[2].X:=FMax3D.X;   P[2].Y:=FMin3D.Y;   P[2].Z:=FMin3D.Z;
   P[3].X:=FMax3D.X;   P[3].Y:=FMax3D.Y;   P[3].Z:=FMin3D.Z;
   P[4].X:=FMin3D.X;   P[4].Y:=FMax3D.Y;   P[4].Z:=FMin3D.Z;
   P[5].X:=FMin3D.X;   P[5].Y:=FMin3D.Y;   P[5].Z:=FMax3D.Z;
   P[6].X:=FMax3D.X;   P[6].Y:=FMin3D.Y;   P[6].Z:=FMax3D.Z;
   P[7].X:=FMax3D.X;   P[7].Y:=FMax3D.Y;   P[7].Z:=FMax3D.Z;
   P[8].X:=FMin3D.X;   P[8].Y:=FMax3D.Y;   P[8].Z:=FMax3D.Z;
   for I:=1 to 8 do begin
      P3D:=RotatedPoint(P[i]);                  // apply perspective projection
      Tmp:=FCameralocation.X-P3D.X;             // apply perspective correction
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
   if (Width<>0) and (Height<>0) then begin
      FXScale:=ClientWidth/Width;
      FYScale:=ClientHeight/Height;
      if FXScale<FYScale then FYScale:=FXScale
                         else FXScale:=FYScale;
   end else begin
      FXScale:=1;
      FYScale:=FXScale;
   end; // Decrease both XScale and YScale with 1% to keep the model free from the edges
   FXScale:=0.99*FXScale;
   FYScale:=0.99*FYScale;
   FScreencenter.X:=ClientWidth div 2;
   FScreencenter.Y:=ClientHeight div 2;
   // Calculate correction (pan T3DVector) to make sure that the ship appears in the middle of the viewport
   Pt1.X:=FScreencenter.X+Round(FXScale*Min2D.X);
   Pt1.Y:=FScreencenter.Y-Round(FYScale*Min2D.Y);
   Pt2.X:=FScreencenter.X+Round(FXScale*Max2D.X);
   Pt2.Y:=FScreencenter.Y-Round(FYScale*Max2D.Y);
   HorCorr:=(Pt1.X+Pt2.X)div 2 - ClientWidth div 2;
   VertCorr:=(Pt1.Y+Pt2.Y)div 2 - ClientHeight div 2;
   FScreencenter.X:=FScreencenter.X-HorCorr;
   FScreencenter.Y:=FScreencenter.Y-vertCorr;   // Now force a complete repaint
   Invalidate;
// FZBuffer.Initialize;
end;

function TFreeViewport.Project(P:T3DVector):TPoint;
var P3D  : T3DVector;
    P2D  : T2DCoordinate;
    Dist:TFloatType;
begin
   P3D:=RotatedPoint(P);
   Dist:=FCameralocation.X-P3D.X;               // apply perspective correction
   P2D.X:=FCameralocation.X*P3D.Y/dist;
   P2D.Y:=FCameralocation.X*P3D.Z/Dist;
   Result.X:=FPan.X+FScreencenter.X+Round(FZoom*FXScale*P2D.X);
   Result.Y:=FPan.Y+FScreencenter.Y-Round(FZoom*FYScale*P2D.Y);
end;

function TFreeViewport.ProjectBack(P:TPoint;Input:T3DVector):T3DVector;
var P2D: T2DCoordinate;
    P1,P2,P3D: T3DVector;
    Dist: TFloatType;
   Function Dist_PL_3D(P,P1,P2:T3DVector):T3DVector; var t:TFloatType;
   begin
      T:=-((P1.X-P.X)*(P2.X-P1.X)+(P1.Y-P.Y)*(P2.Y-P1.Y)
       +(P2.Z-P.Z)*(P2.Z-P1.Z))/(sqr(P2.X-P1.X)+sqr(P2.Y-P1.Y)+sqr(P2.Z-P1.Z));
      Result:=P1+T*(P2-P1);
   end;
begin                   // convert from screencoordinate to 2D world coordinate
   P2D.X:=(P.X-FPan.X-FScreencenter.X)/(FZoom*FXScale);
   P2D.Y:=(P.Y-FPan.Y-FScreencenter.Y)/-(FZoom*FYScale);
   // Now correct for perspective projection and create a 3D ray through the screen coordinate
   P3D.X:=FMin3D.X;
   Dist:=FCameralocation.X-P3D.X;
   P3D.Y:=P2D.X*dist/FCameralocation.X;
   P3D.Z:=P2D.Y*Dist/FCameralocation.X; P1:=RotatedPointBack(P3D);
   P3D.X:=FMax3D.X;
   Dist:=FCameralocation.X-P3D.X;
   P3D.Y:=P2D.X*dist/FCameralocation.X;
   P3D.Z:=P2D.Y*Dist/FCameralocation.X; P2:=RotatedPointBack(P3D);
                    // Finally project point Input on the ray through P1 and P2
   Result:=Dist_PL_3D(Input,P1,P2);
end;

function TFreeViewport.ProjectBackTo2D(P:TPoint):T2DCoordinate;
var P2D: T2DCoordinate;
    P1,P2,P3D: T3DVector;
    Dist: TFloatType;
begin                   // convert from screencoordinate to 2D world coordinate
   P2D.X:=(P.X-FPan.X-FScreencenter.X)/(FZoom*FXScale);
   P2D.Y:=(P.Y-FPan.Y-FScreencenter.Y)/-(FZoom*FYScale);
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

//        Projects a 3D point to screen and calculate it's Z-value for Z-buffer
function TFreeViewport.ProjectToZBuffer(P:T3DVector):TShadePoint;
var P3D    : T3DVector;
    P2D    : T2DCoordinate;
    Dist   : TFloatType;
begin
   P3D:=RotatedPoint(P);
   Dist:=FCameralocation.X-P3D.X;               // apply perspective correction
   P2D.X:=FCameralocation.X*P3D.Y/dist;
   P2D.Y:=FCameralocation.X*P3D.Z/Dist;
   Result.X:=FPan.X+FScreencenter.X+Round(FZoom*FXScale*P2D.X);
   Result.Y:=FPan.Y+FScreencenter.Y-Round(FZoom*FYScale*P2D.Y);
   Result.Z:=FCameralocation.X*P3D.X/Dist;
end;

// Projects a 3D point with a certain z-buffer offset to the screen, used for drawing lines on top of shaded surfaces
function TFreeViewport.ProjectToZBuffer(Scale:TFloatType;P:T3DVector):TShadePoint;
var P3D  : T3DVector;
    P2D  : T2DCoordinate;
    Dist : TFloatType;
begin
   P3D:=RotatedPoint(P);
   Dist:=FCameralocation.X-P3D.X;
   // apply perspective correction
   P2D.X:=FCameralocation.X*P3D.Y/(Dist);
   P2D.Y:=FCameralocation.X*P3D.Z/(Dist);
   Result.X:=FPan.X+FScreencenter.X+Round(FZoom*FXScale*P2D.X);
   Result.Y:=FPan.Y+FScreencenter.Y-Round(FZoom*FYScale*P2D.Y);
   Result.Z:=FCameralocation.X*Scale*P3D.X/Dist;
end;

function TFreeViewport.RotatedPoint(P:T3DVector):T3DVector;
begin
   // This function takes a point from worldspace and rotates it around the midpoint
   // of the scene as specified by the viewing-parameters (angle/elevation)
   // translate midpoint back to origin
   P.X:=P.X-FMidpoint.X;
   P.Y:=P.Y-FMidpoint.Y;
   P.Z:=P.Z-FMidpoint.Z;
   // Rotate around the origin
   Result.x:=(P.x*FCosAngle-P.y*FSinAngle)*FCosElevation+P.z*FSinElevation;
   Result.y:=P.x*FSinAngle+P.y*FCosAngle;
   Result.z:=-(P.x*FCosAngle-P.y*FSinAngle)*FSinElevation+P.z*FCosElevation;
   // Translate origin back to midpoint
   Result.X:=Result.X+FMidPoint.X;
   Result.Y:=Result.Y+FMidPoint.Y;
   Result.Z:=Result.Z+FMidPoint.Z;
end;

function TFreeViewport.RotatedPointBack(P:T3DVector):T3DVector;
var CosAngle,SinAngle,CosElevation,SinElevation: TFloatType;
begin
   // This function takes a point from worldspace and rotates it around
   // the midpoint of the scene as specified by the viewing-parameters
   // (angle/elevation) translate midpoint back to origin
   CosAngle:=Cos(DegToRad(-FAngle));
   SinAngle:=sin(DegToRad(-FAngle));
   CosElevation:=Cos(DegToRad(-FElevation));
   SinElevation:=sin(DegToRad(-FElevation));
   P:=P-FMidPoint; // Rotate a point first around Y-axis then around the Z-axis
   Result.x:=(P.x*CosElevation+P.z*SinElevation)*CosAngle-P.y*SinAngle;
   Result.y:=(P.x*CosElevation+P.z*SinElevation)*SinAngle+P.y*CosAngle;
   Result.z:=(-P.x*SinElevation+P.z*CosElevation);
   Result:=Result+FMidPoint;               // Translate origin back to midpoint
end;

procedure TFreeViewport.Paint;
    begin
      if not (csDestroying in ComponentState) then begin
         if Shade then Canvas.Brush.Color:=clWhite
                  else Canvas.Brush.Color:=Color;
                       Canvas.Brush.Style:=bsSolid;
         if Shade then FZBuffer.Initialize;
         Canvas.Rectangle( -1,-1,ClientWidth+1,ClientHeight+1 );
         if Assigned(OnRedraw) then OnRedraw(Self);
    end;
end;
procedure TFreeViewport.Resize;
    begin Inherited Resize; InitializeViewport( FMin3D,FMax3D ); end;
procedure TFreeViewport.MouseDown(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
    begin Inherited;
      if Assigned(FOnMouseDown) then OnMouseDown(Self,Button,Shift,X,Y);
    end;
procedure TFreeViewport.MouseMove(Shift:TShiftState;X,Y:Integer);
    begin Inherited;
      if Assigned(FOnMouseMove) then OnMouseMove(Self,Shift,X,Y);
    end;
procedure TFreeViewport.MouseUp(Button:TMouseButton;Shift:TShiftState;X,Y:Integer);
    begin Inherited;
      if Assigned(FOnMouseUp) then OnMouseUp(Self,Button,Shift,X,Y);
    end;
procedure TFreeViewport.SetPenWidth(Width:integer);
    begin if Canvas.Pen.Width<>Width then Canvas.Pen.Width:=Width; end;
procedure TFreeViewport.ShadeTriangle(P_1,P_2,P_3:T3DVector;R,G,B:integer);
var Pt1,Pt2,Pt3,T: TShadePoint;
    Center,Normal,LSourceDirection: T3DVector;
    Y,XLeft,dXLeft,XRight,dXRight: Integer;
    ZLeft,dZLeft,ZRight,dZRight,LIntensityRatio: TFloatType;
   procedure Swap(var A,B:Integer); var C:Integer; begin C:=A; A:=B; B:=C; end;
   procedure ShadeLine( X1,X2,Y: integer;Z1,Z2: TFloatType );
   var IncZ,T: TFloatType; Color: TColor;          //     Row: pRGBTripleArray;
   begin
      if (Y<0) or (Y>ClientHeight-1) then exit;
      X1:=X1 div 256;
      X2:=X2 div 256;
      if X1>X2 then begin Swap(X1,X2); T:=Z1; Z1:=Z2; Z2:=T; end;
      if X1<>X2 then IncZ:=(Z2-Z1)/(X2-X1)
                else IncZ:=0;
      if (X1>ClientWidth-1) or (X2<0) then exit;    Color:=RGBtoColor( R,G,B );
      if (X1<0) then begin Z1:=Z1+abs(X1)*IncZ; X1:=0; end;
      if X2>ClientWidth-1 then X2:=ClientWidth-1;
      if X1>=0 then begin     // Use scanline property for faster pixel access
         while X1<=X2 do begin
            if Z1>FZBuffer.FBuffer[Y][X1] then begin
               Canvas.Pixels[X1,Y]:=Color;
               FZBuffer.FBuffer[Y][X1]:=Z1;
            end;
            Z1:=Z1+IncZ;
            Inc( X1 );
         end;
      end;
   end;
begin                                          // Calculate data for the points
   Pt1:=ProjectToZBuffer(P_1);
   Pt2:=ProjectToZBuffer(P_2);
   Pt3:=ProjectToZBuffer(P_3);
   P_1:=RotatedPoint(P_1);
   P_2:=RotatedPoint(P_2);
   P_3:=RotatedPoint(P_3);              // Calculate triangle normal and center
   Normal:=UnifiedNormal(P_1,P_2,P_3);
   Center:=(P_1+P_2+P_3)/3.0;                      // Calculate light T3DVector
   LSourceDirection:=Center-FLight.Position;
   LSourceDirection:=Unify(LSourceDirection);
   LIntensityRatio:=Dotproduct(Normal,LSourceDirection);
   if LIntensityRatio < 0 then begin LIntensityRatio := -LIntensityRatio; end;
   LIntensityRatio:=0.1+1.1*LIntensityRatio;
   R:=Round(LIntensityRatio*R); if R>255 then R:=255;
   G:=Round(LIntensityRatio*G); if G>255 then G:=255;
   B:=Round(LIntensityRatio*B); if B>255 then B:=255; // Sort points according to Y-value
   if Pt2.Y<Pt1.Y then begin T:=Pt1; Pt1:=Pt2; Pt2:=T; end;
   if Pt3.Y<Pt2.Y then begin T:=Pt2; Pt2:=Pt3; Pt3:=T;
     if Pt2.Y<Pt1.Y then begin T:=Pt1; Pt1:=Pt2; Pt2:=T; end;
   end;                           // check if min/max values are outside window
   if ((Pt1.Y>=ClientHeight) or (Pt3.Y<=0))
   or ((Pt1.X<0) and (Pt2.X<0) and (Pt3.X<0))
   or ((Pt1.X>ClientWidth) and (Pt2.X>ClientWidth) and (Pt3.X>ClientWidth)) then exit;
   Pt1.X:=Pt1.X shl 8;
   Pt2.X:=Pt2.X shl 8;
   Pt3.X:=Pt3.X shl 8;
   if Pt3.Y=Pt1.Y then begin
     if Pt2.X>=Pt1.X then ShadeLine(Pt1.X,Pt2.X,Pt1.Y,Pt1.Z,Pt2.Z)
                     else ShadeLine(Pt2.X,Pt1.X,Pt1.Y,Pt2.Z,Pt1.Z);
     if Pt3.X>=Pt2.X then ShadeLine(Pt2.X,Pt3.X,Pt1.Y,Pt2.Z,Pt3.Z)
                     else ShadeLine(Pt3.X,Pt2.X,Pt3.Y,Pt3.Z,Pt2.Z);
     Exit;
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
         Inc(XLeft,dXLeft);
         ZLeft:=ZLeft+dZLeft;
         Inc(XRight,dXRight);
         ZRight:=ZRight+dZRight;
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
      Inc(XLeft,dXLeft);
      ZLeft:=ZLeft+dZLeft;
      Inc(XRight,dXRight);
      ZRight:=ZRight+dZRight;
   end;
end;

procedure TFreeViewport.ZoomExtents;
var Min,Max:T3DVector;
begin
   if Assigned(FOnRequestExtents) then begin
      FOnRequestExtents( self,Min,Max );
      FZoom:=1.0;
      FPan.X:=0;
      FPan.Y:=0;
      InitializeViewport(Min,Max);
   end;
end;
procedure TFreeViewport.ZoomIn; begin FZoom:=FZoom*1.1; Refresh; end;
procedure TFreeViewport.ZoomOut; begin FZoom:=FZoom/1.1; Refresh; end;

{----------------------------------------------------------}
{ This is the base class of all 3D entities in the project }
{----------------------------------------------------------}
function TFreeEntity.FGetMin:T3DVector;
   begin if not Build then Rebuild; Result:=FMin; end;
function TFreeEntity.FGetMax:T3DVector;
   begin if not Build then Rebuild; Result:=FMax; end;
procedure TFreeEntity.FSetBuild(Val:Boolean);
begin if Val<>FBuild then begin FBuild:=Val;
          if not Val then begin FMin:=ZERO; FMAx:=ZERO; end; end;
end;
constructor TFreeEntity.Create;               // Create and initialise all data
      begin inherited Create; Clear; Build:=False; end;
destructor TFreeEntity.Destroy; begin Inherited Destroy; end;
procedure TFreeEntity.Clear;
begin
   Build:=False;
   FMin:=ZERO;
   FMAx:=ZERO;
   FColor:=clBlack;
   FPenwidth:=1;
   FPenStyle:=psSolid;
end;
procedure TFreeEntity.Extents(Var Min,Max : T3DVector);
begin
   if not Build then Rebuild;
   MinMax(FMin,Min,Max);
   MinMax(FMax,Min,Max);
end;
procedure TFreeEntity.Draw; begin end;
procedure TFreeEntity.Rebuild; begin end;

{--------------------------------------------------------------------}
{ 3D CSpline                                                         }
{ Copied from page 107 of the book: "Numerical recipes in fortan 77" }
{ Url: http://www.library.cornell.edu/nr/bookfpdf/f3-3.pdf           }
{ Modified to use chordlength parametrisation for smoother           }
{ interpolation and to accept knuckles in the controlpoints          }
{--------------------------------------------------------------------}
procedure TFreeSpline.FSetBuild(val:boolean);
begin
   if not val then
   begin
      Setlength(FDerivatives,0);
      Setlength(FParameters,0);                               // Clear extents
      FMin:=ZERO;
      FMax.X:=1;
      FMax.Y:=1;
      Fmax.Z:=1;
   end;
   Inherited FSetBuild(Val);
end;

procedure TFreeSpline.FSetCapacity(Val:integer);
begin
   if Val<>FCapacity then begin
      FCapacity:=Val;
      Setlength(FPoints,FCapacity);
      if FNoPoints>FCapacity then begin // Make sure that number of points does not exceed the capacity of the curve
         FNoPoints:=FCapacity;
         Build:=false;
      end;
      Setlength(FKnuckles,FCapacity);
   end;
end;

procedure TFreeSpline.FSetFragments(Val:Integer);
begin
   if Val<>FFragments then begin
      FFragments:=val;
      Build:=False;
   end;
end;

function TFreeSpline.FGetFragments:Integer;
begin
   Result:=FFragments;
end;

function TFreeSpline.FGetKnuckle(Index:integer):Boolean;
begin if (Index>=0) and (Index<FNoPoints) then Result:=FKnuckles[Index];
//    else Raise Exception.Create('List index out of bounds in '+ClassName+'.FGetKnuckle. ('+IntToStr(Index)+').');
end;

procedure TFreeSpline.FSetKnuckle(Index:integer;Value:Boolean);
begin
   if (Index>=0) and (Index<FNoPoints) then begin
      FKnuckles[Index]:=Value;
      Build:=false;
   end; // else Raise Exception.Create('List index out of bounds in '+ClassName+'.FSetKnuckle. ('+IntToStr(Index)+').');
end;

procedure TFreeSpline.FSetPoint(Index:Integer;P:T3DVector);
begin
   if (Index>=0) and (Index<NumberOfPoints)
       then FPoints[index]:=P;
//     else Raise exception.Create('Point index out of bounds!');
end;

function TFreeSpline.FGetParameter(Index:integer):TFloatType;
begin
   if (Index>=0) and (Index<FNoPoints) then begin
      if not build then rebuild;
      Result:=FParameters[Index];
   end; // else Raise Exception.Create('List index out of bounds in '+ClassName+'.FGetParameter. ('+IntToStr(Index)+').');
end;

function TFreeSpline.FGetPoint(Index:Integer):T3DVector;
begin
   if (Index>=0) and (Index<NumberOfPoints) then Result:=FPoints[index];
//                                          else Raise exception.Create('Point index out of bounds!');
end;

procedure TFreeSpline.Rebuild;
var I,K: integer;
    MaxLength,Length,Sig,P: TFloatType;
    U: array of T3DVector;
    Un,Qn: T3DVector;
begin
   Build:=False; // First attempt to eliminate double points
   I:=2;
   MaxLength:=0;
   while I<=FNoPoints do begin
      Length:=Sqrt( Abs(FPoints[I-2]-FPoints[I-1]) );
      MaxLength:=MaxLength+Length;
      Inc(I);
   end;
   if FNoPoints>1 then begin
      Setlength(FDerivatives,FNoPoints);
      Setlength(FParameters,FNoPoints);
      SetLength(U,FNoPoints);
      Length:=0;
      if abs(MaxLength)<1e-5 then begin // zero arclength, use uniform parameterisation
         for I:=1 to FNoPoints do FParameters[I-1]:=(I-1)/(FNoPoints-1);
      end else begin
         FParameters[0]:=0.0;
         for I:=2 to FNoPoints-1 do begin
            Length:=Length+Sqrt( Abs(FPoints[I-2]-FPoints[I-1]));
            FParameters[I-1]:=Length/MaxLength;
         end;
         FParameters[FNoPoints-1]:=1.0;
      end;
      FDerivatives[0]:=ZERO;
      U[0]:=FDerivatives[0];
      for I:=2 to FNoPoints-1 do begin
         if Knuckle[I-1] then begin
            U[I-1]:=ZERO;
            FDerivatives[I-1]:=ZERO;
         end else begin
            if (abs(FParameters[I]-FParameters[I-2])<1e-5)
            or (abs(FParameters[I-1]-FParameters[I-2])<1e-5)
            or (abs(FParameters[I]-FParameters[I-1])<1e-5) then begin
               FDerivatives[I-1]:=ZERO;
            end else begin
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
      Qn:=ZERO;
      Un:=Qn;
      FDerivatives[FNoPoints-1].X:=(Un.X-Qn.X*U[FNoPoints-2].X)/(Qn.X*FDerivatives[FNoPoints-2].X+1.0);
      FDerivatives[FNoPoints-1].Y:=(Un.Y-Qn.Y*U[FNoPoints-2].Y)/(Qn.Y*FDerivatives[FNoPoints-2].Y+1.0);
      FDerivatives[FNoPoints-1].Z:=(Un.Z-Qn.Z*U[FNoPoints-2].Z)/(Qn.Z*FDerivatives[FNoPoints-2].Z+1.0);
      // Back substitution
      for K:=FNoPoints-1 downto 1 do begin
         FDerivatives[K-1].X:=FDerivatives[K-1].X*FDerivatives[K].X+U[K-1].X;
         FDerivatives[K-1].Y:=FDerivatives[K-1].Y*FDerivatives[K].Y+U[K-1].Y;
         FDerivatives[K-1].Z:=FDerivatives[K-1].Z*FDerivatives[K].Z+U[K-1].Z;
      end;
   end;
   FBuild:=true;
   inherited Rebuild;
end;

procedure TFreeSpline.Add(P:T3DVector);
begin
   if NumberOfPoints=Capacity then begin // Make sure that the allocated memory is sufficient
      Capacity:=capacity+IncrementSize;
   end;
   FPoints[FNoPoints]:=P;
   FKnuckles[FNoPoints]:=False;
   inc(FNoPoints);
   Build:=False;  // Curve needs to be rebuild
end;

constructor TFreeSpline.Create;
begin
   Setlength(FPoints,0);
   Setlength(FDerivatives,0);
   Setlength(FParameters,0);
   Setlength(FKnuckles,0);
   FCapacity:=0;
   FNoPoints:=0;
   inherited Create;
end;

procedure TFreeSpline.DeletePoint(Index:Integer);
var I : integer;
begin
   if NumberOfPoints>0 then begin
      dec(FNoPoints);
      for I:=Index to NumberOfPoints-1 do begin
         FPoints[I]:=FPoints[I+1];
         FKnuckles[I]:=FKnuckles[I+1];
      end;
      Build:=false;
   end;
   if NumberOfPoints=0 then begin
      if FParameters<>nil then FreeMem(FParameters);
      FParameters:=nil;
   end;
end;

procedure TFreeSpline.Draw(Viewport:TFreeViewport;Mode:TPenmode);
var I: Integer;
    P1: T3DVector;
    PArray: array of TPoint;
begin
   if not Build then Rebuild;
   Fragments:=Self.Fragments;
   SetLength(PArray,Fragments);
   for I:=1 to Fragments do
   begin
      P1:=Value((I-1)/(Fragments-1));
      PArray[I-1]:=Viewport.Project(P1);
   end;
   Viewport.SetPenWidth(1);
   Viewport.PenColor:=Color;
   Viewport.Canvas.Pen.Style:=FPenstyle;
   Viewport.Canvas.Polyline(PArray);
end;

procedure TFreeSpline.InsertSpline(Index:Integer;Invert:Boolean;Source:TFreeSpline);
var I:Integer;
begin
   if NumberOfPoints=0 then begin
      Capacity:=Source.NumberOfPoints;
      if Invert then begin
         for I:=0 to Source.NumberOfPoints-1 do begin
            FPoints[Source.NumberOfPoints-1-I]:=Source.FPoints[I];
            FKnuckles[Source.NumberOfPoints-1-I]:=Source.FKnuckles[I];
         end;
      end else begin
         for I:=0 to Source.NumberOfPoints-1 do begin
            FPoints[I]:=Source.FPoints[I];
            FKnuckles[I]:=Source.FKnuckles[I];
         end;
      end;
      FNoPoints:=Source.NumberOfpoints;
   end else begin
      Capacity:=NumberOfPoints+Source.NumberOfPoints-1;
      Build:=False;
      if Index<NumberOfPoints then begin         // insert space for new points
         Move(FPoints[Index],FPoints[Index+Source.NumberOfPoints-1],(NumberOfPoints-Index)*SizeOf(T3DVector));
         Move(FKnuckles[Index],FKnuckles[Index+Source.NumberOfPoints-1],(NumberOfPoints-Index));
         // Insert the new data
         if Invert then  begin
            Knuckle[index]:=Knuckle[Index] or Source.Knuckle[Source.NumberOfPoints-1];
            for I:=1 to Source.NumberOfPoints-1 do begin
               FPoints[Index+I-1]:=Source.FPoints[Source.FNoPoints-I];
               FKnuckles[Index+I-1]:=Source.FKnuckles[Source.FNoPoints-I];
            end;
         end else begin
            Knuckle[index]:=Knuckle[Index] or Source.Knuckle[0];
            Move(Source.FPoints[0],FPoints[Index],(Source.NumberOfPoints-1)*SizeOf(T3DVector));
            Move(Source.FKnuckles[0],FKnuckles[Index],Source.NumberOfPoints-1);
         end;
      end else begin
         if Invert then begin
            Knuckle[NumberOfPoints-1]:=Knuckle[NumberOfPoints-1] or Source.Knuckle[Source.NumberOfPoints-1];
            for I:=1 to Source.NumberOfPoints-1 do begin
               FPoints[FNoPoints-1+I]:=Source.FPoints[Source.FNoPoints-I-1];
               FKnuckles[FNoPoints-1+I]:=Source.FKnuckles[Source.FNoPoints-I-1];
            end;
         end else begin
            Knuckle[NumberOfPoints-1]:=Knuckle[NumberOfPoints-1] or Source.Knuckle[0]; // Add controlpoints
            Move(Source.FPoints[Index-Index+1],FPoints[NumberOfPoints],(Source.NumberOfPoints-1)*SizeOf(T3DVector)); // Add knuckles
            Move(Source.FKnuckles[Index-Index+1],FKnuckles[NumberOfPoints],Source.NumberOfPoints-1);
         end;
      end;
      inc(FNoPoints,Source.NumberOfpoints-1);
   end;
end;

procedure TFreeSpline.Clear;
begin
   Setlength(FDerivatives,0);
   Setlength(FParameters,0);
   FNoPoints:=0;
   inherited Clear;
   Build:=False;
   Setlength(FPoints,0);
   FCapacity:=0;
   FNoPoints:=0;
   FFragments:=100;
end;

function TFreeSpline.Value(Parameter:extended):T3DVector;
var Lo,Hi,K: Integer;
    H,a,b : TFloatType;
begin
   Result:=ZERO;
   if FNoPoints<2 then exit;
   if not FBuild then Rebuild;
   if FNoPoints<2 then exit;
   if FNoPoints=2 then begin Lo:=0; Hi:=1; end else begin
      Lo:=0;
      Hi:=FNoPoints-1;
      repeat
         K:=(Lo+Hi) div 2;
      // try
            if FParameters[K]<Parameter then Lo:=K
                                        else Hi:=K;
      // except
      //    FParameters[K]:=FParameters[K]-1+1;
      // end;
      until Hi-Lo<=1;
   end;
   H:=FParameters[Hi]-FParameters[Lo];
   if abs(H)<1e-6 then begin //Raise exception.Create('Invalid cspline');
      Result:=FPoints[Hi];
   end else begin
      A:=(FParameters[Hi]-Parameter)/H;
      B:=(Parameter-FParameters[Lo])/H;
      Result:=A*FPoints[Lo] + B*FPoints[Hi] + (H*H)*( (A*A*A-A)*FDerivatives[Lo]+(B*B*B-B)*(Fderivatives[Hi]) )/6.0;
   end;
end;

{--------------------------------------------}
{ TFreeSubdivisionBase is the base class for }
{ all subdivision points, edges and faces    }
{--------------------------------------------}
constructor TFreeSubdivisionBase.Create(Owner:TFreeSubdivisionSurface);
      begin Inherited Create; FOwner:=Owner; end;

{-----------------------------------------------------------------------------------}
{ TFreeSubdivisionLayer is a leyrtype class                                         }
{ All individual controlfaces can be assigned to a leyer. Properties such as color, }
{ visibility etc. are common for all controlfaces belonging the the same layer      }
{-----------------------------------------------------------------------------------}
function TFreeSubdivisionLayer.FGetColor:TColor;
   begin Result:=FColor; end;
function TFreeSubdivisionLayer.FGetCount:Integer;
   begin Result:=FPatches.Count; end;
function TFreeSubdivisionLayer.FGetName:string;
begin
   if FDescription='' then Result:='Layer '+IntToStr(LayerId)
                      else Result:=FDescription;
end;
function TFreeSubdivisionLayer.FGetItems(Index:Integer):TFreeSubdivisionControlFace;
   begin Result:=FPatches[Index]; end;
function TFreeSubdivisionLayer.FGetLayerIndex:Integer;
   begin Result:=Owner.FLayers.IndexOf(self); end;

procedure TFreeSubdivisionLayer.FSetName(Val:String);
begin
   if Uppercase(Val)<>Uppercase(FDescription) then begin
      FDescription:=Val;
      if assigned(Owner.FOnChangeLayerData) then Owner.FOnChangeLayerData(self);
      if (self=Owner.ActiveLayer) and (assigned(Owner.FOnChangeActiveLayer)) then owner.FOnChangeActiveLayer(Owner,Owner.ActiveLayer);
   end;
end;

procedure TFreeSubdivisionLayer.FSetSymmetric(Val:Boolean);
begin
   if Val<>FSymmetric then begin
      FSymmetric:=Val;
      if assigned(Owner.FOnChangeLayerData) then Owner.FOnChangeLayerData(self);
   end;
end;

procedure TFreeSubdivisionLayer.FSetColor(Val:TColor);
begin
   if Val<>FColor then begin
      FColor:=Val;
      if assigned(Owner.FOnChangeLayerData) then Owner.FOnChangeLayerData(self);
      if (self=Owner.ActiveLayer) and (assigned(Owner.FOnChangeActiveLayer)) then owner.FOnChangeActiveLayer(Owner,Owner.ActiveLayer);
   end;
end;

procedure TFreeSubdivisionLayer.FSetVisible(Val:Boolean);
begin
   if Val<>FVisible then begin
      FVisible:=Val;
      if assigned(Owner.FOnChangeLayerData) then Owner.FOnChangeLayerData(self);
   end;
end;

procedure TFreeSubdivisionLayer.AddControlFace(ControlFace:TFreeSubdivisionControlFace);
begin // disconnect from current layer
   if ControlFace.Layer<>nil then ControlFace.Layer.DeleteControlFace(ControlFace);
   if FPatches.Indexof(ControlFace)=-1 then FPatches.Add(ControlFace);
   ControlFace.FLayer:=self;
end;

constructor TFreeSubdivisionLayer.Create(Owner:TFreeSubdivisionSurface);
begin
   inherited Create;
   FOwner:=Owner;
   FPatches:=TFasterList.Create;
   Clear;
end;

procedure TFreeSubdivisionLayer.Clear;
begin
   FLayerID:=-1;
   FPatches.Clear;
   FColor:=DefaultLayerColor;
   FVisible:=True;
   FDescription:='';
   FSymmetric:=True;
end;

function TFreeSubdivisionLayer.Delete:Boolean;
var I     : Integer;
    Index : Integer;
begin
   Result:=True;
   for I:=Count downto 1 do Items[I-1].Delete;
   if Owner.FActiveLayer=self then Owner.FActiveLayer:=nil;
   Index:=LayerIndex;
   if Index<>-1 then Owner.FLayers.Delete(Index);
   Clear;
   if assigned(Owner.FOnChangeLayerData) then Owner.FOnChangeLayerData(self);
   Destroy;
end;

procedure TFreeSubdivisionLayer.DeleteControlFace(ControlFace:TFreeSubdivisionControlFace);
var Index : Integer;
begin
   Index:=FPatches.IndexOf(ControlFace);
   if index<>-1 then FPatches.Delete(Index);
end;

destructor TFreeSubdivisionLayer.Destroy;
begin
   FPatches.Destroy;
   FPatches:=nil;
   Inherited Destroy;
end;

procedure TFreeSubdivisionLayer.Draw(Viewport:TFreeViewport;Mode:TPenMode);
var I,J  : Integer;
    Face : TFreeSubdivisionControlface;
    Edge : TFreeSubdivisionEdge;
begin
   if (Visible) and (Count>0) then begin
      if Viewport.Shade then begin
         for I:=1 to count do Items[I-1].Draw(Viewport,pmCOPY);
      end else begin
         if Owner.ShowInteriorEdges then begin
            Viewport.SetPenWidth(1);
            Viewport.PenColor:=Color;
            For I:=1 to Count do Items[I-1].Draw(Viewport,pmCOPY);
         end;
         // Draw all interior crease-edges
         Viewport.SetPenWidth(1);
         Viewport.PenStyle:=psSolid;
         Viewport.PenColor:=clBlack;
         For I:=1 to Count do begin
            Face:=Items[I-1];
            for J:=1 to Face.FControlEdges.Count do begin
               Edge:=Face.FControlEdges[J-1];
               if Edge.Crease then begin
                  Edge.Draw(Owner.DrawMirror and Symmetric,Viewport);
               end;
            end;
         end;
      end;
   end;
end;

procedure TFreeSubdivisionLayer.Extents(var Min,Max:T3DVector);
var I    : Integer;
    Face : TFreeSubdivisionControlface;
    P    : T3DVector;
begin
   if Visible then for I:=1 to Count do begin
      Face:=Items[I-1];
      MinMax(Face.FMin,Min,Max);
      MinMax(Face.FMax,Min,Max);
      if (Symmetric) and (Owner.DrawMirror) then begin
         P:=Face.FMin;
         P.Y:=-P.Y;
         MinMax(P,Min,Max);
         P:=Face.FMax;
         P.Y:=-P.Y;
         MinMax(P,Min,Max);
      end;
   end;
end;
{-----------------------}
{ TFreeSubdivisionPoint }
{-----------------------}
function TFreeSubdivisionPoint.FGetEdge(Index:Integer):TFreeSubdivisionEdge;
   begin Result:=FEdges[Index]; end;
function TFreeSubdivisionPoint.FGetFace(Index:Integer):TFreeSubdivisionFace;
   begin Result:=FFaces[Index]; end;
function TFreeSubdivisionPoint.FGetIndex:Integer;
   begin Result:=Owner.FPoints.IndexOf(Self); end;
function TFreeSubdivisionPoint.FGetNumberOfEdges:integer;
   begin Result:=FEdges.Count; end;
function TFreeSubdivisionPoint.FGetNumberOfFaces:integer;
   begin Result:=FFaces.Count; end;
procedure TFreeSubdivisionPoint.FSetCoordinate(Val:T3DVector);
    begin FCoordinate:=Val; end;
procedure TFreeSubdivisionPoint.AddEdge(Edge:TFreeSubdivisionEdge);
    begin if FEdges.IndexOf(Edge)=-1 then begin FEdges.Add(Edge); end; end;
procedure TFreeSubdivisionPoint.AddFace(Face:TFreeSubdivisionFace);
    begin if FFaces.IndexOf(Face)=-1 then begin FFaces.Add(Face); end; end;

function TFreeSubdivisionPoint.Averaging:T3DVector;
var I,J,Nt,Nq: Integer;
    A,Weight,TotalWeight:TFloatType;
    Center: T3DVector;
    Face: TFreeSubdivisionFace;
    Edge: TFreeSubdivisionEdge;
    P: TFreeSubdivisionPoint;
begin
   if (NumberOfedges=0) or (FVertexType=svCorner) then Result:=FCoordinate
   else begin
      if FVertexType=svCrease then begin
         Result:=0.5*FCoordinate;
         for I:=1 to FEdges.Count do begin
            Edge:=FEdges[I-1];
            if (Edge.FFaces.Count=1) or (Edge.FCrease) then begin
               if Edge.FStartpoint=self then P:=Edge.FEndpoint
                                        else P:=Edge.FStartpoint;
               Result:=Result + 0.25*P.FCoordinate;
            end;
         end;
      end else begin
         TotalWeight:=0.0;
         Result:=ZERO;
         Nt:=0;
         for I:=1 to FFaces.Count do begin
            Face:=FFaces[I-1];
            Center:=ZERO;
            if Face.NumberOfpoints=3 then begin
               inc(Nt);                                // Calculate centerpoint
               for j:=1 to Face.NumberOfpoints do begin
                  P:=Face.FPoints[J-1];
                  if P=self then Weight:=1/4
                            else Weight:=3/8;
                  Center:=Center + Weight*P.FCoordinate;
               end;
               Weight:=Pi/3;
            end else
            if Face.NumberOfpoints=4 then begin        // Calculate centerpoint
               for j:=1 to Face.NumberOfpoints do begin
                  P:=Face.FPoints[J-1];
                  Weight:=1/4;
                  Center:=Center + Weight*P.FCoordinate;
               end;
               Weight:=Pi/2;
            end; // else Raise exception.Create('Invalid number of points in TFreeSubdivisionPoint.Averaging');
            Result:=Result + Weight*Center;
            TotalWeight:=TotalWeight+Weight;
         end;
         if TotalWeight<>0 then begin
            Result:=Result/TotalWeight;
         end;
         Nq:=FFaces.Count-Nt;
         if Nt=FFaces.Count then begin // apply averaging in case of vertex surrounded by triangles
            a:=5/3-8/3*sqr(3/8+1/4*cos(2*Pi/FFaces.Count));
         end else
         if Nq=FFaces.Count then begin // apply averaging in case of vertex surrounded by quads
            a:=4/FFaces.Count;
         end else begin // apply averaging in case of vertex on boundary of quads and triangles
            if (Nq=0) and (Nt=3) then a:=1.5
                                 else a:=12/(3*Nq+2*Nt);
         end;
         if A<>1.0 then begin
            Result:=FCoordinate + A*(Result-FCoordinate);
         end;
      end;
   end;
end;

function TFreeSubdivisionPoint.CalculateVertexPoint:TFreeSubdivisionPoint;
var Point   : T3DVector;
begin
   Point:=FCoordinate;
   Result:=TFreeSubdivisionPoint.Create(Owner);
   Result.FVertexType:=FVertexType;
   Result.FCoordinate:=Point;
end;

procedure TFreeSubdivisionPoint.Clear;
begin
   Fillchar(FCoordinate,SizeOf(T3DVector),0);
   FFaces.Clear;
   FEdges.Clear;
   FVertexType:=svRegular;
end;

constructor TFreeSubdivisionPoint.Create(Owner:TFreeSubdivisionSurface);
begin
   inherited Create(Owner);
   FFaces:=TFasterList.Create;
   FEdges:=TFasterList.Create;
   Clear;
end;

procedure TFreeSubdivisionPoint.DeleteEdge(Edge:TFreeSubdivisionEdge);
var Index:Integer;
begin
   index:=FEdges.IndexOf(Edge);
   if Index<>-1 then FEdges.Delete(Index);
end;

procedure TFreeSubdivisionPoint.DeleteFace(Face:TFreeSubdivisionFace);
var Index:Integer;
begin
   index:=FFaces.IndexOf(Face);
   if Index<>-1 then FFaces.Delete(Index);
end;

destructor TFreeSubdivisionPoint.Destroy;
begin
   Clear;
   FFaces.Destroy;
   FFaces:=nil;
   FEdges.Destroy;
   Fedges:=nil;
   inherited Destroy;
end;
function TFreeSubdivisionPoint.IndexOfFace(Face:TFreeSubdivisionFace):Integer;
   begin Result:=FFaces.IndexOf(Face); end;

{------------------------------}
{ TFreeSubdivisionControlPoint }
{------------------------------}
function TFreeSubdivisionControlPoint.FGetColor:TColor;
begin
   if Selected then Result:=DefaultSelectedColor else
   Case FVertexType of
      svRegular : Result:=$00E1E1E1;
      svCorner  : Result:=$00B95C00;
      svDart    : result:=clFuchsia;
      svCrease  : result:=$00004080;
      else Result:=clRed;
   end;
end;
function TFreeSubdivisionControlPoint.FGetIndex:Integer;
   begin Result:=Owner.FControlPoints.IndexOf(Self); end;
function TFreeSubdivisionControlPoint.FGetSelected:Boolean;
   begin Result:=Owner.FSelectedControlPoints.IndexOf(self)<>-1; end;

function TFreeSubdivisionControlPoint.FGetVisible:Boolean;
var I: Integer;
    CFace: TFreeSubdivisionControlFace;
begin
   // meant for controlpoints only.
   // a controlpoint is visible if at least one of it's
   // neighbouring controlfaces belongs to a visible layer
   Result:=False;
   if Owner.ShowControlNet then begin
      for i:=1 to FFaces.Count do
      if Face[I-1] is TFreeSubdivisionControlFace then begin
         CFace:=FFaces[I-1];
         if CFace.Layer<>nil then
         if CFace.Layer.Visible then begin Result:=True; exit; end;
      end;
   end;            // Finally check if the point is selected.
                   // Selected points must be visible at all times
                   // Points with no faces connected also!
   if not Result then Result:=(Selected) or (NumberOfFaces=0);
end;

procedure TFreeSubdivisionControlPoint.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedControlPoints.IndexOf(self);
   if Val then begin               // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedControlPoints.Add(self);
   end else begin
      if Index<>-1 then Owner.FSelectedControlPoints.Delete(index);
   end;
   if Assigned(Owner.FOnSelectItem) then Owner.FOnSelectItem(self);
end;

procedure TFreeSubdivisionControlPoint.FSetCoordinate(Val:T3DVector);
    begin Inherited FsetCoordinate(Val); Owner.Build:=False; end;

procedure TFreeSubdivisionControlPoint.Collapse;
var I,J: Integer;
    P1,P2: TFreeSubdivisionControlPoint;
    Face : TFreeSubdivisionControlFace;
    Edge1,Edge2: TFreesubdivisionControlEdge;
    Edges,Points,Sorted,Checklist:TFasterList;
    Crease,EdgeCollapse:Boolean;
begin
   if NumberOfFaces<=2 then begin
      Selected:=False;
      P1:=nil;
      P2:=nil; // This is possibly a point on a boundary edge, check for this special case
      Edge1:=nil;
      Edge2:=nil;
      for i:=1 to NumberOfEdges do if Edge[I-1].NumberOfFaces=1 then begin
         if Edge1=nil then Edge1:=Edge[I-1] as TFreesubdivisionControlEdge else
                           Edge2:=Edge[I-1] as TFreesubdivisionControlEdge;
      end;
      if (Edge1<>nil) and (Edge2<>nil) then begin
         for I:=NumberOfEdges downto 1 do if Edge[I-1].NumberOfFaces>1 then begin
            Edge1:=Edge[I-1] as TFreesubdivisionControlEdge;
            Edge1.Collapse;
         end;
      end;
      if NumberOfEdges=2 then begin
         EdgeCollapse:=True;
         Edge1:=FEdges[0];
         if Edge1.FStartpoint=self then P1:=Edge1.FEndpoint as TFreeSubdivisionControlPoint
                                   else P1:=Edge1.FStartpoint as TFreeSubdivisionControlPoint;
         Edge2:=FEdges[1];
         if Edge2.FStartpoint=self then P2:=Edge2.FEndpoint as TFreeSubdivisionControlPoint
                                   else P2:=Edge2.FStartpoint as TFreeSubdivisionControlPoint;
         Crease:=Edge1.Crease or Edge2.Crease;
      end else begin
         Crease:=False;
         EdgeCollapse:=False;
      end;
      for I:=NumberOfFaces downto 1 do begin
         Face:=FFaces[I-1];
         Points:=TFasterList.Create;
         for J:=1 to Face.FPoints.Count do if Face.FPoints[J-1]<>self then Points.Add(Face.FPoints[J-1]);
         FOwner.AddControlFace(Points,Face.Layer);
         Points.Destroy;
         Face.Delete;
      end;
      if EdgeCollapse then begin
         Edge1:=FOwner.EdgeExists(P1,P2) as TFreesubdivisionControlEdge;
         if Edge1<>nil then begin
            Edge1.Crease:=Crease;// or (Edge1.NumberOfFaces=1);
         end;
      end;
   end else begin
      Checklist:=TFasterList.Create;
      Edges:=TFasterList.Create;
      for i:=1 to NumberOfEdges do if Edge[I-1].StartPoint=self then CheckList.Add(Edge[I-1].EndPoint)
                                                                else CheckList.Add(Edge[I-1].StartPoint);
      for I:=1 to NumberOfFaces do begin
         Face:=Ffaces[I-1];
         P1:=Face.FPoints[Face.NumberOfPoints-1];
         for J:=1 to Face.FPoints.Count do begin
            P2:=face.FPoints[J-1];
            if (P1<>self) and (P2<>self) then begin
               Edge1:=FOwner.EdgeExists(P1,P2) as TFreesubdivisionControlEdge;
               if Edge1<>nil then if Edges.IndexOf(Edge1)=-1 then Edges.Add(Edge1);
            end;
            P1:=P2;
         end;
      end;                      // sort edges in correct order and add new face
      if Edges.Count>2 then begin
         Sorted:=TFasterList.Create;
         Fowner.IsolateEdges(Edges,Sorted);
         Edges.Destroy;
         for I:=1 to Sorted.Count do begin Points:=Sorted[I-1];
            if Points.Count>2 then begin Face:=FOwner.AddControlFace(Points);
               if Face<>nil then begin P1:=Face.FPoints[Face.FPoints.Count-1];
                  for J:=1 to Face.FPoints.Count do begin P2:=face.FPoints[J-1];
                     Edge1:=fowner.EdgeExists(p1,p2) as TFreesubdivisionControlEdge;
                     if edge1<>nil then begin
                     {  Cur:=Edge.FFaces.IndexOf(self);
                        if Cur=-1 then Edge.Crease:=Edge.NumberOfFaces<2
                                  else Edge.Crease:=Edge.NumberOfFaces<3;
                     }
                     end; P1:=P2;
                  end;
               end;
            end; Points.Destroy;
         end; Sorted.Destroy;
      end else Edges.Destroy;
      delete;
      for i:=Checklist.Count downto 1 do begin
         P1:=Checklist[I-1];
         if (P1.NumberOfFaces>1) and (P1.NumberOfEdges=2) then begin
            P1.Collapse;
         end;
      end;
      checklist.Destroy;
   end;
end;

constructor TFreeSubdivisionControlPoint.Create(Owner:TFreeSubdivisionSurface);
      begin inherited Create(Owner); end;

procedure TFreeSubdivisionControlPoint.Delete;
var Index:Integer;
    Edge :TFreesubdivisionControlEdge;
begin                                                 // delete from selection;
   Selected:=False;
   if FEdges.Count>0 then begin
      Index:=Owner.FControlPoints.IndexOf(Self);
      if Index<>-1 then Owner.FControlPoints.Delete(index);
      while FEdges<>nil do begin //.Count>0 do
         Edge:=self.Edge[NumberOfEdges-1] as TFreesubdivisionControlEdge;
         Edge.Delete;
      end;
   end else begin
      Index:=Owner.FControlPoints.IndexOf(Self);
      if Index<>-1 then Owner.FControlPoints.Delete(index);
      Destroy;
   end;
end;

procedure TFreeSubdivisionControlPoint.Draw(Viewport:TFreeViewport);
var P : TPoint;
    Pz: TShadePoint;
    I : Integer;
begin
   if Viewport.Shade then begin
      Pz:=Viewport.ProjectToZBuffer(1.002*ZBufferScaleFactor,FCoordinate);
      // Check if the point lies within the viewport's drawingcanvas boundaries
      if (Pz.X>=0) and (Pz.Y>=0)
      and (Pz.X<Viewport.ClientWidth)
      and (Pz.Y<Viewport.ClientHeight) then  begin                 // Compare to Z buffer to check visibility;
         if Pz.Z>=Viewport.FZBuffer.FBuffer[Pz.Y][Pz.X] then begin // yes, the point is visible
            Viewport.FZBuffer.FBuffer[Pz.Y][Pz.X]:=Pz.Z;
            if Viewport.Canvas.Pen.Width<>1 then Viewport.Canvas.Pen.Width:=1;
            Viewport.PenColor:=Color;
            if Viewport.Canvas.Brush.Style<>bsClear then Viewport.Canvas.Brush.Style:=bsClear;
            for I:=1 to ControlPointSize do Viewport.Canvas.Rectangle(Pz.X-I,Pz.Y-I,Pz.X+I,Pz.Y+I);
         end;
      end;
   end else begin
      with Viewport.Canvas do begin
         P:=Viewport.Project(FCoordinate);
         if Pen.Width<>1 then Pen.Width:=1;
         Viewport.PenColor:=Color;
         if Brush.Style<>bsClear then Brush.Style:=bsClear;
         if Selected then begin                                      //FInitializeCanvas(Viewport,1,Color,Mode);
            for I:=1 to ControlPointSize do Viewport.Canvas.Rectangle(P.X-I,P.Y-I,P.X+I,P.Y+I);
            Viewport.Canvas.Rectangle(P.X-ControlPointSize-2,P.Y-ControlPointSize-2,P.X+ControlPointSize+2,P.Y+ControlPointSize+2);
         end else begin
            for I:=1 to ControlPointSize do Viewport.Canvas.Rectangle(P.X-I,P.Y-I,P.X+I,P.Y+I);
         end;
      end;
   end;
end;

function TFreeSubdivisionControlPoint.DistanceToCursor(X,Y:Integer;Viewport:TFreeViewport):integer;
var Pt:TPoint;
begin                    // Check if cursor position lies within the boundaries
   Pt:=Viewport.Project(FCoordinate);
   Result:=Round( hypot( Pt.X-X,Pt.y-Y ) ); // (Sqrt(Sqr(Pt.X-X)+SQR(Pt.Y-Y)));
end;

{----------------------}
{ TFreeSubdivisionEdge }
{----------------------}
function TFreeSubdivisionEdge.FGetIndex:Integer;
begin
   Result:=Owner.FEdges.IndexOf(self);
   if result=-1 then begin
      Result:=Owner.FControlEdges.IndexOf(self);
      if Result=-1 then Result:=0;
   end;
end;

function TFreeSubdivisionEdge.FGetFace(Index:Integer):TFreeSubdivisionFace;
   begin Result:=FFaces[Index]; end;
function TFreeSubdivisionEdge.FGetNumberOfFaces:Integer;
   begin Result:=FFaces.Count; end;

procedure TFreeSubdivisionEdge.FSetCrease(Val:Boolean);
var I,N  : Integer;
    Edge : TFreeSubdivisionEdge;
begin
   if (Val<>FCrease) then begin
      FCrease:=Val;
      N:=0;
      for I:=1 to FStartPoint.FEdges.Count do begin
         Edge:=FStartPoint.FEdges[I-1];
         if Edge.Crease then Inc(N);
      end;
      if FStartpoint.VertexType=svCorner then begin
         if (FStartPoint.NumberOfFaces>1) and (N=2) then FStartpoint.VertexType:=svCrease;
      end else begin
         if N=0 then FStartpoint.VertexType:=svRegular else
         if N=1 then FStartpoint.VertexType:=svDart else
         if N=2 then FStartpoint.VertexType:=svCrease else
         if N>2 then FStartpoint.VertexType:=svCorner;
      end;
      N:=0;
      for I:=1 to FEndPoint.FEdges.Count do begin
            Edge:=FEndPoint.FEdges[I-1];
         if Edge.Crease then Inc(N);
      end;
      if FEndpoint.VertexType=svCorner then begin
         if (FEndPoint.NumberOfFaces>1) and (N=2) then FEndpoint.VertexType:=svCrease;
      end else begin
         if N=0 then FEndpoint.VertexType:=svRegular else
         if N=1 then FEndpoint.VertexType:=svDart else
         if N=2 then FEndpoint.VertexType:=svCrease else
         if N>2 then FEndpoint.VertexType:=svCorner;
      end;
      FStartPoint.FOwner.Build:=false;
   end;
end;

procedure TFreeSubdivisionEdge.AddFace(Face:TFreeSubdivisionFace);
    begin if FFaces.IndexOf(Face)=-1 then begin FFaces.Add(Face); end;
    end;
procedure TFreeSubdivisionEdge.Assign(Edge:TFreeSubdivisionEdge);
    begin FCrease:=Edge.FCrease; FControlEdge:=Edge.FControlEdge; end;

function TFreeSubdivisionEdge.CalculateEdgePoint:TFreeSubdivisionPoint;
var Point   : T3DVector;
begin
   Point:=0.5*(FStartpoint.FCoordinate+FEndpoint.FCoordinate);
   Result:=TFreeSubdivisionPoint.Create(FStartPoint.Owner);
   if FCrease then Result.FVertexType:=svCrease;
   Result.FCoordinate:=Point;
end;

procedure TFreeSubdivisionEdge.Clear;
begin
   FStartpoint:=nil;
   FEndpoint:=nil;
   FFaces.Clear;
   FCrease:=False;
   FControlEdge:=False;
end;

procedure TFreeSubdivisionEdge.SwapData;
var Tmp:TFreeSubdivisionPoint;
begin
   Tmp:=FStartpoint;
   FStartpoint:=FEndpoint;
   FEndpoint:=Tmp;
end;

constructor TFreeSubdivisionEdge.Create(Owner:TFreeSubdivisionSurface);
begin
   Inherited Create(Owner);
   FFaces:=TFasterList.Create;
   clear;
end;

procedure TFreeSubdivisionEdge.DeleteFace(Face:TFreeSubdivisionFace);
var Index:Integer;
begin
   Index:=FFaces.IndexOf(Face);
   if Index<>-1 then begin
      FFaces.Delete(Index);
      if FFaces.Count=1 then Crease:=true else
         if FFaces.Count=0 then Crease:=False;
   end;
end;

destructor TFreeSubdivisionEdge.Destroy;
begin
   if self=nil then exit;
   Clear;
   FFaces.Destroy;
   Inherited Destroy;
end;

function TFreeSubdivisionEdge.DistanceToCursor(X,Y:Integer;var P:T3DVector;Viewport:TFreeViewport):integer;
var Pt,P1,P2 : TPoint;
    Param    : TFloatType;
begin                    // Check if cursor position lies within the boundaries
   Pt.X:=X;
   Pt.Y:=Y;
   P1:=Viewport.Project(FStartPoint.FCoordinate);
   P2:=Viewport.Project(FEndPoint.FCoordinate);
   Result:=Round(DistanceToLine(P1,P2,X,Y,Param));
   P:=Interpolate(FStartPoint.FCoordinate,FEndPoint.FCoordinate,Param);
end;

procedure TFreeSubdivisionEdge.Draw(DrawMirror:Boolean;Viewport:TFreeViewport);
var P1,P2   : T3DVector;
    Pt1,Pt2 : TPoint;
begin
   P1:=FStartPoint.FCoordinate;
   P2:=FEndPoint.FCoordinate;
   Pt1:=Viewport.Project(P1);
   Pt2:=Viewport.Project(P2);
   Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
   Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
   if DrawMirror then begin
      P1.Y:=-P1.Y;
      P2.Y:=-P2.Y;
      Pt1:=Viewport.Project(P1);
      Pt2:=Viewport.Project(P2);
      Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
      Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
   end;
end;

{-----------------------------}
{ TFreesubdivisionControlEdge }
{-----------------------------}
function TFreesubdivisionControlEdge.FGetColor:TColor;
begin
   if Selected then Result:=DefaultSelectedColor else
      if Crease then Result:=clred else
         Result:=$006F6F6F//clAqua;
end;

function TFreesubdivisionControlEdge.FGetIndex:Integer;
begin
   Result:=Owner.FControlEdges.IndexOf(self);
end;

procedure TFreesubdivisionControlEdge.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedControlEdges.IndexOf(self);
   if Val then begin               // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedControlEdges.Add(self);
   end else begin
      if Index<>-1 then Owner.FSelectedControlEdges.Delete(index);
   end;
   if Assigned(Owner.FOnSelectItem) then Owner.FOnSelectItem(self);
end;

function TFreesubdivisionControlEdge.FGetSelected:Boolean;
begin
   Result:=Owner.FSelectedControlEdges.IndexOf(self)<>-1;
end;

function TFreesubdivisionControlEdge.FGetVisible:Boolean;
var I       : Integer;
    CFace   : TFreeSubdivisionControlFace;
begin
   // meant for controledges only.
   // a controledge is visible if at least one of it's
   // neighbouring controlfaces belongs to a visible layer
   Result:=False;
   if Owner.ShowControlNet then begin
      for I:=1 to FFaces.Count do
      if Face[I-1] is TFreeSubdivisionControlFace then begin
         CFace:=FFaces[I-1];
         if CFace.Layer<>nil then begin
            if CFace.Layer.Visible then begin
               Result:=True;
               exit;
            end;
         end;
      end;
   end;
   // Finally check if the edge is selected.
   // Selected edges must be visible at all times
   if not Result then Result:=Selected;
end;

procedure TFreesubdivisionControlEdge.Collapse;
var Face1,Face2   : TFreeSubdivisionControlFace;
    NewFace       : TFreeSubdivisionControlFace;
    Edge          : TFreeSubdivisionEdge;
    I,Ind1,Ind2,Ind3,Ind4: Integer;
    P1,P2         : TFreeSubdivisionPoint;
    S,E           : TFreeSubdivisionControlPoint;
    Layer         : TFreeSubdivisionLayer;
    procedure Swap(var Ind1,Ind2:Integer);
    var Tmp:Integer;
    begin
       Tmp:=Ind1;
       Ind1:=Ind2;
       Ind2:=Tmp;
    end;
begin
   if NumberOfFaces=2 then if (Face[0] is TFreeSubdivisionControlFace)
   and (Face[1] is TFreeSubdivisionControlFace) then begin
      if (StartPoint.NumberOfEdges>2) and (EndPoint.NumberOfEdges>2) then begin
         if selected then Selected:=False;
         S:=Startpoint as TFreeSubdivisionControlPoint;
         E:=Endpoint as TFreeSubdivisionControlPoint;
         Owner.Build:=False;
         Face1:=Face[0] as TFreeSubdivisionControlFace;
         Face2:=Face[1] as TFreeSubdivisionControlFace;
         Layer:=Face1.Layer; // Remove the controlfaces from the layers which they belong to
         Face1.Layer.DeleteControlFace(Face1);
         Face2.Layer.DeleteControlFace(Face2);
         Ind1:=Face1.FPoints.IndexOf(FStartPoint);
         Ind2:=Face1.FPoints.IndexOf(FEndPoint);
         if (Ind2<Ind1) and (abs(Ind2-Ind1)=1) then Swap(Ind1,Ind2);
         Ind3:=Face2.FPoints.IndexOf(FStartPoint);
         Ind4:=Face2.FPoints.IndexOf(FEndPoint);
         if (Ind4<Ind3) and (abs(Ind4-Ind3)=1) then Swap(Ind3,Ind4);

         if (Ind1=0) and (Ind2=Face1.NumberOfpoints-1) and
            (Ind3=0) and (Ind4=Face2.NumberOfpoints-1) then begin
            Swap(Ind1,Ind2);
            Swap(Ind3,Ind4);
         end;
         if (Ind1=0) and (Ind2=Face1.NumberOfpoints-1) then begin
            Swap(Ind1,Ind2);
         end;
         if (Ind3=0) and (Ind4=Face2.NumberOfpoints-1) then begin
            Swap(Ind3,Ind4);
         end;
         // Remove all references to Face1
         for I:=1 to Face1.NumberOfpoints do Face1.Point[I-1].DeleteFace(Face1);
         // Remove all references to Face2
         for I:=1 to Face2.NumberOfpoints do Face2.Point[I-1].DeleteFace(Face2);
         // Add the new face
         NewFace:=TFreeSubdivisionControlFace.Create(Owner);
         NewFace.FLayer:=layer;
         Owner.FControlFaces.Add(NewFace);
         for I:=0 to Ind1 do begin
            if NewFace.FPoints.IndexOf(Face1.Point[I])=-1 then begin
               NewFace.AddPoint(Face1.Point[I]);
            end;
         end;
         begin
            //Swap(Ind3,Ind4);
            for I:=Ind4 to Face2.NumberOfpoints-1 do begin
               if NewFace.FPoints.IndexOf(Face2.Point[I])=-1 then begin
                  NewFace.AddPoint(Face2.Point[I]);
               end;
            end;
            for I:=0 to Ind3 do begin
               if NewFace.FPoints.IndexOf(Face2.Point[I])=-1 then begin
                  NewFace.AddPoint(Face2.Point[I]);
               end;
            end;
         end;
         for I:=Ind2 to Face1.NumberOfpoints-1 do begin
            if NewFace.FPoints.IndexOf(Face1.Point[I])=-1 then begin
               NewFace.AddPoint(Face1.Point[I]);
            end;
         end;
         // Check if all appropriate points are added
         if Newface.NumberOfpoints<>Face1.NumberOfpoints+Face2.NumberOfpoints-2 then
         messageDlg('Not all points could be added while collapsing edge '+IntToStr(self.EdgeIndex),mtError,[mbOk],0);

         P1:=NewFace.Point[Newface.NumberOfPoints-1];
         for I:=1 to Newface.NumberOfPoints do begin
            P2:=NewFace.Point[I-1];
            Edge:=Owner.EdgeExists(P1,P2);
            if Edge<>nil then begin
               Ind1:=Edge.FFaces.IndexOf(Face1);
               if Ind1<>-1 then Edge.FFaces.Delete(Ind1);
               Ind1:=Edge.FFaces.IndexOf(Face2);
               if Ind1<>-1 then Edge.FFaces.Delete(Ind1);
               Edge.AddFace(NewFace);
               if Edge.NumberOfFaces<2 then Edge.Crease:=True;
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
         face2.Destroy;
                    // check if startpoint and endpoint can be collapsed aswell
         if (S.NumberOfFaces>1) and (S.NumberOfEdges=2) then begin S.Collapse; end;
         if (E.NumberOfFaces>1) and (E.NumberOfEdges=2) then begin E.Collapse; end;
         Owner.Build:=False;
         Destroy;
      end;
   end;
end;

constructor TFreesubdivisionControlEdge.Create(Owner:TFreeSubdivisionSurface);
      begin Inherited Create(Owner); end;

procedure TFreesubdivisionControlEdge.Delete;
var I,Index: Integer;
    Face   : TFreeSubdivisionControlFace;
    Point  : TFreeSubdivisionControlPoint;
begin                                                 // delete from selection;
   Selected:=False;
   Index:=Owner.FControlEdges.IndexOf(self);
   if Index<>-1 then begin
      Owner.FControlEdges.Delete(index);
      for I:=FFaces.Count downto 1 do begin
         Face:=FFaces[I-1];
         Face.Delete;
      end;                        // Remove endpoint from startpoint neighbours
      EndPoint.DeleteEdge(self);
      if EndPoint.NumberOfEdges=0 then begin
         Point:=Endpoint as TFreeSubdivisionControlPoint;
         Point.Delete;
      end;
                                  // Remove startpoint from endpoint neighbours
      StartPoint.DeleteEdge(self);
      if StartPoint.NumberOfEdges=0 then begin
         Point:=StartPoint as TFreeSubdivisionControlPoint;
         Point.Delete;
      end;
      Destroy;
   end;
end;

procedure TFreesubdivisionControlEdge.Draw(DrawMirror:Boolean;Viewport:TFreeViewport);
begin
   if Visible then begin
      if Viewport.Shade then  begin
         Viewport.DrawLineToZBuffer(StartPoint.Coordinate,EndPoint.Coordinate,GetRValue(Color),GetGValue(Color),GetBValue(Color));
      end else begin
         Viewport.PenColor:=(Color);
         if Crease then Viewport.SetPenWidth(2)
                   else Viewport.SetPenWidth(1);
         inherited Draw(DrawMirror,Viewport);
      end;
   end;
end;

function TFreeSubdivisionControlEdge.InsertControlPoint(P:T3DVector):TFreeSubdivisionControlpoint;
var I,I1,I2: Integer;
    Face: TFreeSubdivisionFace;
    Edge: TFreeSubdivisionControlEdge;
begin
   Result:=TFreeSubdivisionControlpoint.Create(FOwner);
   Result.FCoordinate:=P;
   FOwner.FControlPoints.Add(Result);
   for I:=1 to NumberOfFaces do begin
      Face:=FFaces[I-1];
      I1:=Face.FPoints.IndexOf(FStartPoint);
      I2:=Face.FPoints.IndexOf(FEndPoint);
      if (I1<>-1) and (I2<>-1) then begin
         if (I2=I1+1) then Face.FPoints.Insert(I2,Result) else
            if (I1=I2+1) then Face.FPoints.Insert(I1,Result) else
               if (I1=0) and (I2=Face.FPoints.Count-1) then Face.FPoints.Insert(0,Result) else
                  if (I2=0) and (I1=Face.FPoints.Count-1) then Face.FPoints.Insert(0,Result);
         Result.AddFace(Face);
      end;
   end;
   FEndpoint.DeleteEdge(self);
   Edge:=FOwner.AddControlEdge(Result,FEndPoint);
   Edge.FCrease:=FCrease;
   if FCrease then Result.FVertexType:=svCrease;
   for I:=1 to NumberOffaces do Edge.AddFace(FFaces[I-1]);
   FEndPoint:=Result;
   Result.AddEdge(self);
   Owner.Build:=False;
end;

{----------------------}
{ TFreeSubdivisionFace }
{----------------------}
function TFreeSubdivisionFace.FGetNumberOfPoints: Integer;
   begin Result:=FPoints.Count; end;
function TFreeSubdivisionFace.FGetPoint(Index:Integer):TFreeSubdivisionPoint;
   begin Result:=FPoints[Index]; end;
procedure TFreeSubdivisionFace.AddPoint(Point:TFreeSubdivisionPoint);
    begin FPoints.Add(Point); Point.AddFace(self); end;

function TFreeSubdivisionFace.CalculateFacePoint:TFreeSubdivisionPoint;
var I: Integer;
    P,Centre:T3DVector;
begin
   Result:=nil;
   Centre:=ZERO;
   if FPoints.Count>3 then begin
      if FPoints.Count>0 then begin
         for I:=1 to FPoints.Count do begin
            P:=Point[I-1].FCoordinate;
            Centre:=Centre+P;
         end;
         Centre:=Centre/FPoints.Count;
      end;
      Result:=TFreeSubdivisionPoint.Create(Owner);
      Result.FCoordinate:=Centre;
   end; // else if FPoints.Count=3 then begin
        //      Result:=nil; end;
end;

procedure TFreeSubdivisionFace.Clear;
    begin FPoints.Clear; end;
constructor TFreeSubdivisionFace.Create(Owner:TFreeSubdivisionSurface);
    begin FPoints:=TFasterlist.Create;
          inherited Create(Owner);
          Clear;
    end;
destructor TFreeSubdivisionFace.Destroy;
    begin Clear; inherited Destroy; FPoints.Destroy;
    end;
function TFreeSubdivisionFace.IndexOfPoint(P:TFreeSubdivisionPoint):Integer;
   begin Result:=FPoints.IndexOf(P); end;

procedure TFreeSubdivisionFace.Subdivide(Owner:TFreeSubdivisionSurface;ControlFace:Boolean;VertexPoints,EdgePoints,FacePoints,InteriorEdges,ControlEdges,Dest:TFasterList);
var P2: TFreeSubdivisionPoint;
    I,TmpIndex,Index,J : Integer;
    NewFace: TFreeSubdivisionFace;
    Pts: array[0..3] of TFreeSubdivisionPoint;
    PrevEdge,CurrEdge: TFreeSubdivisionEdge;

    PrevEdgePoint,
    CurrEdgePoint,
    P2Point,
    NewLocation:TFreeSubdivisionPoint;

    procedure EdgeCheck(P1,P2:TFreeSubdivisionPoint;Crease,Controledge:Boolean);
    var NewEdge:TFreeSubdivisionEdge;
    begin
       NewEdge:=nil;
       if (P1<>nil) and (P2<>nil) then begin
          NewEdge:=Owner.EdgeExists(P1,P2);
          if NewEdge=nil then begin
            NewEdge:=TFreeSubdivisionEdge.Create(Owner);
            NewEdge.FStartpoint:=P1;
            NewEdge.FEndpoint:=P2;
            NewEdge.FFaces.Capacity:=2;
            NewEdge.FStartpoint.FEdges.Add(NewEdge);
            NewEdge.FEndpoint.FEdges.Add(NewEdge);
            NewEdge.FControlEdge:=ControlEdge;
            NewEdge.FCrease:=Crease;
            if NewEdge.FControlEdge then ControlEdges.Add(NewEdge)
                                    else InteriorEdges.Add(NewEdge);
          end else if NewEdge.FControlEdge then ControlEdges.Add(NewEdge);
       end else begin
          Showmessage('Error in TFreeSubdivisionFace.Subdivide');
       end;
       NewEdge.FFaces.Add(NewFace);
    end;
begin
   if NumberOfPoints<>3 then begin
      for I:=1 to FPoints.Count do begin
         P2:=FPoints[I-1];
         Index:=(I-2+FPoints.Count) mod FPoints.Count;
         PrevEdge:=Owner.EdgeExists(P2,FPoints[Index]);
         Index:=(I+FPoints.Count) mod FPoints.Count;
         CurrEdge:=Owner.EdgeExists(P2,FPoints[Index]);
         Index:=(I-1) mod 4;
         TmpIndex:=VertexPoints.SortedIndexOf(P2);
         Pts[Index]:=VertexPoints.Objects[TmpIndex];   // P2.FNewLocation;
         P2Point:=Pts[Index];
         Index:=(Index+1) mod 4;
         TmpIndex:=EdgePoints.SortedIndexOf(CurrEdge);
         Pts[index]:=EdgePoints.Objects[TmpIndex];     //CurrEdge.FNewLocation;
         CurrEdgePoint:=Pts[index];
         Index:=(Index+1) mod 4;
         TmpIndex:=FacePoints.SortedIndexOf(self);
         Pts[index]:=FacePoints.Objects[TmpIndex];     //self.FNewLocation;
         NewLocation:=Pts[index];
         Index:=(Index+1) mod 4;
         TmpIndex:=EdgePoints.SortedIndexOf(PrevEdge);
         Pts[index]:=Edgepoints.Objects[TmpIndex];    // PrevEdge.FNewLocation;
         PrevEdgePoint:=Pts[index];                   // add the new face
         NewFace:=TFreeSubdivisionFace.Create(Owner);
         Dest.Add(NewFace);
         //EdgeCheck(PrevEdge.FNewLocation,P2.FNewLocation,PrevEdge.Crease,PrevEdge.FControlEdge or ControlFace);
         //EdgeCheck(P2.FNewLocation,CurrEdge.FNewLocation,CurrEdge.Crease,CurrEdge.FControlEdge or ControlFace);
         //EdgeCheck(CurrEdge.FNewLocation,FNewLocation,False,False);
         //EdgeCheck(PrevEdge.FNewLocation,FNewLocation,False,False);
         EdgeCheck(PrevEdgePoint,P2Point,PrevEdge.Crease,PrevEdge.FControlEdge or ControlFace);
         EdgeCheck(P2Point,CurrEdgePoint,CurrEdge.Crease,CurrEdge.FControlEdge or ControlFace);
         EdgeCheck(CurrEdgePoint,NewLocation,False,False);
         EdgeCheck(PrevEdgePoint,NewLocation,False,False);
         NewFace.FPoints.Capacity:=4;
         for J:=1 to 4 do begin                       // Add new face to points
            Pts[J-1].FFaces.Add(NewFace);
            NewFace.FPoints.Add(Pts[J-1]);
         end;
      end;
   end else if NumberOfPoints=3 then begin
                   // Special case, quadrisect triancle by connecting all three
                   // edge points first the three surrounding triangles
      for I:=1 to FPoints.Count do begin
         P2:=FPoints[I-1];
         Index:=(I-2+FPoints.Count) mod FPoints.Count;
         PrevEdge:=Owner.EdgeExists(P2,FPoints[Index]);
         Index:=(I+FPoints.Count) mod FPoints.Count;
         CurrEdge:=Owner.EdgeExists(P2,FPoints[Index]);

         Index:=0;
         TmpIndex:=EdgePoints.SortedIndexOf(PrevEdge);
         Pts[Index]:=EdgePoints.Objects[tmpindex];    // PrevEdge.FNewLocation;
         Index:=1;
         TmpIndex:=VertexPoints.SortedIndexOf(P2);
         Pts[index]:=VertexPoints.Objects[Tmpindex];  // P2.FNewLocation;
         Index:=2;
         TmpIndex:=EdgePoints.SortedIndexOf(CurrEdge);
         Pts[index]:=Edgepoints.Objects[Tmpindex];    // CurrEdge.FNewLocation;
         NewFace:=TFreeSubdivisionFace.Create(Owner); // add the new face
         Dest.Add(NewFace);
         EdgeCheck(Pts[0],Pts[1],PrevEdge.Crease,PrevEdge.FControlEdge or ControlFace);
         EdgeCheck(Pts[1],Pts[2],CurrEdge.Crease,CurrEdge.FControlEdge or ControlFace);
         EdgeCheck(Pts[2],Pts[0],False,False);
         NewFace.FPoints.Capacity:=3;
         for J:=1 to 3 do begin                       // Add new face to points
            Pts[J-1].FFaces.Add(NewFace);
            NewFace.FPoints.Add(Pts[J-1]);
            Pts[J-1].AddFace(NewFace);
         end;
      end;                                          // then the center triangle
      for I:=1 to FPoints.Count do begin
         P2:=FPoints[I-1];
         Index:=(I-2+FPoints.Count) mod FPoints.Count;
         PrevEdge:=Owner.EdgeExists(P2,FPoints[Index]);
         TmpIndex:=EdgePoints.SortedIndexOf(PrevEdge);
         Pts[I-1]:=EdgePoints.Objects[TmpIndex];      // PrevEdge.FNewLocation;
      end;                                                  // add the new face
      NewFace:=TFreeSubdivisionFace.Create(Owner);
      Dest.Add(NewFace);
      EdgeCheck(Pts[0],Pts[1],False,False);
      EdgeCheck(Pts[1],Pts[2],False,False);
      EdgeCheck(Pts[2],Pts[0],False,False);
      NewFace.FPoints.Capacity:=3;
      for J:=1 to 3 do begin                          // Add new face to points
         Pts[J-1].FFaces.Add(NewFace);
         NewFace.FPoints.Add(Pts[J-1]);
         Pts[J-1].AddFace(NewFace);
      end;
   end;
end;
{-----------------------------}
{ TFreeSubdivisionControlFace }
{-----------------------------}
function TFreeSubdivisionControlFace.FGetChild(Index:Integer):TFreeSubdivisionFace;
   begin Result:=FChildren[index]; end;
function TFreeSubdivisionControlFace.FGetChildCount:Integer;
   begin Result:=FChildren.Count; end;
function TFreeSubdivisionControlFace.FGetColor:TColor;
   begin if Selected then Result:=DefaultSelectedColor
               else Result:=Layer.Color;
   end;
function TFreeSubdivisionControlFace.FGetControlEdge(Index:Integer):TFreeSubdivisionEdge;
   begin Result:=FControlEdges[Index]; end;
procedure TFreeSubdivisionControlFace.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedControlFaces.IndexOf(self);
   if Val then begin               // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedControlFaces.Add(self);
   end else begin
      if Index<>-1 then Owner.FSelectedControlFaces.Delete(index);
   end;
   if Assigned(Owner.FOnSelectItem) then Owner.FOnSelectItem(self);
end;
function TFreeSubdivisionControlFace.FGetSelected:Boolean;
   begin Result:=Owner.FSelectedControlFaces.IndexOf(self)<>-1; end;
function TFreeSubdivisionControlFace.FGetControlEdgeCount:Integer;
   begin Result:=FControlEdges.Count; end;
function TFreeSubdivisionControlFace.FGetEdge(Index:Integer):TFreeSubdivisionEdge;
   begin Result:=FEdges[Index]; end;
function TFreeSubdivisionControlFace.FGetEdgeCount:Integer;
   begin Result:=FEdges.Count; end;
function TFreeSubdivisionControlFace.FGetIndex:Integer;
   begin Result:=Owner.FControlFaces.IndexOf(self); end;
function TFreeSubdivisionControlFace.FGetVisible:Boolean;
   begin Result:=Layer.Visible; end;

procedure TFreeSubdivisionControlFace.FSetLayer(Val:TFreeSubdivisionLayer);
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

procedure TFreeSubdivisionControlFace.CalcExtents;
var I,J     : Integer;
    Face    : TFreeSubdivisionFace;
    P1      : TFreeSubdivisionPoint;
begin                           // Calculate min/max coordinate of all children
   if NumberOfPoints>0 then FMin:=Point[0].Coordinate
                       else FMin:=ZERO;
   FMax:=FMin;
   if FChildren.Count>0 then begin
      for I:=1 to FChildren.Count do begin
         Face:=FChildren[I-1];
         for J:=1 to Face.FPoints.Count do begin
            P1:=Face.FPoints[J-1];
            MinMax(P1.FCoordinate,FMin,FMax);
         end;
      end;
   end else
   for I:=2 to NumberOfPoints do MinMax(Point[I-1].Coordinate,FMin,FMax);
end;

procedure TFreeSubdivisionControlFace.Clear;
begin
   ClearChildren;
   inherited Clear;
   FLayer:=nil;
end;

procedure TFreeSubdivisionControlFace.ClearChildren;
var I:Integer;
begin
   for I:=1 to Childcount do Child[I-1].Destroy;
   FChildren.Clear;
   for I:=1 to EdgeCount do Edge[I-1].Destroy;
   FEdges.Clear;
end;

constructor TFreeSubdivisionControlFace.Create(Owner:TFreeSubdivisionSurface);
begin
   FLayer:=nil;
   FChildren:=TFasterlist.Create;
   FEdges:=TFasterList.Create;
   FControlEdges:=TFasterList.Create;
   Inherited Create(Owner);
end;

function TFreeSubdivisionControlFace.DistanceToCursor(X,Y:Integer;var P:T3DVector;Viewport:TFreeViewport):integer;
var I,Dist  : Integer;
    Param   : TFloatType;
    Edge    : TFreeSubdivisionEdge;
    P1,P2   : T3DVector;
begin
   Result:=1000000;
   P:=ZERO;
   if Owner.ShowInteriorEdges then begin // check distance to all interior edges
      for I:=1 to FEdges.Count do begin
         Edge:=FEdges[I-1];
         P1:=Edge.FStartpoint.Coordinate;
         P2:=Edge.FEndpoint.Coordinate;
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
         if Dist=0 then begin break; end;
      end;
   end;
end;

procedure TFreeSubdivisionControlFace.Delete;
var I,Index: Integer;
    Edge : TFreesubdivisionControlEdge;
    P1,P2: TFreeSubdivisionPoint;
begin                                                 // delete from selection;
   Selected:=false;                                        // remove from layer
   Layer:=nil;
   Index:=Owner.FControlFaces.IndexOf(Self);
   if Index<>-1 then begin
      Owner.FControlFaces.Delete(Index);
      P1:=Point[NumberOfPoints-1];
      P1.DeleteFace(Self);
      for I:=1 to NumberOfPoints do begin
         P2:=Point[I-1];
         Edge:=Owner.EdgeExists(P1,P2) as TFreesubdivisionControlEdge;
         P2.DeleteFace(Self);
         if Edge<>nil then begin
            Edge.DeleteFace(Self);
            if Edge.NumberOfFaces=0 then Edge.Delete;
         end;
         P1:=P2;
      end;
   end;
   Clear;
   Destroy;
end;

destructor TFreeSubdivisionControlFace.Destroy;
begin
   Inherited Destroy;
   FEdges.Destroy;
   FControlEdges.Destroy;
   FChildren.Destroy;
end;

procedure TFreeSubdivisionControlFace.Draw(Viewport:TFreeViewport;mode:TPenMode);
var I,J: Integer;
    Edge: TFreeSubdivisionEdge;
    Child: TFreeSubdivisionFace;
    P1,P2,P3: T3DVector;
    R,G,B: Byte;
begin
   if Viewport.Shade then begin
      R:=GetRValue(Layer.Color);
      G:=GetGValue(Layer.Color);
      B:=GetBValue(Layer.Color);
      for I:=1 to ChildCount do begin
         Child:=Self.Child[I-1];
         for J:=2 to Child.NumberOfpoints-1 do begin
            P1:=Child.Point[0].Coordinate;
            P2:=Child.Point[J-1].Coordinate;
            P3:=Child.Point[J].Coordinate;
            Viewport.ShadeTriangle(P1,P2,P3,R,G,B);
            if (Owner.DrawMirror) and (Layer.Symmetric) then begin
               P1.Y:=-P1.Y;
               P2.Y:=-P2.Y;
               P3.Y:=-P3.Y;
               Viewport.ShadeTriangle(P1,P3,P2,R,G,B);
            end;
         end;
      end;
   end else begin     // Draw interior edges (not descending from controledges)
      Viewport.PenStyle:=psSolid;
      if Selected then Viewport.PenColor:=clYellow
                  else Viewport.PenColor:=Layer.Color;
      for I:=1 to FEdges.Count do begin
         Edge:=FEdges[I-1];
         Edge.Draw(Owner.DrawMirror and Layer.Symmetric,Viewport);
      end;                           // Draw edges descending from controledges
      for I:=1 to FControlEdges.Count do begin
         Edge:=FControlEdges[I-1];
         Edge.Draw(Owner.DrawMirror and Layer.Symmetric,Viewport);
      end;
   end;
end;

function TFreeSubdivisionControlFace.InsertEdge(P1,P2:TFreeSubdivisionControlPoint):TFreesubdivisionControlEdge;
var Tmp,I: Integer;
    Pts: TFasterList;
begin
   Result:=nil;
// try
      if (P1.FFaces.IndexOf(self)<>-1) and (P2.FFaces.IndexOf(self)<>-1) then begin
         if Owner.EdgeExists(P1,P2)<>nil then exit;
         Tmp:=IndexOfPoint(P1);
         Pts:=TFasterList.Create;
         Pts.Add(P1);
         for I:=1 to NumberOfpoints do begin
            Tmp:=(Tmp+1) mod NumberOfpoints;
            Pts.Add(Point[Tmp]);
            if Pts[Pts.Count-1]=P2 then break;
         end;
         if Pts.Count>2 then begin
            Owner.AddControlFace(Pts,Layer);
         end;
         Tmp:=IndexOfPoint(P2);
         Pts.Clear;
         Pts.Add(P2);
         for I:=1 to NumberOfpoints do begin
            Tmp:=(Tmp+1) mod NumberOfpoints;
            Pts.Add(Point[Tmp]);
            if Pts[Pts.Count-1]=P1 then break;
         end;
         if Pts.Count>2 then begin
            Owner.AddControlFace(Pts,Layer);
         end;
         Pts.Destroy;
         Delete;
      end;
      Result:=Fowner.EdgeExists(P1,P2) as TFreesubdivisionControlEdge;
// except
//   Result:=Fowner.EdgeExists(P1,P2) as TFreesubdivisionControlEdge;
// end;
end;

procedure TFreeSubdivisionControlFace.RemoveReferences;
var P1,P2   : TFreeSubdivisionPoint;
    I       : Integer;
    Edge    : TFreeSubdivisionEdge;
begin
   P1:=FPoints[FPoints.Count-1];
   for I:=1 to FPoints.Count do begin
      P2:=FPoints[I-1];
      P2.DeleteFace(self);
      Edge:=FOwner.EdgeExists(P1,P2);
      if Edge<>nil then begin Edge.DeleteFace(self); end;
      P1:=p2;
   end;
end;

procedure TFreeSubdivisionControlFace.Subdivide(Owner:TFreeSubdivisionSurface;ControlFace:Boolean;VertexPoints,EdgePoints,FacePoints,InteriorEdges,ControlEdges,Dest:TFasterList);
var TmpList,Tmp: TFasterList;
    I: Integer;
    Face: TFreeSubdivisionFace;
begin
   FControlEdges.Clear;
   if FChildren.Count=0 then begin
      FChildren.Capacity:=NumberOfPoints;
      FEdges.Capacity:=4;
      Inherited Subdivide(Owner,True,VertexPoints,EdgePoints,FacePoints,FEdges,FControlEdges,FChildren);
   end else begin
      TmpList:=TFasterlist.Create;
      TmpList.Capacity:=4*ChildCount;
      Tmp:=TFasterList.Create;
      I:=Round(Power(2,Owner.FCurrentSubdivisionLevel));
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
   for I:=1 to FControlEdges.Count do begin
      if ControlEdges.SortedIndexOf(FControlEdges[I-1])=-1 then
         ControlEdges.AddSorted( FControlEdges[I-1] );
   end;
   CalcExtents;
end;
{-------------------------}
{ TFreeSubdivisionSurface }
{-------------------------}
function TFreeSubdivisionSurface.AddControlPoint(P:T3DVector;BoundaryVertices:TFasterList):TFreeSubdivisionControlPoint;
var I             : Integer;
    MaxError      : Double;
    Point         : TFreeSubdivisionControlPoint;
   function NewPoint(P:T3DVector):TFreeSubdivisionControlPoint;
   begin
      Result:=TFreeSubdivisionControlPoint.Create(self);
      Result.FCoordinate:=P;
      FControlPoints.Add(Result);
   end;
begin
   result:=nil;
   MaxError:=1e-5;
   for I:=1 to BoundaryVertices.Count do begin
      Point:=BoundaryVertices[I-1];
      if Sqr(P-Point.FCoordinate)<=MaxError then begin
         Result:=Point;
         break;
      end;
   end;
   if Result=nil then Result:=NewPoint(P);
end;
function TFreeSubdivisionSurface.AddControlPoint(P:T3DVector):TFreeSubdivisionControlPoint;
var I             : Integer;
    MaxError      : Double;
    Edge          : TFreeSubdivisionEdge;
   function NewPoint(P:T3DVector):TFreeSubdivisionControlPoint;
   begin
      Result:=TFreeSubdivisionControlPoint.Create(self);
      Result.FCoordinate:=P;
      FControlPoints.Add(Result);
   end;
begin
   result:=nil;
   MaxError:=1e-5;
   for I:=1 to NumberOfControlEdges do begin
      Edge:=FControlEdges[I-1];
      if Edge.FFaces.Count<=1 then begin                       // boundary edge
         if Sqr(P-Edge.FStartpoint.FCoordinate)<=MaxError then begin
            Result:=Edge.FStartpoint as TFreeSubdivisionControlPoint;
            break;
         end else if Sqr(P-Edge.FEndpoint.FCoordinate)<=MaxError
         then begin
            Result:=Edge.FEndpoint as TFreeSubdivisionControlPoint;
            break;
         end;
      end;
   end;
   if Result=nil then begin               // Search controlpoints without edges
      for I:=1 to FControlPoints.Count
      do if ControlPoint[I-1].NumberOfEdges=0 then begin
         if Sqr(P-ControlPoint[I-1].FCoordinate)<=MaxError then begin
            Result:=FControlPoints[I-1];
            break;
         end;
      end;
   end;
   if Result=nil then Result:=NewPoint(P);
end;
procedure TFreeSubdivisionSurface.AddControlPoint(P:TFreeSubdivisionControlPoint);
begin
   if FControlPoints.IndexOf(P)=-1 then begin
      FControlPoints.Add(P);
      P.FOwner:=self;
   end;
   Build:=False;
end;
// Adds a new controlpoint at 0,0,0 without checking other points
function TFreeSubdivisionSurface.AddControlPoint:TFreeSubdivisionControlPoint;
begin
   Result:=TFreeSubdivisionControlPoint.Create(self);
   Result.FCoordinate:=ZERO;
   FControlPoints.Add(Result);
end;
function TFreeSubdivisionSurface.AddNewLayer:TFreeSubdivisionLayer;
begin
   Result:=TFreeSubdivisionLayer.Create(Self);
   FLayers.Add(Result);
   Result.FLayerID:=FRequestNewLayerID;
   if assigned(FOnChangeLayerData) then FOnChangeLayerData(self);
   ActiveLayer:=Result;
end;
function TFreeSubdivisionSurface.FGetControlPoint(Index:Integer):TFreeSubdivisionControlPoint;
   begin Result:=TObject(FControlpoints[index]) as TFreeSubdivisionControlPoint;
   end;
function TFreeSubdivisionSurface.FGetControlEdge(Index:Integer):TFreesubdivisionControlEdge;
   begin Result:=TObject(FControlEdges[index]) as TFreesubdivisionControlEdge;
   end;
function TFreeSubdivisionSurface.FGetControlFace(Index:Integer):TFreeSubdivisionControlFace;
   begin Result:=TObject(FControlFaces[index]) as TFreeSubdivisionControlFace;
   end;
function TFreeSubdivisionSurface.FGetLayer(Index:Integer):TFreeSubdivisionLayer;
begin if (Index>=0) and (Index<Flayers.Count) then Result:=FLayers[index];
//    else begin Raise Exception.Create('Invalid layer index!'); end;
end;
function TFreeSubdivisionSurface.FGetNumberOfControlPoints:Integer;
   begin Result:=FControlPoints.Count; end;
function TFreeSubdivisionSurface.FGetNumberOfControlEdges:Integer;
   begin Result:=FControlEdges.Count; end;
function TFreeSubdivisionSurface.FGetNumberOfControlFaces:Integer;
   begin Result:=FControlFaces.Count; end;
function TFreeSubdivisionSurface.FGetNumberOfFaces:Integer;
var I:Integer;
begin Result:=0;
   for I:=1 to NumberOfControlfaces do inc(Result,ControlFace[I-1].ChildCount);
end;
function TFreeSubdivisionSurface.FGetNumberOfLayers:Integer;
   begin Result:=FLayers.Count; end;
function TFreeSubdivisionSurface.FGetPoint(Index:Integer):TFreeSubdivisionPoint;
   begin if FPoints.Count>0 then Result:=FPoints[index]
                            else Result:=FControlpoints[index];
   end;
function TFreeSubdivisionSurface.FGetEdge(Index:Integer):TFreeSubdivisionEdge;
begin if FEdges.Count>0 then Result:=FEdges[index]
                        else Result:=FControlEdges[index];
end;
function TFreeSubdivisionSurface.FGetNumberOfPoints:Integer;
   begin if FPoints.Count>0 then Result:=FPoints.Count
                            else Result:=FControlpoints.Count;
   end;
function TFreeSubdivisionSurface.FGetNumberOfSelectedControlEdges:Integer;
   begin Result:=FSelectedControlEdges.Count; end;
function TFreeSubdivisionSurface.FGetNumberOfSelectedControlFaces:Integer;
   begin Result:=FSelectedControlFaces.Count; end;
function TFreeSubdivisionSurface.FGetNumberOfSelectedControlPoints:Integer;
   begin Result:=FSelectedControlPoints.Count; end;
function TFreeSubdivisionSurface.FGetNumberOfEdges:Integer;
   begin if FEdges.Count>0 then Result:=FEdges.Count
                           else Result:=FControlEdges.Count;
   end;
function TFreeSubdivisionSurface.FGetSelectedControlEdge(Index:Integer):TFreeSubdivisionControlEdge;
   begin Result:=FSelectedControlEdges[index]; end;
function TFreeSubdivisionSurface.FGetSelectedControlFace(Index:Integer):TFreeSubdivisionControlFace;
   begin Result:=FSelectedControlfaces[index]; end;
function TFreeSubdivisionSurface.FGetSelectedControlPoint(Index:Integer):TFreeSubdivisionControlPoint;
   begin Result:=FSelectedControlPoints[index]; end;
function TFreeSubdivisionSurface.FRequestNewLayerID:Integer;
begin
   inc(FLastusedLayerID);
   Result:=FLastusedLayerID;
end;
procedure TFreeSubdivisionSurface.FSetActiveLayer(Val:TFreeSubdivisionLayer);
begin
   FActiveLayer:=Val;
   if assigned(FOnChangeActiveLayer) then FOnChangeActiveLayer(self,FActiveLayer);
end;
procedure TFreeSubdivisionSurface.FSetBuild(Val:Boolean);
begin
   inherited FSetBuild(Val);
   if not Val then begin ClearFaces; FCurrentSubdivisionLevel:=0; end;
end;
procedure TFreeSubdivisionSurface.FSetDesiredSubdivisionLevel(val:byte);
begin
   if Val>4 then Val:=4;
   if Val<>FDesiredSubdivisionLevel then begin
      FDesiredSubdivisionLevel:=val;
      Build:=False;
   end;
end;

procedure TFreeSubdivisionSurface.FSetFShowControlNet(Val:Boolean);
begin if Val<>FShowControlNet then begin FShowControlNet:=Val; end;
end;

function TFreeSubdivisionSurface.AddControlFace(Points:array of T3DVector;NoPoints:Integer):TFreeSubdivisionControlFace;
var I,J,N      : Integer;
    P          : T3DVector;
    Edge       : TFreeSubdivisionEdge;
    Point,Prev : TFreeSubdivisionPoint;
    dist       : TFloatType;
    MaxError   : double;
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
      end;
      Inc(I);
   end;
   Prev:=nil;
   if NoPoints>2 then begin
      Result:=TFreeSubdivisionControlFace.Create(Self);
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
      for I:=1 to Result.NumberOfpoints do begin
         N:=0;
         Point:=Result.Point[I-1];
         for J:=1 to Point.NumberOfFaces do if Point.Face[J-1]=Result then Inc(N);
         if N>1 then begin InvalidFace:=True; end;
      end;
      if (Result.NumberOfpoints<3) or (InvalidFace) then begin
         for J:=1 to Result.NumberOfpoints do begin // Delete invalid controlfaces
            Result.Point[J-1].DeleteFace(Result);
            if J=1 then Edge:=EdgeExists(Result.Point[Result.NumberOfPoints-1],Result.Point[J-1])
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
      end else begin
         FControlFaces.Add(Result);
      end;
   end else Result:=nil;
   Build:=False;
end;

function TFreeSubdivisionSurface.AddControlEdge(P1,P2:TFreeSubdivisionPoint):TFreesubdivisionControlEdge;
var Edge : TFreesubdivisionControlEdge;
begin
   Edge:=EdgeExists(P1,P2) as TFreesubdivisionControlEdge;
   if Edge=nil then begin
      Edge:=TFreesubdivisionControlEdge.Create(Self);
      Edge.Startpoint:=P1;
      Edge.Endpoint:=P2;
      Edge.FControlEdge:=True;
      P1.AddEdge(Edge);
      P2.AddEdge(Edge);
      FControlEdges.Add(Edge);
      Result:=Edge;
   end else Result:=Edge;
end;

procedure TFreeSubdivisionSurface.AddControlEdge(Edge:TFreesubdivisionControlEdge);
begin
   if FControlEdges.IndexOf(Edge)=-1 then begin
      FControlEdges.Add(Edge);
      Edge.FControlEdge:=True;
      Edge.FOwner:=self;
   end;
end;

function TFreeSubdivisionSurface.AddControlFace(Points:TFasterList;Layer:TFreeSubdivisionLayer):TFreeSubdivisionControlFace;
var I,J,N,Index: Integer;
    P1,P2      : TFreeSubdivisionControlPoint;
    Edge       : TFreesubdivisionControlEdge;
    Face       : TFreeSubdivisionControlFace;
    FaceExists : boolean;
begin
   Result:=nil;
   if Points.Count>2 then begin
      if Points[Points.Count-1]=Points[0] then Points.Delete(Points.Count-1);
      // Check if another patch with the same vertices exists
      FaceExists:=False;
      I:=1;
      while I<=Points.Count do begin
         P1:=Points[I-1];
         J:=1;
         while J<=P1.NumberOfFaces do begin
            Face:=P1.Face[J-1] as TFreeSubdivisionControlFace;
            if Face.NumberOfpoints=Points.Count then begin
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
            end; inc(J);
         end; Inc(I);
      end;
      if FaceExists then begin Result:=nil; exit; end;
      Result:=TFreeSubdivisionControlFace.Create(Self);
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
         Edge:=EdgeExists(P1,P2) as TFreesubdivisionControlEdge;
         if Edge=nil then begin
            Edge:=TFreesubdivisionControlEdge.Create(Self);
            Edge.FStartpoint:=P1;
            Edge.FEndpoint:=P2;
            Edge.FControlEdge:=True;
            P1.FEdges.Add(Edge);
            P2.FEdges.Add(Edge);
            FControlEdges.Add(Edge);
            Edge.FFaces.Add(Result);
         end else Edge.AddFace(Result);
         P1:=P2;
      end;
      if Result.NumberOfpoints<3 then begin
         Result.Destroy;
         Result:=nil;
      end else begin
         Build:=False;
      end;
   end;
end;
function TFreeSubdivisionSurface.AddControlFace(Points:TFasterList):TFreeSubdivisionControlFace;
begin Result:=AddControlFace(Points,nil);
end;
procedure TFreeSubdivisionSurface.AddControlFace(Face:TFreeSubdivisionControlFace);
begin
   if FControlFaces.IndexOf(Face)=-1 then begin
      FControlFaces.Add(Face);
      Face.FOwner:=self;
   end;
end;
procedure TFreeSubdivisionSurface.Clear;
var I: Integer; Layer: TFreeSubdivisionLayer;
begin
   inherited Clear;
   for I:=1 to FControlPoints.Count do ControlPoint[I-1].Destroy; FControlPoints.Clear;
   for I:=1 to NumberOfControlFaces do ControlFace[I-1].Destroy; FControlFaces.Clear;
   for I:=1 to NumberOfControlEdges do ControlEdge[I-1].Destroy; FControlEdges.Clear;
   for I:=1 to FEdges.Count do Edge[I-1].Destroy; FEdges.Clear;
   for I:=1 to FPoints.Count do Point[I-1].Destroy; FPoints.Clear;
   for i:=1 to NumberOfLayers do self.Layer[I-1].Destroy;  FLayers.Clear;
   if assigned(FOnChangeLayerData) then FOnChangeLayerData(self);
   FLastusedLayerID:=-1;                    // delete lists with selected items
   FSelectedControlPoints.Clear;
   FSelectedControlEdges.Clear;
   FSelectedControlFaces.Clear;
   Layer:=AddNewLayer;            // Add one default layer and set it to active
   ActiveLayer:=Layer;
   FCreaseColor:=clRed;
   Build:=False;
   FDrawMirror:=False;
   FShowControlNet:=True;
   FShowInteriorEdges:=False;
   FInitialized:=False;
   FDesiredSubdivisionLevel:=1;
end;
procedure TFreeSubdivisionSurface.ClearFaces;
var I : integer;
begin
   for I:=1 to NumberOfControlFaces do Controlface[I-1].ClearChildren; // deletes children and rendermesh
   for I:=1 to FEdges.Count do Edge[I-1].Destroy;
   FEdges.Clear;
   for I:=1 to FPoints.Count do Point[I-1].Destroy;
   FPoints.Clear;
   for I:=1 to NumberOfControlFaces do begin
      Controlface[I-1].FControlEdges.Clear;
   end;
end;
procedure TFreeSubdivisionSurface.Clearselection; // Deselect all selected items at once
begin
   FSelectedControlPoints.Clear;
   FSelectedControlEdges.Clear;
   FSelectedControlFaces.Clear;
   if Assigned(FOnSelectItem) then FOnSelectItem(nil);
end;
procedure TFreeSubdivisionSurface.Edge_Connect;
var Face: TFreeSubdivisionControlFace;
    Edge: TFreeSubdivisionControlEdge;
    V1,V2: TFreeSubdivisionControlPoint;
    I,J: Integer;
begin
   if NumberOfSelectedControlPoints>1 then begin
      for I:=NumberOfSelectedControlPoints-1 downto 1 do begin
         V1:=SelectedControlPoint[NumberOfSelectedControlPoints-2];
         V2:=SelectedControlPoint[NumberOfSelectedControlPoints-1];
         if EdgeExists(V1,V2)=nil then begin
            if (V1.NumberOfFaces=0) and (V2.NumberOfFaces=0) then begin
               Edge:=AddControlEdge(V1,V2);
               if Edge<>nil then edge.Crease:=True;
            end else For J:=1 to V1.NumberOfFaces do begin
               Face:=V1.Face[J-1] as TFreeSubdivisionControlFace;
               if V2.IndexOfFace(Face)<>-1 then begin
                  Face.InsertEdge(V1,V2);
                  V2.Selected:=false;
                  Build:=False;
                  break;
               end;
            end;
         end else if NumberOfSelectedControlPoints=2 then MessageDlg('Edge already exists!',mtWarning,[mbOk],0);
      end;
      for I:=NumberOfSelectedControlPoints downto 1 do SelectedControlPoint[I-1].Selected:=False;
   end;
end;

procedure TFreeSubdivisionSurface.Extents(Var Min,Max : T3DVector);
var I: Integer;
begin
   if not build then Rebuild;
   for I:=1 to NumberOfLayers do Layer[I-1].Extents(Min,Max);
end;

procedure TFreeSubdivisionSurface.CalculateIntersections(Plane:T3DPlane;Faces,Destination:TFasterList);

type IntersectionData = record
        Point  : T3DVector;
        Knuckle: Boolean;
     end;
var I,J,K,N,M,ArrayLength,NoPoints: Integer;
    Edge       : TFreeSubdivisionEdge;
    P1,P2,P3   : TFreeSubdivisionPoint;
    CtrlFace   : TFreesubdivisionControlFace;
    Side1,Side2,Parameter: TFloatType;
    Output     : T3DVector;
    Spline     : TFreeSpline;
    Face,F2    : TFreeSubdivisionface;
    IntArray   : array of IntersectionData;
    Edges      : TFasterList;
    AddEdge    : Boolean;
begin  // first assemble all edges belonging to this set of faces
   Edges:=TFasterlist.Create;
   Edges.Capacity:=Faces.Count+100;
   ArrayLength:=10;
   Setlength(IntArray,ArrayLength);
   for I:=1 to Faces.Count do begin
      CtrlFace:=Faces[I-1];
      if Ctrlface.FaceIndex=-2 then exit;
      begin
         for J:=1 to Ctrlface.ChildCount do begin
            Face:=Ctrlface.Child[J-1];
            NoPoints:=0;
            P1:=Face.Point[Face.NumberOfPoints-1];
            Side1:=Plane.A*P1.FCoordinate.x+Plane.B*P1.FCoordinate.y+Plane.C*P1.FCoordinate.z+Plane.D;
            for K:=1 to Face.FPoints.Count do begin
               P2:=Face.FPoints[K-1];
               Side2:=Plane.A*P2.FCoordinate.x+Plane.B*P2.FCoordinate.y+Plane.C*P2.FCoordinate.z+Plane.D;
               AddEdge:=False;
               if ((Side1<-1e-5) and (Side2>1e-5))
               or ((Side1>1e-5) and (Side2<-1e-5)) then begin // regular intersection of edge add the edge to the list
                  Parameter:=-side1/(side2-side1);
                  Output:=P1.FCoordinate + Parameter*(P2.FCoordinate-P1.FCoordinate);
                  Inc(NoPoints);
                  if NoPoints>ArrayLength then
                  begin
                     Inc(ArrayLength,10);
                     Setlength(IntArray,ArrayLength);
                  end;
                  IntArray[NoPoints-1].Point:=Output;
                  Edge:=EdgeExists(P1,P2);
                  if Edge<>nil then IntArray[NoPoints-1].Knuckle:=Edge.Crease
                               else IntArray[NoPoints-1].Knuckle:=False;
               end else begin  // Does the edge lie entirely within the plane??
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
                                 Parameter:=Plane.A*P3.FCoordinate.x+Plane.B*P3.FCoordinate.y+Plane.C*P3.FCoordinate.z+Plane.D;
                                 if abs(Parameter)>=1e-5 then begin
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
                              Inc(NoPoints);
                              if NoPoints+2>ArrayLength then begin
                                 Inc(ArrayLength,10);
                                 Setlength(IntArray,ArrayLength);
                              end;
                              IntArray[NoPoints-1].Point:=P1.FCoordinate;
                              if not Edge.FCrease then IntArray[NoPoints-1].Knuckle:=P1.VertexType<>svRegular
                                                  else IntArray[NoPoints-1].Knuckle:=P1.VertexType=svCorner;
                              Inc(NoPoints);
                              IntArray[NoPoints-1].Point:=P2.FCoordinate;
                              if not Edge.FCrease then IntArray[NoPoints-1].Knuckle:=P2.VertexType<>svRegular
                                                  else IntArray[NoPoints-1].Knuckle:=P2.VertexType=svCorner;
                           end;
                        end;
                     end;
                  end else if abs(Side2)<1e-5 then begin Inc(NoPoints);
                     if NoPoints>ArrayLength then begin
                        Inc(ArrayLength,10);
                        Setlength(IntArray,ArrayLength);
                     end;
                     IntArray[NoPoints-1].Point:=P2.Coordinate;
                     IntArray[NoPoints-1].Knuckle:=P2.VertexType<>svRegular;
                  end;
               end;
               P1:=P2;
               Side1:=Side2;
            end;
            if NoPoints>1 then begin
               if Abs(IntArray[0].Point-IntArray[NoPoints-1].Point)<1e-4
                  then dec(NoPoints);
               if NoPoints>1 then begin
                  Spline:=TFreeSpline.Create;
                  Spline.Capacity:=NoPoints;
                  for K:=1 to NoPoints do begin
                     Spline.Add(IntArray[K-1].Point);
                     Spline.Knuckle[Spline.NumberOfPoints-1]:=IntArray[K-1].Knuckle;
                  end;
                  Destination.Add(Spline);
               end;
            end;
         end;
      end;
   end;
   if Destination.Count>1 then begin
      Destination.Capacity:=Destination.Count;
      JoinSplineSegments(0.01,False,Destination);
   end;
   Edges.Destroy;
end;

constructor TFreeSubdivisionSurface.Create;
begin
   FControlPoints:=TFasterList.Create;
   FControlEdges:=TFasterList.Create;
   FControlFaces:=TFasterList.Create;
   FPoints:=TFasterList.Create;
   FEdges:=TFasterList.Create;
   FLayers:=TFasterList.Create;
   FSelectedControlPoints:=TFasterList.Create;
   FSelectedControlEdges:=TFasterList.Create;
   FSelectedControlFaces:=TFasterList.Create;
   inherited Create;
end;

destructor TFreeSubdivisionSurface.Destroy;
var I : Integer;
begin
   Clear;              // Make sure to also destroy the default layer (layer 0)
   for I:=1 to NumberOfLayers do Layer[I-1].Destroy;
   FLayers.Clear;
   FControlFaces.Free;
   FControlEdges.Free;
   FControlPoints.Free;
   FEdges.Free;
   FPoints.Free;
   FLayers.Free;
   FSelectedControlPoints.Free;
   FSelectedControlEdges.Free;
   FSelectedControlFaces.Free;
   inherited Destroy;
end;

procedure TFreeSubdivisionSurface.Draw(Viewport:TFreeViewport;Mode:TPenmode);
var I    : Integer;
    Edge : TFreeSubdivisionEdge;
begin
   if not Build then Rebuild;
   if Viewport.Shade then begin //
   end else inherited Draw(Viewport,Mode);
   for I:=1 to NumberOfLayers do Layer[I-1].Draw(Viewport,Mode);
   if ShowControlNet then begin
      for I:=1 to NumberOfControlEdges do begin
         Edge:=ControlEdge[I-1];
         Edge.Draw(False,Viewport);
      end;
      for I:=1 to NumberOfControlPoints do
         if ControlPoint[I-1].Visible then ControlPoint[I-1].Draw(Viewport);
   end;
end;

function TFreeSubdivisionSurface.EdgeExists(P1,P2:TFreeSubdivisionPoint):TFreeSubdivisionEdge;
var I    : Integer;
    Edge : TFreeSubdivisionEdge;
begin
   Result:=nil;
   // If the edge exists then it must exist
   // in both the points, therefore only the point
   // with the smallest number of edges has to be checked
   if P1.FEdges.Count<=P2.FEdges.Count then begin
      for I:=1 to P1.FEdges.Count do begin
         Edge:=P1.FEdges[I-1];
         if ((Edge.FStartpoint=P1) and (Edge.FEndpoint=P2))
         or ((Edge.FStartpoint=P2) and (Edge.FEndpoint=P1)) then begin
            Result:=Edge;
            exit;
         end;
      end;
   end else for I:=1 to P2.FEdges.Count do begin
      Edge:=P2.FEdges[I-1];
      if ((Edge.FStartpoint=P1) and (Edge.FEndpoint=P2))
      or ((Edge.FStartpoint=P2) and (Edge.FEndpoint=P1)) then begin
         Result:=Edge;
         exit;
      end;
   end;
end;

function TFreeSubdivisionSurface.IntersectPlane(Plane:T3DPlane;List:TFasterList):Boolean;
var I                : Integer;
    CtrlFace         : TFreesubdivisionControlFace;
    IntersectedFaces : TFasterList;
    Min,Max          : T3DVector;
begin
   Result:=False;
   if not build then Rebuild;
   if not PlaneIntersectsBox( FMin,FMax,Plane ) then exit;
   IntersectedFaces:=TFasterList.Create;
   for I:=1 to NumberOfControlFaces do begin
      CtrlFace:=ControlFace[I-1];
      Min:=CtrlFace.FMin;
      Max:=CtrlFace.FMAx;
      if PlaneIntersectsBox(Min,Max,Plane) then IntersectedFaces.Add(CtrlFace);
   end;
   CalculateIntersections(Plane,IntersectedFaces,List);
   IntersectedFaces.Destroy;
   Result:=List.Count>0;
end;

procedure TFreeSubdivisionSurface.IsolateEdges(Source,destination:TFasterList);
var I: Integer;
    Edge,Edge2: TFreesubdivisionControlEdge;
    TmpEdges,TmpPts: TFasterList;
    Findmore: Boolean;
begin                       // Try to isolate individual (closed) sets of edges
   TmpEdges:=TFasterList.Create;
   while Source.Count>0 do
   begin
      Edge:=Source[0];
      Source.Delete(0);
      FindMore:=True;
      TmpEdges.Clear;
      TmpEdges.Add(Edge);
      while (Source.Count>0) and (FindMore) do begin FindMore:=False;
         for I:=1 to Source.Count do begin Edge2:=Source[I-1]; // compare at start
            Edge:=TmpEdges[0];
            if (Edge2.FStartpoint=Edge.FStartpoint) or (Edge2.FStartpoint=Edge.FEndpoint)
            or (Edge2.FEndpoint=Edge.FStartpoint) or (Edge2.FEndpoint=Edge.FEndpoint)
            then begin
               TmpEdges.Insert(0,Edge2);
               Source.Delete(I-1);
               Findmore:=true;
               break;
            end else begin
               Edge:=TmpEdges[Tmpedges.Count-1];
               if (Edge2.FStartpoint=Edge.FStartpoint) or (Edge2.FStartpoint=Edge.FEndpoint)
               or (Edge2.FEndpoint=Edge.FStartpoint) or (Edge2.FEndpoint=Edge.FEndpoint)
               then begin
                  TmpEdges.Add(Edge2);
                  Source.Delete(I-1);
                  Findmore:=true;
                  break;
               end;
            end;
         end;
      end;
      if TmpEdges.Count>1 then begin   // Sort all found edges in correct order
         SortEdges(TmpEdges,TmpPts);
         if TmpPts<>nil then Destination.Add(TmpPts);
      end;
   end;
   TmpEdges.Destroy;
end;

procedure TFreeSubdivisionSurface.Selection_Delete;
  var I : Integer;
begin                            // First faces, then edges and finally points!
   I:=self.NumberOfSelectedControlFaces;
   while I>=1 do begin
      SelectedControlFace[I-1].Delete;
      dec(I);
      if I>NumberOfSelectedControlFaces then  begin
         I:=NumberOfSelectedControlFaces;
      end;
   end;
   I:=self.NumberOfSelectedControlEdges;
   while I>=1 do begin
      SelectedControlEdge[I-1].Delete;
      dec(I);
      if I>NumberOfSelectedControlEdges then  begin
         // Security check ==> if an edge is deleted from one isolated patch (with all edges only attached
         // to the current face), the patch will become degenerate and therefore the patch (and the other
         // edges) will be deleted, and NumberOfSelectedControlEdges may become smaller than index I
         I:=NumberOfSelectedControlEdges;
      end;
   end;
   I:=self.NumberOfSelectedControlPoints;
   while I>=1 do begin
      SelectedControlPoint[I-1].Delete;
      dec(I);
      if I>NumberOfSelectedControlPoints then begin           // Same as above
         I:=NumberOfSelectedControlPoints;
      end;
   end;
   Build:=False;
end;

procedure TFreeSubdivisionSurface.SortEdges(Edges:TFasterList);
var Edge1,Edge2:TFreeSubdivisionEdge; J:Integer;
begin
   if Edges.Count<=1 then exit else begin Edge1:=Edges[0];
      for J:=2 to Edges.Count do begin Edge2:=Edges[J-1];
         if J=2 then begin
            if (Edge1.FStartPoint=Edge2.FStartPoint) then Edge1.SwapData else
            if (Edge1.FStartPoint=Edge2.FEndPoint) then begin
                Edge1.SwapData;
                Edge2.SwapData;
            end else if (Edge1.FEndPoint=Edge2.FStartPoint) then begin
            end else if (Edge1.FEndPoint=Edge2.FEndPoint) then begin
               Edge2.SwapData;
            end;
         end else begin
            if (Edge1.FEndPoint=Edge2.FEndPoint) then Edge2.SwapData;
            if (Edge1.FEndPoint=Edge2.FStartPoint) then begin
               Edge2.SwapData;
               Edge2.SwapData;
            end;
         end;  Edge1:=Edge2;
      end;
   end;
end;

procedure TFreeSubdivisionSurface.SortEdges(Edges:TFasterList;var Points:TFasterList);
  var I: Integer; Edge: TFreeSubdivisionEdge;
begin
   if Edges.Count>0 then begin
      Points:=TFasterList.Create;
      Points.Capacity:=Edges.Count+1;
      SortEdges(Edges);
      for I:=1 to Edges.Count do begin
         Edge:=Edges[I-1];
         if I=1 then Points.Add(Edge.StartPoint);
      // if Edge.EndPoint<>Points[0] then Points.Add(Edge.EndPoint);
         Points.Add(Edge.EndPoint);
      end;
   end else Points:=nil;
end;

{$I FreeGeometry_File.inc}
{$I FreeGeometry_Build.inc}

//Var I:Integer=55;
//function RandomColor:TColor;
//begin Result:=RGB(90+(I*3) mod 165,90+(I*5) mod 165,90+(I*7) mod 165); I:=(I*11) mod 165; end;
//begin Result:=RGB(90+Random(165),90+Random(165),90+Random(165)); end;
procedure Register;
    begin RegisterComponents( 'FreeShip',[TFreeViewport] ); end;
// initialization Randomize;
end.

