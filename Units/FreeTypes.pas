
unit FreeTypes;

//{$mode delphi}
{$mode objfpc}

Interface
Uses Classes, SysUtils;
Const PixelCountMax=32768; // used for faster pixel acces when shading to viewport

Type
  TFloatType   = single;                        // All floatingpoint variables are of this type
  TFloatArray  = array of TFloatType;
  T2DCoordinate= record X,Y:TFloatType; end;    // 2D coordinate type
  T3DCoordinate= record X,Y,Z:TFloatType; end;  // 3D coordinate type
  T3DLine      = record A,B:T3DCoordinate; end; // 3D line type
  T3DPlane     = record a,b,c,d:TFloatType;end; // Description of a 3D plane: a*x + b*y + c*z -d = 0.0;
  T3DVector    = record X,Y,Z:TFloatType; end;  // 3D coordinate type

  operator =  (c1, c2:T3DCoordinate): boolean;
  operator <> (c1, c2:T3DCoordinate): boolean;
  operator =  (v1, v2:T3DVector):     boolean;
  operator <> (v1, v2:T3DVector):     boolean;
  operator +  (c:T3DCoordinate; v:T3DVector): T3DCoordinate;
  operator -  (c:T3DCoordinate; v:T3DVector): T3DCoordinate;
//operator -  ( A,B:T3DCoordinate ): T3DCoordinate;  // A-B
  operator -  (c1,c2:T3DCoordinate): T3DVector;
  operator /  ( A:T3DCoordinate; B:TFloatType ): T3DCoordinate;  // A/B
  operator *  (s:TFloatType; v:T3DVector): T3DVector;
  operator *  (v1:T3DVector; v2:T3DVector): T3DVector;
  operator *  (v1:T3DCoordinate; v2:T3DCoordinate): T3DCoordinate;

Type
  TRGBTriple = packed record rgbtBlue : BYTE;
                             rgbtGreen: BYTE;
                             rgbtRed  : BYTE; end;

  pRGBTripleArray               = ^TRGBTripleArray;
  TRGBTripleArray               = array[0..PixelCountMax-1] of TRGBTriple;
  T3DCoordinateArray            = array of T3DCoordinate;
  TPointArray                   = array of TPoint;
  TFreePrecisionType           = (fpLow,fpMedium,fpHigh,fpVeryHigh);                  // Precision of the ship-model
  TFreeIntersectionType        = (fiFree,fiStation,fiButtock,fiWaterline,fiDiagonal); // Different types of intersectionlines, stations, buttocks, waterlines and lines orientated in random planes
  TFreeModelView               = (mvPort,mvBoth);                                     // Show half the hull or the entire hull
  TFreeEditMode                = (emSelectItems,emAddPoint,emAddFlowLine);            // The program responds differnt to mouse actions depending on the editmode of the component
  TFreeHydrostaticType         = (fhShort,fhExtensive);                               // Determines how calculations are performed: short, extensive etc.
  TFreeHydrostaticsMode        = (fhSingleCalculation,fhMultipleCalculations);        // Used when creating hydrostatic reports
  TFreeHydrostaticsCalculation = (hcAll,hcVolume,hcMidship,hcWaterline,hcSAC,hcLateralArea,hcBulbSection);
  TFreeHydrostaticsCalculate   = set of TFreeHydrostaticsCalculation;                 // Set with all calculations to be performed
  TFreeHydrostaticsCalculateGravity = set of TFreeHydrostaticsCalculation;
  TFreeHydrostaticCoeff        = (fcProjectSettings,fcActualData);
  TFreeHydrostaticError        = (feNothingSubmerged,feMakingWater,feNotEnoughBuoyancy); // Errors that may occur when calculating hydrostatics
  TFreeHydrostaticErrors       = set of TFreeHydrostaticError;
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
  ZERO : T3DCoordinate = (X:0.0;Y:0.0;Z:0.0);
  EOL                  = #13#10;

Function F2S( Value: TFloatType ): TFloatType;
Function GetFloat(const S: String): TFloatType;
Function FloatTypeToStr( Value: TFloatType ): String;
Procedure WestPoint;
//Function Dist( A:T3DVector ): TFloatType;

