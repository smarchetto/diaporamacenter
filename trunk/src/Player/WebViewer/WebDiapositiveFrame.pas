unit WebDiapositiveFrame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  SHDocVw, Menus,
  Diapositive, DiaporamaRepository, UContainer;

type
  TUserEventType = (USER_ACTIVATE_FULL_SCREEN, USER_DEACTIVATE_FULL_SCREEN,
    TOGGLE_FULL_SCREEN);

  TUserEvent = procedure(const Sender: TObject;
    const event: TUserEventType) of object;

  // Viewer to display diapositive with html content
  // Uses a TWebBrowser compnent (Internet Explorer)
  TFrameWebDiapositive = class(TFrame)
  private
    //TODO : No need two variables TWebBrowser ?
    FWebBrowser1: TWebBrowser;
    FWebBrowser2: TWebBrowser;

    FWBContainer1 : TWBContainer;
    FWBContainer2 : TWBContainer;

    FFrontWebBrowser: TWebBrowser;
    FBackWebBrowser: TWebBrowser;

    FCurDispatch: IDispatch;

    FOnChangeEvent: TNotifyEvent;

    FUserEvent: TUserEvent;

    FPopUpMenu: TPopupMenu;

    procedure CreateMenu;

    procedure SetWebBrowsers(
      const backWebBrowser, frontWebBrowser: TWebBrowser;
      const backWebContainer, frontWebContainer: TWBContainer);
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;

    procedure Show;

    procedure PopupMenuClick(Sender: TObject);

    procedure NavigateComplete2Event(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);

    procedure DocumentCompleteEvent(Sender:TObject;
      const pDisp: IDispatch; var URL: OleVariant);

    procedure OnKeyDownExecute(Sender: TObject; var Key: Word;
      Shift: TShiftState);

    function PrepareDisplay(const aDiapositive: TDiapositive;
      const aRepository: TDiaporamaRepository): Boolean; overload;
    function PrepareDisplay(const anURL: string): Boolean; overload;

    procedure Display;

    property OnChange: TNotifyEvent read FOnChangeEvent write FOnChangeEvent;

    property UserEvent: TUserEvent read FUserEvent write FUserEvent;
  end;

implementation

{$R *.dfm}

uses
  MSXML2_TLB, Logs;

constructor TFrameWebDiapositive.Create(Owner: TComponent);
begin
  inherited Create(Owner);

  FWebBrowser1 := nil;
  FWebBrowser2 := nil;

  FOnChangeEvent := nil;
  FUserEvent := nil;
end;

procedure TFrameWebDiapositive.Show;
begin
  FWebBrowser1 := TWebBrowser.Create(nil);
  FWebBrowser1.Align := alClient;
  FWebBrowser1.Silent := True;
  FWebBrowser1.Cursor := crNone;
  InsertControl(FWebBrowser1);

  FWBContainer1 := TWBContainer.Create(FWebBrowser1);
  FWBContainer1.UseCustomCtxMenu := True;
  FWBContainer1.ShowScrollBars := False;

  FWebBrowser2 := TWebBrowser.Create(nil);
  FWebBrowser2.Align := alClient;
  FWebBrowser2.Silent := True;
  FWebBrowser2.Cursor := crNone;
  InsertControl(FWebBrowser2);

  FWBContainer2 := TWBContainer.Create(FWebBrowser2);
  FWBContainer2.UseCustomCtxMenu := True;
  FWBContainer2.ShowScrollBars := False;

  FWebBrowser1.Visible := False;
  FWebBrowser2.Visible := False;
  SetWebBrowsers(FWebBrowser2, FWebBrowser1, FWBContainer2, FWBContainer1);

  CreateMenu;
end;


procedure TFrameWebDiapositive.CreateMenu;
var
  mnItem: TMenuItem;
begin
  FPopupMenu := TPopupMenu.Create(nil);
  FPopupMenu.AutoPopup := True;
  mnItem := TMenuItem.Create(FPopupMenu);
  mnItem.Name := 'mnFullScreen';
  mnItem.Checked := True;
  mnItem.AutoCheck := True;
  mnItem.Caption := 'Plein écran';
  mnItem.OnClick := PopUpMenuClick;
  FPopupMenu.Items.Add(mnItem);
