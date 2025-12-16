defmodule Sashite.Feen.Parser.StyleTurnTest do
  use ExUnit.Case, async: true

  alias Sashite.Feen.Parser.StyleTurn
  alias Sashite.Sin

  # =============================================================================
  # Valid Inputs - Same Style Both Sides
  # =============================================================================

  describe "parse/1 with same style for both sides" do
    test "first player active (uppercase first) - Chess style" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("C/c")

      assert %Sin{} = active
      assert active.style == :C
      assert active.side == :first

      assert %Sin{} = inactive
      assert inactive.style == :C
      assert inactive.side == :second
    end

    test "second player active (lowercase first) - Chess style" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("c/C")

      assert active.style == :C
      assert active.side == :second

      assert inactive.style == :C
      assert inactive.side == :first
    end

    test "Shogi style - first player active" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("S/s")

      assert active.style == :S
      assert active.side == :first

      assert inactive.style == :S
      assert inactive.side == :second
    end

    test "Shogi style - second player active" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("s/S")

      assert active.style == :S
      assert active.side == :second

      assert inactive.style == :S
      assert inactive.side == :first
    end

    test "Xiangqi style - first player active" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("X/x")

      assert active.style == :X
      assert active.side == :first

      assert inactive.style == :X
      assert inactive.side == :second
    end

    test "Xiangqi style - second player active" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("x/X")

      assert active.style == :X
      assert active.side == :second

      assert inactive.style == :X
      assert inactive.side == :first
    end

    test "Makruk style - first player active" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("M/m")

      assert active.style == :M
      assert active.side == :first

      assert inactive.style == :M
      assert inactive.side == :second
    end

    test "Makruk style - second player active" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("m/M")

      assert active.style == :M
      assert active.side == :second

      assert inactive.style == :M
      assert inactive.side == :first
    end
  end

  # =============================================================================
  # Valid Inputs - Cross-Style Games
  # =============================================================================

  describe "parse/1 with different styles (cross-style games)" do
    test "Chess vs Makruk - first player (Chess) active" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("C/m")

      assert active.style == :C
      assert active.side == :first

      assert inactive.style == :M
      assert inactive.side == :second
    end

    test "Chess vs Makruk - second player (Makruk) active" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("m/C")

      assert active.style == :M
      assert active.side == :second

      assert inactive.style == :C
      assert inactive.side == :first
    end

    test "Shogi vs Xiangqi - first player (Shogi) active" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("S/x")

      assert active.style == :S
      assert active.side == :first

      assert inactive.style == :X
      assert inactive.side == :second
    end

    test "Shogi vs Xiangqi - second player (Xiangqi) active" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("x/S")

      assert active.style == :X
      assert active.side == :second

      assert inactive.style == :S
      assert inactive.side == :first
    end

    test "arbitrary styles A vs Z" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("A/z")

      assert active.style == :A
      assert active.side == :first

      assert inactive.style == :Z
      assert inactive.side == :second
    end

    test "arbitrary styles z vs A (second active)" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("z/A")

      assert active.style == :Z
      assert active.side == :second

      assert inactive.style == :A
      assert inactive.side == :first
    end
  end

  # =============================================================================
  # Valid Inputs - All Letters
  # =============================================================================

  describe "parse/1 with all possible letters" do
    test "all uppercase letters as active (first player)" do
      for letter <- ?A..?Z do
        upper = <<letter::utf8>>
        lower = <<(letter + 32)::utf8>>
        input = "#{upper}/#{lower}"

        assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse(input),
               "Failed for input: #{input}"

        assert active.side == :first
        assert inactive.side == :second
      end
    end

    test "all lowercase letters as active (second player)" do
      for letter <- ?a..?z do
        lower = <<letter::utf8>>
        upper = <<(letter - 32)::utf8>>
        input = "#{lower}/#{upper}"

        assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse(input),
               "Failed for input: #{input}"

        assert active.side == :second
        assert inactive.side == :first
      end
    end
  end

  # =============================================================================
  # Invalid Inputs - Delimiter Errors
  # =============================================================================

  describe "parse/1 with invalid delimiter" do
    test "missing delimiter" do
      assert {:error, msg} = StyleTurn.parse("Cc")
      assert msg =~ "expected exactly one '/' delimiter"
    end

    test "multiple delimiters" do
      assert {:error, msg} = StyleTurn.parse("C/c/S")
      assert msg =~ "expected exactly one '/' delimiter"
    end

    test "empty string" do
      assert {:error, msg} = StyleTurn.parse("")
      assert msg =~ "expected exactly one '/' delimiter"
    end

    test "only delimiter" do
      assert {:error, msg} = StyleTurn.parse("/")
      assert msg =~ "invalid" or msg =~ "style token"
    end

    test "delimiter with only active" do
      assert {:error, msg} = StyleTurn.parse("C/")
      assert msg =~ "invalid" or msg =~ "style token"
    end

    test "delimiter with only inactive" do
      assert {:error, msg} = StyleTurn.parse("/c")
      assert msg =~ "invalid" or msg =~ "style token"
    end
  end

  # =============================================================================
  # Invalid Inputs - Same Case (Violates §9.3)
  # =============================================================================

  describe "parse/1 with same case tokens (violates §9.3)" do
    test "both uppercase" do
      assert {:error, msg} = StyleTurn.parse("C/C")
      assert msg =~ "opposite case"
    end

    test "both lowercase" do
      assert {:error, msg} = StyleTurn.parse("c/c")
      assert msg =~ "opposite case"
    end

    test "both uppercase - different letters" do
      assert {:error, msg} = StyleTurn.parse("C/S")
      assert msg =~ "opposite case"
    end

    test "both lowercase - different letters" do
      assert {:error, msg} = StyleTurn.parse("c/s")
      assert msg =~ "opposite case"
    end

    test "both uppercase - A/Z" do
      assert {:error, msg} = StyleTurn.parse("A/Z")
      assert msg =~ "opposite case"
    end

    test "both lowercase - a/z" do
      assert {:error, msg} = StyleTurn.parse("a/z")
      assert msg =~ "opposite case"
    end
  end

  # =============================================================================
  # Invalid Inputs - Invalid SIN Tokens
  # =============================================================================

  describe "parse/1 with invalid SIN tokens" do
    test "digit as active style" do
      assert {:error, msg} = StyleTurn.parse("1/c")
      assert msg =~ "invalid" and msg =~ "active"
    end

    test "digit as inactive style" do
      assert {:error, msg} = StyleTurn.parse("C/1")
      assert msg =~ "invalid" and msg =~ "inactive"
    end

    test "multiple letters as active style" do
      assert {:error, msg} = StyleTurn.parse("CC/c")
      assert msg =~ "invalid" and msg =~ "active"
    end

    test "multiple letters as inactive style" do
      assert {:error, msg} = StyleTurn.parse("C/cc")
      assert msg =~ "invalid" and msg =~ "inactive"
    end

    test "special character as active style" do
      assert {:error, msg} = StyleTurn.parse("+/c")
      assert msg =~ "invalid" and msg =~ "active"
    end

    test "special character as inactive style" do
      assert {:error, msg} = StyleTurn.parse("C/+")
      assert msg =~ "invalid" and msg =~ "inactive"
    end

    test "space in active style" do
      assert {:error, msg} = StyleTurn.parse(" C/c")
      assert msg =~ "invalid"
    end

    test "space in inactive style" do
      assert {:error, msg} = StyleTurn.parse("C/ c")
      assert msg =~ "invalid"
    end

    test "non-ASCII character" do
      assert {:error, msg} = StyleTurn.parse("é/c")
      assert msg =~ "invalid"
    end

    test "empty active style" do
      assert {:error, msg} = StyleTurn.parse("/c")
      assert msg =~ "invalid" and msg =~ "active"
    end

    test "empty inactive style" do
      assert {:error, msg} = StyleTurn.parse("C/")
      assert msg =~ "invalid" and msg =~ "inactive"
    end

    test "PIN-like token (with modifier) as active" do
      assert {:error, msg} = StyleTurn.parse("+C/c")
      assert msg =~ "invalid"
    end

    test "PIN-like token (with terminal) as inactive" do
      assert {:error, msg} = StyleTurn.parse("C/c^")
      assert msg =~ "invalid"
    end

    test "EPIN-like token (with derivation) as active" do
      assert {:error, msg} = StyleTurn.parse("C'/c")
      assert msg =~ "invalid"
    end
  end

  # =============================================================================
  # Edge Cases
  # =============================================================================

  describe "parse/1 edge cases" do
    test "boundary letters A and a" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("A/a")
      assert active.style == :A
      assert inactive.style == :A
    end

    test "boundary letters Z and z" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("Z/z")
      assert active.style == :Z
      assert inactive.style == :Z
    end

    test "boundary letters a and A (second active)" do
      assert {:ok, %{active: active, inactive: _inactive}} = StyleTurn.parse("a/A")
      assert active.style == :A
      assert active.side == :second
    end

    test "boundary letters z and Z (second active)" do
      assert {:ok, %{active: active, inactive: _inactive}} = StyleTurn.parse("z/Z")
      assert active.style == :Z
      assert active.side == :second
    end
  end

  # =============================================================================
  # Return Type Validation
  # =============================================================================

  describe "parse/1 return type validation" do
    test "returns correct structure" do
      assert {:ok, result} = StyleTurn.parse("C/c")

      assert is_map(result)
      assert Map.has_key?(result, :active)
      assert Map.has_key?(result, :inactive)
    end

    test "active is a SIN struct" do
      assert {:ok, %{active: active, inactive: _}} = StyleTurn.parse("C/c")

      assert %Sin{} = active
      assert is_atom(active.style)
      assert active.side in [:first, :second]
    end

    test "inactive is a SIN struct" do
      assert {:ok, %{active: _, inactive: inactive}} = StyleTurn.parse("C/c")

      assert %Sin{} = inactive
      assert is_atom(inactive.style)
      assert inactive.side in [:first, :second]
    end
  end

  # =============================================================================
  # Consistency with FEEN Spec §9
  # =============================================================================

  describe "FEEN spec §9 compliance" do
    @tag :spec_compliance
    test "§9: format is <ACTIVE-STYLE>/<INACTIVE-STYLE>" do
      # Position determines who is active, not case
      assert {:ok, %{active: active, inactive: _}} = StyleTurn.parse("C/c")
      assert active.side == :first

      assert {:ok, %{active: active, inactive: _}} = StyleTurn.parse("c/C")
      assert active.side == :second
    end

    @tag :spec_compliance
    test "§9.1: uppercase = Side first, lowercase = Side second" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("C/c")

      # Active is uppercase C -> first
      assert active.side == :first
      # Inactive is lowercase c -> second
      assert inactive.side == :second
    end

    @tag :spec_compliance
    test "§9.1: side attribution is by token case, independent of turn order" do
      # When second player is active (lowercase first)
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("s/S")

      # Active s is lowercase -> side second
      assert active.side == :second
      # Inactive S is uppercase -> side first
      assert inactive.side == :first
    end

    @tag :spec_compliance
    test "§9.2: first position identifies Active Player" do
      # C is first -> active player is first player
      assert {:ok, %{active: active, inactive: _}} = StyleTurn.parse("C/c")
      assert active.side == :first

      # c is first -> active player is second player
      assert {:ok, %{active: active, inactive: _}} = StyleTurn.parse("c/C")
      assert active.side == :second
    end

    @tag :spec_compliance
    test "§9.3: tokens must be of opposite case" do
      # Same case should fail
      assert {:error, _} = StyleTurn.parse("C/C")
      assert {:error, _} = StyleTurn.parse("c/c")
      assert {:error, _} = StyleTurn.parse("S/X")
      assert {:error, _} = StyleTurn.parse("s/x")

      # Opposite case should succeed
      assert {:ok, _} = StyleTurn.parse("C/c")
      assert {:ok, _} = StyleTurn.parse("c/C")
      assert {:ok, _} = StyleTurn.parse("S/x")
      assert {:ok, _} = StyleTurn.parse("x/S")
    end

    @tag :spec_compliance
    test "§9.3: each token must be a valid SIN token" do
      # SIN tokens are exactly one ASCII letter
      assert {:error, _} = StyleTurn.parse("CC/c")
      assert {:error, _} = StyleTurn.parse("C/cc")
      assert {:error, _} = StyleTurn.parse("1/c")
      assert {:error, _} = StyleTurn.parse("C/1")
    end
  end

  # =============================================================================
  # Active Player Determination
  # =============================================================================

  describe "active player determination" do
    test "uppercase first means first player is active" do
      for letter <- ?A..?Z do
        upper = <<letter::utf8>>
        lower = <<(letter + 32)::utf8>>

        assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("#{upper}/#{lower}")

        assert active.side == :first,
               "Expected first player active for #{upper}/#{lower}"

        assert inactive.side == :second
      end
    end

    test "lowercase first means second player is active" do
      for letter <- ?a..?z do
        lower = <<letter::utf8>>
        upper = <<(letter - 32)::utf8>>

        assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("#{lower}/#{upper}")

        assert active.side == :second,
               "Expected second player active for #{lower}/#{upper}"

        assert inactive.side == :first
      end
    end
  end

  # =============================================================================
  # Style Preservation
  # =============================================================================

  describe "style preservation" do
    test "same style letter produces same style atom regardless of case" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("C/c")
      assert active.style == inactive.style
      assert active.style == :C
    end

    test "different style letters produce different style atoms" do
      assert {:ok, %{active: active, inactive: inactive}} = StyleTurn.parse("C/s")
      assert active.style == :C
      assert inactive.style == :S
    end

    test "style is always uppercase atom" do
      assert {:ok, %{active: active, inactive: _}} = StyleTurn.parse("c/C")
      # Even though input was lowercase c, style atom is uppercase :C
      assert active.style == :C
    end
  end
end
