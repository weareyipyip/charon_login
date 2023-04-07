defmodule MfaTest do
  use CharonLogin.ConnCase

  defp post_conn(path, body, token \\ "") do
    %{resp_body: resp_body} =
      conn(:post, path, body)
      |> put_req_header("authorization", "Bearer #{token}")
      |> CharonLogin.TestModule.Plugs.LoginEndpoint.call(%{})

    resp_parsed = Jason.decode!(resp_body)
    {Map.get(resp_parsed, "token"), resp_parsed}
  end

  describe "Succesfully walk through a 2FA flow" do
    test "happy path through whole 2FA" do
      # Send user in conn
      # Send token
      # enabled_challenged [:password, :totp], client-side validation
      # Token contains remaining
      # in Auth header `bearer ${token}`
      # new token each request

      assert {token, %{"stages" => [%{"key" => "password_stage"}, %{"key" => "totp_stage"}]}} =
               post_conn("/flows/mfa/start", %{"user_identifier" => "00"})

      assert {token, _} =
               post_conn(
                 "/stages/password_stage/challenges/password/execute",
                 %{"password" => "admin"},
                 token
               )

      %{totp_secret: secret} = fetch_user(nil)
      totp_code = NimbleTOTP.verification_code(secret)

      assert {token, _} =
               post_conn(
                 "/stages/totp_stage/challenges/totp/execute",
                 %{"otp" => totp_code},
                 token
               )

      conn(:post, "/complete")
      |> put_req_header("authorization", "Bearer #{token}")
      |> CharonLogin.TestModule.Plugs.LoginEndpoint.call(%{})
    end
  end
end
