{%MainUnit MDIPanel.pas}

{ WinPanelManager }
function WinPanelManager.GetMDIPanel(Index: Integer): TCustomMDIPanel;
begin Result := TCustomMDIPanel(MList[Index]); end;

//function WinPanelManager.GetPanelCount: integer;
//begin result := MList.Count; end;

constructor WinPanelManager.Create;
      begin inherited Create; MList:=TFPList.Create; end;

destructor WinPanelManager.Destroy;
     begin FreeAndNil( MList ); end; // inherited; end;

//function WinPanelManager.IndexOf( APanel: TCustomMDIPanel ): integer;
//begin result := MList.IndexOf( APanel ); end;

procedure WinPanelManager.Add(APanel: TCustomMDIPanel);
begin if APanel=nil then exit;
      MList.Add( APanel );
      APanel.MDIPanelManager:=self;
end;

procedure WinPanelManager.Insert(APanel: TCustomMDIPanel);
begin Insert( APanel,MList.Count );
      APanel.MDIPanelManager:=self;
end;

procedure WinPanelManager.Insert(APanel: TCustomMDIPanel; Index: integer);
begin if APanel = nil then exit;
      MList.Insert( Index,APanel );
      APanel.MDIPanelManager:=self;
end;
procedure WinPanelManager.Remove( APanel: TCustomMDIPanel );
begin if APanel=nil then exit; MList.Remove( APanel );
      APanel.PanelManager:=nil;                                     ///+++
end;

procedure WinPanelManager.Delete( Index: integer );
begin MList.Delete(Index); end;

function WinPanelManager.FindActivePanel: TCustomMDIPanel;
var i:integer;
begin result:=nil;
  for i:=0 to MList.Count-1 do
   if TCustomMDIPanel(MList[i]).Active then result:=TCustomMDIPanel(MList[i]);
end;

procedure WinPanelManager.Show( Cascad: Boolean  ); // const WN: array[0..3] of Integer=(3,1,0,2);
var MW,MH, W,H, M,MCC, i,j : Integer;
    WM: array[0..3] of Record x,y,w,h: Integer; end;
    panel  : TCustomMDIPanel;
    parent : TWinControl;
    swc    : TScrollingWinControl;
begin
  if MList.Count=0 then exit;
  parent:=Panels[0].Parent; // we get just parent of first MDIPanel. Assumed that all have same parent.
  if parent=nil then exit;

 MCC := MList.Count; if MCC=0 then exit else M:=MCC;

  MW := parent.ClientWidth;
  MH := parent.ClientHeight;
{ if (parent is TScrollingWinControl) then begin
    swc := TScrollingWinControl(parent);
    if (parent is TCustomForm) and TCustomForm(parent).AutoScroll then begin
      if ((swc.HorzScrollBar<>nil) and swc.HorzScrollBar.Visible)
      or ((swc.VertScrollBar<>nil) and swc.VertScrollBar.Visible) then begin
          MH := MH - swc.HorzScrollBar.Size;
          MW := MW - swc.VertScrollBar.Size; end;
    end else begin
      if (swc.HorzScrollBar<>nil) and swc.HorzScrollBar.IsScrollBarVisible then
          MH := MH - swc.HorzScrollBar.Size;
      if (swc.VertScrollBar<>nil) and swc.VertScrollBar.IsScrollBarVisible then
          MW := MW - swc.VertScrollBar.Size;
    end
  end;
}
  if Cascad and (M>1) then M:=0 else begin       // слева-направо и сверху-вниз
    if M>4 then M:=4; H:=MH div 2;
                      W:=MW div 3;
    if M=1 then begin WM[0].x:=0; WM[0].y:=0; WM[0].h:=MH; WM[0].w:=MW; end else
    if M=2 then begin WM[0].x:=0; WM[0].y:=H; WM[0].h:=H;  WM[0].w:=MW;
                      WM[1].x:=0; WM[1].y:=0; WM[1].h:=H;  WM[1].w:=MW; end else
    if M=3 then begin WM[0].x:=0; WM[0].y:=0; WM[0].h:=MH; WM[0].w:=W;
                      WM[1].x:=W; WM[1].y:=H; WM[1].h:=H; WM[1].w:=W*2;
                      WM[2].x:=W; WM[2].y:=0; WM[2].h:=H; WM[2].w:=W*2; end else
    begin WM[0].x:=W*2; WM[0].y:=0; WM[0].h:=H;   WM[0].w:=W;   // fvBodyplan
          WM[1].x:=0;   WM[1].y:=0; WM[1].h:=H;   WM[1].w:=W*2; // fvProfile
          WM[2].x:=0;   WM[2].y:=H; WM[2].h:=H;   WM[2].w:=W*2; // fvPlan
          WM[3].x:=W*2; WM[3].y:=H; WM[3].h:=H+2; WM[3].w:=W+2; // fvPerspective
    end;
    for i:=0 to M-1 do begin  panel:=Panels[i];
      if Assigned( panel ) then panel.SetBounds( WM[i].x,WM[i].y,WM[i].w,WM[i].h );
    end;
  end;
  if MCC>M then begin j:=MCC-M-1;
    if j=0 then begin W:=0; H:=0; j:=1; end else begin
      W:=MW div 16; MW -= W;
      H:=MH div 16; MH -= H; end;
    for i:=M to MCC-1 do begin panel:=Panels[i];
      if Assigned( panel ) then
         panel.SetBounds( ((i-M)*W) div j,
                          ((i-M)*H) div j, MW,MH );
    end;
  end;
end;

