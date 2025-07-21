//
//        TFreeShip
//
procedure TFreeShip.RebuildModel;
begin Build:=False;
      Surface.DesiredSubdivisionLevel:=Ord(Precision)+1;
      Surface.Rebuild;
      Draw;
end;
Procedure TFreeShip.LoadFromFile;
var  Strings: TStringList;
begin
   Strings:=TStringList.Create;
   Strings.LoadFromFile( FileName );   // Load everything into memory
   LoadFromStream( Strings );          // Now read the information from memory
   Strings.Destroy;
   FileChanged:=False;
end;
Procedure TFreeShip.LoadFromStream( Strings:TStringList );
var I,N,CurrentLine: Integer; Str: String; PrevCursor: TCursor;
    Intersection: TFreeIntersection;
begin
   PrevCursor:=Screen.Cursor;
   // Remember the filename because it will be erased by the clear method
   Str:=FFilename;
   Clear;
   FFilename:=Str;
   if Strings.Count=0 then exit;             // empty file, most likely invalid
   Screen.Cursor:=crHourGlass;
   CurrentLine:=-1;                       // check for Freeship identifier line
   Inc(CurrentLine);
   Str:=Strings[CurrentLine];
   if Str='FREE!ship' then begin                            // Read fileversion
      Inc(CurrentLine);
      Str:=Strings[CurrentLine];
      I:=GetInteger(Str);
      FFileVersion:=TFreeVersion(I);                          // Read precision
      Inc(CurrentLine);
      Str:=Strings[CurrentLine];
      I:=GetInteger(Str);
      FPrecision:=TFreePrecisionType(I);         // Read visibility information
      Visibility.LoadFromStream(CurrentLine,Strings); // Load actual
      Surface.LoadFromStream(CurrentLine,Strings); // subdivision-surface data.
      Inc(CurrentLine);                                        // Load stations
      Str:=Strings[CurrentLine];
      N:=GetInteger(Str);
      FStations.Capacity:=N;
      for I:=1 to N do begin
         Intersection:=TFreeIntersection.Create(self);
         FStations.Add(Intersection);
         Intersection.LoadFromStream(CurrentLine,Strings);
      end;
      Inc(CurrentLine);                                        // Load Buttocks
      Str:=Strings[CurrentLine];
      N:=GetInteger(Str);
      FButtocks.Capacity:=N;
      for I:=1 to N do begin
         Intersection:=TFreeIntersection.Create(self);
         FButtocks.Add(Intersection);
         Intersection.LoadFromStream(CurrentLine,Strings);
      end;
      Inc(CurrentLine);                                      // Load Waterlines
      Str:=Strings[CurrentLine];
      N:=GetInteger(Str);
      FWaterlines.Capacity:=N;
      for I:=1 to N do begin
         Intersection:=TFreeIntersection.Create(self);
         FWaterlines.Add(Intersection);
         Intersection.LoadFromStream(CurrentLine,Strings);
      end;
      {
       for I:=1 to 40 do Edit.Intersection_Add(fiStation,Surface.Min.X+I/41*(Surface.Max.X-Surface.Min.X));
       for I:=1 to  7 do Edit.Intersection_Add(fiButtock,I/8*(Surface.Max.Y));
       for I:=1 to 10 do Edit.Intersection_Add(fiWaterline,Surface.Min.Z+I/11*(Surface.Max.Z-Surface.Min.Z));
      }
   end else MessageDlg('This is not a valid file!',mtError,[mbOK],0);
   RebuildModel;
   FileChanged:=False;
   Screen.Cursor:=PrevCursor;
end;

procedure TFreeShip.SaveToFile;
var strings : TStringlist;
    SaveDialog:TSaveDialog;
begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=ExtractFilepath(FileName);
   Savedialog.FileName:=Filename;
   SaveDialog.Filter:='FREE!ship files (*.Free)|*.Free';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      Filename:=Savedialog.Filename;
      Strings:=TStringList.Create;
      SaveToStream(Strings);
      Strings.SaveToFile(Filename);
      Strings.Destroy;
   end;
   SaveDialog.Destroy;
end;

