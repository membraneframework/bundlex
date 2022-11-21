/** @file */

#include <erl_nif.h>
#include <example_lib/example_lib_nif.h>

/**
 * @brief NIF function to call the C function from the example_lib library.
 * Subtracts first element from itself.
 *
 * @param argc Unused.
 * @param argv Only the first element is used.
 * @return ERL_NIF_TERM
 */
static ERL_NIF_TERM export_bar(ErlNifEnv* env, int argc,
                               const ERL_NIF_TERM argv[]) {
  (void)argc;
  int a, b;
  enif_get_int(env, argv[0], &a);
  enif_get_int(env, argv[0], &b);
  return enif_make_int(env, sub(a, b));
}

static ErlNifFunc nif_funcs[] = {{"bar", 2, export_bar, 0}};

ERL_NIF_INIT(Elixir.ExampleTest.Bar.Nif, nif_funcs, NULL, NULL, NULL, NULL)
