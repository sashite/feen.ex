defmodule Sashite.Feen.Dumper.PiecesInHand do
  @moduledoc """
  Dumper (serializer) for the Hands field of FEEN notation.

  Converts a hands structure back to its canonical FEEN string representation
  with aggregated multiplicities and deterministic ordering.

  ## Canonical Form

  Hand items are aggregated and sorted deterministically:

  1. By multiplicity - descending (larger counts first)
  2. By EPIN base letter - case-insensitive alphabetical order
  3. By EPIN letter case - uppercase before lowercase (first before second)
  4. By EPIN state modifier - `-` before `+` before none
  5. By EPIN terminal marker - absent before present
  6. By EPIN derivation marker - absent before present
  """

  alias Sashite.Epin

  @doc """
  Dumps a hands structure to its canonical FEEN string.

  ## Parameters

  - `hands` - A map with `:first` and `:second` keys containing lists of EPIN structs

  ## Returns

  A canonical hands string.
  """
  @spec dump(map()) :: String.t()
  def dump(%{first: first, second: second}) do
    first_str = dump_hand(first)
    second_str = dump_hand(second)

    "#{first_str}/#{second_str}"
  end

  # ===========================================================================
  # Private - Hand Dumping
  # ===========================================================================

  defp dump_hand([]) do
    ""
  end

  defp dump_hand(pieces) do
    pieces
    |> aggregate_pieces()
    |> sort_canonical()
    |> Enum.map(&format_hand_item/1)
    |> Enum.join()
  end

  # ===========================================================================
  # Private - Aggregation
  # ===========================================================================

  defp aggregate_pieces(pieces) do
    pieces
    |> Enum.group_by(&Epin.to_string/1)
    |> Enum.map(fn {_epin_str, group} ->
      {List.first(group), length(group)}
    end)
  end

  # ===========================================================================
  # Private - Canonical Sorting
  # ===========================================================================

  defp sort_canonical(aggregated) do
    Enum.sort(aggregated, &compare_hand_items/2)
  end

  defp compare_hand_items({epin1, count1}, {epin2, count2}) do
    cond do
      # 1. By multiplicity - descending (larger counts first)
      count1 != count2 ->
        count1 > count2

      # 2-6. By EPIN attributes
      true ->
        compare_epins(epin1, epin2)
    end
  end

  defp compare_epins(epin1, epin2) do
    # 2. By EPIN base letter - case-insensitive alphabetical order
    letter1 = epin1.pin.type |> Atom.to_string() |> String.upcase()
    letter2 = epin2.pin.type |> Atom.to_string() |> String.upcase()

    cond do
      letter1 != letter2 ->
        letter1 < letter2

      # 3. By EPIN letter case - uppercase before lowercase (first before second)
      epin1.pin.side != epin2.pin.side ->
        epin1.pin.side == :first

      # 4. By EPIN state modifier - `-` before `+` before none
      epin1.pin.state != epin2.pin.state ->
        state_order(epin1.pin.state) < state_order(epin2.pin.state)

      # 5. By EPIN terminal marker - absent before present
      epin1.pin.terminal != epin2.pin.terminal ->
        !epin1.pin.terminal

      # 6. By EPIN derivation marker - absent before present
      epin1.derived != epin2.derived ->
        !epin1.derived

      # Equal - maintain stability
      true ->
        true
    end
  end

  defp state_order(:diminished), do: 0
  defp state_order(:enhanced), do: 1
  defp state_order(:normal), do: 2

  # ===========================================================================
  # Private - Formatting
  # ===========================================================================

  defp format_hand_item({epin, 1}) do
    Epin.to_string(epin)
  end

  defp format_hand_item({epin, count}) when count >= 2 do
    "#{count}#{Epin.to_string(epin)}"
  end
end
