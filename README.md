# Bundlex

Bundlex is a multi-platform tool for compiling C code along with elixir projects, for use in NIFs. The tool provides also convenient way of loading compiled NIFs in elixir modules.

## Instalation

To install, you need to configure Mix project as follows:

```elixir
defmodule MyApp.Mixfile do
  use Mix.Project
  # Addition of below line is required until https://github.com/elixir-lang/elixir/issues/7561 is fixed
  Application.put_env(:bundlex, :my_app, __ENV__)

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
      {:bundlex, git: "git@github.com:radiokit/bundlex.git"} # add bundlex to deps
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
      nif: nif(Bundlex.platform)
    ]
  end

  defp nif(:linux) do
    [
      my_nif: [
        sources: ["something.c", "for_linux_only.c"]
      ]
    ]
  end

  defp nif(_platform) do
    [
      my_nif: [
        sources: ["something.c", "multiplatform.c"]
      ]
    ]
  end
end
```

The sources should reside in `project_root/c_src/my_app` directory.

Besides the `sources` key, also other options are supported, for full list see documentation for `Budnex.Project.nif_config_t` type.

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
