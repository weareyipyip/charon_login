defmodule CharonLogin.Challenges.OTP do
  @moduledoc """
  Generates and validates a 5-digit one-time password.
  The client must implement a communication method (e.g. SMS, e-mail).

  Charon config:

      CharonLogin %{
        challenges: %{
          challenge_name: {CharonLogin.Challenges.OTP, %{send_otp: &my_sender/2}}
        }
      }

  Genrating a password doesn't require any data in the JSON body.

  Validation request JSON body:

  ```json
  {
    "otp": 12345
  }
  ```
  """

  alias CharonLogin.Internal

  import CharonLogin.Internal.Handlers.Helpers

  @behaviour CharonLogin.Challenge

  @impl true
  def type(), do: :otp

  @impl true
  def execute(%Plug.Conn{body_params: %{"otp" => password}} = conn, _opts, %{id: user_id} = _user) do
    config = Internal.get_conn_config(conn)
    session = get_user_state(config, user_id)

    case Map.get(session.extra_payload, :generated_otp) do
      nil ->
        {:error, :no_generated_otp}

      ^password ->
        set_user_state(config, session, %{generated_otp: nil})
        {:ok, :completed}

      _ ->
        {:error, :invalid_otp}
    end
  end

  def execute(%Plug.Conn{} = conn, %{send_otp: send_otp} = _opts, %{id: user_id} = user) do
    otp = Charon.Internal.Crypto.strong_random_digits(5)

    config = Internal.get_conn_config(conn)
    session = get_user_state(config, user_id)

    case set_user_state(config, session, %{generated_otp: otp}) do
      :ok ->
        send_otp.(otp, user)
        {:ok, :continue}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def execute(_, _, _), do: {:error, :invalid_args}
end
