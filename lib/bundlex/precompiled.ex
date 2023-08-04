defmodule Bundlex.Precompiled do
  @precompiled_path "_build/precompiled/"

  def fetch_precompiled(native) do
    parse_os_deps(native.os_deps)
    |> Enum.each(fn {repository_url, package_name} ->
      maybe_download_precompiled_package(repository_url, package_name)
    end)
  end

  def get_precompiled_flags(native, flags_type) do
    parse_os_deps(native.os_deps)
    |> Enum.flat_map(fn {repository_url, package_name} ->
      get_precompiled_flags_for_package(repository_url, package_name, flags_type)
    end)
    |> Enum.uniq()
    |> Enum.join(" ")
  end

  defp get_precompiled_flags_for_package(repository_url, package_name, flags_type) do
    version = Bundlex.platform()
    path = get_url(repository_url, package_name, version) |> get_repository_path()

    case flags_type do
      :libs ->
        full_library_path = Path.join([path, "lib"]) |> Path.absname()
        ["-L #{full_library_path}", "-l #{package_name}"]

      :cflags ->
        full_include_path = Path.join([path, "include"]) |> Path.absname()
        ["-I #{full_include_path}"]

      other ->
        raise "Unknown flag type: #{inspect(other)}"
    end
  end

  defp parse_os_deps(os_deps) do
    Enum.filter(os_deps, fn
      {:precompiled, _desc} -> true
      _other -> false
    end)
    |> Enum.flat_map(fn {:precompiled, {repository, name_or_names_list}} ->
      Bunch.listify(name_or_names_list)
      |> Enum.map(&{repository, to_string(&1) |> remove_lib_prefix()})
    end)
  end

  defp remove_lib_prefix(libname) do
    if String.starts_with?(libname, "lib") do
      String.slice(libname, 3..-1)
    else
      libname
    end
  end

  defp maybe_download_precompiled_package(repository_url, package_name) do
    File.mkdir_p(@precompiled_path)
    version = Bundlex.platform()
    url = get_url(repository_url, package_name, version)
    dest = get_repository_dest(url)
    path = get_repository_path(url)

    if File.exists?(path) do
      ""
    else
      File.mkdir(path)
      download(url, dest)
      System.shell("tar -xf #{dest} -C #{path} --strip-components 1")
      System.shell("rm #{dest}")
    end
  end

  defp get_repository_path(repository_url) do
    last_part =
      String.split(repository_url, "/") |> Enum.at(-1) |> String.split(".") |> Enum.at(0)

    "#{@precompiled_path}#{last_part}"
  end

  defp get_repository_dest(repository_url) do
    last_part = String.split(repository_url, "/") |> Enum.at(-1)
    "#{@precompiled_path}#{last_part}"
  end

  defp get_url(repository_url, package_name, version) do
    "#{repository_url}/ffmpeg-master-latest-linux64-gpl-shared.tar.xz"
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
