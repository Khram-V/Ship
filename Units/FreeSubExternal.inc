{------------------------------------------------------------------}
{ Импорт-експорт файлов в различных КАД-форматах по поверхностям }
{------------------------------------------------------------------}
{
  1 = Wavefront Technologies for The Advanced Visualizer animation package.
  2 = WaveFront.obj-запись
  3 = Virtual Reality Markup Language.VRML(.wrl)
  4 = DXF - AutoCAD = SaveToDXF(Strings: TStringList)
  5 = FREE!ship Exchange Format (export.fef)
  6 = ... import.fef
  7 = ImportControlPointGrid  равномерная сетка узлов?(точек) с равным шагом
  8 = ImportCoordGrid похоже на прямоугольную сетку ординат с равным шагом ()
   =
}
procedure TFreeSubdivisionSurface.ImportObjFile( Strings: TStringList );
var
  I,J,K,Index: integer; Str: AnsiString;
// CFace: TFreeSubdivisionControlFace; CPoint: TFreeSubdivisionCOntrolPoint;
  CPoints, FacePoints: TFasterListTFreeSubdivisionControlPoint;
  C3d: T3DVector;
  Faces: TStringList;
  Vindex: array of AnsiString;
begin
  CPoints:=TFasterListTFreeSubdivisionControlPoint.Create;
  FacePoints:=TFasterListTFreeSubdivisionControlPoint.Create;
  Faces:=TStringList.Create;
  Self.IsLoading:=true;
  for I:=0 to Strings.Count-1 do begin
    Str:=BlankOff( Strings[I] );
    if Str.StartsWith( '#' ) then else
    if Str.StartsWith( 'v ' ) then begin SetLength( Vindex,0 );
      Vindex:=Str.Split( [' '] );
      C3d.X:=StrtoFloat( Vindex[1] );
      C3d.Y:=StrtoFloat( Vindex[3] );
      C3d.Z:=StrtoFloat( Vindex[2] ); CPoints.Add( AddControlPoint( C3d ) );
    end else
    if Str.StartsWith('f ') then Faces.Append( Str );
  end;
  for I:=0 to Faces.Count-1 do begin SetLength( Vindex,0 ); FacePoints.Clear;
    Vindex:=Faces[I].Split( [' '] );
    K:=Length( Vindex )-1;           //?? с замыкаением контура много?угольника
    if K>2 then begin
      for J:=1 to K do begin
        Index:=StrtoInt( Vindex[J].Replace( '/',' ' ) );       // впереди 'f'
        FacePoints.Add( CPoints[Index-1] );
      end;
      if  ( FacePoints[0]<>FacePoints[1] )  // нулевая площадь - приемлема
      and ( FacePoints[1]<>FacePoints[2] )  // совпедение точек - недопустимо
      and ( FacePoints[2]<>FacePoints[0] )
      then AddControlFace( FacePoints,True,Self.Layer[0] );
    end;
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
  C3d: T3DVector;
begin
  if not ExportControlNet then begin               // export subdivided surface
    if not Built then rebuild;
           // first sort subdiv points for faster acces of function (Indexof())
    Strings.Add( '# FREE!ship subdivided surface' );
//  FPoints.Sort;                                 // Create points for portside
    Tmp:=TFasterListTFreeSubdivisionPoint.Create;
    Tmp.Capacity:=NumberOfSubDivPoints;
    for I:=1 to NumberOfSubDivPoints do begin
      C3d:=SubDivPoint[I-1].Coordinate;
      Strings.Add(format('v %07.04f %07.04f %07.04f',[C3d.x,C3d.z,C3d.y]));
      if C3d.y>0 then Tmp.Add(SubDivPoint[I-1]);  /// ????
    end;
    if DrawMirror then begin                      // Create points for portside
