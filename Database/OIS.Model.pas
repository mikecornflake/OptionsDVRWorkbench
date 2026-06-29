Unit OIS.Model;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, fgl;

Type
  TOISID = Int64;

  // -- Folder
  //CREATE TABLE IF NOT EXISTS Folder (
  //    Folder_ID   INTEGER PRIMARY KEY AUTOINCREMENT,
  //    Name        TEXT NOT NULL,
  //    Description TEXT,
  //    BaseFolder  TEXT
  //);

  TOISFolder = Class
  Public
    Folder_ID: TOISID;
    Name: String;
    Description: String;
    BaseFolder: String;
  End;

  //-- MediaType
  //CREATE TABLE IF NOT EXISTS MediaType (
  //    MediaType_ID INTEGER PRIMARY KEY AUTOINCREMENT,
  //    Name         TEXT NOT NULL UNIQUE,
  //    Description  TEXT
  //);

  TOISMediaType = Class
  Public
    MediaType_ID: TOISID;
    Name: String;
    Description: String;
  End;

  //-- VehicleClass
  //CREATE TABLE IF NOT EXISTS VehicleClass (
  //    VehicleClass_ID INTEGER PRIMARY KEY AUTOINCREMENT,
  //    Name            TEXT NOT NULL UNIQUE,
  //    Description     TEXT
  //);

  TOISVehicleClass = Class
  Public
    VehicleClass_ID: TOISID;
    Name: String;
    Description: String;
  End;

  //-- Vessel
  //CREATE TABLE IF NOT EXISTS Vessel (
  //    Vessel_ID INTEGER PRIMARY KEY AUTOINCREMENT,
  //    Name      TEXT NOT NULL
  //);

  TOISVessel = Class
  Public
    Vessel_ID: TOISID;
    Name: String;
  End;

  //-- Workpack
  //CREATE TABLE IF NOT EXISTS Workpack (
  //    Workpack_ID      INTEGER PRIMARY KEY AUTOINCREMENT,
  //    Name             TEXT NOT NULL,
  //    StartDateTime    TEXT CHECK (StartDateTime GLOB '????-??-??T??:??:??*'),
  //    EndDateTime      TEXT CHECK (EndDateTime GLOB '????-??-??T??:??:??*'),
  //    Client           TEXT,
  //    Contractor       TEXT,
  //    AnomalyFolder_ID INTEGER NOT NULL REFERENCES Folder(Folder_ID) ON DELETE RESTRICT ON UPDATE CASCADE
  //);

  TOISWorkpack = Class
  Public
    Workpack_ID: TOISID;
    Name: String;
    StartDateTime: TDateTime;
    EndDateTime: TDateTime;
    Client: String;
    Contractor: String;
    AnomalyFolder_ID: TOISID;
  End;

  //-- Component
  //CREATE TABLE IF NOT EXISTS Component (
  //    Component_ID       INTEGER PRIMARY KEY AUTOINCREMENT,
  //    ParentComponent_ID INTEGER REFERENCES Component(Component_ID) ON DELETE SET NULL ON UPDATE CASCADE,
  //    Name               TEXT NOT NULL,
  //    IsStructure        INTEGER DEFAULT 0,
  //    Path               TEXT,
  //    ComponentFolder_ID INTEGER REFERENCES Folder(Folder_ID) ON DELETE RESTRICT ON UPDATE CASCADE
  //);

  TOISComponent = Class
  Public
    Component_ID: TOISID;
    ParentComponent_ID: TOISID;
    Name: String;
    IsStructure: Boolean;
    Path: String;
    ComponentFolder_ID: TOISID;
  End;

  //-- Vehicle
  //CREATE TABLE IF NOT EXISTS Vehicle (
  //    Vehicle_ID      INTEGER PRIMARY KEY AUTOINCREMENT,
  //    Vessel_ID       INTEGER NOT NULL REFERENCES Vessel(Vessel_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
  //    VehicleClass_ID INTEGER NOT NULL REFERENCES VehicleClass(VehicleClass_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
  //    Name            TEXT NOT NULL
  //);

  TOISVehicle = Class
  Public
    Vehicle_ID: TOISID;
    Vessel_ID: TOISID;
    VehicleClass_ID: TOISID;
    Name: String;
  End;

  TOISVehicles = Specialize TFPGObjectList<TOISVehicle>;

  //-- Media
  //CREATE TABLE IF NOT EXISTS Media (
  //    Media_ID      INTEGER PRIMARY KEY AUTOINCREMENT,
  //    Caption       TEXT NOT NULL,
  //    Filename      TEXT NOT NULL,
  //    SubFolder     TEXT,
  //    StartDateTime TEXT CHECK (StartDateTime GLOB '????-??-??T??:??:??*'),
  //    EndDateTime   TEXT CHECK (EndDateTime GLOB '????-??-??T??:??:??*'),
  //    MediaType_ID  INTEGER REFERENCES MediaType(MediaType_ID) ON DELETE RESTRICT ON UPDATE CASCADE
  //);

  TOISMedia = Class
  Public
    Media_ID: TOISID;
    Caption: String;
    Filename: String;
    SubFolder: String;
    StartDateTime: TDateTime;
    EndDateTime: TDateTime;
    MediaType_ID: TOISID;
  End;

  //-- Channel
  //CREATE TABLE IF NOT EXISTS Channel (
  //    Channel_ID    INTEGER PRIMARY KEY AUTOINCREMENT,
  //    Workpack_ID   INTEGER NOT NULL REFERENCES Workpack(Workpack_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
  //    Name          TEXT,
  //    Vehicle_ID    INTEGER NOT NULL REFERENCES Vehicle(Vehicle_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
  //    DataFolder_ID INTEGER REFERENCES Folder(Folder_ID) ON DELETE RESTRICT ON UPDATE CASCADE
  //);

  TOISChannel = Class
  Public
    Channel_ID: TOISID;
    Workpack_ID: TOISID;
    Name: String;
    Vehicle_ID: TOISID;
    DataFolder_ID: TOISID;
  End;

  //-- ChannelData
  //CREATE TABLE IF NOT EXISTS ChannelData (
  //    ChannelData_ID INTEGER PRIMARY KEY AUTOINCREMENT,
  //    Channel_ID     INTEGER REFERENCES Channel(Channel_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
  //    Media_ID       INTEGER REFERENCES Media(Media_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
  //    Component_ID   INTEGER REFERENCES Component(Component_ID) ON DELETE RESTRICT ON UPDATE CASCADE
  //);

  TOISChannelData = Class
  Public
    ChannelData_ID: TOISID;
    Channel_ID: TOISID;
    Media_ID: TOISID;
    Component_ID: TOISID;
  End;

Implementation

End.
