defmodule OPWeb.TournamentLive.SubmitTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.AccountsFixtures
  import OP.TournamentsFixtures

  describe "Authorization" do
    test "redirects non-authenticated users to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/tournaments/submit")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end

    test "redirects regular users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, redirect} = live(conn, ~p"/tournaments/submit")
      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/"
    end

    test "allows system_admin users to access", %{conn: conn} do
      user = admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/tournaments/submit")
      assert html =~ "Submit Tournament"
    end

    test "allows td users to access", %{conn: conn} do
      user = td_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/tournaments/submit")
      assert html =~ "Submit Tournament"
    end
  end

  describe "Creating as draft" do
    setup %{conn: conn} do
      user = td_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "saves tournament as draft", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/tournaments/submit")

      start_at =
        DateTime.utc_now()
        |> DateTime.add(7, :day)
        |> DateTime.truncate(:second)
        |> Calendar.strftime("%Y-%m-%dT%H:%M")

      lv
      |> form("#tournament-submit-form", %{
        tournament: %{
          name: "My Draft Tournament",
          start_at: start_at
        }
      })
      |> render_submit(%{submit_action: "draft"})

      flash = assert_redirected(lv, ~p"/tournaments")

      assert flash["info"] =~ "submitted successfully"

      tournament = OP.Repo.get_by!(OP.Tournaments.Tournament, name: "My Draft Tournament")
      assert tournament.status == :draft
      assert tournament.organizer_id == user.id
    end
  end

  describe "Submitting for sanctioning" do
    setup %{conn: conn} do
      user = td_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "submit button is disabled until code of conduct checkbox is checked", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/tournaments/submit")

      # Button should be disabled initially
      assert html =~ "I agree that all"
      assert html =~ "Code of Conduct"
      assert html =~ ~s(disabled)

      # Check the checkbox
      lv |> element(~s(input[name="code_of_conduct_agreed"])) |> render_click()

      # Button should now be enabled
      html = render(lv)
      refute html =~ ~s(disabled="disabled")
    end

    test "saves tournament as pending_review", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/tournaments/submit")

      # Check code of conduct checkbox
      lv |> element(~s(input[name="code_of_conduct_agreed"])) |> render_click()

      start_at =
        DateTime.utc_now()
        |> DateTime.add(7, :day)
        |> DateTime.truncate(:second)
        |> Calendar.strftime("%Y-%m-%dT%H:%M")

      lv
      |> form("#tournament-submit-form", %{
        tournament: %{
          name: "My Submitted Tournament",
          start_at: start_at
        }
      })
      |> render_submit(%{submit_action: "submit"})

      flash = assert_redirected(lv, ~p"/tournaments")

      assert flash["info"] =~ "submitted successfully"

      tournament = OP.Repo.get_by!(OP.Tournaments.Tournament, name: "My Submitted Tournament")
      assert tournament.status == :pending_review
      assert tournament.organizer_id == user.id
    end
  end

  describe "Edit draft" do
    setup %{conn: conn} do
      user = td_user_fixture()
      scope = OP.Accounts.Scope.for_user(user)

      tournament =
        tournament_fixture(scope, %{
          name: "Editable Draft",
          status: :draft,
          organizer_id: user.id
        })

      %{conn: log_in_user(conn, user), user: user, tournament: tournament}
    end

    test "can edit a draft tournament", %{conn: conn, tournament: tournament} do
      {:ok, lv, html} = live(conn, ~p"/tournaments/submit/#{tournament.id}/edit")

      assert html =~ "Edit Draft Tournament"
      assert html =~ "Editable Draft"

      start_at =
        DateTime.utc_now()
        |> DateTime.add(14, :day)
        |> DateTime.truncate(:second)
        |> Calendar.strftime("%Y-%m-%dT%H:%M")

      lv
      |> form("#tournament-submit-form", %{
        tournament: %{
          name: "Updated Draft",
          start_at: start_at
        }
      })
      |> render_submit(%{submit_action: "draft"})

      flash = assert_redirected(lv, ~p"/tournaments")
      assert flash["info"] =~ "updated successfully"

      updated = OP.Repo.get!(OP.Tournaments.Tournament, tournament.id)
      assert updated.name == "Updated Draft"
      assert updated.status == :draft
    end
  end
end
