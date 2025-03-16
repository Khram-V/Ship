{ 
  © Import the files are always UTF8
}
procedure TFreeEdit.File_ImportObj;
var
  OpenDialog: TOpenDialog;
  PrevCursor: TCursor;
  Strings: TStringList;
begin
  OpenDialog:=TOpenDialog.Create( FreeShip );
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory; //+ConfigDirectory
  OpenDialog.Filter:=createDialogFilter( 'OBJ file',['obj'] );
  if OpenDialog.Execute then begin
    if not CheckIfChangedAndAskToSave() then begin
      FreeAndNil( OpenDialog ); exit;
    end;
    PrevCursor:=Screen.Cursor;
    Screen.Cursor:=crHourglass;
//    try
      CreateUndoObject( 'OBJ file',True );
      FreeShip.Clear;

      Strings:=TStringList.Create;
      Strings.LoadFromFile( ChangeFileExt( OpenDialog.FileName,'.obj' ) );
      FreeShip.Surface.ImportObjFile( Strings );

      FreeShip.ModelIsLoaded:=True;
      FreeShip.FileName:=ChangeFileExt( Opendialog.FileName,'' );
      FreeShip.RebuildModel;
      FreeShip.FileChanged:=True;
      FreeShip.Redraw;

//    finally
      FreeAndNil(Strings);
      if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
      Screen.Cursor:=PrevCursor;
//    end;
  end;
  FreeAndNil( OpenDialog );
end;
//
//
//
procedure TFreeEdit.File_ImportSTL;
var
  OpenDialog: TOpenDialog;
  FileName,Str: AnsiString;
  FFile: TextFile;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter( rsSTLFile,['stl'] );
  if OpenDialog.Execute then begin
    if not CheckIfChangedAndAskToSave() then begin FreeAndNil(OpenDialog); exit; end;
    CreateUndoObject( rsSTLfile, True);
    FreeShip.Clear;
    FileName:=ChangeFileExt( OpenDialog.FileName, '.stl' );
    AssignFile( FFile,FileName ); Reset( FFile );
    if IOResult = 0 then begin
      if not EOF(FFile) then begin
        Readln( FFile,Str ); Str:=Str.Trim.ToLower;
        if Str.StartsWith( 'solid ' ) then begin
          CloseFile( FFile ); File_ImportSTLtext( FileName );
        end else begin
          CloseFile( FFile ); File_ImportSTLbin( FileName );
        end;
      end;
      FreeShip.FileName:=ChangeFileExt( Opendialog.FileName,'' );
      FreeShip.ModelIsLoaded:=True;
      FreeShip.FileChanged:=True;
      FreeShip.RebuildModel;
      FreeShip.Redraw;
    end else MessageDlg( UserString(97), mtError, [mbOK], 0);
  end;
  FreeAndNil(OpenDialog);
end;{TFreeEdit.File_ImportSTL}

procedure TFreeEdit.File_ImportSTLtext( FileName: AnsiString );
var
  FFile: TextFile;
  Str: AnsiString; idSolid:boolean;
  LineNr,SolidNr,FacetNr,VertexNr:Integer; V:T3DVector;
  Layer: TFreeSubdivisionLayer;
  FacePoints: TFasterListTFreeSubdivisionControlPoint;
  CtrPoint: TFreeSubdivisionControlPoint;
  SubdivisionSurface: TFreeSubdivisionSurface;
  Tokens: array of string;
begin
    FreeShip.ProjectSettings.FProjectName:=ExtractFileName( FileName );
    AssignFile( FFile,FileName ); Reset( FFile);
    if IOResult = 0 then begin
//    try
        SubdivisionSurface:=FreeShip.Surface;
        SubdivisionSurface.IsLoading:=true;
        FacePoints:=TFasterListTFreeSubdivisionControlPoint.Create;
        LineNr:=1; SolidNr:=0; FacetNr:=0; VertexNr:=0;
        while not EOF(FFile) do begin
          Readln( FFile,Str );                   // if EOF( FFile ) then break;
          idSolid:=copy( Str,1,6 ).ToLower.StartsWith( 'solid ' );
          if not idSolid then Str:=BlankOff( Str );             Inc( LineNr );
          if idSolid then begin                                 inc( SolidNr );
            if SolidNr=1
               then Layer:=SubdivisionSurface.Layer[0]
               else Layer:=SubdivisionSurface.AddNewLayer;
            if Length( Str )>7 then Layer.Name:=copy( Str,7,Length(Str)-6 )     // Str.SubString( 7,256 )
                               else Layer.Name:='Layer '+inttostr( SolidNr );
          end else
          if Str.StartsWith('facet ') then begin inc(FacetNr);  // read Normal?
            VertexNr:=1; FacePoints.Clear;
          end else
          if Str.StartsWith('outer loop') then else
          if Str.StartsWith('vertex ') then begin
            Tokens:=Str.Split( [' '] );
            V.X:=GetFloat( Tokens[1] );
            V.Y:=GetFloat( Tokens[2] );
            V.Z:=GetFloat( Tokens[3] );
//          Precision:=detectPrecision( Tokens[1] );
            CtrPoint:=SubdivisionSurface.AddControlPoint( V );//,Precision );
//          if FacePoints.IndexOf( CtrPoint )=-1 then
               FacePoints.Add( CtrPoint );                     inc( VertexNr );
            SetLength( Tokens,0 );
          end else
          if Str.StartsWith('endloop') then else                      // break;
          if Str.StartsWith('endfacet') then begin
            if FacePoints.Count>2 then
               SubdivisionSurface.AddControlFace( FacePoints,True,Layer );
          end else
          if Str.StartsWith('endsolid') then begin                    // break;
          end;
        end;
        FreeAndNil(FacePoints);
//    finally
        CloseFile(FFile);
        SubdivisionSurface.IsLoading:=false;
//    end;
    end
    else
      MessageDlg( UserString(97), mtError, [mbOK], 0);
end;

procedure TFreeEdit.File_ImportSTLbin(FileName: AnsiString);
var
  FileStream: TFileStream;
  STLheader: array[0..79] of char;
  STLfacets: uint32;
  STLrecord: packed record
      normalX,   normalY,   normalZ: single;
    vertex1_X, vertex1_Y, vertex1_Z: single;      // для Зумвальта, т.к.
    vertex2_X, vertex2_Y, vertex2_Z: single;      // другого файла провреки
    vertex3_X, vertex3_Y, vertex3_Z: single;      // тогда не находилось
    unused: uint16;
  end;
  Str: AnsiString; SolidNr, FacetNr: Integer; r: longint; V: T3DVector;
  Layer: TFreeSubdivisionLayer;
  FacePoints: TFasterListTFreeSubdivisionControlPoint;
  CtrPoint: TFreeSubdivisionControlPoint;
  SubdivisionSurface: TFreeSubdivisionSurface;    //  Precision: double = 1e-8;
begin
    FreeShip.ProjectSettings.FProjectName:=ExtractFileName( FileName );
    FileStream:=TFileStream.Create( FileName,fmOpenRead );
    if FileStream.Size>80 then begin
//      try
        SubdivisionSurface:=FreeShip.Surface;
        SubdivisionSurface.IsLoading:=true;
        FacePoints:=TFasterListTFreeSubdivisionControlPoint.Create;
        SolidNr:=0; FacetNr:=1;
        r:=FileStream.Read( STLheader,80 );
        Str:=String.Create( STLheader );                        inc( SolidNr );
        if SolidNr=1
           then Layer:=SubdivisionSurface.Layer[0]
           else Layer:=SubdivisionSurface.AddNewLayer;
        Layer.Name:=Str;
        r:=FileStream.Read( STLfacets,4 );
        for FacetNr:=1 to STLfacets do begin
          r:=FileStream.Read( STLrecord,SizeOf( STLrecord ) );
          if r<SizeOf( STLrecord ) then break;
          FacePoints.Clear;
          V.X:=STLrecord.vertex1_X;
          V.Y:=STLrecord.vertex1_Y;
          V.Z:=STLrecord.vertex1_Z;                    //     Precision:=0.1;
          CtrPoint:=SubdivisionSurface.AddControlPoint( V );  //,Precision );
          FacePoints.Add( CtrPoint );
          V.X:=STLrecord.vertex2_X;
          V.Y:=STLrecord.vertex2_Y;
          V.Z:=STLrecord.vertex2_Z;                    //     Precision:=0.1;
          CtrPoint:=SubdivisionSurface.AddControlPoint( V );  //,Precision );
          FacePoints.Add( CtrPoint );
          V.X:=STLrecord.vertex3_X;
          V.Y:=STLrecord.vertex3_Y;
          V.Z:=STLrecord.vertex3_Z;                    //     Precision:=0.1;
          CtrPoint:=SubdivisionSurface.AddControlPoint( V );  //,Precision );
          FacePoints.Add( CtrPoint );
          SubdivisionSurface.AddControlFace( FacePoints,True,Layer );
        end;
//      finally
        FileStream.Free;
        SubdivisionSurface.IsLoading:=false;
//      end;
    end else MessageDlg( UserString(97), mtError, [mbOK], 0);
