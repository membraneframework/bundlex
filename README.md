# Bundlex

[![Build Status](https://travis-ci.com/membraneframework/bundlex.svg?branch=master)](https://travis-ci.com/membraneframework/bundlex)

Bundlex is a multi-platform tool for compiling C code along with elixir projects, for use in NIFs and CNodes. The tool provides also convenient way of accessing compiled code in elixir modules.

This tool is a part of [Membrane Framework](https://membraneframework.org/)

## Instalation

To install, you need to configure Mix project as follows:

```elixir
defmodule MyApp.Mixfile do
  use Mix.Project

  def project do
    [
      app: :my_app,
      compilers: [:bundlex] ++ Mix.compilers, # add bundlex to compilers
      ...,
      deps: deps()
   ]
  end

  defp deps() do
    [
      {:bundlex, "~> 0.1"} # add bundlex to deps
    ]
  end
end
```

and create `bundlex.exs` file in the project root folder, containing bundlex project module:

```elixir
defmodule Membrane.Element.Mad.BundlexProject do
  use Bundlex.Project

  def project() do
    []
  end
end
```

Now your project does not contain any C sources, but should compile successfully, and some bundlex messages should be printed while compilation proceeds.

## Usage

### Adding natives to project

Adding natives can be done in `project/0` function of bundlex project module in the following way:

```elixir
defmodule MyApp.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      nifs: nifs(Bundlex.platform),
      CNodes: CNodes(),
      libs: libs()
    ]
  end

  defp nifs(:linux) do
    [
      my_nif: [
        sources: ["something.c", "linux_specific.c"]
      ],
      my_other_nif: [
        # ...
      ]
    ]
  end

  defp nifs(_platform) do
    [
      my_nif: [
        sources: ["something.c", "multiplatform.c"]
      ],
      my_other_nif: [
        # ...
      ]
    ]
  end

  defp CNodes() do
    [
      my_cnode: [
        sources: ["something.c", "something_other.c"]
      ],
      my_other_cnode: [
        # ...
      ]
    ]
  end

  defp libs(_platform) do
    [
      my_lib: [
        sources: ["something.c", "something_other.c"]
      ],
      my_other_lib: [
        # ...
      ]
    ]
  end
end
```

As we can see, there are three types of natives:
- NIFs - dynamically linked to the Erlang VM (see [Erlang docs](http://erlang.org/doc/man/erl_nif.html))
- CNodes - executed as separate OS processes, accessed through sockets (see [Erlang docs](http://erlang.org/doc/man/ei_connect.html))
- libs - can be used by other natives as dependencies (see `deps` option below)

The sources should reside in `project_root/c_src/my_app` directory (this can be changed with `src_base` option, see below).

Configuration of each native may contain following options:
* `sources` - C files to be compiled (at least one must be provided),
* `includes` - Paths to look for header files (empty list by default).
* `libs_dirs` - Paths to look for libraries (empty list by default).
* `libs` - Names of libraries to link (empty list by default).
* `pkg_configs` - Names of libraries for which the appropriate flags will be
obtained using pkg-config (empty list by default).
* `deps` - Dependencies in the form of `{app, lib_name}`, where `app`
is the application name of the dependency, and `lib_name` is the name of lib
specified in bundlex project of this dependency.
* `src_base` - Native files should reside in `project_root/c_src/<src_base>`
(application name by default).

### Compilation options

Setting env variable `BUNDLEX_STORE_BUILD_SCRIPTS=true` makes bundlex store build
scripts (`bundlex.sh`/`bundlex.bat`) in projects root folders for analysis.

### Loading NIFs in modules

Loading NIF in a module is depicted below:

```elixir
defmodule MyApp.SomeNativeStuff do
  use Bundlex.Loader, nif: :my_nif

  def normal_function(a, b, c, d) do
    private_native_function(a+b, c+d)
  end

  defnif native_function(a, b)

  defnifp private_native_function(x, y)

end
```

Note that unlike when using `:erlang.load_nif/2`, here `def`s and `defp`s can be used to create usual functions, native ones are declared with `defnif` and `defnifp`. This is achieved by creating a new module under the hood, and that is why module passed to C macro `ERL_NIF_INIT` has to be succeeded by `.Nif`, i.e.
```C
ERL_NIF_INIT(MyApp.SomeNativeStuff.Nif, funs, load, NULL, upgrade, unload)
```

In spite of this, any native erlang macros and functions shall be used as usual, as described at http://erlang.org/doc/man/erl_nif.html

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://membraneframework.github.io/static/logo/swm_logo_readme.png)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
