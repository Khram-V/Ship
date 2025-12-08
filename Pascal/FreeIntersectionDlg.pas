
unit FreeIntersectionDlg;
interface uses
     SysUtils, Classes,
     Forms,    Controls,
     ExtCtrls, Dialogs,
     CheckLst, ComCtrls,
     ActnList, FreeGeometry,FreeShipUnit,FreeTypes;
type
  TFreeIntersectionDialog = class(TForm)
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
     Ship: TFreeShip;
     procedure FillBox;
  public
     procedure Execute( FreeShip:TFreeShip );
     procedure UpdateMenu;
end;

var FreeIntersectionDialog: TFreeIntersectionDialog;

implementation uses FreeLanguageSupport;
{$R *.lfm}

procedure TFreeIntersectionDialog.UpdateMenu;
begin
   if ViewStations.Checked then begin
//      AddOne.Hint:=Userstring(223)+'.';
//      AddRange.Hint:=Userstring(224)+'.';
//      DeleteAll.Hint:=Userstring(225)+'.';
      DeleteAll.Enabled:=Ship.NumberofStations>0;
   end else if ViewButtocks.Checked then begin
//      AddOne.Hint:=Userstring(226)+'.';
//      AddRange.Hint:=Userstring(227)+'.';
//      DeleteAll.Hint:=Userstring(228)+'.';
      DeleteAll.Enabled:=Ship.NumberofButtocks>0;
   end else if ViewWaterlines.Checked then begin
//      AddOne.Hint:=Userstring(229)+'.';
//      AddRange.Hint:=Userstring(230)+'.';
//      DeleteAll.Hint:=Userstring(231)+'.';
      DeleteAll.Enabled:=Ship.NumberofWaterlines>0;
   end else if ViewDiagonals.Checked then begin
//      AddOne.Hint:=Userstring(232)+'.';
//      AddRange.Hint:=Userstring(233)+'.';
//      DeleteAll.Hint:=Userstring(234)+'.';
      DeleteAll.Enabled:=Ship.NumberofDiagonals>0;
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
      for I:=1 to Ship.NumberofStations do begin
         Ind:=ListBox.Items.AddObject(Ship.Station[I-1].Description,Ship.Station[I-1]);
         ListBox.Checked[Ind]:=Ship.Station[I-1].ShowCurvature;
      end;
   end else if ViewButtocks.Checked then begin        // Fill box with buttocks
      for I:=1 to Ship.NumberofButtocks do begin
         Ind:=ListBox.Items.AddObject(Ship.Buttock[I-1].Description,Ship.Buttock[I-1]);
         ListBox.Checked[Ind]:=Ship.Buttock[I-1].ShowCurvature;
      end;
   end else if ViewWaterlines.Checked then begin    // Fill box with waterlines
      for I:=1 to Ship.NumberofWaterlines do begin
         Ind:=ListBox.Items.AddObject(Ship.Waterline[I-1].Description,Ship.Waterline[I-1]);
         ListBox.Checked[Ind]:=Ship.Waterline[I-1].ShowCurvature;
     end;
   end else begin                                    // Fill box with diagonals
      for I:=1 to Ship.NumberofDiagonals do begin
         Ind:=ListBox.Items.AddObject(Ship.Diagonal[I-1].Description,Ship.Diagonal[I-1]);
         ListBox.Checked[Ind]:=Ship.Diagonal[I-1].ShowCurvature;
      end;
   end;
   ListBox.Items.EndUpdate;
   if (PrevInd>=0) and (PrevInd<ListBox.Count) then ListBox.ItemIndex:=PrevInd;
end;

procedure TFreeIntersectionDialog.Execute( FreeShip:TFreeShip );
    begin Ship:=FreeShip;
          FillBox;
          UpdateMenu;
          ShowModal;
end;

