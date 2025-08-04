unit FreeShipUnit;
interface uses
     SysUtils, // this declaration must be at the start, before the FreeGeometry unit
     Math, Graphics,    // Types,
     Forms, Controls,
     Windows,Dialogs,
     Classes,FasterList,FreeTypes,FreeGeometry;

const FreeShipExtention= '.Free';   // Default extention for hull model files
      SelectDistance   = 3;         // Max. distance in pixels between an item and the cursor in order to be selected
      Threshold        = 3;         // The distance that the cursor has to be moved before a controlpoint starts moving
      StationColor     = $00808040; // Kind of teal-blue
      ButtockColor     = StationColor;
      WaterlineColor   = StationColor;

type
//   TFreePrecisionType   =(fpLow,fpMedium,fpHigh,fpVeryHigh);       // Precision of the ship-model
//   TFreeIntersectionType=(fiFree,fiStation,fiButtock,fiWaterline); // Different types of intersectionlines, stations, buttocks, waterlines and lines orientated in random planes
//   TFreeModelView       =(mvPort,mvBoth);                          // Show half the hull or the entire hull
//   TFreeEditMode        =(emSelectItems);                          // The program responds differnt to mouse actions depending on the editmode of the component
     TFreeShip            = class;                                   // to be declared later
{------------------------------------------------------------------------}
{ TFreeIntersection is a list of curves calculated from the intersection }
{ of a ship hull (represented by a subdivision surface) and a plane.     }
{ This plane can be a orthogonal plane (eg. stations, waterlines,        }
{ buttocks) or a freely oriented 3D plane (sent)                         }
{------------------------------------------------------------------------}
TFreeIntersection = class
   private
      FOwner           : TFreeShip;
      FItems           : TFasterList;
      FIntersectionType: TFreeIntersectionType;
      FPlane           : T3DPlane;
      FBuild           : Boolean;
      function    FGetColor:TColor; virtual;
      function    FGetPlane:T3DPlane; virtual;
      function    FGetCount:Integer;
      function    FGetDescription:string;
      function    FGetItem(Index:Integer):TFreeSpline;
      procedure   FSetBuild(Val:Boolean); virtual;
   public
      procedure   Add(Item:TFreeSpline);
      procedure   Clear; virtual;
      constructor Create(Owner:TFreeShip); virtual;
      procedure   Delete;
      procedure   DeleteItem(Item:TFreeSpline);
      destructor  Destroy; override;
      procedure   Draw(Viewport:TFreeViewport;Mode:TPenMode);
      procedure   DrawAll(Mode:TPenMode);
      procedure   Extents(Var Min,Max:T3DVector);
      procedure   LoadFromStream(Var LineNr:Integer;Strings:TStringList); virtual;
      procedure   Rebuild; virtual;
      procedure   SaveToStream(Strings:TStringList); virtual;
      property    Build                : Boolean read FBuild write FSetBuild;
      property    Color                : TColor read FGetColor;
      property    Count                : Integer read FGetCount;
      property    Description          : string read FGetDescription;
      property    IntersectionType     : TFreeIntersectionType read FIntersectionType;
      property    Items[index:Integer] : TFreeSpline read FGetItem;
      property    Owner                : TFreeShip read FOwner;
      property    Plane                : T3DPlane read FGetPlane;
end;
{--------------------------------------------------------}
{                                     TFreeVisibility    }
{ This object stores all visibility options for the hull }
{--------------------------------------------------------}
TFreeVisibility = class(TPersistent)
   private
      FOwner            : TFreeShip;
      FShowControlNet   : Boolean;
      FShowInteriorEdges: Boolean;        // Show the surface edges
      FShowStations     : Boolean;        // Show the calculated stations
      FShowButtocks     : Boolean;        // Show the calculated Buttocks
      FShowWaterlines   : Boolean;        // Show the calculated Waterlines
      FModelView        : TFreeModelView; // Show half or entire ship
      procedure FSetShowButtocks(Val:Boolean);
      procedure FSetShowControlNet(Val:Boolean);
      procedure FSetModelView(Val:TFreeModelView);
      procedure FSetShowInteriorEdges(Val:Boolean);
      procedure FSetShowStations(Val:Boolean);
      procedure FSetShowWaterlines(Val:Boolean);
   public
      constructor Create(Owner:TFreeShip);
      procedure Clear;
      procedure LoadFromStream(Var LineNr:Integer;Strings:TStringList);
      procedure SaveToStream(Strings:TStringList);
      property  Owner: TFreeShip read FOwner write FOwner;
   published
      property  ModelView        : TFreeModelView read FModelView write FSetModelView;
      property  ShowButtocks     : boolean read FShowButtocks write FSetShowButtocks;
      property  ShowControlNet   : boolean read FShowControlNet write FSetShowControlNet;
      property  ShowInteriorEdges: boolean read FShowInteriorEdges write FSetShowInteriorEdges;
      property  ShowStations     : boolean read FShowStations write FSetShowStations;
      property  ShowWaterlines   : boolean read FShowWaterlines write FSetShowWaterlines;
