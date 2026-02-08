defmodule OP.FeatureFlagsTest do
  use ExUnit.Case, async: true

  alias OP.FeatureFlags

  describe "enabled?/1" do
    test "returns true when flag is enabled" do
      Application.put_env(:op, :feature_flags, test_flag: true)
      assert FeatureFlags.enabled?(:test_flag) == true
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        tournaments_only: false
      )
    end

    test "returns false when flag is disabled" do
      Application.put_env(:op, :feature_flags, test_flag: false)
      assert FeatureFlags.enabled?(:test_flag) == false
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        tournaments_only: false
      )
    end

    test "returns false when flag is not configured" do
      Application.put_env(:op, :feature_flags, [])
      assert FeatureFlags.enabled?(:nonexistent_flag) == false
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        tournaments_only: false
      )
    end

    test "returns false when feature_flags config is not set" do
      Application.delete_env(:op, :feature_flags)
      assert FeatureFlags.enabled?(:any_flag) == false
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        tournaments_only: false
      )
    end
  end

  describe "registration_enabled?/0" do
    test "returns true when registration is enabled" do
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true
      )

      assert FeatureFlags.registration_enabled?() == true
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        tournaments_only: false
      )
    end

    test "returns false when registration is disabled" do
      Application.put_env(:op, :feature_flags, registration_enabled: false)
      assert FeatureFlags.registration_enabled?() == false
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        tournaments_only: false
      )
    end
  end

  describe "tournament_submission_enabled?/0" do
    test "returns true when tournament submission is enabled" do
      Application.put_env(:op, :feature_flags, tournament_submission_enabled: true)
      assert FeatureFlags.tournament_submission_enabled?() == true
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        tournaments_only: false
      )
    end

    test "returns false when tournament submission is disabled" do
      Application.put_env(:op, :feature_flags, tournament_submission_enabled: false)
      assert FeatureFlags.tournament_submission_enabled?() == false
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        tournaments_only: false
      )
    end
  end

  describe "tournaments_only?/0" do
    test "returns true when tournaments_only is enabled" do
      Application.put_env(:op, :feature_flags, tournaments_only: true)
      assert FeatureFlags.tournaments_only?() == true
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        tournaments_only: false
      )
    end

    test "returns false when tournaments_only is disabled" do
      Application.put_env(:op, :feature_flags, tournaments_only: false)
      assert FeatureFlags.tournaments_only?() == false
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        tournaments_only: false
      )
    end
  end
end
