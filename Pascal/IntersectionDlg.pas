
unit IntersectionDlg;
interface uses
     SysUtils, Classes,
     Forms,    Controls,
     ExtCtrls, Dialogs,
     CheckLst, ComCtrls,
     ActnList, Geometry,ShipUnit,STypes;
type
  TIntersectionDialog = class(TForm)
     MenuImages: TImageList;
     ActionList1: TActionList;
     Panel1: TPanel;
     ListBox: TCheckListBox;
     ToolBar1: TToolBar;
     TB1,TB2,TB3,TB4,TB5,TB6, TB7,TB13,TB14,TB21: TToolButton;
     ViewStations,ViewButtocks,ViewWaterlines,ViewDiagonals,
     CloseDialog,AddOne,AddRange,DeleteAll: TAction;
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
     St: TShip;
     procedure FillBox;
  public
     procedure Execute( Ship:TShip );
     procedure UpdateMenu;
end;

var IntersectionDialog: TIntersectionDialog;

implementation uses LanguageSupport;
{$R *.lfm}

procedure TIntersectionDialog.UpdateMenu;
begin
   if ViewStations.Checked then begin
//      AddOne.Hint:=Userstring(223)+'.';
//      AddRange.Hint:=Userstring(224)+'.';
//      DeleteAll.Hint:=Userstring(225)+'.';
      DeleteAll.Enabled:=St.NoStations>0;
   end else if ViewButtocks.Checked then begin
//      AddOne.Hint:=Userstring(226)+'.';
//      AddRange.Hint:=Userstring(227)+'.';
//      DeleteAll.Hint:=Userstring(228)+'.';
      DeleteAll.Enabled:=St.NoButtocks>0;
   end else if ViewWaterlines.Checked then begin
//      AddOne.Hint:=Userstring(229)+'.';
//      AddRange.Hint:=Userstring(230)+'.';
//      DeleteAll.Hint:=Userstring(231)+'.';
      DeleteAll.Enabled:=St.NoWaterlines>0;
   end else if ViewDiagonals.Checked then begin
//      AddOne.Hint:=Userstring(232)+'.';
//      AddRange.Hint:=Userstring(233)+'.';
//      DeleteAll.Hint:=Userstring(234)+'.';
      DeleteAll.Enabled:=St.NoDiagonals>0;
   end;
end;

procedure TIntersectionDialog.FillBox;
var I,Ind   : Integer;
    PrevInd : Integer;
begin
   PrevInd:=ListBox.ItemIndex;
   ListBox.Items.BeginUpdate;
   ListBox.Clear;
   if ViewStations.Checked then begin                 // Fill box with stations
      for I:=1 to St.NoStations do begin
         Ind:=ListBox.Items.AddObject(St.Station[I-1].Description,St.Station[I-1]);
         ListBox.Checked[Ind]:=St.Station[I-1].ShowCurvature;
      end;
   end else if ViewButtocks.Checked then begin        // Fill box with buttocks
      for I:=1 to St.NoButtocks do begin
         Ind:=ListBox.Items.AddObject(St.Buttock[I-1].Description,St.Buttock[I-1]);
         ListBox.Checked[Ind]:=St.Buttock[I-1].ShowCurvature;
      end;
   end else if ViewWaterlines.Checked then begin    // Fill box with waterlines
      for I:=1 to St.NoWaterlines do begin
         Ind:=ListBox.Items.AddObject(St.Waterline[I-1].Description,St.Waterline[I-1]);
         ListBox.Checked[Ind]:=St.Waterline[I-1].ShowCurvature;
     end;
   end else begin                                    // Fill box with diagonals
      for I:=1 to St.NoDiagonals do begin
         Ind:=ListBox.Items.AddObject(St.Diagonal[I-1].Description,St.Diagonal[I-1]);
         ListBox.Checked[Ind]:=St.Diagonal[I-1].ShowCurvature;
      end;
   end;
   ListBox.Items.EndUpdate;
   if (PrevInd>=0) and (PrevInd<ListBox.Count) then ListBox.ItemIndex:=PrevInd;
end;

procedure TIntersectionDialog.Execute( Ship:TShip );
    begin St:=Ship;
          FillBox;
          UpdateMenu;
          ShowModal;
end;

procedure TIntersectionDialog.ListBoxKeyDown
( Sender: TObject; var Key: Word; Shift: TShiftState );
var Intersection: TIntersection; Index: Integer;
begin
   if Key=46 then begin          // Delete the currently selected intersection
      Index:=ListBox.ItemIndex;
      if Index<>-1 then begin
         Intersection:=Listbox.Items.Objects[Index] as TIntersection;
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

