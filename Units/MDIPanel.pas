unit MDIPanel;
{$mode objfpc}{$H+}
interface uses
  Classes,  SysUtils,
  LResources,Graphics,
  Menus,    ActnList,
  Controls, Forms,
  StdCtrls, ExtCtrls,
  Buttons;
type
  TWindowPositionState= ( wpsNone,wpsMoving,wpsResizing );
  TWindowResizingSide = ( wrszsNW,wrszsN,wrszsNE,
                          wrszsW, wrszsZ,wrszsE,
                          wrszsSW,wrszsS,wrszsSE );
{ TCaptionButton =     // Form title bar items
    ( cbSystemMenu,   // system menu
      cbMinimize,     // minimize button
      cbMaximize,     // maximize button
      cbRestore,      // restore button
      cbClose );
  TCaptionButtons = set of TCaptionButton;
}
type WinPanelManager = class;

TMDIClientPanel = class( TPanel )     // здесь цепляютcя горячие ключи ViewPort
public procedure ActiveDefaultControlChanged( NewControl: TControl ); override;
end;

TCustomMDIPanel = class( TCustomPanel )
  private
    FCaptionPanel: TPanel;
    FCaptionLabel: TLabel;
    FClientPanel: TMDIClientPanel;
    FSystemButton: TImage;
    FMaximizeButton,FMinimizeButton,FRestoreButton,FCloseButton: TSpeedButton;
    FMenuItemMinimize,FMenuItemMaximize,FMenuItemRestore,FMenuItemClose: TMenuItem;
    FSystemPopupMenu: TPopupMenu;
    PanelManager: WinPanelManager;
  private
    FOnCreate,FOnActivate,FOnShow,FOnDeactivate,FOnDestroy:TNotifyEvent;
    FOnShortcut: TShortCutEvent;
    FOnClose: TCloseEvent;
    FNormalBounds: Trect; // bounds when not maximized,minimized or hidden
    FWindowState: TWindowState;
    FCornerSize: integer;
    FActive: boolean;
    FWindowResizingSide: TWindowResizingSide;
    FClosing: boolean;
    FFormState:TFormState;
    FFormStyle:TFormStyle;
    FPosition: TPosition;
    FActionClose: TAction;
    FActionList: TActionList;
    procedure FActionCloseOnExecute( sender:TObject );
  private
    WindowPositionState: TWindowPositionState;
    WindowCaptionMouseX,WindowCaptionMouseY: integer;
    procedure CreateCaptionPanel; //( aCaptionButtons:TCaptionButtons );
    procedure CreateClientPanel;
    procedure CreateSystemPopupMenu;
    procedure DeleteSystemPopupMenu;

    procedure SystemButtonClick(Sender: TObject);
    procedure CloseButtonClick( Sender: TObject);  procedure DoClose(CloseAction:TCloseAction);
    procedure MaximizeButtonClick(Sender:TObject); procedure DoMaximize;
    procedure MinimizeButtonClick(Sender:TObject); procedure DoMinimize;
    procedure RestoreButtonClick( Sender:TObject); procedure DoRestore;
    procedure OrderButtons;
    procedure SetCaptionButtons; //( aVal: TCaptionButtons );
    procedure setDefaultSystemIcon;
    procedure CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure CaptionPanelMouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
    procedure CaptionPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure BorderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure BorderMouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
    procedure BorderMouseUp( Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure SetBorderCursor( X,Y: integer );
    procedure SetCaption( const Value: TCaption );
    function GetCaption: TCaption;
    function GetControl(const Index: integer): TControl;
    function getUniqueName( nameBase: AnsiString ): AnsiString;
    procedure ScreenOnActiveControlChanged(Sender: TObject; LastControl: TControl);
  protected
    procedure Deactivate; virtual;
    procedure SetActive(val: boolean);
    procedure SetName(const Value: TComponentName); override;
  private
    procedure ProcessResource;
    procedure SetMDIPanelManager(AValue: WinPanelManager);
    procedure InactivateSiblings;
  public
    constructor CreateNew( AOwner: TComponent ); virtual;
    constructor Create( AOwner: TComponent ); override;
    destructor Destroy; override;
    procedure Close;
    procedure InsertControl( AControl: TControl; Index: integer ); override;
    procedure RemoveControl( AControl: TControl ); override;
    property Controls[Index: integer]: TControl read GetControl;
    property FormStyle:TFormStyle read FFormStyle write FFormStyle default fsMDIChild;
    property MDIPanelManager: WinPanelManager read PanelManager write SetMDIPanelManager;
    property Position: TPosition read FPosition write FPosition default poDesigned;

    property Active: boolean read FActive write setActive;
    property Caption: TCaption read GetCaption write SetCaption;
    property CaptionPanel: TPanel read FCaptionPanel;
    property OnActivate: TNotifyEvent read FOnActivate write FOnActivate;
    property OnDeactivate: TNotifyEvent read FOnDeactivate write FOnDeactivate;
    property OnClose: TCloseEvent read FOnClose write FOnClose;
    property OnCreate: TNotifyEvent read FOnCreate write FOnCreate;
    property OnDestroy: TNotifyEvent read FOnDestroy write FOnDestroy;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;

 // unused plugs from TCustomForm just to satisfy IDE save/read properties
    private
        FActiveControl: TControl;
    public
      property ActiveControl: TControl read FActiveControl write FActiveControl;
      property OnResize stored True;
      property OnShortcut: TShortcutEvent read FOnShortcut write FOnShortcut;
      property WindowState: TWindowState read FWindowState write FWindowState default wsNormal;
  end;

 WinPanelManager = class                                  { TMDIPanelManager }
    MList: TFPList;
  private
    function GetMDIPanel(Index: Integer): TCustomMDIPanel;
    function GetPanelCount: integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Add(APanel: TCustomMDIPanel );
    procedure Insert( APanel: TCustomMDIPanel );
    procedure Insert( APanel: TCustomMDIPanel; Index: integer );
    procedure Remove( APanel: TCustomMDIPanel );
    procedure Delete( Index:integer );
    function  FindActivePanel: TCustomMDIPanel;
    procedure Show( Cascad: Boolean );  // Tile(false)+Cascade(true);
  public
    property MDIPanels[Index: Integer]: TCustomMDIPanel read GetMDIPanel;
    function IndexOf( APanel: TCustomMDIPanel ):integer;
    property PanelCount:integer read GetPanelCount;
  end;

implementation

constructor TCustomMDIPanel.CreateNew(AOwner: TComponent);
begin
  Include(FFormState,fsCreating);
  inherited Create(AOwner);                             // UpdateSysColorMap();
  Name:=getUniqueName( 'WINCapt' );
  Color:=clForm;
  FActive:=false;
  BevelOuter:=bvNone;
  BevelInner:=bvNone;
  BevelWidth:=1;
  BorderStyle:=bsNone;                                              //bsSingle;
  BorderWidth:=1;
  FCornerSize:=6;
  FWindowState:=wsNormal;
  WindowPositionState:=wpsNone;
  CreateCaptionPanel; // [cbSystemMenu,cbMinimize,cbMaximize,cbRestore,cbClose]
  CreateClientPanel;
  CreateSystemPopupMenu;
  OrderButtons;
  SetActive( false );
  Screen.AddHandlerActiveControlChanged( @ScreenOnActiveControlChanged,False );
  Exclude( FFormState,fsCreating );
  Invalidate;
end;

procedure TCustomMDIPanel.Close; begin DoClose( caFree ); end;
procedure TCustomMDIPanel.DoClose( CloseAction: TCloseAction );
  var K: Integer = -1;
begin
  if not assigned( self ) then exit;
  if FClosing then exit;
  FClosing:=true;
  FSystemPopupMenu.Close;
  if CloseAction = caHide then Visible:=False else
  if CloseAction = caMinimize then doMinimize else
  if CloseAction = caFree then begin
     if PanelManager<>nil then begin
       K:=PanelManager.MList.IndexOf( Self );
       if K>=0 then begin
           PanelManager.MList.Remove( Self );
//         PanelManager.MList.Delete( K );                     ///*** окна-окна
           if Application<>nil then Application.ReleaseComponent( Self ) else Free;
//         Destroy;
       end;
     end;
   end; FClosing:=false;
end;

constructor TCustomMDIPanel.Create( AOwner: TComponent );
begin
  GlobalNameSpace.BeginWrite;
  CreateNew( AOwner ); // this calls BeginFormUpdate,which is ended in AfterConstruction
  if (ClassType<>TCustomMDIPanel) and not (csDesigning in ComponentState) then begin
     Include( FFormState,fsCreating );
     ProcessResource; // load controls from the program resources to FClientControls
     Exclude( FFormState,fsCreating );
  end;
  GlobalNameSpace.EndWrite;
end;

destructor TCustomMDIPanel.Destroy;
begin
   Screen.RemoveHandlerActiveControlChanged( @ScreenOnActiveControlChanged );
   DeleteSystemPopupMenu;
   if assigned( onDestroy ) then onDestroy( Self );
   inherited Destroy;
end;

procedure TCustomMDIPanel.ProcessResource;
    begin InitResourceComponent( Self,TCustomMDIPanel ); end;

procedure TCustomMDIPanel.SetMDIPanelManager(AValue: WinPanelManager);
    begin
      if PanelManager=AValue then Exit;
      if PanelManager<>nil then                             // another manager
         PanelManager.Remove( Self );
         PanelManager:=AValue;
    end;

function TCustomMDIPanel.getUniqueName(nameBase: AnsiString): AnsiString;
  var i: integer;
begin i:=1; while assigned( Owner.FindComponent(nameBase+IntToStr(i)) ) do Inc(i);
            Result:=nameBase+IntToStr(i);
end;
procedure TCustomMDIPanel.SetName(const Value: TComponentName);
var Newname:AnsiString;  gCnt:integer;
begin
  if Owner.FindComponent(Value)=nil then inherited SetName( Value )
  else begin
    gCnt:=Owner.ComponentCount;
    Newname:=Value+'__'+IntToStr(gCnt+1);
    inherited SetName(NewName);
  end;
end;

procedure TCustomMDIPanel.FActionCloseOnExecute(sender:TObject );
    begin DoClose( caFree ); end;

procedure TCustomMDIPanel.CreateCaptionPanel; //( aCaptionButtons:TCaptionButtons );
begin
  OnMouseDown:=@BorderMouseDown;
  OnMouseMove:=@BorderMouseMove;
  OnMouseUp  :=@BorderMouseUp;
//SCH:=GetSystemMetrics( SM_CYCAPTION );    // header height
//SFW:=GetSystemMetrics( SM_CYDLGFRAME );   // frame width
  FCaptionPanel:=TPanel.Create( Self );
  FCaptionPanel.Parent:=Self;
  with FCaptionPanel do begin
    Name:='CaptionPanel';                        // Height:=26; AutoSize:=True;
    Align:=alTop;
    BevelOuter:=bvNone;
    BevelInner:=bvNone;
    BorderStyle:=bsNone; //bsSingle;
    BorderWidth:=0;
    Caption:='';
    Color:=clInactiveCaption;
    Font.Color:=clCaptionText;
    Font.Style:=[fsBold];
    Height:=20;                                         // SCH = Font.Height+8;
    ParentColor:=False;
    ParentFont:=False;
    TabStop:=False;
    OnMouseMove:=@CaptionPanelMouseMove;
    OnMouseUp:=@CaptionPanelMouseUp;
    OnMouseDown:=@CaptionPanelMouseDown;
  end;
  FCaptionLabel:=TLabel.Create(Self);
  FCaptionLabel.Parent:=FCaptionPanel;
  FCaptionLabel.ParentFont:=true;
  FCaptionLabel.Align:=alClient;
  FCaptionLabel.Alignment:=taCenter;
  FCaptionLabel.Layout:=tlCenter;
  FCaptionLabel.OnMouseMove:=@CaptionPanelMouseMove;
  FCaptionLabel.OnMouseUp:=@CaptionPanelMouseUp;
  FCaptionLabel.OnMouseDown:=@CaptionPanelMouseDown;
  FCaptionPanel.Constraints.MinHeight:=20;              // deriveCaptionHeight;
  SetCaptionButtons; //( aCaptionButtons );
end;
procedure TCustomMDIPanel.SetCaptionButtons;
begin
  if FSystemButton=nil then begin
    FSystemButton:=TImage.Create( Self );
    with FSystemButton do
         begin onClick:=@SystemButtonClick; setDefaultSystemIcon; end;
  end;
  if FCloseButton=nil then begin
    FCloseButton:=TSpeedButton.Create( Self );
    with FCloseButton do begin Parent:=FCaptionPanel; Align:=alRight;
      onClick:=@CloseButtonClick;
      Font.Color:=clRed; Caption:=' × '; //x ';
    end;
  end;
  if FMaximizeButton=nil then begin
    FMaximizeButton:=TSpeedButton.Create(Self);
    with FMaximizeButton do begin Parent:=FCaptionPanel; Align:=alRight;
      onClick:=@MaximizeButtonClick;
      Font.Color:=clSkyBlue; Caption:=' ▓ ' // ▒ ' // ░ '
    end;
  end;
  if FMinimizeButton=nil  then begin
    FMinimizeButton:=TSpeedButton.Create(Self);
    with FMinimizeButton do begin Parent:=FCaptionPanel; Align:=alRight;
      onClick:=@MinimizeButtonClick;
      Font.Color:=clblue; Caption:=' ⇐ '; //  ̅  '; //← '; //_ '; //… ';
    end;
  end;
  if FRestoreButton=nil then begin
    FRestoreButton:=TSpeedButton.Create(Self);
    with FRestoreButton do begin Parent:=FCaptionPanel; Align:=alRight;
      onClick:=@RestoreButtonClick;
      Font.Color:=clGreen; Caption:=' √ '; // ⌘ '; //≡ '; //o '; // ⌂ '; // ■ '; // 🌀 ';
      Visible:=False;
    end;
  end;
end;

procedure TCustomMDIPanel.setDefaultSystemIcon;
  var icn: TIcon; pf: TCustomForm;
begin
  pf:=getParentForm( Self );
  if assigned( pf ) and assigned( TCustomForm( pf ).Icon )
                    and ( TCustomForm( pf ).Icon.Width>0 )
      then icn:=TCustomForm( pf ).Icon
      else icn:=Application.Icon;
  FSystemButton.Parent:=nil;
  FSystemButton.Picture.Icon.Assign(icn);
  FSystemButton.Stretch:=true;
  FSystemButton.Constraints.MaxHeight:=20; //sz:=deriveCaptionIconHeight;
  FSystemButton.Constraints.MaxWidth:=20; //ch:=FCaptionPanel.ClientHeight;
  FSystemButton.BorderSpacing.Around:=1; //(ch-sz)div 2;
  FSystemButton.Parent:=FCaptionPanel;
end;

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

procedure TCustomMDIPanel.SetBorderCursor( X,Y: integer );
begin
  FWindowResizingSide:=wrszsZ;
  Cursor:=crDefault;
  if X <= FCornerSize then begin
    if Y<=FCornerSize then begin FWindowResizingSide:=wrszsNW; Cursor:=crSizeNW; end else
    if Y>=Height-FCornerSize then begin FWindowResizingSide:=wrszsSW; Cursor:=crSizeSW; end
                             else begin FWindowResizingSide:=wrszsW; Cursor:=crSizeWE; end;
  end else
  if X >= Width-FCornerSize then begin
    if Y<=FCornerSize then begin FWindowResizingSide:=wrszsNE; Cursor:=crSizeNE; end else
    if Y>=Height-FCornerSize then begin FWindowResizingSide:=wrszsSE; Cursor:=crSizeSE; end
                             else begin FWindowResizingSide:=wrszsE; Cursor:=crSizeWE; end;
  end else begin  // X in mid
    if Y<=FCornerSize then begin FWindowResizingSide:=wrszsN; Cursor:=crSizeNS; end else
    if Y>=Height-FCornerSize then begin FWindowResizingSide:=wrszsS; Cursor:=crSizeNS; end
                             else begin FWindowResizingSide:=wrszsZ; Cursor:=crSizeNS; end;
  end;
end;

procedure TCustomMDIPanel.BorderMouseDown
( Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y:integer );
var TL: TPoint;
begin
  if (Button = mbLeft) and (Shift = [ssLeft]) then begin
    WindowPositionState:=wpsResizing;
    TL:=Parent.ClientToScreen(BoundsRect.TopLeft);
    WindowCaptionMouseX:=Mouse.CursorPos.X-TL.X;
    WindowCaptionMouseY:=Mouse.CursorPos.Y-TL.Y;
    setActive(True);
  end;
end;

procedure TCustomMDIPanel.BorderMouseMove
( Sender: TObject; Shift: TShiftState; X,Y: integer );
var TL,SL: TPoint; L,T,W,H: integer;
begin
  if not (WindowPositionState=wpsResizing) then SetBorderCursor( X,Y );
  if (Shift=[ssLeft]) and (WindowPositionState=wpsResizing) then begin
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
    end;
    setBounds( L,T,W,H );
  end;
end;

procedure TCustomMDIPanel.BorderMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X,Y: integer);
begin
  if (WindowPositionState=wpsResizing) then WindowPositionState:=wpsNone;
