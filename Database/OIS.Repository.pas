Unit OIS.Repository;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, SQLDB,
  OIS.Database, OIS.Model, OIS.Support;

Type

  { TOISRepository }

  TOISRepository = Class
  Private
    FDatabase: TOISDatabase;

    Function NewQuery(Const ASQL: String): TSQLQuery;
    Function ExecInsert(Q: TSQLQuery): TOISID;
    Function SelectID(Const ASQL: String; Const AID: TOISID): TSQLQuery;

    Procedure SetIDParam(Q: TSQLQuery; Const AName: String; Const AValue: TOISID);
    Procedure SetDateTimeParam(Q: TSQLQuery; Const AName: String; Const AValue: TDateTime);

    Procedure LoadVehicle(Q: TSQLQuery; AVehicle: TOISVehicle);
  Public
    Constructor Create(ADatabase: TOISDatabase);

    Function AddFolder(AFolder: TOISFolder): TOISID;
    Function GetFolder(AID: TOISID): TOISFolder;

    Function AddMediaType(AMediaType: TOISMediaType): TOISID;
    Function GetMediaType(AID: TOISID): TOISMediaType;

    Function AddVehicleClass(AVehicleClas: TOISVehicleClass): TOISID;
    Function GetVehicleClass(AID: TOISID): TOISVehicleClass;

    Function AddVessel(AVessel: TOISVessel): TOISID;
    Function GetVessel(AID: TOISID): TOISVessel;

    Function AddWorkpack(AWorkpack: TOISWorkpack): TOISID;
    Function GetWorkpack(AID: TOISID): TOISWorkpack;

    Function AddComponent(AComponent: TOISComponent): TOISID;
    Function GetComponent(AID: TOISID): TOISComponent;

    Function AddVehicle(AVehicle: TOISVehicle): TOISID;
    Function GetVehicle(AID: TOISID): TOISVehicle;
    Function GetVehiclesForVessel(AVessel: TOISVessel): TOISVehicles;

    Function AddMedia(AMedia: TOISMedia): TOISID;
    Function GetMedia(AID: TOISID): TOISMedia;

    Function AddChannel(AChannel: TOISChannel): TOISID;
    Function GetChannel(AID: TOISID): TOISChannel;

    Function AddChannelData(AChannelData: TOISChannelData): TOISID;
    Function GetChannelData(AID: TOISID): TOISChannelData;
  End;

Implementation

Constructor TOISRepository.Create(ADatabase: TOISDatabase);
Begin
  Inherited Create;
  FDatabase := ADatabase;
End;

Function TOISRepository.NewQuery(Const ASQL: String): TSQLQuery;
Begin
  Result := TSQLQuery.Create(nil);
  Result.Database := FDatabase.Connection;
  Result.Transaction := FDatabase.Transaction;
  Result.SQL.Text := ASQL;
End;

Function TOISRepository.ExecInsert(Q: TSQLQuery): TOISID;
Var
  QID: TSQLQuery;
Begin
  Q.ExecSQL;

  QID := NewQuery('SELECT last_insert_rowid() AS NewID');
  Try
    QID.Open;
    Result := QID.FieldByName('NewID').AsLargeInt;
  Finally
    QID.Free;
  End;
End;

Function TOISRepository.SelectID(Const ASQL: String; Const AID: TOISID): TSQLQuery;
Begin
  Result := NewQuery(ASQL);
  Result.ParamByName('ID').AsLargeInt := AID;
  Result.Open;

  If Result.EOF Then
  Begin
    Result.Free;
    Result := nil;
  End;
End;

Procedure TOISRepository.SetIDParam(Q: TSQLQuery; Const AName: String; Const AValue: TOISID);
Begin
  If AValue = 0 Then
    Q.ParamByName(AName).Clear
  Else
    Q.ParamByName(AName).AsLargeInt := AValue;
End;

