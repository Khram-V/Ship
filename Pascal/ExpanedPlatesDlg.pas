
unit ExpanedPlatesDlg;

interface uses Windows,
     SysUtils,
     Classes,
     Graphics,
     Controls,
     Forms,
     Dialogs,
     ExtCtrls,
     StdCtrls,
     ActnList,
     ComCtrls,
     Math,
     CheckLst,
     FasterList,Geometry,ShipUnit,STypes;

type TExpanedplatesDialog  = class(TForm)
     Viewport: TViewport;
     ActionList1: TActionList;
     ToolBar1: TToolBar;
     Splitter1: TSplitter;
     Panel2,Panel3: TPanel;
     Label1,_Label2,Label3,_Label4,Label5,_Label6,Label7,Label8,_Label9,Label10,
     Label11,_Label12,_Label13,_Label14,Label15,_Label16,Label17,_Label18: TLabel;
     Edit1,Edit2,Edit3: TEdit;
     TB1,TB2,TB3,TB4,_TB4,TB5,TB6,_TB6,TB7,TB8,TB9,TB10,TB11,TB12,TB13,_TB14,
     TB15,TB16,TB17,TB18,TB19,TB20,_TB21,TB22,TB23,TB24,TB26,TB27: TToolButton;
     CheckBox1: TCheckBox;
     RotateCCW90: TAction;
     MenuImages: TImageList;
     RotateCCW5: TAction;
     RotateCW5: TAction;
     RotateCW90: TAction;
     ZoomExtents: TAction;
     SaveBitmap: TAction;
     ZoomIn: TAction;
     ZoomOut: TAction;
     RotateCCW1: TAction;
     RotateCW1: TAction;
     ListBox: TCheckListBox;
     ExportDXF: TAction;
     ShowStations: TAction;
     ShowButtocks: TAction;
     ShowWaterlines: TAction;
     ShowInteriorEdges: TAction;
     ShowFillColor: TAction;
     ShowErrorEdges: TAction;
     ShowDiagonals: TAction;
     ShowDimensions: TAction;
     ShowPartName: TAction;
     ShowSubmergedArea: TAction;
     ExportTextFile: TAction;
     procedure ViewportRequestExtents(Sender: TObject; var Min,Max: Vector);
     procedure ViewportRedraw(Sender:TObject);
     procedure ViewportMouseMove(Sender:TObject; Shift:TShiftState; X,Y: Integer);
     procedure ViewportMouseDown(Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y: Integer);
     procedure ListBoxClick(Sender: TObject);
     procedure ViewportMouseUp(Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y: Integer);
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
     procedure ToolButton22Click(Sender: TObject);
     procedure ShowErrorEdgesExecute(Sender: TObject);
     procedure ShowDiagonalsExecute(Sender: TObject);
     procedure ShowDimensionsExecute(Sender: TObject);
     procedure Edit2KeyPress(Sender: TObject; var Key: Char);
     procedure Edit2Exit(Sender: TObject);
     procedure Edit3KeyPress(Sender: TObject; var Key: Char);
     procedure Edit3Exit(Sender: TObject);
     procedure Edit1KeyPress(Sender: TObject; var Key: Char);
     procedure Edit1Exit(Sender: TObject);
     procedure ShowPartNameExecute(Sender: TObject);
     procedure CheckBox1Click(Sender: TObject);
     procedure ShowSubmergedAreaExecute(Sender: TObject);
     procedure ExportTextFileExecute(Sender: TObject);
private
   FPlates: TFasterList;
   FShip: TShip;
   FInitialPosition: TPoint;
   FAllowPanOrZoom: Boolean;
   FXGridSpacing,
   FYGridSpacing: Real;
   function FGetActivePatch:TDevelopedPatch;
   procedure FSetActivePatch(Val:TDevelopedPatch);
   procedure FUpdateListBox;
public
   function Execute(Ship:TShip;Plates:TFasterList):boolean;
   property ActivePatch : TDevelopedPatch read FGetActivePatch write FSetActivePatch;
end;

var ExpanedplatesDialog: TExpanedplatesDialog;

