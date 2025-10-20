
unit FreeControlPointFrm;

interface

uses SysUtils,
     Classes,
     Graphics,
     Controls,
     Forms,
     StdCtrls,
     Buttons,
     FreeGeometry,
     FreeTypes;
type TFreeControlPointForm  = class(TForm)
     Edit1,Edit2,Edit3: TEdit;
     Label1,Label2,Label3: TLabel;
     CheckBox1: TCheckBox;
     SpeedButton1,SpeedButton2,SpeedButton3,SpeedButton4,SpeedButton5,SpeedButton6: TSpeedButton;
     procedure Edit1KeyPress(Sender: TObject; var Key: Char);
     procedure Edit1Exit(Sender: TObject);
     procedure Edit2KeyPress(Sender: TObject; var Key: Char);
     procedure Edit2Exit(Sender: TObject);
     procedure Edit3KeyPress(Sender: TObject; var Key: Char);
     procedure Edit3Exit(Sender: TObject);
     procedure CheckBox1MouseUp(Sender: TObject; Button: TMouseButton;Shift: TShiftState; X, Y: Integer);
     procedure SpeedButton1Click(Sender: TObject);
     procedure SpeedButton4Click(Sender: TObject);
     procedure SpeedButton2Click(Sender: TObject);
     procedure SpeedButton5Click(Sender: TObject);
     procedure SpeedButton3Click(Sender: TObject);
     procedure SpeedButton6Click(Sender: TObject);
  private
     FActiveControlPoint  : TFreeSubdivisionControlPoint;
     FFreeShip            : TComponent;
     procedure FSetActiveControlPoint(Val:TFreeSubdivisionControlPoint);
  public
     property ActiveControlPoint   : TFreeSubdivisionControlPoint read FActiveControlPoint write FSetActiveControlPoint;
     property FreeShip             : TComponent read FFreeShip write FFreeShip;
end;

var FreeControlPointForm: TFreeControlPointForm;

implementation

uses FreeLanguageSupport,
     FreeShipUnit;

{$R *.lfm}

procedure TFreeControlPointForm.FSetActiveControlPoint(Val:TFreeSubdivisionControlPoint);
var I,N : Integer;
    BCol,FCol:TColor;
begin
   FActiveControlPoint:=Val;
   if ActiveControlPoint=nil then begin
      Visible:=False;
      Edit1.Text:='';
      Edit2.Text:='';
      Edit3.Text:='';
      Checkbox1.Checked:=false;
   end else begin
      Edit1.Text:=Truncate(FActiveControlPoint.Coordinate.X,4);
      Edit2.Text:=Truncate(FActiveControlPoint.Coordinate.Y,4);
      Edit3.Text:=Truncate(FActiveControlPoint.Coordinate.Z,4);
      Checkbox1.Checked:=FActiveControlPoint.VertexType=svCorner;
      // Count the number of crease edges connected to this point
      N:=0;
      for I:=1 to FActiveControlPoint.NumberOfEdges do if FActiveControlPoint.Edge[I-1].Crease then inc(N);
      Checkbox1.Enabled:=(N>0) and (N<3); // points with more than two crease edges must always be a corner
      Edit1.Enabled:=not Val.Locked;
      Edit2.Enabled:=not Val.Locked;
      Edit3.Enabled:=not Val.Locked;
      SpeedButton1.Enabled:=not val.locked;
      SpeedButton2.Enabled:=not val.locked;
      SpeedButton3.Enabled:=not val.locked;
      SpeedButton4.Enabled:=not val.locked;
      SpeedButton5.Enabled:=not val.locked;
      SpeedButton6.Enabled:=not val.locked;
      Checkbox1.Enabled:=not Val.Locked;
      if Val.Locked then begin
         BCol:=clBtnFace;
         FCol:=clDkgray;
      end else begin
         BCol:=clWindow;
         FCol:=clBlack;
      end;
      if Edit1.Color<>BCol then Edit1.Color:=BCol;
      if Edit1.Font.Color<>FCol then Edit1.Font.Color:=FCol;
      if Edit2.Color<>BCol then Edit2.Color:=BCol;
      if Edit2.Font.Color<>FCol then Edit2.Font.Color:=FCol;
      if Edit3.Color<>BCol then Edit3.Color:=BCol;
      if Edit3.Font.Color<>FCol then Edit3.Font.Color:=FCol;
   end;
