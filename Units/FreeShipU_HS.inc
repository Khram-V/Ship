
{
   TFreeHydrostaticCalc is an object class for hydrostatic calculations.
   Each calculation has it's own draft, trim and angle of heel.
   Multiple calculations can be stored and then send to a report.

function TFreeHydrostaticCalc.FGetErrorString:string;
begin Result:='';
   if feNothingSubmerged in Errors then Result:=Result+UserString(0)+EOL;
   if feMakingWater in Errors then
   Result:=Result+UserString(1)+#32+FloatToStrF(FData.Leak.X,ffFixed,7,3)+', '+
                                    FloatToStrF(FData.Leak.Y,ffFixed,7,3)+', '+
                                    FloatToStrF(FData.Leak.Z,ffFixed,7,3)+EOL;
end;
}
function TFreeHydrostaticCalc.FGetTrimAngle:TFloatType;
begin
   Result:=RadToDeg(ArcTan((-Trim*Cos(DegToRad(HeelingAngle)))/Owner.ProjectSettings.ProjectLength));
end;
function TFreeHydrostaticCalc.FGetWlPlane:T3DPlane;
var LowestValue:TFloatType;
    P1,P2,P3:T3DVector;
begin
   LowestValue:=Owner.FindLowestHydrostaticsPoint;
   P1:=Vector(0.0,0.0,LowestValue+(Draft-0.5*Trim));
   P2:=Vector(Owner.ProjectSettings.ProjectLength,0.0,LowestValue+(Draft+0.5*Trim));
   P3:=Vector(Owner.ProjectSettings.ProjectLength,Cos(DegToRad(-HeelingAngle)),LowestValue+(Draft+0.5*Trim)-Sin(DegToRad(-HeelingAngle)));
   Result:=PlanePPP(P1,P2,P3);
end;
procedure TFreeHydrostaticCalc.FSetCalculated(val:Boolean);
begin
   FCalculated:=val;
   if not FCalculated then begin Errors:=[];
      Fillchar(FData,SizeOf(FData),0);
      FMainframe.Clear;
   end;
end;
procedure TFreeHydrostaticCalc.FSetHeelingAngle(Val:TFloatType);
    begin if Val<>FHeelingAngle then begin FheelingAngle:=val; Calculated:=False; end; end;
procedure TFreeHydrostaticCalc.FSetTrim(Val:TFloatType);
    begin if Val<>FTrim then begin FTrim:=val; Calculated:=False; end; end;
procedure TFreeHydrostaticCalc.FSetDraft(Val:TFloatType);
    begin if Val<>FDraft then begin FDraft:=val; Calculated:=False; end; end;

procedure TFreeHydrostaticCalc.FSetErrors(val:TFreeHydrostaticErrors);
    begin {FErrors:=Val;} end; //#//#// Val:=[feNothingSubmerged]; без регистрации ошибок
procedure TFreeHydrostaticCalc.FSetHydrostaticType(val:TFreeHydrostaticType);
begin if Val<>FHydrostaticType then begin
          FHydrostaticType:=val;
            Calculated:=False;
       end; // Calculated:=True;
end;

// The actual calculation of the hydrostatics finds place in this procedure
procedure TFreeHydrostaticCalc.Calculate;
var I,J,K,L,First,Last,
    PointCapacity,             // Length of the dynamic point-array
    NoPoints: integer;         // number of points stored int the dynamic array
    CosHeel,SinHeel,CosTrim,SinTrim,Parameter,
    Side1,Side2,SubmergedLength,SubmergedWidth: TFloatType;
    Layer            : TFREESubdivisionLayer;
    Face             : TFreeSubdivisionControlFace;
    Child            : TFreeSubdivisionFace;
    P1,P2,P,Keel,NewOrigin: T3DVector;
    TmpP2D           : T2DCoordinate;
    FirstSubmPoint,FirstPoint,Submerged: Boolean;
    Points       : array of T3DVector; // Array containing the coordinates of the underwaterpart of a face
    Waterplane,LateralPlane,Frame: TFreeIntersection;
    Spline: TFreeSpline;

    function RotatePoint(P:T3DVector):T3DVector;
    begin // Rotate a point at heel=0 and trim=0 position to given trim and heel
      P.Z:=P.Z-Keel.Z;
      Result.x:=P.x*CosTrim+P.y*SinHeel*SinTrim+P.z*CosHeel*SinTrim;
      Result.y:=P.y*CosHeel-P.z*SinHeel;
      Result.z:=-P.x*SinTrim+P.y*SinHeel*CosTrim+P.z*CosHeel*CosTrim;
    end;

    procedure ProcessTriangle(P1,P2,P3:T3DVector);
    var VolumeMoment,Center: T3DVector;
        Volume,ax,ay,az: TFloatType;
    begin         // Reposition points with respect to the new projected origin
       P1:=P1-NewOrigin;
       P2:=P2-NewOrigin;
       P3:=P3-NewOrigin;
       Center:=(P1+P2+P3)/3;
       Volume:=((P1.z)*(P2.x*P3.y-P2.y*P3.x)+
                (P1.y)*(P2.z*P3.x-P2.x*P3.z)+
                (P1.x)*(P2.y*P3.z-P2.z*P3.y))/6;
       if Volume<>0 then begin
          VolumeMoment:=(0.75*Volume)*Center;
          FData.Volume:=Fdata.Volume+Volume;
          FData.CenterOfBuoyancy:=FData.CenterOfBuoyancy+VolumeMoment;
       end;
       ax:=0.5*((P1.y-P2.y)*(P1.z+P2.z)+(P2.y-P3.y)*(P2.z+P3.z)+(P3.y-P1.y)*(P3.z+P1.z));
       ay:=0.5*((P1.z-P2.z)*(P1.x+P2.x)+(P2.z-P3.z)*(P2.x+P3.x)+(P3.z-P1.z)*(P3.x+P1.x));
       az:=0.5*((P1.x-P2.x)*(P1.y+P2.y)+(P2.x-P3.x)*(P2.y+P3.y)+(P3.x-P1.x)*(P3.y+P1.y));
       FData.WettedSurface:=FData.WettedSurface+Sqrt(ax*ax+ay*ay+az*az);
    end;

    procedure CheckSubmergedBody(P:T3DVector;Side:TFloatType);
    begin                 // Calculate extents of waterplane and submerged body
      P:=RotatePoint(P);
      if FirstSubmPoint then begin
         FData.SubMin:=P;
         FData.SubMax:=P;
         FirstSubmPoint:=False;
      end else MinMax(P,FData.SubMin,FData.SubMax);
      if (Side>-1e-5) and (Side<1e-5) then begin // point is exactly on waterplane
         if FirstPoint then begin               // Calculate waterline properties
            FData.WlMin:=P;
            FData.WlMax:=P;
            FirstPoint:=False;
         end else MinMax(P,FData.WlMin,FData.WlMax);
      end;
    end;
