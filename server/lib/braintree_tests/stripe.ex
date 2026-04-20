defmodule BraintreeTests.Stripe do
  @base_url "https://api.stripe.com/v1"

  def payment_intent(amount) when is_integer(amount) do
    response =
      Req.post!(
        url: "#{@base_url}/payment_intents",
        auth: {:basic, "#{api_key()}:"},
        form: %{
          "amount" => amount,
          "currency" => "EUR",
          "payment_method_types[]" => "card"
        }
      )

    %{
      "client_secret" => response.body["client_secret"]
    }
  end

  def webhook_secret() do
    :braintree_tests
    |> Application.fetch_env!(:stripe)
    |> Keyword.fetch!(:webhook_secret)
  end

  def api_key() do
    :braintree_tests
    |> Application.fetch_env!(:stripe)
    |> Keyword.fetch!(:secret_key)
  end
end
