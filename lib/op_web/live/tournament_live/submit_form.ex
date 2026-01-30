defmodule OPWeb.TournamentLive.SubmitForm do
  use OPWeb, :live_component

  alias OP.Tournaments
  alias OP.Leagues
  alias OP.Locations
  alias OP.Players

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Submit a tournament for sanctioning.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="tournament-submit-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-6 space-y-6"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <.input
          field={@form[:start_at]}
          type="datetime-local"
          label="Start Date"
          required
        />

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:season_id]}
            type="select"
            label="Season"
            options={@season_options}
            prompt="Select a season"
          />
          <.location_search
            form={@form}
            location_search_query={@location_search_query}
            location_search_results={@location_search_results}
            show_location_results={@show_location_results}
            selected_location={@selected_location}
            myself={@myself}
          />
        </div>

        <.input
          field={@form[:qualifying_format]}
          type="select"
          label="Qualifying Format"
          options={@qualifying_format_options}
        />

        <.input
          field={@form[:finals_format]}
          type="select"
          label="Finals Format"
          options={@finals_format_options}
        />

        <.input
          field={@form[:meaningful_games]}
          type="number"
          label="Meaningful Games"
          min="0"
          step="0.01"
          phx-debounce="blur"
        />

        <div class="border-t border-zinc-200 pt-6 mt-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-zinc-900">Standings</h3>
            <.button
              type="button"
              variant="invisible"
              phx-click="add_standing"
              phx-target={@myself}
            >
              <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add Standing
            </.button>
          </div>

          <.inputs_for :let={standing_form} field={@form[:standings]}>
            <input type="hidden" name="tournament[standings_sort][]" value={standing_form.index} />
            <div class="flex items-end gap-3 mb-3 p-3 bg-zinc-50 rounded-lg">
              <div class="w-20">
                <.input
                  field={standing_form[:position]}
                  type="number"
                  label="Position"
                  min="1"
                />
              </div>
              <div class="flex-1">
                <.player_search
                  standing_form={standing_form}
                  player_searches={@player_searches}
                  player_results={@player_results}
                  selected_players={@selected_players}
                  myself={@myself}
                />
              </div>
              <div class="flex items-center gap-4 pb-2">
                <label class="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    name={standing_form[:is_finals].name}
                    value="true"
                    checked={standing_form[:is_finals].value == true}
                    class="rounded border-zinc-300"
                  /> Finals
                </label>
              </div>
              <button
                type="button"
                name="tournament[standings_drop][]"
                value={standing_form.index}
                phx-click={JS.dispatch("change")}
                class="pb-2 text-red-500 hover:text-red-700"
              >
                <.icon name="hero-trash" class="w-5 h-5" />
              </button>
            </div>
          </.inputs_for>

          <input type="hidden" name="tournament[standings_drop][]" />

          <div
            :if={Enum.empty?(@form[:standings].value || [])}
            class="text-sm text-zinc-500 text-center py-4"
          >
            No standings added yet. Click "Add Standing" to add players.
          </div>
        </div>

        <div class="border-t border-zinc-200 pt-4 mt-4">
          <label class="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              name="code_of_conduct_agreed"
              value="true"
              checked={@code_of_conduct_agreed}
              phx-click="toggle_code_of_conduct"
              phx-target={@myself}
              class="rounded border-zinc-300"
            /> I agree that all
            <.link href="/f/rules/code-of-conduct" target="_blank" class="text-blue-600 underline">
              Code of Conduct
            </.link>
            policies were followed
          </label>
        </div>

        <div class="flex justify-end gap-4 pt-4">
          <.link navigate={~p"/tournaments"} class="inline-flex items-center">
            <.button type="button" variant="invisible">
              Cancel
            </.button>
          </.link>
          <.button
            type="submit"
            name="submit_action"
            value="draft"
            variant="invisible"
            phx-disable-with="Saving..."
          >
            Save as Draft
          </.button>
          <.button
            type="submit"
            name="submit_action"
            value="submit"
            variant="solid"
            phx-disable-with="Submitting..."
            disabled={!@code_of_conduct_agreed}
          >
            Submit for Sanctioning
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :location_search_query, :string, required: true
  attr :location_search_results, :list, required: true
  attr :show_location_results, :boolean, required: true
  attr :selected_location, :any, required: true
  attr :myself, :any, required: true

  defp location_search(assigns) do
    ~H"""
    <div class="relative">
      <label class="block text-sm font-semibold leading-6 text-zinc-800 mb-1">Location</label>
      <input
        type="hidden"
        name={@form[:location_id].name}
        value={(@selected_location && @selected_location.id) || ""}
      />

      <div :if={@selected_location} class="flex items-center gap-2">
        <span class="flex-1 px-3 py-2 bg-white border border-zinc-300 rounded-lg text-sm">
          {@selected_location.name}
        </span>
        <button
          type="button"
          phx-click="clear_location"
          phx-target={@myself}
          class="text-zinc-400 hover:text-zinc-600"
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>

      <div :if={!@selected_location}>
        <input
          type="text"
          value={@location_search_query}
          placeholder="Search for a location..."
          phx-keyup="search_location"
          phx-target={@myself}
          phx-debounce="200"
          autocomplete="off"
          class="w-full px-3 py-2 border border-zinc-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />

        <div
          :if={@show_location_results}
          class="absolute z-10 w-full mt-1 bg-white border border-zinc-200 rounded-lg shadow-lg max-h-48 overflow-y-auto"
        >
          <button
            :for={location <- @location_search_results}
            type="button"
            phx-click="select_location"
            phx-value-location-id={location.id}
            phx-target={@myself}
            class="w-full px-3 py-2 text-left text-sm hover:bg-zinc-100 focus:bg-zinc-100 focus:outline-none"
          >
            {location.name}
          </button>
        </div>

        <div
          :if={@location_search_query != "" and @location_search_results == []}
          class="absolute z-10 w-full mt-1 bg-white border border-zinc-200 rounded-lg shadow-lg p-3 text-sm text-zinc-500"
        >
          No locations found
        </div>
      </div>
    </div>
    """
  end

  attr :standing_form, :any, required: true
  attr :player_searches, :map, required: true
  attr :player_results, :map, required: true
  attr :selected_players, :map, required: true
  attr :myself, :any, required: true

  defp player_search(assigns) do
    index = assigns.standing_form.index
    player_id = assigns.standing_form[:player_id].value
    search_query = Map.get(assigns.player_searches, index, "")
    results = Map.get(assigns.player_results, index, [])
    selected_player = Map.get(assigns.selected_players, player_id)

    assigns =
      assigns
      |> assign(:index, index)
      |> assign(:player_id, player_id)
      |> assign(:search_query, search_query)
      |> assign(:results, results)
      |> assign(:selected_player, selected_player)
      |> assign(:show_results, search_query != "" and results != [])

    ~H"""
    <div class="relative">
      <label class="block text-sm font-medium text-zinc-700 mb-1">Player</label>
      <input type="hidden" name={@standing_form[:player_id].name} value={@player_id || ""} />

      <div :if={@selected_player} class="flex items-center gap-2">
        <span class="flex-1 px-3 py-2 bg-white border border-zinc-300 rounded-lg text-sm">
          {@selected_player.name}
        </span>
        <button
          type="button"
          phx-click="clear_player"
          phx-value-index={@index}
          phx-target={@myself}
          class="text-zinc-400 hover:text-zinc-600"
        >
          <.icon name="hero-x-mark" class="w-5 h-5" />
        </button>
      </div>

      <div :if={!@selected_player}>
        <input
          type="text"
          value={@search_query}
          placeholder="Search for a player..."
          phx-keyup="search_player"
          phx-value-index={@index}
          phx-target={@myself}
          phx-debounce="200"
          autocomplete="off"
          class="w-full px-3 py-2 border border-zinc-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        />

        <div
          :if={@show_results}
          class="absolute z-10 w-full mt-1 bg-white border border-zinc-200 rounded-lg shadow-lg max-h-48 overflow-y-auto"
        >
          <button
            :for={player <- @results}
            type="button"
            phx-click="select_player"
            phx-value-index={@index}
            phx-value-player-id={player.id}
            phx-target={@myself}
            class="w-full px-3 py-2 text-left text-sm hover:bg-zinc-100 focus:bg-zinc-100 focus:outline-none"
          >
            {player.name}
          </button>
        </div>

        <div
          :if={@search_query != "" and @results == []}
          class="absolute z-10 w-full mt-1 bg-white border border-zinc-200 rounded-lg shadow-lg p-3 text-sm text-zinc-500"
        >
          No players found
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{tournament: tournament} = assigns, socket) do
    selected_players =
      (tournament.standings || [])
      |> Enum.filter(& &1.player_id)
      |> Enum.map(fn standing ->
        player = standing.player || Players.get_player!(assigns.current_scope, standing.player_id)
        {standing.player_id, player}
      end)
      |> Map.new()

    selected_location =
      if tournament.location_id do
        tournament.location ||
          Locations.get_location!(assigns.current_scope, tournament.location_id)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:code_of_conduct_agreed, fn -> false end)
     |> assign(:player_searches, %{})
     |> assign(:player_results, %{})
     |> assign(:selected_players, selected_players)
     |> assign(:location_search_query, "")
     |> assign(:location_search_results, [])
     |> assign(:show_location_results, false)
     |> assign(:selected_location, selected_location)
     |> assign_form(Tournaments.change_tournament(assigns.current_scope, tournament))
     |> assign_options(assigns.current_scope)}
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_options(socket, current_scope) do
    seasons = Leagues.list_seasons(current_scope)

    season_options = Enum.map(seasons, &{&1.name, &1.id})

    qualifying_format_options = [
      {"None", :none},
      {"Single Elimination", :single_elimination},
      {"Double Elimination", :double_elimination},
      {"Match Play", :match_play},
      {"Best Game", :best_game},
      {"Card Qualifying", :card_qualifying},
      {"Pin Golf", :pin_golf},
      {"Flip Frenzy", :flip_frenzy},
      {"Strike Format", :strike_format},
      {"Target Match Play", :target_match_play},
      {"Hybrid", :hybrid}
    ]

    finals_format_options = [
      {"None", :none},
      {"Single Elimination", :single_elimination},
      {"Double Elimination", :double_elimination},
      {"Strike Knockout Standard", :strike_knockout_standard},
      {"Strike Knockout Fair", :strike_knockout_fair},
      {"Strike Knockout Progressive", :strike_knockout_progressive},
      {"Group Match Play", :group_match_play},
      {"Ladder", :ladder},
      {"Amazing Race", :amazing_race},
      {"Flip Frenzy", :flip_frenzy},
      {"Target Match Play", :target_match_play},
      {"Max Match Play", :max_match_play}
    ]

    socket
    |> assign(:season_options, season_options)
    |> assign(:qualifying_format_options, qualifying_format_options)
    |> assign(:finals_format_options, finals_format_options)
  end

  @impl true
  def handle_event("toggle_code_of_conduct", _params, socket) do
    {:noreply, assign(socket, :code_of_conduct_agreed, !socket.assigns.code_of_conduct_agreed)}
  end

  def handle_event("search_location", %{"value" => query}, socket) do
    results =
      if String.length(query) >= 1 do
        Locations.search_locations(socket.assigns.current_scope, query)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:location_search_query, query)
     |> assign(:location_search_results, results)
     |> assign(:show_location_results, query != "" and results != [])}
  end

  def handle_event("select_location", %{"location-id" => location_id}, socket) do
    location_id = String.to_integer(location_id)
    location = Locations.get_location!(socket.assigns.current_scope, location_id)

    changeset =
      socket.assigns.form.source
      |> Ecto.Changeset.put_change(:location_id, location_id)

    {:noreply,
     socket
     |> assign(:selected_location, location)
     |> assign(:location_search_query, "")
     |> assign(:location_search_results, [])
     |> assign(:show_location_results, false)
     |> assign_form(changeset)}
  end

  def handle_event("clear_location", _params, socket) do
    changeset =
      socket.assigns.form.source
      |> Ecto.Changeset.put_change(:location_id, nil)

    {:noreply,
     socket
     |> assign(:selected_location, nil)
     |> assign(:location_search_query, "")
     |> assign(:location_search_results, [])
     |> assign(:show_location_results, false)
     |> assign_form(changeset)}
  end

  def handle_event("validate", %{"tournament" => tournament_params}, socket) do
    changeset =
      Tournaments.change_tournament(
        socket.assigns.current_scope,
        socket.assigns.tournament,
        tournament_params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"tournament" => tournament_params} = params, socket) do
    status =
      case params["submit_action"] do
        "submit" -> "pending_review"
        _ -> "draft"
      end

    tournament_params =
      tournament_params
      |> Map.put("status", status)
      |> Map.put("organizer_id", socket.assigns.current_scope.user.id)

    save_tournament(socket, socket.assigns.action, tournament_params)
  end

  def handle_event("add_standing", _params, socket) do
    changeset = socket.assigns.form.source
    existing_standings = Ecto.Changeset.get_field(changeset, :standings) || []
    next_position = length(existing_standings) + 1

    new_standing = %OP.Tournaments.Standing{
      position: next_position,
      player_id: nil,
      is_finals: false
    }

    updated_standings = existing_standings ++ [new_standing]

    changeset =
      changeset
      |> Ecto.Changeset.put_assoc(:standings, updated_standings)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("search_player", %{"value" => query, "index" => index}, socket) do
    index = String.to_integer(index)

    player_searches = Map.put(socket.assigns.player_searches, index, query)

    player_results =
      if String.length(query) >= 1 do
        results = Players.search_players(socket.assigns.current_scope, query)
        Map.put(socket.assigns.player_results, index, results)
      else
        Map.put(socket.assigns.player_results, index, [])
      end

    {:noreply,
     socket
     |> assign(:player_searches, player_searches)
     |> assign(:player_results, player_results)}
  end

  def handle_event("select_player", %{"index" => index, "player-id" => player_id}, socket) do
    index = String.to_integer(index)
    player_id = String.to_integer(player_id)

    player = Players.get_player!(socket.assigns.current_scope, player_id)

    selected_players = Map.put(socket.assigns.selected_players, player_id, player)

    player_searches = Map.delete(socket.assigns.player_searches, index)
    player_results = Map.delete(socket.assigns.player_results, index)

    changeset = socket.assigns.form.source
    standings = Ecto.Changeset.get_field(changeset, :standings) || []

    updated_standings =
      standings
      |> Enum.with_index()
      |> Enum.map(fn {standing, i} ->
        if i == index do
          %{standing | player_id: player_id}
        else
          standing
        end
      end)

    changeset = Ecto.Changeset.put_assoc(changeset, :standings, updated_standings)

    {:noreply,
     socket
     |> assign(:selected_players, selected_players)
     |> assign(:player_searches, player_searches)
     |> assign(:player_results, player_results)
     |> assign_form(changeset)}
  end

  def handle_event("clear_player", %{"index" => index}, socket) do
    index = String.to_integer(index)

    changeset = socket.assigns.form.source
    standings = Ecto.Changeset.get_field(changeset, :standings) || []

    updated_standings =
      standings
      |> Enum.with_index()
      |> Enum.map(fn {standing, i} ->
        if i == index do
          %{standing | player_id: nil}
        else
          standing
        end
      end)

    changeset = Ecto.Changeset.put_assoc(changeset, :standings, updated_standings)

    {:noreply, assign_form(socket, changeset)}
  end

  defp save_tournament(socket, :edit, tournament_params) do
    case Tournaments.update_tournament(
           socket.assigns.current_scope,
           socket.assigns.tournament,
           tournament_params
         ) do
      {:ok, tournament} ->
        notify_parent({:saved, tournament})

        {:noreply,
         socket
         |> put_flash(:info, "Tournament updated successfully")
         |> push_navigate(to: ~p"/tournaments")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_tournament(socket, :new, tournament_params) do
    case Tournaments.create_tournament(socket.assigns.current_scope, tournament_params) do
      {:ok, tournament} ->
        notify_parent({:saved, tournament})

        {:noreply,
         socket
         |> put_flash(:info, "Tournament submitted successfully")
         |> push_navigate(to: ~p"/tournaments")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
