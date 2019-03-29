defmodule Bundlex.Toolchain.Common.Unix do
  @moduledoc false

  use Bunch
  alias Bundlex.{Native, Toolchain}

  def compiler_commands(native, compile, link, options \\ []) do
    includes = native.includes |> paths("-I")
    pkg_config_cflags = native.pkg_configs |> pkg_config(:cflags)
    compiler_flags = native.compiler_flags |> Enum.join(" ")
    output = Toolchain.output_path(native.app, native.name)
    output_obj = output <> "_obj"

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
        #{compile} -Wall -Wextra -c -std=c11 -O2 -g #{compiler_flags} \
        -o #{path(object)} #{includes} #{pkg_config_cflags} #{path(source)}
        """
      end)

    ["mkdir -p #{path(output_obj)}"] ++
      compile_commands ++ link_commands(native, link, output, objects, options)
  end

  defp link_commands(%Native{type: :lib}, _link, output, objects, _options) do
    a_path = path(output <> ".a")
    ["rm -f #{a_path}", "ar rcs #{a_path} #{paths(objects)}"]
  end

  defp link_commands(native, link, output, objects, options) do
    extension =
      case native.type do
        :nif -> ".so"
        :cnode -> ""
      end

    wrap_deps = options |> Keyword.get(:wrap_deps, & &1)

    deps =
      native.deps
      |> Enum.map(fn {app, name} -> Toolchain.output_path(app, name) <> ".a" end)
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
