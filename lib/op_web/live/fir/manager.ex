defmodule OPWeb.FirLive.Manager do
  use OPWeb, :live_view

  alias OP.Repo
  alias OP.Fir
  alias OP.Fir.{Section, Page}

  import OPWeb.Fir, only: [editor: 1]

  attr :nodes, :list, required: true
  attr :level, :integer, default: 0
  attr :path, :string, default: ""

  defp tree_view(assigns) do
    ~H"""
    <div>
      <div :for={node <- @nodes} class="border-l-2 border-slate-700 ml-4 truncate">
        <%= if node.type == :section do %>
          <div class="flex items-center">
            <.button
              class="grow truncate"
              color="invisible"
              phx-click={JS.push("select:content", value: %{slug: node.item.slug, type: "section"})}
              title={"Slug: #{node.item.slug}"}
            >
              <div class="flex flex-col truncate">
                <span class="truncate">
                  <.icon name="hero-folder" class="size-3 min-w-3" />
                  <span>{node.item.name}</span>
                </span>
                <span class="text-xs text-slate-700 text-left">{@path}/{node.item.slug}</span>
              </div>
            </.button>
            <div class="shrink-0 flex items-center space-x-0.5">
              <.button size="xs">
                Prev.
              </.button>
            </div>
          </div>
          <%= if node.children != [] do %>
            <.tree_view
              nodes={node.children}
              level={@level + 1}
              path={@path <> "/" <> node.item.slug}
            />
          <% end %>
        <% else %>
          <div class="flex items-center">
            <.button
              class="grow truncate"
              color="invisible"
              phx-click={JS.push("select:content", value: %{slug: node.item.slug, type: "page"})}
            >
              <div class="flex flex-col truncate">
                <span class="truncate text-left">
                  <.icon name="hero-document" class="size-3 min-w-3" />
                  <span>{node.item.name}</span>
                </span>
                <span class="text-xs text-slate-700 text-left">{@path}/{node.item.slug}</span>
              </div>
            </.button>
            <div class="shrink-0 flex items-center space-x-0.5">
              <.button size="xs">
                Prev.
              </.button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex h-full">
        <%!-- Left Sidebar --%>
        <div class="w-75 shrink-0 border-r border-gray-200 overflow-y-auto">
          <div class="p-4">
            <h1 class="text-xl font-semibold">Outline</h1>
            <%= if Enum.empty?(@sections) && Enum.empty?(@pages) do %>
              <p class="text-gray-500">No sections or pages available.</p>
            <% else %>
              <div>
                <.tree_view nodes={@tree} level={0} />
              </div>
            <% end %>
          </div>
        </div>

        <%!-- Middle Content --%>
        <div class="flex-1 overflow-auto">
          <div class="p-4">
            <div class="flex items-center space-x-4">
              <div class="grow truncate">
                <h1 class="text-lg font-semibold grow">Fir CMS</h1>
                <p class="truncate">Manage the site's content sections and pages.</p>
              </div>
              <div class="">
                <.button phx-click="create:section">Add section </.button>
                <.button phx-click="create:page">Add page </.button>
                <%= if !is_nil(@selected_content) && @selected_content.type == :section do %>
                  <div class="flex items-center p-2 border rounded mt-2">
                    <p>Adding to section: {@selected_content.content.name}</p>
                    <.button color="secondary" size="sm" phx-click="clear:content">Clear</.button>
                  </div>
                <% end %>
              </div>
            </div>

            <div class="mt-4">
              <%= if !is_nil(@selected_content) do %>
                <%= if @selected_content.type == :page do %>
                  <div class="p-4 border rounded">
                    <div class="flex items-center space-x-2">
                      <h2 class="text-2xl font-semibold grow">Edit Page</h2>
                      <.button
                        color="error"
                        phx-click="delete:page"
                        data-confirm="Are you sure you want to delete this page?"
                        class="mr-12"
                      >
                        Delete
                      </.button>
                      <.button color="secondary">Preview</.button>

                      <.button
                        color="primary"
                        type="submit"
                        form="page-form"
                        phx-disable-with="Saving..."
                      >
                        Save changes
                      </.button>
                    </div>

                    <.form
                      for={@page_form}
                      id="page-form"
                      phx-change="validate:page"
                      phx-submit="update:page"
                      class="mt-2"
                    >
                      <div class="grid grid-cols-2 gap-4">
                        <.input field={@page_form[:name]} type="text" label="Name" />
                        <.input field={@page_form[:slug]} type="text" label="Slug" />
                      </div>
                      <div class="grid grid-cols-4 gap-4">
                        <div />
                        <div />
                        <.input
                          field={@page_form[:section_id]}
                          type="select"
                          label="Parent Section"
                          options={[{"None", nil}] ++ Enum.map(@sections, &{&1.name, &1.id})}
                          prompt="Select a section"
                        />
                        <.input
                          field={@page_form[:state]}
                          type="select"
                          label="State"
                          options={[
                            {"Drafting", "drafting"},
                            {"Published", "published"},
                            {"Archived", "archived"}
                          ]}
                          prompt="Select a state"
                        />
                      </div>
                      <div class="flex justify-end"></div>
                    </.form>

                    <div class="mt-6">
                      <.alert color="info">
                        <p>This section autosaves</p>
                      </.alert>
                      <label class="text-2xl font-semibold">Description</label>
                      <p>
                        Restrict this to a sentence or two, this is what shows up when they view the parent section.
                      </p>
                      <.editor
                        key="html_description"
                        slug={@selected_content.content.slug}
                        html={@selected_content.content.html_description}
                      />

                      <label class="text-2xl font-semibold">Content</label>

                      <.editor
                        key="html"
                        slug={@selected_content.content.slug}
                        html={@selected_content.content.html}
                      />
                    </div>
                  </div>
                <% end %>
                <%= if @selected_content.type == :section do %>
                  <div class="p-4 border rounded">
                    <div class="flex items-center space-x-2">
                      <h2 class="text-2xl font-semibold grow">Edit Section</h2>
                      <.button
                        color="error"
                        phx-click="delete:section"
                        data-confirm="Are you sure you want to delete this section? This will also delete all child sections and pages."
                        class="mr-12"
                      >
                        Delete
                      </.button>
                      <.button color="secondary">Preview</.button>

                      <.button
                        color="primary"
                        type="submit"
                        form="section-form"
                        phx-disable-with="Saving..."
                      >
                        Save changes
                      </.button>
                    </div>

                    <.form
                      for={@section_form}
                      id="section-form"
                      phx-change="validate:section"
                      phx-submit="update:section"
                      class="mt-2"
                    >
                      <div class="grid grid-cols-2 gap-4">
                        <.input field={@section_form[:name]} type="text" label="Name" />
                        <.input field={@section_form[:slug]} type="text" label="Slug" />
                      </div>
                      <div class="grid grid-cols-4 gap-4">
                        <div />
                        <div />
                        <.input
                          field={@section_form[:parent_section_id]}
                          type="select"
                          label="Parent Section"
                          options={
                            [{"None", nil}] ++
                              Enum.map(
                                Enum.reject(@sections, &(&1.id == @selected_content.content.id)),
                                &{&1.name, &1.id}
                              )
                          }
                          prompt="Select a section"
                        />
                        <.input
                          field={@section_form[:state]}
                          type="select"
                          label="State"
                          options={[
                            {"Drafting", "drafting"},
                            {"Published", "published"},
                            {"Archived", "archived"}
                          ]}
                          prompt="Select a state"
                        />
                      </div>
                      <div class="mt-4">
                        <label class="font-semibold text-2xl">Description</label>
                        <.editor
                          key="html_description"
                          slug={@selected_content.content.slug}
                          html={@selected_content.content.html_description}
                        />
                      </div>
                      <div class="flex justify-end"></div>
                    </.form>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    sections = Repo.all(Section)
    pages = Repo.all(Page)
    tree = Fir.build_tree(pages, sections)

    {:ok,
     assign(socket,
       sections: sections,
       pages: pages,
       tree: tree,
       selected_content: nil,
       page_form: nil,
       section_form: nil
     )}
  end

  def handle_event("create:section", _params, socket) do
    now = DateTime.utc_now()
    name = "Section #{Calendar.strftime(now, "%Y-%m-%d %H:%M:%S")}"

    parent_section_id =
      case socket.assigns.selected_content do
        %{type: :section, content: section} -> section.id
        _ -> nil
      end

    case Fir.create_section(%{name: name, parent_section_id: parent_section_id}) do
      {:ok, _section} ->
        sections = Repo.all(Section)
        pages = socket.assigns.pages
        tree = Fir.build_tree(pages, sections)

        {:noreply,
         socket
         |> assign(sections: sections, tree: tree)
         |> put_flash(:info, "Section created successfully")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create section")}
    end
  end

  def handle_event("create:page", _params, socket) do
    now = DateTime.utc_now()
    name = "Page #{Calendar.strftime(now, "%Y-%m-%d %H:%M:%S")}"

    section_id =
      case socket.assigns.selected_content do
        %{type: :section, content: section} -> section.id
        _ -> nil
      end

    case Fir.create_page(%{name: name, content: "", section_id: section_id}) do
      {:ok, _page} ->
        sections = socket.assigns.sections
        pages = Repo.all(Page)
        tree = Fir.build_tree(pages, sections)

        {:noreply,
         socket
         |> assign(pages: pages, tree: tree)
         |> put_flash(:info, "Page created successfully")}

      {:error, _e} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create page")}
    end
  end

  def handle_event("select:content", %{"slug" => slug, "type" => "section"}, socket) do
    sections = socket.assigns.sections
    section = Enum.find(sections, fn sec -> sec.slug == slug end)

    changeset = Section.changeset(section, %{})
    form = to_form(changeset)

    {:noreply,
     assign(socket, selected_content: %{type: :section, content: section}, section_form: form)}
  end

  def handle_event("select:content", %{"slug" => slug, "type" => "page"}, socket) do
    pages = socket.assigns.pages
    page = Enum.find(pages, fn page -> page.slug == slug end)

    changeset = Page.changeset(page, %{})
    form = to_form(changeset)

    {:noreply, assign(socket, selected_content: %{type: :page, content: page}, page_form: form)}
  end

  def handle_event("clear:content", _params, socket) do
    {:noreply, assign(socket, selected_content: nil, page_form: nil, section_form: nil)}
  end

  def handle_event("validate:page", %{"page" => page_params}, socket) do
    case socket.assigns.selected_content do
      %{type: :page, content: page} ->
        changeset =
          page
          |> Page.changeset(page_params)
          |> Map.put(:action, :validate)

        {:noreply, assign(socket, page_form: to_form(changeset))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("validate:section", %{"section" => section_params}, socket) do
    case socket.assigns.selected_content do
      %{type: :section, content: section} ->
        changeset =
          section
          |> Section.changeset(section_params)
          |> Map.put(:action, :validate)

        {:noreply, assign(socket, section_form: to_form(changeset))}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("update:page", %{"page" => page_params}, socket) do
    case socket.assigns.selected_content do
      %{type: :page, content: page} ->
        changeset = Page.changeset(page, page_params)

        case Repo.update(changeset) do
          {:ok, updated_page} ->
            pages =
              Enum.map(socket.assigns.pages, fn p ->
                if p.id == updated_page.id, do: updated_page, else: p
              end)

            sections = socket.assigns.sections
            tree = Fir.build_tree(pages, sections)
            form = to_form(Page.changeset(updated_page, %{}))

            {:noreply,
             socket
             |> assign(
               pages: pages,
               tree: tree,
               selected_content: %{type: :page, content: updated_page},
               page_form: form
             )
             |> put_flash(:info, "Page updated successfully")}

          {:error, changeset} ->
            {:noreply,
             socket
             |> assign(page_form: to_form(changeset))
             |> put_flash(:error, "Failed to update page")}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("update:section", %{"section" => section_params}, socket) do
    case socket.assigns.selected_content do
      %{type: :section, content: section} ->
        changeset = Section.changeset(section, section_params)

        case Repo.update(changeset) do
          {:ok, updated_section} ->
            sections =
              Enum.map(socket.assigns.sections, fn s ->
                if s.id == updated_section.id, do: updated_section, else: s
              end)

            pages = socket.assigns.pages
            tree = Fir.build_tree(pages, sections)
            form = to_form(Section.changeset(updated_section, %{}))

            {:noreply,
             socket
             |> assign(
               sections: sections,
               tree: tree,
               selected_content: %{type: :section, content: updated_section},
               section_form: form
             )
             |> put_flash(:info, "Section updated successfully")}

          {:error, changeset} ->
            {:noreply,
             socket
             |> assign(section_form: to_form(changeset))
             |> put_flash(:error, "Failed to update section")}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("fir:update", %{"html" => html, "key" => key}, socket)
      when key in ["html", "html_description"] do
    case socket.assigns.selected_content do
      %{type: :page, content: page} ->
        key = String.to_existing_atom(key)
        attrs = Map.put(%{}, key, html)
        changeset = Page.changeset(page, attrs)

        case Repo.update(changeset) do
          {:ok, updated_page} ->
            pages =
              Enum.map(socket.assigns.pages, fn p ->
                if p.id == updated_page.id, do: updated_page, else: p
              end)

            {:noreply,
             assign(socket, pages: pages, selected_content: %{type: :page, content: updated_page})}

          {:error, _changeset} ->
            {:noreply, socket}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("delete:page", _params, socket) do
    case socket.assigns.selected_content do
      %{type: :page, content: page} ->
        case Fir.delete_page(page) do
          {:ok, _deleted_page} ->
            pages = Enum.reject(socket.assigns.pages, fn p -> p.id == page.id end)
            sections = socket.assigns.sections
            tree = Fir.build_tree(pages, sections)

            {:noreply,
             socket
             |> assign(pages: pages, tree: tree, selected_content: nil, page_form: nil)
             |> put_flash(:info, "Page deleted successfully")}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to delete page")}
        end

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("delete:section", _params, socket) do
    case socket.assigns.selected_content do
      %{type: :section, content: section} ->
        case Fir.delete_section(section) do
          {:ok, _deleted_section} ->
            sections = Enum.reject(socket.assigns.sections, fn s -> s.id == section.id end)
            pages = socket.assigns.pages
            tree = Fir.build_tree(pages, sections)

            {:noreply,
             socket
             |> assign(sections: sections, tree: tree, selected_content: nil, section_form: nil)
             |> put_flash(:info, "Section deleted successfully")}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to delete section")}
        end

      _ ->
        {:noreply, socket}
    end
  end
end