//    Tmp.Sort;                                   // лишний болрт для картинки
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
            Index:=FPoints.IndexOf(Child.FPoints[K-1]);
            if Index <> -1 then Str:=Str+#32+IntToStr(index+1);
          end;
          Strings.Add(Str);
          if (CFace.Layer.Symmetric) and (DrawMirror) then begin // Starboard side
            Str:='f';
            Child:=CFace.Child[J-1];
            for k:=Child.FPoints.Count downto 1 do begin
              if Child.Point[K-1].Coordinate.Y > 0 then begin
                Index:=Tmp.IndexOf(Child.Point[K-1])+NumberOfSubDivPoints;
              end else
                Index:=FPoints.IndexOf(Child.FPoints[K-1]);
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
//  FControlPoints.Sort;                   // Create ControlPoints for portside
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
//    Tmp.Sort;
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
          Index:=FControlPoints.IndexOf(Cface.Point[K-1]);
          if Index <> -1 then Str:=Str+#32+IntToStr(index+1);
        end;
        Strings.Add(Str);
        if (CFace.Layer.Symmetric) and (DrawMirror) then begin // Starboard side
          Str:='f';
          for k:=Cface.FPoints.Count downto 1 do begin
            if Cface.Point[K-1].Coordinate.Y>0 then begin
              Index:=Tmp.IndexOf(Cface.Point[K-1])+NumberOfControlPoints;
            end else
              Index:=FControlPoints.IndexOf(Cface.Point[K-1]);
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
var VRMLList: TVRMLList;
    VRMLVersion: String;
begin
//if FileExists(Filename) then begin
//  VRMLList:=TVRMLList.Create;
    VRMLVersion:=TVRMLList.CheckVRMLFileVersion( Filename );
    if VRMLVersion='VRML V1.0' then VRMLList:=TVRMLList.Create else
    if VRMLVersion='VRML V2.0' then VRMLList:=TVRML2Scene.Create else
                               begin FIsLoading:=false; exit; end;
    FIsLoading:=true;
    MainForm.FreeShip.Clear;
    VRMLList.Import( Filename,Self );
//end;
end;
//
//  DXF AutoCAD = SaveToDXF(Strings: TStringList)
//
// find nearest DXF color corresponding to a windows color
function FindDXFColorIndex(Color: TColor): integer;
 const DXFLayerColors: array[1..255] of TColor =
   ($0000FF, $00FFFF, $00FF00, $FFFF00, $FF0000, $FF00FF, $000000, $808080, $C0C0C0, $0000FF,
    $7F7FFF, $0000A5, $5252A5, $00007F, $3F3F7F, $00004C, $26264C, $000026, $131326, $003FFF,
    $7F9FFF, $0029A5, $5267A5, $001F7F, $3F4F7F, $00134C, $262F4C, $000926, $131726, $007FFF,
    $7FBFFF, $0052A5, $527CA5, $003F7F, $3F5F7F, $00264C, $26394C, $001326, $131C26, $00BFFF,
    $7FDFFF, $007CA5, $5291A5, $005F7F, $3F6F7F, $00394C, $26424C, $001C26, $132126, $00FFFF,
    $7FFFFF, $00A5A5, $52A5A5, $007F7F, $3F7F7F, $004C4C, $264C4C, $002626, $132626, $00FFBF,
    $7FFFDF, $00A57C, $52A591, $007F5F, $3F7F6F, $004C39, $264C42, $00261C, $132621, $00FF7F,
    $7FFFBF, $00A552, $52A57C, $007F3F, $3F7F5F, $004C26, $264C39, $002613, $13261C, $00FF3F,
    $7FFF9F, $00A529, $52A567, $007F1F, $3F7F4F, $004C13, $264C2F, $002609, $132617, $00FF00,
    $7FFF7F, $00A500, $52A552, $007F00, $3F7F3F, $004C00, $264C26, $002600, $132613, $3FFF00,
    $9FFF7F, $29A500, $67A552, $1F7F00, $4F7F3F, $134C00, $2F4C26, $092600, $172613, $7FFF00,
    $BFFF7F, $52A500, $7CA552, $3F7F00, $5F7F3F, $264C00, $394C26, $132600, $1C2613, $BFFF00,
    $DFFF7F, $7CA500, $91A552, $5F7F00, $6F7F3F, $394C00, $424C26, $1C2600, $212613, $FFFF00,
    $FFFF7F, $A5A500, $A5A552, $7F7F00, $7F7F3F, $4C4C00, $4C4C26, $262600, $262613, $FFBF00,
    $FFDF7F, $A57C00, $A59152, $7F5F00, $7F6F3F, $4C3900, $4C4226, $261C00, $262113, $FF7F00,
    $FFBF7F, $A55200, $A57C52, $7F3F00, $7F5F3F, $4C2600, $4C3926, $261300, $261C13, $FF3F00,
    $FF9F7F, $A52900, $A56752, $7F1F00, $7F4F3F, $4C1300, $4C2F26, $260900, $261713, $FF0000,
    $FF7F7F, $A50000, $A55252, $7F0000, $7F3F3F, $4C0000, $4C2626, $260000, $261313, $FF003F,
    $FF7F9F, $A50029, $A55267, $7F001F, $7F3F4F, $4C0013, $4C262F, $260009, $261317, $FF007F,
    $FF7FBF, $A50052, $A5527C, $7F003F, $7F3F5F, $4C0026, $4C2639, $260013, $26131C, $FF00BF,
    $FF7FDF, $A5007C, $A55291, $7F005F, $7F3F6F, $4C0039, $4C2642, $26001C, $261321, $FF00FF,
    $FF7FFF, $A500A5, $A552A5, $7F007F, $7F3F7F, $4C004C, $4C264C, $260026, $261326, $BF00FF,
    $DF7FFF, $7C00A5, $9152A5, $5F007F, $6F3F7F, $39004C, $42264C, $1C0026, $211326, $7F00FF,
    $BF7FFF, $5200A5, $7C52A5, $3F007F, $5F3F7F, $26004C, $39264C, $130026, $1C1326, $3F00FF,
    $9F7FFF, $2900A5, $6752A5, $1F007F, $4F3F7F, $13004C, $2F264C, $090026, $171326, $000000,
    $2D2D2D, $5B5B5B, $898989, $B7B7B7, $B3B3B3);
