defmodule CharonLogin do
  @moduledoc """
      use CharonLogin, @charon_config
  """

  alias CharonLogin.Internal.GenMod.Plugs.LoginEndpoint

  @doc false
  def init_config(enum), do: __MODULE__.Config.from_enum(enum)

  defmacro __using__(config) do
    quote location: :keep, generated: true do
      # @charon_config unquote(config)
      @login_endpoint __MODULE__.Plugs.LoginEndpoint
      @config_endpoint CharonLogin.FastConfig
      @config unquote(config |> Macro.escape())

      # charon_config = Macro.escape(@charon_config)

      login_endpoint = LoginEndpoint.generate(unquote(config))
      Module.create(@login_endpoint, login_endpoint, Macro.Env.location(__ENV__))

      Module.create(
        @config_endpoint,
        quote do
          def get_config(), do: unquote(@config)
        end,
        Macro.Env.location(__ENV__)
      )
    end
  end
end
