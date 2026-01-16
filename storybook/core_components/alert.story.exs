defmodule OPWeb.Storybook.CoreComponents.Alert do
  use PhoenixStorybook.Story, :component

  def function, do: &OPWeb.CoreComponents.alert/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default alert with secondary color",
        slots: ["This is a default alert message"]
      },
      %VariationGroup{
        id: :colors,
        description: "Alert colors",
        variations: [
          %Variation{
            id: :primary,
            description: "Primary alert",
            attributes: %{
              color: "primary"
            },
            slots: ["This is a primary alert"]
          },
          %Variation{
            id: :secondary,
            description: "Secondary alert",
            attributes: %{
              color: "secondary"
            },
            slots: ["This is a secondary alert"]
          },
          %Variation{
            id: :info,
            description: "Info alert",
            attributes: %{
              color: "info"
            },
            slots: ["This is an informational message"]
          },
          %Variation{
            id: :success,
            description: "Success alert",
            attributes: %{
              color: "success"
            },
            slots: ["Operation completed successfully"]
          },
          %Variation{
            id: :warning,
            description: "Warning alert",
            attributes: %{
              color: "warning"
            },
            slots: ["This is a warning message"]
          },
          %Variation{
            id: :error,
            description: "Error alert",
            attributes: %{
              color: "error"
            },
            slots: ["An error has occurred"]
          },
          %Variation{
            id: :invisible,
            description: "Invisible alert",
            attributes: %{
              color: "invisible"
            },
            slots: ["This is an invisible alert"]
          }
        ]
      },
      %VariationGroup{
        id: :with_longer_messages,
        description: "Alerts with longer text content",
        variations: [
          %Variation{
            id: :info_long,
            description: "Info alert with longer message",
            attributes: %{
              color: "info"
            },
            slots: [
              "This is a longer informational message that provides more context and details about the situation. It demonstrates how the alert handles multiple lines of text."
            ]
          },
          %Variation{
            id: :error_long,
            description: "Error alert with detailed message",
            attributes: %{
              color: "error"
            },
            slots: [
              "An error occurred while processing your request. Please check your input and try again. If the problem persists, contact support."
            ]
          }
        ]
      }
    ]
  end
end
