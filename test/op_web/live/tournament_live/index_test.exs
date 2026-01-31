defmodule OPWeb.TournamentLive.IndexTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.TournamentsFixtures

  describe "list view (default)" do
    test "renders card grid by default", %{conn: conn} do
      tournament_fixture(nil, %{name: "Test Tourney"})

      {:ok, _lv, html} = live(conn, ~p"/tournaments")
      assert html =~ "Test Tourney"
      assert html =~ "tournaments-wrapper"
    end

    test "does not render calendar grid by default", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/tournaments")
      refute html =~ "Previous month"
    end
  end

  describe "calendar view" do
    test "renders calendar grid when view=calendar", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/tournaments?view=calendar")
      assert html =~ "Sun"
      assert html =~ "Mon"
      assert html =~ "Sat"
    end

    test "tournament appears on correct date cell", %{conn: conn} do
      start_at = DateTime.new!(~D[2025-06-15], ~T[18:00:00], "Etc/UTC")
      tournament_fixture(nil, %{name: "June Tourney", start_at: start_at})

      {:ok, _lv, html} = live(conn, ~p"/tournaments?view=calendar&month=2025-06")
      assert html =~ "June Tourney"
      assert html =~ "June 2025"
    end

    test "month navigation updates URL", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/tournaments?view=calendar&month=2025-06")

      lv
      |> element("a[aria-label='Next month']")
      |> render_click()

      html = render(lv)
      assert html =~ "July 2025"
    end

    test "previous month navigation works", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/tournaments?view=calendar&month=2025-06")

      lv
      |> element("a[aria-label='Previous month']")
      |> render_click()

      html = render(lv)
      assert html =~ "May 2025"
    end
  end

  describe "view toggle" do
    test "toggle between views works", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/tournaments")
      assert html =~ "tournaments-wrapper"

      lv
      |> element("a[aria-label='Calendar view']")
      |> render_click()

      html = render(lv)
      assert html =~ "Sun"
      assert html =~ "Mon"

      lv
      |> element("a[aria-label='List view']")
      |> render_click()

      html = render(lv)
      assert html =~ "tournaments-wrapper"
    end
  end

  describe "filters in calendar mode" do
    test "filters apply in calendar mode", %{conn: conn} do
      start_at = DateTime.new!(~D[2025-06-15], ~T[18:00:00], "Etc/UTC")
      tournament_fixture(nil, %{name: "Findable Tourney", start_at: start_at})
      tournament_fixture(nil, %{name: "Other Event", start_at: start_at})

      {:ok, lv, _html} = live(conn, ~p"/tournaments?view=calendar&month=2025-06")

      lv
      |> form("#tournament-filters", filters: %{search: "Findable"})
      |> render_change()

      html = render(lv)
      assert html =~ "Findable Tourney"
    end

    test "clear filters preserves calendar view", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/tournaments?view=calendar&month=2025-06&search=test")

      lv
      |> element("button.flex.items-center.space-x-0\\.5", "Clear")
      |> render_click()

      html = render(lv)
      # Should still be in calendar mode
      assert html =~ "Sun"
      assert html =~ "Mon"
    end
  end
end
