#include "example_lib_cnode.h"

double add(double a, double b) {
    // some operations that require erl_interface.h
    ei_x_buff buf;
    ei_x_new(&buf);
    ei_x_free(&buf);
    return a + b;
}
