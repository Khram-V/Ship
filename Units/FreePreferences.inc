{--------------------------------------------------------------}
{   FreePreferences                                            }
{   Container class for all program settings                   }
{--------------------------------------------------------------}

const iniFileName: String = 'FreeShip.ini';
const G: String = 'Graphic';
const D: String = 'Directories';

procedure TFreePreferences.FSetViewportColor(Val: TColor);
var I: integer;
begin FViewportColor:=Val;
  for I:=1 to Owner.NumberOfViewports do Owner.Viewport[I-1].Color:=FViewportColor;
end;

procedure TFreePreferences.Clear;
begin
  ResetColors;         FPointSize:=2;
  ResetDirectories;    LastDirectory:='';
  Language:='English'; LanguageFile:=''; FFbmEncoding:='cp1251';
  FMaxUndoMemory:=20;                                    // Max 20Mb undomemory
end;
constructor TFreePreferences.Create(Owner: TFreeShip);
  begin inherited Create; FOwner:=Owner; Clear; end;

procedure TFreePreferences.Edit;
var Dialog: TFreePreferencesDialog;
    Dir, Lang: string;
    I: integer;
const DS = DirectorySeparator;
  procedure Browse( Dir: string );
  var SearchRec: TSearchRec;
    procedure Add( FileName:string );
    var Tmp: string; I: integer; Found: boolean;
    begin
      Tmp:=ChangeFileExt( ExtractFilename( Filename ),'' ); found:=False;
      for I:=1 to Dialog.ComboBox1.Items.Count do
        if Uppercase( Tmp )=Uppercase(Dialog.Combobox1.Items[I-1]) then begin
          Found:=True; break;
        end;
      if not found then Dialog.Combobox1.Items.Add( Tmp );
    end; {Add}
  begin
    if Dir[Length(Dir)]<>DirectorySeparator then Dir:=Dir+DirectorySeparator;
    if FindFirstUTF8(Dir+'*.ini',faAnyfile,SearchRec) = 0 then begin
      if Uppercase(ExtractFileExt(SearchRec.Name))='.INI' then Add(Searchrec.Name);
      while FindNextUTF8(SearchRec) = 0 do
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        if Uppercase(ExtractFileExt(SearchRec.Name))='.INI' then Add(Searchrec.Name);
      FindCloseUTF8(SearchRec);
    end;
  end; {Browse}
