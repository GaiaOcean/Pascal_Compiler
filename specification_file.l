%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "parser.tab.h"

int line_number = 1;
%}

DIGIT       [0-9]
LETTER      [a-zA-Z]
ID          {LETTER}({LETTER}|{DIGIT}|_)*
INTEGER     {DIGIT}+

%%

"program"       { return PROGRAM; }
"begin"         { return BEGIN_KW; }
"end"           { return END_KW; }

{ID} {
        yylval.strVal = strdup(yytext);
        return IDENTIFIER;
}

{INTEGER} {
        yylval.intVal = atoi(yytext);
        return NUMBER;
}

";"             { return SEMICOLON; }
"."             { return DOT; }

[ \t]+          ;

\n              { line_number++; }

<<EOF>>         { return 0; }

. {
    fprintf(stderr,
            "Lexical error at line %d: %s\n",
            line_number,
            yytext);
    exit(1);
}

%%

int yywrap()
{
    return 1;
}