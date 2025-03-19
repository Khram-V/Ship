{$H+}
unit FreePrinter;                    // ...недоразумение какое-то
interface uses Printers;
procedure AssignPrn( var F:TextFile );
implementation
procedure AssignPrn( var F:TextFile ); begin Assign( F,Printer.FileName ); end;
end.
