unit LayerDlg;
interface uses
     SysUtils, Controls, StdCtrls,
     ExtCtrls, Forms, CheckLst, Dialogs,
     ComCtrls, STypes,ShipUnit,Geometry;
type
  TLayerDialog  = class(TForm)
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
     TB1,_TB2,TB3,_TB4,TB20,MoveUp,MoveDown: TToolButton;
     procedure LayerBoxClick(Sender: TObject);
     procedure LayerBoxDblClick(Sender: TObject);
     procedure Edit1Change(Sender: TObject);
     procedure Panel3Click(Sender: TObject);
     procedure CheckBox1Click(Sender: TObject);
     procedure CheckBox2Click(Sender: TObject);
     procedure CheckBox3Click(Sender: TObject);
     procedure CheckBox4Click(Sender: TObject);
     procedure CheckBox5Click(Sender: TObject);
     procedure TB20Click(Sender: TObject);
     procedure TB1Click(Sender: TObject);
     procedure TB3Click(Sender: TObject);
     procedure Edit2KeyPress(Sender: TObject; var Key: Char);
     procedure Edit3KeyPress(Sender: TObject; var Key: Char);
     procedure Edit2Exit(Sender: TObject);
     procedure Edit3Exit(Sender: TObject);
     procedure MoveUpClick(Sender: TObject);
     procedure MoveDownClick(Sender: TObject);
     procedure AlphaBarChange(Sender: TObject);
  private
     St: TShip;
     procedure FFillBox;
     function FGetSelectedLayer: SLayer;
  public
     function Execute( Ship:TShip ):Boolean;
     procedure UpdateMenu;
     property SelectedLayer:SLayer read FGetSelectedLayer;
end;

var LayerDialog: TLayerDialog;

implementation uses LanguageSupport,LinesplanFrme;
{$R *.LFM}

procedure TLayerDialog.UpdateMenu;
var I,N : INteger;
begin
   N:=0;
   for I:=1 to St.NoLayers do if St.Layer[I-1].Count=0 then inc(N);
   TB3.Enabled:=(N>0) and (N<St.NoLayers);
   MoveUp.Enabled:=False;
   MoveDown.Enabled:=False;
   if (St.NoLayers>1) and (SelectedLayer<>nil) then
   begin
      MoveUp.Enabled:=SelectedLayer.LayerIndex>0;
      MoveDown.Enabled:=SelectedLayer.LayerIndex<St.NoLayers-1;
   end;
end;

function TLayerDialog.Execute(Ship:TShip):Boolean;
var Undo : TUndoObject;
begin
   St:=Ship;
   Undo:=ship.Edit.CreateUndoObject(Userstring(244),False);
   FFillBox;
   _Label4.Caption:=DensityStr(St.ProjectSettings.ProjectUnits); // Skip translation
   if St.ProjectSettings.ProjectUnits=fuImperial
      then _Label6.Caption:='['+UserString(755)+']'                     //  Inch
      else _Label6.Caption:='['+UserString(756)+']';                     //'[mm]';
   UpdateMenu;
   ShowModal;
   Result:=ModalResult=mrOk;
   if Result then Undo.Accept else begin
      Undo.Restore;
      Undo.Destroy;
   end;
end;

procedure TLayerDialog.FFillBox;
var I,N: Integer; Layer: SLayer;
begin
   LayerBox.Items.BeginUpdate;
   LayerBox.Clear;
// try
      for I:=1 to St.NoLayers do begin
         Layer:=St.Layer[I-1];
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

function TLayerDialog.FGetSelectedLayer:SLayer;
begin if Layerbox.ItemIndex<>-1
      then Result:=Layerbox.Items.Objects[Layerbox.ItemIndex] as SLayer
      else Result:=nil;
end;

procedure TLayerDialog.LayerBoxClick(Sender: TObject);
var Layer   : SLayer;
    Prop    : TLayerProperties;
