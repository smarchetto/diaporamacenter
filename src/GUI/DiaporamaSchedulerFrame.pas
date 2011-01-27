unit DiaporamaSchedulerFrame;

interface

uses
  Classes, Controls, Forms, ComCtrls, StdCtrls, ActnList, Contnrs, ExtCtrls,
  Generics.Defaults, Generics.Collections,
  DiaporamaCenterAgent, DiaporamaScheduler, ScheduleAction,
  DiaporamaDevice, DiaporamaPlayer, Diaporama;

type
  TFrameDiaporamaScheduler = class(TFrame)
    devicePageControl: TPageControl;
    pnlButton: TPanel;
    btnApplySettings: TButton;
    btnSaveSettings: TButton;
    ActionList: TActionList;
    actSaveDeviceSettings: TAction;
    actApplyDeviceSettings: TAction;
    diaporamaPageControl: TPageControl;
    pnlPageControl: TPanel;
    pnlDiaporama: TPanel;
    pnlDiaporamaHeader: TPanel;
    lblDiaporamaHeader: TLabel;
    pnlDevice: TPanel;
    pnlDeviceHeader: TPanel;
    lblDeviceHeader: TLabel;

    procedure OnCheckBoxClick(Sender: TObject);
    procedure UpdateFromGUI(Sender: TObject);

    procedure actApplyDeviceSettingsExecute(Sender: TObject);
    procedure actApplyDeviceSettingsUpdate(Sender: TObject);
    procedure actSaveDeviceSettingsExecute(Sender: TObject);
    procedure actSaveDeviceSettingsUpdate(Sender: TObject);
  private
    FDiaporamaCenterAgent: TDiaporamaCenterAgent;

    FSavedSchedule: TDiaporamaScheduler;
    FEditedSchedule: TDiaporamaScheduler;

    procedure CheckBoxClickRefresh(Sender: TObject);

    function GetAction(sourceName: string;
      const actionCode: Integer): TScheduleAction; reintroduce;
    function GetEditedAction(sourceName: string;
      const actionCode: Integer): TScheduleAction;

    procedure CreateScheduleActionGUI(
      const actionName, checkBoxCaption, comboValues, labelCaption,
      defaultTime: string; const aContainer: TwinControl;
      var y, aTabOrder: Integer);

    procedure CreateDeviceScheduleTabSheet(
      const diaporamaDevice: TDiaporamaDevice);
    procedure CreateDiaporamaScheduleTabSheet(const diaporama: TDiaporama);

    function GetTabSheetIndex(
      const diaporamaDevice: TDiaporamaDevice): Integer;

    procedure UpdateAction(
      const aScheduleAction: TScheduleAction; const aContainer: TWinControl;
      const tabIndex: Integer; const controlName: string); reintroduce;

    procedure RefreshAction(
      const aScheduleAction: TScheduleAction; const aContainer: TWinControl;
      const tabIndex: Integer; const controlName: string);

    procedure FillDiaporamaCombo(const aComboBox: TComboBox;
      const diaporamaList: TEnumerable<TDiaporama>);

    function GetDiaporamaItemIndex(const aComboBox: TComboBox;
      const anID: string): Integer;

    function GetDiaporamaID(const aName: string): string;
  public
    constructor Create(aOwner: TComponent;
      const diaporamaCenter: TDiaporamaCenterAgent); reintroduce;
    destructor Destroy; override;

    procedure BuildGUI;
    procedure RefreshGUI;
  end;

implementation

uses
  SysUtils, Spin, StrUtils, Graphics,
  DiaporamaDownloader, Diapositive,
  DiaporamaUtils, GUIUtils;

const
  LEFT1 = 4;
  LEFT2 = 12;
  LEFT3 = 150;
  LEFT4 = 320;
  LEFT5 = 350;
  LEFT6 = 400;

  DELTA_TOP = 30;
  DELTA_TOP2 = 36;

  cstPeriodicityStr =
  'Every day,Every day except sunday,Every day except week end';

{$R *.dfm}

constructor TFrameDiaporamaScheduler.Create(aOwner: TComponent;
  const diaporamaCenter: TDiaporamaCenterAgent);
