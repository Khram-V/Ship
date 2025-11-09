
unit FreeRotateDlg;
{$MODE Delphi}
interface uses
     SysUtils,     Classes,
     Controls,     Forms,
     StdCtrls,     Buttons,
     ExtCtrls,     FreeTypes;

type TFreeRotateDialog = class(TForm)
  Label1,Label2,Label3,Label4,Label6,Label9: TLabel;
  Panel1,Panel2,Panel3: TPanel;
  Edit1,Edit2,Edit3: TEdit;
  OKButton,CancelButton: TSpeedButton;
     procedure Edit1KeyPress(Sender: TObject; var Key: Char);
     procedure Edit1KeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
     procedure Edit1Exit(Sender: TObject);
     procedure Edit2Exit(Sender: TObject);
     procedure Edit3Exit(Sender: TObject);
     procedure OKButtonClick(Sender: TObject);
     procedure CancelButtonClick(Sender: TObject);
  private
     function FGetXValue:Real; procedure FSetXValue(val:Real);
     function FGetYValue:Real; procedure FSetYValue(val:Real);
     function FGetZValue:Real; procedure FSetZValue(val:Real);
  public
     function Execute( Caption,Units:String ):Boolean;
     property XValue:Real read FGetXValue write FSetXValue;
     property YValue:Real read FGetYValue write FSetYValue;
     property ZValue:Real read FGetZValue write FSetZValue;
end;

var FreeRotateDialog:TFreeRotateDialog;
implementation
{$R *.lfm}

function TFreeRotateDialog.FGetXValue:Real;
   begin if Edit1.Text='' then result:=0.0
                          else Result:=StrToFloat(Edit1.Text);
   end;
procedure TFreeRotateDialog.FSetXValue(val:Real);
    begin Edit1.Text:=FloatToDec( Val,5 ); //StrF(Val,ffFixed,7,4);
    end;
function TFreeRotateDialog.FGetYValue:Real;
   begin if Edit2.Text='' then result:=0.0
                          else Result:=StrToFloat( Edit2.Text );
   end;
procedure TFreeRotateDialog.FSetYValue(val:Real);
    begin Edit2.Text:=FloatToDec( Val,5 ); //StrF(Val,ffFixed,7,4);
    end;
function TFreeRotateDialog.FGetZValue:Real;
   begin if Edit3.Text='' then Result:=0.0
                          else Result:=StrToFloat(Edit3.Text);
   end;
procedure TFreeRotateDialog.FSetZValue(val:Real);
    begin Edit3.Text:=FloatToDec( Val,5 ); //StrF(Val,ffFixed,7,4);
    end;
function TFreeRotateDialog.Execute(Caption,Units:String):Boolean;
begin
   Self.Caption:=Caption;
   Label3.Caption:=Units;
   Label6.Caption:=Units;
   Label9.Caption:=Units;
   Showmodal;
   Result:=ModalResult=mrOk;
end;

procedure TFreeRotateDialog.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
   if (Key in [#8,'1'..'9','0','-','+',#13]) or (Key=DecimalSeparator) then else key:=#0;
end;

procedure TFreeRotateDialog.Edit1Exit(Sender: TObject);
    begin XValue:=self.XValue; end;
procedure TFreeRotateDialog.Edit1KeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    begin if Key=13 then SelectNext(Activecontrol,True,true); end;
procedure TFreeRotateDialog.Edit2Exit(Sender: TObject);
    begin inherited; YValue:=self.YValue; end;
procedure TFreeRotateDialog.Edit3Exit(Sender: TObject);
    begin ZValue:=self.ZValue; end;
procedure TFreeRotateDialog.OKButtonClick(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TFreeRotateDialog.CancelButtonClick(Sender: TObject);
    begin ModalResult:=mrCancel; end;

end.