end;

procedure TCustomMDIPanel.CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X,Y: integer);
var TL: TPoint;
begin
  if (Button = mbLeft) and (Shift = [ssLeft]) then begin
    WindowPositionState:=wpsMoving;
  //TL:=ClientToScreen(TPanel(TPanel(Sender).Parent).BoundsRect.TopLeft);
    TL:=Parent.ClientToScreen( BoundsRect.TopLeft );
    WindowCaptionMouseX:=Mouse.CursorPos.X-TL.X;
    WindowCaptionMouseY:=Mouse.CursorPos.Y-TL.Y;
    setActive(True);
  end;
end;
procedure TCustomMDIPanel.CaptionPanelMouseMove
  ( Sender: TObject; Shift: TShiftState; X,Y: integer);
var TL,SL: TPoint;
begin
  if (Shift=[ssLeft]) and (WindowPositionState=wpsMoving) then begin
    FCaptionLabel.Cursor:=crSizeAll;
    SL:=Point(Mouse.CursorPos.X-WindowCaptionMouseX,Mouse.CursorPos.Y-WindowCaptionMouseY);
    TL:=Parent.ScreenToClient(SL);
    Left:=TL.X;
    Top:=TL.Y;
  end;
end;
procedure TCustomMDIPanel.CaptionPanelMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X,Y: integer);
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
  if assigned(FRestoreButton) then FRestoreButton.Visible:=(FWindowState<>wsNormal);
  if assigned(FMaximizeButton) then FMaximizeButton.Visible:=(FWindowState<>wsMaximized);
  if assigned(FMinimizeButton) then FMinimizeButton.Visible:=(FWindowState<>wsMinimized);

  FMenuItemMinimize.Enabled:=(FWindowState<>wsMinimized);
  FMenuItemMaximize.Enabled:=(FWindowState<>wsMaximized);
  FMenuItemRestore.Enabled :=(FWindowState<>wsNormal);

  if assigned(FCloseButton) then FCloseButton.Left:=120;
  if assigned(FMaximizeButton) then FMaximizeButton.Left:=100;
  if assigned(FRestoreButton) then FRestoreButton.Left:=80;
  if assigned(FMinimizeButton) then FMinimizeButton.Left:=60;
