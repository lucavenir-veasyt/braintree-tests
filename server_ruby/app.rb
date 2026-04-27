require 'sinatra'
require 'sinatra/json'
require 'stripe'
require 'rack/cors'
require 'json'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: %i[get post options]
  end
end

Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
WEBHOOK_SECRET = ENV.fetch('STRIPE_WEBHOOK_SECRET')

post '/api/stripe/payment' do
  body = JSON.parse(request.body.read)
  amount = body['amount']

  intent = Stripe::PaymentIntent.create(
    amount: amount,
    currency: 'eur',
    payment_method_types: ['card']
  )

  json client_secret: intent.client_secret
end

# stripe sends the raw body;
# signature verification requires it untouched!
# TL;DR: do NOT parse JSON before calling construct_event.
post '/api/webhooks/stripe' do
  payload    = request.body.read
  sig_header = request.env['HTTP_STRIPE_SIGNATURE']

  event = Stripe::Webhook.construct_event(
    payload, sig_header, WEBHOOK_SECRET
  )

  case event.type
  when 'payment_intent.succeeded'
    pi = event.data.object
    puts "Payment confirmed: #{pi.id}, amount: #{pi.amount} #{pi.currency}"
  end

  status 200
  json received: true
rescue Stripe::SignatureVerificationError
  halt 400, json(error: 'Invalid signature')
rescue JSON::ParserError
  halt 400, json(error: 'Invalid payload')
end
