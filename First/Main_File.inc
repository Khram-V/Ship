
procedure TMainForm.LoadFileExecute( Sender: TObject );
var HullformWindow:TFreeHullWindow; I:Integer;
begin
   OpenDialog.InitialDir:=ExtractFilePath(Application.ExeName);
   if OpenDialog.Execute then begin
      if MDIChildCount=0 then begin
         for i:=0 to 3 do begin                          // open a new window
           HullformWindow:=TFreeHullWindow.Create(self); // Connect viewport to
           HullformWindow.FreeShip:=FreeShip;            // freeship component
           HullformWindow.Viewport.ViewType:=TFreeViewType(I);
           HullformWindow.SetCaption;
         end;
         Tile;
      end;
      FreeShip.Filename:=OpenDialog.Filename;
      FreeShip.LoadFromFile;
      SetCaption;
      UpdateMenu;
   end;
end;
procedure TMainForm.SaveFileExecute(Sender: TObject);
    begin FreeShip.SaveToFile; UpdateMenu; end;


