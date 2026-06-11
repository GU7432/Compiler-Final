#include <stdlib.h>
#include <stdio.h>
#include <math.h>

#include "FormalPowerSeries.h"

void main(){
    poly P = make_poly(5);
    P->a[0] = 1;
    P->a[1] = -1;
    poly A = inverse(P,P->size * 2);
    print_poly(mul(A,P));
    printf("\n");
}