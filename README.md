# Bundlex

[![Build Status](https://travis-ci.com/membraneframework/bundlex.svg?branch=master)](https://travis-ci.com/membraneframework/bundlex)

Bundlex is a multi-platform tool for compiling C code along with elixir projects, for use in NIFs. The tool provides also convenient way of loading compiled NIFs in elixir modules.

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

### Adding NIFs to project

Adding C sources can be done in `project/0` function of bundlex project module in the following way:

```elixir
defmodule MyApp.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      nifs: nifs(Bundlex.platform)
    ]
  end

  defp nifs(:linux) do
    [
      my_nif: [
        sources: ["something.c", "linux_specific.c"]
      ],
      my_other_nif: [
        ...
      ]
    ]
  end

  defp nifs(_platform) do
    [
      my_nif: [
        sources: ["something.c", "multiplatform.c"]
      ],
      my_other_nif: [
        ...
      ]
    ]
  end
end
```

The sources should reside in `project_root/c_src/my_app` directory.

Configuration of each NIF can contain following options:
* `sources` - C files to be compiled (at least one must be provided),
* `includes` - Paths to look for header files (empty list by default).
* `libs` - Names of libraries to link (empty list by default).
* `pkg_configs` - Names of libraries that should be linked with pkg config (empty list by default).
* `deps` - Dependencies in the form `{app_name, nif_name}`, where `app_name` is the application name of the dependency, and `nif_name` is the name of nif specified in bundlex file of this dependency. Sources, includes,
libs and pkg_configs from those nifs will be appended. Empty list by default.
* `export_only?` - Flag specifying whether NIF is only to be added as dependency and should not be compiled itself. `false` by default.
* `src_base` - Native files should reside in `project_root/c_src/<src_base>`.
Current app name by default.

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
