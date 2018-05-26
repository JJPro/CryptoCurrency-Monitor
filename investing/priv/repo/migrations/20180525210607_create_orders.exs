defmodule Investing.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :symbol, :string
      add :action, :string
      add :target, :float
      add :quantity, :integer
      add :stoploss, :float
      add :expired, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:orders, [:user_id])
  end
end
