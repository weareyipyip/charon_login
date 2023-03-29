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
  @spec handle(Charon.Config.t(), Conn.t()) :: Conn.t()
  def handle(config, conn) do
    module_config = Internal.get_module_config(config)

    with {:ok, %{flow_key: flow_key, incomplete_stages: incomplete_stages}} <-
           fetch_token(config, conn),
         :all_stages_completed <- check_stages(incomplete_stages) do
      module_config.success_callback(conn, flow_key)
    else
      {:error, :invalid_authorization} -> send_json(conn, %{error: :invalid_authorization}, 400)
      :incomplete_stages -> send_json(conn, %{error: :incomplete_stages}, 400)
    end
  end

  defp check_stages([]), do: :all_stages_completed
  defp check_stages(_), do: :incomplete_stages
end
