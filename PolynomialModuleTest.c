#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "PolynomialModule.h"

void main(){
    poly_h handle = add_poly(0,0);
    for(int i = 0; i < 10; ++i){
        add_poly_term(polynomials[handle],1,i/2);
    }
    add_poly_term(polynomials[handle],0,100);
    add_poly_term(polynomials[handle],0,100);
    print_poly(polynomials[handle]);
    poly_t P = polynomials[handle];
    sort_poly(P);
    print_poly(polynomials[handle]);
}