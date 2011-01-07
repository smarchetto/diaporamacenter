unit DiaporamaSequenceItem;

interface

uses
  Diaporama, Diapositive, SequenceItem;

type
  TDiaporamaSequenceOrder = (soNormal, soID, soRandom);

  TDiaporamaSequenceItem = class;

  // Enumerator of diapositives given a diaporama sequence settings item
  TDiaporamaEnumerator = class(TEnumerator)
  private
    // TO COMMENT
    FDiaporamaSequenceItem: TDiaporamaSequenceItem;
    // Counter for enumerator
    FDiapositiveCounter: Integer;

    function CheckDiaporama: Boolean;
    function Checksequence: Boolean;
    function GetDiaporama: TDiaporama;
  protected
    function GetCurrent: TDiapositive; override;
  public
    constructor Create(const aDiaporama: TDiaporama;
      const diaporamaSequenceItem: TDiaporamaSequenceItem); reintroduce;

    function MoveNext: Boolean; override;

    function GetCurrentDiapositiveDuration: Integer;
  end;

  // Sequence settings item to specify to play a diaporama
  TDiaporamaSequenceItem = class(TSequenceItem)
  private
    // Link to diaporama to be played
    FDiaporamaName: string;
    // Duration of diapositive
    FDiapositiveDuration: Integer;
    // Playing order of the diaporama : normal, random
    FOrder: TDiaporamaSequenceOrder;
    // Default sequence
    class var FDefaultSequence: TDiaporamaSequenceItem;
  public
    constructor Create(const aDiaporama: string;
      const aNbDiapositive: Integer;
      const aDiapositiveDuration: Integer;
      const anOrder: TDiaporamaSequenceOrder);

    function GetEnumerator(const aDiaporama: TObject): TEnumerator; override;

    property DiaporamaName: string read FDiaporamaName;

    property DiapositiveDuration: Integer read FDiapositiveDuration
      write FDiapositiveDuration;

    property Order: TDiaporamaSequenceOrder read FOrder;

    class property DefaultSequence: TDiaporamaSequenceItem read
      FDefaultSequence;
  end;

implementation

uses
  SysUtils,
  DiapositiveSequenceItem;

{$REGION 'TDiaporamaEnumerator'}

function TDiaporamaEnumerator.GetDiaporama: TDiaporama;
begin
  Result := TDiaporama(FDiaporama);
end;

constructor TDiaporamaEnumerator.Create(const aDiaporama: TDiaporama;
  const diaporamaSequenceItem: TDiaporamaSequenceItem);
begin
  inherited Create(aDiaporama);
  FDiaporamaSequenceItem := diaporamaSequenceItem;
  FDiapositiveCounter := 0;
end;

// Checks diaporama associated to sequence
function TDiaporamaEnumerator.CheckDiaporama: Boolean;
begin
  Result := Assigned(FDiaporama) and GetDiaporama.HasContent;
end;

// Checks sequence of diaporama
function TDiaporamaEnumerator.CheckSequence: Boolean;
begin
  Result := Assigned(GetDiaporama.Sequence) and
    (GetDiaporama.Sequence.ItemCount>0);
end;

// Move to next diapositive
function TDiaporamaEnumerator.MoveNext: Boolean;
var
  sequenceItem: TSequenceItem;
  aDiaporama: TDiaporama;
  diaporamaName: string;
