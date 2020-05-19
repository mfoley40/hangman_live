defmodule HangmanLive.Repo do
  use Ecto.Repo,
    otp_app: :hangman_live,
    adapter: Ecto.Adapters.Postgres
end
