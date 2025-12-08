{
  included in FreeGometry.pas 
}

function AreaStr(Units: TFreeUnitType): String;
begin if Units=fuImperial then Result:=UserString(465)  //Result:='ft^2 '
                          else Result:=UserString(452); //Result:='m^2 ';
end;
// Returns a string value with the length units
function LengthStr(Units: TFreeUnitType): String;
begin if Units=fuImperial then Result:=UserString(464)  //'ft '
                          else Result:=UserString(451); //'m ';
end;
// Returns a string value with the moment of inertia units
function InertiaStr(Units: TFreeUnitType): String;
begin if Units=fuImperial then Result:=UserString(467) //  Result:='ft^4 '
                          else Result:=UserString(470) //  Result:='m^4 ';
end;

function VolStr(Units: TFreeUnitType): String;
begin if Units=fuImperial then Result:=UserString(466)  // Result:='ft^3 '
                          else Result:=UserString(453); // Result:='m^3 ';
end;
{
function DensStr(Units: TFreeUnitType): String;
begin if Units=fuImperial then Result:='lbs/ft^3 '
                            else Result:='t/m^3 '; end;
function ViscStr(Units: TFreeUnitType): String;
begin if Units=fuImperial then Result:='ft^2/s '
                            else Result:='m^2/s '; end;
function DegrStr(Units: TFreeUnitType): String;
begin result:='° ';
  if Units=fuImperial then Result:='degr '
                        else Result:='degr '; end;
}
function LenMMStr(Units: TFreeUnitType): String;
begin if Units=fuImperial then Result:='in '
                          else Result:='мм ';
end;

function VolumeToDisplacement              // Converts a volume to displacement
( Volume,Density,AppCoeff: Real; Units: TFreeUnitType): Real;
begin         // convert to British imperial tons (1 imperial LONG ton=2240 lb)
  if Units=fuImperial then Result:=Volume*AppCoeff*Density/2240
                      else Result:=Volume*AppCoeff*Density;
end;
function DensityStr(Units: TFreeUnitType): String;
begin if Units=fuImperial then Result:=UserString(468)  // Result:='lbs/ft^3 '
                          else Result:=UserString(469); // Result:='t/m^3 ';
end;
function WeightStr(Units: TFreeUnitType): String;
begin if Units=fuImperial then Result:=UserString(473)  //'tons '
                          else Result:=UserString(474); //'tonnes';
end;
function BoolToStr( Val: boolean ): String;
   begin if Val then Result:='1' else Result:='0'; end;

procedure ClipTriangle( P1,P2,P3: Vector; s1,s2,s3: Real;
        var Nf,Nb: integer; var Front,Back: VectorArray); overload;
var T: Real;
    P: Vector;
begin
  Nf:=0;
  Nb:=0;
  if (S1<=0) and (S2<=0) and (S3<=0) then begin // all at the back of the plane
    Nb:=3;
    Setlength(Back,Nb);
    Back[0]:=P1;
    Back[1]:=P2;
    Back[2]:=P3;
  end else
  if (S1>0) and (S2>0) and (S3>0) then begin   // all at the front of the plane
    Nf:=3;
    Setlength(Front,Nf);
    Front[0]:=P1;
    Front[1]:=P2;
    Front[2]:=P3;
  end else begin       // Triangle spans the plane,calculate the intersections
    Setlength(Back,6);
    Setlength(Front,6);
    if S1 <= 0 then begin Inc(Nb); Back[Nb-1]:=P1; end;
    if S1 >= 0 then begin Inc(Nf); Front[Nf-1]:=P1; end;
    if ((S1 < 0) and (S2 > 0))
    or ((S1 > 0) and (S2 < 0)) then begin
      if S1=S2 then begin T:=0.5; end
                 else T:=-s1/(s2-s1);
      P:=P1+T*(P2-P1);
      Inc(Nb); Back[Nb-1]:=P;
      Inc(Nf); Front[Nf-1]:=P;
    end;
    if S2 <= 0 then begin Inc(Nb); Back[Nb-1]:=P2; end;
    if S2 >= 0 then begin Inc(Nf); Front[Nf-1]:=P2; end;
    if ((S2 < 0) and (S3 > 0)) or ((S2 > 0) and (S3 < 0)) then begin
      if S2=S3 then begin T:=0.5; end else T:=-S2/(S3-S2);
      P:=P2+T*(P3-P2);
      Inc(Nb); Back[Nb-1]:=P;
      Inc(Nf); Front[Nf-1]:=P;
    end;
    if S3 <= 0 then begin Inc(Nb); Back[Nb-1]:=P3; end;
    if S3 >= 0 then begin Inc(Nf); Front[Nf-1]:=P3; end;
    if ((S3 < 0) and (S1 > 0)) or ((S3 > 0) and (S1 < 0)) then begin
      if S3=S1 then begin T:=0.5; end else T:=-S3/(S1-S3);
      P:=P3+T*(P1-P3);
      Inc(Nb); Back[Nb-1]:=P;
      Inc(Nf); Front[Nf-1]:=P;
    end;
  end;
