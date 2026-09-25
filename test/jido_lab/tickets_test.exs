defmodule JidoLab.TicketsTest do
  use JidoLab.DataCase, async: false

  alias JidoLab.Tickets

  @valid %{
    title: "Widget cracked",
    email: "a@b.io",
    priority: "high",
    body: "Housing cracked on arrival, ORD-1"
  }

  test "accepts a valid ticket" do
    assert Tickets.validate(@valid) == []
    assert {:ok, _} = Tickets.create(@valid)
  end

  test "reports every broken rule" do
    errors = Tickets.validate(%{title: "x", email: "nope", priority: "meh", body: "short"})
    assert length(errors) == 4
    assert "title should be at least 5 character(s)" in errors
  end

  test "urgent tickets need an order number" do
    assert [error] =
             Tickets.validate(%{
               @valid
               | priority: "urgent",
                 body: "Nothing works at all, please help"
             })

    assert error =~ "order number"
  end
end
