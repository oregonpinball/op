defmodule OPWeb.PageControllerTest do
  use OPWeb.ConnCase

  test "GET /, unauthenticated", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Want to play?"
  end
end
