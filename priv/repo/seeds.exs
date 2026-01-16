# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     OP.Repo.insert!(%OP.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query

require Logger

alias OP.Repo
alias OP.Leagues.{League, Season, Ranking}
alias OP.Players.Player
alias OP.Accounts.User
alias OP.Tournaments.{Standing, Tournament}

Logger.info("🌱 Seeding database...")

# Helper function for insert-or-update behavior
# Note: This could have been abstracted to a separate file, but this is simpler for now.
defmodule SeedHelpers do
  def upsert_player(repo, attrs) do
    case repo.get_by(Player, external_id: attrs.external_id) do
      nil ->
        %Player{}
        |> Player.changeset(attrs)
        |> repo.insert!()

      existing ->
        existing
        |> Player.changeset(attrs)
        |> repo.update!()
    end
  end

  def upsert_tournament(repo, attrs) do
    case repo.get_by(Tournament, external_id: attrs.external_id) do
      nil ->
        %Tournament{}
        |> Tournament.changeset(attrs)
        |> repo.insert!()

      existing ->
        existing
        |> Tournament.changeset(attrs)
        |> repo.update!()
    end
  end

  def upsert_user(repo, attrs) do
    case repo.get_by(User, email: attrs.email) do
      nil ->
        %User{}
        |> User.email_changeset(attrs)
        |> repo.insert!()

      existing ->
        existing
        |> User.email_changeset(attrs)
        |> repo.update!()
    end
  end

  def upsert_league(repo, attrs) do
    case repo.get_by(League, slug: attrs.slug) do
      nil ->
        %League{}
        |> League.changeset(attrs)
        |> repo.insert!()

      existing ->
        existing
        |> League.changeset(attrs)
        |> repo.update!()
    end
  end

  def upsert_season(repo, attrs) do
    case repo.get_by(Season, slug: attrs.slug) do
      nil ->
        %Season{}
        |> Season.changeset(attrs)
        |> repo.insert!()

      existing ->
        existing
        |> Season.changeset(attrs)
        |> repo.update!()
    end
  end

  def upsert_ranking(repo, attrs) do
    case repo.get_by(Ranking, player_id: attrs.player_id, season_id: attrs.season_id) do
      nil ->
        %Ranking{}
        |> Ranking.changeset(attrs)
        |> repo.insert!()

      existing ->
        existing
        |> Ranking.changeset(attrs)
        |> repo.update!()
    end
  end
end

# Create sample players (using insert for idempotency)
Logger.info("Creating players...")

player1 =
  SeedHelpers.upsert_player(Repo, %{
    external_id: "player-1",
    name: "Alice Champion"
  })

player2 =
  SeedHelpers.upsert_player(Repo, %{
    external_id: "player-2",
    name: "Bob Wizard"
  })

player3 =
  SeedHelpers.upsert_player(Repo, %{
    external_id: "player-3",
    name: "Charlie Flipper"
  })

player4 =
  SeedHelpers.upsert_player(Repo, %{
    external_id: "player-4",
    name: "Diana Tilt"
  })

player5 =
  SeedHelpers.upsert_player(Repo, %{
    external_id: "player-5",
    name: "Eve Plunger"
  })

player_count = Repo.aggregate(Player, :count)
Logger.info("✓ Created #{player_count} players")

# Seed users from environment variables (development only)
seed_admin_email = System.get_env("SEED_ADMIN_EMAIL")
seed_admin_password = System.get_env("SEED_ADMIN_PASSWORD")
seed_test_email = System.get_env("SEED_TEST_EMAIL")
seed_test_password = System.get_env("SEED_TEST_PASSWORD")

# Create admin user if credentials provided
if seed_admin_email && seed_admin_password do
  Logger.info("Creating admin user from env...")

  SeedHelpers.upsert_user(Repo, %{
    email: seed_admin_email,
    password: seed_admin_password
  })

  Logger.info("✓ Created admin user (#{seed_admin_email})")
else
  Logger.info("⏭ Skipping admin user (SEED_ADMIN_EMAIL/SEED_ADMIN_PASSWORD not set)")
end

# Create test user if credentials provided (linked to Alice Champion)
if seed_test_email && seed_test_password do
  Logger.info("Creating test user from env...")

  test_user =
    SeedHelpers.upsert_user(Repo, %{
      email: seed_test_email,
      password: seed_test_password
    })

  # Link test user to player1
  player1
  |> Ecto.Changeset.change(user_id: test_user.id)
  |> Repo.update!()

  Logger.info("✓ Created test user (#{seed_test_email}) linked to #{player1.name}")
else
  Logger.info("⏭ Skipping test user (SEED_TEST_EMAIL/SEED_TEST_PASSWORD not set)")
end

# Create default admin user
Logger.info("Creating default admin user...")
admin_password = "AdminPassword123!"

admin =
  SeedHelpers.upsert_user(Repo, %{
    email: "admin@example.com",
    password: admin_password,
    role: :system_admin
  })

Logger.info("✓ Created admin user (admin@example.com / #{admin_password})")

# Create sample leagues and seasons
Logger.info("Creating leagues & seasons...")

