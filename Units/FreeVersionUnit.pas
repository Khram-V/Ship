//
//   FreeVersionUnit
//
unit FreeVersionUnit;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

// Unit to keep track of fileversions, bux fixes and release dates

interface
uses SysUtils;
const
 ReleasedDate:string={$I %DATE%};
 COMPILE_TIME:string={$I %TIME%};
 TARGET_CPU:string={$I %FPCTARGETCPU%};
 TARGET_OS:string={$I %FPCTARGETOS%};
 FPCVERSION:string={$I %FPCVERSION%};


type TFreeFileVersion=( fv100,fv110,fv120,fv130,fv140,fv150,fv160,fv165,fv170,
                        fv180,fv190,fv191,fv195,fv198,fv200,fv201,fv210,fv220,
                        fv230,fv240,fv250,fv261,fv270,fv280,fv290,fv295,fv296,
                        fv297,fv298,fv300,fv302,fv303,fv305,fv309,fv310,fv313,
                        fv314,fv317,fv327,fv332,fv335,fv421,
                        {   ControlPointNames, ControlEdgeNames,
                            ControlFaceNames, ControlCurveNames,
                            ControlPointLinearConstraints }
                        fv430, // ControlPointGroups
                        fv462, // Anchors
                        fv500  // UnderWaterColorAlpha
                      );
const CurrentVersion=fv261;    //high( TFreeFileVersion );
                      // Current (latest) version of the FREE!ship project.
                      // All new created models are initialized to this version
var
//FREESHIP_MAJOR_VERSION : string ='5.0';   // Major version
  FREESHIP_VERSION : string = '2.6.1.2';    // Current full version

function VersionString( Version:TFreeFileVersion): String;
function VersionBinary( Version:String ):TFreeFileVersion;

implementation

function VersionString(Version:TFreeFileVersion):String; begin
  Case Version of
    fv100  : Result:='1.0';  fv110  : Result:='1.1';  fv120  : Result:='1.2';
    fv130  : Result:='1.3';  fv140  : Result:='1.4';  fv150  : Result:='1.5';
    fv160  : Result:='1.6';  fv165  : Result:='1.65'; fv170  : Result:='1.7';
    fv180  : Result:='1.8';  fv190  : Result:='1.9';  fv191  : Result:='1.91';
    fv195  : Result:='1.95'; fv198  : Result:='1.98'; fv200  : Result:='2.0';
    fv201  : Result:='2.01'; fv210  : Result:='2.1';  fv220  : Result:='2.2';
    fv230  : Result:='2.3';  fv240  : Result:='2.4';  fv250  : Result:='2.5'
     else    Result:='2.6'; // = fv261
  end
end;
function VersionBinary(Version:String):TFreeFileVersion; begin
  if Version='1.0'   then Result:=fv100 else
  if Version='1.1'   then Result:=fv110 else
  if Version='1.2'   then Result:=fv120 else
  if Version='1.3'   then Result:=fv130 else
  if Version='1.4'   then Result:=fv140 else
  if Version='1.5'   then Result:=fv150 else
  if Version='1.6'   then Result:=fv160 else
  if Version='1.65'  then Result:=fv165 else
  if Version='1.7'   then Result:=fv170 else
  if Version='1.8'   then Result:=fv180 else
  if Version='1.9'   then Result:=fv190 else
  if Version='1.91'  then Result:=fv191 else
  if Version='1.95'  then Result:=fv195 else
  if Version='1.98'  then Result:=fv198 else
  if Version='2.0'   then Result:=fv200 else
  if Version='2.01'  then Result:=fv201 else
  if Version='2.1'   then Result:=fv210 else
  if Version='2.2'   then Result:=fv220 else
  if Version='2.3'   then Result:=fv230 else
  if Version='2.4'   then Result:=fv240 else
  if Version='2.5'   then Result:=fv250 else
  if Version='2.6'   then Result:=fv261 else // !!!
  if Version='2.7+'  then Result:=fv270 else
  if Version='2.8+'  then Result:=fv280 else
  if Version='2.94+' then Result:=fv290 else
  if Version='2.95+' then Result:=fv295 else
  if Version='2.96+' then Result:=fv296 else
  if Version='2.97+' then Result:=fv297 else
  if Version='2.98+' then Result:=fv298 else
  if Version='3.0+'  then Result:=fv300 else
  if Version='3.02+' then Result:=fv302 else
  if Version='3.03+' then Result:=fv303 else
  if Version='3.08+' then Result:=fv305 else
  if Version='3.09+' then Result:=fv309 else
  if Version='3.12+' then Result:=fv310 else
  if Version='3.13+' then Result:=fv313 else
  if Version='3.16+' then Result:=fv314 else
  if Version='3.27+' then Result:=fv317 else
  if Version='3.3+'  then Result:=fv327 else
  if Version='3.34+' then Result:=fv332 else
  if Version='3.4'   then Result:=fv335 else
  if Version='4.2'   then Result:=fv421 else
  if Version='4.3'   then Result:=fv430 else
  if Version='4.6.2' then Result:=fv462 else Result:=fv500; // всего 45 версий
//if Version='5.0'   then Result:=fv500 else Result:=fv261
end;

end.
