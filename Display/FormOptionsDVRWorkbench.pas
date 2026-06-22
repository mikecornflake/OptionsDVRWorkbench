Unit FormOptionsDVRWorkbench;

{$mode objfpc}{$H+}
{$WARN 6058 off : Call to subroutine "$1" marked as inline is not inlined}
{$WARN 5024 off : Parameter "$1" not used}
Interface

Uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Buttons, LCLType, IniFiles,
  FormMain, FrameVideoPlayer, FrameVideoBase, FrameSyncedVideo,
  VehicleFolders, OptionsProperties;

Type

  { TfrmOptionsDVRWorkbench }

  TfrmOptionsDVRWorkbench = Class(TFormMain)
    lvFiles: TListView;
    memLog: TMemo;
    pnlVideo: TPanel;
    pcMain: TPageControl;
    Splitter1: TSplitter;
    splVideo: TSplitter;
    tbVideo: TToolBar;
    btnOpenVideoFolder: TToolButton;
    btnOpenAnomalyFolder: TToolButton;
    btnOpenStillsFolder: TToolButton;
    btnPlayFileA: TToolButton;
    btnAutoload: TToolButton;
    btnConfigureFolders: TToolButton;
    btnAutoplay: TToolButton;
    btnToggle: TToolButton;
    ToolButton2: TToolButton;
    ToolButton5: TToolButton;
    btnPlayFileB: TToolButton;
    btnPlayFileC: TToolButton;
    btnPlayFileD: TToolButton;
    tsLog: TTabSheet;
    tsVideo: TTabSheet;
    tbMain: TToolBar;
    btnScanFolders: TToolButton;
    tvFolders: TTreeView;
    Procedure btnAutoloadClick(Sender: TObject);
    Procedure btnConfigureFoldersClick(Sender: TObject);
    Procedure btnAutoplayClick(Sender: TObject);
    Procedure btnScanFoldersClick(Sender: TObject);
    Procedure btnOpenFolderClick(Sender: TObject);
    Procedure btnPlayFileClick(Sender: TObject);
    Procedure btnPlayInternalClick(Sender: TObject);
    Procedure btnToggleClick(Sender: TObject);
    Procedure FormCreate(Sender: TObject);
    Procedure FormDestroy(Sender: TObject);
    Procedure lvFilesSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    Procedure tvFoldersDeletion(Sender: TObject; Node: TTreeNode);
    Procedure tvFoldersSelectionChanged(Sender: TObject);
  Private
    FVehicleFolders: TVehicleFolders;
    FOptionsProperties: TOptionsProperties;
    FLastLogTick: QWord;
    FAutoload: Boolean;
    FAutoPlay: Boolean;
    FStartDateTime: TDateTime;

    fmeVideoPlayer: TFrameVideoPlayer;
    fmeSyncedVideo: TFrameSyncedVideo;

    Procedure ArrangeVideo(ARow: Boolean; ALength: Integer = -1);
    Procedure RefreshListViewControlPanel(AForceDisable: Boolean = False);
  Protected
    // Stored in %appdata% - Recommended for persisting user UI preferences
    Procedure LoadLocalSettings(oInifile: TIniFile); Override;
    Procedure SaveLocalSettings(oInifile: TIniFile); Override;

    // Stored in ini file with exe - what folders to load etc
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
  OSSupport, FileSupport,
  VideoEngineFactory, LibmpvSupport, ControlGridLayout,
  // Include all required video playback engines below this point
  FrameVideoLibmpv;

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
  FAutoload := False;
  FAutoPlay := True;

  // Override the need to use --configure
  FAlwaysSaveSettings := True;

  pcMain.ActivePage := tsVideo;

  memLog.Lines.Clear;

  RefreshListViewControlPanel;

  fmeVideoPlayer := TFrameVideoPlayer.Create(Self);
  fmeVideoPlayer.Parent := pnlVideo;
  fmeVideoPlayer.ShowLabel := True;
  fmeVideoPlayer.Autoplay := FAutoPlay;
  fmeVideoPlayer.Name := 'fmeVideoPlayer';
  fmeVideoPlayer.Align := alClient;

  // Change this line to swap playback engines.
  fmeVideoPlayer.VideoEngineClass := TFrameSyncedVideo;

  fmeSyncedVideo := nil;

  If assigned(fmeVideoPlayer.PlaybackFrame) Then
  Begin
    If fmeVideoPlayer.PlaybackFrame Is TFrameSyncedVideo Then
    Begin
      fmeSyncedVideo := TFrameSyncedVideo(fmeVideoPlayer.PlaybackFrame);
      fmeSyncedVideo.VideoEngineClass := TVideoEngineFactory.DefaultClass;
    End;
  End;
