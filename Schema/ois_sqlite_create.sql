/*==============================================================================
  Open Inspection Database Schema
  Version    : 0.1.0
  File       : ois_sqlite_create.sql

  Description
    Vendor-neutral SQLite database schema for subsea, offshore and industrial
    inspection data.

    The schema provides a common data model for workpacks, assets, components,
    vehicles, media, observations, anomalies and associated inspection data.

    Project:
      https://github.com/MikeCornflake/IM_inspection_schema

  Copyright (c) 2026 Inspector Mike Pty Ltd

  Released under the MIT License.

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

==============================================================================*/

PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

---------------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS (dependency‑ordered)
---------------------------------------------------------------------

-- Folder
CREATE TABLE IF NOT EXISTS Folder (
    Folder_ID   INTEGER PRIMARY KEY AUTOINCREMENT,
    Name        TEXT NOT NULL,
    Description TEXT,
    BaseFolder  TEXT
);

-- LookupGroup
CREATE TABLE IF NOT EXISTS LookupGroup (
    LookupGroup_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name           TEXT NOT NULL UNIQUE,
    Description    TEXT
);

-- LookupValue
CREATE TABLE IF NOT EXISTS LookupValue (
    LookupValue_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    LookupGroup_ID INTEGER NOT NULL REFERENCES LookupGroup(LookupGroup_ID) ON DELETE CASCADE ON UPDATE CASCADE,
    Code           TEXT NOT NULL,
    Description    TEXT,

	UNIQUE (LookupGroup_ID, Code)
);

-- FieldDataType
CREATE TABLE IF NOT EXISTS FieldDataType (
    DataType_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name        TEXT NOT NULL UNIQUE,
    Description TEXT
);

-- ObservationType
CREATE TABLE IF NOT EXISTS ObservationType (
    ObservationType_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name               TEXT NOT NULL UNIQUE,
    Description        TEXT,
    IsDeleted          INTEGER DEFAULT 0
);

-- AnomalyCode (old‑world)
CREATE TABLE IF NOT EXISTS AnomalyCode (
    AnomalyCode_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name           TEXT NOT NULL UNIQUE,
    Description    TEXT
);

-- MediaType
CREATE TABLE IF NOT EXISTS MediaType (
    MediaType_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name         TEXT NOT NULL UNIQUE,
    Description  TEXT
);

-- VehicleClass
CREATE TABLE IF NOT EXISTS VehicleClass (
    VehicleClass_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name            TEXT NOT NULL UNIQUE,
    Description     TEXT
);

-- Vessel
CREATE TABLE IF NOT EXISTS Vessel (
    Vessel_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Name      TEXT NOT NULL
);

