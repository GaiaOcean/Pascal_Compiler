program Fibonacci;
begin
    n := ParamStr(1);
    anterior := 0;
    atual := 1;
    i := 1;

    while i < n do
    begin
        proximo := anterior + atual;
        anterior := atual;
        atual := proximo;
        i := i + 1;
    end;

    writeln(atual);
end.