implementation
{$R *.lfm}

function GetGridSpacing(OveralSize:Real):Real;
var I,Tmp: Real;
begin
   OveralSize:=Abs(OveralSize);
   if OveralSize<1e-6 then OveralSize:=1e-6;
   I:=Ln(OveralSize)/2.30258;
   Tmp:=Power(10,round(I-1));
   while OveralSize/Tmp<5 do Tmp:=Tmp/2;
   while OveralSize/Tmp>20 do Tmp:=Tmp*2;
   if Tmp<OveralSize/1000 then Tmp:=OveralSize/1000;
   Result:=Tmp;
end;

function TExpanedplatesDialog.FGetActivePatch:TDevelopedPatch;
begin
   Result:=nil;
   if ListBox.ItemIndex<>-1 then
      Result:=Listbox.Items.Objects[ListBox.ItemIndex] as TDevelopedPatch;
end;

procedure TExpanedplatesDialog.FSetActivePatch(Val:TDevelopedPatch);
var Current: TDevelopedPatch; Index: Integer;
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
      if Index<>-1 then begin        // Put it at the end of the list to ensure
         FPlates.Delete(Index);      // that it is always drawn on top
         FPlates.Add(Val);
      end;
   end;
   Label1.Enabled:=Val<>nil;
   Label3.Enabled:=Val<>nil;
   Label5.Enabled:=Val<>nil;
   Label8.Enabled:=Val<>nil;
   RotateCCW90.Enabled:=Val<>nil;
   RotateCCW5.Enabled:=Val<>nil;
   RotateCCW1.Enabled:=Val<>nil;
   RotateCW1.Enabled:=Val<>nil;
   RotateCW5.Enabled:=Val<>nil;
   RotateCW90.Enabled:=Val<>nil;
   if Val=nil then begin
      _Label2.Caption:='';
      _Label4.Caption:='';
      _Label6.Caption:='';
      _Label9.Caption:='';
      _Label16.Caption:='';
      _Label18.Caption:='';
      Edit1.Text:='';
      Checkbox1.Checked:=False;
   end else begin
      _Label2.Caption:=': '+FloatToDec(Val.MinError,5);
      _Label4.Caption:=': '+FloatToDec(Val.MaxError,5);
      _Label16.Caption:=': '+FloatToDec(Val.MaxAreaError,6);
      _Label18.Caption:=': '+FloatToDec(Val.TotalAreaError,6);
      _Label6.Caption:=': '+Val.Name;
      _Label9.Caption:=IntToStr(Val.NoIterations);
      Edit1.Text:=FloatToDec(Val.Rotation,3);
      Checkbox1.Checked:=Val.MirrorOnScreen;
   end;
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.FUpdateListBox;
var I,Index: Integer; Patch: TDevelopedPatch;
begin
   ListBox.Items.BeginUpdate;
   ListBox.Clear;
   for I:=1 to FPlates.Count do begin
      Patch:=FPlates[I-1];
      Index:=ListBox.Items.AddObject(Patch.Name,Patch);
      ListBox.Checked[index]:=Patch.Visible;
   end;
   Listbox.Items.EndUpdate;
end;

procedure TExpanedplatesDialog.ViewportRequestExtents(Sender: TObject;var Min, Max: Vector);
var FMin,FMax  : Vector;
    I,N        : Integer;
    Patch      : TDevelopedPatch;
begin
   if FPlates<>nil then begin N:=1;
      for I:=1 to FPlates.Count do begin Patch:=FPlates[I-1];
         if Patch.Visible then begin Patch.Extents(FMin,FMax);
            if N=1 then begin                // this is the first visible patch
               Min:=FMin;
               Max:=FMax;
            end;
            MinMax(FMin,Min,Max);
            MinMax(FMax,Min,Max);
            inc(N);
         end;
      end;
   end;
end;

function TExpanedplatesDialog.Execute(Ship:TShip;Plates:TFasterList):boolean;
var I: Integer;
    Patch: TDevelopedPatch;
    Min,Max,MinT,MaxT  : Vector;
    P2D: Place;
    Clearance,Tmp: Real;
