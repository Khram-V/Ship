unit FreeProjectSettingsDlg;
{$MODE Delphi}{$H+}
interface uses
  Graphics,
  Controls, Forms,
  Dialogs,  ExtCtrls,
  StdCtrls, Buttons,
  ComCtrls, Spin,
  FreeTypes,FreeGeometry,FreeShipUnit,FreeLanguageSupport;
type
  TFREEProjectSettingsDialog=class( TForm )
    ColorDialog:                              TColorDialog;
    ComboBox1,Unitbox,PrecisionBox:           TComboBox;
    cbSavePreviewImage,cbShadeUnderwater,cbSimplifyIntersections,
    CheckBox11,CheckBox12,CheckBox2,CheckBox5,CheckBox6,CheckBox7,
    CheckBox8,CheckBox9,CheckBox3,CheckBox13: TCheckBox;
    GroupBox1: TGroupBox;
    Label1:  TLabel;  Edit1:  TEdit;   // 'Project name'
    Label7:  TLabel;  Edit7:  TEdit;   // 'Designer'
    Label15: TLabel;  Edit9:  TEdit;   // 'Comment'
    Label16: TLabel;  Edit10: TEdit;   // 'File created by'
    Label27: TLabel;  Panel14: TPanel; // 'Underwater color'
    Edit17: TEdit;
    Label9{Длина},Label10{Ширина},Label11{Осадка},
    lbWaterDensity,Label2,Label12,Label13,Label14,Label17,
    Label18,Label19,Label20,Label21,Label22,Label23,Label24,Label25,
    Label26,Label3,Label4,Label6,Label8,Label5:          TLabel;
    Panel,Panel1,Panel2,Panel3,Panel4,Panel5,Panel6,
    Panel7,Panel8,Panel9,Panel10,Panel11,Panel12,Panel13: TPanel;
    Edit2,Edit3,Edit4,Edit5,Edit6,Edit8,Edit25,Edit26,Edit27: TFloatSpinEdit;
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
  private
    ConversionFactor: Real;
    function FGetConversionFactor: Real;
    function FGetBeam: Real;         procedure FSetBeam(Val: Real);
    function FGetCoefficient: Real;  procedure FSetCoefficient(Val: Real);
    function FGetDensity: Real;      procedure FSetDensity(Val: Real);
    function FGetTemper: Real;       procedure FSetTemper(Val: Real);
    function FGetDraft: Real;        procedure FSetDraft(Val: Real);
    function FGetLength: Real;       procedure FSetLength(Val: Real);
    function FGetMainframe:Real;     procedure FSetMainframe(Val:Real);
    function FGetYWindAreaMax: Real; procedure FSetYWindAreaMax(Val: Real);
    function FGetXWindAreaMax: Real; procedure FSetXWindAreaMax(Val: Real);
    procedure FSetUnitCaptions;
  public
    function Execute: boolean;
    property Beam: Real        read FGetBeam write FSetBeam;
    property Coefficient: Real read FGetCoefficient write FSetCoefficient;
    property Density: Real     read FGetDensity write FSetDensity;
    property Temper: Real      read FGetTemper write FSetTemper;
    property Draft: Real       read FGetDraft write FSetDraft;
    property Length: Real      read FGetLength write FSetLength;
    property MidleFrame: Real  read FGetMainframe write FSetMainframe;
    property YWindAreaMax:Real read FGetYWindAreaMax write FSetYWindAreaMax;
    property XWindAreaMax:Real read FGetXWindAreaMax write FSetXWindAreaMax;
  end;

var
  FREEProjectSettingsDialog: TFREEProjectSettingsDialog;

implementation

{$R *.lfm}

function TFREEProjectSettingsDialog.FGetConversionFactor: Real;
begin
  if Unitbox.ItemIndex=1 then Result:=1/0.3048
                           else Result:=1.0;
end;

function TFREEProjectSettingsDialog.FGetBeam: Real;
   begin Result:=Edit3.Value; end;
function TFREEProjectSettingsDialog.FGetCoefficient: Real;
   begin Result:=Edit6.Value; end;
function TFREEProjectSettingsDialog.FGetDensity: Real;
   begin Result:=Edit5.Value; end;
function TFREEProjectSettingsDialog.FGetTemper: Real;
   begin Result:=Edit25.Value; end;
function TFREEProjectSettingsDialog.FGetDraft: Real;
   begin Result:=Edit4.Value; end;
function TFREEProjectSettingsDialog.FGetLength: Real;
   begin Result:=Edit2.Value; end;
procedure TFREEProjectSettingsDialog.FSetBeam(Val: Real);
    begin Edit3.Value:=Val; end;
procedure TFREEProjectSettingsDialog.FSetCoefficient(Val: Real);
    begin Edit6.Value:=Val; end;
procedure TFREEProjectSettingsDialog.FSetDensity(Val: Real);
    begin Edit5.Value:=Val; end;
procedure TFREEProjectSettingsDialog.FSetTemper(Val: Real);
    begin Edit25.Value:=Val; end;
procedure TFREEProjectSettingsDialog.FSetDraft(Val: Real);
    begin Edit4.Value:=Val; end;

