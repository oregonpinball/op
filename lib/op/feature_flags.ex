defmodule OP.FeatureFlags do
  @moduledoc """
  Central module for feature flags controlled via environment variables.

  Flags are read from `Application.get_env(:op, :feature_flags)` which is
  populated in `config/runtime.exs` from environment variables.
  All flags default to off (false) when unset.
  """

  @doc """
  Returns whether the given feature flag is enabled.
  """
  @spec enabled?(atom()) :: boolean()
  def enabled?(flag) do
    :op
    |> Application.get_env(:feature_flags, [])
    |> Keyword.get(flag, false)
  end

  @doc """
  Returns whether user registration is enabled.
  """
  @spec registration_enabled?() :: boolean()
  def registration_enabled?, do: enabled?(:registration_enabled)
end