var
  R, G, B: byte;
  R1, G1, B1: byte;
  I: integer;
  Dist, Tmp: single;
begin
  Result:=1;
  R:=GetRValue(Color);
  G:=GetGValue(Color);
  B:=GetBValue(Color);
  Dist:=1e30;
  for I:=1 to 255 do
  begin
    R1:=GetRValue(DXFLayerColors[I]);
    G1:=GetGValue(DXFLayerColors[I]);
    B1:=GetBValue(DXFLayerColors[I]);
    Tmp:=Sqrt(Sqr(R1-R)+Sqr(G1-G)+Sqr(B1-B));
    if Tmp < Dist then
    begin
      Dist:=Tmp;
      Result:=I;
    end;
  end;
end;{FindDXFColorIndex}

procedure TFreeSubdivisionControlCurve.SaveToDXF( Strings: TStringList );
begin FSpline.Fragments:=FSpline.NumberOfPoints;
      FSpline.SaveToDXF( Strings,'Control_curves',Surface.DrawMirror );
end;
procedure TFreeSubdivisionLayer.SaveToDXF(Strings: TStringList);
var
  NAssembled, I,J,K, Cols,Rows: integer; P: T3DVector;
  Layers: TFasterListTFreeSubdivisionLayer;
  Assembled: TFreeFaceArray;
  AssFace: TFreeFaceGrid;
  Face: TFreeSubdivisionControlFace;
  Grid: TFreeSubdivisionPointGrid;

  DXFName: string;
