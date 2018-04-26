defmodule InvestingWeb.Plugs.RequireAuth do
  import Plug.Conn
  alias Investing.{Accounts, Accounts.User}
  import InvestingWeb.Router.Helpers, only: [session_path: 2]
  import Phoenix.Controller, only: [redirect: 2]

  def init(_params) do end

  def call(conn, _params) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> redirect(to: session_path(conn, :new))
      |> halt()
    end
  end
end
