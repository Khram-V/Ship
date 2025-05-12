{-------------------------------------------------------------------------}
{                                       TFreeHydrostaticCalc              }
{   TFreeHydrostaticCalc is an object class for hydrostatic calculations. }
{   Each calculation has it's own draft, trim and angle of heel.          }
{   Multiple calculations can be stored and then send to a report.        }
{-------------------------------------------------------------------------}

function TFreeHydrostaticCalc.FGetTrimAngle: TFloatType;
begin
  Result:=RadToDeg(ArcTan((-Trim * Cos(DegToRad(HeelingAngle))) /
    Owner.ProjectSettings.ProjectLength));
end;

function TFreeHydrostaticCalc.FGetWlPlane: T3DPlane;
  var LowestValue: TFloatType; P1,P2,P3: T3DVector;
begin
  LowestValue:=Owner.FindLowestHydrostaticsPoint;
  P1:=Vector( 0.0,0.0,LowestValue+(Draft-0.5*Trim) );
  P2:=Vector(Owner.ProjectSettings.ProjectLength,0.0,LowestValue+(Draft+0.5*Trim));
  P3:=Vector(Owner.ProjectSettings.ProjectLength,Cos(DegToRad(-HeelingAngle)),
                   LowestValue+(Draft+0.5 * Trim)-Sin(DegToRad(-HeelingAngle)));
  Result:=PlanePPP( P1,P2,P3 );
end;

procedure TFreeHydrostaticCalc.FSetCalculated(val: boolean);
begin
  FCalculated:=val;
  if not FCalculated then begin
     Fillchar( FData,SizeOf(FData),0 ); FMidshipSection.Clear;
  end;
end;

procedure TFreeHydrostaticCalc.FSetHeelingAngle(Val: TFloatType);
begin
  if Val<>FHeelingAngle then begin FheelingAngle:=val; Calculated:=False; end;
end;

procedure TFreeHydrostaticCalc.FSetTrim(Val: TFloatType);
begin if Val <> FTrim then begin FTrim:=val; Calculated:=False; end;
end;

procedure TFreeHydrostaticCalc.FSetDraft( Val: TFloatType );
begin if Val <> FDraft then begin FDraft:=val; Calculated:=False; end;
end;

// Add calculated data to a stringlist to either show in a report or save to disc
procedure TFreeHydrostaticCalc.AddData( Strings: TStringList );                 // Mode: TFreeHydrostaticsMode; Separator: char );
const S4='    '; Ls=37;
var
  Str: AnsiString;
  ID, I, N, II, JJ, J: integer;
  Calculation,HydObject: TFreehydrostaticCalc;
  Properties,Total: TLayerProperties;
  Position: TFloatType;
  HeelAngle,vTrimAngle,h0,hl,D1,D2,Swl,dD,X1,X2,Y1,Y2,Z1,Z2,Xd,Yd,Zd,
  k_test,h_min,m_ballast,L_max,Zc,a,Teta,dT,dT_,Tr,Ix,Iy: Single;
  Xs,Ws: array [1..100] of single;
  T,Displ:array [1..10] of single;
  Twl: array [1..101] of single;
  Xaft: array [1..101] of single;
  Xfor: array [1..101] of single;
  ffile,ffile1,ffile2: textfile;
const Line_1='┌─────────────────────────┬─────────┬───────────┬──────────┬─────────┬─────────┬─────────┐';
const Line_2='├─────────────────────────┼─────────┼───────────┼──────────┼─────────┼─────────┼─────────┤';
const Line_3='└─────────────────────────┴─────────┴───────────┴──────────┴─────────┴─────────┴─────────┘';
label
  ExitDo, new;
begin
  m_ballast:=20;  // масса балласта принята 2% от водоизмещения порожнем [кг/т]
  h_min:=0;
//Separator:=#32;
  Calculate;                                                          ///***???
  AddHeader(Strings);
  Strings.Add(UserString(2)+':');
  Strings.Add(S4+Makelength(Userstring(3),Ls)+
  ' :  '+ MakeLength(FData.Volume,-1,12)+' '+VolStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+Makelength(Userstring(4),Ls)+
  ' :  '+MakeLength(FData.Displacement,-1,12)+' '+WeightStr(Owner.ProjectSettings.ProjectUnits));
  if Owner.ProjectSettings.ProjectCoefficients=fcActualData then begin
    Strings.Add(S4+MakeLength(Userstring(5),Ls)+
    ' :  '+MakeLength(FData.SubMax.X-FData.SubMin.X,3,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(6),Ls)+
    ' :  '+MakeLength(FData.SubMax.Y-FData.SubMin.Y,3,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  end;
// Пересчет коэфФициентов полноты, если базовая линия проходит через линию киля
// if abs(FData.ModelMin.Z) > 0.001 then begin
  FData.BlockCoefficient:=FData.BlockCoefficient;// * FData.AbsoluteDraft / (FData.AbsoluteDraft+FData.ModelMin.Z);
  FData.MidshipCoeff := FData.MidshipCoeff;      // * FData.AbsoluteDraft / (FData.AbsoluteDraft+FData.ModelMin.Z);
  if FData.MidshipCoeff > 0 then begin
    FData.PrismCoefficient:=FData.BlockCoefficient/FData.MidshipCoeff;
    FData.VertPrismCoefficient:=FData.BlockCoefficient/FData.WaterplaneCoeff;
  end else begin
    Strings.Add(S4+MakeLength(Userstring(15),Ls) +
    ' :  '+MakeLength(FData.MidshipCoeff,4,12)); //Strings.Add(S4+'ATTENTION!!! Cm<=0');
  end; // end;
  Strings.Add(S4+MakeLength(Userstring(7),Ls)+
  ' :  ' +MakeLength(FData.BlockCoefficient,4,12));
  if FData.MidshipCoeff > 0.01 then
    Strings.Add(S4+MakeLength(Userstring(8),Ls)+' :  '+MakeLength(FData.PrismCoefficient,4,12));
  if FData.WaterplaneCoeff > 0.01 then
    Strings.Add(S4+MakeLength(Userstring(9),Ls)+' :  '+MakeLength(FData.VertPrismCoefficient,4,12));
  Strings.Add(S4+MakeLength(Userstring(10), Ls)+' :  '+MakeLength(FData.WettedSurface,-1,12)+' '+Areastr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(11), Ls)+' :  '+MakeLength(FData.CenterOfBuoyancy.X,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits)
                                               +'  = '+MakeLength(FData.LCBPerc,3,6)+' %');
  Strings.Add(S4+MakeLength(Userstring(880),Ls)+' :  '+MakeLength(FData.CenterOfBuoyancy.Y,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(12), Ls)+' :  '+MakeLength(FData.CenterOfBuoyancy.Z+FData.ModelMin.Z,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  if FData.MidshipCoeff>0.01 then begin Strings.Add(Userstring(13)+':'); // мидельшпангоут
    Strings.Add(S4+MakeLength(Userstring(49),Ls)+
    ' :  '+MakeLength(FMidshipLocation,4,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(14),Ls)+    // Площадь мидельшпангоута
    ' :  '+MakeLength(FData.MidshipArea,-1,12)+' '+Areastr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(15),Ls)+
    ' :  '+MakeLength(FData.MidshipCoeff,4,12));
  end;
  Strings.Add(Userstring(16)+':');               // харакетристики ватерлинии
  Strings.Add(S4+MakeLength(Userstring(17),Ls)+
  ' :  '+MakeLength(FData.LengthWaterline,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(18),Ls)+
  ' :  '+MakeLength(FData.BeamWaterline, -1, 12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  if FData.WaterplaneMomInertia.X > 0.0001 then begin
    Strings.Add(S4+MakeLength(Userstring(19),Ls)+
    ' :  '+MakeLength(FData.WaterplaneArea,-1,12)+' '+Areastr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(20),Ls)+
    ' :  '+MakeLength(FData.WaterplaneCoeff,4,12));
    Strings.Add(S4+MakeLength(Userstring(21),Ls)+
    ' :  '+MakeLength(FData.WaterplaneCOG.X,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(881),Ls) +
    ' :  '+MakeLength(FData.WaterplaneCOG.Y,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  end else                        //  Расчет Площади КВЛ альтернативным методом
  if (FData.WaterplaneCoeff>1) or (FData.WaterplaneCoeff<0.1) then begin
    HydObject:=TFreeHydrostaticCalc.Create(Owner);
    HydObject.Draft:=Owner.ProjectSettings.ProjectDraft-0.001;
    HydObject.Calculate;
    D1:=HydObject.Data.Volume;
    X1:=HydObject.Data.CenterOfBuoyancy.X;
    Y1:=HydObject.Data.CenterOfBuoyancy.Y;
    Z1:=HydObject.Data.CenterOfBuoyancy.Z;
    HydObject.Draft:=Owner.ProjectSettings.ProjectDraft+0.001;
    HydObject.Calculate;
    D2:=HydObject.Data.Volume;
    X2:=HydObject.Data.CenterOfBuoyancy.X;
    Y2:=HydObject.Data.CenterOfBuoyancy.Y;
    Z2:=HydObject.Data.CenterOfBuoyancy.Z;
    Swl:=(D2-D1) * 500;
    FData.WaterplaneArea:=Swl;
    FData.WaterplaneCoeff:=Swl / FData.LengthWaterline / FData.BeamWaterline;
    Strings.Add(S4+MakeLength(UserString(19),Ls) +
    ' :  '+Makelength(Swl,-1,12)+' '+Areastr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(20),Ls) +
    ' :  '+Makelength(FData.WaterplaneCoeff, -1, 12));
    FreeAndNil(HydObject);
    Xd:=(X2 * D2-X1 * D1) / (D2-D1);
    Strings.Add(S4+MakeLength(Userstring(21),Ls) +
    ' :  '+Makelength(Xd,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Yd:=(Y2 * D2-Y1 * D1) / (D2-D1);
    Strings.Add(S4+MakeLength(Userstring(881),Ls)+
    ' :  '+Makelength(Yd, -1, 12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Zd:=(Z2*D2-Z1*D1)/(D2-D1);
    // Strings.Add(S4+MakeLength('VCF',43)+' :  '+Makelength(Zd,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    FData.WaterplaneCOG.X:=Xd;
    FData.WaterplaneCOG.Y:=Yd;
    FData.WaterplaneCOG.Z:=Zd+FData.ModelMin.Z;
  end;

  Strings.Add(S4+MakeLength(Userstring(22),Ls)+
  ' :  '+MakeLength(FData.WaterplaneEntranceAngle,-1,12)+' °' ); //DegrStr(Owner.ProjectSettings.ProjectUnits));
  if FData.WaterplaneMomInertia.X < 0.01 then
  if FData.BeamWaterline>2*Owner.ProjectSettings.ProjectBeam then begin // Strings.Add('As for catamaran :');
    FData.WaterplaneMomInertia.X:=FData.WaterplaneArea*sqr((FData.BeamWaterline-Owner.ProjectSettings.ProjectBeam)/2.0);
    FData.WaterplaneMomInertia.Y:=sqr(FData.WaterplaneArea)/Owner.ProjectSettings.ProjectBeam * FData.LengthWaterline / 16;
    FData.KMtransverse:=FData.WaterplaneMomInertia.X/FData.Volume+FData.CenterOfBuoyancy.Z;
    FData.KMlongitudinal:=FData.WaterplaneMomInertia.Y/FData.Volume+FData.CenterOfBuoyancy.Z;
  end else begin
    //           Strings.Add('Theoretical formula for monohull ships:');
    a:=FData.WaterplaneCoeff;
    FData.WaterplaneMomInertia.X :=((0.0613486*a+0.0298348)*a-0.0076467)
                * power(FData.BeamWaterline, 3) * FData.LengthWaterline;
    FData.WaterplaneMomInertia.Y :=((0.0811652*a+0.0021749)*a-0.0060582)
                * power(FData.LengthWaterline, 3) * FData.BeamWaterline;
    // FData.WaterplaneMomInertia.X:=sqr(FData.WaterplaneCoeff)*FData.LengthWaterline*power(Owner.ProjectSettings.ProjectBeam,3)/18;
    // FData.WaterplaneMomInertia.Y:=sqr(FData.WaterplaneCoeff)*Owner.ProjectSettings.ProjectBeam*power(FData.LengthWaterline,3)/16;
    FData.KMtransverse:=FData.WaterplaneMomInertia.X/FData.Volume+FData.CenterOfBuoyancy.Z;
    FData.KMlongitudinal:=FData.WaterplaneMomInertia.Y/FData.Volume+FData.CenterOfBuoyancy.Z;
  end;
  Strings.Add(S4+MakeLength(Userstring(23),Ls)+
  ' :  '+MakeLength(FData.WaterplaneMomInertia.X,-1,12)+' '+InertiaStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(24),Ls)+
  ' :  '+MakeLength(abs(FData.WaterplaneMomInertia.Y),-1,12)+' '+InertiaStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(Userstring(25)+':');
  Strings.Add(S4+MakeLength(Userstring(26),Ls)+
  ' :  '+MakeLength(FData.KMtransverse+FData.ModelMin.Z,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(882),Ls)+
  ' :  '+MakeLength(FData.KMtransverse-FData.CenterOfBuoyancy.Z,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(27),Ls)+
  ' :  '+MakeLength(FData.KMlongitudinal+FData.ModelMin.Z,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(883),Ls)+
  ' :  '+MakeLength(FData.KMlongitudinal-FData.CenterOfBuoyancy.Z,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  if FData.LateralArea > 0 then begin
    Strings.Add(Userstring(28)+':');
    Strings.Add(S4+MakeLength(Userstring(29),Ls)+
    ' :  '+MakeLength(FData.LateralArea, -1, 12)+' '+Areastr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(30),Ls)+
    ' :  '+MakeLength(FData.LateralCOG.X,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(31),Ls)+
    ' :  '+MakeLength(FData.LateralCOG.Z+FData.ModelMin.Z,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  end;
  if FData.SDP > 0 then begin
    Strings.Add(Userstring(1137)+':');
    Strings.Add(S4+MakeLength(Userstring(1134),Ls) +
    ' :  '+MakeLength(FData.SDP,-1,12)+' '+Areastr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(1434),Ls) +
    ' :  '+MakeLength(FData.sdpCOG.Z+FData.ModelMin.Z,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(1435),Ls) +
    ' :  '+MakeLength(FData.sdpCOG.X,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(1135),Ls) +
    ' :  '+MakeLength(FData.Zsdp,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(1136),Ls) +
    ' :  '+MakeLength(FData.Xsdp+FData.ModelMin.Z,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    if FData.Z_Min_board < 10000 then begin
      L_max:=FData.ModelMax.X-FData.ModelMin.X;
      h_min:=FData.Z_min_board-Owner.ProjectSettings.Projectdraft-FData.ModelMin.Z;
      Strings.Add(S4+MakeLength(Userstring(1443),Ls) +
      ' :  '+MakeLength(h_min, -1, 12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
      Strings.Add(S4+MakeLength(Userstring(1443),Ls) +
      ' :  '+MakeLength(h_min / L_max * 100, -1, 12)+' %Lmax');
      Strings.Add(Userstring(1442)+':');
      k_test:=(FData.BeamWaterline+h_min * 2) / FData.LengthWaterline +
      Owner.ProjectSettings.Projectdraft * m_ballast / 2;
      Strings.Add(S4+MakeLength(Userstring(1444),Ls)+
      ' :  '+MakeLength(k_test, -1, 12)+' if >= 0,8 then OK');
    end;
  end;
  Strings.Add('');
  N:=0;
  for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].Count>0 then Inc(N);
  if N>0 then
  if Owner.NumberofWaterlines>0 then begin
    for i:=1 to 2 do Strings.Add('');
    Fillchar(Total, SizeOf(Total), 0);
    Strings.Add(Userstring(32)+':');
    Strings.Add( Line_1 );
    Strings.Add('│          '+Makelength(UserString(33),14) +
               ' │ '+Makelength(UserString(34),7)+
               ' │ '+Makelength(UserString(35),9)+
               ' │ '+Makelength(UserString(36),8)+
               ' │  CoG X  │  CoG Y  │  CoG Z  │' );
    Strings.Add('│ '+MakeLength('', 23)+
               ' │  '+Makelength(AreaStr(Owner.ProjectSettings.ProjectUnits),6) +
               ' │    '+Makelength(LenMMStr(Owner.ProjectSettings.ProjectUnits),6)+
               ' │   '+Makelength(WeightStr(Owner.ProjectSettings.ProjectUnits),6)+
               ' │   '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),5)+
               ' │   '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),5)+
               ' │   '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),5)+' │');
    Strings.Add( Line_2 );
    for I:=1 to Owner.NumberOfLayers do
    if Owner.Layer[I-1].Count > 0 then begin
      Str:=Owner.Layer[I-1].Name;
(*    if Owner.ProjectSettings.EnableBonjeanSAC then begin
      if FileExistsUTF8('Weights.txt') { *Converted from FileExists* } then
      begin  Assignfile(FFile1, 'Weights.txt'); Append(FFile1); end
        else begin Assignfile(FFile1, 'Weights.txt'); Rewrite(FFile1); end;
        writeln(ffile1, '! '+str);
        closefile(ffile1);
      end;
*)
      Properties:=Owner.Layer[I-1].SurfaceProperties;
      Properties.SurfaceCenterOfGravity.Z :=
      Properties.SurfaceCenterOfGravity.Z-FData.ModelMin.Z;
      if Owner.ProjectSettings.ProjectUnits = fuImperial
         then Properties.Weight:=Properties.Weight / (12 * 2240)
         else Properties.Weight:=Properties.Weight / 1000;
      Strings.Add(
               '│ '+MakeLength( Str,23 ) +
              ' │ '+Makelength(Properties.SurfaceArea, -1, 7) +
              ' │ '+MakeLength(Owner.Layer[I-1].Thickness, 3, 9) +
              ' │ '+Makelength(Properties.Weight, 3, 8)+
              ' │ '+MakeLength(Properties.SurfaceCenterOfGravity.X, 3, 7)+
              ' │ '+MakeLength(Properties.SurfaceCenterOfGravity.Y,3, 7)+
              ' │ '+MakeLength(Properties.SurfaceCenterOfGravity.Z+FData.ModelMin.Z,3,7)+
              ' │');
      Total.SurfaceArea:=Total.SurfaceArea+Properties.SurfaceArea;
      Total.Weight:=Total.Weight+Properties.Weight;
      Total.SurfaceCenterOfGravity.X:=Total.SurfaceCenterOfGravity.X+Properties.Weight*Properties.SurfaceCenterOfGravity.X;
      Total.SurfaceCenterOfGravity.Y:=Total.SurfaceCenterOfGravity.Y+Properties.Weight*Properties.SurfaceCenterOfGravity.Y;
      Total.SurfaceCenterOfGravity.Z:=Total.SurfaceCenterOfGravity.Z+Properties.Weight*Properties.SurfaceCenterOfGravity.Z;
    end;
    Strings.Add( Line_3 );
    if Total.Weight <> 0 then begin
      Total.SurfaceCenterOfGravity.X := Total.SurfaceCenterOfGravity.X / Total.Weight;
      Total.SurfaceCenterOfGravity.Y := Total.SurfaceCenterOfGravity.Y / Total.Weight;
      Total.SurfaceCenterOfGravity.Z := Total.SurfaceCenterOfGravity.Z / Total.Weight+FData.ModelMin.Z;
    end;
    if N > 1 then begin // if more then 1 layer is added, then show the properties of all layers together
      Strings.Add('  '+MakeLength(UserString(37),24)+'   '+Makelength(Total.SurfaceArea,-1,6)+
      MakeLength('',15)+Makelength(Total.Weight, 3, 8)+'   ' +
      MakeLength(Total.SurfaceCenterOfGravity.X, 3, 7)+'   ' +
      MakeLength(Total.SurfaceCenterOfGravity.Y, 3, 7)+'   ' +
      MakeLength(Total.SurfaceCenterOfGravity.Z, 3, 7));
    end;
  end;
//    Расчет средней осадки и углов крена и дифферента
// if (FData.Displacement<0.01) or (FData.WaterplaneArea<0.01) then begin
//     ShowMessage('Project Draft or Weight are very large/small!!!');
//     exit;
// end;
// dDispl:=Total.Weight / FData.Displacement-1.;
  dT:=0;
  if Total.Weight > 0.01 then begin
    dT:=(Total.Weight-FData.Displacement)/FData.WaterplaneArea/Owner.ProjectSettings.ProjectWaterDensity;
    if abs(dT) > 0.001 then begin
      Strings.Add('  ');
      Strings.Add(S4+MakeLength(UserString(1021),44) +
      ' : '+Makelength(dT,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
      Strings.Add(S4+MakeLength(UserString(1022),44) +
      ' : '+Makelength(Draft+dT+FData.ModelMin.Z,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
      if abs(FData.ModelMin.Z) > 0.01 then
      Strings.Add(S4+MakeLength(UserString(258),44) +
      ' : '+Makelength(Draft+dT,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
      Strings.Add('  ');
      if Owner.ProjectSettings.EnableModelAutoMove
         then Strings.Add(S4+UserString(1451))
         else Strings.Add(S4+UserString(1452));
    end;
  end;
  Strings.Add('  ');
  Strings.Add(UserString(1020));
  Strings.Add(S4+MakeLength(UserString(1021),44) +
  ' : '+Makelength(dT,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(UserString(1022),44) +
  ' : '+Makelength(Draft+dT+FData.ModelMin.Z,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  if abs(FData.ModelMin.Z)>0.01 then
  Strings.Add(S4+MakeLength(UserString(258),44)+
  ' : '+Makelength(Draft+dT,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  h0:=FData.KMtransverse-Total.SurfaceCenterOfGravity.Z;
  hl:=FData.KMlongitudinal-Total.SurfaceCenterOfGravity.Z;
  HeelAngle:=(Total.SurfaceCenterOfGravity.Y-FData.CenterOfBuoyancy.Y)/h0*Radian;
  vTrimAngle:=-(Total.SurfaceCenterOfGravity.X-FData.CenterOfBuoyancy.X)/hl*Radian;
  if FData.CenterOfBuoyancy.Y<0.01 then begin
    Strings.Add(S4+MakeLength(UserString(1030),44)+
    ' : '+Makelength(h0+FData.ModelMin.Z,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(UserString(1031),44)+
    ' : '+Makelength(hl+FData.ModelMin.Z,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Owner.ProjectSettings.FTrim:=Draft;
  end else begin
    Strings.Add(S4+MakeLength(UserString(1449),44)+
    ' : '+Makelength(h0,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(UserString(1450),44)+
    ' : '+Makelength(hl,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  end;
  Strings.Add(S4+MakeLength(UserString(1023),44)+' : '+Makelength(HeelAngle,-1,8)+' °');
  Strings.Add(S4+MakeLength(UserString(1024),44)+' : '+Makelength(vTrimAngle,-1,8)+' °');

//   Расчет параметров остойчивости в накрененном положении

  if abs(FData.CenterOfBuoyancy.Y) > 0.01 then begin
    Strings.Add(S4);
    Strings.Add(S4+MakeLength(UserString(1453),44) +
    ' : '+MakeLength(FData.CenterOfBuoyancy.Y,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(UserString(1454),44) +
    ' : '+MakeLength(FData.CenterOfBuoyancy.Y-Total.SurfaceCenterOfGravity.Y,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(UserString(1455),44) +
    ' : '+MakeLength(FData.CenterOfBuoyancy.X,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(UserString(1456),44) +
    ' : '+MakeLength(FData.CenterOfBuoyancy.X-Total.SurfaceCenterOfGravity.X,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(UserString(1581),44) +
    ' : '+MakeLength((FData.CenterOfBuoyancy.X-Total.SurfaceCenterOfGravity.X) * 9.807 * FData.Displacement,-1,8)+' '+UserString(1133));
    if hl > 0 then
    Strings.Add(S4+MakeLength(UserString(1582),44)+' : '+MakeLength((FData.CenterOfBuoyancy.X-Total.SurfaceCenterOfGravity.X)*Radian/hl,-1,8)+' °' );
  end;
  Strings.Add(S4);

      // Расчет координат штевней для СПШ и масштаба Бонжана

(*    if (Owner.NumberofWaterlines > 0) and (Owner.NumberofWaterlines < 100) and
        (Owner.NumberofStations < 100) and Owner.ProjectSettings.EnableBonjeanSAC then
      begin
        Assignfile(FFile, 'Sterns.txt');
         {$I-}
        Rewrite(FFile);
{$I+}
        Writeln(FFile, Owner.NumberofWaterlines: 3, Owner.NumberofStations: 3);
        Writeln(FFile, ' ');
        HydObject:=TFreeHydrostaticCalc.Create(Owner);
        for I:=0 to Owner.NumberofWaterlines-1 do
        begin
          FData.WaterlinePlane.D:=Owner.Waterline[I].FPlane.d;
          Twl[I+1]:=-FData.WaterlinePlane.D;
          HydObject.Draft:=Twl[I+1];
          HydObject.Calculate;
          Xaft[I+1]:=HydObject.Data.WlMin.X;
          Xfor[I+1]:=HydObject.Data.WlMax.X;
          Writeln(FFile, -FData.WaterlinePlane.D: 9: 3, HydObject.Data.WlMin.X: 9: 3,
            HydObject.Data.WlMax.X: 9: 3);
        end;
        FreeAndNil(HydObject);
        Writeln(FFile, ' ');
        Writeln(FFile, 'EOF ');
        CloseFile(FFile);
      end;
*)
      // Расчет грузового размера, если включено автоперемещение

  if (Owner.ProjectSettings.EnableModelAutoMove) and (abs(dT)>0.0005) then begin
  //    Strings.Add(S4+MakeLength('Старая осадка',44)+' : '+Makelength(Draft,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Owner.ProjectSettings.ProjectDraft:=Draft+dT;
    HydObject:=TFreeHydrostaticCalc.Create(Owner);
    T[1]:=FData.ModelMin.Z;
    Displ[1]:=0;
    T[10]:=FData.ModelMax.Z;
    if (h_min <= 0) then h_min:=T[10]-Draft;
    dT:=(Draft+h_min)/9;
new:
    for id:=2 to 10 do begin
      Displ[id]:=0;
      HydObject.Draft:=(id-1) * dT-0.001;
      T[id]:=HydObject.Draft;
      if HydObject.Draft >= Owner.Surface.Max.Z then goto ExitDo;
      // if (HydObject.Draft>=h_min+Draft) and (h_min>0) then goto ExitDo;
      if HydObject.Draft >= h_min+Draft then goto ExitDo;
      HydObject.Calculate;
      HydObject.CalculateGravity;
      Displ[id]:=HydObject.Data.Displacement;
{     Strings.Add(S4+MakeLength('T,Xaft,Xfor=',10)+' : '+Makelength(T[id],-1,8)+Makelength(HydObject.Data.WlMin.x,-1,8)+Makelength(HydObject.Data.WlMax.x,-1,8));
      Strings.Add(S4+MakeLength('D0',44)+' : '+Makelength(HydObject.Data.Weight_,-1,8));
      Strings.Add(S4+MakeLength('Rho*g*V',44)+' : '+Makelength(HydObject.Data.Displacement,-1,8));
      Strings.Add(S4+MakeLength('S',44)+' : '+Makelength(HydObject.Data.WaterplaneArea,-1,8));
      Strings.Add(S4+MakeLength('Новая осадка',44)+' : '+Makelength(HydObject.Draft,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
      Strings.Add(' ');
}   end;
ExitDo:               // Рассчитываем новую осадку по грузовому размеру
    id:=id-1;
    // Strings.Add(S4+MakeLength('Id=',44)+' : '+Makelength(id,-1,8));
    Interpolation( HydObject.Data.Weight_,id,Displ,T,Tr );
    //SFINEX1( id,Displ,T,HydObject.Data.Weight_,Tr );
    // Strings.Add(S4+MakeLength('T raschet=',44)+' : '+Makelength(Tr,-1,8));
    Owner.ProjectSettings.ProjectDraft:=Tr;        // Уточняем новую осадку
    // Strings.Add(S4+MakeLength('Максимальная осадка',44)+' : '+Makelength(h_min+Draft,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    // Strings.Add(S4+MakeLength('Новая осадка',44)+' : '+Makelength(Tr,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    HydObject.Draft:=Tr;
    HydObject.Calculate;
    HydObject.CalculateGravity;
    // dT_:=(HydObject.Data.Weight_-HydObject.Data.Displacement)/HydObject.Data.WaterplaneArea/Owner.ProjectSettings.ProjectWaterDensity;
    if HydObject.Data.WaterplaneArea > 0.1
    then dT_:=(HydObject.Data.Weight_-HydObject.Data.Displacement)/HydObject.Data.WaterplaneArea/Owner.ProjectSettings.ProjectWaterDensity
    else dT_:=(HydObject.Data.Weight_-HydObject.Data.Displacement)/Owner.ProjectSettings.ProjectLength/Owner.ProjectSettings.ProjectBeam/Owner.ProjectSettings.ProjectWaterDensity;
    Owner.ProjectSettings.ProjectDraft:=Tr+dT_;
    if abs( Tr/(Tr+dT_)-1)>0.1 then begin dT:=Tr/9; goto new; end;
    if Owner.ProjectSettings.ProjectDraft > 1.1 * Tr then
       Owner.ProjectSettings.ProjectDraft:=Draft+dT+FData.ModelMin.Z;
{   Strings.Add(S4+MakeLength('D1',44)+' : '+Makelength(HydObject.Data.Weight_,-1,8));
    Strings.Add(S4+MakeLength('Rho*g*V',44)+' : '+Makelength(HydObject.Data.Displacement,-1,8));
    Strings.Add(S4+MakeLength('S',44)+' : '+Makelength(HydObject.Data.WaterplaneArea,-1,8));
    Strings.Add(S4+MakeLength('dT',44)+' : '+Makelength(dT_,-1,8));
    Strings.Add(S4+MakeLength('Старая осадка',44)+' : '+Makelength(Draft,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength('Новая осадка',44)+' : '+Makelength(Owner.ProjectSettings.ProjectDraft,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(' ');
}
    FreeAndNil(HydObject);
  end;
  //  Strings.Add(S4+MakeLength('Максимум возможной осадки',44)+' : '+Makelength(Owner.Surface.Max.Z,-1,8)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  // Add sectional Area data
  N:=Length(FData.SAC); // ************************************************
  //if N > 100 then ShowMessage('N='+FloatToStrF(N,ffFixed,6,0)+' - '+UserString(1484) );
  if N > 0 then begin
    Strings.Add('');
    Strings.Add(UserString(38)+':');
    Strings.Add('');
    Strings.Add(' ┌───────────┬──────────┐');
    Strings.Add(' │ '+MakeLength(Userstring(57),9)+' │ '+ MakeLength(Userstring(34),8)+' │');
    Strings.Add(' │    '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),6)+' │   '+MakeLength(AreaStr(Owner.ProjectSettings.ProjectUnits),6)+' │');
    Strings.Add(' ├───────────┼──────────┤'); JJ:=1;
    Strings.Add(' │ '+Makelength(FData.SubMin.X,3,9)+' │ '+Makelength(Fdata.Sac[0].Y,3,8)+' │ ');
    Xs[JJ]:=FData.SubMin.X;
    Ws[JJ]:=FData.Sac[0].Y;
    JJ:=2;
    II:=1;
    if (FData.SubMin.X < 0) or (FData.SubMin.X > Fdata.Sac[0].X) then II:=2;
    for I:=II to N-1 do begin
      Position:=FData.Sac[I-1].X;
      Strings.Add(' │ '+Makelength(Position,3,9)+' │ '+Makelength(Fdata.Sac[I-1].Y,3,8)+' │ ');
      Xs[JJ]:=Position;
      Ws[JJ]:=FData.Sac[I-1].Y;
      JJ:=JJ+1;
    end;
    Strings.Add(' │ '+Makelength(FData.SubMax.X,3,9)+' │ '+Makelength(0.,3,8)+' │ ');
    Xs[JJ]:=FData.SubMax.X;
    Ws[JJ]:=0.;
    Strings.Add(' └───────────┴──────────┘');
  end;
  if (FData.ModelMin.Z<>0.0)
  and Owner.ProjectSettings.EnableModelAutoMove then Face_MoveZAuto;
  AddFooter( Strings );
end;

procedure TFreeHydrostaticCalc.AddHeader( Strings: TStringList ); const ls=28;
begin                                                             // Проект
  Strings.Add(MakeLength(Userstring(39),10)+': '+Owner.ProjectSettings.ProjectName);
  Strings.Add(MakeLength(Userstring(40),10)+': '+Owner.ProjectSettings.ProjectDesigner);
  if Owner.ProjectSettings.ProjectFileCreatedBy<>'' then
     Strings.Add(MakeLength(Userstring(41),10)+': '+Owner.ProjectSettings.ProjectFileCreatedBy);
  if Owner.ProjectSettings.ProjectComment<>''then
     Strings.Add(MakeLength(Userstring(42),10)+': '+Owner.ProjectSettings.ProjectComment );
  Strings.Add(MakeLength(Userstring(43),10)+': '+ExtractFilename(Owner.FileName));
  Strings.Add( '' );
  Strings.Add(MakeLength(Userstring(44),ls)+
  ' : '+MakeLength(Owner.ProjectSettings.ProjectLength,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(MakeLength(Userstring(45),ls)+
  ' : '+MakeLength(FData.ModelMax.X-FData.ModelMin.X,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(MakeLength(Userstring(46),ls)+
  ' : '+MakeLength(Owner.ProjectSettings.ProjectBeam,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(MakeLength(Userstring(47),ls)+
  ' : '+MakeLength( 2*FData.ModelMax.Y,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(MakeLength(Userstring(48),ls)+
  ' : '+MakeLength(Owner.ProjectSettings.Projectdraft+FData.ModelMin.Z,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(MakeLength(Userstring(258),ls)+
  ' : '+MakeLength(Owner.ProjectSettings.Projectdraft,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(MakeLength(Userstring(49),ls)+
  ' : '+MakeLength(Owner.ProjectSettings.ProjectSplitSectionLocation,-1,10)+#32+{FMidshipLocation,-1,10)+#32+}LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(MakeLength(Userstring(50),ls)+
  ' : '+MakeLength(Owner.ProjectSettings.ProjectWaterDensity,3,10)+#32+DensityStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(MakeLength(Userstring(51),ls)+
  ' : '+MakeLength(Owner.ProjectSettings.ProjectAppendageCoefficient,4,10));
end;

procedure TFreeHydrostaticCalc.Face_MoveZAuto;
var
  I,J,Nlocked: integer;
  Points: TFasterListTFreeSubdivisionControlPoint;
  PrevCursor: TCursor;
  Point: TFreeSubdivisionControlPoint;
  Proceed: boolean;
  P, Translate: T3DVector;
  Marker: TFreeMarker;
begin
  for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].SurfaceVisible then
    for J:=1 to Owner.Layer[I-1].Count do Owner.Layer[I-1].Items[J-1].Selected:=True;
  for I:=1 to Owner.Surface.NumberOfControlPoints do if Owner.Surface.ControlPoint[I-1].Visible then
              Owner.Surface.ControlPoint[I-1].Selected:=True;
  for I:=1 to Owner.NumberofMarkers do if Owner.Marker[I-1].Visible then
              Owner.Marker[I-1].Selected:=True;
  Owner.Redraw;

  Points:=TFasterListTFreeSubdivisionControlPoint.Create;
  if Owner.ActiveControlPoint <> nil then
    Points.Add(Owner.ActiveControlPoint);
  Owner.Surface.ExtractPointsFromSelection(Points, NLocked);
  Translate.X:=0.0;
  Translate.Y:=0.0;
  Translate.Z:=-FData.ModelMin.Z;
  PrevCursor:=Screen.Cursor;
  Screen.Cursor:=crHourGlass;
  for I:=1 to Points.Count do begin
    Point:=TFreeSubdivisionControlPoint(Points[I-1]);
    if not Point.Locked then begin
      P:=Point.Coordinate;
      P.Z:=P.Z+Translate.Z;
      Point.Coordinate:=P;
    end;
  end;
  if Points.Count = Owner.Surface.NumberOfControlPoints then begin
    for I:=1 to Owner.NumberofWaterlines do
      Owner.Waterline[I-1].FPlane.d:=Owner.Waterline[I-1].FPlane.d-Translate.Z; // Update markers
    for I:=1 to Owner.NumberofMarkers do begin
      Marker:=Owner.Marker[I-1];
      for J:=1 to Marker.NumberOfPoints do begin
        P:=Marker.Point[J-1];
        P.Z:=P.Z+Translate.Z;
        Marker.Point[J-1]:=P;
      end;
    end;
  end;
  Owner.Built:=False;
  Owner.Redraw;                                  // Refresh controlpoint data
  if Points.IndexOf(Owner.ActiveControlPoint) <> -1 then
    Owner.ActiveControlPoint:=Owner.ActiveControlPoint;
  Screen.Cursor:=PrevCursor;
  for I:=1 to Owner.Surface.NumberOfControlPoints do
    if Owner.Surface.ControlPoint[I-1].Visible then
      Owner.Surface.ControlPoint[I-1].Selected:=False;
  for I:=1 to Owner.NumberofMarkers do
    if Owner.Marker[I-1].Visible then
      Owner.Marker[I-1].Selected:=False;
  Owner.Surface.Clearselection;
  //  Owner.ActiveControlPoint:=nil;
  //  Owner.FSelectedFlowlines.Clear;
  Owner.FSelectedMarkers.Clear;
  FreeAndNil(Points);
end;

procedure TFreeHydrostaticCalc.AddFooter( Strings: TStringList ); // Mode: TFreeHydrostaticsMode );
begin
  Strings.Add(Userstring(52));
  if FOwner.ProjectSettings.ProjectCoefficients=fcActualData
     then Strings.Add(Userstring(53))
     else Strings.Add(Userstring(54));               // Проверка наличия бульба
end;

///////////// Calculate Gravity Weight and CoG
procedure TFreeHydrostaticCalc.CalculateGravity;
var I,N: integer; Properties,Total: TLayerProperties;
begin
  if not Owner.Built then exit;
  N:=0;
  Total.Weight:=0;
  Total.SurfaceCenterOfGravity.X:=0.0;
  Total.SurfaceCenterOfGravity.Y:=0.0;
  Total.SurfaceCenterOfGravity.Z:=0.0;
  for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].Count>0 then Inc(N);
  if N > 0 then
  for I:=1 to Owner.NumberOfLayers do
  if Owner.Layer[I-1].Count>0 then begin
    Properties:=Owner.Layer[I-1].SurfaceProperties;
    Properties.SurfaceCenterOfGravity.Z:=Properties.SurfaceCenterOfGravity.Z-FData.ModelMin.Z;
    if Owner.ProjectSettings.ProjectUnits=fuImperial
        then Properties.Weight:=Properties.Weight / (12 * 2240)
        else Properties.Weight:=Properties.Weight / 1000;
    Total.SurfaceArea:=Total.SurfaceArea+Properties.SurfaceArea;
    Total.Weight:=Total.Weight+Properties.Weight;
    Total.SurfaceCenterOfGravity.X:=Total.SurfaceCenterOfGravity.X+Properties.Weight*Properties.SurfaceCenterOfGravity.X;
    Total.SurfaceCenterOfGravity.Y:=Total.SurfaceCenterOfGravity.Y+Properties.Weight*Properties.SurfaceCenterOfGravity.Y;
    Total.SurfaceCenterOfGravity.Z:=Total.SurfaceCenterOfGravity.Z+Properties.Weight*Properties.SurfaceCenterOfGravity.Z;
  end;
  if N>=1 then
  if Total.Weight<>0 then begin
    Total.SurfaceCenterOfGravity.X:=Total.SurfaceCenterOfGravity.X/Total.Weight;
    Total.SurfaceCenterOfGravity.Y:=Total.SurfaceCenterOfGravity.Y/Total.Weight;
    Total.SurfaceCenterOfGravity.Z:=Total.SurfaceCenterOfGravity.Z/Total.Weight;
  end; // if more then 1 layer is added, then show the properties of all layers together
  ////  Weight
  FData.Weight_:=Total.Weight;
  FData.CenterOfGravity_.X:=Total.SurfaceCenterOfGravity.X;
  FData.CenterOfGravity_.Y:=Total.SurfaceCenterOfGravity.Y;
  FData.CenterOfGravity_.Z:=Total.SurfaceCenterOfGravity.Z;
end;

procedure TFreeHydrostaticCalc.CalculateMidshipLocation;
var i:integer; Frame: TFreeIntersection;
  X,X1,X2, Step, MaxArea, Area :TFloatType;
  MOI: T2DCoordinate;
  COG: T3DVector;
  MaxStation: integer;
begin
  MaxStation:=0;
  FMidshipLocation:=0.5 * FData.ModelMax.X;

  Frame:=TFreeIntersection.Create(Owner);
  Frame.FUseHydrostaticsSurfacesOnly:=True;
  Frame.FIntersectionType:=fiStation;
  MaxArea:=0.0;
  for I:=0 to Owner.NumberofStations-1 do begin
    Frame.Plane:=Owner.Station[I].Plane;
    X:=-Frame.Plane.d;
    Frame.Built:=false;
    Frame.CalculateArea(FData.WaterlinePlane, Area, COG, MOI);
    if MaxArea < Area then begin
      FMidshipLocation:=X;
      MaxArea:=Area;
      MaxStation:=i;
    end;
  end;                        // find precise location up to 0.1 of length unit
  Step:=0.1;                  // search between MaxStation-1 and MaxStation
  if MaxStation > 0 then begin
    X1:=- Owner.Station[MaxStation-1].Plane.d;
    X2:=- Owner.Station[MaxStation].Plane.d;
    Frame.FPlane.a:=1.0;
    Frame.FPlane.b:=0.0;
    Frame.FPlane.c:=0.0;
    X:=X1;
    while X < X2 do begin
      Frame.FPlane.d:=-X;
      Frame.Built:=false;
      Frame.CalculateArea(FData.WaterlinePlane, Area, COG, MOI);
      if MaxArea < Area then begin
        FMidshipLocation:=X;
        MaxArea:=Area;
      end;
      X:=X+Step;
    end;
  end;                            // search between MaxStation and MaxStation+1
  if MaxStation < Owner.NumberofStations-1 then begin
    X1:=- Owner.Station[MaxStation].Plane.d;
    X2:=- Owner.Station[MaxStation+1].Plane.d;
    Frame.FPlane.a:=1.0;
    Frame.FPlane.b:=0.0;
    Frame.FPlane.c:=0.0;
    X:=X1;
    while X < X2 do begin
      Frame.FPlane.d:=-X;
      Frame.Built:=false;
      Frame.CalculateArea(FData.WaterlinePlane, Area, COG, MOI);
      if MaxArea < Area then begin
        FMidshipLocation:=X;
        MaxArea:=Area;
      end; X:=X+Step;
    end;
  end; FreeAndNil(Frame);
end;

    // The actual calculation of the hydrostatics finds place in this procedure
procedure TFreeHydrostaticCalc.Calculate;
var
  I,J,K,L,M,N, First,Last: integer;
  CosHeel,SinHeel,CosTrim,SinTrim, Parameter: TFloatType;
  Layer: TFREESubdivisionLayer;
  Face: TFreeSubdivisionControlFace;
  Child: TFreeSubdivisionFace;
  Side1,Side2, SubmergedLength,SubmergedWidth: TFloatType;
  Leaks: TFasterListTFreeSubdivisionControlPoint;
  CtrlPoint: TFreeSubdivisionControlPoint;
  Point, Pt: TFreeSubdivisionPoint;
  P, P1, P2, Keel, NewOrigin: T3DVector;
  TmpP2D: T2DCoordinate;
  FirstSubmPoint,FirstPoint,Submerged: boolean;
  Points: array of T3DVector;
            // Array containing the coordinates of the underwaterpart of a face
  PointCapacity: integer;                  // Length of the dynamic point-array
  NoPoints: integer;           // number of points stored int the dynamic array
  Waterplane, LateralPlane, Frame: TFreeIntersection;
  Spline: TFreeSpline;
  HydObject: TFreehydrostaticCalc;
//  ffile: textfile;
  SDP, Zsdp, SDP_, Zsdp_, SmomentZ,
             Xsdp, Xsdp_, SmomentX, Z_min,
             Smid, Zmid, Smid_, Zmid_, Smom, dT, T, Vol: single;
  isymm, Nmet: integer;
  Sw, Sm: array [1..101] of single;
  Twl: array [1..101] of single;
  Xbon: array [1..101] of single;
  Wbon: array [1..101, 1..101] of single;

  function RotatePoint(P: T3DVector): T3DVector;
    // Rotate a point at heel=0 and trim=0 position to given trim and heel
  begin
    P.Z:=P.Z-Keel.Z;
    Result.x:=P.x * CosTrim+(P.y * SinHeel+P.z * CosHeel) * SinTrim;
    Result.y:=P.y * CosHeel-P.z * SinHeel;
    Result.z:=-P.x * SinTrim+(P.y * SinHeel+P.z * CosHeel) * CosTrim;
  end;

  procedure ProcessTriangle(P1, P2, P3: T3DVector);
  var
    VolumeMoment: T3DVector;
    Volume: TFloatType;
    Center: T3DVector;
    ax, ay, az: TFloatType;
  begin           // Reposition points with respect to the new projected origin
    P1.X:=P1.X-NewOrigin.X;
    P1.Y:=P1.Y-NewOrigin.Y;
    P1.Z:=P1.Z-NewOrigin.Z;
    P2.X:=P2.X-NewOrigin.X;
    P2.Y:=P2.Y-NewOrigin.Y;
    P2.Z:=P2.Z-NewOrigin.Z;
    P3.X:=P3.X-NewOrigin.X;
    P3.Y:=P3.Y-NewOrigin.Y;
    P3.Z:=P3.Z-NewOrigin.Z;
    Center.X:=(P1.X+P2.X+P3.X) / 3;
    Center.Y:=(P1.Y+P2.Y+P3.Y) / 3;
    Center.Z:=(P1.Z+P2.Z+P3.Z) / 3;
    Volume:=((P1.z) * (P2.x * P3.y-P2.y * P3.x)
            +(P1.y) * (P2.z * P3.x-P2.x * P3.z)
            +(P1.x) * (P2.y * P3.z-P2.z * P3.y)) / 6;
    if Volume <> 0 then begin
      VolumeMoment.X:=0.75 * Center.X * Volume;
      VolumeMoment.Y:=0.75 * Center.Y * Volume;
      VolumeMoment.Z:=0.75 * Center.Z * Volume;
      FData.Volume:=Fdata.Volume+Volume;
      FData.CenterOfBuoyancy.X:=FData.CenterOfBuoyancy.X+VolumeMoment.X;
      FData.CenterOfBuoyancy.Y:=FData.CenterOfBuoyancy.Y+VolumeMoment.Y;
      FData.CenterOfBuoyancy.Z:=FData.CenterOfBuoyancy.Z+VolumeMoment.Z;
    end;
    ax:=0.5*((P1.y-P2.y)*(P1.z+P2.z)+(P2.y-P3.y)*(P2.z+P3.z)+(P3.y-P1.y)*(P3.z+P1.z));
    ay:=0.5*((P1.z-P2.z)*(P1.x+P2.x)+(P2.z-P3.z)*(P2.x+P3.x)+(P3.z-P1.z)*(P3.x+P1.x));
    az:=0.5*((P1.x-P2.x)*(P1.y+P2.y)+(P2.x-P3.x)*(P2.y+P3.y)+(P3.x-P1.x)*(P3.y+P1.y));
    FData.WettedSurface:=FData.WettedSurface+Sqrt( ax*ax+ay*ay+az*az );
  end; {ProcessTriangle}

  procedure CheckSubmergedBody( P: T3DVector; Side: TFloatType );
  begin                   // Calculate extents of waterplane and submerged body
    P:=RotatePoint(P);
    if FirstSubmPoint then begin
      FData.SubMin:=P;
      FData.SubMax:=P;
      FirstSubmPoint:=False;
    end else MinMax(P, FData.SubMin, FData.SubMax);
    if (Side > -1e-6) and (Side < 1e-6) then
      if FirstPoint then begin                // Calculate waterline properties
        FData.WlMin:=P;
        FData.WlMax:=P;
        FirstPoint:=False;                    // point is exactly on waterplane
      end else MinMax( P,FData.WlMin, FData.WlMax );
    ;
  end;{CheckSubmergedBody}

begin
  if not Owner.Built then exit;                                 ///***???

   { Draft:=4.567;      4.713954;                      // Initial setup of data
     Trim:=-1.824;      -2.3698;
     HeelingAngle:=30;  40;
   }
  isymm:=0;
  Nmet:=0;
  CosHeel:=Cos(DegToRad(-HeelingAngle));
  SinHeel:=Sin(DegToRad(-HeelingAngle));
  CosTrim:=Cos(DegToRad(-TrimAngle));
  SinTrim:=Sin(DegToRad(-TrimAngle));

  Calculated:=False;           // Resets all data and calculated variables
                              // Calculate the definition of the waterlineplane
  Keel:=Vector(0.0, 0.0, Owner.FindLowestHydrostaticsPoint);
  FData.WaterlinePlane:=WaterlinePlane;

  // In order to calculate the volume enclosed by the underwatership correctly,
  // the origin (0.0, 0.0, 0.0) is projected onto the waterline plane
  NewOrigin:=ProjectPointOnPlane(ZERO, FData.WaterlinePlane);
                                             // Now calculate the actual volume
  FirstPoint:=True;
  Submerged:=False;
  PointCapacity:=5;
  Setlength( Points,PointCapacity );
  FirstSubmPoint:=True;
//FData.AbsoluteDraft:=Draft; //1000;

  //  Альтернативный метод N1 расчета объема с использованием СПВ и СПШ
  if Nmet = 1 then begin
    dT:=Owner.ProjectSettings.Projectdraft / 12;
    T:=-dT;
    Vol:=0;
    FData.WaterplaneEntranceAngle:=0;
    FData.WaterplaneArea:=0;
    FData.WaterplaneCOG.X:=0;
    FData.WaterplaneCOG.Y:=0;
    FData.WaterplaneCOG.Z:=0;
//  FData.AbsoluteDraft:=Draft;
    Waterplane:=TFreeIntersection.Create(Owner);
    Waterplane.FIntersectionType:=fiWaterline;
    Waterplane.FUseHydrostaticsSurfacesOnly:=True;
    for N:=1 to 13 do begin
      T:=T+dT;
      Draft:=T;
      FData.WaterlinePlane:=WaterlinePlane;
      Waterplane.FPlane:=FData.WaterlinePlane;
      Waterplane.Rebuild;
      Waterplane.CalculateArea(FData.WaterlinePlane, FData.WaterplaneArea,
        FData.WaterplaneCOG, FData.WaterplaneMomInertia);
      Sw[N]:=FData.WaterplaneArea;
      Vol:=Vol+Sw[N];
      if N = 13 then Vol:=Vol-Sw[N] / 2-Sw[1] / 2;
    end;
    FreeAndNil(Waterplane);
    Vol:=Vol * dT;
  end;

  // calculate overall extents of the hull alone
  for I:=1 to Owner.NumberOfLayers do begin Layer:=Owner.Layer[I-1];
    if Layer.UseInHydrostatics then
      for J:=1 to Layer.Count do begin Face:=Layer.Items[J-1];
        for K:=1 to Face.ChildCount do begin Child:=Face.Child[K-1];
          for L:=1 to Child.NumberOfPoints do begin
            P2:=Child.Point[L-1].Coordinate;
            if FirstPoint then begin
              FData.ModelMin:=P2;
              FData.ModelMax:=P2;
              FirstPoint:=False;
            end else MinMax( P2,FData.ModelMin,FData.ModelMax );
          end;
        end;
      end;
  end;
  FirstPoint:=True;
  for I:=1 to Owner.NumberOfLayers do begin Layer:=Owner.Layer[I-1];
    if Layer.UseInHydrostatics then
      for J:=1 to Layer.Count do begin Face:=Layer.Items[J-1];
        for K:=1 to Face.ChildCount do begin Child:=Face.Child[K-1]; // Calculate the portside of the model
          NoPoints:=0;
          P1:=Child.Point[Child.NumberOfPoints-1].Coordinate;        // calculate on which side of the waterplane this point is
          Side1:=FData.Waterlineplane.A * P1.x+FData.Waterlineplane.B *
            P1.y+FData.Waterlineplane.C * P1.z+FData.Waterlineplane.D;
          for L:=1 to Child.NumberOfPoints do begin
            P2:=Child.Point[L-1].Coordinate;
            Side2:=FData.Waterlineplane.A * P2.x+FData.Waterlineplane.B *
              P2.y+FData.Waterlineplane.C * P2.z+FData.Waterlineplane.D;
            if ((Side1 < -1e-6) and (Side2 > 1e-6))
            or ((Side1 > 1e-6) and (Side2 < -1e-6)) then begin
              // The current linesegment between P1-P2 intersects the waterlineplae
              if Side1 = Side2 then Parameter:=0.5 * (Side1+Side2)
                               else Parameter:=-Side1 / (Side2-Side1);
              P.X:=P1.X+Parameter * (P2.X-P1.X);
              P.Y:=P1.Y+Parameter * (P2.Y-P1.Y);
              P.Z:=P1.Z+Parameter * (P2.Z-P1.Z);
              Inc(NoPoints);
              if NoPoints > PointCapacity then begin
                Inc(PointCapacity);
                Setlength(Points, PointCapacity);
              end;
              Points[NoPoints-1]:=P;
              CheckSubmergedBody(P, 0.0);
            end;
            if Side2 <= 1e-6 then begin
//            if Side2<FData.AbsoluteDraft then FData.AbsoluteDraft:=Side2;
              // P2 lies also on or under the waterlineplane
              Inc(NoPoints);
              if NoPoints>PointCapacity then begin
                Inc(PointCapacity);
                Setlength( Points,PointCapacity );
              end;
              Points[NoPoints-1]:=P2;
              CheckSubmergedBody( P2,Side2 );
            end;
            P1:=P2;
            Side1:=Side2;
          end;                             // calculate volume aft of this face
          if NoPoints > 2 then Submerged:=True;
          for L:=3 to NoPoints do ProcessTriangle(Points[0],Points[L-2],Points[L-1]);
          if Layer.Symmetric then begin // Calculate the starboardside of the model
            NoPoints:=0;
            P1:=Child.Point[Child.NumberOfPoints-1].Coordinate;
            P1.Y:=-P1.Y; // calculate on which side of the waterplane this point is
            Side1:=FData.Waterlineplane.A * P1.x
                  +FData.Waterlineplane.B * P1.y
                  +FData.Waterlineplane.C * P1.z
                  +FData.Waterlineplane.D;
            for L:=1 to Child.NumberOfPoints do begin
              P2:=Child.Point[L-1].Coordinate;
              P2.Y:=-P2.Y;
              Side2:=FData.Waterlineplane.A * P2.x
                    +FData.Waterlineplane.B * P2.y
                    +FData.Waterlineplane.C * P2.z
                    +FData.Waterlineplane.D;
              if ((Side1 < -1e-6) and (Side2 > 1e-6)) or
                ((Side1 > 1e-6) and (Side2 < -1e-6)) then begin
                // The current linesegment between P1-P2 intersects the waterlineplane
                if Side1 = Side2 then Parameter:=0.5 * (Side1+Side2)
                                 else Parameter:=-Side1 / (Side2-Side1);
                P.X:=P1.X+Parameter * (P2.X-P1.X);
                P.Y:=P1.Y+Parameter * (P2.Y-P1.Y);
                P.Z:=P1.Z+Parameter * (P2.Z-P1.Z);
                Inc(NoPoints);
                if NoPoints > PointCapacity then begin
                  Inc(PointCapacity);
                  Setlength(Points, PointCapacity);
                end;
                Points[NoPoints-1]:=P;
                CheckSubmergedBody(P, 0.0);
              end;
              if Side2 <= 1e-6 then begin // P2 lies also under the waterlineplane
//              if Side2<FData.AbsoluteDraft then FData.AbsoluteDraft:=Side2;
                Inc(NoPoints);
                if NoPoints > PointCapacity then begin
                  Inc(PointCapacity);
                  Setlength(Points, PointCapacity);
                end;
                Points[NoPoints-1]:=P2;
                CheckSubmergedBody(P2, Side2);
              end;
              P1:=P2;
              Side1:=Side2;
            end;                           // calculate volume aft of this face
            if NoPoints > 2 then Submerged:=True;
            for L:=3 to NoPoints do
              ProcessTriangle(Points[0], Points[L-1], Points[L-2]);
          end;
        end;
      end;
  end;
  FData.Volume:=FData.Volume;
//FData.AbsoluteDraft:=-FData.AbsoluteDraft;
//if FirstPoint then
//if not submerged then FData.AbsoluteDraft:=0.0;
                       // No intersection with the watersurface found,
                       // the ship is either not submerged or totally submerged
  SubmergedLength:=Fdata.SubMax.X-FData.SubMin.X;
  SubmergedWidth:=FData.SubMax.Y-FData.SubMin.Y;
  FData.Displacement:=VolumeToDisplacement(FData.Volume,
    Owner.ProjectSettings.ProjectWaterDensity,
    Owner.ProjectSettings.ProjectAppendageCoefficient,
    Owner.ProjectSettings.ProjectUnits);
  FData.LengthWaterline:=FData.WlMax.X-FData.WlMin.X;
  FData.BeamWaterline:=FData.WlMax.Y-FData.WlMin.Y;
  if FData.Volume<>0 then begin // Translate center of buoyancy back to the original origin
    FData.CenterOfBuoyancy.X:=NewOrigin.X+FData.CenterOfBuoyancy.X / FData.Volume;
    FData.CenterOfBuoyancy.Y:=NewOrigin.Y+FData.CenterOfBuoyancy.Y / FData.Volume;
    FData.CenterOfBuoyancy.Z:=NewOrigin.Z+FData.CenterOfBuoyancy.Z / FData.Volume;
    FData.CenterOfBuoyancy:=RotatePoint(FData.CenterOfBuoyancy);
    if FData.LengthWaterline<>0 then FData.LCBPerc:=100*((FData.CenterOfBuoyancy.X
             - (FData.WlMin.X+FData.LengthWaterline/2))/FData.LengthWaterline);
    // Apply appendage coeff.
    FData.Volume:=FData.Volume * Owner.ProjectSettings.ProjectAppendageCoefficient;
  end;
  if (FData.Volume>0)
  and ((hcMidship in Calculations) or (hcAll in Calculations)) then begin
    CalculateMidshipLocation; // Calculate midship/mainframe properties-Расчет параметров мидельшпангоута до КВЛ
    FMidshipSection.FIntersectionType:=fiStation;
    FMidshipSection.FUseHydrostaticsSurfacesOnly:=True;
    FMidshipSection.FPlane.a:=1.0;
    FMidshipSection.FPlane.b:=0.0;
    FMidshipSection.FPlane.c:=0.0;
//  FMidshipSection.FPlane.d:=-FMidshipLocation;
    FMidshipSection.FPlane.d:=-Owner.ProjectSettings.ProjectSplitSectionLocation;
    FMidshipSection.CalculateArea( FData.WaterlinePlane,FData.MidshipArea,FData.MidshipCOG,TmpP2D ); // writeln( 'Mid='+floattostr( FData.MidshipArea ) );
    FData.MidshipCOG.Z:=FData.MidshipCOG.Z-FData.ModelMin.Z;
    Smid_:=FData.MidshipArea;
    Zmid_:=FData.MidshipCOG.Z;
    if Owner.ProjectSettings.ProjectCoefficients = fcActualData then
    begin
      if SubmergedWidth*Draft<>0.0 then FData.MidshipCoeff:=FData.MidshipArea/(SubmergedWidth*Draft);
      if FData.MidshipCoeff>1.01 then begin
        FData.MidshipCoeff:=FData.MidshipCoeff/2.0;
        FData.MidshipArea:=FData.MidshipArea/2.0;
        isymm:=1;
      end;
    end else
    if Owner.ProjectSettings.ProjectBeam*Draft<>0.0 then
      FData.MidshipCoeff:=FData.MidshipArea/(Owner.ProjectSettings.ProjectBeam*Draft);
  end;

  if (FData.Volume>0) // Calculate waterplane properties-Расчет площади ватерлинии
  and ((hcWaterline in Calculations)
  or (hcAll in Calculations)) then begin
    Waterplane:=TFreeIntersection.Create(Owner);
    Waterplane.FIntersectionType:=fiWaterline;
    Waterplane.FPlane:=FData.WaterlinePlane;
    Waterplane.FUseHydrostaticsSurfacesOnly:=True;
    Waterplane.Rebuild;
    Parameter:=-1e6;
    FData.WaterplaneEntranceAngle:=0;
    for J:=1 to Waterplane.Count do begin
      Spline:=Waterplane.Items[J-1]; // Rotate all the points back to a horizontal plane
      for K:=1 to Spline.NumberOfPoints do begin
        P1:=Spline.Point[K-1];
        P2:=RotatePoint(P1);
        Spline.Point[K-1]:=P2;
      end;
      if Spline.Value(0.0).X>Spline.Value(1.0).X then Spline.InvertDirection;
      P1:=Spline.Value(1.00);
      if P1.X > Parameter then begin
        Parameter:=P1.X;
        P2:=Spline.Value(0.96);   /// для судов лучше и точнее
        if P1.X-P2.X <> 0
           then FData.WaterplaneEntranceAngle:=RadToDeg(ArcTan((P2.Y-P1.Y)/(P1.X-P2.X)))
           else FData.WaterplaneEntranceAngle:=90.0;
        if P2.Y < P1.Y
           then FData.WaterplaneEntranceAngle:=-FData.WaterplaneEntranceAngle;      //if symmetry
        if FData.WaterplaneEntranceAngle < 0
           then FData.WaterplaneEntranceAngle:=-FData.WaterplaneEntranceAngle/2.0;
      end;
    end;
    Waterplane.CalculateArea(FData.WaterlinePlane, FData.WaterplaneArea,
      FData.WaterplaneCOG, FData.WaterplaneMomInertia);

    if Owner.ProjectSettings.ProjectCoefficients = fcActualData then begin
      if SubmergedWidth * SubmergedLength <> 0.0 then
        FData.WaterplaneCoeff :=
          FData.Waterplanearea / (SubmergedWidth * SubmergedLength);
      //if symmetry
      if FData.WaterplaneCoeff > 1.1 then begin
        FData.WaterplaneCoeff:=FData.WaterplaneCoeff / 2.0;
        FData.Waterplanearea:=FData.Waterplanearea / 2.0;
        FData.WaterplaneMomInertia.Y :=
          -FData.WaterplaneMomInertia.Y+FData.Waterplanearea *
          sqr(FData.WaterplaneCOG.X);
      end;
      //if symmetry end
    end
    else if FData.BeamWaterline * FData.LengthWaterline <> 0.0 then
      FData.WaterplaneCoeff :=
        FData.Waterplanearea / (FData.BeamWaterline * FData.LengthWaterline);
    FreeAndNil(Waterplane);
    // Stability data
    FData.KMtransverse:=FData.CenterOfBuoyancy.Z+FData.WaterplaneMomInertia.X /
      FData.Volume;
    FData.KMlongitudinal:=FData.CenterOfBuoyancy.Z+abs(
      FData.WaterplaneMomInertia.Y) / FData.Volume;
  end;
  if Draft<>0 then with Owner.ProjectSettings do begin
    if ProjectCoefficients = fcActualData then begin
      // Block coefficient based on length and beam measured on the waterline
      if SubmergedWidth * SubmergedLength * Draft <> 0.0 then
        FData.BlockCoefficient :=
          FData.Volume / (SubmergedWidth * SubmergedLength * Draft);
      // Prismatic coefficient based on length and beam measured on the waterline
      if FData.MidshipArea * SubmergedLength <> 0.0 then
        FData.PrismCoefficient:=FData.Volume / (FData.MidshipArea * SubmergedLength);
    end else begin
      // Block coefficient based on length and beam from project settings
      if ProjectLength*ProjectBeam*Draft <> 0.0 then
        FData.BlockCoefficient:=FData.Volume/(ProjectLength*ProjectBeam*Draft);
      // Prismatic coefficient based on length from project settings
      if FData.MidshipArea*ProjectLength <> 0.0 then
        FData.PrismCoefficient := FData.Volume/(FData.MidshipArea*ProjectLength);
    end;
    if FData.WaterplaneCoeff <> 0 then
      FData.VertPrismCoefficient:=FData.BlockCoefficient / FData.WaterplaneCoeff;
  end;

  // Calculate sectional areas SAC-Расчет СПШ
  if (hcSAC in Calculations) or (hcAll in Calculations) then
    if Owner.NumberofStations > 0 then begin
      Setlength(FData.SAC, Owner.NumberofStations);
      for I:=0 to Owner.NumberofStations-1 do begin
        FData.SAC[I].X:=0.0;
        FData.SAC[I].Y:=0.0;
      end;
      // Расчет семейства СПШ до крайней верхней ватерлинии для построения масштаба Бонжана
      SmomentZ:=FData.WaterlinePlane.D;                                            ////****
      // Расчет СПШ для действующей ватерлинии КВЛ
      FData.WaterlinePlane.D:=SmomentZ;
      for I:=0 to Owner.NumberofStations-1 do begin
        Frame:=TFreeIntersection.Create(Owner);
        Frame.FIntersectionType:=Owner.Station[I].FIntersectionType;
        Frame.Plane:=Owner.Station[I].Plane;
        Frame.FUseHydrostaticsSurfacesOnly:=True;
        Fdata.Sac[I].X:=-Frame.Plane.d;
        Frame.CalculateArea(FData.WaterlinePlane, FData.Sac[I].Y, P1, TmpP2D);
        FreeAndNil(Frame);
      end;
      if (Fdata.Sac[Trunc(Owner.NumberofStations / 2)].Y > FData.MidshipArea)
      and (isymm = 1) then
        for I:=0 to Owner.NumberofStations-1 do Fdata.Sac[I].Y:=Fdata.Sac[I].Y/2.0;
    end;
  if (hcLateralArea in Calculations) or (hcAll in Calculations) then begin
    // Calculate lateral area end center of gravity -Расчет площади контура ДП и цт (выше ватерлинии тоже)
    SmomentZ:=FData.WaterlinePlane.D;
    FData.WaterlinePlane.D:=-500;  // Задаем ватерлинию
    LateralPlane:=TFreeIntersection.Create(Owner);
    LateralPlane.FIntersectionType:=fiButtock;
    LateralPlane.FUseHydrostaticsSurfacesOnly:=True;
    LateralPlane.FPlane.a:=0.0;
    LateralPlane.FPlane.b:=1.0;
    LateralPlane.FPlane.c:=0.0;
    LateralPlane.FPlane.d:=-0.001;
    LateralPlane.CalculateArea(FData.WaterlinePlane, FData.LateralArea,
      FData.LateralCOG, TmpP2D);
    FData.LateralCOG.Z:=FData.LateralCOG.Z-FData.ModelMin.Z;
    SDP:=FData.LateralArea;
    Zsdp:=FData.LateralCOG.Z;
    Xsdp:=FData.LateralCOG.X;
    FreeAndNil(LateralPlane);
    FData.WaterlinePlane.D:=SmomentZ;
  end;

  if (hcLateralArea in Calculations) or (hcAll in Calculations) then begin
    // Calculate lateral area end center of gravity -Расчет площади ДП и цт
    LateralPlane:=TFreeIntersection.Create(Owner);
    LateralPlane.FIntersectionType:=fiButtock;
    LateralPlane.FUseHydrostaticsSurfacesOnly:=True;
    LateralPlane.FPlane.a:=0.0;
    LateralPlane.FPlane.b:=1.0;
    LateralPlane.FPlane.c:=0.0;
    LateralPlane.FPlane.d:=-0.001;
    LateralPlane.CalculateArea(FData.WaterlinePlane, FData.LateralArea,
      FData.LateralCOG, TmpP2D);
    FData.LateralCOG.Z:=FData.LateralCOG.Z-FData.ModelMin.Z;
    SDP_:=FData.LateralArea;
    Zsdp_:=FData.LateralCOG.Z;
    Xsdp_:=FData.LateralCOG.X;
    FreeAndNil(LateralPlane);
    //   Определяем боковую проекцию площади контура ДП выше ватерлинии и координату Z ее ЦТ от линии воды
    SmomentZ:=SDP * Zsdp-SDP_ * Zsdp_;
    SmomentX:=SDP * Xsdp-SDP_ * Xsdp_;
    SDP:=SDP-SDP_;
    if SDP<=0 then SDP:=0.0001;
    Zsdp:=SmomentZ / SDP+FData.WaterlinePlane.D;
    Xsdp:=SmomentX / SDP;
    FData.SDP:=SDP;
    FData.Zsdp:=Zsdp;
    FData.SDPCOG.X:=Xsdp;
    FData.Xsdp:=FData.WlMax.X-Xsdp; ///*** FData.BulbSectionCOG.X-Xsdp;
    FData.SDPCOG.Z:=FData.Zsdp-FData.WaterlinePlane.D;
  end;

  //1473 FData.LengthWaterline:=FData.WlMax.X-FData.WlMin.X;
  ////// Расчет минимального надводного борта

  Leaks:=TFasterListTFreeSubdivisionControlPoint.Create;
  FData.Z_min_board:=10000;
  Z_min:=10000;
  for I:=1 to Owner.Surface.NumberOfControlPoints do begin
    CtrlPoint:=Owner.Surface.ControlPoint[I-1];
    if CtrlPoint.Coordinate.Z<Z_min then Z_min:=CtrlPoint.Coordinate.Z;
    // Определяем наинизшую точку
    if CtrlPoint.IsLeak then Leaks.Add(CtrlPoint);
  end;

  for I:=1 to Leaks.Count do
    for J:=I to Leaks.Count do begin
      Pt:=TFreeSubdivisionControlPoint(Leaks[J-1]);
      if Pt.Coordinate.Z < FData.Z_min_board then
        FData.Z_min_board:=Pt.Coordinate.Z;
      // Определяем Z точки утечки с минимальной аппликатой
    end;
  FreeAndNil(Leaks);

  Calculated:=True;
end;{TFreeHydrostaticCalc.Calculate}

procedure TFreeHydrostaticCalc.Clear;
begin
  Calculated:=False;
  FHeelingAngle:=0.0;
  FTrim:=0.0;
  FDraft:=0.0;
  Fillchar(FData, SizeOf(FData), 0);
  FMidshipLocation:=0.0;
  FMidshipSection.Clear;
  FCalculations:=[hcAll];
end;

constructor TFreeHydrostaticCalc.Create(Owner: TFreeShip);
begin inherited Create;
  FOwner:=Owner;
  FMidshipSection:=TFreeIntersection.Create(Owner);
  Owner.FHydrostaticCalculations.Add(self);
  Clear;
end;

destructor TFreeHydrostaticCalc.Destroy; var Index: integer;
begin
  Clear;
  Index:=Owner.FHydrostaticCalculations.IndexOf(self);
  if Index <> -1 then Owner.FHydrostaticCalculations.Delete(Index);
  FreeAndNil(FMidshipSection);
  inherited Destroy;
end;

procedure TFreeHydrostaticCalc.ShowData;                                        // (Mode: TFreeHydrostaticsMode);
var Strings: TStringList;
    Dialog: TFreeHydrostaticsDialog;
    I: integer;
begin
  if not Calculated then Calculate;
  Strings:=TStringList.Create;
  AddData( Strings );                                            //,Mode,';' );
  Dialog:=TFreeHydrostaticsDialog.Create( Owner );
  ShowTranslatedValues( Dialog );
//  Strings.SaveToFile( 'FreeHydrostaticsMode.ShowData.Strings.txt' );
    Dialog.Edit.Lines.BeginUpdate;
    Dialog.Edit.Clear;
    for I:=0 to Strings.Count-1 do Dialog.Edit.Lines.Add( Strings.Strings[I] );
    Dialog.Edit.Lines.EndUpdate;
    Dialog.ShowModal;
    FreeAndNil(Strings);
    FreeAndNil(Dialog);
end;

