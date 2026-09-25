defmodule JidoLab.Tickets.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tickets" do
    field :title, :string
    field :email, :string
    field :priority, :string
    field :body, :string
    field :status, :string, default: "open"

    timestamps(type: :utc_datetime)
  end

  @priorities ~w(low normal high urgent)

  def changeset(ticket, attrs) do
    ticket
    |> cast(attrs, [:title, :email, :priority, :body, :status])
    |> validate_required([:title, :email, :priority, :body])
    |> validate_length(:title, min: 5, max: 120)
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
    |> validate_inclusion(:priority, @priorities)
    |> validate_length(:body, min: 20, max: 5_000)
    |> validate_order_number_when_urgent()
  end

  defp validate_order_number_when_urgent(changeset) do
    if get_field(changeset, :priority) == "urgent" and
         not ((get_field(changeset, :body) || "") =~ ~r/ORD-\d+/) do
      add_error(changeset, :body, "must reference an order number (ORD-12345) for urgent tickets")
    else
      changeset
    end
  end
end