End;

Procedure TfrmOptionsDVRWorkbench.FormDestroy(Sender: TObject);
Begin
  FreeAndNil(fmeVideoPlayer);
  FreeAndNil(FOptionsProperties);
  FreeAndNil(FVehicleFolders);
End;

Procedure TfrmOptionsDVRWorkbench.btnScanFoldersClick(Sender: TObject);
Begin
  btnScanFolders.Enabled := False;
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
    btnScanFolders.Enabled := True;
    Busy := False;
  End;
End;

Procedure TfrmOptionsDVRWorkbench.btnAutoloadClick(Sender: TObject);
Begin
  FAutoload := Not FAutoload;

  btnAutoload.Down := FAutoload;

  If Not FAutoload Then
    fmeSyncedVideo.ClearUnloadedVideoFrames
  Else If Assigned(lvFiles.Selected) Then
    btnPlayInternalClick(nil);
End;

Procedure TfrmOptionsDVRWorkbench.btnConfigureFoldersClick(Sender: TObject);
Var
  dlgFolders: TdlgVehicleFolders;
Begin
  dlgFolders := TdlgVehicleFolders.Create(Self);
  Try
    dlgFolders.SetVehicleFolders(FVehicleFolders);
    If dlgFolders.ShowModal = mrOk Then
    Begin
      FVehicleFolders.Assign(dlgFolders.GetVehicleFolders);
    End;
  Finally
    FreeAndNil(dlgFolders);
  End;
End;

Procedure TfrmOptionsDVRWorkbench.btnAutoplayClick(Sender: TObject);
Begin
  FAutoPlay := Not FAutoPlay;
  fmeVideoPlayer.Autoplay := FAutoplay;

  btnAutoplay.Down := FAutoPlay;
End;

Procedure TfrmOptionsDVRWorkbench.btnOpenFolderClick(Sender: TObject);
Var
  sFolder, sFile: String;
Begin
  If Not (Sender Is TToolButton) Then
    Exit;

  If Not TToolButton(Sender).Enabled Then
    Exit;

  sFolder := TToolButton(Sender).Hint;
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
  If Not (Sender Is TToolButton) Then
    Exit;

  If Not TToolButton(Sender).Enabled Then
    Exit;

  sFile := TToolButton(Sender).Hint;

  If Assigned(lvFiles.Selected) Then
    lvFiles.Selected.Focused := True;

  If (sFile <> '') And FileExists(sFile) Then
    LaunchDocument(sFile);

  If Assigned(lvFiles.Selected) Then
    lvFiles.Selected.Focused := True;
End;

Procedure TfrmOptionsDVRWorkbench.btnPlayInternalClick(Sender: TObject);
Begin
  If Assigned(lvFiles.Selected) Then
  Begin
    Busy := True;
    BeginFormUpdate;
    Try
      If Not Assigned(fmeSyncedVideo) Then
        If assigned(fmeVideoPlayer.PlaybackFrame) Then
        Begin
          If fmeVideoPlayer.PlaybackFrame Is TFrameSyncedVideo Then
          Begin
            fmeSyncedVideo := TFrameSyncedVideo(fmeVideoPlayer.PlaybackFrame);
            fmeSyncedVideo.VideoEngineClass := TVideoEngineFactory.DefaultClass;
          End;
        End;

      If (btnPlayFileA.Enabled) And Assigned(fmeSyncedVideo) Then
      Begin
        fmeVideoPlayer.Autoplay := FAutoPlay;
        fmeSyncedVideo.Rate := 1.0;

        fmeSyncedVideo.BeginLoadVideos;
        Try
          If FileExists(btnPlayFileA.Hint) Then
            fmeSyncedVideo.Load(btnPlayFileA.Hint, 'A', FStartDateTime);

          If FileExists(btnPlayFileB.Hint) Then
            fmeSyncedVideo.Load(btnPlayFileB.Hint, 'B', FStartDateTime);

          If FileExists(btnPlayFileC.Hint) Then
            fmeSyncedVideo.Load(btnPlayFileC.Hint, 'C', FStartDateTime);

          If FileExists(btnPlayFileD.Hint) Then
            fmeSyncedVideo.Load(btnPlayFileD.Hint, 'D', FStartDateTime);
        Finally
          fmeSyncedVideo.EndLoadVideos;
        End;

        If fmeSyncedVideo.VideoFileCount > 0 Then
        Begin
          // Get the layout correct for the number of loaded videos
          If btnToggle.ImageIndex = 8 Then
            fmeSyncedVideo.Layout(1, fmeSyncedVideo.VideoFileCount, clsLeftToRightThenDown)
          Else
            fmeSyncedVideo.Layout(fmeSyncedVideo.VideoFileCount, 1, clsTopToBottomThenRight);

          // Play the video
          fmeSyncedVideo.Play;
          fmeVideoPlayer.RefreshUI;
        End;
      End;
    Finally
      EndFormUpdate;
      Busy := False;
    End;
  End;
