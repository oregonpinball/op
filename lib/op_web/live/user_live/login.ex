defmodule OPWeb.UserLive.Login do
  use OPWeb, :live_view

  alias OP.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto">
        <div class="text-center mb-8">
          <.header>
            <p>Log in</p>
            <:subtitle>
              <%= if @current_scope do %>
                You need to reauthenticate to perform sensitive actions on your account.
              <% else %>
                Don't have an account? <.link
                  navigate={~p"/users/register"}
                  class="font-semibold text-brand hover:underline"
                  phx-no-format
                >Sign up</.link> for an account now.
              <% end %>
            </:subtitle>
          </.header>
        </div>

        <.alert :if={local_mail_adapter?()} class="mx-auto" color="info">
          <p>You are running the local mail adapter.</p>
          <p>
            To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
          </p>
        </.alert>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mt-4">
          <%!-- Passwordless Email Login Column --%>
          <div class="space-y-4 bg-white p-4 border rounded">
            <div class="border-b pb-3 mb-4">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">
                <.icon name="hero-sparkles" class="size-5 inline-block" /> Simple Login
              </h2>
              <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                Get a secure login link (magic link) sent to your email
              </p>
            </div>
            <.form
              :let={f}
              for={@form}
              id="login_form_magic"
              action={~p"/users/log-in"}
              phx-submit="submit_magic"
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="email"
                required
                phx-mounted={JS.focus()}
              />
              <.button class="w-full" color="primary" size="md">
                Log in with email <span aria-hidden="true">→</span>
              </.button>
            </.form>
          </div>

          <%!-- Email/Password Login Column --%>
          <div class="space-y-4 bg-gray-50 p-4">
            <div class="border-b pb-3 mb-4">
              <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">
                Traditional Login
              </h2>
              <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                Sign in with your email and password
              </p>
            </div>
            <.form
              :let={f}
              for={@form}
              id="login_form_password"
              action={~p"/users/log-in"}
              phx-submit="submit_password"
              phx-trigger-action={@trigger_submit}
            >
              <.input
                readonly={!!@current_scope}
                field={f[:email]}
                type="email"
                label="Email"
                autocomplete="email"
                required
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                autocomplete="current-password"
              />
              <.button class="btn btn-primary w-full" name={@form[:remember_me].name} value="true">
                Log in and stay logged in <span aria-hidden="true">→</span>
              </.button>
              <.button class="btn btn-primary btn-soft w-full mt-2">
                Log in only this time
              </.button>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:op, OP.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