begin
  Dialog:=TFreePreferencesDialog.Create(Owner);
  ShowTranslatedValues( Dialog );
  Dir:=LanguagesDirectory; // ConfigDirectory = установлена активная директория
  Dialog.ComboBox1.Items.Clear;
  Dialog.ComboBox1.Items.Add( 'English' ); Browse( Dir );
  Dialog.ComboBox1.ItemIndex:=0;
  for I:=1 to Dialog.ComboBox1.Items.Count do
    if Uppercase(Dialog.ComboBox1.Items[I-1])=Uppercase(FLanguage) then begin
       Dialog.ComboBox1.ItemIndex:=I-1; break;
    end;
  if Dialog.Execute(Owner) then begin
    LayerColor       :=Dialog.Panel2.Color;
    ViewportColor    :=Dialog.Panel4.Color; // Set viewportcolor last, because it forces a repaint
    UnderWaterColor  :=Dialog.Panel5.Color;
    EdgeColor        :=Dialog.Panel6.Color;
    CreaseEdgeColor  :=Dialog.Panel7.Color;
    CreaseColor      :=Dialog.Panel8.Color;
    RegularPointColor:=Dialog.Panel9.Color;
    CreasePointColor :=Dialog.Panel10.Color;
    CornerPointColor :=Dialog.Panel11.Color;
    DartPointColor   :=Dialog.Panel12.Color;
    SelectColor      :=Dialog.Panel13.Color;
    GridColor        :=Dialog.Panel14.Color;
    GridFontColor    :=Dialog.Panel15.Color;
    StationColor     :=Dialog.Panel16.Color;
    ButtockColor     :=Dialog.Panel17.Color;
    WaterlineColor   :=Dialog.Panel18.Color;
    NormalColor      :=Dialog.Panel19.Color;
    DiagonalColor    :=Dialog.Panel20.Color;
    LeakPointColor   :=Dialog.Panel21.Color;
    MarkerColor      :=Dialog.Panel22.Color;
    CurvaturePlotColor:= Dialog.Panel23.Color;
    ControlCurveColor:=Dialog.Panel24.Color;
    HydrostaticsFontColor:= Dialog.Panel25.Color;
    ZebraStripeColor    :=Dialog.Panel26.Color;

    UnderWaterColorAlpha:=Dialog.seSubmergedSurfaceOpacity.Value * 255 div 100;
    PointSize:=Dialog.SpinEdit1.Value;
    FontSize:=Dialog.seFontSize.Value;
    Lang:=Dialog.Combobox1.Text;

    LanguagesDirectory:=Dialog.EditLanguagesDir.Text;
    ManualsDirectory  :=Dialog.EditManualsDir.Text;
    OpenDirectory     :=Dialog.EditOpenDir.Text;
    SaveDirectory     :=Dialog.EditSaveDir.Text;
    ImportDirectory   :=Dialog.EditImportDir.Text;
    ExportDirectory   :=Dialog.EditExportDir.Text;
    if Uppercase( Lang )<>Uppercase( FLanguage ) then begin // Converted from FileExists
      LanguageFile := LanguagesDirectory+DS+Lang+'.ini';    //+ConfigDirectory
      if FileExistsUTF8( LanguageFile )then begin
        LoadLanguage( Lang,LanguageFile );
        FLanguage:=Lang;
        for I:=1 to Application.ComponentCount do
        if Application.Components[I-1] is TCustomForm
           then ShowTranslatedValues( Application.Components[I-1] );
        with MainForm as TMainForm do
         for I:=1 to MDIChildCount do
          if MDIChildren[I-1] is TFreeLinesplanForm
           then ShowTranslatedValues( TFreeLinesplanForm(MDIChildren[I-1]).LinesplanFrame )
           else ShowTranslatedValues( MDIChildren[I-1] );
      end; // else FLanguage:=Lang;
    end;
    FFbmEncoding:=string( Dialog.ComboBoxEncoding.Items.Objects[Dialog.ComboBoxEncoding.ItemIndex] );
    FMaxUndoMemory:=Dialog.FreeNumInput1.Value;

    if assigned(Owner.FOnFileChanged) then Owner.FOnFileChanged(Owner);
    if assigned(Owner.FOnUpdateUndoData) then Owner.FOnUpdateUndoData(Owner);
    if assigned(Owner.FOnUpdateRecentFileList) then Owner.FOnUpdateRecentFileList(Owner);
    if assigned(Owner.FOnChangeCursorIncrement) then Owner.FOnChangeCursorIncrement(Owner);
    if assigned(Owner.FOnUpdateGeometryInfo) then Owner.FOnUpdateGeometryInfo(owner);
    Owner.Redraw;
    end;
  FreeAndNil(Dialog);
end;
(*
procedure TFreePreferences.detectApplicationScope; var appPath:string;
begin appPath:=ExtractFilePath( Application.Exename );
{$ifdef Windows}
   if appPath.StartsWith( windirs.GetWindowsSpecialDir( CSIDL_LOCAL_APPDATA) )
   or appPath.StartsWith( windirs.GetWindowsSpecialDir( CSIDL_PROFILE ) )
      then FApplicationScope:=asUser
      else FApplicationScope:=asMachine;
{$endif}
end;
*)
function TColorIniFile.ReadColor(const Section,Ident:string; Default:TColor): TColor;
begin Result:=StringToColor(ReadString(Section, Ident, ColorToString(Default)));
end;
procedure TColorIniFile.WriteColor(const Section,Ident:string; Value:TColor);
begin WriteString( Section,Ident,'$'+HexStr(Value,6) ); // ColorToString( Value ) );
end;
procedure TFreePreferences.LoadFromIni;
var I, T, L, W, H, S: Integer;
    params: TColorIniFile; RecentFileNames: TStringList;
