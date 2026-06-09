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
|exp ADD factor { $$ = make_node(node_add, $1, $3,0,NULL); }
|exp SUB factor { $$ = make_node(node_sub, $1, $3,0,NULL); }
;

factor:
term { $$ = $1;}
|factor MUL term { $$ = make_node(node_mul, $1, $3,0,NULL); }
|factor DIV term { $$ = make_node(node_div, $1, $3,0,NULL); }
;

term:
NUMBER { $$ = make_node(node_num, NULL, NULL, $1,NULL);}
|LP exp RP { $$ = $2; }
|ID { $$ = make_node(node_term, NULL, NULL, 0.0, $1); }
;

%%

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
int main(int argc,char **argv){
    yyparse();
    print_tree(ast_root,0);
    printf("\n");
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}