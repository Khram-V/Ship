
unit FreePreferencesDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, LCLType,
{$ENDIF}
  //Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Buttons,
  ExtCtrls,
  FreeShipUnit,
  ComCtrls,
  Spin, Menus; //ValEdit,

type

{$IFDEF ZWindows}
  TTabSheet = class(ComCtrls.TTabSheet)
  protected
    //procedure PaintWindow(DC: HDC); override;
  public
    ActualColor: TColor;
  end;
{$ENDIF}

  { TFreePreferencesDialog }

  TFreePreferencesDialog = class(TForm)
    BitBtnResetDirs: TSpeedButton;
    BitBtnResetColors: TSpeedButton;
    ComboBox1: TComboBox;
    ComboBoxEncoding: TComboBox;
//  ComboBoxThemes: TComboBox;
    EditExportDir: TEdit;
    EditImportDir: TEdit;
    EditLanguagesDir: TEdit;
    EditManualsDir: TEdit;
    EditOpenDir: TEdit;
    EditSaveDir: TEdit;
    FreeNumInput1: TSpinEdit;
//  EditExecDir: TEdit;
//  EditGlobalImportDir: TEdit;
//  EditGlobalOpenDir: TEdit;
//  EditTempDir: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label2: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    lbSubmergedSurfaceOpacity: TLabel;
    Label29: TLabel;
    Label3: TLabel;
//  Label30: TLabel;
//  Label31: TLabel;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
//  Label36: TLabel;
//  Label37: TLabel;
//  Label38: TLabel;
//  Label39: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LabelEncoding: TLabel;
    LabelLanguagesDir: TLabel;
    PageControl1: TPageControl;
    Panel: TPanel;
    Panel1: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel2: TPanel;
    Panel20: TPanel;
    Panel21: TPanel;
    Panel22: TPanel;
    Panel23: TPanel;
    Panel24: TPanel;
    Panel25: TPanel;
    Panel26: TPanel;
    Panel27: TPanel;
    ButtonPanel: TPanel;
    BitBtn2: TSpeedButton;
    ColorDialog: TColorDialog;
//  Panel28: TPanel;
//  Panel29: TPanel;
    Panel3: TPanel;
    Panel30: TPanel;
    Panel31: TPanel;
    Panel32: TPanel;
    Panel33: TPanel;
//  Panel34: TPanel;
//  Panel35: TPanel;
    Panel36: TPanel;
//  Panel37: TPanel;
    Panel38: TPanel;
    Panel39: TPanel;
    Panel4: TPanel;
    Panel40: TPanel;
    Panel41: TPanel;
    Panel42: TPanel;
    Panel43: TPanel;
    Panel44: TPanel;
    Panel45: TPanel;
    Panel46: TPanel;
//  Panel47: TPanel;
//  Panel48: TPanel;
//  Panel49: TPanel;
    Panel5: TPanel;
    Panel50: TPanel;
    Panel51: TPanel;
    Panel52: TPanel;
    Panel53: TPanel;
    Panel54: TPanel;
    Panel55: TPanel;
    Panel56: TPanel;
    Panel57: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
//  PanelGlobalImportDir: TPanel;

    SelectDirectoryDialog1: TSelectDirectoryDialog;
    BitBtn1: TSpeedButton;
//  SelectToolIconSize: TComboBox;
//  SpeedButton12: TSpeedButton;
//  SpeedButton13: TSpeedButton;
    SpeedButton14: TSpeedButton;
    SpeedButton15: TSpeedButton;
    SpeedButton16: TSpeedButton;
    SpeedButton17: TSpeedButton;
