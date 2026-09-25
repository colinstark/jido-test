defmodule JidoLabWeb.ChatLive do
  use JidoLabWeb, :live_view

  alias JidoLab.Agents.Master
  alias JidoLab.Chats

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {agent, messages} =
      if connected?(socket) do
        {:ok, pid} = Chats.get(id)
        {pid, Chats.history(pid)}
      else
        {nil, []}
      end

    {:ok,
     assign(socket,
       id: id,
       agent: agent,
       messages: messages,
       busy: false,
       form: to_form(%{"q" => ""})
     )}
  end

  def mount(_params, _session, socket),
    do: {:ok, push_navigate(socket, to: ~p"/c/#{Ecto.UUID.generate()}")}

  @impl true
  def handle_event("ask", %{"q" => q}, socket) when q != "" and not socket.assigns.busy do
    %{agent: pid, id: id} = socket.assigns

    socket =
      socket
      |> update(:messages, &(&1 ++ [%{role: :user, text: q, tools: []}]))
      |> assign(busy: true, form: to_form(%{"q" => ""}))
      |> start_async(:answer, fn ->
        {:ok, req} = Master.ask(pid, q)
        answer = Master.await(req, timeout: :timer.minutes(10))
        Chats.checkpoint(pid, id)
        {:ok, status} = Jido.AgentServer.status(pid)
        {answer, List.wrap(status.snapshot.details[:tool_results])}
      end)

    {:noreply, socket}
  end

  def handle_event("ask", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_async(:answer, {:ok, {answer, tools}}, socket) do
    text =
      case answer do
        {:ok, text} -> text
        {:error, reason} -> "Error: #{inspect(reason)}"
      end

    {:noreply, socket |> add_reply(text, tools) |> assign(busy: false)}
  end

  def handle_async(:answer, {:exit, reason}, socket) do
    {:noreply, socket |> add_reply("Crashed: #{inspect(reason)}", []) |> assign(busy: false)}
  end

  defp tool_output({:ok, output, _effects}), do: output
  defp tool_output(other), do: other

  defp add_reply(socket, text, tools),
    do: update(socket, :messages, &(&1 ++ [%{role: :assistant, text: text, tools: tools}]))

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="mx-auto max-w-2xl space-y-4">
        <.link navigate={~p"/"} class="btn btn-ghost btn-sm">New chat</.link>
        <div
          :for={msg <- @messages}
          class={["chat", msg.role == :user && "chat-end", msg.role == :assistant && "chat-start"]}
        >
          <div class={["chat-bubble whitespace-pre-wrap", msg.role == :user && "chat-bubble-primary"]}>
            {msg.text}
          </div>
          <details :for={tool <- msg.tools} class="chat-footer mt-1 text-xs opacity-70">
            <summary class="cursor-pointer">tool: {tool.name}({inspect(tool.arguments)})</summary>
            <pre class="mt-1 max-h-64 overflow-auto rounded bg-base-200 p-2">{inspect(tool_output(tool.result), pretty: true, limit: 50)}</pre>
          </details>
        </div>

        <div :if={@busy} class="chat chat-start">
          <div class="chat-bubble"><span class="loading loading-dots loading-sm"></span></div>
        </div>

        <.form for={@form} phx-submit="ask" class="flex gap-2">
          <input
            type="text"
            name="q"
            value={@form[:q].value}
            placeholder="Ask about shipping, returns, Widget Pro, or open a ticket…"
            class="input input-bordered flex-1"
            autocomplete="off"
            disabled={@busy}
          />
          <button class="btn btn-primary" disabled={@busy}>Ask</button>
        </.form>
      </div>
    </Layouts.app>
    """
  end
end
