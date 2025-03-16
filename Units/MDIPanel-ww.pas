—равнение файлов MDIPanel.pas и MDIPANEL-Z.PAS
***** MDIPanel.pas
                          wrszsSW, wrszsS, wrszsSE );
  TCaptionButton =     // Form title bar items
  ( cbSystemMenu,      // system menu
***** MDIPANEL-Z.PAS
                          wrszsSW, wrszsS, wrszsSE );
{ TCaptionButton =     // Form title bar items
  ( cbSystemMenu,      // system menu
*****

***** MDIPanel.pas
  TCaptionButtons = set of TCaptionButton;

type TMDIClientPanel = class(TPanel)
***** MDIPANEL-Z.PAS
  TCaptionButtons = set of TCaptionButton;
}
type TMDIClientPanel = class(TPanel)
*****

***** MDIPanel.pas
    FSystemButton: TImage;
    FCloseButton: TSpeedButton;
    FMaximizeButton: TSpeedButton;
    FMinimizeButton: TSpeedButton;
    FRestoreButton: TSpeedButton;
    FSystemPopupMenu: TPopupMenu;
    FMenuItemMinimize: TMenuItem;
    FMenuItemMaximize: TMenuItem;
    FMenuItemRestore: TMenuItem;
    FMenuItemClose: TMenuItem;
    PanelManager: WinPanelManager;
***** MDIPANEL-Z.PAS
    FSystemButton: TImage;
    FMenuItemMinimize,FMenuItemMaximize,FMenuItemRestore,FMenuItemClose: TMenuItem;
    FSystemPopupMenu: TPopupMenu;
    PanelManager: WinPanelManager;
*****

***** MDIPanel.pas
    FCornerSize: integer;
 // FBorderColor: TColor;
    FActiveBorderColor: TColor;
***** MDIPANEL-Z.PAS
    FCornerSize: integer;
    FActiveBorderColor: TColor;
*****

***** MDIPanel.pas
    FPassiveBevel: TGraphicControl;
//  FClickProxies: TFPList;
    FCaptionButtons: TCaptionButtons;
    FWindowResizingSide: TWindowResizingSide;
***** MDIPANEL-Z.PAS
    FPassiveBevel: TGraphicControl;
    FWindowResizingSide: TWindowResizingSide;
*****

***** MDIPanel.pas

 // FLastResizeWidth:integer;
 // FLastResizeHeight:integer;
 // FLastResizeClientWidth:integer;
 // FLastResizeClientHeight:integer;

    FClosing: boolean;
***** MDIPANEL-Z.PAS

    FClosing: boolean;
*****

***** MDIPanel.pas

    function getUniqueName(nameBase: AnsiString): AnsiString;
    procedure CreateCaptionPanel(aCaptionButtons:TCaptionButtons);
    procedure CreateClientPanel;
***** MDIPANEL-Z.PAS

    function getUniqueName( nameBase: AnsiString ): AnsiString;
    procedure CreateCaptionPanel;
    procedure CreateClientPanel;
*****

***** MDIPanel.pas
    procedure SystemButtonClick(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure DoClose(CloseAction: TCloseAction);
    procedure MaximizeButtonClick(Sender: TObject);
    procedure DoMaximize;
    procedure MinimizeButtonClick(Sender: TObject);
    procedure DoMinimize;
    procedure RestoreButtonClick(Sender: TObject);
    procedure DoRestore;
    procedure OrderButtons;
    procedure SetCaptionButtons(aVal:TCaptionButtons);
    procedure setDefaultSystemIcon;

//  procedure CreateSystemActions;
//  procedure ActionActionSystemMenuExecute(Sender: TObject);
 // function  drawCloseIcon(size: integer): TBitmap;
 // function  drawMaximizeIcon(size: integer): TBitmap;
 // function  drawMinimizeIcon(size: integer): TBitmap;
 // function  drawRestoreIcon(size: integer): TBitmap;

    procedure CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure CaptionPanelMouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
    procedure CaptionPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);

    procedure BorderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure BorderMouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
    procedure BorderMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure SetBorderCursor(X, Y: integer);

***** MDIPANEL-Z.PAS
    procedure SystemButtonClick(Sender: TObject);
    procedure CloseButtonClick( Sender: TObject);  procedure DoClose(CloseAction:TCloseAction);
    procedure MaximizeButtonClick(Sender:TObject); procedure DoMaximize;
    procedure MinimizeButtonClick(Sender:TObject); procedure DoMinimize;
    procedure RestoreButtonClick( Sender:TObject); procedure DoRestore;
    procedure OrderButtons;
    procedure setDefaultSystemIcon;
    procedure CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure CaptionPanelMouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
    procedure CaptionPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure BorderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure BorderMouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
    procedure BorderMouseUp( Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure SetBorderCursor( X,Y: integer );

*****

***** MDIPanel.pas
  protected
    procedure LMSysCommand(var message: TLMessage); message LM_SYSCOMMAND;
 // procedure Release;
    procedure Deactivate; virtual;
    procedure Paint; override;
    function  GetBorderColor: TColor;
    procedure SetActive(val: boolean);
    procedure SetActiveBorderColor(AValue: TColor);
    procedure SetInactiveBorderColor(AValue: TColor);
    procedure SetParent(NewParent: TWinControl); override;
    procedure AdjustClientRect(var ARect: TRect); override;
    procedure SetName(const Value: TComponentName); override;
***** MDIPANEL-Z.PAS
  protected
    procedure Deactivate; virtual;
    procedure SetActive(val: boolean);
    procedure SetParent(NewParent: TWinControl); override;
    procedure SetName(const Value: TComponentName); override;
*****

***** MDIPanel.pas
    procedure WndProc(var TheMessage: TLMessage); override;
 // procedure Resize; override;
  private
 // function IsIconStored: Boolean;
    procedure ProcessResource;
***** MDIPANEL-Z.PAS
    procedure WndProc(var TheMessage: TLMessage); override;
  private
    procedure ProcessResource;
*****

***** MDIPanel.pas
    procedure RemoveControl( AControl: TControl ); override;

 // function GetIcon: TIcon; procedure SetIcon( val:TIcon );

    property Controls[Index: integer]: TControl read GetControl;
 // property ControlCount: integer read GetControlCount;

    property CaptionButtons:TCaptionButtons read FCaptionButtons write SetCaptionButtons;
    property FormStyle:TFormStyle read FFormStyle write FFormStyle default fsMDIChild;
***** MDIPANEL-Z.PAS
    procedure RemoveControl( AControl: TControl ); override;
    property Controls[Index: integer]: TControl read GetControl;
    property FormStyle:TFormStyle read FFormStyle write FFormStyle default fsMDIChild;
*****

***** MDIPanel.pas
    property Active: boolean read FActive write setActive;
    property BorderColor: TColor read GetBorderColor;
    property ActiveBorderColor: TColor read FActiveBorderColor write SetActiveBorderColor default clDefault;
    property InactiveBorderColor: TColor read FInactiveBorderColor write SetInactiveBorderColor default clDefault;
    property Caption: TCaption read GetCaption write SetCaption;
***** MDIPANEL-Z.PAS
    property Active: boolean read FActive write setActive;
    property Caption: TCaption read GetCaption write SetCaption;
*****

***** MDIPanel.pas
    property CaptionPanel: TPanel read FCaptionPanel;
 // property Icon: TIcon read getIcon write setIcon stored IsIconStored;
    property OnActivate: TNotifyEvent read FOnActivate write FOnActivate;
***** MDIPANEL-Z.PAS
    property CaptionPanel: TPanel read FCaptionPanel;
    property OnActivate: TNotifyEvent read FOnActivate write FOnActivate;
*****

***** MDIPanel.pas
      property OnWindowStateChange: TNotifyEvent read FOnWindowStateChange write FOnWindowStateChange;
   {  property ParentFont default False;
      property Position: TPosition read FPosition write SetPosition default poDesigned;
      property RestoredLeft: integer read FRestoredLeft;
      property RestoredTop: integer read FRestoredTop;
      property RestoredWidth: integer read FRestoredWidth;
      property RestoredHeight: integer read FRestoredHeight;
      property Visible stored VisibleIsStored default false;
   }
      property PixelsPerInch: Integer read FPixelsPerInch write FPixelsPerInch stored False;
***** MDIPANEL-Z.PAS
      property OnWindowStateChange: TNotifyEvent read FOnWindowStateChange write FOnWindowStateChange;
      property PixelsPerInch: Integer read FPixelsPerInch write FPixelsPerInch stored False;
*****

***** MDIPanel.pas
    property Active;
    property BorderColor;
    property ActiveBorderColor;
    property InactiveBorderColor;
    property Caption;
***** MDIPANEL-Z.PAS
    property Active;
    property Caption;
*****

***** MDIPanel.pas
    property CaptionPanel;
//  property Icon;
    property OnActivate;
***** MDIPANEL-Z.PAS
    property CaptionPanel;
    property OnActivate;
*****

***** MDIPanel.pas
    property OnShow;

    // from TForm
    property Action;
    property ActiveControl;
***** MDIPANEL-Z.PAS
    property OnShow;
    property Action;                                          // from TForm
    property ActiveControl;
*****

***** MDIPanel.pas
    property Anchors;
//  property AutoScroll;
    property AutoSize;
***** MDIPANEL-Z.PAS
    property Anchors;
    property AutoSize;
*****

***** MDIPanel.pas
    property BiDiMode;
//  property BorderIcons;
    property BorderStyle;
***** MDIPANEL-Z.PAS
    property BiDiMode;
    property BorderStyle;
*****

***** MDIPanel.pas
  WindowPositionState:=wpsNone;
  FCaptionButtons:=[cbSystemMenu,cbMinimize,cbMaximize,cbRestore,cbClose];
  CreateCaptionPanel([cbSystemMenu,cbMinimize,cbMaximize,cbRestore,cbClose]);
  CreateClientPanel;
***** MDIPANEL-Z.PAS
  WindowPositionState:=wpsNone;
///but  FCaptionButtons:=[cbSystemMenu,cbMinimize,cbMaximize,cbRestore,cbClose];
  CreateCaptionPanel; //([cbSystemMenu,cbMinimize,cbMaximize,cbRestore,cbClose]);
  CreateClientPanel;
*****

***** MDIPanel.pas
  GlobalNameSpace.BeginWrite;
  CreateNew( AOwner );   // this calls BeginFormUpdate, which is ended in AfterConstruction
  if (ClassType<>TMDIPanel) and not (csDesigning in ComponentState) then begin
***** MDIPANEL-Z.PAS
  GlobalNameSpace.BeginWrite;
  CreateNew( AOwner ); // this calls BeginFormUpdate, which is ended in AfterConstruction
  if (ClassType<>TMDIPanel) and not (csDesigning in ComponentState) then begin
*****

***** MDIPanel.pas
     Include( FFormState,fsCreating );
     ProcessResource;              // load controls from the program resources to FClientControls
     Exclude( FFormState,fsCreating );
***** MDIPANEL-Z.PAS
     Include( FFormState,fsCreating );
     ProcessResource; // load controls from the program resources to FClientControls
     Exclude( FFormState,fsCreating );
*****

***** MDIPanel.pas
procedure TCustomMDIPanel.ProcessResource;
begin InitResourceComponent( Self,TMDIPanel );
(*if not InitResourceComponent(Self, TMDIPanel) then
    if RequireDerivedFormResource
      then raise EResNotFound.CreateFmt( rsFormResourceSNotFoundForResourcelessFormsCreateNew,[ClassName] )
      else DebugLn(Format(rsFormResourceSNotFoundForResourcelessFormsCreateNew, [ClassName])); *)
end;

***** MDIPANEL-Z.PAS
procedure TCustomMDIPanel.ProcessResource;
    begin InitResourceComponent( Self,TMDIPanel ); end;

*****

***** MDIPanel.pas
end;

procedure TCustomMDIPanel.LMSysCommand(var message: TLMessage);
begin if (message.WParam and $FFF0)=SC_CLOSE then begin DoClose(caFree); end;
          message.Result:=0;
end;

procedure TCustomMDIPanel.FActionCloseOnExecute(sender:TObject );
***** MDIPANEL-Z.PAS
end;
procedure TCustomMDIPanel.FActionCloseOnExecute(sender:TObject );
*****

***** MDIPanel.pas
  fd:=GetFontData( FCaptionPanel.Font.Handle );             // TFontData.Height is in logical units, convert it to pixels
  H:=abs(round(1.0 * fd.Height * Font.PixelsPerInch/72.0)); // add 4 so font does not touch borders
  result:=h+4;
***** MDIPANEL-Z.PAS
  fd:=GetFontData( FCaptionPanel.Font.Handle );             // TFontData.Height is in logical units, convert it to pixels
  H:=abs(round(1.0*fd.Height*Font.PixelsPerInch/72.0)); // add 4 so font does not touch borders
  result:=h+4;
*****

***** MDIPanel.pas

procedure TCustomMDIPanel.CreateCaptionPanel( aCaptionButtons:TCaptionButtons );
var SCH: integer;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.CreateCaptionPanel;
var SCH: integer;
*****

***** MDIPanel.pas
  FCaptionPanel.Constraints.MinHeight:=deriveCaptionHeight;
  SetCaptionButtons( aCaptionButtons );
end;
***** MDIPANEL-Z.PAS
  FCaptionPanel.Constraints.MinHeight:=deriveCaptionHeight;
  FSystemButton:=TImage.Create( Self );
  with FSystemButton
    do begin onClick:=@SystemButtonClick; setDefaultSystemIcon; end;
end;
*****

***** MDIPanel.pas

procedure TCustomMDIPanel.SetCaptionButtons(aVal:TCaptionButtons);
//var
// IconSize: integer;
// IconSizeString: AnsiString;
begin  // exit;
  if aVal=FCaptionButtons then exit; FCaptionButtons:=aVal;

//IconSize:=deriveCaptionIconHeight-4;
//IconSizeString:=IntToStr(IconSize)+'x'+IntToStr(IconSize);
//IconSizeString:='X';
(*
  if not (cbSystemMenu in FCaptionButtons) and assigned(FSystemButton) then FreeAndNil(FSystemButton);
  if not (cbClose in FCaptionButtons) and assigned(FCloseButton) then FreeAndNil(FCloseButton);
  if not (cbMinimize in FCaptionButtons) and assigned(FMinimizeButton) then FreeAndNil(FMinimizeButton);
  if not (cbMaximize in FCaptionButtons) and assigned(FMaximizeButton) then FreeAndNil(FMaximizeButton);
  if not (cbRestore in FCaptionButtons) and assigned(FRestoreButton) then FreeAndNil(FRestoreButton);
*)
  //h:=deriveCaptionIconHeight;
  if (cbSystemMenu in FCaptionButtons) and (FSystemButton = nil) then begin
    FSystemButton:=TImage.Create( Self );
    with FSystemButton do
         begin onClick:=@SystemButtonClick; setDefaultSystemIcon; end;
  end;
  if (cbClose in FCaptionButtons) and (FCloseButton = nil) then begin
    FCloseButton:=TSpeedButton.Create(Self);
    with FCloseButton do begin
      Parent:=FCaptionPanel;
      Left:=200;
      Align:=alRight;
      onClick:=@CloseButtonClick;
      AutoSize:=True;
      ParentFont:=False;
      Font.Color:=clWindowText;
      Font.Style:=[fsBold];
      Caption:=' x ';
    end;
  end;
  if (cbMaximize in FCaptionButtons) and (FMaximizeButton = nil) then begin
    FMaximizeButton:=TSpeedButton.Create(Self);
    with FMaximizeButton do begin
      Parent:=FCaptionPanel;
      Left:=100;
      Align:=alRight;
      AutoSize:=True;
      AllowAllUp:=True;
      onClick:=@MaximizeButtonClick;
      Font.Color:=clWindowText;
      Font.Style:=[fsBold];
      ParentFont:=False;
      Caption:=' т÷— '
    end;
  end;
  if (cbMinimize in FCaptionButtons) and (FMinimizeButton = nil)  then begin
    FMinimizeButton:=TSpeedButton.Create(Self);
    with FMinimizeButton do begin
      Parent:=FCaptionPanel;
      Left:=80;
      Align:=alRight;
      AutoSize:=True;
      AllowAllUp:=True;
      onClick:=@MinimizeButtonClick;
      Font.Color:=clWindowText;
      Font.Style:=[fsBold];
      ParentFont:=False;
      Caption:=' тјж ';
    end;
  end;
  if (cbRestore in FCaptionButtons) and (FRestoreButton = nil) then begin
    FRestoreButton:=TSpeedButton.Create(Self);
    with FRestoreButton do begin
      Parent:=FCaptionPanel;
      Left:=60;
      Align:=alRight;
      AutoSize:=True;
      AllowAllUp:=True;
      onClick:=@RestoreButtonClick;
      Font.Color:=clBlue; //WindowText;
      Font.Style:=[fsBold];
      ParentFont:=False;
      Caption:=' т÷а ';
      Visible:=False;
    end;
  end;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.SetName(const Value: TComponentName);
var Newname:AnsiString;  gCnt:integer;
begin
  if Owner.FindComponent(Value) = nil then inherited SetName(Value)
  else begin
    gCnt:=Owner.ComponentCount;
    Newname:=Value+'__'+IntToStr(gCnt+1);
    inherited SetName(NewName);
  end;
*****

***** MDIPanel.pas
end;
(*
function TCustomMDIPanel.GetIcon: TIcon;
begin result:=nil;
  if not assigned(FSystemButton) then exit;
  if not assigned(FSystemButton.Picture) then exit;
  if not assigned(FSystemButton.Picture.Icon) then exit;
  result:=TIcon.Create;
  result.Assign(FSystemButton.Picture.Icon);
end;
procedure TCustomMDIPanel.SetIcon(val: TIcon);
begin FSystemButton.Picture.Icon.Assign(val); end;
*)
procedure TCustomMDIPanel.Paint;
var IRect: TRect; ibw:integer;
begin
  inherited Paint;
  IRect:=GetClientRect;
  ibw:=0;
  if self.BevelInner <> bvNone then ibw:=BevelWidth;
  InflateRect(IRect, -ibw, -ibw);
  Canvas.Frame3d(IRect, BorderColor, BorderColor, BorderWidth);
end;
{
procedure TCustomMDIPanel.Resize;
var cw,ch:integer;
begin
  inherited Resize;
  cw:=ClientWidth; ch:=ClientHeight;                // AdjustClientRect(Rect();
  {
  if ([csLoading,csDestroying]*ComponentState<>[]) then exit;
  if AutoSizeDelayed then exit;
  cw:=ClientWidth; ch:=ClientHeight;
  if (FLastResizeWidth<>Width) or (FLastResizeHeight<>Height)
  or (FLastResizeClientWidth<>ClientWidth)
  or (FLastResizeClientHeight<>ClientHeight) then
  begin
    inherited Resize;
    FLastResizeWidth:=Width;
    FLastResizeHeight:=Height;
    FLastResizeClientWidth:=ClientWidth;
    FLastResizeClientHeight:=ClientHeight;
  end;
  }
end;
}
function TCustomMDIPanel.GetBorderColor: TColor;
begin
  if Active then
    if FActiveBorderColor <> clDefault
      then result:=FActiveBorderColor
      else if ColorToRGB(clActiveBorder)<>ColorToRGB(clInactiveBorder)
         then result:=clActiveBorder
         else result:=clActiveCaption
  else
    if FInactiveBorderColor <> clDefault
      then result:=FInactiveBorderColor
      else if ColorToRGB(clActiveBorder)<>ColorToRGB(clInactiveBorder)
         then result:=clInactiveBorder
         else result:=clInactiveCaption;
end;
***** MDIPANEL-Z.PAS
end;


procedure TCustomMDIPanel.WndProc( var TheMessage: TLMessage );// does not help
var Form: TCustomForm;
begin                                                      // keyboard messages
  if (TheMessage.Msg>=LM_KEYFIRST) and (TheMessage.Msg<=LM_KEYLAST) then begin
      Form:=GetParentForm( Self );
      if (Form<>nil) and (Form.WantChildKey(Self,TheMessage)) then exit;
   end;
   Dispatch( TheMessage );
end;
*****

***** MDIPanel.pas

procedure TCustomMDIPanel.SetActiveBorderColor(AValue: TColor);
begin
  if FActiveBorderColor <> AValue then begin
    FActiveBorderColor:=AValue;
    Invalidate;
  end;
end;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.setDefaultSystemIcon;
var icn:TIcon; sz,ch:integer; pf:TCustomForm;
{ function getParentForm( c:TControl ): TCustomForm;
  begin result:=nil;
    if assigned(c.Parent) then
    if (c.Parent is TCustomForm) then result:=TCustomForm(c.Parent)
                                 else getParentForm(c.Parent); end; }
begin
  pf:=getParentForm(Self);
  if assigned(pf)
  and assigned(TCustomForm(pf).Icon) and (TCustomForm(pf).Icon.Width>0)
       then icn:=TCustomForm( pf ).Icon
       else icn:=Application.Icon;
  FSystemButton.Parent:=nil;
  FSystemButton.Picture.Icon.Assign(icn);
  FSystemButton.Stretch:=true;
  ch:=FCaptionPanel.ClientHeight;
  sz:=deriveCaptionIconHeight;
  FSystemButton.Constraints.MaxHeight:=sz;
  FSystemButton.Constraints.MaxWidth:=sz;
  FSystemButton.BorderSpacing.Around:=(ch-sz)div 2;
  FSystemButton.Parent:=FCaptionPanel;
end;
*****

***** MDIPanel.pas

procedure TCustomMDIPanel.SetInactiveBorderColor(AValue: TColor);
begin
  if FInactiveBorderColor <> AValue then begin
    FInactiveBorderColor:=AValue;
    Invalidate;
  end;
end;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.SetParent(NewParent: TWinControl);
var H:integer; //bv:TPanelBevel; bw:integer;  bs:TBorderStyle;
begin
  if Parent = NewParent then exit;
  inherited SetParent( NewParent );
  FParentForm:=GetParentForm(Self);
  if assigned(FSystemButton) then setDefaultSystemIcon;
   // with FSystemButton do begin setDefaultSystemIcon; end;
  Invalidate;
  FCaptionPanel.AdjustSize;
  H:=FCaptionPanel.Height+2*BorderWidth;
  if BevelInner<>bvNone then H:=H+2*BevelWidth;
  if BevelOuter<>bvNone then H:=H+2*BevelWidth;
  Constraints.MinHeight:=H+4; // +4-to prevent lower border disappear
  Constraints.MinWidth :=200;
end;
*****

***** MDIPanel.pas

procedure TCustomMDIPanel.AdjustClientRect(var ARect: TRect);
begin
  inherited AdjustClientRect( ARect );
  self.FCornerSize:=10;
  if ClientRect.Left > 10 then self.FCornerSize:=ClientRect.Left;
end;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.CreateClientPanel;
begin
  FClientPanel:=TMDIClientPanel.Create( Self );
  with FClientPanel do begin Parent:=Self;
    Name:='ClientPanel';    Align:=alClient;
    TabStop:=False;         BevelOuter:=bvNone;
    BevelInner:=bvNone;     BorderStyle:=bsNone;                    //bsSingle;
    BorderWidth:=0;         TabStop:=true;                       // to get keys
  end;
end;
*****

***** MDIPanel.pas

procedure TCustomMDIPanel.SetName(const Value: TComponentName);
var Newname:AnsiString;  gCnt:integer;
begin
  if Owner.FindComponent(Value) = nil then inherited SetName(Value)
  else begin
    gCnt:=Owner.ComponentCount;
    Newname:=Value+'__'+IntToStr(gCnt+1);
    inherited SetName(NewName);
  end;
end;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.DeleteSystemPopupMenu; var MenuItem: TMenuItem;
begin
  FActionClose.ActionList:=nil;
  FreeAndNil( FActionClose );
  FreeAndNil( FActionList );
  FreeAndNil( FMenuItemMaximize );
  FreeAndNil( FMenuItemMinimize );
  FreeAndNil( FMenuItemRestore );
  FreeAndNil( FMenuItemClose );
  while FSystemPopupMenu.Items.Count>0 do begin
     MenuItem:=FSystemPopupMenu.Items[0];
     FreeAndNil(MenuItem);
  end;
  FreeAndNil( FSystemPopupMenu );
end;
*****

***** MDIPanel.pas

// does not help
procedure TCustomMDIPanel.WndProc( var TheMessage: TLMessage );
var Form: TCustomForm;
begin                                             //DebugLn('CCC TControl.WndPRoc ',Name,':',ClassName);
{   if (csDesigning in ComponentState) then begin // redirect messages to designer
      Form:=GetDesignerForm(Self);              //debugln(['TControl.WndProc ',dbgsname(Self)]);
      if Assigned(Form) and Assigned(Form.Designer) and Form.Designer.IsDesignMsg(Self, TheMessage) then
      Exit;
    end else
}
  if (TheMessage.Msg >= LM_KEYFIRST) and (TheMessage.Msg <= LM_KEYLAST)
    then begin                                             // keyboard messages
      Form:=GetParentForm( Self );
      if (Form <> nil) and (Form.WantChildKey(Self,TheMessage)) then exit;
    end;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.CreateSystemPopupMenu; var MenuItem: TMenuItem;
begin
  FSystemPopupMenu:=TPopupMenu.Create(Self);

  FMenuItemMaximize:=TMenuItem.Create(Self);
  FMenuItemMaximize.Name:='Maximize';
  FMenuItemMaximize.OnClick:=@MaximizeButtonClick;
  FSystemPopupMenu.Items.Add(FMenuItemMaximize);

  FMenuItemMinimize:=TMenuItem.Create(Self);
  FMenuItemMinimize.Name:='Minimize';
  FMenuItemMinimize.OnClick:=@MinimizeButtonClick;
  FSystemPopupMenu.Items.Add(FMenuItemMinimize);

  FMenuItemRestore:=TMenuItem.Create(Self);
  FMenuItemRestore.Name:='Restore';
  FMenuItemRestore.OnClick:=@RestoreButtonClick;
  FSystemPopupMenu.Items.Add(FMenuItemRestore);

  MenuItem:=TMenuItem.Create(Self);
  MenuItem.Caption:='-';
  MenuItem.Name:='Separator';
  FSystemPopupMenu.Items.Add(MenuItem);

  FActionList:=TActionList.Create(self);
  FActionClose:=TAction.Create(self);
  FActionClose.Name:='ActionClose';
  FActionClose.Caption:='Close';
  FActionClose.OnExecute:=@FActionCloseOnExecute;
  FActionClose.ActionList:=FActionList;

  FMenuItemClose:=TMenuItem.Create(Self);
  FMenuItemClose.Name:='Close';
  FMenuItemClose.Action:=FActionClose;
  FMenuItemClose.OnClick:=@CloseButtonClick;
  FSystemPopupMenu.Items.Add(FMenuItemClose);

  self.FCaptionPanel.PopupMenu:=FSystemPopupMenu;
end;
(*
procedure TCustomMDIPanel.ActionActionSystemMenuExecute(Sender:TObject);begin end;
procedure TCustomMDIPanel.CreateSystemActions;
var Act:TAction;
begin
   FActionList:=TActionList.Create(Self);
   FActionList.name:='ActionList';
   Act:=TAction.Create(Self);
   Act.ActionList:=FActionList;
   Act.Name:='ActionSystemMenu';
   Act.ShortCut:=TextToShortcut('Alt+Space');
   Act.OnExecute:=@ActionActionSystemMenuExecute;
   Act:=TAction.Create(Self);
   Act.ActionList:=FActionList;
   Act.Name:='ActionSystemMenu';
   Act.ShortCut:=TextToShortCut('Alt+F4');
   Act.OnExecute:=@CloseButtonClick;
end;
*)
procedure TCustomMDIPanel.SetBorderCursor( X,Y: integer );
begin
  FWindowResizingSide:=wrszsZ;
  Cursor:=crDefault;
  if X <= FCornerSize then begin
    if Y <= FCornerSize then begin
      FWindowResizingSide:=wrszsNW;
      Cursor:=crSizeNW;
    end
    else if Y >= Height-FCornerSize then begin
      FWindowResizingSide:=wrszsSW;
      Cursor:=crSizeSW;
    end else begin
      FWindowResizingSide:=wrszsW;
      Cursor:=crSizeWE;
    end;
  end
  else if X >= Width-FCornerSize then begin
    if Y <= FCornerSize then begin
      FWindowResizingSide:=wrszsNE;
      Cursor:=crSizeNE;
    end
    else if Y >= Height-FCornerSize then begin
      FWindowResizingSide:=wrszsSE;
      Cursor:=crSizeSE;
    end else begin
      FWindowResizingSide:=wrszsE;
      Cursor:=crSizeWE;
    end;
  end else begin  // X in mid
    if Y <= FCornerSize then begin
      FWindowResizingSide:=wrszsN;
      Cursor:=crSizeNS;
    end
    else if Y >= Height-FCornerSize then begin
      FWindowResizingSide:=wrszsS;
      Cursor:=crSizeNS;
    end else begin
      FWindowResizingSide:=wrszsZ;
      Cursor:=crSizeNS;
    end;
*****

***** MDIPanel.pas
    end;
    Dispatch( TheMessage );
end;
***** MDIPANEL-Z.PAS
    end;
  end;
end;
*****

***** MDIPanel.pas

//function TCustomMDIPanel.IsIconStored: Boolean; begin result:=Icon<>nil; end;

procedure TCustomMDIPanel.setDefaultSystemIcon;
var icn:TIcon; sz,ch:integer; pf:TCustomForm;
{
  function getParentForm(c:TControl):TCustomForm;
  begin result:=nil;
    if assigned(c.Parent) then
    if (c.Parent is TCustomForm) then result:=TCustomForm(c.Parent)
                                 else getParentForm(c.Parent); end;
}
begin
  pf:=getParentForm(Self);
  if assigned(pf) and assigned(TCustomForm(pf).Icon)
  and (TCustomForm(pf).Icon.Width>0)
       then icn:=TCustomForm( pf ).Icon
       else icn:=Application.Icon;
  FSystemButton.Parent:=nil;
  FSystemButton.Picture.Icon.Assign(icn);
  FSystemButton.Stretch:=true;
  ch:=FCaptionPanel.ClientHeight;
  sz:=deriveCaptionIconHeight;
  FSystemButton.Constraints.MaxHeight:=sz;
  FSystemButton.Constraints.MaxWidth:=sz;
  FSystemButton.BorderSpacing.Around:=(ch-sz)div 2;
  FSystemButton.Parent:=FCaptionPanel;
end;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.BorderMouseDown
( Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y:integer );
var TL: TPoint;
begin
  if (Button = mbLeft) and (Shift = [ssLeft]) then begin
    WindowPositionState:=wpsResizing;
    TL:=Parent.ClientToScreen(BoundsRect.TopLeft);                              //writeln('d:',Mouse.CursorPos.X, ':', Mouse.Cu
rsorPos.Y);
    WindowCaptionMouseX:=Mouse.CursorPos.X-TL.X;
    WindowCaptionMouseY:=Mouse.CursorPos.Y-TL.Y;
    setActive(True);
  end;
end;
*****

***** MDIPanel.pas

procedure TCustomMDIPanel.SetParent(NewParent: TWinControl);
var H:integer; //bv:TPanelBevel; bw:integer;  bs:TBorderStyle;
begin
  if Parent = NewParent then exit;
  inherited SetParent( NewParent );
  FParentForm:=GetParentForm(Self);
  { bv:=BevelOuter;
    bv:=BevelInner;
    bw:=BevelWidth;
    bs:=BorderStyle;
    bw:=BorderWidth;
  }
  if assigned(FSystemButton) then setDefaultSystemIcon;
   // with FSystemButton do begin setDefaultSystemIcon; end;
  Invalidate;
  FCaptionPanel.AdjustSize;
  H:=FCaptionPanel.Height+2*BorderWidth;
  if BevelInner<>bvNone then H:=H+2*BevelWidth;
  if BevelOuter<>bvNone then H:=H+2*BevelWidth;
  Constraints.MinHeight:=H+4; // +4-to prevent lower border disappear
  Constraints.MinWidth :=200;
end;

procedure TCustomMDIPanel.CreateClientPanel;
begin
  FClientPanel:=TMDIClientPanel.Create(Self);
  with FClientPanel do begin
    Parent:=Self;
    Name:='ClientPanel';
    Align:=alClient;
    TabStop:=False;
    BevelOuter:=bvNone;
    BevelInner:=bvNone;
    BorderStyle:=bsNone; //bsSingle;
    BorderWidth:=0;
    TabStop:=true; // to get keys
  end;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.BorderMouseMove
( Sender: TObject; Shift: TShiftState; X,Y: integer );
var TL,SL: TPoint; L,T,W,H: integer;
begin
  if not (WindowPositionState = wpsResizing) then SetBorderCursor( X,Y );
  if (Shift=[ssLeft]) and (WindowPositionState=wpsResizing) then begin          // writeln('m:',Mouse.CursorPos.X,':',Mouse.Cur
sorPos.Y,' sender:',TControl(Sender).Name);
    L:=Left;
    T:=Top;
    W:=Width;
    H:=Height;
    case FWindowResizingSide of
      wrszsNW: begin
        SL:=Point(Mouse.CursorPos.X-WindowCaptionMouseX,Mouse.CursorPos.Y-WindowCaptionMouseY);
        TL:=Parent.ScreenToClient(SL);
        H:=H-(TL.Y-T);
        W:=W-(TL.X-L);
        L:=TL.X;
        T:=TL.Y;
      end;
      wrszsN: begin
        SL:=Point(Mouse.CursorPos.X-WindowCaptionMouseX,Mouse.CursorPos.Y-WindowCaptionMouseY);
        TL:=Parent.ScreenToClient(SL);
        H:=H-(TL.Y-T);
        T:=TL.Y;
      end;
      wrszsNE: begin
        W:=X;
        SL:=Point( Mouse.CursorPos.X-WindowCaptionMouseX,Mouse.CursorPos.Y-WindowCaptionMouseY);
        TL:=Parent.ScreenToClient(SL);
        H:=H-(TL.Y-T);
        T:=TL.Y;
      end;
      wrszsE:  W:=X;
      wrszsSE: begin W:=X; H:=Y; end;
      wrszsS:  H:=Y;
      wrszsSW: begin
        H:=Y;
        SL:=Point(Mouse.CursorPos.X-WindowCaptionMouseX,Mouse.CursorPos.Y-WindowCaptionMouseY);
        TL:=Parent.ScreenToClient(SL);
        W:=W-(TL.X-L);
        L:=TL.X;
      end;
      wrszsW: begin
        SL:=Point(Mouse.CursorPos.X-WindowCaptionMouseX,Mouse.CursorPos.Y-WindowCaptionMouseY);
        TL:=Parent.ScreenToClient(SL);
        W:=W-(TL.X-L);
        L:=TL.X;
      end;
    end;                                                                        // writeln('setBounds(', L, ',', T, ',', W, ','
