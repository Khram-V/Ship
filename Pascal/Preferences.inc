{
   included in ShipUnit

   Preferences
   Container class for all program settings

}
const iniFileName='FreeShip.ini';
      G='Graphic';
      D='Directories';
      W='Window';

procedure TPreferences.FSetViewportColor( Val: TColor ); var I: integer;
    begin FViewportColor:=Val;
          for I:=0 to St.nV-1 do St.Viewport[I].Color:=FViewportColor;
    end;
procedure TPreferences.Clear;
    begin ResetColors;           PointSize:=2;
          ResetDirectories;      LastDirectory:='Ships\';
          Language:='Russian';   LanguageFile:='Russian.ini';
          FbmEncoding:='cp1251'; MaxUndoMemory:=128;     // Max 20Mb undomemory
    end;
constructor TPreferences.Create( Owner: TShip );
  begin inherited Create; St:=Owner; Clear; end;

procedure TPreferences.Edit;
var Dialog: TPreferencesDialog; Dir,Lang: String; I: integer;
  procedure Browse( Dir: String ); var SearchRec: TSearchRec;
    procedure Add( FileName:String ); var Tmp:String; I:integer; Found:boolean;
    begin
      Tmp:=ChangeFileExt( ExtractFilename( Filename ),'' ); found:=False;
      for I:=1 to Dialog.ComboBox1.Items.Count do
        if Uppercase( Tmp )=Uppercase(Dialog.Combobox1.Items[I-1]) then begin
          Found:=True; break;
        end;
      if not found then Dialog.Combobox1.Items.Add( Tmp );
    end;
  begin
    if Dir[Length(Dir)]<>'\' then Dir:=Dir+'\';
    if FindFirstUTF8(Dir+'*.ini',faAnyfile,SearchRec)=0 then begin
      if Uppercase(ExtractFileExt(SearchRec.Name))='.INI' then Add(Searchrec.Name);
      while FindNextUTF8(SearchRec)=0 do
        if (SearchRec.Name<>'.') and (SearchRec.Name<>'..') then
        if Uppercase(ExtractFileExt(SearchRec.Name))='.INI' then Add(Searchrec.Name);
      FindCloseUTF8(SearchRec);
    end;
  end;
