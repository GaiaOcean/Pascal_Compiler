program PiDigits;
begin
    n := ParamStr(1);
    
    i := 1;
    pi := 0;
    sinal := 1;
    
    while i < n + 1 do
    begin
        term := 40000 / (2 * i - 1);
        if sinal = 1 then
        begin
            pi := pi + term;
            sinal := 0;
        end
        else
        begin
            pi := pi - term;
            sinal := 1;
        end;
        i := i + 1;
    end;
    
    writeln(pi);
end.