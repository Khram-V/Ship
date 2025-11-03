
{
   TFreeHydrostaticCalc is an object class for hydrostatic calculations.
   Each calculation has it's own draft, trim and angle of heel.
   Multiple calculations can be stored and then send to a report.
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
   if not FCalculated then begin // FErrors:=[];
      Fillchar(FData,SizeOf(FData),0);
      MidFrame.Clear;
   end;
end;
procedure TFreeHydrostaticCalc.FSetHeelingAngle(Val:TFloatType);
    begin if Val<>FHeelingAngle then begin FheelingAngle:=val; Calculated:=False; end; end;
procedure TFreeHydrostaticCalc.FSetTrim(Val:TFloatType);
    begin if Val<>FTrim then begin FTrim:=val; Calculated:=False; end; end;
procedure TFreeHydrostaticCalc.FSetDraft(Val:TFloatType);
    begin if Val<>FDraft then begin FDraft:=val; Calculated:=False; end; end;
(*
procedure TFreeHydrostaticCalc.FSetErrors(val:TFreeHydrostaticErrors);
    begin {FErrors:=Val;} end; //#//#// Val:=[feNothingSubmerged]; без регистрации ошибок
procedure TFreeHydrostaticCalc.FSetHydrostaticType(val:TFreeHydrostaticType);
    begin if Val<>FHydrostaticType then begin
            FHydrostaticType:=val; Calculated:=False; end; // Calculated:=True;
end;
*)
// The actual calculation of the hydrostatics finds place in this procedure
procedure TFreeHydrostaticCalc.Calculate;
var I,J,K,L,First,Last,
    PointCapacity,             // Length of the dynamic point-array
    NoPoints: integer;         // number of points stored int the dynamic array
    CosHeel,SinHeel,CosTrim,SinTrim,Parameter,
    Side1,Side2,SubmergedLength,SubmergedWidth: TFloatType;
    Layer: TFREESubdivisionLayer;
    Face : TFreeSubdivisionControlFace;
    Child: TFreeSubdivisionFace;
    P1,P2,P,Keel,NewOrigin: T3DVector;
    TmpP2D: T2DCoordinate;
    FirstSubmPoint,FirstPoint,Submerged: Boolean;
    Points: array of T3DVector; // Array containing the coordinates of the underwaterpart of a face
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
                        //if not (feMakingWater in Errors) then begin
                        //   Errors:=Errors+[feMakingwater];
                           FData.Leak:=Child.Point[L-1].Coordinate;
                        //end;
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
                           //if not (feMakingWater in Errors) then begin
                             // Errors:=Errors+[feMakingwater];
                             FData.Leak:=Child.Point[L-1].Coordinate;
                           //end;
                        end;
                     end;
                     CheckSubmergedBody(P2,Side2);
                  end;
                  P1:=P2;
                  Side1:=Side2;
               end;                        // calculate volume aft of this face
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
         //Errors:=Errors+[feNothingSubmerged];
         FData.AbsoluteDraft:=0.0;
      end;
   end;
{  if feMakingWater in Errors then begin
      FData.Volume:=0.0;
      FData.CenterOfBuoyancy:=ZERO;
   end;
}  SubmergedLength:=Fdata.SubMax.X-FData.SubMin.X;
   SubmergedWidth:=FData.SubMax.Y-FData.SubMin.Y;
   FData.Displacement:=VolumeToDisplacement(FData.Volume,Owner.ProjectSettings.ProjectWaterDensity,Owner.ProjectSettings.ProjectAppendageCoefficient,Owner.ProjectSettings.ProjectUnits);
   FData.LengthWaterline:=FData.WlMax.X-FData.WlMin.X;
   FData.BeamWaterline:=FData.WlMax.Y-FData.WlMin.Y;
   if FData.Volume<>0 then begin // Translate center of buoyancy back to the original origin
      FData.CenterOfBuoyancy:=NewOrigin+FData.CenterOfBuoyancy/FData.Volume;
      FData.CenterOfBuoyancy:=RotatePoint( FData.CenterOfBuoyancy );
      if FData.LengthWaterline<>0 then FData.LCBPerc:=100*((FData.CenterOfBuoyancy.X-Owner.ProjectSettings.MidleFrame)/FData.LengthWaterline);
      // Apply appendage coeff.
      FData.Volume:=FData.Volume*Owner.ProjectSettings.ProjectAppendageCoefficient;
   end;
   if (FData.Volume>0) {and (Errors=[])}
   and ((hcMainframe in Calculations)
   or (hcAll in Calculations)) then begin     // Calculate mainframe properties
      MidFrame.IntersectionType:=fiStation;
      MidFrame.UseHydrostaticsSurfacesOnly:=True;
      MidFrame.FPlane.a:=1.0;
      MidFrame.FPlane.b:=0.0;
      MidFrame.FPlane.c:=0.0;
      MidFrame.FPlane.d:=-Owner.ProjectSettings.MidleFrame;
      MidFrame.CalculateArea(FData.WaterlinePlane,FData.MainframeArea,FData.MainframeCOG,TmpP2D);
      FData.MainframeCOG.Z:=FData.MainframeCOG.Z-FData.ModelMin.Z;
      if Owner.ProjectSettings.ProjectCoefficients=fcActualData then begin
         if SubmergedWidth*Draft<>0.0 then FData.MainframeCoeff:=FData.Mainframearea/(SubmergedWidth*Draft);
      end else if Owner.ProjectSettings.ProjectBeam*Draft<>0.0 then FData.MainframeCoeff:=FData.Mainframearea/(Owner.ProjectSettings.ProjectBeam*Draft);
   end;
   if (FData.Volume>0) {and (Errors=[])}
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
   if (hcSAC in Calculations) or (hcAll in Calculations) then begin // Calculate sectional areas
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
   Result.ShowData; //( fhSingleCalculation );
end;

procedure TFreeHydrostaticCalc.ShowData;   // (Mode: TFreeHydrostaticsMode);
var Strings: TStringList;
    Dialog: TFreeHydrostaticsDialog;
    I: integer;
begin
  if not Calculated then Calculate;
  Strings:=TStringList.Create;
  AddData( Strings ); //,Mode,';' );
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

///////////// Calculate Gravity Weight and CoG
procedure TFreeHydrostaticCalc.CalculateGravity;
var I,N: integer; Properties,Total: TLayerProperties;
begin
  if not Owner.Build then exit;
  N:=0;
  Total.Weight:=0;
  Total.SurfaceCenterOfGravity:=Zero;;
  for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].Count>0 then Inc(N);
  if N > 0 then
  for I:=1 to Owner.NumberOfLayers do
  if Owner.Layer[I-1].Count>0 then begin
    Properties:=Owner.Layer[I-1].SurfaceProperties;
    Properties.SurfaceCenterOfGravity.Z:=Properties.SurfaceCenterOfGravity.Z-FData.ModelMin.Z;
    if Owner.ProjectSettings.ProjectUnits=fuImperial
        then Properties.Weight:=Properties.Weight/(12*2240)
        else Properties.Weight:=Properties.Weight/1000;
    Total.SurfaceArea:=Total.SurfaceArea+Properties.SurfaceArea;
    Total.Weight:=Total.Weight+Properties.Weight;
    Total.SurfaceCenterOfGravity += Properties.Weight*Properties.SurfaceCenterOfGravity;
  end;
  if N>=1 then // if more then 1 layer is added,then show the properties of all layers together
  if Total.Weight<>0 then Total.SurfaceCenterOfGravity/=Total.Weight;
  FData.Weight_:=Total.Weight;                                     ////  Weight
  FData.CenterOfGravity_:=Total.SurfaceCenterOfGravity;
