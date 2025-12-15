unit VRMLUnit;
interface uses
     LazFileUtils,Classes,SysUtils,Dialogs,
     Graphics,STypes,Geometry,FasterList;
type 
TIntArray = array of integer;
TVRMLFileType = (ftVRML1,ftVRML2);
TVRMLList = class;
TVRMLCoordinate3 = class;
TVRMLIndexedFaceSet = class;
TVRMLobject = class
private
   FOwner:TVRMLList;
public
   constructor Create(Owner:TVRMLList); virtual;
   procedure Clear; virtual;
   destructor Destroy;override;
   procedure Load(var LineNr:Integer;Strings:TStringList);virtual;
end;
TVRMLSeparator = class(TVRMLobject)
private
   FObjects: TFasterList;
   function FGetCount:Integer;
   function FGetItems(Index:Integer):TVRMLObject;
public
   procedure Add(VRMLObject:TVRMLObject);
   constructor Create(Owner:TVRMLList);override;
   procedure Clear;override;
   destructor Destroy;override;
   procedure Load(var LineNr:Integer;Strings:TStringList);override;
   property Count: Integer read FGetCount;
   property Items[index:Integer]: TVRMLObject read FGetItems;
end;
TVRMLCoordinate3 = class(TVRMLobject)
private
   FCapacity,FCount: Integer;
   FFaceSets: TFasterList;
   FCoordinates: VectorArray;
   function FGetNoFacesets:Integer;
   function FGetPoint(Index:INteger):Vector;
   procedure FSetCapacity(val:Integer);
public
   procedure Add( P:Vector );
   procedure AddFaceSet(FaceSet:TVRMLIndexedFaceSet);
   procedure Clear;override;
   constructor Create(Owner:TVRMLList);override;
   destructor Destroy;override;
   procedure Load(var LineNr:Integer;Strings:TStringList);override;
   property Count: Integer read FCount;
   property Capacity: Integer read FCapacity write FSetCapacity;
   property NoFaceSets: Integer read FGetNoFacesets;
   property Point[index:Integer]: Vector read FGetPoint;
end;
TVRMLIndexedFaceSet = class(TVRMLobject)
private
   FCapacity,FCount: Integer;
   FFaces: array of TIntArray;
   FCoordinates: TVRMLCoordinate3;
   function FGetFace(Index:Integer):TIntArray;
   procedure FSetCapacity(val:Integer);
public
   procedure Clear;override;
   procedure Load(var LineNr:Integer;Strings:TStringList);override;
   property Coordinates: TVRMLCoordinate3 read FCoordinates;
   property Count   : Integer read FCount;
   property Capacity: Integer read FCapacity write FSetCapacity;
   property Face[index:Integer]: TIntArray read FGetFace;
end;
TVRMLList = class
private
   FObjects: TFasterList;
   FFaceSets: TFasterList;
   FFileType: TVRMLFileType;
   FLastAddedCoordinates: TVRMLCoordinate3;
   function FGetCount:integer;
   function FGetItems(Index:Integer):TVRMLObject;
public
   procedure Add(VRMLObject:TVRMLObject);
   procedure Clear;
   constructor Create;
   destructor Destroy;override;
   function ExtractFaceSetData:TFasterList;
   procedure LoadFromFile(Filename:String);
   property Count: Integer read FGetCount;
   property Items[index:Integer]: TVRMLObject read FGetItems;
end;

implementation Uses LanguageSupport;

procedure ProcessString( Input: ansistring; var output: TStringList );
 var Tmp: TStringArray; I: integer;
begin OutPut.Clear; if InPut='' then exit; Tmp:=BlankOff(Input).Split([' ']);
      for I:=0 to Length(Tmp)-1 do if Tmp[I]<>'' then OutPut.Add(Tmp[I]);
end;

procedure LoadNextObject
( strings: TStringList;
  var LineNr,NoObjects: integer;
  var Objectname: AnsiString;
  Dest: TStringList );
