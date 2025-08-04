unit FreeTypes;
{$mode objfpc}{$H+}
Interface Uses SysUtils,Math;

Const
  Radian=57.295779513082320876798154814105;                // 180/π = °\rad
  PixelCountMax=32768; // used for faster pixel acces when shading to viewport
  Foot = 0.3048;       // All new models are initialized to this version
  EOL  = #13#10;

Type
  TFreeVersion = (fv100);
  TFloatType   = single;        // All floatingpoint variables are of this type
  TFloatArray  = array of TFloatType;
  T2DCoordinate= record X,Y    :TFloatType; end; // 2D coordinate type
  T3DVector    = record X,Y,Z  :TFloatType; end; // 3D coordinate type
  T3DPlane     = record a,b,c,d:TFloatType; end; // 3D plane: a*x+b*y+c*z-d=0.0
//T3DLine      = record A,B    :T3DVector;  end; // 3D line type
//TFreeUnitType=(fuMetric,fuImperial); // Switch between metric and imperial units
  TRGBTriple=packed record rgbtBlue : BYTE;
                           rgbtGreen: BYTE;
                           rgbtRed  : BYTE; end;
  pRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..PixelCountMax-1] of TRGBTriple;
//T3DVectorArray  = array of T3DVector;
//TPointArray     = array of TPoint;
  TFreePrecisionType=( fpLow,fpMedium,fpHigh,fpVeryHigh ); // Precision of the ship-model
  TFreeIntersectionType=( fiFree,fiStation,fiButtock,fiWaterline,fiDiagonal);// Different types of intersectionlines, stations, buttocks, waterlines and lines orientated in random planes
  TFreeModelView =( mvPort,mvBoth ); // Show half the hull or the entire hull
  TFreeEditMode  =( emSelectItems ); //,emAddPoint,emAddFlowLine ); // The program responds differnt to mouse actions depending on the editmode of the component

const ZERO: T3DVector=( X:0.0;Y:0.0;Z:0.0 );
  CurrentVersion=fv100; // Current(latest) version of the FREE!ship application
  ReleasedDate='April 26, 2005';             // Releasedate of the last version

  operator <>( const A,B: T3DVector ): boolean;
  operator = ( const A,B: T3DVector ): boolean;
  operator - ( const A,B: T3DVector ): T3DVector;  // A-B
  operator + ( const A,B: T3DVector ): T3DVector;
  operator * ( const A,B: T3DVector ): T3DVector;  // векторное пероизведение
  operator * ( const D:TFloatType; const B:T3DVector ): T3DVector;  // D*B
  operator / ( const A:T3DVector; const D:TFloatType ): T3DVector;  // A/D
  operator - ( const A,B: T2DCoordinate ): T2DCoordinate; // A-B

function Vector( X: TFloatType; Y: TFloatType=0.0; Z: TFloatType=0.0 ): T3DVector;
Function GetFloat( var S: AnsiString): TFloatType;
Function GetInteger( var S:AnsiString ): Integer;
Function GetBoolean( var S:AnsiString ): Boolean;
Function FloatToDec( Value: TFloatType; Maxlength: integer ): AnsiString;
                 // Convert a floatingpoint to a string value with a max.number
                 // of specified decimals All trailing zeros will be removed
Function FloatTypeToStr( Value: TFloatType ): AnsiString;
Function Angles( V: T3DVector; Rad: TFloatType=Radian ): T3DVector;   // => [°]
Function Inter( const a,b,c: Integer ): Integer; overload;
Procedure WestPoint;            // ... или сброс всех запятых с заменой точками
Function BlankOff( S: AnsiString ): AnsiString;

function Abs( const P: T2DCoordinate ): extended; overload;
function Sqr( const V: T3DVector ): extended; overload;
function Abs( const V: T3DVector ): extended; overload;
Function AxisStep( D: double ): double;            // для разметки осевых линий
function VersionString( Version:TFreeVersion ):String; // Version 1.00

Implementation
function Vector( X: TFloatType; Y: TFloatType=0.0; Z: TFloatType=0.0 ): T3DVector;
   begin Result.X:=X;
         Result.Y:=Y;                                            // == SetPoint
         Result.Z:=Z; end;
Function Angles( V: T3DVector; Rad: TFloatType=Radian ): T3DVector;
  Var R: TFloatType;
begin R:=Abs( V );
      if R<1e-5 then Result:=ZERO else begin
         Result.x:=arccos( V.x/R )*Rad;
         Result.y:=arccos( V.y/R )*Rad;
         Result.z:=arccos( V.z/R )*Rad; end;
end;
Function Inter( const a,b,c: Integer ): Integer;
begin if b<=a then Result:=a else if b>=c then Result:=c-1 else Result:=b; end;

operator = ( const A,B: T3DVector ): boolean;
begin result:=(A.x=B.x) and (A.y=A.y) and (A.z=B.z); end;

operator <> ( const A,B: T3DVector ): boolean;
begin result:=(A.x<>B.x) or (A.y<>A.y) or (A.z<>B.z); end;

operator + ( const A,B: T3DVector ): T3DVector ;
begin result.x:=(A.x+B.x);
      result.y:=(A.y+B.y);
      result.z:=(A.z+B.z);
end;
operator - ( const A,B: T3DVector ): T3DVector;   // A-B
begin result.x:=(A.x-B.x);   // B:=( X:1.0; Y:2.0; Z:0.3 );
      result.y:=(A.y-B.y);
      result.z:=(A.z-B.z);
