{------------------------------------------------------------------}
{ Импорт-експорт файлов в различных КАД-форматах по поверхностям }
{------------------------------------------------------------------}
{
  1 = Wavefront Technologies for The Advanced Visualizer animation package.
  2 = WaveFront.obj-запись
  3 = Virtual Reality Markup Language.VRML(.wrl)
  4 = FREE!ship Exchange Format (.fef)
  5 = ImportControlPointGrid  равномерная сетка узлов?(точек) с равным шагом
  6 = ImportCoordGrid похоже на прямоугольную сетку ординат с равным шагом ()
  7 =
}
procedure TFreeSubdivisionSurface.ImportObjFile( Strings: TStringList );
var
  I,J,K,Index: integer; Str: AnsiString;
// CFace: TFreeSubdivisionControlFace; CPoint: TFreeSubdivisionCOntrolPoint;
  CPoints, FacePoints: TFasterListTFreeSubdivisionControlPoint;
  C3d: T3DCoordinate;
  Faces: TStringList;
  Vindex: array of AnsiString;
begin
  CPoints:=TFasterListTFreeSubdivisionControlPoint.Create(true,false);
  FacePoints:=TFasterListTFreeSubdivisionControlPoint.Create(true,false);
  Faces:=TStringList.Create;
  Self.IsLoading:=true;
  for I:=0 to Strings.Count-1 do begin
    Str:=BlankOff( Strings[I] );
    if Str.StartsWith('#') then else
    if Str.StartsWith('v ') then begin SetLength( Vindex,0 );
      Vindex:=Str.Split( [' '] );
      C3d.X:=GetFloat( Vindex[1] );
      C3d.Y:=GetFloat( Vindex[3] );
      C3d.Z:=GetFloat( Vindex[2] ); CPoints.Add( AddControlPoint( C3d ) );
    end else
    if Str.StartsWith('f ') then Faces.Append( Str );
  end;
  for I:=0 to Faces.Count-1 do begin SetLength( Vindex,0 ); FacePoints.Clear;
    Vindex:=Faces[I].Split( [' '] );
    K:=Length( Vindex )-1;           //?? с замыкаением контура много?угольника
    for J:=0 to K do begin
      Index:=GetInteger( Vindex[(J mod K)+1].Replace('/',' ') ); // впереди 'f'
      FacePoints.Add( CPoints[Index-1] );
    end;
    AddControlFace( FacePoints,True,Self.Layer[0] );
  end;
  Self.IsLoading:=false;
  SetLength( Vindex,0 );
  CPoints.Free;
  FacePoints.Free;
  Faces.Free;
end;
procedure TFreeSubdivisionSurface.ExportObjFile
        ( ExportControlNet: boolean; Strings: TStringList );
var
  I, J, K: integer;
  Index: integer;
  Tmp: TFasterListTFreeSubdivisionPoint;
  CFace: TFreeSubdivisionControlFace;
  Child: TFreeSubdivisionFace;
  Str: string;
  P: TFreeSubdivisionPoint;
  C3d: T3DCoordinate;