oregon_league =
  SeedHelpers.upsert_league(Repo, %{
    name: "Oregon Pinball Championship",
    description: "The premier pinball league in Oregon.",
    slug: "oregon-pinball-championship",
    author_id: admin.id
  })

season_open_2026 =
  SeedHelpers.upsert_season(Repo, %{
    name: "2026 Open Season",
    description: "The 2026 Open Season for all players.",
    slug: "2026-open-season",
    year: 2026,
    start_date: ~D[2026-01-01],
    end_date: ~D[2026-12-31],
    league_id: oregon_league.id
  })

season_women_2026 =
  SeedHelpers.upsert_season(Repo, %{
    name: "2026 Women's Season",
    description: "The 2026 Women's Season",
    slug: "2026-womens-season",
    year: 2026,
    start_date: ~D[2026-01-01],
    end_date: ~D[2026-12-31],
    league_id: oregon_league.id
  })

league_count = Repo.aggregate(League, :count)
season_count = Repo.aggregate(Season, :count)
Logger.info("✓ Created #{league_count} leagues and #{season_count} seasons")

# Create sample tournaments (using insert for idempotency)
Logger.info("Creating tournaments...")

tournament1 =
  SeedHelpers.upsert_tournament(Repo, %{
    external_id: "tournament-1",
    name: "World Pinball Championship 2024",
    start_at: ~U[2024-03-15 00:00:00Z],
    event_booster: :major,
    allows_opt_out: false,
    tgp_config: %{
      "qualifying" => %{
        "type" => "limited",
        "meaningfulGames" => 12,
        "fourPlayerGroups" => true
      },
      "finals" => %{
        "formatType" => "match-play",
        "meaningfulGames" => 20,
        "fourPlayerGroups" => true,
        "finalistCount" => 16
      },
      "ballCountAdjustment" => 1.0
    },
    base_value: 32.0,
    tva_rating: 25.0,
    tva_ranking: 50.0,
    total_tva: 75.0,
    tgp: 1.92,
    event_booster_multiplier: 2.0,
    first_place_value: 411.84,
    season_id: season_open_2026.id
  })

tournament2 =
  SeedHelpers.upsert_tournament(Repo, %{
    external_id: "tournament-2",
    name: "Spring Classics 2024",
    start_at: ~U[2024-04-20 00:00:00Z],
    event_booster: :certified,
    allows_opt_out: true,
    tgp_config: %{
      "qualifying" => %{
        "type" => "limited",
        "meaningfulGames" => 7
      },
      "finals" => %{
        "formatType" => "double-elimination",
        "meaningfulGames" => 15,
        "fourPlayerGroups" => false,
        "finalistCount" => 8
      }
    },
    base_value: 28.0,
    tva_rating: 18.5,
    tva_ranking: 32.0,
    total_tva: 50.5,
    tgp: 0.88,
    event_booster_multiplier: 1.25,
    first_place_value: 87.28,
    season_id: season_open_2026.id
  })

tournament3 =
  SeedHelpers.upsert_tournament(Repo, %{
    external_id: "tournament-3",
    name: "Monthly League Finals",
    start_at: ~U[2024-05-10 00:00:00Z],
    event_booster: :none,
    allows_opt_out: false,
    tgp_config: %{
      "qualifying" => %{
        "type" => "none",
        "meaningfulGames" => 0
      },
      "finals" => %{
        "formatType" => "match-play",
        "meaningfulGames" => 10,
        "fourPlayerGroups" => true,
        "finalistCount" => 8
      }
    },
    base_value: 15.0,
    tva_rating: 8.5,
    tva_ranking: 12.0,
    total_tva: 20.5,
    tgp: 0.80,
    event_booster_multiplier: 1.0,
    first_place_value: 28.4,
    season_id: season_women_2026.id
  })

tournament_count = Repo.aggregate(Tournament, :count)
Logger.info("✓ Created #{tournament_count} tournaments")

# Create tournament standings (delete existing first for idempotency)
Logger.info("Creating tournament standings...")

# Delete existing standings for seeded tournaments
from(s in Standing,
  where: s.tournament_id in ^[tournament1.id, tournament2.id, tournament3.id]
)
|> Repo.delete_all()

# World Championship standings
world_championship_standings = [
  %{
    player_id: player1.id,
    tournament_id: tournament1.id,
    position: 1,
    is_finals: true,
    total_points: 411.84,
    linear_points: 41.18,
    dynamic_points: 370.66,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 411.84,
    efficiency: 85.5
  },
  %{
    player_id: player2.id,
    tournament_id: tournament1.id,
    position: 2,
    is_finals: true,
    total_points: 298.45,
    linear_points: 41.18,
    dynamic_points: 257.27,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 298.45,
    efficiency: 72.5
  },
  %{
    player_id: player3.id,
    tournament_id: tournament1.id,
    position: 3,
    is_finals: true,
    total_points: 215.32,
    linear_points: 41.18,
    dynamic_points: 174.14,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 215.32,
    efficiency: 65.2
  },
  %{
    player_id: player4.id,
    tournament_id: tournament1.id,
    position: 5,
    is_finals: true,
    total_points: 125.18,
    linear_points: 41.18,
    dynamic_points: 84.00,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 125.18,
    efficiency: 48.3
  }
]

