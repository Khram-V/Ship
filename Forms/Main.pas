unit Main;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
     SysUtils,
     Classes,
     Graphics, IntfGraphics,
     Controls, LCLIntf, LCLType, LazFileUtils,
     Forms,
     Math,
     Dialogs,
     ExtCtrls,
     ActnList,
     StdCtrls,
     ComCtrls,
     FreeTypes,
     FreeGeometry,
     FreeShipUnit,
     FreeVersionUnit,
     freehullformwindow_panel, MDIPanel,
     FreeAboutDlg,
     Menus, StdActns, Spin,                     // Buttons, DefaultTranslator,
     Interfaces,
     FreeSplitSectionDlg,
     FreeLayerVisibilityDlg,
     FreeSelectedDlg,FreeLanguageSupport;

type

  { TMainForm }

  TMainForm = class( TForm )                                    // TMainForm

     ToolBarCurves,
     ToolBarFaces,
     ToolBarFile,
     ToolBarEdit,
     ToolBarEdges,
     ToolBarPoints,
     ToolBarVisibility,
     ToolBarLayers : TToolBar;

     ActionList1 : TActionList;
//   FActionListHull : TActionList;

     AboutAction,                   CrossCurves,
     NewModel,                      ResistanceDelft,
     ResistanceKaper,               SelectionDialog,
     SplitSection50pct,             LayerVisibilityDialog,
     SplitSectionDialog,            ShowFreeObjects,
     PointExtrude,                  PointsCoincide,
     AddGridPanel,                  ActionCheckUpdates,
     AddFlowLine,                   SelectAllControlPoints,
     PointAnchor,                   PointAlighnPermanently,
     AddPointToGroup,               SelectLeakPoints,
     LoadFile,                      NewWindow,
     TileWindow,                    CascadeWindow,
     BothSides,                     FileSaveas,
     LayerAutoGroup,                NewLayer,
     Delete,                        ExitProgram,
     ShowControlNet,                ShowInteriorEdges,
     EdgeCollapse,                  NewEdge,
     ImportFEF,                     EdgeCrease,
     DeselectAll,                   PointCollapse,
     ActiveLayerColor,              DeleteEmptyLayers,
     LayerDialog,               //  NewModel,
     ShowStations,                  ShowButtocks,
     ShowWaterlines,                NewFace,
     IntersectionDialog,            EdgeExtrude,
     EdgeSplit,                     ExportFEF,
     EditProjectSettings,           CheckModel,
     ShowNormals,                   DesignHydrostatics,
     ImportVRML: TAction;

     AuroraHullVsl,                 MichletCFD1,
     miSelectionDialog,             miShowLayerVisibilityDialog,
     miSetSplitSection,             miShowFreeObjects,
     miPointExtrude,                MenuItem2,
     MenuItem1,                     CheckUpdates,
     miAddGridPanel,                SelectAllControlPoints1,
     MenuItemPointAnchor,           HelpContents,
     HelpAbout,                     AddControlPointToGroup,
     MenuItemPointAlignPermanently, Visibility1,
     ShowControlNet1,               ShowInteriorEdges1,
     Window1,                       Cascade1,
     Tile1,                         NewWindow1,
     N1,                            Showbothsides1,
     Save1,                         Layer1,
     Autogroup1,                    New1,
     SelectLeakPoints1,             File1,
     Open,                          ExitProgram1,
     Edit1,                         Point1,
     Edge1,                         Face1,
     Collapse1,                     Delete1,
     New2,                          ImportOff1,
     Crease1,                       Selection1,
     Clearselection1,               PointCollapse1,
     Activelayercolor1,             Deleteempty1,
     Deleteempty2,                  New3,
     Stations1,                     Buttocks1,
     Waterlines1,                   New4,
     Extrude1,                      Help1,
     Split1,                        ExportFEFfile1,
     Project1,                      Projectsettings1,
     ools1,                         Analyzesurface1,
     Calculations,                  Hydrostatics1,
     Normals1,                      Export1,
     VRML1,
     Import1: TMenuItem;

     cbPrecision               : TComboBox;
     LayerBox                  : TComboBox;
     ColorButton1              : TColorButton;
     FontDialog1               : TFontDialog;
     HelpAction                : THelpAction;
     LabelProgress             : TLabel;
     LabelNumbers              : TLabel;
     LabelDistance             : TLabel;
     LabelUndoMemory           : TLabel;
     MainClientPanel           : TPanel;
     StatusPanel5              : TPanel;
     PanelMain                 : TPanel;
     ProgressBarMain           : TProgressBar;
    FreeShip                   : TFreeShip;
    SpinEditFontSize           : TSpinEdit;
    StatusBar                  : TPanel;
    MenuImages                 : TImageList;
    MainMenu1                  : TMainMenu;

    tbShowFreeObjects,
    ToolButton1,
    ToolButton39,
    ToolButtonSelect,
    ToolButtonRedo,
    ToolButtonUndo,
 // ToolButtonOpenFile,
 // ToolButton3,
    ToolButton5,
    ToolButton6,
    ToolButton8,
    ToolButton9,
    ToolButton10,
    ToolButton13,
    ToolButtonDelete,
    ToolButton16,
    ToolButton17,
    ToolButton18,
//  ToolButton20,
    ToolButton21,
    ToolButton22,
    ToolButton23,
    ToolButton24,
    ToolButton26,
    ToolButton27,
    ToolButton29,
    ToolButton30: TToolButton;

    ColorDialog : TColorDialog;
    RemoveNegative: TAction;         RemoveNegative1: TMenuItem;
    RotateModel   : TAction;         Rotatemodel1   : TMenuItem;
    RotateModelM  : TAction;         Rotatemodel2   : TMenuItem;
    ScaleModel    : TAction;         Scale3D1       : TMenuItem;
    Undo: TAction;                   Undo1: TMenuItem;
    ShowGrid: TAction;
    ToolButton31: TToolButton;
    Analyzesurface2: TMenuItem;
    StatusPanel2: TPanel;
    HydrostaticsDialog: TAction;
    Hydrostatics2: TMenuItem;
    ExportObj: TAction;
    WavefrontfileObj1: TMenuItem;
    InvertFace: TAction;
    Invert1: TMenuItem;
    ToolButton32: TToolButton;
    ToolButton33: TToolButton;
    Preferences: TAction;
    Preferences1: TMenuItem;
    N2: TMenuItem;
    ImportBodyplan: TAction;
    ExportDXF3DPolylines: TAction;
    ExportDXFPolylines1: TMenuItem;
    ExportDXFFaces: TAction;
    DXF3Dfaces1: TMenuItem;
    ImportHullFile: TAction;
    Carlssonhulfile1: TMenuItem;
    ExportOffsets: TAction;
    Offsets1: TMenuItem;
    MoveModel: TAction;
    Deselectall2: TMenuItem;
    AddPoint: TAction;
    Add1: TMenuItem;
    Intersections1: TMenuItem;
    DevelopLayers: TAction;
    Developplates1: TMenuItem;
    ExportArchimedes: TAction;
    N3: TMenuItem;
    ArchimedesMB1: TMenuItem;
    ToolButton34: TToolButton;
    ShowLinesplan: TAction;
    Linesplan1: TMenuItem;
    ShowDiagonals: TAction;
    ToolButton35: TToolButton;
    Diagonals1: TMenuItem;
    RecentFiles: TMenuItem;
    N4: TMenuItem;
    ImportCarene: TAction;
    Carenefile1: TMenuItem;
    ShowMarkers: TAction;
    ToolButton36: TToolButton;
    Markers1: TMenuItem;
    DeleteMarkers: TAction;
    Deletemarkers1: TMenuItem;
    ImportSurface: TAction;
    Surface1: TMenuItem;
    Showcurvature: TAction;
    ToolButton37: TToolButton;
    IncreaseCurvatureScale: TAction;
    DecreaseCurvatureScale: TAction;
    N5: TMenuItem;
    Decrcurvaturescale1: TMenuItem;
    Incrcurvaturescale1: TMenuItem;
    FileSave: TAction;
//  ToolButton38: TToolButton;
    Save2: TMenuItem;
    Curvature1: TMenuItem;
    ImportChines: TAction;
    Chines1: TMenuItem;
    Curve1: TMenuItem;
    ShowControlCurves: TAction;
    Controlcurves1: TMenuItem;
    ToolButton2: TToolButton;
    NewCurve: TAction;
    AddCurve1: TMenuItem;
    ToolButton40: TToolButton;
    ExportCoordinates: TAction;
    Coordinates1: TMenuItem;
    InsertPlane: TAction;
    InsertPlane1: TMenuItem;
    ToolButton41: TToolButton;
    PointsLock: TAction;
    PointsLock1: TMenuItem;
    PointsUnlock: TAction;
    Unlockpoints1: TMenuItem;
    ToolButton42: TToolButton;
    ToolButton43: TToolButton;
    PointsUnlockAll: TAction;
    Unlockallpoints1: TMenuItem;
    ToolButton44: TToolButton;
    Markers2: TMenuItem;
    ImportMarkers: TAction;
    Import2: TMenuItem;
    ExportAurora: TAction;
    ExportMichlet: TAction;
