
unit FreeFileBuffer;

{ $mode objfpc}
{$mode Delphi}

interface

uses
  Classes,
  SysUtils,
  Graphics,
  StrUtils,
  FreeTypes,
  LConvEncoding,
  FreeVersionUnit;

const FileBufferBlockSize = 4096;
// used for reading and writing files using TFilebuffer

type
  TNameData = record N:integer; Name:String; end;
  TLinearConstraintData = record N, LinearConstraintPointA, LinearConstraintPointB:integer; end;
  TAnchorData = record N, AnchorPoint:integer; IsAnchorHard:boolean; end;

  {----------------------------------------------------------------------------}
  {                    TFreeFileBuffer                                         }
  { Binary stream used to store file info                                      }
  {----------------------------------------------------------------------------}
  TFreeFileBuffer = class
private
    FCapacity: integer; // Amount of bytes allocated
    FCount: integer;    // The amount of bytes actually used
    FPosition: integer; // current position when reading information from buffer
    FVersion: TFreeFileVersion;
    FData: array of byte;
    FFileName: string;
    FFile: file;
    FEncoding: string;
    procedure FGrow(size: integer);
    procedure FSetCapacity(val: integer); virtual;
    function FGetCapacity: integer; virtual;
  public
    procedure Add(IntegerValue: integer);      overload; virtual;
    procedure Add(Text: string);               overload; virtual;
    procedure Add(BooleanValue: boolean);      overload; virtual;
//  procedure Add2(BooleanValue:Boolean);        overload;virtual;
    procedure Add(FloatValue: TFloatType);     overload; virtual;
    procedure Add(words: TStrings);            overload; virtual;
//  procedure Add(WordValue:word);               overload;virtual;
    procedure Add(Version: TFreeFileVersion);  overload; virtual;
    procedure Add(Coordinate: T3DCoordinate);      overload; virtual;
    procedure Add(NameData: TNameData);                overload; virtual;
    procedure Add(AnchorData: TAnchorData);                overload; virtual;
    procedure Add(LCData: TLinearConstraintData);      overload; virtual;
    procedure Add(Plane: T3DPlane);                overload; virtual;
    procedure Add(Data: TFreeDelftSeriesResistanceData);      overload; virtual;
    procedure Add(Data: TFreeKAPERResistanceData);            overload; virtual;
//  procedure Add(const source;Size:Integer);    overload;virtual;
    procedure Add(JPegImage: TJPEGImage);      overload; virtual;

    procedure LoadInteger(var Output: integer);    virtual;
    procedure LoadString(var Output: string);      virtual;
//  procedure Load(var Output:Word);           virtual;
    procedure LoadTStrings(var Output: TStrings);        virtual;
    procedure LoadTFreeFileVersion(var Output: TFreeFileVersion);      virtual;
    procedure LoadBoolean(var Output: boolean);      virtual;
    procedure LoadTColor(var Output: TColor); virtual;
    procedure LoadTNameData(var NameData: TNameData); virtual;
    procedure LoadTAnchorData(var AnchorData: TAnchorData);  virtual;
    procedure LoadTLinearConstraintData(var LCData: TLinearConstraintData);  virtual;
    procedure LoadTFloatType(var Output: TFloatType);       virtual;
    procedure LoadT3DCoordinate(var Output: T3DCoordinate);       virtual;
    procedure LoadT3DPlane(var Output: T3DPlane);       virtual;
    procedure LoadTJPEGImage(var JPegImage: TJPEGImage);       virtual;
    procedure LoadTFreeKAPERResistanceData(var Data: TFreeKAPERResistanceData); virtual;
    procedure LoadTFreeDelftSeriesResistanceData(var Data: TFreeDelftSeriesResistanceData); virtual;
