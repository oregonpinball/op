defmodule OPWeb.TD.TournamentLiveTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.AccountsFixtures
  import OP.TournamentsFixtures

  describe "Index - Authorization" do
    test "redirects non-authenticated users to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/td/tournaments")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects regular users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, redirect} = live(conn, ~p"/td/tournaments")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You must be an admin to access this page."} = flash
    end

    test "allows system_admin users to access", %{conn: conn} do
      user = admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/td/tournaments")
      assert html =~ "Tournaments"
    end

    test "allows td users to access", %{conn: conn} do
      user = td_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/td/tournaments")
      assert html =~ "Tournaments"
    end
  end

  describe "Index" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "lists all tournaments", %{conn: conn} do
      tournament = tournament_fixture(%{name: "Test Tournament"})

      {:ok, _lv, html} = live(conn, ~p"/td/tournaments")

      assert html =~ "Tournaments"
      assert html =~ tournament.name
    end

    test "shows empty state when no tournaments", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/td/tournaments")

      assert html =~ "No tournaments found"
    end

    test "navigates to new tournament form", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/td/tournaments")

      assert lv |> element("a", "New Tournament") |> render_click() =~
               "New Tournament"
    end
  end

  describe "Create Tournament" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "creates a new tournament with valid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/td/tournaments/new")

      start_at =
        DateTime.utc_now()
        |> DateTime.add(1, :day)
        |> DateTime.truncate(:second)
        |> Calendar.strftime("%Y-%m-%dT%H:%M")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "name" => "New Test Tournament",
          "start_at" => start_at
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/td/tournaments")

      html = render(lv)
      assert html =~ "Tournament created successfully"
      assert html =~ "New Test Tournament"
    end

    test "shows validation errors with invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/td/tournaments/new")

      result =
        lv
        |> form("#tournament-form", %{
          "tournament" => %{
            "name" => ""
          }
        })
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end
  end

  describe "Update Tournament" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      tournament = tournament_fixture(%{name: "Original Name"})
      %{conn: log_in_user(conn, user), user: user, tournament: tournament}
    end

    test "updates tournament with valid data", %{conn: conn, tournament: tournament} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      lv
      |> form("#tournament-form", %{
        "tournament" => %{
          "name" => "Updated Name"
        }
      })
      |> render_submit()

      assert_patch(lv, ~p"/td/tournaments")

      html = render(lv)
      assert html =~ "Tournament updated successfully"
      assert html =~ "Updated Name"
    end

    test "shows validation errors with invalid data", %{conn: conn, tournament: tournament} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}/edit")

      result =
        lv
        |> form("#tournament-form", %{
          "tournament" => %{
            "name" => ""
          }
        })
        |> render_change()

      assert result =~ "can&#39;t be blank"
    end
  end

  describe "Delete Tournament" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      tournament = tournament_fixture(%{name: "Tournament to Delete"})
      %{conn: log_in_user(conn, user), user: user, tournament: tournament}
    end

    test "deletes tournament from list", %{conn: conn, tournament: tournament} do
      {:ok, lv, html} = live(conn, ~p"/td/tournaments")

      assert html =~ tournament.name

      lv
      |> element("button", "Delete")
      |> render_click()

      refute render(lv) =~ tournament.name
    end
  end

  describe "Show Tournament" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      tournament = tournament_fixture(%{name: "Show Tournament", description: "Test description"})
      %{conn: log_in_user(conn, user), user: user, tournament: tournament}
    end

    test "displays tournament details", %{conn: conn, tournament: tournament} do
      {:ok, _lv, html} = live(conn, ~p"/admin/tournaments/#{tournament}")

      assert html =~ tournament.name
      assert html =~ "Tournament details"
    end

    test "navigates to edit from show page", %{conn: conn, tournament: tournament} do
      {:ok, lv, _html} = live(conn, ~p"/admin/tournaments/#{tournament}")

      assert lv |> element("a", "Edit Tournament") |> render_click() =~
               "Edit Tournament"
    end

    test "redirects non-admin users", %{tournament: tournament} do
      user = user_fixture()
      non_admin_conn = log_in_user(build_conn(), user)

      assert {:error, redirect} = live(non_admin_conn, ~p"/admin/tournaments/#{tournament}")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/"
    end
  end
end
