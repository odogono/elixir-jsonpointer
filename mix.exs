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
     docs: [readme: "README.md", main: "README",
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
    []
  end

  defp package do
    %{licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/odogono/json_pointer"}}
  end

end
