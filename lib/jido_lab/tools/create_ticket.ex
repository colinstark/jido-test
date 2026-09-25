defmodule JidoLab.Tools.CreateTicket do
  @moduledoc "Saves a ticket if it passes `JidoLab.Tickets.Ticket` validation."
  use Jido.Action,
    name: "create_ticket",
    description:
      "Create a support ticket. It is validated first; if invalid, nothing is saved and the errors are returned so you can ask the user to fix them.",
    schema:
      Zoi.object(%{
        title: Zoi.string(description: "Short summary, 5-120 chars"),
        email: Zoi.string(description: "Customer email"),
        priority: Zoi.string(description: "low | normal | high | urgent"),
        body: Zoi.string(description: "Problem description, at least 20 chars")
      })

  alias JidoLab.Tickets

  @impl true
  def run(params, _context) do
    case Tickets.create(Map.take(params, [:title, :email, :priority, :body])) do
      {:ok, ticket} -> {:ok, %{created: true, ticket_id: ticket.id}}
      {:error, changeset} -> {:ok, %{created: false, errors: Tickets.error_messages(changeset)}}
    end
  end
end
