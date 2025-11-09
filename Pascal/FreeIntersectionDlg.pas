
unit FreeIntersectionDlg;
interface

uses SysUtils, Classes,
     Forms,    Controls,
     ExtCtrls, Dialogs,
     CheckLst, ComCtrls,
     ActnList, FreeGeometry,FreeShipUnit,FreeTypes;
type
  TFreeIntersectionDialog = class(TForm)
     Panel1: TPanel;
     ListBox: TCheckListBox;
     ToolBar1: TToolBar;
     ToolButton1,ToolButton2,ToolButton3,ToolButton4,ToolButton5,ToolButton6,
     ToolButton7,ToolButton13,ToolButton14,ToolButton21: TToolButton;
     MenuImages: TImageList;
     ActionList1: TActionList;
     ViewStations: TAction;
     ViewButtocks: TAction;
     ViewWaterlines: TAction;
     ViewDiagonals: TAction;
     CloseDialog: TAction;
     AddOne: TAction;
     AddRange: TAction;
     DeleteAll: TAction;
     procedure ListBoxKeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
     procedure ListBoxClick(Sender: TObject);
     procedure ViewStationsExecute(Sender: TObject);
     procedure ViewButtocksExecute(Sender: TObject);
     procedure ViewWaterlinesExecute(Sender: TObject);
     procedure ViewDiagonalsExecute(Sender: TObject);
     procedure CloseDialogExecute(Sender: TObject);
     procedure AddOneExecute(Sender: TObject);
     procedure AddRangeExecute(Sender: TObject);
     procedure DeleteAllExecute(Sender: TObject);
  private
     FFreeShip:TFreeShip;
     procedure FillBox;
  public
     procedure Execute(FreeShip:TFreeShip);
     procedure UpdateMenu;
end;

var FreeIntersectionDialog: TFreeIntersectionDialog;

implementation

uses FreeLanguageSupport;
{$R *.lfm}

procedure TFreeIntersectionDialog.UpdateMenu;
begin
   if ViewStations.Checked then begin
//      AddOne.Hint:=Userstring(223)+'.';
//      AddRange.Hint:=Userstring(224)+'.';
//      DeleteAll.Hint:=Userstring(225)+'.';
      DeleteAll.Enabled:=FFreeship.NumberofStations>0;
   end else if ViewButtocks.Checked then begin
//      AddOne.Hint:=Userstring(226)+'.';
//      AddRange.Hint:=Userstring(227)+'.';
//      DeleteAll.Hint:=Userstring(228)+'.';
      DeleteAll.Enabled:=FFreeship.NumberofButtocks>0;
   end else if ViewWaterlines.Checked then begin
//      AddOne.Hint:=Userstring(229)+'.';
//      AddRange.Hint:=Userstring(230)+'.';
//      DeleteAll.Hint:=Userstring(231)+'.';
      DeleteAll.Enabled:=FFreeship.NumberofWaterlines>0;
   end else if ViewDiagonals.Checked then begin
//      AddOne.Hint:=Userstring(232)+'.';
//      AddRange.Hint:=Userstring(233)+'.';
//      DeleteAll.Hint:=Userstring(234)+'.';
      DeleteAll.Enabled:=FFreeship.NumberofDiagonals>0;
   end;
end;

procedure TFreeIntersectionDialog.FillBox;
var I,Ind   : Integer;
    PrevInd : Integer;
