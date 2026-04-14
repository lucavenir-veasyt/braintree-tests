defmodule BraintreeTestsWeb.BraintreeController do
  use BraintreeTestsWeb, :controller

  alias BraintreeTests.Braintree

  def generate_client_token(conn, _params) do
    result = Braintree.generate_client_token()
    json(conn, result.body)
  end

  def charge_with_nonce(conn, %{"nonce" => nonce}) do
    response = Braintree.charge_with_nonce(nonce)
    json(conn, response.body)
  end
end
