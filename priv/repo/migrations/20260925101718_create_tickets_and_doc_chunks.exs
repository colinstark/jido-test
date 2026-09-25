defmodule JidoLab.Repo.Migrations.CreateTicketsAndDocChunks do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :title, :string, null: false
      add :email, :string, null: false
      add :priority, :string, null: false
      add :body, :text, null: false
      add :status, :string, null: false, default: "open"

      timestamps(type: :utc_datetime)
    end

    create index(:tickets, [:email])

    # FTS5 full-text index over markdown chunks; ranked with bm25().
    execute(
      "CREATE VIRTUAL TABLE doc_chunks USING fts5(path, heading, content, tokenize = 'porter')",
      "DROP TABLE doc_chunks"
    )
  end
end
