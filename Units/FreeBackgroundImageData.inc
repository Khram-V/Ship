{---------------------------------------------------------------------}
{                                       TFreeBackgroundImageData      }
{   Freeship can import a max. of three different background images   }
{    that may be coupled either to the bodyplan, profile or planview. }
{   These images can be used to trace the lines of an                 }
{   hullform and are stored within the FREE!ship file.                }
{---------------------------------------------------------------------}
procedure TFreeBackgroundImageData.Clear;
begin
  FAssignedView:=fvPerspective;
  FImageData.Free;
  FImageData:=TJPEGImage.Create;
  FQuality:=100;
  FOrigin.X:=0;
  FOrigin.Y:=0;
  FScale:=10;
  FBlendingValue:=255;
  FTransparent:=False;
  FTransparentColor:=clBlack;
  FVisible:=True;
  FTolerance:=3;
end;

constructor TFreeBackgroundImageData.Create(Owner: TFreeship);
begin
  inherited Create;
  FOwner:=Owner;
  FImageData:=TJPEGImage.Create;
end;

destructor TFreeBackgroundImageData.Destroy;
begin
  Clear;
  FreeAndNil(FImageData);
  inherited Destroy;
end;

procedure TFreeBackgroundImageData.LoadBinary(Source: TFreeFileBuffer);
var
  I: integer;
begin
  Source.LoadInteger(I);
  FAssignedView:=TFreeViewType(I);
  Source.LoadBoolean(FVisible);
  Source.LoadInteger(FQuality);
  Source.LoadInteger(FOrigin.X);
  Source.LoadInteger(FOrigin.Y);
  Source.LoadTFloatType(FScale);
  Source.LoadInteger(FBlendingValue);
  Source.LoadBoolean(FTransparent);
  Source.LoadTColor(FTransparentColor);
  Source.LoadInteger(FTolerance);
  Source.LoadTJPEGImage(FImageData);
end;

procedure TFreeBackgroundImageData.SaveBinary(Destination: TFreeFileBuffer);
begin
  Destination.Add(Ord(AssignedView));
  Destination.Add(FVisible);
  Destination.Add(FQuality);
  Destination.Add(FOrigin.X);
  Destination.Add(FOrigin.Y);
  Destination.Add(FScale);
  Destination.Add(FBlendingValue);
  Destination.Add(FTransparent);
  Destination.Add(FTransparentColor);
  Destination.Add(FTolerance);
  FImageData.CompressionQuality:=FQuality;
  Destination.Add(FImageData);
end;

procedure TFreeBackgroundImageData.UpdateData(Viewport: TFreeViewport);
var I: integer;
begin
  FOrigin:=Viewport.BackgroundImage.Origin;
  FScale:=Viewport.BackgroundImage.Scale;
  FTransparent:=Viewport.BackgroundImage.Transparent;
  FBlendingValue:=Viewport.BackgroundImage.Alpha;
  FTransparentColor:=Viewport.BackgroundImage.TransparentColor;
  FTolerance:=Viewport.BackgroundImage.Tolerance;
  for I:=1 to FOwner.NumberOfViewports do
    if  (FOwner.Viewport[I-1] <> Viewport)
    and (FOwner.Viewport[I-1].ViewType = AssignedView)
    then FOwner.Viewport[I-1].BackgroundImage.AssignData
       ( FImageData, AssignedView, FOrigin, FScale, FTransparent,
         FTransparentColor,FBlendingValue,FQuality,Ftolerance,False );
  FOwner.FileChanged:=True;
end;

procedure TFreeBackgroundImageData.UpdateViews;
var I: integer;
begin
  for I:=1 to FOwner.NumberOfViewports do
    if FOwner.Viewport[I-1].Viewtype = AssignedView
    then FOwner.Viewport[I-1].BackgroundImage.AssignData
       ( FImageData, AssignedView, FOrigin, FScale, FTransparent,
         FTransparentColor,FBlendingValue,FQuality,FTolerance,False);
end;

