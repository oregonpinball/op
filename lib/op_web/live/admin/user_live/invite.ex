defmodule OPWeb.Admin.UserLive.Invite do
  use OPWeb, :live_view

  alias OP.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
        <.header>
          Invite User
          <:subtitle>
            Send a unique invitation link — the user will set their own password
          </:subtitle>
        </.header>

        <div class="mt-6 max-w-2xl">
          <%= if @invitation_url do %>
            <div class="rounded-lg border border-green-200 bg-green-50 p-6">
              <div class="flex items-center gap-2 mb-4">
                <.icon name="hero-check-circle" class="w-5 h-5 text-green-600" />
                <h3 class="text-base font-semibold text-green-800">Invitation created</h3>
              </div>

              <p class="text-sm text-green-700 mb-4">
                Share this link with <strong>{@invited_email}</strong> — it expires in 7 days.
              </p>

              <div class="flex gap-2">
                <input
                  id="invitation-url"
                  type="text"
                  value={@invitation_url}
                  readonly
                  class="flex-1 rounded-lg border border-green-300 bg-white px-3 py-2 text-sm font-mono text-gray-700 select-all"
                />
                <button
                  id="copy-invitation-url"
                  phx-hook="Clipboard"
                  phx-update="ignore"
                  data-clipboard-text={@invitation_url}
                  class={[
                    "inline-flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm font-medium",
                    "border border-green-300 bg-white text-green-700",
                    "hover:bg-green-100 transition-colors cursor-pointer"
                  ]}
                >
                  <.icon name="hero-clipboard-document" class="w-4 h-4" />
                  <span data-label>Copy</span>
                </button>
              </div>

              <div class="mt-6 flex gap-3">
                <.link navigate={~p"/admin/users/invite"}>
                  <.button color="primary" variant="invisible">
                    <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Invite Another
                  </.button>
                </.link>
                <.link navigate={~p"/admin/users"}>
                  <.button variant="invisible">Back to Users</.button>
                </.link>
              </div>
            </div>
          <% else %>
            <.form for={@form} id="invite-form" phx-change="validate" phx-submit="invite">
              <.input field={@form[:email]} type="email" label="Email" required />

              <.input
                field={@form[:role]}
                type="select"
                label="Role"
                options={[
                  {"System Admin", :system_admin},
                  {"TD", :td},
                  {"Player", :player}
                ]}
                required
              />

              <div class="mt-6 flex gap-4">
                <.button type="submit" color="primary" phx-disable-with="Inviting...">
                  Create Invitation
                </.button>
                <.button navigate={~p"/admin/users"} variant="invisible">
                  Cancel
                </.button>
              </div>
            </.form>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Invite User")
     |> assign(:invitation_url, nil)
     |> assign(:invited_email, nil)
     |> assign(:form, to_form(Accounts.change_invitation()))}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      Accounts.change_invitation(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("invite", %{"user" => user_params}, socket) do
    case Accounts.invite_user(user_params) do
      {:ok, {user, encoded_token}} ->
        invitation_url = url(~p"/users/invitation/#{encoded_token}")

        {:noreply,
         socket
         |> assign(:invitation_url, invitation_url)
         |> assign(:invited_email, user.email)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
