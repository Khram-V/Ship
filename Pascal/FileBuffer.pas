unit FileBuffer;
interface uses
  Classes,   SysUtils,
  Graphics,  StrUtils,
  LConvEncoding, STypes, VersionUnit;
const FileBufferBlockSize=32768;                         //=2^15 <= 4096=2^12
                        // used for reading and writing files using TFilebuffer
type
{
  TFileBuffer
  Binary stream used to store file info
}
TFileBuffer=class
  private
    FCapacity,         // Amount of bytes allocated
    FCount: Integer;   // The amount of bytes actually used
    FData: array of byte;
    FFileName: String;
    FFile: file;
    procedure FSetCapacity(val: integer); virtual;
    function FGetCapacity: integer; virtual;
  public
    Version: TFileVersion;
    FPosition:Integer; // current position when reading information from buffer
    constructor Create;
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure Add( IntegerValue: integer); overload; virtual;
    procedure Add( Text: String);        overload; virtual;
    procedure Add( BooleanValue: boolean); overload; virtual;
    procedure Add( FloatValue: Real);    overload; virtual;
    procedure Add( Coordinate: Vector);  overload; virtual;
    procedure Add( Plane: Plate);        overload; virtual;
    procedure Add( Ver: TFileVersion);   overload; virtual;
    procedure Add( JPegImage: TJPEGImage ); overload; virtual;
    procedure LoadInteger(var Output: integer); virtual;
    procedure LoadString(var Output: String); virtual;
    procedure LoadTFileVersion(var Output: TFileVersion); virtual;
    procedure LoadBoolean(var Output: boolean); virtual;
    procedure LoadTFloatType(var Output: Real); virtual;
    procedure LoadVector(var Output: Vector); virtual;
    procedure LoadT3DPlane(var Output: Plate); virtual;
    procedure LoadTJPEGImage(var JPegImage: TJPEGImage); virtual;
    procedure LoadFromFile(Filename: String); virtual;
    procedure Reset; virtual;                  // reset the data before reading
    function SaveToFile(Filename: String):boolean; virtual;
    function GetPosition:integer; virtual;
    property Capacity: integer read FGetCapacity write FSetCapacity;
    property Count: integer read FCount;
    property Position: integer read GetPosition;
  end;
  {  TTextBuffer
     Text file used to store file info
  }
  TTextBuffer=class( TFileBuffer )
  private
    FLines: TStringList;                    // FormatSettings: TFormatSettings;
    function FGetCapacity: integer; override;
    procedure FSetCapacity( val: integer ); override;
  public
    FPosition: integer;                                 // this is our position
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
    procedure Add(IntegerValue: integer); override; overload;
    procedure Add(Text: String); override; overload;
    procedure Add(BooleanValue: boolean); override; overload;
    procedure Add(FloatValue: Real); override; overload;
    procedure Add(Ver: TFileVersion); override; overload;
    procedure Add(Coordinate: Vector); override; overload;
    procedure Add(Plane: Plate); override; overload;
    procedure Add(JPegImage: TJPEGImage); override; overload;
    procedure LoadInteger(var Output: integer); override;
    procedure LoadString(var Output: String); override;
    procedure LoadTFileVersion(var Output: TFileVersion); override;
    procedure LoadBoolean(var Output: boolean); override;
    procedure LoadTFloatType(var Output: Real); override;
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

implementation Uses ShipUnit;
{
  TFileBuffer
  Binary stream used to store file info
}
function TFileBuffer.FGetCapacity: integer; begin Result:=FCapacity; end;
procedure TFileBuffer.FSetCapacity( Val: Integer ); //Var I: Integer;
begin if FCapacity<=Val then begin
      FCapacity:=Val+1024; Setlength( FData,Fcapacity ); //for I:=FCapacity+1 to Val do FData[I-1]:=255;
  end; end;

constructor TFileBuffer.Create;
      begin inherited Create; Clear; end;
procedure TFileBuffer.Clear;
    begin FCapacity:=0;   FCount:=0;
          FPosition:=0;   Setlength( FData,0 );
          FFileName:='';
    end;
destructor TFileBuffer.Destroy;
     begin Clear; inherited Destroy; end;
function TFileBuffer.GetPosition:integer;
   begin Result:=FPosition; end;

procedure TFileBuffer.LoadFromFile( Filename: String );
var DataLeft,Tmp,Size: integer;
begin
  FFileName:=Filename;
  AssignFile( FFile,Filename );
// TheStream:=TFileStream.Create( FileName,fmOpenRead or fmShareDenyWrite );
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
  Closefile( FFile );
  FFileName:='';
end;

// reset the data before reading
procedure TFileBuffer.Reset; begin FPosition:=0; end;

