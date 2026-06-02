Unit VehicleFolders;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, fgl;

Type

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

    Property Exclude: TStringList Read FExclude Write FExclude;
  End;

  TVehicleFolders = Class(Specialize TFPGObjectList<TVehicleFolder>);

Implementation

{ TVehicleFolder }

Constructor TVehicleFolder.Create;
Begin
  FExclude := TStringList.Create;
  FExclude.CaseSensitive := False;
End;

Destructor TVehicleFolder.Destroy;
Begin
  FreeAndNil(FExclude);

  Inherited Destroy;
End;

End.
