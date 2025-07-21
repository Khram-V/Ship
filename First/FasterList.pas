
unit FasterList;
interface //uses math;
type
{ TFasterlist is an improved version of Delphi's standard TList object.        }
{ It is stripped of unneccesary code to improve speed.                         }
{ Additionally the contents (pointers) can be sorted so that the time needed   }
{ to search an item has been redced with a factor 2^n                          }
{ Use the SORT          method to sort the list                                }
{ Use the SORTEDINDEXOF function to perform a binary search in the sorted list }
TFasterList = class
private
   FCount,FCapacity: Integer;
   FSorted,FUseUserData: Boolean;
   FList,FData: array of Pointer;      // Pointers to any user specified object
   function FGet(Index: Integer): Pointer;
   function FGetObject(Index: Integer): Pointer;
   procedure FSet(Index: Integer; Item: Pointer);
   procedure FSetObject( Index: integer; UserObject: Pointer );
   procedure FSetCapacity(NewCapacity: Integer);
public
   constructor Create;
   destructor Destroy; override;
   procedure Clear; virtual;
   procedure Add(Item:Pointer);
   procedure AddList(List:TFasterList);
   procedure AddObject(Item,UserObject: Pointer);
   procedure AddSorted(Item:Pointer);
   procedure AddSortedObject(Item,UserObject:Pointer);
   procedure Assign(List:TFasterList);
   procedure Delete(Index: Integer);
   procedure Exchange(Index1, Index2: Integer);
   function  IndexOf(Item: Pointer): Integer;                               // normal TList function
   procedure Insert(Index: Integer; Item: Pointer);
   procedure Sort;
   function SortedIndexOf(Item: Pointer): Integer;
   property Capacity             : Integer read FCapacity write FSetCapacity;
   property Count                : Integer read FCount;
   property Items[Index:Integer] : Pointer read FGet write FSet; default;
   property Objects[Index:Integer] : Pointer read FGetObject write FSetObject;
end;

implementation
constructor TFasterList.Create;
begin Inherited Create; FList:=nil; FCount:=0;
                        FData:=nil; FCapacity:=0; FSorted:=False; end;
procedure TFasterList.Clear;
   begin FCount:=0; FSorted:=False; FUseUserData:=False; end;
destructor TFasterList.Destroy;
   begin Clear;
     if FCapacity>0 then begin SetLength( FList,0 );
        if FUseUserData then SetLength( FData,0 );
     end; inherited Destroy;
   end;
procedure TFasterList.Assign( List:TFasterList );
begin
   FUseUserdata:=List.FUseUserData;
   if List.Count>FCapacity then Capacity:=List.Count;
                        Move(List.FList[0],FList[0],List.Count*SizeOf(Pointer));
   if FUseUserdata then Move(List.FData[0],FData[0],List.Count*SizeOf(Pointer));
   FCount:=List.Count;
   FSorted:=List.FSorted;
end;
procedure TFasterList.FSet(Index: Integer; Item: Pointer);
begin
   FList[Index]:=Item;
   if FUseUserData then FData[index]:=nil;
end;
procedure TFasterList.FSetObject( Index: integer; UserObject: Pointer );
begin
  if Index<0 then Index:=0 else if Index>=FCount then Index:=FCount-1;
  if not FUseUserdata then
     begin Setlength( FData,FCapacity ); FUseUserdata:=True; end;
  FData[Index]:=UserObject;
end;
procedure TFasterList.FSetCapacity( NewCapacity: integer );
begin if FCapacity<=NewCapacity then
   begin FCapacity:=NewCapacity+16; SetLength( FList,FCapacity );
      if FUseUserData then SetLength( FData,FCapacity );
   end;
end;
procedure TFasterList.Delete(Index: Integer);
begin
   Dec(FCount);
   if Index<FCount then begin
      Move(FList[Index+1],FList[Index],(FCount-Index)*SizeOf(Pointer));
      if FUseUserData then Move(FData[Index+1],FData[Index],(FCount-Index)*SizeOf(Pointer));
   end;
end;

procedure TFasterList.Exchange(Index1, Index2: Integer);
var Item: Pointer;
begin
   Item:=FList[Index1];
   FList[Index1]:=FList[Index2];
   FList[Index2]:=Item;
   if FUseUserData then begin
      Item:=FData[Index1];
      FData[Index1]:=FData[Index2];
      FData[Index2]:=Item;
   end;
   if FSorted then FSorted:=False;
end;

procedure TFasterList.Add( Item: Pointer ); var Cur,Prev:Cardinal;
begin
   if FCount>=FCapacity then Capacity:=FCount+32; // FGrow;
   FList[FCount]:=Item;
   if FUseUserData then FData[FCount]:=nil;
   if FCount<=1 then FSorted:=True else if FSorted then begin
      Prev:=Cardinal(FList[FCount-1]);
      Cur:=Cardinal(Item);
      FSorted:=Prev<Cur;
   end;
   Inc(FCount);
end;

procedure TFasterList.AddObject(Item,UserObject: Pointer);
var Cur,Prev:Cardinal;
begin
   if FCount>=FCapacity then Capacity:=FCount+32; // FGrow;
   if not FUseUserdata then begin
      Setlength(FData,FCapacity);
      FUseUserdata:=True;
   end;
   FList[FCount]:=Item;
   FData[FCount]:=UserObject;
   if FCount<=1 then FSorted:=True else if FSorted then begin
      Prev:=Cardinal(FList[FCount-1]);
      Cur:=Cardinal(Item);
      FSorted:=Prev<Cur;
   end;
   Inc(FCount);
end;

procedure TFasterList.AddList(List:TFasterList);
var NewCap:Integer;
begin
   NewCap:=FCount+List.FCount;
   FUseUserData:=FUseUserData or List.FUseUserData;
   if NewCap>FCapacity then begin Capacity:=NewCap;
      Setlength( FList,FCapacity );
      if FUseUserData then Setlength(FData,FCapacity);
   end;
   Move(List.FList[0],FList[FCount],List.FCount*SizeOf(Pointer));
   if FUseUserData then Move(List.FData[0],FData[FCount],List.FCount*SizeOf(Pointer));
   FSorted:=False;
   Inc(FCount,List.FCount);
end;

procedure TFasterList.AddSorted(Item:Pointer);
var Address : Cardinal;
    L,H,Mid : Integer;
begin
   if FCount>=FCapacity then Capacity:=FCount+32; // FGrow;
   if FCount=0 then begin
      FList[FCount]:=Item;
      if FUseUserData then FData[FCount]:=nil;
      Inc(FCount);
   end else begin
      Address:=Cardinal(Item);                 // check start
      if Address<Cardinal(FList[0]) then begin // insert at start
         Move(FList[0],FList[1],FCount*SizeOf(Pointer));
         FList[0]:=Item;
         if FUseUserData then begin
            Move(FData[0],FData[1],FCount*SizeOf(Pointer));
            FData[0]:=nil;
         end;
      end else if Address>Cardinal(FList[FCount-1]) then begin    // add at end
         FList[FCount]:=Item;
         if FUseUserdata then FData[FCount]:=nil;
      end else begin      // perform binary search to quickly find the location
         L:=0;
         H:=FCount-1;
         while H-L>1 do begin
            Mid:=(L+H) div 2;
            if Address<Cardinal(FList[Mid]) then H:=Mid-1
                                            else L:=Mid+1;
         end;
         if Address<cardinal(FList[L]) then Mid:=L else
            if Address<cardinal(FList[H]) then Mid:=H else Mid:=H+1;
         Move(FList[Mid],FList[Mid+1],(FCount-Mid)*4);
         FList[Mid]:=Item;
         if FUseUserdata then begin
            Move(FData[Mid],FData[Mid+1],(FCount-Mid)*4);
            FData[Mid]:=nil;
         end;
      end;
      Inc(FCount);
   end;
end;

procedure TFasterList.AddSortedObject(Item,UserObject:Pointer);
var Address : Cardinal;
    L,H,Mid : Integer;
begin
   if not FUseUserData then begin
      FUseUserData:=True;
      Setlength( FData,FCapacity );
   end;
   if FCount>=FCapacity then Capacity:=FCount+32; // FGrow;
   if FCount=0 then begin
      FList[FCount]:=Item;
      if FUseUserData then FData[FCount]:=UserObject;
      Inc(FCount);
   end else begin
      Address:=Cardinal(Item);                 // check start
      if Address<Cardinal(FList[0]) then begin // insert at start
         Move(FList[0],FList[1],FCount*SizeOf(Pointer));
         FList[0]:=Item;
         if FUseUserData then begin
            Move(FData[0],FData[1],FCount*SizeOf(Pointer));
            FData[0]:=UserObject;
         end;
      end else if Address>Cardinal(FList[FCount-1]) then begin // add at end
         FList[FCount]:=Item;
         if FUseUserdata then FData[FCount]:=UserObject;
      end else begin      // perform binary search to quickly find the location
         L:=0;
         H:=FCount-1;
         while H-L>1 do begin Mid:=(L+H) div 2;
            if Address<Cardinal(FList[Mid]) then H:=Mid-1
                                            else L:=Mid+1;
         end;
         if Address<cardinal(FList[L]) then Mid:=L else
            if Address<cardinal(FList[H]) then Mid:=H else Mid:=H+1;
         Move(FList[Mid],FList[Mid+1],(FCount-Mid)*4);
         FList[Mid]:=Item;
         if FUseUserdata then begin
            Move(FData[Mid],FData[Mid+1],(FCount-Mid)*4);
            FData[Mid]:=UserObject;
         end;
      end;
      Inc(FCount);
   end;
end;

function TFasterList.FGet(Index: Integer): Pointer;
begin
   if (Index>=0) and (Index<FCount) then Result:=FList[Index]
                                    else Result:=nil;
end;

function TFasterList.FGetObject(Index: Integer): Pointer;
begin
  if (Index>=0) and (Index<FCount) and (FUseUserData) then Result:=FData[Index]
                                                      else Result:=nil;
end;

function TFasterList.IndexOf(Item: Pointer): Integer;
var I : Integer;
begin
   Result:=-1;
   for I:=1 to FCount do if FList[I-1]=Item then begin
      Result:=I-1;
      break;
   end;
end;

procedure TFasterList.Insert( Index: Integer; Item: Pointer );
begin
   if FCount>=FCapacity then Capacity:=FCount+32; // FGrow;
   if Index<FCount then begin
      Move(FList[Index],FList[Index + 1],(FCount-Index)*4);
      if FUseUserData then Move(FData[Index],FData[Index + 1],(FCount-Index)*4);
   end;
   FList[Index]:=Item;
   if FUseUserData then FData[index]:=nil;
   if FSorted then FSorted:=False;
   Inc(FCount);
end;

procedure TFasterList.Sort;
   procedure QuickSort(L,R:Integer);
   var I,J : Integer;
       Val : Cardinal;
       Procedure Swap(I,J:Integer);
       var Tmp : Pointer;
       begin                         Tmp:=FList[I]; FList[I]:=FList[J]; FList[J]:=Tmp;
          if FUseUserdata then begin Tmp:=FData[I]; FData[I]:=FData[J]; FData[J]:=Tmp; end;
       end;
   begin
      I:=L;
      J:=R;
      Val:=Cardinal(FList[(L+R) div 2]);
      repeat
         While Cardinal(FList[I])<Val do Inc(I);
         while Val<Cardinal(FList[J]) do Dec(J);
         if I<=J then begin Swap(I,J); Inc(I); Dec(J); end;
      Until I>J;
      if L<J then QuickSort(L,J);
      if I<R then QuickSort(I,R);
   end;{QuickSort}

begin
   if (FCount>1) then {and not (FSorted) then} begin
      QuickSort(0,FCount-1);
      FSorted:=True;
   end;
end;

function TFasterList.SortedIndexOf(Item: Pointer): Integer;
var MemAddr,MidVal: Cardinal;
    L,H,Mid : Integer;
begin
   Result:=-1;
   MemAddr:=Cardinal(Item);
   L:=0;
   H:=FCount-1;
   while L<=H do begin
      Mid:=(L+H) div 2;
      MidVal:=Cardinal(FList[Mid]);
      if MemAddr=MidVal then begin Result:=Mid; exit; end else
      if MemAddr<MidVal then H:=Mid-1
                        else L:=Mid+1;
   end;
end;

end.
(*
function TFasterList.FGetMemory:Integer;
begin Result:=4+           // self        : pointer
              4+           // FCapacity   : integer
              4+           // fcount      : integer
              1+ 3+        // FSorted     : Boolean
              1+ 3+        // FUseUserdata: boolean
              4*FCapacity; // c выравниванием по словам в 4 байта
   if FUseUserData then inc( Result,4*FCapacity );
end;
 *
procedure TFasterList.FGrow;
var Delta : Integer;
begin
  if FCapacity>64 then begin
     Delta:=FCapacity div 4;
     if Delta>1000 then Delta:=1000;
  end else
     if FCapacity>8 then Delta:=16 else Delta:=4;
  FSetCapacity(FCapacity + Delta);
end;
*)

