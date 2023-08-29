defmodule Bundlex.Precompiled do
  @precompiled_path "_build/precompiled/"

  def get_precompiled_flags(native, flags_type) do
    parse_os_deps(native.os_deps)
    |> Enum.flat_map(fn {get_url_lambda, lib_name} ->
      get_precompiled_flags_for_package(get_url_lambda, lib_name, flags_type)
    end)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  defp get_precompiled_flags_for_package(get_url_lambda, lib_name, flags_type) do
    platform = Bundlex.platform()
    path = get_url_lambda.(platform) |> get_package_path()

    case flags_type do
      :libs ->
        full_packages_library_path = Path.join([path, "lib"]) |> Path.absname()

        [
          "-L#{full_packages_library_path}",
          "-l#{lib_name}",
          "-Wl,--disable-new-dtags,-rpath,#{full_packages_library_path}"
        ]

      :cflags ->
        full_include_path = Path.join([path, "include"]) |> Path.absname()
        ["-I#{full_include_path}"]

      other ->
        raise "Unknown flag type: #{inspect(other)}"
    end
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
    |> Enum.each(fn {get_url_lambda, _lib_name} ->
      maybe_download_precompiled_package(get_url_lambda)
    end)
  end

  defp parse_os_deps(os_deps) do
    Enum.filter(os_deps, fn
      {:precompiled, _desc} -> true
      _other -> false
    end)
    |> Enum.flat_map(fn {:precompiled, {get_url_lambda, name_or_names_list}} ->
      Bunch.listify(name_or_names_list)
      |> Enum.map(&{get_url_lambda, to_string(&1) |> remove_lib_prefix()})
    end)
  end

  defp maybe_download_precompiled_package(get_url_lambda) do
    File.mkdir_p(@precompiled_path)
    platform = Bundlex.platform()
    url = get_url_lambda.(platform)
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