var Index,Level,L: integer; Tmp,Str: AnsiString; Ch:char; Done: boolean;
begin
  Str:=''; Dest.Clear; Level:=0; Done:=False; Objectname:='';
  NoObjects:=0;
  while (LineNr<Strings.Count) and (not Done) do begin
    Index:=1; Tmp:=Strings[LineNr]; L:=Length(Tmp);
    while Index<=L do begin Ch:=Tmp[index];
      if (Level=0) and (Ch<>'{') then begin
        if Ch=#32 then begin
          if Objectname<>'' then ObjectName:=ObjectName+ch;
        end else Objectname:=Objectname+Ch;  //and (Ch<>#32) then Objectname:=Objectname+Ch;
      end;
      if ch='[' then begin if level<>0 then Str:=Str+Ch; Inc(level); end else
      if Ch=']' then begin Dec(Level); if Level=0 then begin Done:=True; break; end else Str:=Str+Ch; end else
      if Ch='{' then begin Inc(NoObjects); if Level<>0 then Str:=Str+Ch; Inc(Level); end else
      if Ch='}' then begin Dec(Level); if Level=0 then begin Done:=True; break; end else Str:=Str+Ch; end else
      if Level<>0 then Str:=Str+Ch;
      Inc( Index );
    end;
    if Str<>'' then begin Dest.Add( Str ); Str:=''; end;
    if Done then begin Delete( Tmp,1,Index );
      if Tmp='' then begin Inc( LineNr ); end
                else begin Strings[ LineNr ]:=Tmp; end;
    end else begin
      if level=0 then
      if objectname<>'' then
      if Objectname[length(Objectname)]<>#32 then objectname:=objectname+#32;
      Inc(LineNr);
    end;
  end;
  Objectname:=Trim( Objectname );
  if not Done then begin
     Done:=(Objectname='') and (Dest.Count=0);
     if NoObjects=0 then Done:=True;
     if not done then WriteLn( Userstring(115) );
  end;
end;

procedure GetEmbeddedObjects(Source:TStringlist;Dest:TStringList);
var ToDo: TList;
    I,Line,NObj: Integer;
    Current,OutPut: TStringList;
    ObjName : string;
begin
   ToDo:=TList.Create;
   ToDo.Add(Source); I:=1;
   while I<=ToDo.Count do begin Current:=ToDo[I-1]; Line:=0;
      While Line<Current.Count do begin OutPut:=TStringlist.Create;
         LoadNextObject( Current,Line,NObj,ObjName,Output );
         if NObj>1 then ToDo.Add(Output)
                   else Dest.AddObject(ObjName,Output);
      end; inc(I);
   end; ToDo.Destroy;
end;

// VRML base object
constructor TVRMLobject.Create(Owner:TVRMLList);
      begin inherited Create; FOwner:=Owner; clear; end;
procedure TVRMLobject.Clear; begin end;
destructor TVRMLobject.Destroy;
     begin {Clear;} inherited Destroy; end;
procedure TVRMLobject.Load(var LineNr:Integer;Strings:TStringList); begin end;

// VRML Separator
function TVRMLSeparator.FGetCount:Integer;
   begin Result:=FObjects.Count; end;
function TVRMLSeparator.FGetItems(Index:Integer):TVRMLObject;
   begin Result:=FObjects[index]; end;

procedure TVRMLSeparator.Add(VRMLObject:TVRMLObject);
begin FObjects.Add(VRMLObject);
   if VRMLObject is TVRMLCoordinate3 then begin
      FOwner.FLastAddedCoordinates:=VRMLObject as TVRMLCoordinate3;
   end else begin
      if VRMLObject is TVRMLIndexedFaceSet then begin
         FOwner.FFaceSets.Add(VRMLObject as TVRMLIndexedFaceSet);
         if FOwner.FLastAddedCoordinates<>nil 
         then FOwner.FLastAddedCoordinates.AddFaceSet(VRMLObject as TVRMLIndexedFaceSet);
      end;
   end;
