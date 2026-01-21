defmodule OPWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: OPWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :hidden, :boolean, default: false, doc: "whether the flash should be hidden by default"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  attr :color, :string,
    default: "secondary",
    values: ~w(primary secondary info success warning error invisible),
    doc: "the color variant of the alert"

  attr :variant, :string,
    default: "solid",
    values: ~w(solid),
    doc: "the variant of the alert"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    base = "flex items-center space-x-2 max-w-xl p-2 rounded"

    # Flash uses `kind` to determine which set of flash messages
    # to pull and render.  This is also used for the `color` in a general
    # sense, wso we'll map it here
    color =
      case assigns.kind do
        :info -> "info"
        :error -> "error"
        _ -> assigns[:color] || "secondary"
      end

    colors =
      %{
        "primary" => %{
          "solid" => "border bg-emerald-100 text-emerald-800 border-emerald-400"
        },
        "secondary" => %{
          "solid" => "border bg-slate-100 text-slate-800 border-slate-300"
        },
        "info" => %{
          "solid" => "border bg-sky-100 text-sky-800 border-sky-400"
        },
        "success" => %{
          "solid" => "border bg-green-100 text-green-800 border-green-400"
        },
        "warning" => %{
          "solid" => "border bg-yellow-100 text-yellow-800 border-yellow-400"
        },
        "error" => %{
          "solid" => "border bg-red-100 text-red-800 border-red-400"
        },
        "invisible" => %{
          "solid" => "border bg-transparent text-inherit border-transparent"
        }
      }

    color_classes = colors |> Map.fetch!(color) |> Map.fetch!(assigns[:variant])
    class = [base, color_classes]
    assigns = Map.put(assigns, :class, class)
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        @hidden && "hidden",
        "fixed bottom-6 right-4 mr-2 max-w-xl rounded-lg p-4 transition-opacity duration-300 z-9999",
        @class
      ]}
      {@rest}
    >
      <div class={[
        "flex items-center space-x-2 max-w-sm text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button
          type="button"
          class="absolute top-0 right-2 group self-start cursor-pointer"
          aria-label={gettext("close")}
        >
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click={toggle("#test")} color="primary">Send!</.button>
      <.button navigate={~p"/"} size="xl">Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :string, default: ""

  attr :color, :string,
    default: "secondary",
    values: ~w(primary secondary info success warning error invisible),
    doc: "the color variant of the button"

  attr :variant, :string,
    default: "solid",
    values: ~w(solid invisible underline),
    doc: "the variant of the button"

  attr :size, :string, default: "md", values: ~w(xs sm md lg xl)

  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    base = "inline-flex rounded transition-colors font-medium hover:cursor-pointer"

    colors =
      %{
        "primary" => %{
          "solid" =>
            "border bg-emerald-800 text-emerald-50 border-emerald-950 hover:bg-emerald-900 dark:bg-rose-100",
          "invisible" =>
            "bg-transparent text-emerald-800 border-transparent hover:bg-emerald-100 dark:text-emerald-100 dark:hover:bg-emerald-900",
          "underline" => "bg-transparent underline decoration-emerald-500 hover:bg-slate-100/90"
        },
        "secondary" => %{
          "solid" =>
            "border bg-slate-200 text-slate-800 border-slate-300 hover:bg-slate-300 dark:bg-slate-100",
          "invisible" =>
            "bg-transparent text-slate-800 border-transparent hover:bg-slate-100 dark:text-slate-100 dark:hover:bg-slate-800",
          "underline" => "bg-transparent underline decoration-slate-400 hover:bg-slate-100/90"
        },
        "info" => %{
          "solid" =>
            "border bg-sky-800 text-sky-50 border-sky-950 hover:bg-sky-900 dark:bg-blue-100",
          "invisible" =>
            "bg-transparent text-sky-800 border-transparent hover:bg-sky-100 dark:text-sky-100 dark:hover:bg-sky-900",
          "underline" => "bg-transparent underline decoration-sky-500 hover:bg-slate-100/90"
        },
        "success" => %{
          "solid" =>
            "border bg-green-700 text-green-50 border-green-800 hover:bg-green-800 dark:bg-green-100",
          "invisible" =>
            "bg-transparent text-green-700 border-transparent hover:bg-green-100 dark:text-green-100 dark:hover:bg-green-900",
          "underline" => "bg-transparent underline decoration-green-500 hover:bg-slate-100/90"
        },
        "warning" => %{
          "solid" =>
            "border bg-yellow-600 text-yellow-50 border-yellow-800 hover:bg-yellow-700 dark:bg-yellow-100",
          "invisible" =>
            "bg-transparent text-yellow-600 border-transparent hover:bg-yellow-100 dark:text-yellow-100 dark:hover:bg-yellow-800",
          "underline" => "bg-transparent underline decoration-yellow-500 hover:bg-slate-100/90"
        },
        "error" => %{
          "solid" =>
            "border bg-red-800 text-red-50 border-red-950 hover:bg-red-900 dark:bg-red-100",
          "invisible" =>
            "bg-transparent text-red-800 border-transparent hover:bg-red-100 dark:text-red-100 dark:hover:bg-red-900",
          "underline" => "bg-transparent underline decoration-red-500 hover:bg-slate-100/90"
        },
        "invisible" => %{
          "solid" =>
            "border bg-transparent text-inherit border-transparent hover:bg-slate-100 dark:hover:bg-slate-800",
          "invisible" =>
            "bg-transparent text-inherit border-transparent hover:bg-slate-100 dark:hover:bg-slate-800",
          "underline" => "bg-transparent underline decoration-current hover:bg-slate-100/90"
        }
      }

    sizes =
      %{
        "xs" => %{
          "solid" => "text-xs p-0.5",
          "invisible" => "text-xs p-0.5",
          "underline" => ""
        },
        "sm" => %{
          "solid" => "text-sm p-0.5",
          "invisible" => "text-sm p-0.5",
          "underline" => ""
        },
        "md" => %{
          "solid" => "text-base py-1 px-2",
          "invisible" => "text-base py-1 px-2",
          "underline" => ""
        },
        "lg" => %{
          "solid" => "text-base p-2",
          "invisible" => "text-base p-2",
          "underline" => ""
        },
        "xl" => %{
          "solid" => "text-lg py-2 px-4",
          "invisible" => "text-lg py-2 px-4",
          "underline" => ""
        }
      }

    color_classes = colors |> Map.fetch!(assigns[:color]) |> Map.fetch!(assigns[:variant])
    size_classes = sizes |> Map.fetch!(assigns[:size]) |> Map.fetch!(assigns[:variant])
    class = [assigns.class, base, color_classes, size_classes]
    assigns = Map.put(assigns, :class, class)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an alert message with an icon.

  ## Examples

      <.alert>Something went wrong</.alert>
      <.alert color="success">Task completed successfully</.alert>
      <.alert color="error">Invalid input</.alert>
  """
  attr :class, :string, default: ""

  attr :color, :string,
    default: "secondary",
    values: ~w(primary secondary info success warning error invisible),
    doc: "the color variant of the alert"

  attr :variant, :string,
    default: "solid",
    values: ~w(solid invisible underline),
    doc: "the variant of the alert"

  attr :size, :string, default: "md", values: ~w(xs sm md lg xl)

  slot :inner_block, required: true

  def alert(assigns) do
    base = "flex items-center space-x-2 max-w-xl p-2 rounded"

    colors =
      %{
        "primary" => %{
          "solid" => "border bg-emerald-100 text-emerald-900 border-emerald-950"
        },
        "secondary" => %{
          "solid" => "border bg-slate-200 text-slate-900 border-slate-300"
        },
        "info" => %{
          "solid" => "border bg-sky-100 text-sky-900 border-sky-950"
        },
        "success" => %{
          "solid" => "border bg-green-100 text-green-900 border-green-800"
        },
        "warning" => %{
          "solid" => "border bg-yellow-100 text-yellow-900 border-yellow-800"
        },
        "error" => %{
          "solid" => "border bg-red-100 text-red-900 border-red-950"
        },
        "invisible" => %{
          "solid" => "border bg-transparent text-inherit border-transparent"
        }
      }

    color_classes = colors |> Map.fetch!(assigns[:color]) |> Map.fetch!(assigns[:variant])
    class = [assigns.class, base, color_classes]
    assigns = Map.put(assigns, :class, class)

    ~H"""
    <div role="alert" class={@class}>
      <.icon name="hero-exclamation-circle" class="size-5 shrink-0" />
      <div>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders
  """
  attr :class, :string, default: ""

  attr :color, :string,
    default: "secondary",
    values: ~w(primary secondary info success warning error invisible),
    doc: "the color variant of the button"

  attr :size, :string, default: "md", values: ~w(xs sm md lg xl)
  attr :rest, :global

  slot :inner_block, required: true

  def badge(assigns) do
    base = "inline-flex items-center truncate rounded-lg border font-medium transition-all"

    colors =
      %{
        "primary" => "bg-emerald-700 text-emerald-50 border-emerald-800 dark:bg-rose-100",
        "secondary" => "bg-slate-200 text-slate-800 border-slate-300 dark:bg-slate-100",
        "info" => "bg-sky-700 text-sky-50 border-sky-800 dark:bg-blue-100",
        "success" => "bg-green-700 text-green-50 border-green-800 dark:bg-green-100",
        "warning" => "bg-yellow-600 text-yellow-50 border-yellow-700 dark:bg-yellow-100",
        "error" => "bg-red-800 text-red-50 border-red-800 dark:bg-red-100"
      }

    sizes =
      %{
        "xs" => "text-xs px-0.5",
        "sm" => "text-xs px-1",
        "md" => "text-xs px-2 py-0.5",
        "lg" => "text-base px-1.5 py-1",
        "xl" => "text-lg px-2 py-1"
      }

    assigns =
      Map.put(assigns, :class, [
        base,
        Map.fetch!(colors, assigns[:color]),
        Map.fetch!(sizes, assigns[:size]),
        assigns.class
      ])

    ~H"""
    <span class={@class}>
      <span>
        {render_slot(@inner_block)}
      </span>
    </span>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :string, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="mb-2">
      <label>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            "p-2 border w-full rounded bg-white",
            @class || "",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="mb-2">
      <label>
        <span :if={@label} class="">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            "p-2 border w-full rounded bg-white transition-all",
            @class || "",
            @errors != [] && (@error_class || "bg-red-100 border-red-800")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1 flex items-center space-x-1 text-sm text-red-800">
      <.icon name="hero-exclamation-circle" class="size-5" />
      <span>{render_slot(@inner_block)}</span>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="w-full table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a modal dialog.

  ## Examples

      <.modal id="confirm-modal">
        Are you sure?
        <:actions>
          <.button>OK</.button>
        </:actions>
      </.modal>

  JS commands may be used to show and hide the modal:

      <.button phx-click={show_modal("my-modal")}>Show</.button>
      <.modal id="my-modal">Content</.modal>
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="fixed inset-0 bg-black/60 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="relative hidden rounded-xl bg-white border border-gray-200 p-8 shadow-lg shadow-gray-700/10 ring-1 ring-gray-700/10 transition"
            >
              <div class="absolute top-4 right-4">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-60 hover:opacity-100"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark" class="size-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows a modal by ID.
  """
  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "##{id}-container",
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc """
  Hides a modal by ID.
  """
  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      time: 200,
      transition: {"transition-all ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "##{id}-container",
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Renders a slide-over sheet that enters from the right side of the screen.

  Useful for mobile navigation menus or detail panes.
  """
  attr :id, :string, required: true
  slot :inner_block, required: true

  def sheet(assigns) do
    ~H"""
    <div id={@id} class="hidden z-100 fixed inset-0">
      <div class="fixed inset-0 bg-black/60 pointer-events-none" data-sheet-bg />
      <div
        class="outline-hidden fixed inset-0 flex justify-end animate-slide-in-right"
        data-sheet-content
      >
        <div class="p-4 min-w-3/4 md:min-w-1/4 overflow-y-auto relative bg-slate-100 border-l-4 dark:bg-slate-800 shadow-base flex flex-col">
          <div class="flex justify-end sticky top-0">
            <button phx-click={toggle("##{@id}")} class="" aria-label="Close">
              <.icon
                name="hero-x-mark"
                class="size-6 text-black dark:text-white hover:cursor-pointer"
              />
            </button>
          </div>

          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def toggle(_js \\ %JS{}, selector) do
    JS.dispatch("op:toggle", to: "#{selector}")
  end

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Renders pagination controls.

  ## Examples

      <.pagination page={@page} total_pages={@total_pages} path={~p"/admin/players"} params={@params} />
  """
  attr :page, :integer, required: true
  attr :total_pages, :integer, required: true
  attr :path, :string, required: true
  attr :params, :map, default: %{}

  def pagination(assigns) do
    ~H"""
    <nav
      :if={@total_pages > 1}
      class="flex items-center justify-center gap-1 mt-6"
      aria-label="Pagination"
    >
      <.link
        :if={@page > 1}
        patch={"#{@path}?#{URI.encode_query(Map.put(@params, "page", @page - 1))}"}
        class="p-2 rounded hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
        aria-label="Previous page"
      >
        <.icon name="hero-chevron-left" class="size-5" />
      </.link>
      <span :if={@page == 1} class="p-2 text-slate-400 dark:text-slate-600">
        <.icon name="hero-chevron-left" class="size-5" />
      </span>

      <%= for page_num <- pagination_range(@page, @total_pages) do %>
        <%= cond do %>
          <% page_num == :ellipsis -> %>
            <span class="px-2 text-slate-400">...</span>
          <% page_num == @page -> %>
            <span class="px-3 py-1 rounded bg-emerald-700 text-white font-medium">
              {page_num}
            </span>
          <% true -> %>
            <.link
              patch={"#{@path}?#{URI.encode_query(Map.put(@params, "page", page_num))}"}
              class="px-3 py-1 rounded hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
            >
              {page_num}
            </.link>
        <% end %>
      <% end %>

      <.link
        :if={@page < @total_pages}
        patch={"#{@path}?#{URI.encode_query(Map.put(@params, "page", @page + 1))}"}
        class="p-2 rounded hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
        aria-label="Next page"
      >
        <.icon name="hero-chevron-right" class="size-5" />
      </.link>
      <span :if={@page >= @total_pages} class="p-2 text-slate-400 dark:text-slate-600">
        <.icon name="hero-chevron-right" class="size-5" />
      </span>
    </nav>
    """
  end

  defp pagination_range(_current, total) when total <= 7 do
    Enum.to_list(1..total)
  end

  defp pagination_range(current, total) do
    cond do
      current <= 3 ->
        [1, 2, 3, 4, :ellipsis, total]

      current >= total - 2 ->
        [1, :ellipsis, total - 3, total - 2, total - 1, total]

      true ->
        [1, :ellipsis, current - 1, current, current + 1, :ellipsis, total]
    end
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(OPWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(OPWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
