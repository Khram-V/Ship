{
  included in ShipUnit
}
//*** Detect Minimal File Version depneding on features used

function TShip.DetectMinFileVersion( isText: boolean ): TFileVersion;
var I: integer;      // 160 => если с картинкой - и хотелось бы никак не меньше
begin result:=fv165; // в оригинале ошибка на версии 165 = всё должно быть выше
  if NoDiagonals>0 then result:=fv180;
  if NoMarkers>0   then result:=fv191;   // не очень надо,но пусть будет
  if ProjectSettings.FSavePreview then Result:=fv210;
  if (NobackgroundImages>0) or (NoFlowlines>0) then result:=fv250;
  if not isText then                     // TFileBuffer или TTextBuffer
    for i:=0 to Surface.NoLayers-1 do
      if Surface.Layer[i].AlphaBlend<255 then result:=fv260;
end;

Procedure TShip.SaveProject( Destination:TFileBuffer );
var PrevCursor: TCursor; I: integer;
begin
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   FileVersion:=DetectMinFileVersion( Destination is TTextBuffer );
   Destination.Add( 'FREE!ship' );
   Destination.Add( FileVersion );
   Destination.Add( Ord( Precision ) );
   Visibility.SaveBinary( Destination );
   ProjectSettings.SaveBinary( Destination );// actual subdivision-surface data
   Surface.SaveBinary( Destination );        // Save stations
   Destination.Add( NoStations );
   For I:=1 to NoStations do Station[I-1].SaveBinary(Destination); // Save Buttocks
   Destination.Add( NoButtocks );
   For I:=1 to NoButtocks do Buttock[I-1].SaveBinary(Destination); // Save Waterlines
   Destination.Add( NoWaterlines );
   For I:=1 to NoWaterlines do Waterline[I-1].SaveBinary(Destination);
   if FileVersion>=fv180 then begin                           // Save Diagonals
      Destination.Add( NoDiagonals );
      For I:=1 to NoDiagonals do Diagonal[I-1].SaveBinary(Destination);
      if FileVersion>=fv191 then begin                          // Save markers
         Destination.Add( NoMarkers );
         for I:=1 to NoMarkers do Marker[I-1].SaveBinary(Destination);
         if FileVersion>=fv210 then begin     // пропускается и не используется
            if Destination is TTextBuffer then I:=0 else I:=1; {112 или 29}
            while I<=28 do begin Destination.Add( integer( 0 ) ); inc( I ) end;
//          for I:=1 to 17 do Destination.Add(0); +2b (+2) // Delft
//          for I:=1 to 9 do Destination.Add(0);  +1b (+3) // Kaper
            if FileVersion>=fv250 then begin
               Destination.Add(NobackgroundImages);
               for I:=1 to NoBackgroundImages do BackgroundImage[I-1].SaveBinary(Destination);
               Destination.Add(NoFlowlines);
               for I:=1 to NoFlowlines do Flowline[I-1].SaveBinary(Destination);
            end;
         end;
      end;
   end; FileChanged:=False; Screen.Cursor:=PrevCursor;
end;

// save as !St file without prompting for a filename (must already been set)

