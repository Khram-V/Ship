unit MethodList;                              // simple not sorted generic list
{$mode objfpc}{$H+}
interface                          // TItemType can be procedure of object type
type generic TMethodList<TItemType>=class  // double pointer, like TNotifyEvent
private
  FCount,FCapacity: integer;                 // длина и зарезервированный объём
  FList: array of TItemType;                 // собственно сам список элементов
  function FGet( Index:integer ): TItemType; // заграничные точки с обнулением
  function IndexOf( Item: TItemType ): integer;        // normal TList function
  procedure Add( Item: TItemType );
public
  constructor Create;
  destructor Destroy; override;
  procedure DeleteItem( Item: TItemType ); // deletes all instances of the item
  property Count: integer read FCount;
  property Items[Index: integer]: TItemType read FGet; default;
end;

implementation
constructor TMethodList.Create;
  begin inherited Create; FList:=nil; FCount:=0; FCapacity:=0; end;
destructor TMethodList.Destroy;
  begin FCount:=0; FCapacity:=0; SetLength( FList,0 ); inherited Destroy; end;

function TMethodList.FGet( Index: integer ): TItemType;
  begin if (Index>=0) and (Index<FCount) then Result:=FList[Index]
                                         else Result:=nil;
  end;
procedure TMethodList.Add( Item: TItemType );
  begin if FCount=FCapacity then begin                                 //FGrow;
           FCapacity+=256; Setlength( FList,FCapacity ); end;
        FList[FCount]:=Item; Inc( FCount );
  end;
procedure TMethodList.DeleteItem( Item: TItemType ); var I: integer;
begin   I:=IndexOf( Item );
  while I>=0 do begin Dec( FCount );                             //Delete( I );
    if I<FCount then Move( FList[I+1],FList[I],(FCount-I)*SizeOf( TItemType ) );
    I:=IndexOf( Item );
  end;
end;
function TMethodList.IndexOf( Item: TItemType ): integer;
  var I: integer;
begin Result:=-1;
  for I:=0 to FCount-1 do if FList[I]=Item then begin Result:=I; break; end;
end;

end.