end;

procedure TCustomMDIPanel.MaximizeButtonClick(Sender: TObject);
begin SetActive(true); DoMaximize; end;

procedure TCustomMDIPanel.MinimizeButtonClick(Sender: TObject);
begin SetActive(true); DoMinimize; end;

procedure TCustomMDIPanel.RestoreButtonClick( Sender: TObject );
begin SetActive( true ); DoRestore; end;

function TCustomMDIPanel.GetControl( const Index: integer ): TControl;
begin Result:=FClientPanel.Controls[Index]; end;

procedure TCustomMDIPanel.InsertControl(AControl: TControl; Index: integer);
begin
  if (AControl=FCaptionPanel) or (AControl=FClientPanel) //or (AControl=FPassiveBevel)
  then inherited InsertControl( AControl,Index )
  else begin
    // Add to FClientControls during loading from resources.
    // Immediate inserting into FClientPanel causes corruption of sizes and adjustments.
    // We du that later after load
    if fsCreating in FFormState then //FClientControls.Add(AControl)
                                else FClientPanel.InsertControl(AControl,index-2);
                          // -2 because FClientPanel and FCaptionPanel
  end;
end;

procedure TCustomMDIPanel.RemoveControl(AControl: TControl);
begin
  if (AControl=FCaptionPanel) or (AControl=FClientPanel) // or (AControl=FPassiveBevel)
      then inherited RemoveControl(AControl)
      else FClientPanel.RemoveControl(AControl);
