defmodule Mix.Tasks.Op.RecalculateTgpPoints do
  @moduledoc """
  Recalculates TGP points for all tournaments with meaningful_games set.

  This task is useful for:
  - Backfilling points for tournaments imported before point calculation was added
  - Recalculating all points if the formula changes
  - Fixing any data inconsistencies

  ## Usage

      mix op.recalculate_tgp_points

  ## Options

      --tournament-id ID  Only recalculate for a specific tournament
      --dry-run          Show what would be updated without making changes
  """
  use Mix.Task

  import Ecto.Query

  alias OP.Repo
  alias OP.Tournaments
  alias OP.Tournaments.Tournament

  @shortdoc "Recalculates TGP points for all tournaments"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [tournament_id: :integer, dry_run: :boolean]
      )

    Mix.Task.run("app.start")

    tournament_id = Keyword.get(opts, :tournament_id)
    dry_run = Keyword.get(opts, :dry_run, false)

    tournaments = fetch_tournaments(tournament_id)

    Mix.shell().info("Found #{length(tournaments)} tournament(s) with meaningful_games set")

    if dry_run do
      Mix.shell().info("Dry run mode - no changes will be made")
    end

    Enum.each(tournaments, fn tournament ->
      process_tournament(tournament, dry_run)
    end)

    Mix.shell().info("Done!")
  end

  defp fetch_tournaments(nil) do
    Tournament
    |> where([t], not is_nil(t.meaningful_games) and t.meaningful_games > 0.0)
    |> preload(standings: :player)
    |> Repo.all()
  end

  defp fetch_tournaments(tournament_id) do
    Tournament
    |> where([t], t.id == ^tournament_id)
    |> preload(standings: :player)
    |> Repo.all()
  end

  defp process_tournament(tournament, dry_run) do
    standings_count = length(tournament.standings || [])

    Mix.shell().info(
      "Processing: #{tournament.name} (ID: #{tournament.id}, " <>
        "meaningful_games: #{tournament.meaningful_games}, standings: #{standings_count})"
    )

    if standings_count == 0 do
      Mix.shell().info("  Skipping - no standings")
    else
      if dry_run do
        Mix.shell().info("  Would recalculate #{standings_count} standings")
      else
        case Tournaments.recalculate_standings_points(nil, tournament) do
          {:ok, _} ->
            Mix.shell().info("  Recalculated #{standings_count} standings")

          {:error, reason} ->
            Mix.shell().error("  Error: #{inspect(reason)}")
        end
      end
    end
  end
end
