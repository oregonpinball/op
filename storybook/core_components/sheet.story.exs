defmodule Storybook.CoreComponents.Sheet do
  use PhoenixStorybook.Story, :component

  def function, do: &OPWeb.CoreComponents.sheet/1
  def imports, do: [{OPWeb.CoreComponents, toggle: 1, button: 1}]
  def render_source, do: :function

  def template do
    """
    <button phx-click={toggle("#:variation_id")} class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
      Open Sheet
    </button>
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
        id: :detail_pane,
        description: "Sheet with detailed content",
        attributes: %{
          id: "detail-sheet"
        },
        slots: [
          """
          <div class="space-y-4">
            <h2 class="text-2xl font-bold">Item Details</h2>
            <div class="space-y-2">
              <div>
                <span class="font-semibold">Name:</span>
                <span class="ml-2">Product Name</span>
              </div>
              <div>
                <span class="font-semibold">Description:</span>
                <p class="mt-1">This is a detailed description of the item with more information about its features and benefits.</p>
              </div>
              <div>
                <span class="font-semibold">Price:</span>
                <span class="ml-2">$99.99</span>
              </div>
            </div>
            <button class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
              Add to Cart
            </button>
          </div>
          """
        ]
      },
      %Variation{
        id: :form_sheet,
        description: "Sheet with a form",
        attributes: %{
          id: "form-sheet"
        },
        slots: [
          """
          <div class="space-y-4">
            <h2 class="text-xl font-bold">Contact Form</h2>
            <form class="space-y-4">
              <div>
                <label class="block text-sm font-medium mb-1">Name</label>
                <input type="text" class="w-full px-3 py-2 border rounded-lg" />
              </div>
              <div>
                <label class="block text-sm font-medium mb-1">Email</label>
                <input type="email" class="w-full px-3 py-2 border rounded-lg" />
              </div>
              <div>
                <label class="block text-sm font-medium mb-1">Message</label>
                <textarea class="w-full px-3 py-2 border rounded-lg" rows="4"></textarea>
              </div>
              <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                Submit
              </button>
            </form>
          </div>
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
            #{Enum.map_join(1..20, "\n", fn i -> "<p>Paragraph #{i}: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>" end)}
          </div>
          """
        ]
      }
    ]
  end
end
