{
  Included in ShipUnit

  1 = © Aurora.Vsl-штормовой вычислительный эксперимент
  2 = WaveFront.Obj
  3 - Standard triangle.Stl
  4 - dxf - три варианта
  5 - iges
}
//        Export for Aurora-Hull stormy computational experiments (simulations)
//
procedure SEdit.File_Export_Aurora_Experiments;
var
  Str,Aft,Bow: String;
  Strings: TStringList;
  Min,Max: Vector;

  Procedure Str2( A,B: Real ); begin Str:=Str+'  '+FloatToDec(A,5)+' '+FloatToDec(B,5); end;
  Procedure StemStern; //( Dir:boolean );// Dir = 1-форштевень, 0-ахтерштевень
    var I,K,M,Jn,Jx:Integer; Y,Zn,Zx:Real;
  begin K:=0; Bow:=' 0'; Aft:=' 0';
    if St.NoButtocks<1 then exit;// подстройка со сбросом в начало списка
    for I:=0 to St.NoButtocks-1 do     // поиск нулевого батокса
    with St.Buttock[I] do                    // if not Built then Rebuild;
    if I=0 then Y:=abs( Items[0].Point[0].Y ) else
    if Y>abs( Items[0].Point[0].Y ) then
       begin K:=I; Y:=abs( Items[0].Point[0].Y ) end; // K -> ближайший к ДП
//  if I<>K then begin W:=St.Buttock[0].FItems;
//                        St.Buttock[0].FItems:=St.Buttock[K].FItems;
//                        St.Buttock[K].FItems:=W end;
    with St.Buttock[K] do begin ReBuild; // Extents( Min,Max );
       JoinSplineSegments(0,True,FItems);  // слияние ДП-батокса в один контур
       with Items[0] do begin
          for I:=0 to Ns-1 do
          if I=0 then begin Zn:=Point[I].z; Zx:=Zn; Jn:=0; Jx:=0 end else begin
             if Zx<Point[I].z then begin Zx:=Point[I].z; Jx:=I end; // x - max
             if Zn>Point[I].z then begin Zn:=Point[I].z; Jn:=I end; // n - min
          end;
          if Point[Jn].x>Point[(Jn+1) mod Ns].x
             then begin Items[0].InvertDirection; Jn:=Ns-Jn-1; Jx:=Ns-Jx-1 end;
     //// ахтерштевень
          M:=Jn-Jx; if M<0 then M+=Ns; Str:=' '+InttoStr( M ); I:=Jn;
//        while I<>Jx do begin Str2(Point[I].Z,Point[I].X);
//              I:=(I+Ns-1) mod Ns; end;
          for I:=0 to M-1 do Str2(Point[(Jn+Ns-I) mod Ns].Z,Point[(Jn+Ns-I) mod Ns].X);
          Aft:=Str;
     //// форштевень
          M:=Jx-Jn+1; if M<0 then M+=Ns; Str:=' '+InttoStr( M ); I:=Jn;
//        repeat Str2(Point[I].Z,Point[I].X); I:=(I+1) mod Ns;
//        until I=Jx;  !!#= Jx+1
          for I:=0 to M-1 do Str2(Point[(I+Jn) mod Ns].Z,Point[(I+Jn) mod Ns].X);
          Bow:=Str;
       end;
    end;
  end;
var I,J,K,N: integer;
    Title,S: String; P0,PN: Vector; Dis: boolean;
    Dialog: TSaveDialog;
begin
     Title:=ExtractFilename( St.FileName ); Dis:=True;
     Dialog:=TSaveDialog.Create( St );
     Dialog.InitialDir:=St.Preferences.ExportDirectory;
     Dialog.FileName:=ChangeFileExt( Title,'.vsl');
     Dialog.Filter:='Aurora+Hull Vessel [*.vsl]|*.vsl';
     Dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
  if Dialog.Execute then begin
    WestPoint;
    St.Extents( Min,Max );
    St.Preferences.ExportDirectory:=Dialog.InitialDir;
    Strings:=TStringList.Create;
    with St.FProjectSettings do                              // RawByteString
    Strings.Add( '; !St'+EOL+';'
            +EOL+'; File Name: '+Title
            +EOL+'; Name     : '+ProjectName
            +EOL+'; Designer : '+ProjectDesigner
            +EOL+'; Create by: '+ProjectFileCreatedBy
            +EOL+'; Comment  : '+ProjectComment
            +EOL+';'                                     // уточнить где мидель
            +EOL+#30+' < '+ExtractFilename( Dialog.FileName )+' > '
            +EOL+InttoStr( St.NoStations )
            +' '+InttoStr( St.NoStations div 2 )
            +EOL+FloatToDec( FProjectLength,5)
            +' '+FloatToDec( FProjectBeam, 5)
            +' '+FloatToDec( FProjectDraft,5)
            +' '+FloatToDec( Min.z,5 )+EOL );
    StemStern;                             // первые две строки для ахтерштевня
    Strings.Add( Aft );
    Strings.Add( ' 0'+EOL );
    for I:=0 to St.NoStations-1 do
    with St.Station[I] do begin ReBuild;     // if not Built then Rebuild;
       JoinSplineSegments( 0,True,FItems );    // слияние сплайна в один контур
       N:=0;                 // под суммарное количество точек на всех отрезках
       if Count>0 then P0:=Items[0].Point[0] else exit; PN:=P0;
       for J:=0 to Count-1 do with Items[J] do
      {if Ns>1 then } begin N+=Ns;
          if J=0 then P0:=Point[0];
          if J=Count-1 then PN:=Point[Ns-1];
       end;                 // Z-положительно
//     Dis:=(P0.Z<PN.Z) { or (P0.Y<1e-6) } or (P0.Y<=PN.Y);
       Dis:=(P0.Z<PN.Z) or ((P0.Z=PN.Z) and (P0.Y<=PN.Y));
//     Title:=format( '%3d %-4.4g',[N,Items[0].Point[0].X] ); S:='';
       Title:=' '+InttoStr( N )+' '+FloattoDec( Items[0].Point[0].X,5 ); S:='';
       for J:=0 to Count-1 do with Items[J] do
      {if nS>1 then } begin
          N:=nS-1; Str:='';             // ещё и сортировки только и не хватало
          if Point[N].Z>=Point[0].Z                  // == может быть на палубе
             then begin for K:=0 to N do with Point[K] do Str2( Z,Y ); end
             else begin for K:=N downto 0 do with Point[K] do Str2( Z,Y ); end;
          if J=0 then S:=Str else begin if Dis then S:=S+Str else S:=Str+S; end;
       end;
       Strings.Add( Title+S+'  ←'+inttostr(Count)+'→' );
    end;
    Strings.Add( EOL+' 0' );          // форштевень в завершение и в заключение
    Strings.Add( Bow );
    with St.FProjectSettings do
    Strings.Add( EOL+' Длина:  '+FloattoDec( Min.X,3 )
                          +' ÷ '+FloattoDec( Max.X,3 )
                         +' ≈≥ '+FloattoDec( FProjectLength,3 )
                +EOL+' Ширина: '+FloattoDec( Min.Y,3 )
                          +' ÷ '+FloattoDec( Max.Y,3 )
                         +' ≈≥ '+FloattoDec( FProjectBeam,3 )
                +EOL+' Высота: '+FloattoDec( Min.Z,3 )
                          +' ÷ '+FloattoDec( Max.Z,3 )
                         +' ≈≥ '+FloattoDec( FProjectDraft,3 )+EOL );
    //                             ...и всё-таки батокс следует прописать особо
    if St.NoButtocks>0 then begin
      Strings.Add(' Батокс из ['+IntToStr(St.NoButtocks)+'] у ДП <CenterLine>');
      for I:=0 to St.NoButtocks-1 do       // поиск нулевого батокса
      with St.Buttock[I] do begin Str:='';      // if not Built then Rebuild;
         if Count>0 then                  // батокс для диаметрильной плоскости
         for J:=0 to Count-1 do
         if abs(Items[J].Point[0].Y)<1e-4 then begin  // достаточно приближёных
            N:=Items[J].nS;
            Str:=' '+InttoStr( N )+' ('+FloatToDec(Items[J].Point[0].Y,5)+') ';
            if Count>1 then Str:=Str+'  ←'+inttostr(J+1)+'→ '; // разбой кривой
            for K:=0 to N-1 do with Items[J].Point[K] do Str2( Z,X );
            Strings.Add( Str );
         end;
      end;
    end;
    Strings.SaveToFile( ChangeFileExt( Dialog.FileName,'.vsl' ) );
    Strings.Destroy;   // writeln( Dialog.InitialDir+' -=> '+Dialog.filename );
  end;
  Dialog.Destroy;
end;
//
// STL (stereolithography) - список треугольных граней, и их нормалей.
//
procedure SEdit.File_ImportSTL;
var
  OpenDialog: TOpenDialog;    Answer: Word;
  FileName,Str: String;   PrevCursor: TCursor;
  FFile: TextFile;
begin
  OpenDialog:=TOpenDialog.Create(St);
  OpenDialog.InitialDir:=St.Preferences.ImportDirectory;
  OpenDialog.Filter:='StereoLitography STL [*.stl]|*.stl';
  if OpenDialog.Execute then begin
    Answer:=St.Edit.File_SaveCheck;
    if (Answer=mrCancel) or St.FileChanged
       then begin OpenDialog.Destroy; exit; end;
    CreateUndoObject('STL file',True);
    PrevCursor:=Screen.Cursor;
    Screen.Cursor:=crHourglass;
    St.Clear;
    FileName:=ChangeFileExt( OpenDialog.FileName,'.stl' );
    AssignFile( FFile,FileName ); Reset( FFile );
    if IOResult=0 then begin
      if not EOF(FFile) then begin
        Readln( FFile,Str ); Str:=Str.Trim.ToLower; CloseFile( FFile );
        if Str.StartsWith( 'solid ' )
           then File_ImportSTLtext( FileName )
           else File_ImportSTLbin( FileName );
      end;
//    CloseFile( FFile );
      St.FileName:=ChangeFileExt( Opendialog.FileName,'' );
//    St.ModelIsLoaded:=True;
      St.FileChanged:=True;
      St.RebuildModel;
      St.Redraw;
    end else ShowMessage( UserString(97) );
    Screen.Cursor:=PrevCursor;
  end;
  FreeAndNil(OpenDialog);
end;

procedure SEdit.File_ImportSTLtext( FileName: String );
var
  FFile: TextFile;
  Str: String; idSolid:boolean;
  LineNr,SolidNr,FacetNr,VertexNr:Integer; V:Vector;
  Layer: SLayer;
  FacePoints: TFasterList; //SControlPoint;
  CtrPoint: SControlPoint;
  SubdivisionSurface: SSurface;
//  Tokens: array of string;
begin
    St.ProjectSettings.FProjectName:=ExtractFileName( FileName );
    AssignFile( FFile,FileName ); Reset( FFile);
    if IOResult=0 then begin
      SubdivisionSurface:=St.Surface;
//    SubdivisionSurface.IsLoading:=true;
      FacePoints:=TFasterList.Create; // SControlPoint.Create;
      LineNr:=1; SolidNr:=0; FacetNr:=0; VertexNr:=0;
      while not EOF(FFile) do begin
        Readln( FFile,Str );                     // if EOF( FFile ) then break;
        idSolid:=copy( Str,1,6 ).ToLower.StartsWith( 'solid ' );
        if not idSolid then Str:=BlankOff( Str ); Inc( LineNr );
        if idSolid then begin                     inc( SolidNr );
          if SolidNr=1
             then Layer:=SubdivisionSurface.Layer[0]
             else Layer:=SubdivisionSurface.AddNewLayer;
          if Length( Str )>7 then Layer.Name:=copy( Str,7,Length(Str)-6 )       // Str.SubString( 7,256 )
                             else Layer.Name:='Layer '+inttostr( SolidNr );
        end else
        if Str.StartsWith('facet ') then begin inc(FacetNr);    // read Normal?
          VertexNr:=1; FacePoints.Clear;
        end else
        if Str.StartsWith('outer loop') then else
        if Str.StartsWith('vertex ') then begin Str:=copy( Str,7,Length(Str)-6 ); // Str.SubString(7,Length(Str)-6);
          V:=GetVector( Str );
          CtrPoint:=SubdivisionSurface.AddControlPoint( V );
          if FacePoints.IndexOf( CtrPoint )=-1 then begin
             FacePoints.Add( CtrPoint );
             inc( VertexNr );
          end;
        end else
        if Str.StartsWith('endloop') then else                      // break;
        if Str.StartsWith('endfacet') then begin
          if FacePoints.Count>2 then
             SubdivisionSurface.AddControlFace( FacePoints,True,Layer );
        end else
        if Str.StartsWith('endsolid') then begin end;               // break;
      end;
      FreeAndNil(FacePoints);
      CloseFile(FFile);
//    SubdivisionSurface.IsLoading:=false;
    end else ShowMessage( UserString(97) );
end;