begin
  inherited Create(aOwner);

  FDiaporamaCenterAgent := diaporamaCenter;

  BuildGUI;
  RefreshGUI;

  FEditedSchedule := FDiaporamaCenterAgent.Scheduler.Copy;
  FSavedSchedule := FDiaporamaCenterAgent.Scheduler.Copy;
end;

destructor TFrameDiaporamaScheduler.Destroy;
begin
  // FIXME : free these objects provoke an exception at app closing
  //FSavedSchedule.Free;
  //FEditedSchedule.Free;
  inherited;
end;

procedure TFrameDiaporamaScheduler.BuildGUI;
var
  y, aTabOrder: Integer;
  aDiaporama: TDiaporama;
  aLabel: TLabel;
  i: integer;
begin
  y := 24;
  aTabOrder := 0;
  aLabel := CreateLabel(pnlDevice, 'lblPowerAllDevices',
    'Power on/off all devices', LEFT1, y, True);
  aLabel.Font.Color := clBackGround;

  // Auto power on all devices
  Inc(y, DELTA_TOP);
  CreateScheduleActionGUI('PowerOnAllDevices', 'Power on:', cstPeriodicityStr,
    'à :', '08:00', pnlDevice, y, aTabOrder);

  // Auto power off all devices
  Inc(y, DELTA_TOP);
  CreateScheduleActionGUI('PowerOffAllDevices', 'Power off:', cstPeriodicityStr,
    'à :', '23:00', pnlDevice, y, aTabOrder);

  for i := 0 to FDiaporamaCenterAgent.DiaporamaDeviceCount-1 do
    CreateDeviceScheduleTabSheet(FDiaporamaCenterAgent.DiaporamaDevice[i]);
  for aDiaporama in FDiaporamaCenterAgent.Repository.Diaporamas do
    CreateDiaporamaScheduleTabSheet(aDiaporama);
end;

procedure TFrameDiaporamaScheduler.CreateScheduleActionGUI(
  const actionName, checkBoxCaption, comboValues, labelCaption, defaultTime: string;
  const aContainer: TWinControl; var y, aTabOrder: Integer);
var
  aCheckBox: TCheckBox;
  aComboBox: TComboBox;
  aTimePicker: TDateTimePicker;
begin
  aCheckBox := CreateCheckBox(aContainer, 'cbx'+actionName, checkBoxCaption,
    LEFT2, y);
  aCheckBox.OnClick := OnCheckBoxClick;

  aComboBox := CreateComboBox(aContainer, 'cmb'+actionName, LEFT3, y-3, 160);
  aComboBox.Items.StrictDelimiter := True;
  aComboBox.Items.CommaText := cstPeriodicityStr;
  aComboBox.OnChange := UpdateFromGUI;
  aComboBox.TabOrder := aTabOrder;

  CreateLabel(aContainer, 'lbl'+actionName+'At', labelCaption, LEFT4, y);

  aTimePicker := CreateTimePicker(aContainer, 'tp'+actionName, LEFT5, y-3);
  //aTimePicker.DateTime := StrToTime(defaultTime);
  aTimePicker.OnChange := UpdateFromGUI;
  Inc(aTabOrder);
  aTimePicker.TabOrder := aTabOrder;

  Inc(aTabOrder);
end;

procedure TFrameDiaporamaScheduler.CreateDeviceScheduleTabSheet(
  const diaporamaDevice: TDiaporamaDevice);
var
  tabSheet: TTabSheet;
  aLabel: TLabel;
  aComboBox: TComboBox;
  aSpinEdit: TSpinEdit;
  y, aTabOrder: Integer;
