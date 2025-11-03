unit FreeLayerDlg;
interface
uses SysUtils,
     Classes,
     Controls,
     StdCtrls,
     ExtCtrls,
     Forms,
     CheckLst,
     Dialogs,
     ComCtrls,
     FreeTypes,FreeShipUnit,FreeGeometry;
type
  TFreeLayerDialog  = class(TForm)
     GroupBox1: TGroupBox;
     AlphaBar: TScrollBar;
     LayerBox: TCheckListBox;
     CheckBox1,CheckBox2,CheckBox3,CheckBox4,CheckBox5: TCheckBox;
     ToolBar1: TToolBar;
     MenuImages: TImageList;
     ColorDialog: TColorDialog;
     Panel1,Panel2,Panel3: TPanel;
     Edit1,Edit2,Edit3: TEdit;
     Label1,_Label1,Label2,Label3,Label4,_Label4,Label5,_Label6,
     Label7,Label8,Label9,_Label10,_Label11,_Label12: TLabel;
     ToolButton1,_ToolButton2,ToolButton3,_ToolButton4,ToolButton20,
                                      MoveUp,MoveDown: TToolButton;
     procedure LayerBoxClick(Sender: TObject);
     procedure LayerBoxDblClick(Sender: TObject);
     procedure Edit1Change(Sender: TObject);
     procedure Panel3Click(Sender: TObject);
     procedure CheckBox1Click(Sender: TObject);
     procedure CheckBox2Click(Sender: TObject);
     procedure CheckBox3Click(Sender: TObject);
     procedure CheckBox4Click(Sender: TObject);
     procedure CheckBox5Click(Sender: TObject);
     procedure ToolButton20Click(Sender: TObject);
     procedure ToolButton1Click(Sender: TObject);
     procedure ToolButton3Click(Sender: TObject);
     procedure Edit2KeyPress(Sender: TObject; var Key: Char);
     procedure Edit3KeyPress(Sender: TObject; var Key: Char);
     procedure Edit2Exit(Sender: TObject);
     procedure Edit3Exit(Sender: TObject);
     procedure MoveUpClick(Sender: TObject);
     procedure MoveDownClick(Sender: TObject);
     procedure AlphaBarChange(Sender: TObject);
  private
     FFreeShip: TFreeShip;
     procedure FFillBox;
     function FGetSelectedLayer:TFreeSubdivisionLayer;
  public
     function Execute(FreeShip:TFreeShip):Boolean;
     procedure UpdateMenu;
     property SelectedLayer:TFreeSubdivisionLayer read FGetSelectedLayer;
end;

var FreeLayerDialog : TFreeLayerDialog;

implementation

uses FreeLanguageSupport,
     FreeLinesplanFrme;

{$R *.LFM}

procedure TFreeLayerDialog.UpdateMenu;
var I,N : INteger;
begin
   N:=0;
   for I:=1 to FFreeship.NumberOfLayers do if FFreeship.Layer[I-1].Count=0 then inc(N);
   Toolbutton3.Enabled:=(N>0) and (N<FFreeship.NumberOfLayers);
   MoveUp.Enabled:=False;
   MoveDown.Enabled:=False;
   if (FFreeship.NumberOfLayers>1) and (SelectedLayer<>nil) then
   begin
      MoveUp.Enabled:=SelectedLayer.LayerIndex>0;
      MoveDown.Enabled:=SelectedLayer.LayerIndex<FFreeship.NumberOfLayers-1;
   end;
end;

function TFreeLayerDialog.Execute(FreeShip:TFreeShip):Boolean;
var Undo : TFreeUndoObject;
begin
   FFreeShip:=FreeShip;
   Undo:=Freeship.Edit.CreateUndoObject(Userstring(244),False);
   FFillBox;
   _Label4.Caption:=DensityStr(FFreeship.ProjectSettings.ProjectUnits); // Skip translation
   if FFreeship.ProjectSettings.ProjectUnits=fuImperial then _Label6.Caption:='[Inch]'
                                                        else _Label6.Caption:='[mm]';
   UpdateMenu;
   ShowModal;
   Result:=ModalResult=mrOk;
   if Result then Undo.Accept else begin
      Undo.Restore;
      Undo.Destroy;
   end;
