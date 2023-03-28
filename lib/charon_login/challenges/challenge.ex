defmodule CharonLogin.Challenge do
  @doc """
  Get the key for this challenge, which can be used by the client to:
  * Determine which screen should be shown to the user
  * Determine which steps are required to complete the challenge
  """
  @callback type() :: atom()

  @doc """
  Execute a step of the challenge.
  The implementation of a challenge can have any number of steps.
  For example, some challenges may require a setup step to send an OTP to the user.
  It is up to the client to call all required steps in the correct order.
  The challenge should return `{:ok, :continue}` for each successful step while it is not fully completed.
  When the challenge has been fully completed, it should return `{:ok, :completed}`.
  """
  @callback execute(map(), map()) :: {:ok, :continue | :completed} | {:error, String.t()}
end
