defmodule Sashite.Feen.Parser.PiecePlacementTest do
  use ExUnit.Case, async: true

  alias Sashite.Feen.Parser.PiecePlacement
  alias Sashite.Epin

  # ===========================================================================
  # Helpers
  # ===========================================================================

  defp parse_ok!(string) do
    case PiecePlacement.parse(string) do
      {:ok, result} -> result
      {:error, reason} -> flunk("Expected parse to succeed, got error: #{inspect(reason)} for #{inspect(string)}")
    end
  end

  defp parse_error!(string) do
    case PiecePlacement.parse(string) do
      {:ok, result} -> flunk("Expected parse to fail, got success: #{inspect(result)} for #{inspect(string)}")
      {:error, reason} -> reason
    end
  end

  defp epin!(token) do
    case Epin.parse(token) do
      {:ok, epin} -> epin
      {:error, reason} -> flunk("EPIN token expected to be valid in this test: #{inspect(token)} (#{inspect(reason)})")
    end
  end

  defp empties(n), do: List.duplicate(nil, n)

  # ===========================================================================
  # Conformance: segments and slash groups
  # (FEEN Field 1: must not start/end with '/', segments separated by 1+ '/'.
  #  Slash multiplicity must be preserved.)
  # ===========================================================================

  describe "segments and slash groups" do
    test "single segment => separators is empty" do
      assert %{squares: [segment], separators: []} = parse_ok!("8")
      assert segment == empties(8)
    end

    test "n segments => n-1 separator groups" do
      for n <- 1..10 do
        input = Enum.join(List.duplicate("1", n), "/")
        %{squares: squares, separators: seps} = parse_ok!(input)

        assert length(squares) == n
        assert length(seps) == max(n - 1, 0)
        assert Enum.all?(seps, &is_integer/1)
        assert Enum.all?(seps, &(&1 >= 1))
      end
    end

    test "preserves slash group multiplicity exactly" do
      # 4 segments, 3 separator groups: "/" then "//" then "/"
      %{squares: squares, separators: seps} = parse_ok!("8/8//8/8")
      assert length(squares) == 4
      assert seps == [1, 2, 1]
    end

    test "supports arbitrary slash group sizes" do
      %{squares: squares, separators: seps} = parse_ok!("1/1//1///1////1")
      assert length(squares) == 5
      assert seps == [1, 2, 3, 4]
    end
  end

  # ===========================================================================
  # Conformance: empty-count tokens
  # (Must be base-10 integer >= 1, no leading zeros.
  #  Scanning rule: if next char is digit, read MAXIMAL digit run.)
  # ===========================================================================

  describe "empty-count tokens" do
    test "parses a single empty-count token" do
      assert %{squares: [segment], separators: []} = parse_ok!("1")
      assert segment == [nil]
    end

    test "reads maximal digit run (12 => twelve empties, not 1 then 2)" do
      assert %{squares: [segment]} = parse_ok!("12")
      assert segment == empties(12)
    end

    test "allows zeros inside the number (10 is valid) but not as leading zero" do
      assert %{squares: [segment]} = parse_ok!("10")
      assert segment == empties(10)

      reason = parse_error!("01")
      assert reason =~ "leading zeros"
    end

    test "rejects 0 (must be >= 1)" do
      reason = parse_error!("0")
      assert reason =~ ">= 1"
    end

    test "rejects empty-count with leading zeros (e.g. 08)" do
      reason = parse_error!("08")
      assert reason =~ "leading zeros"
    end
  end

  # ===========================================================================
  # Conformance: EPIN piece tokens
  # (Non-digit => read MAXIMAL substring that forms a valid EPIN token.)
  # ===========================================================================

  describe "piece tokens (EPIN)" do
    test "parses a single EPIN token" do
      k = epin!("K")
      assert %{squares: [[^k]], separators: []} = parse_ok!("K")
    end

    test "parses EPIN tokens with modifier / terminal / derivation markers" do
      tokens = ["K", "k", "+R", "-r", "K^", "k^", "K'", "k'", "+K^'", "-k^'"]

      for token <- tokens do
        piece = epin!(token)
        assert %{squares: [[^piece]], separators: []} = parse_ok!(token)
      end
    end

    test "reads maximal EPIN token when followed by another token (K^'Q => [K^', Q])" do
      k = epin!("K^'")
      q = epin!("Q")

      assert %{squares: [[^k, ^q]], separators: []} = parse_ok!("K^'Q")
    end

    test "accepts all ASCII letters as EPIN base (A-Z and a-z)" do
      # EPIN regex allows [A-Za-z] as the base letter. :contentReference[oaicite:1]{index=1}
      for codepoint <- ?A..?Z do
        token = <<codepoint>>
        piece = epin!(token)
        assert %{squares: [[^piece]]} = parse_ok!(token)
      end

      for codepoint <- ?a..?z do
        token = <<codepoint>>
        piece = epin!(token)
        assert %{squares: [[^piece]]} = parse_ok!(token)
      end
    end
  end

  # ===========================================================================
  # Conformance: mixed scanning (digits vs EPIN), left-to-right
  # ===========================================================================

  describe "mixed tokens and left-to-right scanning" do
    test "digit-run then piece then digit-run" do
      k = epin!("K")
      assert %{squares: [segment]} = parse_ok!("3K10")
      assert segment == empties(3) ++ [k] ++ empties(10)
    end

    test "piece then digit-run then piece" do
      r = epin!("R")
      k = epin!("k")
      assert %{squares: [segment]} = parse_ok!("R2k")
      assert segment == [r] ++ empties(2) ++ [k]
    end

    test "digits are never part of EPIN token (1a => [nil, a])" do
      a = epin!("a")
      assert %{squares: [segment]} = parse_ok!("1a")
      assert segment == [nil, a]
    end
  end

  # ===========================================================================
  # Examples: multi-segment positions (field 1 only)
  # (No semantic board-size validation here; FEEN leaves that to context.)
  # ===========================================================================

  describe "multi-segment examples" do
    test "parses chess-like ranks" do
      input = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR"
      %{squares: squares, separators: seps} = parse_ok!(input)

      assert length(squares) == 8
      assert seps == [1, 1, 1, 1, 1, 1, 1]
      assert Enum.all?(Enum.at(squares, 2), &is_nil/1) # "8"
    end

    test "parses an irregular shape (still syntactically valid field 1)" do
      input = "rkr/pp/PPPP"
      %{squares: [s1, s2, s3], separators: [1, 1]} = parse_ok!(input)

      assert length(s1) == 3
      assert length(s2) == 2
      assert length(s3) == 4
    end

    test "parses multi-dimensional separators (// treated as a distinct group)" do
      input = "8/8//8/8"
      %{squares: squares, separators: seps} = parse_ok!(input)

      assert length(squares) == 4
      assert seps == [1, 2, 1]
    end
  end

  # ===========================================================================
  # Invalid inputs: structural (slashes / emptiness)
  # ===========================================================================

  describe "invalid structural cases" do
    test "rejects leading slash" do
      reason = parse_error!("/8/8")
      assert reason =~ "must not start with /"
    end

    test "rejects trailing slash" do
      reason = parse_error!("8/8/")
      assert reason =~ "must not end with /"
    end

    test "rejects only slashes" do
      reason = parse_error!("///")
      assert reason =~ "must not start with /"
    end

    test "rejects empty string (must contain at least one segment and tokens)" do
      # Field 1 grammar: piece_placement ::= segment (slash_group segment)* ; segment ::= placement_token+
      # So the empty string is invalid. :contentReference[oaicite:2]{index=2}
      _reason = parse_error!("")
    end
  end

  # ===========================================================================
  # Invalid inputs: token-level (empty-count / EPIN / characters)
  # ===========================================================================

  describe "invalid token cases" do
    test "rejects zero empty-count inside a segment" do
      reason = parse_error!("K0K")
      assert reason =~ ">= 1"
    end

    test "rejects leading zeros inside a segment" do
      reason = parse_error!("K01K")
      assert reason =~ "leading zeros"
    end

    test "rejects invalid EPIN constructions (examples)" do
      # Modifier must be prefix, terminal must be suffix, derivation marker must be last (EPIN).
      # EPIN token format: ^[+-]?[A-Za-z]\^?'?$ :contentReference[oaicite:3]{index=3}
      for input <- ["K+", "++K", "^K", "K''", "K'^", "+^K", "--k"] do
        _reason = parse_error!(input)
      end
    end

    test "rejects unexpected characters" do
      for input <- ["8/8/@",
                    "8/8/8/8/8/8/8/ ",
                    "8/8\t/8",
                    "K#Q",
                    "K\nQ",
                    "é"] do
        reason = parse_error!(input)
        assert reason =~ "unexpected character"
      end
    end
  end
end
