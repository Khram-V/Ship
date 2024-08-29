
unit FreeLinesplanFrm;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, //
{$ENDIF}
  //Messages,
   SysUtils,
   Variants,
   Classes,
   Controls,
   Forms,
   Dialogs,
   FreeGeometry,
   FreeLinesplanFrme;

type

{ TFreeLinesplanForm }

 TFreeLinesplanForm  = class(TForm)
    LinesplanFrame: TFreeLinesplanFrame;
    Viewport: TFreeViewport;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure LinesplanFrameClick(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
 private   { Private declarations }
 public    { Public declarations }
    constructor Create(Owner: TComponent); override;
 end;

var FreeLinesplanForm: TFreeLinesplanForm;

implementation

{$IFnDEF FPC}
  {$R *.dfm}
{$ELSE}
  {$R *.lfm}
{$ENDIF}

{
inherited Viewport: TFreeViewport
  Width = 820
  Height = 570
end
}

constructor TFreeLinesplanForm.Create(Owner: TComponent);
begin
  inherited Create(Owner);
  Viewport:=LinesplanFrame.Viewport;
  LinesplanFrame.FontSize:=7;
  LinesplanFrame.SpinEdit1.Value:=7;
end;

procedure TFreeLinesplanForm.FormClose(Sender: TObject;var Action: TCloseAction);
begin
   // Disconnect from FreeShip component;
   LinesplanFrame.FreeShip:=nil;
   Action:=caFree;
end;{TFreeLinesplanForm.FormClose}

procedure TFreeLinesplanForm.LinesplanFrameClick(Sender: TObject);
begin

end;

procedure TFreeLinesplanForm.SpinEdit1Change(Sender: TObject);
begin
  LinesplanFrame.SpinEdit1Change(Sender);
end;

end.
