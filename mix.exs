defmodule CharonLogin.MixProject do
  use Mix.Project

  def project do
    [
      app: :charon_login,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:nimble_totp]
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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
      {:nimble_totp, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:makeup_json, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.2", only: :dev, runtime: false}
    ]
  end
end
