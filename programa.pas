program TesteCompleto;
begin
    limite := ParamStr(1);
    i := 1;
    soma := 0;

    while i < limite do
    begin
        if i = 3 then
        begin
            soma := soma + 100;
        end
        else
        begin
            soma := soma + i;
        end;
        
        i := i + 1;
    end;

    writeln(soma);
end.