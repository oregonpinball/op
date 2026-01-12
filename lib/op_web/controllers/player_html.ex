defmodule OPWeb.PlayerHTML do
  @moduledoc """
  This module contains pages rendered by PlayerController.

  See the `player_html` directory for all templates available.
  """
  use OPWeb, :html

  embed_templates "player_html/*"
end