begin
  if not Assigned(diaporamaDevice) then
    Exit;

  tabSheet := TTabSheet.Create(devicePageControl);
  tabSheet.PageControl := devicePageControl;
  tabSheet.Caption := diaporamaDevice.Title;

  y := 8;
  aTabOrder := 2;

  aLabel := CreateLabel(tabsheet, 'lblPowerOnOff', 'Power on/off', LEFT1, y,
    True);
  aLabel.Font.Color := clBackGround;

  // Auto power on
  Inc(y, DELTA_TOP);
  CreateScheduleActionGUI('PowerOn', 'Power on:', cstPeriodicityStr,
    'à :', '08:00', tabSheet, y, aTabOrder);

  // Auto power off
  Inc(y, DELTA_TOP);
  CreateScheduleActionGUI('PowerOff', 'Power off:', cstPeriodicityStr,
    'à :', '23:00', tabSheet, y, aTabOrder);

  // Auto play
  Inc(y, DELTA_TOP2);
  aLabel := CreateLabel(tabsheet, 'lblPlay', 'Play diaporama', LEFT1, y, True);
  aLabel.Font.Color := clBackGround;

  Inc(y, DELTA_TOP);
  CreateScheduleActionGUI('Play', 'Play:', cstPeriodicityStr, 'à :', '08:05',
    tabSheet, y, aTabOrder);

  Inc(y, DELTA_TOP);
  CreateLabel(tabsheet, 'lblDiaporama', 'Diaporama:', LEFT2, y);

  aComboBox := CreateComboBox(tabsheet, 'cmbDiaporamaList', LEFT3, y-3, 161);
  Inc(aTabOrder);
  aComboBox.TabOrder := aTabOrder;
  aComboBox.OnChange := UpdateFromGUI;

  Inc(y, DELTA_TOP);
  CreateLabel(tabsheet, 'lblPlayDuration', 'Slide duration(s):',
    LEFT2, y);

  aSpinEdit := CreateSpinEdit(tabsheet, 'sePlayDuration', LEFT3, y-3, 61, 5, 0, 0);
  Inc(aTabOrder);
  aSpinEdit.TabOrder := aTabOrder;
  aSpinEdit.OnChange := UpdateFromGUI;

  // Auto stop
  Inc(y, DELTA_TOP);
  Inc(aTabOrder);

  CreateScheduleActionGUI('Stop', 'Stop:', cstPeriodicityStr,
    'à :', '22:55', tabSheet, y, aTabOrder);
end;

procedure TFrameDiaporamaScheduler.CreateDiaporamaScheduleTabSheet(
  const diaporama: TDiaporama);
var
  tabSheet: TTabSheet;
  y, aTabOrder: Integer;
begin
  if not Assigned(diaporama) then
    Exit;

  tabSheet := TTabSheet.Create(diaporamaPageControl);
  tabSheet.PageControl := diaporamaPageControl;
  if diaporama.Name<>'' then
    tabSheet.Caption := diaporama.Name
  else
    tabSheet.Caption := Format('ID = %s', [diaporama.ID]);

  // Auto diaporama update
  y := 8;
  aTabOrder := 0;
  CreateScheduleActionGUI('Update', 'Update:',
    cstPeriodicityStr + ',Every hour', 'at:', '08am', tabSheet,
    y, aTabOrder);
end;

function TFrameDiaporamaScheduler.GetAction(sourceName: string;
  const actionCode: Integer): TScheduleAction;
begin
  Result := FDiaporamaCenterAgent.Scheduler.GetAction(sourceName, actionCode);
end;

function TFrameDiaporamaScheduler.GetEditedAction(sourceName: string;
  const actionCode: Integer): TScheduleAction;
begin
  Result := FEditedSchedule.GetAction(sourceName, actionCode);
end;

function TFrameDiaporamaScheduler.GetTabSheetIndex(
  const diaporamaDevice: TDiaporamaDevice): Integer;
begin
  if Assigned(diaporamaDevice) then
    Result := diaporamaDevice.DeviceIndex-1
  else
    Result := -1;
end;

procedure TFrameDiaporamaScheduler.UpdateAction(
  const aScheduleAction: TScheduleAction; const aContainer: TWinControl;
  const tabIndex: Integer; const controlName: string);
var
  aDateTimePicker: TDateTimePicker;
  aCheckBox: TCheckBox;
  aComboBox: TComboBox;
