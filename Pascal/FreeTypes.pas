unit FreeTypes;
{$mode objfpc}{$H+}
Interface Uses SysUtils,Math;
Const
  UFont='Times New Roman';
  Radian=57.295779513082320876798154814105;                // 180/π = °\rad
  PixelCountMax=32768; // used for faster pixel acces when shading to viewport
  Foot = 0.3048;       // All new models are initialized to this version
  EOL  = #13#10;

Type
  TFreeVersion = (fv100);
  Real = double; { желательно всё перевести к единому числовому представлению }
  TFloatType   = single;    // All floatingpoint variables are of this type
  TFloatArray  = array of TFloatType;
  T2DCoordinate= record X,Y    :TFloatType; end; // 2D coordinate type
  T3DVector    = record X,Y,Z  :TFloatType; end; // 3D coordinate type
  T3DLine      = record A,B    :T3DVector;  end; // 3D line type
  T3DPlane     = record a,b,c,d:TFloatType; end; // 3D plane: a*x+b*y+c*z-d=0.0
  T3DVectorArray = array of T3DVector;
  TFreePrecisionType=( fpLow,fpMedium,fpHigh,fpVeryHigh ); // Precision of the ship-model
  TFreeIntersectionType=( fiFree,fiStation,fiButtock,fiWaterline,fiDiagonal);
  // Different types of intersectionlines, stations, buttocks, waterlines and lines orientated in random planes
  TFreeModelView =( mvPort,mvBoth ); // Show half the hull or the entire hull
  TFreeEditMode  =( emSelectItems ); //,emAddPoint,emAddFlowLine ); // The program responds differnt to mouse actions depending on the editmode of the component

  TFreeDelftSeriesResistanceData=record // явно лишнее, выбросить не получается
       StartSpeed,EndSpeed,StepSpeed, Bwl,Cp,Displacement,Draft,DraftTotal,
       KeelChordLength,KeelArea, LCB,Lwl, RudderChordLength,RudderArea,
       Viscosity,WettedSurface,WlArea: Single;
       EstimateWetSurf,Extract: Boolean; end;
  TFreeKAPERResistanceData = record
       Draft,Lwl,Bwl,Cp,Displacement,LCB,WettedSurface,At_Ax,
       EntranceAngle: Single;
       Extract: Boolean;
  end;

const ZERO: T3DVector=( X:0.0;Y:0.0;Z:0.0 );

  operator <>( const A,B: T3DVector ): boolean;
  operator = ( const A,B: T3DVector ): boolean;
  operator - ( const A,B: T3DVector ): T3DVector;  // A-B
  operator + ( const A,B: T3DVector ): T3DVector;
//operator % ( const A,B: T3DVector ): TFloatType; // скалярное пероизведение
  operator * ( const A,B: T3DVector ): T3DVector;  // векторное пероизведение
  operator * ( const D:Real; const B:T3DVector ): T3DVector;  // D*B
  operator / ( const A:T3DVector; const D:Real ): T3DVector;  // A/D
  operator - ( const A,B: T2DCoordinate ): T2DCoordinate; // A-B

function Vector( X: TFloatType; Y: TFloatType=0.0; Z: TFloatType=0.0 ): T3DVector;
Function GetFloat( var S: String): TFloatType;
Function GetInteger( var S:String ): Integer;
Function GetBoolean( var S:String ): Boolean;
Function FloatToDec( Value: TFloatType; Maxlength: integer ): String;
                 // Convert a floatingpoint to a string value with a max.number
                 // of specified decimals All trailing zeros will be removed
Function FloatTypeToStr( Value: TFloatType ): String;
Function Angles( V: T3DVector; Rad: Real=Radian ): T3DVector;   // => [°]
Function Inter( const a,b,c: Integer ): Integer; overload;
Procedure WestPoint;            // ... или сброс всех запятых с заменой точками
Function BlankOff( S: String ): String;

function Sqr( const P: T2DCoordinate ): Real; overload;
function Abs( const P: T2DCoordinate ): Real; overload;
function Sqr( const V: T3DVector ): Real; overload;
function Abs( const V: T3DVector ): Real; overload;
Function AxisStep( D: Real ): Real;            // для разметки осевых линий
procedure ArraySort( var FloatArray:TFloatArray; var N:integer );

Function I2S( Value: Integer ): String;
procedure Interpolation   // Линейная ИНТЕРПОЛЯЦИЯ И ЗКСТРАПОЛЯЦИЯ ФУНКЦИИ Y(X)
( XX: TFloatType;             // аргумент поиска
  N: integer;                 // наверное,длина массива
  X,Y: array of TFloatType;   // собственно аргумент и функция
  var YY: TFloatType );       // результат

