{--------------------------------------------------------------------------------------------------}
{                                         TFreeSubdivisionEdge                                     }
{--------------------------------------------------------------------------------------------------}
function TFreeSubdivisionEdge.FGetIndex: integer;
begin
  Result:=Surface.FEdges.IndexOf(self);
  if Result = -1 then
  begin
    Result:=Surface.FControlEdges.IndexOf(self as TFreeSubdivisionControlEdge);
    if Result = -1 then
      Result:=0;
  end;
end;{TFreeSubdivisionEdge.FGetIndex}

function TFreeSubdivisionEdge.FGetIsBoundaryEdge: boolean;
begin
  Result:=False;
  if NumberOfFaces = 1 then
    Result:=(abs(StartPoint.Coordinate.Y) > 1e-4) or (abs(EndPoint.Coordinate.Y) > 1e-4);
end;{TFreeSubdivisionEdge.FGetIsBoundaryEdge}

function TFreeSubdivisionEdge.FGetFace(Index: integer): TFreeSubdivisionFace;
begin
  Result:=FFaces[Index];
end;{TFreeSubdivisionEdge.FGetFace}

function TFreeSubdivisionEdge.FGetNumberOfFaces: integer;
begin
  Result:=FFaces.Count;
end;{TFreeSubdivisionEdge.FGetNumberOfFaces}

procedure TFreeSubdivisionEdge.FSetCrease(Val: boolean);
var
  I, N, FN: integer;
  Edge: TFreeSubdivisionEdge;
begin
  if NumberOfFaces <= 1 then
    Val:=True;  // Boundary and freestanding edges must ALWAYS be crease edges
  if (Val <> FCrease) then
  begin
    FCrease:=Val;
    N:=0;
    for I:=1 to FStartPoint.FEdges.Count do
    begin
      Edge:=FStartPoint.FEdges[I - 1];
      if Edge.Crease then
        Inc(N);
    end;
    if FStartpoint.VertexType = svCorner then
    begin
      if (FStartPoint.FFaces.Count > 1) and (N = 2) then
        FStartpoint.VertexType:=svCrease;
    end
    else
    begin
      FN:=FStartPoint.FFaces.Count;
      if N = 0 then
        FStartpoint.VertexType:=svRegular
      else
      if N = 1 then
        FStartpoint.VertexType:=svDart
      else
      if N = 2 then
        FStartpoint.VertexType:=svCrease
      else
      if N > 2 then
        FStartpoint.VertexType:=svCorner;
    end;

    N:=0;
    for I:=1 to FEndPoint.FEdges.Count do
    begin
      Edge:=FEndPoint.FEdges[I - 1];
      if Edge.Crease then
        Inc(N);
    end;
    if FEndpoint.VertexType = svCorner then
    begin
      if (FEndPoint.NumberOfFaces > 1) and (N = 2) then
        FEndpoint.VertexType:=svCrease;
    end
    else
    begin
      if N = 0 then
        FEndpoint.VertexType:=svRegular
      else
      if N = 1 then
        FEndpoint.VertexType:=svDart
      else
      if N = 2 then
        FEndpoint.VertexType:=svCrease
      else
      if N > 2 then
        FEndpoint.VertexType:=svCorner;
    end;

    FStartPoint.FSurface.Built:=False;
  end;
end;{TFreesubdivisionEdge.FSetCrease}

function TFreeSubdivisionEdge.FGetPreviousEdge: TFreeSubdivisionEdge;
var
  P: TFreeSubdivisionPoint;
  Edge: TFreeSubdivisionEdge;
  I, J, Index: integer;
  Sharesface: boolean;
begin
  P:=Startpoint;
  Result:=nil;
  if (P.RegularPoint) and (P.VertexType <> svCorner) then
  begin
    // Find previous edge
    for I:=1 to P.NumberOfEdges do
      if P.Edge[I - 1] <> self then
      begin
        Edge:=P.Edge[I - 1];
        if Edge.Crease = self.Crease then
        begin
          SharesFace:=False;
          for J:=1 to self.NumberOfFaces do
          begin
            Index:=Edge.FFaces.IndexOf(self.Face[J - 1]);
            if Index <> -1 then
            begin
              SharesFace:=True;
              Break;
            end;
          end;
          if not SharesFace then
          begin
            if Edge.StartPoint = self.StartPoint then
              Edge.SwapData;
            Result:=Edge;
            exit;
          end;
        end;
      end;
  end;
end;{TFreesubdivisionEdge.FGetPreviousEdge}