end;

procedure TCustomMDIPanel.InactivateSiblings;
var i: integer; C: TControl;
begin
  if not assigned(Parent) then exit;
  for i:=0 to Parent.ControlCount-1 do begin
    C:=Parent.Controls[i];
    if (C is TCustomMDIPanel) and (C<>Self) then TCustomMDIPanel(C).setActive(False);
  end;
end;

procedure TCustomMDIPanel.ScreenOnActiveControlChanged(Sender: TObject; LastControl: TControl);
begin
  if LastControl=nil then exit;
  if LastControl.Owner=Self then begin
    SetActive(true);
    TCustomForm(Owner).FocusControl( LastControl as TWinControl );
  end else SetActive( false );
end;
procedure TCustomMDIPanel.SetActive(val: boolean);
begin
  if val and not self.Focused and not(csLoading in ComponentState) then begin
    TCustomForm(Owner).ActiveControl:=self;
    TCustomForm(Owner).FocusControl(self);
    if assigned(FOnActivate) then FOnActivate(Self);
  end;
  if FActive=val then exit; FActive:=val;
  if val then begin
    FCaptionPanel.Color:=clActiveCaption;
    setZOrder(True);
    InactivateSiblings;
  end else begin
    FCaptionPanel.Color:=clInactiveCaption;
    if assigned(FOnDeactivate) then FOnDeactivate(Self);
  end;
  invalidate;
