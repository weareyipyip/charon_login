defmodule CharonLogin.MixProject do
  use Mix.Project

  def project do
    [
      app: :charon_login,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:jason, "~> 1.4"},
      {:charon, ">= 2.0.0 and < 4.0.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:makeup_json, ">= 0.0.0", only: :dev, runtime: false}
      # {:argon2_elixir, "~> 3.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
