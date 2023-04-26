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
    module_config = Internal.conn_module_config(conn)

    stage_keys =
      Map.get(module_config.flows, flow_key)
      |> get_stage_keys(conn)

    with user_identifier when not is_nil(user_identifier) <-
           Map.get(conn.body_params, "user_identifier"),
         {:ok, user} <- fetch_user_by_id(module_config, user_identifier),
         {:ok, token} <-
           create_token(conn, %{
             flow_key: flow_key,
             user_identifier: user_identifier,
             incomplete_stages: stage_keys
           }) do
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
      {:error, reason} -> send_json(conn, %{error: reason}, 400)
      nil -> send_json(conn, %{error: :invalid_user}, 400)
    end
  end

  # TODO: verify whether token is for current user and flow!
  defp get_stage_keys(stages, conn) do
    case Conn.get_req_header(conn, "x-skip-token") do
      [token] ->
        config = Internal.conn_config(conn)

        {:ok, %{"skipped_stages" => skipped_stages}} =
          config.token_factory_module.verify(token, config)

        Enum.flat_map(stages, fn raw_stage ->
          case raw_stage do
            {stage, [skippable: true]} ->
              if Enum.member?(skipped_stages, stage |> Atom.to_string()) do
                []
              else
                [stage]
              end

            stage ->
              [stage]
          end
        end)
        |> IO.inspect()

      _ ->
        Enum.map(stages, fn stage ->
          case stage do
            {stage, _} ->
              stage

            stage ->
              stage
          end
        end)
    end
  end

  defp fetch_user_by_id(module_config, user_id) do
    case module_config.fetch_user.(user_id) do
      {:ok, user} -> {:ok, user}
      {:error, reason} -> {:error, reason}
      _ -> {:error, :user_not_found}
    end
  end
end
