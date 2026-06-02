Unit OptionsDVRSupport;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, ComCtrls, OptionsProperties;

Type
  TFolderTreeNodeData = Class
    RelativePath: String;  // e.g. Jotun_FPSO_Marine_Subsea\Mooring_Line\ML1
  End;

// MainForm helpers
Procedure PopulateOptionsDVRTreeView(ATreeView: TTreeView; AOptionsProperties: TOptionsProperties);
Procedure PopulateFilesListForFolder(AListView: TListView; AOptionsProperties: TOptionsProperties;
  Const ARelativePath: String);

// TODO, this belongs in OptionsProperties
Function GetRelativeOptionsFolder(AOptionsProperty: TOptionsProperty): String;

// Sort Routines
Function CompareOptionsPropertyStartDate(Const Left, Right: TOptionsProperty): Integer;
Procedure SortOptionsPropertiesByStartDate(AOptionsProperties: TOptionsProperties);

Implementation

Uses
  VehicleFolders, StringSupport, OSSupport, FormMain;

Procedure PopulateFilesListForFolder(AListView: TListView; AOptionsProperties: TOptionsProperties;
  Const ARelativePath: String);
Var
  i: Integer;
  Prop: TOptionsProperty;
  PropRelativePath: String;
  Item: TListItem;
Begin
  AListView.Items.BeginUpdate;
  SetBusy;
  Try
    AListView.Items.Clear;

    For i := 0 To AOptionsProperties.Count - 1 Do
    Begin
      Prop := AOptionsProperties[i];

      PropRelativePath := GetRelativeOptionsFolder(Prop);

      If SameText(PropRelativePath, ARelativePath) Or
        SameText(Copy(PropRelativePath, 1, Length(ARelativePath) + 1),
        ARelativePath + PathDelim) Then
      Begin
        Item := AListView.Items.Add;
        Item.Caption := Prop.VideoFile0;
        Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss', Prop.StartDate));
        Item.SubItems.Add(FormatDateTime('HH:nn:ss', Abs(Prop.EndDate-Prop.StartDate)));
        Item.SubItems.Add(Prop.Folder);
        Item.Data := Prop;
      End;
    End;
  Finally
    ClearBusy;
    AListView.Items.EndUpdate;
  End;
End;

Procedure PopulateOptionsDVRTreeView(ATreeView: TTreeView; AOptionsProperties: TOptionsProperties);

  Function StripDataLeafFolder(Const AFolder: String): String;
  Begin
    Result := ExcludeTrailingPathDelimiter(AFolder);

    If Pos('DATA_', UpperCase(ExtractFileName(Result))) = 1 Then
      Result := ExtractFileDir(Result);
  End;

  Function RemoveScanRoot(Const AFolder: String; AVehicleFolder: TVehicleFolder): String;
  Var
    ScanRoot: String;
  Begin
    ScanRoot :=
      IncludeTrailingPathDelimiter(AVehicleFolder.Folder) + 'Data' + PathDelim +
      AVehicleFolder.VesselCode;

    ScanRoot :=
      IncludeTrailingPathDelimiter(AVehicleFolder.Folder) + 'Data' + PathDelim +
      AVehicleFolder.VesselCode;

    If SameText(Copy(AFolder, 1, Length(ScanRoot)), ScanRoot) Then
      Result := Copy(AFolder, Length(ScanRoot) + 1, MaxInt)
    Else
      Result := AFolder;
  End;

  Function RemoveVehicleNameFolders(Const APath: String;
    AVehicleFolder: TVehicleFolder): String;
  Begin
    Result := APath;

    Result := StringReplace(Result, PathDelim + AVehicleFolder.VehicleName +
      PathDelim, PathDelim, [rfReplaceAll, rfIgnoreCase]);

    If SameText(ExtractFileName(Result), AVehicleFolder.VehicleName) Then
      Result := ExtractFileDir(Result);

    Result := ExcludeTrailingPathDelimiter(Result);
  End;

  Procedure SplitPath(Const APath: String; AParts: TStringList);
  Var
    s: String;
    p: Integer;
  Begin
    AParts.Clear;
    s := APath;

    Repeat
      p := Pos(PathDelim, s);

      If p > 0 Then
      Begin
        If Copy(s, 1, p - 1) <> '' Then
          AParts.Add(Copy(s, 1, p - 1));

        Delete(s, 1, p);
      End
      Else
      Begin
        If s <> '' Then
          AParts.Add(s);
      End;
    Until p = 0;
  End;

  Function FindChildNode(AParent: TTreeNode; Const AText: String): TTreeNode;
  Var
    Node: TTreeNode;
  Begin
    Result := nil;

    If Assigned(AParent) Then
      Node := AParent.GetFirstChild
    Else
      Node := ATreeView.Items.GetFirstNode;

    While Assigned(Node) Do
    Begin
      If SameText(Node.Text, AText) Then
        Exit(Node);

      Node := Node.GetNextSibling;
    End;
  End;

  Procedure AddPathToTree(AParts: TStringList);
  Var
    i: Integer;
    ParentNode, Node: TTreeNode;
  Begin
    ParentNode := nil;

    For i := 0 To AParts.Count - 1 Do
    Begin
      Node := FindChildNode(ParentNode, AParts[i]);

      If Not Assigned(Node) Then
      Begin
        If Assigned(ParentNode) Then
          Node := ATreeView.Items.AddChild(ParentNode, AParts[i])
        Else
          Node := ATreeView.Items.Add(nil, AParts[i]);

        Node.Data := TFolderTreeNodeData.Create;

        TFolderTreeNodeData(Node.Data).RelativePath :=
          BuildPathFromParts(AParts, i + 1);
      End;

      ParentNode := Node;
    End;
  End;

