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
procedure TFreeEdit.AddToRecentFiles( Filename:AnsiString );
var
  I,Index: integer;
  AlreadyPresent: boolean;
  Tmp,Ext: AnsiString;
begin
  AlreadyPresent:=False;
  FreeShip.Preferences.LastDirectory:=ExtractFilePath( FileName );
  Ext:=Uppercase(ExtractFileExt(Filename));
  Index:=-1;
  Tmp:=Trim(Filename);
  for I:=0 to FRecentFiles.Count-1 do
  if Uppercase(Trim(FRecentFiles[I]))=Uppercase(Tmp) then begin Index:=I;
    break;
  end;                                 // Already in list. move to the front;
  if Index>=0 then begin
    FRecentFiles.Delete( Index );
    FRecentFiles.Insert( 0,Tmp );
  end else
    if FRecentFiles.Count=0 then FRecentFiles.Add(Tmp) else
       FRecentFiles.Insert(0,Tmp);// file not yet in the list, add at the front
                                 // delete items until no more than 36 are left
  while FRecentFiles.Count>36 do FRecentFiles.Delete(FRecentFiles.Count-1); ///***!!!
  if assigned( FreeShip.FOnUpdateRecentFileList ) then
               FreeShip.FOnUpdateRecentFileList( self );
end;

// Delete the backgrundimage associated with this view
procedure TFreeEdit.BackgroundImage_Delete(Viewport: TFreeViewport);
var
  I: integer;
