defmodule CharonLogin.TestHelpers do
  def get_base_secret(), do: 0

  def get_config() do
    [
      token_issuer: "Charon",
      get_base_secret: &__MODULE__.get_base_secret/0,
      session_store_module: Charon.SessionStore.LocalStore,
      optional_modules: %{
        CharonLogin => %{
          challenges: %{},
          stages: %{},
          flows: %{}
        }
      }
    ]
    |> Charon.Config.from_enum()
  end
end
