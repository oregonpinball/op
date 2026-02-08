defmodule OPWeb.UserLive.RegistrationTest do
  use OPWeb.ConnCase

  import Phoenix.LiveViewTest
  import OP.AccountsFixtures

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Register"
      assert html =~ "Log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, ~p"/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces"})

      assert result =~ "Register"
      assert result =~ "must have the @ sign and no spaces"
    end
  end

  describe "register user" do
    test "submit button is disabled when agreement checkbox is unchecked", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "disabled"
      assert html =~ "I agree to the"
      assert html =~ "Code of Conduct"
      assert html =~ "Terms of Service"
      assert html =~ "Privacy Policy"
    end

    test "creates account but does not log in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      # Check the agreement checkbox
      lv |> element("input[name=agreed]") |> render_click()

      email = unique_user_email()
      form = form(lv, "#registration_form", user: valid_user_attributes(email: email))

      {:ok, _lv, html} =
        render_submit(form)
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~
               ~r/An email was sent to .*, please access it to confirm your account/
    end

    test "renders errors for duplicated email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      user = user_fixture(%{email: "test@email.com"})

      result =
        lv
        |> form("#registration_form",
          user: %{"email" => user.email}
        )
        |> render_submit()

      assert result =~ "has already been taken"
    end
  end

  describe "registration feature flag" do
    test "redirects to / with flash when registration is disabled", %{conn: conn} do
      Application.put_env(:op, :feature_flags, registration_enabled: false)

      assert {:error, {:redirect, %{to: "/", flash: %{"error" => message}}}} =
               live(conn, ~p"/users/register")

      assert message == "Registration is not currently available."
    after
      Application.put_env(:op, :feature_flags, registration_enabled: true)
    end

    test "allows access when registration is enabled", %{conn: conn} do
      Application.put_env(:op, :feature_flags, registration_enabled: true)

      {:ok, _lv, html} = live(conn, ~p"/users/register")
      assert html =~ "Register"
    after
      Application.put_env(:op, :feature_flags, registration_enabled: true)
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Log in")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/log-in")

      assert login_html =~ "Log in"
    end
  end
end
