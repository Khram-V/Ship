unit FreeControlPointFrm;
{$MODE Delphi}{$H+}
interface uses
  SysUtils, Classes,
  Graphics, Controls,
  Forms,    Dialogs,
  Math,     StdCtrls, StrUtils,
  Buttons,  ExtCtrls,
  FreeTypes,FreeGeometry,FreeStringUtils,FreeLanguageSupport;
type
{TEntryMethod = ( emNone, emTyping, emArrowKeys, emMouse, emPaste );
TFormStyle=(fsNormal,fsMDIChild,fsMDIForm,fsStayOnTop,fsSplash,fsSystemStayOnTop);
TFormBorderStyle=(bsNone,bsSingle,bsSizeable,bsDialog,bsToolWindow,bsSizeToolWin);
}

  TFreeControlPointForm=class( TForm )
    SpeedButtonRemoveLinearConstraint,SpeedButtonRemoveAnchorPoint: TSpeedButton;
    EditLinearConstraintA,EditAnchorPoint,EditLinearConstraintB: TEdit;
    LabelInf,LabelX,LabelY,LabelZ:             TLabel;
    Panel1,Panel2,Panel4,Panel5,Panel6,Panel7,Panel8: TPanel;
//  EditDistance,EditAngles:                          TFloatSpinEdit;
    GroupBoxLinearConstraint,GroupBoxAnchorConstraint: TGroupBox;
    SpeedButton4:TSpeedButton; Edit1:TEdit; SpeedButton1:TSpeedButton; LabelA:Tlabel;
    SpeedButton5:TSpeedButton; Edit2:TEdit; SpeedButton2:TSpeedButton; LabelB:Tlabel;
    SpeedButton6:TSpeedButton; Edit3:TEdit; SpeedButton3:TSpeedButton; LabelG:Tlabel;
    CheckBoxAnchorHard,CheckBoxCorner: TCheckBox;

    Function Change( Text: String; Comp: Integer ): String; // Comp: 0:X,1:Y,2:Z
    procedure Edit1Exit(Sender:TObject); procedure Edit1KeyPress(Sender:TObject; var Key:Char);
    procedure Edit2Exit(Sender:TObject); procedure Edit2KeyPress(Sender:TObject; var Key:Char);
    procedure Edit3Exit(Sender:TObject); procedure Edit3KeyPress(Sender:TObject; var Key:Char);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
    procedure CheckBoxCornerChange(Sender: TObject);
    procedure OrdinateEditorEnter(Sender: TObject);  // только в
    procedure OrdinateEditorExit(Sender: TObject);   // CheckBoxCorner
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CheckBoxAnchorHardChange(Sender: TObject);
    procedure SpeedButtonRemoveAnchorPointClick(Sender: TObject);
    procedure SpeedButtonRemoveLinearConstraintClick(Sender: TObject);
   private
    FActiveControlPoint : TFreeSubdivisionControlPoint;
    FSkipCheckbox1OnClick : boolean;
    EnteredControl: TControl;
    procedure FSetActiveControlPoint( Val:TFreeSubdivisionControlPoint );
    procedure FSetActiveControlPointCorner( isCorner: boolean );
   public
    procedure Reload;
    property ActiveControlPoint: TFreeSubdivisionControlPoint
                            read FActiveControlPoint
                           write FSetActiveControlPoint;
end;
function ConvertCoordinate( Coord: String; OldCoord: TFloatType ): TFloatType;

var FreeControlPointForm: TFreeControlPointForm;

implementation uses FreeShipUnit;
{$R *.lfm}

procedure TFreeControlPointForm.FSetActiveControlPoint
  ( Val:TFreeSubdivisionControlPoint );
var I,N,Npoi: Integer; BCol,FCol: TColor; Str: String=''; Len: TFloatType;
    Angle,C0,CN,C1,Cp,Ci: T3DVector;
    IsPointDifferent: boolean;
begin
  IsPointDifferent:=FActiveControlPoint<>Val;
  FActiveControlPoint:=Val;
