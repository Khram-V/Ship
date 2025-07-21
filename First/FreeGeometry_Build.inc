//
//        TFreeSubdivisionSurface
//
procedure TFreeSubdivisionSurface.Initialize
        ( PointStartIndex,EdgeStartIndex,FaceStartIndex: Integer );
var I: Integer; Edge:TFreeSubdivisionEdge;
begin                                              // Identify all border edges
   if EdgeStartIndex<=NumberOfControlEdges then
   for I:=EdgeStartIndex to NumberOfControlEdges do begin
      Edge:=ControlEdge[I-1];
      if Edge.NumberOfFaces=0 then begin
         Edge.StartPoint.DeleteEdge(Edge);
         Edge.EndPoint.DeleteEdge(Edge);
         Edge.Crease:=false;
      end else if Edge.NumberOfFaces<>2 then Edge.Crease:=true;
   end;
 //for I:=1 to NumberOfControlEdges do if ControlEdge[I-1].NumberOfFaces<>2 then ControlEdge[I-1].Crease:=True;
   for I:=PointStartIndex to NumberOfControlPoints do 
      if ControlPoint[I-1].NumberOfFaces<2 then 
         ControlPoint[I-1].VertexType:=svCorner;
   FInitialized:=True;
end;
procedure TFreeSubdivisionSurface.Rebuild; var I: Integer;
begin
   if not FInitialized then Initialize( 1,1,1 );
   FBuild:=True;
   while (FCurrentSubdivisionLevel<FDesiredSubdivisionlevel)
     and (FControlFaces.Count>0) do Subdivide;
   for I:=1 to NumberOfControlfaces do begin ControlFace[I-1].CalcExtents;
      if I=1 then begin
         FMin:=Controlface[I-1].FMin;
         FMax:=Controlface[I-1].FMax;
      end else begin
         MinMax(Controlface[I-1].FMin,FMin,FMax);
         MinMax(Controlface[I-1].FMax,FMin,FMax);
      end;
   end;
end;

procedure TFreeSubdivisionSurface.SubDivide;
{ type TQuadData = record
          P:array[1..4] of TFreeSubdivisionPoint;
          Crease1,Crease2:Boolean;
       end; }
var I,J,Number: Integer;
    CtrlFace  : TFreeSubdivisionControlFace;
    Edge      : TFreeSubdivisionEdge;
    Point     : TFreeSubdivisionPoint;
//  NewPointList: TFasterList;
    NewEdgeList,VertexPoints,FacePoints,EdgePoints: TFasterList;
    TmpPoints : array of T3DVector;
begin
   if NumberOfControlFaces<1 then exit;
   inc( FCurrentSubdivisionLevel,1 );
// NewPointList:=TFasterList.Create;
// NewPointlist.Capacity:=2*NumberOfPoints;
   NewEdgeList:=TFasterList.Create;
   I:=Round( Power( 2,FCurrentSubdivisionLevel ) );
   NewEdgelist.Capacity:=NumberOfControlEdges*I;
   Number:=NumberOfFaces;
   FacePoints:=TFasterList.Create;   // Create the list with new facepoints and a reference to the original face
   EdgePoints:=TFasterList.Create;   // Create the list with new edgepoints and a reference to the original edge
   VertexPoints:=TFasterList.Create; // Create the list with new vertexpoints and a reference to the original vertex
   if Number=0 then begin
      FacePoints.Capacity:=NumberOfControlFaces;
      for I:=1 to NumberOfControlFaces do begin
         CtrlFace:=ControlFace[I-1];
         FacePoints.AddObject(CtrlFace,CtrlFace.CalculateFacePoint);
      end;
   end else begin
      FacePoints.Capacity:=4*NumberOfControlFaces;
      for I:=1 to NumberOfControlFaces do begin
         CtrlFace:=ControlFace[I-1];
         for J:=1 to CtrlFace.Childcount do
           FacePoints.AddObject(CtrlFace.Child[J-1],CtrlFace.Child[J-1].CalculateFacePoint);
         for J:=1 to CtrlFace.Edgecount do
           EdgePoints.AddObject(CtrlFace.Edge[J-1],CtrlFace.Edge[J-1].CalculateEdgePoint);
      end;
   end;                                           // Calculate other edgepoints
   EdgePoints.Capacity:=EdgePoints.Count+NumberOfEdges;
   for I:=1 to NumberOfEdges do
     EdgePoints.AddObject( self.Edge[I-1],self.Edge[I-1].CalculateEdgePoint );
                                                      // Calculate vertexpoints
   VertexPoints.Capacity:=VertexPoints.Count+NumberOfPoints;
   for I:=1 to NumberOfpoints do
     VertexPoints.AddObject
                ( Self.Point[I-1],Self.Point[I-1].CalculateVertexPoint );
   VertexPoints.Sort;          // Sort the new points for faster acces
   EdgePoints.Sort;           // finally create the refined mesh over the newly
   FacePoints.Sort;          //  create vertexpoints, edgepoints and facepoints
   for I:=1 to NumberOfControlFaces do begin
      CtrlFace:=ControlFace[I-1];
      CtrlFace.Subdivide(Self,True,VertexPoints,EdgePoints,FacePoints,nil,NewEdgeList,nil);
   end;
   for I:=1 to FEdges.Count do begin                        // cleanup old mesh
      Edge:=FEdges[I-1];
      Edge.Destroy;
   end;
   FEdges.Destroy;
   FEdges:=NewEdgeList;
   for I:=1 to FPoints.Count do begin
      Point:=FPoints[I-1];
      Point.Destroy;
   end;
   FPoints.Clear;                      // Add all new points int the point-list
   FPoints.Capacity:=VertexPoints.Count+EdgePoints.Count+FacePoints.Count;
   for I:=1 to VertexPoints.Count do
     if VertexPoints.Objects[I-1]<>nil then FPoints.Add(VertexPoints.Objects[I-1]);
   for I:=1 to EdgePoints.Count do
     if EdgePoints.Objects[I-1]<>nil then FPoints.Add(EdgePoints.Objects[I-1]);
   for I:=1 to FacePoints.Count do
     if FacePoints.Objects[I-1]<>nil then FPoints.Add(FacePoints.Objects[I-1]);
   FPoints.Capacity:=FPoints.Count;
   VertexPoints.Destroy;                                 // Cleanup temp. lists
   EdgePoints.Destroy;
   FacePoints.Destroy;    // perform averaging procedure to smooth the new mesh
   Setlength(TmpPoints,FPoints.Count);
   for I:=1 to FPoints.Count do begin
      Point:=FPoints[I-1];
      TmpPoints[I-1]:=Point.Averaging;
   end;
   for I:=1 to FPoints.Count do begin
      Point:=FPoints[I-1];
      Point.FCoordinate:=TmpPoints[I-1];
   end;
end;

