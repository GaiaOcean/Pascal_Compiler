#ifndef AST_H
#define AST_H

#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <llvm/IR/LLVMContext.h>
#include <llvm/IR/Module.h>
#include <llvm/IR/IRBuilder.h>

extern llvm::LLVMContext Context;
extern llvm::Module* ModuleOb;
extern llvm::IRBuilder<> Builder;
extern std::map<std::string, llvm::AllocaInst*> SymbolTable;
extern llvm::Function* PrintfFunc;
extern llvm::Value* ArgvGlobal;

class ASTNode {
public:
    virtual ~ASTNode() = default;
    virtual llvm::Value* codeGen() = 0;
};

class IntASTNode : public ASTNode {
    int Val;
public:
    IntASTNode(int val) : Val(val) {}
    llvm::Value* codeGen() override {
        return llvm::ConstantInt::get(Context, llvm::APInt(32, Val));
    }
};

class VariableASTNode : public ASTNode {
    std::string Name;
public:
    VariableASTNode(const std::string &name) : Name(name) {}
    llvm::Value* codeGen() override {
        llvm::AllocaInst* Alloca = SymbolTable[Name];
        if (!Alloca) {
            std::cerr << "Erro semântico: Variável não declarada " << Name << std::endl;
            return nullptr;
        }
        return Builder.CreateLoad(llvm::Type::getInt32Ty(Context), Alloca, Name.c_str());
    }
};

class ParamStrASTNode : public ASTNode {
    ASTNode* IndexExpr;
public:
    ParamStrASTNode(ASTNode* index) : IndexExpr(index) {}
    ~ParamStrASTNode() { delete IndexExpr; }
    llvm::Value* codeGen() override {
        llvm::Value* idx = IndexExpr->codeGen();
        if (!idx) return nullptr;

        llvm::Type* PtrTy = llvm::PointerType::getUnqual(Context);

        llvm::Value* ArgvPtr = Builder.CreateLoad(PtrTy, ArgvGlobal, "argv_load");
        llvm::Value* GEP = Builder.CreateGEP(PtrTy, ArgvPtr, idx, "argv_idx");
        llvm::Value* ArgStr = Builder.CreateLoad(PtrTy, GEP, "arg_str");

        llvm::Function* AtoiFunc = ModuleOb->getFunction("atoi");
        if (!AtoiFunc) {
            std::vector<llvm::Type*> AtoiArgs = { PtrTy };
            llvm::FunctionType* AtoiType = llvm::FunctionType::get(llvm::Type::getInt32Ty(Context), AtoiArgs, false);
            AtoiFunc = llvm::Function::Create(AtoiType, llvm::Function::ExternalLinkage, "atoi", ModuleOb);
        }

        return Builder.CreateCall(AtoiFunc, ArgStr, "atoi_call");
    }
};

class BinaryExprASTNode : public ASTNode {
    std::string Op;
    ASTNode *LHS, *RHS;
public:
    BinaryExprASTNode(const std::string &op, ASTNode* lhs, ASTNode* rhs) : Op(op), LHS(lhs), RHS(rhs) {}
    ~BinaryExprASTNode() { delete LHS; delete RHS; }
    llvm::Value* codeGen() override {
        llvm::Value* L = LHS->codeGen();
        llvm::Value* R = RHS->codeGen();
        if (!L || !R) return nullptr;

        if (Op == "+") return Builder.CreateAdd(L, R, "addtmp");
        if (Op == "-") return Builder.CreateSub(L, R, "subtmp");
        if (Op == "*") return Builder.CreateMul(L, R, "multmp");
        if (Op == "/") return Builder.CreateSDiv(L, R, "divtmp");
        
        llvm::Value* Comp = nullptr;
        if (Op == "<")  Comp = Builder.CreateICmpSLT(L, R, "cmptmp");
        if (Op == ">")  Comp = Builder.CreateICmpSGT(L, R, "cmptmp");
        if (Op == "<=") Comp = Builder.CreateICmpSLE(L, R, "cmptmp");
        if (Op == ">=") Comp = Builder.CreateICmpSGE(L, R, "cmptmp");
        if (Op == "=")  Comp = Builder.CreateICmpEQ(L, R, "cmptmp");
        if (Op == "<>") Comp = Builder.CreateICmpNE(L, R, "cmptmp");
        
        if (Comp) return Builder.CreateZExt(Comp, llvm::Type::getInt32Ty(Context), "booltmp");
        return nullptr;
    }
};

