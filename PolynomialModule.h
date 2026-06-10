
#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#define MAX_POLY_TERMS 200000
#define MAX_SYMBOLS 200000

#include "SymbolicMapping.h"

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
} poly;

const double eps = 1e-9;
int sgn(double x){
    return (x > eps) - (x < -eps);
}

typedef int poly_h;
typedef poly* poly_t;
typedef poly_term* term_t;

term_t tmp_terms[MAX_POLY_TERMS];
int compare(const void* a,const void *b){
    term_t p = *(term_t*)a;
    term_t q = *(term_t*)b;
    
    if(sgn(p->expo - q->expo) == 0) return 0;
    return (p->expo < q->expo ? -1 : 1);
}
void print_term(term_t t,int id){
    if(sgn(t->expo) == 0) {
        printf("%g",t->coeff);
        return;
    }
    if(sgn(t->coeff - 1)) printf("%g",t->coeff);
    printf("%s",symbolic_table[id]);
    if(sgn(t->expo - 1)) printf("^%g",t->expo);
}
int merge_terms(int n){
    int i = 0;
    int t = 0; //last usable pos
    while(i < n){
        int j = i;
        while(j < n && sgn(tmp_terms[j]->expo - tmp_terms[i]->expo) == 0) ++j;
        term_t cur_term = tmp_terms[i];
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
int duplicate_to_tmp(poly_t P){
    int t = 0;
    term_t root = P->root;
    while(root) tmp_terms[t++] = root, root = root->next;
    return t;
}
term_t dup_term(term_t a){
    term_t x = (term_t)malloc(sizeof(poly_term));
    *x = *a;
    return x;
}
void sort_poly(poly* P){
    int t = duplicate_to_tmp(P);
    qsort(tmp_terms,t,sizeof(term_t),compare);
    t = merge_terms(t);
    P->root = NULL;
    P->tail = NULL;
    if(t){
        P->root = tmp_terms[0];
        P->tail = tmp_terms[t-1];
    }
}
void add_poly_term_raw(poly* P,term_t term){
    if(!P->root){
        P->root = term;
        P->tail = term;
        return;
    }
    P->tail->next = term;
    P->tail = term;
}
term_t make_term(double coef,double exp){
    term_t term = (term_t)malloc(sizeof(poly_term));
    term->coeff = coef;
    term->expo = exp;
    term->next = NULL;
    return term;
}
void add_poly_term(poly_t P,double coef,double exp){
    add_poly_term_raw(P,make_term(coef,exp));
}
void print_poly(poly* p){
    poly_term* cur = p->root;
    while(cur != p->tail){
        print_term(cur,p->id);
        printf(cur->next->coeff < 0 ? "" : "+");
        cur = cur->next;
    }
    if(p->tail) print_term(p->tail,p->id);
    printf("\n");
}

poly* polynomials[MAX_SYMBOLS];
int current_poly_count = 0;

poly_t make_poly(int id){
    poly_t P = (poly_t)malloc(sizeof(poly));
    P->id = id;
    P->func = 0;
    P->root = P->tail = NULL;
    return P;
}
term_t mul_term(term_t a,term_t b){
    term_t ret = (poly_term*)malloc(sizeof(poly_term));
    ret->coeff = a->coeff * b->coeff;
    ret->expo = a->expo + b->expo;
    return ret;
}
poly_t mul(poly_t A,poly_t B){
    poly_t P = make_poly(A->id);
    term_t a = A->root;
    while(a){
        term_t b = B->root;
        while(b){
            term_t c = mul_term(a,b);
            add_poly_term_raw(P,c);
            b = b->next;
        }
        a = a->next;
    }
    sort_poly(P);
    return P;
}
poly_t mul_scalar(double c,poly_t A){
    poly_t P = make_poly(A->id);
    term_t a = A->root;
    if(a && sgn(c) == 0){
        add_poly_term(P,0,0);
        return P;
    }
    while(a){
        add_poly_term(P,c * a->coeff,a->expo);
        a = a->next;
    }
    return P;
}
poly_t add(poly_t A,poly_t B){
    poly_t P = make_poly(A->id);
    term_t a = A->root;
    term_t b = B->root;
    while(a) add_poly_term_raw(P,dup_term(a)), a = a->next;
    while(b) add_poly_term_raw(P,dup_term(b)), b = b->next;
    sort_poly(P);
    return P;
}
poly_t sub(poly_t A,poly_t B){
    poly_t P = make_poly(A->id);
    term_t a = A->root;
    term_t b = B->root;
    while(a) add_poly_term_raw(P,dup_term(a)), a = a->next;
    while(b) add_poly_term(P,-b->coeff,b->expo), b = b->next;
    sort_poly(P);
    return P;
}

poly_t poly_pow(poly_t P, int n) {
    poly_t result = make_poly(P->id);
    add_poly_term(result, 1.0, 0.0);
    for (int i = 0; i < n; ++i) {
        poly_t tmp = mul(result, P);
        result = tmp;
    }
    return result;
}

//return poly handle
poly_h add_poly(int id,int func){
    poly_t P = make_poly(id);
    P->func = func;
    polynomials[current_poly_count] = P;
    current_poly_count++;
    return current_poly_count - 1;
}
int get_size(poly_t A){
    int t = 0;
    term_t a = A->root;
    while(a) a = a->next,++t;
    return t;
}
#define MIN(x,y) (((x)) < ((y)) ? ((x)) : ((y)))

poly_t mod(poly_t A,int n){
    poly_t ret = make_poly(A->id);
    term_t a = A->root;
    while(a && a->expo < n) add_poly_term_raw(ret,dup_term(a)), a = a->next;
    return ret;
}

