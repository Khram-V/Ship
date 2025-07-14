unit VRMLUnit;
{$MODE ObjFPC}{$H+}

interface
uses
  LazFileUtils,Math,
  Classes,
  SysUtils,
  Dialogs,
  FreeTypes,FreeGeometry,FasterList;

type
  TIntArray = array of integer;
  TVRMLFileType = (ftVRML1,ftVRML2);
  TVRMLList = class;
  TVRMLCoordinate3 = class;
  TVRMLIndexedFaceSet = class;

  TVRMLobject = class // пустышка
  private FOwner: TVRMLList;
  public constructor Create(Owner: TVRMLList); virtual; overload;
         destructor Destroy; override;
         procedure Clear; virtual;
         procedure Load( var LineNr: integer; Strings: TStringList ); virtual; overload;
  end;

  TFasterListTVRMLObject = specialize TFasterList<TVRMLObject>;
  TFasterListTVRMLCoordinate3 = specialize TFasterList<TVRMLCoordinate3>;
  TFasterListTVRMLIndexedFaceSet = specialize TFasterList<TVRMLIndexedFaceSet>;

  TVRMLCoordinate3 = class( TVRMLobject )
  private
    FCapacity,FCount: integer;
    FFaceSets: specialize TFasterList<TVRMLIndexedFaceSet>;
    FCoordinates: array of T3DVector;

    function FGetNumberOfFacesets: integer;
    function FGetPoint(Index: integer): T3DVector;
    procedure FSetCapacity(val: integer);
  public
    procedure Add(P: T3DVector);
    procedure AddFaceSet(FaceSet: TVRMLIndexedFaceSet);
    procedure Clear; override;
    constructor Create(Owner: TVRMLList); override;
    destructor Destroy; override;
    procedure Load(var LineNr: integer; Strings: TStringList); override;

    property Count: integer read FCount;
    property Capacity: integer read FCapacity write FSetCapacity;
    property NumberOfFaceSets: integer read FGetNumberOfFacesets;
    property Point[index: integer]: T3DVector read FGetPoint;
  end;

  TVRMLIndexedFaceSet = class(TVRMLobject)
  private
    FCapacity,FCount: integer;
    FFaces: array of TIntArray;
    FCoordinates: TVRMLCoordinate3;
    function FGetFace(Index: integer): TIntArray;
    procedure FSetCapacity(val: integer);
  public
    procedure Clear; override;
    procedure Load( var LineNr: integer; Strings: TStringList); override;
    property Coordinates: TVRMLCoordinate3 read FCoordinates;
    property Count: integer read FCount;
    property Capacity: integer read FCapacity write FSetCapacity;
    property Face[index: integer]: TIntArray read FGetFace;
  end;

  TVRMLSeparator = class(TVRMLobject)
  private
    FObjects: TFasterListTVRMLObject;
    function FGetCount: integer;
    function FGetItems(Index: integer): TVRMLObject;
  public
    procedure Add(VRMLObject: TVRMLObject);
    constructor Create(Owner: TVRMLList); override;
    destructor Destroy; override;
    procedure Clear; override;
    procedure Load( var LineNr: integer; Strings: TStringList); override;
    property Count: integer read FGetCount;
    property Items[index: integer]: TVRMLObject read FGetItems;
  end;

  TVRMLList = class
  private
    FObjects: TFasterListTVRMLObject;
    FFaceSets: TFasterListTVRMLIndexedFaceSet;
    FFileType: TVRMLFileType;
    FLastAddedCoordinates: TVRMLCoordinate3;
    function GetCount: integer;
    function GetItems(Index: integer): TVRMLObject;
  public
    procedure Add(VRMLObject: TVRMLObject);
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function ExtractFaceSetData: TFasterListTVRMLIndexedFaceSet;
    class function CheckVRMLFileVersion( Filename: AnsiString ):AnsiString;
    procedure LoadFromFile(Filename:AnsiString); virtual;  // загрузка в память
    procedure LoadVrml1( Strings: TStringList );
    procedure Import( Filename:AnsiString;
                      SubdivisionSurface: TFreeSubdivisionSurface); virtual;
    property Count: integer read GetCount;
    property Items[index: integer]: TVRMLObject read GetItems;
  end;


implementation  // ############## пустышки VRML base object ################№№
constructor TVRMLobject.Create(Owner: TVRMLList);
      begin inherited Create; FOwner:=Owner; Clear; end;