//    Resistance1: TMenuItem;
//    Kaper1: TMenuItem;
//    ResistanceDelft: TAction;
//    Delftyachtseries1: TMenuItem;
//    ResistanceKaper: TAction;
//    MichletCFD1: TMenuItem;
    StatusPanel3: TPanel;
    PointAlign: TAction;
    ToolButton45: TToolButton;
    Projectline1: TMenuItem;
    ImportMichletWaves: TAction;
    N6: TMenuItem;
    ImportMichletWaves1: TMenuItem;
    ShowHydrostatics: TAction;
    ToolButton46: TToolButton;
    Hydrostaticdata1: TMenuItem;
    MirrorFace: TAction;
    ransform1: TMenuItem;
    MirrorFace1: TMenuItem;
    ExportDXF2DPolylines: TAction;
    DXF2DPolylines1: TMenuItem;
    StatusPanel4: TPanel;
    TransformLackenby: TAction;
    Lackenby1: TMenuItem;
    ExportIGES: TAction;
    IGES1: TMenuItem;
    ExportPart: TAction;
    Part1: TMenuItem;
    ImportPart: TAction;
    Part2: TMenuItem;
    LayerIntersection: TAction;
    ToolButton47: TToolButton;
    Saveas1: TMenuItem;
    KeelRudderWizard: TAction;
    Deleteempty3: TMenuItem;
    Redo: TAction;
    Archimedes1: TMenuItem;
    ClearUndo: TAction;
    N7: TMenuItem;
    Undohistory1: TMenuItem;
    Clear1: TMenuItem;
    ShowUndoHistory: TAction;
    Show1: TMenuItem;
    ImportPolyCad: TAction;
    PolyCad1: TMenuItem;
    RemoveUnusedPoints: TAction;
    Removeunusedpoints1: TMenuItem;
    ExportGHS: TAction;
    GHS1: TMenuItem;
    ShowFlowlines: TAction;
    Flowlines1: TMenuItem;
    ToolButton48: TToolButton;
    AddCylinder: TAction;
    AddCylinder1: TMenuItem;
    SelectAll: TAction;
    Selectall1: TMenuItem;
    ExportSTL: TAction;
    STL1: TMenuItem;
 // CrossCurves: TAction;
 // Crosscurves1: TMenuItem;
 // SelectLeakPoints: TAction;
    SelectionSeparator1: TMenuItem;
    Select_LeakPoints: TMenuItem;

 // FMDIChildList : TList;
    PanelManager: WinPanelManager;                       { FMDIPanelManager }

    procedure ActionCheckUpdatesExecute(Sender: TObject);
    procedure AddFlowLineExecute       (Sender: TObject);
    procedure AddGridPanelExecute      (Sender: TObject);
    procedure AddPointToGroupExecute   (Sender: TObject);
    procedure cbPrecisionChange        (Sender: TObject);
    procedure ColorButton1Click        (Sender: TObject);
    procedure FormActivate             (Sender: TObject);
    procedure FormChangeBounds         (Sender: TObject);
    procedure FormDestroy              (Sender: TObject);
    procedure FormResize               (Sender: TObject);
    procedure FormWindowStateChange    (Sender: TObject);
    procedure LoadFileExecute          (Sender: TObject);
    procedure ExitProgramExecute       (Sender: TObject);
    procedure LayerBoxPanelClick       (Sender: TObject);
    procedure PointExtrudeExecute      (Sender: TObject);
    procedure PointsCoincideExecute    (Sender: TObject);
    procedure SelectionDialogExecute   (Sender: TObject);
    procedure SplitSectionDialogExecute(Sender: TObject);
    procedure ShowFreeObjectsExecute   (Sender: TObject);
    procedure LayerVisibilityDialogExecute(Sender: TObject);
 // function ShowSplashWindow:TModalResult;
    procedure FormShow                 (Sender: TObject);
    procedure MainClientPanelClick     (Sender: TObject);
    procedure MenuItem1Click           (Sender: TObject);
    procedure PanelMainResize          (Sender: TObject);
    procedure PointAnchorExecute       (Sender: TObject);
    procedure SelectAllControlPoints1Click(Sender: TObject);
    procedure SelectAllControlPointsExecute(Sender: TObject);
    procedure ShowControlNetExecute    (Sender: TObject);
    procedure ShowInteriorEdgesExecute (Sender: TObject);
    procedure NewWindowSet(Sender: TObject; ViewType: TFreeViewType );
    procedure NewWindowExecute         (Sender: TObject);
    procedure SpinEditFontSizeChange   (Sender: TObject);
    procedure TileWindowExecute        (Sender: TObject);
    procedure CascadeWindowExecute     (Sender: TObject);
    procedure BothSidesExecute         (Sender: TObject);
    procedure FreeShipFileChanged      (Sender: TObject);
 // procedure PrecisionBoxChange       (Sender: TObject);
    procedure FileSaveasExecute        (Sender: TObject);
    procedure LayerAutoGroupExecute    (Sender: TObject);
    procedure MainFormClose            (Sender: TObject; var Action: TCloseAction);
    procedure NewLayerExecute          (Sender: TObject);
    procedure DeleteExecute            (Sender: TObject);
    procedure EdgeCollapseExecute      (Sender: TObject);
    procedure NewEdgeExecute           (Sender: TObject);
    procedure ImportFEFExecute         (Sender: TObject);
    procedure EdgeCreaseExecute        (Sender: TObject);
    procedure DeselectAllExecute       (Sender: TObject);
    procedure PointCollapseExecute     (Sender: TObject);
    procedure LayerBoxChange           (Sender: TObject);
    procedure PanelActiveLayerColorClick(Sender: TObject);
    procedure ActiveLayerColorExecute  (Sender: TObject);
    procedure DeleteEmptyLayersExecute (Sender: TObject);
    procedure LayerDialogExecute       (Sender: TObject);
    procedure NewModelExecute          (Sender: TObject);
    procedure FormCreate               (Sender: TObject);
    procedure ShowStationsExecute      (Sender: TObject);
    procedure ShowButtocksExecute      (Sender: TObject);
    procedure ShowWaterlinesExecute    (Sender: TObject);
    procedure FormCloseQuery           (Sender: TObject; var CanClose: Boolean);
    procedure NewFaceExecute           (Sender: TObject);
    procedure IntersectionDialogExecute(Sender: TObject);
    procedure EdgeExtrudeExecute       (Sender: TObject);
    procedure About1Click              (Sender: TObject);
    procedure Help1Click               (Sender: TObject);
    procedure EdgeSplitExecute         (Sender: TObject);
    procedure ExportFEFExecute         (Sender: TObject);
    procedure EditProjectSettingsExecute(Sender: TObject);
    procedure CheckModelExecute        (Sender: TObject);
    procedure ShowNormalsExecute       (Sender: TObject);
    procedure DesignHydrostaticsExecute(Sender: TObject);
    procedure ImportVRMLExecute        (Sender: TObject);
    procedure RemoveNegativeExecute    (Sender: TObject);
    procedure RotateModelExecute       (Sender: TObject);
    procedure RotateModelMExecute      (Sender: TObject);
    procedure ScaleModelExecute        (Sender: TObject);
    procedure ShowGridExecute          (Sender: TObject);
    procedure ToolButtonSelectClick    (Sender: TObject);
    procedure UndoExecute              (Sender: TObject);
    procedure FreeShipUpdateUndoData   (Sender: TObject);
    procedure HydrostaticsDialogExecute(Sender: TObject);
    procedure ExportObjExecute         (Sender: TObject);
    procedure InvertFaceExecute        (Sender: TObject);
    procedure PreferencesExecute       (Sender: TObject);
    procedure ImportBodyplanExecute    (Sender: TObject);
    procedure ExportAuroraHullVslExecute(Sender: TObject);
    procedure ExportDXF3DPolylinesExecute(Sender: TObject);
    procedure ExportDXFFacesExecute    (Sender: TObject);
    procedure ImportHullFileExecute    (Sender: TObject);
    procedure ExportOffsetsExecute     (Sender: TObject);
    procedure MoveModelExecute         (Sender: TObject);
    procedure AddPointExecute          (Sender: TObject);
    procedure DevelopLayersExecute     (Sender: TObject);
    procedure ExportArchimedesExecute  (Sender: TObject);
    procedure ShowLinesplanExecute     (Sender: TObject);
    procedure ShowDiagonalsExecute     (Sender: TObject);
    procedure FreeShipUpdateRecentFileList(Sender: TObject);
    procedure ImportCareneExecute      (Sender: TObject);
    procedure ShowMarkersExecute       (Sender: TObject);
    procedure DeleteMarkersExecute     (Sender: TObject);
    procedure ImportSurfaceExecute     (Sender: TObject);
    procedure ShowcurvatureExecute     (Sender: TObject);
    procedure IncreaseCurvatureScaleExecute(Sender: TObject);
    procedure DecreaseCurvatureScaleExecute(Sender: TObject);
    procedure FileSaveExecute          (Sender: TObject);
    procedure ImportChinesExecute      (Sender: TObject);
    procedure ShowControlCurvesExecute (Sender: TObject);
    procedure NewCurveExecute          (Sender: TObject);
    procedure ExportCoordinatesExecute (Sender: TObject);
    procedure InsertPlaneExecute       (Sender: TObject);
    procedure PointsLockExecute        (Sender: TObject);
    procedure PointsUnlockExecute      (Sender: TObject);
    procedure PointsUnlockAllExecute   (Sender: TObject);
    procedure ImportMarkersExecute     (Sender: TObject);
    procedure ExportMichletExecute     (Sender: TObject);
 // procedure ResistanceKaperExecute   (Sender: TObject);
 // procedure ResistanceDelftExecute   (Sender: TObject);
    procedure FreeShipChangeCursorIncrement(Sender: TObject);
    procedure StatusPanel3Click        (Sender: TObject);
    procedure PointAlignExecute        (Sender: TObject);
    procedure PointAlighnPermanentlyExecute(Sender: TObject);
    procedure ImportMichletWavesExecute(Sender: TObject);
    procedure ShowHydrostaticsExecute  (Sender: TObject);
    procedure MirrorFaceExecute        (Sender: TObject);
    procedure ExportDXF2DPolylinesExecute(Sender: TObject);
    procedure FreeShipUpdateGeometryInfo(Sender: TObject);
    procedure TransformLackenbyExecute (Sender: TObject);
    procedure ExportIGESExecute        (Sender: TObject);
    procedure ExportPartExecute        (Sender: TObject);
    procedure ImportPartExecute        (Sender: TObject);
    procedure LayerIntersectionExecute (Sender: TObject);
    procedure KeelRudderWizardExecute  (Sender: TObject);
    procedure RedoExecute              (Sender: TObject);
    procedure ClearUndoExecute         (Sender: TObject);
    procedure ShowUndoHistoryExecute   (Sender: TObject);
    procedure ImportPolyCadExecute     (Sender: TObject);
    procedure RemoveUnusedPointsExecute(Sender: TObject);
    procedure ExportGHSExecute         (Sender: TObject);
    procedure ShowFlowlinesExecute     (Sender: TObject);
    procedure AddCylinderExecute       (Sender: TObject);
    procedure SelectAllExecute         (Sender: TObject);
    procedure ExportSTLExecute         (Sender: TObject);
//  procedure CrossCurvesExecute       (Sender: TObject);
    procedure SelectLeakPointsExecute  (Sender: TObject);

    procedure LoadMostRecentFile;
//    procedure LoadNamedFile(FileName:string);
//    procedure dumpIcons;
//    procedure LoadToolIcons;
//    function  getToolbarControlsWidth(tb:TToolBar): integer;
//    function  getAllToolbarsControlWidth: integer;
//    procedure AlignAllToolbars;
//    procedure SetAllActionsEnabled(val : boolean);
    procedure InitiallyLoadModel;
   private                                             { Private declarations }
      FAllToolbarsControlsWidth,
      FToolBarFileControlsWidth,
      FToolBarVisibilityControlsWidth,
      FToolBarLayersControlsWidth,
      FToolBarPointsControlsWidth,
      FToolBarEditControlsWidth,
      FToolBarEdgesControlsWidth,
      FToolBarFacesControlsWidth,
      FToolBarCurvesControlsWidth : integer;
      FDestroying: boolean;
      FSplitSectionDialog: TFreeSplitSectionDialog;

      function  Load_and_Scale( FileName: String ): Boolean;
      procedure FLoadRecentFile(sender:TObject);
      procedure FreeLayerVisibilityDialogChange(Sender: TObject);
      procedure FreeShipChangeLayerData(Sender: TObject);
      procedure FreeShipChangeActiveLayer(Sender: TObject;Layer: TFreeSubdivisionLayer);
      procedure OnSplitSectionLocationChange(Sender: TObject; aValue: TFloatType);
      procedure OnSelectItem(Sender:TObject);
      procedure OnChangeActiveControlPoint(Sender:TObject);
      procedure OnChangeActiveControlEdge(Sender:TObject);
      procedure OnChangeActiveControlFace(Sender:TObject);
      procedure OnChangeActiveControlCurve(Sender:TObject);

      procedure HullformWindowOnActivate(Sender:TObject);
      procedure HullformWindowOnDeactivate(Sender:TObject);
      procedure HullformWindowOnClose(Sender:TObject; var CloseAction:TCloseAction);

      procedure CloseHullWindows;
      procedure FOpenHullWindows;  // Creates 4 different views on the hullform
   public     { Public declarations }
      FFileName : string;
      FModelInitallyLoaded : boolean;
///+++ {$IFDEF FPC}
      function  ActiveMDIChild: TFreeHullWindow; reintroduce;
      function  MDIChildCount: Integer; reintroduce;
      function  GetMDIChildren(AIndex: Integer): TFreeHullWindow; reintroduce;
      procedure AbandonMDIChildren(AIndex: Integer);
