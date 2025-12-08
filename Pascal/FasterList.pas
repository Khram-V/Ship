unit FasterList;
interface //uses math;
type
{ TFasterlist is an improved version of Delphi's standard TList object.
  It is stripped of unneccesary code to improve speed.
  Additionally the contents (pointers) can be sorted so that the time needed
  to search an item has been redced with a factor 2^n
  Use the SORT method to sort the list
  Use the SORTEDINDEXOF function to perform a binary search in the sorted list
}
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
   procedure Assign( List:TFasterList );
   procedure Add(Item:Pointer);
   procedure AddObject(Item,UserObject: Pointer);
   procedure AddList(List:TFasterList);
   procedure AddSorted(Item:Pointer);
   procedure AddSortedObject( Item,UserObject:Pointer );
   procedure Exchange( Index1,Index2: Integer );
   procedure Delete(Index: Integer);
   procedure Insert(Index: Integer; Item: Pointer);
   Procedure Swap( I,J: Integer );
   procedure Sort;
   function IndexOf(Item: Pointer): Integer;           // normal TList function
   function SortedIndexOf(Item: Pointer): Integer;
   property Count: Integer read FCount;
   property Capacity: Integer read FCapacity write FSetCapacity;
   property Items[Index:Integer]: Pointer read FGet write FSet; default;
   property Objects[Index:Integer]: Pointer read FGetObject write FSetObject;
end;

implementation
constructor TFasterList.Create;
   begin Inherited Create; FList:=nil; FCount:=0;
                           FData:=nil; FCapacity:=0; FSorted:=False; end;
destructor TFasterList.Destroy;
   begin Clear;
     if FCapacity>0 then SetLength( FList,0 ); FList:=nil; FCapacity:=0;
      if FData<>nil then SetLength( FData,0 ); FData:=nil; inherited Destroy;
   end;
procedure TFasterList.FSetCapacity( NewCapacity: integer );
    begin if FCapacity<=NewCapacity+256 then begin
             FCapacity:=NewCapacity+512; SetLength( FList,FCapacity );
                    if FUseUserData then SetLength( FData,FCapacity );
          end else if FUseUserData then
                   if FData=nil then SetLength( FData,FCapacity );
    end;
procedure TFasterList.Clear;
   begin FCount:=0; FSorted:=False; FUseUserData:=False; // SetLength( FData,0 );
   end;
procedure TFasterList.FSet( Index: Integer; Item: Pointer );
   begin FList[Index]:=Item; if FUseUserData then FData[index]:=nil;
   end;
procedure TFasterList.FSetObject( Index: integer; UserObject: Pointer );
    begin if not FUseUserdata then
             begin Setlength( FData,FCapacity ); FUseUserdata:=True; end;
          FData[Index]:=UserObject;
    end;
procedure TFasterList.Delete( Index: Integer );
begin Dec(FCount);
   if Index<FCount then begin
      Move(FList[Index+1],FList[Index],(FCount-Index)*SizeOf(Pointer));
      if FUseUserData then
         Move(FData[Index+1],FData[Index],(FCount-Index)*SizeOf(Pointer));
   end;
end;
procedure TFasterList.Assign( List:TFasterList );
begin
   FUseUserdata:=List.FUseUserData;
   Capacity:=List.Count;
   Move( List.FList[0],FList[0],List.Count*SizeOf(Pointer) );
   if FUseUserdata then Move( List.FData[0],FData[0],List.Count*SizeOf(Pointer) );
   FCount:=List.Count;
   FSorted:=List.FSorted;
end;
procedure TFasterList.Add( Item: Pointer ); var Cur,Prev: Pointer;
begin Capacity:=FCount;
   FList[FCount]:=Item;
   if FUseUserData then FData[FCount]:=nil;
   if FCount<=1 then FSorted:=True else if FSorted then begin
      Prev:=FList[FCount-1];
      Cur:=Item;
      FSorted:=Prev<Cur;
   end;
   Inc(FCount);
end;
procedure TFasterList.AddObject( Item,UserObject: Pointer );
  var Cur,Prev:Pointer;
begin Capacity:=FCount; {+256}
   if not FUseUserdata then begin Setlength( FData,FCapacity );
                                  FUseUserdata:=True; end;
   FList[FCount]:=Item;
   FData[FCount]:=UserObject;
   if FCount<=1 then FSorted:=True else if FSorted then
      begin Prev:=FList[FCount-1]; Cur:=Item; FSorted:=Prev<Cur; end;
   Inc(FCount);
end;
procedure TFasterList.AddList( List:TFasterList );
var NewCap:Integer;
begin
   NewCap:=FCount+List.FCount;
   FUseUserData:=FUseUserData or List.FUseUserData;
   if NewCap>FCapacity then begin
      FCapacity:=NewCap;
      Setlength( FList,FCapacity );
      if FUseUserData then Setlength( FData,FCapacity );
   end;
                        Move(List.FList[0],FList[FCount],List.FCount*SizeOf(Pointer));
   if FUseUserData then Move(List.FData[0],FData[FCount],List.FCount*SizeOf(Pointer));
   FSorted:=False;
   Inc(FCount,List.FCount);
