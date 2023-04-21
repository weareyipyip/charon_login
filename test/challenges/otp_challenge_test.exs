defmodule CharonLogin.PasswordChallengeTest do
  use ExUnit.Case
  alias CharonLogin.Internal
  alias CharonLogin.Challenges.OTP

  @config CharonLogin.TestHelpers.get_config()
  @user %{id: "0"}

  defp gen_conn(fields) do
    struct(Plug.Conn, fields)
    |> Internal.put_conn_config(@config)
  end

  defp gen_send_otp() do
    fn otp, _user -> send(self(), {:otp, otp}) end
  end

  defp get_otp(opts) do
    conn = gen_conn(%{})
    assert {:ok, :continue} = OTP.execute(conn, opts, @user)
    receive do
      {:otp, otp} -> otp
    end
  end

  setup do
    [otp_opts: %{send_otp: gen_send_otp()}]
  end

  describe "execute/3" do
    test "generates and validates a one-time password", %{otp_opts: opts} do
      otp = get_otp(opts)
      conn = gen_conn(%{body_params: %{"otp" => otp}})
      assert {:ok, :complete} = OTP.execute(conn, opts, @user)
    end
  end
end
