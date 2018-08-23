defmodule InvestingWeb.Plugs.SetUser do
  import Plug.Conn
  alias Investing.Accounts

  def init(_params) do
  end

  @doc """
  Put user struct into conn
  """
  def call(conn, _params) do
    uid = get_session(conn, :current_user)
    cond do
      user = uid && Accounts.get_user!(uid) -> assign(conn, :current_user, user)
      true -> assign(conn, :current_user, nil)
    end
  end
end