Procedure TFreeShip.SaveToStream(Strings:TStringList);
var PrevCursor: TCursor; I: Integer;
begin
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   Strings.Add('FREE!ship');
   Strings.Add(IntToStr(Ord(FileVersion))+' // '+'Version '+VersionString(FileVersion));
   Strings.Add(IntToStr(Ord(Precision)));        // Save visibility information
   Visibility.SaveToStream(Strings);    // Save actual subdivision-surface data
   Surface.SaveToStream(Strings);                              // Save stations
   Strings.Add(IntToStr(NumberOfStations));
   For I:=1 to NumberOfStations do Station[I-1].SaveToStream(Strings);
   Strings.Add(IntToStr(NumberOfButtocks));                    // Save Buttocks
   For I:=1 to NumberOfButtocks do Buttock[I-1].SaveToStream(Strings);
   Strings.Add(IntToStr(NumberOfWaterlines));                // Save Waterlines
   For I:=1 to NumberOfWaterlines do Waterline[I-1].SaveToStream(Strings);
   FileChanged:=False;
   Screen.Cursor:=PrevCursor;
end;
//
//        TFreeIntersection
//
procedure TFreeIntersection.Rebuild;
begin // Force to destroy all current Items
   Build:=false;
   Owner.Surface.IntersectPlane(Plane,FItems);
   Build:=true;
end;
procedure TFreeIntersection.LoadFromStream(Var LineNr:Integer;Strings:TStringList);
var I,J,M,N : Integer;
    Spline  : TFreeSpline;
    Str     : String;
    P       : T3DVector;
begin                                                 // Read intersection type
   Inc(LineNr);
   Str:=Strings[LineNr];
   N:=GetInteger(Str);
   FIntersectionType:=TFreeIntersectionType(N);       // Read plane information
   FPlane.a:=GetFloat(Str);
   FPlane.b:=GetFloat(Str);
   FPlane.c:=GetFloat(Str);
   FPlane.d:=GetFloat(Str);              // Read build-flag
   FBuild:=GetBoolean(Str);                 // Read number of Items
   N:=GetInteger(Str);
   for I:=1 to N do begin
      Spline:=TFreeSpline.Create;
      FItems.Add(Spline);              // Read number of points for this spline
      Inc(LineNr);
      Str:=Strings[LineNr];
      M:=GetInteger(Str);              // Read actual 3D coordinates
      Spline.Capacity:=M;
      for J:=1 to M do begin
         Inc(LineNr);
         Str:=Strings[LineNr];
         P.X:=GetFloat(Str);
         P.Y:=GetFloat(Str);
         P.Z:=GetFloat(Str);
         Spline.Add(P);
         Spline.Knuckle[J-1]:=GetBoolean(Str);
      end;
   end;
   FBuild:=Count>0;
end;
procedure TFreeIntersection.SaveToStream(Strings:TStringList);
var I,J     : Integer;
    Spline  : TFreeSpline;
    P       : T3DVector;
begin
   Strings.Add(IntToStr(Ord(FIntersectionType))+#32+Truncate(FPlane.a,5)+#32+Truncate(FPlane.b,5)+#32+
               Truncate(FPlane.c,5)+#32+Truncate(FPlane.d,5)+#32+BoolToStr(FBuild)+#32+IntToStr(Count));
   for I:=1 to Count do begin
      Spline:=Items[I-1];
      Strings.Add(IntToStr(Spline.NumberOfPoints));
      for J:=1 to Spline.NumberOfPoints do begin
         P:=Spline.Point[J-1];
         Strings.Add(Truncate(P.X,4)+#32+Truncate(P.Y,4)+#32+Truncate(P.Z,4)+#32+BoolToStr(Spline.Knuckle[J-1]));
      end;
   end;
end;
//
//        TFreeVisibility
//
procedure TFreeVisibility.LoadFromStream(Var LineNr:Integer;Strings:TStringList);
var Str : String;
    I   : integer;
begin
   Inc(LineNr);
   Str:=Strings[LineNr];                            // Read model view
   I:=GetInteger(Str);
   FModelView:=TFreeModelView(I);                   // Read show controlnet
   FShowControlNet:=GetBoolean(Str);    // Read interior edges flag
   FShowInteriorEdges:=GetBoolean(Str); // Read show-stations flag
   FShowStations:=GetBoolean(Str);      // Read show-Buttocks flag
   FShowButtocks:=GetBoolean(Str);      // Read show-Waterlines flag
   FShowWaterlines:=GetBoolean(Str);
end;

procedure TFreeVisibility.SaveToStream(Strings:TStringList);
var Str:string;
begin
   Str:=IntToStr(Ord(FModelView))+#32+
        BoolToStr(FShowControlNet)+#32+
        BoolToStr(FShowInteriorEdges)+#32+
        BoolToStr(FShowStations)+#32+
        BoolToStr(FShowButtocks)+#32+
        BoolToStr(FShowWaterlines);
   Strings.Add(Str);
end;

