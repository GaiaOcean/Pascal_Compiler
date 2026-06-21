all: compiler

compiler: parser.tab.c lex.yy.c
	clang++ parser.tab.c lex.yy.c $(shell llvm-config --cxxflags --ldflags --system-libs --libs core) -o compiler

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

lex.yy.c: lexer.l parser.tab.h
	flex lexer.l

clean:
	rm -f compiler parser.tab.c parser.tab.h lex.yy.c
