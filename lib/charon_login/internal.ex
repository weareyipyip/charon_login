defmodule CharonLogin.Internal do
  @doc false
  defdelegate get_config, to: CharonLogin.FastConfig, as: :get_config

  @doc false
  def get_module_config(), do: get_config() |> get_module_config()

  def get_module_config(%{optional_modules: %{CharonLogin => config}}), do: config
end