begin
  if Assigned(aScheduleAction) then
  begin
    if aContainer is TPageControl then
      aCheckBox := TCheckBox(getControlByName(TPageControl(aContainer), tabIndex,
        'cbx' + controlName))
    else
      aCheckBox := TCheckBox(getControlByName(aContainer,
        'cbx' + controlName));

    if Assigned(aCheckBox) then
      aScheduleAction.Enabled := aCheckBox.Checked;

    if aContainer is TPageControl then
      aComboBox := TComboBox(getControlByName(TPageControl(aContainer), tabIndex,
        'cmb' + controlName))
    else
      aComboBox := TComboBox(getControlByName(aContainer,
        'cmb' + controlName));

    if Assigned(aComboBox) then
      aScheduleAction.Periodicity.PeriodicityType :=
        TPeriodicityType(aComboBox.ItemIndex);

    if aContainer is TPageControl then
      aDateTimePicker := TDateTimePicker(getControlByName(TPageControl(aContainer),
        tabIndex, 'tp' + controlName))
    else
      aDateTimePicker := TDateTimePicker(getControlByName(aContainer,
        'tp' + controlName));

    if Assigned(aDateTimePicker) then
      aScheduleAction.Periodicity.Time := aDateTimePicker.Time;
  end;
end;

procedure TFrameDiaporamaScheduler.UpdateFromGUI(Sender: TObject);
var
  aScheduleAction: TScheduleAction;
  aComboBox: TComboBox;
  aSpinEdit: TSpinEdit;
  diaporamaID: string;
  i, tabIndex: Integer;
begin
  // Auto power on of all devices
  aScheduleAction := GetEditedAction(
    'DiaporamaCenterAgent', ACT_POWER_ON_ALL_DEVICES);

  UpdateAction(aScheduleAction, pnlDevice, 0, 'PowerOnAllDevices');

  // Auto power off of all devices
  aScheduleAction := GetEditedAction(
    'DiaporamaCenterAgent', ACT_POWER_OFF_ALL_DEVICES);

  UpdateAction(aScheduleAction, pnlDevice, 0, 'PowerOffAllDevices');

  // For each device
  for i := 0 to FDiaporamaCenterAgent.DiaporamaDeviceCount-1 do
  begin
    tabIndex := GetTabSheetIndex(FDiaporamaCenterAgent.DiaporamaDevice[i]);

    // Auto power on
    aScheduleAction := GetEditedAction(
      FDiaporamaCenterAgent.DiaporamaDevice[i].GetSourceName, ACT_POWER_ON);

    UpdateAction(aScheduleAction, devicePageControl, tabIndex, 'PowerOn');

    // Auto power off
    aScheduleAction := GetEditedAction(
      FDiaporamaCenterAgent.DiaporamaDevice[i].GetSourceName, ACT_POWER_OFF);

    UpdateAction(aScheduleAction, devicePageControl, tabIndex, 'PowerOff');

    // Auto play
    aScheduleAction := GetEditedAction(
      FDiaporamaCenterAgent.DiaporamaPlayer[i].GetSourceName,
      ACT_PLAY_DIAPORAMA);

    UpdateAction(aScheduleAction, devicePageControl, tabIndex, 'Play');

    // Diaporama to be played
    aComboBox := TComboBox(GetControlByName(devicePageControl,
      GetTabSheetIndex(FDiaporamaCenterAgent.DiaporamaDevice[i]),
      'cmbDiaporamaList'));
    if Assigned(aComboBox) then
    begin
      diaporamaID := GetDiaporamaID(aComboBox.Text);
      if diaporamaID<>'' then
        aScheduleAction.Parameters.Values[cstDiaporamaIDParam] := diaporamaID;
    end;

    // Diapositive duration
    aSpinEdit := TSpinEdit(GetControlByName(devicePageControl,
      GetTabSheetIndex(FDiaporamaCenterAgent.DiaporamaDevice[i]),
        'sePlayDuration'));
    if Assigned(aSpinEdit) then
      aScheduleAction.Parameters.Values[cstDurationParam] :=
        IntToStr(aSpinEdit.Value);

    // Auto stop
    aScheduleAction := GetEditedAction(
      FDiaporamaCenterAgent.DiaporamaPlayer[i].GetSourceName,
        ACT_STOP_DIAPORAMA);

    UpdateAction(aScheduleAction, devicePageControl, tabIndex, 'Stop');
  end;

  // For each diaporama
  for i := 0 to FDiaporamaCenterAgent.Repository.DiaporamaCount-1 do
  begin
    // Auto update
    aScheduleAction := GetEditedAction(Format('Diaporama %s downloader',
      [FDiaporamaCenterAgent.Repository.Diaporama[i].ID]), ACT_UPDATE_DIAPORAMA);

    UpdateAction(aScheduleAction, diaporamaPageControl, i, 'Update');
  end;
