defmodule OPWeb.Storybook.CoreComponents.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &OPWeb.CoreComponents.button/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default button with primary color",
        slots: ["Click me"]
      },
      %Variation{
        id: :primary,
        description: "Primary colored button",
        attributes: %{
          color: "primary"
        },
        slots: ["Primary"]
      },
      %Variation{
        id: :secondary,
        description: "Secondary colored button",
        attributes: %{
          color: "secondary"
        },
        slots: ["Secondary"]
      },
      %Variation{
        id: :info,
        description: "Info colored button",
        attributes: %{
          color: "info"
        },
        slots: ["Info"]
      },
      %Variation{
        id: :success,
        description: "Success colored button",
        attributes: %{
          color: "success"
        },
        slots: ["Success"]
      },
      %Variation{
        id: :warning,
        description: "Warning colored button",
        attributes: %{
          color: "warning"
        },
        slots: ["Warning"]
      },
      %Variation{
        id: :error,
        description: "Error colored button",
        attributes: %{
          color: "error"
        },
        slots: ["Error"]
      },
      %Variation{
        id: :invisible,
        description: "Invisible button with transparent background",
        attributes: %{
          color: "invisible"
        },
        slots: ["Invisible"]
      },
      %VariationGroup{
        id: :sizes,
        description: "Button sizes",
        variations: [
          %Variation{
            id: :xs,
            description: "Extra small button",
            attributes: %{
              size: "xs"
            },
            slots: ["Extra Small"]
          },
          %Variation{
            id: :sm,
            description: "Small button",
            attributes: %{
              size: "sm"
            },
            slots: ["Small"]
          },
          %Variation{
            id: :md,
            description: "Medium button (default)",
            attributes: %{
              size: "md"
            },
            slots: ["Medium"]
          },
          %Variation{
            id: :lg,
            description: "Large button",
            attributes: %{
              size: "lg"
            },
            slots: ["Large"]
          },
          %Variation{
            id: :xl,
            description: "Extra large button",
            attributes: %{
              size: "xl"
            },
            slots: ["Extra Large"]
          }
        ]
      },
      %VariationGroup{
        id: :with_navigation,
        description: "Buttons with navigation",
        variations: [
          %Variation{
            id: :navigate,
            description: "Button with navigate link",
            attributes: %{
              navigate: "/",
              color: "primary"
            },
            slots: ["Go Home"]
          },
          %Variation{
            id: :patch,
            description: "Button with patch link",
            attributes: %{
              patch: "/",
              color: "secondary"
            },
            slots: ["Patch Route"]
          },
          %Variation{
            id: :href,
            description: "Button with href",
            attributes: %{
              href: "https://example.com",
              color: "info"
            },
            slots: ["External Link"]
          }
        ]
      }
    ]
  end
end
