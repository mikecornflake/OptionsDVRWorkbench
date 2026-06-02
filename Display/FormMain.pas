Unit FormMain;

{$mode objfpc}{$H+}
{$WARN 6058 off : Call to subroutine "$1" marked as inline is not inlined}
Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, VehicleFolders, OptionsProperties;

Type

  { TfrmMain }

  TfrmMain = Class(TForm)
    ImageList1: TImageList;
    lvFiles: TListView;
    memLog: TMemo;
    pcMain: TPageControl;
    sbMain: TStatusBar;
    Splitter1: TSplitter;
    tsLog: TTabSheet;
    tsVideo: TTabSheet;
    tsAnomaly: TTabSheet;
    tsStills: TTabSheet;
    tbMain: TToolBar;
    btnConfigureFolders: TToolButton;
    tvFolders: TTreeView;
    Procedure btnConfigureFoldersClick(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure tvFoldersDeletion(Sender: TObject; Node: TTreeNode);
    Procedure tvFoldersSelectionChanged(Sender: TObject);
  Private
    FVehicleFolders: TVehicleFolders;
    FOptionsProperties: TOptionsProperties;
    Procedure LoadOptions;
    Procedure SaveOptions;
  Public
    Procedure Log(ALog: String);
  End;

Var
  frmMain: TfrmMain;

Procedure Log(ALog: String);

Implementation

Uses DialogFolders, IniFiles, OptionsScanner, OptionsDVRSupport;

Procedure Log(ALog: String);
Begin
  frmMain.Log(ALog);
End;

{$R *.lfm}

{ TfrmMain }

Procedure TfrmMain.FormCreate(Sender: TObject);
Var
  oVehicle: TVehicleFolder;
Begin
  FVehicleFolders := TVehicleFolders.Create(True);
  FOptionsProperties := TOptionsProperties.Create(True);

  LoadOptions;

  pcMain.ActivePage := tsVideo;

  memLog.Lines.Clear;
End;

Procedure TfrmMain.btnConfigureFoldersClick(Sender: TObject);
Begin
  FOptionsProperties.Clear;

  Log('Scanning Video');
  ScanVehicleFolders(FVehicleFolders, FOptionsProperties);

  Log('Sorting Video');
  SortOptionsPropertiesByStartDate(FOptionsProperties);

  Log('Sorting Video');
  PopulateOptionsDVRTreeView(tvFolders, FOptionsProperties);

  Log('');
End;

Procedure TfrmMain.FormDestroy(Sender: TObject);
Begin
  SaveOptions;

  FreeAndNil(FOptionsProperties);
  FreeAndNil(FVehicleFolders);
End;

Procedure TfrmMain.tvFoldersDeletion(Sender: TObject; Node: TTreeNode);
Begin
  TObject(Node.Data).Free;
  Node.Data := nil;
End;

Procedure TfrmMain.tvFoldersSelectionChanged(Sender: TObject);
Var
  Data: TFolderTreeNodeData;
Begin
  If Not Assigned(tvFolders.Selected) Then
    Exit;

  If Not Assigned(tvFolders.Selected.Data) Then
    Exit;

  Data := TFolderTreeNodeData(tvFolders.Selected.Data);

  PopulateFilesListForFolder(lvFiles, FOptionsProperties, Data.RelativePath);
End;

Procedure TfrmMain.LoadOptions;
Var
  ini: TIniFile;
  sIniFile: String;
  i, j: Integer;
  Vehicle: TVehicleFolder;
  Section: String;
Begin
  FVehicleFolders.Clear;

  sIniFile := ChangeFileExt(Application.ExeName, '.ini');

  If Not FileExists(sIniFile) Then
    Exit;

  ini := TIniFile.Create(sIniFile);
  Try
    For i := 0 To ini.ReadInteger('General', 'VehicleCount', 0) - 1 Do
    Begin
      Section := Format('Vehicle%d', [i]);

      Vehicle := TVehicleFolder.Create;

      Vehicle.Folder := ini.ReadString(Section, 'Folder', '');
      Vehicle.VesselCode := ini.ReadString(Section, 'VesselCode', '');
      Vehicle.VesselName := ini.ReadString(Section, 'VesselName', '');
      Vehicle.VehicleName := ini.ReadString(Section, 'VehicleName', '');
      Vehicle.VehicleClass := ini.ReadString(Section, 'VehicleClass', '');

      Vehicle.Exclude.Clear;

      For j := 0 To ini.ReadInteger(Section, 'ExcludeCount', 0) - 1 Do
        Vehicle.Exclude.Add(ini.ReadString(Section, Format('Exclude%d', [j]), ''));

      FVehicleFolders.Add(Vehicle);
    End;
  Finally
    ini.Free;
  End;
End;

Procedure TfrmMain.SaveOptions;
Var
  ini: TIniFile;
  sIniFile: String;
  i, j: Integer;
  Vehicle: TVehicleFolder;
  Section: String;
Begin
  sIniFile := ChangeFileExt(Application.ExeName, '.ini');

  ini := TIniFile.Create(sIniFile);
  Try
    ini.EraseSection('General');

    For i := 0 To FVehicleFolders.Count - 1 Do
      ini.EraseSection(Format('Vehicle%d', [i]));

    ini.WriteInteger('General', 'VehicleCount', FVehicleFolders.Count);

    For i := 0 To FVehicleFolders.Count - 1 Do
    Begin
      Vehicle := FVehicleFolders[i];
      Section := Format('Vehicle%d', [i]);

      ini.WriteString(Section, 'Folder', Vehicle.Folder);
      ini.WriteString(Section, 'VesselCode', Vehicle.VesselCode);
      ini.WriteString(Section, 'VesselName', Vehicle.VesselName);
      ini.WriteString(Section, 'VehicleName', Vehicle.VehicleName);
      ini.WriteString(Section, 'VehicleClass', Vehicle.VehicleClass);

      ini.WriteInteger(Section, 'ExcludeCount',
        Vehicle.Exclude.Count);

      For j := 0 To Vehicle.Exclude.Count - 1 Do
        ini.WriteString(Section,
          Format('Exclude%d', [j]),
          Vehicle.Exclude[j]);
    End;

    ini.UpdateFile;
  Finally
    ini.Free;
  End;
End;

Procedure TfrmMain.Log(ALog: String);
Begin
  If ALog <> '' Then
    memLog.Lines.Add(TimeToStr(Now) + ': ' + ALog);

  sbMain.Panels[0].Text := ALog;
End;



End.
