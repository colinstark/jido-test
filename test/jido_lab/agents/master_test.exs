defmodule JidoLab.Agents.MasterTest do
  # Not async: tools run in agent-owned processes, so the Ecto sandbox is shared.
  use JidoLab.DataCase, async: false

  import Jido.AI.Test

  alias JidoLab.Agents.Master
  alias JidoLab.Tickets

  setup do
    JidoLab.Docs.index!(Path.join(:code.priv_dir(:jido_lab), "docs"))
    {:ok, pid} = Jido.AgentServer.start_link(jido: JidoLab.Jido, agent: Master)
    %{pid: pid}
  end

  test "answers from docs via the search_docs tool", %{pid: pid} do
    script =
      expect_react do
        user("What is the return window?")
        call("search_docs", %{query: "return window"})
        answer("30 days [returns.md]")
      end

    assert {:ok, "30 days [returns.md]"} =
             Master.ask_sync(pid, "What is the return window?", react_opts(script))

    {:ok, status} = Jido.AgentServer.status(pid)
    [search] = status.snapshot.details[:tool_results]
    assert search.name == "search_docs"
    assert inspect(search) =~ "returns.md"
  end

  test "create_ticket only persists tickets the validator accepts", %{pid: pid} do
    script =
      expect_react do
        user("Open an urgent ticket")

        call("create_ticket", %{
          title: "Broken",
          email: "a@b.io",
          priority: "urgent",
          body: "It does not work at all!!"
        })

        call("create_ticket", %{
          title: "Broken",
          email: "a@b.io",
          priority: "urgent",
          body: "ORD-777 does not work at all"
        })

        answer("Ticket created.")
      end

    assert {:ok, "Ticket created."} =
             Master.ask_sync(pid, "Open an urgent ticket", react_opts(script))

    assert [%{body: "ORD-777" <> _}] = Tickets.list(%{email: "a@b.io"})
  end
end
