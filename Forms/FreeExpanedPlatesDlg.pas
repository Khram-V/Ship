unit FreeExpanedPlatesDlg;
{$MODE Delphi}{$H+}
interface uses
  LCLIntf,   PrintersDlgs,
  SysUtils,  Classes,
  Graphics,  Controls,
  Forms,     Dialogs,
  ExtCtrls,  StdCtrls,
  ActnList,  ComCtrls,
  Printers,  Math,
  CheckLst,  Spin,
  FreeTypes, FreeShipUnit,
  FreeGeometry, FreeStringUtils, FreeLanguageSupport;
type
  TFreeExpanedplatesDialog = class( TForm )
    ToolBar1: TToolBar;
    MenuImages: TImageList;
    ListBox: TCheckListBox;
    Viewport: TFreeViewport;
    ActionList1: TActionList;
    CheckBoxMirror: TCheckBox;
    SpinEditFontSize: TSpinEdit;
    FloatSpinEdit1,FloatSpinEdit2,FloatSpinEdit3: TFloatSpinEdit;
    Label1,Label3,_Label4,Label5,Label7,Label8,Label10,Label11,Label15,Label17,
    _Label2,_Label6,_Label9,_Label12,_Label13,_Label14,_Label16,_Label18:TLabel;
    Panel1,Panel2,Panel3,Panel4,PaneLayer:                              TPanel;
    ZoomIn,ZoomOut,RotateCCW1,RotateCW1,RotateCCW90,RotateCCW5,RotateCW5,
    RotateCW90,ZoomExtents,SaveBitmap,ExportDXF,ShowStations,ShowButtocks,
    ShowWaterlines,ShowFillColor,ShowInteriorEdges,ShowErrorEdges,
    ShowDiagonals,ShowDimensions,ShowPartName,ShowSubmergedArea,Print,
    ExportTextFile,CloseDialog:                                        TAction;
    ToolButton1,ToolButton2,ToolButton3,ToolButton5,ToolButton7,ToolButton4,
    _ToolButton4,ToolButton6,_ToolButton6,ToolButton8,ToolButton9,ToolButton10,
    ToolButton11,ToolButton12,ToolButton13,_ToolButton14,ToolButton15,
    ToolButton16,ToolButton17,ToolButton18,ToolButton19,ToolButton20,
    _ToolButton21,ToolButton22,ToolButton23,ToolButton24,ToolButton25,
    ToolButton26,ToolButton27:                                     TToolButton;
    PrintDialog: TPrintDialog;
    procedure CloseDialogExecute(Sender: TObject);
    procedure FloatSpinEdit1Change(Sender: TObject);
    procedure FloatSpinEdit2Change(Sender: TObject);
    procedure FloatSpinEdit3Change(Sender: TObject);
    procedure ListBoxClick(Sender: TObject);
    procedure ListBoxClickCheck(Sender: TObject);
    procedure SpinEditFontSizeChange(Sender: TObject);
    procedure ViewportRequestExtents(Sender: TObject; var Min, Max: T3DVector);
    procedure ViewportRedraw(Sender: TObject);
    procedure ViewportMouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
    procedure ViewportMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure ViewportMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure RotateCCW90Execute(Sender: TObject);
    procedure RotateCCW5Execute(Sender: TObject);
    procedure RotateCW5Execute(Sender: TObject);
    procedure RotateCW90Execute(Sender: TObject);
    procedure ZoomExtentsExecute(Sender: TObject);
    procedure SaveBitmapExecute(Sender: TObject);
    procedure ZoomInExecute(Sender: TObject);
    procedure ZoomOutExecute(Sender: TObject);
    procedure RotateCCW1Execute(Sender: TObject);
    procedure RotateCW1Execute(Sender: TObject);
    procedure ExportDXFExecute(Sender: TObject);
    procedure ShowStationsExecute(Sender: TObject);
    procedure ShowButtocksExecute(Sender: TObject);
    procedure ShowWaterlinesExecute(Sender: TObject);
    procedure ShowInteriorEdgesExecute(Sender: TObject);
    procedure ShowFillColorExecute(Sender: TObject);
    procedure ShowErrorEdgesExecute(Sender: TObject);
    procedure ShowDiagonalsExecute(Sender: TObject);
    procedure PrintExecute(Sender: TObject);
    procedure ShowDimensionsExecute(Sender: TObject);
    procedure Edit2KeyPress(Sender: TObject; var Key: char);
    procedure Edit2Exit(Sender: TObject);
    procedure Edit3KeyPress(Sender: TObject; var Key: char);
    procedure Edit3Exit(Sender: TObject);
    procedure Edit1KeyPress(Sender: TObject; var Key: char);
    procedure ShowPartNameExecute(Sender: TObject);
    procedure CheckBoxMirrorClick(Sender: TObject);
    procedure ShowSubmergedAreaExecute(Sender: TObject);
    procedure ExportTextFileExecute(Sender: TObject);
  private   { Private declarations }
    FPlates: TFasterListTFreeDevelopedPatch;
    FFreeShip: TFreeShip;
    FInitialPosition: TPoint;
    FAllowPanOrZoom: boolean;
    FXGridSpacing, FYGridSpacing: TFloatType;
    FFontSize: integer;
    function FGetActivePatch: TFreeDevelopedPatch;
    procedure FSetActivePatch(Val: TFreeDevelopedPatch);
    procedure FUpdateListBox;
    procedure InitViewPort;
  public    { Public declarations }
    function Execute( FreeShip: TFreeShip; Plates: TFasterListTFreeDevelopedPatch ): boolean;
    property ActivePatch: TFreeDevelopedPatch read FGetActivePatch write FSetActivePatch;

  end;

