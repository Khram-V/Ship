
// Creates 4 different views on the hullform
// BevelWidth - ширина границы/рамки
// BevelInner, BevelOuter - соответственно внутренняя и внешняя граница/рамка
//  - определяют стиль рамки (вдавленная, выступающая)
//  - используется для создания псевдо-3D-эффектов.

procedure TMainForm.AddWindow( Win: TFreeHullWindow );
    begin if Windows.IndexOf( Win )=-1 then Windows.Add( Win ); end;
procedure TMainForm.DelWindow( Win: TFreeHullWindow ); Var I:Integer;
    begin I:=Windows.IndexOf( Win ); if I<>-1 then Windows.Delete( I ); end;

procedure TMainForm.FormCreate( Sender: TObject );
begin
   Windows:=TFasterList.Create;
   WindowState:=wsNormal; //wsMaximized;
   FormStyle:=fsNormal;
// AlphaBlend:= True;
// AlphaBlendValue:= 128;
   Color:=1; //clWhite;        --- не лучший вариант ...
   SetWindowLongPtr(Self.Handle, GWL_EXSTYLE,GetWindowLongPtr(Self.Handle, GWL_EXSTYLE) or WS_EX_LAYERED);
   SetLayeredWindowAttributes(Self.Handle, 1{clWhite}, 128, LWA_COLORKEY);
                     // Initialize memcheck, for memory-leak tracking = MemChk;
//{$ifndef Windows}
//   if self.Align=alTop then self.Top:=0;
//{$endif}                                       // Removed from LFM,moved here
   Ship:=TFreeShip.Create( self );
   With Ship do begin        // FreeShipUnit оригинал воссоздания новых моделей
      MainForm:=self;
      FileChanged:=true;
      Filename:='Example_Ship';
      OnChangeCursorIncrement:=FreeShipChangeCursorIncrement;
      OnFileChanged          :=FreeShipFileChanged;
      OnUpdateGeometryInfo   :=FreeShipUpdateGeometryInfo;
      OnUpdateRecentFileList :=FreeShipUpdateRecentFileList;
      OnUpdateUndoData       :=FreeShipUpdateUndoData;
      Precision:=fpLow;
   // ModelInitallyLoaded:=false;
   end;
end;

procedure TMainForm.NewOneWindow;
var HullformWindow :TFreeHullWindow; W,H: Integer;
begin                       // Application.OnException:=CustomExceptionHandler;
   W:=(10*ClientWidth) div 12;
   H:=(10*ClientHeight) div 12;
   HullformWindow:=TFreeHullWindow.Create( self );         // open a new window
   HullformWindow.SetBounds( Left+W div 12,
                             Top+75+H div 12, W,H-75 );
   HullformWindow.FreeShip:=Ship;     // Connect viewport to freeship component
   HullformWindow.Viewport.ViewType:=fvPerspective;
   HullformWindow.ViewPort.ViewportMode:=vmShade;
   HullformWindow.FormStyle:=fsStayOnTop;
   HullformWindow.BorderStyle:=bsSizeable;
   HullformWindow.BorderIcons:=[biSystemMenu,biMaximize]; // biMinimize,biMaximize,biHelp
   AddWindow( HullFormWindow );
   SetCaption;
   UpdateMenu;
end;

const S: array [0..3,0..3] of single
 = ( ( 0.7,  0,0.3,0.5 )    //  корпус
   , (   0,  0,0.7,0.5 )    //  бок
   , (   0,0.5,0.7,0.5 )    //  полуширота
   , ( 0.7,0.5,0.3,0.5 ) ); //  перспектива

procedure TMainForm.FOpenHullWindows;
var HullformWindow: TFreeHullWindow; I,J,W,H,L,T: Integer; R: TRect;
begin  W:=ClientWidth; H:=ClientHeight-72; L:=Left; T:=Top+75; //73;
    if Ship.NumberOfViewports=0 then begin
      for I:=3 downto 0 do begin                          // open a new window
        HullformWindow:=TFreeHullWindow.Create(self); // Connect viewport to freeship component
        HullformWindow.FreeShip:=Ship;
        AddWindow( HullFormWindow );
        HullformWindow.PopUpParent:=Self;
//      PopupParent:=Self;
//      PopupMode:=pmExplicit;
//      PopupMode:=pmAuto;
//      PopupMode:=pmNone;
        with HullformWindow do begin
           Viewport.ViewType:=TFreeViewType( I );
           J:=ord( ViewPort.ViewType );  // fvBodyplan,fvProfile,fvPlan,fvPerspective
           R.Left  :=Round( S[J][0]*W )+L;
           R.Top   :=Round( S[J][1]*H )+T;
           R.Right :=Round( S[J][2]*W );
           R.Bottom:=Round( S[J][3]*H );
           FormStyle:=fsNormal; // (fsNormal, fsMDIChild, fsMDIForm, fsStayOnTop, fsSplash, fsSystemStayOnTop);
           SetBounds( R.Left,R.Top,R.Right,R.Bottom );
           BorderStyle:=bsSizeable; //Sizeable; //bsNone; //bsToolWindow; //bsDialog; //bsSingle; //bsSizeToolWin;
           BorderIcons:= [biSystemMenu,biMaximize]; // , biMinimize, biMaximize, biHelp )]
           BorderWidth:=0;
           if Viewport.ViewType=fvPerspective then
              Viewport.ViewportMode:=vmShade;
           ViewPort.Invalidate;
