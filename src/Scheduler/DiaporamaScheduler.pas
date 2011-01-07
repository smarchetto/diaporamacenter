unit DiaporamaScheduler;

interface

uses
  Classes,
  ScheduleActionList, ScheduleAction, ThreadIntf;

type
  TScheduleTriggerEvent = procedure(
    const scheduleAction: TScheduleAction) of object;

  // Scheduler : used to trigger automatically actions such as
  // - download, play, stop a diaporama
  // - power off/on a display device
  TDiaporamaScheduler = class(TObject, IThread)
  private
    FDiaporamaCenterAgent: TObject;

    // Action list registered
    FSchedule: TScheduleActionList;

    // Registered action sources
    FSources: TInterfaceList;

    // Scheduler runs in a thread
    FThreadLink: TThreadLink;

    // Next action to trigger
    FTriggerAction: TScheduleAction;

    // Main process : watch clock and trigger actions
    procedure MonitorSchedule;
  public
    constructor Create(const diaporamaCenterAgent: TObject);
    destructor Destroy; override;

    // Add a new source
    procedure RegisterSource(const aSource: IScheduleSource);
    // Remove a source
    procedure UnregisterSource(const aSource: IScheduleSource);

    // Get source by name
    function GetSource(const sourceName: string): IScheduleSource;

    procedure Assign(const aScheduler: TDiaporamaScheduler);
    function Copy: TDiaporamaScheduler;
    function Equals(anObject: TObject): Boolean; override;

    // Load & Save agenda
    function LoadFromXML(const xmlFilePath: string): Boolean;
    function SaveToXML(const xmlFilePath: string): Boolean;

    // Add a new action to schedule
    // TODO : utiliser le type TTime qui represente seulement l'heure
    procedure AddAction(const aScheduleAction: TScheduleAction); overload;
    procedure RemoveAction(const aScheduleAction: TScheduleAction);

    // Execute next action
    // FIXME : should be better with an argument
    procedure ExecuteAction;

    function GetAction(const sourceName: string;
      const actionCode: Integer): TScheduleAction;

    // Removes all actions from schedule
    procedure ClearSchedule;

    procedure Resume;
    procedure Terminate;

    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    // IThread
    procedure Execute;
    procedure OnTerminateExecute;
  end;

implementation

uses
  Generics.Defaults, Generics.Collections, DateUtils, ActiveX, MSXML2_TLB,
  Windows, SysUtils,
  DiaporamaCenterAgent, Logs, DiaporamaUtils;

const
  cstNodeSchedule = 'Schedule';

  cstActionScheduled =
    'Action ''%s'' for source ''%s'' is scheduled at %s';

  MONITOR_PERIOD_TIME = 15*1000; // 1 mn

{$REGION 'TDiaporamaScheduler'}

constructor TDiaporamaScheduler.Create(const diaporamaCenterAgent: TObject);
begin
  FSchedule := TScheduleActionList.Create(True);
  FSources := TInterfaceList.Create;
  FThreadLink := TThreadLink.Create(Self);
  FDiaporamaCenterAgent := diaporamaCenterAgent;
  FTriggerAction := nil;
end;

destructor TDiaporamaScheduler.Destroy;
begin
  FSchedule.Free;
  FSources.Free;

  FThreadLink.Free;

  inherited;
end;

procedure TDiaporamaScheduler.RegisterSource(const aSource: IScheduleSource);
begin
  if Assigned(aSource) then
  begin
    if not Assigned(GetSource(aSource.GetSourceName)) then
      FSources.Add(aSource);
  end;
end;

procedure TDiaporamaScheduler.UnregisterSource(const aSource: IScheduleSource);
begin
  if Assigned(aSource) then
  begin
    FSchedule.RemoveActions(aSource.GetSourceName);
    FSources.Remove(aSource);
  end;
end;

function TDiaporamaScheduler.GetSource(
  const sourceName: string): IScheduleSource;
var
  i: Integer;