var FreeExpanedplatesDialog: TFreeExpanedplatesDialog;

implementation
  {$R *.lfm}
function GetGridSpacing(OveralSize: TFloatType): TFloatType;
var I: TFloatType; Tmp: TFloatType;
begin
  OveralSize := Abs(OveralSize);
  if OveralSize < 1e-6 then OveralSize := 1e-6;
  I := Ln(OveralSize) / 2.30258;
  Tmp := Power(10, round(I - 1));
  while OveralSize / Tmp < 5 do Tmp := Tmp / 2;
  while OveralSize / Tmp > 20 do Tmp := Tmp * 2;
  if Tmp < OveralSize / 1000 then Tmp := OveralSize / 1000;
  Result := Tmp;
end;
function TFreeExpanedplatesDialog.FGetActivePatch: TFreeDevelopedPatch;
begin Result:=nil;
  if ListBox.ItemIndex<>-1 then
     Result:=Listbox.Items.Objects[ListBox.ItemIndex] as TFreeDevelopedPatch;
end;
procedure TFreeExpanedplatesDialog.FSetActivePatch( Val: TFreeDevelopedPatch );
var Current: TFreeDevelopedPatch; Index: integer;
begin
  Current:=ActivePatch;
  if Val<>Current then begin
    if Val=nil then Index:=-1
               else Index:=ListBox.Items.IndexOfObject(Val);
    ListBox.ItemIndex:=index;
  end;
  Val:=ActivePatch;
  if Val<>nil then begin
    Index:=FPlates.IndexOf(Val);
    if Index<>-1 then begin         // Put it at the end of the list to ensure
      FPlates.Delete(Index);        // that it is always drawn on top
      FPlates.Add(Val);
    end;
  end;
  Label1.Enabled := Val <> nil;
  Label3.Enabled := Val <> nil;
  Label5.Enabled := Val <> nil;
  Label8.Enabled := Val <> nil;
  RotateCCW90.Enabled := Val <> nil;
  RotateCCW5.Enabled := Val <> nil;
  RotateCCW1.Enabled := Val <> nil;
  RotateCW1.Enabled := Val <> nil;
  RotateCW5.Enabled := Val <> nil;
  RotateCW90.Enabled := Val <> nil;
  if Val = nil then begin
    _Label2.Caption := '';
    _Label4.Caption := '';
    _Label6.Caption := '';
    _Label9.Caption := '';
    _Label16.Caption := '';
    _Label18.Caption := '';
    FloatSpinEdit1.Value := 0;
    CheckBoxMirror.Checked := False;
  end else begin
    _Label2.Caption := ': ' + FloatToStrF(Val.MinError, ffFixed,7,5);
    _Label4.Caption := ': ' + FloatToStrF(Val.MaxError, ffFixed,7,5);
    _Label16.Caption:= ': ' + FloatToStrF(Val.MaxAreaError, ffFixed,7,6);
    _Label18.Caption:= ': ' + FloatToStrF(Val.TotalAreaError, ffFixed,7,6);
    _Label6.Caption := ': ' + Val.Name;
    _Label9.Caption := IntToStr(Val.NumberOfIterations);
    FloatSpinEdit1.Value := Val.Rotation;
    CheckBoxMirror.Checked := Val.MirrorOnScreen;
  end;
  Viewport.Refresh;