begin
  if not ExportControlNet then begin               // export subdivided surface
    if not Built then rebuild;
           // first sort subdiv points for faster acces of function (Indexof())
    Strings.Add( '# FREE!ship subdivided surface' );
    FPoints.Sort;                                 // Create points for portside
    Tmp:=TFasterListTFreeSubdivisionPoint.Create;
    Tmp.Capacity:=NumberOfSubDivPoints;
    for I:=1 to NumberOfSubDivPoints do begin
      C3d:=SubDivPoint[I-1].Coordinate;
      Strings.Add(format('v %07.04f %07.04f %07.04f',[C3d.x,C3d.z,C3d.y]));
      if C3d.y>0 then Tmp.Add(SubDivPoint[I-1]);  /// ????
    end;
    if DrawMirror then begin                      // Create points for portside
      Tmp.Sort;                                   // лишний болрт для картинки
      for I:=1 to Tmp.Count do begin
        P:=Tmp[I-1]; C3d:=P.Coordinate;
        Strings.Add(format('v %07.04f %07.04f %07.04f',[C3d.x,C3d.z,-C3d.y])); //(-Y)!
      end;
    end;
    for I:=1 to NumberOfControlFaces do begin
      CFace:=ControlFace[I-1];
      if CFace.Layer.SurfaceVisible then begin
        for J:=1 to CFace.ChildCount do begin                       // portside
          Str:='f';
          Child:=CFace.Child[J-1];
          for k:=1 to Child.FPoints.Count do begin
            Index:=FPoints.SortedIndexOf(Child.FPoints[K-1]);
            if Index <> -1 then Str:=Str+#32+IntToStr(index+1);
          end;
          Strings.Add(Str);
          if (CFace.Layer.Symmetric) and (DrawMirror) then begin // Starboard side
            Str:='f';
            Child:=CFace.Child[J-1];
            for k:=Child.FPoints.Count downto 1 do begin
              if Child.Point[K-1].Coordinate.Y > 0 then begin
                Index:=Tmp.SortedIndexOf(Child.Point[K-1])+NumberOfSubDivPoints;
              end else
                Index:=FPoints.SortedIndexOf(Child.FPoints[K-1]);
              Str:=Str+#32+IntToStr( index+1 );
            end;
            Strings.Add(Str);
          end;
        end;
      end;
    end;
    FreeAndNil(Tmp);
  end else begin                                  // export the controlnet only
    if not Built then rebuild;
           // first sort controlpoints for faster acces of function (Indexof())
    Strings.Add( '# FREE!ship controlnet' );
    FControlPoints.Sort;                   // Create ControlPoints for portside
    Tmp:=TFasterListTFreeSubdivisionPoint.Create;
    Tmp.Capacity:=NumberOfControlPoints;
    for I:=0 to NumberOfControlPoints-1 do begin
      Strings.Add
      ( 'v '+FloatToStrF( ControlPoint[I].Coordinate.x,ffFixed,7,4 )+ #32
            +FloatToStrF( ControlPoint[I].Coordinate.z,ffFixed,7,4 )+ #32
            +FloatToStrF( ControlPoint[I].Coordinate.y,ffFixed,7,4 ) );
      if ControlPoint[I].Coordinate.y>0 then Tmp.Add( ControlPoint[I] );
    end;
    if DrawMirror then begin               // Create ControlPoints for portside
      Tmp.Sort;
      for I:=0 to Tmp.Count-1 do begin P:=Tmp[I];
        Strings.Add( 'v '+FloatToStrF( P.Coordinate.x,ffFixed,7,4 )+#32
                         +FloatToStrF( P.Coordinate.z,ffFixed,7,4 )+#32
                         +FloatToStrF(-P.Coordinate.y,ffFixed,7,4 ) );
      end;
    end;
    for I:=1 to NumberOfControlFaces do begin
      CFace:=ControlFace[I-1];
      if CFace.Layer.SurfaceVisible then begin                      // portside
        Str:='f';
        for k:=1 to Cface.FPoints.Count do begin
          Index:=FControlPoints.SortedIndexOf(Cface.Point[K-1]);
          if Index <> -1 then Str:=Str+#32+IntToStr(index+1);
        end;
        Strings.Add(Str);
        if (CFace.Layer.Symmetric) and (DrawMirror) then begin // Starboard side
          Str:='f';
          for k:=Cface.FPoints.Count downto 1 do begin
            if Cface.Point[K-1].Coordinate.Y>0 then begin
              Index:=Tmp.SortedIndexOf(Cface.Point[K-1])+NumberOfControlPoints;
            end else
              Index:=FControlPoints.SortedIndexOf(Cface.Point[K-1]);
            Str:=Str+#32+IntToStr( index+1 );
          end;
          Strings.Add(Str);
        end;
      end;
    end;
    FreeAndNil(Tmp);
  end;
end;
//
// VRML (Virtual Reality Modeling Language, pronounced vermal or by its initials, 
// originally—before 1995—known as the Virtual Reality Markup Language) 
// is a standard file format for representing 3-dimensional (3D) interactive vector graphics,
// designed particularly with the World Wide Web in mind. It has been superseded by X3D.[1]
//
procedure TFreeSubdivisionSurface.LoadVRMLFile(Filename: string);
var
  VRMLList: TVRMLList;
  VRMLVersion: String;
begin
  if FileExists(Filename) then begin
    FIsLoading:=true;
//  VRMLList:=TVRMLList.Create;
    VRMLVersion:=TVRMLList.CheckVRMLFileVersion( Filename );
    if VRMLVersion='VRML V1.0' then VRMLList:=TVRMLList.Create else
    if VRMLVersion='VRML V2.0' then VRMLList:=TVRML2Scene.Create else
                               begin FIsLoading:=false; exit; end;
    MainForm.FreeShip.Clear;
    VRMLList.Import( Filename,Self );
  end;
