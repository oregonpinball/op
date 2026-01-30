defmodule OPWeb.Admin.PlayerLive.Form do
  use OPWeb, :live_view

  alias OP.Players
  alias OP.Players.Player
  alias OP.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
        <.header>
          {@page_title}
          <:subtitle>
            <%= if @live_action == :new do %>
              Add a new player
            <% else %>
              Update player details
            <% end %>
          </:subtitle>
        </.header>

        <div class="mt-6 max-w-2xl">
          <.form for={@form} id="player-form" phx-change="validate" phx-submit="save">
            <.input field={@form[:name]} type="text" label="Name" required />
            <.input field={@form[:number]} type="number" label="Player Number" />
            <.input field={@form[:external_id]} type="text" label="External ID" />

            <div class="mt-6 flex gap-4">
              <.button type="submit" color="primary" phx-disable-with="Saving...">
                Save Player
              </.button>
              <.button navigate={~p"/admin/players"} variant="invisible">
                Cancel
              </.button>
            </div>
          </.form>

          <div :if={@live_action == :edit} class="mt-8 pt-6 border-t border-slate-300">
            <h3 class="text-base font-semibold mb-4">Linked User Account</h3>

            <%= if @player.user do %>
              <div class="flex items-center gap-4 p-4 bg-slate-100 rounded-lg">
                <div class="flex-1">
                  <p class="font-medium">{@player.user.email}</p>
                  <p class="text-sm text-slate-600">Currently linked</p>
                </div>
                <.button
                  color="error"
                  variant="invisible"
                  phx-click="unlink_user"
                  data-confirm="Are you sure you want to unlink this user?"
                >
                  <.icon name="hero-x-mark" class="mr-1" /> Unlink
                </.button>
              </div>
            <% else %>
              <div class="space-y-4">
                <p class="text-slate-600">No user account linked to this player.</p>

                <.form for={@search_form} id="user-search-form" phx-change="search_users">
                  <.input
                    field={@search_form[:user_search]}
                    type="text"
                    label="Search for user by email"
                    phx-debounce="300"
                    placeholder="Start typing email..."
                  />
                </.form>

                <div :if={@user_results != []} class="border border-slate-300 rounded-lg divide-y">
                  <div
                    :for={user <- @user_results}
                    class="p-3 flex items-center justify-between hover:bg-slate-50"
                  >
                    <span>{user.email}</span>
                    <.button
                      size="sm"
                      color="primary"
                      phx-click="link_user"
                      phx-value-user-id={user.id}
                    >
                      Link
                    </.button>
                  </div>
                </div>

                <p :if={@user_search != "" && @user_results == []} class="text-slate-500 text-sm">
                  No users found matching "{@user_search}"
                </p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:user_search, "")
     |> assign(:user_results, [])
     |> assign(:search_form, to_form(%{"user_search" => ""}, as: :search))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    player = %Player{}

    socket
    |> assign(:page_title, "New Player")
    |> assign(:player, player)
    |> assign(:form, to_form(Players.change_player(player)))
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    player = Players.get_player_by_slug!(socket.assigns.current_scope, slug)

    socket
    |> assign(:page_title, "Edit Player")
    |> assign(:player, player)
    |> assign(:form, to_form(Players.change_player(player)))
  end

  @impl true
  def handle_event("validate", %{"player" => player_params}, socket) do
    changeset =
      socket.assigns.player
      |> Players.change_player(player_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"player" => player_params}, socket) do
    save_player(socket, socket.assigns.live_action, player_params)
  end

  def handle_event("search_users", %{"search" => %{"user_search" => query}}, socket) do
    results = Accounts.search_users(query)

    {:noreply,
     assign(socket,
       user_search: query,
       user_results: results,
       search_form: to_form(%{"user_search" => query}, as: :search)
     )}
  end

  def handle_event("link_user", %{"user-id" => user_id}, socket) do
    user_id = String.to_integer(user_id)

    case Players.link_user(socket.assigns.current_scope, socket.assigns.player, user_id) do
      {:ok, player} ->
        # Reload player with user preload
        player = Players.get_player_by_slug!(socket.assigns.current_scope, player.slug)

        {:noreply,
         socket
         |> assign(:player, player)
         |> assign(:user_search, "")
         |> assign(:user_results, [])
         |> put_flash(:info, "User linked successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to link user")}
    end
  end

  def handle_event("unlink_user", _params, socket) do
    case Players.unlink_user(socket.assigns.current_scope, socket.assigns.player) do
      {:ok, player} ->
        # Reload player with user preload
        player = Players.get_player_by_slug!(socket.assigns.current_scope, player.slug)

        {:noreply,
         socket
         |> assign(:player, player)
         |> put_flash(:info, "User unlinked successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to unlink user")}
    end
  end

  defp save_player(socket, :edit, player_params) do
    case Players.update_player(
           socket.assigns.current_scope,
           socket.assigns.player,
           player_params
         ) do
      {:ok, _player} ->
        {:noreply,
         socket
         |> put_flash(:info, "Player updated successfully")
         |> push_navigate(to: ~p"/admin/players")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_player(socket, :new, player_params) do
    case Players.create_player(socket.assigns.current_scope, player_params) do
      {:ok, _player} ->
        {:noreply,
         socket
         |> put_flash(:info, "Player created successfully")
         |> push_navigate(to: ~p"/admin/players")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
