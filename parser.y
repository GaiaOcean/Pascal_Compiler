%{
#include <stdio.h>
#include <stdlib.h>

int yylex();
int yyparse();
void yyerror(const char *s);
%}

/* values coming from lexer */

%union {
    int intVal;
    char* strVal;
}

/* tokens */

%token PROGRAM
%token BEGIN_KW
%token END_KW

%token SEMICOLON
%token DOT

%token <strVal> IDENTIFIER
%token <intVal> NUMBER

%%

program:
      PROGRAM IDENTIFIER SEMICOLON block DOT
      {
          printf("Program is valid!\n");
      }
      ;

block:
      BEGIN_KW END_KW
      ;

%%

void yyerror(const char *s)
{
    fprintf(stderr, "Syntax Error: %s\n", s);
}

int main()
{
    return yyparse();
}