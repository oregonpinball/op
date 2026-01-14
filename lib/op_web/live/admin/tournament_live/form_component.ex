defmodule OPWeb.Admin.TournamentLive.FormComponent do
  use OPWeb, :live_component

  alias OP.Tournaments
  alias OP.Leagues
  alias OP.Locations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage tournament records.</:subtitle>
      </.header>

      <.form
        for={@form}
        id="tournament-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="mt-6 space-y-6"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:description]} type="textarea" label="Description" />

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:start_at]}
            type="datetime-local"
            label="Start Date"
            required
          />
          <.input
            field={@form[:end_at]}
            type="datetime-local"
            label="End Date"
          />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:season_id]}
            type="select"
            label="Season"
            options={@season_options}
            prompt="Select a season"
          />
          <.input
            field={@form[:location_id]}
            type="select"
            label="Location"
            options={@location_options}
            prompt="Select a location"
          />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:event_booster]}
            type="select"
            label="Event Booster"
            options={@event_booster_options}
          />
          <.input
            field={@form[:qualifying_format]}
            type="select"
            label="Qualifying Format"
            options={@qualifying_format_options}
          />
        </div>

        <.input field={@form[:allows_opt_out]} type="checkbox" label="Allows Opt-Out" />

        <div class="flex justify-end gap-4">
          <.button type="button" variant="invisible" phx-click={JS.patch(@patch)}>
            Cancel
          </.button>
          <.button variant="solid" phx-disable-with="Saving...">
            Save Tournament
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{tournament: tournament} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(Tournaments.change_tournament(assigns.current_scope, tournament))
     |> assign_options(assigns.current_scope)}
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_options(socket, current_scope) do
    seasons = Leagues.list_seasons(current_scope)
    locations = Locations.list_locations(current_scope)

    season_options = Enum.map(seasons, &{&1.name, &1.id})
    location_options = Enum.map(locations, &{&1.name, &1.id})

    event_booster_options = [
      {"None", :none},
      {"Certified", :certified},
      {"Certified Plus", :certified_plus},
      {"Championship Series", :championship_series},
      {"Major", :major}
    ]

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

    socket
    |> assign(:season_options, season_options)
    |> assign(:location_options, location_options)
    |> assign(:event_booster_options, event_booster_options)
    |> assign(:qualifying_format_options, qualifying_format_options)
  end

  @impl true
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

  def handle_event("save", %{"tournament" => tournament_params}, socket) do
    save_tournament(socket, socket.assigns.action, tournament_params)
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
         |> push_patch(to: socket.assigns.patch)}

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
         |> put_flash(:info, "Tournament created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
