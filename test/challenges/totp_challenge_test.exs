defmodule CharonLogin.TOTPChallengeTest do
  use ExUnit.Case
  alias CharonLogin.Challenges.TOTP
  alias CharonLogin.Internal

  @config CharonLogin.TestHelpers.get_config()
  @secret <<68, 97, 110, 105, 32, 105, 115, 32, 99, 111, 111, 108, 33>>
  @user %{id: "0", totp_secret: @secret}
  @opts %{}

  defp gen_conn(fields) do
    struct(Plug.Conn, fields)
    |> Internal.put_conn_config(@config)
  end

  describe "execute/3" do
    test "returns error on incorrect arguments" do
      assert {:error, :invalid_args} = TOTP.execute(nil, @opts, @user)

      conn = gen_conn(%{})
      assert {:error, :invalid_args} = TOTP.execute(conn, @opts, nil)
    end

    test "returns error on incorrect or outdated TOTP" do
      conn = gen_conn(%{body_params: %{"otp" => "incorrect"}})
      assert {:error, :invalid_otp} = TOTP.execute(conn, @opts, @user)

      now = System.os_time(:second)
      otp = NimbleTOTP.verification_code(@secret, time: now - 60)

      conn = gen_conn(%{body_params: %{"otp" => otp}})
      assert {:error, :invalid_otp} = TOTP.execute(conn, @opts, @user)
    end

    test "returns ok on correct TOTP generated within past 60 seconds" do
      now = System.os_time(:second)
      otp = NimbleTOTP.verification_code(@secret, time: now - 30)

      conn = gen_conn(%{body_params: %{"otp" => otp}})
      assert {:ok, :completed} = TOTP.execute(conn, @opts, @user)
    end

    test "returns error on already used TOTP" do
      new_user = %{@user | id: "1"}
      otp = NimbleTOTP.verification_code(@secret)

      conn = gen_conn(%{body_params: %{"otp" => otp}})
      assert {:ok, :completed} = TOTP.execute(conn, @opts, new_user)

      conn = gen_conn(%{body_params: %{"otp" => otp}})
      assert {:error, :invalid_otp} = TOTP.execute(conn, @opts, new_user)
    end
  end
end
