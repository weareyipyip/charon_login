defmodule CharonLogin.Internal.GenMod.Plugs.LoginEndpoint do
  @moduledoc false

  def generate(config) do
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
        CharonLogin.Internal.Handlers.StartFlow.handle(@config, conn, flow_key)
      end

      def call(
            %{
              method: "POST",
              path_info: ["stages", stage_key, "challenges", challenge_key, "execute"]
            } = conn,
            _
          ) do
        CharonLogin.Internal.Handlers.ExecuteChallenge.handle(
          @config,
          conn,
          stage_key,
          challenge_key
        )
      end

      def call(%{method: "POST", path_info: ["complete"]} = conn) do
        CharonLogin.Internal.Handlers.CompleteFlow.handle(@config, conn)
      end

      def call(conn, _) do
        CharonLogin.Internal.Handlers.NotFound.handle(conn)
      end
    end
  end
end
