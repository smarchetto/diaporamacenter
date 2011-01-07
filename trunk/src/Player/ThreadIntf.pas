unit ThreadIntf;

interface

uses
  Classes;

type
  IThread = interface
    ['{E887C9B2-E8A1-4D0D-90CF-B65C8FFC3B4A}']

    procedure Execute;
    procedure OnTerminateExecute;
  end;

  TThreadLink = class(TThread)
    private
      FThreadIntf: IThread;
      FFinished: Boolean;
    public
      constructor Create(const aThreadIntf: IThread);
      procedure OnTerminateExecute(Sender: TObject);
      procedure Execute; override;
      procedure DoSynchronize(AMethod: TThreadMethod);
      //procedure Terminate; 
      procedure WaitTerminate(const timeOut: Cardinal);
      property Suspended;
      property Terminated;
      property Finished: Boolean read FFinished;
   end;

implementation

uses
  Windows, Forms;

procedure TThreadLink.WaitTerminate(const timeOut: Cardinal);
var
  iStop : cardinal;
begin
  iStop := GetTickCount + timeOut;
  while (GetTickCount < iStop) and not FFinished do
  begin
    Application.HandleMessage;
    sleep(1);
  end
end;

constructor TThreadLink.Create(const aThreadIntf: IThread);
begin
 inherited Create(True);

 FThreadIntf := aThreadIntf;
                                      
 FreeOnTerminate := False;

 FFinished := False;

 OnTerminate := OnTerminateExecute;
end;

{procedure TThreadLink.Terminate;
begin
  Terminate;
end;}

procedure TThreadLink.Execute;
begin
  FFinished := False;
  FThreadIntf.Execute;
end;

procedure TThreadLink.DoSynchronize(AMethod: TThreadMethod);
begin
  Synchronize(AMethod);
end;

procedure TThreadLink.OnTerminateExecute(Sender: TObject);
begin
  FThreadIntf.OnTerminateExecute;
  FFinished := True;
end;


end.
