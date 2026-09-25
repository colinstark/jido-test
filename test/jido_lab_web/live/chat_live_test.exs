defmodule JidoLabWeb.ChatLiveTest do
  use JidoLabWeb.ConnCase

  test "GET / starts a new conversation", %{conn: conn} do
    assert "/c/" <> _ = redirected_to(get(conn, ~p"/"))
  end

  test "GET /c/:id renders the chat", %{conn: conn} do
    assert html_response(get(conn, ~p"/c/abc"), 200) =~ "Ask about shipping, returns"
  end
end
