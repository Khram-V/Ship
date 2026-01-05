unit Main;
interface uses Windows,
    SysUtils,Classes,  Graphics,Controls, StdActns {HelpAction},
    Forms,   Menus,    Dialogs, ExtCtrls, DOS,     { exec }
    ActnList,StdCtrls, ComCtrls,Spin,  // LCLIntf  {OpenDocument},
    LazFileUtils,FasterList,LinesplanFrme,STypes,
    SplitSectionDlg,Geometry,ShipUnit,HullformWindow;

type TMainForm = class(TForm) {Ship:TShip;->St:ShipUnit~~TCustomForm}
    ActionList1: TActionList;
    MenuImages : TImageList;
    MainMenu1  : TMainMenu;
    HintBar    : TStatusBar;
    LayerBox,PrecisionBox: TComboBox;
    ToolBar    : TToolBar;
    ColorDialog: TColorDialog;
    SpinEditFontSize: TSpinEdit;         //!!! нет единого управления шрифтами
    StatusBar,Panel1,Panel2,Panel3,Panel4: TPanel;
    TB1,TB2,TB3,TB4,TB5,TB6,TB7,TB8,TB9,TB10,TB11,TB12,TB13,TB14,TB15,TB16,
    TB17,TB18,TB19,TB20,TB21,TB22,TB23,TB24,TB25,TB26,TB27,TB28,TB29,TB30,TB31,
    TB32,TB33,TB34,TB35,TB36,TB37,TB38,TB39,TB40,TB41,TB42,TB43,TB44,TB45,TB46,
                             TB47,TB48,ShowBuildCurve,tbMiddleFrame: TToolButton;
    HelpAction: THelpAction; HelpAbout,HelpContents: TMenuItem;
    ExportAurora     : TAction; AuroraHullVsl    : TMenuItem;
    FramesDialog     : TAction; Intersections1   : TMenuItem;
    ShowHydrostatics,
    ActHydrostatics  : TAction; Hydrostatics1    : TMenuItem;
    MidelDialog      : TAction; miSetSplitSection: TMenuItem;
    CascadeWindow    : TAction; Cascade1         : TMenuItem;
    TileWindow       : TAction; Tile1            : TMenuItem;
    NewWindow        : TAction; NewWindow1       : TMenuItem;
    LoadFile         : TAction; File1            : TMenuItem;
    ExitProgram      : TAction; ExitProgram1     : TMenuItem;
    ShowControlNet   : TAction; ShowControlNet1  : TMenuItem;
    ShowInteriorEdges: TAction; ShowInteriorEdges1:TMenuItem;
    BothSides        : TAction; Showbothsides1   : TMenuItem;
    FileSaveas       : TAction; Save1            : TMenuItem;
    LayerAutoGroup   : TAction; Layer1           : TMenuItem;
    NewLayer         : TAction; New1             : TMenuItem;
    ShowFlowlines    : TAction; Flowlines1       : TMenuItem;
    SelectAll        : TAction; Selectall1       : TMenuItem;
                                Visibility1: TMenuItem;
                                Window1: TMenuItem;
                                Autogroup1: TMenuItem;
                                FindFile: TMenuItem;
                                Edit1: TMenuItem;
                                Point1: TMenuItem;
    NewEdge: TAction;           New2,Edge1: TMenuItem;
                                Face1: TMenuItem;
    EdgeCollapse: TAction;      Collapse1: TMenuItem;
    Delete: TAction;            Delete1: TMenuItem;
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
    AboutAction: TAction;       About1: TMenuItem;
    EdgeSplit: TAction;         Split1: TMenuItem;
    EditProjectSettings: TAction; Project1: TMenuItem;
                                Projectsettings1: TMenuItem;
    CheckModel: TAction;        Tools1: TMenuItem;
                                Analyzesurface1: TMenuItem;
    ShowNormals: TAction;       Normals1: TMenuItem;
    ImportVRML: TAction;        VRML1: TMenuItem;
                                Import1,Export1: TMenuItem;
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
    //                          Curve1: TMenuItem = 'Кривые';
    ShowControlCurves: TAction; Controlcurves1: TMenuItem;
    NewCurve: TAction;          AddCurve1: TMenuItem;
    ExportCoordinates: TAction; Coordinates1: TMenuItem;
    InsertPlane: TAction;       InsertPlane1: TMenuItem;
    PointsLock: TAction;        PointsLock1: TMenuItem;
    PointsUnlock: TAction;      Unlockpoints1: TMenuItem;
    PointsUnlockAll: TAction;   Unlockallpoints1: TMenuItem;
    ImportMarkers: TAction;     Import2: TMenuItem;
                                Markers2: TMenuItem;
    PointAlign: TAction;        Projectline1: TMenuItem;
    MirrorFace: TAction;        MirrorFace1: TMenuItem;
                                Transform1: TMenuItem;
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
    procedure ShipFileChanged(Sender: TObject);
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
    procedure Help1Click(Sender: TObject);
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
    procedure ShipUpdateUndoData(Sender: TObject);
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
    procedure ShipUpdateRecentFileList(Sender: TObject);
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
    procedure ShipChangeCursorIncrement(Sender: TObject);
    procedure Panel3Click(Sender: TObject);
    procedure PointAlignExecute(Sender: TObject);
    procedure MirrorFaceExecute(Sender: TObject);
    procedure ExportDXF2DPolylinesExecute(Sender: TObject);
    procedure ShipUpdateGeometryInfo(Sender: TObject);
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
    FSplitSectionDialog: TSplitSectionDialog;
    procedure OnMidMove(Sender: TObject; aV: Real);
    procedure FLoadRecentFile(sender:TObject);
    procedure ShipChangeLayerData(Sender: TObject);
    procedure ShipChangeActiveLayer(Sender: TObject;Layer: SLayer);
    procedure FOnSelectItem(Sender:TObject);
    procedure FOpenHullWindows; // Creates 4 different views on the hullform
  public
    Windows: TFasterList;       // Список активных окон
    procedure AddWindow( Win: THullWindow );
    procedure DelWindow( Win: THullWindow );
    procedure WindowMenu;       // опции нет, пусть будет процедура
    procedure WinClick( Sender: TObject );
    procedure NewOneWindow;
    procedure NewLinesPlane;
    procedure TileView;
    procedure CascadeView;
    procedure SetCaption;
    procedure UpdateMenu;
