defmodule BraintreeTests.Repo do
  use Ecto.Repo,
    otp_app: :braintree_tests,
    adapter: Ecto.Adapters.Postgres
end
