
function TFreeNamedObject.FGetSelected: boolean;  // descendant must implement
   begin result:=false; end;
procedure TFreeNamedObject.FSetSelected(AValue: boolean); // descendant must implement
    begin end;
constructor TFreeNamedObject.Create(Owner: TFreeSubdivisionSurface);
begin Surface:=Owner; FId:=-1;
  if Owner<>nil then begin inc(Owner.FIdSequence); FId:=Owner.FIdSequence; end;
end;

