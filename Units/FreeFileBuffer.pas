unit FreeFileBuffer;
{$mode Delphi}{$H+}
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
//  TNameData=record N:integer; Name:AnsiString; end;
//  TLinearConstraintData=record N,LinearConstraintPointA,LinearConstraintPointB:integer; end;
//  TAnchorData=record N,AnchorPoint:integer; IsAnchorHard:boolean; end;
{---------------------------------------}
{                    TFreeFileBuffer    }
{ Binary stream used to store file info }
{---------------------------------------}
TFreeFileBuffer=class
  private
    FCapacity: integer; // Amount of bytes allocated
    FCount: integer;    // The amount of bytes actually used
    FPosition: integer; // current position when reading information from buffer
    FVersion: TFreeFileVersion;
    FData: array of byte;
    FFileName: AnsiString;
    FFile: file;
    procedure FSetCapacity(val: integer); virtual;
    function FGetCapacity: integer; virtual;
  public
    Encoding: String;
    procedure Add( IntegerValue: integer);     overload; virtual;
    procedure Add( Text: AnsiString);          overload; virtual;
    procedure Add( BooleanValue: boolean);     overload; virtual;
    procedure Add( FloatValue: TFloatType);    overload; virtual;
    procedure Add( Coordinate: T3DVector);     overload; virtual;
    procedure Add( Plane: T3DPlane);           overload; virtual;
    procedure Add( Version: TFreeFileVersion); overload; virtual;
    procedure Add(JPegImage: TJPEGImage); overload; virtual;
    procedure Add(Data: TFreeDelftSeriesResistanceData); overload; virtual; /// только
    procedure Add(Data: TFreeKAPERResistanceData); overload; virtual;       /// здесь
    procedure LoadInteger(var Output: integer); virtual;
    procedure LoadString(var Output: AnsiString); virtual;
    procedure LoadTStrings(var Output: TStrings); virtual;
    procedure LoadTFreeFileVersion(var Output: TFreeFileVersion); virtual;
    procedure LoadBoolean(var Output: boolean); virtual;
    procedure LoadTFloatType(var Output: TFloatType); virtual;
    procedure LoadT3DVector(var Output: T3DVector); virtual;
    procedure LoadT3DPlane(var Output: T3DPlane); virtual;
    procedure LoadTJPEGImage(var JPegImage: TJPEGImage); virtual;
    procedure LoadTFreeKAPERResistanceData(var Data: TFreeKAPERResistanceData); virtual;
    procedure LoadTFreeDelftSeriesResistanceData(var Data: TFreeDelftSeriesResistanceData); virtual;
//  procedure Add( Color: TColor; Alfa:byte ); overload; virtual;
//  procedure Add( words: TStrings);           overload; virtual;
//  procedure Add2(BooleanValue:Boolean);      overload; virtual;
//  procedure Add(WordValue:word);             overload; virtual;
//  procedure Add(NameData: TNameData);        overload; virtual;
//  procedure Add(AnchorData: TAnchorData);    overload; virtual;
//  procedure Add(LCData:TLinearConstraintData); overload; virtual;
//  procedure Add(const source;Size:Integer);  overload;virtual;
//  procedure Load( var Output:Word ); virtual;
//  procedure LoadTNameData(var NameData: TNameData); virtual;
//  procedure LoadTAnchorData(var AnchorData: TAnchorData); virtual;
//  procedure LoadTLinearConstraintData(var LCData: TLinearConstraintData); virtual;
// ?procedure Load(var Dest;Size:Integer); overload;virtual;
//  procedure LoadTColor( var Output: TColor {var Alfa: Byte} ); virtual;
    constructor Create;
    procedure Clear; virtual;
    procedure LoadFromFile(Filename: AnsiString); virtual;
    procedure Reset; virtual;                  // reset the data before reading
    function SaveToFile(Filename: AnsiString):boolean; virtual;
    function GetPosition:integer; virtual;
    destructor Destroy; override;
    property Capacity: integer read FGetCapacity write FSetCapacity;
    property Count: integer read FCount;
    property Version: TFreeFileVersion read FVersion write FVersion;
    property Position: integer read GetPosition;
  end;
  {-----------------------------------------------------------}
  {                                           TFreeTextBuffer }
  { Text file used to store file info                         }
  {-----------------------------------------------------------}
  TFreeTextBuffer=class( TFreeFileBuffer )
  private
    FLines: TStringList;
    FPosition: integer;    // this is our position
