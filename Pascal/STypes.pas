unit STypes;
{$mode objfpc}{$H+}
Interface Uses SysUtils,Math,Graphics;
Const
  Radian = 57.295779513082320876798154814105; // 180/π = °\rad
  Foot = 0.3048;
  Lbs  = 0.4535924;
  MaxRecent = 24;
  WeightConversionFactor=(1000/Lbs)/((1/Foot)*(1/Foot)*(1/Foot));
  Eps = 1.0e-12;
  EOL = #13#10;
Type
  Real = Double;  { желательно всё привести к единому числовому представлению }
  RealArray = array of Real;  // Single=32b; // Real=double; // Float=extended;
  Vector = record X,Y,Z:Real; end;  // 3D coordinate type
  VectorArray = array of Vector;
  Plate = record a,b,c,d:Real; end; // 3D plane: a*x+b*y+c*z-d=0.0
  Place = record X,Y:Real; end;     // 2D coordinate type
  TPrecisionType=( fpLow,fpMedium,fpHigh,fpVeryHigh ); // Precision of the St-model
  TIntersectionType=( fi,fiStation,fiButtock,fiWaterline,fiDiagonal);
  // Different types of intersectionlines, stations, buttocks, waterlines and lines orientated in random planes
  TModelView =( mvPort,mvBoth ); // Show half the hull or the entire hull
  TEditMode  =( emSelectItems ); //,emAddPoint,emAddFlowLine ); // The program responds differnt to mouse actions depending on the editmode of the component
  ShipInit = Record
    Edge,       // Color of normal edges
    Crease,     // color of crease edges
    CreaseEdge, // color of crease control-edges
    Grid,       // Color of gridlines
    GridFont,   // Color of font with gridlines
    CreasePoint,// Color of crease vertices
    RegularPoint,
    CornerPoint,// Color of cornerpoints and points with at least 3 crease edges
    DartPoint,
    Select,     // Color of selected items
    Layer,      // Default color for new layers
    Normal,     // color of surface normals
    LeakPoint,
    Marker,
    CurvaturePlot,
    ControlCurve,
    HydrostaticsFont,
    ZebraStripe,
    Station,
    Buttock,
    Waterline,
    Diagonal,
    UColor: TColor;    // Цветовое затенение смоченной обшивки
    UColorIs: boolean; // Временно отключение подводного затенения
    UAlfa: byte;       // Color used for shading the underwater part opaque
//    IntersectionLW,  //  in pixels when drawn on screen Colors
//    ControlEdgeLW,
//    InteriorEdgeLW,
//    AuxEdgeLW,
//    HydrostaticLW: integer;
    CurvatureScale: Real; // переобъявлялось в трёх структурах ...
  end;

const ZERO: Vector=( X:0.0;Y:0.0;Z:0.0 );
      UFont: String='Times New Roman'; // 'Serif';

  operator <>( const A,B: Vector ): boolean;
  operator = ( const A,B: Vector ): boolean;
  operator - ( const A,B: Vector ): Vector;  // A-B
  operator + ( const A,B: Vector ): Vector;
//operator % ( const A,B: Vector ): Real; // скалярное пероизведение
  operator * ( const A,B: Vector ): Vector;  // векторное пероизведение
  operator * ( const D:Real; const B:Vector ): Vector;  // D*B
  operator / ( const A:Vector; const D:Real ): Vector;  // A/D
  operator - ( const A,B: Place ): Place; // A-B
function iVect( const X: Real; const Y: Real=0.0; const Z: Real=0.0 ): Vector;
Function GetFloat( var S: String): Real;
Function GetVector( var S: String): Vector;
Function GetInteger( var S:String ): Integer;
Function GetBoolean( var S:String ): Boolean;
Function FloatToDec( const Value: Real; Maxlength: integer ): String;
                 // Convert a floatingpoint to a string value with a max.number
                 // of specified decimals All trailing zeros will be removed
