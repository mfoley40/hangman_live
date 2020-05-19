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
    Logger.debug "#{__MODULE__} play params: #{inspect params}"
    changeset = HangmanLive.GameParameters.changeset(%HangmanLive.GameParameters{}, params)
      |> Map.put(:action, :insert)

    if changeset.valid? do
      length = String.to_integer(Map.get(params, "length"))
      guesses = String.to_integer(Map.get(params, "guesses"))
      Logger.debug "#{__MODULE__} length: #{length}"
      Logger.debug "#{__MODULE__} guesses: #{guesses}"
      alphabet = Enum.to_list(?a..?z) ++ Enum.to_list(?0..?9)
      id_length = 12
      id = for _ <- 1..id_length, into: "", do: << Enum.random(alphabet) >>
      Logger.debug "#{__MODULE__} Game id: #{id}"
      pid = Game.Supervisor.start [id: String.to_atom(id),
                            word_length: length,
                            number_of_guesses: guesses]
      Logger.debug "#{__MODULE__} Game PID #{inspect pid}"
      guessed = case Game.guessed pid do
        [] -> "none"
        g -> g
      end

      Logger.info "#{inspect guessed} "
      {:noreply, socket
                    |> assign(title: "Make a Guess")
                    |> assign(playing: :true)
                    |> assign(pattern: Game.pattern pid)
                    |> assign(guessed: guessed)
                    |> assign(remaining: Game.guesses_remaining pid)
                    |> assign(word_count: Game.word_count pid)
                    |> assign(pid: pid)}
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
    Game.Supervisor.stop socket.assigns.pid
    changeset = HangmanLive.GameParameters.changeset(%HangmanLive.GameParameters{}, %{"length" => "5", "guesses" => "10"})
    {:noreply, socket
                  |> assign(playing: :false)
                  |> assign(changeset: changeset)
                  |> assign(pid: nil)}
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
    pid = socket.assigns.pid
    if(0 < Game.guesses_remaining(pid) and Game.pattern(pid) =~ "-") do
      Game.make_guess key, pid

      cond do
        Game.guesses_remaining(pid) == 0 ->
          {:noreply, assign(socket, title: "Game Over", pattern: Game.winning_word(pid), guessed: Game.guessed(pid), remaining: Game.guesses_remaining(pid), word_count: Game.word_count(pid))}
        Game.pattern(pid) =~ "-" ->
          {:noreply, assign(socket, pattern: Game.pattern(pid), guessed: Game.guessed(pid), remaining: Game.guesses_remaining(pid), word_count: Game.word_count(pid))}
        :true ->
          {:noreply, assign(socket, title: "You Win!", pattern: Game.pattern(pid), guessed: Game.guessed(pid), remaining: Game.guesses_remaining(pid), word_count: Game.word_count(pid))}
      end
    else
      {:noreply, socket}
    end
  end
end
