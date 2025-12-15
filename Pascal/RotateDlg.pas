unit RotateDlg;
{$MODE Delphi}
interface uses
     SysUtils, Classes,
     Controls, Forms,
     StdCtrls, Buttons,
     ExtCtrls, STypes;

type TRotateDialog = class(TForm)
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

var RotateDialog:TRotateDialog;
implementation
{$R *.lfm}

function TRotateDialog.FGetXValue:Real;
   begin if Edit1.Text='' then result:=0.0
                          else Result:=StrToFloat(Edit1.Text);
   end;
procedure TRotateDialog.FSetXValue(val:Real);
    begin Edit1.Text:=FloatToDec( Val,5 ); //StrF(Val,ffFixed,7,4);
    end;
function TRotateDialog.FGetYValue:Real;
   begin if Edit2.Text='' then result:=0.0
                          else Result:=StrToFloat( Edit2.Text );
   end;
procedure TRotateDialog.FSetYValue(val:Real);
    begin Edit2.Text:=FloatToDec( Val,5 ); //StrF(Val,ffFixed,7,4);
    end;
function TRotateDialog.FGetZValue:Real;
   begin if Edit3.Text='' then Result:=0.0
                          else Result:=StrToFloat(Edit3.Text);
   end;
procedure TRotateDialog.FSetZValue(val:Real);
    begin Edit3.Text:=FloatToDec( Val,5 ); //StrF(Val,ffFixed,7,4);
    end;
function TRotateDialog.Execute(Caption,Units:String):Boolean;
begin
   Self.Caption:=Caption;
   Label3.Caption:=Units;
   Label6.Caption:=Units;
   Label9.Caption:=Units;
   Showmodal;
   Result:=ModalResult=mrOk;
end;

procedure TRotateDialog.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
   if Key in [#8,'1'..'9','0','-','+',#13,'.'] then else key:=#0;
end;

procedure TRotateDialog.Edit1Exit(Sender: TObject);
    begin XValue:=self.XValue; end;
procedure TRotateDialog.Edit1KeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    begin if Key=13 then SelectNext(Activecontrol,True,true); end;
procedure TRotateDialog.Edit2Exit(Sender: TObject);
    begin inherited; YValue:=self.YValue; end;
procedure TRotateDialog.Edit3Exit(Sender: TObject);
    begin ZValue:=self.ZValue; end;
procedure TRotateDialog.OKButtonClick(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TRotateDialog.CancelButtonClick(Sender: TObject);
    begin ModalResult:=mrCancel; end;

end.
