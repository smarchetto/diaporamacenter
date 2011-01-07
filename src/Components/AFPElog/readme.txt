(*******************************************************************************
Subject    : afpEventLog Component
Version    : 1.0
Author     : Alfred Petri (alfred_petri@compuserve.com)
Copyright  : Copyright (c) 1997 by Alfred Petri. All rights reserved.
Description: This is a non-visual VCL component that encapsulates the
             NT 4.x REPORTEVENT function. The purpose of this component
             is to facilitate the generation of log entries in the
             Windows NT Event-Log.
Platform   : Delphi 3.01, NT
Date       : 8 October 1997
Release    : Freeware, just let me know what you think of it. If you make
             any modifications to the source, please send me a copy. I will
             verify your changes and give you proper credit when included.


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
- LogEvent:            Used to write a message to the Event Log. Typical call:
  afpEventLog1.LogEvent('Password Expired!'#13#10'Contact support!');

Notes:
*******************************************************************************)

