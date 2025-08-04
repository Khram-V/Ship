//
//        TFreeSubdivisionLayer
//
procedure TFreeSubdivisionLayer.LoadFromStream(var LineNr:Integer;Strings:TStringList);
var Str     : string;
begin                                                       // read description
   inc(LineNr);
   FDescription:=Strings[LineNr];                  // read Layer identification
   inc(LineNr);
   Str:=Strings[LineNr];
   FLayerID:=GetInteger(Str);
   if FLayerID>Owner.FLastusedLayerID then Owner.FLastusedLayerID:=FLayerID; // read color
   FColor:=GetInteger(Str);                          // read visible
   FVisible:=GetBoolean(Str);
   FSymmetric:=GetBoolean(Str);
end;
procedure TFreeSubdivisionLayer.SaveToStream(Strings:TStringList);
var Str   : string;
begin
   Strings.Add(FDescription);
   Str:=IntToStr(FLayerID)+#32+
        IntToStr(FColor)+#32+
        BoolToStr(FVisible)+#32+
        BoolToStr(FSymmetric);
   Strings.Add(Str);
end;
//
//        TFreeSubdivisionControlPoint
//
procedure TFreeSubdivisionControlPoint.LoadFromStream(var LineNr:Integer;Strings:TStringList);
var Str: string;
    I: Integer;
begin                                                            // FCoordinate
   Inc(LineNr);
   Str:=Strings[LineNr];
   FCoordinate.X:=GetFloat(Str);
   FCoordinate.Y:=GetFloat(Str);
   FCoordinate.Z:=GetFloat(Str);                  // FVertexType
   if Str<>'' then begin
      I:=GetInteger(Str);
      FVertextype:=TFreeVertexType(I);
   end else FVertextype:=TFreeVertexType(0);
end;
procedure TFreeSubdivisionControlPoint.SaveToStream(Strings:TStringlist);
var Str  : String;
begin
   Str:=Truncate(Fcoordinate.X,5)+#32+Truncate(Fcoordinate.Y,5)+#32+Truncate(Fcoordinate.Z,5);
   if Ord(FVertexType)<>0 then Str:=Str+#32+IntToStr(Ord(VertexType));
   Strings.Add(Str);
end;
//
//        TFreesubdivisionControlEdge
//
procedure TFreesubdivisionControlEdge.LoadFromStream(var LineNr:Integer;Strings:TStringList);
var Str:string;
    Index:Integer;
begin
   Inc(LineNr);
   Str:=Strings[LineNr];                                         // FStartpoint
   Index:=GetInteger(Str);
   if index=-1 then index:=0;
   if Index<>-1 then begin
      FStartPoint:=Owner.FControlPoints[Index];
      FStartPoint.FEdges.Add(Self);
   end;                                                            // FEndpoint
   Index:=GetInteger(Str);
   if index=-1 then index:=0;
   if Index<>-1 then begin
      FEndPoint:=Owner.FControlPoints[Index];
      FEndPoint.FEdges.Add(Self);
   end;                                                              // FCrease
   FCrease:=GetInteger(Str)=1;
end;
procedure TFreesubdivisionControlEdge.SaveToStream(Strings:TStringlist);
begin
   Strings.Add(IntToStr(Owner.FControlPoints.SortedIndexOf(FStartpoint))+#32+
               IntToStr(Owner.FControlPoints.SortedIndexOf(FEndpoint))+#32+
               IntToStr(Ord(FCrease)));
end;
//
//        TFreeSubdivisionControlFace
//
procedure TFreeSubdivisionControlFace.LoadFromStream(var LineNr:Integer;Strings:TStringList);
var Str: string;
    I,N,Index: Integer;
    P1,P2: TFreeSubdivisionControlPoint;
    Edge: TFreeSubdivisionControlEdge;
begin
   Inc(LineNr);
   Str:=Strings[LineNr];                              // Read controlpoint data
   N:=GetInteger(Str);
   FPoints.Clear;
   FPoints.Capacity:=N;
   for I:=1 to N do begin
      Index:=GetInteger(Str);
      if Index=-1 then Index:=0;
      if Index<>-1 then begin
         P1:=Owner.FControlPoints[Index];
         FPoints.Add(P1);
         P1.FFaces.Add(Self);
      end;
   end;                                                     // Read layer-index
   Index:=GetInteger(Str);
   if (Index>=0) and (Index<Owner.FLayers.Count) then begin
      FLayer:=Owner.Layer[Index];
   end else begin
      FLayer:=Owner.Layer[0]; // Reference to an invalid layer. Assign to owners default layer
   end;
   if FLayer<>nil then FLayer.AddControlFace(self);
