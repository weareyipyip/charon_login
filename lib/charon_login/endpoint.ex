defmodule CharonLogin.Endpoint do
  alias CharonLogin.Internal
  alias CharonLogin.Internal.LoginEndpoint

  use Plug.Builder

  @impl true
  def init(opts), do: opts

  plug(LoginEndpoint)

  @impl true
  def call(conn, opts) do
    conn
    |> Internal.put_conn_config(opts[:config])
    |> super([])
  end
end