begin
   PrevInd:=ListBox.ItemIndex;
   ListBox.Items.BeginUpdate;
   ListBox.Clear;
   if ViewStations.Checked then begin                 // Fill box with stations
      for I:=1 to FFreeShip.NumberofStations do begin
         Ind:=ListBox.Items.AddObject(FFreeship.Station[I-1].Description,FFreeship.Station[I-1]);
         ListBox.Checked[Ind]:=FFreeship.Station[I-1].ShowCurvature;
      end;
   end else if ViewButtocks.Checked then begin        // Fill box with buttocks
      for I:=1 to FFreeShip.NumberofButtocks do begin
         Ind:=ListBox.Items.AddObject(FFreeship.Buttock[I-1].Description,FFreeship.Buttock[I-1]);
         ListBox.Checked[Ind]:=FFreeship.Buttock[I-1].ShowCurvature;
      end;
   end else if ViewWaterlines.Checked then begin    // Fill box with waterlines
      for I:=1 to FFreeShip.NumberofWaterlines do begin
         Ind:=ListBox.Items.AddObject(FFreeship.Waterline[I-1].Description,FFreeship.Waterline[I-1]);
         ListBox.Checked[Ind]:=FFreeship.Waterline[I-1].ShowCurvature;
     end;
   end else begin                                    // Fill box with diagonals
      for I:=1 to FFreeShip.NumberofDiagonals do begin
         Ind:=ListBox.Items.AddObject(FFreeship.Diagonal[I-1].Description,FFreeship.Diagonal[I-1]);
         ListBox.Checked[Ind]:=FFreeship.Diagonal[I-1].ShowCurvature;
      end;
   end;
   ListBox.Items.EndUpdate;
   if (PrevInd>=0) and (PrevInd<ListBox.Count) then ListBox.ItemIndex:=PrevInd;
end;

procedure TFreeIntersectionDialog.Execute(FreeShip:TFreeShip);
begin
   FFreeShip:=FreeShip;
   FillBox;
   UpdateMenu;
   ShowModal;
end;

procedure TFreeIntersectionDialog.ListBoxKeyDown
( Sender: TObject; var Key: Word; Shift: TShiftState );
var Intersection: TFreeIntersection;
    Index: Integer;
begin
   if Key=46 then begin          // Delete the currently selected intersection
      Index:=ListBox.ItemIndex;
      if Index<>-1 then begin
         Intersection:=Listbox.Items.Objects[Index] as TFreeIntersection;
         if Intersection<>nil then begin
            Intersection.Delete(True);
            ListBox.Items.BeginUpdate;
            ListBox.Items.Delete(Index);
            dec(Index);
            if Index<0 then Index:=0;
            if Index>Listbox.Count-1 then Index:=Listbox.Count-1;
            Listbox.ItemIndex:=index;
            ListBox.Items.EndUpdate;
         end;
      end;
   end;
end;

procedure TFreeIntersectionDialog.ListBoxClick(Sender: TObject);
var Intersection : TFreeIntersection;
    I            : Integer;
begin
   if ListBox.ItemIndex<>-1 then begin
      Intersection:=ListBox.Items.Objects[ListBox.ItemIndex] as TFreeIntersection;
      if Intersection.ShowCurvature<>ListBox.Checked[ListBox.ItemIndex]
      then begin
         Intersection.ShowCurvature:=ListBox.Checked[ListBox.ItemIndex];
         FFreeShip.FileChanged:=true;
         if FFreeship.Visibility.ShowCurvature then
           for I:=1 to FFreeship.NumberOfViewports do
             if FFreeship.Viewport[I-1].Viewportmode=vmWireframe then
                FFreeship.Viewport[I-1].Refresh;
      end;
   end;
end;

procedure TFreeIntersectionDialog.ViewStationsExecute(Sender: TObject);
begin
   ViewStations.Checked:=True;
   ViewButtocks.Checked:=False;
   ViewWaterlines.Checked:=False;
   ViewDiagonals.Checked:=False;
   UpdateMenu;
   FillBox;
end;

procedure TFreeIntersectionDialog.ViewButtocksExecute(Sender: TObject);
begin
   ViewStations.Checked:=False;
   ViewButtocks.Checked:=True;
   ViewWaterlines.Checked:=False;
   ViewDiagonals.Checked:=False;
   UpdateMenu;
   FillBox;
end;

procedure TFreeIntersectionDialog.ViewWaterlinesExecute(Sender: TObject);
begin
   ViewStations.Checked:=False;
   ViewButtocks.Checked:=False;
   ViewWaterlines.Checked:=True;
   ViewDiagonals.Checked:=False;
   UpdateMenu;
   FillBox;