///+++ {$ENDIF}
      procedure Tile;
      procedure Cascade;
      procedure CustomExceptionHandler(Sender: TObject; E: Exception);
      constructor Create(AOwner: TComponent); override;
//+++  destructor Destroy; override;

      procedure SetCaption;
      procedure UpdateMenu;
      procedure RecentFilesDialogActivate(Sender: TObject);
      procedure ShowRecentFilesDialog;
  end;

var MainForm: TMainForm;

implementation

uses FreeLinesplanFrm,
     FreeKeelWizardDlg,
     FreeEmptyModelChooserDlg,
//   RibbonToolBarMgr,        <<== ArrangeRibbonPanel( PanelMain );
     TileDialog,
     FreePointGroupForm;

{$R *.lfm}

procedure TMainForm.CustomExceptionHandler( Sender:TObject; E:Exception ); begin
      WriteLn( 'Exception: '+E.Message );
////  Halt; // End of program execution
end;

constructor TMainForm.Create(AOwner: TComponent);
begin
  Application.OnException:=CustomExceptionHandler;
inherited Create(AOwner);
  PanelManager:=WinPanelManager.Create;
  FFileName:='';
//FreeShip.Preferences.SetDefaults;
end;
(*
destructor TMainForm.Destroy;
var i: Integer; thw:TFreeHullWindow;   ptr:pointer; al:TActionList;
begin
 FDestroying:=true;
 FreeShip.OnChangeActiveLayer:=nil;
 Freeship.OnChangeLayerData:=nil;
 //FreeShip.OnSelectItem:=nil;
 //FreeShip.OnChangeActiveControlPoint:=nil;
 FreeShip.Surface.RemoveOnChangeActiveControlPointListener(self.OnChangeActiveControlPoint);
 {al:=FActionListHull;
 ptr:=pointer(FActionListHull);
 if assigned(FActionListHull)
    then FreeAndNil(FActionListHull);}
 if assigned(PanelManager) then
 for i:=0 to PanelManager.PanelCount - 1 do
   if assigned(PanelManager.Panels[i]) then begin
      thw:=TFreeHullWindow(PanelManager.Panels[i]);
      //if assigned(thw.FreeHullForm) and assigned(thw.FreeHullForm.ActionListHull)
      //  then self.RemoveComponent(thw.FreeHullForm.ActionListHull);
      thw.Free;
      end;
 FreeAndNil(PanelManager);
 FreeAndNil(FreeShip);
 inherited;
end;
*)
procedure TMainForm.AbandonMDIChildren(AIndex: Integer);
begin PanelManager.Delete(AIndex); end;

function TMainForm.ActiveMDIChild: TFreeHullWindow;
begin Result:=PanelManager.FindActivePanel as TFreeHullWindow; end;

function TMainForm.MDIChildCount: Integer;
begin Result:=PanelManager.MList.Count; end;

function TMainForm.GetMDIChildren( AIndex: Integer ): TFreeHullWindow;
begin
   Result:=nil;
// if not (FormStyle in [fsMDIForm, fsMDIChild]) then  exit;
// if (AIndex<0) or (AIndex>=PanelManager.MList.Count) then exit;
   if AIndex<0 then AIndex:=0 else
   if AIndex>=PanelManager.MList.Count then AIndex:=PanelManager.MList.Count-1;
   Result:=TFreeHullWindow( PanelManager.Panels[AIndex] ) ;
end;

procedure TMainForm.FormChangeBounds(Sender: TObject); begin end;
procedure TMainForm.FormDestroy(Sender: TObject); begin end;
procedure TMainForm.FormResize( Sender: TObject );
begin
  // if MainForm.IsResizing then exit;
  // PanelMain.Invalidate;
  // Application.ProcessMessages;
  //// AlignAllToolbars;
end;
procedure TMainForm.FormWindowStateChange(Sender: TObject);
begin // this is just to kick toolbar to autoresize
{ Self.Height:=Self.Height+1;
  Self.Resize;
  Self.Height:=Self.Height-1;
  Self.Resize;
  Self.Invalidate;
}
end;

procedure TMainForm.InitiallyLoadModel;
var FileExt: string; Est: Boolean;
begin
  if FFileName='' then LoadMostRecentFile;                  // default if no recent file defined
  if (FFileName='') and not FreeShip.ModelIsLoaded then NewModelExecute(Self) else
  if (FFileName<>'') and not FreeShip.ModelIsLoaded and not FreeShip.IsLoadError
  then begin                                                // Skip translation
    FileExt:=Uppercase( ExtractFileExt( FFileName ) );
       Est:=(FileExt='.FBM') or (FileExt='.FTM');
    if Est then Est:=Load_and_Scale( FFileName );
    if not Est then begin
       FreeEmptyModelChooserDialog:=TFreeEmptyModelChooserDialog.Create(Self);
       ShowTranslatedValues(FreeEmptyModelChooserDialog);
       if FreeEmptyModelChooserDialog.Execute( FFileName ) then begin
         if FreeEmptyModelChooserDialog.RbCreateNew.Checked then NewModelExecute(Self) else
         if FreeEmptyModelChooserDialog.RbLoadFile.Checked then LoadFileExecute(Self)
       end; FreeEmptyModelChooserDialog.Free;
    end;                                                // End Skip translation
  end;
//SetCaption;
//LoadToolIcons;
//UpdateMenu;
end;

var inActivation: boolean = false;

procedure TMainForm.FormActivate(Sender: TObject);
var i:integer; splashResult:TModalResult;
begin
  if FDestroying then exit;
  if inActivation then exit;
  inActivation:=true;
  Freeship.Edit.ProgressBar:=nil; // temporary turn off until empty VP resolved in Win10
  Freeship.Surface.OnFaceRebuilt:=Freeship.Edit.OnFaceRebuilt;
  BringToFront;
  Application.BringToFront;
  Application.ProcessMessages;
  if not FModelInitallyLoaded then begin
       InitiallyLoadModel;
       FModelInitallyLoaded:=true;
  end;
//Freeship.Draw;
  inActivation:=false;
end;

procedure TMainForm.AddPointToGroupExecute(Sender: TObject);
var pgf:TFreePointGroupForm;
begin
  pgf:=TFreePointGroupForm.Create(Self);
  pgf.FreeShip:=FreeShip;
  pgf.LoadGroups;
  if pgf.ShowModal = mrOk then begin end;
end;

procedure TMainForm.cbPrecisionChange(Sender: TObject);
begin
  if cbPrecision.ItemIndex = ord(FreeShip.Precision) then exit;
  FreeShip.Precision:=TFreePrecisionType(cbPrecision.ItemIndex);
  FreeShip.RebuildModel;
  UpdateMenu;
end;

procedure TMainForm.AddFlowLineExecute(Sender: TObject);
    begin FreeShip.EditMode:=emAddFlowLine; UpdateMenu; end;

procedure TMainForm.AddGridPanelExecute(Sender: TObject);
    begin Freeship.Edit.Geometry_AddGridPanel; UpdateMenu; end;

procedure TMainForm.DesignHydrostaticsExecute(Sender: TObject);
var Calculation : TFreeHydrostaticCalc;
begin
   Calculation:=Freeship.Edit.Hydrostatics_Calculate(Freeship.ProjectSettings.ProjectDraft,0.0,0.0);
   if Calculation<>nil then begin FreeAndNil( Calculation ); end;
end;

procedure TMainForm.ActionCheckUpdatesExecute( Sender: TObject );
var Calculation : TFreeHydrostaticCalc;
begin
   Calculation:=Freeship.Edit.Hydrostatics_Calculate(Freeship.ProjectSettings.ProjectDraft,0.0,0.0);
   if Calculation<>nil then begin FreeAndNil( Calculation ); end;
// DesignHydrostaticsExecute( TObject )
end;

procedure TMainForm.ColorButton1Click( Sender:TObject );
    begin ActiveLayerColorExecute(self); end;

procedure TMainForm.OnSelectItem( Sender:TObject );
var Face1,Face2 : TFreeSubdivisionControlFace;
    Diff : Boolean;
    I : Integer;
begin
{ if (Sender is TFreeSubdivisionControlPoint)
     and (Sender=FreeShip.ActiveControlPoint)
     and (not FreeShip.ActiveControlPoint.Selected)
   then
     begin
        // The active controlpoint was deselected, probably internally by the subdivision surface.
        // Set the FreeShip.ActiveControlPoint to nil (which also closes the controlpoint window)
        FreeShip.ActiveControlPoint:=nil;
     end;
}
   if FreeShip.NumberOfSelectedControlFaces>0 then begin
      // set the layerbox itemindex to the index of the layer of the selected controlfaces
      Face1:=FreeShip.SelectedControlFace[0];
      // check if all selected controlfaces belong to the same layer
      Diff:=False;
      for I:=1 to FreeShip.NumberOfSelectedControlFaces do begin
         Face2:=FreeShip.SelectedControlFace[I-1];
         if Face1.Layer<>Face2.Layer then begin Diff:=True; Break; end;
      end;
      if not Diff then FreeShipChangeActiveLayer( self,Face1.Layer )
                  else FreeShipChangeActiveLayer( self,nil );
   end else FreeShipChangeActiveLayer(self,FreeShip.ActiveLayer);
   UpdateMenu;
end;

procedure TMainForm.OnChangeActiveControlPoint(Sender: TObject);
begin
   if (Sender = nil)
      and assigned(FreeShip)
      and assigned(FreeShip.ControlpointForm) then
     FreeShip.ControlpointForm.ActiveControlPoint:=nil;
   if (Sender is TFreeSubdivisionControlPoint) then
     FreeShip.ControlpointForm.ActiveControlPoint:=Sender as TFreeSubdivisionControlPoint;
   UpdateMenu;
end;

procedure TMainForm.OnChangeActiveControlEdge(Sender: TObject);
begin UpdateMenu; end;

procedure TMainForm.OnChangeActiveControlFace(Sender: TObject);
begin UpdateMenu; end;

procedure TMainForm.OnChangeActiveControlCurve(Sender: TObject);
begin UpdateMenu; end;

procedure TMainForm.HullformWindowOnActivate(Sender:TObject);
begin
  // bring Action List here to process keys and shortcuts
  // FActionListHull:=TFreeHullWindow(Sender).FreeHullForm.ActionListHull;
  // self.InsertComponent(FActionListHull);
end;

procedure TMainForm.HullformWindowOnDeactivate(Sender:TObject);
begin
  // remove Action List to free place for another MDI action list
  ///if not assigned(FActionListHull) then exit;
  ///if not assigned(Sender) then exit;
  ///if not assigned(TFreeHullWindow(Sender).FreeHullForm) then exit;
  ///if not assigned(TFreeHullWindow(Sender).FreeHullForm.ActionListHull) then exit;
  ///if FActionListHull <> TFreeHullWindow(Sender).FreeHullForm.ActionListHull
     ///then exit;
  ///if not FDestroying then
  ///   RemoveComponent(FActionListHull);
  ///FActionListHull:=nil;
end;

procedure TMainForm.HullformWindowOnClose(Sender:TObject; var CloseAction: TCloseAction);
begin
  HullformWindowOnDeactivate( Sender );
  PanelManager.Remove(Sender as TFreeHullWindow);
end;

