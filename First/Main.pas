unit Main;
{$MODE Delphi}
interface uses
//   Windows,ToolWin,Messages,Variants,Classes,Math,ImgList,Memcheck is used for memory-leak tracking (debugging all)
     SysUtils,
     Graphics,
     Controls,
     Forms,Menus,
     Dialogs,
     ExtCtrls,
     ActnList,
     StdCtrls,
     ComCtrls,
     FreeTypes,FreeGeometry,FreeShipUnit,FreeHullformWindow;

type TMainForm = class( TForm )
     FreeShip: TFreeShip;
     MainMenu1: TMainMenu;
     ActionList1: TActionList;
     StatusBar,Panel1: TPanel;            // WindowMenu = Window1
     MenuImages: TImageList;
     LayerBox,PrecisionBox: TComboBox;
     ColorDialog: TColorDialog;
     OpenDialog: TOpenDialog;
     ToolBar1: TToolBar;
     LoadFile,ExitProgram,ShowControlNet,ShowInteriorEdges,NewWindow,TileWindow,
     CascadeWindow,BothSides,SaveFile,LayerAutoGroup,NewLayer,Delete,
     NewEdge,NewFace,EdgeCollapse,EdgeCrease,DeselectAll,PointCollapse,
     ActiveLayerColor,DeleteEmptyLayers,EdgeSplit,
     ShowStations,ShowButtocks,ShowWaterlines: TAction;

     ToolButton1,ToolButton2,ToolButton3,ToolButton4,ToolButton5,ToolButton6,
     ToolButton7,ToolButton8,ToolButton9,ToolButton10,ToolButton11,ToolButton12,
     ToolButton13,ToolButton14,ToolButton15,ToolButton16,ToolButton17,ToolButton18,
     ToolButton19,ToolButton21,ToolButton22,ToolButton23,ToolButton24,
     ToolButton25,ToolButton28,ToolButton29: TToolButton;

     File1,Mediumtelelens130mm1,ExitProgram1,Visibility1,ShowControlNet1,
     ShowInteriorEdges1,Window1,Cascade1,Tile1,NewWindow1,N1,Showbothsides1,
     Save1,Layer1,Autogroup1,New1,Edit1,Point1,Edge1,Face1,Collapse1,Delete1,
     New2,New4,Crease1,Selection1,PointCollapse1,Clearselection1,
     Activelayercolor1,Deleteempty1,
     Stations1,Buttocks1,Waterlines1,Deselectall1,Split1: TMenuItem;

     procedure LoadFileExecute(Sender: TObject);
     procedure ExitProgramExecute(Sender: TObject);
     procedure FormShow(Sender: TObject);
     procedure ShowControlNetExecute(Sender: TObject);
     procedure ShowInteriorEdgesExecute(Sender: TObject);
     procedure NewWindowExecute(Sender: TObject);
     procedure TileWindowExecute(Sender: TObject);
     procedure CascadeWindowExecute(Sender: TObject);
     procedure BothSidesExecute(Sender: TObject);
     procedure FreeShipFileChanged(Sender: TObject);
     procedure PrecisionBoxChange(Sender: TObject);
     procedure SaveFileExecute(Sender: TObject);
     procedure LayerAutoGroupExecute(Sender: TObject);
     procedure FormClose(Sender: TObject; var Action: TCloseAction);
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
     procedure FormCreate(Sender: TObject);
     procedure ShowStationsExecute(Sender: TObject);
     procedure ShowButtocksExecute(Sender: TObject);
     procedure ShowWaterlinesExecute(Sender: TObject);
     procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
     procedure NewFaceExecute(Sender: TObject);
     procedure EdgeSplitExecute(Sender: TObject);
  private
     procedure FreeShipChangeLayerData(Sender: TObject);
     procedure FreeShipChangeActiveLayer(Sender: TObject;Layer: TFreeSubdivisionLayer);
     procedure FOnSelectItem(Sender:TObject);
  public
//   procedure CustomExceptionHandler(Sender: TObject; E: Exception);
     procedure SetCaption;
     procedure UpdateMenu;
end;

var MainForm: TMainForm;

implementation
{$R *.lfm}
{
procedure TMainForm.CustomExceptionHandler( Sender:TObject; E:Exception );
    begin WriteLn( 'Exception: '+E.Message ); end;    // Halt; = End of program
}
procedure TMainForm.FOnselectItem(Sender:TObject);
var Face1,Face2: TFreeSubdivisionControlFace; Diff: Boolean; I: Integer;
begin
   if FreeShip.NumberOfSelectedControlFaces>0 then begin // set the layerbox itemindex to the index of the layer of the selected controlfaces
      Face1:=FreeShip.SelectedControlFace[0];            // check if all selected controlfaces belong to the same layer
      Diff:=False;
      for I:=1 to FreeShip.NumberOfSelectedControlFaces do begin
         Face2:=FreeShip.SelectedControlFace[I-1];
         if Face1.Layer<>Face2.Layer then begin Diff:=True; Break; end;
      end;
      if not Diff
       then FreeShipChangeActiveLayer( self,Face1.Layer )
       else FreeShipChangeActiveLayer( self,nil );
   end else FreeShipChangeActiveLayer( self,FreeShip.ActiveLayer );
   UpdateMenu;