Procedure TOISRepository.SetDateTimeParam(Q: TSQLQuery; Const AName: String;
  Const AValue: TDateTime);
Begin
  If OISDateTimeIsNull(AValue) Then
    Q.ParamByName(AName).Clear
  Else
    Q.ParamByName(AName).AsString := OISDateTimeToSQL(AValue);
End;

Procedure TOISRepository.LoadVehicle(Q: TSQLQuery; AVehicle: TOISVehicle);
Begin
  AVehicle.Vehicle_ID := Q.FieldByName('Vehicle_ID').AsLargeInt;
  AVehicle.Vessel_ID := Q.FieldByName('Vessel_ID').AsLargeInt;
  AVehicle.VehicleClass_ID := Q.FieldByName('VehicleClass_ID').AsLargeInt;
  AVehicle.Name := Q.FieldByName('Name').AsString;
End;

Function TOISRepository.AddFolder(AFolder: TOISFolder): TOISID;
Var
  Q: TSQLQuery;
Begin
  Q := NewQuery('INSERT INTO Folder (Name, Description, BaseFolder) ' +
    'VALUES (:Name, :Description, :BaseFolder)');
  Try
    Q.ParamByName('Name').AsString := AFolder.Name;
    Q.ParamByName('Description').AsString := AFolder.Description;
    Q.ParamByName('BaseFolder').AsString := AFolder.BaseFolder;

    Result := ExecInsert(Q);
    AFolder.Folder_ID := Result;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetFolder(AID: TOISID): TOISFolder;
Var
  Q: TSQLQuery;
Begin
  Result := nil;
  Q := SelectID('SELECT * FROM Folder WHERE Folder_ID = :ID', AID);
  If Q = nil Then Exit;

  Try
    Result := TOISFolder.Create;
    Result.Folder_ID := Q.FieldByName('Folder_ID').AsLargeInt;
    Result.Name := Q.FieldByName('Name').AsString;
    Result.Description := Q.FieldByName('Description').AsString;
    Result.BaseFolder := Q.FieldByName('BaseFolder').AsString;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.AddMediaType(AMediaType: TOISMediaType): TOISID;
Var
  Q: TSQLQuery;
Begin
  Q := NewQuery('INSERT INTO MediaType (Name, Description) ' + 'VALUES (:Name, :Description)');
  Try
    Q.ParamByName('Name').AsString := AMediaType.Name;
    Q.ParamByName('Description').AsString := AMediaType.Description;

    Result := ExecInsert(Q);
    AMediaType.MediaType_ID := Result;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetMediaType(AID: TOISID): TOISMediaType;
Var
  Q: TSQLQuery;
Begin
  Result := nil;
  Q := SelectID('SELECT * FROM MediaType WHERE MediaType_ID = :ID', AID);
  If Q = nil Then Exit;

  Try
    Result := TOISMediaType.Create;
    Result.MediaType_ID := Q.FieldByName('MediaType_ID').AsLargeInt;
    Result.Name := Q.FieldByName('Name').AsString;
    Result.Description := Q.FieldByName('Description').AsString;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.AddVehicleClass(AVehicleClas: TOISVehicleClass): TOISID;
Var
  Q: TSQLQuery;
Begin
  Q := NewQuery('INSERT INTO VehicleClass (Name, Description) ' +
    'VALUES (:Name, :Description)');
  Try
    Q.ParamByName('Name').AsString := AVehicleClas.Name;
    Q.ParamByName('Description').AsString := AVehicleClas.Description;

    Result := ExecInsert(Q);
    AVehicleClas.VehicleClass_ID := Result;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetVehicleClass(AID: TOISID): TOISVehicleClass;
Var
  Q: TSQLQuery;
