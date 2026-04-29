require 'sinatra'
require 'sinatra/json'
require 'stripe'
require 'rack/cors'
require 'json'
require 'date'
require_relative 'fattura_client'
require_relative 'invoice_pdf'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: %i[get post options]
  end
end

Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')
WEBHOOK_SECRET = ENV.fetch('STRIPE_WEBHOOK_SECRET')
FATTURA_CLIENT = FatturaClient.new

post '/api/stripe/checkout' do
  body = JSON.parse(request.body.read)
  amount = body['amount']
  base_url = ENV.fetch('APP_BASE_URL', 'http://localhost:4000')

  session = Stripe::Checkout::Session.create(
    mode: 'payment',
    payment_method_types: ['card'],
    line_items: [{
      price_data: {
        currency: 'eur',
        unit_amount: amount,
        product_data: { name: 'payment' }
      },
      quantity: 1
    }],
    success_url: "#{base_url}/payment/success",
    cancel_url: "#{base_url}/payment/cancel"
  )

  json url: session.url, session_id: session.id
end

get '/payment/success' do
  content_type :html
  '<html><body style="font-family:sans-serif;text-align:center;padding:60px"><h2>Payment complete ✓</h2><p>You can close this window.</p></body></html>'
end

get '/payment/cancel' do
  content_type :html
  '<html><body style="font-family:sans-serif;text-align:center;padding:60px"><h2>Payment cancelled</h2><p>You can close this window.</p></body></html>'
end

post '/api/stripe/payment' do
  body = JSON.parse(request.body.read)
  amount = body['amount']

  intent = Stripe::PaymentIntent.create(
    amount: amount,
    currency: 'eur',
    payment_method_types: ['card'],
    metadata: {
      codice_fiscale: body['codice_fiscale'],
      nome:           body['nome'],
      cognome:        body['cognome'],
      indirizzo:      body['indirizzo'],
      cap:            body['cap'],
      comune:         body['comune'],
      provincia:      body['provincia'],
      nazione:        body.fetch('nazione', 'IT')
    }
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

  puts event

  case event.type
  when 'payment_intent.succeeded'
    pi = event.data.object
    puts "Payment confirmed: #{pi.id}, amount: #{pi.amount} #{pi.currency}"

    result = FATTURA_CLIENT.send_invoice(pi)
    puts "Invoice sent: #{result.inspect}"

    m = pi.metadata
    pdf = InvoicePdf.generate(
      numero:  result['id'].to_s,
      data:    Date.today.to_s,
      cliente: {
        nome:           m['nome'],
        cognome:        m['cognome'],
        codice_fiscale: m['codice_fiscale'],
        indirizzo:      m['indirizzo'],
        cap:            m['cap'],
        comune:         m['comune'],
        provincia:      m['provincia'],
        nazione:        m['nazione']
      },
      righe: [{
        descrizione: 'credito VEASYT',
        quantita:    1,
        prezzo:      pi.amount / 100.0,
        iva:         22
      }]
    )
    pdf_path = "invoice_#{result['id']}.pdf"
    File.binwrite(pdf_path, pdf)
    puts "Invoice PDF saved: #{pdf_path}"
  end

  status 200
  json received: true
rescue Stripe::SignatureVerificationError
  halt 400, json(error: 'Invalid signature')
rescue JSON::ParserError
  halt 400, json(error: 'Invalid payload')
end
