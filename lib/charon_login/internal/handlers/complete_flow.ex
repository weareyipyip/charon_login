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
    module_config = Internal.conn_module_config(conn)

    with {:ok, %{extra_payload: session_payload}} <- fetch_token(conn),
         {:ok, :all_stages_completed} <- check_stages(session_payload.incomplete_stages) do
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
end
