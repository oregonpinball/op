# Open Pinball (OP)

## Dependencies

* Erlang 24+, ideally latest (OTP 28)
* Elixir 1.18+, ideally latest (1.19)

There is no NodeJS requirement, as this project uses `esbuild` natively and does not have any external build system (e.g. WebPack).

## Setup

The setup was performed on a Ubuntu 24.04 LTS server via SSH.  It will need adjusted for Mac or other environments.

For installation and management of Erlang and Elixir, [asdf](https://asdf-vm.com/) version manager is recommended or [mise](https://mise.jdx.dev/).  A single-version installation (e.g. `brew`) is fine, too, just may run into problems down the road if Erlang/Elixir versions change.

Installation of Erlang happens first, as Elixir depends on it.  To install via `asdf`:

1. Before you install anything, [ensure the Erlang requirements are installed](https://github.com/asdf-vm/asdf-erlang?tab=readme-ov-file#before-asdf-install).
    * On Ubuntu, the specific command ran was the entire `apt-get` under [their documentation for it](https://github.com/asdf-vm/asdf-erlang?tab=readme-ov-file#ubuntu-2404-lts).
    * Note that Mac OS has a dedicated section in the notes.
2. Install `asdf` via [their documentation](https://asdf-vm.com/guide/getting-started.html) in whatever method is easiest for your platform.
3. `asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git`
4. `asdf erlang install 28.3`
5. `asdf set -u erlang 28.3`
6. `asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git`
7. `asdf elixir install 1.19.5-otp-28`
8. `asdf set -u elixir 1.19.5-opt-28`

## Starting your server

From the root directory (what you cloned from Git), run:

1. `mix ecto.reset`
    * This should create, migrate, and seed your SQLite3 database (in `/db`).
        * `mix ecto.create`, `mix ecto.migrate`, `mix ecto.seed`
2. `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.