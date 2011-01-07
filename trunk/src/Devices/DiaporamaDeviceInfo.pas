unit DiaporamaDeviceInfo;

interface

uses
  Classes, MSXML2_TLB;

type
  TDPMSCapability = (capPowerOnOff, capStandby, capSuspend);
  TDPMSCapabilities = set of TDPMSCapability;

  // Interface IDiaporamaDeviceInfo
  IDiaporamaDeviceInfo = interface
    procedure Assign(const aDiaporamaDeviceInfo: IDiaporamaDeviceInfo);
    function Equals(const aDiaporamaDeviceInfo: IDiaporamaDeviceInfo): Boolean;

    function GetModel: string;
    function GetManufacturer: string;
    function GetSerial: string;
    function GetVesaID: string;
    function GetPnpID: string;

    function LoadFromXML(const parentNode: IXMLDOMNode): Boolean;
    function SaveToXML(const xmlDocument: IXMLDOMDocument;
      const parentNode: IXMLDOMNode): Boolean;

    property Model: string read GetModel;
    property Manufacturer: string read GetManufacturer;
    property Serial: string read GetSerial;
    property VesaID: string read GetVesaID;
    property PnpID: string read GetPnpID;
  end;

  // Class to retrive display device infos (manufacturer, model, serial...)
  // Informations are extracted from the EDID of device
  // (Extended Display Identification Data) stored in the Windows registry
  TDiaporamaDeviceInfo = class(TInterfacedObject, IDiaporamaDeviceInfo)
  private
    // VesaID
    FVesaID: string;
    // PnpID
    FPnpID: string;
    // Manufacturer name
    FManufacturer: string;
    // Model name
    FModel: string;
    // Serial numbe
    FSerial: string;
    // DPMS disponibles (power on / standby by VGA cable)
    FDPMSCapabilities: TDPMSCapabilities;

    function FindDeviceInfo(const vesaID, pnpID: string): Boolean; overload;
    function GetDisplayDeviceIDs(const videoDeviceName: string): TStringList;
    function FindPnpID(const vesaID, driver: string): string;

    // Checks the device is a display device
    function IsDisplayDevice(const vesaID, pnpID: string): Boolean;
    // Checks the device is active
    function IsActiveDisplayDevice(const vesaID, pnpID: string): Boolean;

    // Retrives the EDID given the device Vesa ID and Plug'nPlay ID
    function GetDisplayDeviceEDID(const vesaID, pnpID: string): ansistring;
    // Parses the EDID string
    function ParseDeviceID(const deviceID: string;
      out vesaID, driver: string): Boolean;

    // IDiaporamaDeviceInfo
    function GetModel: string;
    function GetManufacturer: string;
    function GetSerial: string;
    function GetDPMSCapabilities: TDPMSCapabilities;
    function GetVesaID: string;
    function GetPnpID: string;
  public
    constructor Create; overload;
    constructor Create(const deviceName: string); overload;

    function Matchs(const aDiaporamaDeviceInfo: IDiaporamaDeviceInfo): Integer;
    function Equals(const aDiaporamaDeviceInfo: IDiaporamaDeviceInfo): Boolean; reintroduce;
    procedure Assign(const aDiaporamaDeviceInfo: IDiaporamaDeviceInfo);
    function CheckDevice(const deviceName: string): Boolean;

    // Main function that retrives device nfo
    function FindDeviceInfo(const deviceName: string): Boolean; overload;

    function LoadFromXML(const parentNode: IXmlDomNode): Boolean;
    function SaveToXML(const xmlDocument: IXMLDomDocument;
      const parentNode: IXmlDomNode): Boolean;

    property VesaID: string read GetVesaID;
    property PnpID: string read GetPnpID;

    // IDiaporamaDeviceInfo
    property Model: string read GetModel;
    property Manufacturer: string read GetManufacturer;
    property Serial: string read GetSerial;
    property DPMSCapabilities: TDPMSCapabilities read GetDPMSCapabilities;
  end;
implementation

uses
  Registry, Windows, SysUtils, StrUtils, AnsiStrings,
  DiaporamaUtils, Logs;