end;
operator / ( const A:T3DVector; const D:TFloatType ): T3DVector;  // A/B
begin result.x:=A.x/D;
      result.y:=A.y/D;
      result.z:=A.z/D;
end;
operator * ( const D:TFloatType; const B:T3DVector): T3DVector; // scalar product
begin result.x:=D*B.x;
      result.y:=D*B.y;
      result.z:=D*B.z;
end;
operator * ( const A,B: T3DVector ): T3DVector;        // crossproduct
begin result.x:=(A.y*B.z)-(A.z*B.y);                  // векторное произведение
      result.y:=(A.z*B.x)-(A.x*B.z);
      result.z:=(A.x*B.y)-(A.y*B.x);
end;
operator - ( const A,B: T2DCoordinate ): T2DCoordinate; // A-B
   begin result.x:=(A.x-B.x);
         result.y:=(A.y-B.y);
   end;
function Abs( const P: T2DCoordinate ): extended;
   begin Result:=sqrt( sqr( P.X )+sqr( P.Y ) ); end;
function Sqr( const V: T3DVector ): extended;
   begin Result:=sqr( V.X )+sqr( V.Y )+sqr( V.Z ); end;
function Abs( const V: T3DVector ): extended;
   begin Result:=sqrt( sqr( V.X )+sqr( V.Y )+sqr( V.Z ) ); end;
Function AxisStep( D: double ): double;            // для разметки осевых линий
 const M_LN10=2.30258509299404568402;
 var iPart: double;
begin D:=log10( D );
      iPart:=floor( D );
      D:=exp( (D-iPart)*M_LN10 );
      if D>=6 then D:=2 else
      if D>=3 then D:=1 else
      if D>=1.5 then D:=0.5 else D:=0.2;
      Result:=power( 10.0,iPart )*D;
end;
function FloatTypeToStr( Value: TFloatType ): AnsiString; var W: extended;
   begin if abs( Value )<1e-5 then Value:=0.0
            else begin W:=Value; W:=Int( 0.5+W*1e6 ); Value:=W/1e6; end;
     Result:=FloatToDec(Value,6); // или FloatToStrF(F2S(Value),ffGeneral,6,1);
   end;
function FloatToDec(Value: TFloatType; Maxlength: integer): AnsiString;
   begin
     Result:=FloatToStrF( Value,ffFixed,MaxLength+2,Maxlength ); //, fmt);
     MaxLength:=Length( Result );
     while Result[MaxLength]='0' do dec( MaxLength );
     if Result[MaxLength] in ['.', ','] then Inc(MaxLength);
     SetLength( Result,MaxLength );
  end;
Function GetFloat( var S: AnsiString ): TFloatType;
  var LocalFormatSettings: TFormatSettings; I,J,K: Integer; // R:extended;
begin LocalFormatSettings:=DefaultFormatSettings; I:=0; K:=0; Result:=0.0;
  for J:=1 to Length( S ) do begin
    if S[J]>' ' then begin K:=J+1;                   // обход значимого символа
      if I=0 then I:=J;                              // начало записи числа
      if S[J]='.' then begin LocalFormatSettings.DecimalSeparator:='.';
                             LocalFormatSettings.ThousandSeparator:=','; end else
      if S[J]=',' then begin LocalFormatSettings.DecimalSeparator:=',';
                             LocalFormatSettings.ThousandSeparator:='.'; end;
    end else if I>0 then begin K:=J; break; end;    // здесь к = новый пробел
  end;
  if I>0 then Result:=StrToFloat( copy( S,I,K-I ),LocalFormatSettings );
  Delete( S,1,K-1 ); // удаление считанного с последующим пробелом ??
end;
Function GetInteger( var S: AnsiString ): Integer;
var I,J,K: Integer;
begin I:=0; K:=0; Result:=0;
  for J:=1 to Length( S ) do
    if S[J]>' ' then begin K:=J+1; if I=0 then I:=J; end else
    if I>0 then begin K:=J; break; end;
  if I>0 then Result:=StrToInt( copy( S,I,K-I ) ); Delete( S,1,K-1 );
end;
Function GetBoolean( var S: AnsiString ): Boolean;
var I,J,K: Integer; Str: AnsiString;
begin I:=0; K:=0; Result:=false;
  for J:=1 to Length( S ) do
   if S[J]>' ' then begin K:=J+1; if I=0 then I:=J; end else if I>0 then break;
  if K>0 then begin Str:=Upcase( copy( S,I,K-I ) );
         Result:=(Str='1') or (Str='TRUE') or (Str='YES'); Delete( S,1,K-1 );
  end;
end;
Procedure WestPoint;
Begin DefaultFormatSettings.DecimalSeparator:='.';
      DefaultFormatSettings.ThousandSeparator:=',';
      DefaultFormatSettings.ShortDateFormat:='yyyy-mm-dd';
      DefaultFormatSettings.ShortTimeFormat:='hh:nn:ss';
      FormatSettings:=DefaultFormatSettings;
end;
Function BlankOff( S: AnsiString ): AnsiString; var I,J,K,L:integer;
begin J:=1; K:=1; L:=Length( S );       // вычистка лишних пробелов и пропусков
  for I:=1 to L do
    if S[I]>' ' then begin S[J]:=S[I]; inc( J ); K:=J; end else
      if (J>1) and (J=K) then begin S[J]:=' '; inc( J ); end;
    //for I:=J to L do S[I]:=' ';
    SetLength( S,J-1 );
    Result:=S;
end;
function VersionString(Version:TFreeVersion): String;
   begin Result:='1.00'; end;

end.

