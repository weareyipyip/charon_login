defmodule CharonLogin.Internal do
  @spec get_conn_config(Plug.Conn.t()) :: Charon.Config.t()
  def get_conn_config(%{private: %{charon_login_config: config}}), do: config

  @spec get_conn_module_config(Plug.Conn.t()) :: CharonLogin.Config.t()
  def get_conn_module_config(%{private: %{charon_login_module_config: module_config}}),
    do: module_config

  @spec put_conn_config(Plug.Conn.t(), Charon.Config.t()) :: Plug.Conn.t()
  def put_conn_config(
        conn,
        %Charon.Config{optional_modules: %{CharonLogin => module_config}} = config
      ) do
    conn
    |> Plug.Conn.put_private(:charon_login_config, config)
    |> Plug.Conn.put_private(:charon_login_module_config, module_config)
  end
end
