defmodule Investing.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add :symbol, :string, null: false
      add :condition, :string, null: false
      add :expired, :boolean, default: false
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:alerts, [:user_id])
  end
end
