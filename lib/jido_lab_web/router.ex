defmodule JidoLabWeb.Router do
  use JidoLabWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JidoLabWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", JidoLabWeb do
    pipe_through :browser

    live "/", ChatLive
    live "/c/:id", ChatLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", JidoLabWeb do
  #   pipe_through :api
  # end
end
