defmodule OPWeb.LeagueHTML do
  @moduledoc """
  This module contains pages rendered by LeagueController.

  See the `league_html` directory for all templates available.
  """
  use OPWeb, :html

  embed_templates "league_html/*"
end