end;

procedure TFrameDiaporamaScheduler.RefreshAction(
  const aScheduleAction: TScheduleAction; const aContainer: TWinControl;
  const tabIndex: Integer; const controlName: string);
var
  aComboBox: TComboBox;
  aCheckBox: TCheckBox;
  aDateTimePicker: TDateTimePicker;
begin
  if Assigned(aScheduleAction) then
  begin
    if aContainer is TPageControl then
      aCheckBox := TCheckBox(getControlByName(TPageControl(aContainer), tabIndex,
        'cbx' + controlName))
    else
      aCheckBox := TCheckBox(getControlByName(aContainer,
        'cbx' + controlName));

    if Assigned(aCheckBox) then
    begin
      aCheckBox.OnClick := nil;
      aCheckBox.Checked := aScheduleAction.Enabled;
      aCheckBox.OnClick := OnCheckBoxClick;
      CheckBoxClickRefresh(aCheckBox);
    end;

    if aContainer is TPageControl then
      aComboBox := TComboBox(getControlByName(TPageControl(aContainer), tabIndex,
        'cmb' + controlName))
    else
      aComboBox := TComboBox(getControlByName(aContainer,
        'cmb' + controlName));

    if Assigned(aComboBox) then
    begin
      aComboBox.OnChange := nil;
      aComboBox.ItemIndex :=
        Ord(aScheduleAction.Periodicity.PeriodicityType);
      aComboBox.OnChange := UpdateFromGUI;
    end;

    if aContainer is TPageControl then
      aDateTimePicker := TDateTimePicker(getControlByName(TPageControl(aContainer),
        tabIndex, 'tp' + controlName))
    else
      aDateTimePicker := TDateTimePicker(getControlByName(aContainer,
        'tp' + controlName));

    if Assigned(aDateTimePicker) then
    begin
      aDateTimePicker.OnChange := nil;
      aDateTimePicker.Time := aScheduleAction.Periodicity.Time;
      aDateTimePicker.OnChange := UpdateFromGUI;
    end;
  end;
end;

procedure TFrameDiaporamaScheduler.RefreshGUI;
var
  aScheduleAction: TScheduleAction;
  aComboBox: TComboBox;
  aSpinEdit: TSpinEdit;
  diaporamaID, diapositiveDuration: string;
  i, tabIndex, idx: Integer;
