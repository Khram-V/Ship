{----------------------------------------------------------}
{                                           TFreeEntity    }
{ This is the base class of all 3D entities in the project }
{----------------------------------------------------------}
function TFreeEntity.GetMin: T3DVector;
   begin if not Built then Rebuild; Result:=FMin; end;
function TFreeEntity.GetMax: T3DVector;
   begin if not Built then Rebuild; Result:=FMax; end;
procedure TFreeEntity.SetBuilt(Val: boolean);
begin
  if Val <> FBuilt then begin FBuilt:=Val;
    if not Val then begin FMin:=ZERO; FMAx:=ZERO; end;
  end;
end;

constructor TFreeEntity.Create(Owner: TFreeSubdivisionSurface); // Create and initialise all data
begin
  inherited Create( Owner ); //Clear;
  FBuilt:=False;
  FMin:=ZERO;
  FMax:=ZERO; // The min/max boundary coordinates of the entity after it has been Built
  PenWidth:=1;        // Pen thickness to use when drawing
  Color:=clBlack;     // Color when drawing
  Penstyle:=psSolid;  // Pen style for drawing the line
end;

procedure TFreeEntity.Clear;
begin
  Built:=False;
  FMin:=ZERO;
  FMAx:=ZERO;
  Color:=clBlack;
  Penwidth:=1;
  PenStyle:=psSolid;
end;

destructor TFreeEntity.Destroy; begin inherited Destroy; end;

procedure TFreeEntity.Extents(var Min, Max: T3DVector);
begin
  if not Built then Rebuild;
  MinMax(FMin, Min, Max);
  MinMax(FMax, Min, Max);
end;

procedure TFreeEntity.Draw( Viewport: TFreeViewport ); begin end;
//procedure TFreeEntity.Draw; begin end;

procedure TFreeEntity.Rebuild; begin FBuilt:=True; end;

