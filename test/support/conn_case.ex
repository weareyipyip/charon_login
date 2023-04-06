defmodule CharonLogin.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      use Plug.Test
    end
  end
end
