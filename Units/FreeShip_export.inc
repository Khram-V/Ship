{ 
  1 = © Aurora.Vsl-штормовой вычислительный эксперимент
  2 = WaveFront.Obj
  3-Standard triangle.Stl
}
//
// Export for Aurora-Hull computational experiments
//
procedure TFreeEdit.File_Export_Aurora_Experiments;
var
  Str: AnsiString;
  Strings: TStringList;

  Procedure Str2( A,B: single );
    begin Str:=Str+format( ' %1.5g %1.5g',[F2S(A),F2S(B)] );
    end;
  Procedure StemStern( Dir:boolean );                 // Dir=true-форштевень
    var I,J,K,M,N: Integer; z1:single;
  begin Str:='';
    for I:=0 to FreeShip.NumberofButtocks-1 do        // поиск нулевого батокса
    with FreeShip.Buttock[I] do begin
      if not Built then Rebuild;
      if Count>0 then                     // батокс для диаметрильной плоскости
      if abs( Items[0].Point[0].Y )<1e-4 then begin M:=0; z1:=Items[0].Point[0].Z;
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
    //
    //                            ...и всё-таки батокс следует записать особо
    if Dir and (FreeShip.NumberofButtocks>0) then begin
      Strings.Add( EOL+'Buttocs['+IntToStr( FreeShip.NumberofButtocks )+'] of Centerline' );
      for I:=0 to FreeShip.NumberofButtocks-1 do      // поиск нулевого батокса
      with FreeShip.Buttock[I] do begin Str:='';
      if not Built then Rebuild;
        if Count>0 then                   // батокс для диаметрильной плоскости
        for J:=0 to Count-1 do begin
          if abs( Items[J].Point[0].Y )<1e-4 then begin
            N:=Items[J].NumberOfPoints;
            Str:=' '+InttoStr( N );
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
    then for J:=0 to N do with Spline.Point[J] do Str:=Str+format( ' %1.5g %1.5g %1.5g ',[F2S(X),F2S(Y),F2S(Z)] )
    else for J:=N downto 0 do with Spline.Point[J] do Str:=Str+format( ' %1.5g %1.5g %1.5g ',[F2S(X),F2S(Y),F2S(Z)] );
    Strings.Add( Str );
  end;

var I,J,K,N: integer;
    Title,S: AnsiString; P0,PN: T3DVector; Dis: boolean=true;
    Dialog: TSaveDialog;
//    T3: T3DVector=(X:0;Y:0;Z:0);
    EdgePointLists: TFasterListTFasterListTFreeSubdivisionPoint;
    Points: TFasterListTFreeSubdivisionPoint;
    Point: TFreeSubdivisionPoint;

begin
  Title:=ExtractFilename( FreeShip.FileName );
  Dialog:=TSaveDialog.Create( FreeShip );
  Dialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  Dialog.FileName:=ChangeFileExt( Title,'.vsl');
  Dialog.Filter:=createDialogFilter( 'Aurora+Hull Vessel(db)file',['vsl'] );
  dialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if Dialog.Execute then begin WestPoint;
    FreeShip.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
    Strings:=TStringList.Create;
    with FreeShip.FProjectSettings do
    Strings.Add( '; FREE!Ship'+EOL+';'
         +EOL +'; File Name: '+Title
         +EOL +'; Name     : '+ProjectName
         +EOL +'; Designer : '+ProjectDesigner
         +EOL +'; Create by: '+ProjectFileCreatedBy
         +EOL +'; Comment  : '+ProjectComment
         +EOL +';'
         +EOL+#30+' < '+ExtractFilename( Dialog.FileName )+' > '      ///+++!!! уточнить где мидель
         +EOL+InttoStr( FreeShip.NumberofStations )
         +' '+InttoStr( FreeShip.NumberofStations div 2 )
         +EOL+FloatToStrF( FProjectLength,ffGeneral,6,1)
         +' '+FloatToStrF( FProjectBeam,ffGeneral,6,1)
         +' '+FloatToStrF( FProjectDraft,ffGeneral,6,1)+EOL );
//  T3.Z:=FreeShip.FProjectSettings.FProjectDraft;
    StemStern( false );                    // первые две строки для ахтерштевня
    Strings.Add( ' 0'+EOL );
    for I:=0 to FreeShip.NumberofStations-1 do
    with FreeShip.Station[I] do begin
      if not Built then Rebuild; N:=0;                   //  T3.Z:=0;
      for J:=0 to Count-1 do with Items[J] do begin
        N+=NumberOfPoints; //for K:=0 to NumberOfPoints-1 do T3.Z+=Point[K].Z;
        if J=0 then P0:=Point[0]; // else
        if J=Count-1 then PN:=Point[NumberOfPoints-1];
      end;                                                   // Z-положительно
        Dis:=(P0.Z<PN.Z) or (P0.Y<1e-6) or (P0.Y<=PN.Y);
//      Dis:=P0.Y<=PN.Y;
//      T3.Z:=0.98*T3.Z/N;
//      T3.Y:=-FreeShip.FProjectSettings.FProjectBeam;
//      T3.X:=Items[0].Point[0].X;
      Title:=format( '%3d %-4.4g',[N,F2S(Items[0].Point[0].X)] ); S:='';
      for J:=0 to Count-1 do with Items[J] do begin
        N:=NumberOfPoints-1; Str:='';   // ещё и сортировки только и не хватало
        if ( Point[N].Z>=Point[0].Z )                // == может быть на палубе
//      or ( Point[N].X>Point[0].X )
//      or ( ( (Point[0]-T3) * (Point[N]-T3) ).X>=0.0 )
//      or ( Point[0].Y=0.0 )
//      if Dis
        then begin for K:=0 to N do with Point[K] do Str2( Z,Y ); end
        else begin for K:=N downto 0 do with Point[K] do Str2( Z,Y ); end;

        if J=0 then S:=Str else begin if Dis then S:=S+Str else S:=Str+S; end;
      end;
      Strings.Add( Title+S );//+' ['+InttoStr(Count)+'] = '+floattostr(P0.y)+' < '+floattostr(PN.y) );
    end;
    Strings.Add( EOL+' 0' );                         // форштевень в завершение
    StemStern( true );  // и в заключение еще и все контрольные точки и контуры
                        //
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
//
//  WaveFront.obj
//
procedure TFreeEdit.File_ExportObj;
var
  SaveDialog: TSaveDialog;
  Strings: TStringList;
begin
  SaveDialog:=TSaveDialog.Create(FreeShip);
  SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '.obj');
  SaveDialog.Filter:=createDialogFilter( 'Wavefront export subdivided surface',['obj'],false )
               +'|'+ createDialogFilter( 'Wavefront export the controlnet only',['obj'],false );
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  SaveDialog.FilterIndex:=1;
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
  C1, C2, C3: T3DVector;
  Layer: TFreeSubdivisionLayer;
  Face: TFreeSubdivisionControlface;
  Child: TFreeSubdivisionface;

  procedure Addfacet( C1,C2,C3: T3DVector );
  var
    Normal: T3DVector;
  begin
    Normal:=UnifiedNormal( C1,C2,C3 );