end;

constructor TVRMLSeparator.Create(Owner:TVRMLList);
      begin FObjects:=TFasterList.Create; Inherited Create(Owner); end;
procedure TVRMLSeparator.Clear; var I:Integer;
begin for I:=0 to Count-1 do Items[I].Destroy; FObjects.Clear; inherited clear;
end;
destructor TVRMLSeparator.Destroy;
     begin FreeAndNil( FObjects ); Inherited Destroy; {FObjects.Destroy;} end;

procedure TVRMLSeparator.Load(var LineNr:Integer;Strings:TStringList);
var Words: TStringList;      ObjectName: string;
    VRMLObject: TVRMLObject; Index,NObj: Integer;
begin
   Words:=TStringList.Create;
   While LineNr<Strings.Count do begin
      LoadNextObject( Strings,LineNr,NObj,Objectname,Words ); VRMLObject:=nil;
      if Pos('SEPARATOR',Objectname)<>0 then VRMLObject:=TVRMLSeparator.create(FOwner) else
      if Pos('COORDINATE3',Objectname)<>0 then VRMLObject:=TVRMLCoordinate3.create(FOwner) else
      if Pos('INDEXEDFACESET',Objectname)<>0 then VRMLObject:=TVRMLIndexedFaceSet.Create(FOwner)
      else begin
      { if NObj>1 then begin
            Objects:=TStringList.Create;
            GetEmbeddedObjects(Words,Objects);
            for I:=1 to Objects.Count do begin ObjectName:=Objects[I-1];
               if Pos('INDEXEDFACESET',Objectname)<>0 then begin end;
               Words:=Objects.Objects[I-1] as TStringList;
               Words.destroy;
            end; //Showmessage(Objects.Text);
            Objects.Destroy;
         end; }
      end;
      if VRMLObject<>nil then begin Index:=0;
         VRMLObject.Load( Index,Words );
         Add( VRMLObject );
      end;
   end; words.Destroy;
end;

// # VRML Material #
function TVRMLCoordinate3.FGetNoFacesets:Integer;
   begin Result:=FFaceSets.Count; end;

function TVRMLCoordinate3.FGetPoint(Index:Integer):Vector;
begin
   if (Index>=0) and (Index<FCount) then Result:=FCoordinates[index]
   else begin Result:=ZERO; // ShowMessage('Point index out of bounds in TVRMLCoordinate3.FGetPoint');
   end;
end;
procedure TVRMLCoordinate3.FSetCapacity(val:Integer);
begin FCapacity:=val; Setlength(FCoordinates,FCapacity);
      if FCapacity<FCount then FCount:=FCapacity;
end;
procedure TVRMLCoordinate3.Add(P:Vector);
begin if FCount>=FCapacity then Capacity:=Count+25; inc(FCount);
      FCoordinates[FCount-1]:=P;
end;
procedure TVRMLCoordinate3.AddFaceSet(FaceSet:TVRMLIndexedFaceSet);
begin if FFaceSets.IndexOf(FaceSet)=-1 then begin
         FFaceSets.Add(FaceSet); FaceSet.FCoordinates:=self; end;
end;
procedure TVRMLCoordinate3.Clear;
    begin Capacity:=0; FCount:=0; FFaceSets.Clear; end;
constructor TVRMLCoordinate3.Create(Owner:TVRMLList);
      begin FFaceSets:=TFasterList.Create; Inherited Create(Owner); end;
destructor TVRMLCoordinate3.Destroy;
     begin FreeAndNil(FFaceSets); Inherited Destroy; {FFaceSets.Destroy;} end;

procedure TVRMLCoordinate3.Load(var LineNr: integer; Strings: TStringList);
var Index,S,F,I,L: integer; Ch: char; Data: String; Points: TStringList;
    P: Vector;
