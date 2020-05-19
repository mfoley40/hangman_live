defmodule HangmanLive.Word do
  @moduledoc """
  The Schema for the words database table.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  require Logger

  @doc """
  The schema for the Words table in the database.
  """
  @doc since: "1.1.0"
  schema "words" do
    field :word, :string
    field :length, :integer, default: 0
    field :used, :boolean, default: :false
    timestamps()
  end

  @fields ~w(word length used)a

  @doc """
  Validate that an actual word is provided and it has at
  least two characters.
  """
  @doc since: "1.1.0"
  def changeset words \\ %HangmanLive.Word{}, attrs do
    words
    |> cast(attrs, @fields)
    |> validate_required([:word])
    |> validate_length(:word, min: 2)
  end

  @doc """
  Add the given word to the Words table in the database.
  """
  @doc since: "1.1.0"
  def create w do
    cs = changeset %{word: w, length: String.length(w)}
    if cs.valid? do
      HangmanLive.Repo.insert(cs)
    else
      cs
    end
  end

  @doc """
  Return a list of all the words in the Words table of the given length.
  Each word in the returned list is a string.
  """
  @doc since: "1.1.0"
  def words_of_length length do
    q = from(i in HangmanLive.Word, select: %{word: i.word},
            where: i.length == ^length and i.used == :false)
    HangmanLive.Repo.all(q)
    |> Enum.map(fn(%{word: w}) ->
      w
    end)
  end

  @doc """
  Query the database for the given word.

  Returns the HangmanLive.Word structure for the word.
  """
  @doc since: "1.1.0"
  def word(w) when is_binary(w) do
    q = from(i in HangmanLive.Word, where: i.word == ^w)
    [h|_t] = HangmanLive.Repo.all(q)
    h
  end

  @doc """
  Mark the given word as used. I.e. change the used field to true.
  """
  @doc since: "1.1.0"
  def mark_as_used(w) when is_binary(w) do
    x = word(w)
    cs = changeset(x, %{used: :true})
    Logger.info "cs: #{inspect cs}\n\n"
    HangmanLive.Repo.update(cs)
  end

  @doc """
  Return a list of words, as strings, which have been previously used.
  A word is marked as used by having it's used field set to true.
  """
  @doc since: "1.1.0"
  def used_words do
    q = from(i in HangmanLive.Word, select: %{word: i.word},
            where: i.used == :true)
    HangmanLive.Repo.all(q)
    |> Enum.map(fn(%{word: w}) ->
      w
    end)
  end

  @doc """
  Return the number of words in the Word table.
  """
  @doc since: "1.1.0"
  def count do
    HangmanLive.Repo.one(from w in HangmanLive.Word, select: count(w.id))
  end

  @doc """
  Reset all the words to not-used.
  A not-used word is identied by having its used field set to false.
  """
  @doc since: "1.1.0"
  def reset_used do
    HangmanLive.Repo.update_all(HangmanLive.Word, set: [used: :false])
  end

  @doc """
  Reset all the words of the given length to not-used.
  A not-used word is identied by having its used field set to false.
  """
  @doc since: "1.1.0"
  def reset_used length do
    q = from(i in HangmanLive.Word, select: %{word: i.word},
            where: i.length == ^length)
    HangmanLive.Repo.update_all(q, set: [used: :false])
  end

  @doc """
  Return all the words in the table.
  """
  @doc since: "1.1.0"
  def dump do
    q = from(i in HangmanLive.Word, select: %{word: i.word})
    HangmanLive.Repo.all(q)
  end
end
