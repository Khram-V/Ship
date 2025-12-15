{
   included in ShipUnit
}
//
//  TProjectSettings
//    Container class for project settings for each project
//                such as mainparticulars,waterdensity etc.

procedure TProjectSettings.FSetHydrostaticCoefficients
          ( val: THydrostaticCoeff );
var I: integer;
begin
  if val<>FHydrostaticCoefficients then begin
    FHydrostaticCoefficients:=val;
    St.FileChanged:=True;
    for I:=0 to St.NoHydrostaticCalculations-1 do
      St.HydrostaticCalculation[I].Calculated:=False;
  end;
end;
procedure TProjectSettings.FSetDisableModelCheck(Val: boolean);
    begin if val<>FDisableModelCheck then begin
          FDisableModelCheck:=Val; St.FileChanged:=True; end;
    end;
function TProjectSettings.FGetMidleFrame: Real;
   begin if FUseMidleFrame
            then Result:=(St.Surface.Max.X+St.Surface.Min.X)/2
            else Result:=FMidleFrame;
   end;
procedure TProjectSettings.FSetProjectAppendageCoefficient(Val: Real);
    begin if abs(Val-FProjectAppendageCoefficient)>1e-6 then begin
          FProjectAppendageCoefficient:=Val; St.FileChanged:=True; end;
    end;
procedure TProjectSettings.FSetProjectBeam( Val: Real );
    begin if Val<0.001 then Val:=1; FProjectBeam:=Val; St.FileChanged:=True;
    end;
procedure TProjectSettings.FSetProjectDraft(Val: Real);
    begin if Val<0.001 then Val:=1; FProjectDraft:=Val; St.FileChanged:=True;
    end;
procedure TProjectSettings.FSetProjectLength(Val: Real);
    begin if Val<0.001 then Val:=1; FProjectLength:=Val; St.FileChanged:=True;
    end;
procedure TProjectSettings.FSetMidleFrame(Mid: Real);
    begin if Mid<>FMidleFrame then begin FMidleFrame:=Mid; St.FileChanged:=True;
    end;
end;
procedure TProjectSettings.FSetProjectWaterDensity(Val: Real);
    begin if abs( Val-FProjectWaterDensity )>1e-6 then
          begin FProjectWaterDensity:=Val; St.FileChanged:=True; end;
    end;
procedure TProjectSettings.FSetProjectWaterTemper(Val: Real);
    begin if abs( Val-FProjectWaterTemper )>1e-6 then
          begin FProjectWaterTemper:=Val; St.FileChanged:=True; end;
    end;
procedure TProjectSettings.FSetSavePreview(val: boolean);
    begin if val<>FSavePreview then
          begin FSavePreview:=Val; St.FileChanged:=True; end;
    end;
procedure TProjectSettings.FSetStartDraft(Val: Real);
    begin if Val<>FStartDraft then
          begin FStartdraft:=Val; St.FileChanged:=True; end;
    end;
procedure TProjectSettings.FSetTrim(Val: Real);
    begin if Val<>FTrim then begin FTrim:=Val; St.FileChanged:=True; end;
    end;
procedure TProjectSettings.FSetEndDraft(Val: Real);
    begin if Val<>FEndDraft then begin FEnddraft:=Val; St.FileChanged:=True; end;
    end;
procedure TProjectSettings.FSetDraftStep(Val: Real);
    begin if Val<>FDraftStep then begin FDraftStep:=Val; St.FileChanged:=True; end;
    end;
procedure TProjectSettings.FSetUseMidleFrame(Mid: boolean);
    begin if Mid<>FUseMidleFrame then
          begin FUseMidleFrame:=Mid; St.FileChanged:=True; end;
    end;
procedure TProjectSettings.FSetProjectShadeUnderwaterShip(Val: boolean);
    begin if val<>FProjectShadeUnderwaterShip then
          begin FProjectShadeUnderwaterShip:=Val; St.FileChanged:=True; end;
    end;