begin
  Data:=Strings.Text;
  Index:=Pos('POINT',Data);
  if Index<>0 then begin S:=-1; F:=-1; L:=Length(Data); I:=Index+1;
    while I<=L do begin Ch:=Data[I];
      if (Ch='[') and (S=-1) then S:=I;
      if (Ch=']') and (F=-1) then F:=I;
      if (S<>-1) and (F<>-1) then break; Inc(I);
    end;
    if (S<>-1) and (F<>-1) then begin Points:=TStringList.Create;
      ProcessString( Copy( Data,S+1,F-S-2 ),Points );
      if Points.Count mod 3=0 then begin Capacity:=Points.Count div 3; I:=1;
        while I<=Points.Count do begin
          P.X:=StrtoFloat( Points[I-1] );
          P.Y:=StrtoFloat( Points[I]   );
          P.Z:=StrtoFloat( Points[I+1] ); Add( P ); Inc( I,3 );
        end;
      end; FreeAndNil(Points);
    end;
  end;
end;

// # VRML Indexed face set #
function TVRMLIndexedFaceSet.FGetFace(Index:Integer):TIntArray;
begin
  if (Index>=0) and (Index<FCount) then Result:=FFaces[index] else
  begin Result:=nil;
//     ShowMessage('Face index out of bounds in TVRMLIndexedFaceSet.FGetFace');
  end;
end;
procedure TVRMLIndexedFaceSet.FSetCapacity(val:Integer);
begin FCapacity:=val;
      Setlength(FFaces,FCapacity);
      if FCapacity<FCount then FCount:=FCapacity;
end;
procedure TVRMLIndexedFaceSet.Clear;
    begin Capacity:=0; FCount:=0; FCoordinates:=nil; end;

procedure TVRMLIndexedFaceSet.Load(var LineNr: integer; Strings: TStringList);
var
  Data: AnsiString;
  Index,S,F,I,L,N: integer; Ch:char;
  Faces: TStringList;
  Tmp: array of integer;
begin
  Data:=Strings.Text;
  Index:=Pos('COORDINDEX',Data);
  if Index<>0 then begin S:=-1; F:=-1; L:=Length(Data); I:=Index+1;
    while I<=L do begin Ch:=Data[I];
      if (Ch='[') and (S=-1) then S:=I;
      if (Ch=']') and (F=-1) then F:=I;
      if (S<>-1) and (F<>-1) then break; Inc(I);
    end;
    if (S<>-1) and (F<>-1) then begin
      Faces:=TStringList.Create;
      ProcessString( Copy( Data,S+1,F-S-2 ),Faces );
      Setlength( Tmp,Faces.Count ); N:=0;
      for I:=1 to faces.Count do begin Index:=strtoint( Faces[I-1] );
        if Index=-1 then begin
          if N>2 then begin
            if FCount>=Capacity then Capacity:=FCount+25;
            setlength( FFaces[FCount],N );
            Move( Tmp[0],FFaces[FCount][0],N*SizeOf(integer) ); Inc(FCount);
          end; N:=0;
        end else begin Tmp[N]:=Index; Inc(N); end;
      end; Faces.Destroy;
    end;
  end;
end;

// VRML list

function TVRMLList.FGetCount:integer;
   begin Result:=FObjects.Count; end;
function TVRMLList.FGetItems(Index:Integer):TVRMLObject;
   begin Result:=FObjects[index]; end;

procedure TVRMLList.Add(VRMLObject:TVRMLObject);
begin
   FObjects.Add(VRMLObject);
   if VRMLObject is TVRMLCoordinate3 then begin
      FLastAddedCoordinates:=VRMLObject as TVRMLCoordinate3 end else
   if VRMLObject is TVRMLIndexedFaceSet then begin
      FFaceSets.Add(VRMLObject as TVRMLIndexedFaceSet);
      if FLastAddedCoordinates<>nil then
         FLastAddedCoordinates.AddFaceSet(VRMLObject as TVRMLIndexedFaceSet);
   end;
