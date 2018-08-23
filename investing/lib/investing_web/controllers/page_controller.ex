defmodule InvestingWeb.PageController do
  use InvestingWeb, :controller

  # alias Investing.{Mailer, Email}

  def index(conn, _params) do
    render conn, "index.html"
  end

  def main(conn, _params) do

    # Need to change
    # Email.basic_email()
    # |> Mailer.deliver_now()

    render conn, "main.html"
  end
end
