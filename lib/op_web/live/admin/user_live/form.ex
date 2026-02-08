defmodule OPWeb.Admin.UserLive.Form do
  use OPWeb, :live_view

  alias OP.Accounts
  alias OP.Players

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
        <.header>
          {@page_title}
          <:subtitle>
            <%= if @live_action == :new do %>
              Create a new user with email, password, and role
            <% else %>
              Edit user role and linked player account
            <% end %>
          </:subtitle>
        </.header>

        <div class="mt-6 max-w-2xl">
          <.form for={@form} id="user-form" phx-change="validate" phx-submit="save">
            <%= if @live_action == :new do %>
              <.input field={@form[:email]} type="email" label="Email" required />

              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                required
              />
            <% else %>
              <.input field={@form[:email]} type="text" label="Email" disabled />
            <% end %>

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
              <.button type="submit" color="primary" phx-disable-with="Saving...">
                {if @live_action == :new, do: "Create User", else: "Save User"}
              </.button>
              <.button navigate={~p"/admin/users"} variant="invisible">
                Cancel
              </.button>
            </div>
          </.form>

          <%= if @live_action == :edit do %>
            <div class="mt-8 pt-6 border-t border-slate-300">
              <h3 class="text-base font-semibold mb-4">Linked Player Account</h3>

              <%= if @user.player do %>
                <div class="flex items-center gap-4 p-4 bg-slate-100 rounded-lg">
                  <div class="flex-1">
                    <p class="font-medium">{@user.player.name}</p>
                    <p class="text-sm text-slate-600">Currently linked</p>
                  </div>
                  <.button
                    color="error"
                    variant="invisible"
                    phx-click="unlink_player"
                    data-confirm="Are you sure you want to unlink this player?"
                  >
                    <.icon name="hero-x-mark" class="mr-1" /> Unlink
                  </.button>
                </div>
              <% else %>
                <div class="space-y-4">
                  <p class="text-slate-600">No player account linked to this user.</p>

                  <.form
                    for={@player_search_form}
                    id="player-search-form"
                    phx-change="search_players"
                    phx-submit="search_players"
                  >
                    <.input
                      field={@player_search_form[:query]}
                      type="search"
                      label="Search for player by name"
                      placeholder="Start typing player name..."
                      phx-debounce="300"
                    />
                  </.form>

                  <div :if={@player_results != []} class="border border-slate-300 rounded-lg divide-y">
                    <div
                      :for={player <- @player_results}
                      class="p-3 flex items-center justify-between hover:bg-slate-50"
                    >
                      <div class="flex-1">
                        <span class="font-medium">{player.name}</span>
                        <%= if player.user do %>
                          <span class="text-sm text-amber-600 ml-2">
                            (already linked to {player.user.email})
                          </span>
                        <% end %>
                      </div>
                      <.button
                        size="sm"
                        color="primary"
                        phx-click="link_player"
                        phx-value-player-id={player.id}
                        disabled={player.user != nil}
                      >
                        Link
                      </.button>
                    </div>
                  </div>

                  <p
                    :if={@player_search != "" && @player_results == []}
                    class="text-slate-500 text-sm"
                  >
                    No players found matching "{@player_search}"
                  </p>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create User")
    |> assign(:user, nil)
    |> assign(:form, to_form(Accounts.change_admin_user_creation()))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = Accounts.get_user_with_player!(String.to_integer(id))

    socket
    |> assign(:page_title, "Edit User")
    |> assign(:user, user)
    |> assign(:player_search, "")
    |> assign(:player_results, [])
    |> assign(:player_search_form, to_form(%{"query" => ""}, as: :player_search))
    |> assign(:form, to_form(Accounts.change_user(user)))
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      case socket.assigns.live_action do
        :new ->
          Accounts.change_admin_user_creation(user_params)

        :edit ->
          Accounts.change_user(socket.assigns.user, user_params)
      end

    changeset = Map.put(changeset, :action, :validate)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.live_action, user_params)
  end

  def handle_event("search_players", %{"player_search" => %{"query" => query}}, socket) do
    results = Players.search_players(socket.assigns.current_scope, query)

    {:noreply,
     assign(socket,
       player_search: query,
       player_results: results,
       player_search_form: to_form(%{"query" => query}, as: :player_search)
     )}
  end

  def handle_event("link_player", %{"player-id" => player_id}, socket) do
    player_id = String.to_integer(player_id)
    player = Players.get_player!(socket.assigns.current_scope, player_id)

    # Check if player is already linked to another user
    if player.user_id && player.user_id != socket.assigns.user.id do
      {:noreply, put_flash(socket, :error, "Player is already linked to another user")}
    else
      case Players.link_user(socket.assigns.current_scope, player, socket.assigns.user.id) do
        {:ok, _player} ->
          # Reload user with player preload
          user = Accounts.get_user_with_player!(socket.assigns.user.id)

          {:noreply,
           socket
           |> assign(:user, user)
           |> assign(:player_search, "")
           |> assign(:player_results, [])
           |> assign(:player_search_form, to_form(%{"query" => ""}, as: :player_search))
           |> put_flash(:info, "Player linked successfully")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Failed to link player")}
      end
    end
  end

  def handle_event("unlink_player", _params, socket) do
    player = socket.assigns.user.player

    case Players.unlink_user(socket.assigns.current_scope, player) do
      {:ok, _player} ->
        # Reload user with player preload
        user = Accounts.get_user_with_player!(socket.assigns.user.id)

        {:noreply,
         socket
         |> assign(:user, user)
         |> put_flash(:info, "Player unlinked successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to unlink player")}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.admin_create_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_navigate(to: ~p"/admin/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user_role(
           socket.assigns.user,
           user_params,
           socket.assigns.current_scope.user.id
         ) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_navigate(to: ~p"/admin/users")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
