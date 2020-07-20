#include "example_lib_nif.h"

int add(int a, int b) {
    some_nif_op();
    return a + b;
}

int sub(int a, int b) {
    some_nif_op();
    return a - b;
}

void some_nif_op() {
    // some operations that require erl_nif.h
    int *some_int_ptr = enif_alloc(sizeof(int));
    enif_free(some_int_ptr);
}