end;

procedure TMDIClientPanel.ActiveDefaultControlChanged( NewControl: TControl );
begin
  if assigned(NewControl) and assigned(Parent) and (Parent is TCustomMDIPanel)
  then TCustomMDIPanel( Parent ).setActive( true );
end;

//procedure Register; begin RegisterComponents('MDIPanel',[TMDIPanel]); end;
//{$I MDIPanelManager.inc}
{%MainUnit MDIPanel.pas}

function WinPanelManager.GetMDIPanel(Index: Integer): TCustomMDIPanel;
   begin Result:=TCustomMDIPanel(MList[Index]); end;
function WinPanelManager.GetPanelCount: integer;
   begin result:=MList.Count; end;
constructor WinPanelManager.Create;
      begin inherited Create; MList:=TFPList.Create; end;
destructor WinPanelManager.Destroy;
     begin FreeAndNil( MList ); end; // inherited; end;
function WinPanelManager.IndexOf( APanel: TCustomMDIPanel ): integer;
   begin result:=MList.IndexOf( APanel ); end;
procedure WinPanelManager.Add( APanel: TCustomMDIPanel );
begin if APanel=nil then exit;
      MList.Add( APanel );
      APanel.MDIPanelManager:=self;
end;
procedure WinPanelManager.Insert( APanel: TCustomMDIPanel );
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

