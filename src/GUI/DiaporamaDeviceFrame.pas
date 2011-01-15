unit DiaporamaDeviceFrame;

interface

uses
  Classes, Controls, Forms, ComCtrls, StdCtrls, Contnrs, ActnList,
  DiaporamaDevice, DisplayMode, DiaporamaCenterAgent, DiaporamaDeviceSettings,
  ExtCtrls;

type
  TFrameDiaporamaDevice = class(TFrame)
    PageControl: TPageControl;
    ActionList: TActionList;
    btnApplySettings: TButton;
    actSaveDeviceSettings: TAction;
    actApplyDeviceSettings: TAction;
    btnSaveSettings: TButton;
    pnlButton: TPanel;

    procedure actApplyDeviceSettingsExecute(Sender: TObject);
    procedure actApplyDeviceSettingsUpdate(Sender: TObject);
    procedure actSaveDeviceSettingsExecute(Sender: TObject);
    procedure actSaveDeviceSettingsUpdate(Sender: TObject);

    procedure btnComSettingsClick(Sender: TObject);
    procedure btnCommandSettingsClick(Sender: TObject);

    procedure btnPowerClick(Sender: TObject);

    procedure UpdateFromGUI(Sender: TObject);
    procedure RefreshPowerStatus(Sender: TObject);
  private
    FDiaporamaCenterAgent: TDiaporamaCenterAgent;
    FSavedSettings: TObjectList;
    FEditedSettings: TObjectList;

    function GetDiaporamaDevice: TDiaporamaDevice;
    function GetTabSheetIndex(const diaporamaDevice: TDiaporamaDevice): Integer;

    function GetDisplayMode(const aComboBox: TComboBox): TDisplayMode;
    function GetEditedSettings: TDiaporamaDeviceSettings;
    function GetSavedSettings: TDiaporamaDeviceSettings;
    function CopyDeviceSettings: TObjectList;

    procedure CreateDeviceTabSheet(
      const diaporamaDevice: TDiaporamaDevice);

    procedure FillComboDisplayMode(const diaporamaDevice: TDiaporamaDevice;
      const comboBox: TComboBox);
    procedure DisplayDeviceInfos(const diaporamaDevice: TDiaporamaDevice);
    //procedure RefreshAutoPowerGUI(Sender: TObject);

  public
    constructor Create(aOwner: TComponent;
      const diaporamaCenter: TDiaporamaCenterAgent); reintroduce;
    destructor Destroy; override;

    procedure BuildGUI;
    procedure RefreshGUI;
  end;

implementation

{$R *.dfm}

uses
  SysUtils, Graphics, Spin, Generics.Defaults, Generics.Collections,
  DiaporamaUtils, ComSettingForm, ControlCommandSettingForm, GUIUtils,
  DeviceControl, ScheduleAction;


const
  LEFT1 = 4;
  LEFT2 = 12;
  LEFT3 = 120;
  LEFT4 = 210;
  LEFT5 = 380;
  LEFT6 = 400;
  DELTA_TOP1 = 26; //28
  DELTA_TOP2 = 30; //32
  DELTA_TOP3 = 38; //40

constructor TFrameDiaporamaDevice.Create(aOwner: TComponent;
  const diaporamaCenter: TDiaporamaCenterAgent);
begin
  inherited Create(aOwner);
  FDiaporamaCenterAgent := diaporamaCenter;

  BuildGUI;
  FSavedSettings := CopyDeviceSettings;

  FEditedSettings := nil;
  RefreshGUI;
  FEditedSettings := CopyDeviceSettings;
end;

destructor TFrameDiaporamaDevice.Destroy;
begin
  FEditedSettings.Free;
  FSavedSettings.Free;
  inherited;
end;


function TFrameDiaporamaDevice.CopyDeviceSettings: TObjectList;
var
  i: Integer;
begin
  Result := TObjectList.Create;
  for i := 0 to FDiaporamaCenterAgent.DiaporamaDeviceCount-1 do
    Result.Add(FDiaporamaCenterAgent.DiaporamaDevice[i].Settings.Copy);
end;

procedure TFrameDiaporamaDevice.BuildGUI;
var
  i: Integer;
begin
  for i := 0 to FDiaporamaCenterAgent.DiaporamaDeviceCount-1 do
  begin
    CreateDeviceTabSheet(FDiaporamaCenterAgent.DiaporamaDevice[i]);
  end;