End;

Procedure TfrmOptionsDVRWorkbench.btnToggleClick(Sender: TObject);
Begin
  BeginFormUpdate;
  Try
    If btnToggle.ImageIndex = 8 Then
      btnToggle.ImageIndex := 9
    Else
      btnToggle.ImageIndex := 8;

    ArrangeVideo(btnToggle.ImageIndex = 8);
  Finally
    EndFormUpdate;
  End;
End;

Procedure TfrmOptionsDVRWorkbench.ArrangeVideo(ARow: Boolean; ALength: Integer = -1);
Var
  iTemp: Integer;
Begin
  If ARow Then
  Begin
    btnToggle.ImageIndex := 8;
    If ALength = -1 Then
      iTemp := pnlVideo.Width
    Else
      iTemp := ALength;
    pnlVideo.Align := alBottom;
    pnlVideo.Height := iTemp;

    splVideo.Align := alBottom;
    splVideo.Top := pnlVideo.Top - splVideo.Height;

    fmeSyncedVideo.Layout(1, fmeSyncedVideo.VideoFileCount, clsLeftToRightThenDown);
  End
  Else
  Begin
    btnToggle.ImageIndex := 9;
    If ALength = -1 Then
      iTemp := pnlVideo.Height
    Else
      iTemp := ALength;

    pnlVideo.Align := alRight;
    pnlVideo.Width := iTemp;;

    splVideo.Align := alRight;
    splVideo.Left := pnlVideo.Left - splVideo.Width;

    fmeSyncedVideo.Layout(fmeSyncedVideo.VideoFileCount, 1, clsTopToBottomThenRight);
  End;

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
  bRow: Boolean;
  iLength: Longint;
Begin
  // Stored in ini file with exe - what folders to load etc
  Inherited;

  bRow := oInifile.ReadBool('Video', 'Layout As Row', True);
  iLength := oInifile.ReadInteger('Video', 'Length', pnlVideo.Height);
  ArrangeVideo(bRow, iLength);

  FAutoload := oInifile.ReadBool('Video', 'Autoload', False);
  FAutoPlay := oInifile.ReadBool('Video', 'Autoplay', True);

  FVehicleFolders.Clear;

  For i := 0 To oIniFile.ReadInteger('General', 'VehicleCount', 0) - 1 Do
  Begin
    sIniSection := Format('Vehicle%d', [i]);

    oVehicle := TVehicleFolder.Create;

    oVehicle.Folder := ExpandFolder(oIniFile.ReadString(sIniSection, 'Folder', ''));
    oVehicle.VesselCode := oIniFile.ReadString(sIniSection, 'VesselCode', '');
    oVehicle.VesselName := oIniFile.ReadString(sIniSection, 'VesselName', '');
    oVehicle.VehicleName := oIniFile.ReadString(sIniSection, 'VehicleName', '');
    oVehicle.VehicleClass := oIniFile.ReadString(sIniSection, 'VehicleClass', '');

    oVehicle.Exclude.Clear;

    For j := 0 To oIniFile.ReadInteger(sIniSection, 'ExcludeCount', 0) - 1 Do
      oVehicle.Exclude.Add(oIniFile.ReadString(sIniSection, Format('Exclude%d', [j]), ''));

    {%H-}FVehicleFolders.Add(oVehicle);
  End;

  fmeVideoPlayer.Autoplay := FAutoplay;