end;

var MainForm: TMainForm;

implementation uses SplashWndw,LanguageSupport;
{$R *.lfm}
{$include Main_Wins.inc} // раздельная и групповая обработка оконных запросов

procedure TMainForm.FormShow( Sender: TObject ); Var NF: String='';
begin With St do begin                                // Initialize some data
   OnChangeActiveLayer:=ShipChangeActiveLayer;
   OnChangeLayerData:=ShipChangeLayerData;
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
var Face1,Face2: SControlFace;
    Diff: Boolean;
    I: Integer;
begin
   if (Sender is SControlPoint)
   and (Sender=St.ActiveControlPoint)
   and (St.ActiveControlPoint.Selected=false) then begin
      // The active controlpoint was deselected, probably internally by the subdivision surface.
      // Set the Ship.ActiveControlPoint to nil (which also closes the controlpoint window)
      St.ActiveControlPoint:=nil;
   end;
   if St.NoSelectedControlFaces>0 then begin
      // set the layerbox itemindex to the index of the layer of the selected controlfaces
      Face1:=St.SelectedControlFace[0];
      // check if all selected controlfaces belong to the same layer
      Diff:=False;
      for I:=1 to St.NoSelectedControlFaces do begin
         Face2:=St.SelectedControlFace[I-1];
         if Face1.Layer<>Face2.Layer then begin Diff:=True; Break; end;
      end;
      if not Diff then ShipChangeActiveLayer(self,Face1.Layer)
                  else ShipChangeActiveLayer(self,nil);
   end else ShipChangeActiveLayer(self,St.ActiveLayer);
   UpdateMenu;
end;

procedure TMainForm.SetCaption;
begin if St.FileChanged
         then Caption:='free!Ship   : '+St.Filename+' ('+Userstring(280)+')'
         else Caption:='free!Ship   : '+St.Filename+' ('+Userstring(281)+')';
end;

