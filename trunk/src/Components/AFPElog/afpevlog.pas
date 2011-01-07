unit afpevlog;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, afpEventLog, ExtCtrls, Spin;

type
  TEventLogDemo = class(TForm)
    CreateLogEntryButton: TButton;
    cb1: TCheckBox;
    afpEventLog1: TafpEventLog;
    LogMsgEdit: TEdit;
    CloseButton: TButton;
    Label1: TLabel;
    AppnameEdit: TEdit;
    Label2: TLabel;
    rg1: TRadioGroup;
    cb2: TCheckBox;
    se1: TSpinEdit;
    se2: TSpinEdit;
    Label3: TLabel;
    Label4: TLabel;
    procedure CreateLogEntryButtonClick(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EventLogDemo: TEventLogDemo;

implementation

{$R *.DFM}

procedure TEventLogDemo.CreateLogEntryButtonClick(Sender: TObject);

begin
	case rg1.ItemIndex of
  	0:	afpEventLog1.EventType := etError;
		1:	afpEventLog1.EventType := etWarning;
		2:	afpEventLog1.EventType := etInformation;
  	3:	afpEventLog1.EventType := etAuditSuccess;
		4:	afpEventLog1.EventType := etAuditFailure;
  end;
  afpEventLog1.IncludeUserName :=cb1.Checked;
  afpEventLog1.RegisterApplication :=cb2.Checked;
	afpEventLog1.EventCategory := se1.Value;
  afpEventLog1.EventID := se2.Value;
  afpEventLog1.ApplicationName := AppnameEdit.Text;
  afpEventLog1.LogEvent(LogMsgEdit.Text+#13#10'Contact support!');
end;

procedure TEventLogDemo.CloseButtonClick(Sender: TObject);
begin
	Close;
end;

end.