end;

procedure TFreeLayerDialog.FFillBox;
var I,N: Integer; Layer: TFreeSubdivisionLayer;
begin
   LayerBox.Items.BeginUpdate;
   LayerBox.Clear;
// try
      for I:=1 to FFreeShip.NumberOfLayers do begin
         Layer:=FFreeShip.Layer[I-1];
         N:=Layerbox.Items.AddObject(Layer.Name,Layer);
         LayerBox.Checked[N]:=Layer.Visible;
      end;
// finally
      LayerBox.Items.EndUpdate;
      if LayerBox.Count>0 then begin
         LayerBox.ItemIndex:=0;
         LayerBoxClick(self);
      end;
// end;
end;

function TFreeLayerDialog.FGetSelectedLayer:TFreeSubdivisionLayer;
begin if Layerbox.ItemIndex<>-1
      then Result:=Layerbox.Items.Objects[Layerbox.ItemIndex] as TFreeSubdivisionLayer
      else Result:=nil;
end;

procedure TFreeLayerDialog.LayerBoxClick(Sender: TObject);
var Layer   : TFreeSubdivisionLayer;
    Prop    : TLayerProperties;
begin
   if Layerbox.ItemIndex<>-1 then
   begin
      Layer:=Layerbox.Items.Objects[Layerbox.ItemIndex] as TFreeSubdivisionLayer;
      if Layer.Visible<>Layerbox.Checked[Layerbox.ItemIndex] then begin
         Layer.Visible:=Layerbox.Checked[Layerbox.ItemIndex];
         FFreeShip.FileChanged:=true;
         FFreeShip.Redraw;
      end;
      if Layer<>nil then
      begin
         Edit1.Text:=Layer.Name;
         Panel3.Color:=Layer.Color;
         Checkbox1.Checked:=Layer.Developable;
         Checkbox2.Checked:=Layer.UseForIntersections;
         Checkbox3.Checked:=Layer.UseInHydrostatics;
         Checkbox4.Checked:=layer.ShowInLinesplan;
         Checkbox5.Checked:=layer.Symmetric;
         Checkbox5.Enabled:=not Layer.UseInHydrostatics;
         Edit2.Text:=Truncate(Layer.MaterialDensity,4);
         Edit3.Text:=Truncate(Layer.Thickness,4);
         Prop:=Layer.SurfaceProperties;
         if FFreeship.ProjectSettings.ProjectUnits=fuImperial then Prop.Weight:=Prop.Weight/(12*2240)
                                                              else Prop.Weight:=Prop.Weight/1000;
         _Label10.Caption:=FloatToStrF(Prop.SurfaceArea,ffFixed,7,3)+#32+AreaStr(FFreeship.ProjectSettings.ProjectUnits);
         _Label11.Caption:=FloatToStrF(Prop.Weight,ffFixed,7,3)+#32+WeightStr(FFreeship.ProjectSettings.ProjectUnits);
         _Label12.Caption:=Makelength(Prop.SurfaceCenterOfGravity.X,2,7)+','+
                          Makelength(Prop.SurfaceCenterOfGravity.Y,2,7)+', '+
                          Makelength(Prop.SurfaceCenterOfGravity.Z,2,7)+#32+LengthStr(FFreeship.ProjectSettings.ProjectUnits);
         Alphabar.Position:=255-Layer.AlphaBlend;
         _label1.Caption:=FloatToStrF(100*(255-Layer.AlphaBlend)/255,ffFixed,7,1)+'%';
      end;
   end;
   UpdateMenu;
end;

