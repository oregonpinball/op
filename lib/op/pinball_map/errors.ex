defmodule OP.PinballMap.Errors do
  @moduledoc """
  Custom error types for Pinball Map API interactions.
  """

  defmodule ApiError do
    @moduledoc "Raised when the Pinball Map API returns an error"
    defexception [:message, :status_code, :response]

    @impl true
    def exception(opts) do
      status_code = Keyword.get(opts, :status_code)
      response = Keyword.get(opts, :response)

      %__MODULE__{
        message: "Pinball Map API error (status #{status_code})",
        status_code: status_code,
        response: response
      }
    end
  end

  defmodule NetworkError do
    @moduledoc "Raised when a network error occurs"
    defexception [:message, :cause]

    @impl true
    def exception(opts) do
      cause = Keyword.get(opts, :cause)

      %__MODULE__{
        message: "Network error connecting to Pinball Map API",
        cause: cause
      }
    end
  end
end