end;
procedure TMainForm.SetCaption;
begin
  if FreeShip.FileChanged then Caption:='FREE!ship : '+FreeShip.Filename+' (modified)'
                          else Caption:='FREE!ship : '+FreeShip.Filename+' (not modified)';
end;
procedure TMainForm.UpdateMenu;         // In this procedure all actions are set
begin  //  to enabled/disabled according to the current state and selected items
   SaveFile.Enabled:=FreeShip.Surface.NumberOfControlPoints>0; // File menu
   ShowControlNet.Enabled:=FreeShip.Surface.NumberOfControlPoints>0;
   ShowControlNet.Checked:=FreeShip.Visibility.ShowControlNet; // Show interior edges
   ShowInteriorEdges.Enabled:=FreeShip.Surface.NumberOfControlFaces>0;
   ShowInteriorEdges.Checked:=FreeShip.Visibility.ShowInteriorEdges; // Show both sides
   BothSides.Checked:=Freeship.Visibility.ModelView=mvBoth;
   BothSides.Enabled:=FreeShip.Surface.NumberOfControlFaces>0; // Delete
   Delete.Enabled:=Freeship.NumberOfSelectedControlPoints+FreeShip.NumberOfSelectedControlEdges+Freeship.NumberOfSelectedControlFaces>0;
   TileWindow.Enabled:=MDIChildCount>0;                        // Window menu actions
   CascadeWindow.Enabled:=MDIChildCount>0;                     // Precision
   PrecisionBox.ItemIndex:=Ord(FreeShip.Precision);            // Layers
   LayerAutoGroup.Enabled:=(Freeship.Surface.NumberOfControlFaces>1) and (FreeShip.Visibility.ShowInteriorEdges);
   EdgeCollapse.Enabled:=FreeShip.NumberOfSelectedControlEdges>0;
   NewEdge.Enabled:=FreeShip.NumberOfSelectedControlPoints>1;
   EdgeCrease.Enabled:=FreeShip.NumberOfSelectedControlEdges>0;
   DeselectAll.Enabled:=Freeship.NumberOfSelectedControlPoints+FreeShip.NumberOfSelectedControlEdges+Freeship.NumberOfSelectedControlFaces>0;
   PointCollapse.Enabled:=Freeship.NumberOfSelectedControlPoints>0;
   DeleteEmptyLayers.Enabled:=FreeShip.NumberOfLayers>1;
   ShowStations.Enabled:=Freeship.NumberofStations>0;
   ShowStations.Checked:=FreeShip.Visibility.ShowStations;
   ShowButtocks.Enabled:=Freeship.NumberofButtocks>0;
   ShowButtocks.Checked:=FreeShip.Visibility.ShowButtocks;
   ShowWaterlines.Enabled:=Freeship.NumberofWaterlines>0;
   ShowWaterlines.Checked:=FreeShip.Visibility.ShowWaterlines;
   NewFace.Enabled:=FreeShip.NumberOfSelectedControlPoints>2;
   EdgeSplit.Enabled:=FreeShip.NumberOfSelectedControlEdges>0;
end;
procedure TMainForm.ExitProgramExecute( Sender: TObject );
    begin UpdateMenu; Close; end;
procedure TMainForm.FormShow( Sender: TObject );
var HullformWindow:TFreeHullWindow; I:Integer;
begin                                                  // Initialize some data
   DecimalSeparator:='.';
   FreeShip.OnChangeActiveLayer:=FreeShipChangeActiveLayer;
   Freeship.OnChangeLayerData:=FreeShipChangeLayerData;
   FreeShip.OnSelectItem:=FOnSelectItem;
   FreeShip.Clear;
   if ParamCount<>0 then begin
      if (FileExists(ParamStr(1)))
      and (Uppercase(ExtractFileExt(ParamStr(1)))='.FREE') then begin
{*+ =    FOpenHullWindows;
}        if MDIChildCount=0 then begin
            for i:=0 to 3 do begin                            // open a new window
               HullformWindow:=TFreeHullWindow.Create(self); // Connect viewport to freeship component
               HullformWindow.FreeShip:=FreeShip;
               HullformWindow.Viewport.ViewType:=TFreeViewType(I);
               HullformWindow.SetCaption;
            end;
            Tile;
{*}      end;
         FreeShip.Filename:=ParamStr(1);
         FreeShip.LoadFromFile;
         SetCaption;
         UpdateMenu;
      end else MessageDlg('Unable to open '+ParamStr(1),mtError,[mbOk],0);
   end;
   SetCaption;
   UpdateMenu;
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
procedure TMainForm.NewWindowExecute(Sender: TObject);
var HullformWindow :TFreeHullWindow;
begin                       // Application.OnException:=CustomExceptionHandler;
   HullformWindow:=TFreeHullWindow.Create(self);           // open a new window
   HullformWindow.FreeShip:=FreeShip; // Connect viewport to freeship component
   HullformWindow.Viewport.ViewType:=fvPerspective;
   HullformWindow.SetCaption;
   UpdateMenu;
