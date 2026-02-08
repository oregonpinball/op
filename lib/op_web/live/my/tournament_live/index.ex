defmodule OPWeb.My.TournamentLive.Index do
  use OPWeb, :live_view

  alias OP.Locations
  alias OP.Tournaments

  @default_per_page 25

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
        <%!-- Tabs --%>
        <div class="border-b border-gray-200">
          <nav class="flex gap-6" aria-label="Tabs">
            <button
              phx-click="switch_tab"
              phx-value-tab="organized"
              class={[
                "py-3 px-1 border-b-2 text-sm font-semibold transition-colors",
                if(@active_tab == "organized",
                  do: "border-emerald-600 text-emerald-700",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                )
              ]}
            >
              Organized
            </button>
            <button
              phx-click="switch_tab"
              phx-value-tab="played"
              class={[
                "py-3 px-1 border-b-2 text-sm font-semibold transition-colors",
                if(@active_tab == "played",
                  do: "border-emerald-600 text-emerald-700",
                  else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                )
              ]}
            >
              Played
            </button>
          </nav>
        </div>

        <%!-- Organized Tab --%>
        <section :if={@active_tab == "organized"} class="mt-6">
          <.section_filters
            id="organized"
            filter_form={@org_filter_form}
            location_options={@location_options}
            prefix="org"
          />
          <.section_summary
            empty?={@org_empty?}
            pagination={@org_pagination}
            prefix="org"
            label="organized tournaments"
          />
          <.organized_cards streams={@streams} />
          <.pagination
            page={@org_pagination.page}
            total_pages={@org_pagination.total_pages}
            path={~p"/my/tournaments"}
            params={
              pagination_params(
                @org_filter_form,
                @org_pagination.per_page,
                @org_sort_by,
                @org_sort_dir,
                "org"
              )
              |> then(fn p ->
                if @active_tab != "organized", do: Map.put(p, "tab", @active_tab), else: p
              end)
            }
          />
        </section>

        <%!-- Played Tab --%>
        <section :if={@active_tab == "played"} class="mt-6">
          <.section_filters
            id="played"
            filter_form={@played_filter_form}
            location_options={@location_options}
            prefix="played"
          />
          <.section_summary
            empty?={@played_empty?}
            pagination={@played_pagination}
            prefix="played"
            label="played tournaments"
          />
          <.played_cards streams={@streams} user_player_id={@user_player_id} />
          <.pagination
            page={@played_pagination.page}
            total_pages={@played_pagination.total_pages}
            path={~p"/my/tournaments"}
            params={
              pagination_params(
                @played_filter_form,
                @played_pagination.per_page,
                @played_sort_by,
                @played_sort_dir,
                "played"
              )
              |> then(fn p ->
                if @active_tab != "organized", do: Map.put(p, "tab", @active_tab), else: p
              end)
            }
          />
        </section>
      </div>
    </Layouts.app>
    """
  end

  defp section_filters(assigns) do
    ~H"""
    <div class="mt-4 bg-white rounded-lg border border-gray-200 p-4">
      <.form
        for={@filter_form}
        id={"#{@id}-filters"}
        phx-change={"filter_#{@prefix}"}
        phx-submit={"filter_#{@prefix}"}
        class="space-y-4"
      >
        <div class="flex gap-4 items-end">
          <div class="flex-1">
            <.input
              field={@filter_form[:search]}
              type="search"
              label="Search tournaments"
              placeholder="Search by name..."
              phx-debounce="300"
            />
          </div>
          <.button
            type="button"
            variant="invisible"
            phx-click={"clear_#{@prefix}_filters"}
            class="mb-2"
          >
            <.icon name="hero-x-mark" class="w-4 h-4 mr-1" /> Clear
          </.button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <.input
            field={@filter_form[:location_id]}
            type="select"
            label="Location"
            options={@location_options}
            prompt="All locations"
          />
          <.input
            field={@filter_form[:start_date]}
            type="date"
            label="From date"
          />
          <.input
            field={@filter_form[:end_date]}
            type="date"
            label="To date"
          />
        </div>
      </.form>
    </div>
    """
  end

  defp section_summary(assigns) do
    ~H"""
    <div class="mt-4 flex items-center justify-between text-sm text-gray-500">
      <span>
        <%= if @empty? do %>
          No {@label} found
        <% else %>
          Showing {(@pagination.page - 1) * @pagination.per_page + 1} to {min(
            @pagination.page * @pagination.per_page,
            @pagination.total_count
          )} of {@pagination.total_count} {@label}
        <% end %>
      </span>
      <form phx-change={"change_#{@prefix}_per_page"}>
        <label for={"#{@prefix}-per-page"} class="mr-2">Per page:</label>
        <select
          id={"#{@prefix}-per-page"}
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
    """
  end

  attr :streams, :any, required: true

  defp organized_cards(assigns) do
    ~H"""
    <div
      id="organized-tournaments"
      phx-update="stream"
      class="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
    >
      <div id="empty-organized" class="hidden only:block col-span-full text-center py-8 text-gray-500">
        You haven't organized any tournaments yet.
      </div>
      <div
        :for={{id, tournament} <- @streams.organized_tournaments}
        id={id}
        class="rounded-lg bg-white shadow-sm hover:shadow-lg transition-all border-2 border-transparent hover:border-emerald-600"
      >
        <.link navigate={~p"/tournaments/#{tournament.slug}"}>
          <div
            class="h-30 rounded-t bg-cover"
            style={"background-image: url('#{OPWeb.Tournaments.banner_url(tournament)}')"}
          />
        </.link>
        <div class="p-4">
          <.link navigate={~p"/tournaments/#{tournament.slug}"}>
            <h3 class="text-xl font-semibold mt-1">{tournament.name}</h3>
          </.link>
          <p :if={tournament.start_at} class="text-sm font-medium mt-1">
            {Calendar.strftime(tournament.start_at, "%a, %b %d, %Y")}
          </p>
          <p :if={tournament.location} class="text-sm text-gray-500">
            @ {tournament.location.name}
          </p>
          <div class="mt-2">
            <span class={[
              "inline-flex items-center rounded-full px-2 py-1 text-xs font-medium",
              status_badge_class(tournament.status)
            ]}>
              {status_label(tournament.status)}
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :streams, :any, required: true
  attr :user_player_id, :any, required: true

  defp played_cards(assigns) do
    ~H"""
    <div
      id="played-tournaments"
      phx-update="stream"
      class="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
    >
      <div id="empty-played" class="hidden only:block col-span-full text-center py-8 text-gray-500">
        No tournament results found for your player profile.
      </div>
      <div
        :for={{id, tournament} <- @streams.played_tournaments}
        id={id}
        class="rounded-lg bg-white shadow-sm hover:shadow-lg transition-all border-2 border-transparent hover:border-emerald-600"
      >
        <.link navigate={~p"/tournaments/#{tournament.slug}"}>
          <div
            class="h-30 rounded-t bg-cover"
            style={"background-image: url('#{OPWeb.Tournaments.banner_url(tournament)}')"}
          />
        </.link>
        <div class="p-4">
          <.link navigate={~p"/tournaments/#{tournament.slug}"}>
            <h3 class="text-xl font-semibold mt-1">{tournament.name}</h3>
          </.link>
          <p :if={tournament.start_at} class="text-sm font-medium mt-1">
            {Calendar.strftime(tournament.start_at, "%a, %b %d, %Y")}
          </p>
          <p :if={tournament.location} class="text-sm text-gray-500">
            @ {tournament.location.name}
          </p>
          <% standing = Enum.find(tournament.standings, &(&1.player_id == @user_player_id)) %>
          <div :if={standing} class="mt-3 flex items-center gap-3">
            <span class="inline-flex items-center rounded-full bg-emerald-100 text-emerald-800 px-2.5 py-1 text-xs font-semibold">
              #{standing.position}
            </span>
            <span :if={standing.total_points} class="text-sm text-gray-600">
              {:erlang.float_to_binary(standing.total_points / 1, decimals: 1)} pts
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp status_badge_class(:draft), do: "bg-gray-100 text-gray-800"
  defp status_badge_class(:pending_review), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_class(:sanctioned), do: "bg-green-100 text-green-800"
  defp status_badge_class(:cancelled), do: "bg-red-100 text-red-800"
  defp status_badge_class(:rejected), do: "bg-orange-100 text-orange-800"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-800"

  defp status_label(:draft), do: "Draft"
  defp status_label(:pending_review), do: "Pending Review"
  defp status_label(:sanctioned), do: "Sanctioned"
  defp status_label(:cancelled), do: "Cancelled"
  defp status_label(:rejected), do: "Rejected"
  defp status_label(status), do: status

  @impl true
  def mount(_params, _session, socket) do
    locations = Locations.list_locations(socket.assigns.current_scope)
    location_options = Enum.map(locations, &{&1.name, &1.id})

    user = OP.Repo.preload(socket.assigns.current_scope.user, :player)
    player_id = if user.player, do: user.player.id

    {:ok,
     socket
     |> assign(:location_options, location_options)
     |> assign(:user_player_id, player_id)
     |> stream(:organized_tournaments, [])
     |> stream(:played_tournaments, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    active_tab = params["tab"] || "organized"

    socket =
      socket
      |> assign(:page_title, "My Tournaments")
      |> assign(:active_tab, active_tab)
      |> apply_organized_filters(params)
      |> apply_played_filters(params)

    {:noreply, socket}
  end

  @allowed_sort_fields ~w(name start_at location status)

  defp apply_organized_filters(socket, params) do
    page = parse_page(params["org_page"])
    per_page = parse_per_page(params["org_per_page"])
    search = params["org_search"] || ""
    location_id = params["org_location_id"] || ""
    start_date = params["org_start_date"] || ""
    end_date = params["org_end_date"] || ""
    sort_by = parse_sort_by(params["org_sort_by"])
    sort_dir = parse_sort_dir(params["org_sort_dir"])

    filter_params = %{
      "search" => search,
      "location_id" => location_id,
      "start_date" => start_date,
      "end_date" => end_date
    }

    {tournaments, pagination} =
      Tournaments.list_organized_tournaments_paginated(
        socket.assigns.current_scope,
        page: page,
        per_page: per_page,
        search: non_empty(search),
        location_id: non_empty(location_id),
        start_date: non_empty(start_date),
        end_date: non_empty(end_date),
        sort_by: String.to_existing_atom(sort_by),
        sort_dir: String.to_existing_atom(sort_dir)
      )

    socket
    |> assign(:org_filter_form, to_form(filter_params, as: :filters, id: "org_filters"))
    |> assign(:org_pagination, pagination)
    |> assign(:org_sort_by, sort_by)
    |> assign(:org_sort_dir, sort_dir)
    |> assign(:org_empty?, tournaments == [])
    |> stream(:organized_tournaments, tournaments, reset: true)
  end

  defp apply_played_filters(socket, params) do
    page = parse_page(params["played_page"])
    per_page = parse_per_page(params["played_per_page"])
    search = params["played_search"] || ""
    location_id = params["played_location_id"] || ""
    start_date = params["played_start_date"] || ""
    end_date = params["played_end_date"] || ""
    sort_by = parse_sort_by(params["played_sort_by"])
    sort_dir = parse_sort_dir(params["played_sort_dir"])

    filter_params = %{
      "search" => search,
      "location_id" => location_id,
      "start_date" => start_date,
      "end_date" => end_date
    }

    {tournaments, pagination} =
      Tournaments.list_played_tournaments_paginated(
        socket.assigns.current_scope,
        page: page,
        per_page: per_page,
        search: non_empty(search),
        location_id: non_empty(location_id),
        start_date: non_empty(start_date),
        end_date: non_empty(end_date),
        sort_by: String.to_existing_atom(sort_by),
        sort_dir: String.to_existing_atom(sort_dir)
      )

    socket
    |> assign(:played_filter_form, to_form(filter_params, as: :filters, id: "played_filters"))
    |> assign(:played_pagination, pagination)
    |> assign(:played_sort_by, sort_by)
    |> assign(:played_sort_dir, sort_dir)
    |> assign(:played_empty?, tournaments == [])
    |> stream(:played_tournaments, tournaments, reset: true)
  end

  defp pagination_params(filter_form, per_page, sort_by, sort_dir, prefix) do
    params = %{
      "#{prefix}_search" => filter_form[:search].value,
      "#{prefix}_location_id" => filter_form[:location_id].value,
      "#{prefix}_start_date" => filter_form[:start_date].value,
      "#{prefix}_end_date" => filter_form[:end_date].value
    }

    params =
      if per_page != @default_per_page,
        do: Map.put(params, "#{prefix}_per_page", per_page),
        else: params

    params =
      if sort_by != "start_at", do: Map.put(params, "#{prefix}_sort_by", sort_by), else: params

    params =
      if sort_dir != "desc", do: Map.put(params, "#{prefix}_sort_dir", sort_dir), else: params

    params
    |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
    |> Map.new()
  end

  defp parse_sort_by(val) when is_binary(val) do
    if val in @allowed_sort_fields, do: val, else: "start_at"
  end

  defp parse_sort_by(_), do: "start_at"

  defp parse_sort_dir("asc"), do: "asc"
  defp parse_sort_dir("desc"), do: "desc"
  defp parse_sort_dir(_), do: "desc"

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

  defp collect_all_params(socket) do
    params = %{}

    params =
      if socket.assigns.active_tab != "organized",
        do: Map.put(params, "tab", socket.assigns.active_tab),
        else: params

    # Organized section params
    org_form = socket.assigns.org_filter_form
    params = maybe_add(params, "org_search", org_form[:search].value)
    params = maybe_add(params, "org_location_id", org_form[:location_id].value)
    params = maybe_add(params, "org_start_date", org_form[:start_date].value)
    params = maybe_add(params, "org_end_date", org_form[:end_date].value)

    params =
      if socket.assigns.org_pagination.per_page != @default_per_page,
        do: Map.put(params, "org_per_page", socket.assigns.org_pagination.per_page),
        else: params

    params =
      if socket.assigns.org_sort_by != "start_at",
        do: Map.put(params, "org_sort_by", socket.assigns.org_sort_by),
        else: params

    params =
      if socket.assigns.org_sort_dir != "desc",
        do: Map.put(params, "org_sort_dir", socket.assigns.org_sort_dir),
        else: params

    # Played section params
    played_form = socket.assigns.played_filter_form
    params = maybe_add(params, "played_search", played_form[:search].value)
    params = maybe_add(params, "played_location_id", played_form[:location_id].value)
    params = maybe_add(params, "played_start_date", played_form[:start_date].value)
    params = maybe_add(params, "played_end_date", played_form[:end_date].value)

    params =
      if socket.assigns.played_pagination.per_page != @default_per_page,
        do: Map.put(params, "played_per_page", socket.assigns.played_pagination.per_page),
        else: params

    params =
      if socket.assigns.played_sort_by != "start_at",
        do: Map.put(params, "played_sort_by", socket.assigns.played_sort_by),
        else: params

    params =
      if socket.assigns.played_sort_dir != "desc",
        do: Map.put(params, "played_sort_dir", socket.assigns.played_sort_dir),
        else: params

    params
  end

  defp maybe_add(params, _key, nil), do: params
  defp maybe_add(params, _key, ""), do: params
  defp maybe_add(params, key, value), do: Map.put(params, key, value)

  # Organized section events
  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    params =
      collect_all_params(socket)
      |> Map.put("tab", tab)

    {:noreply, push_patch(socket, to: ~p"/my/tournaments?#{params}")}
  end

  def handle_event("filter_org", %{"filters" => filter_params}, socket) do
    params =
      collect_all_params(socket)
      |> Map.merge(%{
        "org_search" => filter_params["search"],
        "org_location_id" => filter_params["location_id"],
        "org_start_date" => filter_params["start_date"],
        "org_end_date" => filter_params["end_date"],
        "org_page" => "1"
      })
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()

    {:noreply, push_patch(socket, to: ~p"/my/tournaments?#{params}")}
  end

  def handle_event("clear_org_filters", _params, socket) do
    params =
      collect_all_params(socket)
      |> Map.drop([
        "org_search",
        "org_location_id",
        "org_start_date",
        "org_end_date",
        "org_page",
        "org_per_page",
        "org_sort_by",
        "org_sort_dir"
      ])

    {:noreply, push_patch(socket, to: ~p"/my/tournaments?#{params}")}
  end

  def handle_event("change_org_per_page", %{"per_page" => per_page}, socket) do
    params =
      collect_all_params(socket)
      |> Map.put("org_per_page", per_page)
      |> Map.put("org_page", "1")

    {:noreply, push_patch(socket, to: ~p"/my/tournaments?#{params}")}
  end

  # Played section events
  def handle_event("filter_played", %{"filters" => filter_params}, socket) do
    params =
      collect_all_params(socket)
      |> Map.merge(%{
        "played_search" => filter_params["search"],
        "played_location_id" => filter_params["location_id"],
        "played_start_date" => filter_params["start_date"],
        "played_end_date" => filter_params["end_date"],
        "played_page" => "1"
      })
      |> Enum.reject(fn {_k, v} -> v == "" or is_nil(v) end)
      |> Map.new()

    {:noreply, push_patch(socket, to: ~p"/my/tournaments?#{params}")}
  end

  def handle_event("clear_played_filters", _params, socket) do
    params =
      collect_all_params(socket)
      |> Map.drop([
        "played_search",
        "played_location_id",
        "played_start_date",
        "played_end_date",
        "played_page",
        "played_per_page",
        "played_sort_by",
        "played_sort_dir"
      ])

    {:noreply, push_patch(socket, to: ~p"/my/tournaments?#{params}")}
  end

  def handle_event("change_played_per_page", %{"per_page" => per_page}, socket) do
    params =
      collect_all_params(socket)
      |> Map.put("played_per_page", per_page)
      |> Map.put("played_page", "1")

    {:noreply, push_patch(socket, to: ~p"/my/tournaments?#{params}")}
  end
end
