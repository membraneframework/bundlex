defmodule Bundlex.Doxygen.Generator do
  alias Doxygen.Project

  @type doxygen_t :: %{
          project_name: String.t(),
          doxyfile_path: String.t(),
          doxygen_path: String.t(),
          page_path: String.t()
        }

  @spec doxygen(Project.t()) :: doxygen_t()
  def doxygen(project) do
    project_name = Atom.to_string(project.app)

    %{
      project_name: project_name,
      doxyfile_path: doxyfile_path(project),
      doxygen_path: doxygen_path(project),
      page_path: page_path(project)
    }
  end

  defp doxyfile_path(project) do
    project_name = "#{project.app}"
    project_dirpath = Path.join([project.src_path, project_name])
    Path.join(project_dirpath, "Doxyfile")
  end

  defp doxygen_path(project) do
    project_name = "#{project.app}"
    Path.join(["doc", "doxygen", project_name])
  end

  defp page_path(project) do
    Path.join(["pages", "doxygen", "#{project.app}.md"])
  end

  @spec generate_doxyfile(doxygen_t()) :: no_return()
  def generate_doxyfile(doxygen) do
    create_doxyfile_template(doxygen)

    keywords_to_change = keywords_to_change(doxygen)
    update_doxyfile_keywords(doxygen, keywords_to_change)
  end

  defp create_doxyfile_template(doxygen) do
    System.cmd("doxygen", ["-g", doxygen.doxyfile_path])
  end

  defp keywords_to_change(doxygen) do
    %{
      "PROJECT_NAME" => "#{doxygen.project_name}",
      "OUTPUT_DIRECTORY" => doxygen.doxygen_path,
      "TAB_SIZE" => "2",
      "BUILTIN_STL_SUPPORT" => "YES",
      "RECURSIVE" => "YES",
      "GENERATE_LATEX" => "NO"
    }
  end

  defp update_doxyfile_keywords(doxygen, keywords_to_change) do
    doxyfile_path = doxygen.doxyfile_path

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

  @spec generate_doxygen(doxygen_t()) :: no_return()
  def generate_doxygen(doxygen) do
    if not File.exists?(doxygen.doxygen_path) do
      File.mkdir_p!(doxygen.doxygen_path)
      File.touch!(Path.join(["doc", ".build"]))
    end

    System.cmd("doxygen", [doxygen.doxyfile_path])
  end

  @spec generate_hex_page(doxygen_t()) :: :ok
  def generate_hex_page(doxygen) do
    pages_dirpath = Path.dirname(doxygen.page_path)

    if not File.exists?(pages_dirpath) do
      File.mkdir_p!(pages_dirpath)
    end

    html_filepath = Path.join(["..", doxygen.doxygen_path, "html", "index.html"])

    page = """
    # #{doxygen.project_name |> String.capitalize()}
    [Doxygen documentation of the native code](#{html_filepath})
    """

    File.write!(doxygen.page_path, page)
  end
end
