#<editor-fold desc='Game.Supervisor Module'>
defmodule Game.Supervisor do
  @moduledoc """
  The Supervisor of the Game logic module

  © Innovative Yachtter Solutions, 2020
  """
  @moduledoc since: "1.0.0"

  use Supervisor
  require Logger

  @name __MODULE__

  def start_link _args do
    Supervisor.start_link(__MODULE__, [], name: @name)
  end

  @doc """
  Start the child process with the default name
  """
  def start (args \\ []) do
    #Logger.info "#{__MODULE__} start args: #{inspect args}"
    case Supervisor.start_child(@name, [args]) do
      {:ok, pid} -> Logger.info("#{__MODULE__} pid: #{inspect pid}")
      {:error, err} -> Logger.warn("#{__MODULE__} #{inspect err}")
      _ -> Logger.error("#{__MODULE__} What did start_child return?")
    end
  end

  @doc """
  Stop the child process
  """
  def stop do
    pid = Process.whereis(:game)
    Supervisor.terminate_child(@name, pid)
  end

  @impl true
  def init(_args) do
    #Logger.info("#{__MODULE__} Init args #{inspect args}")

    Process.flag(:trap_exit, true)

    children = [
      worker(Game, [])
    ]
    opts = [strategy: :simple_one_for_one, name: Game]
    supervise(children, opts)
  end
end
#</editor-fold>


