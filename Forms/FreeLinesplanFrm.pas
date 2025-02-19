unit FreeLinesplanFrm;
{$MODE Delphi}

interface
uses
   Classes,
   Forms,
   FreeGeometry,
   FreeLinesplanFrme;
type
 TFreeLinesplanForm  = class(TForm)                      { TFreeLinesplanForm }
    LinesplanFrame: TFreeLinesplanFrame;
    Viewport: TFreeViewport;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure LinesplanFrameClick(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
 public
    constructor Create(Owner: TComponent); override;
 end;

var FreeLinesplanForm: TFreeLinesplanForm;

implementation
{$R *.lfm}
{ inherited Viewport: TFreeViewport Width = 820 Height = 570 end }

constructor TFreeLinesplanForm.Create(Owner: TComponent);
begin
  inherited Create(Owner);
  Viewport:=LinesplanFrame.Viewport;
  LinesplanFrame.FontSize:=7;
  LinesplanFrame.SpinEdit1.Value:=7;
end;

procedure TFreeLinesplanForm.FormClose(Sender: TObject;var Action: TCloseAction);
begin                                    // Disconnect from FreeShip component;
   LinesplanFrame.FreeShip:=nil; Action:=caFree;
end;
procedure TFreeLinesplanForm.LinesplanFrameClick(Sender: TObject); begin end;

procedure TFreeLinesplanForm.SpinEdit1Change(Sender: TObject);
    begin LinesplanFrame.SpinEdit1Change(Sender); end;
end.
