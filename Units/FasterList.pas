{$MODE ObjFPC}{$H+}
{---------------------------------------------------}
{                                       TFasterList }
{---------------------------------------------------}
unit FasterList;
interface
type
  generic TFasterList<TItemType> = class
  private
    FCount,FCapacity: integer;
    FUseUserData: boolean;
    FList: array of TItemType;
    FData: array of Pointer;         // TItemTypes to any user specified object
    function FGet( Index: integer ): TItemType;
    function FGetObject( Index: integer ): Pointer;
    procedure FSet( Index: integer; Item: TItemType );
    procedure FSetObject( Index: integer; UserObject: Pointer );
    procedure FSetCapacity( NewCapacity: integer );
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddList( List: TFasterList );
    procedure Assign( List: TFasterList );
    procedure Clear; virtual;
    procedure Delete( Index: integer );
    procedure DeleteItem(Item:TItemType);   //deletes all instances of the item
                                 //deletes all instances of the aList from Self
    procedure DeleteList( const aList: TFasterList );
    procedure Insert( Index: integer; Item: TItemType );
    procedure Exchange( Index1, Index2: integer );

    procedure Add(Item: TItemType);
    procedure AddObject(Item: TItemType; UserObject: Pointer);   //TODO: specialize UserObject
    function IndexOf(Item: TItemType): integer;        // normal TList function
    property Count: integer read FCount;
    property Items[Index: integer]: TItemType read FGet write FSet; default;
    property Capacity: integer read FCapacity write FSetCapacity;
    property Objects[Index: integer]: Pointer read FGetObject write FSetObject;
  end;

implementation

constructor TFasterList.Create;
begin inherited Create; FList:=nil; FCount:=0;
                        FData:=nil; FCapacity:=0;
end;
destructor TFasterList.Destroy; begin Clear; inherited Destroy; end;
procedure TFasterList.Clear;
begin //FSetCapacity( 0 );
      FCount:=0; FUseUserData:=False; // leave it as created
end;
procedure TFasterList.AddList( List:TFasterList ); var NewCap: Integer;
begin if List.FCount=0 then exit;
   NewCap:=FCount+List.FCount;
   FUseUserData:=FUseUserData or List.FUseUserData;
   if NewCap>FCapacity then begin FCapacity:=NewCap;
     if FUseUserData then Setlength( FData,FCapacity );
                          Setlength( FList,FCapacity );
   end;
   if FUseUserData then
      Move( List.FData[0],FData[FCount],List.FCount*SizeOf( Pointer ) );
      Move( List.FList[0],FList[FCount],List.FCount*SizeOf( TItemType ) ); // FSorted:=False;
   Inc( FCount,List.FCount );
end;
procedure TFasterList.Add( Item: TItemType );
begin if FCount>=FCapacity then FSetCapacity( FCount+256 );
  FList[FCount]:=Item; if FUseUserData then FData[FCount]:=nil; Inc( FCount );
end;
procedure TFasterList.AddObject( Item: TItemType; UserObject: Pointer );
begin if not FUseUserData then
         begin SetLength( FData,FCapacity ); FUseUserdata:=True; end;
      if FCount>=FCapacity then FSetCapacity( FCount+256 );             // FGrow;
      FList[FCount]:=Item;
      FData[FCount]:=UserObject; Inc(FCount);
end;

procedure TFasterList.FSetCapacity( NewCapacity: integer );
begin if FCapacity<NewCapacity then begin FCapacity:=NewCapacity;
         if FUseUserData then Setlength( FData,FCapacity );
                              Setlength( FList,FCapacity ); end;
   // if FCapacity<=FCount then FCount:=Fcapacity;
end;

procedure TFasterList.Assign( List: TFasterList );
begin FUseUserdata:=List.FUseUserData; FCount:=List.Count;
      FSetCapacity( FCount );
      Move( List.FList[0],FList[0],FCount*SizeOf( TItemType ) );
      if FUseUserdata then
         Move( List.FData[0],FData[0],FCount*SizeOf( Pointer ) );

end;

procedure TFasterList.Delete( Index: Integer );
begin
  if (FCount<=0) or (Index<0) or (Index>=FCount) then exit;
