defmodule MfaTest do
  use CharonLogin.ConnCase

  @uid "1234-abcd"
  @config CharonLogin.TestHelpers.get_config()

  defp post_conn(path, body \\ %{}, token \\ "") do
    %{resp_body: resp_body} =
      conn(:post, path, body)
      |> put_req_header("authorization", "Bearer #{token}")
      |> CharonLogin.Endpoint.call(config: @config)

    Jason.decode!(resp_body)
  end

  describe "Succesfully walk through a 2FA flow" do
    test "happy path through whole 2FA" do
      assert %{
               "stages" => [%{"key" => "password_stage"}, %{"key" => "totp_stage"}],
               "token" => token
             } = post_conn("/flows/mfa/start", %{"user_identifier" => @uid})

      assert %{} =
               post_conn(
                 "/stages/password_stage/challenges/password/execute",
                 %{"password" => "admin"},
                 token
               )

      {:ok, %{totp_secret: secret}} = fetch_user(@uid)
      totp_code = NimbleTOTP.verification_code(secret)

      assert %{} =
               post_conn(
                 "/stages/totp_stage/challenges/totp/execute",
                 %{"otp" => totp_code},
                 token
               )

      assert %{"challenge" => "complete"} = post_conn("/complete", %{}, token)
    end

    test "error on invalid url" do
      assert %{"error" => "not_found"} = post_conn("/atlantis")
    end

    test "error when starting non-existant flow" do
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
      assert %{"token" => token} = post_conn("/flows/mfa/start", %{"user_identifier" => @uid})

      assert %{"error" => "is_not_current_stage"} =
               post_conn(
                 "/stages/totp_stage/challenges/totp/execute",
                 %{},
                 token
               )
    end

    test "error on incorrect challenge" do
      assert %{"token" => token} = post_conn("/flows/mfa/start", %{"user_identifier" => @uid})

      assert %{"error" => "is_invalid_challenge"} =
               post_conn(
                 "/stages/password_stage/challenges/totp/execute",
                 %{},
                 token
               )
    end

    test "error on trying to complete flow without stages" do
      assert %{
               "stages" => [%{"key" => "password_stage"}, %{"key" => "totp_stage"}],
               "token" => token
             } = post_conn("/flows/mfa/start", %{"user_identifier" => @uid})

      assert %{"error" => "incomplete_stages"} = post_conn("/complete", %{}, token)
    end
  end
end
