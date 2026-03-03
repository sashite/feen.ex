defmodule Sashite.Feen do
  @moduledoc """
  FEEN (Field Expression Encoding Notation) implementation for Elixir.

  Provides serialization and deserialization of board game positions
  between FEEN strings and `Qi` objects.

  FEEN is a rule-agnostic, canonical position encoding for two-player,
  turn-based board games built on the Sashite Game Protocol. A FEEN
  string encodes exactly three fields: piece placement, hands, and
  style-turn.

  ## Parsing (FEEN String -> Qi)

      {:ok, position} = Sashite.Feen.parse("8/8/8/8/8/8/8/8 / C/c")
      position.shape  #=> [8, 8]
      position.turn   #=> :first

  ## Dumping (Qi -> FEEN String)

      Sashite.Feen.dump(position)  #=> "8/8/8/8/8/8/8/8 / C/c"

  ## Validation

      Sashite.Feen.valid?("8/8/8/8/8/8/8/8 / C/c")  #=> true
      Sashite.Feen.valid?("invalid")                  #=> false
  """

  alias Sashite.Feen.{Dumper, Limits, Parser}

  @doc """
  Parses a FEEN string into a `Qi` position.

  Returns `{:ok, %Qi{}}` on success or `{:error, reason}` on failure,
  where `reason` is an atom identifying the validation error.

  Pieces on the board are stored as EPIN token strings. Empty squares
  are `nil`. Hands are `%{String.t() => pos_integer()}` count maps.

  ## Examples

      iex> {:ok, pos} = Sashite.Feen.parse("k^7/8/8/8/8/8/8/7K^ / C/c")
      iex> pos.shape
      [8, 8]
      iex> elem(pos.board, 0)
      "k^"
      iex> pos.turn
      :first

      iex> Sashite.Feen.parse("invalid")
      {:error, :invalid_field_count}
  """
  @spec parse(String.t()) :: {:ok, Qi.t()} | {:error, atom()}
  def parse(input), do: Parser.parse(input)

  @doc """
  Parses a FEEN string into a `Qi` position.

  Returns the `%Qi{}` directly on success. Raises `ArgumentError`
  on failure with a descriptive message.

  ## Examples

      iex> pos = Sashite.Feen.parse!("1 / C/c")
      iex> pos.shape
      [1]
      iex> pos.turn
      :first
  """
  @spec parse!(String.t()) :: Qi.t()
  def parse!(input) do
    case Parser.parse(input) do
      {:ok, position} ->
        position

      {:error, reason} ->
        raise ArgumentError,
              "invalid FEEN string: #{reason} (input: #{inspect(input)})"
    end
  end

  @doc """
  Reports whether the given value is a valid FEEN string.

  Returns `true` if the input is a binary that can be parsed as a
  valid, canonical FEEN position. Returns `false` for any other input.

  Never raises. Uses an exception-free code path internally and never
  constructs a `Qi` on invalid input.

  ## Examples

      iex> Sashite.Feen.valid?("8/8/8/8/8/8/8/8 / C/c")
      true

      iex> Sashite.Feen.valid?("invalid")
      false

      iex> Sashite.Feen.valid?(nil)
      false
  """
  @spec valid?(term()) :: boolean()
  def valid?(input), do: Parser.valid?(input)

  @doc """
  Serializes a `Qi` position to a canonical FEEN string.

  Board pieces must be valid EPIN token strings. Style values must
  be valid SIN token strings. The output is always in canonical form.

  ## Examples

      iex> pos = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 / C/c")
      iex> Sashite.Feen.dump(pos)
      "8/8/8/8/8/8/8/8 / C/c"
  """
  @spec dump(Qi.t()) :: String.t()
  def dump(position), do: Dumper.dump(position)

  @doc """
  Returns the maximum allowed FEEN string length in bytes.

  Inputs exceeding this limit are rejected before any parsing begins.

  ## Examples

      iex> Sashite.Feen.max_string_length()
      4096
  """
  @spec max_string_length() :: pos_integer()
  def max_string_length, do: Limits.max_string_length()
end
