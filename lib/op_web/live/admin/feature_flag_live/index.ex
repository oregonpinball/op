defmodule OPWeb.Admin.FeatureFlagLive.Index do
  use OPWeb, :live_view

  alias OP.FeatureFlags

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, flags: FeatureFlags.flags())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="container mx-auto p-4">
        <.header>
          Feature Flags
          <:subtitle>
            View the current status of feature flags configured via environment variables.
          </:subtitle>
        </.header>

        <div class="mt-8 space-y-4">
          <div
            :for={flag <- @flags}
            id={"flag-#{flag.key}"}
            class="rounded-lg border border-gray-200 p-5 transition-all hover:border-gray-300 hover:shadow-sm"
          >
            <div class="flex items-center justify-between">
              <div>
                <h3 class="font-semibold text-gray-900">{flag.label}</h3>
                <p class="mt-1 text-sm text-gray-500">{flag.description}</p>
              </div>
              <.flag_badge enabled={flag.enabled} />
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :enabled, :boolean, required: true

  defp flag_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-medium whitespace-nowrap",
      if(@enabled, do: "bg-green-50 text-green-700", else: "bg-gray-100 text-gray-500")
    ]}>
      <span class={[
        "size-1.5 rounded-full",
        if(@enabled, do: "bg-green-500", else: "bg-gray-400")
      ]} />
      {if @enabled, do: "Enabled", else: "Disabled"}
    </span>
    """
  end
end
