defmodule CharonLogin.ChallengeCase do
  use ExUnit.CaseTemplate

  use CharonLogin, CharonLogin.TestHelpers.get_config()

  setup do
    start_supervised!(Charon.SessionStore.LocalStore)
    :ok
  end
end