end;
procedure TMainForm.TileWindowExecute( Sender: TObject );
    begin Tile; end;
procedure TMainForm.CascadeWindowExecute( Sender: TObject );
    begin Cascade; end;
procedure TMainForm.BothSidesExecute( Sender: TObject );
begin
   if FreeShip.Visibility.ModelView=mvBoth then FreeShip.Visibility.ModelView:=mvPort
                                           else FreeShip.Visibility.ModelView:=mvBoth;
   UpdateMenu;
end;
procedure TMainForm.FreeShipFileChanged(Sender: TObject);
    begin SetCaption; end;
procedure TMainForm.PrecisionBoxChange(Sender: TObject);
    begin FreeShip.Precision:=TFreePrecisionType(PrecisionBox.ItemIndex);
          UpdateMenu;
    end;
procedure TMainForm.LayerAutoGroupExecute(Sender: TObject);
    begin FreeShip.Edit.Layer_AutoGroup; UpdateMenu; end;
procedure TMainForm.FreeShipChangeLayerData(Sender: TObject);
var I : Integer;
begin                              // Fill the layerbox with the current layers
   LayerBox.Items.BeginUpdate;
   LayerBox.Items.Clear;
   for I:=1 to Freeship.NumberOfLayers do
       Layerbox.Items.AddObject(FreeShip.Layer[I-1].Name,FreeShip.Layer[I-1]);
       LayerBox.Items.EndUpdate;
end;
procedure TMainForm.FreeShipChangeActiveLayer(Sender: TObject;Layer: TFreeSubdivisionLayer);
var Index : Integer;
begin
   if (FreeShip.NumberOfSelectedControlFaces<>0)
   and (FreeShip.ActiveLayer=Layer) then begin // do not switch to the active layer when controlfaces are selected
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
procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
    begin FreeShip.OnChangeActiveLayer:=nil;
          Freeship.OnChangeLayerData:=nil;
          FreeShip.OnSelectItem:=nil;
    end;
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

procedure TMainForm.LayerBoxChange(Sender: TObject);
var Layer: TFreeSubdivisionLayer; I,Index: Integer;
begin
   Index:=Layerbox.ItemIndex;
   if index=-1 then Index:=0;
   Layer:=Layerbox.Items.Objects[index] as TFreeSubdivisionLayer;
   if Freeship.NumberOfSelectedControlFaces=0 then begin // change the active layer
      if Layer<>FreeShip.ActiveLayer then FreeShip.ActiveLayer:=Layer;
   end else begin          // Assign all selected controlfaces to the new layer
      for I:=FreeShip.NumberOfSelectedControlFaces downto 1 do
          FreeShip.SelectedControlFace[I-1].Layer:=Layer;
      FreeShip.FileChanged:=True;
      FreeShip.Redraw;
   end;
   UpdateMenu;
end;
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
procedure TMainForm.Panel1Click(Sender: TObject);
    begin ActiveLayerColorExecute(self); end;
procedure TMainForm.DeleteEmptyLayersExecute(Sender: TObject);
    begin Freeship.Edit.Layer_DeleteEmpty; UpdateMenu; end;
procedure TMainForm.FormCreate(Sender: TObject);
    begin end; // Initialize memcheck, for memory-leak tracking = MemChk;
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
procedure TMainForm.NewFaceExecute(Sender: TObject);
    begin FreeShip.Edit.Face_New; UpdateMenu; end;
procedure TMainForm.EdgeSplitExecute(Sender: TObject);
    begin FreeShip.Edit.Edge_Split; UpdateMenu; end;
procedure TMainForm.FormCloseQuery( Sender: TObject; var CanClose: Boolean );
begin if Freeship.FileChanged
      then CanClose:=mrYes=MessageDlg('The model has been changed.'+EOL
           + 'Are you sure you want to quit?',mtWarning,[mbYes,mbNo],0 );
end;

{$I Main_File.inc}

end.
