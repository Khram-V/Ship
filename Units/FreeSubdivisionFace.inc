{--------------------------------------------------------------------------------------------------}
{                                         TFreeSubdivisionFace                                     }
{--------------------------------------------------------------------------------------------------}
function TFreeSubdivisionFace.FGetArea: TFloatType;
var
  I: integer;

  function TriangleArea(P1, P2, P3: T3DCoordinate): TFloatType;
  var
    ax, ay, az: TFloatType;
  begin
    ax:=0.5 * ((P1.y - P2.y) * (P1.z + P2.z) + (P2.y - P3.y) * (P2.z + P3.z) +
      (P3.y - P1.y) * (P3.z + P1.z));
    ay:=0.5 * ((P1.z - P2.z) * (P1.x + P2.x) + (P2.z - P3.z) * (P2.x + P3.x) +
      (P3.z - P1.z) * (P3.x + P1.x));
    az:=0.5 * ((P1.x - P2.x) * (P1.y + P2.y) + (P2.x - P3.x) * (P2.y + P3.y) +
      (P3.x - P1.x) * (P3.y + P1.y));
    Result:=Sqrt(ax * ax + ay * ay + az * az);
  end;{TriangleArea}

begin
  Result:=0.0;
  for I:=3 to NumberOfPoints do
    Result:=Result + TriangleArea(Point[0].Coordinate, Point[I - 2].Coordinate,
      Point[I - 1].Coordinate);
end;{TFreeSubdivisionFace.FGetArea}

function TFreeSubdivisionFace.FGetFaceCenter: T3DCoordinate;
var
  I: integer;
  P: TFreeSubdivisionPoint;
begin
  Result:=ZERO;
  if FPoints.Count > 1 then
  begin
    for I:=1 to FPoints.Count do
    begin
      P:=FPoints[I - 1];
      Result.X:=Result.X + P.FCoordinate.X;
      Result.Y:=Result.Y + P.FCoordinate.Y;
      Result.Z:=Result.Z + P.FCoordinate.Z;
    end;
    Result.X:=Result.X / FPoints.Count;
    Result.Y:=Result.Y / FPoints.Count;
    Result.Z:=Result.Z / FPoints.Count;
  end;
end;{TFreeSubdivisionFace.FGetCentre}

function TFreeSubdivisionFace.FGetFaceNormal: T3DCoordinate;
var
  I: integer;
  N, C, P: T3DCoordinate;
  P1, P2: TFreeSubdivisionPoint;
begin
  Result:=ZERO;
  C:=ZERO;
  //calculate center of the face
  for I:=1 to NumberOfPoints do
  begin
    P:=Point[I - 1].Coordinate;
    C.X:=C.X + P.X;
    C.Y:=C.Y + P.Y;
    C.Z:=C.Z + P.Z;
  end;
  C.X:=C.X / NumberOfPoints;
  C.Y:=C.Y / NumberOfPoints;
  C.Z:=C.Z / NumberOfPoints;
  // calculate normal
  P1:=Point[NumberOfPoints - 1];
  for I:=1 to NumberOfPoints do
  begin
    P2:=Point[I - 1];
    N:=UnifiedNormal(C, P1.Coordinate, P2.Coordinate);
    Result.X:=Result.X + N.X;
    Result.Y:=Result.Y + N.Y;
    Result.Z:=Result.Z + N.Z;
    P1:=P2;
  end;
  Result:=Normalize(Result);
end;

function TFreeSubdivisionFace.FGetNumberOfPoints;
begin Result:=FPoints.Count; end;

function TFreeSubdivisionFace.FGetPoint(Index: integer): TFreeSubdivisionPoint;
begin Result:=FPoints[Index]; end;

procedure TFreeSubdivisionFace.AddPoint(Point: TFreeSubdivisionPoint);
begin FPoints.Add(Point); Point.AddFace(self);
end;

function TFreeSubdivisionFace.CalculateFaceCenterPoint: TFreeSubdivisionPoint;
var
  I: integer;
  P: T3DCoordinate;
  Centre: T3DCoordinate;
