defmodule OP.Matchplay.Errors do
  @moduledoc """
  Custom error types for Matchplay API interactions.
  """

  defmodule NotFoundError do
    @moduledoc "Raised when a tournament is not found on Matchplay"
    defexception [:message, :resource_id]

    @impl true
    def exception(opts) do
      resource_id = Keyword.get(opts, :resource_id, "unknown")

      %__MODULE__{
        message: "Tournament #{resource_id} not found on Matchplay",
        resource_id: resource_id
      }
    end
  end

  defmodule ApiError do
    @moduledoc "Raised when the Matchplay API returns an error"
    defexception [:message, :status_code, :response]

    @impl true
    def exception(opts) do
      status_code = Keyword.get(opts, :status_code)
      response = Keyword.get(opts, :response)

      %__MODULE__{
        message: "Matchplay API error (status #{status_code})",
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
        message: "Network error connecting to Matchplay API",
        cause: cause
      }
    end
  end
end
