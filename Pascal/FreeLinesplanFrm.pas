
unit FreeLinesplanFrm;
interface
uses Forms,FreeLinesplanFrme;
type TFreeLinesplanForm  = class(TForm)
     LinesplanFrame: TFreeLinesplanFrame;
       procedure FormClose(Sender: TObject; var Action: TCloseAction);
     end;

var FreeLinesplanForm: TFreeLinesplanForm;

implementation
{$R *.lfm}
procedure TFreeLinesplanForm.FormClose(Sender: TObject;var Action: TCloseAction);
    begin LinesplanFrame.FreeShip:=nil;  // Disconnect from FreeShip component;
          Action:=caFree;
    end;

end.
