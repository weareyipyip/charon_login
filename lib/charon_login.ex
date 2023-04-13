defmodule CharonLogin do
  @doc false
  def init_config(enum), do: __MODULE__.Config.from_enum(enum)
end
