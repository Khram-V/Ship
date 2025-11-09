
// Based upon IniLang v 0.9
// Freeware unit for Delphi 4 projects
// by Frédéric Sigonneau <aFas member> 24/04/1999
// e-mail : frederic.sigonneau@wanadoo.fr
// Modified to suit FREEship and adapted to new components

unit FreeLanguageSupport;
{$mode objfpc}{$H+}
interface uses
     LCLType, LazFileUtils,
     SysUtils,Classes,
     stdCtrls,typInfo,
     extCtrls,iniFiles,FreeStringUtils;

type TLanguageIniFile=class( TMemIniFile )               { TLanguageIniFile }
public Name: String;
  constructor Create( const AName:String; const AFileName:String );
end;

var CurrentLanguage: TLanguageIniFile=nil; // Global variable for current language
function LoadLanguage(aName:String; aFileName:String):TLanguageIniFile;overload;
procedure ShowTranslatedValues( Component:TComponent );
function UserString( Index:Integer ): String;

implementation

function LoadLanguage( aName:String; aFileName:String ):TLanguageIniFile;
begin if aName<>'' then                  // leave with default English language
      if FileExistsUTF8( aFilename ) then begin
        if CurrentLanguage<>nil then CurrentLanguage.Free;
        CurrentLanguage:=TLanguageIniFile.create( aName,aFilename );
        if CurrentLanguage<>nil then begin
          aName:=CurrentLanguage.readString( 'Translation','Author','' );
          if aName='' then begin CurrentLanguage.Free; CurrentLanguage:=nil; end;
        end;
      end;
      if CurrentLanguage<>nil then writeln( aName ); Result:=CurrentLanguage;
end;

function UserString( Index:Integer ): String;   // == Languages\Russian.ini
{$I Russian.inc}        // const U: array of record L:Word; C:String; end =
  var Val: String; I: Integer;
begin Result:='';
   if CurrentLanguage=nil then begin  // при отсутствии текстовых строк в файле
     for I:=0 to Length( U )*2-1 do   // [216++..]
     if U[I].L=Index then begin Result:=U[I].C; break; end;
   end else begin Val:=IntToStr( Index );
     Result:=CurrentLanguage.readString
           ( 'User',Copy( 'User0000',1,8-len( Val ) )+Val,'' );
   end;
end;

// TODO Replace custom translations with standard.
{ Translates the forms you choose in the language called in ini.
  Only created forms are translated with ShowTranslatedValues. Call it in the
  onShow event of your main form whith names of all automatically created forms
  at the start-up of your application in the TC parameter.
  In runtime,call it when you create dynamically a form. See demo for a sample
}
procedure ShowTranslatedValues(Component:TComponent);
var I,J,Index : Integer;
    Comp      : TComponent;
    CmbBox    : TComboBox;
    Str,Tmp   : TTranslateString;

// Assign the value value to prop property of comp component
   procedure setProp( comp: TComponent; {const } prop,value: String );
     var ppi:PPropInfo;
     begin if value<>'' then begin ppi:=getPropInfo( comp.classInfo,prop );
              if ppi<>nil then setStrProp( comp,ppi,value ); end; end;
begin
   if (CurrentLanguage=nil) or (Component=nil) then exit;
// if (CurrentLanguage.Name='Russian') then exit;
   with CurrentLanguage do begin
      Str:=readString( Component.Classname,Component.Classname+'.Caption','' );
      if Str<>'' then setProp( Component,'Caption',Str );
      for I:=0 to Component.componentCount-1 do begin comp:=Component.Components[i];
         Str:=readString(Component.Classname,Component.Classname+'.'+comp.name+'.Caption','');
         if Str<>'' then setProp(comp,'Caption',Str);
         Str:=readString(Component.ClassName,Component.Classname+'.'+comp.name+'.Hint','');
         if Str<>'' then setProp(comp,'Hint',Str);
         if comp is TCustomMemo then begin
            for J:=0 to TCustomMemo(comp).lines.count-1 do begin
               Str:=readString(Component.classname,Component.classname+'.'+comp.name+'.lines['+intToStr(J)+']','fsdef');
               //in TMemo or TRichEdit,you may have to leave some lines empty
               if Str<>'fsdef' then TCustomMemo(comp).lines[J]:=Str;
            end;
         end else if comp is TRadioGroup then begin
            for J:=0 to TRadioGroup(comp).items.count-1 do begin
               Str:=readString(Component.classname,Component.classname+'.'+comp.name+'.items['+intToStr(J)+']','');
               if Str<>'' then TRadioGroup(comp).items[J]:=Str;
            end;
         end else if comp is TComboBox then begin
            CmbBox:=TComboBox(comp);
            Index:=CmbBox.ItemIndex;
            CmbBox.Items.BeginUpdate;
            for J:=0 to CmbBox.items.count-1 do begin
              Tmp:=Component.classname+'.'+CmbBox.name+'.items['+IntToStr(J)+']';
              Str:=readString(Component.classname,Tmp,'');
              if Str<>'' then CmbBox.items[J]:=Str;
            end;
            CmbBox.Items.EndUpdate;
            CmbBox.ItemIndex:=Index;
            if (Index>-1) and (Index<CmbBox.items.count)
               then CmbBox.Text:=TComboBox(comp).Items[Index];
         end;
      end;
   end;
end;

{ TLanguageIniFile }

constructor TLanguageIniFile.Create(const AName: String; const AFileName: String);
      begin Name:=aName; inherited Create( AFileName,false ); end;
{
initialization
   CurrentLanguage:=nil;
finalization
   if CurrentLanguage<>nil then CurrentLanguage.Free;
}
end.