//           ViewPort.Parent:=Self;
//           PopUpParent:=Self;
//           ViewPort.Show;
//           ShowOnTop;
        end;
        ShowTranslatedValues( HullformWindow );
        HullformWindow.SetCaption;
      end;
   end;// else Tile;
   SetCaption;
end;

procedure TMainForm.TileView;
Var R: Trect; I,J,LU,RU,LD,RD,W,H,L,T: Integer;         // Количество наложений
begin LU:=0; RU:=0; LD:=0; RD:=0; W:=ClientWidth; H:=ClientHeight-72; L:=Left; T:=Top+73;
    for I:=0 to Windows.Count-1 do begin
      with TFreeHullWindow( Windows[I] ) do begin
         J:=ord(ViewPort.ViewType);  // fvBodyplan,fvProfile,fvPlan,fvPerspective
         R.Left  :=Round( S[J][0]*W )+L;
         R.Top   :=Round( S[J][1]*H )+T;
         R.Right :=Round( S[J][2]*W );
         R.Bottom:=Round( S[J][3]*H );
         if J=1 then begin R.left+=LU; R.Top+=LU; end else // fvProfile
         if J=2 then begin R.left+=LD; R.Top-=LD; end else // fvPlan
         if J=0 then begin R.left-=RU; R.Top+=RU; end else // fvBodyplan
         if J=3 then begin R.left-=RD; R.Top-=RD; end;     // fvPerspective
         SetBounds( R.Left,R.Top,R.Right,R.Bottom );
{        if Viewport.ViewType=fvPerspective then
            Viewport.ViewportMode:=vmShade;
}        if J=1 then LU+=25 else // постобработка последующих позиций
         if J=2 then LD+=25 else
         if J=0 then RU+=25 else
         if J=3 then RD+=25;
         ViewPort.Invalidate;
         SetCaption;
    end; end;
    SetCaption;
end;

procedure TMainForm.CascadeView; Var I,J,W0,H0,W,H,L,T: Integer;
begin
   W0:=ClientWidth;     W:=Round( 0.75*W0 ); J:=0;
   H0:=ClientHeight-72; H:=Round( 0.75*H0 ); L:=Left; T:=Top+73;
    for I:=0 to Windows.Count-1 do begin
      with TFreeHullWindow( Windows[I] ) do begin
         SetBounds( L+J,T+J,W,H );
         ViewPort.Invalidate;
         SetCaption;
         J+=25; if (J+W>W0) or (J+H>H0) then J:=0;
    end; end;
    SetCaption;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var Answer:word;
begin if Ship.FileChanged then begin
        Answer:=MessageDlg(Userstring(103)+EOL+Userstring(282)+'?',mtWarning,[mbYes,mbNo],0);
        CanClose:=Answer=mrYes;
end; end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin Ship.Preferences.Save;
      Ship.OnChangeActiveLayer:=nil;
      Ship.OnChangeLayerData:=nil;
      Ship.OnSelectItem:=nil;
end;

procedure TMainForm.CascadeWindowExecute( Sender: TObject );
    begin if Ship.NumberOfViewports=0 then FOpenHullWindows; CascadeView; end;
procedure TMainForm.TileWindowExecute( Sender: TObject );
    begin if Ship.NumberOfViewports=0 then FOpenHullWindows else TileView;
    end;
procedure TMainForm.BothSidesExecute( Sender: TObject );
    begin if Ship.Visibility.ModelView=mvBoth
             then Ship.Visibility.ModelView:=mvPort
             else Ship.Visibility.ModelView:=mvBoth; UpdateMenu;
    end;
(*
/// !!!    ViewPort.BevelWidth:=6;      // - не срабатывает
/// !!!    ViewPort.BevelOuter:=bvNone; // ( bvNone, bvLowered, bvRaised, bvSpace )
/// !!!    ViewPort.BevelInner:=bvNone; // Raised
     ??    ViewPort.Caption.Height:=15;
HullformWindow.ChildSizing.LeftRightSpacing:=0;
HullformWindow.ChildSizing.TopBottomSpacing:=0;
HullformWindow.ChildSizing.VerticalSpacing:=0;
HullformWindow.ChildSizing.HorizontalSpacing:=0;
*)