end;{TFreeExpanedplatesDialog.FSetActivePatch}

procedure TFreeExpanedplatesDialog.FUpdateListBox;
var I,Index: integer; Patch: TFreeDevelopedPatch;
begin
  ListBox.Items.BeginUpdate;
  ListBox.Clear;
  for I:=1 to FPlates.Count do begin Patch:=FPlates[I-1];
    Index:=ListBox.Items.AddObject(Patch.Name, Patch);
    ListBox.Checked[index]:=Patch.Visible;
  end;
  Listbox.Items.EndUpdate;
end;

procedure TFreeExpanedplatesDialog.ViewportRequestExtents(Sender: TObject; var Min, Max: T3DVector);
var FMin,FMax: T3DVector; I,N: integer; Patch: TFreeDevelopedPatch;
begin
  if FPlates<>nil then begin N:=1;
    for I:=1 to FPlates.Count do begin Patch := FPlates[I-1];
      if Patch.Visible then begin Patch.Extents(FMin,FMax);
        if N=1 then begin Min:=FMin; Max:=FMax; end;
        MinMax( FMin,Min,Max );             // this is the first visible patch
        MinMax( FMax,Min,Max ); Inc( N );
      end;
    end;
  end;
end;
function TFreeExpanedplatesDialog.Execute(FreeShip: TFreeShip; Plates: TFasterListTFreeDevelopedPatch): boolean;
var I:Integer; Clearance,Tmp: TFloatType;
  Patch: TFreeDevelopedPatch; Min,Max,MinT,MaxT: T3DVector; P2D: T2DCoordinate;
begin
  InitViewPort;
  FFreeship := FreeShip;
  FPlates := Plates;
  SpinEditFontSizeChange( SpinEditFontSize );
  ToolBar1.ButtonHeight:= MenuImages.Height + 4;
  ToolBar1.ButtonWidth := MenuImages.Width  + 4;
  FUpdateListBox;
  ShowStations.Checked := FreeShip.Visibility.ShowStations;
  ShowButtocks.Checked := FreeShip.Visibility.ShowButtocks;
  ShowWaterlines.Checked := FreeShip.Visibility.ShowWaterlines;
  ShowDiagonals.Checked := FreeShip.Visibility.ShowDiagonals;
  ShowInteriorEdges.Checked := FreeShip.Visibility.ShowInteriorEdges;
  ShowSubmergedArea.Checked := Freeship.ProjectSettings.ProjectShadeUnderwaterShip;
  ShowFillColor.Checked := True;
  ShowErrorEdges.Checked := False;
  ShowSubmergedArea.Enabled := ShowFillColor.Checked;
  Print.Enabled:=Printer <> nil;
  _Label13.Caption:='['+LengthStr(FFreeship.ProjectSettings.ProjectUnits)+']';
  _Label14.Caption:=_Label13.Caption;
  for I:=1 to FPlates.Count do begin // Calculate the initial position fo each surface
    Patch:=Plates[I-1];
    Patch.Extents(Min,Max);
    Clearance := 0.025 * Abs(Min-Max);
    if I = 1 then begin
      P2D.X := -Min.X;
      P2D.Y := -Max.Y - 0.5 * Clearance;
      Patch.Translation := P2D;
      Patch.Extents(MinT,MaxT);
    end else begin
      P2D.X := -Min.X;
      if odd(I) then P2D.Y:=MinT.Y-Max.Y-Clearance  // Odd(I) means portside plate, put at bottom
                else P2D.Y:=MaxT.Y-Min.Y+Clearance; // even(I) is starboard plate, put at top
      Patch.Translation := P2D;
      Patch.Extents(Min, Max);
      MinMax(Min, MinT, MaxT);
      MinMax(Max, MinT, MaxT);
    end;
  end;                                                     // calculate extents
  for I := 1 to FPlates.Count do begin
    Patch := Plates[I - 1];
    Patch.Extents(MinT, MaxT);
    if I = 1 then begin Min := MinT; Max := MaxT; end
             else begin MinMax(MinT,Min,Max); MinMax(MaxT,Min,Max); end;
  end;
  if Max.X - Min.X > Max.Y - Min.Y then Tmp := Max.X - Min.X
                                   else Tmp := Max.Y - Min.Y;
  FXGridSpacing := GetGridSpacing(Tmp) / 2;
  FYGridSpacing := FXGridSpacing;
  FloatSpinEdit2.Value := FXGridSpacing;
  FloatSpinEdit3.Value := FYGridSpacing;
  SpinEditFontSizeChange(nil); //refresh font sizes
  Viewport.ZoomExtents;
  if Plates.Count = 0 then ActivePatch := nil
                      else ListBox.ItemIndex := 0;
  ActivePatch := ActivePatch;
  ShowTranslatedValues(Self);
  ShowModal;
  Result := ModalResult = mrOk;
