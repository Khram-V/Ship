{--------------------------------------------------------------}
{   FreePreferences                                            }
{   Container class for all program settings                   }
{--------------------------------------------------------------}

const iniFileName = 'FreeShip.ini';
const G = 'Graphic';
const D = 'Directories';

procedure TFreePreferences.FSetViewportColor( Val: TColor );
var I: integer;
begin FViewportColor:=Val;
  for I:=0 to Owner.NumberOfViewports-1 do
              Owner.Viewport[I].Color:=FViewportColor;
end;
procedure TFreePreferences.Clear;
begin
  ResetColors;           PointSize:=2;
  ResetDirectories;      LastDirectory:='';
  Language:='English';   LanguageFile:='';
  FbmEncoding:='cp1251'; MaxUndoMemory:=64;              // Max 20Mb undomemory
end;
constructor TFreePreferences.Create(Owner: TFreeShip);
  begin inherited Create; FOwner:=Owner; Clear; end;

procedure TFreePreferences.Edit;
var Dialog: TFreePreferencesDialog;
    Dir, Lang: AnsiString;
    I: integer;
//const DS = DirectorySeparator;
  procedure Browse( Dir: AnsiString );
  var SearchRec: TSearchRec;
    procedure Add( FileName:AnsiString );
    var Tmp: AnsiString; I: integer; Found: boolean;
    begin
      Tmp:=ChangeFileExt( ExtractFilename( Filename ),'' ); found:=False;
      for I:=1 to Dialog.ComboBox1.Items.Count do
        if Uppercase( Tmp )=Uppercase(Dialog.Combobox1.Items[I-1]) then begin
          Found:=True; break;
        end;
      if not found then Dialog.Combobox1.Items.Add( Tmp );
    end; {Add}
  begin
    if Dir[Length(Dir)]<>'\' then Dir:=Dir+'\';
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
    if Uppercase(Dialog.ComboBox1.Items[I-1])=Uppercase(Language) then begin
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

    LanguagesDirectory:=OnlyName( Dialog.EditLanguagesDir.Text );
    ManualsDirectory  :=OnlyName( Dialog.EditManualsDir.Text );
    OpenDirectory     :=OnlyName( Dialog.EditOpenDir.Text );
    SaveDirectory     :=OnlyName( Dialog.EditSaveDir.Text );
    ImportDirectory   :=OnlyName( Dialog.EditImportDir.Text );
    ExportDirectory   :=OnlyName( Dialog.EditExportDir.Text );
    if Uppercase( Lang )<>Uppercase( Language ) then begin // Converted from FileExists
      LanguageFile:=LanguagesDirectory+Lang+'.ini';    //+ConfigDirectory
      if FileExistsUTF8( LanguageFile )then begin
        LoadLanguage( Lang,LanguageFile );
        Language:=Lang;
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
    FbmEncoding:=string( Dialog.ComboBoxEncoding.Items.Objects[Dialog.ComboBoxEncoding.ItemIndex] );
    MaxUndoMemory:=Dialog.FreeNumInput1.Value;

    if assigned(Owner.OnFileChanged) then Owner.OnFileChanged(Owner);
    if assigned(Owner.OnUpdateUndoData) then Owner.OnUpdateUndoData(Owner);
    if assigned(Owner.OnUpdateRecentFileList) then Owner.OnUpdateRecentFileList(Owner);
    if assigned(Owner.OnChangeCursorIncrement) then Owner.OnChangeCursorIncrement(Owner);
    if assigned(Owner.OnUpdateGeometryInfo) then Owner.OnUpdateGeometryInfo(owner);
    Owner.Redraw;
    end;
  FreeAndNil(Dialog);
