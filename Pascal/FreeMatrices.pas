unit FreeMatrices;
interface uses Classes,SysUtils;//,FreeTypes;
//const Singulier=True;
//      Regulier=false;
//      MatrixError = 1e-5;
type TFreeMatrix = class( TObject )
private
   RowCount,ColCount: integer;
   function  Copy:TFreeMatrix;
   procedure CreateIdentity;
   procedure Assign(Matrix: TFreeMatrix);
public
   Value: Array of Array of single;
   constructor Create;
   destructor Destroy; override;
   procedure SetSize(Cols,Rows:Integer);
   procedure Add(Matrix: TFreeMatrix);
   procedure Fill( V: single );
   procedure Clear;
   function  Invert: TFreeMatrix;
   function  Multiply( Matrix: TFreeMatrix ): TFreeMatrix;
end;

implementation

constructor TFreeMatrix.Create; begin inherited Create; Clear; end;
destructor TFreeMatrix.Destroy;
     begin Clear; inherited Destroy; end;
function TFreeMatrix.Copy:TFreeMatrix;
   begin Result:=TFreeMatrix.Create; Result.Assign( Self ); end;
procedure TFreeMatrix.Clear; begin SetSize( 0,0 ); end;
procedure TFreeMatrix.CreateIdentity; var I: integer;
    begin for I:=0 to RowCount-1 do Value[I,I]:=1.0;
    end;

procedure TFreeMatrix.SetSize( Cols,Rows:Integer );
var I: integer;
begin if RowCount>0 then                                    // сначала вычистка
      begin for I:=0 to RowCount-1 do Setlength( Value[I],0 );
                                      SetLength( Value,0 );
      end;
      SetLength( Value,Rows ); RowCount:=Rows; ColCount:=Cols;
      if Rows>0 then for I:=0 to Rows-1 do Setlength( Value[I],Cols );
      Fill( 0.0 );                                    // set all values to zero
end;
procedure TFreeMatrix.Fill( V: single ); var I,J: Integer;
    begin for I:=0 to RowCount-1 do
          for J:=0 to ColCount-1 do Value[I][J]:=V;
    end;
procedure TFreeMatrix.Assign( Matrix: TFreeMatrix ); var I,J: Integer;
    begin for I:=0 to RowCount-1 do
          for J:=0 to ColCount-1 do Value[I][J]:=Matrix.Value[I][J];
    end;
procedure TFreeMatrix.Add( Matrix: TFreeMatrix ); var I,J: integer;
    begin for I:=0 to RowCount-1 do
          for J:=0 to ColCount-1 do Value[I][J]+=Matrix.Value[I][J];
    end;

function TFreeMatrix.Invert:TFreeMatrix;
var I,J,K,L,N,IMax: integer;
    Factor,Det,Amax,H: Real;
//  State: Boolean;
    Inverted{,Back}:TFreeMatrix;// матрица будет с переустановленными столбцами
begin
   Result:=nil;
// if Square then begin
//    if ColCount=RowCount then begin
//       Back:=Copy;
         Inverted:=TFreeMatrix.Create;
         Inverted.SetSize(ColCount,RowCount);
         Inverted.CreateIdentity;
//       State:=Regulier;
         N:=ColCount;
         I:=0;
         Det:=1.0;
         repeat
            Inc(I);
            IMax:=I;
            AMax:=abs(Value[I-1,I-1]);
            if I<>N then for K:=I+1 to N do
            if Abs(Value[K-1,I-1])>AMax then begin
               IMax:=K;
               AMax:=abs(Value[K-1,I-1]);
            end;
//          if AMax<MatrixError then State:=Singulier;
//          if State=Regulier then begin
               if I<>Imax then begin Det:=-Det;       // Swap rows if necessary
                  for L:=I to N do begin
                     H:=Value[I-1,L-1];
                     Value[I-1,L-1]:=Value[IMax-1,L-1];
                     Value[IMax-1,L-1]:=H;
                  end;
                  for L:=1 to N do begin
                     H:=Inverted.Value[I-1,L-1];
                     Inverted.Value[I-1,L-1]:=Inverted.Value[IMax-1,L-1];
                     Inverted.Value[IMax-1,L-1]:=H;
                  end;
               end;                                       // Sweep column clear
               if I<>N then
               for K:=I+1 to N do {if abs(Value[K-1,I-1])>MatrixError then } begin
                   Factor:=Value[k-1,I-1]/Value[I-1,I-1];
                   if Factor<>0 then begin
                      for L:=I to N do Value[K-1,L-1]-=Factor*Value[I-1,L-1];
                      for L:=1 to N do Inverted.Value[K-1,L-1]-=Factor*Inverted.Value[I-1,L-1];
                   end;
               end;
               if I<>1 then
               for K:=I-1 downto 1 do
//             if abs(Value[K-1,I-1])>MatrixError then
               begin
                  Factor:=Value[K-1,I-1]/Value[I-1,I-1];
                  if Factor<>0 then begin
                     for L:=I to N do Value[K-1,L-1]-=Factor*Value[I-1,L-1];
                     for L:=1 to N do Inverted.Value[K-1,L-1]-=Factor*Inverted.Value[I-1,L-1];
                  end;
               end;
//          end;
         until (I=N); // or (State=Singulier);
//       if abs(Value[N-1,N-1])<MatrixError then State:=Singulier;
//       if State=Regulier then begin
            for I:=1 to N do begin
               Det*=Value[I-1,I-1];
               Factor:=Value[I-1,I-1];
               Value[I-1,I-1]:=1.0;
               for J:=1 to N do Inverted.Value[I-1,J-1]/=Factor;
            end;
            Result:=Inverted;
//       end else begin Inverted.Destroy; //WriteLn('Matrix could not be solved.');
//       end;
//       Assign(Back);
//       Back.Destroy;
//     end; // else WriteLn('Matrix size must match to be solved');
//   end; // else WriteLn('Matrix must be square to invert');
end;

function TFreeMatrix.Multiply(Matrix:TFreeMatrix):TFreeMatrix; Var I,J,K:integer;
begin         //if ColCount<>Matrix.RowCount then WriteLn('Matrix size do not match in multiply');
     Result:=TFreeMatrix.Create;
     Result.SetSize(Matrix.ColCount,RowCount);
     for I:=0 to Result.RowCount-1 do
     for J:=0 to Result.ColCount-1 do
     for K:=0 to ColCount-1 do Result.Value[I,J]+=Value[I,K]*Matrix.Value[K,J];
end;

end.
