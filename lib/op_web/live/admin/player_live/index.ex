defmodule OPWeb.Admin.PlayerLive.Index do
  use OPWeb, :live_view

  alias OP.Players

  @default_per_page 25

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
        <.header>
          Manage Players
          <:subtitle>
            {if @total_count > 0, do: "#{@total_count} players total", else: "No players yet"}
          </:subtitle>
          <:actions>
            <.button navigate={~p"/admin/players/new"} color="primary">
              <.icon name="hero-plus" class="mr-1" /> New Player
            </.button>
          </:actions>
        </.header>

        <div class="mt-6 bg-white rounded-lg border border-gray-200 p-4">
          <.form
            for={@filter_form}
            id="player-filters"
            phx-change="filter"
            phx-submit="filter"
            class="space-y-4"
          >
            <div class="flex gap-4 items-end">
              <div class="flex-1">
                <.input
                  field={@filter_form[:search]}
                  type="search"
                  label="Search players"
                  placeholder="Search by name..."
                  phx-debounce="300"
                />
              </div>
              <div class="w-full sm:w-48">
                <.input
                  field={@filter_form[:linked]}
                  type="select"
                  label="Link status"
                  options={[
                    {"All players", ""},
                    {"Linked to user", "linked"},
                    {"Not linked", "unlinked"}
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
            <%= if @players_empty? do %>
              No players found
            <% else %>
              Showing {(@page - 1) * @per_page + 1} to {min(@page * @per_page, @total_count)} of {@total_count} players
            <% end %>
          </span>
          <form phx-change="change_per_page">
            <label for="per-page" class="mr-2">Per page:</label>
            <select
              id="per-page"
              name="per_page"
              class="rounded-md border-gray-300 text-sm py-1 pl-2 pr-8"
            >
              <option :for={opt <- [10, 25, 50, 100]} value={opt} selected={opt == @per_page}>
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
                  field="name"
                  label="Name"
                  sort_by={@sort_by}
                  sort_dir={@sort_dir}
                  params={@sort_params}
                />
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Number
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  External ID
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Linked User
                </th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody id="players" phx-update="stream" class="divide-y divide-gray-200">
              <tr id="empty-players" class="hidden only:table-row">
                <td colspan="5" class="text-center py-8 text-gray-500">
                  <%= if @has_filters? do %>
                    No players match your search criteria. Try adjusting your filters.
                  <% else %>
                    No players found. Create your first player to get started.
                  <% end %>
                </td>
              </tr>
              <tr
                :for={{id, player} <- @streams.players}
                id={id}
                class="hover:bg-gray-50"
              >
                <td class="px-4 py-3 text-sm font-medium text-gray-900">
                  {player.name}
                </td>
                <td class="px-4 py-3 text-sm text-gray-500">
                  {player.number || "-"}
                </td>
                <td class="px-4 py-3 text-sm text-gray-500">
                  {player.external_id || "-"}
                </td>
                <td class="px-4 py-3 text-sm text-gray-500">
                  {if player.user, do: player.user.email, else: "-"}
                </td>
                <td class="px-4 py-3 text-sm text-right whitespace-nowrap">
                  <.link navigate={~p"/admin/players/#{player.slug}/edit"}>
                    <.button variant="invisible" size="sm">
                      <.icon name="hero-pencil-square" class="w-4 h-4" />
                    </.button>
                  </.link>
                  <.button
                    variant="invisible"
                    size="sm"
                    phx-click={JS.push("scrub", value: %{id: player.id})}
                    data-confirm="Are you sure you want to scrub this player? This will anonymize their data but keep the record for historical purposes."
                  >
                    <.icon name="hero-trash" class="w-4 h-4" />
                  </.button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <.pagination
          page={@page}
          total_pages={@total_pages}
          path={~p"/admin/players"}
          params={filter_params_for_pagination(@filter_form, @per_page, @sort_by, @sort_dir)}
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
        patch={~p"/admin/players?#{@href_params}"}
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
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page = parse_page(params["page"])
    per_page = parse_per_page(params["per_page"])
    search = params["search"]
    linked = params["linked"]
    sort_by = parse_sort_by(params["sort_by"])
    sort_dir = parse_sort_dir(params["sort_dir"])

    filter_params =
      %{}
      |> maybe_put("search", search)
      |> maybe_put("linked", linked)

    result =
      Players.list_players_paginated(socket.assigns.current_scope,
        page: page,
        per_page: per_page,
        search: search,
        linked: linked,
        sort_by: String.to_existing_atom(sort_by),
        sort_dir: String.to_existing_atom(sort_dir)
      )

    has_filters? = search not in [nil, ""] or linked not in [nil, ""]

    sort_params = sort_params_for_url(filter_params, per_page, sort_by, sort_dir)

    {:noreply,
     socket
     |> assign(:page, result.page)
     |> assign(:total_pages, result.total_pages)
     |> assign(:total_count, result.total_count)
     |> assign(:per_page, result.per_page)
     |> assign(:players_empty?, result.players == [])
     |> assign(:has_filters?, has_filters?)
     |> assign(:filter_params, filter_params)
     |> assign(:filter_form, to_form(filter_params))
     |> assign(:sort_by, sort_by)
     |> assign(:sort_dir, sort_dir)
     |> assign(:sort_params, sort_params)
     |> stream(:players, result.players, reset: true)}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filter_params =
      %{}
      |> maybe_put("search", params["search"])
      |> maybe_put("linked", params["linked"])

    per_page = socket.assigns.per_page
    sort_by = socket.assigns.sort_by
    sort_dir = socket.assigns.sort_dir

    params =
      filter_params
      |> Map.put("page", "1")
      |> maybe_put_non_default("per_page", per_page, @default_per_page)
      |> maybe_put_non_default("sort_by", sort_by, "name")
      |> maybe_put_non_default("sort_dir", sort_dir, "asc")

    {:noreply, push_patch(socket, to: ~p"/admin/players?#{params}")}
  end

  def handle_event("change_per_page", %{"per_page" => per_page}, socket) do
    params =
      filter_params_for_pagination(
        socket.assigns.filter_form,
        parse_per_page(per_page),
        socket.assigns.sort_by,
        socket.assigns.sort_dir
      )
      |> Map.put("page", "1")
      |> Map.put("per_page", per_page)

    {:noreply, push_patch(socket, to: ~p"/admin/players?#{params}")}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/players")}
  end

  def handle_event("scrub", %{"id" => id}, socket) do
    player = Players.get_player_with_preloads!(socket.assigns.current_scope, id)
    {:ok, scrubbed_player} = Players.scrub_player(socket.assigns.current_scope, player)

    scrubbed_player =
      Players.get_player_with_preloads!(socket.assigns.current_scope, scrubbed_player.id)

    {:noreply,
     socket
     |> put_flash(:info, "Player scrubbed successfully")
     |> stream_insert(:players, scrubbed_player)}
  end

  @allowed_sort_fields ~w(name)

  defp parse_sort_by(val) when is_binary(val) do
    if val in @allowed_sort_fields, do: val, else: "name"
  end

  defp parse_sort_by(_), do: "name"

  defp parse_sort_dir("asc"), do: "asc"
  defp parse_sort_dir("desc"), do: "desc"
  defp parse_sort_dir(_), do: "asc"

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

  defp sort_params_for_url(filter_params, per_page, sort_by, sort_dir) do
    base =
      filter_params
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()

    base = if per_page != @default_per_page, do: Map.put(base, "per_page", per_page), else: base
    base = if sort_by != "name", do: Map.put(base, "sort_by", sort_by), else: base
    base = if sort_dir != "asc", do: Map.put(base, "sort_dir", sort_dir), else: base
    base
  end

  defp filter_params_for_pagination(filter_form, per_page, sort_by, sort_dir) do
    params =
      %{}
      |> maybe_put("search", filter_form[:search].value)
      |> maybe_put("linked", filter_form[:linked].value)

    params =
      if per_page != @default_per_page,
        do: Map.put(params, "per_page", per_page),
        else: params

    params = if sort_by != "name", do: Map.put(params, "sort_by", sort_by), else: params
    params = if sort_dir != "asc", do: Map.put(params, "sort_dir", sort_dir), else: params
    params
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp maybe_put_non_default(map, _key, value, default) when value == default, do: map
  defp maybe_put_non_default(map, key, value, _default), do: Map.put(map, key, value)
end