, H, ')');
    setBounds( L,T,W,H );
  end;
*****

***** MDIPanel.pas

procedure TCustomMDIPanel.DeleteSystemPopupMenu;
var MenuItem: TMenuItem;
begin
  FActionClose.ActionList:=nil;
  FreeAndNil(FActionClose);
  FreeAndNil(FActionList);
  FreeAndNil(FMenuItemMaximize);
  FreeAndNil(FMenuItemMinimize);
  FreeAndNil(FMenuItemRestore);
  FreeAndNil(FMenuItemClose);
  while FSystemPopupMenu.Items.Count>0 do begin
     MenuItem:=FSystemPopupMenu.Items[0];
     FreeAndNil(MenuItem);
  end;
  FreeAndNil( FSystemPopupMenu );
end;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.BorderMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  if (WindowPositionState = wpsResizing) then WindowPositionState:=wpsNone;
end;
*****

Ќе удаетс€ выполнить синхронизацию строк. —лишком много различий между файлами.
***** MDIPanel.pas

procedure TCustomMDIPanel.CreateSystemPopupMenu;
var
  MenuItem: TMenuItem;
begin
  FSystemPopupMenu:=TPopupMenu.Create(Self);

  FMenuItemMaximize:=TMenuItem.Create(Self);
  FMenuItemMaximize.Name:='Maximize';
  FMenuItemMaximize.OnClick:=@MaximizeButtonClick;
  FSystemPopupMenu.Items.Add(FMenuItemMaximize);

  FMenuItemMinimize:=TMenuItem.Create(Self);
  FMenuItemMinimize.Name:='Minimize';
  FMenuItemMinimize.OnClick:=@MinimizeButtonClick;
  FSystemPopupMenu.Items.Add(FMenuItemMinimize);

  FMenuItemRestore:=TMenuItem.Create(Self);
  FMenuItemRestore.Name:='Restore';
  FMenuItemRestore.OnClick:=@RestoreButtonClick;
  FSystemPopupMenu.Items.Add(FMenuItemRestore);

  MenuItem:=TMenuItem.Create(Self);
  MenuItem.Caption:='-';
  MenuItem.Name:='Separator';
  FSystemPopupMenu.Items.Add(MenuItem);

  FActionList:=TActionList.Create(self);
  FActionClose:=TAction.Create(self);
  FActionClose.Name:='ActionClose';
  FActionClose.Caption:='Close';
  FActionClose.OnExecute:=@FActionCloseOnExecute;
  FActionClose.ActionList:=FActionList;

  FMenuItemClose:=TMenuItem.Create(Self);
  FMenuItemClose.Name:='Close';
  FMenuItemClose.Action:=FActionClose;
  FMenuItemClose.OnClick:=@CloseButtonClick;
  FSystemPopupMenu.Items.Add(FMenuItemClose);

  self.FCaptionPanel.PopupMenu:=FSystemPopupMenu;
