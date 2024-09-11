

unit FreeSaveImageDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf,
{$ENDIF}
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Buttons,
  ExtCtrls, Spin,
  FreeShipUnit,FreeLanguageSupport;

type

  { TSaveImageDialog }

  TSaveImageDialog = class(TForm)
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    Edit3: TEdit;
    FloatSpinEdit1: TFloatSpinEdit;
    Label1: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Label2: TLabel;
    Label4: TLabel;
    Panel4: TPanel;
    SpinEdit1: TSpinEdit;
    SpinEdit2: TSpinEdit;
    Label7: TLabel;
    SpeedButton1: TSpeedButton;
    SaveDialog: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure SpinEdit2Change(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure SetImageSizes(W,H: integer);
  private   { Private declarations }
    FRatio: single;
    FIsInteractive : boolean;
    function FGetFilename: string;
    function FGetImageWidth: integer;
    procedure FSetImageWidth(val: integer);
    procedure FSetFilename(val: string);
    function FGetImageHeight: integer;
    procedure FSetImageHeight(val: integer);
  public    { Public declarations }
    function Execute: boolean;
    procedure SetImageSize;
    property Filename: string
      read FGetFilename write FSetFilename;
    property ImageWidth: integer
      read FGetImageWidth write FSetImageWidth;
    property ImageHeight: integer
      read FGetImageHeight write FSetImageHeight;
  end;

var
  SaveImageDialog: TSaveImageDialog;

implementation

{$IFnDEF FPC}
  {$R *.dfm}

{$ELSE}
  {$R *.lfm}
{$ENDIF}

procedure TSaveImageDialog.SetImageSize;
var
  Size: single;
begin
  Size:=ImageWidth * ImageHeight * 3 / 1024;
  if size > 1024 then begin
    FloatSpinEdit1.Value:=Size / 1024; Label5.Caption:='MB';
  end else begin
    FloatSpinEdit1.Value:=Size / 1024; Label5.Caption:='KB';
  end;
end;

function TSaveImageDialog.FGetFilename: string;
begin Result:=Edit3.Text; end;

procedure TSaveImageDialog.FSetFilename(val: string);
begin
  Edit3.Text:=val;
end;

procedure TSaveImageDialog.SetImageSizes(W,H: integer);
begin
  FIsInteractive:=false;
  ImageWidth:=W;
  ImageHeight:=H;
  FRatio:=ImageWidth / ImageHeight;
  FIsInteractive:=true;
end;

function TSaveImageDialog.FGetImageWidth: integer;
begin Result:=SpinEdit1.Value; end;

procedure TSaveImageDialog.FSetImageWidth(val: integer);
begin SpinEdit1.Value:=val; SetImageSize; end;

function TSaveImageDialog.FGetImageHeight: integer;
begin Result:=SpinEdit2.Value; end;

procedure TSaveImageDialog.FSetImageHeight(val: integer);
begin SpinEdit2.Value:=val; SetImageSize; end;

function TSaveImageDialog.Execute: boolean;
begin
  FRatio:=Imagewidth / ImageHeight;
  ShowTranslatedValues(Self); Showmodal;
  Result:=ModalResult = mrOk;
end;

procedure TSaveImageDialog.FormCreate(Sender: TObject);
begin
  FIsInteractive:=true;
  FRatio:=1.0;
end;

procedure TSaveImageDialog.SpinEdit1Change(Sender: TObject);
begin
  if not FIsInteractive then exit;
  //ImageWidth:=self.ImageWidth;
  ImageHeight:=Round(Imagewidth / FRatio);
  SetImageSize;
end;

procedure TSaveImageDialog.SpinEdit2Change(Sender: TObject);
begin
  if not FIsInteractive then exit;
  //ImageHeight:=self.ImageHeight;
  ImageWidth:=Round(FRatio * ImageHeight);
  SetImageSize;
end;

procedure TSaveImageDialog.SpeedButton1Click(Sender: TObject);
begin
  SaveDialog.InitialDir:= ExtractFileDir(Filename);
  SaveDialog.FileName:=ExtractFileName(Filename);
  if SaveDialog.Execute then
    Filename:=SaveDialog.FileName;
end;

procedure TSaveImageDialog.BitBtn1Click(Sender: TObject);
begin ModalResult:=mrOk; end;

procedure TSaveImageDialog.BitBtn2Click(Sender: TObject);
begin ModalResult:=mrCancel; end;

end.