procedure TVRMLobject.Clear; begin end;
destructor TVRMLobject.Destroy; begin {Clear;} inherited Destroy; end;
procedure TVRMLobject.Load(var LineNr:integer; Strings:TStringList); begin end;

//**

procedure ProcessString( Input: ansistring; var output: TStringList );
  var Tmp: TStringArray; I: integer;
begin OutPut.Clear; if InPut='' then exit; Tmp:=BlankOff(Input).Split([' ']);
      for I:=0 to Length( Tmp )-1 do if Tmp[I]<>'' then OutPut.Add( Tmp[I] );
end;

procedure LoadNextObject
( strings: TStringList;
  var LineNr,NumberOfObjects: integer;
  var Objectname: AnsiString;
  Dest: TStringList);
var
  Index,Level,L: integer;
  Tmp,Str: AnsiString; Ch:char; Done: boolean;
begin
  Str:=''; Dest.Clear; Level:=0; Done:=False; Objectname:='';
  NumberOfObjects:=0;
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
      if Ch='{' then begin Inc(NumberOfObjects); if Level<>0 then Str:=Str+Ch; Inc(Level); end else
      if Ch='}' then begin Dec(Level); if Level=0 then begin Done:=True; break; end else Str:=Str+Ch; end else
      if Level<>0 then Str:=Str+Ch;
      Inc( Index );
    end;

    if Str<>'' then begin Dest.Add( Str ); Str:=''; end;
    if Done then begin Delete( Tmp,1,Index );
      if Tmp='' then begin Inc( LineNr ); end
                else begin Strings[ LineNr ]:=Tmp; end;
    end else begin
      if level=0 then begin
        if objectname<>'' then
          if Objectname[length(Objectname)]<>#32 then objectname:=objectname+#32;
      end;
      Inc(LineNr);
    end;
  end;
  Objectname:=Trim( Objectname );
  if not Done then begin
    Done:=(Objectname='') and (Dest.Count=0);
    if NumberOfObjects=0 then Done:=True;
    if not done then WriteLn( 'Unexpected end of file!');
  end;
end;

procedure GetEmbeddedObjects( Source: TStringList; Dest: TStringList );
var ToDo: TList;
    I,Line,NObj: integer;
    Current,OutPut: TStringList; ObjName: AnsiString;
begin
  ToDo:=TList.Create;
  ToDo.Add( Source ); I:=1;
  while I<=ToDo.Count do begin Current:=TStringList( ToDo[I-1] ); Line:=0;
    while Line<Current.Count do begin OutPut:=TStringList.Create;
      LoadNextObject( Current,Line,NObj,ObjName,Output );
      if NObj>1 then ToDo.Add(Output)
                else Dest.AddObject(ObjName,Output);
    end; Inc(I);
  end; FreeAndNil(ToDo);
end;

// ##################################### VRML Separator ######################
function TVRMLSeparator.FGetCount: integer; begin Result:=FObjects.Count; end;
function TVRMLSeparator.FGetItems(Index: integer): TVRMLObject;
   begin Result:=FObjects[index]; end;

procedure TVRMLSeparator.Add( VRMLObject: TVRMLObject );
begin
  FObjects.Add( VRMLObject );
  if VRMLObject is TVRMLCoordinate3 then begin
    FOwner.FLastAddedCoordinates:=VRMLObject as TVRMLCoordinate3;
  end else begin
    if VRMLObject is TVRMLIndexedFaceSet then begin
      FOwner.FFaceSets.Add(VRMLObject as TVRMLIndexedFaceSet);
      if FOwner.FLastAddedCoordinates<>nil then
        FOwner.FLastAddedCoordinates.AddFaceSet( VRMLObject as TVRMLIndexedFaceSet );
    end;
  end;
end;

constructor TVRMLSeparator.Create(Owner: TVRMLList);
begin FObjects:= TFasterListTVRMLObject.Create; inherited Create( Owner ); end;

procedure TVRMLSeparator.Clear; var I: integer;
begin for I:=0 to Count-1 do Items[I].Destroy; FObjects.Clear; inherited Clear;
end;

destructor TVRMLSeparator.Destroy;
     begin FreeAndNil( FObjects ); inherited Destroy; end;

procedure TVRMLSeparator.Load(var LineNr: integer; Strings: TStringList);
var
  Words: TStringList;
  ObjectName: AnsiString;
  VRMLObject: TVRMLObject;
  Index,NObj: integer;