function TFreeSubdivisionEdge.FGetNextEdge: TFreeSubdivisionEdge;
var
  P: TFreeSubdivisionPoint;
  Edge: TFreeSubdivisionEdge;
  I, J, Index: integer;
  Sharesface: boolean;
begin
  P:=Endpoint;
  Result:=nil;
  if (P.RegularPoint) and (P.VertexType <> svCorner) then
  begin
    // Find Next edge
    for I:=1 to P.NumberOfEdges do
      if P.Edge[I - 1] <> self then
      begin
        Edge:=P.Edge[I - 1];
        if Edge.Crease = self.Crease then
        begin
          SharesFace:=False;
          for J:=1 to self.NumberOfFaces do
          begin
            Index:=Edge.FFaces.IndexOf(self.Face[J - 1]);
            if Index <> -1 then
            begin
              SharesFace:=True;
              Break;
            end;
          end;
          if not SharesFace then
          begin
            if Edge.StartPoint = self.StartPoint then
              Edge.SwapData;
            Result:=Edge;
            exit;
          end;
        end;
      end;
  end;
end;{TFreesubdivisionEdge.FGetNextEdge}

procedure TFreeSubdivisionEdge.AddFace(Face: TFreeSubdivisionFace);
begin
  if FFaces.IndexOf(Face) = -1 then
  begin
    FFaces.Add(Face);
  end;
end;{TFreeSubdivisionEdge.AddFace}

procedure TFreeSubdivisionEdge.Assign(Edge: TFreeSubdivisionEdge);
begin
  FStartpoint:= edge.FStartpoint;
  FEndpoint:= edge.FEndpoint;
  FFaces:= edge.FFaces;
  FCrease:= edge.FCrease;
  FControlEdge:= edge.FControlEdge;
  FCurve:= edge.FCurve;
end;{TFreeSubdivisionEdge.Assign}

function TFreeSubdivisionEdge.CalculateEdgeCenterPoint: TFreeSubdivisionPoint;
var
  Point: T3DCoordinate;
  SP, EP: TFreeSubdivisionPoint;
begin
  SP:=FStartpoint;
  EP:=FEndpoint;
  Point.X:=0.5 * (SP.FCoordinate.X + EP.FCoordinate.X);
  Point.Y:=0.5 * (SP.FCoordinate.Y + EP.FCoordinate.Y);
  Point.Z:=0.5 * (SP.FCoordinate.Z + EP.FCoordinate.Z);
  Result:=TFreeSubdivisionPoint.Create(FStartPoint.Surface);
  Result.FCoordinate:=Point;
  if FCrease then
    Result.FVertexType:=svCrease;
  if FCurve <> nil then
  begin
    FCurve.InsertEdgePoint(FStartPoint, FEndPoint, Result);
  end;
end;{TFreeSubdivisionEdge.CalculateEdgePoint}

procedure TFreeSubdivisionEdge.Clear;
begin
  FStartpoint:=nil;
  FEndpoint:=nil;
  FCurve:=nil;
  if assigned(FFaces) then FFaces.Clear;
  FCrease:=False;
  FControlEdge:=False;
end;{TFreeSubdivisionEdge.Clear}

procedure TFreeSubdivisionEdge.SwapData;
var
  Tmp: TFreeSubdivisionPoint;
begin
  Tmp:=FStartpoint;
  FStartpoint:=FEndpoint;
  FEndpoint:=Tmp;
end;{TFreeSubdivisionEdge.SwapData}

function TFreeSubdivisionEdge.CheckIntegrity: boolean;
var i:integer;
begin
  result:=true;
  if FStartpoint = nil then
  begin
//  logger.Error(Format('TFreeSubdivisionEdge.CheckIntegrity: FStartpoint = nil',[]));
    result:=false;
  end
  else
  begin
    if FStartpoint.FEdges.IndexOf(Self) = -1 then
      begin
//      logger.Error(Format('TFreeSubdivisionEdge.CheckIntegrity: Self not in Startpoint.Edges',[]));
        result:=false;
      end;
    FStartpoint.CheckIntegrity;
  end;

  if FEndpoint = nil then
  begin
//  logger.Error(Format('TFreeSubdivisionEdge.CheckIntegrity: FEndpoint = nil',[]));
    result:=false;
  end
  else
    begin
      if FEndpoint.FEdges.IndexOf(Self) = -1 then
        begin
//        logger.Error(Format('TFreeSubdivisionEdge.CheckIntegrity: Self not in Endpoint.Edges',[]));
          result:=false;
        end;
      FEndpoint.CheckIntegrity;
    end;

  if FCurve <> nil then result:=result and FCurve.CheckIntegrity;

//if not result then self.PrintDebug;
end;

