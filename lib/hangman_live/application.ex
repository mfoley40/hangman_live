defmodule HangmanLive.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    children = [
      # Start the database repo
      {HangmanLive.Repo, []},
      # Start the Telemetry supervisor
      HangmanLiveWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: HangmanLive.PubSub},
      # Start the Endpoint (http/https)
      HangmanLiveWeb.Endpoint,
      # Start the Game supervisor
      {Game.Supervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HangmanLive.Supervisor]
    out = Supervisor.start_link(children, opts)

    #
    # If the database hasn't been populated, do that.
    # This must be done after the Repo is started above.
    #
    if HangmanLive.Word.count == 0 do
      populate_db
    end
    out
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HangmanLiveWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @doc since: "1.1.0"
  defp populate_db do
    dictionary_file = Path.join(:code.priv_dir(:hangman_live), "static/dictionary.txt")
    case File.read(dictionary_file) do
      {:ok, body}      -> add_words(body)
      {:error, reason} -> Logger.error "Couldn't read file: #{reason}"
                          []
    end
  end

  @doc since: "1.1.0"
  defp add_words contents do
    words = contents
    |> String.split("\n", trim: true)

    Enum.filter(words, fn(x) ->
      HangmanLive.Word.create x
    end)
  end

end
