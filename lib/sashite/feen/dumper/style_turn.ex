# lib/sashite/feen/dumper/style_turn.ex

defmodule Sashite.Feen.Dumper.StyleTurn do
  @moduledoc """
  Dumper (serializer) for the Style-Turn field of FEEN notation.

  Converts a style-turn structure back to its canonical FEEN string representation.

  ## Format

      <ACTIVE-STYLE>/<INACTIVE-STYLE>

  ## Examples

      iex> style_turn = %{active: %Sashite.Sin{style: :C, side: :first}, inactive: %Sashite.Sin{style: :C, side: :second}}
      iex> Sashite.Feen.Dumper.StyleTurn.dump(style_turn)
      "C/c"

      iex> style_turn = %{active: %Sashite.Sin{style: :S, side: :second}, inactive: %Sashite.Sin{style: :S, side: :first}}
      iex> Sashite.Feen.Dumper.StyleTurn.dump(style_turn)
      "s/S"

  """

  alias Sashite.Sin

  @doc """
  Dumps a style-turn structure to its canonical FEEN string.

  ## Parameters

  - `style_turn` - A map with `:active` and `:inactive` keys containing SIN structs

  ## Returns

  A canonical style-turn string.
  """
  @spec dump(map()) :: String.t()
  def dump(%{active: active, inactive: inactive}) do
    active_str = Sin.to_string(active)
    inactive_str = Sin.to_string(inactive)

    "#{active_str}/#{inactive_str}"
  end
end
