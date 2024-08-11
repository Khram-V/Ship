

unit FreeEmptyModelChooserDlg;

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
    FreeGeometry;

type

{ TFreeEmptyModelChooserDialog }

 TFreeEmptyModelChooserDialog = class(TForm)
   Label1: TLabel;
    LabelFileName: TLabel;
    Panel2: TPanel;
    Panel1: TPanel;
    Panel3: TPanel;
    OKbutton: TSpeedButton;
    CancelButton: TSpeedButton;
    RadioGroup1: TRadioGroup;
    RbCreateNew: TRadioButton;
    RbEmptyModel: TRadioButton;
    RbLoadFile: TRadioButton;
    procedure OKbuttonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
 private   { Private declarations }
    FViewport: TFreeViewport;
 public    { Public declarations }
    function Execute(FileName:String):Boolean;
end;

var FreeEmptyModelChooserDialog:TFreeEmptyModelChooserDialog;

implementation

{$R *.lfm}

function TFreeEmptyModelChooserDialog.Execute(FileName:String):Boolean;
begin
   LabelFileName.Caption := FileName;                                           // ShowTranslatedValues(Self);
   Showmodal;
   BringToFront;
   Result:=ModalResult=mrOk;
end;

procedure TFreeEmptyModelChooserDialog.OKbuttonClick(Sender: TObject);
begin ModalResult:=mrOk; end;

procedure TFreeEmptyModelChooserDialog.CancelButtonClick(Sender: TObject);
begin ModalResult:=mrCancel; end;

end.
