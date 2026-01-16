defmodule OPWeb.Storybook.CoreComponents.Flash do
  use PhoenixStorybook.Story, :component

  def function, do: &OPWeb.CoreComponents.flash/1
  def imports, do: [{OPWeb.CoreComponents, button: 1, show: 1}]
  def render_source, do: :function

  def template do
    """
    <.button phx-click={show("#:variation_id")}>
      Trigger Flash Message
    </.button>
    <.psb-variation/>
    """
  end

  def variations do
    [
      %Variation{
        id: :info,
        description: "Info flash message",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Info Flash
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :info,
          id: "info",
          hidden: true
        },
        slots: ["Your changes have been saved"]
      },
      %Variation{
        id: :error,
        description: "Error flash message",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Error Flash
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :error,
          id: "error",
          hidden: true
        },
        slots: ["Something went wrong"]
      },
      %Variation{
        id: :info_with_title,
        description: "Info flash with title",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Info with Title
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :info,
          title: "Success",
          id: "info-with-title",
          hidden: true
        },
        slots: ["Your profile has been updated successfully"]
      },
      %Variation{
        id: :error_with_title,
        description: "Error flash with title",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Error with Title
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :error,
          title: "Error",
          id: "error-with-title",
          hidden: true
        },
        slots: ["Failed to save your changes. Please try again."]
      },
      %Variation{
        id: :primary,
        description: "Primary flash",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Primary
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :info,
          color: "primary",
          id: "primary",
          hidden: true
        },
        slots: ["Primary colored flash message"]
      },
      %Variation{
        id: :secondary,
        description: "Secondary flash",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Secondary
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :info,
          color: "secondary",
          id: "secondary",
          hidden: true
        },
        slots: ["Secondary colored flash message"]
      },
      %Variation{
        id: :info_color,
        description: "Info flash",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Info Color
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :info,
          color: "info",
          id: "info-color",
          hidden: true
        },
        slots: ["Info colored flash message"]
      },
      %Variation{
        id: :success,
        description: "Success flash",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Success
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :info,
          color: "success",
          id: "success",
          hidden: true
        },
        slots: ["Success colored flash message"]
      },
      %Variation{
        id: :warning,
        description: "Warning flash",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Warning
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :info,
          color: "warning",
          id: "warning",
          hidden: true
        },
        slots: ["Warning colored flash message"]
      },
      %Variation{
        id: :error_color,
        description: "Error flash",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Error Color
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :error,
          color: "error",
          id: "error-color",
          hidden: true
        },
        slots: ["Error colored flash message"]
      },
      %Variation{
        id: :info_long,
        description: "Info flash with longer message",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Long Info
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :info,
          title: "Information",
          id: "info-long",
          hidden: true
        },
        slots: [
          "This is a longer informational flash message that provides more context and details about the action that just occurred. It demonstrates how the flash handles multiple lines of text."
        ]
      },
      %Variation{
        id: :error_long,
        description: "Error flash with detailed message",
        template: """
        <.button phx-click={show("#:variation_id")}>
          Trigger Long Error
        </.button>
        <.psb-variation/>
        """,
        attributes: %{
          kind: :error,
          title: "Validation Failed",
          id: "error-long",
          hidden: true
        },
        slots: [
          "Your form submission failed due to validation errors. Please review the highlighted fields and ensure all required information is provided correctly before trying again."
        ]
      }
    ]
  end
end
