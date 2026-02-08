defmodule OPWeb.PageControllerTest do
  use OPWeb.ConnCase

  test "GET /, unauthenticated", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Want to play?"
  end

  test "GET / redirects unauthenticated users to /tournaments when tournaments_only is enabled",
       %{conn: conn} do
    Application.put_env(:op, :feature_flags,
      registration_enabled: true,
      tournament_submission_enabled: true,
      magic_link_login_enabled: true,
      tournaments_only: true
    )

    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/tournaments"
  after
    Application.put_env(:op, :feature_flags,
      registration_enabled: true,
      tournament_submission_enabled: true,
      magic_link_login_enabled: true,
      tournaments_only: false
    )
  end

  describe "authenticated" do
    setup :register_and_log_in_user

    test "GET / does not redirect authenticated users when tournaments_only is enabled",
         %{conn: conn} do
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        magic_link_login_enabled: true,
        tournaments_only: true
      )

      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Welcome back"
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        magic_link_login_enabled: true,
        tournaments_only: false
      )
    end
  end
end
