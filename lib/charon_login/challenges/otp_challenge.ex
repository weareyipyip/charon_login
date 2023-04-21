defmodule CharonLogin.Challenges.OTP do
  @moduledoc """
  OTP challenge
  """

  alias CharonLogin.Internal

  import CharonLogin.Internal.Handlers.Helpers

  @behaviour CharonLogin.Challenge

  @impl true
  def type(), do: :otp

  @impl true
  def execute(%Plug.Conn{body_params: %{"otp" => password}} = conn, _opts, %{id: user_id} = _user) do
    config = Internal.conn_config(conn)
    session = get_flow_payload(config, user_id)

    case Map.get(session.extra_payload, :generated_otp) do
      nil ->
        {:error, :no_generated_password}

      otp ->
        if otp == password do
          {:ok, :complete}
        else
          {:error, :invalid_password}
        end
    end
  end

  def execute(%Plug.Conn{} = conn, %{send_otp: send_otp} = _opts, %{id: user_id} = user) do
    otp = random_digits()

    config = Internal.conn_config(conn)
    session = get_flow_payload(config, user_id)

    case set_flow_payload(config, session, %{generated_otp: otp}) do
      :ok ->
        send_otp.(otp, user)
        {:ok, :continue}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def execute(_, _, _), do: {:error, :invalid_args}

  defp random_digits() do
    :crypto.strong_rand_bytes(3)
    |> :binary.decode_unsigned()
    |> rem(10 ** 5)
  end
end