begin
  if not FileExistsUTF8( iniFileName ) then begin
    if Mainform <> nil then begin
       MainForm.WindowState:=wsNormal;
       MainForm.SetBounds( 0,0,Screen.WorkAreaWidth,Screen.WorkAreaHeight );
    end;
    SetDefaults; exit;
  end;
  params:=TColorIniFile.Create( iniFilename,False );
  LastDirectory     :=params.ReadString(D,'LastDirectory',LastDirectory);
  OpenDirectory     :=params.ReadString(D,'OpenDirectory',OpenDirectory);
  SaveDirectory     :=params.ReadString(D,'SaveDirectory',SaveDirectory);
  ImportDirectory   :=params.ReadString(D,'ImportDirectory',ImportDirectory);
  ExportDirectory   :=params.ReadString(D,'ExportDirectory',ExportDirectory);
  LanguagesDirectory:=params.ReadString(D,'LanguagesDirectory',LanguagesDirectory);
  ManualsDirectory  :=params.ReadString(D,'ManualsDirectory',ManualsDirectory);

  FPointSize           :=params.ReadInteger(G,'PointSize', FPointSize);
  FFontSize            :=params.ReadInteger(G,'FontSize', FFontSize);
  FButtockColor        :=params.ReadColor  (G,'ButtockColor', FButtockColor);
  FWaterlineColor      :=params.ReadColor  (G,'WaterlineColor', FWaterlineColor);
  FStationColor        :=params.ReadColor  (G,'StationColor', FStationColor);
  FCreaseColor         :=params.ReadColor  (G,'CreaseColor', FCreaseColor);
  FCreaseEdgeColor     :=params.ReadColor  (G,'CreaseEdgeColor', FCreaseEdgeColor);
  FGridColor           :=params.ReadColor  (G,'GridColor', FGridColor);
  FGridFontColor       :=params.ReadColor  (G,'GridFontColor', FGridFontColor);
  FEdgeColor           :=params.ReadColor  (G,'EdgeColor', FEdgeColor);
  FCreasePointColor    :=params.ReadColor  (G,'CreasePointColor',FCreasePointColor);
  FRegularPointColor   :=params.ReadColor  (G,'RegularPointColor',FRegularPointColor);
  FCornerPointColor    :=params.ReadColor  (G,'CornerPointColor',FCornerPointColor);
  FDartPointColor      :=params.ReadColor  (G,'DartPointColor', FDartPointColor);
  FSelectColor         :=params.ReadColor  (G,'SelectColor', FSelectColor);
  FLayerColor          :=params.ReadColor  (G,'LayerColor', FLayerColor);
  FUnderWaterColor     :=params.ReadColor  (G,'UnderWaterColor', FUnderWaterColor);
  FUnderWaterColorAlpha:=params.ReadInteger(G,'UnderWaterColorAlpha',FUnderWaterColorAlpha);
  FNormalColor         :=params.ReadColor  (G,'NormalColor', FNormalColor);
  FViewportColor       :=params.ReadColor  (G,'ViewportColor', FViewportColor);
  FDiagonalColor       :=params.ReadColor  (G,'DiagonalColor', FDiagonalColor);
  FLeakPointColor      :=params.ReadColor  (G,'LeakPointColor', FLeakPointColor);
  FMarkerColor         :=params.ReadColor  (G,'MarkerColor', FMarkerColor);
  FCurvaturePlotColor  :=params.ReadColor  (G,'CurvaturePlotColor',FCurvaturePlotColor);
  FControlCurveColor   :=params.ReadColor  (G,'ControlCurveColor',FControlCurveColor);
  FHydrostaticsFontColor:=params.ReadColor (G,'HydrostaticsFontColor',FHydrostaticsFontColor);
  FZebraStripeColor    :=params.ReadColor  (G,'ZebraStripeColor',FZebraStripeColor);

  FIntersectionLineWidth:= params.ReadInteger(G,'IntersectionLineWidth', FIntersectionLineWidth);
  FControlEdgeLineWidth:=params.ReadInteger(G,'ControlEdgeLineWidth', FControlEdgeLineWidth);
  FInteriorEdgeLineWidth:= params.ReadInteger(G,'InteriorEdgeLineWidth', FInteriorEdgeLineWidth);
  FHydrostaticLineWidth:=params.ReadInteger(G,'HydrostaticLineWidth', FHydrostaticLineWidth);
  FAuxEdgeLineWidth    :=params.ReadInteger(G,'AuxEdgeLineWidth', FAuxEdgeLineWidth);

  RecentFileNames:=TStringList.Create;
  params.ReadSectionValues( 'RecentFiles',RecentFileNames );
  Owner.Edit.FRecentFiles.Clear;
  Owner.Edit.FRecentFiles.Capacity:=RecentFileNames.Count;
  for I:=0 to RecentFileNames.Count-1 do
    Owner.Edit.FRecentFiles.Add( RecentFileNames.ValueFromIndex[I] );
  FreeAndNil( RecentFileNames );
  if assigned( Owner.FOnUpdateRecentFileList )
          then Owner.FOnUpdateRecentFileList( self ); //Readln(FFile,T,L,H,W,S);
  T:=params.ReadInteger( 'Window','Top',0 );
  L:=params.ReadInteger( 'Window','Left',0 );
  H:=params.ReadInteger( 'Window','Height',Screen.WorkAreaHeight);
  W:=params.ReadInteger( 'Window','Width', Screen.WorkAreaWidth);
  S:=params.ReadInteger( 'Window','State', integer( wsNormal ) );

  if MainForm<>nil then begin
    if L > Screen.Width then L:=0;
    if T > Screen.Height then T:=0;
    if W > Screen.Width then W:=Screen.WorkAreaWidth;
    if H > Screen.Height then H:=Screen.WorkAreaHeight;
    case TWindowState( S ) of
      wsNormal: MainForm.SetBounds( L,T,W,H );
      wsMinimized: begin
        MainForm.WindowState:=wsNormal;
        MainForm.SetBounds( L,T,W,H );
      end;
      wsMaximized: MainForm.WindowState:=wsMaximized;
    end;
  end;
  FLanguage:=params.ReadString( 'General','Language',FLanguage );
  LanguageFile:=LanguagesDirectory+DirectorySeparator+Flanguage+'.ini'; //+ConfigDirectory
  if not FileExistsUTF8( LanguageFile ) then begin
    Writeln( '! нет файла: '+LanguageFile );
    FLanguage:='English';
    LanguageFile:=ConfigDirectory+LanguagesDirectory+'\English.ini';
  end;
  FFbmEncoding :=params.ReadString( 'General','FbmEncoding',FbmEncoding );
  FMaxUndoMemory:= params.ReadInteger('General','MaxUndoMemory',FMaxUndoMemory);
  params.Free;
