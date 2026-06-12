%{
#include "SymbolicEngine.tab.h"
%}

%option noyywrap

%%

"+" { return ADD; }
"-" { return SUB; }
"*" { return MUL; }
"/" { return DIV; }
"|" { return ABS; }
"=" { return EQ;}
"(" { return LP;}
")" { return RP;}
"^" { return EXP;}

[A-Za-z] {
    yylval.id = strdup(yytext);
    return ID;
}

[0-9]+ {
    yylval.fval = atoi(yytext);
    return NUMBER;
}


\n {return EOL;}
[ \t] {/*skip space*/}
. {printf("illegal syntax %c\n", *yytext);}

%%