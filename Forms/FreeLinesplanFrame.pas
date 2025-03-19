unit FreeLinesPlanFrame;
{$MODE Delphi}
interface
uses
  LCLIntf,  PrintersDlgs,
  SysUtils, Classes,
  Graphics, Controls,
  Forms,    Dialogs,
  ComCtrls, Printers,
  Math,     ActnList,
  Spin,
  FreeTypes, FreeShipUnit, FreeGeometry, FreeStringUtils, FreeLanguageSupport;
type
  TLinesplanView = (lvProfile, lvAftBody, lvFrontBody, lvPlan);
  TLinesplanViews = set of TLinesplanView;
  TFreeLinesplanFrame = class( TFrame )                 { TFreeLinesplanFrame }
    ToolBar1: TToolBar;
    MenuImages: TImageList;
    ActionList1: TActionList;
    UseLights,ShowMonochrome,MirrorPlanView,ZoomExtents,ZoomIn,ZoomOut,
    Print,ShowFillColor,ExportDXF,SaveBitmap:                    TAction;
    ToolButton1,ToolButton2,ToolButton3,ToolButton4,
    ToolButton5,ToolButton7,ToolButton8,ToolButton9,ToolButton6,
    ToolButton13,ToolButton14,ToolButton15,ToolButton19:      TToolButton;
    SpinEdit1: TSpinEdit;
    PrintDialog: TPrintDialog;
    procedure SpinEdit1Change(Sender: TObject);
    procedure ViewportRequestExtents(Sender: TObject; var Min, Max: T3DVector);
    procedure ViewportRedraw(Sender: TObject);
    procedure ZoomExtentsExecute(Sender: TObject);
    procedure ZoomInExecute(Sender: TObject);
    procedure ZoomOutExecute(Sender: TObject);
    procedure ShowFillColorExecute(Sender: TObject);
    procedure PrintExecute(Sender: TObject);
    procedure ViewportMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure ViewportMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure SaveBitmapExecute(Sender: TObject);
    procedure UseLightsExecute(Sender: TObject);
    procedure ShowMonochromeExecute(Sender: TObject);
    procedure MirrorPlanViewExecute(Sender: TObject);
    procedure ExportDXFExecute(Sender: TObject);
  private                                              { Private declarations }
    FFreeShip: TFreeShip;
    FModelLength,                      // длина
    FModelHeight,                      // высота
    FModelBeam,                        // ширина
    FDiagonalWidth: TFloatType;        // толщина рыбины
    FMin3D, FMax3D,
    FProfileOrigin,                    // проекция бок
    FAftOrigin,                        // корпус - корма
    FFrontOrigin,                      // корпус - нос
    FPlanOrigin: T3DVector;            // полуширота
    FInitialPosition: TPoint;
//  HydObject: TFreeHydrostaticCalc;
//  Descr: TStringList;
    procedure FSetFreeShip( Val: TFreeShip );
    procedure CreateViewport;
  public                                                { Public declarations }
    Viewport: TFreeViewport;
    FontSize: integer;
    constructor Create( TheOwner: TComponent ); override;
    procedure UpdateMenu;
    property FreeShip: TFreeShip read FFreeShip write FSetFreeShip;
  end;

const
  SpacePercentage = 0.20; Textspace = 0.05;
var
  FreeLinesplanFrame: TFreeLinesplanFrame;

implementation
{$R *.lfm}

function CalculateSpace( Percentage, Min,Max: TFloatType): TFloatType;
   begin Result:=Percentage*(Max-Min); end; {Space}

procedure TFreeLinesplanFrame.CreateViewport;
begin
  Viewport:=TFreeViewport.Create( Self );
  with Viewport do begin
    Parent:=Self;
    Left:=0;
    Height:=465;
    Top:=29;
    Width:=800;
    Angle:=90;
    Align:=alClient;
    BackgroundImage.Alpha:=255;
    BackgroundImage.Owner:=Viewport;
    BackgroundImage.Quality:=100;
    BackgroundImage.Scale:=1;
    BackgroundImage.ShowInView:=fvBodyplan;
    BackgroundImage.Tolerance:=5;
    BackgroundImage.Transparent:=False;
    BackgroundImage.TransparentColor:=clBlack;
    BackgroundImage.Visible:=True;
    BevelOuter:=bvLowered;
    CameraType:=ftStandard;
    Color:=clWhite;
    DoubleBuffer:=True;
    Elevation:=90;
    Margin:=1;
    ViewType:=fvPlan;
    ViewportMode:=vmWireFrame;
    OnMouseDown:=ViewportMouseDown;
    OnMouseMove:=ViewportMouseMove;
    OnRedraw:=ViewportRedraw;
    OnRequestExtents:=ViewportRequestExtents;
  end;
end;

constructor TFreeLinesplanFrame.Create( TheOwner: TComponent );
      begin inherited Create( TheOwner ); CreateViewport; end;

procedure TFreeLinesplanFrame.UpdateMenu;
begin
  ShowFillcolor.Enabled:=not ShowMonochrome.Checked;
  UseLights.Enabled:=(ShowFillcolor.Checked) and (not ShowMonochrome.Checked);
  MirrorPlanview.Enabled:=Freeship.NumberofDiagonals=0;
end;

procedure TFreeLinesplanFrame.FSetFreeShip( Val:TFreeShip );
begin
  if FFreeShip<>nil then FFreeShip.LinesplanFrame:=nil; FFreeShip:=Val;
  if FFreeShip<>nil then begin //USE ONCE!
     FFreeShip.LinesplanFrame:=self;
     ViewPort.ZoomExtents;
     UpdateMenu;
  end;
end;

procedure TFreeLinesplanFrame.ZoomExtentsExecute(Sender: TObject);
begin Viewport.ZoomExtents; end;

procedure TFreeLinesplanFrame.ZoomInExecute(Sender: TObject);
begin Viewport.ZoomIn; end;

procedure TFreeLinesplanFrame.ZoomOutExecute(Sender: TObject);
begin Viewport.ZoomOut; end;

procedure TFreeLinesplanFrame.ShowFillColorExecute(Sender: TObject);
begin
  ShowFillcolor.Checked:=not ShowFillcolor.Checked;
  UpdateMenu;
  Viewport.Refresh;
end;


procedure TFreeLinesplanFrame.PrintExecute( Sender: TObject );
begin
  if Viewport.Width > Viewport.Height then Printer.Orientation:=poLandscape
                                      else Printer.Orientation:=poPortrait;
  if PrintDialog.Execute then
     Viewport.Print( FFreeship.ProjectSettings.ProjectUnits,True,
                    'FREE!ship linesplan ' );
end;

procedure TFreeLinesplanFrame.ViewportMouseMove
( Sender: TObject;
  Shift: TShiftState;
  X,Y: integer );
var
  P: TPoint;
begin
  if ssLeft in Shift then begin                         // Zoom in or zoom out
    if abs(FInitialPosition.Y-Y) > 4 then begin
      if Y < FInitialPosition.Y then Viewport.ZoomIn else
      if Y > FInitialPosition.Y then Viewport.ZoomOut;
      FInitialPosition.X:=X;
      FInitialPosition.Y:=Y;
    end;
  end
  else if ssRight in Shift then begin // Pan the window left, right, top or bottom
    if (abs(FInitialPosition.X-X)>4) or (abs(FInitialPosition.Y-Y)>4) then begin
      P.X:=Viewport.Pan.X+X-FInitialPosition.X;
      P.Y:=Viewport.Pan.Y+Y-FInitialPosition.Y; Viewport.Pan:=P;
      FInitialPosition.X:=X;
      FInitialPosition.Y:=Y;
    end;
  end;
end;

procedure TFreeLinesplanFrame.ViewportMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X,Y: integer);
begin
  FInitialPosition.X:=X;
  FInitialPosition.Y:=Y;
end;

procedure TFreeLinesplanFrame.SaveBitmapExecute( Sender: TObject );
  var Str: Ansistring;
begin Str:=FFreeShip.Preferences.ExportDirectory;
  if Str[Length(Str)]<>'\' then Str:=Str+'\';
  Str:=Str+ChangeFileExt( ExtractFilename(FFreeship.FileName),'')+'_Linesplan.png';
  Viewport.SaveAsBitmap( Str );
end;

procedure TFreeLinesplanFrame.UseLightsExecute(Sender: TObject);
begin
  UseLights.Checked:=not UseLights.Checked;
  UpdateMenu;
  Viewport.Refresh;
end;

procedure TFreeLinesplanFrame.ShowMonochromeExecute(Sender: TObject);
begin
  ShowMonochrome.Checked:=not ShowMonochrome.Checked;
  UpdateMenu;
  Viewport.Refresh;
end;

procedure TFreeLinesplanFrame.MirrorPlanViewExecute(Sender: TObject);
begin
  MirrorPlanview.Checked:=not MirrorPlanview.Checked;
  UpdateMenu;
  Viewport.ZoomExtents;
end;

procedure TFreeLinesplanFrame.ViewportRequestExtents
( Sender: TObject;
  var Min,Max: T3DVector );
var I,J,K: integer;
  Space,Tmp: TFloatType;
  Min3D,Max3D, P,Diff: T3DVector;
  Diagonal: TFreeIntersection;
  Spline: TFreeSpline;
  Plane: T3DPlane;
  First: boolean;
  Layer: TFreeSubdivisionLayer;