end;
(*
procedure TFreePreferences.detectApplicationScope; var appPath:AnsiString;
begin appPath:=ExtractFilePath( Application.Exename );
{$ifdef Windows}
   if appPath.StartsWith( windirs.GetWindowsSpecialDir( CSIDL_LOCAL_APPDATA) )
   or appPath.StartsWith( windirs.GetWindowsSpecialDir( CSIDL_PROFILE ) )
      then FApplicationScope:=asUser
      else FApplicationScope:=asMachine;
{$endif}
end;
*)
function TColorIniFile.ReadColor(const Section,Ident:AnsiString; Default:TColor): TColor;
begin Result:=StringToColor(ReadString(Section, Ident, ColorToString(Default)));
end;
procedure TColorIniFile.WriteColor(const Section,Ident:AnsiString; Value:TColor);
begin WriteString( Section,Ident,'$'+HexStr(Value,6) ); // ColorToString( Value ) );
end;
procedure TFreePreferences.LoadFromIni;
var I,T,L,W,H,S: Integer; params: TColorIniFile; RecentFileNames: TStringList;
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

  PointSize           :=params.ReadInteger(G,'PointSize',PointSize);
  FontSize            :=params.ReadInteger(G,'FontSize', FontSize);
  StationColor        :=params.ReadColor  (G,'StationColor', StationColor);
  ButtockColor        :=params.ReadColor  (G,'ButtockColor', ButtockColor);
  WaterlineColor      :=params.ReadColor  (G,'WaterlineColor',WaterlineColor);
  DiagonalColor       :=params.ReadColor  (G,'DiagonalColor', DiagonalColor);
  UnderWaterColor     :=params.ReadColor  (G,'UnderWaterColor',UnderWaterColor);
  UnderWaterColorAlpha:=params.ReadInteger(G,'UnderWaterColorAlpha',UnderWaterColorAlpha);
  CreaseColor         :=params.ReadColor  (G,'CreaseColor', CreaseColor);
  CreaseEdgeColor     :=params.ReadColor  (G,'CreaseEdgeColor', CreaseEdgeColor);
  GridColor           :=params.ReadColor  (G,'GridColor', GridColor);
  GridFontColor       :=params.ReadColor  (G,'GridFontColor', GridFontColor);
  EdgeColor           :=params.ReadColor  (G,'EdgeColor', EdgeColor);
  CreasePointColor    :=params.ReadColor  (G,'CreasePointColor',CreasePointColor);
  RegularPointColor   :=params.ReadColor  (G,'RegularPointColor',RegularPointColor);
  CornerPointColor    :=params.ReadColor  (G,'CornerPointColor',CornerPointColor);
  DartPointColor      :=params.ReadColor  (G,'DartPointColor', DartPointColor);
  SelectColor         :=params.ReadColor  (G,'SelectColor', SelectColor);
  LayerColor          :=params.ReadColor  (G,'LayerColor', LayerColor);
  NormalColor         :=params.ReadColor  (G,'NormalColor', NormalColor);
  LeakPointColor      :=params.ReadColor  (G,'LeakPointColor', LeakPointColor);
  MarkerColor         :=params.ReadColor  (G,'MarkerColor', MarkerColor);
  CurvaturePlotColor  :=params.ReadColor  (G,'CurvaturePlotColor',CurvaturePlotColor);
  ControlCurveColor   :=params.ReadColor  (G,'ControlCurveColor',ControlCurveColor);
  HydrostaticsFontColor:=params.ReadColor (G,'HydrostaticsFontColor',HydrostaticsFontColor);
  ZebraStripeColor    :=params.ReadColor  (G,'ZebraStripeColor',ZebraStripeColor);
  FViewportColor      :=params.ReadColor  (G,'ViewportColor', FViewportColor );

  FIntersectionLineWidth:= params.ReadInteger(G,'IntersectionLineWidth', FIntersectionLineWidth);
  FControlEdgeLineWidth:=params.ReadInteger(G,'ControlEdgeLineWidth', FControlEdgeLineWidth);
  FInteriorEdgeLineWidth:= params.ReadInteger(G,'InteriorEdgeLineWidth', FInteriorEdgeLineWidth);
  FHydrostaticLineWidth:=params.ReadInteger(G,'HydrostaticLineWidth', FHydrostaticLineWidth);
  FAuxEdgeLineWidth    :=params.ReadInteger(G,'AuxEdgeLineWidth', FAuxEdgeLineWidth);

  RecentFileNames:=TStringList.Create;
  params.ReadSectionValues( 'RecentFiles',RecentFileNames );
  Owner.Edit.RecentFiles.Clear;
  Owner.Edit.RecentFiles.Capacity:=RecentFileNames.Count;
  for I:=0 to RecentFileNames.Count-1 do
    Owner.Edit.RecentFiles.Add( RecentFileNames.ValueFromIndex[I] );
  FreeAndNil( RecentFileNames );
  if assigned( Owner.OnUpdateRecentFileList ) then Owner.OnUpdateRecentFileList( self );
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
      wsMinimized: begin MainForm.WindowState:=wsNormal;
                         MainForm.SetBounds( L,T,W,H ); end;
      wsMaximized: MainForm.WindowState:=wsMaximized;
    end;
  end;
  Language:=params.ReadString( 'General','Language',Language );
  LanguageFile:=LanguagesDirectory+Language+'.ini';          //~ConfigDirectory
  if not FileExistsUTF8( LanguageFile ) then begin
    Writeln( '?no file: '+LanguageFile ); Language:='English';
    LanguageFile:=ConfigDirectory+LanguagesDirectory+'English.ini';
  end;
  FbmEncoding :=params.ReadString( 'General','FbmEncoding',FbmEncoding );
  MaxUndoMemory:= params.ReadInteger('General','MaxUndoMemory',MaxUndoMemory);
  params.Free;
