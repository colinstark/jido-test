defmodule JidoLab.Tools.FindTickets do
  @moduledoc "Looks up support tickets in SQLite."
  use Jido.Action,
    name: "find_tickets",
    description:
      "List support tickets from the database, newest first. Optionally filter by customer email and/or status.",
    schema:
      Zoi.object(%{
        email: Zoi.string(description: "Customer email to filter by") |> Zoi.optional(),
        status: Zoi.string(description: "open | closed") |> Zoi.optional()
      })

  @impl true
  def run(params, _context) do
    tickets =
      params
      |> Map.take([:email, :status])
      |> JidoLab.Tickets.list()
      |> Enum.map(&Map.take(&1, [:id, :title, :email, :priority, :status, :body, :inserted_at]))

    {:ok, %{tickets: tickets}}
  end
end
