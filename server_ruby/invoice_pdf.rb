require 'prawn'
require 'prawn/table'
require 'date'

class InvoicePdf
  BLUE = '1B3F6F'
  GRAY = 'CCCCCC'

  SELLER = {
    name:    'VEASYT srl',
    piva:    'IT04088680279',
    cf:      '04088680279',
    address: 'via Gaspare Gozzi 55',
    city:    '30172 - Venezia (VE) - IT',
    phone:   '0418310083',
    email:   'info@veasyt.com'
  }.freeze

  def self.generate(**args)
    new(**args).render
  end

  def initialize(numero:, data:, cliente:, righe:)
    @numero  = numero
    @data    = Date.parse(data) 
    @cliente = cliente
    @righe   = righe

    @imponibile = righe.sum { |r| r[:quantita] * r[:prezzo] }.round(2)
    @iva_pct    = righe.first[:iva]
    @iva_amt    = (@imponibile * @iva_pct / 100.0).round(2)
    @totale     = (@imponibile + @iva_amt).round(2)
  end

  def render
    @pdf = Prawn::Document.new(page_size: 'A4', margin: [40, 40, 60, 40])
    build_header
    build_parties
    build_line_items
    build_payment
    build_tax_section
    build_footer
    @pdf.render
  end

  private

  def build_header
    w = @pdf.bounds.width

    @pdf.bounding_box([@pdf.bounds.left + w * 0.55, @pdf.cursor], width: w * 0.45) do
      @pdf.text 'FATTURA', size: 22, style: :bold, align: :right, color: BLUE
      @pdf.text "nr. #{@numero} del #{fmt_date(@data)}", size: 8, align: :right
      @pdf.text "Data invio: #{fmt_date(Date.today)}", size: 8, align: :right
    end

    @pdf.move_down 40
    @pdf.stroke_color BLUE
    @pdf.line_width 1.5
    @pdf.stroke_horizontal_rule
    @pdf.stroke_color '000000'
    @pdf.line_width 1
  end

  def build_parties
    @pdf.move_down 15
    w    = @pdf.bounds.width
    col  = (w - 20) / 2
    y    = @pdf.cursor
    ends = []

    @pdf.bounding_box([@pdf.bounds.left, y], width: col) do
      section_label 'FORNITORE'
      @pdf.move_down 4
      @pdf.text SELLER[:name],    style: :bold, size: 9
      @pdf.text "P.IVA: #{SELLER[:piva]}", size: 8
      @pdf.text "C.F.: #{SELLER[:cf]}",    size: 8
      @pdf.text SELLER[:address],           size: 8
      @pdf.text SELLER[:city],              size: 8
      @pdf.text "Telefono: #{SELLER[:phone]}", size: 8
      @pdf.text SELLER[:email],             size: 8
      ends << @pdf.y
    end

    @pdf.bounding_box([@pdf.bounds.left + col + 20, y], width: col) do
      section_label 'CLIENTE'
      @pdf.move_down 4
      @pdf.text "#{@cliente[:nome]} #{@cliente[:cognome]}", style: :bold, size: 9
      @pdf.text "C.F.: #{@cliente[:codice_fiscale]}", size: 8
      @pdf.text @cliente[:indirizzo],        size: 8
      @pdf.text "#{@cliente[:cap]} - #{@cliente[:comune]} (#{@cliente[:provincia]}) - #{@cliente[:nazione]}", size: 8
      ends << @pdf.y
    end

    @pdf.move_cursor_to ends.min - @pdf.bounds.absolute_bottom
    @pdf.move_down 20
  end

  def build_line_items
    section_label 'PRODOTTI E SERVIZI'
    @pdf.move_down 6

    w    = @pdf.bounds.width
    rows = [["NR", "DESCRIZIONE", "QUANTITA'", "PREZZO", "IMPORTO", "IVA", "NATURA IVA"]]

    @righe.each_with_index do |r, i|
      rows << [
        i + 1,
        r[:descrizione],
        r[:quantita],
        fmt_eur(r[:prezzo]),
        fmt_eur((r[:quantita] * r[:prezzo]).round(2)),
        "#{r[:iva]} %",
        '-'
      ]
    end

    @pdf.table(rows, width: w) do |t|
      t.cells.padding           = [5, 6]
      t.row(0).background_color = BLUE
      t.row(0).text_color       = 'FFFFFF'
      t.row(0).font_style       = :bold
      t.cells.size              = 8
      t.cells.border_color      = GRAY
      t.column(0).width         = 25
      t.column(2).width         = 55
      t.column(3).width         = 60
      t.column(4).width         = 60
      t.column(5).width         = 35
      t.column(6).width         = 60
    end
  end

  def build_payment
    @pdf.move_down 15
    section_label 'METODO DI PAGAMENTO'
    @pdf.move_down 6

    rows = [
      ['NR RATA', 'MODALITÀ', 'PAGAMENTO', 'BANCA', 'IBAN', 'BIC/SWIFT', 'DATA SCADENZA', 'IMPORTO'],
      ['1', 'Carta di pagamento', 'Pagamento in unica soluzione', '', '', '', fmt_date(@data), fmt_eur(@totale)]
    ]

    @pdf.table(rows, width: @pdf.bounds.width) do |t|
      t.cells.padding           = [5, 6]
      t.row(0).background_color = BLUE
      t.row(0).text_color       = 'FFFFFF'
      t.row(0).font_style       = :bold
      t.cells.size              = 8
      t.cells.border_color      = GRAY
    end

    @pdf.move_down 4
    @pdf.text 'Beneficiario: VEASYT srl', size: 8
  end

  def build_tax_section
    @pdf.move_down 15
    w    = @pdf.bounds.width
    col  = (w - 20) / 2
    y    = @pdf.cursor
    ends = []

    @pdf.bounding_box([@pdf.bounds.left, y], width: col) do
      section_label 'REGIME FISCALE'
      @pdf.move_down 6
      @pdf.table([['REGIME FISCALE'], ['RF01 - Ordinario']], width: col) do |t|
        t.cells.padding           = [5, 6]
        t.row(0).background_color = BLUE
        t.row(0).text_color       = 'FFFFFF'
        t.row(0).font_style       = :bold
        t.cells.size              = 8
        t.cells.border_color      = GRAY
      end
      ends << @pdf.y
    end

    @pdf.bounding_box([@pdf.bounds.left + col + 20, y], width: col) do
      section_label 'RIEPILOGO IVA'
      @pdf.move_down 6
      rows = [
        ['IVA', 'NATURA', 'NORMATIVA', "ESIGIBILITA'", 'IMPONIBILE', 'IMPOSTA'],
        ["#{@iva_pct}%", '', '', 'Immediata', fmt_eur(@imponibile), fmt_eur(@iva_amt)]
      ]
      @pdf.table(rows, width: col) do |t|
        t.cells.padding           = [4, 4]
        t.row(0).background_color = BLUE
        t.row(0).text_color       = 'FFFFFF'
        t.row(0).font_style       = :bold
        t.cells.size              = 7
        t.cells.border_color      = GRAY
      end
      ends << @pdf.y
    end

    @pdf.move_cursor_to ends.min - @pdf.bounds.absolute_bottom
    @pdf.move_down 15

    section_label 'CALCOLO FATTURA'
    @pdf.move_down 6

    rows = [
      ['Importo prodotti o servizi', fmt_eur(@imponibile)],
      ['Totale imponibile',          fmt_eur(@imponibile)],
      ['Totale IVA',                 fmt_eur(@iva_amt)],
      ['Totale documento',           fmt_eur(@totale)],
      ['Netto a pagare',             fmt_eur(@totale)]
    ]

    @pdf.table(rows, width: @pdf.bounds.width) do |t|
      t.cells.padding      = [4, 6]
      t.cells.size         = 8
      t.cells.border_color = GRAY
      t.cells.borders      = [:bottom]
      t.column(1).align    = :right
      t.row(-2).font_style = :bold
      t.row(-1).font_style = :bold
      t.row(-1).size       = 10
    end
  end

  def build_footer
    @pdf.move_down 20
    @pdf.stroke_color GRAY
    @pdf.line_width 0.5
    @pdf.stroke_horizontal_rule
    @pdf.move_down 4
    @pdf.text(
      'Copia analogica della fattura elettronica inviata a SdI | ' \
      'Il documento xml originale è disponibile online sul portale "Fatture e Corrispettivi dell\'Agenzia delle Entrate"',
      size: 6, align: :center, color: '888888'
    )
    @pdf.move_down 4
    @pdf.text "Fattura Nr. #{@numero} del #{fmt_date(@data)}", size: 7, color: '888888'
  end

  def section_label(text)
    @pdf.text text, style: :bold, size: 9, color: BLUE
  end

  def fmt_date(date)
    date.strftime('%d/%m/%Y')
  end

  def fmt_eur(amount)
    format('%.2f €', amount)
  end
end
