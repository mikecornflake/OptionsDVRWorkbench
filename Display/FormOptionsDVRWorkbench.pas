Unit FormOptionsDVRWorkbench;

{$mode objfpc}{$H+}
{$WARN 6058 off : Call to subroutine "$1" marked as inline is not inlined}
{$WARN 5024 off : Parameter "$1" not used}
Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Buttons, LCLType, IniFiles,
  FormMain,
  VehicleFolders, OptionsProperties;

Type

  { TfrmOptionsDVRWorkbench }

  TfrmOptionsDVRWorkbench = Class(TfrmMain)
    btnOpenVideoFolder: TBitBtn;
    btnPlayFileA: TBitBtn;
    btnPlayFileB: TBitBtn;
    btnPlayFileC: TBitBtn;
    btnPlayFileD: TBitBtn;
    btnOpenAnomalyFolder: TBitBtn;
    btnOpenStillsFolder: TBitBtn;
    ImageList1: TImageList;
    lvFiles: TListView;
    memLog: TMemo;
    pnlControl: TPanel;
    pnlBottom: TPanel;
    pcMain: TPageControl;
    Splitter1: TSplitter;
    tsLog: TTabSheet;
    tsVideo: TTabSheet;
    tsAnomaly: TTabSheet;
    tsStills: TTabSheet;
    tbMain: TToolBar;
    btnConfigureFolders: TToolButton;
    tvFolders: TTreeView;
    Procedure btnConfigureFoldersClick(Sender: TObject);
    Procedure btnOpenFolderClick(Sender: TObject);
    Procedure btnPlayFileClick(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure lvFilesSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    Procedure tvFoldersDeletion(Sender: TObject; Node: TTreeNode);
    Procedure tvFoldersSelectionChanged(Sender: TObject);
  Private
    FVehicleFolders: TVehicleFolders;
    FOptionsProperties: TOptionsProperties;
    FLastLogTick: QWord;
    Procedure RefreshListViewControlPanel(AForceDisable: Boolean = False);
  Protected
    Procedure SaveGlobalSettings(oInifile: TIniFile); Override;
    Procedure LoadGlobalSettings(oIniFile: TIniFile); Override;
  Public
    Procedure Log(Const ALog: String);
    Procedure LogOncePerSecond(Const ALog: String);
  End;

Var
  frmOptionsDVRWorkbench: TfrmOptionsDVRWorkbench;

Procedure Log(Const ALog: String);
Procedure LogOncePerSecond(Const ALog: String);

Implementation

Uses
  DateUtils,
  DialogFolders, OptionsScanner, OptionsDVRSupport,
  OSSupport;

Procedure Log(Const ALog: String);
Begin
  frmOptionsDVRWorkbench.Log(ALog);
End;

Procedure LogOncePerSecond(Const ALog: String);
Begin
  frmOptionsDVRWorkbench.LogOncePerSecond(ALog);
End;

{$R *.lfm}

{ TfrmOptionsDVRWorkbench }

Procedure TfrmOptionsDVRWorkbench.FormCreate(Sender: TObject);
Begin
  FVehicleFolders := TVehicleFolders.Create(True);
  FOptionsProperties := TOptionsProperties.Create(True);
  FLastLogTick := 0;

  pcMain.ActivePage := tsVideo;

  memLog.Lines.Clear;

  RefreshListViewControlPanel;
End;

Procedure TfrmOptionsDVRWorkbench.FormDestroy(Sender: TObject);
Begin
  FreeAndNil(FOptionsProperties);
  FreeAndNil(FVehicleFolders);
End;

Procedure TfrmOptionsDVRWorkbench.btnConfigureFoldersClick(Sender: TObject);
Begin
  btnConfigureFolders.Enabled := False;
  RefreshListViewControlPanel(True);
  Busy := True;
  Try
    pcMain.ActivePage := tsLog;

    FOptionsProperties.Clear;

    Log('Scanning Video');
    ScanVehicleFolders(FVehicleFolders, FOptionsProperties);

    Log('Sorting Video');
    SortOptionsPropertiesByStartDate(FOptionsProperties);

    Log('Populating Treeview');
    PopulateOptionsDVRTreeView(tvFolders, FOptionsProperties);

    sbMain.Panels[1].Text := Format('Total %d videos', [FOptionsProperties.Count]);
    Log('');

    RefreshListViewControlPanel;
  Finally
    pcMain.ActivePage := tsVideo;
    btnConfigureFolders.Enabled := True;
    Busy := False;
  End;
End;

Procedure TfrmOptionsDVRWorkbench.btnOpenFolderClick(Sender: TObject);
Var
  sFolder, sFile: String;
Begin
  If Not (Sender Is TBitBtn) Then
    Exit;

  If Not TBitBtn(Sender).Enabled Then
    Exit;

  sFolder := TBitBtn(Sender).Hint;
  sFile := sFolder + PathDelim + btnPlayFileA.Hint;

  If (sFolder <> '') And DirectoryExists(sFolder) Then
    If FileExists(sFile) Then
      LaunchFile('explorer.exe', Format('/e,/select,"%s"', [sFile]))
    Else
      LaunchFile('explorer.exe', Format('"%s"', [sFolder]));
End;

Procedure TfrmOptionsDVRWorkbench.btnPlayFileClick(Sender: TObject);
Var
  sFile: String;
Begin
  If Not (Sender Is TBitBtn) Then
    Exit;

  If Not TBitBtn(Sender).Enabled Then
    Exit;

  sFile := TBitBtn(Sender).Hint;

  If Assigned(lvFiles.Selected) Then
    lvFiles.Selected.Focused := True;

  If (sFile <> '') And FileExists(sFile) Then
    LaunchDocument(sFile);

  If Assigned(lvFiles.Selected) Then
    lvFiles.Selected.Focused := True;
End;

Procedure TfrmOptionsDVRWorkbench.lvFilesSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
Begin
  RefreshListViewControlPanel;

  If Selected Then
    Item.ImageIndex := 3   // selected icon
  Else
    Item.ImageIndex := -1;  // normal icon
End;

Procedure TfrmOptionsDVRWorkbench.tvFoldersDeletion(Sender: TObject; Node: TTreeNode);
Begin
  TObject(Node.Data).Free;
  Node.Data := nil;
End;

Procedure TfrmOptionsDVRWorkbench.tvFoldersSelectionChanged(Sender: TObject);
Var
  Data: TFolderTreeNodeData;
Begin
  If Not Assigned(tvFolders.Selected) Then
    Exit;

  If Not Assigned(tvFolders.Selected.Data) Then
    Exit;

  Data := TFolderTreeNodeData(tvFolders.Selected.Data);

  Log('Loading files for: ' + Data.RelativePath);

  PopulateFilesListForFolder(lvFiles, FOptionsProperties, Data.RelativePath);

  sbMain.Panels[2].Text := Format('%d videos loaded', [lvFiles.Items.Count]);

  Caption := Format('%s: [%s]', [Application.Title, Data.RelativePath]);
End;

Procedure TfrmOptionsDVRWorkbench.LoadGlobalSettings(oIniFile: TIniFile);
Var
  i, j: Integer;
  oVehicle: TVehicleFolder;
  sIniSection: String;
Begin
  Inherited;

  FVehicleFolders.Clear;

  For i := 0 To oIniFile.ReadInteger('General', 'VehicleCount', 0) - 1 Do
  Begin
    sIniSection := Format('Vehicle%d', [i]);

    oVehicle := TVehicleFolder.Create;

    oVehicle.Folder := oIniFile.ReadString(sIniSection, 'Folder', '');
    oVehicle.VesselCode := oIniFile.ReadString(sIniSection, 'VesselCode', '');
    oVehicle.VesselName := oIniFile.ReadString(sIniSection, 'VesselName', '');
    oVehicle.VehicleName := oIniFile.ReadString(sIniSection, 'VehicleName', '');
    oVehicle.VehicleClass := oIniFile.ReadString(sIniSection, 'VehicleClass', '');

    oVehicle.Exclude.Clear;

    For j := 0 To oIniFile.ReadInteger(sIniSection, 'ExcludeCount', 0) - 1 Do
      oVehicle.Exclude.Add(oIniFile.ReadString(sIniSection, Format('Exclude%d', [j]), ''));

    FVehicleFolders.Add(oVehicle);
  End;
End;

Procedure TfrmOptionsDVRWorkbench.SaveGlobalSettings(oInifile: TIniFile);
Var
  i, j: Integer;
  oVehicle: TVehicleFolder;
  sIniSection: String;
Begin
  Inherited;

  For i := 0 To FVehicleFolders.Count - 1 Do
    oInifile.EraseSection(Format('oVehicle%d', [i]));

  oInifile.WriteInteger('General', 'VehicleCount', FVehicleFolders.Count);

  For i := 0 To FVehicleFolders.Count - 1 Do
  Begin
    oVehicle := FVehicleFolders[i];
    sIniSection := Format('Vehicle%d', [i]);

    oInifile.WriteString(sIniSection, 'Folder', oVehicle.Folder);
    oInifile.WriteString(sIniSection, 'VesselCode', oVehicle.VesselCode);
    oInifile.WriteString(sIniSection, 'VesselName', oVehicle.VesselName);
    oInifile.WriteString(sIniSection, 'VehicleName', oVehicle.VehicleName);
    oInifile.WriteString(sIniSection, 'VehicleClass', oVehicle.VehicleClass);

    // Write the exclude TStringList
    oInifile.WriteInteger(sIniSection, 'ExcludeCount',
      oVehicle.Exclude.Count);

    For j := 0 To oVehicle.Exclude.Count - 1 Do
      oInifile.WriteString(sIniSection,Format('Exclude%d', [j]),oVehicle.Exclude[j]);
  End;
End;

Procedure TfrmOptionsDVRWorkbench.RefreshListViewControlPanel(AForceDisable: Boolean);
Var
  sVideoFolder, sFileA, sAnomalyFolder, sStillsFolder, sFileB, sFileC, sFileD: String;
  oItem: TListItem;
Begin
  btnOpenVideoFolder.Enabled := False;
  btnOpenAnomalyFolder.Enabled := False;
  btnOpenStillsFolder.Enabled := False;

  btnPlayFileA.Enabled := False;
  btnPlayFileB.Enabled := False;
  btnPlayFileC.Enabled := False;
  btnPlayFileD.Enabled := False;

  If AForceDisable Then
    Exit;

  If (lvFiles.Items.Count = 0) Then
    Exit;

  oItem := lvFiles.Selected;

  If Not Assigned(oItem) Then
    Exit;

  If lvFiles.SelCount <> 1 Then
    Exit;

  If oItem.SubItems.Count < 4 Then
    Exit;

  sVideoFolder := oItem.SubItems[3];  // TODO Wrap column in Constant

  sAnomalyFolder := ExcludeTrailingPathDelimiter(sVideoFolder);
  sAnomalyFolder := ExtractFilePath(sAnomalyFolder);
  sAnomalyFolder := ExcludeTrailingPathDelimiter(sAnomalyFolder);
  sAnomalyFolder := StringReplace(sAnomalyFolder, PathDelim + 'Data' + PathDelim,
    PathDelim + 'Anomaly' + PathDelim, [rfIgnoreCase]);

  sStillsFolder := ExcludeTrailingPathDelimiter(sVideoFolder);
  sStillsFolder := ExtractFilePath(sStillsFolder);
  sStillsFolder := ExcludeTrailingPathDelimiter(sStillsFolder);
  sStillsFolder := StringReplace(sStillsFolder, PathDelim + 'Data' + PathDelim,
    PathDelim + 'Stills' + PathDelim, [rfIgnoreCase]);

  btnOpenAnomalyFolder.Hint := sAnomalyFolder;
  btnOpenAnomalyFolder.Enabled := DirectoryExists(sAnomalyFolder);

  btnOpenStillsFolder.Hint := sStillsFolder;
  btnOpenStillsFolder.Enabled := DirectoryExists(sStillsFolder);

  btnOpenVideoFolder.Hint := sVideoFolder;
  btnOpenVideoFolder.Enabled := DirectoryExists(sVideoFolder);

  sFileA := sVideoFolder + PathDelim + lvFiles.Selected.Caption;
  sFileB := StringReplace(sFileA, '@A.mp4', '@B.mp4', [rfIgnoreCase]);
  sFileC := StringReplace(sFileA, '@A.mp4', '@C.mp4', [rfIgnoreCase]);
  sFileD := StringReplace(sFileA, '@A.mp4', '@D.mp4', [rfIgnoreCase]);

  btnPlayFileA.Hint := sFileA;
  btnPlayFileA.Enabled := FileExists(sFileA);

  btnPlayFileB.Hint := sFileB;
  btnPlayFileB.Enabled := FileExists(sFileB);

  btnPlayFileC.Hint := sFileC;
  btnPlayFileC.Enabled := FileExists(sFileC);

  btnPlayFileD.Hint := sFileD;
  btnPlayFileD.Enabled := FileExists(sFileD);
End;

Procedure TfrmOptionsDVRWorkbench.Log(Const ALog: String);
Begin
  If ALog <> '' Then
    memLog.Lines.Add(FormatDateTime('HH:nn:ss.zzz', Now) + ': ' + ALog);

  sbMain.Panels[0].Text := ALog;
End;

Procedure TfrmOptionsDVRWorkbench.LogOncePerSecond(Const ALog: String);
Var
  Tick: QWord;
Begin
  Tick := GetTickCount64;

  If Tick - FLastLogTick < 1000 Then
    Exit;

  FLastLogTick := Tick;
  Log(ALog);

  // TODO Oh god NO!!!!  Thread the scanner you fool!
  Application.ProcessMessages;
End;



End.
