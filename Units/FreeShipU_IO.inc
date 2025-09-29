//
///*** Detect Minimal File Version depneding on features used
//
function TFreeShip.DetectMinFileVersion( isText: boolean ): TFreeFileVersion;
var I: integer;
begin result:=fv160;                           // с картинкой - никак не меньше
  if NumberOfDiagonals>0 then result:=fv180;
  if NumberOfMarkers>0   then result:=fv191;   // не очень надо,но пусть будет
  if ProjectSettings.FSavePreview then Result:=fv210;
  if (NumberOfbackgroundImages>0) or (NumberOfFlowlines>0) then result:=fv250;
  if not isText then                     // TFreeFileBuffer или TFreeTextBuffer
    for i:=0 to Surface.NumberOfLayers-1 do
      if Surface.Layer[i].AlphaBlend<255 then result:=fv260;
end;

Procedure TFreeShip.SaveProject( Destination:TFreeFileBuffer );
var PrevCursor: TCursor; I: integer;
begin
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   FileVersion:=DetectMinFileVersion( Destination is TFreeTextBuffer );
   Destination.Add( 'FREE!ship' );
   Destination.Add( FileVersion );
   Destination.Add( Ord(Precision) );
   Visibility.SaveBinary( Destination );
   ProjectSettings.SaveBinary( Destination ); // Save actual subdivision-surface data.
   Surface.SaveBinary( Destination );         // Save stations
   Destination.Add( NumberOfStations );
   For I:=1 to NumberOfStations do Station[I-1].SaveBinary(Destination); // Save Buttocks
   Destination.Add( NumberOfButtocks );
   For I:=1 to NumberOfButtocks do Buttock[I-1].SaveBinary(Destination); // Save Waterlines
   Destination.Add( NumberOfWaterlines );
   For I:=1 to NumberOfWaterlines do Waterline[I-1].SaveBinary(Destination);
   if FileVersion>=fv180 then begin                        // Save Diagonals
      Destination.Add( NumberOfDiagonals );
      For I:=1 to NumberOfDiagonals do Diagonal[I-1].SaveBinary(Destination);
      if FileVersion>=fv191 then begin                       // Save markers
         Destination.Add( NumberOfMarkers );
         for I:=1 to NumberOfMarkers do Marker[I-1].SaveBinary(Destination);
         if FileVersion>=fv210 then begin
     (*##*) Fillchar(FResistanceDelftData,SizeOf(FResistanceDelftData),0);     // чистка
     (*##*) Fillchar(FResistanceKaperData,SizeOf(TFreeKAPERResistanceData),0); // файла
            Destination.Add(FResistanceDelftData {,SizeOf(FResistanceDelftData)    } );
            Destination.Add(FResistanceKaperData {,SizeOf(TFreeKAPERResistanceData)} );
            if FileVersion>=fv250 then begin
               Destination.Add(NumberOfbackgroundImages);
               for I:=1 to NumberOfBackgroundImages do BackgroundImage[I-1].SaveBinary(Destination);
               Destination.Add(NumberOfFlowlines);
               for I:=1 to NumberOfFlowlines do Flowline[I-1].SaveBinary(Destination);
            end;
         end;
      end;
   end;
   FileChanged:=False;
   Screen.Cursor:=PrevCursor;
end;

// save as FREE!ship file without prompting for a filename (must already been set)

function TFreeEdit.File_Save: boolean;
var Str: AnsiString; Strings: TStringList=nil; Destination: TFreeFileBuffer;
begin Result:=false;
  if not Ship.FilenameSet // or Ship.FileIsReadOnl
     then begin Ship.FilenameSet:=false; result:=File_SaveAs; exit; end;
  DeleteFileUTF8( Ship.Filename+'.bak' );
  RenameFileUTF8( Ship.Filename,Ship.Filename+'.bak' );
  Str:=LowerCase( ExtractFileExt( Ship.Filename ) );
  if Str='.fbm' then Destination:=TFreeFileBuffer.Create else
  if Str='.ftm' then Destination:=TFreeTextBuffer.Create else
  if Str='.fef' then Strings:=TStringlist.Create;
  if Strings<>nil then begin
     Strings.Add( Ship.ProjectSettings.ProjectName );
     Strings.Add( Ship.ProjectSettings.ProjectDesigner );
     Strings.Add( Ship.ProjectSettings.ProjectFileCreatedBy );
     Strings.Add( Ship.ProjectSettings.ProjectComment );
     Strings.Add( Truncate(Ship.ProjectSettings.ProjectLength,4)
             +#32+Truncate(Ship.ProjectSettings.ProjectBeam,4)
             +#32+Truncate(Ship.ProjectSettings.ProjectDraft,4)
             +#32+Truncate(Ship.ProjectSettings.ProjectWaterDensity,5)
             +#32+Truncate(Ship.ProjectSettings.ProjectAppendageCoefficient,5)
             +#32+IntToStr(Ord(Ship.ProjectSettings.ProjectUnits))
//           +#32+BoolToStr(Ship.ProjectSettings.MainparticularsHasBeenset)
           +' 1 '+IntToStr(Ord(Ship.Precision)) );
     Ship.Surface.ExportFeFFile( Strings );
     Strings.SaveToFile( Ship.Filename );
     Strings.Destroy;
  end else begin
    Destination.Encoding:=Ship.Preferences.FbmEncoding;
    Ship.SaveProject( Destination );
    result:=Destination.SaveToFile( Ship.Filename );
    FreeAndNil( Destination );
  end;
  Ship.FileChanged:=false;
  Ship.Preferences.LastDirectory:=ExtractFilePath( Ship.FileName );
  AddToRecentFiles( Ship.FileName );
end;

const FileFilter = 'Free!Ship (*.ftm *.fbm *.fef)|*.ftm;*.fbm;*.fef'
                  +'|         <source types> (*.ftm)|*.ftm'
                  +'|            <binary files> (*.fbm)|*.fbm'
                  +'|    <обменный вид> (*.fef)|*.fef| All files (*.*)|*.*';

function TFreeEdit.File_SaveAs: boolean; var SaveDialog: TSaveDialog;
begin result:=false;
   SaveDialog:=TSaveDialog.Create( Ship );
   SaveDialog.InitialDir:=Ship.Preferences.SaveDirectory; //+ConfigDirectory
   Savedialog.FileName:=ExtractFilename( Ship.Filename );
   SaveDialog.Filter:=FileFilter;
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin WestPoint;
      Ship.Preferences.SaveDirectory:=ExtractFilePath( SaveDialog.FileName );
//    if CurrentVersion>Ship.FileVersion then Ship.StopAskingForFileVersion:=False;
      Ship.Filename:=Savedialog.Filename;
      Ship.FilenameSet:=True;
      Result:=File_Save;
      if Result then Ship.Preferences.LastDirectory:=ExtractFilePath(SaveDialog.FileName);
   end;
   SaveDialog.Destroy;
end;

procedure TFreeEdit.File_Load; var Answer: word; OpenDialog: TOpenDialog;
begin
  Ship.Edit.Selection_Clear;                        ///***  Selection_Clear
  OpenDialog:=TOpenDialog.Create( Ship );
  OpenDialog.InitialDir:=Ship.Preferences.OpenDirectory; //+ConfigDirectory
  OpenDialog.Filter:=FileFilter;
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
     Answer:=Ship.Edit.File_SaveCheck;
     if (Answer=mrCancel) or Ship.FileChanged then exit;
     File_Load( Opendialog.FileName );           // Load everything into memory
  end;
  Opendialog.Destroy;
end;

procedure TFreeEdit.File_Load( FileName: AnsiString );
var Source: TFreeFileBuffer; I,LineNR: Integer; Str: String;
    Strings: TStringList=nil;
begin
  if ExtractFileExt( FileName )=''
     then FileName:=ChangeFileExt( FileName,FreeShipExtention );
  Str:=LowerCase( ExtractFileExt( FileName ) );
  if Str='.fbm' then Source:=TFreeFileBuffer.Create else
  if Str='.ftm' then Source:=TFreeTextBuffer.Create else
  if Str='.fef' then Strings:=TStringList.Create else
       begin WriteLN( '...нет ftm,fbm или fef' ); exit; end;
//  Ship.Surface.Clearselection;               // Make sure no items are selected
//  Ship.Edit.Selection_Clear;
//  Ship.FSelectedFlowlines.Clear;
//  Ship.FSelectedMarkers.Clear;
//# Ship.ModelIsLoaded:=False;
//# Ship.FileIsReadOnly:=True;
  Ship.Clear;
  Ship.Filename:=FileName;
  if Strings<>nil then begin
    Strings.LoadFromFile( Filename );
    LineNr:=-1;  // Read general information and mainparticulars
    inc(LineNr); Ship.ProjectSettings.FProjectName:=Strings[LineNr];
    inc(LineNr); Ship.ProjectSettings.FProjectDesigner:=Strings[LineNr];
    inc(LineNr); Ship.ProjectSettings.FProjectFileCreatedBy:=Strings[LineNr];
    inc(LineNr); Ship.ProjectSettings.FProjectComment:=Strings[LineNr];
    Inc(LineNr); Str:=Strings[LineNr];
    Ship.ProjectSettings.ProjectLength:=ReadFloatfromStr(LineNr,Str);
    Ship.ProjectSettings.ProjectBeam:=ReadFloatfromStr(LineNr,Str);
    Ship.ProjectSettings.ProjectDraft:=ReadFloatfromStr(LineNr,Str);
    Ship.ProjectSettings.ProjectWaterDensity:=ReadFloatfromStr(LineNr,Str);
    Ship.ProjectSettings.ProjectAppendageCoefficient:=ReadFloatfromStr(LineNr,Str);
    I:=ReadIntfromStr(LineNr,Str);
    Ship.ProjectSettings.FProjectUnits:=TFreeUnitType(I);
   {Ship.ProjectSettings.FMainparticularsHasBeenset:=} ReadBoolfromStr(LineNr,Str);
    I:=ReadIntfromStr(LineNr,Str);
    Ship.FPrecision:=TFreePrecisionType(I);
    Ship.Surface.ImportFEFFile(Strings,LineNr);
    Strings.Destroy;
//  Ship.Build:=False;
//  Ship.RebuildModel;
    if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
  end else begin
    Source.LoadFromFile( FileName );
    Ship.LoadProject( Source );
    FreeAndNil( Source );
  end;
//if FileExistsUTF8( FreeShip.Filename ) then
//# Ship.FileIsReadOnly:=( FileGetAttr( FileName ) and faReadOnly )<>0;
  Ship.FilenameSet:=True;
//# Ship.StopAskingForFileVersion:=False;
//# Ship.ModelIsLoaded:=True;
//  Application.ProcessMessages;
  with Ship do begin
    ZoomFitAllViewports;
//  Surface.Rebuild;
    for I:=0 to NumberofBackgroundImages-1 do BackgroundImage[I].UpdateViews;
    Draw;
  end;
//#Ship.Edit.ProgressBar:=nil;
  if Ship.LinesplanFrame<>nil then
     TFreeLinesplanframe( Ship.LinesplanFrame ).FreeShip:=Ship;
//with TFreeLinesplanframe( FreeShip.LinesplanFrame ) do begin
//     Viewport.ZoomExtents; UpdateMenu; end;
 {#if Ship.ModelIsLoaded then} AddToRecentFiles( FileName );
                               Undo_Clear;
  Ship.FileChanged:=False;
end;

Procedure TFreeShip.LoadProject( Source:TFreeFileBuffer );        // LoadBinary
var PrevCursor  : TCursor;
    I,N         : Integer;
    Str         : AnsiString;
    Data        : TFreeBackgroundImageData;
    Intersection: TFreeIntersection;
    Flowline    : TFreeFlowline;
    Marker      : TFreeMarker;
begin    // Remember the filename because it will be erased by the clear method
   Str:=FFilename;
   Clear;
   FFilename:=Str;
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
// try
   Source.Reset;
   Source.Encoding:=Preferences.FbmEncoding;
   Source.LoadString(Str);
   if Str='FREE!ship' then begin
      Source.LoadTFreeFileVersion(FFileVersion);
      Source.Version:=FFileVersion;
//    if (FFileVersion<=CurrentVersion)
//    or (FFileVersion<=High(FFileVersion)) then
      begin
         Write( '[',FFileVersion,'] ',ExtractFilename( FFilename ) );
         Source.LoadInteger(I);
         FPrecision:=TFreePrecisionType(I);
         Visibility.LoadBinary(Source);
         ProjectSettings.LoadBinary(Source,nil);
      // Load actual subdivision-surface data.
         Surface.LoadBinary(Source);
      // Load stations
         Source.LoadInteger(N);
         FStations.Capacity:=N;
         for I:=1 to N do begin
             Intersection:=TFreeIntersection.Create(self);
             FStations.Add(Intersection);
             Intersection.LoadBinary(Source);
         end;
      // Load Buttocks
         Source.LoadInteger(N);
         FButtocks.Capacity:=N;
         for I:=1 to N do begin
             Intersection:=TFreeIntersection.Create(self);
             FButtocks.Add(Intersection);
             Intersection.LoadBinary(Source);
         end;
         // Load Waterlines
         Source.LoadInteger(N);
         FWaterlines.Capacity:=N;
         for I:=1 to N do begin
             Intersection:=TFreeIntersection.Create(self);
             FWaterlines.Add(Intersection);
             Intersection.LoadBinary(Source);
         end;
         if FileVersion>=fv180 then begin                  // Load Diagonals
            Source.LoadInteger(N);
            FDiagonals.Capacity:=N;
            for I:=1 to N do begin
                Intersection:=TFreeIntersection.Create(self);
                FDiagonals.Add(Intersection);
                Intersection.LoadBinary(Source);
            end;
            if FileVersion>=fv191 then begin                 // Load markers
               Source.LoadInteger(N);
               FMarkers.Capacity:=N;
               for I:=1 to N do begin
                   Marker:=TFreeMarker.Create;
                   Marker.FOwner:=Self;
                   Edit.Marker_Add(Marker);
                   Marker.LoadBinary(Source);
               end;
               if FileVersion>=fv210 then begin
                  Source.LoadTFreeDelftSeriesResistanceData(FResistanceDelftData ); //,SizeOf(FResistanceDelftData));
                  Source.LoadTFreeKAPERResistanceData(FResistanceKaperData ); // ,SizeOf(TFreeKAPERResistanceData));
                  if FileVersion>=fv250 then begin
                     Source.LoadInteger(N);
                     for I:=1 to N do begin
                         Data:=TFreeBackgroundImageData.Create(self);
                         FBackgroundImages.Add(data);
                         Data.LoadBinary(Source);
                     end;
                     Source.LoadInteger(N);
                     FFlowlines.Capacity:=N;
                     for I:=1 to N do begin
                         Flowline:=TFreeFlowline.Create(self);
                         FFlowlines.Add(Flowline);
                         Flowline.LoadBinary(Source);
                     end;
                  end {fv250};
               end    {fv210};
            end       {fv191};
         end          {fv180};
      end; // else ShowMessage( Userstring(113)+eol+UserString(188)+'.' );
      FileVersion:=fv260;
      WriteLn( '.' );
   end else ShowMessage( Userstring(189) );

   FileChanged:=False;
   Surface.DesiredSubdivisionLevel:=Ord(Precision)+1;
// Surface.Rebuild;
   Screen.Cursor:=PrevCursor;
// for I:=1 to NumberofBackgroundImages do BackgroundImage[I-1].UpdateViews;
   if Assigned(OnUpdateGeometryInfo) then OnUpdateGeometryInfo(self);
end;


