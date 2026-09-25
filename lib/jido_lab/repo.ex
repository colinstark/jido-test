defmodule JidoLab.Repo do
  use Ecto.Repo,
    otp_app: :jido_lab,
    adapter: Ecto.Adapters.SQLite3
end
