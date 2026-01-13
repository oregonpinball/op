defmodule OPWeb.Storybook.CoreComponents.Badge do
  use PhoenixStorybook.Story, :component

  def function, do: &OPWeb.CoreComponents.badge/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default badge with secondary color and medium size",
        slots: ["Badge"]
      },
      %VariationGroup{
        id: :colors,
        description: "Badge colors",
        variations: [
          %Variation{
            id: :primary,
            description: "Primary badge",
            attributes: %{
              color: "primary",
              size: "md"
            },
            slots: ["Primary"]
          },
          %Variation{
            id: :secondary,
            description: "Secondary badge",
            attributes: %{
              color: "secondary",
              size: "md"
            },
            slots: ["Secondary"]
          },
          %Variation{
            id: :info,
            description: "Info badge",
            attributes: %{
              color: "info",
              size: "md"
            },
            slots: ["Info"]
          },
          %Variation{
            id: :success,
            description: "Success badge",
            attributes: %{
              color: "success",
              size: "md"
            },
            slots: ["Success"]
          },
          %Variation{
            id: :warning,
            description: "Warning badge",
            attributes: %{
              color: "warning",
              size: "md"
            },
            slots: ["Warning"]
          },
          %Variation{
            id: :error,
            description: "Error badge",
            attributes: %{
              color: "error",
              size: "md"
            },
            slots: ["Error"]
          }
        ]
      },
      %VariationGroup{
        id: :sizes,
        description: "Badge sizes",
        variations: [
          %Variation{
            id: :xs,
            description: "Extra small badge",
            attributes: %{
              color: "primary",
              size: "xs"
            },
            slots: ["XS"]
          },
          %Variation{
            id: :sm,
            description: "Small badge",
            attributes: %{
              color: "primary",
              size: "sm"
            },
            slots: ["SM"]
          },
          %Variation{
            id: :md,
            description: "Medium badge",
            attributes: %{
              color: "primary",
              size: "md"
            },
            slots: ["MD"]
          },
          %Variation{
            id: :lg,
            description: "Large badge",
            attributes: %{
              color: "primary",
              size: "lg"
            },
            slots: ["LG"]
          },
          %Variation{
            id: :xl,
            description: "Extra large badge",
            attributes: %{
              color: "primary",
              size: "xl"
            },
            slots: ["XL"]
          }
        ]
      },
      %VariationGroup{
        id: :examples,
        description: "Badge examples with different content",
        variations: [
          %Variation{
            id: :status,
            description: "Status badge",
            attributes: %{
              color: "success",
              size: "sm"
            },
            slots: ["Active"]
          },
          %Variation{
            id: :count,
            description: "Count badge",
            attributes: %{
              color: "error",
              size: "xs"
            },
            slots: ["99+"]
          },
          %Variation{
            id: :category,
            description: "Category badge",
            attributes: %{
              color: "info",
              size: "md"
            },
            slots: ["Technology"]
          },
          %Variation{
            id: :truncate,
            description: "Long text badge (truncated)",
            attributes: %{
              color: "secondary",
              size: "md",
              class: "max-w-32"
            },
            slots: ["This is a very long badge text that will be truncated"]
          }
        ]
      }
    ]
  end
end
