{%MainUnit FreeShipUnit.pas}
{-------------------------------------------------------------}
{   TFreeEdit                                                 }
{   Container class for all editing commandsns for the hull   }
{-------------------------------------------------------------}

function TFreeEdit.FGetRecentFile(Index: integer): string;
begin
  if (index<0) or (index>=FRecentFiles.Count) then exit;
  Result:=FRecentFiles[index];
end;

function TFreeEdit.FGetRecentFileCount: integer;
begin Result:=FRecentFiles.Count;
end;

// Takes a filename and adds it to the list with recent files
procedure TFreeEdit.AddToRecentFiles(Filename: string);
var
  I,Index: integer;
  AlreadyPresent: boolean;
  Tmp,Ext: string;
begin
  AlreadyPresent:=False;
  Ext:=Uppercase(ExtractFileExt(Filename));
  Index:=-1;
  Tmp:=Trim(Filename);
  for I:=0 to FRecentFiles.Count-1 do
    if Uppercase(Trim(FRecentFiles[I]))=Uppercase(Tmp) then begin
      Index:=I; break;
    end;                                 // Already in list. move to the front;
  if Index >= 0 then begin
    FRecentFiles.Delete(Index);
    FRecentFiles.Insert(0, Tmp);
  end else
    if FRecentFiles.Count = 0 then FRecentFiles.Add(Tmp) else
       FRecentFiles.Insert(0,Tmp); // file not yet in the list, add at the front
                                  // delete items until no more than 10 are left
  while FRecentFiles.Count > 10 do FRecentFiles.Delete(FRecentFiles.Count - 1);
  if assigned(FreeShip.FOnUpdateRecentFileList) then
     FreeShip.FOnUpdateRecentFileList(self);
end;

// Delete the backgrundimage associated with this view
procedure TFreeEdit.BackgroundImage_Delete(Viewport: TFreeViewport);
var
  I: integer;