begin
   Fship:=Ship;
   FPlates:=Plates;
   FUpdateListBox;
   ShowStations.Checked:=Ship.Visibility.ShowStations;
   ShowButtocks.Checked:=Ship.Visibility.ShowButtocks;
   ShowWaterlines.Checked:=Ship.Visibility.ShowWaterlines;
   ShowDiagonals.Checked:=Ship.Visibility.ShowDiagonals;
   ShowInteriorEdges.Checked:=Ship.Visibility.ShowInteriorEdges;
   ShowSubmergedArea.Checked:=Sp.UColorIs; //.ProjectSettings.ProjectShadeUnderwaterShip;
   ShowFillColor.Checked:=True;
   ShowErrorEdges.Checked:=False;
   ShowSubmergedArea.Enabled:=ShowFillColor.Checked;
   _Label13.Caption:=LengthStr(Fship.ProjectSettings.ProjectUnits);
   _Label14.Caption:=_Label13.Caption; // Calculate the initial position fo each surface
   for I:=1 to FPlates.Count do begin
      Patch:=Plates[I-1];
      Patch.Extents( Min,Max );
      Clearance:=0.025*Abs( Min-Max );
      if I=1 then begin
         P2D.X:=-Min.X;
         P2D.Y:=-Max.Y-0.5*Clearance;
         Patch.Translation:=P2D;
         Patch.Extents(MinT,MaxT);
      end else begin
         P2D.X:=-Min.X;
         if odd(I) then P2D.Y:=MinT.Y-Max.Y-Clearance  // Odd(I) means portside plate, put at bottom
                   else P2D.Y:=MaxT.Y-Min.Y+Clearance; // even(I) is starboard plate, put at top
         Patch.Translation:=P2D;
         Patch.Extents(Min,Max);
         MinMax(Min,MinT,MaxT);
         MinMax(Max,MinT,MaxT);
      end;
   end;
   for I:=1 to FPlates.Count do begin                  // calculate extents
      Patch:=Plates[I-1];
      Patch.Extents(MinT,MaxT);
      if I=1 then begin
         Min:=MinT;
         Max:=MaxT;
      end else begin
         MinMax(MinT,Min,Max);
         MinMax(MaxT,Min,Max);
      end;
   end;
   if Max.X-Min.X>Max.Y-Min.Y then Tmp:=Max.X-Min.X
                              else Tmp:=Max.Y-Min.Y;
   FXGridSpacing:=GetGridSpacing(Tmp)/2;
   FYGridSpacing:=FXGridSpacing;
   Edit2.Text:=FloatToDec(FXGridSpacing,3);
   Edit3.Text:=FloatToDec(FYGridSpacing,3);

   Viewport.ZoomExtents;
   if Plates.Count=0 then ActivePatch:=nil
                     else ListBox.ItemIndex:=0;
   ActivePatch:=ActivePatch;
   ShowModal;
   Result:=ModalResult=mrOk;
end;

procedure TExpanedplatesDialog.ViewportRedraw(Sender: TObject);
var I,N: Integer;
    Patch: TDevelopedPatch;
    X,Y,Space: Real;
    P: Vector;
    Pt1,Pt2: TPoint;
    Suppress:Boolean;
    Str: string;
