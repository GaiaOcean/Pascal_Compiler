program PiDigits;
begin
    n := ParamStr(1);
    num := 355;
    den := 113;
    cont := 0;
    
    digito := 0;
    aux := 0;

    while cont < n do
    begin
        digito := num / den;
        writeln(digito);

        aux := digito * den;
        num := num - aux;
        num := num * 10;

        cont := cont + 1;
    end;
end.
