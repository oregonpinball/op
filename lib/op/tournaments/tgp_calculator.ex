defmodule OP.Tournaments.TgpCalculator do
  @moduledoc """
  Authoritative module for TGP (Tournament Grading Percentage) scoring calculations.

  This module implements the IFPA-style point calculation system used by Oregon Pinball.
  All formulas are based on the TGP_SCORING_GUIDE.md documentation.
  """

  # Constants from TGP_SCORING_GUIDE.md
  @tgp_rate 0.04
  @tgp_cap 2.0
  @linear_weight 0.1
  @dynamic_weight 0.9
  @position_exponent 0.7
  @cubic_exponent 3
  @divisor_cap 64

  @doc """
  Calculate TGP percentage from meaningful games.

  TGP increases by 4% per meaningful game, capping at 200% (2.0).

  ## Examples

      iex> TgpCalculator.calculate_tgp(13.5)
      0.54

      iex> TgpCalculator.calculate_tgp(50)
      2.0

      iex> TgpCalculator.calculate_tgp(0)
      0.0
  """
  @spec calculate_tgp(number()) :: float()
  def calculate_tgp(meaningful_games) when is_number(meaningful_games) do
    min(meaningful_games * @tgp_rate, @tgp_cap)
  end

  @doc """
  Calculate first place value from player count and TGP.

  First place value is simply player_count * TGP.

  ## Examples

      iex> TgpCalculator.calculate_first_place_value(19, 0.54)
      10.26
  """
  @spec calculate_first_place_value(pos_integer(), float()) :: float()
  def calculate_first_place_value(player_count, tgp)
      when is_integer(player_count) and player_count > 0 and is_float(tgp) do
    player_count * tgp
  end

  @doc """
  Calculate linear points for a position.

  Linear points provide an even distribution where each position gets slightly
  less than the one above. This component makes up 10% of the total point pool.

  Formula: (player_count + 1 - position) * 0.1 * (first_place_value / player_count)

  ## Examples

      iex> TgpCalculator.calculate_linear_points(1, 19, 10.26)
      1.026
  """
  @spec calculate_linear_points(pos_integer(), pos_integer(), float()) :: float()
  def calculate_linear_points(position, player_count, first_place_value)
      when is_integer(position) and position > 0 and
             is_integer(player_count) and player_count > 0 and
             is_number(first_place_value) do
    (player_count + 1 - position) * @linear_weight * (first_place_value / player_count)
  end

  @doc """
  Calculate dynamic points for a position.

  Dynamic points use an exponential curve that heavily rewards top finishes.
  This component makes up 90% of the total point pool.

  Formula: max(((1 - ((position - 1) / min(player_count/2, 64))^0.7)^3) * 0.9 * first_place_value, 0)

  ## Examples

      iex> TgpCalculator.calculate_dynamic_points(1, 19, 10.26)
      9.234

      iex> TgpCalculator.calculate_dynamic_points(19, 19, 10.26)
      0.0
  """
  @spec calculate_dynamic_points(pos_integer(), pos_integer(), float()) :: float()
  def calculate_dynamic_points(position, player_count, first_place_value)
      when is_integer(position) and position > 0 and
             is_integer(player_count) and player_count > 0 and
             is_number(first_place_value) do
    divisor = min(player_count / 2, @divisor_cap)
    position_ratio = (position - 1) / divisor

    inner = :math.pow(position_ratio, @position_exponent)
    inverted = 1 - inner
    cubed = :math.pow(inverted, @cubic_exponent)
    scaled = cubed * @dynamic_weight * first_place_value

    max(scaled, 0.0)
  end

  @doc """
  Calculate all point components for a single position.

  Returns a map with:
  - `:tgp` - TGP percentage (0.0 to 2.0)
  - `:first_place_value` - Base value for the tournament
  - `:linear_points` - Linear component of points
  - `:dynamic_points` - Dynamic component of points
  - `:total_points` - Sum of linear and dynamic
  - `:weight` - Percentage relative to 1st place (0.0 to 1.0)

  ## Examples

      iex> TgpCalculator.calculate_points(1, 19, 13.5)
      %{tgp: 0.54, first_place_value: 10.26, linear_points: 1.026, dynamic_points: 9.234, total_points: 10.26, weight: 1.0}
  """
  @spec calculate_points(pos_integer(), pos_integer(), number()) :: map()
  def calculate_points(position, player_count, meaningful_games)
      when is_integer(position) and position > 0 and
             is_integer(player_count) and player_count > 0 and
             is_number(meaningful_games) do
    tgp = calculate_tgp(meaningful_games)
    first_place_value = calculate_first_place_value(player_count, tgp)
    linear_points = calculate_linear_points(position, player_count, first_place_value)
    dynamic_points = calculate_dynamic_points(position, player_count, first_place_value)
    total_points = linear_points + dynamic_points

    # Calculate weight relative to 1st place
    first_place_total =
      if position == 1 do
        total_points
      else
        first_linear = calculate_linear_points(1, player_count, first_place_value)
        first_dynamic = calculate_dynamic_points(1, player_count, first_place_value)
        first_linear + first_dynamic
      end

    weight = if first_place_total > 0, do: total_points / first_place_total, else: 0.0

    %{
      tgp: tgp,
      first_place_value: first_place_value,
      linear_points: linear_points,
      dynamic_points: dynamic_points,
      total_points: total_points,
      weight: weight
    }
  end

  @doc """
  Calculate points for all positions in a tournament.

  Returns a list of maps (one per position, 1 to player_count) with all point components.

  ## Examples

      iex> TgpCalculator.calculate_all_points(19, 13.5)
      [%{position: 1, ...}, %{position: 2, ...}, ...]
  """
  @spec calculate_all_points(pos_integer(), number()) :: [map()]
  def calculate_all_points(player_count, meaningful_games)
      when is_integer(player_count) and player_count > 0 and is_number(meaningful_games) do
    tgp = calculate_tgp(meaningful_games)
    first_place_value = calculate_first_place_value(player_count, tgp)

    # Pre-calculate first place total for weight calculation
    first_linear = calculate_linear_points(1, player_count, first_place_value)
    first_dynamic = calculate_dynamic_points(1, player_count, first_place_value)
    first_place_total = first_linear + first_dynamic

    Enum.map(1..player_count, fn position ->
      linear_points = calculate_linear_points(position, player_count, first_place_value)
      dynamic_points = calculate_dynamic_points(position, player_count, first_place_value)
      total_points = linear_points + dynamic_points
      weight = if first_place_total > 0, do: total_points / first_place_total, else: 0.0

      %{
        position: position,
        tgp: tgp,
        first_place_value: first_place_value,
        linear_points: linear_points,
        dynamic_points: dynamic_points,
        total_points: total_points,
        weight: weight
      }
    end)
  end
end
