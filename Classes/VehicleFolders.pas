Unit VehicleFolders;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, fgl;

Type
  TVehicleFolders = Class;

  { TVehicleFolder }

  TVehicleFolder = Class
  Private
    FExclude: TStringList;
  Public
    Folder: String;
    VesselCode: String;
    VesselName: String;
    VehicleName: String;
    VehicleClass: String;

    Constructor Create;
    Destructor Destroy; Override;

    Procedure Assign(ASource: TVehicleFolder);

    Property Exclude: TStringList Read FExclude;
  End;

  { TVehicleFolders }

  TVehicleFolders = Class(Specialize TFPGObjectList<TVehicleFolder>)
  Public
    Procedure Assign(ASource: TVehicleFolders);
  End;

Implementation

{ TVehicleFolder }

Constructor TVehicleFolder.Create;
Begin
  FExclude := TStringList.Create;
  FExclude.CaseSensitive := False;
  FExclude.Sorted := True;
  FExclude.Duplicates := dupIgnore;
  FExclude.Delimiter := ',';
End;

Destructor TVehicleFolder.Destroy;
Begin
  FreeAndNil(FExclude);

  Inherited Destroy;
End;

Procedure TVehicleFolder.Assign(ASource: TVehicleFolder);
Begin
  If ASource = Self Then
    Exit;

  Folder := ASource.Folder;
  VesselCode := ASource.VesselCode;
  VesselName := ASource.VesselName;
  VehicleName := ASource.VehicleName;
  VehicleClass := ASource.VehicleClass;

  FExclude.Assign(ASource.Exclude);
End;

{ TVehicleFolders }

Procedure TVehicleFolders.Assign(ASource: TVehicleFolders);
Var
  oSourceVehicle, oVehicle: TVehicleFolder;
Begin
  Clear;

  For oSourceVehicle In ASource Do
  Begin
    oVehicle := TVehicleFolder.Create;
    oVehicle.Assign(oSourceVehicle);

    Add(oVehicle);
  End;
End;

End.
