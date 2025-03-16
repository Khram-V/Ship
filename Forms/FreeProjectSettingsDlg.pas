unit FreeProjectSettingsDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface
uses
  Graphics,
  Controls,  Forms,
  Dialogs,   ExtCtrls,
  StdCtrls,  Buttons,
  ComCtrls,  Spin,
  FreeTypes,FreeGeometry,FreeLanguageSupport;
type                                             { TFREEProjectSettingsDialog }
  TFREEProjectSettingsDialog = class( TForm )
    ColorDialog:                              TColorDialog;
    ComboBox1,Unitbox,PrecisionBox:           TComboBox;
    cbSavePreviewImage,cbShadeUnderwater,cbSimplifyIntersections,
    CheckBox11,CheckBox12,CheckBox2,CheckBox5,CheckBox6,CheckBox7,
    CheckBox8,CheckBox9,CheckBox3,CheckBox13: TCheckBox;           // MainFrame
    GroupBox1: TGroupBox;
    Label1:  TLabel;  Edit1:  TEdit;   // 'Project name'
    Label7:  TLabel;  Edit7:  TEdit;   // 'Designer'
    Label15: TLabel;  Edit9:  TEdit;   // 'Comment'
    Label16: TLabel;  Edit10: TEdit;   // 'File created by'
    Label27: TLabel;  Panel14: TPanel; // 'Underwater color'
    Edit17: TEdit;
    lbWaterDensity,Label2,Label10,Label11,Label12,Label13,Label14,Label17,
    Label18,Label19,Label20,Label21,Label22,Label23,Label24,Label25,
    Label26,Label3, Label4,Label6,Label9,Label8,Label5:   TLabel;
    Panel,Panel1,Panel2,Panel3,Panel4,Panel5,Panel6,
    Panel7,Panel8,Panel9,Panel10,Panel11,Panel12,Panel13: TPanel;
    Edit2,Edit3,Edit4,Edit5,Edit6,Edit8,
    Edit25,Edit26,Edit27:         TFloatSpinEdit;
    BitBtn1,BitBtn2:                TSpeedButton;
    PageControl1:                   TPageControl;
    seUnderwaterOpacity:               TSpinEdit;
    TabSheet1,TabSheet2,TabSheet3:     TTabSheet;
    procedure Edit2EditingDone(Sender: TObject);
    procedure Edit3EditingDone(Sender: TObject);
    procedure Edit4EditingDone(Sender: TObject);
    procedure Edit5EditingDone(Sender: TObject);
    procedure Edit25EditingDone(Sender: TObject);
    procedure Edit6EditingDone(Sender: TObject);
    procedure Panel4Click(Sender: TObject);
    procedure UnitboxChange(Sender: TObject);
    procedure SplitSectionLocationEditingDone(Sender: TObject); // MainFrame
    procedure Edit26EditingDone(Sender: TObject);
    procedure Edit27EditingDone(Sender: TObject);
    procedure CheckBox2Click(Sender: TObject);
    procedure CheckBox11Click(Sender: TObject);
    procedure CheckBox12Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private   { Private declarations }
    ConversionFactor: double;
    function FGetConversionFactor: double;
    function FGetBeam: double;         procedure FSetBeam(Val: double);
    function FGetCoefficient: double;  procedure FSetCoefficient(Val: double);
    function FGetDensity: double;      procedure FSetDensity(Val: double);
    function FGetTemper: double;       procedure FSetTemper(Val: double);
    function FGetDraft: double;        procedure FSetDraft(Val: double);
    function FGetLength: double;       procedure FSetLength(Val: double);
    function FGetMainframe:double;     procedure FSetMainframe(Val:double);
    function FGetYWindAreaMax: double; procedure FSetYWindAreaMax(Val: double);
    function FGetXWindAreaMax: double; procedure FSetXWindAreaMax(Val: double);
    procedure FSetUnitCaptions;
  public    { Public declarations }
    function Execute: boolean;
    property Beam: double        read FGetBeam write FSetBeam;
    property Coefficient: double read FGetCoefficient write FSetCoefficient;
    property Density: double     read FGetDensity write FSetDensity;
    property Temper: double      read FGetTemper write FSetTemper;
    property Draft: double       read FGetDraft write FSetDraft;
    property Length: double      read FGetLength write FSetLength;
    property Mainframe: double   read FGetMainframe write FSetMainframe;
    property YWindAreaMax:double read FGetYWindAreaMax write FSetYWindAreaMax;
    property XWindAreaMax:double read FGetXWindAreaMax write FSetXWindAreaMax;
  end;