end;

procedure ClipTriangle
( P1,P2,P3: Vector; Plane: Plate; var Nf,Nb: integer; var Front,Back: VectorArray);
var  S1,S2,S3: Real;
begin
  S1:=Plane.a*P1.x+Plane.b*P1.y+Plane.c*P1.z+Plane.d;
  S2:=Plane.a*P2.x+Plane.b*P2.y+Plane.c*P2.z+Plane.d;
  S3:=Plane.a*P3.x+Plane.b*P3.y+Plane.c*P3.z+Plane.d;
  ClipTriangle( P1,P2,P3,s1,s2,s3,Nf,Nb,Front,Back );
end;

function ConvertDimension(Value: Real; Units: TFreeUnitType): String;
var Feet: integer; Inches: Real;
begin
  if Units=fuImperial then begin
    if Value<0 then Feet:=-abs(Trunc(Value))
               else Feet:=Trunc(Value);
    Inches:=abs(Value-Feet)*12;
    Result:=IntToStr(Feet);
    if (Feet=0) and (Value<0) then Result:='-'+Result;
    Result:=Result+''''+#32+FloatToDec(Inches,1)+'''''';
  end else
  Result:=FloatToDec( Value,2 ); //Str( Round( Value*100 )/100 );
end;

Function DistancePointToLine(P,P1,P2:Vector):Real;
var V1,V2: Vector; Len: Real;
begin
  V1:=P-P1;
  V2:=P1-P2; Len:=Abs( V2 );
  if Len>1e-6 then Result:=Abs( V1*V2 )/Len
              else Result:=Abs( V1 );
end;
{
function DistancePointToPlane( P: Vector; Plane: Plate ): Real;
begin Result:=Plane.a*P.x + Plane.b*P.y + Plane.c*P.z + Plane.d;
end;
}
function DistanceToLine
( P1,P2: TPoint; X,Y: integer; var Parameter: Real ): Real;
  var Pt: Place;
begin
  if (P1.X<0) and (P2.X<0) then Result:=1e6 else
  if (P1.X>Screen.Width) and (P2.X>Screen.Width) then Result:=1e6 else
  if (P1.Y<0) and (P2.Y<0) then Result:=1e6 else
  if (P1.Y>Screen.Height) and (P2.Y>Screen.Height) then Result:=1e6 else
  if (P2.X=P1.X) and (P1.Y=P2.Y) then begin Result:=Hypot( P1.X-X,P1.Y-Y );
  end else begin
    Parameter:=((X-P1.X)*(P2.X-P1.X)+(Y-P1.Y)*(P2.Y-P1.Y))/(sqr(P2.X-P1.X)+Sqr(P2.Y-P1.Y));
    if (Parameter >= 0) and (Parameter <= 1) then begin
      Pt.X:=P1.X+Parameter*(P2.X-P1.X);
      Pt.Y:=P1.Y+Parameter*(P2.Y-P1.Y);
      if (Pt.X >= 0) and (Pt.Y >= 0)
      and (Pt.X <= Screen.Width)
      and (Pt.Y <= Screen.Height) then Result:=Hypot( Pt.X-X,Pt.Y-Y )
      else Result:=1e6;
    end else Result:=1e6;
  end;
end;
function DisplacementToVolume              // Converts a displacement to volume
 ( Displ,Density,AppCoeff: Real; Units: TFreeUnitType ): Real;
begin Result:=Displ/Density/AppCoeff;
      if Units=fuImperial then Result:=Result*2240;
end;
{ if Units=fuImperial // convert to British imperial tons (1 imperial LONG ton=2240 lb)
     then Result:=Displ*2240/Density else Result:=Displ/Density;
          Result:=Result/AppCoeff; end;
}
function DotProduct( const U,V: Vector): Real;
   begin Result := (U.X*V.X)+(U.Y*V.Y)+(U.Z*V.Z); end;

function Interpolate( P1,P2: Vector; Param: Real): Vector;
   begin Result:=P1+Param*(P2-P1); end;

Function Lines3DIntersect(P1,P2,P3,P4:Vector;var Param:Real;var Int:Vector):Boolean;
//   Calculate the line segment PaPb that is the shortest route between
//   two lines P1P2 and P3P4. Calculate also the values of mua and mub where
//      Pa = P1 + mua (P2 - P1)
//      Pb = P3 + mub (P4 - P3)
//   Return FALSE if no solution exists.

const eps=1e-12; // 1e-6;
var pa,{pb,}p13,p43,p21:Vector;
    denom,mua,mub,d1343,d4321,d1321,d4343,d2121: Real; // L1,L2:Real;
begin Result:=False;
   P13:=P1-P3;
   P43:=P4-P3; d4343:=Sqr( P43 ); if sqr( d4343 )<eps then exit;
   P21:=P2-P1; d2121:=Sqr( P21 ); if sqr( d2121 )<eps then exit;
   d4321:=p43.x * p21.x + p43.y * p21.y + p43.z * p21.z;
   denom:=d2121*d4343 - d4321*d4321; if (abs(denom)<eps) then exit;
   d1343:=p13.x*p43.x + p13.y*p43.y + p13.z*p43.z;
   d1321:=p13.x*p21.x + p13.y*p21.y + p13.z*p21.z;
   mua:=(d1343*d4321 - d1321*d4343)/denom;
   mub:=(d1343 + d4321*(mua)) / d4343;
   PA:=P1+mua*P21;
   if (mua>-1e-6) and (mua<1) and (mub>-1e-6) and (mub<1) then begin
      Result:=true;
      Int:=Pa;
   end;
{  PB:=P3+mub*P43;
   if not result then begin
      L1:=Abs(P1-P2);
      L2:=Abs(P3-P4);
      Result:=(Abs(P1-Pa)<=L1) and (Abs(P2-Pa)<=L1) and
              (Abs(P3-Pb)<=L2) and (Abs(P4-Pb)<=L2);
      if Result then Int:=Pa;
   end; }
end;

// Calculate the mid-point between P1 and P2
function Midpoint(P1,P2:Vector):Vector;
   begin Result:=0.5*(P1+P2); end;
function Mid3point( P1,P2,P3: Vector ): Vector;
   begin Result:=(P1+P2+P3)/3.0; end;

function MirrorPlane( P:Vector; Plane:Plate ):Vector;
   begin Result := P + 2.0*( ProjectPointOnPlane( P,Plane )-P ); end;

// Finds out with how many decimals a number should be presented
function NumberOfDecimals(Value: Real): integer;
var I: Real;
begin Value:=Abs( Value );
   if Value < 1e-6 then Value:=1e-6;
   I:=Ln( Value )/2.30258;
   Result:=4-Trunc(I);
   if Result < 0 then Result:=0;
   if Result > 3 then Result:=3;
end;

// Function to determine if a plane intersects a bounding box
function PlaneIntersectsBox(Min,Max: Vector; Plane: Plate): boolean;
var
  P: array[1..8] of Vector; I: integer; S,SMin,SMax: Real;
begin SMin:=0; SMax:=0;
  P[1]:=Min;
  P[2].X:=Max.X;  P[2].Y:=Min.Y;  P[2].Z:=Min.Z;
  P[3].X:=Max.X;  P[3].Y:=Max.Y;  P[3].Z:=Min.Z;
  P[4].X:=Min.X;  P[4].Y:=Max.Y;  P[4].Z:=Min.Z;
  P[5].X:=Min.X;  P[5].Y:=Min.Y;  P[5].Z:=Max.Z;
  P[6].X:=Max.X;  P[6].Y:=Min.Y;  P[6].Z:=Max.Z;
  P[7]:=Max;
  P[8].X:=Min.X;  P[8].Y:=Max.Y;  P[8].Z:=Max.Z;
  for I:=1 to 8 do begin
    S:=Plane.A*P[I].x+Plane.B*P[I].y+Plane.C*P[I].z+Plane.D;
    if I=1 then begin SMin:=S; SMax:=S; end;
    if S < SMin then SMin:=S;
    if S > SMax then SMax:=S;
  end;
  Result:=((Smin<=0.0) and (SMax>=0.0)) or ((SMax<=0.0) and (SMin>=0.0));
end;

// Calculates the plane with a given normal N through point P
function PlanePointNormal(P,Normal: Vector): Plate;
begin
  Result.a:=Normal.x;
  Result.b:=Normal.y;
  Result.c:=Normal.z;
  Result.d:=-P.x*Result.a-P.y*Result.b-P.z*Result.c;
end;

function PlanePPP(P1,P2,P3:Vector):Plate;
var N : Vector;
    L : Real;
begin
   // Calculate normal
   N:=(P2-P1)*(P3-P1);
   // Make normal unit length
   L:=Abs( N ); // Sqrt((N.X*N.X)+(N.Y*N.Y)+(N.Z*N.Z));
   if L<=0 then L:=0.0000001;
   Result.a:=N.x/L;
   Result.b:=N.y/L;
   Result.c:=N.z/L;
   Result.d:=-P1.x*Result.a-P1.y*Result.b-P1.z*Result.c;
end;

function PointInBlock(P,Pmin,Pmax: Vector): boolean;
begin Result:=((P.X >= Pmin.X) and (P.Y >= Pmin.Y) and (P.Z >= Pmin.Z))
          and ((P.X <= Pmax.X) and (P.Y <= Pmax.Y) and (P.Z <= Pmax.Z));
end;

// This function calculates if a point lies inside a triangle
// assuming it lies on the plane determined by the triangle

function PointInTriangle( P,A,B,C:Vector ):Boolean;
   function SameSide( P1,P2,A,B: Vector ):Boolean; var BA: Vector; Dp: Real;
   begin BA:=B-A; Dp:=DotProduct( BA*(P1-A),BA*(P2-A) );
          if abs( Dp )<1e-5 then Dp:=0.0;   //? Dp-1+1;
          Result:=Dp>=0.0; end;
begin Result:=SameSide(P,A,B,C) and SameSide(P,B,A,C) and SameSide(P,C,A,B);
end;

function RotatePoint(Center,Point: Vector; Angle,Elevation:Real): Vector;
var CosAngle,SinAngle,CosElevation,SinElevation: Real;
begin
// This function takes a point from 3D space and rotates it around the C center
// of the scene as specified by the viewing-parameters (angle/elevation)
// translate centerpoint back to origin
  CosAngle:=cos(DegToRad(Angle));
  SinAngle:=sin(DegToRad(Angle));
  CosElevation:=cos(DegToRad(Elevation));
  SinElevation:=sin(DegToRad(Elevation));
  Point-=Center;  // Rotate a point first around Y-axis then around the Z-axis
  Result.x:=(Point.x*CosElevation+Point.z*SinElevation)*CosAngle-Point.y*SinAngle;
  Result.y:=(Point.x*CosElevation+Point.z*SinElevation)*SinAngle+Point.y*CosAngle;
  Result.z:=(-Point.x*SinElevation+Point.z*CosElevation); // Translate origin back to midpoint
  Result+=Center;
end;
{
// converts pounds to Newton
function PoundsToNewton(InpLbs: Real): Real;
   begin Result:=InpLbs*Lbs*9.81; end;
}
function ConvertCoordinate(Coord: String; OldCoord: Real):Real;
{
  parses input "Coord" and and returns the new value of a coordinate
  if first character of input is (RelIdentifier - currently '@')
     then the input value is added to the old value "OldCoord".
  if the first character of the value is '-',
     then the remainder is treated as a negative value
  if the remainding value contains ONE '-'
     then the part after that '-' is considered as a fraction of a unit
     The size of the fraction is const. "InchFractions"
}
var myString: String;
    myFactor,myOldValue,myWholeFeet,myWholeInch,myFracInch: Real;
    myFracPos: Integer;
const RelIdentifier: String='@'; InchFractions: Real=8;
begin
     myString:=Coord;
     myFactor:=1.0;
     myOldValue:=OldCoord;
     myWholeFeet:=0.0;
     myWholeInch:=0.0;
     myFracInch:=0.0;
  if LeftStr(myString,1)=RelIdentifier then begin // get rid of the '@'
     myString:=MidStr(myString,2,255);
     if Pos(RelIdentifier,myString)>0 then myString:='0'; // make sure not to have another '@' (and a 0 doesn't hurt)
  end else myOldValue:=0; // we have a new value now, so don't add the old one!
  if LeftStr( myString,1 )='-' then begin               // get rid of the minus
    myFactor:=-1.0;
    myString:=MidStr(myString,2,255);
  end;
  myFracPos:=Pos('-', myString);
  if myFracPos>0 then begin     // check whether we have imperial input format
    if myFracPos>1 then begin   // check whether there is an whole feet value
      myWholeFeet:=StrToFloat(LeftStr(myString,myFracPos-1));
      myString:=MidStr(myString,myFracPos+1,255);
    end;
    myFracPos:=Pos('-', myString); // is there a second "-", i.e. do we have also fractional inches?
    if myFracPos>0 then begin
      if myFracPos>1 then begin  // check whether there is an whole inch value
        myWholeInch:=StrToFloat(LeftStr(myString, myFracPos-1));
        myString:=MidStr(myString,myFracPos,255);
      end; // new: check whether there is a + or a - to add or subtract a half fraction
      myString:= MidStr(myString,2,255);
      if (RightStr(myString,1)='-') then begin
          myFracInch:=StrToFloat(LeftStr(myString,Pos('-',myString)-1))-0.5;
      end else
      if (RightStr(myString,1)='+') then begin
          myFracInch:=StrToFloat(LeftStr(myString,Pos('+',myString)-1))+0.5;
      end else myFracInch:=StrToFloat(myString);   // end new
    end else myWholeInch:=StrToFloat(myString);      // no fractional inches
  end else myWholeFeet:=StrToFloat(myString);       // no imperial input format
  Result:=myOldValue+myFactor*(myWholeFeet+myWholeInch/12+myFracInch/(12*InchFractions));
end;

function ProjectPointOnPlane(P: Vector; Plane: Plate): Vector; // Projects a point on a plane
var R,Q: Real;
begin Q:=Sqr(Plane.a)+Sqr(Plane.b)+Sqr(Plane.c);
   if Q<>0.0 then begin
      R:=(Plane.a*P.x+Plane.b*P.y+Plane.c*P.z+Plane.d)/Q;
      Result.x:=P.x-Plane.a*R;
      Result.y:=P.y-Plane.b*R;
      Result.z:=P.z-Plane.c*R;
   end else Result:=ZERO;
end;

Function ProjectPointOnLine( P,P1,P2: Vector ):Vector;
  var V1,V2: Vector; L: Real;
begin V1:=P-P1; V2:=P2-P1; L:=Sqr( V2 );
   if L>1e-12 then Result:=P1+(DotProduct( V1,V2 )/L)*V2 else Result:=P;
end;

// This procedure takes a lot of linesegments
//      and tries to connect them into as few as possible splines

procedure JoinSplineSegments
( JoinError:Real; ForceToOneSegment:Boolean; List:TFasterList );
{ type TSegmentRecord = record Length: Real; COG: Vector; end;
       TSegmentdata   = array[0..0] of TSegmentRecord;
       PSegmentdata   = ^TSegmentdata; }
var I,J,MatchIndex: Integer;
    Fixed,Match,Nearest: TFreeSpline;
    D1,D2,D3,D4,NearestDist,Min:Real;
    FixedClosed,MatchClosed: Boolean;
    function Minimum( D1,D2,D3,D4:Real ):Real;
    begin                Result:=D1;
       if D2<Result then Result:=D2;
       if D3<Result then Result:=D3;
       if D4<Result then Result:=D4;
    end;
begin I:=1; // First remove any single linesegments;
   while I<=List.Count do begin
      Fixed:=List.Items[I-1];
      if Fixed.nS>1
         then FixedClosed:=Sqr(Fixed.Point[0]-Fixed.Point[Fixed.nS-1])<1e-10
         else FixedClosed:=False;
      if (Fixed.nS>1) and (Not FixedClosed) then begin
         NearestDist:=1e30;
         Nearest:=nil;
         MatchIndex:=-1;
         for J:=1 to List.Count do if I<>J then begin Match:=List.Items[J-1];
            if Match.nS>1
               then MatchClosed:=Sqr(Match.Point[0]-Match.Point[Match.nS-1])<1e-10
               else MatchClosed:=False;
            if (Match.nS>1) and (Not MatchClosed) then begin
               D1:=Sqr(Fixed.Point[0]-Match.Point[0]);
               D2:=Sqr(Fixed.Point[0]-Match.Point[Match.nS-1]);
               D3:=Sqr(Fixed.Point[Fixed.nS-1]-Match.Point[0]);
               D4:=Sqr(Fixed.Point[Fixed.nS-1]-Match.Point[Match.nS-1]);
               Min:=Minimum( D1,D2,D3,D4 );
               if Min<NearestDist then begin
                  NearestDist:=Min;
                  Nearest:=Match;
                  MatchIndex:=J;
                  if Min<1e-10 then break;
               end;
            end;
         end;
         if Nearest<>nil then begin Match:=Nearest;
            D1:=Sqr(Fixed.Point[0]-Match.Point[0]);
            D2:=Sqr(Fixed.Point[0]-Match.Point[Match.nS-1]);
            D3:=Sqr(Fixed.Point[Fixed.nS-1]-Match.Point[0]);
            D4:=Sqr(Fixed.Point[Fixed.nS-1]-Match.Point[Match.nS-1]);
            Min:=Minimum( D1,D2,D3,D4 );
            if (Min<JoinError) or (ForceToOneSegment) then begin // The splines do touch each other on one of their ends
               Fixed.Capacity:=Fixed.Capacity+Match.nS;          // Increase capacity of fixed spline
               if Min=D1 then Fixed.InsertSpline( 0,      True, False,Match) else // Case 1
               if Min=D2 then Fixed.InsertSpline( 0,      False,False,Match) else // Case 2
               if Min=D3 then Fixed.InsertSpline(Fixed.nS,False,False,Match) else // Case 3
               if Min=D4 then Fixed.InsertSpline(Fixed.nS,True, False,Match)      // Case 4
                  ;// else ShowMessage( 'Error in comparing minimum values.' );
               List.Delete( MatchIndex-1 );      // Destroy the matching spline
               Match.Destroy;
               I:=0; // Reset match index to start searching for a new matching spline
            end;
         end;
      end;     Inc(I);
   end;
end;

function RandomColor:TColor; const B = 40;
begin Result:=RGB(B+Random(255-B),B+Random(255-B),B+Random(255-B));
end;

// Rotates a Vector around the origin

function RotateVector
( P0: Vector; sinx,cosx,siny,cosy,sinz,cosz: Real ): Vector;
var r11,r12,r13,r21,r22,r23,r31,r32,r33: Real;
begin // Do rotation
  r11:=cosy*cosz;
  r12:=cosy*sinz;
  r13:=-siny;
  r21:=sinx*siny*cosz-cosx*sinz;
  r22:=sinx*siny*sinz+cosx*cosz;
  r23:=sinx*cosy;
  r31:=cosx*siny*cosz+sinx*sinz;
  r32:=cosx*siny*sinz-sinx*cosz;
  r33:=cosx*cosy;
  Result.x:=P0.x*r11+P0.y*r12+P0.z*r13;
  Result.y:=P0.x*r21+P0.y*r22+P0.z*r23;
  Result.z:=P0.x*r31+P0.y*r32+P0.z*r33;
end;

function SetPlane( a,b,c,d: Real ): Plate;
begin Result.a:=a;
      Result.b:=b;
      Result.c:=c;
      Result.d:=d;
end;

function MakeLength(Value: Real; Decimals,DesLength: integer): String;
var Input: String;
begin
  if Decimals=-1 then Decimals:=NumberOfDecimals(Value);
  Input:=FloatToStrF(Value,ffFixed,10,Decimals);
  while Length(Input) < DesLength do Input:=' '+Input;
  Result:=Input;
end;

function MakeLength(Value: String; DesLength: integer): String;
   begin while UTF8Length(Value)<DesLength do Value:=Value+' '; Result:=Value;
   end;
procedure MinMax(P: Vector; var Min,Max: Vector);
   begin if P.X<Min.X then Min.X:=P.X else if P.X>Max.X then Max.X:=P.X;
         if P.Y<Min.Y then Min.Y:=P.Y else if P.Y>Max.Y then Max.Y:=P.Y;
         if P.Z<Min.Z then Min.Z:=P.Z else if P.Z>Max.Z then Max.Z:=P.Z;
   end;

// Normalize a iVect to unit length
function Normalize( const P: Vector ): Vector; var L: Real;
   begin //Result:=P/Abs( P ); end;
       L:=sqr( P ); if L>=1e-36 then Result:=P/sqrt( L ) else Result:=P; end;   //if IsNan(L) then///

Function UnifiedNormal( const P1,P2,P3:Vector ):Vector;
   begin Result:=Normalize( (P2-P3)*(P2-P1) ); end;

procedure FillColor(Parameter:Real; var R,G,B:byte); // Calculate color on basis of wavelength (0.0-1.0)
var Blue,Green,Red,wavelength: Real;
  function Adjust(Color: Real): integer;
  begin if color <= 0.0 then Result:=0 else
        if Color >= 1.0 then Result:=255 else begin
           Result:=Round(255*Power(Color,0.8));
           //if result<0 then result:=0 else if result>255 then result:=255;
         end;
  end;
begin
  Parameter:=1-Parameter;
  wavelength:=420+Parameter*280;
  case TRUNC(Wavelength) of
    380..439: begin
      Red:=-(Wavelength-440)/(440-380);
      Green:=0.0;
      Blue:=1.0;
    end;
    440..489: begin
      Red:=0.0;
      Green:=(Wavelength-440)/(490-440);
      Blue:=1.0;
    end;
    490..509: begin
      Red:=0.0;
      Green:=1.0;
      Blue:=-(Wavelength-510)/(510-490);
    end;
    510..579: begin
      Red:=(Wavelength-510)/(580-510);
      Green:=1.0;
      Blue:=0.0;
    end;
    580..644: begin
      Red:=1.0;
      Green:=-(Wavelength-645)/(645-580);
      Blue:=0.0;
    end;
    645..780: begin
      Red:=1.0;
      Green:=0.0;
      Blue:=0.0;
    end;
    else
      Red:=0.0;
      Green:=0.0;
      Blue:=0.0
  end;
  R:=Adjust( Red );
  G:=Adjust( Green );
  B:=Adjust( Blue );
end;

// find nearest IGES color corresponding to a windows color

function FindIGSColorIndex( Color:TColor ):integer;
const IGSLayerColors: array[0..8] of TColor =
//  ( 0,clBlack,clRed,clGreen,clBlue,clYellow,clFuchsia,clAqua,clWhite );
    ( 0,clWhite,clRed,clGreen,clBlue,clYellow,clAqua,clFuchsia,clBlack );
var R,G,B,R1,G1,B1,I,Dist,Tmp:Integer;
begin Result:=0;
   R:=GetRValue( Color );
   G:=GetGValue( Color );
   B:=GetBValue( Color ); Dist:=256*256+1; // 512^2
   for I:=1 to 8 do begin
      R1:=abs( R-GetRValue( IGSLayerColors[I] ) );
      G1:=abs( G-GetGValue( IGSLayerColors[I] ) );
      B1:=abs( B-GetBValue( IGSLayerColors[I] ) );
      Tmp:=R1*R1 + G1*G1 + B1*B1;
      if Tmp<=Dist then begin Dist:=Tmp; Result:=I; end;
   end;
end;

// find nearest DXF color corresponding to a windows color

function FindDXFColorIndex( Color:TColor ):integer;
const DXFLayerColors: array[1..255] of TColor =
     ($0000FF, $00FFFF, $00FF00, $FFFF00, $FF0000, $FF00FF, $000000, $808080, $C0C0C0, $0000FF,
      $7F7FFF, $0000A5, $5252A5, $00007F, $3F3F7F, $00004C, $26264C, $000026, $131326, $003FFF,
      $7F9FFF, $0029A5, $5267A5, $001F7F, $3F4F7F, $00134C, $262F4C, $000926, $131726, $007FFF,
      $7FBFFF, $0052A5, $527CA5, $003F7F, $3F5F7F, $00264C, $26394C, $001326, $131C26, $00BFFF,
      $7FDFFF, $007CA5, $5291A5, $005F7F, $3F6F7F, $00394C, $26424C, $001C26, $132126, $00FFFF,
      $7FFFFF, $00A5A5, $52A5A5, $007F7F, $3F7F7F, $004C4C, $264C4C, $002626, $132626, $00FFBF,
      $7FFFDF, $00A57C, $52A591, $007F5F, $3F7F6F, $004C39, $264C42, $00261C, $132621, $00FF7F,
      $7FFFBF, $00A552, $52A57C, $007F3F, $3F7F5F, $004C26, $264C39, $002613, $13261C, $00FF3F,
      $7FFF9F, $00A529, $52A567, $007F1F, $3F7F4F, $004C13, $264C2F, $002609, $132617, $00FF00,
      $7FFF7F, $00A500, $52A552, $007F00, $3F7F3F, $004C00, $264C26, $002600, $132613, $3FFF00,
      $9FFF7F, $29A500, $67A552, $1F7F00, $4F7F3F, $134C00, $2F4C26, $092600, $172613, $7FFF00,
      $BFFF7F, $52A500, $7CA552, $3F7F00, $5F7F3F, $264C00, $394C26, $132600, $1C2613, $BFFF00,
      $DFFF7F, $7CA500, $91A552, $5F7F00, $6F7F3F, $394C00, $424C26, $1C2600, $212613, $FFFF00,
      $FFFF7F, $A5A500, $A5A552, $7F7F00, $7F7F3F, $4C4C00, $4C4C26, $262600, $262613, $FFBF00,
      $FFDF7F, $A57C00, $A59152, $7F5F00, $7F6F3F, $4C3900, $4C4226, $261C00, $262113, $FF7F00,
      $FFBF7F, $A55200, $A57C52, $7F3F00, $7F5F3F, $4C2600, $4C3926, $261300, $261C13, $FF3F00,
      $FF9F7F, $A52900, $A56752, $7F1F00, $7F4F3F, $4C1300, $4C2F26, $260900, $261713, $FF0000,
      $FF7F7F, $A50000, $A55252, $7F0000, $7F3F3F, $4C0000, $4C2626, $260000, $261313, $FF003F,
      $FF7F9F, $A50029, $A55267, $7F001F, $7F3F4F, $4C0013, $4C262F, $260009, $261317, $FF007F,
      $FF7FBF, $A50052, $A5527C, $7F003F, $7F3F5F, $4C0026, $4C2639, $260013, $26131C, $FF00BF,
      $FF7FDF, $A5007C, $A55291, $7F005F, $7F3F6F, $4C0039, $4C2642, $26001C, $261321, $FF00FF,
      $FF7FFF, $A500A5, $A552A5, $7F007F, $7F3F7F, $4C004C, $4C264C, $260026, $261326, $BF00FF,
      $DF7FFF, $7C00A5, $9152A5, $5F007F, $6F3F7F, $39004C, $42264C, $1C0026, $211326, $7F00FF,
      $BF7FFF, $5200A5, $7C52A5, $3F007F, $5F3F7F, $26004C, $39264C, $130026, $1C1326, $3F00FF,
      $9F7FFF, $2900A5, $6752A5, $1F007F, $4F3F7F, $13004C, $2F264C, $090026, $171326, $000000,
      $2D2D2D, $5B5B5B, $898989, $B7B7B7, $B3B3B3);
var R,G,B, R1,G1,B1:Byte; I:Integer; Dist,Tmp:Real;
begin
   Result:=1;
   R:=GetRValue(Color);
   G:=GetGValue(Color);
   B:=GetBValue(Color);
   Dist:=1e30;
   for I:=1 to 255 do begin
      R1:=GetRValue(DXFLayerColors[I]);
      G1:=GetGValue(DXFLayerColors[I]);
      B1:=GetBValue(DXFLayerColors[I]);
      Tmp:=Sqrt((R1-R)*(R1-R)+(G1-G)*(G1-G)+(B1-B)*(B1-B));
      if Tmp<Dist then begin
         Dist:=Tmp;
         Result:=I;
      end;
   end;
end;
{
///###???
function Truncate( Value:Real; Maxlength:integer ): String;
begin Result:=FloatToStrF(Value,ffFixed,10,Maxlength);
      while Result[Length(Result)]='0' do Delete(Result,Length(Result),1);
      if Length(Result)<MaxLength then Result:=Result+'0' else
      if Result[Length(Result)] in ['.',','] then Result:=Result+'0';
end;
}


