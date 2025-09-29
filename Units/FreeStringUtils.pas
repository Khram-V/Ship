unit FreeStringUtils;
{$mode delphi}{$H+}
interface uses SysUtils,LazUTF8;
resourcestring rsTextFile='Text file';
               rsJPEGFiles='JPEG files';
               rsImageFiles='Image files';
               rsBitmapFiles='Bitmap files';
               rsAngle='Angle';                     //UTF8 degree sign   °αβγ
               rsAngles='Angles';
//             rsPointMove='point move';

function Len(s: AnsiString): PtrInt;
function Pos(const SearchForText,SearchInText: AnsiString): PtrInt;             //inline;
function Copy(const s:AnsiString; StartCharIndex,CharCount:PtrInt): AnsiString;  //inline;
procedure Delete(var s: AnsiString; StartCharIndex,CharCount: PtrInt);          //inline;
procedure Insert(const source:AnsiString;var s:AnsiString;StartCharIndex:PtrInt);//inline;
Function ReplaceText(const AText,AFromText,AToText: AnsiString): AnsiString;   // inline;
function UpperCase(const s: AnsiString): AnsiString;
function LowerCase(const s: AnsiString): AnsiString;
//Procedure WriteLn( const Str: AnsiString ); overload;
Function createDialogFilter
       ( FilterName:AnsiString;
         extensions:array of AnsiString;
         NeedsAll:boolean=True ): AnsiString;

implementation
function Len(s: AnsiString): PtrInt; begin result:=UTF8Length(s); end;
function Pos( const SearchForText,SearchInText:AnsiString ): PtrInt;             //inline;
   begin result:=UTF8Pos( SearchForText,SearchInText ); end;
function Copy( const s:AnsiString; StartCharIndex,CharCount:PtrInt):AnsiString;  //inline;
   begin result:=UTF8Copy( s,StartCharIndex,CharCount ); end;
procedure Delete( var s:AnsiString; StartCharIndex,CharCount:PtrInt );           //inline;
    begin UTF8Delete( s,StartCharIndex,CharCount ); end;
procedure Insert(const source:AnsiString;var s:AnsiString;StartCharIndex:PtrInt);//inline;
    begin UTF8Insert( source,s,StartCharIndex ); end;
Function ReplaceText( const AText,AFromText,AToText:AnsiString ): AnsiString;    //inline;
   begin result:=UTF8StringReplace( AText,AFromText,AToText,[rfReplaceAll] ); end;
function UpperCase(const s:AnsiString):AnsiString;begin result:=UTF8UpperCase(s);end;
function LowerCase(const s:AnsiString):AnsiString;begin result:=UTF8LowerCase(s);end;

// creates dialog filter for Windows (case insensitive) or GTK (case sensitive)

function createDialogFilter( FilterName: AnsiString;
                             extensions: array of AnsiString;
                             NeedsAll: boolean=True ): AnsiString;
var I: integer; ext,fltr: AnsiString;
{ function makeGTKfilter( ext:AnsiString ):AnsiString; var I:integer;
  begin Result:='';
  for i:=1 to length(ext) do Result+='['+uppercase(ext[i])+lowercase(ext[i])+']';
  end; }
begin
  ext:=''; fltr:=''; Result:=FilterName+' (';
  for i:=0 to length( extensions )-1 do begin
    ext += '*.'+extensions[i]+';';
    fltr += '*.'+extensions[i]+';';
  end;
  ext:=LeftStr( ext,length(ext)-1 );
  fltr:=LeftStr( fltr,length(fltr)-1 );
  Result += ext+')|'+fltr;
  if NeedsAll then Result += '|All files (*.*)|*.*';
end;

end.

