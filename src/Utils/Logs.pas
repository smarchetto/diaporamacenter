unit Logs;

interface

type
  TLogType = (ltError=1, ltWarning=2, ltInformation=3);

function InitializeLog(const logLevel: Integer): Boolean;
function FinalizeLog: Boolean;

procedure LogEvent(const senderName: string; const logType: TLogType;
  const msg: string);

implementation

uses
  Forms, SysUtils, afpEventLog;

var
  FLog: TAfpEventLog;
  FLogLevel: Integer;

function InitializeLog(const logLevel: Integer): Boolean;
begin
  FLog := TAfpEventLog.Create(nil);
  FLogLevel := logLevel;
  FLog.ApplicationName := ExtractFileName(Application.ExeName);
  FLog.RegisterApplication := True;
  Result := Assigned(FLog);
end;

function FinalizeLog: Boolean;
begin
  FreeAndNil(FLog);
  Result := not Assigned(FLog);
end;

procedure LogEvent(const senderName: string; const logType: TLogType;
  const msg: string);
var
  line: string;
begin
  if Ord(logType)<=FLogLevel then
  begin
    case logType of
      ltError       : FLog.EventType := etError;
      ltWarning     : FLog.EventType := etWarning;
      ltInformation : FLog.EventType := etInformation;
    end;
    line := Format('%s - %16s [%d] : %s',
      [DateTimeToStr(Now), senderName, Ord(logType), msg]);
    FLog.LogEvent(line);
  end;
end;

initialization
  FLog := nil;

finalization
  FinalizeLog;

end.
