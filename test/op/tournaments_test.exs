defmodule OP.TournamentsTest do
  use OP.DataCase

  import Ecto.Changeset
  import OP.AccountsFixtures
  import OP.TournamentsFixtures

  alias OP.Accounts.Scope
  alias OP.Tournaments
  alias OP.Tournaments.Tournament

  describe "create_tournament/2" do
    test "sets created_by_id and updated_by_id from scope" do
      user = user_fixture()
      scope = Scope.for_user(user)

      {:ok, tournament} =
        Tournaments.create_tournament(scope, valid_tournament_attributes())

      assert tournament.created_by_id == user.id
      assert tournament.updated_by_id == user.id
    end

    test "works without a scope (nil)" do
      {:ok, tournament} =
        Tournaments.create_tournament(nil, valid_tournament_attributes())

      assert tournament.created_by_id == nil
      assert tournament.updated_by_id == nil
    end
  end

  describe "update_tournament/3" do
    test "sets updated_by_id from scope" do
      user = user_fixture()
      scope = Scope.for_user(user)
      tournament = tournament_fixture()

      {:ok, updated} =
        Tournaments.update_tournament(scope, tournament, %{name: "Updated"})

      assert updated.updated_by_id == user.id
    end

    test "does not change created_by_id on update" do
      creator = user_fixture()
      updater = user_fixture()
      creator_scope = Scope.for_user(creator)
      updater_scope = Scope.for_user(updater)

      {:ok, tournament} =
        Tournaments.create_tournament(creator_scope, valid_tournament_attributes())

      {:ok, updated} =
        Tournaments.update_tournament(updater_scope, tournament, %{name: "Updated"})

      assert updated.created_by_id == creator.id
      assert updated.updated_by_id == updater.id
    end
  end

  describe "list_organized_tournaments_paginated/2" do
    import OP.PlayersFixtures

    test "returns only tournaments organized by the user" do
      user = user_fixture()
      scope = Scope.for_user(user)
      other_user = user_fixture()

      tournament_fixture(nil, %{name: "Mine", organizer_id: user.id})
      tournament_fixture(nil, %{name: "Theirs", organizer_id: other_user.id})

      {tournaments, _pagination} = Tournaments.list_organized_tournaments_paginated(scope)

      assert length(tournaments) == 1
      assert hd(tournaments).name == "Mine"
    end

    test "returns empty list when user has no organized tournaments" do
      user = user_fixture()
      scope = Scope.for_user(user)

      {tournaments, _pagination} = Tournaments.list_organized_tournaments_paginated(scope)
      assert tournaments == []
    end
  end

  describe "Tournament changeset - matchplay URLs" do
    test "converts qualifying URL to external_id and external_url" do
      changeset =
        Tournament.changeset(%Tournament{}, %{
          name: "Test",
          start_at: DateTime.utc_now() |> DateTime.truncate(:second),
          qualifying_matchplay_url: "https://app.matchplay.events/tournaments/12345"
        })

      assert get_change(changeset, :external_id) == "matchplay:12345"

      assert get_change(changeset, :external_url) ==
               "https://app.matchplay.events/tournaments/12345"
    end

    test "converts qualifying numeric ID to external_id" do
      changeset =
        Tournament.changeset(%Tournament{}, %{
          name: "Test",
          start_at: DateTime.utc_now() |> DateTime.truncate(:second),
          qualifying_matchplay_url: "99999"
        })

      assert get_change(changeset, :external_id) == "matchplay:99999"

      assert get_change(changeset, :external_url) ==
               "https://app.matchplay.events/tournaments/99999"
    end

    test "converts finals URL to finals_external_id" do
      changeset =
        Tournament.changeset(%Tournament{}, %{
          name: "Test",
          start_at: DateTime.utc_now() |> DateTime.truncate(:second),
          finals_matchplay_url: "https://app.matchplay.events/tournaments/67890"
        })

      assert get_change(changeset, :finals_external_id) == "matchplay:67890"
    end

    test "clearing qualifying URL clears external_id and external_url" do
      changeset =
        Tournament.changeset(
          %Tournament{
            external_id: "matchplay:12345",
            external_url: "https://app.matchplay.events/tournaments/12345"
          },
          %{qualifying_matchplay_url: ""}
        )

      assert get_change(changeset, :external_id) == nil
      assert get_change(changeset, :external_url) == nil
    end

    test "clearing finals URL clears finals_external_id" do
      changeset =
        Tournament.changeset(
          %Tournament{finals_external_id: "matchplay:67890"},
          %{finals_matchplay_url: ""}
        )

      assert get_change(changeset, :finals_external_id) == nil
    end

    test "invalid qualifying input adds changeset error" do
      changeset =
        Tournament.changeset(%Tournament{}, %{
          name: "Test",
          start_at: DateTime.utc_now() |> DateTime.truncate(:second),
          qualifying_matchplay_url: "not-a-valid-input"
        })

      assert {:qualifying_matchplay_url, {"must be a valid Matchplay URL or numeric ID", []}} in changeset.errors
    end

    test "invalid finals input adds changeset error" do
      changeset =
        Tournament.changeset(%Tournament{}, %{
          name: "Test",
          start_at: DateTime.utc_now() |> DateTime.truncate(:second),
          finals_matchplay_url: "garbage"
        })

      assert {:finals_matchplay_url, {"must be a valid Matchplay URL or numeric ID", []}} in changeset.errors
    end

    test "handles URL with trailing path segments" do
      changeset =
        Tournament.changeset(%Tournament{}, %{
          name: "Test",
          start_at: DateTime.utc_now() |> DateTime.truncate(:second),
          qualifying_matchplay_url: "https://app.matchplay.events/tournaments/55550/standings"
        })

      assert get_change(changeset, :external_id) == "matchplay:55550"
    end
  end

  describe "matchplay_url_from_external_id/1" do
    test "reconstructs URL from matchplay external_id" do
      assert Tournament.matchplay_url_from_external_id("matchplay:12345") ==
               "https://app.matchplay.events/tournaments/12345"
    end

    test "returns nil for nil input" do
      assert Tournament.matchplay_url_from_external_id(nil) == nil
    end

    test "returns nil for non-matchplay external_id" do
      assert Tournament.matchplay_url_from_external_id("other:12345") == nil
    end
  end

  describe "list_played_tournaments_paginated/2" do
    import OP.PlayersFixtures

    test "returns only tournaments where user's player has standings" do
      user = user_fixture()
      scope = Scope.for_user(user)
      player = player_fixture(scope, %{name: "My Player"})
      {:ok, player} = OP.Players.link_user(scope, player, user.id)

      tournament = tournament_fixture(nil, %{name: "Played"})
      standing_fixture(tournament, player, %{position: 2})

      other_tournament = tournament_fixture(nil, %{name: "Not Played"})
      other_player = player_fixture(nil, %{name: "Other"})
      standing_fixture(other_tournament, other_player, %{position: 1})

      {tournaments, _pagination} = Tournaments.list_played_tournaments_paginated(scope)

      assert length(tournaments) == 1
      assert hd(tournaments).name == "Played"
    end

    test "returns empty list when user has no linked player" do
      user = user_fixture()
      scope = Scope.for_user(user)

      {tournaments, _pagination} = Tournaments.list_played_tournaments_paginated(scope)
      assert tournaments == []
    end
  end
end