//  FormatSettings: TFormatSettings;
    function FGetCapacity: integer; override;
    procedure FSetCapacity( val: integer ); override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear; override;
    procedure Add(IntegerValue: integer); override; overload;
    procedure Add(Text: Ansistring); override; overload;
    procedure Add(BooleanValue: boolean); override; overload;
    procedure Add(FloatValue: TFloatType); override; overload;
    procedure Add(PVersion: TFreeFileVersion); override; overload;
    procedure Add(Coordinate: T3DVector); override; overload;
    procedure Add(Plane: T3DPlane); override; overload;
    procedure Add(JPegImage: TJPEGImage); override; overload;
    procedure LoadInteger(var Output: integer); override;
    procedure LoadString(var Output: Ansistring); override;
    procedure LoadTFreeFileVersion(var Output: TFreeFileVersion); override;
    procedure LoadBoolean(var Output: boolean); override;
    procedure LoadTFloatType(var Output: TFloatType); override;
    procedure LoadTStrings(var Output: TStrings); override;
    procedure LoadT3DVector(var Output: T3DVector); override;
    procedure LoadT3DPlane(var Output: T3DPlane); override;
    procedure LoadTJPEGImage(var JPegImage: TJPEGImage); override;
    procedure LoadFromFile(Filename: AnsiString); override;
    procedure Reset; override;                 // reset the data before reading
    function SaveToFile(Filename: AnsiString):boolean; override;
    function GetPosition:integer; override;
    property Capacity: integer read FGetCapacity write FSetCapacity;
    property Position: integer read GetPosition;
//  procedure Add( Color:TColor; Alfa:byte ); overload; overload;
//  procedure Add(words: TStrings); override; overload;
//  procedure Add(NameData: TNameData); override; overload;
//  procedure Add(LCData: TLinearConstraintData); override; overload;
//  procedure Add(const source;Size:Integer);     override;
//  procedure LoadTColor( var Output: TColor {var Alfa: Byte} ); override;
//  procedure LoadTNameData(var Output: TNameData); override;
//  procedure LoadTLinearConstraintData(var Output: TLinearConstraintData); override;
  end;


implementation

{---------------------------------------}
{ TFreeFileBuffer                       }
{ Binary stream used to store file info }
{---------------------------------------}

function TFreeFileBuffer.FGetCapacity: integer; begin Result:=FCapacity; end;
procedure TFreeFileBuffer.FSetCapacity( Val: Integer ); Var I: Integer;
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

procedure TFreeFileBuffer.LoadFromFile( Filename: AnsiString );
var DataLeft,Tmp,Size: integer;
begin
  FFileName:=Filename;
  AssignFile( FFile,Filename );
//TheStream:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
//try
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
//finally
    Closefile(FFile);
//end;
  FFileName:='';
end;

// reset the data before reading
procedure TFreeFileBuffer.Reset; begin FPosition:=0; end;

function TFreeFileBuffer.SaveToFile( Filename: AnsiString ):boolean;
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
{
procedure TFreeFileBuffer.Add( Color: TColor; Alfa:byte );
  var C: Cardinal; Size: Integer;
begin Size:=4; // SizeOf( Integer );
  C := ( Color and $FFFFFF ) or ( Cardinal( 255-Alfa ) shl 24 );
  if Count+Size > Capacity then Capacity:=Count+Size;
  Move( C,FData[FCount],Size );
  Inc( FCount,Size );              // NtoLE( IntegerValue )=Indian swap bytes
end;
                    // Destination.Add( (ProjectUnderWaterColor and $FFFFFF )
                   //  or (TColor( 255-ProjectUnderWaterColorAlpha ) shl 24) );
 *
procedure TFreeFileBuffer.Add(NameData: TNameData);
begin
  Add( NameData.N );    // integer
  Add( NameData.Name ); // string
end;
 *
procedure TFreeFileBuffer.Add(AnchorData: TAnchorData);
begin
  Add( AnchorData.N );
  Add( AnchorData.AnchorPoint );
  Add( AnchorData.IsAnchorHard );
end;
 *
procedure TFreeFileBuffer.Add(LCData: TLinearConstraintData);
begin
  Add(LCData.N);
  Add(LCData.LinearConstraintPointA);
  Add(LCData.LinearConstraintPointB);
end;
}
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

procedure TFreeFileBuffer.Add(Coordinate: T3DVector);
var
  Size: integer;
