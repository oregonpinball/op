defmodule OP.TournamentsTest do
  use OP.DataCase

  import OP.AccountsFixtures
  import OP.TournamentsFixtures

  alias OP.Accounts.Scope
  alias OP.Tournaments

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