begin
  Result:=nil;
  Centre:=ZERO;
  if (FPoints.Count > 3) or (Surface.FSubdivisionMode = fmCatmullClark) then
  begin
    if FPoints.Count > 0 then
    begin
      for I:=1 to FPoints.Count do
      begin
        P:=Point[I - 1].FCoordinate;
        Centre.X:=Centre.X + P.X;
        Centre.Y:=Centre.Y + P.Y;
        Centre.Z:=Centre.Z + P.Z;
      end;
      Centre.X:=Centre.X / FPoints.Count;
      Centre.Y:=Centre.Y / FPoints.Count;
      Centre.Z:=Centre.Z / FPoints.Count;
    end;
    Result:=TFreeSubdivisionPoint.Create(Surface);
    Result.FCoordinate:=Centre;
  end
  else if FPoints.Count = 3 then begin Result:=nil; end;
//if FPoints.Count < 3 then raise Exception.Create('TFreeSubdivisionFace points count < 3');
end;

function TFreeSubdivisionFace.CheckIntegrity: boolean;
var  I, J: integer;
  point: TFreeSubdivisionPoint;
begin
  result:=true;

  if FPoints = nil then
  begin
//  logger.Error(Format('TFreeSubdivisionFace.CheckIntegrity: FPoints = nil',[]));
    result:=false;
    exit;
  end;

  if FPoints.Count < 1 then
  begin
//  logger.Error(Format('TFreeSubdivisionFace.CheckIntegrity: FPoints empty',[]));
    result:=false;
    exit;
  end;

  for I:=0 to FPoints.Count-1 do
    if FPoints[i] <> nil then
    begin
      Point:=FPoints[i];
      if Point.FFaces.IndexOf(Self) = -1 then
      begin
//      logger.Error(Format('TFreeSubdivisionFace.CheckIntegrity: not in Point[%d]',[I]));
        result:=false;
      end;
      result:=result and Point.CheckIntegrity;
    end
  else
  begin
//  logger.Error(Format('TFreeSubdivisionFace.CheckIntegrity: Edge.NumberOfFaces = 0',[I]));
    result:=false;
  end;

end;

procedure TFreeSubdivisionFace.Clear;
begin
  FPoints.Clear;
end;{TFreeSubdivisionFace.Clear}

constructor TFreeSubdivisionFace.Create(Owner: TFreeSubdivisionSurface);
begin
  inherited Create(Owner);
  FPoints:=TFasterListTFreeSubdivisionPoint.Create(true,false);
  Clear;
end;{TFreeSubdivisionFace.Create}

procedure TFreeSubdivisionFace.Delete;
var
  I: integer;
  Index: integer;
  Edge: TFreesubdivisionEdge;
  P1, P2: TFreeSubdivisionPoint;
begin
//logger.IncreaseIndent;
//logger.Debug(format('TFreeSubdivisionFace[%d].Delete',[self.FID]));
  Unreference;
  Surface.Built:=False;
  Clear;
  Free;
  //Destroy;
  //DelayedDestroyList.Add(Self);
//logger.DecreaseIndent;
end;{TFreeSubdivisionFace.Delete}

procedure TFreeSubdivisionFace.Unreference;
var i,j: integer; E:TFreeSubdivisionEdge; P:TFreeSubdivisionPoint;
begin
  if not IsUnreferenceEnabled then exit;
  if InUnreference then exit; // speed up
  InUnreference:=true;
//logger.IncreaseIndent;
//logger.Debug(format('TFreeSubdivisionFace[%d].Unreference',[self.FID]));
  {if FID=99
   then FID:=99;
  if FPoints = nil then // debug
     FID:=FID;}

  if FPoints <> nil then
  for i:=0 to FPoints.Count-1 do
    begin
    P:=FPoints[i];
    P.UnreferenceFace(Self);
    {for j:=0 to FPoints[i].FEdges.Count-1 do
      begin
      E:=FPoints[i].FEdges[j];
      if (E<>nil)
        and ((E is TFreeSubdivisionEdge)or(E is TFreeSubdivisionControlEdge) )
        and (E.FFaces <> nil) then
         E.FFaces.DeleteItem(Self);
      end;}
    end;
  if FSurface <> nil then FSurface.UnreferenceFace(Self);
  InUnreference:=false;
