defmodule JsonPointer.Mixfile do
  use Mix.Project

  @version "3.0.1"

  def project do
    [
      app: :odgn_json_pointer,
      name: "JSON Pointer",
      version: @version,
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/odogono/elixir-jsonpointer"
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.3.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.19.2", only: :dev, runtime: false},
      {:jason, "~> 1.1.2", only: [:dev, :test]},
    ]
  end

  defp dialyzer() do
    [
      ignore_warnings: "dialyzer.ignore"
    ]
  end

  defp description do
    """
    This is an implementation of JSON Pointer (RFC 6901) for Elixir.
    """
  end

  defp package do
    [
      name: "odgn_json_pointer",
      licenses: ["MIT"],
      maintainers: ["Alexander Veenendaal"],
      links: %{"GitHub" => "https://github.com/odogono/elixir-jsonpointer"},
      files: ["lib", "mix.exs", "README.md", "LICENSE"]
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
