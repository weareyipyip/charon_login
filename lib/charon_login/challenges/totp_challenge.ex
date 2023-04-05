defmodule CharonLogin.Challenges.TOTP do
  @moduledoc """
  Verifies a Timed One-Time Password using NimbleTOTP.
  Succeeds if given password is valid for this or the previous 30-second cycle.

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
  @behaviour CharonLogin.Challenge

  @impl true
  def type(), do: :totp

  # TODO: blacklist keys that have already been used
  @impl true
  def execute(
        %Plug.Conn{body_params: %{"otp" => password}} = _conn,
        _opts,
        %{totp_secret: secret} = _user
      ) do
    base_time = Elixir.System.os_time(:second)

    if NimbleTOTP.valid?(secret, password, time: base_time) or
         NimbleTOTP.valid?(secret, password, time: base_time - 30) do
      {:ok, :completed}
    else
      {:ok, :continue}
    end
  end

  def execute(_, _, _), do: {:error, :invalid_args}
end