// else Raise Exception.Create('Invalid layer reference in procedure TFreeSubdivisionControlFace.LoadFromStream!');
   P1:=FPoints[NumberOfPoints-1];
   for I:=1 to NumberOfPoints do begin
      P2:=FPoints[I-1];
      Edge:=Owner.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
      if Edge<>nil then Edge.FFaces.Add(Self)
                   else MessageDlg('Could not find edge!',mtError,[mbOk],0);
      P1:=P2;
   end;
end;
procedure TFreeSubdivisionControlFace.SaveToStream(Strings:TStringlist);
var Str     : string;
    I,Index : Integer;
begin
   Str:=IntToStr(NumberOfPoints);
   for I:=1 to NumberOfPoints do Str:=Str+#32+IntToStr(Owner.FControlPoints.SortedIndexOf(Point[I-1]));
   // Add layer index
   if Layer<>nil then Index:=Owner.FLayers.IndexOf(Layer)
                 else Index:=-1;
   Str:=Str+#32+IntToStr(Index);
   strings.Add(Str);
end;
//
//        TFreeSubdivisionSurface
//
procedure TFreeSubdivisionSurface.LoadFromStream
  ( var LineNr:Integer; Strings:TStringList );
var Str  : string;
    I,N  : Integer;
    Point: TFreeSubdivisionControlPoint;
    Edge : TFreeSubdivisionControlEdge;
    Face : TFreeSubdivisionControlFace;
    Layer: TFreeSubdivisionLayer;
begin                                                   // First read layerdata
   Inc(LineNr);
   Str:=Strings[LineNr];
   N:=GetInteger(Str);
   if N<>0 then begin                // Delete current layers and load new ones
      for I:=1 to NumberOfLayers do self.Layer[I-1].Destroy;
      FLayers.Clear;
      FLayers.Capacity:=N;
      for I:=1 to N do begin
         Layer:=AddNewLayer;
         Layer.LoadFromStream(LineNr,Strings);
      end;
   end; // else begin end; // No layers in the file, so keep the current default one

   if assigned( FOnChangeLayerData ) then FOnChangeLayerData( self );
   Inc(LineNr);                                   // Read index of active layer
   Str:=Strings[LineNr];
   N:=GetInteger(Str);
   ActiveLayer:=self.Layer[N];
   if assigned(FOnChangeActiveLayer) then FOnChangeActiveLayer(self,self.Layer[0]);
   Inc(LineNr);
   Str:=Strings[LineNr];
   N:=GetInteger(Str);                                    // Read controlpoints
   for I:=1 to N do begin
      Point:=TFreeSubdivisionControlPoint.Create(self);
      FControlPoints.Add(Point);
      Point.LoadFromStream(LineNr,Strings);
   end;
   Inc(LineNr);                                            // Read controlEdges
   Str:=Strings[LineNr];
   N:=GetInteger(Str);
   for I:=1 to N do begin
      Edge:=TFreeSubdivisionControlEdge.Create(self);
      Edge.FControlEdge:=True;
      FControlEdges.Add(Edge);
      Edge.LoadFromStream(LineNr,Strings);
   end;
   Inc(LineNr);                                            // Read controlFaces
   Str:=Strings[LineNr];
   N:=GetInteger(Str);
   for I:=1 to N do begin
      Face:=TFreeSubdivisionControlFace.Create(self);
      FControlFaces.Add(Face);
      Face.LoadFromStream(LineNr,Strings);
   end;
   Build:=False;
   FInitialized:=True;
   if assigned(FOnChangeLayerData) then FOnChangeLayerData( self );
   if assigned(FOnChangeActiveLayer) then FOnChangeActiveLayer( self,self.Layer[0] );
end;
procedure TFreeSubdivisionSurface.SaveToStream(Strings:TStringlist);
var I: Integer;
begin
   Strings.Add(IntToStr(NumberOfLayers));               // First save layerdata
   for I:=1 to NumberOfLayers do Layer[I-1].SaveToStream(Strings);
   Strings.Add(IntToStr(ActiveLayer.LayerIndex)); // Save index of active layer
   FControlPoints.Sort; // first sort controlpoints for faster acces of function (Indexof())
   Strings.Add(IntToStr(NumberOfControlPoints));
   for I:=1 to NumberOfControlPoints do ControlPoint[I-1].SaveToStream(Strings);
   Strings.Add(IntToStr(NumberOfControlEdges));
   for I:=1 to NumberOfControlEdges do ControlEdge[I-1].SaveToStream(Strings);
   Strings.Add(IntToStr(NumberOfControlFaces));
   for I:=1 to NumberOfControlFaces do ControlFace[I-1].SaveToStream(Strings);
end;