Begin
  Result := nil;
  Q := SelectID('SELECT * FROM VehicleClass WHERE VehicleClass_ID = :ID', AID);
  If Q = nil Then Exit;

  Try
    Result := TOISVehicleClass.Create;
    Result.VehicleClass_ID := Q.FieldByName('VehicleClass_ID').AsLargeInt;
    Result.Name := Q.FieldByName('Name').AsString;
    Result.Description := Q.FieldByName('Description').AsString;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.AddVessel(AVessel: TOISVessel): TOISID;
Var
  Q: TSQLQuery;
Begin
  Q := NewQuery('INSERT INTO Vessel (Name) VALUES (:Name)');
  Try
    Q.ParamByName('Name').AsString := AVessel.Name;

    Result := ExecInsert(Q);
    AVessel.Vessel_ID := Result;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetVessel(AID: TOISID): TOISVessel;
Var
  Q: TSQLQuery;
Begin
  Result := nil;
  Q := SelectID('SELECT * FROM Vessel WHERE Vessel_ID = :ID', AID);
  If Q = nil Then Exit;

  Try
    Result := TOISVessel.Create;
    Result.Vessel_ID := Q.FieldByName('Vessel_ID').AsLargeInt;
    Result.Name := Q.FieldByName('Name').AsString;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.AddWorkpack(AWorkpack: TOISWorkpack): TOISID;
Var
  Q: TSQLQuery;
Begin
  Q := NewQuery('INSERT INTO Workpack ' +
    '(Name, StartDateTime, EndDateTime, Client, Contractor, AnomalyFolder_ID) ' +
    'VALUES (:Name, :StartDateTime, :EndDateTime, :Client, :Contractor, :AnomalyFolder_ID)');
  Try
    Q.ParamByName('Name').AsString := AWorkpack.Name;
    SetDateTimeParam(Q, 'StartDateTime', AWorkpack.StartDateTime);
    SetDateTimeParam(Q, 'EndDateTime', AWorkpack.EndDateTime);
    Q.ParamByName('Client').AsString := AWorkpack.Client;
    Q.ParamByName('Contractor').AsString := AWorkpack.Contractor;
    SetIDParam(Q, 'AnomalyFolder_ID', AWorkpack.AnomalyFolder_ID);

    Result := ExecInsert(Q);
    AWorkpack.Workpack_ID := Result;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetWorkpack(AID: TOISID): TOISWorkpack;
Var
  Q: TSQLQuery;
Begin
  Result := nil;
  Q := SelectID('SELECT * FROM Workpack WHERE Workpack_ID = :ID', AID);
  If Q = nil Then Exit;

  Try
    Result := TOISWorkpack.Create;
    Result.Workpack_ID := Q.FieldByName('Workpack_ID').AsLargeInt;
    Result.Name := Q.FieldByName('Name').AsString;
    Result.StartDateTime := SQLToOISDateTime(Q.FieldByName('StartDateTime').AsString);
    Result.EndDateTime := SQLToOISDateTime(Q.FieldByName('EndDateTime').AsString);
    Result.Client := Q.FieldByName('Client').AsString;
    Result.Contractor := Q.FieldByName('Contractor').AsString;
    Result.AnomalyFolder_ID := Q.FieldByName('AnomalyFolder_ID').AsLargeInt;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.AddComponent(AComponent: TOISComponent): TOISID;
Var
  Q: TSQLQuery;
Begin
  Q := NewQuery('INSERT INTO Component ' +
    '(ParentComponent_ID, Name, IsStructure, Path, ComponentFolder_ID) ' +
    'VALUES (:ParentComponent_ID, :Name, :IsStructure, :Path, :ComponentFolder_ID)');
  Try
    SetIDParam(Q, 'ParentComponent_ID', AComponent.ParentComponent_ID);
    Q.ParamByName('Name').AsString := AComponent.Name;
    Q.ParamByName('IsStructure').AsInteger := Ord(AComponent.IsStructure);
    Q.ParamByName('Path').AsString := AComponent.Path;
    SetIDParam(Q, 'ComponentFolder_ID', AComponent.ComponentFolder_ID);

    Result := ExecInsert(Q);
    AComponent.Component_ID := Result;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetComponent(AID: TOISID): TOISComponent;
