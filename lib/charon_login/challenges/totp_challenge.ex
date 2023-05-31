if Code.ensure_loaded?(NimbleTOTP) do
  defmodule CharonLogin.Challenges.TOTP do
    @moduledoc """
    Verifies a Time-based One-Time Password using NimbleTOTP.
    Succeeds if given password is valid for this or the previous 30-second cycle.
    Passwords can only be used once.

    Charon config:

        CharonLogin %{
          challenges: %{
            challenge_name: {CharonLogin.Challenges.TOTP, %{}}
          }
        }

    Request JSON body:

    ```json
    {
      "otp": "123456"
    }
    ```
    """
    alias CharonLogin.Internal

    import CharonLogin.Internal.Handlers.Helpers

    @behaviour CharonLogin.Challenge

    @impl true
    def type(), do: :totp

    @impl true
    def execute(
          %Plug.Conn{body_params: %{"otp" => password}} = conn,
          _opts,
          %{totp_secret: secret, id: user_id} = _user
        ) do
      config = Internal.conn_config(conn)
      now = Charon.Internal.now()
      session = get_user_state(config, user_id)
      since = Map.get(session.extra_payload, :totp_last_used, 0)

      with {:ok, :valid} <- validate_totp(secret, password, now, since),
           :ok <- set_user_state(config, session, %{totp_last_used: now}) do
        {:ok, :completed}
      end
    end

    def execute(_, _, _), do: {:error, :invalid_args}

    defp validate_totp(secret, password, now, since) do
      if NimbleTOTP.valid?(secret, password, time: now, since: since) or
           NimbleTOTP.valid?(secret, password, time: now - 30, since: since) do
        {:ok, :valid}
      else
        {:error, :invalid_otp}
      end
    end
  end
else
  defmodule CharonLogin.Challenges.TOTP do
    @impl true
    def execute(_, _, _), do: raise("TOTP challenge relies on NimbleTOTP dependency.")
  end
end