procedure TProjectSettings.FSetProjectSimplifyIntersections(val: boolean);
var I: integer;
begin
   if val<>FProjectSimplifyIntersections then begin
      FProjectSimplifyIntersections:=val;
      for I:=1 to St.NoStations do St.Station[I-1].Built:=False;
      for I:=1 to St.NoButtocks do St.Buttock[I-1].Built:=False;
      for I:=1 to St.NoWaterlines do St.Waterline[I-1].Built:=False;
      for I:=1 to St.NoDiagonals do St.Diagonal[I-1].Built:=False;
      for I:=1 to St.NoHydrostaticCalculations do
                  St.HydrostaticCalculation[I-1].Calculated:=False;
   end;
end;
procedure TProjectSettings.FSetProjectUnits(Val: TUnitType);
var
  UnitConversionFactor,WeightFactor,ThicknessFactor: Real;
  Layer: SLayer;
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
    for I:=1 to St.Surface.NoLayers do begin
      Layer:=St.Surface.Layer[I-1];
      Layer.MaterialDensity:=Layer.MaterialDensity*WeightFactor;
      Layer.Thickness:=Layer.Thickness*ThicknessFactor;
    end;
    ScaleVector.X:=UnitConversionFactor;
    ScaleVector.Y:=UnitConversionFactor;
    ScaleVector.Z:=UnitConversionFactor;
    St.Edit.Model_Scale(Scalevector,True,True);       // Scale and redraw
  end;
end;

procedure TProjectSettings.Clear;
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
  FProjectShadeUnderwaterShip:=True;
// Shades the underwaterpart of the hull in a different color
  ProjectUnderWaterColor:=St.Preferences.UnderWaterColor;
  ProjectUnderWaterColorAlpha:=St.Preferences.UnderWaterColorAlpha;
  FProjectUnits:=TUnitType( 0 ); // Default is metric units
  FUseMidleFrame:=True;
  FMidleFrame:=0.0;
  FDisableModelCheck:=True;
  FSavePreview:=False;
  FHydrostaticCoefficients:=fcActualData;
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
  YesTrim:=True;
  FVCG:=1.0;
end;

constructor TProjectSettings.Create(Owner: TShip);
begin inherited Create; St:=Owner; Clear;
end;

// User input of mainparticulars and project setting
procedure TProjectSettings.Edit;
var
  Dialog: TProjectSettingsDialog;
begin
  Dialog:=TProjectSettingsDialog.Create( St );
  Dialog.Edit1.Text:=ProjectName;           //  'Project name'
  Dialog.Edit7.Text:=ProjectDesigner;       //  'Designer'
  Dialog.Edit9.Text:=ProjectComment;        //  'Comment'
  Dialog.Edit10.Text:=ProjectFileCreatedBy; //  'File created by'
  Dialog.UnitBox.ItemIndex:=Ord(ProjectUnits);
  Dialog.PrecisionBox.ItemIndex:=Ord(St.Precision);
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
  Dialog.CheckBox5.Checked:=St.Visibility.FShowHydrostDisplacement;
  Dialog.CheckBox6.Checked:=St.Visibility.FShowHydrostSectionalAreas;
  Dialog.CheckBox7.Checked:=St.Visibility.FShowHydrostMetacentricHeight;
  Dialog.CheckBox8.Checked:=St.Visibility.FShowHydrostLCF;
  Dialog.CheckBox9.Checked:=St.Visibility.FShowHydrostLateralArea;
  Dialog.cbSimplifyIntersections.Checked:=ProjectSimplifyIntersections;
  ShowTranslatedValues(Dialog);
  if Dialog.Execute then begin
    St.Edit.CreateUndoObject('Project settings ',True );
    FProjectName         :=BlankOff( Dialog.Edit1.Text ); //ProjectName.Trim;
    FProjectDesigner     :=BlankOff( Dialog.Edit7.Text ); //ProjectDesigner.Trim;
    FProjectComment      :=BlankOff( Dialog.Edit9.Text ); //ProjectComment.Trim;
    FProjectFileCreatedBy:=BlankOff( Dialog.Edit10.Text); //ProjectFileCreatedBy.Trim;
    ProjectUnits:=TUnitType(Dialog.UnitBox.ItemIndex);
    St.Precision:=TPrecisionType(Dialog.PrecisionBox.ItemIndex);
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
    ProjectCoefficients:=THydrostaticCoeff(Dialog.ComboBox1.ItemIndex);
    St.Visibility.FShowHydrostDisplacement:=Dialog.CheckBox5.Checked;
    St.Visibility.FShowHydrostSectionalAreas:=Dialog.CheckBox6.Checked;
    St.Visibility.FShowHydrostMetacentricHeight:=Dialog.CheckBox7.Checked;
    St.Visibility.FShowHydrostLCF:=Dialog.CheckBox8.Checked;
    St.Visibility.FShowHydrostLateralArea:=Dialog.CheckBox9.Checked;
    ProjectSimplifyIntersections:=Dialog.cbSimplifyIntersections.Checked;
    St.FileChanged:=True;
    St.Redraw;
  end;
  FreeAndNil(Dialog);
