defmodule Investing.Finance.Asset do
  use Ecto.Schema
  import Ecto.Changeset


  schema "assets" do
    field :symbol, :string
    field :market, :string
    belongs_to :user, Investing.Accounts.User # will generate default foreign key :user_id

    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:symbol, :market, :user_id])
    |> validate_required([:symbol, :market, :user_id])
    |> unique_constraint(:unique_symbol_market_user, name: :combined_unique_constraint)
  end
end
