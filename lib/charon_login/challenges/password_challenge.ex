defmodule CharonLogin.PasswordChallenge do
  @behaviour CharonLogin.Challenge

  def type(), do: :password

  def execute(opts, user) do
    {:ok, :completed}
  end
end