//logger.DecreaseIndent;
end;

destructor TFreeSubdivisionFace.Destroy;
begin
  //logger.Debug(format('TFreeSubdivisionFace.Destroy[%d]',[self.FID]));
  //Unreference;
  Clear;
  FreeAndNil(FPoints);
  inherited Destroy;
end;{TFreeSubdivisionFace.Destroy}

// Inverts the point ordering of the face
procedure TFreeSubdivisionFace.FlipNormal;
var
  Mid: integer;
  I: integer;
begin
  Mid:=(FPoints.Count div 2) - 1;
  for I:=0 to Mid do
  begin
    FPoints.Exchange(I, FPoints.Count - I - 1);
  end;
end;{TFreeSubdivisionFace.FlipNormal}

function TFreeSubdivisionFace.IndexOfPoint(P: TFreeSubdivisionPoint): integer;
begin
  Result:=FPoints.IndexOf(P);
end;{TFreeSubdivisionFace.IndexOfPoint}
{
procedure TFreeSubdivisionFace.PrintDebug;
var i:integer;
begin
  inherited;
//Logger.Debug(Format(' SubdivisionLevel:%d',[SubdivisionLevel]));
//for i:=0 to FPoints.Count-1 do Logger.Debug(Format(' point[%d]:%d %s',[i,FPoints[i].Id, FPoints[i].Name]));
end;
}

procedure TFreeSubdivisionFace.Subdivide(
    aOwner: TFreeSubdivisionSurface;
    aIsControlFace: boolean; // All new edges will be Control Descendand
    aRefVertices:TFasterListTFreeSubdivisionPoint;
    aRefEdges:TFasterListTFreeSubdivisionEdge;
    aRefFaces:TFasterListTFreeSubdivisionFace;
    aInteriorEdges:TFasterListTFreeSubdivisionEdge; // Output. Here TFreeSubdivisionEdge edges will be added.
    aControlDescendandEdges:TFasterListTFreeSubdivisionEdge; // Output. Here boundary edges will be added.
    aNewFaces: TFasterListTFreeSubdivisionFace); // Output. Here new faces will be added.
var
  P1,P2, P: TFreeSubdivisionPoint;
  I, TmpIndex: integer;
  NewFace: TFreeSubdivisionFace;
  IndexPE, IndexCE, Index0, Index1, Index2, Index3, J, X: integer;
  Pts: array[0..3] of TFreeSubdivisionPoint;
  PrevEdge: TFreeSubdivisionEdge;
  CurrEdge: TFreeSubdivisionEdge;
  Edge: TFreeSubdivisionEdge;
  PrevEdgePoint, CurrEdgePoint, P2Point, NewLocation: TFreeSubdivisionPoint;

  procedure EdgeCheck(P1,P2:TFreeSubdivisionPoint; Crease, IsControledge:Boolean;
            Curve:TFreeSubdivisionControlCurve);
  var NewEdge:TFreeSubdivisionEdge;
  begin
     NewEdge:=nil;
     if (P1<>nil) and (P2<>nil) then
     begin
       // MM: we create regular edge that can inherit just some properties of Control Edge, like Curve
       // It is sort of Control Edge child called Control Descendant Edge.
       // But there are no real ControlEdges in subdivided faces
       NewEdge:=aOwner.EdgeExists(P1,P2);
       if NewEdge=nil then
        begin
          NewEdge:=TFreeSubdivisionEdge.Create(aOwner);
          NewEdge.FStartpoint:=P1;
          NewEdge.FEndpoint:=P2;
          NewEdge.FFaces.Capacity:=2;
          NewEdge.FStartpoint.FEdges.Add(NewEdge);
          NewEdge.FEndpoint.FEdges.Add(NewEdge);
          NewEdge.FControlEdge:=IsControlEdge;
          NewEdge.FCrease:=Crease;
          if IsControlEdge
            then aControlDescendandEdges.Add(NewEdge)
            else aInteriorEdges.Add(NewEdge);

        end
        else
        begin
          // just in case one of points is not associated with the edge
          if P1.FEdges.IndexOf(NewEdge) = -1 then
            P1.FEdges.Add(NewEdge);
          if P2.FEdges.IndexOf(NewEdge) = -1 then
            P2.FEdges.Add(NewEdge);
          if NewEdge.FStartpoint.FEdges.IndexOf(NewEdge) = -1 then
            NewEdge.FStartpoint.FEdges.Add(NewEdge);
          if NewEdge.FEndpoint.FEdges.IndexOf(NewEdge) = -1 then
            NewEdge.FEndpoint.FEdges.Add(NewEdge);

          if IsControlEdge
            then aControlDescendandEdges.Add(NewEdge)
            else aInteriorEdges.Add(NewEdge);
        end;
        if IsControlEdge then
         begin
            NewEdge.FCurve:=Curve;
         end;
        NewEdge.FFaces.Add(NewFace);

     end else
     begin
        Showmessage('Error in TFreeSubdivisionFace.Subdivide');
     end;
  end; //EdgeCheck

