defmodule CharonLogin.TestHelpers do
  def get_base_secret(), do: "0"

  def fetch_user(user_id) do
    case user_id do
      "invalid" ->
        nil

      uid ->
        {:ok,
         %{
           id: uid,
           totp_secret: <<1, 2, 3, 5, 8, 13, 21, 34>>,
           enabled_challenges: [],
           password_hash: :crypto.hash(:md5, "admin")
         }}
    end
  end

  def succes_callback(conn, _, _), do: %{conn | resp_body: "{\"challenge\": \"complete\"}"}

  def validate_password(pass, user_pass) do
    :crypto.hash(:md5, pass) == user_pass
  end

  def gen_send_otp() do
    fn otp, _user -> send(self(), {:otp, otp}) end
  end

  def get_challenges() do
    %{
      password: {CharonLogin.Challenges.Password, %{validate: &__MODULE__.validate_password/2}},
      totp: {CharonLogin.Challenges.TOTP, %{}},
      otp: {CharonLogin.Challenges.OTP, %{}}
    }
  end

  def get_config(challenges \\ get_challenges()) do
    [
      token_issuer: "Charon",
      get_base_secret: &__MODULE__.get_base_secret/0,
      session_store_module: Charon.SessionStore.LocalStore,
      optional_modules: %{
        CharonLogin => %{
          challenges: challenges,
          stages: %{
            password_stage: [:password],
            totp_stage: [:totp],
            otp_stage: [:otp]
          },
          flows: %{
            mfa: [:password_stage, :totp_stage, :otp_stage],
            no_op: []
          },
          success_callback: &__MODULE__.succes_callback/3,
          fetch_user: &__MODULE__.fetch_user/1
        }
      }
    ]
    |> Charon.Config.from_enum()
  end
end
