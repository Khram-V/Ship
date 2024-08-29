
unit FreeHydrostaticsFrm;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, LCLType, //LMessages,
{$ENDIF}
  //Messages,
  SysUtils,
  Variants,
  Classes,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  FreeShipUnit,
  FreeTypes,
  FreeGeometry,
  ExtCtrls,
  FreeHydrostaticsResultsDlg,
  Buttons, Spin;

type

  { TFreeHydrostaticsForm }

  TFreeHydrostaticsForm = class(TForm)
    FloatSpinEdit1: TFloatSpinEdit;
    FloatSpinEdit2: TFloatSpinEdit;
    FloatSpinEdit3: TFloatSpinEdit;
    FloatSpinEdit4: TFloatSpinEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label9: TLabel;
    Panel2: TPanel;
    Button1: TSpeedButton;
    Panel1: TPanel;
    Button2: TSpeedButton;
    _Label10: TLabel;
    _Label11: TLabel;
    _Label5: TLabel;
    procedure Edit1KeyPress(Sender: TObject; var Key: char);
    procedure Button1Click(Sender: TObject);
    procedure Edit1Exit(Sender: TObject);
    procedure Edit3Exit(Sender: TObject);
    procedure Edit4Exit(Sender: TObject);
    procedure Edit2Exit(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private   { Private declarations }
    FFreeShip: TFreeShip;
    function FGetStartDraft: single;
    procedure FSetStartDraft(Val: single);
    function FGetEndDraft: single;
    procedure FSetEndDraft(Val: single);
    function FGetDraftStep: single;
    procedure FSetDraftStep(Val: single);
    function FGetTrim: single;
    procedure FSetTrim(Val: single);
  public    { Public declarations }
    function Execute(FreeShip: TFreeShip): boolean;
    property DraftStep: single read FGetDraftStep write FSetDraftStep;
    property EndDraft: single read FGetEndDraft write FSetEndDraft;
    property StartDraft: single read FGetStartDraft write FSetStartDraft;
    property Trim: single read FGetTrim write FSetTrim;
  end;

var
  FreeHydrostaticsForm: TFreeHydrostaticsForm;

implementation

{$IFnDEF FPC}
  {$R *.dfm}

{$ELSE}
  {$R *.lfm}
{$ENDIF}


function TFreeHydrostaticsForm.FGetStartDraft: single;
begin
  Result:=FloatSpinEdit1.Value;
end;{TFreeHydrostaticsForm.FGetStartDraft}

procedure TFreeHydrostaticsForm.FSetStartDraft(Val: single);
begin
  FloatSpinEdit1.Value:=Val;
end;{TFreeHydrostaticsForm.FSetStartDraft}

function TFreeHydrostaticsForm.FGetTrim: single;
begin
  Result:=FloatSpinEdit4.Value;
end;{TFreeHydrostaticsForm.FGetTrim}

procedure TFreeHydrostaticsForm.FSetTrim(Val: single);
begin
  FloatSpinEdit4.Value:=Val;
end;{TFreeHydrostaticsForm.FSetTrim}

function TFreeHydrostaticsForm.FGetEndDraft: single;
begin
  Result:=FloatSpinEdit2.Value;
end;{TFreeHydrostaticsForm.FGetEndDraft}

procedure TFreeHydrostaticsForm.FSetEndDraft(Val: single);
begin
  FloatSpinEdit2.Value:=Val;
end;{TFreeHydrostaticsForm.FSetEndDraft}

function TFreeHydrostaticsForm.FGetDraftStep: single;
begin
  Result:=FloatSpinEdit3.Value;
end;{TFreeHydrostaticsForm.FGetDraftStep}

procedure TFreeHydrostaticsForm.FSetDraftStep(Val: single);
begin
  FloatSpinEdit3.Value:=Val;
end;{TFreeHydrostaticsForm.FSetDraftStep}

function TFreeHydrostaticsForm.Execute(FreeShip: TFreeShip): boolean;
var
  Str: string;
begin
  FFreeShip:=Freeship;
  Str:=LengthStr(FreeShip.ProjectSettings.ProjectUnits);
  _Label5.Caption:=Str;
  Label9.Caption:=Str;
  _Label10.Caption:=Str;
  _Label11.Caption:=Str;
  ShowModal;
  Result:=Modalresult = mrOk;
end;

procedure TFreeHydrostaticsForm.Edit1KeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in [#8, '0'..'9', '.', '-', #13]) then key:=#0;
end;

procedure TFreeHydrostaticsForm.Button1Click(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TFreeHydrostaticsForm.Edit1Exit(Sender: TObject);
    begin StartDraft:=StartDraft; end;
procedure TFreeHydrostaticsForm.Edit3Exit(Sender: TObject);
    begin DraftStep:=DraftStep; end;
procedure TFreeHydrostaticsForm.Edit4Exit(Sender: TObject);
    begin Trim:=Trim; end;
procedure TFreeHydrostaticsForm.Edit2Exit(Sender: TObject);
    begin EndDraft:=Enddraft; end;

procedure TFreeHydrostaticsForm.Button2Click(Sender: TObject);
var
  Value: single;
  HydObject: TFreeHydrostaticCalc;
  I: integer;
  PrevCursor: TCursor;
  ResultsDlg: TFreeHydrostaticsResultsDialog;
  Units: TFreeUnitType;
  Strings: TStringList;
  Cb, Cm, Cp, Zmin: single;
begin
  if (StartDraft < EndDraft) and (DraftStep > 0.0001) then
  begin
    Value:=StartDraft;
    PrevCursor:=Screen.Cursor;
    Screen.Cursor:=crHourglass;
    Strings:=TStringList.Create;
    ResultsDlg:=TFreeHydrostaticsResultsDialog.Create(self);                  //  ShowTranslatedValues(ResultsDlg);
//  try  // Quietly test for inconsistencies
      if not FFreeShip.ProjectSettings.DisableModelCheck then
        FFreeShip.Edit.Model_Check(False);
      HydObject:=TFreeHydrostaticCalc.Create(FFreeShip);
      ResultsDlg.Grid.RowCount:=Round((EndDraft - StartDraft) / DraftStep) + 3;
      Units:=FFreeship.ProjectSettings.ProjectUnits;

      ResultsDlg.Grid.Colcount:=18;
      ResultsDlg.Grid.Cells[0, 0]:='Draft';
      ResultsDlg.Grid.Cells[0, 1]:=LengthStr(Units);
      ResultsDlg.Grid.Cells[1, 0]:='Trim';
      ResultsDlg.Grid.Cells[1, 1]:=LengthStr(Units);
      ResultsDlg.Grid.Cells[2, 0]:='Lwl';
      ResultsDlg.Grid.Cells[2, 1]:=LengthStr(Units);
      ResultsDlg.Grid.Cells[3, 0]:='Bwl';
      ResultsDlg.Grid.Cells[3, 1]:=LengthStr(Units);
      ResultsDlg.Grid.Cells[4, 0]:='Volume';
      ResultsDlg.Grid.Cells[4, 1]:=VolStr(Units);
      ResultsDlg.Grid.Cells[5, 0]:='Displ.';
      ResultsDlg.Grid.Cells[5, 1]:=WeightStr(Units);
      ResultsDlg.Grid.Cells[6, 0]:='LCB';
      ResultsDlg.Grid.Cells[6, 1]:=LengthStr(Units);
      ResultsDlg.Grid.Cells[7, 0]:='VCB';
      ResultsDlg.Grid.Cells[7, 1]:=LengthStr(Units);
      ResultsDlg.Grid.Cells[8, 0]:='Cb';
      ResultsDlg.Grid.Cells[8, 1]:='[-]';
      ResultsDlg.Grid.Cells[9, 0]:='Am';
      ResultsDlg.Grid.Cells[9, 1]:=AreaStr(Units);
      ResultsDlg.Grid.Cells[10, 0]:='Cm';
      ResultsDlg.Grid.Cells[10, 1]:='[-]';
      ResultsDlg.Grid.Cells[11, 0]:='Aw';
      ResultsDlg.Grid.Cells[11, 1]:=AreaStr(Units);
      ResultsDlg.Grid.Cells[12, 0]:='Cw';
      ResultsDlg.Grid.Cells[12, 1]:='[-]';
      ResultsDlg.Grid.Cells[13, 0]:='LCF';
      ResultsDlg.Grid.Cells[13, 1]:=LengthStr(Units);
      ResultsDlg.Grid.Cells[14, 0]:='Cp';
      ResultsDlg.Grid.Cells[14, 1]:='[-]';
      ResultsDlg.Grid.Cells[15, 0]:='S';
      ResultsDlg.Grid.Cells[15, 1]:=AreaStr(Units);
      ResultsDlg.Grid.Cells[16, 0]:='KMt';
      ResultsDlg.Grid.Cells[16, 1]:=LengthStr(Units);
      ResultsDlg.Grid.Cells[17, 0]:='KMl';
      ResultsDlg.Grid.Cells[17, 1]:=LengthStr(Units);

      for I:=0 to 16 do if I in [0, 1, 2, 3, 6, 7, 8, 10, 12, 14]
      then ResultsDlg.Grid.ColWidths[I]:=47
      else if I in [4, 5, 15] then ResultsDlg.Grid.ColWidths[I]:=55;
      Zmin:=0;
      I:=2;
      while (Value <= EndDraft + DraftStep) or (abs(Value - EndDraft) < 1e-3) do begin
        HydObject.Clear;
        HydObject.HeelingAngle:=0.0;
        HydObject.Trim:=Trim;
        if Value <= EndDraft then HydObject.Draft:=Value - Zmin
                             else HydObject.Draft:=EndDraft - Zmin;
        HydObject.Calculate;
        // Пересчет коэфФициентов полноты, если базовая линия проходит через линию киля
        if abs(HydObject.Data.ModelMin.Z) > 0.001 then
        begin
          Zmin:=HydObject.Data.ModelMin.Z;
          Cb:=HydObject.Data.BlockCoefficient * HydObject.Draft / (HydObject.Draft + HydObject.Data.ModelMin.Z);
          Cm:=HydObject.Data.MidshipCoeff * HydObject.Draft / (HydObject.Draft + HydObject.Data.ModelMin.Z);
        end else begin
          Cb:=HydObject.Data.BlockCoefficient;
          Cm:=HydObject.Data.MidshipCoeff;
        end;
        if Cm > 0 then begin
          Cp:=Cb / Cm;
          ResultsDlg.Grid.RowCount:=I + 1;
          ResultsDlg.Grid.Cells[0, I]:=FloatToStrF(HydObject.Draft + Zmin, ffFixed, 7, 3);
          ResultsDlg.Grid.Cells[1, I]:=FloatToStrF(HydObject.Trim, ffFixed, 7, 3);
          ResultsDlg.Grid.Cells[2, I]:=FloatToStrF(HydObject.Data.LengthWaterline, ffFixed, 7, 3);
          ResultsDlg.Grid.Cells[3, I]:=FloatToStrF(HydObject.Data.BeamWaterline, ffFixed, 7, 3);
          ResultsDlg.Grid.Cells[4, I]:=FloatToStrF(HydObject.Data.Volume, ffFixed, 8, NumberOfDecimals(HydObject.Data.Volume));
          ResultsDlg.Grid.Cells[5, I]:=FloatToStrF(HydObject.Data.Displacement, ffFixed, 8, NumberOfDecimals( HydObject.Data.Displacement));
          ResultsDlg.Grid.Cells[6, I]:=FloatToStrF(HydObject.Data.CenterOfBuoyancy.X, ffFixed, 7, 3);
          ResultsDlg.Grid.Cells[7, I]:=FloatToStrF(HydObject.Data.CenterOfBuoyancy.Z + Zmin, ffFixed, 7, 3);
          ResultsDlg.Grid.Cells[8, I]:=FloatToStrF(Cb, ffFixed, 7, 4);
          ResultsDlg.Grid.Cells[9, I]:=FloatToStrF(HydObject.Data.MidshipArea, ffFixed, 7, 3);
          ResultsDlg.Grid.Cells[10, I]:=FloatToStrF(Cm, ffFixed, 7, 4);
          ResultsDlg.Grid.Cells[11, I]:=FloatToStrF(HydObject.Data.Waterplanearea, ffFixed, 7, NumberOfDecimals( HydObject.Data.Waterplanearea));
          ResultsDlg.Grid.Cells[12, I]:=FloatToStrF(HydObject.Data.WaterplaneCoeff, ffFixed, 7, 4);
          ResultsDlg.Grid.Cells[13, I]:=FloatToStrF(HydObject.Data.WaterplaneCOG.X, ffFixed, 7, 3);
          ResultsDlg.Grid.Cells[14, I]:=FloatToStrF(Cp, ffFixed, 7, 4);
          ResultsDlg.Grid.Cells[15, I]:=FloatToStrF(HydObject.Data.WettedSurface, ffFixed, 7, NumberOfDecimals( HydObject.Data.WettedSurface));
          ResultsDlg.Grid.Cells[16, I]:=FloatToStrF(HydObject.Data.KMtransverse + Zmin, ffFixed, 7, 3);
          ResultsDlg.Grid.Cells[17, I]:=FloatToStrF(HydObject.Data.KMlongitudinal + Zmin, ffFixed, 7, NumberOfDecimals( HydObject.Data.KMlongitudinal));
          Inc(I);
        end;
        Value:=Value + DraftStep;
        if (feMakingWater in HydObject.Errors) then break; // stop if the vessel is making water
      end;
      HydObject.AddHeader(Strings);
      Strings.add('');
      Strings.add('');
      HydObject.AddFooter(Strings, fhMultipleCalculations);
      ResultsDlg.Header.Lines.AddStrings(Strings);
      HydObject.Destroy;                       //ResultsDlg.Grid.RowCount:=I;
//  finally
      Strings.Destroy;
      Screen.Cursor:=PrevCursor;
      ResultsDlg.Execute;
      ResultsDlg.Destroy;
//  end;
  end;
end;

end.
