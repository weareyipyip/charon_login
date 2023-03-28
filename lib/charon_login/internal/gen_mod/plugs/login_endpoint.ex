defmodule CharonLogin.Internal.GenMod.Plugs.LoginEndpoint do
  @moduledoc false

  def generate(config) do
    module_config = CharonLogin.Internal.get_module_config(config)
    challenges = parse_challenges(module_config)
    stages = parse_stages(module_config)
    flows = parse_flows(module_config)
    flattened_flows = flatten_flows(flows, stages, challenges)

    quote generated: true do
      @moduledoc """
      ## Usage

          alias #{__MODULE__}

          forward "/login", LoginEndpoint
      """
      @behaviour Plug
      alias Plug.Conn
      import Conn

      @config unquote(Macro.escape(config))
      @module_config unquote(Macro.escape(module_config))
      @challenges unquote(Macro.escape(challenges))
      @stages unquote(Macro.escape(stages))
      @flows unquote(Macro.escape(flows))
      @flattened_flows unquote(Macro.escape(flattened_flows))

      @impl true
      def init(opts), do: opts

      @impl true
      @doc """
      Start the requested flow.

      The client will receive:
      * The required stages for the flow.
      * The available challenges for each stage.
      * An initial token that can be used to complete these stages in order.
      """
      def call(%{method: "POST", path_info: ["flows", flow_key, "start"]} = conn, _) do
        IO.inspect(@flows)

        with required_stages <- Map.get(@flows, flow_key),
             {:ok, token} <-
               @config.token_factory_module.sign(
                 %{flow_key: flow_key, incomplete_stages: required_stages},
                 @config
               ) do
          res = %{
            # TODO: map keys are not ordered.
            stages: Map.get(@flattened_flows, flow_key),
            token: token
          }

          conn |> send_json(res)
        end
      end

      def call(
            %{
              method: "POST",
              path_info: ["stages", stage_key, "challenges", challenge_key, "execute"]
            } = conn,
            _
          ) do
        with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
             {:ok, %{"flow_key" => flow_key, "incomplete_stages" => incomplete_stages}} <-
               @config.token_factory_module.verify(token, @config),
             true <- verify_exists(flow_key, stage_key, challenge_key),
             hd(incomplete_stages) == stage_key do
          {challenge, opts} = Map.get(@challenges, challenge_key)

          case challenge.execute(opts, conn) do
            {:ok, :completed} ->
              send_json(conn, create_token(flow_key, incomplete_stages |> Enum.drop(1)))

            {:ok, :continue} ->
              send_json(conn, %{flow_key: flow_key, incomplete_stages: incomplete_stages})

            {:error, error} ->
              send_json(conn, %{error: error}, 500)
          end
        end
      end

      def call(%{method: "POST", path_info: ["complete"]} = conn) do
        with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
             {:ok, %{"flow_key" => flow_key, "incomplete_stages" => incomplete_stages}} <-
               @config.token_factory_module.verify(token, @config),
             [] <- incomplete_stages do
          @module_config.success_callback(conn, flow_key)
        end
      end

      def call(conn, _) do
        conn |> send_json(%{error: "not_found"}, 404)
      end

      defp create_token(flow_key, incomplete_stages) do
        {:ok, token} =
          @config.token_factory_module.sign(
            %{"flow_key" => flow_key, "incomplete_stages" => incomplete_stages},
            @config
          )

        token
      end

      defp send_json(conn, data, status \\ 200) do
        {:ok, json} = Jason.encode(data)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(status, json)
      end

      defp verify_exists(flow), do: Map.has_key?(@flattened_flows, flow)

      defp verify_exists(flow, stage),
        do: Map.get(@flattened_flows, flow, %{}) |> Map.has_key?(stage)

      defp verify_exists(flow, stage, challenge),
        do: Map.get(@flattened_flows, flow, %{}) |> Map.get(stage, %{}) |> Map.has_key?(challenge)
    end
  end

  defp parse_challenges(module_config) do
    Enum.reduce(module_config.challenges, %{}, fn {key, {module, opts}}, acc ->
      Map.put(acc, key |> Atom.to_string(), {module, opts})
    end)
  end

  defp parse_stages(module_config) do
    Enum.reduce(module_config.stages, %{}, fn {key, challenges}, acc ->
      Map.put(acc, key |> Atom.to_string(), challenges |> Enum.map(&Atom.to_string/1))
    end)
  end

  defp parse_flows(module_config) do
    Enum.reduce(module_config.flows, %{}, fn {key, stages}, acc ->
      Map.put(acc, key |> Atom.to_string(), stages |> Enum.map(&Atom.to_string/1))
    end)
  end

  def flatten_flows(flows, stages, challenges) do
    flows
    |> Enum.reduce(%{}, fn {flow_key, stage_keys}, acc ->
      stages =
        stage_keys
        |> Enum.reduce(%{}, fn stage_key, acc ->
          challenge_keys = Map.get(stages, stage_key)

          challenges =
            challenge_keys
            |> Enum.reduce(%{}, fn challenge_key, acc ->
              {challenge, opts} = Map.get(challenges, challenge_key)

              Map.put(acc, challenge_key, %{"type" => challenge.type()})
            end)

          Map.put(acc, stage_key, challenges)
        end)

      Map.put(acc, flow_key, stages)
    end)
  end
end
