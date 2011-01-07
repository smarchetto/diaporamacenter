unit DiaporamaPlayerFrame;

interface

uses
  Classes, Controls, Forms, ComCtrls, StdCtrls,
  ActnList, Generics.Defaults, Generics.Collections,
  DiaporamaCenterAgent, DiaporamaDevice, Diaporama;

type
  TFrameDiaporamaPlayer = class(TFrame)
    PageControl: TPageControl;
    ActionList: TActionList;
  private
    FDiaporamaCenterAgent: TDiaporamaCenterAgent;

    procedure CreatePlayerTabSheet(
      const diaporamaDevice: TDiaporamaDevice);

    procedure BuildGUI;
    procedure RefreshGUI;

    procedure FillDiaporamaCombo(const aComboBox: TComboBox;
      const diaporamaList: TEnumerable<TDiaporama>);

    function GetDiaporamaID(const aName: string): string;
    function GetDiaporamaComboBox(const tabIndex: Integer): TComboBox;
  public
    constructor Create(aOwner: TComponent;
      const diaporamaCenter: TDiaporamaCenterAgent); reintroduce;

    procedure actPlayUpdate(Sender: TObject);
    procedure actStopUpdate(Sender: TObject);
    procedure actPlayExecute(Sender: TObject);
    procedure actStopExecute(Sender: TObject);
  end;

implementation

uses
  SysUtils, Spin, StrUtils, Graphics,
  DiaporamaUtils, DiaporamaPlayer, Diapositive, GUIUtils;

const
  LEFT1 = 4;
  LEFT2 = 12;
  LEFT3 = 150;
  LEFT4 = 320;
  LEFT5 = 350;
  DELTA_TOP = 30;
  DELTA_TOP2 = 46;

  cstPlayExecute = 'actPlayExecute';
  cstStopExecute = 'actStopExecute';

{$R *.dfm}

constructor TFrameDiaporamaPlayer.Create(aOwner: TComponent;
  const diaporamaCenter: TDiaporamaCenterAgent);
begin
  inherited Create(aOwner);

  FDiaporamaCenterAgent := diaporamaCenter;

  BuildGUI;
  RefreshGUI;
end;

procedure TFrameDiaporamaPlayer.BuildGUI;
var
  i: Integer;
begin
  for i := 0 to FDiaporamaCenterAgent.DiaporamaDeviceCount-1 do
    CreatePlayerTabSheet(FDiaporamaCenterAgent.DiaporamaDevice[i]);
end;

procedure TFrameDiaporamaPlayer.CreatePlayerTabSheet(
  const diaporamaDevice: TDiaporamaDevice);
var
  sIndex: string;
  tabSheet: TTabSheet;
  aComboBox: TComboBox;
  aButton: TButton;
  aSpinEdit: TSpinEdit;
  anAction: TAction;
  y: Integer;
begin
  if not Assigned(diaporamaDevice) then
    Exit;

  tabSheet := TTabSheet.Create(pageControl);
  tabSheet.PageControl := pageControl;
  tabSheet.Caption := diaporamaDevice.Title;
  sIndex := IntToStr(diaporamaDevice.DeviceIndex);

  y := 8;

  // Current diaporama
  CreateLabel(tabSheet, 'lblPlay', 'Current diaporama', LEFT1, y, True);

  Inc(y, DELTA_TOP);

  CreateLabel(tabSheet, 'lblDiaporama', 'Diaporama:', LEFT2, y);

  aComboBox := CreateComboBox(tabSheet, 'cbDiaporama', LEFT3, y-3, 161);
  aComboBox.TabOrder := 0;

  Inc(y, DELTA_TOP);

  CreateLabel(tabSheet, 'lblDuration', 'Slide duration(s):', LEFT2, y);

  aSpinEdit := CreateSpinEdit(tabSheet, 'seDuration', LEFT3, y-3, 61,
    DIAPOSITIVE_DURATION_S, 0, 0);
  aSpinEdit.TabOrder := 1;

  Inc(y, DELTA_TOP);

  anAction := CreateAction(tabSheet, cstPlayExecute , 'Play', actPlayExecute,
    actPlayUpdate, ActionList);

  aButton := CreateButton(tabSheet, 'btnPlay', '', LEFT2, y, 88, anAction);
  aButton.TabOrder := 2;

  anAction := CreateAction(tabSheet, cstStopExecute , 'Stop', actStopExecute,
    actStopUpdate, ActionList);

  aButton := CreateButton(tabSheet, 'btnStop', '', 105, y, 88, anAction);
  aButton.TabOrder := 3;
end;

function TFrameDiaporamaPlayer.GetDiaporamaComboBox(const tabIndex: Integer): TComboBox;
begin
  Result := TComboBox(GetControlByName(PageControl, tabIndex, 'cbDiaporama'));
end;

