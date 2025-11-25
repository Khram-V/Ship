
{
  TFreeProjectSettings
   Container class for project settings for each project
    such as mainparticulars,waterdensity etc.
}
procedure TFreeProjectSettings.FSetFreeHydrostaticCoefficients
          ( val: TFreeHydrostaticCoeff );
var I: integer;
begin
  if val<>FFreeHydrostaticCoefficients then begin
    FFreeHydrostaticCoefficients:=val;
    Ship.FileChanged:=True;
    for I:=0 to Ship.NumberOfHydrostaticCalculations-1 do
      Ship.HydrostaticCalculation[I].Calculated:=False;
  end;
end;
procedure TFreeProjectSettings.FSetDisableModelCheck(Val: boolean);
    begin if val<>FDisableModelCheck then begin
          FDisableModelCheck:=Val; Ship.FileChanged:=True; end;
    end;
function TFreeProjectSettings.FGetMidleFrame: Real;
   begin if FUseMidleFrame
            then Result:=(Ship.Surface.Max.X+Ship.Surface.Min.X)/2
            else Result:=FMidleFrame;
   end;
procedure TFreeProjectSettings.FSetProjectAppendageCoefficient(Val: Real);
    begin if abs(Val-FProjectAppendageCoefficient)>1e-6 then begin
          FProjectAppendageCoefficient:=Val; Ship.FileChanged:=True; end;
    end;
procedure TFreeProjectSettings.FSetProjectBeam( Val: Real );
    begin if Val<0.001 then Val:=1; FProjectBeam:=Val; Ship.FileChanged:=True;
    end;
procedure TFreeProjectSettings.FSetProjectDraft(Val: Real);
    begin if Val<0.001 then Val:=1; FProjectDraft:=Val; Ship.FileChanged:=True;
    end;
procedure TFreeProjectSettings.FSetProjectLength(Val: Real);
    begin if Val<0.001 then Val:=1; FProjectLength:=Val; Ship.FileChanged:=True;
    end;
procedure TFreeProjectSettings.FSetMidleFrame(Mid: Real);
    begin if Mid<>FMidleFrame then begin FMidleFrame:=Mid; Ship.FileChanged:=True;
    end;
end;
procedure TFreeProjectSettings.FSetProjectWaterDensity(Val: Real);
    begin if abs( Val-FProjectWaterDensity )>1e-6 then
          begin FProjectWaterDensity:=Val; Ship.FileChanged:=True; end;
    end;
procedure TFreeProjectSettings.FSetProjectWaterTemper(Val: Real);
    begin if abs( Val-FProjectWaterTemper )>1e-6 then
          begin FProjectWaterTemper:=Val; Ship.FileChanged:=True; end;
    end;
procedure TFreeProjectSettings.FSetSavePreview(val: boolean);
    begin if val<>FSavePreview then
          begin FSavePreview:=Val; Ship.FileChanged:=True; end;
    end;
procedure TFreeProjectSettings.FSetStartDraft(Val: Real);
    begin if Val<>FStartDraft then
          begin FStartdraft:=Val; Ship.FileChanged:=True; end;
    end;
procedure TFreeProjectSettings.FSetTrim(Val: Real);
    begin if Val<>FTrim then begin FTrim:=Val; Ship.FileChanged:=True; end;
    end;
procedure TFreeProjectSettings.FSetEndDraft(Val: Real);
    begin if Val<>FEndDraft then begin FEnddraft:=Val; Ship.FileChanged:=True; end;
    end;
procedure TFreeProjectSettings.FSetDraftStep(Val: Real);
    begin if Val<>FDraftStep then begin FDraftStep:=Val; Ship.FileChanged:=True; end;
    end;
procedure TFreeProjectSettings.FSetUseMidleFrame(Mid: boolean);
    begin if Mid<>FUseMidleFrame then
          begin FUseMidleFrame:=Mid; Ship.FileChanged:=True; end;
    end;
procedure TFreeProjectSettings.FSetProjectShadeUnderwaterShip(Val: boolean);
    begin if val<>FProjectShadeUnderwaterShip then
          begin FProjectShadeUnderwaterShip:=Val; Ship.FileChanged:=True; end;
    end;
