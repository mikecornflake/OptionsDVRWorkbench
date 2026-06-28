Unit OIS.Database;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, SQLite3Conn, SQLDB;

Type
  EOISDatabase = Class(Exception);

  TOISDatabase = Class
  Private
    FConnection: TSQLite3Connection;
    FTransaction: TSQLTransaction;
    FDatabaseFilename: String;

    Procedure CheckOpen;
    Procedure ExecuteStatement(Const ASQL: String);

  Public
    Constructor Create;
    Destructor Destroy; Override;

    Class Function DatabaseExists(Const AFilename: String): Boolean;

    Procedure OpenDatabase(Const AFilename: String);
    Procedure CloseDatabase;

    Procedure CreateDatabase(Const AFilename: String; Const ACreateSQL: String);
    Procedure ExecuteSQLScript(Const ASQL: String);

    Function IsOpen: Boolean;
    Function SchemaVersion: Integer;

    Property Connection: TSQLite3Connection Read FConnection;
    Property Transaction: TSQLTransaction Read FTransaction;
    Property DatabaseFilename: String Read FDatabaseFilename;
  End;

Implementation

{ TOISDatabase }

Constructor TOISDatabase.Create;
Begin
  Inherited Create;

  FConnection := TSQLite3Connection.Create(Nil);
  FTransaction := TSQLTransaction.Create(Nil);

  FConnection.Transaction := FTransaction;
  FTransaction.Database := FConnection;
End;

Destructor TOISDatabase.Destroy;
Begin
  CloseDatabase;

  FTransaction.Free;
  FConnection.Free;

  Inherited Destroy;
End;

Class Function TOISDatabase.DatabaseExists(Const AFilename: String): Boolean;
Begin
  Result := FileExists(AFilename);
End;

Function TOISDatabase.IsOpen: Boolean;
Begin
  Result := Assigned(FConnection) And FConnection.Connected;
End;

Procedure TOISDatabase.OpenDatabase(Const AFilename: String);
Begin
  If Trim(AFilename) = '' Then
    Raise EOISDatabase.Create('Database filename is blank');

  CloseDatabase;

  FDatabaseFilename := AFilename;
  FConnection.DatabaseName := AFilename;
  FConnection.Connected := True;

  ExecuteStatement('PRAGMA foreign_keys = ON;');
End;

Procedure TOISDatabase.CloseDatabase;
Begin
  If Assigned(FTransaction) And FTransaction.Active Then
    FTransaction.Rollback;

  If Assigned(FConnection) And FConnection.Connected Then
    FConnection.Connected := False;

  FDatabaseFilename := '';
End;

Procedure TOISDatabase.CheckOpen;
Begin
  If Not IsOpen Then
    Raise EOISDatabase.Create('Database is not open');
End;

Procedure TOISDatabase.CreateDatabase(Const AFilename: String; Const ACreateSQL: String);
Begin
  If Trim(AFilename) = '' Then
    Raise EOISDatabase.Create('Database filename is blank');

  If FileExists(AFilename) Then
    Raise EOISDatabase.CreateFmt('Database already exists: %s', [AFilename]);

  OpenDatabase(AFilename);
  ExecuteSQLScript(ACreateSQL);
End;

Function TOISDatabase.SchemaVersion: Integer;
Var
  Query: TSQLQuery;
Begin
  CheckOpen;

  Query := TSQLQuery.Create(Nil);
  Try
    Query.Database := FConnection;
    Query.Transaction := FTransaction;
    Query.SQL.Text := 'PRAGMA user_version;';
    Query.Open;

    Result := Query.Fields[0].AsInteger;
  Finally
    Query.Free;
  End;
End;

Procedure TOISDatabase.ExecuteStatement(Const ASQL: String);
Var
  Query: TSQLQuery;
Begin
  CheckOpen;

  If Trim(ASQL) = '' Then
    Exit;

  Query := TSQLQuery.Create(Nil);
  Try
    Query.Database := FConnection;
    Query.Transaction := FTransaction;
    Query.SQL.Text := ASQL;
    Query.ExecSQL;
  Finally
    Query.Free;
  End;
End;

Procedure TOISDatabase.ExecuteSQLScript(Const ASQL: String);
Var
  Script: TStringList;
  i: Integer;
  Statement: String;
  Line: String;
Begin
  CheckOpen;

  Script := TStringList.Create;
  Try
    Script.Text := ASQL;
    Statement := '';

    FTransaction.StartTransaction;
    Try
      For i := 0 To Script.Count - 1 Do
      Begin
        Line := Trim(Script[i]);

        If Line = '' Then
          Continue;

        If Copy(Line, 1, 2) = '--' Then
          Continue;

        Statement := Statement + Script[i] + LineEnding;

        If Pos(';', Line) = Length(Line) Then
        Begin
          ExecuteStatement(Statement);
          Statement := '';
        End;
      End;

      If Trim(Statement) <> '' Then
        ExecuteStatement(Statement);

      FTransaction.Commit;
    Except
      If FTransaction.Active Then
        FTransaction.Rollback;
      Raise;
    End;
  Finally
    Script.Free;
  End;
End;

End.