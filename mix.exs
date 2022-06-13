defmodule DatadogErrorHandler.MixProject do
  @moduledoc """
  Defines the Mix project.
  """
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :datadog_error_handler,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Main dependencies
      {:dogstatsd, "~> 0.0.4"},

      # Documentation generation
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      assets: "assets",
      main: "readme",
      source_ref: @version
    ]
  end
end