procedure TMainForm.UpdateMenu; // In this procedure all actions are set to enabled/disabled
var I,NLayers: Integer;    // according to the current state and selected items
begin With St do begin
   NLayers:=0;
   For I:=1 to NoLayers do if Layer[I-1].Count>0 then inc(NLayers); // File menu
   FileSaveas.Enabled:=(Surface.NoControlPoints>0) or FileChanged or FilenameSet;
   FileSave.Enabled:={(FileSaveas.Enabled) and} FileChanged and FilenameSet;
   ExportObj.Enabled:=Surface.NoControlFaces>0;
   ExportSTL.Enabled:=Surface.NoControlFaces>0;
   ExportDXF3DPolylines.Enabled:=((NoStations>0) and (Visibility.ShowStations)) or
                                 ((NoButtocks>0) and (Visibility.ShowButtocks)) or
                                 ((NoWaterlines>0) and (Visibility.ShowWaterlines)) or
                                 ((NoDiagonals>0) and (Visibility.ShowDiagonals)) or
                                 ((NoControlcurves>0) and (Visibility.ShowControlcurves));
   ExportDXF2DPolylines.Enabled:=((NoStations>0) and (Visibility.ShowStations)) or
                                 ((NoButtocks>0) and (Visibility.ShowButtocks)) or
                                 ((NoWaterlines>0) and (Visibility.ShowWaterlines));
   ExportDXFFaces.Enabled:=Surface.NoControlFaces>0;
   ExportIGES.Enabled:=Surface.NoControlFaces>0;
   ExportOffsets.Enabled:=NoStations+NoButtocks+NoWaterlines+
                          NoDiagonals+NoControlCurves>0;
   ExportArchimedes.Enabled:=NoStations>0;
   ExportGHS.Enabled:=NoStations>0;
   RecentFiles.Enabled:=RecentFiles.Count>0;
   ExportCoordinates.Enabled:=Surface.NoControlPoints>0;
   ExportPart.Enabled:=(Surface.NoControlFaces>0);
   ImportPart.Enabled:=(Surface.NoControlFaces>0) and (nV>0);
   // Show controledges and controlpoints
   ShowControlNet.Enabled:=Surface.NoControlPoints>0;
   ShowControlNet.Checked:=Visibility.ShowControlNet;
   // Show interior edges
   ShowInteriorEdges.Enabled:=Surface.NoControlFaces>0;
   ShowInteriorEdges.Checked:=Visibility.ShowInteriorEdges;
   // Show both sides
   BothSides.Checked:=Visibility.ModelView=mvBoth;
   BothSides.Enabled:=Surface.NoControlFaces>0;
   // Delete
   Delete.Enabled:=NoSelectedControlPoints+NoSelectedControlEdges+
                   NoSelectedControlFaces+NoSelectedControlCurves+
                   NoSelectedFlowLines+NoselectedMarkers>0;
   // Window menu actions
   TileWindow.Enabled:=nV>0;
   CascadeWindow.Enabled:=nV>0;
   // Precision
   PrecisionBox.ItemIndex:=Ord(Precision);
   // Layers
   LayerAutoGroup.Enabled:=(Surface.NoControlFaces>1) and (Visibility.ShowInteriorEdges);
   // Tools
   CheckModel.Enabled:=Surface.NoControlFaces>0;
   DevelopLayers.Enabled:=False;
   for I:=1 to NoLayers do
   if (Layer[I-1].Developable) and (Layer[I-1].Count>0) then begin
      DevelopLayers.Enabled:=True;
      break;
   end;
   DeleteMarkers.Enabled:=NoMarkers>0;
// Calculations
   ActHydrostatics.Enabled:=Surface.NoControlFaces>0;
// Hydrostaticsdialog.Enabled:=Surface.NoControlFaces>0;
// CrossCurves.Enabled:=Surface.NoControlFaces>0;
// edit commands
   AddPoint.Enabled:=(nV>0) and (Visibility.ShowControlNet);
   Insertplane.Enabled:=(Surface.NoControlEdges>0) and (Visibility.ShowControlNet);
   LayerIntersection.Enabled:=NLayers>1;
   EdgeCollapse.Enabled:=NoSelectedControlEdges>0;
   NewEdge.Enabled:=NoSelectedControlPoints>1;
   EdgeCrease.Enabled:=NoSelectedControlEdges>0;
   DeselectAll.Enabled:=(NoSelectedControlPoints+NoSelectedControlEdges
                        +NoSelectedControlFaces+NoSelectedControlCurves>0)
                     or (ActiveControlPoint<>nil);
   NewCurve.Enabled:=NoSelectedControlEdges>0;
   PointCollapse.Enabled:=NoSelectedControlPoints>0;
   DeleteEmptyLayers.Enabled:=False;
   for I:=1 to NoLayers do
   if (Layer[I-1].Count=0) and (NoLayers>0) then begin
      DeleteEmptyLayers.Enabled:=True; break;
   end;
   RemoveUnusedPoints.Enabled:=False;
   for I:=1 to Surface.NoControlPoints do
   if Surface.ControlPoint[I-1].NoFaces=0 then begin
      RemoveUnusedPoints.Enabled:=True; break;
   end;
   InvertFace.Enabled:=NoSelectedControlFaces>0;
   ShowStations.Enabled:=NoStations>0;
   ShowStations.Checked:=Visibility.ShowStations;
   ShowButtocks.Enabled:=NoButtocks>0;
   ShowButtocks.Checked:=Visibility.ShowButtocks;
   ShowWaterlines.Enabled:=NoWaterlines>0;
   ShowWaterlines.Checked:=Visibility.ShowWaterlines;
   ShowDiagonals.Enabled:=NoDiagonals>0;
   ShowDiagonals.Checked:=Visibility.ShowDiagonals;
   ShowNormals.Checked:=Visibility.ShowNormals;
   ShowNormals.Enabled:=NoSelectedControlFaces>0;
   ShowGrid.Checked:=Visibility.ShowGrid;
   ShowGrid.Enabled:=NoStations+NoButtocks+NoWaterlines+NoDiagonals>0;
   ShowMarkers.Checked:=Visibility.ShowMarkers;
   ShowMarkers.Enabled:=NoMarkers>0;
   ShowCurvature.Checked:=Visibility.ShowCurvature;
   ShowCurvature.Enabled:=NoStations+NoButtocks+NoWaterlines+NoDiagonals+NoControlCurves>0;
   ShowControlCurves.Checked:=Visibility.ShowControlCurves;
   ShowControlCurves.Enabled:=Surface.NoControlCurves>0;
   ShowHydrostatics.Checked:=Visibility.ShowHydrostaticData;
