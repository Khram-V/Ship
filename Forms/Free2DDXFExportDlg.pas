

unit Free2DDXFExportDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils,
  Classes,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Buttons,
  ExtCtrls,
  Spin,
  LazFileUtils,FreeShipUnit,FreeLanguageSupport;
type

  { TDXFExport2DDialog }

  TDXFExport2DDialog = class(TForm)
    cbCreateIndividualFiles: TCheckBox;
    cbCreateIndividualLayers: TCheckBox;
    ComboBox1: TComboBox;
    Edit1: TFloatSpinEdit;
    Edit3: TEdit;
    Label1: TLabel;
    Label4: TLabel;
    Label7: TLabel;
    Panel1: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    SaveDialog: TSaveDialog;
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    SpeedButton1: TSpeedButton;
    procedure SpeedButton1Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
  private   { Private declarations }
    function FGetExportDirectory: string;
    procedure FSetExportDirectory(val: string);
    function FGetSegmentLength: double;
    procedure FSetSegmentLength(val: double);
    procedure FSetUnits;
  public    { Public declarations }
    function BrowseForFolder(
      const browseTitle: PAnsiChar; initialFolder: string = ''): string;
    function Execute: boolean;
    property ExportDirectory: string
      read FGetExportDirectory write FSetExportDirectory;
    property SegmentLength: double
      read FGetSegmentLength write FSetSegmentLength;
  end;

var DXFExport2DDialog: TDXFExport2DDialog;

implementation

  {$R *.lfm}

var lg_StartFolder: string;

{$IFnDEF FPC}
///////////////////////////////////////////////////////////////////
// Call back function used to set the initial browse directory.
///////////////////////////////////////////////////////////////////
function BrowseForFolderCallBack(Wnd: HWND;
  uMsg: UINT; lParam, lpData: LPARAM): integer stdcall;
begin
  if uMsg = BFFM_INITIALIZED then
    SendMessage(Wnd, BFFM_SETSELECTION, 1, integer(@lg_StartFolder[1]));
  Result:=0;
end;

///////////////////////////////////////////////////////////////////
// This function allows the user to browse for a folder
//
// Arguments:-
//    browseTitle : The title to display on the browse dialog.
//  initialFolder : Optional argument. Use to specify the folder
//                  initially selected when the dialog opens.
//
// Returns: The empty string if no folder was selected (i.e. if the
//          user clicked cancel), otherwise the full folder path.
///////////////////////////////////////////////////////////////////
function TDXFExport2DDialog.BrowseForFolder(const browseTitle: PAnsiChar;
  initialFolder: string = ''): string;
var browse_info: TBrowseInfo;
  folder: array[0..MAX_PATH] of char;
  find_context: PItemIDList;
  I: integer;
begin
  FillChar(browse_info, SizeOf(browse_info), #0);
  lg_StartFolder:=initialFolder;
  browse_info.pszDisplayName:=@folder[0];
  browse_info.lpszTitle:=browseTitle;
  browse_info.ulFlags:=BIF_RETURNONLYFSDIRS;
  browse_info.hwndOwner:=Application.Handle;
  if initialFolder <> '' then browse_info.lpfn:=BrowseForFolderCallBack;
  find_context:=SHBrowseForFolder(browse_info);
  if Assigned(find_context) then begin
    if SHGetPathFromIDList(find_context, folder) then begin
      Result:='';
      for I:=1 to length(Folder) do
        if Folder[I - 1] = #0 then break else Result:=Result + Folder[I - 1];
    end
    else Result:='';
    GlobalFreePtr(find_context);
  end
  else Result:='';
end;
{$ENDIF}

function TDXFExport2DDialog.BrowseForFolder(const browseTitle: PAnsiChar;
  initialFolder: string = ''): string;
var dlg: TSelectDirectoryDialog;
begin
  dlg:=TSelectDirectoryDialog.Create(Self);
  dlg.Title:=browseTitle;
  dlg.InitialDir:=initialFolder;
  if dlg.Execute then Result:=dlg.FileName
                 else Result:='';
end;

function TDXFExport2DDialog.FGetExportDirectory: string;
begin Result:=Edit3.Text; end;

procedure TDXFExport2DDialog.FSetExportDirectory(val: string);
begin Edit3.Text:=Val; end;

function TDXFExport2DDialog.FGetSegmentLength: double;
begin Result:=Edit1.Value; end;

procedure TDXFExport2DDialog.FSetSegmentLength(val: double);
begin if Val < 1e-5 then Val:=1e-5; Edit1.Value:=Val; end;

procedure TDXFExport2DDialog.FSetUnits;
var Str: string;
begin Str:=ComboBox1.Text + ' ';  //Label3.Caption:=Str;
end;

function TDXFExport2DDialog.Execute: boolean;
begin
  FSetUnits;
  ShowTranslatedValues(Self); Showmodal;
  Result:=ModalResult = mrOk;
end;

procedure TDXFExport2DDialog.SpeedButton1Click(Sender: TObject);
var Tmp: string;
begin
  Tmp:=BrowseForFolder( 'Choose a directory where you want to save the dxf files to: ', ExportDirectory);
  if DirectoryExistsUTF8(Tmp) { *Converted from DirectoryExists* }
     then self.ExportDirectory:=Tmp;
end;
procedure TDXFExport2DDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TDXFExport2DDialog.BitBtn2Click(Sender: TObject);
    begin ModalResult:=mrCancel; end;
procedure TDXFExport2DDialog.ComboBox1Change(Sender: TObject);
    begin FSetUnits; end;

end.
