unit ShipUnit;
interface uses // do WIndows-specific code here
     Forms,SysUtils, // this declaration must be at the start, before the Geometry unit
     Controls,LazFileUtils, //LazUTF8,
     Windows,iniFiles,Dialogs,Classes,
     Graphics,Geometry,FileBuffer,Matrices,
     FasterList,STypes,LanguageSupport,VersionUnit,ControlPointFrm;
  // free!Ship uses British imperial format, eg 1 long ton=2240 lbs
const ShipExtention='.ftm'; // Default extention for hull model files
      SelectDistance   = 3;     // Max. distance in pixels between an item and the cursor in order to be selected
      Threshold        = 3;     // The distance that the cursor has to be moved before a controlpoint starts moving
type  TShip= class;         // to be declared later
      TIntersection= class;
      THydrostaticCoeff= (fcProjectSettings,fcActualData);

HydrostaticsData = record
   ModelMin,ModelMax, // Min/max coordinates under given heelingangle and trim
   WlMin,WlMax,       // Min/max coordinates of the waterline
   SubMin,SubMax: Vector; // Min/max extents of the submerged body
   WaterlinePlane: Plate;
   AbsoluteDraft, // Depth of the lowest point of the hull beneath the waterplane
   // The following properties are always calculated
   Volume,Displacement: Real; // Displaced volume of the hull
   CenterOfBuoyancy: Vector; // Center of gravity of displaced volume
   LCBPerc,
   LengthWaterline,
   BeamWaterline,
   BlockCoefficient, // BlockCoefficient
   WettedSurface: Real;
   Leak: Vector; // Coordinate encountered where the St is making water
   Mainframearea: Real; // Mainframe properties
   MainFrameCOG,
   WaterplaneCOG,
   LateralCOG: Vector;
   MainframeCoeff,
   Waterplanearea,
   WaterplaneEntranceAngle, // Waterplane properties
   WaterplaneCoeff: Real;
   WaterplaneMomInertia: Place; // Stability data
   KMtransverse,
   KMlongitudinal, // Lateral area and center
   LateralArea,
   PrismCoefficient, // Prismatic coefficient
   VertPrismCoefficient: Real; // Sectional areas
   SAC: array of Place;
end;
{
   HydrostaticCalc is an object class for hydrostatic calculations.
   Each calculation has it's own draft, trim and angle of heel.
   Multiple calculations can be stored and then send to a report.
}
HydrostaticCalc = class
private
   FOwner       : TShip;        // Input data for each calculation
   FHeelingAngle: Real;
   FTrim        : Real;
   FDraft       : Real;             // Calculation flags
   FCalculated  : Boolean;
   FData        : HydrostaticsData; // The following data is calculated
   MidFrame     : TIntersection;
   function FGetTrimAngle:Real;
   function FGetWlPlane:Plate;
   procedure FSetCalculated(val:Boolean);
   procedure FSetDraft(Val:Real);
   procedure FSetHeelingAngle(Val:Real);
   procedure FSetTrim(Val:Real);
public
   constructor Create(Owner:TShip); virtual;
   destructor  Destroy; override;
   procedure   Clear;

   // Add calculated data to a stringlist to either show in a report or save to disc
   procedure   ShowData;                     // ( Mode:THydrostaticsMode );
   procedure   AddData(Strings:TStringlist); // Mode:THydrostaticsMode;Separator:char);
   procedure   AddHeader(Strings:TStringlist);
   Procedure   AddFooter(Strings:TStringlist); // Mode:THydrostaticsMode );
// function    Balance(Displacement:Real;ToTrim:Boolean;var Output:TCrosscurvesData):boolean;
   procedure   Calculate; // The actual calculation of the hydrostatics finds place in this procedure
   property    Calculated     : Boolean read FCalculated write FSetCalculated;
   property    Data           : HydrostaticsData read FData;
   property    Draft          : Real read FDraft write FSetDraft;
   property    HeelingAngle   : Real read FHeelingAngle write FSetHeelingAngle;
   property    Owner          : TShip read FOwner;
   property    Trim           : Real read FTrim write FSetTrim;
   property    TrimAngle      : Real read FGetTrimAngle;
   property    WaterlinePlane : Plate read FGetWlPlane;
end;
{
  TUndoObject is an object class for undoing actions.
  It's function is very basic, just before each modification the file
  is saved to a the undo object rather then to a file. When the undo is
  called, the previous state will be read from the undo object and restored
}
TUndoObject = class
private
// St: TShip;                 // локальное перекрытие внешненго имени - а надо?
   FUndoData: TTextBuffer;    // some other data to be stored
   FFileChanged,FFilenameSet,FIsTempRedoObject: Boolean;
   FUndoText,FFilename: String;
   FEditMode: TEditMode;
   FTime: TDateTime;
   function FGetMemory: integer; // calculates the amount of bytes used for each undo object
   function FGetTime: string;
   function FGetUndoText: string;
public
   procedure Accept;
   constructor Create(Owner:TShip);
   destructor Destroy; override;
   procedure Delete;
   procedure Restore;
   property Memory  : integer read FGetMemory; // calculates the amount of bytes used for each undo object
// property Owner   : TShip read FOwner;
   property Time    : String read FGetTime;
   property UndoData: TTextBuffer read FUndoData;
   property UndoText: string read FGetUndoText;
end;
{
   ship can import a max. of three different background images that
   may be coupled either to the bodyplan, profile or planview.
   These images can be used to trace the lines of an
   hullform and are stored within the free!Ship file.
}
TBackgroundImageData=class
private
   FOwner: Tship;
   FAssignedView: TViewType;
   FImageData: TJPEGImage;
   FQuality,FBlendingValue,FTolerance: Integer;
   FOrigin: TPoint;
   FScale: Real;
   FTransparent,FVisible: Boolean;
   FTransparentColor:TColor;
public
   procedure Clear;
   constructor Create(Owner:Tship);
   destructor Destroy; override;
   procedure LoadBinary(Source:TFileBuffer);
   procedure SaveBinary(Destination:TFileBuffer);
   procedure UpdateData(Viewport:TViewport);
   procedure UpdateViews;
   property AssignedView    : TViewType read FAssignedView;
   property BlendingValue   : Integer read FBlendingValue;
   property Image           : TJPEGImage read FImageData;
   property Origin          : TPoint read FOrigin;
   property Quality         : Integer read FQuality;
   property Scale           : Real read FScale;
   property Tolerance       : integer read FTolerance;
   property Transparent     : Boolean read FTransparent;
   property TransparentColor: TColor read FTransparentColor;
end;
{
    TIntersection is a list of curves calculated from the intersection
    of a St hull (represented by a subdivision surface) and a plane.
    This plane can be a orthogonal plane (eg. stations, waterlines,
    buttocks) or a ly oriented 3D plane (sent)
}
TIntersection = class
private
   FItems: TFasterList;
   FPlane: Plate;
   FBuilt: Boolean;
   function FGetColor: TColor;
   function FGetPlane: Plate;
   function FGetCount: integer;
   function FGetDescription: string;
   function FGetItem(Index:integer):TSpline;
   procedure FSetBuilt(Val:Boolean);
public
   St: TShip;
   ShowCurvature,
   UseHydrostaticsSurfacesOnly: boolean; // used for lateral area, mainframe and waterplane properties
   IntersectionType: TIntersectionType;
   constructor Create( Owner:TShip );
   destructor Destroy; override;
   procedure ReBuild;
   procedure Clear;
   procedure Add( Item:TSpline );
   procedure CalculateArea(Plane:Plate;var Area:Real;var COG:Vector;var MomentOfInertia:Place);
   procedure CreateStarboardPart; // Create the starboardhalf of the St, for use in hydrostatic calculations
   procedure Delete( Redraw:Boolean );
   procedure DeleteItem(Item:TSpline);
   procedure Draw(Viewport:TViewport);
   procedure DrawAll;
   procedure Extents(Var Min,Max:Vector);
   procedure LoadBinary(Source:TFileBuffer);
   procedure SaveToDXF(Strings:TStringList);
   procedure SaveBinary(Destination:TFileBuffer);
   property Built: Boolean read FBuilt write FSetBuilt;
   property Color: TColor read FGetColor;
   property Count: integer read FGetCount;
   property Description: string read FGetDescription;
   property Items[index:integer]: TSpline read FGetItem;
   property Plane: Plate read FGetPlane write FPlane;
end;
{
  TMarker
}
TMarker = class(TSpline)
private
   FVisible: Boolean;
   FOwner: TShip;
   function FGetSelected:Boolean;
   procedure FSetSelected(val:Boolean);
public
   procedure Clear; override;
   function  DistanceToCursor(X,Y:Integer;Viewport:TViewport):integer; override;
   procedure Delete;
   procedure Draw(Viewport:TViewport); override;
   procedure LoadBinary(Source:TFileBuffer); override;
   procedure SaveBinary(Destination:TFileBuffer); override;
   property Owner   : TShip read FOwner;
   property Selected: Boolean read FGetSelected write FSetSelected;
   property Visible : Boolean read FVisible write FVisible;
 end;
{
  Flowline
}
TFlowline = class
private
   FFlowLine: TSpline;
   FProjectionPoint: Place;
   FProjectionView: TViewType;
   FBuild: Boolean;
// FMethodNew:Boolean;
   function FGetColor:TColor;
   function FGetSelected:Boolean;
   function FGetVisible:Boolean;
   procedure FSetBuild(val:Boolean);
   procedure FSetSelected(val:Boolean);
public
   procedure Clear;
   constructor Create; //(Owner:TShip);
   procedure Delete;
   destructor Destroy; override;
   function  DistanceToCursor(X,Y:Integer;Viewport:TViewport):integer;
   procedure Draw(Viewport:TViewport);
   procedure LoadBinary(Source:TFileBuffer);
   procedure Rebuild;
   procedure SaveBinary(Destination:TFileBuffer);
   property Build   : Boolean read FBuild write FSetBuild;
   property Color   : TColor read FGetColor;
   property Selected: Boolean read FGetSelected write FSetSelected;
   property Visible : boolean read FGetvisible;
end;
{
  This object stores all visibility options for the hull
}
TVisibility = class(TPersistent)
private
   FOwner: TShip;
   FShowControlNet,
   FShowInteriorEdges,      // Show the surface edges
   FShowStations,           // Show the calculated stations
   FShowButtocks,           // Show the calculated Buttocks
   FShowWaterlines,         // Show the calculated Waterlines
   FShowDiagonals: Boolean; // Show the calculated Diagonals
   FModelView: TModelView; // Show half or entire St
   FShowNormals,               // Show normals of selected surface patches
   FShowGrid, // Show the grid of intersections in the plan,profile and bodyplan view
   FShowMarkers,
   FShowControlCurves,
   FShowCurvature,
   FShowHydrostaticData,
   FShowHydrostDisplacement,
   FShowHydrostLateralArea,
   FShowHydrostSectionalAreas,
   FShowHydrostMetacentricHeight,
   FShowHydrostLCF,
   FShowFlowlines: Boolean;
   FCursorIncrement: Real; // Distance added when the active controlpoint is moved withe the arrow keys
   procedure FSetCursorIncrement(val:Real);
   procedure FSetShowButtocks(Val:Boolean);
   procedure FSetShowControlNet(Val:Boolean);
   procedure FSetShowCurvature(Val:Boolean);
   procedure FSetShowDiagonals(Val:Boolean);
   procedure FSetShowFlowlines(Val:Boolean);
   procedure FSetShowGrid(Val:Boolean);
   procedure FSetModelView(Val:TModelView);
   procedure FSetShowInteriorEdges(Val:Boolean);
   procedure FSetShowMarkers(Val:Boolean);
   procedure FSetShowNormals(Val:Boolean);
   procedure FSetShowStations(Val:Boolean);
   procedure FSetShowWaterlines(Val:Boolean);
   procedure FSetShowControlCurves(Val:Boolean);
   procedure FSetShowHydrostaticData(Val:Boolean);
public
   constructor Create(Owner:TShip);
   procedure Clear;
   procedure SetCurvatureScale(Val:Real);
   procedure DecreaseCurvatureScale;
   procedure IncreaseCurvatureScale;
   procedure LoadBinary(Source:TFilebuffer);
   procedure SaveBinary(Destination:TFileBuffer);
   property  Owner: TShip read FOwner write FOwner;
published
   property CursorIncrement    : Real read FCursorIncrement write FSetCursorIncrement;
   property ModelView          : TModelView read FModelView write FSetModelView;
   property ShowButtocks       : boolean read FShowButtocks write FSetShowButtocks;
   property ShowControlCurves  : boolean read FShowControlCurves write FSetShowControlCurves;
   property ShowControlNet     : boolean read FShowControlNet write FSetShowControlNet;
   property ShowCurvature      : boolean read FShowCurvature write FSetShowCurvature;
   property ShowDiagonals      : boolean read FShowDiagonals write FSetShowDiagonals;
   property ShowFlowlines      : boolean read FShowFlowlines write FSetShowFlowlines;
   property ShowGrid           : boolean read FShowGrid write FSetShowGrid;
   property ShowHydrostaticData: boolean read FShowHydrostaticData write FSetShowHydrostaticData;
   property ShowInteriorEdges  : boolean read FShowInteriorEdges write FSetShowInteriorEdges;
   property ShowMarkers        : boolean read FShowMarkers write FSetShowMarkers;
   property ShowNormals        : boolean read FShowNormals write FSetShowNormals;
   property ShowStations       : boolean read FShowStations write FSetShowStations;
   property ShowWaterlines     : boolean read FShowWaterlines write FSetShowWaterlines;
end;

{ Container class for all editing commandsns for the hull }

SEdit = class { Ship: TShip; -=> St }
private
   FRecentFiles: TStringList;
   function FGetRecentFile(Index:integer):string;
   function FGetRecentFileCount:integer;
public St: TShip;
   constructor Create( Owner:TShip );
   destructor Destroy; override;
   procedure LineDrawing; // автоматическое формирование теоретических контуров
   procedure File_Export_Aurora_Experiments; // Теория корабля и штормовой вычислительный эксперимент
   procedure File_Load; overload; virtual; // Load a free!Ship file by showing an opendialog
   procedure File_Load(filename:string); reintroduce; overload; // Loads the given filename quietly
   function File_Save: Boolean;   // save as free!Ship file without prompting for a filename (must already been set)
   function File_SaveAs: Boolean; // Ask for filename and save as free!Ship file
   function File_SaveCheck:word;  // с запроосом необходимости -> mrOk,mrNo,mrCancel
   procedure Flowline_Add(Source:Place;View:TviewType);
   procedure AddToRecentFiles(Filename:String); // Takes a filename and adds it to the list with recent files
   procedure BackgroundImage_Delete(Viewport:TViewport); // Delete the backgrundimage associated with this view
   procedure BackgroundImage_Open(Viewport:TViewport); // browse for and open a backgroundimage
   function  CreateRedoObject:TUndoObject; // Creates redo data before an undo is done
   function  CreateUndoObject(UndoText:String;Accept:Boolean):TUndoObject; // Creates undodata just prior to modifications
   procedure Curve_Add;          // Add a new controlcurve
   procedure Edge_Collapse;      // Remove an edge by replacing the two connected faces by one controlface
   procedure Edge_Connecte;      // Create a new edge by connection two controlpoints belonging to the same controlface
   procedure Edge_Crease;        // Switch selected edges between normal or crease edges (knuckle lines)
   procedure Edge_Extrude;       // Create new controlfaces by extruding selected boundary edges (eg edges with only 1 controlface connected to it)
   procedure Edge_Split;         // Create new controlpoints by splitting an controledge into two.
   procedure Face_Assemble;
   procedure Face_DeleteNegative; // Deletes all faces on the starboardside of the hull
   procedure Face_Flip;          // Inverts the normal-direction of all selected controlfaces
   procedure Face_MirrorPlane;   // Mirrors all selected faces in a 3D plane
   procedure Face_New;           // Creates a new controlface from the currently selected controlpoints
   procedure Face_Rotate;        // Rotate selected faces around the X,Y and/or Z axis
   procedure Face_Scale;         // Scale selected faces
   procedure Face_Move;          // Move selected faces in X,Y and Z direction
   procedure File_ExportArchimedes; // Exports stations to Archimedes or ArchimedesMB
   procedure File_ExportCoordinates; // export the coordinates of all controlpoints to a textfile
   procedure File_ExportDXF_2DPolylines; // Export all intersections to an individual DXF file as 2D polylines
   procedure File_ExportDXF_3DPolylines; // Export all lines to a 3D DXF model as polylines
   procedure File_ExportDXF_Faces; // Export all faces to a 3D DXF model
   procedure File_ExportGHS;     // Save ordinates to the GHS file format
   procedure File_ExportPart;    // Save part of the geometry to a file
   procedure File_ExportIGES;    // Save NURBS patches to an IGES file
   procedure File_ImportObj;     // Import the model as a Wavefront Technologies.Obj file
   procedure File_ExportObj;     // Saves the model as a wavefront .Obj file
   procedure File_ExportOffsets; // Exports all intersections to a textfile as 3D points
   procedure File_ImportSTL;     // Imoprt the surface to a Standard Triangle STL file
   procedure File_ImportSTLbin( FileName: String );
   procedure File_ImportSTLtext( FileName: String );
   procedure File_ExportSTL;     // Export the surface to a STL file
   procedure File_ImportCarene;  // imports a Carene XYZ file and creates a multichine boat with developable surfaces
   procedure File_ImportHull; overload;virtual; // Imports a file created with Carlssons's Hulls program
   procedure File_ImportHull(Filename:string;Quiet:Boolean);reintroduce;overload; // Imports a file created with Carlssons's Hulls program
   procedure File_ImportPart;    // Import a partfile and add it to the current geometry
   procedure File_ImportPolycad; // Imports a PolyCad file
   procedure File_ImportSurface; // Imports a number of curves and fits a surface
   Procedure File_ImportVRML;    // Import a VRML 1.0 file
   function  Hydrostatics_Calculate(Draft,AngleOfHeel,Trim:Real):HydrostaticCalc;// Creates and calculates a hydrostatics calculation
   procedure ImportFrames;       // Loads a bodyplane and tries to fit a surface to it
   function  Intersection_Add(IntType:TIntersectionType;Distance:Real):TIntersection;// Add a new intersection at the specified location
   procedure Intersection_AddToList(Intersection:TIntersection); // Adds an intersection to the appropriate list
   procedure Intersection_Dialog; // Pops up the dialog in whcih to add or delete stations, buttocks and waterlines
   procedure Layer_AutoGroup;    // All connected patches surrounded by crease edges are grouped together into a new layer
   procedure Layer_Develop;      // Developes all developable layers
   procedure Layer_Dialog;       // Show layer dialog window
   procedure Layer_DeleteEmpty(Quiet:Boolean); // Delete all layers that are empty from the model
   function  Layer_New:SLayer; // Add a new empty layer
   procedure Marker_Add(Marker:TMarker); // Adds a marker to the list with markers
   procedure Marker_Delete;      // Delete all markers from the model
   procedure Marker_Import;      // Import markers from a textfile
   procedure Model_Check(ShowResult:Boolean); // Checks the surface for inconsistent normal directions and leaks
   function  Model_New:Boolean;  // Start a new model (with a predefined surface)
   procedure Model_LackenbyTransformation; // Affine hullform transformation according to Lackenby
   procedure Model_Scale(ScaleVector:Vector;OverrideLock,AdjustMarkers:Boolean); // Scale the entire model and all equivalent data such as stations etc.
   procedure Point_Collapse;     // Merge two selected edges by removing their common controlpoint.
   procedure Point_RemoveUnused; // removes any unused points from the model
   procedure Point_InsertPlane;  // Finds all intersection of VISIBLE edges and a 3D plane, and inserts a point on each of these edges
   procedure Point_IntersectLayer; // Calculates the intersection points of two layers
   procedure Point_Lock;       // Locks all selected points
   function  Point_New:SControlPoint; // Add a new point to the model with no edges/faces attached
   procedure Point_ProjectStraightLine; // Project all selected points onto a straight line through the first and last selected points
   procedure Point_Unlock;     // Unlocks all selected locked points
   procedure Point_UnlockAll;  // Unlocks all points
   function  ProceedWhenLockedPoints:Boolean; // Function that shows a warning when certain edit commands are invoked and the model contains locked points
   procedure Redo;             // Restores the state of the model as it was after the previous undone
   procedure Selection_Clear;  // Deselect all selected items at once
   procedure Selection_Delete; // Delete all selected items
   procedure Selection_SelectAll; // Select all visible items
   procedure Undo;             // Restores the state of the model as it was before the last modification
   procedure Undo_Clear;       // Clear the undo history
   procedure Undo_ShowHistory; // Show the undo history
   property  RecentFiles: TStringList read FRecentFiles;
   property  RecentFile[index:integer]: string read FGetRecentFile; // retrieve a filename from the recently used file list
   property  RecentFileCount: integer read FGetRecentFileCount; // The number of files in the recently used file list
end;
{
   Container class for all program settings TApplicationScope=(asMachine,asUser);
}
TPreferences=class(TPersistent)
private
  FViewportColor: TColor; // Half width of controlpoints
//  FIntersectionLineWidth, //  in pixels when drawn on screen Colors
//  FControlEdgeLineWidth,
//  FInteriorEdgeLineWidth,
//  FAuxEdgeLineWidth,
//  FHydrostaticLineWidth: integer;

  procedure FSetViewportColor( Val: TColor );
public
  St: TShip;
  MainForm: TForm;
  FbmEncoding, //encoding that is used to convert national strings from/to FBM files
  Language: String;
  ConfigDirectory,   // Default directory where users FreeShip.ini file is stored
  ManualsDirectory,  // Manuals directory
  OpenDirectory,     // Default directory to open existing files
  SaveDirectory,     // Default directory to save files
  ImportDirectory,   // Default directory to import files
  ExportDirectory,   // Default directory to export files
  LanguagesDirectory,// Default directory where Language files stored.
  LastDirectory,     // directory of last Open/Save
  LanguageFile: UTF8String; //UnicodeString;
  MaxUndoMemory,    // Max. amount of allowable undo memory in megabytes
  FontSize,PointSize: integer;
//  FInitDirectory,   // Default directory where ship.exe started
//  FUserDataDirectory,// Default directory where users Ship r/w data (projects etc) stored
//  FUserAppDataDirectory,// Default directory where users Ship programs and r/o resource files stored
//  function FullName( const N: String ): String; // --
  function OnlyName( const S: String; DS:boolean=true ): String; // имя внутри/вне директории
  procedure Clear;
  constructor Create(Owner: TShip);
  procedure Edit;
  procedure Load;
  procedure LoadFromIni;
  procedure ResetColors;
  procedure ResetDirectories;
  procedure SetDefaults;
  procedure Save;
published                                                  // General options
  property ViewportColor: TColor read FViewportColor write FSetViewportColor;
end;
{
   Container class for project settings for each projecttl
}
TProjectSettings=class
private
  FDisableModelCheck: boolean; // Disable the automatic checking of the surface
  FProjectAppendageCoefficient,
  FProjectBeam,FProjectDraft,FProjectLength,
  FProjectWaterDensity,FProjectWaterTemper: Real;
  FProjectName,FProjectDesigner,FProjectComment,FProjectFileCreatedBy: String;
  FProjectSimplifyIntersections,
  FSavePreview: boolean;
  FProjectUnits: TUnitType;
  FHydrostaticCoefficients: THydrostaticCoeff; // General hydrostatics calculation settings
  FStartDraft,FEndDraft,FDraftStep: Real;
  FTrim: Real;  // crosscurves settings
  FDisplacements: RealArray;
  FNoDisplacements: integer;
  FMinimumDisplacement,FMaximumDisplacement,FDisplIncrement: Real;
  FUseDisplIncrements: boolean;
  FNoAngles: integer;
  FAngles: RealArray;
  FNoStabTrims: integer;
  FStabTrims: RealArray;
  YesTrim: boolean;
  FVCG: Real;
  FUseMidleFrame: Boolean;
  FMidleFrame: Real;                   // заданная или полубсцисса миделя
  procedure FSetMidleFrame(Mid:Real); Function FGetMidleFrame:Real;
  procedure FSetUseMidleFrame(Mid:Boolean);
  procedure FSetDisableModelCheck(Val: boolean);
  procedure FSetHydrostaticCoefficients(val: THydrostaticCoeff);
  procedure FSetProjectAppendageCoefficient(Val: Real);
  procedure FSetProjectBeam(Val: Real);
  procedure FSetProjectDraft(Val: Real);
  procedure FSetProjectLength(Val: Real);
  procedure FSetProjectShadeUnderwaterShip(Val: boolean);
  procedure FSetProjectSimplifyIntersections(val: boolean);
  procedure FSetProjectUnits(Val: TUnitType);
  procedure FSetProjectWaterDensity(Val: Real);
  procedure FSetProjectWaterTemper(Val: Real);
  procedure FSetSavePreview(val: boolean);
  procedure FSetStartDraft(Val: Real);
  procedure FSetEndDraft(Val: Real);
  procedure FSetDraftStep(Val: Real);
  procedure FSetTrim(Val: Real);
public
  St: TShip;
  constructor Create( Owner: TShip );
  procedure Clear;
  procedure Edit;        // User input of mainparticulars and project setting
  procedure LoadBinary(Source: TFilebuffer; Image: TJPegImage); overload; virtual;
  procedure SaveBinary(Destination: TFileBuffer);
  property MidleFrame: Real read FGetMidleFrame write FSetMidleFrame;
  property UseMidleFrame: Boolean read FUseMidleFrame write FSetUseMidleFrame;
  property Hydrostatics_Startdraft: Real read FStartDraft write FSetStartDraft;
  property Hydrostatics_EndDraft: Real read FEndDraft write FSetEndDraft;
  property Hydrostatics_DraftStep:Real read FDraftStep write FSetDraftStep;
  property Hydrostatics_Trim: Real    read FTrim write FSetTrim;
  property DisableModelCheck: boolean read FDisableModelCheck write FSetDisableModelCheck;
  property ProjectAppendageCoefficient: Real read FProjectAppendageCoefficient write FSetProjectAppendageCoefficient;
  property ProjectBeam: Real read FProjectBeam write FSetProjectBeam;
  property ProjectCoefficients: THydrostaticCoeff read FHydrostaticCoefficients write FSetHydrostaticCoefficients;
  property ProjectDraft: Real read FProjectDraft write FSetProjectDraft;
  property ProjectLength: Real read FProjectLength write FSetProjectLength;
  property ProjectName: String read FProjectName;         // write FSetProjectName;
  property ProjectDesigner: String read FProjectDesigner; // write FSetProjectDesigner;
  property ProjectComment: String read FProjectComment;   // write FSetProjectComment;
  property ProjectFileCreatedBy: String read FProjectFileCreatedBy; // write FSetProjectFileCreatedBy;
  property ProjectSimplifyIntersections: boolean read FProjectSimplifyIntersections write FSetProjectSimplifyIntersections;
  property ProjectUnits: TUnitType read FProjectUnits write FSetProjectUnits;
  property ProjectWaterDensity: Real read FProjectWaterDensity write FSetProjectWaterDensity;
  property ProjectWaterTemper: Real read FProjectWaterTemper write FSetProjectWaterTemper;
  property SavePreview: boolean read FSavePreview write FSetSavePreview;
end;
{
   TShip is the actual component used for modelling and representing the St
}
TShip = class(TComponent)
private
   FViewports,    // List containing all viewports associated with the hullform
   FStations,
   FButtocks,
   FWaterlines,
   FDiagonals,
   FMarkers,
   FBackgroundImages,
   FFlowLines,
   FSelectedFlowlines,
   FSelectedMarkers   : TFasterList;
   FPrecision         : TPrecisionType;
   FFileVersion       : TFileVersion;
   FEditMode          : TEditMode; // The component has different edit-modes which determine how the program responds to mouse-events
   FPreferences       : TPreferences;
   FActiveControlPoint: SControlPoint; // The last selected controlpoint (still selected)
   FFileChanged       : boolean;   // Flag to keep track of modifications to the file
   FSurface           : SSurface;
   FFilename          : string;    // Filename of the current project;
   FEdit              : SEdit;     // Containerclass for all editing commands
   FVisibility        : TVisibility;
   FFilenameSet,      // Flag to determine if the filename already has been set
   FCurrentlyMoving,  // variables are for moving controlpoints with the mouse
   FPointHasBeenMoved      : boolean;
   FPrevCursorPosition     : TPoint;
   FControlpointForm       : TControlPointForm; // form for manual adjustment of controlpoints
   FIntersectionDialog     : TForm; // Dialog containing intersectionlines
   FProjectSettings        : TProjectSettings;
   FHydrostaticCalculations: TFasterList; // List containing all hydrostatic calculations
   FUndoObjects            : TFasterList;
   FUndoPosition,FPreviousUndoPosition: Integer; // Index of the current undo object
   FOnFileChanged,
   FOnUpdateUndoData,
   FOnUpdateRecentFileList,
   FOnChangeCursorIncrement,
   FOnUpdateGeometryInfo: TNotifyEvent; // This event is raised whenever items are added or deleted from the surface

   // Assembles all stations and builds a 2D bodyplan for export to other calculating programs
   procedure FBuildValidFrameTable(Destination:TFasterList;CloseAtDeck:Boolean);
   function  FGetActiveLayer:Slayer;
   function  FGetBackgroundImage(Index:Integer):TBackgroundImageData;
   function  FGetBuild:Boolean;
   function  FGetButtock(Index:integer):TIntersection;
   function  FGetControlCurve(Index:integer):SControlCurve;
   function  FGetDiagonal(Index:integer):TIntersection;
   function  FGetFlowline(Index:integer):TFlowline;
   function  FGetFilename:string;
   function  FGetHydrostaticCalculation(Index:integer):HydrostaticCalc;
   function  FGetNoLayers:integer;
   function  FGetLayer(Index:integer):SLayer;
   function  FGetMarker(Index:integer):TMarker;
   function  FGetNoBackgroundImages:Integer;
   function  FGetNoButtocks:integer;
   function  FGetNoControlCurves:integer;
   function  FGetNoDiagonals:integer;
   function  FGetNoFlowLines:Integer;
   function  FGetNoHydrostaticCalculations:integer;
   function  FGetNoLockedPoints:Integer;
   function  FGetNoMarkers:integer;
   function  FGetNoStations:integer;
   function  FGetNoViewports:integer;
   function  FGetNoWaterlines:integer;
   function  FGetOnChangeActiveLayer:TChangeActiveLayerEvent;
   function  FGetOnChangeLayerData:TNotifyEvent;
   function  FGetOnSelectItem:TNotifyEvent;
   function  FGetSelectedControlPoint(Index:integer):SControlPoint;
   function  FGetSelectedControlEdge(Index:integer):SControlEdge;
   function  FGetSelectedControlCurve(Index:integer):SControlCurve;
   function  FGetSelectedControlFace(Index:integer):SControlFace;
   function  FGetSelectedFlowline(index:Integer):TFlowline;
   function  FGetSelectedMarker(index:Integer):TMarker;
   function  FGetStation(Index:integer):TIntersection;
   function  FGetUndoCount:integer;
   function  FGetUndoMemory:integer;
   function  FGetUndoObject(Index:integer):TUndoObject;
   function  FGetViewport(Index:integer):TViewport;
   function  FGetWaterline(Index:integer):TIntersection;
   procedure FSetActiveControlPoint(Val:SControlPoint);
   procedure FSetActiveLayer(Val:SLayer);
   procedure FSetBuild(Val:Boolean);
   procedure FSetEditMode(Val:TEditMode);
   procedure FSetFileChanged(Val:Boolean);
   procedure FSetFileName(Val:string);
   procedure FSetFileVersion(Val:TFileVersion);
   function  FGetNoSelectedControlCurves:integer;
   function  FGetNoSelectedControlEdges:integer;
   function  FGetNoSelectedControlFaces:integer;
   function  FGetNoSelectedControlPoints:integer;
   function  FGetNoselectedFlowlines:Integer;
   function  FGetNoSelectedLockedPoints:integer;
   function  FGetNoselectedMarkers:Integer;
   procedure FSetOnChangeActiveLayer(val:TChangeActiveLayerEvent);
   procedure FSetOnChangeLayerData(Val:TNotifyEvent);
   procedure FSetOnSelectItem(Val:TNotifyEvent);
   procedure FSetPrecision(Val:TPrecisionType);
   function  FGetPreview:TJPEGImage;