end;
//
// Virtual Modeling
// Load a VRML file
procedure TFreeEdit.File_ImportVRML;
var
  OpenDialog: TOpenDialog;
  Answer: word;
  PrevCursor: TCursor;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter('VRML files',['wrl','vrml']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
    Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
    if (Answer=mrCancel) or FreeShip.FileChanged then begin FreeAndNil( OpenDialog ); exit; end;
    PrevCursor:=Screen.Cursor;
    Screen.Cursor:=crHourglass;
      CreateUndoObject(Userstring(125), True);
//    FreeShip.Clear;
//    FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      FreeShip.Surface.LoadVRMLFile( Opendialog.FileName );
//    if FreeShip.Surface.FIsLoading then
      begin
          FreeShip.ModelIsLoaded:=True;
          FreeShip.FileName:=ChangeFileExt( Opendialog.FileName,'' );
          FreeShip.RebuildModel;
          FreeShip.FileChanged:=True;
      end;
      if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
      Screen.Cursor:=PrevCursor;
  end;
  FreeAndNil(OpenDialog);
end;
//
// Loads a bodyplane and tries to fit a surface to it
//
procedure TFreeEdit.ImportFrames;
type
  TMinMax = record MinZ, MaxZ: TFloatType; end;
  // Assumptions:
  //    1. All stations have multiplicity of 1
  //    2. All stations are defined from bottom to top
var
  OpenDialog: TOpenDialog;
  I, J, K, Nr, Index, NoStations, NoPoints: integer;
  Frames: TFasterListTFreeSpline;
  FFile: TextFile;
  Spline, NewSpline: TFreeSpline;
  P: T3DVector;
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
  OpenDialog.Filter:=createDialogFilter( '3D text file',['txt'] );
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
    Frames:=TFasterListTFreeSpline.Create;
    case OpenDialog.FilterIndex of
      1: begin      // 3D textfile containing stations, waterlines and buttocks
        AssignFile(FFile, Opendialog.FileName);
{$I-}
        Reset(FFile);
{$I+}
        if IOResult = 0 then begin K:=0; Nr:=1; // Inc( Nr );
          Readln( FFile,NoStations );
          for I:=1 to NoStations do begin Inc( Nr );
            readln( FFile ); Inc( Nr );        // Skip description of this line
            readln( FFile,NoPoints );
            Spline:=TFreeSpline.Create( FreeShip.Surface );
            Spline.Capacity:=NoPoints;
            ValidStation:=NoPoints>1;
            for J:=1 to Nopoints do begin
//            try
                Inc( Nr ); Read( FFile, P.X,P.Y,P.Z );
                if not EOLN(FFile) then Readln(FFile,K)
                                   else begin K:=0; Readln( FFile ); end;
//            except
//              ShowMessage( Userstring(132)+#32+IntToStr(Nr) );
//            end;
              Spline.Add(P);
              if J>1 then ValidStation:=abs(P.X-Spline.Point[0].X) < 1e-4;
              if (K=1) and (J<>1) and (J<>NoPoints) then Spline.Knuckle[J-1]:=True;
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
      MaxZ:=0.0;                   // first sort the stations from aft to front
      for I:=1 to Frames.Count-1 do
      for J:=I+1 to Frames.Count do
       if TFreeSpline(Frames[J-1]).Point[0].X
        < TFreeSpline(Frames[I-1]).Point[0].X then Frames.Exchange(I-1,J-1);
                              // Determine the minimum and maximum Z values for
                           // each station and the overall min/max z-coordinate
      Setlength(MinMaxData, Frames.Count);
      for I:=1 to Frames.Count do begin
        Spline:=Frames[I-1];
        MinMaxData[I-1].MinZ:=Spline.Point[0].Z;
        MinMaxData[I-1].MaxZ:=Spline.Point[Spline.NumberOfPoints-1].Z;
        if I = 1 then begin MinZ:=Spline.Point[0].Z;
                            MaxZ:=MinZ;
        end;
        if Spline.Point[0].Z < MinZ then MinZ:=Spline.Point[0].Z;
        if Spline.Point[Spline.NumberOfPoints-1].Z > MaxZ
           then MaxZ:=Spline.Point[Spline.NumberOfPoints-1].Z;
        Marker:=TFreeMarker.Create(FreeShip.Surface);
        Marker_Add(Marker);
        Marker.Capacity:=Spline.NumberOfPoints;
        for J:=1 to Spline.NumberOfPoints do begin
          Marker.Add(Spline.Point[J-1]);
          Marker.Knuckle[J-1]:=Spline.Knuckle[J-1];
        end;
      end;
           // extend all stations upwards and downwards to the min/max z-values
      for I:=1 to Frames.Count do begin Spline:=Frames[I-1]; // extend downwards to Z=0
        if Spline.Point[0].Z > MinZ then begin
          P:=Spline.Point[0];
          P.Z:=MinZ;
          Spline.Insert(0, P);
          Spline.Knuckle[1]:=True;
        end;                                                  // extend upwards
        if Spline.Point[Spline.NumberOfPoints-1].Z < MaxZ then begin
          P:=Spline.Point[Spline.NumberOfPoints-1];
          P.Z:=MaxZ;
          Spline.Add(P);
          Spline.Knuckle[Spline.NumberOfPoints-2]:=True;
        end;
      end;

      NoPoints:=10; // resample all stations to a user defined number of points
      NoPoints:=StrToInt(InputBox('', Userstring(135)+':', IntToStr(NoPoints)));
      if NoPoints<5 then NoPoints:=5;
      Setlength(ControlPoints, Frames.Count);
      for I:=1 to Frames.Count do begin
        Spline:=Frames[I-1];
        NewSpline:=TFreeSpline.Create(FreeShip.Surface);
        NewSpline.Capacity:=NoPoints;
        for J:=1 to NoPoints do begin
          P:=Spline.Value((J-1) / (NoPoints-1));
          NewSpline.Add(P);
        end;                                // correct for any present knuckles
        for J:=1 to Spline.NumberOfPoints do
        if Spline.Knuckle[J-1] then begin Index:=0; // find the nearest point on resampled spline
          for K:=2 to NewSpline.NumberOfPoints-1 do
          if Distance3D(Spline.Point[J-1], NewSpline.Point[K-1]) <
             Distance3D(Spline.Point[J-1], NewSpline.Point[index]) then Index:=K-1; // replace by the old coordinate
          NewSpline.Point[index]:=Spline.Point[J-1];
          NewSpline.Knuckle[index]:=True;
        end;
                                            // Delete the old station
        FreeAndNil(Spline);                 // and replace by the resampled one
        Frames[I-1]:=NewSpline; // Add the controlpoints to the subdivision surface
        Setlength(ControlPoints[I-1], NewSpline.NumberOfPoints);
        for J:=1 to NewSpline.NumberOfPoints do
          ControlPoints[I-1][J-1] :=
            FreeShip.Surface.AddControlPoint(NewSpline.Point[J-1]);
      end;                                          // Add the new controlfaces
      Points:=TFasterListTFreeSubdivisionControlPoint.Create;
      for I:=2 to Frames.Count do
        for J:=2 to NoPoints do
        begin
          Points.Clear;
          Points.Add(ControlPoints[I-1][J-1]);
          Points.Add(ControlPoints[I-1][J-2]);
          Points.Add(ControlPoints[I-2][J-2]);
          Points.Add(ControlPoints[I-2][J-1]);
          FreeShip.Surface.AddControlFace(Points, True);
        end;

      Points.Clear;                        // Try to reconnect the contourline
      P1:=nil;
      P2:=nil;
      for I:=1 to Frames.Count do begin
        for J:=1 to NoPoints do
          if abs(ControlPoints[I-1][J-1].Coordinate.Z-MinMaxData[I-1].MinZ)<1e-7
          then begin
            P2:=ControlPoints[I-1][J-1];
            if P2.Coordinate.Y <> 0.0 then begin  // Force point to centerplane
              P:=P2.Coordinate;
              P.Y:=0;
              P2.Coordinate:=P;
            end;
            break;
          end else Points.Add(ControlPoints[I-1][J-1]); // store to be deleted later
        if (P1 <> nil) and (P2 <> nil) then begin
          Edge:=FreeShip.Surface.EdgeExists(P1, P2) as TFreeSubdivisionControlEdge;
          if Edge <> nil then Edge.Crease:=True
          else begin // Find out if P1 and P2 share the same controlface
            for J:=1 to P1.NumberOfFaces do
              if P2.IndexOfFace(P1.Face[J-1]) <> -1 then begin
                Face:=P1.Face[J-1] as TFreeSubdivisionControlFace;
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
      for I:=1 to Frames.Count do begin
        for J:=1 to NoPoints do
          if abs(ControlPoints[I-1][J-1].Coordinate.Z-MinMaxData[I-1].MaxZ)<1e-7
          then begin P2:=ControlPoints[I-1][J-1];
            K:=J+1;
            while K <= NoPoints do begin
              Points.Add(ControlPoints[I-1][K-1]); Inc(K);
            end;
            break;
          end;
        if (P1 <> nil) and (P2 <> nil) then begin
          Edge:=FreeShip.Surface.EdgeExists(P1, P2) as TFreeSubdivisionControlEdge;
          if Edge <> nil then Edge.Crease:=True
          else begin        // Find out if P1 and P2 share the same controlface
            for J:=1 to P1.NumberOfFaces do
              if P2.IndexOfFace(P1.Face[J-1]) <> -1 then begin
                Face:=P1.Face[J-1] as TFreeSubdivisionControlFace;
                Edge:=Face.InsertEdge(P1, P2, IsFaceDeleted);
                if Edge <> nil then Edge.Crease:=True;
              end;
            DelayedDestroyList.DestroyAll;
          end;
        end;
        P1:=P2;
        P2:=nil;
      end;
      // Delete all controlpoints beneath the contourline and above the deckline
      for J:=1 to Points.Count do begin
        P1:=Points[J-1];
        if FreeShip.Surface.PointExists(P1) then P1.Delete;
      end;
      for I:=1 to FreeShip.Surface.NumberOfControlPoints do
        if FreeShip.Surface.ControlPoint[I-1].NumberOfFaces = 1 then
          FreeShip.Surface.ControlPoint[I-1].VertexType:=svCorner;
      FreeAndNil(Points);
      FreeShip.FileChanged:=True;
    end;
    FreeShip.Draw;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo( self );
    // Destroy allocated stations
    for I:=1 to Frames.Count do begin
      Spline:=Frames[I-1];
      FreeAndNil(Spline);
    end;
    FreeAndNil(Frames);
  end;
  FreeAndNil(OpenDialog);
end;{TFreeEdit.ImportFrames}
//
// imports a number of longitudinally lines and creates developable surfaces
// between each two subsequent chines
//
procedure TFreeShip.ImportChines
( Np: integer; Chines: TFasterListTFreeSpline );
var
  I, J: integer;
  P, Min, Max: T3DVector;
  Pts,Pts2,Tmp: TFasterListTFreeSubdivisionControlPoint;
  Points: array of array of TFreeSubdivisionControlPoint;
  Point: TFreeSubdivisionControlPoint;
  Edge: TFreeSubdivisionControlEdge;
  vLayer: TFreeSubdivisionLayer;
  Spline: TFreeSpline;
  vMarker: TFreeMarker;
  Matrix,Inv,OrgPts,NewPts: TFreeMatrix;
  Curve: TFreeSubdivisionControlCurve;
begin
//  try
    for I:=1 to Chines.Count-1 do begin
      if I <= Surface.NumberOfLayers then vLayer:=Surface.Layer[I-1]
                                     else vLayer:=Surface.AddNewLayer;
      vLayer.Name:=Userstring(186)+#32+IntToStr(I);
      vLayer.Developable:=True;
    end;
    // add special layer to close the hull at centerline
    vLayer:=Surface.AddNewLayer;
    vLayer.Name:=Userstring(187);
    Setlength(Points, Np);

    // Prepare matrices
    Matrix:=TFreeMatrix.Create;
    Matrix.SetSize(Np, Np);
    Matrix.Fill(0.0);
    Matrix.Value[0, 0]:=1.0;
    for I:=2 to Np-1 do begin
      Matrix.Value[I-1,I-2]:=1 / 6;
      Matrix.Value[I-1,I-1]:=2 / 3;
      Matrix.Value[I-1,I]:=1 / 6;
    end;
    Matrix.Value[Np-1, Np-1]:=1.0;                 // Invert matrix
    Inv:=Matrix.Invert;
    FreeAndNil(Matrix);

    OrgPts:=TFreeMatrix.Create;
    OrgPts.SetSize( 3,Np );

    for I:=1 to Np do Setlength(Points[I-1], Chines.Count);
    for I:=1 to Chines.Count do begin
      Spline:=Chines[I-1];
      OrgPts.Fill(0.0);
      for J:=1 to Np do begin
        P:=Spline.Value((J-1) / (Np-1));
        OrgPts.Value[J-1, 0]:=P.X;
        OrgPts.Value[J-1, 1]:=P.Y;
        OrgPts.Value[J-1, 2]:=P.Z;
      end;
      // calculate new points
      NewPts:=Inv.Multiply(OrgPts);
      for J:=1 to Np do begin
        P.X:=NewPts.Value[J-1, 0];
        P.Y:=NewPts.Value[J-1, 1];
        if P.Y < 0 then P.Y:=0;
        P.Z:=NewPts.Value[J-1, 2];
        if (I = 1) and (J = 1) then begin
          Min:=P;
          Max:=Min;
        end
        else MinMax(P, Min, Max);
        Points[J-1][I-1]:=Surface.AddControlPoint(P);
      end;
      FreeAndNil(NewPts);
    end;
    FreeAndNil(OrgPts);    // Delete inverted matrix
    FreeAndNil(Inv);       // Add chines as markers
    for I:=1 to Chines.Count do begin
      Spline:=Chines[I-1];
      vMarker:=TFreeMarker.Create(Surface);
      vMarker.FOwner:=self;
      Edit.Marker_Add(vMarker);
      for J:=1 to Spline.NumberOfPoints do begin
        vMarker.Add(Spline.Point[J-1]);
        vMarker.Knuckle[J-1]:=Spline.Knuckle[J-1];
      end;
    end;                    // Setup controlfaces
    Pts:=TFasterListTFreeSubdivisionControlPoint.Create;
    for I:=2 to Np do
      for J:=2 to Chines.Count do begin
        Pts.Clear;
        Point:=Points[I-1][J-1];
        if Pts.IndexOf(Point) = -1 then Pts.Add(Point);
        Point:=Points[I-2][J-1];
        if Pts.IndexOf(Point) = -1 then Pts.Add(Point);
        Point:=Points[I-2][J-2];
        if Pts.IndexOf(Point) = -1 then Pts.Add(Point);
        Point:=Points[I-1][J-2];
        if Pts.IndexOf(Point) = -1 then Pts.Add(Point);
        if Pts.Count > 2 then
          Surface.AddControlFace(Pts, True, Surface.Layer[J-2]);
      end;

    for I:=2 to Np do
      for J:=1 to Chines.Count do begin
        Edge:=Surface.EdgeExists(Points[I-2][J-1], Points[I-1][J-1])
                as TFreeSubdivisionControlEdge;
        if Edge <> nil then Edge.Crease:=True;
      end;

    // Add controlcurves
    for J:=1 to Chines.Count do begin
      Curve:=TFreeSubdivisionControlCurve.Create(Surface);
      Surface.AddControlCurve(Curve);
      for I:=1 to Np do begin
        Curve.AddPoint(Points[I-1][J-1]);
        if I > 1 then begin
          Edge:=Surface.EdgeExists(Points[I-2][J-1], Points[I-1][J-1]) as
            TFreeSubdivisionControlEdge;
          if Edge <> nil then Edge.Curve:=Curve;
        end;
      end;
    end;

    // Check for stem, keel and stern points to be closed
    Pts.Clear;
    // first stern
    for I:=Chines.Count downto 2 do Pts.Add(Points[Np-1][I-1]);
    // then keel
    for I:=Np downto 1 do Pts.Add(Points[I-1][0]);
    // and finally stem
    for I:=2 to Chines.Count do Pts.Add(Points[0][I-1]);
    Pts2:=TFasterListTFreeSubdivisionControlPoint.Create;
    for I:=1 to Pts.Count do begin
      Point:=Pts[I-1];
      P:=Point.Coordinate;
      if P.Y <> 0.0 then begin
        P.Y:=0;
        Point:=Surface.AddControlPoint(P);
        if Point.Coordinate.Y <> 0.0 then Point.Coordinate:=P;
        Pts2.Add(Point);
      end else Pts2.Add(Point);
    end;
    Tmp:=TFasterListTFreeSubdivisionControlPoint.Create;
    for I:=2 to Pts.Count do begin
      Tmp.Clear;
      if Tmp.IndexOf(Pts2[I-1]) = -1 then Tmp.Add(Pts2[I-1]);
      if Tmp.IndexOf(Pts2[I-2]) = -1 then Tmp.Add(Pts2[I-2]);
      if Tmp.IndexOf(Pts[ I-2]) = -1 then Tmp.Add(Pts[I-2]);
      if Tmp.IndexOf(Pts[ I-1]) = -1 then Tmp.Add(Pts[I-1]);
      if Tmp.Count > 2 then Surface.AddControlFace(Tmp, False, vLayer);
    end;

    // Now check if there are any edges on the bottom panel that are created by extruding the
    // bottom points and whose crease properties are set to true. This causes undesired knuckle in the bottompanel
    {
      for I:=Np-1 downto 2 do
      begin
         Point:=Points[I-1][0];
         if Point.Coordinate.Y>0 then
         begin
            for J:=1 to point.NumberOfEdges do
            begin
               Edge:=Point.Edge[J-1] as TFreeSubdivisionControlEdge;
               if ((Edge.Crease) and (Edge.StartPoint=Point) and (abs(Edge.EndPoint.Coordinate.Y)<1e-7)) or
                  ((Edge.Crease) and (Edge.EndPoint=Point) and (abs(Edge.StartPoint.Coordinate.Y)<1e-7)) then Edge.Crease:=False;
            end;
         end;
      end;
    }
    // set transom as knuckle
    for J:=2 to Chines.Count do begin
      Edge:=Surface.EdgeExists(Points[Np-1][J-2], Points[Np-1][J-1]) as
        TFreeSubdivisionControlEdge;
      if Edge <> nil then Edge.Crease:=True;
    end;
    // Delete unused layers;
    Edit.Layer_DeleteEmpty(True);
    // delete unused controlpoints
    for I:=Surface.NumberOfControlPoints downto 1 do
      if Surface.ControlPoint[I-1].NumberOfFaces = 0 then
         Surface.ControlPoint[I-1].Delete;
    FreeAndNil( Tmp  );
    FreeAndNil( Pts2 );
    FreeAndNil( Pts  );
//  finally
    Extents(Min, Max);
    //ProjectSettings.ProjectWaterDensity:=1.0;
    ProjectSettings.ProjectBeam:=2 * Max.Y;
    ProjectSettings.ProjectLength:=Max.X-Min.X;
    ProjectSettings.ProjectDraft:=1.0;
    Built:=False;
    Precision:=fpHigh;
    Draw;
    FileChanged:=True;
    for I:=1 to Chines.Count do begin
      Spline:=Chines[I-1];
      FreeAndNil(Spline);
    end;
//  end;
end;
//
// Imports a number of curves and fits a surface;
//
procedure TFreeEdit.File_ImportSurface;
var
  OpenDialog: TOpenDialog;
  I, J, Nr, Cols, Rows: integer;
  Str: AnsiString;
  FFile: TextFile;
  Spline,NewSpline: TFreeSpline;
  P: T3DVector;
  Points: array of array of T3DVector;
  ControlPoints: array of array of TFreeSubdivisionControlPoint;
  P1: TFreeSubdivisionControlPoint;
  Curves,LongCurves: TFasterListTFreeSpline;
  Pts: TFasterListTFreeSubdivisionControlPoint;
  Matrix,ColMatrix,RowMatrix,OrgPts,NewPts: TFreeMatrix;
  UnitType: TFreeUnitType;
  Marker: TFreeMarker;
  PrevCursor: TCursor;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter('3D text file',['txt']);
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
        if IOResult = 0 then begin Nr:=0;
//          try            // first read unit information; 0=metric, 1=imperial
            readln( FFile,I );
            if I in [0,1] then UnitType:=TFreeUnitType(I)
                          else MessageDlg(Userstring(108),mtError,[mbOK],0);
            Spline:=TFreeSpline.Create(FreeShip.Surface);
            repeat
              Readln(FFile, Str);
              repeat
                I:=Pos(#9, Str);
                if I <> 0 then str[I]:=#32;
              until I = 0;
              Inc(Nr);
              Str:=Trim(Uppercase(Str));
              if (Str <> '') and (Str <> 'EOF') then begin
                P.X:=GetFloat( Str);
                P.Y:=GetFloat( Str);
                P.Z:=GetFloat( Str);
                Spline.Add(P);
                Str:=#32;
              end else
              if Str = '' then begin
                if Spline.NumberOfPoints > 1 then Curves.Add(Spline)
                                             else FreeAndNil(Spline);
                Spline:=TFreeSpline.Create(FreeShip.Surface);
              end;
            until (Str = 'EOF') or (EOF(FFile));
            if Spline.NumberOfPoints > 1 then Curves.Add(Spline)
                                         else FreeAndNil(Spline);
//          except
//            MessageDlg(Userstring(132)+#32+IntToStr(Nr), mtError, [mbOK], 0);
//          end;
          CloseFile(FFile);
        end else MessageDlg(Userstring(132),mtError,[mbOK],0);
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
        Cols:=StrToInt(InputBox('', Userstring(137)+':', IntToStr(Cols)));
        if Cols < 3 then Cols:=3;
        Rows:=10;
        Rows:=StrToInt(InputBox('', Userstring(138)+':', IntToStr(Rows)));
        if Rows < 3 then Rows:=3;

        // Build number of desired longitudinal curves
        LongCurves:=TFasterListTFreeSpline.Create;
        for I:=1 to Rows do begin
          NewSpline:=TFreeSpline.Create(FreeShip.Surface);
          LongCurves.Add(NewSpline);
          Newspline.Capacity:=Curves.Count;
          for J:=1 to Curves.Count do begin
            Spline:=Curves[J-1];
            Newspline.Add(Spline.Value((I-1) / (Rows-1)));
          end;
        end;
        for I:=1 to Curves.Count do begin
          Spline:=Curves[I-1];
          Marker:=TFreeMarker.Create(FreeShip.Surface);
          Marker.Capacity:=Spline.NumberOfPoints;
          for J:=1 to Spline.NumberOfPoints do
            Marker.Add(Spline.Point[J-1]);
          Marker_Add(Marker);
          FreeAndNil(Spline);
        end;
        FreeAndNil(Curves);

        // build matrix for column interpolation
        Matrix:=TFreeMatrix.Create;
        Matrix.SetSize(Cols, Cols);
        Matrix.Fill(0.0);
        Matrix.Value[0,0]:=1.0;
        for I:=2 to Cols-1 do begin
          Matrix.Value[I-1,I-2]:=1 / 6;
          Matrix.Value[I-1,I-1]:=2 / 3;
          Matrix.Value[I-1,I]:=1 / 6;
        end;
        Matrix.Value[Cols-1, Cols-1]:=1.0;
        Colmatrix:=Matrix.Invert;

        Matrix.SetSize(Rows, Rows);
        Matrix.Fill(0.0);
        Matrix.Value[0, 0]:=1.0;
        for I:=2 to Rows-1 do begin
          Matrix.Value[I-1,I-2]:=1 / 6;
          Matrix.Value[I-1,I-1]:=2 / 3;
          Matrix.Value[I-1,I]:=1 / 6;
        end;
        Matrix.Value[Rows-1, Rows-1]:=1.0;        // Invert matrix
        Rowmatrix:=Matrix.Invert;
        FreeAndNil(Matrix);
        Setlength(Points,Rows);                   // build initial point grid
        for I:=1 to Rows do begin
          setlength(Points[I-1], Cols);
          Spline:=LongCurves[I-1];
          OrgPts:=TFreeMatrix.Create;
          OrgPts.SetSize(3,Cols);
          for J:=1 to Cols do begin
            P:=Spline.Value((J-1) / (Cols-1));
            OrgPts.Value[J-1,0]:=P.X;
            OrgPts.Value[J-1,1]:=P.Y;
            OrgPts.Value[J-1,2]:=P.Z;
          end;
          NewPts:=ColMatrix.Multiply(OrgPts);
          for J:=1 to Cols do begin
            P.X:=NewPts.Value[J-1,0];
            P.Y:=NewPts.Value[J-1,1];
            if (OrgPts.Value[J-1,1]>=0.0) and (P.Y<0.0) then P.Y:=0.0;
            P.Z:=NewPts.Value[J-1,2];
            Points[I-1][J-1]:=P;
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
            P:=Points[J-1][I-1];
            OrgPts.Value[J-1, 0]:=P.X;
            OrgPts.Value[J-1, 1]:=P.Y;
            OrgPts.Value[J-1, 2]:=P.Z;
          end;
          NewPts:=RowMatrix.Multiply(OrgPts);
          for J:=1 to Rows do begin
            P.X:=NewPts.Value[J-1, 0];
            P.Y:=NewPts.Value[J-1, 1];
            if (OrgPts.Value[J-1,1] >= 0.0) and (P.Y < 0.0) then P.Y:=0.0;
            P.Z:=NewPts.Value[J-1, 2];
            Points[J-1][I-1]:=P;
          end;
          FreeAndNil(OrgPts);
          FreeAndNil(NewPts);
        end;
        FreeAndNil(RowMatrix);
                                                         // delete long. curves
        for I:=1 to LongCurves.Count do begin
          Spline:=LongCurves[I-1];
          FreeAndNil(Spline);
        end;
        FreeAndNil(LongCurves);
                                                       // import actual surface
        Setlength(ControlPoints, Rows);
        for I:=1 to Rows do begin
          Setlength(ControlPoints[I-1], Cols);
          for J:=1 to Cols do begin
            ControlPoints[I-1][J-1] :=
              TFreesubdivisionControlPoint.Create(FreeShip.Surface);
            FreeShip.Surface.AddControlPoint(ControlPoints[I-1][J-1]);
            ControlPoints[I-1][J-1].Coordinate:=Points[I-1][J-1];
            //ControlPoints[I-1][J-1]:=FreeShip.Surface.AddControlPoint(Points[I-1][J-1]);
          end;
        end;
        Pts:=TFasterListTFreeSubdivisionControlPoint.Create;
        for I:=2 to Rows do
          for J:=2 to Cols do begin
            Pts.Clear;
            P1:=ControlPoints[I-2][J-2];
            Pts.Add(P1);
            P1:=ControlPoints[I-2][J-1];
            if Pts.IndexOf(P1) = -1 then Pts.Add(P1);
            P1:=ControlPoints[I-1][J-1];
            if Pts.IndexOf(P1) = -1 then Pts.Add(P1);
            P1:=ControlPoints[I-1][J-2];
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

procedure TFreeEdit.File_Import_MichletWaves;
var
  FFile: TextFile;
  Grid: array of array of T3DVector;
  CtrlGrid: array of array of TFreeSubdivisionControlPoint;
  I,J,K, Nx,Ny, DecrY: integer; AllZero: boolean;
  MultFact,Angle: TFloatType;
  Str,Tmp,Speed: AnsiString;
  P, Min, Max: T3DVector;
  XArray: array of TFloatType;
  Pts: TFasterListTFreeSubdivisionControlPoint;
  Layer: TFreeSubdivisionLayer;
  OpenDialog: TOpenDialog;
  PrevCursor: TCursor;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory; //+ConfigDirectory
  OpenDialog.Filter:=createDialogFilter('Michlet wave elevations file',['mlt']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
    assignfile( FFile,Opendialog.Filename );
    Reset(FFile);
    Readln(FFile, Str);
    Nx:=0;
    Ny:=0;
    Speed:='';
    if Str = 'RECTANGULAR PATCH' then begin
      readln(FFile);
      readln(FFile, Speed);
      readln(FFile);
      //Read X0, X1, Nx
      Readln(FFile, Str);                      // X0
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J-1);
      Delete(Str, 1, J);                       // X1
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J-1);
      Delete(Str, 1, J);                       // Nx
      Nx:=StrToInt(Str);
      //Read Y0, Y1, Ny
      Readln(FFile, Str);
      Readln(FFile, Str);                      // Y0
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J-1);
      Delete(Str, 1, J);                       // Y1
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J-1);
      Delete(Str, 1, J);                       // Ny
      Ny:=StrToInt(Str);

      for I:=1 to 5 do readln(Ffile);

      Ny:=Ny div 2;                            // use only port half
      Setlength(XArray, Nx);                   // Read X distances
      Readln(FFile, Str);
      J:=Pos(',', Str);
      if J <> 0 then Delete(Str, 1, J);
      for I:=1 to Nx do begin
        Str:=Trim(Str);
        J:=Pos(',', Str);
        if J <> 0 then begin
          Tmp:=Copy(Str, 1, J-1);
          XArray[I-1]:=GetFloat(Tmp);
          Delete(Str, 1, J);
        end
        else if I = Nx then XArray[I-1]:=GetFloat(Str);
      end;

      Setlength(Grid, Ny);                  // Now read all the wave elevations
      for J:=1 to Ny do begin
        Readln(FFile, Str);
        Setlength(Grid[J-1], Nx);
        for I:=0 to Nx do begin
          Str:=Trim( Str );
          K:=Pos(',', Str);
          if K <> 0 then begin
            Tmp:=Copy(Str, 1, K-1);
            Delete(Str, 1, K);
            if I = 0 then begin
              if J = Ny then P.Y:=0
                        else P.Y:=GetFloat(Tmp);
            end else begin
              P.X:=XArray[I-1];
              P.Z:=GetFloat(Tmp);
              Grid[J-1][I-1]:=P;
            end;
          end else
          if I = Nx then begin
            P.X:=XArray[I-1];
            P.Z:=GetFloat(Tmp);
            Grid[J-1][I-1]:=P;
          end;
        end;
      end;
    end else
    if Str = 'SECTORIAL PATCH' then begin
      readln(FFile);
      readln(FFile, Speed);
      readln(FFile);
                                                    //Read Nx
      Readln(FFile, Str);                           // X0
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J-1);
      Delete(Str, 1, J);                            // X1
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J-1);
      Delete(Str, 1, J);                            // Nx
      Nx:=StrToInt(Str);
                                                    //Read Y0, Y1, Ny
      Readln(FFile, Str);
      Readln(FFile, Str);                           // Y0
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J-1);
      Delete(Str, 1, J);                            // Y1
      Str:=Trim(Str);
      J:=Pos(',', Str);
      Tmp:=Copy(Str, 1, J-1);
      Delete(Str, 1, J);                            // Ny
      Ny:=StrToInt(Str);

      for I:=1 to 13 do readln(Ffile);
      Ny:=(Ny-1);                                   // use only port half
      Setlength(XArray, Nx);                        // Read Radia
      Readln(FFile, Str);
      J:=Pos(',', Str);
      if J <> 0 then Delete(Str, 1, J);
      for I:=1 to Nx do begin
        Str:=Trim(Str);
        J:=Pos(',', Str);
        if J <> 0 then begin
          Tmp:=Copy(Str, 1, J-1);
          XArray[I-1]:=GetFloat(Tmp);
          Delete(Str, 1, J);
        end
        else if I = Nx then XArray[I-1]:=GetFloat(Str);
      end;

      Setlength(Grid, Ny);                  // Now read all the wave elevations
      angle:=0;
      for J:=1 to Ny do begin
        Readln(FFile, Str);
        Setlength(Grid[J-1], Nx);
        for I:=0 to Nx do begin
          Str:=Trim(Str);
          K:=Pos(',', Str);
          if K <> 0 then begin
            Tmp:=Copy(Str, 1, K-1);
            Delete(Str, 1, K);
            if I = 0 then begin
              if J = Ny then Angle:=0
              else Angle:=-GetFloat(Tmp);
            end else begin
              P.X:=XArray[I-1] * Cos(DegToRad(Angle));
              P.Y:=XArray[I-1] * Sin(DegToRad(Angle));
              P.Z:=GetFloat(Tmp);
              Grid[J-1][I-1]:=P;
            end;
          end else
          if I = Nx then begin
            P.X:=XArray[I-1] * Cos(DegToRad(Angle));
            P.Y:=XArray[I-1] * Sin(DegToRad(Angle));
            //P.X:=XArray[I-1];
            P.Z:=GetFloat(Tmp);
            Grid[J-1][I-1]:=P;
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
          Grid[I-1][J-1].Z:=Grid[I-1][J-1].Z * MultFact;
          if abs(Grid[I-1][J-1].Z) > 1e-3 then begin
            AllZero:=False;
            break;
          end;
        end;
        if AllZero then Inc(DecrY);
      end;
      if DecrY > 0 then Dec(DecrY);

      // Add controlpoints
      Setlength(CtrlGrid, Ny);
      for I:=1+DecrY to Ny do begin
        Setlength(CtrlGrid[I-1], Nx);
        for J:=1 to Nx do begin
          if FreeShip.ProjectSettings.ProjectUnits = fuImperial then begin // scale to feet
            Grid[I-1][J-1].X:=Grid[I-1][J-1].X / Foot;
            Grid[I-1][J-1].Y:=Grid[I-1][J-1].Y / Foot;
            Grid[I-1][J-1].Z:=Grid[I-1][J-1].Z / Foot;
          end;
          Grid[I-1][J-1].X := 0.5 * FreeShip.ProjectSettings.ProjectLength-Grid[I-1][J-1].X;
          Grid[I-1][J-1].Z := Min.Z+FreeShip.ProjectSettings.ProjectDraft+Grid[I-1][J-1].Z;
          CtrlGrid[I-1][J-1]:=TFreeSubdivisionControlPoint.Create(FreeShip.Surface);
          FreeShip.Surface.AddControlPoint(CtrlGrid[I-1][J-1]);
          CtrlGrid[I-1][J-1].Coordinate:=Grid[I-1][J-1];
        end;
      end;

      Pts:=TFasterListTFreeSubdivisionControlPoint.Create;
      Layer:=FreeShip.Surface.AddNewLayer;
      if Speed <> '' then Layer.Name:='Michlet waves, speed='+speed+' m/s'
                     else Layer.Name:='Michlet wave elevations, speed='+speed+' m/s';
      Layer.Color:=clAqua;
      Layer.UseInHydrostatics:=False;
      Layer.ShowInLinesplan:=False;
      Layer.UseForIntersections:=False; // Add faces to controlpoints
      for I:=DecrY+2 to Ny do begin
        Setlength(CtrlGrid[I-1], Nx);
        for J:=2 to Nx do begin Pts.Clear;
          Pts.Add(CtrlGrid[I-1][J-1]);
          Pts.Add(CtrlGrid[I-1][J-2]);
          Pts.Add(CtrlGrid[I-2][J-2]);
          Pts.Add(CtrlGrid[I-2][J-1]);
          FreeShip.Surface.AddControlFace(Pts, True, Layer);
        end;
      end;                              // set cornerpoints
      for I:=1+DecrY to Ny do
      for J:=1 to Nx do
       if CtrlGrid[I-1][J-1].NumberOfFaces = 1 then
          CtrlGrid[I-1][J-1].VertexType:=svCorner;
      FreeAndNil(Pts);
      FreeShip.Draw;
      Screen.Cursor:=PrevCursor;
    end else MessageDlg( Userstring(102),mtError,[mbOK],0 );
    CloseFile( FFile );
    FreeShip.FileChanged:=True;
    if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
  end;
  FreeAndNil(OpenDialog);