begin
  // Auto power on
  aScheduleAction := GetAction(
    'DiaporamaCenterAgent', ACT_POWER_ON_ALL_DEVICES);

  RefreshAction(aScheduleAction, pnlDevice, 0, 'PowerOnAllDevices');

  // Auto power off
  aScheduleAction := GetAction(
    'DiaporamaCenterAgent', ACT_POWER_OFF_ALL_DEVICES);

  RefreshAction(aScheduleAction, pnlDevice, 0, 'PowerOffAllDevices');

  // For each device
  for i := 0 to FDiaporamaCenterAgent.DiaporamaDeviceCount-1 do
  begin
    tabIndex := GetTabSheetIndex(FDiaporamaCenterAgent.DiaporamaDevice[i]);

    // Auto power on
    aScheduleAction := GetAction(
      FDiaporamaCenterAgent.DiaporamaDevice[i].GetSourceName,
      ACT_POWER_ON);

    RefreshAction(aScheduleAction, devicePageControl, tabIndex, 'PowerOn');

    // Auto power off
    aScheduleAction := GetAction(
      FDiaporamaCenterAgent.DiaporamaDevice[i].GetSourceName,
      ACT_POWER_OFF);

    RefreshAction(aScheduleAction, devicePageControl, tabIndex, 'PowerOff');

    // Auto play
    aScheduleAction := GetAction(
      FDiaporamaCenterAgent.DiaporamaPlayer[i].GetSourceName, ACT_PLAY_DIAPORAMA);

    RefreshAction(aScheduleAction, devicePageControl, tabIndex, 'Play');

    if FDiaporamaCenterAgent.Repository.DiaporamaCount>0 then
    begin
      // Diaporama to be played
      aComboBox := TComboBox(GetControlByName(devicePageControl,
        GetTabSheetIndex(FDiaporamaCenterAgent.DiaporamaDevice[i]),
        'cmbDiaporamaList'));

      if Assigned(aComboBox) then
      begin
        aSpinEdit := TSpinEdit(GetControlByName(devicePageControl,
        GetTabSheetIndex(FDiaporamaCenterAgent.DiaporamaDevice[i]),
          'sePlayDuration'));

        aSpinEdit.OnChange := nil;
        FillDiaporamaCombo(aComboBox, FDiaporamaCenterAgent.Repository.Diaporamas);

        diaporamaID := aScheduleAction.Parameters.Values[cstDiaporamaIDParam];
        idx := GetDiaporamaItemIndex(aComboBox, diaporamaID);
        aComboBox.ItemIndex := idx;
        aSpinEdit.OnChange := UpdateFromGUI;
      end;

      // Diapositive duration
      diapositiveDuration :=
        aScheduleAction.Parameters.Values[cstDurationParam];
      aSpinEdit := TSpinEdit(GetControlByName(devicePageControl,
        GetTabSheetIndex(FDiaporamaCenterAgent.DiaporamaDevice[i]),
          'sePlayDuration'));
      if Assigned(aSpinEdit) then
      begin
        aSpinEdit.OnChange := nil;
        aSpinEdit.Value := StrToIntDef(diapositiveDuration,
          DIAPOSITIVE_DURATION_S);
        aSpinEdit.OnChange := UpdateFromGUI;
      end;
    end;

    // Auto stop
    aScheduleAction := GetAction(
      FDiaporamaCenterAgent.DiaporamaPlayer[i].GetSourceName,
        ACT_STOP_DIAPORAMA);

    RefreshAction(aScheduleAction, devicePageControl, tabIndex, 'Stop');
  end;

  // Diaporama
  for i := 0 to FDiaporamaCenterAgent.Repository.DiaporamaCount-1 do
  begin
    // Auto diaporama update
    aScheduleAction := GetAction(Format('Diaporama %s downloader',
      [FDiaporamaCenterAgent.Repository.Diaporama[i].ID]),
      ACT_UPDATE_DIAPORAMA);

    RefreshAction(aScheduleAction, diaporamaPageControl, i, 'Update');
  end;
end;

procedure TFrameDiaporamaScheduler.OnCheckBoxClick(Sender: TObject);
begin
  CheckBoxClickRefresh(Sender);
  UpdateFromGUI(Sender);
end;


procedure TFrameDiaporamaScheduler.CheckBoxClickRefresh(Sender: TObject);
var
  aContainer: TWinControl;
  comboBoxName, dateTimePickerName, lblName: string;
  checked: Boolean;
  name, sIndex: string;
  l, tabIndex: Integer;

  procedure enableControl(const controlName: string);
  var
    aControl: TControl;
  begin
    if aContainer is TPageControl then
      aControl := getControlByName(TPageControl(aContainer), tabIndex,
        controlName)
    else
      aControl := getControlByName(aContainer, controlName);
    if Assigned(aControl) then
      aControl.Enabled := checked;
  end;

