defmodule Investing.Accounts.Helper do

  alias Investing.Repo
  alias Investing.Accounts.User

  def current_user(conn) do
    id = Plug.Conn.get_session(conn, :current_user)
    if id do
      Repo.get(User, id)
    end
  end

  def logged_in?(conn) do
    !! current_user(conn)
  end
end