begin
   if FPlates<>nil then
   begin
      if ShowDimensions.Checked then begin
         Suppress:=False;                                   // Draw grid lines
         Space:=0.025*Abs( Viewport.Min3D-Viewport.Max3D ); // Calculate and draw XGrid
         if FXGridSpacing<>0
            then N:=round((2*Space+Viewport.Max3D.X-Viewport.Min3D.X)/FXGridSpacing)
            else N:=10000;
         if N<500 then begin
            Viewport.PenColor:=RGB(225,225,225);
            Viewport.Penwidth:=1;
            Viewport.PenStyle:=psSolid;
            I:=Round((Viewport.Min3D.X)/FXGridSpacing)-2;
            X:=I*FXGridSpacing;
            Viewport.FontName:=UFont; //'Arial';
            Viewport.Canvas.Font.Size:=6;
            while X<=Viewport.Max3D.X do begin
               if (X>=Viewport.Min3D.X-0.01)
               and (X<=Viewport.Max3D.X+0.01) then begin
                  P:=iVect(X,Viewport.Min3D.Y-Space,0.0);
                  Pt1:=Viewport.Project(P);
                  Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                  P:=iVect(X,Viewport.Max3D.Y+Space,0.0);
                  Pt2:=Viewport.Project(P);
                  Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
                  Str:=ConvertDimension(X,Fship.ProjectSettings.ProjectUnits);
                  Viewport.Canvas.TextOut(Pt1.X-Viewport.Canvas.TextWidth(Str) div 2,Pt1.Y,Str);
                  Viewport.Canvas.TextOut(Pt2.X-Viewport.Canvas.TextWidth(Str) div 2,Pt2.Y-Viewport.Canvas.TextHeight(Str),Str);
               end;
               X:=X+FXGridSpacing;
            end;
         end else Suppress:=True;                   // Calculate and draw YGrid
         if FYGridSpacing<>0
            then N:=round((2*Space+Viewport.Max3D.Y-Viewport.Min3D.Y)/FYGridSpacing)
            else N:=10000;
         if N<500 then begin
            Viewport.PenColor:=RGB(225,225,225);
            Viewport.Penwidth:=1;
            Viewport.PenStyle:=psSolid;
            I:=Round((Viewport.Min3D.Y)/FYGridSpacing)-2;
            Y:=I*FYGridSpacing;
            Viewport.FontName:=UFont; //'Arial';
            Viewport.Canvas.Font.Size:=6;
            while Y<=Viewport.Max3D.Y do begin
               if (Y>=Viewport.Min3D.Y-0.01)
               and (Y<=Viewport.Max3D.Y+0.01) then begin
                  P:=iVect(Viewport.Min3D.X-Space,Y,0.0);
                  Pt1:=Viewport.Project(P);
                  Viewport.Canvas.MoveTo(Pt1.X,Pt1.Y);
                  P:=iVect(Viewport.Max3D.X+Space,Y,0.0);
                  Pt2:=Viewport.Project(P);
                  Viewport.Canvas.LineTo(Pt2.X,Pt2.Y);
                  Str:=ConvertDimension(Y,Fship.ProjectSettings.ProjectUnits);
                  Viewport.Canvas.TextOut(Pt1.X,Pt1.Y-Viewport.Canvas.TextHeight(Str) div 2,Str);
                  Viewport.Canvas.TextOut(Pt2.X-Viewport.Canvas.TextWidth(Str) div 2,Pt2.Y-Viewport.Canvas.TextHeight(Str) div 2,Str);
               end;
               Y:=Y+FYGridSpacing;
            end;
         end else Suppress:=True;
      end else Suppress:=False;

      for I:=1 to FPlates.Count do begin
         Patch:=FPlates[I-1];
         if Patch.Visible then begin
            Patch.ShowDimensions:=(ShowDimensions.Checked) and (not Suppress);
            Patch.ShowBoundingBox:=Patch=ActivePatch;
            Patch.ShowStations:=ShowStations.Checked;
            Patch.ShowButtocks:=ShowButtocks.Checked;
            Patch.ShowWaterlines:=ShowWaterlines.Checked;
            Patch.ShowDiagonals:=ShowDiagonals.Checked;
            Patch.ShowInteriorEdges:=ShowInteriorEdges.Checked;
            Patch.ShowSolid:=ShowFillColor.Checked;
            Patch.ShowErrorEdges:=ShowErrorEdges.Checked;
            Patch.XGrid:=FXGridSpacing;
            Patch.YGrid:=FYGridSpacing;
            Patch.Units:=Fship.ProjectSettings.ProjectUnits;
            Patch.ShowPartName:=ShowPartName.Checked;
            Patch.ShadeSubmerged:=ShowSubmergedArea.Checked;
            Patch.Draw(Viewport);
         end;
      end;
   end;
end;