procedure TMainForm.CloseHullWindows;
var thw: TFreeHullWindow;
begin
   if assigned(PanelManager) then while PanelManager.MList.Count>0 do
   begin
     thw:=TFreeHullWindow(PanelManager.Panels[0]);
            ///if assigned(thw) and assigned(thw.FreeHullForm)
            ///  and assigned(thw.FreeHullForm.ActionListHull)
            ///  then self.RemoveComponent(thw.FreeHullForm.ActionListHull);
      if assigned(thw) then thw.Close;
      PanelManager.Remove(thw);
   end;
end;
            // Creates 4 different views on the hullform and open a new window
procedure TMainForm.FOpenHullWindows;
  var I : Integer;                 //const WN:array[0..3] of Integer=(3,1,0,2);
begin
   if MDIChildCount=0 then
      for I:=0 to 3 do NewWindowSet( self,TFreeViewType( I ) ); // Tile;
// for I:=0 to 3 do
//   if GetMDIChildren( I )=nil then NewWindowSet( self,TFreeViewType( I ) );
   Tile;
// SetCaption;
end;

procedure TMainForm.SetCaption;
begin if FreeShip.FileChanged then Caption:='Free!Ship : '+FreeShip.Filename+' (modified)'
                              else Caption:='Free!Ship : '+FreeShip.Filename+' (not modified';
end;
(*
procedure TMainForm.SetAllActionsEnabled( val: boolean );
var i: integer; A: TAction;
begin
  for i:=0 to ActionList1.ActionCount-1 do begin
    A:=TAction( ActionList1.Actions[i] );
    A.Enabled:=val;
  end;
end;
*)
procedure TMainForm.UpdateMenu;
var I,NLayers : Integer;
//  FExecDirectory     : string;
//  FileToFind         : string;
// In this procedure all actions are set to enabled/disabled according to the current state
// and selected items
  const DS=DirectorySeparator;
begin
   NLayers:=0;
   For I:=1 to Freeship.NumberOfLayers do
     if Freeship.Layer[I-1].Count>0 then inc(NLayers);
   {
   // disable almost all actions if model was not loaded for some reason
   if not Freeship.ModelLoaded then begin
        FreeShip.Filename:='MODEL NOT LOADED!';
        FreeShip.FilenameSet:=false;
        SetAllActionsEnabled(false);
        NewModel.Enabled:=true;
        LoadFile.Enabled:=true;
        ExitProgram.Enabled:=true;
        HelpAction.Enabled:=true;
        AboutAction.Enabled:=true;
        //ImportFEF.Enabled:=true;
        //ImportCarene.Enabled:=true;
        //ImportVRML.Enabled:=true;
        //ImportHullFile.Enabled:=true;
     end;
    }
   // File menu
   FileSaveas.Enabled:=(FreeShip.Surface.NumberOfControlPoints>0)
                      or (Freeship.FileChanged) or (Freeship.FilenameSet);
   FileSave.Enabled:= FileSaveas.Enabled and Freeship.FileChanged
                      and not Freeship.FileIsReadOnly;

   ImportMichletWaves1.Enabled:=(MDIChildCount>0) and (Freeship.Surface.NumberOfControlFaces>1);
   ExportFEF.Enabled:=Freeship.Surface.NumberOfControlPoints>0;
   ExportObj.Enabled:=Freeship.Surface.NumberOfControlFaces>0;
   ExportSTL.Enabled:=Freeship.Surface.NumberOfControlFaces>0;
   ExportDXF3DPolylines.Enabled:=((FreeShip.NumberofStations>0) and (FreeShip.Visibility.ShowStations)) or
                                 ((Freeship.NumberofButtocks>0) and (Freeship.Visibility.ShowButtocks)) or
                                 ((Freeship.NumberofWaterlines>0) and (FreeShip.Visibility.ShowWaterlines)) or
                                 ((FreeShip.NumberofDiagonals>0) and (FreeShip.Visibility.ShowDiagonals)) or
                                 ((FreeShip.NumberofControlcurves>0) and (FreeShip.Visibility.ShowControlcurves));
   ExportDXF2DPolylines.Enabled:=((FreeShip.NumberofStations>0) and (FreeShip.Visibility.ShowStations)) or
                                 ((Freeship.NumberofButtocks>0) and (Freeship.Visibility.ShowButtocks)) or
                                 ((Freeship.NumberofWaterlines>0) and (FreeShip.Visibility.ShowWaterlines));
   ExportDXFFaces.Enabled:=Freeship.Surface.NumberOfControlFaces>0;
   ExportIGES.Enabled:=Freeship.Surface.NumberOfControlFaces>0;
   ExportOffsets.Enabled:=FreeShip.NumberofStations+Freeship.NumberofButtocks+Freeship.NumberofWaterlines+
                          Freeship.NumberofDiagonals+Freeship.NumberOfControlCurves>0;
   ExportArchimedes.Enabled:=FreeShip.NumberofStations>0;
   ExportGHS.Enabled:=FreeShip.NumberofStations>0;
// ExportPAM.Enabled:=FreeShip.NumberofStations>0;
// Detect existance of external modules
// FExecDirectory:=Freeship.Preferences.ExecDirectory;
   ExportMichlet.Enabled:=(Freeship.Surface.NumberOfControlFaces>0) and (Freeship.ProjectSettings.MainparticularsHasBeenset);

   RecentFiles.Enabled:=RecentFiles.Count>0;
   ExportCoordinates.Enabled:=Freeship.Surface.NumberOfControlPoints>0;
   ExportPart.Enabled:=(Freeship.Surface.NumberOfControlFaces>0);
   ImportPart.Enabled:=(Freeship.Surface.NumberOfControlFaces>0) and (MDIChildCount>0);
   // Show controledges and controlpoints
   ShowControlNet.Enabled:=FreeShip.Surface.NumberOfControlPoints>0;
   ShowControlNet.Checked:=FreeShip.Visibility.ShowControlNet;

   // Show free (not having faces) points and edges
   ShowFreeObjects.Enabled:=(FreeShip.Surface.NumberOfControlPoints>0);
   ShowFreeObjects.Checked:=FreeShip.Visibility.ShowFreeObjects;

   // Show interior edges
   ShowInteriorEdges.Enabled:=FreeShip.Surface.NumberOfControlFaces
                            + FreeShip.NumberofControlcurves>0;
   ShowInteriorEdges.Checked:=FreeShip.Visibility.ShowInteriorEdges;
   // Show both sides
   BothSides.Checked:=Freeship.Visibility.ModelView=mvBoth;
   BothSides.Enabled:=FreeShip.Surface.NumberOfControlFaces>0;
   // Delete
   Delete.Enabled:=Freeship.NumberOfSelectedControlPoints
                 + FreeShip.NumberOfSelectedControlEdges
                 + Freeship.NumberOfSelectedControlFaces
                 + Freeship.NumberOfSelectedControlCurves
                 + Freeship.NumberOfSelectedFlowLines
                 + Freeship.NumberOfselectedMarkers>0;
   // Window menu actions
   TileWindow.Enabled:=MDIChildCount>0;
   CascadeWindow.Enabled:=MDIChildCount>0;
   // Precision
   //PrecisionBox.ItemIndex:=Ord(FreeShip.Precision);
   SpinEditFontSize.Value:=FreeShip.Preferences.FontSize;
   // Layers
   LayerAutoGroup.Enabled:=(Freeship.Surface.NumberOfControlFaces>1) and (FreeShip.Visibility.ShowInteriorEdges);
   // Tools
   CheckModel.Enabled:=FreeShip.Surface.NumberOfControlFaces>0;
   DevelopLayers.Enabled:=False;
   for I:=1 to FreeShip.NumberOfLayers do
     if (FreeShip.Layer[I-1].Developable) and (FreeShip.Layer[I-1].Count>0)
     then begin
          DevelopLayers.Enabled:=True;
          break;
      end;
   KeelRudderWizard.Enabled:=MDIChildCount>0;
   DeleteMarkers.Enabled:=Freeship.NumberofMarkers>0;
   // Calculations
   DesignHydrostatics.Enabled:=Freeship.Surface.NumberOfControlFaces>0;
   Hydrostaticsdialog.Enabled:=Freeship.Surface.NumberOfControlFaces>0;
