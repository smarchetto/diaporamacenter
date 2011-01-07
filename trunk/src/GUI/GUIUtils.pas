unit GUIUtils;

interface

uses
  StdCtrls, Spin, ComCtrls, ActnList, Classes, Controls;

function CreateLabel(const aContainer: TWinControl;
  const name, caption: string;
  const left, top: Integer;
  const header: Boolean = False): TLabel;

function CreateEdit(const aContainer: TWinControl;
  const name, text: string;
  const left, top, width: Integer): TEdit;

function CreateCheckBox(const aContainer: TWinControl;
  const name, caption: string;
  const left, top: Integer): TCheckBox;

function CreateSpinEdit(const aContainer: TWinControl;
  const name: string;
  const left, top, width, value, minvalue, maxvalue: Integer): TSpinEdit;

function CreateComboBox(const aContainer: TWinControl;
  const name: string;
  const left, top, width: Integer): TComboBox;

function CreateTimePicker(const aContainer: TWinControl;
  const name: string;
  const left, top: Integer): TDateTimePicker;

function CreateButton(const aContainer: TWinControl;
  const name, caption: string;
  const left, top, width: Integer;
  const anAction: TAction): TButton;

function CreateAction(const aContainer: TWinControl;
  const name, caption: string;
  const actExecute, actUpdate: TNotifyEvent;
  const anActionList: TActionList): TAction;

implementation

uses
  Graphics, Types, SysUtils;

function CreateLabel(const aContainer: TWinControl;
  const name, caption: string;
  const left, top: Integer;
  const header: Boolean = False): TLabel;
begin
  Result := TLabel.Create(aContainer);
  Result.Parent := aContainer;
  Result.Name := name;
  if aContainer is TTabSheet then
    Result.Name := Result.Name + IntToStr(TTabSheet(aContainer).TabIndex);
  Result.AutoSize := True;
  Result.Caption := caption;
  Result.BoundsRect := Rect(left, top, left+150, top+13);
  if header then
    Result.Font.Style := [fsBold];
end;

function CreateEdit(const aContainer: TWinControl;
  const name, text: string;
  const left, top, width: Integer): TEdit;
begin
  Result := TEdit.Create(aContainer);
  Result.Parent := aContainer;
  Result.Name := name;
  if aContainer is TTabSheet then
    Result.Name := Result.Name + IntToStr(TTabSheet(aContainer).TabIndex);
  Result.BoundsRect := Rect(left, top, left+width, top+21);
  Result.Text := text;
end;

function CreateCheckBox(const aContainer: TWinControl;
  const name, caption: string;
  const left, top: Integer): TCheckBox;
begin
  Result := TCheckBox.Create(aContainer);
  Result.Parent := aContainer;
  Result.Name := name;
  if aContainer is TTabSheet then
    Result.Name := Result.Name + IntToStr(TTabSheet(aContainer).TabIndex);
  Result.Caption := caption;
  Result.BoundsRect := Rect(left, top, left+150, top+13);
end;

function CreateSpinEdit(const aContainer: TWinControl;
  const name: string;
  const left, top, width, value, minvalue, maxvalue: Integer): TSpinEdit;
begin
  Result := TSpinEdit.Create(aContainer);
  Result.Parent := aContainer;
  Result.Name := name;
  if aContainer is TTabSheet then
    Result.Name := Result.Name + IntToStr(TTabSheet(aContainer).TabIndex);
  Result.Left := left;
  Result.Top := top;
  Result.Width := width;
  Result.Height := 23;
  Result.MaxValue := 0;
  Result.MinValue := 0;
  Result.Value := value;
end;

function CreateComboBox(const aContainer: TWinControl;
  const name: string;
  const left, top, width: Integer): TComboBox;
begin
  Result := TComboBox.Create(aContainer);
  Result.Parent := aContainer;
  Result.Name := name;
  if aContainer is TTabSheet then
    Result.Name := Result.Name + IntToStr(TTabSheet(aContainer).TabIndex);
  Result.Style := csDropDownList;
  Result.Left := left;
  Result.Top := top;
  Result.Width := width;
  Result.Height := 21;
  Result.ItemHeight := 0;
  //Result.Text := '';
end;

function CreateTimePicker(const aContainer: TWinControl;
  const name: string;
  const left, top: Integer): TDateTimePicker;
begin
  Result := TDateTimePicker.Create(aContainer);
  Result.Parent := aContainer;
  Result.Name := name;
  if aContainer is TTabSheet then
    Result.Name := Result.Name + IntToStr(TTabSheet(aContainer).TabIndex);
  Result.Left := left;
  Result.Top := top;
  Result.Width := 60;
  Result.Height := 21;
  Result.Kind := dtkTime;
  Result.DateMode := dmUpDown;
  Result.Format := 'HH:mm';
end;

function CreateButton(const aContainer: TWinControl;
  const name, caption: string;
  const left, top, width: Integer;
  const anAction: TAction): TButton;
begin
  Result := TButton.Create(aContainer);
  Result.Parent := aContainer;
  Result.Caption:= caption;
  Result.Name := name;
  if aContainer is TTabSheet then
    Result.Name := Result.Name + IntToStr(TTabSheet(aContainer).TabIndex);
  Result.BoundsRect := Rect(left, top, left+width, top+25);
  Result.Action := anAction;
end;

function CreateAction(const aContainer: TWinControl;
  const name, caption: string;
  const actExecute, actUpdate: TNotifyEvent;
  const anActionList: TActionList): TAction;
begin
  Result := TAction.Create(aContainer);
  Result.Name := name;
  if aContainer is TTabSheet then
    Result.Name := Result.Name + IntToStr(TTabSheet(aContainer).TabIndex);
  Result.Caption := caption;
  Result.Category := '';
  Result.OnExecute := actExecute;
  Result.OnUpdate := actUpdate;
  Result.ActionList := anActionList;
end;


end.
