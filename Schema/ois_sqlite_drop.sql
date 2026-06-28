/*==============================================================================
  Open Inspection Database Schema
  Version    : 0.1.0
  File       : ois_sqlite_drop.sql

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
-- DROP TABLES (reverse dependency order)
---------------------------------------------------------------------
DROP TABLE IF EXISTS ObservationAnomaly;
DROP TABLE IF EXISTS FieldValue;
DROP TABLE IF EXISTS FieldDefinition;
DROP TABLE IF EXISTS Observation;
DROP TABLE IF EXISTS AnomalyMedia;
DROP TABLE IF EXISTS ChannelData;
DROP TABLE IF EXISTS Channel;
DROP TABLE IF EXISTS Anomaly;
DROP TABLE IF EXISTS Media;
DROP TABLE IF EXISTS Component;
DROP TABLE IF EXISTS Vehicle;
DROP TABLE IF EXISTS VehicleClass;
DROP TABLE IF EXISTS Vessel;
DROP TABLE IF EXISTS Workpack;
DROP TABLE IF EXISTS MediaType;
DROP TABLE IF EXISTS LookupValue;
DROP TABLE IF EXISTS LookupGroup;
DROP TABLE IF EXISTS FieldDataType;
DROP TABLE IF EXISTS ObservationType;
DROP TABLE IF EXISTS AnomalyCode;
DROP TABLE IF EXISTS Folder;

DELETE FROM sqlite_sequence;

---------------------------------------------------------------------
-- Make it so...
---------------------------------------------------------------------
COMMIT;
PRAGMA user_version = 0; -- No longer OIS
PRAGMA foreign_keys = ON;