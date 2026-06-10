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
Node* make_node(NodeType type, Node* left, Node* right,double val,char* id){
    Node* node = (Node*)malloc(sizeof(Node));
    node->type = type;
    node->val = val;
    node->left = left;
    node->right = right;
    node->id = id;
    return node;
}

extern int yylex();
void yyerror(const char *s);

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

Node* node_dup(Node* ori){
    Node* ret = (Node*)malloc(sizeof(Node));
    *ret = *ori;
    return ret;
}
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
void print_tree(Node* node,int dep){
    if(node == NULL) return;
    // for(int i = 0; i < dep; ++i) printf(" ");
    print_tree(node->left,dep+1);
    switch(node->type) {
        case node_num: printf("[%g]", node->val); break;
        case node_add: printf("[+]"); break;
        case node_sub: printf("[-]"); break;
        case node_term: printf("[%s]",node->id); break;
        case node_div: printf("[/]"); break;
    }
    print_tree(node->right,dep+2);
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
        case node_term: printf("%s",node->id); break;
        case node_div: printf("/"); break;
    }
    print_tree_plain(node->right,dep+1);
}
int main(int argc,char **argv){
    yyparse();
    print_tree_plain(derive(ast_root),0);
    printf("\n");
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}