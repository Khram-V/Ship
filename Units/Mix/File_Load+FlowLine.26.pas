
procedure TMainForm.LoadFileExecute(Sender: TObject);
begin
   FreeShip.Edit.File_Load;
   FOpenHullWindows;
   SetCaption;
   UpdateMenu;
end;{TMainForm.LoadFileExecute}



procedure TFreeEdit.File_Load;
var Answer     : word;
    OpenDialog : TOpenDialog;
begin
   OpenDialog:=TOpenDialog.Create(Owner);
   OpenDialog.InitialDir:=Owner.Preferences.OpenDirectory;
   OpenDialog.Filter:='FREE!ship files (*.fbm)|*.fbm';
   Opendialog.Options:=[ofHideReadOnly];
   if OpenDialog.Execute then
   begin
      if Owner.FileChanged then
      begin
         Answer:=MessageDlg(Userstring(103)+EOL+Userstring(104),mtConfirmation,[mbYes,mbNo,mbCancel],0);
         if Answer=mrCancel then
         begin
            OpenDialog.Destroy;
            exit;
         end;
         if Answer=mrYes then
         begin
            File_SaveAs;
            if Owner.FileChanged then
            begin
               // Apparently saving was not successfull, abort
               OpenDialog.Destroy;
               exit;
            end;
         end;
      end;
      File_Load(Opendialog.FileName);   // Load everything into memory
   end;
   Opendialog.Destroy;
end;{TFreeEdit.File_Load}

procedure TFreeEdit.File_Load(filename:string);
var Source  : TFreeFileBuffer;
begin
   Source:=TFreeFileBuffer.Create;
   try
      Source.LoadFromFile(FileName);                // Load everything into memory
      Owner.Preferences.OpenDirectory:=ExtractFilePath(FileName);
      Owner.Filename:=ChangeFileExt(FileName,'.fbm');
      Owner.LoadBinary(Source);                    // Now read the information from memory
      Owner.Surface.Clearselection;                // Make sure no items are selected
      Owner.FSelectedFlowlines.Clear;
      Owner.FSelectedMarkers.Clear;
      Owner.Draw;
      Owner.FFilenameSet:=True;
      Owner.FStopAskingForFileVersion:=False;
   finally
      Source.Destroy;
      AddToRecentFiles(FileName);
      Undo_Clear;
   end;
   Owner.FileChanged:=False;
end;{TFreeEdit.File_Load}

// save as FREE!ship file without prompting for a filename (must already been set)
procedure TFreeEdit.File_Save;
var Backup     : string;
    Destination: TFreeFileBuffer;
    Str        : string;
    Answer     : word;
begin
   if not Owner.FilenameSet then File_SaveAs;
   if not Owner.FilenameSet then exit;

   if (Owner.FileVersion<CurrentVersion) and (not Owner.FStopAskingForFileVersion) then
   begin
      Str:=Userstring(126)+VersionString(Owner.FileVersion)+EOL+
           Userstring(127)+#32+VersionString(CurrentVersion)+ '?';
      Answer:=MessageDlg(Str,mtInformation,[mbYes,mbNo],0);
      if Answer=mrYes then Owner.FileVersion:=CurrentVersion
                      else Owner.FStopAskingForFileVersion:=True;
   end;

   Owner.FFilenameSet:=True;
   // Check if the file already exists
   if FileExists(Owner.Filename) then
   begin
      Backup:=ChangeFileExt(Owner.Filename,'.Bak');
      // First check for a backup, and delete when present
      if FileExists(Backup) then if not SysUtils.DeleteFile(Backup) then MessageDlg(Userstring(128),mtError,[mbOk],0);
      // Then create a backup of the old file
      if not RenameFile(Owner.Filename,Backup) then MessageDlg(Userstring(129),mtError,[mbOk],0);
   end;
   Destination:=TFreeFileBuffer.Create;
   Owner.SaveBinary(Destination);
   Destination.SaveToFile(Owner.Filename);
   Owner.Preferences.SaveDirectory:=ExtractFilePath(Owner.FileName);
   AddToRecentFiles(Owner.FileName);
   Destination.Destroy;
end;{TFreeEdit.File_Save}

procedure TFreeEdit.File_SaveAs;
var SaveDialog : TSaveDialog;
begin
   SaveDialog:=TSaveDialog.Create(Owner);
   SaveDialog.InitialDir:=Owner.Preferences.SaveDirectory;
   Savedialog.FileName:=ExtractFilename(Owner.Filename);
   SaveDialog.Filter:='FREE!ship files (*.fbm)|*.fbm';
   Savedialog.Options:=[ofOverwritePrompt,ofHideReadOnly];
   if SaveDialog.Execute then
   begin
      Owner.Preferences.SaveDirectory:=ExtractFilePath(SaveDialog.FileName);
      if CurrentVersion>Owner.FileVersion then Owner.FStopAskingForFileVersion:=False;
      Owner.Filename:=Savedialog.Filename;;
      Owner.FFilenameSet:=True;
      File_Save;
   end;
   SaveDialog.Destroy;
end;{TFreeEdit.File_SaveAs}

procedure TFreeEdit.Flowline_Add(Source:T2DCoordinate;View:TFreeviewType);
var Flowline : TFreeFlowline;
    Undo     : TFreeUndoObject;
begin
   Undo:=CreateUndoObject(Userstring(130),False);
   Flowline:=TFreeflowline.Create(Owner);
   Owner.FFlowLines.Add(Flowline);
   Flowline.FProjectionPoint:=Source;
   Flowline.FProjectionView:=View;
//   Flowline.FMethodNew:=True;
   Flowline.Rebuild;
   if Flowline.FFlowLine.NumberOfPoints>0 then
   begin
      Owner.FileChanged:=True;
      Undo.Accept;
      Owner.Redraw;
   end else
   begin
      Undo.Delete;
      Flowline.Delete;
   end;
end;{TFreeEdit.Flowline_Add}
