defmodule OPWeb.UserLive.Login do
  use OPWeb, :live_view

  alias OP.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-[url('/images/pin1.png')] bg-cover bg-fixed">
        <div class="w-full md:w-1/2 md:mx-auto p-4">
          <div class="">
            <h1 class="text-center text-5xl text-slate-100 font-bold [text-shadow:3px_0_0_rgb(0_0_0),-3px_0_0_rgb(0_0_0),0_3px_0_rgb(0_0_0),0_-2px_0_rgb(0_0_0)]">
              Oregon Pinball
            </h1>
            <.alert :if={local_mail_adapter?()} class="mx-auto mt-4" color="info">
              <p>You are running the local mail adapter.</p>
              <p>
                To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
              </p>
            </.alert>

            <.alert :if={@current_scope} color="info" class="mx-auto mt-4">
              You need to reauthenticate to perform sensitive actions on your account.
            </.alert>

            <div class="grid grid-cols-1 gap-8 mt-4">
              <%!-- Passwordless Email Login Column --%>
              <div class="space-y-4 bg-white/95 p-4 border rounded">
                <div class="border-b pb-3">
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
              <div class="rounded space-y-4 bg-white/95 p-4">
                <div class="border-b pb-3">
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
