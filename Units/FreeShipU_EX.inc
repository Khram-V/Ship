{
  1 = © Aurora.Vsl-штормовой вычислительный эксперимент
  2 = WaveFront.Obj
  3 - Standard triangle.Stl
  4 - dxf - три варианта
  5 - iges
}
//
//        Export for Aurora-Hull stormy computational experiments (simulations)
//
procedure TFreeEdit.File_Export_Aurora_Experiments;
var
  Str: AnsiString;
  Strings: TStringList;
  Procedure Str2( A,B: single ); begin Str:=Str+'  '+FloatToDec(A,5)+' '+FloatToDec(B,5); end;
  Procedure Str3( X,Y,Z: single ); begin Str:=Str+'  '+FloatToDec(X,5)+' '+FloatToDec(Y,5)+' '+FloatToDec(Z,5); end;
//Procedure Str2( A,B: single ); begin Str:=Str+' '+FloatTypetoStr(A)+' '+FloatTypetoStr(B); end;
//Procedure Str3( X,Y,Z: single ); begin Str:=Str+' '+FloatTypetoStr(X)+' '+FloatTypetoStr(Y)+' '+FloatTypetoStr(Z); end;

  Procedure StemStern( Dir:boolean ); // Dir=true - форштевень, иначе - ахтерштевень
    var I,J,K,M,N: Integer; z1:single;
  begin Str:='';
    for I:=0 to Ship.NumberofButtocks-1 do        // поиск нулевого батокса
    with Ship.Buttock[I] do begin
//    if not Built then Rebuild;
      if Count>1 then                     // батокс для диаметрильной плоскости
      if abs( Items[0].Point[0].Y )<1e-4 then
      begin z1:=Items[0].Point[0].Z;         // батокс диаметральной плоскости
        for J:=0 to Count-1 do begin M:=0;   // однако он составлен из обрезков
          N:=Items[J].NumberOfPoints-1;      // выбор конкретного огрызка
          if N>0 then for K:=0 to N do       // хотя бы две точки - не менее
          if Items[J].Point[K].Z<=z1 then    // сдвиг начальной точки вниз
             begin z1:=Items[J].Point[K].Z; M:=K; end;
(*#?#*)   if Dir then begin Str:=' '+InttoStr( M+1 );
             for K:=M downto 0 do with Items[J].Point[K] do Str2( Z,X );
//           if Z>=z1 then begin Str2( Z,X ); z1:=Z; end else break;
          end else begin Str:=' '+InttoStr( N-M+1 );
             for K:=M to N do with Items[J].Point[K] do Str2( Z,X );
//           if Z>=z1 then begin Str2( Z,X ); z1:=Z; end else break;
          end;
        end;         break; // выход с первым же отрезком без полной пересборки
      end;
    end;
    if Str='' then Strings.Add( EOL+' 0' ) else Strings.Add( Str );
    //
    //                            ...и всё-таки батокс следует записать особо
    if Dir and (Ship.NumberofButtocks>0) then begin
      Strings.Add( EOL+'Buttocs['+IntToStr( Ship.NumberofButtocks )+'] of Centerline' );
      for I:=0 to Ship.NumberofButtocks-1 do      // поиск нулевого батокса
      with Ship.Buttock[I] do begin Str:='';
      // if not Built then Rebuild;
         if Count>0 then                   // батокс для диаметрильной плоскости
         for J:=0 to Count-1 do begin
            if abs( Items[J].Point[0].Y )<1e-4 then begin
            N:=Items[J].NumberOfPoints;
            Str:=' '+InttoStr( N )+' ('+FloatToDec(Items[J].Point[0].Y,5)+') ';
            for K:=0 to N-1 do with Items[J].Point[K] do Str2( Z,X );
            Strings.Add( Str );
          end;
        end;
      end;
    end;
  end;
  procedure SendSpline( Spline:TFreespline );
  var J,N: integer; P: T3DVector;
  begin N:=Spline.NumberOfPoints-1;
     Str:=format( ' %3d ',[N+1] );
     if Spline.Point[0].Z<=Spline.Point[N].Z
        then for J:=0 to N do with Spline.Point[J] do Str3( X,Y,Z )
        else for J:=N downto 0 do with Spline.Point[J] do Str3( X,Y,Z );
     Strings.Add( Str );
  end;
var I,J,K,N: integer;
    Title,S: AnsiString; P0,PN: T3DVector; Dis: boolean;
    Dialog: TSaveDialog;
//  T3: T3DVector=(X:0;Y:0;Z:0);
    EdgePointLists: TFasterList; // TFasterListTFreeSubdivisionPoint;
    Points: TFasterList;         // TFreeSubdivisionPoint;
    Point: TFreeSubdivisionPoint;
//? Frame: TFreeCoordinateGrid;
begin
  Title:=ExtractFilename( Ship.FileName ); Dis:=True;
  Dialog:=TSaveDialog.Create( Ship );
  Dialog.InitialDir:=Ship.Preferences.ExportDirectory;
  Dialog.FileName:=ChangeFileExt( Title,'.vsl');
  Dialog.Filter:='Aurora+Hull Vessel (*.vsl)|*.vsl';
  dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];

  if Dialog.Execute then begin WestPoint;
    //Ship.Preferences.ExportDirectory:=Dialog.InitialDir;
    Strings:=TStringList.Create;
    with Ship.FProjectSettings do                        //  RawByteString
    Strings.Add( '; FREE!Ship'+EOL+';'
            +EOL+'; File Name: '+Title
            +EOL+'; Name     : '+ProjectName
            +EOL+'; Designer : '+ProjectDesigner
            +EOL+'; Create by: '+ProjectFileCreatedBy
            +EOL+'; Comment  : '+ProjectComment
            +EOL+';'                                     // уточнить где мидель
            +EOL+#30+' < '+ExtractFilename( Dialog.FileName )+' > '
            +EOL+InttoStr( Ship.NumberofStations )
            +' '+InttoStr( Ship.NumberofStations div 2 )
            +EOL+FloatToStrF( FProjectLength,ffGeneral,6,1)
            +' '+FloatToStrF( FProjectBeam,ffGeneral,6,1)
            +' '+FloatToStrF( FProjectDraft,ffGeneral,6,1)+EOL );

    //  Ship.Preferences.ExportDirectory:=ExtractFilePath( Dialog.FileName );
    //  T3.Z:=Ship.FProjectSettings.FProjectDraft;

    StemStern( false );                    // первые две строки для ахтерштевня
    Strings.Add( ' 0'+EOL );
    for I:=0 to Ship.NumberofStations-1 do
    with Ship.Station[I] do begin
    // if not Built then Rebuild;
       N:=0;                     // суммарное количество точек на всех отрезках
       if Count>0 then P0:=Items[0].Point[0]; PN:=P0;
       for J:=0 to Count-1 do with Items[J] do
       if NumberOfPoints>1 then begin
          N+=NumberOfPoints;
          if J=0 then P0:=Point[0];
          if J=Count-1 then PN:=Point[NumberOfPoints-1];
       end;                                                   // Z-положительно
       Dis:=(P0.Z<PN.Z) or (P0.Y<1e-6) or (P0.Y<=PN.Y);
       Title:=format( '%3d %-4.4g',[N,Items[0].Point[0].X] ); S:='';
       for J:=0 to Count-1 do with Items[J] do
       if NumberOfPoints>1 then begin
          N:=NumberOfPoints-1; Str:=''; // ещё и сортировки только и не хватало
          if Point[N].Z>=Point[0].Z                  // == может быть на палубе
             then begin for K:=0 to N do with Point[K] do Str2( Z,Y ); end
             else begin for K:=N downto 0 do with Point[K] do Str2( Z,Y ); end;
         if J=0 then S:=Str else begin if Dis then S:=S+Str else S:=Str+S; end;
       end;
       Strings.Add( Title+S );
    end;
    Strings.Add( EOL+' 0' );          // форштевень в завершение и в заключение
    StemStern( true );                // еще и все контрольные точки и контуры
    if Ship.NumberOfControlCurves>0 then begin
       Strings.Add( EOL+'ContorlCurves['+IntToStr(Ship.NumberOfControlCurves)+']' );
       for I:=0 to Ship.NumberOfControlCurves-1 do
                SendSpline( Ship.ControlCurve[I].Curve );
    end;
    EdgePointLists:=TFasterList.Create;                // TFreeSubdivisionPoint
    Ship.Surface.ExtractAllEdgeLoops( EdgePointLists );
    if EdgePointLists.Count>1 then begin
       Strings.Add( EOL+'EdgePoints['+IntToStr( EdgePointLists.Count )+']' );
       for I:=0 to EdgePointLists.Count-1 do begin
          Points:=EdgePointLists[I];
          N:=Points.Count-1;
          Str:=format( ' %3d ',[N+1] );        // ' '+IntToStr( Points.Count );
          if TFreeSubdivisionPoint(Points[0]).Coordinate.Z<=TFreeSubdivisionPoint(Points[N]).Coordinate.Z
          then for J:=0 to N do with TFreeSubdivisionPoint(Points[J]).Coordinate do Str3( X,Y,Z )      //:=Str+format( ' %1.5g %1.5g %1.5g ',[X,Y,Z] )
          else for J:=N downto 0 do with TFreeSubdivisionPoint(Points[J]).Coordinate do Str3( X,Y,Z ); //:=Str+format( ' %1.5g %1.5g %1.5g ',[X,Y,Z] );
          Strings.Add( Str );
          Points.Destroy;
       end;
    end;
    Strings.SaveToFile( ChangeFileExt( Dialog.FileName,'.vsl' ) );
    EdgePointLists.Destroy;
    Strings.Destroy;   // writeln( Dialog.InitialDir+' -=> '+Dialog.filename );
  end;
  Dialog.Destroy;
end;
{
    Loads a bodyplane and tries to fit a surface to it
}
procedure TFreeEdit.ImportFrames;
type TMinMax = record MinZ,MaxZ:TFloatType; end;
// Assumptions:
//    1. All stations have multiplicity of 1
//    2. All stations are defined from bottom to top
var OpenDialog    : TOpenDialog;
    I,J,K,Nr,Index,NoStations,NoPoints: integer;
    Frames        : TFasterList;
    FFile         : TextFile;
    Spline        : TFreeSpline;
    NewSpline     : TFreeSpline;
    P             : T3DVector;
    ValidStation  :Boolean;
    MinMaxData    : array of TMinMax;
    MinZ,MaxZ     : TFloatType;
    ControlPoints : array of array of TFreeSubdivisionControlPoint;
    P1,P2         : TFreeSubdivisionControlPoint;
    Edge          : TFreeSubdivisionControlEdge;
    Face          : TFreeSubdivisionControlFace;
    Points        : TFasterList;
    Marker        : TFreeMarker;
begin
   OpenDialog:=TOpenDialog.Create(Ship);
   OpenDialog.InitialDir:=ExtractFilepath(Application.ExeName);
   OpenDialog.Filter:='3D text file (*.Txt)|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      Frames:=TFasterList.Create;
      Case OpenDialog.FilterIndex of
         1 :begin   // 3D textfile containing stations, waterlines and buttocks
               AssignFile(FFile,Opendialog.FileName);
               {$I-}Reset(FFile);{$I+}
               if IOResult=0 then begin
                  K:=0;
                  Nr:=0;
                  inc(Nr);
                  Readln(FFile,NoStations);
                  for I:=1 to NoStations do begin
                     inc(Nr);
                     readln(FFile);            // Skip description of this line
                     inc(Nr);
                     readln(FFile,NoPoints);
                     Spline:=TFreeSpline.Create;
                     Spline.Capacity:=NoPoints;
                     ValidStation:=NoPoints>1;
                     for J:=1 to Nopoints do begin
//                   try
                        inc(Nr);
                        Read(FFile,P.X,P.Y,P.Z);
                        if not EOLN(FFile) then Readln(FFile,K) else begin
                           K:=0;
                           Readln(FFile);
                        end;
