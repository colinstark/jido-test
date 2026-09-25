defmodule JidoLabWeb.ChatLiveTest do
  use JidoLabWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET / starts a new conversation", %{conn: conn} do
    assert "/c/" <> _ = redirected_to(get(conn, ~p"/"))
  end

  test "GET /c/:id renders the chat", %{conn: conn} do
    assert html_response(get(conn, ~p"/c/abc"), 200) =~ "Ask about shipping, returns"
  end

  test "an unrestorable conversation redirects to a fresh one", %{conn: conn} do
    id = Ecto.UUID.generate()
    # Same derivation as Jido.Storage.File.checkpoint_path/2; Persist prefixes the agent module.
    hash =
      :crypto.hash(:sha256, :erlang.term_to_binary({JidoLab.Agents.Master, {:chats, id}}))
      |> Base.url_encode64(padding: false)

    path =
      Path.join([
        Application.fetch_env!(:jido_lab, :agent_storage),
        "checkpoints",
        "#{hash}.term"
      ])

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "not an erlang term")
    on_exit(fn -> File.rm(path) end)

    assert {:error, {:live_redirect, %{to: "/", flash: flash}}} = live(conn, ~p"/c/#{id}")
    assert is_binary(flash)
  end
end
