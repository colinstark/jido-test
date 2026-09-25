defmodule JidoLab.Docs do
  @moduledoc """
  Markdown knowledge base backed by SQLite FTS5.

  Files are split into one chunk per heading so search returns focused
  sections instead of whole documents.
  """

  alias JidoLab.Repo

  @doc "Replaces the index with every `*.md` file under `dir`. Returns the chunk count."
  def index!(dir) do
    chunks =
      Path.wildcard(Path.join(dir, "**/*.md"))
      |> Enum.flat_map(fn path -> path |> File.read!() |> chunk(Path.relative_to(path, dir)) end)

    Repo.transaction(fn ->
      Repo.query!("DELETE FROM doc_chunks")

      for %{path: path, heading: heading, content: content} <- chunks do
        Repo.query!("INSERT INTO doc_chunks (path, heading, content) VALUES (?1, ?2, ?3)", [
          path,
          heading,
          content
        ])
      end
    end)

    length(chunks)
  end

  @doc "Splits markdown into `%{path, heading, content}` chunks, one per heading."
  def chunk(markdown, path) do
    markdown
    |> String.split(~r/^(?=#+ )/m, trim: true)
    |> Enum.map(fn section ->
      [first | _] = String.split(section, "\n", parts: 2)

      heading =
        if String.starts_with?(first, "#"), do: String.replace(first, ~r/^#+\s*/, ""), else: path

      %{path: path, heading: String.trim(heading), content: String.trim(section)}
    end)
    |> Enum.reject(&(&1.content == ""))
  end

  @doc "Returns the best matching chunks for a natural-language query, best first."
  def search(query, limit \\ 4) do
    case fts_query(query) do
      "" ->
        []

      match ->
        Repo.query!(
          """
          SELECT path, heading, content, bm25(doc_chunks) AS score
          FROM doc_chunks WHERE doc_chunks MATCH ?1
          ORDER BY score LIMIT ?2
          """,
          [match, limit]
        ).rows
        |> Enum.map(fn [path, heading, content, score] ->
          %{path: path, heading: heading, content: content, score: score}
        end)
    end
  end

  # Quote every word and OR them so user text can't break FTS5 query syntax.
  defp fts_query(query) do
    Regex.scan(~r/[\p{L}\p{N}]{2,}/u, String.downcase(query))
    |> Enum.map_join(" OR ", fn [word] -> ~s("#{word}") end)
  end
end
