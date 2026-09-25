defmodule JidoLab.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      JidoLabWeb.Telemetry,
      JidoLab.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:jido_lab, :ecto_repos), skip: skip_migrations?()},
      JidoLab.Jido,
      JidoLab.Chats,
      {DNSCluster, query: Application.get_env(:jido_lab, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: JidoLab.PubSub},
      # Start a worker by calling: JidoLab.Worker.start_link(arg)
      # {JidoLab.Worker, arg},
      # Start to serve requests, typically the last entry
      JidoLabWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JidoLab.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    JidoLabWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
