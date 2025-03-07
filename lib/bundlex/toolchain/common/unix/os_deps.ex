defmodule Bundlex.Toolchain.Common.Unix.OSDeps do
  @moduledoc false

  require Logger
  alias Bundlex.Output

  @spec resolve_os_deps(Bundlex.Native.t()) :: Bundlex.Native.t()
  def resolve_os_deps(native) do
    {cflags_list, libs_list} =
      native.os_deps
      |> Enum.map(&handle_old_api(native.name, &1))
      |> Enum.map(fn {name, providers} ->
        resolve_os_dep(name, native.app, Bunch.listify(providers), native, [])
      end)
      |> Enum.unzip()

    compiler_flags = cflags_list |> List.flatten() |> Enum.uniq()
    libs_flags = libs_list |> List.flatten() |> Enum.uniq()

    %{
      native
      | compiler_flags: native.compiler_flags ++ compiler_flags,
        linker_flags: native.linker_flags ++ libs_flags
    }
  end

  defp handle_old_api(native_name, entry) do
    is_old_api =
      case entry do
        {:pkg_config, value} ->
          is_binary(value) or (is_list(value) and value != [] and Enum.all?(value, &is_binary/1))

        {name, _providers} when is_atom(name) ->
          false

        {_providers, _lib_names} ->
          true
      end

    if is_old_api do
      Output.warn("""
      Native #{inspect(native_name)} uses deprecated syntax for `os_deps`. \
      See `Bundlex.Project.os_dep` for the new syntax.
      """)

      {providers, lib_names} = entry

      name = lib_names |> Bunch.listify() |> Enum.join("_") |> String.to_atom()

      providers =
        providers
        |> Bunch.listify()
        |> Enum.map(fn
          {:precompiled, url} -> {:precompiled, url, lib_names}
          :pkg_config -> {:pkg_config, lib_names}
        end)

      {name, providers}
    else
      entry
    end
  end

  defp resolve_os_dep(name, app, [], _native, []) do
    Output.raise("""
    Couldn't load OS dependency #{inspect(name)} of package #{app}, \
    because no providers were specified. \
    Make sure to follow installation instructions that may be available in the readme of #{app}.
    """)
  end

  defp resolve_os_dep(name, app, [], _native, errors) do
    Output.raise("""
    Couldn't load OS dependency #{inspect(name)} of package #{app}. \
    Make sure to follow installation instructions that may be available in the readme of #{app}.

    Tried the following providers:

    #{errors |> Enum.reverse() |> Enum.join("\n")}
    """)
  end

  defp resolve_os_dep(name, app, [provider | providers], native, errors) do
    case resolve_os_dep_provider(name, provider, native) do
      {:ok, cflags, libs} ->
        {cflags, libs}

      {:skip, reason} ->
        resolve_os_dep(name, app, providers, native, [
          "Provider `#{inspect(provider)}` #{reason}" | errors
        ])

      {:error, reason} ->
        warn_provider_change(reason, provider, providers)

        resolve_os_dep(name, app, providers, native, [
          "Provider `#{inspect(provider)}` #{reason}" | errors
        ])
    end
  end

  defp resolve_os_dep_provider(name, :pkg_config, native) do
    resolve_os_dep_provider(name, {:pkg_config, "#{name}"}, native)
  end

  defp resolve_os_dep_provider(_name, {:pkg_config, pkg_configs}, _native) do
    pkg_configs = Bunch.listify(pkg_configs)

    with {:ok, cflags} <- get_flags_from_pkg_config(pkg_configs, :cflags),
         {:ok, libs} <- get_flags_from_pkg_config(pkg_configs, :libs) do
      {:ok, cflags, libs}
    end
  end

  defp resolve_os_dep_provider(name, {:precompiled, url}, native) do
    resolve_os_dep_provider(name, {:precompiled, url, "#{name}"}, native)
  end

  defp resolve_os_dep_provider(name, {:precompiled, url, lib_names}, native) do
    is_precompiled_disabled =
      case Application.get_env(:bundlex, :disable_precompiled_os_deps, false) do
        bool when is_boolean(bool) -> bool
        [apps: apps] when is_list(apps) -> native.app in apps
      end

    if is_precompiled_disabled do
      {:skip,
       """
       is disabled in the application configuration, check the config.exs file.
       """}
    else
      lib_names = Bunch.listify(lib_names)

      with {:ok, dep_dir_name, dep_path} <- maybe_download_precompiled_package(name, url) do
        {:ok, get_precompiled_cflags(dep_path),
         get_precompiled_libs_flags(dep_path, dep_dir_name, lib_names, native)}
      end
    end
  end

  defp get_precompiled_libs_flags(dep_path, logical_dep_dir_name, lib_names, native) do
    lib_path = Path.join(dep_path, "lib")
    logical_output_path = Bundlex.Toolchain.output_path(native.app, native.interface)
    create_relative_symlink_or_copy(lib_path, logical_output_path, logical_dep_dir_name)

    # TODO: pass the platform via arguments
    # $ORIGIN must be escaped so that it's not treated as an ENV variable
    rpath_root =
      case Bundlex.get_target() do
        %{os: "darwin" <> _rest} -> "@loader_path"
        %{os: "linux"} -> "\\$ORIGIN"
        %{os: _other} -> ""
      end

    [
      "-L#{Path.join(dep_path, "lib")}",
      "-Wl,-rpath,#{rpath_root}/#{logical_dep_dir_name}",
      "-Wl,-rpath,/opt/homebrew/lib"
    ] ++ Enum.map(lib_names, &"-l#{remove_lib_prefix(&1)}")
  end

  defp get_precompiled_cflags(dep_path) do
    ["-I#{Path.join(dep_path, "include")}"]
  end

  defp get_flags_from_pkg_config(pkg_configs, flags_type) do
    try do
      flags_type = "--#{flags_type}"
      System.put_env("PATH", System.get_env("PATH", "") <> ":/usr/local/bin:/opt/homebrew/bin")

      case System.cmd("which", ["pkg-config"]) do
        {_path, 0} ->
          :ok

        {_path, _error} ->
          raise BundlexError, """
          pkg-config not found. Bundlex needs pkg-config to find packages in system.
          On Mac OS, you can install pkg-config via Homebrew by typing `brew install pkg-config`.
          """
      end

      pkg_configs
      |> Enum.map(fn pkg_config ->
        case System.cmd("pkg-config", [flags_type, pkg_config], stderr_to_stdout: true) do
          {output, 0} ->
            String.trim_trailing(output)

          {output, error} ->
            raise BundlexError, """
            pkg-config error:
            Code: #{error}
            #{output}
            """
        end
      end)
      |> then(&{:ok, &1})
    rescue
      e ->
        error = """
        couldn't load #{inspect(pkg_configs)} libraries with pkg-config due to:
        #{format_exception(e)}
        """

        {:error, error}
    end
  end

  defp remove_lib_prefix("lib" <> libname), do: libname
  defp remove_lib_prefix(libname), do: libname

  defp maybe_download_precompiled_package(_name, nil) do
    {:error, "ignored, no URL provided"}
  end

  defp maybe_download_precompiled_package(name, url) do
    precompiled_path = Path.join(Bundlex.Toolchain.bundlex_shared_path(), "precompiled")
    File.mkdir_p!(precompiled_path)
    package_dir_name = Zarex.sanitize(url)
    package_path = Path.join(precompiled_path, package_dir_name)

    if File.exists?(package_path) do
      {:ok, package_dir_name, package_path}
    else
      File.mkdir!(package_path)

      try do
        temporary_destination = Path.join(precompiled_path, "temporary")
        download(url, temporary_destination)

        {_output, 0} =
          System.shell("tar -xf #{temporary_destination} -C #{package_path} --strip-components 1")

        File.rm!(temporary_destination)
        {:ok, package_dir_name, package_path}
      rescue
        e ->
          File.rm_rf!(package_path)

          error = """
          couldn't download and extract the precompiled dependency #{inspect(name)} due to:
          #{format_exception(e)}
          """

          {:error, error}
      end
    end
  end

  defp download(url, dest) do
    response = Req.get!(url)

    case response.status do
      200 ->
        File.write!(dest, response.body)

      _other ->
        raise BundlexError, """
        Cannot download file from #{url}
        Response status: #{response.status}
        """
    end
  end

  defp format_exception(exception) do
    Exception.format(:error, exception)
    |> String.trim()
    |> String.replace(~r/^/m, "\t")
  end

  defp create_relative_symlink_or_copy(target, dir, name) do
    link = Path.join(dir, name)

    unless File.exists?(link) do
      File.mkdir_p!(dir)
      # If the `priv` directory is symlinked by `mix`
      # we cannot reliably create a relative symlink
      # that would work in all cases, including releases,
      # thus we make a copy instead.
      {dir_physical, realpath_result} = System.shell("realpath #{dir} 2>/dev/null")
      dir_physical = String.trim(dir_physical)

      if realpath_result == 0 and dir_physical == dir do
        File.ln_s(path_from_to(dir, target), link)
      else
        File.mkdir_p!(link)
        File.cp_r!(target, link)
      end
    end

    :ok
  end

  defp path_from_to(from, to) do
    from = Path.expand(from) |> Path.split()
    to = Path.expand(to) |> Path.split()

    longest_common_prefix =
      Enum.zip(from, to)
      |> Enum.take_while(fn {from, to} -> from == to end)
      |> Enum.count()

    Path.join(
      Bunch.Enum.repeated("..", Enum.count(from) - longest_common_prefix) ++
        Enum.drop(to, longest_common_prefix)
    )
  end

  # pkg_config .pc name can differ on different systems/vendors
  # no warning is emited if next provider is same type, example:
  # {:pkg_config, "SDL2"},
  # {:pkg_config, "sdl2"}
  defp warn_provider_change(reason, provider, [next_provider | _]) do
    if provider_type(provider) !== provider_type(next_provider) do
      Output.warn("""
      Couldn't load OS dependency using #{inspect(provider)}

      #{reason}

      Loading using #{inspect(next_provider)}
      """)
    end
  end

  defp warn_provider_change(_reason, _provider, _providers), do: nil

  defp provider_type(provider) when is_atom(provider), do: provider
  defp provider_type(provider), do: elem(provider, 0)
end
