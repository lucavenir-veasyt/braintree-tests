require 'net/http'
require 'json'
require 'base64'

class FatturaClient
  BASE_URL = "https://fattura-elettronica-api.it/ws2.0/test"

  def initialize
    @username = ENV.fetch('FATTURA_API_USERNAME')
    @password = ENV.fetch('FATTURA_API_PASSWORD')
    @token    = nil
    @token_expires_at = nil
  end


  def fetch_pdf(invoice_id)
    uri = URI("#{BASE_URL}/fatture/#{invoice_id}/pdf")
    req = Net::HTTP::Get.new(uri, 'Authorization' => "Bearer #{bearer_token}")
    response = http(uri).request(req)
    raise "FatturaClient PDF fetch failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    response.body
  end

  def send_invoice(payment_intent)
    amount_eur = (payment_intent.amount / 100.0).round(2)
    m = payment_intent.metadata

    payload = {
      destinatario: {
        CodiceSDI:     '0000000',
        CodiceFiscale: m['codice_fiscale'],
        Denominazione: "#{m['nome']} #{m['cognome']}",
        Indirizzo:     m['indirizzo'],
        CAP:           m['cap'],
        Comune:        m['comune'],
        Provincia:     m['provincia']
      },
      documento: {
        Data:   Time.now.strftime('%Y-%m-%d'),
        Numero: payment_intent.id
      },
      righe: [{
        Descrizione:    'credito VEASYT',
        PrezzoUnitario: amount_eur.to_s,
        AliquotaIVA:    22
      }]
    }

    uri = URI("#{BASE_URL}/fatture")
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{bearer_token}")
    req.body = payload.to_json
    response = http(uri).request(req)
    raise "FatturaClient send_invoice failed: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  end

  def bearer_token
    return @token if @token && Time.now < @token_expires_at

    uri = URI("#{BASE_URL}/authentication")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Basic #{Base64.strict_encode64("#{@username}:#{@password}")}"

    res = http(uri).request(req)
    raise "FatturaClient auth failed: #{res.code} #{res.body}" unless res.is_a?(Net::HTTPSuccess)

    @token = res['X-auth-token']
    @token_expires_at = Time.now + (12 * 3600 - 300) # 5-min buffer before 12h expiry
    @token
  end

  def http(uri)
    Net::HTTP.new(uri.host, uri.port).tap { |h| h.use_ssl = true }
  end
end
