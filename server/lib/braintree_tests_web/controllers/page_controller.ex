defmodule BraintreeTestsWeb.PageController do
  use BraintreeTestsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
