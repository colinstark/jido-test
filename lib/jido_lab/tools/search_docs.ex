defmodule JidoLab.Tools.SearchDocs do
  @moduledoc "Full-text search over the indexed markdown knowledge base."
  use Jido.Action,
    name: "search_docs",
    description:
      "Search the product documentation. Returns the most relevant markdown sections with their source file. Use specific keywords.",
    schema:
      Zoi.object(%{
        query: Zoi.string(description: "Keywords or a question to search for"),
        limit: Zoi.integer(description: "Max sections to return (1-8)") |> Zoi.default(4)
      })

  @impl true
  def run(%{query: query} = params, _context) do
    results = JidoLab.Docs.search(query, params |> Map.get(:limit, 4) |> min(8) |> max(1))
    {:ok, %{results: Enum.map(results, &Map.delete(&1, :score))}}
  end
end
