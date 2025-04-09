unit FreeControlPointFrm;
{$MODE Delphi}{$H+}
interface
uses
     SysUtils, Classes,
     Graphics, Controls,
     Forms,    Dialogs,
     Math,     StdCtrls,
     Buttons,  ExtCtrls,
     Spin,FreeTypes,FreeGeometry,FreeStringUtils,FreeLanguageSupport;
type
  TEntryMethod = ( emNone, emTyping, emArrowKeys, emMouse, emPaste );

  TFreeControlPointForm=class( TForm )               { TFreeControlPointForm }
    CheckBoxAnchorHard,CheckBoxCorner:                 TCheckBox;
    SpeedButtonRemoveLinearConstraint,
    SpeedButtonRemoveAnchorPoint:                      TSpeedButton;
    EditLinearConstraintA,EditAnchorPoint,
    EditLinearConstraintB:                             TEdit;
    Label1,Label2,Label3,Label4,Label5,
    LabelX,LabelAX,LabelY,LabelAY,LabelZ,LabelAZ:      TLabel;
    Panel1,Panel2,Panel4,Panel5,Panel6,Panel7,Panel8:  TPanel;
    EditX,EditAX,EditY,EditAY,EditZ,EditAZ,
    EditDistance,EditAngles:                           TFloatSpinEdit;
    GroupBoxLinearConstraint,GroupBoxAnchorConstraint: TGroupBox;

    procedure CheckBoxAnchorHardChange(Sender: TObject);
    procedure CheckBoxCornerChange(Sender: TObject);
//  procedure EditNameEditingDone(Sender: TObject);
    procedure OrdinateEditorChange(Sender: TObject);
    procedure OrdinateEditorEditingDone(Sender: TObject);
    procedure OrdinateEditorEnter(Sender: TObject);
    procedure OrdinateEditorExit(Sender: TObject);
    procedure OrdinateEditorMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
    procedure EditMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure OrdinateEditorKeyDown(Sender:TObject; var Key:Word; Shift:TShiftState);
    procedure OrdinateEditorKeyPress(Sender:TObject; var Key:char);
    procedure EditYChange(Sender: TObject);
    procedure EditZChange(Sender: TObject);
//  procedure EditYEditingDone(Sender: TObject);
//  procedure EditZEditingDone(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
{   procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton5Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton6Click(Sender: TObject);
}   procedure SpeedButtonRemoveAnchorPointClick(Sender: TObject);
    procedure SpeedButtonRemoveLinearConstraintClick(Sender: TObject);
{   procedure FilterComboBoxLinearConstraintAChange(Sender: TObject);  //TODO delete if not used
    procedure PopulateFilterComboBoxLinearConstraintA(Sender:TObject); //TODO delete if not used
    procedure FilterComboBoxLinearConstraintBChange(Sender: TObject);  //TODO delete if not used
    procedure PopulateFilterComboBoxLinearConstraintB(Sender:TObject); //TODO delete if not used
}
   private                                             { Private declarations }
      FActiveControlPoint : TFreeSubdivisionControlPoint;
      FPointEditorChanging,
      FSkipCheckbox1OnClick,
      FActiveControlPointChanging,
      FilterComboBoxLinearConstraintAPopulating,
      FilterComboBoxLinearConstraintBPopulating : boolean; //TODO delete if not used
      EnteredControl: TControl;
      EntryMethod: TEntryMethod;
      procedure FSetActiveControlPoint( Val:TFreeSubdivisionControlPoint );
      procedure FSetActiveControlPointCorner( isCorner: boolean );
   public                                               { Public declarations }
      FreeShip: TComponent;
      procedure Reload;
      property ActiveControlPoint: TFreeSubdivisionControlPoint
          read FActiveControlPoint
         write FSetActiveControlPoint;
   // property FreeShip: TComponent read FFreeShip write FFreeShip;
   // property FreeShip: TFreeShip read FFreeShip write FFreeShip;
end;

var FreeControlPointForm: TFreeControlPointForm;

implementation
uses FreeShipUnit;
{$R *.lfm}

procedure TFreeControlPointForm.FSetActiveControlPoint(Val:TFreeSubdivisionControlPoint);
var I,N,Npoi : Integer;
    BCol,FCol: TColor;
    R,R1,R2,alfa,beta,gamma,acos,len,
    cos1a,cos2a,cos1b,cos2b,cos1g,cos2g : single;
    C0,CN,C1,C2,C3,Cp,Ci: T3DVector;
    IsPointDifferent: boolean;