procedure TFREEProjectSettingsDialog.FSetLength(Val: Real);
begin Edit2.Value:=Val;
  if Checkbox2.Checked then MidleFrame:=0.5*Length;
  if Checkbox12.Checked then XWindAreaMax:=0.5*Length;
end;

function TFREEProjectSettingsDialog.FGetMainframe:Real;
   begin Result:=Edit8.Value; end;

procedure TFREEProjectSettingsDialog.FSetMainframe(Val:Real);
    begin Edit8.Value:=Val; end;

function TFREEProjectSettingsDialog.FGetYWindAreaMax: Real;
   begin Result:=Edit26.Value; end;

procedure TFREEProjectSettingsDialog.FSetYWindAreaMax(Val: Real);
begin Edit26.Value:=Val; end;

function TFREEProjectSettingsDialog.FGetXWindAreaMax: Real;
   begin Result:=Edit27.Value; end;

procedure TFREEProjectSettingsDialog.FSetXWindAreaMax(Val: Real);
    begin Edit27.Value:=Val; end;

procedure TFREEProjectSettingsDialog.FSetUnitCaptions;
var Str: String; Min,Max: Vector;
begin
  if UnitBox.ItemIndex=1 then Str:=LengthStr( fuImperial )
                           else Str:=Lengthstr( fuMetric );
  Ship.Extents( Min,Max );
  Label9.Caption :=Str+'   ↔  { '+FloattoDec(ConversionFactor*(Max.X-Min.X),2)+' }';
  Label10.Caption:=Str+'   ↔  { '+FloattoDec(ConversionFactor*(Max.Y-Min.Y),2)+' }';
  Label11.Caption:=Str+'   ↔  { '+FloattoDec(ConversionFactor*(Max.Z-Min.Z),2)+' }';
  Label14.Caption:=Str;
  Label21.Caption:=Str;
  Label23.Caption:=Str;
  if UnitBox.ItemIndex=1 then Str:=DensityStr( fuImperial )
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
  XWindAreaMax:=0.5*Length;
  FSetUnitCaptions;
  ShowTranslatedValues(Self); ShowModal;
  Result:=Modalresult=mrOk;
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
   MidleFrame:=MidleFrame/ConversionFactor;
   YWindAreaMax:=YWindAreaMax/ConversionFactor;
   XWindAreaMax:=XWindAreaMax/ConversionFactor;
   if (Unitbox.ItemIndex=0) and (Conversionfactor>1) then Density:=Density/WeightConversionFactor;
   if (Unitbox.ItemIndex=1) and (Conversionfactor=1) then Density:=Density*WeightConversionFactor;
   Conversionfactor:=FGetConversionFactor;
   Length:=Length*ConversionFactor;
   Beam:=Beam*Conversionfactor;
   Draft:=Draft*Conversionfactor;
   if not checkbox2.Checked then MidleFrame:=MidleFrame*ConversionFactor;
   if not checkbox11.Checked then YWindAreaMax:=YWindAreaMax*ConversionFactor;
   if not checkbox12.Checked then XWindAreaMax:=XWindAreaMax*ConversionFactor;
   FSetUnitCaptions;
end;
procedure TFREEProjectSettingsDialog.SplitSectionLocationEditingDone(Sender: TObject);
    begin MidleFrame:=MidleFrame; end;
procedure TFREEProjectSettingsDialog.Edit26EditingDone(Sender: TObject);
    begin YWindAreaMax:=YWindAreaMax; end;
procedure TFREEProjectSettingsDialog.Edit27EditingDone(Sender: TObject);
    begin XWindAreaMax:=XWindAreaMax; end;

procedure TFREEProjectSettingsDialog.CheckBox2Click(Sender: TObject);
begin
  if Checkbox2.Checked then begin
    Edit8.Color:=clBtnFace;            //      Label13.Enabled:=False;
    Edit8.Font.Color:=clDkGray;        //      Label14.Enabled:=False;
    Edit8.Enabled:=False;
  end else begin
    Edit8.Color:=clWindow;             //      Label13.Enabled:=True;
    Edit8.Font.Color:=clBlack;         //      Label14.Enabled:=True;
    Edit8.Enabled:=True;
  end;
end;

procedure TFREEProjectSettingsDialog.CheckBox11Click(Sender: TObject);
begin
  if Checkbox11.Checked then begin
    Edit26.Color:=clBtnFace;           //      Label20.Enabled:=False;
    Edit26.Font.Color:=clDkGray;       //      Label21.Enabled:=False;
    Edit26.Enabled:=False;
  end else begin
    Edit26.Color:=clWindow;            //      Label20.Enabled:=True;
    Edit26.Font.Color:=clBlack;        //      Label21.Enabled:=True;
    Edit26.Enabled:=True;
  end;
end;

procedure TFREEProjectSettingsDialog.CheckBox12Click(Sender: TObject);
begin
  if Checkbox12.Checked then begin
    Edit27.Color:=clBtnFace;           //      Label22.Enabled:=False;
    Edit27.Font.Color:=clDkGray;       //      Label23.Enabled:=False;
    Edit27.Enabled:=False;
  end else begin
    Edit27.Color:=clWindow;            //      Label22.Enabled:=True;
    Edit27.Font.Color:=clBlack;        //      Label23.Enabled:=True;
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