function TFileBuffer.SaveToFile( Filename: String ):boolean;
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

procedure TFileBuffer.Add( IntegerValue:Integer ); var Size:integer;
begin Size:=4; //SizeOf( Integer );
   if Count+Size>Capacity then Capacity:=Count+Size;
      Move( IntegerValue,FData[FCount],Size ); Inc( FCount,Size );
  end;                            // NtoLE( IntegerValue )=Indian swap bytes

procedure TFileBuffer.Add( FloatValue: Real );
const Size=4; {SizeOf( Single );} var W: Single;
begin W:=FloatValue;
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move( W,FData[FCount],Size );
  Inc( FCount,Size );
end;
procedure TFileBuffer.Add( Coordinate: Vector );
begin Add( Coordinate.X ); Add( Coordinate.Y ); Add( Coordinate.Z ); end;
procedure TFileBuffer.Add( Plane: Plate );
begin Add( Plane.a ); Add( Plane.b ); Add( Plane.c ); Add( Plane.d ); end;

procedure TFileBuffer.Add( Text: String ); var Size: integer;
begin                                 // convert text from UTF8 to Windows ANSI
  if St.Preferences.FbmEncoding<>'utf8' then
    Text:=ConvertEncoding( Text,'utf8',St.Preferences.FbmEncoding );
  Size:=Length( Text );
  Add( Size );
  if Size=0 then exit;
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move( Text[1],FData[FCount],Size );
  Inc(FCount,Size);
end;

procedure TFileBuffer.Add( BooleanValue: boolean );
const Size=1; //SizeOf( Boolean );
begin
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move( BooleanValue,FData[FCount],Size );
  Inc( FCount,Size );
end;

procedure TFileBuffer.Add( Ver: TFileVersion );
var Size: integer;
begin
  Version:=Ver;
  Size:=SizeOf(Version);
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move( Version,FData[FCount],Size );
  Inc( FCount,Size );
end;

procedure TFileBuffer.Add( JPegImage: TJPEGImage );
var Stream: TMemoryStream; Size: integer;
begin
  Add( JPEGImage.Width );
  Add( JPEGImage.Height );
  Stream:=TMemoryStream.Create;
  JPEGImage.SaveToStream( Stream );
  Size:=Stream.Size;
  Stream.Position:=0;
  Add( Size );
  if Count+Size+20>Capacity then Capacity:=Count+Size+20;
  Stream.Read( FData[FCount],Size );
  Inc(FCount,Size);
  Stream.Destroy;
end;

procedure TFileBuffer.LoadTJPEGImage(var JPegImage: TJPEGImage);
var Stream: TMemoryStream; W,H,Size: integer;
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
procedure TFileBuffer.LoadString( var Output: String );
var I,Size: integer; Ch: char; // S: String;
begin Output:='';
  if FPosition=0 then
  if (Integer(FData[0])<>9) and (Integer(FData[0])<>18) then exit;// 0-контроль
  LoadInteger( Size );
  for I:=1 to Size do begin
     Ch:=char( FData[FPosition] ); Inc( FPosition );
     Output:=Output+Ch;
  end;
  if St.Preferences.FbmEncoding<>'utf8' then
     Output:=ConvertEncoding( Output,St.Preferences.FbmEncoding,'utf8' );
end;

procedure TFileBuffer.LoadInteger( var Output: integer );
var Size: integer;
begin Size:=4; Output:=0;
  Move( FData[FPosition],Output,Size );
  Output:=LEtoN( Output );
  Inc( FPosition,Size );
end;

procedure TFileBuffer.LoadTFileVersion(var Output: TFileVersion);
var Size: integer;
begin
  Size:=SizeOf( Output );
  Move( FData[FPosition],Output,Size );
  Inc( FPosition,Size );
end;

procedure TFileBuffer.LoadBoolean( var Output: boolean ); const Size=1;
begin Output:=False; Move(FData[FPosition],Output,Size); Inc(FPosition,Size);
end;
procedure TFileBuffer.LoadTFloatType( var Output: Real );
const Size=sizeof( Single ); var W: Single=0.0;
begin Move( FData[FPosition],W,Size ); OutPut:=W; Inc( FPosition,Size );
end;
procedure TFileBuffer.LoadVector( var Output: Vector );
begin LoadTFloatType( OutPut.X );
      LoadTFloatType( OutPut.Y );
      LoadTFloatType( OutPut.Z );
end;
procedure TFileBuffer.LoadT3DPlane( var Output: Plate );
begin LoadTFloatType( OutPut.a );
      LoadTFloatType( OutPut.b );
      LoadTFloatType( OutPut.c );
      LoadTFloatType( OutPut.d );
