defmodule HangmanLiveWeb.PageLive do
  @moduledoc """
  A Phoenix LiveView to manage interaction with the Evil Hangman game.
  """
  use HangmanLiveWeb, :live_view

  require Logger

  @doc """
  Initialize the parameters used in the parameter gathering portion
  of the LiveView.
  """
  @doc since: "1.0.0"
  @impl true
  def mount(_params, _session, socket) do
    changeset = HangmanLive.GameParameters.changeset(%HangmanLive.GameParameters{}, %{"length" => "5", "guesses" => "10"})
    {:ok, socket
            |> assign(changeset: changeset)
            |> assign(playing: :false)}
  end

  @doc """
  Validate user input on the view.
  """
  @doc since: "1.0.0"
  @impl true
  def handle_event("validate", %{"game_parameters" => params}, socket) do
    Logger.info "validate #{inspect params}"

    changeset = HangmanLive.GameParameters.changeset(%HangmanLive.GameParameters{}, params)
      |> Map.put(:action, :insert)
    {:noreply, socket
                |> assign(:changeset, %{changeset | action: :insert})}
  end

  @doc """
  The play button was pressed. If the parameters entered by the user are
  valid, extract the word length and number of allowed guesses and start
  the Game.

  Return the assigns required for playing the game.

  If the paramters are not valid, do not start the game.
  REVIEW: Should probably return an assign with why the game isn't starting.
  """
  @doc since: "1.0.0"
  @impl true
  def handle_event("play", %{"game_parameters" => params}, socket) do

    changeset = HangmanLive.GameParameters.changeset(%HangmanLive.GameParameters{}, params)
      |> Map.put(:action, :insert)

    if changeset.valid? do
      length = String.to_integer(Map.get(params, "length"))
      guesses = String.to_integer(Map.get(params, "guesses"))

      Game.Supervisor.start [word_length: length,
                            number_of_guesses: guesses]

      guessed = case Game.guessed do
        [] -> "none"
        g -> g
      end

      Logger.info "#{inspect guessed} "
      {:noreply, socket
                    |> assign(title: "Make a Guess")
                    |> assign(playing: :true)
                    |> assign(pattern: Game.pattern)
                    |> assign(guessed: guessed)
                    |> assign(remaining: Game.guesses_remaining)
                    |> assign(word_count: Game.word_count)}
    else
      {:noreply, socket}
    end
  end

  @doc """
  End the current game and go back to gather parameters for a new Game.
  """
  @doc since: "1.0.0"
  @impl true
  def handle_event("restart", _, socket) do
    Game.Supervisor.stop
    changeset = HangmanLive.GameParameters.changeset(%HangmanLive.GameParameters{}, %{"length" => "5", "guesses" => "10"})
    {:noreply, socket
                  |> assign(playing: :false)
                  |> assign(changeset: changeset)}
  end

  @doc """
  If a character key has been entered, pass the lower case character to the
  Game and return the new assignes.

  If a non-character key is entered, ignore it.
  """
  @doc since: "1.0.0"
  @impl true
  def handle_event("keyup", %{"key" => key}, socket) when (key >= "a" and key <= "z") do
    play_game key, socket
  end
  def handle_event("keyup", %{"key" => key}, socket) when (key >= "A" and key <= "Z") and byte_size(key) == 1 do
    play_game String.downcase(key), socket
  end
  def handle_event("keyup", _, socket) do
    {:noreply, socket}
  end

  #
  # Play the game for the given keystroke.
  #
  # Return any new assigns for the live view.
  #
  defp play_game key, socket do
    if(0 < Game.guesses_remaining and Game.pattern =~ "-") do
      Game.make_guess key

      cond do
        Game.guesses_remaining == 0 ->
          {:noreply, assign(socket, title: "Game Over", pattern: Game.winning_word, guessed: Game.guessed, remaining: Game.guesses_remaining, word_count: Game.word_count)}
        Game.pattern =~ "-" ->
          {:noreply, assign(socket, pattern: Game.pattern, guessed: Game.guessed, remaining: Game.guesses_remaining, word_count: Game.word_count)}
        :true ->
          {:noreply, assign(socket, title: "You Win!", pattern: Game.pattern, guessed: Game.guessed, remaining: Game.guesses_remaining, word_count: Game.word_count)}
      end
    else
      {:noreply, socket}
    end
  end
end
