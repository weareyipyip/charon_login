defmodule CharonLogin.Endpoint do
  alias CharonLogin.Internal.LoginEndpoint

  use Plug.Builder

  @impl true
  def init(opts), do: opts

  plug(LoginEndpoint)

  @impl true
  def call(conn, opts) do
    with %Charon.Config{} = config <- opts[:config],
         %{optional_modules: %{CharonLogin => module_config}} <- config do
      conn
      |> put_private(:charon_login_config, config)
      |> put_private(:charon_login_module_config, module_config)
      |> super([])
    else
      _ -> raise "Missing or invalid config"
    end
  end
end
