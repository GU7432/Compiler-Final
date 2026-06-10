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
static int same_var(const char* a, const char* b) {
    if (!a || !b) return 0;
    for (int i = 0; ; i++) {
        if (a[i] != b[i]) return 0;
        if (a[i] == '\0') return 1;
    }
}

/* Extract coefficient and variable from: num, var, num*var, var*num, num*var^exp, var^exp,
   or a simplified mul-tree that is already a single-variable power product. */
static double get_coeff(Node* node, const char** var_out, double* exp_out) {
    if (node->type == node_num) {
        *var_out = NULL; *exp_out = 1.0; return node->val;
    }
    if (node->type == node_term) {
        *var_out = node->id; *exp_out = 1.0; return 1.0;
    }
    if (node->type == node_exp && node->left->type == node_term && node->right->type == node_num) {
        *var_out = node->left->id; *exp_out = node->right->val; return 1.0;
    }
    if (node->type == node_mul) {
        /* num * something */
        if (node->left->type == node_num) {
            double sub_coeff = get_coeff(node->right, var_out, exp_out);
            return node->left->val * sub_coeff;
        }
        /* something * num */
        if (node->right->type == node_num) {
            double sub_coeff = get_coeff(node->left, var_out, exp_out);
            return node->right->val * sub_coeff;
        }
        /* x^m * x^n  (after recursion both sides are clean power terms) */
        const char *lvar = NULL, *rvar = NULL;
        double lexp, rexp;
        double lc = get_coeff(node->left,  &lvar, &lexp);
        double rc = get_coeff(node->right, &rvar, &rexp);
        if (lvar && rvar && same_var(lvar, rvar)) {
            *var_out = lvar;
            *exp_out = lexp + rexp;
            return lc * rc;
        }
    }
    *var_out = NULL; *exp_out = 0.0; return 0.0;
}

/* Build coefficient * var^exp node */
static Node* make_term_node(double coeff, const char* var, double exp) {
    if (var == NULL) return make_num(coeff);
    Node* base = make_variable((char*)var);
    Node* xexp = (exp == 1.0) ? base : make_op(node_exp, base, make_num(exp));
    if (coeff == 1.0) return xexp;
    return make_op(node_mul, make_num(coeff), xexp);
}

Node* simplify(Node* node) {
    if (node == NULL) return NULL;

    /* Recurse first */
    if (node->type != node_num && node->type != node_term) {
        node->left  = simplify(node->left);
        node->right = simplify(node->right);
    }

    /* Constant folding */
    if (node->left && node->left->type == node_num &&
        node->right && node->right->type == node_num) {
        double l = node->left->val, r = node->right->val;
        switch (node->type) {
            case node_add: return make_num(l + r);
            case node_sub: return make_num(l - r);
            case node_mul: return make_num(l * r);
            case node_div: return (sgn(r) != 0) ? make_num(l / r) : node;
            case node_exp: {
                double result = 1.0;
                for (int i = 0; i < (int)r; ++i) result *= l;
                return make_num(result);
            }
            default: break;
        }
    }

    if (node->type == node_mul) {
        Node *l = node->left, *r = node->right;
        if (l->type == node_num && sgn(l->val) == 0) return make_num(0.0);
        if (r->type == node_num && sgn(r->val) == 0) return make_num(0.0);
        if (l->type == node_num && sgn(l->val - 1.0) == 0) return r;
        if (r->type == node_num && sgn(r->val - 1.0) == 0) return l;

        /* a * (b * expr)  ->  (a*b) * expr  (flatten nested num coefficients) */
        if (l->type == node_num && r->type == node_mul && r->left->type == node_num)
            return simplify(make_op(node_mul, make_num(l->val * r->left->val), r->right));
        if (r->type == node_num && l->type == node_mul && l->left->type == node_num)
            return simplify(make_op(node_mul, make_num(r->val * l->left->val), l->right));

        /* x^m * x^n -> coeff * x^(m+n) */
        const char *lvar = NULL, *rvar = NULL;
        double lexp, rexp;
        double lc = get_coeff(l, &lvar, &lexp);
        double rc = get_coeff(r, &rvar, &rexp);
        if (lvar && rvar && same_var(lvar, rvar)) {
            return simplify(make_term_node(lc * rc, lvar, lexp + rexp));
        }
    }

    if (node->type == node_add) {
        Node *l = node->left, *r = node->right;
        if (l->type == node_num && sgn(l->val) == 0) return r;
        if (r->type == node_num && sgn(r->val) == 0) return l;

        /* Like-term combining: ax^n + bx^n -> (a+b)x^n */
        const char *lvar = NULL, *rvar = NULL;
        double lexp, rexp, lcoeff, rcoeff;
        lcoeff = get_coeff(l, &lvar, &lexp);
        rcoeff = get_coeff(r, &rvar, &rexp);
        if (lvar && rvar && lexp == rexp && same_var(lvar, rvar)) {
            return make_term_node(lcoeff + rcoeff, lvar, lexp);
        }
    }

    if (node->type == node_sub) {
        Node *l = node->left, *r = node->right;
        if (r->type == node_num && sgn(r->val) == 0) return l;
        if (l->type == node_num && sgn(l->val) == 0) return make_op(node_mul, make_num(-1.0), r);

        /* ax^n - bx^n -> (a-b)x^n */
        const char *lvar = NULL, *rvar = NULL;
        double lexp, rexp, lcoeff, rcoeff;
        lcoeff = get_coeff(l, &lvar, &lexp);
        rcoeff = get_coeff(r, &rvar, &rexp);
        if (lvar && rvar && lexp == rexp && same_var(lvar, rvar)) {
            double diff = lcoeff - rcoeff;
            return make_term_node(diff, lvar, lexp);
        }
    }

    if (node->type == node_exp) {
        Node *l = node->left, *r = node->right;
        if (r->type == node_num && sgn(r->val) == 0) return make_num(1.0);
        if (r->type == node_num && sgn(r->val - 1.0) == 0) return l;
        if (l->type == node_num && sgn(l->val) == 0) return make_num(0.0);
        if (l->type == node_num && sgn(l->val - 1.0) == 0) return make_num(1.0);
    }

    return node;
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
const double eps = 1e-18;
int sgn(double x){
    return (x > eps) - (x < -eps);
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
    Node* simnode = simplify(ast_root);

    // Node* d = simplify(derive(simplify(ast_root)));
    print_tree_plain(simnode, 0);
    printf("\n");
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}