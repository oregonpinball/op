defmodule OP.Tournaments.TgpCalculatorTest do
  use ExUnit.Case, async: true

  alias OP.Tournaments.TgpCalculator

  describe "calculate_tgp/1" do
    test "calculates 4% per meaningful game" do
      assert TgpCalculator.calculate_tgp(10) == 0.4
      assert TgpCalculator.calculate_tgp(25) == 1.0
      assert TgpCalculator.calculate_tgp(12.5) == 0.5
    end

    test "caps at 200% (2.0)" do
      assert TgpCalculator.calculate_tgp(50) == 2.0
      assert TgpCalculator.calculate_tgp(100) == 2.0
      assert TgpCalculator.calculate_tgp(75) == 2.0
    end

    test "handles 0 meaningful games" do
      assert TgpCalculator.calculate_tgp(0) == 0.0
    end

    test "handles fractional meaningful games" do
      assert TgpCalculator.calculate_tgp(13.5) == 0.54
    end
  end

  describe "calculate_first_place_value/2" do
    test "multiplies player count by TGP" do
      assert TgpCalculator.calculate_first_place_value(19, 0.54) == 19 * 0.54
      assert TgpCalculator.calculate_first_place_value(10, 1.0) == 10.0
      assert TgpCalculator.calculate_first_place_value(100, 2.0) == 200.0
    end

    test "handles edge cases" do
      assert TgpCalculator.calculate_first_place_value(1, 0.5) == 0.5
      assert TgpCalculator.calculate_first_place_value(1, 2.0) == 2.0
    end
  end

  describe "calculate_linear_points/3" do
    test "1st place gets highest linear points" do
      first_place_value = 10.26

      first = TgpCalculator.calculate_linear_points(1, 19, first_place_value)
      second = TgpCalculator.calculate_linear_points(2, 19, first_place_value)
      last = TgpCalculator.calculate_linear_points(19, 19, first_place_value)

      assert first > second
      assert second > last
    end

    test "points decrease evenly by position" do
      first_place_value = 10.26
      player_count = 19

      # The step between positions should be constant
      step = 0.1 * (first_place_value / player_count)

      first = TgpCalculator.calculate_linear_points(1, player_count, first_place_value)
      second = TgpCalculator.calculate_linear_points(2, player_count, first_place_value)
      third = TgpCalculator.calculate_linear_points(3, player_count, first_place_value)

      assert_in_delta first - second, step, 0.0001
      assert_in_delta second - third, step, 0.0001
    end

    test "last place gets lowest non-zero linear points" do
      first_place_value = 10.26
      player_count = 19

      last = TgpCalculator.calculate_linear_points(player_count, player_count, first_place_value)

      # Last place should get (19 + 1 - 19) * 0.1 * (10.26 / 19) = 1 * 0.1 * 0.54 = 0.054
      expected = 0.1 * (first_place_value / player_count)
      assert_in_delta last, expected, 0.0001
      assert last > 0
    end

    test "matches expected 1st place value from TGP guide" do
      # 19 players, FPV=10.26
      # Expected: (19 + 1 - 1) × 0.1 × (10.26 / 19) = 19 × 0.1 × 0.54 = 1.026
      first_place_value = 10.26
      result = TgpCalculator.calculate_linear_points(1, 19, first_place_value)
      assert_in_delta result, 1.026, 0.001
    end
  end

  describe "calculate_dynamic_points/3" do
    test "1st place gets approximately 90% of first_place_value" do
      first_place_value = 10.26

      # 1st place: position ratio = 0, so result = 1^3 * 0.9 * FPV = 0.9 * FPV
      result = TgpCalculator.calculate_dynamic_points(1, 19, first_place_value)
      expected = 0.9 * first_place_value

      assert_in_delta result, expected, 0.001
    end

    test "last place gets approximately 0" do
      first_place_value = 10.26

      result = TgpCalculator.calculate_dynamic_points(19, 19, first_place_value)

      # Should be very small (close to 0 but might not be exactly 0)
      assert result < 0.01
    end

    test "dynamic points decrease from 1st to last" do
      first_place_value = 10.26
      player_count = 19

      points =
        Enum.map(1..player_count, fn pos ->
          TgpCalculator.calculate_dynamic_points(pos, player_count, first_place_value)
        end)

      # Each position should have fewer or equal dynamic points than the one before
      points
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.each(fn [higher, lower] ->
        assert higher >= lower
      end)
    end

    test "respects divisor cap of 64 for large tournaments" do
      # With 200 players, divisor should cap at 64
      # Position 65 should behave as if divisor is 64, not 100
      first_place_value = 100.0
      player_count = 200

      # At position 65, ratio = (65-1)/64 = 1.0
      # So dynamic points should be 0 (or very close)
      result = TgpCalculator.calculate_dynamic_points(65, player_count, first_place_value)

      assert result < 0.001
    end
  end

  describe "calculate_points/3" do
    test "returns correct structure with all fields" do
      result = TgpCalculator.calculate_points(1, 19, 13.5)

      assert Map.has_key?(result, :tgp)
      assert Map.has_key?(result, :first_place_value)
      assert Map.has_key?(result, :linear_points)
      assert Map.has_key?(result, :dynamic_points)
      assert Map.has_key?(result, :total_points)
      assert Map.has_key?(result, :weight)
    end

    test "total_points equals linear + dynamic" do
      result = TgpCalculator.calculate_points(5, 19, 13.5)

      assert_in_delta result.total_points, result.linear_points + result.dynamic_points, 0.0001
    end

    test "1st place weight is 100%" do
      result = TgpCalculator.calculate_points(1, 19, 13.5)

      assert_in_delta result.weight, 1.0, 0.0001
    end

    test "later positions have lower weight" do
      first = TgpCalculator.calculate_points(1, 19, 13.5)
      second = TgpCalculator.calculate_points(2, 19, 13.5)
      last = TgpCalculator.calculate_points(19, 19, 13.5)

      assert first.weight > second.weight
      assert second.weight > last.weight
      assert last.weight > 0
    end
  end

  describe "calculate_all_points/2" do
    test "returns list with correct number of entries" do
      result = TgpCalculator.calculate_all_points(19, 13.5)

      assert length(result) == 19
    end

    test "positions are in order" do
      result = TgpCalculator.calculate_all_points(19, 13.5)

      positions = Enum.map(result, & &1.position)
      assert positions == Enum.to_list(1..19)
    end

    test "matches 19-player Excel template values" do
      # Values verified against "2026 Tournament Submission Template.xlsx"
      result = TgpCalculator.calculate_all_points(19, 13.5)

      # Position 1: linear=1.026, dynamic=9.234, total=10.26, weight=100%
      first = Enum.find(result, &(&1.position == 1))
      assert_in_delta first.linear_points, 1.026, 0.001
      assert_in_delta first.dynamic_points, 9.234, 0.001
      assert_in_delta first.total_points, 10.26, 0.001
      assert_in_delta first.weight, 1.0, 0.001

      # Position 2: linear=0.972, dynamic=4.608, total=5.58
      second = Enum.find(result, &(&1.position == 2))
      assert_in_delta second.linear_points, 0.972, 0.001
      assert_in_delta second.dynamic_points, 4.608, 0.001
      assert_in_delta second.total_points, 5.58, 0.001

      # Position 3: linear=0.918, dynamic=2.704, total=3.622
      third = Enum.find(result, &(&1.position == 3))
      assert_in_delta third.linear_points, 0.918, 0.001
      assert_in_delta third.dynamic_points, 2.704, 0.001
      assert_in_delta third.total_points, 3.622, 0.001

      # Position 19: linear=0.054, dynamic≈0.00, total≈0.054
      last = Enum.find(result, &(&1.position == 19))
      assert_in_delta last.linear_points, 0.054, 0.001
      assert_in_delta last.dynamic_points, 0.0, 0.001
      assert_in_delta last.total_points, 0.054, 0.001
      assert last.weight < 0.01
    end

    test "all entries have consistent tgp and first_place_value" do
      result = TgpCalculator.calculate_all_points(19, 13.5)

      tgp_values = result |> Enum.map(& &1.tgp) |> Enum.uniq()
      fpv_values = result |> Enum.map(& &1.first_place_value) |> Enum.uniq()

      assert length(tgp_values) == 1
      assert length(fpv_values) == 1
    end

    test "handles 0 meaningful games" do
      result = TgpCalculator.calculate_all_points(10, 0)

      # All points should be 0
      Enum.each(result, fn entry ->
        assert entry.tgp == 0.0
        assert entry.first_place_value == 0.0
        assert entry.total_points == 0.0
      end)
    end
  end
end