end;
procedure TVRMLList.Clear; var I:Integer;
begin for I:=0 to Count-1 do Items[I].Destroy;
      FObjects.Clear;
      FFaceSets.Clear;
      FLastAddedCoordinates:=nil;
      FFileType:=ftVRML1;
end;
constructor TVRMLList.Create;
      begin FObjects:=TFasterList.Create;
            FFaceSets:=TFasterList.Create; clear;
end;
destructor TVRMLList.destroy;
     begin Clear; FObjects.Destroy;
                  FFaceSets.Destroy; inherited Destroy;
     end;

function TVRMLList.ExtractFaceSetData:TFasterList;
var I: Integer; FaceSet: TVRMLIndexedFaceSet;
begin Result:=nil;
   if FFaceSets.Count>0 then begin
      Result:=TFasterList.Create;
      Result.Capacity:=FFaceSets.Count;
      for I:=1 to FFaceSets.Count do begin
         FaceSet:=FFacesets[I-1];
         if Faceset.Coordinates<>nil then Result.Add(FaceSet);
      end;
      if Result.Count=0 then begin FreeAndNil(Result); {Result.Destroy;} Result:=nil; end;
   end;
end;

procedure TVRMLList.LoadFromFile(Filename:String);
var Strings,Words : TStringList;
    LineNr,I,J,Index,NObj: Integer;
    Str,ObjectName: string;
    FFile         : TextFile;
    VRMLObject    : TVRMLObject;
    ValidFile     : Boolean;
begin
   if FileExistsUTF8( Filename ) then begin
      Clear;
      Strings:=TStringList.Create;
      AssignFile(FFile,FileName);
      Reset(FFile);
      ValidFile:=False;
      if not EOF(FFile) then begin
         Readln(FFile,Str); // First line, must contain the string: "#VRML V1.0 ascii"
         Str:=Uppercase(Str);
         if pos('#VRML V1.0 ASCII',Str)<>0 then begin
            FFileType:=ftVRML1; ValidFile:=true;
         end else if pos('#VRML V2.0 UTF8',Str)<>0 then begin
            FFileType:=ftVRML2;
         end;
      end;
      if not ValidFile then begin
         ShowMessage(Userstring(208)+'!');
         CloseFile(FFile);
         Strings.Destroy;
         exit;
      end;
      while not EOF(FFile) do begin                 //  ... поехали
        Readln( FFile,Str );                        // Read(FFile,Str);
        I:=Str.IndexOf( '#' );                      // remove comments
        if I>0 then SetLength( Str,I-1 );
        if Length( Str )>0 then begin
          Str:=BlankOff( Str.Replace( ',',' ' ).RePlace( #9,' ' ) );
          if Length( Str )>0 then Strings.Add( Uppercase( Str ) ); end;
      end;
      CloseFile(FFile);
      if Strings.Count>0 then begin LineNr:=0;
         Words:=TStringList.Create;
         While LineNr<Strings.Count do begin
            LoadNextObject(Strings,LineNr,NObj,Objectname,Words);
            VRMLObject:=nil;
            if Pos('SEPARATOR',Objectname)<>0 then VRMLObject:=TVRMLSeparator.create(self) else
            if Pos('COORDINATE3',Objectname)<>0 then VRMLObject:=TVRMLCoordinate3.create(self) else
            if pos('INDEXEDFACESET',Objectname)<>0 then VRMLObject:=TVRMLIndexedFaceSet.Create(self);
            if VRMLObject<>nil then begin Index:=0;
               VRMLObject.Load(Index,Words);
               Add(VRMLObject);
            end;
         end; words.Destroy;

      end else ShowMessage(Userstring(208)+'!');
      Strings.destroy;
   end;
end;

end.