procedure TFrameDiaporamaPlayer.RefreshGUI;
var
  diaporamaList: TEnumerable<TDiaporama>;
  aComboBox: TComboBox;
  i: integer;
begin
  diaporamaList := FDiaporamaCenterAgent.Repository.Diaporamas;
  if Assigned(diaporamaList) then
  begin
    for i := 0 to FDiaporamaCenterAgent.DiaporamaDeviceCount-1 do
    begin
      aComboBox := GetDiaporamaComboBox(i);
      if Assigned(aComboBox) then
        FillDiaporamaCombo(aComboBox, diaporamaList)
    end;
  end;
end;

procedure TFrameDiaporamaPlayer.FillDiaporamaCombo(const aComboBox: TComboBox;
  const diaporamaList: TEnumerable<TDiaporama>);
var
  aDiaporama: TDiaporama;
begin
  aComboBox.Items.Clear;

  if not Assigned(diaporamaList) then
    Exit;

  for aDiaporama in diaporamaList do
    aComboBox.Items.Add(aDiaporama.Name);

  if aComboBox.Items.Count>0 then
    aComboBox.ItemIndex := 0;
end;

function TFrameDiaporamaPlayer.GetDiaporamaID(const aName: string): string;
var
  aDiaporama: TDiaporama;
begin
  aDiaporama := FDiaporamaCenterAgent.Repository.GetDiaporamaByName(aName);
  if Assigned(aDiaporama) then
    Result := aDiaporama.ID
  else
    Result := '';
end;

procedure TFrameDiaporamaPlayer.actPlayUpdate(Sender: TObject);
var
  action: TAction;
  sIndex: string;
  playerIndex: Integer;
  diaporamaPlayer: TDiaporamaPlayer;
  status: TDiaporamaPlayerStatus;
  aComboBox: TComboBox;
begin
  if not Assigned(Sender) or not (Sender is TAction) then
    Exit;

  action := TAction(Sender);

  sIndex := Copy(action.Name, Length(cstPlayExecute)+1,
      Length(action.Name)-Length(cstPlayExecute));
  playerIndex := StrToIntDef(sIndex, -1);

  diaporamaPlayer := FDiaporamaCenterAgent.DiaporamaPlayer[playerIndex];

  if Assigned(diaporamaPlayer) then
  begin
    status := diaporamaPlayer.PlayerStatus;

    aComboBox := GetDiaporamaComboBox(playerIndex);

    if Assigned(aComboBox) then
      action.Enabled := (status <> dpsPlaying)
        and (aComboBox.ItemIndex<>-1);
  end else
    action.Enabled := False;
end;

procedure TFrameDiaporamaPlayer.actStopUpdate(Sender: TObject);
var
  action: TAction;
  sIndex: string;
  playerIndex: Integer;
  diaporamaPlayer: TDiaporamaPlayer;
  status: TDiaporamaPlayerStatus;
begin
  if not Assigned(Sender) or not (Sender is TAction) then
    Exit;

  action := TAction(Sender);

  sIndex := Copy(action.Name, Length(cstStopExecute)+1,
      Length(action.Name)-Length(cstStopExecute));
  playerIndex := StrToIntDef(sIndex, -1);

  diaporamaPlayer := FDiaporamaCenterAgent.DiaporamaPlayer[playerIndex];

  if Assigned(diaporamaPlayer) then
  begin
    status := diaporamaPlayer.PlayerStatus;

    action.Enabled := (status = dpsPlaying) or
      (status = dpsSuspended)
  end else
    action.Enabled := False;
end;

procedure TFrameDiaporamaPlayer.actPlayExecute(Sender: TObject);
var
  diaporamaID: string;
  diaporamaDeviceIndex, duration: Integer;
  aComboBox: TComboBox;
  aSpinEdit: TSpinEdit;
begin
  diaporamaDeviceIndex := PageControl.TabIndex;
  aComboBox := GetDiaporamaComboBox(diaporamaDeviceIndex);
  aSpinEdit := TSpinEdit(GetControlByName(PageControl,
    diaporamaDeviceIndex, 'seDuration'));

  if Assigned(aComboBox) then
  begin
    diaporamaID := GetDiaporamaID(aComboBox.Text);

    if Assigned(aSpinEdit) then
      duration := aSpinEdit.Value
    else
      duration := DIAPOSITIVE_DURATION_S;
    FDiaporamaCenterAgent.PlayDiaporama(diaporamaID, diaporamaDeviceIndex,
      duration);
  end;
end;

procedure TFrameDiaporamaPlayer.actStopExecute(Sender: TObject);
var
  diaporamaDeviceIndex: Integer;
begin
  diaporamaDeviceIndex := PageControl.TabIndex;
  FDiaporamaCenterAgent.StopDiaporama(diaporamaDeviceIndex);
end;


end.
