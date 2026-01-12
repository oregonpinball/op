defmodule OPWeb.SeasonHTML do
  @moduledoc """
  This module contains pages rendered by SeasonController.

  See the `season_html` directory for all templates available.
  """
  use OPWeb, :html

  embed_templates "season_html/*"
end