end;

procedure TFreeExpanedplatesDialog.ViewportRedraw(Sender: TObject);
var I, N: integer;
  Patch: TFreeDevelopedPatch;
  X,Y,Space: TFloatType;
  P: T3DVector;
  Pt1, Pt2: TPoint;
  Suppress: boolean;
  Str: AnsiString;
begin
  if FPlates <> nil then begin                              // Skip translation
    Viewport.DrawingCanvas.Font.Color := clBlack;
    Viewport.DrawingCanvas.Font.Name := 'Arial';
    Viewport.DrawingCanvas.Font.Size := FFontSize;      // End Skip translation
    Viewport.FontSize:=FFontSize;
    if ShowDimensions.Checked then begin Suppress := False;  // Draw grid lines
      Space := 0.025 * Abs(Viewport.Min3D-Viewport.Max3D);
      if FXGridSpacing=0 then N:=10000              // Calculate and draw XGrid
       else N:=round((2*Space+Viewport.Max3D.X-Viewport.Min3D.X)/FXGridSpacing);
      if N<500 then begin
        Viewport.PenColor := RGB(225, 225, 225);
        Viewport.Penwidth := 1;
        Viewport.PenStyle := psSolid;
        I := Round((Viewport.Min3D.X) / FXGridSpacing) - 2;
        X := I * FXGridSpacing;
        while X <= Viewport.Max3D.X do begin
          if (X>=Viewport.Min3D.X-0.01) and (X<=Viewport.Max3D.X+0.01) then begin
            P := Vector(X, Viewport.Min3D.Y - Space, 0.0);
            Pt1 := Viewport.Project(P);
            Viewport.MoveTo(Pt1.X, Pt1.Y);
            P := Vector(X, Viewport.Max3D.Y + Space, 0.0);
            Pt2 := Viewport.Project(P);
            Viewport.LineTo(Pt2.X, Pt2.Y);
            Str := ConvertDimension(X, FFreeship.ProjectSettings.ProjectUnits);
            Viewport.TextOut(Pt1.X-Viewport.TextWidth(Str) div 2, Pt1.Y, Str);
            Viewport.TextOut(Pt2.X-Viewport.TextWidth(Str) div 2, Pt2.Y-Viewport.TextHeight(Str),Str);
          end;
          X:=X+FXGridSpacing;
        end;
      end else Suppress := True;                    // Calculate and draw YGrid
      if FYGridSpacing <> 0 then
        N:=round((2*Space+Viewport.Max3D.Y-Viewport.Min3D.Y)/FYGridSpacing)
      else N := 10000;
      if N < 500 then begin
        Viewport.PenColor := RGB(225, 225, 225);
        Viewport.Penwidth := 1;
        Viewport.PenStyle := psSolid;
        I := Round((Viewport.Min3D.Y) / FYGridSpacing) - 2;
        Y := I * FYGridSpacing;
        while Y <= Viewport.Max3D.Y do begin
          if (Y >= Viewport.Min3D.Y - 0.01) and (Y <= Viewport.Max3D.Y + 0.01) then begin
            P := Vector(Viewport.Min3D.X - Space, Y, 0.0);
            Pt1 := Viewport.Project(P);
            Viewport.MoveTo(Pt1.X, Pt1.Y);
            P := Vector(Viewport.Max3D.X + Space, Y, 0.0);
            Pt2 := Viewport.Project(P);
            Viewport.LineTo(Pt2.X, Pt2.Y);
            Str := ConvertDimension(Y, FFreeship.ProjectSettings.ProjectUnits);
            Viewport.TextOut(Pt1.X,Pt1.Y-Viewport.TextHeight(Str) div 2,Str);
            Viewport.TextOut(Pt2.X-Viewport.TextWidth(Str) div 2,Pt2.Y-Viewport.TextHeight(Str) div 2,Str);
          end;
          Y := Y + FYGridSpacing;
        end;
      end else Suppress := True;
    end else Suppress := False;

    for I := 1 to FPlates.Count do begin
      Patch := FPlates[I - 1];
      if Patch.Visible then begin
        Patch.ShowDimensions   := (ShowDimensions.Checked) and (not Suppress);
        Patch.ShowBoundingBox  := Patch = ActivePatch;
        Patch.ShowStations     := ShowStations.Checked;
        Patch.ShowButtocks     := ShowButtocks.Checked;
        Patch.ShowWaterlines   := ShowWaterlines.Checked;
        Patch.ShowDiagonals    := ShowDiagonals.Checked;
        Patch.ShowInteriorEdges:= ShowInteriorEdges.Checked;
        Patch.ShowSolid        := ShowFillColor.Checked;
        Patch.ShowErrorEdges   := ShowErrorEdges.Checked;
        Patch.XGrid := FXGridSpacing;
        Patch.YGrid := FYGridSpacing;
        Patch.Units := FFreeship.ProjectSettings.ProjectUnits;
        Patch.ShowPartName := ShowPartName.Checked;
        Patch.ShadeSubmerged := ShowSubmergedArea.Checked;
        Patch.Draw( Viewport );
      end;
    end;
  end;