procedure TFreeLayerDialog.LayerBoxDblClick(Sender: TObject);
var Layer : TFreeSubdivisionLayer;
begin
   if Layerbox.ItemIndex<>-1 then
   begin
      Layer:=Layerbox.Items.Objects[Layerbox.ItemIndex] as TFreeSubdivisionLayer;
      FFreeShip.ActiveLayer:=Layer;
   end;
end;

procedure TFreeLayerDialog.Edit1Change(Sender: TObject);
begin
   if SelectedLayer<>nil then if SelectedLayer.Name<>Edit1.Text then
   begin
      SelectedLayer.Name:=Edit1.Text;
      Layerbox.Items[Layerbox.ItemIndex]:=SelectedLayer.Name;
   end;
end;

procedure TFreeLayerDialog.Panel3Click(Sender: TObject);
begin
   if SelectedLayer<>nil then
   begin
      ColorDialog.Color:=SelectedLayer.Color;
      if ColorDialog.Execute then
      begin
         SelectedLayer.Color:=ColorDialog.Color;
         Panel3.Color:=ColorDialog.Color;
         FFreeShip.Redraw;
      end;
   end;
end;

procedure TFreeLayerDialog.CheckBox1Click(Sender: TObject);
begin
   if SelectedLayer<>nil then if SelectedLayer.Developable<>Checkbox1.Checked then
   begin
      SelectedLayer.Developable:=CheckBox1.Checked;
      FFreeShip.FileChanged:=true;
      FFreeShip.Redraw;
   end;
end;

procedure TFreeLayerDialog.ToolButton20Click(Sender: TObject);
var N:         Integer;
    NewLayer:  TFreeSubdivisionLayer;
    LayVis:    Boolean;
begin
// create the new layer, set the colour, set the file to "changed", create undo objcect:
   NewLayer:=FFreeShip.Edit.Layer_New;
// now update the dialog box. The new layer is the active layer (not the selected layer)
   if FFreeShip.ActiveLayer<>NewLayer then FFreeShip.ActiveLayer:=NewLayer;
   LayVis:=NewLayer.Visible;
   N:=Layerbox.Items.AddObject(NewLayer.Name,NewLayer);
   Layerbox.Checked[N] := LayVis;
   Layerbox.ItemIndex:=N;
   LayerBoxClick(self);
   UpdateMenu;
end;

procedure TFreeLayerDialog.ToolButton1Click(Sender: TObject);
begin
   Modalresult:=mrOK;
end;

procedure TFreeLayerDialog.ToolButton3Click(Sender: TObject);
var noFeedback: Boolean;
begin
// delete the emtpy layers, set a new active layer:
   noFeedback := False; // if quiet, then no undo object, no feedback about number of deleted layers
   FFreeShip.Edit.Layer_DeleteEmpty(noFeedback);
// now update the dialog box: clear it and build it new
   FFillBox;
   UpdateMenu
end;

procedure TFreeLayerDialog.CheckBox2Click(Sender: TObject);
begin
   if SelectedLayer<>nil then if SelectedLayer.UseForIntersections<>Checkbox2.Checked then
   begin
      SelectedLayer.UseForIntersections:=CheckBox2.Checked;
      FFreeship.Build:=False;// forces to rebuild all intersection lines
      FFreeShip.FileChanged:=true;
      FFreeShip.Redraw;
   end;
end;

procedure TFreeLayerDialog.CheckBox3Click(Sender: TObject);
begin
   if SelectedLayer<>nil then if SelectedLayer.UseInHydrostatics<>Checkbox3.Checked then
   begin
      SelectedLayer.UseInHydrostatics:=CheckBox3.Checked;
      Checkbox5.Enabled:=not SelectedLayer.UseInHydrostatics;
      Checkbox5.Checked:=SelectedLayer.Symmetric;
      FFreeship.Build:=False;// forces to rebuild all hydrostatic calculations
      FFreeShip.FileChanged:=true;
      FFreeShip.Redraw;
   end;
