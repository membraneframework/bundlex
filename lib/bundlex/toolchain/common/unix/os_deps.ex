defmodule Bundlex.Toolchain.Common.Unix.OSDeps do
  @moduledoc false

  require Logger
  alias Bundlex.Output

  @spec resolve_os_deps(Bundlex.Native.t()) :: Bundlex.Native.t()
  def resolve_os_deps(native) do
    {cflags_list, libs_list} =
      native.os_deps
      |> Enum.map(fn {provider_or_providers, lib_name_or_names} ->
        providers = Bunch.listify(provider_or_providers)
        lib_names = Bunch.listify(lib_name_or_names)

        resolve_single_os_dep(providers, lib_names, native.app)
      end)
      |> Enum.unzip()
      |> then(&{List.flatten(elem(&1, 0)), List.flatten(elem(&1, 1))})

    compiler_flags =
      Enum.uniq(cflags_list)

    libs_flags =
      Enum.uniq(libs_list)

    %{
      native
      | compiler_flags: native.compiler_flags ++ compiler_flags,
        linker_flags: native.linker_flags ++ libs_flags
    }
  end

  defp resolve_single_os_dep([], lib_names, _app) do
    raise "Couldn't load OS dependencies for libraries: #{inspect(lib_names)}."
  end

  defp resolve_single_os_dep(providers, lib_names, app) do
    [first_provider | rest_of_providers] = providers

    case first_provider do
      nil ->
        resolve_single_os_dep(rest_of_providers, lib_names, app)

      :pkg_config ->
        try do
          {get_flags_for_pkg_config(lib_names, :cflags, app),
           get_flags_for_pkg_config(lib_names, :libs, app)}
        rescue
          e ->
            IO.warn(
              "Couldn't load #{inspect(lib_names)} libraries with pkg-config due to: #{inspect(e)}."
            )

            resolve_single_os_dep(rest_of_providers, lib_names, app)
        end

      {:precompiled, precompiled_dependency_url} ->
        case maybe_download_precompiled_package(precompiled_dependency_url) do
          :unavailable ->
            resolve_single_os_dep(rest_of_providers, lib_names, app)

          package_path ->
            {get_flags_for_precompiled({{:precompiled, package_path}, lib_names}, :cflags),
             get_flags_for_precompiled({{:precompiled, package_path}, lib_names}, :libs)}
        end
    end
  end

  defp get_precompiled_path(), do: "#{Mix.Project.build_path()}/bundlex_precompiled/"

  defp get_flags_for_precompiled(
         {{:precompiled, precompiled_dependency_path}, lib_names},
         flags_type
       ) do
    case flags_type do
      :libs ->
        full_packages_library_path = Path.absname("#{precompiled_dependency_path}/lib")

        [
          "-L#{full_packages_library_path}",
          "-Wl,-rpath,#{full_packages_library_path}"
        ] ++
          Enum.map(lib_names, &"-l#{remove_lib_prefix(&1)}")

      :cflags ->
        full_include_path = Path.absname("#{precompiled_dependency_path}/include")
        "-I#{full_include_path}"
    end
  end

  defp get_flags_for_pkg_config(lib_names, flags_type, app) do
    flags_type = "--#{flags_type}"
    System.put_env("PATH", System.get_env("PATH", "") <> ":/usr/local/bin:/opt/homebrew/bin")

    case System.cmd("which", ["pkg-config"]) do
      {_path, 0} ->
        :ok

      {_path, _error} ->
        Output.raise("""
        pkg-config not found. Bundlex needs pkg-config to find packages in system.
        On Mac OS, you can install pkg-config via Homebrew by typing `brew install pkg-config`.
        """)
    end

    Enum.map(lib_names, fn lib_name ->
      case System.cmd("pkg-config", [flags_type, lib_name], stderr_to_stdout: true) do
        {output, 0} ->
          String.trim_trailing(output)

        {output, error} ->
          Output.raise("""
          Couldn't find system library #{lib_name} with pkg-config. Check whether it's installed.
          Installation instructions may be available in the readme of package #{app}.
          Output from pkg-config:
          Error: #{error}
          #{output}
          """)
      end
    end)
  end

  defp remove_lib_prefix("lib" <> libname), do: libname
  defp remove_lib_prefix(libname), do: libname

  defp maybe_download_precompiled_package(precompiled_dependency_url) do
    get_precompiled_path() |> File.mkdir_p!()
    package_path = get_package_path(precompiled_dependency_url)

    cond do
      package_path == :unavailable ->
        :unavailable

      File.exists?(package_path) ->
        package_path

      true ->
        File.mkdir!(package_path)

        try do
          temporary_destination = "#{get_precompiled_path()}/temporary"
          download(precompiled_dependency_url, temporary_destination)

          {_output, 0} =
            System.shell(
              "tar -xf #{temporary_destination} -C #{package_path} --strip-components 1"
            )

          File.rm!(temporary_destination)
          package_path
        rescue
          e ->
            IO.warn("Couldn't download the dependency due to: #{inspect(e)}.")
            :unavailable
        end
    end
  end

  defp get_package_path(:unavailable), do: :unavailable

  defp get_package_path(url) do
    "#{get_precompiled_path()}#{Zarex.sanitize(url)}"
  end

  defp download(url, dest) do
    response = Req.get!(url)

    case response.status do
      200 -> File.write!(dest, response.body)
      _other -> raise "Cannot download file from #{url}. Repsonse status: #{response.status}"
    end
  end
end