#<editor-fold desc='Game Module'>
defmodule Game do
  @moduledoc """
  The game logic for `Evil Hangman`.
  """
  @moduledoc since: "1.0.0"

  use GenServer
  require Logger

  @no_word_length [23, 25, 26, 27]

   #<editor-fold desc='Module State'>
   defmodule State do
     @moduledoc """
     Process state
     """
     @enforce_keys [:words]
     defstruct [:words,     # List of possible words in solution
       :word_length,        # The length of the word to be guessed
       :pattern,            # The pattern of the word and guesses
       :guesses,            # The number of guesses left before loosing
       :guessed            # Letters which have been guessed
   ]

   defimpl String.Chars do
     def to_string(state) do
       "State[patter: #{state.patter} guesses: #{state.guesses}" <>
       " guessed: #{inspect state.guessed} words left: #{length(state.words)}]"
     end
   end
   end
   #</editor-fold>


  def start(args \\ []) do
    #Logger.info "#{__MODULE__} start args: #{inspect args}"
    id = Keyword.get args, :id, :game
    GenServer.start __MODULE__, args, [name: id]
  end


  @doc """
  Start our server.

  ### Example

  We assert that start link gives :ok, pid

      iex> Game.start_link
      {:ok, pid}
  """
  def start_link(args \\ []) do
    #Logger.info "#{__MODULE__} start_link args: #{inspect args}"
    id = Keyword.get args, :id, :game
    case GenServer.start_link __MODULE__, args, [name: id] do
      {:error, {:already_started, pid}} ->
        Logger.error "Game already running on: #{inspect pid}"
        {:ok, pid}
      ret ->
        ret
    end
  end


  #<editor-fold desc='Init'>
  @doc """
  Game initialization.

  The args passed to the function is a Keyword list with the
  game's configuration settings. The dictionary must contain:

      :word_length        The length of the word to be guessed
      :number_of_guesses  The number of guesses which are allowed before
                          the game is lost.

  There isn't ANY error checking on these settings. Wrong values will
  crash the game.
  """
  @doc since: "1.0.0"
  @impl true
  def init(argument_dictionary)
  def init(args) do
     #Logger.info "#{__MODULE__} Initing args: #{inspect args}"

    word_length = Keyword.get args, :word_length, nil
     if word_length == nil do
       raise ArgumentError, message: ":word_length paramater not provided"
     end

     #
     # REVIEW: Pretty bad solution for hanling when a lengh for which
     #         there aren't any words given. Throw error instead?
     #
     word_length = if word_length in @no_word_length do
       24
     else
       word_length
     end

     number_of_guesses = Keyword.get args, :number_of_guesses, nil
      if number_of_guesses == nil do
        raise ArgumentError, message: ":number_of_guesses paramater not provided"
      end

     words = HangmanLive.Word.words_of_length word_length
     words = if length(words) == 0 do
       HangmanLive.Word.reset_used word_length
       HangmanLive.Word.words_of_length word_length
     else
       words
     end

     pattern = Enum.reduce(1..word_length, "", fn(_x, acc) ->
       acc <> "- "
     end)
     |> String.trim

    #
    # Register to get a terminate callback when shutting down
    #
    Process.flag(:trap_exit, true)

    state = %State {
      words: words,
      pattern: pattern,
      word_length: word_length,
      guesses: number_of_guesses,
      guessed: []
    }
     {:ok, state}
  end
  #</editor-fold>


  #<editor-fold desc='Client API'>
  @doc """
  Return the number of potential words still available
  to be the solution for the game.
  """
  def word_count pid \\ :game do
    GenServer.call pid, {:get_word_count}
  end

  @doc """
  Return the "pattern" for the possible solution word
  and the guesses already made. In the pattern, a '-'
  character represents an unguessed spot in the word.
  If a position has been guessed, that letter is in the patter.

  ### Example

  If the word is "apple" and the current guesses are 'a' and 'e'
  the pattern is

  "a - - - e"

  This is a synchronise call.
  """
  @doc since: "1.0.0"
  def pattern pid \\ :game do
    GenServer.call pid, {:get_pattern}
  end

  @doc """
  Return the list of guessed letters.

  This is a synchronise call.
  """
  @doc since: "1.0.0"
  def guessed pid \\ :game do
    GenServer.call pid, {:get_guessed}
  end

  @doc """
  Return the number of guesses remaining until the game is lost.

  This is a synchronise call.
  """
  def guesses_remaining pid \\ :game do
    GenServer.call pid, {:get_guesses_remaining}
  end

  @doc """
  Perform a guess with the given character, guess.

  Return the updated pattern for the potential solution word.

  This is a synchronise call.
  """
  @doc since: "1.0.0"
  def make_guess guess, pid \\ :game do
    GenServer.call pid, {:guess, guess}
  end

  @doc """
  Return the winning word. This function is intended to be
  used after the game is over to recover the solution if the game
  was lost. However, that isn't enforced. The winning word
  is chosen at random from the set of possible solutions. Thus,
  calling this function multiple times could lead to different
  words being returned.

  This is a synchronise call.
  """
  @doc since: "1.0.0"
  def winning_word pid \\ :game do
    GenServer.call pid, {:get_winning_word}
  end
  #</editor-fold>


  #<editor-fold desc='Server API'>
  @impl true
  def handle_call({:get_word_count}, _from, %{words: words} = state) do
    {:reply, length(words), state}
  end

  @impl true
  def handle_call({:get_pattern}, _from, %{pattern: pattern} = state) do
    {:reply, pattern, state}
  end

  @impl true
  def handle_call({:get_guessed}, _from, %{guessed: guessed} = state) do
    {:reply, guessed, state}
  end

  @impl true
  def handle_call({:get_guesses_remaining}, _from, %{guesses: guesses} = state) do
    {:reply, guesses, state}
  end

  @impl true
  def handle_call({:get_winning_word}, _from, %{words: words} = state) do
    #
    # The winning word is chosen at random from the possible remaining solutions.
    #
    rand = :random.uniform(length(words)) - 1
    word = Enum.at(words, rand)

    HangmanLive.Word.mark_as_used word

    {:reply, word, state}
  end

  @impl true
  def handle_call({:guess, guess}, _from, %{guesses: guesses, guessed: guessed} = state)
  when 0 < guesses do

    updated_state = if (guess in guessed) do
      state
    else
      process_guess guess, state
    end

    unless updated_state.pattern =~ "-" do
      #
      # Game was won, mark word as used.
      #
      word = String.replace updated_state.pattern, " ", ""
      HangmanLive.Word.mark_as_used word
    end

    #
    # Return the new pattern and updated state.
    #
    {:reply, updated_state.pattern, updated_state}
  end

  @doc """
  No more guesses left, just return the same pattern.
  """
  def handle_call({:guess, _guess}, _from, %{pattern: pattern} =state) do
    {:reply, pattern, state}
  end
  #</editor-fold>


  #<editor-fold desc='Private Methods'>

  defp process_guess guess, %{words: words, pattern: pattern, guesses: guesses, guessed: guessed} = state do
    #
    # Add the guess to the list of guessed words.
    # NOTE: The list is formatted for output here, but that probably should be
    #       done in a client, or getter function, and only have the list of
    #       guessed letters be that.
    updated_guessed = case length(guessed) do
      0 -> [guess]
      _ -> guessed ++ [", ", guess]
    end

    #
    # Create a map of potential solutions. The element in the map with
    # the most possible solutions is chosen as the next set of potential
    # solutions and the pattern for that item becomes the word pattern.
    #
    map = map_words words, pattern, guess
    {p, w} = Enum.reduce(map, {"", []}, fn({k, v}, {acck, accv}) ->
      if length(accv) < length(v) do
        {k, v}
      else
        {acck, accv}
      end
    end)

    #
    # If the guessed letter isn't in the solution, a guess is used up.
    # decrement the guesses cound.
    #
    updated_guesses = case guess in String.split(p, "") do
      :true -> guesses
      :false -> guesses - 1
    end

    #
    # Return the updated state.
    #
    %{state | words: w, pattern: p, guesses: updated_guesses, guessed: updated_guessed}
  end

  #
  # Create a map from the set of potential word solutions. Each item
  # in the map has the word pattern as the key and a list of words
  # which conform to that pattern as the value.
  #
  # Return the created map.
  #
  defp map_words words, pattern, guess do
    words
    |> Enum.reduce(%{}, fn(x, acc) ->
      word_pattern = make_pattern pattern, x, guess
      case acc[word_pattern] do
        nil -> Map.put(acc, word_pattern, [x])
        v -> Map.put(acc, word_pattern, [x] ++ v)
      end
    end)
  end

  #
  # Make the pattern for the given word.
  #
  # Each character in the word is compared to the given guess.
  # If they match, the guess is added to the patter.
  # If they don't match, whatever was in the existing, given pattern,
  # are added to the new patter. Thus, previous guesses will remain
  # in the patter.
  #
  # Return the updated pattern for the given word.
  #
  defp make_pattern(pattern, word, guess)
  when is_binary(pattern) and is_binary(word) and is_binary(guess) do
    {s, _} = String.graphemes(word)
    |> Enum.reduce({"", pattern <> " "}, fn(c, {acc, p}) ->
      <<head :: binary-size(2)>> <> rest = p
      case c == guess do
        :true -> {acc <> "#{c} ", rest}
        :false -> {acc <> head, rest}
      end
    end)
    String.trim(s)
  end
  #</editor-fold>


  #<editor-fold desc='terminate Functions'>
  #
  # handle the trapped exit call
  #
  # Not really used here.
  #
  @impl true
  def terminate(:shutdown, _state) do
    :normal
  end

  #
  # handle the trapped exit call
  #
  @impl true
  def terminate(reason, state) do
    Logger.error("#{__MODULE__} terminate reason: #{inspect reason} state #{inspect state}")
    :error
  end
  #</editor-fold>
end
#</editor-fold>