var
  FREEProjectSettingsDialog: TFREEProjectSettingsDialog;

implementation

{$R *.lfm}

function TFREEProjectSettingsDialog.FGetConversionFactor: double;
begin
  if Unitbox.ItemIndex = 1 then Result:=1 / 0.3048
                           else Result:=1.0;
end;

function TFREEProjectSettingsDialog.FGetBeam: double;
   begin Result:=Edit3.Value; end;
function TFREEProjectSettingsDialog.FGetCoefficient: double;
   begin Result:=Edit6.Value; end;
function TFREEProjectSettingsDialog.FGetDensity: double;
   begin Result:=Edit5.Value; end;
function TFREEProjectSettingsDialog.FGetTemper: double;
   begin Result:=Edit25.Value; end;
function TFREEProjectSettingsDialog.FGetDraft: double;
   begin Result:=Edit4.Value; end;
function TFREEProjectSettingsDialog.FGetLength: double;
   begin Result:=Edit2.Value; end;

procedure TFREEProjectSettingsDialog.FSetBeam(Val: double);
    begin Edit3.Value:=Val; end;
procedure TFREEProjectSettingsDialog.FSetCoefficient(Val: double);
    begin Edit6.Value:=Val; end;
procedure TFREEProjectSettingsDialog.FSetDensity(Val: double);
    begin Edit5.Value:=Val; end;
procedure TFREEProjectSettingsDialog.FSetTemper(Val: double);
    begin Edit25.Value:=Val; end;
procedure TFREEProjectSettingsDialog.FSetDraft(Val: double);
    begin Edit4.Value:=Val; end;

procedure TFREEProjectSettingsDialog.FSetLength(Val: double);
begin Edit2.Value:=Val;
  if Checkbox2.Checked then MainFrame:=0.5*Length;
  if Checkbox12.Checked then XWindAreaMax:=0.5*Length;
end;

function TFREEProjectSettingsDialog.FGetMainframe:double;
   begin Result:=Edit8.Value; end;

procedure TFREEProjectSettingsDialog.FSetMainframe(Val:double);
    begin Edit8.Value:=Val; end;

function TFREEProjectSettingsDialog.FGetYWindAreaMax: double;
   begin Result:=Edit26.Value; end;

procedure TFREEProjectSettingsDialog.FSetYWindAreaMax(Val: double);
begin Edit26.Value:=Val; end;

function TFREEProjectSettingsDialog.FGetXWindAreaMax: double;
   begin Result:=Edit27.Value; end;

procedure TFREEProjectSettingsDialog.FSetXWindAreaMax(Val: double);
    begin Edit27.Value:=Val; end;

procedure TFREEProjectSettingsDialog.FSetUnitCaptions;
var Str: string;
begin
  if UnitBox.ItemIndex = 1 then Str:=LengthStr( fuImperial )
                           else Str:=Lengthstr( fuMetric );
  Label9.Caption:=Str;
  Label10.Caption:=Str;
  Label11.Caption:=Str;
  Label14.Caption:=Str;
  Label21.Caption:=Str;
  Label23.Caption:=Str;
  if UnitBox.ItemIndex = 1 then Str:=DensityStr( fuImperial )
                           else Str:=DensityStr( fuMetric );
  lbWaterDensity.Caption:=Str;
end;

function TFREEProjectSettingsDialog.Execute: boolean;
begin
  Conversionfactor:=FGetConversionFactor;
  checkbox2.Checked:=True;
  checkbox11.Checked:=True;
  checkbox12.Checked:=True;
  YWindAreaMax:=0.0;
  XWindAreaMax:=0.5 * Length;
  FSetUnitCaptions;
  ShowTranslatedValues(Self); ShowModal;
  Result:=Modalresult = mrOk;
end;

procedure TFREEProjectSettingsDialog.Edit2EditingDone(Sender: TObject);
    begin Length:=Length; end; // force repaint
procedure TFREEProjectSettingsDialog.Edit3EditingDone(Sender: TObject);
    begin Beam:=Beam; end;
procedure TFREEProjectSettingsDialog.Edit4EditingDone(Sender: TObject);
    begin Draft:=Draft; end;
procedure TFREEProjectSettingsDialog.Edit5EditingDone(Sender: TObject);
    begin Density:=Density; end;