// ShowHydrostatics.Enabled:=(Surface.NoControlFaces>2) and (ProjectSettings.MainparticularsHasBeenset);
   ShowFlowlines.Checked:=Visibility.ShowFlowlines;
   ShowFlowlines.Enabled:=NoFlowLines>0;
   NewFace.Enabled:=NoSelectedControlPoints>2;
   FramesDialog.Enabled:=Surface.NoControlFaces>0;
   EdgeExtrude.Enabled:=NoSelectedControlEdges>0;
   EdgeSplit.Enabled:=NoSelectedControlEdges>0;
   RotateModel.Enabled:=Surface.NoControlPoints>0;
   ScaleModel.Enabled:=Surface.NoControlPoints>0;
   MoveModel.Enabled:=Surface.NoControlPoints>0;
   Mirrorface.Enabled:=Surface.NoControlFaces>0;      // Skip translation
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
   PointsLock.Enabled:=(NoSelectedControlPoints>0)
          and (NoSelectedLockedPoints<NoSelectedControlPoints);
   PointsUnlock.Enabled:=NoSelectedLockedPoints>0;
   PointsUnlockAll.Enabled:=NoLockedPoints>0;
   PointAlign.Enabled:=NoSelectedControlPoints>2;
   TransformLackenby.Enabled:=Surface.NoControlFaces>0;
   if Assigned( OnUpdateGeometryInfo )
           then OnUpdateGeometryInfo( St);
// ActiveControlPoint:=ActiveControlPoint;
   WindowMenu;
end; end;

procedure TMainForm.LoadFileExecute( Sender: TObject );
    begin St.Edit.File_Load; // FOpenHullWindows;
          SetCaption;
          UpdateMenu;
    end;

procedure TMainForm.ShowControlNetExecute(Sender: TObject);
    begin St.Visibility.ShowControlNet:=not St.Visibility.ShowControlNet;
          UpdateMenu;
    end;
procedure TMainForm.ShowInteriorEdgesExecute(Sender: TObject);
    begin St.Visibility.ShowInteriorEdges:=not St.Visibility.ShowInteriorEdges;
          UpdateMenu;
    end;
procedure TMainForm.NewWindowExecute(Sender: TObject);
    begin NewOneWindow; end;

procedure TMainForm.ShowLinesplanExecute(Sender: TObject);
   begin NewLinesPlane; end;

procedure TMainForm.ShipFileChanged(Sender: TObject);
    begin SetCaption; end;

procedure TMainForm.PrecisionBoxChange(Sender: TObject);
    begin St.Precision:=TPrecisionType( PrecisionBox.ItemIndex );
          UpdateMenu;
    end;
procedure TMainForm.FileSaveasExecute(Sender: TObject);
    begin St.Edit.File_SaveAs; UpdateMenu; SetCaption; end;

procedure TMainForm.LayerAutoGroupExecute(Sender: TObject);
    begin St.Edit.Layer_AutoGroup; UpdateMenu; end;

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
         Answer:=St.Edit.File_SaveCheck;
         if (Answer=mrCancel) or St.FileChanged then exit;
         St.Edit.File_Load( RName );
//       FOpenHullWindows;
         SetCaption;
         UpdateMenu;
      end;
   end;
end;

procedure TMainForm.ShipChangeLayerData( Sender: TObject ); var I: Integer;
begin                              // Fill the layerbox with the current layers
   LayerBox.Items.BeginUpdate;
   LayerBox.Items.Clear;
   for I:=1 to St.NoLayers do
       Layerbox.Items.AddObject(St.Layer[I-1].Name,St.Layer[I-1]);
   LayerBox.Items.EndUpdate;
   I:=LayerBox.Items.IndexOfObject(St.ActiveLayer);
   Layerbox.ItemIndex:=I;
end;

procedure TMainForm.ShipChangeActiveLayer(Sender: TObject;Layer: SLayer);
var Index : Integer;
begin
   if (St.NoSelectedControlFaces<>0)
   and (St.ActiveLayer=Layer) then begin // do not switch to the active layer when controlfaces are selected
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
    begin St.Edit.Layer_New; UpdateMenu; end;
procedure TMainForm.DeleteExecute(Sender: TObject);
    begin St.Edit.Selection_Delete; UpdateMenu; end;
procedure TMainForm.EdgeCollapseExecute(Sender: TObject);
    begin St.Edit.Edge_Collapse; UpdateMenu; end;