begin                                         Min3D:=Vector(0); Max3D:=Min3D;
  if Freeship<>nil then begin First:=True; // всяко хотя бы одна точка должна быть
    for I:=1 to Freeship.NumberOfLayers do begin
      Layer:=Freeship.Layer[I-1];
      if Layer.ShowInLinesplan then begin
        for J:=1 to Layer.Count do begin
          if First then begin
            Min3D:=Layer.Items[J-1].Min; Max3D:=Min3D; First:=False;
          end;
          MinMax( Layer.Items[J-1].Min,Min3D,Max3D );          // по внутренним
          MinMax( Layer.Items[J-1].Max,Min3D,Max3D );          // экстремумам
        end;
      end;
    end;
    for I:=1 to Freeship.NumberofStations do Freeship.Station[I-1].Extents(Min3D, Max3D);
    for I:=1 to Freeship.NumberofButtocks do Freeship.Buttock[I-1].Extents(Min3D, Max3D);
    for I:=1 to Freeship.NumberofWaterlines do Freeship.Waterline[I-1].Extents(Min3D, Max3D);
    for I:=1 to Freeship.NumberofDiagonals do Freeship.Diagonal[I-1].Extents(Min3D, Max3D);
    FMin3D:=Min3D;
    FMax3D:=Max3D;
    FModelHeight:=Max3D.Z-Min3D.Z;                         // высота
    FModelBeam:=2*Max3D.Y;                                 // ширина
    if FModelBeam<-2*Min3D.Y then FModelBeam:=-2*Min3D.Y;  // случай асимметрии
    FModelLength:=Max3D.X-Min3D.X;                         // длина
    Space:=SpacePercentage*FModelHeight;                   // зазор от высоты
    if 2*FModelBeam+Space>FModelLength then FModelLength:=2*FModelBeam+Space;
    FDiagonalWidth:=0;
    for I:=1 to Freeship.NumberofDiagonals do begin        // рыбины
      Diagonal:=Freeship.Diagonal[I-1];
      Plane.a:=0.0;
      Plane.b:=1/Sqrt( 2 );
      Plane.c:=-1/sqrt( 2 );
      Plane.d:=-Diagonal.Plane.d;
      if not Diagonal.Built then Diagonal.Rebuild;
      for J:=1 to Diagonal.Count do begin Spline:=Diagonal.Items[J-1];
        for k:=1 to Spline.NumberOfPoints do begin P:=Spline.Point[K-1];
          Tmp:=abs( Plane.A*P.x+Plane.B*P.y+Plane.C*P.z+Plane.D );
          if Tmp>FDiagonalWidth then FDiagonalWidth:=Tmp;
        end;
      end;
    end;
    Min.X:=Min3D.X-0.5*space;
    if Freeship.NumberofDiagonals>0 // if no diagonals present in model, the mirror planview
      then Min.Y:=Min3D.Z-2*Space-FModelHeight-0.5*FModelBeam-0.5*space-space-FDiagonalWidth
      else if (Freeship.NumberofDiagonals=0) and (MirrorPlanview.Checked)
        then Min.Y:=Min3D.Z-2*Space-FModelHeight-FModelBeam-0.5*space
        else Min.Y:=Min3D.Z-2*Space-FModelHeight-0.5*FModelBeam-0.5*space;
    Min.Z:=0.0;
    Max.X:=Min.X+FModelLength+3*space+1.2*FModelBeam;
    Max.Y:=-Min3D.Z+FModelHeight+0.5*space;
    Max.Z:=0.0;

    FProfileOrigin.X:=0.0;                       // Attachpoint for profileview
    FPlanOrigin:=FProfileOrigin;
    FProfileOrigin.Y:=-Min3D.Z; FProfileOrigin.Z:=0.0;
    FPlanOrigin.Y:=FProfileOrigin.Y-2*space-0.5*FModelBeam+Min3D.Z;

    FAftOrigin:=FProfileOrigin;         // Attachpoint for aft view of bodyplan
    FAftOrigin.X:=Max3D.x+3*space+0.6*FModelBeam;
    FFrontOrigin:=FAftOrigin;
    Diff:= 0.01*( Max3D-Min3D );              // Blowup the boundary box by 1%
    Min := Min - Diff;
    Max := Max + 6*Diff;
  end else begin
    Min.X:=-1; Max.X:=1; Min.Y:=-1; Max.Y:=1; Min.Z:=-1; Max.Z:=1;
  end; UpdateMenu;
end;

procedure TFreeLinesplanFrame.SpinEdit1Change( Sender: TObject );
begin
      FontSize:=(Sender as TSpinEdit).Value;
      Viewport.invalidate;
end;

procedure TFreeLinesplanFrame.ViewportRedraw( Sender: TObject );
type
  TriangleData = record
    P1,P2,P3, Center: T3DVector; Color: TColor; Symmetric: boolean;
  end;
  TriangleArray = record
    Capacity,Count: integer;
    Triangles: array of TriangleData;
  end;