//                   except
//                         Showmessage(Userstring(132)+#32+IntToStr(Nr));
//                   end;
                        Spline.Add(P);
                        if J>1 then ValidStation:=abs(P.X-Spline.Point[0].X)<1e-4;
                        if (K=1) and (J<>1) and (J<>NoPoints) then Spline.Knuckle[J-1]:=True;
                     end;
                     if ValidStation then Frames.Add(Spline)
                                     else Spline.Destroy;
                  end; CloseFile(FFile);
               end; // else ShowMessage(Userstring(132));
            end;
      end;
      if Frames.Count>1 then begin
         Ship.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         CreateUndoObject(Userstring(133),True);
         Ship.Clear;
         Ship.Filename:=Opendialog.FileName;
         MinZ:=0.0;
         MaxZ:=0.0;                // first sort the stations from aft to front
         for I:=1 to Frames.Count-1 do
            for J:=I+1 to Frames.count
              do if TFreeSpline(Frames[J-1]).Point[0].X<TFreeSpline(Frames[I-1]).Point[0].X then Frames.Exchange(I-1,J-1);
         // Determine the minimum and maximum Z values for each station
         // and the overall min/max z-coordinate
         Setlength(MinMaxData,Frames.Count);
         for I:=1 to Frames.Count do begin
            Spline:=Frames[I-1];
            MinMaxData[I-1].MinZ:=Spline.Point[0].Z;
            MinMaxData[I-1].MaxZ:=Spline.Point[Spline.NumberOfPoints-1].Z;
            if I=1 then begin
               MinZ:=Spline.Point[0].Z;
               MaxZ:=MinZ;
            end;
            if Spline.Point[0].Z<MinZ then MinZ:=Spline.Point[0].Z;
            if Spline.Point[Spline.NumberOfPoints-1].Z>MaxZ then MaxZ:=Spline.Point[Spline.NumberOfPoints-1].Z;
            Marker:=TFreeMarker.Create;
            Marker_Add(Marker);
            Marker.Capacity:=Spline.NumberOfPoints;
            for J:=1 to Spline.NumberOfPoints do begin
               Marker.Add(Spline.Point[J-1]);
               Marker.Knuckle[J-1]:=Spline.Knuckle[J-1];
            end;
         end;
         // extend all stations upwards and downwards to the min/max z-values
         for I:=1 to Frames.Count do begin
            Spline:=Frames[I-1];                     // extend downwards to Z=0
            if Spline.Point[0].Z>MinZ then begin
               P:=Spline.Point[0];
               P.Z:=MinZ;
               Spline.Insert(0,P);
               Spline.Knuckle[1]:=True;
            end;                                              // extend upwards
            if Spline.Point[Spline.NumberOfPoints-1].Z<MaxZ then begin
               P:=Spline.Point[Spline.NumberOfPoints-1];
               P.Z:=MaxZ;
               Spline.Add(P);
               Spline.Knuckle[Spline.NumberOfPoints-2]:=True;
            end;
         end;
         NoPoints:=10; // resample all stations to a user defined number of points
         NoPoints:=StrToInt(InputBox('',Userstring(135)+':',IntToStr(NoPoints)));
         if NoPoints<5 then NoPoints:=5;
         Setlength(ControlPoints,Frames.Count);
         for I:=1 to Frames.Count do begin
            Spline:=Frames[I-1];
            NewSpline:=TFreeSpline.Create;
            NewSpline.Capacity:=NoPoints;
            for J:=1 to NoPoints do begin
               P:=Spline.Value((J-1)/(NoPoints-1));
               NewSpline.Add(P);
            end;                           // correct for any present knuckles
            for J:=1 to Spline.NumberOfPoints do if Spline.Knuckle[J-1] then begin
               Index:=0;          // find the nearest point on resampled spline
               for K:=2 to NewSpline.NumberOfPoints-1 do
               if Sqr( Spline.Point[J-1]-NewSpline.Point[K-1] )<Sqr( Spline.Point[J-1]-NewSpline.Point[index] )
                 then Index:=K-1;              // replace by the old coordinate
               NewSpline.Point[index]:=Spline.Point[J-1];
               NewSpline.Knuckle[index]:=True;
            end;                                 // Delete the old station and
            Spline.Destroy;                     // replace by the resampled one
            Frames[I-1]:=NewSpline; // Add the controlpoints to the subdivision surface
            Setlength(ControlPoints[I-1],NewSpline.NumberOfPoints);
            for J:=1 to NewSpline.NumberOfPoints
             do ControlPoints[I-1][J-1]:=Ship.Surface.AddControlPoint(NewSpline.Point[J-1]);
         end;                                       // Add the new controlfaces
         Points:=TfasterList.Create;
         For I:=2 to Frames.Count do begin
            for J:=2 to NoPoints do begin
               Points.Clear;
               Points.Add(ControlPoints[I-1][J-1]);
               Points.Add(ControlPoints[I-1][J-2]);
               Points.Add(ControlPoints[I-2][J-2]);
               Points.Add(ControlPoints[I-2][J-1]);
               Ship.Surface.AddControlFace(Points,True);
            end;
         end;
         Points.Clear;                      // Try to reconnect the contourline
         P1:=nil;
         P2:=nil;
         for I:=1 to Frames.Count do begin
            for J:=1 to NoPoints do
            if abs(ControlPoints[I-1][J-1].Coordinate.Z-MinMaxData[I-1].MinZ)<1e-5
            then begin
               P2:=ControlPoints[I-1][J-1];
               if P2.Coordinate.Y<>0.0 then begin // Force point to centerplane
                  P:=P2.Coordinate;
                  P.Y:=0;
                  P2.Coordinate:=P;
               end;
               break;
            end else Points.Add(ControlPoints[I-1][J-1]);// store to be deleted later
            if (P1<>nil) and (P2<>nil) then begin
               Edge:=Ship.Surface.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
               if Edge<>nil then Edge.Crease:=True else begin
                            // Find out if P1 and P2 share the same controlface
                  for J:=1 to P1.NumberOfFaces do
                  if P2.IndexOfFace(P1.Face[J-1])<>-1 then begin
                     Face:=P1.Face[J-1] as TFreeSubdivisionControlFace;
                     Edge:=Face.InsertEdge(P1,P2);
                     if Edge<>nil then
                        Edge.Crease:=True;
                  end;
               end;
            end;
            P1:=P2;
            P2:=nil;
         end;
         P1:=nil;                              // Try to reconnect the deckline
         P2:=nil;
         for I:=1 to Frames.Count do begin
            for J:=1 to NoPoints do
            if abs(ControlPoints[I-1][J-1].Coordinate.Z-MinMaxData[I-1].MaxZ)<1e-5
            then begin
               P2:=ControlPoints[I-1][J-1];
               K:=J+1;
               while K<=NoPoints do begin
                  Points.Add(ControlPoints[I-1][K-1]);
                  inc(K);
               end;
               break;
            end;
            if (P1<>nil) and (P2<>nil) then begin
               Edge:=Ship.Surface.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
               if Edge<>nil then Edge.Crease:=True
               else begin   // Find out if P1 and P2 share the same controlface
                  for J:=1 to P1.NumberOfFaces
                  do if P2.IndexOfFace(P1.Face[J-1])<>-1 then begin
                     Face:=P1.Face[J-1] as TFreeSubdivisionControlFace;
                     Edge:=Face.InsertEdge(P1,P2);
                     if Edge<>nil then
                        Edge.Crease:=True;
                  end;
               end;
            end;
            P1:=P2;
            P2:=nil;
         end;
      // Delete all controlpoints beneath the contourline and above the deckline
         for J:=1 to Points.Count do begin
            P1:=Points[J-1];
            if Ship.Surface.PointExists(P1) then P1.Delete;
         end;
         for I:=1 to Ship.Surface.NumberOfControlPoints do
           if Ship.Surface.ControlPoint[I-1].NumberOfFaces=1 then
              Ship.Surface.ControlPoint[I-1].VertexType:=svCorner;
         Points.Destroy;
         Ship.FileChanged:=True;
      end;
      Ship.Draw;                                  // Destroy allocated stations
      if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
      for I:=1 to Frames.Count do begin
         Spline:=Frames[I-1];
         Spline.Destroy;
      end;
      Frames.Destroy;
   end;
   OpenDialog.Destroy;
end;

// Imports a number of curves and fits a surface;
procedure TFreeEdit.File_ImportSurface;
var OpenDialog    : TOpenDialog;
    I,J,Nr        : integer;
    Str           : string;
    FFile         : TextFile;
    Cols,Rows     : Integer;
    Spline        : TFreeSpline;
    NewSpline     : TFreeSpline;
    P             : T3DVector;
    Points        : array of array of T3DVector;
    ControlPoints : array of array of TFreeSubdivisionControlPoint;
    P1            : TFreeSubdivisionControlPoint;
    Curves        : TFasterList;
    LongCurves    : TFasterList;
    Pts           : TfasterList;
    Matrix        : TFreeMatrix;
    ColMatrix     : TFreeMatrix;
    RowMatrix     : TFreematrix;
    OrgPts        : TFreeMatrix;
    NewPts        : TFreeMatrix;
    UnitType      : TFreeUnitType;
    Marker        : TFreeMarker;
    PrevCursor    : TCursor;
begin
   OpenDialog:=TOpenDialog.Create(Ship);
   OpenDialog.InitialDir:=Ship.Preferences.ImportDirectory;
   OpenDialog.Filter:='3D text file (*.Txt)|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      UnitType:=TFreeUnitType(0);
      Curves:=TFasterList.Create;
      Case OpenDialog.FilterIndex of
         1 :begin // 3D textfile containing a number of curves to be interpolated
               AssignFile(FFile,Opendialog.FileName);
               {$I-}Reset(FFile);{$I+}
               if IOResult=0 then begin
                  Nr:=0;