end;

procedure TFreeExpanedplatesDialog.ViewportMouseMove
        ( Sender: TObject; Shift: TShiftState; X,Y: integer );
var P: TPoint;
  P1,P2,Diff: T2DCoordinate;
  Patch: TFreeDevelopedPatch;
begin
  if FAllowPanOrZoom then begin
    if ssLeft in Shift then begin                        // Zoom in or zoom out
      if abs(FInitialPosition.Y - Y) > 4 then begin
        if Y < FInitialPosition.Y then Viewport.ZoomIn else
        if Y > FInitialPosition.Y then Viewport.ZoomOut;
        FInitialPosition.X := X;
        FInitialPosition.Y := Y;
      end;
    end else if ssRight in Shift then
      if (abs(FInitialPosition.X - X) > 4) or (abs(FInitialPosition.Y - Y) > 4) then begin
        P.X := Viewport.Pan.X + X - FInitialPosition.X;
        P.Y := Viewport.Pan.Y + Y - FInitialPosition.Y;
        Viewport.Pan := P;
        FInitialPosition.X := X;
        FInitialPosition.Y := Y;
      end; // Pan the window left, right, top or bottom
  end else begin
    Patch := ActivePatch;
    if (ssLeft in Shift) and (Patch <> nil) then
      if (abs(FInitialPosition.X - X) > 0) or (abs(FInitialPosition.Y - Y) > 0) then begin
        P.X := X;
        P.Y := Y;
        P1 := Viewport.ProjectBackTo2D(FInitialPosition);
        P2 := Viewport.ProjectBackTo2D(P);
        Diff.X := Patch.Translation.X + (P2.X - P1.X);
        Diff.Y := Patch.Translation.Y + (P2.Y - P1.Y);
        Patch.Translation := Diff;
        Viewport.Refresh;
        FInitialPosition.X := X;
        FInitialPosition.Y := Y;
      end; // Translate the selected patch
  end;
end;