end;
{---------------------------------------------------------}
{                                     TFreeEdit           }
{ Container class for all editing commandsns for the hull }
{---------------------------------------------------------}
TFreeEdit = class
// private FOwner: TFreeShip;
   public
      Owner: TFreeShip;
      constructor Create( Ship:TFreeShip );      // Edit commands applicable to layers
      procedure Edge_Collapse;                   // Remove an edge by replacing the two connected faces by one controlface
      procedure Edge_Connect;                    // Create a new edge by connection two controlpoints belonging to the same controlface
      procedure Edge_Crease;                     // Switch selected edges between normal or crease edges (knuckle lines)
      procedure Edge_Split;                      // Create new controlpoints by splitting an controledge into two.
      procedure Face_New;                        // Creates a new controlface from the currently selected controlpoints
      procedure Layer_AutoGroup;                 // All connected patches surrounded by crease edges are grouped together into a new layer
      procedure Layer_DeleteEmpty;               // Delete all layers that are empty from the model
      function  Layer_New:TFreeSubdivisionLayer; // add a new empty layer
      procedure Point_Collapse;                  // Merge two selected edges by removing their common controlpoint.
      procedure Selection_Clear;                 // Deselect all selected items at once
      procedure Selection_Delete;                // Delete all selected items
//    property  Owner: TFreeShip read FOwner write FOwner;
end;
{--------------------------------------------------------------------------------}
{ TFreeShip is the actual component used for modelling and representing the ship }
{--------------------------------------------------------------------------------}
 TFreeShip = class(TComponent)
   private
      FViewports         : TFasterList;                  // List containing all viewports associated with the hullform
      FPrecision         : TFreePrecisionType;
      FFileVersion       : TFreeVersion;
      FEditMode          : TFreeEditMode;                // The component has different edit-modes which determine how the program responds to mouse-events
      FActiveControlPoint: TFreeSubdivisionControlPoint; // The last selected controlpoint (still selected)
      FFileChanged       : boolean;                      // Flag to keep track of modifications to the file
      FSurface           : TFreeSubdivisionSurface;
      FFilename          : string;                       // Filename of the current project;
      FEdit              : TFreeEdit;                    // Containerclass for all editing commands
      FStations          : TFasterList;
      FButtocks          : TFasterList;
      FWaterlines        : TFasterList;
      FVisibility        : TFreeVisibility;
      FOnFileChanged     : TNotifyEvent;
      // The folowing private variables are for moving controlpoints with the mouse
      FCurrentlyMoving   : boolean;
      FPointHasBeenMoved : boolean;
      FPrevCursorPosition: TPoint;
      function  FGetActiveLayer:TFreeSubdivisionlayer;
      function  FGetBuild:Boolean;
      function  FGetButtock(Index:Integer):TFreeIntersection;
      function  FGetFilename:string;
      function  FGetNumberOfLayers:Integer;
      function  FGetLayer(Index:Integer):TFreeSubdivisionLayer;
      function  FGetNumberOfButtocks:Integer;
      function  FGetNumberOfStations:Integer;
      function  FGetNumberOfViewports:Integer;
      function  FGetNumberOfWaterlines:Integer;
      function  FGetOnChangeActiveLayer:TChangeActiveLayerEvent;
      function  FGetOnChangeLayerData:TNotifyEvent;
      function  FGetOnSelectItem:TNotifyEvent;
      function  FGetSelectedControlPoint(Index:Integer):TFreeSubdivisionControlPoint;
      function  FGetSelectedControlEdge(Index:Integer):TFreeSubdivisionControlEdge;
      function  FGetSelectedControlFace(Index:Integer):TFreeSubdivisionControlFace;
      function  FGetStation(Index:Integer):TFreeIntersection;
      function  FGetViewport(Index:Integer):TFreeViewport;
      function  FGetWaterline(Index:Integer):TFreeIntersection;
      procedure FSetActiveControlPoint(Val:TFreeSubdivisionControlPoint);
      procedure FSetActiveLayer(Val:TFreeSubdivisionLayer);
      procedure FSetBuild(Val:Boolean);
      procedure FSetEditMode(Val:TFreeEditMode);
      procedure FSetFileChanged(Val:Boolean);
      procedure FSetFileName(Val:string);
      procedure FSetFileVersion(Val:TFreeVersion);
      function  FGetNumberOfSelectedControlEdges:Integer;
      function  FGetNumberOfSelectedControlFaces:Integer;
      function  FGetNumberOfSelectedControlPoints:Integer;
      procedure FSetOnChangeActiveLayer(val:TChangeActiveLayerEvent);
      procedure FSetOnChangeLayerData(Val:TNotifyEvent);
      procedure FSetOnSelectItem(Val:TNotifyEvent);
      procedure FSetPrecision(Val:TFreePrecisionType);
   public
      constructor Create(AOwner:TComponent); override;
      destructor  Destroy; override;
      procedure   Clear;
      procedure   AddViewport(Viewport:TFreeViewport); // Add a viewport to the list of viewports connected to the model
      procedure   DeleteViewport(Viewport:TFreeViewport); // Delete a viewport from the list of viewports connected to the model
      procedure   Draw;
      procedure   DrawToViewport(Viewport:TFreeViewport);
      procedure   Extents(Var Min,Max:T3DVector);  // calculate the bounding box coordinates of the model
      Procedure   LoadFromFile;                        // Import a FreeShip file
      Procedure   LoadFromStream(Strings:TStringList); // Process the information read from a file
      procedure   RebuildModel;                        // Force to rebuild the entire ship and recalculate all data
      procedure   Redraw;                              // Redraws the model on all viewports
      procedure   SaveToFile;
      Procedure   SaveToStream(Strings:TStringList);
      procedure   MouseDown(Viewport:TFreeViewport;Button:TMouseButton;Shift:TShiftState;X,Y:Integer;var ItemSelected:Boolean);
      procedure   MouseMove(Viewport:TFreeViewport;Shift:TShiftState;X,Y:Integer);
      property    ActiveControlPoint                  : TFreeSubdivisionControlPoint read FActiveControlPoint write FSetActiveControlPoint;
      property    ActiveLayer                         : TFreeSubdivisionLayer read FGetActiveLayer write FSetActiveLayer;
      property    Build                               : Boolean read FGetBuild write FSetBuild;
      property    Buttock[index:Integer]              : TFreeIntersection read FGetButtock;
      property    Edit                                : TFreeEdit read FEdit;                      // Containerclass for all editing commands
      property    EditMode                            : TFreeEditMode read FEditMode write FSetEditMode;
      property    Layer[index:integer]                : TFreeSubdivisionLayer read FGetLayer;
      property    NumberofButtocks                    : Integer read FGetNumberOfButtocks;
      property    NumberOfLayers                      : Integer read FGetNumberOfLayers;
      property    NumberOfSelectedControlEdges        : Integer read FGetNumberOfSelectedControlEdges;
      property    NumberOfSelectedControlFaces        : Integer read FGetNumberOfSelectedControlFaces;
      property    NumberOfSelectedControlPoints       : Integer read FGetNumberOfSelectedControlPoints;
      property    NumberofStations                    : Integer read FGetNumberOfStations;
      property    NumberOfViewports                   : integer read FGetNumberOfViewports;
      property    NumberofWaterlines                  : Integer read FGetNumberOfWaterlines;
      property    OnChangeActiveLayer                 : TChangeActiveLayerEvent read FGetOnChangeActiveLayer write FSetOnChangeActiveLayer;
      property    OnChangeLayerData                   : TNotifyEvent read FGetOnChangeLayerData write FSetOnChangeLayerData;
      property    OnSelectItem                        : TNotifyEvent read FGetOnSelectItem write FSetOnSelectItem;
      property    SelectedControlPoint[index:Integer] : TFreeSubdivisionControlPoint read FGetSelectedControlPoint;
      property    SelectedControlEdge[index:Integer]  : TFreeSubdivisionControlEdge read FGetSelectedControlEdge;
      property    SelectedControlFace[index:Integer]  : TFreeSubdivisionControlFace read FGetSelectedControlFace;
      property    Station[index:Integer]              : TFreeIntersection read FGetStation;
      property    Viewport[index:Integer]             : TFreeViewport read FGetViewport;
      property    Waterline[index:Integer]            : TFreeIntersection read FGetWaterline;
      property    Surface                             : TFreeSubdivisionSurface read FSurface;
   published
      property    FileChanged   : boolean read FFileChanged write FSetFileChanged;
      property    Filename      : string read FGetFilename write FSetFileName;
      property    FileVersion   : TFreeVersion read FFileVersion write FSetFileVersion;
      property    OnFileChanged : TNotifyEvent read FOnFileChanged write FOnFileChanged;
      property    Precision     : TFreePrecisionType read FPrecision write FSetPrecision;
      property    Visibility    : TFreeVisibility read FVisibility;