procedure TMainForm.NewEdgeExecute(Sender: TObject);
    begin St.Edit.Edge_Connecte; UpdateMenu; end;
procedure TMainForm.EdgeCreaseExecute(Sender: TObject);
    begin St.Edit.Edge_Crease; UpdateMenu; end;
procedure TMainForm.DeselectAllExecute(Sender: TObject);
    begin St.Edit.Selection_Clear; UpdateMenu; end;
procedure TMainForm.PointCollapseExecute(Sender: TObject);
    begin St.Edit.Point_Collapse; UpdateMenu; end;

procedure TMainForm.LayerBoxChange(Sender: TObject);
var Layer: SLayer; I,Index : Integer;
begin
   Index:=Layerbox.ItemIndex;
   if index=-1 then Index:=0;
   Layer:=Layerbox.Items.Objects[index] as SLayer;
   if St.NoSelectedControlFaces=0 then begin // change the active layer
      if Layer<>St.ActiveLayer then St.ActiveLayer:=Layer;
   end else begin          // Assign all selected controlfaces to the new layer
      for I:=St.NoSelectedControlFaces downto 1 do
         St.SelectedControlFace[I-1].Layer:=Layer;
      St.FileChanged:=True;
      St.Redraw;
   end;
   UpdateMenu;
end;

procedure TMainForm.Panel1Click(Sender: TObject);
    begin ActiveLayerColorExecute(self); end;

procedure TMainForm.ActiveLayerColorExecute(Sender: TObject);
begin // change the color of the currently active layer
   ColorDialog.Color:=St.ActiveLayer.Color;
   if ColorDialog.Execute then begin
      St.ActiveLayer.Color:=ColorDialog.Color;
      St.FileChanged:=True;
      St.Redraw;
      ShipChangeActiveLayer(self,St.ActiveLayer);
      UpdateMenu;
   end;
end;
procedure TMainForm.DeleteEmptyLayersExecute(Sender: TObject);
    begin St.Edit.Layer_DeleteEmpty(False); UpdateMenu; end;
procedure TMainForm.LayerDialogExecute(Sender: TObject);
    begin St.Edit.Layer_Dialog; UpdateMenu; end;
procedure TMainForm.NewModelExecute(Sender: TObject);
    begin if St.Edit.Model_New then FOpenHullWindows; Updatemenu;
    end;
procedure TMainForm.ShowStationsExecute(Sender: TObject);
    begin St.Visibility.ShowStations:=not St.Visibility.ShowStations;
          UpdateMenu;
    end;
procedure TMainForm.ShowButtocksExecute(Sender: TObject);
    begin St.Visibility.ShowButtocks:=not St.Visibility.ShowButtocks;
          UpdateMenu;
    end;
procedure TMainForm.ShowWaterlinesExecute(Sender: TObject);
    begin St.Visibility.ShowWaterlines:=not St.Visibility.ShowWaterlines;
          UpdateMenu;
    end;
procedure TMainForm.NewFaceExecute(Sender: TObject);
    begin St.Edit.Face_New; UpdateMenu; end;
procedure TMainForm.IntersectionDialogExecute(Sender: TObject);
    begin St.Edit.Intersection_Dialog; UpdateMenu; end;
procedure TMainForm.DesignHydrostaticsExecute(Sender: TObject);
      var Calculation: HydrostaticCalc;
    begin Calculation:=St.Edit.Hydrostatics_Calculate
          ( St.ProjectSettings.ProjectDraft,0.0,0.0 );
          if Calculation<>nil then FreeAndNil( Calculation );
    end;
procedure TMainForm.EdgeExtrudeExecute(Sender: TObject);
    begin St.Edit.Edge_Extrude; UpdateMenu; end;
procedure TMainForm.About1Click(Sender: TObject);   // Show splash screen again
    begin SplashWindow:=TSplashWindow.Create( Application );
          ShowTranslatedValues( SplashWindow );
          SplashWindow.Show;
          SplashWindow.Refresh;
    end;
procedure TMainForm.Help1Click(Sender: TObject);
  Var Man: String;
begin Man:=St.Preferences.ManualsDirectory+St.Preferences.Language+'.pdf';
  if not FileExistsUTF8( Man ) then begin
     write( Man ); Man:=St.Preferences.ManualsDirectory+'Russian.pdf';
     write( ' -> ',Man );
     if not FileExistsUTF8( Man ) then begin writeln( ' not found' ); exit end;
     writeln;
  end;
  Exec( {GetEnv( 'COMSPEC')} 'cmd','/C Start '+Man );
//OpenDocument( Man ) = +10 Kb ~~ ComSpec=C:\WINDOWS\system32\cmd.exe
end;
procedure TMainForm.EdgeSplitExecute(Sender: TObject);
    begin St.Edit.Edge_Split; UpdateMenu; end;
