Unit DialogFolders;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, VehicleFolders;

Type

  { TdlgVehicleFolders }

  TdlgVehicleFolders = Class(TForm)
    btnAdd: TToolButton;
    btnCancel: TButton;
    btnDelete: TToolButton;
    btnEdit: TToolButton;
    btnOK: TButton;
    ImageList1: TImageList;
    lvVehicles: TListView;
    pnlButtons: TPanel;
    tbMain: TToolBar;
    btnSep: TToolButton;
    Procedure btnAddClick(Sender: TObject);
    Procedure btnEditClick(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure lvVehiclesDblClick(Sender: TObject);
    Procedure lvVehiclesSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  Private
    FVehicleFolders: TVehicleFolders;
    Procedure LoadListView;
    Procedure RefreshUI;
  Public
    Function GetVehicleFolders: TVehicleFolders;
    Procedure SetVehicleFolders(AValue: TVehicleFolders);
  End;

Implementation

Uses
  DialogFolder;

  {$R *.lfm}

  { TdlgVehicleFolders }

Procedure TdlgVehicleFolders.FormCreate(Sender: TObject);
Begin
  FVehicleFolders := TVehicleFolders.Create(True);
End;

Procedure TdlgVehicleFolders.btnAddClick(Sender: TObject);
Var
  dlgFolder: TdlgVehicleFolder;
  oVehicleFolder: TVehicleFolder;
Begin
  dlgFolder := TdlgVehicleFolder.Create(Self);
  Try
    If dlgFolder.ShowModal = mrOk Then
    Begin
      oVehicleFolder := TVehicleFolder.Create;
      oVehicleFolder.Assign(dlgFolder.GetVehicleFolder);

      FVehicleFolders.Add(oVehicleFolder);

      LoadListView;
    End;
  Finally
    FreeAndNil(dlgFolder);
  End;
End;

Procedure TdlgVehicleFolders.btnEditClick(Sender: TObject);
Var
  dlgFolder: TdlgVehicleFolder;
  oVehicleFolder: TVehicleFolder;
Begin
  If Assigned(lvVehicles.Selected) Then
  Begin
    oVehicleFolder := FVehicleFolders[lvVehicles.Selected.Index];

    dlgFolder := TdlgVehicleFolder.Create(Self);
    Try
      dlgFolder.SetVehicleFolder(oVehicleFolder);

      If dlgFolder.ShowModal = mrOk Then
      Begin
        oVehicleFolder.Assign(dlgFolder.GetVehicleFolder);
        LoadListView;
      End;
    Finally
      FreeAndNil(dlgFolder);
    End;
  End;
End;

Procedure TdlgVehicleFolders.FormDestroy(Sender: TObject);
Begin
  FreeAndNil(FVehicleFolders);
End;

Procedure TdlgVehicleFolders.lvVehiclesDblClick(Sender: TObject);
Begin
  If btnEdit.Enabled Then
    btnEdit.Click;
End;

Procedure TdlgVehicleFolders.lvVehiclesSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
Begin
  RefreshUI;
End;

Function TdlgVehicleFolders.GetVehicleFolders: TVehicleFolders;
Begin
  Result := FVehicleFolders;
End;

Procedure TdlgVehicleFolders.SetVehicleFolders(AValue: TVehicleFolders);
Begin
  FVehicleFolders.Assign(AValue);
  LoadListView;
End;

Procedure TdlgVehicleFolders.RefreshUI;
Begin
  btnAdd.Enabled := True;
  btnEdit.Enabled := (lvVehicles.SelCount>0) Or Assigned(lvVehicles.Selected);
  btnDelete.Enabled := (lvVehicles.SelCount>0) Or Assigned(lvVehicles.Selected);
End;

Procedure TdlgVehicleFolders.LoadListView;
Var
  oVehicle: TVehicleFolder;
  oItem: TListItem;
  iLast: Integer;

  Procedure Select(AIndex: Integer);
  Begin
    If (AIndex < 0) Or (AIndex >= lvVehicles.Items.Count) Then
      Exit;

    lvVehicles.ItemFocused := lvVehicles.Items[AIndex];
    lvVehicles.Items[AIndex].Selected := True;
    lvVehicles.Selected := lvVehicles.Items[AIndex];
    lvVehicles.Items[AIndex].MakeVisible(False);
  End;

Begin
  If Assigned(lvVehicles.Selected) Then
    iLast := lvVehicles.Selected.Index
  Else
    iLast := -1;

  lvVehicles.Items.BeginUpdate;
  lvVehicles.BeginUpdate;
  Try
    lvVehicles.Items.Clear;

    For oVehicle In FVehicleFolders Do
    Begin
      oItem := lvVehicles.Items.Add;

      oItem.Caption := oVehicle.VesselName;
      oItem.SubItems.Add(oVehicle.VesselCode);
      oItem.SubItems.Add(oVehicle.VehicleName);
      oItem.SubItems.Add(oVehicle.VehicleClass);
      oItem.SubItems.Add(oVehicle.Exclude.DelimitedText);
      oItem.SubItems.Add(oVehicle.Folder);
    End;

  Finally
    lvVehicles.Items.EndUpdate;
    lvVehicles.EndUpdate;
  End;

  If (iLast >= 0) And (iLast < lvVehicles.Items.Count) Then
    Select(iLast)
  Else If lvVehicles.Items.Count > 0 Then
    Select(0);

  RefreshUI;
End;

End.
