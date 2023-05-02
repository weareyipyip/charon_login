defmodule MfaTest do
  use CharonLogin.ConnCase

  @config CharonLogin.TestHelpers.get_config()

  defp post_conn(path, body \\ %{}, token \\ "", config \\ @config) do
    %{resp_body: resp_body} =
      conn(:post, path, body)
      |> put_req_header("authorization", "Bearer #{token}")
      |> CharonLogin.Endpoint.call(config: config)

    Jason.decode!(resp_body)
  end

  describe "2FA flow" do
    test "happy path through whole flow" do
      user_id = Charon.Internal.Crypto.random_url_encoded(16)

      assert %{
               "stages" => [
                 %{"key" => "password_stage"},
                 %{"key" => "totp_stage"},
                 %{"key" => "otp_stage"}
               ],
               "token" => token
             } = post_conn("/flows/mfa/start", %{"user_identifier" => user_id})

      assert %{"result" => "completed"} =
               post_conn(
                 "/stages/password_stage/challenges/password/execute",
                 %{"password" => "admin"},
                 token
               )

      {:ok, %{totp_secret: secret}} = fetch_user(user_id)
      totp_code = NimbleTOTP.verification_code(secret)

      assert %{"result" => "completed"} =
               post_conn(
                 "/stages/totp_stage/challenges/totp/execute",
                 %{"otp" => totp_code},
                 token
               )

      new_challenges =
        CharonLogin.TestHelpers.get_challenges()
        |> Map.put(:otp, {CharonLogin.Challenges.OTP, %{send_otp: gen_send_otp()}})

      new_config = CharonLogin.TestHelpers.get_config(new_challenges)

      assert %{"result" => "continue"} =
               post_conn(
                 "/stages/otp_stage/challenges/otp/execute",
                 %{},
                 token,
                 new_config
               )

      otp =
        receive do
          {:otp, otp} -> otp
        after
          1_000 -> raise("Didn't receive one-time password.")
        end

      assert %{"result" => "completed"} =
               post_conn(
                 "/stages/otp_stage/challenges/otp/execute",
                 %{"otp" => otp},
                 token,
                 new_config
               )

      assert %{"flow" => "complete"} = post_conn("/complete", %{}, token)
    end

    test "error on invalid url" do
      assert %{"error" => "not_found"} = post_conn("/atlantis")
    end

    test "error when starting non-existent flow" do
      assert %{"error" => "flow_not_found"} = post_conn("/flows/styx/start")
    end

    test "error on invalid user" do
      assert %{"error" => "user_not_found"} =
               post_conn("/flows/mfa/start", %{"user_identifier" => "invalid"})
    end

    test "error without user_identifier" do
      assert %{"error" => "invalid_user"} = post_conn("/flows/mfa/start")
    end

    test "error on trying to skip a stage" do
      user_id = Charon.Internal.Crypto.random_url_encoded(16)

      assert %{"token" => token} = post_conn("/flows/mfa/start", %{"user_identifier" => user_id})

      assert %{"error" => "is_not_current_stage"} =
               post_conn(
                 "/stages/totp_stage/challenges/totp/execute",
                 %{},
                 token
               )
    end

    test "error on incorrect challenge" do
      user_id = Charon.Internal.Crypto.random_url_encoded(16)

      assert %{"token" => token} = post_conn("/flows/mfa/start", %{"user_identifier" => user_id})

      assert %{"error" => "is_invalid_challenge"} =
               post_conn(
                 "/stages/password_stage/challenges/totp/execute",
                 %{},
                 token
               )
    end

    test "error on trying to complete flow without stages" do
      user_id = Charon.Internal.Crypto.random_url_encoded(16)

      assert %{
               "stages" => [
                 %{"key" => "password_stage"},
                 %{"key" => "totp_stage"},
                 %{"key" => "otp_stage"}
               ],
               "token" => token
             } = post_conn("/flows/mfa/start", %{"user_identifier" => user_id})

      assert %{"error" => "incomplete_stages"} = post_conn("/complete", %{}, token)
    end
  end

  describe "empty flow" do
    test "error when trying to complete flow more than once" do
      user_id = Charon.Internal.Crypto.random_url_encoded(16)

      assert %{"token" => token} =
               post_conn("/flows/no_op/start", %{"user_identifier" => user_id})

      assert %{"flow" => "complete"} = post_conn("/complete", %{}, token)
      assert %{"error" => "invalid_authorization"} = post_conn("/complete", %{}, token)
    end
  end

  describe "skippable flow" do
    test "allows user to skip challenges after completing flow" do
      user_id = Charon.Internal.Crypto.random_url_encoded(16)

      assert %{
               "stages" => [%{"key" => "password_stage"}],
               "token" => token
             } = post_conn("/flows/skippable/start", %{"user_identifier" => user_id})

      assert %{"result" => "completed"} =
               post_conn(
                 "/stages/password_stage/challenges/password/execute",
                 %{"password" => "admin", "skip_next_time" => true},
                 token
               )

      assert [skip_token] =
               conn(:post, "/complete")
               |> put_req_header("authorization", "Bearer #{token}")
               |> CharonLogin.Endpoint.call(config: @config)
               |> Plug.Conn.get_resp_header("x-skip-token")

      assert %{"token" => token, "stages" => []} =
               conn(:post, "/flows/skippable/start", %{"user_identifier" => user_id})
               |> put_req_header("x-skip-token", skip_token)
               |> CharonLogin.Endpoint.call(config: @config)
               |> Map.get(:resp_body)
               |> Jason.decode!()

      assert %{"flow" => "complete"} = post_conn("/complete", %{}, token)
    end

    test "can't skip unskippable stages" do
      user_id = Charon.Internal.Crypto.random_url_encoded(16)

      assert %{
               "stages" => [%{"key" => "password_stage"}],
               "token" => token
             } = post_conn("/flows/unskippable/start", %{"user_identifier" => user_id})

      assert %{"result" => "completed"} =
               post_conn(
                 "/stages/password_stage/challenges/password/execute",
                 %{"password" => "admin", "skip_next_time" => true},
                 token
               )

      assert [skip_token] =
               conn(:post, "/complete")
               |> put_req_header("authorization", "Bearer #{token}")
               |> CharonLogin.Endpoint.call(config: @config)
               |> Plug.Conn.get_resp_header("x-skip-token")

      assert %{"token" => token, "stages" => [%{"key" => "password_stage"}]} =
               conn(:post, "/flows/unskippable/start", %{"user_identifier" => user_id})
               |> put_req_header("x-skip-token", skip_token)
               |> CharonLogin.Endpoint.call(config: @config)
               |> Map.get(:resp_body)
               |> Jason.decode!()

      assert %{"error" => "incomplete_stages"} = post_conn("/complete", %{}, token)
    end

    test "can't skip different flow" do
      user_id = Charon.Internal.Crypto.random_url_encoded(16)

      assert %{
               "stages" => [%{"key" => "password_stage"}],
               "token" => token
             } = post_conn("/flows/skippable/start", %{"user_identifier" => user_id})

      assert %{"result" => "completed"} =
               post_conn(
                 "/stages/password_stage/challenges/password/execute",
                 %{"password" => "admin", "skip_next_time" => true},
                 token
               )

      assert [skip_token] =
               conn(:post, "/complete")
               |> put_req_header("authorization", "Bearer #{token}")
               |> CharonLogin.Endpoint.call(config: @config)
               |> Plug.Conn.get_resp_header("x-skip-token")

      assert %{"token" => _token, "stages" => [%{"key" => "password_stage"}]} =
               conn(:post, "/flows/other_skippable/start", %{"user_identifier" => user_id})
               |> put_req_header("x-skip-token", skip_token)
               |> CharonLogin.Endpoint.call(config: @config)
               |> Map.get(:resp_body)
               |> Jason.decode!()
    end

    test "can't skip as a different user" do
      user_id = Charon.Internal.Crypto.random_url_encoded(16)

      assert %{
               "stages" => [%{"key" => "password_stage"}],
               "token" => token
             } = post_conn("/flows/skippable/start", %{"user_identifier" => user_id})

      assert %{"result" => "completed"} =
               post_conn(
                 "/stages/password_stage/challenges/password/execute",
                 %{"password" => "admin", "skip_next_time" => true},
                 token
               )

      assert [skip_token] =
               conn(:post, "/complete")
               |> put_req_header("authorization", "Bearer #{token}")
               |> CharonLogin.Endpoint.call(config: @config)
               |> Plug.Conn.get_resp_header("x-skip-token")

      assert %{"token" => _token, "stages" => [%{"key" => "password_stage"}]} =
               conn(:post, "/flows/skippable/start", %{
                 "user_identifier" => Charon.Internal.Crypto.random_url_encoded(16)
               })
               |> put_req_header("x-skip-token", skip_token)
               |> CharonLogin.Endpoint.call(config: @config)
               |> Map.get(:resp_body)
               |> Jason.decode!()
    end
  end
end
