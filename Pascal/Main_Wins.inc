
{ included in Main.pas }

procedure TMainForm.FormCreate( Sender: TObject );
begin
   Windows:=TFasterList.Create;
//   WindowState:=wsNormal;
//   ClientWidth:=1280;
//   ClientHeight:=768;
//   FormStyle:=fsNormal;
   Color:=clWindow;
   SetWindowLong( (Self as TForm).Handle,GWL_EXSTYLE,
   GetWindowLong( (Self as TForm).Handle, GWL_EXSTYLE) or WS_EX_LAYERED );
   SetLayeredWindowAttributes( (Self as TForm).Handle,Color,228,LWA_ALPHA ); // LWA_COLORKEY );//
   St:=TShip.Create( self );
   With St do begin              // ShipUnit оригинал воссоздания новых моделей
      MainForm:=self;
      FileChanged:=true;
      Filename:='Example_Ship';
      OnChangeCursorIncrement:=ShipChangeCursorIncrement;
      OnFileChanged          :=ShipFileChanged;
      OnUpdateGeometryInfo   :=ShipUpdateGeometryInfo;
      OnUpdateRecentFileList :=ShipUpdateRecentFileList;
      OnUpdateUndoData       :=ShipUpdateUndoData;
      Precision:=fpLow;
      SpinEditFontSize.value:=St.Preferences.FontSize;
   end;
end;

// BevelWidth - ширина границы/рамки ? никак не срабатывает
// BevelInner, BevelOuter - соответственно внутренняя и внешняя граница/рамка
//  - определяют стиль рамки (вдавленная, выступающая)
//  - используется для создания псевдо-3D-эффектов.

procedure TMainForm.AddWindow( Win: THullWindow );
    begin if Windows.IndexOf( Win )=-1 then Windows.Add( Win );
             WindowMenu;
    end;
procedure TMainForm.DelWindow( Win: THullWindow ); Var I:Integer;
    begin I:=Windows.IndexOf( Win ); if I<>-1 then Windows.Delete( I );
             WindowMenu;
    end;

procedure TMainForm.NewOneWindow;
var HullformWindow :THullWindow; W,H: Integer;
begin                       // Application.OnException:=CustomExceptionHandler;
   W:=(10*ClientWidth) div 12;
   H:=(10*ClientHeight) div 12;
   HullformWindow:=THullWindow.Create( self );         // open a new window
   HullformWindow.St:=St;         // Connect viewport to ship component
   AddWindow( HullFormWindow );
   HullformWindow.PopUpParent:=Self;  // !!!
   HullformWindow.SetBounds( Left+W div 12,Top+75+H div 12, W,H-75 );
   HullformWindow.Viewport.ViewType:=fvPerspective;
   HullformWindow.ViewPort.ViewportMode:=vmShade;
   HullformWindow.FormStyle:=fsNormal;  // fsStayOnTop;
   HullformWindow.BorderStyle:=bsSizeable;
// HullformWindow.BorderIcons:=[biSystemMenu,biMaximize]; // biMinimize,biMaximize,biHelp
   HullformWindow.ViewPort.Invalidate;
   SetCaption;
   WindowMenu;
end;


procedure TMainForm.NewLinesPlane;
begin
   if LinesplanFrame<>nil then with LinesplanFrame do begin
      WindowState:=wsNormal;
      BringToFront;
   end else begin
      LinesplanFrame:=TLinesplanFrame.Create( self );
      LinesplanFrame.PopUpParent:=Self;
      LinesplanFrame.FormStyle:=fsNormal;
      LinesplanFrame.BorderStyle:=bsSizeable;
      LinesplanFrame.SetBounds( Left+50,Top+75,Width-50,((4*Height) div 5)-75);
      ShowTranslatedValues( LinesplanFrame) ;
      LinesplanFrame.Ship:=St;
      LinesplanFrame.Viewport.ZoomExtents;
      LinesplanFrame.UpdateMenu;
      WindowMenu;
end end;


const S: array [0..3,0..3] of single
 = ( ( 0.7,  0,0.3,0.5 )    //  корпус
   , (   0,  0,0.7,0.5 )    //  бок
   , (   0,0.5,0.7,0.5 )    //  полуширота
   , ( 0.7,0.5,0.3,0.5 ) ); //  перспектива

procedure TMainForm.FOpenHullWindows;
var HullformWindow: THullWindow; I,J,W,H,L,T: Integer; R: TRect;
begin  W:=ClientWidth; H:=ClientHeight-72; L:=Left; T:=Top+75; //73;
   if St.nV=0 then
   for I:=3 downto 0 do begin                          // open a new window
      HullformWindow:=THullWindow.Create(self); // Connect viewport to ship component
      HullformWindow.St:=St;
      AddWindow( HullFormWindow );
      HullformWindow.PopUpParent:=Self;
//    PopupMode:=pmExplicit; =pmAuto; =pmNone;
      with HullformWindow do begin
         Viewport.ViewType:=TViewType( I );
         J:=ord( ViewPort.ViewType );  // fvBodyplan,fvProfile,fvPlan,fvPerspective
         R.Left  :=Round( S[J][0]*W )+L;
         R.Top   :=Round( S[J][1]*H )+T;
         R.Right :=Round( S[J][2]*W );
         R.Bottom:=Round( S[J][3]*H );
         FormStyle:=fsNormal; // (fsNormal, fsMDIChild, fsMDIForm, fsStayOnTop, fsSplash, fsSystemStayOnTop);
         SetBounds( R.Left,R.Top,R.Right,R.Bottom );
         BorderStyle:=bsSizeable; //Sizeable; //bsNone; //bsToolWindow; //bsDialog; //bsSingle; //bsSizeToolWin;
