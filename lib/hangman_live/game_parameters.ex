defmodule HangmanLive.GameParameters do
  @moduledoc """
  A simple schema for the Game parameters entered by the user in
  the LiveView.
  Validation is perfomed here.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "game_parameters" do
    field :length, :integer
    field :guesses, :integer
  end

  def changeset(game_parameters, attrs) do
    game_parameters
    |> cast(attrs, [:length, :guesses])
    |> validate_required([:length], message: "Word length can't be blank.")
    |> validate_required([:guesses], message: "Guesses can't be blank.")
    |> validate_number(:length, greater_than: 1, less_than: 30, message: "Word lengh must be between 2 and 29.")
    |> validate_number(:guesses, greater_than: 0, less_than: 27, message: "Guesses must be between 1 and 26.")
  end
end