begin                                                  // Initial setup of data
   {
     Draft:=4.567;              Draft:=4.713954;
     Trim:=-1.824;              Trim:=-2.3698;
     HeelingAngle:=30;          HeelingAngle:=40;
   }
   CosHeel:=Cos(DegToRad(-HeelingAngle));
   SinHeel:=Sin(DegToRad(-HeelingAngle));
   CosTrim:=Cos(DegToRad(-TrimAngle));
   SinTrim:=Sin(DegToRad(-TrimAngle));
   Calculated:=False;         // Resets all data and calculated variables
                              // Calculate the definition of the waterlineplane
   Keel:=Vector(0.0,0.0,Owner.FindLowestHydrostaticsPoint);
   FData.WaterlinePlane:=WaterlinePlane;

   // In order to calculate the volume enclosed by the underwatership correctly,
   // the origin (0.0, 0.0, 0.0) is projected onto the waterline plane
   NewOrigin:=ProjectPointOnPlane(ZERO,FData.WaterlinePlane);

   // Now calculate the actual volume
   FirstPoint:=True;
   Submerged:=False;
   PointCapacity:=5;
   Setlength(Points,PointCapacity);
   FirstSubmPoint:=True;
   FData.AbsoluteDraft:=1000;

   // calculate overall extents of the hull alone
   for I:=1 to Owner.NumberOfLayers do begin
      Layer:=Owner.Layer[I-1];
      if Layer.UseInHydrostatics then for J:=1 to Layer.Count do begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do begin
            Child:=Face.Child[K-1];
            for L:=1 to Child.NumberOfPoints do begin
               P2:=Child.Point[L-1].Coordinate;
               if FirstPoint then begin
                  FData.ModelMin:=P2;
                  FData.ModelMax:=P2;
                  FirstPoint:=False;
               end else MinMax(P2,FData.ModelMin,FData.ModelMax);
            end;
         end;
      end;
   end;
   FirstPoint:=True;
   for I:=1 to Owner.NumberOfLayers do begin
      Layer:=Owner.Layer[I-1];
      if Layer.UseInHydrostatics then for J:=1 to Layer.Count do begin
         Face:=Layer.Items[J-1];
         for K:=1 to Face.ChildCount do begin
            Child:=Face.Child[K-1];      // Calculate the portside of the model
            NoPoints:=0;
            P1:=Child.Point[Child.NumberOfPoints-1].Coordinate; // calculate on which side of the waterplane this point is
            Side1:=FData.Waterlineplane.A*P1.x+FData.Waterlineplane.B*P1.y+FData.Waterlineplane.C*P1.z+FData.Waterlineplane.D;
            for L:=1 to Child.NumberOfPoints do begin
               P2:=Child.Point[L-1].Coordinate;
               Side2:=FData.Waterlineplane.A*P2.x+FData.Waterlineplane.B*P2.y+FData.Waterlineplane.C*P2.z+FData.Waterlineplane.D;
               if ((Side1<-1e-5)
               and (Side2>1e-5))
               or ((Side1>1e-5)
               and (Side2<-1e-5)) then begin // The current linesegment between P1-P2 intersects the waterlineplae
                  if Side1=Side2 then Parameter:=0.5*(Side1+Side2)
                                 else Parameter:=-Side1/(Side2-Side1);
                  P:=P1+Parameter*(P2-P1);
                  Inc(NoPoints);
                  if NoPoints>PointCapacity then begin
                     inc(PointCapacity);
                     Setlength(Points,PointCapacity);
                  end;
                  Points[NoPoints-1]:=P;
                  CheckSubmergedBody(P,0.0);
               end;
               if Side2<=1e-5 then begin
                  if Side2<FData.AbsoluteDraft then FData.AbsoluteDraft:=Side2; // P2 lies also on or under the waterlineplane
                  Inc(NoPoints);
                  if NoPoints>PointCapacity then begin
                     inc(PointCapacity);
                     Setlength(Points,PointCapacity);
                  end;
                  Points[NoPoints-1]:=P2;
                  if Side2<-1e-5 then begin // point is submerged, check if the model is making water
                     if (Child.Point[L-1].IsBoundaryVertex)
                     and (abs(Child.Point[L-1].Coordinate.Y)>1e-4) then begin
                        if not (feMakingWater in Errors) then begin
                           Errors:=Errors+[feMakingwater];
                           FData.Leak:=Child.Point[L-1].Coordinate;
                        end;
                     end;
                  end;
                  CheckSubmergedBody(P2,Side2);
               end;
               P1:=P2;
               Side1:=Side2;
            end;

            // calculate volume aft of this face
            if NoPoints>2 then Submerged:=True;
            for L:=3 to NoPoints do ProcessTriangle(Points[0],Points[L-2],Points[L-1]);

            if Layer.Symmetric then begin // Calculate the starboardside of the model
               NoPoints:=0;
               P1:=Child.Point[Child.NumberOfPoints-1].Coordinate;
               P1.Y:=-P1.Y; // calculate on which side of the waterplane this point is
               Side1:=FData.Waterlineplane.A*P1.x+FData.Waterlineplane.B*P1.y+FData.Waterlineplane.C*P1.z+FData.Waterlineplane.D;
               for L:=1 to Child.NumberOfPoints do begin
                  P2:=Child.Point[L-1].Coordinate;
                  P2.Y:=-P2.Y;
                  Side2:=FData.Waterlineplane.A*P2.x+FData.Waterlineplane.B*P2.y+FData.Waterlineplane.C*P2.z+FData.Waterlineplane.D;
                  if ((Side1<-1e-5)
                  and (Side2>1e-5))
                  or ((Side1>1e-5)
                  and (Side2<-1e-5)) then begin // The current linesegment between P1-P2 intersects the waterlineplae
                     if Side1=Side2 then Parameter:=0.5*(Side1+Side2)
                                    else Parameter:=-Side1/(Side2-Side1);
                     P.X:=P1.X+Parameter*(P2.X-P1.X);
                     P.Y:=P1.Y+Parameter*(P2.Y-P1.Y);
                     P.Z:=P1.Z+Parameter*(P2.Z-P1.Z);
                     Inc(NoPoints);
                     if NoPoints>PointCapacity then begin
                        inc(PointCapacity);
                        Setlength(Points,PointCapacity);
                     end;
                     Points[NoPoints-1]:=P;
                     CheckSubmergedBody(P,0.0);
                  end;
                  if Side2<=1e-5 then begin // P2 lies also under the waterlineplane
                     if Side2<FData.AbsoluteDraft then FData.AbsoluteDraft:=Side2;
                     Inc(NoPoints);
                     if NoPoints>PointCapacity then begin
                        inc(PointCapacity);
                        Setlength(Points,PointCapacity);
                     end;
                     Points[NoPoints-1]:=P2;
                     if Side2<-1e-5 then begin // point is submerged, check if the model is making water
                        if (Child.Point[L-1].IsBoundaryVertex)
                        and (abs(Child.Point[L-1].Coordinate.Y)>1e-4) then begin
                           if not (feMakingWater in Errors) then begin
                              Errors:=Errors+[feMakingwater];
                              FData.Leak:=Child.Point[L-1].Coordinate;
                           end;
                        end;
                     end;
                     CheckSubmergedBody(P2,Side2);
                  end;
                  P1:=P2;
                  Side1:=Side2;
               end;
               // calculate volume aft of this face
               if NoPoints>2 then Submerged:=True;
               for L:=3 to NoPoints do ProcessTriangle(Points[0],Points[L-1],Points[L-2]);
            end;
         end;
      end;
   end;
   FData.AbsoluteDraft:=-FData.AbsoluteDraft;
   if FirstPoint then begin // No intersection with the watersurface found, the
                           // ship is either not submerged or totally submerged
      if not submerged then begin
         Errors:=Errors+[feNothingSubmerged];
         FData.AbsoluteDraft:=0.0;
      end;
   end;
   if feMakingWater in Errors then begin
      FData.Volume:=0.0;
      FData.CenterOfBuoyancy:=ZERO;
   end;

   SubmergedLength:=Fdata.SubMax.X-FData.SubMin.X;
   SubmergedWidth:=FData.SubMax.Y-FData.SubMin.Y;
   FData.Displacement:=VolumeToDisplacement(FData.Volume,Owner.ProjectSettings.ProjectWaterDensity,Owner.ProjectSettings.ProjectAppendageCoefficient,Owner.ProjectSettings.ProjectUnits);
   FData.LengthWaterline:=FData.WlMax.X-FData.WlMin.X;
   FData.BeamWaterline:=FData.WlMax.Y-FData.WlMin.Y;
   if FData.Volume<>0 then begin // Translate center of buoyancy back to the original origin
      FData.CenterOfBuoyancy.X:=NewOrigin.X+FData.CenterOfBuoyancy.X/FData.Volume;
      FData.CenterOfBuoyancy.Y:=NewOrigin.Y+FData.CenterOfBuoyancy.Y/FData.Volume;
      FData.CenterOfBuoyancy.Z:=NewOrigin.Z+FData.CenterOfBuoyancy.Z/FData.Volume;
      FData.CenterOfBuoyancy:=RotatePoint(FData.CenterOfBuoyancy);
      if FData.LengthWaterline<>0 then FData.LCBPerc:=100*((FData.CenterOfBuoyancy.X-Owner.ProjectSettings.MidleFrame)/FData.LengthWaterline);
      // Apply appendage coeff.
      FData.Volume:=FData.Volume*Owner.ProjectSettings.ProjectAppendageCoefficient;
   end;
   if (FData.Volume>0) and (Errors=[])
   and ((hcMainframe in Calculations) or (hcAll in Calculations)) then begin
      // Calculate mainframe properties
      FMainframe.IntersectionType:=fiStation;
      FMainframe.UseHydrostaticsSurfacesOnly:=True;
      FMainframe.FPlane.a:=1.0;
      FMainframe.FPlane.b:=0.0;
      FMainframe.FPlane.c:=0.0;
      FMainframe.FPlane.d:=-Owner.ProjectSettings.MidleFrame;
      FMainframe.CalculateArea(FData.WaterlinePlane,FData.MainframeArea,FData.MainframeCOG,TmpP2D);
      FData.MainframeCOG.Z:=FData.MainframeCOG.Z-FData.ModelMin.Z;
      if Owner.ProjectSettings.ProjectCoefficients=fcActualData then begin
         if SubmergedWidth*Draft<>0.0 then FData.MainframeCoeff:=FData.Mainframearea/(SubmergedWidth*Draft);
      end else if Owner.ProjectSettings.ProjectBeam*Draft<>0.0 then FData.MainframeCoeff:=FData.Mainframearea/(Owner.ProjectSettings.ProjectBeam*Draft);
   end;
   if (FData.Volume>0) and (Errors=[])
   and ((hcWaterline in Calculations)
   or (hcAll in Calculations)) then begin    // Calculate waterplane properties
      Waterplane:=TFreeIntersection.Create(Owner);
      Waterplane.IntersectionType:=fiWaterline;
      Waterplane.FPlane:=FData.WaterlinePlane;
      Waterplane.UseHydrostaticsSurfacesOnly:=True;
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
         if P1.X>Parameter then begin
            Parameter:=P1.X;
            P2:=Spline.Value(0.99);
            if P1.X-P2.X<>0 then FData.WaterplaneEntranceAngle:=RadToDeg(ArcTan((P2.Y-P1.Y)/(P1.X-P2.X)))
                            else FData.WaterplaneEntranceAngle:=90.0;
            if P2.Y<P1.Y then FData.WaterplaneEntranceAngle:=-FData.WaterplaneEntranceAngle;
         end;
      end;
      Waterplane.CalculateArea(FData.WaterlinePlane,FData.WaterplaneArea,FData.WaterplaneCOG,FData.WaterplaneMomInertia);
      if Owner.ProjectSettings.ProjectCoefficients=fcActualData then begin
         if SubmergedWidth*SubmergedLength<>0.0 then FData.WaterplaneCoeff:=FData.Waterplanearea/(SubmergedWidth*SubmergedLength);
      end else if Owner.ProjectSettings.ProjectBeam*Owner.ProjectSettings.ProjectLength<>0.0 then FData.WaterplaneCoeff:=FData.Waterplanearea/(Owner.ProjectSettings.ProjectBeam*Owner.ProjectSettings.ProjectLength);
      Waterplane.Destroy;                                     // Stability data
      FData.KMtransverse:=FData.CenterOfBuoyancy.Z+FData.WaterplaneMomInertia.X/FData.Volume;
      FData.KMlongitudinal:=FData.CenterOfBuoyancy.Z+FData.WaterplaneMomInertia.Y/FData.Volume;
   end;
   if Draft<>0 then begin
      if FData.Waterplanearea*Draft<>0 then FData.VertPrismCoefficient:=FData.Volume/(FData.Waterplanearea*Draft);
      if Owner.ProjectSettings.ProjectCoefficients=fcActualData then begin
         // Block coefficient based on length and beam measured on the waterline
         if SubmergedWidth*SubmergedLength*Draft<>0.0 then FData.BlockCoefficient:=FData.Volume/(SubmergedWidth*SubmergedLength*Draft);
         // Prismatic coefficient based on length and beam measured on the waterline
         if FData.Mainframearea*SubmergedLength<>0.0 then FData.PrismCoefficient:=FData.Volume/(FData.MainframeArea*SubmergedLength);
      end else begin
         // Block coefficient based on length and beam from project settings
         if Owner.ProjectSettings.ProjectLength*Owner.ProjectSettings.ProjectBeam*Draft<>0.0 then FData.BlockCoefficient:=FData.Volume/(Owner.ProjectSettings.ProjectLength*Owner.ProjectSettings.ProjectBeam*Draft);
         // Prismatic coefficient based on length from project settings
         if FData.Mainframearea*Owner.ProjectSettings.ProjectLength<>0.0 then FData.PrismCoefficient:=FData.Volume/(FData.Mainframearea*Owner.ProjectSettings.ProjectLength);
      end;
   end;
   if (hcSAC in Calculations) or (hcAll in Calculations) then begin
      // Calculate sectional areas
      if Owner.NumberofStations>0 then begin
         Setlength(FData.SAC,Owner.NumberofStations);
         for I:=1 to Owner.NumberofStations do begin
            FData.SAC[I-1].X:=0.0;
            FData.SAC[I-1].Y:=0.0;
         end;
         for I:=1 to Owner.NumberofStations do begin
            Frame:=TFreeIntersection.Create(Owner);
            Frame.IntersectionType:=Owner.Station[I-1].IntersectionType;
            Frame.Plane:=Owner.Station[I-1].Plane;
            Frame.UseHydrostaticsSurfacesOnly:=True;
            Fdata.Sac[I-1].X:=-Frame.Plane.d;
            Frame.CalculateArea(FData.WaterlinePlane,FData.Sac[I-1].Y,P1,TmpP2D);
            Frame.Destroy;
         end;
         First:=Owner.NumberofStations-1;
         Last:=0;
         for I:=1 to Owner.NumberofStations do if FData.SAC[I-1].Y<>0 then begin
            if I-1<First then First:=I-1;
            if I-1>last then Last:=I-1;
         end;
         if First>0 then Dec(First);
         if Last<Owner.NumberofStations-1 then inc(Last);
         for I:=First to Last do FData.SAC[I-First]:=FData.SAC[I];
         if Last-First+1>0 then Setlength(FData.SAC,Last-First+1)
                           else Setlength(FData.SAC,0);
      end
   end;                         // Calculate lateral area end center of gravity
   if (hcLateralArea in Calculations) or (hcAll in Calculations) then begin
      LateralPlane:=TFreeIntersection.Create(Owner);
      LateralPlane.IntersectionType:=fiButtock;
      LateralPlane.UseHydrostaticsSurfacesOnly:=True;
      LateralPlane.FPlane.a:=0.0;
      LateralPlane.FPlane.b:=1.0;
      LateralPlane.FPlane.c:=0.0;
      LateralPlane.FPlane.d:=-0.001;
      LateralPlane.CalculateArea(FData.WaterlinePlane,FData.LateralArea,FData.LateralCOG,TmpP2D);
      FData.LateralCOG.Z:=FData.LateralCOG.Z-FData.ModelMin.Z;
      LateralPlane.Destroy;
   end;
   Calculated:=True;
