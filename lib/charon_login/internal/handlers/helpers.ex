defmodule CharonLogin.Internal.Handlers.Helpers do
  alias CharonLogin.Internal
  alias Plug.Conn

  import Conn

  @type token :: %{flow_key: atom(), user_identifier: String.t(), incomplete_stages: [atom()]}

  @doc """
  Create a new progress token.
  """
  @spec create_token(Conn.t(), token()) :: String.t()
  def create_token(conn, %{
        flow_key: flow_key,
        user_identifier: user_identifier,
        incomplete_stages: incomplete_stages
      }) do
    config = Internal.conn_config(conn)

    now = Charon.Internal.now()
    expiration = now + 60 * 15

    session = %Charon.Models.Session{
      id: Charon.Internal.Crypto.random_url_encoded(16),
      user_id: user_identifier,
      created_at: now,
      expires_at: expiration,
      type: :proto,
      refreshed_at: now,
      refresh_expires_at: expiration,
      refresh_token_id: 0,
      tokens_fresh_from: 0,
      extra_payload: %{
        flow_key: flow_key,
        user_identifier: user_identifier,
        incomplete_stages: incomplete_stages
      }
    }

    :ok = Charon.SessionStore.upsert(session, config)

    {:ok, token} =
      config.token_factory_module.sign(
        %{"session_id" => session.id, "user_id" => session.user_id},
        config
      )

    token
  end

  @spec update_token(Conn.t(), Charon.Models.Session.t(), map()) :: :ok
  def update_token(conn, session, updates) do
    config = Internal.conn_config(conn)

    :ok =
      session
      |> Map.update(:extra_payload, %{}, &Map.merge(&1, updates))
      |> Charon.SessionStore.upsert(config)
  end

  @doc """
  Fetch and validate the progress token from the current request.
  """
  @spec fetch_token(Conn.t()) ::
          {:ok, Charon.Models.Session.t()} | {:error, :invalid_authorization}
  def fetch_token(conn) do
    config = Internal.conn_config(conn)

    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, %{"session_id" => session_id, "user_id" => user_id}} <-
           config.token_factory_module.verify(token, config),
         session <- Charon.SessionStore.get(session_id, user_id, :proto, config) do
      {:ok, session}
    else
      _ -> {:error, :invalid_authorization}
    end
  end

  @doc """
  Creates a proto-session for the current flow. Uses user_id for session.id.
  """
  @spec set_flow_payload(Charon.Config.t(), Charon.Models.Session.t(), map()) ::
          :ok | {:error, :conflict | binary}
  def set_flow_payload(config, session, extra_payload_updates \\ %{}) do
    now = Charon.Internal.now()
    expiration = now + 60 * 15

    session
    |> Map.put(:expires_at, expiration)
    |> Map.update(:extra_payload, %{}, &Map.merge(&1, extra_payload_updates))
    |> Charon.SessionStore.upsert(config)
  end

  @doc """
  Get the proto-session corresponding to the current flow.
  """
  @spec get_flow_payload(Charon.Config.t(), binary()) :: Charon.Models.Session.t()
  def get_flow_payload(config, user_id) do
    case Charon.SessionStore.get(user_id, user_id, :proto, config) do
      nil ->
        now = Charon.Internal.now()
        expiration = now + 60 * 15

        %Charon.Models.Session{
          id: user_id,
          user_id: user_id,
          created_at: now,
          expires_at: expiration,
          type: :proto,
          refreshed_at: now,
          refresh_expires_at: expiration,
          refresh_token_id: 0,
          tokens_fresh_from: 0,
          extra_payload: %{}
        }

      session ->
        session
    end
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