end;

procedure TFreePreferences.SetDefaults;
begin
  PointSize:=2;
  FontSize :=8;
  Language :='English';
  FbmEncoding:='cp1251';
  MaxUndoMemory:=64;
  ResetDirectories;
  ResetColors;
end;

procedure TFreePreferences.ResetDirectories;
begin
//ConfigDirectory:=ExtractFileDir( ParamStr( 0 ) );
  ConfigDirectory:=ExtractFilePath( Application.ExeName );
  SetCurrentDir( ConfigDirectory );
  LanguagesDirectory:='Languages\';
  ManualsDirectory  :='Manuals\';
  OpenDirectory     :='Ships\';
  SaveDirectory     :='Save\';
  ImportDirectory   :='Save\Import\';
  ExportDirectory   :='Save\Export\';
//ConfigDirectory:=ConfigDirectory+'\';
end;

procedure TFreePreferences.Load; begin setDefaults; LoadFromIni; end;

function TFreePreferences.OnlyName( const S: AnsiString; DS:boolean=true ): AnsiString;
  var L:Integer;
begin Result:=S;                   Result.Replace( '/','\' );
     L:=Length( ConfigDirectory ); Result:=trim( Result );
  if Result.StartsWith( ConfigDirectory ) then Result:=Result.SubString( L,Length(Result)-L );
  if DS then if Result[Length(Result)]<>'\' then Result:=Result+'\';
end;

procedure TFreePreferences.ResetColors; // Расцветка по умолчанию
begin
  FViewportColor:=clWhite;
  GridColor    :=clSilver;
  GridFontColor:=clGray;
  LayerColor   :=$FFFFF0;   // Default color each layer
  NormalColor  :=clLime;    // color of surface normals
  StationColor  :=$FF6464;  // =clBlue;
  ButtockColor  :=clGray;
  WaterlineColor:=clGreen;
  DiagonalColor :=$C08000;   //clSkyBlue;
  UnderwaterColor:=clGreen;
  UnderwaterColorAlpha:=192; // Color used for shading the underwater part opaque
  ControlCurveColor:=$FF0080;
  EdgeColor        :=$6F6F6F; // Color of normal edges (no crease)
  CreaseEdgeColor  :=$32CD9A; // Color of crease control edges
  CreaseColor      :=$999966; // color of descendants from crease controledges
  RegularPointColor:=$E1E1E1; // Color of regular controlpoints
  CreasePointColor:=$004080; // Color for vertices connected to two creaseedges
  CornerPointColor:=$B95C00; // color of cornerpoints
  DartPointColor  :=clFuchsia;
  LeakPointColor  :=clRed;    //~~ color of leak points
  SelectColor     :=clYellow; // Default color for selected items
  CurvaturePlotColor:=clFuchsia; // color of the curvature plot of controlcurves
  MarkerColor       :=$8000FF;
  HydrostaticsFontColor:=clGreen;
  ZebraStripeColor     :=clltGray;
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
  params.WriteString ( 'General','Language',Language );
  params.WriteString ( 'General','FbmEncoding',FbmEncoding );
  params.WriteInteger( 'General','MaxUndoMemory',MaxUndoMemory );
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
  params.WriteInteger( G,'PointSize',            PointSize);
  params.WriteInteger( G,'FontSize',             FontSize);
  params.WriteColor  ( G,'ViewportColor',        FViewportColor);
  params.WriteColor  ( G,'GridColor',            GridColor);
  params.WriteColor  ( G,'GridFontColor',        GridFontColor);
  params.WriteColor  ( G,'LayerColor',           LayerColor);
  params.WriteColor  ( G,'NormalColor',          NormalColor);
  params.WriteColor  ( G,'UnderWaterColor',      UnderWaterColor);
  params.WriteInteger( G,'UnderWaterColorAlpha', UnderWaterColorAlpha);
  params.WriteColor  ( G,'ControlCurveColor',    ControlCurveColor);
  params.WriteColor  ( G,'EdgeColor',            EdgeColor);
  params.WriteColor  ( G,'CreaseEdgeColor',      CreaseEdgeColor);
  params.WriteColor  ( G,'CreaseColor',          CreaseColor);
  params.WriteColor  ( G,'RegularPointColor',    RegularPointColor);
  params.WriteColor  ( G,'CreasePointColor',     CreasePointColor);
  params.WriteColor  ( G,'CornerPointColor',     CornerPointColor);
  params.WriteColor  ( G,'DartPointColor',       DartPointColor);
  params.WriteColor  ( G,'LeakPointColor',       LeakPointColor);
  params.WriteColor  ( G,'SelectColor',          SelectColor);
  params.WriteColor  ( G,'CurvaturePlotColor',   CurvaturePlotColor);
  params.WriteColor  ( G,'MarkerColor',          MarkerColor);
  params.WriteColor  ( G,'StationColor',         StationColor);
  params.WriteColor  ( G,'ButtockColor',         ButtockColor);
  params.WriteColor  ( G,'WaterlineColor',       WaterlineColor);
  params.WriteColor  ( G,'DiagonalColor',        DiagonalColor);
  params.WriteColor  ( G,'HydrostaticsFontColor',HydrostaticsFontColor);
  params.WriteColor  ( G,'ZebraStripeColor',     ZebraStripeColor);
  params.WriteInteger( G,'IntersectionLineWidth',FIntersectionLineWidth);
  params.WriteInteger( G,'ControlEdgeLineWidth', FControlEdgeLineWidth);
  params.WriteInteger( G,'InteriorEdgeLineWidth',FInteriorEdgeLineWidth);
  params.WriteInteger( G,'HydrostaticLineWidth', FHydrostaticLineWidth);
  params.WriteInteger( G,'AuxEdgeLineWidth',     FAuxEdgeLineWidth);
  params.EraseSection( 'RecentFiles');
  for I:=0 to Owner.Edit.RecentFiles.Count-1 do
    params.WriteString('RecentFiles','File'+IntToStr(I+1),Owner.Edit.RecentFiles[I] );
  if assigned( Owner.OnUpdateRecentFileList ) then Owner.OnUpdateRecentFileList( self );
end;

