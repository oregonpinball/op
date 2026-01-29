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
end
