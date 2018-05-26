defmodule Investing.Repo.Migrations.CreateHoldings do
  use Ecto.Migration

  def change do
    create table(:holdings) do
      add :symbol, :string
      add :bought_at, :float
      add :quantity, :integer
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:holdings, [:user_id])
  end
end