end;
(*
procedure TCustomMDIPanel.ActionActionSystemMenuExecute(Sender:TObject);begin end;
procedure TCustomMDIPanel.CreateSystemActions;
var Act:TAction;
begin
   FActionList:=TActionList.Create(Self);
   FActionList.name:='ActionList';
   Act:=TAction.Create(Self);
   Act.ActionList:=FActionList;
   Act.Name:='ActionSystemMenu';
   Act.ShortCut:=TextToShortcut('Alt+Space');
   Act.OnExecute:=@ActionActionSystemMenuExecute;
   Act:=TAction.Create(Self);
   Act.ActionList:=FActionList;
   Act.Name:='ActionSystemMenu';
   Act.ShortCut:=TextToShortCut('Alt+F4');
   Act.OnExecute:=@CloseButtonClick;
end;
*)
procedure TCustomMDIPanel.SetBorderCursor(X, Y: integer);
begin
  FWindowResizingSide:=wrszsZ;
  Cursor:=crDefault;
  if X <= FCornerSize then begin
    if Y <= FCornerSize then begin
      FWindowResizingSide:=wrszsNW;
      Cursor:=crSizeNW;
    end
    else if Y >= Height-FCornerSize then begin
      FWindowResizingSide:=wrszsSW;
      Cursor:=crSizeSW;
    end else begin
      FWindowResizingSide:=wrszsW;
      Cursor:=crSizeWE;
    end;
  end
  else if X >= Width-FCornerSize then begin
    if Y <= FCornerSize then begin
      FWindowResizingSide:=wrszsNE;
      Cursor:=crSizeNE;
    end
    else if Y >= Height-FCornerSize then begin
      FWindowResizingSide:=wrszsSE;
      Cursor:=crSizeSE;
    end else begin
      FWindowResizingSide:=wrszsE;
      Cursor:=crSizeWE;
    end;
  end else begin  // X in mid
    if Y <= FCornerSize then begin
      FWindowResizingSide:=wrszsN;
      Cursor:=crSizeNS;
    end
    else if Y >= Height-FCornerSize then begin
      FWindowResizingSide:=wrszsS;
      Cursor:=crSizeNS;
    end else begin
      FWindowResizingSide:=wrszsZ;