end;

procedure TFrameDiaporamaDevice.FillComboDisplayMode(
  const diaporamaDevice: TDiaporamaDevice;
  const comboBox: TComboBox);
var
  displayModes: TObjectList<TDisplayMode>;
  displayMode: TDisplayMode;
  i: Integer;
begin
  if not Assigned(comboBox) then
    Exit;

  displayModes := diaporamaDevice.GetAvailableDisplayModes;

  comboBox.Clear;
  if Assigned(displayModes) then
  begin
    for displayMode in displayModes do
    begin
      comboBox.Items.AddObject(displayMode.ToString, displayMode);
    end;

    if diaporamaDevice.ValidMode(diaporamaDevice.Settings.DisplayMode) then
      displayMode := diaporamaDevice.Settings.DisplayMode
    else
      displayMode := diaporamaDevice.DisplayMode;

    for i := 0 to comboBox.Items.Count - 1 do
    begin
      if TDisplayMode(comboBox.Items.Objects[i]).Equals(displayMode) then
      begin
        comboBox.ItemIndex := i;
        Break;
      end;
    end;
  end;
end;

function TFrameDiaporamaDevice.GetDisplayMode(const aComboBox: TComboBox): TDisplayMode;
begin
  if aComboBox.ItemIndex<>-1 then
    Result := TDisplayMode(aComboBox.Items.Objects[aComboBox.ItemIndex])
  else
    Result := nil;
end;

function TFrameDiaporamaDevice.GetDiaporamaDevice: TDiaporamaDevice;
begin
  if Assigned(FEditedSettings) and
    (PageControl.TabIndex>=0) and (PageControl.TabIndex<FEditedSettings.Count)
  then
    Result := FDiaporamaCenterAgent.DiaporamaDevice[PageControl.TabIndex]
  else
    Result := nil;
end;

function TFrameDiaporamaDevice.GetTabSheetIndex(
  const diaporamaDevice: TDiaporamaDevice): Integer;
begin
  if Assigned(diaporamaDevice) then
    Result := diaporamaDevice.DeviceIndex-1
  else
    Result := -1;
end;

function TFrameDiaporamaDevice.GetEditedSettings: TDiaporamaDeviceSettings;
begin
  if Assigned(FEditedSettings) and
    (PageControl.TabIndex>=0) and (PageControl.TabIndex<FEditedSettings.Count)
  then
    Result := TDiaporamaDeviceSettings(
      FEditedSettings[PageControl.TabIndex])
  else
    Result := nil;
end;

function TFrameDiaporamaDevice.GetSavedSettings: TDiaporamaDeviceSettings;
begin
  if Assigned(FEditedSettings) and
    (PageControl.TabIndex>=0) and (PageControl.TabIndex<FEditedSettings.Count)
  then
    Result := TDiaporamaDeviceSettings(
      FSavedSettings[PageControl.TabIndex])
  else
    Result := nil;
end;

procedure TFrameDiaporamaDevice.CreateDeviceTabSheet(
  const diaporamaDevice: TDiaporamaDevice);
var
  tabSheet: TTabSheet;
  aEdit: TEdit;
  aComboBox: TComboBox;
  aButton: TButton;
  aCheckBox: TCheckBox;
  y: Integer;