begin
  Words:=TStringList.Create;
  while LineNr < Strings.Count do begin
    LoadNextObject( Strings,LineNr,NObj,Objectname,Words );
    VRMLObject:=nil;
    if Pos('SEPARATOR',Objectname)<>0 then VRMLObject:=TVRMLSeparator.Create(FOwner) else
    if Pos('COORDINATE3',Objectname)<>0 then VRMLObject:=TVRMLCoordinate3.Create(FOwner) else
    if Pos('INDEXEDFACESET',Objectname)<>0 then VRMLObject:=TVRMLIndexedFaceSet.Create(FOwner)
    else begin
    { if NObj>1 then begin Objects:=TStringList.Create;
         GetEmbeddedObjects(Words,Objects);
         for I:=1 to Objects.Count do begin ObjectName:=Objects[I-1];
           if Pos('INDEXEDFACESET',Objectname)<>0 then begin end;
            words:=Objects.Objects[I-1] as TStringList; FreeAndNil(Words);
         end; //Showmessage(Objects.Text);
         FreeAndNil(Objects);
      end; }
    end;
    if VRMLObject<>nil then
//  if VRMLObject<>self then -- рекурсия
    begin Index:=0; VRMLObject.Load( Index,Words ); Add( VRMLObject );
    end;
  end; FreeAndNil(words);
end;

// ##################################### VRML Material #####################################
function TVRMLCoordinate3.FGetNumberOfFacesets: integer;
   begin Result:=FFaceSets.Count; end;

function TVRMLCoordinate3.FGetPoint(Index: integer): T3DVector;
begin
  if (Index >= 0) and (Index < FCount) then Result:=FCoordinates[index] else
  begin Result:=ZERO;
     // WriteLn( 'Point index out of bounds in TVRMLCoordinate3.FGetPoint' );
  end;
end;

procedure TVRMLCoordinate3.FSetCapacity(val: integer);
begin FCapacity:=val; Setlength(FCoordinates,FCapacity);
      if FCapacity<FCount then FCount:=FCapacity;
end;

procedure TVRMLCoordinate3.Add(P: T3DVector);
begin if FCount>=FCapacity then Capacity:=Count+25; Inc(FCount);
      FCoordinates[FCount-1]:=P;
end;

procedure TVRMLCoordinate3.AddFaceSet(FaceSet: TVRMLIndexedFaceSet);
begin if FFaceSets.IndexOf(FaceSet)=-1 then begin
         FFaceSets.Add( FaceSet ); FaceSet.FCoordinates:=self; end;
end;

procedure TVRMLCoordinate3.Clear;
begin Capacity:=0; FCount:=0; FFaceSets.Clear; end;

constructor TVRMLCoordinate3.Create(Owner: TVRMLList);
begin FFaceSets:=TFasterListTVRMLIndexedFaceSet.Create;
      inherited Create(Owner);
end;

destructor TVRMLCoordinate3.Destroy;
begin FreeAndNil(FFaceSets);
      inherited Destroy;
end;

procedure TVRMLCoordinate3.Load(var LineNr: integer; Strings: TStringList);
var
  Data: AnsiString;
  Index,S,F,I,L,Flag: integer; Ch: char;
  Points: TStringList;
  P: T3DVector;
begin
  Data:=Strings.Text;                            // writeln( 'Coord3: '+Data );
  Index:=Pos('POINT',Data);
  if Index <> 0 then begin S:=-1; F:=-1; L:=Length(Data); I:=Index+1;
    while I <= L do begin Ch:=Data[I];
      if (Ch='[') and (S=-1) then S:=I;
      if (Ch=']') and (F=-1) then F:=I;
      if (S<>-1) and (F<>-1) then break; Inc(I);
    end;
    if (S<>-1) and (F<>-1) then begin Points:=TStringList.Create;
      ProcessString( Copy( Data,S+1,F-S-2 ),Points );
      if Points.Count mod 3 = 0 then begin
        Capacity:=Points.Count div 3; I:=1;
        while I <= Points.Count do begin
          P.X:=StrtoFloat( Points[I-1] );
          P.Y:=StrtoFloat( Points[I]   );
          P.Z:=StrtoFloat( Points[I+1] ); Add( P ); Inc( I,3 );
        end;
      end; FreeAndNil(Points);
    end;
  end;
end;

