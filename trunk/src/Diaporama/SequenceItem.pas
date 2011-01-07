unit SequenceItem;

interface

uses
  Diapositive;

type
  TSequenceItem = class;

  // Generic diapositive enumerator, bases on a sequence settings
  TEnumerator = class
  protected
    // Link to diaporama
    FDiaporama: TObject;
    // Counter for enumerating
    FIndex: Integer;

    function GetCurrent: TDiapositive; virtual; abstract;
  public
    constructor Create(const aDiaporama: TObject); virtual;

    function MoveNext: Boolean; virtual; abstract;

    property Diaporama: TObject read FDiaporama;
    property Current: TDiapositive read GetCurrent;
  end;

  // Generic sequence settings item
  TSequenceItem = class
  protected
    // Number of diapositives to play
    FNbDiapositive: integer;
    // Enumerator associated
    FEnumerator: TEnumerator;
  public
    function GetEnumerator(
      const aDiaporama: TObject): TEnumerator; virtual;

    property NbDiapositive: Integer read FNbDiapositive;
  end;

implementation

uses
  SysUtils;

constructor TEnumerator.Create(const aDiaporama: TObject);
begin
  FDiaporama := aDiaporama;
  FIndex := -1;
end;


function TSequenceItem.GetEnumerator(const aDiaporama: TObject): TEnumerator;
begin
  if Assigned(FEnumerator) and (FEnumerator.Diaporama<>aDiaporama) then
    FreeAndNil(FEnumerator);
  Result := FEnumerator;
end;



end.
