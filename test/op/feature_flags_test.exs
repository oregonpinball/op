defmodule OP.FeatureFlagsTest do
  use ExUnit.Case, async: true

  alias OP.FeatureFlags

  describe "enabled?/1" do
    test "returns true when flag is enabled" do
      Application.put_env(:op, :feature_flags, test_flag: true)
      assert FeatureFlags.enabled?(:test_flag) == true
    after
      Application.put_env(:op, :feature_flags, registration_enabled: true)
    end

    test "returns false when flag is disabled" do
      Application.put_env(:op, :feature_flags, test_flag: false)
      assert FeatureFlags.enabled?(:test_flag) == false
    after
      Application.put_env(:op, :feature_flags, registration_enabled: true)
    end

    test "returns false when flag is not configured" do
      Application.put_env(:op, :feature_flags, [])
      assert FeatureFlags.enabled?(:nonexistent_flag) == false
    after
      Application.put_env(:op, :feature_flags, registration_enabled: true)
    end

    test "returns false when feature_flags config is not set" do
      Application.delete_env(:op, :feature_flags)
      assert FeatureFlags.enabled?(:any_flag) == false
    after
      Application.put_env(:op, :feature_flags, registration_enabled: true)
    end
  end

  describe "registration_enabled?/0" do
    test "returns true when registration is enabled" do
      Application.put_env(:op, :feature_flags, registration_enabled: true)
      assert FeatureFlags.registration_enabled?() == true
    after
      Application.put_env(:op, :feature_flags, registration_enabled: true)
    end

    test "returns false when registration is disabled" do
      Application.put_env(:op, :feature_flags, registration_enabled: false)
      assert FeatureFlags.registration_enabled?() == false
    after
      Application.put_env(:op, :feature_flags, registration_enabled: true)
    end
  end
end