// ?procedure Load(var Dest;Size:Integer); overload;virtual;
    constructor Create;
    procedure Clear; virtual;
    procedure LoadFromFile(Filename: string); virtual;
    procedure Reset; virtual;                  // reset the data before reading
    function SaveToFile(Filename: string):boolean; virtual;
    function GetPosition:integer; virtual;
    destructor Destroy; override;
    property Capacity: integer read FGetCapacity write FSetCapacity;
    property Count: integer read FCount;
    property Version: TFreeFileVersion read FVersion write FVersion;
    property Position: integer read GetPosition;
    property Encoding: string read FEncoding write FEncoding;
  end;
  {---------------------------------------------------------------------------------------------------}
  {                                           TFreeTextBuffer                                         }
  { Text file used to store file info                                                                 }
  {---------------------------------------------------------------------------------------------------}
  TFreeTextBuffer = class(TFreeFileBuffer)
  private
    FLines: TStringList;
    FPosition: integer; // this is our position
    FormatSettings: TFormatSettings;
    procedure FSetCapacity(val: integer); override;
    function FGetCapacity: integer; override;
  public
    constructor Create;
    Function StrToFloatType(Const S : String) : TFloatType;
//  Function FloatTypeToStr(Value: TFloatType): String;
    procedure Add(IntegerValue: integer); override; overload;
    procedure Add(Text: string); override; overload;
    procedure Add(BooleanValue: boolean); override; overload;
    procedure Add(FloatValue: TFloatType); override; overload;
    procedure Add(words: TStrings); override; overload;
    procedure Add(PVersion: TFreeFileVersion); override; overload;
    procedure Add(NameData: TNameData); override; overload;
    procedure Add(LCData: TLinearConstraintData); override; overload;
    procedure Add(Coordinate: T3DCoordinate); override; overload;
    procedure Add(Plane: T3DPlane); override; overload;
//  procedure Add(const source;Size:Integer);     override;
    procedure Add(JPegImage: TJPEGImage); override; overload;

    procedure LoadInteger(var Output: integer); override;
    procedure LoadString(var Output: string); override;
    procedure LoadTFreeFileVersion(var Output: TFreeFileVersion); override;
    procedure LoadBoolean(var Output: boolean); override;
    procedure LoadTColor(var Output: TColor); override;
    procedure LoadTFloatType(var Output: TFloatType); override;
    procedure LoadTStrings(var Output: TStrings); override;
    procedure LoadTNameData(var Output: TNameData); override;
    procedure LoadTLinearConstraintData(var Output: TLinearConstraintData); override;
//  procedure LoadTFreeMHSeriesResistanceData(var Output: TColor); override;
    procedure LoadT3DCoordinate(var Output: T3DCoordinate); override;
    procedure LoadT3DPlane(var Output: T3DPlane); override;
    procedure LoadTJPEGImage(var JPegImage: TJPEGImage); override;
//  procedure LoadTFreeMHSeriesResistanceData(var Dest;Size:Integer); override;

    procedure Clear; override;
    procedure LoadFromFile(Filename: string); override;
    procedure Reset; override;                 // reset the data before reading
    function SaveToFile(Filename: string):boolean; override;
    function GetPosition:integer; override;
    destructor Destroy; override;
    property Capacity: integer read FGetCapacity write FSetCapacity;
    property Position: integer read GetPosition;
  end;


implementation

{---------------------------------------}
{ TFreeFileBuffer                       }
{ Binary stream used to store file info }
{---------------------------------------}

procedure TFreeFileBuffer.FGrow(size: integer);
var AmountToGrow: integer;
begin
  AmountToGrow := 1024;
  if Size > AmountToGrow then AmountToGrow := Size;
  Capacity := Capacity + AmountToGrow;
end;

function TFreeFileBuffer.FGetCapacity: integer;
begin Result := FCapacity; end;

procedure TFreeFileBuffer.FSetCapacity(val: integer);
var I: integer;
begin
  Setlength(FData, Val);
  for I := FCapacity + 1 to Val do FData[I - 1] := 255;
  FCapacity := Val;
end;

procedure TFreeFileBuffer.Add( IntegerValue: integer );
var Size: integer;
begin
  Size := 4; //SizeOf(Integer);
  if Count + Size > Capacity then FGrow(Size);
  Move( NtoLE(IntegerValue), FData[FCount], Size );
  Inc(FCount, Size);
end;

procedure TFreeFileBuffer.Add(NameData: TNameData);
begin
  Add( NameData.N );
  Add( NameData.Name );
end;

procedure TFreeFileBuffer.Add(AnchorData: TAnchorData);
begin
  Add( AnchorData.N );
  Add( AnchorData.AnchorPoint );
  Add( AnchorData.IsAnchorHard );