begin
  if not Assigned(diaporamaDevice) then
    Exit;

  tabSheet := TTabSheet.Create(pageControl);
  tabSheet.PageControl := pageControl;
  tabSheet.Caption := diaporamaDevice.Title;

  y := 8;

  // Device properties
  CreateLabel(tabsheet, 'lblProperties', 'Properties', LEFT1,
    y, True);

  Inc(y, DELTA_TOP1);
  CreateLabel(tabsheet, 'lblDeviceNameHeader', 'Name:', LEFT2, y);

  aEdit := CreateEdit(tabsheet, 'edDeviceName', '<Name>', LEFT3, y-3, 170);
  aEdit.TabOrder := 0;
  aEdit.OnChange := UpdateFromGUI;

  Inc(y, DELTA_TOP1);
  CreateLabel(tabsheet, 'lblDeviceModelHeader', 'Model name:', LEFT2, y);
  CreateLabel(tabsheet, 'lblDeviceModel', '<ModelName>', LEFT3, y);

  Inc(y, DELTA_TOP1);
  CreateLabel(tabsheet, 'lblDeviceManufacturerHeader', 'Manufacturer:', LEFT2, y);
  CreateLabel(tabsheet, 'lblDeviceManufacturer', '<Manufacturer>', LEFT3, y);

  Inc(y, DELTA_TOP1);
  CreateLabel(tabsheet, 'lblDeviceSerialHeader', 'Serial number:', LEFT2, y);
  CreateLabel(tabsheet, 'lblDeviceSerial', '<SerialNumber>', LEFT3, y);

  Inc(y, DELTA_TOP1);
  CreateLabel(tabsheet, 'lblDeviceDisplayMode', 'Display mode:', LEFT2, y);

  aComboBox := CreateComboBox(tabsheet, 'cmbDeviceDisplayMode', LEFT3, y-3, 170);
  aComboBox.TabOrder := 1;
  aComboBox.OnChange := UpdateFromGUI;

  Inc(y, DELTA_TOP1);
  aCheckBox := CreateCheckBox(tabsheet, 'cbDeviceFullScreen', 'Full screen:', LEFT2, y);
  aCheckBox.TabOrder := 2;
  aCheckBox.OnClick := UpdateFromGUI;

  // Power commands
  Inc(y, DELTA_TOP2);
  CreateLabel(tabsheet, 'lblPower', 'Power off/on', LEFT1, y, True);

  Inc(y, DELTA_TOP1);

  CreateLabel(tabsheet, 'lblPowerStatus', 'Status: ?', LEFT2, y, False);

  Inc(y, DELTA_TOP2);
  aButton := CreateButton(tabsheet, 'btnPower', 'Power on/off', LEFT2, y-5,
    88, nil);
  aButton.OnClick := btnPowerClick;
  aButton.TabOrder := 3;

  // Device control
  Inc(y, DELTA_TOP2);
  CreateLabel(tabsheet, 'lblDeviceControl', 'Device control', LEFT1, y, True);

  Inc(y, DELTA_TOP2);
  aButton := CreateButton(tabsheet, 'btnComSettings', 'RS232 port...', LEFT2, y, 100, nil);
  aButton.OnClick := btnComSettingsClick;
  aButton.TabOrder := 4;

  aButton := CreateButton(tabsheet, 'btnCommandSettings', 'Control commands...',
    LEFT2+120, y, 160, nil);
  aButton.OnClick := btnCommandSettingsClick;
  aButton.TabOrder := 5;

  // Configuration file
  Inc(y, DELTA_TOP3);
  CreateLabel(tabsheet, 'lblSettingFile', 'Configuration file', LEFT1,
    y, True);

  Inc(y, DELTA_TOP2);
  CreateLabel(tabsheet, 'lblSettingFileName', 'File name:', LEFT2, y);

  aEdit := CreateEdit(tabsheet, 'edDeviceSettingFileName', '<Name>', LEFT3, y-3, 180);
  aEdit.TabOrder := 6;
  aEdit.OnChange := UpdateFromGUI;
end;

procedure TFrameDiaporamaDevice.RefreshGUI;
var
  i: Integer;
begin
  for i := 0 to FDiaporamaCenterAgent.DiaporamaDeviceCount-1 do
  begin
    DisplayDeviceInfos(FDiaporamaCenterAgent.DiaporamaDevice[i]);

    FDiaporamaCenterAgent.DiaporamaDevice[i].OnPowerChange := RefreshPowerStatus;
  end;
end;

procedure TFrameDiaporamaDevice.DisplayDeviceInfos(
  const diaporamaDevice: TDiaporamaDevice);
var
  tabIndex: Integer;
  aLabel: TLabel;
  aEdit: TEdit;
  aComboBox: TComboBox;
  aCheckBox: TCheckBox;
