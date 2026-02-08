defmodule OPWeb.UserLive.Registration do
  use OPWeb, :live_view

  alias OP.Accounts
  alias OP.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
        <div class="text-center">
          <.header>
            Register for an account
            <:subtitle>
              Already registered?
              <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
                Log in
              </.link>
              to your account now.
            </:subtitle>
          </.header>
        </div>

        <div class="mx-auto w-1/2">
          <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              autocomplete="username"
              required
              phx-mounted={JS.focus()}
            />

            <div class="my-4 rounded-lg border border-zinc-200 bg-zinc-50 p-4">
              <label class="flex items-start gap-3 text-sm">
                <input
                  type="checkbox"
                  name="agreed"
                  value="true"
                  checked={@agreed}
                  phx-click="toggle_agreed"
                  class="mt-1 rounded border-zinc-300"
                />
                <span>
                  I agree to the <.link
                    href="/f/rules/code-of-conduct"
                    target="_blank"
                    class="text-blue-600 underline"
                  >
                    Code of Conduct
                  </.link>, <.link
                    href="/f/rules/terms-of-service"
                    target="_blank"
                    class="text-blue-600 underline"
                  >
                    Terms of Service
                  </.link>, and <.link
                    href="/f/rules/privacy-policy"
                    target="_blank"
                    class="text-blue-600 underline"
                  >
                    Privacy Policy
                  </.link>.
                </span>
              </label>
            </div>

            <div class="flex justify-end">
              <.button
                phx-disable-with="Creating account..."
                color="primary"
                disabled={!@agreed}
              >
                Create an account
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: OPWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    if OP.FeatureFlags.registration_enabled?() do
      changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

      {:ok, socket |> assign(:agreed, false) |> assign_form(changeset),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Registration is not currently available.")
       |> redirect(to: ~p"/")}
    end
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("toggle_agreed", _params, socket) do
    {:noreply, assign(socket, :agreed, !socket.assigns.agreed)}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params, validate_unique: false)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
