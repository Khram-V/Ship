unit SplitSectionDlg;
interface uses
  Classes,SysUtils,Forms,Controls,Dialogs,ComCtrls,ExtCtrls,Buttons,Spin,//Types,
  STypes,ShipUnit;
type
  TEditMode=(emProgrammatic,emMouse,emKeyboard);
  TSplitSectionDialogChangeEvent=procedure ( Sender: TObject; aValue: Real ) of object;
  TSplitSectionDialog=class( TForm )
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
    FOnMiFChange: TSplitSectionDialogChangeEvent;
    procedure SetMiF(AValue: Real);
  public
    procedure SetDimensions;
    property MiF:Real read FMiF write SetMiF;
    property OnMiFChange: TSplitSectionDialogChangeEvent
             read FOnMiFChange
             write FOnMiFChange;
  end;

var SplitSectionDialog: TSplitSectionDialog;

implementation                                      { TSplitSectionDialog }
{$R *.lfm}

procedure TSplitSectionDialog.fseMiFMouseDown
    ( Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin FEditMode:=emMouse; end;

procedure TSplitSectionDialog.fseMiFMouseWheel
( Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean );
begin FEditMode:=emMouse; end;

procedure TSplitSectionDialog.SpeedButton1Click(Sender: TObject);
    begin with St.Surface do SetMiF( (Min.X+Max.X)*0.5 ); end;    // 'Medium'

procedure TSplitSectionDialog.SpeedButton3Click(Sender: TObject);
    begin                                                // 'From hydrostatics'
          SetMiF( St.FDesignHydrostatics.Data.CenterOfBuoyancy.X );
    end;
procedure TSplitSectionDialog.tbMiFChange(Sender: TObject);
    begin SetMiF( 0.001*tbMiF.Position ); end;

procedure TSplitSectionDialog.SetMiF( AValue: Real );
begin
  if FMiF=AValue then Exit;
  FMiF:=AValue;                  // FEditMode:=emProgrammatic;
  fseMiF.Value:=AValue;
  tbMiF.Position:=round( AValue*1e3 );
  if assigned(OnMiFChange) then OnMiFChange( Self,FMiF );
end;

// Lendth of St,location of widest place,location of spaciest place

procedure TSplitSectionDialog.SetDimensions;
begin
 tbMiF.Min:=round(St.Surface.Min.X*1e3); fseMiF.MinValue:=St.Surface.Min.X;
 tbMiF.Max:=round(St.Surface.Max.X*1e3); fseMiF.MaxValue:=St.Surface.Max.X;
end;

procedure TSplitSectionDialog.fseMiFKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState );
    begin FEditMode:=emKeyboard; end;

procedure TSplitSectionDialog.fseMiFEditingDone(Sender: TObject);
begin //if abs(fseMiF.Value-FMiF) < 1e-5 then exit;
        FEditMode:=emKeyboard;
        SetMiF( fseMiF.Value );
end;

procedure TSplitSectionDialog.fseMiFChange(Sender: TObject);
begin // if FEditMode in [emMouse] then
         SetMiF( fseMiF.Value );
end;

procedure TSplitSectionDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrClose; Close; end;

procedure TSplitSectionDialog.FormShow(Sender: TObject); begin end;

end.

