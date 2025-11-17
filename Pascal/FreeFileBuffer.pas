unit FreeFileBuffer;
interface uses
  Classes,
  SysUtils,
  Graphics,
  StrUtils,
  FreeTypes,
  LConvEncoding,
  FreeVersionUnit;
const FileBufferBlockSize=32768;                         //=2^15 <= 4096=2^12
                        // used for reading and writing files using TFilebuffer
type
{
  TFreeFileBuffer
  Binary stream used to store file info
}
TFreeFileBuffer=class
  private
    FCapacity: integer; // Amount of bytes allocated
    FVersion: TFreeFileVersion;
    FData: array of byte;
    FFileName: String;
    FFile: file;
    procedure FSetCapacity(val: integer); virtual;
    function FGetCapacity: integer; virtual;
  public
    FCount: integer;    // The amount of bytes actually used
    FPosition: integer; // current position when reading information from buffer
    Encoding: String;
    procedure Add( IntegerValue: integer);     overload; virtual;
    procedure Add( Text: String);          overload; virtual;
    procedure Add( BooleanValue: boolean);     overload; virtual;
    procedure Add( FloatValue: Real);    overload; virtual;
    procedure Add( Coordinate: Vector);     overload; virtual;
    procedure Add( Plane: Plate);           overload; virtual;
    procedure Add( Version: TFreeFileVersion); overload; virtual;
    procedure Add(JPegImage: TJPEGImage); overload; virtual;
    procedure LoadInteger(var Output: integer); virtual;
    procedure LoadString(var Output: String); virtual;
    procedure LoadTStrings(var Output: TStrings); virtual;
    procedure LoadTFreeFileVersion(var Output: TFreeFileVersion); virtual;
    procedure LoadBoolean(var Output: boolean); virtual;
    procedure LoadTFloatType(var Output: Real); virtual;
    procedure LoadVector(var Output: Vector); virtual;
    procedure LoadT3DPlane(var Output: Plate); virtual;
    procedure LoadTJPEGImage(var JPegImage: TJPEGImage); virtual;
    constructor Create;
    procedure Clear; virtual;
    procedure LoadFromFile(Filename: String); virtual;
    procedure Reset; virtual;                  // reset the data before reading
    function SaveToFile(Filename: String):boolean; virtual;
    function GetPosition:integer; virtual;
    destructor Destroy; override;
    property Capacity: integer read FGetCapacity write FSetCapacity;
    property Count: integer read FCount;
    property Version: TFreeFileVersion read FVersion write FVersion;
    property Position: integer read GetPosition;
  end;
  {  TFreeTextBuffer
     Text file used to store file info
  }
  TFreeTextBuffer=class( TFreeFileBuffer )
  private
    FLines: TStringList;
//  FormatSettings: TFormatSettings;
    function FGetCapacity: integer; override;
    procedure FSetCapacity( val: integer ); override;
  public
    FPosition: integer;    // this is our position
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
    procedure Add(IntegerValue: integer); override; overload;
    procedure Add(Text: String); override; overload;
    procedure Add(BooleanValue: boolean); override; overload;
    procedure Add(FloatValue: Real); override; overload;
    procedure Add(PVersion: TFreeFileVersion); override; overload;
    procedure Add(Coordinate: Vector); override; overload;
    procedure Add(Plane: Plate); override; overload;
    procedure Add(JPegImage: TJPEGImage); override; overload;
    procedure LoadInteger(var Output: integer); override;
    procedure LoadString(var Output: String); override;
    procedure LoadTFreeFileVersion(var Output: TFreeFileVersion); override;
    procedure LoadBoolean(var Output: boolean); override;
    procedure LoadTFloatType(var Output: Real); override;
    procedure LoadTStrings(var Output: TStrings); override;
    procedure LoadVector(var Output: Vector); override;
    procedure LoadT3DPlane(var Output: Plate); override;
    procedure LoadTJPEGImage(var JPegImage: TJPEGImage); override;
    procedure LoadFromFile(Filename: String); override;
    procedure Reset; override;                 // reset the data before reading
    function SaveToFile(Filename: String):boolean; override;
    function GetPosition:integer; override;
    property Capacity: integer read FGetCapacity write FSetCapacity;
    property Position: integer read GetPosition;
  end;

implementation
{
  TFreeFileBuffer
  Binary stream used to store file info
}
function TFreeFileBuffer.FGetCapacity: integer; begin Result:=FCapacity; end;
procedure TFreeFileBuffer.FSetCapacity( Val: Integer ); //Var I: Integer;
begin if FCapacity<=Val then begin
      FCapacity:=Val+512; Setlength( FData,Fcapacity ); //for I:=FCapacity+1 to Val do FData[I-1]:=255;
  end; end;

constructor TFreeFileBuffer.Create;
      begin inherited Create; Clear; end;
