unit FreeTypes;
{$mode objfpc}{$H+}

Interface
Uses Classes,SysUtils,Graphics,Math;
Const Radian=57.295779513082320876798154814105;              // 180/π = °\rad
      PixelCountMax=32768; // used for faster pixel acces when shading to viewport
//    DirectorySeparator='\';
      Foot = 0.3048;

Type
  TFloatType   = single;        // All floatingpoint variables are of this type
  TFloatArray  = array of TFloatType;
  T2DCoordinate= record X,Y:TFloatType; end;   // 2D coordinate type
  T3DVector    = record X,Y,Z:TFloatType; end; // 3D coordinate type
  T3DLine      = record A,B:T3DVector; end;    // 3D line type
  T3DPlane     = record a,b,c,d:TFloatType; end;
                                     // Description 3D plane: a*x+b*y+c*z-d=0.0
  TFreeUnitType=(fuMetric,fuImperial); // Switch between metric and imperial units


  operator <>( const A,B: T3DVector): boolean;
  operator = ( const A,B: T3DVector): boolean;
  operator - ( const A,B: T3DVector ): T3DVector;  // A-B
  operator + ( const A,B: T3DVector ): T3DVector;
  operator * ( const A,B: T3DVector ): T3DVector;  // векторное пероизведение
  operator * ( const D:TFloatType; const B:T3DVector ): T3DVector;  // D*B
  operator / ( const A:T3DVector; const D:TFloatType ): T3DVector;  // A/D
  operator - ( const A,B: T2DCoordinate ): T2DCoordinate; // A-B
Type
  TRGBTriple=packed record rgbtBlue : BYTE;
                           rgbtGreen: BYTE;
                           rgbtRed  : BYTE; end;

  pRGBTripleArray      = ^TRGBTripleArray;
  TRGBTripleArray      = array[0..PixelCountMax-1] of TRGBTriple;
//TRGBTripleArray      = array of TRGBTriple;
  T3DVectorArray       = array of T3DVector;
  TPointArray          = array of TPoint;
  TFreePrecisionType   =(fpLow,fpMedium,fpHigh,fpVeryHigh);                  // Precision of the ship-model
  TFreeIntersectionType=(fiFree,fiStation,fiButtock,fiWaterline,fiDiagonal); // Different types of intersectionlines, stations, buttocks, waterlines and lines orientated in random planes
  TFreeModelView       =(mvPort,mvBoth);                                     // Show half the hull or the entire hull
  TFreeEditMode        =(emSelectItems,emAddPoint,emAddFlowLine);            // The program responds differnt to mouse actions depending on the editmode of the component
//TFreeHydrostaticsMode=(fhSingleCalculation,fhMultipleCalculations);        // Used when creating hydrostatic reports
  TFreeHydrostaticsCalculation= (hcAll,hcVolume,hcMidship,hcWaterline,hcSAC,hcLateralArea,hcBulbSection);
  TFreeHydrostaticsCalculate  = set of TFreeHydrostaticsCalculation;         // Set with all calculations to be performed
  TFreeHydrostaticsCalculateGravity = set of TFreeHydrostaticsCalculation;
  TFreeHydrostaticCoeff       = (fcProjectSettings,fcActualData);
  TFreeDelftSeriesResistanceData=record
                                    StartSpeed,
                                    EndSpeed,
                                    StepSpeed,
                                    Bwl,
                                    Cp,
                                    Displacement,
                                    Draft,
                                    DraftTotal,
                                    KeelChordLength,
                                    KeelArea,
                                    LCB,
                                    Lwl,
                                    RudderChordLength,
                                    RudderArea,
                                    Viscosity,
                                    WettedSurface,
                                    WlArea            : TFloatType;
                                    EstimateWetSurf,
                                    Extract           : Boolean;
                                 end;
  TFreeKAPERResistanceData     = record
                                    Draft,
                                    Lwl,
                                    Bwl,
                                    Cp,
                                    Displacement,
                                    LCB,
                                    WettedSurface,
                                    At_Ax,
                                    EntranceAngle     : TFloatType;
                                    Extract           : Boolean;
                                 end;
