defmodule Sashite.Feen do
  @moduledoc """
  FEEN (Field Expression Encoding Notation) implementation for Elixir.

  FEEN is a **rule-agnostic position encoding** for two-player, turn-based
  board games built on the Sashite Game Protocol.

  A FEEN string encodes exactly:

  1. **Board occupancy** (which Pieces are on which Squares)
  2. **Hands** (multisets of off-board Pieces held by each Player)
  3. **Side styles** and the **Active Player**

  ## Format

  A FEEN string consists of three fields separated by single ASCII spaces:

      <PIECE-PLACEMENT> <HANDS> <STYLE-TURN>

  ## Examples

      iex> feen = "+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c"
      iex> {:ok, position} = Sashite.Feen.parse(feen)
      iex> position.style_turn.active.side
      :first

      iex> Sashite.Feen.valid?("lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s")
      true

      iex> Sashite.Feen.valid?("invalid")
      false

  See the [FEEN Specification](https://sashite.dev/specs/feen/1.0.0/) for details.
  """

  alias Sashite.Feen.Dumper
  alias Sashite.Feen.Parser

  @typedoc """
  A parsed FEEN position containing all three fields.
  """
  @type t :: %__MODULE__{
          piece_placement: piece_placement(),
          hands: hands(),
          style_turn: style_turn()
        }

  @typedoc """
  Piece placement data representing board occupancy.

  - `squares` - List of segments, each segment is a list of squares (nil for empty, EPIN for piece)
  - `separators` - List of separator counts between consecutive segments
  """
  @type piece_placement :: %{
          squares: [[Sashite.Epin.t() | nil]],
          separators: [pos_integer()]
        }

  @typedoc """
  Hands data representing pieces held by each player.

  - `first` - List of EPIN structs held by first player
  - `second` - List of EPIN structs held by second player
  """
  @type hands :: %{
          first: [Sashite.Epin.t()],
          second: [Sashite.Epin.t()]
        }

  @typedoc """
  Style-turn data representing native styles and active player.

  - `active` - SIN struct of the active player (to move)
  - `inactive` - SIN struct of the inactive player
  """
  @type style_turn :: %{
          active: Sashite.Sin.t(),
          inactive: Sashite.Sin.t()
        }

  @enforce_keys [:piece_placement, :hands, :style_turn]
  defstruct [:piece_placement, :hands, :style_turn]

  # ===========================================================================
  # Parsing
  # ===========================================================================

  @doc """
  Parses a FEEN string into a position struct.

  Returns `{:ok, position}` on success, `{:error, reason}` on failure.

  ## Examples

      iex> {:ok, position} = Sashite.Feen.parse("8/8/8/8/8/8/8/8 / C/c")
      iex> position.style_turn.active.side
      :first

      iex> {:ok, position} = Sashite.Feen.parse("lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s")
      iex> position.style_turn.active.style
      :S

      iex> Sashite.Feen.parse("invalid")
      {:error, "Invalid FEEN string: expected exactly 3 fields separated by spaces, got 1"}

  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, String.t()}
  def parse(feen_string) when is_binary(feen_string) do
    Parser.parse(feen_string)
  end

  def parse(feen_string) do
    {:error, "Invalid FEEN string: expected a string, got: #{inspect(feen_string)}"}
  end

  @doc """
  Parses a FEEN string into a position struct.

  Returns the position struct on success, raises `ArgumentError` on failure.

  ## Examples

      iex> position = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 / C/c")
      iex> position.style_turn.active.side
      :first

  """
  @spec parse!(String.t()) :: t()
  def parse!(feen_string) do
    case parse(feen_string) do
      {:ok, position} -> position
      {:error, reason} -> raise ArgumentError, reason
    end
  end

  @doc """
  Checks if a string is a valid FEEN notation.

  ## Examples

      iex> Sashite.Feen.valid?("8/8/8/8/8/8/8/8 / C/c")
      true

      iex> Sashite.Feen.valid?("lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s")
      true

      iex> Sashite.Feen.valid?("invalid")
      false

      iex> Sashite.Feen.valid?(123)
      false

  """
  @spec valid?(any()) :: boolean()
  def valid?(feen_string) when is_binary(feen_string) do
    case parse(feen_string) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  def valid?(_), do: false

  # ===========================================================================
  # Dumping (Serialization)
  # ===========================================================================

  @doc """
  Converts a position struct to its canonical FEEN string representation.

  ## Examples

      iex> {:ok, position} = Sashite.Feen.parse("8/8/8/8/8/8/8/8 / C/c")
      iex> Sashite.Feen.to_string(position)
      "8/8/8/8/8/8/8/8 / C/c"

  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = position) do
    Dumper.dump(position)
  end
end

defimpl String.Chars, for: Sashite.Feen do
  def to_string(position) do
    Sashite.Feen.to_string(position)
  end
end

defimpl Inspect, for: Sashite.Feen do
  def inspect(position, _opts) do
    "#Sashite.Feen<#{Sashite.Feen.to_string(position)}>"
  end
end