begin
  if (NumberOfPoints <> 3) or (aOwner.FSubdivisionMode = fmCatmullClark) then
  begin
    for I:=1 to FPoints.Count do
    begin
      P2:=FPoints[I - 1];
      IndexPE:=(I - 2 + FPoints.Count) mod FPoints.Count;
      P1:=FPoints[IndexPE];
      PrevEdge:=aOwner.EdgeExists(P2, P1);
//    if PrevEdge = nil
//      then raise Exception.Create('Subdivision error. Previous edge not found');

      IndexCE:=(I + FPoints.Count) mod FPoints.Count;
      P:=FPoints[IndexCE];
      CurrEdge:=aOwner.EdgeExists(P2, FPoints[IndexCE]);
//    if CurrEdge = nil
//      then raise Exception.Create('Subdivision error. Current edge not found');

      Index0:=(I - 1) mod 4;
      TmpIndex:=aRefVertices.SortedIndexOf(P2);
      Pts[Index0]:=aRefVertices.Objects[TmpIndex];// P2.FNewLocation;
//    if Pts[Index0] = nil
//      then raise Exception.Create('Subdivision error. Point 0 not found');
      P2Point:=Pts[Index0];

      Index1:=(Index0 + 1) mod 4;
      TmpIndex:=aRefEdges.SortedIndexOf(CurrEdge);
      Pts[index1]:=aRefEdges.Objects[TmpIndex];//CurrEdge.FNewLocation;
//    if Pts[Index1] = nil
//      then raise Exception.Create('Subdivision error. Point 1 not found');
      CurrEdgePoint:=Pts[index1];

      Index2:=(Index1 + 1) mod 4;
      TmpIndex:=aRefFaces.SortedIndexOf(self);
      Pts[index2]:=aRefFaces.Objects[TmpIndex];//self.FNewLocation;
//    if Pts[Index2] = nil
//      then raise Exception.Create('Subdivision error. Point 2 (face center) not found');
      NewLocation:=Pts[index2];

      Index3:=(Index2 + 1) mod 4;
      TmpIndex:=aRefEdges.SortedIndexOf(PrevEdge);
      Pts[index3]:=aRefEdges.Objects[TmpIndex];// PrevEdge.FNewLocation;
//    if Pts[Index3] = nil
//      then raise Exception.Create('Subdivision error. Point 3 not found');
      PrevEdgePoint:=Pts[index3];

      // add the new face
      NewFace:=TFreeSubdivisionFace.Create(aOwner);
      NewFace.SubdivisionLevel:=self.SubdivisionLevel+1;
      aNewFaces.Add(NewFace);

      EdgeCheck(PrevEdgePoint,P2Point,PrevEdge.Crease,PrevEdge.FControlEdge or aIsControlFace,PrevEdge.FCurve);
      EdgeCheck(P2Point,CurrEdgePoint,CurrEdge.Crease,CurrEdge.FControlEdge or aIsControlFace,CurrEdge.FCurve);
      EdgeCheck(CurrEdgePoint,NewLocation,False,False,nil);
      EdgeCheck(PrevEdgePoint,NewLocation,False,False,nil);

      NewFace.FPoints.Capacity:=4;
      for J:=0 to 3 do
      if Pts[J] <> nil then // TEMP
        begin
          // Add new face to points
          Pts[J].FFaces.Add(NewFace);
          NewFace.FPoints.Add(Pts[J]);
        end;