// ##################################### VRML Indexed face set #####################################
function TVRMLIndexedFaceSet.FGetFace(Index: integer): TIntArray;
begin
  if (Index >= 0) and (Index < FCount) then Result:=FFaces[index]
  else begin Result:=nil; // WriteLn('Face index out of bounds in TVRMLIndexedFaceSet.FGetFace');
  end;
end;
procedure TVRMLIndexedFaceSet.FSetCapacity(val: integer);
begin FCapacity:=val;
  Setlength( FFaces,FCapacity ); if FCapacity<FCount then FCount:=FCapacity;
end;
procedure TVRMLIndexedFaceSet.Clear;
begin Capacity:=0; FCount:=0; FCoordinates:=nil; end;

procedure TVRMLIndexedFaceSet.Load(var LineNr: integer; Strings: TStringList);
var
  Data: AnsiString;
  Index,S,F,I,L,N,Flag: integer; Ch:char;
  Faces: TStringList;
  Tmp: array of integer;
begin
  Data:=Strings.Text;                               // writeln( 'Face['+inttostr(LineNr)+']: '+Data );
  Index:=Pos('COORDINDEX',Data);
  if Index <> 0 then begin S:=-1; F:=-1; L:=Length(Data); I:=Index+1;
    while I<=L do begin Ch:=Data[I];
      if (Ch='[') and (S=-1) then S:=I;
      if (Ch=']') and (F=-1) then F:=I;
      if (S<>-1) and (F<>-1) then break; Inc(I);
    end;
    if (S<>-1) and (F<>-1) then begin
      Faces:=TStringList.Create;                // Data:=Copy( Data,S+1,F-S-2 );
      ProcessString( Copy( Data,S+1,F-S-2 ),Faces );
      Setlength( Tmp,Faces.Count ); N:=0;
      for I:=1 to faces.Count do begin
//      Index:=getInteger( Faces[I-1] ); Flag:=0;
        Val( Faces[I-1],Index,Flag );  ///***???
        if Flag=0 then begin
          if Index=-1 then begin
            if N>2 then begin
              if FCount>=Capacity then Capacity:=FCount+25;
              setlength( FFaces[FCount],N );
              Move( Tmp[0],FFaces[FCount][0],N*SizeOf(integer) ); Inc(FCount);
            end; N:=0;
          end else begin Tmp[N]:=Index; Inc(N); end;
        end;
      end; FreeAndNil(Faces);
    end;
  end;
end;

// ##################################### VRML list #####################################
function TVRMLList.GetCount: integer; begin Result:=FObjects.Count; end;

function TVRMLList.GetItems(Index: integer): TVRMLObject;
begin Result:=FObjects[index]; end;

procedure TVRMLList.Add(VRMLObject: TVRMLObject);
begin
  FObjects.Add(VRMLObject);
  if VRMLObject is TVRMLCoordinate3 then begin
    FLastAddedCoordinates:=VRMLObject as TVRMLCoordinate3; end else
  if VRMLObject is TVRMLIndexedFaceSet then begin
    FFaceSets.Add(VRMLObject as TVRMLIndexedFaceSet);
    if FLastAddedCoordinates <> nil then
      FLastAddedCoordinates.AddFaceSet(VRMLObject as TVRMLIndexedFaceSet);
  end;
end;
procedure TVRMLList.Clear;
var I: integer;
begin
  for I:=0 to Count-1 do begin FObjects[I].Free; FObjects[I]:=nil; end;
  FObjects.Clear;
  FFaceSets.Clear;
  FLastAddedCoordinates:=nil;
  FFileType:=ftVRML1;
end;

constructor TVRMLList.Create;
begin FObjects:=TFasterListTVRMLObject.Create;
      FFaceSets:=TFasterListTVRMLIndexedFaceSet.Create; Clear;
end;

destructor TVRMLList.Destroy;
begin Clear; FreeAndNil(FObjects);
             FreeAndNil(FFaceSets); inherited Destroy;
end;

function TVRMLList.ExtractFaceSetData: TFasterListTVRMLIndexedFaceSet;
var I: integer;
    FaceSet: TVRMLIndexedFaceSet;
begin Result:=nil;
  if FFaceSets.Count > 0 then begin
    Result:=TFasterListTVRMLIndexedFaceSet.Create;
    Result.Capacity:=FFaceSets.Count;
    for I:=1 to FFaceSets.Count do begin
      FaceSet:=FFacesets[I-1];
      if Faceset.Coordinates <> nil then Result.Add(FaceSet);
    end;
    if Result.Count=0 then begin FreeAndNil(Result); Result:=nil; end;
  end;
