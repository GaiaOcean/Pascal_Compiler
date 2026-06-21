#!/bin/bash
# Script para compilar e testar os programas Mini-Pascal automaticamente

echo "--- Construindo o Compilador ---"
make

echo -e "\n--- Testando Fibonacci (Entrada: 10) ---"
./compiler fibonacci.pas -o fibonacci
./fibonacci 10

echo -e "\n--- Testando IsPrime (Entrada: 17) ---"
./compiler isprime.pas -o isprime
./isprime 17

echo -e "\n--- Testando Factor (Entrada: 84) ---"
./compiler factor.pas -o factor
./factor 84

echo -e "\n--- Testando PiDigits (Entrada: 6) ---"
./compiler pidigits.pas -o pidigits
./pidigits 6

echo -e "\n Fim"