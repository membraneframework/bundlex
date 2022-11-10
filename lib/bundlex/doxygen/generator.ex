defmodule Bundlex.Doxygen.Generator do
  alias Doxygen.Project

  @spec generate_doxyfile(Project.t()) :: no_return()
  def generate_doxyfile(project) do
    doxyfile_path = create_doxygen_template(project)
    keywords_to_change = keywords_to_change(project)

    update_doxygen_keywords(doxyfile_path, keywords_to_change)
  end

  defp create_doxygen_template(project) do
    doxyfile_path = doxyfile_path(project)
    System.cmd("doxygen", ["-g", doxyfile_path])
    doxyfile_path
  end

  @spec doxyfile_path(Project.t()) :: String.t()
  def doxyfile_path(project) do
    project_name = "#{project.app}"
    project_dirpath = Path.join([project.src_path, project_name])
    Path.join(project_dirpath, "Doxyfile")
  end

  defp keywords_to_change(project) do
    project_name = "#{project.app}"
    doc_dirpath = Path.join(["doc", "doxygen", project_name])

    %{
      "PROJECT_NAME" => "#{project.app}",
      "OUTPUT_DIRECTORY" => doc_dirpath,
      "TAB_SIZE" => "2",
      "BUILTIN_STL_SUPPORT" => "YES",
      "RECURSIVE" => "YES",
      "GENERATE_LATEX" => "NO"
    }
  end

  defp update_doxygen_keywords(doxyfile_path, keywords_to_change) do
    File.stream!(doxyfile_path)
    |> Stream.map(fn line ->
      if comment?(line) do
        line
      else
        replace_keywords(line, keywords_to_change)
      end
    end)
    |> Enum.join()
    |> then(&File.write!(doxyfile_path, &1))
  end

  defp comment?(line) do
    String.starts_with?(line, "#")
  end

  defp replace_keywords(line, keywords_to_change) do
    Enum.reduce(keywords_to_change, line, fn {keyword, value}, acc ->
      String.replace(acc, ~r/(#{keyword}\s*=)\s*(.*)\n/, "\\1 \"#{value}\"\n")
    end)
  end
end