procedure SEdit.File_ImportSTLbin(FileName: String);
var
  FileStream: TFileStream;
  STLheader: array[0..79] of char;
  STLfacets: uint32;
  STLrecord: packed record
      normalX,  normalY,  normalZ,
    vertex1_X,vertex1_Y,vertex1_Z,       // для Зумвальта,т.к.
    vertex2_X,vertex2_Y,vertex2_Z,       // другого файла проверки
    vertex3_X,vertex3_Y,vertex3_Z: Real; // тогда не находилось
    unused: uint16;
  end;
  Str: String; SolidNr,FacetNr: Integer; r: longint; V: Vector;
  Layer: SLayer;
  FacePoints: TFasterList; //SControlPoint;
  CtrPoint: SControlPoint;
  SubdivisionSurface: SSurface;    //  Precision: double=1e-8;
begin
    St.ProjectSettings.FProjectName:=ExtractFileName( FileName );
    FileStream:=TFileStream.Create( FileName,fmOpenRead );
    if FileStream.Size>80 then begin
//    try
      SubdivisionSurface:=St.Surface;
//    SubdivisionSurface.IsLoading:=true;
      FacePoints:=TFasterList.Create; //SControlPoint.Create;
      SolidNr:=0; FacetNr:=1;
      r:=FileStream.Read( STLheader,80 );
      Str:=trim( String.Create( STLheader ) );                inc( SolidNr );
      if Str='' then Str:='STL layer '+InttoStr( Layer.Count );
      if SolidNr=1 then Layer:=SubdivisionSurface.Layer[0]
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
      FileStream.Free;
//    SubdivisionSurface.IsLoading:=false;
    end else ShowMessage( UserString(97) );
end;
{
  © Import the files are always UTF8
}
procedure SEdit.File_ImportObj;
var
  OpenDialog: TOpenDialog; Answer: Word;
  PrevCursor: TCursor;
  Strings: TStringList;
begin
   OpenDialog:=TOpenDialog.Create( St );
   OpenDialog.InitialDir:=St.Preferences.ImportDirectory;  //+ConfigDirectory
   OpenDialog.Filter:='WaveFront Technology [*.obj]|*.obj';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=St.Edit.File_SaveCheck;
      if (Answer=mrCancel) or St.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      CreateUndoObject('OBJ file',True);
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      St.Clear;
      Strings:=TStringList.Create;
      Strings.LoadFromFile( ChangeFileExt( OpenDialog.FileName,'.obj' ) );
      St.Surface.ImportObjFile( Strings );       // St.ModelIsLoaded:=True;
      St.FileName:=ChangeFileExt( Opendialog.FileName,'' );
      St.RebuildModel;
      St.FileChanged:=True;
      St.Redraw;
      FreeAndNil(Strings);
      if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
      Screen.Cursor:=PrevCursor;
  end;
  FreeAndNil( OpenDialog );
end;

procedure SEdit.File_ExportObj;
var SaveDialog : TSaveDialog;
    Strings    : TStringlist;
begin
   SaveDialog:=TSaveDialog.Create(St);
   SaveDialog.InitialDir:=St.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(St.FileName),'.obj');
   SaveDialog.Filter:='Wavefront file [*.Obj]|*.Obj|Controlnet to wavefront file [*.obj]|*.obj';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      St.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      Strings:=TStringlist.Create;
      St.Surface.ExportObjFile(SaveDialog.FilterIndex=2,Strings);
      Strings.SaveToFile(ChangeFileExt(Savedialog.FileName,'.obj'));
      Strings.Destroy;
   end;
   SaveDialog.Destroy;
end;
{
    Loads a bodyplane and tries to fit a surface to it
}
procedure SEdit.ImportFrames;
type TMinMax = record MinZ,MaxZ:Real; end;
// Assumptions:
//    1. All stations have multiplicity of 1
//    2. All stations are defined from bottom to top
var OpenDialog    : TOpenDialog;
    I,J,K,{Nr,} Index,NoStations,NoPoints: integer;
    Frames,Points: TFasterList;
    FFile: TextFile;
    Spline,NewSpline: TSpline;
    P: Vector;
    ValidStation:Boolean;
    MinMaxData: array of TMinMax;
    MinZ,MaxZ: Real;
    ControlPoints: array of array of SControlPoint;
    P1,P2: SControlPoint;
    Edge: SControlEdge;
    Face: SControlFace;
    Marker: TMarker;
begin
   OpenDialog:=TOpenDialog.Create(St);
   OpenDialog.InitialDir:=ExtractFilepath(Application.ExeName);
   OpenDialog.Filter:='3D text file [*.Txt]|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Frames:=TFasterList.Create;
//    Case OpenDialog.FilterIndex of
//       1 :begin   // 3D textfile containing stations, waterlines and buttocks
      if OpenDialog.FilterIndex=1 then begin
         AssignFile(FFile,Opendialog.FileName);
         {$I-}Reset(FFile);{$I+}
         if IOResult=0 then begin K:=0;        // Nr:=1;
            Readln(FFile,NoStations);
            for I:=1 to NoStations do begin    // inc(Nr);
               readln(FFile);                  // Skip description of this line
               readln(FFile,NoPoints);         // inc(Nr);
               Spline:=TSpline.Create;
               Spline.Capacity:=NoPoints;
               ValidStation:=NoPoints>1;
               for J:=1 to Nopoints do begin   // inc(Nr);
                  Read(FFile,P.X,P.Y,P.Z);
                  if not EOLN(FFile) then Readln(FFile,K)
                                     else begin K:=0; Readln(FFile); end;
                  Spline.Add(P);
            //#?? if J>1 then ValidStation:=abs( P.X-Spline.Point[0].X )<1e-4;
                  if (K=1) and (J<>1) and (J<>NoPoints) then Spline.Knuckle[J-1]:=True;
               end;
               if ValidStation then Frames.Add(Spline)
                               else Spline.Destroy;
            end; CloseFile(FFile);
         end; // else ShowMessage(Userstring(132));
      end;
      if Frames.Count>1 then begin
         St.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         CreateUndoObject(Userstring(133),True);
         St.Clear;
         St.Filename:=Opendialog.FileName;
         MinZ:=0.0;
         MaxZ:=0.0;                // first sort the stations from aft to front
         for I:=1 to Frames.Count-1 do
            for J:=I+1 to Frames.count
              do if TSpline(Frames[J-1]).Point[0].X<TSpline(Frames[I-1]).Point[0].X then Frames.Exchange(I-1,J-1);
         // Determine the minimum and maximum Z values for each station
         // and the overall min/max z-coordinate
         Setlength(MinMaxData,Frames.Count);
         for I:=1 to Frames.Count do begin
            Spline:=Frames[I-1];
            MinMaxData[I-1].MinZ:=Spline.Point[0].Z;
            MinMaxData[I-1].MaxZ:=Spline.Point[Spline.nS-1].Z;
            if I=1 then begin
               MinZ:=Spline.Point[0].Z;
               MaxZ:=MinZ;
            end;
            if Spline.Point[0].Z<MinZ then MinZ:=Spline.Point[0].Z;
            if Spline.Point[Spline.nS-1].Z>MaxZ then MaxZ:=Spline.Point[Spline.nS-1].Z;
            Marker:=TMarker.Create;
            Marker_Add(Marker);
            Marker.Capacity:=Spline.nS;
            for J:=1 to Spline.nS do begin
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
            if Spline.Point[Spline.nS-1].Z<MaxZ then begin
               P:=Spline.Point[Spline.nS-1];
               P.Z:=MaxZ;
               Spline.Add(P);
               Spline.Knuckle[Spline.nS-2]:=True;
            end;
         end;
         NoPoints:=10; // resample all stations to a user defined number of points
         NoPoints:=StrToInt(InputBox('',Userstring(135)+':',IntToStr(NoPoints)));
         if NoPoints<5 then NoPoints:=5;
         Setlength(ControlPoints,Frames.Count);
         for I:=1 to Frames.Count do begin
            Spline:=Frames[I-1];
            NewSpline:=TSpline.Create;
            NewSpline.Capacity:=NoPoints;
            for J:=1 to NoPoints do begin
               P:=Spline.Value((J-1)/(NoPoints-1));
               NewSpline.Add(P);
            end;                           // correct for any present knuckles
            for J:=1 to Spline.nS do if Spline.Knuckle[J-1] then begin
               Index:=0;          // find the nearest point on resampled spline
               for K:=2 to NewSpline.nS-1 do
               if Sqr( Spline.Point[J-1]-NewSpline.Point[K-1] )<Sqr( Spline.Point[J-1]-NewSpline.Point[index] )
                 then Index:=K-1;              // replace by the old coordinate
               NewSpline.Point[index]:=Spline.Point[J-1];
               NewSpline.Knuckle[index]:=True;
            end;                                 // Delete the old station and
            Spline.Destroy;                     // replace by the resampled one
            Frames[I-1]:=NewSpline; // Add the controlpoints to the subdivision surface
            Setlength(ControlPoints[I-1],NewSpline.nS);
            for J:=1 to NewSpline.nS
             do ControlPoints[I-1][J-1]:=St.Surface.AddControlPoint(NewSpline.Point[J-1]);
         end;                                       // Add the new controlfaces
         Points:=TfasterList.Create;
         For I:=2 to Frames.Count do begin
            for J:=2 to NoPoints do begin
               Points.Clear;
               Points.Add(ControlPoints[I-1][J-1]);
               Points.Add(ControlPoints[I-1][J-2]);
               Points.Add(ControlPoints[I-2][J-2]);
               Points.Add(ControlPoints[I-2][J-1]);
               St.Surface.AddControlFace(Points,True);
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
               Edge:=St.Surface.EdgeExists(P1,P2) as SControlEdge;
               if Edge<>nil then Edge.Crease:=True else begin
                            // Find out if P1 and P2 share the same controlface
                  for J:=1 to P1.NoFaces do
                  if P2.IndexOfFace(P1.Face[J-1])<>-1 then begin
                     Face:=P1.Face[J-1] as SControlFace;
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
               Edge:=St.Surface.EdgeExists(P1,P2) as SControlEdge;
               if Edge<>nil then Edge.Crease:=True
               else begin   // Find out if P1 and P2 share the same controlface
                  for J:=1 to P1.NoFaces
                  do if P2.IndexOfFace(P1.Face[J-1])<>-1 then begin
                     Face:=P1.Face[J-1] as SControlFace;
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
            if St.Surface.PointExists(P1) then P1.SelDeletePoint;
         end;
         for I:=1 to St.Surface.NoControlPoints do
           if St.Surface.ControlPoint[I-1].NoFaces=1 then
              St.Surface.ControlPoint[I-1].VertexType:=svCorner;
         Points.Destroy;
         St.FileChanged:=True;
      end;
      St.Draw;                                  // Destroy allocated stations
      if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
      for I:=1 to Frames.Count do begin
         Spline:=Frames[I-1];
         Spline.Destroy;
      end;
      Frames.Destroy;
   end;
   OpenDialog.Destroy;
end;

// Imports a number of curves and fits a surface - Поверхность

procedure SEdit.File_ImportSurface;
var OpenDialog: TOpenDialog;
    I,J,{Nr,}Cols,Rows: integer;
    Str: string;
    FFile: TextFile;
    Spline,NewSpline: TSpline;
    P: Vector;
    Points: array of VectorArray;
    ControlPoints: array of array of SControlPoint;
    P1: SControlPoint;
    Curves,LongCurves,Pts: TfasterList;
    Matrix,ColMatrix,RowMatrix,OrgPts,NewPts: TMatrix;
    UnitType: TUnitType;
    Marker: TMarker;
    PrevCursor: TCursor;
begin
   OpenDialog:=TOpenDialog.Create(St);
   OpenDialog.InitialDir:=St.Preferences.ImportDirectory;
   OpenDialog.Filter:='3D text file [*.Txt]|*.txt';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      UnitType:=TUnitType(0);
      Curves:=TFasterList.Create;
      if OpenDialog.FilterIndex=1 then begin // 3D textfile containing a number
         AssignFile(FFile,Opendialog.FileName); // of curves to be interpolated
         {$I-}Reset(FFile);{$I+}
         if IOResult=0 then begin
