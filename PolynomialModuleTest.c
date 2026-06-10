#include <stdlib.h>
#include <stdio.h>

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
    else
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


void main(){
    poly_h handle = add_poly(0,0);
    for(int i = 0; i < 10; ++i){
        add_poly_term(polynomials[handle],i*6,i/2);
    }
    add_poly_term(polynomials[handle],0,100);
    add_poly_term(polynomials[handle],0,100);
    print_poly(polynomials[handle]);
    sort_poly(polynomials[handle]);
    print_poly(polynomials[handle]);
}