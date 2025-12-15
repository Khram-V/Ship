unit PreferencesDlg;
interface uses
  LCLIntf, LCLType,
  SysUtils,Variants,
  Classes, Graphics,
  Controls,Forms,
  Dialogs, StdCtrls,
  Buttons, ExtCtrls,
  ComCtrls,Spin,Menus, ShipUnit;
type                                                 { TPreferencesDialog }
  TPreferencesDialog=class(TForm)
    EditExportDir,EditImportDir,EditLanguagesDir,
    EditManualsDir,EditOpenDir,EditSaveDir: TEdit;
    lbSubmergedSurfaceOpacity,
    Label1,Label2,Label3,Label4,Label5,Label6,Label7,Label8,Label9,Label10,
    Label11,Label12,Label13,Label14,Label15,Label16,Label17,Label18,Label19,
    Label20,Label21,Label22,Label23,Label24,Label25,Label26,Label27,Label28,
    Label29,Label32,Label33,Label34,Label35,LabelEncoding,LabelLanguagesDir:
                                                                     TLabel;
    Panel,Panel1,Panel2,Panel3,Panel4,Panel5,Panel6,Panel7,Panel8,Panel9,
    Panel10,Panel11,Panel12,Panel13,Panel14,Panel15,Panel16,Panel17,Panel18,
    Panel19,Panel20,Panel21,Panel22,Panel23,Panel24,Panel25,Panel26,Panel27,
    Panel30,Panel31,Panel32,Panel33,Panel36,Panel38,Panel39,Panel40,Panel41,
    Panel42,Panel43,Panel44,Panel45,Panel46,Panel50,Panel51,Panel52,Panel53,
    Panel54,Panel55,Panel56,Panel57,ButtonPanel:                     TPanel;
    BitBtnResetDirs,BitBtnResetColors,
    BitBtn1,BitBtn2,SpeedButton9,SpeedButton14,SpeedButton15,
    SpeedButton16,SpeedButton17,SpeedButtonLanguagesDir:       TSpeedButton;
    SpinEdit1,seFontSize,seSubmergedSurfaceOpacity,NumInput1: TSpinEdit;
    TabSheet1,TabSheet2,TabSheet3:                                TTabSheet;
    ComboBox1,ComboBoxEncoding:                                   TComboBox;
    SelectDirectoryDialog1:                          TSelectDirectoryDialog;
    PageControl1:                                              TPageControl;
    ColorDialog:                                               TColorDialog;
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ResetColorsButtonClick(Sender: TObject);
    procedure ColorPanelClick(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure ResetDirsButtonClick(Sender: TObject);
    procedure EditDirChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure SpeedButton14Click(Sender: TObject);
    procedure SpeedButton15Click(Sender: TObject);
    procedure SpeedButton16Click(Sender: TObject);
    procedure SpeedButton17Click(Sender: TObject);
    procedure SpeedButtonLanguagesDirClick(Sender: TObject);
    procedure SpeedButton9Click(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure seSubmergedSurfaceOpacityChange(Sender: TObject);
  private                                             { Private declarations }
    Fship: TShip;
    FConfigChanged: boolean;
    procedure Updatedata;
    procedure ComboBoxEncodingFillItems;
    function getPreferredSize:TRect; reintroduce;
  public                                                { Public declarations }
    property IsConfigChanged: boolean read FConfigChanged;
    function Execute( ship: TShip ): boolean;
  end;

var PreferencesDialog: TPreferencesDialog;

const rs_Save='Are you sure you want to reset the preferences?'
                +#13#10+'The current settings will be lost.';

implementation
{$R *.lfm}

procedure TPreferencesDialog.Updatedata;
var I: integer;
begin                                                         //  Label Panel Top
  Panel4.Color:=Fship.Preferences.ViewportColor;          //    1    4    4   'Viewport background'
  Panel14.Color:=Fship.Preferences.GridColor;             //    12   14   32  'Viewport grid'
  Panel15.Color:=Fship.Preferences.GridFontColor;         //    3    5    60  'Grid font'
  Panel2.Color:=Fship.Preferences.LayerColor;             //    2    2    94  'New surfaces'
  Panel19.Color:=Fship.Preferences.NormalColor;           //   18    19   122 'Surface normals'
  Panel5.Color:=Fship.Preferences.UnderWaterColor;        //    3    5    150 'Submerged surfaces'
  seSubmergedSurfaceOpacity.Value:=Fship.Preferences.UnderWaterColorAlpha*100 div 255; // 178 'Submerged surface opacity,%'
  Panel24.Color:=Fship.Preferences.ControlCurveColor;     //   23    24   220 'Control curves'
  Panel6.Color:=Fship.Preferences.EdgeColor;              //    4    6    248 'Regular control edges'
  Panel7.Color:=Fship.Preferences.CreaseEdgeColor;        //    5    17   276 'Crease edges (control)'
  Panel8.Color:=Fship.Preferences.CreaseColor;            //    6    8    304 'Crease edges (interior)'
  Panel9.Color:=Fship.Preferences.RegularPointColor;      //    7    9      4 'Regular control points'
  Panel10.Color:=Fship.Preferences.CreasePointColor;      //    8    10    32 'Crease points'
  Panel11.Color:=Fship.Preferences.CornerPointColor;      //    9    11    60 'Corner points'
  Panel12.Color:=Fship.Preferences.DartPointColor;        //   10    12    88 'Dart points'
  Panel21.Color:=Fship.Preferences.LeakPointColor;        //   20    21   116 'Leak points'
  Panel13.Color:=Fship.Preferences.SelectColor;           //   11    13   150 'Selected items'
  Panel23.Color:=Fship.Preferences.CurvaturePlotColor;    //   22    23   178 'Curvature plots'
  Panel22.Color:=Fship.Preferences.MarkerColor;           //   21    33   206 'Markers'
  Panel16.Color:=Fship.Preferences.StationColor;          //   14    16   234 'Stations'
  Panel17.Color:=Fship.Preferences.ButtockColor;          //   15    17   262 'Buttocks'
  Panel18.Color:=Fship.Preferences.WaterlineColor;        //   16    18   290 'Waterlines'
  Panel20.Color:=Fship.Preferences.DiagonalColor;         //   19    20   318 'Diagonals'
  Panel25.Color:=Fship.Preferences.HydrostaticsFontColor; //   24    25   346 'Hydrostatics font color'
  Panel26.Color:=Fship.Preferences.ZebraStripeColor;      //   25    26   374 'Zebra stripes color'
{ object ColorDialog: TColorDialog
    Color=clBlack
    CustomColors.Strings=(
      'ColorA=000000' 'ColorB=000080' 'ColorC=008000' 'ColorD=008080'
      'ColorE=800000' 'ColorF=800080' 'ColorG=808000' 'ColorH=808080'
      'ColorI=C0C0C0' 'ColorJ=0000FF' 'ColorK=00FF00' 'ColorL=00FFFF'
      'ColorM=FF0000' 'ColorN=FF00FF' 'ColorO=FFFF00' 'ColorP=FFFFFF'
      'ColorQ=C0DCC0' 'ColorR=C08000' 'ColorS=F0FBFF' 'ColorT=A4A0A0' <-F0CAA6'
    ) Left=240
  end
}
  SpinEdit1.Value:=Fship.Preferences.PointSize;
  seFontSize.Value:=Fship.Preferences.FontSize;
  if Fship.Preferences.MaxUndoMemory<1
     then NumInput1.Value:=1
     else NumInput1.Value:=Fship.Preferences.MaxUndoMemory;
  with Fship.Preferences do begin
    EditLanguagesDir.Text:=OnlyName( LanguagesDirectory );
    EditManualsDir.Text:=  OnlyName( ManualsDirectory );
    EditOpenDir.Text:=     OnlyName( OpenDirectory );
    EditSaveDir.Text:=     OnlyName( SaveDirectory );
    EditImportDir.Text:=   OnlyName( ImportDirectory );
    EditExportDir.Text:=   OnlyName( ExportDirectory );
  end;
  ComboBoxEncodingFillItems;
  for I:=0 to ComboBoxEncoding.Items.Count-1 do
    if string( ComboBoxEncoding.Items.Objects[i] ) =
               Fship.Preferences.FbmEncoding then break;
  if I>ComboBoxEncoding.Items.Count then I:=-1;
       ComboBoxEncoding.ItemIndex:=I;
end;

function TPreferencesDialog.Execute(ship: TShip): boolean;
begin
  Fship:=ship;
  Updatedata;
  FConfigChanged:=False;
  Showmodal;
  Fship.Preferences.PointSize:=SpinEdit1.Value;
  Fship.Preferences.FontSize:=seFontSize.Value;
  Result:=ModalResult=mrOk;
end;

procedure TPreferencesDialog.ColorPanelClick(Sender: TObject);
var Panel: TPanel;
begin
  if (Sender.ClassType<>TPanel) then exit;
  Panel:=TPanel(Sender);
  ColorDialog.Color:=Panel.Color;
  if ColorDialog.Execute then
  if ColorDialog.Color<>Panel.Color then begin
    Panel.Color:=ColorDialog.Color;
    FConfigChanged:=true;
  end;
end;

procedure TPreferencesDialog.ResetColorsButtonClick(Sender: TObject);
    begin if MessageDlg( rs_Save,mtWarning,[mbYes,mbNo],0)=mrYes
          then begin Fship.Preferences.ResetColors; Updatedata; end;
    end;
procedure TPreferencesDialog.FormResize(Sender: TObject); var sz:TRect;
    begin sz:=getPreferredSize; end;
procedure TPreferencesDialog.FormShow(Sender: TObject); var sz:TRect;
    begin sz:=getPreferredSize; end;
procedure TPreferencesDialog.OkButtonClick(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TPreferencesDialog.CancelButtonClick(Sender: TObject);
    begin ModalResult:=mrCancel; end;
procedure TPreferencesDialog.EditDirChange(Sender: TObject);
    begin FConfigChanged:=True; end;
procedure TPreferencesDialog.PageControl1Change(Sender: TObject);
    begin FormActivate(Sender); end;
procedure TPreferencesDialog.FormActivate(Sender: TObject); var sz:TRect;
    begin sz:=getPreferredSize; end;
function TPreferencesDialog.getPreferredSize:TRect;
var TxH,HdrHeight,BrdWidth,TbT,PgT,PnT,PGIB: integer; ScreenPoint: TPoint;
begin
  Invalidate;
//Application.ProcessMessages;
  ScreenPoint:=ButtonPanel.ClientToScreen( Point(0,0) );
  HdrHeight:=ScreenPoint.Y-self.Top;
  BrdWidth:=ScreenPoint.X-self.Left;
  HdrHeight:=HdrHeight-BrdWidth;
{   Tabsheet1.AdjustSize;
    Tabsheet1.Repaint;
//  Tabsheet1.Invalidate;
    TabSheet2.AdjustSize;
    PageControl1.AdjustSize;
    Panel1.AdjustSize;
    ButtonPanel.AdjustSize;
    self.AdjustSize;
    Application.ProcessMessages;
}
  TbT:=TabSheet2.ClientToParent( Point(0,0),self ).Y;
  PgT:=PageControl1.ClientToParent( Point(0,0),self ).Y;
  PnT:=Panel1.ClientToParent( Point(0,0),self ).Y;
//TbH:=PgT-PnT-Panel1.BorderWidth-Panel1.BorderSpacing.InnerBorder;
  PGIB :={EditImportDir}Panel42.Height*10+TabSheet2.ChildSizing.VerticalSpacing*9;
//PGIB:=PanelGlobalImportDir.Height*10+TabSheet2.ChildSizing.VerticalSpacing*9;
  TxH:=PGIB+TabSheet2.ChildSizing.TopBottomSpacing*2 + //TbH +
    Panel1.BorderWidth*2+Panel1.BorderSpacing.InnerBorder*2 +
    ButtonPanel.Height+HdrHeight+BrdWidth*2;
{ if self.Constraints.MinHeight < TxH then self.Constraints.MinHeight:=TxH; }
  result:=Rect( 0,0,Width,BitBtnResetDirs.Top+BitBtnResetDirs.Height+16 );
end;

procedure TPreferencesDialog.SpinEdit1Change(Sender: TObject);
    begin FConfigChanged:=True; end;
procedure TPreferencesDialog.seSubmergedSurfaceOpacityChange(Sender: TObject);
    begin FConfigChanged:=True;
      Fship.Preferences.UnderWaterColorAlpha:=(seSubmergedSurfaceOpacity.Value*255) div 100;
    end;
procedure TPreferencesDialog.ResetDirsButtonClick(Sender: TObject);
    begin if MessageDlg( rs_Save,mtWarning,[mbYes,mbNo],0 )=mrYes
          then begin Fship.Preferences.ResetDirectories; end;
    end;
procedure TPreferencesDialog.SpeedButtonLanguagesDirClick(Sender: TObject);
    begin SelectDirectoryDialog1.FileName:=EditLanguagesDir.Text;
       if SelectDirectoryDialog1.Execute then
          EditLanguagesDir.Text:=SelectDirectoryDialog1.FileName;
    end;
procedure TPreferencesDialog.SpeedButton9Click(Sender: TObject);
begin SelectDirectoryDialog1.FileName:=EditManualsDir.Text;
   if SelectDirectoryDialog1.Execute then
      EditManualsDir.Text:=SelectDirectoryDialog1.FileName;
end;
procedure TPreferencesDialog.SpeedButton14Click(Sender: TObject);
begin SelectDirectoryDialog1.FileName:=EditOpenDir.Text;
   if SelectDirectoryDialog1.Execute then
      EditOpenDir.Text:=SelectDirectoryDialog1.FileName;
end;
procedure TPreferencesDialog.SpeedButton15Click(Sender: TObject);
begin SelectDirectoryDialog1.FileName:=EditSaveDir.Text;
   if SelectDirectoryDialog1.Execute then
      EditSaveDir.Text:=SelectDirectoryDialog1.FileName;
end;
procedure TPreferencesDialog.SpeedButton16Click(Sender: TObject);
begin SelectDirectoryDialog1.FileName:=EditImportDir.Text;
   if SelectDirectoryDialog1.Execute then
      EditImportDir.Text:=SelectDirectoryDialog1.FileName;
end;
procedure TPreferencesDialog.SpeedButton17Click(Sender: TObject);
begin SelectDirectoryDialog1.FileName:=EditExportDir.Text;
   if SelectDirectoryDialog1.Execute then
      EditExportDir.Text:=SelectDirectoryDialog1.FileName;
end;
procedure TPreferencesDialog.ComboBoxEncodingFillItems; // для *.fbm фалов
begin                                                      // или совместимость
  with ComboBoxEncoding.Items do begin                    // к старым версиям
    AddObject('UTF-8 (Unicode Transformation Format,8-bit) — стандарт кодирования Unicode(65001)',TObject(string('utf8')));
    AddObject('CP866 Русский DOS and Windows console',TObject(string('cp866')));
    AddObject('CP950 中文 (漢語/汉语) Traditional Chinese(Taiwan; Hong Kong SAR,PRC); Chinese Traditional(Big5)',TObject(string('cp950')));
    AddObject('CP1251 Русский (Windows)',TObject(string('cp1251')));
    AddObject('CP1252 Latin; Western European',TObject(string('cp1252')));
    AddObject('CP1255 עִבְרִית Hebrew',TObject(string('cp1255')));
    AddObject('CP1258 Việt ngữ (越語) Vietnam',TObject(string('cp1258')));
(*  AddObject('ISO_8859_1-Central Europe',TObject(string('iso88591')));
    AddObject('ISO_8859_15-Western European languages',TObject(string('iso885915')));
    AddObject('ISO_8859_2-Eastern Europe',TObject(string('iso88592')));
    AddObject('CP1250- Central Europe',TObject(string('cp1250')));
    AddObject('CP1253- Greek', TObject(string('cp1253')));
    AddObject('CP1254- Turkish',TObject(string('cp1254')));
    AddObject('CP1256- Arabic',TObject(string('cp1256')));
    AddObject('CP1257- Baltic',TObject(string('cp1257')));
    AddObject( 'CP437- DOS Central Europe',TObject(string('cp437')));
    AddObject( 'CP850- DOS Western Europe',TObject(string('cp850')));
    AddObject( 'CP852- DOS Central Europe',TObject(string('cp852')));
    AddObject( 'CP874- Thai',TObject(string('cp874')));
    AddObject(  'KOI8- Russian Cyrillic',TObject(string('koi8')));
*)end;
end;

end.
