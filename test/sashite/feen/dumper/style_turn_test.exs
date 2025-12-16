# test/sashite/feen/dumper/style_turn_test.exs

defmodule Sashite.Feen.Dumper.StyleTurnTest do
  use ExUnit.Case, async: true

  alias Sashite.Feen.Dumper.StyleTurn
  alias Sashite.Sin

  # ===========================================================================
  # Helper functions
  # ===========================================================================

  defp sin!(string) do
    Sin.parse!(string)
  end

  # ===========================================================================
  # dump/1 - First player active
  # ===========================================================================

  describe "dump/1 with first player active" do
    test "dumps chess style with first player active" do
      style_turn = %{active: sin!("C"), inactive: sin!("c")}

      assert StyleTurn.dump(style_turn) == "C/c"
    end

    test "dumps shogi style with first player active" do
      style_turn = %{active: sin!("S"), inactive: sin!("s")}

      assert StyleTurn.dump(style_turn) == "S/s"
    end

    test "dumps xiangqi style with first player active" do
      style_turn = %{active: sin!("X"), inactive: sin!("x")}

      assert StyleTurn.dump(style_turn) == "X/x"
    end

    test "dumps makruk style with first player active" do
      style_turn = %{active: sin!("M"), inactive: sin!("m")}

      assert StyleTurn.dump(style_turn) == "M/m"
    end

    test "dumps arbitrary style with first player active" do
      style_turn = %{active: sin!("G"), inactive: sin!("g")}

      assert StyleTurn.dump(style_turn) == "G/g"
    end
  end

  # ===========================================================================
  # dump/1 - Second player active
  # ===========================================================================

  describe "dump/1 with second player active" do
    test "dumps chess style with second player active" do
      style_turn = %{active: sin!("c"), inactive: sin!("C")}

      assert StyleTurn.dump(style_turn) == "c/C"
    end

    test "dumps shogi style with second player active" do
      style_turn = %{active: sin!("s"), inactive: sin!("S")}

      assert StyleTurn.dump(style_turn) == "s/S"
    end

    test "dumps xiangqi style with second player active" do
      style_turn = %{active: sin!("x"), inactive: sin!("X")}

      assert StyleTurn.dump(style_turn) == "x/X"
    end

    test "dumps makruk style with second player active" do
      style_turn = %{active: sin!("m"), inactive: sin!("M")}

      assert StyleTurn.dump(style_turn) == "m/M"
    end

    test "dumps arbitrary style with second player active" do
      style_turn = %{active: sin!("g"), inactive: sin!("G")}

      assert StyleTurn.dump(style_turn) == "g/G"
    end
  end

  # ===========================================================================
  # dump/1 - Cross-style games
  # ===========================================================================

  describe "dump/1 with cross-style games" do
    test "dumps chess vs makruk with first player active" do
      style_turn = %{active: sin!("C"), inactive: sin!("m")}

      assert StyleTurn.dump(style_turn) == "C/m"
    end

    test "dumps chess vs makruk with second player active" do
      style_turn = %{active: sin!("m"), inactive: sin!("C")}

      assert StyleTurn.dump(style_turn) == "m/C"
    end

    test "dumps shogi vs xiangqi with first player active" do
      style_turn = %{active: sin!("S"), inactive: sin!("x")}

      assert StyleTurn.dump(style_turn) == "S/x"
    end

    test "dumps shogi vs xiangqi with second player active" do
      style_turn = %{active: sin!("x"), inactive: sin!("S")}

      assert StyleTurn.dump(style_turn) == "x/S"
    end

    test "dumps chess vs shogi with first player active" do
      style_turn = %{active: sin!("C"), inactive: sin!("s")}

      assert StyleTurn.dump(style_turn) == "C/s"
    end

    test "dumps arbitrary cross-style combination" do
      style_turn = %{active: sin!("A"), inactive: sin!("z")}

      assert StyleTurn.dump(style_turn) == "A/z"
    end
  end

  # ===========================================================================
  # dump/1 - All letters
  # ===========================================================================

  describe "dump/1 with various letters" do
    test "dumps style A" do
      style_turn = %{active: sin!("A"), inactive: sin!("a")}

      assert StyleTurn.dump(style_turn) == "A/a"
    end

    test "dumps style Z" do
      style_turn = %{active: sin!("Z"), inactive: sin!("z")}

      assert StyleTurn.dump(style_turn) == "Z/z"
    end

    test "dumps all uppercase letters as active" do
      for letter <- ?A..?Z do
        upper = <<letter>>
        lower = String.downcase(upper)
        style_turn = %{active: sin!(upper), inactive: sin!(lower)}

        assert StyleTurn.dump(style_turn) == "#{upper}/#{lower}"
      end
    end

    test "dumps all lowercase letters as active" do
      for letter <- ?a..?z do
        lower = <<letter>>
        upper = String.upcase(lower)
        style_turn = %{active: sin!(lower), inactive: sin!(upper)}

        assert StyleTurn.dump(style_turn) == "#{lower}/#{upper}"
      end
    end
  end

  # ===========================================================================
  # Round-trip tests
  # ===========================================================================

  describe "round-trip with parser" do
    alias Sashite.Feen.Parser.StyleTurn, as: Parser

    test "round-trips chess style with first player active" do
      original = "C/c"
      {:ok, parsed} = Parser.parse(original)

      assert StyleTurn.dump(parsed) == original
    end

    test "round-trips chess style with second player active" do
      original = "c/C"
      {:ok, parsed} = Parser.parse(original)

      assert StyleTurn.dump(parsed) == original
    end

    test "round-trips shogi style" do
      original = "S/s"
      {:ok, parsed} = Parser.parse(original)

      assert StyleTurn.dump(parsed) == original
    end

    test "round-trips xiangqi style" do
      original = "X/x"
      {:ok, parsed} = Parser.parse(original)

      assert StyleTurn.dump(parsed) == original
    end

    test "round-trips makruk style" do
      original = "M/m"
      {:ok, parsed} = Parser.parse(original)

      assert StyleTurn.dump(parsed) == original
    end

    test "round-trips cross-style chess vs makruk" do
      original = "C/m"
      {:ok, parsed} = Parser.parse(original)

      assert StyleTurn.dump(parsed) == original
    end

    test "round-trips cross-style with second player active" do
      original = "s/C"
      {:ok, parsed} = Parser.parse(original)

      assert StyleTurn.dump(parsed) == original
    end

    test "round-trips all same-style combinations" do
      for letter <- ?A..?Z do
        upper = <<letter>>
        lower = String.downcase(upper)

        # First player active
        original1 = "#{upper}/#{lower}"
        {:ok, parsed1} = Parser.parse(original1)
        assert StyleTurn.dump(parsed1) == original1

        # Second player active
        original2 = "#{lower}/#{upper}"
        {:ok, parsed2} = Parser.parse(original2)
        assert StyleTurn.dump(parsed2) == original2
      end
    end
  end

  # ===========================================================================
  # Structure verification
  # ===========================================================================

  describe "dump/1 structure verification" do
    test "always produces format with single slash" do
      style_turn = %{active: sin!("C"), inactive: sin!("c")}
      result = StyleTurn.dump(style_turn)

      assert String.contains?(result, "/")
      assert length(String.split(result, "/")) == 2
    end

    test "active style is always first" do
      style_turn = %{active: sin!("C"), inactive: sin!("c")}
      result = StyleTurn.dump(style_turn)

      [active_str, _inactive_str] = String.split(result, "/")
      assert active_str == "C"
    end

    test "inactive style is always second" do
      style_turn = %{active: sin!("C"), inactive: sin!("c")}
      result = StyleTurn.dump(style_turn)

      [_active_str, inactive_str] = String.split(result, "/")
      assert inactive_str == "c"
    end

    test "output is exactly 3 characters for same-style games" do
      style_turn = %{active: sin!("C"), inactive: sin!("c")}
      result = StyleTurn.dump(style_turn)

      assert String.length(result) == 3
    end

    test "output is exactly 3 characters for cross-style games" do
      style_turn = %{active: sin!("C"), inactive: sin!("m")}
      result = StyleTurn.dump(style_turn)

      assert String.length(result) == 3
    end
  end
end