begin
  Size:=SizeOf(Coordinate);
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move(Coordinate,FData[FCount],Size);
  Inc(FCount,Size);
end;

procedure TFreeFileBuffer.Add(Plane: T3DPlane);
var Size: integer;
begin
  Size:=SizeOf(Plane);
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move(Plane,FData[FCount],Size);
  Inc(FCount,Size);
end;
procedure TFreeFileBuffer.Add(JPegImage: TJPEGImage);
var
  Stream: TMemoryStream;
  Size: integer;
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

/// !!!-на случай восстановления ~~~ c множеством перезагружаемых вызовов

procedure TFreeFileBuffer.LoadTFreeDelftSeriesResistanceData(var Data: TFreeDelftSeriesResistanceData);
  var bp: integer;
begin bp:=FPosition;
  with Data do begin
    LoadTFloatType(StartSpeed);
    LoadTFloatType(EndSpeed);
    LoadTFloatType(StepSpeed);
    LoadTFloatType(Bwl);
    LoadTFloatType(Cp);
    LoadTFloatType(Displacement);
    LoadTFloatType(Draft);
    LoadTFloatType(DraftTotal);
    LoadTFloatType(KeelChordLength);
    LoadTFloatType(KeelArea);
    LoadTFloatType(LCB);
    LoadTFloatType(Lwl);
    LoadTFloatType(RudderChordLength);
    LoadTFloatType(RudderArea);
    LoadTFloatType(Viscosity);
    LoadTFloatType(WettedSurface);
    LoadTFloatType(WlArea);
    LoadBoolean(EstimateWetSurf); // Structures are aligned to 2 bytes,so LoadTFreeMHSeriesResistanceData Boolean as Word
    LoadBoolean( Extract );
  end;
  FPosition:=bp+sizeof(Data); //record data can be aligned
end;

procedure TFreeFileBuffer.LoadTFreeKAPERResistanceData(var Data: TFreeKAPERResistanceData);
  var bp: integer;
begin bp:=FPosition;
  with Data do begin
    LoadTFloatType(Draft);
    LoadTFloatType(Lwl);
    LoadTFloatType(Bwl);
    LoadTFloatType(Cp);
    LoadTFloatType(Displacement);
    LoadTFloatType(LCB);
    LoadTFloatType(WettedSurface);
    LoadTFloatType(At_Ax);
    LoadTFloatType(EntranceAngle);
    LoadBoolean( Extract );
  end;
  FPosition:=bp+sizeof( Data ); //record data can be aligned
end;

////////// Add

procedure TFreeFileBuffer.Add( Data: TFreeDelftSeriesResistanceData );
var Size: integer=sizeof( Data ); bp: integer;
begin
  bp:=FCount;
  if Count+Size>Capacity then Capacity:=Count+Size;
  with Data do begin
    Add(StartSpeed);
    Add(EndSpeed);
    Add(StepSpeed);
    Add(Bwl);
    Add(Cp);
    Add(Displacement);
    Add(Draft);
    Add(DraftTotal);
    Add(KeelChordLength);
    Add(KeelArea);
    Add(LCB);
    Add(Lwl);
    Add(RudderChordLength);
    Add(RudderArea);
    Add(Viscosity);
    Add(WettedSurface);
    Add(WlArea);
    Add(EstimateWetSurf);
    Add(Extract);
  end;
  FCount:=bp+Size;
end;

procedure TFreeFileBuffer.Add(Data: TFreeKAPERResistanceData);
var Size: integer=sizeof( Data ); bp: integer;
begin
  bp:=FCount;
  if Count+Size>Capacity then Capacity:=Count+Size;
  with Data do begin
    Add( Draft );
    Add( Lwl );
    Add( Bwl );
    Add( Cp );
    Add( Displacement );
    Add( LCB );
    Add( WettedSurface );
    Add( At_Ax );
    Add( EntranceAngle );
    Add( Extract );
  end;
  FCount:=bp+Size;
end;