end;

procedure Register;

implementation //uses
//   FreeExtrudeDlg,
//     FreeLayerDlg;
{---------------------------------------------------------------------------}
{ TFreeIntersection is a list of curves calculated from the intersection    }
{ of a ship hull (represented by a subdivision surface) and a plane.        }
{ This plane can be a orthogonal plane (eg. stations, waterlines, buttocks) }
{ or a freely oriented 3D plane (sent)                                      }
{---------------------------------------------------------------------------}
procedure TFreeIntersection.DeleteItem(Item:TFreeSpline);
var Index:Integer;
begin                Index:=FItems.IndexOf(Item);
   if Index<>-1 then FItems.Delete(index);
                     Item.Destroy;
end;

function TFreeIntersection.FGetColor:TColor;
begin
   Case IntersectionType of
      fiStation  : Result:=StationColor;
      fiButtock  : Result:=ButtockColor;
      fiWaterline: Result:=WaterlineColor;
      else Result:=clWhite;
   end;
end;

function TFreeIntersection.FGetPlane:T3DPlane;
   begin Result:=FPlane; end;

function TFreeIntersection.FGetCount:Integer;
begin
   if self=nil then result:=0
               else Result:=FItems.Count;
end;

function TFreeIntersection.FGetDescription:string;
begin
   Case IntersectionType of
      fiStation : Result:='Station';
      fiButtock : Result:='Buttock';
      fiWaterline : Result:='Waterline';
      else Result:='Free';
   end;
   Result:=Result+#32+FloatToStrF(-FPLane.d,ffFixed,7,3);
end;

function TFreeIntersection.FGetItem(Index:Integer):TFreeSpline;
   begin Result:=FItems.Items[Index]; end;

procedure TFreeIntersection.FSetBuild( Val:Boolean );
var I: Integer;
begin
   if not Val then begin
      for I:=1 to Count do Items[I-1].Destroy;
      FItems.Clear;
   end;
   FBuild:=Val;
end;

procedure TFreeIntersection.Add(Item:TFreeSpline);
    begin FItems.Add(Item); end;

procedure TFreeIntersection.Clear;
var I : Integer;
begin
   for I:=1 to Count do Items[I-1].Destroy;
   FItems.Clear;
   FBuild:=False;
end;

constructor TFreeIntersection.Create(Owner:TFreeShip);
begin
   inherited Create;
   FOwner:=Owner;
   FItems:=TFasterList.Create;
   Clear;
end;