constructor TFreeSubdivisionEdge.Create(Owner: TFreeSubdivisionSurface);
begin
  inherited Create(Owner);
  FFaces:=TFasterListTFreeSubdivisionFace.Create(false,false);
  Clear;
end;{TFreeSubdivisionEdge.Create}
{
procedure TFreeSubdivisionEdge.PrintDebug;
var i:integer;
begin
  inherited;
//Logger.Debug(Format(' Crease:%s ControlEdge:%s',[boolTostr(FCrease), boolTostr(FControlEdge)]));
  if self.StartPoint <> nil then
//   Logger.Debug(Format(' StartPoint:%d %s',[self.StartPoint.Id, self.StartPoint.Name]));
  if self.EndPoint <> nil then
//   Logger.Debug(Format(' EndPoint:%d %s',[self.EndPoint.Id, self.EndPoint.Name]));
  for i:=0 to FFaces.Count-1 do
//   Logger.Debug(Format(' face[%d]:%d',[i,FFaces[i].Id]));
//if Curve<>nil then Logger.Debug(Format(' curve:%d',[Curve.Id]));
end;
}
procedure TFreeSubdivisionEdge.SetCurve(AValue: TFreeSubdivisionControlCurve);
begin
  if FCurve=AValue then Exit;
  FCurve:=AValue;
end;

procedure TFreeSubdivisionEdge.SetStartPoint(aPoint: TFreeSubdivisionPoint);
var i: integer;
begin
  if aPoint = FStartPoint then exit;
  if FCurve<>nil then
    begin
    i:=FCurve.ControlPoints.Indexof(FStartPoint as TFreesubdivisionControlPoint);
    if i > -1 then
      if aPoint <> nil then
         FCurve.ReplaceVertexPoint(FStartPoint, aPoint as TFreesubdivisionPoint)
      else
         FCurve.DeletePoint(FStartPoint as TFreesubdivisionControlPoint);
    FCurve.Built:=false;
    end;
  FStartPoint:=aPoint;
end;

procedure TFreeSubdivisionEdge.SetEndPoint(aPoint: TFreeSubdivisionPoint);
var i: integer;
begin
  if aPoint = FStartPoint then exit;
  if FCurve<>nil then
    begin
    i:=FCurve.ControlPoints.Indexof(FEndPoint as TFreesubdivisionControlPoint);
    if i > -1 then
      if aPoint <> nil then
         FCurve.ReplaceVertexPoint(FEndPoint, aPoint)
      else
         FCurve.DeletePoint(FStartPoint as TFreesubdivisionControlPoint);
    FCurve.Built:=false;
    end;
  FEndPoint:=aPoint;
end;

procedure TFreeSubdivisionEdge.UnreferenceFace(Face: TFreeSubdivisionFace);
var
  Index: integer;
begin
//logger.IncreaseIndent;
//logger.Debug(format('TFreeSubdivisionEdge[%d].UnreferenceFace',[self.FID]));

  FFaces.DeleteItem(Face);
  //Crease:=(FFaces.Count = 1);
  if FFaces.Count = 1 then
    FCrease:=True
  else
  if FFaces.Count = 0 then
    FCrease:=False;

  {Index:=FFaces.IndexOf(Face);
  if Index > -1 then
  begin
    FFaces.Delete(Index);
    if FFaces.Count = 1 then
      Crease:=True
    else
    if FFaces.Count = 0 then
      Crease:=False;
  end;}
//logger.DecreaseIndent;
end;{TFreeSubdivisionEdge.DeleteFace}

procedure TFreeSubdivisionEdge.Delete;
var
  I: integer;
  Index: integer;
  Face: TFreeSubdivisionFace;
  CFace: TFreeSubdivisionControlFace;
  Point: TFreeSubdivisionControlPoint;
begin
//logger.IncreaseIndent;
//logger.Debug(format('TFreeSubdivisionEdge[%d].Delete',[self.FId]));

  Surface.FEdges.DeleteItem(Self);

  begin
    for I:=FFaces.Count-1 downto 0 do
    begin
      Face:=FFaces[I];
      FFaces.Delete(I);
      Face.Delete;
    end;

    // Remove endpoint from startpoint neighbours
    if EndPoint <> nil then
    begin
      EndPoint.UnreferenceEdge(self);
      if EndPoint.NumberOfEdges = 0 then
      begin
        Point:=Endpoint as TFreeSubdivisionControlPoint;
        Point.Delete;
      end;
      EndPoint:=nil;
    end;

    // Remove startpoint from endpoint neighbours
    if StartPoint <> nil then
    begin
      StartPoint.UnreferenceEdge(self);
      if StartPoint.NumberOfEdges = 0 then
      begin
        Point:=StartPoint as TFreeSubdivisionControlPoint;
        Point.Delete;
      end;
      StartPoint:=nil;
    end;
    //Destroy;
  end;
  Unreference;
  Destroy;
