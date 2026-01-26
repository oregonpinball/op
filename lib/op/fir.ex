defmodule OP.Fir do
  @moduledoc """
  The Fir context provides helper functions for working with content sections and pages.
  """

  import Ecto.Query, warn: false
  alias OP.Repo
  alias OP.Fir.{Section, Page}

  @doc """
  Gets all sections matching the provided slugs list.

  Returns a list of sections in the order they were found.

  ## Examples

      iex> get_sections_by_slugs(["announcements", "guides"])
      [%Section{slug: "announcements"}, %Section{slug: "guides"}]

      iex> get_sections_by_slugs([])
      []
  """
  def get_sections_by_slugs(slugs) when is_list(slugs) do
    Section
    |> where([s], s.slug in ^slugs)
    |> Repo.all()
  end

  @doc """
  Gets a section by its slug.

  Returns the section if found, nil otherwise.

  ## Examples

      iex> get_section_by_slug("my-first-section")
      %Section{slug: "my-first-section"}

      iex> get_section_by_slug("nonexistent")
      nil
  """
  def get_section_by_slug(slug) when is_binary(slug) do
    Section
    |> where([s], s.slug == ^slug)
    |> Repo.one()
  end

  @doc """

  Gets a section by its slug with preloaded associations.
  Returns the section if found, nil otherwise.
  ## Examples

      iex> get_section_by_slug_with_preloads("my-first-section")
      %Section{slug: "my-first-section", parent_section: ..., child_sections: [...], pages: [...]}

      iex> get_section_by_slug_with_preloads("nonexistent")
      nil
  """
  def get_section_by_slug_with_preloads(slug) when is_binary(slug) do
    Section
    |> preload([:parent_section, :child_sections, :pages])
    |> where([s], s.slug == ^slug)
    |> Repo.one()
  end

  @doc """
  Gets a page by its slug.

  Returns the page if found, nil otherwise.

  ## Examples

      iex> get_page_by_slug("my-first-page")
      %Page{slug: "my-first-page"}

      iex> get_page_by_slug("nonexistent")
      nil
  """
  def get_page_by_slug(slug) when is_binary(slug) do
    Page
    |> where([p], p.slug == ^slug)
    |> Repo.one()
  end

  @doc """
  Gets a page by its slug with preloaded associations.

  Returns the page if found, nil otherwise.

  ## Examples

      iex> get_page_by_slug_with_preloads("my-first-page")
      %Page{slug: "my-first-page", section: %Section{...}}

      iex> get_page_by_slug_with_preloads("nonexistent")
      nil
  """
  def get_page_by_slug_with_preloads(slug) when is_binary(slug) do
    Page
    |> preload(:section)
    |> where([p], p.slug == ^slug)
    |> Repo.one()
  end

  @doc """
  Gets a published page by its slug with preloaded associations.

  Returns the page if found and published, nil otherwise.

  ## Examples

      iex> get_published_page_by_slug_with_preloads("my-first-page")
      %Page{slug: "my-first-page", state: :published, section: %Section{...}}

      iex> get_published_page_by_slug_with_preloads("draft-page")
      nil
  """
  def get_published_page_by_slug_with_preloads(slug) when is_binary(slug) do
    Page
    |> preload(:section)
    |> where([p], p.slug == ^slug and p.state == :published)
    |> Repo.one()
  end

  @doc """
  Gets a published section by its slug with preloaded associations.

  Returns the section if found and published, nil otherwise.

  ## Examples

      iex> get_published_section_by_slug_with_preloads("my-first-section")
      %Section{slug: "my-first-section", state: :published, parent_section: ..., child_sections: [...], pages: [...]}

      iex> get_published_section_by_slug_with_preloads("draft-section")
      nil
  """
  def get_published_section_by_slug_with_preloads(slug) when is_binary(slug) do
    Section
    |> preload([:parent_section, :child_sections, :pages])
    |> where([s], s.slug == ^slug and s.state == :published)
    |> Repo.one()
  end

  @doc """
  Gets all pages matching the provided slugs list.

  Returns a list of pages in the order they were found.

  ## Examples

      iex> get_pages_by_slugs(["first-page", "second-page"])
      [%Page{slug: "first-page"}, %Page{slug: "second-page"}]

      iex> get_pages_by_slugs([])
      []
  """
  def get_pages_by_slugs(slugs) when is_list(slugs) do
    Page
    |> where([p], p.slug in ^slugs)
    |> Repo.all()
  end

  @doc """
  Builds a tree structure from a list of pages and sections based on parent/child relationships.

  Returns a list of maps representing the tree structure, where each node contains:
  - `:type` - either `:section` or `:page`
  - `:item` - the actual Section or Page struct
  - `:children` - a list of child nodes (for sections only)

  Root sections (those without a parent) appear at the top level. Pages are nested under
  their parent sections, and sections are nested under their parent sections.

  ## Examples

      iex> build_tree([%Page{}], [%Section{id: 1, parent_section_id: nil}])
      [%{type: :section, item: %Section{}, children: []}]

      iex> build_tree([], [])
      []
  """
  def build_tree(pages, sections) when is_list(pages) and is_list(sections) do
    # Create a map of section_id -> pages for quick lookup
    pages_by_section = Enum.group_by(pages, & &1.section_id)

    # Create a map of parent_section_id -> sections for quick lookup
    sections_by_parent = Enum.group_by(sections, & &1.parent_section_id)

    # Find root sections (those without a parent)
    root_sections = Map.get(sections_by_parent, nil, [])

    # Build the tree recursively
    build_section_nodes(root_sections, sections_by_parent, pages_by_section)
  end

  # Recursively build tree nodes for sections and their children
  defp build_section_nodes(sections, sections_by_parent, pages_by_section) do
    Enum.map(sections, fn section ->
      # Get child sections for this section
      child_sections = Map.get(sections_by_parent, section.id, [])

      # Get pages for this section
      section_pages = Map.get(pages_by_section, section.id, [])

      # Build child nodes recursively
      child_section_nodes =
        build_section_nodes(child_sections, sections_by_parent, pages_by_section)

      # Build page nodes
      page_nodes =
        Enum.map(section_pages, fn page ->
          %{type: :page, item: page}
        end)

      # Combine children: sections first, then pages
      children = child_section_nodes ++ page_nodes

      %{type: :section, item: section, children: children}
    end)
  end

  @doc """
  Builds the full slug path for a section or page by traversing up the parent chain.

  For sections, returns a list of slugs from root to the given section.
  For pages, returns a list of slugs from root section to the page.

  ## Examples

      iex> build_slug_path(%Section{slug: "child", parent_section: %Section{slug: "parent"}})
      ["parent", "child"]

      iex> build_slug_path(%Section{slug: "root", parent_section: nil})
      ["root"]

      iex> build_slug_path(%Page{slug: "page", section: %Section{slug: "section"}})
      ["section", "page"]
  """
  def build_slug_path(%Section{slug: slug, parent_section: nil}) do
    [slug]
  end

  def build_slug_path(%Section{slug: slug, parent_section: %Section{} = parent}) do
    build_slug_path(parent) ++ [slug]
  end

  def build_slug_path(%Section{slug: slug, parent_section: %Ecto.Association.NotLoaded{}}) do
    # If parent is not loaded, we can only return the current slug
    # This should be avoided by ensuring parent_section is preloaded
    [slug]
  end

  def build_slug_path(%Page{slug: slug, section: %Section{} = section}) do
    build_slug_path(section) ++ [slug]
  end

  def build_slug_path(%Page{slug: slug, section: %Ecto.Association.NotLoaded{}}) do
    # If section is not loaded, we can only return the page slug
    # This should be avoided by ensuring section is preloaded
    [slug]
  end

  @doc """
  Creates a section.

  ## Examples

      iex> create_section(%{name: "New Section"})
      {:ok, %Section{}}

      iex> create_section(%{name: nil})
      {:error, %Ecto.Changeset{}}
  """
  def create_section(attrs \\ %{}) do
    %Section{}
    |> Section.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a page.

  ## Examples

      iex> create_page(%{title: "New Page"})
      {:ok, %Page{}}

      iex> create_page(%{title: nil})
      {:error, %Ecto.Changeset{}}
  """
  def create_page(attrs \\ %{}) do
    %Page{}
    |> Page.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a section.

  ## Examples

      iex> delete_section(%Section{})
      {:ok, %Section{}}

      iex> delete_section(%Section{})
      {:error, %Ecto.Changeset{}}
  """
  def delete_section(%Section{} = section) do
    Repo.delete(section)
  end

  @doc """
  Deletes a page.

  ## Examples

      iex> delete_page(%Page{})
      {:ok, %Page{}}

      iex> delete_page(%Page{})
      {:error, %Ecto.Changeset{}}
  """
  def delete_page(%Page{} = page) do
    Repo.delete(page)
  end
end
