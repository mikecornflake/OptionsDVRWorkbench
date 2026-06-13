Unit OptionsScanner;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, IniFiles,
  VehicleFolders, OptionsProperties;

Procedure ScanVehicleFolders(AVehicleFolders: TVehicleFolders;
  AOptionsProperties: TOptionsProperties);

Implementation

Uses DateUtils, FormOptionsDVRWorkbench;

Function IsExcludedFolder(Const AFolder: String; AExclude: TStringList): Boolean;
Var
  i: Integer;
  sFolderName: String;
Begin
  Result := False;
  sFolderName := LowerCase(ExtractFileName(ExcludeTrailingPathDelimiter(AFolder)));

  For i := 0 To AExclude.Count - 1 Do
  Begin
    If Pos(LowerCase(AExclude[i]), sFolderName) > 0 Then
      Exit(True);
  End;
End;

Function ReadOptionsDateTime(Const sValue: String): TDateTime;
Var
  fs: TFormatSettings;
Begin
  fs := DefaultFormatSettings;
  fs.DateSeparator := '-';
  fs.TimeSeparator := ':';
  fs.ShortDateFormat := 'yyyy-mm-dd';
  fs.LongTimeFormat := 'hh:nn:ss.zzz';

  Result := ScanDateTime('yyyy-mm-dd hh:nn:ss.zzz', sValue, fs);
End;

Procedure ReadPropertiesIni(Const AFolder: String; AVehicleFolder: TVehicleFolder;
  AOptionsProperties: TOptionsProperties);
Var
  ini: TIniFile;
  prop: TOptionsProperty;
  sIniFile: String;
  dStartKP, dEndKP: Double;
Begin
  sIniFile := IncludeTrailingPathDelimiter(AFolder) + 'properties.ini';

  If Not FileExists(sIniFile) Then
    Exit;

  ini := TIniFile.Create(sIniFile);
  Try
    dStartKP := ini.ReadFloat('Properties', 'KPStart', 1);
    dEndKP := ini.ReadFloat('Properties', 'KPEnd', 1);

    If (dStartKP = 0) And (dEndKP = 0) Then
    Begin
      prop := TOptionsProperty.Create;
      Try
        prop.VehicleFolder := AVehicleFolder;

        prop.Folder := AFolder;

        prop.StartDate := ReadOptionsDateTime(ini.ReadString('General', 'Start', ''));

        prop.EndDate := ReadOptionsDateTime(ini.ReadString('General', 'End', ''));

        prop.VideoFile0 := ini.ReadString('Properties', 'VideoFile0', '');
        prop.VideoFile1 := ini.ReadString('Properties', 'VideoFile1', '');
        prop.VideoFile2 := ini.ReadString('Properties', 'VideoFile2', '');
        prop.VideoFile3 := ini.ReadString('Properties', 'VideoFile3', '');

        AOptionsProperties.Add(prop);
        prop := nil;
      Finally
        prop.Free;
      End;
    End;
  Finally
    ini.Free;
  End;
End;

Procedure ScanFolder(Const AFolder: String; AExclude: TStringList;
  AVehicleFolder: TVehicleFolder; AOptionsProperties: TOptionsProperties);
Var
  sr: TSearchRec;
  sChildFolder: String;
Begin
  If IsExcludedFolder(AFolder, AExclude) Then
    Exit;

  LogOncePerSecond('Scanning: ' + AFolder);

  ReadPropertiesIni(AFolder, AVehicleFolder, AOptionsProperties);

  If FindFirst(IncludeTrailingPathDelimiter(AFolder) + '*', faDirectory, sr) = 0 Then
  Try
    Repeat
      If (sr.Name <> '.') And (sr.Name <> '..') And ((sr.Attr And faDirectory) <> 0) Then
      Begin
        sChildFolder := IncludeTrailingPathDelimiter(AFolder) + sr.Name;

        If Not IsExcludedFolder(sChildFolder, AExclude) Then
          ScanFolder(sChildFolder, AExclude, AVehicleFolder, AOptionsProperties);
      End;
    Until FindNext(sr) <> 0;
  Finally
    FindClose(sr);
  End;
End;

Procedure ScanVehicleFolders(AVehicleFolders: TVehicleFolders;
  AOptionsProperties: TOptionsProperties);
Var
  i: Integer;
  vf: TVehicleFolder;
  ScanRoot: String;
Begin
  If Not Assigned(AVehicleFolders) Then
    Exit;

  If Not Assigned(AOptionsProperties) Then
    Exit;

  For i := 0 To AVehicleFolders.Count - 1 Do
  Begin
    vf := AVehicleFolders[i];

    Log('Scanning: Vehicle=' + vf.VehicleName);

    ScanRoot :=
      IncludeTrailingPathDelimiter(vf.Folder) + 'Data' + PathDelim + vf.VesselCode;

    If DirectoryExists(ScanRoot) Then
      ScanFolder(ScanRoot, vf.Exclude, vf, AOptionsProperties);
  End;

  Log('');
End;

End.
