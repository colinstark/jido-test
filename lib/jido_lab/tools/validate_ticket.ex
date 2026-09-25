defmodule JidoLab.Tools.ValidateTicket do
  @moduledoc "Exposes `JidoLab.Tickets.validate/1` to LLM agents as the `validate_ticket` tool."
  use Jido.Action,
    name: "validate_ticket",
    description:
      "Check a draft support ticket against business rules without saving it. Returns valid plus a list of errors.",
    schema:
      Zoi.object(%{
        title: Zoi.string(description: "Short summary, 5-120 chars") |> Zoi.optional(),
        email: Zoi.string(description: "Customer email") |> Zoi.optional(),
        priority: Zoi.string(description: "low | normal | high | urgent") |> Zoi.optional(),
        body: Zoi.string(description: "Problem description, at least 20 chars") |> Zoi.optional()
      })

  @impl true
  def run(params, _context) do
    errors = JidoLab.Tickets.validate(params)
    {:ok, %{valid: errors == [], errors: errors}}
  end
end
