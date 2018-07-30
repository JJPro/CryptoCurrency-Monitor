defmodule Investing.Repo.Migrations.ReplaceExpiredWithStatusInOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      remove :expired
      add :status, :string, default: "pending", null: false
    end
  end
end
