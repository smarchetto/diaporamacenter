unit DiaporamaEntity;

interface

type
  TDiaporamaEntity = class
  protected
    // ID
    FID: string;
    // Index in diaporama
    FIndex: Integer;
  public
    constructor Create(const anID: string;
      const anIndex: Integer=-1); virtual;

    property ID: string read FID;
    property Index: Integer read FIndex;
  end;

implementation

uses
  SysUtils,
  Diapositive, Diaporama;

{$REGION 'DiaporamaSortFunctions'}

function SortDiaporamaByIndex(Item1, Item2: Pointer): Integer;
var
  diapoEntity1, diapoEntity2: TDiaporamaEntity;
begin
  diapoEntity1 := TDiaporamaEntity(Item1);
  diapoEntity2 := TDiaporamaEntity(Item2);
  if Assigned(diapoEntity1) and Assigned(diapoEntity2) then
    Result := diapoEntity1.Index-diapoEntity2.Index
  else
    Result := 0;
end;

function SortDiaporamaById(Item1, Item2: Pointer): Integer;
var
  diapoEntity1, diapoEntity2: TDiaporamaEntity;
begin
  diapoEntity1 := TDiaporamaEntity(Item1);
  diapoEntity2 := TDiaporamaEntity(Item2);
  if Assigned(diapoEntity1) and Assigned(diapoEntity2) then
  begin
    if diapoEntity1.ClassType=diapoEntity2.ClassType then
      Result := CompareText(diapoEntity1.ID, diapoEntity2.ID)
    else if diapoEntity1 is TDiapositive then
      Result := -1
    else
      Result := 1;
  end else
    Result := 0;
end;

function SortDiaporamaByType(Item1, Item2: Pointer): Integer;
var
  diapoEntity1, diapoEntity2: TDiaporamaEntity;
  str1, str2: string;
begin
  diapoEntity1 := TDiaporamaEntity(Item1);
  diapoEntity2 := TDiaporamaEntity(Item2);
  if Assigned(diapoEntity1) and Assigned(diapoEntity2) then
  begin
    if diapoEntity1.ClassType=diapoEntity2.ClassType then
    begin
      if diapoEntity1 is TDiaporama then
        Result := CompareText(TDiaporama(diapoEntity1).Name,
          TDiaporama(diapoEntity2).Name)
      else
      begin
        if Assigned(TDiapositive(diapoEntity1).DiapositiveType) then
          str1 := TDiapositive(diapoEntity1).DiapositiveType.Name
        else
          str1 := '';
        if Assigned(TDiapositive(diapoEntity2).DiapositiveType) then
          str2 := TDiapositive(diapoEntity2).DiapositiveType.Name
        else
          str2 := '';
        if not SameText(str1, str2) then
          Result := CompareText(str1, str2)
        else
          Result := CompareText(diapoEntity1.ID, diapoEntity2.ID);
      end;
    end
    else if diapoEntity1 is TDiapositive then
      Result := -1
    else
      Result := 1;
  end else
    Result := 0;
end;

{$ENDREGION}

constructor TDiaporamaEntity.Create(const anID: string;
  const anIndex: Integer=-1);
begin
  FId := anId;
  FIndex := anIndex;
end;


end.