procedure TIntersectionDialog.ListBoxClick(Sender: TObject);
var Intersection: TIntersection; I: Integer;
begin
   if ListBox.ItemIndex<>-1 then begin
      Intersection:=ListBox.Items.Objects[ListBox.ItemIndex] as TIntersection;
      if Intersection.ShowCurvature<>ListBox.Checked[ListBox.ItemIndex] then begin
         Intersection.ShowCurvature:=ListBox.Checked[ListBox.ItemIndex];
         St.FileChanged:=true;
         if St.Visibility.ShowCurvature then
           for I:=1 to St.nV do
             if St.Viewport[I-1].Viewportmode=vmWireframe then
                St.Viewport[I-1].Refresh;
      end;
   end;
end;

procedure TIntersectionDialog.ViewStationsExecute(Sender: TObject);
begin
   ViewStations.Checked:=True;
   ViewButtocks.Checked:=False;
   ViewWaterlines.Checked:=False;
   ViewDiagonals.Checked:=False;
   UpdateMenu;
   FillBox;
end;

procedure TIntersectionDialog.ViewButtocksExecute(Sender: TObject);
begin
   ViewStations.Checked:=False;
   ViewButtocks.Checked:=True;
   ViewWaterlines.Checked:=False;
   ViewDiagonals.Checked:=False;
   UpdateMenu;
   FillBox;
end;

procedure TIntersectionDialog.ViewWaterlinesExecute(Sender: TObject);
begin
   ViewStations.Checked:=False;
   ViewButtocks.Checked:=False;
   ViewWaterlines.Checked:=True;
   ViewDiagonals.Checked:=False;
   UpdateMenu;
   FillBox;
end;

procedure TIntersectionDialog.ViewDiagonalsExecute(Sender: TObject);
begin
   ViewStations.Checked:=False;
   ViewButtocks.Checked:=False;
   ViewWaterlines.Checked:=False;
   ViewDiagonals.Checked:=True;
   FillBox;
end;

procedure TIntersectionDialog.CloseDialogExecute(Sender: TObject);
    begin Close; end;

procedure TIntersectionDialog.AddOneExecute(Sender: TObject);
var Str: String; Int: TIntersection;
begin Str:='1.0';
   if InputQuery(Userstring(235),Userstring(236)+':',Str) then begin Int:=nil;
      if ViewStations.Checked then Int:=St.Edit.Intersection_Add(fiStation,StrToFloat(Str));
      if ViewButtocks.Checked then Int:=St.Edit.Intersection_Add(fiButtock,StrToFloat(Str));
      if ViewWaterlines.Checked then Int:=St.Edit.Intersection_Add(fiWaterline,StrToFloat(Str));
      if ViewDiagonals.Checked then Int:=St.Edit.Intersection_Add(fiDiagonal,StrToFloat(Str));
      if Int<>nil then FillBox;            // Added and sorted, refill the list
      UpdateMenu;
   end;
end;

procedure TIntersectionDialog.AddRangeExecute( Sender: TObject );
var Str: String; Min,Max: Vector; Start,Stop,Step: Real; Index: Integer;
begin Str:='1.0';
   if not InputQuery(Userstring(237),Userstring(236)+':',Str) then exit;
   Step:=abs( StrToFloat(Str) );
   if abs(Step)<1e-3 then exit;
   St.Extents(Min,Max);
   if ViewStations.Checked   then begin Start:=Min.X; Stop:=Max.X; end else
   if ViewButtocks.Checked   then begin Start:=0.0;   Stop:=Max.Y; end else
   if ViewWaterlines.Checked then begin Start:=Min.Z; Stop:=Max.Z; end else
   if ViewDiagonals.Checked  then begin Start:=Min.Z; Stop:=2*Max.Z; end else
                                  begin Start:=0.0; Stop:=-0.01; end;
   Index:=Trunc((Start/step)-2);
   Start:=Index*Step;
   while Start<=Stop do begin
      if ViewStations.Checked   then St.Edit.Intersection_Add(fiStation,Start);
      if ViewButtocks.Checked   then St.Edit.Intersection_Add(fiButtock,Start);
      if ViewWaterlines.Checked then St.Edit.Intersection_Add(fiWaterline,Start);
      if ViewDiagonals.Checked  then St.Edit.Intersection_Add(fidiagonal,Start);
      Start+=Step;
   end;
   St.Redraw;
   UpdateMenu;
   FillBox;
end;

procedure TIntersectionDialog.DeleteAllExecute(Sender: TObject);
  var I: Integer;
begin with St do begin
   if ViewStations.Checked then begin
      for I:=NoStations downto 1 do Station[I-1].Delete(I=1); FillBox;
   end else if ViewButtocks.Checked then begin
      for I:=NoButtocks downto 1 do Buttock[I-1].Delete(I=1); FillBox;
   end else if ViewWaterlines.Checked then begin
      for I:=NoWaterlines downto 1 do Waterline[I-1].Delete(I=1); FillBox;
   end else if ViewDiagonals.Checked then begin
      for I:=NoDiagonals downto 1 do Diagonal[I-1].Delete(I=1); FillBox;
   end;
   UpdateMenu;
end end;

end.