begin
  if not Assigned(Sender) then
    Exit;

  name := TControl(Sender).Name;

  if AnsiStartsStr('cbxPowerOnAllDevices', name) then
  begin
    l := Length('cbxPowerOnAllDevices');
    comboBoxName := 'cmbPowerOnAllDevices';
    dateTimePickerName := 'tpPowerOnAllDevices';
    lblName := 'lblPowerOnAllDevices';
    aContainer := pnlDevice;
  end
  else if AnsiStartsStr('cbxPowerOffAllDevices', name) then
  begin
    l := Length('cbxPowerOffAllDevices');
    comboBoxName := 'cmbPowerOffAllDevices';
    dateTimePickerName := 'tpPowerOffAllDevices';
    lblName := 'lblPowerOffAllDevices';
    aContainer := pnlDevice;
  end
  else if AnsiStartsStr('cbxPowerOn', name) then
  begin
    l := Length('cbxPowerOn');
    comboBoxName := 'cmbPowerOn';
    dateTimePickerName := 'tpPowerOn';
    lblName := 'lblPowerOn';
    aContainer := devicePageControl;
  end
  else if AnsiStartsStr('cbxPowerOff', name) then
  begin
    l := Length('cbxPowerOff');
    comboBoxName := 'cmbPowerOff';
    dateTimePickerName := 'tpPowerOff';
    lblName := 'lblPowerOff';
    aContainer := devicePageControl;
  end
  else if AnsiStartsStr('cbxPlay', name) then
  begin
    l := Length('cbxPlay');
    comboBoxName := 'cmbPlay';
    dateTimePickerName := 'tpPlay';
    lblName := 'lblPlayAt';
    aContainer := devicePageControl;
  end
  else if AnsiStartsStr('cbxStop', name) then
  begin
    l := Length('cbxStop');
    comboBoxName := 'cmbStop';
    dateTimePickerName := 'tpStop';
    lblName := 'lblStopAt';
    aContainer := devicePageControl;
  end
  else if AnsiStartsStr('cbxUpdate', name) then
  begin
    l := Length('cbxUpdate');
    comboBoxName := 'cmbUpdate';
    dateTimePickerName := 'tpUpdate';
    lblName := 'lblUpdate';
    aContainer := diaporamaPageControl;
  end else
    Exit;

  sIndex := Copy(name, l+1, Length(name)-l);
  tabIndex := StrToIntDef(sIndex, -1);

  checked := TCheckBox(Sender).Checked;

  enableControl(comboBoxName);

  enableControl(dateTimePickerName);

  enableControl(lblName);

  if AnsiStartsStr('cbxPlay', name) then
  begin
    enableControl('lblDiaporama');

    enableControl('cmbDiaporamaList');

    enableControl('lblPlayDuration');

    enableControl('sePlayDuration');
  end;
end;

procedure TFrameDiaporamaScheduler.FillDiaporamaCombo(const aComboBox: TComboBox;
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

function TFrameDiaporamaScheduler.GetDiaporamaID(const aName: string): string;
var
  aDiaporama: TDiaporama;
begin
  Result := '';
  if aName<>'' then
  begin
    aDiaporama :=
      FDiaporamaCenterAgent.Repository.GetDiaporamaByName(aName);
    if Assigned(aDiaporama) then
      Result := aDiaporama.ID;
  end;
end;

function TFrameDiaporamaScheduler.GetDiaporamaItemIndex(const
  aComboBox: TComboBox; const anID: string): Integer;
var
  aDiaporama: TDiaporama;
begin
  Result := -1;
  if anID<>'' then
  begin
    aDiaporama := FDiaporamaCenterAgent.Repository.GetDiaporamaByID(anID);
    if Assigned(aDiaporama) then
      Result := aComboBox.Items.IndexOf(aDiaporama.Name);
  end;
end;

procedure TFrameDiaporamaScheduler.actApplyDeviceSettingsUpdate(Sender: TObject);
begin
  TAction(sender).Enabled :=
    not FEditedSchedule.Equals(FDiaporamaCenterAgent.Scheduler);
end;

procedure TFrameDiaporamaScheduler.actApplyDeviceSettingsExecute(Sender: TObject);
begin
  FDiaporamaCenterAgent.Scheduler.Assign(FEditedSchedule);
end;

procedure TFrameDiaporamaScheduler.actSaveDeviceSettingsUpdate(Sender: TObject);
begin
  TAction(sender).Enabled :=
    not FSavedSchedule.Equals(FEditedSchedule);
end;

procedure TFrameDiaporamaScheduler.actSaveDeviceSettingsExecute(Sender: TObject);
begin
  FSavedSchedule.Assign(FEditedSchedule);
  FSavedSchedule.SaveToXML(FDiaporamaCenterAgent.Settings.ScheduleFilePath);
end;


end.
