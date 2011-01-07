program evlog;

uses
  Forms,
  afpevlog in 'afpevlog.pas' {EventLogDemo};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TEventLogDemo, EventLogDemo);
  Application.Run;
end.
