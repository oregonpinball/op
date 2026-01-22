defmodule OPWeb.ImportLive do
  @moduledoc """
  LiveView for importing tournaments from Matchplay Events API.

  The import process is split into steps:
  1. Enter Matchplay tournament ID
  2. Review and map players to existing players or create new ones
  3. Tournament details - edit tournament info and select location/season (required)
  4. Execute import
  """
  use OPWeb, :live_view

  alias OP.Leagues
  alias OP.Locations
  alias OP.Players
  alias OP.Tournaments.Import

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-4xl mx-auto">
        <.header>
          Import from Matchplay
          <:subtitle>Import tournament data and standings from Matchplay Events</:subtitle>
        </.header>

        <div class="mt-8">
          <%= case @step do %>
            <% :enter_id -> %>
              <.enter_id_step form={@form} loading={@loading} />
            <% :match_players -> %>
              <.match_players_step
                tournament={@tournament_preview}
                player_mappings={@player_mappings}
                search_results={@search_results}
                search_index={@search_index}
              />
            <% :tournament_details -> %>
              <.tournament_details_step
                tournament={@tournament_preview}
                player_mappings={@player_mappings}
                tournament_form={@tournament_form}
                location_options={@location_options}
                league_options={@league_options}
                season_options={@season_options}
                selected_league_id={@selected_league_id}
                location_data={@location_data}
                matched_location={@matched_location}
                location_created={@location_created}
              />
            <% :importing -> %>
              <.importing_step />
            <% :success -> %>
              <.success_step result={@import_result} />
            <% :error -> %>
              <.error_step error={@error} />
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Step components

  defp enter_id_step(assigns) do
    ~H"""
    <.form for={@form} id="import-form" phx-submit="fetch_preview" class="space-y-6">
      <.input
        field={@form[:matchplay_id]}
        type="text"
        label="Matchplay Tournament ID"
        placeholder="e.g., 12345 or the URL"
        required
      />
      <p class="text-sm text-slate-500">
        Enter the tournament ID from Matchplay. You can find it in the tournament URL:
        <code class="bg-slate-100 px-1 rounded">
          https://app.matchplay.events/tournaments/<strong>12345</strong>
        </code>
      </p>
      <.button type="submit" variant="solid" disabled={@loading}>
        <%= if @loading do %>
          <.icon name="hero-arrow-path" class="size-5 mr-2 animate-spin" /> Fetching...
        <% else %>
          <.icon name="hero-arrow-down-tray" class="size-5 mr-2" /> Fetch Tournament
        <% end %>
      </.button>
    </.form>
    """
  end

  defp match_players_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="bg-slate-50 rounded-lg p-4">
        <h3 class="font-semibold text-lg">{@tournament["name"]}</h3>
        <p class="text-sm text-slate-600">
          <%= if @tournament["startUtc"] do %>
            {format_date(@tournament["startUtc"])}
          <% end %>
        </p>
      </div>

      <div>
        <h4 class="font-medium mb-4">
          Match Players ({length(@player_mappings)} players)
        </h4>
        <p class="text-sm text-slate-600 mb-4">
          Review player mappings below. Auto-matched players have been linked automatically.
          For others, select an existing player or create a new one.
        </p>

        <div class="flex justify-end mb-4">
          <.button
            type="button"
            variant="invisible"
            phx-click="create_unselected_players"
            disabled={not has_unmatched_players?(@player_mappings)}
          >
            <.icon name="hero-plus-circle" class="size-5 mr-2" /> Create unselected players
          </.button>
        </div>

        <div class="border rounded-lg overflow-hidden">
          <table class="min-w-full divide-y divide-slate-200">
            <thead class="bg-slate-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">
                  Pos
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">
                  Matchplay Name
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">
                  Status
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase">
                  Local Player
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-200">
              <%= for {mapping, index} <- Enum.with_index(@player_mappings) do %>
                <tr id={"player-row-#{index}"}>
                  <td class="px-4 py-3 text-sm text-slate-900">
                    {mapping.position}
                  </td>
                  <td class="px-4 py-3 text-sm text-slate-900">
                    {mapping.matchplay_name}
                  </td>
                  <td class="px-4 py-3 text-sm">
                    <.match_status_badge match_type={mapping.match_type} />
                  </td>
                  <td class="px-4 py-3 text-sm">
                    <.player_selector
                      mapping={mapping}
                      index={index}
                      search_results={@search_results}
                      search_index={@search_index}
                    />
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>

      <div class="flex gap-4">
        <.button type="button" variant="invisible" phx-click="back_to_id">
          <.icon name="hero-arrow-left" class="size-5 mr-2" /> Back
        </.button>
        <.button
          type="button"
          variant="solid"
          phx-click="continue_to_confirm"
          disabled={not all_players_mapped?(@player_mappings)}
        >
          Continue <.icon name="hero-arrow-right" class="size-5 ml-2" />
        </.button>
      </div>
    </div>
    """
  end

  defp match_status_badge(assigns) do
    ~H"""
    <%= case @match_type do %>
      <% :auto -> %>
        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
          <.icon name="hero-check-circle" class="size-4 mr-1" /> Auto-matched
        </span>
      <% :suggested -> %>
        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
          <.icon name="hero-light-bulb" class="size-4 mr-1" /> Suggested
        </span>
      <% :manual -> %>
        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800">
          <.icon name="hero-user" class="size-4 mr-1" /> Manual
        </span>
      <% :create_new -> %>
        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-800">
          <.icon name="hero-plus-circle" class="size-4 mr-1" /> Create New
        </span>
      <% :unmatched -> %>
        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
          <.icon name="hero-question-mark-circle" class="size-4 mr-1" /> Needs Match
        </span>
    <% end %>
    """
  end

  defp player_selector(assigns) do
    ~H"""
    <%= case @mapping.match_type do %>
      <% :auto -> %>
        <span class="text-slate-700">{@mapping.local_player.name}</span>
      <% :create_new -> %>
        <span class="text-amber-700 italic">Will create: {@mapping.matchplay_name}</span>
      <% :manual -> %>
        <span class="text-slate-700">{@mapping.local_player.name}</span>
        <button
          type="button"
          phx-click="clear_mapping"
          phx-value-index={@index}
          class="ml-2 text-slate-400 hover:text-slate-600"
        >
          <.icon name="hero-x-mark" class="size-4" />
        </button>
      <% :suggested -> %>
        <div class="space-y-2">
          <div class="flex flex-wrap gap-1">
            <%= for player <- @mapping.suggested_players do %>
              <button
                type="button"
                phx-click="select_player"
                phx-value-index={@index}
                phx-value-player-id={player.id}
                class="inline-flex items-center px-2 py-1 rounded text-xs bg-emerald-50 text-emerald-700 hover:bg-emerald-100"
              >
                {player.name}
              </button>
            <% end %>
          </div>
          <button
            type="button"
            phx-click="create_new_player"
            phx-value-index={@index}
            class="text-sm text-amber-600 hover:text-amber-700"
          >
            Create New Instead
          </button>
        </div>
      <% :unmatched -> %>
        <div class="space-y-2">
          <%= if @mapping.suggested_players != [] do %>
            <div class="flex flex-wrap gap-1">
              <%= for player <- @mapping.suggested_players do %>
                <button
                  type="button"
                  phx-click="select_player"
                  phx-value-index={@index}
                  phx-value-player-id={player.id}
                  class="inline-flex items-center px-2 py-1 rounded text-xs bg-blue-50 text-blue-700 hover:bg-blue-100"
                >
                  {player.name}
                </button>
              <% end %>
            </div>
          <% end %>

          <div class="flex gap-2">
            <form phx-change="search_player" phx-submit="search_player" class="flex-1">
              <input type="hidden" name="index" value={@index} />
              <input
                type="text"
                name="query"
                placeholder="Search players..."
                value={if @search_index == @index, do: "", else: ""}
                class="w-full px-2 py-1 text-sm border rounded"
                phx-debounce="300"
              />
            </form>
            <button
              type="button"
              phx-click="create_new_player"
              phx-value-index={@index}
              class="px-2 py-1 text-xs bg-amber-50 text-amber-700 rounded hover:bg-amber-100"
            >
              Create New
            </button>
          </div>

          <%= if @search_index == @index and @search_results != [] do %>
            <div class="border rounded bg-white shadow-sm max-h-32 overflow-y-auto">
              <%= for player <- @search_results do %>
                <button
                  type="button"
                  phx-click="select_player"
                  phx-value-index={@index}
                  phx-value-player-id={player.id}
                  class="w-full px-2 py-1 text-left text-sm hover:bg-slate-50"
                >
                  {player.name}
                </button>
              <% end %>
            </div>
          <% end %>
        </div>
    <% end %>
    """
  end

  defp tournament_details_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <.form
        for={@tournament_form}
        id="tournament-details-form"
        phx-change="validate_tournament"
        phx-submit="execute_import"
      >
        <div class="space-y-6">
          <!-- Tournament Info Section -->
          <div class="bg-slate-50 rounded-lg p-4 space-y-4">
            <div class="flex items-center justify-between">
              <h3 class="font-semibold text-lg">Tournament Details</h3>
              <%= if @tournament["link"] do %>
                <a
                  href={@tournament["link"]}
                  target="_blank"
                  class="text-sm text-blue-600 hover:underline"
                >
                  View on Matchplay
                  <.icon name="hero-arrow-top-right-on-square" class="size-3 inline" />
                </a>
              <% end %>
            </div>

            <.input field={@tournament_form[:name]} type="text" label="Tournament Name" required />
            <.input field={@tournament_form[:description]} type="textarea" label="Description" />
            <.input
              field={@tournament_form[:start_at]}
              type="datetime-local"
              label="Start Date"
              required
            />
            <.input
              field={@tournament_form[:meaningful_games]}
              type="number"
              label="Meaningful Games"
              step="0.5"
              min="0"
            />
            <p class="text-sm text-slate-500">
              Number of meaningful games for TGP calculation. Leave blank to set later.
            </p>
          </div>
          
    <!-- Location Section (Required) -->
          <div class="bg-slate-50 rounded-lg p-4 space-y-4">
            <h3 class="font-semibold text-lg">Location</h3>

            <%= if @location_data do %>
              <div class="text-sm text-slate-600 bg-white rounded p-3 border">
                <p class="font-medium">Matchplay venue:</p>
                <p>{@location_data["name"]}</p>
                <%= if @location_data["address"] do %>
                  <p class="text-slate-500">{@location_data["address"]}</p>
                <% end %>
                <%= cond do %>
                  <% @location_created -> %>
                    <p class="mt-2 text-blue-600">
                      <.icon name="hero-plus-circle" class="size-4 inline" />
                      Created new local location
                    </p>
                  <% @matched_location -> %>
                    <p class="mt-2 text-green-600">
                      <.icon name="hero-check-circle" class="size-4 inline" />
                      Auto-matched to local location
                    </p>
                  <% true -> %>
                <% end %>
              </div>
            <% end %>

            <.input
              field={@tournament_form[:location_id]}
              type="select"
              label="Location"
              options={@location_options}
              prompt="-- Select a location --"
              required
            />
            <%= if is_nil(@matched_location) do %>
              <p class="text-sm text-slate-500">
                If your location isn't listed, create it first in the admin area.
              </p>
            <% end %>
          </div>
          
    <!-- League/Season Section -->
          <div class="bg-slate-50 rounded-lg p-4 space-y-4">
            <h3 class="font-semibold text-lg">League & Season</h3>

            <.input
              field={@tournament_form[:league_id]}
              type="select"
              label="League"
              options={@league_options}
              prompt="-- Select a league --"
            />

            <.input
              field={@tournament_form[:season_id]}
              type="select"
              label="Season"
              options={@season_options}
              prompt={
                if @selected_league_id,
                  do: "-- Select a season --",
                  else: "-- Select a league first --"
              }
              required
              disabled={is_nil(@selected_league_id)}
            />
          </div>
          
    <!-- Import Summary -->
          <div class="bg-slate-50 rounded-lg p-4">
            <h4 class="font-medium mb-4">Import Summary</h4>

            <dl class="grid grid-cols-2 gap-4 text-sm">
              <div>
                <dt class="text-slate-500">Total Players</dt>
                <dd class="font-medium">{length(@player_mappings)}</dd>
              </div>
              <div>
                <dt class="text-slate-500">New Players to Create</dt>
                <dd class="font-medium">
                  {Enum.count(@player_mappings, &(&1.match_type == :create_new))}
                </dd>
              </div>
              <div>
                <dt class="text-slate-500">Auto-matched</dt>
                <dd class="font-medium">
                  {Enum.count(@player_mappings, &(&1.match_type == :auto))}
                </dd>
              </div>
              <div>
                <dt class="text-slate-500">Manually Mapped</dt>
                <dd class="font-medium">
                  {Enum.count(@player_mappings, &(&1.match_type in [:suggested, :manual]))}
                </dd>
              </div>
            </dl>
          </div>
          
    <!-- Actions -->
          <div class="flex gap-4">
            <.button type="button" variant="invisible" phx-click="back_to_match">
              <.icon name="hero-arrow-left" class="size-5 mr-2" /> Back
            </.button>
            <.button
              type="submit"
              variant="solid"
              disabled={not tournament_form_valid?(@tournament_form)}
            >
              <.icon name="hero-arrow-down-tray" class="size-5 mr-2" /> Import Tournament
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  defp importing_step(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center py-12">
      <.icon name="hero-arrow-path" class="size-12 animate-spin text-emerald-600" />
      <p class="mt-4 text-lg text-slate-600">Importing tournament data...</p>
    </div>
    """
  end

  defp success_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="rounded-lg bg-green-50 border border-green-200 p-6">
        <div class="flex items-center">
          <.icon name="hero-check-circle" class="size-8 text-green-600" />
          <h3 class="ml-3 text-lg font-semibold text-green-800">Import Successful</h3>
        </div>
        <dl class="mt-4 grid grid-cols-2 gap-4 text-sm">
          <div>
            <dt class="text-slate-500">Tournament</dt>
            <dd class="font-medium">{@result.tournament.name}</dd>
          </div>
          <div>
            <dt class="text-slate-500">Status</dt>
            <dd class="font-medium">
              {if @result.is_new, do: "Created", else: "Updated"}
            </dd>
          </div>
          <div>
            <dt class="text-slate-500">Players Created</dt>
            <dd class="font-medium">{@result.players_created}</dd>
          </div>
          <div>
            <dt class="text-slate-500">Players Updated</dt>
            <dd class="font-medium">{@result.players_updated}</dd>
          </div>
          <div>
            <dt class="text-slate-500">Standings</dt>
            <dd class="font-medium">{@result.standings_count}</dd>
          </div>
        </dl>
      </div>

      <div class="flex gap-4">
        <.button type="button" variant="invisible" phx-click="reset">
          <.icon name="hero-plus" class="size-5 mr-2" /> Import Another
        </.button>
        <.link navigate={~p"/tournaments"} class="btn btn-solid">
          View Tournaments
        </.link>
      </div>
    </div>
    """
  end

  defp error_step(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="rounded-lg bg-red-50 border border-red-200 p-6">
        <div class="flex items-center">
          <.icon name="hero-exclamation-circle" class="size-8 text-red-600" />
          <h3 class="ml-3 text-lg font-semibold text-red-800">Import Failed</h3>
        </div>
        <p class="mt-2 text-red-700">{@error}</p>
      </div>

      <.button type="button" variant="invisible" phx-click="reset">
        <.icon name="hero-arrow-path" class="size-5 mr-2" /> Try Again
      </.button>
    </div>
    """
  end

  # Mount and lifecycle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, reset_state(socket)}
  end

  # Event handlers

  @impl true
  def handle_event("fetch_preview", %{"matchplay_id" => matchplay_id}, socket) do
    matchplay_id = extract_tournament_id(matchplay_id)

    socket =
      socket
      |> assign(:loading, true)
      |> assign(:matchplay_id, matchplay_id)
      |> start_async(:fetch_preview, fn ->
        Import.fetch_tournament_preview(matchplay_id)
      end)

    {:noreply, socket}
  end

  def handle_event("back_to_id", _params, socket) do
    {:noreply, assign(socket, step: :enter_id)}
  end

  def handle_event("back_to_match", _params, socket) do
    {:noreply, assign(socket, step: :match_players)}
  end

  def handle_event("search_player", %{"index" => index, "query" => query}, socket) do
    index = String.to_integer(index)

    search_results =
      if String.length(query) >= 2 do
        Players.search_players(socket.assigns.current_scope, query)
      else
        []
      end

    {:noreply, assign(socket, search_results: search_results, search_index: index)}
  end

  def handle_event("select_player", %{"index" => index, "player-id" => player_id}, socket) do
    index = String.to_integer(index)
    player_id = String.to_integer(player_id)
    player = Players.get_player!(socket.assigns.current_scope, player_id)

    player_mappings =
      List.update_at(socket.assigns.player_mappings, index, fn mapping ->
        %{mapping | match_type: :manual, local_player_id: player_id, local_player: player}
      end)

    {:noreply,
     assign(socket, player_mappings: player_mappings, search_results: [], search_index: nil)}
  end

  def handle_event("create_new_player", %{"index" => index}, socket) do
    index = String.to_integer(index)

    player_mappings =
      List.update_at(socket.assigns.player_mappings, index, fn mapping ->
        %{mapping | match_type: :create_new, local_player_id: nil, local_player: nil}
      end)

    {:noreply, assign(socket, player_mappings: player_mappings)}
  end

  def handle_event("create_unselected_players", _params, socket) do
    player_mappings =
      Enum.map(socket.assigns.player_mappings, fn mapping ->
        if mapping.match_type == :unmatched do
          %{mapping | match_type: :create_new, local_player_id: nil, local_player: nil}
        else
          mapping
        end
      end)

    {:noreply, assign(socket, player_mappings: player_mappings)}
  end

  def handle_event("clear_mapping", %{"index" => index}, socket) do
    index = String.to_integer(index)

    player_mappings =
      List.update_at(socket.assigns.player_mappings, index, fn mapping ->
        %{mapping | match_type: :unmatched, local_player_id: nil, local_player: nil}
      end)

    {:noreply, assign(socket, player_mappings: player_mappings)}
  end

  def handle_event("continue_to_confirm", _params, socket) do
    scope = socket.assigns.current_scope
    tournament = socket.assigns.tournament_preview
    matched_location = socket.assigns.matched_location

    # Load location and league options
    location_options =
      Locations.list_locations(scope)
      |> Enum.map(&{&1.name, &1.id})
      |> Enum.sort_by(&elem(&1, 0))

    league_options =
      Leagues.list_leagues(scope)
      |> Enum.map(&{&1.name, &1.id})
      |> Enum.sort_by(&elem(&1, 0))

    # Build initial form values from Matchplay data
    initial_values = %{
      "name" => tournament["name"] || "",
      "description" => tournament["description"] || "",
      "start_at" => format_datetime_local(tournament["startUtc"]),
      "location_id" => if(matched_location, do: to_string(matched_location.id), else: ""),
      "league_id" => "",
      "season_id" => "",
      "meaningful_games" => ""
    }

    {:noreply,
     socket
     |> assign(:step, :tournament_details)
     |> assign(:tournament_form, to_form(initial_values))
     |> assign(:location_options, location_options)
     |> assign(:league_options, league_options)
     |> assign(:season_options, [])
     |> assign(:selected_league_id, nil)}
  end

  def handle_event("validate_tournament", %{"name" => _} = params, socket) do
    scope = socket.assigns.current_scope

    # Check if league changed and update seasons
    league_id = params["league_id"]
    current_league_id = socket.assigns.selected_league_id

    {season_options, selected_league_id} =
      if league_id != "" and league_id != current_league_id do
        league_id_int = String.to_integer(league_id)
        seasons = Leagues.list_seasons_by_league(scope, league_id_int)
        options = Enum.map(seasons, &{&1.name, &1.id})
        {options, league_id}
      else
        if league_id == "" do
          {[], nil}
        else
          {socket.assigns.season_options, current_league_id}
        end
      end

    {:noreply,
     socket
     |> assign(:tournament_form, to_form(params))
     |> assign(:season_options, season_options)
     |> assign(:selected_league_id, selected_league_id)}
  end

  def handle_event("execute_import", params, socket) do
    # Extract assigns before start_async to avoid copying entire socket
    current_scope = socket.assigns.current_scope
    tournament_preview = socket.assigns.tournament_preview
    player_mappings = socket.assigns.player_mappings

    # Build tournament overrides from form params
    tournament_overrides = build_tournament_overrides(params)

    socket =
      socket
      |> assign(:step, :importing)
      |> start_async(:execute_import, fn ->
        Import.execute_import(
          current_scope,
          tournament_preview,
          player_mappings,
          tournament_overrides
        )
      end)

    {:noreply, socket}
  end

  def handle_event("reset", _params, socket) do
    {:noreply, reset_state(socket)}
  end

  # Async handlers

  @impl true
  def handle_async(:fetch_preview, {:ok, {:ok, result}}, socket) do
    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:step, :match_players)
     |> assign(:tournament_preview, result.tournament)
     |> assign(:player_mappings, result.player_mappings)
     |> assign(:location_data, result.location_data)
     |> assign(:matched_location, result.matched_location)
     |> assign(:location_created, result.location_created)}
  end

  def handle_async(:fetch_preview, {:ok, {:error, error}}, socket) do
    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:step, :error)
     |> assign(:error, format_error(error))}
  end

  def handle_async(:fetch_preview, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:loading, false)
     |> assign(:step, :error)
     |> assign(:error, "Failed to fetch tournament: #{inspect(reason)}")}
  end

  def handle_async(:execute_import, {:ok, {:ok, result}}, socket) do
    {:noreply,
     socket
     |> assign(:step, :success)
     |> assign(:import_result, result)}
  end

  def handle_async(:execute_import, {:ok, {:error, error}}, socket) do
    {:noreply,
     socket
     |> assign(:step, :error)
     |> assign(:error, format_error(error))}
  end

  def handle_async(:execute_import, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:step, :error)
     |> assign(:error, "Import failed: #{inspect(reason)}")}
  end

  # Helpers

  defp reset_state(socket) do
    socket
    |> assign(:page_title, "Import Tournament")
    |> assign(:step, :enter_id)
    |> assign(:form, to_form(%{"matchplay_id" => ""}))
    |> assign(:loading, false)
    |> assign(:matchplay_id, nil)
    |> assign(:tournament_preview, nil)
    |> assign(:player_mappings, [])
    |> assign(:search_results, [])
    |> assign(:search_index, nil)
    |> assign(:import_result, nil)
    |> assign(:error, nil)
    # Tournament details form assigns
    |> assign(:tournament_form, nil)
    |> assign(:location_data, nil)
    |> assign(:matched_location, nil)
    |> assign(:location_created, false)
    |> assign(:location_options, [])
    |> assign(:league_options, [])
    |> assign(:season_options, [])
    |> assign(:selected_league_id, nil)
  end

  defp extract_tournament_id(input) do
    input = String.trim(input)

    # Check if it's a URL
    case Regex.run(~r/tournaments\/(\d+)/, input) do
      [_, id] -> id
      nil -> input
    end
  end

  defp all_players_mapped?(mappings) do
    Enum.all?(mappings, fn m -> m.match_type != :unmatched end)
  end

  defp has_unmatched_players?(mappings) do
    Enum.any?(mappings, fn m -> m.match_type == :unmatched end)
  end

  defp format_date(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} ->
        Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p UTC")

      _ ->
        datetime_string
    end
  end

  defp format_date(_), do: ""

  defp format_error(:api_token_required) do
    "Matchplay API token is required. Please set the MATCHPLAY_API_TOKEN environment variable."
  end

  defp format_error(%OP.Matchplay.Errors.NotFoundError{resource_id: id}) do
    "Tournament #{id} not found on Matchplay. Please check the ID and try again."
  end

  defp format_error(%OP.Matchplay.Errors.ApiError{message: msg}) do
    "Matchplay API error: #{msg}"
  end

  defp format_error(%OP.Matchplay.Errors.NetworkError{}) do
    "Network error connecting to Matchplay. Please check your connection and try again."
  end

  defp format_error(error) when is_binary(error), do: error
  defp format_error(error), do: inspect(error)

  defp format_datetime_local(nil), do: ""

  defp format_datetime_local(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _} ->
        # Format as datetime-local input value: YYYY-MM-DDTHH:MM
        Calendar.strftime(datetime, "%Y-%m-%dT%H:%M")

      _ ->
        ""
    end
  end

  defp tournament_form_valid?(form) do
    params = form.params

    name = params["name"] || ""
    start_at = params["start_at"] || ""
    location_id = params["location_id"] || ""
    season_id = params["season_id"] || ""

    name != "" and start_at != "" and location_id != "" and season_id != ""
  end

  defp build_tournament_overrides(params) do
    %{
      name: params["name"],
      description: params["description"],
      start_at: params["start_at"],
      location_id: parse_id(params["location_id"]),
      season_id: parse_id(params["season_id"]),
      meaningful_games: parse_float(params["meaningful_games"])
    }
  end

  defp parse_float(""), do: nil
  defp parse_float(nil), do: nil
  defp parse_float(val) when is_binary(val), do: String.to_float(val)
  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val / 1

  defp parse_id(""), do: nil
  defp parse_id(nil), do: nil
  defp parse_id(id) when is_binary(id), do: String.to_integer(id)
  defp parse_id(id) when is_integer(id), do: id
end
