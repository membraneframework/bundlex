defmodule Bundlex.Toolchain.Common.Unix do
  @moduledoc false

  use Bunch
  alias Bundlex.{Native, Toolchain, Project}
  alias Bundlex.Toolchain.Common.Compilers

  def compiler_commands(native, compile, link, lang, native_interface \\ nil, options \\ []) do
    includes = native.includes |> paths("-I")
    pkg_config_cflags = native.pkg_configs |> pkg_config(:cflags)
    compiler_flags = native.compiler_flags |> Enum.join(" ")
    output = Toolchain.output_path(native.app, native.name, native_interface)
    output_obj = output <> "_obj"
    std_flag = Compilers.get_std_flag(lang)

    objects =
      native.sources
      |> Enum.map(fn source ->
        """
        #{Path.join(output_obj, source |> Path.basename())}_\
        #{:crypto.hash(:sha, source) |> Base.encode16()}.o\
        """
      end)

    compile_commands =
      native.sources
      |> Enum.zip(objects)
      |> Enum.map(fn {source, object} ->
        """
        #{compile} -Wall -Wextra -c #{std_flag} -O2 -g #{compiler_flags} \
        -o #{path(object)} #{includes} #{pkg_config_cflags} #{path(source)}
        """
      end)

    ["mkdir -p #{path(output_obj)}"] ++
      compile_commands ++ link_commands(native, link, output, objects, options, native_interface)
  end

  defp link_commands(%Native{type: :lib}, _link, output, objects, _options, _native_interface) do
    a_path = path(output <> ".a")
    ["rm -f #{a_path}", "ar rcs #{a_path} #{paths(objects)}"]
  end

  defp link_commands(native, link, output, objects, options, native_interface) do
    extension =
      case native_interface do
        :nif -> ".so"
        t when t in [:cnode, :port] -> ""
      end

    wrap_deps = options |> Keyword.get(:wrap_deps, & &1)

    deps =
      native.deps
      |> Enum.map(fn {app, name} ->
        lib_interfaces = get_lib_interfaces(app, name)

        cond do
          native_interface in lib_interfaces ->
            Toolchain.output_path(app, name, native_interface) <> ".a"

          lib_interfaces == [] ->
            Toolchain.output_path(app, name, nil) <> ".a"
        end
      end)
      |> paths()
      |> wrap_deps.()

    linker_flags = native.linker_flags |> Enum.join(" ")

    [
      """
      #{link} #{linker_flags} -o #{path(output <> extension)} \
      #{deps} #{paths(objects)} #{libs(native)}
      """
    ]
  end

  defp get_lib_interfaces(app, name) do
    {:ok, project} = Project.get(app)
    libs = Keyword.get_values(project.config[:libs], name)
    libs |> Enum.flat_map(&Keyword.get(&1, :interfaces, []))
  end

  defp paths(paths, flag \\ "") do
    paths |> Enum.map(fn p -> "#{flag}#{path(p)}" end) |> Enum.join(" ")
  end

  defp path(path) do
    path = path |> String.replace(~S("), ~S(\")) |> Path.expand()
    ~s("#{path}")
  end

  defp libs(native) do
    lib_dirs = native.lib_dirs |> paths("-L")
    libs = native.libs |> Enum.map_join(" ", fn lib -> "-l#{lib}" end)
    pkg_config_libs = native.pkg_configs |> pkg_config(:libs)
    "#{pkg_config_libs} #{lib_dirs} #{libs}"
  end

  defp pkg_config([], _options), do: ""

  defp pkg_config(packages, options) do
    options = options |> Bunch.listify() |> Enum.map(&"--#{&1}")
    {output, 0} = System.cmd("pkg-config", options ++ packages)
    String.trim_trailing(output)
  end
end