***** MDIPANEL-Z.PAS

procedure TCustomMDIPanel.CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var TL: TPoint;
begin
  if (Button = mbLeft) and (Shift = [ssLeft]) then begin
    WindowPositionState:=wpsMoving;
  //TL:=ClientToScreen(TPanel(TPanel(Sender).Parent).BoundsRect.TopLeft);
    TL:=Parent.ClientToScreen( BoundsRect.TopLeft );                            //writeln('d:',Mouse.CursorPos.X, ':', Mouse.Cu
rsorPos.Y);
    WindowCaptionMouseX:=Mouse.CursorPos.X-TL.X;
    WindowCaptionMouseY:=Mouse.CursorPos.Y-TL.Y;
    setActive(True);
  end;
end;
procedure TCustomMDIPanel.CaptionPanelMouseMove
  ( Sender: TObject; Shift: TShiftState; X,Y: integer);
var TL,SL: TPoint;
begin
  if (Shift=[ssLeft]) and (WindowPositionState=wpsMoving) then begin            //writeln('m:',Mouse.CursorPos.X, ':', Mouse.Cu
rsorPos.Y);
    FCaptionLabel.Cursor:=crSizeAll;
    SL:=Point(Mouse.CursorPos.X-WindowCaptionMouseX,Mouse.CursorPos.Y-WindowCaptionMouseY);
    TL:=Parent.ScreenToClient(SL);
    Left:=TL.X;
    Top:=TL.Y;                                                                  //writeln('w:',TL.X, ':', TL.Y);
  end;
