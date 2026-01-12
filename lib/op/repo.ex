defmodule OP.Repo do
  use Ecto.Repo,
    otp_app: :op,
    adapter: Ecto.Adapters.SQLite3
end