var
    I,J,N,K,L, Pn,Pn1,Pn2, Steps,PenwidthFactor: integer;  Done: boolean;
    Edge: TFreeSubdivisionEdge;
    Layer: TFreeSubdivisionLayer;
    Child: TFreeSubdivisionFace;
    Face: TFreeSubdivisionControlface;
    MidshipLocation,Tmp,Space,Min,Max: TFloatType;  // ResFactor: TFloatType;
    WlPlane,MainPlane,Plane: T3DPlane;              // ScaleFactor: TFloatType;
    Below,Above: TriangleArray;
    Diagonal: TFreeIntersection;
    Spline: TFreeSpline;
    P,P1,P2,Pkn: T3DVector;
    Pts: array of TPoint; Pt: TPoint;
    Pts3D: array of T3DVector;
    Str: AnsiString;
    Prevcursor: TCursor;
    SubmColor: TColor;

  procedure DrawLineAtt
  ( Attachpoint, P1,P2: T3DVector;
    Text: AnsiString; CenterText: boolean; UpText: boolean = false
  );
  var
    Proj1,Proj2: T3DVector;
    Pts: array[0..1] of TPoint;
    W,S: integer;
  begin
    Proj1.X:=Attachpoint.X+P1.X;
    Proj1.Y:=Attachpoint.Y+P1.Y; Proj1.Z:=0.0;
    Pts[0]:=Viewport.Project( Proj1 );
    Proj2.X:=Attachpoint.X+P2.X;
    Proj2.Y:=Attachpoint.Y+P2.Y; Proj2.Z:=0.0;
    Pts[1]:=Viewport.Project( Proj2 );
    Viewport.Polyline( Pts );
    if UpText then begin
      Pts[0].y += (ViewPort.FontHeight-3);
      Pts[1].y += (ViewPort.FontHeight-3);
    end;
    if Text<>'' then begin
      if (CenterText) and (Pts[0].X = Pts[1].X) then begin
        W:=Viewport.TextWidth(Text) div 2;
        if UpText then Viewport.TextOut(Pts[1].X-W,Pts[1].Y, Text)
                  else Viewport.TextOut(Pts[0].X-W,Pts[0].Y, Text);
      end else begin
        W:=Viewport.TextWidth( Text ); S:=ViewPort.FontSize div 2;
        if Text[1]=' ' then Viewport.TextOut(Pts[1].X+S,Pts[1].Y,Text )
                       else Viewport.TextOut(Pts[0].X-W-S*2,Pts[1].Y,Text );
      end;
    end;
  end; {DrawLineAtt}

  procedure DrawDiagonalLine(Origin: T3DVector; P1, P2: T3DVector);
  var Pt: TPoint; P: T3DVector;
  begin
    P.X:=Origin.X+P1.Y;
    P.Y:=Origin.Y+P1.Z; P.Z:=0.0;
    Pt:=Viewport.Project(P);        Viewport.MoveTo( Pt.X,Pt.Y );
    P.X:=Origin.X+P2.Y;
    P.Y:=Origin.Y+P2.Z;
    Pt:=Viewport.Project(P);        Viewport.LineTo( Pt.X,Pt.Y );
    P.X:=Origin.X-P1.Y;
    P.Y:=Origin.Y+P1.Z;
    Pt:=Viewport.Project(P);        Viewport.MoveTo( Pt.X,Pt.Y );
    P.X:=Origin.X-P2.Y;
    P.Y:=Origin.Y+P2.Z;
    Pt:=Viewport.Project(P);        Viewport.LineTo( Pt.X,Pt.Y );
  end;{DrawDiagonalLine}

  procedure DrawLine(P1, P2: T3DVector);
  var
    Proj1,Proj2: T3DVector;
    Pts: array[0..1] of TPoint;
  begin                                                  // Draw in profileview
    Proj1.X:=FProfileOrigin.X+P1.X;
    Proj1.Y:=FProfileOrigin.Y+P1.Z;
    Proj1.Z:=0.0;
    Pts[0]:=Viewport.Project(Proj1);
    Proj2.X:=FProfileOrigin.X+P2.X;
    Proj2.Y:=FProfileOrigin.Y+P2.Z;
    Proj2.Z:=0.0;
    Pts[1]:=Viewport.Project(Proj2);
    Viewport.Polyline(Pts);                     // Draw in aft view of bodyplan
    if (P1.X<=MidshipLocation) and (P2.X<MidshipLocation) then begin
      Proj1.X:=FAftOrigin.X-P1.Y;
      Proj1.Y:=FAftOrigin.Y+P1.Z;
      Pts[0]:=Viewport.Project(Proj1);
      Proj2.X:=FAftOrigin.X-P2.Y;
      Proj2.Y:=FAftOrigin.Y+P2.Z;
      Pts[1]:=Viewport.Project(Proj2);
      Viewport.PolyLine(Pts);
      Proj1.X:=FAftOrigin.X+P1.Y;
      Proj1.Y:=FAftOrigin.Y+P1.Z;
      Pts[0]:=Viewport.Project(Proj1);
      Proj2.X:=FAftOrigin.X+P2.Y;
      Proj2.Y:=FAftOrigin.Y+P2.Z;
      Pts[1]:=Viewport.Project(Proj2);
      Viewport.Polyline(Pts);
    end;                                      // Draw in front view of bodyplan
    if (P1.X>=MidshipLocation) and (P2.X>MidshipLocation) then begin
      Proj1.X:=FFrontOrigin.X-P1.Y;
      Proj1.Y:=FFrontOrigin.Y+P1.Z;
      Pts[0]:=Viewport.Project(Proj1);
      Proj2.X:=FFrontOrigin.X-P2.Y;
      Proj2.Y:=FFrontOrigin.Y+P2.Z;
      Pts[1]:=Viewport.Project(Proj2);
      Viewport.Polyline(Pts);
      Proj1.X:=FFrontOrigin.X+P1.Y;
      Proj1.Y:=FFrontOrigin.Y+P1.Z;
      Pts[0]:=Viewport.Project(Proj1);
      Proj2.X:=FFrontOrigin.X+P2.Y;
      Proj2.Y:=FFrontOrigin.Y+P2.Z;
      Pts[1]:=Viewport.Project(Proj2);
      Viewport.Polyline(Pts);
    end;                                                   // Draw in plan view
    Proj1.X:=FPlanOrigin.X+P1.X;
    Proj1.Y:=FPlanOrigin.Y+P1.Y;
    Pts[0]:=Viewport.Project(Proj1);
    Proj2.X:=FPlanOrigin.X+P2.X;
    Proj2.Y:=FPlanOrigin.Y+P2.Y;
    Pts[1]:=Viewport.Project(Proj2);
    Viewport.Polyline(Pts);
    if (Freeship.NumberofDiagonals = 0) and (MirrorPlanview.Checked) then begin
      Proj1.X:=FPlanOrigin.X+P1.X;
      Proj1.Y:=FPlanOrigin.Y-P1.Y;
      Pts[0]:=Viewport.Project(Proj1);
      Proj2.X:=FPlanOrigin.X+P2.X;
      Proj2.Y:=FPlanOrigin.Y-P2.Y;
      Pts[1]:=Viewport.Project(Proj2);
      Viewport.Polyline(Pts);
    end;
  end; {DrawLine}

  procedure DrawSpline
  ( Spline: TFreeSpline;
    Views: TLinesplanViews;
    Style: TPenStyle );
  var
    I,YSign: integer;
    P,Pr: T3DVector;
    VPs: array of T3DVector;
    Pts: array of TPoint;
  begin
    VPs:=Spline.GetValues;
    Setlength( Pts,length(VPs) );
    if lvProfile in views then begin                 // батоксы и рыбины здесь?
      for i:=0 to length(VPs)-1 do begin P:=VPs[i];
        Pr:=Vector( FProfileOrigin.X+P.X,FProfileOrigin.Y+P.Z );
        Pts[i]:=Viewport.Project(Pr);
      end; Viewport.Polyline( Pts );
    end;
    if (lvAftBody in views) and (Spline.Max.X<=MidshipLocation) then begin
      for i:=0 to length(VPs)-1 do begin P:=VPs[i];           // корпус - корма
        Pr:=Vector( FAftOrigin.X-P.Y,FAftOrigin.Y+P.Z );
        Pts[i]:=Viewport.Project(Pr);
      end; Viewport.Polyline(Pts);
    end;
    if (lvFrontBody in views) and (Spline.Min.X>=MidshipLocation) then begin
      for i:=0 to length(VPs)-1 do begin P:=VPs[i];             // корпус - нос
        Pr:=Vector( FFrontOrigin.X+P.Y,FFrontOrigin.Y+P.Z );
        Pts[i]:=Viewport.Project(Pr);
      end; Viewport.Polyline(Pts);
    end;
    if lvPLan in views then for YSign:=-1 to +1 do
    if (YSign=1) or ((YSign=-1)                 // (+) ватерлинии левого борта
    and (Freeship.NumberofDiagonals=0)          // (-) ватерлинии правого борта
    and (MirrorPlanview.Checked)) then begin    //                   или рыбины
      for i:=0 to length(VPs)-1 do begin P:=VPs[i];
        Pr:=Vector( FPlanOrigin.X+P.X,FPlanOrigin.Y+YSign*P.Y );
          Pts[i]:=Viewport.Project(Pr);
        end; Viewport.Polyline(Pts);
    end;
  end; {DrawSpline}

  procedure DrawIntersection
  (Intersection: TFreeIntersection; Views: TLinesplanViews; Style: TPenStyle );
  var I: integer;
  begin
    if not Intersection.Built then Intersection.Rebuild;
    for I:=0 to Intersection.Count-1 do DrawSpline( Intersection.Items[I],Views,Style );
  end;

  procedure AddTriangle
  ( P1,P2,P3: T3DVector; Color: TColor;
    var Destination: TriangleArray; Symmetric: boolean );
  var C: T3DVector;
  begin
    if Destination.Count = Destination.Capacity then begin
      Destination.Capacity:=Destination.Capacity+50;
      Setlength(Destination.Triangles, Destination.Capacity);
    end;
    C.X:=(P1.X+P2.X+P3.X) / 3;
    C.Y:=(P1.Y+P2.Y+P3.Y) / 3;
    C.Z:=(P1.Z+P2.Z+P3.Z) / 3;
    Destination.Triangles[Destination.Count].P1:=P1;
    Destination.Triangles[Destination.Count].P2:=P2;
    Destination.Triangles[Destination.Count].P3:=P3;
    Destination.Triangles[Destination.Count].Center:=C;
    Destination.Triangles[Destination.Count].Color:=Color;
    Destination.Triangles[Destination.Count].Symmetric:=Symmetric;
    Inc(Destination.Count);
  end; {AddTriangle}

  procedure ProcessFace(Face: TFreeSubdivisionFace; Color: TColor; Symmetric: boolean);
  var
    I,J,Nabove,Nbelow: integer;
    AbovePoints,BelowPoints: TFreeCoordinateArray;
  begin
    for I:=3 to Face.NumberOfpoints do begin
      ClipTriangle(Face.Point[0].Coordinate,
        Face.Point[I-2].Coordinate,
        Face.Point[I-1].Coordinate,
        WlPlane, Nabove, Nbelow, AbovePoints, BelowPoints); // proces submerged area
      for J:=3 to NBelow do
        AddTriangle(BelowPoints[0], BelowPoints[J-2], BelowPoints[J-1], SubmColor, Below, Symmetric);
      for J:=3 to NAbove do
        AddTriangle(AbovePoints[0], AbovePoints[J-2], AbovePoints[J-1], Color, Above, Symmetric);
    end;
  end; {Processface}

  procedure SortTriangles( var Triangles: TriangleArray; SortType: byte );
    procedure QuickSort( L,R: integer );              // Sorttype 1=X, 2=Y, 3=Z
    var I,J: integer; T1: TriangleData;
      procedure Swap( I,J: integer ); var Tmp: TriangleData;
      begin Tmp:=Triangles.Triangles[I];
            Triangles.Triangles[I]:=Triangles.Triangles[J];
            Triangles.Triangles[J]:=Tmp;
      end; {swap two triangles}
    begin
      I:=L; J:=R; T1:=Triangles.Triangles[(L+R) div 2];
      repeat
        if SortType = 1 then begin
          while Triangles.Triangles[I].Center.X < T1.Center.X do Inc(I);
          while T1.Center.X < Triangles.Triangles[J].Center.X do Dec(J); end else
        if SortType = 2 then begin
          while Triangles.Triangles[I].Center.Y < T1.Center.Y do Inc(I);
          while T1.Center.Y < Triangles.Triangles[J].Center.Y do Dec(J); end else
        begin
          while Triangles.Triangles[I].Center.Z < T1.Center.Z do Inc(I);
          while T1.Center.Z < Triangles.Triangles[J].Center.Z do Dec(J);
        end;
        if I<=J then begin Swap(I,J); Inc(I); Dec(J); end;
      until I>J;
      if L<J then QuickSort(L,J);
      if I<R then QuickSort(I,R);
    end; {QuickSort}
  begin
    if Triangles.Count > 1 then QuickSort(0, Triangles.Count-1);
  end; {SortTriangles}

  procedure DrawTriangles(Triangles: TriangleArray; Views: TLinesplanViews);
  var
    I: integer;
    Triangle: TriangleData;
    Pts: array[0..2] of TPoint;
    P,L: T3DVector;
    Col: TColor;

    function GetColor
    ( Lightvector: T3DVector;
      DpScale,Contrast: TFloatType;
      Triangle: TriangleData ): TColor;
    var
      N: T3DVector; Dp: TFloatType; R,G,B: byte;
    begin
      N:=UnifiedNormal( Triangle.P1,Triangle.P2,Triangle.P3 );
      Dp:=DotProduct( N,L );
      if Dp<0.0 then Dp:=-Dp;
      Dp:=Power( Dp,Contrast );
      Dp:=(DpScale-1.0)+DpScale * Dp;
      if Dp > 1.0 then Dp:=1.0;
      R:=Round( Dp*GetRValue(Triangle.Color) );
      G:=Round( Dp*GetGValue(Triangle.Color) );
      B:=Round( Dp*GetBValue(Triangle.Color) );
      Result:=RGB( R,G,B );
    { Viewport.ShadedColor(Dp,GetRValue(Triangle.Color),GetGValue(Triangle.Color),GetBValue(Triangle.Color),R,G,B);
      Result:=RGB(R,G,B);
    }
    end; {GetColor}
  begin
    if lvAftBody in views then begin P.Z:=0.0;           // (-) кормовые обводы
      L:=Vector( -1.0 );
      for I:=Triangles.Count downto 1 do begin
        Triangle:=Triangles.Triangles[I-1];
        if not UseLights.Checked then begin
          Viewport.BrushColor:=Triangle.Color;
          Viewport.PenColor:=Triangle.Color;
        end else begin
          Col:=GetColor( L,1.4,1.0,Triangle );
          Viewport.BrushColor:=Col;
          Viewport.PenColor:=Col;
        end;                                                // Draw in aft view
        P.X:=FAftOrigin.X-Triangle.P1.Y;
        P.Y:=FAftOrigin.Y+Triangle.P1.Z;
        Pts[0]:=Viewport.Project(P);
        P.X:=FAftOrigin.X-Triangle.P2.Y;
        P.Y:=FAftOrigin.Y+Triangle.P2.Z;
        Pts[1]:=Viewport.Project(P);
        P.X:=FAftOrigin.X-Triangle.P3.Y;
        P.Y:=FAftOrigin.Y+Triangle.P3.Z;
        Pts[2]:=Viewport.Project(P);
        Viewport.Polygon(Pts);
{       if Triangle.Symmetric then begin
          P.X:=FAftOrigin.X+Triangle.P1.Y;
          P.Y:=FAftOrigin.Y+Triangle.P1.Z;
          Pts[0]:=Viewport.Project(P);
          P.X:=FAftOrigin.X+Triangle.P2.Y;
          P.Y:=FAftOrigin.Y+Triangle.P2.Z;
          Pts[1]:=Viewport.Project(P);
          P.X:=FAftOrigin.X+Triangle.P3.Y;
          P.Y:=FAftOrigin.Y+Triangle.P3.Z;
          Pts[2]:=Viewport.Project(P);
          Viewport.Polygon(Pts);
        end;
}     end;
    end else begin
      L:=Vector( -1.0 );
      for I:=1 to Triangles.Count do begin
        Triangle:=Triangles.Triangles[I-1];
        P.Z:=0.0;
        if lvProfile in Views then begin
          L:=Vector( 0.0,-1.0 );
          if not UseLights.Checked then begin
            Viewport.BrushColor:=Triangle.Color;
            Viewport.PenColor:=Triangle.Color;
          end else begin
            Col:=GetColor(L, 1.1, 1.5, Triangle);
            Viewport.BrushColor:=Col;
            Viewport.PenColor:=Col;
          end;                                          // Draw in profile view
          P.X:=FProfileOrigin.X+Triangle.P1.X;
          P.Y:=FProfileOrigin.Y+Triangle.P1.Z;
          Pts[0]:=Viewport.Project(P);
          P.X:=FProfileOrigin.X+Triangle.P2.X;
          P.Y:=FProfileOrigin.Y+Triangle.P2.Z;
          Pts[1]:=Viewport.Project(P);
          P.X:=FProfileOrigin.X+Triangle.P3.X;
          P.Y:=FProfileOrigin.Y+Triangle.P3.Z;
          Pts[2]:=Viewport.Project(P);
          Viewport.Polygon(Pts);
        end;
        if lvFrontBody in views then begin
          L:=Vector( 1.0 );
          if not UseLights.Checked then begin
            Viewport.BrushColor:=Triangle.Color;
            Viewport.PenColor:=Triangle.Color;
          end else begin
            Col:=GetColor( L,1.4,1.0,Triangle );
            Viewport.BrushColor:=Col;
            Viewport.PenColor:=Col;
          end;                                            // Draw in Front view
          P.X:=FFrontOrigin.X+Triangle.P1.Y;              // (+) носовые обводы
          P.Y:=FFrontOrigin.Y+Triangle.P1.Z;
          Pts[0]:=Viewport.Project(P);
          P.X:=FFrontOrigin.X+Triangle.P2.Y;
          P.Y:=FFrontOrigin.Y+Triangle.P2.Z;
          Pts[1]:=Viewport.Project(P);
          P.X:=FFrontOrigin.X+Triangle.P3.Y;
          P.Y:=FFrontOrigin.Y+Triangle.P3.Z;
          Pts[2]:=Viewport.Project(P);
          Viewport.Polygon(Pts);
{         if Triangle.Symmetric then begin
            P.X:=FFrontOrigin.X+Triangle.P1.Y;
            P.Y:=FFrontOrigin.Y+Triangle.P1.Z;
            Pts[0]:=Viewport.Project(P);
            P.X:=FFrontOrigin.X+Triangle.P2.Y;
            P.Y:=FFrontOrigin.Y+Triangle.P2.Z;
            Pts[1]:=Viewport.Project(P);
            P.X:=FFrontOrigin.X+Triangle.P3.Y;
            P.Y:=FFrontOrigin.Y+Triangle.P3.Z;
            Pts[2]:=Viewport.Project(P);
            Viewport.Polygon(Pts);
          end;
}       end;
        if lvPlan in views then begin
          L:=Vector( 0.0,0.0,-1.0 );
          if not UseLights.Checked then begin
            Viewport.BrushColor:=Triangle.Color;
            Viewport.PenColor:=Triangle.Color;
          end else begin
            Col:=GetColor(L, 1.1, 1.5, Triangle);
            Viewport.BrushColor:=Col;
            Viewport.PenColor:=Col;
          end;                                    // Draw portside in plan view
          P.X:=FPlanOrigin.X+Triangle.P1.X;
          P.Y:=FPlanOrigin.Y+Triangle.P1.Y;
          Pts[0]:=Viewport.Project(P);
          P.X:=FPlanOrigin.X+Triangle.P2.X;
          P.Y:=FPlanOrigin.Y+Triangle.P2.Y;
          Pts[1]:=Viewport.Project(P);
          P.X:=FPlanOrigin.X+Triangle.P3.X;
          P.Y:=FPlanOrigin.Y+Triangle.P3.Y;
          Pts[2]:=Viewport.Project(P);
          Viewport.Polygon(Pts);
          if (Freeship.NumberofDiagonals = 0)
          and (MirrorPlanview.Checked) and (Triangle.Symmetric) then begin
            P.X:=FPlanOrigin.X+Triangle.P1.X;
            P.Y:=FPlanOrigin.Y-Triangle.P1.Y;
            Pts[0]:=Viewport.Project(P);
            P.X:=FPlanOrigin.X+Triangle.P2.X;
            P.Y:=FPlanOrigin.Y-Triangle.P2.Y;
            Pts[1]:=Viewport.Project(P);
            P.X:=FPlanOrigin.X+Triangle.P3.X;
            P.Y:=FPlanOrigin.Y-Triangle.P3.Y;
            Pts[2]:=Viewport.Project(P);
            Viewport.Polygon(Pts);
          end;
        end;
      end;
    end;
  end;{DrawTriangles}

  procedure SetFontHeight(DesiredHeight: TFloatType);
  var Height: integer;
      CurrentHeight: integer;
  begin                        // Sets the fontheight to a height in modelspace
    Height:=round( DesiredHeight*Viewport.Scale*Viewport.Zoom );
    CurrentHeight:=Viewport.FontHeight;
    if CurrentHeight <> Height then Viewport.FontHeight:=Height;
                // below code causes loop redraw and 100% CPU.
               // Changed to above code with direct set of required Font.Height
      {Height:=DesiredHeight*Viewport.Scale*Viewport.Zoom;
      Viewport.Font.Size:=8;
      CurrentHeight:=Viewport.TextHeight('X');
      while CurrentHeight>Height do begin
         Viewport.Font.Size:=Viewport.Font.Size-1;
         CurrentHeight:=Viewport.TextHeight('X');
         if Viewport.Font.Size<6 then break;
      end;}
  end;{SetFontHeight}