procedure TFreeIntersectionDialog.ListBoxKeyDown
( Sender: TObject; var Key: Word; Shift: TShiftState );
var Intersection: TFreeIntersection; Index: Integer;
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
var Intersection: TFreeIntersection; I: Integer;
begin
   if ListBox.ItemIndex<>-1 then begin
      Intersection:=ListBox.Items.Objects[ListBox.ItemIndex] as TFreeIntersection;
      if Intersection.ShowCurvature<>ListBox.Checked[ListBox.ItemIndex] then begin
         Intersection.ShowCurvature:=ListBox.Checked[ListBox.ItemIndex];
         Ship.FileChanged:=true;
         if Ship.Visibility.ShowCurvature then
           for I:=1 to Ship.nV do
             if Ship.Viewport[I-1].Viewportmode=vmWireframe then
                Ship.Viewport[I-1].Refresh;
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
    begin Close; end;

procedure TFreeIntersectionDialog.AddOneExecute(Sender: TObject);
var Str: String; Int: TFreeIntersection;
begin Str:='1.0';
   if InputQuery(Userstring(235),Userstring(236)+':',Str) then begin Int:=nil;
      if ViewStations.Checked then Int:=Ship.Edit.Intersection_Add(fiStation,StrToFloat(Str));
      if ViewButtocks.Checked then Int:=Ship.Edit.Intersection_Add(fiButtock,StrToFloat(Str));
      if ViewWaterlines.Checked then Int:=Ship.Edit.Intersection_Add(fiWaterline,StrToFloat(Str));
      if ViewDiagonals.Checked then Int:=Ship.Edit.Intersection_Add(fiDiagonal,StrToFloat(Str));
      if Int<>nil then FillBox;            // Added and sorted, refill the list
      UpdateMenu;
   end;
end;

procedure TFreeIntersectionDialog.AddRangeExecute( Sender: TObject );
var Str: String; Min,Max: Vector; Start,Stop,Step: Real; Index: Integer;
begin Str:='1.0';
   if not InputQuery(Userstring(237),Userstring(236)+':',Str) then exit;
   Step:=abs( StrToFloat(Str) );
   if abs(Step)<1e-3 then exit;
   Ship.Extents(Min,Max);
   if ViewStations.Checked   then begin Start:=Min.X; Stop:=Max.X; end else
   if ViewButtocks.Checked   then begin Start:=0.0;   Stop:=Max.Y; end else
   if ViewWaterlines.Checked then begin Start:=Min.Z; Stop:=Max.Z; end else
   if ViewDiagonals.Checked  then begin Start:=Min.Z; Stop:=2*Max.Z; end else
                                  begin Start:=0.0; Stop:=-0.01; end;
   Index:=Trunc((Start/step)-2);
   Start:=Index*Step;
   while Start<=Stop do begin
      if ViewStations.Checked   then Ship.Edit.Intersection_Add(fiStation,Start);
      if ViewButtocks.Checked   then Ship.Edit.Intersection_Add(fiButtock,Start);
      if ViewWaterlines.Checked then Ship.Edit.Intersection_Add(fiWaterline,Start);
      if ViewDiagonals.Checked  then Ship.Edit.Intersection_Add(fidiagonal,Start);
      Start+=Step;
   end;
   Ship.Redraw;
   UpdateMenu;
   FillBox;
end;

procedure TFreeIntersectionDialog.DeleteAllExecute(Sender: TObject);
  var I: Integer;
begin with Ship do begin
   if ViewStations.Checked then begin
      for I:=NumberofStations downto 1 do Station[I-1].Delete(I=1); FillBox;
   end else if ViewButtocks.Checked then begin
      for I:=NumberofButtocks downto 1 do Buttock[I-1].Delete(I=1); FillBox;
   end else if ViewWaterlines.Checked then begin
      for I:=NumberofWaterlines downto 1 do Waterline[I-1].Delete(I=1); FillBox;
   end else if ViewDiagonals.Checked then begin
      for I:=NumberofDiagonals downto 1 do Diagonal[I-1].Delete(I=1); FillBox;
   end;
   UpdateMenu;
end end;

end.