Implementation

operator = (c1,c2:T3DCoordinate): boolean;
begin result := (c1.x=c2.x) and (c1.y=c2.y) and (c1.z=c2.z); end;

operator <> (c1,c2:T3DCoordinate): boolean;
begin result := not( (c1.x=c2.x) and (c1.y=c2.y) and (c1.z=c2.z) ); end;

operator = (v1, v2:T3DVector): boolean;
begin result := (v1.x=v2.x) and (v1.y=v2.y) and (v1.z=v2.z); end;

operator <> (v1, v2:T3DVector): boolean;
begin result := not( (v1.x=v2.x) and (v1.y=v2.y) and (v1.z=v2.z) ); end;

operator + (c:T3DCoordinate; v:T3DVector): T3DCoordinate ;
begin result.x := (c.x + v.x);
      result.y := (c.y + v.y);
      result.z := (c.z + v.z);
end;

operator - (c:T3DCoordinate; v:T3DVector): T3DCoordinate;
begin result.x := (c.x - v.x);
      result.y := (c.y - v.y);
      result.z := (c.z - v.z);
end;

operator - (c1,c2:T3DCoordinate): T3DVector;
begin result.x := (c1.x - c2.x);
      result.y := (c1.y - c2.y);
      result.z := (c1.z - c2.z);
end;

operator / ( A:T3DCoordinate; B:TFloatType ): T3DCoordinate;  // A/B
begin result.x := A.x/B;
      result.y := A.y/B;
      result.z := A.z/B;
end;

operator * (s:TFloatType; v:T3DVector): T3DVector; // scalar product
begin result.x := s*v.x;
      result.y := s*v.y;
      result.z := s*v.z;
end;

operator *  (v1:T3DCoordinate; v2:T3DCoordinate): T3DCoordinate;
begin result.x := (v1.y * v2.z) - (v1.z * v2.y);
      result.y := (v1.z * v2.x) - (v1.x * v2.z);
      result.z := (v1.x * v2.y) - (v1.y * v2.x);
end;

operator * (v1:T3DVector; v2:T3DVector): T3DVector; // cross product
begin result.x := (v1.y * v2.z) - (v1.z * v2.y);
      result.y := (v1.z * v2.x) - (v1.x * v2.z);
      result.z := (v1.x * v2.y) - (v1.y * v2.x);
end;

//Function Dist( A:T3DVector ): TFloatType;
//   begin result:=sqrt( A.x*A.x+A.y*A.y+A.z*A.z ); end;

function F2S( Value: TFloatType ): TFloatType;
var W:Double; begin W:=Value; W:=Round( W*1e6 ); Result:=W/1e6; end;

//Function Length( Str: AnsiString ): Integer; overload; // ??? reintroduce; override; virtual;
//   begin Result:=UTF8Length( Str ); end;

function FloatTypeToStr( Value: TFloatType ): String;
//begin Result:=FloatToStr( F2S( Value ) ); end;
begin Result:=FloatToStrF( F2S( Value ),ffGeneral,6,1 ); end;

function GetFloat( const S: String ): TFloatType;
  var LocalFormatSettings: TFormatSettings; I: Integer;
begin LocalFormatSettings:=DefaultFormatSettings;
  for i:=1 to length(S) do
    if S[i] ='.' then begin
      LocalFormatSettings.DecimalSeparator:='.';
      LocalFormatSettings.ThousandSeparator:=','; break; end else
    if S[i] =',' then begin
      LocalFormatSettings.DecimalSeparator:=',';
      LocalFormatSettings.ThousandSeparator:='.'; break; end;
    Result := StrToFloat( S,LocalFormatSettings );
end;

Procedure WestPoint;
Begin
  DefaultFormatSettings.DecimalSeparator:='.';
  DefaultFormatSettings.ThousandSeparator:=',';
  DefaultFormatSettings.ShortDateFormat:='yyyy-mm-dd';
  DefaultFormatSettings.ShortTimeFormat:='hh:nn:ss';
  FormatSettings:=DefaultFormatSettings;
end;

end.

