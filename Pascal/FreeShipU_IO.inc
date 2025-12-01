{
  included in FreeShipUnit
}
//*** Detect Minimal File Version depneding on features used

function TFreeShip.DetectMinFileVersion( isText: boolean ): TFreeFileVersion;
var I: integer;      // 160 => если с картинкой - и хотелось бы никак не меньше
begin result:=fv165; // в оригинале ошибка на версии 165 = всё должно быть выше
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
   Destination.Add( Ord( Precision ) );
   Visibility.SaveBinary( Destination );
   ProjectSettings.SaveBinary( Destination );// actual subdivision-surface data
   Surface.SaveBinary( Destination );        // Save stations
   Destination.Add( NumberOfStations );
   For I:=1 to NumberOfStations do Station[I-1].SaveBinary(Destination); // Save Buttocks
   Destination.Add( NumberOfButtocks );
   For I:=1 to NumberOfButtocks do Buttock[I-1].SaveBinary(Destination); // Save Waterlines
   Destination.Add( NumberOfWaterlines );
   For I:=1 to NumberOfWaterlines do Waterline[I-1].SaveBinary(Destination);
   if FileVersion>=fv180 then begin                           // Save Diagonals
      Destination.Add( NumberOfDiagonals );
      For I:=1 to NumberOfDiagonals do Diagonal[I-1].SaveBinary(Destination);
      if FileVersion>=fv191 then begin                          // Save markers
         Destination.Add( NumberOfMarkers );
         for I:=1 to NumberOfMarkers do Marker[I-1].SaveBinary(Destination);
         if FileVersion>=fv210 then begin     // пропускается и не используется
            if Destination is TFreeTextBuffer then I:=0 else I:=1; {112 или 29}
            while I<=28 do begin Destination.Add( integer( 0 ) ); inc( I ) end;
//          for I:=1 to 17 do Destination.Add(0); +2b (+2) // Delft
//          for I:=1 to 9 do Destination.Add(0);  +1b (+3) // Kaper
            if FileVersion>=fv250 then begin
               Destination.Add(NumberOfbackgroundImages);
               for I:=1 to NumberOfBackgroundImages do BackgroundImage[I-1].SaveBinary(Destination);
               Destination.Add(NumberOfFlowlines);
               for I:=1 to NumberOfFlowlines do Flowline[I-1].SaveBinary(Destination);
            end;
         end;
      end;
   end; FileChanged:=False; Screen.Cursor:=PrevCursor;
end;

// save as FREE!ship file without prompting for a filename (must already been set)

