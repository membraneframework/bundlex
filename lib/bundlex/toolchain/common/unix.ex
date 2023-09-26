defmodule Bundlex.Toolchain.Common.Unix do
  @moduledoc false

  use Bunch
  alias Bundlex.{Native, Toolchain}
  alias Bundlex.Toolchain.Common.Compilers

  @spec compiler_commands(
          Native.t(),
          compile :: String.t(),
          link :: String.t(),
          lang :: Native.language_t(),
          options :: Keyword.t()
        ) :: [String.t()]
  def compiler_commands(native, compile, link, lang, options \\ []) do
    includes = native.includes |> paths("-I")

    compiler_flags = resolve_compiler_flags(native.compiler_flags, native.interface, lang)
    output = Toolchain.output_path(native.app, native.name, native.interface)
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
        #{compile} -Wall -Wextra -c -O2 -g #{compiler_flags} \
        -o #{path(object)} #{includes} #{path(source)}
        """
      end)

    ["mkdir -p #{path(output_obj)}"] ++
      compile_commands ++ link_commands(native, link, output, objects, options)
  end

  defp resolve_compiler_flags(compiler_flags, interface, lang) do
    compiler_flags
    |> add_interface_macro_flag(interface)
    |> maybe_add_std_flag(lang)
    |> Enum.join(" ")
  end

  defp add_interface_macro_flag(compiler_flags, nil) do
    compiler_flags
  end

  defp add_interface_macro_flag(compiler_flags, interface) do
    macro_flag = "-DBUNDLEX_#{interface |> Atom.to_string() |> String.upcase()}"
    [macro_flag] ++ compiler_flags
  end

  defp maybe_add_std_flag(compiler_flags, lang) do
    if standard_specyfied?(compiler_flags) do
      compiler_flags
    else
      flag = Compilers.get_default_std_flag(lang)
      [flag | compiler_flags]
    end
  end

  defp standard_specyfied?(compiler_flags) do
    Enum.any?(compiler_flags, &String.match?(&1, ~r/^-std=/))
  end

  defp link_commands(%Native{type: :lib}, _link, output, objects, _options) do
    a_path = path(output <> ".a")
    ["rm -f #{a_path}", "ar rcs #{a_path} #{paths(objects)}"]
  end

  defp link_commands(native, link, output, objects, options) do
    extension =
      case native.interface do
        :nif -> ".so"
        interface when interface in [:cnode, :port] -> ""
      end

    wrap_deps = options |> Keyword.get(:wrap_deps, & &1)

    deps =
      native.deps
      |> Enum.map(&(Toolchain.output_path(&1.app, &1.name, &1.interface) <> ".a"))
      |> paths()
      |> wrap_deps.()

    linker_flags = native.linker_flags |> Enum.join(" ")

    [
      """
      #{link} -o #{path(output <> extension)} \
      #{deps} #{paths(objects)} #{libs(native)} #{linker_flags}
      """
    ]
  end

  defp paths(paths, flag \\ "") do
    Enum.map_join(paths, " ", fn p -> "#{flag}#{path(p)}" end)
  end

  defp path(path) do
    path = path |> String.replace(~S("), ~S(\")) |> Path.expand()
    ~s("#{path}")
  end

  defp libs(native) do
    lib_dirs = native.lib_dirs |> paths("-L")
    libs = native.libs |> Enum.map_join(" ", fn lib -> "-l#{lib}" end)

    "#{lib_dirs} #{libs}"
  end
end
