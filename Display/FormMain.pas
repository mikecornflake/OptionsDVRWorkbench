Unit FormMain;

{$mode objfpc}{$H+}
{$WARN 6058 off : Call to subroutine "$1" marked as inline is not inlined}
{$WARN 5024 off : Parameter "$1" not used}
Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Buttons, LCLType, VehicleFolders, OptionsProperties;

Type

  { TfrmMain }

  TfrmMain = Class(TForm)
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
    Procedure LoadOptions;
    Procedure SaveOptions;

    Procedure RefreshListViewControlPanel(AForceDisable: Boolean = False);
  Public
    Procedure Log(Const ALog: String);
    Procedure LogOncePerSecond(Const ALog: String);
  End;

Var
  frmMain: TfrmMain;

Procedure Log(Const ALog: String);
Procedure LogOncePerSecond(Const ALog: String);

Implementation

Uses
  IniFiles, DateUtils,
  DialogFolders, OptionsScanner, OptionsDVRSupport,
  OSSupport;

Procedure Log(Const ALog: String);
Begin
  frmMain.Log(ALog);
End;

Procedure LogOncePerSecond(Const ALog: String);
Begin
  frmMain.LogOncePerSecond(ALog);
End;

{$R *.lfm}

{ TfrmMain }

Procedure TfrmMain.FormCreate(Sender: TObject);
Begin
  FVehicleFolders := TVehicleFolders.Create(True);
  FOptionsProperties := TOptionsProperties.Create(True);
  FLastLogTick := 0;

  LoadOptions;

  pcMain.ActivePage := tsVideo;

  memLog.Lines.Clear;

  RefreshListViewControlPanel;
End;

Procedure TfrmMain.btnConfigureFoldersClick(Sender: TObject);
Begin
  btnConfigureFolders.Enabled := False;
  RefreshListViewControlPanel(True);
  SetBusy;
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
    ClearBusy;
  End;
End;

Procedure TfrmMain.btnOpenFolderClick(Sender: TObject);
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

Procedure TfrmMain.btnPlayFileClick(Sender: TObject);
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

Procedure TfrmMain.FormDestroy(Sender: TObject);
Begin
  SaveOptions;

  FreeAndNil(FOptionsProperties);
  FreeAndNil(FVehicleFolders);
End;

Procedure TfrmMain.lvFilesSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
Begin
  RefreshListViewControlPanel;

  If Selected Then
    Item.ImageIndex := 3   // selected icon
  Else
    Item.ImageIndex := -1;  // normal icon
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

  Log('Loading files for: ' + Data.RelativePath);

  PopulateFilesListForFolder(lvFiles, FOptionsProperties, Data.RelativePath);

  sbMain.Panels[2].Text := Format('%d videos loaded', [lvFiles.Items.Count]);

  Caption := Format('%s: [%s]', [Application.Title, Data.RelativePath]);
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

Procedure TfrmMain.RefreshListViewControlPanel(AForceDisable: Boolean);
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

Procedure TfrmMain.Log(Const ALog: String);
Begin
  If ALog <> '' Then
    memLog.Lines.Add(FormatDateTime('HH:nn:ss.zzz', Now) + ': ' + ALog);

  sbMain.Panels[0].Text := ALog;
End;

Procedure TfrmMain.LogOncePerSecond(Const ALog: String);
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