procedure TMainForm.EditProjectSettingsExecute(Sender: TObject);
    begin St.ProjectSettings.Edit; UpdateMenu; end;
procedure TMainForm.CheckModelExecute(Sender: TObject);
    begin St.Edit.Model_Check(True); UpdateMenu; end;
procedure TMainForm.ShowNormalsExecute(Sender: TObject);
    begin St.Visibility.ShowNormals:=not St.Visibility.ShowNormals;
          UpdateMenu;
    end;
procedure TMainForm.ExportAuroraHullVslExecute(Sender: TObject);
    begin St.Edit.File_Export_Aurora_Experiments; UpdateMenu; end;
procedure TMainForm.ImportOBJExecute(Sender: TObject);
    begin St.Edit.File_ImportOBJ; FOpenHullWindows; SetCaption; UpdateMenu;
    end;
procedure TMainForm.ExportObjExecute(Sender: TObject);
    begin St.Edit.File_ExportObj; UpdateMenu; end;
procedure TMainForm.ImportSTLExecute(Sender: TObject);
    begin St.Edit.File_ImportSTL; FOpenHullWindows; SetCaption; UpdateMenu;
    end;
procedure TMainForm.ImportVRMLExecute(Sender: TObject);
    begin St.Edit.File_ImportVRML; FOpenHullWindows; UpdateMenu; end;
procedure TMainForm.RemoveNegativeExecute(Sender: TObject);
    begin St.Edit.Face_DeleteNegative; UpdateMenu; end;
procedure TMainForm.RotateModelExecute(Sender: TObject);
    begin St.Edit.Face_Rotate; UpdateMenu; end;
procedure TMainForm.ScaleModelExecute(Sender: TObject);
    begin St.Edit.Face_Scale; UpdateMenu; end;
procedure TMainForm.ShowGridExecute(Sender: TObject);
    begin St.Visibility.ShowGrid:=not St.Visibility.ShowGrid; UpdateMenu;
    end;
procedure TMainForm.UndoExecute(Sender: TObject);
    begin St.Edit.Undo; UpdateMenu; SetCaption; end;

// Update undo memory usage
procedure TMainForm.ShipUpdateUndoData(Sender: TObject);
var Memory : Integer;
begin
   Memory:=Trunc( St.UndoMemory/1024 );
   if Memory<1024 then Panel2.Caption:=Userstring(283)+' : '+IntToStr(Memory)+' Kb.'
                  else Panel2.Caption:=Userstring(283)+' : '+FloatToDec(Memory/1024,3)+' Mb.';
   Undo.Enabled:=St.UndoCount>0;
   SetCaption;
   UpdateMenu;
end;
procedure TMainForm.InvertFaceExecute(Sender: TObject);
    begin St.Edit.Face_Flip; UpdateMenu; end;
procedure TMainForm.PreferencesExecute(Sender: TObject);
    begin St.Preferences.Edit; UpdateMenu; end;
procedure TMainForm.ImportBodyplanExecute(Sender: TObject);
    begin St.Edit.ImportFrames;
          FOpenHullWindows;
          SetCaption;
          UpdateMenu;
    end;
procedure TMainForm.ExportDXF3DPolylinesExecute(Sender: TObject);
    begin St.Edit.File_ExportDXF_3DPolylines; UpdateMenu; end;
procedure TMainForm.ExportDXFFacesExecute(Sender: TObject);
    begin St.Edit.File_ExportDXF_Faces; UpdateMenu; end;
procedure TMainForm.ImportHullFileExecute(Sender: TObject);
    begin St.Edit.File_ImportHull; FOpenHullWindows; UpdateMenu; end;
procedure TMainForm.ExportOffsetsExecute(Sender: TObject);
    begin St.Edit.File_ExportOffsets; UpdateMenu; end;
procedure TMainForm.MoveModelExecute(Sender: TObject);
    begin St.Edit.Face_Move; UpdateMenu; end;
procedure TMainForm.AddPointExecute(Sender: TObject);
    begin St.Edit.Point_New; UpdateMenu; end;
procedure TMainForm.DevelopLayersExecute(Sender: TObject);
    begin St.Edit.Layer_Develop; UpdateMenu; end;
procedure TMainForm.ExportArchimedesExecute(Sender: TObject);
    begin St.Edit.File_ExportArchimedes; UpdateMenu; end;
procedure TMainForm.ShowDiagonalsExecute(Sender: TObject);
    begin St.Visibility.ShowDiagonals:=not St.Visibility.ShowDiagonals;
          UpdateMenu;
    end;
