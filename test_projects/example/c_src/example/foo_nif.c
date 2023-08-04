/** @file */

#include <erl_nif.h>
#include <example_lib/example_lib_nif.h>

#include <libswscale/swscale.h>

typedef struct State
{
  struct SwsContext *sws_context;
  int width, height;
  enum AVPixelFormat src_format, dst_format;

  uint8_t *src_data[4], *dst_data[4];
  int src_linesize[4], dst_linesize[4];

  int dst_image_size;
} State;

/**
 * @brief NIF function to call the C function from the example_lib library. Adds
 * first element to itself.
 *
 * @param argc Unused.
 * @param argv Only the first element is used.
 * @return ERL_NIF_TERM
 */
static ERL_NIF_TERM export_foo(ErlNifEnv *env, int argc,
                               const ERL_NIF_TERM argv[])
{
  (void)argc;
  int a, b;
  enif_get_int(env, argv[0], &a);
  enif_get_int(env, argv[0], &b);
  return enif_make_int(env, add(a, b));
}

static ErlNifFunc nif_funcs[] = {{"foo", 2, export_foo, 0}};

ERL_NIF_INIT(Elixir.ExampleTest.Foo.Nif, nif_funcs, NULL, NULL, NULL, NULL)