Const
  ZERO : T3DVector = (X:0.0;Y:0.0;Z:0.0);
  EOL              = #13#10;

Function F2S( Value: TFloatType ): TFloatType;
function Vector( X: TFloatType; Y: TFloatType=0.0; Z: TFloatType=0.0 ): T3DVector;
Function GetFloat( var S: AnsiString): TFloatType;
Function GetInteger( var S:AnsiString ): Integer;
Function GetBoolean( var S:AnsiString ): Boolean;
function FloatToDec( Value: TFloatType; Maxlength: integer ): AnsiString;
                 // Convert a floatingpoint to a string value with a max.number
                 // of specified decimals All trailing zeros will be removed
Function FloatTypeToStr( Value: TFloatType ): AnsiString;
Procedure WestPoint;
Function BlankOff( S: AnsiString ): AnsiString;
function Abs( const P: T2DCoordinate ): extended; overload;
function Sqr( const V: T3DVector ): extended; overload;
function Abs( const V: T3DVector ): extended; overload;
Function AxisStep( D: double ): double;            // для разметки осевых линий
procedure ArraySort( var FloatArray: TFloatArray; var N:integer );
Procedure Interpolation   // Линейная ИНТЕРПОЛЯЦИЯ И ЗКСТРАПОЛЯЦИЯ ФУНКЦИИ Y(X)
( XX: TFloatType;            // аргумент поиска
  N: integer;                // наверное, длина массива
  X,Y: array of TFloatType;  // собственно аргумент и функция
  var YY: TFloatType         // результат
);                           // и без проверок интервалов аргумента !!!
function FindWaterViscosity( Temper:TFloatType; Units:TFreeUnitType ):TFloatType;
function TimeString: String;

Implementation
function Vector( X: TFloatType; Y: TFloatType=0.0; Z: TFloatType=0.0 ): T3DVector;
   begin Result.X:=X;
         Result.Y:=Y;                                            // == SetPoint
         Result.Z:=Z; end;

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