begin
  if SurfaceVisible then
  begin
    Layers:=TFasterListTFreeSubdivisionLayer.Create;
    Layers.Add(self);
    Surface.AssembleFacesToPatches(Layers, amRegular, Assembled, NAssembled);
    if NAssembled > 0 then begin
      // assign all patches to new layers
      for I:=1 to NAssembled do begin
        AssFace:=Assembled[I-1];
        if ((AssFace.NCols > 1) and (AssFace.NRows >= 1)) or
          ((AssFace.NCols >= 1) and (AssFace.NRows > 1)) or
          ((AssFace.NCols = 1) and (AssFace.NRows = 1) and
          (AssFace.Faces[0][0].NumberOfPoints = 4)) then begin
          Surface.ConvertToGrid(AssFace, Cols, Rows, Grid);
          if (Cols > 0) and (Rows > 0) then begin
            DXFName:=DXFLayerName;
            Strings.Add('0'+EOL+'POLYLINE');
            Strings.Add('8'+EOL+DXFName);
            Strings.Add('62'+EOL+IntToStr(FindDXFColorIndex(color)));
            Strings.Add('66'+EOL+'1');
            Strings.Add('70'+EOL+'16');
            Strings.Add('71'+EOL+IntToStr(Rows));
            Strings.Add('72'+EOL+IntToStr(Cols));
            for J:=1 to Rows do begin
              for K:=1 to Cols do begin
                P:=Grid[J-1][K-1].FCoordinate;
                Strings.Add('0'+EOL+'VERTEX');
                Strings.Add('8'+EOL+DXFName);
                Strings.Add('10'+EOL+FloatToDec(P.X, 4));   ///***??? DXF-layer
                Strings.Add('20'+EOL+FloatToDec(P.Z, 4));
                Strings.Add('30'+EOL+FloatToDec(P.Y, 4));
                Strings.Add('70'+EOL+'64');              // polygon mesh vertex
              end;
            end;
            Strings.add('0'+EOL+'SEQEND');
            if (Symmetric) and (Surface.DrawMirror) then begin
              Strings.Add('0'+EOL+'POLYLINE');
              Strings.Add('8'+EOL+DXFName);
              Strings.Add('62'+EOL+IntToStr(FindDXFColorIndex(color)));
              Strings.Add('66'+EOL+'1');
              Strings.Add('70'+EOL+'16');
              Strings.Add('71'+EOL+IntToStr(Rows));
              Strings.Add('72'+EOL+IntToStr(Cols));
              for J:=1 to Rows do begin
                for K:=1 to Cols do begin
                  P:=Grid[J-1][K-1].FCoordinate;
                  Strings.Add('0'+EOL+'VERTEX');
                  Strings.Add('8'+EOL+DXFName);
                  Strings.Add('10'+EOL+FloatToDec(P.X, 4));
                  Strings.Add('20'+EOL+FloatToDec(-P.Z, 4));
                  Strings.Add('30'+EOL+FloatToDec(P.Y, 4));
                  Strings.Add('70'+EOL+'64');    // polygon mesh vertex
                end;
              end;
              Strings.add('0'+EOL+'SEQEND');
            end;
          end else begin
            for J:=1 to AssFace.NRows do begin
              for K:=1 to AssFace.NCols do begin
                Face:=AssFace.Faces[J-1][K-1];
                if Face <> nil then Face.SaveToDXF(Strings);
              end;
            end;
          end;
        end
        else if (AssFace.NCols = 1) and (AssFace.NRows = 1) then
        begin
          Face:=AssFace.Faces[0][0];
          Face.SaveToDXF(Strings);
        end;
      end;
    end;
    FreeAndNil(Layers);
  end;
end;
//
//   AutoCAD - Face = треугольники
//
procedure TFreeSubdivisionControlFace.SaveToDXF(Strings: TStringList);
var
  I,J,K, Cols,Rows, ColorIndex: integer;   P: T3DVector;
  Child: TFreeSubdivisionFace;
  LayerName: string;
  Grid: TFreeSubdivisionPointGrid;
  FaceData: TFreeFaceGrid;