begin
  if MessageDlg(Userstring(68), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    for I:=FFreeShip.NumberofBackgroundImages downto 1 do
      if FFreeShip.BackgroundImage[I-1].AssignedView = Viewport.ViewType then
      begin
        FFreeShip.BackgroundImage[I-1].Destroy;
        FFreeShip.FBackgroundImages.Delete(I-1);
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
    if FreeShip.BackgroundImage[I-1].AssignedView = Viewport.ViewType then
      Data:=FreeShip.BackgroundImage[I-1];
  if Data <> nil then
    if MessageDlg(Userstring(69)+EOL+Userstring(70), mtConfirmation,
      [mbYes, mbNo], 0) = mrNo then exit;

  Dialog:=TOpenPictureDialog.Create(Viewport);
  Dialog.InitialDir:=FreeShip.Preferences.ImportDirectory; //+ConfigDirectory
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
      else begin                                             // calculate scale
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
    for I:=FFreeShip.FUndoObjects.Count downto FreeShip.FUndoPosition+1 do
      FreeShip.UndoObject[I-1].Delete;    // Temp. set to the latest fileversion so that no data will be lost
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
  for I:=0 to FreeShip.NumberOfSelectedControlEdges-1 do
  begin
    Edge:=FreeShip.SelectedControlEdge[I];
    if Edge.Curve = nil then
      Edges.Add(Edge);
  end;
  if Edges.Count > 0 then
  begin
    Self.CreateUndoObject(Userstring(72), True);
    SortedPointLists:=TFasterListTFreeSubdivisionFace.Create;
    FreeShip.Surface.IsolateEdges(Edges, SortedPointLists);
    for I:=1 to SortedPointLists.Count do begin
      Points:=SortedPointLists[I-1].Points;
      if Points.Count > 1 then begin
        Curve:=TFreeSubdivisionControlCurve.Create(FreeShip.Surface);
        FreeShip.Surface.AddControlCurve(Curve);
        for J:=1 to Points.Count do begin
          Point:=Points[J-1] as TFreeSubdivisionControlPoint;
          Curve.AddPoint(Point);
          if J > 1 then begin
            Edge:=Curve.Surface.EdgeExists(
              Curve.ControlPoint[J-2], Curve.ControlPoint[J-1]) as
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
      Edge:=FreeShip.SelectedControlEdge[I-1];
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
  for I:=FreeShip.NumberOfSelectedControlEdges downto 1 do begin
    Edge:=FreeShip.SelectedControlEdge[I-1];
    if Edge.NumberOfFaces>1then begin Edge.Collapse; Inc(N); end;
  end;
  if N>0 then begin
    vUndo.Accept;
    FreeShip.Built:=False;
    Freeship.RebuildModel;
    FreeShip.FileChanged:=True;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
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
    FreeShip.SelectedControlEdge[I-1].Crease :=
      not FreeShip.SelectedControlEdge[I-1].Crease;
  FreeShip.Built:=False;
  Freeship.RebuildModel;
  FreeShip.FileChanged:=True;
end;

// Create new controlPoints by extruding selected points
procedure TFreeEdit.Point_Extrude;
var
  Dialog: TFreeExtrudeDialog;
  Point: TFreeSubdivisionControlPoint;
  Vector: T3DVector;
  Points, NewPoints: TFasterListTFreeSubdivisionControlPoint;
  I: integer;
  Str: string;
  vUndo: TFreeUndoObject;
begin
  Dialog:=TFreeExtrudeDialog.Create(FreeShip);
  ShowTranslatedValues(Dialog);
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
  Vector: T3DVector;
  Edges: TFasterListTFreeSubdivisionEdge;
  I: integer;
  Str: string;
  vUndo: TFreeUndoObject;
begin
  Dialog:=TFreeExtrudeDialog.Create(FreeShip);
  ShowTranslatedValues(Dialog);
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
      Edge:=FreeShip.Surface.SelectedControlEdge[I-1]; // only boundary and freestanding edges are allowed!!
      if Edge.NumberOfFaces <= 1 then Edges.Add(Edge);
      Edge.Selected:=False;
    end;
    if Edges.Count > 0 then begin
      FreeShip.Surface.ExtrudeEdges(Edges, Vector);        // New edges are returned in the edges-list, select them
      for I:=1 to Edges.Count do begin
        Edge:=Edges[I-1] as TFreeSubdivisionControlEdge;
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
    Edge:=FreeShip.Surface.SelectedControlEdge[I-1];
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
  NAssembled,I,J,K: integer;
  Layers: TFasterListTFreeSubdivisionLayer;
  AssFace: TFreeFaceGrid;
  Layer: TFreeSubdivisionLayer;
  Face: TFreeSubdivisionControlFace;
begin
  Layers:=TFasterListTFreeSubdivisionLayer.Create;
  for I:=1 to FreeShip.Surface.NumberOfLayers do
      Layers.Add(FreeShip.Surface.Layer[I-1]);
  FreeShip.Visibility.ShowInteriorEdges:=True;
  FreeShip.Surface.AssembleFacesToPatches(Layers, amNurbs, Assembled, NAssembled);
  if NAssembled > 0 then begin              // assign all patches to new layers
    for I:=1 to NAssembled do begin
      Layer:=FreeShip.Surface.AddNewLayer;
      Layer.Color:=clLtGray; //RandomColor;
      AssFace:=Assembled[I-1];
      for J:=1 to AssFace.NRows do
      for K:=1 to AssFace.NCols do begin
        Face:=AssFace.Faces[J-1][K-1]; if Face<>nil then Face.Layer:=Layer;
      end;
    end;
    Layer_DeleteEmpty(True);
    Freeship.RebuildModel;
    ShowMessage('Assembled '+IntToStr(NAssembled)+' patches');
  end;
  FreeAndNil(Layers);
end;

// Deletes all faces on the starboardside of the hull
procedure TFreeEdit.Face_DeleteNegative;
var
  IsPlus,isZero,isMinus: Boolean; Str: AnsiString;
  I,J, RemovedF, RemovedP: integer; P3D: T3DVector;
  Face: TFreeSubdivisionControlFace;
  Point: TFreeSubdivisionControlPoint;
  PrevCursor: TCursor;
  vUndo: TFreeUndoObject;
begin
  RemovedF:=0;
  RemovedP:=0;
  PrevCursor:=Screen.Cursor;
  Screen.Cursor:=crHourglass;
  vUndo:=CreateUndoObject( Userstring(79),False );                     /// 1e-7
//  for I:=FreeShip.Surface.NumberOfControlPoints-1 downto 0 do begin
//    Point:=FreeShip.Surface.ControlPoint[I];
//    if Point.NumberOfFaces=0 then begin Point.Delete; Inc( RemovedP ); end;
//  end;
  //
  //  приведение к диметральной плоскости правых отрицательных точек
  //
  for I:=FreeShip.Surface.NumberOfControlFaces-1 downto 0 do begin
    isPlus:=false; isMinus:=false; isZero:=false;
    Face:=FreeShip.Surface.ControlFace[I];
    if face.NumberOfpoints>2 then                   // точки и линии удаляются
    for J:=0 to Face.NumberOfpoints-1 do begin P3D:=Face.Point[J].Coordinate;
      if P3D.Y>0 then IsPlus:=true else
      if P3D.Y<0 then IsMinus:=true else isZero:=true;
    end;
    if not IsPlus then begin Face.Delete; Inc( RemovedF ); end; // else
//  if (not IsPlus) and (not isZero) then begin Face.Delete; Inc( RemovedF ); end; // else
//    for J:=0 to Face.NumberOfpoints-1 do begin P3D:=Face.Point[J].Coordinate;
//      if P3D.Y<0 then begin P3D.Y:=0.0; Face.Point[J].Coordinate:=P3D; end;
//  end;
  end;
  //
  //  расчистка всех точек, не привязанных к треугольникам
  //
  for I:=FreeShip.Surface.NumberOfControlPoints-1 downto 0 do begin
    Point:=FreeShip.Surface.ControlPoint[I];
    if Point.Coordinate.Y<0 then                                      // -1e-4
      if Point.NumberOfFaces=0 then begin Point.Delete; Inc( RemovedP ); end
      else begin P3D:=Point.Coordinate; P3D.Y:=0.0; // Point.Coordinate:=P3D;
                 FreeShip.Surface.ControlPoint[I].Coordinate:=P3D;
           end;
  end;
  //
  //  справка по успешным результатам
  //
  if (RemovedF+RemovedP)>0 then begin Str:='';
    if RemovedF>0 then Str:=Str+IntToStr(RemovedF)+#32+Userstring(80);
    if RemovedP>0 then begin if Str<>'' then Str:=Str+EOL;
       Str:=Str+IntToStr(RemovedP)+#32+Userstring(81);
    end;
    MessageDlg( Str,mtInformation,[mbOK],0 ); vUndo.Accept;
    FreeShip.FileChanged:=True;
    FreeShip.Built:=False;
    Freeship.RebuildModel;
    if Assigned( FreeShip.OnUpdateGeometryInfo ) then
                 FreeShip.OnUpdateGeometryInfo( self );
  end else begin
    MessageDlg( Userstring(82),mtInformation,[mbOK],0); vUndo.Delete;
  end;
  Screen.Cursor:=PrevCursor;
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
  Vertices,Points: TFasterListTFreeSubdivisionControlPoint;
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
    SelectDlg:=TFreeSelectLayersDialog.Create(FreeShip);
    ShowTranslatedValues(SelectDlg);
    if SelectDlg.Execute(FFreeShip, fsFaces) then
      SelectDlg.ExtractSelectedFaces(Faces)
    else begin
      for I:=FreeShip.NumberOfSelectedControlFaces downto 1 do
          FreeShip.SelectedControlFace[I-1].Selected:=False;
      Freeship.RebuildModel;
    end;
    FreeAndNil(SelectDlg);
  end else begin
    Faces.Capacity:=Faces.Count+FreeShip.NumberOfSelectedControlFaces;
    for I:=1 to FreeShip.NumberOfSelectedControlFaces do
                Faces.Add(FreeShip.SelectedControlFace[I-1]);
  end;
  if Faces.Count > 0 then begin
    Dialog:=TFreeMirrorPlaneDialog.Create(FreeShip);
    ShowTranslatedValues(Dialog);
    if Dialog.Execute then begin
      Mirrorplane:=Dialog.Plane;
      CreateUndoObject(Userstring(84), True);
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
//    try                                               // assemble all points
        Vertices:=TFasterListTFreeSubdivisionControlPoint.Create;
        Vertices.Capacity:=4 * Faces.Count;
        for I:=1 to Faces.Count do begin
          Face:=Faces[I-1];
          for J:=1 to Face.NumberOfpoints do begin
            P1:=Face.Point[J-1] as TFreeSubdivisionControlPoint;
            if Vertices.IndexOf(P1) = -1 then Vertices.Add(P1);
          end;
        end;                          // Create all the mirrored control points
        for I:=1 to Vertices.Count do begin
          P1:=Vertices[I-1];
          if not Dialog.CheckBox1.Checked then begin
            // Do NOT try to connect the points to any existing point
            // create always a new point
            P2:=TFreeSubdivisionControlPoint.Create(P1.Surface);
            P1.Surface.AddControlPoint(P2);
            P2.Coordinate:=FreeGeometry.MirrorPlane(P1.Coordinate, MirrorPlane);
          end else P2:=P1.Surface.AddControlPoint(
          FreeGeometry.MirrorPlane(P1.Coordinate, MirrorPlane));
        // Try to connect ALL new points to existing ones
          Vertices.Objects[I-1]:=P2;
        end;
        // now create the controlfaces
        Points:=TFasterListTFreeSubdivisionControlPoint.Create;
        for I:=1 to Faces.Count do begin
          Face:=Faces[I-1];
          Points.Clear;
          Points.Capacity:=Face.NumberOfpoints;
          for J:=Face.NumberOfpoints downto 1 do begin
            P1:=Face.Point[J-1] as TFreeSubdivisionControlPoint;
            Index:=Vertices.IndexOf(P1);
            if Index <> -1 then begin
              P2:=TFreeSubdivisionControlPoint(Vertices.Objects[index]);
              Index:=Points.IndexOf(P2);
              if Index = -1 then Points.Add(P2);
            end;
//          else WriteLn(Userstring(85));
          end;
          if Points.Count > 2 then begin
            NewFace:=Face.Surface.AddControlFace(Points, False);
            if Newface <> nil then NewFace.Layer:=Face.Layer;
          end;
        end;
        FreeAndNil( Points );           // Now check all edges for crease edges
        for I:=1 to Vertices.Count do begin
          P1:=Vertices[I-1];
          for J:=1 to P1.NumberOfEdges do begin
            Edge1:=P1.Edge[J-1];
            if Edge1.StartPoint = P1
            then P2:=Edge1.EndPoint as TFreeSubdivisionControlPoint
            else P2:=Edge1.StartPoint as TFreeSubdivisionControlPoint;
            Index:=Vertices.IndexOf(P2);
            if Index <> -1 then begin
              // Edge is part of the selected faces
              Edge2:=FreeShip.Surface.EdgeExists(
                TFreeSubdivisionControlPoint(Vertices.Objects[I-1]),
                TFreeSubdivisionControlPoint(Vertices.Objects[index]));
              if (Edge2 <> nil) and (Edge2 <> Edge1) then
                Edge2.Crease:=Edge1.Crease;
            end;
          end;
        end;
        // Copy cornerpoint and locked ststus that might be lost in the edge-setting process
        for I:=1 to Vertices.Count do
        begin
          P1:=Vertices[I-1];
          P2:=TFreeSubdivisionControlPoint(Vertices.Objects[I-1]);
          if P2 <> P1 then begin
            if P1.VertexType = svCorner then P2.VertexType:=P1.VertexType;
            P2.Locked:=P1.Locked;
          end;
        end;
        FreeAndNil(Vertices);
        for I:=FreeShip.NumberOfSelectedControlFaces downto 1 do
          FreeShip.SelectedControlFace[I-1].Selected:=False;
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
    SelectDlg:=TFreeSelectLayersDialog.Create(FreeShip);
    ShowTranslatedValues(SelectDlg);
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
      Dialog:=TFreeRotateDialog.Create( FreeShip );
      ShowTranslatedValues(Dialog);
      Dialog.Caption:='Rotate selected items.';
      ShowTranslatedValues(Dialog);
      Dialog.XValue:=0.0;
      Dialog.YValue:=0.0;
      Dialog.ZValue:=0.0;
      if Dialog.Execute( '[°]',true ) then begin
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
        for I:=1 to Points.Count do begin Point:=Points[I-1];
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
        if Points.IndexOf(FreeShip.ActiveControlPoint)<>-1
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
  SinX,CosX, SinY,CosY, SinZ,CosZ: TFloatType;
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
    Dialog.Caption:='Heeling and/or trimming all model items.';
    ShowTranslatedValues( Dialog );
    Dialog.XValue:=0.0;
    Dialog.YValue:=0.0;
    Dialog.ZValue:=0.0;
    if Dialog.Execute( '[°]',true ) then begin
      CreateUndoObject( 'rotate',True );
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourGlass;
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
      for I:=1 to FreeShip.NumberofMarkers do begin Marker:=FreeShip.Marker[I-1];
        for J:=1 to Marker.NumberOfPoints do
          Marker.Point[J-1]:=RotateVector(Marker.Point[J-1],SinX,CosX,SinY,CosY,SinZ,CosZ);
      end;
      FreeShip.Built:=False;
      Freeship.RebuildModel;                       // Refresh controlpoint data
      if Points.IndexOf(FreeShip.ActiveControlPoint)<>-1 then
         FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
      Screen.Cursor:=PrevCursor;
    end else begin
      for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
        FreeShip.SelectedControlPoint[I-1].Selected:=False;
      for I:=1 to FreeShip.NumberOfViewports do
        FreeShip.Viewport[I-1].Refresh;
    end;
       FreeAndNil(Dialog);
  end; FreeAndNil(Points);
end;

procedure TFreeEdit.Face_Scale;
var
  I,Nlocked: integer;
  Points: TFasterListTFreeSubdivisionControlPoint;
  PrevCursor: TCursor;
  SelectDlg: TFreeSelectLayersDialog;
  Point: TFreeSubdivisionControlPoint;
  Proceed,Markers: boolean;
  Dialog: TFreeRotateDialog;
  Scale, NewP: T3DVector;
begin
  Points:=TFasterListTFreeSubdivisionControlPoint.Create;
  if FreeShip.ActiveControlPoint<>nil then Points.Add(FreeShip.ActiveControlPoint);
  FreeShip.Surface.ExtractPointsFromSelection(Points, NLocked);
  if Points.Count = 0 then begin
    SelectDlg:=TFreeSelectLayersDialog.Create(FreeShip);
    ShowTranslatedValues(SelectDlg);
    if SelectDlg.Execute(FFreeShip, fsPoints)
    then SelectDlg.ExtractSelectedPoints(Points)
    else begin
      for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do
          FreeShip.SelectedControlPoint[I-1].Selected:=False;
      for I:=1 to FreeShip.NumberOfViewports do
          FreeShip.Viewport[I-1].Refresh;
    end;
    FreeAndNil(SelectDlg);
  end;
  if Points.Count > 0 then begin
    if NLocked > 0
    then Proceed:=MessageDlg(Userstring(86)+EOL+Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes
    else Proceed:=True;
    if Proceed then begin
      Dialog:=TFreeRotateDialog.Create(FreeShip);
      Dialog.Caption:='Scale selected items.';
      ShowTranslatedValues(Dialog);
      Dialog.XValue:=1.0;
      Dialog.YValue:=1.0;
      Dialog.ZValue:=1.0;
      if Dialog.Execute( 'scale') then begin
        CreateUndoObject(Userstring(91), True);
        PrevCursor:=Screen.Cursor;
        Screen.Cursor:=crHourGlass;
        Scale.X:=Dialog.XValue;
        Scale.Y:=Dialog.YValue;
        Scale.Z:=Dialog.ZValue;                       // Scale the entire model
        if Points.Count = FreeShip.Surface.NumberOfControlPoints then begin
          Markers:=FreeShip.AdjustMarkers;
          Model_Scale( Scale,False,Markers );
        end else begin      // only a selected part of the model must be scaled
          for I:=1 to Points.Count do begin
            Point:=Points[I-1];
            if not Point.Locked then begin
              NewP.X:=Scale.X * Point.Coordinate.X;
              NewP.Y:=Scale.Y * Point.Coordinate.Y;
              NewP.Z:=Scale.Z * Point.Coordinate.Z; Point.Coordinate:=NewP;
            end;
          end;
          FreeShip.Built:=False;
          Freeship.RebuildModel;
        end;                                     // Refresh controlpoint data
        if Points.IndexOf(FreeShip.ActiveControlPoint) <> -1 then
          FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
        Screen.Cursor:=PrevCursor;
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
  I,J,Nlocked: integer;
  Points: TFasterListTFreeSubdivisionControlPoint;
  PrevCursor: TCursor;
  SelectDlg: TFreeSelectLayersDialog;
  Point: TFreeSubdivisionControlPoint;
  Proceed: boolean;
  Dialog: TFreeRotateDialog;
  P, Translate: T3DVector;
  Marker: TFreeMarker;
begin
  Points:=TFasterListTFreeSubdivisionControlPoint.Create;
  if FreeShip.ActiveControlPoint <> nil then
    Points.Add(FreeShip.ActiveControlPoint);
  FreeShip.Surface.ExtractPointsFromSelection(Points, NLocked);
  if Points.Count = 0 then begin
    SelectDlg:=TFreeSelectLayersDialog.Create(FreeShip);
    ShowTranslatedValues(SelectDlg);
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
      Dialog:=TFreeRotateDialog.Create( FreeShip );
      Dialog.Caption:='Move the entire model.';
      ShowTranslatedValues( Dialog );
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
        for I:=1 to Points.Count do begin Point:=Points[I-1];
          if not Point.Locked then begin P:=Point.Coordinate;
            P.X:=P.X+Translate.X;
            P.Y:=P.Y+Translate.Y;
            P.Z:=P.Z+Translate.Z; Point.Coordinate:=P;
          end;
        end;
        if Points.Count=FreeShip.Surface.NumberOfControlPoints then begin       // Update main dimensions
          if not FreeShip.ProjectSettings.FUseDefaultSplitSectionLocation then
            FreeShip.ProjectSettings.ProjectSplitSectionLocation :=
              FreeShip.ProjectSettings.ProjectSplitSectionLocation+Translate.X; // Update stations, buttcks and waterlines
          for I:=1 to FreeShip.NumberofStations do
            FreeShip.Station[I-1].FPlane.d:=FreeShip.Station[I-1].FPlane.d-Translate.X;
          for I:=1 to FreeShip.NumberofButtocks do
            FreeShip.Buttock[I-1].FPlane.d:=FreeShip.Buttock[I-1].FPlane.d-Translate.Y;
          for I:=1 to FreeShip.NumberofWaterlines do
            FreeShip.Waterline[I-1].FPlane.d:=FreeShip.Waterline[I-1].FPlane.d-Translate.Z;
          for I:=0 to Freeship.NumberOfFlowlines-1 do with Freeship.Flowline[I] do begin
            FProjectionPoint.X := FProjectionPoint.X + Translate.X;
            FProjectionPoint.Y := FProjectionPoint.Y + Translate.Z;
            for J:=0 to FFlowline.NumberOfPoints-1 do begin
              P:=FFlowline.Point[J]; P.X:=P.X + Translate.X;
                                     P.Y:=P.Y + Translate.Y;
                                     P.Z:=P.Z + Translate.Z; FFlowline.Point[J]:=P;
            end;
          end;                                   // Refresh controlpoint data
          if FreeShip.AdjustMarkers then                    // Update markers
          for I:=1 to FreeShip.NumberofMarkers do begin
            Marker:=FreeShip.Marker[I-1];
            for J:=1 to Marker.NumberOfPoints do begin P:=Marker.Point[J-1];
              P.X:=P.X+Translate.X;
              P.Y:=P.Y+Translate.Y;
              P.Z:=P.Z+Translate.Z; Marker.Point[J-1]:=P;
            end;
          end;
        end;
        FreeShip.Built:=False;
        Freeship.RebuildModel;                   // Refresh controlpoint data
        if Points.IndexOf(FreeShip.ActiveControlPoint) <> -1 then
          FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
        Screen.Cursor:=PrevCursor;
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
end; {TFreeEdit.Face_Move}

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
      Tmp.Add(FreeShip.Surface.SelectedControlPoint[I-1]);
    // Deselect the controlpoints
    for I:=FreeShip.Surface.NumberOfSelectedControlPoints downto 1 do
      FreeShip.Surface.SelectedControlPoint[I-1].Selected:=False;
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

function TFreeEdit.CheckIfChangedAndAskToSave():boolean;
  var Answer: word;
begin
  Result:=true;
  if FreeShip.FileChanged then begin
    Answer:=MessageDlg( UserString(103)+EOL+UserString(104),mtConfirmation,
                                                    [mbYes,mbNo,mbCancel],0 );
    if Answer = mrCancel then begin Result:=false; end
    else if Answer = mrYes then begin File_SaveAs;
      if FreeShip.FileChanged then begin // Apparently saving was not successfull, abort
        Result:=false;
      end;
    end;
  end;
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
//  try
      TempFreeShip.Clear;
      TempFreeShip.LoadPreview( aFileName,Result );
      if not assigned( Result ) or ( Result.Width=0 ) then begin
        Ext:=LowerCase(ExtractFileExt(aFileName));
        if Ext = '.fbm' then Source:=TFreeFileBuffer.Create else
        if Ext = '.ftm' then Source:=TFreeTextBuffer.Create else
           begin WriteLN( 'Unsupported file format: '+Ext); exit; end;

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
          ViewportMode := vmWireFrame;    // vmShade;
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
        TempFreeShip.AddViewport( vp );                      // fill background
        vp.BrushColor:=vp.Color;
        vp.Rectangle( 0,0,pvWidth,pvHeight );
        vp.ZoomExtents;
        TempFreeShip.DrawToViewport( vp );
        vp.Free;
      end;
//  finally
    TempFreeShip.Free;
//  end;
end;

resourcestring
  FileDialogFilterFreeship = 'FreeShip files (*.ftm *.fbm)|*.ftm;*.fbm';
  FileDialogFilterFreeshipText = 'FreeShip Text (*.ftm)|*.ftm';
  FileDialogFilterFreeshipBinary = 'FreeShip Binary (*.fbm)|*.fbm';
  rsFreeShipFiles = 'FreeShip files';
  rsFreeShipTextFiles = 'FreeShip Text files';
  rsFreeShipBinaryFiles = 'FreeShip Binary files';

procedure TFreeEdit.File_Load;
var Answer     : word;
    OpenDialog : TOpenDialog;
begin
   OpenDialog:=TOpenDialog.Create( FreeShip );
   OpenDialog.InitialDir:=FreeShip.Preferences.OpenDirectory; //+ConfigDirectory
   OpenDialog.Filter:=createDialogFilter(rsFreeShipFiles,['fbm','ftm'],False )
             +'|'+createDialogFilter(rsFreeShipTextFiles,['ftm'],False)
             +'|'+createDialogFilter(rsFreeShipBinaryFiles,['fbm'] );
   Opendialog.Options:=[ofHideReadOnly];
//  try
     if OpenDialog.Execute then begin
        Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
        if (Answer=mrCancel) or FreeShip.FileChanged then exit;
        File_Load( Opendialog.FileName );        // Load everything into memory
     end;
//  finally
     Opendialog.Destroy;
//  end
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
     begin WriteLN( 'Unsupported file format: '+Ext); halt; end;
//  try
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
    // Freeship.RebuildModel;
    // Freeship.ZoomFitAllViewports;
    // SetCaption;
    // UpdateMenu;
    Freeship.Edit.ProgressBar:=nil;
    if FreeShip.LinesplanFrame<>nil then
      TFreeLinesplanframe(FreeShip.LinesplanFrame).FreeShip:=FreeShip;
    // with TFreeLinesplanframe(FreeShip.LinesplanFrame) do begin
    //      Viewport.ZoomExtents; UpdateMenu; end;
//  finally
    FreeAndNil( Source );
    if FreeShip.ModelIsLoaded then AddToRecentFiles( FileName );
    Undo_Clear;
//  end;
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
    if FileExistsUTF8(Backup) then
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
// +'Exception class: '+E.ClassName+'\n'+'Message: '+E.Message+'\n',mtError,[mbOK],0 );
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
     if result<>mrCancel then begin          // mrCancel-отмена операций
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
   SaveDialog.InitialDir:=FreeShip.Preferences.SaveDirectory; //+ConfigDirectory
   Savedialog.FileName:=ExtractFilename( FreeShip.Filename );
   SaveDialog.Filter:=FileDialogFilterFreeship +
                '|'+FileDialogFilterFreeshipText +
                '|'+FileDialogFilterFreeshipBinary;
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
  if Flowline.FFlowLine.NumberOfPoints>0 then begin                ///***???
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
  StartPoint: T3DVector;
  EndPoint: T3DVector;
  P1, P2: T3DVector;
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
  Dialog:=TFreeCylinderDialog.Create(FreeShip);
  ShowTranslatedValues(Dialog);
  Dialog.StartPoint:=SetPoint(0.0, 0.0, 0.0);
  Dialog.EndPoint:=SetPoint(0.0, 1.0, 0.0);
  Dialog.Radius.Value:=1.0;
  Dialog.NoOfPoints.Value:=Dialog.NoOfPoints.MinValue+2;

  if Dialog.Execute(LengthStr(FreeShip.ProjectSettings.ProjectUnits)) then
  begin
    CreateUndoObject(Userstring(131), True);
    Layer:=FreeShip.Surface.ActiveLayer;
    StartPoint:=Dialog.StartPoint;
    EndPoint:=Dialog.EndPoint;
    Radius:=Dialog.Radius.Value;
    NPoints:=Dialog.NoOfPoints.Value;
    Setlength(Points, 2);
    setlength(Points[0], NPoints+1);
    setlength(Points[1], NPoints+1);

    // Prepare matrices
    Matrix:=TFreeMatrix.Create;
    Matrix.SetSize(NPoints+4, NPoints+4);
    Matrix.Fill(0.0);
    Matrix.Value[0, 0]:=1.0;
    for I:=2 to NPoints+3 do begin
      Matrix.Value[I-1, I-2]:=1 / 6;
      Matrix.Value[I-1, I-1]:=2 / 3;
      Matrix.Value[I-1, I]:=1 / 6;
    end;
    Matrix.Value[NPoints+3, NPoints+3]:=1.0;             // Invert matrix
    Inv:=Matrix.Invert;
    FreeAndNil(Matrix);

    OrgPts:=TFreeMatrix.Create;
    OrgPts.SetSize(3, NPoints+4);
    for I:=1 to NPoints do begin
      Angle:=-((I-1) / NPoints) * 2 * Pi;
      P1.x:=StartPoint.x+Sin(Angle) * Radius;
      P1.y:=StartPoint.y+Cos(Angle) * Radius;
      P1.z:=StartPoint.z;
      P2:=RotatePointAroundVector( P1,StartPoint,EndPoint-StartPoint );
      OrgPts.Value[I+1, 0]:=P2.X;
      OrgPts.Value[I+1, 1]:=P2.Y;
      OrgPts.Value[I+1, 2]:=P2.Z;
    end;
    for I:=0 to 2 do begin
      OrgPts.Value[1, I]:=OrgPts.Value[NPoints+1, I];
      OrgPts.Value[0, I]:=OrgPts.Value[NPoints, I];
      OrgPts.Value[NPoints+2, I]:=OrgPts.Value[2, I];
      OrgPts.Value[NPoints+3, I]:=OrgPts.Value[3, I];
    end;
    // calculate new points
    NewPts:=Inv.Multiply(OrgPts);
    for I:=1 to NPoints do begin
      P1.X:=NewPts.Value[I+1, 0];
      P1.Y:=NewPts.Value[I+1, 1];
      P1.Z:=NewPts.Value[I+1, 2];
      Points[0][I-1]:=P1;
      Points[1][I-1]:=SetPoint(P1.X+EndPoint.X-StartPoint.X,
        P1.Y+EndPoint.Y-StartPoint.Y, P1.Z+EndPoint.Z-StartPoint.Z);
    end;
    Points[0][NPoints]:=Points[0][0];
    Points[1][NPoints]:=Points[1][0];
    FreeAndNil(Inv);
    FreeAndNil(OrgPts);
    FreeAndNil(NewPts);
    Ne:=FreeShip.Surface.NumberOfControlEdges;
    Setlength(Grid, 2);
    for I:=0 to 1 do begin
      Setlength(Grid[I], NPoints+1);
      for J:=0 to NPoints do
        Grid[I][J]:=FreeShip.Surface.AddControlPoint(Points[I][J]);
    end;
    FreeShip.Surface.ImportControlPointGrid(Grid, NPoints+1, 2, Layer);
    for I:=Ne+1 to FreeShip.Surface.NumberOfControlEdges do
      FreeShip.Surface.ControlEdge[I-1].Crease:=False;
    if Dialog.CloseStartDisk.Checked then begin
      CPoints:=TFasterListTFreeSubdivisionControlPoint.Create;
      for I:=NPoints-1  downto 0 do CPoints.Add(Grid[0][I]);
      FreeShip.Surface.AddControlFaceN(CPoints, true, Layer);
      CPoints.Free;
    end;
    if Dialog.CloseEndDisk.Checked then begin
      CPoints:=TFasterListTFreeSubdivisionControlPoint.Create;
      for I:=0 to NPoints-1 do CPoints.Add(Grid[1][I]);
      FreeShip.Surface.AddControlFaceN(CPoints, true, Layer);
      CPoints.Free;
    end;
    Freeship.RebuildModel;
  end;
  FreeAndNil(Dialog);
end;

procedure TFreeEdit.Geometry_AddGridPanel;
var
  StartPoint: T3DVector;
  Point: T3DVector;
  P1, P2: T3DVector;
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
    Plane:=Dialog.Plane.ItemIndex;
    Setlength( Grid,Cols );
    for i:=0 to Cols-1 do begin
      SetLength(Grid[i], Rows);
      for j:=0 to Rows-1 do begin
        case Plane of
         0: begin // Horizontal
            x:=StartPoint.X+i * SizeA / Cols;
            y:=StartPoint.Y+j * SizeB / Rows;
            z:=0;
            end;
         1: begin // Lateral
            x:=StartPoint.X+i * SizeA / Cols;
            y:=0;
            z:=StartPoint.Z+j * SizeB / Rows;
            end;
         2: begin // Transverse
            x:=0;
            y:=StartPoint.Y+i * SizeA / Cols;
            z:=StartPoint.Z+j * SizeB / Rows;
            end;
        end;
        Point:=SetPoint(x,y,z);
        Grid[I][J]:=FreeShip.Surface.AddControlPoint(Point);
      end;
    end;
    FreeShip.Surface.ImportControlPointGrid(Grid, Cols, Rows, Layer);
    Freeship.RebuildModel;
  end;
  FreeAndNil(Dialog);
end;

// Creates and calculates a hydrostatics calculation
function TFreeEdit.Hydrostatics_Calculate
( Draft,AngleOfHeel,Trim: TFloatType): TFreeHydrostaticCalc;
begin
  if not FreeShip.ProjectSettings.DisableModelCheck then Model_Check(False);
  Result:=TFreeHydrostaticCalc.Create(FreeShip);
  Result.Trim:=Trim;
  Result.HeelingAngle:=AngleOfHeel;
  Result.Draft:=Draft;
  Result.Calculate;
  Result.ShowData( fhSingleCalculation );
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
    Dialog:=TFreeCrosscurvesDialog.Create(FreeShip);
    ShowTranslatedValues(Dialog);
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
  HydrostaticsForm:=TFreeHydrostaticsForm.Create(FreeShip);
  ShowTranslatedValues(HydrostaticsForm);
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
    fiDiagonal: TargetList:=FreeShip.FDiagonals; else TargetList:=nil;
  end;
  if TargetList <> nil then begin
    TargetList.Add(Intersection); // Now sort the list so that the distance is in ascending order
    for I:=1 to TargetList.Count-1 do begin Int1:=TargetList[I-1];
      for J:=I+1 to TargetList.Count do begin Int2:=Targetlist[J-1];
        if -Int2.FPlane.d < -Int1.FPlane.d then begin // swap the two intersections
          Targetlist.Exchange(I-1,J-1);
          Int1:=TargetList[I-1];
        end;
      end;
    end;
  end;
end;
// Pops up the dialog in which to add or delete stations, buttocks and waterlines
procedure TFreeEdit.Intersection_Dialog;
  var Dialog: TFreeIntersectionDialog;
begin
  Dialog:=FreeShip.FIntersectionDialog as TFreeIntersectionDialog;
  ShowTranslatedValues(Dialog);
  Dialog.Execute(FreeShip);
  FreeShip.FDesignHydrostatics.Calculated:=False;
  if FreeShip.Visibility.ShowHydrostaticData then Freeship.ReDraw;
end;

// All connected patches surrounded by crease edges are grouped together into a new layer
procedure TFreeEdit.Layer_AutoGroup;
var I,J: integer;
  ToDoList,DoneList,Current: TList;
  Face, Face2: TFreeSubdivisionControlFace;
  Layer: TFreeSubdivisionLayer;
  SameLayer: boolean;

  procedure FindAttachedFaces(List: TList; Face: TFreeSubdivisionControlFace);
  var I,J,Index: integer;
    P1,P2: TFreeSubdivisionPoint;
    Edge: TFreeSubdivisionEdge;
  begin
    P1:=Face.Point[Face.NumberOfPoints-1];
    for I:=1 to Face.NumberOfpoints do begin
      P2:=Face.Point[I-1];
      Edge:=Face.Surface.EdgeExists(P1, P2);
      if Edge <> nil then
      if not Edge.Crease then
      for J:=1 to Edge.NumberOfFaces do
      if Edge.Face[J-1]<>Face then begin
        Index:=ToDoList.IndexOf( Edge.Face[J-1] );
        if Index<>-1 then begin
          List.Add(Edge.Face[J-1]);
          ToDoList.Delete(Index);
          FindAttachedFaces(List,Edge.Face[J-1] as TFreeSubdivisionControlFace);
        end;
      end; P1:=p2;
    end;
  end;

begin
  ToDoList:=TList.Create;
  DoneList:=TList.Create;
//try
    if FreeShip.NumberOfSelectedControlFaces>0 then begin // Use only the selected ones
      ToDoList.Capacity:=ToDoList.Count+FreeShip.NumberOfSelectedControlFaces;
      for I:=1 to FreeShip.NumberOfSelectedControlFaces do
      begin
        Face:=FreeShip.SelectedControlFace[I-1];
        ToDoList.Add(Face);
      end;
    end
    else
      for I:=1 to FreeShip.NumberOfLayers do
      begin
        Layer:=FreeShip.Layer[I-1];
        if Layer.SurfaceVisible then begin
          ToDoList.Capacity:=ToDoList.Count+Layer.Count;
          for J:=1 to Layer.Count do
            ToDoList.Add(Layer.Items[J-1]);
        end;
      end// use all visible faces
    ;
    if ToDoList.Count > 0 then
    begin
      CreateUndoObject(Userstring(139), True);
      while ToDoList.Count > 0 do
      begin
        Face:=TFreeSubdivisionControlFace(ToDoList[ToDoList.Count-1]);
        ToDoList.Delete(ToDoList.Count-1);
        Current:=TList.Create;
        Current.Add(Face);
        FindAttachedFaces(Current, Face);
        DoneList.Add(Current);
      end;
      // Assign all groups to different layers
      for I:=1 to DoneList.Count do begin
        Current:=TList(DoneList[I-1]);
        if Current.Count > 0 then begin
          SameLayer:=True;   // check if all selected faces currently belong to the same layer
          Face:=TFreeSubdivisionControlFace(Current[0]);
          for J:=2 to Current.Count do begin
            Face2:=TFreeSubdivisionControlFace(Current[J-1]);
            if Face2.Layer <> Face.Layer then SameLayer:=False;
          end;
          Layer:=nil;
          if SameLayer then begin    // yes, all faces belong to the same layer
            if Current.Count = Face.Layer.Count then
                       // apparently the same data is selected as in face.layer, do not change layer
            else begin // a subset of face.layer is selected, copy properties from that layer
              Layer:=FreeShip.Surface.AddNewLayer;
              Layer.AssignProperties(Face.Layer);
            end;
          end else begin                    // Faces belong to multiple layers,
            Layer:=Layer_New;
            Layer.Color:=clLtGray; //RandomColor;
          end;
          if Layer <> nil then
            for J:=1 to Current.Count do begin
              Face:=TFreeSubdivisionControlFace(Current[J-1]);
              Face.Layer:=Layer;
            end;
        end;
        FreeAndNil(Current);
      end;
      FreeShip.ActiveLayer:=FreeShip.Layer[FreeShip.NumberOfLayers-1]; // Delete empty layers
      Layer_DeleteEmpty(True);
      Freeship.ReDraw;
      FreeShip.FileChanged:=True;
    end;
//finally
    if assigned(FreeShip.OnChangeLayerData) then FreeShip.OnChangeLayerData(self);
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
      Layer:=FreeShip.Layer[I-1];
      if Layer.Developable then Layer.Unroll(Plates);
    end;

    Patch:=TFreeDevelopedPatch.Create(FreeShip.ActiveLayer);

    for I:=1 to Plates.Count do begin
      Patch:=Plates[I-1];                                                   // How Plate assigned to Patch?
      for J:=1 to FreeShip.NumberofStations do
        Patch.IntersectPlane(FreeShip.Station[J-1].Plane, FreeShip.Station[J-1].Color);
      for J:=1 to FreeShip.NumberofWaterlines do
        Patch.IntersectPlane(FreeShip.Waterline[J-1].Plane, FreeShip.Waterline[J-1].Color);
      for J:=1 to FreeShip.NumberofButtocks do
        Patch.IntersectPlane(FreeShip.Buttock[J-1].Plane, FreeShip.Buttock[J-1].Color);
      for J:=1 to FreeShip.NumberofDiagonals do
        Patch.IntersectPlane(FreeShip.Diagonal[J-1].Plane, FreeShip.Diagonal[J-1].Color);
    end;
//finally
    Screen.Cursor:=Prev;
//end;

  if Plates.Count > 0 then begin
    Dlg:=TFreeExpanedplatesDialog.Create(FreeShip);
    ShowTranslatedValues(Dlg);
    FreeShip.IsRebuildAsyncDisabled:=true;
    Dlg.Execute(FreeShip, Plates);
    FreeAndNil(Dlg);
    FreeShip.IsRebuildAsyncDisabled:=false;
  end;
  for I:=1 to Plates.Count do begin
    Patch:=plates[I-1];
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
  if Quiet then vUndo:=nil
           else vUndo:=CreateUndoObject(Userstring(140), False);
  for I:=FreeShip.NumberOfLayers downto 1 do
    if (FreeShip.Layer[I-1].Count=0) and (FreeShip.NumberOfLayers>1) then begin
      FreeShip.Layer[I-1].Delete;
      Inc(N);
      FreeShip.FileChanged:=True;
    end;
  if FreeShip.ActiveLayer=nil then FreeShip.ActiveLayer:=FreeShip.Layer[FreeShip.NumberOfLayers-1]
                              else FreeShip.ActiveLayer:=FreeShip.ActiveLayer;
  if (N>0) and (not Quiet) then begin
    vUndo.Accept;
    ShowMessage(IntToStr(N)+#32+Userstring(141)+'.');
  end;
  if (N = 0) and (vUndo <> nil) then vUndo.Delete;
end;

// Show layer dialog window
procedure TFreeEdit.Layer_Dialog;
var
  LayerDialog: TFreeLayerDialog;
begin
  LayerDialog:=TFreeLayerDialog.Create(FreeShip);
  ShowTranslatedValues(LayerDialog);
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
    for I:=1 to FreeShip.NumberofMarkers do FreeShip.Marker[I-1].Destroy;
    FreeShip.FMarkers.Clear;
    FreeShip.FileChanged:=True;
    for I:=1 to FreeShip.NumberOfViewports do
      if FreeShip.Viewport[I-1].Zoom=1.0
         then FreeShip.Viewport[I-1].ZoomExtents
         else FreeShip.Viewport[I-1].Refresh;
  end;
end;

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
  Normal, Tmp: T3DVector;
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
      F1:=DoneList[I-1];
      P1:=F1.Point[F1.NumberOfPoints-1];
      for J:=1 to F1.NumberOfPoints do begin
        P2:=F1.Point[J-1];
        Edge:=FreeShip.Surface.EdgeExists(P1, P2);
        if Edge <> nil then
        if Edge.NumberOfFaces > 1 then
        for K:=1 to Edge.NumberOfFaces do
         if Edge.Face[K-1] <> F1 then begin
            F2:=Edge.Face[K-1];
            Ind:=ToDoList.IndexOf(F2);
            if Ind <> -1 then begin
               // This face is connected to the current, but not present in the
               // done-list.
               DoneList.Add(F2);
               ToDoList.Delete(Ind);
               // Also perform a check to determine if F2 is oriented in
               // the same way as F1 (clockwise or counterclockwise
               Ind:=F2.IndexOfPoint(P2);
               Ind:=(Ind+1) mod F2.NumberOfPoints; // select the next index
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
      Edge1:=FreeShip.Surface.ControlEdge[I-1];
      if Edge1.NumberOfFaces = 1 then
        if DoubleEdges.IndexOf(Edge1) = -1 then
          for J:=1 to Edge1.StartPoint.NumberOfEdges do begin
            Edge2:=Edge1.StartPoint.Edge[J-1] as TFreeSubdivisionControlEdge;
            if (Edge1 <> Edge2) and (Edge2.NumberOfFaces = 1) then
              if ((DistPP3D( Edge1.StartPoint.Coordinate,Edge2.StartPoint.Coordinate ) <  EdgeError)
              and (DistPP3D(Edge1.EndPoint.Coordinate,Edge2.EndPoint.Coordinate) < EdgeError))
              or ((DistPP3D(Edge1.StartPoint.Coordinate, Edge2.EndPoint.Coordinate) < EdgeError)
              and (DistPP3D(Edge1.EndPoint.Coordinate,Edge2.StartPoint.Coordinate) < EdgeError))
              then
              if DoubleEdges.IndexOf(Edge2)=-1 then DoubleEdges.AddObject( Edge1,Edge2 );
          end;
    end;
    Points:=TFasterListTFreeSubdivisionControlPoint.Create;
    for I:=1 to DoubleEdges.Count do
    begin
      Edge1:=DoubleEdges[I-1];
      Edge2:=TFreeSubdivisionControlEdge(DoubleEdges.Objects[I-1]);
      if (FreeShip.Surface.ControlEdges.IndexOf(Edge1) <> -1) and
         (FreeShip.Surface.ControlEdges.IndexOf(Edge2) <> -1) then
      begin
        // remove the face connected to edge2 and rebuild it by connecting it to edge1
        Ctrlface:=Edge2.Face[0] as TFreeSubdivisionControlFace;
        Points.Clear;
        for J:=1 to CtrlFace.NumberOfpoints do
        begin
          Point:=CtrlFace.Point[J-1];
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
    AllFaces.Add(FreeShip.Surface.ControlFace[I-1]);
//  AllFaces.Sort; // Sort list for faster object search

  Leaks:=TFasterListTFreeSubdivisionControlPoint.Create;
  // assemble leaks
  Z_min:=0;
  for I:=1 to FreeShip.Surface.NumberOfControlPoints do begin
    CtrlPoint:=FreeShip.Surface.ControlPoint[I-1];
    if CtrlPoint.Coordinate.Z < Z_min then
      Z_min:=CtrlPoint.Coordinate.Z;
    // Определяем наинизшую точку
    if CtrlPoint.IsLeak then Leaks.Add(CtrlPoint);
  end;
  // sort leaks in ascending z-coordinate
  for I:=1 to Leaks.Count-1 do
    for J:=I+1 to Leaks.Count do begin
      Point:=Leaks[I-1];
      Pt:=Leaks[J-1];
      Swap:=False;
      if Pt.Coordinate.Z < Point.Coordinate.Z then Swap:=True;
      if (abs(Pt.Coordinate.Z-Point.Coordinate.Z) < 1e-6) and
        (Pt.Coordinate.X < Point.Coordinate.X) then Swap:=True;
      if (abs(Pt.Coordinate.Z-Point.Coordinate.Z) < 1e-6) and
        (abs(Pt.Coordinate.X-Point.Coordinate.X) < 1e-6) and
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
      Face:=AllFaces[AllFaces.Count-1];
      AllFaces.Delete(AllFaces.Count-1);
      NewGroup.Clear;
      NewGroup.Capacity:=AllFaces.Count;
      NewGroup.Add(Face);
      // use the first face as seed for the following procedure
      FindConnectedFaces(NewGroup, AllFaces);
//      NewGroup.Sort;

      // find the lowest point of this group of faces
      Pt0:=nil;
      for I:=1 to NewGroup.Count do begin
        Face:=NewGroup[I-1];
        for j:=1 to Face.NumberOfPoints do begin
          Pt:=Face.Point[J-1];
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
          if NewGroup.IndexOf(Pt0.Face[I-1]) <> -1 then
            if Face = nil then begin
              Face:=Pt0.Face[I-1];
              normal:=Face.FaceNormal;
            end else begin
              Tmp:=Pt0.Face[I-1].FaceNormal;
              if abs(Tmp.Z) > abs(Normal.Z) then begin
                Face:=Pt0.Face[I-1];
                normal:=Face.FaceNormal;
              end;
            end;                                                                // MessageDlg('flip I='+FloatToStrF(I,ffFixed,7,3)+' N.X='+FloatToStrF(Normal.X,ffFixed,7,3)+' N.Y='+FloatToStrF(Normal.Y,ffFixed,7,3)+' N.Z='+FloatToStrF(Normal.Z,ffFixed,7,3),mtError,[mbOk],0);
        if Face <> nil then
        if Normal.Z > 0.0 then begin
              // normal points upward, all faces in this group must be inverted
          for I:=0 to NewGroup.Count-1 do begin
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
      Str:=Userstring(149)+' '+IntToStr(Leaks.Count)+' '+Userstring(150)+'.';
      if Leaks.Count > 10 then Str:=Str+EOL+Userstring(151)+':';
      Str:=Str+EOL;
      for I:=1 to Leaks.Count do begin
        Point:=Leaks[I-1];
        Str:=Str+EOL+FloatToStrF(Point.Coordinate.X, ffFixed, 7, 3) +
          ', '+FloatToStrF(Point.Coordinate.Y, ffFixed, 7, 3) +
          ', '+FloatToStrF(Point.Coordinate.Z, ffFixed, 7, 3);
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
        Str:=Userstring(152)+':';
        if DblEdges > 0 then
          Str:=Str+EOL+IntToStr(DblEdges)+' '+UserString(158)+'.';
        if Inconsistent > 0 then
          Str:=Str+EOL+IntToStr(Inconsistent)+' '+Userstring(153)+'.';
        if InvertedFaces > 0 then
          Str:=Str+EOL+IntToStr(InvertedFaces)+' '+Userstring(154)+'.';
        if NonManifold > 0 then
          Str:=Str+EOL+IntToStr(NonManifold)+' '+Userstring(155);
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
    B:=FreeShip.Layer[i].CheckIntegrity;
    IsIntegrityOk:=IsIntegrityOk and B;
  end;

  if not IsIntegrityOk then ShowMessage('Layers integrity is not Ok. Enable logs and check logs output. Further processing is not safe.');
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
  Answer: word; I,J,Cols,Rows: integer;
  L,B,D: TFloatType; P: T3DVector;
  Default: array[0..6, 0..4] of T3DVector; // Default ship has 7 columns of 5 points(or rows)
  Spline1,Spline2: TFreeSpline;
  TrvSplines: TFasterListTFreeSpline;
  TrvPoints: TFasterListTFreeSubdivisionControlPoint;
  Pts: array of array of TFreeSubdivisionControlPoint;
  StemPoint: TFreeSubdivisionControlPoint;
  FreeNewModelDialog: TFreeNewModelDialog;
begin
  Result:=False;
  Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
  if (Answer=mrCancel) or FreeShip.FileChanged then exit;
  FreeNewModelDialog:=TFreeNewModelDialog.Create(FreeShip);
  ShowTranslatedValues(FreeNewModelDialog);
  if FreeNewModelDialog.Execute then begin
    FreeShip.ModelIsLoaded:=False;
    CreateUndoObject( Userstring(157), True );
    Cols:=FreeNewModelDialog.NCols-1;
    Rows:=FreeNewModelDialog.NRows-1;
    L:=FreeNewModelDialog.Length;
    B:=FreeNewModelDialog.Breadth;
    D:=FreeNewModelDialog.Draft/2;
    Default[0,0]:=SetPoint(0.06, 0,   0   );   // station 0, stern
    Default[0,1]:=SetPoint(0.04, 0.0, 1.8 );
    Default[0,2]:=SetPoint(0,    0.01,2   );
    Default[0,3]:=SetPoint(-0.005,0.3,2.6 );
    Default[0,4]:=SetPoint(-0.01,0.3, 3.6 );
    Default[1,0]:=SetPoint(0.2,  0,   0   );   // station 1
    Default[1,1]:=SetPoint(0.18, 0.15,0.9 );
    Default[1,2]:=SetPoint(0.17, 0.34,1.2 );
    Default[1,3]:=SetPoint(0.16, 0.44,2   );
    Default[1,4]:=SetPoint(0.16, 0.42,3.45);
    Default[2,0]:=SetPoint(0.4,  0,   0   );   // station 2
    Default[2,1]:=SetPoint(0.4,  0.32,0.3 );
    Default[2,2]:=SetPoint(0.4,  0.45,0.6 );
    Default[2,3]:=SetPoint(0.4,  0.5, 2   );
    Default[2,4]:=SetPoint(0.4,  0.45,3.4 );
    Default[3,0]:=SetPoint(0.6,  0,   0   );   // station 3
    Default[3,1]:=SetPoint(0.6,  0.32,0.3 );
    Default[3,2]:=SetPoint(0.6,  0.45,0.6 );
    Default[3,3]:=SetPoint(0.6,  0.5, 2.1 );
    Default[3,4]:=SetPoint(0.6,  0.45,3.5 );
    Default[4,0]:=SetPoint(0.8,  0,   0   );   // station 4
    Default[4,1]:=SetPoint(0.8,  0.12,0.5 );
    Default[4,2]:=SetPoint(0.8,  0.2 ,1   );
    Default[4,3]:=SetPoint(0.8,  0.36,2.3 );
    Default[4,4]:=SetPoint(0.8,  0.42,3.8 );
    Default[5,0]:=SetPoint(0.92, 0,   0.15);   // station 5
    Default[5,1]:=SetPoint(0.92, 0.05,0.95);
    Default[5,2]:=SetPoint(0.92, 0.1, 1.9 );
    Default[5,3]:=SetPoint(0.92, 0.18,2.85);
    Default[5,4]:=SetPoint(0.94, 0.26,3.95);
    Default[6,0]:=SetPoint(1,    0,   1   );   // station 6, stem
    Default[6,1]:=SetPoint(0.99, 0,   1.75);
    Default[6,2]:=SetPoint(0.983,0,   2.5 );
    Default[6,3]:=SetPoint(0.98, 0,   3.25);
    Default[6,4]:=SetPoint(0.98, 0,   4   );
    FreeShip.Clear;
    FreeShip.ProjectSettings.ProjectUnits :=
      TFreeUnitType(FreeNewModelDialog.ComboBox1.ItemIndex);
    FreeShip.ProjectSettings.ProjectLength:=L;
    FreeShip.ProjectSettings.ProjectBeam:=B;
    FreeShip.ProjectSettings.ProjectDraft:=D*2;

    TrvSplines:=TFasterListTFreeSpline.Create;
    StemPoint:=nil;        // First create tmp. splines in transverse direction
    for I:=0 to 6 do begin
      Spline1:=TFreeSpline.Create(FreeShip.Surface);
      for J:=0 to 4 do begin P:=Default[I, J];
        P.X:=P.X * L;
        P.Y:=P.Y * B;
        P.Z:=P.Z * D;        Spline1.Add(P);
      end;
      TrvSplines.Add(Spline1);
    end;                   // now create tmp. splines in longitudinal direction
    Setlength(Pts, Rows+1);
    for I:=0 to rows do begin
      Setlength(Pts[I], Cols+1);
      Spline2:=TFreeSpline.Create(FreeShip.Surface);
      for j:=0 to TrvSplines.Count-1 do begin
        Spline1:=TrvSplines[J];
        P:=Spline1.Value(I / Rows);
        Spline2.Add(P);
      end; // now calculate all points on the longitudinal spline and send it to the surface
      for J:=0 to Cols do begin P:=Spline2.Value(J/Cols);
        Pts[I,J]:=TFreeSubdivisionControlPoint.Create(FreeShip.Surface);
        FreeShip.Surface.AddControlPoint(Pts[I, J]);
        Pts[I,J].Coordinate:=P;
        if (I=0) and (J=Cols) then StemPoint:=Pts[I,J];
      end;
      FreeAndNil(Spline2);
    end;
    for I:=1 to TrvSplines.Count do begin                // Destroy tmp splines
      Spline1:=TrvSplines[I-1];
      FreeAndNil(Spline1);
    end;
    TrvPoints:=TFasterListTFreeSubdivisionControlPoint.Create; // finally create the controlfaces over the newly calculated points
    for I:=1 to Rows do
    for J:=1 to cols do begin
        TrvPoints.Clear;
        TrvPoints.Add(Pts[I,J-1]);
        TrvPoints.Add(Pts[I,J]);
        TrvPoints.Add(Pts[I-1,J]);
        TrvPoints.Add(Pts[I-1,J-1]);
        FreeShip.Surface.AddControlFace(TrvPoints, True);
    end;                         // recheck edges crease after all faces added.
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
    for I:=0 to 20 do Intersection_Add(fiStation,I/20*(FreeShip.Surface.Max.X-FreeShip.Surface.Min.X));
    // Add 7 buttocks
    for I:=1 to 6 do Intersection_Add(fiButtock,I/7*(FreeShip.Surface.Max.Y-FreeShip.Surface.Min.Y));
    // Add 11 waterlines
    D:=(FreeShip.Surface.Max.Z-FreeShip.Surface.Min.Z)/10;
    for I:=0 to 10 do Intersection_Add(fiWaterline,I*D ); //10*(FreeShip.Surface.Max.Z-FreeShip.Surface.Min.Z));
    for I:=1 to 4 do Intersection_Add( fiDiagonal,(I*2+1)*D ); //FreeShip.FProjectSettings.ProjectDraft );

    FreeShip.FileChanged:=True;
    FreeShip.ModelIsLoaded:=True;
    FreeShip.Filename:='Example_Ship.ftm';
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
  Dialog:=TFreeLackenbyDialog.Create(FreeShip);
  ShowTranslatedValues(Dialog);
  vUndo:=CreateUndoObject(Userstring(159), False);
  UndoIndex:=FreeShip.UndoCount;
  if Dialog.Execute(FreeShip, Modified) then begin
    for I:=FreeShip.UndoCount downto UndoIndex+1 do
             FreeShip.UndoObject[I-1].Delete;
    if not Modified then vUndo.Delete else vUndo.Accept;
  end else begin
    for I:=FreeShip.UndoCount downto UndoIndex+1 do
             FreeShip.UndoObject[I-1].Delete;
    if Modified then
      vUndo.Restore;
    vUndo.Delete;
  end;
  FreeAndNil(Dialog);
end;

// Scale the entire model and all equivalent data such as stations etc.

procedure TFreeEdit.Model_Scale
( ScaleVector: T3DVector; OverrideLock, AdjustMarkers: boolean
);
var
  I, J: integer;
  Point: TFreeSubdivisionControlPoint;
  P: T3DVector;
  Marker: TFreeMarker;
begin
  for I:=1 to FreeShip.Surface.NumberOfControlPoints do begin
    Point:=FreeShip.Surface.ControlPoint[I-1];
    if (not Point.Locked) or (OverrideLock) then begin P:=Point.Coordinate;
      P.X:=P.X * ScaleVector.X;
      P.Y:=P.Y * ScaleVector.Y;
      P.Z:=P.Z * ScaleVector.Z;
      if Point.Locked then begin Point.Locked:=False;
        Point.Coordinate:=P;
        Point.Locked:=True;
      end else Point.Coordinate:=P;
    end;
  end;                                                // Update Mainparticulars
  FreeShip.ProjectSettings.ProjectLength:=abs(FreeShip.ProjectSettings.ProjectLength * Scalevector.X);
  FreeShip.ProjectSettings.ProjectBeam:=abs(FreeShip.ProjectSettings.ProjectBeam * Scalevector.Y);
  FreeShip.ProjectSettings.ProjectDraft:=abs(FreeShip.ProjectSettings.ProjectDraft * Scalevector.Z);
  if not FreeShip.ProjectSettings.FUseDefaultSplitSectionLocation then
   FreeShip.ProjectSettings.ProjectSplitSectionLocation
   :=abs( FreeShip.ProjectSettings.ProjectSplitSectionLocation*ScaleVector.X );

  if AdjustMarkers then                                       // Update markers
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

  for I:=0 to Freeship.NumberOfFlowlines-1 do with Freeship.Flowline[I] do begin
    FProjectionPoint.X := FProjectionPoint.X*Scalevector.X;
    FProjectionPoint.Y := FProjectionPoint.Y*Scalevector.Z;
    for J:=0 to FFlowline.NumberOfPoints-1 do begin
      P:=FFlowline.Point[J]; P.X:=P.X*Scalevector.X;
                             P.Y:=P.Y*Scalevector.Y;
                             P.Z:=P.Z*Scalevector.Z; FFlowline.Point[J]:=P;
    end;
  end;                                             // Refresh controlpoint data
  FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint; // Reset any present hydrostatic calculations
  for I:=1 to FreeShip.NumberOfHydrostaticCalculations do begin
    FreeShip.HydrostaticCalculation[I-1].Draft:=abs(FreeShip.HydrostaticCalculation[I-1].Draft * ScaleVector.Z);
    FreeShip.HydrostaticCalculation[I-1].Trim:=FreeShip.HydrostaticCalculation[I-1].Trim * ScaleVector.Z;
    FreeShip.HydrostaticCalculation[I-1].Calculated:=False;
  end;                                             // Initialize all other data
  FreeShip.Built:=False;                                              // Redraw
  FreeShip.FileChanged:=True;
  FreeShip.ReDraw;
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
    Point:=FreeShip.SelectedControlPoint[I-1];
    if (not Point.Locked) and (Point.NumberOfEdges = 2) then Inc(N);
  end;
  if N > 0 then FreeShip.Surface.ClearMesh;

  vUndo:=CreateUndoObject(Userstring(160), False);
  for I:=FreeShip.NumberOfSelectedControlPoints downto 1 do begin
    Point:=FreeShip.SelectedControlPoint[I-1];
    if (not Point.Locked) and (Point.NumberOfEdges = 2) then begin
      Point.Collapse;
      Inc(N);
    end;
  end;
  if N > 0 then begin vUndo.Accept;
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
    Point:=FreeShip.Surface.ControlPoint[I-1];
    if Point.NumberOfFaces = 0 then begin Point.Delete; Inc(N); end;
  end;
  if N > 0 then begin
    vUndo.Accept;
    FreeShip.Built:=False;
    Freeship.RebuildModel;
    FreeShip.FileChanged:=True;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
    MessageDlg( IntToStr(N)+#32+Userstring(162),mtInformation,[mbOK],0 );
  end else vUndo.Delete;
end;

// Finds all intersection of VISIBLE edges and a 3D plane, and inserts a point on each of these edges
procedure TFreeEdit.Point_InsertPlane;
var
  Dialog: TFreeInsertPlaneDialog;
  Min, Max: T3DVector;
  vUndo: TFreeUndoObject;
  N: integer;
begin
  FreeShip.Extents(Min, Max);
  Dialog:=TFreeInsertPlaneDialog.Create(FreeShip);
  ShowTranslatedValues(Dialog);
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
    end else vUndo.Delete;                           // nothis has been changed
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
    if FreeShip.Layer[I-1].Count > 0 then Layers.Add(FreeShip.Layer[I-1]);
  if Layers.Count > 1 then begin
    Dialog:=TFreeIntersectLayerDialog.Create(FreeShip);
    ShowTranslatedValues(Dialog);
    if Dialog.Execute(Layers) then
    if assigned(Dialog.Layer1) and assigned(Dialog.Layer2) then
    begin
      vUndo:=CreateUndoObject(Userstring(164), False);
      if Dialog.Layer1.CalculateIntersectionPoints(Dialog.Layer2) then begin
         vUndo.Accept;
         FreeShip.FileChanged:=True;
         FreeShip.Built:=False;
         Freeship.RebuildModel;
         if Assigned(FreeShip.OnUpdateGeometryInfo) then
           FreeShip.OnUpdateGeometryInfo(self);
      end else begin
         vUndo.Delete;
         MessageDlg( Userstring(165),mtInformation,[mbOK],0 );
      end;
    end;
    FreeAndNil(Dialog);
  end
  else MessageDlg(Userstring(166), mtError, [mbOK], 0);
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
      FreeShip.SelectedControlPoint[I-1].Locked:=True;
    FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
    Freeship.ReDraw;
    FreeShip.FileChanged:=True;
  end;
end;

// Unlocks all selected locked points
procedure TFreeEdit.Point_Unlock;
var I: integer;
begin
  if FreeShip.NumberOfSelectedLockedPoints > 0 then begin
    self.CreateUndoObject(Userstring(168), True);
    for I:=1 to FreeShip.NumberOfSelectedControlPoints do
      FreeShip.SelectedControlPoint[I-1].Locked:=False;
    FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
    Freeship.ReDraw;
    FreeShip.FileChanged:=True;
  end;
end;

// Unlocks all locked points
procedure TFreeEdit.Point_UnlockAll;
var I,N: integer;
begin
  if FreeShip.NumberOfLockedPoints > 0 then begin
    CreateUndoObject(Userstring(169), True);
    N:=FreeShip.NumberOfLockedPoints;
    for I:=1 to FreeShip.Surface.NumberOfControlPoints do
      FreeShip.Surface.ControlPoint[I-1].Locked:=False;
    FreeShip.ActiveControlPoint:=FreeShip.ActiveControlPoint;
    Freeship.ReDraw;
    MessageDlg(IntToStr(N)+#32+Userstring(170)+'.', mtInformation, [mbOK], 0);
    FreeShip.FileChanged:=True;
  end;
end;

// Function that shows a warning when certain edit commands are invoked and the model contains locked points
function TFreeEdit.ProceedWhenLockedPoints: boolean;
begin
  if FreeShip.NumberOfLockedPoints > 0 then
    Result:=MessageDlg(Userstring(86)+EOL+Userstring(87),mtWarning,[mbYes,mbNo],0)=mrYes
  else Result:=True;
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
  if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
end;

// Add a new point with XYZ to the model with no edges/faces attached
function TFreeEdit.Point_New(coord:T3DVector): TFreeSubdivisionControlPoint;
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
  P: T3DVector;
  vUndo: TFreeUndoObject;
begin
  if FreeShip.NumberOfSelectedControlPoints > 1 then begin
    NLocked:=0;
    for I:=1 to FreeShip.NumberOfSelectedControlPoints-1 do
      if FreeShip.SelectedControlPoint[I].Locked then Inc(NLocked);
    // Number of lovked points must be smaller then NumberOfSelectedControlPoints-2
    if NLocked < FreeShip.NumberOfSelectedControlPoints-1 then begin
      P1:=FreeShip.SelectedControlPoint[0];
      vUndo:=CreateUndoObject(rsPointAnchorConstraintChanged, False);
      NChanged:=0;
      for I:=1 to FreeShip.NumberOfSelectedControlPoints-1 do begin
        Point:=FreeShip.SelectedControlPoint[I];
        if not Point.Locked then begin Point.AnchorPoint:=P1; Inc(NChanged); end;
      end;
      if NChanged > 0 then begin
        vUndo.Accept;
        FreeShip.FileChanged:=True;
        Freeship.RebuildModel;
      end else vUndo.Delete;
    end else MessageDlg( Userstring(172)+'.',mtError,[mbOK],0 );
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
  P: T3DVector;
  vUndo: TFreeUndoObject;
begin
  if FreeShip.NumberOfSelectedControlPoints>1 then begin
    NLocked:=0;
    // Determine if the number of points to be moved does not conatin locked
    // or hard anchored controlpoints.
    // However the first and last points (determining the linesegment) are
    // allowed to be locked or hard anchored
    NLocked:=0;
    for I:=1 to FreeShip.NumberOfSelectedControlPoints-1 do begin
      Point:=FreeShip.SelectedControlPoint[I];
      if Point.Locked or ((Point.AnchorPoint<>nil)
      and Point.IsAnchorHard) then Inc(NLocked);
    end;
    // Number of locked or hard anchored points must be smaller then NumberOfSelectedControlPoints-2
    if NLocked < FreeShip.NumberOfSelectedControlPoints-1 then begin
      P1:=FreeShip.SelectedControlPoint[0];
      vUndo:=CreateUndoObject(rsPointAnchorConstraintChanged, False);
      NChanged:=0;
      for I:=1 to FreeShip.NumberOfSelectedControlPoints-1 do begin
        Point:=FreeShip.SelectedControlPoint[I];
        if not Point.Locked
        and not((Point.AnchorPoint<>nil) and Point.IsAnchorHard) then begin
          Point.Coordinate:=P1.Coordinate;
          Inc(NChanged);
        end;
      end;
      if NChanged > 0 then begin vUndo.Accept;
        FreeShip.FileChanged:=True;
        Freeship.RebuildModel;
      end else vUndo.Delete;
    end else MessageDlg( Userstring(172)+'.',mtError,[mbOK],0 );
  end;
end;

// Project all selected points onto a straight line through the first and last selected points
procedure TFreeEdit.Point_ProjectStraightLine;
var
  I,NLocked,NChanged: integer;
  Point: TFreeSubdivisionControlPoint;
  P1, P2: TFreeSubdivisionControlPoint;
  P: T3DVector;
  vUndo: TFreeUndoObject;
begin
  if FreeShip.NumberOfSelectedControlPoints > 2 then begin
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
    if NLocked < FreeShip.NumberOfSelectedControlPoints-2 then begin
      P1:=FreeShip.SelectedControlPoint[0];
      P2:=FreeShip.SelectedControlPoint[FreeShip.NumberOfSelectedControlPoints-1];
      vUndo:=CreateUndoObject(userstring(171), False);
      NChanged:=0;
      for I:=2 to FreeShip.NumberOfSelectedControlPoints-1 do begin
        Point:=FreeShip.SelectedControlPoint[I-1];
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
    end else MessageDlg( Userstring(172)+'.',mtError,[mbOK],0 );
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
  P: T3DVector;
  vUndo: TFreeUndoObject;
begin
  if FreeShip.NumberOfSelectedControlPoints > 2 then begin
    // Determine if the number of points to be moved does not conatin locked controlpoints only
    // however the first and last points (determining the linesegment) are allowed to be locked
    NLocked:=0;
    for I:=2 to FreeShip.NumberOfSelectedControlPoints-1 do
      if FreeShip.SelectedControlPoint[I-1].Locked then Inc(NLocked);
    // Number of lovked points must be smaller then NumberOfSelectedControlPoints-2
    if NLocked < FreeShip.NumberOfSelectedControlPoints-2 then begin
      P1:=FreeShip.SelectedControlPoint[0];
      P2:=FreeShip.SelectedControlPoint[FreeShip.NumberOfSelectedControlPoints-1];
      vUndo:=CreateUndoObject(rsPointLinearConstraintChanged, False);
      NChanged:=0;
      for I:=2 to FreeShip.NumberOfSelectedControlPoints-1 do begin
        Point:=FreeShip.SelectedControlPoint[I-1];
        if not Point.Locked then begin
          Point.SetLinearConstraint(P1,P2);
          Point.AdjustToLinearConstraint(self.FreeShip.GetFocusedViewport);
          Inc(NChanged);
        end;
      end;
      if NChanged > 0 then begin vUndo.Accept;
        FreeShip.FileChanged:=True;
        Freeship.RebuildModel;
      end else vUndo.Delete;
    end else MessageDlg(Userstring(172)+'.', mtError, [mbOK], 0);
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
    +FreeShip.NumberOfSelectedControlPointGroups
    +FreeShip.NumberOfSelectedControlEdges
    +FreeShip.NumberOfSelectedControlFaces
    +FreeShip.NumberOfSelectedControlCurves
    +FreeShip.NumberOfselectedMarkers
    +FreeShip.NumberOfselectedFlowlines;

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
    +FreeShip.NumberOfSelectedControlPointGroups
    +FreeShip.NumberOfSelectedControlEdges
    +FreeShip.NumberOfSelectedControlFaces
    +FreeShip.NumberOfSelectedControlCurves
    +FreeShip.NumberOfselectedMarkers
    +FreeShip.NumberOfselectedFlowlines;
           // if MessageDlg(Userstring(173)+#32+IntToStr(N)+#32+Userstring(174)+'?',mtWarning,[mbYes,mbNo],0)=mrYes then
   if (MR = mrAbort) and (N > 0) then begin
      CreateUndoObject( Userstring(175),True );
      for I:=FreeShip.NumberOfselectedFlowlines downto 1
          do FreeShip.SelectedFlowline[I-1].Delete;
      for I:=FreeShip.NumberOfselectedMarkers downto 1
          do FreeShip.SelectedMarker[I-1].Delete;
      FreeShip.Surface.Selection_Delete;
      FreeShip.ActiveControlPoint:=nil;
      FreeShip.FileChanged:=True;
      FreeShip.Built:=False;                                // Freeship.ReDraw;
      if Assigned(FreeShip.OnUpdateGeometryInfo) then
         FreeShip.OnUpdateGeometryInfo(self);
   end;
end;

// Select all visible items
procedure TFreeEdit.Selection_SelectAll;
var
  I, J: integer;
begin
  for I:=1 to FreeShip.NumberOfLayers do
    if FreeShip.Layer[I-1].SurfaceVisible then
      for J:=1 to FreeShip.Layer[I-1].Count do
        FreeShip.Layer[I-1].Items[J-1].Selected:=True;
  for I:=1 to FreeShip.Surface.NumberOfControlEdges do
    if FreeShip.Surface.ControlEdge[I-1].Visible then
      FreeShip.Surface.ControlEdge[I-1].Selected:=True;
  for I:=1 to FreeShip.Surface.NumberOfControlPoints do
    if FreeShip.Surface.ControlPoint[I-1].Visible then
      FreeShip.Surface.ControlPoint[I-1].Selected:=True;
  for I:=1 to FreeShip.Surface.NumberOfControlCurves do
    if FreeShip.Surface.ControlCurve[I-1].Visible then
      FreeShip.Surface.ControlCurve[I-1].Selected:=True;
  for I:=1 to FreeShip.NumberofMarkers do
    if FreeShip.Marker[I-1].Visible then
      FreeShip.Marker[I-1].Selected:=True;
  for I:=1 to FreeShip.NumberofFlowlines do
    if FreeShip.Flowline[I-1].Visible then
      FreeShip.Flowline[I-1].Selected:=True;
  Freeship.ReDraw;
end;

// Select all control points
procedure TFreeEdit.Selection_SelectAllControlPoints;
var  I, J: integer;
begin
  {for I:=1 to FreeShip.NumberOfLayers do
    if FreeShip.Layer[I-1].SurfaceVisible then
      for J:=1 to FreeShip.Layer[I-1].Count do
        FreeShip.Layer[I-1].Items[J-1].Selected:=True;}
  for I:=1 to FreeShip.Surface.NumberOfControlPoints do
    if FreeShip.Surface.ControlPoint[I-1].Visible then
      FreeShip.Surface.ControlPoint[I-1].Selected:=True;
  Freeship.ReDraw;
end;


procedure TFreeEdit.Selection_SelectLeakPoints;
var I: integer;
begin
  for I:=0 to FreeShip.Surface.NumberOfControlPoints-1 do
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
    if FreeShip.FUndoPosition = FreeShip.UndoCount then
      if FreeShip.UndoObject[FreeShip.UndoCount-1].FIsTempRedoObject then //??
      else CreateRedoObject;
    if FreeShip.FPreviousUndoPosition < FreeShip.FUndoPosition then
      Dec(FreeShip.FUndoPosition);
    FreeShip.FPreviousUndoPosition:=FreeShip.FUndoPosition;
    Dec(FreeShip.FUndoPosition);
    UndoObject:=FreeShip.FUndoObjects[FreeShip.FUndoPosition];
    UndoObject.Restore;
    FreeShip.ProjectSettings.SavePreview:=Preview;
  end;
end;

// Clear the undo history
procedure TFreeEdit.Undo_Clear; begin  FreeShip.ClearUndo; end;

// Show the undo history
procedure TFreeEdit.Undo_ShowHistory;
var
  Dialog: TFreeUndoHistoryDialog;
  vUndo: TFreeUndoObject;
  Index: integer;
  vRedo: TFreeUndoObject;
begin
  Dialog:=TFreeUndoHistoryDialog.Create(FreeShip);
  ShowTranslatedValues(Dialog);
  vRedo:=nil;
  if (FreeShip.FUndoPosition = FreeShip.UndoCount) and (FreeShip.UndoCount > 0) then
    if not FreeShip.UndoObject[FreeShip.UndoCount-1].FIsTempRedoObject then
    begin
      vRedo:=CreateRedoObject;
      Dec(FreeShip.FUndoPosition);
    end;
  if Dialog.Execute(FreeShip) then begin
    if Dialog.UndoBox.ItemIndex <> -1 then begin
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
  else if vRedo <> nil then vRedo.Delete; FreeAndNil(Dialog);
end;

procedure TFreeEdit.Redo;
var
  UndoObject: TFreeUndoObject;
  Preview: boolean;
begin
  if FreeShip.FUndoObjects.Count > 0 then begin
    Preview:=FreeShip.ProjectSettings.SavePreview;
//  try
      if FreeShip.FPreviousUndoPosition > FreeShip.FUndoPosition then
        Inc(FreeShip.FUndoPosition);
      FreeShip.FPreviousUndoPosition:=FreeShip.FUndoPosition;
      Inc(FreeShip.FUndoPosition);
      UndoObject:=FreeShip.FUndoObjects[FreeShip.FUndoPosition-1];
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
    Intersection:=TargetList[I-1];
    if Abs(-InterSection.FPlane.d-Distance) < 1e-7 then begin // Yes, it exists, so do not add a new one
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