procedure TMainForm.ShipUpdateRecentFileList(Sender: TObject);
var I: Integer; Item: TMenuItem;
begin                                                  // delete old menu items
   RecentFiles.Clear;                                       // add the new data
   for I:=1 to St.Edit.RecentFileCount do begin
      Item:=TMenuItem.Create(self);
      Item.Caption:=St.Edit.RecentFile[I-1];
      Item.OnClick:=FLoadRecentFile;
      RecentFiles.Add(Item);
   end;
   UpdateMenu;
end;
procedure TMainForm.ImportCareneExecute(Sender: TObject);
    begin St.Edit.File_ImportCarene; FOpenHullWindows; UpdateMenu; end;
procedure TMainForm.ShowMarkersExecute(Sender: TObject);
    begin St.Visibility.ShowMarkers:=not St.Visibility.ShowMarkers;
          UpdateMenu;
    end;
procedure TMainForm.DeleteMarkersExecute(Sender: TObject);
    begin St.Edit.Marker_Delete; UpdateMenu; end;
procedure TMainForm.ImportSurfaceExecute(Sender: TObject);
    begin St.Edit.File_ImportSurface; FOpenHullWindows; SetCaption;
          UpdateMenu;
    end;
procedure TMainForm.ShowcurvatureExecute(Sender: TObject);
    begin St.Visibility.ShowCurvature:=not St.Visibility.ShowCurvature;
          UpdateMenu;
    end;
procedure TMainForm.IncreaseCurvatureScaleExecute(Sender: TObject);
    begin St.Visibility.IncreaseCurvatureScale; end;
procedure TMainForm.DecreaseCurvatureScaleExecute(Sender: TObject);
    begin St.Visibility.DecreaseCurvatureScale; end;
procedure TMainForm.FileSaveExecute(Sender: TObject);
    begin St.Edit.File_Save; UpdateMenu; end;
procedure TMainForm.ShowControlCurvesExecute(Sender: TObject);
    begin St.Visibility.ShowControlCurves:=not St.Visibility.ShowControlCurves;
          UpdateMenu;
    end;
procedure TMainForm.NewCurveExecute(Sender: TObject);
    begin St.Edit.Curve_Add; UpdateMenu; end;
procedure TMainForm.ExportCoordinatesExecute(Sender: TObject);
    begin St.Edit.File_ExportCoordinates; UpdateMenu; end;
procedure TMainForm.InsertPlaneExecute(Sender: TObject);
    begin St.Edit.Point_InsertPlane; UpdateMenu; end;
procedure TMainForm.PointsLockExecute(Sender: TObject);
    begin St.Edit.Point_Lock; UpdateMenu; end;
procedure TMainForm.PointsUnlockExecute(Sender: TObject);
    begin St.Edit.Point_Unlock; UpdateMenu; end;
procedure TMainForm.PointsUnlockAllExecute(Sender: TObject);
    begin St.Edit.Point_UnlockAll; UpdateMenu; end;
procedure TMainForm.ImportMarkersExecute(Sender: TObject);
    begin St.Edit.Marker_Import; UpdateMenu; end;
procedure TMainForm.ShipChangeCursorIncrement(Sender: TObject);
begin
   Panel3.Caption:=Userstring(284)+': '+FloatToDec(St.Visibility.CursorIncrement,5);
end;
procedure TMainForm.Panel3Click(Sender: TObject);
var Str: String; I: integer; Value: Real;
begin
   if St.Surface.NoControlPoints=0 then exit;
   Str:=FloatToDec( St.Visibility.CursorIncrement,5 );
   if InputQuery( '',Userstring(285)+':',Str ) then begin
      Val( Str,Value,I );
      if I=0 then St.Visibility.CursorIncrement:=Value;
   end;
end;
procedure TMainForm.PointAlignExecute(Sender: TObject);
    begin St.Edit.Point_ProjectStraightLine; UpdateMenu; end;
procedure TMainForm.MirrorFaceExecute(Sender: TObject);
    begin St.Edit.Face_MirrorPlane; UpdateMenu; end;
procedure TMainForm.ExportDXF2DPolylinesExecute(Sender: TObject);
    begin St.Edit.File_ExportDXF_2DPolylines; UpdateMenu; end;
procedure TMainForm.SpinEditFontSizeChange( Sender: TObject );
var I: integer;                              // нет единого управления шрифтами
begin
  St.Preferences.FontSize:=SpinEditFontSize.value;
//if SpinEditFontSize.value<10 then SpinEditFontSize.Constraints.MinWidth:=16+24+2
//                             else SpinEditFontSize.Constraints.MinWidth:=16+16+24+2;
  SpinEditFontSize.Width:=SpinEditFontSize.Constraints.MinWidth;
  for I:=0 to St.nV-1 do St.ViewPort[I].InValidate;
end;