end;

procedure TFreeIntersectionDialog.ViewDiagonalsExecute(Sender: TObject);
begin
   ViewStations.Checked:=False;
   ViewButtocks.Checked:=False;
   ViewWaterlines.Checked:=False;
   ViewDiagonals.Checked:=True;
   FillBox;
end;

procedure TFreeIntersectionDialog.CloseDialogExecute(Sender: TObject);
begin
   Close;
end;

procedure TFreeIntersectionDialog.AddOneExecute(Sender: TObject);
var Str: String;
    Int: TFreeIntersection;
begin
   Str:='1.0';
   if InputQuery(Userstring(235),Userstring(236)+':',Str) then begin
      Int:=nil;
      if ViewStations.Checked then Int:=FFreeShip.Edit.Intersection_Add(fiStation,StrToFloat(Str));
      if ViewButtocks.Checked then Int:=FFreeShip.Edit.Intersection_Add(fiButtock,StrToFloat(Str));
      if ViewWaterlines.Checked then Int:=FFreeShip.Edit.Intersection_Add(fiWaterline,StrToFloat(Str));
      if ViewDiagonals.Checked then Int:=FFreeShip.Edit.Intersection_Add(fiDiagonal,StrToFloat(Str));
      if Int<>nil then  begin              // Added and sorted, refill the list
         FillBox;
      end;
      UpdateMenu;
   end;
end;

procedure TFreeIntersectionDialog.AddRangeExecute(Sender: TObject);
var Str        : String;
    Min,Max    : T3DVector;
    Start,Stop : TFloatType;
    Step       : TFloatType;
    Index      : Integer;
begin
   Str:='1.0';
   if not InputQuery(Userstring(237),Userstring(236)+':',Str) then exit;
   Step:=abs(StrToFloat(Str));
   if abs(Step)<1e-3 then exit;
   FFreeShip.Extents(Min,Max);
   if ViewStations.Checked then begin
      Start:=Min.X;
      Stop:=Max.X;
   end else if ViewButtocks.Checked then begin
      Start:=0.0;
      Stop:=Max.Y;
   end else if ViewWaterlines.Checked then begin
      Start:=Min.Z;
      Stop:=Max.Z;
   end else if ViewDiagonals.Checked then begin
      Start:=Min.Z;
      Stop:=2*Max.Z;
   end else begin
      Start:=0.0;
      Stop:=-0.01;
   end;
   Index:=Trunc((Start/step)-2);
   Start:=Index*Step;
   while Start<=Stop do begin
      if ViewStations.Checked then FFreeShip.Edit.Intersection_Add(fiStation,Start);
      if ViewButtocks.Checked then FFreeShip.Edit.Intersection_Add(fiButtock,Start);
      if ViewWaterlines.Checked then FFreeShip.Edit.Intersection_Add(fiWaterline,Start);
      if ViewDiagonals.Checked then FFreeShip.Edit.Intersection_Add(fidiagonal,Start);
      Start:=Start+step;
   end;
   FFreeShip.Redraw;
   UpdateMenu;
   FillBox;
end;

procedure TFreeIntersectionDialog.DeleteAllExecute(Sender: TObject);
var I : Integer;
begin
   if ViewStations.Checked then begin
      for I:=FFreeShip.NumberofStations downto 1 do FFreeship.Station[I-1].Delete(I=1);
      FillBox;
   end else if ViewButtocks.Checked then begin
      for I:=FFreeShip.NumberofButtocks downto 1 do FFreeship.Buttock[I-1].Delete(I=1);
      FillBox;
   end else if ViewWaterlines.Checked then begin
      for I:=FFreeShip.NumberofWaterlines downto 1 do FFreeship.Waterline[I-1].Delete(I=1);
      FillBox;
   end else if ViewDiagonals.Checked then begin
      for I:=FFreeShip.NumberofDiagonals downto 1 do FFreeship.Diagonal[I-1].Delete(I=1);
      FillBox;
   end;
   UpdateMenu;
end;

end.