end;
//
// The Fef file format (FREE!ship Exchange Format) 
// is of no interest to most users since it is mainly
// supported by other programs from the same developer.
//
procedure TFreeSubdivisionSurface.ExportFeFFile(Strings: TStringList);
var I: integer;
begin                                                 // Add layer information
  Strings.Add(IntToStr(NumberOfLayers));
  for I:=0 to NumberOfLayers-1 do begin
    Strings.Add(Layer[I].Name);
    Strings.Add(IntToStr(Layer[I].LayerID)+#32 +
       IntToStr(Layer[I].Color)+#32 +
      BoolToStr(Layer[I].SurfaceVisible)+#32 +
      BoolToStr(Layer[I].Developable)+#32 +
      BoolToStr(Layer[I].Symmetric)+#32 +
      BoolToStr(Layer[I].FUseForIntersections)+#32 +
      BoolToStr(Layer[I].FUseInHydrostatics)+#32 +
      BoolToStr(Layer[I].FShowInLinesplan)+#32 +
      FloatToStrF(Layer[I].MaterialDensity, ffFixed, 10, 8)+#32 +
      FloatToStrF(Layer[I].Thickness, ffFixed, 10, 8));
  end;     // first sort controlpoints for faster acces of function (Indexof())
  FControlPoints.Sort;
  Strings.Add(IntToStr(NumberOfControlPoints));
  for I:=1 to NumberOfControlPoints do ControlPoint[I-1].SaveToStream(Strings);
  Strings.Add(IntToStr(NumberOfControlEdges));
  for I:=1 to NumberOfControlEdges do ControlEdge[I-1].SaveToStream(Strings);
  Strings.Add(IntToStr(NumberOfControlFaces));
  for I:=1 to NumberOfControlFaces do ControlFace[I-1].SaveToStream(Strings);
end;
//
//  ... и то же обратно на вход
//
procedure TFreeSubdivisionSurface.ImportFEFFile(Strings: TStringList; var LineNr: integer);
var
  Str: AnsiString;
  I,J,N,Np, Index: integer;
  Point, P1, P2: TFreeSubdivisionControlPoint;
  Edge: TFreeSubdivisionControlEdge;
  Face: TFreeSubdivisionControlFace;
  Layer: TFreeSubdivisionLayer;

  function NewPoint(P: T3DCoordinate): TFreeSubdivisionControlPoint;
  begin Result:=TFreeSubdivisionControlPoint.Create(self);
        Result.FCoordinate:=P;
        FControlPoints.Add(Result);
  end;{NewPoint}
begin
  FIsLoading:=true;  // Read layer information
  Inc(LineNr);
  Str:=Strings[LineNr];
  N:=GetInteger( Str);
  for I:=1 to N do begin
    if I>NumberOfLayers then Layer:=self.AddNewLayer
                        else Layer:=self.Layer[I-1];
    Inc(LineNr);
    Layer.FDescription:=Strings[LineNr];
    ;
    Inc(LineNr);
    Str:=Strings[LineNr];
    Layer.FLayerID:=GetInteger( Str);
    if Layer.FLayerID > FLastusedLayerID then FLastusedLayerID:=Layer.FLayerID;
    Layer.FColor:=GetInteger( Str);
    Layer.FSurfaceVisible:=GetBoolean( Str);
    Layer.FDevelopable:=GetBoolean( Str);
    Layer.FSymmetric:=GetBoolean( Str);
    Layer.FSymmetric:=True;
    Layer.FUseForIntersections:=GetBoolean( Str);
    Layer.FUseInHydrostatics:=GetBoolean( Str);
    Layer.FShowInLinesplan:=GetBoolean( Str);
    Layer.FMaterialDensity:=GetFloat( Str);
    Layer.FThickness:=GetFloat( Str);
  end;
  if Assigned(FOnChangeLayerData) then FOnChangeLayerData(self);
  Inc(LineNr);
  Str:=Strings[LineNr];            // Read controlpoints
  N:=GetInteger( Str);
  for I:=1 to N do begin
    Point:=TFreeSubdivisionControlPoint.Create(self);
    FControlPoints.Add(Point);
    Point.LoadFromStream(LineNr, Strings);
  end;
                                   // Read controlEdges
  Inc(LineNr);
  Str:=Strings[LineNr];
  N:=GetInteger( Str);
  for I:=1 to N do begin
    Edge:=TFreeSubdivisionControlEdge.Create(self);
    Edge.FControlEdge:=True;
    FControlEdges.Add(Edge);
    Edge.LoadFromStream(LineNr, Strings);
  end;
                                    // Read controlFaces
  Inc(LineNr);
  Str:=Strings[LineNr];
  N:=GetInteger( Str);
  for I:=1 to N do begin
    Face:=TFreeSubdivisionControlFace.Create(self);
    FControlFaces.Add(Face);
    Inc(LineNr);
    Str:=Strings[LineNr];
    Np:=GetInteger( Str);
    for J:=1 to Np do begin
      Index:=GetInteger( Str);           // Attach controlface to controlpoints
      Face.AddPoint(ControlPoint[Index]);
    end;            // Attach controlface to the already existing control edges
    P1:=Face.Point[Face.FPoints.Count-1];
    for J:=1 to Face.FPoints.Count do begin
      P2:=Face.Point[J-1];
      Edge:=EdgeExists(P1, P2) as TFreeSubdivisionControlEdge;
      if Edge<>nil then Edge.AddFace(Face); // else MessageDlg( 'Could not find edge!',mtError,[mbOK],0);
      P1:=P2;
    end;                                   // Read Layerindex
    Index:=GetInteger( Str);
    while Index > NumberOfLayers-1 do begin AddNewLayer; end;
    Layer:=FLayers[Index];
    Layer.AddControlFace(Face);
  end;
  Built:=False;
  FInitialized:=True;
  if assigned(FOnChangeLayerData) then FOnChangeLayerData(self);
  if assigned(FOnChangeActiveLayer) then FOnChangeActiveLayer(self, self.Layer[0]);
  FisLoading:=false;
