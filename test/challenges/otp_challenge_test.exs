defmodule CharonLogin.PasswordChallengeTest do
  use ExUnit.Case
  alias CharonLogin.Internal
  alias CharonLogin.Challenges.OTP

  @config CharonLogin.TestHelpers.get_config()

  defp gen_conn(fields) do
    struct(Plug.Conn, fields)
    |> Internal.put_conn_config(@config)
  end

  defp gen_send_otp() do
    fn otp, _user -> send(self(), {:otp, otp}) end
  end

  defp get_otp(opts, user) do
    conn = gen_conn(%{})
    assert {:ok, :continue} = OTP.execute(conn, opts, user)

    receive do
      {:otp, otp} -> otp
    end
  end

  setup do
    [otp_opts: %{send_otp: gen_send_otp()}, user: %{id: :rand.bytes(16)}]
  end

  describe "execute/3" do
    test "returns error on incorrect arguments", %{otp_opts: opts, user: user} do
      conn = gen_conn(%{})
      assert {:error, :invalid_args} = OTP.execute(nil, opts, user)
      assert {:error, :invalid_args} = OTP.execute(conn, nil, user)
      assert {:error, :invalid_args} = OTP.execute(conn, opts, nil)
    end

    test "generates and validates a one-time password", %{otp_opts: opts, user: user} do
      otp = get_otp(opts, user)
      conn = gen_conn(%{body_params: %{"otp" => otp}})
      assert {:ok, :complete} = OTP.execute(conn, opts, user)
    end

    test "errors on validation before generation of otp", %{user: user} do
      conn = gen_conn(%{body_params: %{"otp" => nil}})
      assert {:error, :no_generated_otp} = OTP.execute(conn, nil, user)
    end

    test "errors on invalid otp", %{user: user} do
      opts = %{send_otp: fn _, _ -> :ok end}
      assert {:ok, :continue} = OTP.execute(gen_conn(%{}), opts, user)
      conn = gen_conn(%{body_params: %{"otp" => :invalid}})
      assert {:error, :invalid_otp} = OTP.execute(conn, opts, user)
    end

    test "deletes otp after usage" , %{otp_opts: opts, user: user} do
      otp = get_otp(opts, user)
      conn = gen_conn(%{body_params: %{"otp" => otp}})
      assert {:ok, :complete} = OTP.execute(conn, opts, user)
      assert {:error, :no_generated_otp} = OTP.execute(conn, nil, user)
    end
  end
end