end;
procedure TCustomMDIPanel.CaptionPanelMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  if (WindowPositionState = wpsMoving) then begin
    WindowPositionState:=wpsNone;
    FCaptionLabel.Cursor:=crDefault;
  end;
end;
procedure TCustomMDIPanel.SetCaption(const Value: TCaption);
    begin FCaptionLabel.Caption:=Value; end;

function TCustomMDIPanel.GetCaption: TCaption;
   begin Result:=FCaptionLabel.Caption; end;
procedure TCustomMDIPanel.DoMaximize;
begin
  if FWindowState = wsNormal then FNormalBounds:=Self.BoundsRect;
  Self.setBounds( 0,0,Parent.ClientWidth,Parent.ClientHeight );
  FWindowState:=wsMaximized;
  OrderButtons;
end;
procedure TCustomMDIPanel.DoMinimize;
var L,H,W: Integer;
begin L:=PanelManager.MList.IndexOf( Self );
      W:=Parent.ClientWidth div 5;
      H:=(2*W) div 3;
  if FWindowState=wsNormal then FNormalBounds:=Self.BoundsRect;
  Self.setBounds( W*(L mod 2),H*(L div 2),W,H );                         ///***
  FWindowState:=wsMinimized;
  OrderButtons;
end;
procedure TCustomMDIPanel.DoRestore;
begin  Self.BoundsRect:=FNormalBounds;
       FWindowState:=wsNormal;
       OrderButtons;