begin
  for i := 0 to FSources.Count - 1 do
  begin
    Result := IScheduleSource(FSources[i]);
    if Assigned(Result) and SameText(Result.GetSourceName, sourceName) then
      Exit;
  end;
  Result := nil;
end;

procedure TDiaporamaScheduler.Assign(const aScheduler: TDiaporamaScheduler);
var
  i: Integer;
begin
  if Assigned(aScheduler) then
  begin
    FSchedule.Assign(aScheduler.FSchedule);
    FSources.Clear;
    for i := 0 to aScheduler.FSources.Count-1 do
      FSources.Add(aScheduler.FSources[i]);
  end;
end;

function TDiaporamaScheduler.Copy: TDiaporamaScheduler;
begin
  Result := TDiaporamaScheduler.Create(FDiaporamaCenterAgent);
  Result.Assign(Self);
end;

function TDiaporamaScheduler.Equals(anObject: TObject): Boolean;
begin
  if Assigned(anObject) then
    Result := FSchedule.Equals(TDiaporamaScheduler(anObject).FSchedule)
  else
    Result := false;
end;

function TDiaporamaScheduler.LoadFromXML(const xmlFilePath: string): Boolean;
var
  xmlDocument: IXMLDomDocument;
  nodeList: IXMLDomNodeList;
  rootNode: IXMLDomNode;
  aScheduleAction: TScheduleAction;
  i: Integer;
begin
  Result := False;

  if not FileExists(xmlFilePath) then
    Exit;
    //raise Exception.Create(Format('Cannot find configuration file %s',
    //  [xmlFilePath]));

  xmlDocument := coDomDocument40.Create;
  xmlDocument.Load(xmlFilePath);

  if xmlDocument.ParseError.ErrorCode=0 then
  begin
    rootNode := xmlDocument.DocumentElement;

    if not SameText(rootNode.NodeName, cstNodeSchedule) then
      Exit;

    ClearSchedule;

    nodeList :=  rootNode.SelectNodes('./' + cstNodeScheduleAction);

    if Assigned(nodeList) then
    begin
      for i:=0 to nodeList.Length-1 do
      begin
        aScheduleAction := TScheduleAction.LoadFromXML(nodeList[i], Self);
        if Assigned(aScheduleAction) then
          AddAction(aScheduleAction);
      end;
    end;

    Result := True;
  end;
end;

function TDiaporamaScheduler.SaveToXML(const xmlFilePath: string): Boolean;
var
  scheduleAction: TScheduleAction;
  xmlDocument: IXMLDomDocument;
begin
  xmlDocument := coDomDocument40.Create;
  xmlDocument.Async := False;

  xmlDocument.documentElement := xmlDocument.createElement(cstNodeSchedule);

  for scheduleAction in FSchedule do
    scheduleAction.SaveToXML(xmlDocument, xmlDocument.DocumentElement);

  xmlDocument.save(xmlFilePath);

  Result := True;
end;

procedure TDiaporamaScheduler.AddAction(const aScheduleAction: TScheduleAction);
begin
  if Assigned(aScheduleAction) then
  begin
    FSchedule.Add(aScheduleAction);

    // TODO : plan action for further days ?
    aScheduleAction.ScheduleToday;

    LogEvent(Self.ClassName, ltInformation,
      Format(cstActionScheduled, [
        aScheduleAction.Source.GetActionName(aScheduleAction),
        aScheduleAction.Source.GetSourceName,
        TimeToStr(aScheduleAction.Time)]));

    FSchedule.SortByTime;
  end;
end;

procedure TDiaporamaScheduler.RemoveAction(const aScheduleAction: TScheduleAction);
begin
  if Assigned(aScheduleAction) then
  begin
    FSchedule.Remove(aScheduleAction);
  end;
end;

procedure TDiaporamaScheduler.ExecuteAction;
begin
  if Assigned(FTriggerAction) and Assigned(FTriggerAction.Source) then
    FTriggerAction.Source.ExecuteAction(FTriggerAction);
end;