//                try
                     // first read unit information; 0=metric, 1=imperial
                     readln(FFile,I);
                     if I in [0,1] then UnitType:=TFreeUnitType(I)
                                   else MessageDlg(Userstring(108),mtError,[mbOk],0);
                     Spline:=TFreeSpline.Create;
                     repeat
                        Readln(FFile,Str);
                        repeat
                           I:=Pos(#9,Str);
                           if I<>0 then str[I]:=#32;
                        until I=0;
                        inc(Nr);
                        Str:=Trim(Uppercase(Str));
                        if (Str<>'') and (Str<>'EOF') then begin
                           P.X:=ReadFloatFromStr(Nr,Str);
                           P.Y:=ReadFloatFromStr(Nr,Str);
                           P.Z:=ReadFloatFromStr(Nr,Str);
                           Spline.Add(P);
                           Str:=#32;
                        end else if Str='' then begin
                           if Spline.NumberOfPoints>1 then Curves.Add(Spline)
                                                      else Spline.Destroy;
                           Spline:=TFreeSpline.Create;
                        end;
                     until (Str='EOF') or (EOF(FFile));
                     if Spline.NumberOfPoints>1 then Curves.Add(Spline)
                                                else Spline.Destroy;
//                except
//                   MessageDlg(Userstring(132)+#32+IntToStr(Nr),mtError,[mbOk],0);
//                end;
                  CloseFile(FFile);
               end; // else ShowMessage(Userstring(132));
            end;
      end;
      if Curves.Count>1 then begin
         PrevCursor:=Screen.Cursor;
         Ship.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         CreateUndoObject(Userstring(136),True);
         Ship.Clear;
         Ship.ProjectSettings.ProjectUnits:=UnitType;
         Ship.Filename:=Opendialog.FileName;
//       try
            Cols:=Curves.Count;
            Cols:=StrToInt(InputBox('',Userstring(137)+':',IntToStr(Cols)));
            if Cols<3 then Cols:=3;
            Rows:=10;
            Rows:=StrToInt(InputBox('',Userstring(138)+':',IntToStr(Rows)));
            if Rows<3 then Rows:=3; // Build number of desired longitudinal curves
            LongCurves:=TFasterList.Create;
            for I:=1 to Rows do begin
               NewSpline:=TFreeSpline.Create;
               LongCurves.Add(NewSpline);
               Newspline.Capacity:=Curves.Count;
               for J:=1 to Curves.Count do begin
                  Spline:=Curves[J-1];
                  Newspline.Add(Spline.Value((I-1)/(Rows-1)));
               end;
            end;
            for I:=1 to Curves.Count do begin
               Spline:=Curves[I-1];
               Marker:=TFreeMarker.Create;
               Marker.Capacity:=Spline.NumberOfPoints;
               for J:=1 to Spline.NumberOfPoints do Marker.Add(Spline.Point[J-1]);
               Marker_Add(Marker);
               Spline.Destroy;
            end;
            Curves.Destroy;            // build matrix for column interpolation
            Matrix:=TFreeMatrix.Create;
            Matrix.SetSize(Cols,Cols);
            Matrix.Fill(0.0);
            Matrix.Value[0,0]:=1.0;
            for I:=2 to Cols-1 do begin
               Matrix.Value[I-1,I-2]:=1/6;
               Matrix.Value[I-1,I-1]:=2/3;
               Matrix.Value[I-1,I  ]:=1/6;
            end;
            Matrix.Value[Cols-1,Cols-1]:=1.0;
            Colmatrix:=Matrix.Invert;
   
            Matrix.SetSize(Rows,Rows);
            Matrix.Fill(0.0);
            Matrix.Value[0,0]:=1.0;
            for I:=2 to Rows-1 do begin
               Matrix.Value[I-1,I-2]:=1/6;
               Matrix.Value[I-1,I-1]:=2/3;
               Matrix.Value[I-1,I  ]:=1/6;
            end;
            Matrix.Value[Rows-1,Rows-1]:=1.0;                  // Invert matrix
            Rowmatrix:=Matrix.Invert;

            Matrix.Destroy;                         // build initial point grid
            Setlength(Points,Rows);
            for I:=1 to Rows do begin
               setlength(Points[I-1],Cols);
               Spline:=LongCurves[I-1];
               OrgPts:=TFreeMatrix.Create;
               OrgPts.SetSize(3,Cols);
               for J:=1 to Cols do begin
                  P:=Spline.Value((J-1)/(Cols-1));
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
               OrgPts.Destroy;
               NewPts.Destroy;
            end;
            ColMatrix.Destroy;
   
            // interpolate rows
            for I:=1 to Cols do begin
               OrgPts:=TFreeMatrix.Create;
               OrgPts.SetSize(3,Rows);
               for J:=1 to Rows do begin
                  P:=Points[J-1][I-1];
                  OrgPts.Value[J-1,0]:=P.X;
                  OrgPts.Value[J-1,1]:=P.Y;
                  OrgPts.Value[J-1,2]:=P.Z;
               end;
               NewPts:=RowMatrix.Multiply(OrgPts);
               for J:=1 to Rows do begin
                  P.X:=NewPts.Value[J-1,0];
                  P.Y:=NewPts.Value[J-1,1];
                  if (OrgPts.Value[J-1,1]>=0.0) and (P.Y<0.0) then P.Y:=0.0;
                  P.Z:=NewPts.Value[J-1,2];
                  Points[J-1][I-1]:=P;
               end;
               OrgPts.Destroy;
               NewPts.Destroy;
            end;
            RowMatrix.Destroy;
   
            // delete long. curves
            for I:=1 to LongCurves.Count do begin
               Spline:=LongCurves[I-1];
               Spline.Destroy;
            end;
            LongCurves.Destroy;
   
            // import actual surface
            Setlength(ControlPoints,Rows);
            for I:=1 to Rows do begin
               Setlength(ControlPoints[I-1],Cols);
               for J:=1 to Cols do begin
                  ControlPoints[I-1][J-1]:=TFreesubdivisionControlPoint.Create(Ship.Surface);
                  Ship.Surface.AddControlPoint(ControlPoints[I-1][J-1]);
                  ControlPoints[I-1][J-1].Coordinate:=Points[I-1][J-1];
                //ControlPoints[I-1][J-1]:=FreeShip.Surface.AddControlPoint(Points[I-1][J-1]);
               end;
            end;
            Pts:=TFasterList.Create;
            for I:=2 to Rows do begin
               for J:=2 to Cols do begin
                  Pts.Clear;
                  P1:=ControlPoints[I-2][J-2];
                  Pts.Add(P1);
                  P1:=ControlPoints[I-2][J-1];
                  if Pts.IndexOf(P1)=-1 then Pts.Add(P1);
                  P1:=ControlPoints[I-1][J-1];
                  if Pts.IndexOf(P1)=-1 then Pts.Add(P1);
                  P1:=ControlPoints[I-1][J-2];
                  if Pts.IndexOf(P1)=-1 then Pts.Add(P1);
                  if Pts.Count>2 then Ship.Surface.AddControlFace(Pts,True);
               end;
            end;
            Pts.Destroy;
            Ship.FileChanged:=True;
//       finally
            if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
            Screen.Cursor:=PrevCursor;
//      end;
      end;
      Ship.Build:=False;
      Ship.Precision:=fpMedium;
      Ship.Draw;
   end;
   OpenDialog.Destroy;
end;

procedure TFreeEdit.File_ExportArchimedes;
var Frames     : TFasterList;
    Frame      : TFreeSpline;
    Tmp,Str    : widestring;
    I,J,Np     : integer;
    P          : T3DVector;
    SaveDialog : TSaveDialog;
    ffile      : textfile;
    Strings    : TStringList;
begin
   //if not Ship.ProjectSettings.FMainparticularsHasBeenset then begin
   //   MessageDlg(Userstring(95),mtWarning,[mbOk],0);
   //   exit;
   //end;
   Frames:=TFasterList.Create;
   Ship.FBuildValidFrameTable(Frames,True);
   if Frames.Count>0 then begin
      SaveDialog:=TSaveDialog.Create(Ship);
      SaveDialog.InitialDir:=Ship.Preferences.ExportDirectory;
      SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Ship.FileName),'');
      SaveDialog.Filter:='ArchimedesMB multi body hull data(*.hll)|*.hll|Archimedes single body hull data(*.app)|*.app';
      SaveDialog.FilterIndex:=1;
      Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
      if SaveDialog.Execute then begin
         Ship.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
         if SaveDialog.FilterIndex=2 then begin       // Single body Archimedes
            assignfile(ffile,ChangeFileExt(SaveDialog.FileName,'.app'));
            rewrite(FFile);
            Write(FFile,'***********************************************************'+#10);
            Write(FFile,'** Appendage Hydrostatics Generator Version 1.0.1        **'+#10);
            Write(FFile,'** Copyright : John A. MacSween - 2000                   **'+#10);
            Write(FFile,'** Please visit the website for updates and new versions **'+#10);
            Write(FFile,'**                          www.naval-architecture.co.uk **'+#10);
            Write(FFile,'** File generated with FREE!ship                         **'+#10);
            Write(FFile,'***********************************************************'+#10);
            // Hull name
            Write(FFile,'APPENDAGE_NAME'+#10);
            if Ship.ProjectSettings.ProjectName<>'' then Tmp:=Ship.ProjectSettings.ProjectName
                                    else Tmp:=ChangeFileExt(ExtractFilename(Ship.Filename),'');
            Write(FFile,Tmp+#10);
            // Aft perpendicular
            Write(FFile,'AP'+#10);
            Write(FFile,'0.0'+#10);
            // Forward perpendicular
            Write(FFile,'FP'+#10);
            Write(FFile,Truncate(Ship.ProjectSettings.ProjectLength,4)+#10);
            // Water density
            Write(FFile,'DENSITY'+#10);
            write(FFile,Truncate(Ship.ProjectSettings.ProjectWaterDensity,3)+#10);
            // Now send the frames
            Write(FFile,'NUMBER_OF_FRAMES'+#10);
            write(FFile,IntToStr(Frames.Count)+#10);
            Write(FFile,'***START_OF_FRAME_INFORMATION***'+#10);
            for I:=1 to Frames.Count do begin
               Frame:=Frames[I-1];
               Np:=Frame.NumberOfPoints;
               Write(FFile,'FRAME_INDEX: '+IntToStr(I-1)+#10);
               Write(FFile,'FRAME_NAME'+#10);
               Write(FFile,'Frame @ Y= '+FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4)+#10);
               Write(FFile,'FRAME_Y'+#10);
               Write(FFile,FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4)+#10);
               Write(FFile,'NUMBER_OF_COORDINATES'+#10);
               write(FFile,IntToStr(2*Np-1)+#10);
               Write(FFile,'***START_OF_ORDINATES***'+#10);

               // First send the starboard side
               for J:=Np downto 1 do begin
                  //P:=Frame.Value((J-1)/(Np-1));
                  P:=Frame.Point[J-1];
                  P.Y:=-P.Y;
                  Write(FFile,Truncate(P.Y,4)+#10);
                  Write(FFile,Truncate(P.Z,4)+#10);
               end;
               // then port side
               for J:=2 to Np do begin
                  //P:=Frame.Value((J-1)/(Np-1));
                  P:=Frame.Point[J-1];
                  Write(FFile,Truncate(P.Y,4)+#10);
                  Write(FFile,Truncate(P.Z,4)+#10);
               end;
               Write(FFile,'***END_OF_ORDINATES***'+#10);
               Frame.Destroy;
            end;
            Write(FFile,'***END_OF_FILE***'+#10);
            closefile(FFile);
         end else begin
            // Multi body ArchimedesMB
            Strings:=TStringList.Create;
            // Add file version info
            Strings.Add(' <?xml version="1.0" encoding="UTF-8" ?>');
            // Start hull
            Strings.Add('<HULL>');
            // Hull name
            Strings.Add('<HULL_NAME>');
            if Ship.ProjectSettings.ProjectName<>''
               then Str:=Ship.ProjectSettings.ProjectName
               else Str:=ChangeFileExt(ExtractFilename(Ship.Filename),'');
            Strings.Add(Str);
            Strings.Add('</HULL_NAME>');
            // Water density
            Strings.Add('<DENSITY>'+#32+Truncate(Ship.ProjectSettings.ProjectWaterDensity,3)+#32+'</DENSITY>');
            // Aft perpendicular
            Strings.Add('<AP> 0.0 </AP>');
            // Forward perpendicular
            Strings.Add('<FP>'+#32+Truncate(Ship.ProjectSettings.ProjectLength,4)+#32+'</FP>');
            // Draught marks
            Strings.Add('<FWD_DRAUGHT_MARK>'+#32+Truncate(Ship.ProjectSettings.ProjectDraft,4)+#32+'</FWD_DRAUGHT_MARK>');
            Strings.Add('<MID_DRAUGHT_MARK>'+#32+Truncate(Ship.ProjectSettings.ProjectDraft,4)+#32+'</MID_DRAUGHT_MARK>');
            Strings.Add('<AFT_DRAUGHT_MARK>'+#32+Truncate(Ship.ProjectSettings.ProjectDraft,4)+#32+'</AFT_DRAUGHT_MARK>');
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
            Strings.Add('<SECTION_COUNT>'+#32+IntToStr(Frames.Count)+#32+'</SECTION_COUNT>');
            for I:=1 to Frames.Count do
            begin
               Frame:=Frames[I-1];
               Np:=2*Frame.NumberOfPoints+1;
               Strings.Add('<SECTION>');
               Strings.Add('<SECTION_NAME>');
               Strings.Add(FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4));
               Strings.Add('</SECTION_NAME>');
               Strings.Add('<YCOORD>'+#32+FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4)+#32+'</YCOORD>');
               Strings.Add('<OFFSET_COUNT>'+#32+IntToStr(2*Np-1)+#32+'</OFFSET_COUNT>');
               Strings.Add('<OFFSETS>');
               // First send the starboard side
               for J:=Np downto 1 do
               begin
                  P:=Frame.Value((J-1)/(Np-1));
                  P.Y:=-P.Y;
                  Strings.Add(Truncate(P.Y,4)+#32+Truncate(P.Z,4));
               end;
               // then port side
               for J:=2 to Np do
               begin
                  P:=Frame.Value((J-1)/(Np-1));
                  Strings.Add(Truncate(P.Y,4)+#32+Truncate(P.Z,4));
               end;
               Strings.Add('</OFFSETS>');
               Strings.Add('</SECTION>');
               Frame.Destroy;
            end;
            Strings.Add('</APPENDAGE>');  // end of appendage
            Strings.Add('</HULL>');       // end of hull
            Strings.SaveToFile(ChangeFileExt(SaveDialog.FileName,'.hll'));
            Strings.Destroy;
         end;
      end else
      begin
         for I:=1 to Frames.Count do
         begin
            Frame:=Frames[I-1];
            Frame.Destroy;
         end;
      end;
      SaveDialog.Destroy;
   end;
   Frames.Destroy;
end;

// export the coordinates of all controlpoints to a textfile
procedure TFreeEdit.File_ExportCoordinates;
var I          : integer;
    Point      : TFreeSubdivisionPoint;
    SaveDialog : TSaveDialog;
    ffile      : textfile;
begin
   SaveDialog:=TSaveDialog.Create(Ship);
   SaveDialog.InitialDir:=Ship.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Ship.FileName),'');
   SaveDialog.Filter:='Text file(*.txt)|*.txt';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      Assignfile(FFile,ChangeFileExt(SaveDialog.FileName,'.txt'));
      {$I-}Rewrite(FFile);{$I+}
      if IOResult=0 then begin
         Ship.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
         {
         for I:=1 to Ship.Surface.NumberOfControlPoints do begin
            Point:=Ship.Surface.ControlPoint[I-1];
            Writeln(FFile,MakeLength(Point.Coordinate.X,6,12),#32,
                          MakeLength(Point.Coordinate.Y,6,12),#32,
                          MakeLength(Point.Coordinate.Z,6,12));
         end;
         }
         for I:=1 to Ship.Surface.NumberOfPoints do begin
            Point:=Ship.Surface.Point[I-1];
            Writeln(FFile,MakeLength(Point.Coordinate.X,6,12),#32,
                          MakeLength(Point.Coordinate.Y,6,12),#32,
                          MakeLength(Point.Coordinate.Z,6,12));
         end;
         CloseFile(FFile);
      end else ShowMessage( Userstring(97) );
   end;
   SaveDialog.Destroy;
end;

procedure TFreeIntersection.SaveToDXF(Strings:TStringList);
var I      : integer;
    Layer  : string;
    Spline : TFreeSpline;
begin
   if not built then Rebuild;
   for I:=1 to count do begin
      Spline:=Items[I-1];
      Case IntersectionType of
         fiStation   : layer:=Userstring(62);
         fiButtock   : layer:=Userstring(63);
         fiWaterline : layer:=Userstring(64);
         fiDiagonal  : layer:=Userstring(65);
         else Layer:='Layer_0';
      end;
      case Owner.Precision of
         fpLow      : Spline.Fragments:=50;
         fpMedium   : Spline.Fragments:=100;
         fpHigh     : Spline.Fragments:=150;
         fpVeryHigh : Spline.Fragments:=500;
         else Spline.Fragments:=100;
      end;
      Spline.SaveToDXF(Strings,Layer,Owner.Visibility.ModelView=mvBoth);
   end;
end;

// Export all intersections to an individual DXF file as 2D polylines
procedure TFreeEdit.File_ExportDXF_2DPolylines;
var I          : integer;
    Strings    : TStringList;
    Dialog     : TDXFExport2DDialog;
    ScaleFactor: Double;
    SegLength  : double;
    PrevCursor : TCursor;
    Filename   : string;
    Intersections:TFasterList;

    procedure CreateDXFData(Intersection:TFreeIntersection;Stringlist:TStringList;Scale:Double;var Filename:string);
     var I,N    :Integer;
         Layername:string;
         procedure SaveSpline(Spline:TFreeSpline;Strings:TStringList;IntersectionType:TFreeIntersectiontype);
         var NParams : Integer;
             Cap     : Integer;
             Params  : TFloatArray;
             I,Ind   : Integer;
             Length  : Double;
             T       : Double;
             P1,P2   : T3DVector;
         begin
            Ind:=FindDXFColorIndex(Spline.Color);
            NParams:=0;
            Setlength(Params,Spline.NumberOfPoints);
            // count number of knucklepoints
            if not Spline.Build then Spline.Rebuild;
            for I:=2 to Spline.NumberOfPoints-1 do begin
               if Spline.Knuckle[I-1] then begin
                  Params[NParams]:=Spline.Parameter[I-1];
                  inc(NParams);
               end;
            end;
            // Calculate the length of the spline
            Length:=0.0;
            P1:=Spline.Value(0.0);
            for I:=1 to 150 do begin
               P2:=Spline.Value(I/150);
               Length:=Length+Abs(P1-P2);
               P1:=P2;
            end;
            Length:=Length*ScaleFactor;
            if length>0 then begin
               N:=Round(Length/(SegLength));
               if N<2*Spline.NumberOfPoints then N:=2*Spline.NumberOfPoints;
               if N>3500 then N:=3500;
               Spline.Fragments:=N;
               Cap:=NParams+100;
               Setlength(Params,Cap);
               inc(Nparams);
               Params[NParams-1]:=0.0;
               inc(Nparams);
               Params[NParams-1]:=1.0;
               for I:=1 to Spline.Fragments do begin
                  T:=Spline.ChordlengthApproximation(I*SegLength/Length);
                  if NParams>=Cap then begin
                     inc(Cap,50);
                     Setlength(Params,Cap);
                  end;
                  inc(NParams);
                  Params[NParams-1]:=T;
               end;
               ArraySort( Params,NParams );
               // now export the actual calculated points
               Strings.Add('0'+EOL+'POLYLINE');
               Strings.Add('8'+EOL+LayerName);   // layername
               Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
               Strings.Add('66'+EOL+'1');    // vertices follow
               for I:=1 to NParams do begin
                  P1:=Spline.Value(Params[I-1]);
                  Strings.Add('0'+EOL+'VERTEX');
                  Strings.Add('8'+EOL+LayerName);

                  Case IntersectionType of
                     fiStation    : begin
                                       Strings.Add('10'+EOL+Truncate(Scale*P1.Y,5));
                                       Strings.Add('20'+EOL+Truncate(Scale*P1.Z,5));
                                    end;
                     fiButtock    : begin
                                       Strings.Add('10'+EOL+Truncate(Scale*P1.X,5));
                                       Strings.Add('20'+EOL+Truncate(Scale*P1.Z,5));
                                    end;
                     fiWaterline  : begin
                                       Strings.Add('10'+EOL+Truncate(Scale*P1.X,5));
                                       Strings.Add('20'+EOL+Truncate(Scale*P1.Y,5));
                                    end;
                  end;
               end;
               Strings.Add('0'+EOL+'SEQEND');
               if (Intersectiontype in [fiStation,fiWaterline])
               and (Ship.Visibility.ModelView=mvBoth) then begin
                  // send the other half
                  Strings.Add('0'+EOL+'POLYLINE');
                  Strings.Add('8'+EOL+LayerName);       // layername
                  Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
                  Strings.Add('66'+EOL+'1');            // vertices follow
                  for I:=1 to NParams do begin
                     P1:=Spline.Value(Params[I-1]);
                     Strings.Add('0'+EOL+'VERTEX');
                     Strings.Add('8'+EOL+LayerName);
                     Case IntersectionType of
                        fiStation: begin
                                     Strings.Add('10'+EOL+Truncate(Scale*-P1.Y,5));
                                     Strings.Add('20'+EOL+Truncate(Scale*P1.Z,5));
                                   end;
                        fiWaterline: begin
                                     Strings.Add('10'+EOL+Truncate(Scale*P1.X,5));
                                     Strings.Add('20'+EOL+Truncate(Scale*-P1.Y,5));
                                   end;
                     end;
                  end;
                  Strings.Add('0'+EOL+'SEQEND');
               end;
            end;
         end;{SaveSpline}

    begin
       if not Intersection.Built then Intersection.Rebuild;
       if intersection.Count>0 then
       begin
         Case Intersection.IntersectionType of
            fiStation  :begin Layername:=Userstring(62); end;
            fiButtock  :begin Layername:=Userstring(63); end;
            fiWaterline:begin Layername:=Userstring(64); end;
            fiDiagonal :begin Layername:=Userstring(65); end;
            else begin ShowMessage( Userstring(66)+'!' ); exit; end;
         end;
         Filename:=Ship.Preferences.ExportDirectory+Intersection.Description+'.dxf';
         for I:=1 to Intersection.Count do begin
            Intersection.Items[I-1].Color:=Intersection.Color;
            SaveSpline(Intersection.Items[I-1],Strings,Intersection.IntersectionType);
         end;
       end;
    end;
begin
   Dialog:=TDXFExport2DDialog.Create(Ship);
   ShowTranslatedValues(Dialog);
   Dialog.ExportDirectory:=Ship.Preferences.ExportDirectory;
   If Ship.ProjectSettings.ProjectUnits=fuMetric then Dialog.ComboBox1.ItemIndex:=0 else
      If Ship.ProjectSettings.ProjectUnits=fuImperial then Dialog.ComboBox1.ItemIndex:=3;

   if Dialog.Execute then begin
      Ship.Preferences.ExportDirectory:=Dialog.ExportDirectory;
      if Length(Ship.Preferences.ExportDirectory)>0 then
      if Ship.Preferences.ExportDirectory[Length(Ship.Preferences.ExportDirectory)]<>'\'
      then Ship.Preferences.ExportDirectory:=Ship.Preferences.ExportDirectory+'\';

      ScaleFactor:=1.0;
      SegLength:=Dialog.SegmentLength;
      If Ship.ProjectSettings.ProjectUnits=fuMetric then begin
         Case Dialog.ComboBox1.ItemIndex of
            0 : ScaleFactor:=1.0;         // Scale from meters to meters
            1 : ScaleFactor:=100;         // Scale from meters to centimeters
            2 : ScaleFactor:=1000;        // Scale from meters to millimeters
            3 : ScaleFactor:=1/Foot;      // Scale from meters to feet
            4 : ScaleFactor:=12/Foot;     // Scale from meters to inches
         end;
      end else If Ship.ProjectSettings.ProjectUnits=fuImperial then begin
         Case Dialog.ComboBox1.ItemIndex of
            0 : ScaleFactor:=Foot;        // Scale from feet to meters
            1 : ScaleFactor:=100*foot;    // Scale from feet to centimeters
            2 : ScaleFactor:=1000*foot;   // Scale from feet to millimeters
            3 : ScaleFactor:=1.0;         // Scale from feet to feet
            4 : ScaleFactor:=12;          // Scale from feet to inches
         end;
      end;
      Strings:=TStringList.Create;
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourGlass;
//    try
         if Dialog.CheckBox1.Checked then begin
            // send each intersection to an individual dxf file
            Intersections:=TFasterList.Create;
            if Ship.Visibility.ShowStations then Intersections.AddList(Ship.FStations);
            if Ship.Visibility.ShowButtocks then Intersections.AddList(Ship.FButtocks);
            if Ship.Visibility.ShowWaterlines then Intersections.AddList(Ship.FWaterlines);
            for I:=1 to Intersections.Count do begin
               Strings.Clear;
               Strings.Add('0'+EOL+'SECTION');
               Strings.Add('2'+EOL+'ENTITIES');
               CreateDXFData(Intersections[I-1],Strings,ScaleFactor,Filename);
               Strings.Add('0'+EOL+'ENDSEC');
               Strings.Add('0'+EOL+'EOF');
               Strings.SaveToFile(Filename);
            end;
            Intersections.Destroy;
         end else begin
            if (Ship.Visibility.ShowStations)
            and (Ship.NumberofStations>0) then begin
               Strings.Clear;
               Strings.Add('0'+EOL+'SECTION');
               Strings.Add('2'+EOL+'ENTITIES');
               for I:=1 to Ship.NumberofStations do CreateDXFData(Ship.Station[I-1],Strings,ScaleFactor,Filename);
               Strings.Add('0'+EOL+'ENDSEC');
               Strings.Add('0'+EOL+'EOF');
               Filename:=Ship.Preferences.ExportDirectory+'stations.dxf';
               Strings.SaveToFile(Filename);
            end;
            if (Ship.Visibility.ShowButtocks)
            and (Ship.NumberofButtocks>0) then begin
               Strings.Clear;
               Strings.Add('0'+EOL+'SECTION');
               Strings.Add('2'+EOL+'ENTITIES');
               for I:=1 to Ship.NumberofButtocks do CreateDXFData(Ship.Buttock[I-1],Strings,ScaleFactor,Filename);
               Strings.Add('0'+EOL+'ENDSEC');
               Strings.Add('0'+EOL+'EOF');
               Filename:=Ship.Preferences.ExportDirectory+'buttocks.dxf';
               Strings.SaveToFile(Filename);
            end;
            if (Ship.Visibility.ShowWaterlines)
            and (Ship.NumberofWaterlines>0) then begin
               Strings.Clear;
               Strings.Add('0'+EOL+'SECTION');
               Strings.Add('2'+EOL+'ENTITIES');
               for I:=1 to Ship.NumberofWaterlines do CreateDXFData(Ship.Waterline[I-1],Strings,ScaleFactor,Filename);
               Strings.Add('0'+EOL+'ENDSEC');
               Strings.Add('0'+EOL+'EOF');
               Filename:=Ship.Preferences.ExportDirectory+'waterlines.dxf';
               Strings.SaveToFile(Filename);
            end;
         end;
//    finally
         Strings.Destroy;
         Screen.Cursor:=PrevCursor;
//    end;
   end;
   Dialog.Destroy;
end;{TFreeEdit.File_ExportDXF_2DPolylines}

// Export all lines to a 3D DXF model as polylines
procedure TFreeEdit.File_ExportDXF_3DPolylines;
var I,J,ind : integer;
    Strings : TStringList;
    Dialog  : TSaveDialog;
    Edges   : TFasterList;
    Points  : TFasterList;
    Point   : TFreeSubdivisionPoint;
    Layername:string;
begin
   Dialog:=TSaveDialog.Create(Ship);
   Dialog.InitialDir:=Ship.Preferences.ExportDirectory;
   Dialog.FileName:=ChangeFileExt(ExtractFilename(Ship.FileName),'.dxf');
   Dialog.Filter:='Autocad dxf file (*.dxf)|*.dxf';
   dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if Dialog.Execute then
   begin
      Ship.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
      Strings:=TStringList.Create;
      Strings.Add('0'+EOL+'SECTION');
      Strings.Add('2'+EOL+'ENTITIES');
      if Ship.Visibility.ShowStations then for I:=1 to Ship.NumberofStations do Ship.Station[I-1].SaveToDXF(Strings);
      if Ship.Visibility.ShowButtocks then for I:=1 to Ship.NumberofButtocks do Ship.Buttock[I-1].SaveToDXF(Strings);
      if Ship.Visibility.ShowWaterlines then for I:=1 to Ship.NumberofWaterlines do Ship.Waterline[I-1].SaveToDXF(Strings);
      if Ship.Visibility.ShowDiagonals then for I:=1 to Ship.NumberofDiagonals do Ship.Diagonal[I-1].SaveToDXF(Strings);
      if Ship.Visibility.ShowControlCurves then for I:=1 to Ship.NumberofControlCurves do Ship.ControlCurve[I-1].SaveToDXF(Strings);

      Edges:=TFasterList.Create;
      Ship.Surface.ExtractAllEdgeLoops(Edges);
      Layername:='Edges';
      ind:=FindDXFColorIndex(Ship.Preferences.EdgeColor);
      for I:=1 to Edges.Count do
      begin
         Points:=Edges[I-1];
         Strings.Add('0'+EOL+'POLYLINE');
         Strings.Add('8'+EOL+LayerName);   // layername
         Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
         Strings.Add('70'+EOL+'10');   // not closed
         Strings.Add('66'+EOL+'1');    // vertices follow
         for J:=1 to Points.Count do
         begin
            Point:=Points[J-1];
            Strings.Add('0'+EOL+'VERTEX');
            Strings.Add('8'+EOL+LayerName);
            Strings.Add('10'+EOL+Truncate(Point.Coordinate.X,4));
            Strings.Add('20'+EOL+Truncate(Point.Coordinate.Y,4));
            Strings.Add('30'+EOL+Truncate(Point.Coordinate.Z,4));
            Strings.Add('70'+EOL+'32');    // 3D polyline mesh vertex
         end;
         Strings.Add('0'+EOL+'SEQEND');
         if Ship.Visibility.ModelView=mvBoth then
         begin
            Strings.Add('0'+EOL+'POLYLINE');
            Strings.Add('8'+EOL+LayerName);   // layername
            Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
            Strings.Add('70'+EOL+'10');   // not closed
            Strings.Add('66'+EOL+'1');    // vertices follow
            for J:=1 to Points.Count do
            begin
               Point:=Points[J-1];
               Strings.Add('0'+EOL+'VERTEX');
               Strings.Add('8'+EOL+LayerName);
               Strings.Add('10'+EOL+Truncate(Point.Coordinate.X,4));
               Strings.Add('20'+EOL+Truncate(-Point.Coordinate.Y,4));
               Strings.Add('30'+EOL+Truncate(Point.Coordinate.Z,4));
               Strings.Add('70'+EOL+'32');    // 3D polyline mesh vertex
            end;
            Strings.Add('0'+EOL+'SEQEND');
         end;
         Points.Destroy;
      end;
      Edges.Destroy;
      Strings.Add('0'+EOL+'ENDSEC');
      Strings.Add('0'+EOL+'EOF');
      Strings.SaveToFile(ChangeFileExt(Dialog.FileName,'.dxf'));
      Strings.Destroy;
   end;
   Dialog.Destroy;
end;{TFreeEdit.File_ExportDXF_3DPolylines}

// Export all faces to a 3D DXF model
procedure TFreeEdit.File_ExportDXF_Faces;
var I       : integer;
    Strings : TStringList;
    Dialog  : TSaveDialog;
    Prev    : TCursor;
begin
   Dialog:=TSaveDialog.Create(Ship);
   Dialog.InitialDir:=Ship.Preferences.ExportDirectory;
   Dialog.FileName:=ChangeFileExt(ExtractFilename(Ship.FileName),'.dxf');
   Dialog.Filter:='Autocad dxf file (*.dxf)|*.dxf';
   dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if Dialog.Execute then
   begin
      Prev:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
//    try
         Ship.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
         Strings:=TStringList.Create;
         Strings.Add('0'+EOL+'SECTION');
         Strings.Add('2'+EOL+'ENTITIES');
         for I:=1 to Ship.Surface.NumberOfLayers do Ship.Surface.Layer[I-1].SaveToDXF(Strings);
         Strings.Add('0'+EOL+'ENDSEC');
         Strings.Add('0'+EOL+'EOF');
//       try
            Strings.SaveToFile( ChangeFileExt(Dialog.FileName,'.dxf') );
//       except
//          MessageDlg('Could not access '+ChangeFileExt(Dialog.FileName,'.dxf'),mtError,[mbOk],0);
//       end;
//    finally
         Screen.Cursor:=Prev;
//    end;
      Strings.Destroy;
   end;
   Dialog.Destroy;
end;

// Save ordinates to the GHS file format

procedure TFreeEdit.File_ExportGHS;
var I,J        : integer;
    Section    : TFreeSpline;
    SaveDialog : TSaveDialog;
    Strings    : TStringList;
    PrevCursor : TCursor;
    Scale      : TFloatType;
    Frames     : TFasterList;
    Str        : string;
    P          : T3DVector;
    NParams    : Integer;
    Params     : TFloatArray;
begin
   //if not Ship.ProjectSettings.FMainparticularsHasBeenset then begin
   //   ShowMessage( Userstring(95) );
   //   exit;
   //end;
   SaveDialog:=TSaveDialog.Create(Ship);
   SaveDialog.InitialDir:=Ship.Preferences.ExportDirectory;
   Str:=ChangeFileExt(ExtractFilename(Ship.Filename),'.GF');
   // no spaces allowed in filename
   repeat
      I:=Pos(#32,Str);
      if I<>0 then Delete(Str,I,1);
   until I=0;
   Savedialog.FileName:=Str;
   SaveDialog.Filter:='GHS files (*.Gf)|*.Gf';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if not SaveDialog.Execute then begin
      Savedialog.Destroy;
      exit;
   end;
   Ship.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   Strings:=TStringList.Create;
   Frames:=TFasterList.Create;
// try
      Ship.FBuildValidFrameTable(Frames,True);
      if Ship.ProjectSettings.ProjectUnits=fuImperial then Scale:=1.0
                                                      else Scale:=1/Foot;
      Str:=Ship.ProjectSettings.ProjectName;
      if Length(Str)>58 then Str:=copy(Str,1,58);
      Strings.Add(Str);                                                                    // ProjectDescription, max 58 characters
      Strings.Add('L:'+FloatToStrF(Scale*Ship.ProjectSettings.ProjectLength,ffFixed,7,3)); // Length
      Strings.Add('W:'+FloatToStrF(Scale*Ship.ProjectSettings.ProjectBeam,ffFixed,7,3));   // Beam
      Strings.Add('OL:Frame 0');
      Strings.Add('OT:Centerplane');
      Strings.Add('OV:Baseline');                           // Units preference
      if Ship.ProjectSettings.ProjectUnits=fuMetric then Strings.Add('P:M')
                                                     else Strings.Add('P:F');
      // Add max. 10 comments
      Strings.Add('\Generated with FREE!ship');
//    Strings.Add('\www.freeship.org');
      // Save shape
      Strings.Add('*');
      Strings.Add('HULL'); // shape name
      Strings.Add(IntToStr(Frames.Count)); // Number of sections
      for I:=Frames.Count downto 1 do begin
         Section:=Frames[I-1];
         if Section.NumberOfPoints>0 then begin
            if section.Point[Section.NumberOfPoints-1].Y>0 then begin
               Section.Knuckle[Section.NumberOfPoints-1]:=true;
               Section.Add(Section.Point[Section.NumberOfPoints-1]);
            end;
         end;
         NParams:=0;
         Setlength(Params,Section.NumberOfPoints); // count number of knucklepoints
         for J:=2 to Section.NumberOfPoints-1 do begin
            if Section.Knuckle[J-1] then begin
               Params[NParams]:=Section.Parameter[J-1];
               inc(NParams);
            end;
         end;
         if Section.NumberOfPoints>100 then begin
            Section.Fragments:=100;
            Setlength(Params,NParams+Section.Fragments);
            for J:=1 to Section.Fragments do begin
               Params[NParams]:=(J-1)/(Section.Fragments-1);
               inc(NParams);
            end;
         end else begin
            Setlength(Params,NParams+Section.NumberOfPoints);
            for J:=1 to Section.NumberOfPoints do begin
               Params[NParams]:=Section.Parameter[J-1];
               inc(NParams);
            end;
         end;
         ArraySort( Params,NParams );
         Strings.Add(Truncate(-Scale*Section.Min.X,4)+','+IntToStr(NParams));
         for J:=1 to NParams do begin
            P:=Section.Value(Params[J-1]);
            Strings.Add(Truncate(Scale*P.Y,4)+','+Truncate(Scale*P.Z,4));
         end;
         Section.Destroy;
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
      if Ship.ProjectSettings.ProjectUnits=fuMetric
         then Strings.Add(FloatToStrF(Ship.ProjectSettings.ProjectWaterDensity,ffFixed,7,3)) // specific gravity of water
         else Strings.Add(FloatToStrF(Ship.ProjectSettings.ProjectWaterDensity/WeightConversionFactor,ffFixed,7,3));
      Strings.Add('0,0,0');      // ReferencePoint
      Strings.Add('1');          // Number of components
      Strings.Add('HULL.C');     // Componentname
      // Mark end of file
      Strings.Add('****');
      Str:=ChangeFileExt(ExtractFilename(Savedialog.FileName),'.GF');
      // no spaces allowed in filename
      repeat
         I:=Pos(#32,Str);
         if I<>0 then Delete(Str,I,1);
      until I=0;
      Str:=ExtractFilePath(SaveDialog.Filename)+Str;
      Strings.SaveToFile(Str);

      SaveDialog.Destroy;
// finally
      Frames.Destroy;
      Screen.Cursor:=PrevCursor;
      Strings.Destroy;
// end;
end;{TFreeEdit.File_ExportGHS}

// Save part of the geometry to a file
procedure TFreeEdit.File_ExportPart;
var SelectDlg  : TFreeSelectLayersDialog;
    Faces      : TFasterList;
    I          : Integer;
begin
   Faces:=TFasterList.Create;
   if Ship.NumberOfSelectedControlFaces=0 then begin
      SelectDlg:=TFreeSelectLayersDialog.Create(Ship);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(Ship,fsFaces) then SelectDlg.ExtractSelectedFaces(Faces);
      for I:=Ship.NumberOfSelectedControlFaces downto 1 do Ship.SelectedControlFace[I-1].Selected:=false;
      Ship.Redraw;
      SelectDlg.Destroy;
   end else begin
      Faces.Capacity:=Faces.Count+Ship.NumberOfSelectedControlFaces;
      for I:=1 to Ship.NumberOfSelectedControlFaces do Faces.Add(Ship.SelectedControlFace[I-1]);
   end;
   if Faces.Count>0 then Ship.SavePart(Faces);
   Faces.Destroy;
end;

// Save NURBS patches to an IGES file
procedure TFreeEdit.File_ExportIGES;
const MinimizeFaces  = True;
      SendTriangles  = False; // true;
var I,J,K,Cols,Rows,NAssembled,PrevLevel,ColorIndex,NSurfaces: Integer;
    ColorIndices  : array of Integer;
    Dialog        : TSaveDialog;
    Prev          : TCursor;
    Layers,CheckFaces: TFasterlist;
    Layer         : TFreeSubdivisionLayer;
    FaceData      : TFreeFaceGrid;
    Assembled     : TFreeFaceArray;
    IGESList      : TFreeIGESList;
    Grid          : TFreeSubdivisionGrid;
    CtrlFace      : TFreeSubdivisionControlFace;
    Face          : TFreeSubdivisionFace;

    function FindFourtPoint(P1,P2,p3:TFreeSubdivisionPoint):TFreeSubdivisionPoint;
    var Face  : TFreeSubdivisionFace;
        I,J   : Integer;
        List  : TList;
    begin
       Result:=nil;
       if (P1<>P2) and (P2<>P3) and (P1<>P3) then begin
          for I:=1 to P2.NumberOfFaces do begin
             Face:=P2.Face[I-1];
             if (Face.IndexOfPoint(P1)<>-1) and
             // (Face.IndexOfPoint(P2)<>-1) and
                (Face.IndexOfPoint(P3)<>-1)
             then begin
                List:=TList.Create;
                for J:=1 to face.NumberOfpoints do list.Add(Face.Point[J-1]);
                J:=List.IndexOf(P1);
                if J<>-1 then list.Delete(J);
                J:=List.IndexOf(P2);
                if J<>-1 then list.Delete(J);
                J:=List.IndexOf(P3);
                if J<>-1 then list.Delete(J);
                if list.Count>0 then result:=List[0];
                List.Destroy;
             end;
          end;
       end;
    end;{FindFourtPoint}

    procedure FindOpposingPoints(P1,P2,P3,P4:TFreeSubdivisionPoint;var OppPoint2,OppPoint3:TFreeSubdivisionPoint);
    // find the points opposite to P2 and P3
    var I,Index:Integer;
        Edge:TFreeSubdivisionEdge;
        Face:TFreeSubdivisionface;
    begin
       OppPoint2:=nil;
       OppPoint3:=nil;
       Edge:=Ship.Surface.EdgeExists(P2,P3);
       if Edge<>nil then if not Edge.Crease then begin
          for I:=1 to Edge.NumberOfFaces do begin
             Face:=Edge.Face[I-1];
             if (Face.IndexOfPoint(P1)=-1) or
                (Face.IndexOfPoint(P2)=-1) or
                (Face.IndexOfPoint(P3)=-1) or
                (Face.IndexOfPoint(P4)=-1) then
             begin
                Index:=Face.IndexOfPoint(P3);
                if Index<>-1 then begin
                   Index:=(Index+1) mod Face.NumberOfpoints;
                   if Face.Point[index]=P2 then begin   // face is oriented CCW
                      Index:=(Index+1) mod Face.NumberOfpoints;
                      OppPoint2:=Face.Point[index];
                      Index:=(Index+1) mod Face.NumberOfpoints;
                      OppPoint3:=Face.Point[index];
                   end else begin
                      Index:=Face.IndexOfPoint(P2);
                      if Index<>-1 then begin
                         Index:=(Index+1) mod Face.NumberOfpoints;
                         if Face.Point[index]=P3 then begin // face is oriented CW
                            Index:=(Index+1) mod Face.NumberOfpoints;
                            OppPoint3:=Face.Point[index];
                            Index:=(Index+1) mod Face.NumberOfpoints;
                            OppPoint2:=Face.Point[index];
                         end;
                      end;
                   end;
                end;
                break;
             end;
          end;
       end;
    end;{FindOpposingPoints}

    procedure AssembleTriangle(var Cols,Rows:Integer;var Grid:TFreeSubdivisionGrid;Face:TFreeSubdivisionControlface);
    var I,J,N, Index: Integer;
        Points,Faces: TFasterList;
        Child: TFreeSubdivisionface;
        P,InteriorPoint: TFreeSubdivisionPoint;
    begin // Initialize grid
      Cols:=0;
      Rows:=0;

      Points:=TFasterList.Create;
      Faces:=TFasterList.Create;
      for I:=1 to Face.ChildCount do begin
         Child:=Face.Child[I-1];
         Faces.Add(Child);
         for J:=1 to Child.NumberOfpoints do begin
            P:=Child.Point[J-1];
            if Points.SortedIndexOf(P)=-1 then Points.AddSorted(P);
         end;
      end;
      Faces.Sort;                          // Try to isolate the interior point
      InteriorPoint:=nil;
      for I:=1 to Points.Count do begin
         P:=Points[I-1]; // check how many of the childfaces are connected (interior point must have 3)
         N:=0;
         for J:=1 to P.NumberOfFaces do
            if Faces.SortedIndexOf(P.Face[J-1])<>-1 then inc(N);
         if N=3 then begin
            InteriorPoint:=P;
            break;
         end;
      end;
      if Interiorpoint<>nil then begin
         Cols:=3;
         Rows:=3;
         Setlength(Grid,Rows);
         for I:=1 to Rows do begin
            Setlength(Grid[I-1],Cols);
            for J:=1 to Cols do Grid[I-1][J-1]:=nil;
         end;

         Grid[1][1]:=InteriorPoint;
         Child:=Face.Child[2];
         Index:=Child.IndexOfPoint(InteriorPoint);
         Grid[1][0]:=Child.Point[(index+1) mod 4];
         Grid[0][0]:=Child.Point[(index+2) mod 4];
         Grid[0][1]:=Child.Point[(index+3) mod 4];
         FindOpposingPoints(Grid[0][0],Grid[0][1],Grid[1][1],Grid[1][0],Grid[0][2],Grid[1][2]);
         FindOpposingPoints(Grid[0][1],Grid[1][1],Grid[1][0],Grid[0][0],Grid[2][1],Grid[2][0]);

         Grid[2][2]:=Grid[2][1];
       { for I:=1 to Rows do
            for J:=1 to cols do if grid[I-1][j-1]=nil then
                begin Raise Exception.create(Userstring(98)); end;
       }
      end; // else ShowMessage( Userstring(99) );
      Faces.Destroy;
      Points.Destroy;
    end;{AssembleTriangle}

    procedure ProcessGrid(Cols,Rows:Integer;Grid:TFreeSubdivisionGrid;ColorInd:Integer);
    // convert grid to a NURB
    var NURB,NURB2: TFreeNURBsurface;
        I,J       : Integer;
        BottomRow,TopRow,LeftColumn,RightColumn: array of TFreeSubdivisionPoint;
        BottomLeft,BottomRight,TopLeft,TopRight: TFreeSubdivisionPoint;
        BottomPresent,LeftPresent,RightPresent,TopPresent: Boolean;
        P: T3DVector;

        function PhantomPoint( BorderPoint,InnerPoint:T3DVector ):T3DVector;
           begin Result:=2.0*BorderPoint-InnerPoint; end;     {PhantomPoint}

        function CornerPoint(P5,P6,P8,P9:T3DVector):T3DVector;
        var P2,P3,P4,P7:T3DVector;
        begin
           P2:=PhantomPoint(P5,P8);
           P3:=PhantomPoint(P6,P9);
           P4:=PhantomPoint(P5,P6);
           P7:=PhantomPoint(P8,P9);
           Result.X:=20*P5.X-4*P2.X-P3.X-4*P4.X-4*P6.X-P7.X-4*P8.X-P9.X;
           Result.Y:=20*P5.Y-4*P2.Y-P3.Y-4*P4.Y-4*P6.Y-P7.Y-4*P8.Y-P9.Y;
           Result.Z:=20*P5.Z-4*P2.Z-P3.Z-4*P4.Z-4*P6.Z-P7.Z-4*P8.Z-P9.Z;
        end;{CornerPoint}

    begin
      if (Cols>0) and (Rows>0) then begin
         Setlength(BottomRow,Cols);
         Setlength(TopRow,Cols);
         Setlength(LeftColumn,Rows);
         Setlength(RightColumn,Rows);

         // assemble bottom row to set tangency
         BottomPresent:=True;
         for I:=2 to Cols do begin
            FindOpposingPoints(Grid[Rows-2][I-2],Grid[Rows-1][I-2],Grid[Rows-1][I-1],Grid[Rows-2][I-1],BottomRow[I-2],BottomRow[I-1]);
            if (BottomRow[I-2]=nil) or (BottomRow[I-1]=nil) then BottomPresent:=false;
         end;
         RightPresent:=True;
         // assemble right column to set tangency
         for I:=2 to Rows do begin
            FindOpposingPoints(Grid[I-1][Cols-2],Grid[I-1][Cols-1],Grid[I-2][Cols-1],Grid[I-2][Cols-2],RightColumn[I-1],RightColumn[I-2]);
            if (RightColumn[I-1]=nil) or (RightColumn[I-2]=nil) then RightPresent:=false;
         end;
         // assemble top row
         TopPresent:=True;
         for I:=2 to Cols do begin
            FindOpposingPoints(Grid[1][I-1],Grid[0][I-1],Grid[0][I-2],Grid[1][I-2],TopRow[I-1],TopRow[I-2]);
            if (TopRow[I-2]=nil) or (TopRow[I-1]=nil) then TopPresent:=false;
         end;
         // Assemble left column
         LeftPresent:=True;
         for I:=2 to Rows do begin
            FindOpposingPoints(Grid[I-2][1],Grid[I-2][0],Grid[I-1][0],Grid[I-1][1],LeftColumn[I-2],LeftColumn[I-1]);
            if (LeftColumn[I-1]=nil) or (LeftColumn[I-2]=nil) then LeftPresent:=false;
         end;
         BottomLeft:=nil;
         BottomRight:=nil;
         TopLeft:=nil;
         TopRight:=nil;

         if BottomPresent and leftPresent then BottomLeft:=FindFourtPoint(LeftColumn[Rows-1],Grid[Rows-1][0],BottomRow[0]);               // find bottomleft cornerpoint
         if BottomPresent and RightPresent then BottomRight:=FindFourtPoint(RightColumn[Rows-1],Grid[Rows-1][Cols-1],BottomRow[Cols-1]);  // find bottomRight cornerpoint
         if TopPresent and leftPresent then TopLeft:=FindFourtPoint(LeftColumn[0],Grid[0][0],TopRow[0]);                                  // find Topleft cornerpoint
         if TopPresent and RightPresent then TopRight:=FindFourtPoint(RightColumn[0],Grid[0][Cols-1],TopRow[Cols-1]);                     // find TopRight cornerpoint

         NURB:=TFreeNURBsurface.Create;
         NURB.SetCapacity(Cols+2,Rows+2);
         NURB.ColCount:=Nurb.ColCapacity;
         NURB.RowCount:=Nurb.RowCapacity;
         for I:=1 to Rows do begin
            for J:=1 to COLS do begin
               NURB.Point[J,I]:=Grid[I-1][J-1].Coordinate;
            end;
         end;
         if SendTriangles then begin // check for special triangle case
            if (Grid[Rows-1][Cols-1]=Grid[Rows-1][Cols-2]) and
               (Grid[Rows-1][Cols-1]=Grid[Rows-2][Cols-1]) then
            begin
               Nurb.Point[Cols,Rows]:=Grid[Rows-1][Cols-1].LimitPoint;
               Nurb.Point[Cols-1,Rows]:=Grid[Rows-1][Cols-1].LimitPoint;
               Nurb.Point[Cols,Rows-1]:=Grid[Rows-1][Cols-1].LimitPoint;
               Nurb.RowCount:=Nurb.RowCount-1+1;
            end;
         end;
         if TopPresent then for I:=1 to Cols do Nurb.Point[I,0]:=TopRow[I-1].Coordinate
                       else for I:=1 to Cols do Nurb.Point[I,0]:=PhantomPoint(Nurb.Point[I,1],Nurb.Point[I,2]);
         if BottomPresent then for I:=1 to Cols do Nurb.Point[I,Rows+1]:=BottomRow[I-1].Coordinate
                          else for I:=1 to Cols do Nurb.Point[I,Rows+1]:=PhantomPoint(Nurb.Point[I,Rows],Nurb.Point[I,Rows-1]);
         if LeftPresent then for I:=1 to Rows do Nurb.Point[0,I]:=LeftColumn[I-1].Coordinate
                        else for I:=1 to Rows do Nurb.Point[0,I]:=PhantomPoint(Nurb.Point[1,I],Nurb.Point[2,I]);
         if RightPresent then for I:=1 to Rows do Nurb.Point[Cols+1,I]:=RightColumn[I-1].Coordinate
                         else for I:=1 to Rows do Nurb.Point[Cols+1,I]:=PhantomPoint(Nurb.Point[Cols,I],Nurb.Point[Cols-1,I]);

         if TopLeft<>nil then Nurb.Point[0,0]:=TopLeft.Coordinate
                         else Nurb.Point[0,0]:=CornerPoint(Nurb.Point[1,1],Nurb.Point[2,1],Nurb.Point[1,2],Nurb.Point[2,2]);
         if TopRight<>nil then Nurb.Point[Nurb.ColCount-1,0]:=TopRight.Coordinate
                          else Nurb.Point[Nurb.ColCount-1,0]:=CornerPoint(Nurb.Point[Nurb.Colcount-2,1],Nurb.Point[Nurb.Colcount-3,1],Nurb.Point[Nurb.Colcount-2,2],Nurb.Point[Nurb.Colcount-3,2]);
         if BottomLeft<>nil then Nurb.Point[0,Nurb.RowCount-1]:=BottomLeft.Coordinate
                            else Nurb.Point[0,Nurb.RowCount-1]:=CornerPoint(Nurb.Point[1,Nurb.Rowcount-2],Nurb.Point[2,Nurb.Rowcount-2],Nurb.Point[1,Nurb.Rowcount-3],Nurb.Point[2,Nurb.Rowcount-3]);
         if BottomRight<>nil then Nurb.Point[Nurb.ColCount-1,Nurb.RowCount-1]:=BottomRight.Coordinate
                             else Nurb.Point[Nurb.ColCount-1,Nurb.RowCount-1]:=CornerPoint(Nurb.Point[Nurb.Colcount-2,Nurb.Rowcount-2],Nurb.Point[Nurb.Colcount-3,Nurb.Rowcount-2],Nurb.Point[Nurb.Colcount-2,Nurb.Rowcount-3],Nurb.Point[Nurb.Colcount-3,Nurb.Rowcount-3]);

         NURB.ColDegree:=3;
         NURB.RowDegree:=3;
         NURB.SetUniformColKnotvector;
         NURB.SetUniformRowKnotvector;

         // Insert knots to force the patch to interpolate start and endknots
         for I:=1 to Nurb.ColDegree do Nurb.InsertColKnot(Nurb.Colknotvector[Nurb.ColDegree]);
         for I:=1 to Nurb.ColDegree do Nurb.InsertColKnot(Nurb.Colknotvector[Nurb.ColCount]);
         for I:=1 to Nurb.RowDegree do Nurb.InsertRowKnot(Nurb.Rowknotvector[Nurb.RowDegree]);
         for I:=1 to Nurb.RowDegree do Nurb.InsertRowKnot(Nurb.Rowknotvector[Nurb.RowCount]);
         // Delete old startpoints
         for I:=1 to Nurb.ColDegree do Nurb.DeleteColumn(0);
         for I:=1 to Nurb.ColDegree do Nurb.DeleteColumn(Nurb.ColCount-1);
         for I:=1 to Nurb.RowDegree do Nurb.DeleteRow(0);
         for I:=1 to Nurb.RowDegree do Nurb.DeleteRow(Nurb.RowCount-1);
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
         Nurb.Point[0,0]:=Grid[0][0].LimitPoint;
         Nurb.Point[Cols+1,0]:=Grid[0][Cols-1].LimitPoint;
         Nurb.Point[0,Rows+1]:=Grid[Rows-1][0].LimitPoint;
         Nurb.Point[Cols+1,Rows+1]:=Grid[Rows-1][Cols-1].LimitPoint;
         IGESList.Add_Entity_128(NURB,ColorInd);
         if Ship.Visibility.ModelView=mvBoth then begin
            NURB2:=TFreeNURBsurface.Create;
            NURB2.SetCapacity(Nurb.ColCount,Nurb.RowCount);
            NURB2.ColCount:=Nurb2.ColCapacity;
            NURB2.RowCount:=Nurb2.RowCapacity;
            NURB2.ColDegree:=Nurb.ColDegree;
            NURB2.RowDegree:=Nurb.RowDegree;
            for I:=Nurb.ColCount downto 1 do begin
               for J:=Nurb.RowCount downto 1 do begin
                  P:=NURB.Point[I-1,J-1];
                  P.Y:=-P.Y;
                  NURB2.Point[NURB2.Colcount-I,Nurb2.RowCount-J]:=P;
               end;
            end;
            NURB2.SetDefaultColKnotvector;
            NURB2.SetDefaultRowKnotvector;
            IGESList.Add_Entity_128(NURB2,ColorInd);
            inc(NSurfaces);
            NURB2.Destroy;
         end;
         inc(NSurfaces);
         NURB.Destroy;
      end;
    end;{ProcessGrid}

begin
   Dialog:=TSaveDialog.Create(Ship);
   Dialog.InitialDir:=Ship.Preferences.ExportDirectory;
   Dialog.FileName:=ChangeFileExt(ExtractFilename(Ship.FileName),'.igs');
   Dialog.Filter:='IGES files (*.igs)|*.igs';
   dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if Dialog.Execute then begin
      Prev:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      PrevLevel:=Ship.Surface.DesiredSubdivisionLevel;
      NSurfaces:=0;
//    try
         Ship.Surface.DesiredSubdivisionLevel:=1;
         Ship.Surface.SubdivisionMode:=fmCatmullClark;
         if not Ship.Surface.Build then Ship.Surface.Rebuild;
         Ship.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
         IGESList:=TFreeIGESList.Create;
         IGESList.IGESUnits:=Ship.ProjectSettings.ProjectUnits;
         IGESList.SystemID:='FREE!ship'+#32+VersionString(CurrentVersion);
         IGESList.FileCreatedBy:=Ship.ProjectSettings.ProjectFileCreatedBy;
         IGESList.FileName:=Dialog.FileName;
         // Build color table
         Layers:=TFasterList.Create;
         for I:=1 to Ship.NumberOfLayers do
           if (Ship.Layer[I-1].Visible)
           and (Ship.Layer[I-1].Count>0) then Layers.Add(Ship.Layer[I-1]);
         Layers.Sort;
         Setlength(ColorIndices,Layers.Count);
         for I:=1 to Layers.Count do begin
            Layer:=Layers[I-1];
            ColorIndices[I-1]:=IGESList.Add_Entity_314(Layer.Color);
         end;
         if MinimizeFaces then begin
            Ship.Surface.AssembleFacesToPatches(Layers,amNURBS,Assembled,NAssembled);
            CheckFaces:=TFasterList.Create;
            for I:=1 to NAssembled do begin
               FaceData:=Assembled[I-1];
               CheckFaces.Clear;
               Checkfaces.Capacity:=FaceData.NCols*FaceData.NRows;
               for J:=1 to Facedata.NRows do
                  for K:=1 to FaceData.NCols do CheckFaces.Add(Facedata.Faces[J-1][K-1]);
               if (FaceData.NCols>0) and (FaceData.NRows>0) then begin
                  if ((FaceData.NCols>1) and (FaceData.NRows>=1))
                  or ((FaceData.NCols>=1) and (FaceData.NRows>1))
                  or ((FaceData.NCols=1) and (FaceData.NRows=1)
                  and (FaceData.Faces[0][0].NumberOfPoints=4)) then begin
                     CtrlFace:=FaceData.Faces[0][0];
                     if Layers.SortedIndexOf(Ctrlface.Layer)<>-1 then ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
                                                                 else Colorindex:=0;
                     Ship.Surface.ConvertToGrid(FaceData,Cols,Rows,Grid);
                     ProcessGrid(Cols,Rows,Grid,ColorIndex);
                  end else begin
                     CtrlFace:=FaceData.Faces[0][0];
                     if Layers.SortedIndexOf(Ctrlface.Layer)<>-1 then ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
                                                                 else Colorindex:=0;
                     if (CtrlFace.NumberOfpoints=3) and (SendTriangles) then begin
                        AssembleTriangle(Cols,Rows,Grid,CtrlFace);
                        if (Cols>0) and (Rows>0) then ProcessGrid(Cols,Rows,Grid,ColorIndex);
                     end else begin
                        Cols:=2;
                        Rows:=2;
                        Setlength(Grid,2);
                        Setlength(Grid[0],2);
                        Setlength(Grid[1],2);
                        for J:=1 to CtrlFace.ChildCount do begin
                           Face:=CtrlFace.Child[J-1];
                           Grid[0][1]:=Face.Point[0];
                           Grid[0][0]:=Face.Point[1];
                           Grid[1][0]:=Face.Point[2];
                           Grid[1][1]:=Face.Point[3];
                           ProcessGrid(Cols,Rows,Grid,ColorIndex);
                        end;
                     end;
                  end;
               end;
            end;
            CheckFaces.Destroy;
         end else begin
            for I:=1 to Ship.Surface.NumberOfControlFaces do
            begin
               CtrlFace:=Ship.Surface.ControlFace[I-1];
               if Layers.SortedIndexOf(Ctrlface.Layer)<>-1
                  then ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
                  else Colorindex:=0;
               if CtrlFace.NumberOfpoints=4 then begin
                  FaceData.NCols:=1;
                  FaceData.NRows:=1;
                  Setlength(FaceData.Faces,1);
                  Setlength(FaceData.Faces[0],1);
                  FaceData.Faces[0][0]:=Ctrlface;
                  Ship.Surface.ConvertToGrid(FaceData,Cols,Rows,Grid);
                  ProcessGrid(Cols,Rows,Grid,ColorIndex);
               end else begin
                  Cols:=2;
                  Rows:=2;
                  Setlength(Grid,2);
                  Setlength(Grid[0],2);
                  Setlength(Grid[1],2);
                  for J:=1 to CtrlFace.ChildCount do begin
                     Face:=CtrlFace.Child[J-1];
                     Grid[0][1]:=Face.Point[0];
                     Grid[0][0]:=Face.Point[1];
                     Grid[1][0]:=Face.Point[2];
                     Grid[1][1]:=Face.Point[3];
                     ProcessGrid(Cols,Rows,Grid,ColorIndex);
                  end;
               end;
            end;
         end;
         if NSurfaces>0 then begin
            IGESList.SaveToFile(ChangeFileExt(Dialog.Filename,'.igs'));
            MessageDlg('Exported '+IntToStr(NSurfaces)+' surfaces.',mtInformation,[mbOK],0);
         end else MessageDlg(Userstring(100),mtInformation,[mbOK],0);
         IGESList.Destroy;
         Layers.Destroy;
//    finally
         Ship.Surface.DesiredSubdivisionLevel:=PrevLevel;
         Ship.Surface.SubdivisionMode:=fmQuadTriangle;
         if not Ship.Surface.Build then Ship.Surface.Rebuild;
         Screen.Cursor:=Prev;
         Ship.Redraw;
//    end;
   end;
   Dialog.Destroy;
end;

{
  © Import the files are always UTF8
}
procedure TFreeEdit.File_ImportObj;
var
  OpenDialog: TOpenDialog; Answer: Word;
  PrevCursor: TCursor;
  Strings: TStringList;
begin
   OpenDialog:=TOpenDialog.Create( Ship );
   OpenDialog.InitialDir:=Ship.Preferences.ImportDirectory; //+ConfigDirectory
// OpenDialog.Filter:=createDialogFilter( 'OBJ file',['obj'] );
   OpenDialog.Filter:='WaveFront OBJ (*.obj)|*.obj';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=Ship.Edit.File_SaveCheck;
      if (Answer=mrCancel) or Ship.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      CreateUndoObject('OBJ file',True);
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      Ship.Clear;
//      assignFile(FFile,ChangeFileExt(Opendialog.FileName,'.xyz'));
//      {$I-}Reset(FFile);{$I+}
 //     if IOResult=0 then begin
  //       Ship.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
   //  Ship.Clear;

      Strings:=TStringList.Create;
      Strings.LoadFromFile( ChangeFileExt( OpenDialog.FileName,'.obj' ) );
      Ship.Surface.ImportObjFile( Strings );

//      Ship.ModelIsLoaded:=True;
      Ship.FileName:=ChangeFileExt( Opendialog.FileName,'' );
      Ship.RebuildModel;
      Ship.FileChanged:=True;
      Ship.Redraw;
      FreeAndNil(Strings);
      if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
      Screen.Cursor:=PrevCursor;
  end;
  FreeAndNil( OpenDialog );
end;

procedure TFreeEdit.File_ExportObj;
var SaveDialog : TSaveDialog;
    Strings    : TStringlist;
begin
   SaveDialog:=TSaveDialog.Create(Ship);
   SaveDialog.InitialDir:=Ship.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Ship.FileName),'.obj');
   SaveDialog.Filter:='Wavefront file (*.Obj)|*.Obj|Controlnet to wavefront file (*.obj)|*.obj';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      Ship.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      Strings:=TStringlist.Create;
      Ship.Surface.ExportObjFile(SaveDialog.FilterIndex=2,Strings);
      Strings.SaveToFile(ChangeFileExt(Savedialog.FileName,'.obj'));
      Strings.Destroy;
   end;
   SaveDialog.Destroy;
end;

// Exports all intersections to a textfile as 3D points
procedure TFreeEdit.File_ExportOffsets;
var SaveDialog : TSaveDialog;
    Strings    : TStringlist;
    I          : integer;
    procedure SendSpline(Spline:TFreespline);
    var J      : integer;
        Str    : string;
        P      : T3DVector;
    begin
      for J:=1 to Spline.NumberOfPoints do
      begin
         P:=Spline.Point[J-1];
         Str:='        '+MakeLength(P.X,4,10)+#32+MakeLength(P.Y,4,10)+#32+MakeLength(P.Z,4,10);
         if Spline.Knuckle[J-1] then Str:=Str+'    KNUCKLE';
         Strings.Add(Str);
      end;
    end;{SendSpline}

    procedure SendIntersection(Intersection:TFreeIntersection);
    var I      : integer;
        Str    : string;
        Spline : TFreeSpline;
    begin
       if not Intersection.Built then Intersection.Rebuild;
       if Intersection.Count>0 then
       begin
          Str:=Intersection.Description;
          Strings.Add(Str);
          if Intersection.Count>1 then Strings.Add(IntToStr(Intersection.Count)+' segments.');
          for I:=1 to Intersection.count do
          begin
             Spline:=Intersection.Items[I-1];
             if Intersection.Count>1 then Strings.Add('SEGMENT '+IntToStr(I));
             SendSpline(Spline);
          end;
       end;
    end;{SendIntersection}

begin
   SaveDialog:=TSaveDialog.Create(Ship);
   SaveDialog.InitialDir:=Ship.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Ship.FileName),'.txt');
   SaveDialog.Filter:='Offsets as 3D points (*.Txt)|*.txt';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then
   begin
      Ship.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      Strings:=TStringlist.Create;
      for I:=1 to Ship.NumberofStations do SendIntersection(Ship.Station[I-1]);
      for I:=1 to Ship.NumberofButtocks do SendIntersection(Ship.Buttock[I-1]);
      for I:=1 to Ship.NumberofWaterlines do SendIntersection(Ship.Waterline[I-1]);
      for I:=1 to Ship.NumberofDiagonals do SendIntersection(Ship.Diagonal[I-1]);
      for I:=1 to Ship.NumberOfControlCurves do
      begin
         Strings.Add('CONTROLCURVE');
         SendSpline(Ship.ControlCurve[I-1].Curve);
      end;
      Strings.SaveToFile(ChangeFileExt(Savedialog.FileName,'.txt'));
      Strings.Destroy;
   end;
   SaveDialog.Destroy;
end;{TFreeEdit.File_ExportOffsets}

// Export the surface to a STL file
//
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
var SaveDialog : TSaveDialog;
    FFile      : TextFile;
    I,J,K,L    : Integer;
    Layer      : TFreeSubdivisionLayer;
    Face       : TFreeSubdivisionControlface;
    Child      : TFreeSubdivisionface;

    procedure Addfacet(P1,P2,P3:TFreeSubdivisionPoint);
    var Normal:T3DVector;
    begin
       Normal:=UnifiedNormal(p1.Coordinate,P2.Coordinate,P3.Coordinate);
       Write(FFile,'  facet normal ');
       writeln(FFile,Truncate(normal.X,4)+#32+Truncate(normal.Y,4)+#32+Truncate(normal.Z,4));
       writeln(FFile,'    outer loop');
       writeln(FFile,'      vertex '+Truncate(P1.Coordinate.X,4)+#32+Truncate(P1.Coordinate.Y,4)+#32+Truncate(P1.Coordinate.Z,4));
       writeln(FFile,'      vertex '+Truncate(P2.Coordinate.X,4)+#32+Truncate(P2.Coordinate.Y,4)+#32+Truncate(P2.Coordinate.Z,4));
       writeln(FFile,'      vertex '+Truncate(P3.Coordinate.X,4)+#32+Truncate(P3.Coordinate.Y,4)+#32+Truncate(P3.Coordinate.Z,4));
       writeln(FFile,'    endloop');
       Writeln(FFile,'  endfacet');
    end;{Addfacet}
begin
   SaveDialog:=TSaveDialog.Create(Ship);
   SaveDialog.InitialDir:=Ship.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(Ship.FileName),'.stl');
   SaveDialog.Filter:='STL file (*.stl)|*.stl';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      Ship.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      AssignFile(FFile,Changefileext(SaveDialog.FileName,'.stl'));
      {$I-}Rewrite(FFile);{$I+}
      if IOResult=0 then begin // perform modelcheck to ensure normals point outward
         writeln(FFile,'solid');
         if not Ship.ProjectSettings.DisableModelCheck then Model_Check(False);
         for I:=1 to Ship.Surface.NumberOfLayers do begin
            Layer:=Ship.Surface.Layer[I-1];
            if Layer.Visible then for J:=1 to Layer.Count do begin
               Face:=Layer.Items[J-1];
               for K:=1 to Face.ChildCount do begin
                  Child:=face.Child[K-1];
                  For L:=3 to Child.NumberOfpoints do AddFacet(Child.Point[0],Child.Point[L-2],Child.Point[L-1]);
               end;
            end;
         end;
         writeln(FFile,'endsolid');
         Closefile(FFile);
      end else MessageDlg(Userstring(97),mtError,[mbOk],0);
   end;
   SaveDialog.Destroy;

end;{TFreeEdit.File_ExportSTL}

// imports a Carene XYZ file and creates a multichine boat with developable surfaces
procedure TFreeEdit.File_ImportCarene;
var OpenDialog : TOpenDialog;
    Answer     : Word;
    Str        : string;
    I,LineNr   : Integer;
    P          : T3DVector;
    FFile      : TextFile;
    Chines     : TFasterList;
    Spline     : TFreeSpline;
begin
   OpenDialog:=TOpenDialog.Create(Ship);
   OpenDialog.InitialDir:=Ship.Preferences.ImportDirectory;
   OpenDialog.Filter:='Carene XYZ files (*.xyz)|*.xyz';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=Ship.Edit.File_SaveCheck;
      if (Answer=mrCancel) or Ship.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      CreateUndoObject(Userstring(105),True);
      Ship.Clear;
      assignFile(FFile,ChangeFileExt(Opendialog.FileName,'.xyz'));
      {$I-}Reset(FFile);{$I+}
      if IOResult=0 then begin
         Ship.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
//       try
            LineNr:=1;
            Readln(FFile,Str);
            // first 18 characters are description
            Str:=Copy(Str,1,18);
            Str:=Trim(Str);
            Ship.ProjectSettings.FProjectName:=Str;
            Chines:=TFasterList.Create;
            while not EOF(FFile) do begin
               Readln(FFile,Str);
               inc(LineNr);
               if Pos('LINE',Str)=1 then begin // New chine skip one line
                  if not EOF(FFile) then begin
                     Readln(FFile);
                     inc(LineNr);
                  end;
                  if not EOF(FFile) then begin
                     Spline:=TFreeSpline.Create;
                     Chines.Add(Spline);
                     repeat
                        Readln(FFile,Str);
                        repeat
                           I:=Pos(#9,Str);
                           if I<>0 then Str[I]:=#32;
                        until I=0;
                        inc(LineNr);
                        if Str<>'' then begin
                           P.X:=ReadFloatFromStr(LineNr,Str);
                           P.Y:=ReadFloatFromStr(LineNr,Str);
                           P.Z:=ReadFloatFromStr(LineNr,Str);
                           Spline.Add(P);
                           Str:=#32;
                        end;
                     until (EOF(FFile)) or (Str='');
                  end;
               end;
            end;
            Ship.ImportChines(8,Chines);
            Chines.Destroy;
//       finally
            CloseFile(FFile);
            Ship.Filename:=ChangeFileExt(Opendialog.FileName,'.fbm');
//       end;
      end else
      begin
         MessageDlg(Userstring(106),mtError,[mbOk],0);
      end;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportCarene}

// Import chines from a textfile and fit a surface through them
procedure TFreeEdit.File_ImportChines;
var OpenDialog : TOpenDialog;
    Answer     : Word;
    Str        : string;
    I          : integer;
    LineNr     : Integer;
    P          : T3DVector;
    FFile      : TextFile;
    Chines     : TFasterList;
    Spline     : TFreeSpline;
begin
   OpenDialog:=TOpenDialog.Create(Ship);
   OpenDialog.InitialDir:=Ship.Preferences.ImportDirectory;
   OpenDialog.Filter:='Text files (*.txt)|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=Ship.Edit.File_SaveCheck;
      if (Answer=mrCancel) or Ship.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      CreateUndoObject(Userstring(107),True);
      Ship.Clear;
      assignFile(FFile,ChangeFileExt(Opendialog.FileName,'.txt'));
      {$I-}Reset(FFile);{$I+}
      if IOResult=0 then begin
         Ship.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         LineNr:=1;
         Chines:=TFasterList.Create;
//       try
//          try
               // first read unit information; 0=metric, 1=imperial
               readln(FFile,I);
               if I in [0,1] then Ship.ProjectSettings.ProjectUnits:=TFreeUnitType(I)
                             else MessageDlg(Userstring(108),mtError,[mbOk],0);
               Spline:=TFreeSpline.Create;
               repeat
                  Readln(FFile,Str);
                  repeat
                     i:=Pos(#9,Str);
                     if I<>0 then str[I]:=#32;
                  until I=0;
                  inc(LineNr);
                  Str:=Trim(Uppercase(Str));
                  if (Str<>'') and (Str<>'EOF') then
                  begin
                     P.X:=ReadFloatFromStr(LineNr,Str);
                     P.Y:=ReadFloatFromStr(LineNr,Str);
                     P.Z:=ReadFloatFromStr(LineNr,Str);
                     Spline.Add(P);
                     Str:=#32;
                  end else if Str='' then
                  begin
                     if Spline.NumberOfPoints>1 then Chines.Add(Spline)
                                                else Spline.Destroy;
                     Spline:=TFreeSpline.Create;
                  end;
               until (Str='EOF') or (EOF(FFile));
               if Spline.NumberOfPoints>1 then Chines.Add(Spline)
                                          else Spline.Destroy;
//          except
//             MessageDlg('Error on line '+IntToStr(LineNr)+' in file '+Opendialog.Filename,mtError,[mbOk],0);
//          end;
            Ship.ImportChines(8,Chines);
            Chines.Destroy;
//       finally
            CloseFile(FFile);
            Ship.Filename:=ChangeFileExt(Opendialog.FileName,'.fbm');
            if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
//       end;
      end else
      begin
         MessageDlg(Userstring(106),mtError,[mbOk],0);
      end;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportChines}

// Imports a file created with Carlssons's Hulls program
procedure TFreeEdit.File_ImportHull;
var OpenDialog : TOpenDialog;
    Answer     : Word;
begin
   OpenDialog:=TOpenDialog.Create(Ship);
   OpenDialog.InitialDir:=Ship.Preferences.ImportDirectory;
   OpenDialog.Filter:='Carlsson Hull files (*.hul)|*.hul';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=Ship.Edit.File_SaveCheck;
      if (Answer=mrCancel) or Ship.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      CreateUndoObject(UserString(110),True);
      File_ImportHull(OpenDialog.FileName,False);
      Ship.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportHull}

procedure TFreeEdit.File_ImportHull(Filename:string;Quiet:Boolean);
var I,J        : integer;
    NBulkHeads : integer;
    P,Min,Max  : T3DVector;
    FFile      : TextFile;
    NoChines   : integer;
    Value      : TFloatType;
    Points     : array of array of T3DVector;
    Chines     : TFasterList;
    Spline     : TFreeSpline;
    Str        : string;
    Skip       : Boolean;
begin
   Ship.Clear;
   assignFile(FFile,ChangeFileExt(FileName,'.hul'));
   {$I-}Reset(FFile);{$I+}
   if IOResult=0 then begin
//    try
         Readln(FFile,NoChines);
         NBulkHeads:=5;
         Setlength(Points,NBulkHeads);
         for I:=1 to NBulkHeads do begin
            Setlength(Points[I-1],NoChines);
            for J:=1 to NoChines do begin
               Readln(FFile,P.Y);
               Readln(FFile,P.Z);
               Readln(FFile,P.X);                // scale from inches to meters
               P.X:=P.X*0.0254;
               P.Y:=P.Y*0.0254;
               P.Z:=P.Z*0.0254;
               if (I=1) and (J=1) then begin
                  Min:=P;
                  Max:=Min;
               end else MinMax(P,Min,Max);
               Points[I-1][J-1]:=P;
            end;
         end;
         Readln(FFile);
         if Quiet then Skip:=True else Skip:=MessageDlg(Userstring(111),mtConfirmation,[mbYes,mbNo],0)=mrNo;
         if not skip then begin
            NBulkHeads:=13;
            Setlength(Points,NBulkHeads);
            for I:=1 to NBulkHeads do begin
               Setlength(Points[I-1],NoChines);
               for J:=1 to NoChines do begin
                  Readln(FFile,P.Y);
                  Readln(FFile,P.Z);
                  Readln(FFile,P.X);             // scale from inches to meters
                  P.X:=P.X*0.0254;
                  P.Y:=P.Y*0.0254;
                  P.Z:=P.Z*0.0254;
                  if (I=1) and (J=1) then begin
                     Min:=P;
                     Max:=Min;
                  end else MinMax(P,Min,Max);
                  Points[I-1][J-1]:=P;
               end;
            end;
         end else begin
            for I:=1 to 13 do for J:=1 to NoChines do begin
               Readln(FFile);
               Readln(FFile);
               Readln(FFile);
            end;
         end;

         Chines:=TFasterlist.Create;
         for I:=1 to NoChines do
         begin
            for J:=1 to NBulkheads do
            begin
               P:=Points[J-1,I-1];
               P.X:=-P.X+Max.X;
               Points[J-1,I-1]:=P;
            end;
            Spline:=TFreeSpline.Create;
            Chines.Add(Spline);
            for J:=1 to NBulkheads do
            begin
               P:=Points[J-1,I-1];
               Spline.Add(P);
               Spline.Knuckle[J-1]:=False;
            end;
         end;
         Ship.ImportChines(NBulkheads,Chines);
         Chines.Destroy;
         // read stations
         for I:=1 to 8 do begin
            Readln(FFile,Value);
            Intersection_Add(fiStation,-Value*0.024+Max.X);
         end;

         // Skip rig info
         for I:=1 to 9 do Readln(FFile);

         // Read designer info
         Readln(FFile,Str);
         Ship.ProjectSettings.FProjectDesigner:=Str;
         Readln(FFile,Str);
         Ship.ProjectSettings.FProjectName:=Str;
//    finally
         CloseFile(FFile);
         Ship.ProjectSettings.ProjectWaterDensity:=1.0;
         Ship.ProjectSettings.ProjectUnits:=fuImperial;
         Ship.ProjectSettings.ProjectDraft:=1.0;
         Ship.FileName:=ChangeFileExt(FileName,'');
         Ship.Draw;
//    end;
   end else
   begin
      MessageDlg(Userstring(106),mtError,[mbOk],0);
   end;
end;

// Import a partfile and add it to the current geometry
procedure TFreeEdit.File_ImportPart;
var OpenDialog    : TOpenDialog;
    PartFile      : TFreeFileBuffer;
    Undo          : TFreeUndoObject;
    PartUnits     : TFreeUnitType;
    Changed       : Boolean;
    Crease        : Boolean;
    I,J,N,Np      : Integer;
    Ind1,Ind2     : Integer;
    LayerID       : Integer;
    PartVersion   : TFreeFileversion;
    Str           : string;
    Scale         : TFloatType;
    Points        : TFasterList;
    Edges         : TFasterList;
    Layers        : TFasterList;
    FacePoints    : TFasterList;
    Edge          : TFreeSubdivisionControlEdge;
    P1,P2         : TFreeSubdivisionControlPoint;
    Curve         : TFreeSubdivisionControlCurve;
    Layer         : TFreeSubdivisionLayer;
    PrevCursor    : TCursor;
begin
   OpenDialog:=TOpenDialog.Create(Ship);
   OpenDialog.InitialDir:=Ship.Preferences.ImportDirectory;
   OpenDialog.Filter:='FREE!ship geometry part (*.Part)|*.part';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      PartFile:=TFreeFileBuffer.Create;
      Ship.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      Changed:=False;
      Undo:=CreateUndoObject(Userstring(112),false);
      Partfile.LoadFromFile(ChangeFileExt(OpenDialog.FileName,'.part'));
      Partfile.LoadString(Str);
      if Str='FREE!ship partfile' then begin                // Load fileversion
         Partfile.LoadInteger(I);
         if I<=Ord(CurrentVersion) then begin
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourglass;
//          try
               Partversion:=TFreeFileVersion(I);
               Partfile.Version:=PartVersion;
               Points:=TFasterList.Create;
               Edges:=TFasterList.Create;
               Layers:=TFasterList.Create;
               // Load units
               Partfile.LoadInteger(I);
               PartUnits:=TFreeUnitType(I);
               if PartUnits<>Ship.ProjectSettings.ProjectUnits then
               begin
                  if PartUnits=fuMetric then Scale:=1/Foot  // Part units=metric and projectunits=imperial, scale from meters to feet
                                        else scale:=Foot;   // Part units=imperial and projectunits=metric, scale from feet to meters
               end else Scale:=1.0;
               // Load number of layers
               Partfile.LoadInteger(N);
               Layers.Capacity:=N;
               for I:=1 to N do
               begin
                  Layer:=Ship.Surface.AddNewLayer;
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
                  P2:=TFreeSubdivisionControlPoint.Create(Ship.Surface);
                  Ship.Surface.AddControlPoint(P2);
                  P2.LoadBinary(PartFile);
                  P2.Coordinate:=ScalePoint(Scale,P2.Coordinate);
                  Points.Add(P2);
                  Changed:=True;
               end;
               // Load control edges
               Partfile.LoadInteger(N);
               Edges.Capacity:=N;
               for I:=1 to N do begin
                  Partfile.LoadInteger(Ind1);
                  Partfile.LoadInteger(Ind2);
                  if (Ind1<>-1) and (Ind2<>-1) then begin
                     P1:=Points[ind1];
                     P2:=Points[ind2];
                     Edge:=Ship.Surface.AddControlEdge(P1,P2);
                  end else Edge:=nil;
                  Partfile.LoadBoolean(Crease);
                  if Edge<>nil then Edge.Crease:=Crease;
                  Changed:=True;
               end;
               // Load controlfaces
               Partfile.LoadInteger(N);
               FacePoints:=TFasterList.Create;
               for I:=1 to N do begin
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
                  Ship.Surface.AddControlFace(FacePoints,False,Layer);
               end;
               for I:=1 to Edges.Count do
               begin
                  Edge:=Edges[I-1];
                  if (Edge.NumberOfFaces<>2) and (not Edge.Crease) then
                     Edge.Crease:=true;
               end;
               // Load controlcurves
               Partfile.LoadInteger(N);
               for I:=1 to N do
               begin
                  Partfile.LoadInteger(Np);
                  if Np>1 then
                  begin
                     Curve:=TFreeSubdivisionControlCurve.Create(Ship.Surface);
                     Ship.Surface.AddControlCurve(Curve);
                     for J:=1 to Np do
                     begin
                        Partfile.LoadInteger(Ind1);
                        P2:=Points[ind1];
                        Curve.AddPoint(P2);
                        if J>1 then
                        begin
                           P1:=Curve.ControlPoint[J-2];
                           Edge:=Ship.Surface.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
                           if Edge<>nil then edge.Curve:=Curve;
                        end;
                     end;
                  end;
               end;
               FacePoints.Destroy;
               Points.Destroy;
               Edges.Destroy;
               Layers.Destroy;
//          finally
               Screen.Cursor:=Prevcursor;
//          end;
            if Changed then begin
               if Assigned(Ship.Surface.OnChangeLayerData) then Ship.Surface.OnChangeLayerData(Ship.Surface);
               Undo.Accept;
               Ship.Build:=False;
               Ship.Draw;
               Ship.FileChanged:=True;
               if assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(Ship);
            end;
         end else MessageDlg(UserString(113),mtError,[mbOk],0);
      end else MessageDlg(Userstring(114),mtError,[mbOk],0);
      if not Changed then Undo.Delete;
      Partfile.Destroy;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportPart}

// Imports a PolyCad file
procedure TFreeEdit.File_ImportPolycad;
var OpenDialog : TOpenDialog;
    Answer     : Word;
    PrevCursor : TCursor;
    Strings    : TStringList;
    I,J,K,N    : Integer;
    Cols,Rows  : Integer;
    Index      : Integer;
    NSurfaces  : Integer;
    Indices    : array of Integer;
    Str,Tmp    : String;
    Abort      : Boolean;
    Points     : TFreeCoordinateGrid;
    Value      : TFloatType;
    P          : T3DVector;

    function NextLine:string;
    begin
       if Index+1<Strings.Count then
       begin
          inc(Index);
          Result:=Strings[index];
       end else
       begin
          Result:='';
          Abort:=True;
          MessageDlg(UserString(115),mtError,[mbOk],0);
       end;
    end;{NextLine}

    Function GetInteger(str:string):Integer;
    var Index:Integer;
    begin
      Index:=Pos('=',Str);
      Result:=0;
      if Index<>0 then
      begin
         Str:=Copy(Str,Index+1,Length(Str)-Index);
         Val(Str,Result,Index);
         if Index<>0 then
         begin
            MessageDlg(Userstring(116)+#32+IntToStr(I),mtError,[mbOk],0);
            Abort:=True;
         end;
      end else Abort:=True;
    end;{GetInteger}

    Function GetFloat(str:string):TFloatType;
    var Index:Integer;
    begin
      Index:=Pos('=',Str);
      Result:=0;
      if Index<>0 then
      begin
         Str:=Copy(Str,Index+1,Length(Str)-Index);
         Val(Str,Result,Index);
         if Index<>0 then
         begin
            MessageDlg(Userstring(117)+#32+IntToStr(I),mtError,[mbOk],0);
            Abort:=True;
         end;
      end else Abort:=True;
    end;{GetFloat}

    function NextParameter(var input:string):string;
    var Index:Integer;
    begin
       Index:=pos(#32,Input);
       if Index<>0 then
       begin
          Result:=Copy(Input,1,Index-1);
          Delete(Input,1,Index);
          Input:=Trim(Input);
       end else
       begin
          Result:='';
          Abort:=True;
       end;
    end;{NextParameter}

begin
   OpenDialog:=TOpenDialog.Create(Ship);
   OpenDialog.InitialDir:=Ship.Preferences.ImportDirectory;
   OpenDialog.Filter:='PolyCad files (*.geo)|*.geo';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=Ship.Edit.File_SaveCheck;
      if (Answer=mrCancel) or Ship.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      Strings:=TStringList.Create;
//    try
         Strings.LoadFromFile(OpenDialog.FileName);
         // delete empty strings
         for I:=Strings.Count downto 1 do if Strings[I-1]='' then Strings.Delete(I-1);
         // count number of BSpline surfaces
         NSurfaces:=0;
         for I:=1 to strings.Count do
          if (pos('[TBSplineSurface]',Strings[I-1])<>0) or
             (pos('[TShipLines]',Strings[I-1])<>0) or
             (pos('[TYachtLines]',Strings[I-1])<>0) then begin
            Setlength(Indices,NSurfaces+1);
            Indices[NSurfaces]:=I-1;
            inc(NSurfaces);
         end;
         if NSurfaces>0 then begin
            CreateUndoObject(Userstring(118),True);
            Ship.Clear;
            Ship.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
            I:=1;
            Abort:=False;
            while (I<=NSurfaces) and (not Abort) do begin
               Index:=Indices[I-1];
               Str:=Strings[index];
               if (pos('[TYachtLines]',Strings[I-1])<>0) then begin // Read loa
                  Str:=NextLine;
                  Ship.ProjectSettings.ProjectLength:=GetFloat(Str);
                  NextLine;
                  NextLine;
                  // read beam over all
                  Str:=NextLine;
                  Ship.ProjectSettings.ProjectBeam:=GetFloat(Str);
                  NextLine;
                  NextLine;
                  // Read draft
                  Str:=NextLine;
                  Ship.ProjectSettings.ProjectDraft:=GetFloat(Str);
//                Ship.ProjectSettings.FMainparticularsHasBeenset:=True;
                  for J:=1 to 12 do NextLine;
               end else if (pos('[TShipLines]',Strings[I-1])<>0) then begin
                  NextLine;
                  // Read length
                  Str:=NextLine;
                  Ship.ProjectSettings.ProjectLength:=GetFloat(Str);
                  // read beam
                  Str:=NextLine;
                  Ship.ProjectSettings.ProjectBeam:=GetFloat(Str);
                  // skip depth
                  NextLine;
                  // Read draft
                  Str:=NextLine;
                  Ship.ProjectSettings.ProjectDraft:=GetFloat(Str);
//                Ship.ProjectSettings.FMainparticularsHasBeenset:=True;
                  for J:=1 to 22 do NextLine;
               end;

               NextLine;            // skip OrderU=
               NextLine;            // skip OrderV=

               // Read number of columns
               Str:=NextLine;
               Cols:=GetInteger(Str);                    // Read number of rows
               Str:=NextLine;
               Rows:=GetInteger(Str);
               if (Cols>1) and (Rows>1) then begin         // Initialize points
                  Setlength(Points,Rows);
                  for J:=1 to Rows do begin
                     Setlength(Points[J-1],Cols);
                     for K:=1 to Cols do Points[J-1][K-1]:=ZERO;
                  end;
                  for J:=1 to Cols do begin
                     for K:=1 to Rows do begin
                        Str:=NextLine;
                        if not abort then begin
                           Str:=Trim(Str);
                           P:=Zero;                             // X coordinate
                           Tmp:=NextParameter(Str);
                           if not abort then begin
                              Val(Tmp,P.X,N);
                              if N<>0 then begin
                                 MessageDlg(Userstring(119)+#32+IntToStr(I),mtError,[mbOk],0);
                                 Abort:=True;
                              end;
                           end;
                           if not Abort then begin
                              Tmp:=NextParameter(Str);
                              if not abort then begin
                                 Val(Tmp,P.Y,N);
                                 if N<>0 then begin
                                    MessageDlg(Userstring(120)+#32+IntToStr(I),mtError,[mbOk],0);
                                    Abort:=True;
                                 end;
                              end;
                           end;
                           if not Abort then begin              // Z coordinate
                              Tmp:=NextParameter(Str);
                              if not abort then begin
                                 Val(Tmp,P.Z,N);
                                 if N<>0 then begin
                                    MessageDlg(Userstring(121)+#32+IntToStr(I),mtError,[mbOk],0);
                                    Abort:=True;
                                 end;
                              end;
                           end;
                           Points[K-1][J-1]:=P;
                        end else break;
                     end;
                     if abort then break;
                  end;
                  if not Abort then Ship.Surface.ImportGrid(Points,Cols,Rows,nil);
               end;
               Inc(i);
            end;
            if not Abort then begin                           // Read contours;
               for I:=1 to Strings.Count do begin
                  if Pos('[TContours]',Strings[I-1])<>0 then begin
                     Index:=I-1;
                     Str:=NextLine;
                     N:=GetInteger(Str);
                     if not abort then begin
                        for J:=1 to N do begin
                           Str:=NextLine;
                           if not abort then begin
                              Str:=Trim(Str);
                              Tmp:=NextParameter(Str);
                              if not abort then begin  // 1=station, 2=buttock, 3=waterline
                                 K:=StrToInt(Tmp);
                              end else K:=0;
                              if not abort then begin
                                 Val(Str,Value,N);
                                 if N<>0 then begin
                                    MessageDlg(Userstring(122),mtError,[mbOk],0);
                                    Abort:=True;
                                 end else begin
                                    Case K of
                                       1 : self.Intersection_Add(fiStation,Value);
                                       2 : if Value>=0 then self.Intersection_Add(fiButtock,Value);
                                       3 : self.Intersection_Add(fiWaterline,Value);
                                    end;
                                 end;
                              end;
                           end;
                           if abort then break;
                        end;
                     end;
                     break;
                  end;
               end;
               Ship.Precision:=fpMedium;
               Ship.FileName:=ChangeFileExt(Opendialog.FileName,'');
               Ship.Build:=False;
               Ship.RebuildModel;
               Ship.FileChanged:=true;
            end else MessageDlg(UserString(123),mtInformation,[mbOK],0);
         end else MessageDlg(UserString(124),mtInformation,[mbOk],0);
//    finally
         Strings.Destroy;
         if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
         Screen.Cursor:=PrevCursor;
//    end;
   end;
   OpenDialog.Destroy;
end;{TFreeEdit.File_ImportPolycad}

// Load a VRML file
Procedure TFreeEdit.File_ImportVRML;
var OpenDialog : TOpenDialog;
    Answer     : Word;
    PrevCursor : TCursor;
begin
   OpenDialog:=TOpenDialog.Create(Ship);
   OpenDialog.InitialDir:=Ship.Preferences.ImportDirectory;
   OpenDialog.Filter:='VRML files (*.wrl)|*.wrl';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=Ship.Edit.File_SaveCheck;
      if (Answer=mrCancel) or Ship.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
//    try
         CreateUndoObject(Userstring(125),True);
         Ship.Clear;
         Ship.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         Ship.Surface.LoadVRMLFile(Opendialog.FileName);
         Ship.FileName:=ChangeFileExt(Opendialog.FileName,'');
         Ship.Build:=False;
         Ship.RebuildModel;
         Ship.FileChanged:=true;
//    finally
         if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
         Screen.Cursor:=PrevCursor;
//    end;
   end;
   OpenDialog.Destroy;
end;

procedure TFreeShip.SavePart(Faces:TFasterList);
var SaveDialog : TSaveDialog;
    I,J,Index  : Integer;
    Layers,Edges,Points,Curves: TFasterList;
    Face       : TFreeSubdivisionControlface;
    Edge       : TFreeSubdivisionControlEdge;
    P1,P2      : TFreeSubdivisionControlPoint;
    Curve      : TFreeSubdivisionControlCurve;
    Layer      : TFreeSubdivisionLayer;
    PartFile   : TFreeFileBuffer;
    PrevCursor : TCursor;
    Surface    : TFreeSubdivisionSurface;
    AddCurve   : Boolean;
begin
   Surface:=nil;
   if Faces.Count>0 then begin
      Face:=Faces[0];
      Surface:=Face.Owner;
   end;
   if Surface=nil then exit;

   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FileName),'.part');
   SaveDialog.Filter:='FREE!ship geometry part (*.Part)|*.part';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      // Extract controlPoints and control edges
      Layers:=TFasterList.Create;
      Points:=TFasterList.Create;
      Edges:=TFasterList.Create;
      Curves:=TFasterList.Create;
      for I:=1 to Faces.Count do begin
         Face:=Faces[I-1];
         if Layers.SortedIndexOf(Face.Layer)=-1 then Layers.AddSorted(Face.Layer);
         P1:=Face.Point[Face.NumberOfPoints-1] as TFreeSubdivisionControlPoint;
         for J:=1 to face.NumberOfpoints do begin
           P2:=Face.Point[J-1] as TFreeSubdivisionControlPoint;
           if Points.SortedIndexOf(P2)=-1 then Points.AddSorted(P2);
           Edge:=P1.Owner.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
           if Edge<>nil then if Edges.SortedIndexOf(Edge)=-1 then Edges.AddSorted(Edge);
           P1:=P2;
         end;
      end;

      // process control curves
      for I:=1 to Surface.NumberOfControlCurves do begin
         Curve:=Surface.ControlCurve[I-1];
         // In order to export this curve, all associated controledges must be in the edges list
         AddCurve:=True and (Curve.NumberOfControlPoints>1);
         for J:=2 to Curve.NumberOfControlPoints do begin
            P1:=Curve.ControlPoint[J-2];
            P2:=Curve.ControlPoint[J-1];
            Edge:=Surface.EdgeExists(P1,P2) as TFreeSubdivisionControlEdge;
            if Edge<>nil then begin
               if Edges.SortedIndexOf(Edge)=-1 then AddCurve:=False;
            end else AddCurve:=False;
         end;
         if AddCurve then Curves.Add(Curve);
      end;

      Curves.Sort;
      Layers.Sort;

      PartFile:=TFreeFileBuffer.Create;
      PartFile.Version:=CurrentVersion;

      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourGlass;
//    try
         Partfile.Add('FREE!ship partfile');
         Partfile.Add(ord(CurrentVersion));                                      // File version
         I:=Ord(ProjectSettings.ProjectUnits);
         Partfile.Add(I);                                                        // Write units type used (imperial or metric);
         Partfile.Add(Layers.Count);                                             // Number of layers in the file
         for I:=1 to Layers.Count do begin                                       // Save layer info
            Layer:=Layers[I-1];
            Layer.SaveBinary(Partfile);
         end;
         // Save controlpoints
         Partfile.Add(Points.Count);
         for I:=1 to Points.Count do begin
            P2:=Points[I-1];
            P2.SaveBinary(PartFile);
         end;
         // Save control edges
         Partfile.Add(Edges.Count);
         for I:=1 to Edges.Count do begin
            Edge:=Edges[I-1];
            Index:=Points.SortedIndexOf(Edge.StartPoint);
            Partfile.Add(Index);
            Index:=Points.SortedIndexOf(Edge.EndPoint);
            Partfile.Add(Index);
            Partfile.Add(Edge.Crease);
         end;
         // save controlfaces
         Partfile.Add(Faces.Count);
         for I:=1 to Faces.Count do begin
            Face:=Faces[I-1];
            Partfile.Add(Face.NumberOfpoints);
            for J:=1 to Face.NumberOfPoints do begin
               Index:=Points.SortedIndexOf(Face.Point[J-1]);
               Partfile.Add(Index);
            end;
            Index:=Layers.SortedIndexOf(Face.Layer);
            Partfile.Add(Index);
         end;
         // Save controlcurves
         Partfile.Add(Curves.Count);
         for I:=1 to Curves.Count do begin
            Curve:=Curves[I-1];
            Partfile.Add(Curve.NumberOfControlPoints);
            for J:=1 to Curve.NumberOfControlPoints do begin
               P2:=Curve.ControlPoint[j-1];
               Index:=points.SortedIndexOf(P2);
               Partfile.Add(Index);
            end;
         end;
         Partfile.SaveToFile(ChangeFileExt(SaveDialog.FileName,'.part'));
//    finally
         Screen.Cursor:=PrevCursor;
//    end;
      Partfile.Destroy;
      Points.Destroy;
      Edges.Destroy;
      Curves.Destroy;
      Layers.Destroy;
   end;
   SaveDialog.Destroy;
end;