procedure TFreeExpanedplatesDialog.ViewportMouseDown
(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
var Active: TFreeDevelopedPatch; I,Dist: integer;
begin
  FInitialPosition.X := X;
  FInitialPosition.Y := Y;
  FAllowPanOrZoom := True;
  if Button = mbLeft then
    for I := FPlates.Count downto 1 do begin Active:=FPlates[I-1];
      if Active.Visible then begin
        Dist := Active.DistanceToCursor( X,Y,Viewport );
        if Dist <= Active.Owner.Surface.ControlPointSize then begin
          if ActivePatch<>Active then ActivePatch:=Active;
          FAllowPanOrZoom := False;
          break;
        end;
      end;
    end;
end;

procedure TFreeExpanedplatesDialog.ListBoxClick( Sender: TObject );
    begin ActivePatch:=ActivePatch; Viewport.Refresh; end;
procedure TFreeExpanedplatesDialog.ListBoxClickCheck( Sender: TObject );
var Patch: TFreeDevelopedPatch;
begin
  if Listbox.ItemIndex<>-1 then begin
    Patch:=Listbox.Items.Objects[Listbox.ItemIndex] as TFreeDevelopedPatch;
    if Patch.Visible<>Listbox.Checked[Listbox.ItemIndex] then begin
      Patch.Visible:=Listbox.Checked[Listbox.ItemIndex];
      if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
    end;
  end; ActivePatch:=ActivePatch;
end;

procedure TFreeExpanedplatesDialog.SpinEditFontSizeChange(Sender: TObject);
var I: integer; Patch: TFreeDevelopedPatch;
begin
  FFontSize := SpinEditFontSize.Value;
  for I:=0 to FPlates.Count - 1 do begin Patch := FPlates[I];
    Patch.DimFontSize := SpinEditFontSize.Value;
  end;
  Viewport.Refresh;
end;

procedure TFreeExpanedplatesDialog.CloseDialogExecute(Sender: TObject);
    begin Close; end;

procedure TFreeExpanedplatesDialog.ViewportMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
begin
  if (not FAllowPanOrZoom) and (Viewport.Zoom = 1.0) then Viewport.ZoomExtents;
  FAllowPanOrZoom := True;
end;

procedure TFreeExpanedplatesDialog.RotateCCW90Execute(Sender: TObject);
begin
  if ActivePatch <> nil then begin
    ActivePatch.Rotation := ActivePatch.Rotation + 90;
    FloatSpinEdit1.Value := ActivePatch.Rotation;
    if Viewport.Zoom = 1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
  end;
end;

procedure TFreeExpanedplatesDialog.RotateCCW5Execute(Sender: TObject);
begin
  if ActivePatch <> nil then
  begin
    ActivePatch.Rotation := ActivePatch.Rotation + 5;
    FloatSpinEdit1.Value := ActivePatch.Rotation;
    if Viewport.Zoom = 1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
  end;
end;

procedure TFreeExpanedplatesDialog.RotateCW5Execute(Sender: TObject);
begin
  if ActivePatch <> nil then begin
    ActivePatch.Rotation := ActivePatch.Rotation - 5;
    FloatSpinEdit1.Value := ActivePatch.Rotation;
    if Viewport.Zoom = 1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
  end;
end;

procedure TFreeExpanedplatesDialog.RotateCW90Execute(Sender: TObject);
begin
  if ActivePatch <> nil then begin
    ActivePatch.Rotation := ActivePatch.Rotation - 90;
    FloatSpinEdit1.Value := ActivePatch.Rotation;
    if Viewport.Zoom = 1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
  end;
end;

procedure TFreeExpanedplatesDialog.ZoomExtentsExecute(Sender: TObject);
    begin Viewport.ZoomExtents; end;
procedure TFreeExpanedplatesDialog.SaveBitmapExecute(Sender: TObject);
    begin Viewport.SaveAsBitmap( FFreeShip.Preferences.ExportDirectory
     +ChangeFileExt(ExtractFilename(FFreeship.FileName),'')+'_developments.png');
    end;
procedure TFreeExpanedplatesDialog.ZoomInExecute(Sender: TObject);
    begin Viewport.ZoomIn; end;
procedure TFreeExpanedplatesDialog.ZoomOutExecute(Sender: TObject);
    begin Viewport.ZoomOut; end;
procedure TFreeExpanedplatesDialog.RotateCCW1Execute(Sender: TObject);
begin
  if ActivePatch<>nil then begin
    ActivePatch.Rotation:=ActivePatch.Rotation+1;
    FloatSpinEdit1.Value:=ActivePatch.Rotation;
    if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                         else Viewport.Refresh;
  end;
end;

procedure TFreeExpanedplatesDialog.RotateCW1Execute(Sender: TObject);
begin
  if ActivePatch<>nil then begin
    ActivePatch.Rotation:=ActivePatch.Rotation-1;
    FloatSpinEdit1.Value:=ActivePatch.Rotation;
    if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                         else Viewport.Refresh;
  end;
end;

procedure TFreeExpanedplatesDialog.ExportDXFExecute(Sender: TObject);
var I: integer;
  Strings: TStringList;
  Patch: TFreeDevelopedPatch;
  SaveDialog: TSaveDialog;
begin
  SaveDialog:=TSaveDialog.Create(Owner);
  SaveDialog.InitialDir:=FFreeship.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FFreeship.FileName),'')+'_developments.dxf';
  SaveDialog.Filter:=createDialogFilter(rsAutocadDxfFile,['dxf']);
  Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
  if SaveDialog.Execute then begin
    FFreeShip.Preferences.ExportDirectory := ExtractFilePath(SaveDialog.FileName);
    Strings := TStringList.Create;
    Strings.Add( '0'+EOL+'SECTION' );
    Strings.Add( '2'+EOL+'ENTITIES' );
    for I := 1 to FPlates.Count do begin
      Patch := FPlates[I-1];
      if Patch.Visible then Patch.SaveToDXF(Strings);
    end;
    Strings.Add( '0'+EOL+'ENDSEC' );
    Strings.Add( '0'+EOL+'EOF' );
    Strings.SaveToFile(ChangeFileExt( SaveDialog.FileName,'.dxf') );
    FreeAndNil(Strings);
  end;
  FreeAndNil(SaveDialog);
