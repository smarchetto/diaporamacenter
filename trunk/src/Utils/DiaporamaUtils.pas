unit DiaporamaUtils;

interface

uses
  MSXML2_TLB,
  Controls,
  ComCtrls;

const
  ES_SYSTEM_REQUIRED  = $01;
  ES_DISPLAY_REQUIRED = $02;

function getAttributeValue(const aNode: IXMLDomNode;
  const attributeName: string): string;

procedure setAttributeValue(const xmlDocument: IXMLDomDocument;
  const aNode: IXMLDomNode; const attributeName: string;
  const value: string);

function getNodeValue(const rootNode: IXMLDomNode;
  const path: string;
  const defaultValue: string = ''): string;

function getNodeValueAsBoolean(const rootNode: IXMLDomNode;
  const path: string;
  const defaultValue: Boolean): Boolean;

procedure setNodeValue(const xmlDocument: IXMLDomDocument;
  const rootNode: IXMLDomNode;
  const path: string;
  const value: string);

function GetControlByName(const pageControl: TPageControl;
  const pageIndex: Integer; const aName: string): TControl; overload;

function GetControlByName(const aWinControl: TWinControl;
  const aName: string): TControl; overload;

function IncludeXMLExtension(const filePath: string): string;

function IsRemoteSession: Boolean;

function OpenFolderDialog(const Title: string = 'Choose a folder'): string;

function ConnectedToInternet: Boolean;

function SetThreadExecutionState(ExecutionState: Cardinal): Cardinal; stdcall;
  external 'Kernel32.dll' name 'SetThreadExecutionState';

implementation

uses
  SysUtils, Windows, ShlObj, Forms;

// Returns Internet connection state
function InternetGetConnectedState(out description: Integer;
  const reservedValue: Integer): Boolean; stdcall;
  external 'Wininet.dll' name 'InternetGetConnectedState';

function getAttributeValue(const aNode: IXMLDomNode;
  const attributeName: string): string;
var
  attr: IXmlDomNode;
begin
  Result := '';
  if Assigned(aNode) and (attributeName<>'') then
  begin
    attr := aNode.attributes.GetNamedItem(attributeName);
    if Assigned(attr) then
      Result := attr.NodeValue
  end;
end;

procedure setAttributeValue(const xmlDocument: IXMLDomDocument;
  const aNode: IXMLDomNode; const attributeName: string;
  const value: string);
var
  attr: IXmlDomAttribute;
  //element: IXMLDomElement; 
begin
  if Assigned(aNode) and (attributeName<>'') then
  begin
    attr := xmlDocument.createAttribute(attributeName);      
    attr.value := value;
    aNode.attributes.setNamedItem(attr);
  end;                        
end;

function getNodeValue(const rootNode: IXMLDomNode;
  const path: string;
  const defaultValue: string): string;
var
  aNode: IXMLDomNode;
begin
  Result := '';
  if Assigned(rootNode) and (path<>'') then
  begin
    aNode := rootNode.selectSingleNode(path);
    if Assigned(aNode) then
      Result := aNode.Text
    else
      Result := defaultValue;
  end;
end;

function getNodeValueAsBoolean(const rootNode: IXMLDomNode;
  const path: string;
  const defaultValue: Boolean): Boolean;
var
  boolStr: string;
begin
  Result := false;
  boolStr := getNodeValue(rootNode, path);
  try
    if boolStr<>'' then
      Result := StrToBool(boolStr);
  except
    on e: EConvertError do
      Result := defaultValue;
  end;
end;

procedure setNodeValue(const xmlDocument: IXMLDomDocument;
  const rootNode: IXMLDomNode;
  const path: string;
  const value: string);
var
  aNode: IXMLDomNode;
begin
  if Assigned(xmlDocument) and Assigned(rootNode) and (path<>'') then
  begin
    aNode := xmlDocument.CreateElement(path);
    if Assigned(aNode) then
    begin
      rootNode.AppendChild(aNode);
      aNode.Text := Value;
    end;
  end;
end;

function GetControlByName(const aWinControl: TWinControl;
  const aName: string): TControl;
var
  i: Integer;
begin
  if Assigned(aWinControl) and (aName<>'') then
  begin
    for i:=0 to aWinControl.ControlCount-1 do
    begin
      Result := aWinControl.Controls[i];
      if Result.Name = aName then
        Exit
      else
      if Result is TWinControl then
      begin
        Result := GetControlByName(TWinControl(Result), aName);
        if Assigned(Result) then
          Exit;
      end;
    end;
  end;
  Result := nil;
end;

function GetControlByName(const pageControl: TPageControl;
  const pageIndex: Integer; const aName: string): TControl;
var
  tabSheet: TTabSheet;
begin
  Result := nil;
  if Assigned(pageControl) and (aName<>'') then
  begin
    if (pageIndex>=0) and (pageIndex<pageControl.PageCount) then
    begin
      tabSheet := pageControl.pages[pageIndex];
      if Assigned(tabSheet) then
        Result := GetControlByName(tabSheet, aName + IntToStr(pageIndex));
    end;
  end;
end;

function IncludeXMLExtension(const filePath: string): string;
var
  ext: string;
begin
  ext := LowerCase(ExtractFileExt(filePath));
  if ext='' then
    Result := filePath + '.xml'
  else if ext<>'.xml' then
    Result := ChangeFileExt(filePath, '.xml')
  else
    Result := filePath;
end;

function IsRemoteSession: Boolean;
begin
  Result := GetSystemMetrics(SM_REMOTESESSION)>0;
end;

function BrowseDialogCallBack
  (Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM):
  integer stdcall;
var
  wa, rect: TRect;
  dialogPT: TPoint;
begin
  //center in work area
  if uMsg = BFFM_INITIALIZED then
  begin
    wa := Screen.WorkAreaRect;
    GetWindowRect(Wnd, Rect);
    dialogPT.X := ((wa.Right-wa.Left) div 2) -
                  ((rect.Right-rect.Left) div 2);
    dialogPT.Y := ((wa.Bottom-wa.Top) div 2) -
                  ((rect.Bottom-rect.Top) div 2);
    MoveWindow(Wnd, dialogPT.X, dialogPT.Y, Rect.Right-Rect.Left,
      Rect.Bottom-Rect.Top, True);
  end;

  Result := 0;
end;

function OpenFolderDialog(const Title: string): string;
var
  lpItemID: PItemIDList;
  BrowseInfo: TBrowseInfo;
  DisplayName: array[0..MAX_PATH] of char;
  TempPath: array[0..MAX_PATH] of char;
begin
  Result := '';
  FillChar(BrowseInfo, sizeof(TBrowseInfo), #0);
  with BrowseInfo do
  begin
    hwndOwner := Application.Handle;
    pszDisplayName := @DisplayName;
    lpszTitle := PChar(Title);
    ulFlags := BIF_RETURNONLYFSDIRS;
    lpfn := BrowseDialogCallBack;
  end;
  lpItemID := SHBrowseForFolder(BrowseInfo);
  if lpItemId <> nil then begin
    SHGetPathFromIDList(lpItemID, TempPath);
    Result := TempPath;
    GlobalFreePtr(lpItemID);
  end;
end;

// Returns Internet connection state
function ConnectedToInternet: Boolean;
var
  desc: Integer;
begin
  Result := InternetGetConnectedState(desc, 0);
end;


end.
