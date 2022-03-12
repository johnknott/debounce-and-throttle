defmodule DebounceAndThrottle.MixProject do
  use Mix.Project
  @github_url "https://github.com/johnknott/debounce-and-throttle"

  def project do
    [
      app: :debounce_and_throttle,
      version: "0.9.0",
      name: "Debounce and Throttle",
      description: "Provides simple debounce and throttle functionality",
      source_url: @github_url,
      homepage_url: @github_url,
      files: ~w(mix.exs lib LICENSE.md README.md CHANGELOG.md),
      package: [
        maintainers: ["John Knott"],
        licenses: ["MIT"],
        links: %{
          "GitHub" => @github_url
        }
      ],
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"]
      ],
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DebounceAndThrottle.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
