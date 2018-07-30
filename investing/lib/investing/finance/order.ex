defmodule Investing.Finance.Order do
  use Ecto.Schema
  import Ecto.Changeset


  schema "orders" do
    field :action, :string
    field :status, :string, default: "pending"
    field :quantity, :integer
    field :stoploss, :float
    field :symbol, :string
    field :target, :float
    belongs_to :user, Investing.Accounts.User # will generate default foreign key :user_id

    timestamps()
  end

  @doc false
  def changeset(order, attrs) do
    order
    |> cast(attrs, [:symbol, :action, :target, :quantity, :stoploss, :status, :user_id])
    |> validate_required([:symbol, :action, :target, :quantity, :user_id])
  end
end