function SEdit.File_Save: boolean;
var Str: String; Strings: TStringList=nil; Destination: TFileBuffer;
begin Result:=false; Strings:=nil;
  if not St.FilenameSet // or St.FileIsReadOnl
    then begin St.FilenameSet:=false; result:=File_SaveAs; exit; end;
  DeleteFileUTF8( St.Filename+'.bak' );
  RenameFileUTF8( St.Filename,St.Filename+'.bak' );
  Str:=LowerCase( ExtractFileExt( St.Filename ) );
  if Str='.fbm' then Destination:=TFileBuffer.Create else
  if Str='.ftm' then Destination:=TTextBuffer.Create else
  if Str='.fef' then Strings:=TStringlist.Create;
  if Strings<>nil then begin
     Strings.Add( St.ProjectSettings.ProjectName );
     Strings.Add( St.ProjectSettings.ProjectDesigner );
     Strings.Add( St.ProjectSettings.ProjectFileCreatedBy );
     Strings.Add( St.ProjectSettings.ProjectComment );
     Strings.Add( FloatToDec(St.ProjectSettings.ProjectLength,4)
             +#32+FloatToDec(St.ProjectSettings.ProjectBeam,4)
             +#32+FloatToDec(St.ProjectSettings.ProjectDraft,4)
             +#32+FloatToDec(St.ProjectSettings.ProjectWaterDensity,5)
             +#32+FloatToDec(St.ProjectSettings.ProjectAppendageCoefficient,5)
             +#32+IntToStr(Ord(St.ProjectSettings.ProjectUnits))
//           +#32+BoolToStr(St.ProjectSettings.MainparticularsHasBeenset)
             +' 1 '+IntToStr( Ord( St.Precision ) ) );
     St.Surface.ExportFeFFile( Strings );
     Strings.SaveToFile( St.Filename );
     Strings.Destroy;
  end else begin
    St.SaveProject( Destination );
    result:=Destination.SaveToFile( St.Filename );
    FreeAndNil( Destination );
  end;
  St.FileChanged:=false;
  St.Preferences.LastDirectory:=ExtractFilePath( St.FileName );
  AddToRecentFiles( St.FileName );
end;

const FileFilter = 'free!Ship [*.ftm *.fbm *.fef]|*.ftm;*.fbm;*.fef'
                  +'|         <source types> [*.ftm]|*.ftm'
                  +'|            <binary files> [*.fbm]|*.fbm'
                  +'|    <обменный вид> [*.fef]|*.fef| All files [*.*]|*.*';

function SEdit.File_SaveAs: boolean; var SaveDialog: TSaveDialog;
begin result:=false;
   SaveDialog:=TSaveDialog.Create( St );
   SaveDialog.InitialDir:=St.Preferences.SaveDirectory;
   Savedialog.FileName:=ExtractFilename( St.Filename );
   SaveDialog.Filter:=FileFilter;
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin WestPoint;
      St.Preferences.SaveDirectory:=SaveDialog.InitialDir;
      St.Filename:=Savedialog.Filename;
      St.FilenameSet:=True;
      Result:=File_Save;
      if Result then St.Preferences.LastDirectory:=ExtractFilePath(SaveDialog.FileName);
   end;
   SaveDialog.Destroy;
end;

procedure SEdit.File_Load; var Answer: word; OpenDialog: TOpenDialog;
begin
  St.Edit.Selection_Clear; ///*** Selection_Clear
  OpenDialog:=TOpenDialog.Create( St );
  OpenDialog.InitialDir:=St.Preferences.OpenDirectory; //+ ConfigDirectory
  OpenDialog.Filter:=FileFilter;
  Opendialog.Options:=[ofHideReadOnly];
  if OpenDialog.Execute then begin
     Answer:=St.Edit.File_SaveCheck;
     if (Answer=mrCancel) or St.FileChanged then exit;
     File_Load( Opendialog.FileName );           // Load everything into memory
     St.Preferences.OpenDirectory:=OpenDialog.InitialDir;
  end;
  Opendialog.Destroy;
end;

procedure SEdit.File_Load( FileName: String );
var Source: TFileBuffer; I,LineNR: Integer; Str: String;
    Strings: TStringList=nil;