end;
procedure TVRMLList.LoadVrml1( Strings: TStringList );
var
  LineNr,Index,NObj: integer; ObjectName: AnsiString;
  VRMLObject: TVRMLObject;
  Words: TStringList;
  ValidFile: boolean;
begin
  LineNr:=0;
  Words:=TStringList.Create;
  while LineNr<Strings.Count do begin
    LoadNextObject( Strings,LineNr,NObj,Objectname,Words );
    VRMLObject:=nil;
    if Pos('SEPARATOR',Objectname)<>0      then VRMLObject:=TVRMLSeparator.Create(self) else
    if Pos('COORDINATE3',Objectname)<>0    then VRMLObject:=TVRMLCoordinate3.Create(self) else
    if pos('INDEXEDFACESET',Objectname)<>0 then VRMLObject:=TVRMLIndexedFaceSet.Create(self);
    if VRMLObject<>nil then begin Index:=0;
       VRMLObject.Load( Index,Words ); Add( VRMLObject ); end;
  end; FreeAndNil( words );
end;
(*
procedure TVRMLList.LoadVrml1( Strings: TStringList );
var
  LineNr,Index,NObj: integer; ObjectName: AnsiString; fi:boolean;
  VRMLObject: TVRMLObject;
  Words: TStringList;
  ValidFile: boolean;
begin
  LineNr:=0; fi:=false;
  Words:=TStringList.Create;
//VRMLObject:=TVRMLSeparator.Create( self ); Add( VRMLObject );
  while LineNr<Strings.Count do begin
    LoadNextObject( Strings,LineNr,NObj,Objectname,Words );
    if not fi then VRMLObject:=nil;
    if Pos('SEPARATOR',Objectname)<>0      then begin VRMLObject:=TVRMLSeparator.Create(self); fi:=false; end else
    if Pos('COORDINATE3',Objectname)<>0    then begin VRMLObject:=TVRMLCoordinate3.Create(self); fi:=false; end else
    if pos('INDEXEDFACESET',Objectname)<>0 then
       begin if not fi then VRMLObject:=TVRMLIndexedFaceSet.Create(self); fi:=true;
             Index:=0; VRMLObject.Load( Index,Words ); Add( VRMLObject );
       end;
    if (not fi) and (VRMLObject<>nil) then begin Index:=0;
        VRMLObject.Load( Index,Words ); Add( VRMLObject );
    end;
  end; FreeAndNil( words );
end;
*)
class function TVRMLList.CheckVRMLFileVersion( Filename: AnsiString ):AnsiString;
  var Str: AnsiString; FFile: TextFile;
begin CheckVRMLFileVersion:='noVRML';
  if FileExistsUTF8( Filename ) { *Converted from FileExists* } then begin
    AssignFile( FFile,FileName ); Reset(FFile);
    if not EOF(FFile) then begin Readln( FFile,Str ); Str:=Uppercase( Str );
      if pos('#VRML V1.0 ASCII',Str)<>0 then CheckVRMLFileVersion:='VRML V1.0' else
      if pos('#VRML V2.0 UTF8',Str)<>0 then CheckVRMLFileVersion:='VRML V2.0';
    end; CloseFile( FFile );
  end;
end;

procedure TVRMLList.LoadFromFile( Filename: AnsiString );
var
  Strings: TStringList; I: integer; Str: AnsiString; FFile: TextFile;
begin
    Clear; Strings:=TStringList.Create;
    AssignFile( FFile,FileName ); Reset( FFile ); FFileType:=ftVRML1;
    while not EOF(FFile) do begin                 //  ... поехали
      Readln( FFile,Str );                        // Read(FFile,Str);
      I:=Str.IndexOf( '#' );                      // remove comments
      if I>0 then SetLength( Str,I-1 );
      if Length( Str )>0 then begin Str:=BlankOff( Str.Replace( ',',' ' ) );
        if Length( Str )>0 then Strings.Add( Uppercase( Str ) ); end;
    end;
    CloseFile(FFile);
    if Strings.Count>0 then LoadVrml1( Strings )
                       else ShowMessage( 'VRML 1.0 file empty!' );
    FreeAndNil( Strings );
end;

