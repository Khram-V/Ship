unit FreeSplitSectionDlg;
interface uses
  Classes,SysUtils,Forms,Controls,Dialogs,ComCtrls,ExtCtrls,Buttons,Spin,Types,
  FreeTypes,FreeShipUnit;
type
  TEditMode=(emProgrammatic,emMouse,emKeyboard);
  TFreeSplitSectionDialogChangeEvent=procedure ( Sender: TObject; aValue: Real ) of object;
  TFreeSplitSectionDialog=class( TForm )
    BitBtn1: TBitBtn;
    fseMiF: TFloatSpinEdit;
    Panel1,TopPanel: TPanel;
    SpeedButton1,SpeedButton3: TSpeedButton;
    tbMiF: TTrackBar;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure fseMiFChange(Sender: TObject);
    procedure fseMiFEditingDone(Sender: TObject);
    procedure fseMiFKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure fseMiFMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure fseMiFMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure tbMiFChange(Sender: TObject);
  private
    FEditMode: TEditMode;
    FMiF: Real;
    FOnMiFChange: TFreeSplitSectionDialogChangeEvent;
    procedure SetMiF(AValue: Real);
  public
    procedure SetDimensions;
    property MiF:Real read FMiF write SetMiF;
    property OnMiFChange: TFreeSplitSectionDialogChangeEvent
             read FOnMiFChange
             write FOnMiFChange;
  end;

var FreeSplitSectionDialog: TFreeSplitSectionDialog;

implementation                                      { TFreeSplitSectionDialog }
{$R *.lfm}

procedure TFreeSplitSectionDialog.fseMiFMouseDown
    ( Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin FEditMode:=emMouse; end;

procedure TFreeSplitSectionDialog.fseMiFMouseWheel
( Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean );
begin FEditMode:=emMouse; end;

procedure TFreeSplitSectionDialog.SpeedButton1Click(Sender: TObject);
    begin with Ship.Surface do SetMiF( (Min.X+Max.X)*0.5 ); end;    // 'Medium'

procedure TFreeSplitSectionDialog.SpeedButton3Click(Sender: TObject);
    begin                                                // 'From hydrostatics'
          SetMiF( Ship.FDesignHydrostatics.Data.CenterOfBuoyancy.X );
    end;
procedure TFreeSplitSectionDialog.tbMiFChange(Sender: TObject);
    begin SetMiF( 0.001*tbMiF.Position ); end;

procedure TFreeSplitSectionDialog.SetMiF( AValue: Real );
begin
  if FMiF=AValue then Exit;
  FMiF:=AValue;                  // FEditMode:=emProgrammatic;
  fseMiF.Value:=AValue;
  tbMiF.Position:=round( AValue*1e3 );
  if assigned(OnMiFChange) then OnMiFChange( Self,FMiF );
end;

// Lendth of ship,location of widest place,location of spaciest place

procedure TFreeSplitSectionDialog.SetDimensions;
begin
 tbMiF.Min:=round(Ship.Surface.Min.X*1e3); fseMiF.MinValue:=Ship.Surface.Min.X;
 tbMiF.Max:=round(Ship.Surface.Max.X*1e3); fseMiF.MaxValue:=Ship.Surface.Max.X;
end;

procedure TFreeSplitSectionDialog.fseMiFKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState );
    begin FEditMode:=emKeyboard; end;

procedure TFreeSplitSectionDialog.fseMiFEditingDone(Sender: TObject);
begin //if abs(fseMiF.Value-FMiF) < 1e-5 then exit;
        FEditMode:=emKeyboard;
        SetMiF( fseMiF.Value );
end;

procedure TFreeSplitSectionDialog.fseMiFChange(Sender: TObject);
begin // if FEditMode in [emMouse] then
         SetMiF( fseMiF.Value );
end;

procedure TFreeSplitSectionDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrClose; Close; end;

procedure TFreeSplitSectionDialog.FormShow(Sender: TObject); begin end;

end.

