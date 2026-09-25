defmodule JidoLab.Tickets do
  @moduledoc "Support tickets stored in SQLite."

  import Ecto.Query
  alias JidoLab.Repo
  alias JidoLab.Tickets.Ticket

  def list(filters \\ %{}) do
    Ticket
    |> maybe_where(:email, filters[:email])
    |> maybe_where(:status, filters[:status])
    |> order_by(desc: :inserted_at)
    |> limit(20)
    |> Repo.all()
  end

  def create(attrs), do: %Ticket{} |> Ticket.changeset(attrs) |> Repo.insert()

  @doc "Business-rule errors for a draft ticket, e.g. `[\"title should be at least 5 character(s)\"]`."
  def validate(attrs), do: %Ticket{} |> Ticket.changeset(attrs) |> error_messages()

  def error_messages(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.flat_map(fn {field, msgs} -> Enum.map(msgs, &"#{field} #{&1}") end)
  end

  defp maybe_where(query, _field, nil), do: query
  defp maybe_where(query, field, value), do: where(query, [t], field(t, ^field) == ^value)
end