end;{TFreeEdit.File_Import_MichletWaves}
//
// imports a Carene XYZ file and creates a multichine boat with developable surfaces
//
procedure TFreeEdit.File_ImportCarene;
var
  OpenDialog: TOpenDialog;
  Answer: word;
  Str: AnsiString;
  I,LineNr: integer;
  P: T3DVector;
  FFile: TextFile;
  Chines: TFasterListTFreeSpline;
  Spline: TFreeSpline;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter( 'Carene XYZ files',['xyz'] );
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin

  Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
  if (Answer=mrCancel) or FreeShip.FileChanged then begin FreeAndNil( OpenDialog ); exit; end;
 (*                                                                     ////+++
    if FreeShip.FileChanged then begin
      Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104), mtConfirmation, [mbYes, mbNo, mbCancel], 0);
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
        FreeShip.ProjectSettings.FProjectName:=Str;
        Chines:=TFasterListTFreeSpline.Create;
        while not EOF(FFile) do
        begin
          Readln(FFile, Str);
          Inc(LineNr);
          if Pos('LINE', Str) = 1 then begin         // New chine skip one line
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
        FreeShip.Filename:=ChangeFileExt( Opendialog.FileName,'.fbm' );
        FreeShip.ModelIsLoaded:=True;
        FreeShip.RebuildModel;