procedure TFREEProjectSettingsDialog.Edit25EditingDone(Sender: TObject);
    begin Temper:=Temper; end;
procedure TFREEProjectSettingsDialog.Edit6EditingDone(Sender: TObject);
    begin Coefficient:=Coefficient; end;
procedure TFREEProjectSettingsDialog.Panel4Click(Sender: TObject);
begin ColorDialog.Color:=panel4.Color;
   if ColorDialog.Execute then Panel4.Color:=ColorDialog.Color;
end;

procedure TFREEProjectSettingsDialog.UnitboxChange(Sender: TObject);
begin
   Length:=Length/ConversionFactor;
   Beam:=Beam/Conversionfactor;
   Draft:=Draft/Conversionfactor;
   Mainframe:=MainFrame/ConversionFactor;
   YWindAreaMax:=YWindAreaMax/ConversionFactor;
   XWindAreaMax:=XWindAreaMax/ConversionFactor;
   if (Unitbox.ItemIndex=0) and (Conversionfactor>1) then Density:=Density/WeightConversionFactor;
   if (Unitbox.ItemIndex=1) and (Conversionfactor=1) then Density:=Density*WeightConversionFactor;
   Conversionfactor:=FGetConversionFactor;
   Length:=Length*ConversionFactor;
   Beam:=Beam*Conversionfactor;
   Draft:=Draft*Conversionfactor;
   if not checkbox2.Checked then Mainframe:=MainFrame*ConversionFactor;
   if not checkbox11.Checked then YWindAreaMax:=YWindAreaMax*ConversionFactor;
   if not checkbox12.Checked then XWindAreaMax:=XWindAreaMax*ConversionFactor;
   FSetUnitCaptions;
end;

procedure TFREEProjectSettingsDialog.SplitSectionLocationEditingDone(Sender: TObject);
    begin MainFrame:=MainFrame; end;
procedure TFREEProjectSettingsDialog.Edit26EditingDone(Sender: TObject);
    begin YWindAreaMax:=YWindAreaMax; end;
procedure TFREEProjectSettingsDialog.Edit27EditingDone(Sender: TObject);
    begin XWindAreaMax:=XWindAreaMax; end;

procedure TFREEProjectSettingsDialog.CheckBox2Click(Sender: TObject);
begin
  if Checkbox2.Checked then begin
    //      Label13.Enabled:=False;
    //      Label14.Enabled:=False;
    Edit8.Color:=clBtnFace;
    Edit8.Font.Color:=clDkGray;
    Edit8.Enabled:=False;
  end else begin
    //      Label13.Enabled:=True;
    //      Label14.Enabled:=True;
    Edit8.Color:=clWindow;
    Edit8.Font.Color:=clBlack;
    Edit8.Enabled:=True;
  end;
end;

procedure TFREEProjectSettingsDialog.CheckBox11Click(Sender: TObject);
begin
  if Checkbox11.Checked then begin
    //      Label20.Enabled:=False;
    //      Label21.Enabled:=False;
    Edit26.Color:=clBtnFace;
    Edit26.Font.Color:=clDkGray;
    Edit26.Enabled:=False;
  end else begin
    //      Label20.Enabled:=True;
    //      Label21.Enabled:=True;
    Edit26.Color:=clWindow;
    Edit26.Font.Color:=clBlack;
    Edit26.Enabled:=True;
  end;
end;

procedure TFREEProjectSettingsDialog.CheckBox12Click(Sender: TObject);
begin
  if Checkbox12.Checked then begin
    //      Label22.Enabled:=False;
    //      Label23.Enabled:=False;
    Edit27.Color:=clBtnFace;
    Edit27.Font.Color:=clDkGray;
    Edit27.Enabled:=False;
  end else begin
    //      Label22.Enabled:=True;
    //      Label23.Enabled:=True;
    Edit27.Color:=clWindow;
    Edit27.Font.Color:=clBlack;
    Edit27.Enabled:=True;
  end;
end;

procedure TFREEProjectSettingsDialog.BitBtn1Click(Sender: TObject);
    begin Modalresult:=mrOk; end;
procedure TFREEProjectSettingsDialog.BitBtn2Click(Sender: TObject);
    begin Modalresult:=mrCancel; end;
procedure TFREEProjectSettingsDialog.FormShow(Sender: TObject);
    begin Pagecontrol1.ActivePage:=Tabsheet1; ActiveControl:=Edit1; end;

end.