begin
  Dialog:=TPreferencesDialog.Create( St );
  ShowTranslatedValues( Dialog );
  Dir:=LanguagesDirectory; // ConfigDirectory=установлена активная директория
  Dialog.ComboBox1.Items.Clear;
  Dialog.ComboBox1.Items.Add( 'Russian' ); Browse( Dir );
  Dialog.ComboBox1.ItemIndex:=0;
  for I:=1 to Dialog.ComboBox1.Items.Count do
    if Uppercase(Dialog.ComboBox1.Items[I-1])=Uppercase(Language) then begin
       Dialog.ComboBox1.ItemIndex:=I-1; break;
    end;
  if Dialog.Execute(St) then with Sp do begin
    Layer       :=Dialog.Panel2.Color;
    ViewportColor    :=Dialog.Panel4.Color; // Set viewportcolor last,because it forces a repaint
    UColor        :=Dialog.Panel5.Color;
    UAlfa:=Dialog.SubmergedOpacity.Value*255 div 100;
    Edge        :=Dialog.Panel6.Color;
    CreaseEdge  :=Dialog.Panel7.Color;
    Crease      :=Dialog.Panel8.Color;
    RegularPoint:=Dialog.Panel9.Color;
    CreasePoint :=Dialog.Panel10.Color;
    CornerPoint :=Dialog.Panel11.Color;
    DartPoint   :=Dialog.Panel12.Color;
    Select      :=Dialog.Panel13.Color;
    Grid        :=Dialog.Panel14.Color;
    GridFont    :=Dialog.Panel15.Color;
    Station     :=Dialog.Panel16.Color;
    Buttock     :=Dialog.Panel17.Color;
    Waterline   :=Dialog.Panel18.Color;
    Normal      :=Dialog.Panel19.Color;
    Diagonal    :=Dialog.Panel20.Color;
    LeakPoint   :=Dialog.Panel21.Color;
    Marker      :=Dialog.Panel22.Color;
    CurvaturePlot:= Dialog.Panel23.Color;
    ControlCurve:=Dialog.Panel24.Color;
    HydrostaticsFont:= Dialog.Panel25.Color;
    ZebraStripe :=Dialog.Panel26.Color;
    PointSize:=Dialog.SpinEdit1.Value;
    FontSize:=Dialog.seFontSize.Value;
    Lang:=Dialog.Combobox1.Text;
    LanguagesDirectory:=OnlyName( Dialog.EditLanguagesDir.Text );
    ManualsDirectory  :=OnlyName( Dialog.EditManualsDir.Text );
    OpenDirectory     :=OnlyName( Dialog.EditOpenDir.Text );
    SaveDirectory     :=OnlyName( Dialog.EditSaveDir.Text );
    ImportDirectory   :=OnlyName( Dialog.EditImportDir.Text );
    ExportDirectory   :=OnlyName( Dialog.EditExportDir.Text );
    if Uppercase( Lang )<>Uppercase( Language ) then begin
      LanguageFile:=LanguagesDirectory+Lang+'.ini';
      if FileExistsUTF8( LanguageFile )then begin
        LoadLanguage( Lang,LanguageFile );
        Language:=Lang;
        for I:=1 to Application.ComponentCount do
        if Application.Components[I-1] is TCustomForm
           then ShowTranslatedValues( Application.Components[I-1] );
        with Application.MainForm as TMainForm do
         for I:=1 to St.nV do ShowTranslatedValues( St.ViewPort[I-1] );
         if LinesplanFrame<>nil then ShowTranslatedValues( LinesplanFrame );
       end;
    end;
    FbmEncoding:=string( Dialog.ComboBoxEncoding.Items.Objects[Dialog.ComboBoxEncoding.ItemIndex] );
    MaxUndoMemory:=Dialog.NumInput1.Value;
    if assigned(St.OnFileChanged) then St.OnFileChanged(St);
    if assigned(St.OnUpdateUndoData) then St.OnUpdateUndoData(St);
    if assigned(St.OnUpdateRecentFileList) then St.OnUpdateRecentFileList(St);
    if assigned(St.OnChangeCursorIncrement) then St.OnChangeCursorIncrement(St);
    if assigned(St.OnUpdateGeometryInfo) then St.OnUpdateGeometryInfo(St);
    St.Redraw;
    end;
  FreeAndNil(Dialog);
