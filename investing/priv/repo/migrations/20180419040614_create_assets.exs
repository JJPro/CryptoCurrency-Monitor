defmodule Investing.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets) do
      add :symbol, :string, null: false
      # add :name, :string
      # add :market, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:assets, [:user_id])
    create unique_index(:assets, [:user_id, :symbol], name: :combined_unique_constraint)
  end
end