{function createDialogFilter( FilterName: String;
                             extensions: array of String;
                             NeedsAll: boolean=True ): String;
function VersionString( Version:TFreeVersion ):String; // Version 1.00
}
Function TimeString: String;
Implementation
function Vector( X: TFloatType; Y: TFloatType=0.0; Z: TFloatType=0.0 ): T3DVector;
   begin Result.X:=X;
         Result.Y:=Y;                                            // == SetPoint
         Result.Z:=Z; end;
Function Angles( V: T3DVector; Rad: Real=Radian ): T3DVector;
  Var R: Real;
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
operator / ( const A:T3DVector; const D:Real ): T3DVector;  // A/B
begin result.x:=A.x/D;
      result.y:=A.y/D;
      result.z:=A.z/D;
end;
operator * ( const D:Real; const B:T3DVector):T3DVector;// scalar product
begin result.x:=D*B.x;
      result.y:=D*B.y;
      result.z:=D*B.z;
end;
//operator % ( const A,B: T3DVector ): TFloatType;   // скалярное пероизведение
//   begin result:=A.x*B.x + A.y*B.y + A.z*B.z; end;

operator * ( const A,B: T3DVector ): T3DVector;        // crossproduct
begin result.x:=(A.y*B.z)-(A.z*B.y);                  // векторное произведение
      result.y:=(A.z*B.x)-(A.x*B.z);
      result.z:=(A.x*B.y)-(A.y*B.x);
end;
operator - ( const A,B: T2DCoordinate ): T2DCoordinate; // A-B
   begin result.x:=(A.x-B.x);
         result.y:=(A.y-B.y);
   end;
function Sqr( const P: T2DCoordinate ): Real;
   begin Result:=P.X*P.X+P.Y*P.Y; end;
function Abs( const P: T2DCoordinate ): Real;
   begin Result:=hypot( P.X,P.Y ); end;             // sqrt(sqr(P.X)+sqr(P.Y));
function Sqr( const V: T3DVector ): Real;
   begin Result:=sqr( V.X )+sqr( V.Y )+sqr( V.Z ); end;
function Abs( const V: T3DVector ): Real;
   begin Result:=sqrt( sqr( V.X )+sqr( V.Y )+sqr( V.Z ) ); end;
Function AxisStep( D: Real ): Real;            // для разметки осевых линий
 const M_LN10=2.30258509299404568402;
 var iPart: Real;
begin D:=log10( D );
      iPart:=floor( D );
      D:=exp( (D-iPart)*M_LN10 );
      if D>=6 then D:=2 else
      if D>=3 then D:=1 else
      if D>=1.5 then D:=0.5 else D:=0.2;
      Result:=power( 10.0,iPart )*D;
end;
function FloatTypeToStr( Value: TFloatType ): String; var W: Real;
   begin if abs( Value )<1e-5 then Value:=0.0
            else begin W:=Value; W:=Int( 0.5+W*1e6 ); Value:=W/1e6; end;
     Result:=FloatToDec(Value,6); // или FloatToStrF(F2S(Value),ffGeneral,6,1);
   end;
function FloatToDec(Value: TFloatType; Maxlength: integer): String;
   begin
     Result:=FloatToStrF( Value,ffFixed,MaxLength+2,Maxlength ); //, fmt);
     MaxLength:=Length( Result );
     while Result[MaxLength]='0' do dec( MaxLength );
     if Result[MaxLength] in ['.',','] then dec( MaxLength ); //Inc(MaxLength);
     SetLength( Result,MaxLength );
  end;
Function GetFloat( var S: String ): TFloatType;
  var LocalFormatSettings: TFormatSettings; I,J,K: Integer; // R:Real~extended;
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
Function GetInteger( var S: String ): Integer;
var I,J,K: Integer;
begin I:=0; K:=0; Result:=0;
  for J:=1 to Length( S ) do
    if S[J]>' ' then begin K:=J+1; if I=0 then I:=J; end else
    if I>0 then begin K:=J; break; end;
  if I>0 then Result:=StrToInt( copy( S,I,K-I ) ); Delete( S,1,K-1 );
