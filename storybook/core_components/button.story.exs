defmodule OPWeb.Storybook.CoreComponents.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &OPWeb.CoreComponents.button/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default button with secondary color and solid variant",
        slots: ["Click me"]
      },
      %VariationGroup{
        id: :colors_solid,
        description: "Solid variant buttons (all colors)",
        variations: [
          %Variation{
            id: :primary_solid,
            description: "Primary solid button",
            attributes: %{
              color: "primary",
              variant: "solid"
            },
            slots: ["Primary"]
          },
          %Variation{
            id: :secondary_solid,
            description: "Secondary solid button",
            attributes: %{
              color: "secondary",
              variant: "solid"
            },
            slots: ["Secondary"]
          },
          %Variation{
            id: :info_solid,
            description: "Info solid button",
            attributes: %{
              color: "info",
              variant: "solid"
            },
            slots: ["Info"]
          },
          %Variation{
            id: :success_solid,
            description: "Success solid button",
            attributes: %{
              color: "success",
              variant: "solid"
            },
            slots: ["Success"]
          },
          %Variation{
            id: :warning_solid,
            description: "Warning solid button",
            attributes: %{
              color: "warning",
              variant: "solid"
            },
            slots: ["Warning"]
          },
          %Variation{
            id: :error_solid,
            description: "Error solid button",
            attributes: %{
              color: "error",
              variant: "solid"
            },
            slots: ["Error"]
          }
        ]
      },
      %VariationGroup{
        id: :colors_invisible,
        description: "Invisible variant buttons (all colors)",
        variations: [
          %Variation{
            id: :primary_invisible,
            description: "Primary invisible button",
            attributes: %{
              color: "primary",
              variant: "invisible"
            },
            slots: ["Primary"]
          },
          %Variation{
            id: :secondary_invisible,
            description: "Secondary invisible button",
            attributes: %{
              color: "secondary",
              variant: "invisible"
            },
            slots: ["Secondary"]
          },
          %Variation{
            id: :info_invisible,
            description: "Info invisible button",
            attributes: %{
              color: "info",
              variant: "invisible"
            },
            slots: ["Info"]
          },
          %Variation{
            id: :success_invisible,
            description: "Success invisible button",
            attributes: %{
              color: "success",
              variant: "invisible"
            },
            slots: ["Success"]
          },
          %Variation{
            id: :warning_invisible,
            description: "Warning invisible button",
            attributes: %{
              color: "warning",
              variant: "invisible"
            },
            slots: ["Warning"]
          },
          %Variation{
            id: :error_invisible,
            description: "Error invisible button",
            attributes: %{
              color: "error",
              variant: "invisible"
            },
            slots: ["Error"]
          }
        ]
      },
      %VariationGroup{
        id: :colors_underline,
        description: "Underline variant buttons (all colors)",
        variations: [
          %Variation{
            id: :primary_underline,
            description: "Primary underline button",
            attributes: %{
              color: "primary",
              variant: "underline"
            },
            slots: ["Primary"]
          },
          %Variation{
            id: :secondary_underline,
            description: "Secondary underline button",
            attributes: %{
              color: "secondary",
              variant: "underline"
            },
            slots: ["Secondary"]
          },
          %Variation{
            id: :info_underline,
            description: "Info underline button",
            attributes: %{
              color: "info",
              variant: "underline"
            },
            slots: ["Info"]
          },
          %Variation{
            id: :success_underline,
            description: "Success underline button",
            attributes: %{
              color: "success",
              variant: "underline"
            },
            slots: ["Success"]
          },
          %Variation{
            id: :warning_underline,
            description: "Warning underline button",
            attributes: %{
              color: "warning",
              variant: "underline"
            },
            slots: ["Warning"]
          },
          %Variation{
            id: :error_underline,
            description: "Error underline button",
            attributes: %{
              color: "error",
              variant: "underline"
            },
            slots: ["Error"]
          }
        ]
      },
      %VariationGroup{
        id: :sizes_solid,
        description: "Button sizes (solid variant)",
        variations: [
          %Variation{
            id: :xs_solid,
            description: "Extra small solid button",
            attributes: %{
              size: "xs",
              variant: "solid",
              color: "primary"
            },
            slots: ["Extra Small"]
          },
          %Variation{
            id: :sm_solid,
            description: "Small solid button",
            attributes: %{
              size: "sm",
              variant: "solid",
              color: "primary"
            },
            slots: ["Small"]
          },
          %Variation{
            id: :md_solid,
            description: "Medium solid button (default)",
            attributes: %{
              size: "md",
              variant: "solid",
              color: "primary"
            },
            slots: ["Medium"]
          },
          %Variation{
            id: :lg_solid,
            description: "Large solid button",
            attributes: %{
              size: "lg",
              variant: "solid",
              color: "primary"
            },
            slots: ["Large"]
          },
          %Variation{
            id: :xl_solid,
            description: "Extra large solid button",
            attributes: %{
              size: "xl",
              variant: "solid",
              color: "primary"
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
              color: "primary",
              variant: "solid"
            },
            slots: ["Go Home"]
          },
          %Variation{
            id: :patch,
            description: "Button with patch link",
            attributes: %{
              patch: "/",
              color: "secondary",
              variant: "solid"
            },
            slots: ["Patch Route"]
          },
          %Variation{
            id: :href,
            description: "Button with href",
            attributes: %{
              href: "https://example.com",
              color: "info",
              variant: "underline"
            },
            slots: ["External Link"]
          }
        ]
      }
    ]
  end
end
