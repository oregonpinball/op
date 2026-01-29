defmodule OPWeb.Admin.PlayerLive.Index do
  use OPWeb, :live_view

  alias OP.Players

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

        <div class="mt-6 space-y-4">
          <.form
            for={@filter_form}
            id="player-filters"
            phx-change="filter"
            phx-submit="filter"
            class="flex flex-col sm:flex-row gap-4"
          >
            <div class="flex-1">
              <.input
                field={@filter_form[:search]}
                type="search"
                placeholder="Search players by name..."
                phx-debounce="300"
                class="w-full input"
              />
            </div>
            <div class="w-full sm:w-48">
              <.input
                field={@filter_form[:linked]}
                type="select"
                options={[
                  {"All players", ""},
                  {"Linked to user", "linked"},
                  {"Not linked", "unlinked"}
                ]}
                class="w-full select"
              />
            </div>
          </.form>

          <.table id="players" rows={@streams.players}>
            <:col :let={{_id, player}} label="Name">{player.name}</:col>
            <:col :let={{_id, player}} label="External ID">{player.external_id || "-"}</:col>
            <:col :let={{_id, player}} label="Linked User">
              {if player.user, do: player.user.email, else: "-"}
            </:col>
            <:action :let={{_id, player}}>
              <.link navigate={~p"/admin/players/#{player.slug}/edit"}>
                <.button size="sm" variant="invisible">Edit</.button>
              </.link>
            </:action>
            <:action :let={{_id, player}}>
              <.button
                size="sm"
                color="error"
                variant="invisible"
                phx-click={JS.push("scrub", value: %{id: player.id})}
                data-confirm="Are you sure you want to scrub this player? This will anonymize their data but keep the record for historical purposes."
              >
                Scrub
              </.button>
            </:action>
          </.table>

          <div :if={@players_empty?} class="text-center text-base-content/70 py-8">
            <%= if @has_filters? do %>
              No players match your search criteria.
            <% else %>
              No players found. Create your first player to get started.
            <% end %>
          </div>

          <.pagination
            page={@page}
            total_pages={@total_pages}
            path={~p"/admin/players"}
            params={@filter_params}
          />
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
  def handle_params(params, _uri, socket) do
    page = parse_page(params["page"])
    search = params["search"]
    linked = params["linked"]

    filter_params =
      %{}
      |> maybe_put("search", search)
      |> maybe_put("linked", linked)

    result =
      Players.list_players_paginated(socket.assigns.current_scope,
        page: page,
        search: search,
        linked: linked
      )

    has_filters? = search not in [nil, ""] or linked not in [nil, ""]

    {:noreply,
     socket
     |> assign(:page, result.page)
     |> assign(:total_pages, result.total_pages)
     |> assign(:total_count, result.total_count)
     |> assign(:players_empty?, result.players == [])
     |> assign(:has_filters?, has_filters?)
     |> assign(:filter_params, filter_params)
     |> assign(:filter_form, to_form(filter_params))
     |> stream(:players, result.players, reset: true)}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filter_params =
      %{}
      |> maybe_put("search", params["search"])
      |> maybe_put("linked", params["linked"])

    {:noreply, push_patch(socket, to: ~p"/admin/players?#{filter_params}")}
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

  defp parse_page(nil), do: 1

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {num, _} when num > 0 -> num
      _ -> 1
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
