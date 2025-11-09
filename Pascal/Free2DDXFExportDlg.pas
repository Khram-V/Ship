
unit Free2DDXFExportDlg;

interface

uses Windows,
     SysUtils,
     Controls,
     Forms,
     Dialogs,
     StdCtrls,
     Buttons,
     ExtCtrls,
     Shlobj,
     Spin;

type TDXFExport2DDialog = class(TForm)
     Panel2: TPanel;
     Label3: TLabel;
     Edit1: TFloatSpinEdit; // TFreeNumInput;
     Panel1: TPanel;
     Panel3: TPanel;
     Label1: TLabel;
     Label7: TLabel;
     Edit3: TEdit;
     SpeedButton1: TSpeedButton;
     SaveDialog: TSaveDialog;
     BitBtn1: TSpeedButton;
     BitBtn2: TSpeedButton;
     Label4: TLabel;
     ComboBox1: TComboBox;
     CheckBox1: TCheckBox;
     procedure SpeedButton1Click(Sender: TObject);
     procedure BitBtn1Click(Sender: TObject);
     procedure BitBtn2Click(Sender: TObject);
     procedure ComboBox1Change(Sender: TObject);
  private
     function FGetExportDirectory:string;
     procedure FSetExportDirectory(val:string);
     function FGetSegmentLength:Real;
     procedure FSetSegmentLength(val:Real);
     procedure FSetUnits;
  public
     function BrowseForFolder(Const browseTitle: PAnsiChar;initialFolder: String = ''): String;
     function Execute:Boolean;
     property ExportDirectory   : string read FGetExportDirectory write FSetExportDirectory;
     property SegmentLength     : Real read FGetSegmentLength write FSetSegmentLength;
end;

var DXFExport2DDialog:TDXFExport2DDialog;

implementation
uses FreeLanguageSupport;

{$R *.LFM}

var lg_StartFolder: String;

// Call back function used to set the initial browse directory.

function BrowseForFolderCallBack(Wnd: HWND; uMsg: UINT;lParam, lpData: LPARAM): Integer stdcall;
begin
   if uMsg = BFFM_INITIALIZED then SendMessage(Wnd,BFFM_SETSELECTION,1,Integer(@lg_StartFolder[1]));
   result := 0;
end;{BrowseForFolderCallBack}

(*
   This function allows the user to browse for a folder
   Arguments:-
      browseTitle : The title to display on the browse dialog.
    initialFolder : Optional argument. Use to specify the folder
                    initially selected when the dialog opens.
   Returns: The empty string if no folder was selected (i.e. if the
            user clicked cancel), otherwise the full folder path.
*)
function TDXFExport2DDialog.BrowseForFolder(Const browseTitle: PAnsiChar;initialFolder: String=''): String;
var browse_info   : TBrowseInfo;
    folder        : array[0..MAX_PATH] of char;
    find_context  : PItemIDList;
    I             : Integer;
begin
   FillChar(browse_info,SizeOf(browse_info),#0);
   lg_StartFolder := initialFolder;
   browse_info.pszDisplayName := @folder[0];
   browse_info.lpszTitle:=browseTitle;
   browse_info.ulFlags := BIF_RETURNONLYFSDIRS;
   browse_info.hwndOwner := Application.Handle;
   if initialFolder<>'' then browse_info.lpfn := BrowseForFolderCallBack;
   find_context := SHBrowseForFolder(browse_info);
   if Assigned(find_context) then begin
      if SHGetPathFromIDList(find_context,folder) then begin
         result:='';
         for I:=1 to length(Folder) do begin
            if Folder[I-1]=#0 then break else Result:=result+Folder[I-1];
         end;
      end else result := '';
      GlobalFreePtr(find_context);
  end else result := '';
end;

function TDXFExport2DDialog.FGetExportDirectory:string;
   begin Result:=Edit3.Text; end;
procedure TDXFExport2DDialog.FSetExportDirectory(val:string);
    begin Edit3.Text:=Val; end;
function TDXFExport2DDialog.FGetSegmentLength:Real;
   begin Result:=Edit1.Value; end;
procedure TDXFExport2DDialog.FSetSegmentLength(val:Real);
    begin if Val<1e-5 then Val:=1e-5; Edit1.Value:=Val; end;
procedure TDXFExport2DDialog.FSetUnits; var Str:String;
    begin Str:=ComboBox1.Text; Label3.Caption:=Str;end;
function TDXFExport2DDialog.Execute:Boolean;
   begin FSetUnits; Showmodal; Result:=ModalResult=mrOk; end;

procedure TDXFExport2DDialog.SpeedButton1Click(Sender: TObject);
var Tmp:string;
begin
   Tmp:=BrowseForFolder(PAnsichar(Userstring(209)+':'),ExportDirectory);
   if DirectoryExists(Tmp) then self.ExportDirectory:=Tmp;
end;

procedure TDXFExport2DDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TDXFExport2DDialog.BitBtn2Click(Sender: TObject);
    begin ModalResult:=mrCancel; end;
procedure TDXFExport2DDialog.ComboBox1Change(Sender: TObject);
    begin FSetUnits; end;

end.
