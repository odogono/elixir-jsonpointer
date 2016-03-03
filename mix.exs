defmodule JsonPointer.Mixfile do
  use Mix.Project

  @version "1.0.0"

  def project do
    [app: :json_pointer,
     name: "JSON Pointer",
     version: @version,
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     docs: [readme: "README.md",
            source_ref: "v#{@version}",
            source_url: "https://github.com/odogono/json_pointer"]]
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
    An implementation of RFC 6901
    """
  end

  defp package do
    %{name: "odgn_json_pointer",
      licenses: ["MIT"],
      maintainers: [ "Alexander Veenendaal" ],
      links: %{"GitHub" => "https://github.com/odogono/json_pointer"},
      files: [ "lib", "mix.exs", "README.md", "LICENSE"]
    }
  end

end