begin Source:=nil; Strings:=nil;
  if ExtractFileExt( FileName )=''
                then FileName:=ChangeFileExt( FileName,ShipExtention );
  Str:=LowerCase( ExtractFileExt( FileName ) );
  if Str='.fbm' then Source:=TFileBuffer.Create else
  if Str='.ftm' then Source:=TTextBuffer.Create else
  if Str='.fef' then Strings:=TStringList.Create else
       begin WriteLN( '...нет ftm,fbm или fef' ); exit; end;
  St.Clear;
  St.Filename:=FileName;
  if Strings<>nil then begin   // обменный формат из начальных версий !St
    Strings.LoadFromFile( Filename );
    LineNr:=-1;                 // Read general information and mainparticulars
    inc(LineNr); St.ProjectSettings.FProjectName:=Strings[LineNr];
    inc(LineNr); St.ProjectSettings.FProjectDesigner:=Strings[LineNr];
    inc(LineNr); St.ProjectSettings.FProjectFileCreatedBy:=Strings[LineNr];
    inc(LineNr); St.ProjectSettings.FProjectComment:=Strings[LineNr];
    Inc(LineNr); Str:=Strings[LineNr];
    St.ProjectSettings.ProjectLength:=GetFloat(Str);
    St.ProjectSettings.ProjectBeam:=GetFloat(Str);
    St.ProjectSettings.ProjectDraft:=GetFloat(Str);
    St.ProjectSettings.ProjectWaterDensity:=GetFloat(Str);
    St.ProjectSettings.ProjectAppendageCoefficient:=GetFloat(Str);
    I:=GetInteger(Str);
    St.ProjectSettings.FProjectUnits:=TUnitType(I);
   {St.ProjectSettings.FMainparticularsHasBeenset:=} GetBoolean(Str);
    I:=GetInteger(Str);
    St.Precision:=TPrecisionType( I );
    St.Surface.ImportFEFFile(Strings,LineNr);
    Strings.Destroy;
    Drawing;
  end else begin
    Source.LoadFromFile( FileName );
    St.LoadProject( Source );
    FreeAndNil( Source );
  end;
  St.FilenameSet:=True;
  with St do begin
    ZoomFitAllViewports; // Surface.Rebuild;
    for I:=0 to NoBackgroundImages-1 do BackgroundImage[I].UpdateViews;
    Draw;
  end;