procedure TFreeFileBuffer.LoadString( var Output: AnsiString );
var I,Size: integer; Ch: char; // S: AnsiString;
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
{
// MM: This may be not endiness safe. Will replace it typed
procedure TFreeFileBuffer.Add(const source;Size:Integer);
var S: PChar;
    I: Integer;
begin
   S:=PChar(@Source);
   if Count+Size+20>Capacity then Capacity:=Count+Size+20;
   for I:=0 to size-1 do begin FData[FCount]:=Byte(S[I]); Inc(FCount); end;
end;
~~~
procedure TFreeFileBuffer.LoadTColor( var Output: TColor ); Var Size: integer;
begin Size:=4; Output:=0;              //if FPosition+Size >= FCount then exit;
  Move( FData[FPosition],Output,Size );
  Output:=LEtoN( Output );
  Inc( FPosition,Size );
end;
---
procedure TFreeFileBuffer.LoadTColor( var Output: TColor; var Alfa: Byte );
var Size: integer; Color: Cardinal;
begin
  Size:=4; Color:=0;                   //if FPosition+Size >= FCount then exit;
  Move( FData[FPosition],Color,Size );
//Color:=LEtoN( Color );
  Alfa := 255-Byte( Color shr 24 );
  OutPut:=Color and $FFFFFF;
  Inc( FPosition,Size );
end;
}
procedure TFreeFileBuffer.LoadTStrings(var Output: TStrings);
var i,c: integer; S:AnsiString;
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

procedure TFreeFileBuffer.LoadBoolean(var Output: boolean);
var
  Size: integer;
begin
  Size:=1;
  Output:=False;                   //if FPosition+Size >= FCount then exit;
  Move(FData[FPosition],Output,Size);
  Inc( FPosition,Size );
end;
(*
procedure TFreeFileBuffer.LoadTNameData(var NameData: TNameData);
begin
  LoadInteger(NameData.N);
  LoadString(NameData.Name);
end;
*
procedure TFreeFileBuffer.LoadTAnchorData(var AnchorData: TAnchorData);
begin
  LoadInteger(AnchorData.N);
  LoadInteger(AnchorData.AnchorPoint);
  LoadBoolean(AnchorData.IsAnchorHard);
end;
 *
procedure TFreeFileBuffer.LoadTLinearConstraintData(var LCData: TLinearConstraintData);
begin
  LoadInteger(LCData.N);
  LoadInteger(LCData.LinearConstraintPointA);
  LoadInteger(LCData.LinearConstraintPointB);
end;
*)
procedure TFreeFileBuffer.LoadTFloatType(var Output: TFloatType);
var
  Size: integer;
begin
  Size:=SizeOf(Output);
  Output:=0.0;                     //if FPosition+Size >= FCount then exit;
  Move( FData[FPosition],Output,Size );
  Inc(FPosition,Size);
end;

procedure TFreeFileBuffer.LoadT3DVector(var Output: T3DVector);
var Size: integer;
begin
  Size:=SizeOf(Output);
  Output:=ZERO;                    //if FPosition+Size >= FCount then exit;
  Move(FData[FPosition],Output,Size);
  Inc(FPosition,Size);
end;

procedure TFreeFileBuffer.LoadT3DPlane(var Output: T3DPlane);
var Size: integer;
begin
  Size:=SizeOf( Output );            //if FPosition+Size >= FCount then exit;
  Move(FData[FPosition],Output,Size);
  Inc(FPosition,Size);
end;

procedure TFreeFileBuffer.Add( Text: AnsiString );
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
var
  Size: integer;
begin
  Size:=1;//SizeOf(BooleanValue);
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move(BooleanValue,FData[FCount],Size);
  Inc(FCount,Size);
end;

procedure TFreeFileBuffer.Add( FloatValue: TFloatType );
  var Size: integer;
begin Size:=SizeOf( FloatValue );
  if Count+Size>Capacity then Capacity:=Count+Size;
  Move( FloatValue,FData[FCount],Size );
  Inc( FCount,Size );
end;
(*
procedure TFreeFileBuffer.Add( words: TStrings ); Var I: Integer;
    begin Add( words.Count ); for i:=0 to words.Count-1 do Add( words[i] );
    end;
*)
{-----------------------------------------------------------------------------}
{                                           TFreeTextBuffer                   }
{                                           Text file used to store file info }
{-----------------------------------------------------------------------------}
constructor TFreeTextBuffer.Create;
begin FLines:=TStringList.Create; inherited Create; WestPoint; end;

function TFreeTextBuffer.FGetCapacity: integer;
   begin Result:=FLines.Capacity; end;
procedure TFreeTextBuffer.FSetCapacity( val: integer );
    begin FLines.Capacity:=val; end;
procedure TFreeTextBuffer.Clear;
    begin if FLines<>nil then FLines.Clear; inherited Clear; end;