end;

procedure TProjectSettings.LoadBinary(Source: TFilebuffer; Image: TJPegImage);
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
{ if St.FileVersion >= fv160 then begin ~~ как бы юолжно быть так, ан нет...}
     FProjectUnits:=TUnitType(I);
     Source.LoadBoolean(FUseMidleFrame);
     Source.LoadTFloatType(FMidleFrame);
{ if St.FileVersion >= fv165 then } Source.LoadBoolean(FDisableModelCheck);
{ end; }
  Source.LoadString( FProjectComment );
  Source.LoadString( FProjectFileCreatedBy );
  FSavePreview:=false;
                            FProjectDesigner:=BlankOff(FProjectDesigner); //???
                                FProjectName:=BlankOff(FProjectName);
                             FProjectComment:=BlankOff(FProjectComment);
                       FProjectFileCreatedBy:=BlankOff(FProjectFileCreatedBy);
  if St.FileVersion >= fv210 then begin
    Source.LoadInteger( I );
    FHydrostaticCoefficients:=THydrostaticCoeff(I);
    Source.LoadBoolean( FSavePreview );
    if FSavePreview then begin
      Jpg:=TJPEGImage.Create;
      Source.LoadTJPEGImage( Jpg );
      if Image<>nil then Image.Assign(Jpg);
      FreeAndNil(Jpg);
    end;
    if St.FileVersion >= fv230 then
      Source.LoadBoolean(FProjectSimplifyIntersections);
    if St.Fileversion >= fv250 then begin
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
      Source.LoadBoolean(YesTrim);
      Source.LoadTFloatType(FVCG);
    end;
    if St.Fileversion >= fv317 then Source.LoadBoolean(FEnableModelAutoMove);
    if St.Fileversion >= fv332 then Source.LoadBoolean(FEnableBonjeanSAC);
    if St.Fileversion >= fv500 then
    begin Source.LoadInteger( I ); ProjectUnderWaterColorAlpha:=byte(I); end;
  end;
end;

procedure TProjectSettings.SaveBinary( Destination: TFileBuffer );
var Jpg: TJPegImage;
begin
  if St.FileVersion>=fv120 then begin
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
  { if St.FileVersion>=fv160 then begin }
       Destination.Add(FUseMidleFrame);
       Destination.Add(FMidleFrame);
  {    if St.FileVersion>=fv165 then } Destination.Add( DisableModelCheck );
  { end; }
    Destination.Add( BlankOff(FProjectComment) );
    Destination.Add( BlankOff(FProjectFileCreatedBy) );
    if St.FileVersion>=fv210 then begin
      Destination.Add( Ord( ProjectCoefficients ) );
      if FSavePreview then begin Jpg:=St.FGetPreview;
        FSavePreview:=Jpg<>nil; Destination.Add( FSavePreview );
        if FSavePreview then begin Destination.Add( Jpg ); Jpg.Destroy end
      end else Destination.Add( false );
      if St.FileVersion>=fv230 then Destination.Add(FProjectSimplifyIntersections);
      if St.Fileversion>=fv250 then begin // save settings for hydrostatics
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
        Destination.Add( YesTrim );
        Destination.Add( FVCG );
      end;
//    if St.Fileversion>=fv317 then Destination.Add(EnableModelAutoMove);
//    if St.Fileversion>=fv332 then Destination.Add(EnableBonjeanSAC); !!
//    if St.Fileversion>=fv332 then Destination.Add( false );
//    if St.Fileversion>=fv500 then Destination.Add( FProjectUnderWaterColorAlpha );
    end;
  end;
end;

