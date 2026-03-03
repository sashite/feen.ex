# feen.ex

[![Hex.pm](https://img.shields.io/hexpm/v/sashite_feen.svg)](https://hex.pm/packages/sashite_feen)
[![Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/sashite_feen)
[![CI](https://github.com/sashite/feen.ex/actions/workflows/elixir.yml/badge.svg?branch=main)](https://github.com/sashite/feen.ex/actions)
[![License](https://img.shields.io/hexpm/l/sashite_feen.svg)](https://github.com/sashite/feen.ex/blob/main/LICENSE)

> **FEEN** (Field Expression Encoding Notation) implementation for Elixir.

## Overview

This library implements the [FEEN Specification v1.0.0](https://sashite.dev/specs/feen/1.0.0/), providing serialization and deserialization of board game positions between FEEN strings and [`Qi`](https://github.com/sashite/qi.ex) objects.

FEEN is a rule-agnostic, canonical position encoding for two-player, turn-based board games built on the [Sashité Game Protocol](https://sashite.dev/game-protocol/). A FEEN string encodes exactly three fields: **piece placement** (board structure and occupancy), **hands** (off-board pieces), and **style–turn** (player styles and active player).

### Implementation Constraints

| Constraint | Value | Rationale |
|------------|-------|-----------|
| Regular shapes only | Required | All ranks must have equal length within each dimension |
| Max string length | 4096 | Sufficient for realistic board positions |
| Max board dimensions | 3 | Sufficient for 1D, 2D, 3D boards |
| Max dimension size | 255 | Fits in 8-bit integer; covers 255×255×255 boards |

These constraints enable bounded memory usage and safe parsing.

Only regular board shapes are supported — every rank within a dimension must contain the same number of cells. For example, `9x10` and `8x8` boards are valid. Irregular structures where ranks have different sizes (e.g., ranks of 3, 2, and 4 cells) are not supported.

## Installation

```elixir
# In your mix.exs
def deps do
  [
    {:sashite_feen, "~> 2.0"}
  ]
end
```

## Dependencies

```elixir
{:qi, "~> 3.0"}            # Position model
{:sashite_epin, "~> 1.2"}  # Extended Piece Identifier Notation
{:sashite_sin, "~> 3.1"}   # Style Identifier Notation
```

## Usage

### Parsing (FEEN String → Qi)

Convert a FEEN string into a `Qi` object.

```elixir
# Parse a Shōgi starting position
{:ok, position} = Sashite.Feen.parse("lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s")

# The result is a Qi
position.shape
# => [9, 9]

position.board
# => {"l", "n", "s", "g", "k^", "g", "s", "n", "l",
#     nil, "r", nil, nil, nil, nil, nil, "b", nil,
#     "p", "p", "p", "p", "p", "p", "p", "p", "p",
#     nil, nil, nil, nil, nil, nil, nil, nil, nil,
#     nil, nil, nil, nil, nil, nil, nil, nil, nil,
#     nil, nil, nil, nil, nil, nil, nil, nil, nil,
#     "P", "P", "P", "P", "P", "P", "P", "P", "P",
#     nil, "B", nil, nil, nil, nil, nil, "R", nil,
#     "L", "N", "S", "G", "K^", "G", "S", "N", "L"}

Qi.to_nested(position)
# => [["l", "n", "s", "g", "k^", "g", "s", "n", "l"],
#     [nil, "r", nil, nil, nil, nil, nil, "b", nil],
#     ["p", "p", "p", "p", "p", "p", "p", "p", "p"],
#     [nil, nil, nil, nil, nil, nil, nil, nil, nil],
#     [nil, nil, nil, nil, nil, nil, nil, nil, nil],
#     [nil, nil, nil, nil, nil, nil, nil, nil, nil],
#     ["P", "P", "P", "P", "P", "P", "P", "P", "P"],
#     [nil, "B", nil, nil, nil, nil, nil, "R", nil],
#     ["L", "N", "S", "G", "K^", "G", "S", "N", "L"]]

position.first_player_hand   # => %{}
position.second_player_hand  # => %{}
position.first_player_style  # => "S"
position.second_player_style # => "s"
position.turn                # => :first

# Invalid input returns an error tuple
Sashite.Feen.parse("invalid")  # => {:error, :invalid_field_count}

# Bang version (raises on invalid input)
position = Sashite.Feen.parse!("lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s")
```

### Dumping (Qi → FEEN String)

Convert a `Qi` back to a canonical FEEN string.

```elixir
# From an existing Qi
{:ok, position} = Sashite.Feen.parse("8/8/8/8/8/8/8/8 / C/c")
Sashite.Feen.dump(position)
# => "8/8/8/8/8/8/8/8 / C/c"

# From a Qi built manually
position = Qi.new([1, 8], first_player_style: "C", second_player_style: "c")
  |> Qi.board_diff([{0, "K^"}, {7, "k^"}])
Sashite.Feen.dump(position)
# => "K^6k^ / C/c"
```

### Validation

```elixir
# Boolean check (never raises)
Sashite.Feen.valid?("lnsgk^gsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGK^GSNL / S/s")  # => true
Sashite.Feen.valid?("8/8/8/8/8/8/8/8 / C/c")  # => true (empty board)
Sashite.Feen.valid?("k^+p4+PK^ / C/c")        # => true (1D board)
Sashite.Feen.valid?("a/b//c/d / G/g")          # => true (3D board)
Sashite.Feen.valid?("rkr//PPPP / G/g")         # => false (dimensional coherence)
Sashite.Feen.valid?("invalid")                  # => false
Sashite.Feen.valid?(nil)                        # => false
```

### Round-trip Examples

FEEN parsing and dumping are perfect inverses — any valid FEEN string round-trips through `Qi` without loss.

```elixir
# Chess starting position
feen = "-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c"
{:ok, position} = Sashite.Feen.parse(feen)
Sashite.Feen.dump(position) == feen  # => true

# Xiangqi starting position
feen = "rheag^aehr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RHEAG^AEHR / X/x"
{:ok, position} = Sashite.Feen.parse(feen)
Sashite.Feen.dump(position) == feen  # => true
```

### Hands

Pieces in hand are represented as count maps (`%{String.t() => pos_integer()}`) in `Qi`. FEEN automatically handles aggregation (for serialization) and expansion (for parsing).

```elixir
# Shōgi mid-game with captured pieces
{:ok, position} = Sashite.Feen.parse("lnsgk^gsnl/1r5b1/pppp1pppp/9/9/9/PPPP1PPPP/1B5R1/LNSGK^GSNL P/p S/s")

position.first_player_hand   # => %{"P" => 1}
position.second_player_hand  # => %{"p" => 1}

# Multiple identical pieces are aggregated in FEEN
position = Qi.new([3, 3], first_player_style: "S", second_player_style: "s")
  |> Qi.board_diff([{4, "K^"}])
  |> Qi.first_player_hand_diff([{"P", 2}, {"B", 1}])
  |> Qi.second_player_hand_diff([{"p", 1}])
Sashite.Feen.dump(position)
# => "3/1K^1/3 2PB/p S/s"
```

### Multi-dimensional Boards

`Qi` supports 1D, 2D, and 3D boards natively.

```elixir
# 1D board
{:ok, position} = Sashite.Feen.parse("k^+p4+PK^ / C/c")
position.shape  # => [8]
position.board
# => {"k^", "+p", nil, nil, nil, nil, "+P", "K^"}

# 3D board (2 layers × 2 ranks × 2 files)
{:ok, position} = Sashite.Feen.parse("ab/cd//AB/CD / G/g")
position.shape  # => [2, 2, 2]
Qi.to_nested(position)
# => [[["a", "b"], ["c", "d"]],
#     [["A", "B"], ["C", "D"]]]
```

### Style–Turn Mapping

The FEEN style–turn field maps directly to `Qi`'s style and turn accessors.

```elixir
# First player to move (uppercase style is active)
{:ok, position} = Sashite.Feen.parse("8/8/8/8/8/8/8/8 / C/c")
position.first_player_style   # => "C"
position.second_player_style  # => "c"
position.turn                 # => :first

# Second player to move (lowercase style is active)
{:ok, position} = Sashite.Feen.parse("8/8/8/8/8/8/8/8 / c/C")
position.first_player_style   # => "C"
position.second_player_style  # => "c"
position.turn                 # => :second
```

## Format Overview

A FEEN string consists of **three fields** separated by single ASCII spaces:

```
<PIECE-PLACEMENT> <HANDS> <STYLE-TURN>
```

### Example: Chess Starting Position

```
-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c
|----------------------------------------------------| |-| |---|
                   Piece Placement                    Hands Style-Turn
```

### Field 1 — Piece Placement

Encodes board occupancy as a stream of tokens organized into segments separated by `/`:

- **Empty-count tokens**: integers representing runs of empty squares (e.g., `8` = 8 empty squares)
- **Piece tokens**: valid EPIN tokens (e.g., `+K^`, `p`, `R'`)

Multi-dimensional boards use separator groups: `//` for layers (3D).

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
"-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/c"

# After 1.e4
"-rnbqk^bn-r/+p+p+p+p+p+p+p+p/8/8/4P3/8/+P+P+P+P1+P+P+P/-RNBQK^BN-R / c/C"

# After 1.e4 c5 (Sicilian Defense)
"-rnbqk^bn-r/+p+p1+p+p+p+p+p/8/2p5/4P3/8/+P+P+P+P1+P+P+P/-RNBQK^BN-R / C/c"
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

### Cross-Style Games

```elixir
# Chess vs Makruk hybrid
"rnsmk^snr/8/pppppppp/8/8/8/+P+P+P+P+P+P+P+P/-RNBQK^BN-R / C/m"
```

## API Reference

### Module Methods

```elixir
# Parses a FEEN string into a Qi.
# Pieces on the board are EPIN token strings; empty squares are nil.
# Returns {:ok, %Qi{}} or {:error, reason}.
@spec Sashite.Feen.parse(String.t()) :: {:ok, Qi.t()} | {:error, atom()}

# Parses a FEEN string into a Qi.
# Raises ArgumentError if the string is not valid.
@spec Sashite.Feen.parse!(String.t()) :: Qi.t()

# Reports whether string is a valid FEEN position.
# Never raises; returns false for any invalid input.
# Uses an exception-free code path internally for performance.
@spec Sashite.Feen.valid?(term()) :: boolean()

# Serializes a Qi to a canonical FEEN string.
# Board pieces must be valid EPIN token strings.
# Style values must be valid SIN token strings.
@spec Sashite.Feen.dump(Qi.t()) :: String.t()
```

### Constants

```elixir
Sashite.Feen.max_string_length()  # => 4096
```

### Errors

Parsing errors are returned as atoms in `{:error, reason}` tuples:

| Atom | Cause |
|------|-------|
| `:not_a_string` | Input is not a binary |
| `:input_too_long` | String exceeds 4096 bytes |
| `:non_ascii_input` | Non-ASCII bytes detected |
| `:invalid_field_count` | Not exactly 3 space-separated fields |
| `:piece_placement_empty` | Field 1 is empty |
| `:piece_placement_starts_with_separator` | Field 1 starts with `/` |
| `:piece_placement_ends_with_separator` | Field 1 ends with `/` |
| `:empty_segment` | Empty segment between separators |
| `:invalid_empty_count` | Empty count is zero or has leading zeros |
| `:invalid_piece_token` | Token is not a valid EPIN identifier |
| `:board_not_regular` | Ranks have different sizes within a dimension |
| `:dimensional_coherence_violation` | Separator depth mismatch |
| `:exceeds_max_dimensions` | Board has more than 3 dimensions |
| `:dimension_size_exceeds_limit` | A dimension exceeds 255 squares |
| `:invalid_hands_delimiter` | Field 2 missing `/` or has multiple |
| `:invalid_hand_count` | Multiplicity is 0, 1, or has leading zeros |
| `:hand_items_not_aggregated` | Identical EPIN tokens not combined |
| `:hand_items_not_in_canonical_order` | Items violate ordering rules |
| `:invalid_style_turn_delimiter` | Field 3 missing `/` or has multiple |
| `:invalid_style_token` | Token is not a valid SIN identifier |
| `:style_tokens_same_case` | Both tokens same case |
| `:too_many_pieces` | Total pieces exceeds total squares |

The bang variant `parse!/1` raises `ArgumentError` with descriptive messages.

## Canonical Form

FEEN output is always **canonical**:

- Empty-count tokens use minimal base-10 integers (no leading zeros, consecutive empties merged)
- Hand items are aggregated and sorted deterministically:
  1. By multiplicity (descending)
  2. By EPIN base letter (case-insensitive alphabetical)
  3. By EPIN letter case (uppercase before lowercase)
  4. By EPIN state modifier (`-` before `+` before none)
  5. By EPIN terminal marker (absent before present)
  6. By EPIN derivation marker (absent before present)

```elixir
# Non-canonical input is rejected
Sashite.Feen.parse("8/8/8/8/8/8/8/8 PpP/p C/c")
# => {:error, :hand_items_not_aggregated}
```

## Security

This library is designed for backend use where inputs may come from untrusted clients. The implementation enforces **zero attack surface** through bounded resource consumption and defensive parsing.

### Bounded resource consumption

All inputs are rejected at the byte level before any allocation occurs:

- **Length check first**: Inputs longer than 4096 bytes are rejected with a single `byte_size/1` check before any parsing begins. This cap is sufficient for any realistic board position (a 255×255 board with all pieces would produce ~1500 bytes).
- **No regex engine**: All parsing uses raw binary pattern matching (`<<byte, rest::binary>>`), eliminating ReDoS as an attack vector.
- **No `String` module on the hot path**: Parsing operates on raw binaries. `String.trim/1`, `String.split/2`, `String.contains?/2`, and `String.at/2` are never called on untrusted input.
- **Bounded numeric parsing**: Empty-count and hand-count digit sequences are bounded by the maximum FEEN string length. Integer overflow is impossible.

### Atom table safety

The BEAM atom table is finite and not garbage-collected. This implementation **never calls `String.to_atom/1` at runtime**. Every atom in the output structs comes from compile-time literals in the EPIN and SIN dependencies. Untrusted input cannot introduce new atoms into the system.

### Rejection guarantees

Any input that is not a valid, canonical FEEN string is rejected with an `{:error, atom()}` tuple. The rejection path does not raise exceptions, does not allocate atoms, and does not allocate intermediate strings.

### Validation checklist

| FEEN spec requirement | Section | Status |
|-----------------------|---------|--------|
| Syntactic validation | §11.1 | ✓ Enforced |
| Canonicality validation | §11.2 | ✓ Enforced (empty-counts and hand ordering) |
| Dimensional coherence | §11.3 | ✓ Enforced |
| Cardinality constraints | §11.4 | ✓ Enforced (n ≥ 1, p ≤ n) |
| Robustness limits | §12 | ✓ Enforced (4096 bytes, 3 dimensions, 255 per axis) |

## Design Principles

- **Spec conformance**: Strict adherence to FEEN v1.0.0, including all MUST-level validation
- **Qi integration**: Parses to and dumps from `Qi`, the shared position model across Sashité libraries
- **Bounded input first**: `byte_size > 4096` is the first check; no code path processes unbounded input
- **Binary pattern matching on the hot path**: Parsing operates on `<<byte, rest::binary>>` destructuring — no `String` module, no regex
- **Zero dynamic atoms**: All atoms are compile-time literals via EPIN and SIN dependencies
- **Zero external parsing dependencies**: EPIN and SIN validation is inlined for performance; only `Qi` is required at runtime
- **Canonical output**: `dump/1` always produces canonical form
- **Elixir idioms**: `{:ok, _} | {:error, _}` tuples, `parse!` bang variant, `parse`/`dump` symmetry

### Performance Architecture

Parsing is internally split into two layers to avoid using exceptions for control flow:

- **Validation layer** — Each sub-parser (`PiecePlacement`, `PiecesInHand`, `StyleTurn`) performs all structural validation and data extraction without raising exceptions. This path operates on raw binaries in a single left-to-right pass, without allocating exception objects or capturing backtraces.
- **Public API layer** — `parse/1` calls the validation layer internally. On failure, it returns `{:error, atom()}`. `parse!/1` calls `parse/1` and raises `ArgumentError` exactly once, at the boundary. `valid?/1` calls `parse/1` and returns a boolean directly, never raising and never constructing a `Qi` object on invalid input.

This dual-path design eliminates the cost of exception-based control flow on the hot path. Since `valid?/1` is commonly called on untrusted or invalid input, avoiding `raise`/`rescue` per rejection keeps validation at pure function-call speed.

Serialization follows the same architecture: `dump/1` delegates to internal dumpers (`Dumper.PiecePlacement`, `Dumper.PiecesInHand`, `Dumper.StyleTurn`), each producing canonical output for one field.

## Related Specifications

- [Game Protocol](https://sashite.dev/game-protocol/) — Conceptual foundation
- [FEEN Specification](https://sashite.dev/specs/feen/1.0.0/) — Official specification
- [FEEN Examples](https://sashite.dev/specs/feen/1.0.0/examples/) — Usage examples
- [EPIN Specification](https://sashite.dev/specs/epin/1.0.0/) — Piece token format
- [SIN Specification](https://sashite.dev/specs/sin/1.0.0/) — Style token format

## License

Available as open source under the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).
