defmodule AshPopWeb.Router do
  use AshPopWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AshPopWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AshPopWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/line-items", LineItemLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", AshPopWeb do
  #   pipe_through :api
  # end
end