procedure TFreeProjectSettings.FSetProjectSimplifyIntersections(val: boolean);
var I: integer;
begin
   if val<>FProjectSimplifyIntersections then begin
      FProjectSimplifyIntersections:=val;
      for I:=1 to Ship.NumberofStations do Ship.Station[I-1].Built:=False;
      for I:=1 to Ship.NumberofButtocks do Ship.Buttock[I-1].Built:=False;
      for I:=1 to Ship.NumberofWaterlines do Ship.Waterline[I-1].Built:=False;
      for I:=1 to Ship.NumberofDiagonals do Ship.Diagonal[I-1].Built:=False;
      for I:=1 to Ship.NumberOfHydrostaticCalculations do
                  Ship.HydrostaticCalculation[I-1].Calculated:=False;
   end;
end;
procedure TFreeProjectSettings.FSetProjectUnits(Val: TFreeUnitType);
var
  UnitConversionFactor,WeightFactor,ThicknessFactor: Real;
  Layer: TFreeSubdivisionLayer;
  ScaleVector: Vector;
  I: integer;
begin
  if Val<>FProjectUnits then begin
    FProjectUnits:=val;
    if FProjectUnits=fuImperial then begin // Scale from metric to imperial units
      UnitConversionFactor:=1/0.3048;
      WeightFactor:=WeightConversionFactor;
      ThicknessFactor:=1/25.4;
    end else begin                           // scale from imperial to metric units
      UnitConversionFactor:=0.3048;
      WeightFactor:=1/WeightConversionFactor;
      ThicknessFactor:=25.4;
    end;
    FProjectWaterDensity:=FProjectWaterDensity*WeightFactor;
    for I:=1 to Ship.Surface.NumberOfLayers do begin
      Layer:=Ship.Surface.Layer[I-1];
      Layer.MaterialDensity:=Layer.MaterialDensity*WeightFactor;
      Layer.Thickness:=Layer.Thickness*ThicknessFactor;
    end;
    ScaleVector.X:=UnitConversionFactor;
    ScaleVector.Y:=UnitConversionFactor;
    ScaleVector.Z:=UnitConversionFactor;
    Ship.Edit.Model_Scale(Scalevector,True,True);       // Scale and redraw
  end;
end;

procedure TFreeProjectSettings.Clear;
begin
  FProjectName:='';
  FProjectDesigner:='';
  FProjectComment:='';
  FProjectFileCreatedBy:='';
  FProjectLength:=1.0;
  FProjectBeam:=1.0;
  FProjectDraft:=1.0;
  FProjectWaterDensity:=1.025;     // 1025 kg/m3 for seawater
  FProjectWaterTemper:=15.;
  FProjectAppendageCoefficient:=1.0;
// Default 1.0,typical values for ships to cpmpensate for appendices and shellplate=1.0005;
// FMainparticularsHasBeenset:=False;
  FProjectShadeUnderwaterShip:=True;
// Shades the underwaterpart of the hull in a different color
  ProjectUnderWaterColor:=Ship.Preferences.UnderWaterColor;
  ProjectUnderWaterColorAlpha:=Ship.Preferences.UnderWaterColorAlpha;
  FProjectUnits:=TFreeUnitType( 0 ); // Default is metric units
  FUseMidleFrame:=True;
  FMidleFrame:=0.0;
  FDisableModelCheck:=True;
  FSavePreview:=False;
  FFreeHydrostaticCoefficients:=fcActualData;
  FProjectSimplifyIntersections:=False;
  // hydrostatics settings
  FStartDraft:=0.0;
  FEndDraft:=1.0;
  FDraftStep:=0.1;
  FTrim:=0.0;
  // crosscurves settings
  FNoDisplacements:=0;
  Setlength(FDisplacements,FNoDisplacements);
  FMinimumDisplacement:=0.0;
  FMaximumDisplacement:=1.0;
  FDisplIncrement:=0.1;
  FUseDisplIncrements:=True;
  FNoAngles:=19;
  SetLength( FAngles,FNoAngles );
  FAngles[0]:=0.0;
  FAngles[1]:=2.0;
  FAngles[2]:=5.0;
  FAngles[3]:=10.0;
  FAngles[4]:=15.0;
  FAngles[5]:=20.0;
  FAngles[6]:=30.0;
  FAngles[7]:=40.0;
  FAngles[8]:=50.0;
  FAngles[9]:=60.0;
  FAngles[10]:=70.0;
  FAngles[11]:=80.0;
  FAngles[12]:=90.0;
  FAngles[13]:=100.0;
  FAngles[14]:=110.0;
  FAngles[15]:=120.0;
  FAngles[16]:=130.0;
  FAngles[17]:=140.0;
  FAngles[18]:=150.0;
  FNoStabTrims:=1;
  SetLength(FStabTrims,FNoStabTrims);
  FStabTrims[0]:=0.0;
  FFreeTrim:=True;
  FVCG:=1.0;