end;

// Creates and calculates a hydrostatics calculation

function TFreeEdit.Hydrostatics_Calculate
( Draft,AngleOfHeel,Trim: TFloatType): TFreeHydrostaticCalc;
begin
   if not Ship.ProjectSettings.DisableModelCheck then Model_Check(False);
   Result:=TFreeHydrostaticCalc.Create(Ship);
   Result.Trim:=Trim;
   Result.HeelingAngle:=AngleOfHeel;
   Result.Draft:=Draft;
   Result.Calculate;
   Result.ShowData( fhSingleCalculation );
end;

procedure TFreeHydrostaticCalc.ShowData;                                        // (Mode: TFreeHydrostaticsMode);
var Strings: TStringList;
    Dialog: TFreeHydrostaticsDialog;
    I: integer;
begin
  if not Calculated then Calculate;
  Strings:=TStringList.Create;
  AddData( Strings,Mode,';' );
  Dialog:=TFreeHydrostaticsDialog.Create( Owner );
  ShowTranslatedValues( Dialog );
  //Strings.SaveToFile( 'FreeHydrostaticsMode.ShowData.Strings.txt' );
    Dialog.Edit.Lines.BeginUpdate;
    Dialog.Edit.Clear;
    for I:=0 to Strings.Count-1 do Dialog.Edit.Lines.Add( Strings.Strings[I] );
    Dialog.Edit.Lines.EndUpdate;
    Dialog.ShowModal;
    FreeAndNil(Strings);
    FreeAndNil(Dialog);
