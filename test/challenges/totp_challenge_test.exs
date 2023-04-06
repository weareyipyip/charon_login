defmodule CharonLogin.TOTPChallengeTest do
  use CharonLogin.ChallengeCase
  alias CharonLogin.Challenges.TOTP

  @secret <<68, 97, 110, 105, 32, 105, 115, 32, 99, 111, 111, 108, 33>>
  @user %{id: 0, totp_secret: @secret}
  @opts %{}

  describe "execute/3" do
    test "returns error on incorrect arguments" do
      assert {:error, :invalid_args} = TOTP.execute(nil, @opts, @user)
      assert {:error, :invalid_args} = TOTP.execute(%Plug.Conn{}, @opts, nil)
    end

    test "returns error on incorrect or outdated TOTP" do
      assert {:error, :invalid_otp} =
               TOTP.execute(%Plug.Conn{body_params: %{"otp" => "incorrect"}}, @opts, @user)

      now = System.os_time(:second)
      otp = NimbleTOTP.verification_code(@secret, time: now - 60)

      assert {:error, :invalid_otp} =
               TOTP.execute(%Plug.Conn{body_params: %{"otp" => otp}}, @opts, @user)
    end

    test "returns ok on correct TOTP generated within past 60 seconds" do
      now = System.os_time(:second)
      otp = NimbleTOTP.verification_code(@secret, time: now - 30)

      assert {:ok, :completed} =
               TOTP.execute(%Plug.Conn{body_params: %{"otp" => otp}}, @opts, @user)
    end

    test "returns error on already used TOTP" do
      otp = NimbleTOTP.verification_code(@secret)

      assert {:ok, :completed} =
               TOTP.execute(%Plug.Conn{body_params: %{"otp" => otp}}, @opts, @user)

      assert {:error, :invalid_otp} =
               TOTP.execute(%Plug.Conn{body_params: %{"otp" => otp}}, @opts, @user)
    end
  end
end
