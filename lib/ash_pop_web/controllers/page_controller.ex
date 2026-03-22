defmodule AshPopWeb.PageController do
  use AshPopWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
