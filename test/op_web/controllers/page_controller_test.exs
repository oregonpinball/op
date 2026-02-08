defmodule OPWeb.PageControllerTest do
  use OPWeb.ConnCase

  test "GET /, unauthenticated", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Want to play?"
  end

  test "GET / redirects to /tournaments when tournaments_only is enabled", %{conn: conn} do
    Application.put_env(:op, :feature_flags,
      registration_enabled: true,
      tournament_submission_enabled: true,
      tournaments_only: true
    )

    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/tournaments"
  after
    Application.put_env(:op, :feature_flags,
      registration_enabled: true,
      tournament_submission_enabled: true,
      tournaments_only: false
    )
  end
end