end;


destructor TFrameWebDiapositive.Destroy;
begin
  FWBContainer1.Free;
  FWBContainer2.Free;

  FWebBrowser1.Free;
  FWebBrowser2.Free;

  FPopupMenu.Free;

  inherited;
end;

procedure TFrameWebDiapositive.SetWebBrowsers(
  const backWebBrowser, frontWebBrowser: TWebBrowser;
  const backWebContainer, frontWebContainer: TWBContainer);
begin
  FCurDispatch := nil;

  FBackWebBrowser := backWebBrowser;
  FFrontWebBrowser := frontWebBrowser;

  FBackWebBrowser.OnDocumentComplete := DocumentCompleteEvent;
  FBackWebBrowser.OnNavigateComplete2 := NavigateComplete2Event;
  backWebContainer.OnKeyDown := nil;

  FFrontWebBrowser.OnDocumentComplete := nil;
  FFrontWebBrowser.OnNavigateComplete2 := nil;
  frontWebContainer.OnKeyDown := OnKeyDownExecute;

  FFrontWebBrowser.BringToFront;
  FFrontWebBrowser.Cursor := crNone;

  FFrontWebBrowser.PopupMenu := FPopupMenu;
  FBackWebBrowser.PopUpMenu := nil;
end;

procedure TFrameWebDiapositive.Display;
begin
  if FFrontWebBrowser = FWebBrowser1 then
    SetWebBrowsers(FWebBrowser1, FWebBrowser2, FWBContainer1, FWBContainer2)
  else
    SetWebBrowsers(FWebBrowser2, FWebBrowser1, FWBContainer2, FWBContainer1);
end;

function TFrameWebDiapositive.PrepareDisplay(const aDiapositive: TDiapositive;
  const aRepository: TDiaporamaRepository): Boolean;
var
  htmlFilePath: string;
  htmlStream: TMemoryStream;
begin
  Result := False;

  if Assigned(aDiapositive) and Assigned(aRepository) then
  begin
    htmlFilePath := aRepository.getDiapositiveFilePath(aDiapositive);

    if not FileExists(htmlFilePath) then
    begin
      htmlStream := TMemoryStream.Create;
      try
        aDiapositive.GetContent(htmlStream);
        htmlStream.SaveToFile(htmlFilePath);
      finally
        htmlStream.Free;
      end;
    end;

    if FileExists(htmlFilePath) then
    begin
      PrepareDisplay(htmlFilePath);

      Result := True;
    end;
  end;
end;

function TFrameWebDiapositive.PrepareDisplay(const anURL: string): Boolean;
var
  OleUrl: OleVariant;
begin
  OleUrl := anUrl;
  FBackWebBrowser.Navigate2(OleURL);
  Result := True;
end;

procedure TFrameWebDiapositive.NavigateComplete2Event(Sender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
begin
  if not Assigned(FCurDispatch) then
    FCurDispatch := pDisp;
end;

procedure TFrameWebDiapositive.DocumentCompleteEvent(Sender:TObject;
  const pDisp: IDispatch; var URL: OleVariant);
begin
  if pDisp=FCurDispatch then
  begin
    if Assigned(FOnChangeEvent) then
      FOnChangeEvent(Self);
  end;
end;

procedure TFrameWebDiapositive.PopupMenuClick(Sender: TObject);
var
  mnItem: TMenuItem;
begin
  if Assigned(FUserEvent) then
  begin
    if Sender is TMenuItem then
    begin
      mnItem := TMenuItem(Sender);
      if mnItem.Name = 'mnFullScreen' then
      begin
        if mnItem.Checked then
          FUserEvent(Self, USER_ACTIVATE_FULL_SCREEN)
        else
          FUserEvent(Self, USER_DEACTIVATE_FULL_SCREEN)
      end;
    end;
  end;
end;

procedure TFrameWebDiapositive.OnKeyDownExecute(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key=VK_ESCAPE then
    FUserEvent(Self, TOGGLE_FULL_SCREEN)
end;


end.