//logger.DecreaseIndent;
end;{TFreesubdivisionEdge.Delete}

procedure TFreeSubdivisionEdge.Unreference;
var i,j: integer; F:TFreeSubdivisionFace;
begin
  if not IsUnreferenceEnabled then exit;
  if InUnreference then exit; // speed up
  InUnreference:=true;

  if FStartPoint<>nil then
     FStartPoint.FEdges.DeleteItem(Self);
  if FEndPoint<>nil then
     FEndPoint.FEdges.DeleteItem(Self);

  if FFaces <> nil then
  for i:=0 to FFaces.Count-1 do
    begin
    F:=FFaces[i];
    if F = nil then continue;
    if not(F is TFreeSubdivisionFace)
       then continue;
    if (F is TFreeSubdivisionControlFace)
       and ((F as TFreeSubdivisionControlFace).FEdges <> nil) then
     (F as TFreeSubdivisionControlFace).FEdges.DeleteItem(Self);
    if (F.FPoints = nil) or not(F.FPoints is TFasterListTFreeSubdivisionPoint) then continue;
    for j:=0 to F.FPoints.Count-1 do
      if F.FPoints[j].FEdges <> nil then
          F.FPoints[j].FEdges.DeleteItem(Self);
    end;

  { // edges are not memorized in Curve
  if FCurve <> nil then
     FCurve.DeleteEdge(Self as TFreeSubdivisionControlEdge);
  }
  if FSurface <> nil then FSurface.UnreferenceEdge(Self);

  InUnreference:=false;
end;

destructor TFreeSubdivisionEdge.Destroy;
begin
  //logger.IncreaseIndent;
  //logger.Debug(format('TFreeSubdivisionEdge[%d].Destroy',[self.FID]));
  if self = nil then
    exit;
  //Unreference;
  Clear;
  FreeAndNil(FFaces);
  inherited Destroy;
  //logger.DecreaseIndent;
end;{TFreeSubdivisionEdge.Destroy}

function TFreeSubdivisionEdge.DistanceToCursor(X, Y: integer;
  var P: T3DCoordinate; Viewport: TFreeViewport): integer;
var
  Pt, Pt1, Pt2: TPoint;
  P1, P2, M: T3DCoordinate;
  Param: TFloatType;
  Tmp: integer;
begin
  // Check if cursor position lies within the boundaries
  P:=ZERO;
  Result:=10000;
  if Viewport.ViewType = fvBodyplan then
  begin
    P1:=StartPoint.FCoordinate;
    P2:=FEndPoint.FCoordinate;
    if ((P1.X < Surface.SplitSectionLocation) and (P2.X > Surface.SplitSectionLocation)) or
      ((P1.X > Surface.SplitSectionLocation) and (P2.X < Surface.SplitSectionLocation)) then
    begin
      if P2.X - P1.X <> 0 then
        M:=Interpolate(P1, P2, (Surface.SplitSectionLocation - P1.X) / (P2.X - P1.X))
      else
        M:=MidPoint(P1, P2);
      if P1.X <= Surface.SplitSectionLocation then
      begin
        // P2 lies on port
        Pt1:=Viewport.Project(P2);
        Pt2:=Viewport.Project(M);
        Tmp:=Round(DistanceToLine(Pt1, Pt2, X, Y, Param));
        if Tmp < Result then
        begin
          Result:=Tmp;
          P:=Interpolate(P2, M, Param);
        end;
        // P1 lies on starboard
        P1.Y:=-P1.Y;
        M.Y:=-M.Y;
        Pt1:=Viewport.Project(P1);
        Pt2:=Viewport.Project(M);
        Tmp:=Round(DistanceToLine(Pt1, Pt2, X, Y, Param));
        if Tmp < Result then
        begin
          Result:=Tmp;
          P:=Interpolate(P1, M, Param);
        end;
      end
      else
      begin
        // P1 lies on port
        Pt1:=Viewport.Project(P1);
        Pt2:=Viewport.Project(M);
        Tmp:=Round(DistanceToLine(Pt1, Pt2, X, Y, Param));
        if Tmp < Result then
        begin
          Result:=Tmp;
          P:=Interpolate(P1, M, Param);
        end;
        // P2 lies on starboard
        P2.Y:=-P2.Y;
        M.Y:=-M.Y;
        Pt1:=Viewport.Project(P2);
        Pt2:=Viewport.Project(M);
        Tmp:=Round(DistanceToLine(Pt1, Pt2, X, Y, Param));
        if Tmp < Result then
        begin
          Result:=Tmp;
          P:=Interpolate(P2, M, Param);
        end;
      end;
    end
    else
    begin
      if P1.X <= Surface.SplitSectionLocation then
        P1.Y:=-P1.Y;
      if P2.X <= Surface.SplitSectionLocation then
        P2.Y:=-P2.Y;
      Pt1:=Viewport.Project(P1);
      Pt2:=Viewport.Project(P2);
      Tmp:=Round(DistanceToLine(Pt1, Pt2, X, Y, Param));
      if Tmp < Result then
      begin
        Result:=Tmp;
        P:=Interpolate(P1, P2, Param);
      end;
    end;
  end
  else
  begin
    Pt.X:=X;
    Pt.Y:=Y;
    Pt1:=Viewport.Project(StartPoint.Coordinate);
    Pt2:=Viewport.Project(EndPoint.Coordinate);
    Result:=Round(DistanceToLine(Pt1, Pt2, X, Y, Param));
    P:=Interpolate(StartPoint.Coordinate, EndPoint.Coordinate, Param);
  end;