# Spring Classics standings
spring_classics_standings = [
  %{
    player_id: player2.id,
    tournament_id: tournament2.id,
    position: 1,
    is_finals: true,
    total_points: 87.28,
    linear_points: 8.73,
    dynamic_points: 78.55,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 87.28,
    efficiency: 92.0
  },
  %{
    player_id: player1.id,
    tournament_id: tournament2.id,
    position: 2,
    is_finals: true,
    total_points: 63.25,
    linear_points: 8.73,
    dynamic_points: 54.52,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 63.25,
    efficiency: 78.5
  },
  %{
    player_id: player4.id,
    tournament_id: tournament2.id,
    position: 3,
    is_finals: true,
    total_points: 45.67,
    linear_points: 8.73,
    dynamic_points: 36.94,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 45.67,
    efficiency: 68.2
  },
  %{
    player_id: player5.id,
    tournament_id: tournament2.id,
    position: 6,
    is_finals: true,
    total_points: 18.52,
    linear_points: 8.73,
    dynamic_points: 9.79,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 18.52,
    efficiency: 35.8
  }
]

# Monthly League standings
monthly_league_standings = [
  %{
    player_id: player3.id,
    tournament_id: tournament3.id,
    position: 1,
    is_finals: true,
    total_points: 28.4,
    linear_points: 2.84,
    dynamic_points: 25.56,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 28.4,
    efficiency: 88.5
  },
  %{
    player_id: player4.id,
    tournament_id: tournament3.id,
    position: 2,
    is_finals: true,
    total_points: 20.58,
    linear_points: 2.84,
    dynamic_points: 17.74,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 20.58,
    efficiency: 75.2
  },
  %{
    player_id: player5.id,
    tournament_id: tournament3.id,
    position: 3,
    is_finals: true,
    total_points: 14.85,
    linear_points: 2.84,
    dynamic_points: 12.01,
    age_in_days: 0,
    decay_multiplier: 1.0,
    decayed_points: 14.85,
    efficiency: 62.5
  }
]

# Insert all standings with timestamps
now = DateTime.utc_now() |> DateTime.truncate(:second)

all_standings =
  (world_championship_standings ++ spring_classics_standings ++ monthly_league_standings)
  |> Enum.map(fn standing ->
    Map.merge(standing, %{inserted_at: now, updated_at: now})
  end)

Repo.insert_all(Standing, all_standings)

standing_count = Repo.aggregate(Standing, :count)
Logger.info("✓ Created #{standing_count} tournament standings")

# Calculate season rankings
Logger.info("Calculating season rankings...")

seasons = Repo.all(Season)
total_rankings = 0

for season <- seasons do
  # Get all standings for tournaments in this season
  standings =
    from(s in Standing,
      join: t in Tournament,
      on: s.tournament_id == t.id,
      where: t.season_id == ^season.id,
      preload: [player: []]
    )
    |> Repo.all()

  if standings != [] do
    # Group by player and calculate totals
    player_stats =
      standings
      |> Enum.group_by(& &1.player_id)
      |> Enum.map(fn {player_id, player_standings} ->
        total_decayed_points =
          player_standings
          |> Enum.map(& &1.decayed_points)
          |> Enum.sum()

        event_count = length(player_standings)

        %{
          player_id: player_id,
          total_decayed_points: total_decayed_points,
          event_count: event_count
        }
      end)
      |> Enum.sort_by(& &1.total_decayed_points, :desc)

    # Create season rankings
    player_stats
    |> Enum.with_index(1)
    |> Enum.each(fn {stats, ranking} ->
      is_rated = stats.event_count >= 1
      rating = 1500

      SeedHelpers.upsert_ranking(Repo, %{
        player_id: stats.player_id,
        season_id: season.id,
        ranking: ranking,
        event_count: stats.event_count,
        is_rated: is_rated,
        rating: rating,
        rating_deviation: 200,
        last_rating_update: DateTime.utc_now()
      })
    end)

    total_rankings = total_rankings + length(player_stats)
  end
end

ranking_count = Repo.aggregate(Ranking, :count)

Logger.info(
  "✓ Calculated #{ranking_count} season player rankings across #{length(seasons)} seasons"
)

Logger.info("")
Logger.info("✅ Database seeded successfully!")
Logger.info("")
Logger.info("Summary:")
Logger.info("  - #{Repo.aggregate(Player, :count)} players")
Logger.info("  - #{Repo.aggregate(User, :count)} users")
Logger.info("  - #{Repo.aggregate(League, :count)} leagues")
Logger.info("  - #{Repo.aggregate(Season, :count)} seasons")
Logger.info("  - #{Repo.aggregate(Tournament, :count)} tournaments")
Logger.info("  - #{Repo.aggregate(Standing, :count)} standings")
Logger.info("  - #{Repo.aggregate(Ranking, :count)} season player rankings")
