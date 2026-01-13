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
        1.

      <% @ranking == 2 -> %>
        <.icon name="hero-trophy" class="size-4 text-gray-400" />
        2.

      <% @ranking == 3 -> %>
        <.icon name="hero-trophy" class="size-4 text-amber-700" />
        3.

      <% true -> %>
        <span class="inline-block size-4" />

        {@ranking}.
    <% end %>
    """
  end

end