-- Workpack
CREATE TABLE IF NOT EXISTS Workpack (
    Workpack_ID      INTEGER PRIMARY KEY AUTOINCREMENT,
    Name             TEXT NOT NULL,
    StartDateTime    TEXT CHECK (StartDateTime GLOB '????-??-??T??:??:??*'),
    EndDateTime      TEXT CHECK (EndDateTime GLOB '????-??-??T??:??:??*'),
    Client           TEXT,
    Contractor       TEXT,
    AnomalyFolder_ID INTEGER NOT NULL REFERENCES Folder(Folder_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Component
CREATE TABLE IF NOT EXISTS Component (
    Component_ID       INTEGER PRIMARY KEY AUTOINCREMENT,
    ParentComponent_ID INTEGER REFERENCES Component(Component_ID) ON DELETE SET NULL ON UPDATE CASCADE,
    Name               TEXT NOT NULL,
    IsStructure        INTEGER DEFAULT 0,
    Path               TEXT,
    ComponentFolder_ID INTEGER REFERENCES Folder(Folder_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Vehicle
CREATE TABLE IF NOT EXISTS Vehicle (
    Vehicle_ID      INTEGER PRIMARY KEY AUTOINCREMENT,
    Vessel_ID       INTEGER NOT NULL REFERENCES Vessel(Vessel_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    VehicleClass_ID INTEGER NOT NULL REFERENCES VehicleClass(VehicleClass_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Name            TEXT NOT NULL
);

-- Media
CREATE TABLE IF NOT EXISTS Media (
    Media_ID      INTEGER PRIMARY KEY AUTOINCREMENT,
    Caption       TEXT NOT NULL,
    Filename      TEXT NOT NULL,
    SubFolder     TEXT,
    StartDateTime TEXT CHECK (StartDateTime GLOB '????-??-??T??:??:??*'),
    EndDateTime   TEXT CHECK (EndDateTime GLOB '????-??-??T??:??:??*'),
    MediaType_ID  INTEGER REFERENCES MediaType(MediaType_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Channel
CREATE TABLE IF NOT EXISTS Channel (
    Channel_ID    INTEGER PRIMARY KEY AUTOINCREMENT,
    Workpack_ID   INTEGER NOT NULL REFERENCES Workpack(Workpack_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Name          TEXT,
    Vehicle_ID    INTEGER NOT NULL REFERENCES Vehicle(Vehicle_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    DataFolder_ID INTEGER REFERENCES Folder(Folder_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ChannelData
CREATE TABLE IF NOT EXISTS ChannelData (
    ChannelData_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Channel_ID     INTEGER REFERENCES Channel(Channel_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Media_ID       INTEGER REFERENCES Media(Media_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Component_ID   INTEGER REFERENCES Component(Component_ID) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Anomaly
CREATE TABLE IF NOT EXISTS Anomaly (
    Anomaly_ID     INTEGER PRIMARY KEY AUTOINCREMENT,
    AnomalyCode_ID INTEGER NOT NULL REFERENCES AnomalyCode(AnomalyCode_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Workpack_ID    INTEGER REFERENCES Workpack(Workpack_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Component_ID   INTEGER NOT NULL REFERENCES Component(Component_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Number         TEXT NOT NULL UNIQUE,
    Description    TEXT,
    IsDeleted      INTEGER DEFAULT 0
);

-- AnomalyMedia
CREATE TABLE IF NOT EXISTS AnomalyMedia (
    AnomalyMedia_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    Anomaly_ID      INTEGER NOT NULL REFERENCES Anomaly(Anomaly_ID) ON DELETE RESTRICT,
    Channel_ID      INTEGER REFERENCES Channel(Channel_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Media_ID        INTEGER NOT NULL REFERENCES Media(Media_ID) ON DELETE RESTRICT
);

-- Observation
CREATE TABLE IF NOT EXISTS Observation (
    Observation_ID     INTEGER PRIMARY KEY AUTOINCREMENT,
    ObservationType_ID INTEGER NOT NULL REFERENCES ObservationType(ObservationType_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Vehicle_ID         INTEGER NOT NULL REFERENCES Vehicle(Vehicle_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Component_ID       INTEGER NOT NULL REFERENCES Component(Component_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    StartDateTime      TEXT CHECK (StartDateTime GLOB '????-??-??T??:??:??*'),
    EndDateTime        TEXT CHECK (EndDateTime GLOB '????-??-??T??:??:??*'),
    Workpack_ID        INTEGER REFERENCES Workpack(Workpack_ID) ON DELETE RESTRICT,
    Location           TEXT,
    Comment            TEXT
);

-- FieldDefinition
CREATE TABLE IF NOT EXISTS FieldDefinition (
    FieldDefinition_ID INTEGER PRIMARY KEY AUTOINCREMENT,
    ObservationType_ID INTEGER NOT NULL REFERENCES ObservationType(ObservationType_ID) ON DELETE CASCADE ON UPDATE CASCADE,
    Name               TEXT NOT NULL,
    DataType_ID        INTEGER NOT NULL REFERENCES FieldDataType(DataType_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Unit               TEXT,
    LookupGroup_ID     INTEGER REFERENCES LookupGroup(LookupGroup_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    IsRequired         INTEGER DEFAULT 0,
    SortOrder          INTEGER DEFAULT 0,
    Description        TEXT,
	
	UNIQUE (ObservationType_ID, Name)
);

-- FieldValue
CREATE TABLE IF NOT EXISTS FieldValue (
    Observation_ID     INTEGER NOT NULL REFERENCES Observation(Observation_ID) ON DELETE CASCADE ON UPDATE CASCADE,
    FieldDefinition_ID INTEGER NOT NULL REFERENCES FieldDefinition(FieldDefinition_ID) ON DELETE CASCADE ON UPDATE CASCADE,
    ValueText          TEXT,
    ValueNumber        REAL,
    ValueBool          INTEGER,
    LookupValue_ID     INTEGER REFERENCES LookupValue(LookupValue_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    PRIMARY KEY (Observation_ID, FieldDefinition_ID)
);

-- ObservationAnomaly
CREATE TABLE IF NOT EXISTS ObservationAnomaly (
    Observation_ID INTEGER REFERENCES Observation(Observation_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    Anomaly_ID     INTEGER REFERENCES Anomaly(Anomaly_ID) ON DELETE RESTRICT ON UPDATE CASCADE,
    PRIMARY KEY (Observation_ID, Anomaly_ID)
);

---------------------------------------------------------------------
-- INSERT SEED DATA (dependency‑ordered)
---------------------------------------------------------------------

-- FieldDataType
INSERT OR IGNORE INTO FieldDataType (Name, Description) VALUES
('Text', 'Single line free text'),
('Number', 'Any numeric with decimal places'),
('Integer', 'Whole numbers'),
('Lookup', 'A value chosen from a list'),
('Percent', 'A number between 0 and 100'),
('Bool', 'Yes or no'),
('Memo', 'Text extending over multiple lines'),
('Datetime', 'Date, Time or Datetime in ISO8601 format');

-- ObservationType
INSERT OR IGNORE INTO ObservationType (Name, Description) VALUES
('DVI', 'Detailed Visual Inspection'),
('CVI', 'Close Visual Inspection'),
('GVI', 'General Visual Inspection'),
('CP-CON', 'Contact CP reading');

-- AnomalyCode (old‑world)
INSERT OR IGNORE INTO AnomalyCode (Name, Description) VALUES
('AW', 'Anode anomalies including depleted, missing, detached or wasted anodes'),
('CD', 'Coating anomalies including damage, disbondment, cracking or blistering'),
('CP', 'Cathodic protection anomalies including low, high or unstable potentials'),
('CR', 'Corrosion anomalies including general, pitting or localised corrosion'),
('DB', 'Debris including fishing gear, foreign objects or dropped items'),
('DM', 'General structural or mechanical damage such as dents, gouges or deformation'),
('FM', 'Flooding or water ingress in members, buoyancy modules, housings or J-tubes'),
('FS', 'Free span anomalies including excessive unsupported spans or seabed scouring'),
('GEN', 'General anomalies not covered by other categories'),
('HYD', 'Hydraulic anomalies including leaks from hoses, fittings or actuators'),
('LK', 'Leakage including hydrocarbon sheen, bubbles or fluid discharge'),
('MG', 'Marine growth anomalies including heavy or obstructive growth'),
('SCOUR', 'Scour or seabed erosion exposing or undermining structures or pipelines'),
('VALVE', 'Valve anomalies including stuck, leaking or missing components'),
('VS', 'Variation to specification'),
('WELD', 'Weld anomalies including cracks, porosity, undercut or corrosion at welds');

-- MediaType
INSERT OR IGNORE INTO MediaType (Name, Description) VALUES
('Video', 'Routine video'),
('Anomaly', 'Anomaly grabs, video and supporting documents'),
('Stills', 'Routine images'),
('Survey', 'Raw and processed positional data'),
('Drawings', 'Structural inspection or engineering drawings'),
('Workpack', 'Workpack documents (SOW, Procedure, Reports)'),
('Data', 'Large sensor datasets'),
('Models', '3D models or point clouds');

-- VehicleClass
INSERT OR IGNORE INTO VehicleClass (Name, Description) VALUES
('WCLASS', 'Workclass ROV'),
('OBSROV', 'Observation / Inspection class ROV'),
('EYEBALL', 'Eyeball Class ROV'),
('AUV', 'Autonomous Underwater Vehicle'),
('AIR', 'Air Diver'),
('SAT', 'Saturation Diver'),
('RAT', 'Rope Access Technician');

---------------------------------------------------------------------
-- INDEXES
---------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_Anomaly_AnomalyCode_ID ON Anomaly (AnomalyCode_ID);
CREATE INDEX IF NOT EXISTS idx_Anomaly_Component_ID ON Anomaly (Component_ID);
CREATE INDEX IF NOT EXISTS idx_Anomaly_Workpack_ID ON Anomaly (Workpack_ID);

CREATE INDEX IF NOT EXISTS idx_AnomalyMedia_Anomaly_ID ON AnomalyMedia (Anomaly_ID);
CREATE INDEX IF NOT EXISTS idx_AnomalyMedia_Channel_ID ON AnomalyMedia (Channel_ID);
CREATE INDEX IF NOT EXISTS idx_AnomalyMedia_Media_ID ON AnomalyMedia (Media_ID);

CREATE INDEX IF NOT EXISTS idx_Channel_Workpack_ID ON Channel (Workpack_ID);
CREATE INDEX IF NOT EXISTS idx_Channel_Vehicle_ID ON Channel (Vehicle_ID);
CREATE INDEX IF NOT EXISTS idx_Channel_DataFolder_ID ON Channel (DataFolder_ID);

CREATE INDEX IF NOT EXISTS idx_ChannelData_Channel_ID ON ChannelData (Channel_ID);
CREATE INDEX IF NOT EXISTS idx_ChannelData_Media_ID ON ChannelData (Media_ID);
CREATE INDEX IF NOT EXISTS idx_ChannelData_Component_ID ON ChannelData (Component_ID);

CREATE INDEX IF NOT EXISTS idx_Component_ParentComponent_ID ON Component (ParentComponent_ID);

CREATE INDEX IF NOT EXISTS idx_FieldDefinition_ObservationType_ID ON FieldDefinition (ObservationType_ID);
CREATE INDEX IF NOT EXISTS idx_FieldDefinition_DataType_ID ON FieldDefinition (DataType_ID);
CREATE INDEX IF NOT EXISTS idx_FieldDefinition_LookupGroup_ID ON FieldDefinition (LookupGroup_ID);

CREATE INDEX IF NOT EXISTS idx_FieldValue_Observation_ID ON FieldValue (Observation_ID);
CREATE INDEX IF NOT EXISTS idx_FieldValue_LookupValue_ID ON FieldValue (LookupValue_ID);

CREATE INDEX IF NOT EXISTS idx_Media_MediaType_ID ON Media (MediaType_ID);

CREATE INDEX IF NOT EXISTS idx_Observation_Component_ID ON Observation (Component_ID);
CREATE INDEX IF NOT EXISTS idx_Observation_Workpack_ID ON Observation (Workpack_ID);

CREATE INDEX IF NOT EXISTS idx_ObservationAnomaly_Observation_ID ON ObservationAnomaly (Observation_ID);
CREATE INDEX IF NOT EXISTS idx_ObservationAnomaly_Anomaly_ID ON ObservationAnomaly (Anomaly_ID);

CREATE INDEX IF NOT EXISTS idx_Vehicle_Vessel_ID ON Vehicle (Vessel_ID);
CREATE INDEX IF NOT EXISTS idx_Vehicle_VehicleClass_ID ON Vehicle (VehicleClass_ID);

CREATE INDEX IF NOT EXISTS idx_Workpack_AnomalyFolder_ID ON Workpack (AnomalyFolder_ID);

COMMIT;
PRAGMA user_version = 10; -- 0.1.0
PRAGMA foreign_keys = ON;