//    end;
    end else MessageDlg(Userstring(106), mtError, [mbOK], 0);
  end;
  FreeAndNil(OpenDialog);
end;

// Import chines from a textfile and fit a surface through them

procedure TFreeEdit.File_ImportChines;
var
  OpenDialog: TOpenDialog;
  Answer: word;
  Str: AnsiString;
  I,LineNr: integer;
  P: T3DVector;
  FFile: TextFile;
  Chines: TFasterListTFreeSpline;
  Spline: TFreeSpline;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter(rsTextFile, ['txt']);
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
                                       else FreeAndNil( Spline );
//        except
//          MessageDlg('Error on line '+IntToStr(LineNr)+' in file ' +
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
//
// Import a Freeship Exchange Format (FEF) file
//
(*
procedure TFreeEdit.File_ImportFEF;
var OpenDialog : TOpenDialog;
    Answer     : word;
    Strings    : TStringList;
    Str        : string;
    LineNr,I   : integer;
begin
   OpenDialog:=TOpenDialog.Create(FreeShip);
   OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
   OpenDialog.Filter:='FREE!ship Exchange Format file ( *.Fef )|*.Fef';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      if FreeShip.FileChanged then
      begin
         Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
         if Answer=mrCancel then
         begin
            OpenDialog.Destroy;
            exit;
         end;
         if Answer=mrYes then
         begin
            File_SaveAs;
            if FreeShip.FileChanged then
            begin
               // Apparently saving was not successfull, abort
               OpenDialog.Destroy;
               exit;
            end;
         end;
      end;
      FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      CreateUndoObject(Userstring(109),True);
      FreeShip.Clear;
      Strings:=TStringList.Create;
      Strings.LoadFromFile(OpenDialog.Filename);
      LineNr:=-1;
      // Read general information and mainparticulars

      inc(LineNr); FreeShip.ProjectSettings.FProjectName:=Strings[LineNr];
      inc(LineNr); FreeShip.ProjectSettings.FProjectDesigner:=Strings[LineNr];
      inc(LineNr); FreeShip.ProjectSettings.FProjectFileCreatedBy:=Strings[LineNr];
      inc(LineNr); FreeShip.ProjectSettings.FProjectComment:=Strings[LineNr];
      Inc(LineNr); Str:=Strings[LineNr];
      FreeShip.ProjectSettings.ProjectLength:=GetFloat(Str);
      FreeShip.ProjectSettings.ProjectBeam:=GetFloat(Str);
      FreeShip.ProjectSettings.ProjectDraft:=GetFloat(Str);
      FreeShip.ProjectSettings.ProjectWaterDensity:=GetFloat(Str);
      FreeShip.ProjectSettings.ProjectAppendageCoefficient:=GetFloat(Str);
      I:=getInteger(Str);
      FreeShip.ProjectSettings.FProjectUnits:=TFreeUnitType( I );
      {FreeShip.ProjectSettings.FMainparticularsHasBeenset} getBoolean( Str );
      I:=getInteger(Str);
      FreeShip.FPrecision:=TFreePrecisionType(I);
      FreeShip.Surface.ImportFEFFile( Strings,LineNr );
      Strings.Destroy;
      FreeShip.FileName:=Opendialog.FileName;
//    FreeShip.Build:=False;
      FreeShip.RebuildModel;
      if Assigned(FreeShip.OnUpdateGeometryInfo) then FreeShip.OnUpdateGeometryInfo(self);
   end;
   OpenDialog.Destroy;
end; {TFreeEdit.File_ImportFEF}
*)
procedure TFreeEdit.File_ImportFEF;
var
  OpenDialog: TOpenDialog;
  Answer: word;
  Strings: TStringList;
  Str: AnsiString;
  LineNr, I: integer;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter('FREE!ship Exchange Format file',['fef']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
    Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
    if (Answer=mrCancel) or FreeShip.FileChanged then begin FreeAndNil( OpenDialog ); exit; end;
    FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
    CreateUndoObject(Userstring(109),True);
    FreeShip.Clear;
    Strings:=TStringList.Create;
    Strings.LoadFromFile(OpenDialog.Filename);
    LineNr:=-1;                 // Read general information and mainparticulars
    Inc(LineNr); FreeShip.ProjectSettings.FProjectName:=Strings[LineNr];
    Inc(LineNr); FreeShip.ProjectSettings.FProjectDesigner:=Strings[LineNr];
    Inc(LineNr); FreeShip.ProjectSettings.FProjectFileCreatedBy:=Strings[LineNr];
    Inc(LineNr); FreeShip.ProjectSettings.FProjectComment:=Strings[LineNr];
    Inc(LineNr); Str:=Strings[LineNr];
    FreeShip.ProjectSettings.ProjectLength:=GetFloat(Str);
    FreeShip.ProjectSettings.ProjectBeam:=GetFloat(Str);
    FreeShip.ProjectSettings.ProjectDraft:=GetFloat(Str);
    FreeShip.ProjectSettings.ProjectWaterDensity:=GetFloat(Str);
                 // FreeShip.ProjectSettings.ProjectWaterTemper:=GetFloat(Str);
    FreeShip.ProjectSettings.ProjectAppendageCoefficient:=GetFloat(Str);
    I:=GetInteger( Str );
    FreeShip.ProjectSettings.FProjectUnits:=TFreeUnitType(I);
    I:=Integer( GetBoolean( Str ) ); // FreeShip.ProjectSettings.FMainparticularsHasBeenset:=GetBoolean(Str);
    I:=GetInteger( Str );
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
end;

// Imports a file created with Carlssons's Hulls program

procedure TFreeEdit.File_ImportHull;
var OpenDialog: TOpenDialog; Answer: word;
begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter( 'Carlsson Hull files',['hul'] );
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
    Answer:=Freeship.Edit.File_SaveCheck( Freeship.FileChanged );
    if (Answer=mrCancel) or FreeShip.FileChanged then begin FreeAndNil( OpenDialog ); exit; end;
    CreateUndoObject(UserString(110), True);
    File_ImportHull(OpenDialog.FileName, False);
    FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
  end;
  FreeAndNil( OpenDialog );
end;

procedure TFreeEdit.File_ImportHull(Filename: AnsiString; Quiet: boolean);
var
  I,J, NBulkHeads,NoChines : integer;
  P, Min, Max: T3DVector;
  FFile: TextFile;
  Value: TFloatType;
  Points: array of array of T3DVector;
  Chines: TFasterListTFreeSpline;
  Spline: TFreeSpline;
  Str: AnsiString;
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
        Setlength(Points[I-1], NoChines);
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
          Points[I-1][J-1]:=P;
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
          Setlength(Points[I-1], NoChines);
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
            Points[I-1][J-1]:=P;
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
      for I:=1 to NoChines do begin
        for J:=1 to NBulkheads do  begin
          P:=Points[J-1,I-1]; P.X:=-P.X+Max.X; Points[J-1,I-1]:=P;
        end;
        Spline:=TFreeSpline.Create(FreeShip.Surface); Chines.Add(Spline);
        for J:=1 to NBulkheads do begin
          P:=Points[J-1,I-1]; Spline.Add(P); Spline.Knuckle[J-1]:=False;
        end;
      end;
      FreeShip.ImportChines( NBulkheads,Chines );
      FreeAndNil(Chines);
      for I:=1 to 8 do begin                               // read stations
        Readln( FFile,Value );
        Intersection_Add( fiStation, -Value * 0.024+Max.X );
      end;
      for I:=1 to 9 do Readln(FFile);                      // Skip rig info
      Readln(FFile,Str);                                   // Read designer info
      FreeShip.ProjectSettings.FProjectDesigner:=Str;
      Readln(FFile,Str);
      FreeShip.ProjectSettings.FProjectName:=Str;
      CloseFile(FFile);                                    //  finally
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
  Changed,Crease: boolean;
  I, J, N, Np, Ind1, Ind2, LayerID: integer;
  PartVersion: TFreeFileversion;
  Str: AnsiString;
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
          if PartUnits <> FreeShip.ProjectSettings.ProjectUnits then begin
            if PartUnits = fuMetric then Scale:=1/Foot // Part units=metric and projectunits=imperial, scale from meters to feet
                                    else scale:=Foot; // Part units=imperial and projectunits=metric, scale from feet to meters
          end else Scale:=1.0;
          Partfile.LoadInteger(N);                     // Load number of layers
          Layers.Capacity:=N;
          for I:=1 to N do begin
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
          for I:=1 to N do begin
            P2:=TFreeSubdivisionControlPoint.Create(FreeShip.Surface);
            FreeShip.Surface.AddControlPoint(P2);
            P2.LoadBinary(PartFile);
            P2.Coordinate:=Scale*P2.Coordinate;
            Points.Add(P2);
            Changed:=True;
          end;
          // Load control edges
          Partfile.LoadInteger(N);
          Edges.Capacity:=N;
          for I:=1 to N do begin
            Partfile.LoadInteger(Ind1);
            Partfile.LoadInteger(Ind2);
            if (Ind1 <> -1) and (Ind2 <> -1) then begin
              P1:=Points[ind1];
              P2:=Points[ind2];
              Edge:=FreeShip.Surface.AddControlEdge(P1, P2);
            end else Edge:=nil;
            Partfile.LoadBoolean(Crease);
            if Edge <> nil then Edge.Crease:=Crease;
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
            Edge:=Edges[I-1];
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
                  P1:=Curve.ControlPoint[J-2];
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
//
//
//
// Imports a PolyCad file
procedure TFreeEdit.File_ImportPolycad;
var
  OpenDialog: TOpenDialog;
  PrevCursor: TCursor;
  Strings: TStringList;
  I,J,K,N, Cols,Rows,Index,EndIndex, NSections,NumSurfaces,SurfaceNo: integer;
  Indices: array of integer;
  Str, Tmp: AnsiString;
  Abort: boolean;
  Points: TFreeCoordinateGrid;
  Value: TFloatType;
  P: T3DVector;

  function NextLine: AnsiString;
  begin
    if Index+1 < Strings.Count then begin
      Inc(Index);
      Result:=Strings[index];
    end else begin
      Result:='';
      Abort:=True;
      MessageDlg( UserString(115), mtError, [mbOK], 0);
    end;
  end;{NextLine}

  function GetInteger(str: AnsiString): integer;
  var
    Index: integer; tmp:AnsiString;
  begin
    Index:=Pos('=', Str);
    Result:=0;
    if Index <> 0 then begin
      tmp:=Copy(Str, Index+1, Length(Str)-Index);
      Val(tmp, Result, Index);
      if Index <> 0 then begin
        MessageDlg(UserString(116)+#32
         +IntToStr(I)+' at row '+IntToStr(Index)+' value: "'+tmp+'"',
          mtError, [mbOK], 0);
        Abort:=True;
      end;
    end else Abort:=True;
  end;{GetInteger}

  function GetFloat( str: AnsiString ): TFloatType;
  var Index: integer; tmp: AnsiString;
  begin
    Index:=Pos('=', Str);
    Result:=0;
    if Index <> 0 then begin
      tmp:=Copy(Str, Index+1, Length(Str)-Index);
      Val(tmp, Result, Index);
      if Index <> 0 then begin
        MessageDlg(UserString(117)+#32
         +IntToStr(I)+' at row '+IntToStr(Index)+' value: "'+tmp+'"',
          mtError, [mbOK], 0);
        Abort:=True;
      end;
    end else Abort:=True;
  end;{GetFloat}

  function NextParameter(var input: string): string;
  var Index: integer;
  begin
    Index:=pos(#32, Input);
    if Index <> 0 then begin
      Result:=Copy(Input, 1, Index-1);
      Delete(Input, 1, Index);
      Input:=Trim(Input);
    end else begin
      Result:='';
      Abort:=True;
    end;
  end;{NextParameter}

  procedure readSurface(Cols, Rows: integer; var Points: TFreeCoordinateGrid);
  var J,K: integer;
    begin
      // Initialize points
      Setlength(Points, Rows);
      for J:=1 to Rows do begin
        Setlength(Points[J-1], Cols);
        for K:=1 to Cols do
          Points[J-1][K-1]:=ZERO;
      end;
      for J:=1 to Cols do begin
        for K:=1 to Rows do begin
          Str:=NextLine;
          if not abort then begin
            Str:=Trim(Str);
            P.X:=0;
            P.Y:=0;
            P.Z:=0;                                             // X coordinate
            Tmp:=NextParameter(Str);
            if not abort then begin
              Val(Tmp, P.X, N);
              if N <> 0 then begin
                MessageDlg(UserString(119)+#32 +
                  IntToStr(I)+' at row '+IntToStr(Index)+' value: "'+Tmp+'"',
                  mtError, [mbOK], 0);
                Abort:=True;
              end;
            end;
            if not Abort then begin
              Tmp:=NextParameter(Str);
              if not abort then begin
                Val(Tmp, P.Y, N);
                if N <> 0 then begin
                  MessageDlg(UserString(119)+#32 +
                    IntToStr(I)+' at row '+IntToStr(Index)+' value: "'+Tmp+'"',
                    mtError, [mbOK], 0);
                  Abort:=True;
                end;
              end;
            end;
            if not Abort then begin                             // Z coordinate
              Tmp:=NextParameter(Str);
              if not abort then begin
                Val(Tmp, P.Z, N);
                if N <> 0 then begin
                  MessageDlg(UserString(119)+#32 +
                    IntToStr(I)+' at row '+IntToStr(Index)+' value: "'+Tmp+'"',
                    mtError, [mbOK], 0);
                  Abort:=True;
                end;
              end;
            end; Points[K-1][J-1]:=P;
          end else break;
        end;
        if abort then break;
      end;
      if not Abort then FreeShip.Surface.ImportCoordGrid(Points,Cols,Rows,nil);
    end;

begin
  OpenDialog:=TOpenDialog.Create(FreeShip);
  OpenDialog.InitialDir:=FreeShip.Preferences.ImportDirectory;
  OpenDialog.Filter:=createDialogFilter('PolyCad files',['geo']);
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
    if not CheckIfChangedAndAskToSave() then begin FreeAndNil(OpenDialog); exit; end;
    PrevCursor:=Screen.Cursor;
    Screen.Cursor:=crHourglass;
    Strings:=TStringList.Create;
//    try
      Strings.LoadFromFile(OpenDialog.FileName);
      // delete empty strings
      {for I:=Strings.Count downto 1 do
        if Strings[I-1] = '' then
          Strings.Delete(I-1);}
      // count number of Sections
      NSections:=0;
      for I:=0 to strings.Count-1 do begin
        Str:=Strings[I].TrimLeft();
        if Str.StartsWith('[') and Str.EndsWith(']') then begin
          Setlength(Indices, NSections+1);
          Indices[NSections]:=I;
          Inc(NSections);
        end;
      end;

      if NSections > 0 then begin
        CreateUndoObject(UserString(118), True);
        FreeShip.Clear;
        FreeShip.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
        I:=1;
        Abort:=False;
        while (I <= NSections) and (not Abort) do begin
          Index:=Indices[I-1];
          Str:=Strings[index];
          if Str = '' then inc(index)
          else if Str = '[TYachtLines]' then begin
            FreeShip.ProjectSettings.ProjectLength:=1;
            FreeShip.ProjectSettings.ProjectBeam:=1;
            FreeShip.ProjectSettings.ProjectDraft:=1;
//          FreeShip.ProjectSettings.FMainparticularsHasBeenset:=False;
            EndIndex:=Strings.Count-1;
            while Index < EndIndex do begin
              Str:=NextLine;
              Str:=Str.TrimLeft();
              if Str = '' then
              else if (pos('Loa=', Str) = 1) then
                FreeShip.ProjectSettings.ProjectLength:=GetFloat(Str)
              else if (pos('Lwl=', Str) = 1) then
              else if (pos('Ovh=', Str) = 1) then
              else if (pos('BMax=', Str) = 1) then
                FreeShip.ProjectSettings.ProjectBeam:=GetFloat(Str)
              else if (pos('Bwl=', Str) = 1) then
              else if (pos('BTransom=', Str) = 1) then
              else if (pos('MaxVParameter=', Str) = 1) then
              else if (pos('Tc=', Str) = 1) then
                FreeShip.ProjectSettings.ProjectDraft:=GetFloat(Str)
              else if (pos('Cp=', Str) = 1) then
              else if (pos('Cm=', Str) = 1) then
              else if (pos('LCB=', Str) = 1) then
              else if (pos('Cwp=', Str) = 1) then
              else if (pos('Lcf=', Str) = 1) then
              else if (pos('FreeBow=', Str) = 1) then
              else if (pos('FreeMid=', Str) = 1) then
              else if (pos('FreeAft=', Str) = 1) then
              else if (pos('BowCurve=', Str) = 1) then
              else if (pos('ForeFoot=', Str) = 1) then
              else if (pos('TransomAngle=', Str) = 1) then
              else if (pos('FlareAngle=', Str) = 1) then
              else if (pos('OrderU=', Str) = 1) then
              else if (pos('OrderV=', Str) = 1) then
              else if (pos('NumU=', Str) = 1) then Cols:=GetInteger(Str)
              else if (pos('NumV=', Str) = 1) then Rows:=GetInteger(Str)
              else if (pos('Name=', Str) = 1) then
              else if (pos('$POLYCADVERSION', Str) = 1) then
              else if (pos('=', Str) = 0) then begin dec(index);
                if (Cols > 1) and (Rows > 1) then begin
                  readSurface(Cols, Rows, Points);
                end;
              end;
            end;
          end else
          if Str = '[TShipLines]' then begin
            FreeShip.ProjectSettings.ProjectLength:=1;
            FreeShip.ProjectSettings.ProjectBeam:=1;
            FreeShip.ProjectSettings.ProjectDraft:=1;
//          FreeShip.ProjectSettings.FMainparticularsHasBeenset:=False;
            EndIndex:=Strings.Count-1;
            while Index < EndIndex do begin
              Str:=NextLine;
              Str:=Str.TrimLeft();
              if Str = '' then
              else if (pos('BowShape=', Str) = 1) then
              else if (pos('Lbp=', Str) = 1) then
                FreeShip.ProjectSettings.ProjectLength:=GetFloat(Str)
              else if (pos('Beam=', Str) = 1) then
                FreeShip.ProjectSettings.ProjectBeam:=GetFloat(Str)
              else if (pos('Depth=', Str) = 1) then
              else if (pos('Draught=', Str) = 1) then
                FreeShip.ProjectSettings.ProjectDraft:=GetFloat(Str)
              else if (pos('ParallelDeckF=', Str) = 1) then
              else if (pos('ParallelDeckA=', Str) = 1) then
              else if (pos('FOSBow=', Str) = 1) then
              else if (pos('FOSAft=', Str) = 1) then
              else if (pos('BowRadiusAtDeck=', Str) = 1) then
              else if (pos('BilgeRadius=', Str) = 1) then
              else if (pos('TransomBehindAP=', Str) = 1) then
              else if (pos('TransomImmersion=', Str) = 1) then
              else if (pos('TransomBeam=', Str) = 1) then
              else if (pos('TransomCurvature=', Str) = 1) then
              else if (pos('BowCurvature=', Str) = 1) then
              else if (pos('BulbRadius=', Str) = 1) then
              else if (pos('ForeOverHang=', Str) = 1) then
              else if (pos('BulbLength=', Str) = 1) then
              else if (pos('ForeFootRadius=', Str) = 1) then
              else if (pos('StemRadius=', Str) = 1) then
              else if (pos('StRootHeight=', Str) = 1) then
              else if (pos('StShaftHeight=', Str) = 1) then
              else if (pos('StBossToRoot=', Str) = 1) then
              else if (pos('StBossRadius=', Str) = 1) then
              else if (pos('StBossStart=', Str) = 1) then
              else if (pos('StFlatOfBottomStart=', Str) = 1) then
              else if (pos('DrawBoundaries=', Str) = 1) then
              else if (pos('DrawParameters=', Str) = 1) then
              else if (pos('DesignDraught=', Str) = 1) then
              else if (pos('OrderU=', Str) = 1) then
              else if (pos('OrderV=', Str) = 1) then
              else if (pos('NumU=', Str) = 1) then Cols:=GetInteger(Str)
              else if (pos('NumV=', Str) = 1) then Rows:=GetInteger(Str)
              else if (pos('Name=', Str) = 1) then
              else if (pos('$POLYCADVERSION', Str) = 1) then
              else if (pos('=', Str) = 0) then begin dec(index);
                if (Cols > 1) and (Rows > 1) then begin
                  readSurface(Cols, Rows, Points);
                end;
              end;
            end;
          end else
          if Str = '[TBSplineSurface]' then begin
            if I < NSections then EndIndex:=Indices[I]-1
                             else EndIndex:=Strings.Count-1;
            while Index < EndIndex do begin
              Str:=NextLine;
              Str:=Str.TrimLeft();
              if Str = '' then
              else if (pos('KnotType=', Str) = 1) then
              else if (pos('KnotU=', Str) = 1) then
              else if (pos('KnotV=', Str) = 1) then
              else if (pos('MinUParameter=', Str) = 1) then
              else if (pos('MinVParameter=', Str) = 1) then
              else if (pos('MaxUParameter=', Str) = 1) then
              else if (pos('MaxVParameter=', Str) = 1) then
              else if (pos('OrderU=', Str) = 1) then
              else if (pos('OrderV=', Str) = 1) then
              else if (pos('NumU=', Str) = 1) then Cols:=GetInteger(Str)
              else if (pos('NumV=', Str) = 1) then Rows:=GetInteger(Str)
              else if (pos('Name=', Str) = 1) then
              else if (pos('$POLYCADVERSION', Str) = 1) then
              else if (pos('=', Str) = 0) then begin dec(index);
                if (Cols > 1) and (Rows > 1) then begin
                  readSurface( Cols,Rows,Points );
                end;
              end;
            end;
          end else
          if Str = '[TBSplineSurfaceList]' then begin
            if I < NSections then EndIndex:=Indices[I]-1
                             else EndIndex:=Strings.Count-1;
            SurfaceNo:=0;
            while Index < EndIndex do begin
              Str:=NextLine;
              Str:=Str.TrimLeft();
              if Str = '' then
              else if (pos('NumSurfaces=', Str) = 1) then NumSurfaces:=GetInteger(Str)
              else if (pos('KnotType=', Str) = 1) then
              else if (pos('KnotU=', Str) = 1) then
              else if (pos('KnotV=', Str) = 1) then
              else if (pos('MinUParameter=', Str) = 1) then
              else if (pos('MinVParameter=', Str) = 1) then
              else if (pos('MaxUParameter=', Str) = 1) then
              else if (pos('MaxVParameter=', Str) = 1) then
              else if (pos('OrderU=', Str) = 1) then
              else if (pos('OrderV=', Str) = 1) then
              else if (pos('NumU=', Str) = 1) then Cols:=GetInteger(Str)
              else if (pos('NumV=', Str) = 1) then Rows:=GetInteger(Str)
              else if (pos('Name=', Str) = 1) then
              else if (pos('$POLYCADVERSION', Str) = 1) then
              else if (pos('=', Str) = 0) then begin
                inc(SurfaceNo);
                dec(index);
                if (Cols > 1) and (Rows > 1) then begin
                  readSurface(Cols, Rows, Points);
                end;
              end;
            end;
          end;
          Inc(I);
        end;  // while (I <= NSections)

        if not Abort then begin     // Read contours;               ///**!**///
          for I:=1 to Strings.Count do
            if Pos('[TContours]', Strings[I-1]) <> 0 then begin
              Index:=I-1;
              Str:=NextLine;
              N:=GetInteger(Str);
              if not abort then
                for J:=1 to N do begin
                  Str:=NextLine;
                  if not abort then begin
                    Str:=Trim(Str);
                    Tmp:=NextParameter(Str);
                    if not abort then K:=StrToInt(Tmp)
                    else K:=0;           // 1=station, 2=buttock, 3=waterline
                    if not abort then begin Val(Str, Value, N);
                      if N <> 0 then begin
                        MessageDlg( UserString(122), mtError, [mbOK], 0);
                        Abort:=True;
                      end else
                        case K of
                          1: self.Intersection_Add( fiStation,Value );
                          2: if Value >= 0 then
                             self.Intersection_Add( fiButtock,Value );
                          3: self.Intersection_Add( fiWaterline,Value );
                        end;
                    end;
                  end;
                  if abort then break;
                end;
              break;
            end;
                                                                    ///**!**///
          FreeShip.Precision:=fpMedium;
          FreeShip.FileName:=ChangeFileExt(Opendialog.FileName, '');
          FreeShip.ModelIsLoaded:=True;
          FreeShip.RebuildModel;
          FreeShip.FileChanged:=True;
        end else MessageDlg(UserString(123), mtInformation, [mbOK], 0);
      end else MessageDlg(UserString(124), mtInformation, [mbOK], 0);
//    finally
      FreeAndNil( Strings );
      if Assigned( FreeShip.OnUpdateGeometryInfo ) then
                   FreeShip.OnUpdateGeometryInfo( self );
      Screen.Cursor:=PrevCursor;
//    end;
  end;
  FreeAndNil(OpenDialog);
end;{TFreeEdit.File_ImportPolycad}
//
//
//
// Import markers from a textfile
procedure TFreeEdit.Marker_Import;
var
  OpenDialog: TOpenDialog;
  Str: AnsiString;
  I,LineNr: integer;
  P: T3DVector;
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
  OpenDialog.Filter:=createDialogFilter(rsTextFile, ['txt']);
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
//        MessageDlg(Userstring(132)+#32+IntToStr(LineNr), mtError, [mbOK], 0);
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
              Marker:=Markers[I-1];
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