Function FloatTypeToStr( Value: Real ): String;
Function Angles( V: Vector; Rad: Real=Radian ): Vector;   // => [°]
Function Inter( const a,b,c: Integer ): Integer; overload;
Procedure WestPoint;            // ... или сброс всех запятых с заменой точками
Function BlankOff( S: String ): String;

function Sqr( const P: Place ): Real; overload;
function Abs( const P: Place ): Real; overload;
function Sqr( const V: Vector ): Real; overload;
function Abs( const V: Vector ): Real; overload;
Function AxisStep( D: Real ): Real;                // для разметки осевых линий
procedure ArraySort( var A:RealArray; var N:integer; Clear:boolean=true );
Function I2S( Value: Integer ): String;
procedure Interpolation   // Линейная ИНТЕРПОЛЯЦИЯ И ЗКСТРАПОЛЯЦИЯ ФУНКЦИИ Y(X)
( XX: Real;               // аргумент поиска
  N: integer;             // наверное,длина массива
  X,Y: RealArray;         // собственно аргумент и функция
  var YY: Real );         // результат
Function TimeString: String;

var Sp: ShipInit;
{=(
   UColorIs: true;    // Временно отключение подводного затенения
   UColor: clGreen;   // Цветовое затенение смоченной обшивки
   UAlfa: 64;         // Color used for shading the underwater part opaque
); }

Implementation

function iVect( const X: Real; const Y: Real=0.0; const Z: Real=0.0 ): Vector;
   begin Result.X:=X;
         Result.Y:=Y;                                            // == SetPoint
         Result.Z:=Z; end;
Function Angles( V: Vector; Rad: Real=Radian ): Vector; Var R: Real;
begin R:=Abs( V );
      if R<1e-5 then Result:=ZERO else begin
         Result.x:=arccos( V.x/R )*Rad;
         Result.y:=arccos( V.y/R )*Rad;
         Result.z:=arccos( V.z/R )*Rad; end;
end;
Function Inter( const a,b,c: Integer ): Integer;
begin if b<=a then Result:=a else if b>=c then Result:=c-1 else Result:=b; end;

operator = ( const A,B: Vector ): boolean;
begin result:=(A.x=B.x) and (A.y=A.y) and (A.z=B.z); end;

operator <> ( const A,B: Vector ): boolean;
begin result:=(A.x<>B.x) or (A.y<>A.y) or (A.z<>B.z); end;

operator + ( const A,B: Vector ): Vector ;
begin result.x:=(A.x+B.x);
      result.y:=(A.y+B.y);
      result.z:=(A.z+B.z);
end;
operator - ( const A,B: Vector ): Vector;   // A-B
begin result.x:=(A.x-B.x); // B:=( X:1.0; Y:2.0; Z:0.3 );
      result.y:=(A.y-B.y);
      result.z:=(A.z-B.z);
end;
operator / ( const A:Vector; const D:Real ): Vector;  // A/B
begin result.x:=A.x/D;
      result.y:=A.y/D;
      result.z:=A.z/D;
end;
operator * ( const D:Real; const B:Vector):Vector;// scalar product
begin result.x:=D*B.x;
      result.y:=D*B.y;
      result.z:=D*B.z;
end;
//operator % ( const A,B: Vector ): Real;   // скалярное пероизведение
//   begin result:=A.x*B.x + A.y*B.y + A.z*B.z; end;

operator * ( const A,B: Vector ): Vector;        // crossproduct
begin result.x:=(A.y*B.z)-(A.z*B.y);                  // векторное произведение
      result.y:=(A.z*B.x)-(A.x*B.z);
      result.z:=(A.x*B.y)-(A.y*B.x);
end;
operator - ( const A,B: Place ): Place; // A-B
   begin result.x:=(A.x-B.x);
         result.y:=(A.y-B.y);
   end;
function Sqr( const P: Place ): Real;
   begin Result:=P.X*P.X+P.Y*P.Y; end;
function Abs( const P: Place ): Real;
   begin Result:=hypot( P.X,P.Y ); end; // sqrt(sqr(P.X)+sqr(P.Y));
function Sqr( const V: Vector ): Real;
   begin Result:=sqr( V.X )+sqr( V.Y )+sqr( V.Z ); end;