function TFreeEdit.File_Save: boolean;
var Str: String; Strings: TStringList=nil; Destination: TFreeFileBuffer;
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
     Strings.Add( FloatToDec(Ship.ProjectSettings.ProjectLength,4)
             +#32+FloatToDec(Ship.ProjectSettings.ProjectBeam,4)
             +#32+FloatToDec(Ship.ProjectSettings.ProjectDraft,4)
             +#32+FloatToDec(Ship.ProjectSettings.ProjectWaterDensity,5)
             +#32+FloatToDec(Ship.ProjectSettings.ProjectAppendageCoefficient,5)
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

const FileFilter = 'Free!Ship [*.ftm *.fbm *.fef]|*.ftm;*.fbm;*.fef'
                  +'|         <source types> [*.ftm]|*.ftm'
                  +'|            <binary files> [*.fbm]|*.fbm'
                  +'|    <обменный вид> [*.fef]|*.fef| All files [*.*]|*.*';

function TFreeEdit.File_SaveAs: boolean; var SaveDialog: TSaveDialog;
begin result:=false;
   SaveDialog:=TSaveDialog.Create( Ship );
   SaveDialog.InitialDir:=Ship.Preferences.SaveDirectory;
   Savedialog.FileName:=ExtractFilename( Ship.Filename );
   SaveDialog.Filter:=FileFilter;
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin WestPoint;
      Ship.Preferences.SaveDirectory:=SaveDialog.InitialDir;
      Ship.Filename:=Savedialog.Filename;
      Ship.FilenameSet:=True;
      Result:=File_Save;
      if Result then Ship.Preferences.LastDirectory:=ExtractFilePath(SaveDialog.FileName);
   end;
   SaveDialog.Destroy;
end;

procedure TFreeEdit.File_Load; var Answer: word; OpenDialog: TOpenDialog;
begin
  Ship.Edit.Selection_Clear; ///*** Selection_Clear
  OpenDialog:=TOpenDialog.Create( Ship );
  OpenDialog.InitialDir:=Ship.Preferences.OpenDirectory; //+ ConfigDirectory
  OpenDialog.Filter:=FileFilter;
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
     Answer:=Ship.Edit.File_SaveCheck;
     if (Answer=mrCancel) or Ship.FileChanged then exit;
     File_Load( Opendialog.FileName );           // Load everything into memory
     Ship.Preferences.OpenDirectory:=OpenDialog.InitialDir;
  end;
  Opendialog.Destroy;
end;

procedure TFreeEdit.File_Load( FileName: String );
var Source: TFreeFileBuffer; I,LineNR: Integer; Str: String;
    Strings: TStringList=nil;
begin Source:=nil; Strings:=nil;
  if ExtractFileExt( FileName )=''
     then FileName:=ChangeFileExt( FileName,FreeShipExtention );
  Str:=LowerCase( ExtractFileExt( FileName ) );
  if Str='.fbm' then Source:=TFreeFileBuffer.Create else
  if Str='.ftm' then Source:=TFreeTextBuffer.Create else
  if Str='.fef' then Strings:=TStringList.Create else
       begin WriteLN( '...нет ftm,fbm или fef' ); exit; end;
  Ship.Clear;
  Ship.Filename:=FileName;
  if Strings<>nil then begin   // обменный формат из начальных версий Free!Ship
    Strings.LoadFromFile( Filename );
    LineNr:=-1;                 // Read general information and mainparticulars
    inc(LineNr); Ship.ProjectSettings.FProjectName:=Strings[LineNr];
    inc(LineNr); Ship.ProjectSettings.FProjectDesigner:=Strings[LineNr];
    inc(LineNr); Ship.ProjectSettings.FProjectFileCreatedBy:=Strings[LineNr];
    inc(LineNr); Ship.ProjectSettings.FProjectComment:=Strings[LineNr];
    Inc(LineNr); Str:=Strings[LineNr];
    Ship.ProjectSettings.ProjectLength:=GetFloat(Str);
    Ship.ProjectSettings.ProjectBeam:=GetFloat(Str);
    Ship.ProjectSettings.ProjectDraft:=GetFloat(Str);
    Ship.ProjectSettings.ProjectWaterDensity:=GetFloat(Str);
    Ship.ProjectSettings.ProjectAppendageCoefficient:=GetFloat(Str);
    I:=GetInteger(Str);
    Ship.ProjectSettings.FProjectUnits:=TFreeUnitType(I);
   {Ship.ProjectSettings.FMainparticularsHasBeenset:=} GetBoolean(Str);
    I:=GetInteger(Str);
    Ship.FPrecision:=TFreePrecisionType(I);
    Ship.Surface.ImportFEFFile(Strings,LineNr);
    Strings.Destroy;
    Drawing;
  end else begin
    Source.LoadFromFile( FileName );
    Ship.LoadProject( Source );
    FreeAndNil( Source );
  end;
  Ship.FilenameSet:=True;
  with Ship do begin
    ZoomFitAllViewports; // Surface.Rebuild;
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
var PrevCursor: TCursor; I,N: Integer; Str: String;               // WW:Real;
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
         Surface.LoadBinary(Source); // Load actual subdivision-surface data.
         Source.LoadInteger(N);      // Load stations
         FStations.Capacity:=N;
         for I:=1 to N do begin
             Intersection:=TFreeIntersection.Create(self);
             FStations.Add(Intersection);
             Intersection.LoadBinary(Source);
         end;
         Source.LoadInteger(N);      // Load Buttocks
         FButtocks.Capacity:=N;
         for I:=1 to N do begin
             Intersection:=TFreeIntersection.Create(self);
             FButtocks.Add(Intersection);
             Intersection.LoadBinary(Source);
         end;
         Source.LoadInteger(N);      // Load Waterlines
         FWaterlines.Capacity:=N;
         for I:=1 to N do begin
             Intersection:=TFreeIntersection.Create(self);
             FWaterlines.Add(Intersection);
             Intersection.LoadBinary(Source);
         end;
         if FileVersion>=fv180 then begin // Load Diagonals
            Source.LoadInteger(N);
            FDiagonals.Capacity:=N;
            for I:=1 to N do begin
                Intersection:=TFreeIntersection.Create(self);
                FDiagonals.Add(Intersection);
                Intersection.LoadBinary(Source);
            end;
            if FileVersion>=fv191 then begin // Load markers
               Source.LoadInteger(N);
               FMarkers.Capacity:=N;
               for I:=1 to N do begin
                   Marker:=TFreeMarker.Create;
                   Marker.FOwner:=Self;
                   Edit.Marker_Add(Marker);
                   Marker.LoadBinary(Source);
               end;
               if FileVersion>=fv210 then begin
                  if Source is TFreeTextBuffer
                  then (Source as TFreeTextBuffer).FPosition+=29  // 9+1 + 17+2
                   else Source.FPosition += 112;     // = Delft(72) + Kaper(40)
                  if FileVersion>=fv250 then begin
                     Source.LoadInteger( N );
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

// автоматическое формирование теоретических контуров

procedure TFreeEdit.Drawing;
Var D,DD:Real; I: Integer;
begin with Ship.ProjectSettings do begin
   dd:=AxisStep( (Ship.Surface.Max.X-Ship.Surface.Min.X)/5.75 ); // шаг шпации
   I:=round( Ship.Surface.Min.X/dd+0.5 );
   repeat Intersection_Add( fiStation,I*dd ); inc( I );         // и шпангоуты
   until I*dd>=Ship.Surface.Max.X;
   dd:=AxisStep( ProjectBeam/1.75 ); I:=0;                      // Батоксы
   repeat Intersection_Add( fiButtock,I*dd ); inc( I ); until I*dd>=ProjectBeam-dd/4;
   dd:=AxisStep( Ship.Surface.Max.Z-Ship.Surface.Min.Z );       // Ватерлинии
   I:=round( Ship.Surface.Min.Z/dd+0.51 );
   repeat Intersection_Add( fiWaterline,I*dd ); inc( I );
   until I*dd>=Ship.Surface.Max.Z-dd*0.25;
   D:=round( ProjectDraft/dd/2+0.51 );              // по паре на обе стороны =
   for I:=0 to 4 do Intersection_Add( fiDiagonal,D+(I-2)*dd ); // пять рыбин
   SavePreview:=false;                              // без предпросмотра
   Ship.FileChanged:=True;
   Ship.Visibility.ModelView:=mvBoth;               // на оба борта
   Ship.Visibility.ShowControlNet:=false;           // без выделения узлов
   Ship.Visibility.ShowInteriorEdges:=True;         // внутрення разбивка рёбер
   Ship.ProjectSettings.SavePreview:=false;
   if Assigned(Ship.OnUpdateGeometryInfo) then Ship.OnUpdateGeometryInfo(self);
   // Ship.Build:=False;
   // Ship.RebuildModel;
end end;
//
//    Выбор корабельной эпохи:
//
//    Великие географические открытия
//
const
 File_A='Галеон Великих Испанских географических открытий';
 Name_A='«Великие географические открытия». Корпус всепогодного корабля среднего водоизмещения (галеон)';
 Comm_A='Вариант эволюционного совершенствования корабельных обводов с уверенным штормованием в эпоху Великих Испанских географических открытий.';
 Ship_A: array [0..6,0..4] of Vector=
{$if false}
 ( ( ( x: 0.06; y:0;    z:0    ),  // station 0,stern=Галеон
     ( x: 0.02; y:0;    z:1.75 ),
     ( x:-0.04; y:0.1;  z:2.1  ),
     ( x:-0.04; y:0.125;z:2.5  ),
     ( x:-0.03; y:0.11; z:5.3  ) ),
   ( ( x: 0.2;  y:0;    z:0    ),  // station 1
     ( x: 0.18; y:0.12; z:1    ),
     ( x: 0.17; y:0.27; z:1.5  ),
     ( x: 0.16; y:0.28; z:2.5  ),
     ( x: 0.16; y:0.29; z:4.9  ) ),
   ( ( x: 0.4;  y:0;    z:0    ),  // station 2
     ( x: 0.4;  y:0.2;  z:0.2  ),
     ( x: 0.4;  y:0.43; z:1    ),
     ( x: 0.4;  y:0.37; z:2.2  ),
     ( x: 0.4;  y:0.38; z:3.8  ) ),
   ( ( x: 0.6;  y:0;    z:0    ),  // station 3
     ( x: 0.6;  y:0.22; z:0.1  ),
     ( x: 0.6;  y:0.45; z:0.9  ),
     ( x: 0.6;  y:0.4;  z:2.2  ),
     ( x: 0.6;  y:0.4;  z:3.6  ) ),
   ( ( x: 0.8;  y:0;    z:0    ),  // station 4
     ( x: 0.8;  y:0.2;  z:0.5  ),
     ( x: 0.8;  y:0.24; z:1.2  ),
     ( x: 0.8;  y:0.3;  z:2.5  ),
     ( x: 0.8;  y:0.368;z:3.8  ) ),
   ( ( x: 0.93; y:0;    z:0.15 ),  // station 5
     ( x: 0.93; y:0.05; z:1    ),
     ( x: 0.93; y:0.075;z:2    ),
     ( x: 0.93; y:0.125;z:3    ),
     ( x: 0.95; y:0.2;  z:4    ) ),
   ( ( x: 1.018;y:0;    z:1    ),  // station 6,stem
     ( x: 1.008;y:0;    z:1.75 ),
     ( x: 1;    y:0;    z:2.5  ),
     ( x: 0.998;y:0;    z:3.25 ),
     ( x: 0.998;y:0;    z:4    ) ) );
{$else} // вариант со сниженной высотой борта в средней части корпуса
 ( ( ( x: 0.06; y:0;    z:0    ),  // station 0,stern=Галеон
     ( x: 0.02; y:0;    z:1.75 ),
     ( x:-0.04; y:0.1;  z:2.1  ),
     ( x:-0.04; y:0.125;z:2.5  ),
     ( x:-0.03; y:0.11; z:5.3  ) ),
   ( ( x: 0.2;  y:0;    z:0    ),  // station 1
     ( x: 0.18; y:0.12; z:1    ),
     ( x: 0.17; y:0.27; z:1.5  ),
     ( x: 0.16; y:0.28; z:2.5  ),
     ( x: 0.16; y:0.29; z:5.1  ) ),
   ( ( x: 0.4;  y:0;    z:0    ),  // station 2
     ( x: 0.4;  y:0.2;  z:0.2  ),
     ( x: 0.4;  y:0.43; z:1    ),
     ( x: 0.4;  y:0.37; z:2.2  ),
     ( x: 0.4;  y:0.38; z:3.9  ) ),
   ( ( x: 0.6;  y:0;    z:0    ),  // station 3
     ( x: 0.6;  y:0.22; z:0.1  ),
     ( x: 0.6;  y:0.45; z:0.9  ),
     ( x: 0.6;  y:0.4;  z:2.2  ),
     ( x: 0.6;  y:0.4;  z:3.3  ) ),
   ( ( x: 0.8;  y:0;    z:0    ),  // station 4
     ( x: 0.8;  y:0.15; z:0.5  ),
     ( x: 0.8;  y:0.24; z:1.2  ),
     ( x: 0.8;  y:0.32; z:2.5  ),
     ( x: 0.8;  y:0.368;z:3.6  ) ),
   ( ( x: 0.93; y:0;    z:0.15 ),  // station 5
     ( x: 0.93; y:0.05; z:1    ),
     ( x: 0.93; y:0.11; z:2    ),
     ( x: 0.93; y:0.16; z:3    ),
     ( x: 0.95; y:0.2;  z:4    ) ),
   ( ( x: 1.018;y:0;    z:1    ),  // station 6,stem
     ( x: 1.008;y:0;    z:1.75 ),
     ( x: 1;    y:0;    z:2.5  ),
     ( x: 0.998;y:0;    z:3.25 ),
     ( x: 0.998;y:0;    z:4    ) ) );
{$endif}
//
//   Новый корабль золотого XIX века
//
 File_B='Совершенный парусный корабль золотого XIX века';
 Name_B='«Новый корабль золотого XIX века». Корпус всепогодного корабля среднего водоизмещения (фрегат)';
 Comm_B='Вариант эволюции корабельных обводов с достижением наилучшей штормовой ходкости при совершенном парусном вооружении.';
 Ship_B: array [0..6,0..4] of Vector=
 ( ( ( x: 0.06; y:0;    z:0    ),  // station 0,stern=Фелюга
     ( x: 0.04; y:0;    z:1.3  ),
     ( x:-0.006;y:0;    z:1.5  ),
     ( x:-0.01; y:0.3;  z:2.5  ),
     ( x:-0.01; y:0.3;  z:3.6  ) ),
   ( ( x: 0.2;  y:0;    z:0    ),  // station 1
     ( x: 0.18; y:0.15; z:0.9  ),
     ( x: 0.17; y:0.34; z:1.2  ),
     ( x: 0.16; y:0.44; z:2    ),
     ( x: 0.16; y:0.42; z:3.45 ) ),
   ( ( x: 0.4;  y:0;    z:0    ),  // station 2
     ( x: 0.4;  y:0.32; z:0.3  ),
     ( x: 0.4;  y:0.45; z:0.6  ),
     ( x: 0.4;  y:0.5;  z:2    ),
     ( x: 0.4;  y:0.45; z:3.4  ) ),
   ( ( x: 0.6;  y:0;    z:0    ),  // station 3
     ( x: 0.6;  y:0.32; z:0.3  ),
     ( x: 0.6;  y:0.45; z:0.6  ),
     ( x: 0.6;  y:0.5;  z:2.1  ),
     ( x: 0.6;  y:0.45; z:3.5  ) ),
   ( ( x: 0.8;  y:0;    z:0    ),  // station 4
     ( x: 0.8;  y:0.12; z:0.5  ),
     ( x: 0.8;  y:0.2;  z:1    ),
     ( x: 0.8;  y:0.36; z:2.3  ),
     ( x: 0.8;  y:0.42; z:3.8  ) ),
   ( ( x: 0.93; y:0;    z:0.15 ),  // station 5
     ( x: 0.93; y:0.05; z:0.95 ),
     ( x: 0.93; y:0.1;  z:1.9  ),
     ( x: 0.93; y:0.18; z:2.85 ),
     ( x: 0.95; y:0.26; z:3.95 ) ),
   ( ( x: 1.018;y:0;    z:1    ),  // station 6,stem
     ( x: 1.008;y:0;    z:1.75 ),
     ( x: 1;    y:0;    z:2.5  ),
     ( x: 0.998;y:0;    z:3.25 ),
     ( x: 0.998;y:0;    z:4    ) ) );
//
//   Чудо в перьях научно-технической революции
//
 File_C='Эстетика современных обводов корабля';
 Name_C='Обводы быстроходного высокоманевренного корабля среднего водоизмещения с мощными машинами';
 Comm_C='Корабль с проектной отработкой элементов технической эстетики с испытаниями только под скоростной тележкой опытового бассейна.';
 Ship_C: array [0..6,0..4] of Vector=
 ( ( ( x: 0.1;   y: 0    ; z: 0     ),     // 0,stern 3 1 =Moдняга
     ( x: 0.06;  y: 0    ; z: 1.1   ),     //         1 1
     ( x:-0.025; y: 0.05 ; z: 1.4   ),     //         1 1
     ( x:-0.03;  y: 0.4  ; z: 1.5   ),     //         1 1
     ( x:-0.06 ; y: 0.5  ; z: 3.6   ) ),   //         3 1
   ( ( x: 0.2;   y: 0    ; z: 0     ),     // 1       1 1
     ( x: 0.19;  y: 0.14 ; z: 0.6   ),     //         0 1
     ( x: 0.17;  y: 0.38 ; z: 1.1   ),     //         0 1
     ( x: 0.16;  y: 0.48 ; z: 2     ),     //         0 1
     ( x: 0.16;  y: 0.533; z: 3.451 ) ),   //         1 1
   ( ( x: 0.38;  y: 0    ; z: 0     ),     // 2       1 1
     ( x: 0.37;  y: 0.3  ; z: 0.3   ),     //         0 1
     ( x: 0.36;  y: 0.45 ; z: 0.6   ),     //         0 1
     ( x: 0.36;  y: 0.5  ; z: 2     ),     //         0 1
     ( x: 0.36;  y: 0.533; z: 3.399 ) ),   //         1 1
   ( ( x: 0.56;  y: 0    ; z: 0     ),     // 3       1 1
     ( x: 0.55;  y: 0.3  ; z: 0.2   ),     //         0 1
     ( x: 0.55;  y: 0.48;  z: 0.6   ),     //         0 1
     ( x: 0.55;  y: 0.51 ; z: 2     ),     //         0 1
     ( x: 0.55;  y: 0.533; z: 3.461 ) ),   //         1 1
   ( ( x: 0.78;  y: 0    ; z:-0.2   ),     // 4       1 1
     ( x: 0.77;  y: 0.04 ; z: 0.25  ),     //         0 1
     ( x: 0.76;  y: 0.12 ; z: 0.5   ),     //         0 1
     ( x: 0.76;  y: 0.4  ; z: 2     ),     //         0 1
     ( x: 0.76;  y: 0.525; z: 3.669 ) ),   //         1 1
   ( ( x: 0.94;  y: 0    ; z:-1     ),     // 5       1 1
     ( x: 0.979; y: 0.075; z:-1     ),     //         0 1
     ( x: 0.927; y: 0.025; z: 0.5   ),     //         0 1
     ( x: 0.927; y: 0.1  ; z: 2     ),     //         0 1
     ( x: 0.987; y: 0.362; z: 4.27  ) ),   //         1 1
   ( ( x: 0.980; y: 0    ; z:-1     ),     // 6,stem  1 1
     ( x: 1.031; y: 0    ; z:-0.41  ),     //         1 1
     ( x: 0.961; y: 0    ; z: 0.61  ),     //         1 1
     ( x: 1    ; y: 0    ; z: 2     ),     //         1 1
     ( x: 1.1  ; y: 0    ; z: 4.55  ) ) ); //         3 1

function TFreeEdit.Model_New:Boolean;
var Answer: word; I,J,Cols,Rows: integer;
    L,B,D,dd: Real; P: Vector;
    Spline1,Spline2: TFreeSpline;
    TrvSplines: TFasterList;
    Pts: array of array of TFreeSubdivisionControlPoint;
    StemPoint: TFreeSubdivisionControlPoint;
    FreeNewModelDialog: TFreeNewModelDialog;
begin
   Result:=False;               // Apparently saving was not successfull, abort
   Answer:=Ship.Edit.File_SaveCheck;
   if (Answer=mrCancel) or Ship.FileChanged then exit;
   FreeNewModelDialog:=TFreeNewModelDialog.Create(Ship);
   ShowTranslatedValues(FreeNewModelDialog);
   if FreeNewModelDialog.Execute then begin
      CreateUndoObject(Userstring(157),True);
      Cols:=FreeNewModelDialog.NCols-1;
      Rows:=FreeNewModelDialog.NRows-1;
      L:=FreeNewModelDialog.Length;
      B:=FreeNewModelDialog.Breadth;
      D:=FreeNewModelDialog.Draft/2;
      Ship.Clear;
      with Ship.ProjectSettings do begin                       // «Free!Ship»
        case FreeNewModelDialog.ShipBox.ItemIndex of
          0: begin Ship.FileName:=File_A;
                   FProjectName:=Name_A;
                   FProjectComment:=Comm_A; end;
          1: begin Ship.FileName:=File_B;
                   FProjectName:=Name_B;
                   FProjectComment:=Comm_B; end;
          2: begin Ship.FileName:=File_C;
                   FProjectName:=Name_C;
                   FProjectComment:=Comm_C; end;
        end;
        FProjectName:='«'+ChangeFileExt(ExtractFilename(Ship.FileName),'')+'». '+FProjectName;
        FProjectDesigner:='Подсекция штормовой мореходности, Научно-инженерное общество корабелов им.А.Н.Крылова';
        FProjectFileCreatedBy:='©'+TimeString+' Free!Ship example'; //, № '+inttostr( FreeNewModelDialog.ShipBox.ItemIndex+1); // FormatDateTime('YYYY-MM-DD_hh:nn',Now );
        ProjectLength:=L;
        ProjectBeam:=B;
        ProjectDraft:=D*2;
        ProjectUnderWaterColorAlpha:=128;
        ProjectUnits:=TFreeUnitType(FreeNewModelDialog.ComboBox1.ItemIndex);
      End;
      TrvSplines:=TFasterList.Create;
      StemPoint:=nil;      // First create tmp. splines in transverse direction
      for I:=0 to 6 do begin
         Spline1:=TFreeSpline.Create;
         for J:=0 to 4 do begin
            case FreeNewModelDialog.ShipBox.ItemIndex of
              0: P:=Ship_A[I,J];
              1: P:=Ship_B[I,J];
              2: P:=Ship_C[I,J];
            end;
            P.X:=P.X*L;
            P.Y:=P.Y*B;
            P.Z:=P.Z*D;
            Spline1.Add( P );
         end;
         TrvSplines.Add( Spline1 );
      end;                 // now create tmp. splines in longitudinal direction
      Setlength( Pts,Rows+1 );
      for I:=0 to rows do begin
         Setlength(Pts[I],Cols+1);
         Spline2:=TFreeSpline.Create;
         for j:=0 to TrvSplines.Count-1 do begin
            Spline1:=TrvSplines[J];
            P:=Spline1.Value(I/Rows);
            Spline2.Add(P);
         end; // now calculate all points on longitudinal spline and send it to surface
         for J:=0 to Cols do begin
            P:=Spline2.Value( J/Cols );
            Pts[I,J]:=TFreeSubdivisionControlPoint.Create(Ship.Surface);
            Ship.Surface.AddControlPoint(Pts[I,J]);
            Pts[I,J].Coordinate:=P;
            if (I=0) and (J=Cols) then StemPoint:=Pts[I,J];
         end;
         Spline2.Destroy;
      end;                                               // Destroy tmp splines
      for I:=1 to TrvSplines.Count do begin
         Spline1:=TrvSplines[I-1];
         Spline1.Destroy;
      end;
      TrvSplines.Clear; // finally create controlfaces over newly calculated points
      for I:=1 to Rows do
      for J:=1 to cols do begin
          TrvSplines.Clear;
          Trvsplines.Add(Pts[I,J-1]);
          Trvsplines.Add(Pts[I,J]);
          Trvsplines.Add(Pts[I-1,J]);
          Trvsplines.Add(Pts[I-1,J-1]);
          Ship.Surface.AddControlFace(Trvsplines,True);
      end;
      Ship.Precision:=fpMedium;
      Ship.Surface.Initialize(1,1,1);
      Ship.ActiveLayer.Name:=Userstring(179); // Обводы и общекорабельная архитектура
      // Collapse stempoint to mage the grid irregular in order to demonstrate subdivision-surface capabilities
      if StemPoint<>nil then if StemPoint.VertexType=svCorner then stempoint.VertexType:=svCrease;
      TrvSplines.Destroy;
      Ship.Build:=False;
      Drawing;
      Ship.draw;
      Result:=true;
//      Ship.ZoomFitAllViewports;
//      Ship.ReDraw;
   end;
   FreeNewModelDialog.Destroy;
end;