begin
   if Layerbox.ItemIndex<>-1 then begin
      Layer:=Layerbox.Items.Objects[Layerbox.ItemIndex] as SLayer;
      if Layer.Visible<>Layerbox.Checked[Layerbox.ItemIndex] then begin
         Layer.Visible:=Layerbox.Checked[Layerbox.ItemIndex];
         St.FileChanged:=true;
         St.Redraw;
      end;
      if Layer<>nil then begin
         Edit1.Text:=Layer.Name;
         Panel3.Color:=Layer.Color;
         Checkbox1.Checked:=Layer.Developable;
         Checkbox2.Checked:=Layer.UseForIntersections;
         Checkbox3.Checked:=Layer.UseInHydrostatics;
         Checkbox4.Checked:=layer.ShowInLinesplan;
         Checkbox5.Checked:=layer.Symmetric;
         Checkbox5.Enabled:=not Layer.UseInHydrostatics;
         Edit2.Text:=FloatToDec(Layer.MaterialDensity,4);
         Edit3.Text:=FloatToDec(Layer.Thickness,4);
         Prop:=Layer.SurfaceProperties;
         if St.ProjectSettings.ProjectUnits=fuImperial then Prop.Weight:=Prop.Weight/(12*2240)
                                                         else Prop.Weight:=Prop.Weight/1000;
         _Label10.Caption:=FloatToDec(Prop.SurfaceArea,3)+#32+AreaStr(St.ProjectSettings.ProjectUnits);
         _Label11.Caption:=FloatToDec(Prop.Weight,3)+#32+WeightStr(St.ProjectSettings.ProjectUnits);
         _Label12.Caption:=Makelength(Prop.SurfaceCenterOfGravity.X,2,7)+','+
                          Makelength(Prop.SurfaceCenterOfGravity.Y,2,7)+', '+
                          Makelength(Prop.SurfaceCenterOfGravity.Z,2,7)+#32+LengthStr(St.ProjectSettings.ProjectUnits);
         Alphabar.Position:=255-Layer.AlphaBlend;
         _label1.Caption:=FloatToDec(100*(255-Layer.AlphaBlend)/255,1)+'%';
      end;
   end;
   UpdateMenu;
end;

procedure TLayerDialog.LayerBoxDblClick(Sender: TObject);
var Layer : SLayer;
begin
   if Layerbox.ItemIndex<>-1 then begin
      Layer:=Layerbox.Items.Objects[Layerbox.ItemIndex] as SLayer;
      St.ActiveLayer:=Layer;
   end;
end;

procedure TLayerDialog.Edit1Change(Sender: TObject);
begin
   if SelectedLayer<>nil then if SelectedLayer.Name<>Edit1.Text then begin
      SelectedLayer.Name:=Edit1.Text;
      Layerbox.Items[Layerbox.ItemIndex]:=SelectedLayer.Name;
   end;
end;

procedure TLayerDialog.Panel3Click(Sender: TObject);
begin
   if SelectedLayer<>nil then begin
      ColorDialog.Color:=SelectedLayer.Color;
      if ColorDialog.Execute then begin
         SelectedLayer.Color:=ColorDialog.Color;
         Panel3.Color:=ColorDialog.Color;
         St.Redraw;
      end;
   end;
end;

procedure TLayerDialog.CheckBox1Click(Sender: TObject);
begin
   if SelectedLayer<>nil then
   if SelectedLayer.Developable<>Checkbox1.Checked then begin
      SelectedLayer.Developable:=CheckBox1.Checked;
      St.FileChanged:=true;
      St.Redraw;
   end;
end;

procedure TLayerDialog.TB20Click(Sender: TObject);
var N:         Integer;
    NewLayer:  SLayer;
    LayVis:    Boolean;
begin
// create the new layer, set the colour, set the file to "changed", create undo objcect:
   NewLayer:=St.Edit.Layer_New;
// now update the dialog box. The new layer is the active layer (not the selected layer)
   if St.ActiveLayer<>NewLayer then St.ActiveLayer:=NewLayer;
   LayVis:=NewLayer.Visible;
   N:=Layerbox.Items.AddObject(NewLayer.Name,NewLayer);
   Layerbox.Checked[N] := LayVis;
   Layerbox.ItemIndex:=N;
   LayerBoxClick(self);
   UpdateMenu;
end;

procedure TLayerDialog.TB1Click(Sender: TObject);
    begin Modalresult:=mrOK; end;

procedure TLayerDialog.TB3Click(Sender: TObject);
var noFeedback: Boolean;
begin
// delete the emtpy layers, set a new active layer:
   noFeedback := False; // if quiet, then no undo object, no feedback about number of deleted layers
   St.Edit.Layer_DeleteEmpty(noFeedback);
// now update the dialog box: clear it and build it new
   FFillBox;
   UpdateMenu
end;

