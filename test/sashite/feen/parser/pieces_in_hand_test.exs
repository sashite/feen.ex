defmodule Sashite.Feen.Parser.PiecesInHandTest do
  use ExUnit.Case, async: true

  alias Sashite.Feen.Parser.PiecesInHand
  alias Sashite.Epin
  alias Sashite.Pin

  # =============================================================================
  # Valid Inputs - Empty Hands
  # =============================================================================

  describe "parse/1 with empty hands" do
    test "both hands empty" do
      assert {:ok, %{first: [], second: []}} = PiecesInHand.parse("/")
    end

    test "first hand empty, second has pieces" do
      assert {:ok, %{first: [], second: second}} = PiecesInHand.parse("/p")
      assert length(second) == 1
      assert hd(second).pin.type == :P
      assert hd(second).pin.side == :second
    end

    test "first hand has pieces, second empty" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("P/")
      assert length(first) == 1
      assert hd(first).pin.type == :P
      assert hd(first).pin.side == :first
    end
  end

  # =============================================================================
  # Valid Inputs - Single Pieces
  # =============================================================================

  describe "parse/1 with single pieces" do
    test "single uppercase piece (first side)" do
      assert {:ok, %{first: [epin], second: []}} = PiecesInHand.parse("K/")
      assert epin.pin.type == :K
      assert epin.pin.side == :first
      assert epin.pin.state == :normal
      assert epin.pin.terminal == false
      assert epin.derived == false
    end

    test "single lowercase piece (second side)" do
      assert {:ok, %{first: [], second: [epin]}} = PiecesInHand.parse("/k")
      assert epin.pin.type == :K
      assert epin.pin.side == :second
      assert epin.pin.state == :normal
      assert epin.pin.terminal == false
      assert epin.derived == false
    end

    test "enhanced piece with + prefix" do
      assert {:ok, %{first: [epin], second: []}} = PiecesInHand.parse("+R/")
      assert epin.pin.type == :R
      assert epin.pin.state == :enhanced
    end

    test "diminished piece with - prefix" do
      assert {:ok, %{first: [epin], second: []}} = PiecesInHand.parse("-B/")
      assert epin.pin.type == :B
      assert epin.pin.state == :diminished
    end

    test "terminal piece with ^ suffix" do
      assert {:ok, %{first: [epin], second: []}} = PiecesInHand.parse("K^/")
      assert epin.pin.type == :K
      assert epin.pin.terminal == true
    end

    test "derived piece with ' suffix" do
      assert {:ok, %{first: [epin], second: []}} = PiecesInHand.parse("P'/")
      assert epin.pin.type == :P
      assert epin.derived == true
    end

    test "piece with all modifiers: enhanced, terminal, derived" do
      assert {:ok, %{first: [epin], second: []}} = PiecesInHand.parse("+K^'/")
      assert epin.pin.type == :K
      assert epin.pin.state == :enhanced
      assert epin.pin.terminal == true
      assert epin.derived == true
    end

    test "piece with diminished, terminal, derived" do
      assert {:ok, %{first: [epin], second: []}} = PiecesInHand.parse("-Q^'/")
      assert epin.pin.type == :Q
      assert epin.pin.state == :diminished
      assert epin.pin.terminal == true
      assert epin.derived == true
    end
  end

  # =============================================================================
  # Valid Inputs - Multiple Pieces Without Counts
  # =============================================================================

  describe "parse/1 with multiple pieces (no counts)" do
    test "multiple different pieces in first hand" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("PBN/")
      assert length(first) == 3

      types = Enum.map(first, & &1.pin.type)
      assert types == [:P, :B, :N]
    end

    test "multiple different pieces in second hand" do
      assert {:ok, %{first: [], second: second}} = PiecesInHand.parse("/pbn")
      assert length(second) == 3

      types = Enum.map(second, & &1.pin.type)
      assert types == [:P, :B, :N]
    end

    test "pieces in both hands" do
      assert {:ok, %{first: first, second: second}} = PiecesInHand.parse("PR/pb")
      assert length(first) == 2
      assert length(second) == 2
    end

    test "mixed modifiers in same hand" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("P+R-BK^N'/")
      assert length(first) == 5

      [p, r, b, k, n] = first
      assert p.pin.type == :P and p.pin.state == :normal
      assert r.pin.type == :R and r.pin.state == :enhanced
      assert b.pin.type == :B and b.pin.state == :diminished
      assert k.pin.type == :K and k.pin.terminal == true
      assert n.pin.type == :N and n.derived == true
    end
  end

  # =============================================================================
  # Valid Inputs - Pieces With Multiplicity Counts
  # =============================================================================

  describe "parse/1 with multiplicity counts" do
    test "count of 2" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("2P/")
      assert length(first) == 2
      assert Enum.all?(first, &(&1.pin.type == :P))
    end

    test "count of 9" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("9P/")
      assert length(first) == 9
    end

    test "count of 10 (multi-digit)" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("10P/")
      assert length(first) == 10
    end

    test "count of 99 (multi-digit)" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("99N/")
      assert length(first) == 99
    end

    test "count of 100 (three digits)" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("100B/")
      assert length(first) == 100
    end

    test "multiple counted pieces" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("3P2B/")
      assert length(first) == 5

      pawns = Enum.filter(first, &(&1.pin.type == :P))
      bishops = Enum.filter(first, &(&1.pin.type == :B))
      assert length(pawns) == 3
      assert length(bishops) == 2
    end

    test "counted pieces mixed with single pieces" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("2PN3B/")
      assert length(first) == 6

      pawns = Enum.filter(first, &(&1.pin.type == :P))
      knights = Enum.filter(first, &(&1.pin.type == :N))
      bishops = Enum.filter(first, &(&1.pin.type == :B))
      assert length(pawns) == 2
      assert length(knights) == 1
      assert length(bishops) == 3
    end

    test "counted pieces in both hands" do
      assert {:ok, %{first: first, second: second}} = PiecesInHand.parse("2P/3p")
      assert length(first) == 2
      assert length(second) == 3
    end

    test "count with enhanced piece" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("2+R/")
      assert length(first) == 2
      assert Enum.all?(first, &(&1.pin.state == :enhanced))
    end

    test "count with diminished piece" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("3-B/")
      assert length(first) == 3
      assert Enum.all?(first, &(&1.pin.state == :diminished))
    end

    test "count with terminal piece" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("2K^/")
      assert length(first) == 2
      assert Enum.all?(first, &(&1.pin.terminal == true))
    end

    test "count with derived piece" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("2P'/")
      assert length(first) == 2
      assert Enum.all?(first, &(&1.derived == true))
    end

    test "count with fully modified piece" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("2+K^'/")
      assert length(first) == 2

      Enum.each(first, fn epin ->
        assert epin.pin.type == :K
        assert epin.pin.state == :enhanced
        assert epin.pin.terminal == true
        assert epin.derived == true
      end)
    end
  end

  # =============================================================================
  # Valid Inputs - All Letters
  # =============================================================================

  describe "parse/1 with various piece letters" do
    test "all uppercase letters A-Z" do
      letters = ?A..?Z |> Enum.map(&<<&1::utf8>>) |> Enum.join()
      input = "#{letters}/"

      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse(input)
      assert length(first) == 26

      types = Enum.map(first, &Atom.to_string(&1.pin.type))
      expected = ?A..?Z |> Enum.map(&<<&1::utf8>>)
      assert types == expected
    end

    test "all lowercase letters a-z" do
      letters = ?a..?z |> Enum.map(&<<&1::utf8>>) |> Enum.join()
      input = "/#{letters}"

      assert {:ok, %{first: [], second: second}} = PiecesInHand.parse(input)
      assert length(second) == 26
      assert Enum.all?(second, &(&1.pin.side == :second))
    end
  end

  # =============================================================================
  # Valid Inputs - Complex Realistic Scenarios
  # =============================================================================

  describe "parse/1 with realistic game scenarios" do
    test "shogi mid-game captures" do
      # First player captured: 2 pawns, 1 lance, 1 gold
      # Second player captured: 1 pawn, 1 silver
      assert {:ok, %{first: first, second: second}} = PiecesInHand.parse("2PLG/pS")
      assert length(first) == 4
      assert length(second) == 2
    end

    test "chess position with captures" do
      assert {:ok, %{first: first, second: second}} = PiecesInHand.parse("2P/p")
      assert length(first) == 2
      assert length(second) == 1
    end

    test "complex cross-style game" do
      # Mix of native and derived pieces
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("2P3P'B/")
      assert length(first) == 6

      native_pawns = Enum.filter(first, &(&1.pin.type == :P and not &1.derived))
      derived_pawns = Enum.filter(first, &(&1.pin.type == :P and &1.derived))
      bishops = Enum.filter(first, &(&1.pin.type == :B))

      assert length(native_pawns) == 2
      assert length(derived_pawns) == 3
      assert length(bishops) == 1
    end
  end

  # =============================================================================
  # Invalid Inputs - Delimiter Errors
  # =============================================================================

  describe "parse/1 with invalid delimiter" do
    test "missing delimiter" do
      assert {:error, msg} = PiecesInHand.parse("P")
      assert msg =~ "expected exactly one '/' delimiter"
    end

    test "multiple delimiters" do
      assert {:error, msg} = PiecesInHand.parse("P/B/N")
      assert msg =~ "expected exactly one '/' delimiter"
    end

    test "empty string" do
      assert {:error, msg} = PiecesInHand.parse("")
      assert msg =~ "expected exactly one '/' delimiter"
    end
  end

  # =============================================================================
  # Invalid Inputs - Count Errors
  # =============================================================================

  describe "parse/1 with invalid counts" do
    test "count of 0 is invalid" do
      assert {:error, msg} = PiecesInHand.parse("0P/")
      assert msg =~ "must not have leading zeros" or msg =~ "must be >= 2"
    end

    test "count of 1 is invalid (must be >= 2 when explicit)" do
      assert {:error, msg} = PiecesInHand.parse("1P/")
      assert msg =~ "must be >= 2"
    end

    test "leading zeros in count" do
      assert {:error, msg} = PiecesInHand.parse("02P/")
      assert msg =~ "leading zeros"
    end

    test "leading zeros with larger number" do
      assert {:error, msg} = PiecesInHand.parse("007P/")
      assert msg =~ "leading zeros"
    end
  end

  # =============================================================================
  # Invalid Inputs - Invalid EPIN Tokens
  # =============================================================================

  describe "parse/1 with invalid EPIN tokens" do
    test "digit as piece" do
      assert {:error, msg} = PiecesInHand.parse("P2/")
      # "P2" would be parsed as P then count 2, then missing piece
      # Actually this depends on implementation - let me check
      # P is valid, then 2 starts a count but has no following piece
      assert msg =~ "unexpected character" or msg =~ "invalid"
    end

    test "invalid character in hand" do
      assert {:error, msg} = PiecesInHand.parse("P@/")
      assert msg =~ "unexpected character"
    end

    test "space in hand" do
      assert {:error, msg} = PiecesInHand.parse("P B/")
      assert msg =~ "unexpected character"
    end

    test "wrong order: terminal before state modifier" do
      # ^+K is invalid EPIN
      assert {:error, msg} = PiecesInHand.parse("^K/")
      assert msg =~ "invalid" or msg =~ "unexpected"
    end

    test "wrong order: derivation before terminal" do
      # K'^ is invalid EPIN (derivation must be last)
      assert {:error, msg} = PiecesInHand.parse("K'^/")
      assert msg =~ "unexpected character"
    end

    test "double state modifier" do
      assert {:error, msg} = PiecesInHand.parse("++K/")
      assert msg =~ "invalid" or msg =~ "unexpected"
    end

    test "double terminal marker" do
      assert {:error, msg} = PiecesInHand.parse("K^^/")
      assert msg =~ "unexpected character"
    end

    test "double derivation marker" do
      assert {:error, msg} = PiecesInHand.parse("K''/")
      assert msg =~ "unexpected character"
    end

    test "non-ASCII character" do
      assert {:error, msg} = PiecesInHand.parse("Pé/")
      assert msg =~ "unexpected character" or msg =~ "invalid"
    end
  end

  # =============================================================================
  # Invalid Inputs - Second Hand Errors
  # =============================================================================

  describe "parse/1 with errors in second hand" do
    test "invalid count in second hand" do
      assert {:error, msg} = PiecesInHand.parse("/1p")
      assert msg =~ "must be >= 2"
    end

    test "leading zeros in second hand" do
      assert {:error, msg} = PiecesInHand.parse("/02p")
      assert msg =~ "leading zeros"
    end

    test "invalid token in second hand" do
      assert {:error, msg} = PiecesInHand.parse("/p@")
      assert msg =~ "unexpected character"
    end
  end

  # =============================================================================
  # Edge Cases
  # =============================================================================

  describe "parse/1 edge cases" do
    test "very long hand" do
      # 26 different uppercase pieces
      input = "ABCDEFGHIJKLMNOPQRSTUVWXYZ/"
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse(input)
      assert length(first) == 26
    end

    test "large count" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("999P/")
      assert length(first) == 999
    end

    test "same piece type with different modifiers" do
      # P, +P, -P, P^, P' are all different EPIN tokens
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("P+P-PP^P'/")
      assert length(first) == 5

      states = Enum.map(first, & &1.pin.state)
      assert :normal in states
      assert :enhanced in states
      assert :diminished in states
    end

    test "uppercase and lowercase same letter" do
      assert {:ok, %{first: first, second: second}} = PiecesInHand.parse("P/p")
      assert length(first) == 1
      assert length(second) == 1
      assert hd(first).pin.side == :first
      assert hd(second).pin.side == :second
    end
  end

  # =============================================================================
  # Return Type Validation
  # =============================================================================

  describe "parse/1 return type validation" do
    test "returns correct structure" do
      assert {:ok, result} = PiecesInHand.parse("2P/p")

      assert is_map(result)
      assert Map.has_key?(result, :first)
      assert Map.has_key?(result, :second)
      assert is_list(result.first)
      assert is_list(result.second)
    end

    test "pieces are EPIN structs" do
      assert {:ok, %{first: [epin | _], second: _}} = PiecesInHand.parse("P/")

      assert %Epin{} = epin
      assert %Pin{} = epin.pin
    end

    test "expanded pieces preserve attributes" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("3+R^'/")

      Enum.each(first, fn epin ->
        assert %Epin{} = epin
        assert epin.pin.type == :R
        assert epin.pin.side == :first
        assert epin.pin.state == :enhanced
        assert epin.pin.terminal == true
        assert epin.derived == true
      end)
    end
  end

  # =============================================================================
  # Consistency with FEEN Spec §8
  # =============================================================================

  describe "FEEN spec §8 compliance" do
    @tag :spec_compliance
    test "§8: delimiter is always present" do
      # Even when both hands empty, delimiter must be present
      assert {:ok, _} = PiecesInHand.parse("/")
      assert {:error, _} = PiecesInHand.parse("")
    end

    @tag :spec_compliance
    test "§8.1: count absent means multiplicity 1" do
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("P/")
      assert length(first) == 1
    end

    @tag :spec_compliance
    test "§8.1: count present must be >= 2" do
      assert {:error, _} = PiecesInHand.parse("1P/")
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("2P/")
      assert length(first) == 2
    end

    @tag :spec_compliance
    test "§8.1: count must not have leading zeros" do
      assert {:error, _} = PiecesInHand.parse("02P/")
      assert {:error, _} = PiecesInHand.parse("007P/")
    end

    @tag :spec_compliance
    test "§8.2: left-to-right parsing" do
      # "2PB" should be parsed as: count=2, piece=P, then piece=B
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("2PB/")
      assert length(first) == 3

      types = Enum.map(first, & &1.pin.type)
      # First two are P, last is B
      assert Enum.count(types, &(&1 == :P)) == 2
      assert Enum.count(types, &(&1 == :B)) == 1
    end

    @tag :spec_compliance
    test "§8.3: piece side is property of piece, not hand" do
      # Even pieces in first hand can have lowercase (second side)
      # This is valid per spec: the EPIN encodes the piece's side attribute
      assert {:ok, %{first: first, second: []}} = PiecesInHand.parse("p/")
      assert length(first) == 1
      assert hd(first).pin.side == :second
    end
  end
end
