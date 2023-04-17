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
  @spec handle(Conn.t(), atom(), atom()) :: Conn.t()
  def handle(conn, stage_key, challenge_key) do
    module_config = Internal.conn_module_config(conn)
    available_challenges = Map.get(module_config.stages, stage_key)

    with {:ok, %{extra_payload: session_payload} = session} <- fetch_token(conn),
         {:ok, :is_current_stage} <- check_stage(session_payload.incomplete_stages, stage_key),
         {:ok, :is_valid_challenge} <- check_challenge(available_challenges, challenge_key) do
      {:ok, user} = module_config.fetch_user.(session_payload.user_identifier)
      {challenge, opts} = Map.get(module_config.challenges, challenge_key)

      case challenge.execute(conn, opts, user) do
        {:ok, :completed} ->
          incomplete_stages = complete_current_stage(session_payload.incomplete_stages)
          update_token(conn, session, %{incomplete_stages: incomplete_stages})

          send_json(conn, %{status: :completed})

        {:ok, :continue} ->
          send_json(conn, %{status: :continue})

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

  defp check_challenge(available_challenges, challenge_key) do
    if challenge_key in available_challenges,
      do: {:ok, :is_valid_challenge},
      else: {:error, :is_invalid_challenge}
  end

  defp complete_current_stage([_current_stage | remaining_stages]), do: remaining_stages
end
