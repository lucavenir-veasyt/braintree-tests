defmodule BraintreeTests.Braintree do
  def merchant_id() do
    braintree_config()
    |> Keyword.fetch!(:merchant_id)
  end

  def public_key() do
    braintree_config()
    |> Keyword.fetch!(:public_key)
  end

  def private_key() do
    braintree_config()
    |> Keyword.fetch!(:private_key)
  end

  defp braintree_config() do
    :braintree_tests
    |> Application.fetch_env!(:braintree)
  end
end