End;

Procedure TfrmOptionsDVRWorkbench.SaveGlobalSettings(oInifile: TIniFile);
Var
  i, j: Integer;
  oVehicle: TVehicleFolder;
  sIniSection: String;
Begin
  // Stored in ini file with exe - what folders to load etc
  Inherited;

  For i := 0 To FVehicleFolders.Count - 1 Do
    oInifile.EraseSection(Format('Vehicle%d', [i]));

  If btnToggle.ImageIndex = 8 Then
  Begin
    oInifile.WriteBool('Video', 'Layout As Row', True);
    oInifile.WriteInteger('Video', 'Length', pnlVideo.Height);
  End
  Else
  Begin
    oInifile.WriteBool('Video', 'Layout As Row', False);
    oInifile.WriteInteger('Video', 'Length', pnlVideo.Width);
  End;

  oInifile.WriteBool('Video', 'Autoload', FAutoload);
  oInifile.WriteBool('Video', 'Autoplay', FAutoPlay);

  oInifile.WriteInteger('General', 'VehicleCount', FVehicleFolders.Count);

  For i := 0 To FVehicleFolders.Count - 1 Do
  Begin
    oVehicle := FVehicleFolders[i];
    sIniSection := Format('Vehicle%d', [i]);

    oInifile.WriteString(sIniSection, 'Folder', ShrinkFolder(oVehicle.Folder));
    oInifile.WriteString(sIniSection, 'VesselCode', oVehicle.VesselCode);
    oInifile.WriteString(sIniSection, 'VesselName', oVehicle.VesselName);
    oInifile.WriteString(sIniSection, 'VehicleName', oVehicle.VehicleName);
    oInifile.WriteString(sIniSection, 'VehicleClass', oVehicle.VehicleClass);

    // Write the exclude TStringList
    oInifile.WriteInteger(sIniSection, 'ExcludeCount',
      oVehicle.Exclude.Count);

    For j := 0 To oVehicle.Exclude.Count - 1 Do
      oInifile.WriteString(sIniSection, Format('Exclude%d', [j]), oVehicle.Exclude[j]);
  End;
End;

Procedure TfrmOptionsDVRWorkbench.RefreshListViewControlPanel(AForceDisable: Boolean);
Var
  sVideoFolder, sFileA, sAnomalyFolder, sStillsFolder, sFileB, sFileC, sFileD, sDateTime: String;
  oItem: TListItem;
Begin
  btnOpenVideoFolder.Enabled := False;
  btnOpenAnomalyFolder.Enabled := False;
  btnOpenStillsFolder.Enabled := False;

  btnPlayFileA.Enabled := False;
  btnPlayFileB.Enabled := False;
  btnPlayFileC.Enabled := False;
  btnPlayFileD.Enabled := False;

  btnAutoLoad.Enabled := False;
  btnAutoplay.Enabled := False;
  btnToggle.Enabled := False;

  If AForceDisable Then
    Exit;

  If (lvFiles.Items.Count = 0) Then
    Exit;

  btnToggle.Enabled := True;
  btnAutoLoad.Enabled := True;
  btnAutoload.Down := FAutoload;

  // TODO Fix dynamic changes
  //btnAutoplay.Enabled := False;
  btnAutoplay.Down := FAutoPlay;

  oItem := lvFiles.Selected;

  If Not Assigned(oItem) Then
    Exit;

  If lvFiles.SelCount <> 1 Then
    Exit;

  If oItem.SubItems.Count < 4 Then
    Exit;

  //  REALLY need to be storing this in a DB and retrieving.  Not this hack...
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

  sDateTime := oItem.SubItems[1];
  FStartDateTime := ScanDateTime('yyyy-mm-dd hh:nn:ss', sDateTime);

  If btnAutoload.Down Then
    btnPlayInternalClick(nil);
End;

Procedure TfrmOptionsDVRWorkbench.LoadLocalSettings(oInifile: TIniFile);
Begin
  // Stored in %appdata% - Recommended for persisting user UI preferences
  Inherited LoadLocalSettings(oInifile);
End;

Procedure TfrmOptionsDVRWorkbench.SaveLocalSettings(oInifile: TIniFile);
Begin
  // Stored in %appdata% - Recommended for persisting user UI preferences
  Inherited SaveLocalSettings(oInifile);
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
