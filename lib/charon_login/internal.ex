defmodule CharonLogin.Internal do
  @compile {:no_warn_undefined, {CharonLogin.FastConfig, :get_config, 0}}

  @doc false
  @spec get_config() :: Charon.Config.t()
  def get_config() do
    CharonLogin.FastConfig.get_config()
  rescue
    UndefinedFunctionError ->
      raise("Cannot find config, did you call `use CharonLogin, @charon_config`?")
  end

  @doc false
  @spec get_module_config() :: CharonLogin.Config.t()
  def get_module_config(), do: get_config() |> get_module_config()

  @spec get_module_config(Charon.Config.t()) :: CharonLogin.Config.t()
  def get_module_config(%{optional_modules: %{CharonLogin => config}}), do: config
end
