defmodule JidoLab.ChatsTest do
  use JidoLab.DataCase, async: false

  import Jido.AI.Test

  alias JidoLab.Agents.Master
  alias JidoLab.Chats

  test "conversation survives the agent process dying" do
    id = Ecto.UUID.generate()
    {:ok, pid} = Chats.get(id)

    script =
      expect_react do
        user("What is the return window?")
        call("search_docs", %{query: "return window"})
        answer("30 days [returns.md]")
      end

    {:ok, _} = Master.ask_sync(pid, "What is the return window?", react_opts(script))
    :ok = Chats.checkpoint(pid, id)

    # :kill skips terminate/2, like a server restart would.
    ref = Process.monitor(pid)
    Process.exit(pid, :kill)
    assert_receive {:DOWN, ^ref, _, _, _}

    assert {:ok, new_pid} = eventually(fn -> Chats.get(id) end)
    assert new_pid != pid

    assert [
             %{role: :user, text: "What is the return window?"},
             %{role: :assistant, text: "30 days [returns.md]"}
           ] =
             Chats.history(new_pid)
  end

  test "history includes assistant replies that carry thinking" do
    context =
      Jido.AI.Context.new(system_prompt: "sys")
      |> Jido.AI.Context.append_user("Who are you?")
      |> Jido.AI.Context.append_assistant("The support assistant.", nil,
        thinking: "User asks identity."
      )

    {:ok, pid} =
      Jido.AgentServer.start_link(
        jido: JidoLab.Jido,
        agent: Master,
        initial_state: %{context: context}
      )

    assert [
             %{role: :user, text: "Who are you?"},
             %{role: :assistant, text: "The support assistant."}
           ] =
             Chats.history(pid)
  end

  # The registry drops the dead pid asynchronously.
  defp eventually(fun, tries \\ 20) do
    case fun.() do
      {:ok, pid} = ok when is_pid(pid) -> if Process.alive?(pid), do: ok, else: retry(fun, tries)
      _ -> retry(fun, tries)
    end
  end

  defp retry(fun, tries) when tries > 0,
    do:
      (
        Process.sleep(10)
        eventually(fun, tries - 1)
      )
end