//FActiveControlPointChanging:=true;
  if ActiveControlPoint=nil then begin Visible:=False; exit; end;       // ! убрать ?
{ if Ship.Surface.SelectedControlPoints.IndexOf(ActiveControlPoint)=-1 then
     Ship.Surface.SelectedControlPoints.Add( ActiveControlPoint ); }

  Visible:=True;
  C0:=FActiveControlPoint.Coordinate;
  ShowTranslatedValues( Self );
  Self.Caption:=UserString(1675)+'['+IntToStr(FActiveControlPoint.Id )+']: '
         +' ( '+FloatToDec(C0.X,3)
         + ', '+FloatToDec(C0.Y,3)
         + ', '+FloatToDec(C0.Z,3)
         +' ) из '+IntToStr( Ship.NumberOfSelectedControlPoints );
  Npoi:=Ship.NumberOfSelectedControlPoints-1;

  if Npoi>=0 then begin                                // крайние точки
     C0:=Ship.SelectedControlPoint[0].Coordinate;      // из всего списка
     CN:=Ship.SelectedControlPoint[Npoi].Coordinate;;  // избранных
     if NPoi>0 then Angle:=CN-C0 else Angle:=C0;       // от первой к последней
     Str:=' '+Userstring(236)+' [1..'+inttostr(NPoi+1)+'] = '
             +FloatToDec( Abs( Angle ),4 );
     Angle:=Angles( Angle );                           // и направление
     if Npoi>=2 then begin Len:=0.0;                   // длина всего пути
       for I:=1 to Npoi do begin
         Cp:=Ship.SelectedControlPoint[i-1].Coordinate;
         Ci:=Ship.SelectedControlPoint[i].Coordinate;
         Len:=Len+Abs( Cp-Ci );
       end;
       Str:=Str+'.  '+UserString(1493)+' = '+FloatToDec( Len,4 );
    end;
  end;
  LabelA.Caption:=' α  '+FloatToDec( Angle.x,2 )+' °'; // Alpha;
  LabelB.Caption:=' β  '+FloatToDec( Angle.y,2 )+' °'; // Beta;
  LabelG.Caption:=' γ  '+FloatToDec( Angle.z,2 )+' °'; // Gamma;
  LabelInf.Caption:=Str;
  Edit1.Text:=FloatToDec( FActiveControlPoint.Coordinate.X,4 );
  Edit2.Text:=FloatToDec( FActiveControlPoint.Coordinate.Y,4 );
  Edit3.Text:=FloatToDec( FActiveControlPoint.Coordinate.Z,4 );
  if IsPointDifferent then begin
     if (CheckBoxCorner.Checked<>(FActiveControlPoint.VertexType=svCorner))
     then begin
       FSkipCheckbox1OnClick:=true;
       CheckBoxCorner.Checked:=FActiveControlPoint.VertexType=svCorner;
       FSkipCheckbox1OnClick:=false;
     end;           // Count the number of crease edges connected to this point
     N:=0;
     for I:=1 to FActiveControlPoint.NumberOfEdges do
              if FActiveControlPoint.Edge[I-1].Crease then inc( N );
     CheckBoxCorner.Enabled:=((N>0) and (N<3) and (not Val.Locked)); // points with more than two crease edges must always be a corner
     Edit1.Enabled:=not Val.Locked;
     Edit2.Enabled:=not Val.Locked;
     Edit3.Enabled:=not Val.Locked;
     if Val.Locked then begin BCol:=clBtnFace; FCol:=clDkgray; end
                   else begin BCol:=clWindow; FCol:=clBlack; end;
     if Edit1.Color<>BCol then Edit1.Color:=BCol;
     if Edit1.Font.Color<>FCol then Edit1.Font.Color:=FCol;
     if Edit2.Color<>BCol then Edit2.Color:=BCol;
     if Edit2.Font.Color<>FCol then Edit2.Font.Color:=FCol;
     if Edit3.Color<>BCol then Edit3.Color:=BCol;
     if Edit3.Font.Color<>FCol then Edit3.Font.Color:=FCol;
     if (FActiveControlPoint.LinearConstraintPointA<>nil)
     and (FActiveControlPoint.LinearConstraintPointB<>nil) then begin
         GroupBoxLinearConstraint.Visible:=true;
         EditLinearConstraintA.Text:='';
         EditLinearConstraintB.Text:='';
         if (FActiveControlPoint.LinearConstraintPointA<>nil)
         then EditLinearConstraintA.Text:=UserString(1675)
             +'['+IntToStr(FActiveControlPoint.LinearConstraintPointA.Id)+']';
         if (FActiveControlPoint.LinearConstraintPointB<>nil)
         then EditLinearConstraintB.Text:=UserString(1675)
             +'['+IntToStr(FActiveControlPoint.LinearConstraintPointB.Id)+']';
     end else GroupBoxLinearConstraint.Visible:=false;
     if (FActiveControlPoint.AnchorPoint<>nil) then begin
         GroupBoxAnchorConstraint.Visible:=true;
         CheckBoxAnchorHard.Checked:=FActiveControlPoint.IsAnchorHard;
         EditAnchorPoint.Text:='';
         EditAnchorPoint.Text:=UserString(1675)+'['+IntToStr(FActiveControlPoint.AnchorPoint.Id)+']';
     end else GroupBoxAnchorConstraint.Visible:=false;
  end;     // FActiveControlPointChanging:=false;
