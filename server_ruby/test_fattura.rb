require_relative 'fattura_client'
require_relative 'invoice_pdf'

FakePI = Struct.new(:id, :amount, :currency, :metadata)

fake_pi = FakePI.new(
  'pi_test_123',
  10000, # 100.00 EUR in cents
  'eur',
  {
    'codice_fiscale' => 'PPPFNC40P02H501L',
    'nome'           => 'Pippo',
    'cognome'        => 'Franco',
    'indirizzo'      => 'Via Francesco Crispi 31',
    'cap'            => '00187',
    'comune'         => 'Roma',
    'provincia'      => 'RM',
    'nazione'        => 'IT'
  }
)

client = FatturaClient.new
result = client.send_invoice(fake_pi)

puts "id:                 #{result['id']}"
puts "sdi_identificativo: #{result['sdi_identificativo']}"
puts "sdi_stato:          #{result['sdi_stato']}"
puts "sdi_nome_file:      #{result['sdi_nome_file']}"

if (xml = result['sdi_fattura']) && !xml.empty?
  File.write(result['sdi_nome_file'], xml)
  puts "XML saved to:       #{result['sdi_nome_file']}"
end

m = fake_pi.metadata
local_pdf = InvoicePdf.generate(
  numero:  result['id'],
  data:    Date.today.to_s,
  cliente: {
    nome:            m['nome'],
    cognome:         m['cognome'],
    codice_fiscale:  m['codice_fiscale'],
    indirizzo:       m['indirizzo'],
    cap:             m['cap'],
    comune:          m['comune'],
    provincia:       m['provincia'],
    nazione:         m['nazione']
  },
  righe: [{
    descrizione: 'credito VEASYT',
    quantita:    1,
    prezzo:      fake_pi.amount / 100.0,
    iva:         22
  }]
)

local_pdf_filename = result['sdi_nome_file'].sub('.xml', '_local.pdf')
File.binwrite(local_pdf_filename, local_pdf)
puts "Local PDF saved to: #{local_pdf_filename}"