//       BorderIcons:= [biSystemMenu,biMaximize]; // , biMinimize, biMaximize, biHelp )]
         BorderWidth:=0;
         if Viewport.ViewType=fvPerspective then
            Viewport.ViewportMode:=vmShade;
         ViewPort.Invalidate;
//         ViewPort.Parent:=Self;
//         PopUpParent:=Self;
//         ViewPort.Show;
//         ShowOnTop;
      end;
      ShowTranslatedValues( HullformWindow );
      HullformWindow.SetCaption;
   end;
   SetCaption;
   WindowMenu;
end;

procedure TMainForm.TileView;
Var R: Trect; I,J,LU,RU,LD,RD,W,H,L,T: Integer;         // Количество наложений
begin LU:=0; RU:=0; LD:=0; RD:=0; W:=ClientWidth; H:=ClientHeight-72; L:=Left; T:=Top+73;
   for I:=0 to Windows.Count-1 do
   with THullWindow( Windows[I] ) do begin
      WindowState:=wsNormal;
      J:=ord(ViewPort.ViewType);   // fvBodyplan,fvProfile,fvPlan,fvPerspective
      R.Left  :=Round( S[J][0]*W )+L;
      R.Top   :=Round( S[J][1]*H )+T;
      R.Right :=Round( S[J][2]*W );
      R.Bottom:=Round( S[J][3]*H );
      if J=1 then begin R.left+=LU; R.Top+=LU; end else // fvProfile
      if J=2 then begin R.left+=LD; R.Top-=LD; end else // fvPlan
      if J=0 then begin R.left-=RU; R.Top+=RU; end else // fvBodyplan
      if J=3 then begin R.left-=RD; R.Top-=RD; end;     // fvPerspective
      SetBounds( R.Left,R.Top,R.Right,R.Bottom );
{     if Viewport.ViewType=fvPerspective then
         Viewport.ViewportMode:=vmShade;
}     if J=1 then LU+=25 else // постобработка последующих позиций
      if J=2 then LD+=25 else
      if J=0 then RU+=25 else
      if J=3 then RD+=25;
      ViewPort.Invalidate;
//    SetCaption;
   end;
   SetCaption;
   WindowMenu;
end;

procedure TMainForm.CascadeView; Var I,J,W0,H0,W,H,L,T: Integer;
begin
   W0:=ClientWidth;     W:=Round( 0.75*W0 ); J:=0;
   H0:=ClientHeight-72; H:=Round( 0.75*H0 ); L:=Left; T:=Top+73;
   for I:=0 to Windows.Count-1 do
   with THullWindow( Windows[I] ) do begin
      WindowState:=wsNormal;
      SetBounds( L+J,T+J,W,H );
      ViewPort.Invalidate;
      SetCaption;
      J+=25; if (J+W>W0) or (J+H>H0) then J:=0;
   end;
   SetCaption;
   WindowMenu;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var Answer:word;
begin if St.FileChanged then begin
        Answer:=MessageDlg(Userstring(103)+EOL+Userstring(282)+'?',mtWarning,[mbYes,mbNo],0);
        CanClose:=Answer=mrYes;
end; end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin St.Preferences.Save;
      St.OnChangeActiveLayer:=nil;
      St.OnChangeLayerData:=nil;
      St.OnSelectItem:=nil;
end;

procedure TMainForm.CascadeWindowExecute( Sender: TObject );
    begin if St.nV=0 then FOpenHullWindows; CascadeView; end;
procedure TMainForm.TileWindowExecute( Sender: TObject );
    begin if St.nV=0 then FOpenHullWindows else TileView;
    end;
procedure TMainForm.BothSidesExecute( Sender: TObject );
    begin if St.Visibility.ModelView=mvBoth
             then St.Visibility.ModelView:=mvPort
             else St.Visibility.ModelView:=mvBoth; UpdateMenu;
    end;

var AI: Array of TmenuItem = nil; // пополняемый статичесчкий массив строк меню
    NI: Integer = 0;              // почему-то Length от массива не срабатывает

procedure TMainForm.WinClick( Sender: TObject );
  var MI: TmenuItem; I: Integer;
begin mi:=Sender as TMenuItem;
   for I:=0 to Windows.Count-1 do
    if MI=AI[I] then with THullWindow( Windows[I] ) do begin
       WindowState:=wsNormal;
       BringToFront; exit
    end;
    if LinesplanFrame<>nil then if MI=AI[Windows.Count] then
    with LinesplanFrame do begin
       WindowState:=wsNormal; // Resizing( wsNormal ) ~ nV
       BringToFront;
end end;

procedure TMainForm.WindowMenu; Var I,N:Integer;
begin With St do begin N:=Windows.Count;
   if LinesplanFrame<>nil then inc( N );
   if AI=nil then begin if N>0 then Window1.AddSeparator;  // сначала отделение
   end else if NI>0 then for I:=NI-1 downto 0             // без старой менюшки
         do begin Window1.Remove( AI[I] ); AI[I].Free end;
   if N>0 then begin setLength( AI,N );
      for I:=0 to Windows.Count-1 do with THullWindow( Windows[I] ) do begin
         AI[I]:=TMenuItem.Create( Window1 );
         AI[I].Caption:=Caption;
         AI[I].onClick:=WinClick;
      end;
      if LinesplanFrame<>nil then begin
         AI[N-1]:=TMenuItem.Create( Window1 );    // LinesplanForm.Caption;
         AI[N-1].Caption:=ShowLinesplan.Caption;  //   'Теоретические чертежи';
         AI[N-1].onClick:=WinClick;
      end;
      Window1.Add( AI );
   end; NI:=N;                                 // и длина как есть запоминается
end end;
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

