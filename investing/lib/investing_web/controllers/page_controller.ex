defmodule InvestingWeb.PageController do
  use InvestingWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
