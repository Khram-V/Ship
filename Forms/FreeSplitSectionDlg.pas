unit FreeSplitSectionDlg;
{$mode objfpc}{$H+}
interface uses
  Classes,SysUtils,Forms,Controls,Dialogs,ComCtrls,ExtCtrls,Buttons,Spin,Types,
  FreeTypes,FreeShipUnit;
type
  TEditMode = (emProgrammatic,emMouse,emKeyboard);
  TFreeSplitSectionDialogChangeEvent = procedure ( Sender: TObject; aValue: TFloatType ) of object;
  TFreeSplitSectionDialog = class(TForm)            { TFreeSplitSectionDialog }
    BitBtn1: TBitBtn;
    fseSplitSectionLocation: TFloatSpinEdit;
    Panel1: TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton3: TSpeedButton;
    TopPanel: TPanel;
    tbSplitSectionLocation: TTrackBar;
    procedure BitBtn1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure fseSplitSectionLocationChange(Sender: TObject);
    procedure fseSplitSectionLocationEditingDone(Sender: TObject);
    procedure fseSplitSectionLocationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure fseSplitSectionLocationMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure fseSplitSectionLocationMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure tbSplitSectionLocationChange(Sender: TObject);
  private
    FEditMode:TEditMode;
    FSplitSectionLocation:TFloatType;
    FOnSplitSectionLocationChange: TFreeSplitSectionDialogChangeEvent;
    procedure SetSplitSectionLocation(AValue: TFloatType);
  public
    procedure SetDimensions;
    property SplitSectionLocation:TFloatType read FSplitSectionLocation write SetSplitSectionLocation;
    property OnSplitSectionLocationChange: TFreeSplitSectionDialogChangeEvent
             read FOnSplitSectionLocationChange
             write FOnSplitSectionLocationChange;
  end;

var
  FreeSplitSectionDialog: TFreeSplitSectionDialog;

implementation                                      { TFreeSplitSectionDialog }
{$R *.lfm}

procedure TFreeSplitSectionDialog.fseSplitSectionLocationMouseDown
    ( Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin FEditMode:=emMouse; end;

procedure TFreeSplitSectionDialog.fseSplitSectionLocationMouseWheel
( Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean );
begin FEditMode:=emMouse; end;

procedure TFreeSplitSectionDialog.SpeedButton1Click(Sender: TObject);
begin                                                               // 'Medium'
  with Ship.Surface do SetSplitSectionLocation( (Min.X+Max.X)*0.5 );
end;

procedure TFreeSplitSectionDialog.SpeedButton3Click(Sender: TObject);
begin                                                    // 'From hydrostatics'
  SetSplitSectionLocation( Ship.DesignHydrostatics.Data.CenterOfBuoyancy.X );
end;

procedure TFreeSplitSectionDialog.tbSplitSectionLocationChange(Sender: TObject);
begin
    SetSplitSectionLocation( 0.001*tbSplitSectionLocation.Position );
end;

procedure TFreeSplitSectionDialog.SetSplitSectionLocation( AValue: TFloatType );
begin
  if FSplitSectionLocation=AValue then Exit;
  FSplitSectionLocation:=AValue;                  // FEditMode:=emProgrammatic;
  fseSplitSectionLocation.Value:=AValue;
  tbSplitSectionLocation.Position:=round(AValue*1000);
  if assigned(OnSplitSectionLocationChange) then
     OnSplitSectionLocationChange( Self,FSplitSectionLocation );
end;

// Lendth of ship,location of widest place,location of spaciest place
procedure TFreeSplitSectionDialog.SetDimensions;
begin
  tbSplitSectionLocation.Min:=round(Ship.Surface.Min.X*1000);
  tbSplitSectionLocation.Max:=round(Ship.Surface.Max.X*1000+1);
  fseSplitSectionLocation.MinValue:=Ship.Surface.Min.X;
  fseSplitSectionLocation.MaxValue:=Ship.Surface.Max.X;
end;

procedure TFreeSplitSectionDialog.fseSplitSectionLocationKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState );
begin FEditMode:=emKeyboard; end;

procedure TFreeSplitSectionDialog.fseSplitSectionLocationEditingDone(Sender: TObject);
begin
//if abs(fseSplitSectionLocation.Value-FSplitSectionLocation) < 1e-5 then exit;
  FEditMode:=emKeyboard;
  SetSplitSectionLocation( fseSplitSectionLocation.Value );
end;

procedure TFreeSplitSectionDialog.fseSplitSectionLocationChange(Sender: TObject);
begin
//if FEditMode in [emMouse] then
  SetSplitSectionLocation( fseSplitSectionLocation.Value );
end;

procedure TFreeSplitSectionDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrClose; Close; end;

procedure TFreeSplitSectionDialog.FormShow(Sender: TObject); begin end;

end.

