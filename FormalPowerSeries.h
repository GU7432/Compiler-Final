
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>

#define mod 998244353
#define G 3
#define MAX(x,y) ((x) > (y) ? (x) : (y))
typedef long long i64;
typedef struct poly_t{
    i64 *a;
    int size;
} poly_t;

typedef poly_t* poly;
void resize(poly P,int _size){
    i64* tmp = (i64*)malloc(sizeof(i64) * _size);
    memset(tmp,0,sizeof(i64) * _size);
    if(P->size > _size) P->size = _size;
    for(int i = 0; i < P->size; ++i) tmp[i] = P->a[i];
    P->size = _size;
    P->a = tmp;
}
inline void swap(poly* a,poly *b){
    poly t = *a;
    *a = *b;
    *b = t;
}
poly make_poly(int size){
    poly p = (poly)malloc(sizeof(poly_t));
    p->size = 0;
    resize(p,size);
    return p;
}
poly dup_poly(poly a){
    poly P = make_poly(a->size);
    for(int i = 0; i < a->size;++i) P->a[i] = a->a[i];
    return P;
}
poly add(poly A,poly B){
    int n = MAX(A->size,B->size);
    poly P = make_poly(n);
    for(int i = 0; i < A->size; ++i) P->a[i] = A->a[i];
    for(int i = 0; i < B->size; ++i) (P->a[i] += B->a[i]),P->a[i] %= mod;
    return P;
}
poly mul_scalar(int a,poly A){
    int n = A->size;
    A = dup_poly(A);
    for(int i = 0; i < n; ++i) A->a[i] = a * A->a[i] % mod;
    return A;
}
poly sub(poly A,poly B){
    int n = MAX(A->size,B->size);
    poly P = make_poly(n);
    for(int i = 0; i < A->size; ++i) P->a[i] = A->a[i];
    for(int i = 0; i < B->size; ++i) (((P->a[i] -= B->a[i]),P->a[i] %= mod),P->a[i] += mod),P->a[i] %= mod;
    return P;
}
i64 power(i64 a, i64 b, i64 m) {
    i64 ret = 1;
    for (; b; b >>= 1, a = a * a % m)
        if (b & 1) ret = ret * a % m;
    return ret;
};
void swapi(i64 *a, i64 *b){
    i64 t = *a;
    *a = *b;
    *b = t;
}

#define __lg(x) ((64 - 1 - __builtin_clzll(x)))
#define M 998244353
#define root 3
#define Log 21
i64 e[Log + 1], ie[Log + 1];
void NTT() {
    //static_assert(__builtin_ctz(M - 1) >= Log);
    e[Log] = power(root, (M - 1) >> Log, M);
    ie[Log] = power(e[Log], M - 2, M);
    for (int i = Log - 1; i >= 0; i--) {
        e[i] = e[i + 1] * e[i + 1] % M;
        ie[i] = ie[i + 1] * ie[i + 1] % M;
    }
}
void ndft(poly p,int inv) {
    int n = p->size;
    i64* v = p->a;
    for (int i = 0, j = 0; i < n; i++) {
        if (i < j) swapi(&(v[i]), &(v[j]));
        for (int k = n / 2; (j ^= k) < k; k /= 2);
    }
    for (int m = 1; m < n; m *= 2) {
        i64 w = (inv ? ie : e)[__lg(m) + 1];
        for (int i = 0; i < n; i += m * 2) {
            i64 cur = 1;
            for (int j = i; j < i + m; j++) {
                i64 g = v[j], t = cur * v[j + m] % M;
                v[j] = (g + t) % M;
                v[j + m] = (g - t + M) % M;
                cur = cur * w % M;
            }
        }
    }
    if (inv) {
        i64 in = power(n, M - 2, M);
        for (int i = 0; i < n; i++) v[i] = v[i] * in % M;
    }
}

int bit_ceil(int n){
    int u = 1;
    while(u < n) u *= 2;
    return u;
}
poly convolution(poly f, poly g) {
	NTT();
    int n = f->size + g->size - 1;
    int len = bit_ceil(n);
    resize(f,len);
    resize(g,len);
    ndft(f, 0), ndft(g, 0);
    for (int i = 0; i < len; i++) {
        (f->a[i] *= g->a[i]);
        f->a[i] %= M;
    }
    ndft(f, 1);
    resize(f,n);
    return f;
}
#undef M
#undef root
#undef Log
i64 inv(i64 a){
    return power(a,mod-2,mod);
}
poly mul(poly A,poly B){
    A = dup_poly(A);
    B = dup_poly(B);
    return convolution(A,B);
}
poly modulo(poly A,int n){
    A = dup_poly(A);
    resize(A,n);
    return A;
}
//Newton method
poly inverse(poly A,int n){
    int tn = 1;
    poly Q = make_poly(tn);
    poly p2 = make_poly(1);
    p2->a[0] = 2;
    Q->a[0] = inv(A->a[0]);
    while(tn < n){
        tn *= 2;
        Q = mul(Q,(sub(p2,mul(modulo(A,tn),modulo(Q,tn)))));
        Q = modulo(Q,tn);
    }
    return Q;
}

poly poly_pow(poly A,int n){
    poly P = dup_poly(A);
    for(int i = 0; i < n - 1; ++i){
        P = mul(P,A);
    }
    return P;
}
void print_poly(poly A){
    if(!A) return;
    if(A->size == 1){
        printf("%lld",A->a[0]);
        return;
    }
    for(int i = 0; i < A->size; ++i){
        if(A->a[i] == 0) continue;
        if(i == 0) printf("%lld",A->a[i]);
        else if(A->a[i] != 1) printf("%lld",A->a[i]);
        
        if(i == 1){
            printf("x");
        }else if(i){
            printf("x^%d",i);
        }
        printf(i == A->size - 1 || (i < A->size - 1 && A->a[i + 1] == 0) ? "" : "+");
    }
    printf("\n");
}