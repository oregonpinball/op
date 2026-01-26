defmodule OPWeb.FirController do
  use OPWeb, :controller

  alias OP.Fir

  def content(conn, %{"slugs" => slugs}) do
    # Get the last slug from the list to find the specific content
    last_slug = List.last(slugs)

    # Try to find a page first, then a section
    case Fir.get_page_by_slug_with_preloads(last_slug) do
      %OP.Fir.Page{} = page ->
        render(conn, :content, content: page, type: :page)

      nil ->
        # If no page found, try to find a section
        section = Fir.get_section_by_slug_with_preloads(last_slug)

        case section do
          %OP.Fir.Section{} = section ->
            render(conn, :content, content: section, type: :section)

          nil ->
            # No content found
            conn
            |> put_status(:not_found)
            |> text("Content not found")
        end
    end
  end
end