const
  cstNodeDeviceInfo = 'DeviceInfo';
  cstNodeModel = 'Model';
  cstNodeManufacturer = 'Manufacturer';
  cstNodeSerial = 'Serial';
  cstNodeVesaID = 'VesaID';
  cstNodePnpID = 'PnpID';

  cstDriver = 'Driver';

  DISPLAY_DEVICE_ACTIVE = 1;

  ENUM_DISPLAY_KEY = 'SYSTEM\CurrentControlSet\Enum\DISPLAY\%s';
  HARDWARE_ID_VALUE = 'HardwareID';
  CONTROL_KEY = 'Control';
  DEVICE_PARAMETERS_KEY = 'Device Parameters';
  EDID_VALUE = 'EDID';
  EDID_SIZE = 256;

type
  // Record containing device ID
  TDisplayDeviceEx = record
    cb: DWord;
    DeviceName: array[0..31] of char;
    DeviceString: array[0..127] of char;
    StateFlags: DWord;
    DeviceID: array[0..127] of char;
    DeviceKey: array[0..127] of char;
  end;

// Windows function that returns all display device IDs
function EnumDisplayDevicesEx(Unused: Pointer; iDevNum: DWORD;
  var lpDisplayDevice: TDisplayDeviceEx; dwFlags: DWORD): BOOL; stdcall;
  external User32 name 'EnumDisplayDevicesW';

// Function to read registry MULTI_SZ value (not in Delphi framework)
procedure ReadREG_MULTI_SZ(const CurrentKey: HKey; const Subkey, ValueName: string;
  Strings: TStrings);
var
  valueType: DWORD;
  valueLen: DWORD;
  p, buffer: PChar;
  key: HKEY;
begin
  Strings.Clear;
  // open the specified key
  if RegOpenKeyEx(CurrentKey, PChar(Subkey), 0, KEY_READ, key) = ERROR_SUCCESS then
  begin
    // retrieve the type and data for a specified value name
    SetLastError(RegQueryValueEx(key, PChar(ValueName), nil, @valueType, nil,
      @valueLen));

    if GetLastError = ERROR_SUCCESS then
      if valueType = REG_MULTI_SZ then
      begin
        GetMem(buffer, valueLen);
        try
          // receive the value's data (in an array).
          RegQueryValueEx(key, PChar(ValueName), nil, nil, PBYTE(buffer),
            @valueLen);
          // Add values to stringlist
          p := buffer;
          while p^ <> #0 do
          begin
            Strings.Add(p);
            Inc(p, lstrlen(p) + 1)
          end
        finally
          FreeMem(buffer)
        end
      end
      else
        raise ERegistryException.Create(
          'EDID value type is not MULTI_SZ')
    else
      raise ERegistryException.Create(
        'Error while reading EDID value');
  end;
end;

// Function parsing the EDID string
// Returns data that contained in one of the four descriptor block
// which prefix matches the tag given in argument
function GetDescriptorBlockFromEDID(const EDID: ansistring;
  const tag: ansistring): ansistring;
var
  descriptorBlock: array[0..3] of ansistring;
  foundBlock: ansistring;
