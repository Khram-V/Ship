
unit FreeTypes;

//{$mode delphi}
{$mode objfpc}

Interface
Uses Classes, SysUtils, Graphics;
Const PixelCountMax=32768; // used for faster pixel acces when shading to viewport

Type
  TFloatType   = single;                        // All floatingpoint variables are of this type
  TFloatArray  = array of TFloatType;
  T2DCoordinate= record X,Y:TFloatType; end;    // 2D coordinate type
  T3DVector    = record X,Y,Z:TFloatType; end;  // 3D coordinate type
  T3DLine      = record A,B:T3DVector; end; // 3D line type
  T3DPlane     = record a,b,c,d:TFloatType;end; // Description of a 3D plane: a*x+b*y+c*z -d = 0.0;




  operator <> (A,B: T3DVector): boolean;
  operator =  (A,B: T3DVector): boolean;
  operator - ( A,B: T3DVector ): T3DVector;  // A-B
  operator + ( A,B: T3DVector ): T3DVector;
  operator * ( A,B: T3DVector ): T3DVector;
  operator * ( D:TFloatType; B:T3DVector ): T3DVector;  // D*B
  operator / ( A:T3DVector; D:TFloatType ): T3DVector;  // A/D
Type
  TRGBTriple = packed record rgbtBlue : BYTE;
                             rgbtGreen: BYTE;
                             rgbtRed  : BYTE; end;

  pRGBTripleArray              = ^TRGBTripleArray;
  TRGBTripleArray              = array[0..PixelCountMax-1] of TRGBTriple;
  T3DVectorArray               = array of T3DVector;
  TPointArray                  = array of TPoint;
  TFreePrecisionType           = (fpLow,fpMedium,fpHigh,fpVeryHigh);                  // Precision of the ship-model
  TFreeIntersectionType        = (fiFree,fiStation,fiButtock,fiWaterline,fiDiagonal); // Different types of intersectionlines, stations, buttocks, waterlines and lines orientated in random planes
  TFreeModelView               = (mvPort,mvBoth);                                     // Show half the hull or the entire hull
  TFreeEditMode                = (emSelectItems,emAddPoint,emAddFlowLine);            // The program responds differnt to mouse actions depending on the editmode of the component
  TFreeHydrostaticsMode        = (fhSingleCalculation,fhMultipleCalculations);        // Used when creating hydrostatic reports
  TFreeHydrostaticsCalculation = (hcAll,hcVolume,hcMidship,hcWaterline,hcSAC,hcLateralArea,hcBulbSection);
  TFreeHydrostaticsCalculate   = set of TFreeHydrostaticsCalculation;                 // Set with all calculations to be performed
  TFreeHydrostaticsCalculateGravity = set of TFreeHydrostaticsCalculation;
  TFreeHydrostaticCoeff        = (fcProjectSettings,fcActualData);
//TFreeHydrostaticError        = (feNothingSubmerged,feMakingWater,feNotEnoughBuoyancy); // Errors that may occur when calculating hydrostatics
//TFreeHydrostaticErrors       = set of TFreeHydrostaticError;
//+++++++++++++++++++++++++++++++++++++
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
  EOL                  = #13#10;
//Var
//  FUnderWaterColor: TColor; // Default color used for shading underwaterpart of the vessel
//  FUnderWaterColorAlpha: byte;


Function F2S( Value: TFloatType ): TFloatType;
//function Point3D( X,Y,Z: TFloattype): T3DVector;
Function GetFloat( var S: AnsiString): TFloatType;
Function GetInteger( var S:AnsiString ): Integer;
Function GetBoolean( var S:AnsiString ): Boolean;
function FloatToDec( Value: TFloatType; Maxlength: integer ): AnsiString;
                 // Convert a floatingpoint to a string value with a max.number
                 // of specified decimals All trailing zeros will be removed
Function FloatTypeToStr( Value: TFloatType ): AnsiString;
Procedure WestPoint;
Function BlankOff( S: AnsiString ): AnsiString;
//Function Dist( A:T3DVector ): TFloatType;
Function Distance2D( P1,P2: T2DCoordinate ): extended;
Function Distance3D( P1,P2: T3DVector ): extended;
//function GetUnderwaterColor: TColor;
//function GetUnderwaterColorAlpha: byte;
//procedure SetUnderwaterColor(Val: TColor);
//procedure SetUnderwaterColorAlpha(AValue: byte);
//property UnderWaterColor: TColor read GetUnderWaterColor write SetUnderwaterColor;
//property UnderWaterColorAlpha: byte read GetUnderWaterColorAlpha write SetUnderwaterColorAlpha;



