defmodule CharonLogin.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import CharonLogin.TestHelpers
      use Plug.Test
    end
  end
end
