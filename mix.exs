defmodule JsonPointer.Mixfile do
  use Mix.Project

  @version "1.2.0"

  def project do
    [app: :json_pointer,
     name: "JSON Pointer",
     description: description,
     package: package,
     deps: deps,
     version: @version,
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     docs: [readme: "README.md",
            source_ref: "v#{@version}",
            source_url: "https://github.com/odogono/elixir-jsonpointer"]]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}]
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
      maintainers: [ "Alexander Veenendaal" ],
      links: %{"GitHub" => "https://github.com/odogono/elixir-jsonpointer"},
      files: [ "lib", "mix.exs", "README.md", "LICENSE"]
    ]
  end

end
