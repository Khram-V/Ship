unit FreePointGroupForm;
{$mode objfpc}{$H+}
interface uses
  Controls, Forms,
  StdCtrls, Buttons, SysUtils,
  CheckLst, Menus, FreeShipUnit, FreeGeometry;
type
  TFreePointGroupForm = class( TForm )
    BitBtnOk,BitBtnCancel: TBitBtn;
    CheckListBoxGroups: TCheckListBox;
    EditNewGroupName,ChangeGroupName: TEdit;
    MenuItemRenameGroup,MenuItemDeleteGroup: TMenuItem;
    PopupMenu1: TPopupMenu;
    SpeedButtonAdd: TSpeedButton;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure MenuItemDeleteGroupClick(Sender: TObject);
    procedure MenuItemRenameGroupClick(Sender: TObject);
    procedure SpeedButtonAddClick(Sender: TObject);
    procedure ChangeOldGroupName(Sender: TObject);
  public
    procedure LoadGroups;
  end;

implementation
{$R *.lfm}
procedure TFreePointGroupForm.LoadGroups; var I:integer;
begin // with Ship.Surface. do begin
  if Ship.Surface.NumberOfSelectedControlPoints=0 then begin
    SpeedButtonAdd.Enabled:=false;
    EditNewGroupName.Enabled:=false;
    EditNewGroupName.Text:='(без выбора)';
  end else begin
    SpeedButtonAdd.Enabled:=True;
    EditNewGroupName.Enabled:=True;
    EditNewGroupName.Text:=
    'Группа узлов № '+IntToStr(Ship.Surface.NumberOfControlPointGroups+1)
              +' из '+IntToStr(Ship.Surface.NumberOfSelectedControlPoints)+' узлов';
  end;
  for I:=0 to Ship.Surface.NumberOfControlPointGroups-1 do
   CheckListBoxGroups.AddItem( Ship.Surface.ControlPointGroup[i].Names,
                               Ship.Surface.ControlPointGroup[i] );
//CheckListBoxGroups.Sorted:=true;
//end;
end;
procedure TFreePointGroupForm.SpeedButtonAddClick(Sender: TObject);
var G:TFreeSubdivisionControlPointGroup;
begin
  G:=TFreeSubdivisionControlPointGroup.create( Ship.Surface );
  G.Names:=(EditNewGroupName.Text);
  CheckListBoxGroups.AddItem( G.Names,G );
  CheckListBoxGroups.Checked[CheckListBoxGroups.Items.Count-1]:=True;
//CheckListBoxGroups.Sorted:=true;
end;
procedure TFreePointGroupForm.FormClose
  ( Sender: TObject; var CloseAction: TCloseAction );
var i,j:integer; found:boolean; G:TFreeSubdivisionControlPointGroup;
begin
  if self.ModalResult = mrOk then begin
    for i:=0 to CheckListBoxGroups.Items.Count-1 do begin
      if CheckListBoxGroups.Checked[i] then begin
        G:=CheckListBoxGroups.Items.Objects[i] as TFreeSubdivisionControlPointGroup;
        for j:=0 to Ship.NumberOfSelectedControlPoints-1 do
          G.AddControlPoint( Ship.SelectedControlPoint[j] );
        if Ship.Surface.ControlPointGroups.IndexOf( G )<0 then
           Ship.Surface.ControlPointGroups.Add( G );
        G.Names:=CheckListBoxGroups.Items[I];
      end;
    end;
    for i:=Ship.Surface.ControlPointGroups.Count-1 downto 0 do begin found:=false;
      for j:=0 to CheckListBoxGroups.Items.Count-1 do
      if CheckListBoxGroups.Items.Objects[j]=Ship.Surface.ControlPointGroups[i]
         then found:=true;
      if not found then Ship.Surface.ControlPointGroups[i].Delete;
    end;
  end;
end;
procedure TFreePointGroupForm.MenuItemDeleteGroupClick( Sender: TObject );
    begin CheckListBoxGroups.DeleteSelected; end;
procedure TFreePointGroupForm.MenuItemRenameGroupClick( Sender: TObject );
begin
  EditNewGroupName.Visible:=false;
  ChangeGroupName.Visible:=true;
  ChangeGroupName.Text:=CheckListBoxGroups.Items[CheckListBoxGroups.ItemIndex];
end;
procedure TFreePointGroupForm.ChangeOldGroupName( Sender: TObject );
Var G: TFreeSubdivisionControlPointGroup;
begin                                                         // Sorted = True
  G:=CheckListBoxGroups.Items.Objects[CheckListBoxGroups.ItemIndex] as TFreeSubdivisionControlPointGroup;
  G.Names:=ChangeGroupName.Text;
  CheckListBoxGroups.Items[CheckListBoxGroups.ItemIndex]:=ChangeGroupName.Text;
  ChangeGroupName.Visible:=false;
  EditNewGroupName.Visible:=true;                 // Не срабатывает, странно ??
end;
(*
object ChangeGroupName: TEdit
  Left = 53
  Height = 23
  Top = 10
  Width = 227
  TabOrder = 0
  OnEditingDone = ChangeOldGroupName
  Text = 'Новое имя'
  Visible = false
end
*)
end.

