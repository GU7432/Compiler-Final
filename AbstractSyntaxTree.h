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