end;{TFreeSubdivisionEdge.DistanceToCursor}

procedure TFreeSubdivisionEdge.Draw(DrawMirror: boolean; Viewport: TFreeViewport);
var
  P1, P2, M: T3DCoordinate;
  Pt1, Pt2: TPoint;
begin
  P1:=StartPoint.FCoordinate;
  P2:=EndPoint.FCoordinate;

  if (DrawMirror = False) and (Viewport.ViewType = fvBodyplan) then
  begin
    if ((P1.X < Surface.SplitSectionLocation) and (P2.X > Surface.SplitSectionLocation)) or
      ((P1.X > Surface.SplitSectionLocation) and (P2.X < Surface.SplitSectionLocation)) then
    begin
      if abs(P2.X - P1.X) > 1e-6 then
        M:=Interpolate(P1, P2, (Surface.SplitSectionLocation - P1.X) / (P2.X - P1.X))
      else
        M:=MidPoint(P1, P2);
      if P1.X <= Surface.SplitSectionLocation then
      begin
        // P2 lies on port
        Pt1:=Viewport.Project(P2);
        Pt2:=Viewport.Project(M);
        Viewport.MoveTo(Pt1.X, Pt1.Y);
        Viewport.LineTo(Pt2.X, Pt2.Y);
        // P1 lies on starboard
        P1.Y:=-P1.Y;
        M.Y:=-M.Y;
        Pt1:=Viewport.Project(P1);
        Pt2:=Viewport.Project(M);
        Viewport.MoveTo(Pt1.X, Pt1.Y);
        Viewport.LineTo(Pt2.X, Pt2.Y);
      end
      else
      begin                                     // P1 lies on port
        Pt1:=Viewport.Project(P1);
        Pt2:=Viewport.Project(M);
        Viewport.MoveTo(Pt1.X, Pt1.Y);
        Viewport.LineTo(Pt2.X, Pt2.Y);          // P2 lies on starboard
        P2.Y:=-P2.Y;
        M.Y:=-M.Y;
        Pt1:=Viewport.Project(P2);
        Pt2:=Viewport.Project(M);
        Viewport.MoveTo(Pt1.X, Pt1.Y);
        Viewport.LineTo(Pt2.X, Pt2.Y);
      end;
    end
    else
    begin
      if P1.X <= Surface.SplitSectionLocation then P1.Y:=-P1.Y;
      if P2.X <= Surface.SplitSectionLocation then P2.Y:=-P2.Y;
      Pt1:=Viewport.Project(P1);
      Pt2:=Viewport.Project(P2);
      Viewport.MoveTo(Pt1.X, Pt1.Y);
      Viewport.LineTo(Pt2.X, Pt2.Y);
    end;

  end
  else
  begin
    Pt1:=Viewport.Project(P1);
    Pt2:=Viewport.Project(P2);
    Viewport.MoveTo(Pt1.X, Pt1.Y);
    Viewport.LineTo(Pt2.X, Pt2.Y);
    if DrawMirror then
    begin
      P1.Y:=-P1.Y;
      P2.Y:=-P2.Y;
      Pt1:=Viewport.Project(P1);
      Pt2:=Viewport.Project(P2);
      Viewport.MoveTo(Pt1.X, Pt1.Y);
      Viewport.LineTo(Pt2.X, Pt2.Y);
    end;
  end;
end;