end;

constructor TFreeProjectSettings.Create(Owner: TFreeShip);
begin inherited Create; Ship:=Owner; Clear;
end;

// User input of mainparticulars and project setting
procedure TFreeProjectSettings.Edit;
var
  Dialog: TFreeProjectSettingsDialog;
begin
  ProjectPrecision:=Ship.Precision;
  Dialog:=TFreeProjectSettingsDialog.Create( Ship );
  Dialog.Edit1.Text:=ProjectName;           //  'Project name'
  Dialog.Edit7.Text:=ProjectDesigner;       //  'Designer'
  Dialog.Edit9.Text:=ProjectComment;        //  'Comment'
  Dialog.Edit10.Text:=ProjectFileCreatedBy; //  'File created by'
  Dialog.UnitBox.ItemIndex:=Ord(ProjectUnits);
  Dialog.PrecisionBox.ItemIndex:=Ord(ProjectPrecision);
  Dialog.Length:=ProjectLength;
  Dialog.Beam:=ProjectBeam;
  Dialog.Draft:=ProjectDraft;
  Dialog.Density:=ProjectWaterDensity;
  Dialog.Temper:=ProjectWaterTemper;
  Dialog.Coefficient:=ProjectAppendageCoefficient;
  Dialog.cbShadeUnderwater.Checked:=ProjectShadeUnderwaterShip;
  Dialog.Panel4.Color:=ProjectUnderWaterColor;
  Dialog.seUnderwaterOpacity.Value:=ProjectUnderWaterColorAlpha*100 div 255;
  Dialog.MidleFrame:=MidleFrame;
  Dialog.CheckBox2.Checked:=UseMidleFrame;
  Dialog.CheckBox3.Checked:=DisableModelCheck;
  Dialog.cbSavePreviewImage.Checked:=SavePreview;
  Dialog.ComboBox1.ItemIndex:=Ord(ProjectCoefficients);
  Dialog.CheckBox5.Checked:=Ship.Visibility.FShowHydrostDisplacement;
  Dialog.CheckBox6.Checked:=Ship.Visibility.FShowHydrostSectionalAreas;
  Dialog.CheckBox7.Checked:=Ship.Visibility.FShowHydrostMetacentricHeight;
  Dialog.CheckBox8.Checked:=Ship.Visibility.FShowHydrostLCF;
  Dialog.CheckBox9.Checked:=Ship.Visibility.FShowHydrostLateralArea;
  Dialog.cbSimplifyIntersections.Checked:=ProjectSimplifyIntersections;
  ShowTranslatedValues(Dialog);
  if Dialog.Execute then begin
    Ship.Edit.CreateUndoObject( 'Project settings ',True );
    FProjectName         :=BlankOff( Dialog.Edit1.Text ); //ProjectName.Trim;
    FProjectDesigner     :=BlankOff( Dialog.Edit7.Text ); //ProjectDesigner.Trim;
    FProjectComment      :=BlankOff( Dialog.Edit9.Text ); //ProjectComment.Trim;
    FProjectFileCreatedBy:=BlankOff( Dialog.Edit10.Text); //ProjectFileCreatedBy.Trim;
    ProjectUnits:=TFreeUnitType(Dialog.UnitBox.ItemIndex);
    ProjectPrecision:=TFreePrecisionType(Dialog.PrecisionBox.ItemIndex);
    ProjectLength:=Dialog.Length;
    ProjectBeam:=Dialog.Beam;
    ProjectDraft:=Dialog.Draft;
    ProjectWaterDensity:=Dialog.Density;
    ProjectWaterTemper:=Dialog.Temper;
    ProjectAppendageCoefficient:=Dialog.Coefficient;
    ProjectShadeUnderwaterShip:=Dialog.cbShadeUnderwater.Checked;
    ProjectUnderWaterColor:=Dialog.Panel4.Color;
    ProjectUnderWaterColorAlpha:=Dialog.seUnderwaterOpacity.Value*255 div 100;
    MidleFrame:=Dialog.MidleFrame;
    UseMidleFrame:=Dialog.CheckBox2.Checked;
    DisableModelCheck:=Dialog.CheckBox3.Checked;
    SavePreview:=Dialog.cbSavePreviewImage.Checked;
    ProjectCoefficients:=TFreeHydrostaticCoeff(Dialog.ComboBox1.ItemIndex);
    Ship.Visibility.FShowHydrostDisplacement:=Dialog.CheckBox5.Checked;
    Ship.Visibility.FShowHydrostSectionalAreas:=Dialog.CheckBox6.Checked;
    Ship.Visibility.FShowHydrostMetacentricHeight:=Dialog.CheckBox7.Checked;
    Ship.Visibility.FShowHydrostLCF:=Dialog.CheckBox8.Checked;
    Ship.Visibility.FShowHydrostLateralArea:=Dialog.CheckBox9.Checked;
    ProjectSimplifyIntersections:=Dialog.cbSimplifyIntersections.Checked;
    Ship.FileChanged:=True;
    Ship.Precision:=ProjectPrecision; // TODO: save and load precision
    Ship.Redraw;
  end;
  FreeAndNil(Dialog);