end;

procedure TFreeFileBuffer.Add(LCData: TLinearConstraintData);
begin
  Add(LCData.N);
  Add(LCData.LinearConstraintPointA);
  Add(LCData.LinearConstraintPointB);
end;


procedure TFreeFileBuffer.Add(Version: TFreeFileVersion);
var
  Size: integer;
begin
  FVersion := Version;
  Size := SizeOf(Version);
  if Count + Size > Capacity then FGrow(Size);
  Move(Version, FData[FCount], Size);
  Inc(FCount, Size);
end;

procedure TFreeFileBuffer.Add(Coordinate: T3DCoordinate);
var
  Size: integer;
begin
  Size := SizeOf(Coordinate);
  if Count + Size > Capacity then FGrow(Size);
  Move(Coordinate, FData[FCount], Size);
  Inc(FCount, Size);
end;

procedure TFreeFileBuffer.Add(Plane: T3DPlane);
var Size: integer;
begin
  Size := SizeOf(Plane);
  if Count + Size > Capacity then FGrow(Size);
  Move(Plane, FData[FCount], Size);
  Inc(FCount, Size);
end;
{
// MM: This may be not endiness safe. Will replace it typed
procedure TFreeFileBuffer.Add(const source;Size:Integer);
var S: PChar;
    I: Integer;
begin
   S:=PChar(@Source);
   if Count+Size>Capacity then FGrow(Size);
   for I := 0 to size-1 do
   begin
      FData[FCount]:=Byte(S[I]); Inc(FCount);
   end;
end;
}
procedure TFreeFileBuffer.Add(JPegImage: TJPEGImage);
var
  Stream: TMemoryStream;
  Size: integer;
begin
  Add(JPEGImage.Width);
  Add(JPEGImage.Height);
  Stream := TMemoryStream.Create;
  JPEGImage.SaveToStream(Stream);
  Size := Stream.Size;
  Stream.Position := 0;
  Add(Size);
  if Count + Size + 20 > Capacity then FGrow( Size+20 );
  Stream.Read(FData[FCount], Size);
  Inc(FCount, Size);
  FreeAndNil(Stream);
end;

procedure TFreeFileBuffer.LoadTJPEGImage(var JPegImage: TJPEGImage);
var
  Stream: TMemoryStream;
  W, H, Size: integer;
begin
  LoadInteger(W);
  LoadInteger(H);
  LoadInteger(Size);
  Stream := TMemoryStream.Create;
  Stream.SetSize(Size);
  Stream.Write(FData[FPosition], Size);
  Inc(FPosition, Size);
  Stream.Position := 0;
  JPEGImage.LoadFromStream(Stream);
  FreeAndNil(Stream);
end;

/// !!! - на случай восстановления

procedure TFreeFileBuffer.LoadTFreeDelftSeriesResistanceData(var Data: TFreeDelftSeriesResistanceData);
  var bp: integer;
begin bp := FPosition;
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
    LoadBoolean(EstimateWetSurf); // Structures are aligned to 2 bytes, so LoadTFreeMHSeriesResistanceData Boolean as Word
    LoadBoolean( Extract );
  end;
  FPosition := bp + sizeof(Data); //record data can be aligned
end;

procedure TFreeFileBuffer.LoadTFreeKAPERResistanceData(var Data: TFreeKAPERResistanceData);
  var bp: integer;
begin bp := FPosition;
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
  FPosition := bp + sizeof( Data ); //record data can be aligned
end;

////////// Add

procedure TFreeFileBuffer.Add( Data: TFreeDelftSeriesResistanceData );
var Size: integer = sizeof( Data ); bp: integer;
begin
  bp := FCount;
  if Count + Size > Capacity then FGrow( Size );
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
  FCount := bp + Size;
end;

procedure TFreeFileBuffer.Add(Data: TFreeKAPERResistanceData);
var Size: integer = sizeof( Data ); bp: integer;
begin
  bp := FCount;
  if Count + Size > Capacity then FGrow(Size);
  with Data do begin
    Add(Draft);
    Add(Lwl);
    Add(Bwl);
    Add(Cp);
    Add(Displacement);
    Add(LCB);
    Add(WettedSurface);
    Add(At_Ax);
    Add(EntranceAngle);
    Add(Extract);
  end;
  FCount := bp + Size;
