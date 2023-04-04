# CharonLogin

Modular authentication procedures.

## Usage

A **flow** is used to represent the steps an account needs to take to be authenticated for a certain
action. A flow could check for email + password validation or a full multi-factor authentication
procedure.

A flow consists of one or multiple **stages**. To complete a flow all stages in it need to be
completed. The stages in a flow are ordered and neet to be fulfilled one at a time.

A **challenge** represent a single authentication method. E.g. password validation or an OAuth
token. Stages contain one or multiple challenges. Only one challenge needs to be fulfilled to
complete a stage.

### Example

The example configuration defines a flow for two-factor authentication.

The user first needs to log into their account using an email and password. This is implemented
within `CharonLogin.PasswordChallenge`.

After that the user needs to fill in a one-time password. They can choose to get it sent via
email or SMS. The email and SMS implementations are seperate challenges, wrapped up in the
otp stage.

```elixir
config :my_project, :charon,
  ...
  optional_modules: %{
    CharonLogin => %{
      challenges: %{
        password: {CharonLogin.PasswordChallenge, %{}},
        sms: {MyProject.SmsChallenge, %{}},
        email: {MyProject.EmailChallenge, %{}}
      },
      stages: %{
        stage_password: [:password],
        stage_otp: [:sms, :email]
      },
      flows: %{
        login_2fa: [:stage_password, :stage_otp]
      },
      success_callback: &MyProject.success_callback/2,
      fetch_user: &MyProject.fetch_user/1
  }
}
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `charon_login` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:charon_login, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/charon_login>.