procedure Interpolation   // Линейная ИНТЕРПОЛЯЦИЯ И ЗКСТРАПОЛЯЦИЯ ФУНКЦИИ Y(X)
( XX: TFloatType;             // аргумент поиска
  N: integer;                 // наверное, длина массива
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

//Function Length( Str: AnsiString ): Integer; overload; // ??? reintroduce; override; virtual;
//   begin Result:=UTF8Length( Str ); end;

function F2S( Value: TFloatType ): TFloatType; var W: extended;
begin if abs( Value )<1e-5 then Result:=0 else begin
           W:=Value; W:=Round( W*1e6 ); Result:=W/1e6; end;
end;

function FloatTypeToStr( Value: TFloatType ): AnsiString;
   begin Result:=FloatToStr( F2S( Value ) ); end;
// begin Result:=FloatToStrF( F2S( Value ),ffGeneral,6,1 ); end;

function FloatToDec(Value: TFloatType; Maxlength: integer): AnsiString;
       //var fmt:TFormatSettings;
begin  //  fmt:=DefaultFormatSettings;
       //  fmt.DecimalSeparator:='.';
       //  fmt.ThousandSeparator:=',';
  Result:=FloatToStrF( Value,ffFixed,10,Maxlength ); //, fmt);
  while Result[Length(Result)]='0' do Delete(Result,Length(Result),1);
  if Length(Result)<MaxLength then Result:=Result+'0' else
  if Result[Length(Result)] in ['.', ','] then Result:=Result+'0';
end;{FloatToDec}

Function GetFloat( var S: AnsiString ): TFloatType;
  var LocalFormatSettings: TFormatSettings; I,J,K: Integer; R:extended;
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
Function TimeString: String;
   begin Result:=FormatDateTime( 'YYYY-MM-DD_hh:nn',Now ); end;

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
    procedure Swap(I, J: integer); var Tmp: TFloatType;
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
//      function to find the corresponding water viscosity based on the density

function FindWaterViscosity(Temper:TFloatType; Units:TFreeUnitType):TFloatType;
const
Temp: array of TFloatType =  //  t,grad C  [0..17]
(0.0, 3.8, 5.0, 7.2,  10.0, 12.2, 15.0, 17.2, 20.0, 22.2,25.0,30.0,40, 50, 60,  70,  80,  90);
Visc: array of TFloatType =  //  Nu*1000
(1.82,1.61,1.56,1.462,1.352,1.274,1.189,1.125,1.02,0.95,0.910,0.817,0.666,0.56,0.479,0.414,0.362,0.321);
{ t   0     1.0 2.0  3.0  4.0  5.0  6.0   7.0  8.0  9.0  10   11   12   13   14   ++  15   16   17   18   19   ++  20   21   22   23   24
 Ro<999>.841~.9~.941~.965~.973~.965~.909 ~.849~.782~.701~.606~.498~.377~.244~.099<998>.943~.775~.594~.406~.205<997>.994~.772~.540~.299~.047
 Nu=(1.75+0.014*s+t*(0.000645*t-0.0503))*1e      -6      ~~~ для соленой воды }
begin Result:=1.02;
    Interpolation( Temper, Length( Temp), Temp,Visc, Result );
    if Units=fuImperial then Result:=Result/(Foot*Foot); // convert to imperial
end;

(*                         //...странная интерполяция, но тоже была в работе...
procedure SFINEX1         // всё то же, но в ином порядке...
( N: integer; X,Y: array of single; X0: single; var YY: single );
var                     // Нелинейная ИНТЕРПОЛЯЦИЯ И ЗКСТРАПОЛЯЦИЯ ФУНКЦИИ Y(X)
  N1,J1,J2,J3,I: integer; SFIN: single;
label exlabel;
begin SFIN:=0; J1:=0; J2:=1; J3:=2; N1:=N-1;
  if N1 = 0 then begin SFIN:=Y[J1]; goto exlabel; end;
  if (X0 <= X[0]) and (N1 > 1) then begin
    SFIN:=Y[J1]+(Y[J2]-Y[J1]) * (X0-X[J1]) / (X[J2]-X[J1]); goto exlabel;
  end;
  if (X0 > X[N1]) then begin
    SFIN:=Y[N1]+(Y[N1]-Y[N1-1]) * (X0-X[N1]) / (X[N1]-X[N1-1]); goto exlabel;
  end;
  if (X0 <= X[J2]) and (N1 >= 2) then begin
    SFIN:=(X0-X[J3]) / (X[J1]-X[J2]) * ((X0-X[J2]) / (X[J1]-X[J3]) *
      Y[J1]-(X0-X[J1]) / (X[J2]-X[J3]) * Y[J2])+(X0-X[J1]) *
      (X0-X[J2]) * Y[J3] / ((X[J3]-X[J1]) * (X[J3]-X[J2]));
    goto exlabel;
  end;
  if (X0 > X[N1-1]) then begin SFIN:=(X0-X[N1]) / (X[N1-2]-X[N1-1]) *
      ((X0-X[N1-1]) / (X[N1-2]-X[N1]) * Y[N1-2]-(X0-X[N1-2]) *
      Y[N1-1] / (X[N1-1]-X[N1]))+(X0-X[N1-2]) * (X0-X[N1-1]) /
      (X[N1]-X[N1-2]) * Y[N1] / (X[N1]-X[N1-1]); goto exlabel;
  end;
  N1:=N-2;
  for I:=1 to N1 do if (X0 > X[I-1]) and (X0 <= X[I]) then
      SFIN:=0.5 * ((X0-X[I-1]) * (X0-X[I]) *
        (Y[I-2] / ((X[I-2]-X[I-1]) * (X[I-2]-X[I])) +
        Y[I+1] / ((X[I+1]-X[I-1]) * (X[I+1]-X[I]))) +
        (X0-X[I]) * ((X0-X[I-2]) / (X[I-1]-X[I-2]) +
        (X0-X[I+1]) / (X[I-1]-X[I+1])) * Y[I-1] /
        (X[I-1]-X[I])+(X0-X[I-1]) * ((X0-X[I-2]) /
        (X[I]-X[I-2])+(X0-X[I+1]) / (X[I]-X[I+1])) * Y[I] /
        (X[I]-X[I-1]));
exlabel: yy:=SFIN;
end; *)
end.

