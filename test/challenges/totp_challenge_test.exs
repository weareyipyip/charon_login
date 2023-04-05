defmodule CharonLogin.TOTPChallengeTest do
  use ExUnit.Case
  alias CharonLogin.Challenges.TOTP

  @secret NimbleTOTP.secret()
  @user %{totp_secret: @secret}
  @opts %{}

  describe "execute/3" do
    test "returns error on incorrect arguments" do
      assert {:error, :invalid_args} = TOTP.execute(nil, @opts, @user)
      assert {:error, :invalid_args} = TOTP.execute(@conn, @opts, nil)
    end

    test "returns continue on incorrect or outdated TOTP" do
      assert {:ok, :continue} =
               TOTP.execute(%Plug.Conn{body_params: %{"otp" => "incorrect"}}, @opts, @user)

      now = System.os_time(:second)
      otp = NimbleTOTP.verification_code(@secret, time: now - 60)

      assert {:ok, :continue} =
               TOTP.execute(%Plug.Conn{body_params: %{"otp" => otp}}, @opts, @user)
    end

    test "returns complete on correct TOTP generated within past 60 seconds" do
      now = System.os_time(:second)
      otp = NimbleTOTP.verification_code(@secret)

      assert {:ok, :completed} =
               TOTP.execute(%Plug.Conn{body_params: %{"otp" => otp}}, @opts, @user)

      otp = NimbleTOTP.verification_code(@secret, time: now - 30)

      assert {:ok, :completed} =
               TOTP.execute(%Plug.Conn{body_params: %{"otp" => otp}}, @opts, @user)
    end
  end
end