begin
  if Freeship = nil then exit;
  if Viewport.Printing then PenWidthfactor:=Round( Viewport.PrintScaleFactor )
                       else PenwidthFactor:=1;
  if Viewport.Printing then Steps:=1250
                       else Steps:=200;
  WlPlane.a:=0.0;
  WlPlane.b:=0.0;
  WlPlane.c:=1.0;
  WlPlane.d:=-(Freeship.Surface.Min.Z+Freeship.ProjectSettings.ProjectDraft);
  MidshipLocation:=Freeship.ProjectSettings.ProjectSplitSectionLocation;
//if not FFreeship.HydrostaticCalculation[0].Calculated then
//                 FFreeship.HydrostaticCalculation[0].Calculate;
//MidshipLocation:=FFreeship.HydrostaticCalculation[0].MidshipLocation;
  Mainplane.a:=1.0;
  Mainplane.b:=0.0;
  Mainplane.c:=0.0;
  Mainplane.d:=-MidshipLocation;

  Viewport.BrushStyle:=bsSolid;
  Below.Count:=0;
  Below.Capacity:=0;
  Above.Count:=0;
  Above.Capacity:=0;
  Prevcursor:=Screen.Cursor;
  Screen.Cursor:=crHourglass;
  Viewport.PenColor:=clSilver;

  Viewport.FontName:='Times';
  Viewport.FontColor:=clBlack;
  if Viewport.DrawingCanvas.Font=nil then Viewport.DrawingCanvas.Font:=TFont.Create;
  Viewport.DrawingCanvas.Font.Name:='Times';
  Viewport.DrawingCanvas.Font.Color:=clBlack;
  Viewport.DrawingCanvas.Font.Size:=FontSize;

  if (not ShowMonochrome.Checked) and (ShowFillcolor.Checked) then begin
  for I:=1 to Freeship.Surface.NumberOfLayers do
    if Freeship.Layer[I-1].ShowInLinesplan then begin
      Layer:=Freeship.Surface.Layer[I-1];
      if Freeship.ProjectSettings.ProjectShadeUnderwaterShip
      then SubmColor:=Freeship.ProjectSettings.ProjectUnderWaterColor
      else SubmColor:=Layer.Color;
      for j:=1 to Layer.Count do begin Face:=Layer.Items[J-1];
        Done:=False;
        if Face.Max.Z<Freeship.Surface.Min.Z +
        Freeship.ProjectSettings.ProjectDraft then begin
          for N:=1 to Face.ChildCount do begin Child:=Face.Child[N-1];
            for K:=3 to Child.NumberOfpoints do
            AddTriangle(Child.Point[0].Coordinate,Child.Point[K-2].Coordinate,
              Child.Point[K-1].Coordinate,SubmColor,Below,Layer.Symmetric);
          end;
          Done:=True;
        end else
        if Face.Min.Z>Freeship.Surface.Min.Z+Freeship.ProjectSettings.ProjectDraft
        then begin
          for N:=1 to Face.ChildCount do begin Child:=Face.Child[N-1];
            for K:=3 to Child.NumberOfpoints do
            AddTriangle(Child.Point[0].Coordinate, Child.Point[K-2].Coordinate,
             Child.Point[K-1].Coordinate, Layer.Color, Above, Layer.Symmetric);
          end; Done:=True;
        end;
        if not done then for N:=1 to Face.ChildCount do
            Processface(Face.Child[N-1], Layer.Color, Layer.Symmetric);
      end;
    end;
    SortTriangles(Below,2); DrawTriangles(Below,[lvProfile]);
    SortTriangles(Above,2); DrawTriangles(Above,[lvProfile]);
    SortTriangles(Below,1); DrawTriangles(Below,[lvAftBody]);
                            DrawTriangles(Below,[lvFrontBody]); // frontview on bodyplan
    SortTriangles(Above,1); DrawTriangles(Above,[lvAftBody]);   // Aft bodyplan
                            DrawTriangles(Above,[lvFrontBody]); // plan view
    SortTriangles(Below,3); DrawTriangles(Below,[lvPlan]);
    SortTriangles(Above,3); DrawTriangles(Above,[lvPlan]); // Draw dwl as a white band in profile and bodyplan views

    Viewport.PenColor:=Viewport.Color;
    Viewport.SetPenWidth(5 * PenwidthFactor);
    Space:=CalculateSpace(0.5 * textspace, FMin3D.X, FMax3D.X);
    Viewport.BrushStyle:=bsClear;                      // draw dwl in profile
    DrawLineAtt( FProfileOrigin,
      Vector( FMin3D.X-Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
      Vector( FMax3D.X+Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),'',False);
                                                    // draw dwl in aft bodyplan
    Space:=CalculateSpace(textspace, FMin3D.Y, FMax3D.Y);
    DrawLineAtt(FAftOrigin,
      Vector(-FMax3D.Y-Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
      Vector( FMax3D.Y+Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),'',False);
                                                  // draw dwl in front bodyplan
    DrawLineAtt(FFrontOrigin,
      Vector(-FMax3D.Y-Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
      Vector( FMax3D.Y+Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),'',False);
  end;                                                             // Draw grid
  if ShowMonochrome.Checked then Viewport.PenColor:=clSilver
                            else Viewport.PenColor:=clSilver;
  Viewport.BrushStyle:=bsClear;              // first draw grid in profile view
  Viewport.SetPenWidth(2 * PenwidthFactor);
  Space:=CalculateSpace(0.2*textspace, FMin3D.X,FMax3D.X);
  if ShowMonochrome.Checked then Viewport.FontColor:=clBlack
                            else Viewport.FontColor:=clTeal;   // draw baseline
  DrawLineAtt( FProfileOrigin,
               Vector( FMin3D.X-Space,FMin3D.Z),
               Vector( FMax3D.X+Space,FMin3D.Z),' Base ',False ); //'Base '+ConvertDimension( FMin3D.Z,Freeship.ProjectSettings.ProjectUnits),False );
  DrawLineAtt( FProfileOrigin,                                    // draw dwl
               Vector(FMin3D.X-Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
               Vector(FMax3D.X+Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
               ' DWL ',false,true );                                            //'DWL '+ConvertDimension(FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft,Freeship.ProjectSettings.ProjectUnits), False);
  Viewport.SetPenWidth( PenwidthFactor );
  Viewport.FontColor:=clBlack;
  for I:=1 to FFreeship.NumberofWaterlines do begin
    Tmp:=-FFreeship.Waterline[I-1].Plane.D;
    Str:=ConvertDimension(Tmp, Freeship.ProjectSettings.ProjectUnits);
    DrawLineAtt( FProfileOrigin,Vector(FMin3D.X-Space,Tmp),
                                Vector(FMax3D.X+Space,Tmp),Str,False,True);
  end;
  Space:=CalculateSpace( textspace,FMin3D.Z,FMax3D.Z );   // ватерлинии на боку
  for I:=1 to FFreeship.NumberofStations do begin
    Tmp:=-FFreeship.Station[I-1].Plane.D;
    Str:=ConvertDimension(Tmp, Freeship.ProjectSettings.ProjectUnits);
    DrawLineAtt( FProfileOrigin,Vector(Tmp,FMin3D.Z-space),
                                Vector(Tmp,FMax3D.Z+space),Str,True );
  end;                                          // draw grid in aft body view
  Viewport.SetPenWidth( 2*PenwidthFactor );
  Space:=CalculateSpace( textspace,FMin3D.Y,FMax3D.Y );
  if ShowMonochrome.Checked then Viewport.FontColor:=clBlack
                            else Viewport.FontColor:=clTeal;;      // draw base
  DrawLineAtt( FAftOrigin,Vector(-FMax3D.Y-Space, FMin3D.Z),
                          Vector(FMax3D.Y+Space, FMin3D.Z),' Base ',false); // +ConvertDimension(FMin3D.Z, Freeship.ProjectSettings.ProjectUnits),False);
  DrawLineAtt(FAftOrigin,                                           // draw dwl
    Vector(-FMax3D.Y-Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
    Vector( FMax3D.Y+Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
    ' DWL ',false,true );                                                       //+ConvertDimension(FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft,Freeship.ProjectSettings.ProjectUnits),False);
  Space:=CalculateSpace( textspace,FMin3D.Z,FMax3D.Z );
  DrawLineAtt(FAftOrigin, Vector(0.0,FMin3D.Z-space),              // ДП=Center
                          Vector(0.0,FMax3D.Z+space),'ДП',True );

  Space:=CalculateSpace(textspace,FMin3D.Y,FMax3D.Y);
  Viewport.FontColor:=clGray;                 // ватерлинии на корпусе по корме
  Viewport.SetPenWidth(PenwidthFactor);
  for I:=1 to FFreeship.NumberofWaterlines do begin
    Tmp:=-FFreeship.Waterline[I-1].Plane.D;
    Str:=ConvertDimension( Tmp,Freeship.ProjectSettings.ProjectUnits );
    DrawLineAtt( FAftOrigin,Vector(-FMax3D.Y-Space,Tmp),
                            Vector(FMax3D.Y+Space,Tmp),Str,False,True );
  end;
  Space:=CalculateSpace( textspace,FMin3D.Z,FMax3D.Z );
  for I:=1 to FFreeship.NumberofButtocks do begin
    Tmp:=-FFreeship.Buttock[I-1].Plane.D;        // батоксы на корпусе по корме
    Str:=ConvertDimension( Tmp,Freeship.ProjectSettings.ProjectUnits );
    DrawLineAtt( FAftOrigin,Vector(Tmp, FMin3D.Z-space),
                            Vector(Tmp, FMax3D.Z+space),Str,True );
    DrawLineAtt( FAftOrigin,Vector(-Tmp,FMin3D.Z-space),
                            Vector(-Tmp,FMax3D.Z+space),Str,True );
  end;
  Viewport.SetPenWidth( 2*PenwidthFactor);      // draw grid in front body view
  Space:=CalculateSpace( textspace,FMin3D.Y,FMax3D.Y );        // корус по носу
  if ShowMonochrome.Checked then Viewport.FontColor:=clBlack
                            else Viewport.FontColor:=clTeal;   // draw baseline
  DrawLineAtt(FFrontOrigin,
    Vector(-FMax3D.Y-Space,FMin3D.Z),
    Vector(FMax3D.Y+Space,FMin3D.Z),' Base ',false );                       // + ConvertDimension(FMin3D.Z, Freeship.ProjectSettings.ProjectUnits),False);
  DrawLineAtt(FFrontOrigin,                         // draw dwl
    Vector(-FMax3D.Y-Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
    Vector(FMax3D.Y+Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
    ' DWL ',false,true );                                                       //+ConvertDimension(FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft,Freeship.ProjectSettings.ProjectUnits), False);
  Space:=CalculateSpace(textspace, FMin3D.Z, FMax3D.Z);
  DrawLineAtt( FFrontOrigin,Vector(0.0,FMin3D.Z-space),
                            Vector(0.0,FMax3D.Z+space),' ДП ', True);
  Space:=CalculateSpace( textspace,FMin3D.Y,FMax3D.Y );
  Viewport.FontColor:=clGray;
  Viewport.SetPenWidth( PenwidthFactor );                // Font.Height;
  for I:=1 to FFreeship.NumberofWaterlines do begin       // ватерлинии по носу
    Tmp:=-FFreeship.Waterline[I-1].Plane.D;
    Str:=ConvertDimension( Tmp,Freeship.ProjectSettings.ProjectUnits );
    DrawLineAtt( FFrontOrigin,Vector(-FMax3D.Y-Space,Tmp),
                              Vector(FMax3D.Y+Space,Tmp),Str,False,true );
  end;
  Space:=CalculateSpace( textspace,FMin3D.Z,FMax3D.Z );
  for I:=1 to FFreeship.NumberofButtocks do begin // бактокы на корпусе по носу
    Tmp:=-FFreeship.Buttock[I-1].Plane.D;
    Str:=ConvertDimension( Tmp,Freeship.ProjectSettings.ProjectUnits);
    DrawLineAtt( FFrontOrigin,Vector(Tmp,FMin3D.Z-space),
                              Vector(Tmp,FMax3D.Z+space),Str,True);
    DrawLineAtt( FFrontOrigin,Vector(-Tmp,FMin3D.Z-space),
                              Vector(-Tmp,FMax3D.Z+space),Str,True);
  end;

  Viewport.SetPenWidth( 2*PenwidthFactor);            // draw grid in plan view
  Space:=CalculateSpace( 0.2*textspace,FMin3D.X,FMax3D.X );
  if ShowMonochrome.Checked then Viewport.FontColor:=clBlack
                            else Viewport.FontColor:=clTeal;
  DrawLineAtt( FPlanOrigin,Vector( FMin3D.X-Space ),
               Vector( FMax3D.X+Space ),' Center ',False,true );
  Viewport.FontColor:=clBlack;
  Viewport.SetPenWidth(PenwidthFactor);
  for I:=1 to FFreeship.NumberofButtocks do begin
    Tmp:=-FFreeship.Buttock[I-1].Plane.D;
    Str:=ConvertDimension(Tmp, Freeship.ProjectSettings.ProjectUnits );
    DrawLineAtt( FPlanOrigin,Vector(FMin3D.X-Space,Tmp),
                             Vector(FMax3D.X+Space,Tmp),Str,False,true );
    if (Freeship.NumberofDiagonals = 0) and (MirrorPlanview.Checked) then
      DrawLineAtt( FPlanOrigin,Vector(FMin3D.X-Space,-Tmp),
                               Vector(FMax3D.X+Space,-Tmp),Str,False,true);
  end;
  Space:=CalculateSpace( textspace,FMin3D.Y,FMax3D.Y );
  for I:=1 to FFreeship.NumberofStations do begin
    Tmp:=-FFreeship.Station[I-1].Plane.D;
    Str:=ConvertDimension(Tmp, Freeship.ProjectSettings.ProjectUnits);
    if (Freeship.NumberofDiagonals=0) and (MirrorPlanview.Checked )
    then DrawLineAtt( FPlanOrigin,Vector( Tmp,-FMax3D.Y-space),
                                  Vector( Tmp,FMax3D.Y+space),Str,True )
    else DrawLineAtt( FPlanOrigin,Vector( Tmp,-FDiagonalWidth-space),
                                  Vector( Tmp,FMax3D.Y+space),Str,True );
  end;
  if not ShowFillColor.checked then begin               //   draw knuckle-lines
    if ShowFillColor.Checked then Viewport.SetPenWidth( PenwidthFactor )
                             else Viewport.SetPenWidth( 2*PenwidthFactor );
    Viewport.PenStyle:=psSolid;
    if ShowMonochrome.Checked then Viewport.PenColor:=clTeal //  Aqua
                              else Viewport.PenColor:=Freeship.Preferences.CreaseColor;
    for I:=1 to FreeShip.NumberOfLayers do begin Layer:=FreeShip.Layer[I-1];
      if Layer.ShowInLinesplan then
      for J:=1 to Layer.Count do begin Face:=layer.Items[J-1];
        for K:=1 to Face.ControlDescendantEdgeCount do begin
          Edge:=Face.ControlDescendantEdge[K-1];
          if Edge.Crease
          then DrawLine(Edge.StartPoint.Coordinate, Edge.EndPoint.Coordinate);
        end;
      end;
    end;
  end;
  Viewport.SetPenWidth(PenwidthFactor);
  MidshipLocation:=Freeship.ProjectSettings.ProjectSplitSectionLocation;
  if ShowMonochrome.Checked then Viewport.PenColor:=clBlack  // Draw Waterlines
               else Viewport.PenColor:=Freeship.Preferences.WaterlineColor;
  for i:=1 to Freeship.NumberofWaterlines do
      DrawIntersection(Freeship.Waterline[I-1],[lvPlan],psSolid);
  if ShowMonochrome.Checked then Viewport.PenColor:=clBlack    // Draw stations
                 else Viewport.PenColor:=Freeship.Preferences.StationColor;
  for i:=1 to Freeship.NumberofStations do
    DrawIntersection(Freeship.Station[I-1],[lvAftBody,lvFrontBody],psSolid);
  if ShowMonochrome.Checked then Viewport.PenColor:=clBlack    // Draw Buttocks
                 else Viewport.PenColor:=Freeship.Preferences.ButtockColor;
  for i:=1 to Freeship.NumberofButtocks do
      DrawIntersection(Freeship.Buttock[I-1],[lvProfile],psSolid);
  Viewport.PenWidth:=PenwidthFactor;
  for I:=1 to Freeship.NumberofDiagonals do begin             // Draw diagonals
    Diagonal:=Freeship.Diagonal[I-1];
    Plane.a:=0.0;
    Plane.b:=1/Sqrt(2);
    Plane.c:=-1/sqrt(2);
    Plane.d:=-Diagonal.Plane.d;
    if not Diagonal.Built then Diagonal.Rebuild;
    for J:=1 to Diagonal.Count do begin
      Viewport.SetPenWidth(1);
      if ShowMonochrome.Checked then Viewport.PenColor:=clBlack
         else Viewport.PenColor:=Freeship.Preferences.DiagonalColor;
      Spline:=Diagonal.Items[J-1];
      Spline.Fragments:=Steps;
      Pts3D:=Spline.GetValues;
      Setlength(Pts, length(Pts3D));
      Min:=0;
      Max:=0;
      L:=0; Pn:=0;
      for K:=0 to length(Pts3D)-1 do begin P:=Pts3D[K];
        Tmp:=abs( Plane.A * P.x+Plane.B * P.y+Plane.C * P.z+Plane.D );
        if K = 0 then begin Min:=Tmp; Max:=Tmp; end else begin
          if Tmp < min then Min:=Tmp;
          if Tmp > max then Max:=Tmp;
        end;
        P:=Vector( FPlanOrigin.X+P.X,FPlanOrigin.Y-abs(Tmp) );
        Pts[K]:=Viewport.Project(P);
      end;
      Viewport.Polyline(Pts);                 // draw as grid in bodyplan views
      Viewport.SetPenWidth(PenwidthFactor);
      if ShowMonochrome.Checked then Viewport.PenColor:=clBlack
                                else Viewport.PenColor:=clSilver;
               // calculate height of intersection of diagonal with centerplane
      Tmp:=-Diagonal.PLane.d / Diagonal.Plane.c;
      P1:=Vector( 0.0,Min*Sin(DegToRad(45)), Tmp-Min*Sin(DegToRad(45)));
      P2:=Vector( 0.0,Max*Sin(DegToRad(45)), Tmp-Max*Sin(DegToRad(45)));
      DrawDiagonalLine( FAftOrigin,P1,P2 );
      DrawDiagonalLine( FFrontOrigin,P1,P2 );
    end;
  end;
//  Descr:=TStringList.Create; // заготовки для гидростатики...
//  HydObject:=TFreeHydrostaticCalc.Create(FFreeShip);
//  HydObject.AddHeader( Descr );
//  HydObject.Destroy;
//  Descr.Destroy;  ...  Pt:=FInitialPosition;

  Viewport.FontColor:=clGray;
  Tmp:=0.0;
  if Freeship.NumberofDiagonals>0 then Tmp:=FDiagonalWidth else
  if MirrorPlanview.Checked then Tmp:=FMax3D.Y;
  Pt:=Viewport.Project( Vector( FMin3D.X,FPlanOrigin.Y-Tmp ) );
  Pt.y-=ViewPort.FontHeight*3;
  Viewport.TextOut( Pt.X,Pt.Y,Userstring(39)+' : '+FreeShip.ProjectSettings.ProjectName );
  Pt.y-=ViewPort.FontHeight;
  Viewport.TextOut( Pt.X,Pt.Y,Userstring(40)+' : '+FreeShip.ProjectSettings.ProjectDesigner );
  if FreeShip.ProjectSettings.ProjectComment<>'' then begin
    Pt.y-=ViewPort.FontHeight;
    Viewport.TextOut( Pt.X,Pt.Y,Userstring(42)+' : '+FreeShip.ProjectSettings.ProjectComment );
  end;
  if FreeShip.ProjectSettings.ProjectFileCreatedBy<>'' then begin
    Pt.y-=ViewPort.FontHeight;
    Viewport.TextOut( Pt.X,Pt.Y,Userstring(41)+' : '+FreeShip.ProjectSettings.ProjectFileCreatedBy );
  end;
  Pt.y-=ViewPort.FontHeight;
  Viewport.TextOut( Pt.X,Pt.Y,Userstring(43)+' : '+ExtractFilename(FreeShip.FileName) );

  Viewport.FontColor:=clNavy;
  Pt:=Viewport.Project(Vector(FAftOrigin.X-FModelBeam/2,FPlanOrigin.Y+FModelBeam/2));
//Pt.y+=ViewPort.FontHeight; // div 2;
  Viewport.TextOut( Pt.X,Pt.Y,'Basic dimensions of a ship''s hull' );
  Pt.y-=(3*ViewPort.FontHeight) div 2;
  Viewport.TextOut( Pt.X,Pt.Y,Userstring(45)+' : '+
         ConvertDimension( FModelLength,Freeship.ProjectSettings.ProjectUnits) ); //+' '+Freeship.ProjectSettings.ProjectUnits );
  Pt.y-=ViewPort.FontHeight;
  Viewport.TextOut( Pt.X,Pt.Y,Userstring(44)+' : '+
         ConvertDimension( FreeShip.ProjectSettings.ProjectLength,Freeship.ProjectSettings.ProjectUnits) );
  Pt.y-=ViewPort.FontHeight;
  Viewport.TextOut( Pt.X,Pt.Y,Userstring(47)+' : '+
         ConvertDimension( FModelBeam,Freeship.ProjectSettings.ProjectUnits) );
  Pt.y-=ViewPort.FontHeight;
  Viewport.TextOut( Pt.X,Pt.Y,Userstring(46)+' : '+
         ConvertDimension( FreeShip.ProjectSettings.ProjectBeam,Freeship.ProjectSettings.ProjectUnits) );
  Pt.y-=ViewPort.FontHeight;
  Viewport.TextOut( Pt.X,Pt.Y,Userstring(48)+' : '+
         ConvertDimension( FreeShip.ProjectSettings.ProjectDraft,Freeship.ProjectSettings.ProjectUnits) );
  Pt.y-=ViewPort.FontHeight;
  Viewport.TextOut( Pt.X,Pt.Y,Userstring(49)+' : '+
         ConvertDimension( FreeShip.ProjectSettings.ProjectSplitSectionLocation,Freeship.ProjectSettings.ProjectUnits) );

  Screen.Cursor:=Prevcursor;
end;

procedure TFreeLinesplanFrame.ExportDXFExecute(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  Strings: TStringList;
  Str: AnsiString;
  Space, Tmp: TFloatType;
  SplitSectionLocation: TFloatType;
  Min, Max: TFloatType;
  I, J, K: integer;
  Edge: TFreeSubdivisionEdge;
  P1, P2: T3DVector;
  Diagonal: TFreeIntersection;
  Plane: T3DPlane;
  Spline: TFreeSpline;
  EdgePointLists: TFasterListTFasterListTFreeSubdivisionPoint;
  Points: TFasterListTFreeSubdivisionPoint;
  SplineValues: T3DVectorArray;

  procedure WriteDXFPoint(N: integer; P: T3DVector);
  begin
    Strings.Add(IntToStr(N)+EOL+FloatToDec(P.X, 6));
    Strings.Add(IntToStr(N+10)+EOL+FloatToDec(P.Y, 6));
  end;{WriteDXFPoint}

  procedure AddLine
  ( P1, P2: T3DVector;
    Views: TLinesplanViews;
    Layername: AnsiString;
    Color: TColor );
  var Startp, Endp: T3DVector;
  begin
    if lvProfile in views then begin
      StartP.X:=FProfileOrigin.X+P1.X;
      StartP.Y:=FProfileOrigin.Y+P1.Z;
      StartP.Z:=0.0;
      EndP.X:=FProfileOrigin.X+P2.X;
      EndP.Y:=FProfileOrigin.Y+P2.Z;
      EndP.Z:=0.0;
    end;
    if lvAftBody in views then begin
      StartP.X:=FAftOrigin.X-P1.Y;
      StartP.Y:=FAftOrigin.Y+P1.Z;
      StartP.Z:=0.0;
      EndP.X:=FAftOrigin.X-P2.Y;
      EndP.Y:=FAftOrigin.Y+P2.Z;
      EndP.Z:=0.0;
    end;
    if lvFrontBody in views then begin
      StartP.X:=FFrontOrigin.X-P1.Y;
      StartP.Y:=FFrontOrigin.Y+P1.Z;
      StartP.Z:=0.0;
      EndP.X:=FFrontOrigin.X-P2.Y;
      EndP.Y:=FFrontOrigin.Y+P2.Z;
      EndP.Z:=0.0;
    end;
    if lvPlan in views then begin
      StartP.X:=FPlanOrigin.X+P1.X;
      StartP.Y:=FPlanOrigin.Y+P1.Y;
      StartP.Z:=0.0;
      EndP.X:=FPlanOrigin.X+P2.X;
      EndP.Y:=FPlanOrigin.Y+P2.Y;
      EndP.Z:=0.0;
    end;
    Strings.Add('0'+EOL+'LINE');
    Strings.Add('8'+EOL+LayerName);
    Strings.Add('62'+EOL+IntToStr(FindDXFColorIndex(Color)));
    WriteDXFPoint(10, StartP);
    WriteDXFPoint(11, EndP);
  end;{AddLine}

  procedure AddSpline(Spline: TFreeSpline; Views: TLinesplanViews;
    Layername: AnsiString; Color: TColor);
  var
    Points: array of T3DVector;
    P: T3DVector;
    I,J, NParams,NValues, Pn,Pn1,Pn2: integer; Params: TFloatArray;
  begin
    NParams:=0;
    Setlength(Params, Spline.NumberOfPoints);  // count number of knucklepoints
    if not Spline.Built then Spline.Rebuild;
    for I:=2 to Spline.NumberOfPoints-1 do begin
      if Spline.Knuckle[I-1] then begin
        Params[NParams]:=Spline.Parameter[I-1];
        Inc(NParams);
      end;
    end;
    Spline.Fragments:=100;
    Setlength(Params, NParams+Spline.Fragments);
    for I:=1 to Spline.Fragments do begin
      Params[NParams]:=(I-1) / (Spline.Fragments-1);
      Inc(NParams);
    end;
    SortFloatArray(Params, NParams);

{   Setlength( Points,NParams+Spline.NumberOfPoints );
    J:=0; Pn:=0;
    for I:=0 to NParams-1 do begin
      P:=Spline.Value( Params[I],Pn1,Pn2 );
      if (Pn<>Pn1) and Spline.Knuckle[Pn1] then begin
        Points[J]:=Spline.Point[Pn1];
        Pn:=Pn1;
        inc(J);
      end; Points[J]:=P;
    end;   Setlength(Points, J+1);
}
    Points:=Spline.GetValues;
    NValues:=length(Points);

    Strings.Add('0'+EOL+'POLYLINE');
    Strings.Add('8'+EOL+LayerName);                                // layername
    Strings.Add('62'+EOL+IntToStr(FindDXFColorIndex(Color)));
    Strings.Add('66'+EOL+'1');                               // vertices follow
    for I:=0 to NValues-1 do begin P.Z:=0.0;
      if lvProfile in views then begin
        P.X:=FProfileOrigin.X+Points[I].X;
        P.Y:=FProfileOrigin.Y+Points[I].Z;
      end;
      if lvAftBody in views then begin
        P.X:=FAftOrigin.X-Points[I].Y;
        P.Y:=FAftOrigin.Y+Points[I].Z;
      end;
      if lvFrontBody in views then begin
        P.X:=FFrontOrigin.X-Points[I].Y;
        P.Y:=FFrontOrigin.Y+Points[I].Z;
      end;
      if lvPlan in views then begin
        P.X:=FPlanOrigin.X+Points[I].X;
        P.Y:=FPlanOrigin.Y+Points[I].Y;
      end;
      Strings.Add('0'+EOL+'VERTEX');
      Strings.Add('8'+EOL+LayerName);
      Strings.Add('10'+EOL+FloatToDec(P.X, 4));
      Strings.Add('20'+EOL+FloatToDec(P.Y, 4));
    end;
    Strings.Add('0'+EOL+'SEQEND');

    if (lvAftBody in views) or (lvFrontBody in views)
    or ((lvPlan in views) and (Freeship.NumberofDiagonals = 0)
    and (MirrorPlanView.Checked)) then begin                     // mirror line
      Strings.Add('0'+EOL+'POLYLINE');
      Strings.Add('8'+EOL+LayerName);                              // layername
      Strings.Add('62'+EOL+IntToStr(FindDXFColorIndex(Color)));
      Strings.Add('66'+EOL+'1');                             // vertices follow
      for I:=0 to NValues-1 do begin P.Z:=0.0;
        if lvAftBody in views then begin
          P.X:=FAftOrigin.X+Points[I].Y;
          P.Y:=FAftOrigin.Y+Points[I].Z;
        end;
        if lvFrontBody in views then begin
          P.X:=FFrontOrigin.X+Points[I].Y;
          P.Y:=FFrontOrigin.Y+Points[I].Z;
        end;
        if lvPlan in views then begin
          P.X:=FPlanOrigin.X+Points[I].X;
          P.Y:=FPlanOrigin.Y-Points[I].Y;
        end;
        Strings.Add('0'+EOL+'VERTEX');
        Strings.Add('8'+EOL+LayerName);
        Strings.Add('10'+EOL+FloatToDec(P.X, 4));
        Strings.Add('20'+EOL+FloatToDec(P.Y, 4));
      end;
      Strings.Add('0'+EOL+'SEQEND');
    end;
  end;{AddSpline}

  procedure AddEdgeLoop
  ( const Points: TFasterListTFreeSubdivisionPoint;
    Views: TLinesplanViews; Layername: AnsiString; Color: TColor );
  var
    Point: TFreeSubdivisionPoint;
    P: T3DVector;
    I: integer;
  begin
    Strings.Add('0'+EOL+'POLYLINE');
    Strings.Add('8'+EOL+LayerName);   // layername
    Strings.Add('62'+EOL+IntToStr(FindDXFColorIndex(Color)));
    Strings.Add('66'+EOL+'1');    // vertices follow
    for I:=1 to Points.Count do begin
      Point:=Points[I-1];
      P.Z:=0.0;
      if lvProfile in views then begin
        P.X:=FProfileOrigin.X+Point.Coordinate.X;
        P.Y:=FProfileOrigin.Y+Point.Coordinate.Z;
      end;
      if lvAftBody in views then begin
        P.X:=FAftOrigin.X-Point.Coordinate.Y;
        P.Y:=FAftOrigin.Y+Point.Coordinate.Z;
      end;
      if lvFrontBody in views then begin
        P.X:=FFrontOrigin.X-Point.Coordinate.Y;
        P.Y:=FFrontOrigin.Y+Point.Coordinate.Z;
      end;
      if lvPlan in views then begin
        P.X:=FPlanOrigin.X+Point.Coordinate.X;
        P.Y:=FPlanOrigin.Y+Point.Coordinate.Y;
      end;
      Strings.Add('0'+EOL+'VERTEX');
      Strings.Add('8'+EOL+LayerName);
      Strings.Add('10'+EOL+FloatToDec(P.X, 4));
      Strings.Add('20'+EOL+FloatToDec(P.Y, 4));
    end;
    Strings.Add('0'+EOL+'SEQEND');

    if (lvAftBody in views)
    or (lvFrontBody in views)
    or ((lvPlan in views)
    and (Freeship.NumberofDiagonals = 0)
    and (MirrorPlanView.Checked)) then begin // mirror line
      Strings.Add('0'+EOL+'POLYLINE');
      Strings.Add('8'+EOL+LayerName);   // layername
      Strings.Add('62'+EOL+IntToStr(FindDXFColorIndex(Color)));
      Strings.Add('66'+EOL+'1');    // vertices follow
      for I:=1 to Points.Count do begin
        Point:=Points[I-1];
        P.Z:=0.0;
        if lvAftBody in views then begin
          P.X:=FAftOrigin.X+Point.Coordinate.Y;
          P.Y:=FAftOrigin.Y+Point.Coordinate.Z;
        end;
        if lvFrontBody in views then begin
          P.X:=FFrontOrigin.X+Point.Coordinate.Y;
          P.Y:=FFrontOrigin.Y+Point.Coordinate.Z;
        end;
        if lvPlan in views then begin
          P.X:=FPlanOrigin.X+Point.Coordinate.X;
          P.Y:=FPlanOrigin.Y-Point.Coordinate.Y;
        end;

        Strings.Add('0'+EOL+'VERTEX');
        Strings.Add('8'+EOL+LayerName);
        Strings.Add('10'+EOL+FloatToDec(P.X, 4));
        Strings.Add('20'+EOL+FloatToDec(P.Y, 4));
      end;
      Strings.Add('0'+EOL+'SEQEND');
    end;
  end;{AddSpline}

  procedure AddIntersection(Intersection: TFreeIntersection;
    Views: TLinesplanViews; Layername: AnsiString; Color: TColor);
  var I: integer;
  begin
    if not Intersection.Built then Intersection.Rebuild;
    for I:=1 to Intersection.Count do
      AddSpline(Intersection.Items[I-1], Views, Layername, Color);
  end;
  {AddIntersection}
begin
  Str:=IncludeTrailingPathDelimiter(FFreeShip.Preferences.ExportDirectory);
  Str:=Str+ChangeFileExt(ExtractFilename(FFreeship.FileName), '')+'_Linesplan';
  SaveDialog:=TSaveDialog.Create(Owner);
  SaveDialog.InitialDir:=Freeship.Preferences.ExportDirectory;
  SaveDialog.FileName:=ChangeFileExt(Str, '');
  SaveDialog.Filter:=createDialogFilter(rsAutocadDxfFile,['dxf']);
  Savedialog.Options:=[ofOverwritePrompt, ofHideReadOnly];
  if SaveDialog.Execute then begin WestPoint;
    Freeship.Preferences.ExportDirectory:=ExtractFilePath(SaveDialog.FileName);
    SplitSectionLocation:=Freeship.ProjectSettings.ProjectSplitSectionLocation;

    EdgePointLists:=TFasterListTFasterListTFreeSubdivisionPoint.Create;
    Freeship.Surface.ExtractAllEdgeLoops(EdgePointLists);
    Strings:=TStringList.Create;
    Strings.Add('0'+EOL+'SECTION');
    Strings.Add('2'+EOL+'ENTITIES');                            // PROFILE VIEW
    Space:=CalculateSpace( 0.5*textspace,FMin3D.X,FMax3D.X );  // draw baseline
    AddLine( Vector(FMin3D.X-Space,FMin3D.Z),
             Vector(FMax3D.X+Space,FMin3D.Z),
             [lvProfile],'Base ',Freeship.Preferences.GridColor );  // draw dwl
    AddLine( Vector(FMin3D.X-Space,0,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
             Vector(FMax3D.X+Space, 0, FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
             [lvProfile],'DWL ', clRed);
    for I:=1 to FFreeship.NumberofWaterlines do begin
      Tmp:=-FFreeship.Waterline[I-1].Plane.D;
      AddLine(Vector(FMin3D.X-Space, 0, Tmp), Vector(FMax3D.X+Space, 0, Tmp),
        [lvProfile], 'wlgrid', Freeship.Preferences.GridColor);
    end;
    Space:=CalculateSpace(textspace, FMin3D.Z, FMax3D.Z);
    for I:=1 to FFreeship.NumberofStations do begin
      Tmp:=-FFreeship.Station[I-1].Plane.D;
      AddLine(Vector(Tmp, 0, FMin3D.Z-space), Vector(Tmp, 0, FMax3D.Z+space),
        [lvProfile], 'stationgrid', Freeship.Preferences.GridColor);
    end;
    // draw buttocks
    for I:=1 to Freeship.NumberofButtocks do
      AddIntersection(Freeship.Buttock[I-1], [lvProfile], 'buttocks',
        Freeship.Preferences.ButtockColor);
    // Add knuckle lines
    for I:=1 to EdgePointLists.Count do begin
      Points:=EdgePointLists[I-1];
      //Points:=TFasterListTFreeSubdivisionPoint.Create;
      //Points.Add(EdgePointLists[I-1].StartPoint);
      //Points.Add(EdgePointLists[I-1].EndPoint);
      AddEdgeLoop(Points, [lvProfile], 'Knuckle_lines',
        Freeship.Preferences.CreaseColor);
    end;

    // AFT VIEW OF BODYPLAN
    Space:=CalculateSpace(0.5 * textspace, -FMax3D.Y, FMax3D.Y);
    // draw baseline
    AddLine(Vector(0,-FMax3D.Y-Space), Vector(0,FMax3D.Y+Space),
      [lvAftBody],'Base ', Freeship.Preferences.GridColor);
    // draw dwl
    AddLine( Vector(0,-FMax3D.Y-Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
             Vector(0,FMax3D.Y+Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
             [lvAftBody],'DWL ',clRed );
    for I:=1 to FFreeship.NumberofWaterlines do begin
      Tmp:=-FFreeship.Waterline[I-1].Plane.D;
      AddLine( Vector(0.0,-FMax3D.Y-Space, Tmp),
               Vector(0.0,FMax3D.Y+Space,Tmp ),
               [lvAftBody], 'wlgrid', Freeship.Preferences.GridColor );
    end;
    Space:=CalculateSpace(textspace, FMin3D.Z, FMax3D.Z);    // draw centerline
    AddLine(Vector(0.0, 0.0, FMin3D.Z-space), Vector(0.0, 0.0, FMax3D.Z+space),
      [lvAftBody],'Center ', clRed);
    for I:=1 to FFreeship.NumberofButtocks do begin
      Tmp:=-FFreeship.Buttock[I-1].Plane.D;
      AddLine(Vector(0.0, Tmp, FMin3D.Z-space),
              Vector(0.0, Tmp, FMax3D.Z+space), [lvAftBody], 'buttockgrid', Freeship.Preferences.GridColor);
      AddLine(Vector(0.0, -Tmp, FMin3D.Z-space),
              Vector(0.0, -Tmp, FMax3D.Z+space), [lvAftBody], 'buttockgrid', Freeship.Preferences.GridColor);
    end;
    // draw stations
    for I:=1 to Freeship.NumberofStations do
      if -Freeship.Station[I-1].Plane.d <= SplitSectionLocation then
        AddIntersection(Freeship.Station[I-1], [lvAftBody], 'stations',
          Freeship.Preferences.StationColor);
    // Add knuckle lines
    for I:=1 to FreeShip.Surface.NumberOfSubDivEdges do begin
      Edge:=FreeShip.Surface.SubDivEdge[I-1];
      if (Edge.Crease) and (Edge.StartPoint.Coordinate.X <= SplitSectionLocation) and
        (Edge.EndPoint.Coordinate.X <= SplitSectionLocation) then begin
        P1:=Edge.StartPoint.Coordinate;
        P2:=Edge.EndPoint.Coordinate;
        AddLine(P1, P2, [lvAftBody], 'Knuckle_lines', Freeship.Preferences.CreaseColor);
        P1.Y:=-P1.Y;
        P2.Y:=-P2.Y;
        AddLine(P1, P2, [lvAftBody], 'Knuckle_lines', Freeship.Preferences.CreaseColor);
      end;
    end;

    Space:=CalculateSpace( 0.5*textspace,-FMax3D.Y,FMax3D.Y ); // FRONT VIEW OF BODYPLAN
    AddLine(Vector(0.0,-FMax3D.Y-Space),               // draw baseline
            Vector(0.0, FMax3D.Y+Space),
            [lvFrontBody],'Base ', Freeship.Preferences.GridColor); // draw dwl
    AddLine(Vector(0.0, -FMax3D.Y-Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft),
            Vector(0.0, FMax3D.Y+Space,FMin3D.Z+FFreeship.ProjectSettings.ProjectDraft), [lvFrontBody],'DWL ',clRed);
    for I:=1 to FFreeship.NumberofWaterlines do begin
      Tmp:=-FFreeship.Waterline[I-1].Plane.D;
      AddLine(Vector(0,-FMax3D.Y-Space,Tmp),
              Vector(0,FMax3D.Y+Space,Tmp),[lvFrontBody], 'wlgrid', Freeship.Preferences.GridColor);
    end;
    Space:=CalculateSpace(textspace, FMin3D.Z, FMax3D.Z);
    // draw centerline
    AddLine(Vector(0.0, 0.0, FMin3D.Z-space), Vector(0.0, 0.0, FMax3D.Z+space),
      [lvFrontBody],'Center ', clRed);
    for I:=1 to FFreeship.NumberofButtocks do begin
      Tmp:=-FFreeship.Buttock[I-1].Plane.D;
      AddLine(Vector(0.0, Tmp, FMin3D.Z-space), Vector(
        0.0, Tmp, FMax3D.Z+space), [lvFrontBody], 'buttockgrid', Freeship.Preferences.GridColor);
      AddLine(Vector(0.0, -Tmp, FMin3D.Z-space), Vector(
        0.0, -Tmp, FMax3D.Z+space), [lvFrontBody], 'buttockgrid', Freeship.Preferences.GridColor);
    end;
    // draw stations
    for I:=1 to Freeship.NumberofStations do
      if -Freeship.Station[I-1].Plane.d >= SplitSectionLocation then
        AddIntersection(Freeship.Station[I-1], [lvFrontBody], 'stations',
          Freeship.Preferences.StationColor);
    // Add knuckle lines
    for I:=1 to FreeShip.Surface.NumberOfSubDivEdges do begin
      Edge:=FreeShip.Surface.SubDivEdge[I-1];
      if (Edge.Crease) and (Edge.StartPoint.Coordinate.X >= SplitSectionLocation)
      and (Edge.EndPoint.Coordinate.X >= SplitSectionLocation) then begin
        P1:=Edge.StartPoint.Coordinate;
        P2:=Edge.EndPoint.Coordinate;
        AddLine( P1,P2,[lvFrontBody], 'Knuckle_lines',Freeship.Preferences.CreaseColor );
        P1.Y:=-P1.Y;
        P2.Y:=-P2.Y;
        AddLine(P1, P2, [lvFrontBody], 'Knuckle_lines',
          Freeship.Preferences.CreaseColor);
      end;
    end;
    // PLAN VIEW
    Space:=CalculateSpace(0.5 * textspace, FMin3D.X, FMax3D.X);
    // draw centerline
    AddLine(Vector(FMin3D.X-Space, 0.0, 0.0), Vector(FMax3D.X+Space, 0.0, 0.0),
      [lvPlan],'Center ', clRed);
    for I:=1 to FFreeship.NumberofButtocks do begin
      Tmp:=-FFreeship.Buttock[I-1].Plane.D;
      AddLine(Vector(FMin3D.X-Space, Tmp, 0.0), Vector(
        FMax3D.X+space, Tmp, 0.0), [lvPlan], 'buttockgrid', Freeship.Preferences.GridColor);
      if (Freeship.NumberofDiagonals = 0) and (MirrorPlanView.Checked) then
        AddLine(Vector(FMin3D.X-space, -Tmp, 0.0), Vector(FMax3D.X+space, -Tmp, 0.0),
          [lvPlan], 'buttockgrid', Freeship.Preferences.GridColor);
    end;
    // stations
    Space:=CalculateSpace(textspace, FMin3D.Y, FMax3D.Y);
    for I:=1 to FFreeship.NumberofStations do begin
      Tmp:=-FFreeship.Station[I-1].Plane.D;
      if (Freeship.NumberofDiagonals = 0) and (MirrorPlanview.Checked) then
        AddLine(Vector(Tmp, -FMax3D.Y-space, 0), Vector(Tmp, FMax3D.Y+space, 0),
          [lvPlan], 'stationgrid', Freeship.Preferences.GridColor)
      else
        AddLine(Vector(Tmp, -FDiagonalWidth-space, 0), Vector(Tmp, FMax3D.Y+space, 0),
          [lvPlan], 'stationgrid', Freeship.Preferences.GridColor);
    end;
    // draw waterlines
    for I:=1 to Freeship.NumberofWaterlines do
      AddIntersection(Freeship.Waterline[I-1], [lvPLan], 'waterlines',
        Freeship.Preferences.WaterlineColor);

    // draw diagonals
    for I:=1 to Freeship.NumberofDiagonals do begin
      Diagonal:=Freeship.Diagonal[I-1];
      Plane.a:=0.0;
      Plane.b:=1 / Sqrt(2);
      Plane.c:=-1 / sqrt(2);
      Plane.d:=-Diagonal.Plane.d;
      if not Diagonal.Built then
        Diagonal.Rebuild;
      for J:=1 to Diagonal.Count do begin
        Spline:=Diagonal.Items[J-1];
        Min:=0;
        Max:=0;
        Strings.Add('0'+EOL+'POLYLINE');
        Strings.Add('8'+EOL+'Diagonals');   // layername
        Strings.Add('62'+EOL+IntToStr(FindDXFColorIndex(
          Freeship.Preferences.DiagonalColor)));
        Strings.Add('66'+EOL+'1');    // vertices follow

        Spline.Fragments:=100;
        SplineValues:=Spline.GetValues;
        for k:=0 to length(SplineValues)-1 do begin
          //P1:=Spline.Value(K / 100, Pn1, Pn2);
          P1:=SplineValues[k];
          Tmp:=abs(Plane.A * P1.x+Plane.B * P1.y+Plane.C * P1.z+Plane.D);
          if K = 0 then begin Min:=Tmp; Max:=Tmp; end else begin
            if Tmp < min then Min:=Tmp;
            if Tmp > max then Max:=Tmp;
          end;
          P2.X:=FPlanOrigin.X+P1.X;
          P2.Y:=FPlanOrigin.Y-abs(Tmp);
          P2.Z:=0.0;
          Strings.Add('0'+EOL+'VERTEX');
          Strings.Add('8'+EOL+'Diagonals');
          Strings.Add('10'+EOL+FloatToDec(P2.X, 4));
          Strings.Add('20'+EOL+FloatToDec(P2.Y, 4));
        end;
        Strings.Add('0'+EOL+'SEQEND');
        // draw as grid in bodyplan views
        // calculate height of intersection of diagonal with centerplane
        Tmp:=-Diagonal.Plane.d / Diagonal.Plane.c;
        P1:=Vector(0.0, Min * Sin(DegToRad(45)), Tmp-Min * Sin(DegToRad(45)));
        P2:=Vector(0.0, Max * Sin(DegToRad(45)), Tmp-Max * Sin(DegToRad(45)));
        AddLine(P1, P2, [lvAftBody], 'diagonalgrid', freeship.Preferences.GridColor);
        AddLine(P1, P2, [lvFrontBody], 'diagonalgrid', freeship.Preferences.GridColor);
        P1.Y:=-P1.Y;
        P2.Y:=-P2.Y;
        AddLine(P1, P2, [lvAftBody], 'diagonalgrid', freeship.Preferences.GridColor);
        AddLine(P1, P2, [lvFrontBody], 'diagonalgrid', freeship.Preferences.GridColor);
      end;
    end;                                                   // Add knuckle lines
    for I:=1 to EdgePointLists.Count do begin
      Points:=EdgePointLists[I-1];
      AddEdgeLoop(Points,[lvPlan],'Knuckle_lines',Freeship.Preferences.CreaseColor);
    end;
    Strings.Add('0'+EOL+'ENDSEC');
    Strings.Add('0'+EOL+'EOF');
    Strings.SaveToFile(ChangeFileExt(SaveDialog.FileName, '.dxf'));
    FreeAndNil(Strings);                         // Destroy extracted edgeloops
    for I:=1 to EdgePointLists.Count do begin
      Points:=EdgePointLists[I-1];
      FreeAndNil(Points);
    end;
    FreeAndNil(EdgePointLists);
  end;
  FreeAndNil(SaveDialog);
end;

end.
