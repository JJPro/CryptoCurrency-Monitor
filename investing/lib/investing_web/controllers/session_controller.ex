defmodule InvestingWeb.SessionController do
  use InvestingWeb, :controller

  alias Comeonin.Argon2
  alias Investing.Repo
  alias Investing.Accounts.User

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, session_params) do
    case login(session_params, Repo) do
      {:ok, user} ->
        conn
        |> put_session(:current_user, user.id)
        |> put_session(:current_username, user.username)
        |> put_flash(:info, "Logged in")
        |> redirect(to: "/")
      :error ->
        conn
        |> put_flash(:error, "Incorrect email or password")
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    IO.puts ">>>> deleting session"
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Logged out")
    |> redirect(to: "/")
  end

  ## help methods
  def login(params, repo) do
    user = repo.get_by(User, email: String.downcase(params["email"]))
    case authenticate(user, params["password"]) do
      true -> {:ok, user}
      _ -> :error
    end
  end

  def authenticate(user, password) do
    case user do
      nil -> false
      _ -> validate_password(password, user.password_hash)
    end
  end

  def validate_password(password, hash) do
    Argon2.checkpw(password, hash)
  end

end