end;
procedure TFreeControlPointForm.Reload;
    begin FSetActiveControlPoint( ActiveControlPoint ); end;
procedure TFreeControlPointForm.CheckBoxCornerChange( Sender: TObject );
    begin if FSkipCheckbox1OnClick then exit;
             FSetActiveControlPointCorner( CheckBoxCorner.Checked );
    end;
procedure TFreeControlPointForm.OrdinateEditorEnter(Sender: TObject);
    begin EnteredControl:=Sender as TControl;
//        FActiveControlPointChanging:=false;
//        FPointEditorChanging:=false;  //EntryMethod:=emNone;
   end;
procedure TFreeControlPointForm.OrdinateEditorExit(Sender: TObject);
    begin EnteredControl:=nil; // EntryMethod:=emNone;
    end;
procedure TFreeControlPointForm.CheckBoxAnchorHardChange(Sender: TObject);
    begin ActiveControlPoint.IsAnchorHard:=CheckBoxAnchorHard.Checked;
    end;
procedure TFreeControlPointForm.FSetActiveControlPointCorner(isCorner: boolean);
var I,N: Integer; OldType: TFreeVertexType; Undo: TFreeUndoObject;
begin
  if (ActiveControlPoint<>nil)
  and (isCorner<>(ActiveControlPoint.VertexType=svCorner)) then begin // Count the number of crease edges connected to this point
    OldType:=ActiveControlPoint.VertexType;
    Undo:=Ship.Edit.CreateUndoObject( 'Corner',false );
    if (ActiveControlPoint.Vertextype=svCorner) and (not isCorner) then begin
      N:=0;                        // Count the number of incident crease edges
      for I:=1 to ActiveControlPoint.NumberOfEdges do
      if FActiveControlPoint.Edge[I-1].Crease then inc( N );
      Case N of
        0 : ActiveControlPoint.Vertextype:=svRegular;
        1 : ActiveControlPoint.VertexType:=svDart;
        2 : ActiveControlPoint.VertexType:=svCrease; // points with more than two crease edges must always be a corner
      end;
    end;
    if (ActiveControlPoint.Vertextype<>svCorner) and (isCorner)
    then ActiveControlPoint.VertexType:=svCorner;
    if ActiveControlPoint.VertexType<>OldType then begin Undo.Accept;
       Ship.Built:=False;
       Ship.FileChanged:=True;
       Ship.Redraw;
       ActiveControlPoint:=ActiveControlPoint;
    end else Undo.Delete;
  end;
end;
procedure TFreeControlPointForm.FormActivate( Sender: TObject );
    begin FSkipCheckbox1OnClick:=false; end;
procedure TFreeControlPointForm.FormCreate( Sender: TObject ); begin end;
procedure TFreeControlPointForm.FormShow(Sender: TObject);
    begin Caption:=Caption; end;
procedure TFreeControlPointForm.SpeedButtonRemoveAnchorPointClick( Sender: TObject );
begin if ActiveControlPoint<>nil then begin
        Ship.Edit.CreateUndoObject( 'AncDel',True );
        ActiveControlPoint.AnchorPoint:=nil;
        EditAnchorPoint.Text:='';
        Ship.FileChanged:=True;
        Ship.Redraw;
        ActiveControlPoint:=ActiveControlPoint;
        GroupBoxAnchorConstraint.Visible:=false; end;