class AssignmentASTNode : public ASTNode {
    std::string Name;
    ASTNode* Expr;
public:
    AssignmentASTNode(const std::string &name, ASTNode* expr) : Name(name), Expr(expr) {}
    llvm::Value* codeGen() override {
        llvm::Value* Val = Expr->codeGen();
        if (!Val) return nullptr;
        if (SymbolTable.find(Name) == SymbolTable.end()) {
            SymbolTable[Name] = Builder.CreateAlloca(llvm::Type::getInt32Ty(Context), nullptr, Name);
        }
        return Builder.CreateStore(Val, SymbolTable[Name]);
    }
};

class IfASTNode : public ASTNode {
    ASTNode *Cond, *Then, *Else;
public:
    IfASTNode(ASTNode* cond, ASTNode* thenBlk, ASTNode* elseBlk = nullptr) 
        : Cond(cond), Then(thenBlk), Else(elseBlk) {}
    llvm::Value* codeGen() override {
        llvm::Value* CondV = Cond->codeGen();
        if (!CondV) return nullptr;
        
        CondV = Builder.CreateICmpNE(CondV, llvm::ConstantInt::get(Context, llvm::APInt(32, 0)), "ifcond");
        
        llvm::Function* TheFunction = Builder.GetInsertBlock()->getParent();
        llvm::BasicBlock* ThenBB = llvm::BasicBlock::Create(Context, "then", TheFunction);
        llvm::BasicBlock* ElseBB = llvm::BasicBlock::Create(Context, "else");
        llvm::BasicBlock* MergeBB = llvm::BasicBlock::Create(Context, "ifcont");
        
        Builder.CreateCondBr(CondV, ThenBB, Else ? ElseBB : MergeBB);
        
        Builder.SetInsertPoint(ThenBB);
        Then->codeGen();
        Builder.CreateBr(MergeBB);
        
        if (Else) {
            ElseBB->insertInto(TheFunction);
            Builder.SetInsertPoint(ElseBB);
            Else->codeGen();
            Builder.CreateBr(MergeBB);
        }
        
        MergeBB->insertInto(TheFunction);
        Builder.SetInsertPoint(MergeBB);
        return nullptr;
    }
};

class WhileASTNode : public ASTNode {
    ASTNode *Cond, *Body;
public:
    WhileASTNode(ASTNode* cond, ASTNode* body) : Cond(cond), Body(body) {}
    llvm::Value* codeGen() override {
        llvm::Function* TheFunction = Builder.GetInsertBlock()->getParent();
        
        llvm::BasicBlock* CondBB = llvm::BasicBlock::Create(Context, "whilecond", TheFunction);
        llvm::BasicBlock* LoopBB = llvm::BasicBlock::Create(Context, "whilebody");
        llvm::BasicBlock* AfterBB = llvm::BasicBlock::Create(Context, "whileafter");
        
        Builder.CreateBr(CondBB);
        Builder.SetInsertPoint(CondBB);
        
        llvm::Value* CondV = Cond->codeGen();
        CondV = Builder.CreateICmpNE(CondV, llvm::ConstantInt::get(Context, llvm::APInt(32, 0)), "whilecondv");
        Builder.CreateCondBr(CondV, LoopBB, AfterBB);
        
        LoopBB->insertInto(TheFunction);
        Builder.SetInsertPoint(LoopBB);
        Body->codeGen();
        Builder.CreateBr(CondBB);
        
        AfterBB->insertInto(TheFunction);
        Builder.SetInsertPoint(AfterBB);
        return nullptr;
    }
};

class WritelnASTNode : public ASTNode {
    ASTNode* Expr;
public:
    WritelnASTNode(ASTNode* expr) : Expr(expr) {}
    llvm::Value* codeGen() override {
        llvm::Value* Val = Expr->codeGen();
        if (!Val) return nullptr;
        
        llvm::Value* FormatStr = Builder.CreateGlobalStringPtr("%d\n", "strfmt");
        std::vector<llvm::Value*> Args = { FormatStr, Val };
        return Builder.CreateCall(PrintfFunc, Args, "callprintf");
    }
};

class BlockASTNode : public ASTNode {
    std::vector<ASTNode*> Statements;
public:
    void addStatement(ASTNode* stmt) { if(stmt) Statements.push_back(stmt); }
    llvm::Value* codeGen() override {
        llvm::Value* last = nullptr;
        for (ASTNode* stmt : Statements) last = stmt->codeGen();
        return last;
    }
};

#endif