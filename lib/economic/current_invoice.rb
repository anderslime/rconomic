require 'economic/entity'

module Economic

  # CurrentInvoices are invoices that are not yet booked. They are therefore not read-only.
  #
  # API documentation: http://www.e-conomic.com/apidocs/Documentation/T_Economic_Api_ICurrentInvoice.html
  #
  # Examples
  #
  #   # Create invoice for debtor:
  #   invoice = debtor.current_invoices.build
  #   invoice.date = Time.now
  #   invoice.due_date = Time.now + 15
  #   invoice.exchange_rate = 100
  #   invoice.is_vat_included = false
  #
  #   # Add a line to the invoice
  #   invoice_line = invoice.lines.build
  #   invoice_line.description = 'Line on invoice'
  #   invoice_line.unit_handle = { :number => 1 }
  #   invoice_line.product_handle = { :number => 101 }
  #   invoice_line.quantity = 12
  #   invoice_line.unit_net_price = 19.95
  #   invoice.lines << invoice_line
  #
  #   invoice.save
  class CurrentInvoice < Entity
    has_properties :id, :debtor_handle, :debtor_name, :debtor_address, :debtor_postal_code, :debtor_city, :debtor_country, :attention_handle, :date, :term_of_payment_handle, :due_date, :currency_handle, :exchange_rate, :is_vat_included, :layout_handle, :delivery_date, :net_amount, :vat_amount, :gross_amount, :margin, :margin_as_percent, :heading

    defaults(
      :id => 0,
      :date => Time.now,
      :term_of_payment_handle => nil,
      :due_date => nil,
      :currency_handle => nil,
      :exchange_rate => 100, # Why am _I_ inputting this?
      :is_vat_included => nil,
      :layout_handle => nil,
      :delivery_date => nil,
      :heading => nil,
      :net_amount => 0,
      :vat_amount => 0,
      :gross_amount => 0,
      :margin => 0,
      :margin_as_percent => 0 # Why do I have to input both Margin and MarginAsPercent? Shouldn't powerful Windows machines running ASP.NET be able to compute this?
    )

    def initialize(properties = {})
      super
    end

    def attention
      return nil if attention_handle.nil?
      @attention ||= session.contacts.find(attention_handle)
    end

    def attention=(contact)
      self.attention_handle = contact.handle
      @attention = contact
    end

    def attention_handle=(handle)
      @attention = nil unless handle == @attention_handle
      @attention_handle = handle
    end

    # Books a current invoice. An invoice number greater than all other invoice numbers will be
    # assigned to the resulting Economic::Invoice.
    #
    # Returns the resulting Economic::Invoice object
    def book
      response = session.request soap_action(:book), {"currentInvoiceHandle" => handle.to_hash}

      # Find the created Invoice
      session.invoices.find(response[:number])
    end

    # Books a current invoice. The given number will be assigned to the
    # resulting Economic::Invoice.
    #
    # Returns the resulting Economic::Invoice object
    def book_with_number(number)
      response = session.request soap_action(:book_with_number), {
          "currentInvoiceHandle" => handle.to_hash,
          "number" => number,
          :order! => ["currentInvoiceHandle", "number"]
        }

      # Find the created Invoice
      session.invoices.find(response[:number])
    end

    def debtor
      return nil if debtor_handle.nil?
      @debtor ||= session.debtors.find(debtor_handle)
    end

    def debtor=(debtor)
      self.debtor_handle = debtor.handle
      @debtor = debtor
    end

    def debtor_handle=(handle)
      @debtor = nil unless handle == @debtor_handle
      @debtor_handle = handle
    end

    def handle
      @handle ||= Handle.new(:id => @id)
    end

    def lines
      @lines ||= CurrentInvoiceLineProxy.new(self)
    end

    def save
      lines = self.lines

      result = super
      self.id = result[:id].to_i
      @handle = nil # Reset a memoized handle, leaving it up to #handle to recreate it with correct id

      lines.each do |invoice_line|
        invoice_line.session = session
        invoice_line.invoice = self
        invoice_line.save
      end
    end

    protected

    # Returns OrderedHash with the properties of CurrentInvoice in the correct order, camelcased and ready
    # to be sent via SOAP
    def build_soap_data
      data = ActiveSupport::OrderedHash.new

      data['Id'] = id
      data['DebtorHandle'] = debtor.handle.to_hash unless debtor.blank?
      data['DebtorName'] = debtor_name
      data['DebtorAddress'] = debtor_address unless debtor_address.blank?
      data['DebtorPostalCode'] = debtor_postal_code unless debtor_postal_code.blank?
      data['DebtorCity'] = debtor_city unless debtor_city.blank?
      data['DebtorCountry'] = debtor_country unless debtor_country.blank?
      data['AttentionHandle'] = { 'Id' => attention_handle[:id] } unless attention_handle.blank?
      data['Date'] = date.iso8601 unless date.blank?
      data['TermOfPaymentHandle'] = { 'Id' => term_of_payment_handle[:id] } unless term_of_payment_handle.blank?
      data['DueDate'] = (due_date.blank? ? nil : due_date.iso8601)
      data['CurrencyHandle'] = { 'Code' => currency_handle[:code] } unless currency_handle.blank?
      data['ExchangeRate'] = exchange_rate
      data['IsVatIncluded'] = is_vat_included
      data['LayoutHandle'] = { 'Id' => layout_handle[:id] } unless layout_handle.blank?
      data['DeliveryDate'] = delivery_date ? delivery_date.iso8601 : nil
      data['Heading'] = heading unless heading.blank?
      data['NetAmount'] = net_amount
      data['VatAmount'] = vat_amount
      data['GrossAmount'] = gross_amount
      data['Margin'] = margin
      data['MarginAsPercent'] = margin_as_percent

      return data
    end
  end

end