begin
  Result := False;

  if not CheckDiaporama then
    Exit;

  // Is there any sequence ?
  if not CheckSequence then
  begin
    // No, then use defaut sequence if exist
    if Assigned(FDiaporamaSequenceItem) then
    begin
      // Enumerate in diaporama
      case FDiaporamaSequenceItem.Order of
        soRandom: FIndex := Random(GetDiaporama.ItemCount);
        soNormal: Inc(FIndex);
      end;

      if FIndex>GetDiaporama.ItemCount-1 then
        FIndex := 0;

      Result := True;
    end;
  end else
  begin
    // Yes, if enumeration has started
    if FIndex<>-1 then
    begin
      sequenceItem := GetDiaporama.Sequence.Item[FIndex];

      if Assigned(sequenceItem) then
      begin
        // A t-on lu le nombre demandé de diapositives pour cet item
        if FDiapositiveCounter<sequenceItem.NbDiapositive-1 then
        begin
          // Lecture de diaporama importe => on recupere le diaporama
          if sequenceItem is TDiaporamaSequenceItem then
          begin
            DiaporamaName := TDiaporamaSequenceItem(sequenceItem).DiaporamaName;
            aDiaporama := GetDiaporama.GetDiaporama(diaporamaName);
          end else
            // Lecture de diapositive => on renvoit le diaporama courant
            aDiaporama := GetDiaporama;

          // Donc encore une diapositive pour ce diaporama
          Result := sequenceItem.GetEnumerator(aDiaporama).MoveNext;

          // On incremente le compteur de diapositive
          Inc(FDiapositiveCounter);

          Exit;
        end else
        begin
          // Oui, fini pour cet item, on passe au prochain dans la sequence
          FDiapositiveCounter := 0;
          // TODO : Result=True à revoir dans MoveNext
          Result := True;
        end;
      end;

      // Move to next sequence item
      Inc(FIndex);
      if FIndex>GetDiaporama.Sequence.ItemCount-1 then
        FIndex := 0;
    end else
      FIndex := 0;
  end;
end;

// Returns the sequence current diapositive
function TDiaporamaEnumerator.GetCurrent: TDiapositive;
var
  sequenceItem: TSequenceItem;
  aDiaporama: TDiaporama;
  diaporamaSequenceItem: TDiaporamaSequenceItem;
begin
  Result := nil;

  if not CheckDiaporama then
    Exit;

  if not CheckSequence then
  begin
    // TODO : depends on order of parent sequence
    if Assigned(FDiaporamaSequenceItem) then
      Result := GetDiaporama.Diapositive[FIndex];
    Exit;
  end;

  // Start sequence if needed
  if FIndex=-1 then
    MoveNext;

  // Get current sequence item
  sequenceItem := GetDiaporama.Sequence.Item[FIndex];

  if Assigned(sequenceItem) then
  begin
    // If we are in a diaporama sequence item, get the diaporama
    if sequenceItem is TDiaporamaSequenceItem then
    begin
      diaporamaSequenceItem := TDiaporamaSequenceItem(sequenceItem);
      aDiaporama := GetDiaporama.GetDiaporama(diaporamaSequenceItem.DiaporamaName)
    end else
      aDiaporama := GetDiaporama;

    if Assigned(aDiaporama) then
    begin
      // Diaporama enumerator returns current diapositive
      Result := sequenceItem.GetEnumerator(aDiaporama).Current;
    end else
    begin
      // Diaporama does not exist, so move to next sequence item
      MoveNext;
      Result := GetCurrent;
    end;
  end;
end;

function TDiaporamaEnumerator.GetCurrentDiapositiveDuration: Integer;
begin
  // Priority to duration defined in parent diaporama sequence item
  if Assigned(FDiaporamaSequenceItem) then
      Result := FDiaporamaSequenceItem.DiapositiveDuration
  else
  // Otherwise duration is got from this sequence diaporama
  if Assigned(GetDiaporama.Sequence) then
    Result := GetDiaporama.Sequence.DiapositiveDuration
  else
    // -1 means default duration
    Result := -1;
end;

{$ENDREGION 'TDiaporamaEnumerator'}

{$REGION 'TDiaporamaSequenceItem'}

constructor TDiaporamaSequenceItem.Create(
  const aDiaporama: string;
  const aNbDiapositive: Integer;
  const aDiapositiveDuration: Integer;
  const anOrder: TDiaporamaSequenceOrder);
begin
  FDiaporamaName := aDiaporama;
  FNbDiapositive := aNbDiapositive;
  FDiapositiveDuration := aDiapositiveDuration;
  FOrder := anOrder;
end;

function TDiaporamaSequenceItem.GetEnumerator(
  const aDiaporama: TObject): TEnumerator;
begin
  Result := inherited GetEnumerator(aDiaporama);
  if not Assigned(FEnumerator) then
  begin
    FEnumerator := TDiaporamaEnumerator.Create(TDiaporama(aDiaporama), Self);
    Result := FEnumerator;
  end;
end;

{$ENDREGION 'TDiaporamaSequenceItem'}

initialization
  //TDiaporamaSequenceItem.FDefaultSequence :=
  //  TDiaporamaSequenceItem.Create('', -1, DEFAULT_DURATION, soNormal);

finalization
  //FreeAndNil(TDiaporamaSequenceItem.FDefaultSequence);

end.