//    else raise Exception.Create(format('Subdivision error. Pts[%d] is nil',[J]));
    end;
  end
  else if NumberOfPoints = 3 then
  begin
    // Special case, quadrisect triangle by connecting all three
    // edge points
    // first process the three surrounding triangles
    for I:=1 to FPoints.Count do
    begin
      P2:=FPoints[I - 1];
      IndexPE:=(I - 2 + FPoints.Count) mod FPoints.Count;
      PrevEdge:=aOwner.EdgeExists(P2, FPoints[IndexPE]);
      IndexCE:=(I + FPoints.Count) mod FPoints.Count;
      CurrEdge:=aOwner.EdgeExists(P2, FPoints[IndexCE]);

      Index0:=0;
      TmpIndex:=aRefEdges.SortedIndexOf(PrevEdge);
      Pts[Index0]:=aRefEdges.Objects[tmpindex];// PrevEdge.FNewLocation;
      Index1:=1;
      TmpIndex:=aRefVertices.SortedIndexOf(P2);
      Pts[index1]:=aRefVertices.Objects[Tmpindex];// P2.FNewLocation;
      Index2:=2;
      TmpIndex:=aRefEdges.SortedIndexOf(CurrEdge);
      Pts[index2]:=aRefEdges.Objects[Tmpindex];// CurrEdge.FNewLocation;

      // add the new face
      NewFace:=TFreeSubdivisionFace.Create(aOwner);
      NewFace.SubdivisionLevel:=self.SubdivisionLevel+1;
      aNewFaces.Add(NewFace);
      EdgeCheck(Pts[0], Pts[1], PrevEdge.Crease, PrevEdge.FControlEdge or
        aIsControlFace, PrevEdge.FCurve);
      EdgeCheck(Pts[1], Pts[2], CurrEdge.Crease, CurrEdge.FControlEdge or
        aIsControlFace, CurrEdge.FCurve);
      EdgeCheck(Pts[2], Pts[0], False, False, nil);

      NewFace.FPoints.Capacity:=3;
      for J:=1 to 3 do begin                       // Add new face to points
        Pts[J - 1].FFaces.Add(NewFace);
        NewFace.FPoints.Add(Pts[J - 1]);
        Pts[J - 1].AddFace(NewFace);
      end;
    end;
    // then process the center triangle
    for I:=1 to FPoints.Count do
    begin
      P2:=FPoints[I - 1];
      IndexPE:=(I - 2 + FPoints.Count) mod FPoints.Count;
      PrevEdge:=aOwner.EdgeExists(P2, FPoints[IndexPE]);
      TmpIndex:=aRefEdges.SortedIndexOf(PrevEdge);
      Pts[I - 1]:=aRefEdges.Objects[TmpIndex];// PrevEdge.FNewLocation;
    end;

    // add the new face
    NewFace:=TFreeSubdivisionFace.Create(aOwner);
    aNewFaces.Add(NewFace);

    EdgeCheck(Pts[0],Pts[1],False,False,nil);
    EdgeCheck(Pts[1],Pts[2],False,False,nil);
    EdgeCheck(Pts[2],Pts[0],False,False,nil);

    NewFace.FPoints.Capacity:=3;
    for J:=1 to 3 do
    begin
      // Add new face to points
      Pts[J - 1].FFaces.Add(NewFace);
      NewFace.FPoints.Add(Pts[J - 1]);
      Pts[J - 1].AddFace(NewFace);
    end;
  end;
end;{TFreeSubdivisionFace.Subdivide}

