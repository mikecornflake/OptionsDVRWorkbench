Unit OIS.Support;

{$mode ObjFPC}{$H+}

Interface

Uses
  Classes, SysUtils, DateUtils;

Function OISDateTimeToSQL(Const ADateTime: TDateTime): String;
Function SQLToOISDateTime(Const AValue: String): TDateTime;
Function OISDateTimeIsNull(Const ADateTime: TDateTime): Boolean;
Function OISSQLDateTimeIsNull(Const AValue: String): Boolean;

Implementation

Function OISDateTimeIsNull(Const ADateTime: TDateTime): Boolean;
Begin
  Result := ADateTime = 0;
End;

Function OISSQLDateTimeIsNull(Const AValue: String): Boolean;
Begin
  Result := Trim(AValue) = '';
End;

Function OISDateTimeToSQL(Const ADateTime: TDateTime): String;
Begin
  If OISDateTimeIsNull(ADateTime) Then
    Result := ''
  Else
    Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', ADateTime);
End;

Function SQLToOISDateTime(Const AValue: String): TDateTime;
Begin
  If OISSQLDateTimeIsNull(AValue) Then
    Exit(0);

  Result := ScanDateTime('yyyy-mm-dd"T"hh:nn:ss', Copy(AValue, 1, 19));
End;

End.
