defmodule CharonLogin.Internal.Handlers.NotFound do
  @moduledoc """
  Handles unknown requests.
  """

  alias Plug.Conn

  import CharonLogin.Internal.Handlers.Helpers

  @doc """
  Handle the request.
  """
  @spec handle(Conn.t()) :: Conn.t()
  def handle(conn) do
    send_json(conn, %{error: :not_found}, 404)
  end
end
