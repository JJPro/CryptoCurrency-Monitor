defmodule Investing.Finance.Holding do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Poison.Encoder, only: [:symbol, :bought_at, :quantity, :id]}

  schema "holdings" do
    field :bought_at, :float
    field :quantity, :integer
    field :symbol, :string
    belongs_to :user, Investing.Accounts.User # will generate default foreign key :user_id

    timestamps()
  end

  @doc false
  def changeset(holding, attrs) do
    holding
    |> cast(attrs, [:symbol, :bought_at, :quantity, :user_id])
    |> validate_required([:symbol, :bought_at, :quantity, :user_id])
  end
end