procedure TFreeFileBuffer.Clear;
begin
  FCapacity:=0;
  FCount:=0;
  FPosition:=0;
  Setlength( FData,0 );
  FFileName:='';
  Encoding:='cp1251';
end;
destructor TFreeFileBuffer.Destroy;
     begin Clear; inherited Destroy; end;

function TFreeFileBuffer.GetPosition:integer;
   begin Result:=FPosition; end;

procedure TFreeFileBuffer.LoadFromFile( Filename: String );
var DataLeft,Tmp,Size: integer;
begin
  FFileName:=Filename;
  AssignFile( FFile,Filename );
//TheStream:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  system.FileMode:=fmOpenRead;
  system.Reset( FFile,1 );
  FCount:=0;
  DataLeft:=FileSize( FFile );
  Capacity:=DataLeft;
  FPosition:=0;
  while DataLeft>0 do begin
    if DataLeft<FileBufferBlockSize then Size:=DataLeft
                                    else Size:=FileBufferBlockSize;
    BlockRead( FFile,FData[FCount],Size,Tmp );
    Dec( DataLeft,Tmp );
    Inc( FCount,Tmp );
  end;
  Closefile(FFile);
  FFileName:='';
end;

// reset the data before reading
procedure TFreeFileBuffer.Reset; begin FPosition:=0; end;

function TFreeFileBuffer.SaveToFile( Filename: String ):boolean;
var DataWritten,DataLeft,Size,Tmp: integer;
begin
  result:=false;
  FFileName:=Filename;
  AssignFile( FFile,Filename );
  Rewrite( FFile,1 );
  DataWritten:=0;
  DataLeft:=Count;
  while DataWritten<Count do begin
    if DataLeft<FileBufferBlockSize then Size:=DataLeft
                                    else Size:=FileBufferBlockSize;
    BlockWrite( FFile,FData[DataWritten],Size,Tmp );
    Dec( DataLeft,Tmp );
    Inc( DataWritten,Tmp );
  end;
  Closefile( FFile );
  FFileName:='';
  result:=true;
end;

procedure TFreeFileBuffer.Add( IntegerValue:Integer ); var Size:integer;
begin Size:=SizeOf( Integer );
   if Count+Size>Capacity then Capacity:=Count+Size;
      Move( IntegerValue,FData[FCount],Size ); Inc( FCount,Size );
  end;                            // NtoLE( IntegerValue )=Indian swap bytes

procedure TFreeFileBuffer.Add(Version: TFreeFileVersion);
var
  Size: integer;
begin
  FVersion:=Version;
  Size:=SizeOf(Version);
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move(Version,FData[FCount],Size);
  Inc(FCount,Size);
end;
procedure TFreeFileBuffer.Add( FloatValue: Real );
const Size=SizeOf( Single ); var W: Single;
begin W:=FloatValue;
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move( W,FData[FCount],Size );
  Inc( FCount,Size );
end;
procedure TFreeFileBuffer.Add( Coordinate: Vector );
begin Add( Coordinate.X ); Add( Coordinate.Y ); Add( Coordinate.Z ); end;
procedure TFreeFileBuffer.Add( Plane: Plate );
begin Add( Plane.a ); Add( Plane.b ); Add( Plane.c ); Add( Plane.d ); end;
procedure TFreeFileBuffer.Add(JPegImage: TJPEGImage);
var Stream: TMemoryStream; Size: integer;
begin
  Add(JPEGImage.Width);
  Add(JPEGImage.Height);
  Stream:=TMemoryStream.Create;
  JPEGImage.SaveToStream(Stream);
  Size:=Stream.Size;
  Stream.Position:=0;
  Add( Size );
  if Count+Size+20>Capacity then Capacity:=Count+Size+20;
  Stream.Read(FData[FCount],Size);
  Inc(FCount,Size);
  FreeAndNil(Stream);
end;

procedure TFreeFileBuffer.LoadTJPEGImage(var JPegImage: TJPEGImage);
var
  Stream: TMemoryStream;
  W,H,Size: integer;
begin
  LoadInteger(W);
  LoadInteger(H);
  LoadInteger(Size);
  Stream:=TMemoryStream.Create;
  Stream.SetSize(Size);
  Stream.Write(FData[FPosition],Size);
  Inc(FPosition,Size);
  Stream.Position:=0;
  JPEGImage.LoadFromStream(Stream);
  FreeAndNil(Stream);
end;
(*
   !!!-на случай восстановления ~~~ c множеством перезагружаемых вызовов
*)
procedure TFreeFileBuffer.LoadString( var Output: String );
var I,Size: integer; Ch: char; // S: String;
begin Output:='';
  if FPosition=0 then
  if (Integer(FData[0])<>9) and (Integer(FData[0])<>18) then exit;// 0-контроль
  LoadInteger( Size );                // if FPosition+Size >= FCount then exit;
  for I:=1 to Size do begin
     Ch:=char( FData[FPosition] ); Inc( FPosition );
     Output:=Output+Ch;
  end;                                                 //  EnCoding:='cp1251';
  if Encoding<>'utf8' then Output:=ConvertEncoding( Output,Encoding,'utf8' );
