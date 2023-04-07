defmodule CharonLogin do
  @moduledoc """
      use CharonLogin, @charon_config
  """

  @doc false
  def init_config(enum), do: __MODULE__.Config.from_enum(enum)

  defmacro __using__(config) do
    quote location: :keep, generated: true do
      @config unquote(config |> Macro.escape())

      # suppress "redefining module" warning, because we actually want to redefine it :)
      Code.compiler_options(ignore_module_conflict: true)

      Module.create(
        CharonLogin.FastConfig,
        quote do
          def get_config(), do: unquote(@config)
        end,
        Macro.Env.location(__ENV__)
      )

      Code.compiler_options(ignore_module_conflict: false)
    end
  end
end