//  SpeedButton18: TSpeedButton;
//  SpeedButton19: TSpeedButton;
    SpeedButton9: TSpeedButton;
    SpeedButtonLanguagesDir: TSpeedButton;
    SpinEdit1: TSpinEdit;
    seSubmergedSurfaceOpacity: TSpinEdit;
    seFontSize: TSpinEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ResetColorsButtonClick(Sender: TObject);
    procedure ColorPanelClick(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure Panel1Paint(Sender: TObject);
    procedure ResetDirsButtonClick(Sender: TObject);
//  procedure ComboBoxThemesChange(Sender: TObject);
    procedure EditDirChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
//  procedure SpeedButton12Click(Sender: TObject);
//  procedure SpeedButton13Click(Sender: TObject);
    procedure SpeedButton14Click(Sender: TObject);
    procedure SpeedButton15Click(Sender: TObject);
    procedure SpeedButton16Click(Sender: TObject);
    procedure SpeedButton17Click(Sender: TObject);
//  procedure SpeedButton18Click(Sender: TObject);
//  procedure SpeedButton19Click(Sender: TObject);
    procedure SpeedButtonLanguagesDirClick(Sender: TObject);
    procedure SpeedButton9Click(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure seSubmergedSurfaceOpacityChange(Sender: TObject);
  private   { Private declarations }
    FFreeship: TFreeShip;
    FConfigChanged: boolean;
//  FThemeChanged: boolean;
    procedure Updatedata;
    procedure ComboBoxEncodingFillItems;
    function getPreferredSize:TRect; reintroduce;
  public    { Public declarations }
//  property IsThemeChanged: boolean read FThemeChanged;
    property IsConfigChanged: boolean read FConfigChanged;
    //property Theme: string read ComboBoxThemes.Text;
    function Execute( Freeship: TFreeShip ): boolean;
  end;

var
  FreePreferencesDialog: TFreePreferencesDialog;

const rs_Save: String = 'Are you sure you want to reset the preferences?'
             + #13#10 + 'The current settings will be lost.';

implementation

{$IFnDEF FPC}
  {$R *.dfm}

{$ELSE}
  {$R *.lfm}
{$ENDIF}

procedure TFreePreferencesDialog.Updatedata;
var
  i: integer;
begin
  Panel4.Color := FFreeship.Preferences.ViewportColor;
  Panel2.Color := FFreeship.Preferences.LayerColor;
  Panel5.Color := FFreeship.Preferences.UnderWaterColor;
  seSubmergedSurfaceOpacity.Value := FFreeship.Preferences.UnderWaterColorAlpha * 100 div 255;
  Panel6.Color := FFreeship.Preferences.EdgeColor;
  Panel7.Color := FFreeship.Preferences.CreaseEdgeColor;
  Panel8.Color := FFreeship.Preferences.CreaseColor;
  Panel9.Color := FFreeship.Preferences.RegularPointColor;
  Panel10.Color := FFreeship.Preferences.CreasePointColor;
  Panel11.Color := FFreeship.Preferences.CornerPointColor;
  Panel12.Color := FFreeship.Preferences.DartPointColor;
  Panel13.Color := FFreeship.Preferences.SelectColor;
  Panel14.Color := FFreeship.Preferences.GridColor;
  Panel15.Color := FFreeship.Preferences.GridFontColor;
  Panel16.Color := FFreeship.Preferences.StationColor;
  Panel17.Color := FFreeship.Preferences.ButtockColor;
  Panel18.Color := FFreeship.Preferences.WaterlineColor;
  Panel19.Color := FFreeship.Preferences.NormalColor;
  Panel20.Color := FFreeship.Preferences.DiagonalColor;
  Panel21.Color := FFreeship.Preferences.LeakPointColor;
  Panel22.Color := FFreeship.Preferences.MarkerColor;
  Panel23.Color := FFreeship.Preferences.CurvaturePlotColor;
  Panel24.Color := FFreeship.Preferences.ControlCurveColor;
  Panel25.Color := FFreeship.Preferences.HydrostaticsFontColor;
  Panel26.Color := FFreeship.Preferences.ZebraStripeColor;
  SpinEdit1.Value := FFreeship.Preferences.PointSize;
  seFontSize.Value := FFreeship.Preferences.FontSize;
  if FFreeship.Preferences.MaxUndoMemory < 1 
     then FreeNumInput1.Value := 1
     else FreeNumInput1.Value := FFreeship.Preferences.MaxUndoMemory;

  EditLanguagesDir.Text := FFreeship.Preferences.LanguagesDirectory;
  EditManualsDir.Text := FFreeship.Preferences.ManualsDirectory;
  EditOpenDir.Text := FFreeship.Preferences.OpenDirectory;
  EditSaveDir.Text := FFreeship.Preferences.SaveDirectory;
  EditImportDir.Text := FFreeship.Preferences.ImportDirectory;
  EditExportDir.Text := FFreeship.Preferences.ExportDirectory;

  ComboBoxEncodingFillItems;
  for i := 0 to ComboBoxEncoding.Items.Count - 1 do
    if string(ComboBoxEncoding.Items.Objects[i]) =
      FFreeship.Preferences.FbmEncoding then
      break;
  if i > ComboBoxEncoding.Items.Count then i:=-1;
  ComboBoxEncoding.ItemIndex := i;
end;

function TFreePreferencesDialog.Execute(Freeship: TFreeShip): boolean;
begin
  FFreeship:=Freeship;
  Updatedata;
  FConfigChanged:=False;
  Showmodal;
  Result := ModalResult = mrOk;
end;

procedure TFreePreferencesDialog.ColorPanelClick(Sender: TObject);
var
  Panel: TPanel;
begin
  if (Sender.ClassType <> TPanel) then
    exit;
  Panel := TPanel(Sender);
  ColorDialog.Color := Panel.Color;
  if ColorDialog.Execute then
    if ColorDialog.Color <> Panel.Color then
    begin
      Panel.Color := ColorDialog.Color;
      FConfigChanged:=true;
    end;
end;

procedure TFreePreferencesDialog.ResetColorsButtonClick(Sender: TObject);
begin
  if MessageDlg( rs_Save, mtWarning, [mbYes, mbNo], 0) = mrYes
  then begin FFreeship.Preferences.ResetColors; Updatedata; end;
end;

procedure TFreePreferencesDialog.FormResize(Sender: TObject);
var sz:TRect;
begin sz:=getPreferredSize; end;

procedure TFreePreferencesDialog.FormShow(Sender: TObject);
var sz:TRect;
begin sz:=getPreferredSize; end;


procedure TFreePreferencesDialog.OkButtonClick(Sender: TObject);
begin ModalResult := mrOk; end;

procedure TFreePreferencesDialog.CancelButtonClick(Sender: TObject);
begin ModalResult := mrCancel; end;

procedure TFreePreferencesDialog.Panel1Paint(Sender: TObject);
begin
  {$IFDEF ZWindows}
  Panel53.Color := Tabsheet1.ActualColor;
  Panel51.Color := Tabsheet1.ActualColor;
  Panel.Color := Tabsheet1.ActualColor;
  {$ENDIF}
end;
(*
procedure TFreePreferencesDialog.ComboBoxThemesChange(Sender: TObject);
begin
  if Sender=ComboBoxThemes then begin
    FFreeship.Preferences.LoadTheme( ComboBoxThemes.Text );
    FThemeChanged := False;
    UpdateData;
  end;
  FConfigChanged := True;
end;
*)
procedure TFreePreferencesDialog.EditDirChange(Sender: TObject);
begin FConfigChanged := True; end;

procedure TFreePreferencesDialog.PageControl1Change(Sender: TObject);
begin FormActivate(Sender); end;

procedure TFreePreferencesDialog.FormActivate(Sender: TObject);
var sz:TRect; begin sz:=getPreferredSize; end;

function TFreePreferencesDialog.getPreferredSize:TRect;
var
  TxH, HdrHeight, BrdWidth, TbT, PgT, PnT, PGIB: integer;
  ScreenPoint: TPoint;
begin
  Invalidate;
  Application.ProcessMessages;
  ScreenPoint := ButtonPanel.ClientToScreen(Point(0, 0));
  HdrHeight := ScreenPoint.Y - self.Top;
  BrdWidth := ScreenPoint.X - self.Left;
  HdrHeight := HdrHeight - BrdWidth;
  {Tabsheet1.AdjustSize;
  Tabsheet1.Repaint;
  //Tabsheet1.Invalidate;

  TabSheet2.AdjustSize;
  PageControl1.AdjustSize;
  Panel1.AdjustSize;
  ButtonPanel.AdjustSize;
  self.AdjustSize;
  Application.ProcessMessages;}

  TbT := TabSheet2.ClientToParent(Point(0, 0), self).Y;
  PgT := PageControl1.ClientToParent(Point(0, 0), self).Y;
  PnT := Panel1.ClientToParent(Point(0, 0), self).Y;
//TbH := PgT - PnT - Panel1.BorderWidth - Panel1.BorderSpacing.InnerBorder;
  PGIB :={EditImportDir}Panel42.Height * 10 + TabSheet2.ChildSizing.VerticalSpacing * 9;
//PGIB := PanelGlobalImportDir.Height * 10 + TabSheet2.ChildSizing.VerticalSpacing * 9;
  TxH := PGIB + TabSheet2.ChildSizing.TopBottomSpacing * 2 + //TbH +
    Panel1.BorderWidth * 2 + Panel1.BorderSpacing.InnerBorder * 2 +
    ButtonPanel.Height + HdrHeight + BrdWidth * 2;
  {if self.Constraints.MinHeight < TxH then self.Constraints.MinHeight := TxH;}
  result := Rect(0,0, Width, BitBtnResetDirs.Top + BitBtnResetDirs.Height + 16);
end;

procedure TFreePreferencesDialog.SpinEdit1Change(Sender: TObject);
begin FConfigChanged := True; end;

procedure TFreePreferencesDialog.seSubmergedSurfaceOpacityChange(Sender: TObject);
begin FConfigChanged := True; end;

procedure TFreePreferencesDialog.ResetDirsButtonClick(Sender: TObject);
begin
  if MessageDlg( rs_Save, mtWarning, [mbYes, mbNo], 0) = mrYes
  then begin FFreeship.Preferences.ResetDirectories;
  end;
end;

procedure TFreePreferencesDialog.SpeedButtonLanguagesDirClick(Sender: TObject);
begin
  SelectDirectoryDialog1.FileName := EditLanguagesDir.Text;
  if SelectDirectoryDialog1.Execute then
    EditLanguagesDir.Text := SelectDirectoryDialog1.FileName;
end;

procedure TFreePreferencesDialog.SpeedButton9Click(Sender: TObject);
begin
  SelectDirectoryDialog1.FileName := EditManualsDir.Text;
  if SelectDirectoryDialog1.Execute then
    EditManualsDir.Text := SelectDirectoryDialog1.FileName;
end;
(*
procedure TFreePreferencesDialog.SpeedButton12Click(Sender: TObject);
begin
  SelectDirectoryDialog1.FileName := EditExecDir.Text;
  if SelectDirectoryDialog1.Execute then
    EditExecDir.Text := SelectDirectoryDialog1.FileName;
end;
procedure TFreePreferencesDialog.SpeedButton13Click(Sender: TObject);
begin
  SelectDirectoryDialog1.FileName := EditTempDir.Text;
  if SelectDirectoryDialog1.Execute then
    EditTempDir.Text := SelectDirectoryDialog1.FileName;
end;
*)
procedure TFreePreferencesDialog.SpeedButton14Click(Sender: TObject);
begin
  SelectDirectoryDialog1.FileName := EditOpenDir.Text;
  if SelectDirectoryDialog1.Execute then
    EditOpenDir.Text := SelectDirectoryDialog1.FileName;
end;

procedure TFreePreferencesDialog.SpeedButton15Click(Sender: TObject);
begin
  SelectDirectoryDialog1.FileName := EditSaveDir.Text;
  if SelectDirectoryDialog1.Execute then
    EditSaveDir.Text := SelectDirectoryDialog1.FileName;
end;

procedure TFreePreferencesDialog.SpeedButton16Click(Sender: TObject);
begin
  SelectDirectoryDialog1.FileName := EditImportDir.Text;
  if SelectDirectoryDialog1.Execute then
    EditImportDir.Text := SelectDirectoryDialog1.FileName;
end;

procedure TFreePreferencesDialog.SpeedButton17Click(Sender: TObject);
begin
  SelectDirectoryDialog1.FileName := EditExportDir.Text;
  if SelectDirectoryDialog1.Execute then
    EditExportDir.Text := SelectDirectoryDialog1.FileName;
end;
(*
procedure TFreePreferencesDialog.SpeedButton18Click(Sender: TObject);
begin
  SelectDirectoryDialog1.FileName := EditGlobalOpenDir.Text;
  if SelectDirectoryDialog1.Execute then
    EditGlobalOpenDir.Text := SelectDirectoryDialog1.FileName;
end;
procedure TFreePreferencesDialog.SpeedButton19Click(Sender: TObject);
begin
  SelectDirectoryDialog1.FileName := EditGlobalImportDir.Text;
  if SelectDirectoryDialog1.Execute then
    EditGlobalImportDir.Text := SelectDirectoryDialog1.FileName;
end;
*)
procedure TFreePreferencesDialog.ComboBoxEncodingFillItems;
begin
  with ComboBoxEncoding.Items do begin
(*  AddObject('ISO_8859_1 -  Central Europe', TObject(string('iso88591')));
    AddObject('ISO_8859_15 -  Western European languages', TObject(string('iso885915')));
    AddObject('ISO_8859_2 -  Eastern Europe', TObject(string('iso88592')));
    AddObject('CP1250 -  Central Europe', TObject(string('cp1250')));
*)  AddObject('CP1251 -  ANSI Cyrillic(Windows)', TObject(string('cp1251')));
    AddObject('CP1252 -  ANSI Latin; Western European(Windows)', TObject(string('cp1252')));
    AddObject( 'CP950 -  ANSI/OEM Traditional Chinese(Taiwan; Hong Kong SAR, PRC); Chinese Traditional(Big5)', TObject(string('cp950')));
(*  AddObject('CP1253 -  Greek', TObject(string('cp1253')));
    AddObject('CP1254 -  Turkish', TObject(string('cp1254')));
    AddObject('CP1255 -  Hebrew', TObject(string('cp1255')));
    AddObject('CP1256 -  Arabic', TObject(string('cp1256')));
    AddObject('CP1257 -  Baltic', TObject(string('cp1257')));
    AddObject('CP1258 -  Vietnam', TObject(string('cp1258')));
    AddObject( 'CP437 -  DOS Central Europe', TObject(string('cp437')));
    AddObject( 'CP850 -  DOS Western Europe', TObject(string('cp850')));
    AddObject( 'CP852 -  DOS Central Europe', TObject(string('cp852')));
    AddObject( 'CP866 -  DOS and Windows console Cyrillic', TObject(string('cp866')));
    AddObject( 'CP874 -  Thai', TObject(string('cp874')));
    AddObject( 'KOI8 -  Russian Cyrillic', TObject(string('koi8')));
*)end;
end;

end.
