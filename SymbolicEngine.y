%{
#include <stdio.h>
#include <stdlib.h>
#include "FormalPowerSeries.h"
#include "AbstractSyntaxTree.h"
#include "SymbolicMapping.h"

extern int yylex();
void yyerror(const char *s);
int sgn(double x);
#define PMODTERM 30

Node* ast_root = NULL;
%}

%union{
    long long fval;
    char* id; 
    struct Node* node;
}

%token <fval> NUMBER
%token ADD SUB MUL DIV EQ EXP
%token LP RP ABS
%token <id> ID
%token SQRT
%token E
%token EOL

%type <node> exp factor term

%%

tree_root:
|tree_root exp EOL {
    ast_root = $2;
    return 0;
}
;

exp:
factor { $$ = $1;}
|exp ADD factor { $$ = make_op(node_add, $1, $3); }
|exp SUB factor { $$ = make_op(node_sub, $1, $3); }
|SUB factor { $$ = make_op(node_sub,NULL,$2); }
;

factor:
term { $$ = $1;}
|factor MUL term { $$ = make_op(node_mul, $1, $3); }
|factor DIV term { $$ = make_op(node_div, $1, $3); }
;

term:
NUMBER { $$ = make_num($1);}
|ID { $$ = make_variable($1); }
|LP exp RP { $$ = $2; }
|ID EXP NUMBER { $$ = make_op(node_exp, make_variable($1), make_num($3)); }
|LP exp RP EXP NUMBER { $$ = make_op(node_exp, $2 , make_num($5)); }
;

%%

poly ast_to_poly(Node* node) {
    if (node == NULL) return NULL;

    if (node->type == node_num) {
        poly P = make_poly(1);
        P->a[0] = node->val;
        node->poly = P;
        return P;
    }

    if (node->type == node_term) {
        insert_table(node->id);
        poly P = make_poly(2);
        P->a[1] = 1;
        node->poly = P;
        return P;
    }

    if (node->type == node_exp) {
        poly base = ast_to_poly(node->left);
        int n = (int)node->right->val;
        poly P = poly_pow(base, n);
        node->poly = P;
        return P;
    }

    poly L = ast_to_poly(node->left);
    poly R = ast_to_poly(node->right);

    poly P = NULL;
    switch (node->type) {
        case node_add: P = add(L, R); break;
        case node_sub: {
            if(L == NULL) P = sub(make_poly(1),R);
            else P = sub(L, R); 
            break;
        }
        case node_mul: P = mul(L, R); break;
        case node_div: {
            poly IR = inverse(R,PMODTERM);
            P = mul(L,IR);
            break;
        }
        default: P = make_poly(0); break;
    }
    node->poly = P;
    return P;
}

void print_tree_plain(Node* node,int dep){
    if(node == NULL) return;
    print_tree_plain(node->left,dep+1);

    switch(node->type) {
        case node_num: printf("%g", node->val); break;
        case node_add: printf("+"); break;
        case node_exp: printf("^"); break;
        case node_mul: printf("*"); break;
        case node_sub: printf("-"); break;
        case node_div: printf("/"); break;

        case node_term: printf("%s",node->id); break;
    }
    print_tree_plain(node->right,dep+1);
}
int main(int argc,char **argv){
    yyparse();

    poly result = ast_to_poly(ast_root);
    if (result) {
        print_poly(result);
        printf("\n");
    }

    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}