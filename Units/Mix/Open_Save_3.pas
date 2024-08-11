program Open_save3;   // Adapted from http://stackoverflow.com/questions/33756036/how-can-i-select-a-file-in-delphi
{$mode objfpc}{$H+}
uses
   Dialogs, Interfaces,
   CRT,   // for readkey
   Forms; // for Application.Initialize
var
  selectedFile: string;
  dlg: TOpenDialog;
begin
  Application.Initialize;
  selectedFile := '';
  dlg := TOpenDialog.Create(nil);
  try
    dlg.InitialDir := '';
    dlg.Filter := 'All files (*.*)|*.*';
    if dlg.Execute( {Handle} ) then selectedFile:=dlg.FileName;
  finally
    dlg.Free;
  end;
  if selectedFile <> '' then  begin // <your code here to handle the selected file>
    writeln('File = ', selectedFile);
    readkey;
  end;
  Application.Free; // needed?
end.
 