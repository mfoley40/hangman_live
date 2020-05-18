# HangmanLive

A LiveView frontend on the Evil Hangman game. This is the classic hangman game
with a twist. The word selected isn't chosen until the last moment possible.
There is a word dictionary with approximately 120,000 words. After each
letter guess is made, (and the word length during the game setup) the list of
possible outcomes is chosen such that the largest number of words remain.
If the word isn't guessed in the allotted number of guesses, a random word
is selected from the remaining list of possible solutions.

# NOTES:
This project was implemented as an educational program to help learn
Phoenix LiveView and it's tools. Currently there aren't any tests.

To start your Phoenix server:

  * Start Phoenix endpoint with `mix phx.server`

  You can also run your app inside IEx (Interactive Elixir) as:
      $ iex -S mix phx.server

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
  * LiveView: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
