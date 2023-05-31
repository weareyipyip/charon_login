defmodule CharonLogin.Internal.LoginEndpoint do
  @moduledoc """
  ## Usage

      alias #{__MODULE__}

      forward "/login", LoginEndpoint
  """
  @behaviour Plug
  alias CharonLogin.Internal.Handlers.{StartFlow, ExecuteChallenge, CompleteFlow, NotFound}
  alias CharonLogin.Internal

  import CharonLogin.Internal.Handlers.Helpers

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%{method: "POST", path_info: ["flows", flow_key, "start"]} = conn, _) do
    module_config = Internal.get_conn_module_config(conn)

    with {:ok, flow_key} <- parse_flow_key(module_config.flows, flow_key) do
      StartFlow.handle(conn, flow_key)
    else
      {:error, error} -> send_json(conn, %{error: error}, 404)
    end
  end

  def call(
        %{
          method: "POST",
          path_info: ["stages", stage_key, "challenges", challenge_key, "execute"]
        } = conn,
        _
      ) do
    module_config = Internal.get_conn_module_config(conn)

    with {:ok, stage_key} <- parse_stage_key(module_config.stages, stage_key),
         {:ok, challenge_key} <- parse_challenge_key(module_config.challenges, challenge_key) do
      ExecuteChallenge.handle(conn, stage_key, challenge_key)
    else
      {:error, error} -> send_json(conn, %{error: error}, 404)
    end
  end

  def call(%{method: "POST", path_info: ["complete"]} = conn, _) do
    CompleteFlow.handle(conn)
  end

  def call(conn, _) do
    NotFound.handle(conn)
  end

  defp parse_flow_key(flows, input_key) do
    Enum.find_value(Map.keys(flows), {:error, :flow_not_found}, fn key ->
      if key |> Atom.to_string() == input_key, do: {:ok, key}, else: false
    end)
  end

  defp parse_stage_key(stages, input_key) do
    Enum.find_value(Map.keys(stages), {:error, :stage_not_found}, fn key ->
      if key |> Atom.to_string() == input_key, do: {:ok, key}, else: false
    end)
  end

  defp parse_challenge_key(challenges, input_key) do
    Enum.find_value(Map.keys(challenges), {:error, :challenge_not_found}, fn key ->
      if key |> Atom.to_string() == input_key, do: {:ok, key}, else: false
    end)
  end
end
