# Bundlex

[![Hex.pm](https://img.shields.io/hexpm/v/bundlex.svg)](https://hex.pm/packages/bundlex)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/bundlex/)
[![CircleCI](https://circleci.com/gh/membraneframework/bundlex.svg?style=svg)](https://circleci.com/gh/membraneframework/bundlex)

Bundlex is a multi-platform tool for compiling C code along with elixir projects, for use in NIFs, CNodes and Ports. The tool provides also convenient way of accessing compiled code in elixir modules.

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
      deps: deps(),
      # ...
   ]
  end

  defp deps() do
    [
      {:bundlex, "~> 3.0"} # add bundlex to deps
    ]
  end
end
```

and create `bundlex.exs` file in the project root folder, containing Bundlex project module:

```elixir
defmodule Membrane.Element.Mad.BundlexProject do
  use Bundlex.Project

  def project() do
    []
  end
end
```

Now your project does not contain any C sources, but should compile successfully, and some Bundlex messages should be printed while compilation proceeds.

## Usage

### Adding natives to project

Adding natives can be done in `project/0` function of Bundlex project module in the following way:

```elixir
defmodule MyApp.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives(Bundlex.platform),
      libs: libs()
    ]
  end

  defp natives(:linux) do
    [
      my_native: [
        sources: ["something.c", "linux_specific.c"],
        interface: :nif
      ],
      my_other_native: [
        sources: ["something_other.c", "linux_specific.c"],
        interface: :cnode
      ],
      my_other_native: [
        sources: ["something_more_other.c", "linux_specific.c"],
        interface: :port
      ]
    ]
  end

  defp natives(_platform) do
    [
      my_native: [
        sources: ["something.c", "multiplatform.c"],
        interface: :nif
      ],
      my_other_native: [
        sources: ["something_other.c", "multiplatform.c"],
        interface: :cnode
      ],
      my_other_native: [
        sources: ["something_more_other.c", "multiplatform.c"],
        interface: :port
      ]
    ]
  end

  defp libs() do
    [
      my_lib: [
        sources: ["something.c"],
        interface: :nif
      ],
      my_lib: [
        sources: ["something_other.c"],
        interface: :cnode
      ]
    ]
  end
end
```

As we can see, we can specify two types of resources:
- natives - code implemented in C that will be used within Elixir code
- libs - can be used by other resources as dependencies (see `deps` option below)

The sources should reside in `project_root/c_src/my_app` directory (this can be changed with `src_base` option, see below).

Configuration of each native may contain following options:
* `sources` - C files to be compiled (at least one must be provided),
* `includes` - Paths to look for header files (empty list by default).
* `lib_dirs` - Absolute paths to look for libraries (empty list by default).
* `libs` - Names of libraries to link (empty list by default).
* `pkg_configs` - Names of libraries for which the appropriate flags will be
obtained using pkg-config (empty list by default).
* `deps` - Dependencies in the form of `{app, lib_name}`, where `app`
is the application name of the dependency, and `lib_name` is the name of lib
specified in Bundlex project of this dependency.
* `src_base` - Native files should reside in `project_root/c_src/<src_base>`
(application name by default).
* `compiler_flags` - Custom flags for compiler.
* `linker_flags` - Custom flags for linker.
* `language` - Language of native. `:c` or `:cpp` may be chosen (`:c` by default)
* `interface` - Interface used to integrate with Elixir code. There are three interfaces available:
    * :nif - dynamically linked to the Erlang VM (see [Erlang docs](http://erlang.org/doc/man/erl_nif.html))
    * :cnode - executed as separate OS processes, accessed through sockets (see [Erlang docs](http://erlang.org/doc/man/ei_connect.html))
    * :port - executed as separate OS processes (see [Elixir Port docs](https://hexdocs.pm/elixir/Port.html))
* `preprocessors` - Modules that will preprocess the native, see `Bundlex.Project.Preprocessor`.

Note that we can specify multiple resources with the same name and different interfaces.
It is especially useful when we want to have library that can work both with CNodes and NIFs. 
When we include such library in `deps` Bundlex will automatically import proper version of it.

### Compilation options

The following command line arguments can be passed:
- `--store-scripts` - if set, shell scripts are stored in the project
root folder for further analysis.

### Loading NIFs in modules

NIFs compiled with Bundlex can be loaded the same way as any other NIFs (see [`:erlang.load_nif/2`](http://erlang.org/doc/man/erlang.html#load_nif-2)), but Bundlex provides `Bundlex.Loader` module to save you some boilerplate:

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

### Interacting with CNodes

As in case of NIFs, CNodes compiled with Bundlex can be used like any other CNodes (see built-in `Node` module), while some useful stuff for interacting with them is provided. `Bundlex.CNode` module contains utilities that make it easier to spawn and control CNodes, and allow to treat them more like usual Elixir processes. Check out documentation for more details.

### Interacting with Ports

Similarly to CNodes Bundlex provides `Bundlex.Port` module for a little easier interacting with Ports.
Please refer to module's documentation to see how to use it.

## More examples

More advanced examples can be found in our [test_projects](https://github.com/membraneframework/bundlex/tree/master/test_projects)
or in our [repositories](https://github.com/membraneframework) where we use Bundlex e.g. in [Unifex](https://github.com/membraneframework/unifex).

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
