defmodule OPWeb.Admin.UserLive.Index do
  use OPWeb, :live_view

  alias OP.Accounts

  @default_per_page 25

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
        <.header>
          Manage Users
          <:subtitle>
            {if @pagination.total_count > 0,
              do: "#{@pagination.total_count} users total",
              else: "No users yet"}
          </:subtitle>
        </.header>

        <div class="mt-6 bg-white rounded-lg border border-gray-200 p-4">
          <.form
            for={@filter_form}
            id="user-filters"
            phx-change="filter"
            phx-submit="filter"
            class="space-y-4"
          >
            <div class="flex gap-4 items-end">
              <div class="flex-1">
                <.input
                  field={@filter_form[:search]}
                  type="search"
                  label="Search users"
                  placeholder="Search by email..."
                  phx-debounce="300"
                />
              </div>
              <div class="w-48">
                <.input
                  field={@filter_form[:role]}
                  type="select"
                  label="Role"
                  options={[
                    {"All roles", ""},
                    {"System Admin", "system_admin"},
                    {"TD", "td"},
                    {"Player", "player"}
                  ]}
                />
              </div>
              <.button
                type="button"
                variant="invisible"
                phx-click="clear_filters"
                class="mb-2"
              >
                <.icon name="hero-x-mark" class="w-4 h-4 mr-1" /> Clear
              </.button>
            </div>
          </.form>
        </div>

        <div class="mt-4 flex items-center justify-between text-sm text-gray-500">
          <span>
            <%= if @users_empty? do %>
              No users found
            <% else %>
              Showing {(@pagination.page - 1) * @pagination.per_page + 1} to {min(
                @pagination.page * @pagination.per_page,
                @pagination.total_count
              )} of {@pagination.total_count} users
            <% end %>
          </span>
          <form phx-change="change_per_page">
            <label for="per-page" class="mr-2">Per page:</label>
            <select
              id="per-page"
              name="per_page"
              class="rounded-md border-gray-300 text-sm py-1 pl-2 pr-8"
            >
              <option
                :for={opt <- [10, 25, 50, 100]}
                value={opt}
                selected={opt == @pagination.per_page}
              >
                {opt}
              </option>
            </select>
          </form>
        </div>

        <div class="mt-4 overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 bg-white border border-gray-200 rounded-lg">
            <thead class="bg-gray-50">
              <tr>
                <.sort_header
                  field="email"
                  label="Email"
                  sort_by={@sort_by}
                  sort_dir={@sort_dir}
                  params={@sort_params}
                />
                <.sort_header
                  field="role"
                  label="Role"
                  sort_by={@sort_by}
                  sort_dir={@sort_dir}
                  params={@sort_params}
                />
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Linked Player
                </th>
                <.sort_header
                  field="confirmed_at"
                  label="Confirmed"
                  sort_by={@sort_by}
                  sort_dir={@sort_dir}
                  params={@sort_params}
                />
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody id="users" phx-update="stream" class="divide-y divide-gray-200">
              <tr id="empty-users" class="hidden only:table-row">
                <td colspan="5" class="text-center py-8 text-gray-500">
                  No users match your filters. Try adjusting your search criteria.
                </td>
              </tr>
              <tr
                :for={{id, user} <- @streams.users}
                id={id}
                class="hover:bg-gray-50"
              >
                <td class="px-4 py-3 text-sm font-medium text-gray-900">
                  {user.email}
                </td>
                <td class="px-4 py-3 text-sm">
                  <.badge color={role_color(user.role)}>
                    {role_label(user.role)}
                  </.badge>
                </td>
                <td class="px-4 py-3 text-sm text-gray-500">
                  {if user.player, do: user.player.name, else: "-"}
                </td>
                <td class="px-4 py-3 text-sm text-gray-500">
                  {if user.confirmed_at, do: "Yes", else: "No"}
                </td>
                <td class="px-4 py-3 text-sm text-right whitespace-nowrap">
                  <.link navigate={~p"/admin/users/#{user.id}/edit"}>
                    <.button variant="invisible" size="sm">
                      <.icon name="hero-pencil-square" class="w-4 h-4" />
                    </.button>
                  </.link>
                  <.button
                    variant="invisible"
                    size="sm"
                    phx-click="delete"
                    phx-value-id={user.id}
                    data-confirm="Are you sure you want to delete this user? This action cannot be undone."
                  >
                    <.icon name="hero-trash" class="w-4 h-4" />
                  </.button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <.pagination
          page={@pagination.page}
          total_pages={@pagination.total_pages}
          path={~p"/admin/users"}
          params={
            filter_params_for_pagination(@filter_form, @pagination.per_page, @sort_by, @sort_dir)
          }
        />
      </div>
    </Layouts.app>
    """
  end

  attr :field, :string, required: true
  attr :label, :string, required: true
  attr :sort_by, :string, required: true
  attr :sort_dir, :string, required: true
  attr :params, :map, required: true

  defp sort_header(assigns) do
    next_dir =
      if assigns.field == assigns.sort_by and assigns.sort_dir == "asc", do: "desc", else: "asc"

    params = Map.merge(assigns.params, %{"sort_by" => assigns.field, "sort_dir" => next_dir})
    assigns = assign(assigns, :href_params, params)

    ~H"""
    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
      <.link
        patch={~p"/admin/users?#{@href_params}"}
        class="group inline-flex items-center gap-1 hover:text-gray-700"
      >
        {@label}
        <span :if={@field == @sort_by} class="text-gray-400">
          <.icon :if={@sort_dir == "asc"} name="hero-chevron-up" class="w-3 h-3" />
          <.icon :if={@sort_dir == "desc"} name="hero-chevron-down" class="w-3 h-3" />
        </span>
        <span
          :if={@field != @sort_by}
          class="text-gray-300 opacity-0 group-hover:opacity-100 transition-opacity"
        >
          <.icon name="hero-chevron-up-down" class="w-3 h-3" />
        </span>
      </.link>
    </th>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :users, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_filters(socket, params)}
  end

  @allowed_sort_fields ~w(email role confirmed_at)

  defp apply_filters(socket, params) do
    page = parse_page(params["page"])
    per_page = parse_per_page(params["per_page"])
    search = params["search"] || ""
    role = params["role"] || ""
    sort_by = parse_sort_by(params["sort_by"])
    sort_dir = parse_sort_dir(params["sort_dir"])

    filter_params = %{"search" => search, "role" => role}

    result =
      Accounts.list_users_paginated(
        page: page,
        per_page: per_page,
        search: non_empty(search),
        role: non_empty(role),
        sort_by: String.to_existing_atom(sort_by),
        sort_dir: String.to_existing_atom(sort_dir)
      )

    pagination = %{
      page: result.page,
      per_page: result.per_page,
      total_count: result.total_count,
      total_pages: result.total_pages
    }

    socket
    |> assign(:page_title, "Manage Users")
    |> assign(:filter_form, to_form(filter_params, as: :filter))
    |> assign(:pagination, pagination)
    |> assign(:sort_by, sort_by)
    |> assign(:sort_dir, sort_dir)
    |> assign(:sort_params, sort_params_for_url(filter_params, per_page, sort_by, sort_dir))
    |> assign(:users_empty?, result.users == [])
    |> stream(:users, result.users, reset: true)
  end

  defp parse_sort_by(val) when is_binary(val) do
    if val in @allowed_sort_fields, do: val, else: "email"
  end

  defp parse_sort_by(_), do: "email"

  defp parse_sort_dir("asc"), do: "asc"
  defp parse_sort_dir("desc"), do: "desc"
  defp parse_sort_dir(_), do: "asc"

  defp sort_params_for_url(filter_params, per_page, sort_by, sort_dir) do
    base =
      filter_params
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()

    base = if per_page != @default_per_page, do: Map.put(base, "per_page", per_page), else: base
    base = if sort_by != "email", do: Map.put(base, "sort_by", sort_by), else: base
    base = if sort_dir != "asc", do: Map.put(base, "sort_dir", sort_dir), else: base
    base
  end

  defp parse_page(nil), do: 1

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {num, _} when num > 0 -> num
      _ -> 1
    end
  end

  @allowed_per_page [10, 25, 50, 100]

  defp parse_per_page(nil), do: @default_per_page

  defp parse_per_page(value) when is_binary(value) do
    case Integer.parse(value) do
      {num, _} when num in @allowed_per_page -> num
      _ -> @default_per_page
    end
  end

  defp non_empty(""), do: nil
  defp non_empty(value), do: value

  defp filter_params_for_pagination(filter_form, per_page, sort_by, sort_dir) do
    params = %{
      "search" => filter_form[:search].value,
      "role" => filter_form[:role].value
    }

    params =
      if per_page != @default_per_page,
        do: Map.put(params, "per_page", per_page),
        else: params

    params = if sort_by != "email", do: Map.put(params, "sort_by", sort_by), else: params
    params = if sort_dir != "asc", do: Map.put(params, "sort_dir", sort_dir), else: params

    params
    |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
    |> Map.new()
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    per_page = socket.assigns.pagination.per_page
    sort_by = socket.assigns.sort_by
    sort_dir = socket.assigns.sort_dir

    params =
      filter_params
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()
      |> Map.put("page", "1")

    params =
      if per_page != @default_per_page,
        do: Map.put(params, "per_page", per_page),
        else: params

    params = if sort_by != "email", do: Map.put(params, "sort_by", sort_by), else: params
    params = if sort_dir != "asc", do: Map.put(params, "sort_dir", sort_dir), else: params

    {:noreply, push_patch(socket, to: ~p"/admin/users?#{params}")}
  end

  def handle_event("change_per_page", %{"per_page" => per_page}, socket) do
    params =
      socket.assigns.filter_form
      |> filter_params_for_pagination(
        parse_per_page(per_page),
        socket.assigns.sort_by,
        socket.assigns.sort_dir
      )
      |> Map.put("page", "1")
      |> Map.put("per_page", per_page)

    {:noreply, push_patch(socket, to: ~p"/admin/users?#{params}")}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/users")}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(String.to_integer(id))

    if user.id == socket.assigns.current_scope.user.id do
      {:noreply, put_flash(socket, :error, "You cannot delete your own account")}
    else
      case Accounts.delete_user(user) do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, "User deleted successfully")
           |> push_patch(to: ~p"/admin/users")}

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
