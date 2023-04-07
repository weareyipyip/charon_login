defmodule CharonLogin.Internal.Handlers.ExecuteChallenge do
  @moduledoc """
  This handler is called by the client to execute a challenge.
  """

  alias CharonLogin.Internal
  alias Plug.Conn

  import CharonLogin.Internal.Handlers.Helpers

  @doc """
  Handle the request.
  """
  @spec handle(Charon.Config.t(), Conn.t(), atom(), atom()) :: Conn.t()
  def handle(config, conn, stage_key, challenge_key) do
    module_config = Internal.get_module_config(config)

    with {:ok, token_payload} <- fetch_token(config, conn),
         {:ok, :is_current_stage} <- check_stage(token_payload.incomplete_stages, stage_key),
         {:ok, :is_valid_challenge} <- check_challenge(module_config, stage_key, challenge_key) do
      user = module_config.fetch_user.(token_payload.user_identifier)
      {challenge, opts} = get_challenge(module_config, challenge_key)

      case challenge.execute(conn, opts, user) do
        {:ok, :completed} ->
          incomplete_stages = complete_current_stage(token_payload.incomplete_stages)

          send_json(conn, %{
            token: create_token(config, %{token_payload | incomplete_stages: incomplete_stages})
          })

        {:ok, :continue} ->
          send_json(conn, %{
            token: create_token(config, token_payload)
          })

        {:error, error} ->
          send_json(conn, %{error: error}, 500)
      end
    else
      {:error, error} when is_atom(error) -> send_json(conn, %{error: error}, 400)
    end
  end

  defp check_stage(incomplete_stages, stage_key) do
    if hd(incomplete_stages) == stage_key,
      do: {:ok, :is_current_stage},
      else: {:error, :is_not_current_stage}
  end

  defp check_challenge(module_config, stage_key, challenge_key) do
    challenge_keys = get_stage(module_config, stage_key)

    if challenge_key in challenge_keys,
      do: {:ok, :is_valid_challenge},
      else: {:error, :is_invalid_challenge}
  end

  defp complete_current_stage([_current_stage | remaining_stages]), do: remaining_stages
end