begin
  LayerName:=self.Layer.Name;
  ColorIndex:=FindDXFColorIndex(Layer.Color);
  if NumberOfpoints = 4 then
  begin
    // create one polymesh for all childfaces
    FaceData.NCols:=1;
    FaceData.NRows:=1;
    Setlength(FaceData.Faces, FaceData.NRows);
    Setlength(FaceData.Faces[0], FaceData.NCols);
    FaceData.Faces[0][0]:=Self;
    Surface.ConvertToGrid(FaceData, Cols, Rows, Grid);
    if (Rows > 0) and (Cols > 0) then
    begin
      Strings.Add('0'+EOL+'POLYLINE');
      Strings.Add('8'+EOL+LayerName);
      Strings.Add('62'+EOL+IntToStr(ColorIndex));
      Strings.Add('66'+EOL+'1');
      Strings.Add('70'+EOL+'16');
      Strings.Add('71'+EOL+IntToStr(Cols));
      Strings.Add('72'+EOL+IntToStr(Rows));
      for I:=1 to Rows do begin
        for J:=1 to Cols do begin
          P:=Grid[I-1][J-1].FCoordinate;
          Strings.Add('0'+EOL+'VERTEX');                     ///***??? DXF-face
          Strings.Add('8'+EOL+LayerName);
          Strings.Add('10'+EOL+FloatToDec(P.X,4));
          Strings.Add('20'+EOL+FloatToDec(P.Z,4));
          Strings.Add('30'+EOL+FloatToDec(P.Y,4));
          Strings.Add('70'+EOL+'64');                    // polygon mesh vertex
        end;
      end;
      Strings.add('0'+EOL+'SEQEND');
      if (Layer.Symmetric) and (Surface.DrawMirror) then begin
        Strings.Add('0'+EOL+'POLYLINE');
        Strings.Add('8'+EOL+LayerName);
        Strings.Add('62'+EOL+IntToStr(ColorIndex));
        Strings.Add('66'+EOL+'1');
        Strings.Add('70'+EOL+'16');
        Strings.Add('71'+EOL+IntToStr(Cols));
        Strings.Add('72'+EOL+IntToStr(Rows));
        for I:=1 to Rows do begin
          for J:=1 to Cols do begin
            P:=Grid[I-1][J-1].FCoordinate;
            Strings.Add('0'+EOL+'VERTEX');
            Strings.Add('8'+EOL+LayerName);
            Strings.Add('10'+EOL+FloatToDec(P.X,4));
            Strings.Add('20'+EOL+FloatToDec(-P.Z,4));
            Strings.Add('30'+EOL+FloatToDec(P.Y,4));
            Strings.Add('70'+EOL+'64');                  // polygon mesh vertex
          end;
        end; Strings.add('0'+EOL+'SEQEND');
      end;
    end;
  end else begin                            // send all child faces as 3D faces
    for J:=1 to ChildCount do begin
      Child:=self.Child[J-1];
      Strings.Add('0'+EOL+'3DFACE');
      Strings.Add('8'+EOL+LayerName);
      Strings.Add('62'+EOL+IntToStr(ColorIndex));
      for K:=1 to Child.NumberOfpoints do begin
        P:=Child.Point[K-1].Coordinate;
        Strings.Add(IntToStr(10+K-1)+EOL+FloatToDec(P.X,4));
        Strings.Add(IntToStr(20+K-1)+EOL+FloatToDec(P.Z,4));
        Strings.Add(IntToStr(30+K-1)+EOL+FloatToDec(P.Y,4));
      end;
      if Child.NumberOfpoints = 3 then begin      // 4th point is same as third
        Strings.Add(IntToStr(13)+EOL+FloatToDec(P.X,4));
        Strings.Add(IntToStr(23)+EOL+FloatToDec(P.Z,4));
        Strings.Add(IntToStr(33)+EOL+FloatToDec(P.Y,4));
      end;
      if (Layer.Symmetric) and (Surface.DrawMirror) then begin // send starboard side also
        Strings.Add('0'+EOL+'3DFACE');
        Strings.Add('8'+EOL+LayerName);
        Strings.Add('62'+EOL+IntToStr(ColorIndex));
        for K:=Child.NumberOfpoints downto 1 do begin
          P:=Child.Point[K-1].Coordinate;
          P.Y:=-P.Y;
          Strings.Add(IntToStr(10+K-1)+EOL+FloatToDec(P.X,4));
          Strings.Add(IntToStr(20+K-1)+EOL+FloatToDec(P.Z,4));
          Strings.Add(IntToStr(30+K-1)+EOL+FloatToDec(P.Y,4));
        end;
        if Child.NumberOfpoints = 3 then begin    // 4th point is same as third
          Strings.Add(IntToStr(13)+EOL+FloatToDec(P.X,4));
          Strings.Add(IntToStr(23)+EOL+FloatToDec(P.Z,4));
          Strings.Add(IntToStr(33)+EOL+FloatToDec(P.Y,4));
        end;
      end;
    end;
  end;
