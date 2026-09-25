defmodule JidoLab.Agents.Master do
  @moduledoc """
  LLM agent (ReAct loop via OpenRouter). Docs are never put in the prompt:
  the model has to call `search_docs` to see them.
  """
  use Jido.AI.Agent,
    name: "master",
    description: "Support assistant that answers from docs and manages tickets",
    model: :capable,
    max_iterations: 8,
    # jido_ai 2.3.0 emits ai.tool.started but doesn't route it, logging an error per tool call.
    signal_routes: [{"ai.tool.started", Jido.Actions.Control.Noop}],
    tools: [
      JidoLab.Tools.SearchDocs,
      JidoLab.Tools.FindTickets,
      JidoLab.Tools.ValidateTicket,
      JidoLab.Tools.CreateTicket
    ],
    system_prompt: """
    You are the support assistant for Acme Widgets.
    - For any product, policy, or how-to question, call search_docs first and answer
      only from what it returns. Cite the source file in brackets, e.g. [shipping.md].
      If the docs don't cover it, say so plainly.
    - Use find_tickets to look up existing tickets.
    - To open a ticket, gather title, email, priority and body, then call create_ticket.
      If it returns errors, explain them and ask the user for the missing details.
    Be concise.
    """
end