begin
  Result := '';

  //There are 4 descriptor blocks in edid at offset locations
  //36 48 5A and 6C each block is 18 bytes long
  //the model and serial numbers are stored in the vesa descriptor
  //blocks in the edid
  descriptorBlock[0] := Copy(EDID, $36+1, 18);
  descriptorBlock[1] := Copy(EDID, $48+1, 18);
  descriptorBlock[2] := Copy(EDID, $5A+1, 18);
  descriptorBlock[3] := Copy(EDID, $6C+1, 18);

  {showMessage(Format('block[0] = %s', [ByteToStr(descriptorBlock[0])]));
  showMessage(Format('block[1] = %s', [ByteToStr(descriptorBlock[1])]));
  showMessage(Format('block[2] = %s', [ByteToStr(descriptorBlock[2])]));
  showMessage(Format('block[3] = %s', [ByteToStr(descriptorBlock[3])]));}

  if Pos(tag, descriptorBlock[0])>0 then
    foundBlock := descriptorBlock[0]
  else if Pos(tag, descriptorBlock[1])>0 then
    foundBlock := descriptorBlock[1]
  else if Pos(tag, descriptorBlock[2])>0 then
    foundBlock := descriptorBlock[2]
  else if Pos(tag, descriptorBlock[3])>0 then
    foundBlock := descriptorBlock[3]
  else
    Exit;
    //raise Exception.Create(Format('tag %s non trouvé dans l''EDID', [ByteToStr(tag)]));

  Result := AnsiStrings.AnsiRightStr(foundBlock, 14);

  //the data in the descriptor block will either fill the
  //block completely or be terminated with a linefeed ($A)
  {if Pos(Result, #10)>0 then
    Result := Trim(AnsiLeftStr(Result, Pos(Result, #10)-1))
  else
    Result := Trim(Result);}
  Result := AnsiStrings.TrimRight(Result);

  //although it is not part of the edid spec it seems as though the
  //information in the descriptor will frequently be preceeded by &H00, this
  //compensates for that
  if Result[1]=#0 then
    Result := AnsiStrings.AnsiRightStr(Result, Length(Result)-1)
end;

function GetDPMSCapabilitiesFromEDID(const EDID: ansistring): TDPMSCapabilities;
var
  featureByte: Byte;
begin
  Result := [];
  featureByte := Ord(EDID[$18+1]);
  if featureByte and 128>0 then
    Result := Result + [capstandby];
  if featureByte and 64>0 then
    Result := Result + [capSuspend];
  if featureByte and 32>0 then
    Result := Result + [capPowerOnOff];
end;

function GetSerialFromEDID(const EDID: ansistring): ansistring;
begin
  // Serial number is prefixed by $000000FF
  Result := GetDescriptorBlockFromEDID(EDID, #$00#$00#$00#$FF);
end;

function GetModelFromEDID(const EDID: ansistring): ansistring;
begin
  // Model name is prefixed by $000000FC
  Result := GetDescriptorBlockFromEDID(EDID, #$00#$00#$00#$FC);
end;

// Returns Vesa ID of manufacturer (3 caracteres) by parsing the EDID
function GetManufacturerFromEDID(const EDID: ansistring): string;
var
  Char1, Char2, Char3: Byte;
  Byte1, Byte2: Byte;
  tmpEDIDMfg: ansistring;
begin
  // Maufacturer ID is contained in 2 bytes at offset $08
  // It is coded on 3 caractères. Chaque character is coded on 5 bits
  // 1=A 2=B 3=C etc..

  tmpEDIDMfg := Copy(EDID, $08+1, 2);

  Byte1 := Ord(tmpEDIDMfg[1]); // Premier octet
  Byte2 := Ord(tmpEDIDMfg[2]); // Deuxième octet

  // Character 1
  Char1 := (Byte1 and $FC) shr 2;

  // Character 2 : use 2 bits and 1 bit of first byte
  Char2 := (Byte1 and $03) shl 3;

  // And bits 7, 6, 5 of second byte
  Char2 := Char2 + (Byte2 shr 5);

  // Caractère 3 : no need to shift
  Char3 := 0;
  Char3 := Char3 + (Byte2 and 16);
  Char3 := Char3 + (Byte2 and 8);
  Char3 := Char3 + (Byte2 and 4);
  Char3 := Char3 + (Byte2 and 2);
  Char3 := Char3 + (Byte2 and 1);

  Result := chr(Char1+64) + chr(Char2+64) + chr(Char3+64);
end;

{$REGION 'TDiaporamaDeviceInfo'}

constructor TDiaporamaDeviceInfo.Create;
begin
  FVesaID := '';
  FPnpID := '';
  FModel := '';
  FManufacturer := '';
  FSerial := '';
  FDPMSCapabilities := [];
end;

constructor TDiaporamaDeviceInfo.Create(const deviceName: string);
begin
  Create;
  FindDeviceInfo(deviceName);
end;

function TDiaporamaDeviceInfo.Equals(
  const aDiaporamaDeviceInfo: IDiaporamaDeviceInfo): Boolean;
begin
  Result := SameText(FModel, aDiaporamaDeviceInfo.Model) and
    SameText(FManufacturer, aDiaporamaDeviceInfo.Manufacturer) and
    SameStr(FSerial, aDiaporamaDeviceInfo.Serial) and
    SameStr(FVesaID, aDiaporamaDeviceInfo.VesaID) and
    SameStr(FPnpID, aDiaporamaDeviceInfo.PnpID);
end;

function TDiaporamaDeviceInfo.Matchs(
  const aDiaporamaDeviceInfo: IDiaporamaDeviceInfo): Integer;
begin                                                                  ;
  Result := 0;
  if (FModel<>'') and SameText(FModel, aDiaporamaDeviceInfo.Model) then
    Inc(Result);
  if (FManufacturer<>'') and SameText(FManufacturer,
    aDiaporamaDeviceInfo.Manufacturer) then
    Inc(Result);
  if (FSerial<>'') and SameStr(FSerial, aDiaporamaDeviceInfo.Serial) then
    Inc(Result);
  if (FVesaID<>'') and SameStr(FVesaID, aDiaporamaDeviceInfo.VesaID) then
    Inc(Result);
  if (FPnpID<>'') and SameStr(FPnpID, aDiaporamaDeviceInfo.PnpID) then
    Inc(Result);
end;

procedure TDiaporamaDeviceInfo.Assign(
  const aDiaporamaDeviceInfo: IDiaporamaDeviceInfo);
begin
  if Assigned(aDiaporamaDeviceInfo) then
  begin
    FModel := aDiaporamaDeviceInfo.Model;
    FManufacturer := aDiaporamaDeviceInfo.Manufacturer;
    FSerial := aDiaporamaDeviceInfo.Serial;
    FVesaID := aDiaporamaDeviceInfo.VesaID;
    FPnpID := aDiaporamaDeviceInfo.PnpID;
  end;
end;

function TDiaporamaDeviceInfo.GetModel: string;
begin
  if FModel<>'' then
    Result := FModel
  else
    Result := 'Generic display device';
end;

function TDiaporamaDeviceInfo.GetManufacturer: string;
begin
  Result := FManufacturer;
end;

function TDiaporamaDeviceInfo.GetSerial: string;
begin
  Result := FSerial;
end;

function TDiaporamaDeviceInfo.GetDPMSCapabilities: TDPMSCapabilities;
begin
  Result := FDPMSCapabilities;
end;

function TDiaporamaDeviceInfo.GetVesaID: string;
begin
  Result := FVesaID;
end;

function TDiaporamaDeviceInfo.GetPnpID: string;
begin
  Result := FPnpID;
end;

function TDiaporamaDeviceInfo.LoadFromXML(const parentNode: IXmlDomNode): Boolean;
begin
  Result := False;
  if not Assigned(parentNode) then
    Exit;

  // Model name
  FModel := getNodeValue(parentNode, cstNodeDeviceInfo + '/' + cstNodeModel);

  // Manufacturer name
  FManufacturer := getNodeValue(parentNode, cstNodeDeviceInfo + '/' + cstNodeManufacturer);

  // Serial number
  FSerial := getNodeValue(parentNode, cstNodeDeviceInfo + '/' + cstNodeSerial);

  // VesaID
  FVesaID := getNodeValue(parentNode, cstNodeDeviceInfo + '/' + cstNodeVesaID);

  // PnpID
  FPnpID := getNodeValue(parentNode, cstNodeDeviceInfo + '/' + cstNodePnpID);

  Result := True;
end;

function TDiaporamaDeviceInfo.SaveToXML(const xmlDocument: IXMLDomDocument;
  const parentNode: IXmlDomNode): Boolean;
var
  aNode: IXMLDomNode;
begin
  Result := False;
  if not Assigned(parentNode) then
    Exit;

  aNode := xmlDocument.CreateElement(cstNodeDeviceInfo);
  parentNode.appendChild(aNode);

  // Model name
  setNodeValue(xmlDocument, aNode, cstNodeModel, FModel);

  // Manufacturer namee
  setNodeValue(xmlDocument, aNode, cstNodeManufacturer, FManufacturer);

  // Serial number
  setNodeValue(xmlDocument, aNode, cstNodeSerial, FSerial);

  // VesaID
  setNodeValue(xmlDocument, aNode, cstNodeVesaID, FVesaID);

  // PnpID
  setNodeValue(xmlDocument, aNode, cstNodePnpID, FPnpID);

  Result := True;
end;

// Retrives the EDID of deivice stored in registry key
// HKLM\SYSTEM\CurrentControlSet\Enum\DISPLAY\DeviceParameters
function TDiaporamaDeviceInfo.GetDisplayDeviceEDID(
  const vesaID, pnpID: string): ansistring;
var
  aRegistry: TRegistry;
  key: string;
  buffer: array[0..EDID_SIZE-1] of Byte;
  BufferSize: Integer;
  multiString: TStringList;
begin
  Result := '';
  aRegistry := nil;
  multiString := nil;
  try
    aRegistry := TRegistry.Create;
    aRegistry.Access := KEY_READ;
    aRegistry.RootKey := HKEY_LOCAL_MACHINE;

    // MonitorID = <VESA_ID>\<PNP_ID>
    key := Format(ENUM_DISPLAY_KEY, [vesaID + '\' + pnpID]);

    if aRegistry.OpenKey(key, False) then
    begin
      if aRegistry.OpenKey(DEVICE_PARAMETERS_KEY, False) then
      begin
        if aRegistry.ValueExists(EDID_VALUE) then
        begin
          bufferSize := aRegistry.ReadBinaryData(EDID_VALUE, buffer, EDID_SIZE);
          SetLength(Result, bufferSize);
          CopyMemory(@Result[1], @buffer[0], bufferSize);
        end;
      end;
    end;
  finally
    aRegistry.Free;
    multiString.Free;
  end;
end;

function TDiaporamaDeviceInfo.IsActiveDisplayDevice(
  const vesaID, pnpID: string): Boolean;
var
  aRegistry: TRegistry;
  key: string;
begin
  Result := False;
  aRegistry := nil;
  try
    aRegistry := TRegistry.Create;
    aRegistry.Access := KEY_READ;
    aRegistry.RootKey := HKEY_LOCAL_MACHINE;

    // MonitorID = <VESA_ID>\<PNP_ID>
    key := Format(ENUM_DISPLAY_KEY, [vesaID + '\' + pnpID]);

    if aRegistry.OpenKey(key, False) then
    begin
      // the device display is active if we find the 'Control' registry sub key
      Result := aRegistry.KeyExists(CONTROL_KEY);
    end;
  finally
    aRegistry.Free;
  end;
end;

function TDiaporamaDeviceInfo.IsDisplayDevice(
  const vesaID, pnpID: string): Boolean;
var
  aRegistry: TRegistry;
  key, hardwareID: string;
  multiString: TStringList;
begin
  Result := False;
  aRegistry := nil;
  multiString := nil;
  try
    aRegistry := TRegistry.Create;
    aRegistry.Access := KEY_READ;
    aRegistry.RootKey := HKEY_LOCAL_MACHINE;

    // MonitorID = <VESA_ID>\<PNP_ID>
    key := Format(ENUM_DISPLAY_KEY, [vesaID + '\' + pnpID]);

    if aRegistry.OpenKey(key, False) then
    begin
      // Is it a display device ? We check the sub key 'HardwareID'
      if aRegistry.ValueExists(HARDWARE_ID_VALUE) then
      begin
        multiString := TStringList.Create;
        ReadREG_MULTI_SZ(HKEY_LOCAL_MACHINE, key, HARDWARE_ID_VALUE, multiString);
        hardwareID := multiString[0];

        Result := AnsiStartsStr('Monitor\', hardwareID);
      end;
    end;
  finally
    aRegistry.Free;
    multiString.Free;
  end;
end;

// Main function to retrive device infos
function TDiaporamaDeviceInfo.FindDeviceInfo(
  const vesaID, pnpID: string): Boolean;
var
  EDID: ansistring;
begin
  Result := False;

  // Retrive EDID (Extended Display Identification Data) for device
  EDID := GetDisplayDeviceEDID(vesaID, pnpID);

  if EDID<>'' then
  begin
    // Model name
    FModel := string(GetModelFromEDID(EDID));

    // Mannufacturer name
    FManufacturer := string(GetManufacturerFromEDID(EDID));

    // Serial number
    FSerial := string(GetSerialFromEDID(EDID));

    // DPMS
    FDPMSCapabilities := GetDPMSCapabilitiesFromEDID(EDID);

    //Date := GetVersionFromEDID(EDID);

    Result := True;
  end;
end;

function TDiaporamaDeviceInfo.GetDisplayDeviceIDs(
  const videoDeviceName: string): TStringList;
var
  dd: TDisplayDeviceEx;
  idd: Integer;
begin
  Result := TStringList.Create;
  ZeroMemory(Pointer(@dd), SizeOf(TDisplaydeviceEx));
  dd.cb := SizeOf(TDisplaydeviceEx);
  idd := 0;
  while EnumDisplayDevicesEx(PChar(videoDeviceName), idd, dd, 0) do
  begin
    if dd.StateFlags and DISPLAY_DEVICE_ACTIVE>0 then
        Result.Add(dd.DeviceID);
    Inc(idd);
  end;
end;

function TDiaporamaDeviceInfo.ParseDeviceID(const deviceID: string;
  out vesaID, driver: string): Boolean;
var
  p1, p2: Integer;
begin
  Result := False;
  vesaID := '';
  driver := '';
  p1 := PosEx('\', deviceID, 2);
  if p1<>-1 then
  begin
    p2 := PosEx('\', deviceID, p1+1);
    if p2<>-1 then
    begin
      vesaID := Copy(deviceID, p1+1, p2-1-(p1+1)+1);
      driver := AnsiRightStr(deviceID, Length(deviceID)-(p2+1)+1);
      Result := True;
    end;
  end;
end;

function TDiaporamaDeviceInfo.FindPnpID(const vesaID, driver: string): string;
var
  aRegistry: TRegistry;
  key, value: string;
  names: TStringList;
  i: Integer;
begin
  Result := '';
  aRegistry := nil;
  names := nil;
  try
    aRegistry := TRegistry.Create;
    aRegistry.Access := KEY_READ;
    aRegistry.RootKey := HKEY_LOCAL_MACHINE;

    key := Format(ENUM_DISPLAY_KEY, [vesaID]);

    if aRegistry.OpenKey(key, False) then
    begin
      names := TStringList.Create;
      aRegistry.GetKeyNames(names);
      aRegistry.CloseKey;

      for i := 0 to names.Count-1 do
      begin
        if aRegistry.OpenKey(key + '\' + names[i], False) then
        begin
          value := aRegistry.ReadString(cstDriver);
          if driver=value then
          begin
            Result := names[i];
            Exit;
          end;
        end;
        aRegistry.CloseKey;
      end;
    end;
  finally
    aRegistry.Free;
    names.Free;
  end;
end;

function TDiaporamaDeviceInfo.CheckDevice(const deviceName: string): Boolean;
var
  dd: TDisplayDeviceEx;
  idd: Integer;
begin
  Result := False;
  ZeroMemory(Pointer(@dd), SizeOf(TDisplaydeviceEx));
  dd.cb := SizeOf(TDisplaydeviceEx);
  idd := 0;
  while EnumDisplayDevicesEx(nil, idd, dd, 0) do
  begin
    if SameStr(dd.DeviceName, deviceName) then
    begin
      Result := (dd.StateFlags and DISPLAY_DEVICE_MIRRORING_DRIVER=0) and
        (dd.StateFlags and DISPLAY_DEVICE_ATTACHED_TO_DESKTOP>0);
      LogEvent(Self.ClassName, ltInformation,
        Format('Device flags ''%s'' : %d', [deviceName, dd.StateFlags]));
      Exit;
    end;
    Inc(idd);
  end;
end;

function TDiaporamaDeviceInfo.FindDeviceInfo(const deviceName: string): Boolean;
var
  deviceIDs: TStringList;
  aVesaID, aDriver, aPnpID: string;
  i: Integer;
begin
  Result := False;

  FVesaID := '';
  FPnpID := '';

  if deviceName<>'' then
  begin
    deviceIDs := nil;
    try
      deviceIDs := GetDisplayDeviceIDs(deviceName);

      for i := 0 to deviceIDs.Count-1 do
      begin
        if ParseDeviceID(deviceIDs[i], aVesaID, aDriver) then
        begin
          aPnpID := FindPnpID(aVesaID, aDriver);

          if IsDisplayDevice(aVesaID, aPnpID) then
          begin
            if IsActiveDisplayDevice(aVesaID, aPnpID) then
            begin
              FVesaID := aVesaID;
              FPnpID := aPnpID;
              Break;
            end;
          end;
        end;
      end;
    finally
      deviceIDs.Free;
    end;

    if (FVesaID<>'') and (FPnpID<>'') then
      Result := FindDeviceInfo(FVesaID, FPnpID);
  end;
end;

{$ENDREGION}


end.