//   begin S:=Output; Output:=ConvertEncoding( S,Encoding,'utf8' ); end;
end;

procedure TFreeFileBuffer.LoadInteger( var Output: integer );
var Size: integer;
begin Size:=4; Output:=0;              //if FPosition+Size >= FCount then exit;
  Move( FData[FPosition],Output,Size );
  Output:=LEtoN( Output );
  Inc( FPosition,Size );
end;
procedure TFreeFileBuffer.LoadTStrings(var Output: TStrings);
var i,c: integer; S:String;
begin
  LoadInteger( c );
  for i:=1 to c do begin
    LoadString(S);
    Output.Add(S);
    end;
end;

procedure TFreeFileBuffer.LoadTFreeFileVersion(var Output: TFreeFileVersion);
var
  Size: integer;
begin
  Size:=SizeOf( Output );         //if FPosition+Size >= FCount then exit;
  Move( FData[FPosition],Output,Size );
  Inc( FPosition,Size );
end;

procedure TFreeFileBuffer.LoadBoolean( var Output: boolean );
const Size=1;
begin Output:=False;                   //if FPosition+Size >= FCount then exit;
  Move(FData[FPosition],Output,Size);
  Inc( FPosition,Size );
end;
procedure TFreeFileBuffer.LoadTFloatType( var Output: Real );
const Size=sizeof( Single ); var W: Single=0.0;
begin// if FPosition+Size >= FCount then exit;
  Move( FData[FPosition],W,Size ); OutPut:=W; Inc( FPosition,Size );
end;
procedure TFreeFileBuffer.LoadVector( var Output: Vector );
begin LoadTFloatType( OutPut.X );
      LoadTFloatType( OutPut.Y );
      LoadTFloatType( OutPut.Z );
end;
procedure TFreeFileBuffer.LoadT3DPlane( var Output: Plate );
begin LoadTFloatType( OutPut.a );
      LoadTFloatType( OutPut.b );
      LoadTFloatType( OutPut.c );
      LoadTFloatType( OutPut.d );
end;

procedure TFreeFileBuffer.Add( Text: String );
var Size: integer;
begin                                 // convert text from UTF8 to Windows ANSI
  if Encoding<>'utf8' then Text:=ConvertEncoding( Text,'utf8',Encoding );
  Size:=Length( Text );
  Add( Size );
  if Size=0 then exit;
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move( Text[1],FData[FCount],Size );
  Inc(FCount,Size);
end;

procedure TFreeFileBuffer.Add( BooleanValue: boolean );
const Size=1; // SizeOf( BooleanValue );
begin
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move( BooleanValue,FData[FCount],Size );
  Inc( FCount,Size );
end;
{
  TFreeTextBuffer
  Text file used to store file info
}
constructor TFreeTextBuffer.Create;
begin FLines:=TStringList.Create; inherited Create; WestPoint; end;

function TFreeTextBuffer.FGetCapacity: integer;
   begin Result:=FLines.Capacity; end;
procedure TFreeTextBuffer.FSetCapacity( val: integer );
    begin FLines.Capacity:=val; end;
procedure TFreeTextBuffer.Clear;
    begin if FLines<>nil then FLines.Clear; inherited Clear; end;