end;
Function GetBoolean( var S: String ): Boolean;
var I,J,K: Integer; Str: String;
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
Function BlankOff( S: String ): String; var I,J,K,L:integer;
begin J:=1; K:=1; L:=Length( S );       // вычистка лишних пробелов и пропусков
  for I:=1 to L do
    if S[I]>' ' then begin S[J]:=S[I]; inc( J ); K:=J; end else
      if (J>1) and (J=K) then begin S[J]:=' '; inc( J ); end;
    //for I:=J to L do S[I]:=' ';
    SetLength( S,J-1 );
    Result:=S;
end;

Function I2S( Value: Integer ): String;
begin if abs( Value )>=$4000 then Result:='$'+IntToHex( Value,4 )
                             else Result:=IntToStr( Value );
end;

{$if 0}
procedure ArraySort( var FloatArray: TFloatArray; var N: Integer );
  var I,J: Integer;  tempValue: TFloatType;           { пузырьковая сортировка }
begin
  for i:=1 to N-1 do                                               // пузырьком
  for j:=N-1 downto i do
  if FloatArray[j-1]>FloatArray[j] then begin               { обмен элементов }
     tempValue:=FloatArray[j]; FloatArray[j]:=FloatArray[j-1];
                FloatArray[j-1]:=tempValue;
  end;
end;
{$else}
procedure ArraySort( var FloatArray:TFloatArray; var N:integer ); var I:integer;
  procedure QuickSort(L,R:integer); var I,J:integer; Val: TFloatType;
    procedure Swap(I,J: integer); var Tmp: TFloatType;
    begin Tmp:=FloatArray[I]; FloatArray[I]:=FloatArray[J]; FloatArray[J]:=Tmp; end;
  begin I:=L; J:=R; Val:=FloatArray[(L+R) div 2];
    repeat while FloatArray[I]<Val do Inc(I);
           while Val<FloatArray[J] do Dec(J);
           if I<=J then begin Swap(I,J); Inc(I); Dec(J); end;
    until I>J;
    if L<J then QuickSort( L,J );
    if I<R then QuickSort( I,R );
  end; {QuickSort}
begin                                              // begin procedure ArraySort
  if N<2 then exit; QuickSort( 0,N-1 ); I:=2;
  while I<=N do                                      // remove duplicate values
  if abs(FloatArray[I-2]-FloatArray[I-1])<1e-4 then begin
     Move(FloatArray[I-1],FloatArray[I-2],(N-I+1)*SizeOf(TFloatType)); Dec(N);
  end else Inc(I);
end; {SortFloatArray}
{$endif}

procedure Interpolation   // Линейная ИНТЕРПОЛЯЦИЯ И ЗКСТРАПОЛЯЦИЯ ФУНКЦИИ Y(X)
( XX: TFloatType;             // аргумент поиска
  N: integer;                 // наверное,длина массива
  X,Y: array of TFloatType;   // собственно аргумент и функция
  var YY: TFloatType );       // результат
var I:integer; B:boolean;     // и без проверок интервалов аргумента !!!
begin
//if XX<=Xs[0] then YY:=Y[0]+(XX-X[0])*(Y[1]-Y[0])/(X[1]-X[0]) else
//if XX>=Xs[N-1] then YY:=Y[N-2]+(XX-X[N-2])*(Y[N-2]-Y[N-1])/(X[N-2]-X[N-1]) else
  B:=XX<=X[0];
  for I:=0 to N-1 do if B or (XX>=X[I]) or (I=N-2) then
    begin YY:=Y[I]+((XX-X[I]))*(Y[I+1]-Y[I])/(X[I+1]-X[I]); break; end;
end;

(*
function createDialogFilter( FilterName: String;
                             extensions: array of String;
                             NeedsAll: boolean=True ): String;
var I: integer; ext,fltr: String;
{ function makeGTKfilter( ext:String ):String; var I:integer;
  begin Result:='';
  for i:=1 to length(ext) do Result+='['+uppercase(ext[i])+lowercase(ext[i])+']';
  end; }
begin
  ext:=''; fltr:=''; Result:=FilterName+' (';
  for i:=0 to length( extensions )-1 do begin
    ext += '*.'+extensions[i]+';';
    fltr += '*.'+extensions[i]+';';
  end;
  ext:=LeftStr( ext,length(ext)-1 );
  fltr:=LeftStr( fltr,length(fltr)-1 );
  Result += ext+')|'+fltr;
  if NeedsAll then Result += '|All files ( *.* )|*.*';
end;
function VersionString(Version:TFreeVersion): String;
   begin Result:='1.00'; end;
*)
Function TimeString: String;
   begin Result:=FormatDateTime( 'YYYY-MM-DD_hh:nn',Now ); end;

end.