Var
  Q: TSQLQuery;
Begin
  Result := nil;
  Q := SelectID('SELECT * FROM Component WHERE Component_ID = :ID', AID);
  If Q = nil Then Exit;

  Try
    Result := TOISComponent.Create;
    Result.Component_ID := Q.FieldByName('Component_ID').AsLargeInt;
    Result.ParentComponent_ID := Q.FieldByName('ParentComponent_ID').AsLargeInt;
    Result.Name := Q.FieldByName('Name').AsString;
    Result.IsStructure := Q.FieldByName('IsStructure').AsInteger <> 0;
    Result.Path := Q.FieldByName('Path').AsString;
    Result.ComponentFolder_ID := Q.FieldByName('ComponentFolder_ID').AsLargeInt;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.AddVehicle(AVehicle: TOISVehicle): TOISID;
Var
  Q: TSQLQuery;
Begin
  Q := NewQuery('INSERT INTO Vehicle (Vessel_ID, VehicleClass_ID, Name) ' +
    'VALUES (:Vessel_ID, :VehicleClass_ID, :Name)');
  Try
    SetIDParam(Q, 'Vessel_ID', AVehicle.Vessel_ID);
    SetIDParam(Q, 'VehicleClass_ID', AVehicle.VehicleClass_ID);
    Q.ParamByName('Name').AsString := AVehicle.Name;

    Result := ExecInsert(Q);
    AVehicle.Vehicle_ID := Result;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetVehicle(AID: TOISID): TOISVehicle;
Var
  Q: TSQLQuery;
Begin
  Result := nil;
  Q := SelectID('SELECT * FROM Vehicle WHERE Vehicle_ID = :ID', AID);
  If Q = nil Then Exit;

  Try
    Result := TOISVehicle.Create;
    LoadVehicle(Q, Result);
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetVehiclesForVessel(AVessel: TOISVessel): TOISVehicles;
Var
  Q: TSQLQuery;
  oVehicle: TOISVehicle;
Begin
  Result := TOISVehicles.Create(True);

  Q := NewQuery('SELECT Vehicle_ID ' + 'FROM oVehicle ' + 'WHERE Vessel_ID = :Vessel_ID ' +
    'ORDER BY Name');

  Try
    Q.ParamByName('Vessel_ID').AsLargeInt := AVessel.Vessel_ID;
    Q.Open;

    While Not Q.EOF Do
    Begin
      oVehicle := TOISVehicle.Create;
      LoadVehicle(Q, oVehicle);
      Result.Add(oVehicle);
      Q.Next;
    End;

  Except
    Result.Free;
    Raise;
  End;

  Q.Free;
End;

Function TOISRepository.AddMedia(AMedia: TOISMedia): TOISID;
Var
  Q: TSQLQuery;
Begin
  Q := NewQuery('INSERT INTO Media ' +
    '(Caption, Filename, SubFolder, StartDateTime, EndDateTime, MediaType_ID) ' +
    'VALUES (:Caption, :Filename, :SubFolder, :StartDateTime, :EndDateTime, :MediaType_ID)');
  Try
    Q.ParamByName('Caption').AsString := AMedia.Caption;
    Q.ParamByName('Filename').AsString := AMedia.Filename;
    Q.ParamByName('SubFolder').AsString := AMedia.SubFolder;
    SetDateTimeParam(Q, 'StartDateTime', AMedia.StartDateTime);
    SetDateTimeParam(Q, 'EndDateTime', AMedia.EndDateTime);
    SetIDParam(Q, 'MediaType_ID', AMedia.MediaType_ID);

    Result := ExecInsert(Q);
    AMedia.Media_ID := Result;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetMedia(AID: TOISID): TOISMedia;
