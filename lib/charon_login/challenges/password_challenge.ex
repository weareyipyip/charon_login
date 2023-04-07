defmodule CharonLogin.Challenges.Password do
  @moduledoc """
  Verifies user password using given validate function.

  Charon config:

      CharonLogin %{
        challenges: %{
          challenge_name: {CharonLogin.Challenges.Password, %{validate: &MyValidator/2}}
        }
      }

  Request JSON body:

  ```json
  {
    "password": "correcthorsebatterystaple"
  }
  ```
  """
  @behaviour CharonLogin.Challenge

  @impl true
  def type(), do: :password

  @impl true

  def execute(
        %Plug.Conn{body_params: %{"password" => password}} = _conn,
        %{validate: validate} = _opts,
        %{password_hash: user_password} = _user
      ) do
    if validate.(password, user_password) do
      {:ok, :completed}
    else
      # incorrect password; continue challenge
      {:error, :incorrect_password}
    end
  end

  def execute(_, _, _), do: {:error, :invalid_args}
end