// CrossCurves.Enabled:=Freeship.Surface.NumberOfControlFaces>0;
   // edit commands
   AddPoint.Enabled:=(MDIChildCount>0) and (FreeShip.Visibility.ShowControlNet);
   Insertplane.Enabled:=(Freeship.Surface.NumberOfControlEdges>0) and (Freeship.Visibility.ShowControlNet);
   LayerIntersection.Enabled:=NLayers>1;
   EdgeCollapse.Enabled:=FreeShip.NumberOfSelectedControlEdges>0;
   NewEdge.Enabled:= (FreeShip.NumberOfSelectedControlPoints>1) and FreeShip.Surface.CanInsertEdge;
   EdgeCrease.Enabled:=FreeShip.NumberOfSelectedControlEdges>0;
   DeselectAll.Enabled:=(Freeship.NumberOfSelectedControlPoints+FreeShip.NumberOfSelectedControlEdges+Freeship.NumberOfSelectedControlFaces+Freeship.NumberOfSelectedControlCurves>0) or
                        (Freeship.ActiveControlPoint<>nil);
   NewCurve.Enabled:=FreeShip.NumberOfSelectedControlEdges>0;
   PointCollapse.Enabled:=Freeship.NumberOfSelectedControlPoints>0;
   DeleteEmptyLayers.Enabled:=False;
   for I:=1 to Freeship.NumberOfLayers do
     if (FreeShip.ModelIsLoaded)
     and (FreeShip.Layer[I-1].Count=0)
     and (FreeShip.NumberOfLayers>0) then begin
          DeleteEmptyLayers.Enabled:=True;
          break;
     end;
   RemoveUnusedPoints.Enabled:=False;
   for I:=1 to Freeship.Surface.NumberOfControlPoints do
     if Freeship.Surface.ControlPoint[I-1].NumberOfFaces=0 then begin
        RemoveUnusedPoints.Enabled:=True;
        break;
   end;
   InvertFace.Enabled:=Freeship.NumberOfSelectedControlFaces>0;
   ShowStations.Enabled:=Freeship.NumberofStations>0;
   ShowStations.Checked:=FreeShip.Visibility.ShowStations;
   ShowButtocks.Enabled:=Freeship.NumberofButtocks>0;
   ShowButtocks.Checked:=FreeShip.Visibility.ShowButtocks;
   ShowWaterlines.Enabled:=Freeship.NumberofWaterlines>0;
   ShowWaterlines.Checked:=FreeShip.Visibility.ShowWaterlines;
   ShowDiagonals.Enabled:=Freeship.NumberofDiagonals>0;
   ShowDiagonals.Checked:=FreeShip.Visibility.ShowDiagonals;
   ShowNormals.Checked:=FreeShip.Visibility.ShowNormals;
   ShowNormals.Enabled:=FreeShip.NumberOfSelectedControlFaces>0;
   ShowGrid.Checked:=Freeship.Visibility.ShowGrid;
   ShowGrid.Enabled:=Freeship.NumberofStations+Freeship.NumberofButtocks+Freeship.NumberofWaterlines+Freeship.NumberofDiagonals>0;
   ShowMarkers.Checked:=FreeShip.Visibility.ShowMarkers;
   ShowMarkers.Enabled:=Freeship.NumberofMarkers>0;
   ShowCurvature.Checked:=FreeShip.Visibility.ShowCurvature;
   ShowCurvature.Enabled:=Freeship.NumberofStations+Freeship.NumberofButtocks+Freeship.NumberofWaterlines+Freeship.NumberofDiagonals+Freeship.NumberOfControlCurves>0;
   ShowControlCurves.Checked:=FreeShip.Visibility.ShowControlCurves;
   ShowControlCurves.Enabled:=Freeship.Surface.NumberOfControlCurves>0;
   ShowHydrostatics.Checked:=Freeship.Visibility.ShowHydrostaticData;
   ShowHydrostatics.Enabled:=(Freeship.Surface.NumberOfControlFaces>2) and (Freeship.ProjectSettings.MainparticularsHasBeenset);
   ShowFlowlines.Checked:=Freeship.Visibility.ShowFlowlines;
   ShowFlowlines.Enabled:=Freeship.NumberOfFlowLines>0;

   NewFace.Enabled:=FreeShip.NumberOfSelectedControlPoints>2;
   IntersectionDialog.Enabled:=FreeShip.Surface.NumberOfControlFaces>0;
   EdgeExtrude.Enabled:=FreeShip.NumberOfSelectedControlEdges>0;
   EdgeSplit.Enabled:=FreeShip.NumberOfSelectedControlEdges>0;
   RotateModel.Enabled:=FreeShip.Surface.NumberOfControlPoints>0;
   RotateModelM.Enabled:=FreeShip.Surface.NumberOfControlPoints>0;
   ScaleModel.Enabled:=FreeShip.Surface.NumberOfControlPoints>0;
   MoveModel.Enabled:=FreeShip.Surface.NumberOfControlPoints>0;
   Mirrorface.Enabled:=Freeship.Surface.NumberOfControlFaces>0;
   if (Freeship.Undoposition-1>=0) and (Freeship.Undoposition-1<Freeship.UndoCount)
     then Undo.Caption:='Undo '+Freeship.UndoObject[Freeship.Undoposition-1].Undotext
     else Undo.Caption:='Undo';
   Undo.Enabled:=(FreeShip.UndoCount>0) and (Freeship.UndoPosition>0);
 //if Undo.Enabled then Undo.Caption:='Undo '+Freeship.UndoObject[Freeship.Undoposition-1].Undotext
 //                else Undo.Caption:='Undo';
   Redo.Enabled:=(FreeShip.UndoCount>0) and (Freeship.UndoPosition<Freeship.UndoCount);
 //if Redo.Enabled then Redo.Caption:='Redo '+Freeship.UndoObject[Freeship.Undoposition].Undotext
 //                else Undo.Caption:='Redo';
   Undohistory1.Enabled:=Freeship.UndoCount>0;
   ClearUndo.Enabled:=Freeship.UndoCount>0;
   PointsLock.Enabled:=(Freeship.NumberOfSelectedControlPoints>0) and (Freeship.NumberOfSelectedLockedPoints<Freeship.NumberOfSelectedControlPoints);
   PointsUnlock.Enabled:=Freeship.NumberOfSelectedLockedPoints>0;
   PointsUnlockAll.Enabled:=Freeship.NumberOfLockedPoints>0;
   PointAlign.Enabled:=Freeship.NumberOfSelectedControlPoints>2;
   PointAnchor.Enabled:=Freeship.NumberOfSelectedControlPoints>1;
   PointsCoincide.Enabled:=Freeship.NumberOfSelectedControlPoints>1;
   PointExtrude.Enabled:=Freeship.NumberOfSelectedControlPoints>0;
   TransformLackenby.Enabled:=Freeship.Surface.NumberOfControlFaces>0;
   if cbPrecision.ItemIndex <> ord(FreeShip.Precision) then
      cbPrecision.ItemIndex:=ord(FreeShip.Precision);
   FreeShip.ControlpointForm.Reload;
   FreeShip.ControlpointForm.FormStyle:=fsSystemStayOnTop;
   if FreeShip.ActiveControlPoint <> nil then
   // FreeShip.ControlpointForm.Visible:=true;
      FreeShip.ControlpointForm.Show;
end;

procedure TMainForm.RecentFilesDialogActivate( Sender: TObject );
var dlg: TTileDialog; i:integer; vFileName,sTime:string; jpg:TJPEGImage;
    pic:TPicture;
begin
  dlg:=Sender as TTileDialog;
  dlg.Cursor:=crHourGlass;
  Screen.Cursor:=crHourGlass;
  Application.ProcessMessages;
  for i:=0 to FreeShip.Edit.RecentFileCount-1 do begin
    vFileName:=Freeship.Edit.RecentFile[i];
    if not FileExists( vFileName ) then continue;
    sTime:=FormatDateTime('YYYY-MM-DD hh:mm:ss',FileDateToDateTime(FileAgeUTF8(vFileName)));
    Screen.Cursor:=crHourGlass;
    dlg.Cursor:=crHourGlass;
    Application.ProcessMessages;
//  Freeship.Edit.ProgressBar:=dlg.ProgressBar1;
    jpg:=Freeship.Edit.getPreviewImage( vFileName );
    if assigned( jpg ) then begin
       pic:=TPicture.Create;
       pic.Bitmap.Assign( jpg );
       dlg.AddTile( pic,sTime+' - '+vFileName, vFileName );
    end;
    Application.ProcessMessages;
  end;
  Screen.Cursor:=crDefault;
  dlg.Cursor:=crDefault;
end;

procedure TMainForm.ShowRecentFilesDialog;
var dlg: TTileDialog; i:integer; Answer: Word;
    vFileName,sTime:string;
    jpg:TJPEGImage;
    pic:TPicture;
begin
  dlg:=TTileDialog.create( Self );
  dlg.FileList:=Freeship.Edit.RecentFiles;
  dlg.onActivate:=RecentFilesDialogActivate;
//Freeship.Edit.ProgressBar:=dlg.ProgressBar1;
  Freeship.Surface.OnFaceRebuilt:=Freeship.Edit.OnFaceRebuilt;
  dlg.ShowModal;
  FreeShipUpdateRecentFileList(nil);   //update just in case if items deleted
  vFileName:=dlg.FileName;
  dlg.Free;
  Freeship.Surface.OnFaceRebuilt:=Freeship.Edit.OnFaceRebuilt;
  Freeship.Edit.ProgressBar:=self.ProgressBarMain;
  if (vFileName<>'') and (vFileName<>'*') then begin
    Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
    if (Answer=mrCancel) or FreeShip.FileChanged then exit;
    FreeShip.Edit.File_Load( vFileName );
  end;
  if (vFileName='*') then FreeShip.Edit.File_Load;     // здесь модель ещё цела
end;

procedure TMainForm.LoadFileExecute( Sender:TObject );
begin FOpenHullWindows;
      if self.RecentFiles.Count>0 then ShowRecentFilesDialog
                                  else FreeShip.Edit.File_Load;
end;

procedure TMainForm.ExitProgramExecute(Sender: TObject); begin
  UpdateMenu;
{ if FileExists('Resist.dat')   then DeleteFile('Resist.dat');
  if FileExists('RESISTp.dat')  then DeleteFile('RESISTp.dat');
  if FileExists('Vint1.dat')    then DeleteFile('Vint1.dat');
  if FileExists('SAC.tmp')      then DeleteFile('SAC.tmp');
  if FileExists('SACs.txt')     then DeleteFile('SACs.txt');
  if FileExists('Bonjean.txt')  then DeleteFile('Bonjean.txt');
  if FileExists('Weights.txt')  then DeleteFile('Weights.txt');
  if FileExists('Sterns.txt')   then DeleteFile('Sterns.txt');
} Close;
end;

procedure TMainForm.LayerBoxPanelClick(Sender: TObject); begin end;

procedure TMainForm.PointExtrudeExecute(Sender: TObject);
begin Freeship.Edit.Point_Extrude; UpdateMenu; end;

procedure TMainForm.PointsCoincideExecute(Sender: TObject);
begin   // get multiple selected points to the location of a first selected one
  Freeship.Edit.Point_CoinsideToPoint;
  UpdateMenu;
end;

procedure TMainForm.SelectionDialogExecute(Sender: TObject);
begin
  if FormSelected = nil then FormSelected:=TFormSelected.Create(Self);
     FormSelected.FreeShip:=FreeShip;
 //  FreeShip.Surface.AddOnSelectItemListener(FormSelected.onSelectionUpdate);
 //  FreeShip.Surface.AddOnChangeItemListener(FormSelected.onSelectionUpdate);
 //  FreeShip.Surface.AddOnChangeActiveControlPointListener(FormSelected.onSelectionUpdate);
 //  FreeShip.Surface.AddOnChangeActiveControlEdgeListener(FormSelected.onSelectionUpdate);
 //  FreeShip.Surface.AddOnChangeActiveControlFaceListener(FormSelected.onSelectionUpdate);
 //  FreeShip.Surface.AddOnChangeActiveControlCurveListener(FormSelected.onSelectionUpdate);
  FormSelected.onSelectionUpdate(Self);
  FormSelected.Show;
end;

procedure TMainForm.SplitSectionDialogExecute(Sender: TObject);
begin
  if FSplitSectionDialog = nil then
     FSplitSectionDialog:=TFreeSplitSectionDialog.Create(Self);
  FSplitSectionDialog.SetDimensions(FreeShip.Surface.Max.X,
                         FreeShip.Surface.Max.X/2, //TODO replace with real Widest
                         FreeShip.Surface.Max.X/2);
  if FreeShip.ProjectSettings.ProjectSplitSectionLocation > 0
    then FSplitSectionDialog.SplitSectionLocation:=FreeShip.ProjectSettings.ProjectSplitSectionLocation
    else FSplitSectionDialog.SplitSectionLocation:=FreeShip.Surface.Max.X/2;
  FSplitSectionDialog.OnSplitSectionLocationChange:=OnSplitSectionLocationChange;
  FreeShip.ProjectSettings.UseDefaultSplitSectionLocation:=false;
  FSplitSectionDialog.Show;
  FreeShip.ProjectSettings.ProjectSplitSectionLocation:=FSplitSectionDialog.SplitSectionLocation;
  //FSplitSectionDialog.Free;
  //FreeShip.FileChanged:=True;
  //FreeShip.Redraw;
  //UpdateMenu;
end;

procedure TMainForm.OnSplitSectionLocationChange(Sender: TObject; aValue: TFloatType);
begin
  FreeShip.ProjectSettings.ProjectSplitSectionLocation:=aValue;
  FreeShip.FileChanged:=True;
  FreeShip.Redraw;
end;

procedure TMainForm.ShowFreeObjectsExecute(Sender: TObject);
begin
  FreeShip.Visibility.ShowFreeObjects:=not FreeShip.Visibility.ShowFreeObjects;
  UpdateMenu;
end;

procedure TMainForm.LayerVisibilityDialogExecute(Sender: TObject);
begin
  if FreeLayerVisibilityDialog = nil then
     FreeLayerVisibilityDialog:=TFreeLayerVisibilityDialog.Create(Self);
  FreeLayerVisibilityDialog.FreeShip:=FreeShip;
  FreeLayerVisibilityDialog.OnChange:=FreeLayerVisibilityDialogChange;
  FreeLayerVisibilityDialog.Show;
end;

procedure TMainForm.FreeLayerVisibilityDialogChange( Sender:TObject );
begin UpdateMenu; end;

procedure TMainForm.FormShow( Sender: TObject );
var FileExt: string; L,T,W,H: Integer;
begin    // Initialize some data
   FreeShip.OnChangeActiveLayer:=FreeShipChangeActiveLayer;
   Freeship.OnChangeLayerData:=FreeShipChangeLayerData;
