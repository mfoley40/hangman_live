defmodule HangmanLive.Repo.Migrations.CreateWords do
  use Ecto.Migration

  def change do
    create table(:words) do
          add :word, :string, null: false
          add :length, :integer, default: 0
          add :used, :boolean, null: false, default: false
          timestamps
        end
  end
end