end;

// Add calculated data to a stringlist to either show in a report or save to disc

procedure TFreeHydrostaticCalc.AddData( Strings: TStringList ); // Mode: TFreeHydrostaticsMode; Separator: char );
Const S4='    '; Ls=37;
var
  Str: AnsiString; I,N,II: Integer;
  HydObject: TFreehydrostaticCalc;
  Properties,Total: TLayerProperties;
  Min,Max: T3DVector;                 {@}
  StartDraft,EndDraft,DraftStep,Trim, {@} Zmin,Value, A: TFloatType;
const Line_1='┌─────────────────────────┬─────────┬───────────┬──────────┬─────────┬─────────┬─────────┐';
const Line_2='├─────────────────────────┼─────────┼───────────┼──────────┼─────────┼─────────┼─────────┤';
const Line_3='└─────────────────────────┴─────────┴───────────┴──────────┴─────────┴─────────┴─────────┘';
begin
// m_ballast:=20; // масса балласта принята 2% от водоизмещения порожнем [кг/т]
// h_min:=0;
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
// Пересчет коэфФициентов полноты,если базовая линия проходит через линию киля
// if abs(FData.ModelMin.Z) > 0.001 then begin  !!!!
  FData.BlockCoefficient:=FData.BlockCoefficient*FData.AbsoluteDraft/(FData.AbsoluteDraft+FData.ModelMin.Z);
  FData.MainFrameCoeff := FData.MainFrameCoeff*FData.AbsoluteDraft/(FData.AbsoluteDraft+FData.ModelMin.Z);
  if FData.MainFrameCoeff > 0 then begin
    FData.PrismCoefficient:=FData.BlockCoefficient/FData.MainFrameCoeff;
    FData.VertPrismCoefficient:=FData.BlockCoefficient/FData.WaterplaneCoeff;
  end else begin
    Strings.Add(S4+MakeLength(Userstring(15),Ls) +
    ' :  '+MakeLength(FData.MainFrameCoeff,4,12)); //Strings.Add(S4+'ATTENTION!!! Cm<=0');
  end; // end;
  Strings.Add(S4+MakeLength(Userstring(7),Ls)+
  ' :  ' +MakeLength(FData.BlockCoefficient,4,12));
  if FData.MainFrameCoeff > 0.01 then
    Strings.Add(S4+MakeLength(Userstring(8),Ls)+' :  '+MakeLength(FData.PrismCoefficient,4,12));
  if FData.WaterplaneCoeff > 0.01 then
    Strings.Add(S4+MakeLength(Userstring(9),Ls)+' :  '+MakeLength(FData.VertPrismCoefficient,4,12));
  Strings.Add(S4+MakeLength(Userstring(10),Ls)+' :  '+MakeLength(FData.WettedSurface,-1,12)+' '+Areastr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(11),Ls)+' :  '+MakeLength(FData.CenterOfBuoyancy.X,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits)
                                              +' ='+MakeLength(FData.LCBPerc,3,6)+' %');
  Strings.Add(S4+MakeLength(Userstring(880),Ls)+' :  '+MakeLength(FData.CenterOfBuoyancy.Y,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(12),Ls)+' :  '+MakeLength(FData.CenterOfBuoyancy.Z+FData.ModelMin.Z,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  if FData.MainFrameCoeff>0.01 then
  begin Strings.Add(Userstring(13)+':'); // мидельшпангоут
    Strings.Add(S4+MakeLength(Userstring(49),Ls)+
    ' :  '+MakeLength(Owner.ProjectSettings.MidleFrame,4,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(14),Ls)+    // Площадь мидельшпангоута
    ' :  '+MakeLength(FData.MainFrameArea,-1,12)+' '+Areastr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(15),Ls)+
    ' :  '+MakeLength(FData.MainFrameCoeff,4,12));
  end;
  Strings.Add(Userstring(16)+':');               // харакетристики ватерлинии
  Strings.Add(S4+MakeLength(Userstring(17),Ls)+
  ' :  '+MakeLength(FData.LengthWaterline,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(18),Ls)+
  ' :  '+MakeLength(FData.BeamWaterline,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(19),Ls)+
  ' :  '+MakeLength(FData.WaterplaneArea,-1,12)+' '+Areastr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(20),Ls)+
  ' :  '+MakeLength(FData.WaterplaneCoeff,4,12));
  Strings.Add(S4+MakeLength(Userstring(21),Ls)+
  ' :  '+MakeLength(FData.WaterplaneCOG.X,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  Strings.Add(S4+MakeLength(Userstring(881),Ls) +
  ' :  '+MakeLength(FData.WaterplaneCOG.Y,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));

  Strings.Add(S4+MakeLength(Userstring(22),Ls)+
  ' :  '+MakeLength(FData.WaterplaneEntranceAngle,-1,12)+' °' ); //DegrStr(Owner.ProjectSettings.ProjectUnits));
  if FData.WaterplaneMomInertia.X < 0.01 then
  if FData.BeamWaterline>2*Owner.ProjectSettings.ProjectBeam then begin // Strings.Add('As for catamaran :');
    FData.WaterplaneMomInertia.X:=FData.WaterplaneArea*sqr((FData.BeamWaterline-Owner.ProjectSettings.ProjectBeam)/2.0);
    FData.WaterplaneMomInertia.Y:=sqr(FData.WaterplaneArea)/Owner.ProjectSettings.ProjectBeam*FData.LengthWaterline/16;
    FData.KMtransverse:=FData.WaterplaneMomInertia.X/FData.Volume+FData.CenterOfBuoyancy.Z;
    FData.KMlongitudinal:=FData.WaterplaneMomInertia.Y/FData.Volume+FData.CenterOfBuoyancy.Z;
  end else begin
    //       Strings.Add('Theoretical formula for monohull ships:');
    a:=FData.WaterplaneCoeff;
    FData.WaterplaneMomInertia.X :=((0.0613486*a+0.0298348)*a-0.0076467)
               *power(FData.BeamWaterline,3)*FData.LengthWaterline;
    FData.WaterplaneMomInertia.Y :=((0.0811652*a+0.0021749)*a-0.0060582)
               *power(FData.LengthWaterline,3)*FData.BeamWaterline;
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
    ' :  '+MakeLength(FData.LateralArea,-1,12)+' '+Areastr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(30),Ls)+
    ' :  '+MakeLength(FData.LateralCOG.X,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
    Strings.Add(S4+MakeLength(Userstring(31),Ls)+
    ' :  '+MakeLength(FData.LateralCOG.Z+FData.ModelMin.Z,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
  end;
(*
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
      ' :  '+MakeLength(h_min,-1,12)+' '+LengthStr(Owner.ProjectSettings.ProjectUnits));
      Strings.Add(S4+MakeLength(Userstring(1443),Ls) +
      ' :  '+MakeLength(h_min/L_max*100,-1,12)+' %Lmax');
      Strings.Add(Userstring(1442)+':');
      k_test:=(FData.BeamWaterline+h_min*2)/FData.LengthWaterline +
      Owner.ProjectSettings.Projectdraft*m_ballast/2;
      Strings.Add(S4+MakeLength(Userstring(1444),Ls)+
      ' :  '+MakeLength(k_test,-1,12)+' if ≥ 0,8 then OK');
    end;
  end;
*)
  Strings.Add('');                  // разборка по слоям с массами и нагрузками
  N:=0;
  for I:=1 to Owner.NumberOfLayers do if Owner.Layer[I-1].Count>0 then Inc(N);
  if N>0 then begin
    Strings.Add('');
    Fillchar(Total,SizeOf(Total),0);
    Strings.Add(Userstring(32)+':');
    Strings.Add('');
    Strings.Add( Line_1 );
    Strings.Add('│          '+Makelength(UserString(33),14) +
               ' │ '+Makelength(UserString(34),7)+
               ' │ '+Makelength(UserString(35),9)+
               ' │ '+Makelength(UserString(36),8)+
               ' │  CoG X  │  CoG Y  │  CoG Z  │' );
    Strings.Add('│ '+MakeLength( '',23 )+
               ' │  '+Makelength(AreaStr(Owner.ProjectSettings.ProjectUnits),6) +
               ' │    '+Makelength(LenMMStr(Owner.ProjectSettings.ProjectUnits),6)+
               ' │   '+Makelength(WeightStr(Owner.ProjectSettings.ProjectUnits),6)+
               ' │   '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),5)+
               ' │   '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),5)+
               ' │   '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),5)+' │');
    Strings.Add( Line_2 );
    for I:=1 to Owner.NumberOfLayers do
    if Owner.Layer[I-1].Count > 0 then begin Str:=Owner.Layer[I-1].Name;
      Properties:=Owner.Layer[I-1].SurfaceProperties;
      Properties.SurfaceCenterOfGravity.Z :=
      Properties.SurfaceCenterOfGravity.Z-FData.ModelMin.Z;
      if Owner.ProjectSettings.ProjectUnits=fuImperial
         then Properties.Weight:=Properties.Weight/(12*2240)
         else Properties.Weight:=Properties.Weight/1000;
      Strings.Add
      ( '│ '+MakeLength( Str,23 ) +
       ' │ '+Makelength(Properties.SurfaceArea,-1,7) +
       ' │ '+MakeLength(Owner.Layer[I-1].Thickness,3,9) +
       ' │ '+Makelength(Properties.Weight,3,8)+
       ' │ '+MakeLength(Properties.SurfaceCenterOfGravity.X,3,7)+
       ' │ '+MakeLength(Properties.SurfaceCenterOfGravity.Y,3,7)+
       ' │ '+MakeLength(Properties.SurfaceCenterOfGravity.Z+FData.ModelMin.Z,3,7)+
       ' │');
      Total.SurfaceArea:=Total.SurfaceArea+Properties.SurfaceArea;
      Total.Weight:=Total.Weight+Properties.Weight;
      Total.SurfaceCenterOfGravity.X:=Total.SurfaceCenterOfGravity.X+Properties.Weight*Properties.SurfaceCenterOfGravity.X;
      Total.SurfaceCenterOfGravity.Y:=Total.SurfaceCenterOfGravity.Y+Properties.Weight*Properties.SurfaceCenterOfGravity.Y;
      Total.SurfaceCenterOfGravity.Z:=Total.SurfaceCenterOfGravity.Z+Properties.Weight*Properties.SurfaceCenterOfGravity.Z;
    end;
    Strings.Add( Line_3 );
    if Total.Weight<>0 then begin
      Total.SurfaceCenterOfGravity.X := Total.SurfaceCenterOfGravity.X/Total.Weight;
      Total.SurfaceCenterOfGravity.Y := Total.SurfaceCenterOfGravity.Y/Total.Weight;
      Total.SurfaceCenterOfGravity.Z := Total.SurfaceCenterOfGravity.Z/Total.Weight+FData.ModelMin.Z;
    end;
    if N>1 then begin // if more then 1 layer is added,then show the properties of all layers together
      Strings.Add('  '+MakeLength(UserString(37),24)+'   '+Makelength(Total.SurfaceArea,-1,6)+
      MakeLength('',15)+Makelength(Total.Weight,3,8)+'   ' +
      MakeLength(Total.SurfaceCenterOfGravity.X,3,7)+'   ' +
      MakeLength(Total.SurfaceCenterOfGravity.Y,3,7)+'   ' +
      MakeLength(Total.SurfaceCenterOfGravity.Z,3,7));
    end;
  end;
  N:=Length(FData.SAC);                            // Add sectional Area data
  if N > 0 then begin
    Strings.Add('');
    Strings.Add(UserString(38)+':');
    Strings.Add('');
    Strings.Add(' ┌───────────┬──────────┐');
    Strings.Add(' │ '+MakeLength(Userstring(57),9)+' │ '+ MakeLength(Userstring(34),8)+' │');
    Strings.Add(' │    '+MakeLength(LengthStr(Owner.ProjectSettings.ProjectUnits),6)+' │   '+MakeLength(AreaStr(Owner.ProjectSettings.ProjectUnits),6)+' │');
    Strings.Add(' ├───────────┼──────────┤');
    Strings.Add(' │ '+Makelength(FData.SubMin.X,3,9)+' │ '+Makelength(Fdata.Sac[0].Y,3,8)+' │ ');
    II:=1;
    if (FData.SubMin.X<0) or (FData.SubMin.X>Fdata.Sac[0].X) then II:=2;
    for I:=II to N-1 do begin
      Strings.Add(' │ '+Makelength(FData.Sac[I-1].X,3,9)
                 +' │ '+Makelength(Fdata.Sac[I-1].Y,3,8)+' │ ');
    end;
    Strings.Add(' │ '+Makelength(FData.SubMax.X,3,9)+' │ '+Makelength(0.,3,8)+' │ ');
    Strings.Add(' └───────────┴──────────┘');
  end;

  if (FData.ModelMin.Z<>0.0)
  and Owner.ProjectSettings.EnableModelAutoMove then Face_MoveZAuto;

  StartDraft:=Owner.ProjectSettings.Hydrostatics_Startdraft;
  EndDraft:=Owner.ProjectSettings.Hydrostatics_Enddraft;
  DraftStep:=Owner.ProjectSettings.Hydrostatics_DraftStep;
  Trim:=Owner.ProjectSettings.Hydrostatics_Trim;
  if StartDraft<EndDraft then begin StartDraft:=0; EndDraft:=0; end;
  if (StartDraft=0)
  and ((EndDraft=1.0) or (EndDraft=0.0)) then begin
    Owner.Extents( Min,Max );
                          // EndDraft:=FreeShip.ProjectSettings.ProjectDraft;
    DraftStep:=AxisStep( (Max.Z-Min.Z)/3 );                    // EndDraft );
    StartDraft:=Round( Min.Z/DraftStep+0.5 )*DraftStep;
    EndDraft:=Round( Max.Z/DraftStep-1 )*DraftStep;
  end;
  Owner.ProjectSettings.Hydrostatics_Startdraft:=StartDraft;
  Owner.ProjectSettings.Hydrostatics_Enddraft:=EndDraft;
  Owner.ProjectSettings.Hydrostatics_DraftStep:=DraftStep;
  Owner.ProjectSettings.Hydrostatics_Trim:=Trim;
  Strings.add('');
  Strings.add(UserString(1677)); //Кривые элементов теоретического чертежа
  Strings.add('');
  Strings.Add('T   : '+Userstring(48));   // Draft проектная осадка
  Strings.Add('δd  : '+Userstring(1674)); // Trim дифферент (δd=dн-dк)
  Strings.Add('Lwl : '+Userstring(17));   // Длина по КВЛ
  Strings.Add('Bwl : '+Userstring(18));   // Ширина по КВЛ
  Strings.Add('V   : '+Userstring(3));    // Volume
  Strings.Add('Δ   : '+Userstring(4));    // Displacement
  Strings.Add('Xc  : '+Userstring(11)+' '+UserString(55)); // LCB
  Strings.Add('Zc  : '+Userstring(12)+' '+UserString(56)); // VCB
  Strings.Add('δ   : '+Userstring(7));    // Cb
  Strings.Add('Sм  : '+Userstring(14));   // Am
  Strings.Add('β   : '+Userstring(15));   // Cm
  Strings.Add('S   : '+Userstring(19));   // Aw
  Strings.Add('α   : '+Userstring(20));   // Cw
  Strings.Add('Xf  : '+Userstring(21));   // LCF
  Strings.Add('φ   : '+Userstring(8));    // Cp
  Strings.Add('W   : '+Userstring(10));   // S
  Strings.Add('Zm  : '+Userstring(26));   // KMt
  Strings.Add('ZM  : '+Userstring(27));   // KMl
  Strings.Add( '' );
  Strings.Add('┌─────┬─────┬──────┬─────┬───────┬───────┬──────┬─────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┐');
  Strings.Add('│  T  │ δd  │ Lwl  │ Bwl │  V    │  Δ    │  Xc  │ Zc  │  δ   │  Sm  │  β   │  S   │  α   │  Xf  │  φ   │  W   │  Zm  │  ZM  │');
  Strings.Add('│  м  │  м  │  м   │  м  │  м³   │  т    │  м   │ м   │  —   │  м²  │  —   │  м²  │  —   │  м   │  —   │  м²  │  м   │  м   │');
  Strings.Add('├─────┼─────┼──────┼─────┼───────┼───────┼──────┼─────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤');
  HydObject:=TFreeHydrostaticCalc.Create( Owner );
  HydObject.Clear;
  HydObject.HeelingAngle:=0.0;
  HydObject.Trim:=Trim;
  HydObject.Draft:=0;              //-Ship.ProjectSettings.ProjectDraft; //0;
  HydObject.Calculate;             // ...,если основная линия проходит по килю
  Zmin:=HydObject.Data.ModelMin.Z; //+Ship.ProjectSettings.ProjectDraft; // =добавка(++)
  I:=2;
  Value:=StartDraft;
  while Value<=EndDraft do         //+DraftStep) or (abs(Value-EndDraft)<1e-3) do begin
  with HydObject do begin
    Clear;
    HeelingAngle:=0.0;
    Trim:=Trim;                  // Zmin:=HydObject.Data.ModelMin.Z+StartDraft;
    if Value<=EndDraft then Draft:=Value-Zmin
                       else Draft:=EndDraft-Zmin;
    Calculate;                                // Пересчет коэфФициентов полноты
    Strings.Add
    ('│'+Makelength(Draft+Zmin,          2,5 )
    +'│'+Makelength(Trim,                2,5 )
    +'│'+Makelength(Data.LengthWaterline,2,6 )
    +'│'+Makelength(Data.BeamWaterline,  2,5 )
    +'│'+Makelength(Data.Volume,         1,7 )    //NumberOfDecimals(HydObject.Data.Volume),7)
    +'│'+Makelength(Data.Displacement,   1,7 )    //NumberOfDecimals(HydObject.Data.Displacement),7)
    +'│'+Makelength(Data.CenterOfBuoyancy.X,2,6 )
    +'│'+Makelength(Data.CenterOfBuoyancy.Z+Zmin,2,5 )
    +'│'+Makelength(Data.BlockCoefficient,       3,6 )
    +'│'+Makelength(Data.MainFrameArea,          2,6 )
    +'│'+Makelength(Data.MainFrameCoeff,         3,6 )
    +'│'+Makelength(Data.Waterplanearea,1,6 )     //NumberOfDecimals(HydObject.Data.Waterplanearea),6)
    +'│'+Makelength(Data.WaterplaneCoeff,3,6)
    +'│'+Makelength(Data.WaterplaneCOG.X,2,6)
    +'│'+Makelength(Data.PrismCoefficient,3,6)
    +'│'+Makelength(Data.WettedSurface,1,6 )      //NumberOfDecimals(HydObject.Data.WettedSurface),6)
    +'│'+Makelength(Data.KMtransverse+Zmin,2,6)
    +'│'+Makelength(Data.KMlongitudinal+Zmin,1,6) //NumberOfDecimals(HydObject.Data.KMlongitudinal),6)
    +'│'
    );   Value:=Value+DraftStep;
  end;   //  ('│     │     │      │     │       │       │      │     │      │      │      │      │      │      │      │      │      │      │');
  Strings.Add('└─────┴─────┴──────┴─────┴───────┴───────┴──────┴─────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┘');
  Strings.add('');
  Strings.Add( '...(максимум возможной осадки: '
    +FloattoDec( Owner.Surface.Max.Z,2 )+' '
    +LengthStr(Owner.ProjectSettings.ProjectUnits )+')');
  AddFooter( Strings );
  FreeAndNil(HydObject);
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