end;

procedure TFreeExpanedplatesDialog.ShowStationsExecute(Sender: TObject);
    begin ShowStations.Checked := not ShowStations.Checked; Viewport.Refresh;
    end;
procedure TFreeExpanedplatesDialog.ShowButtocksExecute(Sender: TObject);
    begin ShowButtocks.Checked := not ShowButtocks.Checked; Viewport.Refresh;
    end;
procedure TFreeExpanedplatesDialog.ShowWaterlinesExecute(Sender: TObject);
    begin ShowWaterlines.Checked := not ShowWaterlines.Checked;
          Viewport.Refresh;
    end;
procedure TFreeExpanedplatesDialog.ShowInteriorEdgesExecute(Sender: TObject);
    begin ShowInteriorEdges.Checked := not ShowInteriorEdges.Checked;
          Viewport.Refresh;
    end;
procedure TFreeExpanedplatesDialog.ShowFillColorExecute(Sender: TObject);
    begin ShowFillColor.Checked := not ShowFillColor.Checked;
          ShowSubmergedArea.Enabled := ShowFillColor.Checked;
          Viewport.Refresh;
    end;
procedure TFreeExpanedplatesDialog.ShowErrorEdgesExecute(Sender: TObject);
    begin ShowErrorEdges.Checked := not ShowErrorEdges.Checked;
          Viewport.Refresh;
    end;
procedure TFreeExpanedplatesDialog.ShowDiagonalsExecute(Sender: TObject);
    begin ShowDiagonals.Checked := not ShowDiagonals.Checked; Viewport.Refresh;
    end;
procedure TFreeExpanedplatesDialog.PrintExecute(Sender: TObject);
begin if Viewport.Width>Viewport.Height then Printer.Orientation:=poLandscape
                                        else Printer.Orientation:=poPortrait;
  if PrintDialog.Execute then
  Viewport.Print(self.FFreeShip.ProjectSettings.ProjectUnits,True,UserString(214));
end;
procedure TFreeExpanedplatesDialog.ShowDimensionsExecute(Sender: TObject);
    begin ShowDimensions.Checked := not ShowDimensions.Checked;
          Viewport.Refresh;
    end;

procedure TFreeExpanedplatesDialog.Edit2KeyPress(Sender: TObject; var Key: char);
    begin end;
procedure TFreeExpanedplatesDialog.Edit2Exit(Sender: TObject);
    begin end;
procedure TFreeExpanedplatesDialog.Edit3KeyPress(Sender: TObject; var Key: char);
    begin end;
procedure TFreeExpanedplatesDialog.Edit3Exit(Sender: TObject);
    begin end;
procedure TFreeExpanedplatesDialog.Edit1KeyPress(Sender: TObject; var Key: char);
    begin end;

procedure TFreeExpanedplatesDialog.FloatSpinEdit2Change(Sender: TObject);
var S, I: integer;
begin
  FloatSpinEdit2.OnChange := nil;                    // detach to avoid looping
//try
    FXGridSpacing := FloatSpinEdit2.Value;
                       // Increment will automatically change from 0.01 to 10.0
                       // We calculate in hundreds ints to simplify comparisons
    I := round(FloatSpinEdit2.Increment * 100);
    S := round(FXGridSpacing * 100);
    if (S < 1) then S := 1;
    if (S > 1000) then S := 1000;
    if (I > 1) and (S <= I) then I := I div 10;
    if (I < 1000) and (S >= (I * 10)) then I := I * 10;
    FloatSpinEdit2.Increment := 0.01 * I;
    FXGridSpacing := 0.01 * S;
    FloatSpinEdit2.Value := FXGridSpacing;
    Viewport.Refresh;
//finally
    FloatSpinEdit2.OnChange := FloatSpinEdit2Change;
//end;
end;

