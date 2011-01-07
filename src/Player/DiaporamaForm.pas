unit DiaporamaForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Forms, Controls,
  WebDiapositiveFrame, Diapositive, DiaporamaRepository;

type
  // Form container of generic frame that displays diapositive content
  // For now, can contain only web viewer frame
  TDiaporamaForm = class(TCustomForm)
  private
    FMonitor: TMonitor;

    FWebDiapositiveFrame: TFrameWebDiapositive;

    FOnCloseEvent: TNotifyEvent;

    FFullScreen: Boolean;

    procedure SetFullScreen;
    procedure UnsetFullScreen;

    procedure PlaceOnMonitor;

    function GetOnChangeEvent: TNotifyEvent;
    procedure SetOnChangeEvent(const value: TNotifyEvent);

    procedure UserEventExecute(const Sender: TObject;
      const event: TUserEventType);
  public
    constructor CreateNew(aOwner: TComponent; Dummy: Integer = 0); override;
    destructor Destroy; override;

    procedure OnCloseExecute(Sender: TObject; var Action: TCloseAction);

    procedure Show; reintroduce;

    procedure SetMonitor(const aMonitor: TMonitor); overload;

    function PrepareDisplay(const aDiapositive: TDiapositive;
      const aRepository: TDiaporamaRepository): Boolean;
    procedure Display;

    property OnClose: TNotifyEvent read FOnCloseEvent
      write FOnCloseEvent;

    property OnChange: TNotifyEvent read GetOnChangeEvent
      write SetOnChangeEvent;
  end;

implementation

constructor TDiaporamaForm.CreateNew(aOwner: TComponent; Dummy: Integer = 0);
begin
  inherited CreateNew(aOwner, Dummy);

  FWebDiapositiveFrame := TFrameWebDiapositive.Create(nil);
  FWebDiapositiveFrame.Parent := Self;
  FWebDiapositiveFrame.Align := AlClient;

  FWebDiapositiveFrame.UserEvent := UserEventExecute;

  FMonitor := nil;

  FOnCloseEvent := nil;
  inherited OnClose := OnCloseExecute;

  FFullScreen := False;
end;

destructor TDiaporamaForm.Destroy;
begin
  FWebDiapositiveFrame.Free;
  inherited;
end;

procedure TDiaporamaForm.PlaceOnMonitor;
begin
  if Assigned(FMonitor) then
  begin
    Left := FMonitor.Left;
    Top := FMonitor.Top;
    Width := FMonitor.Width;
    Height := FMonitor.Height;
  end;
end;

procedure TDiaporamaForm.SetMonitor(const aMonitor: TMonitor);
begin
  FMonitor := aMonitor;
  PlaceOnMonitor;
end;

procedure TDiaporamaForm.SetFullScreen;
var
  HTaskbar: HWND;
  OldVal: LongInt;
begin
  // Simulation d'un ecran de veille
  SystemParametersInfo(SPI_SCREENSAVERRUNNING, Word(True), @OldVal, 0);

  // Désactivation et masquage de la barre des taches
  if FMonitor.Primary then
  begin
    HTaskBar := FindWindow('Shell_TrayWnd', nil);
    EnableWindow(HTaskBar, False);
    ShowWindow(HTaskbar, SW_HIDE);
  end;

  // Plus de bordures et au dessus quoiqu'il arrive
  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;

  // On occupe tout l'écran
  PlaceOnMonitor;

  //SetBounds(0, 0, Screen.Width, Screen.Height);
  FFullScreen := True;
end;

procedure TDiaporamaForm.UnsetFullScreen;
var
  HTaskbar: HWND;
  OldVal: LongInt;
begin
  // On sort de l'état d'écran de veille
  SystemParametersInfo(SPI_SCREENSAVERRUNNING, Word(False), @OldVal, 0);

  // Activation et affichage de la barre des taches
  if FMonitor.Primary then
  begin
    HTaskBar := FindWindow('Shell_TrayWnd', nil);
    EnableWindow(HTaskBar, True);
    ShowWindow(HTaskbar, SW_SHOW);
  end;

  // Fenetre redimensionnable
  BorderStyle := bsSizeable;
  FormStyle := fsNormal;

  // On occupe tout de meme tout l'ecran
  WindowState := wsMaximized;

  // Focus
  if Visible then
    SetFocus;

  FFullScreen := False;
end;

procedure TDiaporamaForm.Show;
begin
  inherited;
  //SetFullScreen;
  FWebDiapositiveFrame.Show;
end;

function TDiaporamaForm.PrepareDisplay(const aDiapositive: TDiapositive;
  const aRepository: TDiaporamaRepository): Boolean;
begin
  Result := FWebDiapositiveFrame.PrepareDisplay(aDiapositive, aRepository);
end;

procedure TDiaporamaForm.Display;
begin
  FWebDiapositiveFrame.Display;
end;


procedure TDiaporamaForm.OnCloseExecute(Sender: TObject;
  var Action: TCloseAction);
begin
  UnsetFullScreen;
  if Assigned(FOnCloseEvent) then
    FOnCloseEvent(Self);
end;

function TDiaporamaForm.GetOnChangeEvent: TNotifyEvent;
begin
  Result := FWebDiapositiveFrame.OnChange;
end;

procedure TDiaporamaForm.SetOnChangeEvent(const value: TNotifyEvent);
begin
  if Assigned(FWebDiapositiveFrame) then
    FWebDiapositiveFrame.OnChange := value;
end;

procedure TDiaporamaForm.UserEventExecute(const Sender: TObject;
  const event: TUserEventType);
begin
  case event of 
    USER_ACTIVATE_FULL_SCREEN : SetFullScreen;
    USER_DEACTIVATE_FULL_SCREEN : UnsetFullScreen;
    TOGGLE_FULL_SCREEN :
    begin
      if FFullScreen then
        UnsetFullScreen
      else
        SetFullScreen;
    end;
  end;
end;

end.