//   FreeShip.OnSelectItem:=OnSelectItem;
//   FreeShip.Surface.AddOnSelectItemListener(OnSelectItem);
//   FreeShip.Surface.AddOnChangeActiveControlPointListener(OnChangeActiveControlPoint);
//   FreeShip.Surface.AddOnChangeActiveControlEdgeListener(OnChangeActiveControlEdge);
//   FreeShip.Surface.AddOnChangeActiveControlFaceListener(OnChangeActiveControlFace);
//   FreeShip.Surface.AddOnChangeActiveControlCurveListener(OnChangeActiveControlCurve);
   FreeShip.Clear;
   // fit to screen
   L:=Left; T:=Top; W:=Width; H:=Height;
   if self.BoundsRect.Right > Screen.Width then L:=0;
   if self.Width > Screen.Width then W:=Screen.Width;
   if self.BoundsRect.Bottom > Screen.Height then T:=0;
   if self.Height > Screen.Height then H:=Screen.Height;
   Self.SetBounds( L,T,W,H );

   SetCaption;
// LoadToolIcons;
   UpdateMenu;
// ArrangeRibbonPanel(PanelMain);
end;

procedure TMainForm.MainClientPanelClick(Sender: TObject); begin end;
procedure TMainForm.MenuItem1Click(Sender: TObject); begin end;

procedure TMainForm.PanelMainResize(Sender: TObject);
 // var I: Integer=0;
 // TP: Tpanel;
 // TB: TToolBar;
begin
 // TP:=TPanel( TObject );
 // for I:=0 to TP.ControlCount-1 do
 // if TP.Controls[I] is TToolBar then
 //   begin
 //     TB:=TToolBar( TP.Controls[I] );
 //     TB.ButtonHeight:=24;
 //     TB.Height:=24;
 //   end;
 //
  PanelMain.Height:=24;
  PanelMain.ClientHeight:=24;
   // if PanelMain.IsResizing then exit;
   // ArrangeRibbonPanel(PanelMain);
end;

procedure TMainForm.ShowControlNetExecute(Sender: TObject);
begin
   FreeShip.Visibility.ShowControlNet:=not FreeShip.Visibility.ShowControlNet;
   UpdateMenu;
end;

procedure TMainForm.ShowInteriorEdgesExecute(Sender: TObject);
begin
   FreeShip.Visibility.ShowInteriorEdges:=not FreeShip.Visibility.ShowInteriorEdges;
   UpdateMenu;
end;

procedure TMainForm.NewWindowSet( Sender: TObject; ViewType: TFreeViewType );
var HullformWindow : TFreeHullWindow; I : Integer;
begin // open a new window
  I:=MainClientPanel.ControlCount;
  HullformWindow:=TFreeHullWindow.Create( Self );
  HullformWindow.CaptionButtons:=[cbSystemMenu,cbMaximize,cbMinimize,cbRestore];
  HullformWindow.Name:='HullformWindow'+IntToStr( I );
  HullformWindow.Viewport.Name :='Viewport'+IntToStr( I );
  HullformWindow.FreeShip:=FreeShip;
  PanelManager.Add( HullformWindow );
  HullformWindow.Parent:=MainClientPanel;
  HullformWindow.OnActivate:=HullformWindowOnActivate;
  HullformWindow.OnDeactivate:=HullformWindowOnDeactivate;
  HullformWindow.OnClose:=HullformWindowOnClose;
  HullformWindow.OnDestroy:=HullformWindowOnDeactivate;
  HullformWindow.Viewport.ViewType:=ViewType;
  if ViewType=fvPerspective then HullformWindow.Viewport.ViewportMode:=vmShade;
  HullformWindow.SetCaption;
  UpdateMenu;
end;

procedure TMainForm.NewWindowExecute(Sender: TObject);
begin NewWindowSet( self,fvPerspective ); end;

procedure TMainForm.SpinEditFontSizeChange( Sender: TObject );
var w: integer;  vp:TFreeViewport;
begin
  FreeShip.Preferences.FontSize:=SpinEditFontSize.value;
//if SpinEditFontSize.value < 10
//  then SpinEditFontSize.Constraints.MinWidth:=16+24+2
//  else SpinEditFontSize.Constraints.MinWidth:=16+16+24+2;
  SpinEditFontSize.Width:=SpinEditFontSize.Constraints.MinWidth;

  for w:=0 to PanelManager.MList.Count-1 do begin
    vp:=TFreeHullWindow(PanelManager.Panels[w]).Viewport;
    vp.invalidate;
  end;
end;

procedure TMainForm.Tile; begin PanelManager.Show( false ); end;
procedure TMainForm.Cascade; begin PanelManager.Show( true ); end;

procedure TMainForm.TileWindowExecute(Sender: TObject);
begin
  {$ifndef LCL}{$ifndef CLX}
  TileMode:=tbHorizontal;
  {$endif}{$endif}
  PanelManager.Show( false );
end;

procedure TMainForm.CascadeWindowExecute(Sender: TObject);
begin
  {$ifndef LCL}{$ifndef CLX}
  TileMode:=tbHorizontal;
  {$endif}{$endif}
  PanelManager.Show( true );
end;


procedure TMainForm.FreeShipFileChanged(Sender: TObject);
    begin SetCaption; end;
procedure TMainForm.NewLayerExecute(Sender: TObject);
    begin FreeShip.Edit.Layer_New; UpdateMenu; end;
procedure TMainForm.DeleteExecute(Sender: TObject);
    begin Freeship.Edit.Selection_Delete; UpdateMenu; end;
procedure TMainForm.EdgeCollapseExecute(Sender: TObject);
    begin FreeShip.Edit.Edge_Collapse; UpdateMenu; end;
procedure TMainForm.NewEdgeExecute(Sender: TObject);
    begin FreeShip.Edit.Edge_Connect; UpdateMenu; end;
procedure TMainForm.EdgeCreaseExecute(Sender: TObject);
    begin FreeShip.Edit.Edge_Crease; UpdateMenu; end;
procedure TMainForm.DeselectAllExecute(Sender: TObject);
    begin FreeShip.Edit.Selection_Clear; UpdateMenu; end;
procedure TMainForm.PointCollapseExecute(Sender: TObject);
    begin Freeship.Edit.Point_Collapse; UpdateMenu; end;
procedure TMainForm.BothSidesExecute(Sender: TObject);
    begin if FreeShip.Visibility.ModelView=mvBoth
            then FreeShip.Visibility.ModelView:=mvPort
            else FreeShip.Visibility.ModelView:=mvBoth; UpdateMenu; end;

{ //moved to TFREEProjectSettingsDialog
procedure TMainForm.PrecisionBoxChange(Sender: TObject);
begin FreeShip.Precision:=TFreePrecisionType(PrecisionBox.ItemIndex); UpdateMenu;
end;
}

procedure TMainForm.FileSaveasExecute(Sender: TObject);
    begin FreeShip.Edit.File_SaveAs; UpdateMenu; SetCaption; end;
procedure TMainForm.LayerAutoGroupExecute(Sender: TObject);
    begin FreeShip.Edit.Layer_AutoGroup; UpdateMenu; end;

function TMainForm.Load_and_Scale( FileName: String ): Boolean;
begin Result:=false;
  if FileExists( Filename ) then begin
     FOpenHullWindows;
     Application.ProcessMessages;
     Freeship.Edit.ProgressBar:=ProgressBarMain;
     Freeship.Surface.OnFaceRebuilt:=Freeship.Edit.OnFaceRebuilt;
     Freeship.Edit.File_Load( Filename );
//     Freeship.RebuildModel;
//     Freeship.ZoomFitAllViewports;
//     SetCaption;
//     UpdateMenu;
     Freeship.Edit.ProgressBar:=nil;
     Result:=true;
  end;
end;

resourcestring
 rsExitConfirmation = 'The current model has been changed!'+EOL+'Are you sure you want to exit?';

procedure TMainForm.FLoadRecentFile(sender:TObject);
var Menu    : TMenuItem;
    Filename: string;
    N       : Integer;
    Answer  : word;
begin
   if sender is TMenuItem then begin
      Menu:=sender as TMenuItem;      // Skip translation
      Filename:=Menu.Caption;
      repeat
         N:=Pos('&',Filename);
         if N<>0 then system.Delete( Filename,N,1 );
      until N=0;

   Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
   if (Answer=mrCancel) or FreeShip.FileChanged then exit;
   if not Load_and_Scale( FileName ) then begin
     FreeEmptyModelChooserDialog:=TFreeEmptyModelChooserDialog.Create(Self);
     if FreeEmptyModelChooserDialog.Execute(FileName) then begin
       if FreeEmptyModelChooserDialog.RbCreateNew.Checked then NewModelExecute(Self) else
       if FreeEmptyModelChooserDialog.RbLoadFile.Checked then LoadFileExecute(Self) end;
       FreeEmptyModelChooserDialog.Free;
     end
   end;
end;

procedure TMainForm.LoadMostRecentFile;
var Menu    : TMenuItem;
    Filename: string;
    N       : Integer;
    Answer  : word;
begin
  if FreeShip.Edit.RecentFileCount = 0 then exit;
  Filename:=Freeship.Edit.RecentFile[0];
  FFilename:=Filename;
  Load_and_Scale( FileName );
end;
{
procedure TMainForm.LoadNamedFile( FileName:string );
var Menu    : TMenuItem;
    N       : Integer;
    Answer  : word;
begin
  if not Load_and_Scale( FileName ) then begin
    FreeEmptyModelChooserDialog:=TFreeEmptyModelChooserDialog.Create(Self);
    if FreeEmptyModelChooserDialog.Execute(FileName) then begin
      if FreeEmptyModelChooserDialog.RbCreateNew.Checked then NewModelExecute(Self) else
      if FreeEmptyModelChooserDialog.RbLoadFile.Checked then LoadFileExecute(Self)
    end;
    FreeEmptyModelChooserDialog.Free;
  end;
end;
}
procedure TMainForm.FreeShipChangeLayerData( Sender: TObject );
var I : Integer;
begin // Fill the layerbox with the current layers
   LayerBox.Items.BeginUpdate;
   LayerBox.Items.Clear;
// try
      for I:=0 to Freeship.NumberOfLayers-1 do
      begin Layerbox.Items.AddObject(FreeShip.Layer[I].Name,FreeShip.Layer[I]);
      end;
// finally
      LayerBox.Items.EndUpdate;
      I:=LayerBox.Items.IndexOfObject(FreeShip.ActiveLayer);
      Layerbox.ItemIndex:=I;
// end;
   if FreeLayerVisibilityDialog <> nil then FreeLayerVisibilityDialog.FillLayers;
end;

procedure TMainForm.FreeShipChangeActiveLayer(Sender: TObject;Layer: TFreeSubdivisionLayer);
var Index : Integer;
begin
   if (FreeShip.NumberOfSelectedControlFaces<>0) and (FreeShip.ActiveLayer=Layer)
   then begin end // do not switch to the active layer when controlfaces are selected
   else begin
     if Layer=nil then begin
        Index:=-1;
        Layerbox.ItemIndex:=Index;
        //PanelActiveLayerColor.Color:=clBtnface;
        ColorButton1.ButtonColor:=clBtnface;
     end else begin
        Index:=Layerbox.Items.IndexOfObject(Layer);
        Layerbox.ItemIndex:=Index;
        //PanelActiveLayerColor.Color:=Layer.Color;
        ColorButton1.ButtonColor:=Layer.Color;
     end;
   end;