function TDiaporamaScheduler.GetAction(const sourceName: string;
  const actionCode: Integer): TScheduleAction;
var
  aSource: IScheduleSource;
begin
  Result := FSchedule.GetAction(sourceName, actionCode);

  // If action is not found, ask source to get action
  if not Assigned(Result) then
  begin
    aSource := GetSource(sourceName);
    if Assigned(aSource) then
      Result := aSource.GetDefaultAction(actionCode);

    // And add it to schedule
    if Assigned(Result) then
      AddAction(Result);
  end;
end;

procedure TDiaporamaScheduler.ClearSchedule;
begin
  FSchedule.Clear;
end;

procedure TDiaporamaScheduler.MonitorSchedule;
var
  sourceActionLists: TDictionary<IScheduleSource, TScheduleActionList>;
  source: IScheduleSource;
  sourceActions, triggerActions: TScheduleActionList;
  aScheduleAction: TScheduleAction;
  nowTime: TDateTime;
begin
  triggerActions := nil;
  sourceActionLists := nil;
  try
    // Get action list to trigger
    sourceActionLists := TObjectDictionary<IScheduleSource,
      TScheduleActionList>.Create([]);
    nowTime := Now;
    for aScheduleAction in FSchedule do
    begin
      // It is time for this, add action to trigger list
      if (aScheduleAction.Enabled) and
        (nowTime>aScheduleAction.Time) then
      begin
        if sourceActionLists.TryGetValue(aScheduleAction.Source, sourceActions) then
        begin
          sourceActions.Add(aScheduleAction);
        end else
        begin
          sourceActions := TScheduleActionList.Create(false);
          sourceActions.Add(aScheduleAction);
          sourceActionLists.Add(aScheduleAction.Source, sourceActions);
        end;
      end;
    end;

    // Check actions
    triggerActions := TScheduleActionList.Create(False);
    for source in sourceActionLists.Keys do
    begin
      sourceActionLists.TryGetValue(source, sourceActions);
      source.CheckActions(sourceActions);
      for aScheduleAction in sourceActions do
        triggerActions.Add(aScheduleAction);
    end;
    // And sort by ascending time
    triggerActions.SortByTime;

    try
      // Trigger actions
      for aScheduleAction in triggerActions do
      begin
        FTriggerAction := aScheduleAction;
        FThreadLink.DoSynchronize(ExecuteAction);
      end;
    finally
      // We reschedule actions
      for sourceActions in sourceActionLists.Values do
      begin
        for aScheduleAction in sourceActions do
        begin
          if not aScheduleAction.ReSchedule then
            FSchedule.Remove(aScheduleAction);
        end;
      end;
    end;

  finally
    triggerActions.Free;
    sourceActionLists.Free;
  end;
end;

procedure TDiaporamaScheduler.Execute;
begin
  coInitializeEx(nil, COINIT_APARTMENTTHREADED);

  while not FThreadLink.Terminated do
  begin
    // Prevent system to standby
    SetThreadExecutionState(ES_SYSTEM_REQUIRED);

    // Monitor actiions, and trigger them when time has come
    MonitorSchedule;

    Sleep(MONITOR_PERIOD_TIME);
  end;

  coUninitialize;
end;

procedure TDiaporamaScheduler.Resume;
begin
  // Start thread
  if FThreadLink.Finished then
  begin
    FThreadLink.Free;
    FThreadLink := TThreadLink.Create(self);
  end;
  FThreadLink.Resume;
end;

procedure TDiaporamaScheduler.Terminate;
begin
  //if Assigned(FThreadLink) then
  if not FThreadLink.Terminated then
    FThreadLink.Terminate;
end;

procedure TDiaporamaScheduler.OnTerminateExecute;
begin
  //FThreadLink := nil;
end;

function TDiaporamaScheduler.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := -1;
end;

function TDiaporamaScheduler._AddRef: Integer;
begin
  Result := -1;
end;

function TDiaporamaScheduler._Release: Integer;
begin
  Result := -1;
end;

{$ENDREGION}

end.
