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

    with {:ok, %{flow_key: flow_key, incomplete_stages: incomplete_stages}} <-
           fetch_token(config, conn),
         :is_current_stage <- check_stage(incomplete_stages, stage_key),
         :is_valid_challenge <- check_challenge(module_config, stage_key, challenge_key) do
      {challenge, opts} = get_challenge(module_config, challenge_key)

      case challenge.execute(opts, conn) do
        {:ok, :completed} ->
          send_json(conn, %{
            token: create_token(config, flow_key, complete_current_stage(incomplete_stages))
          })

        {:ok, :continue} ->
          send_json(conn, %{
            token: create_token(config, flow_key, incomplete_stages)
          })

        {:error, error} ->
          send_json(conn, %{error: error}, 500)
      end
    else
      {:error, :invalid_authorization} -> send_json(conn, %{error: :invalid_authorization}, 400)
      :is_not_current_stage -> send_json(conn, %{error: :not_current_stage}, 400)
      :is_invalid_challenge -> send_json(conn, %{error: :invalid_challenge}, 400)
    end
  end

  defp check_stage(incomplete_stages, stage_key) do
    if hd(incomplete_stages) == stage_key, do: :is_current_stage, else: :is_not_current_stage
  end

  defp check_challenge(module_config, stage_key, challenge_key) do
    case get_stage(module_config, stage_key) do
      nil ->
        :is_invalid_challenge

      challenge_keys ->
        if challenge_key in challenge_keys, do: :is_valid_challenge, else: :is_invalid_challenge
    end
  rescue
    ArgumentError -> :is_invalid_challenge
  end

  defp complete_current_stage([_current_stage | remaining_stages]), do: remaining_stages
end
