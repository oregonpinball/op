defmodule OPWeb.Storybook.Fir.DescriptionEditor do
  use PhoenixStorybook.Story, :component

  def function, do: &OPWeb.Fir.description_editor/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Description editor with empty content",
        attributes: %{
          slug: "example-page",
          html: ""
        },
        slots: [
          ~s|<div class="border-2 border-dashed border-slate-300 rounded p-4 text-center text-slate-400">Tiptap editor placeholder</div>|
        ]
      },
      %Variation{
        id: :with_content,
        description: "Description editor with existing content",
        attributes: %{
          slug: "example-page",
          html: "<p>An example description.</p>"
        },
        slots: [
          ~s|<div class="border-2 border-dashed border-slate-300 rounded p-4 text-center text-slate-400">Tiptap editor with content</div>|
        ]
      }
    ]
  end
end