//    FreeShip:TFreeShip;
begin //FreeShip:=Ship;
   ShowTranslatedValues( Self );
   IsPointDifferent:=FActiveControlPoint<>Val;
   FActiveControlPoint:=Val;
   FActiveControlPointChanging:=true;
   if ActiveControlPoint=nil then begin Visible:=False;
      EditX.Value:=0.0;
      EditY.Value:=0.0;
      EditZ.Value:=0.0;
      EditAX.Value:=0.0;
      EditAY.Value:=0.0;
      EditAZ.Value:=0.0;
      CheckBoxCorner.Checked:=false;
//    EditName.Text:='';
      Self.Caption:='';
   end else begin
//    if TFreeShip(FreeShip).Surface.SelectedControlPoints.IndexOf(ActiveControlPoint)=-1
//      then Ship.Surface.SelectedControlPoints.Add(ActiveControlPoint);
      R:=0.0;
      EditDistance.Value:=0.0;
      Self.Caption:='Point['+IntToStr( FActiveControlPoint.Id )+']: '
//                + FActiveControlPoint.Name {
                  +' ('+FloatToStrF( FActiveControlPoint.Coordinate.X,ffFixed,5,3 )
                  + ','+FloatToStrF( FActiveControlPoint.Coordinate.Y,ffFixed,5,3 )
                  + ','+FloatToStrF( FActiveControlPoint.Coordinate.Z,ffFixed,5,3 ) + ')'; // };
