#include <erl_nif.h>
#include <example_lib/example_lib_nif.h>

static ERL_NIF_TERM export_bar(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    (void)argc;
    int a, b;
    enif_get_int(env, argv[0], &a);
    enif_get_int(env, argv[0], &b);
    return enif_make_int(env, sub(a, b));
}

static ErlNifFunc nif_funcs[] =
{
    {"bar", 2, export_bar, 0}
};

ERL_NIF_INIT(Elixir.ExampleTest.Bar.Nif, nif_funcs, NULL, NULL, NULL, NULL)
