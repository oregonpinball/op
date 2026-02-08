defmodule OP.PinballMap.Client do
  @moduledoc """
  HTTP client for Pinball Map API.
  Uses Req for HTTP requests as per project guidelines.
  """

  alias OP.PinballMap.Errors.{ApiError, NetworkError}

  @base_url "https://pinballmap.com/api/v1"
  @default_timeout 30_000
  @req_options Application.compile_env(:op, :pinball_map_req_options, [])

  defstruct [:base_url, :timeout]

  @type t :: %__MODULE__{
          base_url: String.t(),
          timeout: pos_integer()
        }

  @doc """
  Creates a new Pinball Map client.

  ## Options
    * `:base_url` - Base URL for the API (optional, defaults to Pinball Map production)
    * `:timeout` - Request timeout in milliseconds (optional, defaults to 30s)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      base_url: opts[:base_url] || @base_url,
      timeout: opts[:timeout] || @default_timeout
    }
  end

  @doc """
  Fetches locations for a given region from the Pinball Map API.

  Returns `{:ok, [location_map]}` on success or `{:error, exception}` on failure.
  """
  @spec get_region_locations(t(), String.t()) :: {:ok, list(map())} | {:error, Exception.t()}
  def get_region_locations(%__MODULE__{} = client, region_name) do
    case request(client, "/region/#{region_name}/locations.json") do
      {:ok, %{"locations" => locations}} when is_list(locations) -> {:ok, locations}
      {:ok, locations} when is_list(locations) -> {:ok, locations}
      {:ok, _body} -> {:ok, []}
      {:error, _} = error -> error
    end
  end

  defp request(%__MODULE__{} = client, path) do
    url = client.base_url <> path
    headers = [{"accept", "application/json"}]
    opts = [headers: headers, receive_timeout: client.timeout] ++ @req_options

    is_test? = Application.get_env(:op, :env) == :test
    opts = if is_test?, do: Keyword.put(opts, :retry, false), else: opts

    case Req.get(url, opts) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, ApiError.exception(status_code: status, response: body)}

      {:error, %Req.TransportError{} = error} ->
        {:error, NetworkError.exception(cause: error)}

      {:error, reason} ->
        {:error, NetworkError.exception(cause: reason)}
    end
  end
end
