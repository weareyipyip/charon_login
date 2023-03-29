defmodule CharonLogin.Internal.Handlers.Helpers do
  alias CharonLogin.Config
  alias Plug.Conn

  import Conn

  @type token :: %{flow_key: atom(), user_identifier: String.t(), incomplete_stages: [atom()]}

  @doc """
  Get a list of required stages for the given flow key.
  """
  @spec get_flow(Config.t(), atom()) :: [atom()] | nil
  def get_flow(config, flow_key), do: Map.get(config.flows, flow_key)

  @doc """
  Get a list of available challenges for the given stage key.
  """
  @spec get_stage(Config.t(), atom()) :: [atom()] | nil
  def get_stage(config, stage_key), do: Map.get(config.stages, stage_key)

  @doc """
  Get a challenge for the given challenge key.
  """
  @spec get_challenge(Config.t(), atom()) :: {module(), map()} | nil
  def get_challenge(config, challenge_key), do: Map.get(config.challenges, challenge_key)

  @doc """
  Create a new progress token.
  """
  @spec create_token(Charon.Config.t(), token()) :: String.t()
  def create_token(config, %{
        flow_key: flow_key,
        user_identifier: user_identifier,
        incomplete_stages: incomplete_stages
      }) do
    {:ok, token} =
      config.token_factory_module.sign(
        %{
          "flow_key" => Atom.to_string(flow_key),
          "user_identifier" => user_identifier,
          "incomplete_stages" => Enum.map(incomplete_stages, &Atom.to_string/1)
        },
        config
      )

    token
  end

  @doc """
  Fetch and validate the progress token from the current request.
  """
  @spec fetch_token(Charon.Config.t(), Conn.t()) ::
          {:ok, token()} | {:error, :invalid_authorization}
  def fetch_token(config, conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok,
          %{
            "flow_key" => flow_key,
            "user_identifier" => user_identifier,
            "incomplete_stages" => incomplete_stages
          }} <- config.token_factory_module.verify(token, config) do
      {:ok,
       %{
         flow_key: String.to_existing_atom(flow_key),
         user_identifier: user_identifier,
         incomplete_stages: Enum.map(incomplete_stages, &String.to_existing_atom/1)
       }}
    else
      _ -> {:error, :invalid_authorization}
    end
  rescue
    ArgumentError -> {:error, :invalid_authorization}
  end

  @doc """
  Send a JSON response.
  """
  @spec send_json(Conn.t(), map(), pos_integer()) :: Conn.t()
  def send_json(conn, data, status \\ 200) do
    {:ok, json} = Jason.encode(data)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, json)
  end
end