Var
  Q: TSQLQuery;
Begin
  Result := nil;
  Q := SelectID('SELECT * FROM Media WHERE Media_ID = :ID', AID);
  If Q = nil Then Exit;

  Try
    Result := TOISMedia.Create;
    Result.Media_ID := Q.FieldByName('Media_ID').AsLargeInt;
    Result.Caption := Q.FieldByName('Caption').AsString;
    Result.Filename := Q.FieldByName('Filename').AsString;
    Result.SubFolder := Q.FieldByName('SubFolder').AsString;
    Result.StartDateTime := SQLToOISDateTime(Q.FieldByName('StartDateTime').AsString);
    Result.EndDateTime := SQLToOISDateTime(Q.FieldByName('EndDateTime').AsString);
    Result.MediaType_ID := Q.FieldByName('MediaType_ID').AsLargeInt;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.AddChannel(AChannel: TOISChannel): TOISID;
Var
  Q: TSQLQuery;
Begin
  Q := NewQuery('INSERT INTO Channel (Workpack_ID, Name, Vehicle_ID, DataFolder_ID) ' +
    'VALUES (:Workpack_ID, :Name, :Vehicle_ID, :DataFolder_ID)');
  Try
    SetIDParam(Q, 'Workpack_ID', AChannel.Workpack_ID);
    Q.ParamByName('Name').AsString := AChannel.Name;
    SetIDParam(Q, 'Vehicle_ID', AChannel.Vehicle_ID);
    SetIDParam(Q, 'DataFolder_ID', AChannel.DataFolder_ID);

    Result := ExecInsert(Q);
    AChannel.Channel_ID := Result;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetChannel(AID: TOISID): TOISChannel;
Var
  Q: TSQLQuery;
Begin
  Result := nil;
  Q := SelectID('SELECT * FROM Channel WHERE Channel_ID = :ID', AID);
  If Q = nil Then Exit;

  Try
    Result := TOISChannel.Create;
    Result.Channel_ID := Q.FieldByName('Channel_ID').AsLargeInt;
    Result.Workpack_ID := Q.FieldByName('Workpack_ID').AsLargeInt;
    Result.Name := Q.FieldByName('Name').AsString;
    Result.Vehicle_ID := Q.FieldByName('Vehicle_ID').AsLargeInt;
    Result.DataFolder_ID := Q.FieldByName('DataFolder_ID').AsLargeInt;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.AddChannelData(AChannelData: TOISChannelData): TOISID;
Var
  Q: TSQLQuery;
Begin
  Q := NewQuery('INSERT INTO ChannelData (Channel_ID, Media_ID, Component_ID) ' +
    'VALUES (:Channel_ID, :Media_ID, :Component_ID)');
  Try
    SetIDParam(Q, 'Channel_ID', AChannelData.Channel_ID);
    SetIDParam(Q, 'Media_ID', AChannelData.Media_ID);
    SetIDParam(Q, 'Component_ID', AChannelData.Component_ID);

    Result := ExecInsert(Q);
    AChannelData.ChannelData_ID := Result;
  Finally
    Q.Free;
  End;
End;

Function TOISRepository.GetChannelData(AID: TOISID): TOISChannelData;
Var
  Q: TSQLQuery;
Begin
  Result := nil;
  Q := SelectID('SELECT * FROM ChannelData WHERE ChannelData_ID = :ID', AID);
  If Q = nil Then Exit;

  Try
    Result := TOISChannelData.Create;
    Result.ChannelData_ID := Q.FieldByName('ChannelData_ID').AsLargeInt;
    Result.Channel_ID := Q.FieldByName('Channel_ID').AsLargeInt;
    Result.Media_ID := Q.FieldByName('Media_ID').AsLargeInt;
    Result.Component_ID := Q.FieldByName('Component_ID').AsLargeInt;
  Finally
    Q.Free;
  End;
End;

End.
