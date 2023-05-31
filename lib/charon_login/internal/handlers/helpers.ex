defmodule CharonLogin.Internal.Handlers.Helpers do
  alias CharonLogin.Internal
  alias Plug.Conn

  import Conn

  require Logger

  @type token :: %{flow_key: atom(), user_identifier: String.t(), incomplete_stages: [atom()]}

  @doc """
  Create a new progress token.
  """
  @spec create_session(Conn.t(), token()) :: {:ok, String.t()} | {:error, :unexpected_error}
  def create_session(conn, %{
        flow_key: flow_key,
        user_identifier: user_identifier,
        incomplete_stages: incomplete_stages
      }) do
    config = Internal.get_conn_config(conn)

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

    with :ok <- Charon.SessionStore.upsert(session, config),
         {:ok, token} <-
           config.token_factory_module.sign(
             %{"session_id" => session.id, "user_id" => session.user_id},
             config
           ) do
      {:ok, token}
    else
      {:error, error} ->
        Logger.warning("Failed to create token: #{inspect(error)}")
        {:error, :unexpected_error}
    end
  end

  @doc """
  Update the progress token.
  """
  @spec update_session(Conn.t(), Charon.Models.Session.t(), map()) ::
          :ok | {:error, :unexpected_error}
  def update_session(conn, session, updates) do
    config = Internal.get_conn_config(conn)

    case session
         |> Map.update(:extra_payload, %{}, &Map.merge(&1, updates))
         |> Charon.SessionStore.upsert(config) do
      :ok ->
        :ok

      {:error, error} ->
        Logger.warning("Failed to update token: #{inspect(error)}")
        {:error, :unexpected_error}
    end
  end

  @doc """
  Delete the progress token.
  """
  @spec delete_session(Conn.t(), Charon.Models.Session.t()) :: :ok | {:error, :unexpected_error}
  def delete_session(conn, session) do
    config = Internal.get_conn_config(conn)

    case Charon.SessionStore.delete(session.id, session.user_id, :proto, config) do
      :ok ->
        :ok

      {:error, error} ->
        Logger.warning("Failed to delete token: #{inspect(error)}")
        {:error, :unexpected_error}
    end
  end

  @doc """
  Fetch and validate the progress token from the current request.
  """
  @spec get_session(Conn.t()) ::
          {:ok, Charon.Models.Session.t()} | {:error, :invalid_authorization}
  def get_session(conn) do
    config = Internal.get_conn_config(conn)

    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, %{"session_id" => session_id, "user_id" => user_id}} <-
           config.token_factory_module.verify(token, config),
         session when is_struct(session, Charon.Models.Session) <-
           Charon.SessionStore.get(session_id, user_id, :proto, config) do
      {:ok, session}
    else
      _ -> {:error, :invalid_authorization}
    end
  end

  @doc """
  Creates a proto-session for the current flow. Uses user_id for session.id.
  """
  @spec set_user_state(Charon.Config.t(), Charon.Models.Session.t(), map()) ::
          :ok | {:error, :conflict | binary}
  def set_user_state(config, session, extra_payload_updates \\ %{}) do
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
  @spec get_user_state(Charon.Config.t(), binary()) :: Charon.Models.Session.t()
  def get_user_state(config, user_id) do
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
