program Factor;
begin
    num := ParamStr(1);
    div := 2;

    while 1 < num do
    begin
        while (num / div) * div = num do
        begin
            writeln(div);
            num := num / div;
        end;
        div := div + 1;
    end;
end.