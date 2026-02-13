defmodule OPWeb.UserLive.LoginTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.AccountsFixtures

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Log in"
      assert html =~ "Register"
      assert html =~ "Log in with email"
    end
  end

  describe "user login - magic link" do
    setup do
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        magic_link_login_enabled: true,
        tournaments_only: false
      )
    end

    test "sends magic link email when user exists", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", user: %{email: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "If your email is in our system"

      assert OP.Repo.get_by!(OP.Accounts.UserToken, user_id: user.id).context ==
               "login"
    end

    test "does not disclose if user is registered", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      {:ok, _lv, html} =
        form(lv, "#login_form_magic", user: %{email: "idonotexist@example.com"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "If your email is in our system"
    end
  end

  describe "user login - password" do
    test "redirects if user logs in with valid credentials", %{conn: conn} do
      user = user_fixture() |> set_password()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form_password",
          user: %{email: user.email, password: valid_user_password(), remember_me: true}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if credentials are invalid", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form_password", user: %{email: "test@email.com", password: "123456"})

      render_submit(form, %{user: %{remember_me: true}})

      conn = follow_trigger_action(form, conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "login page with magic link disabled" do
    setup do
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        magic_link_login_enabled: false,
        tournaments_only: false
      )

      on_exit(fn ->
        Application.put_env(:op, :feature_flags,
          registration_enabled: true,
          tournament_submission_enabled: true,
          magic_link_login_enabled: true,
          tournaments_only: false
        )
      end)

      :ok
    end

    test "does not render magic link form", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")
      refute has_element?(lv, "#login_form_magic")
      assert has_element?(lv, "#login_form_password")
    end

    test "submit_magic event is a no-op", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")
      render_hook(lv, :submit_magic, %{"user" => %{"email" => "test@example.com"}})
      refute_redirected(lv, ~p"/users/log-in")
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        magic_link_login_enabled: true,
        tournaments_only: false
      )

      user = user_fixture()
      %{user: user, conn: log_in_user(conn, user)}
    end

    test "shows login page with email filled in", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")
      html = render(lv)

      assert html =~ "You need to reauthenticate"
      refute html =~ "Register"
      assert has_element?(lv, "#login_form_magic")

      assert html =~
               ~s(<input type="email" name="user[email]" id="login_form_magic_email" value="#{user.email}")
    end
  end
end
