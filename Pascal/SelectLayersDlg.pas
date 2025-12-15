unit SelectLayersDlg;
{$MODE Delphi}
interface uses
     Controls,     Forms,
     Buttons,      ExtCtrls,
     StdCtrls,     ShipUnit,
     Geometry, FasterList, CheckLst;

type TSelectMode = (fsFaces,fsPoints);
     TSelectLayersDialog = class(TForm)
        Panel1,Panel3,Panel4: TPanel;
        BitBtn1,BitBtn2: TSpeedButton;
        LayerBox: TCheckListBox;
        CheckBox: TCheckBox;
        procedure BitBtn1Click(Sender: TObject);
        procedure BitBtn2Click(Sender: TObject);
        procedure LayerBoxClickCheck(Sender: TObject);
        procedure CheckBoxClick(Sender: TObject);
     private
        Fship   : TShip;
        FSelectMode : TSelectMode;
        function FGetLayer(Index:Integer):SLayer;
        function FGetNoLayers:Integer;
        function FGetSelected(Index:Integer):boolean;
        procedure FFillBox;
        procedure FUpdateSelection(Destination:TFasterList);
     public
        function Execute(ship:TShip;SelectMode:TSelectMode):Boolean;
        procedure ExtractSelectedFaces(var Destination:TFasterList);
        procedure ExtractSelectedPoints(var Destination:TFasterList);
        property Layer[index:integer]    : SLayer read FGetLayer;
        property NoLayers          : Integer read FGetNoLayers;
        property Selected[index:integer] : Boolean read FGetSelected;
     end;

var SelectLayersDialog: TSelectLayersDialog;

implementation
{$R *.lfm}

function TSelectLayersDialog.FGetNoLayers:Integer;
   begin Result:=Layerbox.Count; end;
function TSelectLayersDialog.FGetSelected(Index:Integer):boolean;
   begin Result:=Layerbox.Checked[index]; end;
function TSelectLayersDialog.FGetLayer(Index:Integer):SLayer;
   begin Result:=Layerbox.Items.Objects[index] as SLayer; end;
procedure TSelectLayersDialog.FFillBox;
var I,Index: Integer;
    Layer: SLayer;
begin
   LayerBox.Items.BeginUpdate;
   Layerbox.Clear;
   for I:=1 to Fship.NoLayers do begin
      Layer:=Fship.Layer[I-1];
      if Layer.Count>0 then begin
         Index:=Layerbox.Items.AddObject(Layer.Name,Layer);
         Layerbox.Checked[index]:=Layer.Visible;
      end;
   end;
   LayerBox.Items.EndUpdate;
   FUpdateSelection(nil);
end;

procedure TSelectLayersDialog.FUpdateSelection(Destination:TFasterList);
var I,J,Ind: Integer;
    Layer  : SLayer;
    Select : Boolean;
    Point  : SControlPoint;
    Face   : SControlFace;
begin
   if FSelectMode=fsFaces then begin
      for I:=1 to LayerBox.Count do begin
         Layer:=self.Layer[I-1];
         Select:=Layerbox.Checked[I-1];
         for J:=1 to Layer.Count do
          if Layer.Items[J-1].Selected<>Select then Layer.Items[J-1].Selected:=Select;
      end;
      if LayerBox.Count>0 then Fship.Redraw;
   end else begin
      for I:=1 to Fship.Surface.NoControlPoints do begin
         Point:=Fship.Surface.ControlPoint[I-1];
         Select:=False;
         if Point.NoFaces>0 then begin
            if Checkbox.Checked then begin
               // Point must be included in the selection if AT LEAST 1 attached
               // face belongs to a selected layer
               for J:=1 to Point.NoFaces do begin
                  Face:=Point.Face[J-1] as SControlFace;
                  Layer:=Face.Layer;
                  Ind:=LayerBox.Items.IndexOfObject(Layer);
                  if Layerbox.Checked[ind] then begin
                     Select:=True;
                     break;
                  end;
               end;
            end else begin
               // Point must be included in the selection only if ALL attached
               // faces belong to selected layers
               Select:=True;
               for J:=1 to Point.NoFaces do begin
                  Face:=Point.Face[J-1] as SControlFace;
                  Layer:=Face.Layer;
                  Ind:=LayerBox.Items.IndexOfObject(Layer);
                  if not Layerbox.Checked[ind] then begin
                     Select:=false;
                     break;
                  end;
               end;
            end;
            if Destination=nil then Point.Selected:=Select
                else if Select then Destination.Add(Point);
         end;
      end;
      Fship.Redraw;
   end;
end;

function TSelectLayersDialog.Execute
( ship:TShip;SelectMode:TSelectMode ):Boolean;
var OldEdges,OldNormals,OldControlNet : boolean;
begin
   Fship:=ship;
   FSelectMode:=SelectMode;
   FFillBox;
   OldNormals:=ship.Visibility.ShowNormals;
   OldEdges:=ship.Visibility.ShowInteriorEdges;
   OldControlNet:=ship.Visibility.ShowControlNet;
   Checkbox.Visible:=SelectMode=fsPoints;
   if SelectMode=fsFaces then begin
      ship.Visibility.ShowNormals:=False;
      ship.Visibility.ShowInteriorEdges:=True;
   end else begin
      ship.Visibility.ShowNormals:=False;
      ship.Visibility.ShowControlNet:=True;
      ship.Visibility.ShowInteriorEdges:=False;
   end;
      ShowModal;
      Result:=ModalResult=mrOK;
      ship.Visibility.ShowInteriorEdges:=OldEdges;
      ship.Visibility.ShowNormals:=OldNormals;
      ship.Visibility.ShowControlNet:=OldControlNet;
end;

procedure TSelectLayersDialog.ExtractSelectedFaces(var Destination:TFasterList);
var I,J: Integer; Layer: SLayer;
begin
   for I:=1 to NoLayers do if Selected[I-1] then begin
      Layer:=self.Layer[I-1];
      Destination.Capacity:=Destination.Count+Layer.Count;
      for J:=1 to Layer.Count do Destination.Add(Layer.Items[J-1]);
   end;
end;

procedure TSelectLayersDialog.ExtractSelectedPoints(var Destination:TFasterList);
    begin FUpdateSelection(Destination); end;
procedure TSelectLayersDialog.BitBtn1Click(Sender: TObject);
    begin Modalresult:=mrOK; end;
procedure TSelectLayersDialog.BitBtn2Click(Sender: TObject);
    begin Modalresult:=mrCancel; end;
procedure TSelectLayersDialog.LayerBoxClickCheck(Sender: TObject);
    begin if Layerbox.ItemIndex<>-1 then FUpdateSelection(nil); end;
procedure TSelectLayersDialog.CheckBoxClick(Sender: TObject);
    begin if FSelectMode=fsPoints then FUpdateSelection(nil); end;

end.