end;

procedure TMainForm.MainFormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Action = caFree then begin
     FreeShip.Preferences.Save;
     FDestroying:=true;
     CloseHullWindows;
  //  FreeShip.OnChangeActiveLayer:=nil;
  //  Freeship.OnChangeLayerData:=nil;
  ////FreeShip.OnSelectItem:=nil;
  //  FreeShip.Surface.RemoveOnSelectItemListener( OnSelectItem );
  end;
end;

procedure TMainForm.ImportFEFExecute(Sender: TObject);
    begin FreeShip.Edit.File_ImportFEF;
          FOpenHullWindows;
          SetCaption;
          UpdateMenu;
    end;

procedure TMainForm.LayerBoxChange(Sender: TObject);
var Layer: TFreeSubdivisionLayer; I,Index: Integer;
begin
   Index:=Layerbox.ItemIndex;
   if index=-1 then Index:=0;
   Layer:=Layerbox.Items.Objects[index] as TFreeSubdivisionLayer;
   if Freeship.NumberOfSelectedControlFaces=0 then begin // change active layer
      if Layer<>FreeShip.ActiveLayer then FreeShip.ActiveLayer:=Layer;
   end else begin          // Assign all selected controlfaces to the new layer
      for I:=FreeShip.NumberOfSelectedControlFaces downto 1
       do FreeShip.SelectedControlFace[I-1].Layer:=Layer;
      FreeShip.FileChanged:=True;
      FreeShip.Redraw;
   end;
   UpdateMenu;
end;

procedure TMainForm.PanelActiveLayerColorClick(Sender: TObject);
begin ActiveLayerColorExecute(self); end;

procedure TMainForm.ActiveLayerColorExecute(Sender: TObject);
begin                         // change the color of the currently active layer
   ColorDialog.Color:=FreeShip.ActiveLayer.Color;
   if ColorDialog.Execute then begin
      FreeShip.ActiveLayer.Color:=ColorDialog.Color;
      FreeShip.FileChanged:=True;
      FreeShip.Redraw;
      FreeShipChangeActiveLayer(self,Freeship.ActiveLayer);
      UpdateMenu;
   end;
end;

procedure TMainForm.DeleteEmptyLayersExecute(Sender: TObject);
begin Freeship.Edit.Layer_DeleteEmpty(False); UpdateMenu; end;

procedure TMainForm.LayerDialogExecute(Sender: TObject);
begin FreeShip.Edit.Layer_Dialog; UpdateMenu; end;

procedure TMainForm.NewModelExecute(Sender: TObject);
begin
   if FreeShip.Edit.Model_New then FOpenHullWindows;
   FreeShip.FileIsReadOnly:=false;
   FreeShip.FileChanged:=true;
// FreeShip.ModelIsLoaded:=true;
// Freeship.RebuildModel;
// Freeship.ZoomFitAllViewports;
// FreeShip.Surface.Rebuild;
// Freeship.RebuildModel;
// FreeShip.Draw;
// FreeShip.ReDraw;
// SetCaption;
   UpdateMenu;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
{$ifndef Windows}
   if self.Align = alTop then self.Top:=0;
{$endif}                                        // Removed from LFM, moved here
   FreeShip            :=TFreeShip.Create( self );
   FreeShip.MainForm   :=self;
   FreeShip.FileChanged:=true;
   FreeShip.Filename   :='New model.fbm';
   FreeShip.FileVersion:=fv261;
   FreeShip.OnChangeCursorIncrement:=FreeShipChangeCursorIncrement;
   FreeShip.OnFileChanged          :=FreeShipFileChanged;
   FreeShip.OnUpdateGeometryInfo   :=FreeShipUpdateGeometryInfo;
   FreeShip.OnUpdateRecentFileList :=FreeShipUpdateRecentFileList;
   FreeShip.OnUpdateUndoData       :=FreeShipUpdateUndoData;
   FreeShip.Precision:=fpLow;
   FAllToolbarsControlsWidth:=0;
   GlobalFreeship      :=Freeship;     // копия для воссоздания новых моделей
   FModelInitallyLoaded:=false;
end;

procedure TMainForm.ShowStationsExecute(Sender: TObject);
begin FreeShip.Visibility.ShowStations:=not FreeShip.Visibility.ShowStations;
      UpdateMenu;
end;
procedure TMainForm.ShowButtocksExecute(Sender: TObject);
begin FreeShip.Visibility.ShowButtocks:=not FreeShip.Visibility.ShowButtocks;
      UpdateMenu;
end;
procedure TMainForm.ShowWaterlinesExecute(Sender: TObject);
begin FreeShip.Visibility.ShowWaterlines:=not FreeShip.Visibility.ShowWaterlines;
      UpdateMenu;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var Answer:word;
begin
  if Freeship.FileChanged then  begin
    Answer:=MessageDlg( rsExitConfirmation,mtWarning,[mbNo,mbYes],0,mbNo );
    CanClose:=Answer=mrYes;
  end;
end;

procedure TMainForm.NewFaceExecute(Sender: TObject);
    begin FreeShip.Edit.Face_New; UpdateMenu; end;

procedure TMainForm.IntersectionDialogExecute(Sender: TObject);
    begin FreeShip.Edit.Intersection_Dialog; UpdateMenu; end;

procedure TMainForm.EdgeExtrudeExecute(Sender: TObject);
    begin FreeShip.Edit.Edge_Extrude; UpdateMenu; end;

procedure TMainForm.About1Click( Sender: TObject );
var FreeAboutDlg: TFreeAboutDlg;
begin
    FreeAboutDlg:=TFreeAboutDlg.Create(Self);
    FreeAboutDlg.ShowModal;
    FreeAndNil(FreeAboutDlg);
end;

// begin correction Victor T
procedure TMainForm.Help1Click(Sender: TObject);
var FileToFind,FManDirectory,FLang,man : string;
begin
  FLang:=Freeship.Preferences.Language;
  FManDirectory:=Freeship.Preferences.ManualsDirectory;
  man:=FLang+'.pdf';
  FileToFind:=FileSearch(FManDirectory+DirectorySeparator+man,FManDirectory);
  if (FileToFind='') and (FLang<>'English') then begin
    MessageDlg('Manual file "'+man+'" not found in "'+FManDirectory+'" directory'+EOL
              +'English manual will be opened.',mtInformation,[mbOk],0);
    man:='English.pdf'
  end;
  FileToFind:=FileSearch(FManDirectory+DirectorySeparator+man,FManDirectory);
  if FileToFind='' then begin
     MessageDlg('Manual file "'+man+'" not found in "'+FManDirectory+'" directory',mtInformation,[mbOk],0);
     exit;
  end;
  OpenDocument( FileToFind );
end;

procedure TMainForm.EdgeSplitExecute(Sender: TObject);
begin FreeShip.Edit.Edge_Split; UpdateMenu; end;

procedure TMainForm.ExportFEFExecute(Sender: TObject);
begin FreeShip.Edit.File_ExportFEF; UpdateMenu; end;

procedure TMainForm.EditProjectSettingsExecute(Sender: TObject);
begin FreeShip.ProjectSettings.Edit; UpdateMenu; end;

procedure TMainForm.CheckModelExecute(Sender: TObject);
begin FreeShip.Edit.Model_Check(True); UpdateMenu; end;

procedure TMainForm.ShowNormalsExecute(Sender: TObject);
begin
   FreeShip.Visibility.ShowNormals:=not FreeShip.Visibility.ShowNormals;
   UpdateMenu;
end;

procedure TMainForm.ImportVRMLExecute(Sender: TObject);
//var DateTime : TDateTime;
//    str_1,str_2 : string;
begin
   //   DateTime:=Time;  // store the current date and time
   //   str_1:=TimeToStr(DateTime); // convert the time into a string
   FreeShip.Edit.File_ImportVRML;
   FOpenHullWindows;
   Application.ProcessMessages;
   FreeShip.ZoomFitAllViewports;
   //   DateTime:=Time;  // store the current date and time
   //   str_2:=TimeToStr(DateTime); // convert the time into a string
   //   MessageDlg(('Time import='+str_2+' - '+str_1),mtInformation,[mbOK],0);
   UpdateMenu;
end;

procedure TMainForm.RemoveNegativeExecute(Sender: TObject);
begin Freeship.Edit.Face_DeleteNegative; UpdateMenu; end;

procedure TMainForm.RotateModelExecute(Sender: TObject);
begin FreeShip.Edit.Face_Rotate; UpdateMenu; end;

procedure TMainForm.RotateModelMExecute(Sender: TObject);
begin FreeShip.Edit.Face_RotateM; UpdateMenu; end;

procedure TMainForm.ScaleModelExecute(Sender: TObject);
begin FreeShip.Edit.Face_Scale; UpdateMenu; end;

procedure TMainForm.ShowGridExecute(Sender: TObject);
begin
   Freeship.Visibility.ShowGrid:=not Freeship.Visibility.ShowGrid;
   UpdateMenu;
end;

procedure TMainForm.ToolButtonSelectClick(Sender: TObject); begin end;

procedure TMainForm.UndoExecute(Sender: TObject);
begin FreeShip.Edit.Undo; UpdateMenu; SetCaption; end;

   // Update undo memory usage
procedure TMainForm.FreeShipUpdateUndoData(Sender: TObject);
var Memory : Integer;
begin
   Memory:=Trunc(Freeship.UndoMemory/1024);
   if Memory<1024 then LabelUndoMemory.Caption:='Undo memory : '+IntToStr(Memory)+' Kb.'
                  else LabelUndoMemory.Caption:='Undo memory : '+FloatToDec(Memory/1024,3)+' Mb.';
   Undo.Enabled:=FreeShip.UndoCount>0;
   SetCaption;
   UpdateMenu;
end;

procedure TMainForm.HydrostaticsDialogExecute(Sender: TObject);
begin Freeship.Edit.Hydrostatics_Dialog; UpdateMenu; end;

procedure TMainForm.ExportObjExecute(Sender: TObject);
begin FreeShip.Edit.File_ExportObj; UpdateMenu; end;

procedure TMainForm.InvertFaceExecute(Sender: TObject);
begin Freeship.Edit.Face_Flip; UpdateMenu; end;

procedure TMainForm.PreferencesExecute(Sender: TObject);
begin FreeShip.Preferences.Edit; UpdateMenu; { LoadToolIcons;}  end;

procedure TMainForm.ImportBodyplanExecute(Sender: TObject);
begin
   FreeShip.Edit.ImportFrames;
   FOpenHullWindows;
   SetCaption;
   UpdateMenu;
end;

procedure TMainForm.ExportAuroraHullVslExecute(Sender: TObject);
begin Freeship.Edit.File_Export_Aurora_Experiments; UpdateMenu; end;

procedure TMainForm.ExportDXF3DPolylinesExecute(Sender: TObject);
begin Freeship.Edit.File_ExportDXF_3DPolylines; UpdateMenu; end;

procedure TMainForm.ExportDXFFacesExecute(Sender: TObject);
begin Freeship.Edit.File_ExportDXF_Faces; UpdateMenu; end;

procedure TMainForm.ImportHullFileExecute(Sender: TObject);
begin Freeship.Edit.File_ImportHull;
      FOpenHullWindows;
      UpdateMenu;
end;

procedure TMainForm.ExportOffsetsExecute(Sender: TObject);
begin Freeship.Edit.File_ExportOffsets; UpdateMenu; end;

