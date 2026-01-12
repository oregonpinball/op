defmodule Storybook.CoreComponents.Sheet do
  use PhoenixStorybook.Story, :component

  def function, do: &OPWeb.CoreComponents.sheet/1
  def imports, do: [{OPWeb.CoreComponents, toggle: 1, button: 1}]
  def render_source, do: :function

  def template do
    """
    <.button phx-click={toggle("#:variation_id")}>
      Open Sheet
    </.button>
    <.psb-variation/>
    """
  end

  def variations do
    [
      %Variation{
        id: :default_sheet,
        note: """
        A slide-over sheet that enters from the right side of the screen.
        Useful for mobile navigation menus or detail panes.
        """,
        attributes: %{
          id: "default-sheet"
        },
        slots: [
          """
          <.sheet id="default-sheet">
            <div class="space-y-4">
              <h2 class="text-xl font-bold">Sheet Title</h2>
              <p>This is the default sheet content.</p>
            </div>
          </.sheet>
          <div class="space-y-4">
            <h2 class="text-xl font-bold">Sheet Title</h2>
            <p>This is the default sheet content.</p>
          </div>
          """
        ]
      },
      %Variation{
        id: :navigation_menu,
        description: "Sheet with navigation menu",
        attributes: %{
          id: "nav-sheet"
        },
        slots: [
          """
          <nav class="space-y-2">
            <h2 class="text-lg font-bold mb-4">Navigation</h2>
            <a href="#" class="block px-4 py-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-700">Home</a>
            <a href="#" class="block px-4 py-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-700">About</a>
            <a href="#" class="block px-4 py-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-700">Services</a>
            <a href="#" class="block px-4 py-2 rounded-lg hover:bg-slate-200 dark:hover:bg-slate-700">Contact</a>
          </nav>
          """
        ]
      },
      %Variation{
        id: :long_content,
        description: "Sheet with scrollable long content",
        attributes: %{
          id: "long-sheet"
        },
        slots: [
          """
          <div class="space-y-4">
            <h2 class="text-xl font-bold">Long Content</h2>
            <p>This sheet contains long scrollable content to demonstrate overflow behavior.</p>
            #{Enum.map_join(1..35, "\n", fn i -> "<p>Paragraph #{i}: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>" end)}
          </div>
          """
        ]
      }
    ]
  end
end
