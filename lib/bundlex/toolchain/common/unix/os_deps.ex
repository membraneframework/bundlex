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
        resolve_os_dep(name, native.app, Bunch.listify(providers), [])
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
      IO.warn("""
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

  defp resolve_os_dep(name, app, [], []) do
    Output.raise("""
    Couldn't load OS dependency #{inspect(name)} of package #{app}, \
    because no providers were specified. \
    Make sure to follow installation instructions that may be available in the readme of #{app}.
    """)
  end

  defp resolve_os_dep(name, app, [], errors) do
    Output.raise("""
    Couldn't load OS dependency #{inspect(name)} of package #{app}. \
    Make sure to follow installation instructions that may be available in the readme of #{app}.

    Tried the following providers:

    #{errors |> Enum.reverse() |> Enum.join("\n")}
    """)
  end

  defp resolve_os_dep(name, app, [provider | providers], errors) do
    case resolve_os_dep_provider(name, provider) do
      {:ok, cflags, libs} ->
        {cflags, libs}

      {:error, reason} ->
        resolve_os_dep(name, app, providers, [
          "Provider `#{inspect(provider)}` #{reason}" | errors
        ])
    end
  end

  defp resolve_os_dep_provider(name, :pkg_config) do
    resolve_os_dep_provider(name, {:pkg_config, "#{name}"})
  end

  defp resolve_os_dep_provider(_name, {:pkg_config, pkg_configs}) do
    pkg_configs = Bunch.listify(pkg_configs)

    with {:ok, cflags} <- get_flags_from_pkg_config(pkg_configs, :cflags),
         {:ok, libs} <- get_flags_from_pkg_config(pkg_configs, :libs) do
      {:ok, cflags, libs}
    end
  end

  defp resolve_os_dep_provider(name, {:precompiled, url}) do
    resolve_os_dep_provider(name, {:precompiled, url, "#{name}"})
  end

  defp resolve_os_dep_provider(name, {:precompiled, url, lib_names}) do
    lib_names = Bunch.listify(lib_names)

    with {:ok, package_path} <-
           maybe_download_precompiled_package(name, url) do
      {:ok, get_flags_for_precompiled(package_path, lib_names, :cflags),
       get_flags_for_precompiled(package_path, lib_names, :libs)}
    end
  end

  defp get_precompiled_path(), do: "#{Mix.Project.build_path()}/bundlex_precompiled/"

  defp get_flags_for_precompiled(precompiled_dependency_path, lib_names, :libs) do
    full_packages_library_path = Path.absname("#{precompiled_dependency_path}/lib")

    [
      "-L#{full_packages_library_path}",
      "-Wl,-rpath,#{full_packages_library_path}"
    ] ++
      Enum.map(lib_names, &"-l#{remove_lib_prefix(&1)}")
  end

  defp get_flags_for_precompiled(precompiled_dependency_path, _lib_names, :cflags) do
    full_include_path = Path.absname("#{precompiled_dependency_path}/include")
    ["-I#{full_include_path}"]
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
        {:error,
         """
         couldn't load #{inspect(pkg_configs)} libraries with pkg-config due to:
         #{format_exception(e)}
         """}
    end
  end

  defp remove_lib_prefix("lib" <> libname), do: libname
  defp remove_lib_prefix(libname), do: libname

  defp maybe_download_precompiled_package(_name, nil) do
    {:error, "ignored, no URL provided"}
  end

  defp maybe_download_precompiled_package(name, url) do
    precompiled_path = get_precompiled_path()
    File.mkdir_p!(precompiled_path)
    package_path = "#{precompiled_path}#{Zarex.sanitize(url)}"

    if File.exists?(package_path) do
      {:ok, package_path}
    else
      File.mkdir!(package_path)

      try do
        temporary_destination = "#{get_precompiled_path()}/temporary"
        download(url, temporary_destination)

        {_output, 0} =
          System.shell("tar -xf #{temporary_destination} -C #{package_path} --strip-components 1")

        File.rm!(temporary_destination)
        {:ok, package_path}
      rescue
        e ->
          File.rm_rf!(package_path)

          {:error,
           """
           couldn't download and extract the precompiled dependency #{inspect(name)} due to:
           #{format_exception(e)}
           """}
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
end
