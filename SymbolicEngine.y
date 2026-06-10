%{
#include <stdio.h>
#include <stdlib.h>
#include "PolynomialModule.h"
#include "AbstractSyntaxTree.h"

extern int yylex();
void yyerror(const char *s);
int sgn(double x);

Node* ast_root = NULL;
%}

%union{
    double fval;
    char* id; 
    struct Node* node;
}

%token <fval> NUMBER
%token ADD SUB MUL DIV EQ EXP
%token LP RP ABS
%token <id> ID
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
;

factor:
term { $$ = $1;}
|factor MUL term { $$ = make_op(node_mul, $1, $3); }
|factor DIV term { $$ = make_op(node_div, $1, $3); }
;

term:
NUMBER { $$ = make_num($1);}
|LP exp RP { $$ = $2; }
|ID { $$ = make_variable($1); }
|ID EXP NUMBER { $$ = make_op(node_exp, make_variable($1), make_num($3)); }
;

%%

Node* derive(Node *node){
    if(node == NULL) return node;

    if(node->type == node_num){
        return make_num(0.0);
    }

    if(node->type == node_add || node->type == node_sub){
        return make_op(node->type,derive(node->left),derive(node->right));
    }

    if(node->type == node_exp){
        Node *c = make_num(node->right->val);
        Node *x = make_variable(node->left->id); //x
        Node *n = make_num(node->right->val - 1); //val

        Node *right = make_op(node_exp,x,n); // x^n
        return make_op(node_mul,c,right);
    }
    
    if(node->type == node_term){
        return make_variable(node->id);
    }

    if(node->type == node_mul){
        //(fg)' = f'g + fg'
        Node *left = make_op(node_mul,node_dup(node->left),derive(node->right)); //f'g
        Node *right = make_op(node_mul,derive(node->left),node_dup(node->right)); //fg'
        return make_op(node_add,left,right);
    }
    
}

void to_poly_plain(Node* node,int handle){
    if(node == NULL) return;
    if(node->type == node_mul){
        add_poly_term(polynomials[handle],node->left->val,node->right->val);
        return;
    }
    if(node->type == node_exp){
        add_poly_term(polynomials[handle],1.0,node->right->val);
        return;
    }
    to_poly_plain(node->left,handle);
    to_poly_plain(node->right,handle);
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

    // print_tree_plain(ast_root, 0);
    poly_h handle = add_poly(0,0);
    to_poly_plain(ast_root,handle);
    printf("\n");
    print_poly(polynomials[handle]);
    sort_poly(polynomials[handle]);
    print_poly(polynomials[handle]);
    
    printf("\n");
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}