procedure TExpanedplatesDialog.ViewportMouseMove(Sender: TObject;Shift: TShiftState; X, Y: Integer);
var P: TPoint;
    P1,P2,Diff: Place;
    Patch: TDevelopedPatch;
begin
   if FAllowPanOrZoom then begin
      if ssLeft in Shift then begin                      // Zoom in or zoom out
         if abs(FInitialPosition.Y-Y)>4 then begin
            if Y<FInitialPosition.Y then Viewport.ZoomIn else
            if Y>FInitialPosition.Y then Viewport.ZoomOut;
            FInitialPosition:=Point( X,Y );
         end;
      end else if ssRight in Shift then begin // Pan the window left, right, top or bottom
         if (abs(FInitialPosition.X-X)>4) or (abs(FInitialPosition.Y-Y)>4)  then
         begin
            P.X:=Viewport.Pan.X+X-FInitialPosition.X;
            P.Y:=Viewport.Pan.Y+Y-FInitialPosition.Y;
            Viewport.Pan:=P;
            FInitialPosition:=Point( X,Y );
         end;
      end;
   end else begin
      Patch:=ActivePatch;
      if (ssLeft in Shift) and (Patch<>nil) then // Translate the selected patch
      if (abs(FInitialPosition.X-X)>0) or (abs(FInitialPosition.Y-Y)>0)
      then begin
         P.X:=X;
         P.Y:=Y;
         P1:=Viewport.ProjectBackTo2D(FInitialPosition);
         P2:=Viewport.ProjectBackTo2D(P);
         Diff.X:=Patch.Translation.X+(P2.X-P1.X);
         Diff.Y:=Patch.Translation.Y+(P2.Y-P1.Y);
         Patch.Translation:=Diff;
         Viewport.Refresh;
         FInitialPosition:=Point( X,Y );
      end;
   end;
end;

