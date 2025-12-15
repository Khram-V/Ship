
unit ExtrudeDlg;
{$MODE Delphi}
interface uses
     SysUtils,     Classes,
     Controls,     Forms,
     StdCtrls,     Buttons,
     ExtCtrls,     STypes;

type TExtrudeDialog = class(TForm)
    Panel1,Panel2,Panel3: TPanel;
    Label1,Label2,Label4,_Label3,_Label6,_Label9: TLabel;
    Edit1,Edit2,Edit3: TEdit;
    BitBtn1,BitBtn2: TSpeedButton;
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
    procedure Edit1Exit(Sender: TObject);
    procedure Edit1KeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    procedure Edit2Exit(Sender: TObject);
    procedure Edit3Exit(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure Edit2KeyPress(Sender: TObject; var Key: Char);
    procedure Edit3KeyPress(Sender: TObject; var Key: Char);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    private
      function FGetXValue:Real;
      procedure FSetXValue(val:Real);
      function FGetYValue:Real;
      procedure FSetYValue(val:Real);
      function FGetZValue:Real;
      procedure FSetZValue(val:Real);
    public
      function Execute(Str:string):Boolean;
      property XValue:Real read FGetXValue write FSetXValue;
      property YValue:Real read FGetYValue write FSetYValue;
      property ZValue:Real read FGetZValue write FSetZValue;
   end;

var ExtrudeDialog : TExtrudeDialog;

implementation
{$R *.lfm}

function TExtrudeDialog.FGetXValue:Real;
   begin if Edit1.Text='' then result:=0.0
                          else Result:=StrToFloat(Edit1.Text);
   end;
procedure TExtrudeDialog.FSetXValue(val:Real);
    begin Edit1.Text:=FloatToDec(Val,4); end;

function TExtrudeDialog.FGetYValue:Real;
   begin if Edit2.Text='' then result:=0.0
                          else Result:=StrToFloat(Edit2.Text);
   end;
procedure TExtrudeDialog.FSetYValue(val:Real);
    begin Edit2.Text:=FloatToDec(Val,4); end;
function TExtrudeDialog.FGetZValue:Real;
   begin if Edit3.Text='' then result:=0.0
                          else Result:=StrToFloat(Edit3.Text);
   end;
procedure TExtrudeDialog.FSetZValue(val:Real);
    begin Edit3.Text:=FloatToDec(Val,4); end;

function TExtrudeDialog.Execute(Str:string):Boolean;
begin
   _label3.Caption:=Str;
   _label6.Caption:=Str;
   _label9.Caption:=Str;
   Showmodal;
   Result:=ModalResult=mrOk;
end;

procedure TExtrudeDialog.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
   if Key in [#8,'1'..'9','0','-','+',#13,'.'] then else key:=#0;
   if Key=#13 then Edit1Exit(self);
end;

procedure TExtrudeDialog.Edit1Exit(Sender: TObject);
    begin XValue:=self.XValue; end;

procedure TExtrudeDialog.Edit1KeyDown(Sender: TObject; var Key: Word;Shift: TShiftState);
    begin if Key=13 then SelectNext(Activecontrol,True,true); end;
procedure TExtrudeDialog.Edit2Exit(Sender: TObject);
    begin inherited; YValue:=self.YValue; end;
procedure TExtrudeDialog.Edit3Exit(Sender: TObject);
    begin ZValue:=self.ZValue; end;
procedure TExtrudeDialog.OKButtonClick(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TExtrudeDialog.CancelButtonClick(Sender: TObject);
    begin ModalResult:=mrCancel; end;
procedure TExtrudeDialog.Edit2KeyPress(Sender: TObject; var Key: Char);
begin
   if Key in [#8,'1'..'9','0','-','+',#13,'.'] then else key:=#0;
   if Key=#13 then Edit2Exit(self);
end;
procedure TExtrudeDialog.Edit3KeyPress(Sender: TObject; var Key: Char);
begin
   if Key in [#8,'1'..'9','0','-','+',#13,'.'] then else key:=#0;
   if Key=#13 then Edit3Exit(self);
end;
procedure TExtrudeDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrOK; end;
procedure TExtrudeDialog.BitBtn2Click(Sender: TObject);
    begin ModalResult:=mrCancel; end;

end.
