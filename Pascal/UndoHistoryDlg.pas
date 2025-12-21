
unit UndoHistoryDlg;

interface uses Windows,
     SysUtils,
     Graphics,
     Controls,
     Forms,
     StdCtrls,
     ExtCtrls,
     ShipUnit,
     Geometry,
     Buttons,STypes;

type  
TUndoHistoryDialog = class(TForm)
    Viewport: TViewport;
    Panel,Panel1: TPanel;
    UndoBox: TListBox;
    Ship1: TShip;
    Splitter1: TSplitter;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    procedure UndoBoxClick(Sender: TObject);
    procedure ViewportRequestExtents(Sender: TObject; var Min,Max: Vector);
    procedure ViewportRedraw(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
 public
    function Execute(ship:TShip):Boolean;
end;

var UndoHistoryDialog: TUndoHistoryDialog;

implementation
{$R *.lfm}

function TUndoHistoryDialog.Execute(ship:TShip):Boolean;
var I,Max : Integer;
    Undo : TUndoObject;
    Str  : string;
begin
   UndoBox.Clear;
   UndoBox.Items.BeginUpdate;
   Max:=0;
   for I:=1 to ship.UndoCount do begin
     Undo:=ship.UndoObject[I-1];
     if length(Undo.UndoText)>Max then Max:=Length(Undo.UndoText);
   end;
   inc(Max,2);
   for I:=1 to ship.UndoCount do begin
      Undo:=ship.UndoObject[I-1];
      Str:=ship.UndoObject[I-1].UndoText;
      if Length(Str)>0 then Str[1]:=Upcase(Str[1]);
      While length(Str)<Max do Str:=Str+#32;
      Str:={Str+}'('+Undo.Time+')'{+Undo.UndoText}+Str;
//    Str:=Str+' ('+Undo.Time+')';
      UndoBox.Items.AddObject(Str,Undo);
   end;
   UndoBox.Items.EndUpdate;
   ship1.AddViewport(Viewport);
   UndoBox.ItemIndex:=ship.UndoPosition-1;
   Viewport.Color:=ship.Preferences.ViewportColor;
   Ship1.LoadProject( Undo.Undodata );
   Viewport.ZoomExtents;
   ShowModal;
   Result:=ModalResult=mrOK;
end;
procedure TUndoHistoryDialog.UndoBoxClick(Sender: TObject);
var Undo:TUndoObject;
begin
   if UndoBox.ItemIndex<>-1 then begin
      Undo:=UndoBox.Items.Objects[UndoBox.ItemIndex] as TUndoObject;;
      ship1.LoadProject(Undo.Undodata);
      Viewport.ZoomExtents;
   end;
end;
procedure TUndoHistoryDialog.ViewportRequestExtents(Sender: TObject;var Min, Max: Vector);
    begin ship1.Extents(Min,Max); end;
procedure TUndoHistoryDialog.ViewportRedraw(Sender: TObject);
    begin ship1.DrawToViewport(Viewport); end;
procedure TUndoHistoryDialog.SpeedButton1Click(Sender: TObject);
    begin ModalResult:=mrOK; end;
procedure TUndoHistoryDialog.SpeedButton2Click(Sender: TObject);
    begin ModalResult:=mrCancel; end;
procedure TUndoHistoryDialog.FormResize(Sender: TObject);
    begin Speedbutton1.Left:=Panel.Width-132;
          Speedbutton2.Left:=Speedbutton1.Left+SpeedButton1.Width+2;
    end;
end.
