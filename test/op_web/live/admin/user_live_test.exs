defmodule OPWeb.Admin.UserLiveTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.AccountsFixtures

  describe "Index - Authorization" do
    test "redirects non-authenticated users to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/users")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects regular users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, redirect} = live(conn, ~p"/admin/users")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You must be a system admin to access this page."} = flash
    end

    test "redirects td users to home page", %{conn: conn} do
      user = td_user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, redirect} = live(conn, ~p"/admin/users")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You must be a system admin to access this page."} = flash
    end

    test "allows system_admin users to access", %{conn: conn} do
      user = admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/admin/users")
      assert html =~ "Manage Users"
    end
  end

  describe "New User - Authorization" do
    test "redirects non-authenticated users to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/users/new")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "redirects regular users to home page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      assert {:error, redirect} = live(conn, ~p"/admin/users/new")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/"
      assert %{"error" => "You must be a system admin to access this page."} = flash
    end

    test "allows system_admin users to access", %{conn: conn} do
      user = admin_user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/admin/users/new")
      assert html =~ "Create User"
    end
  end

  describe "Index" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "has New User button that navigates to create form", %{conn: conn} do
      {:ok, lv, html} = live(conn, ~p"/admin/users")
      assert html =~ "New User"

      lv |> element("a", "New User") |> render_click()
      assert_redirect(lv, ~p"/admin/users/new")
    end
  end

  describe "Create User" do
    setup %{conn: conn} do
      user = admin_user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders create user form", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/users/new")

      assert html =~ "Create User"
      assert html =~ "Email"
      assert html =~ "Password"
      assert html =~ "Role"
    end

    test "creates user with valid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      lv
      |> form("#user-form",
        user: %{
          email: "newuser@example.com",
          password: "valid_password123",
          role: "player"
        }
      )
      |> render_submit()

      assert_redirect(lv, ~p"/admin/users")

      # Verify user was created and confirmed
      user = OP.Accounts.get_user_by_email("newuser@example.com")
      assert user
      assert user.confirmed_at
      assert user.role == :player
    end

    test "creates user with system_admin role", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      lv
      |> form("#user-form",
        user: %{
          email: "admin@example.com",
          password: "valid_password123",
          role: "system_admin"
        }
      )
      |> render_submit()

      assert_redirect(lv, ~p"/admin/users")

      user = OP.Accounts.get_user_by_email("admin@example.com")
      assert user.role == :system_admin
    end

    test "created user can log in with password", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      lv
      |> form("#user-form",
        user: %{
          email: "logintest@example.com",
          password: "valid_password123",
          role: "player"
        }
      )
      |> render_submit()

      user =
        OP.Accounts.get_user_by_email_and_password("logintest@example.com", "valid_password123")

      assert user
    end

    test "validates required fields", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      html =
        lv
        |> form("#user-form", user: %{email: "", password: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "validates email format", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      html =
        lv
        |> form("#user-form",
          user: %{email: "invalid", password: "valid_password123", role: "player"}
        )
        |> render_change()

      assert html =~ "must have the @ sign and no spaces"
    end

    test "validates password length", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      html =
        lv
        |> form("#user-form",
          user: %{email: "test@example.com", password: "short", role: "player"}
        )
        |> render_change()

      assert html =~ "should be at least 8 character(s)"
    end

    test "handles duplicate email", %{conn: conn} do
      existing = user_fixture()
      {:ok, lv, _html} = live(conn, ~p"/admin/users/new")

      html =
        lv
        |> form("#user-form",
          user: %{
            email: existing.email,
            password: "valid_password123",
            role: "player"
          }
        )
        |> render_submit()

      assert html =~ "has already been taken"
    end
  end
end
