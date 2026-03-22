defmodule AshPop.Repo do
  use Ecto.Repo,
    otp_app: :ash_pop,
    adapter: Ecto.Adapters.SQLite3
end