end;
//
//
procedure TFreeDevelopedPatch.SaveToDXF(Strings: TStringList);
var
  I, J: integer;
  Col: integer;
  Index: integer;
  P: TFreeSubdivisionPoint;
  P3D: T3DVector;
  Layer: string;
  Source: TFasterListTFreeSubdivisionEdge;
  Dest: TFasterListTFreeSubdivisionFace;
  Edge:TFreeSubdivisionEdge;
  Face:TFreeSubdivisionFace;

  procedure ExportSpline(Spline: TFreeSpline; Layername: string);
  var
    I, Col: integer;
    P2D: T2DCoordinate;
    P3D: T3DVector;
  begin
    Col:=FindDXFColorIndex(Spline.Color);
    Strings.Add('0'+EOL+'POLYLINE');
    Strings.Add('8'+EOL+LayerName);             // layername
    Strings.Add('62'+EOL+IntToStr(Col));        // color by layer
    Strings.Add('66'+EOL+'1');                  // vertices follow
    for I:=0 to Spline.Fragments do begin
      P3D:=Spline.Value(I / Spline.Fragments);
      P2D.X:=P3D.X;
      P2D.Y:=P3D.Y;
      if (FMirrorOnScreen) and not (FMirror) then P2D.Y:=-P2D.Y;
      P3D:=ConvertTo3D(P2D);
      Strings.Add('0'+EOL+'VERTEX');
      Strings.Add('8'+EOL+Layername);
      Strings.Add('10'+EOL+FloatToDec(P3D.X, 4));
      Strings.Add('20'+EOL+FloatToDec(P3D.Y, 4));
    end;
    Strings.Add('0'+EOL+'SEQEND');
  end;{ExportSpline}

begin
  // Extract edges as polylines
  Source:=TFasterListTFreeSubdivisionEdge.Create;
  Source.AddList(FBoundaryEdges);
  Dest:=TFasterListTFreeSubdivisionFace.Create; // use face as list of points
  Owner.Surface.IsolateEdges(Source, Dest);
  FreeAndNil(Source);
  Col:=FindDXFColorIndex(Owner.Color);
  Layer:=Owner.Name;
  for I:=1 to Dest.Count do begin
    Face:=Dest[I-1];
    // Save data as 2D polyline
    Strings.Add('0'+EOL+'POLYLINE');
    Strings.Add('8'+EOL+Layer);               // layername
    Strings.Add('62'+EOL+IntToStr(Col));      // color by layer
    Strings.Add('66'+EOL+'1');                // vertices follow
    for J:=0 to Face.Points.Count-1 do begin
      P:=Face.Points[J];
      Index:=FPoints.IndexOf(P);
      P3D:=Point[Index];
      Strings.Add('0'+EOL+'VERTEX');
      Strings.Add('8'+EOL+Layer);
      Strings.Add('10'+EOL+FloatToDec(P3D.X, 4));
      Strings.Add('20'+EOL+FloatToDec(P3D.Y, 4));
    end;
    Strings.Add('0'+EOL+'SEQEND');
    if FMirror then begin
      Strings.Add('0'+EOL+'POLYLINE');
      Strings.Add('8'+EOL+Layer);            // layername
      Strings.Add('62'+EOL+IntToStr(Col));   // color by layer
      Strings.Add('66'+EOL+'1');             // vertices follow
      begin
        P:=Face.Points[J];
        Index:=FPoints.IndexOf(P);
        P3D:=MirrorPoint[Index];
        Strings.Add('0'+EOL+'VERTEX');
        Strings.Add('8'+EOL+Layer);
        Strings.Add('10'+EOL+FloatToDec(P3D.X, 4));
        Strings.Add('20'+EOL+FloatToDec(P3D.Y, 4));
      end;
      Strings.Add('0'+EOL+'SEQEND');
    end;
  end;
  if ShowStations then
    for I:=1 to FStations.Count do
      ExportSpline(FStations[I-1], 'stations');
  if ShowButtocks then
    for I:=1 to FButtocks.Count do
      ExportSpline(FButtocks[I-1], 'buttocks');
  if ShowWaterlines then
    for I:=1 to FWaterlines.Count do
      ExportSpline(FWaterlines[I-1], 'waterlines');
  if ShowDiagonals then
    for I:=1 to FDiagonals.Count do
      ExportSpline(FDiagonals[I-1], 'diagonals');
  FreeAndNil(Dest);
end;{TFreeDevelopedPatch.SaveToDXF}
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
//FControlPoints.Sort;
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
  Point,P1,P2: TFreeSubdivisionControlPoint;
  Edge: TFreeSubdivisionControlEdge;
  Face: TFreeSubdivisionControlFace;
  Layer: TFreeSubdivisionLayer;

  function NewPoint( P: T3DVector ): TFreeSubdivisionControlPoint;
  begin Result:=TFreeSubdivisionControlPoint.Create( self );
        Result.FCoordinate:=P;
        FControlPoints.Add( Result );
  end;{NewPoint}