end;

procedure TFreeProjectSettings.LoadBinary(Source: TFreeFilebuffer; Image: TJPegImage);
var
  I:integer; Jpg:TJPEGImage;                                // ### отменено
  FEnableBonjeanSAC,FEnableModelAutoMove,MainparticularsHasBeenset: boolean;
begin
  Clear;
  Source.LoadString(FProjectName);
  Source.LoadString(FProjectDesigner);
  Source.LoadTFloatType(FProjectlength);
  Source.LoadTFloatType(FProjectBeam);
  Source.LoadTFloatType(FProjectDraft);
  Source.LoadBoolean(MainparticularsHasBeenset);
  Source.LoadTFloatType(FProjectWaterDensity);
{ Source.LoadTFloatType(FProjectWaterTemper); }
  Source.LoadTFloatType(FProjectAppendageCoefficient);
  Source.LoadBoolean(FProjectShadeUnderwaterShip);
{ Source.LoadTColor( ProjectUnderWaterColor,ProjectUnderWaterColorAlpha ); }
  Source.LoadInteger( ProjectUnderWaterColor );
         ProjectUnderWaterColorAlpha:=255-Byte(ProjectUnderWaterColor shr 24);
         ProjectUnderWaterColor:=ProjectUnderWaterColor and $FFFFFF;
  Source.LoadInteger(I);
{ if Ship.FileVersion >= fv160 then begin ~~ как бы юолжно быть так, ан нет...}
     FProjectUnits:=TFreeUnitType(I);
     Source.LoadBoolean(FUseMidleFrame);
     Source.LoadTFloatType(FMidleFrame);
{ if Ship.FileVersion >= fv165 then } Source.LoadBoolean(FDisableModelCheck);
{ end; }
  Source.LoadString( FProjectComment );
  Source.LoadString( FProjectFileCreatedBy );
  FSavePreview:=false;
                            FProjectDesigner:=BlankOff(FProjectDesigner); //???
                                FProjectName:=BlankOff(FProjectName);
                             FProjectComment:=BlankOff(FProjectComment);
                       FProjectFileCreatedBy:=BlankOff(FProjectFileCreatedBy);
  if Ship.FileVersion >= fv210 then begin
    Source.LoadInteger( I );
    FFreeHydrostaticCoefficients:=TFreeHydrostaticCoeff(I);
    Source.LoadBoolean( FSavePreview );
    if FSavePreview then begin
      Jpg:=TJPEGImage.Create;
      Source.LoadTJPEGImage( Jpg );
      if Image<>nil then Image.Assign(Jpg);
      FreeAndNil(Jpg);
    end;
    if Ship.FileVersion >= fv230 then
      Source.LoadBoolean(FProjectSimplifyIntersections);
    if Ship.Fileversion >= fv250 then begin
      // save settings for hydrostatics and crosscurves hydrostatics
      Source.LoadTFloatType(FStartdraft);
      Source.LoadTFloatType(FEndDraft);
      Source.LoadTFloatType(FDraftStep);
      Source.LoadTFloatType(FTrim);                     // Crosscurves settings
      Source.LoadInteger(FNoDisplacements);
      Setlength(FDisplacements,FNoDisplacements);
      for I:=0 to FNoDisplacements-1 do Source.LoadTFloatType(FDisplacements[I]);
      Source.LoadTFloatType(FMinimumDisplacement);
      Source.LoadTFloatType(FMaximumDisplacement);
      Source.LoadTFloatType(FDisplIncrement);
      Source.LoadBoolean(FUseDisplIncrements);
      Source.LoadInteger(FNoAngles);
      Setlength(FAngles,FNoAngles);
      for I:=0 to FNoAngles-1 do Source.LoadTFloatType(FAngles[I]);
      Source.LoadInteger(FNoStabTrims);
      Setlength(FStabTrims,FNoStabTrims);
      for I:=0 to FNoStabTrims-1 do Source.LoadTFloatType(FStabTrims[I]);
      Source.LoadBoolean(FFreeTrim);
      Source.LoadTFloatType(FVCG);
    end;
    if Ship.Fileversion >= fv317 then Source.LoadBoolean(FEnableModelAutoMove);
    if Ship.Fileversion >= fv332 then Source.LoadBoolean(FEnableBonjeanSAC);
    if Ship.Fileversion >= fv500 then
    begin Source.LoadInteger( I ); ProjectUnderWaterColorAlpha:=byte(I); end;
  end;
