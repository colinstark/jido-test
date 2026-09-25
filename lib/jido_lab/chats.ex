defmodule JidoLab.Chats do
  @moduledoc """
  One `Master` agent per conversation id, managed by `Jido.Agent.InstanceManager`.

  Idle agents hibernate to disk and are thawed on the next `get/1`. Agent
  processes don't trap exits, so a server shutdown skips that hibernate;
  `checkpoint/2` is called after every answer so a restart loses nothing.
  """

  alias Jido.Agent.InstanceManager

  @manager :chats

  def child_spec(_opts) do
    InstanceManager.child_spec(
      name: @manager,
      agent: JidoLab.Agents.Master,
      idle_timeout: :timer.minutes(15),
      storage: storage(),
      agent_opts: [jido: JidoLab.Jido]
    )
  end

  @doc "Finds, thaws, or starts the agent for `id` and keeps it alive while the caller lives."
  def get(id) do
    with {:ok, pid} <- InstanceManager.get(@manager, id),
         :ok <- Jido.AgentServer.attach(pid) do
      {:ok, pid}
    end
  end

  @doc "Persists the agent's current state under the same key InstanceManager thaws from."
  def checkpoint(pid, id) do
    {:ok, %{agent: agent}} = Jido.AgentServer.state(pid)

    Jido.Persist.hibernate(
      storage(),
      JidoLab.Agents.Master,
      Jido.partition_key({@manager, id}, nil),
      agent
    )
  end

  @doc "User and assistant text turns of the conversation so far."
  def history(pid) do
    {:ok, status} = Jido.AgentServer.status(pid)

    for %{role: role, content: text} <- List.wrap(status.snapshot.details[:conversation]),
        role in [:user, :assistant] and is_binary(text) and text != "",
        do: %{role: role, text: text, tools: []}
  end

  defp storage, do: {Jido.Storage.File, path: Application.fetch_env!(:jido_lab, :agent_storage)}
end