end;

// Add calculated data to a stringlist to either show in a report or save to disc

procedure TFreeHydrostaticCalc.AddData
( Strings:TStringlist;Mode:TFreeHydrostaticsMode; Separator:char );
var Str: string;
    I,N: integer;
    Properties,Total: TLayerProperties;
    Position: TFloatType;
begin
   Separator:=#32;
   if not Calculated then Calculate;
// if Errors=[] then begin
      if Mode=fhSingleCalculation then begin
         AddHeader(Strings);
         Strings.Add(UserString(2)+':');
         Strings.Add(Space(4)+Makelength(Userstring(3),38)+' : '+Separator+MakeLength(FData.Volume,-1,12)+Separator+VolStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+Makelength(Userstring(4),38)+' : '+Separator+MakeLength(FData.Displacement,-1,12)+Separator+WeightStr(Owner.ProjectSettings.ProjectUnits));
         if Owner.ProjectSettings.ProjectCoefficients=fcActualData then
         begin
            Strings.Add(Space(4)+MakeLength(Userstring(5),38)+' : '+Separator+MakeLength(FData.SubMax.X-FData.SubMin.X,3,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
            Strings.Add(Space(4)+MakeLength(Userstring(6),38)+' : '+Separator+MakeLength(FData.SubMax.Y-FData.SubMin.Y,3,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         end;
         Strings.Add(Space(4)+MakeLength(Userstring(7),38)+' : '+Separator+MakeLength(FData.BlockCoefficient,4,12));
         Strings.Add(Space(4)+MakeLength(Userstring(8),38)+' : '+Separator+MakeLength(FData.PrismCoefficient,4,12));
         Strings.Add(Space(4)+MakeLength(Userstring(9),38)+' : '+Separator+MakeLength(FData.VertPrismCoefficient,4,12));
         Strings.Add(Space(4)+MakeLength(Userstring(10),38)+' : '+Separator+MakeLength(FData.WettedSurface,-1,12)+Separator+Areastr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(11),38)+' : '+Separator+MakeLength(FData.CenterOfBuoyancy.X,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(11),38)+' : '+Separator+MakeLength(FData.LCBPerc,3,12)+Separator+'[%]');
         Strings.Add(Space(4)+MakeLength(Userstring(12),38)+' : '+Separator+MakeLength(FData.CenterOfBuoyancy.Z,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));

         Strings.Add(Userstring(13)+':');
         Strings.Add(Space(4)+MakeLength(Userstring(14),38)+' : '+Separator+MakeLength(FData.MainframeArea,-1,12)+Separator+Areastr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(15),38)+' : '+Separator+MakeLength(FData.MainframeCoeff,4,12));
         Strings.Add(Userstring(16)+':');
         Strings.Add(Space(4)+MakeLength(Userstring(17),38)+' : '+Separator+MakeLength(FData.LengthWaterline,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(18),38)+' : '+Separator+MakeLength(FData.BeamWaterline,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(19),38)+' : '+Separator+MakeLength(FData.WaterplaneArea,-1,12)+Separator+Areastr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(20),38)+' : '+Separator+MakeLength(FData.WaterplaneCoeff,4,12));
         Strings.Add(Space(4)+MakeLength(Userstring(21),38)+' : '+Separator+MakeLength(FData.WaterplaneCOG.X,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(22),38)+' : '+Separator+MakeLength(FData.WaterplaneEntranceAngle,-1,12)+Separator+'[degr.]');
         Strings.Add(Space(4)+MakeLength(Userstring(23),38)+' : '+Separator+MakeLength(FData.WaterplaneMomInertia.X,-1,12)+Separator+InertiaStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(24),38)+' : '+Separator+MakeLength(FData.WaterplaneMomInertia.Y,-1,12)+Separator+InertiaStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Userstring(25)+':');
         Strings.Add(Space(4)+MakeLength(Userstring(26),38)+' : '+Separator+MakeLength(FData.KMtransverse,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(27),38)+' : '+Separator+MakeLength(FData.KMlongitudinal,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Userstring(28)+':');
         Strings.Add(Space(4)+MakeLength(Userstring(29),38)+' : '+Separator+MakeLength(FData.LateralArea,-1,12)+Separator+Areastr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(30),38)+' : '+Separator+MakeLength(FData.LateralCOG.X,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add(Space(4)+MakeLength(Userstring(31),38)+' : '+Separator+MakeLength(FData.LateralCOG.Z,-1,12)+Separator+LengthStr(Owner.ProjectSettings.ProjectUnits));
         Strings.Add('');
         Strings.Add('');
      end else
      begin
         if Strings.Count=0 then
         begin
            AddHeader(Strings);
            Strings.Add(' |  Draft |   Trim  |   Lwl   |   Bwl  |   Vol   |  Displ  |   LCB   |   VCB  |   CB   |   AM   |   CM   |   AW   |   CW   |   CP   |    S   |  KMtrv | KMlong | ');
            if Owner.ProjectSettings.ProjectUnits=fuImperial then
            Strings.Add(' |  [ft]  |   [ft]  |   [ft]  |  [ft]  |  [ft3]  |   [t]   |   [ft]  |  [ft]  |        |  [ft2] |        |  [ft2] |        |        |  [ft2] |  [ft]  |  [ft]  | ')
       else Strings.Add(' |  [m]   |   [m]   |   [m]   |   [m]  |   [m3]  |   [t]   |   [m]   |   [m]  |        |  [m2]  |        |  [m2]  |        |        |  [m2]  |   [m]  |   [m]  | ');
            Strings.Add(' |--------+---------+---------+--------+---------+---------+---------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------| ');
         end;
         Strings.Add(' | '+Makelength(Draft,3,6)+' | '+
                     Makelength(Trim,3,7)+' | '+
                     Makelength(FData.LengthWaterline,-1,7)+' | '+
                     Makelength(FData.BeamWaterline,-1,6)+' | '+
                     MakeLength(FData.Volume,-1,7)+' | '+
                     MakeLength(FData.Displacement,-1,7)+' | '+
                     MakeLength(FData.CenterOfBuoyancy.X,-1,7)+' | '+
                     MakeLength(FData.CenterOfBuoyancy.Z,-1,6)+' | '+
                     MakeLength(FData.BlockCoefficient,4,6)+' | '+
                     MakeLength(FData.MainframeArea,-1,6)+' | '+
                     MakeLength(FData.MainframeCoeff,4,6)+' | '+
                     MakeLength(FData.WaterplaneArea,-1,6)+' | '+
                     MakeLength(FData.WaterplaneCoeff,4,6)+' | '+
                     MakeLength(FData.PrismCoefficient,4,6)+' | '+
                     MakeLength(FData.WettedSurface,-1,6)+' | '+
                     MakeLength(FData.KMtransverse,-1,6)+' | '+
                     MakeLength(FData.KMlongitudinal,-1,6)+' | ');
      end;
// end else Strings.Add(ErrorString);

   if Mode=fhSingleCalculation then
   begin
      // Check if any layers are present to show
      N:=0;
      for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].Count>0 then inc(N);
      if N>0 then
      begin
         for i:=1 to 2 do Strings.Add('');
         Fillchar(Total,SizeOf(Total),0);
         Strings.Add(Userstring(32)+':');
         Strings.Add('|'+space(10)+Makelength(UserString(33),14)+' | '+
                                   Makelength(UserString(34),6)+' | '+
                                   Makelength(UserString(35),9)+' | '+
                                   Makelength(UserString(36),8)+' | '+
                                   ' COG X  |  COG Y  |  COG Z  |');
         Strings.Add('| '+MakeLength('',23)+
                    ' | '+Makelength(AreaStr(Owner.ProjectSettings.ProjectUnits),6)+
                    ' | '+Makelength('',9)+
                    ' | '+Makelength(WeightStr(Owner.ProjectSettings.ProjectUnits),8)+
                    ' | '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),7)+
                    ' | '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),7)+
                    ' | '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),7)+' |');

         Strings.Add('|-------------------------|--------|-----------|----------|---------|---------|---------|');

         for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].Count>0 then
         begin
            Properties:=Owner.Layer[I-1].SurfaceProperties;
            Properties.SurfaceCenterOfGravity.Z:=Properties.SurfaceCenterOfGravity.Z-FData.ModelMin.Z;
            if Owner.ProjectSettings.ProjectUnits=fuImperial then Properties.Weight:=Properties.Weight/(12*2240)
                                                             else Properties.Weight:=Properties.Weight/1000;

            Str:=Owner.Layer[I-1].Name;
            While Length(Str)<23 do Str:=Str+#32;
            if length(Str)>23 then Str:=Copy(Str,1,23);
            Strings.Add('| '+Str+' | '+Makelength(Properties.SurfaceArea,-1,6)+
                                 ' | '+MakeLength(Owner.Layer[I-1].Thickness,3,9)+
                                 ' | '+Makelength(Properties.Weight,3,8)+
                                 ' | '+MakeLength(Properties.SurfaceCenterOfGravity.X,3,7)+
                                 ' | '+MakeLength(Properties.SurfaceCenterOfGravity.Y,3,7)+
                                 ' | '+MakeLength(Properties.SurfaceCenterOfGravity.Z,3,7)+' |');
            Total.SurfaceArea:=Total.SurfaceArea+Properties.SurfaceArea;
            Total.Weight:=Total.Weight+Properties.Weight;
            Total.SurfaceCenterOfGravity.X:=Total.SurfaceCenterOfGravity.X+Properties.Weight*Properties.SurfaceCenterOfGravity.X;
            Total.SurfaceCenterOfGravity.Y:=Total.SurfaceCenterOfGravity.Y+Properties.Weight*Properties.SurfaceCenterOfGravity.Y;
            Total.SurfaceCenterOfGravity.Z:=Total.SurfaceCenterOfGravity.Z+Properties.Weight*Properties.SurfaceCenterOfGravity.Z;
         end;
         if N>1 then
         begin
            // if more then 1 layer is added, then show the properties of all layers together
            Strings.Add('|-------------------------|--------|-----------|----------|---------|---------|---------|');
            if Total.Weight<>0 then
            begin
               Total.SurfaceCenterOfGravity.X:=Total.SurfaceCenterOfGravity.X/Total.Weight;
               Total.SurfaceCenterOfGravity.Y:=Total.SurfaceCenterOfGravity.Y/Total.Weight;
               Total.SurfaceCenterOfGravity.Z:=Total.SurfaceCenterOfGravity.Z/Total.Weight;
            end;
            Str:=UserString(37);
            While Length(Str)<23 do Str:=Str+#32;
            Strings.Add('  '+Str+'   '+Makelength(Total.SurfaceArea,-1,6)+
                                 '   '+MakeLength('',9)+
                                 '   '+Makelength(Total.Weight,3,8)+
                                 '   '+MakeLength(Total.SurfaceCenterOfGravity.X,3,7)+
                                 '   '+MakeLength(Total.SurfaceCenterOfGravity.Y,3,7)+
                                 '   '+MakeLength(Total.SurfaceCenterOfGravity.Z,3,7));
         end;
         // Add sectional Area data
         N:=Length(FData.SAC);
         if N>0 then
         begin
            begin
               Strings.Add('');
               Strings.Add('');
               Strings.Add(UserString(38)+':');
               Strings.Add('');

               Strings.Add(' | '+MakeLength(Userstring(57),9)+' | '+
                                 MakeLength(Userstring(34),8)+' |');
               if Owner.ProjectSettings.ProjectUnits=fuImperial then Strings.Add(' |    [ft]   |   [ft2]  |')
                                                                else Strings.Add(' |    [m]    |    [m2]  |');
               Strings.Add(' |-----------+----------|');
               for I:=1 to N do
               begin
                  Position:=FData.Sac[I-1].X;
                  Strings.Add(' | '+Makelength(Position,3,9)+' | '+
                                    Makelength(Fdata.Sac[I-1].Y,3,8)+' | ');
               end;
               Strings.Add(' |-----------+----------|');
            end;
         end;

      end;
      AddFooter(Strings,Mode);
   end;
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
  ' : '+MakeLength(Owner.ProjectSettings.MidleFrame,-1,10)+#32+{FMidshipLocation,-1,10)+#32+}LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(MakeLength(Userstring(50),ls)+
  ' : '+MakeLength(Owner.ProjectSettings.ProjectWaterDensity,3,10)+#32+DensityStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(MakeLength(Userstring(51),ls)+
  ' : '+MakeLength(Owner.ProjectSettings.ProjectAppendageCoefficient,4,10));
