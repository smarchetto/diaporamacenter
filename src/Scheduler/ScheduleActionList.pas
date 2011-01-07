unit ScheduleActionList;

interface

uses
  Generics.Defaults, Generics.Collections,
  ScheduleAction;

type
  TScheduleActionTimeComparer = class(TComparer<TScheduleAction>)
  public
    function Compare(const scheduleAction1,
      scheduleAction2: TScheduleAction): integer; override;
  end;

  TScheduleActionSourceComparer = class(TComparer<TScheduleAction>)
  public
    function Compare(const scheduleAction1,
      scheduleAction2: TScheduleAction): integer; override;
  end;

  TScheduleActionList = class(TObjectList<TScheduleAction>)
  protected
  public
    procedure Assign(const aScheduleActionList: TScheduleActionList);
    function Copy: TScheduleActionList;
    function Equals(anObject: TObject): Boolean; override;

    procedure SortByTime;

    procedure RemoveActions(const sourceName: string);

    function GetAction(const sourceName: string;
      const action: Integer): TScheduleAction;
  end;

implementation

uses
  DateUtils, SysUtils;

{$REGION 'ScheduleActions Comparers'}

function TScheduleActionTimeComparer.Compare(const scheduleAction1,
  scheduleAction2: TScheduleAction): integer;
begin
  if Assigned(scheduleAction1) and Assigned(scheduleAction2) then
  begin
    Result := CompareDateTime(scheduleAction1.Time, scheduleAction2.Time);
  end else
    Result := 0;
end;

function TScheduleActionSourceComparer.Compare(const scheduleAction1,
  scheduleAction2: TScheduleAction): integer;
var
  source1, source2: IScheduleSource;
begin
  if Assigned(scheduleAction1) and Assigned(scheduleAction2) then
  begin
    source1 := scheduleAction1.Source;
    source2 := scheduleAction2.Source;
    Result := CompareText(Source1.GetSourceName, Source2.GetSourceName);
    if Result=0 then
      Result := CompareDateTime(scheduleAction1.Time, scheduleAction2.Time);
  end else
    Result := 0;
end;

{$ENDREGION}


{$REGION 'TScheduleActionList'}

procedure TScheduleActionList.Assign(
  const aScheduleActionList: TScheduleActionList);
var
  aScheduleAction: TScheduleAction;
begin
  if Assigned(aScheduleActionList) then
  begin
    Clear;
    for aScheduleAction in aScheduleActionList do
      Add(aScheduleAction.Copy);
  end;
end;

function TScheduleActionList.Copy: TScheduleActionList;
begin
  Result := TScheduleActionList.Create(True);
  Result.Assign(Self);
end;

function TScheduleActionList.Equals(anObject: TObject): Boolean;
var
  aScheduleActionList: TScheduleActionList;
  i: Integer;
begin
  if Assigned(anObject) and (anObject is TScheduleActionList) then
  begin
    aScheduleActionList := TScheduleActionList(anObject);
    if (Count=aScheduleActionList.Count) then
    begin
      Result := True;
      for i := 0 to Count-1 do
      begin
        if not Items[i].Equals(aScheduleActionList.Items[i]) then
        begin
          Result := False;
          Exit;
        end;
      end;
    end else
      Result := false;
  end else
    Result := false;
end;

function TScheduleActionList.GetAction(const sourceName: string;
  const action: Integer): TScheduleAction;
var
  aScheduleAction: TScheduleAction;
begin
  for aScheduleAction in Self do
  begin
    if (aScheduleAction.Source.GetSourceName=sourceName) and
       (aScheduleAction.Action=action) then
    begin
      Result := aScheduleAction;
      Exit;
    end;
  end;
  Result := nil;
end;

procedure TScheduleActionList.SortByTime;
var
  timeComparer: TScheduleActionTimeComparer;
begin
  timeComparer := TScheduleActionTimeComparer.Create;
  try
    Sort(timeComparer);
  finally
    timeComparer.Free;
  end;
end;

procedure TScheduleActionList.RemoveActions(const sourceName: string);
var
  i: integer;
begin
  for i := Count-1 downto 0 do
  begin
    if Items[i].Source.GetSourceName=sourceName then
      Delete(i);
  end;
end;

{$ENDREGION}


end.
