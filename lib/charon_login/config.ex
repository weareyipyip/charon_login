defmodule CharonLogin.Config do
  @moduledoc """
  Config module for `CharonLogin`.

      Charon.Config.from_enum(
        ...,
        optional_modules: %{
          CharonLogin => %{
            challenges: %{
              password: {CharonLogin.Challenges.PasswordChallenge, %{}},
              totp: {CharonLogin.Challenges.TOTPChallenge, %{}},
              email_code: {CharonLogin.Challenges.EmailCodeChallenge, %{}}
            },
            stages: %{
              stage_a: [:password],
              stage_b: [:totp, :email_code]
            },
            flows: %{
              login: [:stage_a, :stage_b]
            },
            success_callback: &MyApp.CharonLogin.login_successful/2
          }
        }
      )

  # Supported config options
  - `:challenges` (required) Map of (reusable) challenges.
    - `key` (required) Can be used to reference the challenge from stages.
    - `value` (required) A challenge in the format `{Module, opts}`.
  - `:stages` (required) Map of (reusable) stages.
    - `key` (required) Can be used to reference the stage from flows.
    - `value` (required) List of available challenges in the stage.
  - `:flows` (required) Map of flows.
    - `key` (required) Can be used to reference the flow from the client.
    - `value` (required) List of required stages in the flow.
  - `:success_callback` (required) Called with the flow name and user identifier when a flow has been completed successfully.
  """

  @enforce_keys [:stages, :flows]

  defstruct [
    :challenges,
    :stages,
    :flows,
    :success_callback
  ]

  @type challenges :: %{atom() => [{module(), map()}]}
  @type stages :: %{atom() => [atom()]}
  @type flows :: %{atom() => [atom()]}
  @type success_callback :: (atom(), String.t() -> map())

  @type t :: %__MODULE__{
          challenges: challenges(),
          stages: stages(),
          flows: flows(),
          success_callback: success_callback()
        }

  @doc """
  Build config struct from enumerable (useful for passing application environment).
  Raises for missing mandatory keys and sets defaults for optional keys.
  """
  @spec from_enum(Enum.t()) :: t()
  def from_enum(enum), do: struct!(__MODULE__, enum)
end
