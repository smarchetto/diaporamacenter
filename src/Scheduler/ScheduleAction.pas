unit ScheduleAction;

interface

uses
  Generics.Defaults, Generics.Collections, MSXML2_TLB, Classes;

type
  TPeriodicityType = (apNone=-1, apEveryDay, apWorkWeek5,
    apWorkWeek6, apEveryHour);

  TScheduleAction = class;

  // Interface for objects that have to be scheduled
  IScheduleSource = interface
    ['{648DFBFF-B79D-47C3-B75A-50A2DE676E06}']
    // Name of object (source)
    function GetSourceName: string;
    // Returns action of given code
    function GetDefaultAction(const actionCode: Integer): TScheduleAction;
    // Returns action name
    function GetActionName(const aScheduleAction: TScheduleAction): string;
    // Checks an action plan before triggering
    procedure CheckActions(const actions: TObjectList<TScheduleAction>);
    // Execute an action
    function ExecuteAction(const aScheduleAction: TScheduleAction): Boolean;
  end;

  // Periodicity of action
  TActionPeriodicity = class
  private
    // Periodicity type (every day..)
    FPeriodicityType: TPeriodicityType;
    // Triggering time
    FTime: TDateTime;
  public
    constructor Create(const aPeriodicityType: TPeriodicityType;
      const aTime: TDateTime);

    function Equals(anObject: TObject): Boolean; override;
    procedure Assign(const anActionPeriodicity: TActionPeriodicity);

    class function LoadActionPeriodicityFromXML(
      const aNode: IXmlDomNode): TActionPeriodicity;
    function LoadFromXML(const aNode: IXmlDomNode): TActionPeriodicity;
    function SaveToXML(const xmlDocument: IXMLDomDocument;
      const aNode: IXmlDomNode): Boolean;

    property Time: TDateTime read FTime write FTime;
    property PeriodicityType: TPeriodicityType read FPeriodicityType
      write FPeriodicityType;
  end;

  // Class of action to be scheduled
  TScheduleAction = class
  private
    // Source
    FSource: IScheduleSource;
    // Code
    FAction: Integer;
    // Settings
    FParameters: TStringList;
    // Periodicity
    FPeriodicity: TActionPeriodicity;
    // Triggering time
    FTime: TDateTime;
    // Activated or not
    FEnabled: Boolean;
  public
    constructor Create(const aSource: IScheduleSource;
      const anAction: Integer; const aPeriodicityType: TPeriodicityType;
      const aTime: TDateTime; const isEnabled: Boolean;
      const someParameters: TStringList = nil);
    destructor Destroy; override;

    procedure Assign(const aScheduleAction: TScheduleAction);
    function Copy: TScheduleAction;
    function Equals(anObject: TObject): Boolean; override;

    function SameSource(const aSource: IScheduleSource): Boolean; overload;
    function SameSource(const aScheduleAction: TScheduleAction): Boolean; overload;
    function SameAs(const aScheduleAction: TScheduleAction): Boolean;

    procedure ScheduleToday;
    procedure ReScheduleTomorrow;
    procedure ReScheduleNextMonday;
    procedure ReScheduleNextHour;

    function ReSchedule: Boolean;

    class function CreateAction(const aSource: IScheduleSource;
      const anAction: Integer;
      const aPeriodicityType: TPeriodicityType;
      const aTime: TDateTime;
      const isEnabled: Boolean;
      const someParameters: TStringList = nil): TScheduleAction;

    class function LoadFromXML(const aNode: IXMLDomNode;
      const Scheduler: TObject): TScheduleAction;
    function SaveToXML(const xmlDocument: IXMLDomDocument;
      const parentNode: IXMLDomNode): Boolean;

    property Source: IScheduleSource read FSource;
    property Action: Integer read FAction;
    property Time: TDateTime read FTime;
    property Periodicity: TActionPeriodicity read FPeriodicity;
    property Parameters: TStringList read FParameters;
    property Enabled: Boolean read FEnabled write FEnabled;
  end;


const
  cstNodeScheduleAction = 'ScheduleAction';

implementation

uses
  SysUtils, DateUtils,
  Logs, DiaporamaUtils, DiaporamaScheduler;

const
  cstAttrSource = 'Source';
  cstAttrAction = 'Action';
  cstAttrTime = 'Time';
  cstAttrPeriodicity = 'Periodicity';
  cstAttrParameter = 'Parameter';
  cstAttrEnabled = 'Enabled';

  cstActionTimeInvalidFormat =
    'Time format ''%s'' in node ''%s'' is invalid';
  cstActionReScheduled =
    'Action ''%s'' for source ''%s'' is rescheduled on %s at %s';

{$REGION 'TActionPeriodicity'}

constructor TActionPeriodicity.Create(const aPeriodicityType: TPeriodicityType;
  const aTime: TDateTime);
begin
  FPeriodicityType := aPeriodicityType;
  FTime := aTime;
end;

function TActionPeriodicity.Equals(anObject: TObject): Boolean;
var
  anActionPeriodicity: TActionPeriodicity;
