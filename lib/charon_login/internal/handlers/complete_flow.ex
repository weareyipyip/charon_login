defmodule CharonLogin.Internal.Handlers.CompleteFlow do
  @moduledoc """
  This handler is called by the client to complete a flow.
  """

  alias CharonLogin.Internal
  alias Plug.Conn

  import CharonLogin.Internal.Handlers.Helpers

  @doc """
  Handle the request.
  """
  @spec handle(Conn.t()) :: Conn.t()
  def handle(conn) do
    module_config = Internal.get_conn_module_config(conn)
    config = Internal.get_conn_config(conn)

    with {:ok, %{extra_payload: session_payload} = session} <- get_session(conn),
         {:ok, :all_stages_completed} <- check_stages(session_payload.incomplete_stages),
         :ok <- delete_session(conn, session) do
      conn = maybe_put_skip_header(conn, config, session)

      module_config.success_callback.(
        conn,
        session_payload.flow_key,
        session_payload.user_identifier
      )
    else
      {:error, error} when is_atom(error) -> send_json(conn, %{error: error}, 400)
    end
  end

  defp check_stages([]), do: {:ok, :all_stages_completed}
  defp check_stages(_), do: {:error, :incomplete_stages}

  defp maybe_put_skip_header(
         conn,
         config,
         %{
           user_id: user_id,
           extra_payload: %{skipped_stages: skipped_stages, flow_key: flow_key}
         } = _session
       ) do
    {:ok, token} =
      %{
        "user_id" => user_id,
        "skipped_stages" => skipped_stages,
        "flow_key" => flow_key
      }
      |> config.token_factory_module.sign(config)

    Conn.put_resp_header(conn, "x-skip-token", token)
  end

  defp maybe_put_skip_header(conn, _config, _session), do: conn
end