end;

procedure TFreeFileBuffer.LoadString( var Output: string );
var
  I, Size: integer;
  Ch: char;   S: string;
begin
  Output:='';
  if (FPosition=0) and (Integer(FData[0])<>9) then exit;
  LoadInteger( Size );               //if FPosition + Size >= FCount then exit;
  for I := 1 to Size do begin
     Ch := char( FData[FPosition] ); Inc(FPosition);
     Output := Output + Ch;
  end;
  S:=Output;
     Output:=ConvertEncoding( S,FEncoding,'utf8' );
end;

procedure TFreeFileBuffer.LoadInteger( var Output: integer );
var
  Size: integer;
begin
  Size := 4;
  Output := 0;                       //if FPosition + Size >= FCount then exit;
  Move( FData[FPosition], Output, Size );
  Output := LEtoN(Output);
  Inc(FPosition, Size);
end;

procedure TFreeFileBuffer.LoadTColor(var Output: TColor);
var
  Size: integer;
begin
  Size := 4;
  Output := 0;                       //if FPosition + Size >= FCount then exit;
  Move(FData[FPosition], Output, Size);
  Output := LEtoN(Output);
  Inc(FPosition, Size);
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
  Size := SizeOf( Output );         //if FPosition + Size >= FCount then exit;
  Move( FData[FPosition], Output,Size );
  Inc( FPosition,Size );
end;

procedure TFreeFileBuffer.LoadBoolean(var Output: boolean);
var
  Size: integer;
begin
  Size := 1;
  Output := False;                   //if FPosition + Size >= FCount then exit;
  Move(FData[FPosition], Output, Size);
  Inc( FPosition, Size );
end;

procedure TFreeFileBuffer.LoadTNameData(var NameData: TNameData);
begin
  LoadInteger(NameData.N);
  LoadString(NameData.Name);
end;

procedure TFreeFileBuffer.LoadTAnchorData(var AnchorData: TAnchorData);
begin
  LoadInteger(AnchorData.N);
  LoadInteger(AnchorData.AnchorPoint);
  LoadBoolean(AnchorData.IsAnchorHard);
end;

procedure TFreeFileBuffer.LoadTLinearConstraintData(var LCData: TLinearConstraintData);
begin
  LoadInteger(LCData.N);
  LoadInteger(LCData.LinearConstraintPointA);
  LoadInteger(LCData.LinearConstraintPointB);
end;

procedure TFreeFileBuffer.LoadTFloatType(var Output: TFloatType);
var
  Size: integer;
begin
  Size := SizeOf(Output);
  Output := 0.0;                     //if FPosition + Size >= FCount then exit;
  Move( FData[FPosition], Output, Size );
  Inc(FPosition, Size);
end;

procedure TFreeFileBuffer.LoadT3DCoordinate(var Output: T3DCoordinate);
var
  Size: integer;
begin
  Size := SizeOf(Output);
  Output := ZERO;                    //if FPosition + Size >= FCount then exit;
  Move(FData[FPosition], Output, Size);
  Inc(FPosition, Size);
end;

procedure TFreeFileBuffer.LoadT3DPlane(var Output: T3DPlane);
var
  Size: integer;
begin
  Size := SizeOf( Output );          //if FPosition + Size >= FCount then exit;
  Move(FData[FPosition], Output, Size);
  Inc(FPosition, Size);
end;

procedure TFreeFileBuffer.Add(Text: string);
var
  Size: integer;
begin   // convert text from UTF8 to Windows ANSI
  Text:=ConvertEncoding(Text,'utf8',FEncoding);
  Size := Length(Text);
  Add(Size);
  if Size = 0 then exit;
  if Count + Size > Capacity then FGrow(Size);
  Move(Text[1], FData[FCount], Size);
  Inc(FCount, Size);
end;

procedure TFreeFileBuffer.Add(BooleanValue: boolean);
var
  Size: integer;
begin
  Size := 1;//SizeOf(BooleanValue);
  if Count + Size > Capacity then
    FGrow(Size);
  Move(BooleanValue, FData[FCount], Size);
  Inc(FCount, Size);
end;