begin
  tabIndex := GetTabSheetIndex(diaporamaDevice);

  aEdit := TEdit(getControlByName(PageControl, tabIndex, 'edDeviceName'));
  if Assigned(aEdit) then
    aEdit.Text := diaporamaDevice.Name;

  aLabel := TLabel(getControlByName(PageControl, tabIndex, 'lblDeviceModel'));
  if Assigned(aLabel) then
    aLabel.Caption := diaporamaDevice.DeviceInfo.Model;

  aLabel := TLabel(getControlByName(PageControl, tabIndex,
    'lblDeviceManufacturer'));
  if Assigned(aLabel) then
    aLabel.Caption := diaporamaDevice.DeviceInfo.Manufacturer;

  aLabel := TLabel(getControlByName(PageControl, tabIndex, 'lblDeviceSerial'));
  if Assigned(aLabel) then
    aLabel.Caption := diaporamaDevice.DeviceInfo.Serial;

  aComboBox := TComboBox(getControlByName(PageControl, tabIndex,
    'cmbDeviceDisplayMode'));
  FillComboDisplayMode(diaporamaDevice, aComboBox);

  aCheckBox := TCheckBox(getControlByName(PageControl, tabIndex,
    'cbDeviceFullScreen'));
  if Assigned(aCheckBox) then
    aCheckBox.Checked := diaporamaDevice.Settings.FullScreen;

  aEdit := TEdit(getControlByName(PageControl, tabIndex,
    'edDeviceSettingFileName'));
  if Assigned(aEdit) then
    aEdit.Text := diaporamaDevice.GetSettingFileName;

  // Power status
  RefreshPowerStatus(diaporamaDevice);
end;

procedure TFrameDiaporamaDevice.btnComSettingsClick(Sender: TObject);
var
  editedSettings: TDiaporamaDeviceSettings;
begin
  editedSettings := GetEditedSettings;
  if Assigned(editedSettings) then
    EditComSettings(editedSettings.ControlSettings.ComSettings);
end;

procedure TFrameDiaporamaDevice.btnCommandSettingsClick(Sender: TObject);
var
  editedSettings: TDiaporamaDeviceSettings;
begin
  editedSettings := GetEditedSettings;
  if Assigned(editedSettings) then
    EditControlCommands(editedSettings.ControlSettings);
end;

procedure TFrameDiaporamaDevice.actApplyDeviceSettingsUpdate(Sender: TObject);
var
  diaporamaDevice: TDiaporamaDevice;
  editedSettings: TDiaporamaDeviceSettings;
begin
  diaporamaDevice := GetDiaporamaDevice;
  editedSettings := GetEditedSettings;
  if Assigned(diaporamaDevice) and Assigned(editedSettings) then
    TAction(sender).Enabled :=
      not editedSettings.Equals(diaporamaDevice.Settings)
  else
    TAction(sender).Enabled := False;
end;

procedure TFrameDiaporamaDevice.actApplyDeviceSettingsExecute(Sender: TObject);
var
  diaporamaDevice: TDiaporamaDevice;
  editedSettings: TDiaporamaDeviceSettings;
begin
  diaporamaDevice := GetDiaporamaDevice;
  editedSettings := GetEditedSettings;
  if Assigned(diaporamaDevice) and Assigned(editedSettings) then
  begin
    diaporamaDevice.Settings.Assign(editedSettings);
  end;
end;

procedure TFrameDiaporamaDevice.actSaveDeviceSettingsUpdate(Sender: TObject);
var
  savedSettings, editedSettings: TDiaporamaDeviceSettings;
begin
  editedSettings := GetEditedSettings;
  savedSettings := getSavedSettings;
  if Assigned(savedSettings) and Assigned(editedSettings) then
    TAction(sender).Enabled :=
      not savedSettings.Equals(editedSettings)
  else
    TAction(sender).Enabled := False;
end;

procedure TFrameDiaporamaDevice.actSaveDeviceSettingsExecute(Sender: TObject);
var
  savedSettings, editedSettings: TDiaporamaDeviceSettings;
begin
  editedSettings := getEditedSettings;
  savedSettings := getSavedSettings;

  if Assigned(savedSettings) and Assigned(editedSettings) then
  begin
    savedSettings.Assign(editedSettings);
    savedSettings.SaveToXML(FDiaporamaCenterAgent.Settings.DevicePath +
      editedSettings.FileName);
  end;
end;

procedure TFrameDiaporamaDevice.UpdateFromGUI(Sender: TObject);
var
  editedSettings: TDiaporamaDeviceSettings;
  edDeviceName, edDeviceFileName: TEdit;
  aComboBox: TComboBox;
  displayMode: TDisplayMode;
  aCheckBox: TCheckBox;
