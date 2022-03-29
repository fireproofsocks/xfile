defmodule Xfile.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/fireproofsocks/xfile"

  def project do
    [
      app: :xfile,
      description: description(),
      version: @version,
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test],
      docs: [
        main: "readme",
        source_ref: "v#{@version}",
        source_url: @source_url,
        logo: "assets/alien.png",
        extras: extras()
      ]
    ]
  end

  defp aliases do
    [
      lint: ["format --check-formatted", "credo --strict"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.28.3", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Augmentations of the built-in File module, including the ability to ls recursively,
    stream output, and filter files programmatically.
    """
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def extras do
    [
      "README.md",
      "CHANGELOG.md"
    ]
  end

  def links do
    %{
      "GitHub" => @source_url,
      "Readme" => "#{@source_url}/blob/v#{@version}/README.md",
      "Changelog" => "#{@source_url}/blob/v#{@version}/CHANGELOG.md"
    }
  end

  defp package do
    [
      maintainers: ["Everett Griffiths"],
      licenses: ["Apache 2.0"],
      logo: "assets/logo.png",
      links: links(),
      files: [
        "lib",
        "assets/logo.png",
        "mix.exs",
        "README*",
        "CHANGELOG*",
        "LICENSE*"
      ]
    ]
  end
end
