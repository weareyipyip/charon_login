defmodule CharonLogin.Challenges.Password do
  @moduledoc """
  Verifies user password using given callback function.
  json
      {
        "password": "correcthorsebatterystaple"
      }
  """
  @behaviour CharonLogin.Challenge

  @impl true
  def type(), do: :password

  @impl true
  def execute(
        %{body: %{"password" => password}} = _conn,
        %{validate: validate} = _opts,
        %{password: user_password} = _user
      ) do
    if validate.(password, user_password) do
      {:ok, :completed}
    else
      # incorrect password; continue challenge
      {:ok, :continue}
    end
  end

  def execute(_, _, _), do: {:error, :invalid_args}
end
