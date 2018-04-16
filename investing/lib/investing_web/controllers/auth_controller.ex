defmodule InvestingWeb.AuthController do
  use InvestingWeb, :controller

  alias Investing.Repo
  alias Investing.Accounts.User
  plug Ueberauth

  # define a callback function
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_params = %{password_confirmation: auth.credentials.token, password: auth.credentials.token, username: auth.info.name, email: auth.info.email}
    # IO.inspect user_params
    changeset = User.changeset(%User{}, user_params)

    signin(conn, changeset)
  end


  defp insert_or_update_user(changeset) do
    case Repo.get_by(User, email: changeset.changes.email) do
      nil ->
        Repo.insert(changeset)       
      user ->
        {:ok, user}
    end
  end


  defp signin(conn, changeset) do
    case insert_or_update_user(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> put_session(:current_user, user.id)
        |> put_session(:current_username, user.username)
        |> redirect(to: page_path(conn, :index))
      {:error, _reason} ->
        conn
        |> put_flash(:error, "Error singing in")
        |> redirect(to: page_path(conn, :index))
    end
  end

end
