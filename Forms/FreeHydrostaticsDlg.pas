

unit FreeHydrostaticsDlg;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
  RichEdit,
{$ELSE}
  LCLIntf, LCLType, //
  PrintersDlgs, FreePrinter,
{$ENDIF}
  //Messages,
  SysUtils,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Buttons,
  Printers,
  ExtCtrls;

type

  { TFreeHydrostaticsDialog }

  TFreeHydrostaticsDialog = class(TForm)
    Panel1: TPanel;
    Edit: TMemo;
    Panel22: TPanel;
    ButtonClose: TSpeedButton;
    ButtonPrint: TSpeedButton;
    PrintDialog: TPrintDialog;
    ButtonSave: TSpeedButton;
    SaveDialog: TSaveDialog;
    procedure ButtonCloseClick(Sender: TObject);
    procedure ButtonPrintClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private   { Private declarations }
  public    { Public declarations }
  end;

var
  FreeHydrostaticsDialog: TFreeHydrostaticsDialog;

implementation

{$IFnDEF FPC}
  {$R *.dfm}

{$ELSE}
  {$R *.lfm}
{$ENDIF}

procedure TFreeHydrostaticsDialog.ButtonCloseClick(Sender: TObject);
begin Close; end;

procedure TFreeHydrostaticsDialog.ButtonPrintClick(Sender: TObject);
var
  PrintText: TextFile;
  Str: ansistring;
  I: integer;
begin
  if PrintDialog.Execute then
  begin

    AssignPrn(PrintText);
    Rewrite(PrintText);
    Printer.Canvas.Font.Assign(Edit.Font);
    for I := 1 to Edit.Lines.Count do
    begin
      Str := Edit.Lines[I - 1];
      Writeln(PrintText, Str);
    end;
    CloseFile(PrintText);
  end;
end;

procedure TFreeHydrostaticsDialog.ButtonSaveClick(Sender: TObject);
begin
  if SaveDialog.Execute then
    case SaveDialog.FilterIndex of
      1: Edit.Lines.SaveToFile(ChangeFileExt(SaveDialog.FileName, '.txt'));
        // save as plain text

    end;
end;

procedure TFreeHydrostaticsDialog.FormShow(Sender: TObject);
var
  I: integer;
  S: string;
begin
  I := Edit.Lines.Count;
  S := Edit.Lines.CommaText;                       // Place cursor at beginning
  Edit.CaretPos := TPoint(Point(0, 0));
  I := Edit.Lines.Count;
  S := Edit.Lines.CommaText;                                                    //ShowTranslatedValues(Self);
end;

end.
