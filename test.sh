#!/bin/bash
# Script para compilar e testar os programas Mini-Pascal automaticamente

echo "--- Construindo o Compilador ---"
make

echo -e "\n--- Testando Fibonacci (Entrada: 10) ---"
./compiler < fibonacci.pas > fibonacci.ll
clang fibonacci.ll -o fibonacci
./fibonacci 10

echo -e "\n--- Testando IsPrime (Entrada: 17) ---"
./compiler < isprime.pas > isprime.ll
clang isprime.ll -o isprime
./isprime 17

echo -e "\n--- Testando Factor (Entrada: 84) ---"
./compiler < factor.pas > factor.ll
clang factor.ll -o factor
./factor 84

echo -e "\n--- Testando PiDigits (Entrada: 6) ---"
./compiler < pidigits.pas > pidigits.ll
clang pidigits.ll -o pidigits
./pidigits 6

echo -e "\n Fim"