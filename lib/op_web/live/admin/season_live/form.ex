defmodule OPWeb.Admin.SeasonLive.Form do
  use OPWeb, :live_view

  alias OP.Leagues

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage season records.</:subtitle>
      </.header>

      <div class="mt-8 max-w-2xl">
        <.form
          for={@form}
          id="season-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <.input field={@form[:name]} type="text" label="Name" required />
          <.input field={@form[:description]} type="textarea" label="Description" />
          <.input field={@form[:slug]} type="text" label="Slug" placeholder="Auto-generated if left blank" />

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

          <.input
            field={@form[:league_id]}
            type="select"
            label="League"
            options={@league_options}
            prompt="Select a league"
            required
          />

          <div class="flex items-center justify-end gap-3 pt-6">
            <.link navigate={~p"/admin/seasons"}>
              <.button type="button" variant="invisible">
                Cancel
              </.button>
            </.link>
            <.button type="submit" variant="solid" phx-disable-with="Saving...">
              Save Season
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    leagues = Leagues.list_leagues(socket.assigns.current_scope)
    league_options = Enum.map(leagues, &{&1.name, &1.id})

    {:ok,
     socket
     |> assign(:league_options, league_options)
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    season = Leagues.get_season_with_preloads!(socket.assigns.current_scope, id)
    changeset = Leagues.change_season(season)

    socket
    |> assign(:page_title, "Edit Season")
    |> assign(:season, season)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :new, params) do
    season = %Leagues.Season{}
    season = if params["league_id"], do: %{season | league_id: String.to_integer(params["league_id"])}, else: season
    changeset = Leagues.change_season(season)

    socket
    |> assign(:page_title, "New Season")
    |> assign(:season, season)
    |> assign(:form, to_form(changeset))
  end

  @impl true
  def handle_event("validate", %{"season" => season_params}, socket) do
    changeset =
      socket.assigns.season
      |> Leagues.change_season(season_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"season" => season_params}, socket) do
    save_season(socket, socket.assigns.live_action, season_params)
  end

  defp save_season(socket, :edit, season_params) do
    case Leagues.update_season(
           socket.assigns.current_scope,
           socket.assigns.season,
           season_params
         ) do
      {:ok, _season} ->
        {:noreply,
         socket
         |> put_flash(:info, "Season updated successfully")
         |> push_navigate(to: ~p"/admin/seasons")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_season(socket, :new, season_params) do
    case Leagues.create_season(socket.assigns.current_scope, season_params) do
      {:ok, _season} ->
        {:noreply,
         socket
         |> put_flash(:info, "Season created successfully")
         |> push_navigate(to: ~p"/admin/seasons")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
