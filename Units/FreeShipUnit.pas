
unit FreeShipUnit;
interface   // do WIndows-specific code here
uses Forms, // this declaration must be at the start, before the FreeGeometry unit
     SysUtils,
     Controls, LazFileUtils, //LazUTF8,
     Windows,  iniFiles,
     Dialogs,
     Classes,
     Graphics,
     FreeGeometry,FreeFileBuffer,
     FreeMatrices,
     FasterList,FreeTypes,FreeLanguageSupport,FreeVersionUnit,FreeControlPointFrm;
  // FREE!ship uses British imperial format, eg 1 long ton=2240 lbs

const FreeShipExtention='.ftm'; // Default extention for hull model files
      SelectDistance   = 3;     // Max. distance in pixels between an item and the cursor in order to be selected
      Threshold        = 3;     // The distance that the cursor has to be moved before a controlpoint starts moving
      FontheightFactor = 140;   // used for calculating fontheight
type
     TFreeHydrostaticType         = (fhShort,fhExtensive);                        // Determines how calculations are performed: short, extensive etc.
     TFreeHydrostaticsMode        = (fhSingleCalculation,fhMultipleCalculations); // Used when creating hydrostatic reports
     TFreeHydrostaticsCalculation = (hcAll,hcVolume,hcMainframe,hcWaterline,hcSAC,hcLateralArea);
     TFreeHydrostaticsCalculate   = set of TFreeHydrostaticsCalculation;          // Set with all calculations to be performed
     TFreeShip                    = class;                                        // to be declared later
     TFreeIntersection            = class;
     TFreeHydrostaticError        = (feNothingSubmerged,feMakingWater,feNotEnoughBuoyancy); // Errors that may occur when calculating hydrostatics
     TFreeHydrostaticErrors       = set of TFreeHydrostaticError;
     TFreeHydrostaticCoeff        = (fcProjectSettings,fcActualData);
     TFreeHydrostaticsData        = record
        ModelMin,ModelMax       : T3DVector;        // Min/max coordinates under given heelingangle and trim
        WlMin,WlMax             : T3DVector;        // Min/max coordinates of the waterline
        SubMin,SubMax           : T3DVector;        // Min/max extents of the submerged body
        WaterlinePlane          : T3DPlane;
        AbsoluteDraft           : TFloatType;       // Depth of the lowest point of the hull beneath the waterplane
                                                    // The following properties are always calculated
        Volume                  : TFloatType;       // Displaced volume of the hull
        Displacement            : TFloatType;       // Displacement
        CenterOfBuoyancy        : T3DVector;        // Center of gravity of displaced volume
        LCBPerc                 : TFloatType;
        LengthWaterline         : TFloatType;
        BeamWaterline           : TFloatType;
        BlockCoefficient        : TFloatType;       // BlockCoefficient
        WettedSurface           : TFloatType;
        Leak                    : T3DVector;        // Coordinate encountered where the ship is making water
        // Mainframe properties
        Mainframearea           : TFloatType;
        MainFrameCOG            : T3DVector;
        MainframeCoeff          : TFloatType;       // Waterplane properties
        Waterplanearea          : TFloatType;
        WaterplaneCOG           : T3DVector;
        WaterplaneEntranceAngle : TFloatType;
        WaterplaneCoeff         : TFloatType;
        WaterplaneMomInertia    : T2DCoordinate;    // Stability data
        KMtransverse            : TFloatType;
        KMlongitudinal          : TFloatType;       // Lateral area and center
        LateralArea             : TFloatType;
        LateralCOG              : T3DVector;        // Prismatic coefficient
        PrismCoefficient        : TFloatType;       // Prismatic coefficient
        VertPrismCoefficient    : TFloatType;       // Sectional areas
        SAC                     : array of T2DCoordinate;
     end;

   { TFreeUndoObject is an object class for undoing actions.
     It's function is very basic, just before each modification the file
     is saved to a the undo object rather then to a file. When the undo is
     called, the previous state will be read from the undo object and restored
   }
     TFreeUndoObject = class
     private
        FOwner           : TFreeShip;
        FUndoData        : TFreeFileBuffer;     // some other data to be stored
        FFileChanged     : Boolean;
        FFilenameSet     : Boolean;
        FUndoText,FFilename: String;
        FEditMode        : TFreeEditMode;
        FTime            : TDateTime;
        FIsTempRedoObject: Boolean;
        function FGetMemory:integer; // calculates the amount of bytes used for each undo object
        function FGetTime:string;
        function FGetUndoText:string;
     public
        procedure Accept;
        constructor Create(Owner:TFreeShip);
        procedure Delete;
        destructor Destroy; override;
        procedure Restore;
        property Memory  : integer read FGetMemory; // calculates the amount of bytes used for each undo object
        property Owner   : TFreeShip read FOwner;
        property Time    : String read FGetTime;
        property UndoData: TFreeFileBuffer read FUndoData;
        property UndoText: string read FGetUndoText;
      end;
     {
        Freeship can import a max. of three different background images that
        may be coupled either to the bodyplan, profile or planview.
        These images can be used to trace the lines of an
        hullform and are stored within the FREE!ship file.
     }
     TFreeBackgroundImageData=class
     private
        FOwner         : TFreeship;
        FAssignedView  : TFreeViewType;
        FImageData     : TJPEGImage;
        FQuality       : Integer;
        FOrigin        : TPoint;
        FScale         : TFloatType;
        FTransparent   : Boolean;
        FBlendingValue : Integer;
        FTransparentColor:TColor;
        FVisible       : Boolean;
        FTolerance     : Integer;
     public
        procedure Clear;
        constructor Create(Owner:TFreeship);
        destructor Destroy;              override;
        procedure LoadBinary(Source:TFreeFileBuffer);
        procedure SaveBinary(Destination:TFreeFileBuffer);
        procedure UpdateData(Viewport:TFreeViewport);
        procedure UpdateViews;
        property AssignedView      : TFreeViewType read FAssignedView;
        property BlendingValue     : Integer read FBlendingValue;
        property Image             : TJPEGImage read FImageData;
        property Origin            : TPoint read FOrigin;
        property Quality           : Integer read FQuality;
        property Scale             : TFloatType read FScale;
        property Tolerance         : integer read FTolerance;
        property Transparent       : Boolean read FTransparent;
        property TransparentColor  : TColor read FTransparentColor;
     end;
     {
        TFreeHydrostaticCalc is an object class for hydrostatic calculations.
        Each calculation has it's own draft, trim and angle of heel.
        Multiple calculations can be stored and then send to a report.
     }
     TFreeHydrostaticCalc= class
     private
        FOwner       : TFreeShip;        // Input data for each calculation
        FHeelingAngle: TFloatType;
        FTrim        : TFloatType;
        FDraft       : TFloatType;       // Calculation flags
        FCalculated  : Boolean;
        FErrors      : TFreeHydrostaticErrors;
        FHydrostaticType: TFreeHydrostaticType; // Determines how calculations are performed: short, extensive etc.

        FData        : TFreeHydrostaticsData; // The following data is calculated
        FCalculations: TFreeHydrostaticsCalculate;
        FMainFrame   : TFreeIntersection;
//      function FGetErrorString:string;
        function FGetTrimAngle:TFloatType;
        function FGetWlPlane:T3DPlane;
        procedure FSetCalculated(val:Boolean);
        procedure FSetDraft(Val:TFloatType);
        procedure FSetErrors(val:TFreeHydrostaticErrors);
        procedure FSetHeelingAngle(Val:TFloatType);
        procedure FSetHydrostaticType(val:TFreeHydrostaticType);
        procedure FSetTrim(Val:TFloatType);
     public
        constructor Create(Owner:TFreeShip); virtual;
        destructor  Destroy; override;
        procedure   Clear;

        // Add calculated data to a stringlist to either show in a report or save to disc
        procedure   ShowData( Mode:TFreeHydrostaticsMode );
        procedure   AddData(Strings:TStringlist;Mode:TFreeHydrostaticsMode;Separator:char);
        procedure   AddHeader(Strings:TStringlist);
        Procedure   AddFooter(Strings:TStringlist;Mode:TFreeHydrostaticsMode );
//      function    Balance(Displacement:TFloatType;FreeToTrim:Boolean;var Output:TFreeCrosscurvesData):boolean;

        procedure   Calculate; // The actual calculation of the hydrostatics finds place in this procedure
        property    Calculated           : Boolean read FCalculated write FSetCalculated;
        property    Calculations         : TFreeHydrostaticsCalculate read FCalculations write FCalculations;
        property    Data                 : TFreeHydrostaticsData read FData;
        property    Draft                : TFloatType read FDraft write FSetDraft;
        property    Errors               : TFreeHydrostaticErrors read FErrors write FSetErrors;
//      property    ErrorString          : String read FGetErrorString;
        property    HeelingAngle         : TFloatType read FHeelingAngle write FSetHeelingAngle;
        property    HydrostaticType      : TFreeHydrostaticType read FHydrostaticType write FSetHydrostaticType; // Determines how calculations are performed: short, extensive etc.
        property    Owner                : TFreeShip read FOwner;
        property    Trim                 : TFloatType read FTrim write FSetTrim;
        property    TrimAngle            : TFloatType read FGetTrimAngle;
        property    WaterlinePlane       : T3DPLane read FGetWlPlane;
     end;
     {
         TFreeIntersection is a list of curves calculated from the intersection
         of a ship hull (represented by a subdivision surface) and a plane.
         This plane can be a orthogonal plane (eg. stations, waterlines,
         buttocks) or a freely oriented 3D plane (sent)
     }
     TFreeIntersection = class
     private
        FOwner           : TFreeShip;
        FItems           : TFasterList;
        FPlane           : T3DPlane;
        FBuilt,FShowCurvature:Boolean;
        function    FGetColor:TColor;
        function    FGetPlane:T3DPlane;
        function    FGetCount:integer;
        function    FGetDescription:string;
        function    FGetItem(Index:integer):TFreeSpline;
        procedure   FSetBuilt(Val:Boolean);
     public
        UseHydrostaticsSurfacesOnly: boolean; // used for lateral area, mainframe and waterplane properties
        IntersectionType: TFreeIntersectionType;
        procedure   Add(Item:TFreeSpline);
        procedure   CalculateArea(Plane:T3DPlane;var Area:TFloatType;var COG:T3DVector;var MomentOfInertia:T2DCoordinate);
        procedure   Clear;
        constructor Create(Owner:TFreeShip);
        procedure   CreateStarboardPart;       // Create the starboardhalf of the ship, for use in hydrostatic calculations
        procedure   Delete(Redraw:Boolean);
        procedure   DeleteItem(Item:TFreeSpline);
        destructor  Destroy;                                                       override;
        procedure   Draw(Viewport:TFreeViewport);
        procedure   DrawAll;
        procedure   Extents(Var Min,Max:T3DVector);
        procedure   LoadBinary(Source:TFreeFileBuffer);
        procedure   Rebuild;
        procedure   SaveToDXF(Strings:TStringList);
        procedure   SaveBinary(Destination:TFreeFileBuffer);
        property    Built                : Boolean read FBuilt write FSetBuilt;
        property    Color                : TColor read FGetColor;
        property    Count                : integer read FGetCount;
        property    Description          : string read FGetDescription;
        property    Items[index:integer] : TFreeSpline read FGetItem;
        property    Owner                : TFreeShip read FOwner;
        property    Plane                : T3DPlane read FGetPlane write FPlane;
        property    ShowCurvature        : Boolean read FShowCurvature write FShowCurvature;
//      property    UseHydrostaticsSurfacesOnly:boolean read FUseHydrostaticsSurfacesOnly write FUseHydrostaticsSurfacesOnly;
     end;
     {-------------}
     { TFreeMarker }
     {-------------}
     TFreeMarker = class(TFreeSpline)
     private
        FVisible    : Boolean;
        FOwner      : TFreeShip;
        function FGetSelected:Boolean;
        procedure FSetSelected(val:Boolean);
     public
        procedure Clear;                                                        override;
        function  DistanceToCursor(X,Y:Integer;Viewport:TFreeViewport):integer; override;
        procedure Delete;
        procedure Draw(Viewport:TFreeViewport);                                 override;
        procedure LoadBinary(Source:TFreeFileBuffer);                           override;
        procedure SaveBinary(Destination:TFreeFileBuffer);                      override;
        property Owner       : TFreeShip read FOwner;
        property Selected    : Boolean read FGetSelected write FSetSelected;
        property Visible     : Boolean read FVisible write FVisible;
      end;
     {--------------}
     { FreeFlowline }
     {--------------}
     TFreeFlowline = class
     private
        FProjectionPoint     : T2DCoordinate;
        FProjectionView      : TFreeViewType;
        FFlowLine            : TFreeSpline;
        FBuild               : Boolean;
        FOwner               : TFreeShip;
        FMethodNew:Boolean;
        function FGetColor:TColor;
        function FGetSelected:Boolean;
        function FGetVisible:Boolean;
        procedure FSetBuild(val:Boolean);
        procedure FSetSelected(val:Boolean);
     public
        procedure Clear;
        constructor Create(Owner:TFreeShip);
        procedure Delete;
        destructor Destroy;                                                       override;
        function  DistanceToCursor(X,Y:Integer;Viewport:TFreeViewport):integer;
        procedure Draw(Viewport:TFreeViewport);
        procedure LoadBinary(Source:TFreeFileBuffer);
        procedure Rebuild;
        procedure SaveBinary(Destination:TFreeFileBuffer);
        property Build       : Boolean read FBuild write FSetBuild;
        property Color       : TColor read FGetColor;
        property Owner       : TFreeShip read FOwner;
        property Selected    : Boolean read FGetSelected write FSetSelected;
        property Visible     : boolean read FGetvisible;
     end;
     {--------------------------------------------------------}
     { This object stores all visibility options for the hull }
     {--------------------------------------------------------}
     TFreeVisibility     = class(TPersistent)
     private
        FOwner                        : TFreeShip;
        FShowControlNet               : Boolean;
        FShowInteriorEdges            : Boolean;        // Show the surface edges
        FShowStations                 : Boolean;        // Show the calculated stations
        FShowButtocks                 : Boolean;        // Show the calculated Buttocks
        FShowWaterlines               : Boolean;        // Show the calculated Waterlines
        FShowDiagonals                : Boolean;        // Show the calculated Diagonals
        FModelView                    : TFreeModelView; // Show half or entire ship
        FShowNormals                  : Boolean;        // Show normals of selected surface patches
        FShowGrid                     : Boolean;        // Show the grid of intersections in the plan,profile and bodyplan view
        FShowMarkers                  : Boolean;
        FShowControlCurves            : boolean;
        FShowCurvature                : Boolean;
        FShowHydrostaticData          : boolean;
        FShowHydrostDisplacement      : boolean;
        FShowHydrostLateralArea       : boolean;
        FShowHydrostSectionalAreas    : boolean;
        FShowHydrostMetacentricHeight : boolean;
        FShowHydrostLCF               : boolean;
        FShowFlowlines                : Boolean;
        FCurvatureScale               : TFloatType;     // Scalefactor used to increase or decrease the size of the curvature plot
        FCursorIncrement              : TFloatType;     // Distance added when the active controlpoint is moved withe the arrow keys
        procedure FSetCursorIncrement(val:TFloatType);
        procedure FSetCurvatureScale(Val:TFloatType);
        procedure FSetShowButtocks(Val:Boolean);
        procedure FSetShowControlNet(Val:Boolean);
        procedure FSetShowCurvature(Val:Boolean);
        procedure FSetShowDiagonals(Val:Boolean);
        procedure FSetShowFlowlines(Val:Boolean);
        procedure FSetShowGrid(Val:Boolean);
        procedure FSetModelView(Val:TFreeModelView);
        procedure FSetShowInteriorEdges(Val:Boolean);
        procedure FSetShowMarkers(Val:Boolean);
        procedure FSetShowNormals(Val:Boolean);
        procedure FSetShowStations(Val:Boolean);
        procedure FSetShowWaterlines(Val:Boolean);
        procedure FSetShowControlCurves(Val:Boolean);
        procedure FSetShowHydrostaticData(Val:Boolean);
     public
        constructor Create(Owner:TFreeShip);
        procedure   Clear;
        procedure   DecreaseCurvatureScale;
        procedure   IncreaseCurvatureScale;
        procedure   LoadBinary(Source:TFreeFilebuffer);
        procedure   SaveBinary(Destination:TFreeFileBuffer);
        property    Owner                         : TFreeShip read FOwner write FOwner;
     published
        property    CursorIncrement               : TFloatType read FCursorIncrement write FSetCursorIncrement;
        property    CurvatureScale                : TFloatType read FCurvatureScale write FSetCurvatureScale;
        property    ModelView                     : TFreeModelView read FModelView write FSetModelView;
        property    ShowButtocks                  : boolean read FShowButtocks write FSetShowButtocks;
        property    ShowControlCurves             : boolean read FShowControlCurves write FSetShowControlCurves;
        property    ShowControlNet                : boolean read FShowControlNet write FSetShowControlNet;
        property    ShowCurvature                 : boolean read FShowCurvature write FSetShowCurvature;
        property    ShowDiagonals                 : boolean read FShowDiagonals write FSetShowDiagonals;
        property    ShowFlowlines                 : boolean read FShowFlowlines write FSetShowFlowlines;
        property    ShowGrid                      : boolean read FShowGrid write FSetShowGrid;
        property    ShowHydrostaticData           : boolean read FShowHydrostaticData write FSetShowHydrostaticData;
        property    ShowInteriorEdges             : boolean read FShowInteriorEdges write FSetShowInteriorEdges;
        property    ShowMarkers                   : boolean read FShowMarkers write FSetShowMarkers;
        property    ShowNormals                   : boolean read FShowNormals write FSetShowNormals;
        property    ShowStations                  : boolean read FShowStations write FSetShowStations;
        property    ShowWaterlines                : boolean read FShowWaterlines write FSetShowWaterlines;
     end;
     {---------------------------------------------------------}
     { Container class for all editing commandsns for the hull }
     {---------------------------------------------------------}
     TFreeEdit = class  { FreeShip: TFreeShip; -> Ship }
     private
        FRecentFiles: TStringList;
        function FGetRecentFile(Index:integer):string;
        function FGetRecentFileCount:integer;
     public
        Ship: TFreeShip;
        constructor Create( Owner:TFreeShip );
        destructor Destroy; override;
        procedure File_Export_Aurora_Experiments; // Теория корабля и штормовой вычислительный эксперимент
        procedure File_Load; overload; virtual; // Load a FREE!ship file by showing an opendialog
        procedure File_Load(filename:string); reintroduce; overload; // Loads the given filename quietly
        function File_Save: Boolean;   // save as FREE!ship file without prompting for a filename (must already been set)
        function File_SaveAs: Boolean; // Ask for filename and save as FREE!ship file
        function File_SaveCheck:word;  // с запроосом необходимости -> mrOk,mrNo,mrCancel
        procedure Flowline_Add(Source:T2DCoordinate;View:TFreeviewType);
        procedure Geometry_AddCylinder;
        procedure AddToRecentFiles(Filename:String);                            // Takes a filename and adds it to the list with recent files
        procedure BackgroundImage_Delete(Viewport:TFreeViewport);               // Delete the backgrundimage associated with this view
        procedure BackgroundImage_Open(Viewport:TFreeViewport);                 // browse for and open a backgroundimage
        function  CreateRedoObject:TFreeUndoObject;                             // Creates redo data before an undo is done
        function  CreateUndoObject(UndoText:String;Accept:Boolean):TFreeUndoObject;// Creates undodata just prior to modifications
        procedure Curve_Add;                                                    // Add a new controlcurve
        procedure Edge_Collapse;                                                // Remove an edge by replacing the two connected faces by one controlface
        procedure Edge_Connect;                                                 // Create a new edge by connection two controlpoints belonging to the same controlface
        procedure Edge_Crease;                                                  // Switch selected edges between normal or crease edges (knuckle lines)
        procedure Edge_Extrude;                                                 // Create new controlfaces by extruding selected boundary edges (eg edges with only 1 controlface connected to it)
        procedure Edge_Split;                                                   // Create new controlpoints by splitting an controledge into two.
        procedure Face_Assemble;
        procedure Face_DeleteNegative;                                          // Deletes all faces on the starboardside of the hull
        procedure Face_Flip;                                                    // Inverts the normal-direction of all selected controlfaces
        procedure Face_MirrorPlane;                                             // Mirrors all selected faces in a 3D plane
        procedure Face_New;                                                     // Creates a new controlface from the currently selected controlpoints
        procedure Face_Rotate;                                                  // Rotate selected faces around the X,Y and/or Z axis
        procedure Face_Scale;                                                   // Scale selected faces
        procedure Face_Move;                                                    // Move selected faces in X,Y and Z direction
        procedure File_ExportArchimedes;                                        // Exports stations to Archimedes or ArchimedesMB
        procedure File_ExportCoordinates;                                       // export the coordinates of all controlpoints to a textfile
        procedure File_ExportDXF_2DPolylines;                                   // Export all intersections to an individual DXF file as 2D polylines
        procedure File_ExportDXF_3DPolylines;                                   // Export all lines to a 3D DXF model as polylines
        procedure File_ExportDXF_Faces;                                         // Export all faces to a 3D DXF model
     //#procedure File_ExportFEF;                                               // Save to a Freeship Exchange Format (FEF) file
        procedure File_ExportGHS;                                               // Save ordinates to the GHS file format
        procedure File_ExportPart;                                              // Save part of the geometry to a file
        procedure File_ExportIGES;                                              // Save NURBS patches to an IGES file
     // procedure File_Export_Michlet;                                          // Creates a file to be read by the CFD program Michlet
     // procedure File_Import_MichletWaves;
        procedure File_ExportObj;                                               // Saves the model as a wavefront .Obj file
        procedure File_ExportOffsets;                                           // Exports all intersections to a textfile as 3D points
        procedure File_ExportSTL;                                               // Export the surface to a STL file
        procedure File_ImportCarene;                                            // imports a Carene XYZ file and creates a multichine boat with developable surfaces
        procedure File_ImportChines;                                            // Import chines from a textfile and fit a surface through them
     //#procedure File_ImportFEF;                                               // Import a Freeship Exchange Format (FEF) file
        procedure File_ImportHull;                   overload;virtual;          // Imports a file created with Carlssons's Hulls program
        procedure File_ImportHull(Filename:string;Quiet:Boolean);reintroduce;overload; // Imports a file created with Carlssons's Hulls program
        procedure File_ImportPart;                                              // Import a partfile and add it to the current geometry
        procedure File_ImportPolycad;                                           // Imports a PolyCad file
        procedure File_ImportSurface;                                           // Imports a number of curves and fits a surface
        Procedure File_ImportVRML;                                              // Import a VRML 1.0 file
        function  Hydrostatics_Calculate(Draft,AngleOfHeel,Trim:TFloatType):TFreeHydrostaticCalc;// Creates and calculates a hydrostatics calculation
        procedure Hydrostatics_Dialog;                                          // Opens the hydrostatics dialog and calculates hydrostatic data for a range of inputdata
     //#procedure Hydrostatics_Crosscurves;                                     // Opens the dialog to calculate crosscurves
        procedure ImportFrames;                                                 // Loads a bodyplane and tries to fit a surface to it
        function  Intersection_Add(IntType:TFreeIntersectionType;Distance:TFloatType):TFreeIntersection;// Add a new intersection at the specified location
        procedure Intersection_AddToList(Intersection:TFreeIntersection);       // Adds an intersection to the appropriate list
        procedure Intersection_Dialog;                                          // Pops up the dialog in whcih to add or delete stations, buttocks and waterlines
        procedure Layer_AutoGroup;                                              // All connected patches surrounded by crease edges are grouped together into a new layer
        procedure Layer_Develop;                                                // Developes all developable layers
        procedure Layer_Dialog;                                                 // Show layer dialog window
        procedure Layer_DeleteEmpty(Quiet:Boolean);                             // Delete all layers that are empty from the model
        function  Layer_New:TFreeSubdivisionLayer;                              // Add a new empty layer
        procedure Marker_Add(Marker:TFreeMarker);                               // Adds a marker to the list with markers
        procedure Marker_Delete;                                                // Delete all markers from the model
        procedure Marker_Import;                                                // Import markers from a textfile
        procedure Model_Check(ShowResult:Boolean);                              // Checks the surface for inconsistent normal directions and leaks
        function  Model_New:Boolean;                                            // Start a new model (with a predefined surface)
        procedure Model_LackenbyTransformation;                                 // Affine hullform transformation according to Lackenby
        procedure Model_Scale(ScaleVector:T3DVector;OverrideLock,AdjustMarkers:Boolean); // Scale the entire model and all equivalent data such as stations etc.
        procedure Point_Collapse;                                               // Merge two selected edges by removing their common controlpoint.
        procedure Point_RemoveUnused;                                           // removes any unused points from the model
        procedure Point_InsertPlane;                                            // Finds all intersection of VISIBLE edges and a 3D plane, and inserts a point on each of these edges
        procedure Point_IntersectLayer;                                         // Calculates the intersection points of two layers
        procedure Point_Lock;                                                   // Locks all selected points
        function  Point_New:TFreeSubdivisionControlPoint;                       // Add a new point to the model with no edges/faces attached
        procedure Point_ProjectStraightLine;                                    // Project all selected points onto a straight line through the first and last selected points
        procedure Point_Unlock;                                                 // Unlocks all selected locked points
        procedure Point_UnlockAll;                                              // Unlocks all points
        function  ProceedWhenLockedPoints:Boolean;                              // Function that shows a warning when certain edit commands are invoked and the model contains locked points
        procedure Redo;                                                         // Restores the state of the model as it was after the previous undone
     // procedure Resistance_Delft;                                             // Calculate resistance of yachts according to Delft systematic yacht series
     // procedure Resistance_Kaper;                                             // Calculate resistance of slender hulls (canoes) according to John Winters
        procedure Selection_Clear;                                              // Deselect all selected items at once
        procedure Selection_Delete;                                             // Delete all selected items
        procedure Selection_SelectAll;                                          // Select all visible items
        procedure Undo;                                                         // Restores the state of the model as it was before the last modification
        procedure Undo_Clear;                                                   // Clear the undo history
        procedure Undo_ShowHistory;                                             // Show the undo history
        property  RecentFiles               : TStringList read FRecentFiles;
        property  RecentFile[index:integer] : string read FGetRecentFile;       // retrieve a filename from the recently used file list
        property  RecentFileCount           : integer read FGetRecentFileCount; // The number of files in the recently used file list
     end;
{
   Container class for all program settings
}
TApplicationScope=(asMachine,asUser);
TFreePreferences=class(TPersistent)
private
  FOwner: TFreeShip;
  FMainForm: TForm;
  FViewportColor: TColor;
  // Half width of controlpoints in pixels when drawn on screen
  // Colors
  FIntersectionLineWidth,
  FControlEdgeLineWidth,
  FInteriorEdgeLineWidth,
  FAuxEdgeLineWidth,
  FHydrostaticLineWidth: integer;
  procedure FSetViewportColor( Val: TColor );
public
  EdgeColor,       // Color of normal edges
  CreaseColor,     // color of crease edges
  CreaseEdgeColor, // color of crease control-edges
  GridColor,       // Color of gridlines
  GridFontColor,   // Color of font with gridlines
  CreasePointColor,// Color of crease vertices
  RegularPointColor,
  CornerPointColor,// Color of cornerpoints and points with at least 3 crease edges
  DartPointColor,
  SelectColor,     // Color of selected items
  LayerColor,      // Default color for new layers
  NormalColor,     // color of surface normals
  LeakPointColor,
  MarkerColor,
  CurvaturePlotColor,
  ControlCurveColor,
  HydrostaticsFontColor,
  ZebraStripeColor,
  StationColor,
  ButtockColor,
  WaterlineColor,
  DiagonalColor,
  UnderWaterColor:TColor; // Default color used for shading underwaterpart of vessel
  UnderWaterColorAlpha: byte;
  FbmEncoding,//encoding that is used to convert national strings from/to FBM files
  Language:           AnsiString;
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
//  FInitDirectory,   // Default directory where freeship.exe started
//  FUserDataDirectory,// Default directory where users FreeShip r/w data (projects etc) stored
//  FUserAppDataDirectory,// Default directory where users FreeShip programs and r/o resource files stored
//  function FullName( const N: AnsiString ): AnsiString; // --
  function OnlyName( const S: AnsiString; DS:boolean=true ): AnsiString; // имя внутри/вне директории
  procedure Clear;
  constructor Create(Owner: TFreeShip);
  procedure Edit;
  procedure Load;
  procedure LoadFromIni;
  procedure ResetColors;
  procedure ResetDirectories;
  procedure SetDefaults;
  procedure Save;
  property  Owner: TFreeShip read FOwner write FOwner;
  property  MainForm: TForm read FMainForm write FMainForm;
published                                                  // General options
  property ViewportColor: TColor read FViewportColor write FSetViewportColor;
end;
{------------------------------------------------------------}
{   Container class for project settings for each projecttl  }
{------------------------------------------------------------}
TFreeProjectSettings=class
private
// FMainparticularsHasBeenset: boolean; // Flag to check if the main particulars have been set before hydrostatic calculationss are being performed
  FDisableModelCheck: boolean;         // Disable the automatic checking of the surface
  FEnableModelAutoMove: boolean;       // Unable the automatic moving model along Z
  FProjectAppendageCoefficient: TFloatType;
  FProjectBeam,FProjectDraft,FProjectLength: TFloatType;
  FProjectWaterDensity,FProjectWaterTemper: TFloatType;
  FProjectName,FProjectDesigner,FProjectComment,FProjectFileCreatedBy: AnsiString;
  FProjectSimplifyIntersections,
  FProjectShadeUnderwaterShip,FSavePreview: boolean;
  FProjectUnits: TFreeUnitType;
//  FProjectPrecision: TFreePrecisionType;
  FFreeHydrostaticCoefficients: TFreeHydrostaticCoeff; // General hydrostatics calculation settings
  FStartDraft,FEndDraft,FDraftStep: TFloatType;
  FTrim: TFloatType;  // crosscurves settings
  FDisplacements: TFloatArray;
  FNoDisplacements: integer;
  FMinimumDisplacement,FMaximumDisplacement,FDisplIncrement: TFloatType;
  FUseDisplIncrements: boolean;
  FNoAngles: integer;
  FAngles: TFloatArray;
  FNoStabTrims: integer;
  FStabTrims: TFloatArray;
  FFreeTrim: boolean;
  FVCG: TFloatType;

  FUseMidleFrame: Boolean;
  FMidleFrame: TFloatType;                   // заданная или полубсцисса миделя
  procedure FSetMidleFrame(Mid:TFloatType); Function FGetMidleFrame:TFloatType;
  procedure FSetUseMidleFrame(Mid:Boolean);


  procedure FSetDisableModelCheck(Val: boolean);
  procedure FSetFreeHydrostaticCoefficients(val: TFreeHydrostaticCoeff);
  procedure FSetEnableModelAutoMove(Val: boolean);
  procedure FSetProjectAppendageCoefficient(Val: TFloatType);
  procedure FSetProjectBeam(Val: TFloatType);
  procedure FSetProjectDraft(Val: TFloatType);
  procedure FSetProjectLength(Val: TFloatType);
  procedure FSetProjectShadeUnderwaterShip(Val: boolean);
  procedure FSetProjectSimplifyIntersections(val: boolean);
  procedure FSetProjectUnits(Val: TFreeUnitType);
  procedure FSetProjectWaterDensity(Val: TFloatType);
  procedure FSetProjectWaterTemper(Val: TFloatType);
  procedure FSetSavePreview(val: boolean);
  procedure FSetStartDraft(Val: TFloatType);
  procedure FSetEndDraft(Val: TFloatType);
  procedure FSetDraftStep(Val: TFloatType);
  procedure FSetTrim(Val: TFloatType);

public
  FreeShip: TFreeShip;
  ProjectUnderWaterColor: TColor;
  ProjectUnderWaterColorAlpha: byte;
  ProjectPrecision: TFreePrecisionType;
  constructor Create( Owner: TFreeShip );
  procedure Clear;
  procedure Edit;        // User input of mainparticulars and project setting
  procedure LoadBinary(Source: TFreeFilebuffer; Image: TJPegImage); overload; virtual;
  procedure SaveBinary(Destination: TFreeFileBuffer);
  property MidleFrame: TFloatType read FGetMidleFrame write FSetMidleFrame;
  property UseMidleFrame: Boolean read FUseMidleFrame write FSetUseMidleFrame;
  property EnableModelAutoMove: boolean read FEnableModelAutoMove write FSetEnableModelAutoMove;
  property Hydrostatics_Startdraft: TFloatType read FStartDraft write FSetStartDraft;
  property Hydrostatics_EndDraft: TFloatType   read FEndDraft write FSetEndDraft;
  property Hydrostatics_DraftStep:TFloatType   read FDraftStep write FSetDraftStep;
  property Hydrostatics_Trim: TFloatType       read FTrim write FSetTrim;
  property DisableModelCheck: boolean read FDisableModelCheck write FSetDisableModelCheck;
