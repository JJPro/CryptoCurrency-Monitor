defmodule Investing.Email do
  import Bamboo.Email
  alias Investing.Mailer

  def basic_email(recipient, symbol, condition, price) do
    new_email(
      from: "no-reply@jjpro.me",
      # need to change
      to: recipient,
      subject: "MarketWatcher: #{symbol} Threshold is exceed",
      text_body: "Your limit #{symbol} #{condition} is met. \n Lastest price is $#{price}.",
      html_body: "<p>Your limit <span style=\"font-weight:bold;color:dodgerblue;\">#{symbol}</span> #{condition} is met.</p><p>Lastest price is $#{price}.</p>"
    )
    |> Mailer.deliver_now()
  end
end
