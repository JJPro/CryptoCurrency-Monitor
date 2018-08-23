defmodule Investing.Finance.Alert do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Poison.Encoder, only: [:id, :condition, :symbol, :expired, ]}


  schema "alerts" do
    field :condition, :string
    field :symbol, :string
    field :expired, :boolean
    belongs_to :user, Investing.Accounts.User # will generate default foreign key :user_id

    timestamps()
  end

  @doc false
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:symbol, :condition, :expired, :user_id])
    |> validate_required([:symbol, :condition, :user_id])
  end
end
