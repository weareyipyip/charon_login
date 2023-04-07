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
  @spec handle(Conn.t(), atom()) :: Conn.t()
  def handle(conn, flow_key) do
    module_config = Internal.get_module_config()
    stage_keys = Map.get(module_config.flows, flow_key)

    with user_identifier when not is_nil(user_identifier) <-
           Map.get(conn.body_params, "user_identifier"),
         user <- module_config.fetch_user.(user_identifier) do
      token =
        create_token(%{
          flow_key: flow_key,
          user_identifier: user_identifier,
          incomplete_stages: stage_keys
        })

      stages =
        Enum.map(stage_keys, fn stage_key ->
          challenge_keys = Map.get(module_config.stages, stage_key)

          challenges =
            Enum.map(challenge_keys, fn challenge_key ->
              {challenge, _opts} = Map.get(module_config.challenges, challenge_key)
              %{key: challenge_key, type: challenge.type()}
            end)

          %{key: stage_key, challenges: challenges}
        end)

      send_json(conn, %{stages: stages, enabled_challenges: user.enabled_challenges, token: token})
    else
      nil -> send_json(conn, %{error: :invalid_user}, 400)
    end
  end
end