begin
  if (anObject is TObject) then
  begin
    anActionPeriodicity := TActionPeriodicity(anObject);
    Result := Assigned(anActionPeriodicity) and
      (FPeriodicityType = anActionPeriodicity.PeriodicityType) and
      (HourOf(FTime)=HourOf(anActionPeriodicity.Time)) and
      (MinuteOf(FTime)=MinuteOf(anActionPeriodicity.Time));
  end else
    Result := false;
end;

procedure TActionPeriodicity.Assign(const anActionPeriodicity: TActionPeriodicity);
begin
  if Assigned(anActionPeriodicity) then
  begin
    FPeriodicityType := anActionPeriodicity.PeriodicityType;
    FTime := anActionPeriodicity.Time;
  end;
end;

function TActionPeriodicity.LoadFromXML(
  const aNode: IXmlDomNode): TActionPeriodicity;
var
  aStr: string;
begin
  if Assigned(aNode) then
  begin
    aStr := GetAttributeValue(aNode, cstAttrPeriodicity);
    FPeriodicityType := TPeriodicityType(StrToIntDef(aStr, -1));
    aStr := GetAttributeValue(aNode, cstAttrTime);
    FTime := StrToTimeDef(aStr, 0);
    // FIXME : self ?
    Result := Self;
  end else
    Result := nil;
end;

class function TActionPeriodicity.LoadActionPeriodicityFromXML(
  const aNode: IXmlDomNode): TActionPeriodicity;
begin
  if Assigned(aNode) then
  begin
    Result := TActionPeriodicity.Create(apNone, 0);
    Result.LoadFromXML(aNode);
  end else
    Result := nil;
end;

function TActionPeriodicity.SaveToXML(const xmlDocument: IXMLDomDocument;
  const aNode: IXmlDomNode): Boolean;
begin
  Result := False;
  if Assigned(aNode) then
  begin
     SetAttributeValue(xmlDocument, aNode, cstAttrPeriodicity,
      IntToStr(Ord(FPeriodicityType)));

     SetAttributeValue(xmlDocument, aNode, cstAttrTime, TimeToStr(FTime));
  end;
end;

{$ENDREGION}

{$REGION 'TScheduleAction'}

constructor TScheduleAction.Create(
  const aSource: IScheduleSource; const anAction: Integer;
  const aPeriodicityType: TPeriodicityType; const aTime: TDateTime;
  const isEnabled: Boolean; const someParameters: TStringList = nil);
begin
  FSource := aSource;
  FAction := anAction;
  FTime := aTime;
  FPeriodicity := TActionPeriodicity.Create(aPeriodicityType, aTime);
  FParameters := TStringList.Create;
  FParameters.NameValueSeparator := '=';
  FParameters.Delimiter := ',';
  FParameters.StrictDelimiter := True;
  if Assigned(someParameters) then
    FParameters.Assign(someParameters);
  FEnabled := isEnabled;
end;

destructor TScheduleAction.Destroy;
begin
  FPeriodicity.Free;
  FParameters.Free;
  inherited;
end;

class function TScheduleAction.CreateAction(const aSource: IScheduleSource;
  const anAction: Integer;
  const aPeriodicityType: TPeriodicityType;
  const aTime: TDateTime;
  const isEnabled: Boolean;
  const someParameters: TStringList = nil): TScheduleAction;
begin
  Result := nil;
  if Assigned(aSource) then
  begin
    Result := TScheduleAction.Create(aSource, anAction,
      aPeriodicityType, aTime, isEnabled, someParameters);
  end;
end;

class function TScheduleAction.LoadFromXML(
  const aNode: IXMLDomNode; const Scheduler: TObject): TScheduleAction;
var
  anActionPeriodicity: TActionPeriodicity;
  sourceName: string;
  aSource: IScheduleSource;
  someParameters: TStringList;
  isEnabled: Boolean;
  anAction, i: Integer;
begin
  Result := nil;
  if not Assigned(aNode) or
    not SameText(aNode.NodeName, cstNodeScheduleAction) then
    Exit;

  someParameters := nil;
  anActionPeriodicity := nil;
  try
    sourceName := GetAttributeValue(aNode, cstAttrSource);
    if Assigned(Scheduler) and (Scheduler is TDiaporamaScheduler) then
      aSource := TDiaporamaScheduler(Scheduler).GetSource(sourceName)
    else
      aSource := nil;

    if Assigned(aSource) then
    begin
      anAction := StrToIntDef(GetAttributeValue(aNode, cstAttrAction), -1);

      anActionPeriodicity := TActionPeriodicity.LoadActionPeriodicityFromXML(aNode);

      isEnabled := StrToBoolDef(GetAttributeValue(aNode, cstAttrEnabled), False);

      someParameters := TStringList.Create;
      for i := 0 to aNode.childNodes.length-1 do
        someParameters.Values[aNode.childNodes[i].nodeName] :=
          aNode.childNodes[i].Text;

      // TODO : manage errors in source, time...
      {if anActionPeriodicity.Time=0 then
        LogEvent(Self.ClassName, ltError, Format(cstActionTimeInvalidFormat,
          [aStr, aNode.nodeName]));}

      Result := TScheduleAction.CreateAction(aSource, anAction,
        anActionPeriodicity.PeriodicityType, anActionPeriodicity.Time,
        isEnabled, someParameters);
    end;
  finally
    someParameters.Free;
    anActionPeriodicity.Free;
  end;