//  Write(FFile,   'facet normal ');
    writeln(FFile, 'facet normal '+FloatToDec(normal.X, 4)
                            +#32+FloatToDec(normal.Y, 4)
                            +#32+FloatToDec(normal.Z, 4));
    writeln(FFile, '  outer loop');
    writeln(FFile, '    vertex '+FloatToDec(C1.X, 4)
                          +#32+FloatToDec(C1.Y, 4)
                          +#32+FloatToDec(C1.Z, 4) );
    writeln(FFile, '    vertex '+FloatToDec(C2.X, 4)
                          +#32+FloatToDec(C2.Y, 4)
                          +#32+FloatToDec(C2.Z, 4) );
    writeln(FFile, '    vertex '+FloatToDec(C3.X, 4)
                          +#32+FloatToDec(C3.Y, 4)
                          +#32+FloatToDec(C3.Z, 4) );
    writeln(FFile, '  endloop');
    Writeln(FFile, 'endfacet');
  end; {Addfacet}
begin
  SaveDialog:=TSaveDialog.Create(FreeShip);
  SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName),'.stl');
  SaveDialog.Filter:=createDialogFilter( rsSTLFile,['stl','txt'] );
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if SaveDialog.Execute then begin WestPoint;
    FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
    AssignFile( FFile,Changefileext( SaveDialog.FileName,'.stl' ) );
    Rewrite( FFile );
    if IOResult=0 then begin // perform modelcheck to ensure normals point outward
      WriteLn( FFile,'solid ['+Changefileext( ExtractFileName( SaveDialog.FileName ),'' )+']' );
      if not FreeShip.ProjectSettings.DisableModelCheck then Model_Check(False);
      for I:=1 to FreeShip.Surface.NumberOfLayers do begin
        Layer:=FreeShip.Surface.Layer[I-1];
        if Layer.SurfaceVisible then
          for J:=1 to Layer.Count do begin
            Face:=Layer.Items[J-1];
            for K:=1 to Face.ChildCount do begin
              Child:=face.Child[K-1];
              for L:=3 to Child.NumberOfpoints do begin
                C1:=Child.Point[0].Coordinate;
                C2:=Child.Point[L-2].Coordinate;
                C3:=Child.Point[L-1].Coordinate;
                AddFacet( C1,C2,C3 );       // mirror points, starboard to port
                C1.Y:=-C1.Y;
                C2.Y:=-C2.Y;
                C3.Y:=-C3.Y;
                AddFacet( C3,C2,C1 );
              end;
            end;
          end;
      end;
      writeln(FFile, 'endsolid');
      Closefile(FFile);
    end else MessageDlg( Userstring(97),mtError,[mbOK],0 );
  end;
  FreeAndNil(SaveDialog);
end;
//
//  DXF AutoCAD ++
//
procedure TFreeIntersection.SaveToDXF(Strings: TStringList);
var
  I: integer;
  Layer: AnsiString;
  Spline: TFreeSpline;
begin
  if not Built then Rebuild;
  for I:=1 to Count do begin
    Spline:=Items[I-1];
    case IntersectionType of
      fiStation: layer :='Stations ';
      fiButtock: layer :='Buttocks ';
      fiWaterline:layer:='Waterlines ';
      fiDiagonal: layer:='Diagonals ';
      else        Layer:='Layer_0';
    end;
    case FreeShip.Precision of
      fpLow     : Spline.Fragments:=50;
      fpMedium  : Spline.Fragments:=100;
      fpHigh    : Spline.Fragments:=150;
      fpVeryHigh: Spline.Fragments:=500; else Spline.Fragments:=100;
    end;
    Spline.SaveToDXF( Strings,Layer,FreeShip.Visibility.ModelView=mvBoth );
  end;
end;

procedure TFreeSpline.SaveToDXF
( Strings: TStringList;
  Layername: AnsiString;
  SendMirror: boolean );
var I,J,Ind,NParams: integer; P: T3DVector; Params: TFloatArray;
begin
  Ind:=FindDXFColorIndex( Color );
  NParams:=0;
  Setlength( Params,NumberOfPoints );          // count number of knucklepoints
  if not Built then Rebuild;
  for I:=2 to NumberOfPoints-1 do
   if Knuckle[I-1] then begin Params[NParams]:=Parameter[I-1]; Inc(NParams); end;
  Setlength(Params, NParams+Fragments);
  for I:=1 to Fragments do begin Params[NParams]:=(I-1)/(Fragments-1); Inc(NParams); end;
  ArraySort( Params,NParams );
//SortFloatArray(Params,NParams);
  Strings.Add('0'+EOL+'POLYLINE');
  Strings.Add('8'+EOL+LayerName);          // layername
  Strings.Add('62'+EOL+IntToStr(Ind));     // color by layer
  Strings.Add('70'+EOL+'10');              // not closed
  Strings.Add('66'+EOL+'1');               // vertices follow
  for J:=1 to NParams do begin P:=Value(Params[J-1]);
    Strings.Add('0'+EOL+'VERTEX');
    Strings.Add('8'+EOL+LayerName);
    Strings.Add('10'+EOL+FloatToDec(P.X, 4));
    Strings.Add('20'+EOL+FloatToDec(P.Y, 4));
    Strings.Add('30'+EOL+FloatToDec(P.Z, 4));
    Strings.Add('70'+EOL+'32');            // 3D polyline mesh vertex
  end;
  Strings.Add('0'+EOL+'SEQEND');
  if SendMirror then begin              // send starboard side of the ship also
    Strings.Add('0'+EOL+'POLYLINE');
    Strings.Add('8'+EOL+LayerName);      // layername
    Strings.Add('62'+EOL+IntToStr(Ind)); // color by layer
    Strings.Add('70'+EOL+'10');          // not closed
    Strings.Add('66'+EOL+'1');           // vertices follow
    for J:=1 to NParams do begin
      P:=Value(Params[J-1]);
      P.Y:=-P.Y;
      Strings.Add('0'+EOL+'VERTEX');
      Strings.Add('8'+EOL+LayerName);
      Strings.Add('10'+EOL+FloatToDec(P.X, 4));
      Strings.Add('20'+EOL+FloatToDec(P.Y, 4));
      Strings.Add('30'+EOL+FloatToDec(P.Z, 4));
      Strings.Add('70'+EOL+'32');          // 3D polyline mesh vertex
    end;
    Strings.Add('0'+EOL+'SEQEND');
  end;
end;

// Export all intersections to an individual DXF file as 2D polylines

procedure TFreeEdit.File_ExportDXF_2DPolylines;
var
  I: integer;
  Strings: TStringList;
  Dialog: TDXFExport2DDialog;
  ScaleFactor: double;
  SegLength: double;
  PrevCursor: TCursor;
  Filename, Layername: AnsiString;
  Intersections: TFasterListTFreeIntersection;
  CreateIndividualLayers: Boolean;

  function getLayerName(IntersectionType:TFreeIntersectionType):AnsiString;
  begin Result:='';
    case IntersectionType of
      fiStation:      Result:=Userstring(62);
      fiButtock:      Result:=Userstring(63);
      fiWaterline:    Result:=Userstring(64);
      fiDiagonal:     Result:=Userstring(65);
//    else begin Messagedlg(Userstring(66)+'!',mtError,[mbOK],0); exit; end;
    end;
  end;
  procedure DefineLayers(Stringlist: TStringList; LayerPrefix:AnsiString;
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
    Stringlist: TStringList; Scale: double; var Filename: AnsiString);
  var I,N: integer; Layername: AnsiString;

    procedure SaveSpline(Spline: TFreeSpline; Strings: TStringList;
      IntersectionType: TFreeIntersectiontype);
    var
      I,Ind,NParams,Cap, Pn,Pn1,Pn2: integer;
      Params: TFloatArray;
      SplineLength,T: double;
      P1, P2, Pkn: T3DVector;
      SplineValues: T3DVectorArray;

      procedure SaveVertex(P:T3DVector); // port side
      begin
        Strings.Add('0'+EOL+'VERTEX');
        Strings.Add('8'+EOL+LayerName);
        case IntersectionType of
          fiStation: begin
            Strings.Add('10'+EOL+FloatToDec(Scale * P.Y, 5));
            Strings.Add('20'+EOL+FloatToDec(Scale * P.Z, 5)); end;
          fiButtock: begin
            Strings.Add('10'+EOL+FloatToDec(Scale * P.X, 5));
            Strings.Add('20'+EOL+FloatToDec(Scale * P.Z, 5)); end;
          fiWaterline: begin
            Strings.Add('10'+EOL+FloatToDec(Scale * P.X, 5));
            Strings.Add('20'+EOL+FloatToDec(Scale * P.Y, 5)); end;
        end;
      end;
      procedure SaveVertexSB(P:T3DVector); // starboard side
      begin
        Strings.Add('0'+EOL+'VERTEX');
        Strings.Add('8'+EOL+LayerName);
        case IntersectionType of
          fiStation: begin
            Strings.Add('10'+EOL+FloatToDec(Scale * -P.Y, 5));
            Strings.Add('20'+EOL+FloatToDec(Scale * P.Z, 5)); end;
          fiWaterline: begin
            Strings.Add('10'+EOL+FloatToDec(Scale * P.X, 5));
            Strings.Add('20'+EOL+FloatToDec(Scale * -P.Y, 5)); end;
        end;
      end;
    begin
      Ind:=FindDXFColorIndex(Spline.Color);
      NParams:=0;
      Setlength(Params,Spline.NumberOfPoints); // count number of knucklepoints
      //if not Spline.Built then
      Spline.Rebuild;
      for I:=2 to Spline.NumberOfPoints-1 do
        if Spline.Knuckle[I-1] then begin
          Params[NParams]:=Spline.Parameter[I-1];
          Inc(NParams);
        end;

      (* // Calculate the SplineLength of the spline
      SplineLength:=0.0;
      P1:=Spline.Value(0.0);
      for I:=1 to 150 do
      begin
        P2:=Spline.Value(I / 150);
        SplineLength:=SplineLength+DistPP3D(P1, P2);
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
        Cap:=NParams+100;        Setlength(Params, Cap);
        Inc(Nparams);            Params[NParams-1]:=0.0;
        Inc(Nparams);            Params[NParams-1]:=1.0;
        for I:=1 to Spline.Fragments do begin
          T:=Spline.ChordlengthApproximation(I * SegLength / SplineLength);
          if NParams >= Cap then begin
            Inc(Cap, 50);
            Setlength(Params, Cap);
          end;
          Inc(NParams);
          Params[NParams-1]:=T;
        end;
        ArraySort(Params, NParams);
        *)
        // now export the actual calculated points
        Strings.Add('0'+EOL+'POLYLINE');
        Strings.Add('8'+EOL+LayerName);   // layername
        Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
        Strings.Add('66'+EOL+'1');    // vertices follow
        (*
        Pn:=0;
        for I:=0 to NParams-1 do begin
          P1:=Spline.Value(Params[I], Pn1, Pn2);
          if (Pn <> Pn1) and Spline.Knuckle[Pn1] then begin
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
        Strings.Add('0'+EOL+'SEQEND');
        if (Intersectiontype in [fiStation,fiWaterline])
        and (FreeShip.Visibility.ModelView=mvBoth) then begin // send the other half
          Strings.Add('0'+EOL+'POLYLINE');
          Strings.Add('8'+EOL+LayerName);                // layername
          Strings.Add('62'+EOL+IntToStr(Ind));           // color by layer
          Strings.Add('66'+EOL+'1');                     // vertices follow
          (*
          Pn:=0;
          for I:=0 to NParams-1 do
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
          Strings.Add( '0'+EOL+'SEQEND' );
        end;
      end;
    end; {SaveSpline}
  begin
    //if not Intersection.Built then
    Intersection.Rebuild;
    if intersection.Count > 0 then begin
      Layername:=getLayerName(Intersection.IntersectionType);
      if CreateIndividualLayers then
        Layername:=format(Layername+'%.2d',[IntersectionNumber]);
      Filename:=FreeShip.Preferences.ExportDirectory+Intersection.Description+'.dxf';
      for I:=1 to Intersection.Count do begin
        Intersection.Items[I-1].Color:=Intersection.Color;
        SaveSpline(Intersection.Items[I-1], Strings, Intersection.IntersectionType);
      end;
    end;
  end;
begin
  Dialog:=TDXFExport2DDialog.Create(FreeShip);
  ShowTranslatedValues(Dialog);
  Dialog.ExportDirectory:=FreeShip.Preferences.ExportDirectory;
  if FreeShip.ProjectSettings.ProjectUnits = fuMetric
  then Dialog.ComboBox1.ItemIndex:=0
  else if FreeShip.ProjectSettings.ProjectUnits = fuImperial
       then Dialog.ComboBox1.ItemIndex:=3;

  if Dialog.Execute then begin
    FreeShip.Preferences.ExportDirectory:=Dialog.ExportDirectory;
    if Length(FreeShip.Preferences.ExportDirectory) > 0 then
      if FreeShip.Preferences.ExportDirectory[Length(
        FreeShip.Preferences.ExportDirectory)] <> '\' then
        FreeShip.Preferences.ExportDirectory:=FreeShip.Preferences.ExportDirectory+'\';

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
//    try
      CreateIndividualLayers:=Dialog.cbCreateIndividualLayers.Checked;
      if Dialog.cbCreateIndividualFiles.Checked then begin        // send each intersection to an individual dxf file
        Intersections:=TFasterListTFreeIntersection.Create;
        if FreeShip.Visibility.ShowStations then Intersections.AddList(FreeShip.FStations);
        if FreeShip.Visibility.ShowButtocks then Intersections.AddList(FreeShip.FButtocks);
        if FreeShip.Visibility.ShowWaterlines then Intersections.AddList(FreeShip.FWaterlines);
        for I:=1 to Intersections.Count do begin
          Strings.Clear;
          Layername:=getLayerName(Intersections[I-1].IntersectionType);
          DefineLayers(Strings, Layername, I, 1);
          Strings.Add('0'+EOL+'SECTION');
          Strings.Add('2'+EOL+'ENTITIES');
          CreateDXFData(Intersections[I-1], I, Strings, ScaleFactor, Filename);
          Strings.Add('0'+EOL+'ENDSEC');
          Strings.Add('0'+EOL+'EOF');
          Strings.SaveToFile(Filename);
        end;
        FreeAndNil(Intersections);
      end else begin
        if (FreeShip.Visibility.ShowStations) and (FreeShip.NumberofStations > 0) then
        begin
          Strings.Clear;
          Layername:=getLayerName(fiStation);
          DefineLayers(Strings, Layername, 1, FreeShip.NumberofStations);
          Strings.Add('0'+EOL+'SECTION');
          Strings.Add('2'+EOL+'ENTITIES');
          for I:=1 to FreeShip.NumberofStations do
            CreateDXFData(FreeShip.Station[I-1], I, Strings, ScaleFactor, Filename);
          Strings.Add('0'+EOL+'ENDSEC');
          Strings.Add('0'+EOL+'EOF');
          Filename:=FreeShip.Preferences.ExportDirectory+'stations.dxf';
          Strings.SaveToFile(Filename);
        end;
        if (FreeShip.Visibility.ShowButtocks)
        and (FreeShip.NumberofButtocks > 0) then begin
          Strings.Clear;
          Layername:=getLayerName(fiButtock);
          DefineLayers(Strings, Layername, 1, FreeShip.NumberofButtocks);
          Strings.Add('0'+EOL+'SECTION');
          Strings.Add('2'+EOL+'ENTITIES');
          for I:=1 to FreeShip.NumberofButtocks do
            CreateDXFData(FreeShip.Buttock[I-1], I, Strings, ScaleFactor, Filename);
          Strings.Add('0'+EOL+'ENDSEC');
          Strings.Add('0'+EOL+'EOF');
          Filename:=FreeShip.Preferences.ExportDirectory+'buttocks.dxf';
          Strings.SaveToFile(Filename);
        end;
        if (FreeShip.Visibility.ShowWaterlines)
        and (FreeShip.NumberofWaterlines > 0) then begin
          Strings.Clear;
          Layername:=getLayerName(fiWaterline);
          DefineLayers(Strings, Layername, 1, FreeShip.NumberofWaterlines);
          Strings.Add('0'+EOL+'SECTION');
          Strings.Add('2'+EOL+'ENTITIES');
          for I:=1 to FreeShip.NumberofWaterlines do
            CreateDXFData(FreeShip.Waterline[I-1], I, Strings, ScaleFactor, Filename);
          Strings.Add('0'+EOL+'ENDSEC');
          Strings.Add('0'+EOL+'EOF');
          Filename:=FreeShip.Preferences.ExportDirectory+'waterlines.dxf';
          Strings.SaveToFile(Filename);
        end;
      end;
//    finally
      FreeAndNil(Strings);
      Screen.Cursor:=PrevCursor;
//    end;
  end;
  FreeAndNil(Dialog);
end;
//
// Appendage Hydrostatics Generator
//
procedure TFreeEdit.File_ExportArchimedes;
var
  Frames: TFasterListTFreeSpline;
  Frame: TFreeSpline;
  Tmp, Str: AnsiString;
  I, J, Np: integer;
  P: T3DVector;
  SaveDialog: TSaveDialog;
  ffile: textfile;
  Strings: TStringList;
begin
  Frames:=TFasterListTFreeSpline.Create;
  FreeShip.FBuildValidFrameTable(Frames, True);
  if Frames.Count > 0 then begin
    SaveDialog:=TSaveDialog.Create(FreeShip);
    SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
    SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '');
    SaveDialog.Filter :=
     createDialogFilter( 'ArchimedesMB multi body hull data',['hll'], False)
     +'|'+createDialogFilter('Archimedes single body hull data',['app']);
    SaveDialog.FilterIndex:=1;
    Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
    if SaveDialog.Execute then begin WestPoint;
      FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      if SaveDialog.FilterIndex = 2 then begin       // Single body Archimedes
        assignfile(ffile, ChangeFileExt(SaveDialog.FileName, '.app'));
        rewrite(FFile);
        Write(FFile,
        '***************************************************************'+#10+
        '**                                                           **'+#10+
        '**     Appendage Hydrostatics Generator                      **'+#10+
        '**     Version 1.0.1                                         **'+#10+
        '**     Copyright : John A. MacSween-2000                     **'+#10+
        '**     Please visit the website for updates and new versions **'+#10+
        '**                                                           **'+#10+
        '**                 www.naval-architecture.co.uk              **'+#10+
        '** File generated with FREE!ship                             **'+#10+
        '***************************************************************'+#10);
        // Hull name
        Write(FFile, 'APPENDAGE_NAME'+#10);
        if FreeShip.ProjectSettings.ProjectName <> ''
          then Tmp:=FreeShip.ProjectSettings.ProjectName
          else Tmp:=ChangeFileExt(ExtractFilename(FreeShip.Filename), '');
        Write(FFile, Tmp+#10);
        // Aft perpendicular
        Write(FFile, 'AP'+#10);
        Write(FFile, '0.0'+#10);
        // Forward perpendicular
        Write(FFile, 'FP'+#10);
        Write(FFile, FloatToDec(FreeShip.ProjectSettings.ProjectLength, 4)+#10);
        // Water density
        Write(FFile, 'DENSITY'+#10);
        Write(FFile, FloatToDec(FreeShip.ProjectSettings.ProjectWaterDensity, 3)+#10);
        // Now send the frames
        Write(FFile, 'NUMBER_OF_FRAMES'+#10);
        Write(FFile, IntToStr(Frames.Count)+#10);
        Write(FFile, '***START_OF_FRAME_INFORMATION***'+#10);
        for I:=1 to Frames.Count do begin
          Frame:=Frames[I-1];
          Np:=Frame.NumberOfPoints;
          Write(FFile, 'FRAME_INDEX: '+IntToStr(I-1)+#10);
          Write(FFile, 'FRAME_NAME'+#10);
          Write(FFile, 'Frame @ Y= '+FloatToStrF(0.5 * (Frame.Min.X+Frame.Max.X), ffFixed, 7, 4)+#10);
          Write(FFile, 'FRAME_Y'+#10);
          Write(FFile, FloatToStrF(0.5 * (Frame.Min.X+Frame.Max.X),ffFixed, 7, 4)+#10);
          Write(FFile, 'NUMBER_OF_COORDINATES'+#10);
          Write(FFile, IntToStr(2 * Np-1)+#10);
          Write(FFile, '***START_OF_ORDINATES***'+#10);
          // First send the starboard side
          for J:=Np downto 1 do begin           //P:=Frame.Value((J-1)/(Np-1));
            P:=Frame.Point[J-1];
            P.Y:=-P.Y;
            Write(FFile, FloatToDec(P.Y, 4)+#10);
            Write(FFile, FloatToDec(P.Z, 4)+#10);
          end;
          // then port side
          for J:=2 to Np do begin               //P:=Frame.Value((J-1)/(Np-1));
            P:=Frame.Point[J-1];
            Write(FFile, FloatToDec(P.Y, 4)+#10);
            Write(FFile, FloatToDec(P.Z, 4)+#10);
          end;
          Write(FFile, '***END_OF_ORDINATES***'+#10);
          FreeAndNil(Frame);
        end;
        Write(FFile, '***END_OF_FILE***'+#10);
        closefile(FFile);
      end else begin                                 // Multi body ArchimedesMB
        Strings:=TStringList.Create;                   // Add file version info
        Strings.Add(' <?xml version="1.0" encoding="UTF-8" ?>');  // Start hull
        Strings.Add('<HULL>');                                    // Hull name
        Strings.Add('<HULL_NAME>');
        if FreeShip.ProjectSettings.ProjectName <> ''
           then Str:=FreeShip.ProjectSettings.ProjectName
           else Str:=ChangeFileExt(ExtractFilename(FreeShip.Filename), '');
        Strings.Add(Str);
        Strings.Add('</HULL_NAME>');                           // Water density
        Strings.Add('<DENSITY>'+#32+FloatToDec(
          FreeShip.ProjectSettings.ProjectWaterDensity, 3)+#32+'</DENSITY>');
        // Aft perpendicular
        Strings.Add('<AP> 0.0 </AP>');                 // Forward perpendicular
        Strings.Add('<FP>'+#32+FloatToDec(FreeShip.ProjectSettings.ProjectLength,4)
                          +#32+'</FP>' );
        // Draught marks
        Strings.Add('<FWD_DRAUGHT_MARK>'+#32+FloatToDec(
          FreeShip.ProjectSettings.ProjectDraft, 4)+#32+'</FWD_DRAUGHT_MARK>');
        Strings.Add('<MID_DRAUGHT_MARK>'+#32+FloatToDec(
          FreeShip.ProjectSettings.ProjectDraft, 4)+#32+'</MID_DRAUGHT_MARK>');
        Strings.Add('<AFT_DRAUGHT_MARK>'+#32+FloatToDec(
          FreeShip.ProjectSettings.ProjectDraft, 4)+#32+'</AFT_DRAUGHT_MARK>');
        // Number of appendages (only 1, the main hull)
        Strings.Add('<APPENDAGE_COUNT> 1 </APPENDAGE_COUNT>');
        Strings.Add('<APPENDAGE>');
        Strings.Add('<APPENDAGE_NAME>');
        Strings.Add('Main Hull');
        Strings.Add('</APPENDAGE_NAME>');                     // Some constants
        Strings.Add('<ACTIVE> 1 </ACTIVE>');
        Strings.Add('<FREE_FLOODING> 0 </FREE_FLOODING>');
        Strings.Add('<APPENDAGE_COLOUR> 0 </APPENDAGE_COLOUR>'); // Now send the frames
        Strings.Add('<SECTION_COUNT>'+#32+IntToStr(Frames.Count)
                                     +#32+'</SECTION_COUNT>');
        for I:=1 to Frames.Count do begin
          Frame:=Frames[I-1];
          Np:=2 * Frame.NumberOfPoints+1;
          Strings.Add('<SECTION>');
          Strings.Add('<SECTION_NAME>');
          Strings.Add(FloatToStrF(0.5 * (Frame.Min.X+Frame.Max.X), ffFixed, 7, 4));
          Strings.Add('</SECTION_NAME>');
          Strings.Add('<YCOORD>'+#32+FloatToStrF(0.5 * (Frame.Min.X+Frame.Max.X), ffFixed, 7, 4)+#32+'</YCOORD>');
          Strings.Add('<OFFSET_COUNT>'+#32+IntToStr(2 * Np-1) +
            #32+'</OFFSET_COUNT>');
          Strings.Add('<OFFSETS>');            // First send the starboard side
          for J:=Np downto 1 do begin
            P:=Frame.Value((J-1) / (Np-1));
            P.Y:=-P.Y;
            Strings.Add(FloatToDec(P.Y, 4)+#32+FloatToDec(P.Z, 4));
          end;
          // then port side
          for J:=2 to Np do begin
            P:=Frame.Value((J-1) / (Np-1));
            Strings.Add(FloatToDec(P.Y, 4)+#32+FloatToDec(P.Z, 4));
          end;
          Strings.Add('</OFFSETS>');
          Strings.Add('</SECTION>');
          FreeAndNil(Frame);
        end;
        Strings.Add('</APPENDAGE>');                        // end of appendage
        Strings.Add('</HULL>');                             // end of hull
        Strings.SaveToFile(ChangeFileExt(SaveDialog.FileName, '.hll'));
        FreeAndNil(Strings);
      end;
    end else
      for I:=1 to Frames.Count do begin
        Frame:=Frames[I-1];
        FreeAndNil(Frame);
      end;
    FreeAndNil(SaveDialog);
  end;
  FreeAndNil(Frames);
end;

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
        Point:=FreeShip.Surface.SubDivPoint[I-1];
        Writeln(FFile, MakeLength(Point.Coordinate.X, 6, 12), #32,
          MakeLength(Point.Coordinate.Y, 6, 12), #32,
          MakeLength(Point.Coordinate.Z, 6, 12));
      end;
      CloseFile(FFile);
    end else MessageDlg(Userstring(97), mtError, [mbOK], 0);
  end;
  FreeAndNil(SaveDialog);

end;{TFreeEdit.File_ExportCoordinates}

// Exports all intersections to a textfile as 3D points

procedure TFreeEdit.File_ExportOffsets;
var
  SaveDialog: TSaveDialog;
  Strings: TStringList;
  I: integer;
  procedure SendSpline( Spline:TFreespline );
  var J: integer; Str: AnsiString; P: T3DVector;
  begin
    for J:=1 to Spline.NumberOfPoints do begin P:=Spline.Point[J-1];
      Str:='        '+MakeLength( P.X,4,10 ) +
                  #32+MakeLength( P.Y,4,10 ) +
                  #32+MakeLength( P.Z,4,10 );
      if Spline.Knuckle[J-1] then Str:=Str+'    KNUCKLE';
      Strings.Add(Str);
    end;
  end;
  procedure SendIntersection( Intersection: TFreeIntersection );
  var I: integer; Str: AnsiString; Spline: TFreeSpline;
  begin
    if not Intersection.Built then Intersection.Rebuild;
    if Intersection.Count > 0 then begin
      Str:=Intersection.Description;
      Strings.Add( Str );
      if Intersection.Count > 1 then Strings.Add(IntToStr(Intersection.Count)+' segments.');
      for I:=1 to Intersection.Count do begin
        Spline:=Intersection.Items[I-1];
        if Intersection.Count>1 then Strings.Add('SEGMENT '+IntToStr(I));
        SendSpline(Spline);
      end;
    end;
  end;

begin
  SaveDialog:=TSaveDialog.Create(FreeShip);
  SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName),'.txt');
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
  Layername: AnsiString;
begin
  Dialog:=TSaveDialog.Create( FreeShip );
  Dialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  Dialog.FileName:=ChangeFileExt(ExtractFilename(FreeShip.FileName), '.dxf');
  Dialog.Filter:=createDialogFilter(rsAutocadDxfFile,['dxf']);
  dialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if Dialog.Execute then begin WestPoint;
    FreeShip.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
    Strings:=TStringList.Create;
    Strings.Add('0'+EOL+'SECTION');
    Strings.Add('2'+EOL+'ENTITIES');
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
      Points:=EdgePointLists[I-1];
      //Points.Add(EdgePointLists[I-1].StartPoint);
      //Points.Add(EdgePointLists[I-1].EndPoint);
      Strings.Add('0'+EOL+'POLYLINE');
      Strings.Add('8'+EOL+LayerName);       // layername
      Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
      Strings.Add('70'+EOL+'10');           // not closed
      Strings.Add('66'+EOL+'1');            // vertices follow
      for J:=1 to Points.Count do begin
        Point:=Points[J-1];
        Strings.Add('0'+EOL+'VERTEX');
        Strings.Add('8'+EOL+LayerName);
        Strings.Add('10'+EOL+FloatToDec(Point.Coordinate.X, 4));
        Strings.Add('20'+EOL+FloatToDec(Point.Coordinate.Y, 4));
        Strings.Add('30'+EOL+FloatToDec(Point.Coordinate.Z, 4));
        Strings.Add('70'+EOL+'32');              // 3D polyline mesh vertex
      end;
      Strings.Add('0'+EOL+'SEQEND');
      if FreeShip.Visibility.ModelView = mvBoth then begin
        Strings.Add('0'+EOL+'POLYLINE');
        Strings.Add('8'+EOL+LayerName);       // layername
        Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
        Strings.Add('70'+EOL+'10');           // not closed
        Strings.Add('66'+EOL+'1');            // vertices follow
        for J:=1 to Points.Count do begin
          Point:=Points[J-1];
          Strings.Add('0'+EOL+'VERTEX');
          Strings.Add('8'+EOL+LayerName);
          Strings.Add('10'+EOL+FloatToDec(Point.Coordinate.X, 4));
          Strings.Add('20'+EOL+FloatToDec(-Point.Coordinate.Y, 4));
          Strings.Add('30'+EOL+FloatToDec(Point.Coordinate.Z, 4));
          Strings.Add('70'+EOL+'32');    // 3D polyline mesh vertex
        end;
        Strings.Add('0'+EOL+'SEQEND');
      end;
      FreeAndNil(Points);
    end;
    FreeAndNil(EdgePointLists);
    Strings.Add('0'+EOL+'ENDSEC');
    Strings.Add('0'+EOL+'EOF');
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
      Strings.Add('0'+EOL+'SECTION');
      Strings.Add('2'+EOL+'ENTITIES');
      for i:=0 to FreeShip.Surface.NumberOfLayers-1 do
        FreeShip.Surface.Layer[i].SaveToDXF( Strings );
      Strings.Add('0'+EOL+'ENDSEC');
      Strings.Add('0'+EOL+'EOF');
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
  SaveDialog.Filter:=createDialogFilter('FREE!ship Exchange Format',['fef']);
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if SaveDialog.Execute then begin WestPoint;
    FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
    Strings:=TStringList.Create;
    // Add general info and mainparticulars
    Strings.Add(FreeShip.ProjectSettings.FProjectName);
    Strings.Add(FreeShip.ProjectSettings.FProjectDesigner);
    Strings.Add(FreeShip.ProjectSettings.FProjectComment);
    Strings.Add(FreeShip.ProjectSettings.FProjectFileCreatedBy);
    Strings.Add(FloatToDec(FreeShip.ProjectSettings.ProjectLength,4) +
      #32+FloatToDec(FreeShip.ProjectSettings.ProjectBeam,4)+#32 +
      FloatToDec(FreeShip.ProjectSettings.ProjectDraft,4)+#32 +
      FloatToDec(FreeShip.ProjectSettings.ProjectWaterDensity,5)+#32 +
      FloatToDec(FreeShip.ProjectSettings.ProjectAppendageCoefficient,5) +
      #32+IntToStr(Ord(FreeShip.ProjectSettings.ProjectUnits))+#32 +
      'true'+ //BoolToStr(FreeShip.ProjectSettings.MainparticularsHasBeenset) +
      #32+IntToStr(Ord(FreeShip.Precision)));
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
  Str: AnsiString;
  P, Pkn: T3DVector;
  NParams: integer;
  Params: TFloatArray;
  Pn, Pn1, Pn2: integer;
begin
  SaveDialog:=TSaveDialog.Create(FreeShip);
  SaveDialog.InitialDir:=FreeShip.Preferences.ExportDirectory;
  Str:=ChangeFileExt(ExtractFilename(FreeShip.Filename),'.GF'); // no spaces allowed in filename
  repeat
    I:=Pos(#32, Str);
    if I <> 0 then Delete(Str, I, 1);
  until I = 0;
  Savedialog.FileName:=Str;
  SaveDialog.Filter:=createDialogFilter( 'GHS files',['gf'] );
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if not SaveDialog.Execute then begin FreeAndNil(Savedialog); exit; end;
  WestPoint;
  FreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
  PrevCursor:=Screen.Cursor;
  Screen.Cursor:=crHourGlass;
  Strings:=TStringList.Create;
  Frames:=TFasterListTFreeSpline.Create;
//try
    FreeShip.FBuildValidFrameTable( Frames,True );
    Scale:=1.0;
    //       if FreeShip.ProjectSettings.ProjectUnits=fuMetric then Scale:=1.0
    //                                                      else Scale:=1/Foot;
    Str:=FreeShip.ProjectSettings.ProjectName;
    if Length(Str) > 58 then Str:=Copy( Str,1,58 );
    Strings.Add(Str);
    // ProjectDescription, max 58 characters
    Strings.Add('L:'+FloatToStrF(Scale*FreeShip.ProjectSettings.ProjectLength,ffFixed,7,3));
    // Length
    Strings.Add('W:'+FloatToStrF(Scale*FreeShip.ProjectSettings.ProjectBeam,ffFixed,7,3));
    // Beam
    Strings.Add('OL:Frame 0');
    Strings.Add('OT:Centerplane');
    Strings.Add('OV:Baseline');                             // Units preference
    if FreeShip.ProjectSettings.ProjectUnits = fuMetric then Strings.Add('P:M')
                                                        else Strings.Add('P:F');
    Strings.Add('\Generated with FREE!ship');           // Add max. 10 comments
//  Strings.Add('\www.freeship.org');
    Strings.Add('*');                                             // Save shape
    Strings.Add('HULL'); // shape name
    Strings.Add(IntToStr(Frames.Count)); // Number of sections
    for I:=Frames.Count downto 1 do begin
      Section:=Frames[I-1];
      if Section.NumberOfPoints > 0 then
      if section.Point[Section.NumberOfPoints-1].Y > 0 then begin
        Section.Knuckle[Section.NumberOfPoints-1]:=True;
        Section.Add(Section.Point[Section.NumberOfPoints-1]);
      end;
      NParams:=0;
      Setlength(Params, Section.NumberOfPoints); // count number of knucklepoints
      for J:=2 to Section.NumberOfPoints-1 do
      if Section.Knuckle[J-1] then begin
        Params[NParams]:=Section.Parameter[J-1];
        Inc(NParams);
      end;
      if Section.NumberOfPoints > 100 then begin
        Section.Fragments:=100;
        Setlength(Params, NParams+Section.Fragments);
        for J:=1 to Section.Fragments do begin
          Params[NParams]:=(J-1) / (Section.Fragments-1);
          Inc(NParams);
        end;
      end else begin
        Setlength(Params, NParams+Section.NumberOfPoints);
        for J:=1 to Section.NumberOfPoints do begin
          Params[NParams]:=Section.Parameter[J-1];
          Inc(NParams);
        end;
      end;
      ArraySort( Params,NParams );
//    SortFloatArray(Params, NParams);
      Strings.Add(FloatToDec(-Scale * Section.Min.X, 4)+','+IntToStr(NParams));
      Pn:=0;
      for J:=0 to NParams-1 do begin
        P:=Section.Value(Params[J], Pn1, Pn2);
        if (Pn<>Pn1) and Section.Knuckle[Pn1] then begin Pn:=Pn1;
          Pkn:=Section.Point[Pn1];
          Strings.Add(FloatToDec(Scale * Pkn.Y, 4)+','+FloatToDec(Scale * Pkn.Z, 4));
        end;
        Strings.Add(FloatToDec(Scale * P.Y, 4)+','+FloatToDec(Scale * P.Z, 4));
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
    Strings.Add('WATER');         // FluidName
    strings.Add('1');             // part type (displacement)
    if FreeShip.ProjectSettings.ProjectUnits=fuMetric then
      Strings.Add(FloatToStrF(FreeShip.ProjectSettings.ProjectWaterDensity,ffFixed,7,3))
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
      I:=Pos( #32,Str );
      if I<>0 then Delete( Str,I,1 );
    until I=0;
    Str:=ExtractFilePath(SaveDialog.Filename)+Str;
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
  if FreeShip.NumberOfSelectedControlFaces = 0 then begin
    SelectDlg:=TFreeSelectLayersDialog.Create(FreeShip);
    ShowTranslatedValues(SelectDlg);
    if SelectDlg.Execute(FFreeShip, fsFaces) then
      SelectDlg.ExtractSelectedFaces(Faces);
    for I:=FreeShip.NumberOfSelectedControlFaces downto 1 do
      FreeShip.SelectedControlFace[I-1].Selected:=False;
    Freeship.ReDraw;
    FreeAndNil(SelectDlg);
  end else begin
    Faces.Capacity:=Faces.Count+FreeShip.NumberOfSelectedControlFaces;
    for I:=1 to FreeShip.NumberOfSelectedControlFaces do
      Faces.Add(FreeShip.SelectedControlFace[I-1]);
  end;
  if Faces.Count>0 then FreeShip.SavePart(Faces);
  FreeAndNil( Faces );
end;

// Save NURBS patches to an IGES file
procedure TFreeEdit.File_ExportIGES;
const MinimizeFaces = True;
      SendTriangles = False;//true;
var
  I,J,K,LI, Cols,Rows, NAssembled, PrevLevel,ColorIndex,NSurfaces : integer;
  Dialog: TSaveDialog;
  Prev: TCursor;
  Layers: TFasterListTFreeSubdivisionLayer;
  Layer: TFreeSubdivisionLayer;
  FaceData: TFreeFaceGrid;
  Assembled: TFreeFaceArray;
  IGESList: TFreeIGESList;
  Grid: TFreeSubdivisionPointGrid;
  CtrlFace: TFreeSubdivisionControlFace;
  Face: TFreeSubdivisionFace;
  ColorIndices: array of integer;
  CheckFaces: TFasterListTFreeSubdivisionFace;

  function FindFourtPoint( P1,P2,p3: TFreeSubdivisionPoint ): TFreeSubdivisionPoint;
  var Face: TFreeSubdivisionFace;
      I, J: integer;
      List: TList;
  begin
    Result:=nil;
    if (P1 <> P2) and (P2 <> P3) and (P1 <> P3) then
      for I:=1 to P2.NumberOfFaces do begin
        Face:=P2.Face[I-1];
        if (Face.IndexOfPoint(P1)<>-1)
     // and (Face.IndexOfPoint(P2)<>-1)
        and (Face.IndexOfPoint(P3)<>-1) then begin
          List:=TList.Create;
          for J:=1 to face.NumberOfpoints do list.Add(Face.Point[J-1]);
          J:=List.IndexOf( P1 ); if J<>-1 then list.Delete( J );
          J:=List.IndexOf( P2 ); if J<>-1 then list.Delete( J );
          J:=List.IndexOf( P3 ); if J<>-1 then list.Delete( J );
          if list.Count>0 then Result:=TFreeSubdivisionPoint(List[0]);
          FreeAndNil( List );
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
        for I:=1 to Edge.NumberOfFaces do begin
          Face:=Edge.Face[I-1];
          if (Face.IndexOfPoint(P1) = -1) or (Face.IndexOfPoint(P2) = -1) or
            (Face.IndexOfPoint(P3) = -1) or (Face.IndexOfPoint(P4) = -1) then
          begin
            Index:=Face.IndexOfPoint(P3);
            if Index <> -1 then begin
              Index:=(Index+1) mod Face.NumberOfpoints;
              if Face.Point[index] = P2 then begin      // face is oriented CCW
                Index:=(Index+1) mod Face.NumberOfpoints;
                OppPoint2:=Face.Point[index];
                Index:=(Index+1) mod Face.NumberOfpoints;
                OppPoint3:=Face.Point[index];
              end else begin
                Index:=Face.IndexOfPoint(P2);
                if Index <> -1 then begin
                  Index:=(Index+1) mod Face.NumberOfpoints;
                  if Face.Point[index] = P3 then begin   // face is oriented CW
                    Index:=(Index+1) mod Face.NumberOfpoints;
                    OppPoint3:=Face.Point[index];
                    Index:=(Index+1) mod Face.NumberOfpoints;
                    OppPoint2:=Face.Point[index];
                  end;
                end;
              end;
            end; break;
          end;
        end;
  end;{FindOpposingPoints}

  procedure AssembleTriangle(var Cols, Rows: integer; var Grid: TFreeSubdivisionPointGrid;
    Face: TFreeSubdivisionControlface);
  var
    I,J,N, Index: integer;
    Points: TFasterListTFreeSubdivisionPoint;
    Faces: TFasterListTFreeSubdivisionface;
    Child: TFreeSubdivisionface;
    P, InteriorPoint: TFreeSubdivisionPoint;
  begin // Initialize grid
    Cols:=0;
    Rows:=0;
    Points:=TFasterListTFreeSubdivisionPoint.Create;
    Faces:=TFasterListTFreeSubdivisionFace.Create;
    for I:=1 to Face.ChildCount do begin
      Child:=Face.Child[I-1];
      Faces.Add(Child);
      for J:=1 to Child.NumberOfpoints do begin
        P:=Child.Point[J-1];
        if Points.IndexOf(P) = -1 then Points.Add(P);
      end;
    end;
//  Faces.Sort;
    InteriorPoint:=nil;                    // Try to isolate the interior point
    for I:=1 to Points.Count do begin
      P:=Points[I-1]; // check how many of the childfaces are connected (interior point must have 3)
      N:=0;
      for J:=1 to P.NumberOfFaces do
        if Faces.IndexOf(P.Face[J-1])<>-1 then Inc(N);
      if N=3 then begin InteriorPoint:=P; break; end;
    end;
    if Interiorpoint<>nil then begin
      Cols:=3;
      Rows:=3;
      Setlength(Grid, Rows);
      for I:=1 to Rows do begin
        Setlength(Grid[I-1], Cols);
        for J:=1 to Cols do Grid[I-1][J-1]:=nil;
      end;
      Grid[1][1]:=InteriorPoint;
      Child:=Face.Child[2];
      Index:=Child.IndexOfPoint(InteriorPoint);
      Grid[1][0]:=Child.Point[(index+1) mod 4];
      Grid[0][0]:=Child.Point[(index+2) mod 4];
      Grid[0][1]:=Child.Point[(index+3) mod 4];
      FindOpposingPoints(Grid[0][0], Grid[0][1], Grid[1][1], Grid[1][0], Grid[0][2], Grid[1][2]);
      FindOpposingPoints(Grid[0][1], Grid[1][1], Grid[1][0], Grid[0][0], Grid[2][1], Grid[2][0]);
      Grid[2][2]:=Grid[2][1];
//      for I:=1 to Rows do
//        for J:=1 to cols do
//          if grid[I-1][j-1] = nil then WriteLn(Userstring(98));
    end else ShowMessage( Userstring(99) );
    FreeAndNil(Faces);
    FreeAndNil(Points);
  end; {AssembleTriangle}

  procedure ProcessGrid( Cols, Rows: integer; Grid: TFreeSubdivisionPointGrid;
     ColorInd: integer; LayerIsSymmetric: boolean);   // convert grid to a NURB
  var
    NURB, NURB2: TFreeNURBsurface;
    I, J: integer;
    BottomRow: array of TFreeSubdivisionPoint;
    TopRow: array of TFreeSubdivisionPoint;
    LeftColumn: array of TFreeSubdivisionPoint;
    RightColumn: array of TFreeSubdivisionPoint;
    BottomLeft,BottomRight,TopLeft,TopRight: TFreeSubdivisionPoint;
    BottomPresent,LeftPresent,RightPresent,TopPresent: boolean;
    P: T3DVector;

    function PhantomPoint(BorderPoint, InnerPoint: T3DVector): T3DVector;
    begin
      Result.X:=2 * BorderPoint.X-InnerPoint.X;
      Result.Y:=2 * BorderPoint.Y-InnerPoint.Y;
      Result.Z:=2 * BorderPoint.Z-InnerPoint.Z;
    end;{PhantomPoint}

    function CornerPoint(P5, P6, P8, P9: T3DVector): T3DVector;
    var
      P2, P3, P4, P7: T3DVector;
    begin
      P2:=PhantomPoint(P5, P8);
      P3:=PhantomPoint(P6, P9);
      P4:=PhantomPoint(P5, P6);
      P7:=PhantomPoint(P8, P9);
      Result.X:=20 * P5.X-4 * P2.X-P3.X-4 * P4.X-4 * P6.X - P7.X-4 * P8.X-P9.X;
      Result.Y:=20 * P5.Y-4 * P2.Y-P3.Y-4 * P4.Y-4 * P6.Y - P7.Y-4 * P8.Y-P9.Y;
      Result.Z:=20 * P5.Z-4 * P2.Z-P3.Z-4 * P4.Z-4 * P6.Z - P7.Z-4 * P8.Z-P9.Z;
    end;{CornerPoint}

  begin
    if (Cols > 0) and (Rows > 0) then begin
      Setlength(BottomRow, Cols);
      Setlength(TopRow, Cols);
      Setlength(LeftColumn, Rows);
      Setlength(RightColumn, Rows);      // assemble bottom row to set tangency
      BottomPresent:=True;
      for I:=2 to Cols do begin
        FindOpposingPoints(Grid[Rows-2][I-2], Grid[Rows-1][I-2],
          Grid[Rows-1][I-1], Grid[Rows-2][I-1], BottomRow[I-2],
          BottomRow[I-1]);
        if (BottomRow[I-2] = nil) or (BottomRow[I-1] = nil) then
          BottomPresent:=False;
      end;
      RightPresent:=True;              // assemble right column to set tangency
      for I:=2 to Rows do
      begin
        FindOpposingPoints(Grid[I-1][Cols-2], Grid[I-1][Cols-1],
          Grid[I-2][Cols-1], Grid[I-2][Cols-2], RightColumn[I-1],
          RightColumn[I-2]);
        if (RightColumn[I-1] = nil) or (RightColumn[I-2] = nil) then
          RightPresent:=False;
      end;
      // assemble top row
      TopPresent:=True;
      for I:=2 to Cols do begin
        FindOpposingPoints(Grid[1][I-1], Grid[0][I-1], Grid[0][I-2],
          Grid[1][I-2], TopRow[I-1], TopRow[I-2]);
        if (TopRow[I-2] = nil) or (TopRow[I-1] = nil) then
          TopPresent:=False;
      end;
      // Assemble left column
      LeftPresent:=True;
      for I:=2 to Rows do begin
        FindOpposingPoints(Grid[I-2][1], Grid[I-2][0], Grid[I-1]
          [0], Grid[I-1][1], LeftColumn[I-2], LeftColumn[I-1]);
        if (LeftColumn[I-1] = nil) or (LeftColumn[I-2] = nil) then
          LeftPresent:=False;
      end;
      BottomLeft:=nil;
      BottomRight:=nil;
      TopLeft:=nil;
      TopRight:=nil;
      if BottomPresent and leftPresent then
        BottomLeft:=FindFourtPoint(LeftColumn[Rows-1],Grid[Rows-1][0],BottomRow[0]);
      // find bottomleft cornerpoint
      if BottomPresent and RightPresent then
        BottomRight:=FindFourtPoint(RightColumn[Rows-1],Grid[Rows-1][Cols-1],BottomRow[Cols-1]);
      // find bottomRight cornerpoint
      if TopPresent and leftPresent then
        TopLeft:=FindFourtPoint(LeftColumn[0], Grid[0][0], TopRow[0]);
      // find Topleft cornerpoint
      if TopPresent and RightPresent then
        TopRight:=FindFourtPoint(RightColumn[0], Grid[0][Cols-1], TopRow[Cols-1]);
      // find TopRight cornerpoint

      NURB:=TFreeNURBsurface.Create(FreeShip.Surface);
      NURB.SetCapacity(Cols+2, Rows+2);
      NURB.ColCount:=Nurb.ColCapacity;
      NURB.RowCount:=Nurb.RowCapacity;
      for I:=1 to Rows do
        for J:=1 to COLS do
          NURB.Point[J, I]:=Grid[I-1][J-1].Coordinate;

      if SendTriangles then
        if (Grid[Rows-1][Cols-1] = Grid[Rows-1][Cols-2])
        and (Grid[Rows-1][Cols-1] = Grid[Rows-2][Cols-1]) then begin
          Nurb.Point[Cols, Rows]:=Grid[Rows-1][Cols-1].LimitPoint;
          Nurb.Point[Cols-1, Rows]:=Grid[Rows-1][Cols-1].LimitPoint;
          Nurb.Point[Cols, Rows-1]:=Grid[Rows-1][Cols-1].LimitPoint;
          Nurb.RowCount:=Nurb.RowCount-1+1;
        end;                                // check for special triangle case

      if TopPresent
      then for I:=1 to Cols do Nurb.Point[I,0]:=TopRow[I-1].Coordinate
      else for I:=1 to Cols do Nurb.Point[I,0]:=PhantomPoint(Nurb.Point[I,1],Nurb.Point[I,2]);
      if BottomPresent
      then for I:=1 to Cols do Nurb.Point[I,Rows+1]:=BottomRow[I-1].Coordinate
      else for I:=1 to Cols do Nurb.Point[I,Rows+1]:=PhantomPoint(Nurb.Point[I,Rows],Nurb.Point[I,Rows-1]);
      if LeftPresent
      then for I:=1 to Rows do Nurb.Point[0,I]:=LeftColumn[I-1].Coordinate
      else for I:=1 to Rows do Nurb.Point[0,I]:=PhantomPoint(Nurb.Point[1,I],Nurb.Point[2,I]);
      if RightPresent
      then for I:=1 to Rows do Nurb.Point[Cols+1, I]:=RightColumn[I-1].Coordinate
      else for I:=1 to Rows do Nurb.Point[Cols+1, I]:=PhantomPoint(Nurb.Point[Cols,I],Nurb.Point[Cols-1,I]);

      if TopLeft <> nil
      then Nurb.Point[0,0]:=TopLeft.Coordinate
      else Nurb.Point[0,0]:=CornerPoint(Nurb.Point[1,1],Nurb.Point[2,1],Nurb.Point[1,2], Nurb.Point[2,2]);
      if TopRight <> nil
      then Nurb.Point[Nurb.ColCount-1,0]:=TopRight.Coordinate
      else Nurb.Point[Nurb.ColCount-1,0]:=CornerPoint(Nurb.Point[Nurb.Colcount-2, 1],
           Nurb.Point[Nurb.Colcount-3,1],Nurb.Point[Nurb.Colcount-2,2],
           Nurb.Point[Nurb.Colcount-3,2] );
      if BottomLeft <> nil
      then Nurb.Point[0, Nurb.RowCount-1]:=BottomLeft.Coordinate
      else Nurb.Point[0, Nurb.RowCount-1]:=CornerPoint(Nurb.Point[1, Nurb.Rowcount-2],
           Nurb.Point[2, Nurb.Rowcount-2], Nurb.Point[1,Nurb.Rowcount-3],
           Nurb.Point[2, Nurb.Rowcount-3]);
      if BottomRight <> nil
      then Nurb.Point[Nurb.ColCount-1, Nurb.RowCount-1]:=BottomRight.Coordinate
      else Nurb.Point[Nurb.ColCount-1, Nurb.RowCount-1]:=CornerPoint(Nurb.Point[Nurb.Colcount-2, Nurb.Rowcount-2],
          Nurb.Point[Nurb.Colcount-3, Nurb.Rowcount-2],
          Nurb.Point[Nurb.Colcount-2, Nurb.Rowcount-3],
          Nurb.Point[Nurb.Colcount-3, Nurb.Rowcount-3]);
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
      Nurb.Point[0, 0]:=Grid[0][0].LimitPoint;
      Nurb.Point[Cols+1, 0]:=Grid[0][Cols-1].LimitPoint;
      Nurb.Point[0, Rows+1]:=Grid[Rows-1][0].LimitPoint;
      Nurb.Point[Cols+1, Rows+1]:=Grid[Rows-1][Cols-1].LimitPoint;
      IGESList.Add_Entity_128(NURB, ColorInd);
      if (FreeShip.Visibility.ModelView = mvBoth)
      and LayerIsSymmetric then begin
        NURB2:=TFreeNURBsurface.Create(FreeShip.Surface);
        NURB2.SetCapacity(Nurb.ColCount, Nurb.RowCount);
        NURB2.ColCount:=Nurb2.ColCapacity;
        NURB2.RowCount:=Nurb2.RowCapacity;
        NURB2.ColDegree:=Nurb.ColDegree;
        NURB2.RowDegree:=Nurb.RowDegree;
        for I:=Nurb.ColCount downto 1 do
          for J:=Nurb.RowCount downto 1 do begin
            P:=NURB.Point[I-1, J-1];
            P.Y:=-P.Y;
            NURB2.Point[NURB2.Colcount-I, Nurb2.RowCount-J]:=P;
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
  Dialog.Filter:=createDialogFilter('IGES files',['igs']);
  dialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if Dialog.Execute then begin WestPoint;
    Prev:=Screen.Cursor;
    Screen.Cursor:=crHourglass;
    PrevLevel:=FreeShip.Surface.DesiredSubdivisionLevel;
    NSurfaces:=0;
//  try
      FreeShip.Surface.DesiredSubdivisionLevel:=1;
      FreeShip.Surface.SubdivisionMode:=fmCatmullClark;
      if not FreeShip.Surface.Built then FreeShip.Surface.Rebuild;
      FreeShip.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
      IGESList:=TFreeIGESList.Create;
      IGESList.IGESUnits:=FreeShip.ProjectSettings.ProjectUnits;
      IGESList.SystemID:='FREE!ship'+#32+VersionString(CurrentVersion);
      IGESList.FileCreatedBy:=FreeShip.ProjectSettings.ProjectFileCreatedBy;
      IGESList.FileName:=Dialog.FileName;
      // Build color table
      Layers:=TFasterListTFreeSubdivisionLayer.Create;
      for I:=0 to FreeShip.NumberOfLayers-1 do
        if (FreeShip.Layer[I].SurfaceVisible) and (FreeShip.Layer[I].Count > 0) then
          Layers.Add(FreeShip.Layer[I]);
//    Layers.Sort;
      Setlength(ColorIndices, Layers.Count);
      for I:=0 to Layers.Count-1 do begin
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
              CheckFaces.Add(Facedata.Faces[J-1][K-1]);
          if (FaceData.NCols > 0) and (FaceData.NRows > 0) then
            if ((FaceData.NCols > 1) and (FaceData.NRows >= 1)) or
              ((FaceData.NCols >= 1) and (FaceData.NRows > 1)) or
              ((FaceData.NCols = 1) and (FaceData.NRows = 1) and
              (FaceData.Faces[0][0].NumberOfPoints = 4)) then begin
              CtrlFace:=FaceData.Faces[0][0];
              LI:=Layers.IndexOf(Ctrlface.Layer);
              ColorIndex:=ColorIndices[LI];
              FreeShip.Surface.ConvertToGrid(FaceData, Cols, Rows, Grid);
              ProcessGrid(Cols, Rows, Grid, ColorIndex, Ctrlface.Layer.Symmetric);
            end else begin
              CtrlFace:=FaceData.Faces[0][0];
              if Layers.IndexOf(Ctrlface.Layer) <> -1
              then ColorIndex:=ColorIndices[Layers.IndexOf(Ctrlface.Layer)]
              else Colorindex:=0;
              if (CtrlFace.NumberOfpoints = 3) and (SendTriangles) then begin
                AssembleTriangle(Cols, Rows, Grid, CtrlFace);
                if (Cols > 0) and (Rows > 0) then
                  ProcessGrid(Cols, Rows, Grid, ColorIndex, Ctrlface.Layer.Symmetric);
              end else begin
                Cols:=2;
                Rows:=2;
                Setlength(Grid, 2);
                Setlength(Grid[0], 2);
                Setlength(Grid[1], 2);
                for J:=1 to CtrlFace.ChildCount do
                begin
                  Face:=CtrlFace.Child[J-1];
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
      end else
        for I:=1 to FreeShip.Surface.NumberOfControlFaces do begin
          CtrlFace:=FreeShip.Surface.ControlFace[I-1];
          if Layers.IndexOf(Ctrlface.Layer) <> -1
          then ColorIndex:=ColorIndices[Layers.IndexOf(Ctrlface.Layer)]
          else Colorindex:=0;
          if CtrlFace.NumberOfpoints = 4 then begin
            FaceData.NCols:=1;
            FaceData.NRows:=1;
            Setlength(FaceData.Faces, 1);
            Setlength(FaceData.Faces[0], 1);
            FaceData.Faces[0][0]:=Ctrlface;
            FreeShip.Surface.ConvertToGrid(FaceData, Cols, Rows, Grid);
            ProcessGrid(Cols, Rows, Grid, ColorIndex, Ctrlface.Layer.Symmetric);
          end else begin
            Cols:=2;
            Rows:=2;
            Setlength(Grid, 2);
            Setlength(Grid[0], 2);
            Setlength(Grid[1], 2);
            for J:=1 to CtrlFace.ChildCount do begin
              Face:=CtrlFace.Child[J-1];
              Grid[0][1]:=Face.Point[0];
              Grid[0][0]:=Face.Point[1];
              Grid[1][0]:=Face.Point[2];
              Grid[1][1]:=Face.Point[3];
              ProcessGrid(Cols, Rows, Grid, ColorIndex, Ctrlface.Layer.Symmetric);
            end;
          end;
        end;
      if NSurfaces > 0 then begin
        IGESList.SaveToFile( ChangeFileExt(Dialog.Filename,'.igs') );
        MessageDlg('Exported '+IntToStr(NSurfaces)+' surfaces.',mtInformation,[mbOK],0);
      end else MessageDlg(Userstring(100), mtInformation, [mbOK], 0);
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
// temporarily switch to metric units for michlet export
  if FreeShip.ProjectSettings.ProjectUnits = fuImperial then begin
    UndoObject:=CreateUndoObject(Userstring(101), False);
    FreeShip.ProjectSettings.ProjectUnits:=fuMetric;
  end else UndoObject:=nil;
//try
    if not FreeShip.ProjectSettings.DisableModelCheck then Model_Check(False);
    Dialog:=TFreeMichletOutputDialog.Create(FreeShip);
    ShowTranslatedValues(Dialog);                                       // Hull
    Dialog.NumberOfStations:=31;
    Dialog.NumberOfWaterlines:=21;
    Dialog.Draft:=FreeShip.ProjectSettings.ProjectDraft;
    Dialog.Length:=FreeShip.ProjectSettings.ProjectLength;        // Resistance
    Dialog.StartSpeed:=1;
    Dialog.EndSpeed:=5;
    Dialog.NumberOfSpeeds:=50;                                   // Environment
    Dialog.G:=9.80665;
    Dialog.WaterDensity:=FreeShip.ProjectSettings.ProjectWaterDensity;
    //      Dialog.WaterTemper:=FreeShip.ProjectSettings.ProjectWaterTemper;
    Dialog.WaterDepth:=10000;                                          // Waves
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
      SaveDialog.Filter:=createDialogFilter('Michlet input file',['mlt']);
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