end;

procedure TFreePreferences.SetDefaults;
begin
  FPointSize  :=2;
  FFontSize   :=8;
  FLanguage   :='English';
  FFbmEncoding:='cp1251';
  FMaxUndoMemory:= 32;
  ResetDirectories;
  ResetColors;
end;

procedure TFreePreferences.ResetDirectories;
begin
  ConfigDirectory := ExtractFileDir( Application.ExeName );
  SetCurrentDir( ConfigDirectory );
  LanguagesDirectory:='Languages';
  ManualsDirectory  :='Manuals';
  OpenDirectory     :='Ships';
  SaveDirectory     :='Save';
  ImportDirectory   :='Save\Import';
  ExportDirectory   :='Save\Export';
  ConfigDirectory := ConfigDirectory+DirectorySeparator;
end;

procedure TFreePreferences.Load; begin setDefaults; LoadFromIni; end;

function TFreePreferences.OnlyName( const S: string ): string;
  var L:Integer;
begin L:=Length( ConfigDirectory ); Result:=S;
  if S.StartsWith( ConfigDirectory ) then Result:=S.SubString( L,Length(S)-L );
end;

procedure TFreePreferences.ResetColors; // Расцветка по умолчанию
begin
  FViewportColor:=clWhite;
  FGridColor    :=clSilver;
  FGridFontColor:=clGray;
  FLayerColor   :=$FFFFF0;     // Default color each layer
  FNormalColor  :=clLime;
  FUnderwaterColor:=clGreen;
  FUnderwaterColorAlpha:=255;  //opaque
  FControlCurveColor:=$FF0080;
  FEdgeColor        :=$6F6F6F;
  FCreaseEdgeColor  :=$32CD9A; // Color of crease control edges
  FCreaseColor      :=$999966; // color of descendants from crease controledges
  FRegularPointColor:= $E1E1E1;
  FCreasePointColor := $004080;
  FCornerPointColor := $B95C00;
  FDartPointColor   :=clFuchsia;
  FLeakPointColor   :=clRed;
  FSelectColor      :=clYellow;
  FCurvaturePlotColor:=clFuchsia;
  FMarkerColor      :=$8000FF;
  FStationColor     :=clBlue;
  FButtockColor     :=clGray;
  FWaterlineColor   :=clGreen;
  FDiagonalColor    :=clSkyBlue;
  FHydrostaticsFontColor:=clGreen;
  FZebraStripeColor:=clltGray;
  FIntersectionLineWidth:=1;
  FControlEdgeLineWidth :=2;
  FInteriorEdgeLineWidth:=1;
  FAuxEdgeLineWidth     :=1;
  FHydrostaticLineWidth :=1;
end;

procedure TFreePreferences.Save;
 var  I:integer; params:TColorIniFile;
