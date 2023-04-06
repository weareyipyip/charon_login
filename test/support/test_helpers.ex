defmodule CharonLogin.TestHelpers do
  def get_base_secret(), do: 0

  def fetch_user(_) do
    %{
      id: 0,
      totp_secret: <<1, 2, 3, 5, 8, 13, 21, 34>>
    }
  end

  def succes_callback(_conn, _, _), do: :succes!

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
      success_callback: &__MODULE__.succes_callback/3
      fetch_user: &__MODULE__.fetch_user/1
    ]
    |> Charon.Config.from_enum()
  end
end