// property MainparticularsHasBeenset: boolean read FMainparticularsHasBeenset;
  property ProjectAppendageCoefficient: TFloatType read FProjectAppendageCoefficient write FSetProjectAppendageCoefficient;
  property ProjectBeam: TFloatType read FProjectBeam write FSetProjectBeam;
  property ProjectCoefficients: TFreeHydrostaticCoeff read FFreeHydrostaticCoefficients write FSetFreeHydrostaticCoefficients;
  property ProjectDraft: TFloatType read FProjectDraft write FSetProjectDraft;
  property ProjectLength: TFloatType read FProjectLength write FSetProjectLength;
  property ProjectName: AnsiString read FProjectName;         // write FSetProjectName;
  property ProjectDesigner: AnsiString read FProjectDesigner; // write FSetProjectDesigner;
  property ProjectComment: AnsiString read FProjectComment;   // write FSetProjectComment;
  property ProjectFileCreatedBy: AnsiString read FProjectFileCreatedBy; // write FSetProjectFileCreatedBy;
  property ProjectShadeUnderwaterShip: boolean read FProjectShadeUnderwaterShip write FSetProjectShadeUnderwaterShip;
  property ProjectSimplifyIntersections: boolean read FProjectSimplifyIntersections write FSetProjectSimplifyIntersections;
  property ProjectUnits: TFreeUnitType read FProjectUnits write FSetProjectUnits;
  property ProjectWaterDensity: TFloatType read FProjectWaterDensity write FSetProjectWaterDensity;
  property ProjectWaterTemper: TFloatType read FProjectWaterTemper write FSetProjectWaterTemper;
  property SavePreview: boolean read FSavePreview write FSetSavePreview;
end;

(* MidleFrame


FProjectSplitSectionLocation: TFloatType;
FUseDefaultSplitSectionLocation,// If set to true,the midship/mainframe location is set to 0.5*project length,if false then value in FProjectMainframeLocation is used
FProjectMainframeLocation: TFloatType;
FUseDefaultMainframeLocation: Boolean;     // If set to true, the mainframe location is set to 0.5*project length, if false then value in FProjectMainframeLocation is used
property ProjectSplitSectionLocation: TFloatType read FGetProjectSplitSectionLocation write FSetProjectSplitSectionLocation;
property UseDefaultSplitSectionLocation: boolean read FUseDefaultSplitSectionLocation write FSetUseDefaultSplitSectionLocation;
procedure FSetProjectSplitSectionLocation(val: TFloatType);
function FGetProjectSplitSectionLocation: TFloatType;
procedure FSetUseDefaultSplitSectionLocation(Val: boolean);
procedure FSetUseDefaultMainframeLocation(Val:Boolean);
function  FGetProjectMainframeLocation:TFloatType;
procedure FSetProjectMainframeLocation(val:TFloatType);
property UseDefaultMainframeLocation  : boolean read FUseDefaultMainframeLocation write FSetUseDefaultMainframeLocation;
property ProjectMainframeLocation: TFloatType read FGetProjectMainframeLocation write FSetProjectMainframeLocation;
*)


     {----------------------------------------------------------------------------------}
     {   TFreeShip is the actual component used for modelling and representing the ship }
     {----------------------------------------------------------------------------------}
     TFreeShip = class(TComponent)
     private
        FViewports                 : TFasterList;                  // List containing all viewports associated with the hullform
        FPrecision                 : TFreePrecisionType;
        FFileVersion               : TFreeFileVersion;
        FEditMode                  : TFreeEditMode;                // The component has different edit-modes which determine how the program responds to mouse-events
        FPreferences               : TFreePreferences;
        FActiveControlPoint        : TFreeSubdivisionControlPoint; // The last selected controlpoint (still selected)
        FFileChanged               : boolean;                      // Flag to keep track of modifications to the file
        FSurface                   : TFreeSubdivisionSurface;
        FFilename                  : string;                       // Filename of the current project;
        FEdit                      : TFreeEdit;                    // Containerclass for all editing commands
        FStations                  : TFasterList;
        FButtocks                  : TFasterList;
        FWaterlines                : TFasterList;
        FDiagonals                 : TFasterList;
        FMarkers                   : TFasterList;
        FBackgroundImages          : TFasterList;
        FFlowLines                 : TFasterList;
        FSelectedFlowlines         : TFasterList;
        FSelectedMarkers           : TFasterList;
        FVisibility                : TFreeVisibility;
        FOnFileChanged             : TNotifyEvent;
        FOnUpdateUndoData          : TNotifyEvent;
        FOnUpdateRecentFileList    : TNotifyEvent;
        FOnChangeCursorIncrement   : TNotifyEvent;
        FOnUpdateGeometryInfo      : TNotifyEvent; // This event is raised whenever items are added or deleted from the surface
        FFreeLinesplanFrme         : TFrame;
        FFilenameSet               : Boolean; // Flag to determine if the filename already has been set
        // The folowing private variables are for moving controlpoints with the mouse
        FCurrentlyMoving           : boolean;
        FPointHasBeenMoved         : boolean;
//##    FStopAskingForFileVersion  : Boolean;
        FPrevCursorPosition        : TPoint;
        FControlpointForm          : TFreeControlPointForm; // form for manual adjustment of controlpoints
        FIntersectionDialog        : TForm;                 // Dialog containing intersectionlines
        FProjectSettings           : TFreeProjectSettings;
        FHydrostaticCalculations   : TFasterList;          // List containing all hydrostatic calculations
        FUndoObjects               : TFasterList;
        FUndoPosition              : Integer;              // Index of the current undo object
        FPreviousUndoPosition      : Integer;
