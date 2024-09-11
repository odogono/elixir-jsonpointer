defmodule JsonPointer.Mixfile do
  use Mix.Project

  @source_url "https://github.com/odogono/elixir-jsonpointer"
  @version "3.1.0"

  def project do
    [
      app: :odgn_json_pointer,
      name: "JSON Pointer",
      version: @version,
      package: package(),
      deps: deps(),
      description: description(),
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.17",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    An implementation of JSON Pointer (RFC 6901)
    """
  end

  defp deps do
    [
      {:credo, "~> 1.7.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.3", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.34.2", only: :dev, runtime: false},
      {:jason, "~> 1.4", only: [:dev, :test]}
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
