program IsPrime;
begin
    num := ParamStr(1);
    primo := 1;
    
    if num < 2 then
    begin
        primo := 0;
    end;

    div := 2;
    while div * div < num + 1 do
    begin
        if (num / div) * div = num then
        begin
            primo := 0;
        end;
        div := div + 1;
    end;

    writeln(primo);
end.