defmodule BraintreeTestsWeb.StripeController do
  use BraintreeTestsWeb, :controller

  alias BraintreeTests.Stripe

  def payment(conn, %{"amount" => amount}) do
    {amount, _} = Integer.parse(amount)
    result = Stripe.payment_intent(amount)
    json(conn, result)
  end
end
