defmodule CharonLogin.PasswordChallengeTest do
  use ExUnit.Case
  alias CharonLogin.Challenges.Password

  @password "swordfish"
  @user %{password: :crypto.hash(:md5, @password)}
  @conn %{body_params: %{"password" => @password}}
  @opts %{validate: &__MODULE__.validate_password/2}

  describe "execute/3" do
    test "returns error on incorrect arguments" do
      assert {:error, :invalid_args} = Password.execute(nil, @opts, @user)
      assert {:error, :invalid_args} = Password.execute(@conn, nil, @user)
      assert {:error, :invalid_args} = Password.execute(@conn, @opts, nil)
    end

    test "returns continue on incorrect password" do
      assert {:ok, :continue} =
               Password.execute(%{body_params: %{"password" => "incorrect!"}}, @opts, @user)
    end

    test "returns complete on correct password" do
      assert {:ok, :completed} = Password.execute(@conn, @opts, @user)
    end
  end

  def validate_password(pass, user_pass) do
    :crypto.hash(:md5, pass) == user_pass
  end
end