procedure TFreeIntersection.Delete;
var Index : integer;
begin
   Case IntersectionType of
      fiStation : begin
        Index:=Owner.FStations.IndexOf(self);
        if Index<>-1 then begin
          Owner.FStations.Delete(Index);
          Owner.FileChanged:=True;
          Owner.Redraw;
          Destroy;
        end;
      end;
      fiButtock : begin
        Index:=Owner.FButtocks.IndexOf(self);
        if Index<>-1 then begin
          Owner.FButtocks.Delete(Index);
          Owner.FileChanged:=True;
          Owner.Redraw;
          Destroy;
        end;
      end;
      fiWaterline: begin
        Index:=Owner.FWaterlines.IndexOf(self);
        if Index<>-1 then begin
          Owner.FWaterlines.Delete(Index);
          Owner.FileChanged:=True;
          Owner.Redraw;
          Destroy;
       end;
     end;
   end;
end;

destructor TFreeIntersection.Destroy;
begin Clear; FItems.Destroy; Inherited Destroy; end;

procedure TFreeIntersection.Draw(Viewport:TFreeViewport;Mode:TPenMode);
var I,J,R,G,B: Integer;
    Spline: TFreeSpline;
    P,P2: T3DVector;
    Pts: array of TPoint;
begin
   if not Viewport.Shade then begin
      if not Build then Rebuild;
      for I:=1 to Count do begin
         Spline:=Items[I-1];
         Spline.Color:=Color;
         Spline.Fragments:=700;
         Spline.PenStyle:=psSolid;
         if IntersectionType=fiStation then if Viewport.ViewType in [fvProfile,fvPlan] then Spline.PenStyle:=psDot;
         if IntersectionType=fiButtock then if Viewport.ViewType in [fvBodyplan,fvPlan] then Spline.PenStyle:=psDot;
         if IntersectionType=fiWaterline then if Viewport.ViewType in [fvProfile,fvBodyplan] then Spline.PenStyle:=psDot;
         if Spline.PenStyle=psDot then Spline.Color:=clSilver; // Draw portside
         Viewport.PenColor:=Spline.Color;
         Viewport.PenStyle:=Spline.PenStyle;
         Setlength(Pts,Spline.Fragments+1);
         for J:=0 to Spline.Fragments do begin
            P:=Spline.Value(J/Spline.Fragments);
            Pts[J]:=Viewport.Project(P);
         end;
         Viewport.Canvas.Polyline(Pts);
         if Owner.Visibility.ModelView=mvBoth then begin
            for J:=0 to Spline.Fragments do begin // Draw starboardside as well
               P:=Spline.Value(J/Spline.Fragments);
               P.Y:=-P.Y;
               Pts[J]:=Viewport.Project(P);
            end;
            Viewport.Canvas.Polyline(Pts);
         end;
      end;
   end else begin                                           // draw to z-buffer
      if not Build then Rebuild;
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

procedure TFreeIntersection.DrawAll(Mode:TPenMode); var I: Integer;
begin for I:=1 to Owner.NumberOfViewports do Draw(Owner.Viewport[I-1],Mode);
end;

procedure TFreeIntersection.Extents(Var Min,Max:T3DVector); var I: Integer;
begin if not build then Rebuild;
      for I:=1 to Count do Items[I-1].Extents(Min,Max);
end;

{--------------------------------------------------------}
{                                     TFreeVisibility    }
{ This object stores all visibility options for the hull }
{--------------------------------------------------------}
procedure TFreeVisibility.FSetModelView(Val:TFreeModelView);
begin
   if Val<>FModelView then begin
      FModelView:=Val;
      Owner.FileChanged:=True;
      Owner.Draw;
   end;
end;

procedure TFreeVisibility.FSetShowInteriorEdges(Val:Boolean);
begin
   if Val<>FShowInteriorEdges then begin
      FShowInteriorEdges:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

procedure TFreeVisibility.FSetShowControlNet(Val:Boolean);
begin
   if Val<>FShowControlNet then begin
      FShowControlNet:=val;
      Owner.FileChanged:=True;
      Owner.Redraw;
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

procedure TFreeVisibility.FSetShowWaterlines(Val:Boolean);
begin
   if Val<>FShowWaterlines then begin
      FShowWaterlines:=val;
      Owner.FileChanged:=True;
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
   FShowStations:=True;
   FShowbuttocks:=True;
   FShowWaterlines:=True;
end;

{-----------------------------------------------------------}
{   Container class for all editing commandsns for the hull }
{-----------------------------------------------------------}
constructor TFreeEdit.Create( Ship: TFreeShip );
      begin inherited Create; Owner:=Ship; end;

// Remove an edge by replacing the two connected faces by one controlface
procedure TFreeEdit.Edge_Collapse;
var I,N: Integer;
    Edge: TFreeSubdivisionControlEdge;
begin
   N:=0;
   For I:=Owner.NumberOfSelectedControlEdges downto 1 do begin
      Edge:=Owner.SelectedControlEdge[I-1];
      if Edge.NumberOfFaces>1 then begin
         Edge.Collapse;
         inc(N);
      end;
   end;
   if N>0 then begin
      Owner.Build:=false;
      Owner.Redraw;
      Owner.FileChanged:=True;
   end;
end;

// Create a new edge by connection two controlpoints belonging to the same controlface
procedure TFreeEdit.Edge_Connect;
begin
   Owner.Surface.Edge_Connect;
   Owner.FileChanged:=True;
   Owner.Build:=false;
   Owner.Redraw;
end;

