unit FreeEmptyModelChooserDlg;
{$MODE Delphi}{$H+}
interface uses
    Controls,Forms,
    StdCtrls,Buttons,
    ExtCtrls,FreeGeometry,FreeLanguageSupport;
type
 TFreeEmptyModelChooserDialog = class(TForm)
    Label1,LabelFileName: TLabel;
    Panel1,Panel2,Panel3: TPanel;
    OKbutton,CancelButton: TSpeedButton;
    RadioGroup1: TRadioGroup;
    RbCreateNew,RbLoadFile,RbEmptyModel: TRadioButton;
    procedure OKbuttonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
 private FViewport: TFreeViewport;                     { Private declarations }
 public function Execute(FileName:AnsiString):Boolean;  { Public declarations }
end;

var FreeEmptyModelChooserDialog:TFreeEmptyModelChooserDialog;

implementation
{$R *.lfm}

function TFreeEmptyModelChooserDialog.Execute(FileName:AnsiString):Boolean;
begin ShowTranslatedValues(Self);
      LabelFileName.Caption:=FileName;
      if FileName='' then Label1.Caption:='';
      Showmodal;
      BringToFront;
      Result:=ModalResult=mrOk;
end;
procedure TFreeEmptyModelChooserDialog.OKbuttonClick(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TFreeEmptyModelChooserDialog.CancelButtonClick(Sender: TObject);
    begin ModalResult:=mrCancel; end;
end.
