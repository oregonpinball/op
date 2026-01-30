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

    test "auto-generates a number" do
      {:ok, player} = Players.create_player(nil, %{name: "Numbered Player"})
      assert player.number != nil
      assert player.number >= 1000 and player.number <= 9999
    end

    test "two players get different numbers" do
      {:ok, p1} = Players.create_player(nil, %{name: "Player A"})
      {:ok, p2} = Players.create_player(nil, %{name: "Player B"})
      assert p1.number != p2.number
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

    test "preserves number through updates" do
      player = player_fixture()
      original_number = player.number
      {:ok, updated} = Players.update_player(nil, player, %{name: "Updated"})
      assert updated.number == original_number
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

  describe "list_players_paginated/2" do
    test "returns paginated results with defaults" do
      for i <- 1..25 do
        player_fixture(nil, %{name: "Player #{String.pad_leading("#{i}", 2, "0")}"})
      end

      result = Players.list_players_paginated(nil)

      assert result.page == 1
      assert result.per_page == 20
      assert result.total_count == 25
      assert result.total_pages == 2
      assert length(result.players) == 20
    end

    test "returns correct page when specified" do
      for i <- 1..25 do
        player_fixture(nil, %{name: "Player #{String.pad_leading("#{i}", 2, "0")}"})
      end

      result = Players.list_players_paginated(nil, page: 2)

      assert result.page == 2
      assert length(result.players) == 5
    end

    test "respects custom page_size" do
      for i <- 1..15 do
        player_fixture(nil, %{name: "Player #{String.pad_leading("#{i}", 2, "0")}"})
      end

      result = Players.list_players_paginated(nil, page_size: 5)

      assert result.per_page == 5
      assert result.total_pages == 3
      assert length(result.players) == 5
    end

    test "filters by search term" do
      player_fixture(nil, %{name: "John Doe"})
      player_fixture(nil, %{name: "Jane Smith"})
      player_fixture(nil, %{name: "Bob Johnson"})

      result = Players.list_players_paginated(nil, search: "john")

      assert result.total_count == 2
      names = Enum.map(result.players, & &1.name)
      assert "John Doe" in names
      assert "Bob Johnson" in names
    end

    test "search is case insensitive" do
      player_fixture(nil, %{name: "John Doe"})

      result = Players.list_players_paginated(nil, search: "JOHN")

      assert result.total_count == 1
    end

    test "filters by linked status - linked" do
      user = user_fixture()
      linked_player = player_fixture(nil, %{name: "Linked Player"})
      {:ok, _} = Players.link_user(nil, linked_player, user.id)
      _unlinked_player = player_fixture(nil, %{name: "Unlinked Player"})

      result = Players.list_players_paginated(nil, linked: "linked")

      assert result.total_count == 1
      assert hd(result.players).name == "Linked Player"
    end

    test "filters by linked status - unlinked" do
      user = user_fixture()
      linked_player = player_fixture(nil, %{name: "Linked Player"})
      {:ok, _} = Players.link_user(nil, linked_player, user.id)
      _unlinked_player = player_fixture(nil, %{name: "Unlinked Player"})

      result = Players.list_players_paginated(nil, linked: "unlinked")

      assert result.total_count == 1
      assert hd(result.players).name == "Unlinked Player"
    end

    test "combines search and filter" do
      user = user_fixture()
      linked_john = player_fixture(nil, %{name: "John Linked"})
      {:ok, _} = Players.link_user(nil, linked_john, user.id)
      _unlinked_john = player_fixture(nil, %{name: "John Unlinked"})
      _linked_jane = player_fixture(nil, %{name: "Jane Linked"})

      result = Players.list_players_paginated(nil, search: "john", linked: "linked")

      assert result.total_count == 1
      assert hd(result.players).name == "John Linked"
    end

    test "returns empty result for no matches" do
      player_fixture(nil, %{name: "Test Player"})

      result = Players.list_players_paginated(nil, search: "nonexistent")

      assert result.total_count == 0
      assert result.players == []
      assert result.total_pages == 1
    end

    test "preloads user association" do
      user = user_fixture()
      player = player_fixture(nil, %{name: "Player With User"})
      {:ok, _} = Players.link_user(nil, player, user.id)

      result = Players.list_players_paginated(nil)

      loaded_player = hd(result.players)
      assert Ecto.assoc_loaded?(loaded_player.user)
      assert loaded_player.user.id == user.id
    end

    test "orders by name ascending" do
      player_fixture(nil, %{name: "Zack"})
      player_fixture(nil, %{name: "Alice"})
      player_fixture(nil, %{name: "Mike"})

      result = Players.list_players_paginated(nil)

      names = Enum.map(result.players, & &1.name)
      assert names == ["Alice", "Mike", "Zack"]
    end

    test "handles page number less than 1" do
      player_fixture(nil, %{name: "Test"})

      result = Players.list_players_paginated(nil, page: 0)
      assert result.page == 1

      result = Players.list_players_paginated(nil, page: -5)
      assert result.page == 1
    end

    test "ignores empty search string" do
      player_fixture(nil, %{name: "Test"})

      result = Players.list_players_paginated(nil, search: "")

      assert result.total_count == 1
    end

    test "ignores empty linked filter" do
      player_fixture(nil, %{name: "Test"})

      result = Players.list_players_paginated(nil, linked: "")

      assert result.total_count == 1
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
