defmodule OP.PlayersTest do
  use OP.DataCase

  alias OP.Players
  alias OP.Players.Player

  import OP.PlayersFixtures
  import OP.AccountsFixtures

  describe "list_players/1" do
    test "returns all players" do
      player = player_fixture()
      assert Players.list_players(nil) == [player]
    end

    test "returns empty list when no players" do
      assert Players.list_players(nil) == []
    end
  end

  describe "list_players_with_preloads/1" do
    test "returns players with user preloaded" do
      player = player_fixture()
      [loaded_player] = Players.list_players_with_preloads(nil)
      assert loaded_player.id == player.id
      assert Ecto.assoc_loaded?(loaded_player.user)
    end
  end

  describe "get_player!/2" do
    test "returns the player with given id" do
      player = player_fixture()
      assert Players.get_player!(nil, player.id) == player
    end

    test "raises if player not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Players.get_player!(nil, -1)
      end
    end
  end

  describe "get_player_by_slug!/2" do
    test "returns the player with given slug" do
      player = player_fixture()
      loaded_player = Players.get_player_by_slug!(nil, player.slug)
      assert loaded_player.id == player.id
      assert Ecto.assoc_loaded?(loaded_player.user)
    end

    test "raises if player not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Players.get_player_by_slug!(nil, "nonexistent-slug")
      end
    end
  end

  describe "get_player_by_slug/2" do
    test "returns the player with given slug" do
      player = player_fixture()
      assert Players.get_player_by_slug(nil, player.slug).id == player.id
    end

    test "returns nil if player not found" do
      assert Players.get_player_by_slug(nil, "nonexistent-slug") == nil
    end
  end

  describe "create_player/2" do
    test "creates a player with valid data" do
      assert {:ok, %Player{} = player} = Players.create_player(nil, %{name: "Test Player"})
      assert player.name == "Test Player"
      assert player.slug != nil
    end

    test "returns error changeset with invalid data" do
      assert {:error, %Ecto.Changeset{}} = Players.create_player(nil, %{name: nil})
    end

    test "generates a unique slug" do
      {:ok, player1} = Players.create_player(nil, %{name: "Player One"})
      {:ok, player2} = Players.create_player(nil, %{name: "Player Two"})
      assert player1.slug != player2.slug
    end
  end

  describe "update_player/3" do
    test "updates the player with valid data" do
      player = player_fixture()
      assert {:ok, %Player{} = updated} = Players.update_player(nil, player, %{name: "Updated"})
      assert updated.name == "Updated"
    end

    test "returns error changeset with invalid data" do
      player = player_fixture()
      assert {:error, %Ecto.Changeset{}} = Players.update_player(nil, player, %{name: nil})
    end
  end

  describe "delete_player/2" do
    test "deletes the player" do
      player = player_fixture()
      assert {:ok, %Player{}} = Players.delete_player(nil, player)
      assert_raise Ecto.NoResultsError, fn -> Players.get_player!(nil, player.id) end
    end
  end

  describe "scrub_player/2" do
    test "anonymizes player data" do
      player = player_fixture(nil, %{name: "Real Name", external_id: "ext-123"})
      user = user_fixture()
      {:ok, player} = Players.link_user(nil, player, user.id)

      assert {:ok, %Player{} = scrubbed} = Players.scrub_player(nil, player)
      assert scrubbed.name == "Deleted Player"
      assert scrubbed.external_id == nil
      assert scrubbed.user_id == nil
      assert scrubbed.slug != nil
      # Slug should be regenerated
      assert scrubbed.slug != player.slug
    end

    test "generates unique slug for each scrubbed player" do
      player1 = player_fixture(nil, %{name: "Player One"})
      player2 = player_fixture(nil, %{name: "Player Two"})

      {:ok, scrubbed1} = Players.scrub_player(nil, player1)
      {:ok, scrubbed2} = Players.scrub_player(nil, player2)

      assert scrubbed1.name == "Deleted Player"
      assert scrubbed2.name == "Deleted Player"
      assert scrubbed1.slug != scrubbed2.slug
    end
  end

  describe "link_user/3" do
    test "links a user to a player" do
      player = player_fixture()
      user = user_fixture()

      assert {:ok, %Player{} = linked} = Players.link_user(nil, player, user.id)
      assert linked.user_id == user.id
    end
  end

  describe "unlink_user/2" do
    test "unlinks user from player" do
      player = player_fixture()
      user = user_fixture()
      {:ok, player} = Players.link_user(nil, player, user.id)
      assert player.user_id == user.id

      assert {:ok, %Player{} = unlinked} = Players.unlink_user(nil, player)
      assert unlinked.user_id == nil
    end
  end

  describe "change_player/2" do
    test "returns a changeset" do
      player = player_fixture()
      assert %Ecto.Changeset{} = Players.change_player(player)
    end
  end

  describe "search_players/2" do
    test "finds players by partial name match" do
      player_fixture(nil, %{name: "John Doe"})
      player_fixture(nil, %{name: "Jane Smith"})

      results = Players.search_players(nil, "john")
      assert length(results) == 1
      assert hd(results).name == "John Doe"
    end

    test "search is case insensitive" do
      player_fixture(nil, %{name: "John Doe"})

      assert length(Players.search_players(nil, "JOHN")) == 1
      assert length(Players.search_players(nil, "john")) == 1
    end

    test "returns empty list for no matches" do
      player_fixture(nil, %{name: "John Doe"})

      assert Players.search_players(nil, "xyz") == []
    end

    test "returns empty list for empty query" do
      player_fixture(nil, %{name: "John Doe"})

      assert Players.search_players(nil, "") == []
    end
  end
end
