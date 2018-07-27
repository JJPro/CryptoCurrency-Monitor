defmodule Investing.Repo.Migrations.AddBalanceToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :balance, :float
    end
  end
end
