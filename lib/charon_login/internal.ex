defmodule CharonLogin.Internal do
  @doc false
  def get_module_config(%{optional_modules: %{CharonLogin => config}}), do: config
end
