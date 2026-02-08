defmodule OPWeb.UserLive.InvitationAcceptance do
  use OPWeb, :live_view

  alias OP.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <.header>
          Set your password
          <:subtitle>
            Welcome, {@user.email} — choose a password to activate your account
          </:subtitle>
        </.header>

        <.form
          for={@form}
          id="invitation-acceptance-form"
          phx-change="validate"
          phx-submit="accept"
          phx-mounted={JS.focus_first()}
          action={~p"/users/log-in?_action=invitation_accepted"}
          phx-trigger-action={@trigger_submit}
        >
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />

          <.input field={@form[:password]} type="password" label="Password" required />
          <.input
            field={@form[:password_confirmation]}
            type="password"
            label="Confirm password"
            required
          />

          <div class="mt-6">
            <.button type="submit" color="primary" phx-disable-with="Activating..." class="w-full">
              Activate account
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_invitation_token(token) do
      form =
        to_form(%{"password" => "", "password_confirmation" => "", "token" => token}, as: "user")

      {:ok,
       socket
       |> assign(:page_title, "Accept Invitation")
       |> assign(:user, user)
       |> assign(:token, token)
       |> assign(:form, form)
       |> assign(:trigger_submit, false), temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Invitation link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      Accounts.change_invitation_acceptance(socket.assigns.user, user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "user"))}
  end

  def handle_event("accept", %{"user" => user_params}, socket) do
    case Accounts.accept_invitation(socket.assigns.token, user_params) do
      {:ok, {user, _expired_tokens}} ->
        login_token = Accounts.create_login_token_for_user(user)

        form =
          to_form(%{"token" => login_token, "remember_me" => "true"}, as: "user")

        {:noreply, assign(socket, form: form, trigger_submit: true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "user"))}

      {:error, :invalid_token} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invitation link is invalid or it has expired.")
         |> push_navigate(to: ~p"/users/log-in")}
    end
  end
end
