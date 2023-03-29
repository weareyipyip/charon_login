defmodule CharonLogin.Internal.Handlers.StartFlow do
  @moduledoc """
  This handler is called by the client to start a flow.

  If the flow exists, it returns the required stages and their available challenges.
  A token is also included, and can be used to complete challenges.
  """

  alias CharonLogin.Internal
  alias Plug.Conn

  import CharonLogin.Internal.Handlers.Helpers

  @doc """
  Handle the request.
  """
  @spec handle(Charon.Config.t(), Conn.t(), atom()) :: Conn.t()
  def handle(config, conn, flow_key) do
    module_config = Internal.get_module_config(config)

    case get_flow(module_config, flow_key) do
      nil ->
        send_json(conn, %{error: :flow_not_found}, 404)

      stage_keys ->
        token = create_token(config, flow_key, stage_keys)

        stages =
          Enum.map(stage_keys, fn stage_key ->
            challenges =
              Enum.map(Map.get(module_config.stages, stage_key), fn challenge_key ->
                {challenge, _opts} = Map.get(module_config.challenges, challenge_key)

                %{key: challenge_key, type: challenge.type()}
              end)

            %{key: stage_key, challenges: challenges}
          end)

        send_json(conn, %{stages: stages, token: token})
    end
  end
end
