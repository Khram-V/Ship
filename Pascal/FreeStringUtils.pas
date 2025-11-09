unit FreeStringUtils;
{$mode delphi}{$H+}
interface uses SysUtils,LazUTF8;
resourcestring rsJPEGFiles='JPEG files';
               rsAngle='Angle';                     // UTF8 degree sign   °αβγ
               rsAngles='Angles';
{              rsPointMove='point move';
               rsTextFile='Text file';
               rsImageFiles='Image files';
               rsBitmapFiles='Bitmap files';
}
function Len(s: String): PtrInt;
function Pos(const SearchForText,SearchInText: String): PtrInt;             //inline;
function Copy(const s:String; StartCharIndex,CharCount:PtrInt): String;  //inline;
procedure Delete(var s: String; StartCharIndex,CharCount: PtrInt);          //inline;
procedure Insert(const source:String;var s:String;StartCharIndex:PtrInt);//inline;
Function ReplaceText(const AText,AFromText,AToText: String): String;   // inline;
function UpperCase(const s: String): String;
function LowerCase(const s: String): String;
{
Procedure WriteLn( const Str: String ); overload;
Function createDialogFilter
       ( FilterName:String;
         extensions:array of String;
         NeedsAll:boolean=True ): String;
}
implementation
function Len(s: String): PtrInt; begin result:=UTF8Length(s); end;
function Pos( const SearchForText,SearchInText:String ): PtrInt;             //inline;
   begin result:=UTF8Pos( SearchForText,SearchInText ); end;
function Copy( const s:String; StartCharIndex,CharCount:PtrInt):String;  //inline;
   begin result:=UTF8Copy( s,StartCharIndex,CharCount ); end;
procedure Delete( var s:String; StartCharIndex,CharCount:PtrInt );           //inline;
    begin UTF8Delete( s,StartCharIndex,CharCount ); end;
procedure Insert(const source:String;var s:String;StartCharIndex:PtrInt);//inline;
    begin UTF8Insert( source,s,StartCharIndex ); end;
Function ReplaceText( const AText,AFromText,AToText:String ): String;    //inline;
   begin result:=UTF8StringReplace( AText,AFromText,AToText,[rfReplaceAll] ); end;
function UpperCase(const s:String):String;begin result:=UTF8UpperCase(s);end;
function LowerCase(const s:String):String;begin result:=UTF8LowerCase(s);end;
(*
// creates dialog filter for Windows (case insensitive) or GTK (case sensitive)
function createDialogFilter( FilterName: String;
                             extensions: array of String;
                             NeedsAll: boolean=True ): String;
var I: integer; ext,fltr: String;
{ function makeGTKfilter( ext:String ):String; var I:integer;
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
  if NeedsAll then Result += '|All files ( *.* )|*.*';
end;
*)
end.

