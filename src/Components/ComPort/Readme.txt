

If you are migrating to later version the Comport OnRxBuf event has been revised


from
  TRxBufEvent = procedure(Sender: TObject; const Buffer; Count: Integer) of object;
TO:
  TRxBufEvent = procedure(Sender: TObject; const Buffer : PCharBuf; var Count: Integer) of object;


you may get an error like 

--------------------------------------
ComPort1RxBuf method referenced by 
Comport1.OnRxBuf has incompatable 
parameter list. Remove Reference ?

    YES  NO  Cancel  HELP
------------------------------------

You can fix up RxBuf event by;

adding ;  " : PCharBuf; " to the parameter  "const Buffer"

or 'fixup' to   const Buffer : PCharBuf;

PCharBuf is defined as type


   PCharBuf = Array of Char;


e.g.


procedure  Form1.ComPort1RxBuf(Sender: TObject; const Buffer : PCharBuf; var Count: Integer);
var
   s: String;
begin

  SetString(s,pchar(buffer),count);

  Memo.Lines.Add(s);

end;
