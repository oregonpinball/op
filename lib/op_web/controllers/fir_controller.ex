defmodule OPWeb.FirController do
  use OPWeb, :controller

  alias OP.Fir
  alias OP.Fir.{Section, Page}

  def content(conn, %{"slugs" => slugs}) do
    # Get the last slug from the list to find the specific content
    last_slug = List.last(slugs)
    is_system_admin? = is_system_admin?(conn.assigns.current_scope)

    #
    # NOTE: This could be replaced with some sort of Ability.can?(:read, ...) system
    # if this gets more complicated in the future.
    #
    page =
      if is_system_admin? do
        Fir.get_page_by_slug_with_preloads(last_slug)
      else
        Fir.get_published_page_by_slug_with_preloads(last_slug)
      end

    case page do
      %Page{} = page ->
        render(conn, :content, content: page, type: :page)

      nil ->
        # If no page found, try to find a section
        section =
          if is_system_admin? do
            Fir.get_section_by_slug_with_preloads(last_slug)
          else
            Fir.get_published_section_by_slug_with_preloads(last_slug)
          end

        case section do
          %Section{} = section ->
            render(conn, :content, content: section, type: :section)

          nil ->
            # No content found
            conn
            |> put_status(:not_found)
            |> render(:"404", message: "Content cannot be found")
        end
    end
  end
end
