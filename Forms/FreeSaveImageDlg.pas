
unit FreeSaveImageDlg;
{$MODE Delphi}
interface uses
     Classes,   SysUtils,
     Controls,  Forms,
     ExtCtrls,  Dialogs,
     StdCtrls,  Buttons;
type TSaveImageDialog = class(TForm)
     Edit1, Edit2, Edit3: TEdit;
     Panel1,Panel2,Panel3: TPanel;
     Label1,Label2,Label3,Label4,_Label5,Label6,Label7: TLabel;
     SpeedButton1,BitBtn1,BitBtn2: TSpeedButton;
     SaveDialog: TSaveDialog;
     procedure Edit1KeyPress(Sender: TObject; var Key: Char);
     procedure Edit1Exit(Sender: TObject);
     procedure Edit1KeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
     procedure Edit2Exit(Sender: TObject);
     procedure SpeedButton1Click(Sender: TObject);
     procedure BitBtn1Click(Sender: TObject);
     procedure BitBtn2Click(Sender: TObject);
  private   { Private declarations }
     FRatio : single;
     function FGetFilename:AnsiString;
     function FGetImageWidth:integer;
     procedure FSetImageWidth(val:integer);
     procedure FSetFilename(val:AnsiString);
     function FGetImageHeight:integer;
     procedure FSetImageHeight(val:integer);
  public    { Public declarations }
     function Execute:Boolean;
     procedure SetImageSize;
     property FilenamePNG:AnsiString read FGetFilename write FSetFilename;
     property ImageWidth:integer read FGetImageWidth write FSetImageWidth;
     property ImageHeight:integer read FGetImageHeight write FSetImageHeight;
  end;
var SaveImageDialog:TSaveImageDialog;

implementation
{$R *.lfm}

procedure TSaveImageDialog.SetImageSize;
  var Size: single;
begin Size:=ImageWidth*ImageHeight*3/1024;
   if size>1024 then _Label5.caption:=FloatToStrF(Size/1024,ffFixed,7,2)+' MB'
                else _Label5.caption:=FloatToStrF(Size,ffFixed,7,0)+' KB'
end;
function TSaveImageDialog.FGetFilename:AnsiString;
   begin Result:=Edit3.Text; end;
function TSaveImageDialog.FGetImageWidth:integer;
   begin if Edit1.Text='' then result:=1
                          else Result:=StrToInt(Edit1.Text);
end;
procedure TSaveImageDialog.FSetImageWidth(val:integer);
    begin Edit1.Text:=IntToStr(Val); SetImageSize; end;

procedure TSaveImageDialog.FSetFilename(val:AnsiString);
    begin Edit3.Text:=val; end;
function TSaveImageDialog.FGetImageHeight:integer;
begin if Edit2.Text='' then result:=1
                       else Result:=StrToInt(Edit2.Text);
end;
procedure TSaveImageDialog.FSetImageHeight(val:integer);
    begin Edit2.Text:=IntToStr(Val); SetImageSize; end;
function TSaveImageDialog.Execute:Boolean;
   begin FRatio:=Imagewidth/ImageHeight; Showmodal; Result:=ModalResult=mrOk;
   end;
procedure TSaveImageDialog.Edit1KeyPress(Sender: TObject; var Key: Char);
    begin if (Key in [#8,'1'..'9','0',#13])
          or (Key=FormatSettings.DecimalSeparator) then else key:=#0;
    end;
procedure TSaveImageDialog.Edit1Exit(Sender: TObject);
    begin ImageWidth:=self.ImageWidth;
          ImageHeight:=Round(Imagewidth/FRatio);
    end;
procedure TSaveImageDialog.Edit1KeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    begin if Key=13 then SelectNext(Activecontrol,True,true); end;
procedure TSaveImageDialog.Edit2Exit(Sender: TObject);
begin inherited;
      ImageHeight:=self.ImageHeight;
      ImageWidth:=Round(FRatio*ImageHeight);
end;
procedure TSaveImageDialog.SpeedButton1Click(Sender: TObject);
begin SaveDialog.FileName:=FilenamePNG;
      if SaveDialog.Execute then FilenamePNG:=SaveDialog.FileName;
end;
procedure TSaveImageDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrOk; end;

procedure TSaveImageDialog.BitBtn2Click(Sender: TObject);
    begin ModalResult:=mrCancel; end;

end.