begin
  FIsLoading:=true;                                   // Read layer information
  Inc( LineNr ); Str:=Strings[LineNr]; N:=GetInteger( Str );
  if N=0 then               ///*** в преобразованиях из Delft есть лишний нолик
     begin Inc( LineNr ); Str:=Strings[LineNr]; N:=GetInteger( Str ); end;
  for I:=1 to N do begin
    if I>NumberOfLayers then Layer:=self.AddNewLayer
                        else Layer:=self.Layer[I-1];
    Inc( LineNr ); Layer.FDescription:=Strings[LineNr];
    Inc( LineNr ); Str:=Strings[LineNr];
    Layer.FLayerID:=GetInteger( Str );
    if Layer.FLayerID>FLastusedLayerID then FLastusedLayerID:=Layer.FLayerID;
    Layer.FColor:=GetInteger( Str );
    Layer.FSurfaceVisible:=GetBoolean( Str );
    Layer.FDevelopable:=GetBoolean( Str );
    Layer.FSymmetric:=GetBoolean( Str );
    Layer.FSymmetric:=True;
    Layer.FUseForIntersections:=GetBoolean( Str );
    Layer.FUseInHydrostatics:=GetBoolean( Str );
    Layer.FShowInLinesplan:=GetBoolean( Str );
    Layer.FMaterialDensity:=GetFloat( Str );
    Layer.FThickness:=GetFloat( Str );
  end;
  if Assigned(FOnChangeLayerData) then FOnChangeLayerData( self );
  Inc(LineNr); Str:=Strings[LineNr];                      // Read controlpoints
  N:=GetInteger( Str );
  for I:=1 to N do begin
    Point:=TFreeSubdivisionControlPoint.Create(self);
    FControlPoints.Add(Point);
    Point.LoadFromStream(LineNr, Strings);
  end;
  Inc(LineNr); Str:=Strings[LineNr];                       // Read controlEdges
  N:=GetInteger( Str);
  for I:=1 to N do begin
    Edge:=TFreeSubdivisionControlEdge.Create(self);
    Edge.FControlEdge:=True;
    FControlEdges.Add(Edge);
    Edge.LoadFromStream( LineNr,Strings );
  end;
  Inc(LineNr); Str:=Strings[LineNr];                       // Read controlFaces
  N:=GetInteger( Str );
  for I:=1 to N do begin
    Face:=TFreeSubdivisionControlFace.Create(self);
    FControlFaces.Add(Face);
    Inc(LineNr); Str:=Strings[LineNr];
    Np:=GetInteger( Str);
    for J:=1 to Np do begin
      Index:=GetInteger( Str);           // Attach controlface to controlpoints
      Face.AddPoint(ControlPoint[Index]);
    end;            // Attach controlface to the already existing control edges
    P1:=Face.Point[Face.FPoints.Count-1];
    for J:=1 to Face.FPoints.Count do begin
      P2:=Face.Point[J-1];
      Edge:=EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
      if Edge<>nil then Edge.AddFace(Face);                                     // else MessageDlg( 'Could not find edge!',mtError,[mbOK],0);
      P1:=P2;
    end;
    Index:=GetInteger( Str);                                 // Read Layerindex
    while Index > NumberOfLayers-1 do begin AddNewLayer; end;
    Layer:=FLayers[Index];
    Layer.AddControlFace(Face);
  end;
  Built:=False;
  FInitialized:=True;
  if assigned(FOnChangeLayerData) then FOnChangeLayerData(self);
  if assigned(FOnChangeActiveLayer) then FOnChangeActiveLayer(self,self.Layer[0]);
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
  for I:=1 to Rows-1 do
  for J:=1 to Cols-1 do begin FacePoints.Clear;
      P11:=Grid[I-1,J-1];
      P12:=Grid[I-1,J];
      P22:=Grid[I,J];
      P21:=Grid[I,J-1];
      if FacePoints.IndexOf(P11)=-1 then FacePoints.Add(P11);
      if FacePoints.IndexOf(P12)=-1 then FacePoints.Add(P12);
      if FacePoints.IndexOf(P22)=-1 then FacePoints.Add(P22);
      if FacePoints.IndexOf(P21)=-1 then FacePoints.Add(P21);
      if FacePoints.Count>=3 then
      if Layer<>nil then AddControlFace( FacePoints,True,Layer )
                    else AddControlFace( FacePoints,True );
      GridPoints.AddList(FacePoints);
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