Var
  i: Integer;
  Prop: TOptionsProperty;
  RelativePath: String;
  Parts: TStringList;
Begin
  Parts := TStringList.Create;
  ATreeView.Items.BeginUpdate;
  SetBusy;
  Try
    ATreeView.Items.Clear;

    For i := 0 To AOptionsProperties.Count - 1 Do
    Begin
      Prop := AOptionsProperties[i];

      If Not Assigned(Prop.VehicleFolder) Then
        Continue;

      RelativePath := StripDataLeafFolder(Prop.Folder);
      RelativePath := RemoveScanRoot(RelativePath, Prop.VehicleFolder);
      RelativePath := RemoveVehicleNameFolders(RelativePath, Prop.VehicleFolder);

      SplitPath(RelativePath, Parts);

      If Parts.Count > 0 Then
        AddPathToTree(Parts);
    End;

  Finally
    ClearBusy;
    ATreeView.Items.EndUpdate;
    ATreeView.AlphaSort;
    ATreeView.FullCollapse;
    Parts.Free;
  End;
End;

Function GetRelativeOptionsFolder(AOptionsProperty: TOptionsProperty): String;
Var
  ScanRoot: String;
  VehicleFolder: TVehicleFolder;
Begin
  Result := '';

  If Not Assigned(AOptionsProperty) Then
    Exit;

  If Not Assigned(AOptionsProperty.VehicleFolder) Then
    Exit;

  VehicleFolder := AOptionsProperty.VehicleFolder;

  Result := ExcludeTrailingPathDelimiter(AOptionsProperty.Folder);

  // Remove leaf DATA_yyyy...
  If Pos('DATA_', UpperCase(ExtractFileName(Result))) = 1 Then
    Result := ExtractFileDir(Result);

  // Remove base scan root:
  // <BaseFolder>\Data\<VesselCode>\
  ScanRoot :=
    IncludeTrailingPathDelimiter(VehicleFolder.Folder) + 'Data' + PathDelim +
    VehicleFolder.VesselCode;

  ScanRoot := IncludeTrailingPathDelimiter(ScanRoot);

  If SameText(Copy(Result, 1, Length(ScanRoot)), ScanRoot) Then
    Result := Copy(Result, Length(ScanRoot) + 1, MaxInt);

  // Remove vehicle name wherever it is a path element
  Result := StringReplace(Result, PathDelim + VehicleFolder.VehicleName +
    PathDelim, PathDelim, [rfReplaceAll, rfIgnoreCase]);

  // Remove vehicle name if final folder
  If SameText(ExtractFileName(Result), VehicleFolder.VehicleName) Then
    Result := ExtractFileDir(Result);

  Result := ExcludeTrailingPathDelimiter(Result);
End;

Function CompareOptionsPropertyStartDate(Const Left, Right: TOptionsProperty): Integer;
Begin
  If Left.StartDate < Right.StartDate Then
    Result := -1
  Else If Left.StartDate > Right.StartDate Then
    Result := 1
  Else
    Result := 0;
End;

Procedure SortOptionsPropertiesByStartDate(AOptionsProperties: TOptionsProperties);
Begin
  If Not Assigned(AOptionsProperties) Then
    Exit;

  AOptionsProperties.Sort(@CompareOptionsPropertyStartDate);
End;

End.