procedure TLayerDialog.CheckBox2Click(Sender: TObject);
begin
   if SelectedLayer<>nil then
   if SelectedLayer.UseForIntersections<>Checkbox2.Checked then begin
      SelectedLayer.UseForIntersections:=CheckBox2.Checked;
      St.Build:=False;// forces to rebuild all intersection lines
      St.FileChanged:=true;
      St.Redraw;
   end;
end;

procedure TLayerDialog.CheckBox3Click(Sender: TObject);
begin
   if SelectedLayer<>nil then
   if SelectedLayer.UseInHydrostatics<>Checkbox3.Checked then begin
      SelectedLayer.UseInHydrostatics:=CheckBox3.Checked;
      Checkbox5.Enabled:=not SelectedLayer.UseInHydrostatics;
      Checkbox5.Checked:=SelectedLayer.Symmetric;
      St.Build:=False;// forces to rebuild all hydrostatic calculations
      St.FileChanged:=true;
      St.Redraw;
   end;
end;

procedure TLayerDialog.Edit2KeyPress(Sender: TObject; var Key: Char);
begin
   if Key in [#8,'1'..'9','0',#13,'.'] then else key:=#0;
   if Key=#13 then Edit2Exit(self);
end;

procedure TLayerDialog.Edit2Exit(Sender: TObject);
var Value:Real;
begin
   if SelectedLayer<>nil then begin
      Value:=StrToFloat(Edit2.Text);
      if Value<>SelectedLayer.MaterialDensity then begin
         SelectedLayer.MaterialDensity:=Value;
         LayerBoxClick(self);
      end;
   end;
end;

procedure TLayerDialog.Edit3KeyPress(Sender: TObject; var Key: Char);
begin
   if Key in [#8,'1'..'9','0',#13,'.'] then else key:=#0;
   if Key=#13 then Edit3Exit(self);
end;

procedure TLayerDialog.Edit3Exit(Sender: TObject);
var Value:Real;
begin
   if SelectedLayer<>nil then begin
      Value:=StrToFloat(Edit3.Text);
      if Value<>SelectedLayer.Thickness then begin
         SelectedLayer.Thickness:=Value;
         LayerBoxClick(self);
      end;
   end;
end;

procedure TLayerDialog.MoveUpClick(Sender: TObject);
var Index : Integer;
    Layer:SLayer;
begin
   if SelectedLayer<>nil then begin
      Layer:=SelectedLayer;
      Layer.MoveUp;
      FFillBox;
      Index:=Layerbox.Items.IndexOfObject(Layer);
      Layerbox.ItemIndex:=Index;
      St.FileChanged:=True;
      UpdateMenu;
   end;
end;

procedure TLayerDialog.MoveDownClick(Sender: TObject);
var Index : Integer;
    Layer:SLayer;
begin
   if SelectedLayer<>nil then begin
      Layer:=SelectedLayer;
      Layer.MoveDown;
      FFillBox;
      Index:=Layerbox.Items.IndexOfObject(Layer);
      Layerbox.ItemIndex:=Index;
      St.FileChanged:=True;
      UpdateMenu;
   end;
end;

procedure TLayerDialog.CheckBox4Click(Sender: TObject);
begin
   if SelectedLayer<>nil then
   if SelectedLayer.ShowInLinesplan<>Checkbox4.Checked then begin
      SelectedLayer.ShowInLinesplan:=CheckBox4.Checked;
      St.FileChanged:=true;
      if LinesplanFrame<>nil then LinesplanFrame.Viewport.ZoomExtents;
      St.Redraw;
   end;
end;

procedure TLayerDialog.CheckBox5Click(Sender: TObject);
begin
   if SelectedLayer<>nil then if SelectedLayer.Symmetric<>Checkbox5.Checked then
   begin
      SelectedLayer.Symmetric:=CheckBox5.Checked;
      St.Build:=False;      // forces to rebuild all hydrostatic calculations
      St.FileChanged:=true;
      St.Redraw;
   end;
end;

procedure TLayerDialog.AlphaBarChange(Sender: TObject);
var val:byte;
begin
   Val:=255-Alphabar.Position;
   if SelectedLayer<>nil then if SelectedLayer.AlphaBlend<>val then begin
      SelectedLayer.AlphaBlend:=val;
      _label1.Caption:=FloatToDec(100*(255-SelectedLayer.AlphaBlend)/255,1)+'%';
      St.FileChanged:=true;
      St.Redraw;
   end;
end;

end.

