defmodule OPWeb.Storybook.CoreComponents.Input do
  use PhoenixStorybook.Story, :component

  def function, do: &OPWeb.CoreComponents.input/1

  def variations do
    [
      %Variation{
        id: :default,
        description: "Default text input",
        attributes: %{
          name: "default-input",
          label: "Default Input",
          value: ""
        }
      },
      %VariationGroup{
        id: :text_inputs,
        description: "Text-based input types",
        variations: [
          %Variation{
            id: :text,
            description: "Standard text input",
            attributes: %{
              type: "text",
              name: "text-input",
              label: "Text Input",
              value: "Sample text",
              placeholder: "Enter text..."
            }
          },
          %Variation{
            id: :email,
            description: "Email input",
            attributes: %{
              type: "email",
              name: "email-input",
              label: "Email Address",
              value: "user@example.com",
              placeholder: "you@example.com"
            }
          },
          %Variation{
            id: :password,
            description: "Password input",
            attributes: %{
              type: "password",
              name: "password-input",
              label: "Password",
              value: "secret123",
              placeholder: "Enter password..."
            }
          },
          %Variation{
            id: :search,
            description: "Search input",
            attributes: %{
              type: "search",
              name: "search-input",
              label: "Search",
              value: "",
              placeholder: "Search..."
            }
          },
          %Variation{
            id: :url,
            description: "URL input",
            attributes: %{
              type: "url",
              name: "url-input",
              label: "Website URL",
              value: "https://example.com",
              placeholder: "https://..."
            }
          },
          %Variation{
            id: :tel,
            description: "Telephone input",
            attributes: %{
              type: "tel",
              name: "tel-input",
              label: "Phone Number",
              value: "+1-555-0100",
              placeholder: "+1-555-0100"
            }
          }
        ]
      },
      %VariationGroup{
        id: :number_inputs,
        description: "Number-based input types",
        variations: [
          %Variation{
            id: :number,
            description: "Number input",
            attributes: %{
              type: "number",
              name: "number-input",
              label: "Quantity",
              value: "42"
            }
          },
          %Variation{
            id: :number_with_constraints,
            description: "Number input with min/max",
            attributes: %{
              type: "number",
              name: "constrained-number",
              label: "Age (18-100)",
              value: "25"
            }
          }
        ]
      },
      %VariationGroup{
        id: :date_time_inputs,
        description: "Date and time input types",
        variations: [
          %Variation{
            id: :date,
            description: "Date input",
            attributes: %{
              type: "date",
              name: "date-input",
              label: "Select Date",
              value: "2026-01-16"
            }
          },
          %Variation{
            id: :time,
            description: "Time input",
            attributes: %{
              type: "time",
              name: "time-input",
              label: "Select Time",
              value: "14:30"
            }
          },
          %Variation{
            id: :datetime_local,
            description: "DateTime local input",
            attributes: %{
              type: "datetime-local",
              name: "datetime-input",
              label: "Select Date & Time",
              value: "2026-01-16T14:30"
            }
          },
          %Variation{
            id: :month,
            description: "Month input",
            attributes: %{
              type: "month",
              name: "month-input",
              label: "Select Month",
              value: "2026-01"
            }
          },
          %Variation{
            id: :week,
            description: "Week input",
            attributes: %{
              type: "week",
              name: "week-input",
              label: "Select Week",
              value: "2026-W03"
            }
          }
        ]
      },
      %VariationGroup{
        id: :checkbox_inputs,
        description: "Checkbox inputs",
        variations: [
          %Variation{
            id: :checkbox_checked,
            description: "Checked checkbox",
            attributes: %{
              type: "checkbox",
              name: "checkbox-checked",
              label: "I agree to the terms",
              checked: true
            }
          },
          %Variation{
            id: :checkbox_unchecked,
            description: "Unchecked checkbox",
            attributes: %{
              type: "checkbox",
              name: "checkbox-unchecked",
              label: "Subscribe to newsletter",
              checked: false
            }
          },
          %Variation{
            id: :checkbox_disabled,
            description: "Disabled checkbox",
            attributes: %{
              type: "checkbox",
              name: "checkbox-disabled",
              label: "Cannot be changed (disabled)",
              checked: true,
              disabled: true
            }
          }
        ]
      },
      %VariationGroup{
        id: :select_inputs,
        description: "Select dropdown inputs",
        variations: [
          %Variation{
            id: :select,
            description: "Basic select input",
            attributes: %{
              type: "select",
              name: "select-input",
              label: "Choose Option",
              value: "option2",
              options: [
                {"Option 1", "option1"},
                {"Option 2", "option2"},
                {"Option 3", "option3"}
              ]
            }
          },
          %Variation{
            id: :select_with_prompt,
            description: "Select with prompt",
            attributes: %{
              type: "select",
              name: "select-prompt",
              label: "Choose Country",
              value: "",
              prompt: "Select a country...",
              options: [
                {"United States", "us"},
                {"Canada", "ca"},
                {"United Kingdom", "uk"},
                {"Germany", "de"},
                {"France", "fr"}
              ]
            }
          },
          %Variation{
            id: :select_multiple,
            description: "Multiple select",
            attributes: %{
              type: "select",
              name: "select-multiple",
              label: "Choose Tags",
              value: ["elixir", "phoenix"],
              multiple: true,
              options: [
                {"Elixir", "elixir"},
                {"Phoenix", "phoenix"},
                {"LiveView", "liveview"},
                {"Ecto", "ecto"},
                {"JavaScript", "javascript"}
              ]
            }
          }
        ]
      },
      %VariationGroup{
        id: :textarea_inputs,
        description: "Textarea inputs",
        variations: [
          %Variation{
            id: :textarea,
            description: "Basic textarea",
            attributes: %{
              type: "textarea",
              name: "textarea-input",
              label: "Description",
              value: "This is a longer text area for multi-line content.",
              rows: "4"
            }
          },
          %Variation{
            id: :textarea_empty,
            description: "Empty textarea with placeholder",
            attributes: %{
              type: "textarea",
              name: "textarea-empty",
              label: "Your Message",
              value: "",
              placeholder: "Enter your message here...",
              rows: "6"
            }
          }
        ]
      },
      %VariationGroup{
        id: :other_inputs,
        description: "Other input types",
        variations: [
          %Variation{
            id: :color,
            description: "Color picker input",
            attributes: %{
              type: "color",
              name: "color-input",
              label: "Choose Color",
              value: "#3b82f6"
            }
          },
          %Variation{
            id: :file,
            description: "File input",
            attributes: %{
              type: "file",
              name: "file-input",
              label: "Upload File",
              value: nil
            }
          }
        ]
      },
      %VariationGroup{
        id: :input_states,
        description: "Input states and variations",
        variations: [
          %Variation{
            id: :required,
            description: "Required input",
            attributes: %{
              type: "text",
              name: "required-input",
              label: "Required Field",
              value: "",
              required: true,
              placeholder: "This field is required"
            }
          },
          %Variation{
            id: :disabled,
            description: "Disabled input",
            attributes: %{
              type: "text",
              name: "disabled-input",
              label: "Disabled Input",
              value: "Cannot edit this",
              disabled: true
            }
          },
          %Variation{
            id: :readonly,
            description: "Readonly input",
            attributes: %{
              type: "text",
              name: "readonly-input",
              label: "Read-only Input",
              value: "This is read-only",
              readonly: true
            }
          },
          %Variation{
            id: :with_errors,
            description: "Input with validation errors",
            attributes: %{
              type: "email",
              name: "error-input",
              label: "Email with Error",
              value: "invalid-email",
              errors: ["must be a valid email address", "is already taken"]
            }
          },
          %Variation{
            id: :with_placeholder,
            description: "Input with placeholder",
            attributes: %{
              type: "text",
              name: "placeholder-input",
              label: "Username",
              value: "",
              placeholder: "Enter your username..."
            }
          }
        ]
      },
      %VariationGroup{
        id: :custom_styling,
        description: "Inputs with custom styling",
        variations: [
          %Variation{
            id: :custom_class,
            description: "Input with custom class",
            attributes: %{
              type: "text",
              name: "custom-class-input",
              label: "Custom Styled Input",
              value: "Custom styling",
              class: "p-4 border-2 border-blue-500 rounded-xl bg-blue-50 text-blue-900"
            }
          },
          %Variation{
            id: :custom_error_class,
            description: "Input with custom error styling",
            attributes: %{
              type: "text",
              name: "custom-error-input",
              label: "Custom Error Styling",
              value: "Invalid value",
              errors: ["is invalid"],
              error_class: "border-4 border-purple-600 bg-purple-100"
            }
          }
        ]
      },
      %VariationGroup{
        id: :input_without_label,
        description: "Inputs without labels",
        variations: [
          %Variation{
            id: :no_label_text,
            description: "Text input without label",
            attributes: %{
              type: "text",
              name: "no-label-input",
              value: "No label",
              placeholder: "Search..."
            }
          },
          %Variation{
            id: :no_label_select,
            description: "Select without label",
            attributes: %{
              type: "select",
              name: "no-label-select",
              value: "option1",
              options: [
                {"Quick Option 1", "option1"},
                {"Quick Option 2", "option2"}
              ]
            }
          }
        ]
      }
    ]
  end
end
