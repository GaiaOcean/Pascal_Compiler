%{
#include "ast.h"
#include "parser.tab.h"
#include <iostream>
#include <string>

int line_number = 1;
%}

%option noyywrap

DIGIT       [0-9]
LETTER      [a-zA-Z]
ID          {LETTER}({LETTER}|{DIGIT}|_)*
INTEGER     {DIGIT}+

%%

"program"       { return PROGRAM; }
"begin"         { return BEGIN_KW; }
"end"           { return END_KW; }
"if"            { return IF; }
"then"          { return THEN; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"do"            { return DO; }
"writeln"       { return WRITELN; }
"ParamStr"      { return PARAMSTR; }

{ID} {
        yylval.strVal = new std::string(yytext);
        return IDENTIFIER;
}

{INTEGER} {
        yylval.intVal = atoi(yytext);
        return NUMBER;
}

":="            { return ASSIGN; }
";"             { return SEMICOLON; }
"."             { return DOT; }

"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }

"<="            { yylval.strVal = new std::string("<="); return LE; }
">="            { yylval.strVal = new std::string(">="); return GE; }
"<>"            { yylval.strVal = new std::string("<>"); return NE; }
"<"             { yylval.strVal = new std::string("<"); return '<'; }
">"             { yylval.strVal = new std::string(">"); return '>'; }
"="             { yylval.strVal = new std::string("="); return '='; }

\(              { return '('; }
\)              { return ')'; }

[ \t]+          ;
\n              { line_number++; }

. {
    std::cerr << "Erro léxico na linha " << line_number << ": Caractere inválido '" << yytext << "'" << std::endl;
    exit(1);
}

%%