defmodule CharonLogin.PasswordChallengeTest do
  use ExUnit.Case
  alias CharonLogin.Internal
  alias CharonLogin.Challenges.Password

  @password "swordfish"
  @user %{password_hash: :crypto.hash(:md5, @password)}
  @config CharonLogin.TestHelpers.get_config()
  @opts %{validate: &CharonLogin.TestHelpers.validate_password/2}

  defp gen_conn(fields) do
    struct(Plug.Conn, fields)
    |> Internal.put_conn_config(@config)
  end

  describe "execute/3" do
    test "returns error on incorrect arguments" do
      conn = gen_conn(%{body_params: %{"password" => "incorrect!"}})
      assert {:error, :invalid_args} = Password.execute(nil, @opts, @user)
      assert {:error, :invalid_args} = Password.execute(conn, nil, @user)
      assert {:error, :invalid_args} = Password.execute(conn, @opts, nil)
    end

    test "returns error on incorrect password" do
      conn = gen_conn(%{body_params: %{"password" => "incorrect!"}})
      assert {:error, :incorrect_password} = Password.execute(conn, @opts, @user)
    end

    test "returns ok on correct password" do
      conn = gen_conn(%{body_params: %{"password" => @password}})
      assert {:ok, :completed} = Password.execute(conn, @opts, @user)
    end
  end
end
