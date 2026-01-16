defmodule OPWeb.UserLive.Admin.Index do
  use OPWeb, :live_view

  alias OP.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Manage Users
        <:subtitle>
          {if @total_count > 0, do: "#{@total_count} users total", else: "No users yet"}
        </:subtitle>
      </.header>

      <div class="mt-6 space-y-4">
        <.form
          for={@filter_form}
          id="user-filters"
          phx-change="filter"
          phx-submit="filter"
          class="flex flex-col sm:flex-row gap-4"
        >
          <div class="flex-1">
            <.input
              field={@filter_form[:search]}
              type="search"
              placeholder="Search users by email..."
              phx-debounce="300"
              class="w-full input"
            />
          </div>
          <div class="w-full sm:w-48">
            <.input
              field={@filter_form[:role]}
              type="select"
              options={[
                {"All roles", ""},
                {"System Admin", "system_admin"},
                {"TD", "td"},
                {"Player", "player"}
              ]}
              class="w-full select"
            />
          </div>
        </.form>

        <.table id="users" rows={@streams.users}>
          <:col :let={{_id, user}} label="Email">{user.email}</:col>
          <:col :let={{_id, user}} label="Role">
            <.badge color={role_color(user.role)}>
              {role_label(user.role)}
            </.badge>
          </:col>
          <:col :let={{_id, user}} label="Linked Player">
            {if user.player, do: user.player.name, else: "-"}
          </:col>
          <:col :let={{_id, user}} label="Confirmed">
            {if user.confirmed_at, do: "Yes", else: "No"}
          </:col>
          <:action :let={{_id, user}}>
            <.button navigate={~p"/admin/users/#{user.id}/edit"} size="sm" variant="invisible">
              Edit
            </.button>
          </:action>
          <:action :let={{_id, user}}>
            <.button
              phx-click="delete"
              phx-value-id={user.id}
              data-confirm="Are you sure you want to delete this user? This action cannot be undone."
              size="sm"
              color="error"
              variant="invisible"
            >
              Delete
            </.button>
          </:action>
        </.table>

        <div :if={@users_empty?} class="text-center py-12 text-slate-500">
          <p class="text-lg font-medium">No users found</p>
          <p class="text-sm mt-1">
            {if @filter_form[:search].value || @filter_form[:role].value do
              "Try adjusting your filters"
            else
              "Users will appear here once registered"
            end}
          </p>
        </div>

        <.pagination
          page={@page}
          total_pages={@total_pages}
          path={~p"/admin/users"}
          params={@filter_params}
        />
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
    page = String.to_integer(params["page"] || "1")
    search = params["search"] || ""
    role = params["role"] || ""

    filter_form = to_form(%{"search" => search, "role" => role}, as: :filter)
    filter_params = %{"search" => search, "role" => role}

    opts = [
      page: page,
      per_page: 20,
      search: (search != "" && search) || nil,
      role: (role != "" && role) || nil
    ]

    result = Accounts.list_users_paginated(opts)
    total_pages = ceil(result.total_count / result.per_page)

    {:noreply,
     socket
     |> assign(:page_title, "Manage Users")
     |> assign(:page, result.page)
     |> assign(:per_page, result.per_page)
     |> assign(:total_count, result.total_count)
     |> assign(:total_pages, total_pages)
     |> assign(:users_empty?, result.users == [])
     |> assign(:filter_form, filter_form)
     |> assign(:filter_params, filter_params)
     |> stream(:users, result.users, reset: true)}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    params = %{
      "search" => filter_params["search"] || "",
      "role" => filter_params["role"] || "",
      "page" => "1"
    }

    {:noreply, push_patch(socket, to: ~p"/admin/users?#{params}")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(String.to_integer(id))

    # Prevent deleting yourself
    if user.id == socket.assigns.current_scope.user.id do
      {:noreply, put_flash(socket, :error, "You cannot delete your own account")}
    else
      case Accounts.delete_user(user) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "User deleted successfully")
           |> stream_delete(:users, user)}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to delete user")}
      end
    end
  end

  defp role_color(:system_admin), do: "primary"
  defp role_color(:td), do: "info"
  defp role_color(:player), do: "secondary"

  defp role_label(:system_admin), do: "System Admin"
  defp role_label(:td), do: "TD"
  defp role_label(:player), do: "Player"
end
