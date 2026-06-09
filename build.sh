bison -d SymbolicEngine.y
flex SymbolicEngine.l
gcc SymbolicEngine.tab.c lex.yy.c -o SymbolicEngine && ./SymbolicEngine