end;
procedure TFreeControlPointForm.SpeedButtonRemoveLinearConstraintClick( Sender: TObject );
begin if ActiveControlPoint<>nil then begin
        Ship.Edit.CreateUndoObject( 'LineDel',True );
        ActiveControlPoint.SetLinearConstraint(nil,nil);
        EditLinearConstraintA.Text:='';
        EditLinearConstraintB.Text:='';
        Ship.FileChanged:=True;
        Ship.Redraw;
        ActiveControlPoint:=ActiveControlPoint;
        GroupBoxLinearConstraint.visible:=false; end;
end;

procedure TFreeControlPointForm.Edit1KeyPress( Sender: TObject;var Key: Char );
begin if (Key in [#8,'1'..'9','0','-','@',#13])
      or ((Ship.ProjectSettings.ProjectUnits=fuImperial) and (Key='+'))
      or (Key=FormatSettings.DecimalSeparator) then else key:=#0;
      if Key=#13 then Edit1Exit( Self ) else
      if not Assigned( Edit1.OnEditingDone ) then Edit1.OnEditingDone:=Edit1Exit;
end;
procedure TFreeControlPointForm.Edit2KeyPress( Sender: TObject;var Key: Char );
begin if (Key in [#8,'1'..'9','0','-','@',#13])
      or ((Ship.ProjectSettings.ProjectUnits=fuImperial) and (Key='+'))
      or (Key=FormatSettings.DecimalSeparator) then else key:=#0;
      if Key=#13 then Edit2Exit( Self ) else
      if not Assigned( Edit2.OnEditingDone ) then Edit2.OnEditingDone:=Edit2Exit;
end;
procedure TFreeControlPointForm.Edit3KeyPress( Sender: TObject; var Key: Char );
begin if (Key in [#8,'1'..'9','0','-','@',#13])
      or ((Ship.ProjectSettings.ProjectUnits=fuImperial) and (Key='+'))
      or (Key=FormatSettings.DecimalSeparator) then else key:=#0;
      if Key=#13 then Edit3Exit( Self ) else
      if not Assigned( Edit3.OnEditingDone ) then Edit3.OnEditingDone:=Edit3Exit;
end;

Var IdUndo: Integer=1;

Function TFreeControlPointForm.Change( Text: String; Comp: Integer ):String; // Comp: 0:X,1:Y,2:Z
var Saved: Boolean; I: Integer;
    Val,R: TFloatType; P: T3DVector;  Undo: TFreeUndoObject;
begin
  Edit1.OnEditingDone:=nil; Result:=Text;  writeln( Text,'[',Comp,'] ',' N=',Ship.NumberOfSelectedControlPoints );
  Edit2.OnEditingDone:=nil; Saved:=false; // сброс повторных прерывений
  Edit3.OnEditingDone:=nil; if ActiveControlPoint=nil then exit;
  P:=ActiveControlPoint.Coordinate;
  if Comp=2 then R:=P.Z else if Comp=1 then R:=P.Y else R:=P.X;
  Val:=ConvertCoordinate( Text,R );
  Result:=FloatToDec( Val,4 );
  Undo:=Ship.Edit.CreateUndoObject('Coord_'+inttostr(IdUndo),False); Inc(IdUndo);
  for I:=Ship.NumberOfSelectedControlPoints-1 downto 0 do begin
     P:=Ship.SelectedControlPoint[I].Coordinate;
     if Comp=2 then R:=P.Z else if Comp=1 then R:=P.Y else R:=P.X;
     Val:=ConvertCoordinate( Text,R );
     if abs( R-Val )>1e-5 then begin Saved:=true;
       if Comp=2 then P.Z:=Val else if Comp=1 then P.Y:=Val else P.X:=Val;
       Ship.SelectedControlPoint[I].Coordinate:=P;
     end;
  end;
  if not Saved then Undo.Delete else begin Undo.Accept;
    ActiveControlPoint:=ActiveControlPoint;
    Ship.FileChanged:=True;
    Ship.Redraw;
  end;
end;
procedure TFreeControlPointForm.Edit1Exit( Sender: TObject ); // OnEditingDone = Edit1Exit
    begin Edit1.Text:=Change( Edit1.Text,0 ); end;           ///  или OnExit = ???
procedure TFreeControlPointForm.Edit2Exit( Sender: TObject );
    begin Edit2.Text:=Change( Edit2.Text,1 ); end;
procedure TFreeControlPointForm.Edit3Exit( Sender: TObject );
    begin Edit3.Text:=Change( Edit3.Text,2 ); end;

procedure TFreeControlPointForm.SpeedButton1Click(Sender: TObject);
begin Edit1.Text:=Change('@'+FloatToDec(Ship.Visibility.CursorIncrement,4),0); end;
procedure TFreeControlPointForm.SpeedButton2Click(Sender: TObject);
begin Edit2.Text:=Change('@'+FloatToDec(Ship.Visibility.CursorIncrement,4),1); end;
procedure TFreeControlPointForm.SpeedButton3Click(Sender: TObject);
begin Edit3.Text:=Change('@'+FloatToDec(Ship.Visibility.CursorIncrement,4),2); end;
procedure TFreeControlPointForm.SpeedButton4Click(Sender: TObject);
begin Edit1.Text:=Change('@'+FloatToDec(-Ship.Visibility.CursorIncrement,4),0); end;
procedure TFreeControlPointForm.SpeedButton5Click(Sender: TObject);
begin Edit2.Text:=Change('@'+FloatToDec(-Ship.Visibility.CursorIncrement,4),1); end;
procedure TFreeControlPointForm.SpeedButton6Click(Sender: TObject);
begin Edit3.Text:=Change('@'+FloatToDec(-Ship.Visibility.CursorIncrement,4),2); end;

{═══════════════════════════════════════════════════════════════════════}
{ parses input "Coord" and and returns the new value of a coordinate    }
{ if first character of input is (RelIdentifier - currently '@')        }
{    then the input value is added to the old value "OldCoord".         }
{ if the first character of the value is '-',                           }
{    then the remainder is treated as a negative value                  }
{ if the remainding value contains ONE '-'                              }
{    then the part after that '-' is considered as a fraction of a unit }
{    The size of the fraction is const. "InchFractions"                 }

function ConvertCoordinate( Coord: String; OldCoord: TFloatType ): TFloatType;
var
  myString: String;  myFracPos: Integer;
  myFactor,myOldValue,myWholeFeet,myWholeInch,myFracInch: TFloatType;
const RelIdentifier: String='@'; InchFractions: TFloatType=8;
begin
  myString:=Coord;
  myFactor:=1.0;
  myOldValue:=OldCoord;
  myWholeFeet:=0.0;
  myWholeInch:=0.0;
  myFracInch:=0.0;
  if LeftStr(myString,1)=RelIdentifier then begin        // get rid of the '@'
    myString:= MidStr(myString,2,255);
    if Pos(RelIdentifier,myString)>0 then myString:='0'; // make sure not to have another '@' (and a 0 doesn't hurt)
  end else myOldValue:= 0;  // we have a new value now, so don't add the old one!
  if LeftStr(myString, 1)='-' then begin                // get rid of the minus
    myFactor:=-1.0;
    myString:=MidStr(myString,2,255);
  end;
  myFracPos:=Pos('-',myString);
  if myFracPos>0 then begin      // check whether we have imperial input format
    if myFracPos>1 then begin    // check whether there is an whole feet value
      myWholeFeet:=StrToFloat(LeftStr(myString,myFracPos-1));
      myString:=MidStr(myString,myFracPos+1,255);
    end;
    myFracPos:=Pos('-',myString); // is there a second "-", i.e. do we have also fractional inches?
    if myFracPos>0 then begin
      if myFracPos>1 then begin   // check whether there is an whole inch value
        myWholeInch:=StrToFloat(LeftStr(myString,myFracPos-1));
        myString:=MidStr(myString,myFracPos,255);
      end; // new: check whether there is a + or a - to add or subtract a half fraction
      myString:= MidStr(myString,2,255);
      if RightStr(myString,1)='-' then myFracInch:=StrToFloat(LeftStr(myString,Pos('-',myString)-1))-0.5 else
      if RightStr(myString,1)='+' then myFracInch:=StrToFloat(LeftStr(myString,Pos('+',myString)-1))+0.5 else
                                       myFracInch:=StrToFloat(myString); // end new
    end else myWholeInch:=StrToFloat(myString);         // no fractional inches
  end else myWholeFeet:=StrToFloat(myString);       // no imperial input format
  Result:=myOldValue+myFactor*(myWholeFeet+myWholeInch/12+myFracInch/(12*InchFractions));
end; {ConvertCoordinate}

end.