end;

(*
procedure TFreeHydrostaticCalc.AddHeader(Strings:TStringlist);
begin
   Strings.Add(MakeLength(Userstring(39),21)+' : '+Owner.ProjectSettings.ProjectName);
   Strings.Add(MakeLength(Userstring(40),21)+' : '+Owner.ProjectSettings.ProjectDesigner);
   if Owner.ProjectSettings.ProjectFileCreatedBy<>'' then Strings.Add(MakeLength(Userstring(41),21)+' : '+Owner.ProjectSettings.ProjectFileCreatedBy);
   if Owner.ProjectSettings.ProjectComment<>'' then Strings.Add(MakeLength(Userstring(42),21)+' : '+Owner.ProjectSettings.ProjectComment);
   Strings.Add(MakeLength(Userstring(43),21)+' : '+Owner.Filename);
   Strings.Add('');
   Strings.Add(MakeLength(Userstring(44),21)+' : '+MakeLength(Owner.ProjectSettings.ProjectLength,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(45),21)+' : '+MakeLength(FData.ModelMax.X-FData.ModelMin.X,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(46),21)+' : '+MakeLength(Owner.ProjectSettings.ProjectBeam,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(47),21)+' : '+MakeLength(2*FData.ModelMax.Y,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(48),21)+' : '+MakeLength(Owner.ProjectSettings.Projectdraft,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(49),21)+' : '+MakeLength(Owner.ProjectSettings.MidleFrame,-1,10)+#32+LengthStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(50),21)+' : '+MakeLength(Owner.ProjectSettings.ProjectWaterDensity,3,10)+#32+DensityStr(Owner.ProjectSettings.ProjectUnits));
   Strings.Add(MakeLength(Userstring(51),21)+' : '+MakeLength(Owner.ProjectSettings.ProjectAppendageCoefficient,4,10));
end;{TFreeHydrostaticCalc.AddHeader}
*)
Procedure TFreeHydrostaticCalc.AddFooter(Strings:TStringlist;Mode:TFreeHydrostaticsMode);
begin
   Strings.Add(Userstring(52)+' (Z= '+FloatToStrF(FData.ModelMin.Z,ffFixed,7,3)+')');
   if FOwner.ProjectSettings.ProjectCoefficients=fcActualData then Strings.Add(Userstring(53))
                                                             else Strings.Add(Userstring(54));
   Strings.Add('');
   if Mode=fhMultipleCalculations then
   begin
      Strings.Add('Lwl    : '+Userstring(17));
      Strings.Add('Bwl    : '+Userstring(18));
      Strings.Add('Volume : '+Userstring(3));
      Strings.Add('Displ. : '+Userstring(4));
      Strings.Add('LCB    : '+Userstring(11)+', '+UserString(55));
      Strings.Add('VCB    : '+Userstring(12)+', '+UserString(56));
      Strings.Add('Cb     : '+Userstring(7));
      Strings.Add('Am     : '+Userstring(14));
      Strings.Add('Cm     : '+Userstring(15));
      Strings.Add('Aw     : '+Userstring(19));
      Strings.Add('Cw     : '+Userstring(20));
      Strings.Add('LCF    : '+Userstring(21));
      Strings.Add('CP     : '+Userstring(8));
      Strings.Add('S      : '+Userstring(10));
      Strings.Add('KMt    : '+Userstring(26));
      Strings.Add('KMl    : '+Userstring(27));
   end;
end;{TFreeHydrostaticCalc.AddFooter}

// Opens the hydrostatics dialog and calculates hydrostatic data for a range of inputdata

procedure TFreeEdit.Hydrostatics_Dialog; begin end;
(*
 var HydrostaticsForm: TFreeHydrostaticsForm; DP: double; MIN,MAX: T3DVector;
begin
   HydrostaticsForm:=TFreeHydrostaticsForm.Create(FreeShip);
   ShowTranslatedValues( HydrostaticsForm );
   with Hydrostaticsform do begin
      StartDraft:=FreeShip.ProjectSettings.Hydrostatics_Startdraft;
      EndDraft:=FreeShip.ProjectSettings.Hydrostatics_Enddraft;
      DraftStep:=FreeShip.ProjectSettings.Hydrostatics_DraftStep;
      Trim:=FreeShip.ProjectSettings.Hydrostatics_Trim;
      if StartDraft<EndDraft then begin StartDraft:=0; EndDraft:=0; end;
      if (StartDraft=0)
      and ((EndDraft=1.0) or (EndDraft=0.0)) then begin
        Ship.Extents( Min,Max );
        // EndDraft:=FreeShip.ProjectSettings.ProjectDraft;
        DraftStep:=AxisStep( (Max.Z-Min.Z)/3 );                    // EndDraft );
        StartDraft:=Round( Min.Z/DraftStep+0.5 )*DraftStep;
        EndDraft:=Round( Max.Z/DraftStep-1 )*DraftStep;
      end;
    end;
    if TFreeHydrostaticsForm( HydrostaticsForm ).Execute(FreeShip) then begin
    FreeShip.ProjectSettings.Hydrostatics_Startdraft:=HydrostaticsForm.StartDraft;
    FreeShip.ProjectSettings.Hydrostatics_Enddraft:=HydrostaticsForm.EndDraft;
    FreeShip.ProjectSettings.Hydrostatics_DraftStep:=HydrostaticsForm.DraftStep;
    FreeShip.ProjectSettings.Hydrostatics_Trim:=HydrostaticsForm.Trim;
  end;
end;
*)

procedure TFreeHydrostaticCalc.Clear;
begin
   Calculated:=False;
   FHydrostaticType:=fhShort;
   FHeelingAngle:=0.0;
   FTrim:=0.0;
   FDraft:=0.0;
   Fillchar(FData,SizeOf(FData),0);
   FMainframe.Clear;
   FCalculations:=[hcAll];
end;

constructor TFreeHydrostaticCalc.Create(Owner:TFreeShip);
begin
   Inherited create;
   FOwner:=Owner;
   FMainframe:=TFreeIntersection.Create(Owner);
   Owner.FHydrostaticCalculations.Add(self);
   Clear;
end;

destructor TFreeHydrostaticCalc.Destroy;
var Index : integer;
begin
   Clear;
   Index:=Owner.FHydrostaticCalculations.IndexOf(self);
   if Index<>-1 then Owner.FHydrostaticCalculations.Delete(Index);
   FMainframe.Destroy;
   Inherited Destroy;
end;
