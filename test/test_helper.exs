ExUnit.start()
Supervisor.start_link([Charon.SessionStore.LocalStore], strategy: :one_for_one)

defmodule CharonLogin.TestModule do
  use CharonLogin, CharonLogin.TestHelpers.get_config()
end
