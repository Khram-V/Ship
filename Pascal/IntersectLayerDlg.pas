unit IntersectLayerDlg;
interface uses
    Forms,
    Buttons,
    Controls,
    ExtCtrls,
    FasterList, Geometry, StdCtrls;
type 
TIntersectLayerDialog = class(TForm)
    Label1,Label2: TLabel;
    Panel1,Panel2,Panel3: TPanel;
    BitBtn1,BitBtn2: TSpeedButton;
    ComboBox1,ComboBox2: TComboBox;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
 private
    function FGetLayer1:SLayer;
    function FGetLayer2:SLayer;
    procedure UpdateBox2;
  public
    function Execute(Layers:TFasterList):Boolean;
    property Layer1: SLayer read FGetLayer1;
    property Layer2: SLayer read FGetLayer2;
end;

var IntersectLayerDialog: TIntersectLayerDialog;

implementation
  {$R *.lfm}

function TIntersectLayerDialog.FGetLayer1:SLayer;
begin Result:=nil;
  if ComboBox1.Itemindex<>-1 then
     Result:=ComboBox1.Items.Objects[ComboBox1.ItemIndex] as SLayer;
end;

function TIntersectLayerDialog.FGetLayer2:SLayer;
begin Result:=nil;
  if ComboBox2.Itemindex<>-1 then
     Result:=ComboBox2.Items.Objects[ComboBox2.ItemIndex] as SLayer;
end;

procedure TIntersectLayerDialog.UpdateBox2;
var I,Ind: Integer;
    Layer: SLayer;
begin
   Ind:=ComboBox2.ItemIndex;
   ComboBox2.Items.BeginUpdate;
   ComboBox2.Clear;
   for I:=1 to ComboBox1.Items.Count do begin
       Layer:=ComboBox1.Items.Objects[I-1] as SLayer;
       if I-1<>ComboBox1.ItemIndex then ComboBox2.Items.AddObject(Layer.Name,Layer);
   end;
   ComboBox2.Items.EndUpdate;
   if Ind<>-1 then ComboBox2.ItemIndex:=Ind
              else ComboBox2.ItemIndex:=0;
end;

function TIntersectLayerDialog.Execute(Layers:TFasterList):Boolean;
var I: Integer; Layer: SLayer;
begin
   ComboBox1.Items.BeginUpdate;
   ComboBox1.Clear;
   For I:=1 to Layers.Count do begin
       Layer:=Layers[I-1];
       ComboBox1.Items.AddObject(Layer.Name,Layer);
   end;
   ComboBox1.Items.EndUpdate;
   if Combobox1.Items.Count>0 then ComboBox1.ItemIndex:=0;
   UpdateBox2;
   ShowModal;
   Result:=modalResult=mrOk;
end;

procedure TIntersectLayerDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrOK; end;
procedure TIntersectLayerDialog.BitBtn2Click(Sender: TObject);
    begin ModalResult:=mrCancel; end;
procedure TIntersectLayerDialog.ComboBox1Change(Sender: TObject);
    begin UpdateBox2; end;

end.