public
   FDesignHydrostatics: HydrostaticCalc; // This object calculates hydrostatic data to draw in the viewports
   constructor Create( AOwner: TComponent ); override;
   destructor Destroy; override;
   procedure Clear;
   procedure Draw;
   procedure Redraw; // Redraws the model on all viewports
// function  DetectMinFileVersion( isText: boolean ): TFileVersion; ~ в запись только 2.6
   procedure AddViewport(Viewport:TViewport); // Add a viewport to the list of viewports connected to the model
   function  AdjustMarkers:Boolean;
   procedure ClearUndo;
   procedure DeleteViewport(Viewport:TViewport); // Delete a viewport from the list of viewports connected to the model
   procedure DrawToViewport(Viewport:TViewport);
   procedure Extents(Var Min,Max:Vector); // calculate the bounding box coordinates of the model
(*#*) procedure ZoomFitAllViewports;         // <=> HullformWindow
   function  FindLowestHydrostaticsPoint:Real;
   procedure ImportChines(Np:Integer;Chines:TFasterList); // imports a number of longitudinally lines and creates developable surfaces between each two subsequent chines
   Procedure LoadProject(Source:TFileBuffer);
// Procedure LoadBinary(Source:TFileBuffer);
// procedure LoadPreview(Filename:string;Image:TJPegImage); // loads the preview image from a file
   procedure RebuildModel;                                  // Force to rebuild the entire St and recalculate all data
   Procedure SaveProject( Destination:TFileBuffer );
//#Procedure SaveBinary(Destination:TFileBuffer);
   procedure SavePart(Faces:TFasterList);
   procedure SubmergedHullExtents(Wlplane:Plate;var Min,Max:Vector);
   procedure KeyUp(Viewport:TViewport;var Key: Word;Shift: TShiftState);
   procedure MouseDown(Viewport:TViewport;Button:TMouseButton;Shift:TShiftState;X,Y:integer;var ItemSelected:Boolean);
   procedure MouseMove(Viewport:TViewport;Shift:TShiftState;X,Y:integer);
   procedure MouseUp(Viewport:TViewport;Shift:TShiftState;X,Y:integer);
   procedure SelectPointsInFrame( Viewport: TViewport; rect: TRect );

   property  nV: integer read FGetNoViewports;
   property  ActiveControlPoint             : SControlPoint read FActiveControlPoint write FSetActiveControlPoint;
   property  ActiveLayer                    : SLayer read FGetActiveLayer write FSetActiveLayer;
   property  BackgroundImage[index:Integer] : TBackgroundImageData read FGetBackgroundImage;
   property  Build                          : Boolean read FGetBuild write FSetBuild;
   property  Buttock[index:integer]         : TIntersection read FGetButtock;
   property  ControlCurve[index:integer]    : SControlCurve read FGetControlCurve;
   property  ControlpointForm               : TControlPointForm read FControlpointForm; // Pointer to form for manual adjustment of controlpoints
   property  Diagonal[index:integer]        : TIntersection read FGetDiagonal;
   property  Edit                           : SEdit read FEdit; // Containerclass for all editing commands
   property  EditMode                       : TEditMode read FEditMode write FSetEditMode;
   property  FilenameSet                    : boolean read FFilenameSet write FFilenameSet;
   property  Flowline[index:integer]        : TFlowline read FGetFlowline;
   property  HydrostaticCalculation[index:integer]: HydrostaticCalc read FGetHydrostaticCalculation;
   property  Layer[index:integer]           : SLayer read FGetLayer;
   property  Marker[index:integer]          : TMarker read FGetMarker;
   property  NoBackgroundImages             : integer read FGetNoBackgroundImages;
   property  NoButtocks                     : integer read FGetNoButtocks;
   property  NoControlCurves                : integer read FGetNoControlCurves;
   property  NoDiagonals                    : integer read FGetNoDiagonals;
   property  NoHydrostaticCalculations      : integer read FGetNoHydrostaticCalculations;
   property  NoLayers                       : integer read FGetNoLayers;
   property  NoLockedPoints                 : integer read FGetNoLockedPoints;
   property  NoMarkers                      : integer read FGetNoMarkers;
   property  NoFlowLines                    : integer read FGetNoFlowLines;
   property  NoSelectedControlCurves        : integer read FGetNoSelectedControlCurves;
   property  NoSelectedControlEdges         : integer read FGetNoSelectedControlEdges;
   property  NoSelectedControlFaces         : integer read FGetNoSelectedControlFaces;
   property  NoSelectedControlPoints        : integer read FGetNoSelectedControlPoints;
   property  NoselectedFlowlines            : integer read FGetNoselectedFlowlines;
   property  NoSelectedLockedPoints         : integer read FGetNoSelectedLockedPoints;
   property  NoselectedMarkers              : integer read FGetNoselectedMarkers;
   property  NoStations                     : integer read FGetNoStations;
   property  NoWaterlines                   : integer read FGetNoWaterlines;
   property  OnChangeActiveLayer            : TChangeActiveLayerEvent read FGetOnChangeActiveLayer write FSetOnChangeActiveLayer;
   property  OnChangeLayerData              : TNotifyEvent read FGetOnChangeLayerData write FSetOnChangeLayerData;
   property  OnSelectItem                   : TNotifyEvent read FGetOnSelectItem write FSetOnSelectItem;
   property  SelectedControlCurve[index:integer]: SControlCurve read FGetSelectedControlCurve;
   property  SelectedControlPoint[index:integer]: SControlPoint read FGetSelectedControlPoint;
   property  SelectedControlEdge[index:integer] : SControlEdge read FGetSelectedControlEdge;
   property  SelectedControlFace[index:integer] : SControlFace read FGetSelectedControlFace;
   property  SelectedFlowline[index:integer]    : TFlowline read FGetSelectedFlowline;
   property  SelectedMarker[index:integer]      : TMarker read FGetSelectedMarker;
   property  Station[index:integer]             : TIntersection read FGetStation;
   property  UndoCount                : integer read FGetUndoCount;
   property  UndoMemory               : integer read FGetUndoMemory; // amount of memory used by all undoobjects
   property  UndoObject[index:integer]: TUndoObject read FGetUndoObject;
   property  UndoPosition             : integer read FUndoPosition;
   property  Viewport[index:integer]  : TViewport read FGetViewport;
   property  Waterline[index:integer] : TIntersection read FGetWaterline;
   property  Surface                  : SSurface read FSurface;
published
   property  FileChanged            : boolean read FFileChanged write FSetFileChanged;
   property  Filename               : string read FGetFilename write FSetFileName;
   property  FileVersion            : TFileVersion read FFileVersion write FSetFileVersion;
   property  OnChangeCursorIncrement: TNotifyEvent read FOnChangeCursorIncrement write FOnChangeCursorIncrement;
   property  OnFileChanged          : TNotifyEvent read FOnFileChanged write FOnFileChanged;
   property  OnUpdateGeometryInfo   : TNotifyEvent read FOnUpdateGeometryInfo write FOnUpdateGeometryInfo;
   property  OnUpdateRecentFileList : TNotifyEvent read FOnUpdateRecentFileList write FOnUpdateRecentFileList;
   property  OnUpdateUndoData       : TNotifyEvent read FOnUpdateUndoData write FOnUpdateUndoData;
   property  Precision              : TPrecisionType read FPrecision write FSetPrecision;
   property  Preferences            : TPreferences read FPreferences;
   property  ProjectSettings        : TProjectSettings read FProjectSettings;
   property  Visibility             : TVisibility read FVisibility;
 end;

TColorIniFile=class( TIniFile )
public
   function ReadColor(const Section,Ident: String; Default: TColor): TColor; virtual;
   procedure WriteColor(const Section,Ident: String; Value: TColor); virtual;
end;

// function to find the corresponding water viscosity based on the density
function FindWaterViscosity(Density:Real;Units:TUnitType):Real;

procedure Register;
Var St: TShip;

implementation
uses Math,
     Main,
     IGESUnit,
     IntersectionDlg,
     NewModelDlg,
     ExtrudeDlg,
     ProjectSettingsDlg,
     RotateDlg,
     PreferencesDlg,
     ExpanedPlatesDlg,
     LinesplanFrme,
     InsertPlaneDlg,
     SelectLayersDlg,
     MirrorPlaneDlg,
     DDXFExportDlg,
     LackenbyDlg,
     IntersectLayerDlg,
     UndoHistoryDlg,
     LayerDlg,
     HydrostaticsDlg;

// function to find the corresponding water viscosity based on the density
function FindWaterViscosity(Density:Real;Units:TUnitType):Real;
var TmpDensity:Real;
begin
   if Units=fuMetric then begin
      Result:=1.13902+((Density-0.999)/(1.0259-0.999))*(1.18831-1.13902);
   end else begin                                          // convert to metric
     TmpDensity:=Density/WeightConversionFactor;
     Result:=1.13902+((TmpDensity-0.999)/(1.0259-0.999))*(1.18831-1.13902);
     Result:=Result/(Foot*Foot);
   end;
end;
{
   TUndoObject is an object class for undoing actions.
   It's function is very basic, just before each modification the file is saved to a the
   undo object rather then to a file. When the undo is called, the previous state will be
   read from the undo object and restored
}
// calculates the amount of bytes used for each undo object
function TUndoObject.FGetMemory:integer;
begin
   Result:=sizeof( pointer ) + // pointer to self  =4
           sizeof( pointer ) + // pointer to owner =4
           length(Undotext ) + // length of string
           length(FFilename) + // length of filename string
           FUndoData.Count;    // Actual saved data
end;

function TUndoObject.FGetTime:string;
   begin Result:=TimeToStr(FTime); end;
function TUndoObject.FGetUndoText:string;
   begin Result:=FUndoText; end;

procedure TUndoObject.Accept;
  var I:Integer; Obj:TUndoObject;
begin // Add the undo data to the undolist
   if St.UndoCount>0 then
   if St.UndoObject[St.UndoCount-1].FIsTempRedoObject then
      St.UndoObject[St.UndoCount-1].Delete;
                               // delete all undo objects after the current one
   for I:=St.FUndoObjects.Count downto St.FUndoPosition+1 do // ?? и зачем ??
          St.UndoObject[I-1].Delete;
   St.FUndoObjects.Add(self);
   St.FUndoPosition:=St.FUndoObjects.Count;
   while (St.UndoMemory/(1024*1024)>St.Preferences.MaxUndoMemory)
     and (St.FUndoObjects.Count>2) do begin
      Obj:=St.FUndoObjects[0];
      Obj.Destroy;
      St.FUndoObjects.Delete(0);
      Dec(St.FUndoPosition);
      Dec(St.FPreviousUndoPosition);
   end;
   if Assigned(St.FOnUpdateUndoData) then St.FOnUpdateUndoData(St);
end;
constructor TUndoObject.Create( Owner:TShip );
begin
   inherited Create;
   FTime:=Now;
//   St:=Owner;
   FUndoText:='';
   FFilename:='';
   FUndoData:=TTextBuffer.Create;
   FIsTempRedoObject:=False;
end;
procedure TUndoObject.Delete;           // deletes an undo object from the list
var Index:integer;
begin
   Index:=St.FUndoObjects.IndexOf( self );
   if Index<>-1 then St.FUndoObjects.Delete(Index);
   if Assigned(St.FOnUpdateUndoData) then St.FOnUpdateUndoData(St);
   Destroy;
end;

destructor TUndoObject.Destroy;
     begin FUndoData.Destroy; Inherited Destroy; end;

procedure TUndoObject.Restore;
begin With St do begin
   LoadProject(FUndoData);
   FFileChanged:=FFileChanged;
   FFilename:=FFilename;
   FEditMode:=FEditMode;
   FFilenameSet:=FFilenameSet;
   Redraw;
end end;
{
  ship can import a max. of three different background images that may be
  coupled either to the bodyplan, profile or planview. These images can be
  used to trace the lines of an hullform and are stored within the free!Ship file
}
procedure TBackgroundImageData.Clear;
begin
   FAssignedView:=fvPerspective;
   FImageData.Free;
   FImageData:=TJPEGImage.Create;
   FQuality:=100;
   FOrigin.X:=0;
   FOrigin.Y:=0;
   FScale:=10;
   FBlendingValue:=255;
   FTransparent:=False;
   FTransparentColor:=clBlack;
   FVisible:=True;
   FTolerance:=3;
end;

constructor TBackgroundImageData.Create(Owner:Tship);
begin
   Inherited Create;
   FOwner:=Owner;
   FImageData:=TJPEGImage.Create;
end;

destructor TBackgroundImageData.Destroy;
begin
   Clear;
   FImageData.Destroy;
   Inherited Destroy;
end;

procedure TBackgroundImageData.LoadBinary(Source:TFileBuffer);
var I:Integer;
begin
   Source.LoadInteger(I);
   FAssignedView:=TViewType(I);
   Source.LoadBoolean(FVisible);
   Source.LoadInteger(FQuality);
   Source.LoadInteger(FOrigin.X);
   Source.LoadInteger(FOrigin.Y);
   Source.LoadTFloatType(FScale);
   Source.LoadInteger(FBlendingValue);
   Source.LoadBoolean(FTransparent);
   Source.LoadInteger(FTransparentColor);
   Source.LoadInteger(FTolerance);
   Source.LoadTJpegImage(FImageData);
end;

procedure TBackgroundImageData.SaveBinary(Destination:TFileBuffer);
begin
   destination.Add(Ord(AssignedView));
   Destination.Add(FVisible);
   Destination.Add(FQuality);
   Destination.Add(FOrigin.X);
   Destination.Add(FOrigin.Y);
   Destination.Add(FScale);
   Destination.Add(FBlendingValue);
   Destination.Add(FTransparent);
   Destination.Add(FTransparentColor);
   Destination.Add(FTolerance);
   FImageData.CompressionQuality:=FQuality;
   Destination.Add(FImageData);
end;

procedure TBackgroundImageData.UpdateData(Viewport:TViewport);
var I:Integer;
begin
   FOrigin:=Viewport.BackgroundImage.Origin;
   FScale:=Viewport.BackgroundImage.Scale;
   FTransparent:=Viewport.BackgroundImage.Transparent;
   FBlendingValue:=Viewport.BackgroundImage.Alpha;
   FTransparentColor:=Viewport.BackgroundImage.TransparentColor;
   FTolerance:=Viewport.BackgroundImage.Tolerance;
   for I:=1 to FOwner.nV do
    if (FOwner.Viewport[I-1]<>Viewport)
     and (FOwner.Viewport[I-1].ViewType=AssignedView)
   then begin
      FOwner.Viewport[I-1].BackgroundImage.AssignData(FImageData,AssignedView,FOrigin,FScale,FTransparent,FTransparentColor,FBlendingValue,FQuality,Ftolerance,False);
   end;
   FOwner.FileChanged:=True;
end;

procedure TBackgroundImageData.UpdateViews;
var I:Integer;
begin
   for I:=1 to FOwner.nV do
   if FOwner.Viewport[I-1].Viewtype=AssignedView then begin
      FOwner.Viewport[I-1].BackgroundImage.AssignData(FImageData,AssignedView,FOrigin,FScale,FTransparent,FTransparentColor,FBlendingValue,FQuality,FTolerance,False);
   end;
end;
{
   TIntersection is a list of curves calculated from the intersection
   of a St hull (represented by a subdivision surface) and a plane.
   This plane can be a orthogonal plane (eg. stations, waterlines, buttocks)
   or a ly oriented 3D plane (sent)
}
procedure TIntersection.DeleteItem(Item:TSpline);
var Index:integer;
begin
   Index:=FItems.IndexOf(Item);
   if Index<>-1 then FItems.Delete(index);
   Item.Destroy;
end;
function TIntersection.FGetColor:TColor;
begin
   with St do
   Case IntersectionType of
      fiStation  : Result:=Sp.Station;
      fiButtock  : Result:=Sp.Buttock;
      fiWaterline: Result:=Sp.Waterline;
      fiDiagonal : Result:=Sp.Diagonal;
              else Result:=clWhite;
   end;
end;
function TIntersection.FGetPlane:Plate;
   begin Result:=FPlane; end;
function TIntersection.FGetCount:integer;
   begin if self=nil then result:=0
                     else Result:=FItems.Count;
   end;
function TIntersection.FGetDescription:string;
begin
   Case IntersectionType of
      fiStation  : Result:=Userstring(58);
      fiButtock  : Result:=Userstring(59);
      fiWaterline: Result:=Userstring(60);
      fiDiagonal : Result:=Userstring(61);
              else Result:='';
   end;
   if IntersectionType=fiDiagonal
      then Result:=Result+#32+FloatToDec( -FPLane.d/FPlane.c,3 )
      else Result:=Result+#32+FloatToDec( -FPLane.d,3 );
end;

function TIntersection.FGetItem(Index:integer):TSpline;
   begin Result:=FItems.Items[Index]; end;

procedure TIntersection.FSetBuilt(Val:Boolean);
var I: integer;
begin
   if not Val then begin
      for I:=1 to Count do Items[I-1].Destroy;
      FItems.Clear;
   end;
   FBuilt:=Val;
end;
procedure TIntersection.Add(Item:TSpline);
    begin FItems.Add(Item); end;

procedure TIntersection.CalculateArea(Plane:Plate;var Area:Real;var COG:Vector;var MomentOfInertia:Place);
var I: Integer; TmpArea: Real; TmpCOG,MomI: Vector;
   procedure CalculateSplineArea
   ( Spline:TSpline;var SplineArea:Real;Var SplineCOG,MomInertia:Vector );
   var ClosedSpline: Boolean;
       IntersectionData: TIntersectionData;
       Parameters: RealArray;
       I,J,NoPoints: Integer;
       T1,T2,T,Side,DeltaA: Real;
       P: Vector;
       P1,P2,C,MomI: Place;
       function ProjectTo2D(P:Vector):Place;
       begin
          Case IntersectionType of
             fiStation:   begin Result.X:=P.Y; Result.Y:=P.Z; end;
             fiButtock:   begin Result.X:=P.X; Result.Y:=P.Z; end;
             fiWaterline: begin Result.X:=P.X; Result.Y:=P.Y; end;
                     else begin Result.X:=0.0; Result.Y:=0.0; end;
          end;
       end;
   begin
      SplineArea:=0.0;
      SplineCOG:=ZERO;
      MomInertia:=ZERO;
      C.X:=0.0;
      C.Y:=0.0;
      MomI:=C;
      ClosedSpline:=Abs(Spline.Point[0]-Spline.Point[Spline.nS-1])<1e-4;
      if not ClosedSpline then begin                          // make it closed
         Spline.Add(Spline.Point[0]);
         Spline.Knuckle[Spline.nS-2]:=True;
      end;
      Spline.Fragments:=500;
      NoPoints:=2;
      Setlength(Parameters,2);
      Parameters[0]:=0.0;
      Parameters[1]:=1.0;
      if IntersectionType<>fiWaterline then
      if Spline.IntersectPlane(Plane,IntersectionData) then begin
         Setlength(Parameters,NoPoints+Intersectiondata.NoIntersections);
         for I:=1 to Intersectiondata.NoIntersections do begin
            Parameters[NoPoints]:=Intersectiondata.Parameters[I-1];
            Inc(NoPoints);
         end;
      end;
      ArraySort( Parameters,NoPoints );
      if NoPoints>0 then begin
         T1:=0.0;
         for I:=2 to NoPoints do begin
            T2:=Parameters[I-1];
            T:=0.5*(T1+T2);
            P:=Spline.Value(T);
            // check on which side of the plane this point is
            Side:=Plane.a*P.x+Plane.b*P.y+Plane.c*P.z+Plane.d;
            if (Side<0) or (IntersectionType=fiWaterline) then begin
               // The point lies at the back of the plane, include this area
               for J:=0 to 500 do begin                 // Р1 - пропускается
                  T:=T1+(J/500)*(T2-T1);
                  P:=Spline.Value(T);
                  P2:=ProjectTo2D(P);
                  if J>0 then begin
                     DeltaA:=0.5*(P2.X+P1.X)*(P2.Y-P1.Y);
                     SplineArea:=SplineArea+DeltaA;
                     C.X:=C.X+DeltaA*0.25*(P2.X+P1.X);
                     C.Y:=C.Y+DeltaA*0.50*(P2.Y+P1.Y);
                     MomI.X:=MomI.X+(1.0/12.0)*(P1.Y+P2.Y)*(P1.Y*P1.Y+P2.Y*P2.Y)*(P2.X-P1.X);
                     MomI.Y:=MomI.Y+(1.0/12.0)*(P2.X*P2.X*(3*P2.Y+P1.Y)+2*P1.X*P2.X*(P1.Y+P2.Y)+P1.X*P1.X*(3*P1.Y+P2.Y))*(P2.X-P1.X);
                  end; P1:=P2;
               end;
            end;       T1:=T2;
         end;
         if SplineArea<>0.0 then begin
            C.X:=C.X/SplineArea;
            C.Y:=C.Y/SplineArea;
            MomI.X:=abs(MomI.X);
            MomI.Y:=abs(MomI.Y);
            Case IntersectionType of
               fiStation: begin
                 SplineCOG.X:=-FPlane.d;
                 SplineCOG.Y:=C.X;
                 SplineCOG.Z:=C.Y;
                 MomInertia.X:=0;
                 MomInertia.Y:=MomI.X;
                 MomInertia.Z:=MomI.Y; end;
               fiButtock: begin
                 SplineCOG.X:=C.X;
                 SplineCOG.Y:=-FPlane.d;
                 SplineCOG.Z:=C.Y;
                 MomInertia.X:=MomI.X;
                 MomInertia.Z:=MomI.Y;
                 MomInertia.Y:=0; end;
               fiWaterline: begin
                 SplineCOG.X:=C.X;
                 SplineCOG.Y:=C.Y;
                 SplineCOG.Z:=-FPlane.d;
                 MomInertia.X:=MomI.X;
                 MomInertia.Y:=MomI.Y;
                 MomInertia.Z:=0; end;
            end;
         end;
      end;
   end;
begin
   Area:=0.0;
   COG:=ZERO;
   MomentOfInertia.X:=0;
   MomentOfInertia.Y:=0;
   if not Built then Rebuild;
   if Count>0 then begin
      CreateStarboardPart; // This also ensures coreect winding order
      for I:=1 to Count do begin
         CalculateSplineArea(Items[I-1],TmpArea,TmpCOG,MomI);
         Area:=Area+TmpArea;
         COG+=TmpArea*TmpCOG;
      end;
      if Area<>0.0 then begin COG/=Area;
         if IntersectionType=fiWaterline then begin
            MomentOfInertia.X:=MomI.X-COG.Y*COG.Y*Area;
            MomentOfInertia.Y:=MomI.Y-COG.X*COG.X*Area;
         end;
      end;
   end;
   if (Count=0) or (Area=0) then begin COG:=ZERO;
      Case IntersectionType of
           fiStation  : COG.X:=-FPlane.d;
           fiButtock  : COG.Y:=-FPlane.d;
           fiWaterline: COG.Z:=-FPlane.d;
      end;
   end;
end;

procedure TIntersection.Clear;
var I : integer;
begin
   for I:=1 to Count do Items[I-1].Destroy;
   FItems.Clear;
   FBuilt:=False;
   ShowCurvature:=False;
   UseHydrostaticsSurfacesOnly:=False
end;

constructor TIntersection.Create(Owner:TShip);
      begin inherited Create; St:=Owner; FItems:=TFasterList.Create; Clear;
      end;

// Create the starboardhalf of the St, for use in hydrostatic calculations

procedure TIntersection.CreateStarboardPart;
var I,J: integer; Spline: TSpline; P1,P2: Vector; Area,DeltaA: Real;
begin                  // Copy all present splines and mirror the y-coordinate
   if self.IntersectionType<>fiButtock then begin
      FItems.Capacity:=FItems.Count*2;
      for I:=Count downto 1 do begin
         Spline:=TSpline.Create;
         Spline.Assign(Items[I-1]);
         for J:=1 to Spline.nS do begin
            P1:=Spline.Point[J-1];
            P1.Y:=-P1.Y;
            Spline.Point[J-1]:=P1;
         end;
         FItems.Add(Spline);
      end;                                        // Try to connect the splines
      JoinSplineSegments(0.05,False,FItems);
   end;                         // Check if the orientation is counterclockwise
   for I:=Count downto 1 do begin
      Spline:=Items[I-1];
      Area:=0; DeltaA:=0;
      P1:=Spline.Point[Spline.nS-1];
      for J:=0 to 500 do begin
         P2:=Spline.Value(J/500);
         Case IntersectionType of
            fiStation  : DeltaA:=0.5*(P2.Y+P1.Y)*(P2.Z-P1.Z);
            fiButtock  : DeltaA:=0.5*(P2.X+P1.X)*(P2.Z-P1.Z);
            fiWaterline: DeltaA:=0.5*(P2.X+P1.X)*(P2.Y-P1.Y);
         // else Raise exception.Create(Userstring(66)+'!');
         end;
         Area:=Area+DeltaA;
         P1:=P2;
      end;
      if (abs(Area)<1e-4) and (Count>0) then begin
         // Either this spline has a very small area(0.01m x 0.01m) or it is an unconnected
         // straight line. In both cases it may be deleted as long as at least one valid
         // spline segment remains.
         Spline.Destroy;
         FItems.Delete(I-1);
      end else
      if Area<0 then begin // spline is defined clockwise, so invert the controlpoints
         Spline.InvertDirection;
      end;
   end;
end;

procedure TIntersection.Delete;
var Index : integer;
begin
   Case IntersectionType of
      fiStation : begin
         Index:=St.FStations.IndexOf(self);
         if Index<>-1 then begin
            St.FStations.Delete(Index);
            St.FileChanged:=True;
            if Redraw then St.Redraw;
            Destroy;
         end end;
      fiButtock : begin
         Index:=St.FButtocks.IndexOf(self);
         if Index<>-1 then begin
            St.FButtocks.Delete(Index);
            St.FileChanged:=True;
            if Redraw then St.Redraw;
            Destroy;
         end end;
      fiWaterline: begin
         Index:=St.FWaterlines.IndexOf(self);
         if Index<>-1 then begin
            St.FWaterlines.Delete(Index);
            St.FileChanged:=True;
            if Redraw then St.Redraw;
            Destroy;
         end end;
      fiDiagonal : begin
         Index:=St.FDiagonals.IndexOf(self);
         if Index<>-1 then begin
            St.FDiagonals.Delete(Index);
            St.FileChanged:=True;
            if Redraw then St.Redraw;
            Destroy;
         end end;
   end;
end;

destructor TIntersection.Destroy;
begin
   Clear;
   FItems.Destroy;
   Inherited Destroy;
end;

procedure TIntersection.Draw(Viewport:TViewport);
var I,J,R,G,B: integer;
    Spline  : TSpline;
    P,P2,N  : Vector;
    Pts,CPts: array of TPoint;
    Curv    : Real;
    DrawIt  : Boolean;
begin
   if Viewport.ViewportMode=vmWireframe then begin
      if not Built then Rebuild;
      for I:=1 to Count do begin
         Spline:=Items[I-1];
         Spline.Color:=Color;
         Spline.PenStyle:=psSolid;
         if IntersectionType=fiStation then if Viewport.ViewType in [fvProfile,fvPlan] then Spline.PenStyle:=psDot;
         if IntersectionType=fiButtock then if Viewport.ViewType in [fvBodyplan,fvPlan] then Spline.PenStyle:=psDot;
         if IntersectionType=fiWaterline then if Viewport.ViewType in [fvProfile,fvBodyplan] then Spline.PenStyle:=psDot;
         if Spline.PenStyle=psDot then Spline.Color:=clSilver;
         Spline.ShowCurvature:=(St.Visibility.ShowCurvature) and (ShowCurvature);;
         if Spline.ShowCurvature then Spline.Fragments:=800
                                 else Spline.Fragments:=600;
         Setlength(Pts,Spline.Fragments+1);
         if Spline.ShowCurvature then Setlength(CPts,Spline.Fragments+1);
         // Draw portside
         DrawIt:=IntersectionType in [fiButtock,fiWaterline,fiDiagonal];
         if IntersectionType=fiStation then
            Drawit:=(Viewport.ViewType<>fvBodyplan)
                or (St.Visibility.ModelView=mvBoth)
                or (Spline.Max.X>=St.ProjectSettings.MidleFrame );
         {
         if IntersectionType=fiStation then begin
            P:=Spline.Value(0.0);
            P.Y:=0.0;
            Pts[0]:=Viewport.Project(P);
            for J:=1 to Spline.Fragments-1 do begin
               P:=Spline.Value((J-1)/(Spline.Fragments-2));
               Pts[J]:=Viewport.Project(P);
            end;
            P.Y:=0.0;
            Pts[Spline.Fragments]:=Viewport.Project(P);
            Viewport.BrushColor:=clGreen;
            Viewport.BrushStyle:=bsSolid;
            Viewport.PenColor:=Spline.Color;
            Viewport.PenStyle:=Spline.PenStyle;
            Viewport.Canvas.Polygon(Pts);
         end else
         }
         if DrawIt then begin
            for J:=0 to Spline.Fragments do begin
               if Spline.ShowCurvature then begin
                  Curv:=Spline.Curvature(J/Spline.Fragments,P,N);
                  Pts[J]:=Viewport.Project(P);
                  P2:=P-(Curv*Sp.CurvatureScale)*N;
                  CPts[J]:=Viewport.Project(P2);
               end else begin
                  P:=Spline.Value(J/Spline.Fragments);
                  Pts[J]:=Viewport.Project(P);
               end;
            end;
            if Spline.ShowCurvature then begin
               Viewport.SetPenWidth(1);
               Viewport.PenColor:=Sp.CurvaturePlot;
               Viewport.PenStyle:=psSolid;
               for J:=0 to Spline.Fragments do
               if (J mod 10=0) or (J=0) or (J=Spline.Fragments) then begin
                  Viewport.Canvas.MoveTo(Pts[J].X,Pts[J].Y);
                  Viewport.Canvas.LineTo(CPts[J].X,CPts[J].Y);
               end;
               Viewport.Canvas.Polyline(CPts);
            end;
            Viewport.PenColor:=Spline.Color;
            Viewport.PenStyle:=Spline.PenStyle;
            Viewport.Canvas.Polyline(Pts);
         end;

         DrawIt:=False;
         if (St.Visibility.ModelView=mvBoth) then DrawIt:=True
            else if (Viewport.ViewType=fvBodyplan)
                 and (Spline.Max.X<=St.ProjectSettings.MidleFrame) then DrawIt:=True;
         if DrawIt then begin                           // Draw starboard side
            for J:=0 to Spline.Fragments do begin
               if Spline.ShowCurvature then begin
                  Curv:=Spline.Curvature(J/Spline.Fragments,P,N);
                  N.Y:=-N.Y;
                  P.Y:=-P.Y;
                  Pts[J]:=Viewport.Project(P);
                  P2:=P-(Curv*Sp.CurvatureScale)*N;
                  CPts[J]:=Viewport.Project(P2);
               end else begin
                  P:=Spline.Value(J/Spline.Fragments);
                  P.Y:=-P.Y;
                  Pts[J]:=Viewport.Project(P);
               end;
            end;
            if Spline.ShowCurvature then begin
               Viewport.SetPenWidth(1);
               Viewport.PenColor:=Sp.CurvaturePlot;
               Viewport.PenStyle:=psSolid;
               for J:=0 to Spline.Fragments do
               if (J mod 10=0) or (J=0) or (J=Spline.Fragments) then begin
                  Viewport.Canvas.MoveTo(Pts[J].X,Pts[J].Y);
                  Viewport.Canvas.LineTo(CPts[J].X,CPts[J].Y);
               end;
               Viewport.Canvas.Polyline(CPts);
            end;
            Viewport.PenColor:=Spline.Color;
            Viewport.PenStyle:=Spline.PenStyle;
            Viewport.Canvas.Polyline(Pts);
         end;
      end;
   end else begin                                           // draw to z-buffer
      if not Built then Rebuild;
      R:=GetRValue(Color);
      G:=GetGValue(Color);
      B:=GetBValue(Color);
      for I:=1 to Count do begin
         Spline:=Items[I-1];
         Spline.Fragments:=250;
         P:=Spline.Value(0.0);
         DrawIt:=(Viewport.ViewType=fvBodyplan)
             and (P2.x<St.ProjectSettings.MidleFrame );
         if DrawIt then P.y:=-P.y;
         for J:=1 to Spline.Fragments do begin
            P2:=Spline.Value(J/Spline.Fragments); if DrawIt then P2.y:=-P2.y;
            Viewport.DrawLineToZBuffer(P,P2,R,G,B); P:=P2;
         end;
         if St.Visibility.ModelView=mvBoth then begin // Draw starboardside as well
            P:=Spline.Value(0.0);
            P.Y:=-P.Y;
            for J:=1 to Spline.Fragments do begin
               P2:=Spline.Value(J/Spline.Fragments);
               P2.Y:=-P2.Y;
               Viewport.DrawLineToZBuffer(P,P2,R,G,B);
               P:=P2;
            end;
         end;
      end;
   end;
end;

procedure TIntersection.DrawAll; Var I: integer;
    begin for I:=1 to St.nV do Draw(St.Viewport[I-1]); end;

procedure TIntersection.Extents(Var Min,Max:Vector);
var I    : integer;
begin
   if not built then Rebuild;
   for I:=1 to Count do Items[I-1].Extents(Min,Max);
end;

procedure TIntersection.LoadBinary(Source:TFileBuffer);
var I,J,M,N : integer;
    Spline  : TSpline;
    P       : Vector;
    Bool    : Boolean;
begin
   Source.LoadInteger(I);
   IntersectionType:=TIntersectionType(I);
   if St.FileVersion>=fv191 then begin
      Source.LoadBoolean(ShowCurvature);
   end else ShowCurvature:=False;
   Source.LoadT3DPlane(FPlane);
   Source.LoadBoolean(FBuilt);
   Source.LoadInteger(N);
   FItems.Capacity:=N;
   for I:=1 to N do begin
      Spline:=TSpline.Create;
      FItems.Add(Spline);              // Read number of points for this spline
      Source.LoadInteger(M);                  // Read actual 3D coordinates
      Spline.Capacity:=M;
      for J:=1 to M do begin
         if St.FileVersion>=fv160 then begin
            if IntersectionType=fiStation then begin
               P.X:=-FPlane.d;
               Source.LoadTFloatType(P.Y);
               Source.LoadTFloatType(P.Z);
            end else if IntersectionType=fiButtock then begin
               Source.LoadTFloatType(P.X);
               P.Y:=-FPlane.d;
               Source.LoadTFloatType(P.Z);
            end else if IntersectionType=fiWaterline then begin
               Source.LoadTFloatType(P.X);
               Source.LoadTFloatType(P.Y);
               P.Z:=-FPlane.d;
            end else Source.LoadVector(P);
         end else Source.LoadVector(P);
         Spline.Add(P);
         Source.LoadBoolean(Bool);
         Spline.Knuckle[J-1]:=Bool;
      end;
   end;
end;

procedure TIntersection.ReBuild;
var I:Integer;
begin Built:=false;                       // Force to destroy all current Items
   St.Surface.IntersectPlane( Plane,UseHydrostaticsSurfacesOnly,FItems );
// Use a low simplification factor to remove only points that are (nearly) on a line
   if St.ProjectSettings.ProjectSimplifyIntersections then
      for I:=1 to Count do self.Items[I-1].Simplify( 2.0 );
   Built:=true;
end;

procedure TIntersection.SaveBinary( Destination:TFileBuffer );
var I,J: integer; Spline: TSpline; P: Vector;
begin
   Destination.Add(Ord(IntersectionType));
  {if St.FileVersion>=fv191 then} Destination.Add(ShowCurvature);
   Destination.Add(FPlane);
   Destination.Add(FBuilt);
   Destination.Add(Count);
   for I:=1 to Count do begin
      Spline:=Items[I-1];
      Destination.Add(Spline.nS);
      for J:=1 to Spline.nS do begin
         P:=Spline.Point[J-1];
//       if St.FileVersion>=fv160 then begin
            Case IntersectionType of
               fiStation: begin
                   Destination.Add(P.Y);
                   Destination.Add(P.Z);
                   Destination.Add(Spline.Knuckle[J-1]); end;
               fiButtock: begin
                   Destination.Add(P.X);
                   Destination.Add(P.Z);
                   Destination.Add(Spline.Knuckle[J-1]); end;
               fiWaterline: begin
                   Destination.Add(P.X);
                   Destination.Add(P.Y);
                   Destination.Add(Spline.Knuckle[J-1]); end;
               fiDiagonal: begin
                   Destination.Add(P);
                   Destination.Add(Spline.Knuckle[J-1]); end;
            end;
{        end else begin
            Destination.Add(P);
            Destination.Add(Spline.Knuckle[J-1]);
         end;
}     end;
   end;
end;
{
   TMarker
}
function TMarker.FGetSelected:Boolean;
   begin Result:=Owner.FSelectedMarkers.SortedIndexOf(self)<>-1; end;

procedure TMarker.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedMarkers.SortedIndexOf(self);
   if Val then begin               // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedMarkers.AddSorted(self);
   end else begin
      if Index<>-1 then Owner.FSelectedMarkers.Delete(index);
   end;
   if Assigned(Owner.Surface.OnSelectItem) then Owner.Surface.OnSelectItem(self);
end;
procedure TMarker.Clear;
    begin FVisible:=True; inherited Clear; end;

function TMarker.DistanceToCursor(X,Y:Integer;Viewport:TViewport):integer;
var I,Tmp    : Integer;
    Pt,P1,P2 : TPoint;
    V1,V2    : Vector;
    Param    : Real;
begin
   Result:=1000000;      // Check if cursor position lies within the boundaries
   if (Viewport.ViewType=fvBodyPlan)
   and (not (Owner.Visibility.ModelView=mvBoth)) then begin
      Pt.X:=X;
      Pt.Y:=Y;
      if (Pt.X>=0) and (Pt.X<=Viewport.Width)
      and (Pt.Y>=0) and (Pt.Y<=Viewport.Height) then begin
         V1:=Value(0.0);
         if V1.X<Owner.ProjectSettings.MidleFrame then V1.Y:=-V1.Y;
         for I:=1 to Fragments do begin
            V2:=Value((I-1)/(Fragments-1));
            if V2.X<Owner.ProjectSettings.MidleFrame then V2.Y:=-V2.Y;
            if ((V1.X<Owner.ProjectSettings.MidleFrame)
            and (V2.X<Owner.ProjectSettings.MidleFrame))
            or ((V1.X>Owner.ProjectSettings.MidleFrame)
            and (V2.X>Owner.ProjectSettings.MidleFrame)) then begin
               P1:=Viewport.Project(V1);
               P2:=Viewport.Project(V2);
               Tmp:=Round(DistanceToLine(P1,P2,X,Y,Param));
               if Tmp<Result then result:=Tmp;
            end;
            P1:=P2;
            V1:=V2;
         end;
      end;
   end else Result:=inherited DistanceToCursor(X,Y,Viewport);
   if Owner.Visibility.ModelView=mvBoth then begin
      for I:=1 to nS do begin
         V1:=Point[I-1];
         V1.Y:=-V1.Y;
         Point[I-1]:=V1;
      end;
      Tmp:=inherited DistanceToCursor(X,Y,Viewport);
      if Tmp<Result then Result:=Tmp;
      for I:=1 to nS do begin
         V1:=Point[I-1];
         V1.Y:=-V1.Y;
         Point[I-1]:=V1;
      end;
   end;
end;

procedure TMarker.Delete;
var Index:Integer;
begin
   Index:=Owner.FSelectedMarkers.SortedIndexOf(Self);
   if Index<>-1 then Owner.FSelectedMarkers.Delete(Index);
   Index:=Owner.FMarkers.IndexOf(Self);
   if Index<>-1 then Owner.FMarkers.Delete(Index);
   Destroy;
end;

procedure TMarker.Draw(Viewport:TViewport);
var I,J,Size,Scale,NParam,Fragm: Integer;
    Pt: TPoint;
    Plane: Plate;
    Output: TIntersectionData;
    Param: RealArray;
    P3D,Normal: Vector;
    PArray1,PArray2: array of TPoint;
    C,T:Real;
begin
   if Visible then begin
      if Owner<>nil then begin
         if Selected then Color:=Sp.Select
                     else Color:=Sp.Marker;
         Size:=Owner.Preferences.PointSize;
      end else begin
         Color:=clLime;
         Size:=2;
         ShowMessage(Userstring(67));
      end;
      Fragments:=250;
      if (Viewport.ViewType=fvBodyPlan)
      and (Owner.Visibility.ModelView<>mvBoth) then begin
         Plane:=SetPlane(1.0,0.0,0.0,-Owner.ProjectSettings.MidleFrame);
         NParam:=2;
         Setlength(Param,NParam);
         Param[0]:=0.0;
         Param[1]:=1.0;
         if IntersectPlane(Plane,Output) then begin
            Setlength(Param,NParam+Output.NoIntersections);
            for I:=1 to Output.NoIntersections do begin
               Param[NParam]:=Output.Parameters[I-1];
               inc(NParam);
            end;
            ArraySort( Param,NParam );
         end;
         for I:=2 to NParam do begin
            P3D:=Value(0.5*(Param[I-2]+Param[I-1]));
            if P3D.X<Owner.ProjectSettings.MidleFrame then Scale:=-1
                                                      else scale:=1;
            Fragm:=Round((Param[I-1]-Param[I-2])*Fragments);
            if Fragm<10 then Fragm:=10;
            if ShowCurvature then begin
               SetLength(PArray1,Fragm);
               SetLength(PArray2,Fragm);
               for J:=1 to Fragm do begin
                  T:=Param[I-2]+(Param[I-1]-Param[I-2])*(J-1)/(Fragm-1);
                  C:=Curvature(T,P3D,Normal);
                  P3D.Y:=P3D.Y*Scale;
                  Normal.Y:=Normal.Y*Scale;
                  PArray1[J-1]:=Viewport.Project(P3D);
                  PArray2[J-1]:=Viewport.Project(P3D-(2.0*C*Sp.CurvatureScale)*Normal );
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
                  P3D:=Value(T);
                  P3D.Y:=P3D.Y*Scale;
                  PArray1[J-1]:=Viewport.Project(P3D);
               end;
            end;
            Viewport.SetPenWidth(1);
            Viewport.PenColor:=Color;
            Viewport.Canvas.Pen.Style:=Penstyle;
            Viewport.Canvas.Polyline(PArray1);
         end;
         for I:=1 to nS do begin
            P3D:=Point[I-1];
            if P3D.X<Owner.ProjectSettings.MidleFrame then P3D.Y:=-P3D.Y;
            Pt:=Viewport.Project(P3D);
            Viewport.Canvas.MoveTo(Pt.X-Size,Pt.Y-Size);
            Viewport.Canvas.LineTo(Pt.X+Size,Pt.Y+Size);
            Viewport.Canvas.MoveTo(Pt.X-Size,Pt.Y+Size);
            Viewport.Canvas.LineTo(Pt.X+Size,Pt.Y-Size);
         end;
      end else begin
         inherited Draw(Viewport);
         for I:=1 to nS do  begin
            Pt:=Viewport.Project(Point[I-1]);
            Viewport.Canvas.MoveTo(Pt.X-Size,Pt.Y-Size);
            Viewport.Canvas.LineTo(Pt.X+Size,Pt.Y+Size);
            Viewport.Canvas.MoveTo(Pt.X-Size,Pt.Y+Size);
            Viewport.Canvas.LineTo(Pt.X+Size,Pt.Y-Size);
         end;
      end;
   end;
end;

procedure TMarker.LoadBinary(Source:TFileBuffer);
var sel:boolean;
begin
   Source.LoadBoolean(FVisible);
   if Owner.FileVersion>=fv260 then begin
      Source.LoadBoolean(Sel);
      if sel then Owner.FSelectedMarkers.AddSorted(self);
   end;
   Inherited LoadBinary(Source);
end;

procedure TMarker.SaveBinary(Destination:TFileBuffer);
begin
   Destination.Add(FVisible);
  {if Owner.FileVersion>=fv260 then} Destination.Add(Selected);
   Inherited SaveBinary( Destination );
end;
{
   TFlowline
}
function TFlowline.FGetColor:TColor;
begin
   if Selected then result:=Sp.Select
// else if FMethodNew then Result:=clRed
                      else Result:=clAqua; // clBlue;
end;

function TFlowline.FGetSelected:Boolean;
   begin Result:=St.FSelectedFlowlines.SortedIndexOf(self)<>-1; end;
function TFlowline.FGetVisible:Boolean;
   begin Result:=St.Visibility.ShowFlowlines; end;

procedure TFlowline.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=St.FSelectedFlowlines.SortedIndexOf(self);
   if Val then begin               // Only add if it is not already in the list
      if Index=-1 then St.FSelectedFlowlines.AddSorted(self);
   end else begin
      if Index<>-1 then St.FSelectedFlowlines.Delete(index);
   end;
   if Assigned(St.Surface.OnSelectItem) then St.Surface.OnSelectItem(self);
end;

procedure TFlowline.FSetBuild( val:Boolean );
    begin FBuild:=val; if not val then FFlowline.Clear; end;

constructor TFlowline.Create; // (Owner:TShip);
      begin inherited Create; // (*##*) St:=owner;
            FFlowLine:=Tspline.Create; Clear;
      end;
procedure TFlowline.Clear;
    begin FProjectionPoint.X:=0;
          FProjectionPoint.Y:=0;
          FProjectionView:=fvProfile;
          FFlowLine.Clear;
          FBuild:=false; // FMethodNew:=False;
    end;
destructor TFlowline.Destroy;
     begin Clear; FFlowLine.Destroy;
                  Inherited Destroy;
     end;

procedure TFlowline.Delete;
var Index:Integer;
begin
   Index:=St.FSelectedFlowlines.SortedIndexOf(Self);
   if Index<>-1 then St.FSelectedFlowlines.Delete(Index);
   Index:=St.FFlowLines.IndexOf(Self);
   if Index<>-1 then St.FFlowlines.Delete(Index);
   Destroy;
end;

function TFlowline.DistanceToCursor(X,Y:Integer;Viewport:TViewport):integer;
var I,Tmp    : Integer;
    Pt,P1,P2 : TPoint;
    V1,V2    : Vector;
    Param    : Real;
begin
   Result:=1000000;
   if (Viewport.ViewType=fvBodyPlan)
   and (not (St.Visibility.ModelView=mvBoth)) then begin
      Pt.X:=X;           // Check if cursor position lies within the boundaries
      Pt.Y:=Y;
      if (Pt.X>=0) and (Pt.X<=Viewport.Width)
      and (Pt.Y>=0) and (Pt.Y<=Viewport.Height) then begin
         V1:=FFlowline.Value(0.0);
         if V1.X<St.ProjectSettings.MidleFrame then V1.Y:=-V1.Y;
         for I:=1 to FFlowline.Fragments do begin
            V2:=FFlowline.Value((I-1)/(FFlowline.Fragments-1));
            if V2.X<St.ProjectSettings.MidleFrame then V2.Y:=-V2.Y;
            if ((V1.X<St.ProjectSettings.MidleFrame)
            and (V2.X<St.ProjectSettings.MidleFrame))
            or ((V1.X>St.ProjectSettings.MidleFrame)
            and (V2.X>St.ProjectSettings.MidleFrame)) then begin
               P1:=Viewport.Project(V1);
               P2:=Viewport.Project(V2);
               Tmp:=Round(DistanceToLine(P1,P2,X,Y,Param));
               if Tmp<Result then result:=Tmp;
            end;
            P1:=P2;
            V1:=V2;
         end;
      end;
   end else Result:=FFlowline.DistanceToCursor(X,Y,Viewport);
   if St.Visibility.ModelView=mvBoth then begin
      for I:=1 to FFlowline.nS do begin
         V1:=FFlowline.Point[I-1]; V1.Y:=-V1.Y;
             FFlowline.Point[I-1]:=V1;
      end;
      Tmp:=FFlowline.DistanceToCursor(X,Y,Viewport);
      if Tmp<Result then Result:=Tmp;
      for I:=1 to FFlowline.nS do begin
         V1:=FFlowline.Point[I-1];
         V1.Y:=-V1.Y;
         FFlowline.Point[I-1]:=V1;
      end;
   end;
end;

procedure TFlowline.Draw( Viewport:TViewport );
var I,J,Scale,Size,NParam,Fragm: Integer;
    Plane   : Plate;
    Output  : TIntersectionData;
    Param   : RealArray;
    P3D     : Vector;
    PArray1 : array of TPoint;
    Pt      : TPoint;
    T       : Real;
begin
   if not build then ReBuild;
   FFlowline.Color:=Color;
   FFlowline.Fragments:=600;
   if (FFlowline.nS>0) and (Viewport.ViewportMode=vmWireframe) then begin
      P3D:=FFlowline.Point[0];                          // draw flowline source
      if (Viewport.ViewType=fvBodyplan)
      and (St.Visibility.ModelView<>mvBoth)
      and (P3D.X<St.ProjectSettings.MidleFrame)
      then P3D.Y:=-P3D.Y;
      Pt:=Viewport.Project(P3D);
      Size:=Round( Sqrt(Viewport.Zoom)*(St.Preferences.PointSize+1)/2 );
      if size<1 then size:=1;
      Viewport.BrushStyle:=bsClear;
      Viewport.PenColor:=clDkGray;
      Viewport.BrushColor:=clAqua; //White;
      Viewport.BrushStyle:=bsSolid;             // Draw entire circle in white;
      Viewport.Canvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
      if St.Visibility.ModelView=mvBoth then begin
         P3D.Y:=-P3D.Y;
         Pt:=Viewport.Project(P3D);             // Draw entire circle in white;
         Viewport.Canvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
      end;
   end;
   if (Viewport.ViewType=fvBodyPlan)
   and (St.Visibility.ModelView<>mvBoth) then begin
      Plane:=SetPlane(1.0,0.0,0.0,-St.ProjectSettings.MidleFrame);
      NParam:=2;
      Setlength( Param,NParam );
      Param[0]:=0.0;
      Param[1]:=1.0;
      if FFlowline.IntersectPlane(Plane,Output) then begin
         Setlength(Param,NParam+Output.NoIntersections);
         for I:=1 to Output.NoIntersections do begin
            Param[NParam]:=Output.Parameters[I-1]; inc(NParam);
         end;
         ArraySort( Param,NParam );
      end;
      for I:=2 to NParam do begin
         P3D:=FFlowline.Value(0.5*(Param[I-2]+Param[I-1]));
         if P3D.X<St.ProjectSettings.MidleFrame then Scale:=-1
                                                   else scale:=1;
         Fragm:=Round((Param[I-1]-Param[I-2])*FFlowline.Fragments);
         if Fragm<10 then Fragm:=10;
         SetLength( PArray1,Fragm );
         for J:=1 to Fragm do begin
            T:=Param[I-2]+(Param[I-1]-Param[I-2])*(J-1)/(Fragm-1);
            P3D:=FFlowline.Value(T);
            P3D.Y:=P3D.Y*Scale;
            PArray1[J-1]:=Viewport.Project(P3D);
         end;
         Viewport.SetPenWidth(1);
         Viewport.PenColor:=FFlowline.Color;
         Viewport.Canvas.Pen.Style:=FFlowline.Penstyle;
         Viewport.Canvas.Polyline(PArray1);
      end;
   end else begin
      FFlowline.Draw(Viewport);
      if St.Visibility.ModelView=mvBoth then begin
         for I:=1 to FFlowline.nS do begin
            P3D:=FFlowline.Point[I-1];
            P3D.Y:=-P3D.Y;
            FFlowline.Point[I-1]:=P3D;
         end;
         FFlowline.Draw(Viewport);
         for I:=1 to FFlowline.nS do begin
            P3D:=FFlowline.Point[I-1];
            P3D.Y:=-P3D.Y;
            FFlowline.Point[I-1]:=P3D;
         end;
      end;
   end;
end;

procedure TFlowline.LoadBinary(Source:TFileBuffer);
var I,N : Integer;
    P   : Vector;
    K   : Boolean;
begin
   Source.LoadTFloatType(FProjectionPoint.X);
   Source.LoadTFloatType(FProjectionPoint.Y);
   Source.LoadInteger(I);
   FProjectionView:=TviewType(I);
   Source.LoadBoolean(FBuild);
   Source.loadBoolean(K);
   if K then St.FSelectedFlowlines.AddSorted(self);
   Source.LoadInteger(N);
   FFlowline.Capacity:=N;
   for I:=1 to N do begin
      Source.LoadVector(P);
      Source.LoadBoolean(K);
      FFlowline.Add(P);
      FFlowline.Knuckle[FFlowline.nS-1]:=K;
   end;
end;

procedure TFlowline.Rebuild;
type TTriangle  = record
       P1,P2,P3 : Integer;
       Plane    : Plate;
       Index    : Integer;
       Processed: Boolean; end;
     TPointData = record
       Coord    : Vector;
       FlowDir  : Vector;
       Triangles: array of integer;
       Ntriangles: Integer; end;

var Points,Faces: TFasterList;
    Face: SControlFace;
    Point: SPoint;
    Child: SFace;
    I,J,K,L,Index,NTriangles,Iteration,Skip1,Skip2,TriangleCapacity: Integer;
    Layer: SLayer;
    WlHeight: Real;
    Triangles: array of TTriangle;
    PointData: array of TPointData;
    StartPoint,EndPoint,Intersection,Direction: Vector;
    Valid: Boolean;

    procedure AddTriangleToPoint( var Point:TPointData; TriangleIndex:Integer );
    begin
       inc( Point.Ntriangles );
       Setlength( Point.Triangles,Point.Ntriangles );
       Point.Triangles[Point.Ntriangles-1]:=TriangleIndex;
    end;
    procedure AddTriangle(P1,P2,P3:SPoint);
    begin
       if NTriangles=TriangleCapacity then begin
         inc(TriangleCapacity,250);
         Setlength(Triangles,TriangleCapacity);
       end;
       Triangles[NTriangles].Index:=NTriangles;
       Triangles[NTriangles].Processed:=False;
       Triangles[NTriangles].P1:=Points.SortedIndexOf(P1);
       AddTriangleToPoint(PointData[Triangles[NTriangles].P1],NTriangles);
       Triangles[NTriangles].P2:=Points.SortedIndexOf(P2);
       AddTriangleToPoint(PointData[Triangles[NTriangles].P2],NTriangles);
       Triangles[NTriangles].p3:=Points.SortedIndexOf(P3);
       AddTriangleToPoint(PointData[Triangles[NTriangles].P3],NTriangles);
       Triangles[NTriangles].Plane:=PlanePPP(P1.Coordinate,P2.Coordinate,P3.Coordinate);
       inc(NTriangles);
    end;
    function CalculateFlowDirection{2}( {Incoming:Vector;} Point:SPoint ):Vector;
    var Normal,Direction,P,Proj, Incoming: Vector; Plane: Plate;
    begin // Incoming.x-=1.001; Incoming.y*=0.4;
                             // Incoming.z*=0.4; Incoming:=Normalize(Incoming);
       Incoming:=iVect( -1.0,0.0,0.0 );
       Normal:=Point.Normal;
       P:=Point.Coordinate;
       Plane:=PlanePointNormal( P,Normal );
       Direction:=Normalize( Normal+Incoming );
       Incoming:=P+Direction;
       Proj:=ProjectPointOnPlane( Incoming,Plane );
       Direction:=Proj-P;
       Result:=Normalize( Direction );
    end;
    function FindInitialTriangle
    ( StartPoint,EndPoint:Vector; var Int,Dir:Vector ): Integer;
    var Triangle: TTriangle;
        S1,S2,s,t, Distance,b0,b1,b2,UdotV,UdotU,VdotV,WdotU,WdotV: Real;
        P,u,v,w,P0,P1,P2: Vector;
        I: Integer;
    begin
       Result:=-1;
       Distance:=1e8;
       Int:=Zero;
       Dir:=Zero;
       for I:=1 to NTriangles do begin
          Triangle:=Triangles[I-1];
          S1:=Triangle.Plane.a*StartPoint.x
            + Triangle.Plane.b*StartPoint.y
            + Triangle.Plane.c*StartPoint.z + Triangle.Plane.d;
          S2:=Triangle.Plane.a*EndPoint.x
            + Triangle.Plane.b*EndPoint.y
            + Triangle.Plane.c*EndPoint.z + Triangle.Plane.d;
          if ((S1<0) and (S2>0))
          or ((S1>0) and (S2<0)) then begin          // possible intersection
             if S1=S2 then T:=0.5
                      else T:=s1/(s1-s2);
             P:=StartPoint + (T*(EndPoint-StartPoint));
             if PointInTriangle( P,PointData[Triangle.P1].Coord,
                                   PointData[Triangle.P2].Coord,
                                   PointData[Triangle.P3].Coord ) then begin
                T:=Abs( StartPoint-P );
                if T<Distance then begin Distance:=T; Result:=I-1; Int:=P; end;
             end;
          end;
       end;
       if Result<>-1 then begin
       // Calculate baycentric coordinates to interpolate between the three flowdirections
          Triangle:=Triangles[result];
          P0:=PointData[Triangle.P1].Coord;
          P1:=PointData[Triangle.P2].Coord;
          P2:=PointData[Triangle.P3].Coord;
          U:=P1-P0;
          V:=P2-P0;
          W:=Int-P0;
          UdotU:=Dotproduct( U,U );
          UdotV:=Dotproduct( U,V );
          VdotV:=Dotproduct( V,V );
          WdotU:=Dotproduct( W,U );
          WdotV:=Dotproduct( W,V );
          S:=( UdotV*WdotV-VdotV*WdotU )/( UdotV*UdotV-UdotU*VdotV );
          T:=( UdotV*WdotU-UdotU*WdotV )/( UdotV*UdotV-UdotU*VdotV );
          B0:=1-S-T;
          B1:=S;
          B2:=T;                                                       // check
          T:=b0+b1+b2;
          if T=1 then begin
             P0:=PointData[Triangle.P1].FlowDir;
             P1:=PointData[Triangle.P2].FlowDir;
             P2:=PointData[Triangle.P3].FlowDir;
             Dir:=B0*P0 + B1*P1 + B2*P2;
          // if FMethodNew then Dir:=Normalize(iVect(-1,0.1,-0.1));
          end; // else Result:=Result-1+1;
       end;
    end;

    function ProcessTriangle( var Triangle:TTriangle;
                              var SkipInd1,SkipInd2:Integer;
                              var Intersection,Direction:Vector;
                              var NextTriangle:integer ):boolean;
     var P1,P2,Dir1,Dir2,Int: Vector;
        Distance,Param: Real;
        Ind1,Ind2,I: Integer;

        function NextTriangleIndex(P1,P2,CurrIndex:Integer):Integer;
        var Point1,Point2: TPointData; I,J: Integer;
        begin Result:=-1;
           Point1:=PointData[P1];
           Point2:=PointData[P2];
           for I:=1 to Point1.Ntriangles do
           for J:=1 to Point2.Ntriangles do begin
              if (Point1.Triangles[I-1]=Point2.Triangles[J-1])
              and (Point1.Triangles[I-1]<>CurrIndex) then begin
                 Result:=Point1.Triangles[I-1]; exit;
              end;
           end;
        end;
    begin
       Result:=False;
       NextTriangle:=Triangle.Index;
       Triangle.Processed:=True;
       P1:=ProjectPointOnPlane(Intersection,Triangle.Plane) + 0.0005*Direction;
       if not PointInTriangle(P1,PointData[Triangle.P1].Coord,PointData[Triangle.P2].Coord,PointData[Triangle.P3].Coord)
          then P1:=ProjectPointOnPlane(Intersection,Triangle.Plane);
       P1:=ProjectPointOnPlane(P1,Triangle.Plane); // test all three linesegments for intersection
       Distance:=50;
       P2:=ProjectPointOnPlane(P1+Distance*Direction,Triangle.Plane);
       for I:=1 to 3 do begin
          Case I of
             1 : Ind1:=Triangle.P1;
             2 : Ind1:=Triangle.P2;
             3 : Ind1:=Triangle.P3; else Ind1:=0;
          end;
          Case I of
             1 : Ind2:=Triangle.P2;
             2 : Ind2:=Triangle.P3;
             3 : Ind2:=Triangle.P1; else Ind2:=0;
          end;
          if ((Ind1=SkipInd1) and (Ind2=SkipInd2))
          or ((Ind1=SkipInd2) and (Ind2=SkipInd1)) then begin end else
          if Lines3DIntersect(P1,P2,PointData[Ind1].Coord,PointData[Ind2].Coord,Param,Int)
          then begin
             Distance:=Triangle.Plane.a*Int.x
                      +Triangle.Plane.b*Int.y
                      +Triangle.Plane.c*Int.z+Triangle.Plane.d;
             if Distance<1e-1 then begin Intersection:=Int; // calculate direction
{              if FMethodNew then begin
                  Dir1:=CalculateFlowDirection2(Direction,Points[Ind1]);
                  Dir2:=CalculateFlowDirection2(Direction,Points[Ind2]);
               end else begin
}                 Dir1:=PointData[Ind1].FlowDir;
                  Dir2:=PointData[Ind2].FlowDir;
//             end;
               SkipInd1:=Ind1;
               SkipInd2:=ind2;
               Direction:=Dir1 + Param*(Dir2-Dir1);
               NextTriangle:=NextTriangleIndex(ind1,Ind2,Triangle.Index);
               Result:=True; exit;
             end;
          end;
       end;
    end;
begin                                            // clear any present data
   Build:=false;
   // Assemble all faces that are (partially) submerged and extract points
   Faces:=TFasterList.Create;
   WlHeight:=St.FindLowestHydrostaticsPoint+St.ProjectSettings.ProjectDraft;
   // WlHeight:=owner.surface.max.z;
   if St.surface.NoPoints<0 then exit;
   for I:=1 to St.Surface.NoLayers
   do if St.Surface.Layer[I-1].UseInHydrostatics then begin
      Layer:=St.Surface.Layer[I-1];
      for J:=1 to Layer.Count do if Layer.Items[J-1].Min.Z<=WlHeight then begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do begin
            Child:=Face.Child[K-1];
            for L:=1 to Child.Nopoints do
            if Child.Point[L-1].Coordinate.Z<=WlHeight then begin
               Faces.Add(Child);          // Face is (partially) submerged;
               break;
            end;
         end;
      end
   end;
   if Faces.Count>0 then begin
      Points:=TFasterList.create;
      Points.Capacity:=Faces.Count+100;
      for I:=1 to Faces.Count do begin Child:=Faces[I-1];
         for J:=1 to Child.Nopoints do begin
            Point:=Child.Point[J-1];
            if Points.SortedIndexOf(Point)=-1 then Points.AddSorted(Point);
         end;
      end;
      Points.Sort; {##}
      Setlength(PointData,Points.Count);
      for I:=0 to Points.Count-1 do begin
         Point:=Points[I];
         PointData[I].Coord:=Point.Coordinate;
         PointData[I].FlowDir:=CalculateFlowDirection(Point);
         PointData[I].Ntriangles:=0;
      end;
      TriangleCapacity:=2*Faces.Count;
      Setlength(Triangles,TriangleCapacity);
      NTriangles:=0;
      for I:=1 to Faces.Count do begin
         Child:=Faces[I-1];
         for J:=3 to Child.Nopoints do
             AddTriangle( Child.Point[0],Child.Point[J-2],Child.Point[J-1] );
      end;
      Case FProjectionView of
         fvProfile: begin
           Startpoint.X:=FProjectionPoint.X;
           StartPoint.Y:=St.Surface.Max.Y; //+1; //0;
           StartPoint.Z:=FProjectionPoint.Y;
           EndPoint:=iVect(StartPoint.X,0,StartPoint.Z); end;
         fvPlan: begin
           Startpoint.X:=FProjectionPoint.X;
           StartPoint.Y:=FProjectionPoint.Y;
           StartPoint.Z:=St.Surface.Min.Z-10;
           EndPoint:=iVect(StartPoint.X,StartPoint.Y,St.Surface.Max.Z+100); end;
         fvBodyplan:
           if FProjectionPoint.X<0 then begin
              Startpoint.X:=St.Surface.Min.X-10;
              StartPoint.Y:=-FProjectionPoint.X;
              StartPoint.Z:=FProjectionPoint.Y;
              EndPoint:=iVect(St.Surface.Max.X+10,StartPoint.Y,StartPoint.Z);
           end else begin
              Startpoint.X:=St.Surface.Max.X+10;
              StartPoint.Y:=FProjectionPoint.X;
              StartPoint.Z:=FProjectionPoint.Y;
              EndPoint:=iVect(St.Surface.Min.X-10,StartPoint.Y,StartPoint.Z); end;
         else exit;
      end;                                         // find the initial triangle
      Index:=FindInitialTriangle(StartPoint,EndPoint,Intersection,Direction);
      Skip1:=-1;
      Skip2:=-1;                                   // trace triangles from here
      if index<>-1 then begin (*##*) FFlowline.Add(Intersection);
         Iteration:=0;
         repeat
            if Triangles[index].Processed then Valid:=False else
               Valid:=ProcessTriangle(Triangles[index],Skip1,Skip2,Intersection,Direction,Index);
            if Valid then FFlowline.Add(Intersection) else
               Valid:=ProcessTriangle(Triangles[index],Skip1,Skip2,Intersection,Direction,Index);
            inc(Iteration);
         until (not valid) or (index=-1) or (Iteration>5000);

         While FFlowline.nS>1 do begin
            if (FFlowline.Point[FFlowline.nS-1].Z>WlHeight)
            and (FFlowline.Point[FFlowline.nS-2].Z>WlHeight)
            then FFlowline.DeletePoint(FFlowline.nS-1) else
            if (FFlowline.Point[FFlowline.nS-1].Z>WlHeight)
            and (FFlowline.Point[FFlowline.nS-2].Z<WlHeight) then begin
               Endpoint.X:=FFlowline.Point[FFlowline.nS-2].X
                        +( FFlowline.Point[FFlowline.nS-1].X
                          -FFlowline.Point[FFlowline.nS-2].X )
                        *( WlHeight
                          -FFlowline.Point[FFlowline.nS-2].Z )
                        /( FFlowline.Point[FFlowline.nS-1].Z
                          -FFlowline.Point[FFlowline.nS-2].Z );
               Endpoint.Y:=FFlowline.Point[FFlowline.nS-2].Y
                        +( FFlowline.Point[FFlowline.nS-1].Y
                          -FFlowline.Point[FFlowline.nS-2].Y )
                        *( WlHeight
                          -FFlowline.Point[FFlowline.nS-2].Z )
                        /( FFlowline.Point[FFlowline.nS-1].Z
                          -FFlowline.Point[FFlowline.nS-2].Z );
               EndPoint.Z:=wlHeight;
               FFlowline.Point[FFlowline.nS-1]:=EndPoint;
            end else break;
         end;
      end; Points.Destroy;
   end;
   Faces.Destroy;
   FBuild:=True;
end;

procedure TFlowline.SaveBinary(Destination:TFileBuffer);
var I:Integer;
begin
   Destination.Add(FProjectionPoint.X);
   Destination.Add(FProjectionPoint.Y);
   Destination.Add(Ord(FProjectionView));
   Destination.Add(FBuild);
   Destination.Add(Selected);
   Destination.Add(FFlowline.nS);
   for I:=1 to FFlowline.nS do begin
      Destination.Add(FFlowline.Point[I-1]);
      Destination.Add(FFlowline.Knuckle[I-1]);
   end;
end;
{
   TVisibility
   This object stores all visibility options for the hull
}
procedure TVisibility.SetCurvatureScale( Val:Real );
var I:Integer;
begin Sp.CurvatureScale:=Val;
      Owner.FileChanged:=True;
      for I:=1 to Owner.nV do
       if Owner.Viewport[I-1].ViewportMode=vmWireFrame then
          Owner.Viewport[I-1].Refresh
end;

procedure TVisibility.FSetCursorIncrement(val:Real);
begin
   if Val<1e-5 then Val:=1e-5;
   if FCursorIncrement<>val then Owner.FileChanged:=True;
   FCursorIncrement:=val;
   if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(self);
end;

procedure TVisibility.FSetModelView(Val:TModelView);
begin
   if Val<>FModelView then begin
      FModelView:=Val;
      Owner.FileChanged:=True;
      Owner.Draw;
   end;
end;

procedure TVisibility.FSetShowInteriorEdges(Val:Boolean);
var I : Integer;
begin
   if Val<>FShowInteriorEdges then begin
      FShowInteriorEdges:=val;
      if not val then for I:=Owner.NoSelectedControlFaces downto 1 do Owner.SelectedControlFace[I-1].Selected:=False;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TVisibility.FSetShowControlNet(Val:Boolean);
var I : Integer;
begin
   if Val<>FShowControlNet then begin FShowControlNet:=val;
      if not FShowControlNet then begin
         for I:=Owner.NoSelectedControlEdges downto 1 do Owner.SelectedControlEdge[I-1].Selected:=False;
         for I:=Owner.NoSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=False;
      end;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TVisibility.FSetShowCurvature(Val:Boolean);
begin
   if Val<>FShowCurvature then begin
      FShowCurvature:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TVisibility.FSetShowGrid(Val:Boolean);
begin
   if Val<>FShowGrid then begin
      FShowGrid:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TVisibility.FSetShowMarkers(Val:Boolean);
var I : Integer;
begin
   if Val<>FShowMarkers then begin
      FShowMarkers:=val;
      Owner.FileChanged:=True;
      if Owner.NoMarkers>0 then
        for I:=1 to Owner.nV do
          if Owner.Viewport[I-1].Zoom=1.0 then Owner.Viewport[I-1].ZoomExtents
                                          else Owner.Viewport[I-1].Refresh;
   end;
end;

procedure TVisibility.FSetShowNormals(Val:Boolean);
begin
   if Val<>FShowNormals then begin
      FShowNormals:=val;
      Owner.FileChanged:=True;
      if Owner.NoSelectedControlFaces>0 then Owner.Redraw;
   end;
end;

procedure TVisibility.FSetShowStations(Val:Boolean);
begin
   if Val<>FShowStations then begin
      FShowStations:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TVisibility.FSetShowButtocks(Val:Boolean);
begin
   if Val<>FShowButtocks then begin
      FShowButtocks:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TVisibility.FSetShowDiagonals(Val:Boolean);
begin
   if Val<>FShowDiagonals then begin
      FShowDiagonals:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TVisibility.FSetShowFlowlines(Val:Boolean);
begin
   if Val<>FShowFlowlines then begin
      FShowFlowlines:=val;
      if not FShowFlowlines then Owner.FSelectedFlowlines.Clear;
      Owner.FileChanged:=True;
      if Owner.NoFlowLines>0 then Owner.Redraw;
   end;
end;

procedure TVisibility.FSetShowWaterlines(Val:Boolean);
begin
   if Val<>FShowWaterlines then begin
      FShowWaterlines:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TVisibility.FSetShowControlCurves(Val:Boolean);
var I:Integer;
begin
   if val<>FShowControlCurves then begin
      FShowControlCurves:=Val;
      if not val then for I:=Owner.Surface.NoControlCurves downto 1 do Owner.Surface.ControlCurve[I-1].Selected:=False;
      if Owner.Surface.NoControlCurves>0 then Owner.Redraw;
      Owner.Filechanged:=true;
   end;
end;

procedure TVisibility.FSetShowHydrostaticData(Val:Boolean);
begin
   if val<>FShowHydrostaticData then begin
      FShowHydrostaticData:=Val;
      Owner.Filechanged:=true;
      Owner.Redraw;
   end;
end;

constructor TVisibility.Create(Owner:TShip);
begin
   inherited Create;
   FOwner:=Owner;
   Clear;
end;

procedure TVisibility.Clear;
begin
   FModelView:=mvPort;
   FShowInteriorEdges:=False;
   FShowControlNet:=True;
   FShowGrid:=True;
   FShowNormals:=True;
   FShowStations:=True;
   FShowbuttocks:=True;
   FShowWaterlines:=True;
   FShowDiagonals:=True;
   FShowMarkers:=True;
   FShowCurvature:=True;
   FShowControlCurves:=True;
   FCursorIncrement:=0.1;
   FShowHydrostaticData:=true;
   FShowHydrostDisplacement:=true;
   FShowHydrostLateralArea:=true;
   FShowHydrostSectionalAreas:=true;
   FShowHydrostMetacentricHeight:=true;
   FShowHydrostLCF:=True;
   FShowFlowlines:=True;
   if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(self);
end;

procedure TVisibility.DecreaseCurvatureScale;
    begin SetCurvatureScale( Sp.CurvatureScale/1.2 ); end;
procedure TVisibility.IncreaseCurvatureScale;
    begin SetCurvatureScale( Sp.CurvatureScale*1.2 ); end;

procedure TVisibility.LoadBinary(Source:TFilebuffer);
var I : Integer;
begin
   Clear;
   Source.LoadInteger(I);
   FModelView:=TModelView(I);
   Source.LoadBoolean(FShowControlNet);
   Source.LoadBoolean(FShowInteriorEdges);
   Source.LoadBoolean(FShowStations);
   Source.LoadBoolean(FShowButtocks);
   Source.LoadBoolean(FShowWaterlines);
   Source.LoadBoolean(FShowNormals);
   Source.LoadBoolean(FShowGrid);
   Source.LoadBoolean(FShowDiagonals);
   Source.LoadBoolean(FShowMarkers);
   Source.LoadBoolean(FShowCurvature);
   Source.LoadTFloatType(Sp.CurvatureScale);
   if Owner.FileVersion>=fv195 then begin
      Source.LoadBoolean(FShowControlCurves);
      if Owner.FileVersion>=fv210 then begin
         Source.LoadTFloatType(FCursorIncrement);
         if abs(FCursorIncrement)<1e-5 then FCursorIncrement:=0.1;
         if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(self);
         if Owner.FileVersion>=fv220 then begin
            Source.LoadBoolean(FShowHydrostaticData);
            Source.LoadBoolean(FShowHydrostDisplacement);
            Source.LoadBoolean(FShowHydrostLateralArea);
            Source.LoadBoolean(FShowHydrostSectionalAreas);
            Source.LoadBoolean(FShowHydrostMetacentricHeight);
            Source.LoadBoolean(FShowHydrostLCF);
            if Owner.FileVersion>=fv250 then begin
               Source.LoadBoolean(FShowFlowlines);
            end;
         end;
      end;
   end;
end;

procedure TVisibility.SaveBinary(Destination:TFileBuffer);
begin
   Destination.Add(Ord(FModelView));
   Destination.Add(FShowControlNet);
   Destination.Add(FShowInteriorEdges);
   Destination.Add(FShowStations);
   Destination.Add(FShowButtocks);
   Destination.Add(FShowWaterlines);
   Destination.Add(FShowNormals);
   Destination.Add(FShowGrid);
   Destination.Add(FShowDiagonals);
   Destination.Add(FShowMarkers);
   Destination.Add(FShowCurvature);
   Destination.Add(Sp.CurvatureScale);
// if Owner.FileVersion>=fv195 then begin
      Destination.Add(FShowControlCurves);
//    if Owner.FileVersion>=fv210 then begin
         Destination.Add(FCursorIncrement);
//       if Owner.FileVersion>=fv220 then begin
            Destination.Add(FShowHydrostaticData);
            Destination.Add(FShowHydrostDisplacement);
            Destination.Add(FShowHydrostLateralArea);
            Destination.Add(FShowHydrostSectionalAreas);
            Destination.Add(FShowHydrostMetacentricHeight);
            Destination.Add(FShowHydrostLCF);
           {if Owner.FileVersion>=fv250 then} Destination.Add( FShowFlowlines );
//       end;
//    end;
// end;
end;
{
  SEdit
  Container class for all editing commandsns for the hull
}
constructor SEdit.Create( Owner:TShip );
begin inherited Create;
      St:=Owner;
      FRecentFiles:=TStringList.Create;
end;
function SEdit.FGetRecentFile( Index:integer ):string;
   begin Result:=FRecentFiles[index]; end;
function SEdit.FGetRecentFileCount:integer;
   begin Result:=FRecentFiles.Count; end;

// Takes a filename and adds it to the list with recent files
procedure SEdit.AddToRecentFiles(Filename:String);
var I,Index: integer; AlreadyPresent: Boolean; Tmp {#,Ext}: String;
begin
   AlreadyPresent:=false;
//# Ext:=Uppercase(ExtractFileExt(Filename));
//# Tmp:=ChangeFileExt(Filename,'');
//# Tmp:=Trim(Tmp);
   Tmp:=Trim( Filename );
   for I:=1 to FRecentFiles.Count do
   if FRecentFiles[I-1] = Tmp then begin Index:=I-1;
// if Uppercase(FRecentFiles[I])=Uppercase(Tmp) then begin Index:=I-1;
      AlreadyPresent:=True; // if not add the front of the list then move to the front;
      if Index<>0 then begin
         FRecentFiles.Delete(Index);
         FRecentFiles.Insert(0,Tmp);
      end;
   end;
   if not AlreadyPresent then begin // file not yet in the list, add at the front
      if FRecentFiles.Count=0 then FRecentFiles.Add(Tmp)
                              else FRecentFiles.Insert(0,Tmp);
   end;                          // delete items until no more than 10 are left
   while FRecentFiles.Count>MaxRecent do FRecentFiles.Delete(FRecentFiles.Count-1);
   if assigned(St.FOnUpdateRecentFileList) then St.FOnUpdateRecentFileList(self);
end;

// Delete the backgrundimage associated with this view
procedure SEdit.BackgroundImage_Delete( Viewport:TViewport );
var I:Integer;
begin
   if MessageDlg(Userstring(68),mtConfirmation,[mbYes,mbNo],0)=mrYes then begin
      for I:=St.NoBackgroundImages downto 1 do
      if St.BackgroundImage[I-1].AssignedView=Viewport.ViewType then begin
         St.BackgroundImage[I-1].Destroy;
         St.FBackgroundImages.Delete(I-1);
         St.FileChanged:=True;
         break;
      end;
      for I:=1 to St.nV do
      if St.Viewport[I-1].ViewType=Viewport.ViewType then begin
         St.Viewport[I-1].BackgroundImage.Clear;
         St.Viewport[I-1].Refresh;
      end;
   end;
end;

// browse for and open a backgroundimage
procedure SEdit.BackgroundImage_Open(Viewport:TViewport);
var I     : Integer;
    Data  : TbackgroundImagedata;
    Dialog: TOpenDialog;
    Pt    : TPoint;
    P2D   : Place;
    Bmp   : TBitmap;
begin
   Data:=nil;
   for I:=1 to St.NoBackgroundImages do
     if St.BackgroundImage[I-1].AssignedView=Viewport.ViewType
      then Data:=St.BackgroundImage[I-1];
   if Data<>nil then begin
      if MessageDlg( Userstring(69)+EOL+Userstring(70),
         mtConfirmation,[mbYes,mbNo],0 )=mrNo then exit;
   end;
   Dialog:=TOpenDialog.Create(Viewport);
   Dialog.InitialDir:=St.Preferences.ImportDirectory;
   Dialog.Filter:='All files [*.jpg;*.bmp]|*.jpg; *.bmp|Jpeg images [*.jpg]|*.jpg|Bitmap files [*.bmp]|*.bmp|';
   Dialog.Options:=[ofHideReadOnly];
   if Dialog.Execute then begin
      if Data=nil then begin
         Data:=TBackgroundImageData.Create(St);
         St.FBackgroundImages.Add(Data);
      end;
      Data.Clear;
      if Uppercase(ExtractFileExt(Dialog.Filename))='.JPG' then begin
         Data.FImageData.LoadFromFile(Dialog.FileName);
         Data.FQuality:=Data.FImageData.CompressionQuality;
      end else begin
         Bmp:=TBitmap.Create;
         Bmp.LoadFromFile(Dialog.Filename);
         Data.FImageData.Assign(Bmp);
         Bmp.Destroy;
         Data.FQuality:=100;
      end;
      if not Data.FImageData.Empty then begin
         Data.FAssignedView:=Viewport.ViewType;
         Data.FOrigin.X:=0;
         Data.FOrigin.Y:=Data.FImageData.Height;
         if St.NoBackgroundImages>1 then begin // use same scale as previous images
            Data.FScale:=St.BackgroundImage[St.NoBackgroundImages-2].FScale;
         end else begin                                      // calculate scale
            Pt:=Viewport.Project(ZERO);
            Pt.X:=Viewport.ClientWidth;
            P2D:=Viewport.ProjectBackTo2D(Pt);
            Data.FScale:=P2D.X/Data.FImageData.Width;
         end;
         Data.UpdateViews;
      end;
      St.FileChanged:=true;
   end;
   Dialog.Destroy;
end;

// Add (a) new controlcurve(s)
procedure SEdit.Curve_Add;
var Edges,SortedEdges,Points: TFasterList; Edge: SControlEdge;
    Point: SPoint; Curve: SControlCurve;
    I,J: Integer;
begin
   Edges:=TFasterList.Create;
   Edges.Capacity:=St.NoSelectedControlEdges;
   for I:=1 to St.NoSelectedControlEdges do begin
      Edge:=St.SelectedControlEdge[I-1];
      if Edge.Curve=nil then Edges.Add(Edge);
   end;
   if Edges.Count>0 then begin
      Self.CreateUndoObject(Userstring(72),True);
      SortedEdges:=TFasterList.Create;
      St.Surface.IsolateEdges(Edges,SortedEdges);
      for I:=1 to SortedEdges.Count do begin
         Points:=SortedEdges[I-1];
         if Points.Count>1 then begin
            Curve:=SControlCurve.Create(St.Surface);
            St.Surface.AddControlCurve(Curve);
            for J:=1 to Points.Count do begin
               Point:=Points[J-1];
               Curve.AddPoint(Point);
               if J>1 then begin
                  Edge:=Curve.Owner.EdgeExists(Curve.ControlPoint[J-2],Curve.ControlPoint[J-1]) as SControlEdge;
                  if Edge<>nil then begin
                     Edge.Curve:=Curve;
                     Edge.Curve.Selected:=true;
                  end;
               end;
            end;
         end;
         Points.Destroy;
      end;
      for I:=St.NoSelectedControlEdges downto 1 do begin
         Edge:=St.SelectedControlEdge[I-1];
         Edge.Selected:=False;
      end;
      SortedEdges.Destroy;
      if St.Visibility.ShowControlCurves=false
         then St.Visibility.ShowControlCurves:=True
         else St.Redraw;
      St.FileChanged:=True;
      if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
   end;
   Edges.Destroy;
end;

destructor SEdit.Destroy;
     begin FRecentFiles.Destroy; Inherited Destroy; end;

// Remove an edge by replacing the two connected faces by one controlface
procedure SEdit.Edge_Collapse;
var I,K,N: integer; Edge: SControlEdge; Undo: TUndoObject;
begin N:=0; K:=0;
   Undo:=CreateUndoObject(Userstring(73),False);
   while St.NoSelectedControlEdges>K do begin  // на выход с высшим контролем
      I:=St.NoSelectedControlEdges;
      Edge:=St.SelectedControlEdge[K];
      Edge.Collapse;
      if I=St.NoSelectedControlEdges then inc( K )  // нет слияния - пропуск
                                     else inc( N );
   end;
   if N>0 then begin
      Undo.Accept;
      St.Build:=false;
      St.Redraw;
      St.FileChanged:=True;
      if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;

// Create a new edge by connection two controlpoints belonging to the same controlface
procedure SEdit.Edge_ConnectE;
  var Undo: TUndoObject; N: integer; // здесь только фиксация
begin
   N:=St.Surface.NoControlEdges; Undo:=CreateUndoObject(Userstring(74),False);
      St.Surface.Edge_Connect;
   if St.Surface.NoControlEdges>N then begin Undo.Accept;
      St.FileChanged:=True;
      St.Build:=false;
      St.Redraw;
      if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;

// Switch selected edges between normal or crease edges (knuckle lines)
procedure SEdit.Edge_Crease;
var I    : integer;
begin
   CreateUndoObject(Userstring(75),True);
   for I:=St.NoSelectedControlEdges downto 1 do St.SelectedControlEdge[I-1].Crease:=not St.SelectedControlEdge[I-1].Crease;
   St.Build:=False;
   St.Redraw;
   St.FileChanged:=True;
end;

// Create new controlfaces by extruding selected boundary edges (eg edges with only 1 controlface connected to it)
procedure SEdit.Edge_Extrude;
var Dialog  : TExtrudeDialog;
    Edge    : SControledge;
    Ve      : Vector;
    Edges   : TFasterList;
    I       : integer;
    Str     : string;
    Undo    : TUndoObject;
begin
   Dialog:=TExtrudeDialog.Create(St);
   ShowTranslatedValues(Dialog);
   Dialog.XValue:=0.0;
   Dialog.YValue:=0.0;
   Dialog.ZValue:=0.0;
   Str:=LengthStr(St.ProjectSettings.ProjectUnits);
   if Dialog.Execute(Str) then
   begin
      Undo:=CreateUndoObject(Userstring(76),False);
      Ve.X:=Dialog.XValue;
      Ve.Y:=Dialog.YValue;
      Ve.Z:=Dialog.ZValue;
      // Assemble edges in a list
      Edges:=TFasterList.Create;
      for I:=St.NoSelectedControlEdges downto 1 do begin
         Edge:=St.Surface.SelectedControlEdge[I-1]; // only boundary edges are allowed!!
         if Edge.NoFaces=1 then Edges.Add(Edge);
         Edge.Selected:=False;
      end;
      if Edges.Count>0 then begin
         St.Surface.ExtrudeEdges(Edges,Ve); // New edges are returned in the edges-list, select them
         for I:=1 to Edges.Count do begin
            Edge:=Edges[I-1];
            Edge.Selected:=True;
         end;
         Undo.Accept;
         St.Build:=False;
         St.FileChanged:=true;
         St.Redraw;
         if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
      end else begin
         ShowMessage( Userstring(77) ); Undo.Delete;
      end;
      Edges.Destroy;
   end;
   Dialog.Destroy;
end;

// Create new controlpoints by splitting an controledge into two.
procedure SEdit.Edge_Split;
var I,N  : integer;
    Edge : SControlEdge;
    Point,Last : SControlPoint;
    Undo : TUndoObject;
begin
   N:=0;
   Last:=nil;
   Undo:=CreateUndoObject(Userstring(78),false);
   for I:=St.NoSelectedControlEdges downto 1 do begin
      Edge:=St.Surface.SelectedControlEdge[I-1];
      Edge.Selected:=False;
      Point:=Edge.InsertControlPoint(MidPoint(Edge.StartPoint.Coordinate,Edge.EndPoint.Coordinate));
      if Point<>nil then begin
         Point.Selected:=True;
         Last:=Point;
         inc(N);
      end;
   end;
   if Last<>nil then St.ActiveControlPoint:=Last;
   if N>0 then begin
      Undo.Accept;
      St.Build:=False;
      St.FileChanged:=True;
      St.Redraw;
      if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;

procedure SEdit.Face_Assemble;
var Assembled        : TFaceArray;
    NAssembled,I,J,K : Integer;
    Layers           : TFasterList;
    AssFace          : TFaceGrid;
    Layer            : SLayer;
    Face             : SControlFace;
begin
   Layers:=TFasterList.Create;
   for I:=1 to St.Surface.NoLayers do begin
      Layers.Add(St.Surface.Layer[I-1]);
   end;
   St.Visibility.ShowInteriorEdges:=True;
   St.Surface.AssembleFacesToPatches(Layers,amNurbs,Assembled,NAssembled);
   if NAssembled>0 then begin               // assign all patches to new layers
      for I:=1 to NAssembled do begin
         Layer:=St.Surface.AddNewLayer;
         Layer.Color:=RandomColor;
         AssFace:=Assembled[I-1];
         for J:=1 to AssFace.NRows do begin
            for K:=1 to AssFace.NCols do begin
               Face:=AssFace.Faces[J-1][K-1];
               if Face<>nil then Face.Layer:=Layer;
            end;
         end;
      end;
      Layer_DeleteEmpty(True);
      St.Redraw;
      Showmessage('Assembled '+IntToStr(NAssembled)+' patches');
   end;
   Layers.Destroy;
end;

// Deletes all faces on the starboardside of the hull
procedure SEdit.Face_DeleteNegative;
var
  IsPlus,isZero,isMinus: Boolean; Str: String;
  I,J,RemovedF,RemovedP: integer; P3D: Vector;
  Face: SControlFace;
  Point: SControlPoint;
  PrevCursor: TCursor;
  vUndo: TUndoObject;
begin
  RemovedF:=0;
  RemovedP:=0;
  PrevCursor:=Screen.Cursor;
  Screen.Cursor:=crHourglass;
  vUndo:=CreateUndoObject( 'DelRight',False );                     /// 1e-7
  //
  //  приведение к диметральной плоскости правых отрицательных точек
  //
  for I:=St.Surface.NoControlFaces-1 downto 0 do begin
    isPlus:=false; isMinus:=false; isZero:=false;
    Face:=St.Surface.ControlFace[I];
    if face.Nopoints>2 then                   // точки и линии удаляются
    for J:=0 to Face.Nopoints-1 do begin P3D:=Face.Point[J].Coordinate;
      if P3D.Y>0 then IsPlus:=true else
      if P3D.Y<0 then IsMinus:=true else isZero:=true;
    end;
    if not IsPlus then begin Face.SelDeleteFace; Inc( RemovedF ); end; // else
  end;
  //
  //  расчистка всех точек, не привязанных к треугольникам
  //
  for I:=St.Surface.NoControlPoints-1 downto 0 do begin
    Point:=St.Surface.ControlPoint[I];
    if Point.Coordinate.Y<0 then begin Inc( RemovedP );                                    // -1e-4
       if Point.NoFaces=0 then Point.SelDeletePoint else begin
          P3D:=Point.Coordinate; P3D.Y:=0.0; // Point.Coordinate:=P3D;
          St.Surface.ControlPoint[I].Coordinate:=P3D;
       end;
    end;
  end;
  //
  //  справка по успешным результатам
  //
  if (RemovedF+RemovedP)>0 then begin Str:='';
    if RemovedF>0 then Str:=Str+IntToStr(RemovedF)+#32+Userstring(80);
    if RemovedP>0 then begin if Str<>'' then Str:=Str+EOL;
       Str:=Str+IntToStr(RemovedP)+#32+Userstring(81);
    end;
    ShowMessage( Str ); vUndo.Accept;
    St.FileChanged:=True;
    St.Build:=False;
    St.RebuildModel;
    if Assigned( St.OnUpdateGeometryInfo ) then
                 St.OnUpdateGeometryInfo( self );
  end else begin
    ShowMessage( Userstring(82) ); vUndo.Delete;
  end;
  Screen.Cursor:=PrevCursor;
end;

// Inverts the normal-direction of all selected controlfaces

procedure SEdit.Face_Flip; var I:integer;
begin
   CreateUndoObject(Userstring(83),true);
   for I:=1 to St.NoSelectedControlFaces do St.SelectedControlFace[I-1].FlipNormal;
   St.Build:=False;
   St.FileChanged:=True;
   St.Redraw;
end;

// Mirrors all selected faces in a 3D plane

procedure SEdit.Face_MirrorPlane;
var I,J,Index     : Integer;
    Vertices,Points,Faces: TFasterList;
    MirrorPlane   : Plate;
    Face,NewFace  : SControlface;
    P1,P2         : SControlPoint;
    Edge1,Edge2   : SEdge;
    PrevCursor    : TCursor;
    Dialog        : TMirrorPlaneDialog;
    SelectDlg     : TSelectLayersDialog;
begin
   Faces:=TFasterList.Create;
   if St.NoSelectedControlFaces=0 then begin
      SelectDlg:=TSelectLayersDialog.Create(St);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(St,fsFaces)
      then SelectDlg.ExtractSelectedFaces(Faces)
      else begin
         for I:=St.NoSelectedControlFaces downto 1 do
                St.SelectedControlFace[I-1].Selected:=false;
         St.Redraw;
      end;
      SelectDlg.Destroy;
   end else begin
      Faces.Capacity:=Faces.Count+St.NoSelectedControlFaces;
      for I:=1 to St.NoSelectedControlFaces do Faces.Add(St.SelectedControlFace[I-1]);
   end;
   if Faces.Count>0 then begin
      Dialog:=TMirrorPlaneDialog.Create(St);
      ShowTranslatedValues(Dialog);
      if Dialog.Execute then begin
         Mirrorplane:=Dialog.Plane;
         CreateUndoObject(Userstring(84),True);
         PrevCursor:=Screen.Cursor;
         Screen.Cursor:=crHourglass;                     // assemble all points
         Vertices:=TFasterlist.Create;
         Vertices.Capacity:=4*Faces.Count;
         for I:=1 to Faces.Count do begin
            Face:=Faces[I-1];
            for J:=1 to Face.Nopoints do begin
               P1:=Face.Point[J-1] as SControlPoint;
               if Vertices.SortedIndexOf(P1)=-1 then Vertices.AddSorted(P1);
            end;
         end;                         // Create all the mirrored control points
         for I:=1 to Vertices.Count do begin P1:=Vertices[I-1];
            if not Dialog.CheckBox1.Checked then  begin
            // Do NOT try to connect the points to any existing point create always a new point
               P2:=SControlPoint.Create(P1.Owner);
               P1.Owner.AddControlPoint(P2);
               P2.Coordinate:=Geometry.MirrorPlane(P1.Coordinate,MirrorPlane);
            end else begin    // Try to connect ALL new points to existing ones
               P2:=P1.Owner.AddControlPoint(Geometry.MirrorPlane(P1.Coordinate,MirrorPlane));
            end;
            Vertices.Objects[I-1]:=P2;
         end;                                 // now create the controlfaces
         Points:=TFasterList.Create;
         for I:=1 to Faces.Count do begin
            Face:=Faces[I-1];
            Points.Clear;
            Points.Capacity:=Face.Nopoints;
            for J:=Face.Nopoints downto 1 do begin
               P1:=Face.Point[J-1] as SControlPoint;
               Index:=Vertices.SortedIndexOf(P1);
               if Index<>-1 then begin
                  P2:=Vertices.Objects[index];
                  Index:=Points.IndexOf(P2);
                  if Index=-1 then Points.Add(P2);
               end; // else Raise Exception.Create(Userstring(85));
            end;
            if Points.Count>2 then begin
               NewFace:=Face.Owner.AddControlFace(Points,False);
               if Newface<>nil then NewFace.Layer:=Face.Layer;
            end;
         end;
         Points.Destroy;             // Now check all edges for crease edges
         for I:=1 to Vertices.Count do begin
            P1:=Vertices[I-1];
            for J:=1 to P1.NoEdges do begin
               Edge1:=P1.Edge[J-1];
               if Edge1.StartPoint=P1
                  then P2:=Edge1.EndPoint as SControlPoint
                  else P2:=Edge1.StartPoint as SControlPoint;
               Index:=Vertices.SortedIndexOf(P2);
               if Index<>-1 then begin // Edge is part of the selected faces
                  Edge2:=St.Surface.EdgeExists(Vertices.Objects[I-1],Vertices.Objects[index]);
                  if (Edge2<>nil) and (Edge2<>Edge1) then
                      Edge2.Crease:=Edge1.Crease;
               end;
            end;
         end;
         // Copy cornerpoint and locked ststus that might be lost in the edge-setting process
         for I:=1 to Vertices.Count do begin
            P1:=Vertices[I-1];
            P2:=Vertices.Objects[I-1];
            if P2<>P1 then begin
               if P1.VertexType=svCorner then P2.VertexType:=P1.VertexType;
               P2.Locked:=P1.Locked;
            end;
         end;
         Vertices.Destroy;
         for I:=St.NoSelectedControlFaces downto 1 do St.SelectedControlFace[I-1].Selected:=False;
         St.Build:=False;
         St.Draw;
         if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
         Screen.Cursor:=PrevCursor;
      end;
      Dialog.Destroy;
   end;
   Faces.Destroy;
end;

procedure SEdit.Face_Rotate;
var I,J,Nlocked: Integer;
    Points     : TFasterList;
    PrevCursor : TCursor;
    SelectDlg  : TSelectLayersDialog;
    Point      : SControlPoint;
    Proceed    : Boolean;
    Dialog     : TRotateDialog;
    SinX,CosX, SinY,CosY, SinZ,CosZ: Real;
    Marker     : TMarker;
begin
   Points:=TFasterList.Create;
   if St.ActiveControlPoint<>nil then Points.Add(St.ActiveControlPoint);
   St.Surface.ExtractPointsFromSelection(Points,NLocked);
   if Points.Count=0 then begin
      SelectDlg:=TSelectLayersDialog.Create(St);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(St,fsPoints)
      then SelectDlg.ExtractSelectedPoints(Points)
      else begin
         for I:=St.NoSelectedControlPoints downto 1
          do St.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to St.nV do St.Viewport[I-1].Refresh;
      end;
      SelectDlg.Destroy;
   end;
   if Points.Count>0 then begin
      if NLocked>0 then begin
         Proceed:=MessageDlg(Userstring(86)+EOL+
                             Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
      end else Proceed:=True;
      if Proceed then begin
         Dialog:=TRotateDialog.Create(St);
         ShowTranslatedValues(Dialog);
         Dialog.XValue:=0.0;
         Dialog.YValue:=0.0;
         Dialog.ZValue:=0.0;
         if Dialog.Execute(Userstring(88),'[°]') then begin
            CreateUndoObject(Userstring(89),true);
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourGlass;
            CosX:=Cos(DegToRad(Dialog.XValue));
            SinX:=Sin(DegToRad(Dialog.XValue));
            CosY:=Cos(DegToRad(Dialog.YValue));
            SinY:=Sin(DegToRad(Dialog.YValue));
            CosZ:=Cos(DegToRad(Dialog.ZValue));
            SinZ:=Sin(DegToRad(Dialog.ZValue));
            for I:=1 to Points.Count do begin Point:=Points[I-1];
               if not Point.Locked then begin
                  Point.Coordinate:=RotateVector(Point.Coordinate,SinX,CosX,SinY,CosY,SinZ,CosZ);
               end;
            end;
            if Points.Count=St.Surface.NoControlPoints
            then if St.AdjustMarkers then begin
               for I:=1 to St.NoMarkers do begin
                  Marker:=St.Marker[I-1];
                   for J:=1 to Marker.nS
                   do Marker.Point[J-1]:=RotateVector(Marker.Point[J-1],SinX,CosX,SinY,CosY,SinZ,CosZ);
               end;
            end;
            St.Build:=False;
            St.Redraw;                           // Refresh controlpoint data
            if Points.SortedIndexOf(St.ActiveControlPoint)<>-1
               then St.ActiveControlPoint:=St.ActiveControlPoint;
            Screen.Cursor:=PrevCursor;
         end else begin
            for I:=St.NoSelectedControlPoints downto 1 do St.SelectedControlPoint[I-1].Selected:=false;
            for I:=1 to St.nV do St.Viewport[I-1].Refresh;
         end;
         Dialog.Destroy;
      end else begin
         for I:=St.NoSelectedControlPoints downto 1
          do St.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to St.nV do St.Viewport[I-1].Refresh;
      end;
   end;
   Points.Destroy;
end;

procedure SEdit.Face_Scale;
var I,Nlocked : Integer;
    Points    : TFasterList;
    PrevCursor: TCursor;
    SelectDlg : TSelectLayersDialog;
    Point     : SControlPoint;
    Dialog    : TRotateDialog;
    Scale,NewP: Vector;
    Markers,Proceed: Boolean;
begin
   Points:=TFasterList.Create;
   if St.ActiveControlPoint<>nil then Points.Add(St.ActiveControlPoint);
   St.Surface.ExtractPointsFromSelection(Points,NLocked);
   if Points.Count=0 then begin
      SelectDlg:=TSelectLayersDialog.Create(St);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(St,fsPoints)
      then SelectDlg.ExtractSelectedPoints(Points)
      else begin
         for I:=St.NoSelectedControlPoints downto 1
           do St.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to St.nV do St.Viewport[I-1].Refresh;
      end;
      SelectDlg.Destroy;
   end;
   if Points.Count>0 then begin
      if NLocked>0 then begin
         Proceed:=MessageDlg(Userstring(86)+EOL+
                             Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
      end else Proceed:=True;
      if Proceed then begin
         Dialog:=TRotateDialog.Create(St);
         ShowTranslatedValues(Dialog);
         Dialog.XValue:=1.0;
         Dialog.YValue:=1.0;
         Dialog.ZValue:=1.0;
         if Dialog.Execute(Userstring(90),'') then begin
            CreateUndoObject(Userstring(91),true);
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourGlass;
            Scale.X:=Dialog.XValue;
            Scale.Y:=Dialog.YValue;
            Scale.Z:=Dialog.ZValue;
            if Points.Count=St.Surface.NoControlPoints then begin // Scale the entire model
               Markers:=St.AdjustMarkers;
               Model_Scale(Scale,False,Markers);
            end else begin // only a selected part of the model must be scaled
               for I:=1 to Points.Count do begin
                  Point:=Points[I-1];
                  if not Point.Locked then begin
                     NewP.X:=Scale.X*Point.Coordinate.X;
                     NewP.Y:=Scale.Y*Point.Coordinate.Y;
                     NewP.Z:=Scale.Z*Point.Coordinate.Z;
                     Point.Coordinate:=NewP;
                  end;
               end;
               St.Build:=False;
               St.Redraw;
            end;                                   // Refresh controlpoint data
            if Points.SortedIndexOf(St.ActiveControlPoint)<>-1
              then St.ActiveControlPoint:=St.ActiveControlPoint;
            Screen.Cursor:=PrevCursor;
         end else begin
            for I:=St.NoSelectedControlPoints downto 1 do St.SelectedControlPoint[I-1].Selected:=false;
            for I:=1 to St.nV do St.Viewport[I-1].Refresh;
         end;
         Dialog.Destroy;
      end else begin
         for I:=St.NoSelectedControlPoints downto 1 do St.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to St.nV do St.Viewport[I-1].Refresh;
      end;
   end;
   Points.Destroy;
end;

procedure SEdit.Face_Move;
var I,J,Nlocked: Integer;
    Points     : TFasterList;
    PrevCursor : TCursor;
    SelectDlg  : TSelectLayersDialog;
    Point      : SControlPoint;
    Proceed    : Boolean;
    Dialog     : TRotateDialog;
    P,Translate: Vector;
    Marker     : TMarker;
begin
   Points:=TFasterList.Create;
   if St.ActiveControlPoint<>nil then Points.Add(St.ActiveControlPoint);
   St.Surface.ExtractPointsFromSelection(Points,NLocked);
   if Points.Count=0 then begin
      SelectDlg:=TSelectLayersDialog.Create(St);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(St,fsPoints)
      then SelectDlg.ExtractSelectedPoints(Points)
      else begin
         for I:=St.NoSelectedControlPoints downto 1 do St.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to St.nV do St.Viewport[I-1].Refresh;
      end;
      SelectDlg.Destroy;
   end;
   if Points.Count>0 then begin
      if NLocked>0 then begin
         Proceed:=MessageDlg(Userstring(86)+EOL+
                             Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
      end else Proceed:=True;
      if Proceed then begin
         Dialog:=TRotateDialog.Create(St);
         ShowTranslatedValues(Dialog);
         Dialog.XValue:=0.0;
         Dialog.YValue:=0.0;
         Dialog.ZValue:=0.0;
         if Dialog.Execute(Userstring(92),LengthStr(St.ProjectSettings.ProjectUnits))
         then begin
            CreateUndoObject(Userstring(93),true);
            Translate.X:=Dialog.XValue;
            Translate.Y:=Dialog.YValue;
            Translate.Z:=Dialog.ZValue;
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourGlass;
            for I:=1 to Points.Count do begin
               Point:=Points[I-1];
               if not Point.Locked then Point.Coordinate:=Point.Coordinate+Translate;
            end;
            if Points.Count=St.Surface.NoControlPoints then begin // Update main dimensions
               if not St.ProjectSettings.UseMidleFrame then
                  St.ProjectSettings.MidleFrame:=St.ProjectSettings.MidleFrame+Translate.X; // Update stations, buttcks and waterlines
               for I:=1 to St.NoStations do St.Station[I-1].FPlane.d:=St.Station[I-1].FPlane.d-Translate.X;
               for I:=1 to St.NoButtocks do St.Buttock[I-1].FPlane.d:=St.Buttock[I-1].FPlane.d-Translate.Y;
               for I:=1 to St.NoWaterlines do St.Waterline[I-1].FPlane.d:=St.Waterline[I-1].FPlane.d-Translate.Z;
{              for I:=0 to St.NoFlowlines-1 do with St.Flowline[I] do begin
                 FProjectionPoint.X := FProjectionPoint.X + Translate.X;
                 FProjectionPoint.Y := FProjectionPoint.Y + Translate.Z;
                 for J:=0 to FFlowline.nS-1 do begin
                   P:=FFlowline.Point[J]; P+=Translate; FFlowline.Point[J]:=P;
                 end; ReBuild;
               end;                                // Refresh controlpoint data
}
               if St.AdjustMarkers then                     // Update markers
               for I:=1 to St.NoMarkers do begin
                  Marker:=St.Marker[I-1];
                  for J:=1 to Marker.nS do begin
                     Marker.Point[J-1]:=Marker.Point[J-1]+Translate;
                  end;
               end;
            end;
            St.Build:=False;
            for I:=0 to St.NoFlowlines-1 do with St.Flowline[I] do begin
              FProjectionPoint.X := FProjectionPoint.X + Translate.X;
              FProjectionPoint.Y := FProjectionPoint.Y + Translate.Z;
              for J:=0 to FFlowline.nS-1 do begin
                P:=FFlowline.Point[J]; P+=Translate; FFlowline.Point[J]:=P;
              end; // или так? = FFlowline.ReBuild;
            end;
//          St.ReBuildModel;
            St.Redraw;                           // Refresh controlpoint data
            Screen.Cursor:=PrevCursor;
            if Points.SortedIndexOf(St.ActiveControlPoint)<>-1
               then St.ActiveControlPoint:=St.ActiveControlPoint;
         end else begin
            for I:=St.NoSelectedControlPoints downto 1 do St.SelectedControlPoint[I-1].Selected:=false;
            for I:=1 to St.nV do St.Viewport[I-1].Refresh;
         end;
         Dialog.Destroy;
      end else begin
         for I:=St.NoSelectedControlPoints downto 1
          do St.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to St.nV do St.Viewport[I-1].Refresh;
      end;
   end;
   Points.Destroy;
end;

// Creates a new controlface from the currently selected controlpoints
procedure SEdit.Face_New;
var Tmp : TFasterList;
    Face: SControlFace;
    I   : integer;
    Undo: TUndoObject;
begin
   if St.NoSelectedControlPoints>2 then begin
      Tmp:=TFasterList.Create;
      Undo:=CreateUndoObject(Userstring(94),false);
      // Remember the number of faces, edges and points
      // Assemble all points in a temp. list
      for I:=1 to St.Surface.NoSelectedControlPoints
          do Tmp.Add(St.Surface.SelectedControlPoint[I-1]);
      // Deselect the controlpoints
      for I:=St.Surface.NoSelectedControlPoints downto 1
          do St.Surface.SelectedControlPoint[I-1].Selected:=False;
      // Add the new face
      Face:=St.Surface.AddControlFace(Tmp,True,St.ActiveLayer);
      if Face<>nil then begin
         Undo.Accept;
         St.Build:=False;
         St.FileChanged:=True;
         St.Redraw;
         if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
      end else Undo.Delete;              // Initialize then new edges and faces
      Tmp.Destroy;
   end else ShowMessage(Userstring(95));
end;

procedure SEdit.Flowline_Add( Source:Place; View:TviewType );
var Flowline: TFlowline; //Undo: TUndoObject;
begin
// Undo:=CreateUndoObject(Userstring(130),False);
   Flowline:=Tflowline.Create; //( St );
   St.FFlowLines.Add( Flowline );
   Flowline.FProjectionPoint:=Source;
   Flowline.FProjectionView:=View;
   Flowline.Rebuild;
   if Flowline.FFlowLine.nS>0 then begin
      St.FileChanged:=True;
//    Undo.Accept;
      St.Redraw;
   end else begin
//    Undo.Delete;
      Flowline.Delete;
   end;
end;

procedure SEdit.Intersection_AddToList(Intersection:TIntersection);
var I,J       : integer;
    TargetList: TFasterList;
    Int1,Int2 : TIntersection;
begin
   Case Intersection.IntersectionType of
      fiStation  : TargetList:=St.FStations;
      fiButtock  : TargetList:=St.FButtocks;
      fiWaterline: TargetList:=St.FWaterlines;
      fiDiagonal : TargetList:=St.FDiagonals;
      else TargetList:=nil;
   end;
   if TargetList<>nil then begin
      TargetList.Add(Intersection); // Now sort the list so that the distance is in ascending order
      for I:=1 to TargetList.Count-1 do begin
         Int1:=TargetList[I-1];
         for J:=I+1 to TargetList.Count do begin
            Int2:=Targetlist[J-1];
            if -Int2.FPlane.d<-Int1.FPlane.d then begin // swap the two intersections
               Targetlist.Exchange(I-1,J-1);
               Int1:=TargetList[I-1];
            end;
         end;
      end;
   end;
end;

// Pops up the dialog in which to add or delete stations, buttocks and waterlines
procedure SEdit.Intersection_Dialog;
var Dialog: TIntersectionDialog;
begin
  Dialog:=St.FIntersectionDialog as TIntersectionDialog;
  ShowTranslatedValues(Dialog);
  Dialog.Execute(St);
  St.FDesignHydrostatics.Calculated:=false;
  if St.Visibility.ShowHydrostaticData then St.Redraw;
end;

// All connected patches surrounded by crease edges are grouped together into a new layer
procedure SEdit.Layer_AutoGroup;
var ToDoList,DoneList,Current: TList;
    I,J       : integer;
    Face,Face2: SControlFace;
    Layer     : SLayer;
    SameLayer : Boolean;

    procedure FindAttachedFaces(List:TList;Face:SControlFace);
    var I,J,Index: integer;
        P1,P2: SPoint;
        Edge: SEdge;
    begin P1:=Face.Point[Face.NoPoints-1];
       for I:=1 to Face.Nopoints do begin P2:=Face.Point[I-1];
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

begin
   ToDoList:=TList.Create;
   DoneList:=TList.Create;
   if St.NoSelectedControlFaces>0 then begin      // Use only the selected ones
      ToDoList.Capacity:=ToDoList.Count+St.NoSelectedControlFaces;
      for I:=1 to St.NoSelectedControlFaces do begin
         Face:=St.SelectedControlFace[I-1];
         ToDoList.Add(Face);
      end;
   end else begin                                      // use all visible faces
      for I:=1 to St.NoLayers do begin
         Layer:=St.Layer[I-1];
         if Layer.Visible then begin
            ToDoList.Capacity:=ToDoList.Count+Layer.Count;
            for J:=1 to Layer.Count do
               ToDoList.Add(Layer.Items[J-1]);
         end;
      end;
   end;
   if ToDoList.Count>0 then begin
      CreateUndoObject(Userstring(139),True);
      while ToDoList.Count>0 do begin
         Face:=ToDoList[ToDoList.Count-1];
         ToDoList.Delete(ToDoList.Count-1);
         Current:=TList.Create;
         Current.Add(Face);
         FindAttachedFaces(Current,Face);
         DoneList.Add(Current);
      end;                             // Assign all groups to different layers
      for I:=1 to DoneList.Count do begin
         Current:=DoneList[I-1];
         if Current.Count>0 then begin
            SameLayer:=True;
              // check if all selected faces currently belong to the same layer
            Face:=Current[0];
            For J:=2 to Current.Count do begin
               Face2:=Current[J-1];
               if Face2.Layer<>Face.Layer then SameLayer:=False;
            end;
            Layer:=nil;
            if SameLayer then begin //# yes, all faces belong to the same layer
               if Current.Count=Face.Layer.Count then begin
               // apparently the same data is selected as in face.layer, do not change layer
               end else begin
               // a subset of face.layer is selected, copy properties from that layer
                  Layer:=St.Surface.AddNewLayer;
                  Layer.AssignProperties(Face.Layer);
                  Layer.Color:=RandomColor;
               end;
            end else begin                  // Faces belong to multiple layers,
               Layer:=Layer_New;
               Layer.Color:=RandomColor;
            end;
            if Layer<>nil then begin
               for J:=1 to Current.Count do begin
                  Face:=Current[J-1];
                  Face.Layer:=Layer;
               end;
            end;
         end;
         Current.Destroy;
      end;
      St.ActiveLayer:=St.Layer[St.NoLayers-1];
   {  Layer_DeleteEmpty(True);               // Delete empty layers
   }  St.Redraw;
      St.FileChanged:=True;
   end;
   if assigned(St.OnChangeLayerData) then St.OnChangeLayerData(self);
   ToDoList.Destroy;
   DoneList.Destroy;
end;

// Develope all developable layers
procedure SEdit.Layer_Develop;
var Layer   : SLayer;
    Patch   : TDevelopedPatch;
    Dlg     : TExpanedplatesDialog;
    Plates  : TFasterList;
    I,J     : integer;
    Prev    : TCursor;
begin
   Prev:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   Plates:=TFasterList.Create; // perform a quiet test to check normal directions
   if not St.ProjectSettings.DisableModelCheck then Model_Check(False);
   for I:=1 to St.NoLayers do begin
      Layer:=St.Layer[I-1];
      if Layer.Developable then begin
         Layer.Unroll(Plates);
      end;
   end;
   for I:=1 to Plates.Count do begin
      Patch:=Plates[I-1];
      for J:=1 to St.NoStations do Patch.IntersectPlane(St.Station[J-1].Plane,St.Station[J-1].Color);
      for J:=1 to St.NoWaterlines do Patch.IntersectPlane(St.Waterline[J-1].Plane,St.Waterline[J-1].Color);
      for J:=1 to St.NoButtocks do Patch.IntersectPlane(St.Buttock[J-1].Plane,St.Buttock[J-1].Color);
      for J:=1 to St.NoDiagonals do Patch.IntersectPlane(St.Diagonal[J-1].Plane,St.Diagonal[J-1].Color);
   end;
   Screen.Cursor:=Prev;
   if Plates.Count>0 then begin
      Dlg:=TExpanedplatesDialog.Create(St);
      ShowTranslatedValues(Dlg);
      Dlg.Execute(St,Plates);
      Dlg.Destroy;
   end;
   for I:=1 to Plates.Count do begin
      Patch:=plates[I-1];
      Patch.Destroy;
   end;
   Plates.Destroy;
end;

// Delete all layers that are empty from the model
procedure SEdit.Layer_DeleteEmpty;
var I,N: integer; Undo: TUndoObject;
begin
   N:=0;
   if Quiet then Undo:=nil
            else Undo:=CreateUndoObject(Userstring(140),false);
   for I:=St.NoLayers downto 1
   do if (St.Layer[I-1].Count=0) and (St.NoLayers>1) then begin
      St.Layer[I-1].Delete;
      inc(N);
      St.FileChanged:=True;
   end;
   if St.ActiveLayer=nil then St.ActiveLayer:=St.Layer[St.NoLayers-1]
                           else St.ActiveLayer:=St.ActiveLayer;
   if (N>0) and (not Quiet) then begin
      Undo.Accept;
      ShowMessage(IntToStr(N)+#32+Userstring(141)+'.');
   end;
   if (N=0) and (Undo<>nil) then Undo.Delete;
end;

// Show layer dialog window
procedure SEdit.Layer_Dialog; var LayerDialog: TLayerDialog;
begin
   LayerDialog:=TLayerDialog.Create(St);
   ShowTranslatedValues(LayerDialog);
   LayerDialog.Execute(St);
   LayerDialog.Free;
end;

function SEdit.Layer_New:SLayer;
begin
   CreateUndoObject(Userstring(142),True);
   Result:=St.Surface.AddNewLayer;
   Result.Color:=Sp.Layer;
   St.FileChanged:=True;
end;

// Adds a marker to the list with markers
procedure SEdit.Marker_Add(Marker:TMarker);
begin
   St.FMarkers.Add(Marker);
   Marker.FOwner:=St;
end;

// Delete all markers from the model
procedure SEdit.Marker_Delete;
var I:Integer;
begin
   if MessageDlg(Userstring(143),mtConfirmation,[mbYes,mbNo],0)=mrYes then
   begin
      CreateUndoObject(Userstring(144),True);
      for I:=1 to St.NoMarkers do St.Marker[I-1].Destroy;
      St.FMarkers.Clear;
      St.FileChanged:=True;
      for I:=1 to St.nV do if St.Viewport[I-1].Zoom=1.0
          then St.Viewport[I-1].ZoomExtents
          else St.Viewport[I-1].Refresh;
   end;
end;

// Import markers from a textfile
procedure SEdit.Marker_Import;
var OpenDialog : TOpenDialog;
    Str        : string;
    I          : integer;
//  LineNr     : Integer;
    P          : Vector;
    FFile      : TextFile;
    Markers    : TFasterList;
    Marker     : TMarker;
    Answer     : word;
    procedure Import(Markers:TFasterList);
    var I: Integer; Marker: TMarker;
    begin
      for I:=1 to Markers.Count do begin
         Marker:=Markers[I-1];
         Marker_Add(Marker);
      end;
      St.FileChanged:=True;
      St.Visibility.ShowMarkers:=True;
      for I:=1 to St.nV
       do if St.Viewport[I-1].Zoom=1.0 then St.Viewport[I-1].ZoomExtents
                                       else St.Viewport[I-1].Refresh;
      St.Redraw;
    end;
begin
   OpenDialog:=TOpenDialog.Create(St);
   OpenDialog.InitialDir:=St.Preferences.ImportDirectory;
   OpenDialog.Filter:='Text files [*.txt]|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      assignFile(FFile,ChangeFileExt(Opendialog.FileName,'.txt'));
      {$I-}Reset(FFile);{$I+}
      if IOResult=0 then begin
         St.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
//       LineNr:=1;                          // skip the first line of the file
         readln(FFile);
         Markers:=TFasterList.Create;
         Marker:=TMarker.Create;
         repeat
            Readln(FFile,Str);
            repeat
               i:=Pos(#9,Str);
               if I<>0 then str[I]:=#32;
            until I=0;
            Str:=Trim(Uppercase(Str));
            if (Str<>'') and (Str<>'EOF') then begin
               P:=GetVector( Str );
               Marker.Add(P);
               Str:=#32;
            end else if Str='' then begin
               if Marker.nS>1 then Markers.Add(Marker)
                              else Marker.Destroy;
               Marker:=TMarker.Create;
            end;
         until (Str='EOF') or (EOF(FFile));
            if Marker.nS>1 then Markers.Add(Marker)
                           else Marker.Destroy;
         CloseFile(FFile);
         if Markers.Count>0 then begin
            if St.NoMarkers>0 then begin
               Answer:=MessageDlg(Userstring(145),mtConfirmation,[mbYes,mbNo,mbCancel],0);
               if Answer<>mrCancel then begin
                  CreateUndoObject(Userstring(146),True);
                  if Answer=mrYes then begin
                     for I:=1 to St.NoMarkers do St.Marker[I-1].Destroy;
                     St.FMarkers.Clear;
                  end;
                  Import(Markers);
               end else begin
                  for I:=1 to Markers.Count do begin
                     Marker:=Markers[I-1];
                     Marker.Destroy;
                  end;
               end;
            end else begin
               CreateUndoObject(Userstring(146),True);
               Import(Markers);
            end;
         end else ShowMessage( Userstring(147) );
         Markers.Destroy;
      end else ShowMessage( Userstring(106) );
   end;
   OpenDialog.Destroy;
end;

// Checks the surface for inconsistent normal directions and leaks
procedure SEdit.Model_Check(ShowResult:Boolean);
const SqError = 1e-8;
var I,J,InvertedFaces,Inconsistent,NonManifold,DblEdges: Integer;
    Point,Pt    : SPoint;
    Face        : SFace;
    Edge1,Edge2 : SControlEdge;
    CtrlFace    : SControlFace;
    CtrlPoint   : SControlPoint;
    AllFaces,NewGroup,DoubleEdges,Points,Leaks: TFasterList;
    Changed,Swap: Boolean;
    Str         : String;
    Undo        : TUndoObject;
    NewLayer    : SLayer;
    Normal,Tmp  : Vector;

    procedure FindConnectedFaces(DoneList,ToDoList:TFasterList);
    var I,J,K,Ind : integer;
        P1,P2     : SPoint;
        Edge      : SEdge;
        F1,F2     : SFace;
    begin
       I:=1;
       while I<=DoneList.Count do begin
          F1:=DoneList[I-1];
          P1:=F1.Point[F1.NoPoints-1];
          for J:=1 to F1.NoPoints do begin
             P2:=F1.Point[J-1];
             Edge:=St.Surface.EdgeExists(P1,P2);
             if Edge<>nil then if Edge.NoFaces>1 then begin
                for K:=1 to Edge.NoFaces do if Edge.Face[K-1]<>F1
                then begin
                   F2:=Edge.Face[K-1];
                   Ind:=ToDoList.SortedIndexOf(F2);
                   if Ind<>-1 then begin
                      // This face is connected to the current, but not present in the done-list.
                      DoneList.Add(F2);
                      ToDoList.Delete(Ind);
                      // Also perform a check to determine if F2 is oriented in
                      // the same way as F1 (clockwise or counterclockwise
                      Ind:=F2.IndexOfPoint(P2);
                      Ind:=(Ind+1) mod F2.NoPoints; // select the next index
                      if F2.Point[ind]=P1 then begin // Direction is OK, do nothing
                      end else begin      // direction is not ok, invert points
                         F2.FlipNormal;
                         inc(Inconsistent);
                      end;
                   end;
                end;
             end;             P1:=p2;
          end;                inc(I);
       end;
    end;
begin
   Undo:=self.CreateUndoObject(Userstring(148),false);
   Changed:=False;
   InvertedFaces:=0;
   Inconsistent:=0;
   NonManifold:=0;
   DblEdges:=0;
   // if ShowResult=false a quiet test is done, only the direction of facenormals is checked and fixed
   if ShowResult then begin                                // Find double edges
      DoubleEdges:=TFasterList.Create;
      for I:=1 to St.Surface.NoControlEdges do begin
         Edge1:=St.Surface.ControlEdge[I-1];
         if Edge1.NoFaces=1 then
         if DoubleEdges.SortedIndexOf(Edge1)=-1 then begin
            for J:=1 to Edge1.StartPoint.NoEdges do begin
               Edge2:=Edge1.StartPoint.Edge[J-1] as SControlEdge;
               if (Edge1<>Edge2) and (Edge2.NoFaces=1) then begin
                  if ((Sqr(Edge1.StartPoint.Coordinate-Edge2.StartPoint.Coordinate)<SqError)
                  and (Sqr(Edge1.EndPoint.Coordinate-Edge2.EndPoint.Coordinate)<SqError))
                  or ((Sqr(Edge1.StartPoint.Coordinate-Edge2.EndPoint.Coordinate)<SqError)
                  and (Sqr(Edge1.EndPoint.Coordinate-Edge2.StartPoint.Coordinate)<SqError))
                  then if DoubleEdges.SortedIndexOf(Edge2)=-1
                     then DoubleEdges.AddSortedObject( Edge1,Edge2 );
               end;
            end;
         end;
      end;
      Points:=TFasterList.Create;
      for I:=1 to DoubleEdges.Count do begin
         Edge1:=DoubleEdges[I-1];
         Edge2:=DoubleEdges.Objects[I-1];
         if (St.Surface.ControlEdges.IndexOf(Edge1)<>-1)
         and (St.Surface.ControlEdges.IndexOf(Edge2)<>-1) then begin
         // remove the face connected to edge2 and rebuild it by connecting it to edge1
            Ctrlface:=Edge2.Face[0] as SControlFace;
            Points.Clear;
            for J:=1 to CtrlFace.Nopoints do begin
               Point:=CtrlFace.Point[J-1];
               if Point=Edge2.StartPoint then begin
                  if Sqr(Edge2.StartPoint.Coordinate-Edge1.StartPoint.Coordinate)<SqError
                  then begin
                     if Points.IndexOf(Edge1.StartPoint)=-1 then points.Add(Edge1.StartPoint);
                  end else if Sqr(Edge2.StartPoint.Coordinate-Edge1.EndPoint.Coordinate)<SqError
                  then begin
                     if Points.IndexOf(Edge1.EndPoint)=-1 then points.Add(Edge1.EndPoint);
                  end;
               end else
               if Point=Edge2.EndPoint then begin
                  if Sqr(Edge2.EndPoint.Coordinate-Edge1.StartPoint.Coordinate)<SqError
                  then begin
                     if Points.IndexOf(Edge1.StartPoint)=-1 then points.Add(Edge1.StartPoint);
                  end else if Sqr(Edge2.EndPoint.Coordinate-Edge1.EndPoint.Coordinate)<SqError
                  then begin
                     if Points.IndexOf(Edge1.EndPoint)=-1 then points.Add(Edge1.EndPoint);
                  end;
               end else if Points.IndexOf(Point)=-1 then Points.Add(Point);
            end;
            if Points.Count>2 then begin
               NewLayer:=Ctrlface.Layer;
               St.Surface.AddControlFace(Points,False,NewLayer);
               CtrlFace.SelDeleteFace;
               Changed:=True;
               inc(DblEdges);
            end;
         end;
      end;
      DoubleEdges.Destroy;
      Points.Destroy;
   end;
   // Check for correct normal direction (outward)
   // First assemble all controlfaces and extract
   // isolated groups (not physically connected)
   AllFaces:=TFasterList.Create;
   AllFaces.Capacity:=St.Surface.NoControlFaces;
   for I:=1 to St.Surface.NoControlFaces do AllFaces.Add(St.Surface.ControlFace[I-1]);
   AllFaces.Sort;                         // Sort list for faster object search
   Leaks:=TFasterList.Create;                                 // assemble leaks
   for I:=1 to St.Surface.NoControlPoints do begin
      CtrlPoint:=St.Surface.ControlPoint[I-1];
      if CtrlPoint.IsLeak then Leaks.Add(CtrlPoint);
   end;                                 // sort leaks in ascending z-coordinate
   for I:=1 to Leaks.Count-1 do begin
      for J:=I+1 to Leaks.Count do begin
         Point:=Leaks[I-1];
         Pt:=Leaks[J-1];
         Swap:=False;
         if Pt.Coordinate.Z<Point.Coordinate.Z then Swap:=True;
         if (abs(Pt.Coordinate.Z-Point.Coordinate.Z)<1e-6) and (Pt.Coordinate.X<Point.Coordinate.X) then Swap:=True;
         if (abs(Pt.Coordinate.Z-Point.Coordinate.Z)<1e-6) and (abs(Pt.Coordinate.X-Point.Coordinate.X)<1e-6) and (Pt.Coordinate.Y<Point.Coordinate.Y) then Swap:=True;
         if Swap then Leaks.Exchange(I-1,J-1);
      end;
   end;
   for I:=1 to St.Surface.NoControlEdges do if St.Surface.ControlEdge[I-1].NoFaces>2 then inc(NonManifold);
   if AllFaces.Count>0 then begin
      NewGroup:=TFasterList.Create;
      while AllFaces.Count>0 do begin
         Face:=AllFaces[AllFaces.Count-1];
         AllFaces.Delete(AllFaces.Count-1);
         NewGroup.Clear;
         NewGroup.Capacity:=AllFaces.Count;
         NewGroup.Add(Face); // use the first face as seed for the following procedure
         FindConnectedFaces(NewGroup,AllFaces);
         NewGroup.Sort;         // find the lowest point of this group of faces
         Point:=nil;
         for I:=1 to NewGroup.Count do begin
            Face:=NewGroup[I-1];
            for j:=1 to Face.Nopoints do begin
               Pt:=Face.Point[J-1];
               if Point=nil then Point:=Pt
                            else if Pt.Coordinate.Z<Point.Coordinate.Z then Point:=Pt;
            end;
         end;
         if Point<>nil then begin
            // select the a face connected to this point and also present in the
            // newgroup-list with faces and with the most vertical normal of all canditates
            Face:=nil;
            for I:=1 to Point.NoFaces do
            if NewGroup.SortedIndexOf(Point.Face[I-1])<>-1 then begin
               if Face=nil then begin
                  Face:=Point.Face[I-1];
                  normal:=Face.FaceNormal;
               end else begin
                  Tmp:=Point.Face[I-1].FaceNormal;
                  if abs(Tmp.Z)>abs(Normal.Z) then begin
                     Face:=Point.Face[I-1];
                     normal:=Face.FaceNormal;
                  end;
               end;
            end;
            if Face<>nil then begin
               if Normal.Z>0.0 then begin
                  // normal points upward, all faces in this group must be inverted
                  for I:=1 to NewGroup.Count do begin
                     Face:=NewGroup[I-1];
                     Face.FlipNormal;
                  end;
                  Changed:=True;
                  inc(InvertedFaces,NewGroup.Count);
               end;
            end;
         end;
      end;
      NewGroup.Destroy;
      if (Leaks.Count>0) and (ShowResult) then begin
         Str:=Userstring(149)+#32+IntToStr(Leaks.Count)+#32+Userstring(150)+'.';
         if Leaks.Count>10 then Str:=Str+EOL+Userstring(151)+':';
         Str:=Str+EOL;
         for I:=1 to Leaks.Count do begin
            Point:=Leaks[I-1];
            Str:=Str+EOL+FloatToDec(Point.Coordinate.X,3)+', '
                        +FloatToDec(Point.Coordinate.Y,3)+', '
                        +FloatToDec(Point.Coordinate.Z,3);
            if I=10 then break;
         end;
         ShowMessage(Str);
      end;
      if (Changed)
      or (Inconsistent>0)
      or (NonManifold>0)
      or (DblEdges>0) then begin
         Undo.Accept;
         St.Build:=False;
         St.Redraw;
         St.FileChanged:=True;
         if ShowResult then begin
            Str:=Userstring(152)+':';
            if DblEdges>0 then Str:=Str+EOL+IntToStr(DblEdges)+#32+UserString(158)+'.';
            if Inconsistent>0 then Str:=Str+EOL+IntToStr(Inconsistent)+#32+Userstring(153)+'.';
            if InvertedFaces>0 then Str:=Str+EOL+IntToStr(InvertedFaces)+#32+Userstring(154)+'.';
            if NonManifold>0 then begin
               Str:=Str+EOL+IntToStr(NonManifold)+#32+Userstring(155);
            end;
            ShowMessage(Str);
            if assigned(St.FOnUpdateGeometryInfo) then St.FOnUpdateGeometryInfo(self);
         end;
      end else begin
         Undo.Delete;
         if (ShowResult) and (Leaks.Count=0) then ShowMessage(Userstring(156));
      end;
      Leaks.Destroy;
   end;
   AllFaces.Destroy;
end;

// Affine hullform transformation according to Lackenby

procedure SEdit.Model_LackenbyTransformation;
var Dialog     : TLackenbyDialog;
    Undo       : TUndoObject;
    I,UndoIndex: Integer;
    Modified   : Boolean;
begin
   Dialog:=TLackenbyDialog.Create(St);
   ShowTranslatedValues(Dialog);
   Undo:=CreateUndoObject(Userstring(159),false);
   UndoIndex:=St.UndoCount;
   if Dialog.Execute(St,Modified) then begin
      for I:=St.UndoCount downto UndoIndex+1 do St.UndoObject[I-1].Delete;
      if not Modified then Undo.Delete
                      else Undo.Accept;
   end else begin
      for I:=St.UndoCount downto UndoIndex+1 do St.UndoObject[I-1].Delete;
      if Modified then Undo.Restore;
      Undo.Delete;
   end;
   Dialog.Destroy;
end;

// Scale the entire model and all equivalent data such as stations etc.

procedure SEdit.Model_Scale(ScaleVector:Vector;OverrideLock,AdjustMarkers:Boolean);
var I,J   : integer;
    Point : SControlPoint;
    P     : Vector;
    Marker: TMarker;
begin
   for I:=1 to St.Surface.NoControlPoints do begin
      Point:=St.Surface.ControlPoint[I-1];
      if (not Point.Locked) or (OverrideLock) then begin
         P:=Point.Coordinate;
         P.X:=P.X*ScaleVector.X;
         P.Y:=P.Y*ScaleVector.Y;
         P.Z:=P.Z*ScaleVector.Z;
         if Point.Locked then begin
            Point.Locked:=False;
            Point.Coordinate:=P;
            Point.Locked:=True;
         end else Point.Coordinate:=P;
      end;
   end;
   // Update Mainparticulars
   St.ProjectSettings.ProjectLength:=abs(St.ProjectSettings.ProjectLength*Scalevector.X);
   St.ProjectSettings.ProjectBeam:=abs(St.ProjectSettings.ProjectBeam*Scalevector.Y);
   St.ProjectSettings.ProjectDraft:=abs(St.ProjectSettings.ProjectDraft*Scalevector.Z);
   if not St.ProjectSettings.UseMidleFrame then
      St.ProjectSettings.MidleFrame:=abs(St.ProjectSettings.MidleFrame*ScaleVector.X);
   // Update markers
   if AdjustMarkers then for I:=1 to St.NoMarkers do begin
      Marker:=St.Marker[I-1];
      for j:=1 to Marker.nS do begin
         P:=Marker.Point[J-1];
         P.X:=P.X*Scalevector.X;
         P.Y:=P.Y*Scalevector.Y;
         P.Z:=P.Z*Scalevector.Z;
         Marker.Point[J-1]:=P;
      end;
   end;
   // Update stations, buttcks and waterlines
   for I:=1 to St.NoStations do St.Station[I-1].FPlane.d:=St.Station[I-1].FPlane.d*ScaleVector.X;
   for I:=1 to St.NoButtocks do St.Buttock[I-1].FPlane.d:=St.Buttock[I-1].FPlane.d*ScaleVector.Y;
   for I:=1 to St.NoWaterlines do St.Waterline[I-1].FPlane.d:=St.Waterline[I-1].FPlane.d*ScaleVector.Z;
   // Reset any present hydrostatic calculations
   for I:=1 to St.NoHydrostaticCalculations do begin
      St.HydrostaticCalculation[I-1].Draft:=abs(St.HydrostaticCalculation[I-1].Draft*ScaleVector.Z);
      St.HydrostaticCalculation[I-1].Trim:=St.HydrostaticCalculation[I-1].Trim*ScaleVector.Z;
      St.HydrostaticCalculation[I-1].Calculated:=False;
   end;
   St.Build:=False;                          // Initialize all other data
   St.FileChanged:=True;                     // Redraw
   St.Draw;                                  // Refresh controlpoint data
   St.ActiveControlPoint:=St.ActiveControlPoint;
end;

// Merge two selected edges by removing their common controlpoint.
procedure SEdit.Point_Collapse;
var I,N  : integer;
    Point: SControlPoint;
    Undo : TUndoObject;
begin
   N:=0;
   Undo:=CreateUndoObject(Userstring(160),false);
   For I:=St.NoSelectedControlPoints downto 1 do begin
      Point:=St.SelectedControlPoint[I-1];
      if (not Point.Locked) and (Point.NoEdges=2) then begin
         Point.Collapse;
         inc(N);
      end;
   end;
   if N>0 then begin
      Undo.Accept;
      St.Build:=false;
      St.Redraw;
      St.FileChanged:=True;
      if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;

// removes any unused points from the model

procedure SEdit.Point_RemoveUnused;
var I,N: integer; Point: SControlPoint; Undo: TUndoObject;
begin N:=0;
   Undo:=CreateUndoObject(Userstring(161),false);
   For I:=St.Surface.NoControlPoints downto 1 do begin
      Point:=St.Surface.ControlPoint[I-1];
      if Point.NoFaces=0 then begin
         Point.SelDeletePoint;
         inc(N);
      end;
   end;
   if N>0 then begin
      Undo.Accept;
      St.Build:=false;
      St.Redraw;
      St.FileChanged:=True;
      if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
      ShowMessage(IntToStr(N)+#32+Userstring(162));
   end else Undo.Delete;
end;

// Finds all intersection of VISIBLE edges and a 3D plane, and inserts a point on each of these edges

procedure SEdit.Point_InsertPlane;
var Dialog: TInsertPlaneDialog;
    Min,Max: Vector;
    Undo: TUndoObject;
    N: Integer;
begin
   St.Extents(Min,Max);
   Dialog:=TInsertPlaneDialog.Create(St);
   ShowTranslatedValues(Dialog);
   Dialog.Max:=Max;
   Dialog.Min:=min;
   if Dialog.Execute then begin
      Undo:=CreateUndoObject(UserString(163),false);
      N:=St.Surface.NoControlPoints;
      St.Surface.InsertPlane(Dialog.Plane,Dialog.CreateControlCurve);
      if N<St.Surface.NoControlPoints then begin
         Undo.Accept;
         St.FileChanged:=True;
         St.Build:=false;
         St.Redraw;
         if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
      end else Undo.Delete; // nothis has been changed
   end;
   Dialog.Destroy;
end;

// Calculates the intersection points of two layers

procedure SEdit.Point_IntersectLayer;
var I: Integer;
    Layers: TFasterList;
    Undo  : TUndoObject;
    Dialog: TIntersectLayerDialog;
begin
   Layers:=TFasterList.Create;
   for I:=1 to St.NoLayers do if St.Layer[I-1].Count>0 then Layers.Add(St.Layer[I-1]);
   if Layers.Count>1 then begin
      Dialog:=TIntersectLayerDialog.Create(St);
      ShowTranslatedValues(Dialog);
      if Dialog.Execute(Layers) then begin
         if (Dialog.Layer1<>nil) and (Dialog.Layer2<>nil) then begin
            Undo:=CreateUndoObject(Userstring(164),false);
            if Dialog.Layer1.CalculateIntersectionPoints(Dialog.Layer2) then begin
               Undo.Accept;
               St.FileChanged:=True;
               St.Build:=False;
               St.Redraw;
               if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
            end else begin
               Undo.Delete;
               ShowMessage(Userstring(165));
            end;
         end;
      end;
      Dialog.Destroy;
   end else ShowMessage( Userstring(166) );
   Layers.Destroy;
end;

// Locks all selected points

procedure SEdit.Point_Lock;
var I:Integer;
begin
   if St.NoSelectedLockedPoints<St.NoSelectedControlPoints then
   begin
      self.CreateUndoObject(UserString(167),True);
      for I:=1 to St.NoSelectedControlPoints do St.SelectedControlPoint[I-1].Locked:=True;
      St.Redraw;
      St.FileChanged:=True;
      St.ActiveControlPoint:=St.ActiveControlPoint;
   end;
end;

// Unlocks all selected locked points

procedure SEdit.Point_Unlock;
var I:Integer;
begin
   if St.NoSelectedLockedPoints>0 then begin
      self.CreateUndoObject(Userstring(168),True);
      for I:=1 to St.NoSelectedControlPoints do St.SelectedControlPoint[I-1].Locked:=False;
      St.Redraw;
      St.FileChanged:=True;
      St.ActiveControlPoint:=St.ActiveControlPoint;
   end;
end;

// Unlocks all locked points

procedure SEdit.Point_UnlockAll;
var I,N:Integer;
begin
   if St.NoLockedPoints>0 then begin
      CreateUndoObject(Userstring(169),True);
      N:=St.NoLockedPoints;
      for I:=1 to St.Surface.NoControlPoints do St.Surface.ControlPoint[I-1].Locked:=False;
      St.Redraw;
      St.ActiveControlPoint:=St.ActiveControlPoint;
      ShowMessage( IntToStr(N)+#32+Userstring(170)+'.' );
      St.FileChanged:=True;
   end;
end;

// Function that shows a warning when certain edit commands are invoked
//       and the model contains locked points

function SEdit.ProceedWhenLockedPoints:Boolean;
begin
   if St.NoLockedPoints>0 then begin
      Result:=MessageDlg(Userstring(86)+EOL+
                         Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
   end else Result:=True;
end;

// Add a new point to the model with no edges/faces attached

function SEdit.Point_New:SControlPoint;
begin
   Result:=SControlPoint.Create(St.Surface);
   St.Surface.AddControlPoint(Result);
   Result.Coordinate:=ZERO;
   St.FileChanged:=true;
   St.Redraw;
   St.ActiveControlPoint:=Result;
   if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
end;

// Project all selected points onto a straight line through the first and last selected points

procedure SEdit.Point_ProjectStraightLine;
var I,NLocked,NChanged: Integer;
    Point,P1,P2: SControlPoint;
    P: Vector;
    Undo: TUndoObject;
begin
   if St.NoSelectedControlPoints>2 then begin
      // Determine if the number of points to be moved does not conatin locked controlpoints only
      // however the first and last points (determining the linesegment) are allowed to be locked
      NLocked:=0;
      for I:=2 to St.NoSelectedControlPoints-1 do if St.SelectedControlPoint[I-1].Locked then inc(NLocked);
      // Number of lovked points must be smaller then NoSelectedControlPoints-2
      if NLocked<St.NoSelectedControlPoints-2 then begin
         P1:=St.SelectedControlPoint[0];
         P2:=St.SelectedControlPoint[St.NoSelectedControlPoints-1];
         Undo:=CreateUndoObject(userstring(171),False);
         NChanged:=0;
         for I:=2 to St.NoSelectedControlPoints-1 do begin
            Point:=St.SelectedControlPoint[I-1];
            if not Point.Locked then begin
               P:=ProjectPointOnline(Point.Coordinate,P1.Coordinate,P2.Coordinate);
               if Sqr(P-Point.Coordinate)>1e-10 then begin
                  Point.Coordinate:=P;
                  Inc(NChanged);
               end;
            end;
         end;
         if NChanged>0 then begin
            Undo.Accept;
            St.FileChanged:=True;
            St.Redraw;
         end else Undo.Delete;
      end else ShowMessage( Userstring(172)+'.' );
   end;
end;

// Deselect all selected items at once
procedure SEdit.Selection_Clear;
begin
   St.Surface.Clearselection;
   St.ActiveControlPoint:=nil;
   St.FSelectedFlowlines.Clear;
   St.FSelectedMarkers.Clear;
   St.Redraw;
end;

procedure SEdit.Selection_Delete;
var I,N: integer;
begin
   N:=St.NoSelectedControlPoints+
      St.NoSelectedControlEdges+
      St.NoSelectedControlFaces+
      St.NoSelectedControlCurves+
      St.NoselectedMarkers+
      St.NoselectedFlowlines;
   if N>0 then begin
      if MessageDlg( Userstring(173)+#32+IntToStr(N)+#32+Userstring(174)+'?',
                     mtWarning,[mbYes,mbNo],0 )=mrYes
      then begin
         CreateUndoObject(Userstring(175),True);
         for I:=St.NoselectedFlowlines downto 1 do St.SelectedFlowline[I-1].Delete;
         for I:=St.NoselectedMarkers downto 1 do St.SelectedMarker[I-1].Delete;
         St.Surface.Selection_Delete;
         St.ActiveControlPoint:=nil;
         St.Build:=False;
         St.FileChanged:=True;
         St.Redraw;
         if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
      end;
   end;
end;

procedure SEdit.Selection_SelectAll;            // Select all visible items
var I,J:Integer;
begin With St do begin
   for I:=1 to NoLayers do if Layer[I-1].Visible then begin
      for J:=1 to Layer[I-1].Count do Layer[I-1].Items[J-1].Selected:=True;
   end;
   for I:=1 to Surface.NoControlEdges do if Surface.ControlEdge[I-1].Visible then Surface.ControlEdge[I-1].Selected:=True;
   for I:=1 to Surface.NoControlPoints do if Surface.ControlPoint[I-1].Visible then Surface.ControlPoint[I-1].Selected:=True;
   for I:=1 to Surface.NoControlCurves do if Surface.ControlCurve[I-1].Visible then Surface.ControlCurve[I-1].Selected:=True;
   for I:=1 to NoMarkers do if Marker[I-1].Visible then Marker[I-1].Selected:=True;
   for I:=1 to NoFlowlines do if Flowline[I-1].Visible then Flowline[I-1].Selected:=True;
   Redraw;
end end;

function SEdit.CreateRedoObject:TUndoObject;
var UndoObject: TUndoObject;
    Version   : TFileVersion;
    Preview   : Boolean;
begin
   UndoObject:=TUndoObject.Create(St);
   Result:=UndoObject;
   UndoObject.FUndoText:=UserString(71);
   Version:=St.FileVersion;
   Preview:=St.ProjectSettings.SavePreview;
            // Temp. set to the latest fileversion so that no data will be lost
   St.FFileVersion:=Currentversion;  // Temp. disable saving of preview image
   St.ProjectSettings.SavePreview:=False;
   UndoObject.FFileChanged:=St.FileChanged;
   UndoObject.FFileName:=St.Filename;
   UndoObject.FEditMode:=St.EditMode;
   UndoObject.FFilenameSet:=St.FFilenameSet;
   UndoObject.FIsTempRedoObject:=True;
   St.SaveProject(UndoObject.FUndoData);   // <=> St.SaveBinary
   UndoObject.Accept;                       // Restore the original fileversion
   St.FileVersion:=Version;
   St.ProjectSettings.SavePreview:=Preview;
   if Assigned(St.FOnUpdateUndoData) then St.FOnUpdateUndoData(St);
end;

// Creates undodata just prior to modifications
function SEdit.CreateUndoObject( UndoText:String;Accept:Boolean ):TUndoObject;
var UndoObject: TUndoObject;
    Version: TFileVersion;
    Preview: Boolean;
    I: Integer;
begin
   UndoObject:=TUndoObject.Create(St);
   Result:=UndoObject;
   //if UndoText<>'' then UndoText[1]:=Lowercase(UndoText[1]);
   UndoObject.FUndoText:=UndoText;
   Version:=St.FileVersion;
   Preview:=St.ProjectSettings.SavePreview;
   // delete all undo objects after the current one
   for I:=St.FUndoObjects.Count downto St.FUndoPosition+1
       do St.UndoObject[I-1].Delete; // Temp. set to the latest fileversion so that no data will be lost
   St.FFileVersion:=Currentversion;  // Temp. disable saving of preview image
   St.ProjectSettings.SavePreview:=False;
   UndoObject.FFileChanged:=St.FileChanged;
   UndoObject.FFileName:=St.Filename;
   UndoObject.FEditMode:=St.EditMode;
   UndoObject.FFilenameSet:=St.FFilenameSet;
   St.SaveProject(UndoObject.FUndoData);   // <##>SaveBinary
   if Accept then UndoObject.Accept;
   // Restore the original fileversion
   St.FileVersion:=Version;
   St.ProjectSettings.SavePreview:=Preview;
   if Assigned(St.FOnUpdateUndoData) then St.FOnUpdateUndoData(St);
end;

procedure SEdit.Undo;
var UndoObject: TUndoObject; Preview: boolean;
begin
   if St.FUndoObjects.Count>0 then begin
      Preview:=St.ProjectSettings.SavePreview;
      if St.FUndoPosition=St.UndoCount then  begin
         if St.UndoObject[St.UndoCount-1].FIsTempRedoObject then begin
         end else CreateRedoObject;
      end;
      if St.FPreviousUndoPosition<St.FUndoPosition then dec(St.FUndoPosition);
      St.FPreviousUndoPosition:=St.FUndoPosition;
      dec(St.FUndoPosition);
      UndoObject:=St.FUndoObjects[St.FUndoPosition];
      UndoObject.Restore;
      St.ProjectSettings.SavePreview:=Preview;
   end;
end;


procedure SEdit.Undo_Clear; begin St.ClearUndo; end; // Clear the undo history

procedure SEdit.Undo_ShowHistory;                  // Show the undo history
var Dialog   : TUndoHistoryDialog;
    Undo,Redo: TUndoObject;
    Index    : Integer;
begin
   Dialog:=TUndoHistoryDialog.Create(St);
   ShowTranslatedValues(Dialog);
   Redo:=nil;
   if (St.FUndoPosition=St.UndoCount)
   and (St.UndoCount>0) then begin
      if not St.UndoObject[St.UndoCount-1].FIsTempRedoObject then begin
         Redo:=CreateRedoObject;
         dec(St.FUndoPosition);
      end;
   end;
   if Dialog.Execute(St) then begin
      if Dialog.UndoBox.ItemIndex<>-1 then begin
         Undo:=Dialog.UndoBox.Items.Objects[Dialog.UndoBox.ItemIndex] as TUndoObject;;
         Index:=St.FUndoObjects.IndexOf(Undo);
         if Index<>-1 then begin    // St.FPreviousUndoPosition:=Index+1;
            St.FUndoPosition:=Index;
            Undo.Restore;
         end;
      end;
   end else if Redo<>nil then Redo.Delete;
   Dialog.Destroy;
end;

procedure SEdit.Redo;
var UndoObject : TUndoObject;
    Preview    : boolean;
begin
   if St.FUndoObjects.Count>0 then begin
      Preview:=St.ProjectSettings.SavePreview;
      if St.FPreviousUndoPosition>St.FUndoPosition then inc(St.FUndoPosition);
      St.FPreviousUndoPosition:=St.FUndoPosition;
      inc( St.FUndoPosition );
      UndoObject:=St.FUndoObjects[St.FUndoPosition-1];
      UndoObject.Restore;
      St.ProjectSettings.SavePreview:=Preview;
   end;
end;

// Add a new intersection of the specified type at the specified location
function  SEdit.Intersection_Add(IntType:TIntersectionType;Distance:Real):TIntersection;
var Intersection: TIntersection; TargetList: TFasterList; I: integer;
begin
   TargetList:=nil;
   Case IntType of
      fiStation  : TargetList:=St.FStations;
      fiButtock  : TargetList:=St.FButtocks;
      fiWaterline: TargetList:=St.FWaterlines;
      fiDiagonal : TargetList:=St.FDiagonals;
   end;      // First check if an intersection already exists at this location;
   for I:=1 to TargetList.Count do begin
      Intersection:=TargetList[I-1];
      if Abs(-InterSection.FPlane.d-Distance)<1e-5 then begin // Yes, it exists, so do not add a new one
         Result:=nil;
         exit;
      end;
   end;                           // Once here, a new intersection can be added
   Intersection:=TIntersection.Create(St);
   Intersection.IntersectionType:=IntType;
   Intersection.FPlane.a:=0.0;
   Intersection.FPlane.b:=0.0;
   Intersection.FPlane.c:=0.0;
   Intersection.FPlane.d:=0.0;
   Case Intersection.IntersectionType of
      fiStation: begin
        Intersection.FPlane.a:=1.0;
        Intersection.FPlane.d:=-Distance; end;
      fiButtock: begin
        Intersection.FPlane.b:=1.0;
        Intersection.FPlane.d:=-Distance; end;
      fiWaterline: begin
        Intersection.FPlane.c:=1.0;
        Intersection.FPlane.d:=-Distance; end;
      fiDiagonal: begin
        Intersection.FPlane.b:=1/Sqrt(2);
        Intersection.FPlane.c:=1/Sqrt(2);
        Intersection.FPlane.d:=-Intersection.FPlane.c*Distance; end;
   end;
   Intersection.Rebuild;          // Only add if an intersection has been found
   if Intersection.Count>0 then begin
      Intersection_AddToList(Intersection);
      Intersection.DrawAll;
      Result:=Intersection;
   end else begin
      Intersection.Destroy;
      Result:=nil;
   end;
end;
{
  TPreferences Container class for all program settings
}
{$I Preferences.inc}
{
  TProjectSettings
   Container class for project settings for each
   project such as mainparticulars, waterdensity etc.
}
{$I ProjectSettings.inc}
{
  TShip
   TShip is the actual component used
   for modelling and representing the St
}

procedure TShip.AddViewport( Viewport: TViewport );
    begin     // Add a viewport to the list of viewports connected to the model
      if FViewports.IndexOf(Viewport)=-1 then begin
         Viewport.Color:=Preferences.ViewportColor;
         FViewports.Add( Viewport );
         Viewport.ZoomExtents;
    end end;
function TShip.FGetViewport(Index:integer):TViewport;
   begin {if(Index>=0)and(Index<nV)then} Result:=FViewports[index]
         { else Raise Exception.Create('Invalid viewport index!'); }
   end;
function TShip.FGetNoViewports:integer;
   begin Result:=FViewports.Count; end;
procedure TShip.DeleteViewport(Viewport:TViewport); var Index:integer;
    begin Index:=FViewports.IndexOf(Viewport);
          if Index<>-1 then FViewports.Delete(index);
    end;
function TShip.FGetOnChangeActiveLayer:TChangeActiveLayerEvent;
   begin Result:=Surface.OnChangeActiveLayer; end;
function TShip.FGetOnChangeLayerData:TNotifyEvent;
   begin Result:=Surface.OnChangeLayerData; end;
function TShip.FGetOnSelectItem:TNotifyEvent;
   begin Result:=Surface.OnSelectItem; end;
function TShip.FGetSelectedControlCurve(Index:integer):SControlCurve;
   begin Result:=Surface.SelectedControlCurve[index]; end;
function TShip.FGetControlCurve(Index:integer):SControlCurve;
   begin Result:=Surface.ControlCurve[index]; end;
function TShip.FGetSelectedControlEdge(Index:integer):SControlEdge;
   begin Result:=Surface.SelectedControlEdge[index]; end;
function TShip.FGetSelectedControlPoint(Index:integer):SControlPoint;
   begin Result:=Surface.SelectedControlPoint[index]; end;
function TShip.FGetSelectedControlFace(Index:integer):SControlFace;
   begin Result:=Surface.SelectedControlFace[index]; end;
function TShip.FGetSelectedFlowline(index:Integer):TFlowline;
   begin Result:=FSelectedFlowlines[index]; end;
function TShip.FGetSelectedMarker(index:Integer):TMarker;
   begin Result:=FSelectedMarkers[index]; end;
function TShip.FGetStation(Index:integer):TIntersection;
   begin Result:=FStations[index]; end;
function TShip.FGetMarker(Index:integer):TMarker;
   begin Result:=FMarkers[index]; end;
function TShip.FGetNoBackgroundImages:Integer;
   begin Result:=FBackgroundImages.Count; end;
function TShip.FGetUndoCount:integer;
   begin Result:=FUndoObjects.Count; end;
function TShip.FGetUndoMemory:integer; var I:integer;
   begin result:=0; for I:=1 to UndoCount do Result+=UndoObject[I-1].Memory;
   end;
function TShip.FGetUndoObject(Index:integer):TUndoObject;
   begin Result:=FUndoObjects[Index]; end;
function TShip.FGetButtock(Index:integer):TIntersection;
   begin Result:=FButtocks[index]; end;
function TShip.FGetDiagonal(Index:integer):TIntersection;
   begin Result:=FDiagonals[index]; end;
function TShip.FGetFlowline(Index:integer):TFlowline;
   begin Result:=FFlowlines[index]; end;
function TShip.FGetWaterline(Index:integer):TIntersection;
   begin Result:=FWaterlines[index]; end;

// Assembles all stations and builds a 2D bodyplan for export to other calculating programs

procedure TShip.FBuildValidFrameTable(Destination:TFasterList;CloseAtDeck:Boolean);
var I,J: integer; Min: Real; P: Vector;
    Intersection: TIntersection; Spline: TSpline; TmpList: TFasterList;
begin
   Min:=0.0;
   for I:=1 to NoStations do begin
      Intersection:=Station[I-1];
      if not Intersection.Built then Intersection.Rebuild;
      TmpList:=TFasterList.Create;
      for J:=1 to Intersection.Count do begin
         Spline:=TSpline.Create;
         Spline.Assign(Intersection.Items[J-1]); // Quick check to determine if the frame runs from bottom to top
         if Spline.Value(0.0).Z>Spline.Value(1.0).Z then // If not then reverse the points
            Spline.InvertDirection;
         TmpList.Add(Spline);
      end;                               // Take all segments and join into one
      if TmpList.Count>1 then JoinSplineSegments(0.01,True,TmpList);
      for J:=1 to TmpList.Count do begin Spline:=TmpList[J-1];
         if CloseAtDeck then begin
            if Spline.Point[Spline.nS-1].Y<>0.0 then begin
               P:=Spline.Point[Spline.nS-1];
               P.Y:=0.0;
               Spline.Add(P);
               Spline.Knuckle[Spline.nS-2]:=True;
            end;
         end;
         Destination.Add(Spline);
         if I=1 then Min:=Spline.Min.Z
                else if Spline.Min.Z<Min then Min:=Spline.Min.Z;
      end;
      Tmplist.Destroy;
   end;
   // Now shift all stations up or down so that the lowest point
   // of all stations is on the baseline z=0.0
   if Min<>0.0 then for I:=1 to Destination.Count do begin
      Spline:=Destination[I-1];
      for J:=1 to Spline.nS do begin
         P:=Spline.Point[J-1];
         P.Z:=P.Z-Min;
         Spline.Point[J-1]:=P;
      end;
   end;
end;
function TShip.FGetActiveLayer:Slayer;
   begin Result:=Surface.ActiveLayer; end;
function TShip.FGetBackgroundImage(Index:Integer):TBackgroundImageData;
   begin Result:=FBackgroundImages[index]; end;
function TShip.FGetBuild:Boolean;
   begin Result:=Surface.Build; end;
function TShip.FGetHydrostaticCalculation(Index:integer):HydrostaticCalc;
   begin Result:=FHydrostaticCalculations[index]; end;
function TShip.FGetLayer(Index:integer):SLayer;
   begin Result:=Surface.Layer[index]; end;
function TShip.FGetNoMarkers:integer;
   begin Result:=FMarkers.Count; end;
function TShip.FGetNoStations:integer;
   begin Result:=FStations.Count; end;
function TShip.FGetNoWaterlines:integer;
   begin Result:=FWaterlines.Count; end;
function TShip.FGetNoButtocks:integer;
   begin Result:=FButtocks.Count; end;
function TShip.FGetNoDiagonals:integer;
   begin Result:=FDiagonals.Count; end;
function TShip.FGetNoFlowLines:Integer;
   begin Result:=FFlowlines.Count; end;
function TShip.FGetNoHydrostaticCalculations:integer;
   begin Result:=FHydrostaticCalculations.Count; end;
function TShip.FGetNoLockedPoints:Integer;
   begin Result:=Surface.NoLockedPoints; end;
function TShip.FGetNoLayers:integer;
   begin Result:=Surface.NoLayers; end;
procedure TShip.FSetActiveControlPoint( Val:SControlPoint );
begin
   if Val<>FActiveControlPoint then begin
      FActiveControlPoint:=Val;
      FControlpointForm.ActiveControlPoint:=FActiveControlPoint;
      if FActiveControlPoint=nil then begin
         ShowTranslatedValues(FControlpointForm);
         if FControlpointForm.Visible then FControlpointForm.Visible:=False;
      end else begin
   // The first line makes sure that the activecontrolpoint form does NOT recieve focus.
   // because the mousewheel zoom in/out doesn't work anymore in that case
         if not FControlpointForm.Visible then begin
            ShowTranslatedValues(FControlpointForm);
            ShowWindow( FControlpointForm.Handle,SW_SHOWNOACTIVATE );
            FControlpointForm.Visible:=true;
         end;
      end;
      FCurrentlyMoving:=False;
      FPointHasBeenMoved:=False;
   end else
   if FActiveControlPoint<>nil then begin // Update controlpoint information
      FControlpointForm.ActiveControlPoint:=FActiveControlPoint;
   end;
end;

procedure TShip.FSetActiveLayer(Val:SLayer);
    begin Surface.ActiveLayer:=Val; end;

procedure TShip.FSetBuild( Val:Boolean ); var I : integer;
begin
   Surface.Build:=Val;
   if not Build then begin
      for I:=1 to NoStations do Station[I-1].Built:=False;
      for I:=1 to NoButtocks do Buttock[I-1].Built:=False;
      for I:=1 to NoWaterlines do Waterline[I-1].Built:=False;
      for I:=1 to NoDiagonals do Diagonal[I-1].Built:=False;
      for I:=1 to NoHydrostaticCalculations do HydrostaticCalculation[I-1].Calculated:=False;
      for I:=1 to NoFlowlines do Flowline[I-1].Build:=False;
   end;
end;
procedure TShip.FSetEditMode( Val:TEditMode );
begin
   if Val<>FEditMode then begin FEditMode:=Val;
   {  Case EditMode of
         emSelectItems: begin end;
      end;
   }  Redraw;
   end;
end;
procedure TShip.FSetFileChanged(Val:Boolean);
begin if Val<>FFileChanged then begin
         FFileChanged:=Val;
         if assigned(FOnFileChanged) then FOnFileChanged(self); end;
end;
procedure TShip.FSetFileName( Val:string );              // var Tmp:string;
begin if val='' then val:=Userstring(179);
                                // Tmp:=ChangeFileExt( Val,ShipExtention );
         if FFilename<>val then FFilename:=Val;
end;
function TShip.FGetFilename: String; var Ext: String;
begin if FFilename='' then FFilename:=Userstring(179);
      Ext:=ExtractFileExt( FFilename );
      if (Ext='.ftm') or (Ext='.fbm') or (Ext='.fef') then Result:=FFilename
         else Result:=ChangeFileExt( FFilename,ShipExtention );
end;
procedure TShip.FSetFileVersion(Val:TFileVersion);
    begin if Val<>FFileVersion then
          begin FFileVersion:=Val; FileChanged:=true; end;
    end;
function TShip.FGetNoSelectedControlEdges:integer;
   begin Result:=Surface.NoSelectedControlEdges; end;
function TShip.FGetNoSelectedControlCurves:integer;
   begin  Result:=Surface.NoSelectedControlCurves; end;
function TShip.FGetNoControlCurves:integer;
   begin Result:=Surface.NoControlCurves; end;
function TShip.FGetNoSelectedControlFaces:integer;
   begin Result:=Surface.NoSelectedControlFaces; end;
function TShip.FGetNoSelectedControlPoints:integer;
   begin Result:=Surface.NoSelectedControlPoints; end;
function TShip.FGetNoselectedFlowlines:Integer;
   begin Result:=FselectedFlowlines.Count; end;
function TShip.FGetNoselectedMarkers:Integer;
   begin Result:=FselectedMarkers.Count; end;
function TShip.FGetNoSelectedLockedPoints:integer;
   begin Result:=Surface.NoSelectedLockedPoints; end;
procedure TShip.FSetOnChangeActiveLayer(val:TChangeActiveLayerEvent);
    begin Surface.OnChangeActiveLayer:=val; end;
procedure TShip.FSetOnChangeLayerData(Val:TNotifyEvent);
    begin Surface.OnChangeLayerData:=Val;
          if Assigned(OnChangeLayerData) then OnChangeLayerData;
    end;
procedure TShip.FSetOnSelectItem(Val:TNotifyEvent);
    begin Surface.OnSelectItem:=Val; end;

procedure TShip.FSetPrecision(Val:TPrecisionType);
begin if Val<>FPrecision then begin
         FPrecision:=Val;
         Surface.DivSec:=Ord(Precision)+1;
         FileChanged:=True;
         Build:=False;
         Redraw;
end; end;

function TShip.FGetPreview: TJPEGImage;
var Frm: TViewPort; OldCanvas: TCanvas; I: Integer;
begin Result:=nil;
   if ProjectSettings.FSavePreview then
   for I:=1 to nV do begin Frm:=Viewport[I-1];
      if Frm.ViewPortMode=vmShade then begin
         OldCanvas:=Frm.CanVas;
         Result:=TJPEGImage.Create;
         Result.PixelFormat:=pfDevice; // pf24bit; // pf15bit;
         Result.Width:=Frm.ClientWidth;
         Result.Height:=Frm.ClientHeight;
         Result.CompressionQuality:=25;
         BitBlt(Result.CanVas.Handle,0,0,Frm.ClientWidth,Frm.ClientHeight,Frm.CanVas.Handle,0,0,SRCCOPY);
         Frm.CanVas:=Result.CanVas;
         Frm.Refresh;
         Frm.CanVas:=OldCanVas;             // Result.SaveToFile('F:\test.jpg');
         Frm.RefResh; break;
      end;
   end;
end;

function TShip.AdjustMarkers:Boolean;
begin Result:=False;
   if NoMarkers>0 then
    Result:=MessageDlg(Userstring(180)+'?',mtInformation,[mbYes,mbNo],0)=mrYes;
end;

constructor TShip.Create( AOwner:TComponent );
begin
   Inherited Create( AOwner );
   FIntersectionDialog:=TIntersectionDialog.Create(self);
   FEdit:=SEdit.Create(Self);
   FPreferences:=TPreferences.Create(self);
   FPreferences.Load;
   FProjectSettings:=TProjectSettings.Create(self);
   FFileVersion:=CurrentVersion;                     // Ver.2.6
   FActiveControlPoint:=nil;
   FSurface:=SSurface.Create;
   FViewports:=TFasterList.Create;
   FMarkers:=TFasterList.Create;
   FVisibility:=TVisibility.Create(self);
   FStations:=TFasterList.Create;
   FButtocks:=TFasterList.Create;
   FWaterlines:=TFasterList.Create;
   FDiagonals:=TFasterList.Create;
   FHydrostaticCalculations:=TFasterList.Create;
   FUndoObjects:=TFasterList.Create;
   FBackgroundImages:=TFasterList.Create;
   FFlowLines:=TFasterList.Create;
   FSelectedFlowlines:=TFasterList.Create;
   FSelectedMarkers:=TFasterList.Create;
   FDesignHydrostatics:=HydrostaticCalc.Create(self);
   ClearUndo;
   Clear;
   FControlpointForm:=TControlPointForm.Create(Self);
// FControlpointForm.Ship:=self;
end;

procedure TShip.Clear;
var I:integer; Pt:TPoint;
begin                                                    // Initialize all data
   FPrecision:=fpLow;
   FFileVersion:=CurrentVersion;
   FFileChanged:=False;
   FSurface.Clear;
   FFilename:=Userstring(179);
   FVisibility.Clear;
   FEditMode:=emSelectItems;                    // Set editmode to select items
   ActiveControlPoint:=nil;
   // delete Markers
   for I:=1 to NoMarkers do Marker[I-1].Destroy; FMarkers.Clear;
   FSelectedMarkers.Clear;
   // delete stations
   for I:=1 to NoStations do Station[I-1].Destroy; FStations.Clear;
   // delete Buttocks
   for I:=1 to NoButtocks do Buttock[I-1].Destroy; FButtocks.Clear;
   // delete Waterlines
   for I:=1 to NoWaterlines do Waterline[I-1].Destroy; FWaterlines.Clear;
   // delete Diagonals
   for I:=1 to NoDiagonals do Diagonal[I-1].Destroy;
   for I:=1 to NoHydrostaticCalculations do HydrostaticCalculation[I-1].Calculated:=false;
   FDiagonals.Clear;
   FProjectSettings.Clear;
   FFilenameSet:=False;                              // Delete backgroundimages
   for I:=1 to NoBackgroundImages do BackgroundImage[I-1].Destroy;
   FBackGroundImages.Clear;                                  // Clear flowlines
   for I:=1 to NoFlowlines do Flowline[I-1].Destroy;
   FFlowlines.clear;
   FSelectedFlowlines.Clear;
   if not (csDestroying in componentState) then begin
      Pt.X:=0;                        // remove backgroundimages from viewports
      Pt.Y:=0;
      for I:=1 to nV do
         Viewport[I-1].BackgroundImage.AssignData(nil,fvPerspective,Pt,1.0,False,clBlack,255,100,3,True);
      if assigned(FOnFileChanged) then FOnFileChanged(self);
      if Assigned(OnUpdateGeometryInfo) then OnUpdateGeometryInfo(self);
   end;
end;

procedure TShip.ClearUndo; Var I : integer;
begin                                                             // clear undo
   for I:=1 to UndoCount do UndoObject[I-1].Destroy;
   FUndoObjects.Clear;
   FUndoPosition:=0;
   FPreviousUndoPosition:=FUndoPosition-1;
   if not (csdestroying in componentstate) then
      if Assigned(FOnUpdateUndoData) then FOnUpdateUndoData(self);
end;

destructor TShip.Destroy;
begin
   Clear;
   ClearUndo;
   FControlpointForm.Destroy;
   FMarkers.Destroy;
   FStations.Destroy;
   FButtocks.Destroy;
   FWaterlines.Destroy;
   FDiagonals.Destroy;
   FVisibility.Destroy;
   FViewports.Destroy;
   FSurface.Destroy;
   FEdit.Destroy;
   FProjectSettings.Destroy;
   FDesignHydrostatics.Destroy;
   FHydrostaticCalculations.Destroy;
   FUndoObjects.Destroy;
   FPreferences.Destroy;
   FIntersectionDialog.Destroy;
   FBackgroundImages.Destroy;
   FFlowlines.Destroy;
   FSelectedFlowlines.Destroy;
   FSelectedMarkers.Destroy;
   Inherited Destroy;
end;

procedure TShip.Draw;
var I: integer;
begin        // Redraws model to all viewports by re-initializing all viewports
   for I:=1 to nV do Viewport[I-1].ZoomExtents;
    if LinesplanFrame<>nil then Linesplanframe.Viewport.ZoomExtents;
end;

procedure TShip.DrawToViewport(Viewport:TViewport);
var I,Size,LegendHeight,LegendWidth,RectHeight,Nrect,NDecimal: integer;
    Plane: Plate;
    Curve: TSpline;
    P    : Vector;
    Pt   : TPoint;
    Rect : TRect;
    R,G,B: Byte;
    Tmp  : Real;
    Str  : string;
    procedure DrawPoint(P:Vector;Text:string;CompensateHeight:boolean);
    var Pt: TPoint; Size,Sold: Integer;
    begin
      if CompensateHeight then P.Z:=P.Z+FDesignHydrostatics.FData.ModelMin.Z;
      Pt:=Viewport.Project(P);
      Viewport.FontName:=UFont; //'Arial';
      Viewport.FontColor:=Sp.HydrostaticsFont;
//--  size:=Round(Sqrt(Viewport.Zoom)*7);
//##  size:=Round( Preferences.FontSize*Sqrt( Viewport.Zoom )*0.875 );
      size:=Preferences.FontSize+1;
      if size<3 then size:=3;
      Sold:=Viewport.FontSize;
      Viewport.FontSize:=Size;
//##  Viewport.FontSize:=Preferences.FontSize;
      Size:=Round( Sqrt( Viewport.Zoom )*( Preferences.PointSize+1 ) );
      if size<1 then size:=1;
      Viewport.BrushStyle:=bsClear;
      Viewport.PenColor:=clDkGray; //Black;
      Viewport.BrushColor:=clWhite;
      Viewport.BrushStyle:=bsSolid;
      // Draw entire circle in white;
      Viewport.Canvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
      // Draw upper left part in black
      Viewport.BrushColor:=clBlack;
      Viewport.Canvas.Pie(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size,Pt.X-1,Pt.Y-Size,Pt.X-Size,Pt.Y-1);
      // Draw lower right part in black
      Viewport.Canvas.Pie(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size,Pt.X-1,Pt.Y+Size,Pt.X+Size,Pt.Y-1);
      Viewport.BrushStyle:=bsClear;
      Viewport.Canvas.TextOut(Pt.X+2*size,Pt.Y,Text);
      Viewport.FontSize:=Sold;
    end;

    procedure DrawGrid;
    var DrawStations,DrawButtocks,DrawWaterlines,DrawDiagonals: Boolean;
        Min,Max,P1,P2,Diff: Vector;
        I,J,N,Height,Width: integer; Position: Real;
        Pts: array of TPoint;        Pt1,Pt2: TPoint; Str: string;
    begin
       DrawStations:=Viewport.ViewType<>fvBodyplan;
       DrawButtocks:=Viewport.ViewType<>fvProfile;
       DrawWaterlines:=Viewport.ViewType<>fvPlan;
       DrawDiagonals:=Viewport.ViewType=fvBodyplan; // Blowup the boundary box by 3%
       Diff:=0.03*(Viewport.Max3D-Viewport.Min3D);
       Min:=Viewport.Min3D-Diff;
       Diff:=-1.0*Diff;
       Max:=Viewport.Max3D-diff;
       if DrawStations
       or DrawButtocks
       or DrawWaterlines
       or DrawDiagonals then begin
          Viewport.PenColor:=Sp.Grid;
          Viewport.FontName:=UFont; //'Arial';
          Viewport.FontColor:=Sp.GridFont;   // calculate and set fontheight
          Viewport.Canvas.Font.Size:=Preferences.FontSize; //###
          Height:=Viewport.Canvas.TextHeight('X');
          Viewport.BrushStyle:=bsClear;                      // draw centerline
          if Viewport.ViewType<>fvProfile then begin
             Viewport.FontColor:=clRed;
             Viewport.PenWidth:=2;
             P1:=Min;
             P2:=Max;
             Str:=Userstring(183);
             P1.Y:=0.0;
             P2.Y:=P1.Y;
             Pt1:=Viewport.Project(P1);
             Pt2:=Viewport.Project(P2);
             Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
             Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
             Width:=Viewport.Canvas.TextWidth(Str);
             if Viewport.ViewType=fvBodyplan then begin
                Viewport.Canvas.TextOut(Pt1.X-Width div 2,Pt1.Y,str);
//              Viewport.Canvas.TextOut(Pt2.X-width div 2,Pt2.Y-Height,Str);
             end else begin
//             Viewport.Canvas.TextOut(Pt1.X-Width,Pt1.Y-Height,str);
               Viewport.Canvas.TextOut(Pt2.X,Pt2.Y-Height,Str);
             end;
             Viewport.PenWidth:=1;
             Viewport.FontColor:=Sp.GridFont;
          end;
          if Viewport.Viewtype<>fvPlan then begin
             Viewport.FontColor:=clRed;
             Viewport.PenWidth:=2;                             // Draw baseline
             P1:=Min;
             P2:=Max;
             Position:=Surface.Min.Z;
             Str:=Userstring(184)+#32+ConvertDimension(Position,ProjectSettings.ProjectUnits);
             P1.Z:=Position;
             P2.Z:=P1.Z;
             Pt1:=Viewport.Project(P1);
             Pt2:=Viewport.Project(P2);
             Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
             Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
             Width:=Viewport.Canvas.TextWidth(Str);
//           Viewport.Canvas.TextOut(Pt1.X,Pt1.Y-Height,Str);
             Viewport.Canvas.TextOut(Pt2.X{-Width},Pt2.Y-Height,str);
//##         if ProjectSettings.FMainparticularsHasBeenset then
             begin                                                  // Draw dwl
                P1:=Min;
                P2:=Max;
                Position:=Surface.Min.Z+ProjectSettings.FProjectDraft;
                Str:=Userstring(185)+#32+ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.Z:=Position;
                P2.Z:=P1.Z;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
                Width:=Viewport.Canvas.TextWidth(Str);
//              Viewport.Canvas.TextOut(Pt1.X-width div 2,Pt1.Y-Height,Str);
                Viewport.Canvas.TextOut(Pt2.X{-Width div 2},Pt2.Y-Height,str);
             end;
             Viewport.PenWidth:=1;
             Viewport.FontColor:=Sp.GridFont;
          end;
          if DrawStations then begin
             P1:=Min;
             P2:=Max;
             for I:=1 to self.NoStations do begin
                Position:=-Station[I-1].Plane.d;
                Str:=ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.X:=Position;
                P2.X:=P1.X;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
                Viewport.Canvas.TextOut(Pt1.X,Pt1.Y,Str);
//              Viewport.Canvas.TextOut(Pt2.X,Pt2.Y-Height,Str);
             end;
          end;
          if DrawDiagonals then begin
             Setlength(Pts,101);
             Viewport.PenWidth:=1;
             for I:=1 to NoDiagonals do begin
                if not Diagonal[I-1].Built then Diagonal[I-1].Rebuild;
                for J:=1 to Diagonal[I-1].Count do begin
                   for N:=0 to 100 do begin
                      P1:=Diagonal[I-1].Items[J-1].Value(N/100);
                      Pts[N]:=Viewport.Project(P1);
                   end;
                   Viewport.Canvas.Polyline(Pts);
                   if (Visibility.ModelView=mvBoth)
                   or (Viewport.ViewType=fvBodyplan) then begin
                      for N:=0 to 100 do begin
                         P1:=Diagonal[I-1].Items[J-1].Value(N/100);
                         P1.Y:=-P1.Y;
                         Pts[N]:=Viewport.Project(P1);
                      end;
                      Viewport.Canvas.Polyline(Pts);
                   end;
                end;
             end;
          end;
          if DrawButtocks then begin
             P1:=Min;
             P2:=Max;
             for I:=2 to self.NoButtocks do begin
                Position:=-Buttock[I-1].Plane.d;
                Str:=ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.Y:=Position;
                P2.Y:=P1.Y;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
                if Viewport.ViewType=fvBodyplan
                   then Width:=0
                   else Width:=Viewport.Canvas.TextWidth(Str);
                if Viewport.ViewType=fvBodyplan then begin
                   Viewport.Canvas.TextOut(Pt1.X,Pt1.Y,Str);
//                 Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
                end else begin
                   Viewport.Canvas.TextOut(Pt1.X,Pt1.Y-Height,Str);
//                 Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
                end;
                if (Visibility.ModelView=mvBoth)
                or (Viewport.ViewType=fvBodyplan) then begin
                  P1.Y:=-Position;
                  P2.Y:=P1.Y;
                  Str:=ConvertDimension(-Position,ProjectSettings.ProjectUnits);
                  Width:=Viewport.Canvas.TextWidth(Str);
                  Pt1:=Viewport.Project(P1);
                  Pt2:=Viewport.Project(P2);
                  Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                  Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
                  if Viewport.ViewType=fvBodyplan then begin
                     Viewport.Canvas.TextOut(Pt1.X-Width,Pt1.Y,Str);
//                   Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
                  end else begin
//                   Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y,str);
                     Viewport.Canvas.TextOut(Pt1.X,Pt1.Y,Str);
                  end;
                end;
             end;
          end;
          if DrawWaterlines then begin
             P1:=Min;
             P2:=Max;
             for I:=1 to self.NoWaterlines do begin
                Position:=-Waterline[I-1].Plane.d;
                Str:=ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.Z:=Position;
                P2.Z:=P1.Z;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
                Width:=Viewport.Canvas.TextWidth(Str);
                Viewport.Canvas.TextOut(Pt1.X-Width,Pt1.Y-Height,Str);
//              Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
             end;
          end;                       // Draw Split Section (formerly Mainframe)
          if not (Viewport.Viewtype in [fvBodyplan,fvPerspective]) then begin
            Viewport.FontColor:=clBlue;
            Viewport.PenColor:=clBlue;
            Viewport.PenWidth:=1;
            P1:=iVect( Projectsettings.MidleFrame,Min.Y,Min.Z );
            P2:=iVect( Projectsettings.MidleFrame,Max.Y,Max.Z );
            Position:=Projectsettings.MidleFrame;
//          Str:='Split Section:'+ConvertDimension( Position,ProjectSettings.ProjectUnits );
            Str:=UserString(1671)+': '+ConvertDimension( Position,ProjectSettings.ProjectUnits );
            Pt1:=Viewport.Project( P1 );
            Pt2:=Viewport.Project( P2 );
            Viewport.CanVas.MoveTo(Pt1.X,Pt1.Y+30);
            Viewport.CanVas.LineTo(Pt2.X,Pt2.Y-20);
            Width:=Viewport.CanVas.TextWidth(Str);
            Viewport.CanVas.TextOut(Pt1.X,Pt1.Y-Height+30,Str);
//          Viewport.CanVas.TextOut(Pt2.X-Width,Pt2.Y-Height-20,str);
          end;
       end;
    end;
begin
   if not Surface.Build then surface.Rebuild;
   // Draw intersectionlines BEFORE the surface is drawn,
   // so that the controlnet appears on top
   // But the intersections that should be drawn last depends on the view
   Surface.MainframeLocation:=Projectsettings.MidleFrame;
   if Viewport.Viewtype<>fvPerspective then begin
      if Visibility.ShowGrid then // Draws a rectangular grid with measurements, bigger then the hull
         Drawgrid
      else begin               // draws the actual splines as a dashed line
         if Viewport.ViewType<>fvBodyplan then if Visibility.ShowStations then for I:=1 to NoStations do Station[I-1].Draw(Viewport);
         if Viewport.ViewType<>fvProfile then if Visibility.ShowButtocks then for I:=1 to NoButtocks do Buttock[I-1].Draw(Viewport);
         if Viewport.ViewType<>fvPlan then if Visibility.ShowWaterlines then for I:=1 to NoWaterlines do Waterline[I-1].Draw(Viewport);
         if Visibility.ShowDiagonals then for I:=1 to NoDiagonals do Diagonal[I-1].Draw(Viewport);
      end;
      if (Viewport.ViewType=fvBodyplan) and (Visibility.ShowStations) then for I:=1 to NoStations do Station[I-1].Draw(Viewport);
      if (Viewport.ViewType=fvProfile) and (Visibility.ShowButtocks) then for I:=1 to NoButtocks do Buttock[I-1].Draw(Viewport);
      if (Viewport.ViewType=fvPlan) and (Visibility.ShowWaterlines) then for I:=1 to NoWaterlines do Waterline[I-1].Draw(Viewport);
      if (Viewport.ViewType<>fvBodyplan) and (Visibility.ShowDiagonals) then for I:=1 to NoDiagonals do Diagonal[I-1].Draw(Viewport);
   end else begin
      if Visibility.ShowStations then for I:=1 to NoStations do Station[I-1].Draw(Viewport);
      if Visibility.ShowButtocks then for I:=1 to NoButtocks do Buttock[I-1].Draw(Viewport);
      if Visibility.ShowWaterlines then for I:=1 to NoWaterlines do Waterline[I-1].Draw(Viewport);
      if Visibility.ShowDiagonals then for I:=1 to NoDiagonals do Diagonal[I-1].Draw(Viewport);
   end;
   if (Visibility.ShowMarkers) and (Viewport.ViewportMode=vmWireframe)then
      for I:=1 to NoMarkers do Marker[I-1].Draw(Viewport);
   Surface.Color:=clDkGray;
   Surface.ShowControlNet:=Visibility.ShowControlNet;
   Surface.ShowInteriorEdges:=Visibility.ShowInteriorEdges;
   Surface.DrawMirror:=Visibility.ModelView=mvBoth;
   Surface.ShowNormals:=Visibility.ShowNormals;
   Surface.ControlPointSize:=Preferences.PointSize;
   Surface.ShowCurvature:=Visibility.ShowCurvature;
// Surface.CurvatureScale:=Visibility.CurvatureScale;
   Surface.ShowControlCurves:=Visibility.ShowControlCurves;
   if Sp.UColorIs then begin //.ProjectShadeUnderwaterShip then begin
      Plane.a:=0.0;
      Plane.b:=0.0;
      Plane.c:=1.0;
      Plane.d:=-(FindLowestHydrostaticsPoint+ProjectSettings.ProjectDraft);
      Surface.WaterlinePlane:=Plane;
   end;
   Surface.Draw(Viewport);
   if (Viewport.Viewtype<>fvPerspective)
   and (Viewport.ViewportMode<>vmWireframe)
   and (Visibility.ShowGrid) then begin
      // Shaded viewport is a special case when visibility.drawgrid has been set to tru
      if Visibility.ShowStations then for I:=1 to NoStations do Station[I-1].Draw(Viewport);
      if Visibility.ShowButtocks then for I:=1 to NoButtocks do Buttock[I-1].Draw(Viewport);
      if Visibility.ShowWaterlines then for I:=1 to NoWaterlines do Waterline[I-1].Draw(Viewport);
      if Visibility.ShowDiagonals then for I:=1 to NoDiagonals do Diagonal[I-1].Draw(Viewport);
   end;
   if (Viewport.ViewportMode=vmWireframe)
   and (Visibility.ShowHydrostaticData) then begin     // Draw hydrostatic data
      if FDesignHydrostatics.Draft<>ProjectSettings.ProjectDraft then FDesignHydrostatics.Draft:=ProjectSettings.ProjectDraft;
      if not FDesignHydrostatics.Calculated then FDesignHydrostatics.Calculate;
      Viewport.FontSize:=Preferences.FontSize-1;
      if Visibility.FShowHydrostDisplacement then         // Center of bouyancy
         DrawPoint(FDesignHydrostatics.FData.CenterOfBuoyancy,'C:'  // 'Displ='
         +FloatToDec( FDesignHydrostatics.Data.Displacement,1 ),True);
      if Visibility.FShowHydrostMetacentricHeight then // Transverse metacentric height
         DrawPoint(iVect( FDesignHydrostatics.FData.CenterOfBuoyancy.X,0.0,
                          FDesignHydrostatics.FData.KMtransverse),'m: ' // 'KM='
        +FloatToDec(FDesignHydrostatics.Data.KMtransverse,2),True);
      if Visibility.FShowHydrostLCF then // Longitudinal center of floatation
         DrawPoint(FDesignHydrostatics.FData.WaterplaneCOG,'S: '       // 'LCF='
        +FloatToDec(FDesignHydrostatics.Data.WaterplaneCOG.X,2),False);
      if Visibility.FShowHydrostLateralArea then              // Lateral center
         DrawPoint(FDesignHydrostatics.FData.LateralCOG,Userstring(1678)+'='
         +FloatToDec(FDesignHydrostatics.Data.LateralArea,2),True);
      if (Viewport.ViewType=fvProfile)     // строевая по шпангоутам ?? масштаб
      and (Visibility.FShowHydrostSectionalAreas) then begin
         Curve:=Tspline.Create;                          // sectionalarea curve
         with FDesignHydrostatics.FData do begin Tmp:=0.0;
           for I:=0 to length( SAC )-1 do if Tmp<SAC[I].Y then Tmp:=SAC[I].Y;
           Tmp:=1.3*(ModelMax.Z-ModelMin.Z)/Tmp;
           for I:=0 to length( SAC )-1 do
               Curve.Add( iVect( SAC[I].X,0,ModelMin.Z+Tmp*SAC[I].Y ) );
         end;
         Curve.Color:=Sp.HydrostaticsFont;
         Curve.Draw(Viewport);
         for I:=1 to Curve.nS do begin
            P:=Curve.Point[I-1];
            Pt:=Viewport.Project(P);
            Size:=round( Sqrt(Viewport.Zoom)*3 );
            if Size<1 then Size:=1;
            Viewport.Canvas.MoveTo( Pt.X,Pt.Y-Size );
            Viewport.Canvas.LineTo( Pt.X,Pt.Y+Size );
            Viewport.Canvas.MoveTo( Pt.X-Size,Pt.Y );
            Viewport.Canvas.LineTo( Pt.X+Size,Pt.Y );
            Str:=FloatToDec(FDesignHydrostatics.FData.SAC[I-1].Y,2);
            if P.X<FProjectsettings.MidleFrame
               then Viewport.Canvas.TextOut(Pt.X-Viewport.Canvas.TextWidth(str),Pt.Y-Viewport.Canvas.TextHeight(str),Str)
               else Viewport.Canvas.TextOut(Pt.X,Pt.Y-Viewport.Canvas.TextHeight(str),Str);
         end;  Curve.Destroy;
      end;     Viewport.FontSize:=Preferences.FontSize;
   end;                                                        // Drawflowlines
   if Visibility.ShowFlowlines then
      For I:=1 to NoFlowlines do Flowline[I-1].Draw(Viewport);
   if (Viewport.ViewportMode=vmShadeGauss)
   and (Surface.NoControlFaces>0) // Draw Legend with Gaussian curvature values
   and (Surface.MaxGaussCurvature-Surface.MinGaussCurvature>1e-7) then begin
      NRect:=21;
      LegendHeight:=round(0.5*Viewport.ClientHeight);
      if LegendHeight<100 then LegendHeight:=100;
      if LegendHeight>0.9*Viewport.ClientHeight then LegendHeight:=round(0.9*Viewport.ClientHeight);
      if LegendHeight>250 then LegendHeight:=250;
      RectHeight:=round(LegendHeight/NRect);
      LegendHeight:=NRect*RectHeight;
      LegendWidth:=20;
      Viewport.PenColor:=Viewport.Color;
      Viewport.PenStyle:=psClear;
      Viewport.PenWidth:=1;
      Rect.Left:=5;
      Rect.Top:=5;
      Rect.Bottom:=Rect.Top+LegendHeight;
      Rect.Right:=Rect.Left+LegendWidth;
      Viewport.Canvas.Rectangle(Rect);
      Viewport.FontName:=UFont;
      Viewport.FontSize:=Preferences.FontSize; //8;
      Viewport.FontColor:=Sp.GridFont;
      NDecimal:=3;
      for I:=1 to NRect do begin
         Rect.Bottom:=Rect.Top+RectHeight;
         FillColor(I/Nrect,R,G,B);
         Viewport.BrushColor:=RGB(R,G,B);
         Viewport.BrushStyle:=bsSolid;
         Viewport.Canvas.Rectangle(Rect);
         Viewport.BrushStyle:=bsClear;
         if odd(I) then begin
            Tmp:=(I-1)/(NRect-1);
            if Tmp>=0.5 then begin
               Tmp:=2*(Tmp-0.5);
               Str:=FloatToDec(Surface.MinGaussCurvature*Tmp,NDecimal);
            end else if Tmp<0.5 then begin
               Tmp:=2*(0.5-Tmp);
               Str:=FloatToDec(Surface.MaxGaussCurvature*Tmp,NDecimal);
            end else Str:='0.0';
            Viewport.Canvas.TextOut(Rect.Right+5,(Rect.Top+Rect.Bottom-Viewport.Canvas.TextHeight(str)) div 2,Str);
         end;
         Rect.Top:=Rect.Top+RectHeight;
      end;
   end;
// if ActiveControlPoint<>nil then ActiveControlPoint:=ActiveControlPoint;
end; {DrawToViewport}

procedure TShip.Extents( Var Min,Max:Vector );
// calculate the bounding box coordinates of the model
var I : integer;
begin
   if Surface.NoControlFaces>0 then begin
      Surface.DrawMirror:=Visibility.ModelView=mvBoth;
      Min.X:=1e4;
      Min.Y:=Min.X;
      Min.Z:=Min.X;
      Max.X:=-Min.X;
      Max.Y:=-Min.Y;
      Max.Z:=-Min.Z;
      Surface.Extents( Min,Max );
      if Visibility.ShowMarkers then for I:=1 to NoMarkers do Marker[I-1].Extents(Min,Max);
   end else begin
      if Surface.NoControlPoints>1 then begin
         for I:=1 to Surface.NoControlPoints do
         if I=1 then begin
            Min:=Surface.ControlPoint[I-1].Coordinate;
            Max:=Min;
         end else MinmAx( Surface.ControlPoint[I-1].Coordinate,Min,Max );
      end else begin
         Min.X:=-1;
         Min.Y:=Min.X;
         Min.Z:=Min.X;
         Max.X:=-Min.X;
         Max.Y:=Max.X;
         Max.Z:=Max.X;
      end;
   end; // Min:=1.06*Min; Max:=1.06*Max;;
end;

function TShip.FindLowestHydrostaticsPoint:Real;
var I,J: Integer; First: Boolean; Layer: SLayer;
begin
   Result:=Surface.Min.Z;
   First:=True;
   for I:=1 to NoLayers do begin
      Layer:=Surface.Layer[I-1];
      if Layer.UseInHydrostatics then for J:=1 to Layer.Count do begin
         if First then begin
            Result:=Layer.Items[J-1].Min.Z;
            First:=False;
         end else begin
            if Layer.Items[J-1].Min.Z<Result then Result:=Layer.Items[J-1].Min.Z;
         end;
      end;
   end;
end;

// loads the preview image from a file
(*
procedure TShip.LoadPreview(Filename:string;Image:TJPegImage);
var Source: TFileBuffer; I: integer; Str: String;
begin
   Source:=TFileBuffer.Create;
   Source.LoadFromFile(FileName);             // Load everything into memory
   Source.Reset;
   Source.LoadString(Str);
   if Str='FREE!ship' then begin
      Source.LoadTFileVersion(FFileVersion);
      Source.Version:=FFileVersion;
      if FFileVersion>=fv210 then begin
         Source.LoadInteger(I);
         Precision:=TPrecisionType(I);
         Visibility.LoadBinary(Source);
         ProjectSettings.LoadBinary(Source,Image);
      end;
   end;
   Source.Destroy;
end;
*)
procedure TShip.RebuildModel;
var PrevCursor : TCursor;
begin
   PrevCursor:=Screen.Cursor;
   if Screen.Cursor<>crHourglass then Screen.Cursor:=crHourglass;
   Build:=False;
   Surface.DivSec:=Ord(Precision)+1;
   Surface.Rebuild;
   Draw;
   //if Screen.Cursor<>PrevCursor then
   Screen.Cursor:=PrevCursor;
end;

procedure TShip.Redraw;
  var I: integer;
begin                         // Redraws model to all viewports using the
   For I:=0 to nV-1 do begin  // current min/max coordinates of the boundingbox
      if Viewport[I].Zoom=1.0 then Viewport[I].ZoomExtents
                              else Viewport[I].Refresh;
   end;
   if LinesplanFrame<>nil then Linesplanframe.Viewport.Refresh;
end;

procedure TShip.SubmergedHullExtents(Wlplane:Plate;var Min,Max:Vector);
var I,J,K,L   : Integer;
    FirstPoint: boolean;
    Layer     : SLayer;
    Face      : SControlFace;
    Child     : SFace;
    P1,P2,P   : Vector;
    s1,s2,T   : Real;
begin
   FirstPoint:=True;
   for I:=1 to NoLayers do begin
      Layer:=Surface.Layer[I-1];
      if Layer.UseInHydrostatics then for J:=1 to Layer.Count do begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do begin
            Child:=Face.Child[K-1];
            P1:=Child.Point[Child.NoPoints-1].Coordinate;
            s1:=WlPlane.a*P1.x+WlPlane.b*P1.y+WlPlane.c*P1.z+WlPlane.d;
            for L:=1 to Child.Nopoints do begin
               P2:=Child.Point[L-1].Coordinate;
               s2:=WlPlane.a*P2.x+WlPlane.b*P2.y+WlPlane.c*P2.z+WlPlane.d;
               if ((S1<0) and (S2>0)) or ((S1>0) and (S2<0)) then begin // intersection
                  if S1=S2 then T:=0.5
                           else T:=-s1/(s2-s1);
                  P:=P1+T*(P2-P1);
                  if FirstPoint then begin
                     Min:=P;
                     Max:=P;
                     FirstPoint:=False;
                  end else MinMax(P,Min,Max);
                  if Layer.Symmetric then begin
                     P.Y:=-P.Y;
                     MinMax(P,Min,Max);
                  end;
               end;
               if S2<=0 then begin
                  if FirstPoint then begin
                     Min:=P2;
                     Max:=P2;
                     FirstPoint:=False;
                  end else MinMax(P2,Min,Max);
                  if Layer.Symmetric then begin
                     P2.Y:=-P2.Y;
                     MinMax(P2,Min,Max);
                  end;
               end;
               P1:=P2;
               S1:=S2;
            end;
         end;
      end;
   end;
   if FirstPoint then begin                            // no valid points found
      Min:=ZERO; Max.X:=1; Max.Y:=1; Max.Z:=1;
   end;
end;

procedure TShip.KeyUp(Viewport:TViewport;var Key: Word;Shift: TShiftState);
const Left  = 37;
      Right = 39;
      Up    = 38;
      Down  = 40;
var Point: SControlPoint; P: Vector;
begin
   if (Key in [Left..Down])
   and (Viewport.ViewType<>fvPerspective)
   and (ActiveControlPoint<>nil) then begin
      Edit.CreateUndoObject(Userstring(190),True);
      Point:=ActiveControlPoint;
      FileChanged:=True;
      Build:=False;
      P:=Point.Coordinate;
      Case Viewport.Viewtype of
         fvProfile: Case Key of
           Left : P.X:=P.X-Visibility.CursorIncrement;
           Up   : P.Z:=P.Z+Visibility.CursorIncrement;
           Right: P.X:=P.X+Visibility.CursorIncrement;
           Down : P.Z:=P.Z-Visibility.CursorIncrement; end;
         fvPlan: Case Key of
           Left : P.X:=P.X-Visibility.CursorIncrement;
           Up   : P.Y:=P.Y+Visibility.CursorIncrement;
           Right: P.X:=P.X+Visibility.CursorIncrement;
           Down : P.Y:=P.Y-Visibility.CursorIncrement; end;
         fvBodyplan: Case Key of
           Left : if P.X<=self.ProjectSettings.MidleFrame
                   then P.Y:=P.Y+Visibility.CursorIncrement
                   else P.Y:=P.Y-Visibility.CursorIncrement;
           Up   : P.Z:=P.Z+Visibility.CursorIncrement;
           Right: if P.X<=self.ProjectSettings.MidleFrame
                   then P.Y:=P.Y-Visibility.CursorIncrement
                   else P.Y:=P.Y+Visibility.CursorIncrement;
           Down : P.Z:=P.Z-Visibility.CursorIncrement; end;
      end;
      Point.Coordinate:=P;
      ActiveControlPoint:=Point;
      if ControlpointForm.Visible then begin
         // This lines updates the coordinate information in the controlpoint form
         ControlPointform.ActiveControlPoint:=Point;
         // and forces a repaint of the form
         if not Viewport.Focused then Viewport.SetFocus;
         application.ProcessMessages;
      end;
      Build:=False;
      Redraw;
   end else
   if (Key in [187,189,107,109]) and (Viewport.ViewType<>fvPerspective) then begin
      if Key in [107,187] then Visibility.CursorIncrement:=1.1*Visibility.CursorIncrement
                          else Visibility.CursorIncrement:=Visibility.CursorIncrement/1.1;
   end;
end;

procedure TShip.MouseDown
( Viewport:TViewport;
  Button:TMouseButton;
  Shift:TShiftState;
  X,Y:integer;
  var ItemSelected:Boolean );
var I,J: integer; P3D: Vector; Tmp,MinDistance:Real;
    Point: SControlPoint;
    Edge: SControlEdge;
    Curve: SControlCurve;
    Face: SControlFace;
    Entity: SBase;
begin
   ItemSelected:=False;
   if Button=mbLeft then begin
      Case EditMode of
         emSelectItems: begin Entity:=nil; I:=1;    // First check the vertices
           while I<=Surface.NoControlPoints do begin
              if Surface.ControlPoint[I-1].Visible then begin
                 Point:=Surface.ControlPoint[I-1];
                 if Point.DistanceToCursor( X,Y,Viewport )<=SelectDistance then begin
                    Tmp:=Abs( Point.Coordinate-ViewPort.CameraLocation );
                    if not ItemSelected then begin
                      ItemSelected:=True;   // Draw selected point to viewports
                      MinDistance:=Tmp;
                      Entity:=Point;      // Point.Selected:=not Point.Selected;
                    end else
                    if Tmp<MinDistance then begin
                       Tmp:=MinDistance;
                       Entity:=Point;      // Point.Selected:=not Point.Selected;
                    end; // else continue;
                 end;
              end; Inc(I);
           end;
           if ItemSelected then for J:=0 to nV-1 do
              if self.Viewport[J].ViewportMode=vmWireframe then
                  SControlPoint( Entity ).Draw(self.Viewport[J]);

           if Entity=nil then begin // No points found, search for nearest controlEdge
              I:=1;
              while I<=Surface.NoControlEdges do begin
                 if Surface.ControlEdge[I-1].Visible then begin
                    Edge:=Surface.ControlEdge[I-1];
                    Tmp:=Edge.DistanceToCursor(X,Y,P3D,Viewport);
                    if Tmp<=SelectDistance then begin
                       Entity:=Edge;
                       Edge.Selected:=not Edge.Selected;
                    // If CTRL key is pressed, select multiple edges in one pass
                    // by tracing regular edges to a boundary or irregular points
                       if (ssCtrl in shift) then Edge.Trace;
                       ItemSelected:=True;
                       // Draw the selected edge to all viewports
                       for J:=1 to nV do Self.Viewport[J-1].Refresh;
                       break;
                    end;
                 end;  Inc(I);
              end;
           end;
           if (Entity=nil) and (Visibility.ShowInteriorEdges) then begin
              Surface.ShowInteriorEdges:=True; // No edges found, search for nearest control-face
              I:=1;
              while I<=Surface.NoControlFaces do begin
                 if Surface.ControlFace[I-1].Visible then begin
                    Face:=Surface.ControlFace[I-1];
                    Tmp:=Face.DistanceToCursor(X,Y,P3D,Viewport);
                    if Tmp<=SelectDistance then begin
                       Entity:=Face;
                       Face.Selected:=not Face.Selected;
                       // If CTRL key is pressed, select all connected controlfaces that
                       // belong to the same layer and are not separated by a crease edge
                       // and have the same selected state
                       if (ssCtrl in shift) then begin Face.Trace; end;
                       ItemSelected:=True;
                       // Draw the selected faces to all viewports
                       for J:=1 to nV do Self.Viewport[J-1].Refresh;
                       break;
                    end;
                 end; Inc(I);
              end;
           end;
           if (Entity=nil) then begin I:=1;
              while I<=Surface.NoControlCurves do begin
                 if Surface.ControlCurve[I-1].Visible then begin
                    Curve:=Surface.ControlCurve[I-1];
                    Tmp:=Curve.DistanceToCursor(X,Y,Viewport);
                    if Tmp<=SelectDistance then begin
                       Entity:=Curve;
                       Curve.Selected:=not Curve.Selected;
                       ItemSelected:=True; // Draw the selected edge to all viewports
                       for J:=1 to nV do
                         if self.Viewport[J-1].ViewportMode=vmWireframe then
                           Curve.Draw(self.Viewport[J-1]);
                       break;
                    end;
                 end; Inc(I);
              end;
           end;                                              // check flowlines
           if (Entity=nil) and (not ItemSelected)
           and (Visibility.ShowFlowlines) then begin I:=1;
              while I<=NoFlowlines do begin
                 Tmp:=Flowline[I-1].DistanceToCursor(X,Y,Viewport);
                 if Tmp<=SelectDistance then begin
                    Flowline[I-1].Selected:=not Flowline[I-1].Selected;
                    ItemSelected:=True; // Draw the selected flowline to all viewports
                    for J:=1 to nV do
                      if self.Viewport[J-1].ViewportMode=vmWireframe then
                        Flowline[I-1].Draw(self.Viewport[J-1]);
                    break;
                 end; Inc(I);
              end;
           end;                                                // check Markers
           if (Entity=nil) and (not ItemSelected)
           and (Visibility.ShowMarkers) then begin I:=1;
              while I<=NoMarkers do begin
                 Tmp:=Marker[I-1].DistanceToCursor(X,Y,Viewport);
                 if Tmp<=SelectDistance then begin
                    Marker[I-1].Selected:=not Marker[I-1].Selected;
                    ItemSelected:=True; // Draw the selected Marker to all viewports
                    for J:=1 to nV do
                      if self.Viewport[J-1].ViewportMode=vmWireframe then
                         Marker[I-1].Draw(self.Viewport[J-1]);
                    break;
                 end;
                 Inc(I);
              end;
           end;
           if Entity<>nil then begin  // apparently SOMEthing has been selected
              if Entity is SControlPoint then begin
           // If CTRL key is pressed, selection of multiple controlpoints
           //    is allowed, otherwise select only ONE controlpoint
                 Point:=Entity as SControlPoint;
                 if not (ssCtrl in shift) then begin
                    if NoSelectedControlPoints>0 then
                      for I:=NoSelectedControlPoints downto 1 do SelectedControlPoint[I-1].Selected:=False;
                    Point.Selected:=True;
                 end else
                 if not Point.Selected then begin
                   Point.Selected:=True;
//                 Point:=SelectedControlPoint[NoSelectedControlPoints-1];
                 end;;
                 for J:=1 to nV do self.Viewport[J-1].Refresh;
                 if ActiveControlPoint<>point then ActiveControlPoint:=Point;
                 FCurrentlyMoving:=True;
                 FPointHasBeenMoved:=False;
                 FPrevCursorPosition.X:=X;
                 FPrevCursorPosition.Y:=Y;
              end else
              if Entity is SControlCurve then begin
                 for J:=1 to nV do
                  if self.Viewport[J-1].ViewportMode=vmWireframe then
                     self.Viewport[J-1].Refresh;
              end;
           end;
         end;
      end;
   end else if Button=mbRight then EditMode:=emSelectItems;
   // if ActiveControlPoint<>nil then ActiveControlPoint:=ActiveControlPoint;
   // if not Viewport.Focused then Viewport.SetFocus;
end;

procedure TShip.MouseMove(Viewport:TViewport; Shift: TShiftState; X,Y: integer);
var P2D: Place; P: Vector; PtS: SControlPoint; I: Integer; //  Pt: TPoint;
begin
   Case EditMode of
      emSelectItems: 
        if (ActiveControlPoint<>nil) 
        and (FCurrentlyMoving) 
        and (ssLeft in shift) 
        and (Viewport.ViewType<>fvPerspective) then begin
           if (X<>FPrevCursorPosition.X) or (Y<>FPrevCursorPosition.Y) then begin
              if FPointHasBeenMoved=False then begin
                 // This is the first time the vertex is moved
                 // Apply a certain threshold to make sure that
                 // the controlpoint is not moved by accident
                 if hypot( X-FPrevCursorPosition.X,Y-FPrevCursorPosition.Y )<Threshold then exit;
                 if ActiveControlPoint.Locked then begin
                    ShowMessage( Userstring(191)+'!' );
                    exit;
                 end;
                 Edit.CreateUndoObject(Userstring(190),True);
              end;
              PtS:=ActiveControlPoint;
              FileChanged:=True;
              Build:=False;
              FPointHasBeenMoved:=True;
              P2D:=Viewport.ProjectBackTo2D( Point( X,Y ) );
              P:=PtS.Coordinate;
              Case Viewport.Viewtype of
                 fvProfile : begin P.X:=P2D.X; P.Z:=P2D.Y; end;
                 fvPlan    : begin P.X:=P2D.X; P.Y:=P2D.Y; end;
                 fvBodyplan: begin
                   if P.X<=ProjectSettings.MidleFrame
                    then P.Y:=-P2D.X
                    else P.Y:=P2D.X;
                         P.Z:=P2D.Y; end;
              end;
              PtS.Coordinate:=P;
              ActiveControlPoint:=PtS;
              if ControlpointForm.Visible then begin
                 // This lines updates the coordinate information in the controlpoint form
                 ControlPointform.ActiveControlPoint:=PtS;
                 // and forces a repaint of the form
                 if not Viewport.Focused then Viewport.SetFocus;
                 application.ProcessMessages;
                 TForm(Viewport.Owner).BringToFront;
              end;
              Build:=False;
              for I:=1 to nV do self.Viewport[I-1].Refresh;
              if LinesplanFrame<>nil then Linesplanframe.Viewport.Refresh;
              FPrevCursorPosition:=Point( X,Y );
           end;
        end;
   end;
end;

procedure TShip.MouseUp(Viewport:TViewport;Shift:TShiftState;X,Y:integer);
begin FCurrentlyMoving:=False; if not Viewport.Focused then Viewport.SetFocus;
end;

procedure TShip.ZoomFitAllViewports; var I: integer;
begin        // Redraws model to all viewports by re-initializing all viewports
  with Application.MainForm as TMainForm do begin
    for I:=0 to nV-1 do ViewPort[I].ZoomExtents;
    if LinesplanFrame<>nil then Linesplanframe.Viewport.ZoomExtents;
  end;
end;

procedure TShip.SelectPointsInFrame( Viewport: TViewport; rect: TRect );
var I: Integer; Point: SControlPoint; P2D: TPoint;
begin
  case EditMode of
    emSelectItems: with Rect do begin
      if Left>Right then begin I:=Left; Left:=Right; Right:=I; end;
      if Top>Bottom then begin I:=Top; Top:=Bottom; Bottom:=I; end;
      for I:=0 to Surface.NoControlPoints-1 do // это по узлам для начала
      if Surface.ControlPoint[I].Visible then begin
         Point:=Surface.ControlPoint[I];
         P2D:=Viewport.Project(Point.Coordinate);
         if (P2D.x >= Left) and (P2D.x <= Right)
         and (P2D.y >= Top) and (P2D.y <= Bottom)
         then self.Surface.Selection_Add( Point );
      end;
      ReDraw; MainForm.UpdateMenu;
    end;
  end;
end;

function SEdit.File_SaveCheck: word;               // добавлено из 5 версии
begin result:=mrOk;
//if not St.ModelIsLoaded then St.FileChanged:=false else
  if St.FileChanged then begin // корпрус редактировался и дорасчитывался
    Result:=MessageDlg(UserString(103)+EOL+UserString(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
    if Result=mrOk then File_SaveAs;
    if Result<>mrCancel then begin // mrCancel-отмена операций
      St.ClearUndo;                // здесь корпус просто расчищается
      St.Clear;                    // здесь FFileChanged:=False
      St.Surface.ClearSelection;
      St.Surface.ClearFaces;
      St.Surface.Clear;
    end;
  end;
end;

{$I ShipU_IO.inc} // операции ввода/вывода для *.fbm, *.ftm и *.fef
{$I ShipU_EX.inc} // импорт/экспорт ... всякой твари по паре ...
{$I ShipU_HS.inc} // HydrostaticCalc is an object class for hydrostatic calculations.

procedure Register; begin RegisterComponents('Ship', [TShip]); end;

end.