end;

function TScheduleAction.SaveToXML(const xmlDocument: IXMLDomDocument;
  const parentNode: IXMLDomNode): Boolean;
var
  aNode: IXMLDomNode;
  parameterName: string;
  i: Integer;
begin
  Result := false;
  if not Assigned(xmlDocument) or not Assigned(parentNode) then
    Exit;

  aNode := xmlDocument.createElement(cstNodeScheduleAction);
  parentNode.AppendChild(aNode);

  SetAttributeValue(xmlDocument, aNode, cstAttrSource, FSource.GetSourceName);

  SetAttributeValue(xmlDocument, aNode, cstAttrAction, IntToStr(FAction));

  FPeriodicity.SaveToXML(xmlDocument, aNode);

  SetAttributeValue(xmlDocument, aNode, cstAttrEnabled, BoolToStr(FEnabled));

  for i := 0 to FParameters.Count-1 do
  begin
    parameterName := FParameters.Names[i];
    if parameterName<>'' then
      SetNodeValue(xmlDocument, aNode, parameterName,
        FParameters.Values[parameterName]);
  end;

  Result := True;
end;

procedure TScheduleAction.Assign(const aScheduleAction: TScheduleAction);
begin
  if Assigned(aScheduleAction) then
  begin
    FSource := aScheduleAction.Source;
    FAction := aScheduleAction.Action;
    FTime := aScheduleAction.Time;
    FPeriodicity.Assign(aScheduleAction.Periodicity);
    FEnabled := aScheduleAction.Enabled;
    if Assigned(aScheduleAction.Parameters) then
      FParameters.Assign(aScheduleAction.Parameters);
  end;
end;

function TScheduleAction.Copy: TScheduleAction;
begin
  Result := TScheduleAction.Create(FSource, FAction,
    FPeriodicity.PeriodicityType, FPeriodicity.Time, FEnabled, FParameters);
end;

procedure TScheduleAction.ScheduleToday;
var
  aTime: TDateTime;
begin
  aTime := Now;
  ReplaceTime(aTime, FTime);
  FTime := aTime;
end;

procedure TScheduleAction.ReScheduleNextMonday;
begin
  FTime := IncDay(FTime, 8-DayOfTheWeek(FTime));
end;

procedure TScheduleAction.ReScheduleTomorrow;
begin
  FTime := IncDay(FTime);
end;

procedure TScheduleAction.ReScheduleNextHour;
var
  nowTime: TDateTime;
begin
  nowTime := Now;
  while CompareDateTime(FTime, nowTime)<0 do
    FTime := IncHour(FTime);
end;

function TScheduleAction.Reschedule: Boolean;
var
  aStr: string;
begin
  Result := True;
  case FPeriodicity.PeriodicityType of
    apEveryHour :
    begin
      ReScheduleNextHour;
      aStr := '';
    end;
    apEveryDay :
    begin
      ReScheduleTomorrow;
      aStr := 'tomorrow';
    end;
    apWorkWeek5 :
    begin
      if DayOfTheWeek(FTime)>=5 then
      begin
        ReScheduleNextMonday;
        aStr := 'Monday';
      end
      else
      begin
        ReScheduleTomorrow;
        aStr := 'tomorrow';
      end;
    end;
    apWorkWeek6 :
    begin
      if DayOfTheWeek(FTime)=6 then
      begin
        ReScheduleNextMonday;
        aStr := 'Monday';
      end
      else
      begin
        ReScheduleTomorrow;
        aStr := 'tomorrow';
      end;
    end;
  else
    Result := False;
  end;

  if Result then
  LogEvent(Self.ClassName, ltInformation, Format(cstActionReScheduled, [
    FSource.GetActionName(Self), FSource.getSourceName,
    aStr, TimeToStr(FTime)]));
end;

function TScheduleAction.SameSource(const aSource: IScheduleSource): Boolean;
begin
  Result := Assigned(aSource) and (FSource=aSource);
end;

function TScheduleAction.SameSource(const aScheduleAction: TScheduleAction): Boolean;
begin
  Result := Assigned(aScheduleAction) and SameSource(aScheduleAction.Source);
end;

function TScheduleAction.SameAs(const aScheduleAction: TScheduleAction): Boolean;
begin
  Result := SameSource(aScheduleAction) and
    (FAction=aScheduleAction.Action);
end;

function TScheduleAction.Equals(anObject: TObject): Boolean;
var
  aScheduleAction: TScheduleAction;
begin
  if anObject is TScheduleAction then
  begin
    aScheduleAction := TScheduleAction(anObject);
    Result := SameAs(aScheduleAction)
      and (FEnabled = aScheduleAction.Enabled)
      and FPeriodicity.Equals(aScheduleAction.Periodicity)
      and (FParameters.CommaText=aScheduleAction.Parameters.CommaText);
  end else
    Result := false;
end;

{$ENDREGION}

end.