begin
  editedSettings := GetEditedSettings;
  if not Assigned(editedSettings) then
    Exit;

  edDeviceName := TEdit(getControlByName(PageControl, PageControl.TabIndex,
    'edDeviceName'));
  if Assigned(edDeviceName) then
    editedSettings.Name := edDeviceName.Text;

  edDeviceFileName := TEdit(getControlByName(PageControl, PageControl.TabIndex,
    'edDeviceSettingFileName'));
  if Assigned(edDeviceFileName) then
    editedSettings.FileName := edDeviceFileName.Text;

  aComboBox := TComboBox(getControlByName(PageControl, PageControl.TabIndex,
    'cmbDeviceDisplayMode'));

  if Assigned(aComboBox) then
  begin
    displayMode := GetDisplayMode(aComboBox);
    editedSettings.DisplayMode.Assign(displayMode);
  end;

  aCheckBox := TCheckBox(getControlByName(PageControl, PageControl.TabIndex,
    'cbDeviceFullScreen'));
  if Assigned(aCheckBox) then
    editedSettings.FullScreen := aCheckBox.Checked;
end;

(*procedure TFrameDiaporamaDevice.RefreshAutoPowerGUI(Sender: TObject);
var
  aControl: TControl;
  checked: Boolean;
  name, sIndex: string;
  l, tabIndex: Integer;
begin
  if not Assigned(Sender) then
    Exit;

  name := TControl(Sender).Name;
  l := Length('cbAutoPower');
  sIndex := Copy(name, l+1, Length(name)-l);
  tabIndex := StrToIntDef(sIndex, -1);

  checked := TCheckBox(Sender).Checked;

  aControl := getControlByName(PageControl, tabIndex, 'lblPowerOnTime');
  if Assigned(aControl) then
    aControl.Enabled := checked;

  aControl := getControlByName(PageControl, tabIndex, 'tpPowerOn');
  if Assigned(aControl) then
    aControl.Enabled := checked;

  aControl := getControlByName(PageControl, tabIndex, 'lblPowerOffTime');
  if Assigned(aControl) then
    aControl.Enabled := checked;

  aControl := getControlByName(PageControl, tabIndex, 'tpPowerOff');
  if Assigned(aControl) then
    aControl.Enabled := checked;
end;*)

procedure TFrameDiaporamaDevice.RefreshPowerStatus(Sender: TObject);
var
  aLabel: TLabel;
  aButton: TButton;
  diaporamaDevice: TDiaporamaDevice;
  tabIndex: Integer;
begin
  diaporamaDevice := TDiaporamaDevice(Sender);

  if not Assigned(diaporamaDevice) then
    Exit;

  tabIndex := GetTabSheetIndex(diaporamaDevice);

  aLabel := TLabel(getControlByName(PageControl, tabIndex, 'lblPowerStatus'));
  aButton := TButton(getControlByName(PageControl, tabIndex, 'btnPower'));

  case diaporamaDevice.GetPowerStatus of
    psOn :
    begin
      if Assigned(aLabel) then
        aLabel.Caption := 'Status: On';
      if Assigned(aButton) then
        aButton.Caption := 'Power off';
    end;
    psOff :
    begin
      if Assigned(aLabel) then
        aLabel.Caption := 'Status: Off';
      if Assigned(aButton) then
        aButton.Caption := 'Power on';
    end;
    psUnknown :
    begin
      if Assigned(aLabel) then
        aLabel.Caption := 'Status: ?';
      if Assigned(aButton) then
      begin
        if aButton.Caption = 'Power on' then
          aButton.Caption := 'Power off'
        else
          aButton.Caption := 'Power on';
      end;
    end;
  end;
end;

procedure TFrameDiaporamaDevice.btnPowerClick(Sender: TObject);
var
  diaporamaDevice: TDiaporamaDevice;
begin
  diaporamaDevice := GetDiaporamaDevice;

  if Assigned(diaporamaDevice) then
  begin
    case diaporamaDevice.GetPowerStatus of
      psOn: diaporamaDevice.PowerOff;
      psOff: diaporamaDevice.PowerOn;
      psUnknown:
        if TButton(Sender).Caption='Power off' then
          diaporamaDevice.PowerOff
        else
          diaporamaDevice.PowerOn;
    end;
  end;
end;


end.