procedure TFreeFileBuffer.Add(FloatValue: TFloatType);
var
  Size: integer;
begin
  Size := SizeOf(FloatValue);
  if Count + Size > Capacity then
    FGrow(Size);
  Move(FloatValue, FData[FCount], Size);
  Inc(FCount, Size);
end;

procedure TFreeFileBuffer.Add(words: TStrings);
var i: integer;
begin Add( words.Count ); for i:=0 to words.Count-1 do Add(words[i]);
end;

constructor TFreeFileBuffer.Create;
begin inherited Create; Clear;
end;

procedure TFreeFileBuffer.Clear;
begin
  FCapacity := 0;
  FCount := 0;
  FPosition := 0;
  Setlength(FData, 0);
  FFileName := '';
  FEncoding := 'cp1252';
end;

destructor TFreeFileBuffer.Destroy;
begin Clear; inherited Destroy; end;

procedure TFreeFileBuffer.LoadFromFile( Filename: string );
var
  DataLeft: integer;
  Tmp: integer;
  Size: integer;
begin
  FFileName := Filename;
  AssignFile( FFile, Filename );
//TheStream:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
//try
    system.FileMode := fmOpenRead;
    system.Reset( FFile,1 );
    FCount := 0;
    DataLeft := FileSize( FFile );
    Capacity := DataLeft;
    FPosition := 0;
//  if DataLeft < 0 then exit;
    while DataLeft > 0 do begin
      if DataLeft < FileBufferBlockSize then Size:=DataLeft
                                        else Size:=FileBufferBlockSize;
      BlockRead( FFile,FData[FCount],Size,Tmp );
      Dec( DataLeft,Tmp );
      Inc( FCount, Tmp );
    end;
//finally
    Closefile(FFile);
//end;
  FFileName := '';
end;

// reset the data before reading
procedure TFreeFileBuffer.Reset;
begin
  FPosition := 0;
end;{TFreeFileBuffer.Reset}

function TFreeFileBuffer.SaveToFile(Filename: string):boolean;
var
  DataWritten: integer;
  DataLeft: integer;
  Tmp: integer;
  Size: integer;
begin
  result:=false;
  FFileName := Filename;
//try
    AssignFile( FFile, Filename );
    Rewrite( FFile, 1 );
    DataWritten := 0;
    DataLeft := Count;
    while DataWritten < Count do begin
      if DataLeft < FileBufferBlockSize then Size := DataLeft
                                        else Size := FileBufferBlockSize;
      BlockWrite( FFile,FData[DataWritten],Size,Tmp );
      Dec( DataLeft, Tmp );
      Inc( DataWritten,Tmp );
    end;
//finally
    Closefile( FFile );
//end;
  FFileName := '';
  result:=true;
end;

function TFreeFileBuffer.GetPosition:integer;
begin Result:=FPosition;
end;

{-------------------------------------}
{ TFreeTextBuffer                     }
{ Text file used to store file info   }
{-------------------------------------}
constructor TFreeTextBuffer.Create;
var sdf: String;
begin
  FLines := TStringList.Create;
  inherited Create;
  FormatSettings := DefaultFormatSettings;
  FormatSettings.DecimalSeparator:='.';
  FormatSettings.ThousandSeparator:=',';
  FormatSettings.ShortDateFormat:='yyyy-mm-dd';
  FormatSettings.ShortTimeFormat:='hh:nn:ss';
end;

function TFreeTextBuffer.StrToFloatType(const S: String): TFloatType;
var  LocalFormatSettings: TFormatSettings;
begin
  if not TryStrToFloat(S, Result, FormatSettings) then
    begin
    // try an opposite way. this is a workaround if a file was saved with commas
    LocalFormatSettings.DecimalSeparator:=',';
    LocalFormatSettings.ThousandSeparator:='.';
    Result := StrToFloat( S,LocalFormatSettings );
    end;
end;

//function TFreeTextBuffer.FloatTypeToStr( Value: TFloatType ): String;
//begin Result := FloatToStr( F2S( Value ) );
//end;

function TFreeTextBuffer.FGetCapacity: integer;
begin Result := FLines.Capacity;
end;

procedure TFreeTextBuffer.FSetCapacity(val: integer);
begin FLines.Capacity := val;
end;

