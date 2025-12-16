# mix.exs

defmodule Sashite.Feen.MixProject do
  use Mix.Project

  @version "1.0.0"
  @source_url "https://github.com/sashite/feen.ex"

  def project do
    [
      app: :sashite_feen,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Documentation
      name: "Sashite.Feen",
      source_url: @source_url,
      homepage_url: "https://sashite.dev/specs/feen/",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:sashite_epin, "~> 1.0"},
      {:sashite_sin, "~> 1.0"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    FEEN (Field Expression Encoding Notation) implementation for Elixir.
    A rule-agnostic position encoding for two-player, turn-based board games
    built on the Sashité Game Protocol.
    """
  end

  defp package do
    [
      name: "sashite_feen",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE.md),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Specification" => "https://sashite.dev/specs/feen/1.0.0/",
        "Documentation" => "https://hexdocs.pm/sashite_feen"
      },
      maintainers: ["Cyril Kato"]
    ]
  end
end
