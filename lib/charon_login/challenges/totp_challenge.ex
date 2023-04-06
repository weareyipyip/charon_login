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
  import CharonLogin.Internal.Handlers.Helpers
  @behaviour CharonLogin.Challenge

  @impl true
  def type(), do: :totp

  if(Code.ensure_loaded?(NimbleTOTP)) do
    @impl true
    def execute(
          %Plug.Conn{body_params: %{"otp" => password}} = _conn,
          _opts,
          %{totp_secret: secret, id: user_id} = _user
        ) do
      now = Elixir.System.os_time(:second)

      since =
        case get_flow_payload(user_id) do
          %{totp_last_used: last_used} -> last_used
          _ -> 0
        end

      if NimbleTOTP.valid?(secret, password, time: now, since: since) or
           NimbleTOTP.valid?(secret, password, time: now - 30, since: since) do
        set_flow_payload(user_id, totp_last_used: now)
        {:ok, :completed}
      else
        {:error, :invalid_otp}
      end
    end

    def execute(_, _, _), do: {:error, :invalid_args}
  else
    def execute(_, _, _), do: raise("TOTP challenge relies on NimbleTOTP dependency.")
  end
end
