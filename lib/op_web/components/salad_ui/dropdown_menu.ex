defmodule SaladUI.DropdownMenu do
  @moduledoc """
  Implementation of dropdown menu component for SaladUI framework.

  Dropdown menus display a list of options when a trigger element is clicked.
  They provide a way to select from multiple options while conserving screen space.

  ## Examples:

      <.dropdown_menu id="user-menu">
        <.dropdown_menu_trigger>
          <.button variant="outline">Open Menu</.button>
        </.dropdown_menu_trigger>
        <.dropdown_menu_content>
          <.dropdown_menu_label>My Account</.dropdown_menu_label>
          <.dropdown_menu_separator />
          <.dropdown_menu_group>
            <.dropdown_menu_item on-select={JS.push("profile_selected")}>
              Profile
              <.dropdown_menu_shortcut>⌘P</.dropdown_menu_shortcut>
            </.dropdown_menu_item>
            <.dropdown_menu_item on-select={JS.push("settings_selected")}>
              Settings
              <.dropdown_menu_shortcut>⌘S</.dropdown_menu_shortcut>
            </.dropdown_menu_item>
            <.dropdown_menu_item disabled>
              Disabled Option
            </.dropdown_menu_item>
          </.dropdown_menu_group>
          <.dropdown_menu_separator />
          <.dropdown_menu_item variant="destructive" on-select={JS.push("logout")}>
            Log out
          </.dropdown_menu_item>
        </.dropdown_menu_content>
      </.dropdown_menu>

  ## Example with checkbox items
      <.dropdown_menu id="options-menu">
        <.dropdown_menu_trigger>
          <.button variant="outline">Options</.button>
        </.dropdown_menu_trigger>
        <.dropdown_menu_content>
          <.dropdown_menu_checkbox_item
            checked={@is_bold}
            on-checked-change={JS.push("toggle_bold")}
          >
            Bold
          </.dropdown_menu_checkbox_item>
          <.dropdown_menu_checkbox_item
            checked={@is_italic}
            on-checked-change={JS.push("toggle_italic")}
          >
            Italic
          </.dropdown_menu_checkbox_item>
        </.dropdown_menu_content>
      </.dropdown_menu>
  """
  use Phoenix.Component
  import SaladUI.Helpers

  @doc """
  The main dropdown menu component that manages state and positioning.

  ## Options

  * `:id` - Required unique identifier for the dropdown menu.
  * `:open` - Whether the dropdown is initially open. Defaults to `false`.
  * `:use-portal` - Whether to render the dropdown in a portal. Defaults to `false`.
  * `:portal-container` - CSS selector for the portal container. Defaults to `nil`.
  * `:on-open` - Handler for dropdown menu open event.
  * `:on-close` - Handler for dropdown menu close event.
  * `:class` - Additional CSS classes.
  """
  attr :id, :string, required: true, doc: "Unique identifier for the dropdown menu"
  attr :open, :boolean, default: false, doc: "Whether the dropdown menu is initially open"
  attr :"use-portal", :boolean, default: false, doc: "Whether to render the content in a portal"
  attr :"portal-container", :string, default: nil, doc: "CSS selector for the portal container"
  attr :"on-open", :any, default: nil, doc: "Handler for dropdown menu open event"
  attr :"on-close", :any, default: nil, doc: "Handler for dropdown menu close event"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu(assigns) do
    # Collect event mappings
    event_map =
      %{}
      |> add_event_mapping(assigns, "opened", :"on-open")
      |> add_event_mapping(assigns, "closed", :"on-close")

    # Convert kebab-case attributes to snake_case for use in the template
    assigns =
      assigns
      |> assign(:event_map, json(event_map))
      |> assign(:initial_state, if(assigns.open, do: "open", else: "closed"))
      |> assign(:use_portal, assigns[:"use-portal"])
      |> assign(:portal_container, assigns[:"portal-container"])
      |> assign(
        :options,
        json(%{
          usePortal: assigns[:"use-portal"],
          portalContainer: assigns[:"portal-container"],
          animations: get_animation_config()
        })
      )

    ~H"""
    <div
      id={@id}
      class={classes(["relative inline-block", @class])}
      data-component="dropdown-menu"
      data-state={@initial_state}
      data-event-mappings={@event_map}
      data-options={@options}
      data-part="root"
      phx-hook="SaladUI"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  The trigger element that toggles the dropdown menu.

  ## Options

  * `:class` - Additional CSS classes.
  * `:as` - The HTML tag to use for the trigger. Defaults to `"div"`.
  """
  attr :class, :string, default: nil
  attr :as, :any, default: "div"
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_trigger(assigns) do
    ~H"""
    <.dynamic tag={@as} data-part="trigger" tab-index="0" class={classes(["", @class])} {@rest}>
      {render_slot(@inner_block)}
    </.dynamic>
    """
  end

  @doc """
  The dropdown menu content that appears when triggered.

  ## Options

  * `:side` - Placement of the dropdown menu relative to the trigger (top, right, bottom, left). Defaults to `"bottom"`.
  * `:align` - Alignment of the dropdown menu (start, center, end). Defaults to `"start"`.
  * `:side-offset` - Distance from the trigger in pixels. Defaults to `4`.
  * `:align-offset` - Offset along the alignment axis. Defaults to `0`.
  * `:class` - Additional CSS classes.
  """
  attr :class, :string, default: nil
  attr :side, :string, values: ~w(top right bottom left), default: "bottom"
  attr :align, :string, values: ~w(start center end), default: "start"
  attr :"side-offset", :integer, default: 4, doc: "Distance from the trigger in pixels"
  attr :"align-offset", :integer, default: 0, doc: "Offset along the alignment axis"
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_menu_content(assigns) do
    assigns =
      assign(assigns, %{
        side_offset: assigns[:"side-offset"],
        align_offset: assigns[:"align-offset"]
      })

    ~H"""
    <div
      data-part="positioner"
      data-side={@side}
      data-align={@align}
      data-side-offset={@side_offset}
      data-align-offset={@align_offset}
      class="absolute z-50"
      style="min-width: var(--salad-reference-width)"
      hidden
    >
      <div
        data-part="content"
        class={
          classes([
            "z-50 min-w-[8rem] overflow-hidden rounded-md border",
            "transition-all data-[state=open]:animate-in data-[state=open]:animate-pop-in data-[state=closed]:animate-out",
            "bg-white",
            @class
          ])
        }
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp get_animation_config do
    %{
      "open_to_closed" => %{
        duration: 130,
        target_part: "content"
      }
    }
  end

  defp classes(input) do
    TwMerge.merge(List.flatten(input))
  end
end
