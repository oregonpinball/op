defmodule OPWeb.Admin.LeagueLive.Form do
  use OPWeb, :live_view

  alias OP.Leagues

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage league records.</:subtitle>
      </.header>

      <div class="mt-8 max-w-2xl">
        <.form
          for={@form}
          id="league-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-6"
        >
          <.input field={@form[:name]} type="text" label="Name" required />
          <.input field={@form[:description]} type="textarea" label="Description" />
          <.input
            field={@form[:slug]}
            type="text"
            label="Slug"
            placeholder="Auto-generated if left blank"
          />

          <input type="hidden" name={@form[:author_id].name} value={@current_scope.user.id} />

          <div class="flex items-center justify-end gap-3 pt-6">
            <.link navigate={~p"/admin/leagues"}>
              <.button type="button" variant="invisible">
                Cancel
              </.button>
            </.link>
            <.button type="submit" variant="solid" phx-disable-with="Saving...">
              Save League
            </.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    league = Leagues.get_league_with_preloads!(socket.assigns.current_scope, id)
    changeset = Leagues.change_league(league)

    socket
    |> assign(:page_title, "Edit League")
    |> assign(:league, league)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :new, _params) do
    league = %Leagues.League{}
    changeset = Leagues.change_league(league)

    socket
    |> assign(:page_title, "New League")
    |> assign(:league, league)
    |> assign(:form, to_form(changeset))
  end

  @impl true
  def handle_event("validate", %{"league" => league_params}, socket) do
    changeset =
      socket.assigns.league
      |> Leagues.change_league(league_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"league" => league_params}, socket) do
    save_league(socket, socket.assigns.live_action, league_params)
  end

  defp save_league(socket, :edit, league_params) do
    case Leagues.update_league(
           socket.assigns.current_scope,
           socket.assigns.league,
           league_params
         ) do
      {:ok, _league} ->
        {:noreply,
         socket
         |> put_flash(:info, "League updated successfully")
         |> push_navigate(to: ~p"/admin/leagues")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_league(socket, :new, league_params) do
    case Leagues.create_league(socket.assigns.current_scope, league_params) do
      {:ok, _league} ->
        {:noreply,
         socket
         |> put_flash(:info, "League created successfully")
         |> push_navigate(to: ~p"/admin/leagues")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
