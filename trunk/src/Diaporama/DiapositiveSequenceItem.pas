unit DiapositiveSequenceItem;

interface

uses
  Generics.Defaults, Generics.Collections,
  Diaporama, Diapositive, SequenceItem;

type
  TDiapositiveSequenceItem = class;

  // Enumerator of diapositives given a diapositive sequence settings item
  // Differences with TDiaporamaEnumerator :
  // It only takes account of diapositives of the diaporama,
  // and not the diapositives from diaporama imported
  TDiapositiveEnumerator = class(TEnumerator)
  private
    // Diapositive sequence settings item
    FDiapositiveSequenceItem: TDiapositiveSequenceItem;
    // Play order
    FPlayList: TObjectList<TDiapositive>;
  protected
    function GetCurrent: TDiapositive; override;
  public
    constructor Create(const aDiaporama: TDiaporama;
      const diapositiveSequenceItem: TDiapositiveSequenceItem); reintroduce;
    destructor Destroy; override;

    function MoveNext: Boolean; override;
  end;

  // Sequence settings item to specify to an play order of diapositives
  TDiapositiveSequenceItem = class(TSequenceItem)
  private
    // Settings to specify a specific type of diapositive to be played
    FDiapositiveType: string;
    // Settings to specify a specific ID of diapositive to be played
    FDiapositiveID: string;
  public
    constructor Create(const aDiapositiveType: string;
      const aDiapositiveId: string;
      const nbDiapositive: Integer); overload;

    function GetEnumerator(const aDiaporama: TObject): TEnumerator; override;

    property DiapositiveType: string read FDiapositiveType;
    property DiapositiveID: string read FDiapositiveID;
  end;


implementation

uses
  Math, SysUtils;

{$REGION 'TDiapositiveEnumerator'}

constructor TDiapositiveEnumerator.Create(
  const aDiaporama: TDiaporama;
  const diapositiveSequenceItem: TDiapositiveSequenceItem);
var
  aDiapositive: TDiapositive;
  i: Integer;
begin
  inherited Create(aDiaporama);

  FPlayList := TObjectList<TDiapositive>.Create(False);

  FDiapositiveSequenceItem := diapositiveSequenceItem;

  if not Assigned(FDiapositiveSequenceItem) or not Assigned(FDiaporama) then
    Exit;

  if FDiapositiveSequenceItem.DiapositiveType<>'' then
  begin    
    for i := 0 to aDiaporama.DiapositiveCount - 1 do
    begin
      aDiapositive := aDiaporama.Diapositive[i];
      if SameText(aDiapositive.DiapositiveType.Name,
        diapositiveSequenceItem.DiapositiveType) then
        FPlayList.Add(aDiapositive);
    end;
  end
  else if diapositiveSequenceItem.DiapositiveID<>'' then
  begin
    for i := 0 to aDiaporama.DiapositiveCount - 1 do
    begin
      aDiapositive := aDiaporama.Diapositive[i];
      if SameText(aDiapositive.ID,
        diapositiveSequenceItem.DiapositiveID) then
        FPlayList.Add(aDiapositive);
    end;
  end;
end;

destructor TDiapositiveEnumerator.Destroy;
begin
  FPlayList.Free;
  inherited;
end;

function TDiapositiveEnumerator.GetCurrent: TDiapositive;
begin
  if FIndex<0 then
    FIndex := 0;
  if FIndex<FPlayList.Count then
    Result := FPlayList[FIndex]
  else
    Result := nil;
end;

function TDiapositiveEnumerator.MoveNext: Boolean;
begin
  Inc(FIndex);
  if FIndex>FPlayList.Count-1 then
    FIndex := 0;
  Result := True;
end;

{$ENDREGION}

{$REGION 'TDiapositiveSequenceItem'}

constructor TDiapositiveSequenceItem.Create(
  const aDiapositiveType: string;
  const aDiapositiveID: string;
  const nbDiapositive: Integer);
begin
  FDiapositiveType := aDiapositiveType;
  FDiapositiveID := aDiapositiveID;
  FNbDiapositive := Max(nbDiapositive, 1);
end;

function TDiapositiveSequenceItem.GetEnumerator(
  const aDiaporama: TObject): TEnumerator;
begin
  Result := inherited GetEnumerator(aDiaporama); 
  if not Assigned(FEnumerator) then
  begin
    FEnumerator := TDiapositiveEnumerator.Create(TDiaporama(aDiaporama), Self);
    Result := FEnumerator;
  end;
end;

{$ENDREGION}


end.
