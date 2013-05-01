require 'economic/proxies/entity_proxy'

module Economic
  class CreditorEntryProxy < EntityProxy
    def find_by_invoice_number(invoice_number)
      response = session.request(entity_class.soap_action('FindByInvoiceNumber'), {
        'invoiceNumber' => invoice_number
      })

      response[:creditor_entry_handle].map do |creditor_entry_handle|
        # Kinda ugly, but we get an array instead of a hash when there's only one result. :)
        Hash[*creditor_entry_handle.to_a.flatten][:serial_number].to_i
      end
    end

    def find(serial_number)
      response = session.request(entity_class.soap_action('GetData'), {
        'entityHandle' => {
          'SerialNumber' => serial_number
         }
      })

      build(response)
    end

    def match(*serial_numbers)
      session.request(entity_class.soap_action('MatchEntries'), {
        :entries => {
          "CreditorEntryHandle" => serial_numbers.map { |serial_number|
            { "SerialNumber" => serial_number }
          }
        }
      })
    end
  end
end
