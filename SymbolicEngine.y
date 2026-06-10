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
|LP exp RP EXP NUMBER { $$ = make_op(node_exp, $2 , make_num($5)); }
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


static poly_t poly_pow(poly_t P, int n) {
    poly_t result = make_poly(P->id);
    add_poly_term(result, 1.0, 0.0);
    for (int i = 0; i < n; ++i) {
        poly_t tmp = mul(result, P);
        result = tmp;
    }
    return result;
}

poly_t ast_to_poly(Node* node) {
    if (node == NULL) return NULL;

    if (node->type == node_num) {
        poly_t P = make_poly(0);
        add_poly_term(P, node->val, 0.0);
        node->poly = P;
        return P;
    }

    if (node->type == node_term) {
        insert_table(node->id);
        poly_t P = make_poly(getHash(node->id));
        add_poly_term(P, 1.0, 1.0);
        node->poly = P;
        return P;
    }

    if (node->type == node_exp) {
        poly_t base = ast_to_poly(node->left);
        int n = (int)node->right->val;
        poly_t P = poly_pow(base, n);
        sort_poly(P);
        node->poly = P;
        return P;
    }

    poly_t L = ast_to_poly(node->left);
    poly_t R = ast_to_poly(node->right);

    poly_t P = NULL;
    switch (node->type) {
        case node_add: P = add(L, R); break;
        case node_sub: P = sub(L, R); break;
        case node_mul: P = mul(L, R); break;
        case node_div:
            if (R->root && R->root->next == NULL && sgn(R->root->expo) == 0) {
                P = mul_scalar(1.0 / R->root->coeff, L);
            } else {
                fprintf(stderr, "Warning: non-constant divisor — treating as 1\n");
                P = L;
            }
            break;
        default: P = make_poly(0); break;
    }
    sort_poly(P);
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

    poly_t result = ast_to_poly(ast_root);
    if (result) {
        print_poly(result);
    }

    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}