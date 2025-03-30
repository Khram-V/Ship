unit MDIPanel;
{$mode objfpc}{$H+}
//{$define Use_MouseClickProxy}
interface
uses
  Classes, SysUtils, LCLType, LCLIntf,
  LMessages, LResources, GraphType, Graphics, Menus,
  ActnList, Controls, Forms, StdCtrls, ExtCtrls,  Buttons;
type
  TWindowPositionState= ( wpsNone, wpsMoving, wpsResizing );
  TWindowResizingSide = ( wrszsNW, wrszsN, wrszsNE,
                          wrszsW,  wrszsZ, wrszsE,
                          wrszsSW, wrszsS, wrszsSE );
  TCaptionButton =     // Form title bar items
  ( cbSystemMenu,      // system menu
    cbMinimize,        // minimize button
    cbMaximize,        // maximize button
    cbRestore,         // restore button
    cbClose );
  TCaptionButtons = set of TCaptionButton;

type TMDIClientPanel = class(TPanel)
public procedure ActiveDefaultControlChanged( NewControl: TControl ); override;
end;
{$ifdef Use_MouseClickProxy}
TMouseClickProxy = class
  private
    FDestroyed: boolean;
    FOwner: TControl;
    FOwnerOnClick: TNotifyEvent;
    FProxyOnClick: TNotifyEvent;
  public
    constructor Create(TheOwner: TControl);
    destructor Destroy; override;
    procedure OnClick(Sender: TObject);
    property OwnerOnClick: TNotifyEvent read FOwnerOnClick;
    property ProxyOnClick: TNotifyEvent read FProxyOnClick write FProxyOnClick;
    class function IsOnClick(P: TNotifyEvent): boolean;
  end;
{$endif}
type WinPanelManager = class;
type                                                        { TCustomMDIPanel }
  TCustomMDIPanel = class(TCustomPanel)
  private
    FClientControls:TFPList;
    FCaptionPanel: TPanel;
    FCaptionLabel: TLabel;
    FClientPanel: TMDIClientPanel;
    FSystemButton: TImage;
    FMaximizeButton,FMinimizeButton,FRestoreButton,FCloseButton: TSpeedButton;
    FMenuItemMinimize,FMenuItemMaximize,FMenuItemRestore,FMenuItemClose: TMenuItem;
    FSystemPopupMenu: TPopupMenu;
    PanelManager: WinPanelManager;
  private
    FOnCreate,FOnActivate,FOnShow,FOnHide,FOnDeactivate,FOnDestroy:TNotifyEvent;
    FOnShortcut: TShortCutEvent;
    FOnClose: TCloseEvent;
    FOnHelp: THelpEvent;

    FNormalBounds: Trect; // bounds when not maximized, minimized or hidden
    FWindowState: TWindowState;
    FCornerSize: integer;
    FActiveBorderColor: TColor;
    FInactiveBorderColor: TColor;
    FActive: boolean;
    FParentForm: TCustomForm;
    FPassiveBevel: TGraphicControl;
    FCaptionButtons: TCaptionButtons;
    FWindowResizingSide: TWindowResizingSide;

    FClosing: boolean;
    FFormState:TFormState;
    FFormStyle:TFormStyle;
    FPosition: TPosition;

    FActionClose: TAction;
    FActionList: TActionList;
    procedure FActionCloseOnExecute(sender:TObject);

  private
    WindowPositionState: TWindowPositionState;
    WindowCaptionMouseX, WindowCaptionMouseY: integer;

    function getUniqueName( nameBase: AnsiString ): AnsiString;
    procedure CreateCaptionPanel( aCaptionButtons:TCaptionButtons );
    procedure CreateClientPanel;
    procedure PopulateClientPanel;
    procedure CreateSystemPopupMenu;
    procedure DeleteSystemPopupMenu;

    procedure SystemButtonClick(Sender: TObject);
    procedure CloseButtonClick( Sender: TObject);  procedure DoClose(CloseAction:TCloseAction);
    procedure MaximizeButtonClick(Sender:TObject); procedure DoMaximize;
    procedure MinimizeButtonClick(Sender:TObject); procedure DoMinimize;
    procedure RestoreButtonClick( Sender:TObject); procedure DoRestore;
    procedure OrderButtons;
    procedure SetCaptionButtons( aVal: TCaptionButtons );
    procedure setDefaultSystemIcon;
    procedure CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure CaptionPanelMouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
    procedure CaptionPanelMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure BorderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure BorderMouseMove(Sender: TObject; Shift: TShiftState; X,Y: integer);
    procedure BorderMouseUp( Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: integer);
    procedure SetBorderCursor( X,Y: integer );

    function deriveCaptionHeight:integer;
    function deriveCaptionIconHeight:integer;

    procedure SetCaption(const Value: TCaption);
    function GetCaption: TCaption;
    function GetControl(const Index: integer): TControl;
