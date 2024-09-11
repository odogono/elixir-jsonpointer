defmodule JsonPointer.Mixfile do
  use Mix.Project

  @source_url "https://github.com/odogono/elixir-jsonpointer"
  @version "3.0.1"

  def project do
    [
      app: :odgn_json_pointer,
      name: "JSON Pointer",
      version: @version,
      package: package(),
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.1.2", only: [:dev, :test]}
    ]
  end

  defp dialyzer() do
    [
      ignore_warnings: "dialyzer.ignore"
    ]
  end

  defp package do
    [
      name: "odgn_json_pointer",
      description: "This is an implementation of JSON Pointer (RFC 6901) for Elixir.",
      licenses: ["MIT"],
      maintainers: ["Alexander Veenendaal"],
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      links: %{
        "Changelog" => "https://hexdocs.pm/odgn_json_pointer/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: [
        "CHANGELOG.md": [],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
