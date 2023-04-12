ExUnit.start()
Supervisor.start_link([Charon.SessionStore.LocalStore], strategy: :one_for_one)