end;

procedure TFreeProjectSettings.SaveBinary( Destination: TFreeFileBuffer );
var Jpg: TJPegImage;
begin
  if Ship.FileVersion>=fv120 then begin
    Destination.Add( BlankOff(ProjectName) );
    Destination.Add( BlankOff(ProjectDesigner) );
    Destination.Add( FProjectlength );
    Destination.Add( FProjectBeam );
    Destination.Add( FProjectDraft );
    Destination.Add( true );    // Destination.Add(FMainparticularsHasBeenset);
    Destination.Add( FProjectWaterDensity );
 // Destination.Add( FProjectWaterTemper );
    Destination.Add( FProjectAppendageCoefficient );
    Destination.Add( FProjectShadeUnderwaterShip );
//  Destination.Add( ProjectUnderWaterColor,ProjectUnderWaterColorAlpha );
    Destination.Add( (ProjectUnderWaterColor and $FFFFFF)
                  or (TColor(255-ProjectUnderWaterColorAlpha) shl 24) );
    Destination.Add( Ord(FProjectUnits) );
  { if Ship.FileVersion>=fv160 then begin }
       Destination.Add(FUseMidleFrame);
       Destination.Add(FMidleFrame);
  {    if Ship.FileVersion>=fv165 then } Destination.Add( DisableModelCheck );
  { end; }
    Destination.Add( BlankOff(FProjectComment) );
    Destination.Add( BlankOff(FProjectFileCreatedBy) );
    if Ship.FileVersion>=fv210 then begin
      Destination.Add( Ord( ProjectCoefficients ) );
      if FSavePreview then begin Jpg:=Ship.FGetPreview;
        FSavePreview:=Jpg<>nil; Destination.Add( FSavePreview );
        if FSavePreview then begin Destination.Add( Jpg ); Jpg.Destroy end
      end else Destination.Add( false );
      if Ship.FileVersion>=fv230 then Destination.Add(FProjectSimplifyIntersections);
      if Ship.Fileversion>=fv250 then begin // save settings for hydrostatics
        Destination.Add( FStartdraft );
        Destination.Add( FEndDraft );
        Destination.Add( FDraftStep );
        Destination.Add( FTrim );                       // Crosscurves settings
        Destination.Add( Integer( 0 ) );                //  FNoDisplacements );
//      for I:=0 to FNoDisplacements-1 do Destination.Add( FDisplacements[I] );
        Destination.Add( FMinimumDisplacement );
        Destination.Add( FMaximumDisplacement );
        Destination.Add( FDisplIncrement );
        Destination.Add( FUseDisplIncrements );
        Destination.Add( Integer( 0 ) );                    ///*** FNoAngles );
//      for I:=1 to FNoAngles do Destination.Add( FAngles[I-1] );
        Destination.Add( Integer( 0 ) );                     // FNoStabTrims );
//      for I:=1 to FNoStabTrims do Destination.Add( FStabTrims[I-1] );
        Destination.Add( FFreeTrim );
        Destination.Add( FVCG );
      end;
//    if Ship.Fileversion>=fv317 then Destination.Add(EnableModelAutoMove);
//    if Ship.Fileversion>=fv332 then Destination.Add(EnableBonjeanSAC); !!
//    if Ship.Fileversion>=fv332 then Destination.Add( false );
//    if Ship.Fileversion>=fv500 then Destination.Add( FProjectUnderWaterColorAlpha );
    end;
  end;
end;