//          Nr:=0;
//          try
            readln(FFile,I); // first read unit information; 0=metric, 1=imperial
            if I in [0,1] then UnitType:=TUnitType(I)
                           else ShowMessage(Userstring(108));
            Spline:=TSpline.Create;
            repeat
               Readln(FFile,Str);
               repeat I:=Pos(#9,Str); if I<>0 then str[I]:=#32; until I=0;
//             inc(Nr);
               Str:=Trim(Uppercase(Str));
               if (Str<>'') and (Str<>'EOF') then begin
                  Spline.Add( GetVector( Str ) );
               end else if Str='' then begin
                  if Spline.nS>1 then Curves.Add(Spline)
                                             else Spline.Destroy;
                  Spline:=TSpline.Create;
               end;
            until (Str='EOF') or (EOF(FFile));
            if Spline.nS>1 then Curves.Add(Spline)
                                       else Spline.Destroy;
//          except
//            ShowMessage(Userstring(132)+#32+IntToStr(Nr));
//          end;
            CloseFile(FFile);
         end; // else ShowMessage(Userstring(132));
      end;
      if Curves.Count>1 then begin
         PrevCursor:=Screen.Cursor;
         St.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         CreateUndoObject(Userstring(136),True);
         St.Clear;
         St.ProjectSettings.ProjectUnits:=UnitType;
         St.Filename:=Opendialog.FileName;
//      try
         Cols:=Curves.Count;
         Cols:=StrToInt(InputBox('',Userstring(137)+':',IntToStr(Cols)));
         if Cols<3 then Cols:=3;
         Rows:=10;
         Rows:=StrToInt(InputBox('',Userstring(138)+':',IntToStr(Rows)));
         if Rows<3 then Rows:=3; // Build number of desired longitudinal curves
         LongCurves:=TFasterList.Create;
         for I:=1 to Rows do begin
            NewSpline:=TSpline.Create;
            LongCurves.Add(NewSpline);
            Newspline.Capacity:=Curves.Count;
            for J:=1 to Curves.Count do begin
               Spline:=Curves[J-1];
               Newspline.Add(Spline.Value((I-1)/(Rows-1)));
            end;
         end;
         for I:=1 to Curves.Count do begin
            Spline:=Curves[I-1];
            Marker:=TMarker.Create;
            Marker.Capacity:=Spline.nS;
            for J:=1 to Spline.nS do Marker.Add(Spline.Point[J-1]);
            Marker_Add(Marker);
            Spline.Destroy;
         end;
         Curves.Destroy;            // build matrix for column interpolation
         Matrix:=TMatrix.Create;
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
            OrgPts:=TMatrix.Create;
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
         for I:=1 to Cols do begin                       // interpolate rows
            OrgPts:=TMatrix.Create;
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
         for I:=1 to LongCurves.Count do begin        // delete long. curves
            Spline:=LongCurves[I-1];
            Spline.Destroy;
         end;
         LongCurves.Destroy;
         Setlength(ControlPoints,Rows);             // import actual surface
         for I:=1 to Rows do begin
            Setlength(ControlPoints[I-1],Cols);
            for J:=1 to Cols do begin
               ControlPoints[I-1][J-1]:=SControlPoint.Create(St.Surface);
               St.Surface.AddControlPoint(ControlPoints[I-1][J-1]);
               ControlPoints[I-1][J-1].Coordinate:=Points[I-1][J-1];
             //ControlPoints[I-1][J-1]:=Ship.Surface.AddControlPoint(Points[I-1][J-1]);
            end;
         end;
         Pts:=TFasterList.Create;
         for I:=2 to Rows do
         for J:=2 to Cols do begin
            Pts.Clear;
            P1:=ControlPoints[I-2][J-2]; Pts.Add(P1);
            P1:=ControlPoints[I-2][J-1]; if Pts.IndexOf(P1)=-1 then Pts.Add(P1);
            P1:=ControlPoints[I-1][J-1]; if Pts.IndexOf(P1)=-1 then Pts.Add(P1);
            P1:=ControlPoints[I-1][J-2]; if Pts.IndexOf(P1)=-1 then Pts.Add(P1);
            if Pts.Count>2 then St.Surface.AddControlFace(Pts,True);
         end;
         Pts.Destroy;
         St.FileChanged:=True;
//      finally
         if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
         Screen.Cursor:=PrevCursor;
//      end;
      end;
      St.Build:=False;
      St.Precision:=fpMedium;
      St.Draw;
   end;
   OpenDialog.Destroy;
end;

procedure SEdit.File_ExportArchimedes;
var Frames     : TFasterList;
    Frame      : TSpline;
    Tmp,Str    : string;
    I,J,Np     : integer;
    P          : Vector;
    SaveDialog : TSaveDialog;
    ffile      : textfile;
    Strings    : TStringList;
begin
   Frames:=TFasterList.Create;
   St.FBuildValidFrameTable(Frames,True);
   if Frames.Count>0 then begin
      SaveDialog:=TSaveDialog.Create(St);
      SaveDialog.InitialDir:=St.Preferences.ExportDirectory;
      SaveDialog.FileName:=ChangeFileExt(ExtractFilename(St.FileName),'');
      SaveDialog.Filter:='ArchimedesMB multi body hull data[*.hll]|*.hll|Archimedes single body hull data[*.app]|*.app';
      SaveDialog.FilterIndex:=1;
      Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
      if SaveDialog.Execute then begin
         St.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
         if SaveDialog.FilterIndex=2 then begin       // Single body Archimedes
            assignfile(ffile,ChangeFileExt(SaveDialog.FileName,'.app'));
            rewrite(FFile);
            Write(FFile,'** Appendage Hydrostatics Generator Version 1.0.1'+#10);
            Write(FFile,'** Copyright : John A.MacSween-2000'+#10);
            Write(FFile,'** www.naval-architecture.co.uk'+#10);
            Write(FFile,'** File generated with !St'+#10);
            Write(FFile,'APPENDAGE_NAME'+#10);                     // Hull name
            if St.ProjectSettings.ProjectName<>''
               then Tmp:=St.ProjectSettings.ProjectName
               else Tmp:=ChangeFileExt(ExtractFilename(St.Filename),'');
            Write(FFile,Tmp+#10);                          // Aft perpendicular
            Write(FFile,'AP'+#10);
            Write(FFile,'0.0'+#10);                    // Forward perpendicular
            Write(FFile,'FP'+#10);
            Write(FFile,FloatToDec(St.ProjectSettings.ProjectLength,4)+#10);
            Write(FFile,'DENSITY'+#10);                        // Water density
            write(FFile,FloatToDec(St.ProjectSettings.ProjectWaterDensity,3)+#10);
            Write(FFile,'NUMBER_OF_FRAMES'+#10);         // Now send the frames
            write(FFile,IntToStr(Frames.Count)+#10);
            Write(FFile,'***START_OF_FRAME_INFORMATION***'+#10);
            for I:=1 to Frames.Count do begin
               Frame:=Frames[I-1];
               Np:=Frame.nS;
               Write(FFile,'FRAME_INDEX: '+IntToStr(I-1)+#10);
               Write(FFile,'FRAME_NAME'+#10);
               Write(FFile,'Frame @ Y= '+FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4)+#10);
               Write(FFile,'FRAME_Y'+#10);
               Write(FFile,FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4)+#10);
               Write(FFile,'NUMBER_OF_COORDINATES'+#10);
               write(FFile,IntToStr(2*Np-1)+#10);
               Write(FFile,'***START_OF_ORDINATES***'+#10);
               // First send the starboard side
               for J:=Np downto 1 do begin      //P:=Frame.Value((J-1)/(Np-1));
                  P:=Frame.Point[J-1];
                  P.Y:=-P.Y;
                  Write(FFile,FloatToDec(P.Y,4)+#10);
                  Write(FFile,FloatToDec(P.Z,4)+#10);
               end;
               // then port side
               for J:=2 to Np do begin          //P:=Frame.Value((J-1)/(Np-1));
                  P:=Frame.Point[J-1];
                  Write(FFile,FloatToDec(P.Y,4)+#10);
                  Write(FFile,FloatToDec(P.Z,4)+#10);
               end;
               Write(FFile,'***END_OF_ORDINATES***'+#10);
               Frame.Destroy;
            end;
            Write(FFile,'***END_OF_FILE***'+#10);
            closefile(FFile);
         end else begin
            Strings:=TStringList.Create;             // Multi body ArchimedesMB
            Strings.Add(' <?xml version="1.0" encoding="UTF-8" ?>'); // Add file version info
            Strings.Add('<HULL>');                                // Start hull
            Strings.Add('<HULL_NAME>');                            // Hull name
            if St.ProjectSettings.ProjectName<>''
               then Str:=St.ProjectSettings.ProjectName
               else Str:=ChangeFileExt(ExtractFilename(St.Filename),'');
            Strings.Add(Str);
            Strings.Add('</HULL_NAME>');
            // Water density
            Strings.Add('<DENSITY>'+#32+FloatToDec(St.ProjectSettings.ProjectWaterDensity,3)
                                   +#32+'</DENSITY>');
            // Aft perpendicular
            Strings.Add('<AP> 0.0 </AP>');
            // Forward perpendicular
            Strings.Add('<FP>'+#32+FloatToDec(St.ProjectSettings.ProjectLength,4)+#32+'</FP>');
            // Draught marks
            Strings.Add('<FWD_DRAUGHT_MARK>'+#32+FloatToDec(St.ProjectSettings.ProjectDraft,4)+#32+'</FWD_DRAUGHT_MARK>');
            Strings.Add('<MID_DRAUGHT_MARK>'+#32+FloatToDec(St.ProjectSettings.ProjectDraft,4)+#32+'</MID_DRAUGHT_MARK>');
            Strings.Add('<AFT_DRAUGHT_MARK>'+#32+FloatToDec(St.ProjectSettings.ProjectDraft,4)+#32+'</AFT_DRAUGHT_MARK>');
            // Number of appendages (only 1, the main hull)
            Strings.Add('<APPENDAGE_COUNT> 1 </APPENDAGE_COUNT>');
            Strings.Add('<APPENDAGE>');
            Strings.Add('<APPENDAGE_NAME>');
            Strings.Add('Main Hull');
            Strings.Add('</APPENDAGE_NAME>');
            // Some constants
            Strings.Add('<ACTIVE> 1 </ACTIVE>');
            Strings.Add('<_FLOODING> 0 </_FLOODING>');
            Strings.Add('<APPENDAGE_COLOUR> 0 </APPENDAGE_COLOUR>');
            // Now send the frames
            Strings.Add('<SECTION_COUNT>'+#32+IntToStr(Frames.Count)+#32+'</SECTION_COUNT>');
            for I:=1 to Frames.Count do begin
               Frame:=Frames[I-1];
               Np:=2*Frame.nS+1;
               Strings.Add('<SECTION>');
               Strings.Add('<SECTION_NAME>');
               Strings.Add(FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4));
               Strings.Add('</SECTION_NAME>');
               Strings.Add('<YCOORD>'+#32+FloatToStrF(0.5*(Frame.Min.X+Frame.Max.X),ffFixed,7,4)+#32+'</YCOORD>');
               Strings.Add('<OFFSET_COUNT>'+#32+IntToStr(2*Np-1)+#32+'</OFFSET_COUNT>');
               Strings.Add('<OFFSETS>');
               for J:=Np downto 1 do begin     // First send the starboard side
                  P:=Frame.Value((J-1)/(Np-1));
                  P.Y:=-P.Y;
                  Strings.Add(FloatToDec(P.Y,4)+#32+FloatToDec(P.Z,4));
               end;
               for J:=2 to Np do begin                        // then port side
                  P:=Frame.Value((J-1)/(Np-1));
                  Strings.Add(FloatToDec(P.Y,4)+#32+FloatToDec(P.Z,4));
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
procedure SEdit.File_ExportCoordinates;
var I          : integer;
    Point      : SPoint;
    SaveDialog : TSaveDialog;
    ffile      : textfile;
begin
   SaveDialog:=TSaveDialog.Create(St);
   SaveDialog.InitialDir:=St.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(St.FileName),'');
   SaveDialog.Filter:='Text file [*.txt]|*.txt';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      Assignfile(FFile,ChangeFileExt(SaveDialog.FileName,'.txt'));
      {$I-}Rewrite(FFile);{$I+}
      if IOResult=0 then begin
         St.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
         {
         for I:=1 to St.Surface.NoControlPoints do begin
            Point:=St.Surface.ControlPoint[I-1];
            Writeln(FFile,MakeLength(Point.Coordinate.X,6,12),#32,
                          MakeLength(Point.Coordinate.Y,6,12),#32,
                          MakeLength(Point.Coordinate.Z,6,12));
         end;
         }
         for I:=1 to St.Surface.NoPoints do begin
            Point:=St.Surface.Point[I-1];
            Writeln( FFile,MakeLength(Point.Coordinate.X,5,12),#32,
                           MakeLength(Point.Coordinate.Y,5,12),#32,
                           MakeLength(Point.Coordinate.Z,5,12) );
         end;
         CloseFile(FFile);
      end else ShowMessage( Userstring(97) );
   end;
   SaveDialog.Destroy;
end;

procedure TIntersection.SaveToDXF( Strings:TStringList );
var I: integer; Layer: string; Spline: TSpline;
begin
   if not built then Rebuild;
   for I:=1 to count do begin
      Spline:=Items[I-1];
      Case IntersectionType of
         fiStation  : layer:='Stations';   // Userstring(62);
         fiButtock  : layer:='Buttocks';   // Userstring(63);
         fiWaterline: layer:='Waterlines'; // Userstring(64);
         fiDiagonal : layer:='Diagonals';  // Userstring(65);
                 else Layer:='Layer_X';
      end;
      case St.Precision of
         fpLow     : Spline.Fragments:=50;
         fpMedium  : Spline.Fragments:=100;
         fpHigh    : Spline.Fragments:=150;
         fpVeryHigh: Spline.Fragments:=500;
         else Spline.Fragments:=100;
      end;
      Spline.SaveToDXF(Strings,Layer,St.Visibility.ModelView=mvBoth);
   end;
end;

// Export all intersections to an individual DXF file as 2D polylines
procedure SEdit.File_ExportDXF_2DPolylines;
var I          : integer;
    Strings    : TStringList;
    Dialog     : TDXFExport2DDialog;
    ScaleFactor,SegLength: Real;
    PrevCursor : TCursor;
    Filename   : string;
    Intersections:TFasterList;

  procedure CreateDXFData(Intersection:TIntersection;Stringlist:TStringList;Scale:Real;var Filename:string);
   var I,N:Integer;
       Layername:string;
       procedure SaveSpline(Spline:TSpline;Strings:TStringList;IntersectionType:TIntersectiontype);
       var NParams,Cap,I,Ind: Integer;
           Length,T: Real;
           Params: RealArray;
           P1,P2: Vector;
       begin
          Ind:=FindDXFColorIndex(Spline.Color);
          NParams:=0;
          Setlength(Params,Spline.nS);
          if not Spline.Build then Spline.Rebuild; // count number
          for I:=2 to Spline.nS-1 do              // of knucklepoints
           if Spline.Knuckle[I-1] then begin
              Params[NParams]:=Spline.Parameter[I-1];
              inc(NParams);
          end;
          Length:=0.0;          // Calculate the length of the spline
          P1:=Spline.Value(0.0);
          for I:=1 to 150 do begin
             P2:=Spline.Value(I/150);
             Length:=Length+Abs(P1-P2);
             P1:=P2;
          end;
          Length:=Length*ScaleFactor;
          if length>0 then begin
             N:=Round(Length/(SegLength));
             if N<2*Spline.nS then N:=2*Spline.nS;
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
             ArraySort( Params,NParams );            // now export the actual
             Strings.Add('0'+EOL+'POLYLINE');        //     calculated points
             Strings.Add('8'+EOL+LayerName);                     // layername
             Strings.Add('62'+EOL+IntToStr(Ind));           // color by layer
             Strings.Add('66'+EOL+'1');                    // vertices follow
             for I:=1 to NParams do begin
                P1:=Spline.Value(Params[I-1]);
                Strings.Add('0'+EOL+'VERTEX');
                Strings.Add('8'+EOL+LayerName);
                Case IntersectionType of
                  fiStation: begin
                     Strings.Add('10'+EOL+FloatToDec(Scale*P1.Y,5));
                     Strings.Add('20'+EOL+FloatToDec(Scale*P1.Z,5)); end;
                  fiButtock: begin
                     Strings.Add('10'+EOL+FloatToDec(Scale*P1.X,5));
                     Strings.Add('20'+EOL+FloatToDec(Scale*P1.Z,5)); end;
                  fiWaterline: begin
                     Strings.Add('10'+EOL+FloatToDec(Scale*P1.X,5));
                     Strings.Add('20'+EOL+FloatToDec(Scale*P1.Y,5)); end;
               end;
             end;
             Strings.Add('0'+EOL+'SEQEND');
             if (Intersectiontype in [fiStation,fiWaterline])
             and (St.Visibility.ModelView=mvBoth) then begin
                Strings.Add('0'+EOL+'POLYLINE');      // send the other half
                Strings.Add('8'+EOL+LayerName);       // layername
                Strings.Add('62'+EOL+IntToStr(Ind));  // color by layer
                Strings.Add('66'+EOL+'1');            // vertices follow
                for I:=1 to NParams do begin
                   P1:=Spline.Value(Params[I-1]);
                   Strings.Add('0'+EOL+'VERTEX');
                   Strings.Add('8'+EOL+LayerName);
                   Case IntersectionType of
                      fiStation: begin
                        Strings.Add('10'+EOL+FloatToDec(Scale*-P1.Y,5));
                        Strings.Add('20'+EOL+FloatToDec(Scale*P1.Z,5)); end;
                      fiWaterline: begin
                        Strings.Add('10'+EOL+FloatToDec(Scale*P1.X,5));
                        Strings.Add('20'+EOL+FloatToDec(Scale*-P1.Y,5)); end;
                   end;
                end;    Strings.Add('0'+EOL+'SEQEND');
             end;
          end;
       end;
    begin
       if not Intersection.Built then Intersection.Rebuild;
       if intersection.Count>0 then begin
         Case Intersection.IntersectionType of
            fiStation  : Layername:='Stations';   {Userstring(62);}
            fiButtock  : Layername:='Buttocks';   {Userstring(63);}
            fiWaterline: Layername:='Waterlines'; {Userstring(64);}
            fiDiagonal : Layername:='Diagonals';  {Userstring(65);} else exit;
         // else begin ShowMessage( Userstring(66)+'!' ); exit; end;
         end;
         Filename:=St.Preferences.ExportDirectory+Intersection.Description+'.dxf';
         for I:=1 to Intersection.Count do begin
            Intersection.Items[I-1].Color:=Intersection.Color;
            SaveSpline(Intersection.Items[I-1],Strings,Intersection.IntersectionType);
         end;
       end;
    end;
begin
   Dialog:=TDXFExport2DDialog.Create(St);
   ShowTranslatedValues(Dialog);
   Dialog.ExportDirectory:=St.Preferences.ExportDirectory;
   If St.ProjectSettings.ProjectUnits=fuMetric then Dialog.ComboBox1.ItemIndex:=0 else
      If St.ProjectSettings.ProjectUnits=fuImperial then Dialog.ComboBox1.ItemIndex:=3;
   if Dialog.Execute then begin
      St.Preferences.ExportDirectory:=Dialog.ExportDirectory;
      if Length(St.Preferences.ExportDirectory)>0 then
      if St.Preferences.ExportDirectory[Length(St.Preferences.ExportDirectory)]<>'\'
      then St.Preferences.ExportDirectory:=St.Preferences.ExportDirectory+'\';
      ScaleFactor:=1.0;
      SegLength:=Dialog.SegmentLength;
      If St.ProjectSettings.ProjectUnits=fuMetric then begin
         Case Dialog.ComboBox1.ItemIndex of
            0 : ScaleFactor:=1.0;         // Scale from meters to meters
            1 : ScaleFactor:=100;         // Scale from meters to centimeters
            2 : ScaleFactor:=1000;        // Scale from meters to millimeters
            3 : ScaleFactor:=1/Foot;      // Scale from meters to feet
            4 : ScaleFactor:=12/Foot;     // Scale from meters to inches
         end;
      end else If St.ProjectSettings.ProjectUnits=fuImperial then begin
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
      if Dialog.CheckBox1.Checked then begin
      // send each intersection to an individual dxf file
         Intersections:=TFasterList.Create;
         if St.Visibility.ShowStations then Intersections.AddList(St.FStations);
         if St.Visibility.ShowButtocks then Intersections.AddList(St.FButtocks);
         if St.Visibility.ShowWaterlines then Intersections.AddList(St.FWaterlines);
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
         if (St.Visibility.ShowStations)
         and (St.NoStations>0) then begin
            Strings.Clear;
            Strings.Add('0'+EOL+'SECTION');
            Strings.Add('2'+EOL+'ENTITIES');
            for I:=1 to St.NoStations do CreateDXFData(St.Station[I-1],Strings,ScaleFactor,Filename);
            Strings.Add('0'+EOL+'ENDSEC');
            Strings.Add('0'+EOL+'EOF');
            Filename:=St.Preferences.ExportDirectory+'stations.dxf';
            Strings.SaveToFile(Filename);
         end;
         if (St.Visibility.ShowButtocks)
         and (St.NoButtocks>0) then begin
            Strings.Clear;
            Strings.Add('0'+EOL+'SECTION');
            Strings.Add('2'+EOL+'ENTITIES');
            for I:=1 to St.NoButtocks do CreateDXFData(St.Buttock[I-1],Strings,ScaleFactor,Filename);
            Strings.Add('0'+EOL+'ENDSEC');
            Strings.Add('0'+EOL+'EOF');
            Filename:=St.Preferences.ExportDirectory+'buttocks.dxf';
            Strings.SaveToFile(Filename);
         end;
         if (St.Visibility.ShowWaterlines)
         and (St.NoWaterlines>0) then begin
            Strings.Clear;
            Strings.Add('0'+EOL+'SECTION');
            Strings.Add('2'+EOL+'ENTITIES');
            for I:=1 to St.NoWaterlines do CreateDXFData(St.Waterline[I-1],Strings,ScaleFactor,Filename);
            Strings.Add('0'+EOL+'ENDSEC');
            Strings.Add('0'+EOL+'EOF');
            Filename:=St.Preferences.ExportDirectory+'waterlines.dxf';
            Strings.SaveToFile(Filename);
         end;
      end;
      Strings.Destroy;
      Screen.Cursor:=PrevCursor;
   end;
   Dialog.Destroy;
end;

// Export all lines to a 3D DXF model as polylines

procedure SEdit.File_ExportDXF_3DPolylines;
var I,J,ind: integer;
    Strings: TStringList;
    Dialog: TSaveDialog;
    Edges,Points: TFasterList;
    Point: SPoint;
    Layername:string;
begin
   Dialog:=TSaveDialog.Create(St);
   Dialog.InitialDir:=St.Preferences.ExportDirectory;
   Dialog.FileName:=ChangeFileExt(ExtractFilename(St.FileName),'.dxf');
   Dialog.Filter:='Autocad dxf file [*.dxf]|*.dxf';
   dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if Dialog.Execute then begin
      St.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
      Strings:=TStringList.Create;
      Strings.Add('0'+EOL+'SECTION');
      Strings.Add('2'+EOL+'ENTITIES');
      if St.Visibility.ShowStations then for I:=1 to St.NoStations do St.Station[I-1].SaveToDXF(Strings);
      if St.Visibility.ShowButtocks then for I:=1 to St.NoButtocks do St.Buttock[I-1].SaveToDXF(Strings);
      if St.Visibility.ShowWaterlines then for I:=1 to St.NoWaterlines do St.Waterline[I-1].SaveToDXF(Strings);
      if St.Visibility.ShowDiagonals then for I:=1 to St.NoDiagonals do St.Diagonal[I-1].SaveToDXF(Strings);
      if St.Visibility.ShowControlCurves then for I:=1 to St.NoControlCurves do St.ControlCurve[I-1].SaveToDXF(Strings);
      Edges:=TFasterList.Create;
      St.Surface.ExtractAllEdgeLoops(Edges);
      Layername:='Board Edges';
      ind:=FindDXFColorIndex(St.Preferences.EdgeColor);
      for I:=1 to Edges.Count do begin
         Points:=Edges[I-1];
         Strings.Add('0'+EOL+'POLYLINE');
         Strings.Add('8'+EOL+LayerName);      // layername
         Strings.Add('62'+EOL+IntToStr(Ind)); // color by layer
         Strings.Add('70'+EOL+'10');          // not closed
         Strings.Add('66'+EOL+'1');           // vertices follow
         for J:=1 to Points.Count do begin
            Point:=Points[J-1];
            Strings.Add('0'+EOL+'VERTEX');
            Strings.Add('8'+EOL+LayerName);
            Strings.Add('10'+EOL+FloatToDec(Point.Coordinate.X,4));
            Strings.Add('20'+EOL+FloatToDec(Point.Coordinate.z,4));
            Strings.Add('30'+EOL+FloatToDec(Point.Coordinate.y,4));
            Strings.Add('70'+EOL+'32'); // 3D polyline mesh vertex
         end;
         Strings.Add('0'+EOL+'SEQEND');
         if St.Visibility.ModelView=mvBoth then begin
            Strings.Add('0'+EOL+'POLYLINE');
            Strings.Add('8'+EOL+LayerName);      // layername
            Strings.Add('62'+EOL+IntToStr(Ind)); // color by layer
            Strings.Add('70'+EOL+'10');          // not closed
            Strings.Add('66'+EOL+'1');           // vertices follow
            for J:=1 to Points.Count do begin
               Point:=Points[J-1];
               Strings.Add('0'+EOL+'VERTEX');
               Strings.Add('8'+EOL+LayerName);
               Strings.Add('10'+EOL+FloatToDec(Point.Coordinate.X,4));
               Strings.Add('20'+EOL+FloatToDec(Point.Coordinate.z,4));
               Strings.Add('30'+EOL+FloatToDec(-Point.Coordinate.y,4));
               Strings.Add('70'+EOL+'32'); // 3D polyline mesh vertex
            end;
               Strings.Add('0'+EOL+'SEQEND');
         end;  Points.Destroy;
      end;
      Edges.Destroy;
      Strings.Add('0'+EOL+'ENDSEC');
      Strings.Add('0'+EOL+'EOF');
      Strings.SaveToFile(ChangeFileExt(Dialog.FileName,'.dxf'));
      Strings.Destroy;
   end;
   Dialog.Destroy;
end;

// Export all faces to a 3D DXF model
procedure SEdit.File_ExportDXF_Faces;
var I       : integer;
    Strings : TStringList;
    Dialog  : TSaveDialog;
    Prev    : TCursor;
begin
   Dialog:=TSaveDialog.Create(St);
   Dialog.InitialDir:=St.Preferences.ExportDirectory;
   Dialog.FileName:=ChangeFileExt(ExtractFilename(St.FileName),'.dxf');
   Dialog.Filter:='Autocad dxf file [*.dxf]|*.dxf';
   dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if Dialog.Execute then begin
      Prev:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      St.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
      Strings:=TStringList.Create;
      Strings.Add('0'+EOL+'SECTION');
      Strings.Add('2'+EOL+'ENTITIES');
      for I:=1 to St.Surface.NoLayers do St.Surface.Layer[I-1].SaveToDXF(Strings);
      Strings.Add('0'+EOL+'ENDSEC');
      Strings.Add('0'+EOL+'EOF');
      Strings.SaveToFile( ChangeFileExt(Dialog.FileName,'.dxf') );
      Screen.Cursor:=Prev;
      Strings.Destroy;
   end;
   Dialog.Destroy;
end;

// Save ordinates to the GHS file format

procedure SEdit.File_ExportGHS;
var I,J,NParams: integer;
    Section    : TSpline;
    SaveDialog : TSaveDialog;
    Strings    : TStringList;
    PrevCursor : TCursor;
    Scale      : Real;
    Frames     : TFasterList;
    Str        : string;
    P          : Vector;
    Params     : RealArray;
begin
   SaveDialog:=TSaveDialog.Create(St);
   SaveDialog.InitialDir:=St.Preferences.ExportDirectory;
   Str:=ChangeFileExt(ExtractFilename(St.Filename),'.GF');
   repeat
      I:=Pos(#32,Str);                         // no spaces allowed in filename
      if I<>0 then Delete(Str,I,1);
   until I=0;
   Savedialog.FileName:=Str;
   SaveDialog.Filter:='GHS files [*.Gf]|*.Gf';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if not SaveDialog.Execute then begin
      Savedialog.Destroy;
      exit;
   end;
   St.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   Strings:=TStringList.Create;
   Frames:=TFasterList.Create;
      St.FBuildValidFrameTable(Frames,True);
      if St.ProjectSettings.ProjectUnits=fuImperial then Scale:=1.0
                                                      else Scale:=1/Foot;
      Str:=St.ProjectSettings.ProjectName;
      if Length(Str)>58 then Str:=copy(Str,1,58);
      Strings.Add(Str);                                                                    // ProjectDescription, max 58 characters
      Strings.Add('L:'+FloatToStrF(Scale*St.ProjectSettings.ProjectLength,ffFixed,7,3)); // Length
      Strings.Add('W:'+FloatToStrF(Scale*St.ProjectSettings.ProjectBeam,ffFixed,7,3));   // Beam
      Strings.Add('OL:Frame 0');
      Strings.Add('OT:Centerplane');
      Strings.Add('OV:Baseline');                           // Units preference
      if St.ProjectSettings.ProjectUnits=fuMetric then Strings.Add('P:M')
                                                     else Strings.Add('P:F');
      // Add max. 10 comments
      Strings.Add('\Generated with !St');
//    Strings.Add('\www.ship.org');
      // Save shape
      Strings.Add('*');
      Strings.Add('HULL'); // shape name
      Strings.Add(IntToStr(Frames.Count)); // Number of sections
      for I:=Frames.Count downto 1 do begin
         Section:=Frames[I-1];
         if Section.nS>0 then begin
            if section.Point[Section.nS-1].Y>0 then begin
               Section.Knuckle[Section.nS-1]:=true;
               Section.Add(Section.Point[Section.nS-1]);
            end;
         end;
         NParams:=0;
         Setlength(Params,Section.nS); // count number of knucklepoints
         for J:=2 to Section.nS-1 do begin
            if Section.Knuckle[J-1] then begin
               Params[NParams]:=Section.Parameter[J-1];
               inc(NParams);
            end;
         end;
         if Section.nS>100 then begin
            Section.Fragments:=100;
            Setlength(Params,NParams+Section.Fragments);
            for J:=1 to Section.Fragments do begin
               Params[NParams]:=(J-1)/(Section.Fragments-1);
               inc(NParams);
            end;
         end else begin
            Setlength(Params,NParams+Section.nS);
            for J:=1 to Section.nS do begin
               Params[NParams]:=Section.Parameter[J-1];
               inc(NParams);
            end;
         end;
         ArraySort( Params,NParams );
         Strings.Add(FloatToDec(-Scale*Section.Min.X,4)+','+IntToStr(NParams));
         for J:=1 to NParams do begin
            P:=Section.Value(Params[J-1]);
            Strings.Add(FloatToDec(Scale*P.Y,4)+','+FloatToDec(Scale*P.Z,4));
         end;
         Section.Destroy;
      end;
      Strings.Add('0,0,0');      // shell thickness data of shape
      Strings.Add('**');         // save Component
      Strings.Add('HULL.C');     // ComponentName
      Strings.Add('0');          // side=center
      Strings.Add('1.0');        // effectivenes
      Strings.Add('0,0,0');      // attachpoint
      Strings.Add('HULL');       // partname
      Strings.Add('***');        // Save part
      Strings.Add('HULL');       // Partname and description
      Strings.Add('WATER');      // FluidName
      strings.Add('1');          // part type (displacement)
      if St.ProjectSettings.ProjectUnits=fuMetric
        then Strings.Add(FloatToStrF(St.ProjectSettings.ProjectWaterDensity,ffFixed,7,3)) // specific gravity of water
        else Strings.Add(FloatToStrF(St.ProjectSettings.ProjectWaterDensity/WeightConversionFactor,ffFixed,7,3));
      Strings.Add('0,0,0');      // ReferencePoint
      Strings.Add('1');          // Number of components
      Strings.Add('HULL.C');     // Componentname
      Strings.Add('****');       // Mark end of file
      Str:=ChangeFileExt(ExtractFilename(Savedialog.FileName),'.GF');
      repeat                     // no spaces allowed in filename
         I:=Pos(#32,Str);
         if I<>0 then Delete(Str,I,1);
      until I=0;
      Str:=ExtractFilePath(SaveDialog.Filename)+Str;
      Strings.SaveToFile(Str);

      SaveDialog.Destroy;
   Frames.Destroy;
   Screen.Cursor:=PrevCursor;
   Strings.Destroy;
end;

// Save part of the geometry to a file
procedure SEdit.File_ExportPart;
var SelectDlg  : TSelectLayersDialog;
    Faces      : TFasterList;
    I          : Integer;
begin
   Faces:=TFasterList.Create;
   if St.NoSelectedControlFaces=0 then begin
      SelectDlg:=TSelectLayersDialog.Create(St);
      ShowTranslatedValues(SelectDlg);
      if SelectDlg.Execute(St,fsFaces) then SelectDlg.ExtractSelectedFaces(Faces);
      for I:=St.NoSelectedControlFaces downto 1 do St.SelectedControlFace[I-1].Selected:=false;
      St.Redraw;
      SelectDlg.Destroy;
   end else begin
      Faces.Capacity:=Faces.Count+St.NoSelectedControlFaces;
      for I:=1 to St.NoSelectedControlFaces do Faces.Add(St.SelectedControlFace[I-1]);
   end;
   if Faces.Count>0 then St.SavePart(Faces);
   Faces.Destroy;
end;

// Save NURBS patches to an IGES file

procedure SEdit.File_ExportIGES;
const // MinimizeFaces  = True;
         SendTriangles  = True; // было = False;
var I,J,K,Cols,Rows,NAssembled,PrevLevel,ColorIndex,NSurfaces: Integer;
    ColorIndices: array of Integer;
    Dialog: TSaveDialog;
    Layers,CheckFaces: TFasterlist;
    Layer: SLayer;
    Assembled: TFaceArray;
    IGESList: TIGESList;
    Grid: SGrid;        FaceData: TFaceGrid;
    CtrlFace: SControlFace; Face: SFace;
    Prev: TCursor;

    function FindFourtPoint(P1,P2,p3:SPoint):SPoint;
    var Face  : SFace;
        I,J   : Integer;
        List  : TList;
    begin
       Result:=nil;
       if (P1<>P2) and (P2<>P3) and (P1<>P3) then begin
          for I:=1 to P2.NoFaces do begin
             Face:=P2.Face[I-1];
             if (Face.IndexOfPoint(P1)<>-1) and
             // (Face.IndexOfPoint(P2)<>-1) and
                (Face.IndexOfPoint(P3)<>-1) then
             begin
                List:=TList.Create;
                for J:=1 to face.Nopoints do list.Add(Face.Point[J-1]);
                J:=List.IndexOf(P1); if J<>-1 then list.Delete(J);
                J:=List.IndexOf(P2); if J<>-1 then list.Delete(J);
                J:=List.IndexOf(P3); if J<>-1 then list.Delete(J);
                if list.Count>0 then result:=List[0];
                List.Destroy;
             end;
          end;
       end;
    end;
    procedure FindOpposingPoints
    ( P1,P2,P3,P4:SPoint;
      var OppPoint2,OppPoint3:SPoint );
    // find the points opposite to P2 and P3
    var I,Index:Integer;
        Edge:SEdge;
        Face:Sface;
    begin
       OppPoint2:=nil;
       OppPoint3:=nil;
       Edge:=St.Surface.EdgeExists(P2,P3);
       if Edge<>nil then if not Edge.Crease then begin
          for I:=1 to Edge.NoFaces do begin
             Face:=Edge.Face[I-1];
             if (Face.IndexOfPoint(P1)=-1)
             or (Face.IndexOfPoint(P2)=-1)
             or (Face.IndexOfPoint(P3)=-1)
             or (Face.IndexOfPoint(P4)=-1) then begin
                Index:=Face.IndexOfPoint(P3);
                if Index<>-1 then begin
                   Index:=(Index+1) mod Face.Nopoints;
                   if Face.Point[index]=P2 then begin   // face is oriented CCW
                      Index:=(Index+1) mod Face.Nopoints;
                      OppPoint2:=Face.Point[index];
                      Index:=(Index+1) mod Face.Nopoints;
                      OppPoint3:=Face.Point[index];
                   end else begin
                      Index:=Face.IndexOfPoint(P2);
                      if Index<>-1 then begin
                         Index:=(Index+1) mod Face.Nopoints;
                         if Face.Point[index]=P3 then begin // face is oriented CW
                            Index:=(Index+1) mod Face.Nopoints;
                            OppPoint3:=Face.Point[index];
                            Index:=(Index+1) mod Face.Nopoints;
                            OppPoint2:=Face.Point[index];
                         end;
                      end;
                   end;
                end;
                break;
             end;
          end;
       end;
    end;

    procedure AssembleTriangle(var Cols,Rows:Integer;var Grid:SGrid;Face:SControlface);
    var I,J,N, Index: Integer;
        Points,Faces: TFasterList;
        Child: Sface;
        P,InteriorPoint: SPoint;
    begin // Initialize grid
      Cols:=0;
      Rows:=0;
      Points:=TFasterList.Create;
      Faces:=TFasterList.Create;
      for I:=1 to Face.ChildCount do begin
         Child:=Face.Child[I-1];
         Faces.Add(Child);
         for J:=1 to Child.Nopoints do begin
            P:=Child.Point[J-1];
            if Points.SortedIndexOf(P)=-1 then Points.AddSorted(P);
         end;
      end;
      Faces.Sort;                          // Try to isolate the interior point
      InteriorPoint:=nil;
      for I:=1 to Points.Count do begin
         P:=Points[I-1]; // check how many of the childfaces are connected (interior point must have 3)
         N:=0;
         for J:=1 to P.NoFaces do
            if Faces.SortedIndexOf(P.Face[J-1])<>-1 then inc(N);
         if N=3 then begin InteriorPoint:=P; break; end;
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
    end;

    procedure ProcessGrid(Cols,Rows:Integer;Grid:SGrid;ColorInd:Integer);
    var NURB,NURB2: TNURBsurface;           // convert grid to a NURB
        I,J       : Integer;
        BottomRow,TopRow,LeftColumn,RightColumn: array of SPoint;
        BottomLeft,BottomRight,TopLeft,TopRight: SPoint;
        BottomPresent,LeftPresent,RightPresent,TopPresent: Boolean;
        P: Vector;

        function PhantomPoint( BorderPoint,InnerPoint:Vector ):Vector;
           begin Result:=2.0*BorderPoint-InnerPoint; end;     {PhantomPoint}

        function CornerPoint(P5,P6,P8,P9:Vector):Vector;
        var P2,P3,P4,P7:Vector;
        begin
           P2:=PhantomPoint(P5,P8);
           P3:=PhantomPoint(P6,P9);
           P4:=PhantomPoint(P5,P6);
           P7:=PhantomPoint(P8,P9);
           Result:=20*P5 - 4*P2 - P3 - 4*P4 - 4*P6 - P7 - 4*P8 -P9;
        end;

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

         NURB:=TNURBsurface.Create;
         NURB.SetCapacity(Cols+2,Rows+2);
         NURB.ColCount:=Nurb.ColCapacity;
         NURB.RowCount:=Nurb.RowCapacity;
         for I:=1 to Rows do begin
            for J:=1 to COLS do begin
               NURB.Point[J,I]:=Grid[I-1][J-1].Coordinate;
            end;
         end;
         if SendTriangles then begin         // check for special triangle case
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
         // Set knotvectors to open-knot iVect type (standard interpolating form)
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
         if St.Visibility.ModelView=mvBoth then begin
            NURB2:=TNURBsurface.Create;
            NURB2.SetCapacity(Nurb.ColCount,Nurb.RowCount);
            NURB2.ColCount:=Nurb2.ColCapacity;
            NURB2.RowCount:=Nurb2.RowCapacity;
            NURB2.ColDegree:=Nurb.ColDegree;
            NURB2.RowDegree:=Nurb.RowDegree;
            for I:=Nurb.ColCount downto 1 do
            for J:=Nurb.RowCount downto 1 do begin
                P:=NURB.Point[I-1,J-1];
                P.Y:=-P.Y;
                NURB2.Point[NURB2.Colcount-I,Nurb2.RowCount-J]:=P;
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
    end;
begin
   Dialog:=TSaveDialog.Create(St);
   Dialog.InitialDir:=St.Preferences.ExportDirectory;
   Dialog.FileName:=ChangeFileExt(ExtractFilename(St.FileName),'.igs');
   Dialog.Filter:='IGES files [*.igs,*.iges]|*.igs; *.iges';
   dialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if Dialog.Execute then begin
      Prev:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      PrevLevel:=St.Surface.DesiredSubdivisionLevel;
      NSurfaces:=0;
      St.Surface.DesiredSubdivisionLevel:=1;
      St.Surface.SubdivisionMode:=fmCatmullClark;
      if not St.Surface.Build then St.Surface.Rebuild;
      St.Preferences.ExportDirectory:=ExtractFilePath(Dialog.FileName);
      IGESList:=TIGESList.Create;
      IGESList.IGESUnits:=St.ProjectSettings.ProjectUnits;
      IGESList.SystemID:='free!Ship'+#32+VersionString(CurrentVersion);
      IGESList.FileCreatedBy:=St.ProjectSettings.ProjectFileCreatedBy;
      IGESList.FileName:=Dialog.FileName;                  // Build color table
      Layers:=TFasterList.Create;
      for I:=1 to St.NoLayers do
      if (St.Layer[I-1].Visible)
      and (St.Layer[I-1].Count>0) then Layers.Add( St.Layer[I-1] );
      Layers.Sort;
      Setlength( ColorIndices,Layers.Count );
      for I:=1 to Layers.Count do begin
        Layer:=Layers[I-1];
         ColorIndices[I-1]:=FindIGSColorIndex( Layer.Color );
                            //IGESList.Add_Entity_314( Layer.Color );
      end;
{     if MinimizeFaces then begin  ///###
         St.Surface.AssembleFacesToPatches(Layers,amNURBS,Assembled,NAssembled);
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
               and (FaceData.Faces[0][0].NoPoints=4)) then begin
                  CtrlFace:=FaceData.Faces[0][0];
                  if Layers.SortedIndexOf(Ctrlface.Layer)<>-1
                  then ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
                  else Colorindex:=0;
                  St.Surface.ConvertToGrid(FaceData,Cols,Rows,Grid);
                  ProcessGrid(Cols,Rows,Grid,ColorIndex);
               end else begin
                  CtrlFace:=FaceData.Faces[0][0];
                  if Layers.SortedIndexOf(Ctrlface.Layer)<>-1
                  then ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
                  else Colorindex:=0;
                  if (CtrlFace.Nopoints=3) and (SendTriangles) then begin
                     AssembleTriangle( Cols,Rows,Grid,CtrlFace );
                     if (Cols>0) and (Rows>0)then ProcessGrid( Cols,Rows,Grid,ColorIndex );
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
     end else begin }
         for I:=1 to St.Surface.NoControlFaces do begin
            CtrlFace:=St.Surface.ControlFace[I-1];
            if Layers.SortedIndexOf(Ctrlface.Layer)<>-1
               then ColorIndex:=ColorIndices[Layers.SortedIndexOf(Ctrlface.Layer)]
               else Colorindex:=0;
            if CtrlFace.Nopoints=4 then begin
               FaceData.NCols:=1;
               FaceData.NRows:=1;
               Setlength(FaceData.Faces,1);
               Setlength(FaceData.Faces[0],1);
               FaceData.Faces[0][0]:=Ctrlface;
               St.Surface.ConvertToGrid(FaceData,Cols,Rows,Grid);
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
//    end;

      if NSurfaces>0 then begin
         IGESList.SaveToFile(ChangeFileExt(Dialog.Filename,'.igs'));
         ShowMessage('Exported '+IntToStr(NSurfaces)+' surfaces.');
      end else ShowMessage(Userstring(100));
      IGESList.Destroy;
      Layers.Destroy;
      St.Surface.DesiredSubdivisionLevel:=PrevLevel;
      St.Surface.SubdivisionMode:=fmQuadTriangle;
      if not St.Surface.Build then St.Surface.Rebuild;
      Screen.Cursor:=Prev;
      St.Redraw;
   end;
   Dialog.Destroy;
end;

// Exports all intersections to a textfile as 3D points
procedure SEdit.File_ExportOffsets;
var SaveDialog: TSaveDialog; Strings: TStringlist; I: integer;
    procedure SendSpline(Spline:Tspline);
    var J: integer; Str: string; P: Vector;
    begin
      for J:=1 to Spline.nS do begin
         P:=Spline.Point[J-1];
         Str:='        '+MakeLength(P.X,5,10)
                    +#32+MakeLength(P.Y,5,10)
                    +#32+MakeLength(P.Z,5,10);
         if Spline.Knuckle[J-1] then Str:=Str+'    KNUCKLE';
         Strings.Add(Str);
      end;
    end;
    procedure SendIntersection(Intersection:TIntersection);
    var I: integer; Str: string; Spline: TSpline;
    begin
       if not Intersection.Built then Intersection.Rebuild;
       if Intersection.Count>0 then begin
          Str:=Intersection.Description;
          Strings.Add(Str);
          if Intersection.Count>1 then Strings.Add(IntToStr(Intersection.Count)+' segments.');
          for I:=1 to Intersection.count do begin
             Spline:=Intersection.Items[I-1];
             if Intersection.Count>1 then Strings.Add('SEGMENT '+IntToStr(I));
             SendSpline(Spline);
          end;
       end;
    end;
begin
   SaveDialog:=TSaveDialog.Create(St);
   SaveDialog.InitialDir:=St.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(St.FileName),'.txt');
   SaveDialog.Filter:='Offsets as 3D points [*.Txt]|*.txt';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then
   begin
      St.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      Strings:=TStringlist.Create;
      for I:=1 to St.NoStations do SendIntersection(St.Station[I-1]);
      for I:=1 to St.NoButtocks do SendIntersection(St.Buttock[I-1]);
      for I:=1 to St.NoWaterlines do SendIntersection(St.Waterline[I-1]);
      for I:=1 to St.NoDiagonals do SendIntersection(St.Diagonal[I-1]);
      for I:=1 to St.NoControlCurves do
      begin
         Strings.Add('CONTROLCURVE');
         SendSpline(St.ControlCurve[I-1].Curve);
      end;
      Strings.SaveToFile(ChangeFileExt(Savedialog.FileName,'.txt'));
      Strings.Destroy;
   end;
   SaveDialog.Destroy;
end;

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

procedure SEdit.File_ExportSTL;
var SaveDialog : TSaveDialog;
    FFile      : TextFile;
    I,J,K,L    : Integer;
    Layer      : SLayer;
    Face       : SControlface;
    Child      : Sface;

    procedure Addfacet(P1,P2,P3:SPoint);
    var Normal:Vector;
    begin
       Normal:=UnifiedNormal(p1.Coordinate,P2.Coordinate,P3.Coordinate);
       Write(FFile,'  facet normal ');
       writeln(FFile,FloatToDec(normal.X,4)+#32+FloatToDec(normal.Y,4)+#32+FloatToDec(normal.Z,4));
       writeln(FFile,'    outer loop');
       writeln(FFile,'      vertex '+FloatToDec(P1.Coordinate.X,4)+#32+FloatToDec(P1.Coordinate.Y,4)+#32+FloatToDec(P1.Coordinate.Z,4));
       writeln(FFile,'      vertex '+FloatToDec(P2.Coordinate.X,4)+#32+FloatToDec(P2.Coordinate.Y,4)+#32+FloatToDec(P2.Coordinate.Z,4));
       writeln(FFile,'      vertex '+FloatToDec(P3.Coordinate.X,4)+#32+FloatToDec(P3.Coordinate.Y,4)+#32+FloatToDec(P3.Coordinate.Z,4));
       writeln(FFile,'    endloop');
       Writeln(FFile,'  endfacet');
    end;
begin
   SaveDialog:=TSaveDialog.Create(St);
   SaveDialog.InitialDir:=St.Preferences.ExportDirectory;
   SaveDialog.FileName:=ChangeFileExt(ExtractFilename(St.FileName),'.stl');
   SaveDialog.Filter:='STL file [*.stl]|*.stl';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      St.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      AssignFile(FFile,Changefileext(SaveDialog.FileName,'.stl'));
      {$I-}Rewrite(FFile);{$I+}
      if IOResult=0 then begin // perform modelcheck to ensure normals point outward
         writeln( FFile,'solid' );
         if not St.ProjectSettings.DisableModelCheck then Model_Check(False);
         for I:=1 to St.Surface.NoLayers do begin
            Layer:=St.Surface.Layer[I-1];
            if Layer.Visible then for J:=1 to Layer.Count do begin
               Face:=Layer.Items[J-1];
               for K:=1 to Face.ChildCount do begin
                  Child:=face.Child[K-1];
                  For L:=3 to Child.Nopoints do AddFacet(Child.Point[0],Child.Point[L-2],Child.Point[L-1]);
               end;
            end;
         end;
         writeln(FFile,'endsolid');
         Closefile(FFile);
      end else ShowMessage(Userstring(97));
   end;
   SaveDialog.Destroy;
end;

// imports a Carene XYZ file and creates a multichine boat with developable surfaces
procedure SEdit.File_ImportCarene;
var OpenDialog : TOpenDialog;
    Answer     : Word;
    Str        : string;
    I{,LineNr} : Integer;
    P          : Vector;
    FFile      : TextFile;
    Chines     : TFasterList;
    Spline     : TSpline;
begin
   OpenDialog:=TOpenDialog.Create(St);
   OpenDialog.InitialDir:=St.Preferences.ImportDirectory;
   OpenDialog.Filter:='Carene XYZ files [*.xyz]|*.xyz';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=St.Edit.File_SaveCheck;
      if (Answer=mrCancel) or St.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      CreateUndoObject(Userstring(105),True);
      St.Clear;
      assignFile(FFile,ChangeFileExt(Opendialog.FileName,'.xyz'));
      {$I-}Reset(FFile);{$I+}
      if IOResult=0 then begin
         St.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
         Readln(FFile,Str);              // first 18 characters are description
         Str:=Copy(Str,1,18);
         Str:=Trim(Str);
         St.ProjectSettings.FProjectName:=Str;
         Chines:=TFasterList.Create;
         while not EOF(FFile) do begin
            Readln(FFile,Str);
            if Pos('LINE',Str)=1 then begin          // New chine skip one line
               if not EOF(FFile) then begin
                  Readln(FFile);
               end;
               if not EOF(FFile) then begin
                  Spline:=TSpline.Create;
                  Chines.Add(Spline);
                  repeat
                     Readln(FFile,Str);
                     repeat
                        I:=Pos(#9,Str);
                        if I<>0 then Str[I]:=#32;
                     until I=0;
                     if Str<>'' then begin
                        P:=GetVector( Str );
                        Spline.Add(P);
                        Str:=#32;
                     end;
                  until (EOF(FFile)) or (Str='');
               end;
            end;
         end;
         St.ImportChines(8,Chines);
         Chines.Destroy;
         CloseFile(FFile);
         St.Filename:=ChangeFileExt(Opendialog.FileName,'.fbm');
      end else ShowMessage(Userstring(106));
   end;
   OpenDialog.Destroy;
end;

// Imports a file created with Carlssons's Hulls program

procedure SEdit.File_ImportHull;
var OpenDialog : TOpenDialog;
    Answer     : Word;
begin
   OpenDialog:=TOpenDialog.Create(St);
   OpenDialog.InitialDir:=St.Preferences.ImportDirectory;
   OpenDialog.Filter:='Carlsson Hull files [*.hul]|*.hul';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=St.Edit.File_SaveCheck;
      if (Answer=mrCancel) or St.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      CreateUndoObject(UserString(110),True);
      File_ImportHull(OpenDialog.FileName,False);
      St.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
   end;
   OpenDialog.Destroy;
end;

procedure SEdit.File_ImportHull(Filename:string;Quiet:Boolean);
var I,J,NBulkHeads,NoChines: integer;
    P,Min,Max  : Vector;
    FFile      : TextFile;
    Value      : Real;
    Points     : array of VectorArray;
    Chines     : TFasterList;
    Spline     : TSpline;
    Str        : string;
    Skip       : Boolean;
begin
   St.Clear;
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
               P:=0.0254*P;
               if (I=1) and (J=1) then begin Min:=P; Max:=Min; end
                                  else MinMax(P,Min,Max);
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
                  P:=0.0254*P;
                  if (I=1) and (J=1) then begin Min:=P; Max:=Min; end
                                     else MinMax(P,Min,Max);
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
         for I:=1 to NoChines do begin
            for J:=1 to NBulkheads do begin
               P:=Points[J-1,I-1];
               P.X:=-P.X+Max.X;
               Points[J-1,I-1]:=P;
            end;
            Spline:=TSpline.Create;
            Chines.Add(Spline);
            for J:=1 to NBulkheads do begin
               P:=Points[J-1,I-1];
               Spline.Add(P);
               Spline.Knuckle[J-1]:=False;
            end;
         end;
         St.ImportChines(NBulkheads,Chines);
         Chines.Destroy;
         for I:=1 to 8 do begin                        // read stations
            Readln(FFile,Value);
            Intersection_Add(fiStation,-Value*0.024+Max.X);
         end;
         for I:=1 to 9 do Readln(FFile);               // Skip rig info
         Readln(FFile,Str);                            // Read designer info
         St.ProjectSettings.FProjectDesigner:=Str;
         Readln(FFile,Str);
         St.ProjectSettings.FProjectName:=Str;
//    finally
         CloseFile(FFile);
         St.ProjectSettings.ProjectWaterDensity:=1.0;
         St.ProjectSettings.ProjectUnits:=fuImperial;
         St.ProjectSettings.ProjectDraft:=1.0;
         St.FileName:=ChangeFileExt(FileName,'');
         St.Draw;
//    end;
   end else ShowMessage(Userstring(106));
end;

// Import a partfile and add it to the current geometry

procedure SEdit.File_ImportPart;
var OpenDialog    : TOpenDialog;
    PartFile      : TFileBuffer;
    Undo          : TUndoObject;
    PartUnits     : TUnitType;
    Changed,Crease: Boolean;
    I,J,N,Np,Ind1,Ind2,LayerID: Integer;
    PartVersion   : TFileversion;
    Str           : string;
    Scale         : Real;
    Points,Edges,Layers,FacePoints: TFasterList;
    Edge          : SControlEdge;
    P1,P2         : SControlPoint;
    Curve         : SControlCurve;
    Layer         : SLayer;
    PrevCursor    : TCursor;
begin
   OpenDialog:=TOpenDialog.Create(St);
   OpenDialog.InitialDir:=St.Preferences.ImportDirectory;
   OpenDialog.Filter:='free!Ship geometry part [*.Part]|*.part';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      PartFile:=TFileBuffer.Create;
      St.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      Changed:=False;
      Undo:=CreateUndoObject(Userstring(112),false);
      Partfile.LoadFromFile(ChangeFileExt(OpenDialog.FileName,'.part'));
      Partfile.LoadString(Str);
      if Str='FREE!ship partfile' then begin                // Load fileversion
         Partfile.LoadInteger(I);
//       if I<=Ord(CurrentVersion) then begin
            PrevCursor:=Screen.Cursor;
            Screen.Cursor:=crHourglass;
//          try
               Partversion:=TFileVersion(I);
               Partfile.Version:=PartVersion;
               Points:=TFasterList.Create;
               Edges:=TFasterList.Create;
               Layers:=TFasterList.Create;
               // Load units
               Partfile.LoadInteger(I);
               PartUnits:=TUnitType(I);
               if PartUnits<>St.ProjectSettings.ProjectUnits then begin
                  if PartUnits=fuMetric
                  then Scale:=1/Foot // Part units=metric and projectunits=imperial, scale from meters to feet
                  else scale:=Foot;  // Part units=imperial and projectunits=metric, scale from feet to meters
               end else Scale:=1.0;  // Load number of layers
               Partfile.LoadInteger(N);
               Layers.Capacity:=N;
               for I:=1 to N do begin
                  Layer:=St.Surface.AddNewLayer;
                  LayerID:=Layer.LayerID;
                  Layer.LoadBinary(Partfile);
                  Layer.LayerID:=LayerID;
                  Layers.Add(Layer);
                  Changed:=True;
               end;
               Partfile.LoadInteger(N);              // Number of controlpoints
               Points.Capacity:=N;
               for I:=1 to N do begin
                  P2:=SControlPoint.Create(St.Surface);
                  St.Surface.AddControlPoint(P2);
                  P2.LoadBinary(PartFile);
                  P2.Coordinate:=Scale*P2.Coordinate;
                  Points.Add(P2);
                  Changed:=True;
               end;
               Partfile.LoadInteger(N);                   // Load control edges
               Edges.Capacity:=N;
               for I:=1 to N do begin
                  Partfile.LoadInteger(Ind1);
                  Partfile.LoadInteger(Ind2);
                  if (Ind1<>-1) and (Ind2<>-1) then begin
                     P1:=Points[ind1];
                     P2:=Points[ind2];
                     Edge:=St.Surface.AddControlEdge(P1,P2);
                  end else Edge:=nil;
                  Partfile.LoadBoolean(Crease);
                  if Edge<>nil then Edge.Crease:=Crease;
                  Changed:=True;
               end;
               Partfile.LoadInteger(N);                    // Load controlfaces
               FacePoints:=TFasterList.Create;
               for I:=1 to N do begin
                  Partfile.LoadInteger(Np);
                  FacePoints.Clear;
                  FacePoints.Capacity:=N;
                  for J:=1 to Np do begin
                     Partfile.LoadInteger(Ind1);
                     P2:=Points[ind1];
                     FacePoints.Add(P2);
                  end;
                  Partfile.LoadInteger(Ind2);
                  Layer:=Layers[ind2];
                  St.Surface.AddControlFace(FacePoints,False,Layer);
               end;
               for I:=1 to Edges.Count do begin
                  Edge:=Edges[I-1];
                  if (Edge.NoFaces<>2) and (not Edge.Crease) then
                     Edge.Crease:=true;
               end;
               Partfile.LoadInteger(N);                   // Load controlcurves
               for I:=1 to N do begin
                  Partfile.LoadInteger(Np);
                  if Np>1 then begin
                     Curve:=SControlCurve.Create(St.Surface);
                     St.Surface.AddControlCurve(Curve);
                     for J:=1 to Np do begin
                        Partfile.LoadInteger(Ind1);
                        P2:=Points[ind1];
                        Curve.AddPoint(P2);
                        if J>1 then begin
                           P1:=Curve.ControlPoint[J-2];
                           Edge:=St.Surface.EdgeExists(P1,P2) as SControlEdge;
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
               if Assigned(St.Surface.OnChangeLayerData)
                      then St.Surface.OnChangeLayerData(St.Surface);
               Undo.Accept;
               St.Build:=False;
               St.Draw;
               St.FileChanged:=True;
               if assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(St);
            end;
//       end else ShowMessage(UserString(113));
      end else ShowMessage(Userstring(114));
      if not Changed then Undo.Delete;
      Partfile.Destroy;
   end;
   OpenDialog.Destroy;
end;

// Imports a PolyCad file

procedure SEdit.File_ImportPolycad; begin ShowMessage( 'Временно исключено' ) end;
(*
var OpenDialog : TOpenDialog;
    Answer     : Word;
    PrevCursor : TCursor;
    Strings    : TStringList;
    I,J,K,N,Cols,Rows,Index,NSurfaces: Integer;
    Indices    : array of Integer;
    Str,Tmp    : String;
    Abort      : Boolean;
    Points     : TCoordinateGrid;
    Value      : Real;
    P          : Vector;

    function NextLine:string;
    begin
//     if Index+1<Strings.Count then begin
          inc(Index);
          Result:=Strings[index];
{      end else begin Result:=''; Abort:=True; ShowMessage(UserString(115));
       end; }
    end;
    function NextParameter(var input:string):string; var Index:Integer;
    begin
       Index:=pos(#32,Input);
       if Index<>0 then begin
          Result:=Copy(Input,1,Index-1);
          Delete(Input,1,Index);
          Input:=Trim(Input);
       end else begin
          Result:='';
          Abort:=True;
       end;
    end;
begin
   OpenDialog:=TOpenDialog.Create(St);
   OpenDialog.InitialDir:=St.Preferences.ImportDirectory;
   OpenDialog.Filter:='PolyCad files [*.geo]|*.geo';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=St.Edit.File_SaveCheck;
      if (Answer=mrCancel) or St.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      Strings:=TStringList.Create;
         Strings.LoadFromFile(OpenDialog.FileName);     // delete empty strings
         for I:=Strings.Count downto 1 do
             if Strings[I-1]='' then Strings.Delete(I-1);
         NSurfaces:=0;                      // count number of BSpline surfaces
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
            St.Clear;
            St.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
            I:=1;
            Abort:=False;
            while (I<=NSurfaces) and (not Abort) do begin
               Index:=Indices[I-1];
               Str:=Strings[index];
               if (pos('[TYachtLines]',Strings[I-1])<>0) then begin // Read loa
                  Str:=NextLine;
                  St.ProjectSettings.ProjectLength:=GetFloat(Str);
                  NextLine;
                  NextLine;
                  // read beam over all
                  Str:=NextLine;
                  St.ProjectSettings.ProjectBeam:=GetFloat(Str);
                  NextLine;
                  NextLine;
                  // Read draft
                  Str:=NextLine;
                  St.ProjectSettings.ProjectDraft:=GetFloat(Str);
//                St.ProjectSettings.FMainparticularsHasBeenset:=True;
                  for J:=1 to 12 do NextLine;
               end else if (pos('[TShipLines]',Strings[I-1])<>0) then begin
                  NextLine;
                  Str:=NextLine;                                 // Read length
                  St.ProjectSettings.ProjectLength:=GetFloat(Str);
                  Str:=NextLine;                                   // read beam
                  St.ProjectSettings.ProjectBeam:=GetFloat(Str);
                  NextLine;                                       // skip depth
                  Str:=NextLine;                                  // Read draft
                  St.ProjectSettings.ProjectDraft:=GetFloat(Str);
               // St.ProjectSettings.FMainparticularsHasBeenset:=True;
                  for J:=1 to 22 do NextLine;
               end;
               NextLine;            // skip OrderU=
               NextLine;            // skip OrderV=
               Str:=NextLine;                         // Read number of columns
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
                                 ShowMessage(Userstring(119)+#32+IntToStr(I));
                                 Abort:=True;
                              end;
                           end;
                           if not Abort then begin
                              Tmp:=NextParameter(Str);
                              if not abort then begin
                                 Val(Tmp,P.Y,N);
                                 if N<>0 then begin
                                    ShowMessage(Userstring(120)+#32+IntToStr(I));
                                    Abort:=True;
                                 end;
                              end;
                           end;
                           if not Abort then begin              // Z coordinate
                              Tmp:=NextParameter(Str);
                              if not abort then begin
                                 Val(Tmp,P.Z,N);
                                 if N<>0 then begin
                                    ShowMessage(Userstring(121)+#32+IntToStr(I));
                                    Abort:=True;
                                 end;
                              end;
                           end;
                           Points[K-1][J-1]:=P;
                        end else break;
                     end;
                     if abort then break;
                  end;
                  if not Abort then St.Surface.ImportGrid(Points,Cols,Rows,nil);
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
                                    ShowMessage(Userstring(122));
                                    Abort:=True;
                                 end else begin
                                    Case K of
                                       1: self.Intersection_Add(fiStation,Value);
                                       2: if Value>=0 then self.Intersection_Add(fiButtock,Value);
                                       3: self.Intersection_Add(fiWaterline,Value);
                                    end;
                                 end;
                              end;
                           end; if abort then break;
                        end;
                     end; break;
                  end;
               end;
               St.Precision:=fpMedium;
               St.FileName:=ChangeFileExt(Opendialog.FileName,'');
               St.Build:=False;
               St.RebuildModel;
               St.FileChanged:=true;
            end else ShowMessage(UserString(123));
         end else    ShowMessage(UserString(124));
      Strings.Destroy;
      if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
      Screen.Cursor:=PrevCursor;
   end;
   OpenDialog.Destroy;
end;
*)

// Load a VRML file

Procedure SEdit.File_ImportVRML;
var OpenDialog : TOpenDialog;
    Answer     : Word;
    PrevCursor : TCursor;
begin
   OpenDialog:=TOpenDialog.Create(St);
   OpenDialog.InitialDir:=St.Preferences.ImportDirectory;
   OpenDialog.Filter:='VRML files [*.wrl,*.vrml]|*.wrl; *.vrml';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then begin
      Answer:=St.Edit.File_SaveCheck;
      if (Answer=mrCancel) or St.FileChanged
         then begin OpenDialog.Destroy; exit; end;
      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourglass;
      CreateUndoObject(Userstring(125),True);
      St.Clear;
      St.Preferences.ImportDirectory:=ExtractFilePath(OpenDialog.FileName);
      St.Surface.LoadVRMLFile(Opendialog.FileName);
      St.FileName:=ChangeFileExt(Opendialog.FileName,'');
      St.Build:=False;
      St.RebuildModel;
      St.FileChanged:=true;
      if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
      Screen.Cursor:=PrevCursor;
   end;
   OpenDialog.Destroy;
end;

procedure TShip.SavePart(Faces:TFasterList);
var SaveDialog : TSaveDialog;
    I,J,Index  : Integer;
    Layers,Edges,Points,Curves: TFasterList;
    Face       : SControlface;
    Edge       : SControlEdge;
    P1,P2      : SControlPoint;
    Curve      : SControlCurve;
    Layer      : SLayer;
    PartFile   : TFileBuffer;
    PrevCursor : TCursor;
    Surface    : SSurface;
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
   SaveDialog.Filter:='free!Ship geometry part [*.Part]|*.part';
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
         P1:=Face.Point[Face.NoPoints-1] as SControlPoint;
         for J:=1 to face.Nopoints do begin
           P2:=Face.Point[J-1] as SControlPoint;
           if Points.SortedIndexOf(P2)=-1 then Points.AddSorted(P2);
           Edge:=P1.Owner.EdgeExists(P1,P2) as SControlEdge;
           if Edge<>nil then if Edges.SortedIndexOf(Edge)=-1 then Edges.AddSorted(Edge);
           P1:=P2;
         end;
      end;

      // process control curves
      for I:=1 to Surface.NoControlCurves do begin
         Curve:=Surface.ControlCurve[I-1];
         // In order to export this curve, all associated controledges must be in the edges list
         AddCurve:=True and (Curve.NoControlPoints>1);
         for J:=2 to Curve.NoControlPoints do begin
            P1:=Curve.ControlPoint[J-2];
            P2:=Curve.ControlPoint[J-1];
            Edge:=Surface.EdgeExists(P1,P2) as SControlEdge;
            if Edge<>nil then begin
               if Edges.SortedIndexOf(Edge)=-1 then AddCurve:=False;
            end else AddCurve:=False;
         end;
         if AddCurve then Curves.Add(Curve);
      end;

      Curves.Sort;
      Layers.Sort;

      PartFile:=TFileBuffer.Create;
      PartFile.Version:=CurrentVersion;

      PrevCursor:=Screen.Cursor;
      Screen.Cursor:=crHourGlass;
      Partfile.Add('FREE!ship partfile');
      Partfile.Add(ord(CurrentVersion));                        // File version
      I:=Ord(ProjectSettings.ProjectUnits);
      Partfile.Add(I);           // Write units type used (imperial or metric);
      Partfile.Add(Layers.Count);               // Number of layers in the file
      for I:=1 to Layers.Count do begin                      // Save layer info
         Layer:=Layers[I-1];
         Layer.SaveBinary(Partfile);
      end;

      Partfile.Add(Points.Count);                         // Save controlpoints
      for I:=1 to Points.Count do begin
         P2:=Points[I-1];
         P2.SaveBinary(PartFile);
      end;
      Partfile.Add(Edges.Count);                          // Save control edges
      for I:=1 to Edges.Count do begin
         Edge:=Edges[I-1];
         Index:=Points.SortedIndexOf(Edge.StartPoint);
         Partfile.Add(Index);
         Index:=Points.SortedIndexOf(Edge.EndPoint);
         Partfile.Add(Index);
         Partfile.Add(Edge.Crease);
      end;
      Partfile.Add(Faces.Count);                           // save controlfaces
      for I:=1 to Faces.Count do begin
         Face:=Faces[I-1];
         Partfile.Add(Face.Nopoints);
         for J:=1 to Face.NoPoints do begin
            Index:=Points.SortedIndexOf(Face.Point[J-1]);
            Partfile.Add(Index);
         end;
         Index:=Layers.SortedIndexOf(Face.Layer);
         Partfile.Add(Index);
      end;
      Partfile.Add(Curves.Count);                         // Save controlcurves
      for I:=1 to Curves.Count do begin
         Curve:=Curves[I-1];
         Partfile.Add(Curve.NoControlPoints);
         for J:=1 to Curve.NoControlPoints do begin
            P2:=Curve.ControlPoint[j-1];
            Index:=points.SortedIndexOf(P2);
            Partfile.Add(Index);
         end;
      end;
      Partfile.SaveToFile(ChangeFileExt(SaveDialog.FileName,'.part'));
      Screen.Cursor:=PrevCursor;
      Partfile.Destroy;
      Points.Destroy;
      Edges.Destroy;
      Curves.Destroy;
      Layers.Destroy;
   end;
   SaveDialog.Destroy;
end;
//
// imports a number of longitudinally lines and creates developable
//    surfaces between each two subsequent chines
//
procedure TShip.ImportChines( Np:Integer;Chines:TFasterList );
var I,J        : integer;
    P,Min,Max  : Vector;
    Pts,Pts2,Tmp: TFasterList;
    Points     : array of array of SControlPoint;
    Curve      : SControlCurve;
    Point      : SControlPoint;
    Edge       : SControlEdge;
    Layer      : SLayer;
    Spline     : TSpline;
    Marker     : TMarker;
    Matrix,Inv,OrgPts,NewPts: TMatrix;
begin
   for I:=1 to Chines.Count-1 do begin
      if I<=Surface.NoLayers then Layer:=Surface.Layer[I-1]
                                   else Layer:=Surface.AddNewLayer;
      Layer.Name:='Strake '+IntToStr(I);      // Userstring(186)+#32 = "Полоса"
      Layer.Developable:=True;
   end;                 // add special layer to close the hull at centerline
   Layer:=Surface.AddNewLayer;
   Layer.Name:=Userstring(187);
   Setlength(Points,Np);                           // Prepare matrices
   Matrix:=TMatrix.Create;
   Matrix.SetSize(Np,Np);
   Matrix.Fill(0.0);
   Matrix.Value[0,0]:=1.0;
   for I:=2 to Np-1 do begin
      Matrix.Value[I-1,I-2]:=1/6;
      Matrix.Value[I-1,I-1]:=2/3;
      Matrix.Value[I-1,I  ]:=1/6;
   end;
   Matrix.Value[Np-1,Np-1]:=1.0;                   // Invert matrix
   Inv:=Matrix.Invert;
   Matrix.Destroy;
   OrgPts:=TMatrix.Create;
   OrgPts.SetSize(3,Np);
   for I:=1 to Np do Setlength(Points[I-1],Chines.Count);
   for I:=1 to Chines.Count do begin
      Spline:=Chines[I-1];
      OrgPts.Fill(0.0);
      for J:=1 to Np do begin
         P:=Spline.Value((J-1)/(Np-1));
         OrgPts.Value[J-1,0]:=P.X;
         OrgPts.Value[J-1,1]:=P.Y;
         OrgPts.Value[J-1,2]:=P.Z;
      end;                                         // calculate new points
      NewPts:=Inv.Multiply(OrgPts);
      for J:=1 to Np do begin
         P.X:=NewPts.Value[J-1,0];
         P.Y:=NewPts.Value[J-1,1];
         if P.Y<0 then P.Y:=0;
         P.Z:=NewPts.Value[J-1,2];
         if (I=1) and (J=1) then begin Min:=P; Max:=Min; end
                            else MinMax( P,Min,Max );
         Points[J-1][I-1]:=Surface.AddControlPoint(P);
      end;
      NewPts.Destroy;
   end;
   OrgPts.Destroy;                                 // Delete inverted matrix
   Inv.Destroy;                                    // Add chines as markers
   for I:=1 to Chines.Count do begin
      Spline:=Chines[I-1];
      Marker:=TMarker.Create;
      Marker.FOwner:=self;
      Edit.Marker_Add(Marker);
      for J:=1 to Spline.nS do begin
         Marker.Add(Spline.Point[J-1]);
         Marker.Knuckle[J-1]:=Spline.Knuckle[J-1];
      end;
   end;                                                // Setup controlfaces
   Pts:=TFasterlist.Create;
   for I:=2 to Np do
   for J:=2 to Chines.Count do begin Pts.Clear;
     Point:=Points[I-1][J-1]; if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
     Point:=Points[I-2][J-1]; if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
     Point:=Points[I-2][J-2]; if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
     Point:=Points[I-1][J-2]; if Pts.IndexOf(Point)=-1 then Pts.Add(Point);
     if Pts.Count>2 then Surface.AddControlFace(Pts,True,Surface.Layer[J-2]);
   end;
   for I:=2 to Np do
   for J:=1 to Chines.Count do begin
      Edge:=Surface.EdgeExists(Points[I-2][J-1],Points[I-1][J-1]) as SControlEdge;
      if Edge<>nil then Edge.Crease:=True;
   end;                                                 // Add controlcurves
   for J:=1 to Chines.Count do begin
      Curve:=SControlCurve.Create(Surface);
      Surface.AddControlCurve(Curve);
      for I:=1 to Np do begin Curve.AddPoint(Points[I-1][J-1]);
         if I>1 then begin
            Edge:=Surface.EdgeExists(Points[I-2][J-1],Points[I-1][J-1]) as SControlEdge;
           if Edge<>nil then Edge.Curve:=Curve;
         end;
      end;
   end;
   // Check for stem, keel and stern points to be closed
   Pts.Clear;                                                 // first stern
   for I:=Chines.Count downto 2 do Pts.Add(Points[Np-1][I-1]);  // then keel
   for I:=Np downto 1 do Pts.Add(Points[I-1][0]);        // and finally stem
   for I:=2 to Chines.Count do Pts.Add(Points[0][I-1]);
   Pts2:=TFasterList.Create;
   for I:=1 to Pts.Count do begin
      Point:=Pts[I-1];
      P:=Point.Coordinate;
      if P.Y<>0.0 then begin
         P.Y:=0;
         Point:=Surface.AddControlPoint(P);
         if Point.Coordinate.Y<>0.0 then Point.Coordinate:=P;
         Pts2.Add(Point);
      end else Pts2.Add(Point);
   end;
   Tmp:=TFasterList.Create;
   for I:=2 to Pts.Count do begin Tmp.Clear;
      if Tmp.IndexOf(Pts2[I-1])=-1 then Tmp.Add(Pts2[I-1]);
      if Tmp.IndexOf(Pts2[I-2])=-1 then Tmp.Add(Pts2[I-2]);
      if Tmp.IndexOf(Pts[I-2]) =-1 then Tmp.Add(Pts[I-2]);
      if Tmp.IndexOf(Pts[I-1]) =-1 then Tmp.Add(Pts[I-1]);
      if Tmp.Count>2 then Surface.AddControlFace(Tmp,False,Layer);
   end;
// Now check if there are any edges on the bottom panel that are created
// by extruding the bottom points and whose crease properties are set to true.
// This causes undesired knuckle in the bottompanel
   {
   for I:=Np-1 downto 2 do begin
      Point:=Points[I-1][0];
      if Point.Coordinate.Y>0 then begin
         for J:=1 to point.NoEdges do begin
            Edge:=Point.Edge[J-1] as SControlEdge;
            if ((Edge.Crease) and (Edge.StartPoint=Point)
            and (abs(Edge.EndPoint.Coordinate.Y)<1e-5))
            or ((Edge.Crease) and (Edge.EndPoint=Point)
            and (abs(Edge.StartPoint.Coordinate.Y)<1e-5)) then Edge.Crease:=False;
         end;
      end;
   end;
   }
   // set transom as knuckle
   for J:=2 to Chines.Count do begin
      Edge:=Surface.EdgeExists(Points[Np-1][J-2],Points[Np-1][J-1]) as SControlEdge;
      if Edge<>nil then Edge.Crease:=true;
   end;                             // Delete unused layers;
   Edit.Layer_DeleteEmpty(True);    // delete unused controlpoints
   for I:=Surface.NoControlPoints downto 1 do
    if Surface.ControlPoint[I-1].NoFaces=0 then
       Surface.ControlPoint[I-1].SelDeletePoint;
   Tmp.Destroy;
   Pts2.Destroy;
   Pts.Destroy;
   Extents(Min,Max);               // ProjectSettings.ProjectWaterDensity:=1.0;
   ProjectSettings.ProjectBeam:=2*Max.Y;
   ProjectSettings.ProjectLength:=Max.X-Min.X;
   ProjectSettings.ProjectDraft:=Max.Z/2;
   Build:=False;
   Precision:=fpHigh;
   Draw;
   FileChanged:=true;
   for I:=1 to Chines.Count do begin
      Spline:=Chines[I-1];
      Spline.Destroy;
   end;
end;

