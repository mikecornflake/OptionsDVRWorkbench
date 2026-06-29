Unit OIS.Context;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, IniFiles, OIS.Repository, OIS.Model;

Type

  { TOISContext }

  TOISContext = Class
  Private
    FRepository: TOISRepository;
    FWorkpack: TOISWorkpack;
    FVessel: TOISVessel;
    FVehicles: TOISVehicles;
  Public
    Constructor Create(ARepository: TOISRepository);
    Destructor Destroy; Override;

    Procedure LoadSettings(AInifile: TInifile; ASection: String);
    Procedure SaveSettings(AInifile: TInifile; ASection: String);

    Property Workpack: TOISWorkpack Read FWorkpack;
    Property Vessel: TOISVessel Read FVessel;
    Property Vehicles: TOISVehicles Read FVehicles;
  End;

Implementation

{ TOISContext }

Constructor TOISContext.Create(ARepository: TOISRepository);
Begin
  FRepository := ARepository;
  FWorkpack := nil;
  FVessel := nil;
End;

Destructor TOISContext.Destroy;
Begin
  FreeAndNil(FWorkpack);
  FreeAndNil(FVessel);
  FreeAndNil(FVehicles);

  Inherited Destroy;
End;

Procedure TOISContext.LoadSettings(AInifile: TInifile; ASection: String);
Var
  iWorkpackID, iVesselID: TOISID;
Begin
  FreeAndNil(FWorkpack);
  FreeAndNil(FVessel);
  FreeAndNil(FVehicles);

  iWorkpackID := AIniFile.ReadInt64(ASection, 'Workpack_ID', -1);
  If iWorkpackID <> -1 Then
    FWorkpack := FRepository.GetWorkpack(iWorkpackID);

  iVesselID := AIniFile.ReadInt64(ASection, 'Vessel_ID', -1);
  If iVesselID <> -1 Then
    FVessel := FRepository.GetVessel(iVesselID);

  If Assigned(FVessel) Then
    FVehicles := FRepository.GetVehiclesForVessel(FVessel);
End;

Procedure TOISContext.SaveSettings(AInifile: TInifile; ASection: String);
Begin
  If Assigned(FVessel) Then
    AInifile.WriteInt64(ASection, 'Vessel_ID', FVessel.Vessel_ID);

  If Assigned(FWorkpack) Then
    AInifile.WriteInt64(ASection, 'Workpack_ID', FWorkpack.Workpack_ID);
End;

End.
