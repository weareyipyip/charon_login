defmodule CharonLogin.Internal.GenMod.Plugs.LoginEndpoint do
  @moduledoc false

  def generate(config) do
    module_config = CharonLogin.Internal.get_module_config(config)

    quote generated: true, location: :keep do
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

      def call(%{method: "POST", path_info: ["complete"]} = conn, _) do
        CompleteFlow.handle(@config, conn)
      end

      def call(conn, _) do
        NotFound.handle(conn)
      end

      unquote(generate_parse_key(module_config.flows, :flow))
      unquote(generate_parse_key(module_config.stages, :stage))
      unquote(generate_parse_key(module_config.challenges, :challenge))
    end
  end

  defp generate_parse_key(map, type) do
    string_to_atom_map =
      Map.keys(map)
      |> Enum.map(&{Atom.to_string(&1), &1})
      |> Enum.into(%{})

    quote do
      defp unquote(:"parse_#{type}_key")(key) do
        unquote(string_to_atom_map |> Macro.escape())
        |> Map.get(key)
        |> case do
          nil -> {:error, unquote(:"#{type}_not_found")}
          parsed_key -> {:ok, parsed_key}
        end
      end
    end
  end
end