//  function GetControlCount: integer;

{$ifdef Use_MouseClickProxy}
    procedure setMouseClickProxiesRecursively(Ctrl: TControl);
    procedure unsetMouseClickProxiesRecursively(Ctrl: TControl);
    procedure setMouseClickProxies;
    procedure unsetMouseClickProxies;
{$endif Use_MouseClickProxy}
    procedure PassivePanelOnClick(Sender: TObject);
    procedure ScreenOnActiveControlChanged(Sender: TObject; LastControl: TControl);
    procedure ClientPanelOnMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
  protected
    procedure Deactivate; virtual;
    procedure SetActive(val: boolean);
    procedure SetParent(NewParent: TWinControl); override;
    procedure SetName(const Value: TComponentName); override;
    procedure WndProc(var TheMessage: TLMessage); override;
  private
    procedure ProcessResource;
    procedure SetMDIPanelManager(AValue: WinPanelManager);
    procedure InactivateSiblings;
  public
    constructor CreateNew( AOwner: TComponent ); virtual;
    constructor Create( AOwner: TComponent ); override;
    destructor Destroy; override;
    procedure Close;

    procedure InsertControl( AControl: TControl );
    procedure InsertControl( AControl: TControl; Index: integer ); override;
    procedure RemoveControl( AControl: TControl ); override;
    property Controls[Index: integer]: TControl read GetControl;
    property CaptionButtons:TCaptionButtons read FCaptionButtons write SetCaptionButtons;
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
        FAllowDropFiles: Boolean;
        FAlphaBlend: Boolean;
        FAlphaBlendValue: Byte;
     // FBorderIcons: TBorderIcons;
        FDesignTimePPI: Integer;
        FDefaultMonitor: TDefaultMonitor;
        FHelpFile: AnsiString;
        FKeyPreview: Boolean;
     // FMDIChildren: array of TCustomMDIPanel;
        FMenu : TMainMenu;
        FOnCloseQuery : TCloseQueryEvent;
        FOnDropFiles: TDropFilesEvent;
     // FOnShowModalFinished: TModalDialogFinished;
        FOnWindowStateChange: TNotifyEvent;
        FPixelsPerInch: Integer;
        FScaled: Boolean;
        FPopupMode: TPopupMode;
        FPopupParent: TCustomForm;
        FShowInTaskBar: TShowInTaskbar;
    public
      property ActiveControl: TControl read FActiveControl write FActiveControl;
      property AllowDropFiles: Boolean read FAllowDropFiles write FAllowDropFiles default False;
      property AlphaBlend: Boolean read FAlphaBlend write FAlphaBlend;
      property AlphaBlendValue: Byte read FAlphaBlendValue write FAlphaBlendValue;