//#St.Edit.ProgressBar:=nil;
  if LinesplanFrame<>nil then Linesplanframe.Ship:=St;
{ #if St.ModelIsLoaded then } AddToRecentFiles( FileName );
                                Undo_Clear;
  St.FileChanged:=False;
end;

Procedure TShip.LoadProject( Source:TFileBuffer );                // LoadBinary
var PrevCursor: TCursor; I,N: Integer; Str: String;
    Data        : TBackgroundImageData;
    Intersection: TIntersection;
    Flowline    : TFlowline;
    Marker      : TMarker;
begin    // Remember the filename because it will be erased by the clear method
   Str:=FFilename;
   Clear;
   FFilename:=Str;
   PrevCursor:=Screen.Cursor;
   Screen.Cursor:=crHourGlass;
   Source.Reset;
   Source.LoadString(Str);
   if Str='FREE!ship' then begin
      Source.LoadTFileVersion(FFileVersion);
      Source.Version:=FFileVersion;
//    if (FFileVersion<=CurrentVersion)
//    or (FFileVersion<=High(FFileVersion)) then
      begin
         Write( '[',FFileVersion,'] ',ExtractFilename( FFilename ) );
         Source.LoadInteger(I);
         Precision:=TPrecisionType(I);
         Visibility.LoadBinary(Source);
         ProjectSettings.LoadBinary(Source,nil);
         Surface.LoadBinary(Source); // Load actual subdivision-surface data.
         Source.LoadInteger(N);      // Load stations
         FStations.Capacity:=N;
         for I:=1 to N do begin
             Intersection:=TIntersection.Create(self);
             FStations.Add(Intersection);
             Intersection.LoadBinary(Source);
         end;
         Source.LoadInteger(N);      // Load Buttocks
         FButtocks.Capacity:=N;
         for I:=1 to N do begin
             Intersection:=TIntersection.Create(self);
             FButtocks.Add(Intersection);
             Intersection.LoadBinary(Source);
         end;
         Source.LoadInteger(N);      // Load Waterlines
         FWaterlines.Capacity:=N;
         for I:=1 to N do begin
             Intersection:=TIntersection.Create(self);
             FWaterlines.Add(Intersection);
             Intersection.LoadBinary(Source);
         end;
         if FileVersion>=fv180 then begin // Load Diagonals
            Source.LoadInteger(N);
            FDiagonals.Capacity:=N;
            for I:=1 to N do begin
                Intersection:=TIntersection.Create(self);
                FDiagonals.Add(Intersection);
                Intersection.LoadBinary(Source);
            end;
            if FileVersion>=fv191 then begin // Load markers
               Source.LoadInteger(N);
               FMarkers.Capacity:=N;
               for I:=1 to N do begin
                   Marker:=TMarker.Create;
                   Marker.FOwner:=Self;
                   Edit.Marker_Add(Marker);
                   Marker.LoadBinary(Source);
               end;
               if FileVersion>=fv210 then begin
                  if Source is TTextBuffer
                  then (Source as TTextBuffer).FPosition+=29  // 9+1 + 17+2
                   else Source.FPosition += 112;     // = Delft(72) + Kaper(40)
                  if FileVersion>=fv250 then begin
                     Source.LoadInteger( N );
                     for I:=1 to N do begin
                         Data:=TBackgroundImageData.Create(self);
                         FBackgroundImages.Add(data);
                         Data.LoadBinary(Source);
                     end;
                     Source.LoadInteger(N);
                     FFlowlines.Capacity:=N;
                     for I:=1 to N do begin
                         Flowline:=TFlowline.Create(self);
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
// for I:=1 to NoBackgroundImages do BackgroundImage[I-1].UpdateViews;
   if Assigned(OnUpdateGeometryInfo) then OnUpdateGeometryInfo(self);
end;

// автоматическое формирование теоретических контуров

procedure SEdit.Drawing;
Var D,DD:Real; I: Integer;
begin with St.ProjectSettings do begin
   dd:=AxisStep( (St.Surface.Max.X-St.Surface.Min.X)/5.75 ); // шаг шпации
   I:=round( St.Surface.Min.X/dd+0.5 );
   repeat Intersection_Add( fiStation,I*dd ); inc( I );         // и шпангоуты
   until I*dd>=St.Surface.Max.X;
   dd:=AxisStep( ProjectBeam/1.75 ); I:=0;                      // Батоксы
   repeat Intersection_Add( fiButtock,I*dd ); inc( I ); until I*dd>=ProjectBeam-dd/4;
// dd:=AxisStep( St.Surface.Max.Z-St.Surface.Min.Z );       // Ватерлинии
   dd:=AxisStep( ProjectDraft*2 );                              // Ватерлинии
   I:=round( St.Surface.Min.Z/dd+0.51 );
   repeat Intersection_Add( fiWaterline,I*dd );                 // Ватерлинии и
          Intersection_Add( fiDiagonal,I*dd );  inc( I );      // рыбины там же
   until I*dd>=St.Surface.Max.Z-dd*0.25;
   while Intersection_Add( fiDiagonal,I*dd )<>Nil do inc( I ); // плюс по борту


// D:=round( ProjectDraft/dd/2+0.51 );              // по паре на обе стороны =
// D:=round( St.Surface.Min.Z/dd );               // по паре на обе стороны =
// for I:=0 to 5 do Intersection_Add( fiDiagonal,I*dd ); // шесть рыбин
   SavePreview:=false;                              // без предпросмотра
   St.FileChanged:=True;
   St.Visibility.ModelView:=mvBoth;               // на оба борта
   St.Visibility.ShowControlNet:=false;           // без выделения узлов
   St.Visibility.ShowInteriorEdges:=True;         // внутрення разбивка рёбер
   St.ProjectSettings.SavePreview:=false;
   if Assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(self);
   // St.Build:=False;
   // St.RebuildModel;
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

function SEdit.Model_New:Boolean;
var Answer: word; I,J,Cols,Rows: integer;
    L,B,D,dd: Real; P: Vector;
    Spline1,Spline2: TSpline;
    TrvSplines: TFasterList;
    Pts: array of array of SControlPoint;
    StemPoint: SControlPoint;
    NewModelDialog: TNewModelDialog;
begin
   Result:=False;               // Apparently saving was not successfull, abort
   Answer:=St.Edit.File_SaveCheck;
   if (Answer=mrCancel) or St.FileChanged then exit;
   NewModelDialog:=TNewModelDialog.Create(St);
   ShowTranslatedValues(NewModelDialog);
   if NewModelDialog.Execute then begin
      CreateUndoObject(Userstring(157),True);
      Cols:=NewModelDialog.NCols-1;
      Rows:=NewModelDialog.NRows-1;
      L:=NewModelDialog.Length;
      B:=NewModelDialog.Breadth;
      D:=NewModelDialog.Draft/2;
      St.Clear;
      with St.ProjectSettings do begin                       // «free!Ship»
        case NewModelDialog.ShipBox.ItemIndex of
          0: begin St.FileName:=File_A; FProjectName:=Name_A;
                                          FProjectComment:=Comm_A; end;
          1: begin St.FileName:=File_B; FProjectName:=Name_B;
                                          FProjectComment:=Comm_B; end;
          2: begin St.FileName:=File_C; FProjectName:=Name_C;
                                          FProjectComment:=Comm_C; end;
        end;
        FProjectName:='«'+ChangeFileExt(ExtractFilename(St.FileName),'')+'». '+FProjectName;
        FProjectDesigner:='Подсекция штормовой мореходности, Научно-инженерное общество корабелов им.А.Н.Крылова';
        FProjectFileCreatedBy:='©'+TimeString+' !St example'; //, № '+inttostr( NewModelDialog.ShipBox.ItemIndex+1); // FormatDateTime('YYYY-MM-DD_hh:nn',Now );
        ProjectLength:=L;
        ProjectBeam:=B;
        if NewModelDialog.ShipBox.ItemIndex=2 then ProjectDraft:=D*2.5
                                                  else ProjectDraft:=D*2;
        ProjectUnits:=TUnitType(NewModelDialog.ComboBox1.ItemIndex);
      End;
      Sp.UAlfa:=64;
      Sp.UColor:=clGreen;
      Sp.UColorIs:=true;
      TrvSplines:=TFasterList.Create;
      StemPoint:=nil;      // First create tmp. splines in transverse direction
      for I:=0 to 6 do begin Spline1:=TSpline.Create;
         for J:=0 to 4 do begin
            case NewModelDialog.ShipBox.ItemIndex of
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
         Spline2:=TSpline.Create;
         for j:=0 to TrvSplines.Count-1 do begin
            Spline1:=TrvSplines[J];
            P:=Spline1.Value(I/Rows);
            Spline2.Add(P);
         end; // now calculate all points on longitudinal spline and send it to surface
         for J:=0 to Cols do begin
            P:=Spline2.Value( J/Cols );
            Pts[I,J]:=SControlPoint.Create(St.Surface);
            St.Surface.AddControlPoint(Pts[I,J]);
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
          St.Surface.AddControlFace(Trvsplines,True);
      end;
      St.Precision:=fpMedium;
      St.Surface.Initialize(1,1,1);
      St.ActiveLayer.Name:=Userstring(179); // Обводы и общекорабельная архитектура
      if StemPoint<>nil then
        if StemPoint.VertexType=svCorner then stempoint.VertexType:=svCrease;
      TrvSplines.Destroy;
      St.Build:=False;
      Drawing;
      St.draw;
      Result:=true;
//      St.ZoomFitAllViewports;
//      St.ReDraw;
   end;
   NewModelDialog.Destroy;
end;