procedure TFreeTextBuffer.Clear;
begin if FLines <> nil then FLines.Clear;
      inherited Clear;
end;

procedure TFreeTextBuffer.Add(Text: string);
var
  S: string;
begin
  S := ReplaceStr(Text, '\', '\\');
  S := ReplaceStr(S, EOL, '\n');
  FLines.Add(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.Add(BooleanValue: boolean);
var S: string;
begin                         //if BooleanValue then S:='True' else S:='False';
  S := BoolToStr( BooleanValue,'1','0' );
  FLines.Add( S );
  Inc( FPosition );
end;

procedure TFreeTextBuffer.Add(FloatValue: TFloatType);
var S: string;
begin
  S := FloatTypeToStr( FloatValue ); FLines.Add(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.Add(IntegerValue: integer);
var S: string;
begin
  S := IntToStr(IntegerValue);
  FLines.Add(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.Add(words: TStrings);
var
  i: integer;
  S: string;
begin
  S:='';
  if words.Count > 0 then S := words[0];
  for i:=1 to words.Count-1 do S := S + ' ' + words[i];
  FLines.Add(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.Add( PVersion: TFreeFileVersion );
var S: string;
begin
  FVersion := PVersion;
  S := VersionString( PVersion );
  FLines.Add( S );
  Inc( FPosition );
end;

procedure TFreeTextBuffer.Add( NameData: TNameData );
var S: string;
begin
  S := IntToStr(NameData.N) + ' ' + NameData.Name;
  FLines.Add(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.Add(LCData: TLinearConstraintData);
var S: string;
begin
  S := IntToStr(LCData.N)
    + ' ' + IntToStr(LCData.LinearConstraintPointA)
    + ' ' + IntToStr(LCData.LinearConstraintPointB);
  FLines.Add(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.Add( Coordinate: T3DCoordinate );
var S: string;
begin
  S := FloatTypeToStr( Coordinate.X ) + ' '
     + FloatTypeToStr( Coordinate.Y ) + ' '
     + FloatTypeToStr( Coordinate.Z );
  FLines.Add(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.Add(Plane: T3DPlane);
var S: string;
begin
  S := FloatTypeToStr( Plane.a ) + ' ' + FloatTypeToStr( Plane.b ) + ' '
     + FloatTypeToStr( Plane.c ) + ' ' + FloatTypeToStr( Plane.d );
  FLines.Add(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.Add(JPegImage: TJPEGImage);
var
  Stream: TMemoryStream;
  Size: integer;
  S: PChar;
  P: PChar;
  L: string;
begin
  Add(JPEGImage.Width);
  Add(JPEGImage.Height);

  Stream := TMemoryStream.Create;
  JPEGImage.SaveToStream(Stream);
  Size := Stream.Size;
  Stream.Position := 0;
  Add(Size);

  S := StrAlloc(Size * 2 + 2);
  S[Size * 2] := #0;
  S[Size * 2 + 1] := #0;
  P := Stream.Memory;
  BinToHex(P, S, size);
  L := StrPas(S);
  StrDispose(S);
  FLines.Add(L);
  FreeAndNil(Stream);
  Inc(FPosition);
end;{TFreeTextBuffer.Add}

procedure TFreeTextBuffer.LoadTJPEGImage(var JPegImage: TJPEGImage);
var
  Stream: TMemoryStream;
  W, H, Size: integer;
  PData: PChar;
begin
  LoadInteger(W);
  LoadInteger(H);
  LoadInteger(Size);
  PData := StrAlloc(Size);
  Stream := TMemoryStream.Create;
  Stream.SetSize(Size);
  HexToBin(PChar(FLines[FPosition]), Stream.Memory, Size);
  //Stream.Write(PData, Size);
  StrDispose(PData);
  Stream.Position := 0;
  JPEGImage.LoadFromStream(Stream);
  FreeAndNil(Stream);
  Inc(FPosition);
end;{TFreeTextBuffer.Add}

procedure TFreeTextBuffer.LoadInteger(var Output: integer);
var
  S: string;
begin
  S := FLines[FPosition];
  Output := StrToInt(S);
  Inc(FPosition);
end;

procedure TFreeTextBuffer.LoadTColor(var Output: TColor);
var S: string;
begin
   S := FLines[FPosition];
   Output := StrToInt(S);
   Inc(FPosition);
end;

procedure TFreeTextBuffer.LoadString(var Output: string);
var S: string;
begin
   S := FLines[FPosition];
   S := ReplaceStr(S, '\n', EOL);
   S := ReplaceStr(S, '\\', '\');
   Output := S;                //Output := ConvertEncoding(S,FEncoding,'utf8');
   Inc( FPosition );
end;

procedure TFreeTextBuffer.LoadTFreeFileVersion( var Output: TFreeFileVersion );
var
  S: string;
begin
  S := FLines[FPosition];
  Output := VersionBinary( S );
  Inc( FPosition );
end;

procedure TFreeTextBuffer.LoadBoolean(var Output: boolean);
var S: string;
begin
  S := FLines[FPosition];
  Output := StrToBool( S );
  Inc(FPosition);
end;

procedure TFreeTextBuffer.LoadTFloatType(var Output: TFloatType);
var
  S: string;
  LocalFormatSettings: TFormatSettings;
begin
  S := FLines[FPosition];
  Output := StrToFloatType(S);
  Inc(FPosition);
end;
{
procedure TFreeTextBuffer.LoadTJPEGImage(var Output: TColor);
var
  S: string;
begin
  S := FLines[FPosition];
  Output := StrToInt(S);
  Inc(FPosition);
end;}

procedure TFreeTextBuffer.LoadTNameData(var Output: TNameData);
var  p:integer; S: string;
begin
  S := FLines[FPosition];
  p := pos(' ',S);
  Output.N := StrToInt(copy(S,1,p-1));
  Output.Name := copy(S,p+1,length(S));
  Inc(FPosition);
end;

procedure TFreeTextBuffer.LoadTLinearConstraintData(var Output: TLinearConstraintData);
var  S: string;
begin
  S := FLines[FPosition];
  Output.N := StrToInt(ExtractWord(1, S, [' ']));
  Output.LinearConstraintPointA := StrToInt(ExtractWord(2, S, [' ']));
  Output.LinearConstraintPointB := StrToInt(ExtractWord(3, S, [' ']));
  Inc(FPosition);
end;

procedure TFreeTextBuffer.LoadT3DCoordinate(var Output: T3DCoordinate);
var S: string;
begin
  S := FLines[FPosition];
  Output.X := StrToFloatType(ExtractWord(1, S, [' ']));
  Output.Y := StrToFloatType(ExtractWord(2, S, [' ']));
  Output.Z := StrToFloatType(ExtractWord(3, S, [' ']));
  Inc(FPosition);
end;

procedure TFreeTextBuffer.LoadT3DPlane(var Output: T3DPlane);
var S: string;
begin
  S := FLines[FPosition];
  Output.a := StrToFloatType(ExtractWord(1, S, [' ']));
  Output.b := StrToFloatType(ExtractWord(2, S, [' ']));
  Output.c := StrToFloatType(ExtractWord(3, S, [' ']));
  Output.d := StrToFloatType(ExtractWord(4, S, [' ']));
  Inc(FPosition);
end;

// load string of words separated by spaces
procedure TFreeTextBuffer.LoadTStrings(var Output: TStrings);
var  i:integer; S,V: string; //SS:TStrings;
begin
  S := FLines[FPosition];
  i:=1;
  while true do begin
    V:=ExtractWord(i, S, [' ']);
    if V='' then break;
    Output.Add(V);
    inc(i);
  end;
  Inc(FPosition);
end;

destructor TFreeTextBuffer.Destroy; begin Clear; inherited Destroy; end;

procedure TFreeTextBuffer.LoadFromFile( Filename: string );
begin
  FFileName:=Filename;
  FLines.LoadFromFile( Filename );
  FPosition:=0;
end;

// reset the data before reading
procedure TFreeTextBuffer.Reset; begin FPosition:=0; end;

function TFreeTextBuffer.SaveToFile(Filename: string):boolean;
begin
  result:=false;
  FFileName := Filename;
  FLines.SaveToFile(Filename);
  result:=true;
end;

function TFreeTextBuffer.GetPosition:integer; begin Result:=FPosition; end;

end.
