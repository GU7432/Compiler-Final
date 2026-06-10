#include <string.h>

#ifndef MAX_SYMBOLS
#define MAX_SYMBOLS 200000
#endif

#define HASH_PRIME 17

int getHash(char* identifier){
    char* p = identifier;
    int hash = 0;
    while(*p != '\0'){
        hash += *p;
        hash *= HASH_PRIME;
        hash %= MAX_SYMBOLS;
        ++p;
    }
    return hash;
}

char* symbolic_table[MAX_SYMBOLS];

void insert_table(char* identifier){
    int hash = getHash(identifier);
    if(symbolic_table[hash]) return;
    symbolic_table[getHash(identifier)] = strdup(identifier);
}