end;
function TColorIniFile.ReadColor(const Section,Ident:String; Default:TColor): TColor;
begin Result:=StringToColor(ReadString(Section,Ident,ColorToString(Default)));
end;
procedure TColorIniFile.WriteColor(const Section,Ident:String; Value:TColor);
begin WriteString( Section,Ident,'$'+HexStr(Value,6) ); // ColorToString( Value ) );
end;
procedure TPreferences.LoadFromIni;
var I,T,L,R,H,S: Integer; params: TColorIniFile; RecentFileNames: TStringList;
begin
  if not FileExistsUTF8( iniFileName ) then begin        // и так на весь экран
{   if Application.Mainform<>nil then begin
       Application.MainForm.WindowState:=wsNormal;
       Application.MainForm.SetBounds( 0,0,min(1280,Screen.WorkAreaWidth),
                                       //  min(768,Application.Mainform.ClientHeight) );
                                           min(768,Screen.WorkAreaHeight-52) );
    end;
}   SetDefaults; exit;
  end;
  params:=TColorIniFile.Create( iniFilename,False );
  LastDirectory     :=params.ReadString(D,'LastDirectory',LastDirectory);
  OpenDirectory     :=params.ReadString(D,'OpenDirectory',OpenDirectory);
  SaveDirectory     :=params.ReadString(D,'SaveDirectory',SaveDirectory);
  ImportDirectory   :=params.ReadString(D,'ImportDirectory',ImportDirectory);
  ExportDirectory   :=params.ReadString(D,'ExportDirectory',ExportDirectory);
  LanguagesDirectory:=params.ReadString(D,'LanguagesDirectory',LanguagesDirectory);
  ManualsDirectory  :=params.ReadString(D,'ManualsDirectory',ManualsDirectory);
  PointSize        :=params.ReadInteger(G,'PointSize',PointSize);
  FontSize         :=params.ReadInteger(G,'FontSize',FontSize);
  with Sp do begin
    Station      :=params.ReadColor (G,'StationColor',Station);
    Buttock      :=params.ReadColor (G,'ButtockColor',Buttock);
    Waterline    :=params.ReadColor (G,'WaterlineColor',Waterline);
    Diagonal     :=params.ReadColor (G,'DiagonalColor',Diagonal);
    UColor       :=params.ReadColor (G,'UnderWaterColor',UColor);
    UAlfa        :=params.ReadInteger(G,'UnderWaterColorAlpha',UAlfa);
    Crease       :=params.ReadColor (G,'CreaseColor',Crease);
    CreaseEdge   :=params.ReadColor (G,'CreaseEdgeColor',CreaseEdge);
    Grid         :=params.ReadColor (G,'GridColor',Grid);
    GridFont     :=params.ReadColor (G,'GridFontColor',GridFont);
    Edge         :=params.ReadColor (G,'EdgeColor',Edge);
    CreasePoint  :=params.ReadColor (G,'CreasePointColor',CreasePoint);
    RegularPoint :=params.ReadColor (G,'RegularPointColor',RegularPoint);
    CornerPoint  :=params.ReadColor (G,'CornerPointColor',CornerPoint);
    DartPoint    :=params.ReadColor (G,'DartPointColor',DartPoint);
    Select       :=params.ReadColor (G,'SelectColor',Select);
    Layer        :=params.ReadColor (G,'LayerColor',Layer);
    Normal       :=params.ReadColor (G,'NormalColor',Normal);
    LeakPoint    :=params.ReadColor (G,'LeakPointColor',LeakPoint);
    Marker       :=params.ReadColor (G,'MarkerColor',Marker);
    CurvaturePlot:=params.ReadColor (G,'CurvaturePlotColor',CurvaturePlot);
    ControlCurve :=params.ReadColor (G,'ControlCurveColor',ControlCurve);
    HydrostaticsFont:=params.ReadColor(G,'HydrostaticsFontColor',HydrostaticsFont);
    ZebraStripe  :=params.ReadColor (G,'ZebraStripeColor',ZebraStripe);
    FViewportColor:=params.ReadColor (G,'ViewportColor',FViewportColor );
//  IntersectionLW:= params.ReadInteger(G,'IntersectionLineWidth',IntersectionLW);
//  ControlEdgeLW:=params.ReadInteger(G,'ControlEdgeLineWidth',ControlEdgeLW);
//  InteriorEdgeLW:= params.ReadInteger(G,'InteriorEdgeLineWidth',InteriorEdgeLW);
//  HydrostaticLW:=params.ReadInteger(G,'HydrostaticLineWidth',HydrostaticLW);
//  AuxEdgeLW    :=params.ReadInteger(G,'AuxEdgeLineWidth',AuxEdgeLW);
  end;
  RecentFileNames:=TStringList.Create;
  params.ReadSectionValues( 'RecentFiles',RecentFileNames );
  St.Edit.RecentFiles.Clear;
  St.Edit.RecentFiles.Capacity:=RecentFileNames.Count;
  for I:=0 to RecentFileNames.Count-1 do
    St.Edit.RecentFiles.Add( RecentFileNames.ValueFromIndex[I] );
  FreeAndNil( RecentFileNames );
  if assigned( St.OnUpdateRecentFileList ) then St.OnUpdateRecentFileList( self );
  T:=params.ReadInteger( W,'Top',1 );
  L:=params.ReadInteger( W,'Left',1 );
  R:=max(params.ReadInteger( W,'Width',min(1280,Screen.WorkAreaWidth)),1280);
  H:=max(params.ReadInteger( W,'Height',min(768,Screen.WorkAreaHeight-52)),768);
  S:=params.ReadInteger( W,'State',ord( wsNormal ) ); if S=1 then S:=0;
  if Application.Mainform<>nil then
  { TWindowState=(wsNormal=0,wsMinimized=1,wsMaximized=2,wsFullScreen=3); }
  case TWindowState( S ) of
       wsNormal: Application.MainForm.SetBounds( L,T,R,H );