// Switch selected edges between normal or crease edges (knuckle lines)
procedure TFreeEdit.Edge_Crease;
var I:Integer;
begin
   for I:=Owner.NumberOfSelectedControlEdges downto 1 do Owner.SelectedControlEdge[I-1].Crease:=not Owner.SelectedControlEdge[I-1].Crease;
   Owner.Build:=False;
   Owner.Redraw;
   Owner.FileChanged:=True;
end;

// Create new controlpoints by splitting an controledge into two.
procedure TFreeEdit.Edge_Split;
var I,N  : Integer;
    Edge : TFreeSubdivisionControlEdge;
    Point: TFreeSubdivisionControlPoint;
begin
   N:=0;
   for I:=Owner.NumberOfSelectedControlEdges downto 1 do begin
      Edge:=Owner.Surface.SelectedControlEdge[I-1];
      Edge.Selected:=False;
      Point:=Edge.InsertControlPoint(MidPoint(Edge.StartPoint.Coordinate,Edge.EndPoint.Coordinate));
      if Point<>nil then begin
         Point.Selected:=True;
         inc(N);
      end;
   end;
   if N>0 then begin
      Owner.Build:=False;
      Owner.FileChanged:=True;
      Owner.Redraw;
   end;
end;

// Creates a new controlface from the currently selected controlpoints
procedure TFreeEdit.Face_New;
var Tmp     : TFasterList;
    Face    : TFreeSubdivisionControlFace;
    I,F,E,P : integer;
begin
   if Owner.NumberOfSelectedControlPoints>2 then begin
      Tmp:=TFasterList.Create; // Remember the number of faces, edges and points
      F:=Owner.Surface.NumberOfControlFaces;
      E:=Owner.Surface.NumberOfControlEdges;
      P:=Owner.Surface.NumberOfControlPoints; // Assemble all points in a temp. list
      for I:=1 to Owner.Surface.NumberOfSelectedControlPoints
        do Tmp.Add(Owner.Surface.SelectedControlPoint[I-1]);
      // Deselect the controlpoints
      for I:=Owner.Surface.NumberOfSelectedControlPoints
        downto 1 do Owner.Surface.SelectedControlPoint[I-1].Selected:=False;
      // Add the new face
      Face:=Owner.Surface.AddControlFace(Tmp,Owner.ActiveLayer);
      if Face<>nil then begin
         Owner.Build:=False;
         Owner.Surface.Initialize(P+1,E+1,F+1);
         Owner.FileChanged:=True;
         Owner.Redraw;
      end;                               // Initialize then new edges and faces
      Tmp.Destroy;
   end else ShowMessage('You need to select at least 3 controlpoints'+EOL+
                        'in order to create a new controlface');
end;

// All connected patches surrounded by crease edges are grouped together into a new layer

procedure TFreeEdit.Layer_AutoGroup;
var ToDoList,DoneList,Current: TList;
    I,J: Integer;
    Face: TFreeSubdivisionControlFace;
    Layer: TFreeSubdivisionLayer;
    procedure FindAttachedFaces(List:TList;Face:TFreeSubdivisionControlFace);
    var I,J,Index: Integer;
        P1,P2: TFreeSubdivisionPoint;
        Edge: TFreeSubdivisionEdge;
    begin
       P1:=Face.Point[Face.NumberOfPoints-1];
       for I:=1 to Face.NumberOfpoints do begin
          P2:=Face.Point[I-1];
          Edge:=Face.Owner.EdgeExists(P1,P2);
          if Edge<>nil then begin
             if not Edge.Crease then begin
                for J:=1 to Edge.NumberOfFaces do if Edge.Face[J-1]<>Face then begin
                   Index:=ToDoList.IndexOf(Edge.Face[J-1]);
                   if Index<>-1 then begin
                      List.Add(Edge.Face[J-1]);
                      ToDoList.Delete(Index);
                      FindAttachedFaces(List,Edge.Face[J-1] as TFreeSubdivisionControlFace);
                   end;
                end;
             end;
          end; P1:=p2;
       end;
    end;
begin
   ToDoList:=TList.Create;
   DoneList:=TList.Create;
   if Owner.NumberOfSelectedControlFaces>0 then begin // Use only the selected ones
      ToDoList.Capacity:=ToDoList.Count+Owner.NumberOfSelectedControlPoints;
      for I:=1 to Owner.NumberOfSelectedControlPoints do begin
         Face:=Owner.SelectedControlFace[I-1];
         ToDoList.Add(Face);
      end;
   end else begin                                  // use all visible faces
      for I:=1 to Owner.NumberOfLayers do begin
         Layer:=Owner.Layer[I-1];
         if Layer.Visible then begin
            ToDoList.Capacity:=ToDoList.Count+Layer.Count;
            for J:=1 to Layer.Count do ToDoList.Add(Layer.Items[J-1]);
         end;
      end;
   end;
   if ToDoList.Count>0 then begin
      while ToDoList.Count>0 do begin
         Face:=ToDoList[ToDoList.Count-1];
         ToDoList.Delete(ToDoList.Count-1);
         Current:=TList.Create;
         Current.Add(Face);
         FindAttachedFaces(Current,Face);
         DoneList.Add(Current);
      end;                          // Assign all groups to different layers
      for I:=1 to DoneList.Count do  begin
         Current:=DoneList[I-1];
         if Current.Count>0 then begin
            Layer:=Layer_New;
            Layer.Color:=clOlive;  // RandomColor;
            for J:=1 to Current.Count do begin
               Face:=Current[J-1];
               Face.Layer:=Layer;
            end;
         end;
         Current.Destroy;
      end;                                            // Delete empty layers
      for I:=Owner.NumberOfLayers downto 1 do begin
         Layer:=Owner.Layer[I-1];
         if Layer.Count=0 then Layer.Delete;
      end;
      Owner.Redraw;
      Owner.FileChanged:=True;
   end;
   if assigned(Owner.OnChangeLayerData) then Owner.OnChangeLayerData(self);
   ToDoList.Destroy;
   DoneList.Destroy;