end;

procedure TFreeLayerDialog.Edit2KeyPress(Sender: TObject; var Key: Char);
begin
   if (Key in [#8,'1'..'9','0',#13]) or (Key=DecimalSeparator) then else key:=#0;
   if Key=#13 then Edit2Exit(self);
end;

procedure TFreeLayerDialog.Edit2Exit(Sender: TObject);
var Value:TFloatType;
begin
   if SelectedLayer<>nil then
   begin
      Value:=StrToFloat(Edit2.Text);
      if Value<>SelectedLayer.MaterialDensity then
      begin
         SelectedLayer.MaterialDensity:=Value;
         LayerBoxClick(self);
      end;
   end;
end;

procedure TFreeLayerDialog.Edit3KeyPress(Sender: TObject; var Key: Char);
begin
   if (Key in [#8,'1'..'9','0',#13]) or (Key=DecimalSeparator) then else key:=#0;
   if Key=#13 then Edit3Exit(self);
end;

procedure TFreeLayerDialog.Edit3Exit(Sender: TObject);
var Value:TFloatType;
begin
   if SelectedLayer<>nil then
   begin
      Value:=StrToFloat(Edit3.Text);
      if Value<>SelectedLayer.Thickness then
      begin
         SelectedLayer.Thickness:=Value;
         LayerBoxClick(self);
      end;
   end;
end;

procedure TFreeLayerDialog.MoveUpClick(Sender: TObject);
var Index : Integer;
    Layer:TFreeSubdivisionLayer;
begin
   if SelectedLayer<>nil then
   begin
      Layer:=SelectedLayer;
      Layer.MoveUp;
      FFillBox;
      Index:=Layerbox.Items.IndexOfObject(Layer);
      Layerbox.ItemIndex:=Index;
      FFreeship.FileChanged:=True;
      UpdateMenu;
   end;
end;

procedure TFreeLayerDialog.MoveDownClick(Sender: TObject);
var Index : Integer;
    Layer:TFreeSubdivisionLayer;
begin
   if SelectedLayer<>nil then begin
      Layer:=SelectedLayer;
      Layer.MoveDown;
      FFillBox;
      Index:=Layerbox.Items.IndexOfObject(Layer);
      Layerbox.ItemIndex:=Index;
      FFreeship.FileChanged:=True;
      UpdateMenu;
   end;
end;

procedure TFreeLayerDialog.CheckBox4Click(Sender: TObject);
begin
   if SelectedLayer<>nil then
   if SelectedLayer.ShowInLinesplan<>Checkbox4.Checked then begin
      SelectedLayer.ShowInLinesplan:=CheckBox4.Checked;
      FFreeShip.FileChanged:=true;
      if FFreeship.LinesplanFrame<>nil then
         TFreeLinesplanFrame(FFreeship.LinesplanFrame).Viewport.ZoomExtents;
      FFreeShip.Redraw;
   end;
end;

procedure TFreeLayerDialog.CheckBox5Click(Sender: TObject);
begin
   if SelectedLayer<>nil then if SelectedLayer.Symmetric<>Checkbox5.Checked then
   begin
      SelectedLayer.Symmetric:=CheckBox5.Checked;
      FFreeship.Build:=False;// forces to rebuild all hydrostatic calculations
      FFreeShip.FileChanged:=true;
      FFreeShip.Redraw;
   end;
end;

procedure TFreeLayerDialog.AlphaBarChange(Sender: TObject);
var val:byte;
begin
   Val:=255-Alphabar.Position;
   if SelectedLayer<>nil then if SelectedLayer.AlphaBlend<>val then begin
      SelectedLayer.AlphaBlend:=val;
      _label1.Caption:=FloatToStrF(100*(255-SelectedLayer.AlphaBlend)/255,ffFixed,7,1)+'%';
      FFreeShip.FileChanged:=true;
      FFreeShip.Redraw;
   end;
end;

end.

