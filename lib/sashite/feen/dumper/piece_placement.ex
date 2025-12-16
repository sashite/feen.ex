defmodule Sashite.Feen.Dumper.PiecePlacement do
  @moduledoc """
  Dumper (serializer) for the Piece Placement field of FEEN notation.

  Canonical rules:
  - Empty squares are run-length encoded as minimal base-10 integers (no leading zeros)
  - Consecutive empty squares are merged
  - Piece tokens are serialized using canonical EPIN strings
  - Separator multiplicity is preserved exactly

  This dumper expects a structurally valid representation:
  - `squares` must contain at least one segment
  - each segment must contain at least one square
  - `separators` length must be `length(squares) - 1`
  - each separator count must be a positive integer (>= 1)
  """

  alias Sashite.Epin

  @spec dump(%{squares: list(), separators: list()}) :: String.t()
  def dump(%{squares: segments, separators: separators})
      when is_list(segments) and is_list(separators) do
    validate_structure!(segments, separators)

    segments
    |> Enum.map(&dump_segment!/1)
    |> join_with_separators!(separators)
  end

  def dump(other) do
    raise ArgumentError,
          "Invalid piece placement: expected %{squares: list, separators: list}, got: #{inspect(other)}"
  end

  # ===========================================================================
  # Validation
  # ===========================================================================

  defp validate_structure!(segments, separators) do
    if segments == [] do
      raise ArgumentError, "Invalid piece placement: squares must contain at least one segment"
    end

    expected_seps = length(segments) - 1

    if length(separators) != expected_seps do
      raise ArgumentError,
            "Invalid piece placement: expected #{expected_seps} separators, got #{length(separators)}"
    end

    unless Enum.all?(separators, &(is_integer(&1) and &1 >= 1)) do
      raise ArgumentError, "Invalid piece placement: separators must be positive integers (>= 1)"
    end

    Enum.each(segments, fn segment ->
      if segment == [] do
        raise ArgumentError, "Invalid piece placement: segments must not be empty"
      end

      Enum.each(segment, fn
        nil -> :ok
        %Epin{} -> :ok
        other ->
          raise ArgumentError,
                "Invalid piece placement: segment contains invalid square value: #{inspect(other)}"
      end)
    end)
  end

  # ===========================================================================
  # Segment dumping
  # ===========================================================================

  defp dump_segment!(squares) do
    squares
    |> Enum.chunk_by(&is_nil/1)
    |> Enum.map(&chunk_to_token/1)
    |> Enum.join()
  end

  defp chunk_to_token([nil | _] = chunk), do: Integer.to_string(length(chunk))

  defp chunk_to_token(pieces) do
    pieces
    |> Enum.map(&Epin.to_string/1)
    |> Enum.join()
  end

  # ===========================================================================
  # Joining with separators (strict)
  # ===========================================================================

  defp join_with_separators!([first | rest], separators) do
    do_join(first, rest, separators)
  end

  defp do_join(acc, [], []), do: acc

  defp do_join(acc, [segment | segments], [sep | seps]) do
    do_join(acc <> String.duplicate("/", sep) <> segment, segments, seps)
  end

  defp do_join(_acc, _segments, _seps) do
    # Should be unreachable thanks to validate_structure!/2, but kept as a guardrail.
    raise ArgumentError, "Invalid piece placement: separators/segments mismatch"
  end
end