(*##*)  FResistanceDelftData       : TFreeDelftSeriesResistanceData;
(*##*)  FResistanceKaperData       : TFreeKAPERResistanceData;
        FDesignHydrostatics        : TFreeHydrostaticCalc; // This object calculates hydrostatic data to draw in the viewports
        procedure FBuildValidFrameTable(Destination:TFasterList;CloseAtDeck:Boolean); // Assembles all stations and builds a 2D bodyplan for export to other calculating programs
        function  FGetActiveLayer:TFreeSubdivisionlayer;
        function  FGetBackgroundImage(Index:Integer):TFreeBackgroundImageData;
        function  FGetBuild:Boolean;
        function  FGetButtock(Index:integer):TFreeIntersection;
        function  FGetControlCurve(Index:integer):TFreeSubdivisionControlCurve;
        function  FGetDiagonal(Index:integer):TFreeIntersection;
        function  FGetFlowline(Index:integer):TFreeFlowline;
        function  FGetFilename:string;
        function  FGetHydrostaticCalculation(Index:integer):TFreeHydrostaticCalc;
        function  FGetNumberOfLayers:integer;
        function  FGetLayer(Index:integer):TFreeSubdivisionLayer;
        function  FGetMarker(Index:integer):TFreeMarker;
        function  FGetNumberofBackgroundImages:Integer;
        function  FGetNumberOfButtocks:integer;
        function  FGetNumberOfControlCurves:integer;
        function  FGetNumberOfDiagonals:integer;
        function  FGetNumberOfFlowLines:Integer;
        function  FGetNumberOfHydrostaticCalculations:integer;
        function  FGetNumberOfLockedPoints:Integer;
        function  FGetNumberOfMarkers:integer;
        function  FGetNumberOfStations:integer;
        function  FGetNumberOfViewports:integer;
        function  FGetNumberOfWaterlines:integer;
        function  FGetOnChangeActiveLayer:TChangeActiveLayerEvent;
        function  FGetOnChangeLayerData:TNotifyEvent;
        function  FGetOnSelectItem:TNotifyEvent;
        function  FGetSelectedControlPoint(Index:integer):TFreeSubdivisionControlPoint;
        function  FGetSelectedControlEdge(Index:integer):TFreeSubdivisionControlEdge;
        function  FGetSelectedControlCurve(Index:integer):TFreeSubdivisionControlCurve;
        function  FGetSelectedControlFace(Index:integer):TFreeSubdivisionControlFace;
        function  FGetSelectedFlowline(index:Integer):TFreeFlowline;
        function  FGetSelectedMarker(index:Integer):TFreeMarker;
        function  FGetStation(Index:integer):TFreeIntersection;
        function  FGetUndoCount:integer;
        function  FGetUndoMemory:integer;
        function  FGetUndoObject(Index:integer):TFreeUndoObject;
        function  FGetViewport(Index:integer):TFreeViewport;
        function  FGetWaterline(Index:integer):TFreeIntersection;
        procedure FSetActiveControlPoint(Val:TFreeSubdivisionControlPoint);
        procedure FSetActiveLayer(Val:TFreeSubdivisionLayer);
        procedure FSetBuild(Val:Boolean);
        procedure FSetEditMode(Val:TFreeEditMode);
        procedure FSetFileChanged(Val:Boolean);
        procedure FSetFileName(Val:string);
        procedure FSetFileVersion(Val:TFreeFileVersion);
        function  FGetNumberOfSelectedControlCurves:integer;
        function  FGetNumberOfSelectedControlEdges:integer;
        function  FGetNumberOfSelectedControlFaces:integer;
        function  FGetNumberOfSelectedControlPoints:integer;
        function  FGetNumberOfselectedFlowlines:Integer;
        function  FGetNumberOfSelectedLockedPoints:integer;
        function  FGetNumberOfselectedMarkers:Integer;
        procedure FSetOnChangeActiveLayer(val:TChangeActiveLayerEvent);
        procedure FSetOnChangeLayerData(Val:TNotifyEvent);
        procedure FSetOnSelectItem(Val:TNotifyEvent);
        procedure FSetPrecision(Val:TFreePrecisionType);
        function  FGetPreview:TJPEGImage;
     public
        constructor Create( AOwner: TComponent ); override;
        destructor  Destroy; override;
        procedure   Clear;
        procedure   Draw;
        procedure   Redraw; // Redraws the model on all viewports
        function    DetectMinFileVersion( isText: boolean ): TFreeFileVersion;
        procedure   AddViewport(Viewport:TFreeViewport); // Add a viewport to the list of viewports connected to the model
        function    AdjustMarkers:Boolean;
        procedure   ClearUndo;
//      procedure   CreateOutputHeader(CalcHeader:string;Strings:TStrings);                                      // Creates a header with all relevant project data
        procedure   DeleteViewport(Viewport:TFreeViewport); // Delete a viewport from the list of viewports connected to the model
        procedure   DrawToViewport(Viewport:TFreeViewport);
        procedure   Extents(Var Min,Max:T3DVector); // calculate the bounding box coordinates of the model
(*##*)  procedure   ZoomFitAllViewports;            // <=> FreeHullformWindow
        function    FindLowestHydrostaticsPoint:TFloatType;
        procedure   ImportChines(Np:Integer;Chines:TFasterList); // imports a number of longitudinally lines and creates developable surfaces between each two subsequent chines
        Procedure   LoadProject(Source:TFreeFileBuffer);
//      Procedure   LoadBinary(Source:TFreeFileBuffer);
        procedure   LoadPreview(Filename:string;Image:TJPegImage); // loads the preview image from a file
        procedure   RebuildModel;                                  // Force to rebuild the entire ship and recalculate all data
        Procedure   SaveProject( Destination:TFreeFileBuffer );
//##    Procedure   SaveBinary(Destination:TFreeFileBuffer);
        procedure   SavePart(Faces:TFasterList);
        procedure   SubmergedHullExtents(Wlplane:T3DPlane;var Min,Max:T3DVector);
        procedure   KeyUp(Viewport:TfreeViewport;var Key: Word;Shift: TShiftState);
        procedure   MouseDown(Viewport:TFreeViewport;Button:TMouseButton;Shift:TShiftState;X,Y:integer;var ItemSelected:Boolean);
        procedure   MouseMove(Viewport:TFreeViewport;Shift:TShiftState;X,Y:integer);
        procedure   MouseUp(Viewport:TFreeViewport;Shift:TShiftState;X,Y:integer);
        property    ActiveControlPoint                     : TFreeSubdivisionControlPoint read FActiveControlPoint write FSetActiveControlPoint;
        property    ActiveLayer                            : TFreeSubdivisionLayer read FGetActiveLayer write FSetActiveLayer;
        property    BackgroundImage[index:Integer]         : TFreeBackgroundImageData read FGetBackgroundImage;
        property    Build                                  : Boolean read FGetBuild write FSetBuild;
        property    Buttock[index:integer]                 : TFreeIntersection read FGetButtock;
        property    ControlCurve[index:integer]            : TFreeSubdivisionControlCurve read FGetControlCurve;
        property    ControlpointForm                       : TFreeControlPointForm read FControlpointForm; // Pointer to form for manual adjustment of controlpoints
        property    Diagonal[index:integer]                : TFreeIntersection read FGetDiagonal;
        property    Edit                                   : TFreeEdit read FEdit; // Containerclass for all editing commands
        property    EditMode                               : TFreeEditMode read FEditMode write FSetEditMode;
        property    FilenameSet                            : boolean read FFilenameSet write FFilenameSet;
        property    Flowline[index:integer]                : TFreeFlowline read FGetFlowline;
        property    HydrostaticCalculation[index:integer]  : TFreeHydrostaticCalc read FGetHydrostaticCalculation;
        property    Layer[index:integer]                   : TFreeSubdivisionLayer read FGetLayer;
        property    Marker[index:integer]                  : TFreeMarker read FGetMarker;
        property    NumberofBackgroundImages               : integer read FGetNumberofBackgroundImages;
        property    NumberofButtocks                       : integer read FGetNumberOfButtocks;
        property    NumberOfControlCurves                  : integer read FGetNumberOfControlCurves;
        property    NumberofDiagonals                      : integer read FGetNumberOfDiagonals;
        property    NumberOfHydrostaticCalculations        : integer read FGetNumberOfHydrostaticCalculations;
        property    NumberOfLayers                         : integer read FGetNumberOfLayers;
        property    NumberOfLockedPoints                   : integer read FGetNumberOfLockedPoints;
        property    NumberofMarkers                        : integer read FGetNumberOfMarkers;
        property    NumberOfFlowLines                      : integer read FGetNumberOfFlowLines;
        property    NumberOfSelectedControlCurves          : integer read FGetNumberOfSelectedControlCurves;
        property    NumberOfSelectedControlEdges           : integer read FGetNumberOfSelectedControlEdges;
        property    NumberOfSelectedControlFaces           : integer read FGetNumberOfSelectedControlFaces;
        property    NumberOfSelectedControlPoints          : integer read FGetNumberOfSelectedControlPoints;
        property    NumberOfselectedFlowlines              : integer read FGetNumberOfselectedFlowlines;
        property    NumberOfSelectedLockedPoints           : integer read FGetNumberOfSelectedLockedPoints;
        property    NumberOfselectedMarkers                : integer read FGetNumberOfselectedMarkers;
        property    NumberofStations                       : integer read FGetNumberOfStations;
        property    NumberOfViewports                      : integer read FGetNumberOfViewports;
        property    NumberofWaterlines                     : integer read FGetNumberOfWaterlines;
        property    OnChangeActiveLayer                    : TChangeActiveLayerEvent read FGetOnChangeActiveLayer write FSetOnChangeActiveLayer;
        property    OnChangeLayerData                      : TNotifyEvent read FGetOnChangeLayerData write FSetOnChangeLayerData;
        property    OnSelectItem                           : TNotifyEvent read FGetOnSelectItem write FSetOnSelectItem;
        property    SelectedControlCurve[index:integer]    : TFreeSubdivisionControlCurve read FGetSelectedControlCurve;
        property    SelectedControlPoint[index:integer]    : TFreeSubdivisionControlPoint read FGetSelectedControlPoint;
        property    SelectedControlEdge[index:integer]     : TFreeSubdivisionControlEdge read FGetSelectedControlEdge;
        property    SelectedControlFace[index:integer]     : TFreeSubdivisionControlFace read FGetSelectedControlFace;
        property    SelectedFlowline[index:integer]        : TFreeFlowline read FGetSelectedFlowline;
        property    SelectedMarker[index:integer]          : TFreeMarker read FGetSelectedMarker;
        property    Station[index:integer]                 : TFreeIntersection read FGetStation;
//##    property    StopAskingForFileVersion               : boolean read FStopAskingForFileVersion write FStopAskingForFileVersion;
        property    UndoCount                              : integer read FGetUndoCount;
        property    UndoMemory                             : integer read FGetUndoMemory; // amount of memory used by all undoobjects
        property    UndoObject[index:integer]              : TFreeUndoObject read FGetUndoObject;
        property    UndoPosition                           : integer read FUndoPosition;
        property    Viewport[index:integer]                : TFreeViewport read FGetViewport;
        property    Waterline[index:integer]               : TFreeIntersection read FGetWaterline;
        property    Surface                                : TFreeSubdivisionSurface read FSurface;
     published
        property    FileChanged                            : boolean read FFileChanged write FSetFileChanged;
        property    Filename                               : string read FGetFilename write FSetFileName;
        property    FileVersion                            : TFreeFileVersion read FFileVersion write FSetFileVersion;
        property    LinesplanFrame                         : TFrame read FFreeLinesplanFrme write FFreeLinesplanFrme;
        property    OnChangeCursorIncrement                : TNotifyEvent read FOnChangeCursorIncrement write FOnChangeCursorIncrement;
        property    OnFileChanged                          : TNotifyEvent read FOnFileChanged write FOnFileChanged;
        property    OnUpdateGeometryInfo                   : TNotifyEvent read FOnUpdateGeometryInfo write FOnUpdateGeometryInfo;
        property    OnUpdateRecentFileList                 : TNotifyEvent read FOnUpdateRecentFileList write FOnUpdateRecentFileList;
        property    OnUpdateUndoData                       : TNotifyEvent read FOnUpdateUndoData write FOnUpdateUndoData;
        property    Precision                              : TFreePrecisionType read FPrecision write FSetPrecision;
        property    Preferences                            : TFreePreferences read FPreferences;
        property    ProjectSettings                        : TFreeProjectSettings read FProjectSettings;
        property    Visibility                             : TFreeVisibility read FVisibility;
     end;

     TColorIniFile=class( TIniFile )
     public
       function ReadColor(const Section,Ident: AnsiString; Default: TColor): TColor; virtual;
       procedure WriteColor(const Section,Ident: AnsiString; Value: TColor); virtual;
     end;

// function to find the corresponding water viscosity based on the density
function FindWaterViscosity(Density:TFloatType;Units:TFreeUnitType):TFloatType;

procedure Register;
Var Ship: TfreeShip;

implementation
uses Math,Main,
     FreeIGESUnit,
     FreeIntersectionDlg,
     FreeNewModelDlg,
     FreeExtrudeDlg,
     FreeProjectSettingsDlg,
     FreeRotateDlg,
     FreePreferencesDlg,
     FreeExpanedPlatesDlg,
     FreeLinesplanFrm,
     FreeLinesplanFrme,
     FreeInsertPlaneDlg,
     FreeSelectLayersDlg,
     FreeMirrorPlaneDlg,
     Free2DDXFExportDlg,
     FreeLackenbyDlg,
     FreeIntersectLayerDlg,
     FreeUndoHistoryDlg,
     FreeCylinderDlg,
     FreeLayerDlg,
     FreeHullformWindow,
     FreeHydrostaticsDlg;
//     FreeHydrostaticsFrm,
//     FreeMichletOutputDlg,
//     FreeResistance_KaperDlg,
//     FreeResistance_DelftDlg,
//     FreeCrosscurvesDlg,

// function to find the corresponding water viscosity based on the density
function FindWaterViscosity(Density:TFloatType;Units:TFreeUnitType):TFloatType;
var TmpDensity:double;
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
   TFreeUndoObject is an object class for undoing actions.
   It's function is very basic, just before each modification the file is saved to a the
   undo object rather then to a file. When the undo is called, the previous state will be
   read from the undo object and restored
}
// calculates the amount of bytes used for each undo object
function TFreeUndoObject.FGetMemory:integer;
begin
   Result:=sizeof( pointer ) +      // pointer to self  =4
           sizeof( pointer ) +      // pointer to owner =4
           length(Undotext ) +      // length of string
           length(FFilename) +      // length of filename string
           FUndoData.Count;         // Actual saved data
end;

function TFreeUndoObject.FGetTime:string;
   begin Result:=TimeToStr(FTime); end;
function TFreeUndoObject.FGetUndoText:string;
   begin Result:=FUndoText; end;

procedure TFreeUndoObject.Accept;
var I  :Integer;
    Obj:TFreeUndoObject;
begin
// try
   // Add the undo data to the undolist
   if Owner.UndoCount>0 then begin
      if Owner.UndoObject[Owner.UndoCount-1].FIsTempRedoObject then begin
         Owner.UndoObject[Owner.UndoCount-1].Delete;
      end;
   end;                        // delete all undo objects after the current one
   for I:=FOwner.FUndoObjects.Count downto Owner.FUndoPosition+1 do begin
      Owner.UndoObject[I-1].Delete;
   end;
   Owner.FUndoObjects.Add(self);
   Owner.FUndoPosition:=Owner.FUndoObjects.Count;
   while (FOwner.UndoMemory/(1024*1024)>Owner.Preferences.MaxUndoMemory)
     and (Owner.FUndoObjects.Count>2) do begin
      Obj:=FOwner.FUndoObjects[0];
      Obj.Destroy;
      FOwner.FUndoObjects.Delete(0);
      Dec(Owner.FUndoPosition);
      Dec(Owner.FPreviousUndoPosition);
   end;
// finally
   if Assigned(Owner.FOnUpdateUndoData) then Owner.FOnUpdateUndoData(Owner);
// end;
end;

constructor TFreeUndoObject.Create(Owner:TFreeShip);
begin
   inherited Create;
   FTime:=Now;
   FOwner:=Owner;
   FUndoText:='';
   FFilename:='';
   FUndoData:=TFreeFileBuffer.Create;
   FIsTempRedoObject:=False;
end;

// deletes an undo object from the list
procedure TFreeUndoObject.Delete;
var Index:integer;
begin
   Index:=FOwner.FUndoObjects.IndexOf(self);
   if Index<>-1 then Owner.FUndoObjects.Delete(Index);
   if Assigned(Owner.FOnUpdateUndoData) then Owner.FOnUpdateUndoData(Owner);
   Destroy;
end;

destructor TFreeUndoObject.Destroy;
     begin FUndoData.Destroy; Inherited Destroy; end;

procedure TFreeUndoObject.Restore;
begin With Owner do begin
   LoadProject(FUndoData);
   FFileChanged:=FFileChanged;
   FFilename:=FFilename;
   FEditMode:=FEditMode;
   FFilenameSet:=FFilenameSet;
   Redraw;
end end;

{
  Freeship can import a max. of three different background images that may be
  coupled either to the bodyplan, profile or planview. These images can be used
  to trace the lines of an hullform and are stored within the FREE!ship file.
}
procedure TFreeBackgroundImageData.Clear;
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

constructor TFreeBackgroundImageData.Create(Owner:TFreeship);
begin
   Inherited Create;
   FOwner:=Owner;
   FImageData:=TJPEGImage.Create;
end;

destructor TFreeBackgroundImageData.Destroy;
begin
   Clear;
   FImageData.Destroy;
   Inherited Destroy;
end;

procedure TFreeBackgroundImageData.LoadBinary(Source:TFreeFileBuffer);
var I:Integer;
begin
   Source.LoadInteger(I);
   FAssignedView:=TFreeViewType(I);
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

procedure TFreeBackgroundImageData.SaveBinary(Destination:TFreeFileBuffer);
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

procedure TFreeBackgroundImageData.UpdateData(Viewport:TFreeViewport);
var I:Integer;
begin
   FOrigin:=Viewport.BackgroundImage.Origin;
   FScale:=Viewport.BackgroundImage.Scale;
   FTransparent:=Viewport.BackgroundImage.Transparent;
   FBlendingValue:=Viewport.BackgroundImage.Alpha;
   FTransparentColor:=Viewport.BackgroundImage.TransparentColor;
   FTolerance:=Viewport.BackgroundImage.Tolerance;
   for I:=1 to FOwner.NumberOfViewports do if (FOwner.Viewport[I-1]<>Viewport) and (FOwner.Viewport[I-1].ViewType=AssignedView) then
   begin
      FOwner.Viewport[I-1].BackgroundImage.AssignData(FImageData,AssignedView,FOrigin,FScale,FTransparent,FTransparentColor,FBlendingValue,FQuality,Ftolerance,False);
   end;
   FOwner.FileChanged:=True;
end;

procedure TFreeBackgroundImageData.UpdateViews;
var I:Integer;
begin
   for I:=1 to FOwner.NumberOfViewports do
   if FOwner.Viewport[I-1].Viewtype=AssignedView then begin
      FOwner.Viewport[I-1].BackgroundImage.AssignData(FImageData,AssignedView,FOrigin,FScale,FTransparent,FTransparentColor,FBlendingValue,FQuality,FTolerance,False);
   end;
end;

{  TFreeIntersection is a list of curves calculated from the intersection
   of a ship hull (represented by a subdivision surface) and a plane.
   This plane can be a orthogonal plane (eg. stations, waterlines, buttocks)
   or a freely oriented 3D plane (sent)
}
procedure TFreeIntersection.DeleteItem(Item:TFreeSpline);
var Index:integer;
begin
   Index:=FItems.IndexOf(Item);
   if Index<>-1 then FItems.Delete(index);
   Item.Destroy;
end;

function TFreeIntersection.FGetColor:TColor;
begin
   Case IntersectionType of
      fiStation   : Result:=Owner.Preferences.StationColor;
      fiButtock   : Result:=Owner.Preferences.ButtockColor;
      fiWaterline : Result:=Owner.Preferences.WaterlineColor;
      fiDiagonal  : Result:=Owner.Preferences.DiagonalColor;
      else Result:=clWhite;
   end;
end;

function TFreeIntersection.FGetPlane:T3DPlane;
   begin Result:=FPlane; end;
function TFreeIntersection.FGetCount:integer;
begin
   if self=nil then result:=0
               else Result:=FItems.Count;
end;

function TFreeIntersection.FGetDescription:string;
begin
   Case IntersectionType of
      fiStation : Result:=Userstring(58);
      fiButtock : Result:=Userstring(59);
      fiWaterline : Result:=Userstring(60);
      fiDiagonal : Result:=Userstring(61);
      else Result:='Free';
   end;
   if IntersectionType=fiDiagonal then Result:=Result+#32+FloatToStrF(-FPLane.d/FPlane.c,ffFixed,7,3)
                                  else Result:=Result+#32+FloatToStrF(-FPLane.d,ffFixed,7,3);
end;

function TFreeIntersection.FGetItem(Index:integer):TFreeSpline;
   begin Result:=FItems.Items[Index]; end;

procedure TFreeIntersection.FSetBuilt(Val:Boolean);
var I : integer;
begin
   if not Val then begin
      for I:=1 to Count do Items[I-1].Destroy;
      FItems.Clear;
   end;
   FBuilt:=Val;
end;

procedure TFreeIntersection.Add(Item:TFreeSpline);
begin
   FItems.Add(Item);
end;{TFreeIntersection.Add}

procedure TFreeIntersection.CalculateArea(Plane:T3DPlane;var Area:TFloatType;var COG:T3DVector;var MomentOfInertia:T2DCoordinate);
var I       : Integer;
    TmpArea : TFloatType;
    TmpCOG  : T3DVector;
    MomI    : T3DVector;

   procedure CalculateSplineArea(Spline:TFreeSpline;var SplineArea:TFloatType;Var SplineCOG,MomInertia:T3DVector);
   var ClosedSpline     : Boolean;
       IntersectionData : TFreeIntersectionData;
       Parameters       : TFloatArray;
       I,J,NoPoints     : Integer;
       T1,T2,T,Side,DeltaA: TFloatType;
       P: T3DVector;
       P1,P2,C,MomI: T2DCoordinate;

       function ProjectTo2D(P:T3DVector):T2DCoordinate;
       begin
          Case IntersectionType of
             fiStation  : begin
                             Result.X:=P.Y;
                             Result.Y:=P.Z;
                          end;
             fiButtock  : begin
                             Result.X:=P.X;
                             Result.Y:=P.Z;
                          end;
             fiWaterline: begin
                             Result.X:=P.X;
                             Result.Y:=P.Y;
                          end;
             else begin
               Result.X:=0.0;
               Result.Y:=0.0;
             end;
          end;
       end;{ProjectTo2D}

   begin
      SplineArea:=0.0;
      SplineCOG:=ZERO;
      MomInertia:=ZERO;
      C.X:=0.0;
      C.Y:=0.0;
      MomI:=C;
      ClosedSpline:=Abs(Spline.Point[0]-Spline.Point[Spline.NumberOfPoints-1])<1e-4;
      if not ClosedSpline then begin                          // make it closed
         Spline.Add(Spline.Point[0]);
         Spline.Knuckle[Spline.NumberOfPoints-2]:=True;
      end;
      Spline.Fragments:=500;
      NoPoints:=2;
      Setlength(Parameters,2);
      Parameters[0]:=0.0;
      Parameters[1]:=1.0;
      if IntersectionType<>fiWaterline then if Spline.IntersectPlane(Plane,IntersectionData) then
      begin
         Setlength(Parameters,NoPoints+Intersectiondata.NumberOfIntersections);
         for I:=1 to Intersectiondata.NumberOfIntersections do
         begin
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
               for J:=0 to 500 do begin
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
               fiStation    : begin
                                 SplineCOG.X:=-FPlane.d;
                                 SplineCOG.Y:=C.X;
                                 SplineCOG.Z:=C.Y;
                                 MomInertia.X:=0;
                                 MomInertia.Y:=MomI.X;
                                 MomInertia.Z:=MomI.Y;
                              end;
               fiButtock    : begin
                                 SplineCOG.X:=C.X;
                                 SplineCOG.Y:=-FPlane.d;
                                 SplineCOG.Z:=C.Y;
                                 MomInertia.X:=MomI.X;
                                 MomInertia.Z:=MomI.Y;
                                 MomInertia.Y:=0;
                              end;
               fiWaterline  : begin
                                 SplineCOG.X:=C.X;
                                 SplineCOG.Y:=C.Y;
                                 SplineCOG.Z:=-FPlane.d;
                                 MomInertia.X:=MomI.X;
                                 MomInertia.Y:=MomI.Y;
                                 MomInertia.Z:=0;
                              end;
            end;
         end;
      end;
   end;{CalculateSplineArea}
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
         COG.X:=COG.X+TmpArea*TmpCOG.X;
         COG.Y:=COG.Y+TmpArea*TmpCOG.Y;
         COG.Z:=COG.Z+TmpArea*TmpCOG.Z;
      end;
      if Area<>0.0 then begin
         COG.X:=COG.X/Area;
         COG.Y:=COG.Y/Area;
         COG.Z:=COG.Z/Area;
         if IntersectionType=fiWaterline then begin
            MomentOfInertia.X:=MomI.X-COG.Y*COG.Y*Area;
            MomentOfInertia.Y:=MomI.Y-COG.X*COG.X*Area;
         end;
      end;
   end;
   if (Count=0) or (Area=0) then begin
      COG:=ZERO;
      Case IntersectionType of
           fiStation    : COG.X:=-FPlane.d;
           fiButtock    : COG.Y:=-FPlane.d;
           fiWaterline  : COG.Z:=-FPlane.d;
      end;
   end;
end;{TFreeIntersection.CalculateArea}

procedure TFreeIntersection.Clear;
var I : integer;
begin
   for I:=1 to Count do Items[I-1].Destroy;
   FItems.Clear;
   FBuilt:=False;
   FShowCurvature:=False;
   UseHydrostaticsSurfacesOnly:=False
end;{TFreeIntersection.Clear}

constructor TFreeIntersection.Create(Owner:TFreeShip);
begin
   inherited Create;
   FOwner:=Owner;
   FItems:=TFasterList.Create;
   Clear;
end;{TFreeIntersection.Create}

// Create the starboardhalf of the ship, for use in hydrostatic calculations
procedure TFreeIntersection.CreateStarboardPart;
var I,J     : integer;
    Spline  : TFreeSpline;
    P1,P2   : T3DVector;
    Area    : TFloatType;
    DeltaA  : TFloatType;
begin
   if self.IntersectionType<>fiButtock then
   begin
      // Copy all present splines and mirror the y-coordinate
      FItems.Capacity:=FItems.Count*2;
      for I:=Count downto 1 do begin
         Spline:=TFreeSpline.Create;
         Spline.Assign(Items[I-1]);
         for J:=1 to Spline.NumberOfPoints do begin
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
      Area:=0;
      P1:=Spline.Point[Spline.NumberOfPoints-1];
      for J:=0 to 500 do begin
         P2:=Spline.Value(J/500);
         Case IntersectionType of
            fiStation   : DeltaA:=0.5*(P2.Y+P1.Y)*(P2.Z-P1.Z);
            fiButtock   : DeltaA:=0.5*(P2.X+P1.X)*(P2.Z-P1.Z);
            fiWaterline : DeltaA:=0.5*(P2.X+P1.X)*(P2.Y-P1.Y);
            else Raise exception.Create(Userstring(66)+'!');
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

procedure TFreeIntersection.Delete;
var Index : integer;
begin
   Case IntersectionType of
      fiStation : begin
                     Index:=Owner.FStations.IndexOf(self);
                     if Index<>-1 then
                     begin
                        Owner.FStations.Delete(Index);
                        Owner.FileChanged:=True;
                        if Redraw then Owner.Redraw;
                        Destroy;
                     end;
                  end;
      fiButtock : begin
                     Index:=Owner.FButtocks.IndexOf(self);
                     if Index<>-1 then
                     begin
                        Owner.FButtocks.Delete(Index);
                        Owner.FileChanged:=True;
                        if Redraw then Owner.Redraw;
                        Destroy;
                     end;
                  end;
      fiWaterline: begin
                     Index:=Owner.FWaterlines.IndexOf(self);
                     if Index<>-1 then
                     begin
                        Owner.FWaterlines.Delete(Index);
                        Owner.FileChanged:=True;
                        if Redraw then Owner.Redraw;
                        Destroy;
                     end;
                  end;
      fiDiagonal : begin
                     Index:=Owner.FDiagonals.IndexOf(self);
                     if Index<>-1 then
                     begin
                        Owner.FDiagonals.Delete(Index);
                        Owner.FileChanged:=True;
                        if Redraw then Owner.Redraw;
                        Destroy;
                     end;
                  end;

   end;
end;

destructor TFreeIntersection.Destroy;
begin
   Clear;
   FItems.Destroy;
   Inherited Destroy;
end;

procedure TFreeIntersection.Draw(Viewport:TFreeViewport);
var I,J,R,G,B: integer;
    Spline  : TFreeSpline;
    P,P2,N  : T3DVector;
    Pts,CPts: array of TPoint;
    Curv    : TFloatType;
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

         Spline.CurvatureColor:=Owner.Preferences.CurvaturePlotColor;
         Spline.CurvatureScale:=Owner.Visibility.CurvatureScale;
         Spline.ShowCurvature:=(Owner.Visibility.ShowCurvature) and (ShowCurvature);;
         if Spline.ShowCurvature then Spline.Fragments:=800
                                 else Spline.Fragments:=600;

         Setlength(Pts,Spline.Fragments+1);
         if Spline.ShowCurvature then Setlength(CPts,Spline.Fragments+1);
         // Draw portside
         DrawIt:=IntersectionType in [fiButtock,fiWaterline,fiDiagonal];
         if IntersectionType=fiStation then
            Drawit:=(Viewport.ViewType<>fvBodyplan)
                or (Owner.Visibility.ModelView=mvBoth)
                or (Spline.Max.X>=Owner.ProjectSettings.MidleFrame );
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
                  P2.X:=P.X-Curv*Spline.CurvatureScale*N.X;
                  P2.Y:=P.Y-Curv*Spline.CurvatureScale*N.Y;
                  P2.Z:=P.Z-Curv*Spline.CurvatureScale*N.Z;
                  CPts[J]:=Viewport.Project(P2);
               end else begin
                  P:=Spline.Value(J/Spline.Fragments);
                  Pts[J]:=Viewport.Project(P);
               end;
            end;
            if Spline.ShowCurvature then begin
               Viewport.SetPenWidth(1);
               Viewport.PenColor:=Spline.CurvatureColor;
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
         if (Owner.Visibility.ModelView=mvBoth) then DrawIt:=True
            else if (Viewport.ViewType=fvBodyplan)
                 and (Spline.Max.X<=Owner.ProjectSettings.MidleFrame) then DrawIt:=True;
         if DrawIt then begin                           // Draw starboard side
            for J:=0 to Spline.Fragments do begin
               if Spline.ShowCurvature then begin
                  Curv:=Spline.Curvature(J/Spline.Fragments,P,N);
                  N.Y:=-N.Y;
                  P.Y:=-P.Y;
                  Pts[J]:=Viewport.Project(P);
                  P2.X:=P.X-Curv*Spline.CurvatureScale*N.X;
                  P2.Y:=P.Y-Curv*Spline.CurvatureScale*N.Y;
                  P2.Z:=P.Z-Curv*Spline.CurvatureScale*N.Z;
                  CPts[J]:=Viewport.Project(P2);
               end else begin
                  P:=Spline.Value(J/Spline.Fragments);
                  P.Y:=-P.Y;
                  Pts[J]:=Viewport.Project(P);
               end;
            end;
            if Spline.ShowCurvature then begin
               Viewport.SetPenWidth(1);
               Viewport.PenColor:=Spline.CurvatureColor;
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
         for J:=1 to Spline.Fragments do begin
            P2:=Spline.Value(J/Spline.Fragments);
            Viewport.DrawLineToZBuffer(P,P2,R,G,B);
            P:=P2;
         end;
         if Owner.Visibility.ModelView=mvBoth then begin // Draw starboardside as well
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

procedure TFreeIntersection.DrawAll;
var I : integer;
begin
   for I:=1 to Owner.NumberOfViewports do Draw(Owner.Viewport[I-1]);
end;

procedure TFreeIntersection.Extents(Var Min,Max:T3DVector);
var I    : integer;
begin
   if not built then Rebuild;
   for I:=1 to Count do Items[I-1].Extents(Min,Max);
end;

procedure TFreeIntersection.LoadBinary(Source:TFreeFileBuffer);
var I,J,M,N : integer;
    Spline  : TFreeSpline;
    P       : T3DVector;
    Bool    : Boolean;
begin
   Source.LoadInteger(I);
   IntersectionType:=TFreeIntersectionType(I);
   if Owner.FileVersion>=fv191 then begin
      Source.LoadBoolean(FShowCurvature);
   end else FShowCurvature:=False;
   Source.LoadT3DPlane(FPlane);
   Source.LoadBoolean(FBuilt);
   Source.LoadInteger(N);
   FItems.Capacity:=N;
   for I:=1 to N do begin
      Spline:=TFreeSpline.Create;
      FItems.Add(Spline);              // Read number of points for this spline
      Source.LoadInteger(M);                  // Read actual 3D coordinates
      Spline.Capacity:=M;
      for J:=1 to M do begin
         if Owner.FileVersion>=fv160 then begin
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
            end else Source.LoadT3DVector(P);
         end else Source.LoadT3DVector(P);
         Spline.Add(P);
         Source.LoadBoolean(Bool);
         Spline.Knuckle[J-1]:=Bool;
      end;
   end;
end;

procedure TFreeIntersection.Rebuild;
var I:Integer;
begin                                     // Force to destroy all current Items
   Built:=false;
   Owner.Surface.IntersectPlane(Plane,UseHydrostaticsSurfacesOnly,FItems);
   // Use a low simplification factor to remove only points that are (nearly) on a line
   if Owner.ProjectSettings.ProjectSimplifyIntersections then for I:=1 to Count do self.Items[I-1].Simplify(2.0);
   Built:=true;
end;

procedure TFreeIntersection.SaveBinary(Destination:TFreeFileBuffer);
var I,J     : integer;
    Spline  : TFreeSpline;
    P       : T3DVector;
begin
   Destination.Add(Ord(IntersectionType));
   if Owner.FileVersion>=fv191 then begin
      Destination.Add(FShowCurvature);
   end;
   Destination.Add(FPlane);
   Destination.Add(FBuilt);
   Destination.Add(Count);
   for I:=1 to Count do begin
      Spline:=Items[I-1];
      Destination.Add(Spline.NumberOfPoints);
      for J:=1 to Spline.NumberOfPoints do begin
         P:=Spline.Point[J-1];
         if Owner.FileVersion>=fv160 then begin
            Case IntersectionType of
               fiStation    : begin
                                 Destination.Add(P.Y);
                                 Destination.Add(P.Z);
                                 Destination.Add(Spline.Knuckle[J-1]);
                              end;
               fiButtock    : begin
                                 Destination.Add(P.X);
                                 Destination.Add(P.Z);
                                 Destination.Add(Spline.Knuckle[J-1]);
                              end;
               fiWaterline  : begin
                                 Destination.Add(P.X);
                                 Destination.Add(P.Y);
                                 Destination.Add(Spline.Knuckle[J-1]);
                              end;
               fiDiagonal   : begin
                                 Destination.Add(P);
                                 Destination.Add(Spline.Knuckle[J-1]);
                              end;
            end;
         end else begin
            Destination.Add(P);
            Destination.Add(Spline.Knuckle[J-1]);
         end;
      end;
   end;
end;{TFreeIntersection.SaveBinary}

{
   TFreeMarker
}
function TFreeMarker.FGetSelected:Boolean;
   begin Result:=Owner.FSelectedMarkers.SortedIndexOf(self)<>-1; end;

procedure TFreeMarker.FSetSelected(val:Boolean);
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
procedure TFreeMarker.Clear;
    begin FVisible:=True; inherited Clear; end;

function TFreeMarker.DistanceToCursor(X,Y:Integer;Viewport:TFreeViewport):integer;
var I,Tmp    : Integer;
    Pt,P1,P2 : TPoint;
    V1,V2    : T3DVector;
    Param    : TFloatType;
begin
   Result:=1000000;
   if (Viewport.ViewType=fvBodyPlan)
   and (not (Owner.Visibility.ModelView=mvBoth)) then begin // Check if cursor position lies within the boundaries
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
            and (V2.X>Owner.ProjectSettings.MidleFrame)) then
            begin
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
      for I:=1 to NumberOfPoints do begin
         V1:=Point[I-1];
         V1.Y:=-V1.Y;
         Point[I-1]:=V1;
      end;
//    try
         Tmp:=inherited DistanceToCursor(X,Y,Viewport);
         if Tmp<Result then Result:=Tmp;
//    finally
         for I:=1 to NumberOfPoints do begin
            V1:=Point[I-1];
            V1.Y:=-V1.Y;
            Point[I-1]:=V1;
         end;
//    end;
   end;
end;

procedure TFreeMarker.Delete;
var Index:Integer;
begin
   Index:=Owner.FSelectedMarkers.SortedIndexOf(Self);
   if Index<>-1 then Owner.FSelectedMarkers.Delete(Index);
   Index:=Owner.FMarkers.IndexOf(Self);
   if Index<>-1 then Owner.FMarkers.Delete(Index);
   Destroy;
end;

procedure TFreeMarker.Draw(Viewport:TFreeViewport);
var I,J,Size,Scale,NParam,Fragm: Integer;
    Pt      : TPoint;
    Plane   : T3DPlane;
    Output  : TFreeIntersectionData;
    Param   : TFloatArray;
    P3D,P2,Normal: T3DVector;
    PArray1,PArray2: array of TPoint;
    C,T     :TFloatType;
begin
   if Visible then begin
      if Owner<>nil then begin
         if Selected then Color:=Owner.Preferences.SelectColor
                     else Color:=owner.Preferences.MarkerColor;
         Size:=Owner.Preferences.PointSize;
      end else begin
         Color:=clLime;
         Size:=2;
         MessageDlg(Userstring(67),mtError,[mbOk],0);
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
            Setlength(Param,NParam+Output.NumberOfIntersections);
            for I:=1 to Output.NumberOfIntersections do begin
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
                  P2.X:=P3D.X-C*2*CurvatureScale*Normal.X;
                  P2.Y:=P3D.Y-C*2*CurvatureScale*Normal.Y;
                  P2.Z:=P3D.Z-C*2*CurvatureScale*Normal.Z;
                  PArray2[J-1]:=Viewport.Project(P2);
               end;
               Viewport.SetPenWidth(1);
               Viewport.PenColor:=CurvatureColor;
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
         for I:=1 to NumberOfPoints do begin
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
         for I:=1 to NumberOfPoints do  begin
            Pt:=Viewport.Project(Point[I-1]);
            Viewport.Canvas.MoveTo(Pt.X-Size,Pt.Y-Size);
            Viewport.Canvas.LineTo(Pt.X+Size,Pt.Y+Size);
            Viewport.Canvas.MoveTo(Pt.X-Size,Pt.Y+Size);
            Viewport.Canvas.LineTo(Pt.X+Size,Pt.Y-Size);
         end;
      end;
   end;
end;{TFreeMarker.Draw}

procedure TFreeMarker.LoadBinary(Source:TFreeFileBuffer);
var sel:boolean;
begin
   Source.LoadBoolean(FVisible);
   if Owner.FileVersion>=fv260 then begin
      Source.LoadBoolean(Sel);
      if sel then Owner.FSelectedMarkers.AddSorted(self);
   end;
   Inherited LoadBinary(Source);
end;

procedure TFreeMarker.SaveBinary(Destination:TFreeFileBuffer);
begin
   Destination.Add(FVisible);
   if Owner.FileVersion>=fv260 then
   begin
      Destination.Add(Selected);
   end;
   Inherited SaveBinary(Destination);
end;

{---------------}
{ TFreeFlowline }
{---------------}
function TFreeFlowline.FGetColor:TColor;
begin
   if Selected then result:=Owner.Preferences.SelectColor
      else if FMethodNew then result:=clRed
          else Result:=clBlue;
end;

function TFreeFlowline.FGetSelected:Boolean;
   begin Result:=Owner.FSelectedFlowlines.SortedIndexOf(self)<>-1; end;
function TFreeFlowline.FGetVisible:Boolean;
   begin Result:=owner.Visibility.ShowFlowlines; end;

procedure TFreeFlowline.FSetSelected(val:Boolean);
var Index : Integer;
begin
   Index:=Owner.FSelectedFlowlines.SortedIndexOf(self);
   if Val then begin               // Only add if it is not already in the list
      if Index=-1 then Owner.FSelectedFlowlines.AddSorted(self);
   end else begin
      if Index<>-1 then Owner.FSelectedFlowlines.Delete(index);
   end;
   if Assigned(Owner.Surface.OnSelectItem) then Owner.Surface.OnSelectItem(self);
end;

procedure TFreeFlowline.FSetBuild(val:Boolean);
    begin FBuild:=val; if not Build then FFlowline.Clear; end;

procedure TFreeFlowline.Clear;
begin
   FProjectionPoint.X:=0;
   FProjectionPoint.Y:=0;
   FProjectionView:=fvProfile;
   FFlowLine.Clear;
   FBuild:=false;
   FMethodNew:=False;
end;

constructor TFreeFlowline.Create(Owner:TFreeShip);
begin
   inherited Create;
   FOwner:=owner;
   FFlowLine:=TFreespline.Create;
   Clear;
end;

procedure TFreeFlowline.Delete;
var Index:Integer;
begin
   Index:=Owner.FSelectedFlowlines.SortedIndexOf(Self);
   if Index<>-1 then Owner.FSelectedFlowlines.Delete(Index);
   Index:=Owner.FFlowLines.IndexOf(Self);
   if Index<>-1 then Owner.FFlowlines.Delete(Index);
   Destroy;
end;

destructor TFreeFlowline.Destroy;
begin
   Clear;
   FFlowLine.Destroy;
   Inherited Destroy;
end;

function TFreeFlowline.DistanceToCursor(X,Y:Integer;Viewport:TFreeViewport):integer;
var I,Tmp    : Integer;
    Pt,P1,P2 : TPoint;
    V1,V2    : T3DVector;
    Param    : TFloatType;
begin
   Result:=1000000;
   if (Viewport.ViewType=fvBodyPlan)
   and (not (Owner.Visibility.ModelView=mvBoth)) then begin
      Pt.X:=X;           // Check if cursor position lies within the boundaries
      Pt.Y:=Y;
      if (Pt.X>=0) and (Pt.X<=Viewport.Width)
      and (Pt.Y>=0) and (Pt.Y<=Viewport.Height) then begin
         V1:=FFlowline.Value(0.0);
         if V1.X<Owner.ProjectSettings.MidleFrame then V1.Y:=-V1.Y;
         for I:=1 to FFlowline.Fragments do begin
            V2:=FFlowline.Value((I-1)/(FFlowline.Fragments-1));
            if V2.X<Owner.ProjectSettings.MidleFrame then V2.Y:=-V2.Y;
            if ((V1.X<Owner.ProjectSettings.MidleFrame)
            and (V2.X<Owner.ProjectSettings.MidleFrame))
            or ((V1.X>Owner.ProjectSettings.MidleFrame)
            and (V2.X>Owner.ProjectSettings.MidleFrame)) then
            begin
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
   if Owner.Visibility.ModelView=mvBoth then begin
      for I:=1 to FFlowline.NumberOfPoints do begin
         V1:=FFlowline.Point[I-1];
         V1.Y:=-V1.Y;
         FFlowline.Point[I-1]:=V1;
      end;
//    try
         Tmp:=FFlowline.DistanceToCursor(X,Y,Viewport);
         if Tmp<Result then Result:=Tmp;
//    finally
         for I:=1 to FFlowline.NumberOfPoints do begin
            V1:=FFlowline.Point[I-1];
            V1.Y:=-V1.Y;
            FFlowline.Point[I-1]:=V1;
         end;
//    end;
   end;
end;

procedure TFreeFlowline.Draw(Viewport:TFreeViewport);
var I,J,Scale,Size,NParam,Fragm: Integer;
    Plane   : T3DPlane;
    Output  : TFreeIntersectionData;
    Param   : TFloatArray;
    P3D     : T3DVector;
    PArray1 : array of TPoint;
    Pt      : TPoint;
    T       : TFloatType;
begin
   if not build then rebuild;
   FFlowline.Color:=Color;
   FFlowline.Fragments:=600;
   if (FFlowline.NumberOfPoints>0)
   and (Viewport.ViewportMode=vmWireframe) then begin   // draw flowline source
      P3D:=FFlowline.Point[0];
      if (Viewport.ViewType=fvBodyplan)
      and (Owner.Visibility.ModelView<>mvBoth)
      and (P3D.X<Owner.ProjectSettings.MidleFrame)
      then P3D.Y:=-P3D.Y;
      Pt:=Viewport.Project(P3D);
      Size:=Round(Sqrt(Viewport.Zoom)*(Owner.Preferences.PointSize+1));
      if size<1 then size:=1;
      Viewport.BrushStyle:=bsClear;
//    if Viewport.Printing then Size:=round(Size*Viewport.PrintResolution/150);
      Viewport.PenColor:=clDkGray;
      Viewport.BrushColor:=clWhite;
      Viewport.BrushStyle:=bsSolid;
      // Draw entire circle in white;
      Viewport.Canvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
      if Owner.Visibility.ModelView=mvBoth then begin
         P3D.Y:=-P3D.Y;
         Pt:=Viewport.Project(P3D);
         // Draw entire circle in white;
         Viewport.Canvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
      end;
   end;
   if (Viewport.ViewType=fvBodyPlan) and (Owner.Visibility.ModelView<>mvBoth) then
   begin
      Plane:=SetPlane(1.0,0.0,0.0,-Owner.ProjectSettings.MidleFrame);
      NParam:=2;
      Setlength(Param,NParam);
      Param[0]:=0.0;
      Param[1]:=1.0;
      if FFlowline.IntersectPlane(Plane,Output) then
      begin
         Setlength(Param,NParam+Output.NumberOfIntersections);
         for I:=1 to Output.NumberOfIntersections do
         begin
            Param[NParam]:=Output.Parameters[I-1];
            inc(NParam);
         end;
         ArraySort( Param,NParam );
      end;
      for I:=2 to NParam do
      begin
         P3D:=FFlowline.Value(0.5*(Param[I-2]+Param[I-1]));
         if P3D.X<Owner.ProjectSettings.MidleFrame then Scale:=-1
                                                   else scale:=1;
         Fragm:=Round((Param[I-1]-Param[I-2])*FFlowline.Fragments);
         if Fragm<10 then Fragm:=10;
         SetLength(PArray1,Fragm);
         for J:=1 to Fragm do
         begin
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
   end else
   begin
      FFlowline.Draw(Viewport);
      if Owner.Visibility.ModelView=mvBoth then
      begin
         for I:=1 to FFlowline.NumberOfPoints do
         begin
            P3D:=FFlowline.Point[I-1];
            P3D.Y:=-P3D.Y;
            FFlowline.Point[I-1]:=P3D;
         end;
//       try
            FFlowline.Draw(Viewport);
//       finally
            for I:=1 to FFlowline.NumberOfPoints do
            begin
               P3D:=FFlowline.Point[I-1];
               P3D.Y:=-P3D.Y;
               FFlowline.Point[I-1]:=P3D;
            end;
//       end;
      end;
   end;
end;{TFreeFlowline.Draw}

procedure TFreeFlowline.LoadBinary(Source:TFreeFileBuffer);
var I,N : Integer;
    P   : T3DVector;
    K   : Boolean;
begin
   Source.LoadTFloatType(FProjectionPoint.X);
   Source.LoadTFloatType(FProjectionPoint.Y);
   Source.LoadInteger(I);
   FProjectionView:=TFreeviewType(I);
   Source.LoadBoolean(FBuild);
   Source.loadBoolean(K);
   if K then Owner.FSelectedFlowlines.AddSorted(self);
   Source.LoadInteger(N);
   FFlowline.Capacity:=N;
   for I:=1 to N do begin
      Source.LoadT3DVector(P);
      Source.LoadBoolean(K);
      FFlowline.Add(P);
      FFlowline.Knuckle[FFlowline.NumberOfPoints-1]:=K;
   end;
end;{TFreeFlowline.LoadBinary}

procedure TFreeFlowline.Rebuild;
type TTriangle  = record
                     P1,P2,P3 : Integer;
                     Plane    : T3DPlane;
                     Index    : Integer;
                     Processed: Boolean;
                  end;
     TPointData = record
                     Coord     : T3DVector;
                     FlowDir   : T3DVector;
                     Triangles : array of integer;
                     Ntriangles: Integer;
                  end;

var Points     : TFasterList;
    Faces      : TFasterList;
    Face       : TFreeSubdivisionControlFace;
    Point      : TFreeSubdivisionPoint;
    Child      : TFreeSubdivisionFace;
    I,J,K,L    : Integer;
    Index      : Integer;
    Layer      : TFreeSubdivisionLayer;
    WlHeight   : TFloatType;
    Triangles  : array of TTriangle;
    NTriangles : Integer;
    Iteration  : Integer;
    Skip1,Skip2:integer;
    TriangleCapacity:Integer;
    PointData  : array of TPointData;
    StartPoint : T3DVector;
    EndPoint   : T3DVector;
    Intersection:T3DVector;
    Direction  : T3DVector;
    Valid      : Boolean;

    procedure AddTriangleToPoint(var Point:TPointData;TriangleIndex:Integer);
    begin
       inc(Point.Ntriangles);
       Setlength(Point.Triangles,Point.Ntriangles);
       Point.Triangles[Point.Ntriangles-1]:=TriangleIndex;
    end;{AddTriangleToPoint}

    procedure AddTriangle(P1,P2,P3:TFreeSubdivisionPoint);
    begin
       if NTriangles=TriangleCapacity then
       begin
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
    end;{AddTriangle}

    function CalculateFlowDirection2(Incoming:T3DVector;Point:TFreeSubdivisionPoint):T3DVector;
    var Normal    : T3DVector;
        Direction : T3DVector;
        P,Proj    : T3DVector;
        Plane     : T3DPlane;
    begin
       //Incoming.x:=Incoming.x-1.001;
       //Incoming.x:=Incoming.X-1.001;
       //Incoming.y:=0.4*Incoming.y;
       //Incoming.z:=0.4*Incoming.z;
       Incoming:=Normalize(Incoming);
       Normal:=Point.Normal;
       P:=Point.Coordinate;
       Plane:=PlanePointNormal(P,Normal);
       Direction:=Normalize(Normal+Incoming);
       Incoming:=P+Direction;
       Proj:=ProjectPointOnPlane(Incoming,Plane);
       Direction:=Proj-P;
       Result:=Normalize(Direction);
    end;{CalculateFlowDirection2}

    function CalculateFlowDirection(Point:TFreeSubdivisionPoint):T3DVector;
    var V : T3DVector;
    begin
       V:=Vector(-1,0,0);
       Result:=CalculateFlowDirection2(V,Point);
    end;{CalculateFlowDirection}

    function FindInitialTriangle(StartPoint,EndPoint:T3DVector;var Int,Dir:T3DVector):Integer;
    var I         : Integer;
        Triangle  : TTriangle;
        S1,S2,s,t : TFloatType;
        P,u,v,w   : T3DVector;
        P0,P1,P2  : T3DVector;
        Distance  : Double;
        b0,b1,b2  : Double;
        UdotV     : Double;
        UdotU     : Double;
        VdotV     : Double;
        WdotU     : Double;
        WdotV     : Double;
    begin
       Result:=-1;
       Distance:=1e8;
       Int:=Zero;
       Dir:=Zero;
       for I:=1 to NTriangles do
       begin
          Triangle:=Triangles[I-1];
          S1:=Triangle.Plane.a*StartPoint.x+Triangle.Plane.b*StartPoint.y+Triangle.Plane.c*StartPoint.z+Triangle.Plane.d;
          S2:=Triangle.Plane.a*EndPoint.x+Triangle.Plane.b*EndPoint.y+Triangle.Plane.c*EndPoint.z+Triangle.Plane.d;
          if ((S1<0) and (S2>0)) or ((S1>0) and (S2<0)) then
          begin
             // possible intersection
             if S1=S2 then T:=0.5
                      else T:=-s1/(s2-s1);
             P.X:=StartPoint.X+T*(EndPoint.X-StartPoint.X);
             P.Y:=StartPoint.Y+T*(EndPoint.Y-StartPoint.Y);
             P.Z:=StartPoint.Z+T*(EndPoint.Z-StartPoint.Z);
             if PointInTriangle(P,PointData[Triangle.P1].Coord,PointData[Triangle.P2].Coord,PointData[Triangle.P3].Coord) then
             begin
                T:=Abs(StartPoint-P);
                if T<Distance then begin
                   Distance:=T;
                   Result:=I-1;
                   Int:=P;
                end;
             end;
          end;
       end;
       if Result<>-1 then
       begin
          // Calculate baycentric coordinates to interpolate between the three flowdirections
          // http://softsurfer.com/Archive/algorithm_0104/algorithm_0104.htm
          Triangle:=Triangles[result];
          P0:=PointData[Triangle.P1].Coord;
          P1:=PointData[Triangle.P2].Coord;
          P2:=PointData[Triangle.P3].Coord;
          u:=P1-P0;
          v:=P2-P0;
          w:=Int-P0;
          UdotU:=Dotproduct(U,U);
          UdotV:=Dotproduct(U,V);
          VdotV:=Dotproduct(V,V);
          WdotU:=Dotproduct(W,U);
          WdotV:=Dotproduct(W,V);
          s:=(UdotV*WdotV-VdotV*WdotU)/(UdotV*UdotV-UdotU*VdotV);
          t:=(UdotV*WdotU-UdotU*WdotV)/(UdotV*UdotV-UdotU*VdotV);
          b0:=1-s-t;
          b1:=s;
          b2:=t;                                                       // check
          t:=b0+b1+b2;
          if T=1 then begin
             P0:=PointData[Triangle.P1].FlowDir;
             P1:=PointData[Triangle.P2].FlowDir;
             P2:=PointData[Triangle.P3].FlowDir;
             Dir.X:=b0*P0.X+b1*P1.X+b2*P2.X;
             Dir.Y:=b0*P0.Y+b1*P1.Y+b2*P2.Y;
             Dir.Z:=b0*P0.Z+b1*P1.Z+b2*P2.Z;
             if FMethodNew then Dir:=Normalize(Vector(-1,0.1,-0.1));
          end else
          begin
             Result:=Result-1+1;
          end;
       end;
    end;{FindInitialTriangle}

    function ProcessTriangle(var Triangle:TTriangle;var SkipInd1,SkipInd2:Integer;var Intersection,Direction:T3DVector;var NextTriangle:integer):boolean;
    var P1,P2     : T3DVector;
        Dir1,Dir2 : T3DVector;
        Ind1,Ind2 : Integer;
        I         : Integer;
        Int       : T3DVector;
        Distance  : TFloatType;
        Param     : double;

        function NextTriangleIndex(P1,P2,CurrIndex:Integer):Integer;
        var Point1,Point2:TPointData;
            I,J          : Integer;
        begin
           Result:=-1;
           Point1:=PointData[P1];
           Point2:=PointData[P2];
           for I:=1 to Point1.Ntriangles do begin
              for J:=1 to Point2.Ntriangles do begin
                 if (Point1.Triangles[I-1]=Point2.Triangles[J-1])
                 and (Point1.Triangles[I-1]<>CurrIndex) then begin
                    Result:=Point1.Triangles[I-1];
                    exit;
                 end;
              end;
           end;
        end;{NextTriangleIndex}

    begin
       Result:=False;
       NextTriangle:=Triangle.Index;
       Triangle.Processed:=True;

       P1:=ProjectPointOnPlane(Intersection,Triangle.Plane);
       P1.X:=P1.X+0.0005*Direction.X;
       P1.Y:=P1.Y+0.0005*Direction.Y;
       P1.Z:=P1.Z+0.0005*Direction.Z;
       if not PointInTriangle(P1,PointData[Triangle.P1].Coord,PointData[Triangle.P2].Coord,PointData[Triangle.P3].Coord) then
       begin
          P1:=ProjectPointOnPlane(Intersection,Triangle.Plane);
       end;

       P1:=ProjectPointOnPlane(P1,Triangle.Plane);

       Distance:=50;
       P2.X:=P1.X+Distance*Direction.X;
       P2.Y:=P1.Y+Distance*Direction.Y;
       P2.Z:=P1.Z+Distance*Direction.Z;
       P2:=ProjectPointOnPlane(P2,Triangle.Plane);
       // test all three linesegments for intersection

       for I:=1 to 3 do
       begin
          Case I of
             1 : Ind1:=Triangle.P1;
             2 : Ind1:=Triangle.P2;
             3 : Ind1:=Triangle.P3;
             Else Ind1:=0;
          end;
          Case I of
             1 : Ind2:=Triangle.P2;
             2 : Ind2:=Triangle.P3;
             3 : Ind2:=Triangle.P1;
             else Ind2:=0;
          end;
          if ((Ind1=SkipInd1) and (Ind2=SkipInd2)) or ((Ind1=SkipInd2) and (Ind2=SkipInd1)) then
          begin
          end else if Lines3DIntersect(P1,P2,PointData[Ind1].Coord,PointData[Ind2].Coord,Param,Int) then
          begin
             Distance:=Triangle.Plane.a*Int.x+Triangle.Plane.b*Int.y+Triangle.Plane.c*Int.z+Triangle.Plane.d;
             if Distance<1e-1 then
             begin
               Intersection:=Int;
               // calculate direction
               if FMethodNew then
               begin
                  Dir1:=CalculateFlowDirection2(Direction,Points[Ind1]);
                  Dir2:=CalculateFlowDirection2(Direction,Points[Ind2]);
               end else
               begin
                  Dir1:=PointData[Ind1].FlowDir;
                  Dir2:=PointData[Ind2].FlowDir;
               end;
               SkipInd1:=Ind1;
               SkipInd2:=ind2;
               Direction.X:=Dir1.X+Param*(Dir2.X-Dir1.X);
               Direction.Y:=Dir1.Y+Param*(Dir2.Y-Dir1.Y);
               Direction.Z:=Dir1.Z+Param*(Dir2.Z-Dir1.Z);
               NextTriangle:=NextTriangleIndex(ind1,Ind2,Triangle.Index);
               Result:=True;
               Exit;
             end;
          end;
       end;
    end;{ProcessTriangle}

begin
   // clear any present data
   Build:=false;

   // Assemble all faces that are (partially) submerged and extract points
   Faces:=TFasterList.Create;
   WlHeight:=Owner.FindLowestHydrostaticsPoint+Owner.ProjectSettings.ProjectDraft;

   //wlheight:=owner.surface.max.z;

   if Owner.surface.NumberOfPoints<0 then exit;
   for I:=1 to Owner.Surface.NumberOfLayers do if Owner.Surface.Layer[I-1].UseInHydrostatics then
   begin
      Layer:=Owner.Surface.Layer[I-1];
      for J:=1 to Layer.Count do if Layer.Items[J-1].Min.Z<=WlHeight then
      begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do
         begin
            Child:=Face.Child[K-1];
            for L:=1 to Child.NumberOfpoints do if Child.Point[L-1].Coordinate.Z<=WlHeight then
            begin
               // Face is (partially) submerged;
               Faces.Add(Child);
               break;
            end;
         end;
      end
   end;
   if Faces.Count>0 then
   begin
      Points:=TFasterList.create;
      Points.Capacity:=Faces.Count+100;
      for I:=1 to Faces.Count do
      begin
         Child:=Faces[I-1];
         for J:=1 to Child.NumberOfpoints do
         begin
            Point:=Child.Point[J-1];
            if Points.SortedIndexOf(Point)=-1 then Points.AddSorted(Point);
         end;
      end;
      Points.Sort;
      Setlength(PointData,Points.Count);
      for I:=1 to Points.Count do
      begin
         Point:=Points[I-1];
         PointData[I-1].Coord:=Point.Coordinate;
         PointData[I-1].FlowDir:=CalculateFlowDirection(Point);
         PointData[I-1].Ntriangles:=0;
      end;

      TriangleCapacity:=2*Faces.Count;
      Setlength(Triangles,TriangleCapacity);
      NTriangles:=0;
      for I:=1 to Faces.Count do
      begin
         Child:=Faces[I-1];
         for J:=3 to Child.NumberOfpoints do AddTriangle(Child.Point[0],Child.Point[J-2],Child.Point[J-1]);
      end;

      Case FProjectionView of
         fvProfile : begin
                        Startpoint.X:=FProjectionPoint.X;
                        StartPoint.Y:=Owner.Surface.Max.Y+10;
                        StartPoint.Z:=FProjectionPoint.Y;
                        EndPoint:=Vector(StartPoint.X,0,StartPoint.Z);
                     end;
         fvPlan    : begin
                        Startpoint.X:=FProjectionPoint.X;
                        StartPoint.Y:=FProjectionPoint.Y;
                        StartPoint.Z:=Owner.Surface.Min.Z-10;
                        EndPoint:=Vector(StartPoint.X,StartPoint.Y,Owner.Surface.Max.Z+100);
                     end;
         fvBodyplan: if FProjectionPoint.X<0 then
                     begin
                        Startpoint.X:=Owner.Surface.Min.X-10;
                        StartPoint.Y:=-FProjectionPoint.X;
                        StartPoint.Z:=FProjectionPoint.Y;
                        EndPoint:=Vector(Owner.Surface.Max.X+10,StartPoint.Y,StartPoint.Z);
                     end else
                     begin
                        Startpoint.X:=Owner.Surface.Max.X+10;
                        StartPoint.Y:=FProjectionPoint.X;
                        StartPoint.Z:=FProjectionPoint.Y;
                        EndPoint:=Vector(Owner.Surface.Min.X-10,StartPoint.Y,StartPoint.Z);
                     end;
      end;

      // find the initial triangle
      Index:=FindInitialTriangle(StartPoint,EndPoint,Intersection,Direction);
      Skip1:=-1;
      Skip2:=-1;
      if index<>-1 then
      begin
         FFlowline.Add(Intersection);
         // trace triangles from here
         Iteration:=0;
         repeat
            if Triangles[index].Processed then Valid:=False
                                          else Valid:=ProcessTriangle(Triangles[index],Skip1,Skip2,Intersection,Direction,Index);
            if Valid then
            begin
               FFlowline.Add(Intersection);
            end else
            begin
               Valid:=ProcessTriangle(Triangles[index],Skip1,Skip2,Intersection,Direction,Index);
            end;
            inc(Iteration);
         until (not valid) or (index=-1) or (Iteration>5000);
         While FFlowline.NumberOfPoints>1 do
         begin
            if (FFlowline.Point[FFlowline.NumberOfPoints-1].Z>WlHeight) and (FFlowline.Point[FFlowline.NumberOfPoints-2].Z>WlHeight) then
            begin
               FFlowline.DeletePoint(FFlowline.NumberOfPoints-1);
            end else if (FFlowline.Point[FFlowline.NumberOfPoints-1].Z>WlHeight) and (FFlowline.Point[FFlowline.NumberOfPoints-2].Z<WlHeight) then
            begin
               Endpoint.X:=FFlowline.Point[FFlowline.NumberOfPoints-2].X+(FFlowline.Point[FFlowline.NumberOfPoints-1].X-FFlowline.Point[FFlowline.NumberOfPoints-2].X)*(WlHeight-FFlowline.Point[FFlowline.NumberOfPoints-2].Z)/(FFlowline.Point[FFlowline.NumberOfPoints-1].Z-FFlowline.Point[FFlowline.NumberOfPoints-2].Z);
               Endpoint.Y:=FFlowline.Point[FFlowline.NumberOfPoints-2].Y+(FFlowline.Point[FFlowline.NumberOfPoints-1].Y-FFlowline.Point[FFlowline.NumberOfPoints-2].Y)*(WlHeight-FFlowline.Point[FFlowline.NumberOfPoints-2].Z)/(FFlowline.Point[FFlowline.NumberOfPoints-1].Z-FFlowline.Point[FFlowline.NumberOfPoints-2].Z);
               EndPoint.Z:=wlHeight;
               FFlowline.Point[FFlowline.NumberOfPoints-1]:=EndPoint;
            end else break;
         end;
      end;
      Points.Destroy;
   end;
   Faces.Destroy;
   FBuild:=True;
end;{TFreeFlowline.Rebuild}

procedure TFreeFlowline.SaveBinary(Destination:TFreeFileBuffer);
var I:Integer;
begin
   Destination.Add(FProjectionPoint.X);
   Destination.Add(FProjectionPoint.Y);
   Destination.Add(Ord(FProjectionView));
   Destination.Add(FBuild);
   Destination.Add(Selected);
   Destination.Add(FFlowline.NumberOfPoints);
   for I:=1 to FFlowline.NumberOfPoints do
   begin
      Destination.Add(FFlowline.Point[I-1]);
      Destination.Add(FFlowline.Knuckle[I-1]);
   end;
end;{TFreeFlowline.SaveBinary}
{
   TFreeVisibility
   This object stores all visibility options for the hull
}
procedure TFreeVisibility.FSetCurvatureScale(Val:TFloatType);
var I:Integer;
begin
   if abs(Val-FCurvatureScale)>1e-5 then begin
      FCurvatureScale:=Val;
      Owner.FileChanged:=True;
      For I:=1 to Owner.NumberOfViewports do if Owner.Viewport[I-1].ViewportMode=vmWireFrame then Owner.Viewport[I-1].Refresh
   end;
end;

procedure TFreeVisibility.FSetCursorIncrement(val:TFloatType);
begin
   if Val<1e-5 then Val:=1e-5;
   if FCursorIncrement<>val then Owner.FileChanged:=True;
   FCursorIncrement:=val;
   if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(self);
end;

procedure TFreeVisibility.FSetModelView(Val:TFreeModelView);
begin
   if Val<>FModelView then begin
      FModelView:=Val;
      Owner.FileChanged:=True;
      Owner.Draw;
   end;
end;

procedure TFreeVisibility.FSetShowInteriorEdges(Val:Boolean);
var I : Integer;
begin
   if Val<>FShowInteriorEdges then begin
      FShowInteriorEdges:=val;
      if not val then for I:=Owner.NumberOfSelectedControlFaces downto 1 do Owner.SelectedControlFace[I-1].Selected:=False;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowControlNet(Val:Boolean);
var I : Integer;
begin
   if Val<>FShowControlNet then begin FShowControlNet:=val;
      if not FShowControlNet then begin
         for I:=Owner.NumberOfSelectedControlEdges downto 1 do Owner.SelectedControlEdge[I-1].Selected:=False;
         for I:=Owner.NumberOfSelectedControlPoints downto 1 do Owner.SelectedControlPoint[I-1].Selected:=False;
      end;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowCurvature(Val:Boolean);
begin
   if Val<>FShowCurvature then begin
      FShowCurvature:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowGrid(Val:Boolean);
begin
   if Val<>FShowGrid then begin
      FShowGrid:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowMarkers(Val:Boolean);
var I : Integer;
begin
   if Val<>FShowMarkers then begin
      FShowMarkers:=val;
      Owner.FileChanged:=True;
      if Owner.NumberofMarkers>0 then
        for I:=1 to Owner.NumberOfViewports do
          if Owner.Viewport[I-1].Zoom=1.0 then Owner.Viewport[I-1].ZoomExtents
                                          else Owner.Viewport[I-1].Refresh;
   end;
end;

procedure TFreeVisibility.FSetShowNormals(Val:Boolean);
begin
   if Val<>FShowNormals then begin
      FShowNormals:=val;
      Owner.FileChanged:=True;
      if Owner.NumberOfSelectedControlFaces>0 then Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowStations(Val:Boolean);
begin
   if Val<>FShowStations then begin
      FShowStations:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowButtocks(Val:Boolean);
begin
   if Val<>FShowButtocks then begin
      FShowButtocks:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowDiagonals(Val:Boolean);
begin
   if Val<>FShowDiagonals then begin
      FShowDiagonals:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowFlowlines(Val:Boolean);
begin
   if Val<>FShowFlowlines then begin
      FShowFlowlines:=val;
      if not FShowFlowlines then Owner.FSelectedFlowlines.Clear;
      Owner.FileChanged:=True;
      if Owner.NumberOfFlowLines>0 then Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowWaterlines(Val:Boolean);
begin
   if Val<>FShowWaterlines then begin
      FShowWaterlines:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowControlCurves(Val:Boolean);
var I:Integer;
begin
   if val<>FShowControlCurves then begin
      FShowControlCurves:=Val;
      if not val then for I:=Owner.Surface.NumberOfControlCurves downto 1 do Owner.Surface.ControlCurve[I-1].Selected:=False;
      if Owner.Surface.NumberOfControlCurves>0 then Owner.Redraw;
      Owner.Filechanged:=true;
   end;
end;

procedure TFreeVisibility.FSetShowHydrostaticData(Val:Boolean);
begin
   if val<>FShowHydrostaticData then begin
      FShowHydrostaticData:=Val;
      Owner.Filechanged:=true;
      Owner.Redraw;
   end;
end;

constructor TFreeVisibility.Create(Owner:TFreeShip);
begin
   inherited Create;
   FOwner:=Owner;
   Clear;
end;

procedure TFreeVisibility.Clear;
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
   FCurvatureScale:=1.0;
   FCursorIncrement:=0.1;
   FShowHydrostaticData:=True;
   FShowHydrostDisplacement:=True;
   FShowHydrostLateralArea:=True;
   FShowHydrostSectionalAreas:=True;
   FShowHydrostMetacentricHeight:=True;
   FShowHydrostLCF:=True;
   FShowFlowlines:=True;
   if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(self);
end;

procedure TFreeVisibility.DecreaseCurvatureScale;
    begin CurvatureScale:=CurvatureScale/1.1; end;
procedure TFreeVisibility.IncreaseCurvatureScale;
    begin CurvatureScale:=CurvatureScale*1.1; end;

procedure TFreeVisibility.LoadBinary(Source:TFreeFilebuffer);
var I : Integer;
begin
   Clear;
   Source.LoadInteger(I);
   FModelView:=TFreeModelView(I);
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
   Source.LoadTFloatType(FCurvatureScale);
   if Owner.FileVersion>=fv195 then
   begin
      Source.LoadBoolean(FShowControlCurves);
      if Owner.FileVersion>=fv210 then
      begin
         Source.LoadTFloatType(FCursorIncrement);
         if abs(FCursorIncrement)<1e-5 then FCursorIncrement:=0.1;
         if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(self);
         if Owner.FileVersion>=fv220 then
         begin
            Source.LoadBoolean(FShowHydrostaticData);
            Source.LoadBoolean(FShowHydrostDisplacement);
            Source.LoadBoolean(FShowHydrostLateralArea);
            Source.LoadBoolean(FShowHydrostSectionalAreas);
            Source.LoadBoolean(FShowHydrostMetacentricHeight);
            Source.LoadBoolean(FShowHydrostLCF);
            if Owner.FileVersion>=fv250 then
            begin
               Source.LoadBoolean(FShowFlowlines);
            end;
         end;
      end;
   end;
end;{TFreeVisibility.LoadBinary}

procedure TFreeVisibility.SaveBinary(Destination:TFreeFileBuffer);
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
   Destination.Add(FCurvatureScale);
   if Owner.FileVersion>=fv195 then
   begin
      Destination.Add(FShowControlCurves);
      if Owner.FileVersion>=fv210 then
      begin
         Destination.Add(FCursorIncrement);
         if Owner.FileVersion>=fv220 then
         begin
            Destination.Add(FShowHydrostaticData);
            Destination.Add(FShowHydrostDisplacement);
            Destination.Add(FShowHydrostLateralArea);
            Destination.Add(FShowHydrostSectionalAreas);
            Destination.Add(FShowHydrostMetacentricHeight);
            Destination.Add(FShowHydrostLCF);
            if Owner.FileVersion>=fv250 then
            begin
               Destination.Add(FShowFlowlines);
            end;
         end;
      end;
   end;
end;{TFreeVisibility.SaveBinary}
{
  TFreeEdit
  Container class for all editing commandsns for the hull
}
constructor TFreeEdit.Create( Owner:TFreeShip );
begin inherited Create;
      Ship:=Owner;
      FRecentFiles:=TStringList.Create;
end;
function TFreeEdit.FGetRecentFile( Index:integer ):string;
   begin Result:=FRecentFiles[index]; end;
function TFreeEdit.FGetRecentFileCount:integer;
   begin Result:=FRecentFiles.Count; end;

// Takes a filename and adds it to the list with recent files
procedure TFreeEdit.AddToRecentFiles(Filename:String);
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
   while FRecentFiles.Count>10 do FRecentFiles.Delete(FRecentFiles.Count-1);
   if assigned(Ship.FOnUpdateRecentFileList) then Ship.FOnUpdateRecentFileList(self);
end;

// Delete the backgrundimage associated with this view
procedure TFreeEdit.BackgroundImage_Delete( Viewport:TFreeViewport );
var I:Integer;
begin
   if MessageDlg(Userstring(68),mtConfirmation,[mbYes,mbNo],0)=mrYes then begin
      for I:=Ship.NumberofBackgroundImages downto 1 do
      if Ship.BackgroundImage[I-1].AssignedView=Viewport.ViewType then begin
         Ship.BackgroundImage[I-1].Destroy;
         Ship.FBackgroundImages.Delete(I-1);
         Ship.FileChanged:=True;
         break;
      end;
      for I:=1 to Ship.NumberOfViewports do
      if Ship.Viewport[I-1].ViewType=Viewport.ViewType then begin
         Ship.Viewport[I-1].BackgroundImage.Clear;
         Ship.Viewport[I-1].Refresh;
      end;
   end;
end;

// browse for and open a backgroundimage
procedure TFreeEdit.BackgroundImage_Open(Viewport:TFreeViewport);
var I     : Integer;
    Data  : TFreebackgroundImagedata;
    Dialog: TOpenDialog;
    Pt    : TPoint;
    P2D   : T2DCoordinate;
    Bmp   : TBitmap;
begin
   Data:=nil;
   for I:=1 to Ship.NumberofBackgroundImages do
     if Ship.BackgroundImage[I-1].AssignedView=Viewport.ViewType
      then Data:=Ship.BackgroundImage[I-1];
   if Data<>nil then begin
      if MessageDlg( Userstring(69)+EOL+Userstring(70),
         mtConfirmation,[mbYes,mbNo],0 )=mrNo then exit;
   end;
   Dialog:=TOpenDialog.Create(Viewport);
   Dialog.InitialDir:=Ship.Preferences.ImportDirectory;
   Dialog.Filter:='All files (*.jpg;*.bmp)|*.jpg; *.bmp|Jpeg images (*.jpg)|*.jpg|Bitmap files (*.bmp)|*.bmp|';
   Dialog.Options:=[ofHideReadOnly];
   if Dialog.Execute then begin
      if Data=nil then begin
         Data:=TFreeBackgroundImageData.Create(Ship);
         Ship.FBackgroundImages.Add(Data);
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
         if Ship.NumberofBackgroundImages>1 then begin // use same scale as previous images
            Data.FScale:=Ship.BackgroundImage[Ship.NumberofBackgroundImages-2].FScale;
         end else begin                                      // calculate scale
            Pt:=Viewport.Project(ZERO);
            Pt.X:=Viewport.ClientWidth;
            P2D:=Viewport.ProjectBackTo2D(Pt);
            Data.FScale:=P2D.X/Data.FImageData.Width;
         end;
         Data.UpdateViews;
      end;
      Ship.FileChanged:=true;
   end;
   Dialog.Destroy;
end;

function TFreeEdit.CreateRedoObject:TFreeUndoObject;
var UndoObject: TFreeUndoObject;
    Version   : TFreeFileVersion;
    Preview   : Boolean;
begin
   UndoObject:=TFreeUndoObject.Create(Ship);
   Result:=UndoObject;
   UndoObject.FUndoText:=UserString(71);
   Version:=Ship.FileVersion;
   Preview:=Ship.ProjectSettings.SavePreview;
            // Temp. set to the latest fileversion so that no data will be lost
   Ship.FFileVersion:=Currentversion;  // Temp. disable saving of preview image
   Ship.ProjectSettings.SavePreview:=False;
   UndoObject.FFileChanged:=Ship.FileChanged;
   UndoObject.FFileName:=Ship.Filename;
   UndoObject.FEditMode:=Ship.EditMode;
   UndoObject.FFilenameSet:=Ship.FFilenameSet;
   UndoObject.FIsTempRedoObject:=True;
   Ship.SaveProject(UndoObject.FUndoData);   // <=> Ship.SaveBinary
   UndoObject.Accept;                       // Restore the original fileversion
   Ship.FileVersion:=Version;
   Ship.ProjectSettings.SavePreview:=Preview;
   if Assigned(Ship.FOnUpdateUndoData) then Ship.FOnUpdateUndoData(Ship);
end;

// Creates undodata just prior to modifications
function TFreeEdit.CreateUndoObject(UndoText:String;Accept:Boolean):TFreeUndoObject;
var UndoObject : TFreeUndoObject;
    Version    : TFreeFileVersion;
    Preview    : Boolean;
    I          : Integer;
begin
   UndoObject:=TFreeUndoObject.Create(Ship);
   Result:=UndoObject;
   //if UndoText<>'' then UndoText[1]:=Lowercase(UndoText[1]);
   UndoObject.FUndoText:=UndoText;
   Version:=Ship.FileVersion;
   Preview:=Ship.ProjectSettings.SavePreview;
// try
      // delete all undo objects after the current one
      for I:=Ship.FUndoObjects.Count downto Ship.FUndoPosition+1
          do Ship.UndoObject[I-1].Delete;
      // Temp. set to the latest fileversion so that no data will be lost
      Ship.FFileVersion:=Currentversion;
      // Temp. disable saving of preview image
      Ship.ProjectSettings.SavePreview:=False;
      UndoObject.FFileChanged:=Ship.FileChanged;
      UndoObject.FFileName:=Ship.Filename;
      UndoObject.FEditMode:=Ship.EditMode;
      UndoObject.FFilenameSet:=Ship.FFilenameSet;
      Ship.SaveProject(UndoObject.FUndoData);   // <##>SaveBinary
      if Accept then UndoObject.Accept;
// finally
      // Restore the original fileversion
      Ship.FileVersion:=Version;
      Ship.ProjectSettings.SavePreview:=Preview;
      if Assigned(Ship.FOnUpdateUndoData) then Ship.FOnUpdateUndoData(Ship);
// end;
end;

// Add (a) new controlcurve(s)
procedure TFreeEdit.Curve_Add;
var Edges,SortedEdges,Points: TFasterList;
    Edge: TFreeSubdivisionControlEdge;
    Point: TFreeSubdivisionPoint;
    Curve: TFreesubdivisionControlCurve;
    I,J: Integer;
begin
   Edges:=TFasterList.Create;
   Edges.Capacity:=Ship.NumberOfSelectedControlEdges;
   for I:=1 to Ship.NumberOfSelectedControlEdges do begin
      Edge:=Ship.SelectedControlEdge[I-1];
      if Edge.Curve=nil then Edges.Add(Edge);
   end;
   if Edges.Count>0 then begin
      Self.CreateUndoObject(Userstring(72),True);
      SortedEdges:=TFasterList.Create;
      Ship.Surface.IsolateEdges(Edges,SortedEdges);
      for I:=1 to SortedEdges.Count do begin
         Points:=SortedEdges[I-1];
         if Points.Count>1 then begin
            Curve:=TFreeSubdivisionControlCurve.Create(Ship.Surface);
            Ship.Surface.AddControlCurve(Curve);
            for J:=1 to Points.Count do begin
               Point:=Points[J-1];
               Curve.AddPoint(Point);
               if J>1 then begin
                  Edge:=Curve.Owner.EdgeExists(Curve.ControlPoint[J-2],Curve.ControlPoint[J-1]) as TFreeSubdivisionControlEdge;
                  if Edge<>nil then
                     Edge.Curve:=Curve;
               end;
            end;
         end;
         Points.Destroy;
      end;
      for I:=Ship.NumberOfSelectedControlEdges downto 1 do begin
         Edge:=Ship.SelectedControlEdge[I-1];
         Edge.Selected:=False;
      end;
      SortedEdges.Destroy;
      if Ship.Visibility.ShowControlCurves=false
         then Ship.Visibility.ShowControlCurves:=True
         else Ship.Redraw;
      Ship.FileChanged:=True;
      if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
   end;
   Edges.Destroy;
end;{TFreeEdit.Curve_Add}

destructor TFreeEdit.Destroy;
     begin FRecentFiles.Destroy; Inherited Destroy; end;

// Remove an edge by replacing the two connected faces by one controlface
procedure TFreeEdit.Edge_Collapse;
var I,N: integer;
    Edge: TFreeSubdivisionControlEdge;
    Undo: TFreeUndoObject;
begin
   N:=0;
   Undo:=CreateUndoObject(Userstring(73),False);
   For I:=Ship.NumberOfSelectedControlEdges downto 1 do begin
      Edge:=Ship.SelectedControlEdge[I-1];
      if Edge.NumberOfFaces>1 then begin
         Edge.Collapse;
         inc(N);
      end;
   end;
   if N>0 then begin
      Undo.Accept;
      Ship.Build:=false;
      Ship.Redraw;
      Ship.FileChanged:=True;
      if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;

// Create a new edge by connection two controlpoints belonging to the same controlface
procedure TFreeEdit.Edge_Connect;
var Undo: TFreeUndoObject; N: integer;
begin
   N:=Ship.Surface.NumberOfControlEdges;
   Undo:=CreateUndoObject(Userstring(74),False);
   Ship.Surface.Edge_Connect;
   if Ship.Surface.NumberOfControlEdges>N then begin
      Undo.Accept;
      Ship.FileChanged:=True;
      Ship.Build:=false;
      Ship.Redraw;
      if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;

// Switch selected edges between normal or crease edges (knuckle lines)
procedure TFreeEdit.Edge_Crease;
var I    : integer;
begin
   CreateUndoObject(Userstring(75),True);
   for I:=Ship.NumberOfSelectedControlEdges downto 1 do Ship.SelectedControlEdge[I-1].Crease:=not Ship.SelectedControlEdge[I-1].Crease;
   Ship.Build:=False;
   Ship.Redraw;
   Ship.FileChanged:=True;
end;

// Create new controlfaces by extruding selected boundary edges (eg edges with only 1 controlface connected to it)
procedure TFreeEdit.Edge_Extrude;
var Dialog  : TFreeExtrudeDialog;
    Edge    : TFreeSubdivisionControledge;
    Vector  : T3DVector;
    Edges   : TFasterList;
    I       : integer;
    Str     : string;
    Undo    : TFreeUndoObject;
begin
   Dialog:=TFreeExtrudeDialog.Create(Ship);
   ShowTranslatedValues(Dialog);
   Dialog.XValue:=0.0;
   Dialog.YValue:=0.0;
   Dialog.ZValue:=0.0;
   Str:=LengthStr(Ship.ProjectSettings.ProjectUnits);
   if Dialog.Execute(Str) then
   begin
      Undo:=CreateUndoObject(Userstring(76),False);
      Vector.X:=Dialog.XValue;
      Vector.Y:=Dialog.YValue;
      Vector.Z:=Dialog.ZValue;
      // Assemble edges in a list
      Edges:=TFasterList.Create;
      for I:=Ship.NumberOfSelectedControlEdges downto 1 do begin
         Edge:=Ship.Surface.SelectedControlEdge[I-1]; // only boundary edges are allowed!!
         if Edge.NumberOfFaces=1 then Edges.Add(Edge);
         Edge.Selected:=False;
      end;
      if Edges.Count>0 then begin
         Ship.Surface.ExtrudeEdges(Edges,Vector); // New edges are returned in the edges-list, select them
         for I:=1 to Edges.Count do begin
            Edge:=Edges[I-1];
            Edge.Selected:=True;
         end;
         Undo.Accept;
         Ship.Build:=False;
         Ship.FileChanged:=true;
         Ship.Redraw;
         if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
      end else begin
         ShowMessage( Userstring(77) ); Undo.Delete;
      end;
      Edges.Destroy;
   end;
   Dialog.Destroy;
end;

// Create new controlpoints by splitting an controledge into two.
procedure TFreeEdit.Edge_Split;
var I,N  : integer;
    Edge : TFreeSubdivisionControlEdge;
    Point: TFreeSubdivisionControlPoint;
    Last : TFreeSubdivisionControlPoint;
    Undo : TFreeUndoObject;
begin
   N:=0;
   Last:=nil;
   Undo:=CreateUndoObject(Userstring(78),false);
   for I:=Ship.NumberOfSelectedControlEdges downto 1 do begin
      Edge:=Ship.Surface.SelectedControlEdge[I-1];
      Edge.Selected:=False;
      Point:=Edge.InsertControlPoint(MidPoint(Edge.StartPoint.Coordinate,Edge.EndPoint.Coordinate));
      if Point<>nil then begin
         Point.Selected:=True;
         Last:=Point;
         inc(N);
      end;
   end;
   if Last<>nil then Ship.ActiveControlPoint:=Last;
   if N>0 then begin
      Undo.Accept;
      Ship.Build:=False;
      Ship.FileChanged:=True;
      Ship.Redraw;
      if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;

procedure TFreeEdit.Face_Assemble;
var Assembled        : TFreeFaceArray;
    NAssembled       : Integer;
    Layers           : TFasterList;
    I,J,K            : Integer;
    AssFace          : TFreeFaceGrid;
    Layer            : TFreeSubdivisionLayer;
    Face             : TFreeSubdivisionControlFace;
begin
   Layers:=TFasterList.Create;
   for I:=1 to Ship.Surface.NumberOfLayers do begin
      Layers.Add(Ship.Surface.Layer[I-1]);
   end;
   Ship.Visibility.ShowInteriorEdges:=True;
   Ship.Surface.AssembleFacesToPatches(Layers,amNurbs,Assembled,NAssembled);
   if NAssembled>0 then begin               // assign all patches to new layers
      for I:=1 to NAssembled do begin
         Layer:=Ship.Surface.AddNewLayer;
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
      Ship.Redraw;
      Showmessage('Assembled '+IntToStr(NAssembled)+' patches');
   end;
   Layers.Destroy;
end;

// Deletes all faces on the starboardside of the hull
procedure TFreeEdit.Face_DeleteNegative;
var IsNegative: Boolean;
    I,J,RemovedF,RemovedP: Integer;
    Face      : TFreeSubdivisionControlFace;
    Point     : TFreeSubdivisionControlPoint;
    PrevCursor: TCursor;
    Undo      : TFreeUndoObject;
    Str       : String;
begin
   RemovedF:=0;
   RemovedP:=0;
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourglass;
   Undo:=CreateUndoObject(Userstring(79),false);
// try
      for I:=Ship.Surface.NumberOfControlFaces downto 1 do begin
         Face:=Ship.Surface.ControlFace[I-1];
         if face.NumberOfpoints>2 then begin
            IsNegative:=True;
            for J:=1 to Face.NumberOfpoints do if Face.Point[J-1].Coordinate.Y>1e-5 then IsNegative:=False;
         end else IsNegative:=True;
         if IsNegative then begin
            Face.Delete;
            inc(RemovedF);
         end;
      end;
      for I:=Ship.Surface.NumberOfControlPoints downto 1 do begin
         Point:=Ship.Surface.ControlPoint[I-1];
         if (Point.NumberOfFaces=0) and (Point.Coordinate.Y<-1e-4) then begin
            Point.Delete;
            inc(RemovedP);
         end;
      end;
      if (RemovedF+RemovedP)>0 then begin
         Str:='';
         if RemovedF>0 then Str:=Str+IntToStr(RemovedF)+#32+Userstring(80);
         if RemovedP>0 then begin
            if Str<>'' then Str:=Str+EOL;
            Str:=Str+IntToStr(RemovedP)+#32+Userstring(81);
         end;
         MessageDlg(Str,mtInformation,[mbOk],0);
         Undo.Accept;
         Ship.FileChanged:=True;
         Ship.Build:=False;
         Ship.Redraw;
         if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
      end else begin
         ShowMessage( Userstring(82) );
         Undo.Delete;
      end;
// finally
      Screen.Cursor:=PrevCursor;
// end;
end;{TFreeEdit.Face_DeleteNegative}

// Inverts the normal-direction of all selected controlfaces
procedure TFreeEdit.Face_Flip;
var I:integer;
begin
   CreateUndoObject(Userstring(83),true);
   for I:=1 to Ship.NumberOfSelectedControlFaces do Ship.SelectedControlFace[I-1].FlipNormal;
   Ship.Build:=False;
   Ship.FileChanged:=True;
   Ship.Redraw;
end;{TFreeEdit.Face_Flip}

// Mirrors all selected faces in a 3D plane
procedure TFreeEdit.Face_MirrorPlane;
var I,J,Index     : Integer;
    Vertices,Points,Faces: TFasterList;
    MirrorPlane   : T3DPlane;
    Face,NewFace  : TFreeSubdivisionControlface;
    P1,P2         : TFreeSubdivisionControlPoint;
    Edge1,Edge2   : TFreeSubdivisionEdge;
    PrevCursor    : TCursor;
    Dialog        : TFreeMirrorPlaneDialog;
    SelectDlg     : TFreeSelectLayersDialog;
begin
   Faces:=TFasterList.Create;
   if Ship.NumberOfSelectedControlFaces=0 then begin
      SelectDlg:=TFreeSelectLayersDialog.Create(Ship);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(Ship,fsFaces)
      then SelectDlg.ExtractSelectedFaces(Faces)
      else begin
         for I:=Ship.NumberOfSelectedControlFaces downto 1 do
                Ship.SelectedControlFace[I-1].Selected:=false;
         Ship.Redraw;
      end;
      SelectDlg.Destroy;
   end else begin
      Faces.Capacity:=Faces.Count+Ship.NumberOfSelectedControlFaces;
      for I:=1 to Ship.NumberOfSelectedControlFaces do Faces.Add(Ship.SelectedControlFace[I-1]);
   end;
   if Faces.Count>0 then begin
      Dialog:=TFreeMirrorPlaneDialog.Create(Ship);
      ShowTranslatedValues(Dialog);
      if Dialog.Execute then begin
         Mirrorplane:=Dialog.Plane;
         CreateUndoObject(Userstring(84),True);
         PrevCursor:=Screen.Cursor;
         Screen.Cursor:=crHourglass;
//       try
            // assemble all points
            Vertices:=TFasterlist.Create;
            Vertices.Capacity:=4*Faces.Count;
            for I:=1 to Faces.Count do begin
               Face:=Faces[I-1];
               for J:=1 to Face.NumberOfpoints do begin
                  P1:=Face.Point[J-1] as TFreeSubdivisionControlPoint;
                  if Vertices.SortedIndexOf(P1)=-1 then Vertices.AddSorted(P1);
               end;
            end;
            // Create all the mirrored control points
            for I:=1 to Vertices.Count do begin
               P1:=Vertices[I-1];
               if not Dialog.CheckBox1.Checked then  begin
                  // Do NOT try to connect the points to any existing point create always a new point
                  P2:=TFreeSubdivisionControlPoint.Create(P1.Owner);
                  P1.Owner.AddControlPoint(P2);
                  P2.Coordinate:=FreeGeometry.MirrorPlane(P1.Coordinate,MirrorPlane);
               end else begin
                  // Try to connect ALL new points to existing ones
                  P2:=P1.Owner.AddControlPoint(FreeGeometry.MirrorPlane(P1.Coordinate,MirrorPlane));
               end;
               Vertices.Objects[I-1]:=P2;
            end;
            // now create the controlfaces
            Points:=TFasterList.Create;
            for I:=1 to Faces.Count do begin
               Face:=Faces[I-1];
               Points.Clear;
               Points.Capacity:=Face.NumberOfpoints;
               for J:=Face.NumberOfpoints downto 1 do begin
                  P1:=Face.Point[J-1] as TFreeSubdivisionControlPoint;
                  Index:=Vertices.SortedIndexOf(P1);
                  if Index<>-1 then begin
                     P2:=Vertices.Objects[index];
                     Index:=Points.IndexOf(P2);
                     if Index=-1 then Points.Add(P2);
                  end else Raise Exception.Create(Userstring(85));
               end;
               if Points.Count>2 then begin
                  NewFace:=Face.Owner.AddControlFace(Points,False);
                  if Newface<>nil then NewFace.Layer:=Face.Layer;
               end;
            end;
            Points.Destroy;             // Now check all edges for crease edges
            for I:=1 to Vertices.Count do begin
               P1:=Vertices[I-1];
               for J:=1 to P1.NumberOfEdges do begin
                  Edge1:=P1.Edge[J-1];
                  if Edge1.StartPoint=P1
                     then P2:=Edge1.EndPoint as TFreeSubdivisionControlPoint
                     else P2:=Edge1.StartPoint as TFreeSubdivisionControlPoint;
                  Index:=Vertices.SortedIndexOf(P2);
                  if Index<>-1 then begin // Edge is part of the selected faces
                     Edge2:=Ship.Surface.EdgeExists(Vertices.Objects[I-1],Vertices.Objects[index]);
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
            for I:=Ship.NumberOfSelectedControlFaces downto 1 do Ship.SelectedControlFace[I-1].Selected:=False;
//       finally
            Ship.Build:=False;
            Ship.Draw;
            if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
            Screen.Cursor:=PrevCursor;
//       end;
      end;
      Dialog.Destroy;
   end;
   Faces.Destroy;
end;{TFreeEdit.Face_MirrorPlane}

procedure TFreeEdit.Face_Rotate;
var I,J,Nlocked: Integer;
    Points     : TFasterList;
    PrevCursor : TCursor;
    SelectDlg  : TFreeSelectLayersDialog;
    Point      : TFreeSubdivisionControlPoint;
    Proceed    : Boolean;
    Dialog     : TFreeRotateDialog;
    SinX,CosX, SinY,CosY, SinZ,CosZ: TFloatType;
    Marker     : TFreeMarker;
begin
   Points:=TFasterList.Create;
   if Ship.ActiveControlPoint<>nil then Points.Add(Ship.ActiveControlPoint);
   Ship.Surface.ExtractPointsFromSelection(Points,NLocked);
   if Points.Count=0 then begin
      SelectDlg:=TFreeSelectLayersDialog.Create(Ship);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(Ship,fsPoints)
      then SelectDlg.ExtractSelectedPoints(Points)
      else begin
         for I:=Ship.NumberOfSelectedControlPoints downto 1
          do Ship.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Ship.NumberOfViewports do Ship.Viewport[I-1].Refresh;
      end;
      SelectDlg.Destroy;
   end;
   if Points.Count>0 then begin
      if NLocked>0 then begin
         Proceed:=MessageDlg(Userstring(86)+EOL+
                             Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
      end else Proceed:=True;
      if Proceed then begin
         Dialog:=TFreeRotateDialog.Create(Ship);
         ShowTranslatedValues(Dialog);
         Dialog.XValue:=0.0;
         Dialog.YValue:=0.0;
         Dialog.ZValue:=0.0;
         if Dialog.Execute(Userstring(88),'[Degr.]') then begin
            CreateUndoObject(Userstring(89),true);
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourGlass;
//          try
               CosX:=Cos(DegToRad(Dialog.XValue));
               SinX:=Sin(DegToRad(Dialog.XValue));
               CosY:=Cos(DegToRad(Dialog.YValue));
               SinY:=Sin(DegToRad(Dialog.YValue));
               CosZ:=Cos(DegToRad(Dialog.ZValue));
               SinZ:=Sin(DegToRad(Dialog.ZValue));
               for I:=1 to Points.Count do begin
                  Point:=Points[I-1];
                  if not Point.Locked then begin
                     Point.Coordinate:=RotateVector(Point.Coordinate,SinX,CosX,SinY,CosY,SinZ,CosZ);
                  end;
               end;
               if Points.Count=Ship.Surface.NumberOfControlPoints
               then if Ship.AdjustMarkers then begin
                  for I:=1 to Ship.NumberofMarkers do begin
                     Marker:=Ship.Marker[I-1];
                     for J:=1 to Marker.NumberOfPoints
                      do Marker.Point[J-1]:=RotateVector(Marker.Point[J-1],SinX,CosX,SinY,CosY,SinZ,CosZ);
                  end;
               end;
               Ship.Build:=False;
               Ship.Redraw;
//          finally
               // Refresh controlpoint data
               if Points.SortedIndexOf(Ship.ActiveControlPoint)<>-1 then Ship.ActiveControlPoint:=Ship.ActiveControlPoint;
               Screen.Cursor:=PrevCursor;
//          end;
         end else begin
            for I:=Ship.NumberOfSelectedControlPoints downto 1 do Ship.SelectedControlPoint[I-1].Selected:=false;
            for I:=1 to Ship.NumberOfViewports do Ship.Viewport[I-1].Refresh;
         end;
         Dialog.Destroy;
      end else begin
         for I:=Ship.NumberOfSelectedControlPoints downto 1
          do Ship.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Ship.NumberOfViewports do Ship.Viewport[I-1].Refresh;
      end;
   end;
   Points.Destroy;
end;

procedure TFreeEdit.Face_Scale;
var I,Nlocked : Integer;
    Points    : TFasterList;
    PrevCursor: TCursor;
    SelectDlg : TFreeSelectLayersDialog;
    Point     : TFreeSubdivisionControlPoint;
    Proceed   : Boolean;
    Dialog    : TFreeRotateDialog;
    Scale,NewP: T3DVector;
    Markers   : Boolean;
begin
   Points:=TFasterList.Create;
   if Ship.ActiveControlPoint<>nil then Points.Add(Ship.ActiveControlPoint);
   Ship.Surface.ExtractPointsFromSelection(Points,NLocked);
   if Points.Count=0 then begin
      SelectDlg:=TFreeSelectLayersDialog.Create(Ship);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(Ship,fsPoints)
      then SelectDlg.ExtractSelectedPoints(Points)
      else begin
         for I:=Ship.NumberOfSelectedControlPoints downto 1
          do Ship.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Ship.NumberOfViewports do Ship.Viewport[I-1].Refresh;
      end;
      SelectDlg.Destroy;
   end;
   if Points.Count>0 then begin
      if NLocked>0 then begin
         Proceed:=MessageDlg(Userstring(86)+EOL+
                             Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
      end else Proceed:=True;
      if Proceed then begin
         Dialog:=TFreeRotateDialog.Create(Ship);
         ShowTranslatedValues(Dialog);
         Dialog.XValue:=1.0;
         Dialog.YValue:=1.0;
         Dialog.ZValue:=1.0;
         if Dialog.Execute(Userstring(90),'') then begin
            CreateUndoObject(Userstring(91),true);
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourGlass;
//          try
               Scale.X:=Dialog.XValue;
               Scale.Y:=Dialog.YValue;
               Scale.Z:=Dialog.ZValue;
               if Points.Count=Ship.Surface.NumberOfControlPoints then begin // Scale the entire model
                  Markers:=Ship.AdjustMarkers;
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
                  Ship.Build:=False;
                  Ship.Redraw;
               end;
//          finally
               // Refresh controlpoint data
               if Points.SortedIndexOf(Ship.ActiveControlPoint)<>-1 then Ship.ActiveControlPoint:=Ship.ActiveControlPoint;
               Screen.Cursor:=PrevCursor;
//          end;
         end else begin
            for I:=Ship.NumberOfSelectedControlPoints downto 1 do Ship.SelectedControlPoint[I-1].Selected:=false;
            for I:=1 to Ship.NumberOfViewports do Ship.Viewport[I-1].Refresh;
         end;
         Dialog.Destroy;
      end else begin
         for I:=Ship.NumberOfSelectedControlPoints downto 1 do Ship.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Ship.NumberOfViewports do Ship.Viewport[I-1].Refresh;
      end;
   end;
   Points.Destroy;
end;{TFreeEdit.Face_Scale}

procedure TFreeEdit.Face_Move;
var I,J,Nlocked: Integer;
    Points     : TFasterList;
    PrevCursor : TCursor;
    SelectDlg  : TFreeSelectLayersDialog;
    Point      : TFreeSubdivisionControlPoint;
    Proceed    : Boolean;
    Dialog     : TFreeRotateDialog;
    P,Translate: T3DVector;
    Marker     : TFreeMarker;
begin
   Points:=TFasterList.Create;
   if Ship.ActiveControlPoint<>nil then Points.Add(Ship.ActiveControlPoint);
   Ship.Surface.ExtractPointsFromSelection(Points,NLocked);
   if Points.Count=0 then begin
      SelectDlg:=TFreeSelectLayersDialog.Create(Ship);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(Ship,fsPoints)
      then SelectDlg.ExtractSelectedPoints(Points)
      else begin
         for I:=Ship.NumberOfSelectedControlPoints downto 1 do Ship.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Ship.NumberOfViewports do Ship.Viewport[I-1].Refresh;
      end;
      SelectDlg.Destroy;
   end;
   if Points.Count>0 then begin
      if NLocked>0 then begin
         Proceed:=MessageDlg(Userstring(86)+EOL+
                             Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
      end else Proceed:=True;
      if Proceed then begin
         Dialog:=TFreeRotateDialog.Create(Ship);
         ShowTranslatedValues(Dialog);
         Dialog.XValue:=0.0;
         Dialog.YValue:=0.0;
         Dialog.ZValue:=0.0;
         if Dialog.Execute(Userstring(92),LengthStr(Ship.ProjectSettings.ProjectUnits))
         then begin
            CreateUndoObject(Userstring(93),true);
            Translate.X:=Dialog.XValue;
            Translate.Y:=Dialog.YValue;
            Translate.Z:=Dialog.ZValue;
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourGlass;
//          try
               for I:=1 to Points.Count do begin
                  Point:=Points[I-1];
                  if not Point.Locked then begin
                     P:=Point.Coordinate;
                     P.X:=P.X+Translate.X;
                     P.Y:=P.Y+Translate.Y;
                     P.Z:=P.Z+Translate.Z;
                     Point.Coordinate:=P;
                  end;
               end;
               if Points.Count=Ship.Surface.NumberOfControlPoints then begin
                  // Update main dimensions
                  if not Ship.ProjectSettings.UseMidleFrame then
                     Ship.ProjectSettings.MidleFrame:=Ship.ProjectSettings.MidleFrame+Translate.X;
                  // Update stations, buttcks and waterlines
                  for I:=1 to Ship.NumberofStations do Ship.Station[I-1].FPlane.d:=Ship.Station[I-1].FPlane.d-Translate.X;
                  for I:=1 to Ship.NumberofButtocks do Ship.Buttock[I-1].FPlane.d:=Ship.Buttock[I-1].FPlane.d-Translate.Y;
                  for I:=1 to Ship.NumberofWaterlines do Ship.Waterline[I-1].FPlane.d:=Ship.Waterline[I-1].FPlane.d-Translate.Z;
                  // Update markers
                  if Ship.AdjustMarkers then for I:=1 to Ship.NumberofMarkers
                  do begin
                     Marker:=Ship.Marker[I-1];
                     for J:=1 to Marker.NumberOfPoints do begin
                        P:=Marker.Point[J-1];
                        P.X:=P.X+Translate.X;
                        P.Y:=P.Y+Translate.Y;
                        P.Z:=P.Z+Translate.Z;
                        Marker.Point[J-1]:=P;
                     end;
                  end;
               end;
               Ship.Build:=False;
               Ship.Redraw;
//          finally
               // Refresh controlpoint data
               if Points.SortedIndexOf(Ship.ActiveControlPoint)<>-1 then Ship.ActiveControlPoint:=Ship.ActiveControlPoint;
               Screen.Cursor:=PrevCursor;
//          end;
         end else begin
            for I:=Ship.NumberOfSelectedControlPoints downto 1 do Ship.SelectedControlPoint[I-1].Selected:=false;
            for I:=1 to Ship.NumberOfViewports do Ship.Viewport[I-1].Refresh;
         end;
         Dialog.Destroy;
      end else begin
         for I:=Ship.NumberOfSelectedControlPoints downto 1
          do Ship.SelectedControlPoint[I-1].Selected:=false;
         for I:=1 to Ship.NumberOfViewports do Ship.Viewport[I-1].Refresh;
      end;
   end;
   Points.Destroy;
end;

// Creates a new controlface from the currently selected controlpoints
procedure TFreeEdit.Face_New;
var Tmp : TFasterList;
    Face: TFreeSubdivisionControlFace;
    I   : integer;
    Undo: TFreeUndoObject;
begin
   if Ship.NumberOfSelectedControlPoints>2 then begin
      Tmp:=TFasterList.Create;
      Undo:=CreateUndoObject(Userstring(94),false);
      // Remember the number of faces, edges and points
      // Assemble all points in a temp. list
      for I:=1 to Ship.Surface.NumberOfSelectedControlPoints do Tmp.Add(Ship.Surface.SelectedControlPoint[I-1]);
      // Deselect the controlpoints
      for I:=Ship.Surface.NumberOfSelectedControlPoints downto 1 do Ship.Surface.SelectedControlPoint[I-1].Selected:=False;
      // Add the new face
      Face:=Ship.Surface.AddControlFace(Tmp,True,Ship.ActiveLayer);
      if Face<>nil then begin
         Undo.Accept;
         Ship.Build:=False;
         Ship.FileChanged:=True;
         Ship.Redraw;
         if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
      end else Undo.Delete;
      // Initialize then new edges and faces
      Tmp.Destroy;
   end else MessageDlg(Userstring(95),mtInformation,[mbOk],0);
end;{TFreeEdit.Face_New}

procedure TFreeEdit.Flowline_Add(Source:T2DCoordinate;View:TFreeviewType);
var Flowline : TFreeFlowline;
    Undo     : TFreeUndoObject;
begin
   Undo:=CreateUndoObject(Userstring(130),False);
   Flowline:=TFreeflowline.Create(Ship);
   Ship.FFlowLines.Add(Flowline);
   Flowline.FProjectionPoint:=Source;
   Flowline.FProjectionView:=View;
//   Flowline.FMethodNew:=True;
   Flowline.Rebuild;
   if Flowline.FFlowLine.NumberOfPoints>0 then begin
      Ship.FileChanged:=True;
      Undo.Accept;
      Ship.Redraw;
   end else
   begin
      Undo.Delete;
      Flowline.Delete;
   end;
end;{TFreeEdit.Flowline_Add}

procedure TFreeEdit.Geometry_AddCylinder;
var StartPoint,EndPoint,P1,P2: T3DVector;
    I,NPoints,Ne  : Integer;
    Points        : TFreeCoordinateGrid;
    Radius        : TFloatType;
    Angle         : TFloatType;
    Matrix        : TFreeMatrix;
    Inv,OrgPts    : TFreeMatrix;
    NewPts        : TFreeMatrix;
    Dialog        : TFreeCylinderDialog;
    NewLayer      : TFreeSubdivisionLayer;
begin
   Dialog:=TFreeCylinderDialog.Create(Ship);
   ShowTranslatedValues(Dialog);
   Dialog.StartPoint:=Vector(0.0,0.0,0.0);
   Dialog.EndPoint:=Vector(0.0,1.0,0.0);
   Dialog.Input7.Value:=1.0;
   Dialog.Input8.Value:=Dialog.Input8.Min+2;

   if Dialog.Execute(LengthStr(Ship.ProjectSettings.ProjectUnits)) then
   begin
      CreateUndoObject(Userstring(131),True);
      NewLayer:=Ship.Surface.AddNewLayer;
      StartPoint:=Dialog.StartPoint;
      EndPoint:=Dialog.EndPoint;
      Radius:=Dialog.Input7.Value;
      NPoints:=Dialog.Input8.AsInteger;
      Setlength(Points,2);
      setlength(Points[0],NPoints+1);
      setlength(Points[1],NPoints+1);

      // Prepare matrices
      Matrix:=TFreeMatrix.Create;
      Matrix.SetSize(NPoints+4,NPoints+4);
      Matrix.Fill(0.0);
      Matrix.Value[0,0]:=1.0;
      for I:=2 to NPoints+3 do
      begin
         Matrix.Value[I-1,I-2]:=1/6;
         Matrix.Value[I-1,I-1]:=2/3;
         Matrix.Value[I-1,I  ]:=1/6;
      end;
      Matrix.Value[NPoints+3,NPoints+3]:=1.0;
      // Invert matrix
      Inv:=Matrix.Invert;
      Matrix.Destroy;

      OrgPts:=TFreeMatrix.Create;
      OrgPts.SetSize(3,NPoints+4);
      for I:=1 to NPoints do
      begin
         Angle:=-((I-1)/NPoints)*2*Pi;
         P1.x:=StartPoint.x+Sin(Angle)*Radius;
         P1.y:=StartPoint.y+Cos(Angle)*Radius;
         P1.z:=StartPoint.z;
         P2:=RotatePointAroundVector(P1,StartPoint,EndPoint-StartPoint);
         OrgPts.Value[I+1,0]:=P2.X;
         OrgPts.Value[I+1,1]:=P2.Y;
         OrgPts.Value[I+1,2]:=P2.Z;
      end;
      for I:=0 to 2 do
      begin
         OrgPts.Value[1,I]:=OrgPts.Value[NPoints+1,I];
         OrgPts.Value[0,I]:=OrgPts.Value[NPoints,I];
         OrgPts.Value[NPoints+2,I]:=OrgPts.Value[2,I];
         OrgPts.Value[NPoints+3,I]:=OrgPts.Value[3,I];
      end;
      // calculate new points
      NewPts:=Inv.Multiply(OrgPts);
      for I:=1 to NPoints do
      begin
         P1.X:=NewPts.Value[I+1,0];
         P1.Y:=NewPts.Value[I+1,1];
         P1.Z:=NewPts.Value[I+1,2];
         Points[0][I-1]:=P1;
         Points[1][I-1]:=Vector(P1.X+EndPoint.X-StartPoint.X,P1.Y+EndPoint.Y-StartPoint.Y,P1.Z+EndPoint.Z-StartPoint.Z);
      end;
      Points[0][NPoints]:=Points[0][0];
      Points[1][NPoints]:=Points[1][0];
      Inv.Destroy;
      OrgPts.Destroy;
      NewPts.Destroy;
      Ne:=Ship.Surface.NumberOfControlEdges;
      Ship.Surface.ImportGrid(Points,NPoints+1,2,NewLayer);
      for I:=Ne+1 to Ship.Surface.NumberOfControlEdges do Ship.Surface.ControlEdge[I-1].Crease:=False;
      Ship.Redraw;
   end;
   Dialog.Destroy;
end;{TFreeEdit.Geometry_AddCylinder}

procedure TFreeEdit.Intersection_AddToList(Intersection:TFreeIntersection);
var I,J        : integer;
    TargetList : TFasterList;
    Int1,Int2  : TFreeIntersection;
begin
   Case Intersection.IntersectionType of
      fiStation    : TargetList:=Ship.FStations;
      fiButtock    : TargetList:=Ship.FButtocks;
      fiWaterline  : TargetList:=Ship.FWaterlines;
      fiDiagonal   : TargetList:=Ship.FDiagonals;
      else TargetList:=nil;
   end;
   if TargetList<>nil then
   begin
      TargetList.Add(Intersection);
      // Now sort the list so that the distance is in ascending order
      for I:=1 to TargetList.Count-1 do
      begin
         Int1:=TargetList[I-1];
         for J:=I+1 to TargetList.Count do
         begin
            Int2:=Targetlist[J-1];
            if -Int2.FPlane.d<-Int1.FPlane.d then
            begin
               // swap the two intersections
               Targetlist.Exchange(I-1,J-1);
               Int1:=TargetList[I-1];
            end;
         end;
      end;
   end;
end;{TFreeEdit.Intersection_AddToList}

// Pops up the dialog in which to add or delete stations, buttocks and waterlines
procedure TFreeEdit.Intersection_Dialog;
var Dialog: TFreeIntersectionDialog;
begin
  Dialog:=Ship.FIntersectionDialog as TFreeIntersectionDialog;
  ShowTranslatedValues(Dialog);
  Dialog.Execute(Ship);
  Ship.FDesignHydrostatics.Calculated:=false;
  if Ship.Visibility.ShowHydrostaticData then Ship.Redraw;
end;{TFreeEdit.Intersection_Dialog}

// All connected patches surrounded by crease edges are grouped together into a new layer
procedure TFreeEdit.Layer_AutoGroup;
var ToDoList   : TList;
    DoneList   : TList;
    Current    : TList;
    I,J        : integer;
    Face,Face2 : TFreeSubdivisionControlFace;
    Layer      : TFreeSubdivisionLayer;
    SameLayer  : Boolean;

    procedure FindAttachedFaces(List:TList;Face:TFreeSubdivisionControlFace);
    var I,J    : integer;
        Index  : integer;
        P1,P2  : TFreeSubdivisionPoint;
        Edge   : TFreeSubdivisionEdge;
    begin
       P1:=Face.Point[Face.NumberOfPoints-1];
       for I:=1 to Face.NumberOfpoints do
       begin
          P2:=Face.Point[I-1];
          Edge:=Face.Owner.EdgeExists(P1,P2);
          if Edge<>nil then
          begin
             if not Edge.Crease then
             begin
                for J:=1 to Edge.NumberOfFaces do if Edge.Face[J-1]<>Face then
                begin
                   Index:=ToDoList.IndexOf(Edge.Face[J-1]);
                   if Index<>-1 then
                   begin
                      List.Add(Edge.Face[J-1]);
                      ToDoList.Delete(Index);
                      FindAttachedFaces(List,Edge.Face[J-1] as TFreeSubdivisionControlFace);
                   end;
                end;
             end;
          end;
          P1:=p2;
       end;
    end;{FindAttachedFaces}

begin
   ToDoList:=TList.Create;
   DoneList:=TList.Create;
// try
      if Ship.NumberOfSelectedControlFaces>0 then begin // Use only the selected ones
         ToDoList.Capacity:=ToDoList.Count+Ship.NumberOfSelectedControlFaces;
         for I:=1 to Ship.NumberOfSelectedControlFaces do begin
            Face:=Ship.SelectedControlFace[I-1];
            ToDoList.Add(Face);
         end;
      end else begin                                   // use all visible faces
         for I:=1 to Ship.NumberOfLayers do begin
            Layer:=Ship.Layer[I-1];
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
         end;                          // Assign all groups to different layers
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
               if SameLayer then begin // yes, all faces belong to the same layer
                  if Current.Count=Face.Layer.Count then begin
                     // apparently the same data is selected as in face.layer, do not change layer
                  end else begin
                     // a subset of face.layer is selected, copy properties from that layer
                     Layer:=Ship.Surface.AddNewLayer;
                     Layer.AssignProperties(Face.Layer);
                  end;
               end else begin                // Faces belong to multiple layers,
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
         Ship.ActiveLayer:=Ship.Layer[Ship.NumberOfLayers-1];
         // Delete empty layers
         Layer_DeleteEmpty(True);
         Ship.Redraw;
         Ship.FileChanged:=True;
      end;
// finally
      if assigned(Ship.OnChangeLayerData) then Ship.OnChangeLayerData(self);
      ToDoList.Destroy;
      DoneList.Destroy;
// end;
end;{TFreeEdit.Layer_AutoGroup}

// Develope all developable layers
procedure TFreeEdit.Layer_Develop;
var Layer   : TFreeSubdivisionLayer;
    Patch   : TFreeDevelopedPatch;
    Dlg     : TFreeExpanedplatesDialog;
    Plates  : TFasterList;
    I,J     : integer;
    Prev    : TCursor;
begin
   Prev:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   Plates:=TFasterList.Create;
// try
      // perform a quiet test to check normal directions
      if not Ship.ProjectSettings.DisableModelCheck then Model_Check(False);
      for I:=1 to Ship.NumberOfLayers do
      begin
         Layer:=Ship.Layer[I-1];
         if Layer.Developable then
         begin
            Layer.Unroll(Plates);
         end;
      end;
      for I:=1 to Plates.Count do
      begin
         Patch:=Plates[I-1];
         for J:=1 to Ship.NumberofStations do Patch.IntersectPlane(Ship.Station[J-1].Plane,Ship.Station[J-1].Color);
         for J:=1 to Ship.NumberofWaterlines do Patch.IntersectPlane(Ship.Waterline[J-1].Plane,Ship.Waterline[J-1].Color);
         for J:=1 to Ship.NumberofButtocks do Patch.IntersectPlane(Ship.Buttock[J-1].Plane,Ship.Buttock[J-1].Color);
         for J:=1 to Ship.NumberofDiagonals do Patch.IntersectPlane(Ship.Diagonal[J-1].Plane,Ship.Diagonal[J-1].Color);
      end;
// finally
      Screen.Cursor:=Prev;
// end;
   if Plates.Count>0 then begin
      Dlg:=TFreeExpanedplatesDialog.Create(Ship);
      ShowTranslatedValues(Dlg);
      Dlg.Execute(Ship,Plates);
      Dlg.Destroy;
   end;
   for I:=1 to Plates.Count do begin
      Patch:=plates[I-1];
      Patch.Destroy;
   end;
   Plates.Destroy;
end;{TFreeEdit.Layer_Develop}

// Delete all layers that are empty from the model
procedure TFreeEdit.Layer_DeleteEmpty;
var I,N   : integer;
    Undo  : TFreeUndoObject;
begin
   N:=0;
   if Quiet then Undo:=nil
            else Undo:=CreateUndoObject(Userstring(140),false);
   for I:=Ship.NumberOfLayers downto 1 do if (Ship.Layer[I-1].Count=0) and (Ship.NumberOfLayers>1) then
   begin
      Ship.Layer[I-1].Delete;
      inc(N);
      Ship.FileChanged:=True;
   end;
   if Ship.ActiveLayer=nil then Ship.ActiveLayer:=Ship.Layer[Ship.NumberOfLayers-1]
                            else Ship.ActiveLayer:=Ship.ActiveLayer;
   if (N>0) and (not Quiet) then
   begin
      Undo.Accept;
      ShowMessage(IntToStr(N)+#32+Userstring(141)+'.');
   end;
   if (N=0) and (Undo<>nil) then Undo.Delete;
end;{TFreeEdit.Layer_DeleteEmpty}

// Show layer dialog window
procedure TFreeEdit.Layer_Dialog;
var LayerDialog : TFreeLayerDialog;
begin
   LayerDialog:=TFreeLayerDialog.Create(Ship);
   ShowTranslatedValues(LayerDialog);
   LayerDialog.Execute(Ship);
   LayerDialog.Free;
end;{TFreeEdit.Layer_Dialog}

function TFreeEdit.Layer_New:TFreeSubdivisionLayer;
begin
   CreateUndoObject(Userstring(142),True);
   Result:=Ship.Surface.AddNewLayer;
   Result.Color:=Ship.Preferences.LayerColor;
   Ship.FileChanged:=True;
end;{TFreeEdit.Layer_New}

// Adds a marker to the list with markers
procedure TFreeEdit.Marker_Add(Marker:TFreeMarker);
begin
   Ship.FMarkers.Add(Marker);
   Marker.FOwner:=Ship;
end;{TFreeEdit.Marker_Add}

// Delete all markers from the model
procedure TFreeEdit.Marker_Delete;
var I:Integer;
begin
   if MessageDlg(Userstring(143),mtConfirmation,[mbYes,mbNo],0)=mrYes then
   begin
      CreateUndoObject(Userstring(144),True);
      for I:=1 to Ship.NumberofMarkers do Ship.Marker[I-1].Destroy;
      Ship.FMarkers.Clear;
      Ship.FileChanged:=True;
      for I:=1 to Ship.NumberOfViewports do if Ship.Viewport[I-1].Zoom=1.0
          then Ship.Viewport[I-1].ZoomExtents
          else Ship.Viewport[I-1].Refresh;
   end;
end;{TFreeEdit.Marker_Delete}

// Import markers from a textfile
procedure TFreeEdit.Marker_Import;
var OpenDialog : TOpenDialog;
    Str        : string;
    I          : integer;
    LineNr     : Integer;
    P          : T3DVector;
    FFile      : TextFile;
    Markers    : TFasterList;
    Marker     : TFreeMarker;
    Answer     : word;

    procedure Import(Markers:TFasterList);
    var I      : Integer;
        Marker : TFreeMarker;
    begin
      for I:=1 to Markers.Count do
      begin
         Marker:=Markers[I-1];
         Marker_Add(Marker);
      end;
      Ship.FileChanged:=True;
      Ship.Visibility.ShowMarkers:=True;
      for I:=1 to Ship.NumberOfViewports do if Ship.Viewport[I-1].Zoom=1.0 then Ship.Viewport[I-1].ZoomExtents
                                                                             else Ship.Viewport[I-1].Refresh;
      Ship.Redraw;
    end;{import}

begin
   OpenDialog:=TOpenDialog.Create(Ship);
   OpenDialog.InitialDir:=Ship.Preferences.ImportDirectory;
   OpenDialog.Filter:='Text files (*.txt)|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      assignFile(FFile,ChangeFileExt(Opendialog.FileName,'.txt'));
      {$I-}Reset(FFile);{$I+}
      if IOResult=0 then begin
         Ship.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         LineNr:=1;
         // skip the first line of the file
         readln(FFile);
         Markers:=TFasterList.Create;
//       try
//          try
               Marker:=TFreeMarker.Create;
               repeat
                  Readln(FFile,Str);
                  repeat
                     i:=Pos(#9,Str);
                     if I<>0 then str[I]:=#32;
                  until I=0;
                  inc(LineNr);
                  Str:=Trim(Uppercase(Str));
                  if (Str<>'') and (Str<>'EOF') then
                  begin
                     P.X:=ReadFloatFromStr(LineNr,Str);
                     P.Y:=ReadFloatFromStr(LineNr,Str);
                     P.Z:=ReadFloatFromStr(LineNr,Str);
                     Marker.Add(P);
                     Str:=#32;
                  end else if Str='' then
                  begin
                     if Marker.NumberOfPoints>1 then Markers.Add(Marker)
                                                else Marker.Destroy;
                     Marker:=TFreeMarker.Create;
                  end;
               until (Str='EOF') or (EOF(FFile));
               if Marker.NumberOfPoints>1 then Markers.Add(Marker)
                                          else Marker.Destroy;
//          except
//             MessageDlg(Userstring(132)+#32+IntToStr(LineNr),mtError,[mbOk],0);
//          end;
//       finally
            CloseFile(FFile);
//       end;
         if Markers.Count>0 then begin
            if Ship.NumberofMarkers>0 then begin
               Answer:=MessageDlg(Userstring(145),mtConfirmation,[mbYes,mbNo,mbCancel],0);
               if Answer<>mrCancel then begin
                  CreateUndoObject(Userstring(146),True);
                  if Answer=mrYes then begin
                     for I:=1 to Ship.NumberofMarkers do Ship.Marker[I-1].Destroy;
                     Ship.FMarkers.Clear;
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
end;{TFreeEdit.Marker_Import}

// Checks the surface for inconsistent normal directions and leaks
procedure TFreeEdit.Model_Check(ShowResult:Boolean);
const SqError = 1e-8;
var I,J,InvertedFaces,Inconsistent,NonManifold,DblEdges: Integer;
    Point,Pt      : TFreeSubdivisionPoint;
    Face          : TFreeSubdivisionFace;
    Edge1,Edge2   : TFreeSubdivisionControlEdge;
    CtrlFace      : TFreeSubdivisionControlFace;
    CtrlPoint     : TFreeSubdivisionControlPoint;
    AllFaces,NewGroup,DoubleEdges,Points: TFasterList;
    Changed       : Boolean;
    Str           : Widestring;
    Undo          : TFreeUndoObject;
    Leaks         : TFasterList;
    Swap          : Boolean;
    NewLayer      : TFreeSubdivisionLayer;
    Normal,Tmp    : T3DVector;

    procedure FindConnectedFaces(DoneList,ToDoList:TFasterList);
    var I,J,K,Ind : integer;
        P1,P2     : TFreeSubdivisionPoint;
        Edge      : TFreeSubdivisionEdge;
        F1,F2     : TFreeSubdivisionFace;
    begin
       I:=1;
       while I<=DoneList.Count do begin
          F1:=DoneList[I-1];
          P1:=F1.Point[F1.NumberOfPoints-1];
          for J:=1 to F1.NumberOfPoints do begin
             P2:=F1.Point[J-1];
             Edge:=Ship.Surface.EdgeExists(P1,P2);
             if Edge<>nil then if Edge.NumberOfFaces>1 then begin
                for K:=1 to Edge.NumberOfFaces do if Edge.Face[K-1]<>F1
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
                      Ind:=(Ind+1) mod F2.NumberOfPoints; // select the next index
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
    end;// FindConnectedFaces
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
      for I:=1 to Ship.Surface.NumberOfControlEdges do begin
         Edge1:=Ship.Surface.ControlEdge[I-1];
         if Edge1.NumberOfFaces=1 then
         if DoubleEdges.SortedIndexOf(Edge1)=-1 then begin
            for J:=1 to Edge1.StartPoint.NumberOfEdges do begin
               Edge2:=Edge1.StartPoint.Edge[J-1] as TFreeSubdivisionControlEdge;
               if (Edge1<>Edge2) and (Edge2.NumberOfFaces=1) then begin
                  if ((Sqr(Edge1.StartPoint.Coordinate-Edge2.StartPoint.Coordinate)<SqError)
                  and (Sqr(Edge1.EndPoint.Coordinate-Edge2.EndPoint.Coordinate)<SqError))
                  or ((Sqr(Edge1.StartPoint.Coordinate-Edge2.EndPoint.Coordinate)<SqError)
                  and (Sqr(Edge1.EndPoint.Coordinate-Edge2.StartPoint.Coordinate)<SqError)) then
                  if DoubleEdges.SortedIndexOf(Edge2)=-1 then DoubleEdges.AddSortedObject( Edge1,Edge2 );
               end;
            end;
         end;
      end;
      Points:=TFasterList.Create;
      for I:=1 to DoubleEdges.Count do begin
         Edge1:=DoubleEdges[I-1];
         Edge2:=DoubleEdges.Objects[I-1];
         if (Ship.Surface.ControlEdges.IndexOf(Edge1)<>-1)
         and (Ship.Surface.ControlEdges.IndexOf(Edge2)<>-1) then begin
         // remove the face connected to edge2 and rebuild it by connecting it to edge1
            Ctrlface:=Edge2.Face[0] as TFreeSubdivisionControlFace;
            Points.Clear;
            for J:=1 to CtrlFace.NumberOfpoints do begin
               Point:=CtrlFace.Point[J-1];
               if Point=Edge2.StartPoint then begin
                  if Sqr(Edge2.StartPoint.Coordinate-Edge1.StartPoint.Coordinate)<SqError then
                  begin
                     if Points.IndexOf(Edge1.StartPoint)=-1 then points.Add(Edge1.StartPoint);
                  end else if Sqr(Edge2.StartPoint.Coordinate-Edge1.EndPoint.Coordinate)<SqError then
                  begin
                     if Points.IndexOf(Edge1.EndPoint)=-1 then points.Add(Edge1.EndPoint);
                  end;
               end else if Point=Edge2.EndPoint then
               begin
                  if Sqr(Edge2.EndPoint.Coordinate-Edge1.StartPoint.Coordinate)<SqError then
                  begin
                     if Points.IndexOf(Edge1.StartPoint)=-1 then points.Add(Edge1.StartPoint);
                  end else if Sqr(Edge2.EndPoint.Coordinate-Edge1.EndPoint.Coordinate)<SqError then
                  begin
                     if Points.IndexOf(Edge1.EndPoint)=-1 then points.Add(Edge1.EndPoint);
                  end;
               end else if Points.IndexOf(Point)=-1 then Points.Add(Point);
            end;
            if Points.Count>2 then
            begin
               NewLayer:=Ctrlface.Layer;
               Ship.Surface.AddControlFace(Points,False,NewLayer);
               CtrlFace.Delete;
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
   AllFaces.Capacity:=Ship.Surface.NumberOfControlFaces;
   for I:=1 to Ship.Surface.NumberOfControlFaces do AllFaces.Add(Ship.Surface.ControlFace[I-1]);
   AllFaces.Sort; // Sort list for faster object search

   Leaks:=TFasterList.Create;
   // assemble leaks
   for I:=1 to Ship.Surface.NumberOfControlPoints do
   begin
      CtrlPoint:=Ship.Surface.ControlPoint[I-1];
      if CtrlPoint.IsLeak then Leaks.Add(CtrlPoint);
   end;
   // sort leaks in ascending z-coordinate
   for I:=1 to Leaks.Count-1 do
   begin
      for J:=I+1 to Leaks.Count do
      begin
         Point:=Leaks[I-1];
         Pt:=Leaks[J-1];
         Swap:=False;
         if Pt.Coordinate.Z<Point.Coordinate.Z then Swap:=True;
         if (abs(Pt.Coordinate.Z-Point.Coordinate.Z)<1e-6) and (Pt.Coordinate.X<Point.Coordinate.X) then Swap:=True;
         if (abs(Pt.Coordinate.Z-Point.Coordinate.Z)<1e-6) and (abs(Pt.Coordinate.X-Point.Coordinate.X)<1e-6) and (Pt.Coordinate.Y<Point.Coordinate.Y) then Swap:=True;
         if Swap then Leaks.Exchange(I-1,J-1);
      end;
   end;

   for I:=1 to Ship.Surface.NumberOfControlEdges do if Ship.Surface.ControlEdge[I-1].NumberOfFaces>2 then inc(NonManifold);
   if AllFaces.Count>0 then
   begin
      NewGroup:=TFasterList.Create;
      while AllFaces.Count>0 do
      begin
         Face:=AllFaces[AllFaces.Count-1];
         AllFaces.Delete(AllFaces.Count-1);
         NewGroup.Clear;
         NewGroup.Capacity:=AllFaces.Count;
         NewGroup.Add(Face);
         // use the first face as seed for the following procedure
         FindConnectedFaces(NewGroup,AllFaces);
         NewGroup.Sort;

         // find the lowest point of this group of faces
         Point:=nil;
         for I:=1 to NewGroup.Count do
         begin
            Face:=NewGroup[I-1];
            for j:=1 to Face.NumberOfpoints do
            begin
               Pt:=Face.Point[J-1];
               if Point=nil then Point:=Pt
                            else if Pt.Coordinate.Z<Point.Coordinate.Z then Point:=Pt;
            end;
         end;
         if Point<>nil then
         begin
            // select the a face connected to this point and also present in the
            // newgroup-list with faces and with the most vertical normal of all canditates
            Face:=nil;
            for I:=1 to Point.NumberOfFaces do if NewGroup.SortedIndexOf(Point.Face[I-1])<>-1 then
            begin
               if Face=nil then
               begin
                  Face:=Point.Face[I-1];
                  normal:=Face.FaceNormal;
               end else
               begin
                  Tmp:=Point.Face[I-1].FaceNormal;
                  if abs(Tmp.Z)>abs(Normal.Z) then
                  begin
                     Face:=Point.Face[I-1];
                     normal:=Face.FaceNormal;
                  end;
               end;
            end;
            if Face<>nil then
            begin
               if Normal.Z>0.0 then
               begin
                  // normal points upward, all faces in this group must be inverted
                  for I:=1 to NewGroup.Count do
                  begin
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
      if (Leaks.Count>0) and (ShowResult) then
      begin
         Str:=Userstring(149)+#32+IntToStr(Leaks.Count)+#32+Userstring(150)+'.';
         if Leaks.Count>10 then Str:=Str+EOL+Userstring(151)+':';
         Str:=Str+EOL;
         for I:=1 to Leaks.Count do
         begin
            Point:=Leaks[I-1];
            Str:=Str+EOL+FloatToStrF(Point.Coordinate.X,ffFixed,7,3)+', '+FloatToStrF(Point.Coordinate.Y,ffFixed,7,3)+', '+FloatToStrF(Point.Coordinate.Z,ffFixed,7,3);
            if I=10 then break;
         end;
         MessageDlg(Str,mtWarning,[mbOk],0);
      end;

      if (Changed) or (Inconsistent>0) or (NonManifold>0) or (DblEdges>0) then
      begin
         Undo.Accept;
         Ship.Build:=False;
         Ship.Redraw;
         Ship.FileChanged:=True;
         if ShowResult then
         begin
            Str:=Userstring(152)+':';
            if DblEdges>0 then Str:=Str+EOL+IntToStr(DblEdges)+#32+UserString(158)+'.';
            if Inconsistent>0 then Str:=Str+EOL+IntToStr(Inconsistent)+#32+Userstring(153)+'.';
            if InvertedFaces>0 then Str:=Str+EOL+IntToStr(InvertedFaces)+#32+Userstring(154)+'.';
            if NonManifold>0 then
            begin
               Str:=Str+EOL+IntToStr(NonManifold)+#32+Userstring(155);
            end;
            MessageDlg(Str,mtInformation,[mbOk],0);
            if assigned(Ship.FOnUpdateGeometryInfo) then Ship.FOnUpdateGeometryInfo(self);
         end;
      end else
      begin
         Undo.Delete;
         if (ShowResult) and (Leaks.Count=0) then ShowMessage(Userstring(156));
      end;
      Leaks.Destroy;
   end;
   AllFaces.Destroy;
end;{TFreeEdit.Model_Check}

// Start a new model (with a predefined surface)
// returns true if a new model has indeed been created
//
//    Великие географические открытия
//
const Default: array [0..6,0..4] of T3DVector= // ship has 7 columns of 5 points(or rows)
 ( ( ( x: 0.06; y:0;    z:0    ),  // station 0,stern = Галеон
     ( x: 0.02; y:0;    z:1.75 ),
     ( x:-0.04; y:0.1;  z:2.1  ),
     ( x:-0.04; y:0.125;z:2.5  ),
     ( x:-0.03; y:0.11; z:5.3  ) ),
   ( ( x: 0.2;  y:0;    z:0    ),  // station 1
     ( x: 0.18; y:0.12; z:1    ),
     ( x: 0.17; y:0.27; z:1.5  ),
     ( x: 0.16; y:0.28; z:2.5  ),
     ( x: 0.16; y:0.29; z:4.9  ) ),
   ( ( x: 0.4;  y:0;    z:0    ),  // station 2
     ( x: 0.4;  y:0.2;  z:0.2  ),
     ( x: 0.4;  y:0.43; z:1    ),
     ( x: 0.4;  y:0.37; z:2.2  ),
     ( x: 0.4;  y:0.38; z:3.8  ) ),
   ( ( x: 0.6;  y:0;    z:0    ),  // station 3
     ( x: 0.6;  y:0.22; z:0.1  ),
     ( x: 0.6;  y:0.45; z:0.9  ),
     ( x: 0.6;  y:0.4;  z:2.2  ),
     ( x: 0.6;  y:0.4;  z:3.6  ) ),
   ( ( x: 0.8;  y:0;    z:0    ),  // station 4
     ( x: 0.8;  y:0.2;  z:0.5  ),
     ( x: 0.8;  y:0.24; z:1.2  ),
     ( x: 0.8;  y:0.3;  z:2.5  ),
     ( x: 0.8;  y:0.368;z:3.8  ) ),
   ( ( x: 0.93; y:0;    z:0.15 ),  // station 5
     ( x: 0.93; y:0.05; z:1    ),
     ( x: 0.93; y:0.075;z:2    ),
     ( x: 0.93; y:0.125;z:3    ),
     ( x: 0.95; y:0.2;  z:4    ) ),
   ( ( x: 1.018;y:0;    z:1    ),  // station 6,stem
     ( x: 1.008;y:0;    z:1.75 ),
     ( x: 1;    y:0;    z:2.5  ),
     ( x: 0.998;y:0;    z:3.25 ),
     ( x: 0.998;y:0;    z:4    )
   )
 );
function TFreeEdit.Model_New:Boolean;
var Answer: word;
    L,B,D: TFloatType; P: T3DVector;
    I,J,Cols,Rows: integer;
    Spline1,Spline2: TFreeSpline;
    TrvSplines: TFasterList;
    Pts: array of array of TFreeSubdivisionControlPoint;
    StemPoint: TFreeSubdivisionControlPoint;
    FreeNewModelDialog: TFreeNewModelDialog;
begin
   Result:=False;               // Apparently saving was not successfull, abort
   Answer:=Ship.Edit.File_SaveCheck;
   if (Answer=mrCancel) or Ship.FileChanged then exit;
   FreeNewModelDialog:=TFreeNewModelDialog.Create(Ship);
   ShowTranslatedValues(FreeNewModelDialog);
   if FreeNewModelDialog.Execute then begin
      CreateUndoObject(Userstring(157),True);
      Cols:=FreeNewModelDialog.NCols-1;
      Rows:=FreeNewModelDialog.NRows-1;
      L:=FreeNewModelDialog.Length;
      B:=FreeNewModelDialog.Breadth;
      D:=FreeNewModelDialog.Draft/2;
      Ship.Clear;
      with Ship.ProjectSettings do begin                       // «Free!Ship»
        ProjectUnits:=TFreeUnitType(FreeNewModelDialog.ComboBox1.ItemIndex);
        ProjectLength:=L;
        ProjectBeam:=B;
        ProjectDraft:=D*2;
//      Owner.Filename:=FreeNewModelDialog.ShipBox.Items[FreeNewModelDialog.ShipBox.ItemIndex];
        Ship.FileName:='Галеон Великих Испанских географических открытий';
        FProjectName:='«'+ChangeFileExt(ExtractFilename(Ship.FileName),'')
                     +'». Корпус всепогодного корабля среднего водоизмещения (галеон)';
        FProjectDesigner:='Подсекция штормовой мореходности,Научно-инженерное общество корабелов им.А.Н.Крылова';
        FProjectComment:='Вариант эволюционного совершенствования корабельных обводов из эпохи Великих Испанских географических открытий';
        FProjectFileCreatedBy:='Free!Ship (c)'+TimeString; // FormatDateTime('YYYY-MM-DD_hh:nn',Now );
        ProjectUnderWaterColorAlpha:=128;
      End;
      TrvSplines:=TFasterList.Create;
      StemPoint:=nil;      // First create tmp. splines in transverse direction
      for I:=0 to 6 do begin
         Spline1:=TFreeSpline.Create;
         for J:=0 to 4 do begin
            P:=Default[I,J];
            P.X:=P.X*L;
            P.Y:=P.Y*B;
            P.Z:=P.Z*D;
            Spline1.Add(P);
         end;
         TrvSplines.Add( Spline1 );
      end;                 // now create tmp. splines in longitudinal direction
      Setlength( Pts,Rows+1 );
      for I:=0 to rows do begin
         Setlength(Pts[I],Cols+1);
         Spline2:=TFreeSpline.Create;
         for j:=0 to TrvSplines.Count-1 do begin
            Spline1:=TrvSplines[J];
            P:=Spline1.Value(I/Rows);
            Spline2.Add(P);
         end;
         // now calculate all points on the longitudinal spline and send it to the surface
         for J:=0 to Cols do begin
            P:=Spline2.Value( J/Cols );
            Pts[I,J]:=TFreeSubdivisionControlPoint.Create(Ship.Surface);
            Ship.Surface.AddControlPoint(Pts[I,J]);
            Pts[I,J].Coordinate:=P;
            if (I=0) and (J=Cols) then StemPoint:=Pts[I,J];
         end;
         Spline2.Destroy;
      end;                                               // Destroy tmp splines
      for I:=1 to TrvSplines.Count do begin
         Spline1:=TrvSplines[I-1];
         Spline1.Destroy;
      end;
      TrvSplines.Clear; // finally create the controlfaces over the newly calculated points
      for I:=1 to Rows do begin
         for J:=1 to cols do begin
            TrvSplines.Clear;
            Trvsplines.Add(Pts[I,J-1]);
            Trvsplines.Add(Pts[I,J]);
            Trvsplines.Add(Pts[I-1,J]);
            Trvsplines.Add(Pts[I-1,J-1]);
            Ship.Surface.AddControlFace(Trvsplines,True);
         end;
      end;
      Ship.Precision:=fpMedium;
      Ship.Surface.Initialize(1,1,1);
      // Collapse stempoint to mage the grid irregular in order to demonstrate subdivision-surface capabilities
      if StemPoint<>nil then if StemPoint.VertexType=svCorner then stempoint.VertexType:=svCrease;
      Ship.Build:=False;
      // Add 25 stations
      for I:=0 to 24 do Intersection_Add(fiStation,I/25*(Ship.Surface.Max.X-Ship.Surface.Min.X));
      // Add 5 buttocks
      for I:=0 to 4 do Intersection_Add(fiButtock,I/5*(Ship.Surface.Max.Y-Ship.Surface.Min.Y));
      // Add 11 waterlines
      for I:=0 to 10 do Intersection_Add(fiWaterline,I/10*(Ship.Surface.Max.Z-Ship.Surface.Min.Z));
      Ship.draw;
      Ship.FileChanged:=True;
      if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
      Result:=true;
      TrvSplines.Destroy;
   end;
   FreeNewModelDialog.Destroy;
end;{TFreeEdit.Model_New}

// Affine hullform transformation according to Lackenby
procedure TFreeEdit.Model_LackenbyTransformation;
var Dialog     : TFreeLackenbyDialog;
    Undo       : TFreeUndoObject;
    I,UndoIndex: Integer;
    Modified   : Boolean;
begin
//# if not Ship.ProjectSettings.FMainparticularsHasBeenset then
//#    begin ShowMessage( Userstring(96) ); exit; end;
   Dialog:=TFreeLackenbyDialog.Create(Ship);
   ShowTranslatedValues(Dialog);
   Undo:=CreateUndoObject(Userstring(159),false);
   UndoIndex:=Ship.UndoCount;
   if Dialog.Execute(Ship,Modified) then begin
      for I:=Ship.UndoCount downto UndoIndex+1 do Ship.UndoObject[I-1].Delete;
      if not Modified then Undo.Delete
                      else Undo.Accept;
   end else begin
      for I:=Ship.UndoCount downto UndoIndex+1 do Ship.UndoObject[I-1].Delete;
      if Modified then Undo.Restore;
      Undo.Delete;
   end;
   Dialog.Destroy;
end;{TFreeEdit.Model_LackenbyTransformation}

// Scale the entire model and all equivalent data such as stations etc.
procedure TFreeEdit.Model_Scale(ScaleVector:T3DVector;OverrideLock,AdjustMarkers:Boolean);
var I,J     : integer;
    Point   : TFreeSubdivisionControlPoint;
    P       : T3DVector;
    Marker  : TFreeMarker;
begin
   for I:=1 to Ship.Surface.NumberOfControlPoints do begin
      Point:=Ship.Surface.ControlPoint[I-1];
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
   Ship.ProjectSettings.ProjectLength:=abs(Ship.ProjectSettings.ProjectLength*Scalevector.X);
   Ship.ProjectSettings.ProjectBeam:=abs(Ship.ProjectSettings.ProjectBeam*Scalevector.Y);
   Ship.ProjectSettings.ProjectDraft:=abs(Ship.ProjectSettings.ProjectDraft*Scalevector.Z);
   if not Ship.ProjectSettings.UseMidleFrame then
      Ship.ProjectSettings.MidleFrame:=abs(Ship.ProjectSettings.MidleFrame*ScaleVector.X);
   // Update markers
   if AdjustMarkers then for I:=1 to Ship.NumberOfMarkers do begin
      Marker:=Ship.Marker[I-1];
      for j:=1 to Marker.NumberOfPoints do begin
         P:=Marker.Point[J-1];
         P.X:=P.X*Scalevector.X;
         P.Y:=P.Y*Scalevector.Y;
         P.Z:=P.Z*Scalevector.Z;
         Marker.Point[J-1]:=P;
      end;
   end;
   // Update stations, buttcks and waterlines
   for I:=1 to Ship.NumberofStations do Ship.Station[I-1].FPlane.d:=Ship.Station[I-1].FPlane.d*ScaleVector.X;
   for I:=1 to Ship.NumberofButtocks do Ship.Buttock[I-1].FPlane.d:=Ship.Buttock[I-1].FPlane.d*ScaleVector.Y;
   for I:=1 to Ship.NumberofWaterlines do Ship.Waterline[I-1].FPlane.d:=Ship.Waterline[I-1].FPlane.d*ScaleVector.Z;
   // Refresh controlpoint data
   Ship.ActiveControlPoint:=Ship.ActiveControlPoint;
   // Reset any present hydrostatic calculations
   for I:=1 to Ship.NumberOfHydrostaticCalculations do begin
      Ship.HydrostaticCalculation[I-1].Draft:=abs(Ship.HydrostaticCalculation[I-1].Draft*ScaleVector.Z);
      Ship.HydrostaticCalculation[I-1].Trim:=Ship.HydrostaticCalculation[I-1].Trim*ScaleVector.Z;
      Ship.HydrostaticCalculation[I-1].Calculated:=False;
   end;
{
   //## scale data used for KAPER series resistance calculations
   with Ship.FResistanceKaperData do begin
      Draft:=Draft*ScaleVector.Z;
      Lwl:=Lwl*ScaleVector.X;
      Bwl:=Bwl*ScaleVector.Y;
      Displacement:=Displacement*ScaleVector.X*ScaleVector.Y*ScaleVector.Z;
      WettedSurface:=WettedSurface*ScaleVector.X*ScaleVector.Z;
   end;
   //## scale data used for DELFT series resistance calculations
   with Ship.FResistanceDelftData do begin
      Bwl:=Bwl*ScaleVector.Y;
      Displacement:=Displacement*ScaleVector.X*ScaleVector.Y*ScaleVector.Z;
      Draft:=Draft*ScaleVector.Z;
      DraftTotal:=DraftTotal*ScaleVector.Z;
      KeelChordLength:=KeelChordLength*ScaleVector.X;
      KeelArea:=KeelArea*ScaleVector.X*ScaleVector.Z;
      Lwl:=Lwl*ScaleVector.X;
      RudderChordLength:=RudderChordlength*ScaleVector.X;
      RudderArea:=RudderArea*ScaleVector.X*ScaleVector.Z;
      WettedSurface:=WettedSurface*ScaleVector.X*ScaleVector.Z;
      WlArea:=WlArea*ScaleVector.X*ScaleVector.Y;
   end;
}
   Ship.Build:=False;                          // Initialize all other data
   Ship.FileChanged:=True;                     // Redraw
   Ship.Draw;
end;

// Merge two selected edges by removing their common controlpoint.
procedure TFreeEdit.Point_Collapse;
var I,N   : integer;
    Point : TFreeSubdivisionControlPoint;
    Undo  : TFreeUndoObject;
begin
   N:=0;
   Undo:=CreateUndoObject(Userstring(160),false);
   For I:=Ship.NumberOfSelectedControlPoints downto 1 do
   begin
      Point:=Ship.SelectedControlPoint[I-1];
      if (not Point.Locked) and (Point.NumberOfEdges=2) then
      begin
         Point.Collapse;
         inc(N);
      end;
   end;
   if N>0 then
   begin
      Undo.Accept;
      Ship.Build:=false;
      Ship.Redraw;
      Ship.FileChanged:=True;
      if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
   end else Undo.Delete;
end;

// removes any unused points from the model
procedure TFreeEdit.Point_RemoveUnused;
var I,N   : integer;
    Point : TFreeSubdivisionControlPoint;
    Undo  : TFreeUndoObject;
begin
   N:=0;
   Undo:=CreateUndoObject(Userstring(161),false);
   For I:=Ship.Surface.NumberOfControlPoints downto 1 do begin
      Point:=Ship.Surface.ControlPoint[I-1];
      if Point.NumberOfFaces=0 then begin
         Point.Delete;
         inc(N);
      end;
   end;
   if N>0 then begin
      Undo.Accept;
      Ship.Build:=false;
      Ship.Redraw;
      Ship.FileChanged:=True;
      if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
      MessageDlg(IntToStr(N)+#32+Userstring(162),mtInformation,[mbOk],0);
   end else Undo.Delete;
end;

// Finds all intersection of VISIBLE edges and a 3D plane, and inserts a point on each of these edges
procedure TFreeEdit.Point_InsertPlane;
var Dialog  : TFreeInsertPlaneDialog;
    Min,Max : T3DVector;
    Undo    : TFreeUndoObject;
    N       : Integer;
begin
   Ship.Extents(Min,Max);
   Dialog:=TFreeInsertPlaneDialog.Create(Ship);
   ShowTranslatedValues(Dialog);
   Dialog.Max:=Max;
   Dialog.Min:=min;
   if Dialog.Execute then begin
      Undo:=CreateUndoObject(UserString(163),false);
      N:=Ship.Surface.NumberOfControlPoints;
      Ship.Surface.InsertPlane(Dialog.Plane,Dialog.CreateControlCurve);
      if N<Ship.Surface.NumberOfControlPoints then begin
         Undo.Accept;
         Ship.FileChanged:=True;
         Ship.Build:=false;
         Ship.Redraw;
         if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
      end else Undo.Delete; // nothis has been changed
   end;
   Dialog.Destroy;
end;

// Calculates the intersection points of two layers
procedure TFreeEdit.Point_IntersectLayer;
var I: Integer;
    Layers: TFasterList;
    Undo  : TFreeUndoObject;
    Dialog: TFreeIntersectLayerDialog;
begin
   Layers:=TFasterList.Create;
   for I:=1 to Ship.NumberOfLayers do if Ship.Layer[I-1].Count>0 then Layers.Add(Ship.Layer[I-1]);
   if Layers.Count>1 then begin
      Dialog:=TFreeIntersectLayerDialog.Create(Ship);
      ShowTranslatedValues(Dialog);
      if Dialog.Execute(Layers) then begin
         if (Dialog.Layer1<>nil) and (Dialog.Layer2<>nil) then begin
            Undo:=CreateUndoObject(Userstring(164),false);
            if Dialog.Layer1.CalculateIntersectionPoints(Dialog.Layer2) then begin
               Undo.Accept;
               Ship.FileChanged:=True;
               Ship.Build:=False;
               Ship.Redraw;
               if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
            end else begin
               Undo.Delete;
               MessageDlg(Userstring(165),mtInformation,[mbOk],0);
            end;
         end;
      end;
      Dialog.Destroy;
   end else ShowMessage( Userstring(166) );
   Layers.Destroy;
end;

// Locks all selected points
procedure TFreeEdit.Point_Lock;
var I:Integer;
begin
   if Ship.NumberOfSelectedLockedPoints<Ship.NumberOfSelectedControlPoints then
   begin
      self.CreateUndoObject(UserString(167),True);
      for I:=1 to Ship.NumberOfSelectedControlPoints do Ship.SelectedControlPoint[I-1].Locked:=True;
      Ship.ActiveControlPoint:=Ship.ActiveControlPoint;
      Ship.Redraw;
      Ship.FileChanged:=True;
   end;
end;

// Unlocks all selected locked points
procedure TFreeEdit.Point_Unlock;
var I:Integer;
begin
   if Ship.NumberOfSelectedLockedPoints>0 then begin
      self.CreateUndoObject(Userstring(168),True);
      for I:=1 to Ship.NumberOfSelectedControlPoints do Ship.SelectedControlPoint[I-1].Locked:=False;
      Ship.ActiveControlPoint:=Ship.ActiveControlPoint;
      Ship.Redraw;
      Ship.FileChanged:=True;
   end;
end;

// Unlocks all locked points
procedure TFreeEdit.Point_UnlockAll;
var I,N:Integer;
begin
   if Ship.NumberOfLockedPoints>0 then begin
      CreateUndoObject(Userstring(169),True);
      N:=Ship.NumberOfLockedPoints;
      for I:=1 to Ship.Surface.NumberOfControlPoints do Ship.Surface.ControlPoint[I-1].Locked:=False;
      Ship.ActiveControlPoint:=Ship.ActiveControlPoint;
      Ship.Redraw;
      MessageDlg(IntToStr(N)+#32+Userstring(170)+'.',mtInformation,[mbOK],0);
      Ship.FileChanged:=True;
   end;
end;

// Function that shows a warning when certain edit commands are invoked and the model contains locked points
function TFreeEdit.ProceedWhenLockedPoints:Boolean;
begin
   if Ship.NumberOfLockedPoints>0 then begin
      Result:=MessageDlg(Userstring(86)+EOL+
                         Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes;
   end else Result:=True;
end;

// Add a new point to the model with no edges/faces attached
function TFreeEdit.Point_New:TFreeSubdivisionControlPoint;
begin
   Result:=TFreeSubdivisionControlPoint.Create(Ship.Surface);
   Ship.Surface.AddControlPoint(Result);
   Result.Coordinate:=ZERO;
   Ship.ActiveControlPoint:=Result;
   Ship.FileChanged:=true;
   Ship.Redraw;
   if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
end;

// Project all selected points onto a straight line through the first and last selected points
procedure TFreeEdit.Point_ProjectStraightLine;
var I,NLocked,NChanged: Integer;
    Point,P1,P2: TFreeSubdivisionControlPoint;
    P: T3DVector;
    Undo: TFreeUndoObject;
begin
   if Ship.NumberOfSelectedControlPoints>2 then begin
      // Determine if the number of points to be moved does not conatin locked controlpoints only
      // however the first and last points (determining the linesegment) are allowed to be locked
      NLocked:=0;
      for I:=2 to Ship.NumberOfSelectedControlPoints-1 do if Ship.SelectedControlPoint[I-1].Locked then inc(NLocked);
      // Number of lovked points must be smaller then NumberOfSelectedControlPoints-2
      if NLocked<Ship.NumberOfSelectedControlPoints-2 then begin
         P1:=Ship.SelectedControlPoint[0];
         P2:=Ship.SelectedControlPoint[Ship.NumberOfSelectedControlPoints-1];
         Undo:=CreateUndoObject(userstring(171),False);
         NChanged:=0;
         for I:=2 to Ship.NumberOfSelectedControlPoints-1 do begin
            Point:=Ship.SelectedControlPoint[I-1];
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
            Ship.FileChanged:=True;
            Ship.Redraw;
         end else Undo.Delete;
      end else ShowMessage( Userstring(172)+'.' );
   end;
end;

// Deselect all selected items at once
procedure TFreeEdit.Selection_Clear;
begin
   Ship.Surface.Clearselection;
   Ship.ActiveControlPoint:=nil;
   Ship.FSelectedFlowlines.Clear;
   Ship.FSelectedMarkers.Clear;
   Ship.Redraw;
end;

procedure TFreeEdit.Selection_Delete;
var I,N: integer;
begin
   N:=Ship.NumberOfSelectedControlPoints+
      Ship.NumberOfSelectedControlEdges+
      Ship.NumberOfSelectedControlFaces+
      Ship.NumberOfSelectedControlCurves+
      Ship.NumberOfselectedMarkers+
      Ship.NumberOfselectedFlowlines;
   if N>0 then begin
      if MessageDlg(Userstring(173)+#32+IntToStr(N)+#32+Userstring(174)+'?',mtWarning,[mbYes,mbNo],0)=mrYes then
      begin
         CreateUndoObject(Userstring(175),True);
         for I:=Ship.NumberOfselectedFlowlines downto 1 do Ship.SelectedFlowline[I-1].Delete;
         for I:=Ship.NumberOfselectedMarkers downto 1 do Ship.SelectedMarker[I-1].Delete;
         Ship.Surface.Selection_Delete;
         Ship.ActiveControlPoint:=nil;
         Ship.Build:=False;
         Ship.FileChanged:=True;
         Ship.Redraw;
         if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
      end;
   end;
end;

procedure TFreeEdit.Selection_SelectAll;            // Select all visible items
var I,J:Integer;
begin
   for I:=1 to Ship.NumberOfLayers do if Ship.Layer[I-1].Visible then
   begin
      for J:=1 to Ship.Layer[I-1].Count do Ship.Layer[I-1].Items[J-1].Selected:=True;
   end;
   for I:=1 to Ship.Surface.NumberOfControlEdges do if Ship.Surface.ControlEdge[I-1].Visible then Ship.Surface.ControlEdge[I-1].Selected:=True;
   for I:=1 to Ship.Surface.NumberOfControlPoints do if Ship.Surface.ControlPoint[I-1].Visible then Ship.Surface.ControlPoint[I-1].Selected:=True;
   for I:=1 to Ship.Surface.NumberOfControlCurves do if Ship.Surface.ControlCurve[I-1].Visible then Ship.Surface.ControlCurve[I-1].Selected:=True;
   for I:=1 to Ship.NumberofMarkers do if Ship.Marker[I-1].Visible then Ship.Marker[I-1].Selected:=True;
   for I:=1 to Ship.NumberofFlowlines do if Ship.Flowline[I-1].Visible then Ship.Flowline[I-1].Selected:=True;
   Ship.Redraw;
end;

procedure TFreeEdit.Undo;
var UndoObject : TFreeUndoObject;
    Preview    : boolean;
begin
   if Ship.FUndoObjects.Count>0 then begin
      Preview:=Ship.ProjectSettings.SavePreview;
//    try
         if Ship.FUndoPosition=Ship.UndoCount then  begin
            if Ship.UndoObject[Ship.UndoCount-1].FIsTempRedoObject then begin
            end else CreateRedoObject;
         end;
         if Ship.FPreviousUndoPosition<Ship.FUndoPosition then dec(Ship.FUndoPosition);
         Ship.FPreviousUndoPosition:=Ship.FUndoPosition;
         dec(Ship.FUndoPosition);
         UndoObject:=Ship.FUndoObjects[Ship.FUndoPosition];
         UndoObject.Restore;
//    finally
         Ship.ProjectSettings.SavePreview:=Preview;
//    end;
   end;
end;


procedure TFreeEdit.Undo_Clear; begin Ship.ClearUndo; end; // Clear the undo history

procedure TFreeEdit.Undo_ShowHistory;                  // Show the undo history
var Dialog   : TFreeUndoHistoryDialog;
    Undo,Redo: TFreeUndoObject;
    Index    : Integer;
begin
   Dialog:=TFreeUndoHistoryDialog.Create(Ship);
   ShowTranslatedValues(Dialog);
   Redo:=nil;
   if (Ship.FUndoPosition=Ship.UndoCount)
   and (Ship.UndoCount>0) then begin
      if not Ship.UndoObject[Ship.UndoCount-1].FIsTempRedoObject then begin
         Redo:=CreateRedoObject;
         dec(Ship.FUndoPosition);
      end;
   end;
   if Dialog.Execute(Ship) then begin
      if Dialog.UndoBox.ItemIndex<>-1 then begin
         Undo:=Dialog.UndoBox.Items.Objects[Dialog.UndoBox.ItemIndex] as TFreeUndoObject;;
         Index:=Ship.FUndoObjects.IndexOf(Undo);
         if Index<>-1 then begin    // Ship.FPreviousUndoPosition:=Index+1;
            Ship.FUndoPosition:=Index;
            Undo.Restore;
         end;
      end;
   end else if Redo<>nil then Redo.Delete;
   Dialog.Destroy;
end;{TFreeEdit.Undo_ShowHistory}

procedure TFreeEdit.Redo;
var UndoObject : TFreeUndoObject;
    Preview    : boolean;
begin
   if Ship.FUndoObjects.Count>0 then begin
      Preview:=Ship.ProjectSettings.SavePreview;
//    try
         if Ship.FPreviousUndoPosition>Ship.FUndoPosition then inc(Ship.FUndoPosition);
         Ship.FPreviousUndoPosition:=Ship.FUndoPosition;
         inc(Ship.FUndoPosition);
         UndoObject:=Ship.FUndoObjects[Ship.FUndoPosition-1];
         UndoObject.Restore;
//    finally
         Ship.ProjectSettings.SavePreview:=Preview;
//    end;
   end;
end;{TFreeEdit.Redo}

// Add a new intersection of the specified type at the specified location
function  TFreeEdit.Intersection_Add(IntType:TFreeIntersectionType;Distance:TFloatType):TFreeIntersection;
var Intersection  : TFreeIntersection;
    TargetList    : TFasterList;
    I             : integer;
begin
   TargetList:=nil;
   Case IntType of
      fiStation    : TargetList:=Ship.FStations;
      fiButtock    : TargetList:=Ship.FButtocks;
      fiWaterline  : TargetList:=Ship.FWaterlines;
      fiDiagonal   : TargetList:=Ship.FDiagonals;
   end;      // First check if an intersection already exists at this location;
   for I:=1 to TargetList.Count do begin
      Intersection:=TargetList[I-1];
      if Abs(-InterSection.FPlane.d-Distance)<1e-5 then begin // Yes, it exists, so do not add a new one
         Result:=nil;
         exit;
      end;
   end;                           // Once here, a new intersection can be added
   Intersection:=TFreeIntersection.Create(Ship);
   Intersection.IntersectionType:=IntType;
   Intersection.FPlane.a:=0.0;
   Intersection.FPlane.b:=0.0;
   Intersection.FPlane.c:=0.0;
   Intersection.FPlane.d:=0.0;
   Case Intersection.IntersectionType of
      fiStation  : begin
                     Intersection.FPlane.a:=1.0;
                     Intersection.FPlane.d:=-Distance; end;
      fiButtock  : begin
                     Intersection.FPlane.b:=1.0;
                     Intersection.FPlane.d:=-Distance; end;
      fiWaterline: begin
                     Intersection.FPlane.c:=1.0;
                     Intersection.FPlane.d:=-Distance; end;
      fiDiagonal : begin
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
  TFreePreferences Container class for all program settings
}
{$I FreePreferences.inc}
{
  TFreeProjectSettings
   Container class for project settings for each
   project such as mainparticulars, waterdensity etc.
}
{$I FreeProjectSettings.inc}
{
  TFreeShip
   TFreeShip is the actual component used
   for modelling and representing the ship
}
function TFreeShip.FGetNumberOfViewports:integer;
   begin Result:=FViewports.Count; end;
function TFreeShip.FGetOnChangeActiveLayer:TChangeActiveLayerEvent;
   begin Result:=Surface.OnChangeActiveLayer; end;
function TFreeShip.FGetOnChangeLayerData:TNotifyEvent;
   begin Result:=Surface.OnChangeLayerData; end;
function TFreeShip.FGetOnSelectItem:TNotifyEvent;
   begin Result:=Surface.OnSelectItem; end;
function TFreeShip.FGetSelectedControlCurve(Index:integer):TFreeSubdivisionControlCurve;
   begin Result:=Surface.SelectedControlCurve[index]; end;
function TFreeShip.FGetControlCurve(Index:integer):TFreeSubdivisionControlCurve;
   begin Result:=Surface.ControlCurve[index]; end;
function TFreeShip.FGetSelectedControlEdge(Index:integer):TFreeSubdivisionControlEdge;
   begin Result:=Surface.SelectedControlEdge[index]; end;
function TFreeShip.FGetSelectedControlPoint(Index:integer):TFreeSubdivisionControlPoint;
   begin Result:=Surface.SelectedControlPoint[index]; end;
function TFreeShip.FGetSelectedControlFace(Index:integer):TFreeSubdivisionControlFace;
   begin Result:=Surface.SelectedControlFace[index]; end;
function TFreeShip.FGetSelectedFlowline(index:Integer):TFreeFlowline;
   begin Result:=FSelectedFlowlines[index]; end;
function TFreeShip.FGetSelectedMarker(index:Integer):TFreeMarker;
   begin Result:=FSelectedMarkers[index]; end;
function TFreeShip.FGetStation(Index:integer):TFreeIntersection;
begin
   if (Index>=0) and (INdex<Fstations.Count) then Result:=FStations[index]
                                             else raise exception.Create('Invalid station-index');
end;
function TFreeShip.FGetMarker(Index:integer):TFreeMarker;
begin
   if (Index>=0) and (Index<FMarkers.Count) then Result:=FMarkers[index]
                                            else raise exception.Create('Invalid marker-index');
end;
function TFreeShip.FGetNumberofBackgroundImages:Integer;
   begin Result:=FBackgroundImages.Count; end;
function TFreeShip.FGetUndoCount:integer;
   begin Result:=FUndoObjects.Count; end;
function TFreeShip.FGetUndoMemory:integer; var I:integer;
begin
   result:=0; for I:=1 to UndoCount do Result:=Result+UndoObject[I-1].Memory;
end;
function TFreeShip.FGetUndoObject(Index:integer):TFreeUndoObject;
   begin Result:=FUndoObjects[Index]; end;
function TFreeShip.FGetButtock(Index:integer):TFreeIntersection;
begin
   if (Index>=0) and (Index<FButtocks.Count) then Result:=FButtocks[index]
                                             else raise exception.Create('Invalid Buttock-index');
end;
function TFreeShip.FGetDiagonal(Index:integer):TFreeIntersection;
begin
   if (Index>=0) and (Index<FDiagonals.Count) then Result:=FDiagonals[index]
                                              else raise exception.Create('Invalid Diagonal-index');
end;

function TFreeShip.FGetFlowline(Index:integer):TFreeFlowline;
   begin Result:=FFlowlines[index]; end;

function TFreeShip.FGetWaterline(Index:integer):TFreeIntersection;
begin
   if (Index>=0) and (Index<FWaterlines.Count) then Result:=FWaterlines[index]
                                             else raise exception.Create('Invalid Waterline-index');
end;

// Assembles all stations and builds a 2D bodyplan for export to other calculating programs
procedure TFreeShip.FBuildValidFrameTable(Destination:TFasterList;CloseAtDeck:Boolean);
var I,J           : integer;
    Intersection  : TFreeIntersection;
    Spline        : TFreeSpline;
    Min           : TFloatType;
    P             : T3DVector;
    TmpList       : TFasterList;
begin
   Min:=0.0;
   for I:=1 to NumberOfStations do begin
      Intersection:=Station[I-1];
      if not Intersection.Built then Intersection.Rebuild;
      TmpList:=TFasterList.Create;
      for J:=1 to Intersection.Count do begin
         Spline:=TFreeSpline.Create;
         Spline.Assign(Intersection.Items[J-1]); // Quick check to determine if the frame runs from bottom to top
         if Spline.Value(0.0).Z>Spline.Value(1.0).Z then // If not then reverse the points
            Spline.InvertDirection;
         TmpList.Add(Spline);
      end;                                         // Take all segments and join into one
      if TmpList.Count>1 then JoinSplineSegments(0.01,True,TmpList);
      for J:=1 to TmpList.Count do begin
         Spline:=TmpList[J-1];
         if CloseAtDeck then begin
            if Spline.Point[Spline.NumberOfPoints-1].Y<>0.0 then begin
               P:=Spline.Point[Spline.NumberOfPoints-1];
               P.Y:=0.0;
               Spline.Add(P);
               Spline.Knuckle[Spline.NumberOfPoints-2]:=True;
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
      for J:=1 to Spline.NumberOfPoints do begin
         P:=Spline.Point[J-1];
         P.Z:=P.Z-Min;
         Spline.Point[J-1]:=P;
      end;
   end;
end;

function TFreeShip.FGetActiveLayer:TFreeSubdivisionlayer;
   begin Result:=Surface.ActiveLayer; end;
function TFreeShip.FGetBackgroundImage(Index:Integer):TFreeBackgroundImageData;
   begin Result:=FBackgroundImages[index]; end;
function TFreeShip.FGetBuild:Boolean;
   begin Result:=Surface.Build; end;
function TFreeShip.FGetHydrostaticCalculation(Index:integer):TFreeHydrostaticCalc;
   begin Result:=FHydrostaticCalculations[index]; end;
function TFreeShip.FGetLayer(Index:integer):TFreeSubdivisionLayer;
   begin Result:=Surface.Layer[index]; end;
function TFreeShip.FGetNumberOfMarkers:integer;
   begin Result:=FMarkers.Count; end;
function TFreeShip.FGetNumberOfStations:integer;
   begin Result:=FStations.Count; end;
function TFreeShip.FGetNumberOfWaterlines:integer;
   begin Result:=FWaterlines.Count; end;
function TFreeShip.FGetNumberOfButtocks:integer;
   begin Result:=FButtocks.Count; end;
function TFreeShip.FGetNumberOfDiagonals:integer;
   begin Result:=FDiagonals.Count; end;
function TFreeShip.FGetNumberOfFlowLines:Integer;
   begin Result:=FFlowlines.Count; end;
function TFreeShip.FGetNumberOfHydrostaticCalculations:integer;
   begin Result:=FHydrostaticCalculations.Count; end;
function TFreeShip.FGetNumberOfLockedPoints:Integer;
   begin Result:=Surface.NumberOfLockedPoints; end;
function TFreeShip.FGetNumberOfLayers:integer;
   begin Result:=Surface.NumberOfLayers; end;
function TFreeShip.FGetViewport(Index:integer):TFreeViewport;
begin
   if (Index>=0) and (Index<NumberOfViewports) then Result:=FViewports[index]
                                               else Raise Exception.Create('Invalid viewport index!');
end;
procedure TFreeShip.FSetActiveControlPoint(Val:TFreeSubdivisionControlPoint);
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
            ShowWindow(FControlpointForm.Handle, SW_SHOWNOACTIVATE);
         end;
         if not FControlpointForm.Visible then FControlpointForm.Visible:=true;
      end;
      FCurrentlyMoving:=False;
      FPointHasBeenMoved:=False;
   end else if FActiveControlPoint<>nil then begin // Update controlpoint information
      FControlpointForm.ActiveControlPoint:=FActiveControlPoint;
   end;
end;

procedure TFreeShip.FSetActiveLayer(Val:TFreeSubdivisionLayer);
    begin Surface.ActiveLayer:=Val; end;

procedure TFreeShip.FSetBuild(Val:Boolean);
var I : integer;
begin
   Surface.Build:=Val;
   if not Build then begin
      for I:=1 to NumberOfStations do Station[I-1].Built:=False;
      for I:=1 to NumberOfButtocks do Buttock[I-1].Built:=False;
      for I:=1 to NumberOfWaterlines do Waterline[I-1].Built:=False;
      for I:=1 to NumberOfDiagonals do Diagonal[I-1].Built:=False;
      for I:=1 to NumberOfHydrostaticCalculations do HydrostaticCalculation[I-1].Calculated:=False;
      for I:=1 to NumberOfFlowlines do Flowline[I-1].Build:=False;
   end;
end;
procedure TFreeShip.FSetEditMode(Val:TFreeEditMode);
begin
   if Val<>FEditMode then begin FEditMode:=Val;
      Case EditMode of
         emSelectItems: begin end;
      end;
      Redraw;
   end;
end;
procedure TFreeShip.FSetFileChanged(Val:Boolean);
begin if Val<>FFileChanged then begin
         FFileChanged:=Val;
         if assigned(FOnFileChanged) then FOnFileChanged(self); end;
end;
procedure TFreeShip.FSetFileName( Val:string ); var Tmp:string;
begin if val='' then val:=Userstring(179);
         Tmp:=ChangeFileExt( Val,FreeShipExtention );
         if FFilename<>val then FFilename:=Val;
end;
function TFreeShip.FGetFilename: AnsiString; var Ext: AnsiString;
begin if FFilename='' then FFilename:=Userstring(179);
      Ext:=ExtractFileExt( FFilename );
      if (Ext='.ftm') or (Ext='.fbm') or (Ext='.fef') then Result:=FFilename
         else Result:=ChangeFileExt( FFilename,FreeShipExtention );
end;
procedure TFreeShip.FSetFileVersion(Val:TFreeFileVersion);
    begin if Val<>FFileVersion then
       begin FFileVersion:=Val; FileChanged:=true; end;
    end;
function TFreeShip.FGetNumberOfSelectedControlEdges:integer;
   begin Result:=Surface.NumberOfSelectedControlEdges; end;
function TFreeShip.FGetNumberOfSelectedControlCurves:integer;
   begin  Result:=Surface.NumberOfSelectedControlCurves; end;
function TFreeShip.FGetNumberOfControlCurves:integer;
   begin Result:=Surface.NumberOfControlCurves; end;
function TFreeShip.FGetNumberOfSelectedControlFaces:integer;
   begin Result:=Surface.NumberOfSelectedControlFaces; end;
function TFreeShip.FGetNumberOfSelectedControlPoints:integer;
   begin Result:=Surface.NumberOfSelectedControlPoints; end;
function TFreeShip.FGetNumberOfselectedFlowlines:Integer;
   begin Result:=FselectedFlowlines.Count; end;
function TFreeShip.FGetNumberOfselectedMarkers:Integer;
   begin Result:=FselectedMarkers.Count; end;
function TFreeShip.FGetNumberOfSelectedLockedPoints:integer;
   begin Result:=Surface.NumberOfSelectedLockedPoints; end;
procedure TFreeShip.FSetOnChangeActiveLayer(val:TChangeActiveLayerEvent);
    begin Surface.OnChangeActiveLayer:=val; end;
procedure TFreeShip.FSetOnChangeLayerData(Val:TNotifyEvent);
    begin Surface.OnChangeLayerData:=Val;
          if Assigned(OnChangeLayerData) then OnChangeLayerData;
    end;
procedure TFreeShip.FSetOnSelectItem(Val:TNotifyEvent);
    begin Surface.OnSelectItem:=Val; end;

procedure TFreeShip.FSetPrecision(Val:TFreePrecisionType);
begin
   if Val<>FPrecision then begin
      FPrecision:=Val;
      Surface.DesiredSubdivisionLevel:=Ord(Precision)+1;
      FileChanged:=True;
      Build:=False;
      Redraw;
   end;
end;

function TFreeShip.FGetPreview:TJPEGImage;
   procedure Resample1(var source,Target:TBitmap;Width,Height:integer);
   var I,J,W,H, Row1,Row2, Col1,Col2: Integer;
       U,V,S,T, R1,G1,B1, R2,G2,B2  : TFloatType;
       DestPix,SourceRow1,SourceRow2: pRGBTripleArray;
   begin
      W:=Width-1;
      H:=Height-1;
      if Target.Width<>Width then Target.Width:=Width;
      if Target.Height<>Height then Target.Height:=Height;
      for I:=0 to H do begin
         u:=I/H;
         S:=u*(Source.Height-1);
         Row1:=trunc(S);
         if Row1<0 then Row1:=0 else if Row1>Source.Height-2 then Row1:=Source.Height-2;
         Row2:=Row1+1;
         S:=(S-Row1)/(Row2-Row1);
         DestPix:=Target.ScanLine[I];
         SourceRow1:=Source.ScanLine[Row1];
         SourceRow2:=Source.ScanLine[Row2];
         for J:=0 to W-1 do begin
            V:=J/W;
            T:=V*(Source.Width-1);
            Col1:=Trunc(T);
            if Col1<0 then Col1:=0 else if Col1>Source.Width-2 then Col1:=Source.Width-2;
            Col2:=Col1+1;
            T:=(T-Col1)/(Col2-Col1);
            R1:=SourceRow1^[Col1].rgbtRed+S*(SourceRow2^[Col1].rgbtRed-SourceRow1^[Col1].rgbtRed);
            G1:=SourceRow1^[Col1].rgbtGreen+S*(SourceRow2^[Col1].rgbtGreen-SourceRow1^[Col1].rgbtGreen);
            B1:=SourceRow1^[Col1].rgbtBlue+S*(SourceRow2^[Col1].rgbtBlue-SourceRow1^[Col1].rgbtBlue);
            R2:=SourceRow1^[Col2].rgbtRed+S*(SourceRow2^[Col2].rgbtRed-SourceRow1^[Col2].rgbtRed);
            G2:=SourceRow1^[Col2].rgbtGreen+S*(SourceRow2^[Col2].rgbtGreen-SourceRow1^[Col2].rgbtGreen);
            B2:=SourceRow1^[Col2].rgbtBlue+S*(SourceRow2^[Col2].rgbtBlue-SourceRow1^[Col2].rgbtBlue);
            DestPix^[J].rgbtRed:=Round(R1+T*(R2-R1));
            DestPix^[J].rgbtgreen:=Round(G1+T*(G2-G1));
            DestPix^[J].rgbtBlue:=Round(B1+T*(B2-B1));
         end;
      end;
   end;
   procedure Resample(var source,Target:TBitmap;Width,Height:integer);
   var Bmp1: TBitmap;
       I,J : Integer;
       Row1,Row2: pRGBTripleArray;
   begin
      Bmp1:=TBitmap.Create;
      Bmp1.PixelFormat:=pf24bit;
      Resample1(Source,Bmp1,Width,Height);
      Target.PixelFormat:=pf24bit;
      if Target.Width<>Width then Target.Width:=Width;
      if Target.Height<>Height then Target.Height:=Height;

      StretchBlt(Target.Canvas.Handle,0,0,Target.Width,Target.Height,
                 Source.Canvas.Handle,0,0,Source.Width,Source.Height,SRCCOPY);
      // interpolate between the two images to get the best interpolation
      for I:=1 to Target.Height do begin
         Row1:=Bmp1.ScanLine[I-1];
         Row2:=Target.ScanLine[I-1];
         for J:=0 to Target.Width-1 do begin
            Row2^[J].rgbtRed:=  (4*Row1^[J].rgbtRed  +Row2^[J].rgbtRed) div 5;
            Row2^[J].rgbtGreen:=(4*Row1^[J].rgbtGreen+Row2^[J].rgbtGreen) div 5;
            Row2^[J].rgbtBlue:= (4*Row1^[J].rgbtBlue +Row2^[J].rgbtBlue) div 5;
         end;
      end;
      Bmp1.Destroy;
   end;
   Procedure SnapShot(xpos: integer; ypos: integer;OrgWidth,OrgHeight:integer; Var Bmp:TBitmap);
   const DesW = 400;
         DesH = 300;
   Var dc      : HDC;
       lpPal   : PLOGPALETTE;
       W,H     : Integer;
       TmpBmp  : TBitmap;
   Begin
      TmpBmp:=TBitmap.Create;
      TmpBmp.PixelFormat:=pf24bit;
      If ((OrgWidth=0) Or (OrgHeight = 0)) Then exit;
      TmpBmp.Width:=OrgWidth;
      TmpBmp.Height:=OrgHeight;
      dc := GetDc(0);
      If (dc = 0) Then exit;
      If (GetDeviceCaps(dc, RASTERCAPS) And RC_PALETTE = RC_PALETTE) Then Begin
         GetMem(lpPal, sizeof(TLOGPALETTE) + (255 * sizeof(TPALETTEENTRY)));
         FillChar(lpPal^, sizeof(TLOGPALETTE) + (255 * sizeof(TPALETTEENTRY)), #0);
         lpPal^.palVersion := $300;
         lpPal^.palNumEntries := GetSystemPaletteEntries(dc, 0, 256, lpPal^.palPalEntry);
         If (lpPal^.PalNumEntries <> 0) Then TmpBmp.Palette := CreatePalette(lpPal^);
         FreeMem(lpPal, sizeof(TLOGPALETTE) + (255 * sizeof(TPALETTEENTRY)));
      End;
      BitBlt(TmpBmp.Canvas.Handle,0,0,OrgWidth,OrgHeight,Dc,xpos,ypos,SRCCOPY);
      if OrgWidth/OrgHeight>4/3 then begin
         W:=DesW;
         H:=round(W*OrgHeight/OrgWidth);
      end else begin
         H:=DesH;
         W:=Round(H*OrgWidth/OrgHeight);
      end;
      Resample(TmpBmp,Bmp,W,H);
      ReleaseDc(0, dc);
      TmpBmp.Destroy;
   End;{SnapShot}

var Tmp:TBitmap;
begin
   Tmp:=TBitmap.create;
   Tmp.PixelFormat:=pf24bit;
   Snapshot(Application.MainForm.Left,
            Application.MainForm.Top,
            Application.MainForm.Width,
            Application.MainForm.Height,Tmp);
   Result:=TJPEGImage.Create;
   Result.Assign(Tmp);
   Result.CompressionQuality:=90;           //Result.SaveToFile('c:\test.jpg');
   Tmp.Destroy;
end;

procedure TFreeShip.AddViewport(Viewport:TFreeViewport);
// Add a viewport to the list of viewports connected to the model
begin
   if FViewports.IndexOf(Viewport)=-1 then begin
      Viewport.Color:=Preferences.ViewportColor;
      FViewports.Add(Viewport);
      Viewport.ZoomExtents;
   end;
end;

function TFreeShip.AdjustMarkers:Boolean;
begin Result:=False;
   if NumberofMarkers>0 then
    Result:=MessageDlg(Userstring(180)+'?',mtInformation,[mbYes,mbNo],0)=mrYes;
end;

constructor TFreeShip.Create( AOwner:TComponent );
begin
   Inherited Create( AOwner );
   FIntersectionDialog:=TFreeIntersectionDialog.Create(self);
   FEdit:=TFreeEdit.Create(Self);
   FPreferences:=TFreePreferences.Create(self);
   FPreferences.Load;
   FProjectSettings:=TFreeProjectSettings.Create(self);
   FFileVersion:=CurrentVersion;
   FActiveControlPoint:=nil;
   FSurface:=TFreeSubdivisionSurface.Create;
   FSurface.LayerColor:=FPreferences.LayerColor;
   FViewports:=TFasterList.Create;
   FMarkers:=TFasterList.Create;
   FVisibility:=TFreeVisibility.Create(self);
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
   FDesignHydrostatics:=TFreeHydrostaticCalc.Create(self);
   ClearUndo;
   Clear;
   FControlpointForm:=TFreeControlPointForm.Create(Self);
   FControlpointForm.FreeShip:=self;
end;

procedure TFreeShip.DeleteViewport(Viewport:TFreeViewport);
var Index:integer;
begin
   Index:=FViewports.IndexOf(Viewport);
   if Index<>-1 then FViewports.Delete(index);
end;

procedure TFreeShip.Clear;
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
   for I:=1 to NumberOfMarkers do Marker[I-1].Destroy; FMarkers.Clear;
   FSelectedMarkers.Clear;
   // delete stations
   for I:=1 to NumberOfStations do Station[I-1].Destroy; FStations.Clear;
   // delete Buttocks
   for I:=1 to NumberOfButtocks do Buttock[I-1].Destroy; FButtocks.Clear;
   // delete Waterlines
   for I:=1 to NumberOfWaterlines do Waterline[I-1].Destroy; FWaterlines.Clear;
   // delete Diagonals
   for I:=1 to NumberOfDiagonals do Diagonal[I-1].Destroy;
   for I:=1 to NumberOfHydrostaticCalculations do HydrostaticCalculation[I-1].Calculated:=false;
   FDiagonals.Clear;
   FProjectSettings.Clear;
   FFilenameSet:=False;
//## FStopAskingForFileVersion:=False;
(*##*) Fillchar(FResistanceDelftData,SizeOf(FResistanceDelftData),0);
(*##*) Fillchar(FResistanceKaperData,SizeOf(TFreeKAPERResistanceData),0);
   // Delete backgroundimages
   for I:=1 to NumberofBackgroundImages do BackgroundImage[I-1].Destroy;
   FBackGroundImages.Clear;
   // Clear flowlines
   for I:=1 to NumberOfFlowlines do Flowline[I-1].Destroy;
   FFlowlines.clear;
   FSelectedFlowlines.Clear;
   if not (csDestroying in componentState) then begin // remove backgroundimages from viewports
      Pt.X:=0;
      Pt.Y:=0;
      for I:=1 to NumberOfViewports do
         Viewport[I-1].BackgroundImage.AssignData(nil,fvPerspective,Pt,1.0,False,clBlack,255,100,3,True);
      if assigned(FOnFileChanged) then FOnFileChanged(self);
      if Assigned(OnUpdateGeometryInfo) then OnUpdateGeometryInfo(self);
   end;
end;

procedure TFreeShip.ClearUndo; Var I : integer;
begin // clear undo
   for I:=1 to UndoCount do UndoObject[I-1].Destroy;
   FUndoObjects.Clear;
   FUndoPosition:=0;
   FPreviousUndoPosition:=FUndoPosition-1;
   if not (csdestroying in componentstate) then
      if Assigned(FOnUpdateUndoData) then FOnUpdateUndoData(self);
end;

destructor TFreeShip.Destroy;
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

procedure TFreeShip.Draw;
var I : integer;
begin // Redraws model to all viewports by re-initializing all viewports
   For I:=1 to NumberOfViewports do Viewport[I-1].ZoomExtents;
   if LinesplanFrame<>nil then begin
      TFreeLinesplanframe(LinesplanFrame).Viewport.ZoomExtents;
   end;
end;

procedure TFreeShip.DrawToViewport(Viewport:TFreeViewport);
var I,Size,LegendHeight,LegendWidth,RectHeight,Nrect,NDecimal: integer;
    Plane: T3DPlane;
    Curve: TFreeSpline;
    P    : T3DVector;
    Pt   : TPoint;
    Str  : string;
    Rect : TRect;
    R,G,B: Byte;
    Tmp  : TFloatType;

    procedure DrawPoint(P:T3DVector;Text:string;CompensateHeight:boolean);
    var Pt: TPoint; Size: Integer;
    begin
      if CompensateHeight then P.Z:=P.Z+FDesignHydrostatics.FData.ModelMin.Z;
      Pt:=Viewport.Project(P);
      Viewport.FontName:='Arial';
      Viewport.FontColor:=Preferences.HydrostaticsFontColor;
      size:=Round(Sqrt(Viewport.Zoom)*7);
      if size<2 then size:=2;
      Viewport.FontSize:=size;
      Size:=Round(Sqrt(Viewport.Zoom)*(Preferences.PointSize+1));
      if size<1 then size:=1;
      Viewport.BrushStyle:=bsClear;
//    if Viewport.Printing then Size:=round(Size*Viewport.PrintResolution/150);
      Viewport.PenColor:=clDkGray;//Black;
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
    end;{DrawPoint}

    procedure DrawGrid;
    var DrawStations,DrawButtocks,DrawWaterlines,DrawDiagonals: Boolean;
        Min,Max,P1,P2,Diff: T3DVector;
        I,J,N,Height,Width: integer;
        Position: TFloatType;
        Pt1,Pt2: TPoint;
        Str: string;
        Pts: array of TPoint;

        procedure SetFontHeight(DesiredHeight:TFloatType);
        var Height: TFloatType; CurrentHeight: integer;
        begin                  // Sets the fontheight to a height in modelspace
           Height:=DesiredHeight*Viewport.Scale*Viewport.Zoom;
           Viewport.Canvas.Font.Size:=8;
           CurrentHeight:=Viewport.Canvas.TextHeight('X');
           while CurrentHeight>Height do begin
              Viewport.Canvas.Font.Size:=Viewport.Canvas.Font.Size-1;
              CurrentHeight:=Viewport.Canvas.TextHeight('X');
              if Viewport.Canvas.Font.Size<4 then break;
           end;
        end;{SetFontHeight}
    begin
       DrawStations:=Viewport.ViewType<>fvBodyplan;
       DrawButtocks:=Viewport.ViewType<>fvProfile;
       DrawWaterlines:=Viewport.ViewType<>fvPlan;
       DrawDiagonals:=Viewport.ViewType=fvBodyplan;
       // Blowup the boundary box by 3%
       Diff:=ScalePoint(0.03,Viewport.Max3D-Viewport.Min3D);
       Min:=Viewport.Min3D-Diff;
       Diff:=ScalePoint(-1.0,Diff);
       Max:=Viewport.Max3D-diff;
       if DrawStations
       or DrawButtocks
       or DrawWaterlines
       or DrawDiagonals then begin
          Viewport.PenColor:=Preferences.GridColor;
          Viewport.FontName:='Arial';
          Viewport.FontColor:=Preferences.GridFontColor; // calculate and set fontheight
          SetFontHeight(Abs(Min-Max)/FontheightFactor);
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
                Viewport.Canvas.TextOut(Pt2.X-width div 2,Pt2.Y-Height,Str);
             end else begin
               Viewport.Canvas.TextOut(Pt1.X-Width,Pt1.Y-Height,str);
               Viewport.Canvas.TextOut(Pt2.X,Pt2.Y-Height,Str);
             end;
             Viewport.PenWidth:=1;
             Viewport.FontColor:=Preferences.GridFontColor;
          end;
          if Viewport.Viewtype<>fvPlan then begin
             Viewport.FontColor:=clRed;
             // Draw baseline
             Viewport.PenWidth:=2;
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
             Viewport.Canvas.TextOut(Pt1.X,Pt1.Y-Height,Str);
             Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
             // Draw dwl
//##         if ProjectSettings.FMainparticularsHasBeenset then
             begin
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
                Viewport.Canvas.TextOut(Pt1.X-width div 2,Pt1.Y-Height,Str);
                Viewport.Canvas.TextOut(Pt2.X-Width div 2,Pt2.Y-Height,str);
             end;
             Viewport.PenWidth:=1;
             Viewport.FontColor:=Preferences.GridFontColor;
          end;
          if DrawStations then begin
             P1:=Min;
             P2:=Max;
             for I:=1 to self.NumberofStations do begin
                Position:=-Station[I-1].Plane.d;
                Str:=ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.X:=Position;
                P2.X:=P1.X;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
                Viewport.Canvas.TextOut(Pt1.X,Pt1.Y,Str);
                Viewport.Canvas.TextOut(Pt2.X,Pt2.Y-Height,Str);
             end;
          end;
          if DrawDiagonals then begin
             Setlength(Pts,101);
             Viewport.PenWidth:=1;
             for I:=1 to NumberOfDiagonals do begin
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
             for I:=1 to self.NumberofButtocks do begin
                Position:=-Buttock[I-1].Plane.d;
                Str:=ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.Y:=Position;
                P2.Y:=P1.Y;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
                if Viewport.ViewType=fvBodyplan then Width:=0
                                                else Width:=Viewport.Canvas.TextWidth(Str);
                if Viewport.ViewType=fvBodyplan then begin
                   Viewport.Canvas.TextOut(Pt1.X,Pt1.Y,Str);
                   Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
                end else
                begin
                  Viewport.Canvas.TextOut(Pt1.X,Pt1.Y-Height,Str);
                  Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
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
                     Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
                  end else begin
                     Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y,str);
                     Viewport.Canvas.TextOut(Pt1.X,Pt1.Y,Str);
                  end;
                end;
             end;
          end;
          if DrawWaterlines then begin
             P1:=Min;
             P2:=Max;
             for I:=1 to self.NumberofWaterlines do begin
                Position:=-Waterline[I-1].Plane.d;
                Str:=ConvertDimension(Position,ProjectSettings.ProjectUnits);
                P1.Z:=Position;
                P2.Z:=P1.Z;
                Pt1:=Viewport.Project(P1);
                Pt2:=Viewport.Project(P2);
                Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
                Width:=Viewport.Canvas.TextWidth(Str);
                Viewport.Canvas.TextOut(Pt1.X,Pt1.Y-Height,Str);
                Viewport.Canvas.TextOut(Pt2.X-Width,Pt2.Y-Height,str);
             end;
          end;
                                     // Draw Split Section (formerly Mainframe)
          if not (Viewport.Viewtype in [fvBodyplan,fvPerspective]) then begin
            Viewport.FontColor:=clBlue;
            Viewport.PenColor:=clBlue;
            Viewport.PenWidth:=1;
            P1:=Vector( Projectsettings.MidleFrame,Min.Y,Min.Z );
            P2:=Vector( Projectsettings.MidleFrame,Max.Y,Max.Z );
            Position:=Projectsettings.MidleFrame;
//          Str:='Split Section:'+ConvertDimension( Position,ProjectSettings.ProjectUnits );
            Str:=UserString(1671)+': '+ConvertDimension( Position,ProjectSettings.ProjectUnits );
            Pt1:=Viewport.Project( P1 );
            Pt2:=Viewport.Project( P2 );
            Viewport.CanVas.MoveTo(Pt1.X,Pt1.Y+30);
            Viewport.CanVas.LineTo(Pt2.X,Pt2.Y-20);
            Width:=Viewport.CanVas.TextWidth(Str);
            Viewport.CanVas.TextOut(Pt1.X,Pt1.Y-Height+30,Str);
            Viewport.CanVas.TextOut(Pt2.X-Width,Pt2.Y-Height-20,str);
          end;
       end;
    end;{DrawGrid}
begin
   if not Surface.Build then surface.Rebuild;
   // Draw intersectionlines BEFORE the surface is drawn,
   // so that the controlnet appears on top
   // But the intersections that should be drawn last depends on the view
   Surface.MainframeLocation:=Projectsettings.MidleFrame;
   if Viewport.Viewtype<>fvPerspective then begin
      if Visibility.ShowGrid then begin // Draws a rectangular grid with measurements, bigger then the hull
         Drawgrid;
      end else begin               // draws the actual splines as a dashed line
         if Viewport.ViewType<>fvBodyplan then if Visibility.ShowStations then for I:=1 to NumberOfStations do Station[I-1].Draw(Viewport);
         if Viewport.ViewType<>fvProfile then if Visibility.ShowButtocks then for I:=1 to NumberOfButtocks do Buttock[I-1].Draw(Viewport);
         if Viewport.ViewType<>fvPlan then if Visibility.ShowWaterlines then for I:=1 to NumberOfWaterlines do Waterline[I-1].Draw(Viewport);
         if Visibility.ShowDiagonals then for I:=1 to NumberOfDiagonals do Diagonal[I-1].Draw(Viewport);
      end;
      if (Viewport.ViewType=fvBodyplan) and (Visibility.ShowStations) then for I:=1 to NumberOfStations do Station[I-1].Draw(Viewport);
      if (Viewport.ViewType=fvProfile) and (Visibility.ShowButtocks) then for I:=1 to NumberOfButtocks do Buttock[I-1].Draw(Viewport);
      if (Viewport.ViewType=fvPlan) and (Visibility.ShowWaterlines) then for I:=1 to NumberOfWaterlines do Waterline[I-1].Draw(Viewport);
      if (Viewport.ViewType<>fvBodyplan) and (Visibility.ShowDiagonals) then for I:=1 to NumberOfDiagonals do Diagonal[I-1].Draw(Viewport);
   end else begin
      if Visibility.ShowStations then for I:=1 to NumberOfStations do Station[I-1].Draw(Viewport);
      if Visibility.ShowButtocks then for I:=1 to NumberOfButtocks do Buttock[I-1].Draw(Viewport);
      if Visibility.ShowWaterlines then for I:=1 to NumberOfWaterlines do Waterline[I-1].Draw(Viewport);
      if Visibility.ShowDiagonals then for I:=1 to NumberOfDiagonals do Diagonal[I-1].Draw(Viewport);
   end;
   if (Visibility.ShowMarkers) and (Viewport.ViewportMode=vmWireframe)then for I:=1 to NumberOfMarkers do Marker[I-1].Draw(Viewport);
   Surface.Color:=clDkGray;
   Surface.ShowControlNet:=Visibility.ShowControlNet;
   Surface.ShowInteriorEdges:=Visibility.ShowInteriorEdges;
   Surface.DrawMirror:=Visibility.ModelView=mvBoth;
   Surface.ShowNormals:=Visibility.ShowNormals;
   Surface.ControlPointSize:=Preferences.PointSize;
   Surface.CreaseColor:=Preferences.CreaseColor;
   Surface.CreaseEdgeColor:=Preferences.CreaseEdgeColor;
   Surface.EdgeColor:=Preferences.EdgeColor;
   Surface.CreasePointColor:=Preferences.CreasePointColor;
   Surface.RegularPointColor:=Preferences.RegularPointColor;
   Surface.CornerPointColor:=Preferences.CornerPointColor;
   Surface.DartPointColor:=Preferences.DartPointColor;
   Surface.Selectedcolor:=Preferences.SelectColor;
   Surface.LayerColor:=Preferences.LayerColor;
   Surface.NormalColor:=Preferences.NormalColor;
   Surface.LeakColor:=Preferences.LeakPointColor;
   Surface.CurvatureColor:=Preferences.CurvaturePlotColor;
   Surface.ShowCurvature:=Visibility.ShowCurvature;
   Surface.CurvatureScale:=Visibility.CurvatureScale;
   Surface.ShowControlCurves:=Visibility.ShowControlCurves;
   Surface.ControlCurveColor:=Preferences.ControlCurveColor;
   Surface.ZebraColor:=Preferences.ZebraStripeColor;
   if ProjectSettings.ProjectShadeUnderwaterShip then begin
      Plane.a:=0.0;
      Plane.b:=0.0;
      Plane.c:=1.0;
      Plane.d:=-(FindLowestHydrostaticsPoint+ProjectSettings.ProjectDraft);
      Surface.WaterlinePlane:=Plane;
      Surface.UnderWaterColor:=ProjectSettings.ProjectUnderWaterColor;
      Surface.ShadeUnderWater:=True;
   end else Surface.ShadeUnderWater:=False;
   Surface.Draw(Viewport);
   if (Viewport.Viewtype<>fvPerspective)
   and (Viewport.ViewportMode<>vmWireframe)
   and (Visibility.ShowGrid) then begin
      // Shaded viewport is a special case when visibility.drawgrid has been set to tru
      if Visibility.ShowStations then for I:=1 to NumberOfStations do Station[I-1].Draw(Viewport);
      if Visibility.ShowButtocks then for I:=1 to NumberOfButtocks do Buttock[I-1].Draw(Viewport);
      if Visibility.ShowWaterlines then for I:=1 to NumberOfWaterlines do Waterline[I-1].Draw(Viewport);
      if Visibility.ShowDiagonals then for I:=1 to NumberOfDiagonals do Diagonal[I-1].Draw(Viewport);
   end;
   if (Viewport.ViewportMode=vmWireframe)
   and (Visibility.ShowHydrostaticData) then begin     // Draw hydrostatic data
      if FDesignHydrostatics.Draft<>ProjectSettings.ProjectDraft then FDesignHydrostatics.Draft:=ProjectSettings.ProjectDraft;
      if not FDesignHydrostatics.Calculated then FDesignHydrostatics.Calculate;
//    if FDesignHydrostatics.Errors=[] then
      begin
         // Center of bouyancy
         if Visibility.FShowHydrostDisplacement then
            DrawPoint(FDesignHydrostatics.FData.CenterOfBuoyancy,'Displ='+FloatToStrF(FDesignHydrostatics.Data.Displacement,ffFixed,7,2),True);
         // Transverse metacentric height
         if Visibility.FShowHydrostMetacentricHeight then
            DrawPoint(Vector(FDesignHydrostatics.FData.CenterOfBuoyancy.X,0.0,FDesignHydrostatics.FData.KMtransverse),'KM='+FloatToStrF(FDesignHydrostatics.Data.KMtransverse,ffFixed,7,2),True);
         // Longitudinal center of floatation
         if Visibility.FShowHydrostLCF then
            DrawPoint(FDesignHydrostatics.FData.WaterplaneCOG,'LCF='+FloatToStrF(FDesignHydrostatics.Data.WaterplaneCOG.X,ffFixed,7,2),False);
         // Lateral center
         if Visibility.FShowHydrostLateralArea then DrawPoint(FDesignHydrostatics.FData.LateralCOG,Userstring(29)+'='+FloatToStrF(FDesignHydrostatics.Data.LateralArea,ffFixed,7,2),True);
         if (Viewport.ViewType=fvProfile)
         and (Visibility.FShowHydrostSectionalAreas) then begin // draw sectionalarea curve
            Curve:=TFreespline.Create;
            for I:=1 to length(FDesignHydrostatics.FData.SAC) do begin
               P.X:=FDesignHydrostatics.FData.SAC[I-1].X;
               P.Y:=0;
               if (FDesignHydrostatics.FData.BeamWaterline*FDesignHydrostatics.Draft)<>0
                  then P.Z:=2*(FDesignHydrostatics.FData.ModelMax.Z-FDesignHydrostatics.FData.ModelMin.Z)*FDesignHydrostatics.FData.SAC[I-1].Y/(FDesignHydrostatics.FData.BeamWaterline*FDesignHydrostatics.Draft)
                  else P.Z:=FDesignHydrostatics.FData.SAC[I-1].Y;
               P.Z:=P.Z+FDesignHydrostatics.FData.ModelMin.Z;
               Curve.Add(P);
            end;
            Curve.Color:=Preferences.HydrostaticsFontColor;
            Curve.Draw(Viewport);
            for I:=1 to Curve.NumberOfPoints do begin
               P:=Curve.Point[I-1];
               Pt:=Viewport.Project(P);
               Size:=round(Sqrt(Viewport.Zoom)*3);
               if Size<1 then Size:=1;
               Viewport.Canvas.MoveTo(Pt.X,Pt.Y-Size);
               Viewport.Canvas.LineTo(Pt.X,Pt.Y+Size);
               Viewport.Canvas.MoveTo(Pt.X-Size,Pt.Y);
               Viewport.Canvas.LineTo(Pt.X+Size,Pt.Y);
               Str:=FloatToStrF(FDesignHydrostatics.FData.SAC[I-1].Y,ffFixed,7,2);
               if P.X<FProjectsettings.MidleFrame
                  then Viewport.Canvas.TextOut(Pt.X-Viewport.Canvas.TextWidth(str),Pt.Y-Viewport.Canvas.TextHeight(str),Str)
                  else Viewport.Canvas.TextOut(Pt.X,Pt.Y-Viewport.Canvas.TextHeight(str),Str);
            end;
            Curve.Destroy;
         end;
      end;
   end;                                                        // Drawflowlines
   if Visibility.ShowFlowlines then
      For I:=1 to NumberOfFlowlines do Flowline[I-1].Draw(Viewport);
   if (Viewport.ViewportMode=vmShadeGauss)
   and (Surface.NumberOfControlFaces>0)
   and (Surface.MaxGaussCurvature-Surface.MinGaussCurvature>1e-7) then begin
      // Draw Legend with Gaussian curvature values
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
      Viewport.FontName:='Arial';
      Viewport.FontSize:=8;
      Viewport.FontColor:=Preferences.GridFontColor;
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
               Str:=FloatToStrF(Surface.MinGaussCurvature*Tmp,ffFixed,7,NDecimal);
            end else if Tmp<0.5 then begin
               Tmp:=2*(0.5-Tmp);
               Str:=FloatToStrF(Surface.MaxGaussCurvature*Tmp,ffFixed,7,NDecimal);
            end else Str:='0.0';
            Viewport.Canvas.TextOut(Rect.Right+5,(Rect.Top+Rect.Bottom-Viewport.Canvas.TextHeight(str)) div 2,Str);
         end;
         Rect.Top:=Rect.Top+RectHeight;
      end;
   end;
end; {TFreeShip.DrawToViewport}

procedure TFreeShip.Extents(Var Min,Max:T3DVector);
// calculate the bounding box coordinates of the model
var I : integer;
begin
   if Surface.NumberOfControlFaces>0 then begin
      Surface.DrawMirror:=Visibility.ModelView=mvBoth;
      Min.X:=1e6;
      Min.Y:=Min.X;
      Min.Z:=Min.X;
      Max.X:=-Min.X;
      Max.Y:=-Min.Y;
      Max.Z:=-Min.Z;
      Surface.Extents(Min,Max);
      if Visibility.ShowMarkers then for I:=1 to NumberOfMarkers do Marker[I-1].Extents(Min,Max);
   end else begin
      if Surface.NumberOfControlPoints>1 then begin
         for I:=1 to Surface.NumberOfControlPoints do begin
            if I=1 then begin
               Min:=Surface.ControlPoint[I-1].Coordinate;
               Max:=Min;
            end else begin
               MinmAx(Surface.ControlPoint[I-1].Coordinate,Min,Max);
            end;
         end;
      end else begin
         Min.X:=-1;
         Min.Y:=Min.X;
         Min.Z:=Min.X;
         Max.X:=-Min.X;
         Max.Y:=Max.X;
         Max.Z:=Max.X;
      end;
   end;
end;

function TFreeShip.FindLowestHydrostaticsPoint:TFloatType;
var I,J     : Integer;
    First   : Boolean;
    Layer   : TFreeSubdivisionLayer;
begin
   Result:=Surface.Min.Z;
   First:=True;
   for I:=1 to NumberOfLayers do begin
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

// imports a number of longitudinally lines and creates developable surfaces between each two subsequent chines
procedure TFreeShip.ImportChines( Np:Integer;Chines:TFasterList );
var I,J        : integer;
    P,Min,Max  : T3DVector;
    Pts,Pts2,Tmp: TFasterList;
    Points     : array of array of TFreeSubdivisionControlPoint;
    Curve      : TFreeSubdivisionControlCurve;
    Point      : TFreeSubdivisionControlPoint;
    Edge       : TFreeSubdivisionControlEdge;
    Layer      : TFreeSubdivisionLayer;
    Spline     : TFreeSpline;
    Marker     : TFreeMarker;
    Matrix,Inv,OrgPts,NewPts: TFreeMatrix;
begin
// try
      for I:=1 to Chines.Count-1 do begin
         if I<=Surface.NumberOfLayers then Layer:=Surface.Layer[I-1]
                                      else Layer:=Surface.AddNewLayer;
         Layer.Name:=Userstring(186)+#32+IntToStr(I);
         Layer.Developable:=True;
      end;                 // add special layer to close the hull at centerline
      Layer:=Surface.AddNewLayer;
      Layer.Name:=Userstring(187);
      Setlength(Points,Np);                                 // Prepare matrices
      Matrix:=TFreeMatrix.Create;
      Matrix.SetSize(Np,Np);
      Matrix.Fill(0.0);
      Matrix.Value[0,0]:=1.0;
      for I:=2 to Np-1 do begin
         Matrix.Value[I-1,I-2]:=1/6;
         Matrix.Value[I-1,I-1]:=2/3;
         Matrix.Value[I-1,I  ]:=1/6;
      end;
      Matrix.Value[Np-1,Np-1]:=1.0;                            // Invert matrix
      Inv:=Matrix.Invert;
      Matrix.Destroy;

      OrgPts:=TFreeMatrix.Create;
      OrgPts.SetSize(3,Np);

      for I:=1 to Np do Setlength(Points[I-1],Chines.Count);
      for I:=1 to Chines.Count do begin
         Spline:=Chines[I-1];
         OrgPts.Fill(0.0);
         for J:=1 to Np do begin
            P:=Spline.Value((J-1)/(Np-1));
            OrgPts.Value[J-1,0]:=P.X;
            OrgPts.Value[J-1,1]:=P.Y;
            OrgPts.Value[J-1,2]:=P.Z;
         end;
         // calculate new points
         NewPts:=Inv.Multiply(OrgPts);
         for J:=1 to Np do begin
            P.X:=NewPts.Value[J-1,0];
            P.Y:=NewPts.Value[J-1,1];
            if P.Y<0 then P.Y:=0;
            P.Z:=NewPts.Value[J-1,2];
            if (I=1) and (J=1) then begin
               Min:=P;
               Max:=Min;
            end else MinMax(P,Min,Max);
            Points[J-1][I-1]:=Surface.AddControlPoint(P);
         end;
         NewPts.Destroy;
      end;
      OrgPts.Destroy;                                 // Delete inverted matrix
      Inv.Destroy;                                    // Add chines as markers
      for I:=1 to Chines.Count do begin
         Spline:=Chines[I-1];
         Marker:=TFreeMarker.Create;
         Marker.FOwner:=self;
         Edit.Marker_Add(Marker);
         for J:=1 to Spline.NumberOfPoints do begin
            Marker.Add(Spline.Point[J-1]);
            Marker.Knuckle[J-1]:=Spline.Knuckle[J-1];
         end;
      end;                                                // Setup controlfaces
      Pts:=TFasterlist.Create;
      for I:=2 to Np do
      for J:=2 to Chines.Count do begin Pts.Clear;
        Point:=Points[I-1][J-1]; if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
        Point:=Points[I-2][J-1]; if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
        Point:=Points[I-2][J-2]; if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
        Point:=Points[I-1][J-2]; if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
        if Pts.Count>2 then Surface.AddControlFace(Pts,True,Surface.Layer[J-2]);
      end;
      for I:=2 to Np do begin
         for J:=1 to Chines.Count do begin
            Edge:=Surface.EdgeExists(Points[I-2][J-1],Points[I-1][J-1]) as TFreeSubdivisionControlEdge;
            if Edge<>nil then Edge.Crease:=True;
         end;
      end;
      // Add controlcurves
      for J:=1 to Chines.Count do begin
         Curve:=TFreeSubdivisionControlCurve.Create(Surface);
         Surface.AddControlCurve(Curve);
         for I:=1 to Np do begin
            Curve.AddPoint(Points[I-1][J-1]);
            if I>1 then begin
               Edge:=Surface.EdgeExists(Points[I-2][J-1],Points[I-1][J-1]) as TFreeSubdivisionControlEdge;
               if Edge<>nil then Edge.Curve:=Curve;
            end;
         end;
      end;
      // Check for stem, keel and stern points to be closed
      Pts.Clear;                                                 // first stern
      for I:=Chines.Count downto 2 do Pts.Add(Points[Np-1][I-1]);  // then keel
      for I:=Np downto 1 do Pts.Add(Points[I-1][0]);        // and finally stem
      for I:=2 to Chines.Count do Pts.Add(Points[0][I-1]);
      Pts2:=TFasterList.Create;
      for I:=1 to Pts.Count do begin
         Point:=Pts[I-1];
         P:=Point.Coordinate;
         if P.Y<>0.0 then begin
            P.Y:=0;
            Point:=Surface.AddControlPoint(P);
            if Point.Coordinate.Y<>0.0 then Point.Coordinate:=P;
            Pts2.Add(Point);
         end else Pts2.Add(Point);
      end;
      Tmp:=TFasterList.Create;
      for I:=2 to Pts.Count do begin Tmp.Clear;
         if Tmp.IndexOf(Pts2[I-1])=-1 then Tmp.Add(Pts2[I-1]);
         if Tmp.IndexOf(Pts2[I-2])=-1 then Tmp.Add(Pts2[I-2]);
         if Tmp.IndexOf(Pts[I-2]) =-1 then Tmp.Add(Pts[I-2]);
         if Tmp.IndexOf(Pts[I-1]) =-1 then Tmp.Add(Pts[I-1]);
         if Tmp.Count>2 then Surface.AddControlFace(Tmp,False,Layer);
      end;
   // Now check if there are any edges on the bottom panel that are created by extruding the
   // bottom points and whose crease properties are set to true. This causes undesired knuckle in the bottompanel
      {
      for I:=Np-1 downto 2 do begin
         Point:=Points[I-1][0];
         if Point.Coordinate.Y>0 then begin
            for J:=1 to point.NumberOfEdges do begin
               Edge:=Point.Edge[J-1] as TFreeSubdivisionControlEdge;
               if ((Edge.Crease) and (Edge.StartPoint=Point) and (abs(Edge.EndPoint.Coordinate.Y)<1e-5)) or
                  ((Edge.Crease) and (Edge.EndPoint=Point) and (abs(Edge.StartPoint.Coordinate.Y)<1e-5)) then Edge.Crease:=False;
            end;
         end;
      end;
      }
      // set transom as knuckle
      for J:=2 to Chines.Count do begin
         Edge:=Surface.EdgeExists(Points[Np-1][J-2],Points[Np-1][J-1]) as TFreeSubdivisionControlEdge;
         if Edge<>nil then Edge.Crease:=true;
      end;
      // Delete unused layers;
      Edit.Layer_DeleteEmpty(True);
      // delete unused controlpoints
      for I:=Surface.NumberOfControlPoints downto 1 do if Surface.ControlPoint[I-1].NumberOfFaces=0 then Surface.ControlPoint[I-1].Delete;
      Tmp.Destroy;
      Pts2.Destroy;
      Pts.Destroy;
// finally
      Extents(Min,Max);
      //ProjectSettings.ProjectWaterDensity:=1.0;
      ProjectSettings.ProjectBeam:=2*Max.Y;
      ProjectSettings.ProjectLength:=Max.X-Min.X;
      ProjectSettings.ProjectDraft:=1.0;
      Build:=False;
      Precision:=fpHigh;
      Draw;
      FileChanged:=true;
      for I:=1 to Chines.Count do begin
         Spline:=Chines[I-1];
         Spline.Destroy;
      end;
//   end;
end; {TFreeShip.ImportChines}

// loads the preview image from a file
procedure TFreeShip.LoadPreview(Filename:string;Image:TJPegImage);
var Source: TFreeFileBuffer; I: integer; Str: String;
begin
   Source:=TFreeFileBuffer.Create;
// try
      Source.LoadFromFile(FileName);             // Load everything into memory
      Source.Reset;
      Source.LoadString(Str);
      if Str='FREE!ship' then begin
         Source.LoadTFreeFileVersion(FFileVersion);
         Source.Version:=FFileVersion;
         if FFileVersion>=fv210 then begin
            Source.LoadInteger(I);
            FPrecision:=TFreePrecisionType(I);
            Visibility.LoadBinary(Source);
            ProjectSettings.LoadBinary(Source,Image);
         end;
      end;
// finally
      Source.Destroy;
// end;
end;

procedure TFreeShip.RebuildModel;
var PrevCursor : TCursor;
begin
   PrevCursor:=Screen.Cursor;
   if Screen.Cursor<>crHourglass then Screen.Cursor:=crHourglass;
// try
      Build:=False;
      Surface.DesiredSubdivisionLevel:=Ord(Precision)+1;
      Surface.Rebuild;
      Draw;
// finally
      if Screen.Cursor<>PrevCursor then Screen.Cursor:=PrevCursor;
// end;
end;

procedure TFreeShip.Redraw;
var I : integer;
begin // Redraws model to all viewports using the current min/max coordinates of the boundingbox
   For I:=1 to NumberOfViewports do begin
      if Viewport[I-1].Zoom=1.0 then Viewport[I-1].ZoomExtents
                                else Viewport[I-1].Refresh;
   end;
   if LinesplanFrame<>nil then begin
      TFreeLinesplanframe(LinesplanFrame).Viewport.Refresh;
   end;
end;

procedure TFreeShip.SubmergedHullExtents(Wlplane:T3DPlane;var Min,Max:T3DVector);
var I,J,K,L    : Integer;
    FirstPoint : boolean;
    Layer      : TFreeSubdivisionLayer;
    Face       : TFreeSubdivisionControlFace;
    Child      : TFreeSubdivisionFace;
    P1,P2,P    : T3DVector;
    s1,s2,T    : TFloatType;
begin
   FirstPoint:=True;
   for I:=1 to NumberOfLayers do begin
      Layer:=Surface.Layer[I-1];
      if Layer.UseInHydrostatics then for J:=1 to Layer.Count do begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do begin
            Child:=Face.Child[K-1];
            P1:=Child.Point[Child.NumberOfPoints-1].Coordinate;
            s1:=WlPlane.a*P1.x+WlPlane.b*P1.y+WlPlane.c*P1.z+WlPlane.d;
            for L:=1 to Child.NumberOfpoints do begin
               P2:=Child.Point[L-1].Coordinate;
               s2:=WlPlane.a*P2.x+WlPlane.b*P2.y+WlPlane.c*P2.z+WlPlane.d;
               if ((S1<0) and (S2>0)) or ((S1>0) and (S2<0)) then begin // intersection
                  if S1=S2 then T:=0.5
                           else T:=-s1/(s2-s1);
                  P.X:=P1.X+T*(P2.X-P1.X);
                  P.Y:=P1.Y+T*(P2.Y-P1.Y);
                  P.Z:=P1.Z+T*(P2.Z-P1.Z);
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
      Min:=ZERO;
      Max.X:=1;
      Max.Y:=1;
      Max.Z:=1;
   end;
end;

procedure TFreeShip.KeyUp(Viewport:TfreeViewport;var Key: Word;Shift: TShiftState);
const Left  = 37;
      Right = 39;
      Up    = 38;
      Down  = 40;
var Point      : TFreeSubdivisionControlPoint;
    P          : T3DVector;
begin
   if (Key in [Left..Down]) and (Viewport.ViewType<>fvPerspective) and (ActiveControlPoint<>nil) then
   begin
      Edit.CreateUndoObject(Userstring(190),True);
      Point:=ActiveControlPoint;
      FileChanged:=True;
      Build:=False;
      P:=Point.Coordinate;
      Case Viewport.Viewtype of
         fvProfile : Case Key of
                      Left  : P.X:=P.X-Visibility.CursorIncrement;
                      Up    : P.Z:=P.Z+Visibility.CursorIncrement;
                      Right : P.X:=P.X+Visibility.CursorIncrement;
                      Down  : P.Z:=P.Z-Visibility.CursorIncrement; end;
         fvPlan    : Case Key of
                      Left  : P.X:=P.X-Visibility.CursorIncrement;
                      Up    : P.Y:=P.Y+Visibility.CursorIncrement;
                      Right : P.X:=P.X+Visibility.CursorIncrement;
                      Down  : P.Y:=P.Y-Visibility.CursorIncrement; end;
         fvBodyplan: Case Key of
                      Left  : if P.X<=self.ProjectSettings.MidleFrame
                                 then P.Y:=P.Y+Visibility.CursorIncrement
                                 else P.Y:=P.Y-Visibility.CursorIncrement;
                      Up    : P.Z:=P.Z+Visibility.CursorIncrement;
                      Right : if P.X<=self.ProjectSettings.MidleFrame
                                 then P.Y:=P.Y-Visibility.CursorIncrement
                                 else P.Y:=P.Y+Visibility.CursorIncrement;
                      Down  : P.Z:=P.Z-Visibility.CursorIncrement; end;
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

procedure TFreeShip.MouseDown(Viewport:TFreeViewport;Button:TMouseButton;Shift:TShiftState;X,Y:integer;var ItemSelected:Boolean);
var I,J,Tmp: integer;
    P3D    : T3DVector;
    Point  : TFreeSubdivisionControlPoint;
    Edge   : TFreeSubdivisionControlEdge;
    Curve  : TFreeSubdivisionControlCurve;
    Face   : TFreeSubdivisionControlFace;
    Entity : TFreeSubdivisionBase;
begin
   ItemSelected:=False;
   if Button=mbLeft then begin
      Case EditMode of
         emSelectItems: begin Entity:=nil; I:=1;    // First check the vertices
           while I<=Surface.NumberOfControlPoints do begin
              if Surface.ControlPoint[I-1].Visible then begin
                 Point:=Surface.ControlPoint[I-1];
                 Tmp:=Point.DistanceToCursor(X,Y,Viewport);
                 if Tmp<=SelectDistance then begin
                    Entity:=Point;
                    // Point.Selected:=not Point.Selected;
                    ItemSelected:=True;
                    // Draw the selected point to all viewports
                    for J:=1 to NumberOfViewports do
                      if self.Viewport[J-1].ViewportMode=vmWireframe then
                         Point.Draw(self.Viewport[J-1]);
                    break;
                 end;
              end;  Inc(I);
           end;
           if Entity=nil then begin // No points found, search for nearest controlEdge
              I:=1;
              while I<=Surface.NumberOfControlEdges do begin
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
                       for J:=1 to NumberOfViewports do Self.Viewport[J-1].Refresh;
                       break;
                    end;
                 end;  Inc(I);
              end;
           end;
           if (Entity=nil) and (Visibility.ShowInteriorEdges) then begin
              Surface.ShowInteriorEdges:=True; // No edges found, search for nearest control-face
              I:=1;
              while I<=Surface.NumberOfControlFaces do begin
                 if Surface.ControlFace[I-1].Visible then begin
                    Face:=Surface.ControlFace[I-1];
                    Tmp:=Face.DistanceToCursor(X,Y,P3D,Viewport);
                    if Tmp<=SelectDistance then begin
                       Entity:=Face;
                       Face.Selected:=not Face.Selected;
                       // If CTRL key is pressed, select all connected controlfaces that
                       // belong to the same layer and are not separated by a crease edge
                       // and have the same selected state
                       if (ssCtrl in shift) then
                       begin
                          Face.Trace;
                       end;
                       ItemSelected:=True;
                       // Draw the selected faces to all viewports
                       for J:=1 to NumberOfViewports do Self.Viewport[J-1].Refresh;
                       break;
                    end;
                 end; Inc(I);
              end;
           end;
           if (Entity=nil) then begin I:=1;
              while I<=Surface.NumberOfControlCurves do begin
                 if Surface.ControlCurve[I-1].Visible then begin
                    Curve:=Surface.ControlCurve[I-1];
                    Tmp:=Curve.DistanceToCursor(X,Y,Viewport);
                    if Tmp<=SelectDistance then begin
                       Entity:=Curve;
                       Curve.Selected:=not Curve.Selected;
                       ItemSelected:=True; // Draw the selected edge to all viewports
                       for J:=1 to NumberOfViewports do
                         if self.Viewport[J-1].ViewportMode=vmWireframe then
                           Curve.Draw(self.Viewport[J-1]);
                       break;
                    end;
                 end; Inc(I);
              end;
           end;
           // check flowlines
           if (Entity=nil)
           and (not ItemSelected)
           and (Visibility.ShowFlowlines) then begin I:=1;
              while I<=NumberOfFlowlines do begin
                 Tmp:=Flowline[I-1].DistanceToCursor(X,Y,Viewport);
                 if Tmp<=SelectDistance then begin
                    Flowline[I-1].Selected:=not Flowline[I-1].Selected;
                    ItemSelected:=True; // Draw the selected flowline to all viewports
                    for J:=1 to NumberOfViewports do
                      if self.Viewport[J-1].ViewportMode=vmWireframe then
                        Flowline[I-1].Draw(self.Viewport[J-1]);
                    break;
                 end;
                 Inc(I);
              end;
           end;
           // check Markers
           if (Entity=nil)
           and (not ItemSelected)
           and (Visibility.ShowMarkers) then begin I:=1;
              while I<=NumberOfMarkers do begin
                 Tmp:=Marker[I-1].DistanceToCursor(X,Y,Viewport);
                 if Tmp<=SelectDistance then begin
                    Marker[I-1].Selected:=not Marker[I-1].Selected;
                    ItemSelected:=True;
                    // Draw the selected Marker to all viewports
                    for J:=1 to NumberOfViewports do if self.Viewport[J-1].ViewportMode=vmWireframe then Marker[I-1].Draw(self.Viewport[J-1]);
                    break;
                 end;
                 Inc(I);
              end;
           end;
           if Entity<>nil then begin  // apparently SOMEthing has been selected
              if Entity is TFreeSubdivisionControlPoint then begin
                 // If CTRL key is pressed, selection of multiple controlpoints is allowed,
                 // otherwise select only ONE controlpoint
                 Point:=Entity as TFreeSubdivisionControlPoint;
                 if not (ssCtrl in shift) then begin
                    if NumberOfSelectedControlPoints>0 then for I:=NumberOfSelectedControlPoints downto 1 do SelectedControlPoint[I-1].Selected:=False;
                    Point.Selected:=True;
                    for J:=1 to NumberOfViewports do self.Viewport[J-1].Refresh;
                 end else begin
                    Point.Selected:=not Point.Selected;
                    if not Point.Selected then Point:=SelectedControlPoint[NumberOfSelectedControlPoints-1];
                    for J:=1 to NumberOfViewports do self.Viewport[J-1].Refresh;
                 end;
                 if ActiveControlPoint<>point then ActiveControlPoint:=Point;
                 FCurrentlyMoving:=True;
                 FPointHasBeenMoved:=False;
                 FPrevCursorPosition.X:=X;
                 FPrevCursorPosition.Y:=Y;
              end else if Entity is TFreeSubdivisionControlCurve then begin
                 for J:=1 to NumberOfViewports do
                  if self.Viewport[J-1].ViewportMode=vmWireframe then self.Viewport[J-1].Refresh;
              end;
           end;
         end;
      end;
   end else if Button=mbRight then EditMode:=emSelectItems;
   if not Viewport.Focused then Viewport.SetFocus;
end;

procedure TFreeShip.MouseMove(Viewport:TFreeViewport; Shift: TShiftState; X,Y: integer);
var P2D  : T2DCoordinate;
    P    : T3DVector;
    Pt   : TPoint;
    Point: TFreeSubdivisionControlPoint;
    I    : Integer;
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
                    MessageDlg(Userstring(191)+'!',mtWarning,[mbOk],0);
                    exit;
                 end;
                 Edit.CreateUndoObject(Userstring(190),True);
              end;
              Point:=ActiveControlPoint;
              FileChanged:=True;
              Build:=False;
              FPointHasBeenMoved:=True;
              Pt.X:=X;
              Pt.Y:=Y;
              P2D:=Viewport.ProjectBackTo2D(Pt);
              P:=Point.Coordinate;
              Case Viewport.Viewtype of
                 fvProfile : begin
                               P.X:=P2D.X;
                               P.Z:=P2D.Y; end;
                 fvPlan    : begin
                               P.X:=P2D.X;
                               P.Y:=P2D.Y; end;
                 fvBodyplan: begin
                            if P.X<=ProjectSettings.MidleFrame
                               then P.Y:=-P2D.X
                               else P.Y:=P2D.X;
                               P.Z:=P2D.Y; end;
              end;
              Point.Coordinate:=P;
              ActiveControlPoint:=Point;
              if ControlpointForm.Visible then begin
                 // This lines updates the coordinate information in the controlpoint form
                 ControlPointform.ActiveControlPoint:=Point;
                 // and forces a repaint of the form
                 if not Viewport.Focused then Viewport.SetFocus;
                 application.ProcessMessages;
                 TForm(Viewport.Owner).BringToFront;
              end;
              Build:=False;
              for I:=1 to NumberOfViewports do self.Viewport[I-1].Refresh;
              if LinesplanFrame<>nil then TFreeLinesplanframe(LinesplanFrame).Viewport.Refresh;
              FPrevCursorPosition.X:=X;
              FPrevCursorPosition.Y:=Y;
           end;
        end;
   end;
end;

procedure TFreeShip.MouseUp(Viewport:TFreeViewport;Shift:TShiftState;X,Y:integer);
begin FCurrentlyMoving:=False; if not Viewport.Focused then Viewport.SetFocus;
end;

procedure TFreeShip.ZoomFitAllViewports;
var I: integer; P: TFreeHullWindow; //FreeViewPort;
begin        // Redraws model to all viewports by re-initializing all viewports
  with Application.MainForm as TMainForm do begin
    for I:=0 to MDIChildCount-1 do begin
      P:=GetMDIChildren(I) as TFreeHullWindow;
      P.ViewPort.ZoomExtents;
    end;
    if LinesplanFrame<>nil then
       TFreeLinesplanframe(LinesplanFrame).Viewport.ZoomExtents;
  end;
end;

function TFreeEdit.File_SaveCheck: word;               // добавлено из 5 версии
begin result:=mrOk;
//if not Ship.ModelIsLoaded then Ship.FileChanged:=false else
  if Ship.FileChanged then begin // корпрус редактировался и дорасчитывался
    Result:=MessageDlg(UserString(103)+EOL+UserString(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
    if Result=mrOk then File_SaveAs;
    if Result<>mrCancel then begin     // mrCancel-отмена операций
      Ship.ClearUndo;                  // здесь корпус просто расчищается
      Ship.Clear;                      // здесь FFileChanged:=False
      Ship.Surface.ClearSelection;
      Ship.Surface.ClearFaces;
      Ship.Surface.Clear;
    end;
  end;
end;

{$I FreeShipU_IO.inc} // операции ввода/вывода для *.fbm, *.ftm и *.fef
{$I FreeShipU_EX.inc} // импорт/экспорт ... всякой твари по паре ...
{$I FreeShipU_HS.inc} // TFreeHydrostaticCalc is an object class for hydrostatic calculations.

procedure Register; begin RegisterComponents('FreeShip', [TFreeShip]); end;

end.