end;

// Delete all layers that are empty from the model
procedure TFreeEdit.Layer_DeleteEmpty;
var I,N:Integer;
begin
   N:=0;
   for I:=Owner.NumberOfLayers downto 1
   do if (Owner.Layer[I-1].Count=0) and (Owner.NumberOfLayers>1) then begin
      Owner.Layer[I-1].Delete;
      inc(N);
      Owner.FileChanged:=True;
   end;
   if Owner.ActiveLayer=nil then Owner.ActiveLayer:=Owner.Layer[0];
   if N>0 then ShowMessage('Deleted '+IntToStr(N)+' empty layers.');;
end;

function TFreeEdit.Layer_New:TFreeSubdivisionLayer;
   begin Result:=Owner.Surface.AddNewLayer;
         Owner.FileChanged:=True;
   end;

// Merge two selected edges by removing their common controlpoint.
procedure TFreeEdit.Point_Collapse;
var I,N: Integer;
    Point: TFreeSubdivisionControlPoint;
begin N:=0;
   For I:=Owner.NumberOfSelectedControlPoints downto 1 do begin
      Point:=Owner.SelectedControlPoint[I-1];
      if Point.NumberOfEdges=2 then begin
         Point.Collapse;
         inc(N);
      end;
   end;
   if N>0 then begin
      Owner.Build:=false;
      Owner.Redraw;
      Owner.FileChanged:=True;
   end;
end;
procedure TFreeEdit.Selection_Clear;     // Deselect all selected items at once
    begin Owner.Surface.Clearselection;
          Owner.Redraw;
    end;
procedure TFreeEdit.Selection_Delete;
var N: Integer;
begin
   N:=Owner.NumberOfSelectedControlPoints+
      Owner.NumberOfSelectedControlEdges+
      Owner.NumberOfSelectedControlFaces;
   if N>0 then begin
      if MessageDlg('Are you sure you want to delete the '+IntToStr(N)+' selected items?',mtWarning,[mbYes,mbNo],0)=mrYes
      then begin
         Owner.Surface.Selection_Delete;
         Owner.Build:=False;
         Owner.FileChanged:=True;
         Owner.Redraw;
      end;
   end;
end;
{-----------------------------------------}
{ TFreeShip is the actual component used  }
{ for modelling and representing the ship }
{-----------------------------------------}
function TFreeShip.FGetNumberOfViewports:Integer;
   begin Result:=FViewports.Count; end;
function TFreeShip.FGetOnChangeActiveLayer:TChangeActiveLayerEvent;
   begin Result:=Surface.OnChangeActiveLayer; end;
function TFreeShip.FGetOnChangeLayerData:TNotifyEvent;
   begin Result:=Surface.OnChangeLayerData; end;
function TFreeShip.FGetOnSelectItem:TNotifyEvent;
   begin Result:=Surface.OnSelectItem; end;
function TFreeShip.FGetSelectedControlEdge(Index:Integer):TFreeSubdivisionControlEdge;
   begin Result:=Surface.SelectedControlEdge[index]; end;
function TFreeShip.FGetSelectedControlPoint(Index:Integer):TFreeSubdivisionControlPoint;
   begin Result:=Surface.SelectedControlPoint[index]; end;
function TFreeShip.FGetSelectedControlFace(Index:Integer):TFreeSubdivisionControlFace;
   begin Result:=Surface.SelectedControlFace[index]; end;
function TFreeShip.FGetStation(Index:Integer):TFreeIntersection;
   begin Result:=FStations[Inter(0,Index,Fstations.Count)]; end;
function TFreeShip.FGetButtock(Index:Integer):TFreeIntersection;
   begin Result:=FButtocks[Inter(0,Index,FButtocks.Count)]; end;
function TFreeShip.FGetWaterline(Index:Integer):TFreeIntersection;
   begin Result:=FWaterlines[Inter(0,Index,FWaterlines.Count)]; end;
function TFreeShip.FGetActiveLayer:TFreeSubdivisionlayer;
   begin Result:=Surface.ActiveLayer; end;
function TFreeShip.FGetBuild:Boolean;
   begin Result:=Surface.Build; end;
function TFreeShip.FGetFilename:string;
   begin if FFilename='' then FFilename:='New model';
         Result:=ChangeFileExt(FFilename,FreeShipExtention);
   end;
function TFreeShip.FGetLayer(Index:Integer):TFreeSubdivisionLayer;
   begin Result:=Surface.Layer[index]; end;
function TFreeShip.FGetNumberOfStations:Integer;
   begin Result:=FStations.Count; end;
function TFreeShip.FGetNumberOfWaterlines:Integer;
   begin Result:=FWaterlines.Count; end;
function TFreeShip.FGetNumberOfButtocks:Integer;
   begin Result:=FButtocks.Count; end;
function TFreeShip.FGetNumberOfLayers:Integer;
   begin Result:=Surface.NumberOfLayers; end;
