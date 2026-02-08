defmodule Mix.Tasks.Locations.ImportPinballmap do
  @moduledoc """
  Imports pinball venue locations from Pinball Map (pinballmap.com).

  By default, imports all Oregon regions (portland, eugene, southern-oregon).
  You can specify specific regions as arguments.

  ## Usage

      mix locations.import_pinballmap
      mix locations.import_pinballmap portland eugene

  ## Attribution

  Location data is provided by Pinball Map and licensed under CC BY-SA 4.0.
  https://pinballmap.com
  """

  use Mix.Task

  @shortdoc "Imports locations from Pinball Map API"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts =
      if args == [] do
        []
      else
        [regions: args]
      end

    Mix.shell().info("Importing locations from Pinball Map...")

    case OP.PinballMap.Import.import_regions(opts) do
      {:ok, summary} ->
        Mix.shell().info("""

        Import complete!
          Regions processed: #{summary.regions_processed}
          Locations created: #{summary.created}
          Locations updated: #{summary.updated}
          Errors: #{summary.errors}

        Location data provided by Pinball Map (https://pinballmap.com)
        Licensed under CC BY-SA 4.0
        """)
    end
  end
end