end;
procedure TFasterList.AddSorted( Item:Pointer );
var Address: Pointer; L,H,Mid: Integer;
begin Capacity:=FCount; {+256}
   if FCount=0 then begin
      FList[FCount]:=Item;
      if FUseUserData then FData[FCount]:=nil;
      Inc(FCount);
   end else begin
      Address:=Item;                                             // check start
      if Address<FList[0] then begin                         // insert at start
         Move(FList[0],FList[1],FCount*SizeOf(Pointer));
         FList[0]:=Item;
         if FUseUserData then begin
            Move(FData[0],FData[1],FCount*SizeOf(Pointer));
            FData[0]:=nil;
         end;
      end else if Address>FList[FCount-1] then begin    // add at end
         FList[FCount]:=Item;
         if FUseUserdata then FData[FCount]:=nil;
      end else begin      // perform binary search to quickly find the location
         L:=0;
         H:=FCount-1;
         while H-L>1 do begin
            Mid:=(L+H) div 2;
            if Address<FList[Mid] then H:=Mid-1
                                  else L:=Mid+1;
         end;
         if Address<FList[L] then Mid:=L else
         if Address<FList[H] then Mid:=H else Mid:=H+1;
         Move(FList[Mid],FList[Mid+1],(FCount-Mid)*SizeOf(Pointer));
         FList[Mid]:=Item;
         if FUseUserdata then begin
            Move(FData[Mid],FData[Mid+1],(FCount-Mid)*SizeOf(Pointer));
            FData[Mid]:=nil;
         end;
      end;  Inc(FCount);
   end;
end;
procedure TFasterList.AddSortedObject( Item,UserObject:Pointer );
var Address: Pointer;
    L,H,Mid: Integer;
begin Capacity:=FCount; {+256}
   if not FUseUserData then begin
      FUseUserData:=True;
      Setlength( FData,FCapacity );
   end;
   if FCount=0 then begin
      FList[FCount]:=Item;
      if FUseUserData then FData[FCount]:=UserObject;
      Inc(FCount);
   end else begin Address:=Item;                             // check start
      if Address<FList[0] then begin                         // insert at start
         Move(FList[0],FList[1],FCount*SizeOf(Pointer));
         FList[0]:=Item;
         if FUseUserData then begin
            Move(FData[0],FData[1],FCount*SizeOf(Pointer));
            FData[0]:=UserObject;
         end;
      end else if Address>FList[FCount-1] then begin              // add at end
         FList[FCount]:=Item;
         if FUseUserdata then FData[FCount]:=UserObject;
      end else begin      // perform binary search to quickly find the location
         L:=0;
         H:=FCount-1;
         while H-L>1 do begin Mid:=1+(L+H) div 2;     // Mid:=Floor(0.5*(L+H));
            if Address<FList[Mid] then H:=Mid-1
                                  else L:=Mid+1;
         end;
         if Address<FList[L] then Mid:=L else
         if Address<FList[H] then Mid:=H else Mid:=H+1;
         Move(FList[Mid],FList[Mid+1],(FCount-Mid)*SizeOf(Pointer));
         FList[Mid]:=Item;
         if FUseUserdata then begin
            Move(FData[Mid],FData[Mid+1],(FCount-Mid)*SizeOf(Pointer));
            FData[Mid]:=UserObject;
         end;
      end; Inc(FCount);
   end;
end;
procedure TFasterList.Exchange( Index1,Index2: Integer);
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
function TFasterList.FGet(Index: Integer): Pointer;
begin if (Index>=0) and (Index<FCount) then Result:=FList[Index]
                                       else Result:=nil;
end;
function TFasterList.FGetObject(Index: Integer): Pointer;
begin
  if (Index>=0) and (Index<FCount) and (FUseUserData) then Result:=FData[Index]
                                                      else Result:=nil;
end;
function TFasterList.IndexOf( Item: Pointer ): Integer; var I: Integer;
begin Result:=-1;
   for I:=1 to FCount do if FList[I-1]=Item then begin Result:=I-1; break; end;
end;
procedure TFasterList.Insert( Index: Integer; Item: Pointer );
begin Capacity:=FCount; {+256}
   if Index<FCount then begin
      Move(FList[Index],FList[Index + 1],(FCount-Index)*SizeOf(Pointer));
      if FUseUserData then Move(FData[Index],FData[Index + 1],(FCount-Index)*SizeOf(Pointer));
   end;
   FList[Index]:=Item;
   if FUseUserData then FData[index]:=nil;
   if FSorted then FSorted:=False;
   Inc(FCount);
end;
Procedure TFasterList.Swap( I,J: Integer ); var Tmp: Pointer;
begin Tmp:=FList[I]; FList[I]:=FList[J]; FList[J]:=Tmp;
  if FUseUserdata then
     begin Tmp:=FData[I]; FData[I]:=FData[J]; FData[J]:=Tmp; end;
end;
procedure TFasterList.Sort;
   procedure QuickSort( L,R:Integer );
   var I,J: Integer; Val: Pointer;
   begin I:=L; J:=R; Val:=FList[(L+R) div 2];
      repeat
         While FList[I]<Val do Inc(I);
         while Val<FList[J] do Dec(J);
         if I<=J then begin Swap(I,J); Inc(I); Dec(J); end;
      Until I>J;
      if L<J then QuickSort( L,J );
      if I<R then QuickSort( I,R );
   end;
begin
   if FCount>1 then {and not (FSorted) then}
      begin QuickSort( 0,FCount-1 ); FSorted:=True; end;
end;
function TFasterList.SortedIndexOf( Item: Pointer ): Integer;
var MemAddr,MidVal: Pointer; L,H,Mid: Integer;
begin
   Result:=-1; MemAddr:=Item; L:=0; H:=FCount-1;
   while L<=H do begin
      Mid:=(L+H) div 2;
      MidVal:=FList[Mid];
      if MemAddr=MidVal then begin Result:=Mid; exit; end else
      if MemAddr<MidVal then H:=Mid-1
                        else L:=Mid+1;
   end;
end;
end.