function WinPanelManager.FindActivePanel: TCustomMDIPanel; var i:integer;
begin result:=nil;
  for i:=0 to MList.Count-1 do
   if TCustomMDIPanel(MList[i]).Active then result:=TCustomMDIPanel(MList[i]);
end;

procedure WinPanelManager.Show( Cascad: Boolean  ); // const WN: array[0..3] of Integer=(3,1,0,2);
var MW,MH,W,H,M,MCC,I,J,B : Integer;
    WM: array[0..3] of Record x,y,w,h: Integer; end;
    panel  : TCustomMDIPanel;
    parent : TWinControl;
//  swc    : TScrollingWinControl;
begin
  if MList.Count=0 then exit;
  parent:=MDIPanels[0].Parent; // we get just parent of first MDIPanel. Assumed that all have same parent.
  if parent=nil then exit;

  MCC:=MList.Count; if MCC=0 then exit else M:=MCC;

  MW:=parent.ClientWidth;
  MH:=parent.ClientHeight;
  if Cascad and (M>1) then M:=0 else begin       // слева-направо и сверху-вниз
    if M>4 then M:=4; H:=MH div 2;
                      W:=MW div 3;
    if M=1 then begin WM[0].x:=0; WM[0].y:=0; WM[0].h:=MH; WM[0].w:=MW; end else
    if M=2 then begin WM[0].x:=0; WM[0].y:=H; WM[0].h:=H;  WM[0].w:=MW;
                      WM[1].x:=0; WM[1].y:=0; WM[1].h:=H;  WM[1].w:=MW; end else
    if M=3 then begin WM[0].x:=0; WM[0].y:=0; WM[0].h:=MH; WM[0].w:=W;
                      WM[1].x:=W; WM[1].y:=H; WM[1].h:=H; WM[1].w:=W*2;
                      WM[2].x:=W; WM[2].y:=0; WM[2].h:=H; WM[2].w:=W*2; end else
    begin WM[0].x:=W*2; WM[0].y:=0; WM[0].h:=H;   WM[0].w:=W;   // fvBodyplan - корпус
          WM[1].x:=0;   WM[1].y:=0; WM[1].h:=H;   WM[1].w:=W*2; // fvProfile  - бок
          WM[2].x:=0;   WM[2].y:=H; WM[2].h:=H;   WM[2].w:=W*2; // fvPlan     - полуширота
          WM[3].x:=W*2; WM[3].y:=H; WM[3].h:=H+2; WM[3].w:=W+2; // fvPerspective - аксонометрия
    end;
    for I:=0 to M-1 do begin  panel:=MDIPanels[I];
      if Assigned( panel ) then panel.SetBounds( WM[I].x,WM[I].y,WM[I].w,WM[I].h );
    end;
  end;
  if MCC>M then begin J:=MCC-M-1;
    if J=0 then begin W:=0; H:=0; J:=1; end else begin
      W:=MW div 12; MW -= W;
      H:=MH div 12; MH -= H; end;
    if Cascad then B:=0 else
       begin MW:=MW div 2; MH:=MH div 2; B:=(W+H) div 2; end;   // Tile пополам
    for I:=M to MCC-1 do begin panel:=MDIPanels[i];
      if Assigned( panel ) then panel.SetBounds( B+((I-M)*W) div J,
                                                 B+((I-M)*H) div J,MW,MH );
    end;
  end;
end;

end.