function TFreeShip.FGetViewport(Index:Integer):TFreeViewport;
begin Result:=FViewPorts[Inter(0,Index,NumberOfViewports)]; end;
procedure TFreeShip.FSetActiveControlPoint(Val:TFreeSubdivisionControlPoint);
    begin if Val<>FActiveControlPoint then begin
          FActiveControlPoint:=Val; // FMovingControlPoint;
    end;
end;
procedure TFreeShip.FSetActiveLayer(Val:TFreeSubdivisionLayer);
    begin Surface.ActiveLayer:=Val; end;
procedure TFreeShip.FSetBuild(Val:Boolean); var I: Integer;
begin
   Surface.Build:=Val;
   if not Build then begin
      for I:=1 to NumberOfStations do Station[I-1].Build:=False;
      for I:=1 to NumberOfButtocks do Buttock[I-1].Build:=False;
      for I:=1 to NumberOfWaterlines do Waterline[I-1].Build:=False;
   end;
end;
procedure TFreeShip.FSetEditMode(Val:TFreeEditMode);
    begin if Val<>FEditMode then begin FEditMode:=Val;
//          Case EditMode of emSelectItems: begin end; end;
      Redraw;
   end;
end;
procedure TFreeShip.FSetFileChanged(Val:Boolean);
    begin if Val<>FFileChanged then begin FFileChanged:=Val;
            if assigned(FOnFileChanged) then FOnFileChanged(self);
          end;
    end;
procedure TFreeShip.FSetFileName(Val:string); //var Tmp:string;
    begin if val='' then val:='New model';
          Val:=ChangeFileExt( Val,FreeShipExtention );
          if FFilename<>val then FFilename:=Val;
    end;
procedure TFreeShip.FSetFileVersion(Val:TFreeVersion);
begin if val<>FFileVersion then begin FFileVersion:=Val; FileChanged:=true; end;
end;
function TFreeShip.FGetNumberOfSelectedControlEdges:Integer;
   begin Result:=Surface.NumberOfSelectedControlEdges; end;
function TFreeShip.FGetNumberOfSelectedControlFaces:Integer;
   begin Result:=Surface.NumberOfSelectedControlFaces; end;
function TFreeShip.FGetNumberOfSelectedControlPoints:Integer;
   begin Result:=Surface.NumberOfSelectedControlPoints; end;
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
      FileChanged:=True;
      RebuildModel;
   end;
end;
procedure TFreeShip.AddViewport(Viewport:TFreeViewport);
begin         // Add a viewport to the list of viewports connected to the model
   if FViewports.IndexOf(Viewport)=-1 then begin
      FViewports.Add(Viewport);
      Viewport.ZoomExtents;
   end;
end;
constructor TFreeShip.Create( AOwner:TComponent );
begin
   Inherited Create(AOwner);
   FFileVersion:=CurrentVersion;
   FActiveControlPoint:=nil;
   FSurface:=TFreeSubdivisionSurface.Create;
   FViewports:=TFasterList.Create;
   FEdit:=TFreeEdit.Create(Self);
   FVisibility:=TFreeVisibility.Create(self);
   FStations:=TFasterList.Create;
   FButtocks:=TFasterList.Create;
   FWaterlines:=TFasterList.Create;
   Clear;
end;

procedure TFreeShip.DeleteViewport( Viewport:TFreeViewport ); var Index:Integer;
begin Index:=FViewports.IndexOf(Viewport);
      if Index<>-1 then FViewports.Delete(index);
end;

procedure TFreeShip.Clear; var I: Integer;
begin                                                    // Initialize all data
   FPrecision:=fpLow;
   FFileVersion:=CurrentVersion;
   FFileChanged:=False;
   FSurface.Clear;
   FFilename:='New model';
   FVisibility.Clear;
   FEditMode:=emSelectItems;                    // Set editmode to select items
   ActiveControlPoint:=nil;
   for I:=1 to NumberOfStations do Station[I-1].Destroy;     // delete stations
   FStations.Clear;
   for I:=1 to NumberOfButtocks do Buttock[I-1].Destroy;     // delete Buttocks
   FButtocks.Clear;
   for I:=1 to NumberOfWaterlines do Waterline[I-1].Destroy; // delete Waterlines
   FWaterlines.Clear;
   if not (csDestroying in componentState) then if assigned(FOnFileChanged) then FOnFileChanged(self);
end;

destructor TFreeShip.Destroy;
begin Clear;
   FStations.Destroy;
   FButtocks.Destroy;
   FWaterlines.Destroy;
   FVisibility.Clear;
   FViewports.Destroy;
   FSurface.Destroy;
   FEdit.Destroy;
   Inherited Destroy;
end;

procedure TFreeShip.Extents( Var Min,Max:T3DVector );
begin                    // calculate the bounding box coordinates of the model
   if Surface.NumberOfControlFaces>0 then begin
      Surface.DrawMirror:=Visibility.ModelView=mvBoth;
      Min.X:=1e6; Max.X:=-1e6;
      Min.Y:=1e6; Max.Y:=-1e6;
      Min.Z:=1e6; Max.Z:=-1e6; Surface.Extents( Min,Max );
   end else begin
      Min.X:=-1; Max.X:=1;
      Min.Y:=-1; Max.Y:=1;
      Min.Z:=-1; Max.Z:=1;
   end;
end;
procedure TFreeShip.Redraw;
var I: Integer;
begin // Redraws model to all viewports using the current min/max coordinates of the boundingbox
   For I:=1 to NumberOfViewports do Viewport[I-1].Refresh;