end;
procedure TCustomMDIPanel.Deactivate; begin setActive(False); end;
procedure TCustomMDIPanel.SystemButtonClick(Sender: TObject);
    begin FSystemPopupMenu.PopUp; end;
procedure TCustomMDIPanel.CloseButtonClick(Sender: TObject);
    begin DoClose( caFree ); end;                //Application.QueueAsyncCall(
procedure TCustomMDIPanel.OrderButtons;
begin
//  if assigned(FRestoreButton) then FRestoreButton.Visible:=(FWindowState<>wsNormal);
//  if assigned(FMaximizeButton) then FMaximizeButton.Visible:=(FWindowState<>wsMaximized);
//  if assigned(FMinimizeButton) then FMinimizeButton.Visible:=(FWindowState<>wsMinimized);

  FMenuItemMinimize.Enabled:=(FWindowState<>wsMinimized);
  FMenuItemMaximize.Enabled:=(FWindowState<>wsMaximized);
  FMenuItemRestore.Enabled :=(FWindowState<>wsNormal);

//  if assigned(FCloseButton) then FCloseButton.Left:=120;
//  if assigned(FMaximizeButton) then FMaximizeButton.Left:=100;
//  if assigned(FRestoreButton) then FRestoreButton.Left:=80;
//  if assigned(FMinimizeButton) then FMinimizeButton.Left:=60;
end;

procedure TCustomMDIPanel.MaximizeButtonClick(Sender: TObject);
begin SetActive(true); DoMaximize; end;

procedure TCustomMDIPanel.MinimizeButtonClick(Sender: TObject);
begin SetActive(true); DoMinimize; end;

procedure TCustomMDIPanel.RestoreButtonClick( Sender: TObject );
begin SetActive( true ); DoRestore; end;

function TCustomMDIPanel.GetControl( const Index: integer ): TControl;
begin Result:=FClientPanel.Controls[Index]; end;

//function TCustomMDIPanel.GetControlCount: integer;
//begin Result:=FClientPanel.ControlCount; end;

procedure TCustomMDIPanel.InsertControl(AControl: TControl);
*****

