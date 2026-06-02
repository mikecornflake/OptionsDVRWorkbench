Unit OptionsProperties;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, fgl, VehicleFolders;

Type
  TOptionsProperty = Class
    VehicleFolder: TVehicleFolder;
    StartDate: TDateTime;
    EndDate: TDateTime;
    VideoFile0: String;
    VideoFile1: String;
    VideoFile2: String;
    VideoFile3: String;
    Folder: String;
  End;

  TOptionsProperties = Class(Specialize TFPGObjectList<TOptionsProperty>);

Implementation

End.