//    Npoi:=Ship.NumberOfSelectedControlPoints-1;
      Npoi:=Ship.NumberOfSelectedControlPoints-1;
      if Npoi>=0 then begin
         C0:=Ship.SelectedControlPoint[0].Coordinate;
         CN:=Ship.SelectedControlPoint[Npoi].Coordinate;;
      end;
      if Npoi>=1 then begin
         R:=Abs( C0-CN );
         EditDistance.Value:=R;
         EditAngles.Value:=0.0;
      end else EditDistance.Value:=0.0;

      if Npoi>=4 then begin
         R:=Abs( C0-CN );
         EditDistance.Value:=R;
         Len:=0;
         for I:=1 to Npoi do begin
           Cp:=Ship.SelectedControlPoint[i-1].Coordinate;
           Ci:=Ship.SelectedControlPoint[i].Coordinate;
           R:=Abs( Cp-Ci );
           Len:=Len+R;
         end;
         Label5.Caption:=UserString(1493); // 'Length';
         EditAngles.Value:=Len;
      end;
      if R=0 then R:=0.0001;
      if Npoi=0 then begin
        R:=Abs( C0 );
        if R=0 then R:=0.0001;
        alfa:=C0.X/R;
        beta:=C0.Y/R;
        gamma:=C0.Z/R;
        EditAX.Value:=ArcCos( alfa )*Radian;
        EditAY.Value:=ArcCos( beta )*Radian;
        EditAZ.Value:=ArcCos( gamma )*Radian;
        {EditAngles.Text:=FloatToDec(ArcCos(alfa)*Radian,2)+';'+FloatToDec(ArcCos(beta)*Radian,2)+';'+FloatToDec(ArcCos(gamma)*Radian,2);}
      end else
      if Npoi=1 then begin
        alfa:=abs(C0.X-CN.X)/R;
        beta:=abs(C0.Y-CN.Y)/R;
        gamma:=abs(C0.Z-CN.Z)/R;
        EditAX.Value:=ArcCos( alfa )*Radian;
        EditAY.Value:=ArcCos( beta )*Radian;
        EditAZ.Value:=ArcCos( gamma )*Radian;
      end else
      if  Npoi=2 then begin
        C1:=Ship.SelectedControlPoint[1].Coordinate;
        C2:=Ship.SelectedControlPoint[2].Coordinate;
        R1:=Abs( C0-C1 );
        R2:=Abs( C1-C2 );
        if R1>0 then begin
          cos1a:=abs(C0.X-C1.X)/R1;
          cos1b:=abs(C0.Y-C1.Y)/R1;
          cos1g:=abs(C0.Z-C1.Z)/R1;
        end else begin cos1a:=0; cos1b:=0; cos1g:=0; end;
        if R2>0 then begin
          cos2a:=abs(C1.X-C2.X)/R2;
          cos2b:=abs(C1.Y-C2.Y)/R2;
          cos2g:=abs(C1.Z-C2.Z)/R2;
        end else begin cos2a:=0; cos2b:=0; cos2g:=0; end;
        acos:=cos1a*cos2a+cos1b*cos2b+cos1g*cos2g;
        if acos>1 then acos:=1;
        if acos<-1 then acos:=-1;
        EditAngles.Value:=ArcCos(acos)*Radian;
      end else
      if  Npoi=3 then begin
        C1:=Ship.SelectedControlPoint[1].Coordinate;
        C2:=Ship.SelectedControlPoint[2].Coordinate;
        C3:=Ship.SelectedControlPoint[3].Coordinate;
        R1:=Abs( C0-C1 );
        R2:=Abs( C2-C3 );
        if R1>0 then begin
          cos1a:=abs(C0.X-C1.X)/R1;
          cos1b:=abs(C0.Y-C1.Y)/R1;
          cos1g:=abs(C0.Z-C1.Z)/R1;
        end else begin
          cos1a:=0;
          cos1b:=0;
          cos1g:=0;
        end;
        if R2>0 then begin
          cos2a:=(C2.X-C3.X)/R2;
          cos2b:=(C2.Y-C3.Y)/R2;
          cos2g:=(C2.Z-C3.Z)/R2;
        end else begin
          cos1a:=0;
          cos1b:=0;
          cos1g:=0;
        end;
        acos:=cos1a*cos2a+cos1b*cos2b+cos1g*cos2g;
        if acos>1 then acos:=1;
        if acos<-1 then acos:=-1;
        EditAngles.Value:=ArcCos(acos)*Radian;
      end;
      EditX.Value:=FActiveControlPoint.Coordinate.X;
      EditY.Value:=FActiveControlPoint.Coordinate.Y;
      EditZ.Value:=FActiveControlPoint.Coordinate.Z;
      if true or IsPointDifferent then begin
        if  (Npoi<2) or (NPoi>3) then I:=1477 else I:=1476;
        Label5.Caption:=UserString( I );
        if (CheckBoxCorner.Checked<>(FActiveControlPoint.VertexType=svCorner))
        then begin
           FSkipCheckbox1OnClick:=true;
           CheckBoxCorner.Checked:=FActiveControlPoint.VertexType=svCorner;
           FSkipCheckbox1OnClick:=false;
        end;        // Count the number of crease edges connected to this point
        N:=0;
        for I:=1 to FActiveControlPoint.NumberOfEdges do
          if FActiveControlPoint.Edge[I-1].Crease then inc(N);
        CheckBoxCorner.Enabled:=((N>0) and (N<3) and (not Val.Locked)); // points with more than two crease edges must always be a corner
        EditX.Enabled:=not Val.Locked;
        EditY.Enabled:=not Val.Locked;
        EditZ.Enabled:=not Val.Locked;
      { if Val.Locked then begin BCol:=clBtnFace; FCol:=clDkgray; end
                      else begin BCol:=clWindow; FCol:=clBlack; end;
        if EditX.Color<>BCol then EditX.Color:=BCol;
        if EditX.Font.Color<>FCol then EditX.Font.Color:=FCol;
        if EditY.Color<>BCol then EditY.Color:=BCol;
        if EditY.Font.Color<>FCol then EditY.Font.Color:=FCol;
        if EditZ.Color<>BCol then EditZ.Color:=BCol;
        if EditZ.Font.Color<>FCol then EditZ.Font.Color:=FCol;}

//      EditName.Text:=Val.Name;
//      EditName.Color:= clDefault;

        //PopulateFilterComboBoxLinearConstraintA(nil); //TODO delete if not used
        //PopulateFilterComboBoxLinearConstraintB(nil); //TODO delete if not used

        if (FActiveControlPoint.LinearConstraintPointA<>nil)
        and (FActiveControlPoint.LinearConstraintPointB<>nil) then begin
            GroupBoxLinearConstraint.Visible:=true;
            EditLinearConstraintA.Text:='';
            EditLinearConstraintB.Text:='';
            if (FActiveControlPoint.LinearConstraintPointA<>nil) then
