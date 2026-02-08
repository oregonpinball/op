defmodule OPWeb.Fir do
  use OPWeb, :html
  use Phoenix.Component

  alias OP.Fir.{Section, Page}

  attr :page, Page, required: true

  attr :class, :string, default: nil, doc: "Additional CSS classes"
  attr :rest, :global, doc: "Additional HTML attributes"

  def page(assigns) do
    ~H"""
    <%= if Ecto.assoc_loaded?(@page.section) && !is_nil(@page.section) do %>
      <p>
        Part of
        <.button variant="underline" navigate={~p"/f/#{OP.Fir.build_slug_path(@page.section)}"}>
          {@page.section.name}
        </.button>
      </p>
    <% end %>
    <article class="prose lg:prose-xl dark:prose-invert mx-auto">
      <h1>{@page.name}</h1>

      <%= if @page.html do %>
        <div class="mt-6">
          {raw(@page.html)}
        </div>
      <% end %>
    </article>
    """
  end

  attr :section, Section, required: true
  attr :rest, :global, doc: "Additional HTML attributes"

  def section(assigns) do
    # Build the base path for the current section
    assigns = assign(assigns, :section_path, OP.Fir.build_slug_path(assigns.section))

    ~H"""
    <div class="grid grid-cols-3">
      <div :for={section <- @section.child_sections} class="p-4 border rounded m-2">
        <div class="flex items-center">
          <.icon name="hero-folder-open" class="size-6" />
          <h1 class="text-lg font-semibold">{section.name}</h1>
          <.button color="secondary" navigate={~p"/f/#{@section_path ++ [section.slug]}"}>
            <span>View</span>
          </.button>
        </div>
        <p class="mt-2">{raw(section.html_description)}</p>
      </div>
      <div :for={page <- @section.pages} class="p-4 border rounded m-2 wrap-break-word hyphens-auto">
        <div class="flex items-center">
          <.icon name="hero-document" class="size-6" />
          <h1 class="text-lg font-semibold grow">{page.name}</h1>
          <.button color="secondary" navigate={~p"/f/#{@section_path ++ [page.slug]}"}>
            <span>View</span>
          </.button>
        </div>
        <div class="mt-2 max-h-40 overflow-y-auto">
          {raw(page.html_description)}
        </div>
      </div>
    </div>
    """
  end

  attr :slug, :string, required: true
  attr :html, :string, required: true
  attr :class, :string, default: nil
  slot :inner_block

  def description_editor(assigns) do
    ~H"""
    <div class={["border border-slate-200 bg-slate-50 rounded-lg p-4 mt-4", @class]}>
      <div class="flex items-center gap-2 mb-1">
        <.icon name="hero-chat-bubble-left-ellipsis" class="size-5 text-slate-500" />
        <h3 class="text-lg font-semibold text-slate-800">Description</h3>
        <.badge color="info" size="sm">Autosave</.badge>
      </div>
      <p class="text-sm text-slate-500 mb-3">
        Keep this to one or two sentences. This appears when viewing the parent section.
      </p>
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        <.editor key="html_description" slug={@slug} html={@html} />
      <% end %>
    </div>
    """
  end

  attr :slug, :string, required: true
  attr :html, :string, required: true
  attr :class, :string, default: nil
  slot :inner_block

  def content_editor(assigns) do
    ~H"""
    <div class={["border border-slate-200 bg-slate-50 rounded-lg p-4 mt-4", @class]}>
      <div class="flex items-center gap-2 mb-1">
        <.icon name="hero-document-text" class="size-5 text-slate-500" />
        <h3 class="text-lg font-semibold text-slate-800">Content</h3>
        <.badge color="info" size="sm">Autosave</.badge>
      </div>
      <p class="text-sm text-slate-500 mb-3">
        The full page content displayed to visitors.
      </p>
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        <.editor key="html" slug={@slug} html={@html} />
      <% end %>
    </div>
    """
  end

  attr :slug, :string, required: true
  attr :html, :string, required: true
  attr :key, :string, required: true

  def editor(assigns) do
    ~H"""
    <div
      id={"fir-editor-wrapper-#{@slug}-#{@key}"}
      phx-update="ignore"
      class="prose max-w-none"
    >
      <textarea
        id={"fir-editor-#{@slug}-#{@key}"}
        value={@html}
        data-html={@html}
        data-key={@key}
        class="w-full h-64 border mt-2 p-2"
        phx-hook="PageEditor"
      ></textarea>
    </div>
    """
  end
end
