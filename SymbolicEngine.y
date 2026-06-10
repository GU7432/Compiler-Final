%{
#include <stdio.h>
#include <stdlib.h>

typedef enum { 
    node_num,
    node_add,
    node_sub,
    node_mul,
    node_div,
    node_fun,
    node_term,
    node_exp
} NodeType;

typedef struct Node {
    NodeType type;
    double val;
    char* id;
    struct Node *left;
    struct Node *right;
} Node;
Node* make_num(double val){
    Node* node = (Node*)malloc(sizeof(Node));
    node->type = node_num;
    node->val = val;
    node->left = NULL;
    node->right = NULL;
    return node;
}
Node* make_variable(char* id){
    Node* node = (Node*)malloc(sizeof(Node));
    node->type = node_term;
    node->val = 0.0;
    node->id = id;
    return node;
}
Node* make_op(NodeType type, Node* left, Node* right){
    Node* node = (Node*)malloc(sizeof(Node));
    node->type = type;
    node->left = left;
    node->right = right;
    return node;
}

Node* node_dup(Node* ori){
    Node* ret = (Node*)malloc(sizeof(Node));
    *ret = *ori;
    return ret;
}

Node* make_node(NodeType type, Node* left, Node* right,double val,char* id){
    Node* node = (Node*)malloc(sizeof(Node));
    node->type = type;
    node->val = val;
    node->left = left;
    node->right = right;
    node->id = id;
    return node;
}

#define MAX_POLY_TERMS 200000
#define MAX_SYMBOLS 200000

typedef struct poly_term{
    double expo;
    double coeff;
    struct poly_term* next;
} poly_term;

typedef struct poly{
    poly_term* root;
    poly_term* tail;
    int id;
    int func;
    int sym_pos;
} poly;

const double eps = 1e-18;
int sgn(double x){
    return (x > eps) - (x < -eps);
}

poly_term* tmp_terms[MAX_POLY_TERMS];
int compare(const void* a,const void *b){
    poly_term* p = *(poly_term**)a;
    poly_term* q = *(poly_term**)b;
    
    if(sgn(p->expo - q->expo) == 0) return 0;
    return (p->expo > q->expo ? -1 : 1);
}
void print_term(poly_term* t){
    if(sgn(t->expo) == 0)
    printf("%g",t->coeff);
    else if(sgn(t->coeff - 1) == 0){
        printf("x^%g",t->expo);
    }else
    printf("%gx^%g",t->coeff,t->expo);
}
int merge_terms(int n){
    int i = 0;
    int t = 0; //last usable pos
    while(i < n){
        int j = i;
        while(j < n && sgn(tmp_terms[j]->expo - tmp_terms[i]->expo) == 0) ++j;
        poly_term* cur_term = tmp_terms[i];
        for(int k = i + 1; k < j; ++k){
            cur_term->coeff += tmp_terms[k]->coeff;
        }
        if(sgn(cur_term->coeff) != 0){
            tmp_terms[t++] = cur_term;
        }
        i = j;
    }
    for(int k = 0; k < t - 1; ++k){
        tmp_terms[k]->next = tmp_terms[k+1];
    }
    tmp_terms[t-1]->next = NULL;
    return t;

}
int duplicate_to_tmp(poly* P){
    int t = 0;
    poly_term* root = P->root;
    while(root) tmp_terms[t++] = root, root = root->next;
    return t;
}
void sort_poly(poly* P){
    int t = duplicate_to_tmp(P);
    qsort(tmp_terms,t,sizeof(poly_term*),compare);
    t = merge_terms(t);
    P->root = NULL;
    P->tail = NULL;
    if(t){
        P->root = tmp_terms[0];
        P->tail = tmp_terms[t-1];
    }
}
void add_poly_term(poly* P,double coef,double exp){
    poly_term* term = (poly_term*)malloc(sizeof(poly_term));
    term->coeff = coef;
    term->expo = exp;
    term->next = NULL;
    if(!P->root){
        P->root = term;
        P->tail = term;
        return;
    }
    P->tail->next = term;
    P->tail = term;
}
void print_poly(poly* p){
    poly_term* cur = p->root;
    while(cur != p->tail){
        print_term(cur);
        printf("+");
        cur = cur->next;
    }
    if(p->tail) print_term(p->tail);
    printf("\n");
}

poly* polynomials[MAX_SYMBOLS];
int current_poly_count = 0;

typedef int poly_h;

//return poly handle
poly_h add_poly(int id,int func){
    poly* P = (poly*)malloc(sizeof(poly));
    P->id = id;
    P->func = func;
    P->sym_pos = current_poly_count;
    P->root = NULL;
    P->tail = NULL;
    polynomials[current_poly_count] = P;
    current_poly_count++;
    return current_poly_count - 1;
}


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