//             if (FActiveControlPoint.LinearConstraintPointA.Name > '') then
//             EditLinearConstraintA.Text:=FActiveControlPoint.LinearConstraintPointA.Name else
               EditLinearConstraintA.Text:='Point['+IntToStr(FActiveControlPoint.LinearConstraintPointA.Id)+']';
            if (FActiveControlPoint.LinearConstraintPointB<>nil) then
//             if (FActiveControlPoint.LinearConstraintPointB.Name > '') then
//             EditLinearConstraintB.Text:=FActiveControlPoint.LinearConstraintPointB.Name else
               EditLinearConstraintB.Text:='Point['+IntToStr(FActiveControlPoint.LinearConstraintPointB.Id)+']';
          end
        else GroupBoxLinearConstraint.Visible:=false;

        if (FActiveControlPoint.AnchorPoint<>nil) then begin
          GroupBoxAnchorConstraint.Visible:=true;
          CheckBoxAnchorHard.Checked:=FActiveControlPoint.IsAnchorHard;
          EditAnchorPoint.Text:='';
//        if (FActiveControlPoint.AnchorPoint.Name>'') then
//          EditAnchorPoint.Text:=FActiveControlPoint.AnchorPoint.Name else
            EditAnchorPoint.Text:='Point['+IntToStr(FActiveControlPoint.AnchorPoint.Id)+']';
        end else GroupBoxAnchorConstraint.Visible:=false;
      end;
   end; FActiveControlPointChanging:=false;
end;

procedure TFreeControlPointForm.Reload;
    begin FSetActiveControlPoint( ActiveControlPoint ); end;

procedure TFreeControlPointForm.OrdinateEditorChange(Sender: TObject);
var P: T3DVector;
    OrdEdit : TFloatSpinEdit;
    Val: Double;