Implementation
//function Point3D( X,Y,Z: TFloattype): T3DVector;   == SetPoint
//   begin Result.X:=X;
//         Result.Y:=Y;
//         Result.Z:=Z; end;

operator = ( A,B: T3DVector ): boolean;
begin result:=(A.x=B.x) and (A.y=A.y) and (A.z=B.z); end;

operator <> (A,B: T3DVector ): boolean;
begin result:=(A.x<>B.x) or (A.y<>A.y) or (A.z<>B.z); end;

operator + ( A,B: T3DVector ): T3DVector ;
begin result.x:=(A.x+B.x);
      result.y:=(A.y+B.y);
      result.z:=(A.z+B.z);
end;

operator - ( A,B: T3DVector ): T3DVector;   // A-B
begin result.x:=(A.x-B.x);
      result.y:=(A.y-B.y);
      result.z:=(A.z-B.z);
end;

operator / ( A:T3DVector; D:TFloatType ): T3DVector;  // A/B
begin result.x:=A.x/D;
      result.y:=A.y/D;
      result.z:=A.z/D;
end;

operator * ( D:TFloatType; B:T3DVector): T3DVector;   // scalar product
begin result.x:=D*B.x;
      result.y:=D*B.y;
      result.z:=D*B.z;
end;

operator * ( A,B: T3DVector ): T3DVector;  // cross product
begin result.x:=(A.y*B.z)-(A.z*B.y);
      result.y:=(A.z*B.x)-(A.x*B.z);
      result.z:=(A.x*B.y)-(A.y*B.x);
end;

function Distance2D(P1, P2: T2DCoordinate): extended;
  var dX, dY: extended;
begin dX:=P2.X-P1.X;
      dY:=P2.Y-P1.Y; Result:=sqrt( sqr( dX )+sqr( dY ) );
end;{Distance2D}

function Distance3D(P1, P2: T3DVector): extended;
  var dX,dY,dZ: extended;
begin dX:=P2.X-P1.X;
      dY:=P2.Y-P1.Y;
      dZ:=P2.Z-P1.Z; Result:=sqrt( sqr( dX )+sqr( dY )+sqr( dZ ) );
end;{Distance3D}

//Function Dist( A:T3DVector ): TFloatType;
//   begin result:=sqrt( A.x*A.x+A.y*A.y+A.z*A.z ); end;
//Function Length( Str: AnsiString ): Integer; overload; // ??? reintroduce; override; virtual;
//   begin Result:=UTF8Length( Str ); end;

function F2S( Value: TFloatType ): TFloatType;
var W:Double;
begin
  if abs( Value )<1e-5 then Result:=0 else begin
  W:=Value; W:=Round( W*1e6 ); Result:=W/1e6; end;
end;

function FloatTypeToStr( Value: TFloatType ): AnsiString;
begin Result:=FloatToStr( F2S( Value ) ); end;
//begin Result:=FloatToStrF( F2S( Value ),ffGeneral,6,1 ); end;

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

//if K>0 then begin WriteLn( copy( S,I,K-I )+'['+IntToStr(Length(S))+'] <- '+S ); ReadLn; end;
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
(*
function GetUnderwaterColor: TColor;
begin Result:=(FUnderWaterColor and $FFFFFF) or (FUnderWaterColorAlpha shl 24 );
end;
function GetUnderwaterColorAlpha: byte;
begin Result:=FUnderWaterColorAlpha; end; // shr 24; end;

procedure SetUnderwaterColorAlpha( AValue: byte );
begin FUnderWaterColor:=(FUnderWaterColor and $FFFFFF) or (AValue shl 24 );  ///***???
      FUnderWaterColorAlpha:=AValue;
end;
procedure SetUnderwaterColor( Val: TColor );
begin FUnderWaterColor:=(Val and $FFFFFF) or (FUnderWaterColorAlpha shl 24 );
end;
*)
end.