procedure TFreeTextBuffer.Add(Text: Ansistring); var S: AnsiString;
begin
  S:=ReplaceStr( Text,'\','\\' );
  S:=ReplaceStr( S,EOL,'\n' );
  FLines.Add( S );
  Inc( FPosition );
end;

procedure TFreeTextBuffer.Add(BooleanValue: boolean); var S: AnsiString;
begin                        // if BooleanValue then S:='True' else S:='False';
  S:=BoolToStr( BooleanValue,'1','0' );
  FLines.Add( S );
  Inc( FPosition );
end;

procedure TFreeTextBuffer.Add( FloatValue: TFloatType ); var S: AnsiString;
begin S:=FloatTypeToStr( FloatValue ); FLines.Add(S); Inc(FPosition); end;

procedure TFreeTextBuffer.Add( IntegerValue: integer );
    begin FLines.Add( I2S( IntegerValue ) ); Inc( FPosition );
    end;
procedure TFreeTextBuffer.Add( PVersion: TFreeFileVersion ); var S: AnsiString;
    begin FVersion:=PVersion;
      S:=VersionString( PVersion );
      FLines.Add( S );
      Inc( FPosition );
    end;
(*
procedure TFreeTextBuffer.Add( Color: TColor; Alfa:byte );
  var C: Cardinal; S: AnsiString;
begin
  C := Cardinal( Color and $FFFFFF ) + ( Cardinal( 255-Alfa ) shl 24 );
  S:=UIntToStr( C ); FLines.Add( S ); Inc( FPosition );
end;
procedure TFreeTextBuffer.Add( Words: TStrings );
  var I: integer; S: AnsiString;
begin S:='';
      if words.Count > 0 then S:=words[0];
      for i:=1 to words.Count-1 do S:=S+' '+words[i];
      FLines.Add(S);
      Inc( FPosition );
end;
 *
procedure TFreeTextBuffer.Add( NameData: TNameData );
var S: AnsiString;
begin
  S:=IntToStr(NameData.N)+' '+NameData.Name;
  FLines.Add(S);
  Inc(FPosition);
end;
 *
procedure TFreeTextBuffer.Add(LCData: TLinearConstraintData);
var S: AnsiString;
begin
  S:=IntToStr( LCData.N ) +' '+IntToStr( LCData.LinearConstraintPointA )
                          +' '+IntToStr( LCData.LinearConstraintPointB );
  FLines.Add(S);
  Inc(FPosition);
end;
*)
procedure TFreeTextBuffer.Add( Coordinate: T3DVector );
  var S: AnsiString;
begin S:=FloatTypeToStr( Coordinate.X )+' '
        +FloatTypeToStr( Coordinate.Y )+' '
        +FloatTypeToStr( Coordinate.Z ); FLines.Add(S); Inc(FPosition);
end;

procedure TFreeTextBuffer.Add(Plane: T3DPlane);
var S: AnsiString;
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
  L: AnsiString;
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

procedure TFreeTextBuffer.LoadInteger( var Output: integer ); var S: AnsiString;
    begin S:=FLines[FPosition];
      Output:=GetInteger( S ); //StrToInt( S );
      Inc(FPosition);
    end;
{
procedure TFreeTextBuffer.LoadTColor( var Output: TColor ); var S: AnsiString;
    begin S:=FLines[FPosition];
      Output:=GetInteger( S ) ;//StrToUInt( S );
      Inc(FPosition);
    end;
-------
procedure TFreeTextBuffer.LoadTColor( var Output: TColor; var Alfa: Byte );
  var S: AnsiString; Color: Cardinal;
begin S:=FLines[FPosition];
      Color:=StrToUInt( S );
      Alfa := 255-Byte( Color shr 24 );
      OutPut:=Color and $FFFFFF;
      Inc(FPosition);
end;
}
procedure TFreeTextBuffer.LoadString( var Output: AnsiString );
var S: AnsiString;
begin
   S:=FLines[FPosition];
   S:=ReplaceStr(S,'\n',EOL);
   S:=ReplaceStr(S,'\\','\');
   Output:=S;                //!!! Output:=ConvertEncoding(S,FEncoding,'utf8');
   Inc( FPosition );
end;
procedure TFreeTextBuffer.LoadTFreeFileVersion( var Output: TFreeFileVersion );
var S: AnsiString;
begin S:=FLines[FPosition]; Output:=VersionBinary( S ); Inc( FPosition );
end;

procedure TFreeTextBuffer.LoadBoolean(var Output: boolean);
var S: AnsiString;
begin S:=FLines[FPosition]; Output:=StrToBool( S );  Inc( FPosition );
end;

procedure TFreeTextBuffer.LoadTFloatType( var Output: TFloatType );
  var S: AnsiString;                   // LocalFormatSettings: TFormatSettings;
begin S:=FLines[FPosition]; Output:=GetFloat( S ); Inc( FPosition );
end;
(*
procedure TFreeTextBuffer.LoadTJPEGImage(var Output: TColor);
var S: AnsiString;
begin
  S:=FLines[FPosition];
  Output:=StrToInt(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.LoadTNameData(var Output: TNameData);
var  p:integer; S: AnsiString;
begin
  S:=FLines[FPosition];
  p:=pos(' ',S);
  Output.N:=StrToInt(copy(S,1,p-1));
  Output.Name:=copy(S,p+1,length(S));
  Inc( FPosition );
end;

procedure TFreeTextBuffer.LoadTLinearConstraintData(var Output: TLinearConstraintData);
var  S: AnsiString;
begin
  S:=FLines[FPosition];
  Output.N:=GetInteger( S );                      // StrToInt(ExtractWord(1,S,[' ']));
  Output.LinearConstraintPointA:=GetInteger( S ); // StrToInt(ExtractWord(2,S,[' ']));
  Output.LinearConstraintPointB:=GetInteger( S ); // StrToInt(ExtractWord(3,S,[' ']));
  Inc( FPosition );
end;
*)
procedure TFreeTextBuffer.LoadT3DVector(var Output: T3DVector);
var S: AnsiString;
begin
  S:=FLines[FPosition];
  Output.X:=GetFloat( S ); // ExtractWord(1,S,[' ']));
  Output.Y:=GetFloat( S ); // ExtractWord(2,S,[' ']));
  Output.Z:=GetFloat( S ); // ExtractWord(3,S,[' ']));
  Inc( FPosition );
end;

procedure TFreeTextBuffer.LoadT3DPlane(var Output: T3DPlane);
var S: AnsiString;
begin
  S:=FLines[FPosition];
  Output.a:=GetFloat( S ); // ExtractWord(1,S,[' ']));
  Output.b:=GetFloat( S ); // ExtractWord(2,S,[' ']));
  Output.c:=GetFloat( S ); // ExtractWord(3,S,[' ']));
  Output.d:=GetFloat( S ); // ExtractWord(4,S,[' ']));
  Inc( FPosition );
end;

// load string of words separated by spaces
procedure TFreeTextBuffer.LoadTStrings(var Output: TStrings);
var  I:integer; S,V: AnsiString; //SS:TStrings;
begin S:=FLines[FPosition]; I:=1;
  while true do begin V:=ExtractWord(i,S,[' ']);
    if V='' then break;
    Output.Add( V );
    inc( I );
  end;
  Inc(FPosition);
end;

destructor TFreeTextBuffer.Destroy; begin Clear; inherited Destroy; end;

procedure TFreeTextBuffer.LoadFromFile( Filename: AnsiString );
begin
  FFileName:=Filename;
  FLines.LoadFromFile( Filename );
  FPosition:=0;
end;

// reset the data before reading
procedure TFreeTextBuffer.Reset; begin FPosition:=0; end;

function TFreeTextBuffer.SaveToFile(Filename: AnsiString):boolean;
begin
  result:=false;
  FFileName:=Filename;
  FLines.SaveToFile(Filename);
  result:=true;
end;

function TFreeTextBuffer.GetPosition:integer; begin Result:=FPosition; end;

end.
(*
procedure Add(ColorValue: TColor); overload; virtual;
procedure Add(ColorValue: TColor); overload; virtual;
procedure TFreeFileBuffer.Add( ColorValue: TColor );
var Size: integer;
begin
  Size:=4; //SizeOf(TColor);
  if Count+Size > Capacity then FGrow(Size);
  Move( ColorValue,FData[FCount],Size );
  Inc(FCount,Size);
end;
procedure TFreeTextBuffer.Add( ColorValue: TColor );
var S: AnsiString;
begin
  S:='$'+HexStr(ColorValue,8); FLines.Add(S); Inc(FPosition);
end;
procedure LoadColor(var Output: TColor); virtual;
procedure LoadColor(var Output: TColor); virtual;  StringToColor(...
*)