procedure TMainForm.ShipUpdateGeometryInfo(Sender: TObject);
Var Str: String;
begin with St.Surface do begin
  Str:=UserString(288);                                          // Узлы Points
  if NoControlPoints>NoSelectedControlPoints then Str:=Str+' '+IntToStr( NoControlPoints );
  if NoSelectedControlPoints>0 then Str:=Str+'\'+IntToStr( NoSelectedControlPoints );
  Str:=Str+',  '+UserString(287);                                // Рёбра Edges
  if NoControlEdges>NoSelectedControlEdges then Str:=Str+' '+IntToStr( NoControlEdges );
  if NoSelectedControlEdges>0 then Str:=Str+'\'+IntToStr( NoSelectedControlEdges );
  if NoControlFaces>0 then begin
    Str:=Str+',  '+UserString(286);                              // Грани Faces
    if NoControlFaces>NoSelectedControlFaces then Str:=Str+' '+IntToStr( NoControlFaces );
    if NoSelectedControlFaces>0 then Str:=Str+'\'+IntToStr( NoSelectedControlFaces );
  end;
  if NoControlCurves>0 then begin
    Str:=Str+',  '+UserString(289);                           // Контуры Curves
    if NoControlCurves>NoSelectedControlEdges then Str:=Str+' '+IntToStr( NoControlCurves );
    if NoSelectedControlCurves>0 then Str:=Str+'\'+IntToStr( NoSelectedControlCurves );
  end;
  Panel4.Caption:=Str;
end end;
procedure TMainForm.TransformLackenbyExecute(Sender: TObject);
    begin St.Edit.Model_LackenbyTransformation; UpdateMenu; end;
procedure TMainForm.ExportIGESExecute(Sender: TObject);
    begin St.Edit.File_ExportIGES; UpdateMenu; end;
procedure TMainForm.ExportPartExecute(Sender: TObject);
    begin St.Edit.File_ExportPart; UpdateMenu; end;
procedure TMainForm.ImportPartExecute(Sender: TObject);
    begin St.Edit.File_ImportPart; UpdateMenu; end;
procedure TMainForm.LayerIntersectionExecute(Sender: TObject);
    begin St.Edit.Point_IntersectLayer; UpdateMenu; end;
procedure TMainForm.RedoExecute(Sender: TObject);
    begin St.Edit.Redo; UpdateMenu; SetCaption; end;
procedure TMainForm.ClearUndoExecute(Sender: TObject);
    begin St.Edit.Undo_Clear; UpdateMenu; end;
procedure TMainForm.ShowUndoHistoryExecute(Sender: TObject);
    begin St.Edit.Undo_ShowHistory; UpdateMenu; end;
procedure TMainForm.ImportPolyCadExecute(Sender: TObject);
    begin St.Edit.File_ImportPolycad; FOpenHullWindows; UpdateMenu; end;
procedure TMainForm.RemoveUnusedPointsExecute(Sender: TObject);
    begin St.Edit.Point_RemoveUnused; Updatemenu; end;
procedure TMainForm.ExportGHSExecute(Sender: TObject);
    begin St.Edit.File_ExportGHS; UpdateMenu; end;
procedure TMainForm.ShowFlowlinesExecute(Sender: TObject);
    begin St.Visibility.ShowFlowlines:=not St.Visibility.ShowFlowlines;
          updatemenu;
    end;
procedure TMainForm.SelectAllExecute(Sender: TObject);
    begin St.Edit.Selection_SelectAll; UpdateMenu; end;
procedure TMainForm.ExportSTLExecute(Sender: TObject);
    begin St.Edit.File_ExportSTL; UpdateMenu; end;
procedure TMainForm.OnMidMove(Sender: TObject; aV: Real);
    begin St.ProjectSettings.MidleFrame:=aV;
          St.FileChanged:=True;
          St.Redraw;
    end;
procedure TMainForm.MidleFrameDialogExecute( Sender: TObject );
begin
  if FSplitSectionDialog=nil then
     FSplitSectionDialog:=TSplitSectionDialog.Create(Self);
  FSplitSectionDialog.SetDimensions;
                    { St.Surface.Max.X+St.Surface.Min.X)/2,
                      St.DesignHydrostatics.Data.CenterOfBuoyancy.X }
  if St.ProjectSettings.MidleFrame > 0
    then FSplitSectionDialog.Mif:=St.ProjectSettings.MidleFrame
    else FSplitSectionDialog.Mif:=(St.Surface.Max.X+St.Surface.Min.X)/2;
  FSplitSectionDialog.OnMifChange:=OnMidMove;
  St.ProjectSettings.UseMidleFrame:=false;
  FSplitSectionDialog.Show;
  St.ProjectSettings.MidleFrame:=FSplitSectionDialog.Mif;
//FSplitSectionDialog.Free;
  St.FileChanged:=True;
  St.Redraw;
  UpdateMenu;
end;
procedure TMainForm.ShowHydrostaticsExecute(Sender: TObject);
begin With St.Visibility do ShowHydrostaticData:=not ShowHydrostaticData;
      updatemenu;
end;

end.