procedure TVRMLList.Import
( Filename: AnsiString;
  SubdivisionSurface: TFreeSubdivisionSurface
);
var //VRMLList: TVRMLList;
  I,J,K,N,Index: integer; V3Point: T3DVector;
  Data: TFasterListTVRMLIndexedFaceSet;
  CoordInfo: TVRMLCoordinate3;
  FaceInfo: TVRMLIndexedFaceSet;
  Face: TIntArray;
  Layer: TFreeSubdivisionLayer;
  FacePoints: TFasterListTFreeSubdivisionControlPoint;
  AddedCtrlPts: TFasterListTVRMLCoordinate3;
  CtrPoint: TFreeSubdivisionControlPoint;
  Points: TFasterListTFreeSubdivisionControlPoint;
begin
  if TVRMLList.CheckVRMLFileVersion( Filename )='VRML V1.0' then begin
//  try
    SubdivisionSurface.IsLoading:=true;
    Self.LoadFromFile( Filename );
    Data:=Self.ExtractFaceSetData;
    if Data<>nil then begin Clear;
      AddedCtrlPts:=TFasterListTVRMLCoordinate3.Create;
      AddedCtrlPts.Capacity:=Data.Count;
                                                    // Assemble coordinate sets
      for I:=1 to Data.Count do begin FaceInfo:=Data[I-1];
        if AddedCtrlPts.IndexOf(FaceInfo.Coordinates) = -1 then
           AddedCtrlPts.Add(FaceInfo.Coordinates);
      end;
                                                // now add actual controlPoints
      for I:=0 to AddedCtrlPts.Count-1 do begin
        CoordInfo:=AddedCtrlPts[I];
        Points:=TFasterListTFreeSubdivisionControlPoint.Create;
        Points.Capacity:=CoordInfo.Count;
        AddedCtrlPts.Objects[I]:=Points;
        for J:=0 to CoordInfo.Count-1 do begin
          V3Point:=CoordInfo.Point[J];
          CtrPoint:=SubdivisionSurface.AddControlPoint(V3Point,1e-6); //CoordInfo.Precision);
          Points.Add(CtrPoint);
        end;
      end;
                                                            // Add controlfaces
      FacePoints:=TFasterListTFreeSubdivisionControlPoint.Create;
      for I:=1 to Data.Count do begin
        FaceInfo:=Data[I-1];
        Index:=AddedCtrlPts.IndexOf(FaceInfo.Coordinates);
        if Index <> -1 then begin
          Points:=TFasterListTFreeSubdivisionControlPoint(AddedCtrlPts.Objects[Index]);
          Layer:=SubdivisionSurface.AddNewLayer;
          for J:=1 to FaceInfo.Count do begin Face:=FaceInfo.Face[J-1];
            if Face<>nil then begin N:=length( Face ); FacePoints.Clear;
              for K:=1 to N do begin Index:=Face[K-1];
                if (Index >= 0) and (Index<Points.Count) then begin
                  CtrPoint:=Points[Index] as TFreeSubdivisionControlpoint;
                    if FacePoints.IndexOf(CtrPoint) = -1 then FacePoints.Add(CtrPoint);
                end;
              end;
              if FacePoints.Count>2 then
                 SubdivisionSurface.AddControlFaceN( FacePoints,True,Layer );
            end;
          end;
        end;
      end; FreeAndNil(FacePoints);
      for I:=1 to AddedCtrlPts.Count do begin
        Points:=TFasterListTFreeSubdivisionControlPoint(AddedCtrlPts.Objects[I-1]);
        FreeAndNil(Points);
      end;
      FreeAndNil(AddedCtrlPts);                          // delete empty layers
      for I:=SubdivisionSurface.NumberOfLayers downto 1 do begin
        if ( SubdivisionSurface.Layer[I-1].Count=0)
        and ( SubdivisionSurface.NumberOfLayers>1 )
        then  SubdivisionSurface.Layer[I-1].Delete;
      end;
      SubdivisionSurface.ActiveLayer:=
          SubdivisionSurface.Layer[SubdivisionSurface.NumberOfLayers-1];
      SubdivisionSurface.Built:=False;
      FreeAndNil(Data);
    end else ShowMessage( 'No meshdata could be imported.' );
//  except on E:Exception do WriteLn( 'Exception in VRML Load:'+E.Message );
//  end;
//  FreeAndNil(VRMLList);
    SubdivisionSurface.IsLoading:=false;
  end else ShowMessage( 'Not a VRML V1.0 format' );
end;
end.