end;
procedure TFreeShip.Draw;
var I: Integer;
begin  // Redraws model to all viewports by re-initializing all viewports
   For I:=1 to NumberOfViewports do Viewport[I-1].ZoomExtents;
end;
procedure TFreeShip.DrawToViewport( Viewport:TFreeViewport ); var I:Integer;
begin
   if not Surface.Build then surface.Rebuild;
         // Draw intersectionlines BEFORE the surface is drawn,
         // so that the controlnet appears on top
         // But the intersections that should be drawn last depends on the view
   if Viewport.ViewType<>fvBodyplan then if Visibility.ShowStations then for I:=1 to NumberOfStations do Station[I-1].Draw(Viewport,pmCOPY);
   if Viewport.ViewType<>fvProfile then if Visibility.ShowButtocks then for I:=1 to NumberOfButtocks do Buttock[I-1].Draw(Viewport,pmCOPY);
   if Viewport.ViewType<>fvPlan then if Visibility.ShowWaterlines then for I:=1 to NumberOfWaterlines do Waterline[I-1].Draw(Viewport,pmCOPY);
      // Now draw the last intersections, so that they do not appear interupted by other dashed intersections
   if Viewport.ViewType=fvBodyplan then if Visibility.ShowStations then for I:=1 to NumberOfStations do Station[I-1].Draw(Viewport,pmCOPY);
   if Viewport.ViewType=fvProfile then if Visibility.ShowButtocks then for I:=1 to NumberOfButtocks do Buttock[I-1].Draw(Viewport,pmCOPY);
   if Viewport.ViewType=fvPlan then if Visibility.ShowWaterlines then for I:=1 to NumberOfWaterlines do Waterline[I-1].Draw(Viewport,pmCOPY);
   Surface.Color:=clDkGray;
   Surface.CreaseColor:=clRed;
   Surface.ShowControlNet:=Visibility.ShowControlNet;
   Surface.ShowInteriorEdges:=Visibility.ShowInteriorEdges;
   Surface.DrawMirror:=Visibility.ModelView=mvBoth;
   Surface.Draw(Viewport,pmCopy);
end;

procedure TFreeShip.MouseDown(Viewport:TFreeViewport;Button:TMouseButton;Shift:TShiftState;X,Y:Integer;var ItemSelected:Boolean);
var I,J,Tmp: Integer;
    P3D   : T3DVector;
    Point : TFreeSubdivisionControlPoint;
    Edge  : TFreeSubdivisionControlEdge;
    Face  : TFreeSubdivisionControlFace;
    Entity: TFreeSubdivisionBase;
begin
   ItemSelected:=False;
   if Button=mbLeft then begin
      Case EditMode of
         emSelectItems: begin Entity:=nil; I:=1;    // First check the vertices
            while I<=Surface.NumberOfControlPoints do begin
               if Surface.ControlPoint[I-1].Visible then begin
                  Point:=Surface.ControlPoint[I-1];
                  Tmp:=Point.DistanceToCursor( X,Y,Viewport );
                  if Tmp<=SelectDistance then begin
                     Entity:=Point;
                     Point.Selected:=not Point.Selected;
                     ItemSelected:=True; // Draw the selected point to all viewports
                     for J:=1 to NumberOfViewports do if not self.Viewport[J-1].Shade then Point.Draw(self.Viewport[J-1]);
                     break;
                  end;
               end; Inc(I);
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
                        ItemSelected:=True; // Draw the selected edge to all viewports
                        for J:=1 to NumberOfViewports do if not self.Viewport[J-1].Shade then Edge.Draw(False,self.Viewport[J-1]);
                        break;
                     end;
                  end; Inc(I);
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
                        ItemSelected:=True; // Draw the selected edge to all viewports
                        for J:=1 to NumberOfViewports do if not self.Viewport[J-1].Shade then Face.Draw(self.Viewport[J-1],pmCOPY);
                        break;
                     end;
                  end; Inc(I);
               end;
            end;
            if Entity<>nil then begin // apparently SOMEthing has been selected
               if Entity is TFreeSubdivisionControlPoint then begin
                  Point:=Entity as TFreeSubdivisionControlPoint;
                  if not Point.Selected then Point.Selected:=True;
                  if ActiveControlPoint<>point then ActiveControlPoint:=Point;
                  FCurrentlyMoving:=True;
                  FPointHasBeenMoved:=False;
                  FPrevCursorPosition.X:=X;
                  FPrevCursorPosition.Y:=Y;
               end;
            end;
         end;
      end;
   end else if Button=mbRight then begin EditMode:=emSelectItems; end;
end;

procedure TFreeShip.MouseMove
( Viewport: TFreeViewport;
  Shift: TShiftState;
  X,Y: Integer );
var P2D  : T2DCoordinate;
    P    : T3DVector;
    Pt   : TPoint;
    Point: TFreeSubdivisionControlPoint;
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
               fvProfile : begin P.X:=P2D.X; P.Z:=P2D.Y; end;
               fvPlan    : begin P.X:=P2D.X; P.Y:=P2D.Y; end;
               fvBodyplan: begin P.Y:=P2D.X; P.Z:=P2D.Y; end;
            end;
            Point.Coordinate:=P;
            if ActiveControlPoint=nil then FActiveControlPoint:=Point;
            Build:=False;
            Redraw;
            FPrevCursorPosition.X:=X;
            FPrevCursorPosition.Y:=Y;
         end;
      end;
   end;
end;

{$I FreeShipUnit_File.inc}

procedure Register;
    begin RegisterComponents( 'FreeShip',[TFreeShip] ); end; {Register}

end.
