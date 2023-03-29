defmodule CharonLogin.Internal.GenMod.Plugs.LoginEndpoint do
  @moduledoc false

  defp gen_key_map(map) do
    map
    |> Map.keys()
    |> Enum.map(&{Atom.to_string(&1), &1})
    |> Enum.into(%{})
  end

  def generate(config) do
    module_config = CharonLogin.Internal.get_module_config(config)

    quote generated: true do
      @moduledoc """
      ## Usage

          alias #{__MODULE__}

          forward "/login", LoginEndpoint
      """
      @behaviour Plug
      alias CharonLogin.Internal.Handlers.{StartFlow, ExecuteChallenge, CompleteFlow, NotFound}
      alias Plug.Conn

      import CharonLogin.Internal.Handlers.Helpers

      @config unquote(config |> Macro.escape())

      @impl true
      def init(opts), do: opts

      @impl true
      def call(%{method: "POST", path_info: ["flows", flow_key, "start"]} = conn, _) do
        with {:ok, flow_key} <- parse_flow_key(flow_key) do
          StartFlow.handle(@config, conn, flow_key)
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
        with {:ok, stage_key} <- parse_stage_key(stage_key),
             {:ok, challenge_key} <- parse_challenge_key(challenge_key) do
          ExecuteChallenge.handle(@config, conn, stage_key, challenge_key)
        else
          {:error, error} -> send_json(conn, %{error: error}, 404)
        end
      end

      def call(%{method: "POST", path_info: ["complete"]} = conn) do
        CompleteFlow.handle(@config, conn)
      end

      def call(conn, _) do
        NotFound.handle(conn)
      end

      defp parse_flow_key(flow_key) do
        unquote(module_config.flows |> gen_key_map() |> Macro.escape())
        |> Map.get(flow_key)
        |> case do
          nil -> {:error, :flow_not_found}
          flow_key -> {:ok, flow_key}
        end
      end

      defp parse_stage_key(stage_key) do
        unquote(module_config.stages |> gen_key_map() |> Macro.escape())
        |> Map.get(stage_key)
        |> case do
          nil -> {:error, :stage_not_found}
          stage_key -> {:ok, stage_key}
        end
      end

      defp parse_challenge_key(challenge_key) do
        unquote(module_config.challenges |> gen_key_map() |> Macro.escape())
        |> Map.get(challenge_key)
        |> case do
          nil -> {:error, :challenge_not_found}
          challenge_key -> {:ok, challenge_key}
        end
      end
    end
  end
end