procedure TFreeTextBuffer.Add(Text: String); var S: String;
begin
  S:=ReplaceStr( Text,'\','\\' );
  S:=ReplaceStr( S,EOL,'\n' );
  FLines.Add( S );
  Inc( FPosition );
end;

procedure TFreeTextBuffer.Add(BooleanValue: boolean); var S: String;
begin                        // if BooleanValue then S:='True' else S:='False';
  S:=BoolToStr( BooleanValue,'1','0' );
  FLines.Add( S );
  Inc( FPosition );
end;

procedure TFreeTextBuffer.Add( FloatValue: Real ); var S: String;
begin S:=FloatTypeToStr( FloatValue ); FLines.Add(S); Inc(FPosition); end;

procedure TFreeTextBuffer.Add( IntegerValue: integer );
    begin FLines.Add( I2S( IntegerValue ) ); Inc( FPosition );
    end;
procedure TFreeTextBuffer.Add( PVersion: TFreeFileVersion ); var S: String;
    begin FVersion:=PVersion;
      S:=VersionString( PVersion );
      FLines.Add( S );
      Inc( FPosition );
    end;
procedure TFreeTextBuffer.Add( Coordinate: Vector );
  var S: String;
begin S:=FloatTypeToStr( Coordinate.X )+' '
        +FloatTypeToStr( Coordinate.Y )+' '
        +FloatTypeToStr( Coordinate.Z ); FLines.Add(S); Inc(FPosition);
end;

procedure TFreeTextBuffer.Add(Plane: Plate);
var S: String;
begin
  S:=FloatTypeToStr( Plane.a )+' '+FloatTypeToStr( Plane.b )+' '
    +FloatTypeToStr( Plane.c )+' '+FloatTypeToStr( Plane.d );
  FLines.Add(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.Add(JPegImage: TJPEGImage);
var
  Stream: TMemoryStream;
  Size: integer;
  S: PChar;
  P: PChar;
  L: String;
begin
  Add(JPEGImage.Width);
  Add(JPEGImage.Height);

  Stream:=TMemoryStream.Create;
  JPEGImage.SaveToStream(Stream);
  Size:=Stream.Size;
  Stream.Position:=0;
  Add(Size);

  S:=StrAlloc(Size*2+2);
  S[Size*2]:=#0;
  S[Size*2+1]:=#0;
  P:=Stream.Memory;
  BinToHex(P,S,size);
  L:=StrPas(S);
  StrDispose(S);
  FLines.Add(L);
  FreeAndNil(Stream);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.LoadTJPEGImage(var JPegImage: TJPEGImage);
var
  Stream: TMemoryStream;
  W,H,Size: integer;
  PData: PChar;
begin
  LoadInteger(W);
  LoadInteger(H);
  LoadInteger(Size);
  PData:=StrAlloc(Size);
  Stream:=TMemoryStream.Create;
  Stream.SetSize(Size);
  HexToBin(PChar(FLines[FPosition]),Stream.Memory,Size);
//Stream.Write(PData,Size);
  StrDispose(PData);
  Stream.Position:=0;
  JPEGImage.LoadFromStream(Stream);
  FreeAndNil(Stream);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.LoadInteger( var Output: integer ); var S: String;
    begin S:=FLines[FPosition];
      Output:=GetInteger( S ); //StrToInt( S );
      Inc(FPosition);
    end;

procedure TFreeTextBuffer.LoadString( var Output: String );
var S: String;
begin
   S:=FLines[FPosition];
   S:=ReplaceStr(S,'\n',EOL);
   S:=ReplaceStr(S,'\\','\');
   Output:=S;                //!!! Output:=ConvertEncoding(S,FEncoding,'utf8');
   Inc( FPosition );
end;
procedure TFreeTextBuffer.LoadTFreeFileVersion( var Output: TFreeFileVersion );
var S: String;
begin S:=FLines[FPosition]; Output:=VersionBinary( S ); Inc( FPosition );
end;

procedure TFreeTextBuffer.LoadBoolean(var Output: boolean);
var S: String;
begin S:=FLines[FPosition]; Output:=StrToBool( S );  Inc( FPosition );
end;

procedure TFreeTextBuffer.LoadTFloatType( var Output: Real );
  var S: String;                   // LocalFormatSettings: TFormatSettings;
begin S:=FLines[FPosition]; Output:=GetFloat( S ); Inc( FPosition );
end;

procedure TFreeTextBuffer.LoadVector(var Output: Vector);
var S: String;
begin
  S:=FLines[FPosition];
  Output.X:=GetFloat( S );
  Output.Y:=GetFloat( S );
  Output.Z:=GetFloat( S );
  Inc( FPosition );
end;

procedure TFreeTextBuffer.LoadT3DPlane(var Output: Plate);
var S: String;
begin
  S:=FLines[FPosition];
  Output.a:=GetFloat( S );
  Output.b:=GetFloat( S );
  Output.c:=GetFloat( S );
  Output.d:=GetFloat( S );
  Inc( FPosition );
end;

// load string of words separated by spaces
procedure TFreeTextBuffer.LoadTStrings(var Output: TStrings);
var  I:integer; S,V: String; //SS:TStrings;
begin S:=FLines[FPosition]; I:=1;
  while true do begin V:=ExtractWord(i,S,[' ']);
    if V='' then break;
    Output.Add( V );
    inc( I );
  end;
  Inc(FPosition);
end;

destructor TFreeTextBuffer.Destroy; begin Clear; inherited Destroy; end;

procedure TFreeTextBuffer.LoadFromFile( Filename: String );
begin
  FFileName:=Filename;
  FLines.LoadFromFile( Filename );
  FPosition:=0;
end;

// reset the data before reading
procedure TFreeTextBuffer.Reset; begin FPosition:=0; end;

function TFreeTextBuffer.SaveToFile(Filename: String):boolean;
begin
  result:=false;
  FFileName:=Filename;
  FLines.SaveToFile(Filename);
  result:=true;
end;

function TFreeTextBuffer.GetPosition:integer; begin Result:=FPosition; end;

end.