//     wsMinimized: begin Application.MainForm.WindowState:=wsNormal;
//                        Application.MainForm.SetBounds(L,T,R,H); end;
       wsMaximized: Application.MainForm.WindowState:=wsMaximized;
       wsFullScreen: Application.MainForm.WindowState:=wsFullScreen;
  end;
  Language:=params.ReadString( 'General','Language',Language );
  LanguageFile:=LanguagesDirectory+Language+'.ini';         // ~ConfigDirectory
  if not FileExistsUTF8( LanguageFile ) then begin
  { Writeln( '?no file: '+LanguageFile ); } Language:='Russian'; // UserString( 1230 )+
    LanguageFile:=ConfigDirectory+LanguagesDirectory+'Russian.ini';
  end;
  FbmEncoding :=params.ReadString( 'General','FbmEncoding',FbmEncoding );
  MaxUndoMemory:= params.ReadInteger('General','MaxUndoMemory',MaxUndoMemory);
  params.Free;
end;

procedure TPreferences.SetDefaults;
begin
  PointSize:=2;
  FontSize :=8; //12;
  Language :='Russian';
  FbmEncoding:='cp1251';
  MaxUndoMemory:=128;
  ResetDirectories;
  ResetColors;
end;

procedure TPreferences.ResetDirectories;
begin
//ConfigDirectory:=ExtractFileDir( ParamStr( 0 ) );
  ConfigDirectory:=ExtractFilePath( Application.ExeName );
  SetCurrentDirUTF8( ConfigDirectory );
  LanguagesDirectory:='Languages\';
  ManualsDirectory  :='Manuals\';
  OpenDirectory     :='Ships\';
  SaveDirectory     :='Save\';
  ImportDirectory   :='Save\Import\';
  ExportDirectory   :='Save\Export\';
end;

procedure TPreferences.Load; begin setDefaults; LoadFromIni; end;

function TPreferences.OnlyName( const S: String; DS:boolean=true ): String;
  var L:Integer;