function Abs( const V: Vector ): Real;
   begin Result:=sqrt( sqr( V.X )+sqr( V.Y )+sqr( V.Z ) ); end;
Function AxisStep( D: Real ): Real; // для разметки осевых линий
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
function FloatTypeToStr( Value: Real ): String; var W: Real;
   begin if abs( Value )<1e-5 then Value:=0.0
            else begin W:=Value; W:=Int( 0.5+W*1e6 ); Value:=W/1e6; end;
     Result:=FloatToDec(Value,6); // или FloatToStrF(F2S(Value),ffGeneral,6,1);
   end;
function FloatToDec( const Value: Real; Maxlength: integer): String;
   begin
     Result:=FloatToStrF( Value,ffFixed,MaxLength+2,Maxlength ); //, fmt);
     MaxLength:=Length( Result );
     while Result[MaxLength]='0' do dec( MaxLength );
     if Result[MaxLength] in ['.',','] then dec( MaxLength ); //Inc(MaxLength);
     SetLength( Result,MaxLength );
  end;
Function GetFloat( var S: String ): Real;
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
Function GetVector( var S: String): Vector;
begin Result.X:=GetFloat(S); Result.Y:=GetFloat(S); Result.Z:=GetFloat(S);
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
procedure ArraySort( var FloatArray: RealArray; var N: Integer );
  var I,J: Integer;  tempValue: Real;           { пузырьковая сортировка }
begin
  for i:=1 to N-1 do                                               // пузырьком
  for j:=N-1 downto i do
  if FloatArray[j-1]>FloatArray[j] then begin               { обмен элементов }
     tempValue:=FloatArray[j]; FloatArray[j]:=FloatArray[j-1];
                FloatArray[j-1]:=tempValue;
  end;
end;
{$else}
procedure ArraySort( var A:RealArray; var N:integer; Clear:boolean );
Var I:integer;
   procedure QuickSort( L,R:Integer ); var I,J:integer; Val:Real;
      procedure Swap( I,J:Integer ); var T:Real;
           begin T:=A[I]; A[I]:=A[J]; A[J]:=T; end;
   begin I:=L; J:=R; Val:=A[(L+R) div 2];
      repeat while A[I]<Val do Inc(I);
             while Val<A[J] do Dec(J);
             if I<=J then begin Swap(I,J); Inc(I); Dec(J); end;
      until I>J;
      if L<J then QuickSort( L,J );
      if I<R then QuickSort( I,R );
   end;
begin                                              // begin procedure ArraySort
  if N<2 then exit; QuickSort( 0,N-1 );
  if not Clear then exit;
  I:=2;
  while I<=N do if A[I-1]-A[I-2]<Eps then       // 1e-4 remove duplicate values
     begin Move(A[I-1],A[I-2],(N-I+1)*SizeOf(Real)); Dec(N); end else Inc(I);
end;
{$endif}
procedure Interpolation   // Линейная ИНТЕРПОЛЯЦИЯ И ЗКСТРАПОЛЯЦИЯ ФУНКЦИИ Y(X)
( XX: Real;               // аргумент поиска
  N: integer;             // наверное,длина массива
  X,Y: RealArray;         // собственно аргумент и функция
  var YY: Real );         // результат
var I:integer; B:boolean; // и без проверок интервалов аргумента !!!
begin
//if XX<=Xs[0] then YY:=Y[0]+(XX-X[0])*(Y[1]-Y[0])/(X[1]-X[0]) else
//if XX>=Xs[N-1] then YY:=Y[N-2]+(XX-X[N-2])*(Y[N-2]-Y[N-1])/(X[N-2]-X[N-1]) else
  B:=XX<=X[0];
  for I:=0 to N-1 do if B or (XX>=X[I]) or (I=N-2) then
    begin YY:=Y[I]+((XX-X[I]))*(Y[I+1]-Y[I])/(X[I+1]-X[I]); break; end;
end;

Function TimeString: String;
   begin Result:=FormatDateTime( 'YYYY-MM-DD_hh:nn',Now ); end;

end.