begin
//  if not FileExistsUTF8( Filename ) then exit;
//  then ForceDirectoriesUTF8( ExtractFilePath( Filename ) ); // ~~ и то зря
  params:=TColorIniFile.Create( iniFilename,False );
  params.WriteString ( 'General','Language',FLanguage );
  params.WriteString ( 'General','FbmEncoding',FbmEncoding );
  params.WriteInteger( 'General','MaxUndoMemory',FMaxUndoMemory );
  params.WriteString( D,'LanguagesDirectory',OnlyName( LanguagesDirectory));
  params.WriteString( D,'ManualsDirectory',  OnlyName( ManualsDirectory));
  params.WriteString( D,'OpenDirectory',     OnlyName( OpenDirectory   ));
  params.WriteString( D,'SaveDirectory',     OnlyName( SaveDirectory   ));
  params.WriteString( D,'ImportDirectory',   OnlyName( ImportDirectory ));
  params.WriteString( D,'ExportDirectory',   OnlyName( ExportDirectory ));
  params.WriteString( D,'LastDirectory',     OnlyName( LastDirectory   ));
  if MainForm<>nil then begin
    params.WriteInteger( 'Window','Top',MainForm.Top);
    params.WriteInteger( 'Window','Left',MainForm.Left);
    params.WriteInteger( 'Window','Height',MainForm.Height);
    params.WriteInteger( 'Window','Width',MainForm.Width);
    params.WriteInteger( 'Window','State',integer(MainForm.WindowState));
  end;
  params.WriteInteger( G,'PointSize',            FPointSize);
  params.WriteInteger( G,'FontSize',             FFontSize);
  params.WriteColor  ( G,'ViewportColor',        FViewportColor);
  params.WriteColor  ( G,'GridColor',            FGridColor);
  params.WriteColor  ( G,'GridFontColor',        FGridFontColor);
  params.WriteColor  ( G,'LayerColor',           FLayerColor);
  params.WriteColor  ( G,'NormalColor',          FNormalColor);
  params.WriteColor  ( G,'UnderWaterColor',      FUnderWaterColor);
  params.WriteInteger( G,'UnderWaterColorAlpha', FUnderWaterColorAlpha);
  params.WriteColor  ( G,'ControlCurveColor',    FControlCurveColor);
  params.WriteColor  ( G,'EdgeColor',            FEdgeColor);
  params.WriteColor  ( G,'CreaseEdgeColor',      FCreaseEdgeColor);
  params.WriteColor  ( G,'CreaseColor',          FCreaseColor);
  params.WriteColor  ( G,'RegularPointColor',    FRegularPointColor);
  params.WriteColor  ( G,'CreasePointColor',     FCreasePointColor);
  params.WriteColor  ( G,'CornerPointColor',     FCornerPointColor);
  params.WriteColor  ( G,'DartPointColor',       FDartPointColor);
  params.WriteColor  ( G,'LeakPointColor',       FLeakPointColor);
  params.WriteColor  ( G,'SelectColor',          FSelectColor);
  params.WriteColor  ( G,'CurvaturePlotColor',   FCurvaturePlotColor);
  params.WriteColor  ( G,'MarkerColor',          FMarkerColor);
  params.WriteColor  ( G,'StationColor',         FStationColor);
  params.WriteColor  ( G,'ButtockColor',         FButtockColor);
  params.WriteColor  ( G,'WaterlineColor',       FWaterlineColor);
  params.WriteColor  ( G,'DiagonalColor',        FDiagonalColor);
  params.WriteColor  ( G,'HydrostaticsFontColor',FHydrostaticsFontColor);
  params.WriteColor  ( G,'ZebraStripeColor',     FZebraStripeColor);
  params.WriteInteger( G,'IntersectionLineWidth',FIntersectionLineWidth);
  params.WriteInteger( G,'ControlEdgeLineWidth', FControlEdgeLineWidth);
  params.WriteInteger( G,'InteriorEdgeLineWidth',FInteriorEdgeLineWidth);
  params.WriteInteger( G,'HydrostaticLineWidth', FHydrostaticLineWidth);
  params.WriteInteger( G,'AuxEdgeLineWidth',     FAuxEdgeLineWidth);
  params.EraseSection( 'RecentFiles');
  for I:=0 to Owner.Edit.FRecentFiles.Count-1 do
    params.WriteString('RecentFiles','File'+IntToStr(I+1),
                        OnlyName( Owner.Edit.FRecentFiles[I] ) );
  if assigned( Owner.FOnUpdateRecentFileList ) then
               Owner.FOnUpdateRecentFileList( self );
end;

