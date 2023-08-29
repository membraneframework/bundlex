defmodule Bundlex.OSDeps do
  alias Bundlex.Output

  @precompiled_path "_build/#{Mix.env()}/precompiled/"

  def get_flags(native, flags_type) do
    parse_os_deps(native.os_deps)
    |> Enum.flat_map(fn
      {:pkg_config, lib_names} ->
        get_flags_for_pkg_config(lib_names, flags_type, native.app)

      {precompiled_dependency, lib_names} ->
        get_flags_for_precompiled({precompiled_dependency, lib_names}, flags_type, native.app)
    end)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  defp parse_os_deps(os_deps) do
    Enum.map(os_deps, fn
      {precompiled_dependency, lib_name_or_names} ->
        lib_names = Bunch.listify(lib_name_or_names) |> Enum.map(&Atom.to_string/1)
        {precompiled_dependency, lib_names}

      lib_name ->
        {:pkg_config, [Atom.to_string(lib_name)]}
    end)
  end

  defp get_flags_for_precompiled({precompiled_dependency, lib_names}, flags_type, app) do
    platform = Bundlex.platform()
    target = nil
    path = precompiled_dependency.get_build_url(platform, target) |> get_package_path()

    cond do
      not File.exists?(path) ->
        # fallback
        get_flags_for_pkg_config(lib_names, flags_type, app)

      flags_type == :libs ->
        full_packages_library_path =
          precompiled_dependency.get_libs_path(path, platform, target) |> Path.absname()

        [
          "-L#{full_packages_library_path}",
          "-Wl,--disable-new-dtags,-rpath,#{full_packages_library_path}"
        ] ++
          Enum.map(lib_names, &"-l#{remove_lib_prefix(&1)}")

      flags_type == :cflags ->
        full_include_path =
          precompiled_dependency.get_headers_path(path, platform, target) |> Path.absname()

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

    [
      Enum.map_join(lib_names, " ", fn lib_name ->
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
    ]
  end

  defp remove_lib_prefix(libname) do
    if String.starts_with?(libname, "lib") do
      String.slice(libname, 3..-1)
    else
      libname
    end
  end

  def fetch_precompiled(native) do
    parse_os_deps(native.os_deps)
    |> Enum.reject(fn
      {:pkg_config, _lib_names} -> true
      {_precompiled_dependency, _lib_names} -> false
    end)
    |> Enum.each(fn {precompiled_dependency, _lib_names} ->
      maybe_download_precompiled_package(precompiled_dependency)
    end)
  end

  defp maybe_download_precompiled_package(precompiled_dependency) do
    File.mkdir_p(@precompiled_path)
    platform = Bundlex.platform()
    # todo
    target = nil
    url = precompiled_dependency.get_build_url(platform, target)
    package_path = get_package_path(url)

    if not File.exists?(package_path) do
      File.mkdir(package_path)
      temporary_destination = "#{@precompiled_path}/temporary"
      download(url, temporary_destination)
      System.shell("tar -xf #{temporary_destination} -C #{package_path} --strip-components 1")
      System.shell("rm #{temporary_destination}")
    end
  end

  defp get_package_path(url) do
    url = if String.ends_with?(url, "/"), do: String.slice(url, 0..-2), else: url

    last_part =
      String.split(url, "/")
      |> Enum.at(-1)
      |> String.split(".")
      |> Enum.reject(&(&1 in ["tar", "xz"]))
      |> Enum.join(".")

    "#{@precompiled_path}#{last_part}"
  end

  defp network_tool() do
    cond do
      executable_exists?("curl") -> :curl
      executable_exists?("wget") -> :wget
      true -> nil
    end
  end

  defp download(url, dest) do
    command =
      case network_tool() do
        :curl -> "curl --fail -L -o #{dest} #{url}"
        :wget -> "wget -O #{dest} #{url}"
      end

    case System.shell(command) do
      {_, 0} -> :ok
      _ -> :error
    end
  end

  defp executable_exists?(name), do: System.find_executable(name) != nil
end
