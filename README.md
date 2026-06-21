# Compilador de Subconjunto Pascal para LLVM IR 🚀

Este projeto consiste no desenvolvimento de um compilador para um subconjunto da linguagem Pascal, gerando código intermediário (LLVM IR) nativo e compatível com a infraestrutura moderna do **LLVM 18**. 

O projeto foi desenvolvido como parte dos requisitos práticos da disciplina de Compiladores.

## 👥 Integrantes do Grupo
* **Geovanna Cristina Brenzinger**
* **Grazielle Batista de Almeida**
* **Giulia Meninel Mattedi**

---

## 🛠️ Especificações Técnicas do Compilador

O compilador foi estruturado utilizando as ferramentas clássicas de engenharia de linguagens de programação:
* **Análise Léxica (`lexer.l`):** Desenvolvido em **Flex**, responsável por mapear palavras-reservadas (`program`, `begin`, `end`, `if`, `while`, `ParamStr`), identificadores, números e operadores lógicos/aritméticos.
* **Análise Sintática (`parser.y`):** Desenvolvido em **Bison (Yacc)**, definindo a gramática estruturada e tratando a precedência de operadores.
* **Árvore Sintática Abstrata (`ast.h`):** Implementada em C++ para gerenciar os nós de expressões, atribuições e estruturas de controle, injetando as instruções diretamente na API do LLVM.

### Suporte ao LLVM 18 ⚙️
Para garantir compatibilidade com as versões estáveis e recentes do LLVM, o compilador adota:
1. **Ponteiros Opaque/Genéricos:** Migração de tipos obsoletos (`getInt8PtrTy`) para a especificação estável `llvm::PointerType::getUnqual(Context)`.
2. **Gerenciamento de Blocos de Controle:** Inserção explícita de desvios e rótulos condicionais utilizando a API pública `.insertInto(TheFunction)`.

---

## 📑 Funcionalidades Suportadas

O compilador aceita as seguintes construções da linguagem:
* Atribuições de variáveis (`:=`) e aritmética básica (`+`, `-`, `*`, `/`).
* Operadores relacionais (`<`, `>`, `=`, `<=`, `>=`, `<>`).
* Estrutura condicional pura (`if-then-else`) delimitada por blocos `begin ... end`.
* Laços de repetição (`while-do`).
* Leitura dinâmica de argumentos da linha de comando do Sistema Operacional através da função `ParamStr(Index)`.
* Saída padrão de dados por meio da função interna `writeln`.

---

## 🧪 Programas de Teste Obrigatórios

O repositório inclui os 4 casos de teste práticos exigidos no laboratório, adaptados para a gramática do compilador:

1. **`fibonacci.pas`**: Calcula o n-ésimo termo da sequência de Fibonacci de maneira iterativa.
2. **`isprime.pas`**: Algoritmo de verificação de número primo (retorna `1` para primo e `0` para composto).
3. **`factor.pas`**: Decompõe e imprime, linha por linha, os fatores primos do número fornecido.
4. **`pidigits.pas`**: Implementação da série de Gregory-Leibniz para aproximar os dígitos de Pi com escala inteira com base nas iterações fornecidas.

---

## 🚀 Como Compilar e Executar

Siga os passos manuais abaixo dentro do ambiente WSL/Linux para reconstruir o compilador e rodar os testes:

### 1. Limpeza e Construção do Compilador
```bash
# Limpar resíduos de compilações anteriores
rm -f parser.tab.c parser.tab.h lex.yy.c compiler programa_run saida.ll

# Gerar o parser e o lexer
bison -d parser.y
flex -o lex.yy.c lexer.l

# Compilar o driver do compilador ligando as bibliotecas do LLVM 18
g++ `llvm-config --cxxflags` -o compiler parser.tab.c lex.yy.c `llvm-config --ldflags --system-libs --libs core` -Wno-deprecated-register
