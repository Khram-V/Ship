unit Main;
interface uses Windows,
    SysUtils,Classes,  Graphics,Controls,
    Forms,   Menus,    Dialogs, ExtCtrls,
    ActnList,StdCtrls, ComCtrls,Spin,
    LazFileUtils, FasterList,
    FreeSplitSectionDlg,FreeGeometry,FreeShipUnit,FreeHullformWindow,FreeTypes;

type TMainForm = class(TForm) {FreeShip:TFreeShip;->Ship:ShipUnit~~TCustomForm}
    ActionList1: TActionList;
    MenuImages : TImageList;
    MainMenu1  : TMainMenu;
    HintBar    : TStatusBar;
    LayerBox,PrecisionBox: TComboBox;
    ToolBar    : TToolBar;
    ColorDialog: TColorDialog;
    SpinEditFontSize: TSpinEdit;         //!!! нет единого управления шрифтами
    StatusBar,Panel1,Panel2,Panel3,Panel4: TPanel;
    ToolButton1,ToolButton2,ToolButton3,ToolButton4,ToolButton5,ToolButton6,
    ToolButton7,ToolButton8,ToolButton9,ToolButton10,ToolButton11,ToolButton12,
    ToolButton13,ToolButton14,ToolButton15,ToolButton16,ToolButton17,ToolButton18,
    ToolButton19,ToolButton20,ToolButton21,ToolButton22,ToolButton23,ToolButton24,
    ToolButton25,ToolButton26,ToolButton27,ToolButton28,ToolButton29,ToolButton30,
    ToolButton31,ToolButton32,ToolButton33,ToolButton34,ToolButton35,ToolButton36,
    ToolButton37,ToolButton38,ToolButton39,ToolButton40,ToolButton41,ToolButton42,
    ToolButton43,ToolButton44,ToolButton45,ToolButton46,ToolButton47,ToolButton48,
                                      ShowBuildCurve,tbMiddleFrame: TToolButton;
    ExportAurora      : TAction; AuroraHullVsl    : TMenuItem;
    IntersectionDialog: TAction; Intersections1   : TMenuItem;
    ShowHydrostatics  : TAction; Hydrostatics1    : TMenuItem;
    DesignHydrostatics: TAction; Calculations1    : TMenuItem;
    SplitSectionDialog: TAction; miSetSplitSection: TMenuItem;
    CascadeWindow     : TAction; Cascade1         : TMenuItem;
    TileWindow        : TAction; Tile1            : TMenuItem;
    NewWindow         : TAction; NewWindow1       : TMenuItem;
    LoadFile          : TAction; File1            : TMenuItem;
    ExitProgram       : TAction; ExitProgram1     : TMenuItem;
    ShowControlNet    : TAction; ShowControlNet1  : TMenuItem;
    ShowInteriorEdges : TAction; ShowInteriorEdges1:TMenuItem;
    BothSides         : TAction; Showbothsides1   : TMenuItem;
    FileSaveas        : TAction; Save1            : TMenuItem;
    LayerAutoGroup    : TAction; Layer1           : TMenuItem;
    NewLayer          : TAction; New1             : TMenuItem;
                                Visibility1: TMenuItem;
                                Window1: TMenuItem;
                                Autogroup1: TMenuItem;
                                FindFile: TMenuItem;
                                Edit1: TMenuItem;
                                Point1: TMenuItem;
    NewEdge: TAction;           Edge1: TMenuItem;
                                Face1: TMenuItem;
    EdgeCollapse: TAction;      Collapse1: TMenuItem;
    Delete: TAction;            Delete1: TMenuItem;
                                New2: TMenuItem;
    EdgeCrease: TAction;        Crease1: TMenuItem;
    DeselectAll: TAction;       Selection1: TMenuItem;
                                Clearselection1: TMenuItem;
    PointCollapse: TAction;     PointCollapse1: TMenuItem;
    ActiveLayerColor: TAction;  Activelayercolor1: TMenuItem;
    DeleteEmptyLayers: TAction; Deleteempty1: TMenuItem;
    LayerDialog: TAction;       Deleteempty2: TMenuItem;
    NewModel: TAction;          New3: TMenuItem;
    ShowStations: TAction;      Stations1: TMenuItem;
    ShowButtocks: TAction;      ShowWaterlines: TAction;
    Buttocks1: TMenuItem;       Waterlines1: TMenuItem;
    NewFace: TAction;           New4: TMenuItem;
    EdgeExtrude: TAction;       Extrude1: TMenuItem;
                                About1: TMenuItem;
    EdgeSplit: TAction;         Split1: TMenuItem;
    EditProjectSettings: TAction; Project1: TMenuItem;
                                Projectsettings1: TMenuItem;
    CheckModel: TAction;        Tools1: TMenuItem;
                                Analyzesurface1: TMenuItem;
    ShowNormals: TAction;       Normals1: TMenuItem;
    ImportVRML: TAction;        VRML1: TMenuItem;
                                Export1: TMenuItem;
                                Import1: TMenuItem;
    RemoveNegative: TAction;    Removenegative1: TMenuItem;
    RotateModel: TAction;       Rotatemodel1: TMenuItem;
    ScaleModel: TAction;        Scale3D1: TMenuItem;
    ShowGrid: TAction;          Analyzesurface2: TMenuItem;
    ImportObj: TAction;         ImportObj1: TMenuItem;
    ExportObj: TAction;         WavefrontfileObj1: TMenuItem;
    InvertFace: TAction;        Invert1: TMenuItem;
    Preferences: TAction;       Preferences1: TMenuItem;
    ExportDXF3DPolylines:TAction; ExportDXFPolylines1: TMenuItem;
    ExportDXFFaces: TAction;    DXF3Dfaces1: TMenuItem;
    ImportHullFile: TAction;    Carlssonhulfile1: TMenuItem;
    ExportOffsets: TAction;     Offsets1: TMenuItem;
    MoveModel: TAction;         Deselectall2: TMenuItem;
    AddPoint: TAction;          Add1: TMenuItem;
    DevelopLayers: TAction;     Developplates1: TMenuItem;
    ExportArchimedes: TAction;  ArchimedesMB1: TMenuItem;
    ShowLinesplan: TAction;     Linesplan1: TMenuItem;
    ShowDiagonals: TAction;     Diagonals1: TMenuItem;
                                Recentfiles: TMenuItem;
    ImportCarene: TAction;      Carenefile1: TMenuItem;
    ShowMarkers: TAction;       Markers1: TMenuItem;
    DeleteMarkers: TAction;     Deletemarkers1: TMenuItem;
    ImportSurface: TAction;     Surface1: TMenuItem;
    Showcurvature: TAction;     Curvature1: TMenuItem;
    IncreaseCurvatureScale: TAction; Incrcurvaturescale1: TMenuItem;
    DecreaseCurvatureScale: TAction; Decrcurvaturescale1: TMenuItem;
    FileSave: TAction;          Save2: TMenuItem;
    ImportBodyplan: TAction;    Bodyplan: TMenuItem;
                                Curve1: TMenuItem;
    ShowControlCurves: TAction; Controlcurves1: TMenuItem;
    NewCurve: TAction;          AddCurve1: TMenuItem;
    ExportCoordinates: TAction; Coordinates1: TMenuItem;
    InsertPlane: TAction;       InsertPlane1: TMenuItem;
    PointsLock: TAction;        PointsLock1: TMenuItem;
    PointsUnlock: TAction;      Unlockpoints1: TMenuItem;
    PointsUnlockAll: TAction;   Unlockallpoints1: TMenuItem;
    ImportMarkers: TAction;     Import2: TMenuItem;
                                Markers2: TMenuItem;
    PointAlign: TAction;
                                Projectline1: TMenuItem;
    MirrorFace: TAction;        MirrorFace1: TMenuItem;
                                ransform1: TMenuItem;
    ExportDXF2DPolylines: TAction; DXF2DPolylines1: TMenuItem;
    TransformLackenby: TAction; Lackenby1: TMenuItem;
    ExportIGES: TAction;        IGES1: TMenuItem;
    ExportPart: TAction;        Part1: TMenuItem;
    ImportPart: TAction;        Part2: TMenuItem;
    LayerIntersection: TAction; LayerIntersection1: TMenuItem;
    Undo: TAction;              Undo1: TMenuItem;
    Redo: TAction;              Redo1: TMenuItem;
    ClearUndo: TAction;         Clear1: TMenuItem;
    ShowUndoHistory: TAction;   Undohistory1: TMenuItem;
                                Show1:    TMenuItem;
    ImportPolyCad: TAction;     PolyCad1: TMenuItem;
    RemoveUnusedPoints: TAction; Removeunusedpoints1: TMenuItem;
    ExportGHS:    TAction;      GHS1:       TMenuItem;
    ShowFlowlines:TAction;      Flowlines1: TMenuItem;
    SelectAll:    TAction;      Selectall1: TMenuItem;
    ImportSTL:    TAction;      MenuImportSTL:TMenuItem;
    ExportSTL:    TAction;      STL1,N2,N3,N4,N5,N6,N7: TMenuItem;

    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormShow(Sender: TObject);
    procedure LoadFileExecute(Sender: TObject);
    procedure MidleFrameDialogExecute(Sender: TObject);
    procedure IntersectionDialogExecute(Sender: TObject);
    procedure DesignHydrostaticsExecute(Sender: TObject);
    procedure SpinEditFontSizeChange(Sender: TObject);
    procedure ShowHydrostaticsExecute(Sender: TObject);
    procedure ExitProgramExecute(Sender: TObject);
    procedure ShowControlNetExecute(Sender: TObject);
    procedure ShowInteriorEdgesExecute(Sender: TObject);
    procedure NewWindowExecute(Sender: TObject);
    procedure TileWindowExecute(Sender: TObject);
    procedure CascadeWindowExecute(Sender: TObject);
    procedure BothSidesExecute(Sender: TObject);
    procedure FreeShipFileChanged(Sender: TObject);
    procedure PrecisionBoxChange(Sender: TObject);
    procedure FileSaveasExecute(Sender: TObject);
    procedure LayerAutoGroupExecute(Sender: TObject);
    procedure NewLayerExecute(Sender: TObject);
    procedure DeleteExecute(Sender: TObject);
    procedure EdgeCollapseExecute(Sender: TObject);
    procedure NewEdgeExecute(Sender: TObject);
    procedure EdgeCreaseExecute(Sender: TObject);
    procedure DeselectAllExecute(Sender: TObject);
    procedure PointCollapseExecute(Sender: TObject);
    procedure LayerBoxChange(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
    procedure ActiveLayerColorExecute(Sender: TObject);
    procedure DeleteEmptyLayersExecute(Sender: TObject);
    procedure LayerDialogExecute(Sender: TObject);
    procedure NewModelExecute(Sender: TObject);
    procedure ShowStationsExecute(Sender: TObject);
    procedure ShowButtocksExecute(Sender: TObject);
    procedure ShowWaterlinesExecute(Sender: TObject);
    procedure NewFaceExecute(Sender: TObject);
    procedure EdgeExtrudeExecute(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure EdgeSplitExecute(Sender: TObject);
    procedure EditProjectSettingsExecute(Sender: TObject);
    procedure CheckModelExecute(Sender: TObject);
    procedure ShowNormalsExecute(Sender: TObject);
    procedure ImportSTLExecute(Sender: TObject);
    procedure ImportVRMLExecute(Sender: TObject);
    procedure ImportObjExecute(Sender: TObject);
    procedure ImportHullFileExecute(Sender: TObject);
    procedure ImportSurfaceExecute(Sender: TObject);
    procedure ImportBodyplanExecute(Sender: TObject);
    procedure ExportDXF3DPolylinesExecute(Sender: TObject);
    procedure ExportDXFFacesExecute(Sender: TObject);
    procedure ExportObjExecute(Sender: TObject);
    procedure RemoveNegativeExecute(Sender: TObject);
    procedure RotateModelExecute(Sender: TObject);
    procedure ScaleModelExecute(Sender: TObject);
    procedure ShowGridExecute(Sender: TObject);
    procedure UndoExecute(Sender: TObject);
    procedure FreeShipUpdateUndoData(Sender: TObject);
    procedure ExportAuroraHullVslExecute(Sender: TObject);
    procedure InvertFaceExecute(Sender: TObject);
    procedure PreferencesExecute(Sender: TObject);
    procedure ExportOffsetsExecute(Sender: TObject);
    procedure MoveModelExecute(Sender: TObject);
    procedure AddPointExecute(Sender: TObject);
    procedure DevelopLayersExecute(Sender: TObject);
    procedure ExportArchimedesExecute(Sender: TObject);
    procedure ShowLinesplanExecute(Sender: TObject);
    procedure ShowDiagonalsExecute(Sender: TObject);
    procedure FreeShipUpdateRecentFileList(Sender: TObject);
    procedure ImportCareneExecute(Sender: TObject);
    procedure ShowMarkersExecute(Sender: TObject);
    procedure DeleteMarkersExecute(Sender: TObject);
    procedure ShowcurvatureExecute(Sender: TObject);
    procedure IncreaseCurvatureScaleExecute(Sender: TObject);
    procedure DecreaseCurvatureScaleExecute(Sender: TObject);
    procedure FileSaveExecute(Sender: TObject);
    procedure ShowControlCurvesExecute(Sender: TObject);
    procedure NewCurveExecute(Sender: TObject);
    procedure ExportCoordinatesExecute(Sender: TObject);
    procedure InsertPlaneExecute(Sender: TObject);
    procedure PointsLockExecute(Sender: TObject);
    procedure PointsUnlockExecute(Sender: TObject);
    procedure PointsUnlockAllExecute(Sender: TObject);
    procedure ImportMarkersExecute(Sender: TObject);
    procedure FreeShipChangeCursorIncrement(Sender: TObject);
    procedure Panel3Click(Sender: TObject);
    procedure PointAlignExecute(Sender: TObject);
    procedure MirrorFaceExecute(Sender: TObject);
    procedure ExportDXF2DPolylinesExecute(Sender: TObject);
    procedure FreeShipUpdateGeometryInfo(Sender: TObject);
    procedure TransformLackenbyExecute(Sender: TObject);
    procedure ExportIGESExecute(Sender: TObject);
    procedure ExportPartExecute(Sender: TObject);
    procedure ImportPartExecute(Sender: TObject);
    procedure ImportPolyCadExecute(Sender: TObject);
    procedure LayerIntersectionExecute(Sender: TObject);
    procedure RedoExecute(Sender: TObject);
    procedure ClearUndoExecute(Sender: TObject);
    procedure ShowUndoHistoryExecute(Sender: TObject);
    procedure RemoveUnusedPointsExecute(Sender: TObject);
    procedure ExportGHSExecute(Sender: TObject);
    procedure ShowFlowlinesExecute(Sender: TObject);
    procedure SelectAllExecute(Sender: TObject);
    procedure ExportSTLExecute(Sender: TObject);
  private
    FSplitSectionDialog: TFreeSplitSectionDialog;
    procedure OnSplitSectionLocationChange(Sender: TObject; aV: Real);
    procedure FLoadRecentFile(sender:TObject);
    procedure FreeShipChangeLayerData(Sender: TObject);
    procedure FreeShipChangeActiveLayer(Sender: TObject;Layer: TFreeSubdivisionLayer);
    procedure FOnSelectItem(Sender:TObject);
    procedure FOpenHullWindows;   // Creates 4 different views on the hullform
  public
    Windows: TFasterList;        // Список активных окон
    procedure AddWindow( Win: TFreeHullWindow );
    procedure DelWindow( Win: TFreeHullWindow );
    procedure WindowMenu;        // опции нет, пусть будет процедура
    procedure WinClick( Sender: TObject );
    procedure NewOneWindow;
    procedure TileView;
    procedure CascadeView;
    procedure SetCaption;
    procedure UpdateMenu;
end;

var MainForm: TMainForm;

implementation uses FreeSplashWndw,
                    FreeLinesplanFrm,
                    FreeLinesplanFrme,
                    FreeLanguageSupport;
{$R *.lfm}
{$include Main_Wins.inc}

procedure TMainForm.FormCreate( Sender: TObject );
begin
   Windows:=TFasterList.Create;
   WindowState:=wsNormal; //wsMaximized;
   FormStyle:=fsNormal;
// AlphaBlend:= True;
// AlphaBlendValue:= 128;
   Color:=1; //clWhite;        --- не лучший вариант ...
   SetWindowLongPtr( Self.Handle,GWL_EXSTYLE,
   GetWindowLongPtr( Self.Handle,GWL_EXSTYLE) or WS_EX_LAYERED );
   SetLayeredWindowAttributes( Self.Handle,1{clWhite},128,LWA_COLORKEY );
   Ship:=TFreeShip.Create( self );
   With Ship do begin        // FreeShipUnit оригинал воссоздания новых моделей
      MainForm:=self;
      FileChanged:=true;
      Filename:='Example_Ship';
      OnChangeCursorIncrement:=FreeShipChangeCursorIncrement;
      OnFileChanged          :=FreeShipFileChanged;
      OnUpdateGeometryInfo   :=FreeShipUpdateGeometryInfo;
      OnUpdateRecentFileList :=FreeShipUpdateRecentFileList;
      OnUpdateUndoData       :=FreeShipUpdateUndoData;
      Precision:=fpLow;
   end;
end;

procedure TMainForm.FormShow( Sender: TObject ); Var NF: String='';
begin With Ship do begin                                // Initialize some data
   OnChangeActiveLayer:=FreeShipChangeActiveLayer;
   OnChangeLayerData:=FreeShipChangeLayerData;
   OnSelectItem:=FOnSelectItem;
   Preferences.Load;
   Clear;
   if ParamCount>0 then NF:=ParamStr( 1 ) else
   if Edit.RecentFiles.Count>0 then NF:=Edit.RecentFiles[0];
   if FileExistsUTF8( NF ) then Edit.File_Load( NF );
   FOpenHullWindows;
   SetCaption;
   UpdateMenu;
end end;

procedure TMainForm.ExitProgramExecute(Sender: TObject);
    begin UpdateMenu; Close; end;

procedure TMainForm.FOnselectItem(Sender:TObject);
var Face1,Face2: TFreeSubdivisionControlFace;
    Diff: Boolean;
    I: Integer;
begin
   if (Sender is TFreeSubdivisionControlPoint)
   and (Sender=Ship.ActiveControlPoint)
   and (Ship.ActiveControlPoint.Selected=false) then begin
      // The active controlpoint was deselected, probably internally by the subdivision surface.
      // Set the FreeShip.ActiveControlPoint to nil (which also closes the controlpoint window)
      Ship.ActiveControlPoint:=nil;
   end;
   if Ship.NumberOfSelectedControlFaces>0 then begin
      // set the layerbox itemindex to the index of the layer of the selected controlfaces
      Face1:=Ship.SelectedControlFace[0];
      // check if all selected controlfaces belong to the same layer
      Diff:=False;
      for I:=1 to Ship.NumberOfSelectedControlFaces do begin
         Face2:=Ship.SelectedControlFace[I-1];
         if Face1.Layer<>Face2.Layer then begin Diff:=True; Break; end;
      end;
      if not Diff then FreeShipChangeActiveLayer(self,Face1.Layer)
                  else FreeShipChangeActiveLayer(self,nil);
   end else FreeShipChangeActiveLayer(self,Ship.ActiveLayer);
   UpdateMenu;
end;

procedure TMainForm.SetCaption;
begin if Ship.FileChanged
         then Caption:='Free!Ship   : '+Ship.Filename+' ('+Userstring(280)+')'
         else Caption:='Free!Ship   : '+Ship.Filename+' ('+Userstring(281)+')';
end;

procedure TMainForm.UpdateMenu; // In this procedure all actions are set to enabled/disabled
var I,NLayers: Integer;    // according to the current state and selected items
begin With Ship do begin
   NLayers:=0;
   For I:=1 to NumberOfLayers do if Layer[I-1].Count>0 then inc(NLayers); // File menu
   FileSaveas.Enabled:=(Surface.NumberOfControlPoints>0) or (FileChanged) or (FilenameSet);
   FileSave.Enabled:=(FileSaveas.Enabled) and (FilenameSet);
// ExportFEF.Enabled:=Surface.NumberOfControlPoints>0;
   ExportObj.Enabled:=Surface.NumberOfControlFaces>0;
   ExportSTL.Enabled:=Surface.NumberOfControlFaces>0;
   ExportDXF3DPolylines.Enabled:=((NumberofStations>0) and (Visibility.ShowStations)) or
                                 ((NumberofButtocks>0) and (Visibility.ShowButtocks)) or
                                 ((NumberofWaterlines>0) and (Visibility.ShowWaterlines)) or
                                 ((NumberofDiagonals>0) and (Visibility.ShowDiagonals)) or
                                 ((NumberofControlcurves>0) and (Visibility.ShowControlcurves));
   ExportDXF2DPolylines.Enabled:=((NumberofStations>0) and (Visibility.ShowStations)) or
                                 ((NumberofButtocks>0) and (Visibility.ShowButtocks)) or
                                 ((NumberofWaterlines>0) and (Visibility.ShowWaterlines));
   ExportDXFFaces.Enabled:=Surface.NumberOfControlFaces>0;
   ExportIGES.Enabled:=Surface.NumberOfControlFaces>0;
   ExportOffsets.Enabled:=NumberofStations+NumberofButtocks+NumberofWaterlines+
                          NumberofDiagonals+NumberOfControlCurves>0;
   ExportArchimedes.Enabled:=NumberofStations>0;
   ExportGHS.Enabled:=NumberofStations>0;
   RecentFiles.Enabled:=RecentFiles.Count>0;
   ExportCoordinates.Enabled:=Surface.NumberOfControlPoints>0;
   ExportPart.Enabled:=(Surface.NumberOfControlFaces>0);
   ImportPart.Enabled:=(Surface.NumberOfControlFaces>0) and (nV>0);
   // Show controledges and controlpoints
   ShowControlNet.Enabled:=Surface.NumberOfControlPoints>0;
   ShowControlNet.Checked:=Visibility.ShowControlNet;
   // Show interior edges
   ShowInteriorEdges.Enabled:=Surface.NumberOfControlFaces>0;
   ShowInteriorEdges.Checked:=Visibility.ShowInteriorEdges;
   // Show both sides
   BothSides.Checked:=Visibility.ModelView=mvBoth;
   BothSides.Enabled:=Surface.NumberOfControlFaces>0;
   // Delete
   Delete.Enabled:=NumberOfSelectedControlPoints+NumberOfSelectedControlEdges+
                   NumberOfSelectedControlFaces+NumberOfSelectedControlCurves+
                   NumberOfSelectedFlowLines+NumberOfselectedMarkers>0;
   // Window menu actions
   TileWindow.Enabled:=nV>0;
   CascadeWindow.Enabled:=nV>0;
   // Precision
   PrecisionBox.ItemIndex:=Ord(Precision);
   // Layers
   LayerAutoGroup.Enabled:=(Surface.NumberOfControlFaces>1) and (Visibility.ShowInteriorEdges);
   // Tools
   CheckModel.Enabled:=Surface.NumberOfControlFaces>0;
   DevelopLayers.Enabled:=False;
   for I:=1 to NumberOfLayers do
   if (Layer[I-1].Developable) and (Layer[I-1].Count>0) then begin
      DevelopLayers.Enabled:=True;
      break;
   end;
   DeleteMarkers.Enabled:=NumberofMarkers>0;
// Calculations
   DesignHydrostatics.Enabled:=Surface.NumberOfControlFaces>0;
// Hydrostaticsdialog.Enabled:=Surface.NumberOfControlFaces>0;
// CrossCurves.Enabled:=Surface.NumberOfControlFaces>0;
// edit commands
   AddPoint.Enabled:=(nV>0) and (Visibility.ShowControlNet);
   Insertplane.Enabled:=(Surface.NumberOfControlEdges>0) and (Visibility.ShowControlNet);
   LayerIntersection.Enabled:=NLayers>1;
   EdgeCollapse.Enabled:=NumberOfSelectedControlEdges>0;
   NewEdge.Enabled:=NumberOfSelectedControlPoints>1;
   EdgeCrease.Enabled:=NumberOfSelectedControlEdges>0;
   DeselectAll.Enabled:=(NumberOfSelectedControlPoints+NumberOfSelectedControlEdges
                        +NumberOfSelectedControlFaces+NumberOfSelectedControlCurves>0)
                     or (ActiveControlPoint<>nil);
   NewCurve.Enabled:=NumberOfSelectedControlEdges>0;
   PointCollapse.Enabled:=NumberOfSelectedControlPoints>0;
   DeleteEmptyLayers.Enabled:=False;
   for I:=1 to NumberOfLayers do
   if (Layer[I-1].Count=0) and (NumberOfLayers>0) then begin
      DeleteEmptyLayers.Enabled:=True; break;
   end;
   RemoveUnusedPoints.Enabled:=False;
   for I:=1 to Surface.NumberOfControlPoints do
   if Surface.ControlPoint[I-1].NumberOfFaces=0 then begin
      RemoveUnusedPoints.Enabled:=True; break;
   end;
   InvertFace.Enabled:=NumberOfSelectedControlFaces>0;
   ShowStations.Enabled:=NumberofStations>0;
   ShowStations.Checked:=Visibility.ShowStations;
   ShowButtocks.Enabled:=NumberofButtocks>0;
   ShowButtocks.Checked:=Visibility.ShowButtocks;
   ShowWaterlines.Enabled:=NumberofWaterlines>0;
   ShowWaterlines.Checked:=Visibility.ShowWaterlines;
   ShowDiagonals.Enabled:=NumberofDiagonals>0;
   ShowDiagonals.Checked:=Visibility.ShowDiagonals;
   ShowNormals.Checked:=Visibility.ShowNormals;
   ShowNormals.Enabled:=NumberOfSelectedControlFaces>0;
   ShowGrid.Checked:=Visibility.ShowGrid;
   ShowGrid.Enabled:=NumberofStations+NumberofButtocks+NumberofWaterlines+NumberofDiagonals>0;
   ShowMarkers.Checked:=Visibility.ShowMarkers;
   ShowMarkers.Enabled:=NumberofMarkers>0;
   ShowCurvature.Checked:=Visibility.ShowCurvature;
   ShowCurvature.Enabled:=NumberofStations+NumberofButtocks+NumberofWaterlines+NumberofDiagonals+NumberOfControlCurves>0;
   ShowControlCurves.Checked:=Visibility.ShowControlCurves;
   ShowControlCurves.Enabled:=Surface.NumberOfControlCurves>0;
   ShowHydrostatics.Checked:=Visibility.ShowHydrostaticData;
// ShowHydrostatics.Enabled:=(Surface.NumberOfControlFaces>2) and (ProjectSettings.MainparticularsHasBeenset);
   ShowFlowlines.Checked:=Visibility.ShowFlowlines;
   ShowFlowlines.Enabled:=NumberOfFlowLines>0;
   NewFace.Enabled:=NumberOfSelectedControlPoints>2;
   IntersectionDialog.Enabled:=Surface.NumberOfControlFaces>0;
   EdgeExtrude.Enabled:=NumberOfSelectedControlEdges>0;
   EdgeSplit.Enabled:=NumberOfSelectedControlEdges>0;
   RotateModel.Enabled:=Surface.NumberOfControlPoints>0;
   ScaleModel.Enabled:=Surface.NumberOfControlPoints>0;
   MoveModel.Enabled:=Surface.NumberOfControlPoints>0;
   Mirrorface.Enabled:=Surface.NumberOfControlFaces>0;      // Skip translation
   if (Undoposition-1>=0)
   and (Undoposition-1<UndoCount) then begin
      Undo.Caption:=Userstring(290)+#32+UndoObject[Undoposition-1].Undotext;
   end else begin
      Undo.Caption:=Userstring(290);
   end;
   Undo.Enabled:=(UndoCount>0) and (UndoPosition>0);
// if Undo.Enabled then Undo.Caption:='Undo '+UndoObject[Undoposition-1].Undotext
//                 else Undo.Caption:='Undo';
   Redo.Enabled:=(UndoCount>0) and (UndoPosition<UndoCount);
// if Redo.Enabled then Redo.Caption:='Redo '+UndoObject[Undoposition].Undotext
//                 else Undo.Caption:='Redo';
// End Skip translation
   Undohistory1.Enabled:=UndoCount>0;
   Self.ClearUndo.Enabled:=UndoCount>0;
   PointsLock.Enabled:=(NumberOfSelectedControlPoints>0)
          and (NumberOfSelectedLockedPoints<NumberOfSelectedControlPoints);
   PointsUnlock.Enabled:=NumberOfSelectedLockedPoints>0;
   PointsUnlockAll.Enabled:=NumberOfLockedPoints>0;
   PointAlign.Enabled:=NumberOfSelectedControlPoints>2;
   TransformLackenby.Enabled:=Surface.NumberOfControlFaces>0;
   if Assigned( OnUpdateGeometryInfo )
           then OnUpdateGeometryInfo( Ship);
// ActiveControlPoint:=ActiveControlPoint;
   WindowMenu;
end; end;

procedure TMainForm.LoadFileExecute( Sender: TObject );
    begin Ship.Edit.File_Load; // FOpenHullWindows;
          SetCaption;
          UpdateMenu;
    end;

procedure TMainForm.ShowControlNetExecute(Sender: TObject);
    begin Ship.Visibility.ShowControlNet:=not Ship.Visibility.ShowControlNet;
          UpdateMenu;
    end;
procedure TMainForm.ShowInteriorEdgesExecute(Sender: TObject);
    begin Ship.Visibility.ShowInteriorEdges:=not Ship.Visibility.ShowInteriorEdges;
          UpdateMenu;
    end;
procedure TMainForm.NewWindowExecute(Sender: TObject);
    begin NewOneWindow; end;
procedure TMainForm.FreeShipFileChanged(Sender: TObject);
    begin SetCaption; end;
procedure TMainForm.PrecisionBoxChange(Sender: TObject);
begin Ship.Precision:=TFreePrecisionType( PrecisionBox.ItemIndex );
      UpdateMenu;
end;
procedure TMainForm.FileSaveasExecute(Sender: TObject);
    begin Ship.Edit.File_SaveAs; UpdateMenu; SetCaption; end;
procedure TMainForm.LayerAutoGroupExecute(Sender: TObject);
    begin Ship.Edit.Layer_AutoGroup; UpdateMenu; end;

procedure TMainForm.FLoadRecentFile( sender:TObject );
var Menu: TMenuItem; RName: string; N: Integer; Answer: word;
begin
   if sender is TMenuItem then begin
      Menu:=sender as TMenuItem;
      RName:=Menu.Caption;
      repeat N:=Pos( '&',RName );
          if N<>0 then system.Delete( RName,N,1 );
      until N=0;
      if FileExistsUTF8(RName) then begin
         Answer:=Ship.Edit.File_SaveCheck;
         if (Answer=mrCancel) or Ship.FileChanged then exit;
         Ship.Edit.File_Load( RName );
//       FOpenHullWindows;
         SetCaption;
         UpdateMenu;
      end;
   end;
end;

procedure TMainForm.FreeShipChangeLayerData( Sender: TObject ); var I: Integer;
begin                              // Fill the layerbox with the current layers
   LayerBox.Items.BeginUpdate;
   LayerBox.Items.Clear;
   for I:=1 to Ship.NumberOfLayers do
       Layerbox.Items.AddObject(Ship.Layer[I-1].Name,Ship.Layer[I-1]);
   LayerBox.Items.EndUpdate;
   I:=LayerBox.Items.IndexOfObject(Ship.ActiveLayer);
   Layerbox.ItemIndex:=I;
end;

procedure TMainForm.FreeShipChangeActiveLayer(Sender: TObject;Layer: TFreeSubdivisionLayer);
var Index : Integer;
begin
   if (Ship.NumberOfSelectedControlFaces<>0)
   and (Ship.ActiveLayer=Layer) then begin // do not switch to the active layer when controlfaces are selected
   end else begin
      if Layer=nil then begin
         Index:=-1;
         Layerbox.ItemIndex:=Index;
         Panel1.Color:=clBtnface;
      end else begin
         Index:=Layerbox.Items.IndexOfObject(Layer);
         Layerbox.ItemIndex:=Index;
         Panel1.Color:=Layer.Color;
      end;
   end;
end;
procedure TMainForm.NewLayerExecute(Sender: TObject);
    begin Ship.Edit.Layer_New; UpdateMenu; end;
procedure TMainForm.DeleteExecute(Sender: TObject);
    begin Ship.Edit.Selection_Delete; UpdateMenu; end;
procedure TMainForm.EdgeCollapseExecute(Sender: TObject);
    begin Ship.Edit.Edge_Collapse; UpdateMenu; end;
procedure TMainForm.NewEdgeExecute(Sender: TObject);
    begin Ship.Edit.Edge_Connect; UpdateMenu; end;
procedure TMainForm.EdgeCreaseExecute(Sender: TObject);
    begin Ship.Edit.Edge_Crease; UpdateMenu; end;
procedure TMainForm.DeselectAllExecute(Sender: TObject);
    begin Ship.Edit.Selection_Clear; UpdateMenu; end;
procedure TMainForm.PointCollapseExecute(Sender: TObject);
    begin Ship.Edit.Point_Collapse; UpdateMenu; end;

procedure TMainForm.LayerBoxChange(Sender: TObject);
var Layer: TFreeSubdivisionLayer; I,Index : Integer;
begin
   Index:=Layerbox.ItemIndex;
   if index=-1 then Index:=0;
   Layer:=Layerbox.Items.Objects[index] as TFreeSubdivisionLayer;
   if Ship.NumberOfSelectedControlFaces=0 then begin // change the active layer
      if Layer<>Ship.ActiveLayer then Ship.ActiveLayer:=Layer;
   end else begin          // Assign all selected controlfaces to the new layer
      for I:=Ship.NumberOfSelectedControlFaces downto 1 do
         Ship.SelectedControlFace[I-1].Layer:=Layer;
      Ship.FileChanged:=True;
      Ship.Redraw;
   end;
   UpdateMenu;
end;

procedure TMainForm.Panel1Click(Sender: TObject);
    begin ActiveLayerColorExecute(self); end;

procedure TMainForm.ActiveLayerColorExecute(Sender: TObject);
begin // change the color of the currently active layer
   ColorDialog.Color:=Ship.ActiveLayer.Color;
   if ColorDialog.Execute then begin
      Ship.ActiveLayer.Color:=ColorDialog.Color;
      Ship.FileChanged:=True;
      Ship.Redraw;
      FreeShipChangeActiveLayer(self,Ship.ActiveLayer);
      UpdateMenu;
   end;
end;
procedure TMainForm.DeleteEmptyLayersExecute(Sender: TObject);
    begin Ship.Edit.Layer_DeleteEmpty(False); UpdateMenu; end;
procedure TMainForm.LayerDialogExecute(Sender: TObject);
    begin Ship.Edit.Layer_Dialog; UpdateMenu; end;
procedure TMainForm.NewModelExecute(Sender: TObject);
    begin if Ship.Edit.Model_New then FOpenHullWindows; Updatemenu;
    end;
procedure TMainForm.ShowStationsExecute(Sender: TObject);
    begin Ship.Visibility.ShowStations:=not Ship.Visibility.ShowStations;
          UpdateMenu;
    end;
procedure TMainForm.ShowButtocksExecute(Sender: TObject);
    begin Ship.Visibility.ShowButtocks:=not Ship.Visibility.ShowButtocks;
          UpdateMenu;
    end;
procedure TMainForm.ShowWaterlinesExecute(Sender: TObject);
    begin Ship.Visibility.ShowWaterlines:=not Ship.Visibility.ShowWaterlines;
          UpdateMenu;
    end;
procedure TMainForm.NewFaceExecute(Sender: TObject);
    begin Ship.Edit.Face_New; UpdateMenu; end;
procedure TMainForm.IntersectionDialogExecute(Sender: TObject);
    begin Ship.Edit.Intersection_Dialog; UpdateMenu; end;
procedure TMainForm.DesignHydrostaticsExecute(Sender: TObject);
var Calculation: TFreeHydrostaticCalc;
begin Calculation:=Ship.Edit.Hydrostatics_Calculate
         ( Ship.ProjectSettings.ProjectDraft,0.0,0.0 );
      if Calculation<>nil then FreeAndNil( Calculation );
end;
procedure TMainForm.EdgeExtrudeExecute(Sender: TObject);
    begin Ship.Edit.Edge_Extrude; UpdateMenu; end;
procedure TMainForm.About1Click(Sender: TObject);   // Show splash screen again
    begin FreeSplashWindow:=TFreeSplashWindow.Create( Application );
          ShowTranslatedValues( FreeSplashWindow );
          FreeSplashWindow.Show;
          FreeSplashWindow.Refresh;
    end;
procedure TMainForm.EdgeSplitExecute(Sender: TObject);
    begin Ship.Edit.Edge_Split; UpdateMenu; end;
procedure TMainForm.EditProjectSettingsExecute(Sender: TObject);
    begin Ship.ProjectSettings.Edit; UpdateMenu; end;
procedure TMainForm.CheckModelExecute(Sender: TObject);
    begin Ship.Edit.Model_Check(True); UpdateMenu; end;
procedure TMainForm.ShowNormalsExecute(Sender: TObject);
    begin Ship.Visibility.ShowNormals:=not Ship.Visibility.ShowNormals;
          UpdateMenu;
    end;
procedure TMainForm.ExportAuroraHullVslExecute(Sender: TObject);
    begin Ship.Edit.File_Export_Aurora_Experiments; UpdateMenu; end;

procedure TMainForm.ImportOBJExecute(Sender: TObject);
    begin Ship.Edit.File_ImportOBJ;
          FOpenHullWindows; SetCaption; UpdateMenu;
end;
procedure TMainForm.ExportObjExecute(Sender: TObject);
    begin Ship.Edit.File_ExportObj; UpdateMenu; end;
procedure TMainForm.ImportSTLExecute(Sender: TObject);
    begin Ship.Edit.File_ImportSTL;
          FOpenHullWindows; SetCaption; UpdateMenu;
    end;
procedure TMainForm.ImportVRMLExecute(Sender: TObject);
    begin Ship.Edit.File_ImportVRML; FOpenHullWindows; UpdateMenu; end;
procedure TMainForm.RemoveNegativeExecute(Sender: TObject);
    begin Ship.Edit.Face_DeleteNegative; UpdateMenu; end;
procedure TMainForm.RotateModelExecute(Sender: TObject);
    begin Ship.Edit.Face_Rotate; UpdateMenu; end;
procedure TMainForm.ScaleModelExecute(Sender: TObject);
    begin Ship.Edit.Face_Scale; UpdateMenu; end;
procedure TMainForm.ShowGridExecute(Sender: TObject);
begin
   Ship.Visibility.ShowGrid:=not Ship.Visibility.ShowGrid;
   UpdateMenu;
end;
procedure TMainForm.UndoExecute(Sender: TObject);
    begin Ship.Edit.Undo; UpdateMenu; SetCaption; end;
// Update undo memory usage
procedure TMainForm.FreeShipUpdateUndoData(Sender: TObject);
var Memory : Integer;
begin
   Memory:=Trunc(Ship.UndoMemory/1024);
   if Memory<1024 then Panel2.Caption:=Userstring(283)+' : '+IntToStr(Memory)+' Kb.'
                  else Panel2.Caption:=Userstring(283)+' : '+FloatToDec(Memory/1024,3)+' Mb.';
   Undo.Enabled:=Ship.UndoCount>0;
   SetCaption;
   UpdateMenu;
end;

procedure TMainForm.InvertFaceExecute(Sender: TObject);
    begin Ship.Edit.Face_Flip; UpdateMenu; end;
procedure TMainForm.PreferencesExecute(Sender: TObject);
    begin Ship.Preferences.Edit; UpdateMenu; end;
procedure TMainForm.ImportBodyplanExecute(Sender: TObject);
begin
   Ship.Edit.ImportFrames;
   FOpenHullWindows;
   SetCaption;
   UpdateMenu;
end;
procedure TMainForm.ExportDXF3DPolylinesExecute(Sender: TObject);
    begin Ship.Edit.File_ExportDXF_3DPolylines; UpdateMenu; end;
procedure TMainForm.ExportDXFFacesExecute(Sender: TObject);
    begin Ship.Edit.File_ExportDXF_Faces; UpdateMenu; end;
procedure TMainForm.ImportHullFileExecute(Sender: TObject);
begin
   Ship.Edit.File_ImportHull;
   FOpenHullWindows;
   UpdateMenu;
end;
procedure TMainForm.ExportOffsetsExecute(Sender: TObject);
    begin Ship.Edit.File_ExportOffsets; UpdateMenu; end;
procedure TMainForm.MoveModelExecute(Sender: TObject);
    begin Ship.Edit.Face_Move; UpdateMenu; end;
procedure TMainForm.AddPointExecute(Sender: TObject);
    begin Ship.Edit.Point_New; UpdateMenu; end;
procedure TMainForm.DevelopLayersExecute(Sender: TObject);
    begin Ship.Edit.Layer_Develop; UpdateMenu; end;
procedure TMainForm.ExportArchimedesExecute(Sender: TObject);
    begin Ship.Edit.File_ExportArchimedes; UpdateMenu; end;

procedure TMainForm.ShowLinesplanExecute(Sender: TObject);
  var Form: TFreeLinesplanForm;
begin
   if Ship.LinesplanFrame<>nil then with FreeLinesplanForm do begin
      WindowState:=wsNormal;
      BringToFront;
   end else begin
      Form:=TFreeLinesplanForm.Create( self );
      Form.PopUpParent:=Self;
      Form.FormStyle:=fsNormal;
      Form.BorderStyle:=bsSizeable;
      ShowTranslatedValues( Form.LinesplanFrame );
      ShowTranslatedValues( Form) ;
      Form.LinesplanFrame.FreeShip:=Ship;
      Form.LinesplanFrame.Viewport.ZoomExtents;
      FreeLinesplanForm:=Form;
      WindowMenu;
end end;

procedure TMainForm.ShowDiagonalsExecute(Sender: TObject);
begin
   Ship.Visibility.ShowDiagonals:=not Ship.Visibility.ShowDiagonals;
   UpdateMenu;
end;

procedure TMainForm.FreeShipUpdateRecentFileList(Sender: TObject);
var I: Integer; Item: TMenuItem;
begin                                                  // delete old menu items
   RecentFiles.Clear;                                       // add the new data
   for I:=1 to Ship.Edit.RecentFileCount do begin
      Item:=TMenuItem.Create(self);
      Item.Caption:=Ship.Edit.RecentFile[I-1];
      Item.OnClick:=FLoadRecentFile;
      RecentFiles.Add(Item);
   end;
   UpdateMenu;
end;
procedure TMainForm.ImportCareneExecute(Sender: TObject);
begin
   Ship.Edit.File_ImportCarene;
   FOpenHullWindows;
   UpdateMenu;
end;
procedure TMainForm.ShowMarkersExecute(Sender: TObject);
begin
   Ship.Visibility.ShowMarkers:=not Ship.Visibility.ShowMarkers;
   UpdateMenu;
end;
procedure TMainForm.DeleteMarkersExecute(Sender: TObject);
    begin Ship.Edit.Marker_Delete; UpdateMenu; end;
procedure TMainForm.ImportSurfaceExecute(Sender: TObject);
begin
   Ship.Edit.File_ImportSurface;
   FOpenHullWindows;
   SetCaption;
   UpdateMenu;
end;
procedure TMainForm.ShowcurvatureExecute(Sender: TObject);
begin
   Ship.Visibility.ShowCurvature:=not Ship.Visibility.ShowCurvature;
   UpdateMenu;
end;
procedure TMainForm.IncreaseCurvatureScaleExecute(Sender: TObject);
    begin Ship.Visibility.IncreaseCurvatureScale; end;
procedure TMainForm.DecreaseCurvatureScaleExecute(Sender: TObject);
    begin Ship.Visibility.DecreaseCurvatureScale; end;
procedure TMainForm.FileSaveExecute(Sender: TObject);
    begin Ship.Edit.File_Save; UpdateMenu; end;
procedure TMainForm.ShowControlCurvesExecute(Sender: TObject);
begin
   Ship.Visibility.ShowControlCurves:=not Ship.Visibility.ShowControlCurves;
   UpdateMenu;
end;
procedure TMainForm.NewCurveExecute(Sender: TObject);
    begin Ship.Edit.Curve_Add; UpdateMenu; end;
procedure TMainForm.ExportCoordinatesExecute(Sender: TObject);
    begin Ship.Edit.File_ExportCoordinates; UpdateMenu; end;
procedure TMainForm.InsertPlaneExecute(Sender: TObject);
    begin Ship.Edit.Point_InsertPlane; UpdateMenu; end;
procedure TMainForm.PointsLockExecute(Sender: TObject);
    begin Ship.Edit.Point_Lock; UpdateMenu; end;
procedure TMainForm.PointsUnlockExecute(Sender: TObject);
    begin Ship.Edit.Point_Unlock; UpdateMenu; end;
procedure TMainForm.PointsUnlockAllExecute(Sender: TObject);
    begin Ship.Edit.Point_UnlockAll; UpdateMenu; end;
procedure TMainForm.ImportMarkersExecute(Sender: TObject);
    begin Ship.Edit.Marker_Import; UpdateMenu; end;
procedure TMainForm.FreeShipChangeCursorIncrement(Sender: TObject);
begin
   Panel3.Caption:=Userstring(284)+': '+FloatToDec(Ship.Visibility.CursorIncrement,5);
end;
procedure TMainForm.Panel3Click(Sender: TObject);
var Str: String; I: integer; Value: Real;
begin
   if Ship.Surface.NumberOfControlPoints=0 then exit;
   Str:=FloatToDec( Ship.Visibility.CursorIncrement,5 );
   if InputQuery( '',Userstring(285)+':',Str ) then begin
      Val( Str,Value,I );
      if I=0 then Ship.Visibility.CursorIncrement:=Value;
   end;
end;
procedure TMainForm.PointAlignExecute(Sender: TObject);
    begin Ship.Edit.Point_ProjectStraightLine; UpdateMenu; end;
procedure TMainForm.MirrorFaceExecute(Sender: TObject);
    begin Ship.Edit.Face_MirrorPlane; UpdateMenu; end;
procedure TMainForm.ExportDXF2DPolylinesExecute(Sender: TObject);
    begin Ship.Edit.File_ExportDXF_2DPolylines; UpdateMenu; end;
procedure TMainForm.SpinEditFontSizeChange( Sender: TObject );
var I: integer;                              // нет единого управления шрифтами
begin
  Ship.Preferences.FontSize:=SpinEditFontSize.value;
//if SpinEditFontSize.value<10 then SpinEditFontSize.Constraints.MinWidth:=16+24+2
//                             else SpinEditFontSize.Constraints.MinWidth:=16+16+24+2;
  SpinEditFontSize.Width:=SpinEditFontSize.Constraints.MinWidth;
  for I:=0 to Ship.nV-1 do Ship.ViewPort[I].InValidate;
end;

procedure TMainForm.FreeShipUpdateGeometryInfo(Sender: TObject);
Var Str: String;
begin with Ship.Surface do begin
  Str:=UserString(288);                                          // Узлы Points
  if NumberOfControlPoints>NumberofSelectedControlPoints then Str:=Str+' '+IntToStr( NumberOfControlPoints );
  if NumberofSelectedControlPoints>0 then Str:=Str+'\'+IntToStr( NumberOfSelectedControlPoints );
  Str:=Str+',  '+UserString(287);                                // Рёбра Edges
  if NumberOfControlEdges>NumberofSelectedControlEdges then Str:=Str+' '+IntToStr( NumberOfControlEdges );
  if NumberofSelectedControlEdges>0 then Str:=Str+'\'+IntToStr( NumberOfSelectedControlEdges );
  if NumberOfControlFaces>0 then begin
    Str:=Str+',  '+UserString(286);                              // Грани Faces
    if NumberOfControlFaces>NumberofSelectedControlFaces then Str:=Str+' '+IntToStr( NumberOfControlFaces );
    if NumberofSelectedControlFaces>0 then Str:=Str+'\'+IntToStr( NumberOfSelectedControlFaces );
  end;
  if NumberOfControlCurves>0 then begin
    Str:=Str+',  '+UserString(289);                           // Контуры Curves
    if NumberOfControlCurves>NumberofSelectedControlEdges then Str:=Str+' '+IntToStr( NumberOfControlCurves );
    if NumberofSelectedControlCurves>0 then Str:=Str+'\'+IntToStr( NumberOfSelectedControlCurves );
  end;
  Panel4.Caption:=Str;
end end;
procedure TMainForm.TransformLackenbyExecute(Sender: TObject);
    begin Ship.Edit.Model_LackenbyTransformation; UpdateMenu; end;
procedure TMainForm.ExportIGESExecute(Sender: TObject);
    begin Ship.Edit.File_ExportIGES; UpdateMenu; end;
procedure TMainForm.ExportPartExecute(Sender: TObject);
    begin Ship.Edit.File_ExportPart; UpdateMenu; end;
procedure TMainForm.ImportPartExecute(Sender: TObject);
    begin Ship.Edit.File_ImportPart; UpdateMenu; end;
procedure TMainForm.LayerIntersectionExecute(Sender: TObject);
    begin Ship.Edit.Point_IntersectLayer; UpdateMenu; end;
procedure TMainForm.RedoExecute(Sender: TObject);
    begin Ship.Edit.Redo; UpdateMenu; SetCaption; end;
procedure TMainForm.ClearUndoExecute(Sender: TObject);
    begin Ship.Edit.Undo_Clear; UpdateMenu; end;
procedure TMainForm.ShowUndoHistoryExecute(Sender: TObject);
    begin Ship.Edit.Undo_ShowHistory; UpdateMenu; end;
procedure TMainForm.ImportPolyCadExecute(Sender: TObject);
    begin Ship.Edit.File_ImportPolycad; FOpenHullWindows; UpdateMenu; end;
procedure TMainForm.RemoveUnusedPointsExecute(Sender: TObject);
    begin Ship.Edit.Point_RemoveUnused; Updatemenu; end;
procedure TMainForm.ExportGHSExecute(Sender: TObject);
    begin Ship.Edit.File_ExportGHS; UpdateMenu; end;
procedure TMainForm.ShowFlowlinesExecute(Sender: TObject);
begin
   Ship.Visibility.ShowFlowlines:=not Ship.Visibility.ShowFlowlines;
   updatemenu;
end;
procedure TMainForm.SelectAllExecute(Sender: TObject);
    begin Ship.Edit.Selection_SelectAll; UpdateMenu; end;
procedure TMainForm.ExportSTLExecute(Sender: TObject);
    begin Ship.Edit.File_ExportSTL; UpdateMenu; end;

procedure TMainForm.OnSplitSectionLocationChange(Sender: TObject; aV: Real);
    begin Ship.ProjectSettings.MidleFrame:=aV;
          Ship.FileChanged:=True;
          Ship.Redraw;
    end;
procedure TMainForm.MidleFrameDialogExecute( Sender: TObject );
begin
  if FSplitSectionDialog=nil then
     FSplitSectionDialog:=TFreeSplitSectionDialog.Create(Self);
  FSplitSectionDialog.SetDimensions;
                     { Ship.Surface.Max.X+Ship.Surface.Min.X)/2,
                       Ship.DesignHydrostatics.Data.CenterOfBuoyancy.X }
  if Ship.ProjectSettings.MidleFrame > 0
    then FSplitSectionDialog.Mif:=Ship.ProjectSettings.MidleFrame
    else FSplitSectionDialog.Mif:=(Ship.Surface.Max.X+Ship.Surface.Min.X)/2;
  FSplitSectionDialog.OnMifChange:=OnSplitSectionLocationChange;
  Ship.ProjectSettings.UseMidleFrame:=false;
  FSplitSectionDialog.Show;
  Ship.ProjectSettings.MidleFrame:=FSplitSectionDialog.Mif;
//FSplitSectionDialog.Free;
  Ship.FileChanged:=True;
  Ship.Redraw;
  UpdateMenu;
end;
procedure TMainForm.ShowHydrostaticsExecute(Sender: TObject);
begin With Ship.Visibility do ShowHydrostaticData:=not ShowHydrostaticData;
      updatemenu;
end;


end.

