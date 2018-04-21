defmodule Investing.Finance.AlphavantageServer do



  # input example: ["AAPL", "BABA"]
  # output example: %{"AAPL" => %{price: "165.7500", symbol: "AAPL", timestamp: "2018-04-20 16:59:43", volume: "65336628"},
  #                   "BABA" => %{price: "179.0150", symbol: "BABA", timestamp: "2018-04-20 16:29:15", volume: "14238329"}}
  def stocks_now(list_of_stock) do
    stocks = Enum.join(list_of_stock, ",")
    url = "https://www.alphavantage.co/query?function=BATCH_STOCK_QUOTES&symbols=#{stocks}&apikey=ZVNGUSZP22DQUKKQ"
    resp = HTTPoison.get!(url)
    s_data = Poison.decode!(resp.body)["Stock Quotes"]
    data = Enum.map(s_data, fn(s) -> transfer_stock(s) end)

    generate_stock_map(data, %{})
  end

  defp generate_stock_map(data, accum) do
    if Enum.empty?(data) do
      accum
    else
      {:ok, stock} = Enum.fetch(data, 0)
      accum = Map.put(accum, stock.symbol, stock)
      [_first | rest] = data
      generate_stock_map(rest, accum)
    end
  end

  defp transfer_stock(stock) do
    %{"1. symbol" => sym, "2. price" => price, "3. volume" => vol, "4. timestamp" => time} = stock

    %{:symbol => sym, :price => price, :volume => vol, :timestamp => time}
  end
end