end;
{
  TTextBuffer
  Text file used to store file info
}
constructor TTextBuffer.Create;
   begin FLines:=TStringList.Create; inherited Create; WestPoint; end;
function TTextBuffer.FGetCapacity: integer;
   begin Result:=FLines.Capacity; end;
procedure TTextBuffer.FSetCapacity( val: integer );
    begin FLines.Capacity:=val; end;
procedure TTextBuffer.Clear;
    begin if FLines<>nil then FLines.Clear; inherited Clear; end;
procedure TTextBuffer.Add(Text: String); var S: String;
    begin S:=ReplaceStr( Text,'\','\\' );
          S:=ReplaceStr( S,EOL,'\n' );
          FLines.Add( S );
          Inc( FPosition );
    end;
procedure TTextBuffer.Add(BooleanValue: boolean); var S: String;
    begin                    // if BooleanValue then S:='True' else S:='False';
      S:=BoolToStr( BooleanValue,'1','0' );
      FLines.Add( S );
      Inc( FPosition );
    end;
procedure TTextBuffer.Add( FloatValue: Real ); var S: String;
    begin S:=FloatTypeToStr( FloatValue ); FLines.Add(S); Inc(FPosition);
    end;
procedure TTextBuffer.Add( IntegerValue: integer );
    begin FLines.Add( I2S( IntegerValue ) ); Inc( FPosition );
    end;
procedure TTextBuffer.Add( Ver: TFileVersion ); const S: String='2.6';
    begin //Version:=Ver;
          //S:=VersionString( Version );   == функция скрыта в комментариях
      FLines.Add( S );
      Inc( FPosition );
    end;
procedure TTextBuffer.Add( Coordinate: Vector );
  var S: String;
begin S:=FloatTypeToStr( Coordinate.X )+' '
        +FloatTypeToStr( Coordinate.Y )+' '
        +FloatTypeToStr( Coordinate.Z ); FLines.Add(S); Inc(FPosition);
end;

procedure TTextBuffer.Add( Plane: Plate );
var S: String;
begin
  S:=FloatTypeToStr( Plane.a )+' '+FloatTypeToStr( Plane.b )+' '
    +FloatTypeToStr( Plane.c )+' '+FloatTypeToStr( Plane.d );
  FLines.Add( S );
  Inc(FPosition);
end;

procedure TTextBuffer.Add(JPegImage: TJPEGImage);
var Stream: TMemoryStream; Size: integer; S,P: PChar; L: String;
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

procedure TTextBuffer.LoadTJPEGImage(var JPegImage: TJPEGImage);
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

procedure TTextBuffer.LoadInteger( var Output: integer ); var S: String;
    begin S:=FLines[FPosition]; Output:=GetInteger( S ); Inc(FPosition);
    end;
procedure TTextBuffer.LoadString( var Output: String ); var S: String;
    begin S:=FLines[FPosition];
          S:=ReplaceStr( S,'\n',EOL );
          S:=ReplaceStr( S,'\\','\' );
          Output:=S;
          Inc( FPosition );
    end;
procedure TTextBuffer.LoadTFileVersion( var Output: TFileVersion );
    begin Output:=VersionBinary( FLines[FPosition] ); Inc( FPosition ); end;
procedure TTextBuffer.LoadBoolean(var Output: boolean);
    begin Output:=StrToBool( FLines[FPosition] );  Inc( FPosition ); end;
procedure TTextBuffer.LoadTFloatType( var Output: Real );
  var S: String;                       // LocalFormatSettings: TFormatSettings;
begin S:=FLines[FPosition]; Output:=GetFloat( S ); Inc( FPosition ); end;
procedure TTextBuffer.LoadVector( var Output: Vector );
  var S: String;
begin S:=FLines[FPosition]; Output:=GetVector( S ); Inc( FPosition ); end;

procedure TTextBuffer.LoadT3DPlane(var Output: Plate);
  var S: String;
begin S:=FLines[FPosition]; Output.a:=GetFloat( S );
                            Output.b:=GetFloat( S );
                            Output.c:=GetFloat( S );
                            Output.d:=GetFloat( S ); Inc( FPosition );
end;

// load string of words separated by spaces

destructor TTextBuffer.Destroy; begin Clear; inherited Destroy; end;

// reset the data before reading
procedure TTextBuffer.Reset; begin FPosition:=0; end;

procedure TTextBuffer.LoadFromFile( Filename: String );
   begin FFileName:=Filename; FLines.LoadFromFile(Filename,true); FPosition:=0;
   end;

function TTextBuffer.SaveToFile( Filename: String ):boolean;
   begin result:=false; FFileName:=Filename;
                        FLines.SaveToFile( Filename,true ); result:=true;
   end;

function TTextBuffer.GetPosition:integer; begin Result:=FPosition; end;

end.