begin
  if MessageDlg(Userstring(68), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    for I:=FFreeShip.NumberofBackgroundImages downto 1 do
      if FFreeShip.BackgroundImage[I - 1].AssignedView = Viewport.ViewType then
      begin
        FFreeShip.BackgroundImage[I - 1].Destroy;
        FFreeShip.FBackgroundImages.Delete(I - 1);
        FFreeShip.FileChanged:=True;
        break;
      end;
    for I:=1 to FreeShip.NumberOfViewports do
      if FreeShip.Viewport[I-1].ViewType = Viewport.ViewType then begin
         FreeShip.Viewport[I-1].BackgroundImage.Clear;
         FreeShip.Viewport[I-1].Refresh;
      end;
  end;
end;

// browse for and open a backgroundimage
procedure TFreeEdit.BackgroundImage_Open(Viewport: TFreeViewport);
var
  I: integer;
  Data: TFreebackgroundImagedata;
  Dialog: TOpenPictureDialog;
  Pt: TPoint;
  P2D: T2DCoordinate;
  Bmp: TBitmap;
begin
  Data:=nil;
  for I:=1 to FreeShip.NumberofBackgroundImages do
    if FreeShip.BackgroundImage[I - 1].AssignedView = Viewport.ViewType then
      Data:=FreeShip.BackgroundImage[I - 1];
  if Data <> nil then
    if MessageDlg(Userstring(69) + EOL + Userstring(70), mtConfirmation,
      [mbYes, mbNo], 0) = mrNo then exit;

  Dialog:=TOpenPictureDialog.Create(Viewport);
  Dialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  Dialog.Filter:=createDialogFilter(rsImageFiles, ['jpg', 'bmp'], False)
      +'|'+createDialogFilter(rsJPEGFiles, ['jpg'], False)
      +'|'+createDialogFilter(rsBitmapFiles, ['bmp']);

    //Dialog.Options:=[ofHideReadOnly];
  if Dialog.Execute then begin
    if Data = nil then begin
      Data:=TFreeBackgroundImageData.Create(FFreeShip);
      FFreeShip.FBackgroundImages.Add(Data);
    end;
    Data.Clear;
    if Uppercase(ExtractFileExt(Dialog.Filename)) = '.JPG' then begin
      Data.FImageData.LoadFromFile(Dialog.FileName);
      Data.FQuality:=Data.FImageData.CompressionQuality;
    end else begin
      Bmp:=TBitmap.Create;
      Bmp.LoadFromFile(Dialog.Filename);
      Data.FImageData.Assign(Bmp);
      FreeAndNil(Bmp);
      Data.FQuality:=100;
    end;
    if not Data.FImageData.Empty then begin
      Data.FAssignedView:=Viewport.ViewType;
      Data.FOrigin.X:=0;
      Data.FOrigin.Y:=Data.FImageData.Height;
      if FreeShip.NumberofBackgroundImages > 1 then
        Data.FScale:=FreeShip.BackgroundImage // use same scale as previous images
          [FreeShip.NumberofBackgroundImages-2].FScale
      else begin    // calculate scale
        Pt:=Viewport.Project(ZERO);
        Pt.X:=Viewport.ClientWidth;
        P2D:=Viewport.ProjectBackTo2D(Pt);
        Data.FScale:=P2D.X / Data.FImageData.Width;
      end;
      Data.UpdateViews;
    end;
    FreeShip.FileChanged:=True;
  end;
  FreeAndNil(Dialog);

end;

constructor TFreeEdit.Create(FreeShip: TFreeShip);
begin
  inherited Create;
  FFreeShip:=FreeShip;
  FRecentFiles:=TStringList.Create;
end;{TFreeEdit.Create}

function TFreeEdit.CreateRedoObject: TFreeUndoObject;
var
  UndoObject: TFreeUndoObject;
  Version: TFreeFileVersion;
  Preview: boolean;
begin
  UndoObject:=TFreeUndoObject.Create(FreeShip);
  Result:=UndoObject;
  UndoObject.FUndoText:=UserString(71);
  Version:=FreeShip.FileVersion;
  Preview:=FreeShip.ProjectSettings.SavePreview;
//try              // Temp. set to the latest fileversion so that no data will be lost
    FreeShip.FFileVersion:=Currentversion;  // Temp. disable saving of preview image
    FreeShip.ProjectSettings.SavePreview:=False;
    UndoObject.FFileChanged:=FreeShip.FileChanged;
    UndoObject.FFileName:=FreeShip.Filename;
    UndoObject.FEditMode:=FreeShip.EditMode;
    UndoObject.FFilenameSet:=FreeShip.FFilenameSet;
    UndoObject.FIsTempRedoObject:=True;
    FreeShip.SaveProject(UndoObject.FUndoData);
    UndoObject.Accept;
//finally // Restore the original fileversion
    FreeShip.FileVersion:=Version;
    FreeShip.ProjectSettings.SavePreview:=Preview;
    if Assigned( FreeShip.FOnUpdateUndoData ) then
       FreeShip.FOnUpdateUndoData( FreeShip );
//end;
end;

// Creates undodata just prior to modifications
function TFreeEdit.CreateUndoObject(UndoText: string; Accept: boolean): TFreeUndoObject;
var
  UndoObject: TFreeUndoObject;
  Version: TFreeFileVersion;
  Preview: boolean;
  I: integer;
begin
  UndoObject:=TFreeUndoObject.Create(FreeShip);
  Result:=UndoObject;
  //if UndoText<>'' then UndoText[1]:=Lowercase(UndoText[1]);
  UndoObject.FUndoText:=UndoText;
  Version:=FreeShip.FileVersion;
  Preview:=FreeShip.ProjectSettings.SavePreview;
//try                                       // delete all undo objects after the current one
    for I:=FFreeShip.FUndoObjects.Count downto FreeShip.FUndoPosition + 1 do
      FreeShip.UndoObject[I - 1].Delete;    // Temp. set to the latest fileversion so that no data will be lost
    FreeShip.FFileVersion:=Currentversion;
    // Temp. disable saving of preview image
    FreeShip.ProjectSettings.SavePreview:=False;
    UndoObject.FFileChanged:=FreeShip.FileChanged;
    UndoObject.FFileName:=FreeShip.Filename;
    UndoObject.FEditMode:=FreeShip.EditMode;
    UndoObject.FFilenameSet:=FreeShip.FFilenameSet;
    FreeShip.SaveProject(UndoObject.FUndoData);
    if Accept then UndoObject.Accept;
//finally
    // Restore the original fileversion
    FreeShip.FileVersion:=Version;
    FreeShip.ProjectSettings.SavePreview:=Preview;
    if Assigned(FreeShip.FOnUpdateUndoData) then FreeShip.FOnUpdateUndoData(FreeShip);
//end;
end;{TFreeEdit.CreateUndoObject}

// Add (a) new controlcurve(s)
procedure TFreeEdit.Curve_Add;
var
  Edges: TFasterListTFreeSubdivisionEdge;
  SortedPointLists: TFasterListTFreeSubdivisionFace;
  Points: TFasterListTFreeSubdivisionPoint;
  Edge: TFreeSubdivisionControlEdge;
  I, J: integer;
  Point: TFreeSubdivisionControlPoint;
  Curve: TFreesubdivisionControlCurve;
begin
  Edges:=TFasterListTFreeSubdivisionEdge.Create;
  Edges.Capacity:=FreeShip.NumberOfSelectedControlEdges;
  for I:=0 to FreeShip.NumberOfSelectedControlEdges - 1 do
  begin
    Edge:=FreeShip.SelectedControlEdge[I];
    if Edge.Curve = nil then
      Edges.Add(Edge);
  end;
  if Edges.Count > 0 then
  begin
    Self.CreateUndoObject(Userstring(72), True);
    SortedPointLists:=TFasterListTFreeSubdivisionFace.Create(false,false);
    FreeShip.Surface.IsolateEdges(Edges, SortedPointLists);
    for I:=1 to SortedPointLists.Count do begin
      Points:=SortedPointLists[I - 1].Points;
      if Points.Count > 1 then begin
        Curve:=TFreeSubdivisionControlCurve.Create(FreeShip.Surface);
        FreeShip.Surface.AddControlCurve(Curve);
        for J:=1 to Points.Count do begin
          Point:=Points[J - 1] as TFreeSubdivisionControlPoint;
          Curve.AddPoint(Point);
          if J > 1 then begin
            Edge:=Curve.Surface.EdgeExists(
              Curve.ControlPoint[J - 2], Curve.ControlPoint[J - 1]) as
              TFreeSubdivisionControlEdge;
            if Edge <> nil then Edge.Curve:=Curve;
          end;
        end;
        Freeship.Built:=false;
      end;
      FreeAndNil(Points);
    end;
    Freeship.RebuildModel;
    for I:=FreeShip.NumberOfSelectedControlEdges downto 1 do begin
      Edge:=FreeShip.SelectedControlEdge[I - 1];
      Edge.Selected:=False;
    end;
    FreeAndNil(SortedPointLists);
    if FreeShip.Visibility.ShowControlCurves = False
       then FreeShip.Visibility.ShowControlCurves:=True
       else Freeship.RebuildModel;
    FreeShip.FileChanged:=True;
    if Assigned(FreeShip.OnUpdateGeometryInfo)
       then FreeShip.OnUpdateGeometryInfo(self);
  end;
  FreeAndNil(Edges);
end;

destructor TFreeEdit.Destroy;
begin FreeAndNil(FRecentFiles); inherited Destroy; end;

// Remove an edge by replacing the two connected faces by one controlface
procedure TFreeEdit.Edge_Collapse;
var
  I, N: integer;
  Edge: TFreeSubdivisionControlEdge;
  vUndo: TFreeUndoObject;
begin
  N:=0; vUndo:=CreateUndoObject( Userstring(73), False );
  FreeShip.Surface.ClearMesh;
  for I:=FreeShip.NumberOfSelectedControlEdges downto 1 do
  begin
    Edge:=FreeShip.SelectedControlEdge[I - 1];
    if Edge.NumberOfFaces>1then begin Edge.Collapse; Inc(N); end;
  end;
  if N > 0 then begin
    vUndo.Accept;
    FreeShip.Built:=False;
    Freeship.RebuildModel;
    FreeShip.FileChanged:=True;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then
      FreeShip.OnUpdateGeometryInfo(self);
  end else vUndo.Delete;
end;

// Create a new edge by connection two controlpoints belonging to the same controlface
procedure TFreeEdit.Edge_Connect;
var
  vUndo: TFreeUndoObject;
  N: integer;
begin
  N:=FreeShip.Surface.NumberOfControlEdges;
  vUndo:=CreateUndoObject(Userstring(74), False);
  FreeShip.Surface.Edge_Connect;
  if FreeShip.Surface.NumberOfControlEdges > N then
  begin
    vUndo.Accept;
    FreeShip.FileChanged:=True;
    FreeShip.Built:=False;
    Freeship.RebuildModel;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then
      FreeShip.OnUpdateGeometryInfo(self);
  end else vUndo.Delete;
end;

// Switch selected edges between normal or crease edges (knuckle lines)
procedure TFreeEdit.Edge_Crease;
var
  I: integer;
begin
  CreateUndoObject(Userstring(75), True);
  for I:=FreeShip.NumberOfSelectedControlEdges downto 1 do
    FreeShip.SelectedControlEdge[I - 1].Crease :=
      not FreeShip.SelectedControlEdge[I - 1].Crease;
  FreeShip.Built:=False;
  Freeship.RebuildModel;
  FreeShip.FileChanged:=True;
end;

// Create new controlPoints by extruding selected points
procedure TFreeEdit.Point_Extrude;
var
  Dialog: TFreeExtrudeDialog;
  Point: TFreeSubdivisionControlPoint;
  Vector: T3DCoordinate;
  Points, NewPoints: TFasterListTFreeSubdivisionControlPoint;
  I: integer;
  Str: string;
  vUndo: TFreeUndoObject;
begin
  Dialog:=TFreeExtrudeDialog.Create(FreeShip);                                //ShowTranslatedValues(Dialog);
  Dialog.XValue:=0.0;
  Dialog.YValue:=0.0;
  Dialog.ZValue:=0.0;
  Str:=LengthStr(FreeShip.ProjectSettings.ProjectUnits);
  if Dialog.Execute(Str) then begin
    vUndo:=CreateUndoObject(Userstring(76), False);
    Vector.X:=Dialog.XValue;
    Vector.Y:=Dialog.YValue;
    Vector.Z:=Dialog.ZValue;                     // Assemble Points in a list
    Points:=TFasterListTFreeSubdivisionControlPoint.Create;
    for i:=0 to FreeShip.NumberOfSelectedControlPoints-1 do begin
      Point:=FreeShip.Surface.SelectedControlPoint[i];
      Points.Add(Point);
    end;
    if Points.Count > 0 then begin
      for i:=0 to Points.Count-1 do Points[i].Selected:=false;
      NewPoints:=FreeShip.Surface.ExtrudeControlPoints(Points, Vector);
      for i:=0 to NewPoints.Count-1 do begin
        Point:=NewPoints[i];
        Point.Selected:=True;
      end;
      vUndo.Accept;
      FreeShip.Built:=False;
      FreeShip.FileChanged:=True;
      Freeship.RebuildModel;
      if Assigned(FreeShip.OnUpdateGeometryInfo) then
        FreeShip.OnUpdateGeometryInfo(self);
    end else begin
      MessageDlg(Userstring(77), mtError, [mbOK], 0);
      vUndo.Delete;
    end;
    FreeAndNil(Points);
  end;
  FreeAndNil(Dialog);
end;

// Create new controlfaces by extruding selected boundary edges (eg edges with only 1 controlface connected to it)
procedure TFreeEdit.Edge_Extrude;
var
  Dialog: TFreeExtrudeDialog;
  Edge: TFreeSubdivisionControlEdge;
  Vector: T3DCoordinate;
  Edges: TFasterListTFreeSubdivisionEdge;
  I: integer;
  Str: string;
  vUndo: TFreeUndoObject;
begin
  Dialog:=TFreeExtrudeDialog.Create(FreeShip);                                //ShowTranslatedValues(Dialog);
  Dialog.XValue:=0.0;
  Dialog.YValue:=0.0;
  Dialog.ZValue:=0.0;
  Str:=LengthStr(FreeShip.ProjectSettings.ProjectUnits);
  if Dialog.Execute(Str) then begin
    vUndo:=CreateUndoObject(Userstring(76), False);
    Vector.X:=Dialog.XValue;
    Vector.Y:=Dialog.YValue;
    Vector.Z:=Dialog.ZValue;                      // Assemble edges in a list
    Edges:=TFasterListTFreeSubdivisionEdge.Create;
    for I:=FreeShip.NumberOfSelectedControlEdges downto 1 do begin
      Edge:=FreeShip.Surface.SelectedControlEdge[I - 1]; // only boundary and freestanding edges are allowed!!
      if Edge.NumberOfFaces <= 1 then Edges.Add(Edge);
      Edge.Selected:=False;
    end;
    if Edges.Count > 0 then begin
      FreeShip.Surface.ExtrudeEdges(Edges, Vector);        // New edges are returned in the edges-list, select them
      for I:=1 to Edges.Count do begin
        Edge:=Edges[I - 1] as TFreeSubdivisionControlEdge;
        Edge.Selected:=True;
      end;
      vUndo.Accept;
      FreeShip.Built:=False;
      FreeShip.FileChanged:=True;
      Freeship.RebuildModel;
      if Assigned(FreeShip.OnUpdateGeometryInfo) then
        FreeShip.OnUpdateGeometryInfo(self);
    end else begin
      MessageDlg(Userstring(77), mtError, [mbOK], 0);
      vUndo.Delete;
    end;
    FreeAndNil(Edges);
  end;
  FreeAndNil(Dialog);
end;

// Create new controlpoints by splitting an controledge into two.
procedure TFreeEdit.Edge_Split;
var
  I, N: integer;
  Edge: TFreeSubdivisionControlEdge;
  Point: TFreeSubdivisionControlPoint;
  Last: TFreeSubdivisionControlPoint;
  vUndo: TFreeUndoObject;
begin
  N:=0;
  Last:=nil;
  vUndo:=CreateUndoObject(Userstring(78), False);

  FreeShip.Surface.ClearMesh;

  for I:=FreeShip.NumberOfSelectedControlEdges downto 1 do
  begin
    Edge:=FreeShip.Surface.SelectedControlEdge[I - 1];
    Edge.Selected:=False;
    Point:=Edge.InsertControlPoint(
      MidPoint(Edge.StartPoint.Coordinate, Edge.EndPoint.Coordinate));
    if Point <> nil then
    begin
      Point.Selected:=True;
      Last:=Point;
      Inc(N);
    end;
  end;
  if Last <> nil then
    FreeShip.ActiveControlPoint:=Last;
  if N > 0 then
  begin
    vUndo.Accept;
    FreeShip.Built:=False;
    FreeShip.FileChanged:=True;
    Freeship.RebuildModel;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then
      FreeShip.OnUpdateGeometryInfo(self);
  end
  else
    vUndo.Delete;
end;{TFreeEdit.Edge_Split}

procedure TFreeEdit.Face_Assemble;
var
  Assembled: TFreeFaceArray;
  NAssembled: integer;
  Layers: TFasterListTFreeSubdivisionLayer;
  I, J, K: integer;
  AssFace: TFreeFaceGrid;
  Layer: TFreeSubdivisionLayer;
  Face: TFreeSubdivisionControlFace;
begin
  Layers:=TFasterListTFreeSubdivisionLayer.Create;
  for I:=1 to FreeShip.Surface.NumberOfLayers do
    Layers.Add(FreeShip.Surface.Layer[I - 1]);
  FreeShip.Visibility.ShowInteriorEdges:=True;
  FreeShip.Surface.AssembleFacesToPatches(Layers, amNurbs, Assembled, NAssembled);
  if NAssembled > 0 then
  begin
    // assign all patches to new layers
    for I:=1 to NAssembled do
    begin
      Layer:=FreeShip.Surface.AddNewLayer;
      Layer.Color:=RandomColor;
      AssFace:=Assembled[I - 1];
      for J:=1 to AssFace.NRows do
        for K:=1 to AssFace.NCols do
        begin
          Face:=AssFace.Faces[J - 1][K - 1];
          if Face <> nil then
            Face.Layer:=Layer;
        end;
    end;
    Layer_DeleteEmpty(True);
    Freeship.RebuildModel;
    ShowMessage('Assembled ' + IntToStr(NAssembled) + ' patches');
  end;
  FreeAndNil(Layers);
end;{TFreeEdit.Face_Assemble}

// Deletes all faces on the starboardside of the hull
procedure TFreeEdit.Face_DeleteNegative;
var
  IsNegative: boolean;
  I, J: integer;
  RemovedF: integer;
  RemovedP: integer;
  Face: TFreeSubdivisionControlFace;
  Point: TFreeSubdivisionControlPoint;
  PrevCursor: TCursor;
  vUndo: TFreeUndoObject;
  Str: string;
begin
  RemovedF:=0;
  RemovedP:=0;
  PrevCursor:=Screen.Cursor;
  Screen.Cursor:=crHourglass;
  vUndo:=CreateUndoObject(Userstring(79), False);
//try
    for I:=FreeShip.Surface.NumberOfControlFaces downto 1 do
    begin
      Face:=FreeShip.Surface.ControlFace[I - 1];
      if face.NumberOfpoints > 2 then begin
        IsNegative:=True;
        for J:=1 to Face.NumberOfpoints do
          if Face.Point[J - 1].Coordinate.Y > 1e-7 then IsNegative:=False;
      end else IsNegative:=True;
      if IsNegative then begin
        Face.Delete;
        Inc(RemovedF);
      end;
    end;
    for I:=FreeShip.Surface.NumberOfControlPoints downto 1 do begin
      Point:=FreeShip.Surface.ControlPoint[I - 1];
      if (Point.NumberOfFaces = 0) and (Point.Coordinate.Y < -1e-4) then begin
        Point.Delete;
        Inc(RemovedP);
      end;
    end;
    if (RemovedF + RemovedP) > 0 then begin
      Str:='';
      if RemovedF > 0 then Str:=Str + IntToStr(RemovedF) + #32 + Userstring(80);
      if RemovedP > 0 then begin
        if Str <> '' then Str:=Str + EOL;
        Str:=Str + IntToStr(RemovedP) + #32 + Userstring(81);
      end;
      MessageDlg(Str, mtInformation, [mbOK], 0);
      vUndo.Accept;
      FreeShip.FileChanged:=True;
      FreeShip.Built:=False;
      Freeship.RebuildModel;
      if Assigned(FreeShip.OnUpdateGeometryInfo) then
        FreeShip.OnUpdateGeometryInfo(self);
    end else begin
      MessageDlg( Userstring(82),mtInformation,[mbOK],0);
      vUndo.Delete;
    end;
//finally
    Screen.Cursor:=PrevCursor;
//end;
end;

// Inverts the normal-direction of all selected controlfaces
procedure TFreeEdit.Face_Flip;
var I: integer;
begin
  CreateUndoObject(Userstring(83), True);
  for I:=1 to FreeShip.NumberOfSelectedControlFaces do
      FreeShip.SelectedControlFace[I-1].FlipNormal;
  FreeShip.Built:=False;
  FreeShip.FileChanged:=True;
  Freeship.RebuildModel;
end;

// Mirrors all selected faces in a 3D plane
procedure TFreeEdit.Face_MirrorPlane;
var
  I, J, Index: integer;
  Vertices: TFasterListTFreeSubdivisionControlPoint;
  Points: TFasterListTFreeSubdivisionControlPoint;
  Faces: TFasterListTFreeSubdivisionControlface;
  MirrorPlane: T3DPlane;
  Face, NewFace: TFreeSubdivisionControlface;
  P1, P2: TFreeSubdivisionControlPoint;
  Edge1, Edge2: TFreeSubdivisionEdge;
  PrevCursor: TCursor;
  Dialog: TFreeMirrorPlaneDialog;
  SelectDlg: TFreeSelectLayersDialog;
begin
  Faces:=TFasterListTFreeSubdivisionControlFace.Create;
  if FreeShip.NumberOfSelectedControlFaces = 0 then begin
    SelectDlg:=TFreeSelectLayersDialog.Create(FreeShip);                      //  ShowTranslatedValues(SelectDlg);
    if SelectDlg.Execute(FFreeShip, fsFaces) then
      SelectDlg.ExtractSelectedFaces(Faces)
    else begin
      for I:=FreeShip.NumberOfSelectedControlFaces downto 1 do
          FreeShip.SelectedControlFace[I-1].Selected:=False;
      Freeship.RebuildModel;
    end;
    FreeAndNil(SelectDlg);
  end else begin
    Faces.Capacity:=Faces.Count + FreeShip.NumberOfSelectedControlFaces;
    for I:=1 to FreeShip.NumberOfSelectedControlFaces do
                Faces.Add(FreeShip.SelectedControlFace[I-1]);
  end;
  if Faces.Count > 0 then begin
    Dialog:=TFreeMirrorPlaneDialog.Create(FreeShip);                          //  ShowTranslatedValues(Dialog);
    if Dialog.Execute then
    begin
      Mirrorplane:=Dialog.Plane;
      CreateUndoObject(Userstring(84), True);
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
//    try                                               // assemble all points
        Vertices:=TFasterListTFreeSubdivisionControlPoint.Create;
        Vertices.Capacity:=4 * Faces.Count;
        for I:=1 to Faces.Count do begin
          Face:=Faces[I - 1];
          for J:=1 to Face.NumberOfpoints do begin
            P1:=Face.Point[J - 1] as TFreeSubdivisionControlPoint;
            if Vertices.SortedIndexOf(P1) = -1 then Vertices.AddSorted(P1);
          end;
        end;                          // Create all the mirrored control points
        for I:=1 to Vertices.Count do begin
          P1:=Vertices[I - 1];
          if not Dialog.CheckBox1.Checked then begin
            // Do NOT try to connect the points to any existing point
            // create always a new point
            P2:=TFreeSubdivisionControlPoint.Create(P1.Surface);
            P1.Surface.AddControlPoint(P2);
            P2.Coordinate:=FreeGeometry.MirrorPlane(P1.Coordinate, MirrorPlane);
          end else P2:=P1.Surface.AddControlPoint(
          FreeGeometry.MirrorPlane(P1.Coordinate, MirrorPlane));
        // Try to connect ALL new points to existing ones
          Vertices.Objects[I - 1]:=P2;
        end;
        // now create the controlfaces
        Points:=TFasterListTFreeSubdivisionControlPoint.Create;
        for I:=1 to Faces.Count do begin
          Face:=Faces[I - 1];
          Points.Clear;
          Points.Capacity:=Face.NumberOfpoints;
          for J:=Face.NumberOfpoints downto 1 do begin
            P1:=Face.Point[J - 1] as TFreeSubdivisionControlPoint;
            Index:=Vertices.SortedIndexOf(P1);
            if Index <> -1 then begin
              P2:=TFreeSubdivisionControlPoint(Vertices.Objects[index]);
              Index:=Points.IndexOf(P2);
              if Index = -1 then Points.Add(P2);
            end;
//          else raise Exception.Create(Userstring(85));
          end;
          if Points.Count > 2 then begin
            NewFace:=Face.Surface.AddControlFace(Points, False);
            if Newface <> nil then NewFace.Layer:=Face.Layer;
          end;
        end;
        FreeAndNil( Points );           // Now check all edges for crease edges
        for I:=1 to Vertices.Count do begin
          P1:=Vertices[I - 1];
          for J:=1 to P1.NumberOfEdges do begin
            Edge1:=P1.Edge[J - 1];
            if Edge1.StartPoint = P1
            then P2:=Edge1.EndPoint as TFreeSubdivisionControlPoint
            else P2:=Edge1.StartPoint as TFreeSubdivisionControlPoint;
            Index:=Vertices.SortedIndexOf(P2);
            if Index <> -1 then begin
              // Edge is part of the selected faces
              Edge2:=FreeShip.Surface.EdgeExists(
                TFreeSubdivisionControlPoint(Vertices.Objects[I - 1]),
                TFreeSubdivisionControlPoint(Vertices.Objects[index]));
              if (Edge2 <> nil) and (Edge2 <> Edge1) then
                Edge2.Crease:=Edge1.Crease;
            end;
          end;
        end;
        // Copy cornerpoint and locked ststus that might be lost in the edge-setting process
        for I:=1 to Vertices.Count do
        begin
          P1:=Vertices[I - 1];
          P2:=TFreeSubdivisionControlPoint(Vertices.Objects[I - 1]);
          if P2 <> P1 then begin
            if P1.VertexType = svCorner then P2.VertexType:=P1.VertexType;
            P2.Locked:=P1.Locked;
          end;
        end;
        FreeAndNil(Vertices);
        for I:=FreeShip.NumberOfSelectedControlFaces downto 1 do
          FreeShip.SelectedControlFace[I - 1].Selected:=False;
//    finally
        FreeShip.Built:=False;
        FreeShip.Draw;
        if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
        Screen.Cursor:=PrevCursor;
//    end;
    end;
    FreeAndNil(Dialog);
  end;
  FreeAndNil(Faces);
end;

procedure TFreeEdit.Face_Rotate;
var
  I, J, Nlocked: integer;
  Points: TFasterListTFreeSubdivisionControlPoint;
  PrevCursor: TCursor;
  SelectDlg: TFreeSelectLayersDialog;
  Point: TFreeSubdivisionControlPoint;
  Proceed: boolean;
  Dialog: TFreeRotateDialog;
  SinX, CosX: TFloatType;
  SinY, CosY: TFloatType;
  SinZ, CosZ: TFloatType;
  Marker: TFreeMarker;
begin
  Points:=TFasterListTFreeSubdivisionControlPoint.Create;
  if FreeShip.ActiveControlPoint <> nil then
    Points.Add(FreeShip.ActiveControlPoint);
  FreeShip.Surface.ExtractPointsFromSelection( Points,NLocked );
  if Points.Count = 0 then begin
    SelectDlg:=TFreeSelectLayersDialog.Create(FreeShip); // ShowTranslatedValues(SelectDlg);
    if SelectDlg.Execute( FFreeShip,fsPoints ) then
       SelectDlg.ExtractSelectedPoints(Points)
    else begin
      for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do FreeShip.SelectedControlPoint[I-1].Selected:=False;
      for I:=1 to FreeShip.NumberOfViewports do FreeShip.Viewport[I-1].Refresh;
    end;
    FreeAndNil(SelectDlg);
  end;
  if Points.Count>0 then begin
    if NLocked > 0 then
      Proceed:=MessageDlg(Userstring(86)+EOL+Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes
    else Proceed:=True;
    if Proceed then begin
      Dialog:=TFreeRotateDialog.Create( FreeShip ); // ShowTranslatedValues(Dialog);
      Dialog.Caption:='Rotate selected items.';  // ShowTranslatedValues(Dialog);
      Dialog.XValue:=0.0;
      Dialog.YValue:=0.0;
      Dialog.ZValue:=0.0;
      if Dialog.Execute('[°]') then begin
        CreateUndoObject( 'rotate', True);
        PrevCursor:=Screen.Cursor;
        Screen.Cursor:=crHourGlass;
//      try
          CosX:=Cos(DegToRad(Dialog.XValue));
          SinX:=Sin(DegToRad(Dialog.XValue));
          CosY:=Cos(DegToRad(Dialog.YValue));
          SinY:=Sin(DegToRad(Dialog.YValue));
          CosZ:=Cos(DegToRad(Dialog.ZValue));
          SinZ:=Sin(DegToRad(Dialog.ZValue));
          for I:=1 to Points.Count do begin
            Point:=Points[I - 1];
            if not Point.Locked then
              Point.Coordinate:=RotateVector(Point.Coordinate,SinX,CosX,SinY,CosY,SinZ,CosZ);
          end;
          if Points.Count = FreeShip.Surface.NumberOfControlPoints then
          if FreeShip.AdjustMarkers then
           for I:=1 to FreeShip.NumberofMarkers do begin
             Marker:=FreeShip.Marker[I-1];
             for J:=1 to Marker.NumberOfPoints do
               Marker.Point[J-1]:=RotateVector(Marker.Point[J-1],SinX,CosX,SinY,CosY,SinZ,CosZ);
          end;
          FreeShip.Built:=False;
          Freeship.RebuildModel;
//      finally                                    // Refresh controlpoint data
          if Points.SortedIndexOf(FreeShip.ActiveControlPoint)<>-1
             then FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
          Screen.Cursor:=PrevCursor;
//      end;
      end else begin
        for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
          FreeShip.SelectedControlPoint[I-1].Selected:=False;
        for I:=1 to FreeShip.NumberOfViewports do FreeShip.Viewport[I-1].Refresh;
      end;
      FreeAndNil(Dialog);
    end else begin
      for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
        FreeShip.SelectedControlPoint[I-1].Selected:=False;
      for I:=1 to FreeShip.NumberOfViewports do FreeShip.Viewport[I-1].Refresh;
    end;
  end;
  FreeAndNil(Points);
end;

procedure TFreeEdit.Face_RotateM;
var
  I,J,Nlocked: integer;
  Points: TFasterListTFreeSubdivisionControlPoint;
  PrevCursor: TCursor;
  Point: TFreeSubdivisionControlPoint;
  Dialog: TFreeRotateDialog;
  SinX, CosX: TFloatType;
  SinY, CosY: TFloatType;
  SinZ, CosZ: TFloatType;
  Marker: TFreeMarker;
begin
  Points:=TFasterListTFreeSubdivisionControlPoint.Create;
  if FreeShip.ActiveControlPoint<>nil then
     Points.Add( FreeShip.ActiveControlPoint );
  for I:=1 to FreeShip.NumberOfLayers do
    for J:=1 to FreeShip.Surface.NumberOfControlPoints do
      FreeShip.Surface.ControlPoint[J-1].Selected:=True;
  Freeship.RebuildModel;
  FreeShip.Surface.ExtractPointsFromSelection(Points,NLocked);
  if Points.Count>0 then begin
    Dialog:=TFreeRotateDialog.Create( FreeShip );
    Dialog.Caption:='Heeling and/or trimming all model items.';  // ShowTranslatedValues(Dialog);
    Dialog.XValue:=0.0;
    Dialog.YValue:=0.0;
    Dialog.ZValue:=0.0;
    if Dialog.Execute('[°]') then begin
      CreateUndoObject('rotate',True);
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourGlass;
//    try
        CosX:=Cos(DegToRad(Dialog.XValue));
        SinX:=Sin(DegToRad(Dialog.XValue));
        CosY:=Cos(DegToRad(Dialog.YValue));
        SinY:=Sin(DegToRad(Dialog.YValue));
        CosZ:=Cos(DegToRad(Dialog.ZValue));
        SinZ:=Sin(DegToRad(Dialog.ZValue));
        for I:=1 to Points.Count do begin
          Point:=Points[I-1];
          if not Point.Locked then
            Point.Coordinate:=RotateVector(Point.Coordinate,SinX,CosX,SinY,CosY,SinZ,CosZ);
        end;
        if Points.Count = FreeShip.Surface.NumberOfControlPoints then
          if FreeShip.AdjustMarkers then
            for I:=1 to FreeShip.NumberofMarkers do begin
              Marker:=FreeShip.Marker[I - 1];
              for J:=1 to Marker.NumberOfPoints do
                Marker.Point[J-1]:=RotateVector(Marker.Point[J-1],SinX,CosX,SinY,CosY,SinZ,CosZ);
            end;
        FreeShip.Built:=False;
        Freeship.RebuildModel;
//    finally                                      // Refresh controlpoint data
        if Points.SortedIndexOf(FreeShip.ActiveControlPoint)<>-1 then
           FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
        Screen.Cursor:=PrevCursor;
//    end;
    end else begin
      for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
        FreeShip.SelectedControlPoint[I - 1].Selected:=False;
      for I:=1 to FreeShip.NumberOfViewports do
        FreeShip.Viewport[I - 1].Refresh;
    end;
       FreeAndNil(Dialog);
  end; FreeAndNil(Points);
end;

procedure TFreeEdit.Face_Scale;
var
  I: integer;
  Nlocked: integer;
  Points: TFasterListTFreeSubdivisionControlPoint;
  PrevCursor: TCursor;
  SelectDlg: TFreeSelectLayersDialog;
  Point: TFreeSubdivisionControlPoint;
  Proceed: boolean;
  Dialog: TFreeRotateDialog;
  Scale, NewP: T3DCoordinate;
  Markers: boolean;
begin
  Points:=TFasterListTFreeSubdivisionControlPoint.Create;
  if FreeShip.ActiveControlPoint <> nil then
    Points.Add(FreeShip.ActiveControlPoint);
  FreeShip.Surface.ExtractPointsFromSelection(Points, NLocked);
  if Points.Count = 0 then begin
    SelectDlg:=TFreeSelectLayersDialog.Create(FreeShip);                      //  ShowTranslatedValues(SelectDlg);
    if SelectDlg.Execute(FFreeShip, fsPoints) then
      SelectDlg.ExtractSelectedPoints(Points)
    else begin
      for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
          FreeShip.SelectedControlPoint[I-1].Selected:=False;
      for I:=1 to FreeShip.NumberOfViewports do
          FreeShip.Viewport[I-1].Refresh;
    end;
    FreeAndNil(SelectDlg);
  end;
  if Points.Count > 0 then begin
    if NLocked > 0 then
      Proceed:=MessageDlg(Userstring(86)+EOL+Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes
    else Proceed:=True;
    if Proceed then begin
      Dialog:=TFreeRotateDialog.Create(FreeShip);
      Dialog.Caption:='Scale selected items.';                                                //    //ShowTranslatedValues(Dialog);
      Dialog.XValue:=1.0;
      Dialog.YValue:=1.0;
      Dialog.ZValue:=1.0;
      if Dialog.Execute( 'scale') then begin
        CreateUndoObject(Userstring(91), True);
        PrevCursor:=Screen.Cursor;
        Screen.Cursor:=crHourGlass;
//      try
          Scale.X:=Dialog.XValue;
          Scale.Y:=Dialog.YValue;
          Scale.Z:=Dialog.ZValue;
          if Points.Count = FreeShip.Surface.NumberOfControlPoints then begin // Scale the entire model
            Markers:=FreeShip.AdjustMarkers;
            Model_Scale(Scale, False, Markers);
          end else begin                                // only a selected part of the model must be scaled
            for I:=1 to Points.Count do begin
              Point:=Points[I - 1];
              if not Point.Locked then begin
                NewP.X:=Scale.X * Point.Coordinate.X;
                NewP.Y:=Scale.Y * Point.Coordinate.Y;
                NewP.Z:=Scale.Z * Point.Coordinate.Z;
                Point.Coordinate:=NewP;
              end;
            end;
            FreeShip.Built:=False;
            Freeship.RebuildModel;
          end;
//      finally                                    // Refresh controlpoint data
          if Points.SortedIndexOf(FreeShip.ActiveControlPoint) <> -1 then
            FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
          Screen.Cursor:=PrevCursor;
//      end;
      end else begin
        for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
          FreeShip.SelectedControlPoint[I-1].Selected:=False;
        for I:=1 to FreeShip.NumberOfViewports do
          FreeShip.Viewport[I-1].Refresh;
      end;
      FreeAndNil(Dialog);
    end else begin
      for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
        FreeShip.SelectedControlPoint[I-1].Selected:=False;
      for I:=1 to FreeShip.NumberOfViewports do
        FreeShip.Viewport[I-1].Refresh;
    end;
  end;
  FreeAndNil(Points);
end;

procedure TFreeEdit.Face_Move;
var
  I,J: integer;
  Nlocked: integer;
  Points: TFasterListTFreeSubdivisionControlPoint;
  PrevCursor: TCursor;
  SelectDlg: TFreeSelectLayersDialog;
  Point: TFreeSubdivisionControlPoint;
  Proceed: boolean;
  Dialog: TFreeRotateDialog;
  P, Translate: T3DCoordinate;
  Marker: TFreeMarker;
begin
  Points:=TFasterListTFreeSubdivisionControlPoint.Create;
  if FreeShip.ActiveControlPoint <> nil then
    Points.Add(FreeShip.ActiveControlPoint);
  FreeShip.Surface.ExtractPointsFromSelection(Points, NLocked);
  if Points.Count = 0 then begin
    SelectDlg:=TFreeSelectLayersDialog.Create(FreeShip);                      //  ShowTranslatedValues(SelectDlg);
    if SelectDlg.Execute(FFreeShip, fsPoints) then
      SelectDlg.ExtractSelectedPoints(Points)
    else begin
      for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
        FreeShip.SelectedControlPoint[I-1].Selected:=False;
      for I:=1 to FreeShip.NumberOfViewports do
        FreeShip.Viewport[I-1].Refresh;
    end;
    FreeAndNil(SelectDlg);
  end;
  if Points.Count > 0 then begin
    if NLocked > 0 then
      Proceed:=MessageDlg(Userstring(86)+EOL+Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes
    else Proceed:=True;
    if Proceed then begin
      Dialog:=TFreeRotateDialog.Create(FreeShip);
      Dialog.Caption:= 'Move the entire model.'; // ShowTranslatedValues(Dialog);
      Dialog.XValue:=0.0;
      Dialog.YValue:=0.0;
      Dialog.ZValue:=0.0;
      if Dialog.Execute( LengthStr( FreeShip.ProjectSettings.ProjectUnits)) then begin
//    if Dialog.Execute( '[m]' ) then begin
        CreateUndoObject(Userstring(93), True);
        Translate.X:=Dialog.XValue;
        Translate.Y:=Dialog.YValue;
        Translate.Z:=Dialog.ZValue;
        PrevCursor:=Screen.Cursor;
        Screen.Cursor:=crHourGlass;
//      try
          for I:=1 to Points.Count do begin
            Point:=Points[I - 1];
            if not Point.Locked then begin
              P:=Point.Coordinate;
              P.X:=P.X + Translate.X;
              P.Y:=P.Y + Translate.Y;
              P.Z:=P.Z + Translate.Z;
              Point.Coordinate:=P;
            end;
          end;
          if Points.Count=FreeShip.Surface.NumberOfControlPoints then begin       // Update main dimensions
            if not FreeShip.ProjectSettings.FUseDefaultSplitSectionLocation then
              FreeShip.ProjectSettings.ProjectSplitSectionLocation :=
                FreeShip.ProjectSettings.ProjectSplitSectionLocation+Translate.X; // Update stations, buttcks and waterlines
            for I:=1 to FreeShip.NumberofStations do
              FreeShip.Station[I - 1].FPlane.d:=FreeShip.Station[I - 1].FPlane.d - Translate.X;
            for I:=1 to FreeShip.NumberofButtocks do
              FreeShip.Buttock[I - 1].FPlane.d:=FreeShip.Buttock[I - 1].FPlane.d - Translate.Y;
            for I:=1 to FreeShip.NumberofWaterlines do
              FreeShip.Waterline[I - 1].FPlane.d:=FreeShip.Waterline[I - 1].FPlane.d - Translate.Z;
            // Update markers
            if FreeShip.AdjustMarkers then
              for I:=1 to FreeShip.NumberofMarkers do begin
                Marker:=FreeShip.Marker[I - 1];
                for J:=1 to Marker.NumberOfPoints do begin
                  P:=Marker.Point[J - 1];
                  P.X:=P.X + Translate.X;
                  P.Y:=P.Y + Translate.Y;
                  P.Z:=P.Z + Translate.Z;
                  Marker.Point[J - 1]:=P;
                end;
              end;
          end;
          FreeShip.Built:=False;
          Freeship.RebuildModel;
//      finally                                    // Refresh controlpoint data
          if Points.SortedIndexOf(FreeShip.ActiveControlPoint) <> -1 then
            FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
          Screen.Cursor:=PrevCursor;
//      end;
      end else begin
        for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
          FreeShip.SelectedControlPoint[I-1].Selected:=False;
        for I:=1 to FreeShip.NumberOfViewports do
          FreeShip.Viewport[I-1].Refresh;
      end;
      FreeAndNil(Dialog);
    end else begin
      for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
        FreeShip.SelectedControlPoint[I-1].Selected:=False;
      for I:=1 to FreeShip.NumberOfViewports do
        FreeShip.Viewport[I-1].Refresh;
    end;
  end;
  FreeAndNil(Points);
end;{TFreeEdit.Face_Move}

// Creates a new controlface from the currently selected controlpoints

procedure TFreeEdit.Face_New;
var
  Tmp: TFasterListTFreeSubdivisionControlPoint;
  Face: TFreeSubdivisionControlFace;
  I: integer;
  vUndo: TFreeUndoObject;
begin
  if FreeShip.NumberOfSelectedControlPoints > 2 then
  begin
    Tmp:=TFasterListTFreeSubdivisionControlPoint.Create;
    vUndo:=CreateUndoObject(Userstring(94), False);

    FreeShip.Surface.ClearMesh;

    // Remember the number of faces, edges and points
    // Assemble all points in a temp. list
    for I:=1 to FreeShip.Surface.NumberOfSelectedControlPoints do
      Tmp.Add(FreeShip.Surface.SelectedControlPoint[I - 1]);
    // Deselect the controlpoints
    for I:=FreeShip.Surface.NumberOfSelectedControlPoints downto 1 do
      FreeShip.Surface.SelectedControlPoint[I - 1].Selected:=False;
    // Add the new face
    Face:=FreeShip.Surface.AddControlFace(Tmp, True, FreeShip.ActiveLayer);
    if Face <> nil then begin
      vUndo.Accept;
      FreeShip.Built:=False;
      FreeShip.RebuildModel;
      FreeShip.FileChanged:=True;
      Freeship.RebuildModel;
      if Assigned(FreeShip.OnUpdateGeometryInfo) then
        FreeShip.OnUpdateGeometryInfo(self);
    end else vUndo.Delete;               // Initialize then new edges and faces
    FreeAndNil(Tmp);
  end
  else
    MessageDlg(Userstring(95), mtInformation, [mbOK], 0);
end;{TFreeEdit.Face_New}

procedure TFreeEdit.File_ExportArchimedes;
var
  Frames: TFasterListTFreeSpline;
  Frame: TFreeSpline;
  Tmp, Str: string;
  I, J, Np: integer;
  P: T3DCoordinate;
  SaveDialog: TSaveDialog;
  ffile: textfile;
  Strings: TStringList;
begin
  if not FreeShip.ProjectSettings.FMainparticularsHasBeenset then begin
     MessageDlg(Userstring(95), mtWarning, [mbOK], 0);
     exit;
  end;
  Frames:=TFasterListTFreeSpline.Create;
  FreeShip.FBuildValidFrameTable(Frames, True);
  if Frames.Count > 0 then begin
    SaveDialog:=TSaveDialog.Create(FreeShip);
    SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
    SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '');
    SaveDialog.Filter :=
      createDialogFilter(rsArchimedesMBMultiBodyHullData, ['hll'], False)
      + '|' + createDialogFilter(rsArchimedesSingleBodyHullData, ['app']);
    SaveDialog.FilterIndex:=1;
    Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
    if SaveDialog.Execute then begin WestPoint;
      FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      if SaveDialog.FilterIndex = 2 then begin
        // Single body Archimedes
        assignfile(ffile, ChangeFileExt(SaveDialog.FileName, '.app'));
        rewrite(FFile);
        Write(FFile,
        '***************************************************************'+#10+
        '**                                                           **'+#10+
        '**     Appendage Hydrostatics Generator                      **'+#10+
        '**     Version 1.0.1                                         **'+#10+
        '**     Copyright : John A. MacSween - 2000                   **'+#10+
        '**     Please visit the website for updates and new versions **'+#10+
        '**                                                           **'+#10+
        '**                 www.naval-architecture.co.uk              **'+#10+
        '** File generated with FREE!ship                             **'+#10+
        '***************************************************************'+#10);
        // Hull name
        Write(FFile, 'APPENDAGE_NAME' + #10);
        if FreeShip.ProjectSettings.ProjectName <> ''
          then Tmp:=FreeShip.ProjectSettings.ProjectName
          else Tmp:=ChangeFileExt(ExtractFilename(FreeShip.Filename), '');
        Write(FFile, Tmp + #10);
        // Aft perpendicular
        Write(FFile, 'AP' + #10);
        Write(FFile, '0.0' + #10);
        // Forward perpendicular
        Write(FFile, 'FP' + #10);
        Write(FFile, FloatToDec(FreeShip.ProjectSettings.ProjectLength, 4) + #10);
        // Water density
        Write(FFile, 'DENSITY' + #10);
        Write(FFile, FloatToDec(FreeShip.ProjectSettings.ProjectWaterDensity, 3) + #10);
        // Now send the frames
        Write(FFile, 'NUMBER_OF_FRAMES' + #10);
        Write(FFile, IntToStr(Frames.Count) + #10);
        Write(FFile, '***START_OF_FRAME_INFORMATION***' + #10);
        for I:=1 to Frames.Count do begin
          Frame:=Frames[I - 1];
          Np:=Frame.NumberOfPoints;
          Write(FFile, 'FRAME_INDEX: ' + IntToStr(I - 1) + #10);
          Write(FFile, 'FRAME_NAME' + #10);
          Write(FFile, 'Frame @ Y= ' + FloatToStrF(0.5 * (Frame.Min.X + Frame.Max.X), ffFixed, 7, 4) + #10);
          Write(FFile, 'FRAME_Y' + #10);
          Write(FFile, FloatToStrF(0.5 * (Frame.Min.X + Frame.Max.X),ffFixed, 7, 4) + #10);
          Write(FFile, 'NUMBER_OF_COORDINATES' + #10);
          Write(FFile, IntToStr(2 * Np - 1) + #10);
          Write(FFile, '***START_OF_ORDINATES***' + #10);

          // First send the starboard side
          for J:=Np downto 1 do begin
            //P:=Frame.Value((J-1)/(Np-1));
            P:=Frame.Point[J - 1];
            P.Y:=-P.Y;
            Write(FFile, FloatToDec(P.Y, 4) + #10);
            Write(FFile, FloatToDec(P.Z, 4) + #10);
          end;
          // then port side
          for J:=2 to Np do begin
            //P:=Frame.Value((J-1)/(Np-1));
            P:=Frame.Point[J - 1];
            Write(FFile, FloatToDec(P.Y, 4) + #10);
            Write(FFile, FloatToDec(P.Z, 4) + #10);
          end;
          Write(FFile, '***END_OF_ORDINATES***' + #10);
          FreeAndNil(Frame);
        end;
        Write(FFile, '***END_OF_FILE***' + #10);
        closefile(FFile);
      end
      else
      begin
        // Multi body ArchimedesMB
        Strings:=TStringList.Create;
        // Add file version info
        Strings.Add(' <?xml version="1.0" encoding="UTF-8" ?>');
        // Start hull
        Strings.Add('<HULL>');
        // Hull name
        Strings.Add('<HULL_NAME>');
        if FreeShip.ProjectSettings.ProjectName <> '' then
          Str:=FreeShip.ProjectSettings.ProjectName
        else
          Str:=ChangeFileExt(ExtractFilename(FreeShip.Filename), '');
        Strings.Add(Str);
        Strings.Add('</HULL_NAME>');
        // Water density
        Strings.Add('<DENSITY>' + #32 + FloatToDec(
          FreeShip.ProjectSettings.ProjectWaterDensity, 3) + #32 + '</DENSITY>');
        // Aft perpendicular
        Strings.Add('<AP> 0.0 </AP>');
        // Forward perpendicular
        Strings.Add('<FP>' + #32 + FloatToDec(FreeShip.ProjectSettings.ProjectLength, 4) +
          #32 + '</FP>');
        // Draught marks
        Strings.Add('<FWD_DRAUGHT_MARK>' + #32 + FloatToDec(
          FreeShip.ProjectSettings.ProjectDraft, 4) + #32 + '</FWD_DRAUGHT_MARK>');
        Strings.Add('<MID_DRAUGHT_MARK>' + #32 + FloatToDec(
          FreeShip.ProjectSettings.ProjectDraft, 4) + #32 + '</MID_DRAUGHT_MARK>');
        Strings.Add('<AFT_DRAUGHT_MARK>' + #32 + FloatToDec(
          FreeShip.ProjectSettings.ProjectDraft, 4) + #32 + '</AFT_DRAUGHT_MARK>');
        // Number of appendages (only 1, the main hull)
        Strings.Add('<APPENDAGE_COUNT> 1 </APPENDAGE_COUNT>');
        Strings.Add('<APPENDAGE>');
        Strings.Add('<APPENDAGE_NAME>');
        Strings.Add('Main Hull');
        Strings.Add('</APPENDAGE_NAME>');
        // Some constants
        Strings.Add('<ACTIVE> 1 </ACTIVE>');
        Strings.Add('<FREE_FLOODING> 0 </FREE_FLOODING>');
        Strings.Add('<APPENDAGE_COLOUR> 0 </APPENDAGE_COLOUR>');

        // Now send the frames
        Strings.Add('<SECTION_COUNT>' + #32 + IntToStr(Frames.Count) +
          #32 + '</SECTION_COUNT>');
        for I:=1 to Frames.Count do
        begin
          Frame:=Frames[I - 1];
          Np:=2 * Frame.NumberOfPoints + 1;
          Strings.Add('<SECTION>');
          Strings.Add('<SECTION_NAME>');
          Strings.Add(FloatToStrF(0.5 * (Frame.Min.X + Frame.Max.X), ffFixed, 7, 4));
          Strings.Add('</SECTION_NAME>');
          Strings.Add('<YCOORD>' + #32 + FloatToStrF(0.5 * (Frame.Min.X + Frame.Max.X), ffFixed, 7, 4) + #32 + '</YCOORD>');
          Strings.Add('<OFFSET_COUNT>' + #32 + IntToStr(2 * Np - 1) +
            #32 + '</OFFSET_COUNT>');
          Strings.Add('<OFFSETS>');
          // First send the starboard side
          for J:=Np downto 1 do begin
            P:=Frame.Value((J - 1) / (Np - 1));
            P.Y:=-P.Y;
            Strings.Add(FloatToDec(P.Y, 4) + #32 + FloatToDec(P.Z, 4));
          end;
          // then port side
          for J:=2 to Np do begin
            P:=Frame.Value((J - 1) / (Np - 1));
            Strings.Add(FloatToDec(P.Y, 4) + #32 + FloatToDec(P.Z, 4));
          end;
          Strings.Add('</OFFSETS>');
          Strings.Add('</SECTION>');
          FreeAndNil(Frame);
        end;
        Strings.Add('</APPENDAGE>');  // end of appendage
        Strings.Add('</HULL>');       // end of hull
        Strings.SaveToFile(ChangeFileExt(SaveDialog.FileName, '.hll'));
        FreeAndNil(Strings);
      end;
    end else
      for I:=1 to Frames.Count do begin
        Frame:=Frames[I - 1];
        FreeAndNil(Frame);
      end;
    FreeAndNil(SaveDialog);
  end;
  FreeAndNil(Frames);
end;{TFreeEdit.File_ExportArchimedes}

// export the coordinates of all controlpoints to a textfile
procedure TFreeEdit.File_ExportCoordinates;
var
  I: integer;
  Point: TFreeSubdivisionPoint;
  SaveDialog: TSaveDialog;
  ffile: textfile;
begin
  SaveDialog:=TSaveDialog.Create(FreeShip);
  SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '');
  SaveDialog.Filter:=createDialogFilter(rsTextFile,['txt']);
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if SaveDialog.Execute then begin WestPoint;
    Assignfile(FFile, ChangeFileExt(SaveDialog.FileName, '.txt'));
      {$I-}
    Rewrite(FFile);
{$I+}
    if IOResult=0 then begin
      FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
         {
         for I:=1 to FreeShip.Surface.NumberOfControlPoints do
         begin
            Point:=FreeShip.Surface.ControlPoint[I-1];
            Writeln(FFile,MakeLength(Point.Coordinate.X,6,12),#32,
                          MakeLength(Point.Coordinate.Y,6,12),#32,
                          MakeLength(Point.Coordinate.Z,6,12));
         end;
         }
      //         MessageDlg(FloatToStrF(FreeShip.Surface.NumberOfControlPoints,ffFixed,6,0),mtError,[mbOk],0);
      //         MessageDlg(FloatToStrF(FreeShip.Surface.NumberOfPoints,ffFixed,6,0),mtError,[mbOk],0);
      for I:=1 to FreeShip.Surface.NumberOfSubDivPoints do begin
        Point:=FreeShip.Surface.SubDivPoint[I - 1];
        Writeln(FFile, MakeLength(Point.Coordinate.X, 6, 12), #32,
          MakeLength(Point.Coordinate.Y, 6, 12), #32,
          MakeLength(Point.Coordinate.Z, 6, 12));
      end;
      CloseFile(FFile);
    end else MessageDlg(Userstring(97), mtError, [mbOK], 0);
  end;
  FreeAndNil(SaveDialog);

end;{TFreeEdit.File_ExportCoordinates}

// Export all intersections to an individual DXF file as 2D polylines
procedure TFreeEdit.File_ExportDXF_2DPolylines;
var
  I: integer;
  Strings: TStringList;
  Dialog: TDXFExport2DDialog;
  ScaleFactor: double;
  SegLength: double;
  PrevCursor: TCursor;
  Filename, Layername: string;
  Intersections: TFasterListTFreeIntersection;
  CreateIndividualLayers: Boolean;

  function getLayerName(IntersectionType:TFreeIntersectionType):String;
  begin
    Result:='';
    case IntersectionType of
      fiStation:      Result:=Userstring(62);
      fiButtock:      Result:=Userstring(63);
      fiWaterline:    Result:=Userstring(64);
      fiDiagonal:     Result:=Userstring(65);
      else begin
        Messagedlg(Userstring(66) + '!', mtError, [mbOK], 0); exit;
      end;
    end;
  end;
  procedure DefineLayers(Stringlist: TStringList; LayerPrefix:string;
    StartLayer,LayerNumbers:integer);
  var I:integer;
  begin
    Stringlist.add('0');
    Stringlist.add('SECTION');
    Stringlist.add('2');
    Stringlist.add('TABLES');
    Stringlist.add('0');
    Stringlist.add('TABLE');
    Stringlist.add('2');
    Stringlist.add('LTYPE');
    Stringlist.add('70');
    Stringlist.add('1');
    Stringlist.add('0');
    Stringlist.add('LTYPE');
    Stringlist.add('2');
    Stringlist.add('CONTINUOUS');
    Stringlist.add('70');
    Stringlist.add('64');
    Stringlist.add('3');
    Stringlist.add('Solid line');
    Stringlist.add('72');
    Stringlist.add('65');
    Stringlist.add('73');
    Stringlist.add('0');
    Stringlist.add('40');
    Stringlist.add('0.000000');
    Stringlist.add('0');
    Stringlist.add('ENDTAB');

    Stringlist.add('0');
    Stringlist.add('TABLE');
    Stringlist.add('2');
    Stringlist.add('LAYER');
    Stringlist.add('70');
    Stringlist.add('6');
    for I:=StartLayer to LayerNumbers do begin
      Stringlist.add('0');
      Stringlist.add('LAYER');
      Stringlist.add('2');
      Stringlist.add( format(LayerPrefix+'%.2d', [I]) );
      Stringlist.add('70');
      Stringlist.add('64');
      Stringlist.add('62');
      Stringlist.add('7');
      Stringlist.add('6');
      Stringlist.add('CONTINUOUS');
    end;
    Stringlist.add('0');
    Stringlist.add('ENDTAB');
    Stringlist.add('0');
    Stringlist.add('TABLE');
    Stringlist.add('2');
    Stringlist.add('STYLE');
    Stringlist.add('70');
    Stringlist.add('0');
    Stringlist.add('0');
    Stringlist.add('ENDTAB');
    Stringlist.add('0');
    Stringlist.add('ENDSEC');
  end;

  procedure CreateDXFData(Intersection: TFreeIntersection; IntersectionNumber:integer;
    Stringlist: TStringList; Scale: double; var Filename: string);
  var
    I, N: integer;
    Layername: string;

    procedure SaveSpline(Spline: TFreeSpline; Strings: TStringList;
      IntersectionType: TFreeIntersectiontype);
    var
      NParams: integer;
      Cap: integer;
      Params: TFloatArray;
      I, Ind: integer;
      SplineLength: double;
      T: double;
      P1, P2, Pkn: T3DCoordinate;
      Pn, Pn1, Pn2: integer;
      SplineValues: T3DCoordinateArray;

      procedure SaveVertex(P:T3DCoordinate); // port side
      begin
        Strings.Add('0' + EOL + 'VERTEX');
        Strings.Add('8' + EOL + LayerName);
        case IntersectionType of
          fiStation:
          begin
            Strings.Add('10' + EOL + FloatToDec(Scale * P.Y, 5));
            Strings.Add('20' + EOL + FloatToDec(Scale * P.Z, 5));
          end;
          fiButtock:
          begin
            Strings.Add('10' + EOL + FloatToDec(Scale * P.X, 5));
            Strings.Add('20' + EOL + FloatToDec(Scale * P.Z, 5));
          end;
          fiWaterline:
          begin
            Strings.Add('10' + EOL + FloatToDec(Scale * P.X, 5));
            Strings.Add('20' + EOL + FloatToDec(Scale * P.Y, 5));
          end;
        end;
      end;
      procedure SaveVertexSB(P:T3DCoordinate); // starboard side
      begin
        Strings.Add('0' + EOL + 'VERTEX');
        Strings.Add('8' + EOL + LayerName);
        case IntersectionType of
          fiStation: begin
            Strings.Add('10' + EOL + FloatToDec(Scale * -P.Y, 5));
            Strings.Add('20' + EOL + FloatToDec(Scale * P.Z, 5)); end;
          fiWaterline: begin
            Strings.Add('10' + EOL + FloatToDec(Scale * P.X, 5));
            Strings.Add('20' + EOL + FloatToDec(Scale * -P.Y, 5)); end;
        end;
      end;
    begin
      Ind:=FindDXFColorIndex(Spline.Color);
      NParams:=0;
      Setlength(Params, Spline.NumberOfPoints);
      // count number of knucklepoints
      //if not Spline.Built then
      Spline.Rebuild;
      for I:=2 to Spline.NumberOfPoints - 1 do
        if Spline.Knuckle[I - 1] then
        begin
          Params[NParams]:=Spline.Parameter[I - 1];
          Inc(NParams);
        end;

      (* // Calculate the SplineLength of the spline
      SplineLength:=0.0;
      P1:=Spline.Value(0.0);
      for I:=1 to 150 do
      begin
        P2:=Spline.Value(I / 150);
        SplineLength:=SplineLength + DistPP3D(P1, P2);
        P1:=P2;
      end;  *)
      SplineLength:=Spline.TotalLength;
      SplineLength:=SplineLength * ScaleFactor;


      if SplineLength > 0 then begin
        N:=Round(SplineLength / (SegLength));
        if N < 2*Spline.NumberOfPoints then N:=2*Spline.NumberOfPoints;
        if N > 3500 then N:=3500;
        Spline.Fragments:=N;
        (*
        Cap:=NParams + 100;
        Setlength(Params, Cap);
        Inc(Nparams);
        Params[NParams - 1]:=0.0;
        Inc(Nparams);
        Params[NParams - 1]:=1.0;

        for I:=1 to Spline.Fragments do
        begin
          T:=Spline.ChordlengthApproximation(I * SegLength / SplineLength);
          if NParams >= Cap then
          begin
            Inc(Cap, 50);
            Setlength(Params, Cap);
          end;
          Inc(NParams);
          Params[NParams - 1]:=T;
        end;

        SortFloatArray(Params, NParams);
        *)

        // now export the actual calculated points
        Strings.Add('0' + EOL + 'POLYLINE');
        Strings.Add('8' + EOL + LayerName);   // layername
        Strings.Add('62' + EOL + IntToStr(Ind));  // color by layer
        Strings.Add('66' + EOL + '1');    // vertices follow
        (*
        Pn:=0;
        for I:=0 to NParams - 1 do
        begin
          P1:=Spline.Value(Params[I], Pn1, Pn2);
          if (Pn <> Pn1) and Spline.Knuckle[Pn1] then
          begin
            Pn:=Pn1;
            Pkn:=Spline.Point[Pn1];
            SaveVertex(Pkn);
          end;
          SaveVertex(P1);
        end;
        *)
        //MM: 2020-06-12 just use GetValues. no tricks. Knuckle processing is embedded there.
        SplineValues:=Spline.GetValues;
        for i:=0 to Length(SplineValues)-1 do begin
          P1:=SplineValues[i];
          SaveVertex(P1);
        end;

        Strings.Add('0' + EOL + 'SEQEND');
        if (Intersectiontype in [fiStation,fiWaterline]) and
           (FreeShip.Visibility.ModelView=mvBoth) then begin // send the other half
          Strings.Add('0' + EOL + 'POLYLINE');
          Strings.Add('8' + EOL + LayerName);                // layername
          Strings.Add('62' + EOL + IntToStr(Ind));           // color by layer
          Strings.Add('66' + EOL + '1');                     // vertices follow
          (*
          Pn:=0;
          for I:=0 to NParams - 1 do
          begin
            P1:=Spline.Value(Params[I], Pn1, Pn2);
            if (Pn <> Pn1) and Spline.Knuckle[Pn1] then
            begin
              Pn:=Pn1;
              Pkn:=Spline.Point[Pn1];
              SaveVertexSB(Pkn);
            end;
            SaveVertexSB(P1);
          end;
          *)
          for i:=0 to Length(SplineValues)-1 do begin
            P1:=SplineValues[i];
            SaveVertexSB(P1);
          end;

          Strings.Add('0' + EOL + 'SEQEND');
        end;
      end;
    end;{SaveSpline}

  begin
    //if not Intersection.Built then
    Intersection.Rebuild;
    if intersection.Count > 0 then
    begin
      Layername:=getLayerName(Intersection.IntersectionType);
      if CreateIndividualLayers then
        Layername:=format(Layername+'%.2d',[IntersectionNumber]);
      Filename:=FreeShip.Preferences.ExportDirectory + Intersection.Description + '.dxf';
      for I:=1 to Intersection.Count do
      begin
        Intersection.Items[I - 1].Color:=Intersection.Color;
        SaveSpline(Intersection.Items[I - 1], Strings, Intersection.IntersectionType);
      end;
    end;
  end;

begin
  Dialog:=TDXFExport2DDialog.Create(FreeShip);                                //ShowTranslatedValues(Dialog);
  Dialog.ExportDirectory:=FreeShip.Preferences.ExportDirectory;
  if FreeShip.ProjectSettings.ProjectUnits = fuMetric then
    Dialog.ComboBox1.ItemIndex:=0
  else
  if FreeShip.ProjectSettings.ProjectUnits = fuImperial then
    Dialog.ComboBox1.ItemIndex:=3;

  if Dialog.Execute then
  begin
    FreeShip.Preferences.ExportDirectory:=Dialog.ExportDirectory;
    if Length(FreeShip.Preferences.ExportDirectory) > 0 then
      if FreeShip.Preferences.ExportDirectory[Length(
        FreeShip.Preferences.ExportDirectory)] <> DirectorySeparator then
        FreeShip.Preferences.ExportDirectory:=FreeShip.Preferences.ExportDirectory + DirectorySeparator;

    ScaleFactor:=1.0;
    SegLength:=Dialog.SegmentLength;
    if FreeShip.ProjectSettings.ProjectUnits = fuMetric then
      case Dialog.ComboBox1.ItemIndex of
        0: ScaleFactor:=1.0;         // Scale from meters to meters
        1: ScaleFactor:=100;         // Scale from meters to centimeters
        2: ScaleFactor:=1000;        // Scale from meters to millimeters
        3: ScaleFactor:=1/Foot;      // Scale from meters to feet
        4: ScaleFactor:=12/Foot;     // Scale from meters to inches
      end
    else if FreeShip.ProjectSettings.ProjectUnits = fuImperial then
      case Dialog.ComboBox1.ItemIndex of
        0: ScaleFactor:=Foot;        // Scale from feet to meters
        1: ScaleFactor:=100*foot;    // Scale from feet to centimeters
        2: ScaleFactor:=1000*foot;   // Scale from feet to millimeters
        3: ScaleFactor:=1.0;         // Scale from feet to feet
        4: ScaleFactor:=12;          // Scale from feet to inches
      end;

    Strings:=TStringList.Create;
    PrevCursor:=Screen.Cursor;
    Screen.Cursor:=crHourGlass;
    try
      CreateIndividualLayers:=Dialog.cbCreateIndividualLayers.Checked;

      if Dialog.cbCreateIndividualFiles.Checked then begin        // send each intersection to an individual dxf file
        Intersections:=TFasterListTFreeIntersection.Create;
        if FreeShip.Visibility.ShowStations then Intersections.AddList(FreeShip.FStations);
        if FreeShip.Visibility.ShowButtocks then Intersections.AddList(FreeShip.FButtocks);
        if FreeShip.Visibility.ShowWaterlines then Intersections.AddList(FreeShip.FWaterlines);
        for I:=1 to Intersections.Count do begin
          Strings.Clear;
          Layername:=getLayerName(Intersections[I - 1].IntersectionType);
          DefineLayers(Strings, Layername, I, 1);
          Strings.Add('0' + EOL + 'SECTION');
          Strings.Add('2' + EOL + 'ENTITIES');
          CreateDXFData(Intersections[I - 1], I, Strings, ScaleFactor, Filename);
          Strings.Add('0' + EOL + 'ENDSEC');
          Strings.Add('0' + EOL + 'EOF');
          Strings.SaveToFile(Filename);
        end;
        FreeAndNil(Intersections);
      end
      else
      begin
        if (FreeShip.Visibility.ShowStations) and (FreeShip.NumberofStations > 0) then
        begin
          Strings.Clear;
          Layername:=getLayerName(fiStation);
          DefineLayers(Strings, Layername, 1, FreeShip.NumberofStations);
          Strings.Add('0' + EOL + 'SECTION');
          Strings.Add('2' + EOL + 'ENTITIES');
          for I:=1 to FreeShip.NumberofStations do
            CreateDXFData(FreeShip.Station[I - 1], I, Strings, ScaleFactor, Filename);
          Strings.Add('0' + EOL + 'ENDSEC');
          Strings.Add('0' + EOL + 'EOF');
          Filename:=FreeShip.Preferences.ExportDirectory + 'stations.dxf';
          Strings.SaveToFile(Filename);
        end;
        if (FreeShip.Visibility.ShowButtocks) and (FreeShip.NumberofButtocks > 0) then
        begin
          Strings.Clear;
          Layername:=getLayerName(fiButtock);
          DefineLayers(Strings, Layername, 1, FreeShip.NumberofButtocks);
          Strings.Add('0' + EOL + 'SECTION');
          Strings.Add('2' + EOL + 'ENTITIES');
          for I:=1 to FreeShip.NumberofButtocks do
            CreateDXFData(FreeShip.Buttock[I - 1], I, Strings, ScaleFactor, Filename);
          Strings.Add('0' + EOL + 'ENDSEC');
          Strings.Add('0' + EOL + 'EOF');
          Filename:=FreeShip.Preferences.ExportDirectory + 'buttocks.dxf';
          Strings.SaveToFile(Filename);
        end;
        if (FreeShip.Visibility.ShowWaterlines) and (FreeShip.NumberofWaterlines > 0) then
        begin
          Strings.Clear;
          Layername:=getLayerName(fiWaterline);
          DefineLayers(Strings, Layername, 1, FreeShip.NumberofWaterlines);
          Strings.Add('0' + EOL + 'SECTION');
          Strings.Add('2' + EOL + 'ENTITIES');
          for I:=1 to FreeShip.NumberofWaterlines do
            CreateDXFData(FreeShip.Waterline[I - 1], I, Strings, ScaleFactor, Filename);
          Strings.Add('0' + EOL + 'ENDSEC');
          Strings.Add('0' + EOL + 'EOF');
          Filename:=FreeShip.Preferences.ExportDirectory + 'waterlines.dxf';
          Strings.SaveToFile(Filename);
        end;
      end;
    finally
      FreeAndNil(Strings);
      Screen.Cursor:=PrevCursor;
    end;
  end;
  FreeAndNil(Dialog);
end;

// Export for Aurora-Hull computational experiments

procedure TFreeEdit.File_Export_Aurora_Experiments;
var
  I,J,K,N: integer; Title,Str,S: String; z1,z2: Single;
  T3: T3DCoordinate=(X:0;Y:0;Z:0);
  Strings: TStringList;
  Dialog: TSaveDialog;

  EdgePointLists: TFasterListTFasterListTFreeSubdivisionPoint;
  Points: TFasterListTFreeSubdivisionPoint;
  Point: TFreeSubdivisionPoint;

  Procedure Str2( A,B: single );
    begin Str:=Str+format( ' %1.5g %1.5g',[F2S(A),F2S(B)] );  end;
  Procedure StemStern( Dir:boolean );                  // Dir=true - форштевень
    var I,J,K,M,N: Integer;
  begin Str:='';
    for I:=0 to FreeShip.NumberofButtocks-1 do        // поиск нулевого батокса
    with FreeShip.Buttock[I] do begin
      if not Built then Rebuild;
      if Count>0 then                     // батокс для диаметрильной плоскости
      if Items[0].Point[0].Y=0 then begin M:=0; z1:=Items[0].Point[0].Z;
        for J:=0 to Count-1 do begin
          N:=Items[J].NumberOfPoints-1;
          for K:=0 to N do if Items[J].Point[K].Z<=z1 then begin z1:=Items[J].Point[K].Z; M:=K; end;
          if Dir then begin Str:=' '+InttoStr( M+1 );
            for K:=M downto 0 do with Items[J].Point[K] do Str2( Z,X );
//              if Z>=z1 then begin Str2( Z,X ); z1:=Z; end else break;
          end else begin  Str:=' '+InttoStr( N-M+1 );
            for K:=M to N do with Items[J].Point[K] do Str2( Z,X );
//              if Z>=z1 then begin Str2( Z,X ); z1:=Z; end else break;
          end;
        end;
      end;
    end;
    if Str='' then Strings.Add( EOL+' 0' ) else Strings.Add( Str );
  end;
  procedure SendSpline( Spline:TFreespline );
  var J,N: integer; P: T3DCoordinate;
  begin N:=Spline.NumberOfPoints-1;
    Str:=format( ' %3d ',[N+1] );
    if Spline.Point[0].Z<=Spline.Point[N].Z
    then for J:=0 to N do with Spline.Point[J] do Str:=Str+format( ' %1.5g %1.5g %1.5g ',[F2S(X),F2S(Y),F2S(Z)] )
    else for J:=N downto 0 do with Spline.Point[J] do Str:=Str+format( ' %1.5g %1.5g %1.5g ',[F2S(X),F2S(Y),F2S(Z)] );
    Strings.Add( Str );
  end;

begin
  Title:=ExtractFilename( FreeShip.FileName );
  Dialog:=TSaveDialog.Create( FreeShip );
  Dialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  Dialog.FileName:=ChangeFileExt( Title,'.vsl');
  Dialog.Filter:=createDialogFilter('Aurora+Hull Vessel(db)file',['vsl']);
  dialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if Dialog.Execute then begin WestPoint;
    FreeShip.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
    Strings:=TStringList.Create;
    with FreeShip.FProjectSettings do
    Strings.Add( '; FREE!Ship' + EOL+';'
          + EOL +'; File Name: '+Title
          + EOL +'; Name     : '+FProjectName
          + EOL +'; Designer : '+FProjectDesigner
          + EOL +'; Create by: '+FProjectFileCreatedBy
          + EOL +'; Comment  : '+FProjectComment
          + EOL +';'
          + EOL + #30 + ' < ' + ExtractFilename( Dialog.FileName ) + ' > '      ///+++!!! уточнить где мидель
          + EOL + InttoStr( FreeShip.NumberofStations )
          + ' ' + InttoStr( FreeShip.NumberofStations div 2 )
          + EOL + FloatToStrF( FProjectLength,ffGeneral,6,1)
          + ' ' + FloatToStrF( FProjectBeam,ffGeneral,6,1)
          + ' ' + FloatToStrF( FProjectDraft,ffGeneral,6,1)+EOL );
//  T3.Z:=FreeShip.FProjectSettings.FProjectDraft;
    StemStern( false );                    // первые две строки для ахтерштевня
    Strings.Add( ' 0'+EOL );
    for I:=0 to FreeShip.NumberofStations-1 do
    with FreeShip.Station[I] do begin
      if not Built then Rebuild; N:=0; T3.Z:=0;
      for J:=0 to Count-1 do with Items[J] do begin
        N+=NumberOfPoints; for K:=0 to NumberOfPoints-1 do T3.Z+=Point[K].Z;
      end;                                                   // Z-положительно
      T3.Z:=0.98*T3.Z/N;
      T3.Y:=-FreeShip.FProjectSettings.FProjectBeam; T3.X:=Items[0].Point[0].X;
      Title:=format( '%3d %-4.4g',[N,F2S(T3.X)] ); S:='';
      for J:=0 to Count-1 do with Items[J] do begin
        N:=NumberOfPoints-1; Str:='';          // ещё и сортировки - не хватало
        if ( Point[N].Z-Point[0].Z>0.01 ) or         // == может быть на палубе
         ( ( (Point[0]-T3) * (Point[N]-T3) ).X>=0.0 )
        then begin z1:=Point[0].Z; for K:=0 to N do with Point[K] do Str2( Z,Y ); end
        else begin z1:=Point[N].Z; for K:=N downto 0 do with Point[K] do Str2( Z,Y ); end;
        if J=0 then S:=Str else begin if z1>=z2 then S:=S+Str else S:=Str+S; end; z2:=z1;
      end;
      Strings.Add( Title+S );
    end;
    Strings.Add( EOL+' 0' );                         // форштевень в завершение
    StemStern( true );          // и в заключение еще и все контрольные контуры

    if FreeShip.NumberOfControlCurves>0 then begin
      Strings.Add( EOL+'ContorlCurves['+IntToStr(FreeShip.NumberOfControlCurves)+']' );
      for I:=0 to FreeShip.NumberOfControlCurves-1 do
                  SendSpline( FreeShip.ControlCurve[I].Spline );
    end;

    EdgePointLists:=TFasterListTFasterListTFreeSubdivisionPoint.Create;
    FreeShip.Surface.ExtractAllEdgeLoops( EdgePointLists );
    if EdgePointLists.Count>0 then begin
      Strings.Add( EOL+'EdgePoints['+IntToStr( EdgePointLists.Count )+']' );
      for I:=0 to EdgePointLists.Count-1 do begin
        Points:=EdgePointLists[I]; N:=Points.Count-1;
        Str:=format( ' %3d ',[N+1] );          // ' '+IntToStr( Points.Count );
        if Points[0].Coordinate.Z<=Points[N].Coordinate.Z
        then for J:=0 to N do with Points[J].Coordinate do Str:=Str+format( ' %1.5g %1.5g %1.5g ',[F2S(X),F2S(Y),F2S(Z)] )
        else for J:=N downto 0 do with Points[J].Coordinate do Str:=Str+format( ' %1.5g %1.5g %1.5g ',[F2S(X),F2S(Y),F2S(Z)] );
        Strings.Add( Str );
        FreeAndNil(Points);
      end;
    end;
    FreeAndNil( EdgePointLists );
    Strings.SaveToFile( ChangeFileExt(Dialog.FileName, '.vsl' ));
    FreeAndNil(Strings);
  end;
  FreeAndNil(Dialog);
end;


// Exports all intersections to a textfile as 3D points

procedure TFreeEdit.File_ExportOffsets;
var
  SaveDialog: TSaveDialog;
  Strings: TStringList;
  I: integer;
  procedure SendSpline( Spline:TFreespline );
  var J: integer; Str: string; P: T3DCoordinate;
  begin
    for J:=1 to Spline.NumberOfPoints do begin P:=Spline.Point[J-1];
      Str:='        ' + MakeLength( P.X,4,10 ) +
                  #32 + MakeLength( P.Y,4,10 ) +
                  #32 + MakeLength( P.Z,4,10 );
      if Spline.Knuckle[J-1] then Str:=Str + '    KNUCKLE';
      Strings.Add(Str);
    end;
  end;
  procedure SendIntersection( Intersection: TFreeIntersection );
  var I: integer; Str: string; Spline: TFreeSpline;
  begin
    if not Intersection.Built then Intersection.Rebuild;
    if Intersection.Count > 0 then begin
      Str:=Intersection.Description;
      Strings.Add( Str );
      if Intersection.Count > 1 then Strings.Add(IntToStr(Intersection.Count) + ' segments.');
      for I:=1 to Intersection.Count do begin
        Spline:=Intersection.Items[I - 1];
        if Intersection.Count>1 then Strings.Add('SEGMENT '+IntToStr(I));
        SendSpline(Spline);
      end;
    end;
  end;

begin
  SaveDialog:=TSaveDialog.Create(FreeShip);
  SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '.txt');
  SaveDialog.Filter:=createDialogFilter('Offsets as 3D points',['txt']);
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if SaveDialog.Execute then begin WestPoint;
    FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
    Strings:=TStringList.Create;
    for I:=0 to FreeShip.NumberofStations-1 do SendIntersection(FreeShip.Station[I]);
    for I:=0 to FreeShip.NumberofButtocks-1 do SendIntersection(FreeShip.Buttock[I]);
    for I:=0 to FreeShip.NumberofWaterlines-1 do SendIntersection(FreeShip.Waterline[I]);
    for I:=0 to FreeShip.NumberofDiagonals-1 do SendIntersection(FreeShip.Diagonal[I]);
    for I:=0 to FreeShip.NumberOfControlCurves-1 do begin
      Strings.Add('CONTROLCURVE');
      SendSpline( FreeShip.ControlCurve[I].Spline );
    end;
    Strings.SaveToFile(ChangeFileExt(Savedialog.FileName, '.txt'));
    FreeAndNil(Strings);
  end;
  FreeAndNil(SaveDialog);
end;

// Export all lines to a 3D DXF model as polylines

procedure TFreeEdit.File_ExportDXF_3DPolylines;
var
  I, J, ind: integer;
  Strings: TStringList;
  Dialog: TSaveDialog;
  EdgePointLists: TFasterListTFasterListTFreeSubdivisionPoint;
  Points: TFasterListTFreeSubdivisionPoint;
  Point: TFreeSubdivisionPoint;
  Layername: string;
begin
  Dialog:=TSaveDialog.Create( FreeShip );
  Dialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  Dialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '.dxf');
  Dialog.Filter:=createDialogFilter(rsAutocadDxfFile,['dxf']);
  dialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if Dialog.Execute then begin WestPoint;
    FreeShip.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
    Strings:=TStringList.Create;
    Strings.Add('0' + EOL + 'SECTION');
    Strings.Add('2' + EOL + 'ENTITIES');
    if FreeShip.Visibility.ShowStations then
     for I:=0 to FreeShip.NumberofStations-1 do FreeShip.Station[I].SaveToDXF(Strings);
    if FreeShip.Visibility.ShowButtocks then
     for I:=0 to FreeShip.NumberofButtocks-1 do FreeShip.Buttock[I].SaveToDXF(Strings);
    if FreeShip.Visibility.ShowWaterlines then
     for I:=0 to FreeShip.NumberofWaterlines do FreeShip.Waterline[I].SaveToDXF(Strings);
    if FreeShip.Visibility.ShowDiagonals then
     for I:=0 to FreeShip.NumberofDiagonals-1 do FreeShip.Diagonal[I].SaveToDXF(Strings);
    if FreeShip.Visibility.ShowControlCurves then
     for I:=0 to FreeShip.NumberofControlCurves-1 do FreeShip.ControlCurve[I].SaveToDXF(Strings);

    EdgePointLists:=TFasterListTFasterListTFreeSubdivisionPoint.Create;
    FreeShip.Surface.ExtractAllEdgeLoops(EdgePointLists);
    Layername:='Edges';
    ind:=FindDXFColorIndex(FreeShip.Preferences.EdgeColor);
    //Points:=TFasterListTFreeSubdivisionPoint.Create;
    for I:=1 to EdgePointLists.Count do begin
      Points:=EdgePointLists[I - 1];
      //Points.Add(EdgePointLists[I - 1].StartPoint);
      //Points.Add(EdgePointLists[I - 1].EndPoint);
      Strings.Add('0' + EOL + 'POLYLINE');
      Strings.Add('8' + EOL + LayerName);       // layername
      Strings.Add('62' + EOL + IntToStr(Ind));  // color by layer
      Strings.Add('70' + EOL + '10');           // not closed
      Strings.Add('66' + EOL + '1');            // vertices follow
      for J:=1 to Points.Count do begin
        Point:=Points[J - 1];
        Strings.Add('0' + EOL + 'VERTEX');
        Strings.Add('8' + EOL + LayerName);
        Strings.Add('10' + EOL + FloatToDec(Point.Coordinate.X, 4));
        Strings.Add('20' + EOL + FloatToDec(Point.Coordinate.Y, 4));
        Strings.Add('30' + EOL + FloatToDec(Point.Coordinate.Z, 4));
        Strings.Add('70' + EOL + '32');              // 3D polyline mesh vertex
      end;
      Strings.Add('0' + EOL + 'SEQEND');
      if FreeShip.Visibility.ModelView = mvBoth then begin
        Strings.Add('0' + EOL + 'POLYLINE');
        Strings.Add('8' + EOL + LayerName);       // layername
        Strings.Add('62' + EOL + IntToStr(Ind));  // color by layer
        Strings.Add('70' + EOL + '10');           // not closed
        Strings.Add('66' + EOL + '1');            // vertices follow
        for J:=1 to Points.Count do begin
          Point:=Points[J - 1];
          Strings.Add('0' + EOL + 'VERTEX');
          Strings.Add('8' + EOL + LayerName);
          Strings.Add('10' + EOL + FloatToDec(Point.Coordinate.X, 4));
          Strings.Add('20' + EOL + FloatToDec(-Point.Coordinate.Y, 4));
          Strings.Add('30' + EOL + FloatToDec(Point.Coordinate.Z, 4));
          Strings.Add('70' + EOL + '32');    // 3D polyline mesh vertex
        end;
        Strings.Add('0' + EOL + 'SEQEND');
      end;
      FreeAndNil(Points);
    end;
    FreeAndNil(EdgePointLists);
    Strings.Add('0' + EOL + 'ENDSEC');
    Strings.Add('0' + EOL + 'EOF');
    Strings.SaveToFile(ChangeFileExt(Dialog.FileName, '.dxf'));
    FreeAndNil(Strings);
  end;
  FreeAndNil(Dialog);
end;

// Export all faces to a 3D DXF model
procedure TFreeEdit.File_ExportDXF_Faces;
var
  I: integer;
  Strings: TStringList;
  Dialog: TSaveDialog;
  Prev: TCursor;
begin
  Dialog:=TSaveDialog.Create(FreeShip);
  Dialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  Dialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '.dxf');
  Dialog.Filter:=createDialogFilter(rsAutocadDxfFile,['dxf']);
  dialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if Dialog.Execute then begin WestPoint;
    Prev:=Screen.Cursor;
    Screen.Cursor:=crHourglass;
//  try
      FreeShip.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
      Strings:=TStringList.Create;
      Strings.Add('0' + EOL + 'SECTION');
      Strings.Add('2' + EOL + 'ENTITIES');
      for i:=0 to FreeShip.Surface.NumberOfLayers-1 do
        FreeShip.Surface.Layer[i].SaveToDXF(Strings);
      Strings.Add('0' + EOL + 'ENDSEC');
      Strings.Add('0' + EOL + 'EOF');
//    try
        Strings.SaveToFile(ChangeFileExt(Dialog.FileName, '.dxf'));
//    except
//      MessageDlg('Could not access '+ChangeFileExt(Dialog.FileName, '.dxf'),mtError, [mbOK], 0);
//    end;
//  finally
      Screen.Cursor:=Prev;
//  end;
    FreeAndNil(Strings);
  end;
  FreeAndNil(Dialog);
end;

procedure TFreeEdit.File_ExportFEF;
var
  SaveDialog: TSaveDialog;
  Strings: TStringList;
begin
  SaveDialog:=TSaveDialog.Create(FreeShip);
  SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '.fef');
  SaveDialog.Filter:=createDialogFilter(rsFREEShipExchangeFormat,['fef']);
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if SaveDialog.Execute then begin WestPoint;
    FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
    Strings:=TStringList.Create;
    // Add general info and mainparticulars
    Strings.Add(FreeShip.ProjectSettings.ProjectName);
    Strings.Add(FreeShip.ProjectSettings.ProjectDesigner);
    Strings.Add(FreeShip.ProjectSettings.ProjectFileCreatedBy);
    Strings.Add(FreeShip.ProjectSettings.ProjectComment);
    Strings.Add(FloatToDec(FreeShip.ProjectSettings.ProjectLength, 4) +
      #32 + FloatToDec(FreeShip.ProjectSettings.ProjectBeam, 4) + #32 +
      FloatToDec(FreeShip.ProjectSettings.ProjectDraft, 4) + #32 +
      FloatToDec(FreeShip.ProjectSettings.ProjectWaterDensity, 5) + #32 +
      FloatToDec(FreeShip.ProjectSettings.ProjectAppendageCoefficient, 5) +
      #32 + IntToStr(Ord(FreeShip.ProjectSettings.ProjectUnits)) + #32 +
      BoolToStr(FreeShip.ProjectSettings.MainparticularsHasBeenset) +
      #32 + IntToStr(Ord(FreeShip.Precision)));
    FreeShip.Surface.ExportFeFFile(Strings);
    Strings.SaveToFile(ChangeFileExt(Savedialog.FileName, '.fef'));
    FreeAndNil(Strings);
  end;
  FreeAndNil(SaveDialog);
end;{TFreeEdit.File_ExportFEF}

// Save ordinates to the GHS file format
procedure TFreeEdit.File_ExportGHS;
var
  I, J: integer;
  Section: TFreeSpline;
  SaveDialog: TSaveDialog;
  Strings: TStringList;
  PrevCursor: TCursor;
  Scale: TFloatType;
  Frames: TFasterListTFreeSpline;
  Str: string;
  P, Pkn: T3DCoordinate;
  NParams: integer;
  Params: TFloatArray;
  Pn, Pn1, Pn2: integer;
begin
  if not FreeShip.ProjectSettings.FMainparticularsHasBeenset then
  begin
    MessageDlg(Userstring(95), mtWarning, [mbOK], 0);
    exit;
  end;
  SaveDialog:=TSaveDialog.Create(FreeShip);
  SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  Str:=ChangeFileExt(ExtractFilename(FreeShip.Filename), '.GF');
  // no spaces allowed in filename
  repeat
    I:=Pos(#32, Str);
    if I <> 0 then Delete(Str, I, 1);
  until I = 0;
  Savedialog.FileName:=Str;
  SaveDialog.Filter:=createDialogFilter(rsGHSFiles,['gf']);
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if not SaveDialog.Execute then begin FreeAndNil(Savedialog); exit; end;
  WestPoint;
  FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
  PrevCursor:=Screen.Cursor;
  Screen.Cursor:=crHourGlass;
  Strings:=TStringList.Create;
  Frames:=TFasterListTFreeSpline.Create;
//try
    FreeShip.FBuildValidFrameTable(Frames, True);
    Scale:=1.0;
    //      if FreeShip.ProjectSettings.ProjectUnits=fuMetric then Scale:=1.0
    //                                                     else Scale:=1/Foot;
    Str:=FreeShip.ProjectSettings.ProjectName;
    if Length(Str) > 58 then
      Str:=Copy(Str, 1, 58);
    Strings.Add(Str);
    // ProjectDescription, max 58 characters
    Strings.Add('L:' + FloatToStrF(Scale * FreeShip.ProjectSettings.ProjectLength, ffFixed, 7, 3));
    // Length
    Strings.Add('W:' + FloatToStrF(Scale * FreeShip.ProjectSettings.ProjectBeam,
      ffFixed, 7, 3));
    // Beam
    Strings.Add('OL:Frame 0');
    Strings.Add('OT:Centerplane');
    Strings.Add('OV:Baseline');
    // Units preference
    if FreeShip.ProjectSettings.ProjectUnits = fuMetric then
      Strings.Add('P:M')
    else
      Strings.Add('P:F');
    // Add max. 10 comments
    Strings.Add('\Generated with FREE!ship');
    Strings.Add('\www.freeship.org');

    // Save shape
    Strings.Add('*');
    Strings.Add('HULL'); // shape name
    Strings.Add(IntToStr(Frames.Count)); // Number of sections
    for I:=Frames.Count downto 1 do
    begin
      Section:=Frames[I - 1];
      if Section.NumberOfPoints > 0 then
        if section.Point[Section.NumberOfPoints - 1].Y > 0 then
        begin
          Section.Knuckle[Section.NumberOfPoints - 1]:=True;
          Section.Add(Section.Point[Section.NumberOfPoints - 1]);
        end;

      NParams:=0;
      Setlength(Params, Section.NumberOfPoints);
      // count number of knucklepoints
      for J:=2 to Section.NumberOfPoints - 1 do
        if Section.Knuckle[J - 1] then
        begin
          Params[NParams]:=Section.Parameter[J - 1];
          Inc(NParams);
        end;
      if Section.NumberOfPoints > 100 then
      begin
        Section.Fragments:=100;
        Setlength(Params, NParams + Section.Fragments);
        for J:=1 to Section.Fragments do
        begin
          Params[NParams]:=(J - 1) / (Section.Fragments - 1);
          Inc(NParams);
        end;
      end
      else
      begin
        Setlength(Params, NParams + Section.NumberOfPoints);
        for J:=1 to Section.NumberOfPoints do
        begin
          Params[NParams]:=Section.Parameter[J - 1];
          Inc(NParams);
        end;
      end;
      SortFloatArray(Params, NParams);
      Strings.Add(FloatToDec(-Scale * Section.Min.X, 4) + ',' + IntToStr(NParams));
      Pn:=0;
      for J:=0 to NParams - 1 do
      begin
        P:=Section.Value(Params[J], Pn1, Pn2);
        if (Pn <> Pn1) and Section.Knuckle[Pn1] then
        begin
          Pn:=Pn1;
          Pkn:=Section.Point[Pn1];
          Strings.Add(FloatToDec(Scale * Pkn.Y, 4) + ',' + FloatToDec(Scale * Pkn.Z, 4));
        end;
        Strings.Add(FloatToDec(Scale * P.Y, 4) + ',' + FloatToDec(Scale * P.Z, 4));
      end;
      FreeAndNil(Section);
    end;
    Strings.Add('0,0,0');         // shell thickness data of shape

    // save Component
    Strings.Add('**');
    Strings.Add('HULL.C');        // ComponentName
    // side
    Strings.Add('0');             // side=center
    Strings.Add('1.0');           // effectivenes
    Strings.Add('0,0,0');         // attachpoint
    Strings.Add('HULL');          // partname

    // Save part
    Strings.Add('***');
    Strings.Add('HULL');          // Partname and description
    Strings.Add('WATER');                  // FluidName
    strings.Add('1');                      // part type (displacement)
    if FreeShip.ProjectSettings.ProjectUnits = fuMetric then
      Strings.Add(FloatToStrF(FreeShip.ProjectSettings.ProjectWaterDensity, ffFixed, 7, 3))
    // specific gravity of water
    else
      Strings.Add(FloatToStrF(FreeShip.ProjectSettings.ProjectWaterDensity /
        WeightConversionFactor, ffFixed, 7, 3));
    Strings.Add('0,0,0');      // ReferencePoint
    Strings.Add('1');          // Number of components
    Strings.Add('HULL.C');     // Componentname
    // Mark end of file
    Strings.Add('****');
    Str:=ChangeFileExt(ExtractFilename(Savedialog.FileName), '.GF');
    // no spaces allowed in filename
    repeat
      I:=Pos(#32,Str);
      if I<>0 then Delete(Str, I, 1);
    until I=0;
    Str:=ExtractFilePath(SaveDialog.Filename) + Str;
    Strings.SaveToFile(Str);
    FreeAndNil(SaveDialog);
//finally
    FreeAndNil(Frames);
    Screen.Cursor:=PrevCursor;
    FreeAndNil(Strings);
//end;
end;

// Save part of the geometry to a file
procedure TFreeEdit.File_ExportPart;
var
  SelectDlg: TFreeSelectLayersDialog;
  Faces: TFasterListTFreeSubdivisionControlFace;
  I: integer;
begin
  Faces:=TFasterListTFreeSubdivisionControlFace.Create;
  if FreeShip.NumberOfSelectedControlFaces = 0 then
  begin
    SelectDlg:=TFreeSelectLayersDialog.Create(FreeShip);                      //  ShowTranslatedValues(SelectDlg);
    if SelectDlg.Execute(FFreeShip, fsFaces) then
      SelectDlg.ExtractSelectedFaces(Faces);
    for I:=FreeShip.NumberOfSelectedControlFaces downto 1 do
      FreeShip.SelectedControlFace[I - 1].Selected:=False;
    Freeship.ReDraw;
    FreeAndNil(SelectDlg);
  end
  else
  begin
    Faces.Capacity:=Faces.Count + FreeShip.NumberOfSelectedControlFaces;
    for I:=1 to FreeShip.NumberOfSelectedControlFaces do
      Faces.Add(FreeShip.SelectedControlFace[I - 1]);
  end;
  if Faces.Count > 0 then
    FreeShip.SavePart(Faces);
  FreeAndNil(Faces);
end;{TFreeEdit.File_ExportPart}

// Save NURBS patches to an IGES file
procedure TFreeEdit.File_ExportIGES;
const
  MinimizeFaces = True;
  SendTriangles = False;//true;
var
  I, J, K, LI: integer;
  Cols, Rows: integer;
  Dialog: TSaveDialog;
  Prev: TCursor;
  Layers: TFasterListTFreeSubdivisionLayer;
  Layer: TFreeSubdivisionLayer;
  FaceData: TFreeFaceGrid;
  Assembled: TFreeFaceArray;
  NAssembled: integer;
  IGESList: TFreeIGESList;
  Grid: TFreeSubdivisionPointGrid;
  CtrlFace: TFreeSubdivisionControlFace;
  Face: TFreeSubdivisionFace;
  PrevLevel: integer;
  ColorIndices: array of integer;
  ColorIndex: integer;
  NSurfaces: integer;
  CheckFaces: TFasterListTFreeSubdivisionFace;


  function FindFourtPoint(P1, P2, p3: TFreeSubdivisionPoint): TFreeSubdivisionPoint;
  var
    Face: TFreeSubdivisionFace;
    I, J: integer;
    List: TList;
  begin
    Result:=nil;
    if (P1 <> P2) and (P2 <> P3) and (P1 <> P3) then
      for I:=1 to P2.NumberOfFaces do
      begin
        Face:=P2.Face[I - 1];
        if (Face.IndexOfPoint(P1) <> -1) and
          // (Face.IndexOfPoint(P2)<>-1) and
          (Face.IndexOfPoint(P3) <> -1) then
        begin
          List:=TList.Create;
          for J:=1 to face.NumberOfpoints do
            list.Add(Face.Point[J - 1]);
          J:=List.IndexOf(P1);
          if J <> -1 then
            list.Delete(J);
          J:=List.IndexOf(P2);
          if J <> -1 then
            list.Delete(J);
          J:=List.IndexOf(P3);
          if J <> -1 then
            list.Delete(J);
          if list.Count > 0 then
            Result:=TFreeSubdivisionPoint(List[0]);
          FreeAndNil(List);
        end;
      end;
  end;{FindFourtPoint}

  procedure FindOpposingPoints(P1, P2, P3, P4: TFreeSubdivisionPoint;
  var OppPoint2, OppPoint3: TFreeSubdivisionPoint);
  // find the points opposite to P2 and P3
  var
    I, Index: integer;
    Edge: TFreeSubdivisionEdge;
    Face: TFreeSubdivisionface;
  begin
    OppPoint2:=nil;
    OppPoint3:=nil;
    Edge:=FreeShip.Surface.EdgeExists(P2, P3);
    if Edge <> nil then
      if not Edge.Crease then
        for I:=1 to Edge.NumberOfFaces do
        begin
          Face:=Edge.Face[I - 1];
          if (Face.IndexOfPoint(P1) = -1) or (Face.IndexOfPoint(P2) = -1) or
            (Face.IndexOfPoint(P3) = -1) or (Face.IndexOfPoint(P4) = -1) then
          begin
            Index:=Face.IndexOfPoint(P3);
            if Index <> -1 then
            begin
              Index:=(Index + 1) mod Face.NumberOfpoints;
              if Face.Point[index] = P2 then
              begin
                // face is oriented CCW
                Index:=(Index + 1) mod Face.NumberOfpoints;
                OppPoint2:=Face.Point[index];
                Index:=(Index + 1) mod Face.NumberOfpoints;
                OppPoint3:=Face.Point[index];
              end
              else
              begin
                Index:=Face.IndexOfPoint(P2);
                if Index <> -1 then
                begin
                  Index:=(Index + 1) mod Face.NumberOfpoints;
                  if Face.Point[index] = P3 then
                  begin
                    // face is oriented CW
                    Index:=(Index + 1) mod Face.NumberOfpoints;
                    OppPoint3:=Face.Point[index];
                    Index:=(Index + 1) mod Face.NumberOfpoints;
                    OppPoint2:=Face.Point[index];
                  end;
                end;
              end;
            end;
            break;
          end;
        end;
  end;{FindOpposingPoints}

  procedure AssembleTriangle(var Cols, Rows: integer; var Grid: TFreeSubdivisionPointGrid;
    Face: TFreeSubdivisionControlface);
  var
    I, J, N: integer;
    Index: integer;
    Points: TFasterListTFreeSubdivisionPoint;
    Faces: TFasterListTFreeSubdivisionface;
    Child: TFreeSubdivisionface;
    P: TFreeSubdivisionPoint;
    InteriorPoint: TFreeSubdivisionPoint;
  begin
    // Initialize grid
    Cols:=0;
    Rows:=0;

    Points:=TFasterListTFreeSubdivisionPoint.Create;
    Faces:=TFasterListTFreeSubdivisionFace.Create;
    for I:=1 to Face.ChildCount do
    begin
      Child:=Face.Child[I - 1];
      Faces.Add(Child);
      for J:=1 to Child.NumberOfpoints do
      begin
        P:=Child.Point[J - 1];
        if Points.SortedIndexOf(P) = -1 then
          Points.AddSorted(P);
      end;
    end;
    Faces.Sort;
    // Try to isolate the interior point
    InteriorPoint:=nil;
    for I:=1 to Points.Count do
    begin
      P:=Points[I - 1];
      // check how many of the childfaces are connected (interior point must have 3)
      N:=0;
      for J:=1 to P.NumberOfFaces do
        if Faces.SortedIndexOf(P.Face[J - 1]) <> -1 then
          Inc(N);
      if N = 3 then
      begin
        InteriorPoint:=P;
        break;
      end;
    end;
    if Interiorpoint <> nil then
    begin
      Cols:=3;
      Rows:=3;
      Setlength(Grid, Rows);
      for I:=1 to Rows do
      begin
        Setlength(Grid[I - 1], Cols);
        for J:=1 to Cols do
          Grid[I - 1][J - 1]:=nil;
      end;

      Grid[1][1]:=InteriorPoint;
      Child:=Face.Child[2];
      Index:=Child.IndexOfPoint(InteriorPoint);
      Grid[1][0]:=Child.Point[(index + 1) mod 4];
      Grid[0][0]:=Child.Point[(index + 2) mod 4];
      Grid[0][1]:=Child.Point[(index + 3) mod 4];
      FindOpposingPoints(Grid[0][0], Grid[0][1], Grid[1][1], Grid[1]
        [0], Grid[0][2], Grid[1][2]);
      FindOpposingPoints(Grid[0][1], Grid[1][1], Grid[1][0], Grid[0]
        [0], Grid[2][1], Grid[2][0]);

      Grid[2][2]:=Grid[2][1];
//      for I:=1 to Rows do
//        for J:=1 to cols do
//          if grid[I - 1][j - 1] = nil then raise Exception.Create(Userstring(98));
    end
    else
      MessageDlg(Userstring(99), mtError, [mbOK], 0);
    FreeAndNil(Faces);
    FreeAndNil(Points);
  end;{AssembleTriangle}

  procedure ProcessGrid(Cols, Rows: integer; Grid: TFreeSubdivisionPointGrid;
    ColorInd: integer; LayerIsSymmetric: boolean);
  // convert grid to a NURB
  var
    NURB, NURB2: TFreeNURBsurface;
    I, J: integer;
    BottomRow: array of TFreeSubdivisionPoint;
    TopRow: array of TFreeSubdivisionPoint;
    LeftColumn: array of TFreeSubdivisionPoint;
    RightColumn: array of TFreeSubdivisionPoint;
    BottomLeft: TFreeSubdivisionPoint;
    BottomRight: TFreeSubdivisionPoint;
    TopLeft: TFreeSubdivisionPoint;
    TopRight: TFreeSubdivisionPoint;
    BottomPresent: boolean;
    LeftPresent: boolean;
    RightPresent: boolean;
    TopPresent: boolean;
    P: T3DCoordinate;

    function PhantomPoint(BorderPoint, InnerPoint: T3DCoordinate): T3DCoordinate;
    begin
      Result.X:=2 * BorderPoint.X - InnerPoint.X;
      Result.Y:=2 * BorderPoint.Y - InnerPoint.Y;
      Result.Z:=2 * BorderPoint.Z - InnerPoint.Z;
    end;{PhantomPoint}

    function CornerPoint(P5, P6, P8, P9: T3DCoordinate): T3DCoordinate;
    var
      P2, P3, P4, P7: T3DCoordinate;
    begin
      P2:=PhantomPoint(P5, P8);
      P3:=PhantomPoint(P6, P9);
      P4:=PhantomPoint(P5, P6);
      P7:=PhantomPoint(P8, P9);
      Result.X:=20 * P5.X - 4 * P2.X - P3.X - 4 * P4.X - 4 * P6.X -
        P7.X - 4 * P8.X - P9.X;
      Result.Y:=20 * P5.Y - 4 * P2.Y - P3.Y - 4 * P4.Y - 4 * P6.Y -
        P7.Y - 4 * P8.Y - P9.Y;
      Result.Z:=20 * P5.Z - 4 * P2.Z - P3.Z - 4 * P4.Z - 4 * P6.Z -
        P7.Z - 4 * P8.Z - P9.Z;
    end;{CornerPoint}

  begin
    if (Cols > 0) and (Rows > 0) then
    begin
      Setlength(BottomRow, Cols);
      Setlength(TopRow, Cols);
      Setlength(LeftColumn, Rows);
      Setlength(RightColumn, Rows);

      // assemble bottom row to set tangency
      BottomPresent:=True;
      for I:=2 to Cols do
      begin
        FindOpposingPoints(Grid[Rows - 2][I - 2], Grid[Rows - 1][I - 2],
          Grid[Rows - 1][I - 1], Grid[Rows - 2][I - 1], BottomRow[I - 2],
          BottomRow[I - 1]);
        if (BottomRow[I - 2] = nil) or (BottomRow[I - 1] = nil) then
          BottomPresent:=False;
      end;
      RightPresent:=True;
      // assemble right column to set tangency
      for I:=2 to Rows do
      begin
        FindOpposingPoints(Grid[I - 1][Cols - 2], Grid[I - 1][Cols - 1],
          Grid[I - 2][Cols - 1], Grid[I - 2][Cols - 2], RightColumn[I - 1],
          RightColumn[I - 2]);
        if (RightColumn[I - 1] = nil) or (RightColumn[I - 2] = nil) then
          RightPresent:=False;
      end;
      // assemble top row
      TopPresent:=True;
      for I:=2 to Cols do
      begin
        FindOpposingPoints(Grid[1][I - 1], Grid[0][I - 1], Grid[0][I - 2],
          Grid[1][I - 2], TopRow[I - 1], TopRow[I - 2]);
        if (TopRow[I - 2] = nil) or (TopRow[I - 1] = nil) then
          TopPresent:=False;
      end;
      // Assemble left column
      LeftPresent:=True;
      for I:=2 to Rows do
      begin
        FindOpposingPoints(Grid[I - 2][1], Grid[I - 2][0], Grid[I - 1]
          [0], Grid[I - 1][1], LeftColumn[I - 2], LeftColumn[I - 1]);
        if (LeftColumn[I - 1] = nil) or (LeftColumn[I - 2] = nil) then
          LeftPresent:=False;
      end;
      BottomLeft:=nil;
      BottomRight:=nil;
      TopLeft:=nil;
      TopRight:=nil;

      if BottomPresent and leftPresent then
        BottomLeft:=FindFourtPoint(LeftColumn[Rows - 1], Grid[Rows - 1][0],
          BottomRow[0]);
      // find bottomleft cornerpoint
      if BottomPresent and RightPresent then
        BottomRight:=FindFourtPoint(RightColumn[Rows - 1],
          Grid[Rows - 1][Cols - 1], BottomRow[Cols - 1]);
      // find bottomRight cornerpoint
      if TopPresent and leftPresent then
        TopLeft:=FindFourtPoint(LeftColumn[0], Grid[0][0], TopRow[0]);
      // find Topleft cornerpoint
      if TopPresent and RightPresent then
        TopRight:=FindFourtPoint(RightColumn[0], Grid[0][Cols - 1], TopRow[Cols - 1]);
      // find TopRight cornerpoint

      NURB:=TFreeNURBsurface.Create(FreeShip.Surface);
      NURB.SetCapacity(Cols + 2, Rows + 2);
      NURB.ColCount:=Nurb.ColCapacity;
      NURB.RowCount:=Nurb.RowCapacity;
      for I:=1 to Rows do
        for J:=1 to COLS do
          NURB.Point[J, I]:=Grid[I - 1][J - 1].Coordinate;

      if SendTriangles then
        if (Grid[Rows - 1][Cols - 1] = Grid[Rows - 1][Cols - 2]) and
          (Grid[Rows - 1][Cols - 1] = Grid[Rows - 2][Cols - 1]) then
        begin
          Nurb.Point[Cols, Rows]:=Grid[Rows - 1][Cols - 1].LimitPoint;
          Nurb.Point[Cols - 1, Rows]:=Grid[Rows - 1][Cols - 1].LimitPoint;
          Nurb.Point[Cols, Rows - 1]:=Grid[Rows - 1][Cols - 1].LimitPoint;
          Nurb.RowCount:=Nurb.RowCount - 1 + 1;
        end// check for special triangle case
      ;


      if TopPresent then
        for I:=1 to Cols do
          Nurb.Point[I, 0]:=TopRow[I - 1].Coordinate
      else
        for I:=1 to Cols do
          Nurb.Point[I, 0]:=PhantomPoint(Nurb.Point[I, 1], Nurb.Point[I, 2]);
      if BottomPresent then
        for I:=1 to Cols do
          Nurb.Point[I, Rows + 1]:=BottomRow[I - 1].Coordinate
      else
        for I:=1 to Cols do
          Nurb.Point[I, Rows + 1] :=
            PhantomPoint(Nurb.Point[I, Rows], Nurb.Point[I, Rows - 1]);
      if LeftPresent then
        for I:=1 to Rows do
          Nurb.Point[0, I]:=LeftColumn[I - 1].Coordinate
      else
        for I:=1 to Rows do
          Nurb.Point[0, I]:=PhantomPoint(Nurb.Point[1, I], Nurb.Point[2, I]);
      if RightPresent then
        for I:=1 to Rows do
          Nurb.Point[Cols + 1, I]:=RightColumn[I - 1].Coordinate
      else
        for I:=1 to Rows do
          Nurb.Point[Cols + 1, I] :=
            PhantomPoint(Nurb.Point[Cols, I], Nurb.Point[Cols - 1, I]);

      if TopLeft <> nil then
        Nurb.Point[0, 0]:=TopLeft.Coordinate
      else
        Nurb.Point[0, 0]:=CornerPoint(Nurb.Point[1, 1], Nurb.Point[2, 1],
          Nurb.Point[1, 2], Nurb.Point[2, 2]);
      if TopRight <> nil then
        Nurb.Point[Nurb.ColCount - 1, 0]:=TopRight.Coordinate
      else
        Nurb.Point[Nurb.ColCount - 1, 0] :=
          CornerPoint(Nurb.Point[Nurb.Colcount - 2, 1],
          Nurb.Point[Nurb.Colcount - 3, 1], Nurb.Point[Nurb.Colcount - 2, 2],
          Nurb.Point[Nurb.Colcount - 3, 2]);
      if BottomLeft <> nil then
        Nurb.Point[0, Nurb.RowCount - 1]:=BottomLeft.Coordinate
      else
        Nurb.Point[0, Nurb.RowCount - 1] :=
          CornerPoint(Nurb.Point[1, Nurb.Rowcount - 2],
          Nurb.Point[2, Nurb.Rowcount - 2], Nurb.Point[1, Nurb.Rowcount - 3],
          Nurb.Point[2, Nurb.Rowcount - 3]);
      if BottomRight <> nil then
        Nurb.Point[Nurb.ColCount - 1, Nurb.RowCount - 1]:=BottomRight.Coordinate
      else
        Nurb.Point[Nurb.ColCount - 1, Nurb.RowCount - 1] :=
          CornerPoint(Nurb.Point[Nurb.Colcount - 2, Nurb.Rowcount - 2],
          Nurb.Point[Nurb.Colcount - 3, Nurb.Rowcount - 2],
          Nurb.Point[Nurb.Colcount - 2, Nurb.Rowcount - 3],
          Nurb.Point[Nurb.Colcount - 3, Nurb.Rowcount - 3]);

      NURB.ColDegree:=3;
      NURB.RowDegree:=3;
      NURB.SetUniformColKnotvector;
      NURB.SetUniformRowKnotvector;

      // Insert knots to force the patch to interpolate start and endknots
      for I:=1 to Nurb.ColDegree do
        Nurb.InsertColKnot(Nurb.Colknotvector[Nurb.ColDegree]);
      for I:=1 to Nurb.ColDegree do
        Nurb.InsertColKnot(Nurb.Colknotvector[Nurb.ColCount]);
      for I:=1 to Nurb.RowDegree do
        Nurb.InsertRowKnot(Nurb.Rowknotvector[Nurb.RowDegree]);
      for I:=1 to Nurb.RowDegree do
        Nurb.InsertRowKnot(Nurb.Rowknotvector[Nurb.RowCount]);
      // Delete old startpoints
      for I:=1 to Nurb.ColDegree do
        Nurb.DeleteColumn(0);
      for I:=1 to Nurb.ColDegree do
        Nurb.DeleteColumn(Nurb.ColCount - 1);
      for I:=1 to Nurb.RowDegree do
        Nurb.DeleteRow(0);
      for I:=1 to Nurb.RowDegree do
        Nurb.DeleteRow(Nurb.RowCount - 1);
      // Set knotvectors to open-knot vector type (standard interpolating form)
      Nurb.SetDefaultColKnotvector;
      Nurb.SetDefaultRowKnotvector;

      // Check all cornerpoints for irregular vertices
         {
         if TopLeft=nil then if not Grid[0][0].IsRegularNURBSPoint(CheckFaces) then Nurb.Point[0,0]:=LimitPoint(Grid[0][0]);
         if Topright=nil then if not Grid[0][Cols-1].IsRegularNURBSPoint(CheckFaces) then Nurb.Point[Cols+1,0]:=LimitPoint(Grid[0][Cols-1]);
         if BottomLeft=nil then if not Grid[Rows-1][0].IsRegularNURBSPoint(CheckFaces) then Nurb.Point[0,Rows+1]:=LimitPoint(Grid[Rows-1][0]);
         if bottomright=nil then if not Grid[Rows-1][Cols-1].IsRegularNURBSPoint(CheckFaces) then Nurb.Point[Cols+1,Rows+1]:=LimitPoint(Grid[Rows-1][Cols-1]);
         }
         {
         if TopLeft=nil then Nurb.Point[0,0]:=LimitPoint(Grid[0][0]);
         if Topright=nil then Nurb.Point[Cols+1,0]:=LimitPoint(Grid[0][Cols-1]);
         if BottomLeft=nil then Nurb.Point[0,Rows+1]:=LimitPoint(Grid[Rows-1][0]);
         if bottomright=nil then Nurb.Point[Cols+1,Rows+1]:=LimitPoint(Grid[Rows-1][Cols-1]);
         }
      Nurb.Point[0, 0]:=Grid[0][0].LimitPoint;
      Nurb.Point[Cols + 1, 0]:=Grid[0][Cols - 1].LimitPoint;
      Nurb.Point[0, Rows + 1]:=Grid[Rows - 1][0].LimitPoint;
      Nurb.Point[Cols + 1, Rows + 1]:=Grid[Rows - 1][Cols - 1].LimitPoint;
      IGESList.Add_Entity_128(NURB, ColorInd);
      if (FreeShip.Visibility.ModelView = mvBoth)
         and LayerIsSymmetric then
      begin
        NURB2:=TFreeNURBsurface.Create(FreeShip.Surface);
        NURB2.SetCapacity(Nurb.ColCount, Nurb.RowCount);
        NURB2.ColCount:=Nurb2.ColCapacity;
        NURB2.RowCount:=Nurb2.RowCapacity;
        NURB2.ColDegree:=Nurb.ColDegree;
        NURB2.RowDegree:=Nurb.RowDegree;
        for I:=Nurb.ColCount downto 1 do
          for J:=Nurb.RowCount downto 1 do
          begin
            P:=NURB.Point[I - 1, J - 1];
            P.Y:=-P.Y;
            NURB2.Point[NURB2.Colcount - I, Nurb2.RowCount - J]:=P;
          end;
        NURB2.SetDefaultColKnotvector;
        NURB2.SetDefaultRowKnotvector;
        IGESList.Add_Entity_128(NURB2, ColorInd);
        Inc(NSurfaces);
        FreeAndNil(NURB2);
      end;
      Inc(NSurfaces);
      FreeAndNil(NURB);
    end;
  end;{ProcessGrid}

begin
  Dialog:=TSaveDialog.Create(FreeShip);
  Dialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  Dialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '.igs');
  Dialog.Filter:=createDialogFilter(rsIGESFiles,['igs']);
  dialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if Dialog.Execute then begin WestPoint;
    Prev:=Screen.Cursor;
    Screen.Cursor:=crHourglass;
    PrevLevel:=FreeShip.Surface.DesiredSubdivisionLevel;
    NSurfaces:=0;
//  try
      FreeShip.Surface.DesiredSubdivisionLevel:=1;
      FreeShip.Surface.SubdivisionMode:=fmCatmullClark;
      if not FreeShip.Surface.Built then
        FreeShip.Surface.Rebuild;
      FreeShip.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
      IGESList:=TFreeIGESList.Create;
      IGESList.IGESUnits:=FreeShip.ProjectSettings.ProjectUnits;
      IGESList.SystemID:='FREE!ship' + #32 + VersionString(CurrentVersion);
      IGESList.FileCreatedBy:=FreeShip.ProjectSettings.ProjectFileCreatedBy;
      IGESList.FileName:=Dialog.FileName;
      // Build color table
      Layers:=TFasterListTFreeSubdivisionLayer.Create;
      for I:=0 to FreeShip.NumberOfLayers - 1 do
        if (FreeShip.Layer[I].SurfaceVisible) and (FreeShip.Layer[I].Count > 0) then
          Layers.Add(FreeShip.Layer[I]);
      Layers.Sort;
      Setlength(ColorIndices, Layers.Count);
      for I:=0 to Layers.Count - 1 do
      begin
        Layer:=Layers[I];
        ColorIndices[I]:=IGESList.Add_Entity_314(Layer.Color);
      end;
      if MinimizeFaces then begin
        FreeShip.Surface.AssembleFacesToPatches(Layers, amNURBS, Assembled, NAssembled);
        CheckFaces:=TFasterListTFreeSubdivisionFace.Create;
        for I:=1 to NAssembled do begin
          FaceData:=Assembled[I-1];
          CheckFaces.Clear;
          Checkfaces.Capacity:=FaceData.NCols * FaceData.NRows;
          for J:=1 to Facedata.NRows do
            for K:=1 to FaceData.NCols do
              CheckFaces.Add(Facedata.Faces[J - 1][K - 1]);
          if (FaceData.NCols > 0) and (FaceData.NRows > 0) then
            if ((FaceData.NCols > 1) and (FaceData.NRows >= 1)) or
              ((FaceData.NCols >= 1) and (FaceData.NRows > 1)) or
              ((FaceData.NCols = 1) and (FaceData.NRows = 1) and
              (FaceData.Faces[0][0].NumberOfPoints = 4)) then
            begin
              CtrlFace:=FaceData.Faces[0][0];
              LI:=Layers.SortedIndexOf(Ctrlface.Layer);
              ColorIndex:=ColorIndices[LI];
              FreeShip.Surface.ConvertToGrid(FaceData, Cols, Rows, Grid);
              ProcessGrid(Cols, Rows, Grid, ColorIndex, Ctrlface.Layer.Symmetric);
            end
            else
            begin
              CtrlFace:=FaceData.Faces[0][0];
              if Layers.SortedIndexOf(Ctrlface.Layer) <> -1 then
                ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
              else
                Colorindex:=0;
              if (CtrlFace.NumberOfpoints = 3) and (SendTriangles) then
              begin
                AssembleTriangle(Cols, Rows, Grid, CtrlFace);
                if (Cols > 0) and (Rows > 0) then
                  ProcessGrid(Cols, Rows, Grid, ColorIndex, Ctrlface.Layer.Symmetric);
              end
              else
              begin
                Cols:=2;
                Rows:=2;
                Setlength(Grid, 2);
                Setlength(Grid[0], 2);
                Setlength(Grid[1], 2);
                for J:=1 to CtrlFace.ChildCount do
                begin
                  Face:=CtrlFace.Child[J - 1];
                  Grid[0][1]:=Face.Point[0];
                  Grid[0][0]:=Face.Point[1];
                  Grid[1][0]:=Face.Point[2];
                  Grid[1][1]:=Face.Point[3];
                  ProcessGrid(Cols, Rows, Grid, ColorIndex, Ctrlface.Layer.Symmetric);
                end;
              end;
            end;
        end;
        FreeAndNil(CheckFaces);
      end
      else
        for I:=1 to FreeShip.Surface.NumberOfControlFaces do
        begin
          CtrlFace:=FreeShip.Surface.ControlFace[I - 1];
          if Layers.SortedIndexOf(Ctrlface.Layer) <> -1 then
            ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
          else
            Colorindex:=0;
          if CtrlFace.NumberOfpoints = 4 then
          begin
            FaceData.NCols:=1;
            FaceData.NRows:=1;
            Setlength(FaceData.Faces, 1);
            Setlength(FaceData.Faces[0], 1);
            FaceData.Faces[0][0]:=Ctrlface;
            FreeShip.Surface.ConvertToGrid(FaceData, Cols, Rows, Grid);
            ProcessGrid(Cols, Rows, Grid, ColorIndex, Ctrlface.Layer.Symmetric);
          end
          else
          begin
            Cols:=2;
            Rows:=2;
            Setlength(Grid, 2);
            Setlength(Grid[0], 2);
            Setlength(Grid[1], 2);
            for J:=1 to CtrlFace.ChildCount do
            begin
              Face:=CtrlFace.Child[J - 1];
              Grid[0][1]:=Face.Point[0];
              Grid[0][0]:=Face.Point[1];
              Grid[1][0]:=Face.Point[2];
              Grid[1][1]:=Face.Point[3];
              ProcessGrid(Cols, Rows, Grid, ColorIndex, Ctrlface.Layer.Symmetric);
            end;
          end;
        end;
      if NSurfaces > 0 then
      begin
        IGESList.SaveToFile(ChangeFileExt(Dialog.Filename, '.igs'));
        MessageDlg('Exported ' + IntToStr(NSurfaces) + ' surfaces.',
          mtInformation, [mbOK], 0);
      end
      else
        MessageDlg(Userstring(100), mtInformation, [mbOK], 0);
      FreeAndNil(IGESList);
      FreeAndNil(Layers);
//  finally
      FreeShip.Surface.DesiredSubdivisionLevel:=PrevLevel;
      FreeShip.Surface.SubdivisionMode:=fmQuadTriangle;
      if not FreeShip.Surface.Built then FreeShip.Surface.Rebuild;
      Screen.Cursor:=Prev;
      Freeship.ReDraw;
//  end;
  end;
  FreeAndNil(Dialog);
end;

// Creates a file to be read by the CFD program Michlet
procedure TFreeEdit.File_Export_Michlet;
var
  Dialog: TFreeMichletOutputDialog;
  SaveDialog: TSaveDialog;
  UndoObject: TFreeUndoObject;
begin
  if not FreeShip.ProjectSettings.FMainparticularsHasBeenset then begin
    MessageDlg(Userstring(95),mtWarning,[mbOK],0); exit;
  end;
  // temporarily switch to metric units for michlet export
  if FreeShip.ProjectSettings.ProjectUnits = fuImperial then begin
    UndoObject:=CreateUndoObject(Userstring(101), False);
    FreeShip.ProjectSettings.ProjectUnits:=fuMetric;
  end else UndoObject:=nil;
//try
    if not FreeShip.ProjectSettings.DisableModelCheck then
      Model_Check(False);
    Dialog:=TFreeMichletOutputDialog.Create(FreeShip);            //  ShowTranslatedValues(Dialog);
    // Hull
    Dialog.NumberOfStations:=31;
    Dialog.NumberOfWaterlines:=21;
    Dialog.Draft:=FreeShip.ProjectSettings.ProjectDraft;
    Dialog.Length:=FreeShip.ProjectSettings.ProjectLength;
    // Resistance
    Dialog.StartSpeed:=1;
    Dialog.EndSpeed:=5;
    Dialog.NumberOfSpeeds:=50;

    // Environment
    Dialog.G:=9.80665;
    Dialog.WaterDensity:=FreeShip.ProjectSettings.ProjectWaterDensity;
    //      Dialog.WaterTemper:=FreeShip.ProjectSettings.ProjectWaterTemper;
    Dialog.WaterDepth:=10000;
    // Waves
    Dialog.R0:=1.5 * Dialog.Length;
    Dialog.R1:=5.0 * Dialog.Length;
    Dialog.Beta:=22.5;
    Dialog.Nr:=100;
    Dialog.NBeta:=100;
    Dialog.X0:=1.5 * Dialog.Length;
    Dialog.X1:=5.0 * Dialog.Length;
    Dialog.Y0:=-5.0 * Dialog.Length * tan(DegToRad(30));
    Dialog.Y1:=-Dialog.Y0;
    Dialog.Nx:=100;
    Dialog.Ny:=100;

    if Dialog.Execute(FreeShip) then begin
      SaveDialog:=TSaveDialog.Create(FreeShip);
      SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
      SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '.mlt');
      SaveDialog.Filter:=createDialogFilter(rsMichletInputFile,['mlt']);
      Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
      if SaveDialog.Execute then begin WestPoint;
        Dialog.SaveToFile(ChangeFileExt(SaveDialog.FileName, '.mlt'));
      end;
      FreeAndNil(SaveDialog);
    end;
    FreeAndNil(Dialog);
//finally
    if UndoObject <> nil then UndoObject.Restore;
//end;
end;

procedure TFreeEdit.File_Import_MichletWaves;
var
  FFile: TextFile;
  Grid: array of array of T3DCoordinate;
  CtrlGrid: array of array of TFreeSubdivisionControlPoint;
  I, J, K: integer;
  Nx, Ny: integer;
  Str: ansistring;
  Tmp: string;
  Speed: string;
  P, Min, Max: T3DCoordinate;
  XArray: array of TFloatType;
  Pts: TFasterListTFreeSubdivisionControlPoint;
  Layer: TFreeSubdivisionLayer;
  AllZero: boolean;
  DecrY: integer;
  MultFact: TFloatType;
  Angle: TFloatType;
  OpenDialog: TOpenDialog;
  PrevCursor: TCursor;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rsMichletWaveElevationsFile,['mlt']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then
  begin
    assignfile(FFile, Opendialog.Filename);
    Reset(FFile);
    Readln(FFile, Str);
    Nx:=0;
    Ny:=0;
    Speed:='';
    if Str = 'RECTANGULAR PATCH' then
    begin
      readln(FFile);
      readln(FFile, Speed);
      readln(FFile);

      //Read X0, X1, Nx
      Readln(FFile, Str);
      // X0
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J - 1);
      Delete(Str, 1, J);
      // X1
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J - 1);
      Delete(Str, 1, J);
      // Nx
      Nx:=StrToInt(Str);

      //Read Y0, Y1, Ny
      Readln(FFile, Str);
      Readln(FFile, Str);
      // Y0
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J - 1);
      Delete(Str, 1, J);
      // Y1
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J - 1);
      Delete(Str, 1, J);
      // Ny
      Ny:=StrToInt(Str);

      for I:=1 to 5 do
        readln(Ffile);

      Ny:=Ny div 2; // use only port half
      // Read X distances
      Setlength(XArray, Nx);
      Readln(FFile, Str);
      J:=Pos(',', Str);
      if J <> 0 then
        Delete(Str, 1, J);
      for I:=1 to Nx do begin
        Str:=Trim(Str);
        J:=Pos(',', Str);
        if J <> 0 then begin
          Tmp:=Copy(Str, 1, J - 1);
          XArray[I - 1]:=GetFloat(Tmp);
          Delete(Str, 1, J);
        end
        else if I = Nx then XArray[I - 1]:=GetFloat(Str);
      end;

      Setlength(Grid, Ny);
      // Now read all the wave elevations
      for J:=1 to Ny do
      begin
        Readln(FFile, Str);
        Setlength(Grid[J - 1], Nx);
        for I:=0 to Nx do begin
          Str:=Trim(Str);
          K:=Pos(',', Str);
          if K <> 0 then begin
            Tmp:=Copy(Str, 1, K - 1);
            Delete(Str, 1, K);
            if I = 0 then begin
              if J = Ny then P.Y:=0
                        else P.Y:=GetFloat(Tmp);
            end else begin
              P.X:=XArray[I - 1];
              P.Z:=GetFloat(Tmp);
              Grid[J - 1][I - 1]:=P;
            end;
          end
          else if I = Nx then
          begin
            P.X:=XArray[I - 1];
            P.Z:=GetFloat(Tmp);
            Grid[J - 1][I - 1]:=P;
          end;
        end;
      end;
    end
    else if Str = 'SECTORIAL PATCH' then
    begin
      readln(FFile);
      readln(FFile, Speed);
      readln(FFile);

      //Read Nx
      Readln(FFile, Str);
      // X0
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J - 1);
      Delete(Str, 1, J);
      // X1
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J - 1);
      Delete(Str, 1, J);
      // Nx
      Nx:=StrToInt(Str);

      //Read Y0, Y1, Ny
      Readln(FFile, Str);
      Readln(FFile, Str);
      // Y0
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J - 1);
      Delete(Str, 1, J);
      // Y1
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J - 1);
      Delete(Str, 1, J);
      // Ny
      Ny:=StrToInt(Str);

      for I:=1 to 13 do readln(Ffile);

      Ny:=(Ny - 1); // use only port half
      // Read Radia
      Setlength(XArray, Nx);
      Readln(FFile, Str);
      J:=Pos(',', Str);
      if J <> 0 then Delete(Str, 1, J);
      for I:=1 to Nx do begin
        Str:=Trim(Str);
        J:=Pos(',', Str);
        if J <> 0 then begin
          Tmp:=Copy(Str, 1, J - 1);
          XArray[I - 1]:=GetFloat(Tmp);
          Delete(Str, 1, J);
        end
        else if I = Nx then XArray[I - 1]:=GetFloat(Str);
      end;

      Setlength(Grid, Ny);
      // Now read all the wave elevations
      angle:=0;
      for J:=1 to Ny do begin
        Readln(FFile, Str);
        Setlength(Grid[J - 1], Nx);
        for I:=0 to Nx do begin
          Str:=Trim(Str);
          K:=Pos(',', Str);
          if K <> 0 then begin
            Tmp:=Copy(Str, 1, K - 1);
            Delete(Str, 1, K);
            if I = 0 then begin
              if J = Ny then Angle:=0
              else Angle:=-GetFloat(Tmp);
            end else begin
              P.X:=XArray[I - 1] * Cos(DegToRad(Angle));
              P.Y:=XArray[I - 1] * Sin(DegToRad(Angle));
              P.Z:=GetFloat(Tmp);
              Grid[J - 1][I - 1]:=P;
            end;
          end
          else if I = Nx then begin
            P.X:=XArray[I - 1] * Cos(DegToRad(Angle));
            P.Y:=XArray[I - 1] * Sin(DegToRad(Angle));
            //P.X:=XArray[I-1];
            P.Z:=GetFloat(Tmp);
            Grid[J - 1][I - 1]:=P;
          end;
        end;
      end;
    end;
    if (Nx > 0) and (Ny > 0) then begin
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      FreeShip.Extents(Min, Max);
      // Search grid for strips wit zero wave-elevation height and leave these out
      MultFact:=1.0;

      Setlength(CtrlGrid, Ny);
      DecrY:=0;
      for I:=1 to Ny do begin
        AllZero:=True;
        for J:=1 to Nx do begin
          Grid[I - 1][J - 1].Z:=Grid[I - 1][J - 1].Z * MultFact;
          if abs(Grid[I - 1][J - 1].Z) > 1e-3 then begin
            AllZero:=False;
            break;
          end;
        end;
        if AllZero then Inc(DecrY);
      end;
      if DecrY > 0 then Dec(DecrY);

      // Add controlpoints
      Setlength(CtrlGrid, Ny);
      for I:=1 + DecrY to Ny do begin
        Setlength(CtrlGrid[I - 1], Nx);
        for J:=1 to Nx do begin
          if FreeShip.ProjectSettings.ProjectUnits = fuImperial then begin
            // scale to feet
            Grid[I - 1][J - 1].X:=Grid[I - 1][J - 1].X / Foot;
            Grid[I - 1][J - 1].Y:=Grid[I - 1][J - 1].Y / Foot;
            Grid[I - 1][J - 1].Z:=Grid[I - 1][J - 1].Z / Foot;
          end;
          Grid[I - 1][J - 1].X :=
            0.5 * FreeShip.ProjectSettings.ProjectLength - Grid[I - 1][J - 1].X;
          Grid[I - 1][J - 1].Z :=
            Min.Z + FreeShip.ProjectSettings.ProjectDraft + Grid[I - 1][J - 1].Z;
          CtrlGrid[I - 1][J - 1]:=TFreeSubdivisionControlPoint.Create(FreeShip.Surface);
          FreeShip.Surface.AddControlPoint(CtrlGrid[I - 1][J - 1]);
          CtrlGrid[I - 1][J - 1].Coordinate:=Grid[I - 1][J - 1];
        end;
      end;

      Pts:=TFasterListTFreeSubdivisionControlPoint.Create;
      Layer:=FreeShip.Surface.AddNewLayer;
      if Speed <> '' then Layer.Name:='Michlet waves, speed=' + speed + ' m/s'
                     else Layer.Name:='Michlet wave elevations, speed=' + speed + ' m/s';
      Layer.Color:=clAqua;
      Layer.UseInHydrostatics:=False;
      Layer.ShowInLinesplan:=False;
      Layer.UseForIntersections:=False; // Add faces to controlpoints
      for I:=DecrY + 2 to Ny do begin
        Setlength(CtrlGrid[I - 1], Nx);
        for J:=2 to Nx do begin
          Pts.Clear;
          Pts.Add(CtrlGrid[I - 1][J - 1]);
          Pts.Add(CtrlGrid[I - 1][J - 2]);
          Pts.Add(CtrlGrid[I - 2][J - 2]);
          Pts.Add(CtrlGrid[I - 2][J - 1]);
          FreeShip.Surface.AddControlFace(Pts, True, Layer);
        end;
      end;
      // set cornerpoints
      for I:=1 + DecrY to Ny do
        for J:=1 to Nx do
          if CtrlGrid[I - 1][J - 1].NumberOfFaces = 1 then
            CtrlGrid[I - 1][J - 1].VertexType:=svCorner;
      FreeAndNil(Pts);
      FreeShip.Draw;
      Screen.Cursor:=PrevCursor;
    end
    else
      MessageDlg(Userstring(102), mtError, [mbOK], 0);
    CloseFile(FFile);
    FreeShip.FileChanged:=True;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then
      FreeShip.OnUpdateGeometryInfo(self);
  end;
  FreeAndNil(OpenDialog);
end;{TFreeEdit.File_Import_MichletWaves}

procedure TFreeEdit.File_ExportObj;
var
  SaveDialog: TSaveDialog;
  Strings: TStringList;
begin
  SaveDialog:=TSaveDialog.Create(FreeShip);
  SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '.obj');
  SaveDialog.Filter:=createDialogFilter(rsWavefrontFile, ['obj']);
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if SaveDialog.Execute then begin WestPoint;
    FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
    Strings:=TStringList.Create;
    FreeShip.Surface.ExportObjFile( SaveDialog.FilterIndex=2,Strings );
    Strings.SaveToFile(ChangeFileExt( Savedialog.FileName,'.obj'));
    FreeAndNil(Strings);
  end;
  FreeAndNil(SaveDialog);
end;

// Export the surface to a STL file

// The native STL format has to fulfill the following specifications:
// 1. The normal and each vertex of every facet are specified by three coordinates each,
//    so there is a total of 12 numbers stored for each facet.
// 2. Each facet is part of the boundary between the interior and the exterior of the object.
//    The orientation of the facets is specified redundantly in two ways which must be consistent.
//    First, the direction of the normal is outward. Second, the vertices are listed in
//    counterclockwise order when looking at the object from the outside.
// 3. Each triangle must share two vertices with each of its adjacent triangles.
//    This is known as vertex-to-vertex rule.
// 4. The object represented must be located in the all-positive octant (all vertex coordinates
//    must be positive).

procedure TFreeEdit.File_ExportSTL;
var
  SaveDialog: TSaveDialog;
  FFile: TextFile;
  I, J, K, L: integer;
  Layer: TFreeSubdivisionLayer;
  Face: TFreeSubdivisionControlface;
  Child: TFreeSubdivisionface;
  C1, C2, C3: T3DCoordinate;

 {
  procedure Addfacet(P1, P2, P3: TFreeSubdivisionPoint);
  var
    Normal: T3DCoordinate;
  begin
    Normal:=UnifiedNormal(p1.Coordinate, P2.Coordinate, P3.Coordinate);
    Write(FFile, '  facet normal ');
    writeln(FFile, FloatToDec(normal.X, 4) + #32 + FloatToDec(normal.Y, 4) +
      #32 + FloatToDec(normal.Z, 4));
    writeln(FFile, '    outer loop');
    writeln(FFile, '      vertex ' + FloatToDec(P1.Coordinate.X, 4) + #32 +
      FloatToDec(P1.Coordinate.Y, 4) + #32 + FloatToDec(P1.Coordinate.Z, 4));
    writeln(FFile, '      vertex ' + FloatToDec(P2.Coordinate.X, 4) + #32 +
      FloatToDec(P2.Coordinate.Y, 4) + #32 + FloatToDec(P2.Coordinate.Z, 4));
    writeln(FFile, '      vertex ' + FloatToDec(P3.Coordinate.X, 4) + #32 +
      FloatToDec(P3.Coordinate.Y, 4) + #32 + FloatToDec(P3.Coordinate.Z, 4));
    writeln(FFile, '    endloop');
    Writeln(FFile, '  endfacet');

  end;
 }
  procedure Addfacet(C1, C2, C3: T3DCoordinate);
  var
    Normal: T3DCoordinate;
  begin
    Normal:=UnifiedNormal(C1, C2, C3);
    Write(FFile, '  facet normal ');
    writeln(FFile, FloatToDec(normal.X, 4) + #32 + FloatToDec(normal.Y, 4) +
      #32 + FloatToDec(normal.Z, 4));
    writeln(FFile, '    outer loop');
    writeln(FFile, '      vertex ' + FloatToDec(C1.X, 4) + #32 +
      FloatToDec(C1.Y, 4) + #32 + FloatToDec(C1.Z, 4));
    writeln(FFile, '      vertex ' + FloatToDec(C2.X, 4) + #32 +
      FloatToDec(C2.Y, 4) + #32 + FloatToDec(C2.Z, 4));
    writeln(FFile, '      vertex ' + FloatToDec(C3.X, 4) + #32 +
      FloatToDec(C3.Y, 4) + #32 + FloatToDec(C3.Z, 4));
    writeln(FFile, '    endloop');
    Writeln(FFile, '  endfacet');
  end;{Addfacet}
begin
  SaveDialog:=TSaveDialog.Create(FreeShip);
  SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '.stl');
  SaveDialog.Filter:=createDialogFilter(rsSTLFile, ['stl', 'txt']);
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if SaveDialog.Execute then begin WestPoint;
    FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
    AssignFile(FFile, Changefileext(SaveDialog.FileName, '.stl'));
      {$I-}
    Rewrite(FFile);
{$I+}
    if IOResult = 0 then
    begin
      // perform modelcheck to ensure normals point outward
      writeln(FFile, 'solid');
      if not FreeShip.ProjectSettings.DisableModelCheck then
        Model_Check(False);
      for I:=1 to FreeShip.Surface.NumberOfLayers do
      begin
        Layer:=FreeShip.Surface.Layer[I - 1];
        if Layer.SurfaceVisible then
          for J:=1 to Layer.Count do
          begin
            Face:=Layer.Items[J - 1];
            for K:=1 to Face.ChildCount do
            begin
              Child:=face.Child[K - 1];
              for L:=3 to Child.NumberOfpoints do
              begin
                C1:=Child.Point[0].Coordinate;
                C2:=Child.Point[L - 2].Coordinate;
                C3:=Child.Point[L - 1].Coordinate;
                AddFacet(C1, C2, C3);

                // mirror points, starboard to port
                C1.Y:=-C1.Y;
                C2.Y:=-C2.Y;
                C3.Y:=-C3.Y;
                AddFacet(C3, C2, C1);
              end;
            end;
          end;
      end;
      writeln(FFile, 'endsolid');
      Closefile(FFile);
    end
    else
      MessageDlg(Userstring(97), mtError, [mbOK], 0);
  end;
  FreeAndNil(SaveDialog);

end;{TFreeEdit.File_ExportSTL}

// imports a Carene XYZ file and creates a multichine boat with developable surfaces
procedure TFreeEdit.File_ImportCarene;
var
  OpenDialog: TOpenDialog;
  Answer: word;
  Str: string;
  I: integer;
  LineNr: integer;
  P: T3DCoordinate;
  FFile: TextFile;
  Chines: TFasterListTFreeSpline;
  Spline: TFreeSpline;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rsCareneXYZFiles, ['xyz']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin

  Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
  if (Answer=mrCancel) or FreeShip.FileChanged then begin FreeAndNil( OpenDialog ); exit; end;
 (*                                                                     ////+++
    if FreeShip.FileChanged then begin
      Answer:=MessageDlg(Userstring(103) + EOL + Userstring(104), mtConfirmation, [mbYes, mbNo, mbCancel], 0);
      if Answer = mrCancel then begin FreeAndNil( OpenDialog ); exit; end;
      if Answer = mrYes then begin
!!!     File_SaveAs;
        if FreeShip.FileChanged then begin // Apparently saving was not successfull, abort
          FreeAndNil( OpenDialog );
          exit;
        end;
      end;
    end;
*)
    CreateUndoObject(Userstring(105), True);
    FreeShip.Clear;
    assignFile(FFile, ChangeFileExt(Opendialog.FileName, '.xyz'));
{$I-}
    Reset(FFile);
{$I+}
    if IOResult = 0 then begin
      //FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
//    try
        LineNr:=1;
        Readln(FFile, Str);
        // first 18 characters are description
        Str:=Copy(Str, 1, 18);
        Str:=Trim(Str);
        FreeShip.ProjectSettings.ProjectName:=Str;
        Chines:=TFasterListTFreeSpline.Create;
        while not EOF(FFile) do
        begin
          Readln(FFile, Str);
          Inc(LineNr);
          if Pos('LINE', Str) = 1 then begin
            // New chine
            // skip one line
            if not EOF(FFile) then begin
              Readln(FFile);
              Inc(LineNr);
            end;
            if not EOF(FFile) then begin
              Spline:=TFreeSpline.Create(FreeShip.Surface);
              Chines.Add(Spline);
              repeat
                Readln(FFile, Str);
                repeat
                  I:=Pos(#9, Str);
                  if I <> 0 then Str[I]:=#32;
                until I = 0;
                Inc(LineNr);
                if Str <> '' then begin
                  P.X:=GetFloat( Str);
                  P.Y:=GetFloat( Str);
                  P.Z:=GetFloat( Str);
                  Spline.Add(P);
                  Str:=#32;
                end;
              until (EOF(FFile)) or (Str = '');
            end;
          end;
        end;
        FreeShip.ImportChines(8, Chines);
        FreeAndNil(Chines);
//    finally
        CloseFile(FFile);
        FreeShip.Filename:=ChangeFileExt(Opendialog.FileName, '.fbm');
        FreeShip.ModelIsLoaded:=True;
        FreeShip.RebuildModel;
//    end;
    end
    else
      MessageDlg(Userstring(106), mtError, [mbOK], 0);
  end;
  FreeAndNil(OpenDialog);
end;

// Import chines from a textfile and fit a surface through them
procedure TFreeEdit.File_ImportChines;
var
  OpenDialog: TOpenDialog;
  Answer: word;
  Str: string;
  I: integer;
  LineNr: integer;
  P: T3DCoordinate;
  FFile: TextFile;
  Chines: TFasterListTFreeSpline;
  Spline: TFreeSpline;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rsTextFiles, ['txt']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then
  begin
    Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
    if (Answer=mrCancel) or FreeShip.FileChanged then begin FreeAndNil( OpenDialog ); exit; end;
(*                                                                      ////+++
    if FreeShip.FileChanged then  begin
      Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes, mbNo, mbCancel],0);
      if Answer = mrCancel then begin FreeAndNil(OpenDialog); exit; end;
      if Answer = mrYes then begin
!!!     File_SaveAs;            // Apparently saving was not successfull, abort
        if FreeShip.FileChanged then begin
           FreeAndNil( OpenDialog ); exit;
        end;
      end;
    end;
*)
    CreateUndoObject(Userstring(107), True);
    FreeShip.Clear;
    assignFile(FFile, ChangeFileExt(Opendialog.FileName, '.txt'));
{$I-}
    Reset(FFile);
{$I+}
    if IOResult = 0 then begin
      //FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      LineNr:=1;
      Chines:=TFasterListTFreeSpline.Create;
//    try
//      try
          // first read unit information; 0=metric, 1=imperial
          readln(FFile, I);
          if I in [0, 1]
            then FreeShip.ProjectSettings.ProjectUnits:=TFreeUnitType(I)
            else MessageDlg(Userstring(108), mtError, [mbOK], 0);
          Spline:=TFreeSpline.Create(FreeShip.Surface);
          repeat
            Readln(FFile, Str);
            repeat
              i:=Pos(#9, Str);
              if I <> 0 then str[I]:=#32;
            until I = 0;
            Inc(LineNr);
            Str:=Trim(Uppercase(Str));
            if (Str <> '') and (Str <> 'EOF') then begin
              P.X:=GetFloat( Str);
              P.Y:=GetFloat( Str);
              P.Z:=GetFloat( Str);
              Spline.Add(P);
              Str:=#32;
            end else if Str = '' then begin
              if Spline.NumberOfPoints > 1
                 then Chines.Add(Spline)
                 else FreeAndNil(Spline);
              Spline:=TFreeSpline.Create(FreeShip.Surface);
            end;
          until (Str = 'EOF') or (EOF(FFile));
          if Spline.NumberOfPoints > 1 then Chines.Add( Spline )
          else
            FreeAndNil(Spline);
//        except
//          MessageDlg('Error on line ' + IntToStr(LineNr) + ' in file ' +
//            Opendialog.Filename, mtError, [mbOK], 0);
//        end;
        FreeShip.ImportChines(8, Chines);
        FreeAndNil(Chines);
//    finally
        CloseFile(FFile);
        FreeShip.Filename:=ChangeFileExt(Opendialog.FileName, '.fbm');
        if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
        FreeShip.ModelIsLoaded:=True;
        FreeShip.RebuildModel;
//    end;
    end
    else
      MessageDlg(Userstring(106), mtError, [mbOK], 0);
  end;
  FreeAndNil(OpenDialog);
end;

// Import a Freeship Exchange Format (FEF) file
procedure TFreeEdit.File_ImportFEF;
var
  OpenDialog: TOpenDialog;
  Answer: word;
  Strings: TStringList;
  Str: string;
  LineNr, I: integer;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rsFREEShipExchangeFormatFile, ['part']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
    Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
    if (Answer=mrCancel) or FreeShip.FileChanged then begin FreeAndNil( OpenDialog ); exit; end;
(*                                                                      ////+++
    if FreeShip.FileChanged then begin
      Answer:=MessageDlg(Userstring(103) + EOL + Userstring(104),
        mtConfirmation, [mbYes, mbNo, mbCancel], 0);
      if Answer = mrCancel then begin FreeAndNil(OpenDialog); exit; end;
      if Answer = mrYes then begin
!!!     File_SaveAs;
        if FreeShip.FileChanged then begin // Apparently saving was not successfull, abort
          FreeAndNil(OpenDialog);
          exit;
        end;
      end;
    end;
*)
    FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
    CreateUndoObject(Userstring(109), True);
    FreeShip.Clear;
    Strings:=TStringList.Create;
    Strings.LoadFromFile(OpenDialog.Filename);
    LineNr:=-1;
    // Read general information and mainparticulars
    Inc(LineNr);
    FreeShip.ProjectSettings.ProjectName:=Strings[LineNr];
    Inc(LineNr);
    FreeShip.ProjectSettings.ProjectDesigner:=Strings[LineNr];
    Inc(LineNr);
    FreeShip.ProjectSettings.FProjectFileCreatedBy:=Strings[LineNr];
    Inc(LineNr);
    FreeShip.ProjectSettings.FProjectComment:=Strings[LineNr];
    Inc(LineNr);
    Str:=Strings[LineNr];
    FreeShip.ProjectSettings.ProjectLength:=GetFloat( Str);
    FreeShip.ProjectSettings.ProjectBeam:=GetFloat( Str);
    FreeShip.ProjectSettings.ProjectDraft:=GetFloat( Str);
    FreeShip.ProjectSettings.ProjectWaterDensity:=GetFloat( Str);
    //      FreeShip.ProjectSettings.ProjectWaterTemper:=GetFloat( Str);
    FreeShip.ProjectSettings.ProjectAppendageCoefficient:=GetFloat( Str);
    I:=GetInteger( Str);
    FreeShip.ProjectSettings.FProjectUnits:=TFreeUnitType(I);
    FreeShip.ProjectSettings.FMainparticularsHasBeenset :=GetBoolean( Str);
    I:=GetInteger( Str);
    FreeShip.FPrecision:=TFreePrecisionType(I);
    FreeShip.Surface.ImportFEFFile(Strings, LineNr);
    FreeAndNil(Strings);
    FreeShip.FileName:=Opendialog.FileName;
    FreeShip.ModelIsLoaded:=True;
    FreeShip.Built:=False;
    FreeShip.RebuildModel;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then
      FreeShip.OnUpdateGeometryInfo(self);
  end;
  FreeAndNil(OpenDialog);
end;{TFreeEdit.File_ImportFEF}

// Imports a file created with Carlssons's Hulls program
procedure TFreeEdit.File_ImportHull;
var
  OpenDialog: TOpenDialog;
  Answer: word;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rsCarlssonHullFiles, ['hul']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then
  begin
    Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
    if (Answer=mrCancel) or FreeShip.FileChanged then begin FreeAndNil( OpenDialog ); exit; end;
(*                                                                      ////+++
    if FreeShip.FileChanged then begin
      Answer:=MessageDlg(Userstring(103) + EOL + Userstring(104),
        mtConfirmation, [mbYes, mbNo, mbCancel], 0);
      if Answer = mrCancel then begin FreeAndNil(OpenDialog); exit; end;
      if Answer = mrYes then begin
|||     File_SaveAs;
        if FreeShip.FileChanged then begin // Apparently saving was not successfull, abort
          FreeAndNil(OpenDialog); exit;
        end;
      end;
    end;
*)
    CreateUndoObject(UserString(110), True);
    File_ImportHull(OpenDialog.FileName, False);
    FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
  end;
  FreeAndNil( OpenDialog );
end;

procedure TFreeEdit.File_ImportHull(Filename: string; Quiet: boolean);
var
  I, J: integer;
  NBulkHeads: integer;
  P, Min, Max: T3DCoordinate;
  FFile: TextFile;
  NoChines: integer;
  Value: TFloatType;
  Points: array of array of T3DCoordinate;
  Chines: TFasterListTFreeSpline;
  Spline: TFreeSpline;
  Str: string;
  Skip: boolean;
begin
  FreeShip.Clear;
  assignFile(FFile, ChangeFileExt(FileName, '.hul'));
   {$I-}
  Reset(FFile);
{$I+}
  if IOResult = 0 then
  begin
//  try
      Readln(FFile, NoChines);
      NBulkHeads:=5;
      Setlength(Points, NBulkHeads);
      for I:=1 to NBulkHeads do
      begin
        Setlength(Points[I - 1], NoChines);
        for J:=1 to NoChines do
        begin
          Readln(FFile, P.Y);
          Readln(FFile, P.Z);
          Readln(FFile, P.X);
          // scale from inches to meters
          P.X:=P.X * 0.0254;
          P.Y:=P.Y * 0.0254;
          P.Z:=P.Z * 0.0254;
          if (I = 1) and (J = 1) then
          begin
            Min:=P;
            Max:=Min;
          end
          else
            MinMax(P, Min, Max);
          Points[I - 1][J - 1]:=P;
        end;
      end;
      Readln(FFile);
      if Quiet then
        Skip:=True
      else
        Skip:=MessageDlg(Userstring(111), mtConfirmation, [mbYes, mbNo], 0) = mrNo;
      if not skip then
      begin
        NBulkHeads:=13;
        Setlength(Points, NBulkHeads);
        for I:=1 to NBulkHeads do
        begin
          Setlength(Points[I - 1], NoChines);
          for J:=1 to NoChines do
          begin
            Readln(FFile, P.Y);
            Readln(FFile, P.Z);
            Readln(FFile, P.X);
            // scale from inches to meters
            P.X:=P.X * 0.0254;
            P.Y:=P.Y * 0.0254;
            P.Z:=P.Z * 0.0254;
            if (I = 1) and (J = 1) then
            begin
              Min:=P;
              Max:=Min;
            end
            else
              MinMax(P, Min, Max);
            Points[I - 1][J - 1]:=P;
          end;
        end;
      end
      else
        for I:=1 to 13 do
          for J:=1 to NoChines do
          begin
            Readln(FFile);
            Readln(FFile);
            Readln(FFile);
          end;

      Chines:=TFasterListTFreeSpline.Create;
      for I:=1 to NoChines do
      begin
        for J:=1 to NBulkheads do
        begin
          P:=Points[J - 1, I - 1];
          P.X:=-P.X + Max.X;
          Points[J - 1, I - 1]:=P;
        end;
        Spline:=TFreeSpline.Create(FreeShip.Surface);
        Chines.Add(Spline);
        for J:=1 to NBulkheads do
        begin
          P:=Points[J - 1, I - 1];
          Spline.Add(P);
          Spline.Knuckle[J - 1]:=False;
        end;
      end;
      FreeShip.ImportChines(NBulkheads, Chines);
      FreeAndNil(Chines);
      // read stations
      for I:=1 to 8 do
      begin
        Readln(FFile, Value);
        Intersection_Add(fiStation, -Value * 0.024 + Max.X);
      end;

      // Skip rig info
      for I:=1 to 9 do
        Readln(FFile);

      // Read designer info
      Readln(FFile, Str);
      FreeShip.ProjectSettings.ProjectDesigner:=Str;
      Readln(FFile, Str);
      FreeShip.ProjectSettings.ProjectName:=Str;
//  finally
      CloseFile(FFile);
      FreeShip.ProjectSettings.ProjectWaterDensity:=1.0;
      FreeShip.ProjectSettings.ProjectUnits:=fuImperial;
      FreeShip.ProjectSettings.ProjectDraft:=1.0;
      FreeShip.FileName:=ChangeFileExt(FileName, '');
      FreeShip.ModelIsLoaded:=True;
      FreeShip.RebuildModel;
      //FreeShip.Draw;
//  end;
  end
  else
    MessageDlg(Userstring(106), mtError, [mbOK], 0);
end;

// Import a partfile and add it to the current geometry
procedure TFreeEdit.File_ImportPart;
var
  OpenDialog: TOpenDialog;
  PartFile: TFreeFileBuffer;
  vUndo: TFreeUndoObject;
  PartUnits: TFreeUnitType;
  Changed: boolean;
  Crease: boolean;
  I, J, N, Np: integer;
  Ind1, Ind2: integer;
  LayerID: integer;
  PartVersion: TFreeFileversion;
  Str: string;
  Scale: TFloatType;
  Points: TFasterListTFreeSubdivisionControlPoint;
  Edges: TFasterListTFreeSubdivisionControlEdge;
  Layers: TFasterListTFreeSubdivisionLayer;
  FacePoints: TFasterListTFreeSubdivisionControlPoint;
  Edge: TFreeSubdivisionControlEdge;
  P1, P2: TFreeSubdivisionControlPoint;
  Curve: TFreeSubdivisionControlCurve;
  Layer: TFreeSubdivisionLayer;
  PrevCursor: TCursor;

begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rsFREEShipGeometryPart, ['part']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then
  begin
    PartFile:=TFreeFileBuffer.Create;
    //FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
    Changed:=False;
    vUndo:=CreateUndoObject(Userstring(112), False);
    //Partfile.LoadFromFile(ChangeFileExt(OpenDialog.FileName, '.part'));
    Partfile.LoadFromFile(OpenDialog.FileName);
    Partfile.LoadString(Str);
    if Str = 'FREE!ship partfile' then
    begin
      // Load fileversion
      Partfile.LoadInteger(I);
      if I <= Ord(CurrentVersion) then
      begin
        PrevCursor:=Screen.Cursor;
        Screen.Cursor:=crHourglass;
//      try
          Partversion:=TFreeFileVersion(I);
          Partfile.Version:=PartVersion;
          Points:=TFasterListTFreeSubdivisionControlPoint.Create;
          Edges:=TFasterListTFreeSubdivisionControlEdge.Create;
          Layers:=TFasterListTFreeSubdivisionLayer.Create;
          // Load units
          Partfile.LoadInteger(I);
          PartUnits:=TFreeUnitType(I);
          if PartUnits <> FreeShip.ProjectSettings.ProjectUnits then
          begin
            if PartUnits = fuMetric then
              Scale:=1 / Foot
            // Part units=metric and projectunits=imperial, scale from meters to feet
            else
              scale:=Foot;
            // Part units=imperial and projectunits=metric, scale from feet to meters
          end
          else
            Scale:=1.0;
          // Load number of layers
          Partfile.LoadInteger(N);
          Layers.Capacity:=N;
          for I:=1 to N do
          begin
            Layer:=FreeShip.Surface.AddNewLayer;
            LayerID:=Layer.LayerID;
            Layer.LoadBinary(Partfile);
            Layer.LayerID:=LayerID;
            Layers.Add(Layer);
            Changed:=True;
          end;
          // Number of controlpoints
          Partfile.LoadInteger(N);
          Points.Capacity:=N;
          for I:=1 to N do
          begin
            P2:=TFreeSubdivisionControlPoint.Create(FreeShip.Surface);
            FreeShip.Surface.AddControlPoint(P2);
            P2.LoadBinary(PartFile);
            P2.Coordinate:=ScalePoint(Scale, P2.Coordinate);
            Points.Add(P2);
            Changed:=True;
          end;
          // Load control edges
          Partfile.LoadInteger(N);
          Edges.Capacity:=N;
          for I:=1 to N do
          begin
            Partfile.LoadInteger(Ind1);
            Partfile.LoadInteger(Ind2);
            if (Ind1 <> -1) and (Ind2 <> -1) then
            begin
              P1:=Points[ind1];
              P2:=Points[ind2];
              Edge:=FreeShip.Surface.AddControlEdge(P1, P2);
            end
            else
              Edge:=nil;
            Partfile.LoadBoolean(Crease);
            if Edge <> nil then
              Edge.Crease:=Crease;
            Changed:=True;
          end;
          // Load controlfaces
          Partfile.LoadInteger(N);
          FacePoints:=TFasterListTFreeSubdivisionControlPoint.Create;
          for I:=1 to N do
          begin
            Partfile.LoadInteger(Np);
            FacePoints.Clear;
            FacePoints.Capacity:=N;
            for J:=1 to Np do
            begin
              Partfile.LoadInteger(Ind1);
              P2:=Points[ind1];
              FacePoints.Add(P2);
            end;
            Partfile.LoadInteger(Ind2);
            Layer:=Layers[ind2];
            FreeShip.Surface.AddControlFace(FacePoints, False, Layer);
          end;
          for I:=1 to Edges.Count do
          begin
            Edge:=Edges[I - 1];
            if (Edge.NumberOfFaces <> 2) and (not Edge.Crease) then
              Edge.Crease:=True;
          end;
          // Load controlcurves
          Partfile.LoadInteger(N);
          for I:=1 to N do
          begin
            Partfile.LoadInteger(Np);
            if Np > 1 then
            begin
              Curve:=TFreeSubdivisionControlCurve.Create(FreeShip.Surface);
              FreeShip.Surface.AddControlCurve(Curve);
              for J:=1 to Np do
              begin
                Partfile.LoadInteger(Ind1);
                P2:=Points[ind1];
                Curve.AddPoint(P2);
                if J > 1 then
                begin
                  P1:=Curve.ControlPoint[J - 2];
                  Edge:=FreeShip.Surface.EdgeExists(P1, P2) as
                    TFreeSubdivisionControlEdge;
                  if Edge <> nil then
                    edge.Curve:=Curve;
                end;
              end;
            end;
          end;
          FreeAndNil(FacePoints);
          FreeAndNil(Points);
          FreeAndNil(Edges);
          FreeAndNil(Layers);
//      finally
          Screen.Cursor:=Prevcursor;
//      end;
        if Changed then begin
          if Assigned(FreeShip.Surface.OnChangeLayerData) then
            FreeShip.Surface.OnChangeLayerData(FreeShip.Surface);
          vUndo.Accept;
          FreeShip.Built:=False;
          FreeShip.Draw;
          FreeShip.FileChanged:=True;
          if assigned(FreeShip.OnUpdateGeometryInfo) then
            FreeShip.OnUpdateGeometryInfo(FreeShip);
        end;
      end else MessageDlg(UserString(113), mtError, [mbOK], 0);
    end else MessageDlg(Userstring(114), mtError, [mbOK], 0);
    if not Changed then vUndo.Delete;
    FreeAndNil(Partfile);
  end;
  FreeAndNil(OpenDialog);
end;

// Imports a PolyCad file
procedure TFreeEdit.File_ImportPolycad;
var
  OpenDialog: TOpenDialog;
  Answer: word;
  PrevCursor: TCursor;
  Strings: TStringList;
  I, J, K, N: integer;
  Cols, Rows: integer;
  Index: integer;
  NSurfaces: integer;
  Indices: array of integer;
  Str, Tmp: string;
  Abort: boolean;
  Points: TFreeCoordinateGrid;
  Value: TFloatType;
  P: T3DCoordinate;

  function Next_Line: string;
  begin
    if Index + 1 < Strings.Count then begin
      Inc(Index); Result:=Strings[index];
    end else begin
      Result:='';
      Abort:=True;
      MessageDlg(UserString(115), mtError, [mbOK], 0);
    end;
  end;{NextLine}

  function Get_Integer( const Str: string): integer;
  var Index: integer;
  begin
    Index:=Pos('=', Str);
    Result:=0;
    if Index<>0 then Result:=GetInteger( Copy( Str,Index+1,Length(Str)-Index ));
  end;{GetInteger}

  function Get_Float( const Str: string): TFloatType;
  var Index: integer;
  begin
    Index:=Pos( '=',Str );
    Result:=0;
    if Index<>0 then Result:=GetFloat( Copy(Str,Index+1,Length(Str)-Index) );
  end;{GetFloat}

  function NextParameter(var input: string): string;
  var Index: integer;
  begin
    Index:=pos(#32, Input);
    if Index <> 0 then begin
      Result:=Copy(Input, 1, Index - 1);
      Delete(Input, 1, Index);
      Input:=Trim(Input);
    end else begin
      Result:='';
      Abort:=True;
    end;
  end;{NextParameter}

begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rsPolyCadFiles, ['geo']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then
  begin
    Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
    if (Answer=mrCancel) or FreeShip.FileChanged then begin FreeAndNil( OpenDialog ); exit; end;
(*                                                                      ////+++
    if FreeShip.FileChanged then begin
      Answer:=MessageDlg(Userstring(103) + EOL + Userstring(104),
        mtConfirmation, [mbYes, mbNo, mbCancel], 0);
      if Answer = mrCancel then begin FreeAndNil(OpenDialog); exit; end;
      if Answer = mrYes then begin
!!!     File_SaveAs;
        if FreeShip.FileChanged then begin // Apparently saving was not successfull, abort
          FreeAndNil(OpenDialog);
          exit;
        end;
      end;
    end;
*)
    PrevCursor:=Screen.Cursor;
    Screen.Cursor:=crHourglass;
    Strings:=TStringList.Create;
//  try
      Strings.LoadFromFile(OpenDialog.FileName);
      for I:=Strings.Count downto 1 do
        if Strings[I-1] = '' then Strings.Delete(I-1);  // delete empty strings
      NSurfaces:=0;                       // count number of BSpline surfaces
      for I:=1 to strings.Count do
        if (pos('[TBSplineSurface]', Strings[I - 1]) <> 0)
        or (pos('[TShipLines]', Strings[I - 1]) <> 0)
        or (pos('[TYachtLines]', Strings[I - 1]) <> 0) then  begin
          Setlength(Indices, NSurfaces + 1);
          Indices[NSurfaces]:=I - 1;
          Inc(NSurfaces);
        end;
      if NSurfaces > 0 then begin
        CreateUndoObject(Userstring(118), True);
        FreeShip.Clear;
        FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
        I:=1;
        Abort:=False;
        while (I <= NSurfaces) and (not Abort) do begin
          Index:=Indices[I - 1];
          Str:=Strings[index];
          if (pos('[TYachtLines]', Strings[I - 1]) <> 0) then begin // Read loa
            Str:=Next_Line;
            FreeShip.ProjectSettings.ProjectLength:=Get_Float(Str);
            Next_Line;
            Next_Line;
            // read beam over all
            Str:=Next_Line;
            FreeShip.ProjectSettings.ProjectBeam:=Get_Float(Str);
            Next_Line;
            Next_Line;
            // Read draft
            Str:=Next_Line;
            FreeShip.ProjectSettings.ProjectDraft:=Get_Float(Str);
            FreeShip.ProjectSettings.FMainparticularsHasBeenset:=True;
            for J:=1 to 12 do Next_Line;
          end
          else if (pos('[TShipLines]', Strings[I - 1]) <> 0) then begin
            Next_Line;
            // Read length
            Str:=Next_Line;
            FreeShip.ProjectSettings.ProjectLength:=Get_Float(Str);
            // read beam
            Str:=Next_Line;
            FreeShip.ProjectSettings.ProjectBeam:=Get_Float(Str);
            // skip depth
            Next_Line;
            // Read draft
            Str:=Next_Line;
            FreeShip.ProjectSettings.ProjectDraft:=Get_Float(Str);
            FreeShip.ProjectSettings.FMainparticularsHasBeenset:=True;
            for J:=1 to 22 do Next_Line;
          end;

          Next_Line;            // skip OrderU=
          Next_Line;            // skip OrderV=

          // Read number of columns
          Str:=Next_Line;
          Cols:=Get_Integer(Str);
          // Read number of rows
          Str:=Next_Line;
          Rows:=Get_Integer(Str);
          if (Cols > 1) and (Rows > 1) then begin
            // Initialize points
            Setlength(Points, Rows);
            for J:=1 to Rows do begin
              Setlength(Points[J - 1], Cols);
              for K:=1 to Cols do
                Points[J - 1][K - 1]:=ZERO;
            end;
            for J:=1 to Cols do begin
              for K:=1 to Rows do begin
                Str:=Next_Line;
                if not abort then begin
                  Str:=Trim(Str);
                  P.X:=0;
                  P.Y:=0;
                  P.Z:=0;
                  // X coordinate
                  Tmp:=NextParameter(Str);
                  if not abort then begin
                    Val(Tmp, P.X, N);
                    if N <> 0 then begin
                      MessageDlg(Userstring(119) + #32 +
                        IntToStr(I), mtError, [mbOK], 0);
                      Abort:=True;
                    end;
                  end;
                  if not Abort then begin
                    Tmp:=NextParameter(Str);
                    if not abort then begin
                      Val(Tmp, P.Y, N);
                      if N <> 0 then begin
                        MessageDlg(Userstring(120) + #32 +
                          IntToStr(I), mtError, [mbOK], 0);
                        Abort:=True;
                      end;
                    end;
                  end;
                  if not Abort then begin                      // Z coordinate
                    Tmp:=NextParameter(Str);
                    if not abort then begin
                      Val(Tmp, P.Z, N);
                      if N <> 0 then begin
                        MessageDlg(Userstring(121) + #32 +
                          IntToStr(I), mtError, [mbOK], 0);
                        Abort:=True;
                      end;
                    end;
                  end;
                  Points[K - 1][J - 1]:=P;
                end else break;
              end;
              if abort then break;
            end;
            if not Abort then
              FreeShip.Surface.ImportCoordGrid(Points, Cols, Rows, nil);
          end;
          Inc(i);
        end;
        if not Abort then begin                               // Read contours;
          for I:=1 to Strings.Count do
            if Pos('[TContours]', Strings[I - 1]) <> 0 then begin
              Index:=I - 1;
              Str:=Next_Line;
              N:=Get_Integer(Str);
              if not abort then
                for J:=1 to N do begin
                  Str:=Next_Line;
                  if not abort then begin
                    Str:=Trim(Str);
                    Tmp:=NextParameter(Str);
                    if not abort
                      then K:=StrToInt(Tmp)// 1=station, 2=buttock, 3=waterline
                      else K:=0;
                    if not abort then begin
                      Val(Str, Value, N);
                      if N <> 0 then begin
                        MessageDlg(Userstring(122), mtError, [mbOK], 0);
                        Abort:=True;
                      end else
                        case K of
                          1: self.Intersection_Add(fiStation, Value);
                          2: if Value >= 0 then
                              self.Intersection_Add(fiButtock, Value);
                          3: self.Intersection_Add(fiWaterline, Value);
                        end;
                    end;
                  end;
                  if abort then break;
                end;
              break;
            end;
          FreeShip.Precision:=fpMedium;
          FreeShip.FileName:=ChangeFileExt(Opendialog.FileName, '');
          FreeShip.ModelIsLoaded:=True;
          FreeShip.RebuildModel;
          FreeShip.FileChanged:=True;
        end else MessageDlg(UserString(123), mtInformation, [mbOK], 0);
      end else MessageDlg(UserString(124), mtInformation, [mbOK], 0);
//  finally
      FreeAndNil(Strings);
      if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
      Screen.Cursor:=PrevCursor;
//  end;
  end;
  FreeAndNil(OpenDialog);
end;

// Load a VRML file
procedure TFreeEdit.File_ImportVRML;
var
  OpenDialog: TOpenDialog;
  Answer: word;
  PrevCursor: TCursor;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rsVRMLFiles, ['wrl', 'vrml']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then
  begin
    Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
    if (Answer=mrCancel) or FreeShip.FileChanged then begin FreeAndNil( OpenDialog ); exit; end;
(*                                                                      ////+++
    if FreeShip.FileChanged then begin
      Answer:=MessageDlg(Userstring(103) + EOL + Userstring(104),mtConfirmation, [mbYes, mbNo, mbCancel], 0);
      if Answer = mrCancel then begin FreeAndNil(OpenDialog); exit; end;
      if Answer = mrYes then begin
!!!     File_SaveAs;
        if FreeShip.FileChanged then begin // Apparently saving was not successfull, abort
          FreeAndNil(OpenDialog); exit;
        end;
      end;
    end;
*)
    PrevCursor:=Screen.Cursor;
    Screen.Cursor:=crHourglass;
//  try
      CreateUndoObject(Userstring(125), True);
//    FreeShip.Clear;                                        //FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      FreeShip.Surface.LoadVRMLFile( Opendialog.FileName );
//    if FreeShip.Surface.FIsLoading then
      begin
          FreeShip.ModelIsLoaded:=True;
          FreeShip.FileName:=ChangeFileExt(Opendialog.FileName, '');
          FreeShip.RebuildModel;
          FreeShip.FileChanged:=True;
      end;
//  finally
      if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
      Screen.Cursor:=PrevCursor;
//  end;
  end;
  FreeAndNil(OpenDialog);
end;

procedure TFreeEdit.OnFaceRebuilt (Sender: TObject; current:integer; total:integer);
var P:integer;
begin
  if FProgressBar = nil then exit;
  P:=current * 10 div total;
  if P<>FProgressBar.Position then begin
    FProgressBar.Max:=10;
    FProgressBar.Position :=P;
    //for some reason in GTK2 ProgressBar does not refresh unless Label is refreshed. weird.
    Main.MainForm.LabelProgress.Caption:=format('%d / %d',[current,total]);
    Main.MainForm.LabelProgress.Refresh;
    Application.ProcessMessages;
    end;
end;

function TFreeEdit.getPreviewImage(aFileName: string): TJPegImage;
var
  TempFreeShip: TFreeShip;
  vp: TFreeViewPort;
//  thumbNail: TBitmap;
  Source: TFreeFileBuffer;
  ext: string;
  pvWidth, pvHeight: integer;
begin
  if not FileExists( aFileName ) then exit;
  pvWidth:=600;
  pvHeight:=400;
  Result:=TJPegImage.Create;
  TempFreeShip:=TFreeShip.Create(nil);
  try
      TempFreeShip.Clear;
      TempFreeShip.LoadPreview( aFileName,Result );
      if not assigned( Result ) or ( Result.Width=0 ) then begin
        Ext:=LowerCase(ExtractFileExt(aFileName));
        if Ext = '.fbm' then Source:=TFreeFileBuffer.Create else
        if Ext = '.ftm' then Source:=TFreeTextBuffer.Create else
           begin WriteLN( 'Unsupported file format: ' + Ext); exit; end;

        TempFreeShip.ModelIsLoaded:=False;
        Source.LoadFromFile( aFileName );       // Load everything into memory
        // TempFreeShip.Preferences.OpenDirectory:=ExtractFilePath(aFileName);
        TempFreeShip.Filename:=aFileName;
        TempFreeShip.LoadProject( Source ); // Now read the information from memory

        TempFreeShip.Surface.DesiredSubdivisionLevel:=0; // no need to build it in preview in very details
        if not TempFreeShip.Visibility.ShowControlNet
           and TempFreeShip.Visibility.ShowInteriorEdges
          then TempFreeShip.Surface.DesiredSubdivisionLevel:=1;

    //  if assigned(FOnFaceRebuilt) then FOnFaceRebuilt( self,I+1,NumberOfControlFaces );
        TempFreeShip.Surface.OnFaceRebuilt:=@OnFaceRebuilt;

        TempFreeShip.ModelIsLoaded:=True;
    //  TempFreeShip.Preferences.Load;

        vp:=TFreeViewPort.Create(nil);
        with vp do begin
          CameraType:=ftStandard;
          Color:=10461087;
          DoubleBuffer:=True;
          Angle:=30;
          Elevation:=20;
          PopupMenu:=PopupMenu;
          ViewType:=fvPerspective;
          ViewportMode:=vmWireFrame;    // vmShade; //
          Width:=pvWidth;
          Height:=pvHeight;
        end;
//        vp.DestinationWidth :=pvWidth;  // shadow does not work here
//        vp.DestinationHeight:=pvHeight;
//        vp.ZBuffer.Initialize;
//        vp.AlphaBuffer.Initialize;
        Result.PixelFormat:=pf24bit;
        Result.SetSize( pvWidth,pvHeight );
        Result.Canvas.AntialiasingMode:=amOn;
        vp.DrawingCanvas:=Result.Canvas;
        TempFreeShip.AddViewport( vp );
        // fill background
        vp.BrushColor:=vp.Color;
        vp.Rectangle( 0,0,pvWidth,pvHeight );
        vp.ZoomExtents;
        TempFreeShip.DrawToViewport( vp );
        vp.Free;
      end;
  finally
    TempFreeShip.Free;
  end;
end;

resourcestring
  FileDialogFilterFreeship = 'FreeShip files (*.ftm *.fbm)|*.ftm;*.fbm';
  FileDialogFilterFreeshipText = 'FreeShip Text (*.ftm)|*.ftm';
  FileDialogFilterFreeshipBinary = 'FreeShip Binary (*.fbm)|*.fbm';
  FileDialogFilterAll = 'All|*';
  FileDialogPlaceLast = 'Last';
  FileDialogPlaceMyShips = 'My Ships';
  FileDialogPlaceMyImport = 'My Import';
//FileDialogPlaceGlobalShips = 'Global Ships';
//FileDialogPlaceGlobalImport = 'Global Import';
  rsFreeShipFiles = 'FreeShip files';
  rsFreeShipTextFiles = 'FreeShip Text files';
  rsFreeShipBinaryFiles = 'FreeShip Binary files';


procedure TFreeEdit.File_Load;
var Answer     : word;
    OpenDialog : TOpenDialog;
begin
   OpenDialog:=TOpenDialog.Create( FreeShip );
   OpenDialog.InitialDir:=FreeShip.Preferences.OpenDirectory;
// OpenDialog.Filter:='FREE!ship files (*.fbm)|*.fbm';
   OpenDialog.Filter:=createDialogFilter(rsFreeShipFiles,['fbm','ftm'],False )
              + '|' + createDialogFilter(rsFreeShipTextFiles,['ftm'],False)
              + '|' + createDialogFilter(rsFreeShipBinaryFiles,['fbm'] );
   Opendialog.Options:=[ofHideReadOnly];
  try
     if OpenDialog.Execute then begin
        Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
        if (Answer=mrCancel) or FreeShip.FileChanged then exit;
        File_Load( Opendialog.FileName );        // Load everything into memory
     end;
  finally
     Opendialog.Destroy;
  end
end;

procedure TFreeEdit.File_Load( FileName: string );
var
  Source: TFreeFileBuffer; I: Integer;
  ext: string;
begin
  if FileName = '' then exit;
  Ext:=LowerCase( ExtractFileExt( FileName ) );
  if Ext = '.fbm' then Source:=TFreeFileBuffer.Create else
  if Ext = '.ftm' then Source:=TFreeTextBuffer.Create else
     begin WriteLN( 'Unsupported file format: ' + Ext); halt; end;
  try
    FreeShip.Surface.Clearselection;    // Make sure no items are selected
    FreeShip.FSelectedFlowlines.Clear;
    FreeShip.FSelectedMarkers.Clear;
    FreeShip.ModelIsLoaded:=False;
    FreeShip.FileIsReadOnly:=True;
    Source.LoadFromFile( FileName );
    FreeShip.Filename:=FileName;
    FreeShip.LoadProject( Source );
//  if FileExists( FreeShip.Filename ) then
    FreeShip.FileIsReadOnly:=( FileGetAttr( FileName ) and faReadOnly )<>0;
    FreeShip.FFilenameSet:=True;
    FreeShip.FStopAskingForFileVersion:=False;
    FreeShip.ModelIsLoaded:=True;
    Application.ProcessMessages;
    with FreeShip do begin
      ZoomFitAllViewports;
      Surface.Rebuild;
      for I:=0 to NumberofBackgroundImages-1 do BackgroundImage[I].UpdateViews;
      Draw;
    end;
    TMainForm(MainForm).SetCaption;
    TMainForm(MainForm).UpdateMenu;
  finally
    FreeAndNil( Source );
    if FreeShip.ModelIsLoaded then AddToRecentFiles( FileName );
    Undo_Clear;
  end;
  FreeShip.FileChanged:=False;
end;

resourcestring
//rsUnableDeleteBackupFile='Unable to delete backup file';
//rsUnableCreateBackupFile='Unable to create backup file';
  rsSaveWithHigherFileVersion='The current file version is %s.%sDo you want to save the file as version %s ?';
//rsUnableToSaveFile='Unable to save file';

// save as FREE!ship file without prompting for a filename (must already been set)

function TFreeEdit.File_Save: boolean;
var
  Backup, Str, Ext: string;
  Destination: TFreeFileBuffer;
  Answer: word;
  fAttr:longint;  fh:THandle;
  MinFileVersion: TFreeFileVersion;
begin
  result:=false;
{  if FileExistsUTF8(FreeShip.Filename) then begin
    fh:=FileOpenUTF8(FreeShip.Filename, fmOpenWrite);
    if fh = 0 then FreeShip.ModelIsReadOnly:=true;
    FileClose(fh);
  end else begin
    fh:=FileCreateUTF8(FreeShip.Filename);
    if fh = 0 then FreeShip.ModelIsReadOnly:=true;
    FileClose(fh);
  end;
}
  if not FreeShip.FilenameSet or FreeShip.FileIsReadOnly then
  begin FreeShip.FilenameSet:=false; result:=File_SaveAs; exit;
  end;

  if not FreeShip.FilenameSet then exit;

  MinFileVersion:=FreeShip.DetectMinFileVersion;

  if (FreeShip.FileVersion < MinFileVersion) //and (not FreeShip.FStopAskingForFileVersion)
  then begin
    Str:=format(rsSaveWithHigherFileVersion,[VersionString(FreeShip.FileVersion),EOL,VersionString(MinFileVersion)]);
    Answer:=MessageDlg(Str, mtInformation, [mbYes, mbNo], 0);
    if Answer = mrYes then FreeShip.FileVersion:=MinFileVersion
    else exit;                    //FreeShip.FStopAskingForFileVersion:=True;
  end
  else FreeShip.FileVersion:=MinFileVersion;

  FreeShip.FFilenameSet:=True;
  // Check if the file already exists
  if FileExistsUTF8(FreeShip.Filename) then
  begin
    Backup:=ChangeFileExt(FreeShip.Filename, '.Bak'); // First check for a backup, and delete when present
    if FileExistsUTF8(Backup)  then
      if not DeleteFileUTF8(Backup) then begin
        MessageDlg( 'Unable to delete backup file '+Backup, mtError, [mbOK], 0);
        FreeShip.FileIsReadOnly:=true;
        result:=false;
        exit;
      end;
    // Then create a backup of the old file
    if not RenameFileUTF8(FreeShip.Filename, Backup) then begin
      MessageDlg('Unable to create backup file '+Backup, mtError, [mbOK], 0);
      FreeShip.FileIsReadOnly:=true;
      result:=false;
      exit;
    end;
  end;
  Ext:=ExtractFileExt(FreeShip.Filename);
  if Ext = '.fbm' then Destination:=TFreeFileBuffer.Create
                  else Destination:=TFreeTextBuffer.Create;
  Destination.Encoding:=FreeShip.Preferences.FbmEncoding;
  FreeShip.SaveProject( Destination );
//try
    result:=Destination.SaveToFile( FreeShip.Filename );
    FreeShip.FileChanged:=false;
    FreeAndNil( Destination );
    FreeShip.Preferences.LastDirectory:=ExtractFilePath( FreeShip.FileName );
    AddToRecentFiles( FreeShip.FileName );
//except on E:Exception do begin
//  FreeAndNil( Destination ); result:=false;
//  MessageDlg('Unable to save file '+FreeShip.Filename+'\n'
//  + 'Exception class: '+E.ClassName+'\n'+'Message: '+E.Message+'\n',mtError,[mbOK],0 );
//  end;
//end;
end;
(*
procedure TFreeEdit.SaveDialogTypeChange(Sender: TObject);
var
  FName, Ext: string; SD: TSaveDialog;
begin
  SD:=TSaveDialog(Sender);
  with SD do begin
    if DirectoryExists(FileName) then exit; // FileName is Empty
    case FilterIndex of
      1: Ext:='.ftm';
      2: Ext:='.fbm';
    end;
    FName:=ChangeFileExt(ExtractFileName(FileName), Ext);
    FileName:=FName;
    {$IFDEF LCLGTK2}
    Widget:={%H-}PGtkWidget(Handle);
    gtk_file_chooser_set_current_name(PGtkFileChooser(Widget), PChar(FName));
    {$ENDIF}
    {$IFDEF LCLWIN32}
    SendMessage(GetParent(Handle),CDM_SETCONTROLTEXT,1152,LParam(PChar(FName)));
    {$ENDIF}
  end;
end;
*)
resourcestring rsSaveFile = 'Save file';
               rs3DTextFile = '3D text file';
               rsConfirmation =
        'The current model has been modified!'+EOL+'Do you need to keep this?';

function TFreeEdit.File_SaveCheck( Check:boolean ): word;
begin
  result:=mrOk;
  if Check then begin              // корпрус редактировался или дорасчитывался
     result:=MessageDlg( rsConfirmation,mtConfirmation,[mbYes,mbNo,mbCancel],0);
     if result=mrOk then File_SaveAs;
     if result<>mrCancel then begin          // mrCancel - отмена операций
        FreeShip.ClearUndo;                  // здесь корпус просто расчищается
        FreeShip.Clear;                      // здесь FFileChanged:=False
        FreeShip.Surface.ClearSelection;
        FreeShip.Surface.ClearFaces;
        FreeShip.Surface.Clear;
     end;
  end;
end;

function TFreeEdit.File_SaveAs: boolean;
var SaveDialog : TSaveDialog;
begin result:=false;
   SaveDialog:=TSaveDialog.Create( FreeShip );
   SaveDialog.InitialDir:=FreeShip.Preferences.SaveDirectory;
   Savedialog.FileName:=ExtractFilename(FreeShip.Filename);
// SaveDialog.Filter:='FREE!ship files (*.fbm)|*.fbm';
   SaveDialog.Filter:=FileDialogFilterFreeship +
                  '|' + FileDialogFilterFreeshipText +
                  '|' + FileDialogFilterFreeshipBinary;
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin WestPoint;
      FreeShip.Preferences.SaveDirectory:=ExtractFilePath( SaveDialog.FileName );
      if CurrentVersion>FreeShip.FileVersion then FreeShip.FStopAskingForFileVersion:=False;
      FreeShip.Filename:=Savedialog.Filename;
      FreeShip.FFilenameSet:=True;
      Result:=File_Save;
      if Result then FreeShip.Preferences.LastDirectory
                 :=ExtractFilePath( SaveDialog.FileName );
   end;
   SaveDialog.Destroy;
end;{TFreeEdit.File_SaveAs}

procedure TFreeEdit.Flowline_Add(Source: T2DCoordinate; View: TFreeviewType);
var
  Flowline: TFreeFlowline;
  vUndo: TFreeUndoObject;
begin
  vUndo:=CreateUndoObject( 'Add flowline',False );
  Flowline:=TFreeFlowline.Create( FreeShip );
  FreeShip.FFlowLines.Add( Flowline );
  Flowline.FProjectionPoint:=Source;
  Flowline.FProjectionView:=View;
  // Flowline.FMethodNew:=True;
  Flowline.Rebuild;
  if Flowline.FFlowLine.NumberOfPoints > 0 then begin   //////++++++??????
    FreeShip.FileChanged:=True;
    vUndo.Accept;
    Freeship.RebuildModel;
  end else begin
    vUndo.Delete;
    Flowline.Delete;
  end;
end;

procedure TFreeEdit.Geometry_AddCylinder;
var
  StartPoint: T3DCoordinate;
  EndPoint: T3DCoordinate;
  P1, P2: T3DCoordinate;
  I,J, NPoints, Ne: integer;
  Points: TFreeCoordinateGrid;
  CPoints:TFasterListTFreeSubdivisionControlPoint;
  Radius: TFloatType;
  Angle: TFloatType;
  Matrix: TFreeMatrix;
  Inv, OrgPts: TFreeMatrix;
  NewPts: TFreeMatrix;
  Dialog: TFreeCylinderDialog;
  Layer: TFreeSubdivisionLayer;
  Grid: TFreeSubdivisionControlPointGrid;
begin
  Dialog:=TFreeCylinderDialog.Create(FreeShip);                               //ShowTranslatedValues(Dialog);
  Dialog.StartPoint:=SetPoint(0.0, 0.0, 0.0);
  Dialog.EndPoint:=SetPoint(0.0, 1.0, 0.0);
  Dialog.Radius.Value:=1.0;
  Dialog.NoOfPoints.Value:=Dialog.NoOfPoints.MinValue + 2;

  if Dialog.Execute(LengthStr(FreeShip.ProjectSettings.ProjectUnits)) then
  begin
    CreateUndoObject(Userstring(131), True);
    Layer:=FreeShip.Surface.ActiveLayer;
    StartPoint:=Dialog.StartPoint;
    EndPoint:=Dialog.EndPoint;
    Radius:=Dialog.Radius.Value;
    NPoints:=Dialog.NoOfPoints.Value;
    Setlength(Points, 2);
    setlength(Points[0], NPoints + 1);
    setlength(Points[1], NPoints + 1);

    // Prepare matrices
    Matrix:=TFreeMatrix.Create;
    Matrix.SetSize(NPoints + 4, NPoints + 4);
    Matrix.Fill(0.0);
    Matrix.Value[0, 0]:=1.0;
    for I:=2 to NPoints + 3 do begin
      Matrix.Value[I - 1, I - 2]:=1 / 6;
      Matrix.Value[I - 1, I - 1]:=2 / 3;
      Matrix.Value[I - 1, I]:=1 / 6;
    end;
    Matrix.Value[NPoints + 3, NPoints + 3]:=1.0;             // Invert matrix
    Inv:=Matrix.Invert;
    FreeAndNil(Matrix);

    OrgPts:=TFreeMatrix.Create;
    OrgPts.SetSize(3, NPoints + 4);
    for I:=1 to NPoints do begin
      Angle:=-((I - 1) / NPoints) * 2 * Pi;
      P1.x:=StartPoint.x + Sin(Angle) * Radius;
      P1.y:=StartPoint.y + Cos(Angle) * Radius;
      P1.z:=StartPoint.z;
      P2:=RotatePointAroundVector(P1, StartPoint, Subtract(EndPoint, StartPoint));
      OrgPts.Value[I + 1, 0]:=P2.X;
      OrgPts.Value[I + 1, 1]:=P2.Y;
      OrgPts.Value[I + 1, 2]:=P2.Z;
    end;
    for I:=0 to 2 do begin
      OrgPts.Value[1, I]:=OrgPts.Value[NPoints + 1, I];
      OrgPts.Value[0, I]:=OrgPts.Value[NPoints, I];
      OrgPts.Value[NPoints + 2, I]:=OrgPts.Value[2, I];
      OrgPts.Value[NPoints + 3, I]:=OrgPts.Value[3, I];
    end;
    // calculate new points
    NewPts:=Inv.Multiply(OrgPts);
    for I:=1 to NPoints do begin
      P1.X:=NewPts.Value[I + 1, 0];
      P1.Y:=NewPts.Value[I + 1, 1];
      P1.Z:=NewPts.Value[I + 1, 2];
      Points[0][I - 1]:=P1;
      Points[1][I - 1]:=SetPoint(P1.X + EndPoint.X - StartPoint.X,
        P1.Y + EndPoint.Y - StartPoint.Y, P1.Z + EndPoint.Z - StartPoint.Z);
    end;
    Points[0][NPoints]:=Points[0][0];
    Points[1][NPoints]:=Points[1][0];
    FreeAndNil(Inv);
    FreeAndNil(OrgPts);
    FreeAndNil(NewPts);
    Ne:=FreeShip.Surface.NumberOfControlEdges;
    Setlength(Grid, 2);
    for I:=0 to 1 do begin
      Setlength(Grid[I], NPoints + 1);
      for J:=0 to NPoints do
        Grid[I][J]:=FreeShip.Surface.AddControlPoint(Points[I][J]);
    end;
    FreeShip.Surface.ImportControlPointGrid(Grid, NPoints + 1, 2, Layer);
    for I:=Ne + 1 to FreeShip.Surface.NumberOfControlEdges do
      FreeShip.Surface.ControlEdge[I - 1].Crease:=False;
    if Dialog.CloseStartDisk.Checked then begin
      CPoints:=TFasterListTFreeSubdivisionControlPoint.Create(true,false);
      for I:=NPoints - 1  downto 0 do CPoints.Add(Grid[0][I]);
      FreeShip.Surface.AddControlFaceN(CPoints, true, Layer);
      CPoints.Free;
    end;
    if Dialog.CloseEndDisk.Checked then begin
      CPoints:=TFasterListTFreeSubdivisionControlPoint.Create(true,false);
      for I:=0 to NPoints - 1 do CPoints.Add(Grid[1][I]);
      FreeShip.Surface.AddControlFaceN(CPoints, true, Layer);
      CPoints.Free;
    end;
    Freeship.RebuildModel;
  end;
  FreeAndNil(Dialog);
end;

procedure TFreeEdit.Geometry_AddGridPanel;
var
  StartPoint: T3DCoordinate;
  Point: T3DCoordinate;
  P1, P2: T3DCoordinate;
  I,J, Cols,Rows, Plane, Ne: integer;
  CPoints:TFasterListTFreeSubdivisionControlPoint;
  SizeA,SizeB, x,y,z, dX,dY,dZ: TFloatType;
  Dialog: TFreeGridDialog;
  Layer: TFreeSubdivisionLayer;
  Grid: TFreeSubdivisionControlPointGrid;
begin
  Dialog:=TFreeGridDialog.Create(FreeShip);
  Dialog.StartPoint:=SetPoint(0.0, 0.0, 0.0);

  if Dialog.Execute(LengthStr(FreeShip.ProjectSettings.ProjectUnits)) then
  begin
    CreateUndoObject(Userstring(131), True);
    Layer:=FreeShip.Surface.ActiveLayer;
    StartPoint:=Dialog.StartPoint;
    SizeA:=Dialog.SizeA.Value;
    SizeB:=Dialog.SizeB.Value;
    Cols:=Dialog.ColumnPoints.Value;
    Rows:=Dialog.RowPoints.Value;
    Plane:= Dialog.Plane.ItemIndex;

    Setlength(Grid, Cols);
    for i:=0 to Cols-1 do begin
      SetLength(Grid[i], Rows);
      for j:=0 to Rows-1 do begin
        case Plane of
          0: // Horizontal
            begin
            x:=StartPoint.X + i * SizeA / Cols;
            y:=StartPoint.Y + j * SizeB / Rows;
            z:=0;
            end;
          1: // Lateral
            begin
            x:=StartPoint.X + i * SizeA / Cols;
            y:=0;
            z:=StartPoint.Z + j * SizeB / Rows;
            end;
          2: // Transverse
            begin
            x:=0;
            y:=StartPoint.Y + i * SizeA / Cols;
            z:=StartPoint.Z + j * SizeB / Rows;
            end;
        end;

        Point:=Point3D(x,y,z);
        Grid[I][J]:=FreeShip.Surface.AddControlPoint(Point);
        end;
      end;
    FreeShip.Surface.ImportControlPointGrid(Grid, Cols, Rows, Layer);
    Freeship.RebuildModel;
  end;
  FreeAndNil(Dialog);
end;

// Creates and calculates a hydrostatics calculation
function TFreeEdit.Hydrostatics_Calculate(Draft, AngleOfHeel, Trim: TFloatType):
TFreeHydrostaticCalc;
begin
  if not FreeShip.ProjectSettings.FMainParticularsHasBeenset then
  begin
    MessageDlg(UserString(196), mtError, [mbOK], 0);
    Result:=nil;
  end else begin                             // Check model for inconsistencies
    if not FreeShip.ProjectSettings.DisableModelCheck then Model_Check(False);
    Result:=TFreeHydrostaticCalc.Create(FreeShip);
    Result.Trim:=Trim;
    Result.HeelingAngle:=AngleOfHeel;
    Result.Draft:=Draft;
    Result.Calculate;
    Result.ShowData(fhSingleCalculation);
  end;
end;
(*
// Opens the dialog to calculate crosscurves
procedure TFreeEdit.Hydrostatics_Crosscurves;
var
  Dialog: TFreeCrosscurvesDialog;
begin
  if not FreeShip.ProjectSettings.FMainparticularsHasBeenset then
    MessageDlg(UserString(196), mtError, [mbOK], 0)
  else begin                                 // Check model for inconsistencies
    if not FreeShip.ProjectSettings.DisableModelCheck then Model_Check(False);
    Dialog:=TFreeCrosscurvesDialog.Create(FreeShip);                          ////    ShowTranslatedValues(Dialog);
    Dialog.SetDisplacements(FreeShip.ProjectSettings.FDisplacements,FreeShip.ProjectSettings.FNoDisplacements);
    Dialog.FreeNumInput2.Value:=FreeShip.ProjectSettings.FMinimumDisplacement;
    Dialog.FreeNumInput3.Value:=FreeShip.ProjectSettings.FMaximumDisplacement;
    Dialog.FreeNumInput4.Value:=FreeShip.ProjectSettings.FDisplIncrement;
    Dialog.CheckBox1.Checked:=FreeShip.ProjectSettings.FUseDisplIncrements;
    Dialog.SetHeelingAngles(FreeShip.ProjectSettings.FAngles,FreeShip.ProjectSettings.FNoAngles);
    if Dialog.Execute(FreeShip) then begin
      CreateUndoObject('crosscurves settings', True);
      FreeShip.ProjectSettings.FMinimumDisplacement:=Dialog.FreeNumInput2.Value;
      FreeShip.ProjectSettings.FMaximumDisplacement:=Dialog.FreeNumInput3.Value;
      ;
      FreeShip.ProjectSettings.FDisplIncrement:=Dialog.FreeNumInput4.Value;
      Dialog.GetDisplacements(FreeShip.ProjectSettings.FDisplacements,
        FreeShip.ProjectSettings.FNoDisplacements);
      FreeShip.ProjectSettings.FUseDisplIncrements:=Dialog.CheckBox1.Checked;
      Dialog.GetHeelingAngles(FreeShip.ProjectSettings.FAngles,FreeShip.ProjectSettings.FNoAngles);
      FreeShip.FileChanged:=True;
    end;
    FreeAndNil(Dialog);
  end;
end;
*)
// Opens the hydrostatics dialog and calculates hydrostatic data for a range of inputdata
procedure TFreeEdit.Hydrostatics_Dialog;
var HydrostaticsForm: TFreeHydrostaticsForm;
begin
  HydrostaticsForm:=TFreeHydrostaticsForm.Create(FreeShip);                   //ShowTranslatedValues(HydrostaticsForm);
  Hydrostaticsform.StartDraft:=FreeShip.ProjectSettings.Hydrostatics_Startdraft;
  Hydrostaticsform.EndDraft:=FreeShip.ProjectSettings.Hydrostatics_Enddraft;
  Hydrostaticsform.DraftStep:=FreeShip.ProjectSettings.Hydrostatics_DraftStep;
  Hydrostaticsform.Trim:=FreeShip.ProjectSettings.Hydrostatics_Trim;
  if TFreeHydrostaticsForm(HydrostaticsForm).Execute(FreeShip) then begin
    FreeShip.ProjectSettings.Hydrostatics_Startdraft:=HydrostaticsForm.StartDraft;
    FreeShip.ProjectSettings.Hydrostatics_Enddraft:=HydrostaticsForm.EndDraft;
    FreeShip.ProjectSettings.Hydrostatics_DraftStep:=HydrostaticsForm.DraftStep;
    FreeShip.ProjectSettings.Hydrostatics_Trim:=HydrostaticsForm.Trim;
  end;
end;

// Loads a bodyplane and tries to fit a surface to it
procedure TFreeEdit.ImportFrames;
type
  TMinMax = record
    MinZ, MaxZ: TFloatType;
  end;
  // Assumptions:
  //    1. All stations have multiplicity of 1
  //    2. All stations are defined from bottom to top
var
  OpenDialog: TOpenDialog;
  I, J, K, Nr: integer;
  Index: integer;
  Frames: TFasterListTFreeSpline;
  FFile: TextFile;
  NoStations: integer;
  NoPoints: integer;
  Spline: TFreeSpline;
  NewSpline: TFreeSpline;
  P: T3DCoordinate;
  ValidStation, IsFaceDeleted: boolean;
  MinMaxData: array of TMinMax;
  MinZ, MaxZ: TFloatType;
  ControlPoints: array of array of TFreeSubdivisionControlPoint;
  P1, P2: TFreeSubdivisionControlPoint;
  Edge: TFreeSubdivisionControlEdge;
  Face: TFreeSubdivisionControlFace;
  Points: TFasterListTFreeSubdivisionControlPoint;
  Marker: TFreeMarker;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=ExtractFilepath(Application.ExeName);
  OpenDialog.Filter:=createDialogFilter(rs3DTextFile, ['txt']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
    Frames:=TFasterListTFreeSpline.Create;
    case OpenDialog.FilterIndex of
      1:
      begin // 3D textfile containing stations, waterlines and buttocks
        AssignFile(FFile, Opendialog.FileName);
               {$I-}
        Reset(FFile);
{$I+}
        if IOResult = 0 then
        begin
          K:=0;
          Nr:=0;
          Inc(Nr);
          Readln(FFile, NoStations);
          for I:=1 to NoStations do begin Inc(Nr);
            readln(FFile);// Skip description of this line
            Inc(Nr);
            readln(FFile, NoPoints);
            Spline:=TFreeSpline.Create(FreeShip.Surface);
            Spline.Capacity:=NoPoints;
            ValidStation:=NoPoints > 1;
            for J:=1 to Nopoints do begin
//            try
                Inc(Nr);
                Read(FFile, P.X, P.Y, P.Z);
                if not EOLN(FFile) then Readln(FFile, K)
                else begin K:=0; Readln( FFile ); end;
//            except
//              ShowMessage( Userstring(132) + #32 + IntToStr(Nr) );
//            end;
              Spline.Add(P);
              if J > 1 then
                ValidStation:=abs(P.X - Spline.Point[0].X) < 1e-4;
              if (K = 1) and (J <> 1) and (J <> NoPoints) then
                Spline.Knuckle[J - 1]:=True;
            end;
            if ValidStation then Frames.Add( Spline )
                            else FreeAndNil( Spline );
          end;
          CloseFile(FFile);
        end
        else MessageDlg(Userstring(132), mtError, [mbOK], 0);
      end;
    end;
    if Frames.Count > 1 then
    begin
      FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      CreateUndoObject(Userstring(133), True);
      FreeShip.Clear;
      FreeShip.Filename:=Opendialog.FileName;
      MinZ:=0.0;
      MaxZ:=0.0;
      // first sort the stations from aft to front
      for I:=1 to Frames.Count - 1 do
        for J:=I + 1 to Frames.Count do
          if TFreeSpline(Frames[J - 1]).Point[0].X <
            TFreeSpline(Frames[I - 1]).Point[0].X then
            Frames.Exchange(I - 1, J - 1);
      // Determine the minimum and maximum Z values for each station
      // and the overall min/max z-coordinate
      Setlength(MinMaxData, Frames.Count);
      for I:=1 to Frames.Count do
      begin
        Spline:=Frames[I - 1];
        MinMaxData[I - 1].MinZ:=Spline.Point[0].Z;
        MinMaxData[I - 1].MaxZ:=Spline.Point[Spline.NumberOfPoints - 1].Z;
        if I = 1 then
        begin
          MinZ:=Spline.Point[0].Z;
          MaxZ:=MinZ;
        end;
        if Spline.Point[0].Z < MinZ then
          MinZ:=Spline.Point[0].Z;
        if Spline.Point[Spline.NumberOfPoints - 1].Z > MaxZ then
          MaxZ:=Spline.Point[Spline.NumberOfPoints - 1].Z;
        Marker:=TFreeMarker.Create(FreeShip.Surface);
        Marker_Add(Marker);
        Marker.Capacity:=Spline.NumberOfPoints;
        for J:=1 to Spline.NumberOfPoints do
        begin
          Marker.Add(Spline.Point[J - 1]);
          Marker.Knuckle[J - 1]:=Spline.Knuckle[J - 1];
        end;
      end;

      // extend all stations upwards and downwards to the min/max z-values
      for I:=1 to Frames.Count do
      begin
        Spline:=Frames[I - 1];
        // extend downwards to Z=0
        if Spline.Point[0].Z > MinZ then
        begin
          P:=Spline.Point[0];
          P.Z:=MinZ;
          Spline.Insert(0, P);
          Spline.Knuckle[1]:=True;
        end;
        // extend upwards
        if Spline.Point[Spline.NumberOfPoints - 1].Z < MaxZ then
        begin
          P:=Spline.Point[Spline.NumberOfPoints - 1];
          P.Z:=MaxZ;
          Spline.Add(P);
          Spline.Knuckle[Spline.NumberOfPoints - 2]:=True;
        end;
      end;

      NoPoints:=10;
      // resample all stations to a user defined number of points
      NoPoints:=StrToInt(InputBox('', Userstring(135) + ':', IntToStr(NoPoints)));
      if NoPoints < 5 then
        NoPoints:=5;
      Setlength(ControlPoints, Frames.Count);
      for I:=1 to Frames.Count do
      begin
        Spline:=Frames[I - 1];
        NewSpline:=TFreeSpline.Create(FreeShip.Surface);
        NewSpline.Capacity:=NoPoints;
        for J:=1 to NoPoints do
        begin
          P:=Spline.Value((J - 1) / (NoPoints - 1));
          NewSpline.Add(P);
        end;
        // correct for any present knuckles
        for J:=1 to Spline.NumberOfPoints do
          if Spline.Knuckle[J - 1] then
          begin
            Index:=0;
            // find the nearest point on resampled spline
            for K:=2 to NewSpline.NumberOfPoints - 1 do
              if DistPP3D(Spline.Point[J - 1], NewSpline.Point[K - 1]) <
                DistPP3D(Spline.Point[J - 1], NewSpline.Point[index]) then
                Index:=K - 1;
            // replace by the old coordinate
            NewSpline.Point[index]:=Spline.Point[J - 1];
            NewSpline.Knuckle[index]:=True;
          end;

        // Delete the old station
        FreeAndNil(Spline);
        // and replace by the resampled one
        Frames[I - 1]:=NewSpline;
        // Add the controlpoints to the subdivision surface
        Setlength(ControlPoints[I - 1], NewSpline.NumberOfPoints);
        for J:=1 to NewSpline.NumberOfPoints do
          ControlPoints[I - 1][J - 1] :=
            FreeShip.Surface.AddControlPoint(NewSpline.Point[J - 1]);
      end;
      // Add the new controlfaces
      Points:=TFasterListTFreeSubdivisionControlPoint.Create;
      for I:=2 to Frames.Count do
        for J:=2 to NoPoints do
        begin
          Points.Clear;
          Points.Add(ControlPoints[I - 1][J - 1]);
          Points.Add(ControlPoints[I - 1][J - 2]);
          Points.Add(ControlPoints[I - 2][J - 2]);
          Points.Add(ControlPoints[I - 2][J - 1]);
          FreeShip.Surface.AddControlFace(Points, True);
        end;

      Points.Clear;
      // Try to reconnect the contourline
      P1:=nil;
      P2:=nil;
      for I:=1 to Frames.Count do
      begin
        for J:=1 to NoPoints do
          if abs(ControlPoints[I - 1][J - 1].Coordinate.Z -
            MinMaxData[I - 1].MinZ) < 1e-7 then
          begin
            P2:=ControlPoints[I - 1][J - 1];
            if P2.Coordinate.Y <> 0.0 then
            begin
              // Force point to centerplane
              P:=P2.Coordinate;
              P.Y:=0;
              P2.Coordinate:=P;
            end;
            break;
          end
          else
            Points.Add(ControlPoints[I - 1][J - 1]);// store to be deleted later
        if (P1 <> nil) and (P2 <> nil) then
        begin
          Edge:=FreeShip.Surface.EdgeExists(P1, P2) as TFreeSubdivisionControlEdge;
          if Edge <> nil then
            Edge.Crease:=True
          else
          begin
            // Find out if P1 and P2 share the same controlface
            for J:=1 to P1.NumberOfFaces do
              if P2.IndexOfFace(P1.Face[J - 1]) <> -1 then
              begin
                Face:=P1.Face[J - 1] as TFreeSubdivisionControlFace;
                Edge:=Face.InsertEdge(P1, P2, IsFaceDeleted);
                if Edge <> nil then
                  Edge.Crease:=True;
              end;
            DelayedDestroyList.DestroyAll;
          end;
        end;
        P1:=P2;
        P2:=nil;
      end;

      // Try to reconnect the deckline
      P1:=nil;
      P2:=nil;
      for I:=1 to Frames.Count do
      begin
        for J:=1 to NoPoints do
          if abs(ControlPoints[I - 1][J - 1].Coordinate.Z -
            MinMaxData[I - 1].MaxZ) < 1e-7 then
          begin
            P2:=ControlPoints[I - 1][J - 1];
            K:=J + 1;
            while K <= NoPoints do
            begin
              Points.Add(ControlPoints[I - 1][K - 1]);
              Inc(K);
            end;
            break;
          end;
        if (P1 <> nil) and (P2 <> nil) then
        begin
          Edge:=FreeShip.Surface.EdgeExists(P1, P2) as TFreeSubdivisionControlEdge;
          if Edge <> nil then
            Edge.Crease:=True
          else
          begin
            // Find out if P1 and P2 share the same controlface
            for J:=1 to P1.NumberOfFaces do
              if P2.IndexOfFace(P1.Face[J - 1]) <> -1 then
              begin
                Face:=P1.Face[J - 1] as TFreeSubdivisionControlFace;
                Edge:=Face.InsertEdge(P1, P2, IsFaceDeleted);
                if Edge <> nil then
                  Edge.Crease:=True;
              end;
            DelayedDestroyList.DestroyAll;
          end;
        end;
        P1:=P2;
        P2:=nil;
      end;
      // Delete all controlpoints beneath the contourline and above the deckline
      for J:=1 to Points.Count do
      begin
        P1:=Points[J - 1];
        if FreeShip.Surface.PointExists(P1) then
          P1.Delete;
      end;
      for I:=1 to FreeShip.Surface.NumberOfControlPoints do
        if FreeShip.Surface.ControlPoint[I - 1].NumberOfFaces = 1 then
          FreeShip.Surface.ControlPoint[I - 1].VertexType:=svCorner;
      FreeAndNil(Points);
      FreeShip.FileChanged:=True;
    end;
    FreeShip.Draw;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then
      FreeShip.OnUpdateGeometryInfo(self);
    // Destroy allocated stations
    for I:=1 to Frames.Count do
    begin
      Spline:=Frames[I - 1];
      FreeAndNil(Spline);
    end;
    FreeAndNil(Frames);
  end;
  FreeAndNil(OpenDialog);
end;{TFreeEdit.ImportFrames}

// Imports a number of curves and fits a surface;
procedure TFreeEdit.File_ImportSurface;
var
  OpenDialog: TOpenDialog;
  I, J, Nr: integer;
  Str: string;
  FFile: TextFile;
  Cols, Rows: integer;
  Spline: TFreeSpline;
  NewSpline: TFreeSpline;
  P: T3DCoordinate;
  Points: array of array of T3DCoordinate;
  ControlPoints: array of array of TFreeSubdivisionControlPoint;
  P1: TFreeSubdivisionControlPoint;
  Curves: TFasterListTFreeSpline;
  LongCurves: TFasterListTFreeSpline;
  Pts: TFasterListTFreeSubdivisionControlPoint;
  Matrix: TFreeMatrix;
  ColMatrix: TFreeMatrix;
  RowMatrix: TFreematrix;
  OrgPts: TFreeMatrix;
  NewPts: TFreeMatrix;
  UnitType: TFreeUnitType;
  Marker: TFreeMarker;
  PrevCursor: TCursor;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rs3DTextFile, ['txt']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then
  begin
    UnitType:=TFreeUnitType(0);
    Curves:=TFasterListTFreeSpline.Create;
    case OpenDialog.FilterIndex of
      1:
      begin // 3D textfile containing a number of curves to be interpolated
        AssignFile(FFile, Opendialog.FileName);
        {$I-}
        Reset(FFile);
        {$I+}
        if IOResult = 0 then
        begin
          Nr:=0;
          try
            // first read unit information; 0=metric, 1=imperial
            readln(FFile, I);
            if I in [0, 1] then
              UnitType:=TFreeUnitType(I)
            else
              MessageDlg(Userstring(108), mtError, [mbOK], 0);
            Spline:=TFreeSpline.Create(FreeShip.Surface);
            repeat
              Readln(FFile, Str);
              repeat
                I:=Pos(#9, Str);
                if I <> 0 then
                  str[I]:=#32;
              until I = 0;
              Inc(Nr);
              Str:=Trim(Uppercase(Str));
              if (Str <> '') and (Str <> 'EOF') then begin
                P.X:=GetFloat( Str);
                P.Y:=GetFloat( Str);
                P.Z:=GetFloat( Str);
                Spline.Add(P);
                Str:=#32;
              end
              else if Str = '' then begin
                if Spline.NumberOfPoints > 1 then Curves.Add(Spline)
                                             else FreeAndNil(Spline);
                Spline:=TFreeSpline.Create(FreeShip.Surface);
              end;
            until (Str = 'EOF') or (EOF(FFile));
            if Spline.NumberOfPoints > 1 then
              Curves.Add(Spline)
            else
              FreeAndNil(Spline);
          except
            MessageDlg(Userstring(132) + #32 + IntToStr(Nr), mtError, [mbOK], 0);
          end;
          CloseFile(FFile);
        end
        else
          MessageDlg(Userstring(132), mtError, [mbOK], 0);
      end;
    end;
    if Curves.Count > 1 then
    begin
      PrevCursor:=Screen.Cursor;
      FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      CreateUndoObject(Userstring(136), True);
      FreeShip.Clear;
      FreeShip.ProjectSettings.ProjectUnits:=UnitType;
      FreeShip.Filename:=Opendialog.FileName;
//    try
        Cols:=Curves.Count;
        Cols:=StrToInt(InputBox('', Userstring(137) + ':', IntToStr(Cols)));
        if Cols < 3 then Cols:=3;
        Rows:=10;
        Rows:=StrToInt(InputBox('', Userstring(138) + ':', IntToStr(Rows)));
        if Rows < 3 then Rows:=3;

        // Build number of desired longitudinal curves
        LongCurves:=TFasterListTFreeSpline.Create;
        for I:=1 to Rows do begin
          NewSpline:=TFreeSpline.Create(FreeShip.Surface);
          LongCurves.Add(NewSpline);
          Newspline.Capacity:=Curves.Count;
          for J:=1 to Curves.Count do begin
            Spline:=Curves[J - 1];
            Newspline.Add(Spline.Value((I - 1) / (Rows - 1)));
          end;
        end;
        for I:=1 to Curves.Count do begin
          Spline:=Curves[I - 1];
          Marker:=TFreeMarker.Create(FreeShip.Surface);
          Marker.Capacity:=Spline.NumberOfPoints;
          for J:=1 to Spline.NumberOfPoints do
            Marker.Add(Spline.Point[J - 1]);
          Marker_Add(Marker);
          FreeAndNil(Spline);
        end;
        FreeAndNil(Curves);

        // build matrix for column interpolation
        Matrix:=TFreeMatrix.Create;
        Matrix.SetSize(Cols, Cols);
        Matrix.Fill(0.0);
        Matrix.Value[0, 0]:=1.0;
        for I:=2 to Cols - 1 do begin
          Matrix.Value[I - 1, I - 2]:=1 / 6;
          Matrix.Value[I - 1, I - 1]:=2 / 3;
          Matrix.Value[I - 1, I]:=1 / 6;
        end;
        Matrix.Value[Cols - 1, Cols - 1]:=1.0;
        Colmatrix:=Matrix.Invert;

        Matrix.SetSize(Rows, Rows);
        Matrix.Fill(0.0);
        Matrix.Value[0, 0]:=1.0;
        for I:=2 to Rows - 1 do begin
          Matrix.Value[I - 1, I - 2]:=1 / 6;
          Matrix.Value[I - 1, I - 1]:=2 / 3;
          Matrix.Value[I - 1, I]:=1 / 6;
        end;
        Matrix.Value[Rows - 1, Rows - 1]:=1.0;        // Invert matrix
        Rowmatrix:=Matrix.Invert;
        FreeAndNil(Matrix);
        Setlength(Points, Rows);                   // build initial point grid
        for I:=1 to Rows do begin
          setlength(Points[I - 1], Cols);
          Spline:=LongCurves[I - 1];
          OrgPts:=TFreeMatrix.Create;
          OrgPts.SetSize(3, Cols);
          for J:=1 to Cols do begin
            P:=Spline.Value((J - 1) / (Cols - 1));
            OrgPts.Value[J - 1, 0]:=P.X;
            OrgPts.Value[J - 1, 1]:=P.Y;
            OrgPts.Value[J - 1, 2]:=P.Z;
          end;
          NewPts:=ColMatrix.Multiply(OrgPts);

          for J:=1 to Cols do begin
            P.X:=NewPts.Value[J - 1, 0];
            P.Y:=NewPts.Value[J - 1, 1];
            if (OrgPts.Value[J - 1, 1] >= 0.0) and (P.Y < 0.0) then P.Y:=0.0;
            P.Z:=NewPts.Value[J - 1, 2];
            Points[I - 1][J - 1]:=P;
          end;

          FreeAndNil(OrgPts);
          FreeAndNil(NewPts);
        end;
        FreeAndNil(ColMatrix);

        // interpolate rows
        for I:=1 to Cols do begin
          OrgPts:=TFreeMatrix.Create;
          OrgPts.SetSize(3, Rows);
          for J:=1 to Rows do begin
            P:=Points[J - 1][I - 1];
            OrgPts.Value[J - 1, 0]:=P.X;
            OrgPts.Value[J - 1, 1]:=P.Y;
            OrgPts.Value[J - 1, 2]:=P.Z;
          end;
          NewPts:=RowMatrix.Multiply(OrgPts);
          for J:=1 to Rows do begin
            P.X:=NewPts.Value[J - 1, 0];
            P.Y:=NewPts.Value[J - 1, 1];
            if (OrgPts.Value[J-1,1] >= 0.0) and (P.Y < 0.0) then P.Y:=0.0;
            P.Z:=NewPts.Value[J - 1, 2];
            Points[J - 1][I - 1]:=P;
          end;
          FreeAndNil(OrgPts);
          FreeAndNil(NewPts);
        end;
        FreeAndNil(RowMatrix);

        // delete long. curves
        for I:=1 to LongCurves.Count do begin
          Spline:=LongCurves[I - 1];
          FreeAndNil(Spline);
        end;
        FreeAndNil(LongCurves);

        // import actual surface
        Setlength(ControlPoints, Rows);
        for I:=1 to Rows do begin
          Setlength(ControlPoints[I - 1], Cols);
          for J:=1 to Cols do begin
            ControlPoints[I - 1][J - 1] :=
              TFreesubdivisionControlPoint.Create(FreeShip.Surface);
            FreeShip.Surface.AddControlPoint(ControlPoints[I - 1][J - 1]);
            ControlPoints[I - 1][J - 1].Coordinate:=Points[I - 1][J - 1];
            //ControlPoints[I-1][J-1]:=FreeShip.Surface.AddControlPoint(Points[I-1][J-1]);
          end;
        end;
        Pts:=TFasterListTFreeSubdivisionControlPoint.Create;
        for I:=2 to Rows do
          for J:=2 to Cols do begin
            Pts.Clear;
            P1:=ControlPoints[I - 2][J - 2];
            Pts.Add(P1);
            P1:=ControlPoints[I - 2][J - 1];
            if Pts.IndexOf(P1) = -1 then Pts.Add(P1);
            P1:=ControlPoints[I - 1][J - 1];
            if Pts.IndexOf(P1) = -1 then Pts.Add(P1);
            P1:=ControlPoints[I - 1][J - 2];
            if Pts.IndexOf(P1) = -1 then Pts.Add(P1);
            if Pts.Count > 2 then FreeShip.Surface.AddControlFace(Pts, True);
          end;
        FreeAndNil(Pts);
        FreeShip.FileChanged:=True;
//    finally
        if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
        Screen.Cursor:=PrevCursor;
//    end;
    end;
    FreeShip.ModelIsLoaded:=True;
    FreeShip.Built:=False;
    FreeShip.Precision:=fpMedium;
    FreeShip.Draw;
  end;
  FreeAndNil(OpenDialog);
end;

procedure TFreeEdit.Intersection_AddToList(Intersection: TFreeIntersection);
var
  I, J: integer;
  TargetList: TFasterListTFreeIntersection;
  Int1, Int2: TFreeIntersection;
begin
  case Intersection.IntersectionType of
    fiStation: TargetList:=FreeShip.FStations;
    fiButtock: TargetList:=FreeShip.FButtocks;
    fiWaterline: TargetList:=FreeShip.FWaterlines;
    fiDiagonal: TargetList:=FreeShip.FDiagonals;
    else
      TargetList:=nil;
  end;
  if TargetList <> nil then
  begin
    TargetList.Add(Intersection);
    // Now sort the list so that the distance is in ascending order
    for I:=1 to TargetList.Count - 1 do
    begin
      Int1:=TargetList[I - 1];
      for J:=I + 1 to TargetList.Count do
      begin
        Int2:=Targetlist[J - 1];
        if -Int2.FPlane.d < -Int1.FPlane.d then
        begin
          // swap the two intersections
          Targetlist.Exchange(I - 1, J - 1);
          Int1:=TargetList[I - 1];
        end;
      end;
    end;
  end;
end;

// Pops up the dialog in which to add or delete stations, buttocks and waterlines
procedure TFreeEdit.Intersection_Dialog;
var
  Dialog: TFreeIntersectionDialog;
begin
  Dialog:=FreeShip.FIntersectionDialog as TFreeIntersectionDialog;            //ShowTranslatedValues(Dialog);
  Dialog.Execute(FreeShip);
  FreeShip.FDesignHydrostatics.Calculated:=False;
  if FreeShip.Visibility.ShowHydrostaticData then
    Freeship.ReDraw;
end;

// All connected patches surrounded by crease edges are grouped together into a new layer
procedure TFreeEdit.Layer_AutoGroup;
var
  ToDoList: TList;
  DoneList: TList;
  Current: TList;
  I, J: integer;
  Face, Face2: TFreeSubdivisionControlFace;
  Layer: TFreeSubdivisionLayer;
  SameLayer: boolean;

  procedure FindAttachedFaces(List: TList; Face: TFreeSubdivisionControlFace);
  var
    I, J: integer;
    Index: integer;
    P1, P2: TFreeSubdivisionPoint;
    Edge: TFreeSubdivisionEdge;
  begin
    P1:=Face.Point[Face.NumberOfPoints - 1];
    for I:=1 to Face.NumberOfpoints do
    begin
      P2:=Face.Point[I - 1];
      Edge:=Face.Surface.EdgeExists(P1, P2);
      if Edge <> nil then
        if not Edge.Crease then
          for J:=1 to Edge.NumberOfFaces do
            if Edge.Face[J - 1] <> Face then
            begin
              Index:=ToDoList.IndexOf(Edge.Face[J - 1]);
              if Index <> -1 then
              begin
                List.Add(Edge.Face[J - 1]);
                ToDoList.Delete(Index);
                FindAttachedFaces(List, Edge.Face[J - 1] as
                  TFreeSubdivisionControlFace);
              end;
            end;
      P1:=p2;
    end;
  end;

begin
  ToDoList:=TList.Create;
  DoneList:=TList.Create;
//try
    if FreeShip.NumberOfSelectedControlFaces > 0 then
      // Use only the selected ones
    begin
      ToDoList.Capacity:=ToDoList.Count + FreeShip.NumberOfSelectedControlFaces;
      for I:=1 to FreeShip.NumberOfSelectedControlFaces do
      begin
        Face:=FreeShip.SelectedControlFace[I - 1];
        ToDoList.Add(Face);
      end;
    end
    else
      for I:=1 to FreeShip.NumberOfLayers do
      begin
        Layer:=FreeShip.Layer[I - 1];
        if Layer.SurfaceVisible then
        begin
          ToDoList.Capacity:=ToDoList.Count + Layer.Count;
          for J:=1 to Layer.Count do
            ToDoList.Add(Layer.Items[J - 1]);
        end;
      end// use all visible faces
    ;
    if ToDoList.Count > 0 then
    begin
      CreateUndoObject(Userstring(139), True);
      while ToDoList.Count > 0 do
      begin
        Face:=TFreeSubdivisionControlFace(ToDoList[ToDoList.Count - 1]);
        ToDoList.Delete(ToDoList.Count - 1);
        Current:=TList.Create;
        Current.Add(Face);
        FindAttachedFaces(Current, Face);
        DoneList.Add(Current);
      end;
      // Assign all groups to different layers
      for I:=1 to DoneList.Count do
      begin
        Current:=TList(DoneList[I - 1]);
        if Current.Count > 0 then
        begin
          SameLayer:=True;
          // check if all selected faces currently belong to the same layer
          Face:=TFreeSubdivisionControlFace(Current[0]);
          for J:=2 to Current.Count do
          begin
            Face2:=TFreeSubdivisionControlFace(Current[J - 1]);
            if Face2.Layer <> Face.Layer then
              SameLayer:=False;
          end;
          Layer:=nil;
          if SameLayer then
          begin
            // yes, all faces belong to the same layer
            if Current.Count = Face.Layer.Count then
              // apparently the same data is selected as in face.layer, do not change layer

            else
            begin
              // a subset of face.layer is selected, copy properties from that layer
              Layer:=FreeShip.Surface.AddNewLayer;
              Layer.AssignProperties(Face.Layer);
            end;
          end
          else
          begin
            // Faces belong to multiple layers,
            Layer:=Layer_New;
            Layer.Color:=RandomColor;
          end;
          if Layer <> nil then
            for J:=1 to Current.Count do
            begin
              Face:=TFreeSubdivisionControlFace(Current[J - 1]);
              Face.Layer:=Layer;
            end;
        end;
        FreeAndNil(Current);
      end;
      FreeShip.ActiveLayer:=FreeShip.Layer[FreeShip.NumberOfLayers - 1];
      // Delete empty layers
      Layer_DeleteEmpty(True);
      Freeship.ReDraw;
      FreeShip.FileChanged:=True;
    end;
//finally
    if assigned(FreeShip.OnChangeLayerData) then
      FreeShip.OnChangeLayerData(self);
    FreeAndNil(ToDoList);
    FreeAndNil(DoneList);
//end;
end;

// Develope all developable layers
procedure TFreeEdit.Layer_Develop;
var
  Layer: TFreeSubdivisionLayer;
  Patch: TFreeDevelopedPatch;
  Dlg: TFreeExpanedplatesDialog;
  Plates: TFasterListTFreeDevelopedPatch;
  I, J: integer;
  Prev: TCursor;
begin
  Prev:=Screen.Cursor;
  Screen.Cursor:=crHourGlass;
  Plates:=TFasterListTFreeDevelopedPatch.Create;
//try
    // perform a quiet test to check normal directions
    if not FreeShip.ProjectSettings.DisableModelCheck then Model_Check(False);
    for I:=1 to FreeShip.NumberOfLayers do begin
      Layer:=FreeShip.Layer[I - 1];
      if Layer.Developable then Layer.Unroll(Plates);
    end;

    Patch:=TFreeDevelopedPatch.Create(FreeShip.ActiveLayer);

    for I:=1 to Plates.Count do begin
      Patch:=Plates[I - 1];                                                   // How Plate assigned to Patch?
      for J:=1 to FreeShip.NumberofStations do
        Patch.IntersectPlane(FreeShip.Station[J - 1].Plane, FreeShip.Station[J - 1].Color);
      for J:=1 to FreeShip.NumberofWaterlines do
        Patch.IntersectPlane(FreeShip.Waterline[J - 1].Plane, FreeShip.Waterline[J - 1].Color);
      for J:=1 to FreeShip.NumberofButtocks do
        Patch.IntersectPlane(FreeShip.Buttock[J - 1].Plane, FreeShip.Buttock[J - 1].Color);
      for J:=1 to FreeShip.NumberofDiagonals do
        Patch.IntersectPlane(FreeShip.Diagonal[J - 1].Plane, FreeShip.Diagonal[J - 1].Color);
    end;
//finally
    Screen.Cursor:=Prev;
//end;

  if Plates.Count > 0 then begin
    Dlg:=TFreeExpanedplatesDialog.Create(FreeShip);                           //  ShowTranslatedValues(Dlg);
    FreeShip.IsRebuildAsyncDisabled:=true;
    Dlg.Execute(FreeShip, Plates);
    FreeAndNil(Dlg);
    FreeShip.IsRebuildAsyncDisabled:=false;
  end;
  for I:=1 to Plates.Count do
  begin
    Patch:=plates[I - 1];
    FreeAndNil(Patch);
  end;
  FreeAndNil(Plates);
end;

// Delete all layers that are empty from the model
procedure TFreeEdit.Layer_DeleteEmpty(Quiet: boolean);
var
  I, N: integer;
  vUndo: TFreeUndoObject;
begin
  N:=0;
  if Quiet then
    vUndo:=nil
  else
    vUndo:=CreateUndoObject(Userstring(140), False);
  for I:=FreeShip.NumberOfLayers downto 1 do
    if (FreeShip.Layer[I - 1].Count = 0) and (FreeShip.NumberOfLayers > 1) then
    begin
      FreeShip.Layer[I - 1].Delete;
      Inc(N);
      FreeShip.FileChanged:=True;
    end;
  if FreeShip.ActiveLayer = nil then
    FreeShip.ActiveLayer:=FreeShip.Layer[FreeShip.NumberOfLayers - 1]
  else
    FreeShip.ActiveLayer:=FreeShip.ActiveLayer;
  if (N > 0) and (not Quiet) then
  begin
    vUndo.Accept;
    ShowMessage(IntToStr(N) + #32 + Userstring(141) + '.');
  end;
  if (N = 0) and (vUndo <> nil) then vUndo.Delete;
end;

// Show layer dialog window
procedure TFreeEdit.Layer_Dialog;
var
  LayerDialog: TFreeLayerDialog;
begin
  LayerDialog:=TFreeLayerDialog.Create(FreeShip);                             //ShowTranslatedValues(LayerDialog);
  LayerDialog.Execute(FreeShip);
  LayerDialog.Free;
end;

function TFreeEdit.Layer_New: TFreeSubdivisionLayer;
begin
  CreateUndoObject(Userstring(142), True);
  Result:=FreeShip.Surface.AddNewLayer;
  Result.Color:=FreeShip.Preferences.LayerColor;
  FreeShip.FileChanged:=True;
end;

// Adds a marker to the list with markers
procedure TFreeEdit.Marker_Add(Marker: TFreeMarker);
begin
  FreeShip.FMarkers.Add(Marker);
  Marker.FOwner:=FreeShip;
end;

// Delete all markers from the model
procedure TFreeEdit.Marker_Delete;
var
  I: integer;
begin
  if MessageDlg(Userstring(143), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    CreateUndoObject(Userstring(144), True);
    for I:=1 to FreeShip.NumberofMarkers do FreeShip.Marker[I - 1].Destroy;
    FreeShip.FMarkers.Clear;
    FreeShip.FileChanged:=True;
    for I:=1 to FreeShip.NumberOfViewports do
      if FreeShip.Viewport[I-1].Zoom=1.0
         then FreeShip.Viewport[I-1].ZoomExtents
         else FreeShip.Viewport[I-1].Refresh;
  end;
end;

// Import markers from a textfile
procedure TFreeEdit.Marker_Import;
var
  OpenDialog: TOpenDialog;
  Str: string;
  I: integer;
  LineNr: integer;
  P: T3DCoordinate;
  FFile: TextFile;
  Markers: TFasterListTFreeMarker;
  Marker: TFreeMarker;
  Answer: word;

  procedure Import(Markers: TFasterListTFreeMarker);
  var
    I: integer;
    Marker: TFreeMarker;
  begin
    for I:=1 to Markers.Count do begin
      Marker:=Markers[I-1];
      Marker_Add(Marker);
    end;
    FreeShip.FileChanged:=True;
    FreeShip.Visibility.ShowMarkers:=True;
    for I:=1 to FreeShip.NumberOfViewports do
      if FreeShip.Viewport[I-1].Zoom=1.0
         then FreeShip.Viewport[I-1].ZoomExtents
         else FreeShip.Viewport[I-1].Refresh;
    Freeship.RebuildModel;
  end;{import}

begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rsTextFiles, ['txt']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
    assignFile(FFile, ChangeFileExt(Opendialog.FileName, '.txt'));
{$I-}
    Reset(FFile);
{$I+}
    if IOResult = 0 then begin
      FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      LineNr:=1;                             // skip the first line of the file
      readln(FFile);
      Markers:=TFasterListTFreeMarker.Create;
//    try
//      try
          Marker:=TFreeMarker.Create(FreeShip.Surface);
          repeat
            Readln( FFile, Str );
            repeat
              i:=Pos(#9, Str);
              if I <> 0 then str[I]:=#32;
            until I = 0;
            Inc(LineNr);
            Str:=Trim( Uppercase(Str) );
            if (Str <> '') and (Str <> 'EOF') then begin
              P.X:=GetFloat( Str);
              P.Y:=GetFloat( Str);
              P.Z:=GetFloat( Str);
              Marker.Add(P);
              Str:=#32;
            end else
            if Str = '' then begin
              if Marker.NumberOfPoints > 1 then Markers.Add(Marker)
                                           else FreeAndNil(Marker);
              Marker:=TFreeMarker.Create(FreeShip.Surface);
            end;
          until (Str = 'EOF') or (EOF(FFile));
          if Marker.NumberOfPoints > 1 then Markers.Add(Marker)
                                       else FreeAndNil(Marker);
//      except
//        MessageDlg(Userstring(132) + #32 + IntToStr(LineNr), mtError, [mbOK], 0);
//      end;
//    finally
        CloseFile(FFile);
//    end;
      if Markers.Count > 0 then begin
        if FreeShip.NumberofMarkers > 0 then begin
          Answer:=MessageDlg(Userstring(145), mtConfirmation,
            [mbYes, mbNo, mbCancel], 0);
          if Answer <> mrCancel then begin
            CreateUndoObject(Userstring(146), True);
            if Answer = mrYes then begin
              for I:=1 to FreeShip.NumberofMarkers do FreeShip.Marker[I-1].Destroy;
              FreeShip.FMarkers.Clear;
            end;
            Import(Markers);
          end else begin
            for I:=1 to Markers.Count do begin
              Marker:=Markers[I - 1];
              FreeAndNil(Marker);
            end;
          end;
        end else begin
          CreateUndoObject(Userstring(146), True);
          Import(Markers);
        end;
      end else MessageDlg(Userstring(147), mtInformation, [mbOK], 0);
      FreeAndNil(Markers);
    end else MessageDlg(Userstring(106), mtError, [mbOK], 0);
  end;
  FreeAndNil(OpenDialog);
end;{TFreeEdit.Marker_Import}

// Checks the surface for inconsistent normal directions and leaks
procedure TFreeEdit.Model_Check(ShowResult: boolean);
const
  EdgeError = 1e-4;
var
  I, J: integer;
  Pt, Pt0: TFreeSubdivisionPoint;
  Point: TFreeSubdivisionControlPoint;
  Face: TFreeSubdivisionFace;
  Edge1, Edge2: TFreeSubdivisionControlEdge;
  CtrlFace: TFreeSubdivisionControlFace;
  CtrlPoint: TFreeSubdivisionControlPoint;
  AllFaces: TFasterListTFreeSubdivisionFace;
  NewGroup: TFasterListTFreeSubdivisionFace;
  DoubleEdges: TFasterListTFreeSubdivisionControlEdge;
  Points: TFasterListTFreeSubdivisionControlPoint;
  Changed: boolean;
  InvertedFaces: integer;
  Inconsistent: integer;
  NonManifold: integer;
  DblEdges: integer;
  Str: string;
  vUndo: TFreeUndoObject;
  Leaks: TFasterListTFreeSubdivisionControlPoint;
  Swap: boolean;
  NewLayer: TFreeSubdivisionLayer;
  Normal, Tmp: T3DCoordinate;
  Z_min: single;

  procedure FindConnectedFaces(DoneList, ToDoList: TFasterListTFreeSubdivisionFace);
  var
    I, J, K, Ind: integer;
    P1, P2: TFreeSubdivisionPoint;
    Edge: TFreeSubdivisionEdge;
    F1, F2: TFreeSubdivisionFace;
  begin
    I:=1;
    while I <= DoneList.Count do begin
      F1:=DoneList[I - 1];
      P1:=F1.Point[F1.NumberOfPoints - 1];
      for J:=1 to F1.NumberOfPoints do begin
        P2:=F1.Point[J - 1];
        Edge:=FreeShip.Surface.EdgeExists(P1, P2);
        if Edge <> nil then
        if Edge.NumberOfFaces > 1 then
        for K:=1 to Edge.NumberOfFaces do
         if Edge.Face[K - 1] <> F1 then begin
            F2:=Edge.Face[K - 1];
            Ind:=ToDoList.SortedIndexOf(F2);
            if Ind <> -1 then begin
               // This face is connected to the current, but not present in the
               // done-list.
               DoneList.Add(F2);
               ToDoList.Delete(Ind);
               // Also perform a check to determine if F2 is oriented in
               // the same way as F1 (clockwise or counterclockwise
               Ind:=F2.IndexOfPoint(P2);
               Ind:=(Ind + 1) mod F2.NumberOfPoints; // select the next index
               if F2.Point[ind] = P1 then     // Direction is OK, do nothing
               else begin              // direction is not ok, invert points
                 F2.FlipNormal;
                 Inc(Inconsistent);
               end;
            end;
         end;  P1:=p2;
      end;     Inc(I);
    end;
  end;// FindConnectedFaces

  var IsIntegrityOk, B:boolean;
begin
  vUndo:=self.CreateUndoObject(Userstring(148), False);
  Changed:=False;
  InvertedFaces:=0;
  Inconsistent:=0;
  NonManifold:=0;
  DblEdges:=0;
  // if ShowResult=false a quiet test is done, only the direction of facenormals is checked and fixed
  if ShowResult then
  begin
    // Find double edges
    DoubleEdges:=TFasterListTFreeSubdivisionControlEdge.Create;
    for I:=1 to FreeShip.Surface.NumberOfControlEdges do
    begin
      Edge1:=FreeShip.Surface.ControlEdge[I - 1];
      if Edge1.NumberOfFaces = 1 then
        if DoubleEdges.SortedIndexOf(Edge1) = -1 then
          for J:=1 to Edge1.StartPoint.NumberOfEdges do begin
            Edge2:=Edge1.StartPoint.Edge[J - 1] as TFreeSubdivisionControlEdge;
            if (Edge1 <> Edge2) and (Edge2.NumberOfFaces = 1) then
              if ((DistPP3D(Edge1.StartPoint.Coordinate, Edge2.StartPoint.Coordinate) <
                EdgeError) and (DistPP3D(Edge1.EndPoint.Coordinate,
                Edge2.EndPoint.Coordinate) < EdgeError)) or
                ((DistPP3D(Edge1.StartPoint.Coordinate, Edge2.EndPoint.Coordinate) <
                EdgeError) and (DistPP3D(Edge1.EndPoint.Coordinate,
                Edge2.StartPoint.Coordinate) < EdgeError)) then
                if DoubleEdges.SortedIndexOf(Edge2) = -1 then
                  DoubleEdges.AddSortedObject(Edge1, Edge2);
          end;
    end;
    Points:=TFasterListTFreeSubdivisionControlPoint.Create;
    for I:=1 to DoubleEdges.Count do
    begin
      Edge1:=DoubleEdges[I - 1];
      Edge2:=TFreeSubdivisionControlEdge(DoubleEdges.Objects[I - 1]);
      if (FreeShip.Surface.ControlEdges.IndexOf(Edge1) <> -1) and
         (FreeShip.Surface.ControlEdges.IndexOf(Edge2) <> -1) then
      begin
        // remove the face connected to edge2 and rebuild it by connecting it to edge1
        Ctrlface:=Edge2.Face[0] as TFreeSubdivisionControlFace;
        Points.Clear;
        for J:=1 to CtrlFace.NumberOfpoints do
        begin
          Point:=CtrlFace.Point[J - 1];
          if Point = Edge2.StartPoint then
          begin
            if DistPP3D(Edge2.StartPoint.Coordinate, Edge1.StartPoint.Coordinate) <
              EdgeError then
            begin
              if Points.IndexOf(Edge1.StartPoint) = -1 then
                points.Add(Edge1.StartPoint);
            end
            else if DistPP3D(Edge2.StartPoint.Coordinate, Edge1.EndPoint.Coordinate) <
              EdgeError then
              if Points.IndexOf(Edge1.EndPoint) = -1 then
                points.Add(Edge1.EndPoint);
          end
          else if Point = Edge2.EndPoint then
          begin
            if DistPP3D(Edge2.EndPoint.Coordinate, Edge1.StartPoint.Coordinate) <
              EdgeError then
            begin
              if Points.IndexOf(Edge1.StartPoint) = -1 then
                points.Add(Edge1.StartPoint);
            end
            else if DistPP3D(Edge2.EndPoint.Coordinate, Edge1.EndPoint.Coordinate) <
              EdgeError then
              if Points.IndexOf(Edge1.EndPoint) = -1 then
                points.Add(Edge1.EndPoint);
          end
          else if Points.IndexOf(Point) = -1 then
            Points.Add(Point);
        end;
        if Points.Count > 2 then
        begin
          NewLayer:=Ctrlface.Layer;
          FreeShip.Surface.AddControlFace(Points, False, NewLayer);
          CtrlFace.Delete;
          Changed:=True;
          Inc(DblEdges);
        end;
      end;
    end;
    FreeAndNil(DoubleEdges);
    FreeAndNil(Points);
  end;

  // Check for correct normal direction (outward)
  // First assemble all controlfaces and extract
  // isolated groups (not physically connected)
  AllFaces:=TFasterListTFreeSubdivisionFace.Create;
  AllFaces.Capacity:=FreeShip.Surface.NumberOfControlFaces;
  for I:=1 to FreeShip.Surface.NumberOfControlFaces do
    AllFaces.Add(FreeShip.Surface.ControlFace[I - 1]);
  AllFaces.Sort; // Sort list for faster object search

  Leaks:=TFasterListTFreeSubdivisionControlPoint.Create;
  // assemble leaks
  Z_min:=0;
  for I:=1 to FreeShip.Surface.NumberOfControlPoints do begin
    CtrlPoint:=FreeShip.Surface.ControlPoint[I - 1];
    if CtrlPoint.Coordinate.Z < Z_min then
      Z_min:=CtrlPoint.Coordinate.Z;
    // Определяем наинизшую точку
    if CtrlPoint.IsLeak then Leaks.Add(CtrlPoint);
  end;
  // sort leaks in ascending z-coordinate
  for I:=1 to Leaks.Count - 1 do
    for J:=I + 1 to Leaks.Count do begin
      Point:=Leaks[I - 1];
      Pt:=Leaks[J - 1];
      Swap:=False;
      if Pt.Coordinate.Z < Point.Coordinate.Z then Swap:=True;
      if (abs(Pt.Coordinate.Z - Point.Coordinate.Z) < 1e-6) and
        (Pt.Coordinate.X < Point.Coordinate.X) then Swap:=True;
      if (abs(Pt.Coordinate.Z - Point.Coordinate.Z) < 1e-6) and
        (abs(Pt.Coordinate.X - Point.Coordinate.X) < 1e-6) and
        (Pt.Coordinate.Y < Point.Coordinate.Y) then Swap:=True;
      if Swap then Leaks.Exchange(I-1,J-1);
    end;

  for I:=1 to FreeShip.Surface.NumberOfControlEdges do
    if FreeShip.Surface.ControlEdge[I-1].NumberOfFaces > 2 then Inc(NonManifold);

  if AllFaces.Count > 0 then
  begin
    NewGroup:=TFasterListTFreeSubdivisionFace.Create;
    while AllFaces.Count > 0 do
    begin
      Face:=AllFaces[AllFaces.Count - 1];
      AllFaces.Delete(AllFaces.Count - 1);
      NewGroup.Clear;
      NewGroup.Capacity:=AllFaces.Count;
      NewGroup.Add(Face);
      // use the first face as seed for the following procedure
      FindConnectedFaces(NewGroup, AllFaces);
      NewGroup.Sort;

      // find the lowest point of this group of faces
      Pt0:=nil;
      for I:=1 to NewGroup.Count do begin
        Face:=NewGroup[I - 1];
        for j:=1 to Face.NumberOfPoints do begin
          Pt:=Face.Point[J - 1];
                 //if Point = nil then //MM 04/26/2019: Why Point? Changed to Pt
          if Pt = nil then Pt0:=Pt
                 //else if Pt.Coordinate.Z < Point.Coordinate.Z then //MM: same
          else if Pt.Coordinate.Z < Pt.Coordinate.Z then Pt0:=Pt;
        end;
      end;

      if Pt0 <> nil then begin
        // select the a face connected to this point and also present in the
        // newgroup-list with faces and with the most vertical normal of all canditates
        Face:=nil;
        for I:=1 to Pt0.NumberOfFaces do
          if NewGroup.SortedIndexOf(Pt0.Face[I - 1]) <> -1 then
            if Face = nil then begin
              Face:=Pt0.Face[I - 1];
              normal:=Face.FaceNormal;
            end else begin
              Tmp:=Pt0.Face[I - 1].FaceNormal;
              if abs(Tmp.Z) > abs(Normal.Z) then begin
                Face:=Pt0.Face[I - 1];
                normal:=Face.FaceNormal;
              end;
            end;                                                                // MessageDlg('flip I='+FloatToStrF(I,ffFixed,7,3)+' N.X='+FloatToStrF(Normal.X,ffFixed,7,3)+' N.Y='+FloatToStrF(Normal.Y,ffFixed,7,3)+' N.Z='+FloatToStrF(Normal.Z,ffFixed,7,3),mtError,[mbOk],0);
        if Face <> nil then
        if Normal.Z > 0.0 then begin
              // normal points upward, all faces in this group must be inverted
          for I:=0 to NewGroup.Count - 1 do begin
            Face:=NewGroup[I];
            Face.FlipNormal;
          end;
          Changed:=True;
          Inc(InvertedFaces, NewGroup.Count);
        end;
      end;
    end;

    FreeAndNil(NewGroup);
    if (Leaks.Count > 0) and (ShowResult) then begin
      Str:=Userstring(149) + ' ' + IntToStr(Leaks.Count) + ' ' + Userstring(150) + '.';
      if Leaks.Count > 10 then Str:=Str + EOL + Userstring(151) + ':';
      Str:=Str + EOL;
      for I:=1 to Leaks.Count do begin
        Point:=Leaks[I - 1];
        Str:=Str + EOL + FloatToStrF(Point.Coordinate.X, ffFixed, 7, 3) +
          ', ' + FloatToStrF(Point.Coordinate.Y, ffFixed, 7, 3) +
          ', ' + FloatToStrF(Point.Coordinate.Z, ffFixed, 7, 3);
        if I = 10 then break;
      end;
      MessageDlg(Str, mtWarning, [mbOK], 0);
    // begin Victor T
       Point:=Leaks[0];
       if Point.Coordinate.Z-Z_min < FreeShip.ProjectSettings.ProjectDraft then
          MessageDlg(Userstring(899), mtWarning, [mbOK], 0);
    // end Victor T
    end;

    if (Changed) or (Inconsistent > 0) or (NonManifold > 0) or (DblEdges > 0) then
    begin
      vUndo.Accept;
      FreeShip.Built:=False;
      Freeship.RebuildModel;
      FreeShip.FileChanged:=True;
      if ShowResult then
      begin
        Str:=Userstring(152) + ':';
        if DblEdges > 0 then
          Str:=Str + EOL + IntToStr(DblEdges) + ' ' + UserString(158) + '.';
        if Inconsistent > 0 then
          Str:=Str + EOL + IntToStr(Inconsistent) + ' ' + Userstring(153) + '.';
        if InvertedFaces > 0 then
          Str:=Str + EOL + IntToStr(InvertedFaces) + ' ' + Userstring(154) + '.';
        if NonManifold > 0 then
          Str:=Str + EOL + IntToStr(NonManifold) + ' ' + Userstring(155);
        MessageDlg(Str, mtInformation, [mbOK], 0);
        if assigned(FreeShip.FOnUpdateGeometryInfo) then
          FreeShip.FOnUpdateGeometryInfo(self);
      end;
    end else begin
      vUndo.Delete;
      if (ShowResult) and (Leaks.Count = 0) then ShowMessage(Userstring(156));
    end;
    FreeAndNil(Leaks);
  end;
  FreeAndNil(AllFaces);

  IsIntegrityOk:=true;
  for i:=0 to FreeShip.Surface.NumberOfLayers-1 do begin
    B:=FreeShip.Layer[i].CheckIntegrity;                                        //  if not B then logger.Error(Format('In Layer[%d]',[i]));
    IsIntegrityOk:=IsIntegrityOk and B;
  end;

  if not IsIntegrityOk then
    ShowMessage('Layers integrity is not Ok. Enable logs and check logs output. Further processing is not safe.');
{
  for i:=0 to FreeShip.Surface.NumberOfControlFaces-1 do
    IsIntegrityOk:=IsIntegrityOk and FreeShip.Surface.ControlFace[i].CheckIntegrity;
  if not IsIntegrityOk then
    ShowMessage('ControlFaces integrity is not Ok. Enable logs and check logs output. Further processing is not safe.');
}
end;

// Start a new model (with a predefined surface)
// returns true if a new model has indeed been created

function TFreeEdit.Model_New: boolean;
var
  Answer: word;
  L, B, D: TFloatType;
  I, J: integer;
  Cols, Rows: integer;
  P: T3DCoordinate;
  Default: array[0..6, 0..4] of T3DCoordinate;
  // Default ship has 7 columns of 5 points(or rows)
  Spline1: TFreeSpline;
  Spline2: TFreeSpline;
  TrvSplines: TFasterListTFreeSpline;
  TrvPoints: TFasterListTFreeSubdivisionControlPoint;
  Pts: array of array of TFreeSubdivisionControlPoint;
  StemPoint: TFreeSubdivisionControlPoint;
  FreeNewModelDialog: TFreeNewModelDialog;

  function Point3D(X, Y, Z: TFloattype): T3DCoordinate;
  begin
    Result.X:=X;
    Result.Y:=Y;
    Result.Z:=Z;
  end;{Point3D}

begin
  Result:=False;
  Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
  if (Answer=mrCancel) or FreeShip.FileChanged then exit;
(*                                                                      ////+++
  if FreeShip.FileChanged then begin
    Answer:=MessageDlg(Userstring(103) + EOL + Userstring(104),mtConfirmation, [mbYes, mbNo, mbCancel], 0);
    if Answer = mrCancel then exit;
    if Answer = mrYes then begin
!!!   FreeShip.Edit.File_SaveAs( false );
      if FreeShip.FileChanged then exit; // Apparently saving was not successfull, abort
    end;
  end;
*)
  FreeNewModelDialog:=TFreeNewModelDialog.Create(FreeShip);                   //ShowTranslatedValues(FreeNewModelDialog);
  if FreeNewModelDialog.Execute then begin
    FreeShip.ModelIsLoaded:=False;
    CreateUndoObject( Userstring(157), True );
    Cols:=FreeNewModelDialog.NCols - 1;
    Rows:=FreeNewModelDialog.NRows - 1;
    L:=FreeNewModelDialog.Length;
    B:=FreeNewModelDialog.Breadth;
    D:=FreeNewModelDialog.Draft;
    // station 0, stern
    Default[0, 0]:=Point3D(0.00000, 0.00000, 1.56754);
    Default[0, 1]:=Point3D(0.00000, 0.05280, 1.59170);
    Default[0, 2]:=Point3D(0.00000, 0.22171, 1.77284);
    Default[0, 3]:=Point3D(0.00000, 0.28506, 2.64108);
    Default[0, 4]:=Point3D(0.00000, 0.29135, 3.48932);
    // station 1
    Default[1, 0]:=Point3D(0.20880, 0.00000, 0.49656);
    Default[1, 1]:=Point3D(0.20881, 0.18796, 0.53622);
    Default[1, 2]:=Point3D(0.20880, 0.33700, 0.97840);
    Default[1, 3]:=Point3D(0.20880, 0.45607, 2.05422);
    Default[1, 4]:=Point3D(0.20882, 0.47184, 3.44280);
    // station 2
    Default[2, 0]:=Point3D(0.41765, 0.00000, 0.00000);
    Default[2, 1]:=Point3D(0.41765, 0.23565, 0.07524);
    Default[2, 2]:=Point3D(0.41765, 0.41555, 0.67735);
    Default[2, 3]:=Point3D(0.41765, 0.49421, 1.91004);
    Default[2, 4]:=Point3D(0.41737, 0.51468, 3.45474);
    // station 3
    Default[3, 0]:=Point3D(0.58471, 0.00000, 0.00000);
    Default[3, 1]:=Point3D(0.58472, 0.24072, 0.02507);
    Default[3, 2]:=Point3D(0.58472, 0.39528, 0.71080);
    Default[3, 3]:=Point3D(0.58488, 0.45356, 2.04881);
    Default[3, 4]:=Point3D(0.58472, 0.46756, 3.54662);
    // station 4
    Default[4, 0]:=Point3D(0.75179, 0.00000, 0.28284);
    Default[4, 1]:=Point3D(0.75178, 0.13715, 0.44098);
    Default[4, 2]:=Point3D(0.75179, 0.20950, 0.87760);
    Default[4, 3]:=Point3D(0.75179, 0.30538, 2.38232);
    Default[4, 4]:=Point3D(0.75177, 0.34473, 3.67786);
    // station 5
    Default[5, 0]:=Point3D(0.90672, 0.00000, 0.81860);
    Default[5, 1]:=Point3D(0.90681, 0.01887, 0.98650);
    Default[5, 2]:=Point3D(0.90658, 0.04671, 1.29873);
    Default[5, 3]:=Point3D(0.90637, 0.11195, 2.83107);
    Default[5, 4]:=Point3D(0.90672, 0.14523, 3.81697);
    // station 6 , stem
    Default[6, 0]:=Point3D(0.91580, 0.00000, 0.85643);
    Default[6, 1]:=Point3D(0.92562, 0.00000, 1.17444);
    Default[6, 2]:=Point3D(0.93387, 0.00000, 1.44618);
    Default[6, 3]:=Point3D(0.97668, 0.00000, 3.03482);
    Default[6, 4]:=Point3D(1.00000, 0.00000, 3.91366);
    FreeShip.Clear;

    FreeShip.ProjectSettings.ProjectUnits :=
      TFreeUnitType(FreeNewModelDialog.ComboBox1.ItemIndex);
    FreeShip.ProjectSettings.ProjectLength:=L;
    FreeShip.ProjectSettings.ProjectBeam:=B;
    FreeShip.ProjectSettings.ProjectDraft:=D;

    TrvSplines:=TFasterListTFreeSpline.Create;
    StemPoint:=nil;
    // First create tmp. splines in transverse direction
    for I:=0 to 6 do
    begin
      Spline1:=TFreeSpline.Create(FreeShip.Surface);
      for J:=0 to 4 do
      begin
        P:=Default[I, J];
        P.X:=P.X * L;
        P.Y:=P.Y * B;
        P.Z:=P.Z * D;
        Spline1.Add(P);
      end;
      TrvSplines.Add(Spline1);
    end;
    // now create tmp. splines in longitudinal direction
    Setlength(Pts, Rows + 1);
    for I:=0 to rows do
    begin
      Setlength(Pts[I], Cols + 1);
      Spline2:=TFreeSpline.Create(FreeShip.Surface);
      for j:=0 to TrvSplines.Count - 1 do
      begin
        Spline1:=TrvSplines[J];
        P:=Spline1.Value(I / Rows);
        Spline2.Add(P);
      end;
      // now calculate all points on the longitudinal spline and send it to the surface
      for J:=0 to Cols do
      begin
        P:=Spline2.Value(J / Cols);
        Pts[I, J]:=TFreeSubdivisionControlPoint.Create(FreeShip.Surface);
        FreeShip.Surface.AddControlPoint(Pts[I, J]);
        Pts[I, J].Coordinate:=P;
        if (I = 0) and (J = Cols) then
          StemPoint:=Pts[I, J];
      end;
      FreeAndNil(Spline2);
    end;
    for I:=1 to TrvSplines.Count do begin              // Destroy tmp splines
      Spline1:=TrvSplines[I - 1];
      FreeAndNil(Spline1);
    end;
    TrvPoints:=TFasterListTFreeSubdivisionControlPoint.Create; // finally create the controlfaces over the newly calculated points
    for I:=1 to Rows do
    for J:=1 to cols do begin
        TrvPoints.Clear;
        TrvPoints.Add(Pts[I, J - 1]);
        TrvPoints.Add(Pts[I, J]);
        TrvPoints.Add(Pts[I - 1, J]);
        TrvPoints.Add(Pts[I - 1, J - 1]);
        FreeShip.Surface.AddControlFace(TrvPoints, True);
    end;
    // recheck edges crease after all faces added.
    for i:=0 to FreeShip.Surface.ControlEdges.Count-1 do
       FreeShip.Surface.ControlEdge[i].Crease:=false;

    FreeShip.Precision:=fpMedium;
    FreeShip.Surface.Initialize(1, 1, 1);
    // Collapse stempoint to mage the grid irregular in order to demonstrate subdivision-surface capabilities
    if StemPoint <> nil then
      if StemPoint.VertexType = svCorner then
        stempoint.VertexType:=svCrease;
    FreeShip.Built:=False;

    // Add 21 stations
    for I:=0 to 20 do
      Intersection_Add(fiStation,I/20*(FreeShip.Surface.Max.X-FreeShip.Surface.Min.X));
    // Add 7 buttocks
    for I:=1 to 6 do
      Intersection_Add(fiButtock,I/7*(FreeShip.Surface.Max.Y-FreeShip.Surface.Min.Y));
    // Add 11 waterlines
    for I:=0 to 10 do
      Intersection_Add(fiWaterline,I/10*(FreeShip.Surface.Max.Z-FreeShip.Surface.Min.Z));
    FreeShip.FileChanged:=True;
    FreeShip.ModelIsLoaded:=True;
    FreeShip.Filename:='New Model.ftm';
    if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
    Result:=True;
    FreeAndNil( TrvSplines );
    TrvPoints.Free;
    FreeShip.ZoomFitAllViewports;
    FreeShip.ReDraw;
  end;
  FreeAndNil(FreeNewModelDialog);
//FreeShip.ReDraw;
end;

// Affine hullform transformation according to Lackenby
procedure TFreeEdit.Model_LackenbyTransformation;
var
  Dialog: TFreeLackenbyDialog;
  vUndo: TFreeUndoObject;
  UndoIndex: integer;
  I: integer;
  Modified: boolean;
begin
  if not FreeShip.ProjectSettings.FMainparticularsHasBeenset then begin
    MessageDlg( Userstring(96), mtError, [mbOK], 0 );
    exit;
  end;
  Dialog:=TFreeLackenbyDialog.Create(FreeShip);                               //ShowTranslatedValues(Dialog);
  vUndo:=CreateUndoObject(Userstring(159), False);
  UndoIndex:=FreeShip.UndoCount;
  if Dialog.Execute(FreeShip, Modified) then begin
    for I:=FreeShip.UndoCount downto UndoIndex + 1 do
             FreeShip.UndoObject[I - 1].Delete;
    if not Modified then vUndo.Delete else vUndo.Accept;
  end else begin
    for I:=FreeShip.UndoCount downto UndoIndex + 1 do
             FreeShip.UndoObject[I - 1].Delete;
    if Modified then
      vUndo.Restore;
    vUndo.Delete;
  end;
  FreeAndNil(Dialog);
end;

// Scale the entire model and all equivalent data such as stations etc.

procedure TFreeEdit.Model_Scale(ScaleVector: T3DCoordinate; OverrideLock, AdjustMarkers: boolean);
var
  I, J: integer;
  Point: TFreeSubdivisionControlPoint;
  P: T3DCoordinate;
  Marker: TFreeMarker;
begin
  for I:=1 to FreeShip.Surface.NumberOfControlPoints do begin
    Point:=FreeShip.Surface.ControlPoint[I - 1];
    if (not Point.Locked) or (OverrideLock) then begin
      P:=Point.Coordinate;
      P.X:=P.X * ScaleVector.X;
      P.Y:=P.Y * ScaleVector.Y;
      P.Z:=P.Z * ScaleVector.Z;
      if Point.Locked then begin Point.Locked:=False;
//    try
        Point.Coordinate:=P;
//    finally
        Point.Locked:=True;
//    end;
      end else Point.Coordinate:=P;
    end;
  end;
  // Update Mainparticulars
  FreeShip.ProjectSettings.ProjectLength:=abs(FreeShip.ProjectSettings.ProjectLength * Scalevector.X);
  FreeShip.ProjectSettings.ProjectBeam:=abs(FreeShip.ProjectSettings.ProjectBeam * Scalevector.Y);
  FreeShip.ProjectSettings.ProjectDraft:=abs(FreeShip.ProjectSettings.ProjectDraft * Scalevector.Z);
  if not FreeShip.ProjectSettings.FUseDefaultSplitSectionLocation then
    FreeShip.ProjectSettings.ProjectSplitSectionLocation:=abs(FreeShip.ProjectSettings.ProjectSplitSectionLocation * ScaleVector.X);

  // Update markers
  if AdjustMarkers then
    for I:=0 to FreeShip.NumberOfMarkers-1 do begin Marker:=FreeShip.Marker[I];
      for j:=0 to Marker.NumberOfPoints-1 do begin P:=Marker.Point[J];
        P.X:=P.X*Scalevector.X;
        P.Y:=P.Y*Scalevector.Y;
        P.Z:=P.Z*Scalevector.Z;
        Marker.Point[J]:=P;
      end;
    end;
  // Update stations, buttcks and waterlines    ///+++ было отключено ???
  for I:=0 to FreeShip.NumberofStations-1 do
    FreeShip.Station[I].FPlane.d:=FreeShip.Station[I].FPlane.d*ScaleVector.X;
  for I:=0 to FreeShip.NumberofButtocks-1 do
    FreeShip.Buttock[I].FPlane.d:=FreeShip.Buttock[I].FPlane.d*ScaleVector.Y;
  for I:=0 to FreeShip.NumberofWaterlines-1 do
    FreeShip.Waterline[I].FPlane.d:=FreeShip.Waterline[I].FPlane.d*ScaleVector.Z;
  for I:=0 to FreeShip.NumberofDiagonals-1 do
    FreeShip.Diagonal[I].FPlane.d:=FreeShip.Diagonal[I].FPlane.d*ScaleVector.Z;

  Freeship.InvalidateIntersections;

  // Refresh controlpoint data
  FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
  // Reset any present hydrostatic calculations
  for I:=1 to FreeShip.NumberOfHydrostaticCalculations do begin
    FreeShip.HydrostaticCalculation[I-1].Draft:=abs(FreeShip.HydrostaticCalculation[I-1].Draft * ScaleVector.Z);
    FreeShip.HydrostaticCalculation[I-1].Trim:=FreeShip.HydrostaticCalculation[I-1].Trim * ScaleVector.Z;
    FreeShip.HydrostaticCalculation[I-1].Calculated:=False;
  end;

  // Initialize all other data
  FreeShip.Built:=False;                                           // Redraw
  FreeShip.FileChanged:=True;
  FreeShip.Draw;
end;

// Merge two selected edges by removing their common controlpoint.
procedure TFreeEdit.Point_Collapse;
var
  I, N: integer;
  Point: TFreeSubdivisionControlPoint;
  vUndo: TFreeUndoObject;
begin
  N:=0;
  // count points to be collapsed
  for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do begin
    Point:=FreeShip.SelectedControlPoint[I - 1];
    if (not Point.Locked) and (Point.NumberOfEdges = 2) then Inc(N);
  end;
  if N > 0 then FreeShip.Surface.ClearMesh;

  vUndo:=CreateUndoObject(Userstring(160), False);
  for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do begin
    Point:=FreeShip.SelectedControlPoint[I - 1];
    if (not Point.Locked) and (Point.NumberOfEdges = 2) then begin
      Point.Collapse;
      Inc(N);
    end;
  end;
  if N > 0 then begin
    vUndo.Accept;
    FreeShip.Built:=False;
    Freeship.RebuildModel;
    FreeShip.FileChanged:=True;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
  end
  else vUndo.Delete;
end;

// removes any unused points from the model
procedure TFreeEdit.Point_RemoveUnused;
var
  I, N: integer;
  Point: TFreeSubdivisionControlPoint;
  vUndo: TFreeUndoObject;
begin
  N:=0;
  vUndo:=CreateUndoObject(Userstring(161), False);
  for I:=FreeShip.Surface.NumberOfControlPoints downto 1 do begin
    Point:=FreeShip.Surface.ControlPoint[I - 1];
    if Point.NumberOfFaces = 0 then begin
      Point.Delete;
      Inc(N);
    end;
  end;
  if N > 0 then begin
    vUndo.Accept;
    FreeShip.Built:=False;
    Freeship.RebuildModel;
    FreeShip.FileChanged:=True;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then
      FreeShip.OnUpdateGeometryInfo(self);
    MessageDlg(IntToStr(N) + #32 + Userstring(162), mtInformation, [mbOK], 0);
  end
  else vUndo.Delete;
end;

// Finds all intersection of VISIBLE edges and a 3D plane, and inserts a point on each of these edges
procedure TFreeEdit.Point_InsertPlane;
var
  Dialog: TFreeInsertPlaneDialog;
  Min, Max: T3DCoordinate;
  vUndo: TFreeUndoObject;
  N: integer;
begin
  FreeShip.Extents(Min, Max);
  Dialog:=TFreeInsertPlaneDialog.Create(FreeShip);                            //ShowTranslatedValues(Dialog);
  Dialog.Max:=Max;
  Dialog.Min:=Min;
  if Dialog.Execute then begin
    vUndo:=CreateUndoObject(UserString(163), False);
    N:=FreeShip.Surface.NumberOfControlPoints;
    FreeShip.Surface.InsertPlane(Dialog.Plane, Dialog.CreateControlCurve);
    if N < FreeShip.Surface.NumberOfControlPoints then begin
      vUndo.Accept;
      FreeShip.FileChanged:=True;
      FreeShip.Built:=False;
      Freeship.RebuildModel;
      if Assigned(FreeShip.OnUpdateGeometryInfo) then
        FreeShip.OnUpdateGeometryInfo(self);
    end
    else vUndo.Delete; // nothis has been changed
  end;
  FreeAndNil(Dialog);
end;

// Calculates the intersection points of two layers
procedure TFreeEdit.Point_IntersectLayer;
var
  I: integer;
  Layers: TFasterListTFreeSubdivisionLayer;
  vUndo: TFreeUndoObject;
  Dialog: TFreeIntersectLayerDialog;
begin
  Layers:=TFasterListTFreeSubdivisionLayer.Create;
  for I:=1 to FreeShip.NumberOfLayers do
    if FreeShip.Layer[I - 1].Count > 0 then
      Layers.Add(FreeShip.Layer[I - 1]);
  if Layers.Count > 1 then
  begin
    Dialog:=TFreeIntersectLayerDialog.Create(FreeShip);                       //  ShowTranslatedValues(Dialog);
    if Dialog.Execute(Layers) then
      if assigned(Dialog.Layer1) and assigned(Dialog.Layer2) then
      begin
        vUndo:=CreateUndoObject(Userstring(164), False);
        if Dialog.Layer1.CalculateIntersectionPoints(Dialog.Layer2) then
        begin
          vUndo.Accept;
          FreeShip.FileChanged:=True;
          FreeShip.Built:=False;
          Freeship.RebuildModel;
          if Assigned(FreeShip.OnUpdateGeometryInfo) then
            FreeShip.OnUpdateGeometryInfo(self);
        end
        else
        begin
          vUndo.Delete;
          MessageDlg(Userstring(165), mtInformation, [mbOK], 0);
        end;
      end;
    FreeAndNil(Dialog);
  end
  else
    MessageDlg(Userstring(166), mtError, [mbOK], 0);
  FreeAndNil(Layers);
end;

// Locks all selected points
procedure TFreeEdit.Point_Lock;
var
  I: integer;
begin
  if FreeShip.NumberOfSelectedLockedPoints < FreeShip.NumberOfSelectedControlPoints then
  begin
    self.CreateUndoObject(UserString(167), True);
    for I:=1 to FreeShip.NumberOfSelectedControlPoints do
      FreeShip.SelectedControlPoint[I - 1].Locked:=True;
    FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
    Freeship.ReDraw;
    FreeShip.FileChanged:=True;
  end;
end;

// Unlocks all selected locked points
procedure TFreeEdit.Point_Unlock;
var
  I: integer;
begin
  if FreeShip.NumberOfSelectedLockedPoints > 0 then
  begin
    self.CreateUndoObject(Userstring(168), True);
    for I:=1 to FreeShip.NumberOfSelectedControlPoints do
      FreeShip.SelectedControlPoint[I - 1].Locked:=False;
    FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
    Freeship.ReDraw;
    FreeShip.FileChanged:=True;
  end;
end;

// Unlocks all locked points
procedure TFreeEdit.Point_UnlockAll;
var
  I, N: integer;
begin
  if FreeShip.NumberOfLockedPoints > 0 then
  begin
    CreateUndoObject(Userstring(169), True);
    N:=FreeShip.NumberOfLockedPoints;
    for I:=1 to FreeShip.Surface.NumberOfControlPoints do
      FreeShip.Surface.ControlPoint[I - 1].Locked:=False;
    FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
    Freeship.ReDraw;
    MessageDlg(IntToStr(N) + #32 + Userstring(170) + '.', mtInformation, [mbOK], 0);
    FreeShip.FileChanged:=True;
  end;
end;

// Function that shows a warning when certain edit commands are invoked and the model contains locked points
function TFreeEdit.ProceedWhenLockedPoints: boolean;
begin
  if FreeShip.NumberOfLockedPoints > 0 then
    Result:=MessageDlg(Userstring(86) + EOL + Userstring(87),
      mtWarning, [mbYes, mbNo], 0) = mrYes
  else
    Result:=True;
end;

// Add a new point to the model with no edges/faces attached

function TFreeEdit.Point_New: TFreeSubdivisionControlPoint;
begin
  Result:=TFreeSubdivisionControlPoint.Create(FreeShip.Surface);
  FreeShip.Surface.AddControlPoint(Result);
  Result.Coordinate:=ZERO;
  FreeShip.ActiveControlPoint:=Result;
  FreeShip.Surface.Selection_Add(Result);
  FreeShip.FileChanged:=True;
  Freeship.ReDraw; // we do not rebuild model because no impact on subdivision yet
  if Assigned(FreeShip.OnUpdateGeometryInfo) then
    FreeShip.OnUpdateGeometryInfo(self);
end;

// Add a new point with XYZ to the model with no edges/faces attached
function TFreeEdit.Point_New(coord:T3DCoordinate): TFreeSubdivisionControlPoint;
begin
  Result:=TFreeSubdivisionControlPoint.Create(FreeShip.Surface);
  FreeShip.Surface.AddControlPoint(Result);
  Result.Coordinate:=coord;
  FreeShip.ActiveControlPoint:=Result;
  FreeShip.Surface.Selection_Add(Result);
  FreeShip.FileChanged:=true;
  FreeShip.Surface.Changed:=true;
  Freeship.ReDraw;
  if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
end;

// Anchor all selected points onto the first point
procedure TFreeEdit.Point_AnchorToPoint;
var
  I: integer;
  NLocked: integer;
  NChanged: integer;
  Point: TFreeSubdivisionControlPoint;
  P1, P2: TFreeSubdivisionControlPoint;
  P: T3DCoordinate;
  vUndo: TFreeUndoObject;
begin
  if FreeShip.NumberOfSelectedControlPoints > 1 then
  begin
    NLocked:=0;
    for I:=1 to FreeShip.NumberOfSelectedControlPoints-1 do
      if FreeShip.SelectedControlPoint[I].Locked then
        Inc(NLocked);
    // Number of lovked points must be smaller then NumberOfSelectedControlPoints-2
    if NLocked < FreeShip.NumberOfSelectedControlPoints - 1 then begin
      P1:=FreeShip.SelectedControlPoint[0];
      vUndo:=CreateUndoObject(rsPointAnchorConstraintChanged, False);
      NChanged:=0;
      for I:=1 to FreeShip.NumberOfSelectedControlPoints-1 do
      begin
        Point:=FreeShip.SelectedControlPoint[I];
        if not Point.Locked then
        begin
          Point.AnchorPoint:=P1;
          Inc(NChanged);
        end;
      end;
      if NChanged > 0 then
      begin
        vUndo.Accept;
        FreeShip.FileChanged:=True;
        Freeship.RebuildModel;
      end
      else
        vUndo.Delete;
    end
    else
      MessageDlg(Userstring(172) + '.', mtError, [mbOK], 0);
  end;
end;

// get selected points together to the first one
procedure TFreeEdit.Point_CoinsideToPoint;
var
  I: integer;
  NLocked: integer;
  NChanged: integer;
  Point: TFreeSubdivisionControlPoint;
  P1, P2: TFreeSubdivisionControlPoint;
  P: T3DCoordinate;
  vUndo: TFreeUndoObject;
begin
  if FreeShip.NumberOfSelectedControlPoints > 1 then
  begin
    NLocked:=0;
    // Determine if the number of points to be moved does not conatin locked
    // or hard anchored controlpoints.
    // However the first and last points (determining the linesegment) are
    // allowed to be locked or hard anchored
    NLocked:=0;
    for I:=1 to FreeShip.NumberOfSelectedControlPoints-1 do
      begin
      Point:=FreeShip.SelectedControlPoint[I];
      if Point.Locked or ((Point.AnchorPoint<>nil) and Point.IsAnchorHard)
        then
        Inc(NLocked);
      end;
    // Number of locked or hard anchored points must be smaller then NumberOfSelectedControlPoints-2
    if NLocked < FreeShip.NumberOfSelectedControlPoints - 1 then
    begin
      P1:=FreeShip.SelectedControlPoint[0];
      vUndo:=CreateUndoObject(rsPointAnchorConstraintChanged, False);
      NChanged:=0;
      for I:=1 to FreeShip.NumberOfSelectedControlPoints-1 do
      begin
        Point:=FreeShip.SelectedControlPoint[I];
        if not Point.Locked
          and not((Point.AnchorPoint<>nil) and Point.IsAnchorHard) then
        begin
          Point.Coordinate:=P1.Coordinate;
          Inc(NChanged);
        end;
      end;
      if NChanged > 0 then
      begin
        vUndo.Accept;
        FreeShip.FileChanged:=True;
        Freeship.RebuildModel;
      end
      else
        vUndo.Delete;
    end
    else
      MessageDlg(Userstring(172) + '.', mtError, [mbOK], 0);
  end;
end;

// Project all selected points onto a straight line through the first and last selected points
procedure TFreeEdit.Point_ProjectStraightLine;
var
  I: integer;
  NLocked: integer;
  NChanged: integer;
  Point: TFreeSubdivisionControlPoint;
  P1, P2: TFreeSubdivisionControlPoint;
  P: T3DCoordinate;
  vUndo: TFreeUndoObject;
begin
  if FreeShip.NumberOfSelectedControlPoints > 2 then
  begin
    // Determine if the number of points to be moved does not conatin locked
    // or hard anchored controlpoints.
    // However the first and last points (determining the linesegment) are
    // allowed to be locked or hard anchored
    NLocked:=0;
    for I:=1 to FreeShip.NumberOfSelectedControlPoints-1 do begin
      Point:=FreeShip.SelectedControlPoint[I];
      if Point.Locked or ((Point.AnchorPoint<>nil) and Point.IsAnchorHard)
        then Inc(NLocked);
      end;
    // Number of locked or hard anchored points must be smaller then NumberOfSelectedControlPoints-2
    if NLocked < FreeShip.NumberOfSelectedControlPoints - 2 then begin
      P1:=FreeShip.SelectedControlPoint[0];
      P2:=FreeShip.SelectedControlPoint[FreeShip.NumberOfSelectedControlPoints - 1];
      vUndo:=CreateUndoObject(userstring(171), False);
      NChanged:=0;
      for I:=2 to FreeShip.NumberOfSelectedControlPoints - 1 do begin
        Point:=FreeShip.SelectedControlPoint[I - 1];
        if not Point.Locked
          and not((Point.AnchorPoint<>nil) and Point.IsAnchorHard) then begin
          P:=ProjectPointOnline(Point.Coordinate, P1.Coordinate, P2.Coordinate);
          if DistPP3D(P, Point.Coordinate) > 1e-7 then begin
            Point.Coordinate:=P;
            Inc(NChanged);
          end;
        end;
      end;
      if NChanged > 0 then begin
        vUndo.Accept;
        FreeShip.FileChanged:=True;
        Freeship.RebuildModel;
      end else vUndo.Delete;
    end
    else
      MessageDlg(Userstring(172) + '.', mtError, [mbOK], 0);
  end;
end;

// Project all selected points onto a straight line through the first and last selected points
procedure TFreeEdit.Point_ProjectStraightLinePermanentConstraint;
var
  I: integer;
  NLocked: integer;
  NChanged: integer;
  Point: TFreeSubdivisionControlPoint;
  P1, P2: TFreeSubdivisionControlPoint;
  P: T3DCoordinate;
  vUndo: TFreeUndoObject;
begin
  if FreeShip.NumberOfSelectedControlPoints > 2 then
  begin
    // Determine if the number of points to be moved does not conatin locked controlpoints only
    // however the first and last points (determining the linesegment) are allowed to be locked
    NLocked:=0;
    for I:=2 to FreeShip.NumberOfSelectedControlPoints - 1 do
      if FreeShip.SelectedControlPoint[I - 1].Locked then Inc(NLocked);
    // Number of lovked points must be smaller then NumberOfSelectedControlPoints-2
    if NLocked < FreeShip.NumberOfSelectedControlPoints - 2 then
    begin
      P1:=FreeShip.SelectedControlPoint[0];
      P2:=FreeShip.SelectedControlPoint[FreeShip.NumberOfSelectedControlPoints - 1];
      vUndo:=CreateUndoObject(rsPointLinearConstraintChanged, False);
      NChanged:=0;
      for I:=2 to FreeShip.NumberOfSelectedControlPoints - 1 do begin
        Point:=FreeShip.SelectedControlPoint[I - 1];
        if not Point.Locked then begin
          Point.SetLinearConstraint(P1,P2);
          Point.AdjustToLinearConstraint(self.FreeShip.GetFocusedViewport);
          Inc(NChanged);
        end;
      end;
      if NChanged > 0 then begin
        vUndo.Accept;
        FreeShip.FileChanged:=True;
        Freeship.RebuildModel;
      end else vUndo.Delete;
    end else MessageDlg(Userstring(172) + '.', mtError, [mbOK], 0);
  end;
end;

// Deselect all selected items at once
procedure TFreeEdit.Selection_Clear;
begin
  FreeShip.Surface.Clearselection;
  FreeShip.ActiveControlPoint:=nil;
  FreeShip.FSelectedFlowlines.Clear;
  FreeShip.FSelectedMarkers.Clear;
  Freeship.ReDraw;
end;

procedure TFreeEdit.Selection_Delete;
var
  I, N: integer; DelDlg:TFreeDeleteDialog;
  MR: TModalResult;
begin
  N:=FreeShip.NumberOfSelectedControlPoints
     + FreeShip.NumberOfSelectedControlPointGroups
     + FreeShip.NumberOfSelectedControlEdges
     + FreeShip.NumberOfSelectedControlFaces
     + FreeShip.NumberOfSelectedControlCurves
     + FreeShip.NumberOfselectedMarkers
     + FreeShip.NumberOfselectedFlowlines;

  MR:=mrCancel;
  if N > 0 then begin
      DelDlg:=TFreeDeleteDialog.Create(nil);
      DelDlg.FreeShip:=FreeShip;
      DelDlg.Reload;
      DelDlg.ShowModal;
      MR:=DelDlg.ModalResult;
      DelDlg.Free;
    end;
  N:=FreeShip.NumberOfSelectedControlPoints
     + FreeShip.NumberOfSelectedControlPointGroups
     + FreeShip.NumberOfSelectedControlEdges
     + FreeShip.NumberOfSelectedControlFaces
     + FreeShip.NumberOfSelectedControlCurves
     + FreeShip.NumberOfselectedMarkers
     + FreeShip.NumberOfselectedFlowlines;                                      // if MessageDlg(Userstring(173) + #32 + IntToStr(N) + #32 + Userstring( 174) + '?', mtWarning, [mbYes, mbNo], 0) = mrYes then

   if (MR = mrAbort) and (N > 0) then
   begin
      CreateUndoObject(Userstring(175), True);
      for I:=FreeShip.NumberOfselectedFlowlines downto 1 do FreeShip.SelectedFlowline[I-1].Delete;
      for I:=FreeShip.NumberOfselectedMarkers downto 1 do FreeShip.SelectedMarker[I-1].Delete;
      FreeShip.Surface.Selection_Delete;
      FreeShip.ActiveControlPoint:=nil;
      FreeShip.FileChanged:=True;
      FreeShip.Built:=False;
      //Freeship.ReDraw;
      if Assigned(FreeShip.OnUpdateGeometryInfo) then
         FreeShip.OnUpdateGeometryInfo(self);
   end;
end;{TFreeEdit.Selection_Delete}

// Select all visible items
procedure TFreeEdit.Selection_SelectAll;
var
  I, J: integer;
begin
  for I:=1 to FreeShip.NumberOfLayers do
    if FreeShip.Layer[I - 1].SurfaceVisible then
      for J:=1 to FreeShip.Layer[I - 1].Count do
        FreeShip.Layer[I - 1].Items[J - 1].Selected:=True;
  for I:=1 to FreeShip.Surface.NumberOfControlEdges do
    if FreeShip.Surface.ControlEdge[I - 1].Visible then
      FreeShip.Surface.ControlEdge[I - 1].Selected:=True;
  for I:=1 to FreeShip.Surface.NumberOfControlPoints do
    if FreeShip.Surface.ControlPoint[I - 1].Visible then
      FreeShip.Surface.ControlPoint[I - 1].Selected:=True;
  for I:=1 to FreeShip.Surface.NumberOfControlCurves do
    if FreeShip.Surface.ControlCurve[I - 1].Visible then
      FreeShip.Surface.ControlCurve[I - 1].Selected:=True;
  for I:=1 to FreeShip.NumberofMarkers do
    if FreeShip.Marker[I - 1].Visible then
      FreeShip.Marker[I - 1].Selected:=True;
  for I:=1 to FreeShip.NumberofFlowlines do
    if FreeShip.Flowline[I - 1].Visible then
      FreeShip.Flowline[I - 1].Selected:=True;
  Freeship.ReDraw;
end;

// Select all control points
procedure TFreeEdit.Selection_SelectAllControlPoints;
var  I, J: integer;
begin
  {for I:=1 to FreeShip.NumberOfLayers do
    if FreeShip.Layer[I - 1].SurfaceVisible then
      for J:=1 to FreeShip.Layer[I - 1].Count do
        FreeShip.Layer[I - 1].Items[J - 1].Selected:=True;}
  for I:=1 to FreeShip.Surface.NumberOfControlPoints do
    if FreeShip.Surface.ControlPoint[I - 1].Visible then
      FreeShip.Surface.ControlPoint[I - 1].Selected:=True;
  Freeship.ReDraw;
end;


procedure TFreeEdit.Selection_SelectLeakPoints;
var
  I: integer;
begin
  for I:=0 to FreeShip.Surface.NumberOfControlPoints - 1 do
    FreeShip.Surface.ControlPoint[I].Selected:=FreeShip.Surface.ControlPoint[I].IsLeak;
  Freeship.ReDraw;
end;

procedure TFreeEdit.Undo;
var
  UndoObject: TFreeUndoObject;
  Preview: boolean;
begin
  if FreeShip.FUndoObjects.Count > 0 then begin
    Preview:=FreeShip.ProjectSettings.SavePreview;
//  try
      if FreeShip.FUndoPosition = FreeShip.UndoCount then
        if FreeShip.UndoObject[FreeShip.UndoCount - 1].FIsTempRedoObject then
        //??
        else CreateRedoObject;
      if FreeShip.FPreviousUndoPosition < FreeShip.FUndoPosition then
        Dec(FreeShip.FUndoPosition);
      FreeShip.FPreviousUndoPosition:=FreeShip.FUndoPosition;
      Dec(FreeShip.FUndoPosition);
      UndoObject:=FreeShip.FUndoObjects[FreeShip.FUndoPosition];
      UndoObject.Restore;
//  finally
      FreeShip.ProjectSettings.SavePreview:=Preview;
//  end;
  end;
end;

// Clear the undo history
procedure TFreeEdit.Undo_Clear;
begin  FreeShip.ClearUndo;
end;

// Show the undo history
procedure TFreeEdit.Undo_ShowHistory;
var
  Dialog: TFreeUndoHistoryDialog;
  vUndo: TFreeUndoObject;
  Index: integer;
  vRedo: TFreeUndoObject;
begin
  Dialog:=TFreeUndoHistoryDialog.Create(FreeShip);                            //ShowTranslatedValues(Dialog);
  vRedo:=nil;
  if (FreeShip.FUndoPosition = FreeShip.UndoCount) and (FreeShip.UndoCount > 0) then
    if not FreeShip.UndoObject[FreeShip.UndoCount - 1].FIsTempRedoObject then
    begin
      vRedo:=CreateRedoObject;
      Dec(FreeShip.FUndoPosition);
    end;

  if Dialog.Execute(FreeShip) then
  begin
    if Dialog.UndoBox.ItemIndex <> -1 then
    begin
      vUndo:=Dialog.UndoBox.Items.Objects[Dialog.UndoBox.ItemIndex] as
        TFreeUndoObject;
      ;
      Index:=FreeShip.FUndoObjects.IndexOf(vUndo);
      if Index <> -1 then begin //FreeShip.FPreviousUndoPosition:=Index+1;
        FreeShip.FUndoPosition:=Index;
        vUndo.Restore;
      end;
    end;
  end
  else if vRedo <> nil then
    vRedo.Delete;
  FreeAndNil(Dialog);
end;

procedure TFreeEdit.Redo;
var
  UndoObject: TFreeUndoObject;
  Preview: boolean;
begin
  if FreeShip.FUndoObjects.Count > 0 then
  begin
    Preview:=FreeShip.ProjectSettings.SavePreview;
//  try
      if FreeShip.FPreviousUndoPosition > FreeShip.FUndoPosition then
        Inc(FreeShip.FUndoPosition);
      FreeShip.FPreviousUndoPosition:=FreeShip.FUndoPosition;
      Inc(FreeShip.FUndoPosition);
      UndoObject:=FreeShip.FUndoObjects[FreeShip.FUndoPosition - 1];
      UndoObject.Restore;
//  finally
      FreeShip.ProjectSettings.SavePreview:=Preview;
//  end;
  end;
end;

// Add a new intersection of the specified type at the specified location
function TFreeEdit.Intersection_Add(IntType: TFreeIntersectionType;
  Distance: TFloatType): TFreeIntersection;
var
  Intersection: TFreeIntersection;
  TargetList: TFasterListTFreeIntersection;
  I: integer;
begin
  TargetList:=nil;
  case IntType of
    fiStation: TargetList:=FreeShip.FStations;
    fiButtock: TargetList:=FreeShip.FButtocks;
    fiWaterline: TargetList:=FreeShip.FWaterlines;
    fiDiagonal: TargetList:=FreeShip.FDiagonals;
  end;
  // First check if an intersection already exists at this location;
  for I:=1 to TargetList.Count do begin
    Intersection:=TargetList[I - 1];
    if Abs(-InterSection.FPlane.d - Distance) < 1e-7 then begin // Yes, it exists, so do not add a new one
      Result:=nil;
      exit;
    end;
  end;
  // Once here, a new intersection can be added
  Intersection:=TFreeIntersection.Create(FreeShip);
  Intersection.FIntersectionType:=IntType;
  Intersection.FPlane.a:=0.0;
  Intersection.FPlane.b:=0.0;
  Intersection.FPlane.c:=0.0;
  Intersection.FPlane.d:=0.0;
  case Intersection.IntersectionType of
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
      Intersection.FPlane.b:=1 / Sqrt(2);
      Intersection.FPlane.c:=1 / Sqrt(2);
      Intersection.FPlane.d:=-Intersection.FPlane.c * Distance; end;
  end;
  Intersection.Rebuild;
  // Only add if an intersection has been found
  if Intersection.Count > 0 then begin
    Intersection_AddToList(Intersection);
    Intersection.DrawAll;
    Result:=Intersection;
  end else begin
    FreeAndNil(Intersection);
    Result:=nil;
  end;
end;

// Add a new intersection of the specified type at the specified location
procedure TFreeEdit.Intersection_Change(Intersection: TFreeIntersection;
  Distance: TFloatType);
var
  TargetList: TFasterListTFreeIntersection;
  I: integer;
begin
  case Intersection.IntersectionType of
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
      Intersection.FPlane.b:=1 / Sqrt(2);
      Intersection.FPlane.c:=1 / Sqrt(2);
      Intersection.FPlane.d:=-Intersection.FPlane.c * Distance; end;
  end;
  Intersection.Rebuild;
end;

