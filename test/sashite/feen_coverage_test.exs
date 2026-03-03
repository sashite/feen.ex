defmodule Sashite.Feen.CoverageTest do
  use ExUnit.Case, async: true

  # Targets specific uncovered branches to maximize coverage.
  # Each section names the module and lines it exercises.

  # ===========================================================================
  # Dumper.Hands sort_key branches (L62-90)
  # ===========================================================================

  describe "Dumper.Hands sort_key: state modifier branches" do
    test "diminished prefix in hand" do
      feen = "8/8 -P/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "enhanced prefix in hand" do
      feen = "8/8 +P/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  describe "Dumper.Hands sort_key: lowercase letter branch" do
    test "lowercase piece in hand" do
      feen = "8/8 /b C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "lowercase diminished in hand" do
      feen = "8/8 /-p C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "lowercase enhanced in hand" do
      feen = "8/8 /+p C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  describe "Dumper.Hands sort_key: terminal suffix branch" do
    test "terminal piece in hand" do
      feen = "8/8 P^/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "enhanced terminal in hand" do
      feen = "8/8 +P^/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "diminished terminal in hand" do
      feen = "8/8 -P^/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "lowercase terminal in hand" do
      feen = "8/8 /p^ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  describe "Dumper.Hands sort_key: derived suffix branch" do
    test "derived without terminal in hand" do
      feen = "8/8 P" <> "'" <> "/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "terminal derived in hand" do
      feen = "8/8 P^" <> "'" <> "/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "enhanced terminal derived in hand" do
      feen = "8/8 +P^" <> "'" <> "/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "diminished terminal derived in hand" do
      feen = "8/8 -P^" <> "'" <> "/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "lowercase derived in hand" do
      feen = "8/8 /p" <> "'" <> " C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "lowercase terminal derived in hand" do
      feen = "8/8 /p^" <> "'" <> " C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  describe "Dumper.Hands sort_key: mixed modifiers ordering" do
    test "count desc then state ordering" do
      feen = "8/8/8/8/8/8/8/8 2+P-P/2+p-p C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end

    test "multiple distinct modified pieces" do
      feen = "8/8/8/8/8/8/8/8 -B+BP/ C/c"
      assert feen == feen |> Sashite.Feen.parse!() |> Sashite.Feen.dump()
    end
  end

  # ===========================================================================
  # Parser.StyleTurn fallthrough branch (L47-49)
  # ===========================================================================

  describe "Parser.StyleTurn fallthrough: multi-byte with one slash" do
    test "rejects 4-byte style token with one slash" do
      assert {:error, :invalid_style_token} =
               Sashite.Feen.parse("8/8 / CC/c")
    end

    test "rejects long style tokens with slash" do
      assert {:error, :invalid_style_token} =
               Sashite.Feen.parse("8/8 / Chess/chess")
    end
  end

  # ===========================================================================
  # Parser.Hands EPIN modifier extraction (L132-140)
  # ===========================================================================

  describe "Parser.Hands EPIN modifier extraction" do
    test "parses enhanced piece in hand" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8 +P/ C/c")
      assert pos.first_player_hand == %{"+P" => 1}
    end

    test "parses diminished piece in hand" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8 -P/ C/c")
      assert pos.first_player_hand == %{"-P" => 1}
    end

    test "parses terminal piece in hand" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8 P^/ C/c")
      assert pos.first_player_hand == %{"P^" => 1}
    end

    test "parses derived piece in hand" do
      feen = "8/8 P" <> "'" <> "/ C/c"
      assert {:ok, pos} = Sashite.Feen.parse(feen)
      assert pos.first_player_hand == %{("P" <> "'") => 1}
    end

    test "parses terminal derived piece in hand" do
      feen = "8/8 P^" <> "'" <> "/ C/c"
      assert {:ok, pos} = Sashite.Feen.parse(feen)
      assert pos.first_player_hand == %{("P^" <> "'") => 1}
    end

    test "parses enhanced terminal piece in hand" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8 +P^/ C/c")
      assert pos.first_player_hand == %{"+P^" => 1}
    end

    test "parses diminished terminal derived piece in hand" do
      feen = "8/8 -P^" <> "'" <> "/ C/c"
      assert {:ok, pos} = Sashite.Feen.parse(feen)
      assert pos.first_player_hand == %{("-P^" <> "'") => 1}
    end

    test "parses multiplicity with modified piece" do
      assert {:ok, pos} = Sashite.Feen.parse("8/8/8/8/8/8/8/8 2+P/ C/c")
      assert pos.first_player_hand == %{"+P" => 2}
    end
  end

  # ===========================================================================
  # Parser.PiecePlacement dimension limits (L38-39, L65-66, L87-91)
  # ===========================================================================

  describe "Parser.PiecePlacement dimension size limits" do
    test "rejects 1D board with width > 255" do
      assert {:error, :dimension_size_exceeds_limit} =
               Sashite.Feen.parse("256 / C/c")
    end

    test "accepts 1D board at width boundary 255" do
      assert {:ok, _} = Sashite.Feen.parse("255 / C/c")
    end

    test "rejects 2D board with rank width > 255" do
      assert {:error, :dimension_size_exceeds_limit} =
               Sashite.Feen.parse("256/256 / C/c")
    end

    test "rejects 2D board with rank count > 255" do
      ranks = Enum.join(List.duplicate("1", 256), "/")
      feen = ranks <> " / C/c"

      assert {:error, :dimension_size_exceeds_limit} =
               Sashite.Feen.parse(feen)
    end

    test "rejects 4D board (exceeds max dimensions)" do
      assert {:error, :exceeds_max_dimensions} =
               Sashite.Feen.parse("a/b//c/d///e/f//g/h / G/g")
    end

    test "rejects 3D board with rank width > 255" do
      assert {:error, :dimension_size_exceeds_limit} =
               Sashite.Feen.parse("256/256//256/256 / G/g")
    end

    test "rejects 3D board with ranks per layer > 255" do
      layer = Enum.join(List.duplicate("1", 256), "/")
      feen = layer <> "//" <> layer <> " / G/g"

      assert {:error, :dimension_size_exceeds_limit} =
               Sashite.Feen.parse(feen)
    end

    test "rejects 3D board with layer count > 255" do
      layer = "1/1"
      layers = Enum.join(List.duplicate(layer, 256), "//")
      feen = layers <> " / G/g"

      assert {:error, :dimension_size_exceeds_limit} =
               Sashite.Feen.parse(feen)
    end
  end
end