procedure TExpanedplatesDialog.ViewportMouseDown(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var Active: TDevelopedPatch;
    I,Dist:Integer;
begin
   FInitialPosition:=Point( X,Y );
   FAllowPanOrZoom:=True;
   if Button=mbLeft then for I:=FPlates.Count downto 1 do begin
      Active:=FPlates[I-1];
      if Active.Visible then begin
         Dist:=Active.DistanceToCursor(X,Y,Viewport);
         if Dist<=Active.Owner.Owner.ControlPointSize then begin
            if ActivePatch<>Active then ActivePatch:=Active;
            FAllowPanOrZoom:=False;
            break;
         end;
      end;
   end;
end;

procedure TExpanedplatesDialog.ListBoxClick(Sender: TObject);
var Patch: TDevelopedPatch;
begin
   if Listbox.ItemIndex<>-1 then begin
      Patch:=Listbox.Items.Objects[Listbox.ItemIndex] as TDevelopedPatch;
      if Patch.Visible<>Listbox.Checked[Listbox.ItemIndex] then begin
         Patch.Visible:=Listbox.Checked[Listbox.ItemIndex];
         if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                              else Viewport.Refresh;
      end;
   end; ActivePatch:=ActivePatch;
end;

procedure TExpanedplatesDialog.ViewportMouseUp(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   if (not FAllowPanOrZoom) and (Viewport.Zoom=1.0) then Viewport.ZoomExtents;
   FAllowPanOrZoom:=True;
end;

procedure TExpanedplatesDialog.RotateCCW90Execute(Sender: TObject);
begin
   if ActivePatch<>nil then begin
      ActivePatch.Rotation:=ActivePatch.Rotation+90;
      Edit1.Text:=FloatToDec(ActivePatch.Rotation,3);
      if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
   end;
end;

procedure TExpanedplatesDialog.RotateCCW5Execute(Sender: TObject);
begin
   if ActivePatch<>nil then begin
      ActivePatch.Rotation:=ActivePatch.Rotation+5;
      Edit1.Text:=FloatToDec(ActivePatch.Rotation,3);
      if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
   end;
end;

procedure TExpanedplatesDialog.RotateCW5Execute(Sender: TObject);
begin
   if ActivePatch<>nil then begin
      ActivePatch.Rotation:=ActivePatch.Rotation-5;
      Edit1.Text:=FloatToDec(ActivePatch.Rotation,3);
      if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
   end;
end;

procedure TExpanedplatesDialog.RotateCW90Execute(Sender: TObject);
begin
   if ActivePatch<>nil then begin
      ActivePatch.Rotation:=ActivePatch.Rotation-90;
      Edit1.Text:=FloatToDec(ActivePatch.Rotation,3);
      if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
   end;
end;

procedure TExpanedplatesDialog.ZoomExtentsExecute(Sender: TObject);
begin
   Viewport.ZoomExtents;
end;

procedure TExpanedplatesDialog.SaveBitmapExecute(Sender: TObject);
var Str:string;
begin
   Str:=FShip.Preferences.ExportDirectory;
   if Str[Length(Str)]<>'\' then Str:=Str+'\';
   Str:=Str+ChangeFileExt(ExtractFilename(Fship.FileName),'')+'_developments.png';
   Viewport.SaveAsBitmap(Str);
end;

procedure TExpanedplatesDialog.ZoomInExecute(Sender: TObject);
    begin Viewport.ZoomIn; end;
procedure TExpanedplatesDialog.ZoomOutExecute(Sender: TObject);
    begin Viewport.ZoomOut; end;

procedure TExpanedplatesDialog.RotateCCW1Execute(Sender: TObject);
begin
   if ActivePatch<>nil then begin
      ActivePatch.Rotation:=ActivePatch.Rotation+1;
      Edit1.Text:=FloatToDec(ActivePatch.Rotation,3);
      if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
   end;
end;

procedure TExpanedplatesDialog.RotateCW1Execute(Sender: TObject);
begin
   if ActivePatch<>nil then begin
      ActivePatch.Rotation:=ActivePatch.Rotation-1;
      Edit1.Text:=FloatToDec(ActivePatch.Rotation,3);
      if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                           else Viewport.Refresh;
   end;
end;

procedure TExpanedplatesDialog.ExportDXFExecute(Sender: TObject);
var I          : Integer;
    Strings    : TStringList;
    Patch      : TDevelopedPatch;
    SaveDialog : TSaveDialog;
    Str        : string;
begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Fship.Preferences.ExportDirectory;
   Str:=ChangeFileExt(ExtractFilename(Fship.FileName),'');
   Str:=Str+'_developments.dxf';
   SaveDialog.FileName:=Str;
   SaveDialog.Filter:='AutoCad dxf files [*.dxf]|*.dxf';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      FShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      Strings:=TStringlist.Create;
      Strings.Add('0'+EOL+'SECTION');
      Strings.Add('2'+EOL+'ENTITIES');
      for I:=1 to FPlates.Count do begin
         Patch:=FPlates[I-1];
         if Patch.Visible then Patch.SaveToDXF(Strings);
      end;
      Strings.Add('0'+EOL+'ENDSEC');
      Strings.Add('0'+EOL+'EOF');
      Strings.SaveToFile(ChangeFileExt(SaveDialog.FileName,'.dxf'));
      Strings.Destroy;
   end;
   SaveDialog.Destroy;
end;

procedure TExpanedplatesDialog.ShowStationsExecute(Sender: TObject);
begin
   ShowStations.Checked:=not ShowStations.Checked;
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.ShowButtocksExecute(Sender: TObject);
begin
   ShowButtocks.Checked:=not ShowButtocks.Checked;
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.ShowWaterlinesExecute(Sender: TObject);
begin
   ShowWaterlines.Checked:=not ShowWaterlines.Checked;
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.ShowInteriorEdgesExecute(Sender: TObject);
begin
   ShowInteriorEdges.Checked:=not ShowInteriorEdges.Checked;
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.ShowFillColorExecute(Sender: TObject);
begin
   ShowFillColor.Checked:=not ShowFillColor.Checked;
   ShowSubmergedArea.Enabled:=ShowFillColor.Checked;
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.ToolButton22Click(Sender: TObject);
begin
   Close;
end;

procedure TExpanedplatesDialog.ShowErrorEdgesExecute(Sender: TObject);
begin
   ShowErrorEdges.Checked:=not ShowErrorEdges.Checked;
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.ShowDiagonalsExecute(Sender: TObject);
begin
   ShowDiagonals.Checked:=not ShowDiagonals.Checked;
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.ShowDimensionsExecute(Sender: TObject);
begin
   ShowDimensions.Checked:=not ShowDimensions.Checked;
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.Edit2KeyPress(Sender: TObject;var Key: Char);
begin
   if Key in [#8,'1'..'9','0','-','+',#13,'.'] then else key:=#0;
   if Key=#13 then Edit2Exit(self);
end;

procedure TExpanedplatesDialog.Edit2Exit(Sender: TObject);
var Value:Real;
begin
   if Edit2.Text='' then Value:=FXGridSpacing
                    else Value:=StrToFloat(Edit2.Text);
   FXGridSpacing:=Value;
   Edit2.Text:=FloatToDec(FXGridSpacing,3);
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.Edit3KeyPress(Sender: TObject;var Key: Char);
begin
   if Key in [#8,'1'..'9','0','-','+',#13,'.'] then else key:=#0;
   if Key=#13 then Edit3Exit(self);
end;

procedure TExpanedplatesDialog.Edit3Exit(Sender: TObject);
var Value:Real;
begin
   if Edit3.Text='' then Value:=FYGridSpacing
                    else Value:=StrToFloat(Edit3.Text);
   FYGridSpacing:=Value;
   Edit3.Text:=FloatToDec(FYGridSpacing,3);
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.Edit1KeyPress(Sender: TObject;var Key: Char);
begin
   if Key in [#8,'1'..'9','0','-','+',#13,'.'] then else key:=#0;
   if Key=#13 then Edit1Exit(self);
end;

procedure TExpanedplatesDialog.Edit1Exit(Sender: TObject);
var Value:Real;
begin
   if ActivePatch<>nil then begin
      Value:=StrToFloat(Edit1.Text);
      if Value<>ActivePatch.Rotation then begin
         ActivePatch.Rotation:=Value;
         if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                              else Viewport.Refresh;
      end;
   end;
end;

procedure TExpanedplatesDialog.ShowPartNameExecute(Sender: TObject);
begin
   ShowPartName.Checked:=not ShowPartName.Checked;
   Viewport.Refresh;
end;

procedure TExpanedplatesDialog.CheckBox1Click(Sender: TObject);
begin
   if ActivePatch<>nil then begin
      if Checkbox1.Checked<>ActivePatch.MirrorOnScreen then begin
         ActivePatch.MirroronScreen:=Checkbox1.Checked;
         if Viewport.Zoom=1.0 then Viewport.ZoomExtents
                              else Viewport.Refresh;
      end;
   end;
end;

procedure TExpanedplatesDialog.ShowSubmergedAreaExecute(Sender: TObject);
begin
   ShowSubmergedArea.Checked:=not ShowSubmergedarea.Checked;
   Viewport.Refresh;;
end;

procedure TExpanedplatesDialog.ExportTextFileExecute(Sender: TObject);
var I          : Integer;
    Strings    : TStringList;
    Patch      : TDevelopedPatch;
    SaveDialog : TSaveDialog;
    Str        : string;
begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Fship.Preferences.ExportDirectory;
   Str:=ChangeFileExt(ExtractFilename(Fship.FileName),'');
   Str:=Str+'_developments.txt';
   SaveDialog.FileName:=Str;
   SaveDialog.Filter:='Coordinates to text file [*.txt]|*.txt';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then begin
      FShip.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
      Strings:=TStringlist.Create;
      for I:=1 to FPlates.Count do begin
         Patch:=FPlates[I-1];
         if Patch.Visible then Patch.SaveToTextFile(Strings);
      end;
      Strings.SaveToFile(ChangeFileExt(SaveDialog.FileName,'.txt'));
      Strings.Destroy;
   end;
   SaveDialog.Destroy;
end;

end.
