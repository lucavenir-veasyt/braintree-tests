require_relative 'fattura_client'

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

pdf = client.fetch_pdf(result['id'])
pdf_filename = result['sdi_nome_file'].sub('.xml', '.pdf')
File.binwrite(pdf_filename, pdf)
puts "PDF saved to:       #{pdf_filename}"
