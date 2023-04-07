defmodule CharonLogin.FastConfig do
  def get_config(),
    do: raise("Missing config for Charon Login, did you call `use CharonLogin, @charon_config`?")
end
