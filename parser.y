%{
#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/IRBuilder.h>

llvm::LLVMContext Context;
llvm::Module* ModuleOb = new llvm::Module("PascalLLVM", Context);
llvm::IRBuilder<> Builder(Context);
std::map<std::string, llvm::AllocaInst*> SymbolTable;
llvm::Function* PrintfFunc = nullptr;
llvm::Value* ArgvGlobal = nullptr;

#include "ast.h"

int yylex();
void yyerror(const char *s);
%}

%union {
    int intVal;
    std::string* strVal;
    ASTNode* node;
    BlockASTNode* block;
}

%token PROGRAM BEGIN_KW END_KW SEMICOLON DOT ASSIGN
%token IF THEN ELSE WHILE DO WRITELN PARAMSTR
%token <strVal> IDENTIFIER LE GE NE
%token <intVal> NUMBER

%type <block> statements
%type <node> statement expr

%left '=' NE '<' '>' LE GE
%left '+' '-'
%left '*' '/'

%%

program:
      PROGRAM IDENTIFIER SEMICOLON BEGIN_KW statements END_KW DOT
      {
          if ($5) $5->codeGen();
          Builder.CreateRet(llvm::ConstantInt::get(Context, llvm::APInt(32, 0)));
          delete $5;
          delete $2;
      }
      ;

statements:
      statement {
          $$ = new BlockASTNode();
          $$->addStatement($1);
      }
      | statements statement {
          if ($1 && $2) $1->addStatement($2);
          $$ = $1;
      }
      ;

statement:
      IDENTIFIER ASSIGN expr SEMICOLON {
          $$ = new AssignmentASTNode(*$1, $3);
          delete $1;
      }
      | IF expr THEN BEGIN_KW statements END_KW ELSE BEGIN_KW statements END_KW SEMICOLON {
          $$ = new IfASTNode($2, $5, $9);
      }
      | IF expr THEN BEGIN_KW statements END_KW SEMICOLON {
          $$ = new IfASTNode($2, $5, nullptr);
      }
      | WHILE expr DO BEGIN_KW statements END_KW SEMICOLON {
          $$ = new WhileASTNode($2, $5);
      }
      | WRITELN '(' expr ')' SEMICOLON {
          $$ = new WritelnASTNode($3);
      }
      ;

expr:
      NUMBER                  { $$ = new IntASTNode($1); }
      | IDENTIFIER            { $$ = new VariableASTNode(*$1); delete $1; }
      | PARAMSTR '(' expr ')' { $$ = new ParamStrASTNode($3); }
      | expr '+' expr         { $$ = new BinaryExprASTNode("+", $1, $3); }
      | expr '-' expr         { $$ = new BinaryExprASTNode("-", $1, $3); }
      | expr '*' expr         { $$ = new BinaryExprASTNode("*", $1, $3); }
      | expr '/' expr         { $$ = new BinaryExprASTNode("/", $1, $3); }
      | expr '<' expr         { $$ = new BinaryExprASTNode("<", $1, $3); }
      | expr '>' expr         { $$ = new BinaryExprASTNode(">", $1, $3); }
      | expr '=' expr         { $$ = new BinaryExprASTNode("=", $1, $3); }
      | expr LE expr          { $$ = new BinaryExprASTNode("<=", $1, $3); delete $2; }
      | expr GE expr          { $$ = new BinaryExprASTNode(">=", $1, $3); delete $2; }
      | expr NE expr          { $$ = new BinaryExprASTNode("<>", $1, $3); delete $2; }
      | '(' expr ')'          { $$ = $2; }
      ;

%%

void yyerror(const char *s) {
    std::cerr << "Erro Sintático: " << s << std::endl;
}

int main() {
    ModuleOb->setTargetTriple("x86_64-pc-linux-gnu");

    llvm::Type* PtrTy = llvm::PointerType::getUnqual(Context);

    std::vector<llvm::Type*> PrintfArgs = { PtrTy };
    llvm::FunctionType* PrintfType = llvm::FunctionType::get(llvm::Type::getInt32Ty(Context), PrintfArgs, true);
    PrintfFunc = llvm::Function::Create(PrintfType, llvm::Function::ExternalLinkage, "printf", ModuleOb);

    std::vector<llvm::Type*> MainArgTypes = {
        llvm::Type::getInt32Ty(Context),
        PtrTy
    };
    llvm::FunctionType *FT = llvm::FunctionType::get(llvm::Type::getInt32Ty(Context), MainArgTypes, false);
    llvm::Function *MainFunc = llvm::Function::Create(FT, llvm::Function::ExternalLinkage, "main", ModuleOb);
    
    llvm::BasicBlock *BB = llvm::BasicBlock::Create(Context, "entry", MainFunc);
    Builder.SetInsertPoint(BB);

    auto ArgsIt = MainFunc->arg_begin();
    llvm::Value* ArgcVal = &*ArgsIt++;
    llvm::Value* ArgvVal = &*ArgsIt;

    llvm::AllocaInst* ArgcAlloca = Builder.CreateAlloca(llvm::Type::getInt32Ty(Context), nullptr, "ParamCount");
    Builder.CreateStore(ArgcVal, ArgcAlloca);
    SymbolTable["ParamCount"] = ArgcAlloca;

    ArgvGlobal = Builder.CreateAlloca(PtrTy, nullptr, "argv_storage");
    Builder.CreateStore(ArgvVal, ArgvGlobal);

    yyparse();

    ModuleOb->print(llvm::outs(), nullptr);
    return 0;
}