begin
   if FActiveControlPointChanging then exit;
   if FPointEditorChanging then exit;
   OrdEdit:=Sender as TFloatSpinEdit;
   Val:=OrdEdit.Value;
   if EnteredControl <> OrdEdit then exit;
   if not(OrdEdit.Focused and OrdEdit.Enabled and not OrdEdit.ReadOnly) then exit;
   FPointEditorChanging:=true;
   if ActiveControlPoint<>nil then
   if EntryMethod <> emTyping then begin
        OrdinateEditorEditingDone(Sender);
        {P:=ActiveControlPoint.Coordinate;
        if OrdEdit = EditX then P.X:=OrdEdit.Value;
        if OrdEdit = EditY then P.Y:=OrdEdit.Value;
        if OrdEdit = EditZ then P.Z:=OrdEdit.Value;
        //Ship.Edit.CreateUndoObject(rsPointMove,True);
        //P.X:=P.X+Ship.Visibility.CursorIncrement;
        ActiveControlPoint.SetCoordinate(nil, P, nil);
        Ship.Built:=False;
        Ship.FileChanged:=True;
        Ship.Redraw;
        //ActiveControlPoint:=ActiveControlPoint; }
   end;
   FPointEditorChanging:=false;
end;

procedure TFreeControlPointForm.EditYChange(Sender: TObject);
var P   : T3DVector;
begin
   if FActiveControlPointChanging then exit;
   if FPointEditorChanging then exit;
   if EnteredControl <> EditY then exit;
   if not(EditY.Focused and EditY.Enabled and not EditY.ReadOnly) then exit;
   FPointEditorChanging:=true;
   if ActiveControlPoint<>nil then
   if EntryMethod <> emTyping then begin
      Ship.Edit.CreateUndoObject( 'moveY',True );
      P:=ActiveControlPoint.Coordinate;
    //P.Y:=P.Y+Ship.Visibility.CursorIncrement;
      P.Y:=EditY.Value;
      ActiveControlPoint.SetCoordinate( nil,P,nil );
      Ship.Built:=False;
      Ship.FileChanged:=True;
      Ship.Redraw;
   ///ActiveControlPoint:=ActiveControlPoint;
   end;
   FPointEditorChanging:=false;
end;

procedure TFreeControlPointForm.EditZChange(Sender: TObject);
var P   : T3DVector;
begin
   if FActiveControlPointChanging then exit;
   if FPointEditorChanging then exit;
   if EnteredControl <> EditZ then exit;
   if not(EditZ.Focused and EditZ.Enabled and not EditZ.ReadOnly) then exit;
   FPointEditorChanging:=true;
   if ActiveControlPoint<>nil then
   if EntryMethod <> emTyping then begin
      Ship.Edit.CreateUndoObject( 'moveZ',True);
      P:=ActiveControlPoint.Coordinate;
   // P.Z:=P.Z+Ship.Visibility.CursorIncrement;
      P.Z:=EditZ.Value;
      ActiveControlPoint.SetCoordinate( nil,P,nil );
      Ship.Built:=False;
      Ship.FileChanged:=True;
      Ship.Redraw;
   // ActiveControlPoint:=ActiveControlPoint;
   end; FPointEditorChanging:=false;
end;

procedure TFreeControlPointForm.OrdinateEditorEditingDone(Sender: TObject);
var P    : T3DVector;
    Val  : TFloatType;
    I    : Integer;
    saved: Boolean;
    OrdEdit : TFloatSpinEdit;
begin
   saved:=false;
   if Self.FActiveControlPointChanging then exit;
   if not Self.Active then exit;
   //if not Self.Focused then exit;

   if ActiveControlPoint<>nil then begin
      OrdEdit:=Sender as TFloatSpinEdit;
      // do something only if the value has really been changed:
      Val:=OrdEdit.Value;
      P:=ActiveControlPoint.Coordinate;
      if (OrdEdit = EditX) and (abs(P.X-Val) < 1e-5) then exit;
      if (OrdEdit = EditY) and (abs(P.Y-Val) < 1e-5) then exit;
      if (OrdEdit = EditZ) and (abs(P.Z-Val) < 1e-5) then exit;
      if (Ship.NumberOfSelectedControlPoints>0) then begin // SAP change all selected points
         for I:=0 to Ship.NumberOfSelectedControlPoints-1 do begin
            P:=Ship.SelectedControlPoint[I].Coordinate;
            //if abs(P.X-Val)>1e-5 then
            begin
               if not saved then begin
                  Ship.Edit.CreateUndoObject('X Coordinate',True);
                  saved:=true;
               end;
               if (OrdEdit = EditX) then P.X:=Val;
               if (OrdEdit = EditY) then P.Y:=Val;
               if (OrdEdit = EditZ) then P.Z:=Val;
               Ship.SelectedControlPoint[I].SetCoordinate(nil,P,nil);
            end;
         end;
         { // this is for old FreeTextEdit component
         //  finally update the text field:
         if OrdEdit.Text<>'' then
         begin
            P:=ActiveControlPoint.Coordinate;
            //Val:= ConvertCoordinate(EditX.Text, P.X);
            Val:=OrdEdit.Value;
         end
         else Val:= 0;
         OrdEdit.Text:=FloatToDec(Val,4); // update the field in case of input errors
///*** }
         if saved then begin
//          Ship.Surface.Selection_Add( ActiveControlPoint );
            Ship.Built:=False;
            Ship.FileChanged:=True;
            Ship.Redraw;
            ActiveControlPoint:=ActiveControlPoint;
         end;
      end;
   end;
end;
procedure TFreeControlPointForm.OrdinateEditorEnter(Sender: TObject);
    begin EntryMethod:=emNone;
          EnteredControl:=Sender as TControl;
          FActiveControlPointChanging:=false;
          FPointEditorChanging:=false;
   end;
procedure TFreeControlPointForm.OrdinateEditorExit(Sender: TObject);
    begin EnteredControl:=nil;
          EntryMethod:=emNone;
    end;

procedure TFreeControlPointForm.OrdinateEditorMouseDown
( Sender: TObject;
  Button: TMouseButton;
   Shift: TShiftState;
     X,Y: Integer );
begin
  EntryMethod:=emMouse;
  EnteredControl:=Sender as TControl;
  FActiveControlPointChanging:=false;
  FPointEditorChanging:=false;
end;

procedure TFreeControlPointForm.EditMouseWheel
( Sender: TObject;
  Shift: TShiftState;
  WheelDelta: Integer;
  MousePos: TPoint;
  var Handled: Boolean );
begin
  EntryMethod:=emMouse;
  EnteredControl:=Sender as TControl;
  FActiveControlPointChanging:=false;
  FPointEditorChanging:=false;
end;

procedure TFreeControlPointForm.OrdinateEditorKeyDown
( Sender: TObject; var Key: Word; Shift: TShiftState );
begin
  EntryMethod:=emTyping;
  if ((Key=38) or (Key=40) and ([]=Shift)) then EntryMethod:=emArrowKeys;
  if ((Key=86) and ( ssCtrl in Shift)) then EntryMethod:=emPaste; // Ctrl-V
  if ((Key=45) and ( ssShift in Shift)) then EntryMethod:=emPaste; // Shift-Ins
end;

procedure TFreeControlPointForm.OrdinateEditorKeyPress(Sender: TObject; var Key: char);
begin
  if not (Key in ['0'..'9','.','+','-',#13]) then EntryMethod:=emTyping;
//if ((Key >= '0') and (Key <= '9')) or (Key=DefaultFormatSettings.DecimalSeparator) or (Key='.') or (Key=',') or (Key='+') or (Key='-') then EntryMethod:=emTyping;
end;

procedure TFreeControlPointForm.CheckBoxCornerChange( Sender: TObject );
begin if FSkipCheckbox1OnClick then exit;
         FSetActiveControlPointCorner( CheckBoxCorner.Checked );
end;
procedure TFreeControlPointForm.CheckBoxAnchorHardChange(Sender: TObject);
begin ActiveControlPoint.IsAnchorHard:=CheckBoxAnchorHard.Checked;
end;

procedure TFreeControlPointForm.FSetActiveControlPointCorner(isCorner: boolean);
var I,N     : Integer;
    OldType : TFreeVertexType;
    Undo    : TFreeUndoObject;
begin
  if (ActiveControlPoint<>nil)
  and (isCorner <> (ActiveControlPoint.VertexType=svCorner)) then begin
                    // Count the number of crease edges connected to this point
    OldType:=ActiveControlPoint.VertexType;
    Undo:=Ship.Edit.CreateUndoObject( 'Corner ',false );
    if (ActiveControlPoint.Vertextype=svCorner) and (not isCorner) then begin
      N:=0;                        // Count the number of incident crease edges
      for I:=1 to ActiveControlPoint.NumberOfEdges do
      if FActiveControlPoint.Edge[I-1].Crease then inc(N);
      Case N of
        0 : ActiveControlPoint.Vertextype:=svRegular;
        1 : ActiveControlPoint.VertexType:=svDart;
        2 : ActiveControlPoint.VertexType:=svCrease;
              // points with more than two crease edges must always be a corner
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

procedure TFreeControlPointForm.FormActivate(Sender: TObject);
begin
  FSkipCheckbox1OnClick:=false;
  EditX.Increment:=Ship.Visibility.CursorIncrement;
  EditY.Increment:=Ship.Visibility.CursorIncrement;
  EditZ.Increment:=Ship.Visibility.CursorIncrement;
//  LabelAX.Caption:='°'; //cDegree;
//  LabelAY.Caption:='°'; //cDegree;
//  LabelAZ.Caption:='°'; //cDegree;
//  Label1.Caption:='α';  //cAlpha;
//  Label2.Caption:='β';  //cBeta;
//  Label3.Caption:='γ';  //cGamma;
end;

procedure TFreeControlPointForm.FormCreate( Sender: TObject ); begin end;

procedure TFreeControlPointForm.FormShow(Sender: TObject);
    begin Caption:=Caption; end;

procedure TFreeControlPointForm.SpeedButtonRemoveAnchorPointClick( Sender: TObject );
begin
   if ActiveControlPoint<>nil then begin
       Ship.Edit.CreateUndoObject( 'UnAncDel',True );
       ActiveControlPoint.AnchorPoint:=nil;
       EditAnchorPoint.Text:='';
       Ship.FileChanged:=True;
       Ship.Redraw;
       ActiveControlPoint:=ActiveControlPoint;
    end;
end;

procedure TFreeControlPointForm.SpeedButtonRemoveLinearConstraintClick( Sender: TObject );
begin
  if ActiveControlPoint<>nil then begin
      Ship.Edit.CreateUndoObject( 'UnLineDel',True );
      ActiveControlPoint.SetLinearConstraint(nil,nil);
      EditLinearConstraintA.Text:='';
      EditLinearConstraintB.Text:='';
      Ship.FileChanged:=True;
      Ship.Redraw;
      ActiveControlPoint:=ActiveControlPoint;
   end;
end;

end.