//  if Index<0 then Index:=0 else
//  if Index>=FCount then Index:=FCount-1;
  Dec( FCount );
  if Index<FCount then begin
    Move( FList[Index+1],FList[Index],(FCount-Index)*SizeOf(TItemType) );
    if FUseUserData then
      Move( FData[Index+1],FData[Index],(FCount-Index)*SizeOf(Pointer) );
  end;
end;

procedure TFasterList.DeleteItem( Item: TItemType ); var I: integer;
begin repeat I:=IndexOf( Item ); if I>=0 then Delete( I ); until I=-1;
// I:=IndexOf(Item); while I>=0 do begin Delete( I ); I:=IndexOf(Item); end;
end;
procedure TFasterList.DeleteList( const aList: TFasterList ); var I: integer;
begin for I:=0 to aList.Count-1 do DeleteItem( aList[I] );
end;
procedure TFasterList.Exchange( Index1,Index2: integer );
var vItem: TItemType; vData:Pointer;
begin
  vItem:=FList[Index1]; FList[Index1]:=FList[Index2]; FList[Index2]:=vItem;
  if FUseUserData then begin
     vData:=FData[Index1]; FData[Index1]:=FData[Index2]; FData[Index2]:=vData;
  end;
end;
function TFasterList.FGet( Index: integer ): TItemType;
begin
  if (Index>=0) and (Index<FCount) then Result:=FList[Index] else Result:=nil;
end;
function TFasterList.FGetObject( Index: integer ): Pointer;
begin
  if (Index>=0) and (Index<FCount) and (FUseUserData) then Result:=FData[Index]
  else Result:=nil;
end;
function TFasterList.IndexOf( Item: TItemType ): integer; var I: integer;
begin Result:=-1;
  for I:=0 to FCount-1 do if FList[I]=Item then begin Result:=I; break; end;
end;
procedure TFasterList.Insert( Index: Integer; Item: TItemType );
begin
  if Index<0 then Index:=0 else
  if Index>FCount then Index:=FCount;
  if FCount>=FCapacity then FSetCapacity( FCount+256  );
  if Index<FCount then begin
    Move( FList[Index],FList[Index+1],(FCount-Index)*SizeOf(TItemType) );
    if FUseUserData then
      Move( FData[Index],FData[Index+1],(FCount-Index)*SizeOf(Pointer) );
  end;
  FList[Index]:=Item;
  if FUseUserData then FData[index]:=nil; Inc( FCount );
end;

procedure TFasterList.FSet( Index: integer; Item: TItemType );
begin
  if Index<0 then Index:=0 else if Index>=FCount then Index:=FCount-1;
  //  begin Index:=FCount; Inc( FCount ); FSetCapacity( FCount ); end;
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

end.

// function FGetMemory: integer;   // property Memory: integer read FGetMemory;
// procedure FGrow;
{
function TFasterList.FGetMemory: integer;
begin
  Result:=SizeOf(Pointer)+    // self        : TItemType
     SizeOf(integer) +        // FCapacity   : integer
     SizeOf(integer) +        // fcount      : integer
     SizeOf(boolean) +        // FSorted     : Boolean
     SizeOf(boolean) +        // FUseUserdata: boolean
     SizeOf(TItemType)*FCapacity;
  if FUseUserData then Inc( Result,FCapacity*SizeOf(Pointer) );
end;
procedure TFasterList.FGrow;
  var Delta: integer;
begin
  if FCapacity>64 then begin Delta:=FCapacity div SizeOf( TItemType );
                             if Delta>1024 then Delta:=1024; end else
  if FCapacity>8 then Delta:=16 else Delta:=4;
  FSetCapacity( FCapacity+Delta );
end;
procedure TFasterList.AddList( List: TFasterList ); var NewCap: integer;
begin if List.FCount=0 then exit;
  NewCap:=FCount+List.FCount;
  if (not FUseUserData) and (List.FUseUserData) then
    if NewCap>FCapacity then Setlength( FData,NewCap )
                        else Setlength( FData,FCapacity );
  FUseUserData:=FUseUserData or List.FUseUserData;
  if NewCap>FCapacity then begin FCapacity:=NewCap;
                                 Setlength( FList,FCapacity );
         // if FUseUserData then Setlength( FData,FCapacity );
  end;
  Move( List.FList[0],FList[FCount],List.FCount*SizeOf(TItemType) );
  if FUseUserData then
     Move( List.FData[0],FData[FCount],List.FCount*SizeOf(Pointer) );
  Inc( FCount,List.FCount );
end;
}

