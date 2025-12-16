# Sashite.Feen

[![Hex.pm](https://img.shields.io/hexpm/v/sashite_feen.svg)](https://hex.pm/packages/sashite_feen)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/sashite_feen)
[![License](https://img.shields.io/hexpm/l/sashite_feen.svg)](https://github.com/sashite/feen.ex/blob/main/LICENSE.md)

> **FEEN** (Field Expression Encoding Notation) implementation for Elixir.

## What is FEEN?

FEEN (Field Expression Encoding Notation) is a **rule-agnostic position encoding** for two-player, turn-based board games built on the [Sashité Game Protocol](https://sashite.dev/game-protocol/).

A FEEN string encodes exactly:

1. **Board occupancy** (which Pieces are on which Squares)
2. **Hands** (multisets of off-board Pieces held by each Player)
3. **Side styles** and the **Active Player**

This library implements the [FEEN Specification v1.0.0](https://sashite.dev/specs/feen/1.0.0/).

## Installation

Add `sashite_feen` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sashite_feen, "~> 1.0"}
  ]
end
```

This will also install `sashite_epin` and `sashite_sin` as transitive dependencies.

## Quick Start

```elixir
# Parse a FEEN string (Western Chess starting position)
feen_string = "+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c"

{:ok, position} = Sashite.Feen.parse(feen_string)

# Access position components
position.piece_placement   # Board state
position.hands             # Captured pieces
position.style_turn        # Active player and styles

# Serialize back to FEEN string
Sashite.Feen.to_string(position)  # => "+rnbq+k^bn+r/..."

# Validate a FEEN string
Sashite.Feen.valid?(feen_string)  # => true
```

## Format Overview

A FEEN string consists of **three fields** separated by single ASCII spaces:

```
<PIECE-PLACEMENT> <HANDS> <STYLE-TURN>
```

### Example: Chess Starting Position

```
+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c
|----------------------------------------------------| |-| |---|
                   Piece Placement                    Hands Style-Turn
```

### Example: Shogi Starting Position

```
lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s
```

### Example: Position with Captured Pieces

```
r1bqk^b1r/+p+p+p+p1+p+p+p/2n2n2/4p3/2B1P3/5N2/+P+P+P+P1+P+P+P/RNBQK^2R 2P/p C/c
                                                              |--| |-|
                                                              First Second
                                                              hand  hand
```

## Usage

### Parsing FEEN Strings

```elixir
# Parse with error handling
case Sashite.Feen.parse(feen_string) do
  {:ok, position} -> # use position
  {:error, reason} -> # handle error
end

# Bang version (raises on invalid input)
position = Sashite.Feen.parse!(feen_string)

# Validate without parsing
Sashite.Feen.valid?(feen_string)  # => true/false
```

### Accessing Position Components

```elixir
position = Sashite.Feen.parse!("+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c")

# Piece Placement (board state)
position.piece_placement
# => %{squares: [[...], [...], ...], separators: [1, 1, 1, 1, 1, 1, 1]}

# Hands (captured pieces)
position.hands
# => %{first: [], second: []}

# Style-Turn (active player and styles)
position.style_turn
# => %{active: %Sashite.Sin{style: :C, side: :first}, inactive: %Sashite.Sin{style: :C, side: :second}}
```

### Working with Piece Placement

The `piece_placement` field contains:

- `squares` — List of segments, each segment is a list of squares (`nil` for empty, `%Sashite.Epin{}` for piece)
- `separators` — List of separator counts between consecutive segments

```elixir
position = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 / C/c")

# Access segments
position.piece_placement.squares
# => [[nil, nil, nil, nil, nil, nil, nil, nil], ...]

# Access separator structure (for multi-dimensional boards)
position.piece_placement.separators
# => [1, 1, 1, 1, 1, 1, 1]

# Iterate over a segment
Enum.each(hd(position.piece_placement.squares), fn
  nil -> IO.puts("Empty square")
  %Sashite.Epin{} = epin -> IO.puts("Piece: #{epin}")
end)
```

### Working with Hands

The `hands` field contains:

- `first` — List of `%Sashite.Epin{}` structs held by first player
- `second` — List of `%Sashite.Epin{}` structs held by second player

```elixir
position = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 2P/p C/c")

# Access first player's hand
position.hands.first
# => [%Sashite.Epin{...}, %Sashite.Epin{...}]

length(position.hands.first)  # => 2

# Access second player's hand
position.hands.second
# => [%Sashite.Epin{...}]
```

### Working with Style-Turn

The `style_turn` field contains:

- `active` — `%Sashite.Sin{}` of the active player (to move)
- `inactive` — `%Sashite.Sin{}` of the inactive player

```elixir
position = Sashite.Feen.parse!("8/8/8/8/8/8/8/8 / C/c")

# Get active player's style
position.style_turn.active
# => %Sashite.Sin{style: :C, side: :first}

# Get inactive player's style
position.style_turn.inactive
# => %Sashite.Sin{style: :C, side: :second}

# Check who is to move
Sashite.Sin.first_player?(position.style_turn.active)   # => true
Sashite.Sin.second_player?(position.style_turn.active)  # => false
```

### Serialization

```elixir
# Convert position back to FEEN string
feen_string = Sashite.Feen.to_string(position)

# String.Chars protocol is implemented
"Position: #{position}"

# The output is always canonical
```

## Field Specifications

### Field 1 — Piece Placement

Encodes board occupancy as a stream of tokens organized into segments separated by `/`:

- **Empty-count tokens**: integers representing runs of empty squares (e.g., `8` = 8 empty squares)
- **Piece tokens**: valid EPIN tokens (e.g., `+K^`, `p`, `R'`)

```elixir
# 8x8 board with pieces
"+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R"

# Multi-dimensional board (3D Raumschach uses //)
"+rn+k^n+r/+p+p+p+p+p/5/5/5//buqbu/+p+p+p+p+p/5/5/5//..."
```

### Field 2 — Hands

Encodes pieces held by each player, separated by `/`:

```
<FIRST-HAND>/<SECOND-HAND>
```

- Each hand is a concatenation of `[count]<piece>` items
- Count is optional (absent = 1, present ≥ 2)
- Empty hands are represented as empty strings

```elixir
"/"        # Both hands empty
"2P/p"     # First has 2 pawns, second has 1 pawn
"3P2B/2p"  # First has 3 pawns + 2 bishops, second has 2 pawns
```

### Field 3 — Style-Turn

Encodes native styles and active player:

```
<ACTIVE-STYLE>/<INACTIVE-STYLE>
```

- Each style is a valid SIN token (single ASCII letter)
- Uppercase = Side `first`, lowercase = Side `second`
- Position determines who is active

```elixir
"C/c"  # First player (Chess-style) to move
"c/C"  # Second player (Chess-style) to move
"S/s"  # First player (Shogi-style) to move
"M/c"  # First player (Makruk-style) vs second player (Chess-style), first to move
```

## Game Examples

### Western Chess

```elixir
# Starting position
"+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/c"

# After 1.e4
"+rnbq+k^bn+r/+p+p+p+p+p+p+p+p/8/8/4P3/8/+P+P+P+P1+P+P+P/+RNBQ+K^BN+R / c/C"

# After 1.e4 c5 (Sicilian Defense)
"+rnbq+k^bn+r/+p+p1+p+p+p+p+p/8/2p5/4P3/8/+P+P+P+P1+P+P+P/+RNBQ+K^BN+R / C/c"
```

### Japanese Shogi

```elixir
# Starting position
"lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s"

# After 1.P-7f
"lnsgk^gsnl/1r5b1/ppppppppp/9/9/2P6/PP1PPPPPP/1B5R1/LNSGK^GSNL / s/S"
```

### Chinese Xiangqi

```elixir
# Starting position
"rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x"
```

### Thai Makruk

```elixir
# Starting position
"rnsmk^snr/8/pppppppp/8/8/PPPPPPPP/8/RNSK^MSNR / M/m"
```

### Cross-Style Games

```elixir
# Chess vs Makruk hybrid
"rnsmk^snr/8/pppppppp/8/8/8/+P+P+P+P+P+P+P+P/+RNBQ+K^BN+R / C/m"
```

## API Reference

### Main Module

```elixir
# Parse FEEN string
Sashite.Feen.parse(feen_string)   # => {:ok, %Sashite.Feen{}} | {:error, reason}
Sashite.Feen.parse!(feen_string)  # => %Sashite.Feen{} | raises ArgumentError

# Validate string
Sashite.Feen.valid?(feen_string)  # => boolean

# Serialize position
Sashite.Feen.to_string(position)  # => String.t()
```

### Data Structure

```elixir
%Sashite.Feen{
  piece_placement: %{
    squares: [[Sashite.Epin.t() | nil]],  # List of segments
    separators: [pos_integer()]            # Separator counts between segments
  },
  hands: %{
    first: [Sashite.Epin.t()],   # First player's hand
    second: [Sashite.Epin.t()]   # Second player's hand
  },
  style_turn: %{
    active: Sashite.Sin.t(),     # Active player's style
    inactive: Sashite.Sin.t()    # Inactive player's style
  }
}
```

## Canonical Form

FEEN output is always **canonical**:

- Empty-count tokens use minimal base-10 integers (no leading zeros)
- Hand items are aggregated and sorted deterministically:
  1. By multiplicity (descending)
  2. By EPIN base letter (case-insensitive alphabetical)
  3. By EPIN letter case (uppercase before lowercase)
  4. By EPIN state modifier (`-` before `+` before none)
  5. By EPIN terminal marker (absent before present)
  6. By EPIN derivation marker (absent before present)

```elixir
# Non-canonical input is accepted and normalized on output
{:ok, pos} = Sashite.Feen.parse("8/8/8/8/8/8/8/8 PpP/p C/c")
Sashite.Feen.to_string(pos)
# => "8/8/8/8/8/8/8/8 2Pp/p C/c"
```

## Dependencies

FEEN builds on these Sashité specifications:

- **[EPIN](https://sashite.dev/specs/epin/1.0.0/)** — Extended Piece Identifier Notation for piece tokens
- **[SIN](https://sashite.dev/specs/sin/1.0.0/)** — Style Identifier Notation for style-turn encoding

## Design Properties

FEEN is designed to be:

- **Rule-agnostic** — No game-specific rules embedded
- **Protocol-aligned** — Compatible with the Game Protocol's Position model
- **Compact** — Run-length encoding for empty squares, multiplicities for hands
- **Multi-dimensional friendly** — Separator groups preserve higher-dimensional boundaries
- **Canonical** — Single canonical string for each position
- **Engine-friendly** — Suitable for hashing, caching, and repetition detection

## Related Specifications

- [FEEN Specification v1.0.0](https://sashite.dev/specs/feen/1.0.0/) — Technical specification
- [FEEN Examples](https://sashite.dev/specs/feen/1.0.0/examples/) — Comprehensive examples
- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [EPIN Specification](https://sashite.dev/specs/epin/1.0.0/) — Piece encoding
- [SIN Specification](https://sashite.dev/specs/sin/1.0.0/) — Style encoding

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).

## About

Maintained by [Sashité](https://sashite.com/) — promoting chess variants and sharing the beauty of board game cultures.
