defmodule OP.FeatureFlagsTest do
  use ExUnit.Case, async: false

  alias OP.FeatureFlags

  describe "enabled?/1" do
    test "returns true when flag is enabled" do
      Application.put_env(:op, :feature_flags, test_flag: true)
      assert FeatureFlags.enabled?(:test_flag) == true
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        magic_link_login_enabled: true,
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
        magic_link_login_enabled: true,
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
        magic_link_login_enabled: true,
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
        magic_link_login_enabled: true,
        tournaments_only: false
      )
    end
  end

  describe "registration_enabled?/0" do
    test "returns true when registration is enabled" do
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        magic_link_login_enabled: true,
        tournaments_only: false
      )

      assert FeatureFlags.registration_enabled?() == true
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        magic_link_login_enabled: true,
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
        magic_link_login_enabled: true,
        tournaments_only: false
      )
    end
  end

  describe "flags/0" do
    test "returns all flags with required keys" do
      flags = FeatureFlags.flags()

      assert length(flags) == 4

      Enum.each(flags, fn flag ->
        assert Map.has_key?(flag, :key)
        assert Map.has_key?(flag, :label)
        assert Map.has_key?(flag, :description)
        assert Map.has_key?(flag, :enabled)
        assert is_atom(flag.key)
        assert is_binary(flag.label)
        assert is_binary(flag.description)
        assert is_boolean(flag.enabled)
      end)
    end

    test "reflects current config state" do
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: false
      )

      flags = FeatureFlags.flags()
      reg = Enum.find(flags, &(&1.key == :registration_enabled))
      sub = Enum.find(flags, &(&1.key == :tournament_submission_enabled))

      assert reg.enabled == true
      assert sub.enabled == false
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true
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
        magic_link_login_enabled: true,
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
        magic_link_login_enabled: true,
        tournaments_only: false
      )
    end
  end

  describe "magic_link_login_enabled?/0" do
    test "returns true when magic link login is enabled" do
      Application.put_env(:op, :feature_flags, magic_link_login_enabled: true)
      assert FeatureFlags.magic_link_login_enabled?() == true
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        magic_link_login_enabled: true,
        tournaments_only: false
      )
    end

    test "returns false when magic link login is disabled" do
      Application.put_env(:op, :feature_flags, magic_link_login_enabled: false)
      assert FeatureFlags.magic_link_login_enabled?() == false
    after
      Application.put_env(:op, :feature_flags,
        registration_enabled: true,
        tournament_submission_enabled: true,
        magic_link_login_enabled: true,
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
        magic_link_login_enabled: true,
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
        magic_link_login_enabled: true,
        tournaments_only: false
      )
    end
  end
end
