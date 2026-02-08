defmodule OP.FeatureFlags do
  @moduledoc """
  Central module for feature flags controlled via environment variables.

  Flags are read from `Application.get_env(:op, :feature_flags)` which is
  populated in `config/runtime.exs` from environment variables.
  All flags default to off (false) when unset.
  """

  @flags [
    %{
      key: :registration_enabled,
      label: "Registration",
      description: "Allows new users to register accounts via the public registration page."
    },
    %{
      key: :tournament_submission_enabled,
      label: "Tournament Submission",
      description: "Allows tournament directors to submit new tournaments for review."
    },
    %{
      key: :magic_link_login_enabled,
      label: "Magic Link Login",
      description: "Allows users to log in via a magic link sent to their email."
    },
    %{
      key: :tournaments_only,
      label: "Tournaments Only",
      description:
        "Restricts the site to only show tournament-related content for logged-out users."
    }
  ]

  @doc """
  Returns all feature flags with their current enabled state.
  """
  @spec flags() :: [
          %{key: atom(), label: String.t(), description: String.t(), enabled: boolean()}
        ]
  def flags do
    Enum.map(@flags, fn flag -> Map.put(flag, :enabled, enabled?(flag.key)) end)
  end

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

  @doc """
  Returns whether tournament submission is enabled.
  """
  @spec tournament_submission_enabled?() :: boolean()
  def tournament_submission_enabled?, do: enabled?(:tournament_submission_enabled)

  @doc """
  Returns whether magic link login is enabled.
  """
  @spec magic_link_login_enabled?() :: boolean()
  def magic_link_login_enabled?, do: enabled?(:magic_link_login_enabled)

  @doc """
  Returns whether tournaments-only mode is enabled.
  """
  @spec tournaments_only?() :: boolean()
  def tournaments_only?, do: enabled?(:tournaments_only)
end
