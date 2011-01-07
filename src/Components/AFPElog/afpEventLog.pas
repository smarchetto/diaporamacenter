(*******************************************************************************

TafpEventLog Version 1.0
Written by Alfred Petri
Copyright (c) 1997 by Alfred Petri. All rights reserved.

Please send comments to alfred_petri@compuserve.com

 ******************************************************************************
 *   Permission to use, copy,  modify, and distribute this software and its   *
 *        documentation without fee for any purpose is hereby granted,        *
 *   provided that the above copyright notice appears on all copies and that  *
 *     both the copyright notice and this permission notice appear in all     *
 *                         supporting documentation.                          *
 *                                                                            *
 * NO REPRESENTATIONS ARE MADE ABOUT THE SUITABILITY OF THIS SOFTWARE FOR ANY *
 *    PURPOSE. IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.    *
 *        ALFRED PETRI SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY        *
 *                          THE USE OF THIS SOFTWARE.                         *
 ******************************************************************************


This is a non-visual VCL component that encapsulates the NT 4.x REPORTEVENT
function. The purpose of this component is to facilitate the generation of log
entries in the Windows NT Event-Log.

Properties:
- ApplicationName:     Applicationname to appear in Eventlog
- RegisterApplication: If True, a Key of ApplicationName is created in
									 HKEY_LOCAL_MACHINE
                       \SYSTEM\CurrentControlSet\Services\EventLog\Application
                       If the application is not registered (and thus a
                       corresponding key is not found), EventViewer will
                       not be able to filter messages for this application.
- IncludeUserName:     If True, includes the current user name in the message
                       written to the event log.
- EventType:           Determines the icon to display in Event Viewer.
- EventID:             Integer Positive Number - written to log as is.
- EventCategory:       Integer Positive Number - written to log as is.

Methods:
- LogEvent:           Used to write a message to the Event Log. Typical call:
  afpEventLog1.LogEvent('Password Expired!'#13#10'Contact support!');

  Notes:
*******************************************************************************)

unit afpEventLog;

interface

uses
  Windows, Registry, Messages, SysUtils, Classes, Graphics, Controls, Dialogs;

type
	TEventType = (etError,etWarning,etInformation,etAuditSuccess,etAuditFailure);

  TafpEventLog = class(TComponent)

  private
    { Private declarations }
    FApplicationName: String;
    FRegisterApplication: Boolean;
    FIncludeUserName: Boolean;
    FEventType: TEventType;
    FEventID: DWord;
    FEventCategory: Word;
    FUserName: String;

//    procedure SetupCaption;

  protected
    { Protected declarations }
		procedure SetApplicationName(Value: String);
		procedure SetRegisterApplication(Value: Boolean);
		procedure SetIncludeUserName(Value: Boolean);
		procedure SetEventID(Value: DWord);
		procedure SetEventCategory(Value: Word);

  public
    { Public declarations }
		constructor Create(AOwner: TComponent); override;
		destructor Destroy; override;
		procedure LogEvent(const Line: String);

  published
    { Published declarations }
		property ApplicationName: String
	      read FApplicationName write SetApplicationName;
		property RegisterApplication: Boolean
	      read FRegisterApplication write SetRegisterApplication;
		property IncludeUserName: Boolean
	      read FIncludeUserName write SetIncludeUserName;
		property EventType: TEventType
	      read FEventType write FEventType default etInformation;
		property EventID: DWord
	      read FEventID write SetEventID;
		property EventCategory: Word
	      read FEventCategory write SetEventCategory;
  end;

procedure Register;

{$R afpEventLog.Res}


implementation

procedure Register;
begin
  RegisterComponents('AFP', [TafpEventLog]);
end;


constructor TafpEventLog.Create(AOwner: TComponent);
begin
		inherited Create(AOwner);
		ApplicationName     := '!MyApp';
     EventCategory       := 0;
     EventID             := 0;
     EventType           := etInformation;
     IncludeUserName     := True;
     RegisterApplication := True;
end;

destructor TafpEventLog.Destroy;
begin
    inherited Destroy;
end;

procedure TafpEventLog.SetApplicationName(Value: String);
begin
    if FApplicationName = Value then exit;
    FApplicationName := Value;
end;

procedure TafpEventLog.SetRegisterApplication(Value: Boolean);
begin
    if FRegisterApplication = Value then exit;
    FRegisterApplication := Value;
end;

procedure TafpEventLog.SetIncludeUserName(Value: Boolean);
begin
    if FIncludeUserName = Value then exit;
    FIncludeUserName := Value;
end;

procedure TafpEventLog.SetEventId(Value: DWord);
begin
    if FEventID = Value then exit;
    FEventID := Abs(Value);
end;

procedure TafpEventLog.SetEventCategory(Value: Word);
begin
    if FEventCategory = Value then exit;
    FEventCategory := Abs(Value);
end;

procedure TafpEventLog.LogEvent(const Line: String);
const
	cRegPath = '\SYSTEM\CurrentControlSet\Services\EventLog\Application';
var
	LogHandle:	THandle;
	OK,OK2Run: Boolean;
	eType: Word;
  eMsg, aName: PChar;
	Reg: TRegistry;
  nSize: Dword;
  VersionInfo : TOSVersionInfo;
begin
	VersionInfo.dwOSVersionInfoSize := SizeOf( TOSVersionInfo );
 	Ok2Run := False;
	if Windows.GetVersionEx( VersionInfo ) then
    	if VersionInfo.dwPlatformId >= VER_PLATFORM_WIN32_NT then
       	Ok2Run := True;
  if Ok2Run then
  begin
		if RegisterApplication then
		begin
			Reg := TRegistry.Create;
			try
				with Reg do
				begin
					RootKey := HKEY_LOCAL_MACHINE;
		      	OpenKey( cRegPath + '\' + ApplicationName, True );
		  	      CloseKey;
			  	end;
			finally
				Reg.Free;
			end;
		end;

		LogHandle:= OpenEventLog( NIL, PChar(ApplicationName) );
		if Loghandle<>0 then
		begin
  		eType := 0;
		  	case EventType of
				etError:        eType := 1;
        etWarning:      eType := 2;
				etInformation:  eType := 4;
				etAuditSuccess: eType := 8;
				etAuditFailure: eType := 16;
			end;

        FUsername := #13#10;
			If IncludeUserName then
			begin
			  nSize := 20 ; // Max UserName
			  aName := stralloc ( nSize+1 );
			  OK := GetUserName( aName, nSize );
 			  if not OK then strcopy( aName, 'N/A' );
			  FUserName := FUserName + 'User: ' + aName + #13#10;
			  strDispose( aName );
			end;
			eMsg := Pchar(FUserName + Line);

			ReportEvent(LogHandle, eType, EventCategory, EventID, NIL, 1, 0, @eMsg, NIL);
	 		CloseEventLog(LogHandle);
		end;
	end;
end;

end.
