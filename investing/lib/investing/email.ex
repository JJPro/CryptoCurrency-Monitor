defmodule Investing.Email do
  import Bamboo.Email

  def basic_email(email) do
    new_email(
      from: "no-reply@jjpro.com",
      to: email,
      subject: "Threshold is exceed",
      text_body: "The current currency price is beyond your threshold.",
      html_body: "<p>The current currency price is beyond your threshold.</p>"
    )
  end
end
