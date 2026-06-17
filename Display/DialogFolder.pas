Unit DialogFolder;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus, EditBtn, VehicleFolders;

Type

  { TdlgVehicleFolder }

  TdlgVehicleFolder = Class(TForm)
    btnOK: TButton;
    btnCancel: TButton;
    cboVehicleClass: TComboBox;
    edtFolder: TDirectoryEdit;
    edtVesselCode: TEdit;
    edtVesselName: TEdit;
    edtVehicleName: TEdit;
    lblVesselCode: TLabel;
    lblVesselName: TLabel;
    lblVehicleName: TLabel;
    lblVehicleClass: TLabel;
    lblFolder: TLabel;
    lblExclude: TLabel;
    memNotes: TMemo;
    memExclude: TMemo;
    pnlButtons: TPanel;
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
  Private
    FVehicleFolder: TVehicleFolder;
  Public
    Function GetVehicleFolder: TVehicleFolder;
    Procedure SetVehicleFolder(AValue: TVehicleFolder);
  End;

Var
  dlgVehicleFolder: TdlgVehicleFolder;

Implementation

{$R *.lfm}

{ TdlgVehicleFolder }

Procedure TdlgVehicleFolder.FormCreate(Sender: TObject);
Begin
  FVehicleFolder := TVehicleFolder.Create;
End;

Procedure TdlgVehicleFolder.FormDestroy(Sender: TObject);
Begin
  FVehicleFolder.Free;
End;

Function TdlgVehicleFolder.GetVehicleFolder: TVehicleFolder;
Begin
  FVehicleFolder.VesselCode := Trim(edtVesselCode.Text);
  FVehicleFolder.VesselName := Trim(edtVesselName.Text);
  FVehicleFolder.VehicleName := Trim(edtVehicleName.Text);
  FVehicleFolder.VehicleClass := Trim(cboVehicleClass.Text);
  FVehicleFolder.Folder := Trim(edtFolder.Text);
  FVehicleFolder.Exclude.Assign(memExclude.Lines);

  Result := FVehicleFolder;
End;

Procedure TdlgVehicleFolder.SetVehicleFolder(AValue: TVehicleFolder);
Begin
  FVehicleFolder.Assign(AValue);

  edtVesselCode.Text := FVehicleFolder.VesselCode;
  edtVesselName.Text := FVehicleFolder.VesselName;
  edtVehicleName.Text := FVehicleFolder.VehicleName;
  cboVehicleClass.Text := FVehicleFolder.VehicleClass;
  edtFolder.Text := FVehicleFolder.Folder;
  memExclude.Lines.Assign(FVehicleFolder.Exclude);
End;

End.