//    property BorderIcons: TBorderIcons read FBorderIcons write FBorderIcons default [biSystemMenu, biMinimize, biMaximize];
      property DefaultMonitor: TDefaultMonitor read FDefaultMonitor write FDefaultMonitor default dmActiveForm;
      property DesignTimePPI: Integer read FDesignTimePPI write FDesignTimePPI default 96;
      property HelpFile: AnsiString read FHelpFile write FHelpFile;
      property KeyPreview: Boolean read FKeyPreview write FKeyPreview default False;
      property Menu : TMainMenu read FMenu write FMenu;
      property OnCloseQuery : TCloseQueryEvent read FOnCloseQuery write FOnCloseQuery stored True;
      property OnDropFiles: TDropFilesEvent read FOnDropFiles write FOnDropFiles;
      property OnHelp: THelpEvent read FOnHelp write FOnHelp;
      property OnHide: TNotifyEvent read FOnHide write FOnHide;
      property OnResize stored True;
      property OnShortcut: TShortcutEvent read FOnShortcut write FOnShortcut;
   // property OnShowModalFinished: TModalDialogFinished read FOnShowModalFinished write FOnShowModalFinished;
      property OnWindowStateChange: TNotifyEvent read FOnWindowStateChange write FOnWindowStateChange;
      property PixelsPerInch: Integer read FPixelsPerInch write FPixelsPerInch stored False;
      property Scaled: Boolean read FScaled write FScaled default True;
      property PopupMode: TPopupMode read FPopupMode write FPopupMode default pmNone;
      property PopupParent: TCustomForm read FPopupParent write FPopupParent;
      property ShowInTaskBar: TShowInTaskbar read FShowInTaskbar write FShowInTaskBar default stDefault;
      property WindowState: TWindowState read FWindowState write FWindowState default wsNormal;
  end;

  TMDIPanel = class( TCustomMDIPanel )
  private
    FLCLVersion: AnsiString;
    function LCLVersionIsStored: boolean;
  published
    property Active;
    property Caption;
    property CaptionPanel;
    property OnActivate;
    property OnDeactivate;
    property OnClose;
    property OnCreate;
    property OnDestroy;
    property OnShow;
    property Action;                                          // from TForm
    property ActiveControl;
    property Align;
    property AllowDropFiles;
    property AlphaBlend default False;
    property AlphaBlendValue default 255;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property BorderStyle;
    property BorderWidth;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property Constraints;
    property DefaultMonitor;
    property DesignTimePPI;
    property DockSite;
    property DoubleBuffered;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property FormStyle;
    property HelpFile;
    property KeyPreview;
    property Menu;
    property OnChangeBounds;
    property OnClick;
    property OnCloseQuery;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDblClick;
    property OnDockDrop;
    property OnDockOver;
    property OnDragDrop;
    property OnDragOver;
    property OnDropFiles;
    property OnEndDock;
    property OnGetSiteInfo;
    property OnHelp;
    property OnHide;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnMouseWheelHorz;
    property OnMouseWheelLeft;
    property OnMouseWheelRight;
    property OnPaint;
    property OnResize;
    property OnShortCut;
    property OnShowHint;
    property OnStartDock;
    property OnUnDock;
    property OnUTF8KeyPress;
    property OnWindowStateChange;
    property ParentBiDiMode;
    property ParentDoubleBuffered;
    property ParentFont;
    property PixelsPerInch;
    property PopupMenu;
    property PopupMode;
    property PopupParent;
    property Position;
    property SessionProperties;
    property ShowHint;
    property ShowInTaskBar;
    property UseDockManager;
    property LCLVersion: AnsiString read FLCLVersion write FLCLVersion stored LCLVersionIsStored;
    property Scaled;
    property Visible;
    property WindowState;
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
{%MainUnit MDIPanel.pas ##################################################### }

function TMDIPanel.LCLVersionIsStored: boolean; begin Result:=Parent=nil; end;

constructor TCustomMDIPanel.CreateNew(AOwner: TComponent);
begin
  Include(FFormState,fsCreating);
  inherited Create(AOwner);                   // UpdateSysColorMap();
                                              // FClickProxies:=TFPList.Create;
  Name:=getUniqueName( 'WINCapt' );
  Color:=clForm;
  FActive:=false;
  BevelOuter:=bvNone;
  BevelInner:=bvNone;
  BevelWidth:=1;
  BorderStyle:=bsNone;                                              //bsSingle;
  BorderWidth:=1;
  FActiveBorderColor:=clDefault;
  FInactiveBorderColor:=clDefault;
  FClientControls:=TFPList.Create;
  FCornerSize:=6;
  FWindowState:=wsNormal;
  WindowPositionState:=wpsNone;
//FCaptionButtons := [cbSystemMenu,cbMinimize,cbMaximize,cbRestore,cbClose];
  CreateCaptionPanel([cbSystemMenu,cbMinimize,cbMaximize,cbRestore,cbClose]);
  CreateClientPanel;
  CreateSystemPopupMenu;
  OrderButtons;
  SetActive( false );
//SetMouseClickProxies;                                                 ///+++
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
  CreateNew( AOwner ); // this calls BeginFormUpdate, which is ended in AfterConstruction
  if (ClassType<>TMDIPanel) and not (csDesigning in ComponentState) then begin
     Include( FFormState,fsCreating );
     ProcessResource; // load controls from the program resources to FClientControls
     Exclude( FFormState,fsCreating );
     PopulateClientPanel;          // Now place loaded controls to FClientPanel
  end;
  GlobalNameSpace.EndWrite;
end;

destructor TCustomMDIPanel.Destroy;
begin
// unsetMouseClickProxies;                                               ///+++
   Screen.RemoveHandlerActiveControlChanged( @ScreenOnActiveControlChanged );
// FreeAndNil( FClickProxies );
   DeleteSystemPopupMenu;
   FreeAndNil( FClientControls );
   if assigned( onDestroy ) then onDestroy( Self );
   inherited Destroy;
end;

procedure TCustomMDIPanel.PopulateClientPanel;
var i:integer; control:TControl;
begin
  for i:=0 to FClientControls.Count-1 do begin
      control:=TControl( FClientControls[i] );
      FClientPanel.InsertControl( control );
  end;
  FClientPanel.OnMouseDown:=@ClientPanelOnMouseDown;
  FClientPanel.OnChangeBounds:=OnChangeBounds;
  FClientPanel.OnClick:=OnClick;
  // FClientPanel.OnCloseQuery:=OnCloseQuery;
  FClientPanel.OnConstrainedResize:=OnConstrainedResize;
  FClientPanel.OnContextPopup:=OnContextPopup;
  FClientPanel.OnDblClick:=OnDblClick;
  FClientPanel.OnDockDrop:=OnDockDrop;
  FClientPanel.OnDockOver:=OnDockOver;
  FClientPanel.OnDragDrop:=OnDragDrop;
  FClientPanel.OnDragOver:=OnDragOver;
  // FClientPanel.OnDropFiles:=OnDropFiles;
  FClientPanel.OnEndDock:=OnEndDock;
  FClientPanel.OnGetSiteInfo:=OnGetSiteInfo;
  // FClientPanel.OnHelp:=OnHelp;
  // FClientPanel.OnHide:=OnHide;
  FClientPanel.OnKeyDown:=OnKeyDown;
  FClientPanel.OnKeyPress:=OnKeyPress;
  FClientPanel.OnKeyUp:=OnKeyUp;
  FClientPanel.OnMouseEnter:=OnMouseEnter;
  FClientPanel.OnMouseLeave:=OnMouseLeave;
  FClientPanel.OnMouseMove:=OnMouseMove;
  FClientPanel.OnMouseUp:=OnMouseUp;
  FClientPanel.OnMouseWheel:=OnMouseWheel;
  FClientPanel.OnMouseWheelDown:=OnMouseWheelDown;
  FClientPanel.OnMouseWheelUp:=OnMouseWheelUp;
  FClientPanel.OnMouseWheelHorz:=OnMouseWheelHorz;
  FClientPanel.OnMouseWheelLeft:=OnMouseWheelLeft;
  FClientPanel.OnMouseWheelRight:=OnMouseWheelRight;
  FClientPanel.OnPaint:=OnPaint;
  FClientPanel.OnResize:=OnResize;
  // FClientPanel.OnShortCut:=OnShortCut;
  FClientPanel.OnShowHint:=OnShowHint;
  FClientPanel.OnStartDock:=OnStartDock;
  FClientPanel.OnUnDock:=OnUnDock;
  FClientPanel.OnUTF8KeyPress:=OnUTF8KeyPress;
  // FClientPanel.OnWindowStateChange:=OnWindowStateChange;

end;

procedure TCustomMDIPanel.ProcessResource;
    begin InitResourceComponent( Self,TMDIPanel ); end;

procedure TCustomMDIPanel.SetMDIPanelManager(AValue: WinPanelManager);
begin
  if PanelManager=AValue then Exit;
  if PanelManager<>nil then // another manager
     PanelManager.Remove(Self);
  PanelManager:=AValue;
end;
procedure TCustomMDIPanel.FActionCloseOnExecute(sender:TObject );
    begin DoClose( caFree ); end;

function TCustomMDIPanel.getUniqueName(nameBase: AnsiString): AnsiString;
  var i: integer;
begin i:=1;
  while assigned( Owner.FindComponent(nameBase+IntToStr(i)) ) do Inc(i);
  Result:=nameBase+IntToStr(i);
end;
function TCustomMDIPanel.deriveCaptionHeight:integer;
var H:integer; fd:TFontData;
begin
  H:=GetSystemMetrics( SM_CYCAPTION );                      //header height
  if H>0 then begin result:=H; exit; end;                   //detect default font height to derive caption height
  fd:=GetFontData( FCaptionPanel.Font.Handle );             // TFontData.Height is in logical units, convert it to pixels
  H:=abs(round(1.0*fd.Height*Font.PixelsPerInch/72.0)); // add 4 so font does not touch borders
  result:=h+4;
end;

function TCustomMDIPanel.deriveCaptionIconHeight:integer;
var h:integer;
begin h:=deriveCaptionHeight;
  if (h < 24) then result:=16 else
  if (h < 34) then result:=22 else result:=32; result+=4;
end;

procedure TCustomMDIPanel.CreateCaptionPanel( aCaptionButtons:TCaptionButtons );
var SCH: integer;
begin
  OnMouseDown:=@BorderMouseDown;
  OnMouseMove:=@BorderMouseMove;
  OnMouseUp  :=@BorderMouseUp;
  SCH:=GetSystemMetrics( SM_CYCAPTION );    // header height
//SFW:=GetSystemMetrics( SM_CYDLGFRAME );   // frame width
  FCaptionPanel:=TPanel.Create( Self );
  FCaptionPanel.Parent:=Self;
  with FCaptionPanel do begin
    Name:='CaptionPanel';
//  Height:=26;
//  AutoSize:=True;
    Align:=alTop;
    BevelOuter:=bvNone;
    BevelInner:=bvNone;
    BorderStyle:=bsNone; //bsSingle;
    BorderWidth:=0;
    Caption:='';
    Color:=clInactiveCaption;
    Font.Color:=clCaptionText;
    Font.Style:=[fsBold];
    Height:=SCH; // Font.Height+8;
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
  FCaptionLabel.Caption:='WINCapt';
  FCaptionLabel.OnMouseMove:=@CaptionPanelMouseMove;
  FCaptionLabel.OnMouseUp:=@CaptionPanelMouseUp;
  FCaptionLabel.OnMouseDown:=@CaptionPanelMouseDown;
  FCaptionPanel.Constraints.MinHeight:=deriveCaptionHeight;
  SetCaptionButtons( aCaptionButtons );
{ FSystemButton:=TImage.Create( Self );
  with FSystemButton
    do begin onClick:=@SystemButtonClick; setDefaultSystemIcon; end; }
end;
procedure TCustomMDIPanel.SetCaptionButtons( aVal:TCaptionButtons );
// var IconSize: integer; IconSizeString: AnsiString;
begin // exit;
  if aVal=FCaptionButtons then exit; FCaptionButtons:=aVal;
{ IconSize:=deriveCaptionIconHeight-4;
  IconSizeString:=IntToStr(IconSize)+'x'+IntToStr(IconSize);
  IconSizeString:='X';
  if not (cbSystemMenu in FCaptionButtons) and assigned(FSystemButton) then FreeAndNil(FSystemButton);
  if not (cbClose in FCaptionButtons) and assigned(FCloseButton) then FreeAndNil(FCloseButton);
  if not (cbMinimize in FCaptionButtons) and assigned(FMinimizeButton) then FreeAndNil(FMinimizeButton);
  if not (cbMaximize in FCaptionButtons) and assigned(FMaximizeButton) then FreeAndNil(FMaximizeButton);
  if not (cbRestore in FCaptionButtons) and assigned(FRestoreButton) then FreeAndNil(FRestoreButton);
} // h:=deriveCaptionIconHeight;
  if (cbSystemMenu in FCaptionButtons) and (FSystemButton = nil) then begin
    FSystemButton:=TImage.Create( Self );
    with FSystemButton do
         begin onClick:=@SystemButtonClick; setDefaultSystemIcon; end;
  end;
  if (cbClose in FCaptionButtons) and (FCloseButton = nil) then begin
    FCloseButton:=TSpeedButton.Create( Self );
    with FCloseButton do begin Parent:=FCaptionPanel; Align:=alRight;
      onClick:=@CloseButtonClick;
      Font.Color:=clRed; Caption:=' × '; //x ';
    end;
  end;
  if (cbMaximize in FCaptionButtons) and (FMaximizeButton = nil) then begin
    FMaximizeButton:=TSpeedButton.Create(Self);
    with FMaximizeButton do begin Parent:=FCaptionPanel; Align:=alRight;
      onClick:=@MaximizeButtonClick;
      Font.Color:=clSkyBlue; Caption:=' ▓ ' // ▒ ' // ░ '
    end;
  end;
  if (cbMinimize in FCaptionButtons) and (FMinimizeButton = nil)  then begin
    FMinimizeButton:=TSpeedButton.Create(Self);
    with FMinimizeButton do begin Parent:=FCaptionPanel; Align:=alRight;
      onClick:=@MinimizeButtonClick;
      Font.Color:=clblue; Caption:=' ⇐ '; //  ̅  '; //← '; //_ '; //… ';
    end;
  end;
  if (cbRestore in FCaptionButtons) and (FRestoreButton = nil) then begin
    FRestoreButton:=TSpeedButton.Create(Self);
    with FRestoreButton do begin Parent:=FCaptionPanel; Align:=alRight;
      onClick:=@RestoreButtonClick;
      Font.Color:=clGreen; Caption:=' √ '; // ⌘ '; //≡ '; //o '; // ⌂ '; // ■ '; // 🌀 ';
      Visible:=False;             {    Left:=60;
                                       AutoSize:=True;
                                       AllowAllUp:=True;
                                       Font.Style:=[fsBold];
                                       ParentFont:=False;    }
    end;
  end;
end;
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
procedure TCustomMDIPanel.WndProc( var TheMessage: TLMessage );// does not help
var Form: TCustomForm;
begin                                                      // keyboard messages
  if (TheMessage.Msg>=LM_KEYFIRST) and (TheMessage.Msg<=LM_KEYLAST) then begin
      Form:=GetParentForm( Self );
      if (Form<>nil) and (Form.WantChildKey(Self,TheMessage)) then exit;
   end;
   Dispatch( TheMessage );
end;
procedure TCustomMDIPanel.setDefaultSystemIcon;
var icn:TIcon; sz,ch:integer; pf:TCustomForm;
{ function getParentForm( c:TControl ): TCustomForm;
  begin result:=nil;
    if assigned(c.Parent) then
    if (c.Parent is TCustomForm) then result:=TCustomForm(c.Parent)
                                 else getParentForm(c.Parent); end; }
begin
  pf:=getParentForm( Self );
  if assigned( pf )
  and assigned( TCustomForm( pf ).Icon )
  and ( TCustomForm( pf ).Icon.Width>0 )
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
procedure TCustomMDIPanel.SetParent( NewParent: TWinControl );
var H:integer; //bv:TPanelBevel; bw:integer;  bs:TBorderStyle;
begin
  if Parent = NewParent then exit;
  inherited SetParent( NewParent );
  FParentForm:=GetParentForm( Self );
  if assigned( FSystemButton ) then setDefaultSystemIcon;
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
  end;
end;

procedure TCustomMDIPanel.BorderMouseDown
( Sender:TObject; Button:TMouseButton; Shift:TShiftState; X,Y:integer );
var TL: TPoint;
begin
  if (Button = mbLeft) and (Shift = [ssLeft]) then begin
    WindowPositionState:=wpsResizing;
    TL:=Parent.ClientToScreen(BoundsRect.TopLeft);                              //writeln('d:',Mouse.CursorPos.X, ':', Mouse.CursorPos.Y);
    WindowCaptionMouseX:=Mouse.CursorPos.X-TL.X;
    WindowCaptionMouseY:=Mouse.CursorPos.Y-TL.Y;
    setActive(True);
  end;
end;

procedure TCustomMDIPanel.BorderMouseMove
( Sender: TObject; Shift: TShiftState; X,Y: integer );
var TL,SL: TPoint; L,T,W,H: integer;
begin
  if not (WindowPositionState = wpsResizing) then SetBorderCursor( X,Y );
  if (Shift=[ssLeft]) and (WindowPositionState=wpsResizing) then begin          // writeln('m:',Mouse.CursorPos.X,':',Mouse.CursorPos.Y,' sender:',TControl(Sender).Name);
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
    end;                                                                        // writeln('setBounds(', L, ',', T, ',', W, ',', H, ')');
    setBounds( L,T,W,H );
  end;
end;

procedure TCustomMDIPanel.BorderMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
  if (WindowPositionState = wpsResizing) then WindowPositionState:=wpsNone;
end;

procedure TCustomMDIPanel.CaptionPanelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var TL: TPoint;
begin
  if (Button = mbLeft) and (Shift = [ssLeft]) then begin
    WindowPositionState:=wpsMoving;
  //TL:=ClientToScreen(TPanel(TPanel(Sender).Parent).BoundsRect.TopLeft);
    TL:=Parent.ClientToScreen( BoundsRect.TopLeft );                            //writeln('d:',Mouse.CursorPos.X, ':', Mouse.CursorPos.Y);
    WindowCaptionMouseX:=Mouse.CursorPos.X-TL.X;
    WindowCaptionMouseY:=Mouse.CursorPos.Y-TL.Y;
    setActive(True);
  end;
end;
procedure TCustomMDIPanel.CaptionPanelMouseMove
  ( Sender: TObject; Shift: TShiftState; X,Y: integer);
var TL,SL: TPoint;
begin
  if (Shift=[ssLeft]) and (WindowPositionState=wpsMoving) then begin            //writeln('m:',Mouse.CursorPos.X, ':', Mouse.CursorPos.Y);
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

//function TCustomMDIPanel.GetControlCount: integer;
//begin Result:=FClientPanel.ControlCount; end;

procedure TCustomMDIPanel.InsertControl(AControl: TControl);
begin
  if (AControl=FCaptionPanel) or (AControl=FClientPanel) //or (AControl = FPassiveBevel)
  then inherited InsertControl( AControl )
  else FClientPanel.InsertControl( AControl );
end;

procedure TCustomMDIPanel.InsertControl(AControl: TControl; Index: integer);
begin
  if (AControl = FCaptionPanel) or (AControl = FClientPanel) //or (AControl = FPassiveBevel)
  then inherited InsertControl(AControl, Index)
  else begin
    // Add to FClientControls during loading from resources.
    // Immediate inserting into FClientPanel causes corruption of sizes and adjustments.
    // We du that later after load
    if fsCreating in FFormState then FClientControls.Add(AControl)
                                else FClientPanel.InsertControl(AControl,index-2);
                          // -2 because FClientPanel and FCaptionPanel
    {
      if not FActive then setMouseClickProxiesRecursively(AControl);    ///+++
    }
  end;
end;

procedure TCustomMDIPanel.RemoveControl(AControl: TControl);
begin
  if (AControl=FCaptionPanel) or (AControl=FClientPanel) or
     (AControl=FPassiveBevel) then inherited RemoveControl(AControl)
  else begin
    FClientPanel.RemoveControl(AControl);
//  if not Active then unsetMouseClickProxiesRecursively(AControl);    ///+++
  end;
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

procedure TCustomMDIPanel.ClientPanelOnMouseDown(Sender: TObject;
  Button:TMouseButton; Shift:TShiftState; X,Y:Integer);
begin
  SetActive(true);
  if self.OnMouseDown<>nil then self.OnMouseDown(Sender,Button,Shift,X,Y);
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
//  unsetMouseClickProxies;                                             ///+++
  end else begin
    FCaptionPanel.Color:=clInactiveCaption;
//  setMouseClickProxies;                                               ///+++
    if assigned(FOnDeactivate) then FOnDeactivate(Self);
  end;
  invalidate;
end;

procedure TCustomMDIPanel.PassivePanelOnClick( Sender: TObject );
    begin setActive(True); end;

{$ifdef Use_MouseClickProxy}

procedure TCustomMDIPanel.unsetMouseClickProxiesRecursively(Ctrl: TControl);
var
  i: integer;
  C: TControl;

  procedure unsetProxyFor(C: TControl);
  var i: integer;
    L: TMouseClickProxy;
  begin
    if not assigned(C) then exit;
    if TMouseClickProxy.IsOnClick(C.OnClick) then begin i:=0;
      repeat
        L:=TMouseClickProxy(FClickProxies.Items[i]); inc(i);
      until L.FOwner = C;
      C.OnClick:=L.FOwnerOnClick;
      FClickProxies.Remove(L);
      L.Free;
    end;
  end;

begin
  if not assigned(Ctrl) then exit;
  if Ctrl is TWinControl then
    for i:=0 to TWinControl(Ctrl).ControlCount-1 do
    begin
      C:=TWinControl(Ctrl).Controls[i];
      unsetMouseClickProxiesRecursively(C);
    end;
  unsetProxyFor(Ctrl);
end;

procedure TCustomMDIPanel.setMouseClickProxiesRecursively(Ctrl: TControl);
var
  i: integer;
  C: TControl;

  procedure setProxyFor(C: TControl);
  var
    L: TMouseClickProxy;
  begin
    if not assigned(C) then exit;
    if not TMouseClickProxy.IsOnClick(C.OnClick) then begin
      L:=TMouseClickProxy.Create(C);
      L.ProxyOnClick:=@PassivePanelOnClick;
      FClickProxies.Add(L);
    end;
  end;

begin
  if not assigned(Ctrl) then exit;
  setProxyFor(Ctrl);
  if Ctrl is TWinControl then
    for i:=0 to TWinControl(Ctrl).ControlCount-1 do
    begin
      C:=TWinControl(Ctrl).Controls[i];
      setMouseClickProxiesRecursively(C);
    end;
end;

procedure TCustomMDIPanel.setMouseClickProxies;
var
  i: integer;
  C: TControl;
  L: TMouseClickProxy;
  M, MP: TMethod;
begin
  setMouseClickProxiesRecursively(FCaptionPanel);
  unsetMouseClickProxiesRecursively(self.FCloseButton);
  setMouseClickProxiesRecursively(FClientPanel);
end;

procedure TCustomMDIPanel.unsetMouseClickProxies;
var
  i: integer;
  C: TControl;
  L: TMouseClickProxy;
begin
  for i:=0 to FClickProxies.Count-1 do
  begin
    L:=TMouseClickProxy(FClickProxies[i]);
    if assigned(L) and assigned(L.FOwner) then
    begin
      L.FOwner.OnClick:=L.FOwnerOnClick;
      L.Free;
    end;
  end;
  FClickProxies.Clear;
end;

{----------------------  TMouseClickProxy -------------------------
  This object substitutes OnClick method of a TheOwner control
  with its OnClick method.
  When the OnClick called it will call first a ProxyOnClick method
  then the original Owner OnClick method.
  Here in MDIPanel it is used for interseption of OnClick to children controls of
  inactive MDIPanel, so activating it before calling OnClick of the clicked
  children control.
 }
constructor TMouseClickProxy.Create(TheOwner: TControl);
var
  N: AnsiString;
begin
  FDestroyed:=False;
  FOwner:=TheOwner;
  N:=FOwner.Name;
  FOwnerOnClick:=FOwner.onClick;
  FOwner.onClick:=@OnClick;
end;

destructor TMouseClickProxy.Destroy;
begin
  FDestroyed:=True;
  if assigned(FOwner) then
  begin
    FOwner.onClick:=FOwnerOnClick;
    FOwnerOnClick:=nil;
    FProxyOnClick:=nil;
    FOwner:=nil;
  end;
  inherited Destroy;
end;

procedure TMouseClickProxy.OnClick(Sender: TObject);
var
  vOwnerOnClick: TNotifyEvent;
begin
  if FDestroyed then
    exit;
  vOwnerOnClick:=FOwnerOnClick;
  if assigned(FProxyOnClick) then
    FProxyOnClick(Sender);
  if assigned(vOwnerOnClick) then
    vOwnerOnClick(Sender);
end;

class function TMouseClickProxy.IsOnClick( P: TNotifyEvent ): boolean;
var PM: TMethod;
begin Result:=TMethod(P).Code = TMethod(@OnClick).Code; end;

{$endif Use_MouseClickProxy}

procedure TMDIClientPanel.ActiveDefaultControlChanged( NewControl: TControl );
begin
  if assigned(NewControl) and assigned(Parent) and (Parent is TCustomMDIPanel)
  then TCustomMDIPanel( Parent ).setActive( true );
end;
//procedure Register; begin RegisterComponents('MDIPanel', [TMDIPanel]); end;
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
var MW,MH, W,H, M,MCC, I,J,B : Integer;
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
                                                 B+((I-M)*H) div J, MW,MH );
    end;
  end;
end;

end.
