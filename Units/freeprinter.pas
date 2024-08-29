unit FreePrinter;                    // ...недоразумение какое-то
interface
uses LResources,Printers;
     procedure AssignPrn( var f:TextFile );
implementation
     procedure AssignPrn( var f:TextFile ); begin Assign( f,Printer.FileName ); end;
end.