begin Result:=S;                   Result.Replace( '/','\' );
     L:=Length( ConfigDirectory ); Result:=trim( Result );
  if Result.StartsWith( ConfigDirectory ) then Result:=Result.SubString( L,Length(Result)-L );
  if DS then if Result[Length(Result)]<>'\' then Result:=Result+'\';
end;

procedure TPreferences.ResetColors; // Расцветка по умолчанию
begin with Sp do begin
  FViewportColor:=clWhite;
  Grid    :=clSilver;
  GridFont:=clGray;
  Layer   :=$FFFFF0;   // Default color each layer
  Normal  :=clLime;    // color of surface normals
  Station  :=$FF6464;  // =clBlue;
  Buttock  :=clGray;
  Waterline:=clGreen;
  Diagonal :=$C08000;  //clSkyBlue;
  UColorIs:=true;
  UColor:=clGreen;
  UAlfa:=128;           // Color used for shading the underwater part opaque
  ControlCurve:=$FF0080;
  Edge        :=$6F6F6F; // Color of normal edges (no crease)
  CreaseEdge  :=$32CD9A; // Color of crease control edges
  Crease      :=$999966; // color of descendants from crease controledges
  RegularPoint:=$A0A000; // $E1E1E1; // Color of regular controlpoints
  CreasePoint :=$004080; // Color for vertices connected to two creaseedges
  CornerPoint :=clBlue;  // $B95C00; // color of cornerpoints
  DartPoint   :=clFuchsia;
  LeakPoint   :=clRed;    //~~ color of leak points ~~ clTeal; clAqua;
  Select      :=clYellow; // Default color for selected items
  CurvaturePlot:=clFuchsia;// color of the curvature plot of controlcurves
  Marker       :=$8000FF;
  HydrostaticsFont:=clGreen;
  ZebraStripe     :=clltGray;
  CurvatureScale:=1.0;        // собрание из трёх структур
//  IntersectionLW:=1;
//  ControlEdgeLW :=2;
//  InteriorEdgeLW:=1;
//  AuxEdgeLW     :=1;
//  HydrostaticLW :=1;
end end;

procedure TPreferences.Save;
 var  I:integer; params:TColorIniFile;
begin
//  if not FileExistsUTF8( Filename ) then exit;
//  then ForceDirectoriesUTF8( ExtractFilePath( Filename ) ); // ~~ и то зря
  params:=TColorIniFile.Create( iniFilename,False );
  params.WriteString ( 'General','Language',Language );
  params.WriteString ( 'General','FbmEncoding',FbmEncoding );
  params.WriteInteger( 'General','MaxUndoMemory',MaxUndoMemory );
  params.WriteString( D,'LanguagesDirectory',OnlyName( LanguagesDirectory));
  params.WriteString( D,'ManualsDirectory', OnlyName( ManualsDirectory));
  params.WriteString( D,'OpenDirectory',    OnlyName( OpenDirectory   ));
  params.WriteString( D,'SaveDirectory',    OnlyName( SaveDirectory   ));
  params.WriteString( D,'ImportDirectory',  OnlyName( ImportDirectory ));
  params.WriteString( D,'ExportDirectory',  OnlyName( ExportDirectory ));
  params.WriteString( D,'LastDirectory',    OnlyName( LastDirectory   ));
  if Application.MainForm<>nil then With Application.MainForm do begin
  params.WriteInteger( W,'Top',Top);
  params.WriteInteger( W,'Left',Left);
  params.WriteInteger( W,'Height',Height);
  params.WriteInteger( W,'Width',Width);
  params.WriteInteger( W,'State',integer( WindowState)); end;
  params.WriteInteger( G,'PointSize',           PointSize);
  params.WriteInteger( G,'FontSize',            FontSize);
  params.WriteColor  ( G,'ViewportColor',       FViewportColor);
  params.WriteColor  ( G,'GridColor',           Sp.Grid);
  params.WriteColor  ( G,'GridFontColor',       Sp.GridFont);
  params.WriteColor  ( G,'LayerColor',          Sp.Layer);
  params.WriteColor  ( G,'NormalColor',         Sp.Normal);
  params.WriteColor  ( G,'UnderWaterColor',     Sp.UColor);
  params.WriteInteger( G,'UnderWaterColorAlpha',Sp.UAlfa);
  params.WriteColor  ( G,'ControlCurveColor',   Sp.ControlCurve);
  params.WriteColor  ( G,'EdgeColor',           Sp.Edge);
  params.WriteColor  ( G,'CreaseEdgeColor',     Sp.CreaseEdge);
  params.WriteColor  ( G,'CreaseColor',         Sp.Crease);
  params.WriteColor  ( G,'RegularPointColor',   Sp.RegularPoint);
  params.WriteColor  ( G,'CreasePointColor',    Sp.CreasePoint);
  params.WriteColor  ( G,'CornerPointColor',    Sp.CornerPoint);
  params.WriteColor  ( G,'DartPointColor',      Sp.DartPoint);
  params.WriteColor  ( G,'LeakPointColor',      Sp.LeakPoint);
  params.WriteColor  ( G,'SelectColor',         Sp.Select);
  params.WriteColor  ( G,'CurvaturePlotColor',  Sp.CurvaturePlot);
  params.WriteColor  ( G,'MarkerColor',         Sp.Marker);
  params.WriteColor  ( G,'StationColor',        Sp.Station);
  params.WriteColor  ( G,'ButtockColor',        Sp.Buttock);
  params.WriteColor  ( G,'WaterlineColor',      Sp.Waterline);
  params.WriteColor  ( G,'DiagonalColor',       Sp.Diagonal);
  params.WriteColor  ( G,'HydrostaticsFontColor',Sp.HydrostaticsFont);
  params.WriteColor  ( G,'ZebraStripeColor',    Sp.ZebraStripe);
//  params.WriteInteger( G,'IntersectionLineWidth',Sp.IntersectionLW);
//  params.WriteInteger( G,'ControlEdgeLineWidth',Sp.ControlEdgeLW);
//  params.WriteInteger( G,'InteriorEdgeLineWidth',Sp.InteriorEdgeLW);
//  params.WriteInteger( G,'HydrostaticLineWidth',Sp.HydrostaticLW);
//  params.WriteInteger( G,'AuxEdgeLineWidth',    Sp.AuxEdgeLW);
  params.EraseSection( 'RecentFiles');
  for I:=0 to St.Edit.RecentFiles.Count-1 do
    params.WriteString('RecentFiles','File'+IntToStr(I+1),St.Edit.RecentFiles[I] );
  if assigned( St.OnUpdateRecentFileList ) then St.OnUpdateRecentFileList( self );
end;