Procedure TFreeHydrostaticCalc.AddFooter(Strings:TStringlist); //;Mode:TFreeHydrostaticsMode);
begin
  Strings.Add(Userstring(52));
  if FOwner.ProjectSettings.ProjectCoefficients=fcActualData
     then Strings.Add(Userstring(53))
     else Strings.Add(Userstring(54));               // Проверка наличия бульба
end;

procedure TFreeHydrostaticCalc.Face_MoveZAuto;   /// ...нечто неопределённое
var
  I,J,Nlocked: integer;
  Points: TFasterList; //TFreeSubdivisionControlPoint;
  PrevCursor: TCursor;
  Point: TFreeSubdivisionControlPoint;
  Proceed: boolean;
  P,Translate: T3DVector;
  Marker: TFreeMarker;
begin
  for I:=1 to Owner.NumberOfLayers do
    if Owner.Layer[I-1].{Surface}Visible then
      for J:=1 to Owner.Layer[I-1].Count do
        Owner.Layer[I-1].Items[J-1].Selected:=True;
  for I:=1 to Owner.Surface.NumberOfControlPoints do
    if Owner.Surface.ControlPoint[I-1].Visible then
       Owner.Surface.ControlPoint[I-1].Selected:=True;
  for I:=1 to Owner.NumberofMarkers do
    if Owner.Marker[I-1].Visible then
       Owner.Marker[I-1].Selected:=True;
  Owner.Redraw;

  Points:=TFasterList.Create;            //TFreeSubdivisionControlPoint.Create;
  if Owner.ActiveControlPoint<>nil then
     Points.Add(Owner.ActiveControlPoint);
  Owner.Surface.ExtractPointsFromSelection(Points,NLocked);
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
  if Points.Count=Owner.Surface.NumberOfControlPoints then begin
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
  Owner.Build:=False;
  Owner.Redraw;                                    // Refresh controlpoint data
  if Points.IndexOf(Owner.ActiveControlPoint)<>-1 then
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

procedure TFreeHydrostaticCalc.Clear;
begin
   Calculated:=False;
// FHydrostaticType:=fhShort;
   FHeelingAngle:=0.0;
   FTrim:=0.0;
   FDraft:=0.0;
   Fillchar(FData,SizeOf(FData),0);
   MidFrame.Clear;
   FCalculations:=[hcAll];
end;

constructor TFreeHydrostaticCalc.Create(Owner:TFreeShip);
begin
   Inherited create;
   FOwner:=Owner;
   MidFrame:=TFreeIntersection.Create(Owner);
   Owner.FHydrostaticCalculations.Add(self);
   Clear;
end;

destructor TFreeHydrostaticCalc.Destroy;
var Index : integer;
begin
   Clear;
   Index:=Owner.FHydrostaticCalculations.IndexOf(self);
   if Index<>-1 then Owner.FHydrostaticCalculations.Delete(Index);
   MidFrame.Destroy;
   Inherited Destroy;
end;

