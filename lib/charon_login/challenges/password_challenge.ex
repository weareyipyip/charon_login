defmodule CharonLogin.PasswordChallenge do
  @behaviour CharonLogin.Challenge

  def type(), do: :password

  def execute(opts, conn) do
    {:ok, :completed}
  end
end
