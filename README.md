# HangmanLive

A LiveView frontend on the Evil Hangman game. (https://github.com/mfoley40/hangman)
This is the classic hangman game with a twist. The word selected isn't
chosen until the last moment possible. There is a word dictionary with
approximately 120,000 words. After each letter guess is made,
(and the word length during the game setup) the list of possible
outcomes is chosen such that the largest number of words remain. If the
word isn't guessed in the allotted number of guesses, a random word is
selected from the remaining list of possible solutions.

Added a PostgreSQL database. This was to learn about using Ecto in
Elixir. The database is a bit of a stretch for this application. There is
one table which loads in the list of words from the dictionary file. To
make database usage somewhat viable, the word table contains a boolean flag
which is set to true after a word is used. Thus words are not repeated
until after all the words of a given length have been used. Then the flag
for words of that length is reset and the process starts over.

# Next Steps
Currently the game is shared amongst all browsers pointing at the site.
For a game, there should be a new instance for each browser. Not too
important when running a single instance on a PC, but to make this a more
realistic solution, that will be updated.

# NOTES:
This project was implemented as an educational program to help learn
Phoenix LiveView, Ecto and their tools. Currently there aren't any tests.

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

## postgresql Database Information

The database needs to be installed and started before doing any of the
Ecto table creation or other interactions.

Simple database user and password is stored in the configuration file.
This isn't secure for anything other than an test environment.

Nice information on installing on Mac:
  https://wiki.postgresql.org/wiki/Homebrew

  To create a user:
    createuser --interactive --pwprompt

  To have launchd start postgresql now and restart at login:
    brew services start postgresql
  Or, if you don't want/need a background service you can just run:
    pg_ctl -D /usr/local/var/postgres start

  To see if the database is running
    ps auxwww | grep postgres

  Ecto database table manipulations:
    mix ecto.migrate
    mix ecto.rollback

  To clear the word table:
    HangmanLive.Repo.delete_all(HangmanLive.Word)
