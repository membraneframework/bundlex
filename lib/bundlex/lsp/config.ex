defmodule Bundlex.LSP.Config do
  @moduledoc """
  Generates LSP configuration files (compile_commands.json, compile_flags.txt)
  for C/C++ code analysis tools like clangd.
  """

  alias Bundlex.Output

  @type compile_command :: %{
          required(:directory) => String.t(),
          required(:command) => String.t(),
          required(:file) => String.t(),
          optional(:output) => String.t()
        }

  @doc """
  Generates LSP configuration files from a list of build commands.

  ## Returns

    `{:ok, [{:compile_commands_json, path} | {:compile_flags_txt, path}]}`
    or `{:error, reason}` if all writes fail.
  """
  @spec generate(commands :: [String.t()], project_dir :: String.t()) ::
          {:ok, [{atom, String.t()}]} | {:error, String.t()}
  def generate(commands, project_dir) do
    project_dir = Path.expand(project_dir)

    {compile_commands, common_flags} =
      parse_compile_commands(commands, project_dir)

    maybe_commands =
      case write_compile_commands_json(compile_commands, project_dir) do
        {:ok, path} ->
          [{:compile_commands_json, path}]

        {:error, reason} ->
          Output.warn("Failed to write compile_commands.json: #{reason}")
          []
      end

    # Root compile_flags.txt with flags common to all variants written to project root only,
    # avoiding pollution of VCS-tracked source directories.
    maybe_root_flags =
      case write_compile_flags_txt(common_flags, project_dir) do
        {:ok, path} ->
          [{:compile_flags_txt, path}]

        {:error, reason} ->
          Output.warn("Failed to write compile_flags.txt: #{reason}")
          []
      end

    case maybe_commands ++ maybe_root_flags do
      [] -> {:error, "No configuration files were generated"}
      generated -> {:ok, generated}
    end
  end

  defp parse_compile_commands(commands, project_dir) do
    entries =
      commands
      |> Enum.reject(&skip_command?/1)
      |> Enum.flat_map(&parse_entry(&1, project_dir))

    compile_commands = Enum.map(entries, &elem(&1, 0))

    all_flag_sets = Enum.map(entries, &elem(&1, 1))

    common_flags =
      case all_flag_sets do
        [] -> MapSet.new()
        [single] -> single
        [first | rest] -> Enum.reduce(rest, first, &MapSet.intersection(&2, &1))
      end

    {compile_commands, common_flags}
  end

  defp parse_entry(command, project_dir) do
    case parse_compile_command(command, project_dir) do
      nil ->
        []

      info ->
        parts = parse_shell_arguments(command)
        flags = MapSet.new(extract_flags_from_command(parts))
        [{info, flags}]
    end
  end

  # Replaces version-pinned Homebrew Erlang paths with the stable opt/ symlink,
  # e.g. /opt/homebrew/Cellar/erlang/28.4.1/lib/erlang → /opt/homebrew/opt/erlang/lib/erlang
  # No-op on non-Homebrew systems.
  defp normalize_homebrew_erlang_path(str) do
    Regex.replace(
      ~r|/opt/homebrew/Cellar/erlang/[^/]+/lib/erlang|,
      str,
      "/opt/homebrew/opt/erlang/lib/erlang"
    )
  end

  # Checks the basename of the first token so that tools installed under a full path
  # (e.g. /usr/bin/ar) are correctly skipped rather than only bare invocations.
  defp skip_command?(command) do
    binary =
      case parse_shell_arguments(command) do
        [] -> ""
        [first | _rest] -> Path.basename(first)
      end

    binary in ~w[mkdir rm ar] ||
      (String.contains?(command, " -o ") &&
         !String.contains?(command, " -c ") &&
         (String.contains?(command, ".so") ||
            String.contains?(command, ".dll") ||
            String.contains?(command, ".dylib")))
  end

  defp parse_compile_command(command, project_dir) do
    parts = parse_shell_arguments(command)
    {source_file, output_file} = extract_source_and_output(parts)

    case source_file do
      nil ->
        nil

      source ->
        source = to_absolute_path(source, project_dir)
        output = output_file && to_absolute_path(output_file, project_dir)

        %{
          directory: Path.dirname(source),
          command: Enum.join(parts, " "),
          file: source,
          output: output
        }
    end
  end

  defp extract_source_and_output(parts) do
    {source, output, _after_o} =
      Enum.reduce(parts, {nil, nil, false}, fn part, {source, output, after_o} ->
        cond do
          after_o && output == nil -> {source, part, false}
          part == "-o" -> {source, output, true}
          source == nil && source_file?(part) -> {part, output, after_o}
          true -> {source, output, after_o}
        end
      end)

    {source, output}
  end

  defp to_absolute_path(path, base_dir) do
    if Path.absname(path) == path, do: path, else: Path.join(base_dir, path)
  end

  # Naive tokenizer: strips quotes then splits on whitespace. Paths containing spaces will be corrupted.
  defp parse_shell_arguments(command) do
    command
    |> String.replace("\"", "")
    |> String.replace("'", "")
    |> String.split()
  end

  defp source_file?(str) do
    String.ends_with?(str, ".c") ||
      String.ends_with?(str, ".cpp") ||
      String.ends_with?(str, ".cc") ||
      String.ends_with?(str, ".cxx")
  end

  defp extract_flags_from_command(parts) do
    parts
    |> Enum.filter(fn part ->
      String.starts_with?(part, "-") && part != "-o" && part != "-c"
    end)
    |> Enum.map(&normalize_homebrew_erlang_path/1)
  end

  defp write_compile_commands_json(commands, project_dir) do
    path = Path.join(project_dir, "compile_commands.json")

    entries =
      Enum.map(commands, fn cmd ->
        entry = %{
          # Use the directory the compiler was invoked from so clangd resolves relative includes correctly.
          "directory" => cmd.directory,
          "command" => normalize_homebrew_erlang_path(cmd.command),
          "file" => cmd.file
        }

        if cmd.output, do: Map.put(entry, "output", cmd.output), else: entry
      end)

    json = Jason.encode!(entries, pretty: true)

    case File.write(path, json) do
      :ok ->
        Output.info("Generated compile_commands.json at #{path}")
        {:ok, path}

      {:error, reason} ->
        {:error, "Failed to write #{path}: #{inspect(reason)}"}
    end
  end

  defp write_compile_flags_txt(flags, dir) do
    path = Path.join(dir, "compile_flags.txt")
    content = flags |> MapSet.to_list() |> Enum.sort() |> Enum.join("\n")

    case File.write(path, content) do
      :ok ->
        Output.info("Generated compile_flags.txt at #{path}")
        {:ok, path}

      {:error, reason} ->
        {:error, "Failed to write #{path}: #{inspect(reason)}"}
    end
  end
end
