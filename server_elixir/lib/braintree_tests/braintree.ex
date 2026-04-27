defmodule BraintreeTests.Braintree do
  @endpoint "https://payments.sandbox.braintree-api.com/graphql"
  @version "2026-04-13"

  def generate_client_token() do
    query = """
    mutation CreateClientToken($input: CreateClientTokenInput) {
      createClientToken(input: $input) {
        clientToken
      }
    }
    """

    Req.post!(
      url: @endpoint,
      auth: {:basic, "#{public_key()}:#{private_key()}"},
      headers: [{"braintree-version", @version}],
      json: %{
        "query" => query,
        "variables" => %{
          "input" => %{
            "clientToken" => %{
              "merchantAccountId" => merchant_id()
            }
          }
        }
      }
    )
  end

  def charge_with_nonce(nonce) when is_binary(nonce) do
    query = """
    mutation ChargeNonce($input: ChargePaymentMethodInput!) {
      chargePaymentMethod(input: $input) {
        transaction {
          id
          status
        }
      }
    }
    """

    Req.post!(
      url: @endpoint,
      auth: {:basic, "#{public_key()}:#{private_key()}"},
      headers: [{"braintree-version", @version}],
      json: %{
        "query" => query,
        "variables" => %{
          "input" => %{
            "paymentMethodId" => nonce,
            "transaction" => %{
              "amount" => "10.00"
            }
          }
        }
      }
    )
  end

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
