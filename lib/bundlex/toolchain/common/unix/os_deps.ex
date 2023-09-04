defmodule Bundlex.Toolchain.Common.Unix.OSDeps do
  @moduledoc false

  require Logger
  alias Bundlex.Output

  @precompiled_path "#{Mix.Project.build_path()}/bundlex_precompiled/"

  @spec get_flags(Bundlex.Native.t(), atom()) :: String.t()
  def get_flags(native, flags_type) do
    native.os_deps
    |> Enum.flat_map(fn
      {:pkg_config, lib_names} ->
        get_flags_for_pkg_config(lib_names, flags_type, native.app)

      {precompiled_dependency_path, lib_names} ->
        get_flags_for_precompiled(
          {precompiled_dependency_path, lib_names},
          flags_type
        )
    end)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  defp parse_os_deps(os_deps) do
    Enum.map(os_deps, fn
      {precompiled_dependency, lib_name_or_names} ->
        lib_names = Bunch.listify(lib_name_or_names)
        {precompiled_dependency, lib_names}

      lib_name ->
        {:pkg_config, [lib_name]}
    end)
  end

  defp get_flags_for_precompiled(
         {{_precompiled_dependency_url, precompiled_dependency_path}, lib_names},
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

        ["-I#{full_include_path}"]

      true ->
        raise "Unknown flag type: #{inspect(flags_type)}"
    end
  end

  defp get_flags_for_pkg_config(lib_names, options, app) do
    options = options |> Bunch.listify() |> Enum.map(&"--#{&1}")
    do_get_flags_for_pkg_config(lib_names, options, app)
  end

  defp do_get_flags_for_pkg_config([], _options, _app), do: ""

  defp do_get_flags_for_pkg_config(lib_names, options, app) do
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
      case System.cmd("pkg-config", options ++ [lib_name], stderr_to_stdout: true) do
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

  @spec fetch_precompiled(Bundlex.Native.t()) :: Bundlex.Native.t()
  def fetch_precompiled(native) do
    os_deps =
      parse_os_deps(native.os_deps)
      |> Enum.map(fn
        {:pkg_config, lib_names} ->
          {:pkg_config, lib_names}

        {precompiled_dependency, lib_names} ->
          case maybe_download_precompiled_package(precompiled_dependency) do
            :unavailable ->
              # fallback
              {:pkg_config, lib_names}

            package_path ->
              {{precompiled_dependency, package_path}, lib_names}
          end
      end)

    %{native | os_deps: os_deps}
  end

  defp maybe_download_precompiled_package(precompiled_dependency_url) do
    File.mkdir_p(@precompiled_path)
    package_path = get_package_path(precompiled_dependency_url)

    cond do
      package_path == :unavailable ->
        :unavailable

      File.exists?(package_path) ->
        package_path

      true ->
        try do
          File.mkdir(package_path)
          temporary_destination = "#{@precompiled_path}/temporary"
          download(precompiled_dependency_url, temporary_destination)
          System.shell("tar -xf #{temporary_destination} -C #{package_path} --strip-components 1")
          System.shell("rm #{temporary_destination}")
          package_path
        rescue
          e ->
            Logger.warning("Couldn't download the dependency due to: #{inspect(e)}.")
            :unavailable
        end
    end
  end

  defp get_package_path(:unavailable), do: :unavailable

  defp get_package_path(url) do
    url = if String.ends_with?(url, "/"), do: String.slice(url, 0..-2), else: url

    last_part =
      String.split(url, "/")
      |> Enum.at(-1)
      |> String.split(".")
      |> Enum.reject(&(&1 in ["tar", "xz", "gz"]))
      |> Enum.join(".")

    "#{@precompiled_path}#{last_part}"
  end

  defp download(url, dest) do
    response = Req.get!(url)

    if response.status == 200 do
      File.write(dest, response.body)
    else
      :error
    end
  end
end