procedure TMainForm.MoveModelExecute(Sender: TObject);
begin FreeShip.Edit.Face_Move; UpdateMenu; end;

procedure TMainForm.AddPointExecute(Sender: TObject);
begin Freeship.EditMode:=emAddPoint;
    //Freeship.Edit.Point_New;
   UpdateMenu;
end;

procedure TMainForm.DevelopLayersExecute(Sender: TObject);
begin
   Screen.Cursor:=crHourglass;
   Application.ProcessMessages;
   FreeShip.Edit.Layer_Develop;
   Screen.Cursor:=crDefault;
   UpdateMenu;
end;

procedure TMainForm.ExportArchimedesExecute(Sender: TObject);
begin FreeShip.Edit.File_ExportArchimedes; UpdateMenu; end;

procedure TMainForm.ShowLinesplanExecute(Sender: TObject);
var I          : Integer;
    AlreadyOpen: Boolean;
    Form       : TFreeLinesplanForm;
begin
   if not Freeship.ProjectSettings.MainParticularsHasBeenset
   then begin MessageDlg( 'First to set the dimensions! ',mtWarning,[mbOk],0); exit; end;
   AlreadyOpen:=False;
   for I:=1 to MDIChildCount
   do if MDIChildren[I-1] is TFreeLinesplanForm then begin
      AlreadyOpen:=True;
      MDIChildren[I-1].BringToFront; break;
   end;
   if not AlreadyOpen then begin
      Form:=TFreeLinesplanForm.Create(self);
      Form.LinesplanFrame.FreeShip:=FreeShip;
      Form.LinesplanFrame.Viewport.ZoomExtents;
   end;
end;

procedure TMainForm.ShowDiagonalsExecute(Sender: TObject);
begin
   FreeShip.Visibility.ShowDiagonals:=not FreeShip.Visibility.ShowDiagonals;
   UpdateMenu;
end;

procedure TMainForm.FreeShipUpdateRecentFileList(Sender: TObject);
var I    : Integer;
    Item : TMenuItem;
begin                                                  // delete old menu items
   RecentFiles.Clear;                                  // add the new data
   for I:=1 to FreeShip.Edit.RecentFileCount do begin
      Item:=TMenuItem.Create(self);
      Item.Caption:=Freeship.Edit.RecentFile[I-1];
      Item.OnClick:=FLoadRecentFile;
      RecentFiles.Add(Item);
   end;
   UpdateMenu;
end;

procedure TMainForm.ImportCareneExecute(Sender: TObject);
    begin Freeship.Edit.File_ImportCarene; FOpenHullWindows; UpdateMenu; end;

procedure TMainForm.ShowMarkersExecute(Sender: TObject);
begin
   FreeShip.Visibility.ShowMarkers:=not FreeShip.Visibility.ShowMarkers;
   UpdateMenu;
end;

procedure TMainForm.DeleteMarkersExecute(Sender: TObject);
    begin Freeship.Edit.Marker_Delete; UpdateMenu; end;

procedure TMainForm.ImportSurfaceExecute(Sender: TObject);
begin
   FreeShip.Edit.File_ImportSurface;
   FOpenHullWindows;
   SetCaption;
   UpdateMenu;
end;

procedure TMainForm.ShowcurvatureExecute(Sender: TObject);
begin
   FreeShip.Visibility.ShowCurvature:=not FreeShip.Visibility.ShowCurvature;
   UpdateMenu;
end;

procedure TMainForm.IncreaseCurvatureScaleExecute(Sender: TObject);
begin Freeship.Visibility.IncreaseCurvatureScale; end;

procedure TMainForm.DecreaseCurvatureScaleExecute(Sender: TObject);
begin Freeship.Visibility.DecreaseCurvatureScale; end;

procedure TMainForm.FileSaveExecute(Sender: TObject);
begin if Freeship.FilenameSet and not Freeship.FileIsReadOnly
      then FreeShip.Edit.File_Save
      else FreeShip.Edit.File_SaveAs; UpdateMenu;
end;

procedure TMainForm.ImportChinesExecute(Sender: TObject);
begin
   FreeShip.Edit.File_ImportChines;
   FOpenHullWindows;
   SetCaption;
   UpdateMenu;
end;

procedure TMainForm.ShowControlCurvesExecute(Sender: TObject);
begin
   FreeShip.Visibility.ShowControlCurves:=not FreeShip.Visibility.ShowControlCurves;
   UpdateMenu;
end;

procedure TMainForm.NewCurveExecute(Sender: TObject);
begin Freeship.Edit.Curve_Add; UpdateMenu; end;

procedure TMainForm.ExportCoordinatesExecute(Sender: TObject);
    begin Freeship.Edit.File_ExportCoordinates; UpdateMenu; end;
procedure TMainForm.InsertPlaneExecute(Sender: TObject);
    begin Freeship.Edit.Point_InsertPlane; UpdateMenu; end;
procedure TMainForm.PointsLockExecute(Sender: TObject);
    begin Freeship.Edit.Point_Lock; UpdateMenu; end;
procedure TMainForm.PointsUnlockExecute(Sender: TObject);
    begin Freeship.Edit.Point_Unlock; UpdateMenu; end;
procedure TMainForm.PointsUnlockAllExecute(Sender: TObject);
    begin Freeship.Edit.Point_UnlockAll; UpdateMenu; end;
procedure TMainForm.ImportMarkersExecute(Sender: TObject);
    begin Freeship.Edit.Marker_Import; UpdateMenu; end;
procedure TMainForm.ExportMichletExecute(Sender: TObject);
    begin Freeship.Edit.File_Export_Michlet; UpdateMenu; end;

procedure TMainForm.FreeShipChangeCursorIncrement(Sender: TObject);
begin
  if (csdestroying in componentstate) then exit;
  LabelDistance.Caption:='Increase distance: '+FloatToDec(Freeship.Visibility.CursorIncrement,7);
end;

procedure TMainForm.StatusPanel3Click(Sender: TObject);
var Str  : Ansistring;
    I    : integer;
    Value: TFloatType;
begin
   if Freeship.Surface.NumberOfControlPoints=0 then exit;
   Str:=FloatToDec(Freeship.Visibility.CursorIncrement,5);
   if InputQuery('','New increment distance : ',Str) then begin
      Val(Str,Value,I);
      if I=0 then Freeship.Visibility.CursorIncrement:=Value;
   end;
end;

procedure TMainForm.PointAlignExecute(Sender: TObject);
begin Freeship.Edit.Point_ProjectStraightLine; UpdateMenu; end;

procedure TMainForm.PointAlighnPermanentlyExecute(Sender: TObject);
begin Freeship.Edit.Point_ProjectStraightLinePermanentConstraint; UpdateMenu; end;

procedure TMainForm.PointAnchorExecute(Sender: TObject);
begin Freeship.Edit.Point_AnchorToPoint; UpdateMenu; end;

procedure TMainForm.SelectAllControlPoints1Click(Sender: TObject); begin end;

procedure TMainForm.SelectAllControlPointsExecute(Sender: TObject);
begin Freeship.Edit.Selection_SelectAllControlPoints; UpdateMenu; end;

procedure TMainForm.ImportMichletWavesExecute(Sender: TObject);
begin Freeship.Edit.File_Import_MichletWaves; UpdateMenu; end;

procedure TMainForm.ShowHydrostaticsExecute(Sender: TObject);
begin
   Freeship.Visibility.ShowHydrostaticData:=not Freeship.Visibility.ShowHydrostaticData;
   updatemenu;
end;

procedure TMainForm.MirrorFaceExecute(Sender: TObject);
begin Freeship.Edit.Face_MirrorPlane; UpdateMenu; end;

procedure TMainForm.ExportDXF2DPolylinesExecute(Sender: TObject);
begin Freeship.Edit.File_ExportDXF_2DPolylines; UpdateMenu; end;

procedure TMainForm.FreeShipUpdateGeometryInfo(Sender: TObject);
begin LabelNumbers.Caption
                 :=IntToStr(Freeship.Surface.NumberOfControlFaces) +' Faces, '
                 + IntToStr(Freeship.Surface.NumberOfControlEdges) +' Edges, '
                 + IntToStr(Freeship.Surface.NumberOfControlPoints)+' Points, '
                 + IntToStr(Freeship.Surface.NumberOfControlCurves)+' Curves';
   if Freeship.Surface.Changed then UpdateMenu;
end;

procedure TMainForm.TransformLackenbyExecute(Sender: TObject);
begin Freeship.Edit.Model_LackenbyTransformation; UpdateMenu; end;

procedure TMainForm.ExportIGESExecute(Sender: TObject);
begin Freeship.Edit.File_ExportIGES; UpdateMenu; end;

procedure TMainForm.ExportPartExecute(Sender: TObject);
begin Freeship.Edit.File_ExportPart; UpdateMenu; end;

procedure TMainForm.ImportPartExecute(Sender: TObject);
begin Freeship.Edit.File_ImportPart; UpdateMenu; end;

procedure TMainForm.LayerIntersectionExecute(Sender: TObject);
begin Freeship.Edit.Point_IntersectLayer; UpdateMenu; end;

procedure TMainForm.KeelRudderWizardExecute(Sender: TObject);
begin
   if not Assigned(FreeKeelWizardDialog) then
     FreeKeelWizardDialog:=TFreeKeelWizardDialog.Create(Self);
   ShowTranslatedValues(FreeKeelWizardDialog);
   FreeKeelWizardDialog.Execute(freeship);
   UpdateMenu;
end;

procedure TMainForm.RedoExecute(Sender: TObject);
begin FreeShip.Edit.Redo; UpdateMenu; SetCaption; end;

procedure TMainForm.ClearUndoExecute(Sender: TObject);
begin Freeship.Edit.Undo_Clear; UpdateMenu; end;

procedure TMainForm.ShowUndoHistoryExecute(Sender: TObject);
begin Freeship.Edit.Undo_ShowHistory; UpdateMenu; end;

procedure TMainForm.ImportPolyCadExecute(Sender: TObject);
begin
   Freeship.Edit.File_ImportPolycad;
   FOpenHullWindows;
   UpdateMenu;
end;

procedure TMainForm.RemoveUnusedPointsExecute(Sender: TObject);
begin Freeship.Edit.Point_RemoveUnused; Updatemenu; end;

procedure TMainForm.ExportGHSExecute(Sender: TObject);
begin FreeShip.Edit.File_ExportGHS; UpdateMenu; end;

procedure TMainForm.ShowFlowlinesExecute(Sender: TObject);
begin Freeship.Visibility.ShowFlowlines:=not Freeship.Visibility.ShowFlowlines;
      updatemenu;
end;

procedure TMainForm.AddCylinderExecute(Sender: TObject);
begin Freeship.Edit.Geometry_AddCylinder; UpdateMenu; end;

procedure TMainForm.SelectAllExecute(Sender: TObject);
begin Freeship.Edit.Selection_SelectAll; UpdateMenu; end;

procedure TMainForm.ExportSTLExecute(Sender: TObject);
begin FreeShip.Edit.File_ExportSTL; UpdateMenu; end;

//procedure TMainForm.CrossCurvesExecute(Sender: TObject);
//begin Freeship.Edit.Hydrostatics_Crosscurves; UpdateMenu; end;

procedure TMainForm.SelectLeakPointsExecute(Sender: TObject);
begin Freeship.Edit.Selection_SelectLeakPoints; UpdateMenu; end;

//initialization
//  ExceptionDlg:=TExceptionDlg.create(nil);
end.
