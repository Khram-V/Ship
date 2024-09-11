

unit FreeIntersectLayerDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils,
  Classes,
  Controls,
  Forms,
  Buttons,
  StdCtrls,
  ExtCtrls,
  Freegeometry,
  FreeShipUnit,FreeLanguageSupport;

type

  { TFreeIntersectLayerDialog }

  TFreeIntersectLayerDialog = class(TForm)
    BitBtn1: TSpeedButton;
    BitBtn2: TSpeedButton;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
  private { Private declarations }
    function FGetLayer1: TFreeSubdivisionLayer;
    function FGetLayer2: TFreeSubdivisionLayer;
    procedure UpdateBox2;
  public { Public declarations }
    function Execute(
      Layers: TFasterListTFreeSubdivisionLayer): boolean;
    property Layer1: TFreeSubdivisionLayer
      read FGetLayer1;
    property Layer2: TFreeSubdivisionLayer
      read FGetLayer2;
  end;

var
  FreeIntersectLayerDialog: TFreeIntersectLayerDialog;

implementation

{$IFnDEF FPC}
  {$R *.dfm}

{$ELSE}
  {$R *.lfm}
{$ENDIF}

function TFreeIntersectLayerDialog.FGetLayer1: TFreeSubdivisionLayer;
begin
  Result:=nil;
  if ComboBox1.ItemIndex <> -1 then
    Result:=ComboBox1.Items.Objects[ComboBox1.ItemIndex] as TFreeSubdivisionLayer;
end;

function TFreeIntersectLayerDialog.FGetLayer2: TFreeSubdivisionLayer;
begin
  Result:=nil;
  if ComboBox2.ItemIndex <> -1 then
    Result:=ComboBox2.Items.Objects[ComboBox2.ItemIndex] as TFreeSubdivisionLayer;
end;

procedure TFreeIntersectLayerDialog.UpdateBox2;
var
  I, Ind: integer;
  Layer: TFreeSubdivisionLayer;
begin
  Ind:=ComboBox2.ItemIndex;
  ComboBox2.Items.BeginUpdate;
  ComboBox2.Clear;
  try
    for I:=1 to ComboBox1.Items.Count do
    begin
      Layer:=ComboBox1.Items.Objects[I - 1] as TFreeSubdivisionLayer;
      if I - 1 <> ComboBox1.ItemIndex then
        ComboBox2.Items.AddObject(Layer.Name, Layer);
    end;
  finally
    ComboBox2.Items.EndUpdate;
    if Ind <> -1 then
      ComboBox2.ItemIndex:=Ind
    else
      ComboBox2.ItemIndex:=0;
  end;
end;

function TFreeIntersectLayerDialog.Execute(
  Layers: TFasterListTFreeSubdivisionLayer): boolean;
var
  I: integer;
  Layer: TFreeSubdivisionLayer;
begin
  ComboBox1.Items.BeginUpdate;
  ComboBox1.Clear;
//try
    for I:=1 to Layers.Count do begin
      Layer:=Layers[I - 1];
      ComboBox1.Items.AddObject(Layer.Name,Layer);
    end;
//finally
    ComboBox1.Items.EndUpdate;
    if Combobox1.Items.Count > 0 then ComboBox1.ItemIndex:=0;
    UpdateBox2;
//end;
  ShowTranslatedValues(Self); ShowModal;
  Result:=modalResult = mrOk;
end;

procedure TFreeIntersectLayerDialog.BitBtn1Click(Sender: TObject);
    begin ModalResult:=mrOk; end;
procedure TFreeIntersectLayerDialog.BitBtn2Click(Sender: TObject);
    begin ModalResult:=mrCancel; end;
procedure TFreeIntersectLayerDialog.ComboBox1Change(Sender: TObject);
    begin UpdateBox2; end;

end.
