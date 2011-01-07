unit Sequence;

interface

uses
  Generics.Defaults, Generics.Collections, MSXML2_TLB,
  SequenceItem;

type
  // A diaporama sequence is the playing order of diapositives of the diaporama
  // TSequence is the container of the sequence settings
  // This one is composed of several sequence item settings
  TSequence = class
  private
    FItems: TObjectList<TSequenceItem>;
    FDiapositiveDuration: Integer;

    function getItem(const index: Integer): TSequenceItem;
    function getItemCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    procedure LoadFromXML(const sequenceNode: IXMLDomNode);
    //procedure SaveToXML(const parentNode: IXMLDomNode);

    property Item[const index: Integer]: TSequenceItem read getItem;
    property ItemCount: Integer read getItemCount;
    property DiapositiveDuration: Integer read FDiapositiveDuration;
    var
  end;

implementation

uses
  SysUtils,
  DiaporamaSequenceItem, DiapositiveSequenceItem,
  DiapositiveType, Diaporama, DiaporamaUtils;

const
  // XML markups
  cstPlayDiapositiveNode = 'playDiapositive';
  cstPlayDiaporamaNode = 'playDiaporama';
  cstPlayNbDiapositiveAttr = 'nbDiapositive';
  cstPlayDiapositiveTypeAttr = 'type';
  cstPlayDiapositiveIDAttr = 'id';
  cstPlayDiaporamaNameAttr = 'name';
  cstPlayDiaporamaDurationAttr = 'duration';
  cstPlayDiaporamaOrderAttr = 'order';

constructor TSequence.Create;
begin
  FItems := TObjectList<TSequenceItem>.Create;
  FDiapositiveDuration := -1;
end;

destructor TSequence.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TSequence.Clear;
begin
  FItems.Clear;
  FDiapositiveDuration := -1;
end;

function TSequence.GetItem(const index: Integer): TSequenceItem;
begin
  Result := FItems[index];
end;

function TSequence.getItemCount: Integer;
begin
  Result := FItems.Count;
end;

procedure TSequence.LoadFromXML(const sequenceNode: IXMLDomNode);
var
  aNode: IXmlDomNode;
  sequenceItem: TSequenceItem;
  diapositiveId, diapositiveType, diaporamaName, orderStr: string;
  i, nbDiapositive, diapositiveDuration: Integer;
  order: TDiaporamaSequenceOrder;
begin
  if Assigned(sequenceNode) then
  begin
    FDiapositiveDuration :=
      StrToIntDef(getAttributeValue(aNode, cstPlayDiaporamaDurationAttr), -1);

    sequenceItem := nil;
    for i:=0 to sequenceNode.ChildNodes.Length-1 do
    begin
      aNode := sequenceNode.ChildNodes[i];

      // Diapositive node ?
      if SameText(aNode.NodeName, cstPlayDiapositiveNode) then
      begin
        diapositiveType :=
          getAttributeValue(aNode, cstPlayDiapositiveTypeAttr);

        diapositiveId := getAttributeValue(aNode, cstPlayDiapositiveIdAttr);

        nbDiapositive := StrToIntDef(
          getAttributeValue(aNode, cstPlayNbDiapositiveAttr), 1);

        sequenceItem := TDiapositiveSequenceItem.Create(diapositiveType,
          diapositiveId, nbDiapositive);

      end else
      // Diaporama sequence node ?
      if SameText(aNode.NodeName, cstPlayDiaporamaNode) then
      begin
        diaporamaName := getAttributeValue(aNode, cstPlayDiaporamaNameAttr);

        nbDiapositive := StrToIntDef(
          getAttributeValue(aNode, cstPlayNbDiapositiveAttr), 1);

        diapositiveDuration :=
          StrToIntDef(getAttributeValue(aNode, cstPlayDiaporamaDurationAttr),
            -1);

        orderStr := getAttributeValue(aNode, cstPlayDiaporamaOrderAttr);
        if orderStr='random' then
          order := soRandom
        else
          order := soNormal;

        sequenceItem := TDiaporamaSequenceItem.Create(diaporamaName,
          nbDiapositive, diapositiveDuration, order);
      end;

      if Assigned(sequenceItem) then
        FItems.Add(sequenceItem);
    end;
  end;
end;

end.
