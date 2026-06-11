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

([-]?)([0-9]+) {
    yylval.fval = atoi(yytext);
    return NUMBER;
}

[A-Za-z]+[0-9]* {
    yylval.id = strdup(yytext);
    return ID;
}

\n {return EOL;}
[ \t] {/*skip space*/}
. {printf("illegal syntax %c\n", *yytext);}

%%