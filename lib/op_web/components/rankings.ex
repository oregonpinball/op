defmodule OPWeb.Rankings do
  use OPWeb, :html
  use Phoenix.Component
  use Gettext, backend: OPWeb.Gettext

  attr :ranking, :integer, default: nil

  def trophy(assigns) do
    ~H"""
    <%= cond do %>
      <% @ranking == 1 -> %>
        <.icon name="hero-trophy" class="size-4 text-yellow-500" />
      <% @ranking == 2 -> %>
        <.icon name="hero-trophy" class="size-4 text-gray-400" />
      <% @ranking == 3 -> %>
        <.icon name="hero-trophy" class="size-4 text-amber-700" />
      <% true -> %>
        {@ranking}
    <% end %>
    """
  end

end