end;
//
//  похоже на прямоугольную сетку узлов?(точек) с равным шагом
//
procedure TFreeSubdivisionSurface.ImportControlPointGrid
( Grid: TFreeSubdivisionControlPointGrid; 
  Cols, Rows: integer;
  Layer: TFreesubdivisionLayer );
var
  P11,P12,P22,P21:TFreeSubdivisionControlPoint;
  GridPoints, FacePoints: TFasterListTFreeSubdivisionControlPoint;
  Edge: TFreeSubdivisionEdge;
  I, J: integer;
begin
  FIsLoading:=true;
  GridPoints:=TFasterListTFreeSubdivisionControlPoint.Create;
  FacePoints:=TFasterListTFreeSubdivisionControlPoint.Create;
  for I:=1 to Rows-1 do begin
    for J:=1 to Cols-1 do begin
      FacePoints.Clear;
      P11:=Grid[I-1,J-1];
      P12:=Grid[I-1,J];
      P22:=Grid[I,J];
      P21:=Grid[I,J-1];
      if FacePoints.IndexOf(P11) = -1 then FacePoints.Add(P11);
      if FacePoints.IndexOf(P12) = -1 then FacePoints.Add(P12);
      if FacePoints.IndexOf(P22) = -1 then FacePoints.Add(P22);
      if FacePoints.IndexOf(P21) = -1 then FacePoints.Add(P21);
      if FacePoints.Count >= 3 then
        if Layer <> nil then AddControlFace(FacePoints, True, Layer)
                        else AddControlFace(FacePoints, True);
      GridPoints.AddList(FacePoints);
    end;
  end;
{ // set crease edges
  for I:=2 to Cols do begin
    Edge:=EdgeExists(Grid[0][I-2], Grid[0][I-1]);
    if Edge <> nil then Edge.Crease:=True;
    Edge:=EdgeExists(Grid[Rows-1][I-2], Grid[Rows-1][I-1]);
    if Edge <> nil then Edge.Crease:=True;
  end;
  for I:=2 to Rows do begin
    Edge:=EdgeExists(Grid[I-2][0], Grid[I-1][0]);
    if Edge <> nil then Edge.Crease:=True;
    Edge:=EdgeExists(Grid[I-2][Cols-1], Grid[I-1][Cols-1]);
    if Edge <> nil then Edge.Crease:=True;
  end;
}
  for i:=0 to GridPoints.Count-1 do
  for j:=0 to GridPoints[i].Edges.Count-1 do
    GridPoints[i].Edge[j].Crease:=false;
                                                            // set cornerpoints
  for I:=1 to Rows do
  for J:=1 to Cols do
    if Grid[I-1][J-1].NumberOfFaces<2 then Grid[I-1][J-1].VertexType:=svCorner;
  FreeAndNil( FacePoints );
  FIsLoading:=false;
end;
//
//  похоже на прямоугольную сетку ординат с равным шагом
//
procedure TFreeSubdivisionSurface.ImportCoordGrid
( Points: TFreeCoordinateGrid;
  Cols, Rows: integer;
  Layer: TFreesubdivisionLayer);
var
  Grid: TFreeSubdivisionControlPointGrid;
  P11,P12,P22,P21:TFreeSubdivisionControlPoint;
  FacePoints: TFasterListTFreeSubdivisionControlPoint;
  Edge: TFreeSubdivisionEdge;
  I, J: integer;
begin
  FIsLoading:=true;
  Setlength( Grid,Rows );
  for I:=0 to Rows-1 do begin Setlength(Grid[I], Cols);
    for J:=0 to Cols-1 do Grid[I][J]:=AddControlPoint(Points[I][J]);
  end;
  ImportControlPointGrid(Grid, Cols, Rows,  Layer);
  FIsLoading:=false;
end;