end;

procedure TFreeControlPointForm.Edit1KeyPress(Sender: TObject;var Key: Char);
begin
   if (Key in [#8,'1'..'9','0','-','@',#13]) or
      ((TFreeShip(FreeShip).ProjectSettings.ProjectUnits=fuImperial) and (Key='+')) or
      (Key=Decimalseparator) then else key:=#0; //SAP: added the '@'
   if Key=#13 then Edit1Exit(Self);
end;

procedure TFreeControlPointForm.Edit1Exit(Sender: TObject);
var P    : T3DVector;
    Val  : TFloatType;
    I    : Integer;
    saved: Boolean;
begin
   saved := false;
   if ActiveControlPoint<>nil then
   begin
// do only something, if the value has really been changed:
      P:=ActiveControlPoint.Coordinate;
      Val := ConvertCoordinate(Edit1.Text, P.X);
      if (abs(P.X-Val)>1e-4) or (TFreeShip(FreeShip).NumberOfSelectedControlPoints>1) 
      then begin
// SAP change all selected points
         I := 1;
         while I <= TFreeShip(FreeShip).NumberOfSelectedControlPoints do begin
            P := TFreeShip(FreeShip).SelectedControlPoint[I-1].Coordinate;
            Val:=ConvertCoordinate(Edit1.Text, P.X);
            if abs(P.X-Val)>1e-5 then begin
               if not saved then begin
                  TFreeShip(FreeShip).Edit.CreateUndoObject(Userstring(210),True);
                  saved := true;
               end;
               P.X:=Val;
               TFreeShip(FreeShip).SelectedControlPoint[I-1].Coordinate := P;
            end;
            Inc(I);
         end;
//  finally update the text field:
         if Edit1.Text<>'' then begin
            P:=ActiveControlPoint.Coordinate;
            Val:= ConvertCoordinate(Edit1.Text, P.X);
         end
         else Val:= 0;
         Edit1.Text:=Truncate(Val,4); // update the field in case of input errors

         if saved then begin
            TFreeShip(FreeShip).Build:=False;
            TFreeShip(FreeShip).FileChanged:=True;
            TFreeShip(FreeShip).Redraw;
            ActiveControlPoint:=ActiveControlPoint;
         end;
      end;
   end;
end;

procedure TFreeControlPointForm.Edit2KeyPress(Sender: TObject;var Key: Char);
begin
   if (Key in [#8,'1'..'9','0','-','@',#13]) or
      ((TFreeShip(FreeShip).ProjectSettings.ProjectUnits=fuImperial) and (Key='+')) or
      (Key=Decimalseparator) then else key:=#0; //SAP: added the '@'
   if Key=#13 then Edit2Exit(Self);
end;

procedure TFreeControlPointForm.Edit2Exit(Sender: TObject);
var P    : T3DVector;
    Val  : TFloatType;
    I    : Integer;
    saved: Boolean;
begin
   saved := false;
   if ActiveControlPoint<>nil then begin
// do only something, if the value has really been changed:
      P:=ActiveControlPoint.Coordinate;
      Val := ConvertCoordinate(Edit2.Text, P.Y);
      if (abs(P.Y-Val)>1e-4) or (TFreeShip(FreeShip).NumberOfSelectedControlPoints>1) 
      then begin
// SAP change all selected points
        I := 1;
         while I <= TFreeShip(FreeShip).NumberOfSelectedControlPoints do begin
            P := TFreeShip(FreeShip).SelectedControlPoint[I-1].Coordinate;
            Val:=ConvertCoordinate(Edit2.Text, P.Y);
            if abs(P.Y-Val)>1e-5 then begin
               if not saved then begin
                  TFreeShip(FreeShip).Edit.CreateUndoObject(Userstring(211),True);
                  saved := true;
               end;
               P.Y:=Val;
               TFreeShip(FreeShip).SelectedControlPoint[I-1].Coordinate := P;
            end;
            Inc(I);
         end;

//  finally update the text field:
         if Edit2.Text<>'' then begin
            P:=ActiveControlPoint.Coordinate;
            Val:= ConvertCoordinate(Edit2.Text, P.Y);
         end
         else Val:= 0;
         Edit2.Text:=Truncate(Val,4); // update the field in case of input errors

         if saved then begin
            TFreeShip(FreeShip).Build:=False;
            TFreeShip(FreeShip).FileChanged:=True;
            TFreeShip(FreeShip).Redraw;
            ActiveControlPoint:=ActiveControlPoint;
         end;
      end;
   end;
end;

procedure TFreeControlPointForm.Edit3KeyPress(Sender: TObject; var Key: Char);
begin
   if (Key in [#8,'1'..'9','0','-','@',#13]) or
      ((TFreeShip(FreeShip).ProjectSettings.ProjectUnits=fuImperial) and (Key='+')) or
      (Key=Decimalseparator) then else key:=#0; //SAP: added the '@'
   if Key=#13 then Edit3Exit(Self);
end;

procedure TFreeControlPointForm.Edit3Exit(Sender: TObject);
var P    : T3DVector;
    Val  : TFloatType;
    I    : Integer;
    saved: Boolean;
begin
   saved := false;
   if ActiveControlPoint<>nil then begin
// do only something, if the value has really been changed:
      P:=ActiveControlPoint.Coordinate;
      Val := ConvertCoordinate(Edit3.Text, P.Z);
      if (abs(P.Z-Val)>1e-4) 
      or (TFreeShip(FreeShip).NumberOfSelectedControlPoints>1) then begin
// SAP change all selected points
        I := 1;
         while I <= TFreeShip(FreeShip).NumberOfSelectedControlPoints do begin
            P := TFreeShip(FreeShip).SelectedControlPoint[I-1].Coordinate;
            Val:=ConvertCoordinate(Edit3.Text, P.Z);
            if abs(P.Z-Val)>1e-5 then begin
               if not saved then begin
                  TFreeShip(FreeShip).Edit.CreateUndoObject(Userstring(212),True);
                  saved := true;
               end;
               P.Z:=Val;
               TFreeShip(FreeShip).SelectedControlPoint[I-1].Coordinate := P;
            end;
            Inc(I);
         end;

//  finally update the text field:
         if Edit3.Text<>'' then begin
            P:=ActiveControlPoint.Coordinate;
            Val:=ConvertCoordinate(Edit3.Text, P.Z);
         end
         else Val:= 0;
         Edit3.Text:=Truncate(Val,4); // update the field in case of input errors

         if saved then begin
            TFreeShip(FreeShip).Build:=False;
            TFreeShip(FreeShip).FileChanged:=True;
            TFreeShip(FreeShip).Redraw;
            ActiveControlPoint:=ActiveControlPoint;
         end;
      end;
   end;
end;

procedure TFreeControlPointForm.CheckBox1MouseUp(Sender: TObject;Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var I,N     : Integer;
    OldType : TFreeVertexType;
    Undo    : TFreeUndoObject;
begin
   if ActiveControlPoint<>nil then
   begin
      // Count the number of crease edges connected to this point
      OldType:=ActiveControlPoint.VertexType;
      Undo:=TFreeShip(FreeShip).Edit.CreateUndoObject(Userstring(213),false);
      Case ActiveControlPoint.Vertextype of
         svCorner  : begin
                        N:=0;
                        for I:=1 to ActiveControlPoint.NumberOfEdges do 
                          if FActiveControlPoint.Edge[I-1].Crease then inc(N);
                          // Count the number of incident crease edges
                        Case N of
                           0 : ActiveControlPoint.Vertextype:=svRegular;
                           1 : ActiveControlPoint.VertexType:=svDart;
                           2 : ActiveControlPoint.VertexType:=svCrease;
                        end;
                     end;
         else ActiveControlPoint.VertexType:=svCorner;
      end;
      if ActiveControlPoint.VertexType<>OldType then begin
         Undo.Accept;
         TFreeShip(FreeShip).Build:=False;
         TFreeShip(FreeShip).FileChanged:=True;
         TFreeShip(FreeShip).Redraw;
         ActiveControlPoint:=ActiveControlPoint;
      end else Undo.Delete;
   end;
end;

procedure TFreeControlPointForm.SpeedButton1Click(Sender: TObject);
var P   : T3DVector;
begin
   if ActiveControlPoint<>nil then begin
      TFreeShip(FreeShip).Edit.CreateUndoObject(Userstring(190),True);
      P:=ActiveControlPoint.Coordinate;
      P.X:=P.X+TFreeShip(FreeShip).Visibility.CursorIncrement;
      ActiveControlPoint.Coordinate:=P;
      TFreeShip(FreeShip).Build:=False;
      TFreeShip(FreeShip).FileChanged:=True;
      TFreeShip(FreeShip).Redraw;
      ActiveControlPoint:=ActiveControlPoint;
   end;
end;

procedure TFreeControlPointForm.SpeedButton4Click(Sender: TObject);
var P   : T3DVector;
begin
   if ActiveControlPoint<>nil then begin
      TFreeShip(FreeShip).Edit.CreateUndoObject(Userstring(190),True);
      P:=ActiveControlPoint.Coordinate;
      P.X:=P.X-TFreeShip(FreeShip).Visibility.CursorIncrement;
      ActiveControlPoint.Coordinate:=P;
      TFreeShip(FreeShip).Build:=False;
      TFreeShip(FreeShip).FileChanged:=True;
      TFreeShip(FreeShip).Redraw;
      ActiveControlPoint:=ActiveControlPoint;
   end;
end;

procedure TFreeControlPointForm.SpeedButton2Click(Sender: TObject);
var P   : T3DVector;
begin
   if ActiveControlPoint<>nil then begin
      TFreeShip(FreeShip).Edit.CreateUndoObject(Userstring(190),True);
      P:=ActiveControlPoint.Coordinate;
      P.Y:=P.Y+TFreeShip(FreeShip).Visibility.CursorIncrement;
      ActiveControlPoint.Coordinate:=P;
      TFreeShip(FreeShip).Build:=False;
      TFreeShip(FreeShip).FileChanged:=True;
      TFreeShip(FreeShip).Redraw;
      ActiveControlPoint:=ActiveControlPoint;
   end;
end;

procedure TFreeControlPointForm.SpeedButton5Click(Sender: TObject);
var P   : T3DVector;
begin
   if ActiveControlPoint<>nil then begin
      TFreeShip(FreeShip).Edit.CreateUndoObject(Userstring(190),True);
      P:=ActiveControlPoint.Coordinate;
      P.Y:=P.Y-TFreeShip(FreeShip).Visibility.CursorIncrement;
      ActiveControlPoint.Coordinate:=P;
      TFreeShip(FreeShip).Build:=False;
      TFreeShip(FreeShip).FileChanged:=True;
      TFreeShip(FreeShip).Redraw;
      ActiveControlPoint:=ActiveControlPoint;
   end;
end;

procedure TFreeControlPointForm.SpeedButton3Click(Sender: TObject);
var P: T3DVector;
begin
   if ActiveControlPoint<>nil then begin
      TFreeShip(FreeShip).Edit.CreateUndoObject(Userstring(190),True);
      P:=ActiveControlPoint.Coordinate;
      P.Z:=P.Z+TFreeShip(FreeShip).Visibility.CursorIncrement;
      ActiveControlPoint.Coordinate:=P;
      TFreeShip(FreeShip).Build:=False;
      TFreeShip(FreeShip).FileChanged:=True;
      TFreeShip(FreeShip).Redraw;
      ActiveControlPoint:=ActiveControlPoint;
   end;
end;

procedure TFreeControlPointForm.SpeedButton6Click(Sender: TObject);
var P: T3DVector;
begin
   if ActiveControlPoint<>nil then begin
      TFreeShip(FreeShip).Edit.CreateUndoObject(Userstring(190),True);
      P:=ActiveControlPoint.Coordinate;
      P.Z:=P.Z-TFreeShip(FreeShip).Visibility.CursorIncrement;
      ActiveControlPoint.Coordinate:=P;
      TFreeShip(FreeShip).Build:=False;
      TFreeShip(FreeShip).FileChanged:=True;
      TFreeShip(FreeShip).Redraw;
      ActiveControlPoint:=ActiveControlPoint;
   end;
end;

end.
