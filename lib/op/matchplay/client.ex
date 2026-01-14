defmodule OP.Matchplay.Client do
  @moduledoc """
  HTTP client for Matchplay Events API.
  Uses Req for HTTP requests as per project guidelines.
  """

  alias OP.Matchplay.Errors.{NotFoundError, ApiError, NetworkError}

  @base_url "https://app.matchplay.events/api"
  @default_timeout 30_000
  @req_options Application.compile_env(:op, :req_options, [])

  defstruct [:api_token, :base_url, :timeout]

  @type t :: %__MODULE__{
          api_token: String.t() | nil,
          base_url: String.t(),
          timeout: pos_integer()
        }

  @doc """
  Creates a new Matchplay client.

  ## Options
    * `:api_token` - API token for authentication (optional, falls back to config)
    * `:base_url` - Base URL for the API (optional, defaults to Matchplay production)
    * `:timeout` - Request timeout in milliseconds (optional, defaults to 30s)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    api_token =
      if Keyword.has_key?(opts, :api_token) do
        opts[:api_token]
      else
        Application.get_env(:op, :matchplay_api_token)
      end

    %__MODULE__{
      api_token: api_token,
      base_url: opts[:base_url] || @base_url,
      timeout: opts[:timeout] || @default_timeout
    }
  end

  @doc """
  Fetches a single tournament from Matchplay.

  Returns the tournament data wrapped in `{:ok, map()}` or an error tuple.
  """
  @spec get_tournament(t(), integer() | String.t()) :: {:ok, map()} | {:error, Exception.t()}
  def get_tournament(%__MODULE__{} = client, id) do
    case request(client, "/tournaments/#{id}") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  @doc """
  Fetches tournament standings from Matchplay.

  Note: The standings endpoint returns a plain array, not wrapped in `{"data": ...}`.
  """
  @spec get_standings(t(), integer() | String.t()) :: {:ok, list(map())} | {:error, Exception.t()}
  def get_standings(%__MODULE__{} = client, id) do
    request(client, "/tournaments/#{id}/standings")
  end

  defp request(%__MODULE__{} = client, path) do
    url = client.base_url <> path
    headers = build_headers(client)
    opts = [headers: headers, receive_timeout: client.timeout] ++ @req_options

    case Req.get(url, opts) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: 404}} ->
        # Extract ID from path for error message
        resource_id = path |> String.split("/") |> List.last()
        {:error, NotFoundError.exception(resource_id: resource_id)}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, ApiError.exception(status_code: status, response: body)}

      {:error, %Req.TransportError{} = error} ->
        {:error, NetworkError.exception(cause: error)}

      {:error, reason} ->
        {:error, NetworkError.exception(cause: reason)}
    end
  end

  defp build_headers(%__MODULE__{api_token: nil}) do
    [{"accept", "application/json"}]
  end

  defp build_headers(%__MODULE__{api_token: token}) do
    [
      {"accept", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]
  end
end