procedure TFreeExpanedplatesDialog.FloatSpinEdit3Change(Sender: TObject);
var S, I: integer;
begin
  FloatSpinEdit3.OnChange := nil;                    // detach to avoid looping
//try
    FYGridSpacing := FloatSpinEdit3.Value;
                       // Increment will automatically change from 0.01 to 10.0
                       // We calculate in hundreds ints to simplify comparisons
    I := round(FloatSpinEdit3.Increment * 100);
    S := round(FYGridSpacing * 100);
    if (S < 1) then S := 1;
    if (S > 1000) then S := 1000;
    if (I > 1) and (S <= I) then I := I div 10;
    if (I < 1000) and (S >= (I * 10)) then I := I * 10;
    FloatSpinEdit3.Increment := 0.01 * I;
    FYGridSpacing := 0.01 * S;
    FloatSpinEdit3.Value := FYGridSpacing;
    Viewport.Refresh;
//finally
    FloatSpinEdit3.OnChange := FloatSpinEdit3Change;
//end;
end;

procedure TFreeExpanedplatesDialog.FloatSpinEdit1Change(Sender: TObject);
begin
  if FloatSpinEdit1.Value <> ActivePatch.Rotation then begin
    ActivePatch.Rotation := FloatSpinEdit1.Value;
    if Viewport.Zoom = 1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
  end;
end;

procedure TFreeExpanedplatesDialog.ShowPartNameExecute(Sender: TObject);
    begin ShowPartName.Checked := not ShowPartName.Checked; Viewport.Refresh;
    end;

procedure TFreeExpanedplatesDialog.CheckBoxMirrorClick(Sender: TObject);
begin
  if ActivePatch <> nil then
  if CheckBoxMirror.Checked <> ActivePatch.MirrorOnScreen then begin
     ActivePatch.MirrorOnScreen := CheckBoxMirror.Checked;
     if Viewport.Zoom = 1.0 then Viewport.ZoomExtents
                            else Viewport.Refresh;
  end;
end;

procedure TFreeExpanedplatesDialog.ShowSubmergedAreaExecute(Sender: TObject);
begin ShowSubmergedArea.Checked := not ShowSubmergedarea.Checked;
      Viewport.Refresh;
end;

procedure TFreeExpanedplatesDialog.ExportTextFileExecute(Sender: TObject);
var I: integer;
  Strings: TStringList;
  Patch: TFreeDevelopedPatch;
  SaveDialog: TSaveDialog;
begin
  SaveDialog := TSaveDialog.Create(Owner);
  SaveDialog.InitialDir := FFreeship.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(ExtractFilename(FFreeship.FileName),'')+'_developments.txt';
  SaveDialog.Filter:=createDialogFilter(rsTextFile,['txt']);
  Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
  if SaveDialog.Execute then begin
    FFreeShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
    Strings:=TStringList.Create;
    for I:=1 to FPlates.Count do begin Patch:=FPlates[I-1];
      if Patch.Visible then Patch.SaveToTextFile(Strings);
    end;
    Strings.SaveToFile( ChangeFileExt( SaveDialog.FileName,'.txt' ) );
    FreeAndNil( Strings );
  end;
  FreeAndNil( SaveDialog );
end;

procedure TFreeExpanedplatesDialog.InitViewPort;
begin
  ViewPort := TFreeViewPort.Create(Self);
  with Viewport do begin
    Parent := Self;
    Left := 0;
    Height := 557;
    Top := 26;
    Width := 636;
    Angle := 90;
    Align := alClient;
    BackgroundImage.Alpha := 255;
    BackgroundImage.Owner := Viewport;
    BackgroundImage.Quality := 100;
    BackgroundImage.Scale := 1;
    BackgroundImage.ShowInView := fvBodyplan;
    BackgroundImage.Tolerance := 5;
    BackgroundImage.Transparent := False;
    BackgroundImage.TransparentColor := clBlack;
    BackgroundImage.Visible := True;
    CameraType := ftStandard;
    Color := clWhite;
    DoubleBuffer := False;
    Elevation := 90;
    ParentFont:=false;
    Margin := 4;
    ViewType := fvPlan;
    ViewportMode := vmWireFrame;
    OnMouseDown := ViewportMouseDown;
    OnMouseUp := ViewportMouseUp;
    OnMouseMove := ViewportMouseMove;
    OnRedraw := ViewportRedraw;
    OnRequestExtents := ViewportRequestExtents;
  end;
end;

end.
